# NEXT_SESSION — 60-second orientation (rewritten every session end)

As of 2026-07-25, end of session 5. **M2a stage 4: the FULL port fits and
runs; one under-extraction left in the companion-code zone.**

**Where we are:** All space crises solved — layout groups pin PC-relative
families to source-relative spacing (gaps recycled by the allocator),
segmented gap-tolerant oracle diff handles multi-blob asset regions
(Anita's 44.2K region: 2065 rewritten pointers), hole packing closed at
~335K/336.6K. The init chain progresses past pool alloc, spawn record,
class enqueue, anim-table relocation.

**Pick up EXACTLY here:** guard shows vec4 at anim+0x519C (frame 2888) —
a PC-relative call from x088512 (dst 0x0D0170) with source target
~0x905AE: the VS2 companion zone REALLY spans 0x88512-0x915xx (~36K);
our slice is 0x2F00. Budget left: ~4K (hole A) + ~12.9K (hole B) = 17K <
24.8K naive extension. NEXT STEP: code-reachability BFS (jsr/jmp/abs +
PC-rel edges) from Donovan's entry points (0x8B0DA handler, 0x8A5A8 hook,
type-116 chain) through the zone to bound the true subset; if >17K,
either group x088512 with its zone remainder (span cost) and reclaim
elsewhere, or tripwire unreached handlers. All instruments ready:
GUARD_TRACE, segmented diff, chunk-BFS pattern (session-5 scratch),
layout groups ([[layout_group]] in donovan.toml).

**Build/test one-liners:** unchanged — see HANDOFF.md M2a section;
GEN_FLAGS="--allow-plausible --tripwire-open" tools/build_donovan.sh 4 build/donovan

**After the zone closes:** stage-4 gates (test_m2a_stage4_code.sh: pick +
12-replay moveset under -debug guard zero-tripwire; HP-decrease sanity;
vsav2-as-oracle compare (native pick = R x2); dual-emulator; legacy gate),
then stage 5 (select-screen aux pokes), soak, freeze.

**Read:** STATE.md, docs/tables/reconciliation.md (sessions 4-5 sections),
docs/patch_notes.md, docs/GOTCHAS.md.
