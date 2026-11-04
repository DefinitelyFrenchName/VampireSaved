THE PACKET

Decision kind: expectation
Subject: M25: donovan_2's move-parity rows and their attribution re-frozen for #345 A1b's accepted timing
Claim (the working agent's sentence): Re-freeze tests/expected/move_parity_events.tsv and tests/expected/move_parity_attribution.tsv on merged-m25, build/m3b_merged33 (its registry row, measured key and program: build_identity.txt). In move_parity_events.tsv only donovan_2's rows move (move_parity_events.tsv.diff): event 2 Blizzard Sword [HP] DIFF +54 cnt -> DIFF +58 cnt,node, and events 3-25 IDENT -> DIFF after:2, 24 rows; every other row equals the M24 file, and donovan_2's 26 rows equal what 14z-219 measured on its scratch build build/agent219/t345a/mg (parity_vs_219_and_m24.txt), whose program a24aa560 is merged-m25's (programs.txt). The ruling put exactly this, "donovan_2's parity events 3-25 turn DIFF (24 rows move)", and the maintainer answered "Accept, freeze A1b (Recommended)" (DECISIONS_HISTORY.md "Ruled 2026-11-03 (14z-219) — #345: the built A1b's timing is accepted"). In move_parity_attribution.tsv (move_parity_attribution.tsv.diff) the root donovan_2:2 SLOWDOWN reads "zero-pass frame native [3098] ours []" (was native [] ours [3094]), 23 new rows attribute donovan_2 events 3-25 to that root, and the header the gate writes names the build; tests/audit_move_parity_attribution.sh's FREEZE text now writes "First frozen 14z-168 (GitHub #136); this freeze with FREEZE=1 on $(basename "$BUILD")" (audit_move_parity_attribution.sh.diff), after rule-checker run 2026-11-04-1600 found the old text dating this build's freeze to 14z-168; the same diff carries the M25 re-point sweep's change of the gate's default BUILD from build/m3b_merged32 to build/m3b_merged33. The move-parity table was frozen by ALL=1 FREEZE=1 on ERIS at snapshot S3 (S3_freeze_audit_move_parity.log, which names "build m3b_merged33": 64 legs, 526 events of 32 parts) and verified at S3 by audit_rng_forms' form-A re-run of all 32 parts, "move_parity under A equals tests/expected/move_parity_events.tsv (526 rows)" (verify_audit_rng_forms.log, which names "build build/m3b_merged33"; verify_rows.tsv). The attribution was frozen on ERIS at S3 (S3_freeze_audit_move_parity_attribution.log), its header re-frozen on the Mac with the rows unchanged (mac_freeze_audit_move_parity_attribution.log, rows_eris_vs_mac.txt) and verified on the Mac, "every one of the 51 frozen DIFF rows is attributed" and "every row as frozen", both controls fired (mac_verify_audit_move_parity_attribution.log). NOT tested: the attribution logs print no build line, so which build they ran rests on the gate's default (build/m3b_merged33 in the diff) with no BUILD given; the 24 moved rows were not captured one by one (the captures put to the maintainer showed Blizzard Sword's held pictures and the trail, REC_lostframes.md); the battery's own audit_move_parity row ran its default three parts, not all 32; FBNeo and MiSTer were not measured.
Artifacts (read every one, in full):
  - build/agent220/m25/rc/r_parity2/move_parity_events.tsv.diff
  - build/agent220/m25/rc/r_parity2/move_parity_attribution.tsv.diff
  - build/agent220/m25/rc/r_parity2/audit_move_parity_attribution.sh.diff
  - build/agent220/m25/rc/r_parity2/build_identity.txt
  - build/agent220/m25/rc/r_parity2/parity_vs_219_and_m24.txt
  - build/agent220/m25/rc/r_parity2/programs.txt
  - build/agent220/m25/rc/r_parity2/S3_freeze_audit_move_parity.log
  - build/agent220/m25/rc/r_parity2/verify_audit_rng_forms.log
  - build/agent220/m25/rc/r_parity2/verify_rows.tsv
  - build/agent220/m25/rc/r_parity2/S3_freeze_audit_move_parity_attribution.log
  - build/agent220/m25/rc/r_parity2/mac_freeze_audit_move_parity_attribution.log
  - build/agent220/m25/rc/r_parity2/rows_eris_vs_mac.txt
  - build/agent220/m25/rc/r_parity2/mac_verify_audit_move_parity_attribution.log
  - build/agent220/m25/rc/r_parity2/REC_lostframes.md
  - DECISIONS_HISTORY.md.lines-9769-9786 (lines 9769-9786 of DECISIONS_HISTORY.md: its INDEX entry "## Ruled 2026-11-03 (14z-219) — #345: the built A1b's timing is accepted; A1b freezes in M25 with #3")
