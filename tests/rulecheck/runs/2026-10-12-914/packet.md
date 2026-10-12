THE PACKET

Decision kind: expectation
Subject: freeze the #118 replays' game clocks into tests/expected/instr_gameclock/audit_walker_ghost.tsv after their vanilla basis logs entered the walker gate's corpus
Claim (the working agent's sentence): Freeze 16 new rows into tests/expected/instr_gameclock/audit_walker_ghost.tsv, because the release rerun's audit_walker_ghost FAIL on ERIS (audit_walker_ghost.eris_s.log) is 16 runs with no frozen game clock — the eight #118 replays on both legs, which entered the gate's corpus of every replay with a vanilla basis log when their masked-v2 logs were frozen (rule-checker run 910): tests/audit_walker_ghost.sh --freeze-clock at 58302669 froze 128 clocks from reference legs (wg_freeze.log), the 112 rows at HEAD came back unchanged, none changed or gone, the 16 added are the eight on vsavj and reloc with each pair agreeing, the six 118_sel_b* at 5320 frames reading 6b as 03_two_player_vs does, and the header changed only its commit stamp (wg_keys.txt from wg_keys.py), and the gate through tests/run_all_emulator.sh --strict --controls then PASSes with all five controls honoured (wg_runner.log). NOT TESTED: the freeze and its verification ran on one host (MacBook-Pro.local at 58302669, wg_freeze.log), not ERIS; the 16 clocks are each reference leg's own reading and no independent clock source is compared.
Artifacts (read every one, in full):
  - build/agent198/skip118/audit_walker_ghost.eris_s.log
  - build/agent198/skip118/wg_freeze.log
  - build/agent198/skip118/wg_keys.py
  - build/agent198/skip118/wg_keys.txt
  - build/agent198/skip118/wg_runner.log
  - tests/audit_walker_ghost.sh.lines-1-40 (lines 1-40 of tests/audit_walker_ghost.sh)
  - tests/audit_walker_ghost.sh.lines-200-245 (lines 200-245 of tests/audit_walker_ghost.sh)
