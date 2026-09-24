THE PACKET

Decision kind: expectation
Subject: 14z-180 #171 slice Q6: freezing tests/expected/poke_readback.tsv — the 74 findings of tools/audit_poke_readback.py (a gate that samples an address its own rig pokes) over 31 of the 199 emulator gates, one row each, classed READS-BACK for the killshread stock column by the maintainer's 2026-09-22 ruling and UNCLASSIFIED for the other 73, with the rulings put on STATE's Decisions pending as one item
Claim (the working agent's sentence): Every finding in the table is derived by the tool from the gate's text and the schedules its rig generators emit — a poked byte range overlapping a sampled one — and the table carries exactly the derived set (the gate joins them both ways, and its two controls show a removed sample and a planted poke-and-sample pair each move the census); the one classification given, READS-BACK for test_killshread_es's stock column over name_moves' ff8509 top-up, rests on the maintainer's own words of 2026-09-22 quoted in the ruling record, and every other row is UNCLASSIFIED because the classification is the maintainer's, not the tool's — the pending item RECOMMENDS a rule per poke family and decides nothing. NOT tested: the census's reach is its regexes and the two generators — a poke or sample whose address is composed from a variable with no literal in the script, an address a reducer reads from a dump after the fact, and the -debug watchpoint scripts' addresses are outside it, so the 74 is a floor on the true count, not the count; a gate that loops over rig parts is credited with every part of the tenants its text names, which can over-report pokes it never issues; the first census counted rig pokes one byte wide and found 72, the width fix found 2 more (a 4-byte HP pin also covers the white-HP word), and a third such blind spot would show the same way — as a later growth, not a red; whether any UNCLASSIFIED column actually changes a gate's verdict is exactly what the ruling decides and is not measured here.
Artifacts (read every one, in full):
  - tools/audit_poke_readback.py
  - tests/test_poke_readback.sh
  - tests/expected/poke_readback.tsv
  - build/gatequal180/q6_evidence_14z180.txt
  - build/gatequal180/ruling_killshread_2026-09-22.txt
  - tests/test_killshread_es.sh
  - tools/name_moves.py
  - tests/expected/PROVENANCE.md
  - docs/project/gate_qualification_scope.md
  - STATE.md
