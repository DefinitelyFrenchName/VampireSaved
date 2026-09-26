THE PACKET

Decision kind: expectation
Subject: #134: re-freeze the vanilla join-rig expectations after moving the walk-in sets' first event
Claim (the working agent's sentence): Re-freezing tests/expected/vanilla_normal_slots.tsv (eight near-LP rows a2:0x01 -> a2:0x00: BU DE MO FE AU SA LE LI; SA near HP a2:0x04 -> a2:0x05), tests/expected/vanilla_hit_damage.sha256, tests/expected/vanilla_meter_gain.sha256 and tests/expected/community_crosscheck.txt (with its GENERATED page) is correct because the ONLY rig change is tools/vanilla_join_rig.py putting a walk-in set's first event at 2800 instead of 2600 (plus Lei-Lei's hit_jump j.LK press at +18 instead of +14): with the first event at 2600 P1's first walk step was f2546, so LP was pressed at 124-134 px where every later event sat at 43-60 px (separations.txt), with 2800 every near-set press sits at 43-60 px, and the f2600 control leg reproduces SA's frozen near rows; the pre-change out-of-tree tables were regenerated at HEAD 8835c4b3 where both gates PASS, and the rows that move are only LP rows, SA's HP (59 px -> a2:0x04, 60 px -> a2:0x05), the six VOID meter legs (now 1 hit, BOTH) and ten hit-damage LP rows (0 hits -> 1); the cross-check moved no verdict, five characters each gaining one compared row. NOT tested: the unchanged sets (far, crouch, jump, jump_fwd, jump_down) were not re-measured beyond the gates that read them; SA's HP knife edge is recorded, not stabilised; the j.LK +18 is a rig choice inside the measured connecting band +18..+30, and +10 also connects.
Artifacts (read every one, in full):
  - build/agent183/p134_evidence/diff.patch
  - build/agent183/p134_evidence/outoftree_diff.txt
  - build/agent183/p134_evidence/separations.txt
  - build/agent183/p134_evidence/lk_sweep.txt
  - build/agent183/p134g/join_freeze.log
  - build/agent183/p134g/join_verify.log
  - build/agent183/p134g/meter_freeze.log
  - build/agent183/p134g/meter_verify.log
  - build/agent183/p134g/crosscheck_freeze.log
  - build/agent183/p134g/audit_df_startup_invuln.log
  - build/agent183/p134g/test_vanilla_aerial_join.log
  - build/agent183/p134_old/join.log
  - build/agent183/p134_old/meter.log
  - DECISIONS_HISTORY.md.lines-30-36 (lines 30-36 of DECISIONS_HISTORY.md)
