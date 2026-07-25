# NEXT_SESSION — 60-second orientation (rewritten every session end)

As of 2026-07-25, end of session 6. **M2a stage 4: the full port fits,
Donovan's character init COMPLETES, and the match runs — one state-index
delta left before the stage-4 gates.**

**Where we are:** The port is complete in space and structure: ~335K of
336.6K free ROM placed, all pointer classes relocated (bank/anim/sprite
sub-tables/asset graph/code), R1 map ~120 verified rows, two engine hooks
(extended type-dispatch tables), PC-relative word tables handled, layout
groups + near_map keeping displacement-reachable families together,
slot-clearing allocator wrappers. Legacy suite GREEN (13 replays) on
every build. Init chain runs end-to-end: pool alloc → spawn record →
class enqueue → anim relocation → char-init complete → match live.

**Pick up EXACTLY here (session 6 close):** character init now COMPLETES
and the match runs — crash moved to frame 3025, a vec3 address error in
the ENGINE anim-frame setter (0x015096). The anim word table is proven
byte-identical to native vsav2 (data + relocation correct); the INDEX
into it is wrong (A0 = table+1: loaded entry was 1, not the 0x010E the
table holds at index 1). So a state/substate byte upstream carries a
vs2-flavored value. NEXT STEP: watch the writer of that index (trace back
through the 0x0D2092 `cmpi.w #$80,D0` path in Donovan's ported handler)
and compare the same anchor against native vsav2 (pick = cursor R x2) —
expect another VS2-vs-vsavj state-space delta, same family as the
class-7 queue remap. Guard now dumps D0-D7/A0-A6 at the fault (REGS
line), which is how the index was caught.

**Build/test one-liners:** unchanged — see HANDOFF.md M2a section;
GEN_FLAGS="--allow-plausible --tripwire-open" tools/build_donovan.sh 4 build/donovan

**After the zone closes:** stage-4 gates (test_m2a_stage4_code.sh: pick +
12-replay moveset under -debug guard zero-tripwire; HP-decrease sanity;
vsav2-as-oracle compare (native pick = R x2); dual-emulator; legacy gate),
then stage 5 (select-screen aux pokes), soak, freeze.

**Read:** STATE.md, docs/tables/reconciliation.md (sessions 4-6 sections,
esp. "Session 6"), docs/patch_notes.md (stage-4 progress log),
docs/GOTCHAS.md (5 entries — the last three were all paid this milestone).
