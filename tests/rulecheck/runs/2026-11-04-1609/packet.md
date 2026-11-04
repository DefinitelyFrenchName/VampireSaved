THE PACKET

Decision kind: expectation
Subject: M25: the freeze's relocation, build-row and static re-freezes (beyond A1b's four timing files)
Claim (the working agent's sentence): Re-freeze, for the M25 freeze on merged-m25 build/m3b_merged33 and donovan-m29 build/don_m29 (registry rows, measured keys and programs: build_identity.txt), the expectations and pins the freeze moved other than #345 A1b's four timing files (those went through runs 2026-11-04-1601, -1602, -1604 and -1606). (1) The twelve battery expectations in diffs/ (column_flash, defense_row_reads, df_field_readers_live, df_modes, dmg_legacy_sweep, hitbox_parity, ladder_tenant_vs_palette, latch_reads, phobos_dmg_residual, reaction_class_live, tenant_cpu_ai, throw_registration), re-frozen with FREEZE=1 on ERIS at snapshot S3: every changed line is a hex value moved by +0x1610, the build row or build directory, or a header line naming the build, except hitbox_parity's donovan_1 row "regions=21" -> "regions=23" (attr_battery_refreeze.txt); +0x1610 is the shift of every region placed after the two regions M25 adds at the extension's head — the 0x2FE copy at 0x400010 and the 0x1308 table copy at 0x4013E0, each taking its 16-aligned extent, 0x300 + 0x1310 (attribution_merged.txt, attribution_don.txt: "INSERTED op ... 0x400010 len 0x2fe" and "0x4013e0 len 0x1308"; placements_head.txt: 57 regions above 0x400000 shifted +0x1610, Donovan's AI-script block x101aca +0x300). (2) tests/expected/roster_pairings/bases.tsv: Phobos 0x0045b6f0 -> 0x0045cd00 and Pyron 0x004af86c -> 0x004b0e7c, read from the image's own table at PRG:0x0BD97A, the other 30 rows the same (bases_derivation.txt). (3) audit_tenant_cpu_ai's seven placed sites re-pointed +0x1610, each new address holding the old one's eight opcode bytes (cpu_ai_sites.txt). (4) test_region_overlap: section 1's unique count 15 -> 17 — its trio reads build/m5_wide's extract, regenerated for M25, whose two new regions x06e1d2 and x1d7428 are in the listed unique set — and section 5's figures (unique 17 -> 19, the added names exactly x06e1d2 and x1d7428 and none removed (region_overlap_unique.txt), x026142 (38,69) -> (32,75), x05c800 (444,385) -> (429,400), total 2089 -> 2110) re-frozen, the PASS line's 2089 updated to 2110; Donovan's four shared copies are RAW identical to M24 and the moved bytes are words the normaliser maps through the new placed ranges (region_overlap_attr.txt; gate PASS test_region_overlap.log). (5) pointer_flow: new baselines merged-m25 and donovan-m29 — the two STRONG findings the same two moved +0x1610, data:long 1183 -> 1158 and 1262 -> 1264, every row followed by its bytes (pointer_flow_weak_class.txt, the tool pointer_flow_weak_class2.py.txt), the four rows that tool left unmatched followed by hand: each is a flagged long straddling a pointer one word earlier that moved exactly +0x1610, so the straddled value left the WIDE hole (pointer_flow_left4.txt; rule-checker run 2026-11-04-1607 found them untraced); gate PASS test_pointer_flow.log. (6) tests/expect/mister_prg_window.txt: the pos line re-frozen by --freeze on the Mac (prgwin_freeze.log PASS, every structural assertion passed, the neg line unchanged) after the S2 lane read it moved (prgwin_S2_lane.log), its earlier re-freeze notes kept and an M25 note added (diffs/tests_expect_mister_prg_window.txt.diff). (7) rule 5: the new keys of [[obj_hook_extra]], [[ref_pin]] and [[port_patch]].only_variant_slot classified, and a declared growth of seven only_variant_slot rows, 223 -> 230, its growth note and ledger line naming the two rulings' DECISIONS_HISTORY.md entries (diffs; test_rule5_census.log PASS, all four controls fired); test_manifest_merge's port_patch row (25,69,28)/105 (test_manifest_merge.log PASS); test_m3a_reproducible's donovan and merged pins 63447128 and a24aa560; the three charmaps and their page hashes (test_charmap_current.log PASS). (8) The emulator-tier classifier, kept identical in tests/run_all_static.sh and tests/run_all_emulator.sh, now matches a call of test_crash_sweep.sh with --tier emulator, after the S2 parity run read audit_crash_sweep_emu as a DEAD ROW (parity_S2_dead_row.log), with a two-sided case in tests/test_emulator_runner.sh (test_emulator_runner.log PASS) and the S3 battery's registry check "255 emulator-tier gates; 255 registered" (S3_battery_registry_and_tail.txt). The S3 battery ran 183 PASS, 0 FAIL, 4 SKIP, the SKIPs the host-only rows test_release_binaries, test_readme_recording, audit_release_linux_desktop and audit_release_linux_cleanhost (S3_battery_results.tsv); test_freeze_artifacts_current PASSes on the tree (test_freeze_artifacts_current.log). NOT tested: that hitbox_parity's two extra regions are the two the freeze adds is read from the op delta, not traced; the PRG window's small counter moves (blocks 7 -> 8, cyc -559, rd_lo -724) are not separated by controls; the charmaps' JSON changes were reviewed by eye against the op delta, with no separating check; the four host-only rows were not run in the S3 battery and are left to the freeze packet; FBNeo was not measured for the re-frozen MAME expectations.
Artifacts (read every one, in full):
  - build/agent220/m25/rc/r_general/attr_battery_refreeze.txt
  - build/agent220/m25/rc/r_general/diffs/column_flash.tsv.diff
  - build/agent220/m25/rc/r_general/diffs/defense_row_reads.tsv.diff
  - build/agent220/m25/rc/r_general/diffs/df_field_readers_live.tsv.diff
  - build/agent220/m25/rc/r_general/diffs/df_modes.tsv.diff
  - build/agent220/m25/rc/r_general/diffs/dmg_legacy_sweep.tsv.diff
  - build/agent220/m25/rc/r_general/diffs/docs_project_tables_rule5_ledger.md.diff
  - build/agent220/m25/rc/r_general/diffs/hitbox_parity.tsv.diff
  - build/agent220/m25/rc/r_general/diffs/ladder_tenant_vs_palette.txt.diff
  - build/agent220/m25/rc/r_general/diffs/latch_reads.tsv.diff
  - build/agent220/m25/rc/r_general/diffs/phobos_dmg_residual.tsv.diff
  - build/agent220/m25/rc/r_general/diffs/reaction_class_live.tsv.diff
  - build/agent220/m25/rc/r_general/diffs/tenant_cpu_ai.txt.diff
  - build/agent220/m25/rc/r_general/diffs/tests_audit_tenant_cpu_ai.sh.diff
  - build/agent220/m25/rc/r_general/diffs/tests_expect_mister_prg_window.txt.diff
  - build/agent220/m25/rc/r_general/diffs/tests_expected_charmap_pages.sha256.diff
  - build/agent220/m25/rc/r_general/diffs/tests_expected_pointer_flow_donovan-m29.txt.diff
  - build/agent220/m25/rc/r_general/diffs/tests_expected_pointer_flow_merged-m25.txt.diff
  - build/agent220/m25/rc/r_general/diffs/tests_expected_roster_pairings_bases.tsv.diff
  - build/agent220/m25/rc/r_general/diffs/tests_expected_rule5_baked.tsv.diff
  - build/agent220/m25/rc/r_general/diffs/tests_run_all_emulator.sh.diff
  - build/agent220/m25/rc/r_general/diffs/tests_run_all_static.sh.diff
  - build/agent220/m25/rc/r_general/diffs/tests_test_emulator_runner.sh.diff
  - build/agent220/m25/rc/r_general/diffs/tests_test_m3a_reproducible.sh.diff
  - build/agent220/m25/rc/r_general/diffs/tests_test_manifest_merge.sh.diff
  - build/agent220/m25/rc/r_general/diffs/tests_test_pointer_flow.sh.diff
  - build/agent220/m25/rc/r_general/diffs/tests_test_region_overlap.sh.diff
  - build/agent220/m25/rc/r_general/diffs/throw_registration.tsv.diff
  - build/agent220/m25/rc/r_general/diffs/tools_audit_rule5.py.diff
  - build/agent220/m25/rc/r_general/build_identity.txt
  - build/agent220/m25/rc/r_general/attribution_merged.txt
  - build/agent220/m25/rc/r_general/attribution_don.txt
  - build/agent220/m25/rc/r_general/placements_head.txt
  - build/agent220/m25/rc/r_general/bases_derivation.txt
  - build/agent220/m25/rc/r_general/cpu_ai_sites.txt
  - build/agent220/m25/rc/r_general/region_overlap_attr.txt
  - build/agent220/m25/rc/r_general/region_overlap_unique.txt
  - build/agent220/m25/rc/r_general/test_region_overlap.log
  - build/agent220/m25/rc/r_general/pointer_flow_weak_class.txt
  - build/agent220/m25/rc/r_general/pointer_flow_weak_class2.py.txt
  - build/agent220/m25/rc/r_general/pointer_flow_left4.txt
  - build/agent220/m25/rc/r_general/test_pointer_flow.log
  - build/agent220/m25/rc/r_general/prgwin_freeze.log
  - build/agent220/m25/rc/r_general/prgwin_S2_lane.log
  - build/agent220/m25/rc/r_general/test_rule5_census.log
  - build/agent220/m25/rc/r_general/test_manifest_merge.log
  - build/agent220/m25/rc/r_general/test_charmap_current.log
  - build/agent220/m25/rc/r_general/parity_S2_dead_row.log
  - build/agent220/m25/rc/r_general/test_emulator_runner.log
  - build/agent220/m25/rc/r_general/S3_battery_registry_and_tail.txt
  - build/agent220/m25/rc/r_general/S3_battery_results.tsv
  - build/agent220/m25/rc/r_general/test_freeze_artifacts_current.log
