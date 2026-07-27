# NEXT_SESSION — 60-second orientation (rewritten every session end)

As of 2026-07-27, end of session 10. **BOTH stage-4 gates PASS on one
build (fingerprint 67753ee3) — the first all-green run with the full
port active: real state machine, VS2-flavor QCB+K, damage pipeline,
sound stubbed. Moveset replay END-clean, 9320 frames.**

**Sessions 8-10 in one breath:** the vsav2-as-oracle gate
(`tests/test_m2a_stage4_oracle.sh`) was built and immediately caught a
chain of real bugs, each fixed and locked: dispatch_14 (Jedah's state
routine on Donovan's data), the +0x14E extended state dispatch
(state_hook: synthesized stubs + ghost-clean thunks + relocated
palette-seq records + 4 consumer base-swaps), anim_index_a2 (Jedah's
anim rows on Donovan's attacks), 8 sound-farm calls stubbed silent
(M5 restores — sfx ids in reconciliation.toml), and the damage trio
MAPPED to vsavj's own machinery by callsite anchoring in the
byte-parallel damage wrapper (reconciliation.md Session 10 table).
Cross-game frame-exact combat comparison is impossible (the ENGINES
differ by ~1 frame of action latency — veteran control proved it);
the oracle locks are anchors/neutral-exact/HP-trajectory/comparative
bound.

**NEXT WORK (stage-4 close → stage 5):**
1. **Dual-emulator gate (the last stage-4 item):** run
   17_don_oracle_vsavj (it follows the 16_xemu authoring rules — both
   picks scripted) on MAME AND patched FBNeo (FBNEO_ROMPATH loads
   CRC-changed zips; FBNEO_DUMPS for field windows), compare mapped
   fields at anchors via compare_fields WITHOUT --exact (per §4:
   MAME/FBNeo run same states frames apart). The selfcheck
   (16_xemu_2p) is the template. Capture as
   tests/test_m2a_stage4_xemu.sh.
2. Stage 5: select plumbing (aux pokes; Start-hold flavor selector —
   Donovan+Huitzil scope per variant policy), soak, freeze (registry
   row + suite masked-expectation kind + register build sha in
   HANDOFF registry).
3. Parked: 0x36784A alternate anim table (tripwire or port at stage-5
   close); Huitzil/Pyron tripwired handlers; 0x2c31xx data opens
   (likely Anita DF-only); M5 sound-restoration list (8 rows tagged
   stubbed_sound).

**Gates every build:** `tests/test_m2a_stage4_code.sh` +
`tests/test_m2a_stage4_oracle.sh` (both PASS on 67753ee3).

**Read:** STATE.md (sessions 8-10), docs/tables/reconciliation.md
(Sessions 8-10), docs/patch_notes.md (top three), docs/GOTCHAS.md.
