# NEXT SESSION — orientation (written at the close of 14z-62k, 2026-08-06)

**Start here: OPTION A PHASES 1-2 ARE LANDED AND PLAYTEST-VALIDATED —
begin PHASE 3.** The whole select family (portrait bust, name banner, VS
splash, win quote) serves from WIDE group C BANK 5 at native vs2 codes,
with four measured drawer bank gates; group-A select placements are ZERO;
JEDAH IS CONFIRMED INDISTINGUISHABLE FROM VANILLA by five maintainer
playtest rounds (which also caught and validated fixes for the stale
group-B repack, the never-rendered medallions, and the select-sword grey
palette). Evidence build `build/m3a_selrec` = `048521c2`. Read STATE.md
`14z-62j/62k`, then docs/patch_notes.md's 62j/62k sections for the byte
detail.

## Phase 3 work list (in order)

1. **Real medallion art — the wheel bank move.** The wheel record is ONE
   object (one bank), so per-entry banks are impossible; the move that
   works: copy the 18 vanilla medallion tiles BYTE-IDENTICAL into group C
   (same in-group indices) + the three newcomers' real vs2 medallion art
   (their native codes b108/b0f5/b10b), then flip the wheel drawer's bank
   word — vanilla-cell pixels identical by construction, real art for the
   new cells. Find the wheel drawer object + its bank write first (the
   tap method; its $1C rides the relocated record at wide_ext — the
   drawer is whatever walks the 21-entry record, likely inited by the
   0x07C428 family).
2. **The ring/label position source.** The highlight piece IS the cursor
   ring (measured: each cell's pal-0x1E ring art is its highlight
   record). On the appended cells the composed vs2 label draws at a STALE
   base — the ring drawer's per-cell position source does not know the
   new cells (label seen at (152,88) instead of the cell). Find that
   source (tap the drawer's position fields at a hover change), extend it
   for cells 0x10/0x11/0x13.
3. **MAINTAINER DECISION for the newcomer cells' hover content**: a
   vanilla-consistent RING (needs authored/cloned ring art per cell — the
   rings are per-cell shaped) vs vs2's LIT LABEL (his native look, works
   once the position source is fixed) vs placeholder-until-real-art.
4. **The folded venue family**: HUD name plate + mugshot at a variant id
   (the 16-wide tables + the $130(a5) fold — docs/atlas/id_space.md
   0x00A43E). Donovan shows "VICTOR"/wrong mugshot in-match until then.
5. **Win-pal sparse block** (his win-screen palette): the design is in
   STATE 14z-62c — a placed sparse block + one thunk at the base load
   0x5F1B6, same TT pattern as the rest.
6. **The accent/march audit**: 62k fixed the select-venue sword row; audit
   the remaining march phases/venues for other slot-gated palette paths
   at a variant id (the T0/T1 slots are correctly vanilla now — anything
   still reading them for the TENANT is a bug of the 62k class).

## Then: the RE-FREEZE bundle (maintainer sign-off, one change)

Apply the parked mirror-victim fix (donovan.toml flat `fixes=` comment);
declare `id_by_profile = "cps2-wide-v1=0x13"`; re-freeze the WIDE
reference (9bac6ee3 is already non-rebuildable since the 62i coordinate
fix — expected); re-measure and ratify the masked classes; add a
mirror-flavor throw replay; update `test_tenant_id.sh` check 2.

## Standing facts (do not re-derive)

- Group C layout: bank 4 = the fighter band+shelf at code+0x2750 (records
  unchanged from the 0x0F layout); bank 5 = the select family at native
  codes (0x10000+code in-group). `gfx_tiles.bank_word` is the ONLY bank
  encoding (4 -> 0x1000, 5 -> 0x3000 — never bank<<13).
- Sentinel descriptor CRCs for group C (0xdec0de31..37): members resolve
  by NAME; never "fix" them to real CRCs (two measured shadow classes).
- The select-venue objects: P1 figure/name/portrait = FFB880/FFB900/
  FFB980, P2 = +0x200; win drawer = FFB800; each caches things
  differently (measure, don't assume — the name thunk's v1 lesson).
- An emulator over a chained rompath is NOT a member-identity instrument;
  verify zips statically and snapshot on the no-fallback overlay
  (scratchpad honest_rompath pattern).
- Gates: tests/test_tenant_select_records.sh (4 sections) is the
  mechanism gate; tests/test_tenant_id.sh the reproducibility guard;
  the battery includes both.

## Build / test

```sh
export ROMDIR=/Users/koneko/Developer/Vampire_Saved/ROMS
KEY_SET=vsavj GEN_FLAGS="--allow-plausible --tripwire-open \
    --profile cps2-wide-v1 --tenant-id 0x13" \
    tools/build_donovan.sh 6 build/m3a_selrec
tests/test_tenant_select_records.sh build/m3a_selrec
tools/run_wide.sh build/m3a_selrec fbneo     # playtest
```

Frozen refs: stock `ae701ffb` MUST keep reproducing (every change so far
verified); WIDE `9bac6ee3` non-rebuildable pending re-freeze (zips remain
valid). Playtest classification: docs/playtest_m3a_interims.md.
