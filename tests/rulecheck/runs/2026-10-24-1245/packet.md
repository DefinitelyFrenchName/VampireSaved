THE PACKET

Decision kind: recommendation
Subject: #298 closed done on the 14z-207 close tier, test_static_runner's controls counted apart (14z-208), after run 2026-10-24-1244
Claim (the working agent's sentence): #298 can close done (build/agent208/t298/closing_298.md; docs/project/tickets.tsv line 91): its body's done-when (build/agent208/t298/issue298_body.md) — a close run with the rule (a re-run gate executes its controls only when it is absent from the base, not PASS there, its base controls were not all executed, or a program of its reach changed: tools/static_confirm.py lines 144-158) and its control time measured against 1,500-1,800 s — is met by the 14z-207 close tier, a strict --confirm run against the 14z-206 close's results (build/agent207/close/close_params.tsv PREV), the first close whose base was the previous close's run, GREEN, PASS 97 (runner.log lines 13, 398-400, 413, 417): 161 controls executed, 161 HONOURED, 3,941 s, of which test_static_runner 23 controls and 3,172 s (build/agent208/t298/measure.txt C2), re-run as a gate absent from its base (runner.log line 30; build/agent208/t298/runner_absent_206.txt), counted apart as the maintainer ruled (the DECISIONS_HISTORY.md entry of 2026-10-24, 14z-208); without it 138 controls over 25 gates in 769 s (measure.txt C2). The 14z-205 close is a second figure under the rule with a different kind of base, its own sitting's tier 2 (build/agent205/close/close_params.tsv PREV): 129 controls in 577 s without test_static_runner, derived as 143-14 and 1,448-871 from measure.txt C8. The 14z-206 close records no figure under the rule: its tier of record ran without --confirm (the STATE_HISTORY.md 14z-206 entry, its CLOSE section) and its --confirm run's controls file is byte-identical to that full run's (runner_absent_206.txt). The stale must_fire_contract.md paragraph is corrected (build/agent208/t298/must_fire.diff). Run 2026-10-24-1244's Q1 (the two bases described on different terms) is answered by that wording. NOT TESTED: why each of the other 25 gates executed its controls (the runner's log names a re-run reason, not a controls reason), so a gate executing controls by some other path is not excluded; no close whose change set leaves the runner alone was measured; the two closes' change sets differ in size and kind, so their figures are not a like-for-like comparison; the 1,500-1,800 s baseline is the ticket body's figure, not re-measured here; the attribution of the 832 s wall to #312's pool is read from the time line, not measured with the pool off.
Artifacts (read every one, in full):
  - build/agent208/t298/issue298.md
  - build/agent208/t298/issue298_body.md
  - build/agent208/t298/closing_298.md
  - docs/project/tickets.tsv.lines-91-91 (lines 91-91 of docs/project/tickets.tsv)
  - build/agent208/t298/measure.txt
  - build/agent208/t298/runner_absent_206.txt
  - build/agent207/close/tier_results.controls.tsv
  - build/agent207/close/close_params.tsv
  - build/snapshot_runs/20261024T104527-5d32ece0fbe5/runner.log
  - build/agent205/close/tier_results.controls.tsv
  - build/agent205/close/close_params.tsv
  - tools/static_confirm.py.lines-144-158 (lines 144-158 of tools/static_confirm.py)
  - docs/project/must_fire_contract.md.lines-114-145 (lines 114-145 of docs/project/must_fire_contract.md)
  - build/agent208/t298/must_fire.diff
  - DECISIONS_HISTORY.md.lines-7874-7883 (lines 7874-7883 of DECISIONS_HISTORY.md: its INDEX entry "## Ruled 2026-10-24 (14z-208) — #298 closed on the 14z-207 close tier, `test_static_runner`'s contro")
  - STATE_HISTORY.md.lines-700-881 (lines 700-881 of STATE_HISTORY.md: its INDEX entry "## Session 14z-206 — **PILOT and ERIS offline: the Mac carries the work in parallel. #299's cold cac")
