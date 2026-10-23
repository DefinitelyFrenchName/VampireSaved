THE PACKET

Decision kind: recommendation
Subject: #291 closed done: the S4-D span retrofit landed and the full sheet run reviewed (14z-207)
Claim (the working agent's sentence): #291 can close done when this session's commit lands (closing_comment.md): the tool it asks for is tools/proof_sheets.py run <tag|commit> (issue291.md), and the step the 2026-10-23 ruling kept it open for (rulings_291.txt: "Keep #291 open" until the 38 gates on the span debt list are retrofitted and a full sheet run shows it) is done. The span debt list is down to its header (sheet_span_debt.txt) and the census passes (census_main.txt); lanes A-E retrofitted the 38 gates, each reporting the gate's output identical with and without SHEET_OUT except MAME teardown PID lines in two gates (REPORT_A.md..REPORT_E.md); lane H fixed the fighters check on round intros (REPORT_H.md: on 288 pictures classed by eye, yes on 144 of the 144 showing a fighter, 48 before). The full run of the merged commit a9098ffa (run_summary.txt) has 58 gates PASS, the five tracks equal to the frozen references and 0 NOT THE JUDGED RUN; measure.txt and totals.txt give 483 sheets and 25,561 tiles (23,107 PROVEN, 2,299 EVENT-PROVEN, 155 JUDGED FILE), 9 tiles per event on the 38 retrofitted gates against 1 before (before_after.txt), a short stage below 9 kept as ruled (rulings_291.txt, "Keep as is (Recommended)"), and 12 gates below 9 by design, which the orchestrator listed to the maintainer with the question whether any should show 9, answered "all looks and sounds good" (maintainer_words.txt). The 2026-10-22 review ruling's done-when holds on this run: a Setup line on all 101 gate pages and the setup text on all 58 index rows (setup_census_full.txt, setup_index_full.txt), P1, P2 and the speed level on 462 of 483 sheets, 56 of 58 gate heads and 56 of 58 index rows (who_census_full.txt), the 21 sheets without being sheets where 0 of 340 pictures read fighters yes (who_nofighter_full.txt); the proof tally per gate is in tally_full.txt. Between the run's commit and the tree that lands, the tool, the sheet library, tests/lua/ and the 58 gates differ only by a comment block in audit_trap_air_hit.sh (sheet_files_unchanged.txt). Not tested: the run was not repeated on the commit that lands; the fighters read rests on the game-state check (tests/lua/screen_state.lua), scored by eye on 288 pictures by lane H, not on a look at each of the 25,561 tiles; 1,028 tiles read no fighters (measure.txt), most on screens with no fighters by nature, which the maintainer saw; the lanes' S2 logs for A-D sat in their worktrees and are cited from their reports.
Artifacts (read every one, in full):
  - build/agent207/t291/close/closing_comment.md
  - build/agent207/t291/close/issue291.md
  - build/agent207/t291/close/rulings_291.txt
  - build/agent207/t291/close/maintainer_words.txt
  - build/agent207/t291/close/sheet_span_debt.txt
  - build/agent207/t291/close/census_main.txt
  - build/agent207/t291/close/REPORT_A.md
  - build/agent207/t291/close/REPORT_B.md
  - build/agent207/t291/close/REPORT_C.md
  - build/agent207/t291/close/REPORT_D.md
  - build/agent207/t291/close/REPORT_E.md
  - build/agent207/t291/close/REPORT_H.md
  - build/agent207/t291/close/run_summary.txt
  - build/agent207/t291/close/measure.txt
  - build/agent207/t291/close/totals.txt
  - build/agent207/t291/close/before_after.txt
  - build/agent207/t291/close/setup_census_full.txt
  - build/agent207/t291/close/setup_index_full.txt
  - build/agent207/t291/close/who_census_full.txt
  - build/agent207/t291/close/who_nofighter_full.txt
  - build/agent207/t291/close/tally_full.txt
  - build/agent207/t291/close/sheet_files_unchanged.txt
