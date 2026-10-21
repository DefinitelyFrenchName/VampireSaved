THE PACKET

Decision kind: recommendation
Subject: #286: land the narrowings N-I, N-J and N-F-without-the-planner's-text in tools/static_confirm.py (adapted to #298's PROGRAM-CHANGED line), at the 14z-205c close
Claim (the working agent's sentence): The narrowed planner can land: on a strace of every static gate at b91532d8 (PILOT, a clean checkout from a bundle of the commit, 229 of 229 gates, 88,351 gate-file pairs) both the committed and the narrowed predictor score 0 misses, and the over-narrowed control misses 102 reads (CONTROL FIRED); test_static_confirm passes on the tree with all 30 of its controls firing and none dead, and test_trace_static_reads passes; it drops 8 gates from mid2's change set (59 to 51), 8 from a full run record (53 to 45) and 3 from a STATE.md-only change (41 to 38). The hunk that collided with #298's ruled PROGRAM-CHANGED line was resolved by keeping #298's line, which landing.diff leaves untouched (it carries no r1[g] line; REPORT.md 'One hunk moved'). Not tested: four gates exited non-zero under the trace (test_applier_page_browser, test_applier_page, test_emulator_staleness, test_release_roundtrip), so their traced reads may be short of a passing run's; the trace sees reads by path only (a read through git is not seen); the tree it lands in carries uncommitted changes since b91532d8 (the mister_mra.sh lock, the scratch-heal gate's section 6, records) that the trace does not cover; the savings are predictions, not a measured tier.
Artifacts (read every one, in full):
  - build/agent205c/t286/landing.diff
  - build/agent205c/t286/pilot/head.txt
  - build/agent205c/t286/pilot/status.txt
  - build/agent205c/t286/pilot/trace.log
  - build/agent205c/t286/pilot/tr/done.tsv
  - build/agent205c/t286/pilot/score_committed.log
  - build/agent205c/t286/pilot/score_narrowed.log
  - build/agent205c/t286/pilot/control_narrowed.log
  - build/agent205c/t286/pilot/patch.log
  - build/agent205c/t286/pilot/run_x2.sh
  - build/agent205c/t286/gate_main.log
  - build/agent205c/t286/predict_mid2_base.txt
  - build/agent205c/t286/predict_mid2_wt.txt
  - build/agent205c/t286/predict_fullrecord_base.txt
  - build/agent205c/t286/predict_fullrecord_wt.txt
  - build/agent205c/t286/predict_state_base.txt
  - build/agent205c/t286/predict_state_wt.txt
  - build/agent205b/t286/REPORT.md
  - STATE.md.lines-64-78 (lines 64-78 of STATE.md)
