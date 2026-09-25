THE PACKET

Decision kind: expectation
Subject: 14z-182 #175: freeze tests/expected/trap_air_hit.tsv — the Plasma Trap dome hits an airborne Felicia (j.HP node 4) identically on native vs2 and the merged build
Claim (the working agent's sentence): Freeze the four rows of tests/audit_trap_air_hit.sh as measured: with REAL cursor picks on both legs (P1 Phobos, P2 Felicia 0x07), Felicia x-pinned at 695 and Phobos at 540 over 3470-3489, a neutral jump at 3490 and j.HP at 3508, the dome hits her IN THE AIR at f3521 (y 42, a2:0x14#4, class 0x07) on both legs with every traced field equal over 3500-3530; with j.HP at 3511 she is hit on the landing frame (y 42 -> 40) with 0x52 native / 0x38 ours, equal otherwise; the three controls each reach FAIL on their own check; the maintainer read the capture sheets identical (their words: build/agent182/maintainer_read_175.txt). NOT tested: one character (Felicia), one move (j.HP), one spacing and one press window — no other airborne state or character is run; the per-frame level 6 and RNG 0000 pins and the x pins are shared writes on both legs (the level/RNG pins ruled the equalised input 2026-09-25; the x pins land before the window, 3470-3489, and the traced window starts at 3500); the solo Phobos track is not run; which dome record (5 or 6) is live is read from the node, not asserted; the probe's box resolution relies on the engine_internals encoding and a zero vuln id being no box (measured by breakpoints in this session, not by a gate).
Artifacts (read every one, in full):
  - tests/audit_trap_air_hit.sh
  - tests/expected/trap_air_hit.tsv
  - build/agent182/trap_air_hit_verify.log
  - build/agent182/trap_air_hit_modes.log
  - tools/trap_air_probe.sh
  - tools/trap_air_boxes.py
  - build/agent182/rc_sheet_3508.png
  - build/agent182/maintainer_read_175.txt
