THE PACKET

Decision kind: recommendation
Subject: A working rule on when to commit (commit only at a boundary that needs one; run the bookkeeping gates before every tier), proposed to the maintainer
Claim (the working agent's sentence): proposal.md's figures come from build/agent203/commit_rule/measurer_return.txt (eight tiers, four NOT GREEN, four commits since the 14z-202 close); each of the four reds was a gate of the proposal's step-2 list (mid2 test_rule_checker, mid3 test_must_fire_census test_gate_descriptions test_gate_coverage_current, mid5 test_gate_coverage_current, tier7 test_rule5_census, per the logs); the proposal changes no ruling in DECISIONS_HISTORY.md (#290's guard, the close). NOT TESTED: that step 2's list catches every red a future tier could find (it lists today's four classes and the gates of changed files); any time saving (the counterfactual tiers were not run); the cause of each red is the session's reading of its log, not a measurer figure.
Artifacts (read every one, in full):
  - build/agent203/commit_rule/proposal.md
  - build/agent203/commit_rule/measurer_return.txt
  - build/agent203/mid1.log
  - build/agent203/mid2.log
  - build/agent203/mid3.log
  - build/agent203/mid4.log
  - build/agent203/mid5.log
  - build/agent203/mid6.log
  - build/agent203/tier7.log
  - build/agent203/tier8.log
  - STATE.md
  - docs/project/session_close.md
  - DECISIONS_HISTORY.md
  - tools/git-hooks/green_guard.py
