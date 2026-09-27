THE PACKET

Decision kind: expectation
Subject: #174: freeze tests/expected/chains174.tsv — re-check after run 307
Claim (the working agent's sentence): Freeze tests/expected/chains174.tsv as measured by FREEZE=1 with the committed script and verified by a plain re-run (gate_freeze.log, gate_plain.log: 28 rows, PASS): at the parity pins (level 6, RNG) every one of the 12 non-spacer events enters its target chain on native vs2 — Phobos a2:0x4b (Reflect Wall from a crouching block, two), a2:0x50 then a2:0x29 (Genocide Vulcan (ES) catching a jump-in, two), a2:0x4d (Reflect Wall from an air block, two); Donovan a2:0x4f (the ES pursuit off Sword Grapple, the maintainer's setup, two); Pyron a2:0x48 (Piled Hell, three kicks, two), a2:0x03 (6MP far), a2:0x05 (6HP far) — and ours matches native (IDENT) on every event but the two air-block guard cancels (events 6 and 7), which read DIFF at the guard-cancel frame (+30, +32): #182, frozen AS THE DEFECT — those two events captured and read by the maintainer ('Same difference', air_gc_frozen_sheet.png; an earlier timing read first: 'Indeed there's a difference, the GC doesn't trigger or if it does it doesn't resolve'); mechanism in legacy_and_phobos_taps.txt and engine_internals.md. Two SPACER events keep phase-sensitive events on their measured frames (the rig file says why); the entry check skips them. Both must-fire controls fire in-gate and FAIL the gate as modes (gate_wrong-target.log, gate_x-moved.log). NOT tested: the entries hold only at these frames (phase-sensitive: a schedule change can un-enter them — the entry check would then FAIL, not pass silently); the second air event's DIFF row is coupled after the first (after:6); ours' own chain entry is not checked separately (the parity verdict compares its translated node frame by frame); level 6 only; the tenant as P1 only, P2 Demitri only; the ES pursuit only off Sword Grapple [HP] with KK; the Phobos mechanism taps (tapgc) were taken on an earlier ordering of the same rig; the 28 non-attack never-entered a2 starts and tables a, b and c.
Artifacts (read every one, in full):
  - tests/audit_chains174.sh
  - tools/chains174_rigs.py
  - tests/expected/chains174.tsv
  - build/agent184/t174/gate_freeze.log
  - build/agent184/t174/gate_plain.log
  - build/agent184/t174/gate_wrong-target.log
  - build/agent184/t174/gate_x-moved.log
  - build/agent184/t174/legacy_and_phobos_taps.txt
  - build/agent184/t174/captures_sent.txt
  - build/agent184/t174/air_gc_sheet.png
  - build/agent184/t174/air_gc_frozen_sheet.png
  - docs/game/engine_internals.md.lines-4765-4798 (lines 4765-4798 of docs/game/engine_internals.md)
