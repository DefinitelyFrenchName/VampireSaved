# NEXT SESSION — orientation (written at the close of 14z-68, 2026-08-08)

**Start here: GIVE THE BEAM OBJECT A TENANT TYPE (the arc below).
14z-68 refuted the 14z-67 entry theory, exonerated the fighter side
twice over, and then corrected its OWN first conclusion: the beam
object is NOT missing — our build spawns it, but it is type 0x08 (a
SHARED type), so the pool walker ticks it with the VANILLA machine
and vanilla records. One real bug was found and FIXED along the way
(the ported spawner region excluded its own record-base load); the
rest of the session is documentation, rigs, and one gate.
PING #8 = build/hui9 (9e3105e0) is still with the maintainer —
nothing new to playtest.** Frozen references unchanged
(donovan-m3a 4b7d0dc7 / m5_stock 6c93cfa8; m3a-reproducible PASS).

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

## THE ARC: give the beam object a TENANT TYPE so it runs the
## ported machine (the spawn already happens)

**The render-level target** (OBJ dump, replay 83b): native draws the
beam as **one object** — $FFBA00, spawned by vs2 0x6D32A, **owner =
the VICTIM** ($FF8800), chained into the companion records at
0x2B8530 (= base + 0x63C) — emitting 14 sprites: bank-3 codes
0x1E2F/0x1E42/0x1E5F pal 0x0C (H's own band, art present at delta 0
in our group C bank 4), the long stretch segments bank-1 code 0x4EC0
at sz 4x1 and 16x1, and the impact 0x1E84 pal 0x0F.

**Ours already spawns that object** ($FFB880 via the VANILLA vj
0x60EE6, same owner 0x8800, same header 0x0100/0x0802) — but it
chains to the VANILLA record base (0x283690 + 0x62C) and is ticked
by the VANILLA machine (vj 0x606C8/0x60746/0x60DBA). Proof the
porting machinery itself is fine: the neighbouring persistent
companion object carries the SAME relative offset (+0x222C) with
the bank correctly remapped 0x6000 -> 0x1000.

**Why it takes the vanilla path: the object is TYPE 0x08, a SHARED
type.** The pool walker per-type table — already obj_hook'd at site
0x5E542 (vanilla 114 entries / vs2 src 0x6A51C, 124) — dispatches
type 8 to the vanilla machine, because vs2 rewrote its OWN row-8
machine. So the fix is the established **union pattern one level
down**:
1. extend the ported region DOWN over the tick machine — measured
   native PCs 0x6CADC/0x6CAE2/0x6CAE8/0x6CAEE/0x6CAF4/0x6CB5A/
   0x6CB86/0x6CB8E/0x6CB96 all sit below the current boundary.
   **0x6CA00 does NOT pattern-twin at +0x174** — find the real
   boundary (0x6D1E0 twins cleanly at +0x174, already used);
2. give tenant-spawned instances a NEW type (>= 114) with a union
   row pointing at the ported machine entry;
3. gate the type write to tenant-spawned instances — the
   discriminator must come from the SPAWNING CALL PATH, since the
   object owner is the victim (a vanilla character);
4. then un-park the two thunks below as the final wiring.

**ALREADY FIXED AND SHIPPED (14z-68):** the ported spawner region
began at 0x6D240 while the routine own record base load
`movea.l #$2B7EF4,a2` sits at **0x6D200** — 0x40 bytes below, so the
region could never relocate its own base. Root is now
`0x6d1e0:0x560:t0x6d354`; the base relocates to the placed 0x400010
(one occurrence, at 0x6D202). Region renamed x06d240 -> x06d1e0.
Build cf519de8, gates green, 2P legacy bit-identical.

Two thunks are PARKED with full anatomy in huitzil.toml — un-park
them WITH the port, not before:
- `piece_prebake` (vj 0x18F88; a6 = spawning fighter, a4 = new
  piece): installs bank + record at 0x4001F4 = placed base + 0x1E4
  = native own relative offset. Gates green, 2P legacy
  BIT-IDENTICAL (site is cold for legacy — 3 hits, the 3 rays).
- `fleet_record_base` (vj 0x60DD4): base-only swap CRASHES the ES
  flow — the ES driver shares subtype 0x0D and its param stream
  carries vanilla-base offsets. Base + stream + count + updater are
  ONE unit.

Known twins/R1, already resolved: piece machine vj 0x5E780 <-> vs2
0x6A770 (per-seq pc-rel table vj 0x5E7A4 / vs2 0x6A798; walker vj
0x5E540 stride 0x80, type table 0x5E556; rows 2+ are 40-42/48
byte-identical, differing only in R1 addresses). Engine pairs
0x13778->0x15084, 0x13724->0x15030, 0x13c0e->0x1551a,
0x157c2->0x1707a, 0x5122->0x4ce2 are all in reconciliation.toml.
x022400 is placed at 0xC7070; x06d1e0 at 0xD3EF0.
The fighter side is EXONERATED twice over — do not re-open it.

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
