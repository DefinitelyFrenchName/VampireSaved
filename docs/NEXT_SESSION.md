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

**STAGE 4 IS CLOSED.** The dual-emulator gate also passed
(`tests/test_m2a_stage4_xemu.sh`: patched build on MAME + patched
FBNeo, anchors 2363/2364, all mapped fields agree at follow 0/60/180).
All three stage-4 gates green on fingerprint 67753ee3.

**NEXT WORK — STAGE 5 (select plumbing), then soak + freeze:**
1. Select-screen aux pokes so slot 0x0F presents as Donovan (name/
   portrait handling is M2b-graphics-adjacent — check M2_feasibility
   for what's text vs GFX; minimum: correct pick behavior, which
   already works via the anim repoint).
2. Start-hold flavor selector (variant policy scope = Donovan +
   Huitzil): wire Start-held-at-confirm to clear the +0x3C2 latch
   (vsavj select code doesn't write it; the init shim seeds 01 — a
   select-time hook or shim extension can clear on Start; SPEC §3.3/3.4
   presentation questions go to the maintainer).
3. Stage-5 close-out: 0x36784A alternate anim table (tripwire or
   port), then SOAK (long-run replays incl. timeout/DF/pursuit per
   the §4 minimum matrix — grow the replay set), then FREEZE:
   registry row for the frozen fingerprint, suite masked-expectation
   kind, build sha in the HANDOFF registry.
4. Parked: Huitzil/Pyron tripwired handlers (their ports = M3+);
   0x2c31xx data opens (likely Anita DF-only); M5 sound-restoration
   list (8 stubbed_sound rows).

**Gates every build:** test_m2a_stage4_code.sh +
test_m2a_stage4_oracle.sh + test_m2a_stage4_xemu.sh (all PASS on
67753ee3).

**Read:** STATE.md (sessions 8-10), docs/tables/reconciliation.md
(Sessions 8-10), docs/patch_notes.md (top three), docs/GOTCHAS.md.
