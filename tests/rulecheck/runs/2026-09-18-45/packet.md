THE PACKET

Decision kind: recommendation
Subject: 14z-167b close, checklist step 6: every finding of the continuation has a live home
Claim (the working agent's sentence): Close checklist step 6 at the 14z-167b continuation close. Findings table - every finding of the 14z-167b rows (STATE.md lines 57 and 59) and its live home: the round-start entrance as a game fact -> docs/game/engine_internals.md 'The round-start ENTRANCE and the round start'; the facing seed at vs2 0x17178 / vsavj 0x1884E and vs2's rule-5 write at 0x171E0 -> docs/game/atlas/ram.md's +0x5D row; vsavj's meter adder 0x29A16 (a 14z-166 finding found homeless by the tool) -> engine_internals's +0x14 row; the byte-only tap filter -> docs/project/gotchas.md 'A BYTE-ONLY MASK FILTER'; a new gate taking decrypted views from the cache helper -> docs/project/gotchas.md 'A NEW GATE THAT READS A DECRYPTED VIEW'; the rule-checker's run-id collision -> docs/project/rule_checker.md's model paragraph and #160; P2's x not being a compared field -> tests/audit_move_parity.sh's WHAT IT DOES NOT COVER; field_trace.lua writing no END line -> tests/audit_rig_opening.sh's header; tools/close_findings.py's blind spot, its gaps-only output and its REVIEW list -> the tool's own docstring (OUTPUT, WHAT IT CANNOT SEE) and DECISIONS_HISTORY.md 'Ruled 2026-09-18 (14z-167b)'; the checklist's rulings -> DECISIONS_HISTORY.md, STATE's standing line, and the pending entry for where it lives. Step 2: tools/close_findings.py 14z-167 reports no GAP and one REVIEW, $FF8081 - answered: it is the cnt-family observation, an unattributed first look carried by #136's comment and NEXT_SESSION, not yet a finding with a home (named as such in the group). Step 3: 14z-166's row (8) and banner carry pointers to run 41. Step 4: the promise grep over the group and runs 37-44's resolutions finds one commitment ('stated so from here on', run 41), fulfilled in engine_internals's legacy paragraph. NOT tested: whether each home states its finding correctly - this claims presence; the table is the working agent's own enumeration of the two rows.
Artifacts (read every one, in full):
  - STATE.md.lines-57-59 (lines 57-59 of STATE.md)
  - docs/game/engine_internals.md.lines-4264-4281 (lines 4264-4281 of docs/game/engine_internals.md)
  - docs/game/engine_internals.md.lines-1039-1043 (lines 1039-1043 of docs/game/engine_internals.md)
  - docs/game/engine_internals.md.lines-3105-3116 (lines 3105-3116 of docs/game/engine_internals.md)
  - docs/game/atlas/ram.md.lines-163-163 (lines 163-163 of docs/game/atlas/ram.md)
  - docs/project/gotchas.md.lines-5046-5079 (lines 5046-5079 of docs/project/gotchas.md)
  - docs/project/rule_checker.md.lines-185-198 (lines 185-198 of docs/project/rule_checker.md)
  - tests/audit_move_parity.sh.lines-78-90 (lines 78-90 of tests/audit_move_parity.sh)
  - tests/audit_rig_opening.sh.lines-1-30 (lines 1-30 of tests/audit_rig_opening.sh)
  - tools/close_findings.py.lines-1-40 (lines 1-40 of tools/close_findings.py)
  - DECISIONS_HISTORY.md.lines-30-40 (lines 30-40 of DECISIONS_HISTORY.md)
  - STATE.md.lines-98-100 (lines 98-100 of STATE.md)
  - STATE.md.lines-158-166 (lines 158-166 of STATE.md)
