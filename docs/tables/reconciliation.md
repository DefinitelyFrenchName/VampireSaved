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
