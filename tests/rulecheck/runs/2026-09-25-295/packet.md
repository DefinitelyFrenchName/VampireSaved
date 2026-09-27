THE PACKET

Decision kind: recommendation
Subject: #177: recommend closing as invalid — the movement comparison it asks for already exists (audit_move_parity's part-1 events), and the maintainer confirmed the movement on captures
Claim (the working agent's sentence): Recommend closing #177 as invalid: its premise (the 14z-182 finding 'no gate compares a tenant's movement with native vsav2 ... the parity gate compares x/y only inside move events') is refuted by the tree — tests/audit_move_parity.sh compares the tenant's own state (node, seq, sub-state, counter, x, y, stock, facing, DF flag, HP, meter) every frame of each event's window against native vs2, with real cursor picks, the level pinned to 6 and the RNG pinned (#136's method), and the movements are events of it: every movement entry of the three move lists (walk forward, walk back, jump, forward dash, back dash; Phobos's air dash and float) is run in part 1 of each tenant (Walk forward, Walk back, Crouch, Jump [8], Jump [9], Jump [7], Forward dash, Back dash; Phobos also five Air Dashes and four Floats), and every one of those events is frozen IDENT; captures of each (walks both ways, all three jumps, both dashes, Phobos's air dash and float, and the neutral jump every 2 frames from take-off to landing, native above ours on the same frames with the gate's rig and pins) were put before the maintainer, who confirmed the same movement on all of them. The live carrier of the wrong premise (docs/project/coverage_matrix.md's MOVEMENT clause) is to be corrected and the archived 14z-182 finding marked in place. NOT tested: movement inside Dark Force or in Donovan's swordless state beyond 'Forward dash swordless' (IDENT) — Phobos's DF hover is his Ray of Doom, compared by the Dark Force gates, not base movement; the tenant as P2 (the rigs put the tenant at P1); stages other than the rig's; the captures sample every 2 to 10 frames while the gate compares every frame.
Artifacts (read every one, in full):
  - tests/audit_move_parity.sh.lines-1-45 (lines 1-45 of tests/audit_move_parity.sh)
  - build/agent184/t177/census.txt
  - tools/name_moves.py.lines-250-262 (lines 250-262 of tools/name_moves.py)
  - tools/name_moves.py.lines-464-469 (lines 464-469 of tools/name_moves.py)
  - tools/name_moves.py.lines-524-535 (lines 524-535 of tools/name_moves.py)
  - build/agent184/t177/captures_sent.txt
  - build/agent184/t177/movement_sheet.png
  - build/agent184/t177/phobos_air_sheet.png
  - build/agent184/t177/movement2_donovan.png
  - build/agent184/t177/movement2_huitzil.png
  - build/agent184/t177/movement2_pyron.png
  - build/agent184/t177/jump8_donovan.png
  - build/agent184/t177/jump8_huitzil.png
  - build/agent184/t177/jump8_pyron.png
  - docs/project/coverage_matrix.md.lines-30-30 (lines 30-30 of docs/project/coverage_matrix.md)
  - DECISIONS_HISTORY.md.lines-158-158 (lines 158-158 of DECISIONS_HISTORY.md)
