# NEXT SESSION — orientation (written at the close of 14z-68, 2026-08-08)

**Start here: NARROW THE TENANT-TYPE STAMP (the arc below). The
whole union-type mechanism is BUILT and MEASURED WORKING — dispatch,
records and art are now native-equivalent for the beam object — but
it is PARKED because the stamp is too broad (it crashes Dark Force)
and because, even with the path equivalent, THE BEAM STILL DOES NOT
DRAW. Two named blockers, both with next probes.**

14z-68 also refuted the 14z-67 entry theory, exonerated the fighter
side twice over, corrected its own first conclusion (the beam object
is spawned, not missing), and fixed FOUR real defects along the way:
the ported spawner region excluded its own record-base load; the
region was rooted at the middle of vs2's row-8 machine instead of
its entry; and two engine sites tested newcomer char ids against a
WORD-loaded mask, reading a stale high word (undefined).
**PING #8 = build/hui9 (9e3105e0) is still with the maintainer —
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

## THE ARC: NARROW THE TENANT-TYPE STAMP, then find why the beam
## does not draw (the dispatch/record path is already equivalent)

14z-68d built the whole union-type mechanism and MEASURED it working.
Do not re-derive any of this — un-park and continue:

**Proven and in the manifest, PARKED together** (`tenant_type_stamp`
+ the `[[obj_hook_extra]]` row): the stamp fires (+0x02 = 0x7C02),
the object is then ticked by the PORTED vs2 row-8 machine with every
PC normalising EXACTLY to native's sequence (06cadc/06cae2/06cae8/
06caee/06caf4/06cb5a/06cb86/06cb8e/06cb96), its record resolves to
placed base + 0x63C — native's own relative offset — and the record
AND its sub-records are BYTE-IDENTICAL to vs2's (pointers relocated
by exactly the region delta 0x14811C). Dispatch, records and art are
all native-equivalent.

**Blocker 1 — the stamp is too broad (fix this first).** Un-parked,
it regresses `test_hui_pairs`: Dark Force takes a vec3 at PC
0x0D4696 inside the ported machine (f3220, ADDR 0x4029FF, A2 =
0x400010 our record base, A1 = 0x3FFEEE reading BELOW it — an index
underflows the placed region). The victim-spawn site (vj 0x60EE0)
serves EVERY hit of this class from the tenant, not just the ray, so
DF's objects get routed into a machine that mishandles them. Narrow
the stamp to the RAY EFFECT specifically — per-effect, not per-hit
(candidate discriminators: the spawn selector D1, or the victim's
reaction/effect id) — then re-run pairs FIRST.

**Blocker 2 — the beam still does not draw.** With dispatch, records
and art proven equivalent, the residual is the EMITTER path or a
draw flag, not the data. Native emits its 14 sprites right after the
fighter's own 3; ours emits none. Next probes: what the emitter
walks for this object (the +0x1c chain is installed once and does
not advance on either game), and whether a visibility/priority flag
on the object differs.

**Already shipped, do not redo:** the region now covers vs2's WHOLE
row-8 machine (`0x6cac0:0xebc:t0x6cc34`, region x06cac0 — the
14z-68b root was its middle); the generator has `[[obj_hook_extra]]`
for authored union rows (flat table matched by `site`; no-gap
assertion since the engine indexes by type*4); two newcomer-id mask
widenings; and the record-base boundary fix.

Reference facts: the walker reads the type from **+0x02**
(`move.b $2(a6),d0; add.w d0,d0; add.w d0,d0`), so any type >= 114
is unreachable for vanilla objects by construction. The
discriminator is the victim's **+0x32 -> attacker**, **+0x382 ==
0x10** (vs2's own in-machine test). vs2 row 8 = 0x6CAC0, vj row 8 =
0x606AC, vs2 rows 114-120 = the already-ported newcomer types.
Type tables decode from the OPCODE view only.

Two OLDER thunks stay parked (un-park with the port, not before):
`piece_prebake` (vj 0x18F88) and `fleet_record_base` (vj 0x60DD4 —
base-only swap crashes ES; base+stream+count+updater are ONE unit).

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
