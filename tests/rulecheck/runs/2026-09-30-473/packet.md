THE PACKET

Decision kind: recommendation
Subject: open a ticket: tools/move_parity.py compares P2's HP word +0x50 but not the white word +0x52, so the ours-vs-native gates cannot see a white-word-only damage difference
Claim (the working agent's sentence): tools/move_parity.py's compared fields (TENANT_FIELDS, EVENT_FIELDS, FIELD_ADDR) name p1hp and p2hp, the +0x50 words at $FF8450 and $FF8850, and nowhere name the white HP word +0x52 (white_hp_evidence.txt, a grep count of 0); the gates whose code runs its per-event comparison (move_parity.py events) are tests/audit_move_parity.sh, tests/audit_chains174.sh and the new tests/audit_chains184.sh, each read line by line; and the gap is not hypothetical: on native vs2 Phobos's Sitting Attack after a sweep takes P2's +0x52 from 259 to 257, 255 and 254 over three hits while +0x50 stays 272 (hui_hp/f.ft, the event's trace); the maintainer ruled it a ticket, quoted verbatim in DECISIONS_HISTORY.md; this justifies a ticket to add +0x52 to the comparator and re-run the gates that use it; NOT tested: whether any existing frozen parity row hides a +0x52-only difference, the same trace on ours, other characters' white-word-only hits, and which move classes damage the white word alone.
Artifacts (read every one, in full):
  - build/agent186/white_hp_evidence.txt
  - tools/move_parity.py.lines-82-101 (lines 82-101 of tools/move_parity.py)
  - build/agent186/hui_hp/f.ft
  - tests/audit_move_parity.sh.lines-285-292 (lines 285-292 of tests/audit_move_parity.sh)
  - tests/audit_chains174.sh.lines-164-170 (lines 164-170 of tests/audit_chains174.sh)
  - DECISIONS_HISTORY.md.lines-30-40 (lines 30-40 of DECISIONS_HISTORY.md)
