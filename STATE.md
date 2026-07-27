# STATE — living progress log

Updated: 2026-07-25 (session 7 end — M2a stage 4: bring-up ladder DONE,
full moveset replay runs clean; legacy-gate comparison basis awaiting
maintainer decision)

## Session 7 highlights (M2a stage 4 — frontier closed; the crash was ours)

- **The session-6 "anim state-index delta" was NOT a state-space delta.**
  It was extraction tooling corruption: the bare-long relocation heuristic
  fused instruction operand pairs (e.g. `clr.b $6(a6); moveq #0,d0` =
  `0006 7000`) into plausible pointers and rewrote them — 47 false
  rewrites latent in the two source-only zones; one destroyed the
  `moveq #0,d0` anim-state reset, sending an X-distance value into the
  engine anim setter (the vec3 at 0x015096/frame 3025). Diagnosed with a
  new guard instrument (`GUARD_PROBE`/`GUARD_PROBE_COND` conditional
  logging breakpoint — the D0 hit sequence told the whole story).
- **Extractor hardened (tools/extract_char.py + scan_code_refs.py):**
  immediate loads (`movea.l #imm`/`move.l #imm`) are now labeled refs;
  every bare-long candidate is validated against the vhunt2 SIBLING
  (context match with labeled operands wildcarded): identical sibling
  bytes → vetoed (operand pair), host-shift-consistent → confirmed,
  conflicting/absent evidence → rejected loudly. 47 vetoed/rejected,
  5 confirmed real, 0 silent keeps. Details: docs/GOTCHAS.md.
- **RESULT: the full 12_donovan_vs_cpu moveset replay (9320 frames) runs
  END-clean under the -debug crash guard.** No crash, no tripwire. The
  stage-4 bring-up ladder has no frontier.
- **Legacy gate measured honestly (this predates session 7's changes):
  the stage-4 build fails bit-exact whole-RAM comparison** — NOT from a
  behavior change: engine hooks cost cycles on the every-object dispatch
  path; interrupts then land at skewed boundaries → dead-stack ghost
  bytes ($FF7F00-$FF7FFF, below resting SP at frame-done) + the QSound
  handshake latch $FF043C phase-shifts one frame. Hooks converted to a
  ghost-clean topology (vanilla `jsr (A0)` kept in place; thunk jmps back
  to it) removing the push-value ghost; the interrupt-skew ghosts are
  physically unavoidable (zero-cycle table extension proven impossible —
  GOTCHAS). **With exactly those two windows masked, 02 is bit-identical
  to vanilla full-length and attract first diverges at exactly 4278 (the
  Jedah demo).** Live state is vanilla.
- `MASK_RANGES` opt-in on replay.lua (canonical checksums unchanged when
  unset); new gate `tests/test_m2a_stage4_code.sh` locks all of the above.
- **Session-7 extension (after the maintainer approved the masked basis):
  widening the masked legacy gate from 1 to all 7 exact replays found the
  v1 masks are not sufficient alone.** Measured:
  - 03/10/16 each show 1-2 ISOLATED single-frame divergences that fully
    re-converge (03: frames 829+2093 — 829 is the S2 input-accept
    boundary; 10: 3007+3129; 16: 829). Transition state captured one
    frame apart; bytes involved: $FF80B5, object-slot heads
    $FF8400/$FF8800. A real bug in this deterministic engine cannot
    re-converge to bit-identical whole-RAM; bounded re-converging
    flickers are a timing-phase signature. New ground-truthed comparator:
    `tools/compare_flicker.py` + `tests/test_compare_flicker.sh`.
  - 06_test_mode diverges PERSISTENTLY from exactly frame 700 — the TS
    press. Root cause is hook-caused, not ROM-content (stage-3 builds,
    ROM-modified but hook-free, ran 06 bit-identical): service-mode code
    reads the phase-shifted QSound latch and the offset propagates into
    live service state (residue: sound mirror + two checksum/accumulator
    words). Benign, no gameplay surface, but a letter violation.
  - 02/05/07 masked-exact full length; attract 4278 and pick 1080 masked
    diverge-constants hold. Whole-live-state identity therefore holds for
    all match gameplay; the exceptions are input-boundary flickers and
    service mode.
- **2026-07-27 (session 10): BOTH stage-4 gates PASS on one build
  (fingerprint 67753ee3) — the first all-green run with every system
  active.** The "0x17522 trio" turned out to be the DAMAGE PIPELINE and
  is mapped, not ported: the KO-write signature located vsavj's
  byte-parallel damage wrapper (0x189BA ↔ vs2 0x17330) and every bsr
  position voted — 0x17522→0x18B8C (defense-scaling), 0x17422→0x18AB0
  (post-process), 0x17B22→0x19128 (KO). Donovan uses vsavj's own damage
  machinery (correct superset semantics). Moveset replay END-clean 9320
  frames; code gate green (incl. masked legacy, flickers unchanged);
  oracle gate green. **And the dual-emulator gate PASSED
  (test_m2a_stage4_xemu.sh: patched build on MAME + patched FBNeo,
  anchors 2363/2364 — 1-frame skew — all mapped fields agree at follow
  0/60/180). ALL THREE STAGE-4 GATES GREEN on fingerprint 67753ee3:
  STAGE 4 IS CLOSED.** Next: stage 5 (select plumbing + Start-hold
  flavor selector), soak, freeze.
- **2026-07-27 (session 9): the +0x14E frontier is CLOSED and the
  ORACLE GATE PASSES as a scripted test.** The state hook landed
  (synthesized case stubs + ghost-clean thunks + relocated palette-seq
  records + 4 consumer base-swaps — patch_notes session 9); Donovan's 8
  sound-farm calls stubbed silent (M5 restores; sfx ids recorded in
  reconciliation.toml); anim_index_a2 resolved from gap auto-kind (was
  feeding Jedah's anim rows to Donovan's attacks). Moveset replay
  END-clean again. `tests/test_m2a_stage4_oracle.sh` PASS: anchors equal
  (2363), neutral window exact, P2 HP trajectories equal (hits land,
  same damage), and the comparative bound — ported Donovan diverges
  LESS across the two engines (890 mismatches) than vanilla Demitri
  does (2379): the residual ~1-frame action-latency skew is the
  ENGINES' cross-game difference, proven by the 18_veteran_ctl control
  pair. Remaining stage-4 behavior work: dual-emulator gate (16-pattern
  Donovan replay on MAME + FBNeo), then stage 5.
- **2026-07-27 (session 8): the vsav2-as-oracle behavior gate is BUILT
  and immediately caught two real bugs.** Replay pair 17_don_oracle_*
  (both games anchor at frame 2363 — sibling engines run identical menu
  timelines). Bug 1 FIXED+verified: "gap_bd7fa" was really dispatch_14
  (per-char code dispatch); row 0x0F still ran JEDAH's state routine
  against Donovan's data (the session-4 "ignores inputs" family) —
  reclassified, extractor de-hardcoded (walks all dispatch_NN), rows
  repointed; neutral-idle field compare now agrees on all fields for
  1100 frames. Bug 2 OPEN (the current frontier): the +0x14E engine
  state dispatch (vsavj table 0x2A7E2, 89 entries) is EXTENDED in vs2
  (101 entries — 12 newcomer states); Donovan's VS2-flavor QCB+K writes
  state 0xB6 → indexes past the vanilla table → ILLEGAL → soft reset.
  Fix design + details: docs/tables/reconciliation.md "Session 8".
  HP-decrease sanity holds natively (Victor −11 ×2). NOTE: with
  dispatch_14 active the 12_donovan moveset replay also reaches the
  +0x14E states and crashes at 3815 — stage-4 gate lock 2 is KNOWN-RED
  until the hook lands (legacy gate green; one fix closes both).
- **2026-07-27: v2 approved (see Decisions made) and the Start-hold
  flavor mystery RESOLVED** — community protocol confirmed (Donovan +
  Huitzil only), mechanism pinned end-to-end with the new instruments
  (masked comparison found the behavioral fork at the exact QCB+LK
  frame; read-watch named both consumers, both inside ported regions).
  One consequence gates the upcoming vsav2-as-oracle behavior gate: the
  ported build's latch byte defaults to the WRONG flavor (VH2) — the
  oracle's native side defaults VS2, so QCB+K would diverge at the field
  compare until the default-flavor decision lands (Decisions pending).
  Note: 12_donovan_vs_cpu's battery includes QCB+K — the ported
  VH2-branch code path already runs crash-free under guard.

## Sessions 5-6 highlights (M2a stage 4 — the port runs)

- **Companion (Anita) chain decoded end-to-end**: pool geometries are
  identical per-index in both games; allocator family mapped (never
  ported — it reads the game's own RAM bookkeeping); creation handler's
  anim-table pointer was the last unrelocated piece; class-7 (vs2-only
  update queue) remapped to vsavj's equivalent class.
- **New extraction capabilities** (all in `tools/extract_char.py`):
  data-kind extra roots with forced twins; *segmented* gap-tolerant
  oracle diff (resyncs after cross-game insertions — Anita's 44.2K asset
  region: 2065 pointer fields over 75 segments); self-pointer
  classification for micro-shifted multi-blob regions; chunk-BFS graph
  sizing before committing space; PC-relative word-table discovery with
  full-extent protection.
- **New generator capabilities** (`tools/gen_donovan_patch.py`): layout
  groups (PC-referencing families keep source-relative spacing, gaps
  recycled), near_map satellite placement within d16, pcrel entry
  rewrites with shared per-region tripwires, slot-clearing allocator
  wrappers, port_patch byte edits, stage-1 scaffolding gated to stages
  1-3.
- **SPACE BUDGET CLOSED**: ~335K placed of 336.6K free (hole A ~1.4K
  spare, hole B ~12.9K). Achieved by honest region bounding, porting only
  Donovan's own sub-object handler types (others tripwired), and tighter
  margins.
- **Result**: char-init completes, match runs (timer, CPU opponent, HP
  structs). Crash frontier moved 2886 → 3025.
- **Frontier**: vec3 at engine 0x015096 — the anim word table is
  byte-identical to native vsav2 (data+relocation correct) but the INDEX
  into it is wrong; a state/substate byte carries a vs2-flavored value.
  Full detail + next probe: docs/tables/reconciliation.md "Session 6",
  docs/NEXT_SESSION.md.
- **GOTCHAS paid**: PC-relative reads are decrypted reads on CPS-2;
  PC-relative word tables are DATA (a fused pair of word entries was
  silently corrupting a dispatch table).

## Session 4 highlights (M2a — the real Donovan port)

- **M2a plan approved** (staged: C0 harness → C1 extraction → C2 generator →
  bring-up ladder stages 1-5 → close-out). Stage design: null-relocation of
  Jedah's own data first (tooling proof, zero R1 ambiguity), then Donovan
  data → anim → code dispatch (R1 surface) → select plumbing.
- **C0 COMPLETE (harness primitives, all verdict logic ground-truth tested):**
  - Crash guard: breakpoints on 68k exception handlers, fault PC/ADDR from
    the exception frame, stack sketch, RAM dump (`replay_guard.lua`,
    `run_replay_guarded.sh`, `test_crash_guard.sh` — vec3/vec4 positive
    controls trip correctly).
  - Dual-emulator field comparator per amended §4: debounced match-start
    anchors, stable/settled/phase field classes (`compare_fields.py`,
    `fields_m2a.tsv`, selfcheck green: MAME/FBNeo agree on 16_xemu_2p with
    1-frame skew).
  - Auto-detecting suite runner: program-image fingerprint →
    `tests/expected/<expset>/` dispatch; `.diverge` expectation kind
    (exact-frame divergence vs frozen full logs). Suite green, 12 replays
    (added 11_pick_donovan, 16_xemu_2p).
  - FBNeo verified to load CRC-changed patched zips (no descriptor change
    needed); `run_replay_fbneo.sh` gained `FBNEO_DUMPS`/`FBNEO_ROMPATH`.
- **Cross-emulator findings (GOTCHAS paid):** MAME `-debug` perturbs
  multi-CPU timing (checksum gates must run non-debug); vs-CPU replays have
  emulator-divergent content (different CPU-picked opponents); menu presses
  near transitions land on opposite sides of input-accept boundaries;
  match-start predicate flickers during intros (debounced).
- **C1/C2 COMPLETE:** oracle-validated extraction (`extract_char.py` —
  every cross-sibling diff byte must classify as a pointer field under a
  measured shift; auto-discovers new region shifts, e.g. the sprite/OBJ
  sub-tables at −0x2002C), staged patch generator, `find_equiv.py`
  (validated at score 1.00 on the known loader), `build_donovan.sh` driver.
  Donovan footprint closed at ~235KB, 9+ regions.
- **STAGES 1-3 PASS** (gates in tests/): null relocation (Jedah copy,
  10018 B — matches M1 exactly), Donovan passive data (full round under
  guard), anim + sprite sub-tables (idle-coherent; select-screen hover
  reads anim → pick divergence pin moves 2886→1080 at stage 3+).
- **STAGE 4 (in progress, deep):** R1 mechanized (`reconcile_batch.py`:
  pattern ladder, stub-deref, callsite anchoring via veteran parallelism,
  codebytes, farm-param matching; ~120 verified rows) + per-target
  TRIPWIRES for opens (fault PC names the target). Ported regions: +0x34
  newcomer-support zone, 17 extra secondary-object handlers, engine
  char-init pair, VS2-only 0x8xxxx companion zone (source-only). TWO
  engine hooks live (extended type-dispatch tables 59→76 and 114→124,
  jsr-thunk pattern; vanilla rows byte-identical). **Donovan RUNS on the
  vsavj engine** (match, timer, CPU opponent, HP structs, guard clean,
  screenshot in scratch). [Superseded by sessions 5-6 above: the companion
  chain is decoded and the port fits; see that section for the current
  frontier.]
- Suite GREEN, 13 replays (added 11_pick_donovan, 12_donovan_vs_cpu
  moveset-exercise, 16_xemu_2p; vanilla expectations + full logs frozen).
- **Next actions (stage 4 close):**
  1. Decode the pool-index correspondence + spawn-node field protocol
     (vsav2 node writer = the 0x8A5A8 hook; vsavj consumer =
     `PRG:0x0155D0-0x015650` jump-table on `(0x9,A6)`; watch $FF79BE+
     pool heads). Consider REWRITING the hook to vsavj's protocol
     (synthesized, GEN provenance) instead of porting VS2's.
  2. Then: stage-4 gates (vsav2-as-oracle field compare at anchors —
     native Donovan pick on vsav2 = cursor R×2 from default; dual-emulator
     on 16-pattern replay; legacy gate every build).
  3. Then stage 5 (select plumbing aux pokes) + soak + freeze.

## Session 3 highlights

- CLAUDE.md §4 dual-emulator amendment applied (maintainer-approved).
- **Donovan/Huitzil/Pyron located and pinned** (char IDs 0x13/0x10/0x11,
  hitbox bases + handler code addresses in both vsav2 and vhunt2).
- Per-character table bank semantically labeled (14 dispatch tables +
  hitbox pairs + parameter tables); bank layout identical across all three
  sets (same internal deltas from a per-set origin).
- RAM atlas: round timer $FF8109, HP +0x50/+0x52 (max 0x120), X/Y
  +0x10/+0x14 added.
- Remaining for M1 acceptance: per-character manifests' remaining columns
  (anim scripts, tile ranges, palettes, sound cues); meter/rounds-won RAM
  offsets; formal Aulbath slot-9 pick; vhunt2-side pick verification of
  D/H/P; Start-hold flavor mechanism (VS2-vs-VH2 behavioral deltas are NOT
  in hitbox data — identical across both games).

## Current milestone

**M2 — Proof of life. IN PROGRESS.** Replaced slot = Jedah (0x0F).
- Program-patch tooling (`tools/patch_prg.py`) DONE and MAME-verified: data
  raw, code re-encrypted, null bit-identical (`tests/test_patch_prg.sh`).
- **Mechanism PROVEN end-to-end on trusted tooling** (`tests/test_m2_repoint.sh`):
  repointing vsavj Jedah's hitbox-base bank entry to Demitri's takes effect
  in a live match (RAM:$FF8460 loads the new base), AND the superset
  invariant holds exactly — 6/6 non-Jedah legacy replays bit-identical;
  attract bit-identical through frame 4277, diverges at 4278 precisely where
  its CPU demo shows Jedah (char id 0x0F, verified). Attract legitimately
  involving the modified slot is correct superset behavior, not a violation.
- Feasibility assessed (docs/M2_feasibility.md): behavior data portable via
  ~337KB free vsavj space + data-reads-bypass-encryption; sprite tiles are
  the R2 wall (may pull M3 forward); QSound = M5.
- **M2a IN PROGRESS (sessions 4-7, see highlights above):** extraction,
  generation and relocation tooling complete; stages 1-3 PASS; stage 4
  bring-up DONE — the full moveset replay runs END-clean under guard
  (session 7; the session-6 "state-index delta" was extraction
  corruption, fixed). Legacy-gate basis decided (live-RAM masked windows,
  see Decisions made) and the masked legacy gate is green over all 9
  legacy replays. Remaining for stage-4 close: the behavior gates
  (vsav2-as-oracle field compare at anchors, native pick = cursor R×2;
  dual-emulator on the 16-pattern replay). Then stage 5 (select
  plumbing) and M2b graphics.

### M1 — Map. ACCEPTED (2026-07-25).
Both SPEC §4 clauses met; full assessment in docs/M1_acceptance.md.
Deferred sprite-bound exact addresses (tile/palette/sound) are
proven-reachable and scoped to M3/M4/M5.

### M1 detail (all complete)
- Replay harness: DONE both emulators. Shared `.rpl` input-script format;
  MAME runner (`tests/lua/replay.lua` — inputs, checksums, snapshots, RAM
  dumps) and patched-FBNeo runner (`emu/fbneo-patches/0001-…-harness.patch`,
  `tools/run_replay_fbneo.sh`). Both proven deterministic run-to-run.
- 10-replay legacy suite: DONE, green, expectations frozen
  (`tests/run_suite.sh`, `tests/expected/vsavj/`). Semantics spot-verified by
  snapshot (2P pick, challenger interrupt, mid-attract start all confirmed).
- **Cross-emulator finding (important):** MAME and FBNeo agree bit-exactly
  for the first 71 boot frames, then run the same states on *different frame
  indices* (transitions land ±frames apart; static screens re-sync; ~37
  work-RAM bytes differ at title — phase-shifted counters + sound-driver
  area $FF05xx). **Frame-exact whole-RAM dual-emulator comparison does not
  hold.** Superset-invariant enforcement is unaffected (oracle = same
  emulator, vanilla vs patched). Recommendation for CLAUDE.md §4 amendment
  (human sign-off requested, non-blocking): new-content dual-emulator
  verification = mapped gameplay fields (player structs, HP, positions,
  timer) compared at sync anchors (match start), not whole-RAM checksums.
- RAM map: community anchor imported and verified (player structs
  $FF8400/$FF8500, hitbox ptr offsets, match-active flags), extended by
  differential experiments + write-traces. See docs/atlas/ram.md.
- **Character-data plumbing CRACKED (the big one):** write-trace on
  $FF8480 → per-character loader (vsavj PRG:0x028DD8) → three 32-entry
  tables indexed by 5-bit char id → located in ALL THREE sets by
  instruction-pattern search → a whole bank of ~20 per-character tables
  (vsavj PRG:0x0BD0FA-0x0BE8xx). Slot→name map ~10/16 done empirically
  (pick + snapshot + pointer readback). Variant slots: vsavj {8}=Oboro
  Bishamon; vsav2/vhunt2 {0,1,3,8,9} with per-slot hitbox data
  byte-identical between vsav2 and vhunt2 (both games carry both flavors).
  **vsavj slot→character map COMPLETE** (16/16, one by elimination).
  **DONOVAN/HUITZIL/PYRON LOCATED** (pick-verified on vsav2): char IDs
  0x13/0x10/0x11 — the variant half of slots 3/0/1 — with hitbox bases in
  both vsav2 and vhunt2 recorded. Base-half slot assignments are identical
  across the whole series. Full detail: docs/atlas/character_tables.md.
- Three-way diff: window/masked diff built (`tools/diff_sets.py`);
  **finding:** vsavj↔vsav2 share <10% at window level even pointer-masked —
  engines were rebuilt (shifted code, changed PC-relative displacements) and
  most of the 4MB is game-specific data. The atlas grows from anchored
  RE (traces + tables) — which the character-table crack has now proven out.

### M0 — Bench. COMPLETE (2026-07-25). Acceptance status:
- Null-patch output bit-identical to reference: **PASS** (`tests/test_null_build.sh`)
- 60s attract replay deterministic across two runs: **PASS** (`tests/test_attract_determinism.sh`, MAME)
- Headless MAME runner: **DONE** (`tools/run_mame.sh`, MAME 0.288 via Homebrew)
- Headless FBNeo runner: **DONE** (`emu/fbneo` submodule, SDL2 build,
  `tools/run_fbneo.sh` with dummy SDL drivers + sandboxed HOME;
  `tests/test_fbneo_smoke.sh` PASS). The SDL2 frontend has no scripting, so
  the per-frame RAM-checksum probe on the FBNeo side is a frontend patch —
  first M1 task (see below)

Bonus beyond plan: CPS-2 decryption/encryption pipeline
(`tools/cps2_decrypt.py`) proven bit-identical to MAME's implementation via
opcode-space dump oracle (`tests/test_decrypt_oracle.sh`). Both directions
(decrypt for analysis, encrypt for future patch injection) self-check.

## Next actions

1. **FBNeo harness patch (M1 entry):** SDL2 frontend has replay
   (`replay.cpp`) and savestate support but no Lua. Options: (a) small
   frontend patch adding a per-frame work-RAM checksum dump + headless/exit
   flags (frontend, not emulation core — allowed); (b) drive via its .fr
   replay format only. Recommendation: (a); it mirrors the MAME Lua probe.
2. Start M1: three-way program diff (all three sets already decrypt
   bit-identically to the MAME oracle — images in `build/out/`), work-RAM
   map, character-data manifests.

## Open items

- None blocking. Reference collection is COMPLETE: vsav, vsavj, vsav2,
  vhunt2, vhunt2r1, qsound_hle — all MAME `-verifyroms` green, all 76
  members frozen in `docs/checksums.txt` (vsav2 supplied by maintainer
  mid-session 2026-07-25 and folded in; re-freeze recorded here).
- ROM packaging fixes from the 2026-07-25 audit are confirmed applied:
  `vhunt2.key` present in both vhunt2 zips (CRC 61306b20), `qsound_hle.zip`
  present (`dl-1425.bin` CRC d6cf5ef5).

## Decisions made

- **Legacy-gate basis for hooked builds = live-RAM (masked windows)** —
  2026-07-25, maintainer approved ("the invariant interpretation reads
  sound and reliable which is paramount"). For builds carrying engine
  hooks, legacy comparison masks exactly `RAM:$FF043C` (QSound handshake
  phase latch) and `RAM:$FF7F00-$FF7FFF` (dead stack below resting SP);
  every other byte compared every frame (confinement by construction).
  CLAUDE.md §4 amended; windows documented in docs/atlas/ram.md; masked
  vanilla expectations frozen under tests/expected/vsavj/masked/ (this
  session). Suite-runner masked-expectation-kind support lands with the
  stage-5 freeze. New masked windows require the same route: measured
  mechanism + atlas entry + maintainer sign-off.
- **Ported-Donovan default flavor = VS2** — 2026-07-27, maintainer
  ("Default should be VS2, as you proposed"). Implemented as a tunable
  in `build/manifest/donovan.toml` (`[init_shim] flavor_disp=0x3C2,
  flavor_default=0x01`, rule-5 style): the init shim writes the flavor
  latch into the initing player's struct (A6+0x3C2) — vsavj never writes
  it; the ported QCB+K handler + projectile consume it. Verified live:
  P1 $FF87C2=01 in-match on the flavor-defaulted build. Start-hold
  selector wiring (clear-to-00 on held Start) = stage-5 select-plumbing
  scope, §3.3/§3.4 variant policy (Donovan + Huitzil only).
- **Legacy-gate v2 refinement APPROVED** — 2026-07-27, maintainer
  ("I'd rather we iterate with as tight setups as we can build rather
  than try to be perfect and not go forward"). Per-replay classes on the
  masked basis: exact (02/05/07), flicker-tolerated 03/10/16
  (`tools/compare_flicker.py`, stretch ≤2 / re-converge ≥60 / total ≤8),
  frozen diverge constants 06@700, attract@4278, pick@1080. CLAUDE.md §4
  updated to v2. **Standing watch (maintainer caveat): if flickers grow
  beyond the frozen inventory (5 frames across 3 replays: 03@829+2093,
  10@3007+3129, 16@829) or divergences turn systematic, stop and
  root-cause — that would indicate a deeper issue.** The tolerance caps
  themselves fail loudly on growth; treat any new flicker frame as a
  finding to attribute, not noise to absorb.
- **M2 replaced slot = Jedah (slot 0x0F)** — 2026-07-25, maintainer
  approved. Donovan replaces Jedah in vsavj for the proof-of-life
  milestone. Rationale: footprint fit (Jedah 10018 B ≥ Donovan 9358 B),
  boss character (least playtest disruption), keeps Demitri/Victor so the
  M1 replay suite stays valid.
- **CLAUDE.md §4 dual-emulator amendment** — 2026-07-25, maintainer:
  new-content cross-emulator verification is field-level at sync anchors
  (mapped gameplay state), not whole-RAM frame-exact; within-emulator
  oracles stay whole-RAM frame-exact. Text updated in CLAUDE.md §4.
- **Project name = "Vampire Saved"** — 2026-07-25, maintainer.
- **Base revision = `vsavj` (Japan 970519)** — 2026-07-24, maintainer. Closed.
- **Checksum manifest is per-member**, so zip repackaging never matters —
  2026-07-25, session decision (mechanical, no gameplay impact).
- **Raw-image byte-order convention** — 2026-07-25, session decision: ROM
  files are LE-word storage; all derived images are 68k logical (BE) order.
  See docs/GOTCHAS.md first entry.

## Decisions pending (human)

- See SPEC §7 for the rest. Nothing blocks current work.

## Open bugs

None.

## Findings log

- 2026-07-25: key masters — vsavj `0xfa8f4e33a4b881b9` (watchdog
  `cmpi.l #$726A4BAF, D0`), vsav2 `0xd681e4f460371edf`, vhunt2
  `0x36c1eba326b10f18` (vsav2/vhunt2 share watchdog
  `cmpi.l #$06920760, D0` — sibling builds). All three: encrypted range
  `PRG:0x000000-0x0FFFFF` only (first 1MB of 4MB). Decryption of all three
  proven bit-identical to MAME (`tests/test_decrypt_oracle.sh <set>`).
- 2026-07-25: ROM file byte order ≠ 68k logical order; cost ~1h; conventions
  locked and oracle-tested (docs/GOTCHAS.md).
- 2026-07-25: MAME 0.288 vsavj boots and runs attract deterministically
  headless (`-video none -sound none`, fresh sandbox per run).

## Integration notes — SMS docs (imported 2026-07-24)

Conventions live in CLAUDE.md §4/§5 now; taxonomy files exist as of this
session. Still to mine when relevant (park, don't re-derive):
- SMS `coltest.lua` pattern (scripted char-select navigation → saved match
  state) for generating the 18×18 matrix states in M4.
- `trace.lua`/`trace_plan.lua` config shape for the CPS-2 input logger.
