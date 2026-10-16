THE PACKET

Decision kind: recommendation
Subject: #290: the deterministic green guard's design (git pre-commit and pre-push hooks keyed on a strict GREEN run at the committed tree), and the cost of the close's --confirm form on a doc-only commit, put to the maintainer for ruling
Claim (the working agent's sentence): The design in design.md answers #290's four open points (where it hooks, what it reads, what a mid-session commit needs, how it is overridden), holds the three shapes of the class as the ledger records them, enforces the tiers already ruled rather than adding one, quotes the maintainer's words and the documents verbatim with their lines, cites only figures the staged tier log, results files and ledger show, and leaves every choice that changes ruled procedure to the maintainer as Q1-Q4. Not tested: a snapshot of a git stash create commit has not been run; only three of the gates and tools that run git commit were read for whether they commit inside this clone; the --confirm form's cost was measured once on one doc-only change set; the causes given for its 177 executed controls and its R5 re-runs are read from the plan the log prints, not checked against tools/static_confirm.py; --confirm with --exec-controls none has never been run.
Artifacts (read every one, in full):
  - build/agent203/t290/design.md
  - build/agent203/t290/issue_290.md
  - build/agent203/mid1.log
  - build/agent203/mid1_results.tsv
  - build/agent203/mid1_results.controls.tsv
  - tests/rulecheck/ledger.tsv
  - DECISIONS_HISTORY.md
  - tools/git-hooks/commit-msg
  - tools/install_hooks.sh
  - .claude/settings.json
  - tests/run_all_static.sh
  - tests/run_on_snapshot.sh
  - docs/project/snapshot_runs.md
  - docs/project/session_close.md
  - HANDOFF.md
