THE PACKET

Decision kind: recommendation
Subject: #299 closed done: the static tier's --jobs pool, its four open items measured and the cold-cache one fixed (14z-206), after runs 1161 and 1162
Claim (the working agent's sentence): #299 can close done: its plan's four steps are done (--jobs N landed 14z-205; the close runs --jobs 8, ruled 2026-10-19); of the four items its 2026-10-20 comment left open, (1) serial against --jobs 8 with every log kept: on PILOT 620 logs per leg, 596 identical in normal mode (612 under --strict), the only verdict difference the MRA pair and every other difference read as a run-time value, a partial copy or git stderr order; the comparer was checked by planted differences and a corrected copy reports every real plant; and on the Mac the six gates PILOT's environment failed ran for real serially and at --jobs 8 on the landing commit, 23 of their 24 logs identical and the 24th only the browser gate's own retry; (2) the five direct build/out readers that failed or skipped cold under the pool are fixed by a warm-up in tests/run_all_static.sh (test_static_runner sections 28-29, control decrypt-warm-off), and a strict --cadence freeze --jobs 8 whole tier on a snapshot of the landing tree with the six views deleted read PASS 214 SKIP 0 FAIL 1, the FAIL test_emulator_staleness by design at freeze cadence, 415 of 415 controls honoured; (3) a re-traced write census of every static gate on PILOT, twice, with each relative path resolved against the process's working directory and its own controls firing, finds every shared write serialised (the jtsim lock) or benign but one, test_checkdocs_rom's control 5 rewriting a tracked file in place, now fixed to perturb a copy (tools/checkdocs_rom.py --covered; the gate passes, its mode fails, the tracked file unchanged); (4) one loaded run moved no results or control row; NOT tested: the emulator runner's warm-up and build_donovan.sh's non-atomic write (both #305), a gate run on its own (no warm-up), a whole-tier serial leg on the Mac, the census's timing (no timestamps), the emulator tier and the Mac in the census, more than one loaded run, a foreign mode failure without its own CONTROL DEAD beside an exception; compare_legs.py is a session tool, fixed only as a copy, and the census is not a gate
Artifacts (read every one, in full):
  - build/agent206/t299/closing_comment.md
  - build/agent206/t299/issue_299.txt
  - build/agent205c/t299/REPORT.md
  - build/agent206/t299/REPORT.md
  - build/agent206/t299/c2/REPORT.md
  - build/agent206/t299/c2/compare_c2.out
  - build/agent206/t299/c2/plant_mac/result_c2.tsv
  - build/agent206/t299/c2/plant_mac/result_orig.tsv
  - build/agent206/t299/c2/pilot_BA_normal_c2.out
  - build/agent206/t299/c2/pilot_16_read.txt
  - build/agent206/t299/x2/REPORT.md
  - build/agent206/t299/x2/pilot/c1/shared_writes.tsv
  - build/agent206/t299/x2/pilot/c2/shared_writes.tsv
  - build/agent206/t299/x2/pilot/c2/write_read_cross.tsv
  - build/agent206/t299/x2/pilot/c2/notes.txt
  - build/agent206/t299/x2/pilot/ctl/out.json
  - build/agent206/t299/x2/pilot/ctl/out/shared_writes.tsv
  - build/agent206/t299/x2/pilot/ctl/out_blind.json
  - build/agent206/t299/x2/pilot/ctl/out_blind/shared_writes.tsv
  - build/agent206/t299/x2fix/checkdocs.diff
  - build/agent206/t299/x2fix/gate.log
  - build/agent206/t299/x2fix/mode.log
  - build/agent206/t299/t299.diff
  - build/agent206/tier/tier.log
  - STATE_HISTORY.md.lines-698-959 (lines 698-959 of STATE_HISTORY.md: its INDEX entry "## Session 14z-205c — **#292 declined; #277, #262, #263 closed; #299's MRA lock and the dead-control")
  - DECISIONS_HISTORY.md.lines-7310-7315 (lines 7310-7315 of DECISIONS_HISTORY.md: its INDEX entry "## Ruled 2026-10-19 (14z-205) — #299: a session close runs its tier at `--jobs 8`")
  - DECISIONS_HISTORY.md.lines-7585-7593 (lines 7585-7593 of DECISIONS_HISTORY.md: its INDEX entry "## Ruled 2026-10-21 (14z-206) — the landing: one commit at #299's closure; two tickets; S4-B in a wo")
  - docs/project/gotchas.md.lines-7384-7411 (lines 7384-7411 of docs/project/gotchas.md)
  - docs/project/tickets.tsv.lines-82-82 (lines 82-82 of docs/project/tickets.tsv)
