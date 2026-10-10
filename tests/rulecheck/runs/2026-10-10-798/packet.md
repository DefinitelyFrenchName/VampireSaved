THE PACKET

Decision kind: expectation
Subject: #228 step 4, slice 1: walker_ghost.toml re-frozen on emulated time (site 0x54476 sp_min 0xff06de -> 0xff055e, 5 -> 50 replays) and the first frozen game clocks (audit_walker_ghost 112 rows, audit_walker_repoint 10 rows)
Claim (the working agent's sentence): On the shared emulated-frame clock (tests/lua/emu_clock.lua, ground-truthed by tests/test_emu_clock.sh: reference anchor equal to the frozen basis at frame 1500, a breakpoint leg with 12,029 stop frames counting 1500 over 1500 emulated at the reference's game clock, both controls fired), walker_sp.lua's runs cover their whole replays, so audit_walker_ghost's frozen range for site 0x54476 moves from 0xff06de..0xff06de (5 replays, the frame_done clock's artefact, which ghost_mode_drift.log reproduces under INSTR_CLOCK=frame_done) to 0xff055e..0xff06de (50 of 56 replays, the other walker's range; ground truth and visibility still pass), and the per-run game clocks are frozen from reference legs only after the one-time alignment held (walker_ghost_freeze_clock.log: 56 pristine reference legs on the basis, 112 breakpoint runs on their reference legs' clocks; walker_repoint_freeze_clock.log: 10 runs on their reference legs' clocks); both gates then PASS with every control fired and each new mode FAILs (ghost_normal.log, repoint_normal.log, walker_modes.txt). NOT TESTED: that a frozen $FF8080 value reproduces on PILOT or ERIS (frozen on this Mac); the reloc and new legs' values for any build other than build/m3b_merged31 (a freeze that moves the build moves them, and the gate then FAILs until re-frozen); a breakpoint stop that changes state without moving $FF8080 (measured to happen: emu_clock_gate.log notes the breakpoint leg's checksum unlike the basis); that one staging leg (21_don_mash) catches a slip confined to other replays; whether the oracle verdicts catch a byte differing in the push range (the gate's existing NOT covered note).
Artifacts (read every one, in full):
  - build/agent197/t228/emu_clock_gate.log
  - tests/lua/emu_clock.lua
  - tests/lib/instr_align.sh
  - build/agent197/t228/walker_sp.diff
  - build/agent197/t228/walker_ghost_converted.log
  - build/agent197/t228/walker_ghost_freeze_clock.log
  - build/agent197/t228/walker_ghost_freeze_range.log
  - build/agent197/t228/walker_ghost_toml.diff
  - build/agent197/t228/ghost_normal.log
  - build/agent197/t228/ghost_mode_drift.log
  - build/agent197/t228/ghost_mode_skip.log
  - build/agent197/t228/walker_repoint_freeze_clock.log
  - build/agent197/t228/repoint_normal.log
  - build/agent197/t228/walker_modes.txt
  - tests/expected/instr_gameclock/audit_walker_ghost.tsv
  - tests/expected/instr_gameclock/audit_walker_repoint.tsv
  - build/agent197/t228/audit_walker_ghost.diff
  - build/agent197/t228/audit_walker_repoint.diff
  - build/agent196/t228/step3/SUMMARY.txt
  - DECISIONS_HISTORY.md.lines-648-658 (lines 648-658 of DECISIONS_HISTORY.md)
