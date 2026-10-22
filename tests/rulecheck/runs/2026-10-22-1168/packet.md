THE PACKET

Decision kind: recommendation
Subject: land #286's landing.diff: 14z-203's narrowings N-I, N-J, N-F rebased, plus N-F-LINK, after PILOT's trace score (after run 1167)
Claim (the working agent's sentence): #286's landing.diff can land on a8fa5350 (it touches only tools/static_confirm.py and tests/test_static_confirm.sh): it holds 14z-203's three narrowings (N-I, N-J, N-F), rebased, plus N-F-LINK (a run record named by its whole path in a data file of the reach is still a change for a gate that reads no run records), and #225's precondition, a trace of every gate scoring 0 misses, holds: on PILOT, 14z-205c's traces of b91532d8 (229 of 229 gates, 88,351 gate-read pairs) score MISSES 0 under the narrowed + N-F-LINK predictor (sha1 da2593e4, which equals landing.diff applied to a8fa5350), MISSES 1 (test_tickets reading tests/rulecheck/runs/2026-09-17-22/verdict_real.txt) under the committed predictor and under the narrowed one without N-F-LINK, and the scorer's over-narrowed control fires (103 misses); in a scratch worktree at a8fa5350 with landing.diff applied (each log's header names the HEAD, the diff stat and the sha1s), test_static_confirm PASSES with 32 controls fired and none dead and test_trace_static_reads PASSES with 6 fired, and the four new control modes (runs-link-off, runs-link-basename, no-data-rule, runs-change-off) each FAIL as a mode on that tree, each on its own case; on a clean checkout of a8fa5350, the narrowed predictor against the commit's differs on five of nine change sets (state_only, run_record_verdict, run_manifest, scratch_only, gitignore), by the gates listed in predict_cmp.txt (it drops test_py_escapes, test_shell_portability and test_charid_names, and adds test_tickets, test_state_open_lists and test_promise_check through N-F-LINK and test_close_checks and test_freeze_bytediff on .gitignore), and #298's R1 rule is untouched (the diff leaves r1[g] = any(c in rch for c in eff) unchanged). NOT tested: a fresh trace of a8fa5350 (the score used b91532d8's traces with the landing tools laid over that tree); reads a trace cannot see (reads through git, and reads a gate makes only on a branch the traced run did not take); the reads of the four gates that exited non-zero under the trace (test_applier_page_browser, test_applier_page, test_emulator_staleness, test_release_roundtrip), which may be short, so a read they make past their failure point is unscored; the static tier on the landed tree; #286's done-when itself, which this landing does not claim.
Artifacts (read every one, in full):
  - build/agent206/t286/landing.diff
  - build/agent206/t286/REPORT.md
  - build/agent206/t286/issue_286.txt
  - build/agent206/remote/pilot/REPORT.md
  - build/agent206/remote/pilot/logs/out/committed.log
  - build/agent206/remote/pilot/logs/out/narrowed.log
  - build/agent206/remote/pilot/logs/out/nolink.log
  - build/agent206/remote/pilot/logs/out/control.log
  - build/agent206/t286/land/static_confirm.log
  - build/agent206/t286/land/trace.log
  - build/agent206/t286/land/predict_cmp.txt
  - build/agent206/t286/land/mode_runs-link-off.log
  - build/agent206/t286/land/mode_runs-link-basename.log
  - build/agent206/t286/land/mode_no-data-rule.log
  - build/agent206/t286/land/mode_runs-change-off.log
  - build/agent206/t286/link_census.out
  - build/agent206/t286/synth_tickets.out
  - tools/static_confirm.py.lines-560-600 (lines 560-600 of tools/static_confirm.py)
  - DECISIONS_HISTORY.md.lines-7302-7309 (lines 7302-7309 of DECISIONS_HISTORY.md: its INDEX entry "## Ruled 2026-10-18 (14z-205) — the static tier's scope: six families to freeze cadence (#297), cont")
