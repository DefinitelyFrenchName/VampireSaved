THE PACKET

Decision kind: recommendation
Subject: close #341 as done (14z-215), after run 2026-10-31-1465: parked-disagrees takes the first open or parked row of an OPEN saved issue and says NOT JUDGED when none qualifies; run in clean worktrees over three index states and re-traced on PILOT
Claim (the working agent's sentence): CLAIM: close #341 as done (14z-215), after run 2026-10-31-1465. The closing comment closing_comment.md and the row ticket_row_341.tsv state the resolution. The ticket (issue_341.md) reported that test_tickets' control parked-disagrees was judged DEAD at the 14z-214 close's first tier, because every perturbation edits the copy's first ticket row and, once the newest ticket (#340) closed, the flip wrote `open` over a closed issue. It rests on:
1. THE FIX IN TWO STEPS: fix.diff (550958ad..b68922a6: the first open or parked row) and fix2.diff (the working-tree change on b68922a6: the first open or parked row whose saved issue in tickets_github.tsv is OPEN; with none, `NOT JUDGED:` then FAIL exit 1; any other python exit still `no such perturbation`, exit 3). The other six perturbations still take the first row.
2. BEFORE: red_and_green_rows.txt (the 14z-214 red tier row `test_tickets FAIL`, its runner log lines); the DEAD line's text rests on the issue body only.
3. AFTER, in CLEAN worktrees of b68922a6 with only the fixed gate copied in (no STATE.md edit; each case prints git status): sim341.sh and sim341.out with the per-case logs — A the index as is: plain PASS 7 fired, the mode FAILs on #341 written parked; B every open row (#341 #338 #310 #118) done with its saved issue CLOSED: plain PASS 7 fired, the mode FAILs on #294 written open (the parked-to-open branch); C every open and parked row closed: plain FAIL with the NOT JUDGED line, the mode the same, classified UNJUDGED by tests/lib/classify.sh; Cold the b68922a6 gate on C's state: exit 3, StopIteration, classified DIED.
4. PILOT: pilot_t215a/ (fresh clone of scratch commit 3ccc77fd = b68922a6 plus fix2.diff, sh is dash, blob e5009c0a, the gate PASS exit 0; 7 controls traced, SAFE; each control log classified HONOURED in classes.tsv, classified on the Mac from the logs copied back) and controls_concurrent.diff (the row re-pointed to blob e5009c0a, pilot:3ccc77fd).
5. WHAT WAS LEARNED / WENT WRONG: gotcha.diff (the updated docs/project/gotchas.md entry the row cites) and run1465_verdict_real.txt (what the first packet missed).
NOT TESTED: the real row carries sessions 14z-214,14z-215; STATE.md now holds a 14z-215 group (written this sitting), but test_tickets was not re-run on the main tree with the row changed — that run is the closure commit's tier. The other six perturbations were run only in states A, B and C, not with the first row in each possible state. The red run's DEAD line is not on disk. In case C the six other controls were not reached (the NOT JUDGED exit stops the gate, by design). Case B and C's closed rows have hand-filled learned/wrong columns so the index check passes; those values are scaffolding, not answers.
Artifacts (read every one, in full):
  - build/agent215/t341/closure/closing_comment.md
  - build/agent215/t341/closure/ticket_row_341.tsv
  - build/agent215/t341/closure/issue_341.md
  - build/agent215/t341/closure/fix.diff
  - build/agent215/t341/recheck/fix2.diff
  - build/agent215/t341/closure/red_and_green_rows.txt
  - build/agent215/t341/recheck/sim341.sh
  - build/agent215/t341/recheck/sim341.out
  - build/agent215/t341/recheck/A_tree_as_is.mode.log
  - build/agent215/t341/recheck/B_every_open_closed.mode.log
  - build/agent215/t341/recheck/C_no_open_issue.plain.log
  - build/agent215/t341/recheck/C_no_open_issue.mode.log
  - build/agent215/t341/recheck/Cold_no_open_issue_b68922a6_gate.mode.log
  - build/agent215/pilot_t215a/retrace_head.txt
  - build/agent215/pilot_t215a/tt.log
  - build/agent215/pilot_t215a/overlap.txt
  - build/agent215/pilot_t215a/classes.tsv
  - build/agent215/t341/recheck/controls_concurrent.diff
  - build/agent215/t341/recheck/gotcha.diff
  - build/agent215/t341/recheck/run1465_verdict_real.txt
