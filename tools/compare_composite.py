#!/usr/bin/env python3
"""compare_composite.py — the CONJUNCTION of two already-ratified §4
comparison classes, for replays whose masked comparison shows both.

STATUS: PROPOSED, awaiting maintainer ratification (STATE 14z-61). Nothing
validates against it until a `.pending` expectation is turned into a
`composite` one, which is a maintainer decision.

WHY IT EXISTS. On the WIDE reference build every select-reaching legacy
replay measures as:

    the frozen hook-flicker inventory (unchanged, isolated <=2-frame
    divergences)  +  ONE bounded, fully re-convergent window per select
    screen ENTRY

Both halves are already ratified — `flicker` (§4 v2) and `window` (§4 v3) —
but no single class can express their conjunction, so those replays cannot
be frozen without either a new class or a fudge. Measured decomposition
(14z-61): every flicker frame matches donovan-m2c's frozen inventory
EXACTLY, not one added or missing; the windows are the wheel extension.

This class is STRICTER than either component alone: every divergent run
must be accounted for by name, the flicker set must match exactly, the
window list must match exactly, and the run must fully re-converge. It
tolerates nothing that `flicker` and `window` do not each tolerate.

Usage:
  compare_composite.py <base.log> <new.log> --flicker 829,2093 \\
      --windows 890-1802 [--reconverge 60]

  --flicker '-'  for none; --windows '-' for none (then use the plain class).
Exit 0 only if every clause holds.
"""

import argparse
import sys

FLICKER_MAX = 2          # a run longer than this is not flicker (§4 v2)


def load(path):
    out = []
    for line in open(path):
        line = line.strip()
        if not line or line.startswith("END"):
            continue
        f = line.split()
        if len(f) >= 2:
            out.append((int(f[0]), f[1]))
    return out


def parse_windows(spec):
    if spec in ("-", ""):
        return []
    out = []
    for part in spec.split(";"):
        lo, hi = part.split("-")
        out.append((int(lo), int(hi)))
    return out


def parse_flicker(spec):
    if spec in ("-", ""):
        return []
    return [int(x) for x in spec.split(",")]


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("a")
    ap.add_argument("b")
    ap.add_argument("--flicker", required=True,
                    help="frozen flicker frames, comma separated, or '-'")
    ap.add_argument("--windows", required=True,
                    help="frozen windows 'onset-end[;onset-end...]', or '-'")
    ap.add_argument("--reconverge", type=int, default=60,
                    help="minimum identical frames after the last run")
    args = ap.parse_args()

    want_flicker = parse_flicker(args.flicker)
    want_windows = parse_windows(args.windows)
    a, b = load(args.a), load(args.b)
    # 14z-90 (issue #3): see tools/compare_window.py — min() certified a
    # truncated run as fully re-convergent over frames it never compared.
    if len(a) != len(b):
        print(f"FAIL: length mismatch ({len(a)} vs {len(b)} frames) — a short "
              f"log cannot be compared against a prefix of the basis")
        return 1
    n = len(a)
    if n == 0:
        print("FAIL: empty log(s)")
        return 1

    diff = [i for i in range(n) if a[i] != b[i]]
    errs = []
    if not diff:
        print("note: the logs are bit-identical, so the expected shape did "
              "not occur.")
        print("\nFAIL:\n  expected %d flicker frame(s) and %d window(s), found "
              "no divergence at all — this expectation asserts they EXIST, so "
              "identity means something changed"
              % (len(want_flicker), len(want_windows)))
        return 1

    # split into contiguous runs, then classify each by LENGTH only — the
    # frozen lists decide whether the right ones are in the right places.
    runs, start = [], diff[0]
    for i in range(1, len(diff)):
        if diff[i] != diff[i - 1] + 1:
            runs.append((start, diff[i - 1]))
            start = diff[i]
    runs.append((start, diff[-1]))

    got_flicker, got_windows = [], []
    for lo, hi in runs:
        if hi - lo + 1 <= FLICKER_MAX:
            got_flicker.extend(a[i][0] for i in range(lo, hi + 1))
        else:
            got_windows.append((a[lo][0], a[hi][0]))

    tail = n - diff[-1] - 1
    print("divergent frames %d in %d run(s): flicker %s, windows %s, "
          "%d identical after"
          % (len(diff), len(runs),
             ",".join(str(f) for f in got_flicker) or "-",
             ";".join("%d-%d" % w for w in got_windows) or "-", tail))

    if got_flicker != want_flicker:
        errs.append("flicker frames %s, frozen expectation %s"
                    % (got_flicker or "-", want_flicker or "-"))
    if got_windows != want_windows:
        errs.append("windows %s, frozen expectation %s"
                    % (["%d-%d" % w for w in got_windows] or "-",
                       ["%d-%d" % w for w in want_windows] or "-"))
    if tail < args.reconverge:
        errs.append("only %d identical frames after the last run; the class "
                    "requires >= %d (re-convergence is the point, and its "
                    "absence would mean match state was touched)"
                    % (tail, args.reconverge))

    if errs:
        print("\nFAIL:")
        for e in errs:
            print("  " + e)
        return 1
    print("PASS: frozen flicker inventory + frozen window list, nothing else, "
          "fully re-convergent")
    return 0


if __name__ == "__main__":
    sys.exit(main())
