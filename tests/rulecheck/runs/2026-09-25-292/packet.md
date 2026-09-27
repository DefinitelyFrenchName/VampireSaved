THE PACKET

Decision kind: expectation
Subject: #179: freeze tests/expected/shared_wall_push.tsv, the new gate tests/audit_shared_wall_push.sh
Claim (the working agent's sentence): Freeze tests/expected/shared_wall_push.tsv as measured by FREEZE=1 (gate_freeze.log, 17 rows): legacy_lilith — vsavj's push-apart moves P1 (Lilith) to x 0x3C0 at PC 0x0193B2 on f3144, vs2's moves P2 (Victor) at 0x017DB4, vs2's clamp PC 0x02745E the only non-zero +0x148 writer and vsavj none, the end x 960/1000 reversed between the games, ids 0x0E/0x03 on both (real picks, never poked), the first split f3144; huitzil_3 — ours moves P1 (Phobos) at 0x0193B2 from f6150, native moves P2 (Demitri) at 0x017DB4 on f6150-6151, native's +0x148 writers 0x027444 and 0x02745E and ours none; every row agrees with the independent taps in lilith_mechanism.txt and ev8_mechanism.txt; the plain run PASSes with both in-gate controls fired, and each control mode FAILs (gate_run_*.log). NOT tested: the flag-planted control plants at PC 0x0281F0, a vsavj clamp instruction, so it shows the reducer counts a planted vsavj-range writer, not a writer at a tenant (0x4xxxxx) PC; the huitzil_3 part runs the naming rig's pokes (its position pins before each event) on both legs; the flag row covers frames 2300 to each run's end only; the ids row reads the last pre-match write.
Artifacts (read every one, in full):
  - tests/audit_shared_wall_push.sh
  - tests/expected/shared_wall_push.tsv
  - build/agent184/t179/gate_freeze.log
  - build/agent184/t179/gate_run_plain.log
  - build/agent184/t179/gate_run_flag-planted.log
  - build/agent184/t179/gate_run_legs-swapped.log
  - build/agent184/t179/lilith_mechanism.txt
  - build/agent184/t179/ev8_mechanism.txt
  - tests/replays/naming/huitzil_3.json
