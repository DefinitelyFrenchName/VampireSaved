THE PACKET

Decision kind: recommendation
Subject: #172: the agent-architecture scope document and its recommendation, CORRECTED after runs 2026-09-23-97 and -98, put to the maintainer for rulings
Claim (the working agent's sentence): The scope document recommends binding the working discipline first with deterministic Claude Code hooks (deny detached launches and pgrep waiters; block a Stop while a finished background task is unread; a close-time process sweep; settings protected from edit), then a context-free procedural model checker beside rulecheck, then worker and orchestrator definitions, and asks the maintainer to rule five questions; it rests on (a) a census of eleven session transcripts by tools/agent/transcript_gaps.py, whose 14z-174 row reads 17 gaps, 11 ended by a status question, 12 detached launches (itemised in build/agent172/detached_14z174.txt) and 5 harness-tracked tasks (timed in build/agent172/tracked_14z174.txt by the tool's --tasks mode, which reads both notification forms), and (b) five hook probes by tools/agent/probe_hooks.sh including a must-stay-quiet control. NOT tested: that the invisibility of the long jobs CAUSED the idle gaps — across the eleven sessions the correlation is weak (sessions with many detached launches were rarely chased for status), and slice S1's replay is meant to test it; the waste itself — the 1,623 minutes are an upper bound that includes time jobs were genuinely running; the status classifier (keyword plus an 80-character bound) was checked by reading the messages the bound reclassified and the 14z-174 detail list, not every session's gaps; the DETACHED pattern was checked on 14z-174's twelve matches and on selftest cases, not on every match in the other ten sessions, and a detaching form it does not list would be missed; the notification forms were established on one session's transcript (14z-174) and the selftest, and a third form would be missed; the hooks were measured only in headless claude -p runs on Haiku, never in an interactive session or on the orchestrator's model; prompt/agent hooks, subagent frontmatter (model, effort, hooks), permissions deny on settings edits, the --agent flag and the absence of an event when a background Bash task finishes are documented or read from CLI help and never exercised; the procedural checker's questions are drafts with no fixture and no calibration; model reachability is one one-line probe per model. No behaviour a player could feel is concluded, and no decision is attributed to the maintainer beyond the ask quoted from the issue.
Artifacts (read every one, in full):
  - docs/project/agent_architecture_scope.md
  - tools/agent/transcript_gaps.py
  - tools/agent/probe_hooks.sh
  - build/agent172/census.txt
  - build/agent172/census_14z174_detail.txt
  - build/agent172/census_selftest.txt
  - build/agent172/detached_14z174.txt
  - build/agent172/tracked_14z174.txt
  - build/agent172/probe_run.txt
  - build/agent172/cli_agent_flag.txt
  - build/agent172/issue_172.txt
  - docs/project/rule_checker.md
