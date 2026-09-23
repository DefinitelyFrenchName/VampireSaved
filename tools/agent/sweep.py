#!/usr/bin/env python3
"""sweep.py — C0.3 of GitHub #172: NO PROCESS OUTLIVES ITS PURPOSE (slice S2).

At the close, list every process a Claude Code session left alive, so that each one is
either killed or DECLARED in writing before the push
(`docs/project/agent_architecture_scope.md` §4 C0.3; the close checklist in STATE.md's
header). The ground truth is #172's own: a headless Chrome alive 1 d 11 h and a
`tail -F` orphaned for 17 days — in both, the agent checked the OUTPUT it wanted and
never the PROCESS it had started.

TWO KINDS OF SURVIVOR, found two different ways because one way cannot see both:

  ATTACHED  a process under one of this session's Bash-tool shells. Claude Code starts
            every tool call in a shell that is a SESSION LEADER and a direct child of the
            Claude process (`$CLAUDE_PID`); its own helpers (`caffeinate`) are children
            but not leaders, so they are not tool work. A tracked background task is
            labelled by its id, read from the `tasks/<id>.output` file its shell writes to.
            The sweep's own tool shell is excluded.
  ORPHAN    a process whose launching shell exited, reparented to launchd/init (ppid 1),
            that points into THE PROJECT: its working directory, one of its standard
            streams or its command line names a project root, or it is a Claude tool
            shell (`.claude/shell-snapshots/` on its command line), or its environment
            carries `CLAUDE_CODE_SESSION_ID` of the swept session. Orphans are listed
            whatever session left them: nothing tracks an orphan, so any close that sees
            one owns it.

WHY NOT THE ENVIRONMENT ALONE (measured 2026-09-23, 14z-176): every tool-call process
inherits `CLAUDE_CODE_SESSION_ID`, but macOS hides the environment of its own platform
binaries (`/usr/bin/tail`, `/bin/sleep`, `/bin/zsh`) and of hardened apps (Google
Chrome) — `KERN_PROCARGS2` returns the arguments only. Both ground-truth cases are
exactly those binaries. The working directory IS readable for them (`lsof -d cwd`), and
it is what found the second 14z-133 `tail | ugrep` pipeline, alive 18 days, that the
by-hand check for #172 had missed.

THE INSTRUMENT CHECKS ITSELF FIRST: the sweep must find its own process in the table,
with its working directory read, before it may say CLEAN — a blind process lister and a
clean machine print the same empty list (exit 2 if it cannot see itself).

Usage:
  python3 tools/agent/sweep.py [--claude-pid PID] [--session ID] [--root DIR ...]
                               [--declared FILE] [--transcript FILE]
  python3 tools/agent/sweep.py --declare PID "REASON"     # record a deliberate survivor

  --claude-pid  the Claude process (default $CLAUDE_PID; absent: the ATTACHED half is
                skipped and the output says so)
  --session     the session id (default $CLAUDE_CODE_SESSION_ID)
  --root        a project root; repeatable; REPLACES the defaults (the repo, the session
                scratchpad parent, ~/.cache/vampire-saved, /tmp/vampire-saved-*)
  --declared    the declarations file (default build/agent_hooks/declared.tsv)
  --transcript  the session transcript, for the OPEN TASK lines (default derived)

Exit: 0 CLEAN (no survivor, or every survivor declared), 1 SURVIVORS, 2 the instrument
could not see itself. Stdlib only. macOS (ps + lsof) and Linux (/proc).
"""
import argparse
import datetime
import os
import re
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.dirname(os.path.dirname(HERE))
_TASK_OUT = re.compile(r"/([0-9a-f-]{36})/tasks/(\w+)\.output$")
SNAPSHOT = "/.claude/shell-snapshots/"
INITS = {"launchd", "init", "systemd"}


# ------------------------------------------------------------------ the process table

def table():
    """-> {pid: dict(pid, ppid, uid, lstart, etime, comm, command)} from one `ps` call."""
    out = subprocess.run(["ps", "-Ao", "pid=,ppid=,uid=,lstart=,etime=,command="],
                         capture_output=True, text=True).stdout
    procs = {}
    for line in out.splitlines():
        f = line.split(None, 9)
        if len(f) < 9:
            continue
        pid, ppid, uid = int(f[0]), int(f[1]), int(f[2])
        lstart = " ".join(f[3:8])
        cmd = f[9] if len(f) > 9 else ""
        procs[pid] = {"pid": pid, "ppid": ppid, "uid": uid, "lstart": lstart,
                      "etime": f[8], "command": cmd,
                      "comm": os.path.basename(cmd.split(" ", 1)[0]) if cmd else "?"}
    return procs


def files(pids):
    """-> {pid: {"cwd": path, "fd": [paths of 0/1/2]}} for the given pids."""
    res = {p: {"cwd": None, "fd": []} for p in pids}
    if not pids:
        return res
    if os.path.isdir("/proc/self"):
        for p in pids:
            try:
                res[p]["cwd"] = os.readlink(f"/proc/{p}/cwd")
            except OSError:
                pass
            for fd in (0, 1, 2):
                try:
                    res[p]["fd"].append(os.readlink(f"/proc/{p}/fd/{fd}"))
                except OSError:
                    pass
        return res
    out = subprocess.run(["lsof", "-a", "-p", ",".join(map(str, sorted(pids))),
                          "-d", "cwd,0,1,2", "-Fpfn"], capture_output=True, text=True).stdout
    pid = fd = None
    for line in out.splitlines():
        tag, val = line[:1], line[1:]
        if tag == "p":
            pid = int(val)
        elif tag == "f":
            fd = val
        elif tag == "n" and pid in res:
            if fd == "cwd":
                res[pid]["cwd"] = val
            elif val.startswith("/"):
                res[pid]["fd"].append(val)
    return res


def environ_sessions(pids):
    """-> {pid: the CLAUDE_CODE_SESSION_ID in its environment} for the pids whose
    environment is readable and carries one (unreadable for macOS platform binaries and
    hardened apps — measured; see the module doc). One `ps` call, not one per pid."""
    res = {}
    if not pids:
        return res
    if os.path.isdir("/proc/self"):
        for p in pids:
            try:
                env = open(f"/proc/{p}/environ", "rb").read().decode(errors="replace").split("\0")
            except OSError:
                continue
            for e in env:
                if e.startswith("CLAUDE_CODE_SESSION_ID="):
                    res[p] = e.split("=", 1)[1]
        return res
    out = subprocess.run(["ps", "-E", "-ww", "-o", "pid=,command=", "-p", ",".join(map(str, sorted(pids)))],
                         capture_output=True, text=True).stdout
    for line in out.splitlines():
        f = line.split()
        if not f or not f[0].isdigit():
            continue
        for tok in f[1:]:
            if tok.startswith("CLAUDE_CODE_SESSION_ID="):
                res[int(f[0])] = tok.split("=", 1)[1]
    return res


def getsid(pid):
    try:
        return os.getsid(pid)
    except OSError:
        return None


def children_map(procs):
    kids = {}
    for p in procs.values():
        kids.setdefault(p["ppid"], []).append(p["pid"])
    return kids


def subtree(kids, root):
    out, todo = [], [root]
    while todo:
        p = todo.pop(0)
        out.append(p)
        todo.extend(sorted(kids.get(p, [])))
    return out


def ancestors(procs, pid):
    chain = []
    while pid in procs and pid not in chain:
        chain.append(pid)
        pid = procs[pid]["ppid"]
    return chain


# ------------------------------------------------------------------ the two scans

def attached(procs, kids, claude_pid, me):
    """Every tool-shell subtree under the Claude process except the sweep's own."""
    own = set(ancestors(procs, me))
    roots = []
    for c in sorted(kids.get(claude_pid, [])):
        if getsid(c) != c:
            continue  # not a session leader: Claude's own helper (caffeinate), not tool work
        if c in own:
            continue  # the tool shell running this sweep
        roots.append(c)
    return roots


def under(path, roots):
    return bool(path) and any(path == r or path.startswith(r.rstrip("/") + "/") for r in roots)


def orphan_roots(procs, uid, exclude):
    """Every process of this user reparented to launchd/init (ppid 1, or a subreaper init)."""
    out = []
    for p in sorted(procs):
        pr = procs[p]
        if pr["uid"] != uid or p in exclude or p == 1 or pr["comm"] in INITS:
            continue
        parent = procs.get(pr["ppid"])
        if pr["ppid"] == 1 or (parent and parent["comm"] in INITS):
            out.append(p)
    return out


def orphans(procs, cands, info, envs, roots, session):
    """-> [(pid, signals, env session)] for the orphans that point into the project."""
    found = []
    for p in cands:
        pr, fi, es = procs[p], info.get(p, {}), envs.get(p)
        sig = []
        if under(fi.get("cwd"), roots):
            sig.append("cwd")
        if any(under(f, roots) for f in fi.get("fd", [])):
            sig.append("stream")
        if any(r in pr["command"] for r in roots):
            sig.append("argv")
        if SNAPSHOT in pr["command"]:
            sig.append("claude-shell")
        if session and es == session:
            sig.append("env")
        if sig:
            found.append((p, sig, es))
    return found


def task_label(info_p):
    for f in info_p.get("fd", []):
        m = _TASK_OUT.search(f)
        if m:
            return m.group(1), m.group(2)
    return None, None


# ------------------------------------------------------------------ declarations

def read_declared(path):
    d = {}
    try:
        for line in open(path, encoding="utf-8"):
            f = line.rstrip("\n").split("\t")
            if len(f) >= 4 and f[0].isdigit():
                d[(int(f[0]), f[1])] = f[3]
    except OSError:
        pass
    return d


def declare(path, pid, reason):
    procs = table()
    if pid not in procs:
        print(f"REFUSED: pid {pid} is not running — nothing to declare")
        return 2
    if not reason.strip():
        print("REFUSED: a declaration needs a reason in writing")
        return 2
    os.makedirs(os.path.dirname(path), exist_ok=True)
    new = not os.path.exists(path)
    with open(path, "a", encoding="utf-8") as f:
        if new:
            f.write("pid\tlstart\tdeclared_at\treason\n")
        f.write(f"{pid}\t{procs[pid]['lstart']}\t{datetime.datetime.now().isoformat(timespec='seconds')}"
                f"\t{' '.join(reason.split())}\n")
    print(f"DECLARED {pid} (started {procs[pid]['lstart']}): {reason}")
    return 0


# ------------------------------------------------------------------ main

def default_roots():
    uid = os.getuid()
    slug = re.sub(r"[^A-Za-z0-9-]", "-", REPO)
    r = [REPO, f"/private/tmp/claude-{uid}/{slug}", f"/tmp/claude-{uid}/{slug}",
         os.path.expanduser("~/.cache/vampire-saved"), "/tmp/vampire-saved-", "/private/tmp/vampire-saved-"]
    if os.environ.get("JTSIM_SCRATCH"):
        r.append(os.environ["JTSIM_SCRATCH"])
    return r


def fmt(pr, depth=0):
    lead = "    " + "  " * depth + ("└ " if depth else "")
    return f"{lead}{pr['pid']} (up {pr['etime']}) :: {' '.join(pr['command'].split())[:150]}"


def main():
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("--claude-pid", type=int, default=int(os.environ.get("CLAUDE_PID", "0") or 0))
    ap.add_argument("--session", default=os.environ.get("CLAUDE_CODE_SESSION_ID", ""))
    ap.add_argument("--root", action="append")
    ap.add_argument("--declared", default=os.path.join(REPO, "build", "agent_hooks", "declared.tsv"))
    ap.add_argument("--transcript")
    ap.add_argument("--declare", nargs=2, metavar=("PID", "REASON"))
    a = ap.parse_args()

    if a.declare:
        return declare(a.declared, int(a.declare[0]), a.declare[1])

    roots = []
    for r in a.root or default_roots():
        r = os.path.realpath(r) if os.path.exists(r) else r
        if r not in roots:
            roots.append(r)
    me, uid = os.getpid(), os.getuid()
    procs = table()
    kids = children_map(procs)

    # the instrument sees itself, or it may not say CLEAN
    self_info = files([me]).get(me, {})
    if me not in procs or not self_info.get("cwd"):
        print(f"BLIND: the sweep cannot see itself (in table: {me in procs}, cwd read: "
              f"{bool(self_info.get('cwd'))}) — no verdict")
        return 2

    print(f"== C0.3 process sweep (#172 S2) — session {a.session[:8] or '?'}, claude pid "
          f"{a.claude_pid or 'none'}")
    print(f"   roots: {', '.join(roots)}")
    own = set(ancestors(procs, me))
    tool_roots = []
    if a.claude_pid and a.claude_pid in procs:
        tool_roots = attached(procs, kids, a.claude_pid, me)
    elif a.claude_pid:
        print(f"   NOTE: claude pid {a.claude_pid} is not running — the ATTACHED half is skipped")
    else:
        print("   NOTE: no claude pid (not run from a Claude session) — the ATTACHED half is skipped")
    att_all = {q for r in tool_roots for q in subtree(kids, r)}
    cands = orphan_roots(procs, uid, own | att_all)
    info = files(sorted(set(cands) | att_all))
    orph = orphans(procs, cands, info, environ_sessions(cands), roots, a.session)
    declared = read_declared(a.declared)

    survivors = []  # (kind, root pid, label)
    for r in tool_roots:
        sess, tid = None, None
        for q in subtree(kids, r):
            sess, tid = task_label(info.get(q, {}))
            if tid:
                break
        survivors.append(("ATTACHED", r, f"tracked task {tid}" if tid else "tool call"))
    for p, sig, es in orph:
        sess, tid = task_label(info.get(p, {}))
        who = f"session {sess[:8]} task {tid}" if tid else (f"session {es[:8]}" if es else "session unknown")
        survivors.append(("ORPHAN", p, f"ppid 1, {who}, signals {'+'.join(sig)}, cwd {info.get(p, {}).get('cwd')}"))

    undeclared = 0
    for kind, r, label in survivors:
        pr = procs[r]
        why = declared.get((r, pr["lstart"]))
        tag = "DECLARED" if why else kind
        undeclared += 0 if why else 1
        print(f"{tag:9} {r} started {pr['lstart']} — {label}" + (f" — declared: {why}" if why else ""))
        for q in subtree(kids, r):
            depth = len(ancestors(procs, q)) - len(ancestors(procs, r))
            print(fmt(procs[q], depth))

    # the transcript's view: tracked tasks with no completion notification yet
    tpath = a.transcript
    if not tpath and a.session:
        slug = re.sub(r"[^A-Za-z0-9-]", "-", REPO)
        tpath = os.path.expanduser(f"~/.claude/projects/{slug}/{a.session}.jsonl")
    if tpath and not os.path.exists(tpath):
        print(f"   NOTE: transcript {tpath} not found — no OPEN TASK cross-check")
    elif tpath:
        sys.path.insert(0, HERE)
        import agentlib
        live_tids = {task_label(info.get(q, {}))[1] for q in att_all}
        for t in agentlib.tasks(tpath):
            if t["ended"] is None:
                state = "its process is alive" if t["id"] in live_tids else "no process holds its output"
                print(f"OPEN TASK {t['id']} (no completion notification; {state}) :: {t['description'] or t['command'][:80]}")

    n = len(survivors)
    if undeclared:
        # every pid of every undeclared subtree, LEAVES FIRST: killing only a tool shell
        # reparents its child to launchd — the orphan this tool exists to find (measured,
        # 14z-176: `$!` of `cd x && cmd &` is the subshell, and killing it left `cmd` alive)
        pids = []
        for k, r, _ in survivors:
            if not declared.get((r, procs[r]["lstart"])):
                pids += reversed(subtree(kids, r))
        print(f"SURVIVORS {n} ({undeclared} undeclared) — kill each (`kill {' '.join(map(str, pids))}`, then re-run) "
              f"or declare it: `python3 tools/agent/sweep.py --declare PID \"REASON\"`")
        return 1
    print(f"CLEAN: {n} survivor(s), every one declared" if n else "CLEAN: no survivor")
    return 0


if __name__ == "__main__":
    sys.exit(main())
