THE PACKET

Decision kind: recommendation
Subject: #274: land the narrowed --confirm predictor and close #274 on its fresh-trace score and benchmark
Claim (the working agent's sentence): Recommendation: land the narrowed --confirm predictor (tools/static_confirm.py at sha1 8474887b, tools/trace_static_reads.py at 792c967d, tests/test_static_confirm.sh with six new controls, tests/test_trace_static_reads.sh with the control scratch-unscored on the scorer's N-D clause) and close #274 on build/agent200/t274/report.md. On a fresh trace of the 222 registered static gates on PILOT (build/agent200/t274/pilot/final_tr2.log) at 6e329411 with the session's build scratch present, today's predictor misses 15,017 reads in 2 gates (test_entropy_tripwire 15,013, test_applier_key_first 4) and the narrowed one misses 0, its over-narrowed control 59 in 6 gates; the history backtest still catches its three recorded reds; on the 14z-199 change set (4,098 paths) the narrowed predictor marks 154 of 222 gates stale in 386 s against today's 167 in 1,814 s; the gate's 18 controls fire and each new one, run as a mode, exits 1, as does each of test_trace_static_reads' three. Every figure is a FIG line of build/agent200/t274/measure_return.txt or measure_return2.txt; which predictor the backtest ran is read from its code (backtest_code.txt: the invoked file's predict, in-process), not printed by it. NOT TESTED: the plan command itself (tests/run_all_static.sh --confirm) on the narrowed predictor — the benchmark runs predict over the change set a plan builds; what the 13 newly carried gates' executed controls cost; a quieter session's change set; whether a directory LISTING changes a gate's verdict (the trace sees reads by path only, so N-D keeps every whole-tree reader stale on scratch instead of scoring it); the five gates that exited non-zero under the trace (their reads may be short of a passing run's); a gate added after this trace, scored only by the next one; the re-runs of test_entropy_tripwire and test_applier_key_first at HEAD are this Mac's logs, outside the measurer's spec; the three gates named as listing the scratch through git's untracked walk were read from the tr2 trace files by hand.
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
  - STATE.md.lines-119-120 (lines 119-120 of STATE.md)
  - STATE_HISTORY.md.lines-363-363 (lines 363-363 of STATE_HISTORY.md)
  - build/agent199/close/tier_352eeaa8_confirm.log
