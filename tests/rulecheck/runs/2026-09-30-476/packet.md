THE PACKET

Decision kind: recommendation
Subject: open a ticket: tools/move_parity.py compares P2's HP word +0x50 but not the white word +0x52, so the ours-vs-native gates cannot see a white-word-only damage difference (after runs 2026-09-30-473 to -475)
Claim (the working agent's sentence): tools/move_parity.py's compared fields (TENANT_FIELDS, EVENT_FIELDS, CUMULATIVE, FIELD_ADDR) name p1hp and p2hp and the file names the white HP word +0x52 under none of three case-insensitive spellings (ff8852, white, 0x52: 0 each) while the same search form finds 0xFF8850 twice (white_hp_evidence.txt section 5); the gates whose non-comment lines run its per-event comparison, found by the grep shown over tests/*.sh (section 2), are tests/audit_chains174.sh:167, tests/audit_chains184.sh:185 and tests/audit_move_parity.sh:289, and each traces P2's HP as ff8850:w, the 16-bit word at +0x50 alone (section 9; audit_chains184 also traces ff8852 but for its outcome check); the gap is not hypothetical: on native vs2 (hui_hp/run.sh names the set, the rig and every traced address; P1 Phobos id 16, P2 Demitri id 1), in the rig's event 0 (frames 2795 up to 3000), P2's HP words fall on five frames — both at 2804 and 2816, and the white word $FF8852 alone at 2885, 2890 and 2896 (to 257, 255 and 254) while $FF8850 stays 272 (section 7); the maintainer ruled it a ticket, quoted verbatim in DECISIONS_HISTORY.md; this justifies a ticket to add +0x52 to the comparator and re-run the gates that use it; NOT tested: which hit each fall belongs to (P2's hit-reaction entries are listed separately, section 8), the trace's later events, a caller outside tests/*.sh or reached by a path the grep does not match, whether any frozen parity row hides a +0x52-only difference, the same trace on ours, other characters' white-word-only hits, and which move classes damage the white word alone.
Artifacts (read every one, in full):
  - build/agent186/white_hp_evidence.txt
  - build/agent186/white_hp_evidence.sh
  - build/agent186/hui_hp/run.sh
  - build/agent186/hui_hp/f.ft
  - tools/move_parity.py.lines-82-101 (lines 82-101 of tools/move_parity.py)
  - tests/audit_move_parity.sh.lines-285-292 (lines 285-292 of tests/audit_move_parity.sh)
  - tests/audit_chains174.sh.lines-164-170 (lines 164-170 of tests/audit_chains174.sh)
  - tests/audit_chains184.sh.lines-182-188 (lines 182-188 of tests/audit_chains184.sh)
  - tests/replays/chains184/huitzil_c184.json
  - DECISIONS_HISTORY.md.lines-30-40 (lines 30-40 of DECISIONS_HISTORY.md)
