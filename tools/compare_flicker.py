#!/usr/bin/env python3
"""compare_flicker.py — checksum-log comparison with bounded flicker tolerance.

Instrument for the hooked-build legacy gate (CLAUDE.md §4 amendment, v2
refinement pending): cycle-skew from engine hooks can capture a state
transition one frame apart at input-accept/spawn boundaries, producing an
ISOLATED divergent frame (or two) after which the logs re-converge exactly
(measured: 03_two_player_vs frames 829/2093, 10_midattract_start 3007/3129,
16_xemu_2p 829 — single frames, full re-convergence, live bytes involved
are transition-latched state like $FF80B5 / object-slot heads). A real
behavior divergence in this deterministic engine propagates and never
re-converges to bit-identical whole-RAM, so bounded re-converging flickers
are a timing-phase signature, not a bug signature.

Verdicts (stdout, exit 0/1):
  EXACT                 logs identical
  FLICKER <n> <frames>  divergent stretches within tolerance, else identical
  FAIL <reason>         tolerance exceeded / persistent divergence / length

Tolerance (defaults from the session-7 measurements, deliberately tight):
  --max-stretch  2   max consecutive divergent frames per stretch
  --min-converge 60  frames that must match after a stretch (end of log ok)
  --max-total    8   max divergent frames overall
"""

import argparse
import sys


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("log_a")
    ap.add_argument("log_b")
    ap.add_argument("--max-stretch", type=int, default=2)
    ap.add_argument("--min-converge", type=int, default=60)
    ap.add_argument("--max-total", type=int, default=8)
    args = ap.parse_args()

    a = open(args.log_a).read().splitlines()
    b = open(args.log_b).read().splitlines()
    if len(a) != len(b):
        print(f"FAIL length mismatch ({len(a)} vs {len(b)} lines)")
        return 1

    bad = [i for i, (x, y) in enumerate(zip(a, b)) if x != y]
    if not bad:
        print("EXACT")
        return 0

    stretches = []
    for i in bad:
        if stretches and i == stretches[-1][1] + 1:
            stretches[-1][1] = i
        else:
            stretches.append([i, i])

    frames = [a[i].split()[0] for i in bad if a[i].split()]
    if len(bad) > args.max_total:
        print(f"FAIL {len(bad)} divergent frames > max-total {args.max_total} "
              f"(first at frame {frames[0]})")
        return 1
    for s, e in stretches:
        if e - s + 1 > args.max_stretch:
            print(f"FAIL stretch of {e - s + 1} frames at frame "
                  f"{a[s].split()[0]} > max-stretch {args.max_stretch}")
            return 1
    for (s, e), nxt in zip(stretches, stretches[1:] + [[len(a), len(a)]]):
        if nxt[0] - e - 1 < args.min_converge and nxt[0] != len(a):
            print(f"FAIL only {nxt[0] - e - 1} converged frames after frame "
                  f"{a[e].split()[0]} < min-converge {args.min_converge}")
            return 1

    print(f"FLICKER {len(bad)} {','.join(frames)}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
