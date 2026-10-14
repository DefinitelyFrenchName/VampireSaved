THE PACKET

Decision kind: recommendation
Subject: #274: land the narrowed --confirm predictor and close #274 on its fresh-trace score and benchmark
Claim (the working agent's sentence): Recommendation: land the narrowed --confirm predictor (tools/static_confirm.py at sha1 8474887b, tools/trace_static_reads.py at 792c967d, tests/test_static_confirm.sh with six new controls, tests/test_trace_static_reads.sh at 3108bc0b with the control scratch-unscored on the scorer's N-D clause and its mode exit fixed, so a control that catches nothing now exits 0 — the runner's LIES — where it exited 1 since 14z-191) and close #274 on build/agent200/t274/report.md. On a fresh trace of the 222 registered static gates on PILOT (build/agent200/t274/pilot/final_tr2.log) at 6e329411 with the session's build scratch present, today's predictor misses 15,017 reads in 2 gates (test_entropy_tripwire 15,013, test_applier_key_first 4) and the narrowed one misses 0, its over-narrowed control 59 in 6 gates — the narrowed score run by PILOT's score_cand.sh (line 10) executing ~/t200/final/trace_static_reads.py 792c967d, which carries the N-D drop clause (line 114), over static_confirm.py 8474887b, both last written at 09:24:24, before the score log's 09:29:35; today's is the clone's static_confirm.py 064232ae at 6e329411, which defines no drop_scratch, so the clause cannot act on its score, and which scorer program ran it is not recorded (measure_return6.txt C1-C3); the history backtest still catches its three recorded reds; on the 14z-199 change set (4,098 paths), re-run in a worktree of HEAD b497471c changed only in the four #274 files as they then stood (each sha1 equal to the saved copy's; the trace gate, bed5862d then, was amended after only in its mode exit) and the regenerated docs/project/gate_coverage.md (measure_return5.txt C3-C5), with each leg printing the sha1 of the predictor it imported, the narrowed predictor (8474887b) marks 154 of 222 gates stale in 403 s against HEAD's (064232ae) 167 in 1,789 s, the two legs started together (both output files born 10:56:04; the narrowed leg's last write 11:02:47, the base's 11:25:53), so the narrowed leg's 403 s ran wholly beside the base leg; the gate's 18 controls fire and each new one, run as a mode, exits 1, as does each of test_trace_static_reads' three (measured again after the mode-exit fix, measure_return6.txt C4). Every figure is a FIG line of build/agent200/t274/measure_return.txt, measure_return2.txt, measure_return3.txt, measure_return4.txt, measure_return5.txt or measure_return6.txt; which predictor the backtest ran is read from its code (backtest_code.txt: the invoked file's predict, in-process), not printed by it. NOT TESTED: the plan command itself (tests/run_all_static.sh --confirm) on the narrowed predictor — the benchmark runs predict over the change set a plan builds; what the 13 newly carried gates' executed controls cost; a quieter session's change set; whether a directory LISTING changes a gate's verdict (the trace sees reads by path only, so N-D keeps every whole-tree reader stale on scratch instead of scoring it); the five gates that exited non-zero under the trace and the five that printed SKIP there with exit 0 (test_applier_page, test_applier_page_browser, test_applier_vcdiff, test_community_crosscheck, test_release_roundtrip — no node, no Chrome, no xdelta3, no community workbook on PILOT): their reads may be short of a passing run's, and the predictor may carry them on a read the trace never saw; the trace ran on PILOT (Linux) while the predictor decides on this Mac, and no test shows a Linux run's reads stand for a Mac run's; a gate added after this trace, scored only by the next one — between the trace head 6e329411 and HEAD b497471c no gate script, test library, tool or registry changed (measure_return4.txt C3: 0 files; only STATE, the gotchas and rule-checker records did); the re-runs of test_entropy_tripwire and test_applier_key_first at HEAD are this Mac's logs, outside the measurer's spec; the three gates named as listing the scratch through git's untracked walk were read from the tr2 trace files by hand.
Artifacts (read every one, in full):
  - build/agent200/t274/report.md
  - build/agent200/t274/measure_return.txt
  - build/agent200/t274/spec_measure.md
  - build/agent200/t274/diff_static_confirm.txt
  - build/agent200/t274/diff_trace_static_reads.txt
  - build/agent200/t274/diff_test_static_confirm.txt
  - build/agent200/t274/diff_test_trace_static_reads.txt
  - build/agent200/t274/test_static_confirm.log
  - build/agent200/t274/measure_return2.txt
  - build/agent200/t274/spec_measure2.md
  - build/agent200/t274/backtest_code.txt
  - build/agent200/t274/pilot/base_tr2_summary.log
  - build/agent200/t274/pilot/final_tr2.log
  - build/agent200/t274/pilot/tr2.log
  - build/agent200/t274/pilot/done.tsv
  - build/agent200/t274/pilot/head.txt
  - build/agent200/t274/pilot/pilot_state.txt
  - build/agent200/t274/entropy_head.log
  - build/agent200/t274/applier_head.log
  - build/agent200/t274/bench.sh
  - build/agent200/t274/bench2.sh
  - build/agent200/t274/measure_return3.txt
  - build/agent200/t274/spec_measure3.md
  - build/agent200/t274/measure_return4.txt
  - build/agent200/t274/spec_measure4.md
  - build/agent200/t274/measure_return5.txt
  - build/agent200/t274/spec_measure5.md
  - build/agent200/t274/measure_return6.txt
  - build/agent200/t274/spec_measure6.md
  - build/agent200/t274/pilot/score_cand.sh
  - build/agent200/t274/pilot/scorer_identity.txt
  - STATE.md.lines-119-120 (lines 119-120 of STATE.md)
  - STATE_HISTORY.md.lines-363-363 (lines 363-363 of STATE_HISTORY.md)
  - build/agent199/close/tier_352eeaa8_confirm.log
