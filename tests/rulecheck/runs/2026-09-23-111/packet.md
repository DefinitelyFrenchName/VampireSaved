THE PACKET

Decision kind: recommendation
Subject: recommend that the maintainer install the S4 call gate (tools/agent/hooks/pre_agent.py, a PreToolUse hook on Agent|Task) as proposed under build/agent172/proposal_pre_agent/
Claim (the working agent's sentence): The proposed call gate implements the 2026-09-23 S4 ruling on the Agent CALL — refusing a model above Opus-class, a model override on a defined worker, an undefined non-fork type with no model unless it is Explore, and a template-driven worker's prompt missing a template heading, while allowing forks — and it is proven by 24 cases (every rule both ways, fail-open included) run against the hook as a subprocess, with the archive replayed (147 of 278 past Agent calls would have been refused, 83 of them calls that ran within the cap); its premises are probe_agents.sh legs A2, A8, A9 and A11 (run log attached). NOT tested: the hook has not been installed or run live by the harness (A8 proved a hook of this shape can deny an Agent call, not this file); the Explore allowlist rests on one controlled run under a Fable parent plus the archive, and a future Claude Code version may change it (A11 re-measures it); claude-code-guide cannot be probed headless and is therefore refused without a model; the hook cannot see the orchestrator's model, so it refuses within-cap calls it cannot distinguish; and a worker writing a tracked file through Bash is not held by it.
Artifacts (read every one, in full):
  - build/agent172/proposal_pre_agent/pre_agent.py
  - build/agent172/proposal_pre_agent/prove.py
  - build/agent172/proposal_pre_agent/prove_14z177.txt
  - build/agent172/proposal_pre_agent/INSTALL.md
  - build/agent172/proposal_pre_agent/settings_snippet.json
  - tools/agent/probe_agents.sh
  - build/agent172/probe_agents_14z177.txt
  - docs/project/agent_architecture_scope.md.lines-153-168 (lines 153-168 of docs/project/agent_architecture_scope.md)
  - DECISIONS_HISTORY.md.lines-30-62 (lines 30-62 of DECISIONS_HISTORY.md)
