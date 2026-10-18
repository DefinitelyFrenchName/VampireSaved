THE PACKET

Decision kind: recommendation
Subject: close #293 as done, after run 1126 (14z-205)
Claim (the working agent's sentence): #293's two gates now run each leg on a fresh sandbox and pass: audit_flicker_attribution keys its sandboxes per case and checks each vanilla leg against the frozen basis (control shared-sandbox fires in-gate and FAILs as a mode); audit_legacy_pairings sweeps each distinct build once, writes each tenant id's control to its own file, checks that the control loads that id (a plant refused), and refuses any leg whose sandbox already exists through an atomic mkdir (control shared-sandbox fires in-gate and FAILs as a mode, its row added to tests/expected/must_fire_census.tsv); both re-ran with their sheets fully proven (18 of 18, 220 of 220) and outputs identical, and on fresh boots 7 pairings verdicts moved TENANT to LEGACY, each already carrying a .masked. NOT TESTED: no census of other gates that hand one sandbox to several runs; the sheets do not draw the pairings control legs; the pairings gate's runtime was measured twice; the fix does not re-run the legacy oracle itself.
Artifacts (read every one, in full):
  - build/agent205/t293/closing_comment.md
  - build/agent205/t293/flicker.diff
  - build/agent205/t293/pairings.diff
  - build/agent205/t293/must_fire_census.diff
  - build/agent205/t293/flicker_plain.log
  - build/agent205/t293/flicker_ctl_shared_sandbox.log
  - build/agent205/t293/flicker_check.log
  - build/agent205/t293/pairings_plain.log
  - build/agent205/t293/pairings_ctl_shared_sandbox.log
  - build/agent205/t293/pairings_check.log
  - build/agent205/t293/lp_verdicts_before_after.txt
  - build/agent205/s2/ticket_sandbox.md
  - docs/project/tickets.tsv.lines-74-74 (lines 74-74 of docs/project/tickets.tsv)
  - tools/proof_sheets.py.lines-226-245 (lines 226-245 of tools/proof_sheets.py)
