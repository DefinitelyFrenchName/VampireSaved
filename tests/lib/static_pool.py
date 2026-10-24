#!/usr/bin/env python3
"""static_pool.py — THE POOL of a parallel static tier (14z-207, GitHub #312; it replaces #299's `xargs -P`).

N job slots. The queue starts as the tier's gates in registry order, each a `tests/lib/static_job.sh <g> ... gate` job.
When a gate's job ends and it left $W/pre/<g>.ctlq (the controls the runner's rule would execute), its controls go to
the FRONT of the queue: one job per control when the gate is listed in tests/controls_concurrent.txt, otherwise one job
running them one after another (as before #312). So a gate's controls start after the gate, never before it, and never
wait behind the gates still queued. Nothing here classifies: the runner reads the .run files in registry order exactly
as a serial run does.

Every job's start and end go to $W/pre/pool_<tier label>.tsv (kind, gate, control, slot, start, end, exit), and the last line of
stdout says how many jobs ran and how busy the slots were (job-seconds over slot-seconds). A job that exits non-zero is
recorded, not retried: static_job.sh exits 0 whatever its gate did.

usage: static_pool.py <jobs> <work dir> <exec-controls> <tier label> <gate>...
"""
import collections, os, subprocess, sys, time

jobs, W, X, L = int(sys.argv[1]), sys.argv[2], sys.argv[3], sys.argv[4]
gates = sys.argv[5:]
pre = os.path.join(W, "pre")
os.makedirs(pre, exist_ok=True)
queue = collections.deque(("gate", g, "") for g in gates)
running = {}                       # slot -> (Popen, task, start)
free = list(range(jobs))
log = open(os.path.join(pre, "pool_%s.tsv" % L), "w", encoding="utf-8", newline="\n")   # one log a tier: both tiers share $W
err = open(os.path.join(pre, "jobs.err"), "a", encoding="utf-8", newline="\n")
t0 = time.time(); busy = 0.0; n = 0


def argv(task):
    kind, g, c = task
    base = ["sh", "tests/lib/static_job.sh", g, W, X, L]
    return base + (["gate"] if kind == "gate" else ["control", c] if kind == "control" else ["controls"])


def queue_controls(g):   # POOL-CONTROLS-FIRST: a finished gate's controls go to the front of the queue
    q = os.path.join(pre, g + ".ctlq")
    if not os.path.exists(q):
        return
    lines = [l.strip() for l in open(q, encoding="utf-8") if l.strip()]
    if len(lines) < 2:
        return
    if lines[0] == "concurrent":   # POOL-CONCURRENT
        for c in reversed(lines[1:]):
            queue.appendleft(("control", g, c))
    else:
        queue.appendleft(("controls", g, ""))


while queue or running:
    while queue and free:
        task = queue.popleft(); slot = free.pop(0)
        p = subprocess.Popen(argv(task), stdin=subprocess.DEVNULL, stderr=err)
        running[slot] = (p, task, time.time())
    time.sleep(0.05)
    for slot, (p, task, start) in list(running.items()):
        rc = p.poll()
        if rc is None:
            continue
        end = time.time(); busy += end - start; n += 1
        log.write("%s\t%s\t%s\t%d\t%.2f\t%.2f\t%d\n" % (task[0], task[1], task[2], slot, start - t0, end - t0, rc))
        del running[slot]; free.append(slot); free.sort()
        if task[0] == "gate":
            queue_controls(task[1])
wall = time.time() - t0
log.close(); err.close()
print("pool: %d job(s) in %d slot(s), %.0f s; job-seconds %.0f, slots busy %.1f of %d on average"
      % (n, jobs, wall, busy, busy / wall if wall else 0.0, jobs))
