THE PACKET

Decision kind: recommendation
Subject: #276 closed done: a snapshot tier's static run record comes home with its results (14z-205)
Claim (the working agent's sentence): #276 closes done: tests/run_all_static.sh copies results and control times into its own run record when STATIC_RESULTS_OUT sends them elsewhere, and tests/run_on_snapshot.sh copies every new build/static_runs/* record home (fix276.diff, test_static_runner_s26.txt); test_static_runner passes with section 26 and its two new controls fired, each failing the gate as a mode (static_runner.log, mode_runrec-lost.log, mode_runrec-controls-lost.log); test_run_on_snapshot passes with the new no-runs-copy-back control fired and failing it as a mode (run_on_snapshot.log, mode_no-runs-copy-back.log); through the collector's own static_runs(), a run given STATIC_RESULTS_OUT reads 0 runs on HEAD's runner and 1 with the new one (e2e.txt). Not tested: no real snapshot tier has run with the change (the snapshot runs the committed runner, so the first is the next close's, and that close's dashboard step runs before its tier); the snapshot tiers already run are not recovered; the 9-of-12 count of record-less runs is a listing of build/static_runs on 2026-10-19, not in the artifacts. The request and the answers: maintainer_words.txt; closing comment and row: closing_comment_276.md, row_276.tsv
Artifacts (read every one, in full):
  - build/agent205/tooling/fix276.diff
  - build/agent205/tooling/test_static_runner_s26.txt
  - build/agent205/tooling/static_runner.log
  - build/agent205/tooling/mode_runrec-lost.log
  - build/agent205/tooling/mode_runrec-controls-lost.log
  - build/agent205/tooling/run_on_snapshot.log
  - build/agent205/tooling/mode_no-runs-copy-back.log
  - build/agent205/tooling/e2e.txt
  - build/agent205/tooling/maintainer_words.txt
  - build/agent205/tooling/closing_comment_276.md
  - build/agent205/tooling/row_276.tsv
