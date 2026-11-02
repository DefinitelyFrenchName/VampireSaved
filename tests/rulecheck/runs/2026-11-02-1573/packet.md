THE PACKET

Decision kind: recommendation
Subject: #355 closed done: tools/close.py red_base treats a red results file with no gate rows as no results, gated by close.py --selftest's new header-only case and its header-only-base control in tests/test_session_close.sh (14z-218)
Claim (the working agent's sentence): #355 can close done with the closing comment closing_355.md. The issue (issue355.md) reports that red_base() took a plan-refused tier's header-only results file as the re-run's base. The cause is in fix.diff and evidence355.txt C7/C7b: tests/run_all_static.sh writes its results header (lines 359-371) before the --confirm plan refusal exits 2 (line 384), so the file is newer than the log with no gate row. The fix (fix.diff): red_base returns None when read_tsv of the red results file is empty, so {PREV} stands; the selftest gains a plan-refused case and the perturb header-only-base; docs/project/session_close.md's tier row names the case. Reproduced on the real 14z-217 file (evidence355.txt C1 the old close.py: BASE, the bug; C2 the fixed one: None; C3: 0 gate rows). close.py --selftest passes and --perturb header-only-base fails only the new case (C4, C5). tests/test_session_close.sh plain PASS with 6 of 6 controls fired and all 6 control modes HONOURED, run under /bin/sh and classified as the runners classify (C6). NOT TESTED: a real close driven through a plan-refused tier; the case of a real red run followed by a plan-refused red run falls back to {PREV}, which the doc allows; the change is uncommitted until the 14z-218 commit, so the issue closes before the fix is on GitHub.
Artifacts (read every one, in full):
  - build/agent218/t355/close/issue355.md
  - build/agent218/t355/close/fix.diff
  - build/agent218/t355/close/evidence355.txt
  - build/agent218/t355/close/closing_355.md
