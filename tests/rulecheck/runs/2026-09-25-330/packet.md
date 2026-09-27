THE PACKET

Decision kind: expectation
Subject: #182: freeze tests/expected/air_gc_legacy.tsv — the legacy control, re-checked after runs 328 and 329
Claim (the working agent's sentence): Freeze tests/expected/air_gc_legacy.tsv (175 rows) as measured by FREEZE=1 with tests/audit_air_gc_legacy.sh and verified by a plain re-run (gate_freeze.log, gate_plain.log: PASS). The rig uses real cursor picks, asserted per leg, against P2 = Demitri (0x01), with level 6 and the RNG pinned. The legacy characters are Lei-Lei (0x0d; R, D, DR then button 1) and Zabel (0x04; R, D, DR then button 4), each run on pristine vsavj, native vs2 and the merged WIDE build m3b_merged28 (ours; its fingerprint printed, the vsavjw set named in each ours MAME log). From a ground block (E0) each opens P1's guard window +0x158 and commits a guard cancel (+0x3B5 := 6, written by the commit routine's first instruction: vsavj/ours 0x029C6E, vs2 0x028FA0). From an air block (E1, E2) neither opens the window or commits one, on any leg. Each character's three legs give identical rows once the leg label and the per-game writer-PC rows are dropped. The positive leg: Phobos (0x10; R, D, DR then button 1) on native vs2 with the identical rig opens the window and commits an air guard cancel in E1 and in E2, so the air events are at a timing that can produce one. The command checks (disasm_gc.txt): Zabel's (0x036A6E) and Phobos's (vs2 0x055470) require the window with no fall-through; Lei-Lei's (0x04B3FA) falls through to her plain 623+P, which comes out of an air block with no commit. The maintainer's statements are verbatim in maintainer_14z185.txt: the air guard cancel is Phobos's alone; Zabel's guard cancel is 623+K; and, on the three-leg sheets, "Same, confirmed". Lei-Lei's rig is byte-identical to 14z-184's; Zabel's differs only in the motion's first and last steps (rigcheck.log). Five must-fire controls fire in-gate and FAIL the gate as modes. Rule-checker runs 2026-09-25-328 and -329 found earlier forms VIOLATED; resolve_328.txt and resolve_329.txt say what changed. NOT tested: that buttons 1 and 4 are LP and LK; any other original character; P2 as the character; the left side; any event timing other than the three; FBNeo; Phobos on ours (#182's own gate is tests/audit_chains174.sh); the Mizuumi reading for characters other than these three; the vs2 Dark Force air-GC glitch the maintainer quotes.
Artifacts (read every one, in full):
  - tests/audit_air_gc_legacy.sh
  - tests/expected/air_gc_legacy.tsv
  - build/agent185/air_gc/gate_freeze.log
  - build/agent185/air_gc/gate_plain.log
  - build/agent185/air_gc/gate_air-window-planted.log
  - build/agent185/air_gc/gate_ground-window-removed.log
  - build/agent185/air_gc/gate_air-commit-planted.log
  - build/agent185/air_gc/gate_ground-commit-removed.log
  - build/agent185/air_gc/gate_positive-stripped.log
  - build/agent185/air_gc/rigcheck.sh
  - build/agent185/air_gc/rigcheck.log
  - build/agent185/air_gc/disasm_gc.txt
  - build/agent185/air_gc/sheet/run_ch.sh
  - build/agent185/air_gc/sheet/leilei_gc_sheet_3legs.png
  - build/agent185/air_gc/sheet/zabel_gc_sheet_3legs.png
  - build/agent185/air_gc/maintainer_14z185.txt
  - build/agent185/air_gc/resolve_328.txt
  - build/agent185/air_gc/resolve_329.txt
  - docs/game/engine_internals.md.lines-4775-4833 (lines 4775-4833 of docs/game/engine_internals.md)
