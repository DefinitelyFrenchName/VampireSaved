THE PACKET

Decision kind: recommendation
Subject: #172: the agent-architecture scope document and its recommendation (deterministic hook checks first, a procedural model checker beside rulecheck, slices S1-S5), put to the maintainer for rulings
Claim (the working agent's sentence): The scope document recommends binding the working discipline first with deterministic Claude Code hooks (deny detached launches and pgrep waiters; block a Stop while a finished background task is unread; a close-time process sweep; settings protected from edit), then a context-free procedural model checker beside rulecheck, then worker and orchestrator definitions, and asks the maintainer to rule five questions; it rests on (a) a census of eleven session transcripts by tools/agent/transcript_gaps.py and (b) four hook behaviours measured by tools/agent/probe_hooks.sh. NOT tested: that detached launches CAUSE the idle gaps — the census shows a correlation dominated by one session (14z-174: 97 detached, 0 tracked, 11 gaps ended by a status question), which slice S1's transcript replay is meant to test; the waste itself — the 1,623 minutes are an upper bound that includes time jobs were genuinely running; the status classifier (keyword plus an 80-character bound) was checked by reading the messages the bound reclassified and the 14z-174 detail list, not every session's gaps; the hooks were measured only in headless claude -p runs on Haiku, never in an interactive session or on the orchestrator's model; prompt/agent hooks, subagent frontmatter (model, effort, hooks), permissions deny on settings edits and the --agent flag are documented or read from CLI help and never exercised; the procedural checker's questions are drafts with no fixture and no calibration; model reachability is one one-line probe per model. No behaviour a player could feel is concluded, and no decision is attributed to the maintainer beyond the ask quoted from the issue.
Artifacts (read every one, in full):
  - docs/project/agent_architecture_scope.md
  - tools/agent/transcript_gaps.py
  - tools/agent/probe_hooks.sh
  - build/agent172/census.txt
  - build/agent172/census_14z174_detail.txt
  - build/agent172/census_selftest.txt
  - build/agent172/probe_run.txt
  - build/agent172/cli_agent_flag.txt
  - build/agent172/issue_172.txt
  - docs/project/rule_checker.md
