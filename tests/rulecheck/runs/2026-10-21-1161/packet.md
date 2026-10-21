THE PACKET

Decision kind: recommendation
Subject: #299 closed done: the static tier's --jobs pool, its four open items measured and the cold-cache one fixed (14z-206)
Claim (the working agent's sentence): #299 can close done: its plan's four steps are done (--jobs N landed 14z-205; the close runs --jobs 8, ruled 2026-10-19); of the four items its 2026-10-20 comment left open, (1) serial against --jobs 8 with every log kept gave 612 of 620 logs identical on PILOT, the only verdict difference the MRA pair; (2) the five direct build/out readers that failed or skipped cold under the pool are fixed by a warm-up in tests/run_all_static.sh (test_static_runner sections 28-29, control decrypt-warm-off), and a strict --cadence freeze --jobs 8 tier on a snapshot of the landing tree with the six views deleted inside it read PASS 214 SKIP 0 FAIL 1, the FAIL test_emulator_staleness, red by design at freeze cadence, with 415 of 415 controls honoured and the five gates passing; (3) the write census's only colliding class, the jtsim scratch, is locked (test_jtsim_scratch_heal section 6) and its honoured-for-the-wrong-reason control now reads DIED; (4) one loaded run moved no results or control row; NOT tested: the emulator runner's warm-up and build_donovan.sh's non-atomic write (both #305), unlink/rename/mkdir collisions, more than one loaded run, a foreign mode failure without its own CONTROL DEAD beside an exception
Artifacts (read every one, in full):
  - build/agent206/t299/closing_comment.md
  - build/agent206/t299/issue_299.txt
  - build/agent205c/t299/REPORT.md
  - build/agent206/t299/REPORT.md
  - build/agent206/t299/t299.diff
  - build/agent206/tier/tier.log
  - build/snapshot_runs/20261021T164034-04a537694b90/results.tsv
  - STATE_HISTORY.md.lines-698-959 (lines 698-959 of STATE_HISTORY.md: its INDEX entry "## Session 14z-205c — **#292 declined; #277, #262, #263 closed; #299's MRA lock and the dead-control")
  - DECISIONS_HISTORY.md.lines-7309-7314 (lines 7309-7314 of DECISIONS_HISTORY.md: its INDEX entry "## Ruled 2026-10-19 (14z-205) — #299: a session close runs its tier at `--jobs 8`")
  - DECISIONS_HISTORY.md.lines-7584-7591 (lines 7584-7591 of DECISIONS_HISTORY.md: its INDEX entry "## Ruled 2026-10-21 (14z-206) — the landing: one commit at #299's closure; two tickets; S4-B in a wo")
  - docs/project/gotchas.md.lines-7384-7397 (lines 7384-7397 of docs/project/gotchas.md)
  - docs/project/tickets.tsv.lines-81-81 (lines 81-81 of docs/project/tickets.tsv)
