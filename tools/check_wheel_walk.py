#!/usr/bin/env python3
"""check_wheel_walk.py — compare a measured select-cursor walk against the
sequence TABLE B predicts.

This is the half of the select-wheel verification that makes it a FACT
rather than a second reading of the same bytes: tools/select_wheel.py
generates an input script that visits every (cell, direction) pair and
states what each press must produce; the emulator runs it under
tests/lua/tap_writes.lua; this compares the two.

Checks, in order:
  1. every logged write to the cursor-cell byte comes from the commit PC
     (a write from anywhere else means something ELSE moves the cursor and
     the model is incomplete);
  2. the count of navigation writes equals the number of presses;
  3. the tap's frame numbering differs from the script's by a CONSTANT
     (derived, not assumed — the harness and the tap count frames from
     different points);
  4. every press produced exactly the predicted cell.

Usage:
  check_wheel_walk.py <tap.txt> <expect.json>
"""

import json
import sys


def parse_tap(path):
    """-> [(frame, pc, value)] for byte writes, in log order."""
    out = []
    for line in open(path):
        f = line.split()
        if not f or f[0] != "frame":
            continue          # END / PCHIST summary lines
        frame, pc = int(f[1]), int(f[3], 16)
        data, mask = int(f[7], 16), int(f[9], 16)
        out.append((frame, pc, data & 0xFF, mask))
    return out


def main():
    if len(sys.argv) != 3:
        print(__doc__)
        return 2
    tap_path, exp_path = sys.argv[1], sys.argv[2]
    exp = json.load(open(exp_path))
    commit_pc = exp["commit_pc"]
    presses = exp["presses"]

    hits = parse_tap(tap_path)
    nav = [h for h in hits if h[1] == commit_pc]
    other = [h for h in hits if h[1] != commit_pc]
    print("tap %s: %d writes total, %d from the commit PC 0x%06X"
          % (tap_path, len(hits), len(nav), commit_pc))

    errs = []
    # (1) anything else writing the cell byte during the walk window
    if presses:
        lo = presses[0]["frame"] - 5
        hi = presses[-1]["frame"] + 5
        intruders = [h for h in other if lo <= h[0] <= hi]
        for fr, pc, val, _ in intruders:
            errs.append("frame %d: cursor cell written from PC 0x%06X "
                        "(value %02X) — not the navigation commit site"
                        % (fr, pc, val))

    # (2) one navigation write per press
    if len(nav) != len(presses):
        errs.append("expected %d navigation writes (one per press), got %d"
                    % (len(presses), len(nav)))

    # (3) constant frame offset, derived from the first press
    off = None
    if nav and presses:
        off = nav[0][0] - presses[0]["frame"]
        print("frame offset (tap - script): %+d" % off)

    # (4) value agreement, press by press
    n = min(len(nav), len(presses))
    for i in range(n):
        fr, _, val, _ = nav[i]
        p = presses[i]
        if val != p["to"]:
            errs.append("press %d (frame %d, %02X -%s-> expected %02X): "
                        "measured %02X"
                        % (i, p["frame"], p["from"], p["dir_name"],
                           p["to"], val))
            break                      # first divergence is the bug report
        if off is not None and fr - p["frame"] != off:
            errs.append("press %d: frame offset %+d, expected %+d"
                        % (i, fr - p["frame"], off))
            break

    covered = {(p["from"], p["dir"]) for p in presses[:n]}
    print("verified %d presses, covering %d distinct (cell,direction) pairs"
          % (n, len(covered)))

    if errs:
        print("\nFAIL:")
        for e in errs[:10]:
            print("  " + e)
        return 1
    print("PASS: the measured cursor walk reproduces TABLE B exactly")
    return 0


if __name__ == "__main__":
    sys.exit(main())
