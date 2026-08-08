# NEXT SESSION — orientation (written at the close of 14z-68, 2026-08-08)

**Start here: THE COMPANION-MACHINE REGION PORT — the one arc
between build/hui9 and a feature-complete Huitzil. 14z-68 REFUTED
the 14z-67 entry theory, proved the fighter-side flow is already
native-identical, and narrowed the gap to a single measured fact
at the render layer (below). The shipping manifest is UNCHANGED
(functionally identical to HEAD; rebuild = df578358 = the 14z-67
round-final shape). PING #8 = build/hui9 (9e3105e0) is still with
the maintainer — nothing new to playtest.** Frozen references
unchanged (donovan-m3a 4b7d0dc7 / m5_stock 6c93cfa8;
m3a-reproducible PASS).

## Read first, do not re-derive

**The 14z-67 seq-D entry theory is DEAD.** Measured three ways:
native NEVER executes 0x56D68 (zero hits across a replay with three
successful rays); vsavj 0x22500 is NOT the twin of vs2 0x22008 (it
is a timer-decrement inside the every-frame fighter tick — the true
twin is 0x23500, derived through the parallel per-seq tables vsavj
0x225EE / vs2 0x20FD2); and **no seq-head thunk is needed at all**,
because the built image already repoints every per-char dispatch
row 0x10 to H's placed handlers (the 12b/13 `dispatch_1x` bank_map
rows did this long ago). H's ray runs HIS OWN flow, tap-verified
native-identical. Both entry thunks are parked with this written
into the manifest. Do not re-attempt them.

## THE ARC: port the companion machine so the SPAWN happens

**The render-level fact that defines "done"** (OBJ dump, replay 83b,
native vs ours at the same beam phase): native stages the beam as
pieces at **bank-3 codes 0x1E2F / 0x1E42 / 0x1E5F, pal 0x0C**
(H's own band — that art EXISTS in our group C bank 4 at delta 0)
marching x=0x9C..0xDC, PLUS long stretch segments **bank-1 code
0x4EC0 at sz 4x1 and 16x1** (effect page -> our group C bank 5 via
c5). **Ours stages ZERO of them.** Not wrong art, not a wrong bank —
the pieces are never created.

Two thunks were built and measured in 14z-68; both work exactly as
designed and neither restores the beam, which is the point:
**first-tick constants are downstream of a spawn that never
happens.** Both are PARKED with full anatomy in huitzil.toml:
- `piece_prebake` (vj 0x18F88; a6 = spawning fighter, a4 = new
  piece): installs bank + record at 0x4001F4 = placed base + 0x1E4
  = native's own relative offset. All gates green, 2P legacy
  BIT-IDENTICAL (the site is cold for legacy — 3 hits, the 3 rays).
- `fleet_record_base` (vj 0x60DD4): base-only swap CRASHES the ES
  flow — the ES driver shares subtype 0x0D and its param stream
  carries vanilla-base offsets. Base + stream + count + updater are
  ONE unit.

**So: port the region** (vs2 ~0x6CA00-0x6D7A0 spawner family +
the piece machine 0x6A770 family), then un-park those two thunks as
its wiring. Known twin/R1 facts, already resolved: piece machine
vj 0x5E780 ↔ vs2 0x6A770 (per-seq pc-rel table vj 0x5E7A4 /
vs2 0x6A798; walker vj 0x5E540 stride 0x80, type table 0x5E556;
rows 2+ are 40-42/48 byte-identical, differing only in R1
addresses). Engine pairs: 0x13778->0x15084, 0x13724->0x15030,
0x13c0e->0x1551a, 0x157c2->0x1707a, 0x5122->0x4ce2 (all already in
reconciliation.toml). Fleet spawner vj 0x60DC8 ↔ vs2 0x6D200
(updater 152/160 identical); it is invoked via the RAM pump with
a6 = the driver piece. Region x06d240 is ALREADY placed (dst
0xD3EF0) with escapes resolved; x022400 too (dst 0xC7070).

Gate after EVERY iteration: `tests/test_hui_boot.sh` (masked-v2
EXACT — the "cold stub is legacy-hot" lesson) plus ex/grab/air, and
**check the screen, not just the tap** (see below).

## New instruments — use them earlier than I did

- `tests/replays/hui/83b_hui_ray_2p.rpl` — the rig: 2P dummy, three
  spaced 236LP, cross-emulator reproducible, FBNeo-tappable.
  POKES="1400:ff8782:10;1450:ff8782:10;1500:ff8782:10".
- `tests/test_hui_fx_flow.sh [build]` — the attribution gate.
  Fighter-side flow identity (incl. "the refuted 0x56D68 entry
  stays cold") + piece-side machine attribution, auto-detecting
  pre/post-port from the build's own patch notes. Ground-truthed on
  hui9; negative control is the bad-thunk build (fails 3 of 4 legs).
- `snapshot_frames.lua` and `obj_records_dump.lua` now take
  **POKES** (replay.lua grammar) — before 14z-68 the forced-pick
  rigs could not be photographed or OBJ-dumped at all. Two RAM-layer
  iterations measured "perfect" while the screen was pixel-identical
  to the unfixed build; the OBJ dump settled it in one run.
  See docs/GOTCHAS.md "Verify a fix at the RENDER layer".

## The rest of the H worklist (after the effect family)

- Sidekick shadow: extended vs2 shadow table at the 0x8245C site.
- Win screen: palette source re-measure (vs2's win drawer newcomer
  special-case) + garbled art blocks (tiles outside the walked
  inventory).
- Dark Force style: SUPPRESS the host effect for his id.
- FG pacing (may resolve with the effect flow).
- Then: H freeze (registry row + expectation set, maintainer-gated)
  -> the Pyron moveset arc -> his gfx rung.

## Gates (all green at close)

```sh
export ROMDIR=/Users/koneko/Developer/Vampire_Saved/ROMS
tests/test_m3a_reproducible.sh          # after machinery changes
tests/test_hui_boot.sh                  # masked-v2 EXACT legacy leg
tests/test_hui_fx_flow.sh [build]       # NEW 14z-68 attribution gate
tests/test_hui_ex.sh    [build]
tests/test_hui_grab.sh  [build]
tests/test_hui_air.sh   [build]
tests/test_hui_walk.sh  [build]
tests/test_hui_pairs.sh [build]
tests/test_hui_oracle.sh [rompath]      # ~10 min
tests/test_pyron_ladder.sh              # P stages 1-4
tests/test_pyron_soak.sh                # P 11k chaos
tests/test_gfx_layout3.sh
tests/test_census_regions.sh [build]
tests/test_wide_render_content.sh
tools/run_hui_behavior.sh               # interactive (build/hui9)
```
