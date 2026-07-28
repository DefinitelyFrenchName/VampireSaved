#!/usr/bin/env python3
"""obj_records.py — walk a character's OBJ (sprite) records and inventory
the gfx tiles they reference.

Record format (decoded session 14 from the vsavj emitter chain
0x1ABC8 -> 0x1AC68 -> 0x1ADC6 -> 0x1AF9E; format-2 handler 0x1B234):

  +0  format.w   jump-table selector at the emitter (0 and 2 observed)
  +2  budget.w   OBJ-entry budget check against remaining d7
  +4  count.w    entries = count+1 (dbra)
  +6  ptr.l      -> X/Y coordinate word-pair list (one pair per entry)
  +10 entries    format 0: (tile.w, attr.w) per entry
                 format 2: (tile.w, attr.w) per entry (attr palette bits
                 merged with object +0xF at emit)

Emit semantics (the R2 answer, atlas character_tables.md):
  - tile.w is ABSOLUTE within a 64K-tile bank; written RAW to OBJ RAM.
  - bank = OBJ Y-word bits 13-14, OR'd in from object field +0x18
    (per-char init table: vsavj 0x282D4 / vsav2 0x27530, PC-relative =
    read via OPCODE space; slot-indexed).  tile_abs = bank<<16 | tile.
  - attr size bits: bx=(attr>>8&15)+1, by=(attr>>12&15)+1; block cell
    (dx,dy) uses tile (n & ~0xF) + (dy<<4) + ((n+dx) & 0xF)  — row
    stride 16 with within-row wrap, so any code remap must be 16-aligned
    to preserve block geometry.

Usage:
  obj_records.py <image.bin> --base 0xADDR --start 0xADDR --end 0xADDR
                 [--cptr-lo 0x100000] [--cptr-hi 0x400000] [--json out]

  image.bin  data-space image (records/anim live in data space)
  --base     ROM address of image[0] (0 for full images)
  --start/--end  the character's anim region (record pointers + records)
  --cptr-lo/hi   validity window for coordinate-list pointers

Prints the inventory: entries, unique expanded tiles, band clusters.
"""

import argparse
import json
import sys


def walk(dat, base, start, end, cptr_ok):
    """dat indexed by ROM address - base. Returns (tiles set, n_entries,
    n_records)."""
    tiles, entries, records = set(), 0, 0
    seen = set()
    for a in range(start, end - 4, 2):
        i = a - base
        v = int.from_bytes(dat[i:i + 4], "big")
        if not (start <= v < end) or v in seen:
            continue
        o = v - base
        fmt = int.from_bytes(dat[o:o + 2], "big")
        budget = int.from_bytes(dat[o + 2:o + 4], "big")
        count = int.from_bytes(dat[o + 4:o + 6], "big")
        cptr = int.from_bytes(dat[o + 6:o + 10], "big")
        if fmt > 0x20 or fmt % 2 or not (0 < count + 1 <= budget <= 0x100):
            continue
        if not cptr_ok(cptr):
            continue
        seen.add(v)
        records += 1
        for k in range(count + 1):
            t = int.from_bytes(dat[o + 10 + 4*k:o + 12 + 4*k], "big")
            at = int.from_bytes(dat[o + 12 + 4*k:o + 14 + 4*k], "big")
            bx = ((at >> 8) & 15) + 1
            by = ((at >> 12) & 15) + 1
            entries += 1
            for dy in range(by):
                for dx in range(bx):
                    tiles.add((t & ~0xF) + (dy << 4) + ((t + dx) & 0xF))
    return tiles, entries, records


def clusters(tiles, gap=0x400):
    ts = sorted(tiles)
    if not ts:
        return []
    out = [[ts[0], ts[0]]]
    for t in ts[1:]:
        if t - out[-1][1] > gap:
            out.append([t, t])
        else:
            out[-1][1] = t
    return out


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("image")
    ap.add_argument("--base", type=lambda x: int(x, 0), required=True)
    ap.add_argument("--start", type=lambda x: int(x, 0), required=True)
    ap.add_argument("--end", type=lambda x: int(x, 0), required=True)
    ap.add_argument("--cptr-lo", type=lambda x: int(x, 0), default=0x100000)
    ap.add_argument("--cptr-hi", type=lambda x: int(x, 0), default=0x400000)
    ap.add_argument("--json")
    args = ap.parse_args()

    dat = open(args.image, "rb").read()
    inreg = (args.start, args.end)

    def cptr_ok(p):
        return (args.cptr_lo <= p < args.cptr_hi
                and not (inreg[0] <= p < inreg[1]))

    tiles, entries, records = walk(dat, args.base, args.start, args.end,
                                   cptr_ok)
    print(f"records {records}, entries {entries}, "
          f"unique expanded tiles {len(tiles)}")
    for lo, hi in clusters(tiles):
        n = sum(1 for t in tiles if lo <= t <= hi)
        print(f"  band 0x{lo:04X}-0x{hi:04X}: {n} tiles "
              f"({n * 128 // 1024} KB, extent 0x{hi - lo + 1:X})")
    if args.json:
        json.dump(sorted(tiles), open(args.json, "w"))
        print(f"wrote {args.json}")


if __name__ == "__main__":
    main()
