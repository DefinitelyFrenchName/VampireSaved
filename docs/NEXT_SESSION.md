# NEXT SESSION — orientation (written at the close of 14z-68, 2026-08-08)

**Start here: THE SHADOW ITEM, then the WIN-SCREEN PALETTE
(maintainer direction, 2026-08-08). Both are self-contained and
should reach a testable build far faster than the effect arc.**

**THE EFFECT ARC IS PARKED** — deliberately, not blocked-and-forgotten.
It is decoded further than it looks: the union-type mechanism is BUILT
and MEASURED WORKING (dispatch, records and art all native-equivalent
for the beam object), and the one thing standing in front of it is a
TOOLING gap — an embedded data table read with a POST-INCREMENT
walk that neither the census nor the generator's data_in_code
relocator can see. Everything needed to resume is in "THE PARKED
EFFECT ARC" below; resume there when the quick wins are done.

PING #8 = build/hui9 (9e3105e0) is with the maintainer — nothing new
to playtest yet. Frozen references unchanged (donovan-m3a 4b7d0dc7 /
m5_stock 6c93cfa8; m3a-reproducible PASS). Parked-state build
ede6bf15 is all-green.

## THE QUICK WINS (do these first)

### 1. Child-companion shadow — MEASURED AND ATTRIBUTED (14z-68g)
Maintainer clarified: it is **the human child companion's** shadow,
rectangular **all the time** — so replay 82 is a valid repro (he is
on screen throughout).

**It is NOT a shadow-table problem.** vs2's tables are the same size
as vsavj's and the class-0x0C servant path takes 0 probe hits
(14z-68f). Do not re-open that.

**It IS the known bank-0 piece family, now quantified.** OBJ dump,
native vs ours, same frame:
- the shadow's CORE tiles are CORRECT (y=0xC8, codes 0F8B/0F8C/0F8B,
  pal 0x16 — identical on both);
- every pal-0x16 piece in the band at y=0xD0 carries **code =
  native - 0x16A8** and **bank word 0 instead of bank 3** — twelve
  pieces, no exceptions (0F96->F8EE, 0FB7->F90F, 0FA4->F8FC,
  0FA2->F8FA, 0FA3->F8FB), under the child (x 0x2F-0x7F) and again
  at x 0x157-0x1B7.
This is the 14z-67 symptom "F8FC/F90A/F15x-family pieces with BANK
WORD 0 that native never stages — created through a path that leaves
+0x18 unset", so it may share a root with the effect arc and the two
could close together.

**NEXT:** find what stages those band pieces and why their tile word
is -0x16A8 with bank 0. The uniform delta is the lead — a fixed
code-space shift means they read tile words against the wrong base.
(Separate, lower priority: the child's BODY sprites also differ
completely — native pal-0x0D 17A5/17A7/17A9/17AA/0B3F/1781 vs ours
252A/252C/252D, zero overlap — but the maintainer reports the child
itself as acceptable, so treat it as a distinct question.)

### 2. Win-screen palette — DONE (14z-68h, confirmed 14z-68k)
FIXED and shipped in hui10. Source re-derived from vs2's win drawer
(0x6B29C; char id remapped through the byte table at 0x6B2F2 read via
the DATA view -> row 0x59 -> 0x3C2BBC + 0x59*0xA0 = 0x3C635C, a gold
ramp). Verified in RAM, on screen, and finally against a maintainer
NATIVE CAPTURE.
**Item 5b ("garbled blue-grey blocks") is CLOSED BY THE SAME FIX** —
the native capture shows those regions are MAGENTA in the real game;
they only looked blue-grey on hui9 because the palette was wrong.
There was never an art defect: all 134 portrait tiles are
byte-identical to vs2.
ONLY REMAINING: the win QUOTE TEXT differs from native (same theme,
different line). Awaiting the maintainer's answer on whether win
quotes ROTATE per win — if they do, ours is likely a valid alternate
line and the item closes. The quote rows ARE already repointed
(table 0x2672AA rows 0x70/0x90 -> wide_ext).

Both are single-screen, non-gameplay surfaces, so the masked legacy
gates arbitrate cheaply and neither needs the effect machinery.

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

## THE PARKED EFFECT ARC (resume here after the quick wins)
## Step 1 is a TOOLING fix: the data_in_code post-increment shape

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

**Blocker 1 is NOT a stamp problem (14z-68e settled this).** There
is no per-effect discriminator to find at that site: the selector D1
is 0x0C for the ray AND the DF case, and the attacker/victim state
bytes are identical at the spawn frame. Replay 82 activates DF FIRST
and then fires the ray, so the crashing object IS the ray object,
processed while DF is active. The crash decoded into three stacked
defects instead:
1. **Headroom.** vs2 indexes its record table with SIGNED offsets
   that go below the base (measured d0 = 0xFFF3 = -13; on vs2 the
   base has ROM underneath). Our base was at 0x400010, the first
   address of wide_ext, so the read hit the RESERVED CpsFrg window
   `$400000-$40000F`. Moving wide_ext's start to 0x400400 moved the
   fault address, proving it. **Leave headroom below any region whose
   consumers index negatively.**
2. **The index is wrong too.** With headroom the address is still
   ODD, and vec3 is an ADDRESS ERROR — native's equivalent read would
   fault identically, so d0 = 0xFFF3 is not what native reads.
3. **THE REAL ONE — an embedded DATA table the tooling cannot see.**
   a3 is set by `lea $6D868(pc),a3` and read with `move.w (a3)+`.
   The two views differ completely at 0x6D868 (opcode
   `b8020919f5c7…` vs data `0001005800000000…`) and the DATA view is
   correct: 0x6D878 gives **0x0064**, even and sane. RAW placement
   does NOT fix this — raw storage holds one image (the opcode view,
   so it executes), so data reads still see the wrong bytes.

**DO THIS FIRST, ahead of any stamp work:** teach the POST-INCREMENT
reader shape to BOTH `tools/census_regions.py` (its detector matches
only `lea (d16,pc),An + (An,Xn.w)`, which is why this region reported
clean) and the generator's `data_in_code` relocator (its only
supported reader is `lea (d16,pc),a1 + move.b (a1,d0.w),d0`), add a
frozen case to `tests/test_census_regions.sh`, then relocate this
stream as data and re-run `test_hui_pairs` FIRST.

**Blocker 2 — the beam still does not draw.** Unchanged, and note it
may well share root layer 3: with dispatch, records and art proven
equivalent, an embedded table reading garbage is exactly the kind of
thing that would leave the emitter with nothing to draw. Re-measure
after the data_in_code fix before hunting further.

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
