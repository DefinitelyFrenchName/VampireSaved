THE PACKET

Decision kind: expectation
Subject: #118: three emulator gates promoted from the 14z-194 pilot (audit_mizuumi_inputs, audit_extra_pass, audit_mizuumi_attack), their asserted figures frozen in the scripts, merged at 4aa52ade and 42bb2e9d
Claim (the working agent's sentence): CLAIM: tests/audit_mizuumi_inputs.sh, tests/audit_extra_pass.sh and tests/audit_mizuumi_attack.sh assert, on pristine vsavj under MAME, the fighter-block behaviours their EXPECTS lines state (the input words +0x394/+0x395/+0x397 and +0x122..+0x12D predicted from the static mechanism; the speed level's extra logic pass predicted per frame at pinned levels and unpinned; the attack-start fields +0x101, +0x1B8, +0x119 measured with write taps), and each re-run from a clone of the merged main at c4466c51 on ERIS reads PASS (build/agent195/eris_118m/<gate>.log) with every declared control firing and each control run as a mode exiting 1 (the __<control>.log files). NOT TESTED: +0x103 (not promoted: to be judged at the writes by PRG:0x02758C, the gate header says why), +0x167/+0x168 (the marathon re-runs), HOMING items 4 and 5, merged-m23 (no merged leg in any of the three), FBNeo; the figures are the pilot's measurements re-asserted, not compared with the mizuumi wiki beyond the names.
Artifacts (read every one, in full):
  - tests/audit_mizuumi_inputs.sh
  - tests/audit_extra_pass.sh
  - tests/audit_mizuumi_attack.sh
  - tests/replays/118_input_sweep.rpl
  - tests/replays/118_chain.rpl
  - build/agent195/eris_118m/audit_mizuumi_inputs.log
  - build/agent195/eris_118m/audit_extra_pass.log
  - build/agent195/eris_118m/audit_mizuumi_attack.log
  - build/agent195/eris_118m/audit_extra_pass__other-level.log
  - build/agent195/eris_118m/audit_extra_pass__unpinned-equals-6.log
  - build/agent195/eris_118m/audit_mizuumi_attack__cpu-side.log
  - build/agent195/eris_118m/audit_mizuumi_attack__hit-vs-start.log
  - build/agent195/eris_118m/audit_mizuumi_attack__isolated-presses.log
  - build/agent195/eris_118m/audit_mizuumi_attack__previous-press-key.log
  - build/agent195/eris_118m/audit_mizuumi_inputs__lag-120.log
  - build/agent195/eris_118m/audit_mizuumi_inputs__no-edge-mask.log
  - build/agent195/eris_118m/audit_mizuumi_inputs__opposite-flip.log
  - build/agent195/eris_118m/audit_mizuumi_inputs__wrong-run.log
