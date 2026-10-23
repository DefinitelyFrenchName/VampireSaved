THE PACKET

Decision kind: recommendation
Subject: #291 closed done: tools/proof_sheets.py run, S4-G on 7b663645 shown to the maintainer, the qs_voice variant fixed in e5d6f445 (14z-206)
Claim (the working agent's sentence): #291 can close done: the on-demand tool it asks for is tools/proof_sheets.py run <tag|commit>, and the S4 plan's last step is met: S4-G, the full run on the Mac, was run on 7b663645 and shown to the maintainer before this closure, and the maintainer's answer was "pages are looking good" (maintainer_words.txt). In S4-G (s4g_run_7b663645.log) all 58 drawing gates PASS and all five tracks equal the commit's frozen references; tally.py over each gate's proof.json gives PROVEN 15,720, EVENT-PROVEN 2,863, JUDGED FILE 81 and NOT THE JUDGED RUN 74 (tally_7b663645.txt). The 2026-10-22 review ruling's done-when (dh_s4g_reviewed.txt) is met on those pages: a Setup line on each of the 87 gate pages and all 58 on the index, and P1/P2 named on 82 pages (who_setup_census.txt). The 74 were all audit_qs_voice_wav's ours clips, refused as outside the clean checkout's build/. e5d6f445 declares that gate's romset a gate-built variant and fixes its supplied-build ledger (qs_variant_commit.diff); that gate's sheet re-run on e5d6f445 PASSes with 148 JUDGED FILE and 0 NOT THE JUDGED RUN, the variant built in the checkout (qs_sheet_e5d6f445.log, tally_e5d6f445_qs.txt). On e5d6f445, test_proof_sheets PASSes with 15 controls FIRED (test_proof_sheets.log) and test_sheet_census PASSes, 58 legs and 0 on the debt list (test_sheet_census.log); both now run on demand only, as the maintainer ruled (ondemand_commit.diff). Not tested: the whole 58-gate run was not repeated on e5d6f445, only audit_qs_voice_wav. Of the other files that commit changes, the tool reads tests/ci_emulator.tsv (only test_proof_sheets' row differs, a gate that draws no sheet: registry_rows_diff.txt), tests/run_all_emulator.sh (header comments only: run_all_emulator_commit.diff) and docs/project/tickets.tsv (the #313 row) (tool_reads_changed.txt). The 5 pages that name no P1/P2 are no-fighter subjects by their gates, not checked picture by picture.
Artifacts (read every one, in full):
  - build/agent206/t291/close/closing_comment.md
  - build/agent206/t291/close/claim.txt
  - build/agent206/t291/close/maintainer_words.txt
  - build/agent206/t291/close/issue291.txt
  - build/agent206/t291/close/PLAN.md
  - build/agent206/t291/close/dh_s4_plan.txt
  - build/agent206/t291/close/dh_s4g_reviewed.txt
  - build/agent206/t291/close/s4g_run_7b663645.log
  - build/agent206/t291/close/tally.py
  - build/agent206/t291/close/tally_7b663645.txt
  - build/agent206/t291/close/who_setup_census.txt
  - build/agent206/t291/close/qs_variant_commit.diff
  - build/agent206/t291/close/qs_sheet_e5d6f445.log
  - build/agent206/t291/close/tally_e5d6f445_qs.txt
  - build/agent206/t291/close/test_proof_sheets.log
  - build/agent206/t291/close/test_sheet_census.log
  - build/agent206/t291/close/ondemand_commit.diff
  - build/agent206/t291/close/registry_rows_diff.txt
  - build/agent206/t291/close/run_all_emulator_commit.diff
  - build/agent206/t291/close/tool_reads_changed.txt
  - build/agent206/t291/close/head.txt
