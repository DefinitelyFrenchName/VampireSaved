THE PACKET

Decision kind: expectation
Subject: M25: the static re-freezes and fixes the S6 freeze tier found (five relocation re-freezes, patch 0041 named and regenerated, the #345 recurrence acknowledgement)
Claim (the working agent's sentence): Re-freeze, for the M25 freeze on merged-m25 build/m3b_merged33 and donovan-m29 build/don_m29 (registry rows, measured keys and programs: build_identity.txt), what the static freeze tier on snapshot S6 4617659f found unmoved (s6_static_results.tsv: FAIL 10), and fix two of its other reds; the remaining three are not this packet's (test_controls_concurrent: the emulator list's 11 re-traced rows, written since; test_emulator_staleness: runner rows to be re-run at the next snapshot; test_rule_checker: the four new registry rows have no OK freeze run yet, which follows). (1) Five static expectations re-frozen, each with its own regeneration (FREEZE=1 for latch_readers, df_field_readers and reaction_classes; tools/triage_pcrel_escapes.py | LC_ALL=C sort for escape_triage, the gate's own command; tools/tables_char_md.py build/don_m29/extract for donovan.md, the command the gate printed): every changed line attributed by attr_s6reds.py.txt (attribution.txt) — of 73 removed lines, 69 map to an added line when every hex address at or above 0x400000 is moved by +0x1610 (latch_readers 13, df_field_readers 30, reaction_classes 2, escape_triage 24), none by +0x300, and the residuals are only these: latch_readers', df_field_readers' and reaction_classes' header lines naming the build m3b_merged32 -> m3b_merged33; reaction_classes' build row merged-m24 43505a12 -> merged-m25 add7bc1a (merged-m25's registry key, build_identity.txt); and donovan.md's four ADDED lines, two rows each for x06e1d2 (code, 0x2fe) and x1d7428 (data, 0x1308), the two regions M25 adds (attribution_don.txt: "INSERTED op ... 0x400010 len 0x2fe" and "0x4013e0 len 0x1308"); +0x1610 is the shift of every region placed after those two head regions, 0x300 + 0x1310 (placements_head.txt, attribution_merged.txt); the matcher's control: one address of latch_readers' new rows moved +0x10 in memory leaves its line RESIDUAL (attribution_plant.txt: mapped 12 not 13, residual 4 not 2); before and after: each gate FAILed on the tree before (before_*.log) and PASSes after with its controls firing (after_*.log). (2) tools/setup_jtcores.sh's PATCH_NAMES gains emu/jtcores-patches/0041-cps2w-vsavjw-crcs-m25-356-345-14z220.patch, the fork commit 930818f5 the freeze pinned (diffs/setup_jtcores.sh.diff: that one name appended), and the 0041 file is regenerated with the command tools/setup_jtcores.sh line 101 and the gate use, git format-patch --stdout --no-signature -1 930818f5, which drops only the signature trailer the copy written at the freeze's MiSTer tail carried (diffs/0041-...patch.diff: three lines removed, "-- ", "2.54.0 (Apple Git-157)" and a blank); test_jtcores_twin FAILed on 3z and 3y before (the commit not mirrored by a PATCH_NAMES entry) and PASSes after (before_ and after_test_jtcores_twin.log). (3) tests/rulecheck/recurrence.tsv gains one acknowledgement: Q1 3094 3098 under #345, through run 2026-11-04-1599 (diffs/recurrence.tsv.diff), the signature test_recurrence_alarm named (before_test_recurrence_alarm.log: 3 subjects, 3 sessions, runs 2026-11-01-1552 .. 2026-11-04-1599); the three findings (recurring_q1.txt) are each about donovan_2's Blizzard Sword frames 3094 and 3098 in a packet of #345's timing; test_recurrence_alarm PASSes after with both its controls firing (after_test_recurrence_alarm.log). What this rests on that is NOT tested: (a) that the attribution's residuals are as harmless as described is a reading of each residual line, not a check — in particular donovan.md's four added lines are not compared with the extract field by field, they are regenerated from it by the gate's own tool and the gate's equality is the check; (b) the five gates' own correctness is not re-examined here — each is the gate it was, re-frozen on the new build; (c) attr_s6reds.py.txt matches a whole line after shifting every address token at or above 0x400000 by one delta; a line in which two addresses moved by DIFFERENT deltas would read RESIDUAL and none did, but a line whose addresses all happen to land on another added line under +0x1610 would be mis-paired, and the matcher uses each added line at most once; (d) that #345 owns the recurring finding's cause is a reading of the three Q1 texts in recurring_q1.txt, not a measurement.
Artifacts (read every one, in full):
  - build/agent220/m25/rc/r_s6fix/after_test_df_field_readers.log
  - build/agent220/m25/rc/r_s6fix/after_test_escape_triage.log
  - build/agent220/m25/rc/r_s6fix/after_test_jtcores_twin.log
  - build/agent220/m25/rc/r_s6fix/after_test_latch_readers.log
  - build/agent220/m25/rc/r_s6fix/after_test_reaction_classes.log
  - build/agent220/m25/rc/r_s6fix/after_test_recurrence_alarm.log
  - build/agent220/m25/rc/r_s6fix/after_test_tables_current.log
  - build/agent220/m25/rc/r_s6fix/attr_s6reds.py.txt
  - build/agent220/m25/rc/r_s6fix/attribution.txt
  - build/agent220/m25/rc/r_s6fix/attribution_don.txt
  - build/agent220/m25/rc/r_s6fix/attribution_merged.txt
  - build/agent220/m25/rc/r_s6fix/attribution_plant.txt
  - build/agent220/m25/rc/r_s6fix/before_test_df_field_readers.log
  - build/agent220/m25/rc/r_s6fix/before_test_escape_triage.log
  - build/agent220/m25/rc/r_s6fix/before_test_jtcores_twin.log
  - build/agent220/m25/rc/r_s6fix/before_test_latch_readers.log
  - build/agent220/m25/rc/r_s6fix/before_test_reaction_classes.log
  - build/agent220/m25/rc/r_s6fix/before_test_recurrence_alarm.log
  - build/agent220/m25/rc/r_s6fix/before_test_tables_current.log
  - build/agent220/m25/rc/r_s6fix/build_identity.txt
  - build/agent220/m25/rc/r_s6fix/diffs/0041-cps2w-vsavjw-crcs-m25-356-345-14z220.patch.diff
  - build/agent220/m25/rc/r_s6fix/diffs/df_field_readers.tsv.diff
  - build/agent220/m25/rc/r_s6fix/diffs/donovan.md.diff
  - build/agent220/m25/rc/r_s6fix/diffs/escape_triage.txt.diff
  - build/agent220/m25/rc/r_s6fix/diffs/latch_readers.tsv.diff
  - build/agent220/m25/rc/r_s6fix/diffs/reaction_classes.tsv.diff
  - build/agent220/m25/rc/r_s6fix/diffs/recurrence.tsv.diff
  - build/agent220/m25/rc/r_s6fix/diffs/setup_jtcores.sh.diff
  - build/agent220/m25/rc/r_s6fix/placements_head.txt
  - build/agent220/m25/rc/r_s6fix/recurring_q1.txt
  - build/agent220/m25/rc/r_s6fix/s6_static_results.tsv
