THE PACKET

Decision kind: expectation
Subject: #182: freeze tests/expected/air_gc_legacy.tsv — the legacy control, re-checked after run 328
Claim (the working agent's sentence): Freeze tests/expected/air_gc_legacy.tsv (150 rows) as measured by FREEZE=1 with tests/audit_air_gc_legacy.sh and verified by a plain re-run (gate_freeze.log, gate_plain.log: PASS). The rig: P1 = Lei-Lei (0x0d; R, D, DR then button 1) and then Zabel (0x04; R, D, DR then button 4) against P2 = Demitri (0x01), by real cursor picks asserted per leg; level 6 and the RNG pinned; run on pristine vsavj, native vs2 and the merged WIDE build m3b_merged28, whose fingerprint is printed and whose vsavjw set is named in each ours MAME log. The result: from a ground block (E0) each character opens P1's guard window +0x158 and commits a guard cancel, +0x3B5 := 6, written on every leg by the commit routine's first instruction (vsavj/ours 0x029C6E, vs2 0x028FA0; disasm_gc.txt); from an air block (E1, E2) neither character opens the window or commits a guard cancel on any leg; and each character's three legs give identical rows once the leg label and the per-game writer-PC rows are dropped. Lei-Lei's 623+P from an air block still comes out, with no commit: sequence 0x0E while she is still airborne and air-blocking (probe_gc/out/ft_*.txt), through her check's no-window branch (disasm_gc.txt). The capture sheets show the GUARD CANCEL banner on the ground only, on both games. They were sent to the maintainer, whose answer (maintainer_14z185.txt) is that the air guard cancel is Phobos's alone and that Zabel's guard cancel is 623+K. Lei-Lei's rig is byte-identical to 14z-184's, and Zabel's differs only in the motion's first and last steps (rigcheck.log). Four must-fire controls fire in-gate and FAIL the gate as modes. Rule-checker run 2026-09-25-328 found the earlier form of this freeze VIOLATED; resolve_328.txt says what changed. NOT tested: that buttons 1 and 4 are LP and LK; any other original character; P2 as the character; the left side; any event timing other than the three; FBNeo; the Mizuumi reading for characters other than these three; the vs2 Dark Force air-GC glitch the maintainer quotes.
Artifacts (read every one, in full):
  - tests/audit_air_gc_legacy.sh
  - tests/expected/air_gc_legacy.tsv
  - build/agent185/air_gc/gate_freeze.log
  - build/agent185/air_gc/gate_plain.log
  - build/agent185/air_gc/gate_air-window-planted.log
  - build/agent185/air_gc/gate_ground-window-removed.log
  - build/agent185/air_gc/gate_air-commit-planted.log
  - build/agent185/air_gc/gate_ground-commit-removed.log
  - build/agent185/air_gc/rigcheck.sh
  - build/agent185/air_gc/rigcheck.log
  - build/agent185/air_gc/disasm_gc.txt
  - build/agent185/air_gc/probe_gc/run.sh
  - build/agent185/air_gc/probe_gc/out/ft_vsavj.txt
  - build/agent185/air_gc/probe_gc/out/ft_vsav2.txt
  - build/agent185/air_gc/sheet/run_ch.sh
  - build/agent185/air_gc/sheet/leilei_gc_sheet.png
  - build/agent185/air_gc/sheet/zabel623k_gc_sheet.png
  - build/agent185/air_gc/maintainer_14z185.txt
  - build/agent185/air_gc/resolve_328.txt
  - docs/game/engine_internals.md.lines-4775-4830 (lines 4775-4830 of docs/game/engine_internals.md)
