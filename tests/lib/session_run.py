#!/usr/bin/env python3
"""session_run.py — run one gate in a session of its own and leave nothing behind (#364, #371; design R, 14z-226).

Usage: python3 tests/lib/session_run.py <command> [args...]
       (tests/run_all_emulator.sh passes: [timeout -k 30 <secs>] tests/<gate>.sh <args>, plain and CONTROL=)

THE RULING: `DECISIONS_HISTORY.md` "Ruled 2026-11-11 (14z-226) — #364/#371: design R is built, without the lint"
(the maintainer: "R, no lint (Recommended)"). Measured before it (build/agent225/t364/, build/agent226/t364/, local): a
timed-out emulator gate's MAME (`cps2`) caught TERM and outlived its gate and the runner at full CPU (#371), the gate's
work directory and the runner's temp directory were left behind, and a gate-side trap in the split form did not stop
it (#364).

What it does:
  1. starts the command as the leader of a NEW SESSION (start_new_session), with TMPDIR set to a fresh directory of its
     own, `gate.XXXXXX` under the inherited TMPDIR (or /tmp);
  2. stays itself in the CALLER's process group, so a TERM, INT or HUP sent to the runner's group (a Ctrl-C, a caller's
     timeout) reaches it: it forwards the signal to every process of the gate's session, then carries on to step 3;
  3. when the command returns, whatever its status, sends TERM to every process still in that session (nested
     `timeout`s put their children in process groups of their own, so the SESSION is the unit, never one group),
     waits up to REAP_WAIT seconds (default 10) for them to go, then KILLs what is left;
  4. removes the gate's TMPDIR;
  5. exits with the command's status (a death by signal N as 128+N, the shell's form), or 128+N if it was itself
     signalled.
Every action is reported on stderr as `### session_run: ...` lines (the runner sends stderr to the gate's log).
Session membership is read with os.getsid() over `ps -A -o pid=` (Linux and macOS).

Limits (named in the recommendation, build/agent226/t364/recommendation.md):
  - macOS `mktemp -d` with no template ignores TMPDIR (docs/platform/gotchas.md), so on the Mac a gate's bare
    `mktemp -d` directory lands outside the per-gate TMPDIR and step 4 does not remove it; the gate's own trap still
    does on a normal exit;
  - a process that starts a session of its own (tools/desktop_session_play.py does) leaves the gate's session and is
    not reaped here; that driver ends its own group;
  - a manual run of a gate outside the runner is not wrapped.
Ground truth: tests/test_session_reap.sh.
"""
import os
import shutil
import signal
import subprocess
import sys
import tempfile
import time

TAG = "### session_run:"


def say(msg):
    print("%s %s" % (TAG, msg), file=sys.stderr, flush=True)


def members(sid):
    """Every live process whose session id is sid (the session leader included while it lives)."""
    out = subprocess.run(["ps", "-A", "-o", "pid="], capture_output=True, text=True).stdout.split()
    me = os.getpid()
    found = []
    for tok in out:
        try:
            p = int(tok)
        except ValueError:
            continue
        if p == me:
            continue
        try:
            if os.getsid(p) == sid:
                found.append(p)
        except (ProcessLookupError, PermissionError, OSError):
            pass
    return found


def describe(pids):
    if not pids:
        return ""
    r = subprocess.run(["ps", "-o", "pid=,comm=", "-p", ",".join(map(str, pids))], capture_output=True, text=True)
    return "; ".join(" ".join(line.split()) for line in r.stdout.splitlines())


def signal_all(pids, sig):
    for p in pids:
        try:
            os.kill(p, sig)
        except (ProcessLookupError, PermissionError):
            pass


def reap(sid, status, wait_s):
    """TERM, a bounded wait, then KILL, for every process left in the session. Returns the count left after KILL."""
    left = members(sid)
    if not left:
        return 0
    say("%d process(es) left in the gate's session after it returned (status %d): %s"
        % (len(left), status, describe(left)))
    signal_all(left, signal.SIGTERM)
    deadline = time.time() + wait_s
    while time.time() < deadline and members(sid):
        time.sleep(0.2)
    still = members(sid)
    signal_all(still, signal.SIGKILL)
    deadline = time.time() + 5
    while time.time() < deadline and members(sid):
        time.sleep(0.1)
    after = members(sid)
    say("TERM ended %d, KILL needed for %d, %d left after KILL" % (len(left) - len(still), len(still), len(after)))
    return len(after)


def count_entries(d):
    n = 0
    for _root, dirs, files in os.walk(d):
        n += len(dirs) + len(files)
    return n


def main(argv):
    if not argv:
        print("usage: session_run.py <command> [args...]", file=sys.stderr)
        return 2
    base = os.environ.get("TMPDIR") or "/tmp"
    try:
        gtmp = tempfile.mkdtemp(prefix="gate.", dir=base)
    except OSError as e:
        say("could not make the gate's TMPDIR under %s: %s" % (base, e))
        return 2
    env = dict(os.environ, TMPDIR=gtmp)
    got = []
    state = {"sid": None}

    def forward(signum, _frame):
        got.append(signum)
        if state["sid"] is None:   # before the gate's session exists: forwarded the moment it does
            say("received signal %d before the gate started" % signum)
            return
        say("received signal %d: forwarding it to the gate's session" % signum)
        signal_all(members(state["sid"]), signum)

    # The handlers go in BEFORE the gate starts: a TERM in the gap between the two used to kill this helper with the
    # default action and leave the gate's session running (tests/test_session_reap.sh section 4, 14z-226).
    for s in (signal.SIGTERM, signal.SIGINT, signal.SIGHUP):
        signal.signal(s, forward)
    try:
        child = subprocess.Popen(argv, env=env, start_new_session=True)
    except OSError as e:
        say("could not start %s: %s" % (argv[0], e))
        shutil.rmtree(gtmp, ignore_errors=True)
        return 127
    sid = child.pid   # the new session's id is its leader's pid
    state["sid"] = sid
    if got:
        say("forwarding signal %d, received before the gate started, to its session" % got[0])
        signal_all(members(sid) or [sid], got[0])
    while True:
        try:
            rc = child.wait()
            break
        except InterruptedError:
            continue
    if rc < 0:
        rc = 128 - rc
    left = reap(sid, rc, float(os.environ.get("REAP_WAIT", "10")))
    n = count_entries(gtmp)
    shutil.rmtree(gtmp, ignore_errors=True)
    if os.path.exists(gtmp):
        say("the gate's TMPDIR %s could NOT be removed (%d entries)" % (gtmp, n))
    elif n:
        say("the gate's TMPDIR removed (%d entries)" % n)
    if left:
        say("%d process(es) of the gate's session survived KILL" % left)
    if got:
        return 128 + got[0]
    return rc


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
