THE PACKET

Decision kind: build
Subject: #270: the documentation packet's presentation findings re-checked by the close checks, not re-run; the claim states its scope — re-check after runs 968-971
Claim (the working agent's sentence): #270 is built as its body asks (issue270.md): tools/rulecheck.py resolve --recheck RUNDIR --checks NAMES (rulecheck.py lines 1003-1152) resolves a VIOLATED run only after it RUNS the close run directory's checks in full itself (run_recheck: tools/close_checks.py run, then status) with every check as expected, and only on a directory whose checks.tsv was rendered by tools/close_standing.py from tests/close_standing_checks.tsv at its current sha256, holds every standing row with the template's exit and command, each placeholder's fill pinned by standing_pattern (KEY, RUN and SESSDIR to their known values, ROW to text without the characters close_standing.py's BAD_TITLE refuses, inside its quotes, BASE to a hash, TRANSCRIPT to a path), and names only standing checks; it writes RECHECKED by RUNDIR into the ledger. A genuine render of the current standing set binds through recheck_problem itself with all 38 standing names, and the matcher accepts all 38 standing rows of the real 14z-198 close against the template version it was rendered from (real_render_match.out, with the tools/rulecheck.py sha1 it ran, the same as gates.log's). A full run took 83 to 101 s at the 14z-196..198 closes (full_run_cost.out). tools/close_standing.py claim (lines 327-334) opens with a SCOPE sentence naming what the checks cover, what the readers are asked (the items after NOT TESTED) and that route. The RESOLVE RECHECK section of tests/test_rule_checker.sh (lines 294-361 and 521-524), on a set rendered by the real close_standing.py, accepts the re-check once the fix exists and refuses it before (a red check), even beside a forged all-OK run record, and refuses no or an unknown check, the close's own --extra check, a render with a standing row deleted, a hand-edited standing command, shell text inside a filled ROW or RUN and a file with no render line; controls recheck-unchecked, recheck-own-checks, recheck-porous-fill and recheck-pruned-render FIRED in-gate and FAIL the gate as modes, as does claim-unscoped in tests/test_close_standing.sh (gates.log). The rule is in docs/project/rule_checker.md [VSP-184] (lines 246-263), STATE's close checklist step (6) and the skill's [VSP-184] line (SKILL.md line 138); STATE row (8) records the build. The ruling is the maintainer's "I agree with your proposals for C1, C2, C3, C4" (DECISIONS_HISTORY.md). NOT TESTED: which findings are presentation only is the working agent's reading — the re-check certifies that the standing checks pass after the fix, not that the named ones cover the finding, and the close's procedure check reads that choice; a render line and decl file written by hand to imitate a render, with every row equal to a genuine render, are not told apart from one (the checks still run); a ROW fill is bounded to its quotes, not compared with the findings row's real title; the ticket's done-when, this close's packet loop measured against 14z-196..198, is measured at this session's close, and #270 stays open until then; the full static tier has not run on this change, only the gates in gates.log.
Artifacts (read every one, in full):
  - build/agent199/t270/issue270.md
  - DECISIONS_HISTORY.md.lines-6637-6650 (lines 6637-6650 of DECISIONS_HISTORY.md)
  - tools/rulecheck.py.lines-1000-1153 (lines 1000-1153 of tools/rulecheck.py)
  - tests/test_rule_checker.sh.lines-290-375 (lines 290-375 of tests/test_rule_checker.sh)
  - tests/test_rule_checker.sh.lines-519-526 (lines 519-526 of tests/test_rule_checker.sh)
  - tests/test_rule_checker.sh.lines-575-625 (lines 575-625 of tests/test_rule_checker.sh)
  - tools/close_standing.py.lines-50-60 (lines 50-60 of tools/close_standing.py)
  - tools/close_standing.py.lines-102-143 (lines 102-143 of tools/close_standing.py)
  - tools/close_standing.py.lines-282-345 (lines 282-345 of tools/close_standing.py)
  - tools/close_standing.py.lines-410-435 (lines 410-435 of tools/close_standing.py)
  - tests/test_close_standing.sh.lines-20-32 (lines 20-32 of tests/test_close_standing.sh)
  - tools/close_checks.py.lines-1-130 (lines 1-130 of tools/close_checks.py)
  - tests/close_standing_checks.tsv
  - build/agent199/t270/gates.sh
  - build/agent199/t270/gates.log
  - build/agent199/t270/real_render_match.py
  - build/agent199/t270/real_render_match.out
  - build/agent199/t270/full_run_cost.sh
  - build/agent199/t270/full_run_cost.out
  - docs/project/rule_checker.md.lines-244-268 (lines 244-268 of docs/project/rule_checker.md)
  - STATE.md.lines-58-61 (lines 58-61 of STATE.md)
  - STATE.md.lines-89-89 (lines 89-89 of STATE.md)
  - .claude/skills/vampire-saved-port/SKILL.md.lines-138-138 (lines 138-138 of .claude/skills/vampire-saved-port/SKILL.md)
