THE PACKET

Decision kind: expectation
Subject: 14z-182 #175 (after run 219): freeze tests/expected/trap_air_hit.tsv — the Plasma Trap dome hits an airborne Felicia identically on native vs2 and the merged build; her own-data hurtbox differences charged per node
Claim (the working agent's sentence): Freeze the four rows of tests/audit_trap_air_hit.sh as measured: with REAL cursor picks on both legs (P1 Phobos, P2 Felicia 0x07), Felicia x-pinned at 695 and Phobos at 540 over 3470-3489, a neutral jump at 3490 and j.HP at 3508, the dome hits her IN THE AIR at f3521 (y 42, a2:0x14#4, class 0x07) on both legs; every compared field (position, HP, class, freeze, sequence, family ids, node, facing, resolved hurtboxes, the dome's type/record/box extents, Phobos's x/HP/freeze) is equal over 3500-3530 except her hurtboxes on frames whose node has DIFFERENT static boxes in the two games' Felicia data — her b:0x0f head box, f3522 on — which are charged to her own data and frozen per leg (the victim is each game's own Felicia); the air-hit frame's boxes are compared strictly and equal; with j.HP at 3511 she is hit on the landing frame with 0x52 native / 0x38 ours, equal otherwise; five controls each reach FAIL on their own check; the maintainer read both capture sheets identical (their words and the rulings cited: build/agent182/maintainer_read_175.txt). NOT tested: one character (Felicia), one move (j.HP), one spacing and one press window — no other airborne state or character is run; the per-frame level 6 and RNG 0000 pins and the x pins are shared writes on both legs (the level/RNG pins ruled the equalised input; the x pins land before the window, 3470-3489, the traced window starts at 3500); the solo Phobos track is not run; the dome's pool SLOT index and the node ADDRESSES are not compared (they differ by build by construction; the record index and box are); the probe's box resolution relies on the engine_internals encoding and a zero vuln id being no box (measured by breakpoints in this session, not by a gate); the per-node charge rests on tools/anim_nodes.py walking both images' chains the same way.
Artifacts (read every one, in full):
  - tests/audit_trap_air_hit.sh
  - tests/expected/trap_air_hit.tsv
  - build/agent182/tah_verify.log
  - build/agent182/tah_mode_box-drift.log
  - build/agent182/tah_mode_dome-drift.log
  - tools/trap_air_probe.sh
  - tools/trap_air_boxes.py
  - build/agent182/rc_sheet_3508.png
  - build/agent182/rc_sheet_3511.png
  - build/agent182/maintainer_read_175.txt
