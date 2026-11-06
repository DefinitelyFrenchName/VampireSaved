THE PACKET

Decision kind: recommendation
Subject: record #310 group 7 batch 2 done: 18 dead-leg rows over 12 gates (14z-221c)
Claim (the working agent's sentence): #310 group 7 batch 2 is done and goes in with this close: 18 new rows of tests/expected/dead_leg_unjudged.tsv (dead_leg_unjudged.tsv, 43 rows in all) over 12 gates — audit_column_flash, audit_extra_pass, audit_phobos_dmg_residual, audit_pyron_ring, audit_tech_roll, audit_tick_phase, test_down_flash_mechanism, test_dualtrack, test_obj_records, test_random_select_tenants, test_rehit_ring, test_vanilla_command_join (batch2.patch.txt) — read UNJUDGED under a dead emulator and their plain runs read red and silent: tests/test_dead_leg_unjudged.sh (test_dead_leg_unjudged.sh) PASSed over the 43 rows on ERIS at scratch commit a9d02ca8, before its only-instrument check was added, (eris_r2_live2_proof_plain.log, eris_r2_live2_head.txt), and its two controls fire in-gate and are HONOURED as modes (eris_r2_live2_proof_nj-stripped.log, eris_r2_live2_proof_plain-loud.log, eris_r2_live2_dead.tsv); with a LIVE emulator every one of the 12 gates still PASSes plain and all 18 of its batch-2 modes read HONOURED (eris_r1_live_runs.tsv: 10 gates and 14 modes at 3115e7db; eris_r2_live2_runs.tsv: audit_phobos_dmg_residual and audit_tick_phase with their 4 modes, plus audit_crash_sweep_emu, at a9d02ca8; the two commits differ only in those two gates and the table, eris_r1_r2_diff.txt); test_dualtrack's dead leg is FBNeo, named in the table's new fifth column, and the gate now runs such a row's mode once more with ONLY that instrument dead and MAME_BIN UNSET (env -u, never made dead), which must read the same class (mac_plain.log: "test_dualtrack@stray-byte-growth reads UNJUDGED with ONLY FBNEO_BIN dead (MAME_BIN unset, never made dead)"; neither tests/test_dualtrack.sh nor tools/run_replay_fbneo.sh names MAME_BIN at all, and the latter's binary is FBNEO_BIN's, dualtrack_mame.txt; with FBNeo live the same mode reads HONOURED, eris_r1_live_runs.tsv); the gate as it now stands PASSes on this Mac and both its modes read HONOURED (mac_plain.log, mac_mode_*.log, mac_modes_classified.txt, mac_run_head.txt: run on the tree at blobs.txt's 'now' column); both ERIS runs used the emu/fbneo submodule at 79188379 with only the tracked patches 0001 and 0002 applied, the same files as the Mac's, built 2026-09-30 and unchanged since (fbneo_state.txt); blobs.txt follows each batch-2 file from ERIS's a9d02ca8 to the Mac tree now: every file equalled its ERIS blob before #359's trap fix (applied to this tree after the ERIS runs), except docs/project/gate_coverage.md (generated, regenerated at the close) and tests/test_dead_leg_unjudged.sh (the only-instrument check, proven on the Mac after the fix); #359's fix then changed one line in six of them, a trap line, and no other line (blobs.txt's last column). NOT TESTED: the 12 gates' LIVE runs ran on ERIS (Linux/WSL2) only, before #359's trap fix, carried here by blob equality and, for audit_column_flash, audit_extra_pass, audit_phobos_dmg_residual, audit_tick_phase and test_obj_records, by that fix changing only their trap line (a normal-path exit is untouched by it: #359's own proof, not shown here); no live run of the batch on the merged Mac tree; the FBNeo binary is identified by its sources and their dates, not by a hash of the binary; the Mac tree beside these files carries other work of this sitting (#357/#363, #354, #359) that the ERIS commit did not; gates whose controls run concurrently are judged here one run at a time, and the write-trace re-check of the batch's gates on tests/controls_concurrent*.txt after their edit is not shown (it runs on PILOT after #359 merges); group 7's remaining gates (the six held out: Verilator, MAME_REF_BIN, test_release_roundtrip; podman's; the 14 two-mode gates on the concurrent list; every gate with three or more modes) are not in this batch, so #310 stays open; test_meter_gain SKIPs on a host without ../community/vsav-framedata.xlsx and reads LIES in the proof gate there unless SHEET is set (how the ERIS run supplied it is not shown in these artifacts; eris_r2_live2_proof_plain.log reads its row UNJUDGED), a gap of that gate's environment, not fixed here; the bookkeeping gates (gate index, coverage, descriptions, must-fire census) run at the close's clean checkout.
Artifacts (read every one, in full):
  - build/agent221c/rc310/batch2.patch.txt.lines-1-320 (lines 1-320 of build/agent221c/rc310/batch2.patch.txt)
  - build/agent221c/rc310/batch2.patch.txt.lines-321-639 (lines 321-639 of build/agent221c/rc310/batch2.patch.txt)
  - build/agent221c/rc310/blobs.txt
  - build/agent221c/rc310/dead_leg_unjudged.tsv
  - build/agent221c/rc310/dualtrack_mame.txt
  - build/agent221c/rc310/eris_r1_live_dead.tsv
  - build/agent221c/rc310/eris_r1_live_head.txt
  - build/agent221c/rc310/eris_r1_live_proof_nj-stripped.log
  - build/agent221c/rc310/eris_r1_live_proof_plain-loud.log
  - build/agent221c/rc310/eris_r1_live_proof_plain.log
  - build/agent221c/rc310/eris_r1_live_runs.tsv
  - build/agent221c/rc310/eris_r1_live_summary.txt
  - build/agent221c/rc310/eris_r1_r2_diff.txt
  - build/agent221c/rc310/eris_r2_live2_dead.tsv
  - build/agent221c/rc310/eris_r2_live2_head.txt
  - build/agent221c/rc310/eris_r2_live2_proof_nj-stripped.log
  - build/agent221c/rc310/eris_r2_live2_proof_plain-loud.log
  - build/agent221c/rc310/eris_r2_live2_proof_plain.log
  - build/agent221c/rc310/eris_r2_live2_runs.tsv
  - build/agent221c/rc310/eris_r2_live2_summary.txt
  - build/agent221c/rc310/fbneo_state.txt
  - build/agent221c/rc310/mac_mode_nj-stripped.log
  - build/agent221c/rc310/mac_mode_plain-loud.log
  - build/agent221c/rc310/mac_modes_classified.txt
  - build/agent221c/rc310/mac_plain.log
  - build/agent221c/rc310/mac_run_head.txt
  - build/agent221c/rc310/test_dead_leg_unjudged.sh
