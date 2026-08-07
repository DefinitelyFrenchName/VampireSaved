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

## Session 13 (2026-07-28): the whole mash-crash chain is CLOSED — bank-tail dispatch run + the pre-region anim table

After the sound-farm fix, the mash soak surfaced two final rungs, both
found by the standard instruments and both structural:

1. **Bank-tail dispatch run (dispatch_15-19):** the engine state chain at
   vsavj 0x23258 (`movea.l #$BF31A` + id*4) dispatches through a RUN of
   per-char code tables at the bank tail (0xBF21A/31A/39A/49A/61A) that
   the session-4 triage left unmapped ("no ported-code consumer" — wrong:
   the consumer is the ENGINE). Rows 0x0F still ran JEDAH's handlers on
   Donovan; Jedah's anim-advance walker dereferences (0x18,A0) of the
   current record — an indirection Donovan's records don't have —
   writing a garbage anim cursor (the vec4@0x1AFD6 mid-instruction jump
   and its ilk). All five tables' vs2 rows land inside the already-ported
   code region: added to bank_map as dispatch_15-19, auto-repointed.
   (Parked with documented shapes: 0xBF01A-19A data rows, 0xBF59A engine
   rows, 0xBF51A zeros, 0xBF69A sentinel.)
2. **x2b8060 was under-bounded by 0x16C:** a companion anim word table
   sits at vs2 0x2B7EF4, just BEFORE the region start; its ref rode a
   tripwire that the anim setter then read as a table (vec3 with A0 in
   the tripwire band). Root extended to 0x2b7ef4:0xb20c (twin 0x2A4398,
   extension byte-identical in vhunt2).

RESULT (fingerprint 372b0641): all four guarded soaks END-clean (mash
14120, moveset 9320, DP-spam 5930, round-2 12120), the 40K arcade
marathon cycles through game-over and attract normally, and the full
gate battery is green. Flicker inventory: 08_challenger_join carries a
second attributable single-frame flicker (3807) since the farm fix
changed the sound-call cycle profile — same mechanism, within tolerance.

## Session 12b (2026-07-27): THE MASH WEDGE IS ROOT-CAUSED AND FIXED — sibling-coincident sound-farm refs

The mechanical protocol delivered in one pass: video-hash bisection pinned
the onset to (11160,11170]; the healthy-vs-wedged trace showed the wedged
frame executes only ~324 unique PCs — kernel + sound service + the ported
meter loop — and the loop's exit branch NEVER fires. The loop
(`subi.w #$90,D0; bra` with a `bcs` exit) is mathematically bounded, so
the only way it runs forever is its `jsr 0x3B2C` corrupting D0 — and it
does: **vsavj's 0x3B2C is a DIFFERENT sound-farm entry** (no 0x330E save;
"restores" stale registers via 0x3306) than vs2's 0x3B2C (a
self-contained save+sfx-0x172+restore entry). The operand was carried
raw because vs2==vhunt2 at that address — invisible to the sibling diff
(the same-value hazard scan_code_refs' docstring warned about). Full
mechanism + rules: docs/GOTCHAS.md (new entry).

FIXES:
1. extract_char: scanner-labeled engine operands are merged into twinned
   regions' refs when the sibling diff missed them (33 surfaced).
2. reconciliation.toml: +20 verified rows — 0x3B2C→0x3AF6 (unique body
   match), 0x330E/0x3306 identity (24B byte-verified — kernel
   save/restore), 17 sound-farm entries by save+sfx-id signature
   (drift −0x36..−0xDA; dual-entry pairs disambiguated by next opword;
   duplicate-id pair by helper calibration 0x5122↔0x4CE2).

RESULT (fingerprint 450b5800): 26_don_arcade_mash runs the FULL 40K-frame
marathon — matches, game over, and the post-game attract cycling its
demos and story scenes normally. The wedge, the "different music"
(chime-request spam), and every earlier hang manifestation are one bug,
now closed.

## Session 12 (2026-07-27): seq-hijack fixed (real defect); the mash wedge remains OPEN — theories eliminated

**FIXED — the palette-sequence hijack (real defect, found while chasing
the wedge):** session 9 assumed vsavj's global palette-seq table ended
before id 0x2CD; WRONG — vsavj has its own LIVE records there. The
session-9 base-swap thunks on the 4 shared consumers hijacked those ids
globally. Redesign (session 12): the 4 consumer sites are RESTORED to
vanilla; Donovan's 12 state stubs reach the VS2 records via a PRIVATE
12-byte entry (movea.l #records-0x2CD*32,A0; jmp seq_set+6 — into the
engine AFTER its own base load). Vanilla palette flows are now fully
untouched. Moveset + mash soaks green on the new build.

**OPEN — the sustained-mash wedge (deterministic, uncharacterized):**
26_don_arcade_mash still wedges (new build: mid-match vs Bulleta,
display-frozen ≤14000 while RAM advances; quiet-27 variant wedges at the
same frame → not input-driven past 12000). ELIMINATED this session:
(a) the palette hijack (fixed; wedge persists), (b) meter/stock anomaly
(+0x3B2=0 and 99-cap are NORMAL — identical on native vs2 Donovan AND
vanilla Demitri both games; measured from the oracle dumps), (c) the
"Lilith event scene" interpretation — the old-build sequence was the
post-game-over ATTRACT flow (intro movie → title → wedge), i.e. the
wedge follows long mash content, not a specific scene. The PC profile in
the wedged state shows normal per-frame flows (meter routine + sound
service) — something stops WRITING THE DISPLAY (OBJ list/palette) while
logic continues.

**NEXT-SESSION PROTOCOL (mechanical, no theorizing):** (1) video-hash
bisection on 26/new-build — snapshots every 200 frames in 8000-14000,
then step 25 → wedge onset ±25; (2) GUARD_TRACE a 2-frame window at
onset AND at onset-200 (healthy), diff the per-frame call graphs — the
subsystem present in healthy and absent in wedged frames is the answer
(prime suspect: the display-list builder / V-blank copy path); (3) also
diff full RAM at onset±1 for the state byte that flips. All instruments
exist; the repro is deterministic.

## Session 11c: playtest round 3 — the hang is the LILITH EVENT SCENE (open frontier, deterministic repro)

Maintainer round 3 (on cdf62d8c): still a hang-like state under mash —
screen wipes, a new slow-scrolling background + different music, then
unresponsive with stale visuals. Chased through five negative repros
(dual-mash 22, match-win 23, win-mash 24, explicit Dark Force 25 — DF
ACTIVATES AND EXPIRES CLEANLY, screen-darkening verified by snapshot —
all END-clean) before landing it with **26_don_arcade_mash** (1P arcade,
dense chords, multi-match): display freezes between frames 13500-14000
while RAM keeps ticking (no exception, no tight loop). Snapshot at 13500
= the **Lilith/Morrigan event cutscene** — corroborating the maintainer's
very first report ("I was fighting Lilith"). At frame 20000 the P1
struct is fully TORN DOWN (all zeros) yet Donovan's per-char meter
routine (ported x028122 code, the +0x109 stock loop at src 0x28D92 —
correctly identified as meter-gain, jsr 0x3B2C = stock chime, +0x3B2
selects the stock cap) still executes each frame with A6=$FF8400 and a
dispatch id of 0x0F (probe D1=0x3C) — something in the event-scene flow
keeps dispatching slot-0x0F per-char machinery against the empty struct,
and the scene never advances.

NEXT SESSION (bisection plan): dump the P1 struct + scene-mode globals
at 13600/13700/13800/13900 to catch the teardown moment; identify WHAT
dispatches the per-char routine during the cutscene (GUARD_PROBE at the
dispatch_14 site 0x26244 and dispatch_00 shim with A6/id logging); then
compare the native vs2 1P arcade flow at its Lilith-event equivalent
(does vs2 guard its newcomer init against non-match scenes?). Suspects,
in order: (1) the event scene re-inits P1 via dispatch_00 row 0x0F and
Donovan's ported init assumes match infrastructure (pools/companion);
(2) dispatch_14 row 0x0F running in a scene context where Jedah's
vanilla routine was scene-safe and Donovan's is not; (3) a stale class-6
companion queue entry surviving scene teardown.

## Session 11 addendum: second playtest round — the mash/time crash

Playtest round 2 (on d6d8f273): DP fixed ✓; new crash "after ~a round of
play OR mad input spam". Round-transition soak alone (20_don_round2,
idle through timeout into round 2) is CLEAN — the trigger is activity:
the mash soak (21_don_mash, dense deterministic input chaos incl. Start
taps) crashes vec3 at engine 0x1AFB2, frame 3219: a **type-114 effect
object** (companion-pool slot $FFBC00) carries anim cursor 0x1D772A — a
raw VS2-space pointer. Root cause: its ported creation code does
`movea.l #$1D7428,A0; jsr set-anim` — the jsr was R1-remapped but the
TABLE immediate points at an ENGINE-SHARED anim word table hosted by no
ported region, and unhosted address immediates were being silently
carried raw (the documented residual-risk case of the sibling veto).
FIXES:
1. Extractor rule: `movea.l #imm,An` with an un-hosted ROM target is now
   an ENGINE ref (addresses by construction) → R1 row or loud tripwire;
   `move.l #imm,Dn` stays hosted-only (constants). This also retired the
   manual imm_poison for 0x36784A (now auto-tripwired — one mechanism).
2. New engine_data row: vs2 0x1D7428 → vsavj 0x1F3FD2 (the same shared
   effect anim table — 24-byte content match, unique in vsavj).
RESULT: 21_don_mash END-clean (14120 frames). Since type-114 effects
also spawn in normal play, this most likely explains BOTH reported
modes (spam and after-a-round). 20+21 join the code gate's guarded set.

## Session 11 (2026-07-27): first human playtest — triage of all four findings

Maintainer playtested the stage-5 build. Findings and dispositions:

1. **Garbled sprites, recognizably Donovan + Anita** — expected (M2b).
2. **Flavor hard to judge by eye** — expected; the machine fork is QCB+K
   (latch test covers it).
3. **4-option select (normal/turbo/auto/auto+turbo) suspected VS2-like**
   — REFUTED as a port artifact: vanilla vsavj with factory-fresh EEPROM
   shows the identical 4-option menu (pixel-identical snapshots, vanilla
   vs patched, same fresh NVRAM). The 2-option arcade experience comes
   from operator-disabled auto modes in the service EEPROM settings.
4. **DP-spam crash — REAL, reproduced deterministically, root-caused,
   FIXED.** New replay 19_don_dp_spam (meter build + 42 DP attempts incl.
   ES pairs) crashes vec4 at engine 0x18498, frame 3711: the DEFENDER-side
   hit-reaction dispatch (vsavj site 0x18460, table 0x18468, real extent
   ~81 ids; vs2 twin 0x16D2C/0x16D34) is another EXTENDED brief-word
   table — vs2 adds reaction ids 0xA2/0xA4/0xA6, and Donovan's **ES DP**
   inflicts 0xA2 (the 12 battery never pressed two-button ES versions —
   coverage gap, now closed). The three vs2 cases are position-independent
   one-liners on A1/A3 (copy attack-record byte +0x17 into defender
   +0x54, etc.) — synthesized VERBATIM from config hex
   (donovan.toml [reaction_hook]); ghost-clean topology patches the
   preceding tst/bne pair and leaves the original dispatch untouched for
   vanilla ids. 19_don_dp_spam now runs END-clean and joins the code
   gate's guarded set.

Also fixed this session: **gate coverage gap** — 04_select_fuzz /
08_challenger_join / 09_mirror_pick had fallen out of the legacy gate
when it was rebuilt on the masked basis. Measured on the stage-5 build:
all three are pure FLICKER class (isolated single-frame re-converging —
04@1525/2009/2195, 08@3507, 09@829); frozen masked vanilla logs added,
replays added to the gate's flicker list. The masked legacy gate now
covers all 13 original replays.

## Session 10 (2026-07-27): the damage pipeline — trio resolved by callsite anchoring; moveset replay CLEAN on the full build

The session-9 "0x17522 trio" is the DAMAGE PIPELINE, and it is NOT
vs2-only — the skeleton scan missed it because vsavj's implementations
drifted internally. The decisive instrument was the KO-write signature
(`move.w #$FFFF,$50(a1); move.w #$FFFF,$52(a1)` — two hits per game,
positions parallel), which located vsavj's damage WRAPPER at 0x189BA —
**instruction-for-instruction byte-parallel** with vs2's 0x17330 wrapper
(same A5-global shape at drifted displacements, same call structure,
same KO path). Every bsr position votes:

| vs2 | vsavj | role |
|---|---|---|
| 0x17522 | 0x18B8C | per-char defense-scaling calc (5-bit id, 32B table) |
| 0x17422 | 0x18AB0 | damage post-process |
| 0x17B22 | 0x19128 | KO handler |
| 0x173DE | 0x18A6C | halve-damage helper (positional, not yet needed) |
| 0x17806 | 0x18E46 | (positional, not yet needed) |
| 0x175AE | 0x18C08 | damage apply (positional, not yet needed) |

Consequence: Donovan's ported char-init code (x028122's jsr sites) now
calls VSAVJ's own damage machinery — per the allocator rule (engine
subsystems reading the game's own RAM/table state are MAPPED, never
ported). His damage scaling therefore uses vsavj's defense table, which
is the CORRECT superset semantics (he is a vsavj character).

**RESULT: 12_donovan_vs_cpu END-clean (9320 frames) on the FULL build —
real state machine + VS2-flavor QCB+K + damage pipeline. No crash, no
tripwire.** Gates re-run on fingerprint 67753ee3 (see STATE).

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

## 14z-65 — Huitzil's R1 arc (M3b): batch rounds + the five sound stubs

The map is now MULTI-TENANT in content: two `reconcile_batch` rounds over
Huitzil's stage-4 extraction merged into this file (50/101 of his first
engine surface was already Donovan-mapped — shared consumers; ~49 new
verified rows; Donovan's builds proven bit-exact through both rewrites).

**Five `stubbed_sound` rows added BY MEASUREMENT** (ids 0x72a / 0x73c /
0x743 / 0x749 / 0x74a at vsav2 0x4ddc/0x4e5e/0x4e78/0x4f48/0x4f96 -> the
engine rts 0x2A7E0): the ids sit BETWEEN the documented vsavj music
ranges, so "music" was not assumable — the QSound key-on records
(docs/m5/keyons_*.json) show vsavj's same-id entries key DIFFERENT
multi-voice music-class content vs vs2's single-voice samples for all
five. Same-id mapping would play wrong sounds mid-match; silenced until
the M5 voice-bank port. 0x4e78 was the FIRST tripwire Huitzil's init hit
(f2887) once the fall-through layout group let his handler body run.

Open Huitzil rows (18 tripwired targets remain in his stage-4 build):
the companion family (0x2b7ef4/0x2b8060/0x36784a — guarded soaks
decide), engine subs 0x4223c/0x42cee/0x448d4/0x3844e, and mid-ROM data
refs — the per-target grind continues at the next crash/soak frontier.

## 14z-66 — the EX-move crash-reset: three more farm stubs (playtest item 1)

Maintainer playtest round 1 reported BOTH EX moves (Final Guardian
623+2K, Erasing Sphere 421+2K) running most of their animation then
crash-resetting (watchdog signature). Scripted repro (replays
tests/replays/hui/71-73, stock poked via ff8509 per the 14z-44 recipe)
caught it in the guard timeline: **one shared one-shot voice cue**, the
`tst.b $23(a6) / clr.b / jsr 0x4EFA` sequence at support zone
x0689cc+0xec, reached the open tripwire for farm row vs2 0x4EFA — vec4
at f3513 (ES, ~97 frames into the move) and f3364 (FG at connect range,
~98 frames in). In a plain run the ILLEGAL lands in a garbage vector =
the watchdog reset the maintainer saw. A whiffing FG never reaches the
cue (replay 71 ran clean mid-range) — connect range was load-bearing
for the repro.

**Three `stubbed_sound` rows added** (vs2 0x4efa/0x4fb0/0x4fca, ids
0x748/0x729/0x72e, disasm-verified): all newcomer voice-bank range
(0x7xx), the established stub-on-sight class — same shape as the
existing six. RESTORE AT M5. With them the ES fires repeatedly to
completion at both ranges (stock 9->6 across three attempts, guard
clean end-to-end). Gate: tests/test_hui_ex.sh (guard-clean AND
stock-consumed — the anti-coverage-loss shape); its negative control is
measured, not synthetic: both replays CRASH deterministically on the
pre-fix build.

Open Huitzil rows after this: 15 tripwired targets (the three farm rows
resolved out of the 18 above).
