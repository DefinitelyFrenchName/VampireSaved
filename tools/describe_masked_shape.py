#!/usr/bin/env python3
"""describe_masked_shape.py — the measured shape of a masked divergence, and a
PROPOSED expectation line in the ratified vocabulary (CLAUDE.md §4).

Lifted verbatim out of the `describe.py` heredoc that lived inside
tests/audit_merged_legacy.sh (14z-81..88) when a second caller appeared
(tests/audit_legacy_pairings.sh / the 14z-89 promotion work): one classifier,
one set of thresholds, one place to correct. Behaviour is unchanged — the
merged audit now calls this file instead of writing its own copy.

Thresholds are the comparators' own, and must stay in step with them:
  flicker run length  <= 2   (tools/compare_composite.py FLICKER_MAX)
  re-convergence tail >= 60  (compare_window.py / compare_flicker.py default)

Frames are read from the log's FIRST COLUMN, which is compare_window.py's
convention (onset/end are frame numbers, end = last divergent frame,
INCLUSIVE), so a proposed line drops into a .masked spec verbatim.

This proposes; it never ratifies. A shape that does not re-converge is NOT
expressible in the vocabulary and is reported as such — that is the replay-38
signature (a legacy pairing losing a main-loop iteration, 14z-88), and it must
be root-caused, never absorbed into a widened tolerance.

Usage: describe_masked_shape.py <base.log> <new.log> [--basis vsavj/masked-v2]
"""

import argparse
import sys

FLICKER_MAX = 2      # a divergent run this short or shorter is a flicker frame
RECONVERGE = 60      # identical frames required after the last divergence


def load(path):
    out = []
    for line in open(path):
        f = line.split()
        if not f or f[0] == "END":
            continue
        if len(f) >= 2:
            out.append((int(f[0]), f[1]))
    return out


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("base")
    ap.add_argument("new")
    ap.add_argument("--basis", default="vsavj/masked-v2",
                    help="basis path fragment written into the proposed line")
    args = ap.parse_args()

    a, b = load(args.base), load(args.new)
    n = min(len(a), len(b))
    note = "" if len(a) == len(b) else " [LENGTH MISMATCH %d vs %d]" % (len(a), len(b))
    d = [i for i in range(n) if a[i] != b[i]]
    if not d:
        print("shape: bit-identical%s" % note)
        print("proposed: exact %s -" % args.basis)
        return 0

    runs, s, p = [], d[0], d[0]
    for i in d[1:]:
        if i != p + 1:
            runs.append((s, p))
            s = i
        p = i
    runs.append((s, p))
    tail = n - 1 - runs[-1][1]
    fr = lambda i: a[i][0]                       # index -> frame number
    flick = [r for r in runs if r[1] - r[0] + 1 <= FLICKER_MAX]
    wins = [r for r in runs if r[1] - r[0] + 1 > FLICKER_MAX]
    print("shape: %d/%d frames differ in %d run(s), first at frame %d, last ends "
          "frame %d, then %d identical%s" % (len(d), n, len(runs), fr(runs[0][0]),
                                             fr(runs[-1][1]), tail, note))
    print("runs: " + " ".join("%d-%d" % (fr(x), fr(y)) for x, y in runs))
    # 14z-90 (GitHub issue #53): was `tail <= RECONVERGE`, so the PROPOSER
    # refused a tail of exactly 60 while the ENFORCER (compare_window)
    # accepts it — §4 says ">= 60". One character, and it made the tool
    # that writes expectations disagree with the tool that checks them.
    if tail < RECONVERGE:
        print("proposed: NONE — does not re-converge (>=%d identical tail "
              "required); this is not expressible in the ratified vocabulary "
              "and must be root-caused" % RECONVERGE)
    elif not wins:
        print("proposed: flicker %s %d %s"
              % (args.basis, len(d), ",".join(str(fr(i)) for i in d)))
    elif not flick:
        print("proposed: window %s %d %d" % (args.basis, fr(wins[0][0]), fr(wins[0][1]))
              if len(wins) == 1 else
              "proposed: composite %s - " % args.basis +
              ";".join("%d-%d" % (fr(x), fr(y)) for x, y in wins))
    else:
        print("proposed: composite %s %s %s"
              % (args.basis,
                 ",".join(str(fr(i)) for r in flick for i in range(r[0], r[1] + 1)),
                 ";".join("%d-%d" % (fr(x), fr(y)) for x, y in wins)))
    return 0


if __name__ == "__main__":
    sys.exit(main())
