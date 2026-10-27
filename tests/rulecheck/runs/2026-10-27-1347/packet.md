THE PACKET

Decision kind: recommendation
Subject: close #318 as done (14z-210): anim_nodes.py reads index offsets signed
Claim (the working agent's sentence): CLAIM: close #318 as done with the comment build/agent210/closures/final/c318.md (fixed in commit 86d1ca10). Its done-when (build/agent210/closures/issues/318.md): "the walker reads offsets signed; every committed expectation built from `anim_nodes.py` is re-derived and any that moves is explained; a gate holds the signed read with a must-fire control (a negative entry read unsigned lands at the wrong node)."
1. Signed read: tools/anim_nodes.py lines 60-82, `walk_table(..., signed=True)` sign-extends the word; signed=False reproduces the old read, 480 tables x2 compared, 0 differences (build/agent210/rc318/equiv.out, by build/agent210/t318/equiv.py). The engine's own read, vs2 PRG:0x027134 / PRG:0x027138, is recorded in run 2026-10-26-1331's ledger row (tests/rulecheck/ledger.tsv line 1198). The census of 71 negative entries on 11 legacy fighters is build/agent210/t318/census_vsavj.txt lines 445-470.
2. Re-derived and explained, static side: run 2026-10-26-1331 re-froze Pyron's charmap page, same_data_p2.tsv, reaction_classes.tsv and facing_rule.tsv (ledger line 1198, resolved in writing; the changes in build/agent210/rc318/expectations.diff). Each move is traced to a negative entry: build/agent210/t318/explain_sdp2.txt (43 lines, NEG on each) and explain_rc_vsavj.txt / explain_rc_vsav2.txt (ALL-NEG on each ONLY-OLD row, no ONLY-NEW row). The static tier on the committed tree is GREEN (build/agent210/tier4/tier.log, commit 1ad99ddf, the tree of e4aa32ee), with `test_anim_signed_offsets` PASS (tier4/tier_results.tsv line 131).
3. Re-derived, emulator side: the ledger row names vanilla_hit_damage and vanilla_meter_gain as left to "the next emulator tier". build/agent210/t318od/rc.txt and the eleven .out files (run by t318od/one.sh through tests/run_all_emulator.sh at HEAD e4aa32ee, the ten of t318od/gates.txt plus audit_ground_throws) have rc=0 and PASS for all eleven. test_vanilla_frame_join's log confirms the vanilla_hit_damage hash (90 rows) and test_meter_gain's the vanilla_meter_gain hash (49 rows). build/agent210/closures/final/e318_readers.txt (by e318_readers.py: the import closure of anim_nodes over tools/*.py, matched against each registered gate's script) finds 25 emulator gates that read it, 14 on-demand and 11 release-scope, with 0 lacking a PASS after #318. The 11 release-scope readers PASS on ERIS at 86d1ca10 (build/agent210/t321e2/release2_results.tsv, freeze_results.tsv). Of the 14 on-demand ones, eleven PASS at HEAD in t318od, test_tick_durations and test_rehit_ring in build/agent210/book/emu/results.tsv, and audit_guard_cancels in build/agent210/t331f/plain.log.
4. The gate: tests/test_anim_signed_offsets.sh lines 21-22, MUST-FIRE `unsigned-read` (an unsigned walk lands every negative entry at table + word + 0x10000) and `negative-ends-table`; both FIRED, and the gate PASS, in build/agent210/rc318/verify_test_anim_signed_offsets.log.
NOT TESTED: the reader census matches script text; a gate that reaches the walker by another route would be missed. book/emu ran on the working tree on 2026-10-26, not at a commit, and t331f's run on the working tree before e4aa32ee was made. The t318od runs record a dirty tree (commit.txt lists the uncommitted DECISIONS_HISTORY.md, docs/project/operations.md and tests/audit_guard_cancels.sh; whether any of these gates reads them is not checked). Whether the game ever selects Pyron a:0x41 or Victor proj:0x14 is not measured, as the comment says.
Artifacts (read every one, in full):
  - build/agent210/closures/final/c318.md
  - build/agent210/closures/issues/318.md
  - tools/anim_nodes.py.lines-60-82 (lines 60-82 of tools/anim_nodes.py)
  - build/agent210/rc318/equiv.out
  - build/agent210/t318/equiv.py
  - tests/rulecheck/ledger.tsv.lines-1198-1198 (lines 1198-1198 of tests/rulecheck/ledger.tsv)
  - build/agent210/t318/census_vsavj.txt.lines-445-470 (lines 445-470 of build/agent210/t318/census_vsavj.txt)
  - build/agent210/rc318/expectations.diff
  - build/agent210/t318/explain_sdp2.txt
  - build/agent210/t318/explain_rc_vsavj.txt
  - build/agent210/t318/explain_rc_vsav2.txt
  - build/agent210/tier4/tier.log.lines-1-6 (lines 1-6 of build/agent210/tier4/tier.log)
  - build/agent210/tier4/tier.log.lines-455-460 (lines 455-460 of build/agent210/tier4/tier.log)
  - build/agent210/tier4/tier_results.tsv.lines-131-131 (lines 131-131 of build/agent210/tier4/tier_results.tsv)
  - build/agent210/t318od/rc.txt
  - build/agent210/t318od/gates.txt
  - build/agent210/t318od/one.sh
  - build/agent210/t318od/audit_ground_throws/commit.txt
  - build/agent210/t318od/test_vanilla_frame_join/test_vanilla_frame_join.log
  - build/agent210/t318od/test_meter_gain/test_meter_gain.log
  - build/agent210/closures/final/e318_readers.py
  - build/agent210/closures/final/e318_readers.txt
  - tests/test_anim_signed_offsets.sh.lines-19-23 (lines 19-23 of tests/test_anim_signed_offsets.sh)
  - build/agent210/rc318/verify_test_anim_signed_offsets.log
  - build/agent210/t318od/audit_vanilla_pursuits.out
  - build/agent210/t318od/audit_vanilla_specials_a.out
  - build/agent210/t318od/audit_vanilla_specials_b.out
  - build/agent210/t318od/audit_es_ex.out
  - build/agent210/t318od/audit_command_throws.out
  - build/agent210/t318od/audit_demitri_split.out
  - build/agent210/t318od/test_vanilla_aerial_join.out
  - build/agent210/t318od/test_vanilla_command_join.out
  - build/agent210/t318od/test_vanilla_frame_join.out
  - build/agent210/t318od/test_meter_gain.out
  - build/agent210/t318od/audit_ground_throws.out
