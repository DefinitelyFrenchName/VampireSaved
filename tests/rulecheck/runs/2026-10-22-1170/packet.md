THE PACKET

Decision kind: recommendation
Subject: #299 closed done: the static tier's --jobs pool, after the Mac's whole-tier serial against --jobs 8 and real-value comparer plants (14z-206), after runs 1161-1166
Claim (the working agent's sentence): #299 can close done: its plan's four steps are done (--jobs N landed 14z-205; the close runs --jobs 8, ruled 2026-10-19) and the four items its 2026-10-20 comment left open are each measured, and fixed where they failed. (1) On the Mac the whole static tier of 8b82d5d2 ran serially and at --jobs 8 (--strict --cadence freeze, logs kept by the runner's own exit traps; build/agent206/t299/c3/serial/runner.log, c3/pool/runner.log): both legs PASS 212 SKIP 0 FAIL 2 with 392 of 392 controls executed and honoured, and the results and controls tables equal row for row (c3/compare_c3_serial_pool.out). Of 660 logs per leg 25 differ under the narrowed comparer, and c3/compare_c3_serial_pool_full.out shows each a run-time value, a gate's designed retry or a designed fork race's stopping point. The two FAILs are the same in both legs: test_emulator_staleness by design at freeze cadence, test_static_runner the log-keeping patch's own artefact (c3/ORCH_test_static_runner.md, tsr_*.log). PILOT's 14z-205c legs, from copier-kept logs with one copy shown cut short, read 596 identical / 24 differing under both comparer copies (c3/pilot_BA_c2.out, c3/pilot_BA_c3.out). The comparer was planted with real values of each erased shape (c3/plant_check3.py, c3/plant_c3_serial.tsv, c3/plant_c2_plant_pilotB_A.tsv): C2's copy erases six, the narrowed copy (c3/compare_legs_c3.diff) reports those six and erases the four volatile ones, and the closing comment's Not covered list names what it still erases. (2) The cold decrypt cache under the pool is fixed (views built before the tier, t299.diff) and proven on a whole tier with the views deleted (build/agent206/tier/tier.log). (3) The collision census was re-traced with relative paths resolved (x2/REPORT.md); the new hazard it found, a control rewriting a tracked file, is fixed (x2fix/gate.log, x2fix/mode.log). (4) Load moved no verdict (build/agent205c/t299/REPORT.md §4). What is not measured is in the closing comment's Not covered list.
Artifacts (read every one, in full):
  - build/agent206/t299/closing_comment.md
  - build/agent206/t299/issue_299.txt
  - build/agent205c/t299/REPORT.md
  - build/agent206/t299/REPORT.md
  - build/agent206/t299/c2/REPORT.md
  - build/agent206/t299/c2/plant_check2.py
  - build/agent206/t299/c2/epoch_scan.out
  - build/agent206/t299/c2/pilot_BA_normal_c2_full.out
  - build/agent206/t299/c2/pilot_24_classified.md
  - build/agent206/t299/c3/REPORT.md
  - build/agent206/t299/c3/ORCH_test_static_runner.md
  - build/agent206/t299/c3/trap_sete_repro.sh
  - build/agent206/t299/c3/tsr_head_unset.log
  - build/agent206/t299/c3/tsr_head_C2KEEP.log
  - build/agent206/t299/c3/tsr_patched_unset.log
  - build/agent206/t299/c3/tsr_patched_C2KEEP.log
  - build/agent206/t299/c3/inside.sh
  - build/agent206/t299/c3/clone_diff.patch
  - build/agent206/t299/c3/inside_head.txt
  - build/agent206/t299/c3/snapshot.log
  - build/agent206/t299/c3/serial/runner.log
  - build/agent206/t299/c3/pool/runner.log
  - build/agent206/t299/c3/serial/results.tsv
  - build/agent206/t299/c3/pool/results.tsv
  - build/agent206/t299/c3/compare_c3_serial_pool.out
  - build/agent206/t299/c3/compare_c3_serial_pool_full.out
  - build/agent206/t299/c3/compare_c3_serial_pool_strict.out
  - build/agent206/t299/c3/compare_c2_serial_pool.out
  - build/agent206/t299/c3/compare_legs_c3.diff
  - build/agent206/t299/c3/plant_check3.py
  - build/agent206/t299/c3/plant_c3_serial.tsv
  - build/agent206/t299/c3/plant_c2_plant_pilotB_A.tsv
  - build/agent206/t299/c3/pilot_BA_c2.out
  - build/agent206/t299/c3/pilot_BA_c3.out
  - build/agent206/t299/c3/epoch_scan_mac_whole.out
  - build/agent206/t299/c3/rule_checker_5f31e850.log
  - build/agent206/t299/x2/REPORT.md
  - build/agent206/t299/x2fix/gate.log
  - build/agent206/t299/x2fix/mode.log
  - build/agent206/t299/t299.diff
  - build/agent206/tier/tier.log
  - build/agent206/tier/confirm2.log.lines-219-558 (lines 219-558 of build/agent206/tier/confirm2.log)
  - build/agent206/tier/confirm3.log
  - DECISIONS_HISTORY.md.lines-7314-7318 (lines 7314-7318 of DECISIONS_HISTORY.md: its INDEX entry "## Ruled 2026-10-19 (14z-205) — #299: a session close runs its tier at `--jobs 8`")
  - DECISIONS_HISTORY.md.lines-7606-7613 (lines 7606-7613 of DECISIONS_HISTORY.md: its INDEX entry "## Ruled 2026-10-21 (14z-206) — the landing commits now; #299 stays open and its closure goes on sep")
  - docs/project/gotchas.md.lines-7389-7417 (lines 7389-7417 of docs/project/gotchas.md)
  - docs/project/tickets.tsv.lines-84-84 (lines 84-84 of docs/project/tickets.tsv)
  - STATE.md.lines-96-115 (lines 96-115 of STATE.md)
