#!/usr/bin/env python3
"""projectile_census.py — which PROJECTILE-POOL types a rig's events spawn
(character-data map phase 3, 14z-120 (11)).

  python3 tools/projectile_census.py <schedule.json> <field_trace.txt>

The trace samples the 32 pool slots' type bytes ($FF9400 + n*0x100 + 2,
fields t00..t31) per frame. For each schedule event a type counts only if
it FIRST appears after the event's input (a type alive at the event start
is scenery). One line per event with a spawn:  <part>\t<event>\t<type>:slot:+first..+last ...
"""
import json
import sys


def census(sched_path, trace_path):
    sched = json.load(open(sched_path))
    rows = {}
    for line in open(trace_path):
        f = line.split()
        if len(f) < 3 or f[0] != "F":
            continue
        rows[int(f[1])] = {k: int(x) for k, x in (kv.split("=") for kv in f[2:])}
    out = []
    for e in sched["events"]:
        if e["name"].startswith("walk-in"):
            continue
        t0, t1 = e["frame"], e["frame"] + e["gap"]
        seen = {}
        for fr in range(t0, t1):
            v = rows.get(fr)
            if not v:
                continue
            for s in range(32):
                ty = v.get(f"t{s:02d}", 0)
                if ty:
                    seen.setdefault(ty, [s, fr, fr]); seen[ty][2] = fr
        new = {ty: (sl, a - t0, b - t0) for ty, (sl, a, b) in seen.items() if a > t0}
        if new:
            out.append(f"{sched['part']}\t{e['name']}\t" + " ".join(f"{ty:#04x}:{sl}:+{a}..+{b}" for ty, (sl, a, b) in sorted(new.items())))
    return out


if __name__ == "__main__":
    print("\n".join(census(sys.argv[1], sys.argv[2])))
