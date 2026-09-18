THE PACKET

Decision kind: recommendation
Subject: 14z-167: file a ticket - tenant attack records with facing rule +0xE = 5 are XORed into the victim's facing by vsavj's hit code (Killshread Summon (ES) moves Demitri on native only)
Claim (the working agent's sentence): On merged-m18 against native vsav2, on the parity gate's own rig for donovan_3 (tests/replays/naming/donovan_3.json and .rpl, the gate's pokes_for/rpl_for, real cursor picks on both legs, P2 Demitri), Killshread Summon (ES) (event 5, frame 3840) contacts Demitri six times (3882, 3885, 3887, 3919, 3921, 3924). At each contact both engines first seed the victim's facing +0x5D from the attacker's +0xB (vs2 0x17178, vsavj 0x1884E, value 1); native then resolves the record's facing rule +0xE = 5 at vs2 0x171E0 (the branch 0x171D6-0x171E4, 'by the attacker's velocity sign') to 1 on the first wave and 0 on the second, while ours reaches vsavj's resolver at 0x18854, which tests rules 2, 3 and 4 only, and XORs the 5 into the byte at 0x1886C, writing 4 at every contact (a non-debug write tap of RAM:$FF885C-D with writer PCs, facetap/native/tap.txt and facetap/ours/tap.txt; facing_resolvers_disasm.txt). After the last contact (3924, the class 0x16 hit that tests/expected/killshread_es.txt records at +88) native Demitri's x goes 835 -> 755 by 3945 with the camera RAM:$FF8290 following 475 -> 435, and ours stays at 835 with the camera at 475 (the per-frame traces, lines 3870-3960). The capture went to the maintainer BEFORE this conclusion (cap_d3/DELIVERED.txt, times and questions logged); the maintainer first read the 3928-3970 sheet as "looks identical both sprites and GUI", then, on a crop of 3900 and 4040: "But looking at the background it does seems that VS2 has demitri going forward while our Demitri stays in place." Donovan's extracted projectile records 0xD0E02-0xD0F02 carry +0xE = 5 (donovan_rule5_records.tsv). PROPOSED ACTION: file a GitHub ticket (bug) stating that tenant attack records carrying facing rule 5 are resolved by vsavj's hit code as an XOR, with this mechanism and reproduction; no fix is proposed. NOT tested: which code turns +0x5D into Demitri's displacement - the pushback step table is excluded only because its index +0x59 (2) and counter +0x164 (0) and the velocity +0x40 are equal on both legs, and the mover itself is not identified; whether the other rule-5 records (0xCA1CA/0xCA1EA in Donovan's attack table, 0xD17C2/0xD1822 in the projectile region) produce any visible difference; the decoder reads past the projectile region's real records, so the rule-5 list is not a census and Phobos's two attack records with +0xE = 0x0B and Pyron's two with rule 4 are unexamined; no legacy control (whether any vsavj legacy record carries rule 5, or what vsav2's legacy characters do with it, is unmeasured); the capture shows the displacement, not the facing byte; one rig, one character pair, one host; no shipped ROM byte moved.
Artifacts (read every one, in full):
  - build/x_family_14z167/facetap/native/tap.txt
  - build/x_family_14z167/facetap/ours/tap.txt
  - build/x_family_14z167/facing_resolvers_disasm.txt
  - build/x_family_14z167/keep/tr_donovan_3_native.txt.lines-1571-1661 (lines 1571-1661 of build/x_family_14z167/keep/tr_donovan_3_native.txt)
  - build/x_family_14z167/keep/tr_donovan_3_ours.txt.lines-1571-1661 (lines 1571-1661 of build/x_family_14z167/keep/tr_donovan_3_ours.txt)
  - build/x_family_14z167/donovan_rule5_records.tsv
  - build/x_family_14z167/cap_d3/DELIVERED.txt
  - build/x_family_14z167/cap_d3/killshread_demitri_position_crop.png
  - build/x_family_14z167/cap_d3/donovan_3_killshread_summon_sheet.png
  - tests/expected/killshread_es.txt
  - tests/replays/naming/donovan_3.json
  - tests/replays/naming/donovan_3.rpl
  - tests/audit_move_parity.sh.lines-130-200 (lines 130-200 of tests/audit_move_parity.sh)
  - build/x_family_14z167/audit_move_parity_keep.sh.lines-171-172 (lines 171-172 of build/x_family_14z167/audit_move_parity_keep.sh)
  - docs/game/engine_internals.md.lines-1036-1040 (lines 1036-1040 of docs/game/engine_internals.md)
  - docs/game/engine_internals.md.lines-975-990 (lines 975-990 of docs/game/engine_internals.md)
