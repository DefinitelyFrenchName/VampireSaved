THE PACKET

Decision kind: recommendation
Subject: #362 closed done: the crash sweep's perturbed copies live outside tests/ with REPO pinned, and test_gate_descriptions refuses a perturbation that changes nothing; reproduced by a planted file, re-traced SAFE on PILOT, tier GREEN (14z-221)
Claim (the working agent's sentence): #362 can close done with closing_362.md and its row ticket_row_362.tsv. The issue (issue362.md) has two defects: test_crash_sweep wrote its perturbed copies into the live tests/, and test_gate_descriptions' modes did not refuse a vanished target. The fix (fix.diff, committed in d3e8810d) pins each copy's REPO line to CS_REPO and writes the copies under the sweep's scratch directory (refusing one inside tests/), and makes perturb pick its target from the copy and refuse an unchanged file (UNCHANGED), with a new section 3 that proves the refusal fires. Measured by measurer workers: with a planted tests/.cs_aaa_plant.sh both modes exit 0 (LIES) before the fix and exit 1 after it (measurer_repro.txt); on PILOT at bb407777, 26 control runs of the three gates run at once, each exit 1, scored 3 SAFE, 0 SHARED, 0 HOLLOW, and the three plain runs PASS (measurer_pilot.txt, pilot_t362.sh); the traced blobs equal the committed scripts and the list's rows (blobs_committed.txt, controls_concurrent.diff). The strict static tier on the committed tree: first run red only on test_tickets, the confirm run GREEN, PASS 110 (tier.txt, tier_rows.txt). NOT TESTED: the positive control of the trace grep for a write under tests/ (PILOT unreachable after the fetch); the original race by timing (reproduced by a planted file instead); FBNeo and MiSTer are not involved.
Artifacts (read every one, in full):
  - build/agent221/t362/close/issue362.md
  - build/agent221/t362/close/fix.diff
  - build/agent221/t362/close/measurer_repro.txt
  - build/agent221/t362/close/measurer_pilot.txt
  - build/agent221/t362/close/pilot_t362.sh
  - build/agent221/t362/close/blobs_committed.txt
  - build/agent221/t362/close/controls_concurrent.diff
  - build/agent221/t362/close/gotchas.diff
  - build/agent221/t362/close/tier.txt
  - build/agent221/t362/close/tier_rows.txt
  - build/agent221/t362/close/closing_362.md
  - build/agent221/t362/close/ticket_row_362.tsv
