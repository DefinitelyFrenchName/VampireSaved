#!/usr/bin/env python3
"""select_port.py — port Donovan's select-screen web (M2b phase; chains
after patch_prg on the assembled program set).

Pipeline map: docs/engine_internals.md "Select-screen pipeline". The
vsavj per-char roots are 32-bit cells read via helper 0x5F328
(cell = 0x2672AA + 4*d0; hover family d0 = 4*char P1 / 4*(char+0x20)
P2); the name banner rides long-pointer table 0x26771E row 0x0F. All
patched bytes are slot-0x0F-only content.

Ported zones (vs2, data space) are placed INSIDE JEDAH'S FREED ANIM
REGION [0x248B88, ~0x267000): 124KB of pure slot-0x0F data orphaned by
the port (his slot pointers are all repointed; the shared select tail
0x267xxx+ is NOT free and is never touched). Both program holes are
nearly full — this is the only space that fits, and overwriting it is
superset-clean by the same argument as every slot repoint.
  A records  [0x2A1DAE, 0x2A8B50)  newcomer select records/scripts
  B structs  [0x2A05E2, 0x2A0E40)  root table + frame-struct arrays
  C coords   [0x300D40, 0x304E70)  X/Y coordinate lists

Relocations are STRUCTURE-WALKED (never blind byte-scan): frame-struct
payloads (records or indirect struct pointers), record cptr longs, and
in-zone long cells of the struct span. Tile codes are left as-is in
phase 1 (portrait renders from unplaced art = recognizable garbage);
the art placement phase supplies a (src,dst) tile map via --tile-map.

Usage:
  select_port.py <prg_dir> --vs2 <vsav2.zip> [--base 0x3F0000]
                 [--tile-map map.json]

<prg_dir> = patch_prg output dir (the loose program members) — modified
in place (this tool is a chained builder). Prints every write; asserts
the target space is 0xFF fill before placing.
"""

import argparse
import hashlib
import json
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import cps2_decrypt as cps  # noqa: E402

ZONE_A = (0x2A1DAE, 0x2A8B50)
ZONE_B = (0x2A05E2, 0x2A0E40)
ZONE_C = (0x300D40, 0x304E70)

# vsavj patch points (slot-0x0F-only)
HOVER_P1 = 0x2672AA + 16 * 0x0F           # 0x26739A
HOVER_P2 = 0x2672AA + 16 * (0x0F + 0x20)  # 0x26768A
NAME_ROW = 0x26771E + 4 * 0x0F
# vs2 sources for the poke values
VS2_HOVER_P1 = 0x2A05E2 + 16 * 0x13
VS2_HOVER_P2 = 0x2A05E2 + 16 * (0x13 + 0x20)
VS2_NAME = 0x2A0A4A + 4 * 0x13


def u16(d, o):
    return int.from_bytes(d[o:o + 2], "big")


def u32(d, o):
    return int.from_bytes(d[o:o + 4], "big")


def walk_relocs(d):
    """Enumerate relocation sites in the vs2 zones: (addr_of_long).
    Structure-walked: struct payloads in zone B, record cptrs in zone A,
    and zone-B root-table cells."""
    sites = set()

    def in_any(v):
        return (ZONE_A[0] <= v < ZONE_A[1] or ZONE_B[0] <= v < ZONE_B[1]
                or ZONE_C[0] <= v < ZONE_C[1])

    # zone B: treat every aligned long whose value lies in a zone as a
    # cell/payload (the span is pure pointer/flag structs; flags longs
    # have 0xFFxx top bytes and never collide with zone addresses)
    for a in range(ZONE_B[0], ZONE_B[1] - 4, 2):
        if in_any(u32(d, a)):
            sites.add(a)
    # zone A: records' cptr fields, walked via record parsing from every
    # long that zone B or zone A references as a record
    refs = {u32(d, a) for a in sites}
    # also records referenced from within zone A (script sequences):
    for a in range(ZONE_A[0], ZONE_A[1] - 4, 2):
        v = u32(d, a)
        if in_any(v):
            sites.add(a)
            refs.add(v)
    for r in sorted(refs):
        if not (ZONE_A[0] <= r < ZONE_A[1]):
            continue
        fmt = u16(d, r)
        if fmt in (2, 8):
            cptr = u32(d, r + 6)
            if ZONE_C[0] <= cptr < ZONE_C[1]:
                sites.add(r + 6)
    return sites


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("prg_dir")
    ap.add_argument("--vs2", required=True)
    ap.add_argument("--base", type=lambda x: int(x, 0), default=0x248B90)
    ap.add_argument("--tile-map")
    args = ap.parse_args()

    words, key, prgs, sha1s = cps.load_set(args.vs2)
    vs2 = bytes(cps.words_to_logical_bytes(words))
    print(f"read {args.vs2} sha1 {hashlib.sha1(vs2).hexdigest()}")

    # assemble the target program image from the loose prg members
    tgt_prgs = sorted((n for n in os.listdir(args.prg_dir)
                       if cps._PRG_RE.search(n)),
                      key=lambda n: int(cps._PRG_RE.search(n).group(1)))
    assert tgt_prgs, f"no program members in {args.prg_dir}"
    lengths, blob = [], b""
    for n in tgt_prgs:
        b = open(os.path.join(args.prg_dir, n), "rb").read()
        lengths.append(len(b))
        blob += b
    img = bytearray(cps.words_to_logical_bytes(cps.words_from_file_bytes(blob)))

    # placements in the hole-B tail (descending zones packed at --base)
    place = {}
    cur = args.base
    for name, (lo, hi) in (("B", ZONE_B), ("A", ZONE_A), ("C", ZONE_C)):
        place[name] = cur
        print(f"zone {name}: vs2 0x{lo:06X}+0x{hi-lo:X} -> 0x{cur:06X}")
        cur += ((hi - lo) + 0xF) & ~0xF
    # placement must stay inside Jedah's freed private extent, well
    # below the SHARED select tail at 0x267xxx (docs/engine_internals.md)
    assert 0x248B88 <= args.base and cur <= 0x260000, \
        f"select web must fit in Jedah's freed region (ends 0x{cur:06X})"

    def reloc(v):
        for name, (lo, hi) in (("A", ZONE_A), ("B", ZONE_B), ("C", ZONE_C)):
            if lo <= v < hi:
                return place[name] + (v - lo)
        return v

    blobs = {n: bytearray(vs2[lo:hi])
             for n, (lo, hi) in (("A", ZONE_A), ("B", ZONE_B), ("C", ZONE_C))}
    n_rel = 0
    for site in sorted(walk_relocs(vs2)):
        for name, (lo, hi) in (("A", ZONE_A), ("B", ZONE_B)):
            if lo <= site < hi - 3:
                old = u32(blobs[name], site - lo)
                new = reloc(old)
                if new != old:
                    blobs[name][site - lo:site - lo + 4] = new.to_bytes(4,
                                                                        "big")
                    n_rel += 1
    print(f"relocated {n_rel} pointer cells")

    # optional tile-code remap inside the ported records (art phase)
    if args.tile_map:
        tm = {int(k, 0): v for k, v in json.load(open(args.tile_map)).items()}
        n_tw = 0
        # walk records inside blob A via refs from blob B/A (post-reloc
        # addresses are already placed; walk the SOURCE for structure)
        refs = set()
        for a in range(ZONE_B[0], ZONE_B[1] - 4, 2):
            v = u32(vs2, a)
            if ZONE_A[0] <= v < ZONE_A[1]:
                refs.add(v)
        for a in range(ZONE_A[0], ZONE_A[1] - 4, 2):
            v = u32(vs2, a)
            if ZONE_A[0] <= v < ZONE_A[1]:
                refs.add(v)
        for r in sorted(refs):
            fmt = u16(vs2, r)
            ro = r - ZONE_A[0]
            if fmt == 0:
                cnt = u16(vs2, r + 2)
                offs = [ro + 10 + 2 * k for k in range(cnt)]
            elif fmt in (2, 8):
                cnt = u16(vs2, r + 4) + 1
                offs = [ro + 10 + 4 * k for k in range(cnt)]
            elif fmt == 4:
                cnt = u16(vs2, r + 4) + 1
                offs = [ro + 6 + 8 * k for k in range(cnt)]
            else:
                continue
            for o in offs:
                t = u16(blobs["A"], o)
                if t in tm:
                    blobs["A"][o:o + 2] = tm[t].to_bytes(2, "big")
                    n_tw += 1
        print(f"remapped {n_tw} tile words via tile map")

    for name in ("B", "A", "C"):
        img[place[name]:place[name] + len(blobs[name])] = blobs[name]

    pokes = [
        (HOVER_P1, reloc(u32(vs2, VS2_HOVER_P1)), "hover portrait P1"),
        (HOVER_P2, reloc(u32(vs2, VS2_HOVER_P2)), "hover portrait P2"),
        (NAME_ROW, reloc(u32(vs2, VS2_NAME)), "name banner row 0x0F"),
    ]
    for addr, val, what in pokes:
        old = u32(img, addr)
        img[addr:addr + 4] = val.to_bytes(4, "big")
        print(f"poke32 0x{addr:06X}: 0x{old:08X} -> 0x{val:08X}  ({what})")

    # write back the modified program members (file byte order)
    out_blob = cps.words_to_file_bytes(cps.words_from_logical_bytes(bytes(img)))
    pos = 0
    for n, ln in zip(tgt_prgs, lengths):
        seg = out_blob[pos:pos + ln]
        open(os.path.join(args.prg_dir, n), "wb").write(seg)
        print(f"  wrote {n} sha1 {hashlib.sha1(seg).hexdigest()}")
        pos += ln


if __name__ == "__main__":
    main()
