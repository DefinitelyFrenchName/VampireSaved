THE PACKET

Decision kind: expectation
Subject: #134: re-freeze the vanilla join-rig expectations after moving the walk-in sets' first event (after runs 225-227)
Claim (the working agent's sentence): Re-freezing tests/expected/vanilla_normal_slots.tsv (eight near-LP rows a2:0x01 -> a2:0x00: BU DE MO FE AU SA LE LI; SA near HP a2:0x04 -> a2:0x05), tests/expected/vanilla_hit_damage.sha256, tests/expected/vanilla_meter_gain.sha256 and tests/expected/community_crosscheck.txt (with its GENERATED page) is correct because the change is (1) tools/vanilla_join_rig.py putting a walk-in set's first event at 2800 instead of 2600, with Lei-Lei's hit_jump j.LK press at +24 instead of +14 — measured at every offset from +10 to +34 (lk_sweep.txt, 25 legs): connects +10, whiffs +11..+16, connects every offset +17..+32, whiffs +33..+34, so +24 has 7 connecting offsets below it and 8 above — and (2) tests/test_rehit_ring.sh reading its JE control window from the rig's schedule instead of the literal 3560-3700 (its gate PASS and both control modes FAIL, rehit_ring*.log): with the first event at 2600 P1's first walk step was f2546, so LP was pressed at 115-134 px where every later event sat at 43-60 px (separations.txt), with 2800 every near-set press sits at 43-60 px, and the f2600 control leg reproduces SA's frozen near rows; the pre-change out-of-tree tables were regenerated at HEAD 8835c4b3 where both gates PASS; the rows that move are only LP rows, SA's HP (59 px -> a2:0x04, 60 px -> a2:0x05), the six VOID meter legs (now 1 hit, BOTH) and ten hit-damage LP rows (0 hits -> 1); the meter table was re-frozen from the +24 rig and verified (meter_freeze24.log, meter_verify24.log); the cross-check moved no verdict, five characters each gaining one compared row; the hits and whiffs were shown to the maintainer as captures through the victim's reaction and read as expected (maintainer_read.txt). NOT tested: the unchanged sets (far, crouch, jump, jump_fwd, jump_down) were not re-measured beyond the gates that read them; SA's HP knife edge is recorded, not stabilised; offsets below +10 and above +34 were not measured (the rig presses inside +17..+32, not at an edge); the captures show j.LK pressed at +18 (inside the band) and at +14, not at +24, and cover two of the moved legs (SA 5LP, LE j.LK), not all sixteen.
Artifacts (read every one, in full):
  - build/agent183/p134_evidence/diff.patch
  - build/agent183/p134_evidence/outoftree_diff.txt
  - build/agent183/p134_evidence/separations.txt
  - build/agent183/p134_evidence/lk_sweep.txt
  - build/agent183/p134_evidence/maintainer_read.txt
  - build/agent183/p134_evidence/p134_captures_strip.png
  - build/agent183/p134g/join_freeze.log
  - build/agent183/p134g/join_verify.log
  - build/agent183/p134g/meter_freeze24.log
  - build/agent183/p134g/meter_verify24.log
  - build/agent183/p134g/crosscheck_freeze.log
  - build/agent183/p134g/rehit_ring.log
  - build/agent183/p134g/rehit_ring_ctl_clear-on-attack-node.log
  - build/agent183/p134g/rehit_ring_ctl_missing-contact.log
  - build/agent183/p134g/audit_df_startup_invuln.log
  - build/agent183/p134g/test_vanilla_aerial_join.log
  - build/agent183/p134_old/join.log
  - build/agent183/p134_old/meter.log
  - DECISIONS_HISTORY.md.lines-30-36 (lines 30-36 of DECISIONS_HISTORY.md)
