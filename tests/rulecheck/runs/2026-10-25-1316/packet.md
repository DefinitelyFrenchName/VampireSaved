THE PACKET

Decision kind: recommendation
Subject: #321 phase 2 (with #305 and #323): the runner speed-up and the two runner fixes to put to the maintainer
Claim (the working agent's sentence): Recommend to the maintainer, as #321 phase 2 with #305 and #323 folded in: (1) tests/test_mame_parity.sh PARITY_JOBS default 1 -> min(16, nproc*2/3); (2) tests/audit_guard_corpus.sh JOBS default 2 -> min(8, nproc/3); (3) the five fbneo-lane rows run in the mame lane pool; (4) test_mame_wide gains a WIDE_JOBS queue (default min(6, nproc/4)); (5) #323: rename the runner lane loop variable (tests/run_all_emulator.sh:242 and :549) and give vs_ctl_read/vs_meas_read prefixed locals, plus a test_emulator_runner section (a red prereq gate then a passing one must STOP; control: the shared name restored); (6) #305: a decrypt_cache_warm function in tests/lib/decrypt_cache.sh called by both runners after the ROM audit, and tools/build_donovan.sh using decrypt_cache_ensure, plus a test_emulator_runner section with a decrypt-warm-off control; ERIS stays at --jobs 8. Basis (all ERIS, 2aacebe8): the 14z-208b freeze tier ran 8,784 s by its run records (freeze208_wall.txt: run_record_start.json utc 16:40:18Z to run_record_end.json utc 19:06:42Z, build/emu_freeze208_eris), with test_mame_parity 2485 s, test_dualtrack 896 s and audit_guard_corpus 4827 s (its results.tsv); alone, parity took 666/375/300/244 s at PARITY_JOBS 4/8/12/16 (each the same PARTIAL line as the freeze) and the guard corpus 3106/1138/830 s at JOBS 2/8/16, exit 0 (eris_batch1.out, batch1_x times.tsv); test_mame_wide split one invocation per replay took 730 s at 4 at once and 522 s at 12, 36 ok lines and the same verdict line each (eris_batch1_wide.txt); the tier with (1)-(3) at --jobs 8 ran 4,914 s wall (b2/timeline_b2_r8.txt), its ten first reds traced to the clone missing untracked build-dir contents and the harness patch mtime (b2/compare_b2_r8.txt; the guard corpus known-crash control needs build/hui41, tests/audit_guard_corpus.sh:168), and after that fix those rows re-ran and the 182 verdicts read PASS 177, SKIP 4, FAIL 1, the freeze's counts (b2/eris_batch2fix.out); #323 reproduced: _l reads the log path after a PASS classify and prereq after a FAIL one (repro323/repro.out), and the runner's STOP check reads _l after the lane loop (tests/run_all_emulator.sh:666); #305 reproduced: with build/out absent audit_trap_air_hit and audit_dmg_legacy_sweep SKIP, and both PASS after the views are built (batch1_x emu305_cold and emu305_warm results.tsv). NOT TESTED: (4) inside a tier (its tier gain is derived), (5) and (6) as code (designs only, neither written nor run), --jobs 12, the guard corpus queue and the removal of its nice -n 19, the release --controls queue and run_suite.sh parallel replays (later avenues, not recommended now), any host but ERIS (the nproc formulas rest on ERIS's 24 threads alone), whether the after-fix verdicts equal the freeze row by row rather than by count, and a second run of either batch (one run each, so the run-to-run spread of these timings is unmeasured). No gameplay conclusion is drawn.
Artifacts (read every one, in full):
  - build/agent209/t321/freeze208_wall.txt
  - build/emu_freeze208_eris/results.tsv
  - build/agent209/t321/knob_census.txt
  - build/agent209/t321/eris_batch1.sh
  - build/agent209/t321/eris_batch1.out
  - build/agent209/t321/eris_batch1_wide.txt
  - build/agent209/t321/batch1_x/a209/times.tsv
  - build/agent209/t321/batch1_x/a209/emu305_cold/results.tsv
  - build/agent209/t321/batch1_x/a209/emu305_warm/results.tsv
  - build/agent209/t321/eris_batch2.sh
  - build/agent209/t321/b2/timeline_b2_r8.txt
  - build/agent209/t321/b2/compare_b2_r8.txt
  - build/agent209/t321/eris_batch2fix.sh
  - build/agent209/t321/b2/eris_batch2fix.out
  - build/agent209/t321/repro323/repro.sh
  - build/agent209/t321/repro323/repro.out
  - tests/lib/controls.sh
  - tests/lib/measures.sh
  - tests/run_all_emulator.sh.lines-236-250 (lines 236-250 of tests/run_all_emulator.sh)
  - tests/run_all_emulator.sh.lines-545-680 (lines 545-680 of tests/run_all_emulator.sh)
  - tests/audit_guard_corpus.sh
  - tests/ci_emulator.tsv.lines-1-40 (lines 1-40 of tests/ci_emulator.tsv)
  - tests/ci_emulator.tsv.lines-112-150 (lines 112-150 of tests/ci_emulator.tsv)
  - tests/lib/decrypt_cache.sh
