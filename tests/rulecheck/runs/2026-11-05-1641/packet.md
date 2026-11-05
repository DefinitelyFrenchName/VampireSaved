THE PACKET

Decision kind: expectation
Subject: freeze tests/expected/dead_leg_unjudged.tsv: #310 group 7 batch 1, 25 control modes read UNJUDGED on a dead emulator and HONOURED on a live one (PILOT) (14z-221)
Claim (the working agent's sentence): tests/expected/dead_leg_unjudged.tsv can be frozen as written (dead_leg_unjudged.tsv): 25 rows, each a gate's control mode that reads UNJUDGED (tests/lib/classify.sh, classify.sh) when its emulator is dead, and HONOURED (stripped class) when the gate's `# #310 g7 NJ` lines are neutered. The rows are the #310 group 7 batch-1 candidates (batch1_candidates.tsv, census_rows.tsv from the 14z-215 re-census) whose dead-emulator run at d3e8810d read HONOURED (base_classes_d3e8810d.tsv, baseline.sh: MAME_BIN=/usr/bin/false), minus test_dualtrack, whose leg runs on FBNeo so a dead MAME cannot kill it; plus audit_dispatch_census drift-clock, which read LIES because its plain run passed on zero legs. The change (batch_1.diff, batch_2.diff, batch_3.diff, against d3e8810d) adds vs_ctl_nj to tests/lib/controls.sh, calls it beside each liveness check of the 25 gates, and makes six modes' closes fire only on their own finding. Measured: on the Mac at the current tree, test_dead_leg_unjudged.sh PASSES (gate_mac.log): all 25 rows UNJUDGED, every plain run red and silent, all 25 neutered copies HONOURED; its controls nj-stripped and plain-loud both exit 1 and classify HONOURED (ctl_nj-stripped.log, ctl_plain-loud.log). On PILOT at scratch commit aefcb1a7 (pilot_t310g7.sh, pilot_summary.txt), with a live emulator, 25 of 25 plain runs PASS and 28 of 28 control modes read HONOURED (pilot_runs.tsv), so the added lines do not fire on a live leg; the gate passes on Linux (pilot_dead_leg.out); audit_move_parity_attribution, the one batch gate on a concurrent-controls list, re-traced SAFE (pilot_overlap.txt) and its row rewritten (controls_concurrent_emu.diff). The tree differs from aefcb1a7 in the batch's files only by five FOLLOWS comment lines (scratch_vs_tree.diff), and the gate and table blobs are equal (new_files_blobs.txt). NOT TESTED: a leg launched other than through MAME_BIN (FBNeo, MiSTer) in any row's gate; a leg that runs partway and then dies (only an emulator that exits at once was used); the live plain and mode runs on macOS (the Mac ran only the dead-emulator cases); the five FOLLOWS-line edits re-run on PILOT; the 4 DIED and 1 REFUSED baseline rows and the rest of group 7 (later batches); audit_guard_corpus known-crash's FIRED text names vec4 while PILOT's run crashed on vec3 (seen, predates the batch, not addressed).
Artifacts (read every one, in full):
  - build/agent221/t310g7/rc/dead_leg_unjudged.tsv
  - build/agent221/t310g7/rc/test_dead_leg_unjudged.sh
  - build/agent221/t310g7/rc/classify.sh
  - build/agent221/t310g7/rc/batch_1.diff
  - build/agent221/t310g7/rc/batch_2.diff
  - build/agent221/t310g7/rc/batch_3.diff
  - build/agent221/t310g7/rc/batch1_candidates.tsv
  - build/agent221/t310g7/rc/census_rows.tsv
  - build/agent221/t310g7/rc/base_classes_d3e8810d.tsv
  - build/agent221/t310g7/rc/baseline.sh
  - build/agent221/t310g7/rc/gate_mac.log
  - build/agent221/t310g7/rc/ctl_nj-stripped.log
  - build/agent221/t310g7/rc/ctl_plain-loud.log
  - build/agent221/t310g7/rc/pilot_t310g7.sh
  - build/agent221/t310g7/rc/pilot_summary.txt
  - build/agent221/t310g7/rc/pilot_runs.tsv
  - build/agent221/t310g7/rc/pilot_dead_leg.out
  - build/agent221/t310g7/rc/pilot_overlap.txt
  - build/agent221/t310g7/rc/controls_concurrent_emu.diff
  - build/agent221/t310g7/rc/scratch_vs_tree.diff
  - build/agent221/t310g7/rc/new_files_blobs.txt
