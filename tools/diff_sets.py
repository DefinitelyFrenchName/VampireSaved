#!/usr/bin/env python3
"""diff_sets.py — window-based structural diff between two ROM images.

Usage:
    python3 tools/diff_sets.py <imgA> <imgB> [--window 256] [--min-run 4096]

Classifies each WINDOW-byte block of A as:
  SAME   — identical bytes at the identical offset in B
  MOVED  — identical bytes exist in B at a different offset (first match;
           adjacent windows with a consistent delta merge into one run)
  DIFF   — content not found anywhere in B (changed or unique to A)
Adjacent same-class windows (same delta for MOVED) merge into runs; runs
shorter than --min-run are absorbed into a neighboring DIFF run to keep the
report readable (coincidental small matches in tables are noise).

Output: one line per run, "0xAAAAAA-0xBBBBBB CLASS [B:0xCCCCCC delta]".
The three-way atlas is built by running this on each pair (both the data
views and the opcode views — see docs/game/atlas/README.md byte-order note).
Prints SHA-1 of both inputs (tools convention).
"""

import argparse
import hashlib
import sys
from collections import defaultdict
from pathlib import Path


def mask_pointers(blob):
    """Zero out 16-bit-aligned 32-bit BE values in ROM (0x000100-0x3FFFFF) or
    RAM (0xFF0000-0xFFFFFF) address ranges. Not a disassembly — a
    normalization: two engine builds that differ only in relocated absolute
    addresses hash identically afterwards. Also zeroes the 0xFF padding runs'
    complement (nothing: padding already matches)."""
    out = bytearray(blob)
    n = len(out)
    for off in range(0, n - 3, 2):
        v = (out[off] << 24) | (out[off + 1] << 16) | (out[off + 2] << 8) | out[off + 3]
        if 0x000100 <= v <= 0x3FFFFF or 0xFF0000 <= v <= 0xFFFFFF:
            out[off] = out[off + 1] = out[off + 2] = out[off + 3] = 0
    return bytes(out)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("img_a", type=Path)
    ap.add_argument("img_b", type=Path)
    ap.add_argument("--window", type=int, default=256)
    ap.add_argument("--min-run", type=int, default=4096)
    ap.add_argument("--mask-pointers", action="store_true",
                    help="zero aligned 32-bit BE values that look like ROM/RAM "
                         "addresses before comparing — matches engine code that "
                         "only differs by relocated pointers")
    args = ap.parse_args()

    a = args.img_a.read_bytes()
    b = args.img_b.read_bytes()
    if args.mask_pointers:
        a = mask_pointers(a)
        b = mask_pointers(b)
    for p, blob in ((args.img_a, a), (args.img_b, b)):
        print(f"# read {p}  sha1 {hashlib.sha1(blob).hexdigest()}", file=sys.stderr)

    w = args.window
    index = defaultdict(list)  # window bytes -> [offsets in B]
    for off in range(0, len(b) - w + 1, w):
        index[b[off:off + w]].append(off)

    # classify each window of A: (cls, delta)
    windows = []
    for off in range(0, len(a) - w + 1, w):
        chunk = a[off:off + w]
        if b[off:off + w] == chunk:
            windows.append(("SAME", 0))
        else:
            cands = index.get(chunk)
            if cands:
                # prefer the candidate continuing the previous window's delta
                prev_delta = windows[-1][1] if windows and windows[-1][0] == "MOVED" else None
                delta = next((c - off for c in cands if c - off == prev_delta),
                             cands[0] - off)
                windows.append(("MOVED", delta))
            else:
                windows.append(("DIFF", 0))

    # merge into runs
    runs = []  # [start, end, cls, delta]
    for i, (cls, delta) in enumerate(windows):
        off = i * w
        if runs and runs[-1][2] == cls and (cls != "MOVED" or runs[-1][3] == delta) \
                and runs[-1][1] == off:
            runs[-1][1] = off + w
        else:
            runs.append([off, off + w, cls, delta])

    # absorb tiny SAME/MOVED runs between DIFFs into DIFF (noise suppression)
    cleaned = []
    for run in runs:
        start, end, cls, delta = run
        if cls != "DIFF" and end - start < args.min_run and cleaned \
                and cleaned[-1][2] == "DIFF":
            cleaned[-1][1] = end
        elif cls == "DIFF" and cleaned and cleaned[-1][2] == "DIFF":
            cleaned[-1][1] = end
        else:
            cleaned.append(run)

    total = {"SAME": 0, "MOVED": 0, "DIFF": 0}
    for start, end, cls, delta in cleaned:
        total[cls] += end - start
        loc = f"  B:0x{start + delta:06x} delta {delta:+#x}" if cls == "MOVED" else ""
        print(f"0x{start:06x}-0x{end:06x}  {cls}{loc}  ({end - start} bytes)")
    n = len(a)
    print(f"# totals: SAME {total['SAME']} ({100 * total['SAME'] // n}%)  "
          f"MOVED {total['MOVED']} ({100 * total['MOVED'] // n}%)  "
          f"DIFF {total['DIFF']} ({100 * total['DIFF'] // n}%)", file=sys.stderr)


if __name__ == "__main__":
    main()
