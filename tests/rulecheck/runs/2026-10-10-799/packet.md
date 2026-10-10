THE PACKET

Decision kind: recommendation
Subject: #228 step 4: recommend dropping the frozen per-replay $FF8080 tripwire from option A — it measures only the frame count
Claim (the working agent's sentence): Recommendation (build/agent197/t228/gameclock_redundant.md): drop the frozen per-replay RAM:$FF8080 files and their comparison from #228 step 4, keeping each run's frames == emulated check, the per-replay reference legs once at the conversion, and one staging reference leg per gate; it rests on build/agent197/t228/gameclock_by_frames.txt, where all 122 frozen rows over four legs and three builds fall into 34 frame counts each with exactly one $FF8080 value, on build/agent197/t228/ghost_mode_drift.log, where the drift-clock control fires on counted frames against emulated ones, and on build/agent197/t228/emu_clock_gate.log, where a breakpoint leg's checksum is not the basis's while its $FF8080 equals the reference's; it changes the design the maintainer ruled (DECISIONS_HISTORY.md lines 648-658), so it is put to the maintainer. NOT TESTED: that $FF8080 is frame-determined outside this corpus (no stall or paused-counter replay was sought), and whether any other RAM value would detect a breakpoint stop moving the game.
Artifacts (read every one, in full):
  - build/agent197/t228/gameclock_redundant.md
  - build/agent197/t228/gameclock_by_frames.txt
  - tests/expected/instr_gameclock/audit_walker_ghost.tsv
  - tests/expected/instr_gameclock/audit_walker_repoint.tsv
  - build/agent197/t228/ghost_mode_drift.log
  - build/agent197/t228/emu_clock_gate.log
  - tests/lib/instr_align.sh
  - DECISIONS_HISTORY.md.lines-648-658 (lines 648-658 of DECISIONS_HISTORY.md)
