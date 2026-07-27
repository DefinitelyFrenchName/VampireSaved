# R1 reconciliation — vsav2 engine references resolved to vsavj

Human twin of `build/manifest/reconciliation.toml` (the machine map the
patch generator consumes; regenerate rows with `tools/reconcile_batch.py`,
hand rows are preserved). Update both in the same commit.

## How rows are produced (methods, in application order)

1. **pattern** — masked instruction-pattern search (operands wildcarded via
   scan_code_refs), window ladder 0x20-0x80. `pattern-1.00-unique` =
   verified.
2. **stub-deref** — `jmp abs.l`/`bra.w` stubs dereferenced to the real
   routine, which is then pattern-resolved (a matching vsavj stub is
   preferred when unique).
3. **callsite anchoring (veteran parallelism)** — the same engine routine is
   referenced from shared veteran/engine code present in BOTH games;
   each vsav2 reference site's context is pattern-matched in vsavj and the
   vsavj operand read out. Unanimous votes = verified.
4. **codebytes/databytes** — exact byte match for position-independent
   stubs / data blobs, unique-hit required.
5. **farm-helper matching** — predicate-farm entries (`lea (d16,PC),A3;
   bra.w common`) matched by their 8-byte parameter-block CONTENT (raw
   view — the blocks are data), since the farms differ in size between
   games and are pure PC-relative.
6. **hand rows** — individually verified (see notes in the toml), e.g. the
   bank delta rule with byte-identity, the allocator family map.

Statuses: `verified` rows are used by the generator; `plausible` only with
`--allow-plausible` (experiment builds); `open` rows route to per-target
planted-ILLEGAL TRIPWIRES (`--tripwire-open`) whose fault PC names exactly
which unresolved target actually fires. The stage-4 behavior gates
(vsav2-as-oracle field comparison, dual-emulator agreement, crash guard)
are the backstop for wrong mappings.

## Structural findings the map rests on

- **Allocator/pool family (MUST map, never port):** vsav2 secondary-object
  pool helpers `0x156D6 + k*0x16` (count `A5+0x7A42+k`, free list
  `A5+0x79E6+4k`) correspond to vsavj `0x016F8E + k*0x16` (count
  `A5+0x79BE+k`, list `A5+0x7966+4k`). Pool-0 was independently verified by
  call-site anchoring. Allocators read the game's own RAM bookkeeping —
  a ported copy sees an empty pool forever.
- **Type-dispatch tables (obj_hook):** seven `movea.l (d8,PC,D0.w),A0`
  dispatch sites exist in both games; five have equal-sized tables, two are
  extended in vsav2 (59→76 at vsavj site 0x054470, 114→124 at 0x05E542) —
  the extras are the newcomers' secondary-object handlers. Handled by the
  extended-table engine hooks (see docs/patch_notes.md).
- **PC-relative reads are decrypted** (docs/GOTCHAS.md) — governs which
  view any engine table is read from.

## OPEN FRONTIER (stage 4, end of session 4)

The companion-object (Anita) spawn chain: Donovan's init hook
(vsav2-only code at 0x8A5A8-zone, ported source-only) allocates pool nodes
and writes a spawn record in **VS2's node protocol**; vsavj's consumer
(node/category dispatch at `PRG:0x0155D0-0x015650`, jump table on
`(0x9,A6)`) crashes on it (vec3, odd ptr 0x17685 via a corrupted list
head). Root cause to resolve next: the **pool-index correspondence is not
identity** (vsav2 pools 2/4 map to which vsavj pools?) and the node field
layout may differ. All instruments (guard traces, write watches, native
vsav2 ground-truth replay `R×2` pick) are in place; see STATE.md.

## Companion (Anita) chain — resolved mechanism (session 5)

The full spawn chain now decodes end-to-end:

1. Donovan init hook (ported, x088512 zone) allocates a pool-2 slot
   ($FFB800 family, 0x80 stride — GEOMETRIES ARE IDENTICAL in both games,
   pool-for-pool: $FF9400/0x100/cat4, $FFB400/0x80/cat8, $FFB800/0x80/catC
   [+0x3C=0xFF seeded], $FFD400/0x80/cat14) and writes the spawn record
   (header long [01,00,type,sub] at +0, owner at +0x30/+0x32, id at +0x39).
   The allocator FAMILY is mapped (vsav2 0x156D6+k*0x16 ↔ vsavj
   0x016F8E+k*0x16), including pool 4 (0x1572E ↔ 0x016FE6).
2. Creation handler (type 116 via the extended table-3 hook) state 0 loads
   Anita's anim table via `movea.l #$2B8060,A0` — the LAST unrelocated
   piece: a self-relative asset blob (table + scripts + sprite tables) with
   vhunt2 twin 0x2A4504 and per-sub-blob micro-shifts (−0x13B5C/−0x13B70
   family). Chunk-BFS over the pointer graph bounds her REACHABLE assets
   at ~44KB (0x2B8060-0x2C3100 + 0x2D6D00 straggler).
3. Class registration: vs2 inserted class 7 into dispatch-site-1 (8 cases
   vs vsavj's 7); site 2 = classes 7-10 (vsavj) / 8-11 (vs2). Class
   machinery: enqueue cases at 0x015618-table, pumps at 0x01ACAA+ (counts
   $FFF9C9+K, heads $FFF992+4K).
4. The +0x3C byte = render/update MODE (0xFF = direct-emit via +0x1C anim;
   managed modes 0-4 via a 5-case dispatch); the pump path that crashed
   dereferences +0x1C unconditionally in emit mode.

REMAINING WORK (space-constrained): extract Anita's 44KB asset graph as
self-pointer data regions and repack the holes — the FULL port needs
~332KB of the 336.6KB free (hole A 258K + hole B 78K): plan = drop the
stage-1 scaffolding ops from stage-4+ builds (~10KB), assign hitbox +
hitbox_proj + aux0_0-3 + Anita to hole B (~78K), everything else to hole A
(~253K). Margins are <4KB — placement needs the per-region hole hints in
donovan.toml. The port_patch subclass remap (0xE→0xC) becomes unnecessary
once she registers via her real machinery — REVERT it when the class-7
enqueue path is synthesized (site-1 word-table thunk design in this doc's
history) or keep class-6 if behavior gates pass.

## Session 5 close: THE FULL PORT FITS — 335K/336.6K placed

Space crisis resolved (was ~9-11K over budget):
- stage-1 scaffolding ops emitted only for stage 1-3 ladder builds
- hitbox_proj honestly bounded (0x1000 cap; sub-table offsets top out at
  +0x5A/+0x400 — the old 0x435A came from the next-ptr +0x4000 fallback)
- only Donovan's own sub-object handler types ported (59-62); the other
  13 extras are Huitzil/Pyron's and stay TRIPWIRED
- aux0 cluster tail margins 0x400 -> 0x180 (gap histogram bound)
- hole hints: aux0_4 + hitbox_proj -> hole B; Anita (x2b8060) -> hole A
- RESULT: hole A watermark 0x0FFA50 (1.4K spare), hole B 0x3FB790 (18.6K)

Anita asset region (x2b8060, 44.2K) extracted via the new SEGMENTED
oracle diff (gap-tolerant: resyncs on 32-byte exact matches after
insertion walls; 2065 pointer fields across 75 segments, 21K in unaligned
dead zones extracted raw). Chunk-BFS graph sizing tool proved the
reachable set before committing space.

CURRENT FRONTIER: vec6 (CHK bounds) at x028122+0x7EE (vs2 0x028910),
frame 2888 — the ported engine char-init code trips an array bounds guard;
init is progressing (2886 -> 2888). Next: disassemble the CHK site, find
the bound + offending index (likely an id/table-space difference).

## Session 6: PC-relative tables solved; frontier = anim state-index

**Solved this session** (crash advanced 2886 → 3025, i.e. character init
now COMPLETES and the match runs 137 frames):
- Brief-format `(d8,PC,Xn)` dispatch tables inside ported code are now
  discovered, bounded (smallest forward displacement — case code follows
  the table), protected from the bare-long relocation heuristic, and
  their escaping entries rewritten as displacements against real
  placement. A fused pair of word entries (`0006 0068` → "pointer"
  0x60068) had been silently corrupting a table. See GOTCHAS.
- `near_map` placement (satellite region within d16 of its anchor) and
  shared per-region ILLEGAL tripwires within d16 reach.
- Slot-clearing allocator wrappers: ported code assumes virgin pool
  slots (vs2 spawns before any recycling); ours get dirty ones. Wrapper
  zero-fills the 0x80-byte slot, preserving the category byte at +8.
  Only Donovan's alloc calls are wrapped; vanilla allocations untouched.

## Session 9 (2026-07-27): +0x14E hook landed; sound stubbed; anim_index_a2; the skew is the ENGINES'

**The +0x14E frontier is CLOSED.** Implemented per the session-8 design
(`[state_hook]` in donovan.toml, emitter in gen_donovan_patch.py):
- 12 SYNTHESIZED case stubs (vs2's are uniform 26-byte state stubs;
  targets = verified twins ret 0x2A7E0 / seq_set 0x2AD94), extended
  long-pointer table, ghost-clean state thunk (vanilla ids jmp back to
  the untouched move.w+jsr; D0 preserved for the stubs' +0x14F compare).
- The stubs' seq ids 0x2CD-0x2D8 index the global palette-seq table
  (vsavj 0x39A900, 32B stride) — also shorter in vsavj, with NO free
  space in the andi-#$fff-capped reach: the 12 records (vs2 0x3B63DC,
  byte-identical in vhunt2 @0x3963B0 — asserted every build) are placed
  in a hole and the 4 consumer `movea.l #base` sites (0x2AD82/0x2AD94/
  0x2B342/0x2B7E8) got ghost-clean base-swap thunks (6-byte site fit, no
  pushes, CCR-safe).

**Sound-farm stubs (8 rows, kind stubbed_sound):** Donovan's move code
calls vs2 sound-farm entries (jsr 0x330E; move.l #sfx,D1; bsr 0x5122;
jmp 0x3306). Sample migration is M5 — until then they map to a vsavj rts
(0x2A7E0) so moves play silently. The vs2 sfx ids are recorded per row in
reconciliation.toml — RESTORE AT M5.

**anim_index_a2 (bank_map "gap_bcefa" RESOLVED):** the fourth table of
the anim/box-setter family (consumer vsavj 0x27EB8 / vs2 0x2710C).
Unported row 0x0F fed Jedah's anim-index row to Donovan's attacks — the
oracle's first-jab box-id mismatch. Reclassified data_ptr/anim; rows
repointed (0xD51BE = vs2 0x281696 relocated).

**New verified rows (skeleton-match at the pool-family delta +0x18B8):**
0x15744→0x16FFC, 0x1581A→0x170D2. **Next rung (moveset replay crashes
5463 via tripwire for 0x17522):** the vs2-only trio 0x17422/0x17522/
0x17B22 called from x028122 — 0x17522 is a per-char (5-bit id) 32B-table
lookup at vs2 0xD22BE with three sub-helpers and a (d8,PC) dispatch on
$B2(a6); no vsavj skeleton within ±0x3000. Port-vs-map decision needs
its A5-global usage checked (-0x4B74(A5) family) against the allocator
rule. NOTE the moveset "END-clean" below was measured BEFORE
anim_index_a2 deepened the path — the oracle battery window passes on
the final build; the moveset gate is the 0x17522 rung.

**Results (pre-a2 for the moveset line):** 12_donovan moveset replay
END-clean (9320 frames, real state machine + VS2-flavor QCB+K). Oracle battery:
p2 HP trajectories EQUAL (both −11 hits land), disagreements 2201 → 890,
all remaining = a ~1-frame action-latency skew... **which the veteran
control proved is the ENGINES' difference, not the port's**: vanilla
Demitri running the same battery on vsav2-vs-vsavj diverges MORE (2379
mismatches) than ported Donovan does (890). Frame-exact cross-game
combat comparison is impossible by construction; the scripted gate
(`tests/test_m2a_stage4_oracle.sh`) locks: anchors equal (2363), neutral
window exact (1100 frames), HP-trajectory equality, and the comparative
bound (ported Donovan ≤ native-veteran divergence).

## Session 8 (2026-07-27): the oracle gate works — two real bugs on first contact

The vsav2-as-oracle behavior gate (17_don_oracle_* replay pair, both games
anchor at the SAME frame 2363 with identical inputs — sibling engines
traverse identical menu timelines) found, on its first runs:

1. **dispatch_14 missing (FIXED, verified):** the bank's "gap_bd7fa"
   auto-kind table is really a per-character CODE dispatch (consumer:
   engine vsavj 0x026244 / vsav2 0x024EDA — `movea.l (tbl,id*4),A0; jmp
   (A0)` — the idle/system-state per-char routine). Row 0x0F still held
   Jedah's 0x529B4, so Jedah's state routine ran against Donovan's data:
   native re-triggers set-anim(0) at intro-end (via vs2 0x5AB64 →
   0x25EBA), ported didn't → the p1_box_ids oracle mismatch (and the
   session-4 "ignores inputs" family). Fix: bank_map reclassified
   gap_bd7fa → dispatch_14 code_ptr; extractor now walks ALL dispatch_NN
   tables (was a hardcoded range(14)); rows 0x0F/0x1F → relocated 0xC0D74
   (vs2 0x5AB64, inside the ported code region). RESULT: 1100-frame
   neutral-idle field comparison agrees on every compared field.

2. **OPEN FRONTIER — the +0x14E state dispatch is an extended engine
   table:** Donovan's QCB+K (VS2 flavor) writes state 0xB6 to player
   +0x14E; the engine's brief-word dispatch at vsavj 0x02A7CA
   (`move.b ($14E,A6),D0; move.w ($12,PC,D0.w),D1; jsr ($E,PC,D1.w)`,
   table 0x02A7E2, **89 entries**) indexes past its table → garbage
   displacement → PC lands in data → ILLEGAL → soft reset (RAM-check
   screen). vsav2's twin site 0x029B50 (table 0x029B6C) has **101
   entries** — 12 newcomer states (idx 89-100, case block ≈ vs2
   0x2AB80-0x2AD7E+, Donovan's QCB+K = idx 91 → vs2 0x2AC2E). Fix design
   (next session): brief-word variant of the obj_hook — patch the site's
   first 6 bytes to `jmp thunk`; thunk re-reads +0x14E, D0 ≤ 0xB0 →
   `jmp` back to the vanilla move.w+jsr (ghost-clean for all vanilla
   states), else dispatch via an extended long-pointer table to the
   PORTED case block (new extra root ~0x2ab80:0x300:s, sibling-veto
   protects it; jsr from the thunk + `jmp site+8` on return). NOTE: a
   naive site survey (797 vsavj vs 779 vsav2 brief sites) needs proper
   reconcile_batch-style twinning to find any FURTHER extended tables —
   expect more of this family as the combat battery deepens (bring-up
   ladder for engine state dispatch).

Also: the in-match battery phase measured natively — Victor takes two
−11 HPs (HP-decrease sanity holds on the native side); the ported-side
battery is blocked on frontier 2.

## Session 7: the "state-index delta" was tooling corruption — RESOLVED; legacy-gate basis now a pending decision

**The session-6 frontier is CLOSED and its hypothesis was WRONG.** The vec3
at engine 0x015096 (frame 3025) was not a VS2-vs-vsavj state-space delta:
the bare-long relocation heuristic had corrupted `moveq #0,d0` at vs2
0x8A49C (`0006 7000` fused into "pointer 0x00067000") in the ported
companion tail, so the "distance in range → just advance anim" path reached
the anim SETTER (vsavj 0x15084, table still in A0=0xE2830) with D0 holding
an X-distance value instead of a state index. Diagnosis: `GUARD_PROBE`
conditional logging breakpoint at 0x15084 with `a0==0xe2830` — the D0 hit
sequence (0,0,2 then 0x80,0x7E,0x7C… every 2 frames from frame 3019) named
the mechanism directly. 46 further bare-long false positives were latent in
x088512/x0905ae (one, at vs2 0x8B382 in the class-registration code,
corrupting `move.w #0,$2a(a5)`). Fix: sibling-veto + immediate-load labels
in the extractor (docs/GOTCHAS.md). **Result: the full 12_donovan_vs_cpu
moveset replay (9320 frames) runs END-clean under the -debug guard — no
crash, no tripwire.** Stage-4 bring-up ladder frontier: none.

**New instrument:** `GUARD_PROBE=hexaddr` + `GUARD_PROBE_COND=expr` on
`run_replay_guarded.sh` — conditional logging breakpoint, PROBE lines
(regs + (SP)) in the log, run continues.

**Legacy gate finding (measured this session, predates session-7 changes):**
the stage-4 build FAILS the bit-exact legacy gate — 02/03 diverge from
frame ~470, attract from 1145. Root cause is NOT a behavior change: the
engine-hook thunks cost cycles on the every-object dispatch path, so
interrupts land at skewed instruction boundaries → (a) dead-stack ghost
bytes below resting SP ($FF7F00-$FF7FFF), (b) the 68k↔QSound handshake
latch $FF043C phase-shifts one frame. With exactly those two windows
masked (`MASK_RANGES="043c-043d,7f00-8000"`), 02 is bit-identical to
vanilla FULL LENGTH and attract first diverges at exactly 4278 (the Jedah
demo — the original stage-1 constant). The hooks were also converted to a
ghost-clean topology (site's first 6 bytes → `jmp thunk`; vanilla
`jsr (A0)` kept at its original address; thunk jumps back to it) which
removes the different-return-address ghost source. Zero-cycle table
extension is impossible (GOTCHAS). **The comparison basis for hooked
builds (whole-RAM vs live-RAM-with-masked-dead-windows) is a maintainer
decision — see STATE.md.**

**Open (documented, unreached in current scope):** the companion tail's
alternate anim table `movea.l #$36784A,A0`, taken when `$3(a6)≠0` (the
spawn-record sub byte). Donovan's init hook always writes sub=0
(`move.l #$1007700,(a4)`), and the full moveset replay never takes the
branch. The operand is intentionally NOT rewritten (no ported region hosts
it); if a future writer sets sub≠0 the branch reads unrelocated vsavj
bytes — plant a tripwire or port the table (its graph references aux0_4 +
a self-band blob near 0x367xxx) at stage-5 close-out.

**Superseded below — session 6's frontier statement, kept for the record:**

**Current frontier (frame 3025, vec3 address error at engine 0x015096):**
the anim-frame setter reads `movea.l #$E2830,A0` (correctly relocated —
that table's bytes are byte-identical to native vsav2 at 0x28ED08, so the
DATA is right), then indexes it with a state byte and lands on an odd
address (A0=0x0E2831, D0=0xfffe0001 — the loaded entry was 1, not the
0x010E in the table at index 1). So the INDEX is wrong, not the table:
something upstream (state/substate byte in the object struct, or the
byte that selects which anim sub-table is used) holds a vs2-flavored
value. Next: watch the writer of the index byte (trace back from
0x0D2092's `cmpi.w #$80,D0` path) and compare against native vsav2 at the
same anchor; likely another VS2-vs-vsavj state-space delta of the same
family as the class-7 remap.
