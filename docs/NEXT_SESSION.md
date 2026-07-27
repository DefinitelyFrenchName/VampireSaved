# NEXT_SESSION — 60-second orientation (rewritten every session end)

As of 2026-07-27, end of session 9. **The vsav2-as-oracle behavior gate
PASSES as a scripted test (`tests/test_m2a_stage4_oracle.sh`). Every
frontier from sessions 8-9 is closed.**

**What landed in session 9:** the +0x14E engine state-dispatch hook
(donovan.toml `[state_hook]` — synthesized case stubs, ghost-clean
thunks, relocated palette-seq records, 4 consumer base-swaps); 8
sound-farm calls stubbed to rts (SILENT until M5 — vs2 sfx ids recorded
in reconciliation.toml, kind=stubbed_sound); anim_index_a2 resolved
(bank_map gap_bcefa → data_ptr; was feeding Jedah's anim rows to
Donovan's attacks). Moveset replay END-clean (9320 frames, real state
machine + VS2-flavor QCB+K).

**The key measurement to remember:** frame-exact cross-GAME combat
comparison is impossible — the vsavj and vsav2 ENGINES differ by ~1
frame of action latency. Proven with the veteran control
(18_veteran_ctl_*: vanilla Demitri on both games diverges MORE — 2379
mismatches — than ported Donovan does — 890). The oracle gate therefore
locks: anchors equal (2363), neutral-window exact agreement, P2
HP-trajectory equality (hits land, same damage), and the comparative
bound (ported ≤ native-veteran divergence).

**NEXT WORK (stage-4 close, then stage 5):**
1. **The 0x17522 rung (code-gate lock 2 KNOWN-RED — moveset replay
   crashes 5463 via tripwire 0xC2970):** activating anim_index_a2
   deepened the moveset path to the vs2-only helper trio
   0x17422/0x17522/0x17B22 (called from the x028122 char-init region;
   no vsavj skeleton match within ±0x3000 — vs2-only). 0x17522: 5-bit
   char-id lookup in a 32B-stride table at vs2 0xD22BE + three
   sub-helpers (0x176E2/0x1756A/0x1759E) + a (d8,PC) dispatch on
   $B2(a6) — likely damage/rank calc. Decide port-vs-map per the
   allocator rule (it reads A5 globals: -0x4B74(A5) — check whether
   that global family is remapped). Two siblings already resolved by
   skeleton-match at the pool-family delta (+0x18B8):
   0x15744→0x16FFC, 0x1581A→0x170D2 (rows added).
2. **Dual-emulator gate:** a Donovan replay in the 16_xemu_2p authoring
   pattern on MAME + patched FBNeo (field compare at anchors,
   compare_fields WITHOUT --exact, per amended §4).
3. Stage 5: select-screen plumbing (aux pokes; Start-hold selector for
   the flavor latch is in-scope per the variant policy — Donovan +
   Huitzil only), soak, freeze (registry row + suite masked-expectation
   kind land at the freeze).
4. Parked: 0x36784A alternate anim table tripwire; Huitzil/Pyron
   tripwired handler types; the 0x2c31xx data opens (Anita boxes past
   region end — likely DF-only); M5 sound restoration list.

**Read:** STATE.md (sessions 8-9 highlights), docs/tables/
reconciliation.md ("Session 9", "Session 8"), docs/patch_notes.md (top
two entries), docs/GOTCHAS.md.
