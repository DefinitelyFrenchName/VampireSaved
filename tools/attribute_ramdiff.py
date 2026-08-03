#!/usr/bin/env python3
"""attribute_ramdiff.py — every differing byte must fall in a NAMED window.

    python3 tools/attribute_ramdiff.py <logA> <logB> <frame> \
        --window 7F00-7FFF:dead-stack --window 0500-05FF:sound-driver

Reads the work-RAM dumps the harnesses write beside a checksum log
(`<log>.dump_<frame>_<addr>.bin` for FBNeo, `dump_<frame>_<addr>.bin` beside
the log for MAME), diffs them, and requires every differing byte to lie
inside a window the caller can NAME. Windows are offsets from $FF0000.

Why this exists: "the two builds differ, and that's expected" is not a
verdict — it is the absence of one. Two builds can legitimately differ, but
only in places somebody has identified and can justify. This turns that
judgement into an assertion, and prints the stray addresses when it fails so
the next question ("what lives at $FFxxxx?") is immediately askable against
docs/atlas/ram.md.

Exit 0 when every differing byte is attributed, 1 otherwise.
"""
import argparse
import glob
import os
import sys


def find_dump(log, frame):
    base = os.path.dirname(os.path.abspath(log))
    pats = [f"{log}.dump_{frame}_*.bin",                     # FBNeo harness
            os.path.join(base, f"dump_{frame}_*.bin")]       # MAME replay.lua
    for p in pats:
        hits = sorted(glob.glob(p))
        if hits:
            return hits[0]
    return None


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("log_a")
    ap.add_argument("log_b")
    ap.add_argument("frame", type=int)
    ap.add_argument("--window", action="append", default=[],
                    metavar="LO-HI:NAME",
                    help="named window, hex offsets from $FF0000, inclusive")
    ap.add_argument("--base", default="FF0000",
                    help="address base for reporting (default FF0000)")
    args = ap.parse_args()

    wins = []
    for w in args.window:
        rng, _, name = w.partition(":")
        lo, _, hi = rng.partition("-")
        wins.append((int(lo, 16), int(hi, 16), name or "unnamed"))

    da_p, db_p = (find_dump(args.log_a, args.frame),
                  find_dump(args.log_b, args.frame))
    if not da_p or not db_p:
        print(f"  FAIL: dump for frame {args.frame} missing "
              f"(A={bool(da_p)} B={bool(db_p)})")
        return 1
    da, db = open(da_p, "rb").read(), open(db_p, "rb").read()
    if len(da) != len(db):
        print(f"  FAIL: dumps differ in length ({len(da)} vs {len(db)})")
        return 1

    diff = [i for i in range(len(da)) if da[i] != db[i]]
    base = int(args.base, 16)
    if not diff:
        print("  note: the dumps are IDENTICAL at this frame — if a difference "
              "was expected, this frame does not show it")
        return 0

    counts = {name: 0 for _, _, name in wins}
    stray = []
    for o in diff:
        for lo, hi, name in wins:
            if lo <= o <= hi:
                counts[name] += 1
                break
        else:
            stray.append(o)

    summary = ", ".join(f"{counts[n]} {n}" for _, _, n in wins)
    print(f"  {len(diff)} byte(s) differ; {summary}")
    if stray:
        shown = ", ".join(f"${base + o:06X}" for o in stray[:8])
        print(f"  FAIL: {len(stray)} byte(s) OUTSIDE every named window: {shown}"
              + (" ..." if len(stray) > 8 else ""))
        print("        Do not widen a window to make this pass. Identify what "
              "lives there (docs/atlas/ram.md) and justify it, or treat it as "
              "the regression it probably is (CLAUDE.md §4 standing watch).")
        return 1
    print("  ok: every differing byte is attributed to a named window")
    return 0


if __name__ == "__main__":
    sys.exit(main())
