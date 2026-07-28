#!/usr/bin/env python3
"""select_port.py — Donovan's select-screen portrait/name/highlight via
IN-PLACE record surgery (M2b select phase 2; chains after patch_prg).

Mechanism (docs/engine_internals.md "Select-screen phase 2"): the three
select UI pieces ride per-wheel-slot pointer arrays whose slot-0x0F
cells point at Jedah's records; the P2 arrays alias the SAME records.
Replacing the record CONTENT in place fixes both sides with zero
pointer pokes. Donovan's records (dumped live from real vsav2) are all
smaller than Jedah's, and his coordinate lists fit inside Jedah's.

  piece        vsavj record   vs2 record   entries (vs2)
  big portrait 0x271CE8       0x2A63F0     7  (incl. the 8x8 core)
  name banner  0x27221A       0x2A657E     1
  highlight    0x2724A2       0x2A6750     1

Art: 106 bank-1 tiles, block-placed into Jedah's exclusive
select/confirm family art (fit computed session 14e; the splash-frame
OBJ dump proved no other character's art overlaps the placements).
This tool rewrites the record tile codes to the placements and emits
select_tiles.json (src,dst pairs, bank-1) for build_gfx_donovan.

Usage:
  select_port.py <prg_dir> --vs2 <vsav2.zip> --tiles-out <json>

Modifies the loose program members in place; prints every write.
"""

import argparse
import hashlib
import json
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import cps2_decrypt as cps  # noqa: E402

# (piece, vsavj_record, vs2_record)
# The third piece (cursor highlight, vsavj rec 0x2724A2) is deliberately
# NOT replaced: its vs2 coordinates are relative to Donovan's wheel
# position on vsav2's different wheel geometry — replacing it rendered
# a displaced label (snapshot, session 14e). Jedah's highlight stays;
# the wheel face is background scroll art anyway (separate follow-up).
RECORDS = [
    ("big portrait", 0x271CE8, 0x2A63F0),
    ("name banner", 0x27221A, 0x2A657E),
]
# block placements (session 14e greedy fit, splash-overlap-verified):
# (vs2 code, bx, by) -> vsavj bank-1 anchor code
PLACEMENTS = {
    (0x9F55, 1, 1): 0x7A78,
    (0xAD42, 1, 1): 0x7002,
    (0xAD43, 1, 1): 0x7421,
    (0xADC1, 4, 2): 0xA2CB,
    (0xAE07, 8, 8): 0xADA0,
    (0xAE50, 1, 8): 0xAD4F,
    (0xAE51, 1, 8): 0xADA8,
    (0xAF4B, 5, 2): 0xA2B6,
    (0xB000, 5, 1): 0xA2D4,
}


def u16(d, o):
    return int.from_bytes(d[o:o + 2], "big")


def u32(d, o):
    return int.from_bytes(d[o:o + 4], "big")


def parse_record(d, r):
    fmt = u16(d, r)
    assert fmt in (2, 8), f"unexpected record fmt {fmt} at {r:#x}"
    budget = u16(d, r + 2)
    cnt = u16(d, r + 4) + 1
    cptr = u32(d, r + 6)
    ents = [(u16(d, r + 10 + 4 * k), u16(d, r + 12 + 4 * k))
            for k in range(cnt)]
    return fmt, budget, cnt, cptr, ents


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("prg_dir")
    ap.add_argument("--vs2", required=True)
    ap.add_argument("--tiles-out", required=True)
    args = ap.parse_args()

    words, _, _, _ = cps.load_set(args.vs2)
    vs2 = bytes(cps.words_to_logical_bytes(words))
    print(f"read {args.vs2} sha1 {hashlib.sha1(vs2).hexdigest()}")

    tgt_prgs = sorted((n for n in os.listdir(args.prg_dir)
                       if cps._PRG_RE.search(n)),
                      key=lambda n: int(cps._PRG_RE.search(n).group(1)))
    lengths, blob = [], b""
    for n in tgt_prgs:
        b = open(os.path.join(args.prg_dir, n), "rb").read()
        lengths.append(len(b))
        blob += b
    img = bytearray(cps.words_to_logical_bytes(cps.words_from_file_bytes(blob)))

    tile_pairs = []
    for name, jrec, drec in RECORDS:
        jfmt, jbud, jcnt, jcptr, jents = parse_record(img, jrec)
        dfmt, dbud, dcnt, dcptr, dents = parse_record(vs2, drec)
        jsize, dsize = 10 + 4 * jcnt, 10 + 4 * dcnt
        jclist, dclist = 4 * jcnt, 4 * dcnt
        assert dsize <= jsize and dclist <= jclist, \
            f"{name}: Donovan record/coords larger than Jedah's"
        # remap Donovan's entry tile codes to the placements
        new_ents = []
        for t, at in dents:
            bx = ((at >> 8) & 15) + 1
            by = ((at >> 12) & 15) + 1
            anchor = PLACEMENTS.get((t, bx, by))
            assert anchor is not None, \
                f"{name}: no placement for block (0x{t:04X},{bx},{by})"
            new_ents.append((anchor, at))
            for dy in range(by):
                for dx in range(bx):
                    src = (t & ~0xF) + (dy << 4) + ((t + dx) & 0xF)
                    dst = (anchor & ~0xF) + (dy << 4) + ((anchor + dx) & 0xF)
                    tile_pairs.append([src, dst])
        # write Donovan's coordinate pairs over Jedah's list space
        img[jcptr:jcptr + dclist] = vs2[dcptr:dcptr + dclist]
        # compose the record: keep Donovan's fmt/budget/count, Jedah's cptr
        rec = (dfmt.to_bytes(2, "big") + dbud.to_bytes(2, "big")
               + (dcnt - 1).to_bytes(2, "big") + jcptr.to_bytes(4, "big"))
        for t, at in new_ents:
            rec += t.to_bytes(2, "big") + at.to_bytes(2, "big")
        rec += b"\x00" * (jsize - len(rec))    # slack inside Jedah's record
        img[jrec:jrec + jsize] = rec
        print(f"{name}: vsavj rec 0x{jrec:06X} <- vs2 0x{drec:06X} "
              f"({dcnt} entries, {len(rec)}B incl. slack; coords "
              f"{dclist}B at 0x{jcptr:06X})")

    # dedupe tile pairs (blocks may overlap between records)
    seen = {}
    for s, t in tile_pairs:
        if s in seen:
            assert seen[s] == t, f"conflicting placement for tile 0x{s:04X}"
        seen[s] = t
    pairs = sorted([s, t] for s, t in seen.items())
    json.dump(pairs, open(args.tiles_out, "w"))
    print(f"wrote {args.tiles_out}: {len(pairs)} bank-1 tile placements")

    out_blob = cps.words_to_file_bytes(cps.words_from_logical_bytes(bytes(img)))
    pos = 0
    for n, ln in zip(tgt_prgs, lengths):
        seg = out_blob[pos:pos + ln]
        open(os.path.join(args.prg_dir, n), "wb").write(seg)
        print(f"  wrote {n} sha1 {hashlib.sha1(seg).hexdigest()}")
        pos += ln


if __name__ == "__main__":
    main()
