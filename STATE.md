# STATE — living progress log

Updated: 2026-07-25 (session 5 end — M2a stage 4: full port FITS and runs;
last frontier = companion-code zone under-extraction, see NEXT_SESSION)

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
  screenshot in scratch) — remaining: he idles/is unhittable because the
  companion (Anita) spawn chain fails: the ported VS2 init hook speaks
  VS2's pool/node protocol; vsavj's consumer (0x0155D0 family) differs.
  Frontier detail: docs/tables/reconciliation.md "OPEN FRONTIER".
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
- **Next:** author the real Donovan port — extract his program-ROM data from
  vsav2, relocate into vsavj free space, repoint all slot-0x0F bank entries,
  re-encrypt his code, resolve R1 engine-delta. Then M2b graphics.

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

- See SPEC §7 for the rest. None blocks current work.
- **SPEC §2 fact check (community liaison):** "hold Start while selecting
  D/H/P → other game's flavor" did not reproduce in vsav2 under scripted
  test (evidence in docs/atlas/character_tables.md). Since vsav2≡vhunt2
  character data is byte-identical, the variant policy question (§3.3/§3.4)
  may be moot at the data level — worth confirming with the community what
  the Start-hold is believed to do and on which set/revision.

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
