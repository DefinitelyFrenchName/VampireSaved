# NEXT SESSION — orientation (written at the close of 14z-67, 2026-08-08)

**Start here: THE OPENER IS THE EFFECT-FLOW CLOSURE — the one arc
between build/hui9 and a feature-complete Huitzil. Everything is
decoded and placed; what remains is a dependency hunt with an exact
recipe (below). PING #8 = build/hui9 (9e3105e0) is with the
maintainer.** Frozen references unchanged (donovan-m3a 4b7d0dc7 /
m5_stock 6c93cfa8; m3a-reproducible PASS on every commit).

## The effect-flow closure (the opener) — recipe

The missing effects (sustained 236P beam, ES big-beam version, grab
lightning, 214 ground explosion) all run downstream of ONE entry:
vs2's class-02 seq-0xD handler head (0x22008) is a PER-CHAR JMP
DISPATCH — `move.b $382(a6),d0; lsl #2; movea.l #$D9538,a0; jmp
([a0+d0])` — whose row 0x10 is HIS OWN ported handler 0x56D68
(region "code"+0x20D8; head: bsr local, bra 0x574B0 into the x057456
driver). vsavj's seq-D (0x22500) has no dispatch, so none of his
effect flow ever ran on our builds.

State of the pieces (all committed):
- The effect ZONE (vs2 0x22400+0x1600, twin +0x2E — both machine stub
  copies + all 50 per-state handler segments incl. the four fleet-jmp
  tails) and the FLEET SPAWNERS (0x6D240+0x500, twin +0x174) are
  PORTED as regions with escapes resolved (three stage-2 record-
  installer twins per the bank_map pairing; the byte-map data rows
  resolve to vj 0x28D00 WITH the six poked entries; the per-char
  pointer table 0xD96B8->0xBF51A shape-matched).
- TWO entry thunks are PARKED in huitzil.toml with full anatomy:
  `seq_d_dispatch` (the REAL entry — measured: fires every frame,
  seq D is a common state, and with it live the ray move STOPS
  ENTIRELY: his handler flow has SILENT unmet dependencies) and
  `effect_machine` (wrong entry; also hot for legacy effects — it
  broke the boot gate's masked-EXACT leg; keep parked forever).

THE RECIPE: (1) un-park seq_d_dispatch in a SCRATCH build only;
(2) reproduce the silent bail with replay 83b-style input (three
spaced 236LP attempts — the thunk's cycles shift frame-pinned
inputs); (3) probe/tap the placed 0x56D68->0x574B0 flow to find where
it diverges from native (FBNeo taps on the fighter block during the
input window, ours vs native — the write-pattern divergence names the
bailing read); (4) resolve what it reads (candidate classes: per-char
tables the flow indexes, farm rows, sibling D9538-family tables for
other seqs); (5) iterate until the ray fires THROUGH his handler —
then the fleet/zone machinery lights up (already placed) and verify
beam duration/palette + lightning + ES beam + 214 explosion + FG
pacing in one sweep. Gates after EVERY iteration: test_hui_boot
(masked-EXACT — the "cold stub hot for legacy" lesson) + ex/grab/air.

## The rest of the H worklist (after the closure)

- Sidekick shadow: the known clamp-restore design (extended vs2
  shadow table at the 0x8245C site).
- Win screen: palette source re-measure (vs2's win drawer newcomer
  special-case) + the garbled art blocks (tiles outside the walked
  inventory).
- Dark Force style: SUPPRESS the host effect for his id (native
  applies no color change/afterimages — maintainer capture).
- FG pacing (may resolve with the effect flow).
- Then: H freeze (registry row + expectation set, maintainer-gated)
  -> the Pyron moveset arc (ladder 1-4 + soak + sound sweep already
  green; per-move native A/B next) -> his gfx rung.

## Standing facts added 14z-67 (do not re-derive)

- The effect byte map (vj DATA 0x28D00, vs2 0x27FD8): ids 0x4E-0x53
  were the ray-family dispatch gap (poked in huitzil.toml); pc-rel
  table reads are DATA-view reads.
- The throw-arc installer (vj 0x28386 / vs2 0x275E4): 16-byte physics
  rows via map1[2*subidx+d0]; vs2 map1 has 5 entries past vsavj's end
  (rows 0x32-0x36; 63214 arcs = rows 0x33/0x34, yv 16.0/20.0). Fixed
  by the throw_arc_tables tail-replacement thunk (superset tables,
  statically proven).
- Fighter physics fields: +0x40 xv, +0x44 yv, +0x48 xacc, +0x4C
  gravity (16.16). Fighter effect channels: +0x318/0x320/0x330/0x340
  sub-structs. The $FFBxxx pool = 0x80-stride effect pieces (+0x54
  effect id, +0x30 owner link, +0x1C record chain).
- vs2 seq-D per-char dispatch table 0xD9538 (rows 0x0F-0x13 = the
  newcomers' own drivers); the effect-record per-char tables
  0xD7018/98/118 <-> vj 0xBCE7A/EFA/F7A (bank_map rows, already
  repointed for tenants).
- 2P-dummy replays REPRODUCE across emulators (FBNeo taps usable);
  vs-CPU replays do NOT (the standing authoring rule).
- A thunk on a "cold" site can still be hot for LEGACY content — run
  the boot gate after ANY site_thunk addition, and verify a park
  edit actually landed (a silently-missed replace cost a bisect
  round).

## Gates (all green at close)

```sh
export ROMDIR=/Users/koneko/Developer/Vampire_Saved/ROMS
tests/test_m3a_reproducible.sh          # after machinery changes
tests/test_hui_boot.sh                  # masked-v2 EXACT legacy leg
tests/test_hui_ex.sh    [build]         # behavior battery
tests/test_hui_grab.sh  [build]         # + the throw-arc static leg
tests/test_hui_air.sh   [build]
tests/test_hui_walk.sh  [build]
tests/test_hui_oracle.sh [rompath]      # ~10 min
tests/test_pyron_ladder.sh              # P stages 1-4
tests/test_pyron_soak.sh                # P 11k chaos
tests/test_gfx_layout3.sh               # 3-tenant layout locks
tests/test_census_regions.sh [build]    # both censuses
tests/test_wide_render_content.sh       # m3a-semantics render gate
tools/run_hui_behavior.sh               # interactive (build/hui9)
```
