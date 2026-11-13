THE PACKET

Decision kind: recommendation
Subject: #371/#364: close both with design R's commit (the emulator runner reaps each gate's session and removes its TMPDIR), measured on every item the ruling listed NOT TESTED
Claim (the working agent's sentence): Close #371 and #364 with design R's commit. R as built (tests/lib/session_run.py on the emulator runner's four gate lines, tests/test_session_reap.sh) was run, before its commit, on each item the ruling's entry lists as to be measured: the other emulator gates' verdicts (the release-shape tier on PILOT and ERIS, the MiSTer lane on PILOT with TMPDIR set outside the repo, test_mame_parity on the Mac), CONTROL= runs, ERIS, the pooled lanes at --jobs 4 and 6 (pilot_r371.sh line 76, eris_r371.sh line 24), the two Linux desktop gates, the Verilator lane, real gates through R on the Mac, R's KILL step on planted TERM-ignoring and stopped cps2, and the on-demand scope (45 of its 46 rows, split between PILOT and ERIS, report_r.md item 11). Every gate verdict through R is a PASS or the same verdict the stock runner gives on that host (report_r.md items 7, 9 and 11; the parent re-runs in pilot/r371_report.txt § 7, eris/eris_r371_stream.txt § 2, od/pilot/waiter.txt § 2 and od/eris/stream.txt § 2). No cps2, Verilator sim or gate.* directory was left after any run through R (each run's own census, plus, for r371d, mac_ctl and mac_parity whose census did not count gate.*, a later census in census_after_all.txt taken after all runs had ended, so for those three it shows nothing was left by then, not at the moment each ended), while the stock runner left an orphan cps2 under a runner TERM, by group and by PID, and its on-demand re-runs on PILOT left a work directory (tmp.yXe0Laxd7T) in the TMPDIR, attributed to test_inp_corpus under audit_pool_drop from its time and layout only. What this does NOT rest on, and stays open as named limits: the 14z-225 case where a hand TERM left three cps2 alive was not reproduced (the orphans of a bare timeout ended on their own), so R's KILL step is shown only on planted processes; a child that starts a session of its own escapes the reap and no control plants one (the desktop gates' driver does this, so their clean census is the driver's, not R's); a TERM to the runner's PID alone is held until the gate's timeout, on the stock runner too, and why is not measured; tools/trace_controls.sh and the static runner's lanes do not go through R; manual runs are not wrapped, and under dash a killed EXIT-only gate can still leave its work directory; the Mac's bare mktemp -d ignores TMPDIR; the on-demand checks that read data kept outside the tree (the community workbook, the throw-recovery and guard-cancel tables) had no data on PILOT or ERIS, so their gates SKIP or FAIL there through R and on the parent alike and those checks were not exercised; the instrument audit_mask_window_ff42a2 is run only by hand and never went through R. The maintainer's own words are the choice "R, no lint (Recommended)"; the closure terms (#371 when R lands; #364 with the manual-kill case and the Mac's mktemp named as limits) are the text of the recommendation they chose, build/agent226/t364/recommendation.md, not their words. The deliverables are the measurement report and the two closing comments.
Artifacts (read every one, in full):
  - build/agent226/r371/report_r.md
  - build/agent226/r371/comment_371.md
  - build/agent226/r371/comment_364.md
  - build/agent226/r371/pilot/r371_report.txt
  - build/agent226/r371/pilot/r371b_report.txt
  - build/agent226/r371/pilot/r371c/report.txt
  - build/agent226/r371/pilot/r371d/report.txt
  - build/agent226/r371/pilot_r371.sh
  - build/agent226/r371/eris_r371.sh
  - build/agent226/r371/pilot_r371c.sh
  - build/agent226/r371/pilot_r371d.sh
  - build/agent226/r371/mister_fail_lines.txt
  - build/agent226/r371/census_after_all.txt
  - build/agent226/r371/mac_tmo/results.tsv
  - build/agent226/r371/mac_ctl/results.tsv
  - build/agent226/r371/mac_census_after.txt
  - build/agent226/r371/mac_parity/out.txt
  - build/agent226/r371/eris/eris_r371_stream.txt
  - build/agent226/r371/x/p/tier.out.lines-495-527 (lines 495-527 of build/agent226/r371/x/p/tier.out)
  - build/agent226/r371/x/e/tier.out.lines-490-518 (lines 490-518 of build/agent226/r371/x/e/tier.out)
  - build/agent226/tier1/tier.out.lines-585-613 (lines 585-613 of build/agent226/tier1/tier.out)
  - build/agent226/r371/issue_mister_tmp.md
  - build/agent226/r371/od_r371.sh
  - build/agent226/r371/od_all.txt
  - build/agent226/r371/od_pilot_half.txt
  - build/agent226/r371/od_eris_half.txt
  - build/agent226/r371/od/pilot/waiter.txt
  - build/agent226/r371/od/pilot/extra.txt
  - build/agent226/r371/od/eris/stream.txt
  - build/agent226/r371/od/pilot/x/tier.out.lines-100-171 (lines 100-171 of build/agent226/r371/od/pilot/x/tier.out)
  - build/agent226/r371/od/eris/x/tier.out.lines-140-160 (lines 140-160 of build/agent226/r371/od/eris/x/tier.out)
  - build/agent226/r371/od/pilot/x/tier/audit_guard_cancels.log
  - build/agent226/r371/od/pilot/x/par_audit_guard_cancels/audit_guard_cancels.log
  - build/agent226/r371/od/pilot/x/tier/audit_pool_drop.log
  - build/agent226/r371/od/pilot/x/par_audit_pool_drop/audit_pool_drop.log
  - build/agent226/r371/od/pilot/x/tier/audit_sdram_bank_load.log.lines-100-119 (lines 100-119 of build/agent226/r371/od/pilot/x/tier/audit_sdram_bank_load.log)
  - build/agent226/r371/od/eris/x/tier/audit_throw_recovery.log
  - build/agent226/r371/od/eris/x/par_audit_throw_recovery/audit_throw_recovery.log
  - build/agent226/r371/od/eris/x/tier/test_meter_gain.log
  - build/agent226/r371/od/eris/x/par_test_meter_gain/test_meter_gain.log
  - tests/test_inp_corpus.sh.lines-50-100 (lines 50-100 of tests/test_inp_corpus.sh)
  - tests/lib/session_run.py
  - tests/run_all_emulator.sh.lines-55-80 (lines 55-80 of tests/run_all_emulator.sh)
  - tests/run_all_emulator.sh.lines-420-490 (lines 420-490 of tests/run_all_emulator.sh)
  - tests/run_all_emulator.sh.lines-625-700 (lines 625-700 of tests/run_all_emulator.sh)
  - DECISIONS_HISTORY.md.lines-10119-10140 (lines 10119-10140 of DECISIONS_HISTORY.md: its INDEX entry "## Ruled 2026-11-11 (14z-226) — #364/#371: design R is built, without the lint", and the entries after it up to line 10140)
  - build/agent226/t364/recommendation.md
  - build/agent226/t364/issue_364.md
  - build/agent226/t364/issue_371.md
