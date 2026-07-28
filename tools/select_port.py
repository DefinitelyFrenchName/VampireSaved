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

# (piece, vsavj_record, vs2_record) — in-place record replacements.
# The cursor highlight (vsavj 0x2724A2) is deliberately NOT replaced:
# its vs2 coordinates assume vsav2's wheel geometry (displaced label).
# Session 14g adds the VS-splash/hover/pal family (playtest round 8):
# the six per-char cells' FIRST records (the objects' duration fields
# read garbage-huge values, so [0x1C] never advances — only the first
# record renders). Five fit in place; the P1-hover record (Donovan's
# 48-entry bust composition) relocates into Jedah's freed anim region
# with a cell poke (RELOC below).
RECORDS = [
    ("big portrait", 0x271CE8, 0x2A63F0),
    ("name banner", 0x27221A, 0x2A657E),
    ("splash P1", 0x273766, 0x2A7F68),
    ("splash P2", 0x273AAC, 0x2A7F86),
    # "hover P2" (0x272FB0) and "pal P2" (0x272FDA) are NOT replaced:
    # the WIN SCREEN reads 0x272FB0's coordinate list on LEGACY paths
    # (PC 0x8C6E2, frame-10732 trace, session 14g — a one-position
    # divergence of 322 frames in 05_timeout_idle). Those cells are not
    # slot-exclusive; both records are visually trivial (1 entry).
    ("pal P1", 0x2720FA, 0x2A6416),
]
# NO relocated records / cell pokes: legacy replays' cursors VISIT slot
# 0x0F (hover), so everything they can read must stay RAM-invisible —
# in-place only, and every replaced record KEEPS JEDAH'S BUDGET WORD
# (the OBJ emitter debits the shared frame budget by this field; a
# changed budget shifted borderline skip decisions on crowded frames =
# the one-byte $FF811B divergence, session 14g RAM diff). The P1-hover
# big bust record is deliberately NOT ported (the visible portrait and
# VS busts come from the wheel-array and splash records).
# block placements (session 14e greedy fit, splash-overlap-verified):
# (vs2 code, bx, by) -> vsavj bank-1 anchor code
PLACEMENTS = {
    # phase 2 (portrait + name; the dead highlight entry removed)
    (0x9F55, 1, 1): 0x7A78,
    (0xAD42, 1, 1): 0x7002,
    (0xAD43, 1, 1): 0x7421,
    (0xADC1, 4, 2): 0xA2CB,
    (0xAE07, 8, 8): 0xADA0,
    (0xAE50, 1, 8): 0xAD4F,
    (0xAE51, 1, 8): 0xADA8,
    (0xAF4B, 5, 2): 0xA2B6,
    # session 14g (splash/hover/pal family, fit into the remaining pool)
    (0x7A0A, 1, 1): 0xA258, (0x8661, 1, 1): 0xA2CF,
    (0xAEE6, 4, 2): 0xA327, (0xB2A0, 3, 1): 0xAD60,
    (0xB9DE, 1, 1): 0xA27F, (0xB9DF, 1, 3): 0xA21F,
    (0xB9EC, 2, 2): 0xA2F0, (0xB9EE, 1, 1): 0xA27A,
    (0xB9F5, 3, 3): 0xA2F4, (0xB9F8, 2, 1): 0xAD72,
    (0xB9FB, 1, 1): 0xA22A, (0xB9FE, 1, 1): 0xA26A,
    (0xBA08, 1, 1): 0xA25F, (0xBA09, 1, 2): 0xA15F,
    (0xBA0B, 3, 1): 0xA324, (0xBA0E, 1, 1): 0xA24F,
    (0xBA0F, 1, 1): 0xA1EE, (0xBA10, 3, 2): 0xA2F7,
    (0xBA13, 2, 1): 0xAD70, (0xBA18, 1, 1): 0xA244,
    (0xBA1A, 3, 1): 0xAD54, (0xBA1D, 2, 1): 0xAD1D,
    (0xBA1F, 1, 1): 0x7C43, (0xBA23, 6, 2): 0xA2D4,
    (0xBA29, 4, 1): 0xAD50, (0xBA2D, 3, 1): 0xAD63,
    (0xBA30, 1, 1): 0xA264, (0xBA31, 1, 1): 0x99DB,
    (0xBA32, 1, 1): 0xA224, (0xBA39, 4, 1): 0xAD37,
    (0xBA3D, 2, 1): 0xAD74, (0xBA3F, 1, 1): 0xA248,
    (0xBA40, 5, 1): 0xA30B, (0xBA45, 1, 1): 0xA274,
    (0xBA46, 5, 2): 0xA2EB, (0xBA4B, 4, 2): 0xA310,
    (0xBA4F, 1, 3): 0xA1AE, (0xBA50, 3, 1): 0xA317,
    (0xBA53, 2, 1): 0xA2C4, (0xBA55, 1, 1): 0xA254,
    (0xBA60, 2, 1): 0xA2F2, (0xBA62, 1, 1): 0xA26F,
    (0xBA63, 1, 1): 0xA21A, (0xBA64, 1, 1): 0xA1DE,
    (0xBA65, 1, 1): 0xA234, (0xBA66, 2, 2): 0xA32B,
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
        # compose the record: Donovan's fmt/count/entries, JEDAH'S BUDGET
        # (RAM-invisibility: the budget debits the shared frame budget)
        # and Jedah's cptr
        rec = (dfmt.to_bytes(2, "big") + jbud.to_bytes(2, "big")
               + (dcnt - 1).to_bytes(2, "big") + jcptr.to_bytes(4, "big"))
        for t, at in new_ents:
            rec += t.to_bytes(2, "big") + at.to_bytes(2, "big")
        rec += b"\x00" * (jsize - len(rec))    # slack inside Jedah's record
        img[jrec:jrec + jsize] = rec
        print(f"{name}: vsavj rec 0x{jrec:06X} <- vs2 0x{drec:06X} "
              f"({dcnt} entries, {len(rec)}B incl. slack; coords "
              f"{dclist}B at 0x{jcptr:06X})")

    # relocated records: place Donovan's record + coordinate list in
    # Jedah's freed anim region and poke the per-char cell (32-bit,
    # slot-0x0F-only). The freed region holds his orphaned anim data —
    # superset-clean to overwrite (same argument as every slot repoint).
    # select-portrait PALETTE rows (playtest round 7: portrait/name
    # rendered with Jedah's colors). Uploader: vsavj 0x5F136 — source
    # row = 0x3AC000 + (variant*16 + char)*0x20 (11-variant x 16-char
    # grid; char 0x0F). vs2 special-cases Donovan (0x6B1A0:
    # cmpi #$13 -> d0 += 0xC6): rows at 0x3C117C + (0xC6+v)*0x20,
    # 10 variants. Overwrite Jedah's 11 grid slots in place; variant
    # indices past Donovan's supply clamp to his last row.
    JGRID, JCHAR, JVARS = 0x3AC000, 0x0F, 11
    DBASE, DVARS = 0x3C117C + 0xC6 * 0x20, 10
    for v in range(JVARS):
        dst = JGRID + (v * 16 + JCHAR) * 0x20
        src = DBASE + min(v, DVARS - 1) * 0x20
        img[dst:dst + 0x20] = vs2[src:src + 0x20]
    print(f"select palettes: {JVARS} variant rows for char 0x0F "
          f"<- vs2 Donovan rows @0x{DBASE:06X}")

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
