#!/usr/bin/env python3
"""static_pool.py — THE POOL of a parallel static tier (14z-207, GitHub #312; it replaces #299's `xargs -P`; token-aware
since #370, 14z-225).

N job slots. The queue starts as the tier's gates in registry order, each a `tests/lib/static_job.sh <g> ... gate` job.
When a gate's job ends and it left $W/pre/<g>.ctlq (the controls the runner's rule would execute), each control goes to
the FRONT of the queue as a job of its own. So a gate's controls start after the gate, never before it, and never wait
behind the gates still queued. WHAT MAY RUN BESIDE WHAT is the gate's `# SHARES:` line, through tests/lib/share_pool.py
(#370): a job holds its gate's registry tokens, and `self:<gate>` when the gate declares `self`, and starts only when no
running job holds one of its tokens — so the modes of a `self` gate run one after another, as the one "controls" job
of #312 ran them, and two gates holding one resource never overlap. Nothing here classifies: the runner reads the .run
files in registry order exactly as a serial run does.

Every job's start and end go to $W/pre/pool_<tier label>.tsv (kind, gate, control, slot, start, end, exit), and the last line of
stdout says how many jobs ran and how busy the slots were (job-seconds over slot-seconds). A job that exits non-zero is
recorded, not retried: static_job.sh exits 0 whatever its gate did.

usage: static_pool.py <jobs> <work dir> <exec-controls> <tier label> <gate>...
"""
import os, subprocess, sys, time

sys.path[:0] = [os.path.join(os.getcwd(), "tests", "lib"), os.path.dirname(os.path.abspath(__file__))]
import share_pool   # noqa: E402   (the repo's own, from the cwd: a shadow copy of this file elsewhere still finds it)

jobs, W, X, L = int(sys.argv[1]), sys.argv[2], sys.argv[3], sys.argv[4]
gates = sys.argv[5:]
pre = os.path.join(W, "pre")
os.makedirs(pre, exist_ok=True)
log = open(os.path.join(pre, "pool_%s.tsv" % L), "w", encoding="utf-8", newline="\n")   # one log a tier: both tiers share $W
err = open(os.path.join(pre, "jobs.err"), "a", encoding="utf-8", newline="\n")
t0 = time.time(); stats = {"busy": 0.0, "n": 0}
TOK = {}


def toks(g):
    if g not in TOK:
        TOK[g] = share_pool.tokens(os.path.join("tests", g + ".sh"), g)   # POOL-TOKENS
    return TOK[g]


def argv(task):
    kind, g, c = task[0]
    base = ["sh", "tests/lib/static_job.sh", g, W, X, L]
    return base + (["gate"] if kind == "gate" else ["control", c])


def start(task, slot):
    return subprocess.Popen(argv(task), stdin=subprocess.DEVNULL, stderr=err)


def queue_controls(pool, g):   # POOL-CONTROLS-FIRST: a finished gate's controls go to the front of the queue
    q = os.path.join(pre, g + ".ctlq")
    if not os.path.exists(q):
        return
    lines = [l.strip() for l in open(q, encoding="utf-8") if l.strip()]
    for c in reversed(lines[1:]):   # POOL-CONTROL-JOBS: one job each; `self` keeps a gate's modes apart (#370)
        pool.queue.appendleft((("control", g, c), toks(g), None))


def done(task, rc, slot, start_t, end_t):
    kind, g, c = task[0]
    stats["busy"] += end_t - start_t; stats["n"] += 1
    log.write("%s\t%s\t%s\t%d\t%.2f\t%.2f\t%d\n" % (kind, g, c, slot, start_t - t0, end_t - t0, rc))
    if kind == "gate":
        queue_controls(pool, g)


pool = share_pool.Pool(jobs, start, done)
for g in gates:
    pool.queue.append((("gate", g, ""), toks(g), None))   # POOL-GATES
pool.run()
wall = time.time() - t0
log.close(); err.close()
print("pool: %d job(s) in %d slot(s), %.0f s; job-seconds %.0f, slots busy %.1f of %d on average"
      % (stats["n"], jobs, wall, stats["busy"], stats["busy"] / wall if wall else 0.0, jobs))
