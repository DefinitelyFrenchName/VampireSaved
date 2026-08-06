# NEXT SESSION — orientation (written at the close of 14z-64, 2026-08-06)

**Start here: M3a IS COMPLETE AND FROZEN (maintainer-ratified).** The
WIDE reference is **donovan-m3a = `4b7d0dc7`** (`build/m5_wide`,
rebuilds bit-exact): Donovan lives at his native id 0x13 by default
(`--profile cps2-wide-v1`, no id flag), Jedah is fully restored, the
select family + wheel serve from WIDE group C bank 5 with real
medallion art and palettes, ring-reuse hover, variant-id HUD and
win-screen palettes, and the 14z-2 mirror-victim fix. Stock twin
**`6c93cfa8`** (`build/m5_stock`) = the former ae701ffb + exactly the
2-byte fix. Masked basis V2 (per-set `mask` files; the staging-slot
windows). Read STATE.md `14z-64` (the freeze record + the ratified
package), then docs/patch_notes.md's 14z-64 sections.

## Build / validate / playtest

```sh
export ROMDIR=/Users/koneko/Developer/Vampire_Saved/ROMS
KEY_SET=vsavj GEN_FLAGS="--allow-plausible --tripwire-open \
    --profile cps2-wide-v1" tools/build_donovan.sh 6 build/m5_wide
MAME_BIN=~/.cache/vampire-saved/mame/cps2 \
    MAME_ROMPATH="$PWD/build/m5_wide/rompath;$ROMDIR" \
    tests/run_suite.sh vsavjw          # the frozen donovan-m3a set
tests/run_battery_m2.sh build/m5_stock # the stock battery
tools/run_wide.sh build/m5_wide fbneo  # playtest
```

## What comes after M3a (the roster road)

1. **The next tenants: Huitzil/Phobos (0x10) and Pyron (0x11).** The
   whole M3a machinery is id-parameterized — the second tenant is
   mostly manifest work (a new [[tenant]] with its own extraction) +
   the same gates. Their wheel cells, TABLE B rows, medallion art and
   palette rows (0x19/0x1A) are ALREADY in place as placeholders.
   Multi-tenant coexistence in one build is the new mechanism to
   design (the space model + per-tenant holes).
2. **M5 sounds for Donovan**: 25 stubbed sfx rows await the WIDE
   QSound space; the maintainer can now ear-identify missing sfx
   (playtest acceptance is real). The 9bac-era sound work (14z-59i)
   is the prior art.
3. **Small parked items**: the Pyron-medallion 2P residual (row 0x1A
   doubles as the P2 sword row — resolves naturally if a future
   palette-row design lands); the deep-arcade ending flow audit gap
   ($130(a5) fold — re-run the venue taps if endings ever show wrong
   colors); per-cell authored hover rings (supersede ring-reuse by
   repointing the same rows).

## Standing facts (do not re-derive)

- WIDE builds: `--profile cps2-wide-v1` (id_by_profile gives 0x13; the
  stock track keeps slot 0x0F). Group C: bank 4 = fighter band+shelf,
  bank 5 = select family + wheel at 0x10000+code; `gfx_tiles.bank_word`
  is the only encoding. Sentinel CRCs 0xdec0de31..37 stay sentinels.
- The masked basis is PER-EXPECTATION-SET (`tests/expected/<set>/mask`);
  the V2 basis adds the palette staging slots of edited block-A rows
  (the staging area is $FF3F02 + row*0x20 — docs/atlas/ram.md). The
  round-64 window is row 0x14's slot.
- Palette rows on select: NOTHING is free (GOTCHAS "no free palette
  row") — the medallions ride thunk-protected vestigial mid rows
  0x16/0x19/0x1A; 0x2AD44 is the in-match funnel and must NEVER be
  thunked (the $FF8094 parity lesson); block-A row 0 feeds the
  game-over starfield.
- The accent-march census (4 family-base sites) and the mid-row census
  (3 dest computations) are gate-frozen; a new site appearing anywhere
  fails loudly.
- Measure, don't assume: every select object caches differently; an
  emulator over a chained rompath is not a member-identity instrument;
  breakpoint-heavy traces desync replay input.
