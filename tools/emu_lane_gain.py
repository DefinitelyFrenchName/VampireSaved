#!/usr/bin/env python3
"""emu_lane_gain.py <run dir> — the emulator tier's parallel gain per lane, from a
tests/run_all_emulator.sh run directory (14z-189, #133).

WORK is the sum of the lane's gate seconds (results.tsv `seconds`); WALL runs from the
lane's first gate START to its last gate END, where a gate's END is its log file's mtime
(`<gate>.log`, written until the gate exits) and its START is END minus its seconds; GAIN is
WORK / WALL. The whole tier's wall runs from the first start to the last end of any lane.
Control rows (`<gate>@<control>`, --controls) count in their gate's lane; each has its own
log `<gate>@<control>.log` when the runner wrote one, and is skipped (named) when it has none.

Prints one line per lane — gates, work, wall, gain, the three longest gates and the verdict
counts — then the whole tier, then the run's commit (commit.txt, first line). Reads only the
run directory. The figures are only as good as the log mtimes: a log touched after its gate
ended (a copy, an rsync without -t) moves END, so read the run where it ran.
"""
import collections, os, sys


def main(d):
    rows = [l.rstrip("\n").split("\t") for l in open(os.path.join(d, "results.tsv"))]
    head, rows = rows[0], rows[1:]
    ix = {k: i for i, k in enumerate(head)}
    lanes = collections.OrderedDict()
    allspan, skipped = [], []
    for r in rows:
        gate, lane, verdict, secs = r[ix["gate"]], r[ix["lane"]], r[ix["verdict"]], r[ix["seconds"]]
        log = os.path.join(d, gate + ".log")
        if not os.path.exists(log) or not secs.isdigit():
            skipped.append(gate)
            continue
        end = os.path.getmtime(log); s = int(secs)
        L = lanes.setdefault(lane, {"work": 0, "spans": [], "gates": [], "v": collections.Counter()})
        L["work"] += s; L["spans"].append((end - s, end)); L["gates"].append((s, gate)); L["v"][verdict] += 1
        allspan.append((end - s, end))
    tw = 0
    for lane, L in lanes.items():
        wall = max(e for _, e in L["spans"]) - min(b for b, _ in L["spans"])
        tw += L["work"]
        top = ", ".join(f"{g} {s}s" for s, g in sorted(L["gates"], reverse=True)[:3])
        gain = L["work"] / wall if wall else 0.0
        print(f"{lane:8} gates {len(L['gates']):3} work {L['work']:8d} s  wall {wall:7.0f} s  gain {gain:5.2f}x  "
              f"longest {top}  verdicts {dict(L['v'])}")
    if allspan:
        wall = max(e for _, e in allspan) - min(b for b, _ in allspan)
        print(f"whole tier: work {tw} s, wall {wall:.0f} s ({wall / 3600:.2f} h), gain {tw / wall:.2f}x")
    if skipped:
        print(f"no log or no seconds (not counted): {len(skipped)}: {' '.join(skipped)}")
    c = os.path.join(d, "commit.txt")
    if os.path.exists(c):
        print("commit " + open(c).readline().strip())


if __name__ == "__main__":
    if len(sys.argv) != 2:
        sys.exit(__doc__)
    main(sys.argv[1])
