THE PACKET

Decision kind: build
Subject: #268: test_close_tools cut back — re-check after run 946
Claim (the working agent's sentence): #268 is built on the maintainer's C1 ruling (DECISIONS_HISTORY.md lines 6637-6649: C1 as proposed in build/agent199/t1/report.md lines 161-166 — modes run only their section, one scan for all retraction files — plus "a scope limited to what a sitting touched"); putting the whole-tree scan at FREEZE cadence is the working agent's application of the same entry's turned-around static tier ("freeze and release run everything"), to be told to the maintainer, not a ruling of its own. Built: tests/test_close_tools.sh no longer scans the whole tree once per retraction file. At every tier its section 1 judges every retraction file's GONE wordings on the files the sitting touched in ONE scan (tools/retraction_grep.py --touched LIST --each), sound for an unchanged pattern file because the matcher judges each file's text alone (tools/retraction_grep.py judge: a pattern is searched in one file's normalised text at a time); a pattern file the sitting CHANGED (in the touched list: a new one, or an old one with a new wording) is judged on the WHOLE tree, reach and gone, since its new wordings were never scanned (control gone-new-untouched, in-gate on a two-file stand-in for the tree via RETRACTION_GREP_UNIVERSE, its mode on the real tree). The whole-tree check of every file moved to a new gate, tests/test_retraction_reach.sh, FREEZE cadence (tests/ci_cadence.tsv), one scan for all twenty files with its three controls judged in that same scan. Each mode of test_close_tools runs only the section its control perturbs (out/modes.txt: sections=1 for every mode). Measured on this Mac, one run each: the session gate 10 s (out/close_tools_run.txt) against 565 s before (build/agent199/t1/out/close_tools_time.txt); its nine modes 0-29 s each (out/modes.txt) against 482-495 s for eight of the ten at the 14z-198 close (build/agent199/t1/out/close_tools_controls_14z198.tsv); the freeze gate 36 s (out/retraction_reach_run.txt) and each of its three modes 28-29 s; one scan of all twenty files 28 s (out/each_run.txt). Every control fires in-gate, every mode reaches its gate's own FAIL on its plant's text, and an undeclared mode is REFUSED (out/modes.txt). The refactored tool's single-file output is byte-identical to the pre-#268 tool's (git show 05761ce5) for two pattern files (out/single_identical.txt), and its one-scan verdicts equal the old tool's per-file verdicts for all twenty files (out/per_file_old.txt against out/each_run.txt). The scanned set was NOT narrowed: data directories carry 11 of 729 hit-files, 10 of them reach-control hits under tests/expected (out/data_hits.txt); the two patterns repeated across files were left, each file being one sitting's record (out/patterns_audit.txt, from make_out2.sh). NOT TESTED: the static tier has not run on this change, only the ten registry and documentation gates in out/gates/ (run before the gone-new-untouched change); the gate builds its touched list like the runner's cad_changed (out/runner_cad_changed.txt: STATIC_CHANGED_PATHS, else git diff against origin/main) but lists untracked files under the scan's roots one by one (git ls-files --others) where the runner takes git status's names, and the override was tried with one path only (out/override_run.txt); a stale or missing origin/main ref, an edit made after a sitting's last session tier and pushed with it, or a run inside a snapshot clone (whose origin/main is the source tree's own branch) leaves gone wordings in those files unjudged until the next freeze; between freezes a reach control of an earlier, UNCHANGED pattern file whose carrier is lost is caught only at the freeze, the sitting's own file being run on the whole tree by the close's standing check `retraction_grep` (out/standing_retraction_row.txt) and by section 1 when it is in the touched list; the timings are single runs under whatever load the machine carried; the planted gone wording of both section-1 controls is taken from the gate's own header, so they prove the scans judge a listed file and route a changed pattern file whole, not that the git-derived list is complete; RETRACTION_GREP_UNIVERSE, a test harness's stand-in for the tree, is unset by both gates before their real runs, but a caller that sets it narrows the scan, which the scan's header then says (RESTRICTED).
Artifacts (read every one, in full):
  - build/agent199/t268/out/close_tools_run.txt
  - build/agent199/t268/out/retraction_reach_run.txt
  - build/agent199/t268/out/modes.txt
  - build/agent199/t268/out/single_identical.txt
  - build/agent199/t268/out/per_file_old.txt
  - build/agent199/t268/out/each_run.txt
  - build/agent199/t268/out/data_hits.txt
  - build/agent199/t268/out/patterns_audit.txt
  - build/agent199/t268/out/override_run.txt
  - build/agent199/t268/out/nobase_run.txt
  - build/agent199/t268/out/gates/summary.txt
  - build/agent199/t268/out/diff.txt
  - build/agent199/t268/make_out.sh
  - build/agent199/t268/data_hits.py
  - build/agent199/t268/fallbacks.sh
  - build/agent199/t1/out/close_tools_time.txt
  - build/agent199/t1/out/close_tools_controls_14z198.tsv
  - build/agent199/t268/out/standing_retraction_row.txt
  - build/agent199/t268/out/runner_cad_changed.txt
  - build/agent199/t268/make_out2.sh
  - DECISIONS_HISTORY.md.lines-6637-6649 (lines 6637-6649 of DECISIONS_HISTORY.md)
  - build/agent199/t1/report.md.lines-161-166 (lines 161-166 of build/agent199/t1/report.md)
  - tests/test_close_tools.sh
  - tests/test_retraction_reach.sh
  - tools/retraction_grep.py
  - tests/ci_cadence.tsv
