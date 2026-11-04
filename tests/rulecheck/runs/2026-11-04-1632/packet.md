THE PACKET

Decision kind: recommendation
Subject: #361 closed done: the tier classifier names test_crash_sweep.sh --tier emulator in both runners, so audit_crash_sweep_emu is emulator-tier and the registry check reads 255 of 255; gated by test_emulator_runner section 3's two-sided case, shown to fail on a mutant (14z-220 fix, 14z-221 closure)
Claim (the working agent's sentence): #361 can close done with closing_361.md, its row ticket_row_361.tsv and the gotcha edit gotcha.diff. The issue (issue361.md): the emulator runner's registry check read audit_crash_sweep_emu as a DEAD ROW because the tier classifier did not name its only emulator route, test_crash_sweep.sh --tier emulator. The fix (fix_committed.diff, in 91bde83b, an ancestor of origin/main, evidence361.txt E6) adds that alternative to both runners' EMU pattern (E7) and a two-sided case to test_emulator_runner.sh section 3. Measured by a measurer worker (measurer_return.txt; the windows in evidence361.txt are cut by a script from its output files): the dry-run registry check reads 254 of 255 with audit_crash_sweep_emu DEAD at d19546c7 (E1) and 255 of 255 with no dead row at 8bc62bf4 (E2); the gate PASSES on a clean checkout of 8bc62bf4 with both new section-3 lines ok and no FAIL line (E3, E3b, E3c), and on the same checkout with only the new alternative removed from the emulator runner it exits 1 with exactly that case FAILing (E0, E4, E4b, E4c). NOT TESTED: the static runner's copy of the pattern on its own, and a mutant of the static runner; the gate's declared must-fire controls do not cover this case (the mutant run here is a one-off, not a declared control).
Artifacts (read every one, in full):
  - build/agent221/t361/close/issue361.md
  - build/agent221/t361/close/fix_committed.diff
  - build/agent221/t361/close/evidence361.txt
  - build/agent221/t361/close/measurer_return.txt
  - build/agent221/t361/close/gotcha.diff
  - build/agent221/t361/close/closing_361.md
  - build/agent221/t361/close/ticket_row_361.tsv
