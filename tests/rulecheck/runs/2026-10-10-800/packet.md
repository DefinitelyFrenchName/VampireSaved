THE PACKET

Decision kind: expectation
Subject: #228 step 4, slice 1 — re-check after run 798: walker_ghost.toml re-frozen on emulated time (site 0x54476 sp_min 0xff06de -> 0xff055e, 5 -> 50 replays) and the first frozen game clocks (audit_walker_ghost 112 rows, audit_walker_repoint 10 rows)
Claim (the working agent's sentence): On the shared emulated-frame clock (tests/lua/emu_clock.lua, ground-truthed by tests/test_emu_clock.sh), walker_sp.lua's runs cover their whole replays, so audit_walker_ghost's frozen range for site 0x54476 moves from 0xff06de..0xff06de (5 replays, the frame_done clock's artefact, which b2/ghost_mode_drift.log reproduces) to 0xff055e..0xff06de (50 of 56 replays; ground truth and visibility still pass); the per-run game clocks RAM:$FF8080 — the game's own count of emulated frames, an independent witness of the script's frame count and nothing more (tests/lib/instr_align.sh) — are frozen from reference legs only after every reference leg reproduced a yardstick outside the instrument (pristine legs the frozen basis, the relocated, new and don_m5 legs replay.lua run live on their build) and every breakpoint run matched its reference leg's game clock on emulated time (b2/ghost_freeze_clock.log, b2/repoint_freeze_clock.log); both gates then PASS with every control fired and each new mode FAILs on the gate's own check (b2/ghost_normal.log, b2/repoint_normal.log, b2/*_mode_*.log). NOT TESTED: that a frozen $FF8080 value reproduces on PILOT or ERIS (frozen on this Mac); the relocated and new legs' values for any build other than build/m3b_merged31 (a freeze that moves the build moves them, and the gate then FAILs until re-frozen); a breakpoint stop that changes state without moving $FF8080 (measured to happen, emu_clock_gate.log; neither check sees it); that one staging leg (21_don_mash) catches a staging slip confined to other replays; whether the oracle verdicts catch a byte differing in the push range (the gate's existing NOT covered note).
Artifacts (read every one, in full):
  - build/agent197/t228/emu_clock_gate.log
  - tests/lua/emu_clock.lua
  - tests/lib/instr_align.sh
  - build/agent197/t228/walker_sp.diff
  - build/agent197/t228/walker_ghost_converted.log
  - build/agent197/t228/b2/ghost_freeze_clock.log
  - build/agent197/t228/walker_ghost_freeze_range.log
  - build/agent197/t228/walker_ghost_toml.diff
  - build/agent197/t228/b2/ghost_normal.log
  - build/agent197/t228/b2/ghost_mode_drift.log
  - build/agent197/t228/b2/ghost_mode_skip.log
  - build/agent197/t228/b2/repoint_freeze_clock.log
  - build/agent197/t228/b2/repoint_normal.log
  - build/agent197/t228/b2/repoint_mode_drift.log
  - build/agent197/t228/b2/repoint_mode_skip.log
  - build/agent197/t228/b2/batch.txt
  - tests/expected/instr_gameclock/audit_walker_ghost.tsv
  - tests/expected/instr_gameclock/audit_walker_repoint.tsv
  - build/agent197/t228/audit_walker_ghost.diff
  - build/agent197/t228/audit_walker_repoint.diff
  - build/agent196/t228/step3/SUMMARY.txt
  - DECISIONS_HISTORY.md.lines-648-658 (lines 648-658 of DECISIONS_HISTORY.md)
