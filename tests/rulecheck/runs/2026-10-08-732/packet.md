THE PACKET

Decision kind: expectation
Subject: #118: three emulator gates (audit_mizuumi_inputs, audit_extra_pass, audit_mizuumi_attack) after runs 2026-10-08-729, -730 and -731, at 5fd10686
Claim (the working agent's sentence): CLAIM: the three gates assert on pristine vsavj under MAME the checks each header's WHAT and EXPECTS list (inputs I1-I8 and I10 as the routine PRG:0x022114-0x0221F6 predicts them; the extra pass E1 per frame, one activation told from two by $FF8118, at pinned levels 0/6/8/14 and unpinned; attack A1-A5, A2 pairing each attack start with its +0x1B8 write in time and A4 counting the 0xFF rises at the chained starts), and the re-run at 5fd10686 on ERIS reads PASS for each, its log header naming that commit and host (build/agent195/eris_118m4/<gate>.log, exit in <gate>.rc), each declared control firing in the normal run and each run as a mode exiting 1 (<gate>__<control>.rc) — a dead mode prints REFUSED and exits 3 instead. NOT TESTED: everything each header lists under NOT COVERED — I2's flip-source rule against plain +0x0B (the +0x120 branch is reached on 03 P1 but never with L or R held, so a wrong rule would pass), +0x397 (equal to the previous frame's +0x395 on 9531 of 9537 frames, not exactly), +0x12E/+0x12F, +0x103 (to be judged at the writes by PRG:0x02758C), +0x167/+0x168, levels other than 0/6/8/14, what sets the turbo-pass flag $FF812D, merged-m23, FBNeo — plus A4's transient 0xFF writes to +0x119 by other PCs (reported by PC, not asserted), what the game does with each word, and the lag-120 control judged only on the four sides that carry two or more +0x394 values; HOMING items 4 and 5; the figures are the pilot's mechanism re-asserted, not compared with the mizuumi wiki beyond the names.
Artifacts (read every one, in full):
  - tests/audit_mizuumi_inputs.sh
  - tests/audit_extra_pass.sh
  - tests/audit_mizuumi_attack.sh
  - tests/replays/118_input_sweep.rpl
  - tests/replays/118_chain.rpl
  - build/agent195/eris_118m4/audit_extra_pass.log
  - build/agent195/eris_118m4/audit_extra_pass__other-level.log
  - build/agent195/eris_118m4/audit_extra_pass__unpinned-equals-6.log
  - build/agent195/eris_118m4/audit_mizuumi_attack.log
  - build/agent195/eris_118m4/audit_mizuumi_attack__cpu-side.log
  - build/agent195/eris_118m4/audit_mizuumi_attack__hit-vs-start.log
  - build/agent195/eris_118m4/audit_mizuumi_attack__hits-shifted.log
  - build/agent195/eris_118m4/audit_mizuumi_attack__isolated-presses.log
  - build/agent195/eris_118m4/audit_mizuumi_attack__neighbour-word.log
  - build/agent195/eris_118m4/audit_mizuumi_attack__previous-press-key.log
  - build/agent195/eris_118m4/audit_mizuumi_attack__reads-shifted.log
  - build/agent195/eris_118m4/audit_mizuumi_attack__writes-shifted.log
  - build/agent195/eris_118m4/audit_mizuumi_inputs.log
  - build/agent195/eris_118m4/audit_mizuumi_inputs__lag-120.log
  - build/agent195/eris_118m4/audit_mizuumi_inputs__no-edge-mask.log
  - build/agent195/eris_118m4/audit_mizuumi_inputs__opposite-flip.log
  - build/agent195/eris_118m4/audit_mizuumi_inputs__wrong-run.log
  - build/agent195/eris_118m4/audit_extra_pass.rc
  - build/agent195/eris_118m4/audit_extra_pass__other-level.rc
  - build/agent195/eris_118m4/audit_extra_pass__unpinned-equals-6.rc
  - build/agent195/eris_118m4/audit_mizuumi_attack.rc
  - build/agent195/eris_118m4/audit_mizuumi_attack__cpu-side.rc
  - build/agent195/eris_118m4/audit_mizuumi_attack__hit-vs-start.rc
  - build/agent195/eris_118m4/audit_mizuumi_attack__hits-shifted.rc
  - build/agent195/eris_118m4/audit_mizuumi_attack__isolated-presses.rc
  - build/agent195/eris_118m4/audit_mizuumi_attack__neighbour-word.rc
  - build/agent195/eris_118m4/audit_mizuumi_attack__previous-press-key.rc
  - build/agent195/eris_118m4/audit_mizuumi_attack__reads-shifted.rc
  - build/agent195/eris_118m4/audit_mizuumi_attack__writes-shifted.rc
  - build/agent195/eris_118m4/audit_mizuumi_inputs.rc
  - build/agent195/eris_118m4/audit_mizuumi_inputs__lag-120.rc
  - build/agent195/eris_118m4/audit_mizuumi_inputs__no-edge-mask.rc
  - build/agent195/eris_118m4/audit_mizuumi_inputs__opposite-flip.rc
  - build/agent195/eris_118m4/audit_mizuumi_inputs__wrong-run.rc
