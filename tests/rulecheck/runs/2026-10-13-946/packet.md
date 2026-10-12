THE PACKET

Decision kind: build
Subject: #268: test_close_tools cut back — a touched scan of gone wordings at every tier, the whole-tree retraction scan once per freeze in a new gate, modes scoped to their section
Claim (the working agent's sentence): #268 is built as ruled: tests/test_close_tools.sh no longer scans the whole tree once per retraction file; at every tier its section 1 judges every retraction file's GONE wordings on the files the sitting touched in ONE scan (tools/retraction_grep.py --touched LIST --each), and the whole-tree check of every file's reach controls and gone wordings moved to a new gate, tests/test_retraction_reach.sh, at FREEZE cadence (tests/ci_cadence.tsv), one scan for all twenty files with its three controls judged in that same scan. Each mode of test_close_tools now runs only the section its control perturbs (out/modes.txt: sections=1 for every mode). Measured on this Mac, one run each: the session gate 12 s (out/close_tools_run.txt) against 565 s before (build/agent199/t1/out/close_tools_time.txt); its eight modes 0-10 s each (out/modes.txt) against 482-495 s for eight of the ten at the 14z-198 close (build/agent199/t1/out/close_tools_controls_14z198.tsv); the freeze gate about 35 s and each of its three modes 28-29 s; one scan of all twenty files 28 s (out/each_run.txt). Every control fires in-gate, every mode reaches its gate's own FAIL on its plant's text, and an undeclared mode is REFUSED. The refactored tool's single-file output is byte-identical to the pre-#268 tool's (git show 05761ce5) for two pattern files (out/single_identical.txt), and its one-scan verdicts equal the old tool's per-file verdicts for all twenty files (out/per_file_old.txt against out/each_run.txt). The scanned set was NOT narrowed: data directories carry 11 of 729 hit-files, 10 of them reach-control hits under tests/expected (out/data_hits.txt); the two patterns repeated across files were left, each file being one sitting's record (out/patterns_audit.txt). NOT TESTED: the static tier has not run on this change, only the ten registry and documentation gates in out/gates/; the touched list is the static runner's own (STATIC_CHANGED_PATHS, else git diff against origin/main plus the untracked files under the scan's roots), so a stale or missing origin/main ref, an edit made after a sitting's last session tier and pushed with it, or a run inside a snapshot clone (whose origin/main is the source tree's own branch) leaves gone wordings in those files unjudged until the next freeze; between freezes a reach control of an EARLIER sitting whose carrier is lost is caught only at the freeze (the close's standing check still runs the sitting's own file on the whole tree); the timings are single runs under whatever load the machine carried; the planted gone wording of the gone-touched control is one taken from the gate's own header, so the control proves the touched scan judges a listed file, not that the git-derived list is complete.
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
  - tests/test_close_tools.sh
  - tests/test_retraction_reach.sh
  - tools/retraction_grep.py
  - tests/ci_cadence.tsv
