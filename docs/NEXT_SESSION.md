# NEXT SESSION — orientation (written at the close of 14z-63, 2026-08-06)

**Start here: PHASE 3 IS COMPLETE (all six items; rounds 7-8 all
clean; the accent census gate freezes the audit) — the wheel serves REAL
MEDALLION ART from group C bank 5 (vanilla cells measured
pixel-identical), the ring/highlight POSITION SOURCE is fixed in place
(the tenant's highlight draws AT his cell), the in-match HUD shows
the tenant's OWN mugshot and name plate ("Donovan" under the bar,
measured), and the 2P victory screen serves his OWN vs2 win palette
(both thunk paths measured).** Remaining: the palette-block colours ($130(a5) fold), the accent
audit, and the re-freeze bundle (maintainer sign-off). Evidence build
`build/m3a_wheel` = `96a6e737`. Read STATE.md `14z-63`, then
docs/patch_notes.md's 14z-63 sections for byte detail.

## What 14z-63 landed (do not re-derive)

- **Wheel bank-5 move**: drawer $FFB800's select-init bank immediate
  (0x5F8B2) flipped to 0x3000; 85 host tiles byte-identical vsav group
  A -> group C 0x10000+code + 18 vs2 medallion tiles at native codes.
  Gate: `tests/test_wheel_bank5.sh` (in the battery). The shared
  attract init loop 0x07C428 must NEVER be patched (stride-0x80 over
  every menu object).
- **Highlight base rows**: the 32-row pc-rel table at 0x5FAE2 (variant
  half aliased in vsav, un-aliased in vs2 — Capcom's own extension
  move) gained rows 0x10/0x11/0x13 in place as CODE ops (pc-relative
  reads are program-FC = encrypted storage). Bases in the layout's
  `highlight_base` (derivation note in the layout file). Transform:
  OBJ_x = base+coord+64, OBJ_y = 224-(base+coord) — measured, incl.
  one exact prediction.
- **Legacy expectation re-frozen**: the host pick is now the §4 v4
  COMPOSITE — window 889-2415 (bank word at the select init; 0x5FD02
  re-converges) + ONE flicker frame 2836 (8 bytes at $FF406A, the
  fade-staging family staging the changed medallion palette rows for
  one frame). Ratification folds into the re-freeze bundle.
- **Medallion palettes (round 6)**: the newcomers' entries are
  re-palmed to measured-free rows 0x16/0x19/0x00 carrying vs2's real
  palettes via select block A (0x3A3800). Row 0x02 is NOT block-A
  served (live copy from 0x3B5940); 0x1A is the P2-tenant sword row.
- **Semantic correction**: the composed vs2 highlight record (b000
  bar) is vs2's POST-CONFIRM NAME BAR, not a hover label. Both engines
  hover-draw RINGS (per-cell pal-0x1E records, all-different codes).

## Work list (in order)

1. ~~Hover content~~ **RATIFIED + DONE in 14z-63 (round 7): ring
   reuse.** All three extended cells (P1+P2+mirror, 9 pokes) point at
   the host's row-0x0F ring records verbatim; the highlight
   [[select_records]] composition became art="host_ring"; checker
   re-modeled. Per-cell authored rings can supersede later.
2. ~~The folded venue family (HUD name/mugshot)~~ **DONE in 14z-63**
   (attribution corrected: unmasked consumers over 32-row-aliased
   tables, not the $130(a5) fold; gate tests/test_tenant_hud.sh). What
   the fold STILL owns: the select/VS palette-block COLOURS
   (venue_assets.md §2 — widen 0x1BF98-family masks + place blocks at
   pool index 0x13 AFTER confirming what occupies it; the two unmasked
   sites 0x021C64/0x021C8E read past 16 blocks today).
3. ~~Win-pal sparse block~~ **DONE in 14z-63** (both thunk paths
   measured on real 2P victories; gate tests/test_tenant_winpal.sh;
   scoping fact: the arcade win-quote screen never runs 0x5F1B6 —
   only 2P victories do).
4. ~~The accent/march audit~~ **CLOSED in 14z-63**: 4/4 family-base
   sites thunked (frozen census gate tests/test_accent_census.sh),
   zero direct T0/T1 refs, venue sweep complete (the continue screen
   has NO character surface — measured).
5. **The RE-FREEZE bundle** (maintainer sign-off, one change): parked
   mirror-victim fix; `id_by_profile = "cps2-wide-v1=0x13"`; re-freeze
   the WIDE reference; re-measure/ratify the masked classes (incl. the
   889-2415 window); mirror-flavor throw replay; test_tenant_id.sh
   check 2.

## Standing facts (do not re-derive)

- Group C: bank 4 = fighter band+shelf; bank 5 = select family AND the
  whole wheel at 0x10000+code. `gfx_tiles.bank_word` is the only bank
  encoding (4 -> 0x1000, 5 -> 0x3000).
- Sentinel descriptor CRCs for group C (0xdec0de31..37): never "fix"
  them to real CRCs.
- Select objects: P1 figure/name/portrait = FFB880/FFB900/FFB980, P2 =
  +0x200; FFB800 = wheel drawer on select, win drawer at win; FFBA00 =
  P1 ring/highlight. Each caches differently — measure, don't assume.
- GOTCHA (new, 14z-63): unconditioned breakpoints on hot handlers
  DESYNC replay input — the frame counter keeps counting UI frames
  while the CPU is stopped, so the trace measures a screen the replay
  never left. Condition breakpoints to a handful of stops, or use
  write taps.
- An emulator over a chained rompath is NOT a member-identity
  instrument; verify zips statically.

## Build / test

```sh
export ROMDIR=/Users/koneko/Developer/Vampire_Saved/ROMS
KEY_SET=vsavj GEN_FLAGS="--allow-plausible --tripwire-open \
    --profile cps2-wide-v1 --tenant-id 0x13" \
    tools/build_donovan.sh 6 build/m3a_wheel
tests/test_wheel_bank5.sh build/m3a_wheel
tests/test_tenant_hud.sh build/m3a_wheel
tests/test_tenant_winpal.sh build/m3a_wheel
tests/test_tenant_select_records.sh build/m3a_wheel
tools/run_wide.sh build/m3a_wheel fbneo     # playtest
```

Frozen refs: stock `ae701ffb` MUST keep reproducing (verified after
every 14z-63 change); WIDE `9bac6ee3` non-rebuildable pending re-freeze
(zips remain valid). Playtest classification:
docs/playtest_m3a_interims.md.
