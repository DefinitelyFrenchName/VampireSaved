THE PACKET

Decision kind: build
Subject: #270: the documentation packet's presentation findings re-checked by the close checks, not re-run; the claim states its scope
Claim (the working agent's sentence): #270 is built as its body asks (issue270.md): tools/rulecheck.py resolve --recheck RUNDIR --checks NAMES (rulecheck.py lines 1002-1084) resolves a VIOLATED run only on a close run directory whose full run of record passes tools/close_checks.py status, started after the run's verdict_real.txt was recorded, and holding every named check, and writes RECHECKED by RUNDIR into the ledger; tools/close_standing.py claim (lines 327-334) opens with a SCOPE sentence naming what the checks cover, what the readers are asked (the items after NOT TESTED) and that route. The RESOLVE RECHECK section of tests/test_rule_checker.sh (lines 294-330 and 447-450) accepts a good re-check and refuses one made before the verdict, one on a partial run, one naming an unknown check and one naming none; control recheck-unchecked FIRED in-gate and FAILs the gate as a mode, as does claim-unscoped in tests/test_close_standing.sh (gates.log). The rule is in docs/project/rule_checker.md [VSP-184] (line 246), STATE's close checklist step (6) and the skill's [VSP-184] line; STATE row (8) records the build. The ruling is the maintainer's "I agree with your proposals for C1, C2, C3, C4" (DECISIONS_HISTORY.md). NOT TESTED: which findings are presentation only is the working agent's reading — the re-check certifies that the named checks pass after the fix, not that they cover the finding, and the close's procedure check reads that choice; the verdict's record time is its file's mtime, which a fresh checkout resets to the checkout time (a re-check is then refused, never wrongly accepted); the ticket's done-when, this close's packet loop measured against 14z-196..198, is measured at this session's close, and #270 stays open until then; the full static tier has not run on this change, only the gates in gates.log.
Artifacts (read every one, in full):
  - build/agent199/t270/issue270.md
  - DECISIONS_HISTORY.md.lines-6637-6650 (lines 6637-6650 of DECISIONS_HISTORY.md)
  - tools/rulecheck.py.lines-1002-1084 (lines 1002-1084 of tools/rulecheck.py)
  - tests/test_rule_checker.sh.lines-290-330 (lines 290-330 of tests/test_rule_checker.sh)
  - tests/test_rule_checker.sh.lines-445-452 (lines 445-452 of tests/test_rule_checker.sh)
  - tests/test_rule_checker.sh.lines-510-522 (lines 510-522 of tests/test_rule_checker.sh)
  - tools/close_standing.py.lines-282-345 (lines 282-345 of tools/close_standing.py)
  - tools/close_standing.py.lines-410-435 (lines 410-435 of tools/close_standing.py)
  - tests/test_close_standing.sh.lines-20-32 (lines 20-32 of tests/test_close_standing.sh)
  - tools/close_checks.py.lines-1-130 (lines 1-130 of tools/close_checks.py)
  - build/agent199/t270/gates.sh
  - build/agent199/t270/gates.log
  - docs/project/rule_checker.md.lines-244-260 (lines 244-260 of docs/project/rule_checker.md)
  - STATE.md.lines-58-61 (lines 58-61 of STATE.md)
  - STATE.md.lines-89-89 (lines 89-89 of STATE.md)
