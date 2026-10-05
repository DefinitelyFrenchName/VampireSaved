THE PACKET

Decision kind: expectation
Subject: 14z-192 M23 freeze: re-freeze the battery's reds (after run 685)
Claim (the working agent's sentence): Re-freeze the M23 battery's reds (after rule-checker run 2026-10-05-685, resolved) (ERIS build/emu_freeze_m23_p1: PASS 173, SKIP 2, FAIL 10; Mac MiSTer lane: PASS 2, FAIL 1; attr/battery_eris_results.tsv, battery_eris_driver.log, battery_mister_results.tsv), each by its own writer or by a named edit, with every red attributed in attr/battery_reds.txt. (1) BUILD ROW ONLY: audit_column_flash, audit_phobos_dmg_residual and audit_dmg_legacy_sweep, whose one moved row is "ours build merged-m22 797af4a5" -> "ours build merged-m23 f601342d" (eris_reds/audit_column_flash.log, eris_reds/audit_phobos_dmg_residual.log, eris_reds/audit_dmg_legacy_sweep.log), by FREEZE=1. (2) #222/#223: audit_column_flash_cause, whose three census rows at the landing reads (00395e, 003b36) and the air-dash caller (022af2) go DIFF -> SAME against vs2 and nothing else moves (eris_reds/audit_column_flash_cause.log), by FREEZE=1; and an edit to test_hui_electrocute and audit_trap_parity (gate_edits_010b.py) setting our frozen ring id 010a -> 010b, the id the gates' frozen native lists already carry and ERIS measured on ours (eris_reds/test_hui_electrocute.log, eris_reds/audit_trap_parity.log), the move attributed to #223 by a separating control (ring223/: both gates unedited on merged-m23 and on build/hui61, which carries #223 per check_built.txt, fire 010b and fail; on ctl_nolanding, merged-m23 minus #223 only, they fire 010a and pass as frozen), with test_hui_electrocute's by-name assertion of the 010a/010b pair replaced by an assertion of no cross-leg delta. (3) THE CORPUS, replay 128_shadow_vs_legacy_vsavj (84f56520), the only replay added since the freeze/merged-m22 tag (attr/replays_since_m22.txt): audit_defense_row_reads and audit_reaction_class_live by FREEZE=1, their full tables on today's corpus being identical between M23 and M22 (attr/defense_row_reads_m23_vs_m22.txt: 115 rows each, ERIS's M23 table equal to the Mac's; attr/reaction_class_live_m23_vs_m22.txt: 350 rows each, only the vsavj leg differing from the frozen file); and tests/expected/mame_parity_ab.tsv by FREEZE=1 tests/test_mame_parity.sh on the Mac, to freeze replay 128, which ERIS's run put in section 2 and SKIPPED (attr/mame_parity_attr.txt). (4) MiSTer: tests/expect/mister_prg_window.txt by --pos-log/--neg-log --freeze from the lane's own legs, the moved pos line (cyc -621, rd_lo -676) following the graphics members alone in four controls covering every program combination (attr/prg_window_attr.txt, ctl_fingerprints.txt; rule-checker run 2026-10-05-684 resolved). (5) NOT A RE-FREEZE: audit_landing_sound's CONTROL DEAD was our re-point sweep bumping its pinned CTL_BUILD; restored to build/m3b_merged30 and re-run on ERIS, PASS with the control fired (attr/eris_landing_rerun.log); and build/merged1, which audit_merged_legacy regenerates, is identical between the Mac and ERIS on all 23 tracked files (attr/merged1_mac_vs_eris.txt) and differs from the committed files by exactly the four M23 rows in patch.json (844 -> 848 ops, none removed) and the merged-m23 program fingerprint (attr/merged1_rewrite.txt). Each writer's freeze is verified by re-running the gate without FREEZE. NOT TESTED: the mechanism by which graphics bytes move the MiSTer probe's program-read counts; the writers' results themselves, which follow this check and are verified by those re-runs; the content of build/merged1's one changed wheel_bank5.json entry (not decoded).
Artifacts (read every one, in full):
  - build/agent192/m23/attr/claim_refreeze3.txt
  - build/agent192/m23/attr/battery_reds.txt
  - build/agent192/m23/attr/battery_eris_results.tsv
  - build/agent192/m23/attr/battery_eris_driver.log
  - build/agent192/m23/attr/battery_mister_results.tsv
  - build/agent192/m23/eris_reds/audit_column_flash.log
  - build/agent192/m23/eris_reds/audit_phobos_dmg_residual.log
  - build/agent192/m23/eris_reds/audit_dmg_legacy_sweep.log
  - build/agent192/m23/eris_reds/audit_column_flash_cause.log
  - build/agent192/m23/eris_reds/test_hui_electrocute.log
  - build/agent192/m23/eris_reds/audit_trap_parity.log
  - build/agent192/m23/eris_reds/audit_defense_row_reads.log
  - build/agent192/m23/eris_reds/audit_reaction_class_live.log
  - build/agent192/m23/eris_reds/audit_landing_sound.log
  - build/agent192/m23/eris_reds/test_mame_parity.log
  - build/agent192/m23/gate_edits_010b.py
  - tests/test_hui_electrocute.sh
  - tests/audit_trap_parity.sh
  - build/agent192/m23/ring223/electro_m23.log
  - build/agent192/m23/ring223/electro_nolanding.log
  - build/agent192/m23/ring223/trap_m23.log
  - build/agent192/m23/ring223/trap_nolanding.log
  - build/agent192/m23/ring223/trap_hui61.log
  - build/agent192/m23/check_built.txt
  - build/agent192/m23/attr/replays_since_m22.txt
  - build/agent192/m23/attr/defense_row_reads_m23_vs_m22.txt
  - build/agent192/m23/attr/reaction_class_live_m23_vs_m22.txt
  - build/agent192/m23/attr/mame_parity_attr.txt
  - build/agent192/m23/attr/prg_window_attr.txt
  - build/agent192/m23/attr/ctl_fingerprints.txt
  - build/agent192/m23/prgw_ctl_mark.log
  - build/agent192/m23/prgw_ctl_nolanding.log
  - build/agent192/m23/prgw_ctl_noairdash.log
  - build/agent192/m23/prgw_ctl_nocode.log
  - build/emu_freeze_m23_mister/test_mister_prg_window.log
  - build/agent192/m23/attr/eris_landing_rerun.log
  - build/agent192/m23/attr/merged1_mac_vs_eris.txt
  - build/agent192/m23/attr/merged1_rewrite.txt
  - tests/audit_landing_sound.sh
