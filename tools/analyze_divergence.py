#!/usr/bin/env python3
"""analyze_divergence.py — classify a divergence between two checksum logs.

    python3 tools/analyze_divergence.py <a.log> <b.log>

Both files are the "<frame> <hash>" streams written by tests/lua/replay.lua
(work RAM) or by its VIDEO_OUT half (framebuffer). "They differ" is not a
diagnosis; this tool turns a diff into a CLASS, because the classes have
very different meanings:

  IDENTICAL        no divergence.
  PHASE SHIFT k    B[n] == A[n-k] across the divergent window, i.e. one run
                   is k frames ahead and the two re-sync later. This is a
                   TIMING difference, not a state difference — nothing
                   computed a different answer, something happened a beat
                   earlier. (The project already knows this shape from the
                   QSound handshake latch and the hook-induced interrupt
                   skew documented in CLAUDE.md §4.)
  TRANSIENT        a bounded window that re-converges but is NOT a clean
                   phase shift — real state differed, then was overwritten.
  PERMANENT        diverges and never re-converges: the runs are computing
                   different things from here on.

It also prints the window bounds, so a "one-off flake" and a "diverges at
the same frame every time" can be told apart across occurrences.
"""
import sys


def load(path):
    frames = {}
    order = []
    end = None
    with open(path) as fh:
        for line in fh:
            parts = line.split()
            if not parts:
                continue
            if parts[0] == "END":
                end = int(parts[1])
                continue
            n = int(parts[0])
            frames[n] = parts[1]
            order.append(n)
    return frames, order, end


def main():
    if len(sys.argv) != 3:
        sys.exit(__doc__)
    a, aord, aend = load(sys.argv[1])
    b, bord, bend = load(sys.argv[2])

    print(f"A: {sys.argv[1]}  {len(aord)} frames, END {aend}")
    print(f"B: {sys.argv[2]}  {len(bord)} frames, END {bend}")
    if aend != bend:
        print(f"  NOTE: different END frame ({aend} vs {bend}) — the runs are "
              f"not even the same length")

    common = sorted(set(a) & set(b))
    diff = [n for n in common if a[n] != b[n]]
    if not diff:
        print("VERDICT: IDENTICAL")
        return 0

    first, last = diff[0], diff[-1]
    tail = [n for n in common if n > last]
    reconverged = bool(tail)
    print(f"  divergent frames: {len(diff)} of {len(common)}")
    print(f"  window: {first}..{last}"
          f"{' (re-converges, ' + str(len(tail)) + ' clean frames after)' if reconverged else ' (runs to the end)'}")

    # Phase-shift test: is B just running k frames ahead of / behind A?
    for k in list(range(1, 9)) + [-x for x in range(1, 9)]:
        hits = 0
        checked = 0
        for n in diff:
            m = n - k
            if m in a:
                checked += 1
                if b[n] == a[m]:
                    hits += 1
        if checked and hits == checked:
            print(f"VERDICT: PHASE SHIFT {k:+d} — B[n] == A[n{-k:+d}] for every "
                  f"divergent frame.\n"
                  f"         Nothing computed a different value; one run is "
                  f"{abs(k)} frame(s) {'ahead' if k > 0 else 'behind'}.")
            return 0

    print(f"VERDICT: {'TRANSIENT' if reconverged else 'PERMANENT'} — real state "
          f"differed (not a clean phase shift).")
    # A little extra: how far apart are they, byte-wise, is unknowable from
    # hashes, but the shape of the window usually is the tell.
    runs = []
    start = prev = diff[0]
    for n in diff[1:]:
        if n == prev + 1:
            prev = n
            continue
        runs.append((start, prev))
        start = prev = n
    runs.append((start, prev))
    print(f"  {len(runs)} contiguous run(s): "
          + ", ".join(f"{s}-{e}" for s, e in runs[:10])
          + (" ..." if len(runs) > 10 else ""))
    return 0


if __name__ == "__main__":
    sys.exit(main())
