#!/usr/bin/env python3
"""trace_static_reads.py — SCORE THE --confirm PREDICTOR ON WHAT EVERY STATIC GATE ACTUALLY READS (GitHub #225, 14z-191).

    python3 tools/trace_static_reads.py trace --out DIR [--jobs N] [--timeout S] [--gates FILE]     (Linux, strace)
    python3 tools/trace_static_reads.py score --traces DIR [--tools DIR] [--jobs N]
    python3 tools/trace_static_reads.py control --traces DIR [--jobs N]
    python3 tools/trace_static_reads.py all --out DIR [--jobs N] [--timeout S] [--tools DIR]       (the one command)

WHY. `tools/static_confirm.py` decides which static gates a change leaves STALE and which a `--confirm` run may
CARRY (#188). A gate it carries wrongly is a gate that did not re-run on a change it reads — a green that measured
nothing. The only evidence that a narrowing of its rules is safe is a TRACE of what every gate really opens: #188's
option B as first built missed 15 traced reads in 2 gates (14z-190), which no review of the rules had shown. That
trace was rebuilt as scratch twice (ERIS 14z-187b/188, PILOT 14z-190); this is it, promoted.

WHAT EACH STEP DOES.
  trace    every gate `tools/static_confirm.py registry` names, run as `sh tests/<gate>.sh` under
           `strace -f -e trace=open,openat,execve`, N at a time, each capped (default 1,800 s); writes DIR/st/<gate>.st,
           DIR/gates.txt, DIR/head.txt (the HEAD traced) and DIR/done.tsv (gate, exit status, seconds). Run it on the
           commit whose predictor is to be scored, with ROMDIR set (a gate that SKIPs reads less).
  score    for every traced gate, every repo file it OPENED for reading — tracked, or untracked and not ignored (the
           predictor's input is the change set, never an ignored file) — must make the predictor mark the gate STALE,
           judged as `predict()` judges a changed path, by the predictor's own functions: `change_reason` (the change
           set's drop of the session scratch, N-D, #274; a run record no change for a reach that reads none,
           N-F-CHANGE; then `stale_reason`) or R4 for that path (`whole_covers`). A read it does not flag is a MISS.
           Until 14z-206 (#286) the scorer called `stale_reason` itself and never applied N-F-CHANGE, so a run-record
           read the predictor carries was invisible (rule-checker run 2026-10-20-1156); a predictor without those three
           functions is REFUSED. The predictor is imported from --tools (default: this tree's tools/), so the same
           traces score any version of it from 14z-206 on. Exit 1 on a miss. The gates that exited non-zero under the trace are NAMED: their reads may be short of a passing run's.
  control  the same traces scored by a deliberately OVER-NARROWED copy of this tree's predictor (N-A at every depth
           under build/, N-B on every basename, R6's directory templates off), which MUST miss: a scorer that cannot
           find a miss there is blind, and its clean score elsewhere means nothing. Exit 0 when the control fired.
  all      trace, then score, then control; exit 0 only when the score is clean AND the control fired.

LIMITS (as the scratch versions'). A call strace split into `<unfinished ...>` and `<... resumed>` lines is re-joined
(#283, 14z-202); before that, every split open was unscored. Reads are judged by path only. A RELATIVE path counts as repo-relative only if it
exists at the repo root (strace prints no cwd). A gate that exited non-zero (a missing prerequisite on the tracing
host) may have read less than a passing run. A file read only through a process strace did not follow is unseen.
Gate: tests/test_trace_static_reads.sh (the scorer and the control on synthetic traces; no strace needed).
"""
import argparse
import multiprocessing as mp
import os
import re
import shutil
import subprocess
import sys
import tempfile
import time

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
# NAMED LIMITS (#281, 14z-207): gates this tracer cannot drive. `trace` does not run them under strace and writes a
# <gate>.limit marker instead; `score` names each one on its own line, so an untraced gate is never silent. Every reason
# names its ticket (tests/test_trace_static_reads.sh holds that).
TRACE_LIMITS = {
    "test_applier_page_browser": "#281: under strace -f, Chrome never opens the page's file:// ROM reads and the driver "
                                 "stalls after asks_for (PILOT, Chrome for Testing 155, 14z-207: 8 s at virtual-time "
                                 "budgets of 1.8e6, 1.8e7 and 1.8e8 ms; the same run untraced PASSES in 19 s)",
}
OPEN = re.compile(r'^\d+\s+(open|openat|execve)\((?:AT_FDCWD, )?"([^"]+)"(?:, ([A-Z_|]+))?.*\)\s+=\s+(-?\d+)')
# #283 (14z-202): with several processes writing one file, strace SPLITS a call another process interrupts into
# `PID call(args <unfinished ...>` and, later, `PID <... call resumed>) = rc`. Neither line matches OPEN, so every split
# open was unscored (2,513 of 66,463 open lines at 5648e530, 3,784 of 89,228 at 344ebc5e; measured 14z-201). The two
# halves are re-joined by (pid, call) before OPEN reads them.
UNFINISHED = re.compile(r'^(\d+)\s+(open|openat|execve)\((.*) <unfinished \.\.\.>\s*$')
RESUMED = re.compile(r'^(\d+)\s+<\.\.\. (open|openat|execve) resumed>(.*)$')
# the over-narrowing that makes the control (each line must exist verbatim in the predictor, or the control REFUSES)
OVER_NARROW = (
    ("        if k == 1 and parts[0] in NARROW_R3_TOP:   # N-A", "        if parts[0] in NARROW_R3_TOP:   # CONTROL over-narrowed"),
    ("    if bpat and base in NARROW_R2:   # N-B", "    if bpat:   # CONTROL over-narrowed"),
    ('                tail = r"(?:/.*)?$" if PLACE.fullmatch(parts[-1]) else r"$"   # R6 directory template',
     '                tail = r"$"   # CONTROL R6 directory templates off'),
)


def load_predictor(tools):
    sys.path.insert(0, tools)
    for m in ("static_confirm", "battery_reach", "build_dirs"):
        sys.modules.pop(m, None)
    import static_confirm as sc  # noqa: E402
    import battery_reach as br   # noqa: E402
    sys.path.pop(0)
    return sc, br


def repo_files(root):
    out = set()
    for args in (["ls-files"], ["ls-files", "--others", "--exclude-standard"]):
        out |= set(subprocess.run(["git", "-C", root] + args, capture_output=True, text=True, check=True).stdout.split("\n"))
    out.discard("")
    return out


def joined(lines):
    """strace's lines with every split call re-joined (#283): the `<unfinished ...>` half held by (pid, call) until its
    `<... call resumed>` half arrives; an unpaired half is dropped, as it was before."""
    held = {}
    for line in lines:
        line = line.rstrip("\n")
        m = UNFINISHED.match(line)
        if m:
            held[(m.group(1), m.group(2))] = m.group(3)
            continue
        m = RESUMED.match(line)
        if m:
            k = (m.group(1), m.group(2))
            if k in held:
                yield f"{m.group(1)} {m.group(2)}({held.pop(k)}{m.group(3)}"
            continue
        yield line


def reads_of(root, st, files):
    """the repo files a trace opened for reading, and how many came from a relative path"""
    reads, rel = set(), 0
    for line in joined(open(st, errors="replace")):   # SPLIT-PAIRED (#283)
        m = OPEN.match(line)
        if not m:
            continue
        kind, p, flags, rc = m.group(1), m.group(2), m.group(3) or "", int(m.group(4))
        if rc < 0 or (kind != "execve" and re.search(r"O_WRONLY|O_CREAT|O_TRUNC", flags)):
            continue
        if p.startswith(root + "/"):
            rp = os.path.normpath(p[len(root) + 1:])
        elif not p.startswith("/") and os.path.exists(os.path.join(root, p)):
            rp = os.path.normpath(p); rel += 1
        else:
            continue
        if rp in files:
            reads.add(rp)
    return reads, rel


_W = {}


def judged(tools):
    """REFUSED for a predictor older than its shared judgment (14z-206): scoring it by stale_reason alone would hide
    every read N-F-CHANGE carries, the blind spot rule-checker run 2026-10-20-1156 found"""
    s = open(os.path.join(tools, "static_confirm.py")).read()
    missing = [f for f in ("change_reason", "runs_reader", "whole_covers") if f"\ndef {f}(" not in s]
    if missing:
        sys.exit(f"REFUSED: the predictor in {tools} has no {', '.join(missing)}: it predates the scorer's shared "
                 "judgment (14z-206, #286); score it with the scorer of its own commit, and say that one cannot see N-F-CHANGE")


def _init(root, tools, traces):
    os.chdir(root)
    sc, br = load_predictor(tools)
    _W.update(root=root, traces=traces, sc=sc, files=repo_files(root), idx=br.index(root, []))


def _score_one(g):
    root, sc = _W["root"], _W["sc"]
    st = os.path.join(_W["traces"], "st", g + ".st")
    if not os.path.exists(st):
        return g, None, [], 0
    reads, rel = reads_of(root, st, _W["files"])
    rch = sc.reach(root, g, _W["idx"])
    blob = "\n".join(sc.text(root, p) for p in rch)
    # each read judged as predict() judges a changed path, by the predictor's own functions (14z-206, #286): N-D, N-F-
    # CHANGE and stale_reason (change_reason), R4 per path (whole_covers)
    judge = sc.change_reason
    reader = sc.runs_reader(root, rch, blob)
    miss = [c for c in sorted(reads) if not (sc.whole_covers(blob, c) or judge(root, rch, blob, c, sc.patterns(c), reader))]
    return g, len(reads), miss, rel


def score(root, traces, tools, jobs, label):
    judged(tools)
    gates =[g.strip() for g in open(os.path.join(traces, "gates.txt")) if g.strip()]
    with mp.Pool(jobs, initializer=_init, initargs=(root, tools, traces)) as pool:
        res = pool.map(_score_one, gates, chunksize=1)
    traced = sum(1 for r in res if r[1] is not None)
    pairs = sum(r[1] or 0 for r in res)
    misses = [(g, c) for g, _, m, _ in res for c in m]
    head = open(os.path.join(traces, "head.txt")).read().strip() if os.path.exists(os.path.join(traces, "head.txt")) else "?"
    print(f"== {label}: predictor from {tools}")
    print(f"traces {traces} (head {head}); gates traced {traced} of {len(gates)}; (gate, file read) pairs {pairs}; "
          f"relative-path opens resolved at the root {sum(r[3] for r in res)}")
    done = os.path.join(traces, "done.tsv")
    if os.path.exists(done):
        bad = [l.split("\t")[:2] for l in open(done) if l.strip() and l.split("\t")[1] not in ("0", "LIMIT")]
        if bad:
            print("non-zero under the trace (their reads may be short of a passing run's): "
                  + ", ".join(f"{g} ({rc})" for g, rc in bad))
    for g in gates:   # the named limits (#281): not traced, so not scored, and said so
        lim = os.path.join(traces, "st", g + ".limit")
        if os.path.exists(lim):
            print(f"NOT TRACED (named limit)\t{g}\t{open(lim).read().strip()}")
    print(f"MISSES {len(misses)} in {len({g for g, _ in misses})} gates")
    for g, c in misses:
        print(f"MISS\t{g}\t{c}")
    return misses, pairs


def control_tools(root, dest):
    """a copy of this tree's predictor, over-narrowed (the control); REFUSED if a perturbation point moved"""
    os.makedirs(dest, exist_ok=True)
    shutil.copy(os.path.join(root, "tools", "battery_reach.py"), dest)
    sys.path.insert(0, os.path.join(root, "tools"))
    sys.modules.pop("build_dirs", None)
    import build_dirs   # #304: the planner generates N-D from the build-dir list; the copy takes it along
    sys.path.pop(0)
    build_dirs.copy_beside(dest)
    s = open(os.path.join(root, "tools", "static_confirm.py")).read()
    for a, b in OVER_NARROW:
        if s.count(a) != 1:
            sys.exit(f"REFUSED: the control's perturbation point moved in tools/static_confirm.py: {a.strip()!r}")
        s = s.replace(a, b)
    open(os.path.join(dest, "static_confirm.py"), "w").write(s)
    return dest


def trace(root, out, jobs, timeout, gates_file):
    if not shutil.which("strace"):
        sys.exit("REFUSED: strace not found — the trace runs on Linux (PILOT); score and control run anywhere")
    os.makedirs(os.path.join(out, "st"), exist_ok=True)
    sc, _ = load_predictor(os.path.join(root, "tools"))
    gates = [g.strip() for g in open(gates_file)] if gates_file else sorted(set(sc.registry(root)))
    gates = [g for g in gates if g]
    open(os.path.join(out, "gates.txt"), "w").write("\n".join(gates) + "\n")
    head = subprocess.run(["git", "-C", root, "rev-parse", "HEAD"], capture_output=True, text=True).stdout.strip()
    open(os.path.join(out, "head.txt"), "w").write(head + "\n")
    print(f"trace: {len(gates)} gates at {head}, {jobs} at a time, cap {timeout} s")
    done = open(os.path.join(out, "done.tsv"), "w")
    running, queue = [], list(gates)
    while queue or running:
        while queue and len(running) < jobs:
            g = queue.pop(0)
            if g in TRACE_LIMITS:   # a named limit: not traced, marked
                open(os.path.join(out, "st", g + ".limit"), "w").write(TRACE_LIMITS[g] + "\n")
                done.write(f"{g}\tLIMIT\t0\n"); done.flush()
                continue
            st, log = os.path.join(out, "st", g + ".st"), open(os.path.join(out, "st", g + ".out"), "w")
            p = subprocess.Popen(["timeout", "-k", "30", str(timeout), "strace", "-f", "-qq", "-e", "trace=open,openat,execve",
                                  "-o", st, "sh", f"tests/{g}.sh"], cwd=root, stdout=log, stderr=subprocess.STDOUT,
                                 stdin=subprocess.DEVNULL)
            running.append((g, p, time.time(), log))
        time.sleep(1)
        for r in list(running):
            g, p, t0, log = r
            if p.poll() is not None:
                log.close(); running.remove(r)
                done.write(f"{g}\t{p.returncode}\t{int(time.time() - t0)}\n"); done.flush()
    done.close()
    print(f"TRACE DONE {len(gates)}")


def main():
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("step", choices=("trace", "score", "control", "all"))
    ap.add_argument("--root", default=REPO)
    ap.add_argument("--out", help="trace output dir (trace, all)")
    ap.add_argument("--traces", help="a trace dir (score, control)")
    ap.add_argument("--tools", help="the predictor to score (default: <root>/tools)")
    ap.add_argument("--jobs", type=int, default=6)
    ap.add_argument("--timeout", type=int, default=1800)
    ap.add_argument("--gates", help="a file of gate names (default: the registry)")
    a = ap.parse_args()
    root = os.path.abspath(a.root)
    tools = os.path.abspath(a.tools) if a.tools else os.path.join(root, "tools")
    traces = os.path.abspath(a.traces or a.out or "")
    if a.step in ("trace", "all"):
        if not a.out:
            sys.exit("REFUSED: trace needs --out DIR")
        trace(root, traces, a.jobs, a.timeout, a.gates)
    elif not a.traces:
        sys.exit(f"REFUSED: {a.step} needs --traces DIR")
    rc = 0
    if a.step in ("score", "all"):
        misses, pairs = score(root, traces, tools, a.jobs, "score")
        if pairs == 0:
            print("FAIL: no (gate, file read) pair was scored — an empty measurement"); rc = 1
        elif misses:
            print(f"FAIL: the predictor misses {len(misses)} traced read(s)"); rc = 1
        else:
            print("PASS: every traced read makes its gate STALE")
    if a.step in ("control", "all"):
        with tempfile.TemporaryDirectory() as d:
            cmiss, _ = score(root, traces, control_tools(root, d), a.jobs, "control (over-narrowed)")
        if cmiss:
            print(f"CONTROL FIRED: over-narrowed — the over-narrowed predictor misses {len(cmiss)} traced read(s)")
        else:
            print("CONTROL DEAD: over-narrowed — the over-narrowed predictor misses nothing: the scorer is blind"); rc = 1
    return rc


if __name__ == "__main__":
    sys.exit(main())
