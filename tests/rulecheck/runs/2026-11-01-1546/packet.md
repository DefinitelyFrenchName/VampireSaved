THE PACKET

Decision kind: expectation
Subject: #294: freeze audit_don_row0c (R1 and R3 outside Dark Force asserted; the Dark Force window measured, cause open; the blind set)
Claim (the working agent's sentence): Freeze tests/audit_don_row0c.sh's expectation (audit_don_row0c.sh.txt; tap pal_rows_tap.lua.txt, whose V line carries P1's +0x1C3 as f1c3). ASSERTED: P1's palette row 0x0C equals native vs2 on every frame from 2500 of the electrocute rig (R1), and on every frame of the 15 Donovan naming parts (R3) OUTSIDE native's P1 +0x1C3 frames; the `row-reverted` control requires the known-bad leg (row 0x13 back to vsavj's 0x0040 in the opcode share, its write checked by the `opatch-readback` control) to differ on R1 and, outside those frames, in every census part except a frozen blind set of ten (donovan_1, 2, 6, 8, 9, 10, 11, 13, 14, 15). run6_final.log (build/agent216/mb_294): PASS — R1 0, R3 0 outside, both controls FIRED (BAD: R1 55, 5 of 15 parts); mode_row_reverted_current.log (this script): the row-reverted MODE FAILS R1 (55) and R3 (852); mode_opatch_readback_current.log (this script): the opatch-readback MODE FAILS on the readback. MEASURED, NOT ASSERTED, CAUSE OPEN: inside native's +0x1C3 frames row 0x0C differs on 1511 frames, only in donovan_3/4/6/7 (run2_df_rule.log: 378/378/378/377 within native's 388/388/388/387 +0x1C3 frames; run1_before_df_rule.log, before the window rule, shows the same 1511 as R3's whole difference); df6_runs.txt shows native setting +0x1C3 over 2900-3287 on donovan_6 and ours never; df_colour_vs_brightness.txt shows, on donovan_6 only, that the difference on rows 0x0A and 0x0C is in colour, not brightness; R5 (run6_final.log) re-runs donovan_6 with +0x1C3 poked to 1 over native's window and the difference is unchanged (378), a poke with no positive control, so it rules no cause in or out (run4_r5_premise_failed.log is the run where R5 was still an assertion). The port behind it is ruled (ruling_294.txt: the maintainer's "indeed if the 6 free bytes exist, given the cost this seems like the best solution." and "Yes"), its condition met (test_dead_span.log: vsavj PRG:0x024024-0x024029 DEAD, four controls fired; dead_span_ours.txt: DEAD on our merged image), built after rule-checker run 2026-11-01-1541 (ledger_1541.txt and run_1541_meta.tsv name the run; run_1541_verdict.txt: VERDICT OK; build_after_1541.txt: the verdict recorded 07:42:45, the build's outputs 07:43:37). NOT TESTED: the cause of the inside-window difference (open; sheet294_df.png puts the Dark Force look before the maintainer — native draws Donovan in other colours than both of our builds; the newcomers' Dark Force is ruled vsav's CHANGE, ruling_df_change.txt, but no measurement ties the difference to it); whether the poke in R5 reaches the routine's read; the colour/brightness split on donovan_3/4/7; whether +0x1C3's window is the Dark Force window on donovan_3/4/7 (not traced); row 0x0A's differences (1904 frames, measured not asserted; on donovan_3 they extend outside the window: 739 frames against a 388-frame window, not characterised); how the sword LOOKS (sheets build/agent216/rc294/sheets/sheet294_p1..p3.png go to the maintainer; no conclusion about the look is drawn here); Donovan as P2; FBNeo and MiSTer; at the default BUILD (m3b_merged31) the gate FAILS its precondition by design until the freeze re-points it.
Artifacts (read every one, in full):
  - build/agent216/rc294/g0c/audit_don_row0c.sh.txt
  - build/agent216/rc294/g0c/pal_rows_tap.lua.txt
  - build/agent216/rc294/g0c/run1_before_df_rule.log
  - build/agent216/rc294/g0c/df6_runs.txt
  - build/agent216/rc294/g0c/run2_df_rule.log
  - build/agent216/rc294/g0c/df_colour_vs_brightness.txt
  - build/agent216/rc294/g0c/run4_r5_premise_failed.log
  - build/agent216/rc294/g0c/run6_final.log
  - build/agent216/rc294/g0c/mode_row_reverted_current.log
  - build/agent216/rc294/g0c/mode_opatch_readback_current.log
  - build/agent216/rc294/g0c/ruling_294.txt
  - build/agent216/rc294/g0c/ruling_df_change.txt
  - build/agent216/rc294/g0c/test_dead_span.log
  - build/agent216/rc294/g0c/dead_span_ours.txt
  - build/agent216/rc294/g0c/run_1541_verdict.txt
  - build/agent216/rc294/g0c/ledger_1541.txt
  - build/agent216/rc294/g0c/run_1541_meta.tsv
  - build/agent216/rc294/g0c/build_after_1541.txt
  - build/agent216/rc294/g0c/sheet294_df.png
