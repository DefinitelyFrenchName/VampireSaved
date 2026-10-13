THE PACKET

Decision kind: recommendation
Subject: #269: put to the maintainer — narrow the predictor first; neither selection saves much today — re-check after runs 976-979
Claim (the working agent's sentence): Recommend to the maintainer (build/agent199/t269/report.md) that #269 wait for a new, trace-scored narrowing of tools/static_confirm.py, the close running as today until then, with two alternatives offered: build now with a code-change control trigger whose safety the report states is unmeasured, or build the ruling as written. The maintainer's ruling is quoted in DECISIONS_HISTORY.md ("I agree with your proposal to turn the static tier around"); replacing or deferring what it adopted is asked of the maintainer, not decided. Measured on this session's tree against the 14z-198 close's run of record: the path plan re-runs 177 of 222 gates and carries 45 (t269_plan_rel.tsv), the carried costing 90 s of gates and 264 s of controls against 2,123 s and 6,070 s (price_plan.out), the plan taking 14 min 59 s (t269_plan_rel.time); R1 alone selects 13 gates (code_changed.out, its reach built as the predictor builds it) but leaves out 7,224 of 7,703 program reads in 30 gates on the 14z-191 traces, its negative control 7,500 in 82, its positive control, the full predictor on the same worktree and parser, 0 of 29,490 (score_r1.out, score_r1_control.out, provenance.out: PILOT's worktree at 559194f3 with the trace_static_reads.py whose sha1 equals the local one, and every sha1 and the predictor line of that run); the full predictor over changed code files marks 146 of 222 stale in 57 s, the carried 76 gates' controls costing 606 s (code_predict.out). Three inputs the predictor cannot see move within a session: origin/main in tests/test_commit_subject.sh and tests/test_close_tools.sh, and today's date in tests/test_rule_checker.sh (offtree_search_note.md and the staged lines). NOT TESTED: every measurement is of one session that edited tools heavily; the plans ran on the working tree at 9406c32b with this session's uncommitted and untracked files; the base runs' control seconds predate #268; the 14z-191 traces are of plain gate runs at 559194f3, not of today's gates and not of control runs; the positive control's 29,490 read pairs against 14z-191's 40,035 is put down to the untracked files of the clone then (1,983) against the worktree now (1), not traced read by read; code_predict_alluntracked.out came from the first version of code_predict.py (untracked files from everywhere), since changed; the off-tree search is a pattern search, not a trace, and that the other off-tree inputs (ROMDIR, untracked build dirs, submodules, tags, toolchain) do not move within a session is the working agent's judgement; whether a narrowed R3 would save enough is not measured.
Artifacts (read every one, in full):
  - build/agent199/t269/report.md
  - DECISIONS_HISTORY.md.lines-6637-6650 (lines 6637-6650 of DECISIONS_HISTORY.md)
  - build/agent199/tickets/T2.md
  - build/agent199/t269/t269_plan_rel.tsv
  - build/agent199/t269/t269_plan_rel.time
  - build/agent199/t269/price_plan.py
  - build/agent199/t269/price_plan.out
  - build/agent199/t269/code_changed.py
  - build/agent199/t269/code_changed.out
  - build/agent199/t269/code_predict.py
  - build/agent199/t269/code_predict.out
  - build/agent199/t269/code_predict_alluntracked.out
  - build/agent199/t269/score_r1.py
  - build/agent199/t269/score_r1.out
  - build/agent199/t269/score_r1_control.out
  - build/agent199/t269/provenance.out
  - build/agent199/t269/offtree_search_note.md
  - tools/static_confirm.py.lines-1-120 (lines 1-120 of tools/static_confirm.py)
  - tools/static_confirm.py.lines-280-305 (lines 280-305 of tools/static_confirm.py)
  - tools/trace_static_reads.py.lines-1-140 (lines 1-140 of tools/trace_static_reads.py)
  - tests/test_commit_subject.sh.lines-1-40 (lines 1-40 of tests/test_commit_subject.sh)
  - tests/test_close_tools.sh.lines-104-114 (lines 104-114 of tests/test_close_tools.sh)
  - tests/test_rule_checker.sh.lines-155-170 (lines 155-170 of tests/test_rule_checker.sh)
  - build/static_runs/20261012T151552Z_59126/results.tsv
