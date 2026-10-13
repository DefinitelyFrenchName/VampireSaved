THE PACKET

Decision kind: recommendation
Subject: #269: put to the maintainer — every gate at a session close, controls only for gates whose code changed, instead of the path selection
Claim (the working agent's sentence): Recommend to the maintainer (build/agent199/t269/report.md) that #269 be built as: a session runs every static gate and executes controls only for gates whose code changed since the last run that executed them (rule R1 of tools/static_confirm.py), freeze and release unchanged — in place of the path selection the ruling adopted (DECISIONS_HISTORY.md: "I agree with your proposal to turn the static tier around"), which this asks the maintainer to replace, not the working agent. Measured on this session's tree against the 14z-198 close's run of record: the path plan re-runs 177 of 222 gates and carries 45 (t269_plan_rel.tsv), the carried 45 costing 90 s of gates and 264 s of executed controls in the base runs against 2,123 s and 6,070 s for the re-run ones (price_plan.out from price_plan.py), and the plan took 14 min 59 s (t269_plan_rel.time); 13 gates changed code since the base, computed in 20 s (code_changed.out from code_changed.py); the report's 2,213, 209 and 2,212 are marked DERIVED with their arithmetic. Three inputs the predictor cannot see move within a session: origin/main in tests/test_commit_subject.sh and tests/test_close_tools.sh, and today's date in tests/test_rule_checker.sh (offtree_search_note.md, and the staged lines). NOT TESTED: the plan was measured once, on a session that edited tools heavily, so whether a quieter session carries more is unknown; the plan ran on the working tree at 9406c32b with this session's uncommitted and untracked files; the base runs' control seconds predate #268, which cut test_close_tools' modes; the off-tree search is a pattern search by an Explore agent, not a trace, and that the other off-tree inputs stay fixed within a session is the working agent's judgement; R1 as the trigger assumes a control's result changes only with its gate's code, while a control perturbs real inputs that a data change could also affect; nothing of option 1 is built yet.
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
  - build/agent199/t269/offtree_search_note.md
  - tools/static_confirm.py.lines-1-75 (lines 1-75 of tools/static_confirm.py)
  - tests/test_commit_subject.sh.lines-1-40 (lines 1-40 of tests/test_commit_subject.sh)
  - tests/test_close_tools.sh.lines-104-114 (lines 104-114 of tests/test_close_tools.sh)
  - tests/test_rule_checker.sh.lines-155-170 (lines 155-170 of tests/test_rule_checker.sh)
  - build/static_runs/20261012T151552Z_59126/results.tsv
