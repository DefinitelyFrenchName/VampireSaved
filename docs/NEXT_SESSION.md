# NEXT_SESSION — 60-second orientation (rewritten every session end)

As of 2026-07-25, end of session 4. **M2a stages 1-3 PASS. Stage 4:
DONOVAN RUNS ON THE VSAVJ ENGINE** — real match, timer, CPU opponent, his
relocated data live, crash-guard clean through a full moveset-exercise
round (garbage tiles as expected; graphics are M2b). One chain left before
the stage-4 gates: the companion (Anita) spawn.

**Pick up EXACTLY here:** the VS2-only init hook (ported source-only from
vsav2 0x8A5A8-zone) allocates from the secondary-object pools and writes a
spawn record in VS2's node protocol; vsavj's consumer (jump table on
`(0x9,A6)` at `PRG:0x0155D0-0x015650`) crashes vec3 on an odd list-head
(0x17685). Two suspects, in order: (1) the pool-index correspondence is
not identity — vsav2 pools 2/4 (helpers 0x15702/0x1572E) were mapped to
vsavj pools 2/4 (0x016FBA/0x016FE6) by family position; verify which vsavj
pool actually feeds which object category (watch $FF79BE..$FF79CB counts +
$FF7966+ list heads on vanilla vsavj content that spawns satellites);
(2) the node field layout differs — likely REWRITE the hook against
vsavj's protocol (synthesized GEN code) instead of porting VS2's bytes.
Every instrument is ready: `GUARD_TRACE`/`GUARD_BREAK`/`GUARD_PC_LOG` on
the guard, trace_writes, native ground truth = vsav2 pick cursor **R×2**
(12-replay input block, `scratchpad/don12_vs2.rpl` pattern in STATE
history).

**Build/run one-liners:**
- `GEN_FLAGS="--allow-plausible --tripwire-open" tools/build_donovan.sh 4 build/donovan`
- `MAME_ROMPATH="$PWD/build/donovan/rompath;$ROMDIR" tools/run_replay_guarded.sh vsavj tests/replays/12_donovan_vs_cpu.rpl out.log box`
- Legacy gate helpers: `tests/lib/m2a_common.sh`; stage gates
  `tests/test_m2a_stage{1,2,3}*.sh` (all PASS).

**After the companion chain:** author `test_m2a_stage4_code.sh` (pick +
moveset replay under -debug guard, zero tripwires; HP-decrease field
sanity; vsav2-as-oracle compare_fields at anchors; dual-emulator; legacy
gate), then stage 5 (select-screen aux pokes — portrait/name still say
"Jedah", fine for now), soak, freeze (registry row = build decision).

**Key context:** R1 map ~120 verified rows + methods in
docs/tables/reconciliation.md; the two extended-type-table engine hooks
and the PC-relative-reads-are-decrypted rule in docs/patch_notes.md +
docs/GOTCHAS.md. Suite GREEN (13 replays, fingerprint-dispatched).

**Read:** STATE.md, docs/tables/reconciliation.md (OPEN FRONTIER section),
docs/patch_notes.md, docs/GOTCHAS.md (3 new entries).
