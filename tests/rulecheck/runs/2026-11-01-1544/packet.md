THE PACKET

Decision kind: expectation
Subject: #294: freeze audit_don_row0c (row 0x0C = native outside Dark Force, the window measured and open; the blind set)
Claim (the working agent's sentence): Freeze tests/audit_don_row0c.sh's expectation (audit_don_row0c.sh.txt; tap pal_rows_tap.lua.txt, whose V line carries P1's +0x1C3 as f1c3): P1's palette row 0x0C equals native vs2 on every frame from 2500 of the electrocute rig (R1) and, on the 15 Donovan naming parts (R3), on every frame OUTSIDE native's P1 +0x1C3 frames (native's Dark Force window). INSIDE that window the difference is MEASURED, not asserted, and its cause is stated NOT ESTABLISHED: run1_before_df_rule.log shows R3's 1511 differing frames only in donovan_3/4/6/7 (~378 each, the parts that also differ on row 0x0A); df6_runs.txt shows native setting P1 +0x1C3 over 2900-3287 on donovan_6 and ours never; run2_df_rule.log shows 0 differing frames outside native's +0x1C3 frames and 1511 inside (378+378+378+377 within 388/388/388/387); df_colour_vs_brightness.txt shows the inside-window difference on rows 0x0A and 0x0C is colour (low 12 bits) on every differing frame and never the brightness nibble; and the gate's R5 (run4_r5_premise_failed.log, where it was still an assertion and failed; run5_final.log, where it MEASURES) shows that poking P1 +0x1C3 to 1 over native's window on donovan_6 leaves the difference whole (378 poked, 378 unpoked), so it is not the ported routine's +0x1C3 (Dark Force POWER) branch — an earlier attribution to the ruled Dark Force CHANGE is retracted. Its `row-reverted` control (audit_don_row0c.sh.txt) requires the known-bad leg (row 0x13 back to vsavj's 0x0040 in the opcode share; `opatch-readback` control) to differ on R1 and, outside the window, in every census part except a frozen blind set of ten (donovan_1, 2, 6, 8, 9, 10, 11, 13, 14, 15). run5_final.log: PASS, both controls FIRED (BAD: R1 55 frames, 5 of 15 parts); mode_row_reverted_final.log: the row-reverted MODE FAILS R1 (55) and R3 (852 outside the window). The port behind it is ruled (ruling_294.txt: the maintainer's "indeed if the 6 free bytes exist, given the cost this seems like the best solution." and "Yes"), the condition met by the dead-byte search (test_dead_span.log: vsavj PRG:0x024024-0x024029 DEAD, four controls fired; dead_span_ours.txt: DEAD on our merged image), and built after rule-checker run 2026-11-01-1541 (run_1541_verdict.txt: VERDICT OK). NOT TESTED: the opatch-readback MODE (its in-gate control fired); the cause of the inside-window colour difference (open: sheet294_df.png puts the Dark Force look before the maintainer, native drawing Donovan in other colours than both of our builds; whether it is the two games' different Dark Force modes, ruled CHANGE for the newcomers in ruling_df_change.txt, or a port defect is not decided here); whether the +0x1C3 window is the Dark Force window on donovan_3/4/7 (inferred from the same rule and the matching counts, not traced); how the sword LOOKS outside Dark Force (sheets build/agent216/rc294/sheets/sheet294_p1..p3.png go to the maintainer; no conclusion about the look is drawn here); Donovan as P2; FBNeo and MiSTer; at the default BUILD (m3b_merged31) the gate FAILS its precondition by design until the freeze re-points it.
Artifacts (read every one, in full):
  - build/agent216/rc294/g0c/audit_don_row0c.sh.txt
  - build/agent216/rc294/g0c/pal_rows_tap.lua.txt
  - build/agent216/rc294/g0c/run1_before_df_rule.log
  - build/agent216/rc294/g0c/df6_runs.txt
  - build/agent216/rc294/g0c/run2_df_rule.log
  - build/agent216/rc294/g0c/df_colour_vs_brightness.txt
  - build/agent216/rc294/g0c/run4_r5_premise_failed.log
  - build/agent216/rc294/g0c/run5_final.log
  - build/agent216/rc294/g0c/mode_row_reverted_final.log
  - build/agent216/rc294/g0c/ruling_294.txt
  - build/agent216/rc294/g0c/ruling_df_change.txt
  - build/agent216/rc294/g0c/test_dead_span.log
  - build/agent216/rc294/g0c/dead_span_ours.txt
  - build/agent216/rc294/g0c/run_1541_verdict.txt
  - build/agent216/rc294/g0c/sheet294_df.png
