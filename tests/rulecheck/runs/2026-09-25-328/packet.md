THE PACKET

Decision kind: expectation
Subject: #182: freeze tests/expected/air_gc_legacy.tsv — the legacy control promoted into tests/audit_air_gc_legacy.sh
Claim (the working agent's sentence): Freeze tests/expected/air_gc_legacy.tsv (78 rows) as measured by FREEZE=1 with tests/audit_air_gc_legacy.sh and verified by a plain re-run of the same script (gate_freeze.log, gate_plain.log: PASS): with P1 = Lei-Lei (0x0d; the motion R, D, DR then button 1) and then Zabel (0x04; L, D, DL then button 4) against P2 = Demitri (0x01), picked by real cursor paths from each game's decoded wheel (ours driven by vsavj's paths) and the picked ids asserted on every leg, level 6 and the RNG pinned, on pristine vsavj, native vs2 and the merged WIDE build m3b_merged28 (ours), the ground-block event E0 opens P1's guard window +0x158 on every leg (11 non-zero writes for Lei-Lei, 14 for Zabel) and neither air-block event E1/E2 writes a non-zero +0x158 on any leg; each character's three legs give identical rows once the leg label is dropped; Lei-Lei's command +0x106 := 0x06 is written in E0, E1 and E2 on every leg. The gate's rigs are byte-identical to the 14z-184 rigs of build/agent184/t174/legacy/run.sh (rigcheck.log). Three must-fire controls fire in-gate and FAIL the gate as modes (gate_air-window-planted.log, gate_ground-window-removed.log, gate_gc-dropped.log). NOT tested: that Zabel's rig performs a guard cancel (his E0 window expires with no +0x106 write, and his air events enter sequence 0x0A then 0x06 with no +0x106 write, identically on every leg); that the button numbers are the P and K the maintainer named (the rig's inputs are copied from run.sh, not re-derived); any other original character; P2 as the character; the left side; any event timing other than the three; FBNeo.
Artifacts (read every one, in full):
  - tests/audit_air_gc_legacy.sh
  - tests/expected/air_gc_legacy.tsv
  - build/agent185/air_gc/gate_freeze.log
  - build/agent185/air_gc/gate_plain.log
  - build/agent185/air_gc/gate_air-window-planted.log
  - build/agent185/air_gc/gate_ground-window-removed.log
  - build/agent185/air_gc/gate_gc-dropped.log
  - build/agent185/air_gc/rigcheck.sh
  - build/agent185/air_gc/rigcheck.log
  - build/agent184/t174/legacy/run.sh
  - docs/game/engine_internals.md.lines-4775-4798 (lines 4775-4798 of docs/game/engine_internals.md)
