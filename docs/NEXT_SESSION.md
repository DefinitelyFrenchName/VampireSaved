# NEXT SESSION — orientation (written at the close of 14z-67, 2026-08-07)

**Start here: THE D4 PHOBOS GFX VERTICAL IS BUILT AND FULLY GATED —
Huitzil renders his real art everywhere and his wheel cell 0x10 is
hand-pickable. build/hui6 = b99b7359 is PING #7, awaiting the
maintainer playtest, and is PINNED (PING7_DO_NOT_REBUILD.md — never
rebuild into that dir; experiments go to hui7+/scratch, so any bug
report stays attributable to the played version). THE H FREEZE comes
after confirmation. MEANWHILE (maintainer testing deferred): the
patch_index backfill landed and THE PYRON LADDER IS OPEN — stages 1-4
green (tests/test_pyron_ladder.sh: builds, op invariant with the four
named hook-site exemptions, boot probe id-hold/load/guard-clean,
stage-3 unmasked bit-identity + stage-4 masked-v2 EXACT). His next
arc = the moveset R1 loop (support-zone roots, sound-farm sweep,
obj_hook types, probe cycles — the H 14z-65/66 template).** Frozen
references unchanged (donovan-m3a 4b7d0dc7 / m5_stock 6c93cfa8;
m3a-reproducible PASS on every commit of the session).

## What 14z-67 closed (details: STATE 14z-67; bytes: patch_notes)

1. **D4 opener 1 — budgets + layout RATIFIED.** All three tenants
   natively share vs2 bank 3; H/P place at DELTA 0 (no record remap),
   Donovan frozen at +0x2750; disjoint by interval; flip condition
   does NOT trigger (~20K codes free). Ledger
   build/manifest/gfx_layout3.toml; gate tests/test_gfx_layout3.sh.
2. **D4 opener 2 — censuses promoted + Pyron CLEAN.**
   tools/census_regions.py (ground-truthed on H: exact generator
   agreement); P's code region: 0 data_in_code, 0 escapes. One real
   find: x05c800's latent tail escapes — fixed same session
   (recon 0x635FC -> 0x5B25C, double-site verified).
3. **D4 opener 3 — THE H GFX RUNG.** Machinery de-Donovanized
   (per-tenant layout rows, delta-0 path, data_subst gather,
   per-tenant effect_tail keys, walker bounds+sweep fixes) with m3a
   bit-exact throughout; H's full stage-6 manifest authored (12 bank
   setters, table_fix, palettes, 7 select_records, drawer thunks,
   grid-column select palettes, HUD rows, win-pal, wheel roster21).
   Every gate green, incl. the behavior battery ON the stage-6 build
   and the oracle battery (1741 = the stage-4 number exactly).

## The playtest ping (#7)

```sh
export ROMDIR=/Users/koneko/Developer/Vampire_Saved/ROMS
tools/run_hui_behavior.sh          # build/hui6; NO forced id —
                                   # walk D,D,D from default to his cell
```
Things to look at: his art/colors everywhere (select, VS splash, HUD
mug + name plate, win screen after a victory), the three new wheel
medallions, VS2-vs-VH2 float flavors (Start-hold). Sounds silent (M5
scope). Cells 0x11/0x13 exist but are UNBACKED on this single-tenant
build.

## AFTER maintainer confirmation: the H freeze

Registry row (b99b7359 -> huitzil-m4?) + expectation set
(tests/expected/<name>/) + re-freeze note in HANDOFF. Then the
PYRON VERTICAL (D4 order): his R1 root census (support-zone extra
roots — census_regions reruns as they land; the region-count lock in
test_census_regions.sh will fail loudly and guide re-freezing), his
ladder stages 1-4 (the H template), then his gfx rung through the SAME
generalized machinery (his layout row is already reserved; his
manifest needs the H-style stage-6 sections — the grid column for his
select palettes is column-free: vs2 gives him a dedicated +0xBC row
block, measured 14z-67 at vs2 0x6B1A6 area).

## Standing facts (14z-67 additions; do not re-derive)

- Forced-pick pokes do NOT populate the HUD index field — verify HUD
  rows with the real-pick replays only (36 = cell 0x13, 37 = cell
  0x10). GOTCHAS has the anatomy.
- Stale-gate class: a gate not in the battery can sit failing across
  sessions (two found red 14z-67, both attributed + re-frozen). When
  a freeze changes design semantics, run every gate touching that
  surface before closing.
- vs2 select-portrait palette dispatch (uploader compare chain at vs2
  0x6B1A6): id 0x10 -> grid column 0x0B (moveq), id 0x11 -> +0xBC
  dedicated block, id 0x13 -> +0xC6 dedicated block. Grid base
  0x3C117C, row stride 0x20, (variant*16+id) indexing.
- vs2 HUD stager bias is +0x4200 (vsavj's is +0x3800); both tables
  DATA-view. H entries: name 04AB0102/FFE8/0002, mug 05A0.
- The queued docs/patch_index.md backfill (from 14z-66) is STILL
  OPEN.

## Gates (all green at close; run before ANY commit)

```sh
export ROMDIR=/Users/koneko/Developer/Vampire_Saved/ROMS
tests/test_m3a_reproducible.sh          # after machinery changes
tests/test_gfx_layout3.sh               # the 3-tenant layout locks
tests/test_census_regions.sh [build]    # both censuses, H + P
tests/test_hui_boot.sh                  # masked-v2 EXACT legacy leg
tests/test_hui_soak.sh                  # 11k chaos + round-2 pods
tests/test_hui_ex.sh    build/hui6      # 4 sections incl. FG aftermath
tests/test_hui_walk.sh  build/hui6
tests/test_hui_air.sh   build/hui6
tests/test_hui_grab.sh  build/hui6
tests/test_hui_pairs.sh build/hui6
tests/test_hui_oracle.sh build/hui6/rompath   # ~10 min
tests/test_tenant_hud.sh build/hui6     # per-tenant (also m5_wide)
tests/test_wide_render_content.sh       # re-shaped m3a semantics
tools/run_hui_behavior.sh               # interactive (build/hui6)
```
