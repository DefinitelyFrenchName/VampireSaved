# NEXT_SESSION — 60-second orientation (rewritten every session end)

As of 2026-07-27, end of session 8. **The vsav2-as-oracle behavior gate
exists and works — it caught two real bugs on first contact. One is
fixed and verified; the second is the current frontier.**

**Where we are:** legacy-gate v2 signed off (CLAUDE.md §4; standing
watch on flicker growth). Start-hold flavor resolved and defaulted to
VS2 (init-shim tunable in donovan.toml). Oracle replay pair
`tests/replays/17_don_oracle_{vsav2,vsavj}.rpl`: both games anchor at
frame 2363; neutral-idle field comparison (compare_fields --exact,
ROM-pointer fields skipped) agrees on ALL fields for 1100 frames after
the dispatch_14 fix (bank_map: gap_bd7fa was a per-char CODE dispatch;
Jedah's state routine had been running on Donovan's data since stage 4
began — extractor now walks all dispatch_NN tables).

**Pick up EXACTLY here — the +0x14E frontier (reconciliation.md
"Session 8", full detail):** Donovan's VS2-flavor QCB+K writes state
0xB6 to player +0x14E. The engine's brief-word dispatch (vsavj site
0x02A7CA, table 0x02A7E2, 89 entries) indexes past its table → ILLEGAL
at PC 0x02AB6C → soft reset. vsav2's twin (site 0x029B50, table
0x029B6C) has 101 entries; the 12 newcomer case handlers live at ≈vs2
0x2AB80-0x2AD7E+ (Donovan QCB+K = idx 91 → 0x2AC2E). PLAN: brief-word
variant of the obj_hook (site's first 6 bytes → jmp thunk; D0 ≤ 0xB0 →
jmp back to vanilla move.w+jsr = ghost-clean; else extended long table →
ported case block via new extra root ~0x2ab80:0x300:s). Then re-run the
17-pair battery — expect the ladder to surface more extended brief-word
tables (naive survey found candidates but needs reconcile_batch-style
twinning; 797 vs 779 sites).

**KNOWN-RED lock (deliberate, do not be surprised):** with dispatch_14
active, Donovan's real state machine drives the engine +0x14E states —
so the 12_donovan moveset replay now ALSO crashes (frame 3815, same
family) and `tests/test_m2a_stage4_code.sh` lock 2 is RED until the
+0x14E hook lands. The LEGACY gate (the law) is fully green. One fix
closes both the moveset lock and the oracle battery.

**Verification loop:** `tools/compare_fields.py --exact` over the
anchor-window dumps (see session-8 command history in reconciliation) +
`tests/test_m2a_stage4_code.sh` (full gate) every build. The oracle gate
is not yet a scripted test — capture it as
`tests/test_m2a_stage4_oracle.sh` once the battery phase passes
(replays + anchor 2363 + field-agreement + HP-decrease are the locks).

**Read:** STATE.md (session-8 highlights), docs/tables/reconciliation.md
("Session 8"), docs/GOTCHAS.md, docs/atlas/character_tables.md
(Start-hold mechanism), docs/patch_notes.md (top).
