THE PACKET

Decision kind: recommendation
Subject: close #341 as done (14z-215): test_tickets' parked-disagrees takes the first open or parked row, so closing the newest ticket no longer kills it; measured at b68922a6 and on a simulated post-closure tree; the class recorded as a gotcha
Claim (the working agent's sentence): CLAIM: close #341 as done (14z-215). The closing comment closing_comment.md and the row ticket_row_341.tsv state the resolution. The ticket (issue_341.md) reported that test_tickets' control parked-disagrees was judged DEAD at the 14z-214 close's first tier because every perturbation edits the copy's first ticket row and, once the newest ticket (#340) closed, the flip wrote `open` over a closed issue. It rests on:
1. THE FIX: fix.diff (550958ad..b68922a6, tests/test_tickets.sh only): parked-disagrees takes the first row whose status is open or parked; the other six perturbations still take the first row.
2. BEFORE: red_and_green_rows.txt — the 14z-214 close's red tier row `test_tickets FAIL` and its runner log lines (FAIL, exit 1); the DEAD line's text rests on the issue body only (the full log was overwritten).
3. AFTER: red_and_green_rows.txt (the 14z-214 re-run's row `test_tickets PASS 35 7 7 7`); pilot_t214c/ (PILOT, HEAD 88dc1968, sh is dash, blob 35fa3921, the gate PASS exit 0, 7 controls HONOURED) and controls_concurrent_rows.txt (the pilot:88dc1968 row, SAFE); at b68922a6 on the Mac (a measurer's commands; each log opens with identity_14z215.txt: HEAD b68922a6, gate blob 35fa3921 at HEAD and in the worktree, tracked changes STATE.md, docs/NEXT_SESSION.md and the emu/fbneo submodule, none read by the gate's control path): test_tickets.head.log (PASS, 7 CONTROL FIRED, 0 CONTROL DEAD, exit 0) and test_tickets.control_parked.head.log (the mode FAILs on `#341: status parked but the issue is not labelled parked on GitHub`, exit 1).
4. AFTER THE CLOSURE ITSELF, simulated: after_closure_sim.log and row_change.diff — a scratch worktree of b68922a6 with #341's row set done (learned and wrong = the gotcha; sessions 14z-214 only, because 14z-215 has no STATE record yet), the saved issue list's #341 row set CLOSED, the page regenerated: the plain run PASS with 7 controls fired; the mode FAILs on #338 written parked.
5. WHAT WAS LEARNED / WENT WRONG: gotcha_341.md, the docs/project/gotchas.md entry the row's learned and wrong columns cite.
NOT TESTED: the real row will carry sessions 14z-214,14z-215, which test_tickets accepts only once STATE.md holds a 14z-215 group (written in the same change as the row); the simulation used 14z-214 alone. The other six perturbations were not re-run with the first row in each possible state. The red run's DEAD line is not on disk. The PILOT re-trace ran on the 14z-214 staged tree plus the fix (88dc1968), not on b68922a6; equality rests on the gate's blob 35fa3921.
Artifacts (read every one, in full):
  - build/agent215/t341/closure/closing_comment.md
  - build/agent215/t341/closure/ticket_row_341.tsv
  - build/agent215/t341/closure/issue_341.md
  - build/agent215/t341/closure/fix.diff
  - build/agent215/t341/closure/red_and_green_rows.txt
  - build/agent215/t341/closure/identity_14z215.txt
  - build/agent215/t341/closure/test_tickets.head.log
  - build/agent215/t341/closure/test_tickets.control_parked.head.log
  - build/agent215/t341/closure/after_closure_sim.log
  - build/agent215/t341/closure/row_change.diff
  - build/agent215/t341/closure/pilot_t214c/retrace_head.txt
  - build/agent215/t341/closure/pilot_t214c/tt.log
  - build/agent215/t341/closure/pilot_t214c/classes.tsv
  - build/agent215/t341/closure/controls_concurrent_rows.txt
  - build/agent215/t341/closure/gotcha_341.md
