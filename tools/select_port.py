#!/usr/bin/env python3
"""select_port.py — Donovan's select-screen portrait/name/highlight via
IN-PLACE record surgery (M2b select phase 2; chains after patch_prg).

Mechanism (docs/game/engine_internals.md "The select screen's laws"; the M2b
derivation is in docs/game/engine_internals_history.md): the three
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
from gfx_tiles import cell_at, attr_block  # noqa: E402  (GitHub #47)
import cps2_decrypt as cps  # noqa: E402

# REFUSE TO RUN WITH ASSERTIONS DISABLED (14z-94, GitHub #79). The record-format, size-bound, anchor-presence and CONFLICTING TILE
# PLACEMENT checks are the select screen's only placement safety net.
# These are `assert` statements, and `python -O` / PYTHONOPTIMIZE=1 removes
# assert statements ENTIRELY — so under that mode the check does not weaken,
# it VANISHES, and a bad result exits 0. Gated by tests/test_optimize_guard.sh.
if not __debug__:
    raise SystemExit(
        f"{__file__}: refusing to run under python -O / PYTHONOPTIMIZE — its "
        f"safety checks are assertions and would be stripped (GitHub #79)")

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
    ("win quote", 0x274642, 0x2A8CF8),
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
    # session 14h: win-quote record blocks (Jedah's freed win tiles +
    # general pool tail)
    (0x7A66, 1, 1): 0xBE5F,
    (0xA047, 1, 1): 0xB2AF,
    (0xBC22, 4, 1): 0xBE30,
    (0xBC26, 3, 1): 0xBE6C,
    (0xBC4F, 1, 2): 0xBDFF,
    (0xBC6F, 1, 1): 0xBE8B,
    (0xBC7F, 1, 1): 0xA33D,
    (0xBC8F, 1, 1): 0xBE89,
    (0xBC9F, 1, 1): 0xBE7F,
    (0xBCAF, 1, 1): 0xBE6F,
    (0xBCBF, 1, 1): 0xA2DF,
    (0xBCD0, 7, 5): 0xBDF4,
    (0xBCD7, 2, 2): 0xBE02,
    (0xBCD9, 3, 1): 0xBE70,
    (0xBCE9, 2, 1): 0xB2B6,
    (0xBCEB, 1, 1): 0xB2B0,
    (0xBCEE, 2, 1): 0xBE22,
    (0xBCF7, 9, 2): 0xBE46,
    (0xBD17, 9, 1): 0xBE80,
    (0xBD20, 2, 3): 0xBE00,
    (0xBD22, 6, 3): 0xBE40,
    (0xBD28, 2, 1): 0xB2B4,
    (0xBD2A, 1, 1): 0xA89E,
    (0xBD2B, 1, 1): 0xB2BA,
    (0xBD2C, 1, 1): 0xA32D,
    (0xBD2D, 3, 1): 0xBE7C,
    (0xBD38, 1, 2): 0xBE1F,
    (0xBD39, 4, 4): 0xBDFB,
    (0xBD3D, 2, 1): 0xB2B8,
    (0xBD3F, 1, 2): 0xBE3F,
    (0xBD4D, 2, 1): 0xB2A5,
    (0xBD50, 4, 1): 0xBE3B,
    (0xBD54, 3, 1): 0xBE73,
    (0xBD57, 1, 1): 0xA2DA,
    (0xBD60, 6, 2): 0xBE66,
}


def u16(d, o):
    return int.from_bytes(d[o:o + 2], "big")


def u32(d, o):
    return int.from_bytes(d[o:o + 4], "big")


# Coordinate lists shared with other consumers (session 14s): Jedah's
# name-banner list [0x32A196,0x32A19A) doubles as the speed-menu text
# record's first pair. Shared lists are never written (see the surgery
# comment); extend this set if the pixel gate ever fingers another.
SHARED_LISTS = {0x32A196}


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
    ap.add_argument("--out", metavar="DIR",
                    help="write the patched members HERE instead of rewriting "
                         "prg_dir in place. This is the (src, out) form every "
                         "other builder takes (CLAUDE.md 5) and the only one "
                         "that is chainable and idempotent (GitHub #46)")
    ap.add_argument("--force", action="store_true",
                    help="re-run in place over an already-ported directory. "
                         "Refused by default: the size guard below re-parses "
                         "the TARGET image, so on a second pass it measures "
                         "the ALREADY-REPLACED record and asserts nothing")
    args = ap.parse_args()

    # IN-PLACE IS THE EXCEPTION HERE, AND IT IS GUARDED (14z-94, GitHub #46).
    # This tool's docstring says "modifies the loose program members in
    # place", which makes it the one builder that is not (src, out) — so it
    # cannot be chained, and re-running it is not a no-op: `assert dsize <=
    # jsize` re-parses the target, so the second pass measures the record it
    # already overwrote and the guard becomes meaningless.
    #
    # --out gives it the normal form. Without --out it still writes in place,
    # but now atomically and only once: a stamp records the port, and a second
    # run is refused rather than silently double-porting.
    _sp_stamp = os.path.join(args.prg_dir, ".select_port.done")
    if not args.out and os.path.exists(_sp_stamp) and not args.force:
        sys.exit(f"select_port: {args.prg_dir} already carries a select port "
                 f"({_sp_stamp}).\n"
                 f"  Re-running in place would replace ALREADY-REPLACED "
                 f"records, and the size guard would measure them rather than "
                 f"the originals. Rebuild the directory, use --out DIR, or "
                 f"--force if you know why.")

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
            bx, by = attr_block(at)
            anchor = PLACEMENTS.get((t, bx, by))
            assert anchor is not None, \
                f"{name}: no placement for block (0x{t:04X},{bx},{by})"
            new_ents.append((anchor, at))
            for dy in range(by):
                for dx in range(bx):
                    src = cell_at(t, dx, dy)
                    dst = cell_at(anchor, dx, dy)
                    tile_pairs.append([src, dst])
        # Coordinate handling (session 14s, two hard-won rules):
        # 1. The record's CPTR must stay JEDAH'S — cptr values are
        #    RAM-VISIBLE: select-screen init caches list pointers into
        #    work RAM on LEGACY paths (relocating them diverged
        #    02/03/08 masked at select entry ~frame 820 — the fourth
        #    stored-anchor class).
        # 2. The list bytes may only be written if NO other consumer
        #    shares the span: Jedah's 1-pair name-banner list IS the
        #    speed-menu record's first pair (one byte shifted the
        #    TURBO/AUTO text 8px for seven shipped builds —
        #    RAM/VRAM-invisible, caught by tests/test_gfx_menus.sh).
        #    Shared lists keep Jedah's coordinates: Donovan's art draws
        #    at the host position (slot-0x0F-only cosmetic).
        if jcptr in SHARED_LISTS:
            print(f"{name}: coord list 0x{jcptr:06X} SHARED — keeping "
                  f"Jedah's pairs (Donovan draws at host position)")
        else:
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

    # WIN/QUOTE palettes (session 14u — the copy-and-repoint design).
    # In-place block edits are impossible: the mid-frame script/fade
    # system reads arbitrary rows of the per-side blocks through its
    # own PC-relative table (CODE:0x153D0) on legacy paths (the 14t
    # revert). But the WIN-screen uploaders reach the blocks through
    # the DATA-side table 0x38C298 (all four movea sites) plus one
    # hardcoded lea (0x1C424, the char*0x60 view; a second hardcoded
    # site 0x8396 uses a constant row and never touches char slices —
    # left vanilla). So: three patched COPIES go into the proven-dead
    # zone (the parked overlay's legacy-clean placement area), the
    # data table longs are repointed here, and the gen pokes the
    # 0x1C424 immediate (code space, re-encrypted there):
    #   copy A1 0x248D80 (P1, 0xA0-view)  slice [0x960,0xAA0) <- vs2
    #   copy A2 0x24A8A0 (P2, 0xA0-view)  slice [0x960,0xAA0) <- vs2
    #   copy B  0x24C3C0 (0x60-view)      slice [0x5A0,0x6E0) <- vs2
    # (0x60-view dark-char 0x17 reads [0x8A0,0x9E0) — vanilla in copy
    # B by construction; 0xA0-view copies never serve the 0x60 path.)
    # Scripts/fades keep reading the ORIGINAL blocks: legacy byte flow
    # is untouched, and legacy winners read copy bytes identical to
    # vanilla outside the slot-0x0F slices.
    # DISABLED (session 14w): the copies at 0x248D80+ broke FELICIA'S
    # TRIANGLE JUMP (playtest round 18/19 — reproducible: long jump-back
    # never latches the wall, she wraps vertically twice). The "dead
    # anim zone" was attributed from Jedah-demo cursors only; it holds
    # other consumers' data. Nothing may be placed there without a
    # per-consumer proof. Re-enable with a REAL home for the copies.
    # 14z: OFF FOR GOOD at this placement. Round-22 timeline convicts
    # the COPIES (0x248D80 zone) of the throw victim-teleport bug:
    # broken on every copies-active build (d6a751cb, e7682289), healthy
    # without them (ad372a6b) — the 14v grab-row rollback "fixed" it
    # only by coincidence of the 14w winpal disable. The zone holds
    # throw-cinematic/victim-sequence data; NO legacy replay throws
    # (coverage gap now closed by 30_demitri_throw). The palettes the
    # copies served never visibly improved (the quote/HUD rows come
    # from a still-undecoded path), so nothing is lost.
    # THE CODE IS GONE, THE FINDING IS NOT (14z-94, GitHub #46). The block
    # copies above were guarded by a hardcoded `WINPAL_ENABLE = False`, so
    # roughly forty lines of assignments and a copy loop could never execute
    # — and a reader grepping 0x248D80 found live-looking statements for a
    # mechanism disabled FOR GOOD. That is the dead-code-shadowing-live-code
    # class, so the statements are deleted; the analysis above and below is
    # kept verbatim because it is the evidence, not the implementation.
    # The constants it used (BLK 0x1B20, JP1/JP2 0x39FDC0/0x3A18E0,
    # DP1/DP2 0x3B727C/0x3B8EDC, COPY_A1/A2/B 0x248D80/0x24A8A0/0x24C3C0,
    # PRIV_TAB 0x24DE00) are recorded here and recoverable from git for the
    # "next attempt" the 14t post-mortem below anticipates.
    # v3 (the 14u gate iteration): the shared table 0x38C298 must stay
    # VANILLA — site 0x1BF56 is a select-time BULK PRELOADER that
    # stages every char's slice through work RAM on legacy paths
    # (read-watch: one hit at select entry; both earlier attempts
    # diverged 03/16 with identical checksums because the preloader
    # staged the changed 0x0F slice). Instead a PRIVATE table carrying
    # the copy addresses goes at 0x24DE00, and the gen pokes the three
    # quote-time reader sites (0x1C1FA/0x1C5CE/0x7D4FC) to it.
    PRIV_TAB = 0x24DE00
    print("win/quote palettes: DISABLED (no safe home; 14w, code removed 14z-94)")

    # (14t post-mortem kept for the record:) The
    # per-side blocks (0x39FDC0/0x3A18E0, char*0xA0 slices) are BULK-
    # STAGED through work RAM mid-frame during 2P select/match on
    # LEGACY paths — an in-place slice edit diverged 03/16 masked for
    # 3229/2008 frames from select entry (transient: checksum-visible,
    # frame-done-dump-invisible). Any fix needs the staging reader
    # decoded first (STATE 14t). The mechanism map (side table
    # CODE:0x38C298, vs2 0x396C94 -> blocks 0x3B727C/0x3B8EDC, Donovan
    # char 0x13) is correct and kept for that next attempt.

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
    _sp_dir = args.out or args.prg_dir
    if args.out:
        os.makedirs(args.out, exist_ok=True)
    # ATOMIC ACROSS THE WHOLE SET (14z-94, GitHub #46). This loop used to
    # write each member directly, so a crash partway left a HALF-PORTED
    # program image on disk with nothing to distinguish it from a finished
    # one. Every segment is staged first; the renames only start once all of
    # them exist.
    _sp_staged = []
    pos = 0
    for n, ln in zip(tgt_prgs, lengths):
        seg = out_blob[pos:pos + ln]
        tmp = os.path.join(_sp_dir, n + ".select_port.tmp")
        open(tmp, "wb").write(seg)
        _sp_staged.append((tmp, os.path.join(_sp_dir, n), n, seg))
        pos += ln
    for tmp, dst, n, seg in _sp_staged:
        os.replace(tmp, dst)
        print(f"  wrote {n} sha1 {hashlib.sha1(seg).hexdigest()}")
    if not args.out:
        with open(_sp_stamp, "w") as f:
            f.write("select_port ran in place here; see GitHub #46.\n"
                    "A second in-place run is refused (use --out or --force).\n")


if __name__ == "__main__":
    main()
