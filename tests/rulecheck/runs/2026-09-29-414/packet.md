THE PACKET

Decision kind: recommendation
Subject: 14z-185 close: the documentation packet — the findings table (row 14) and the close checklist steps 2-5 (re-checked after 406)
Claim (the working agent's sentence): Record the 14z-185 documentation as complete: STATE row (14), THE FINDINGS TABLE (row14.txt), and the close checklist's steps 2-5 as the CLOSE row states them (close_row.txt).
(1) The table lists 23 findings (a)-(w). Each has a live home, and each has a test or an explicit "none" with the reason. home_texts.py reads each finding's home clause from the row itself and finds every quoted text in its named file (runs/home_texts.out: 23 findings, 27 pairs, 25 texts, 0 failures). Its two plants, a mistyped text and a missing file, each exit 1.
(2) close_findings.py 14z-185 exits 0: GAPS none, PROMISES none. Its two REVIEW addresses are finding (a)'s guard-cancel commit routines, first homed by this sitting's commit f17fa818 before the tool's base 18248b6a (evidence.txt section 3). homes_tracked.py exits 0.
retraction_grep.py also exits 0, but its exit gates only the reach and gone patterns, not a retracted wording's live hits. So every hit is classed by retraction_classes.py (runs/retraction_classes.out): 28 occurrences, ARCHIVE 8, MARKED 13, SCOPED-TRUE 1, SESSION 3, SITE 3, UNMARKED 0. Its two plants each exit 1, and the three wordings added at this close for the false "--stale re-runs it" claim have 0 hits.
tests/test_state_open_lists.sh PASSes. Every check and plant is run by run_checks.sh, which writes each exit code to runs/exits.tsv: 15 runs, 0 not as expected.
(3) Pointers are set on 14z-184 row (8) and on this sitting's rows (2), (5), (6) and (9) (pointers.txt).
(4) The tool lists no promises. The 14z-184 opener's two re-run promises are met gate by gate (evidence.txt section 4). Every gate whose FOLLOWS names a comment-edited file ran in the M21 battery: it passed, or it was a battery red that was re-frozen and verified PASS. The exception is audit_wide_phase_a (scope out), which was run at this close: PHASE A COMPLETE, 4 DECISION lines, exit 0, with 8 tolerated teardown segfaults. The 14z-183 close's three edited headers are covered the same way.
(5) ON TRIAL: five quoted scratch scripts, three promoted.
- tools/battery_reach.py is byte-identical across two hash seeds. Its 7 non-via lines that differ from the scratch run are each explained by a measured tree change (promotion_equivalence.txt).
- tools/attr_placement_moves.py and tools/patch_site_read.py differ from their scratch outputs by 0 lines.
- The equivalence run's exit 1 is the two NON-ADDRESS pairs, by design (evidence.txt section 6).
RUN 341 was abandoned before any reader: it has no ledger row and no directory (evidence.txt section 1).
THE ORDERINGS: runs 374/375 and 399/400 were each a refused combined-label resolve, chained, that let the next prepare run first. Both are shown from the session transcript (ordering_374_375.txt; evidence.txt section 2), and the rule is recorded in docs/project/rule_checker.md.
THE MISTER RE-RUN on commit 28555610 is GREEN, PASS 3 (close_row.txt).
THE RULINGS recorded are quoted in the maintainer's own words (evidence.txt section 5).
NEXT_SESSION is rewritten (NEXT_SESSION.md), with the maintainer's new queue quoted verbatim.
NOT TESTED:
- That the table is COMPLETE: that no finding of the sitting is missing. The tools check the homes of the findings listed, not the findings not listed, and close_findings.py sees addresses, not findings.
- The close's static tier, sweep, procedure-check part 8 and worker cap, which follow this check.
- Whether each quoted home text states its finding correctly (the check is text presence).
Artifacts (read every one, in full):
  - build/agent185/close/row14.txt
  - build/agent185/close/close_row.txt
  - build/agent185/close/pointers.txt
  - build/agent185/close/promotion_equivalence.txt
  - build/agent185/close/ordering_374_375.txt
  - build/agent185/close/evidence.txt
  - build/agent185/close/evidence.sh
  - build/agent185/close/home_texts.py
  - build/agent185/close/retraction_classes.py
  - build/agent185/close/run_checks.sh
  - build/agent185/close/runs/exits.tsv
  - build/agent185/close/runs/home_texts.out
  - build/agent185/close/runs/close_findings.out
  - build/agent185/close/runs/homes_tracked.out
  - build/agent185/close/runs/retraction_grep.out
  - build/agent185/close/runs/retraction_classes.out
  - build/agent185/close/runs/state_open_lists.out
  - build/agent185/close/runs/attr_placement_plant.out
  - build/agent185/close/runs/home_texts_plant.out
  - build/agent185/close/audit_wide_phase_a.log
  - docs/NEXT_SESSION.md
