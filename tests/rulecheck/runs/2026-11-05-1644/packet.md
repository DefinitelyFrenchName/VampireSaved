THE PACKET

Decision kind: expectation
Subject: freeze tests/expected/dead_leg_unjudged.tsv: #310 group 7 batch 1, 25 control modes read UNJUDGED on a dead emulator and HONOURED on a live one (PILOT) (14z-221)
Claim (the working agent's sentence): tests/expected/dead_leg_unjudged.tsv can be frozen as written (dead_leg_unjudged.tsv): 25 rows, each a gate's control mode that reads UNJUDGED (classify.sh) when its emulator is dead, and HONOURED (stripped class) when the gate's `# #310 g7 NJ` lines are neutered. Selection: of the 37 batch-1 candidates (batch1_candidates.tsv, census_rows.tsv from the 14z-215 re-census), six were left out by name before any run because a dead MAME_BIN does not kill their legs — four MiSTer gates (verilator), test_release_roundtrip (no emulator leg) and audit_stock_emulator_stall (a second, stock MAME at MAME_REF_BIN) (excluded.txt) — and these six were never run dead; the other 31 were run with MAME_BIN=/usr/bin/false at d3e8810d (baseline.sh, base_classes_d3e8810d.tsv): 25 HONOURED, 1 LIES, 4 DIED, 1 REFUSED. The rows are the 25 HONOURED minus test_dualtrack (its legs run tools/run_replay_fbneo.sh, and its plain run PASSES with a dead MAME: excluded.txt), plus audit_dispatch_census drift-clock (LIES: that MODE exited 0 on zero legs, base_classes_d3e8810d.tsv; the gate's plain run with the same dead emulator exited 2, plain_dead.txt, run before the gate's edit by the files' times; why it exited 2 its one-line log does not show). The change (batch_1.diff, batch_2.diff, batch_3.diff, against d3e8810d) adds vs_ctl_nj to tests/lib/controls.sh, calls it beside each liveness check of the 25 gates, and makes six modes' closes fire only on their own finding. Measured on the Mac at the current tree: test_dead_leg_unjudged.sh PASSES (gate_mac.log): 25 rows UNJUDGED, every plain run red and silent, 25 neutered copies HONOURED. Its control nj-stripped prints CONTROL FIRED and classifies HONOURED (ctl_nj-stripped.log). Its control plain-loud (fixed after rule-checker run 2026-11-05-1641 found it firing on a crash of its own planted copy) now plants a helper that prints without a mode and cannot crash, swaps it into section 1 and into every row's gate in section 2, and prints CONTROL FIRED only when section 1 shows the exact NOT JUDGED line and some plain run prints it: it fired with 23 of 25 plain runs printing (ctl_plain-loud.log; the two that stay silent: audit_dispatch_census prints its NOT JUDGED only under a mode, batch_1.diff, and audit_id_writers' calls outside its mode branch guard a missing or unregistered BUILD and a failed ROM audit, batch_2.diff, which a dead emulator with the default BUILD and passing ROMs does not reach, as the MUST-FIRE line states), and a copy of the gate with the old crashing plant reads CONTROL DEAD, LIES (ctl_plain-loud_crashcopy.log, crashcopy.sh). On PILOT at scratch commit aefcb1a7 (pilot_t310g7.sh, pilot_summary.txt), with a live emulator, 25 of 25 plain runs PASS and 28 of 28 control modes read HONOURED (pilot_runs.tsv), so the added lines do not fire on a live leg; the gate as it was at aefcb1a7 passes on Linux (pilot_dead_leg.out); audit_move_parity_attribution, the one batch gate on a concurrent-controls list (lists.txt), re-traced SAFE (pilot_overlap.txt), row rewritten (controls_concurrent_emu.diff). The batch's 25 gates and controls.sh differ from aefcb1a7 only by five FOLLOWS comment lines (scratch_vs_tree.diff); the table is equal and the gate differs by the plain-loud fix (new_files_blobs.txt, gate_since_pilot.diff). NOT TESTED: the six candidates never run dead and test_dualtrack (later batches, each needing its own dead instrument); a leg launched other than through MAME_BIN in any row's gate; a leg that runs partway and then dies (only an emulator that exits at once was used); the plain-run silence of audit_dispatch_census and audit_id_writers by the plain-loud control (it rests on the reading of batch_1.diff and batch_2.diff above, and for audit_id_writers on the default BUILD and passing ROMs); the live plain and mode runs on macOS; the fixed gate and the five FOLLOWS edits on PILOT (the gate runs no emulator); the 4 DIED and 1 REFUSED rows and the rest of group 7; tests/lib/classify.sh reading a crash quoted inside a gate's own FAIL line as HONOURED (seen through this control, not changed); audit_guard_corpus known-crash's FIRED text names vec4 while PILOT's run crashed on vec3 (seen, predates the batch).
Artifacts (read every one, in full):
  - build/agent221/t310g7/rc/dead_leg_unjudged.tsv
  - build/agent221/t310g7/rc/test_dead_leg_unjudged.sh
  - build/agent221/t310g7/rc/classify.sh
  - build/agent221/t310g7/rc/batch_1.diff
  - build/agent221/t310g7/rc/batch_2.diff
  - build/agent221/t310g7/rc/batch_3.diff
  - build/agent221/t310g7/rc/batch1_candidates.tsv
  - build/agent221/t310g7/rc/census_rows.tsv
  - build/agent221/t310g7/rc/excluded.txt
  - build/agent221/t310g7/rc/base_classes_d3e8810d.tsv
  - build/agent221/t310g7/rc/baseline.sh
  - build/agent221/t310g7/rc/plain_dead.txt
  - build/agent221/t310g7/rc/gate_mac.log
  - build/agent221/t310g7/rc/ctl_nj-stripped.log
  - build/agent221/t310g7/rc/ctl_plain-loud.log
  - build/agent221/t310g7/rc/ctl_plain-loud_crashcopy.log
  - build/agent221/t310g7/rc/crashcopy.sh
  - build/agent221/t310g7/rc/pilot_t310g7.sh
  - build/agent221/t310g7/rc/pilot_summary.txt
  - build/agent221/t310g7/rc/pilot_runs.tsv
  - build/agent221/t310g7/rc/pilot_dead_leg.out
  - build/agent221/t310g7/rc/pilot_overlap.txt
  - build/agent221/t310g7/rc/lists.txt
  - build/agent221/t310g7/rc/controls_concurrent_emu.diff
  - build/agent221/t310g7/rc/scratch_vs_tree.diff
  - build/agent221/t310g7/rc/new_files_blobs.txt
  - build/agent221/t310g7/rc/gate_since_pilot.diff
