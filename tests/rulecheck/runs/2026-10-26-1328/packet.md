THE PACKET

Decision kind: recommendation
Subject: #244, #305, #306, #321 and #323 closed done at this session's close (14z-209)
Claim (the working agent's sentence): CLAIM: close #244, #305, #306, #321 and #323 as done, each with the closing comment drafted in build/agent209/closing/<N>.md, their index rows set to done with the four answers, the issues closed on GitHub at this session's close, and the code landing in that close's commit. #244: the tenant charmap pages print the power class with the raw byte and nostat/nokill named when bit 5 or 7 is set, as ruled ("Class + flags (Recommended)") — settled through rule-checker runs 2026-10-26-1320 to -1323 (the last resolved in writing per the 14z-163 rule); its evidence: build/agent209/t244/v3/verify_cells.out (both cell functions = an oracle written from the ruling, 256/256 bytes, mutant controls fired), v3/verify_rows.out (865 rows, 0 mismatches), v4/pages_before_after.txt (html: label change only), v4/html_inputs.out; what went wrong is a new gotcha (docs/project/gotchas.md 7664-). #305, #306, #321, #323: fork E's #321 phase 2, as the maintainer ruled (DECISIONS_HISTORY.md 8323-8340: all four speed-ups; "Parity only on the Mac (Recommended)"; #305 "Yes, with #306 (Recommended)"), applied to the main tree; fork E's report saved verbatim (build/agent209/t321e/REPORT_handback.md); the ERIS freeze-shape tier in one pass without --keep-going, 4,364 s against 8,784 s, 181 of 181 shared rows with the freeze's verdict (t321e/compare_tier.txt); parity at 8 jobs on the Mac, 121 output lines identical to the serial freeze log, A/B section included (t321e/parity_compare.txt); test_emulator_runner PASS with its controls fired, lane-var-shared (#323) and decrypt-warm-off (#305) among them (t321e/test_emulator_runner.log); #306: before its change the nine consumers FAIL on a clean PILOT clone, after it they PASS, one (test_don_accent) first failing on a cold build/out — the #305 class, PASS once the views exist (build/agent209/t306/pilot/summary.txt, run_after_test_don_accent/test_don_accent.log); #323's cause and lesson are a gotcha (docs/project/gotchas.md 7653-). NOT TESTED: the job formulas on hosts but ERIS; --jobs 12; a release run with --controls; the test_mame_wide variable rename beyond one Mac replay; one run combining every check; the runner tests and these gates on the main tree as it now stands (fork E ran them in its worktree; #327's change to test_static_runner.sh and the #229 work came after) — the close's strict static tier runs the static ones on the staged tree, and the emulator-tier ones are not re-run before the commit; two stale build defaults of #306's kind outside its scope (tests/audit_trap_sound.sh build/hui30, tests/test_shim_charid.sh build/m5_wide) — closed means nothing left to do, so they go to a new ticket filed at the close, linked from #306's comment. No gameplay conclusion is drawn.
Artifacts (read every one, in full):
  - build/agent209/closing/244.md
  - build/agent209/closing/305.md
  - build/agent209/closing/306.md
  - build/agent209/closing/321.md
  - build/agent209/closing/323.md
  - build/agent209/t244/v3/verify_cells.out
  - build/agent209/t244/v3/verify_rows.out
  - build/agent209/t244/v4/pages_before_after.txt
  - build/agent209/t244/v4/html_inputs.out
  - build/agent209/t321e/REPORT_handback.md
  - build/agent209/t321e/compare_tier.txt
  - build/agent209/t321e/parity_compare.txt
  - build/agent209/t321e/test_emulator_runner.log
  - build/agent209/t306/pilot/summary.txt
  - build/agent209/t306/pilot/run_after_test_don_accent/test_don_accent.log
  - build/agent209/t306/pilot/run_after2_test_don_accent/test_don_accent.log
  - DECISIONS_HISTORY.md.lines-8323-8340 (lines 8323-8340 of DECISIONS_HISTORY.md: its INDEX entry "## Ruled 2026-10-26 (14z-209) — #321 phase 2: all four speed-ups, parity on the Mac only, #305 with ")
  - DECISIONS_HISTORY.md.lines-8296-8303 (lines 8296-8303 of DECISIONS_HISTORY.md: its INDEX entry "## Ruled 2026-10-25 (14z-209) — #244: the tenant charmap pages show the power class, with the raw by")
  - docs/project/gotchas.md.lines-7653-7674 (lines 7653-7674 of docs/project/gotchas.md)
