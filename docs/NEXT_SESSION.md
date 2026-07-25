# NEXT_SESSION — 60-second orientation (rewritten every session end)

As of 2026-07-25, end of session 5. **M2a stage 4: the FULL port fits and
runs; one under-extraction left in the companion-code zone.**

**Where we are:** All space crises solved — layout groups pin PC-relative
families to source-relative spacing (gaps recycled by the allocator),
segmented gap-tolerant oracle diff handles multi-blob asset regions
(Anita's 44.2K region: 2065 rewritten pointers), hole packing closed at
~335K/336.6K. The init chain progresses past pool alloc, spawn record,
class enqueue, anim-table relocation.

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

**Read:** STATE.md, docs/tables/reconciliation.md (sessions 4-5 sections),
docs/patch_notes.md, docs/GOTCHAS.md.
