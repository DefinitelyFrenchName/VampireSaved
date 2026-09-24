THE PACKET

Decision kind: recommendation
Subject: report #172 S4 step 4 done; recommend closing #158 and raising the transcript retention
Claim (the working agent's sentence): #172 slice S4 step 4 is complete as ruled (DECISIONS_HISTORY.md 14z-177 entries): every rule-checker reader in the ledger before run 2026-09-24-114 was handed this project's CLAUDE.md and its memory index (the census and the probe's A13 show CLAUDE.md for every general-purpose worker; the memory index was seen by a no-tool general-purpose worker in one interactive session), while the pinned definition .claude/agents/rule-checker.md (claude-opus-5-5, effort high, omitClaudeMd: true) received neither in its one no-tool interactive probe and in all twenty calibration readers (rulecheck.py spawned reads their own transcripts); all ten fixtures were recalibrated on the version-id definition (ledger 2026-09-24-124..133). I recommend (1) closing #158, because a calibration now counts only if read by the definition's current sha, the definition must name a version id (agent_defs.py), and every run's readers are checked from their own transcripts for the definition's model and effort, a fallback, and an instructions attachment; and (2) setting cleanupPeriodDays at user level, because Claude Code deleted 23 archived worker transcripts during this sitting at its 30-day default. NOT tested: that omitClaudeMd removes the memory index rests on ONE interactive spawn (a headless run loads no memory, so no scripted leg can show it) and that spawn ran on a different model from the memory probe that saw it; whether this session's harness reloaded the edited definition before the second round (the readers' model, effort and context are verified per run, the definition's body is not); a version id's resolution changing under a future Claude Code; and whether a value of cleanupPeriodDays disables the cleanup (undocumented).
Artifacts (read every one, in full):
  - build/agent172/pkt178/issue_158.txt
  - build/agent172/pkt178/memory_probe_evidence.txt
  - build/agent172/pkt178/context_census_14z178_afternoon.txt
  - build/agent172/pkt178/docs_lookup_retention.txt
  - build/agent172/probe_agents_14z178d.log
  - .claude/agents/rule-checker.md
  - tools/agent/agent_defs.py
  - tools/rulecheck.py.lines-85-100 (lines 85-100 of tools/rulecheck.py)
  - tools/rulecheck.py.lines-152-170 (lines 152-170 of tools/rulecheck.py)
  - tools/rulecheck.py.lines-414-440 (lines 414-440 of tools/rulecheck.py)
  - tools/rulecheck.py.lines-555-720 (lines 555-720 of tools/rulecheck.py)
  - docs/project/rule_checker.md.lines-74-90 (lines 74-90 of docs/project/rule_checker.md)
  - docs/project/rule_checker.md.lines-277-306 (lines 277-306 of docs/project/rule_checker.md)
  - docs/platform/gotchas.md.lines-2857-2928 (lines 2857-2928 of docs/platform/gotchas.md)
  - tests/rulecheck/ledger.tsv.lines-131-150 (lines 131-150 of tests/rulecheck/ledger.tsv)
  - DECISIONS_HISTORY.md.lines-30-103 (lines 30-103 of DECISIONS_HISTORY.md)
  - DECISIONS_HISTORY.md.lines-879-900 (lines 879-900 of DECISIONS_HISTORY.md)
