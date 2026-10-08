THE PACKET

Decision kind: expectation
Subject: #118: three emulator gates (audit_mizuumi_inputs, audit_extra_pass, audit_mizuumi_attack) after run 2026-10-08-729's fixes, at c6454458
Claim (the working agent's sentence): CLAIM: tests/audit_mizuumi_inputs.sh, tests/audit_extra_pass.sh and tests/audit_mizuumi_attack.sh assert on pristine vsavj under MAME the checks each header's WHAT and EXPECTS list — the inputs gate I1-I8 over +0x124/+0x125/+0x127/+0x12A-+0x12D/+0x394/+0x395/+0x122/+0x123/+0x126/+0x128/+0x129 as predicted by the routine PRG:0x022114-0x0221F6, the extra-pass gate per frame at pinned levels and unpinned, the attack gate A1-A5 over +0x101, +0x1B8, +0x119 and +0x169 — and each re-run at c6454458 on ERIS reads PASS with its log header naming that commit and host (build/agent195/eris_118m2/<gate>.log), with each declared control firing in the normal run and each run as a mode exiting 1 (the __<control>.log files). NOT TESTED: +0x397 (equal to the previous frame's +0x395 on 9531 of 9537 frames, not exactly — not asserted), +0x12E/+0x12F, +0x103 (to be judged at the writes by PRG:0x02758C), +0x167/+0x168, HOMING items 4 and 5, merged-m23 (no merged leg), FBNeo; the lag-120 control is judged only on the four sides whose active frames carry two or more +0x394 values (replay 37's P2 has one); the figures are the pilot's mechanism re-asserted, not compared with the mizuumi wiki beyond the names.
Artifacts (read every one, in full):
  - tests/audit_mizuumi_inputs.sh
  - tests/audit_extra_pass.sh
  - tests/audit_mizuumi_attack.sh
  - tests/replays/118_input_sweep.rpl
  - tests/replays/118_chain.rpl
  - build/agent195/eris_118m2/audit_mizuumi_inputs.log
  - build/agent195/eris_118m2/audit_extra_pass.log
  - build/agent195/eris_118m2/audit_mizuumi_attack.log
  - build/agent195/eris_118m2/audit_extra_pass__other-level.log
  - build/agent195/eris_118m2/audit_extra_pass__unpinned-equals-6.log
  - build/agent195/eris_118m2/audit_mizuumi_attack__cpu-side.log
  - build/agent195/eris_118m2/audit_mizuumi_attack__hit-vs-start.log
  - build/agent195/eris_118m2/audit_mizuumi_attack__hits-shifted.log
  - build/agent195/eris_118m2/audit_mizuumi_attack__isolated-presses.log
  - build/agent195/eris_118m2/audit_mizuumi_attack__neighbour-word.log
  - build/agent195/eris_118m2/audit_mizuumi_attack__previous-press-key.log
  - build/agent195/eris_118m2/audit_mizuumi_inputs__lag-120.log
  - build/agent195/eris_118m2/audit_mizuumi_inputs__no-edge-mask.log
  - build/agent195/eris_118m2/audit_mizuumi_inputs__opposite-flip.log
  - build/agent195/eris_118m2/audit_mizuumi_inputs__wrong-run.log
