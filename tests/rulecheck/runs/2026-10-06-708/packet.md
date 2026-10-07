THE PACKET

Decision kind: expectation
Subject: #230: audit_tenant_throw_geometry re-frozen at the matched level with Pyron and Donovan as throwers
Claim (the working agent's sentence): Re-freeze tests/audit_tenant_throw_geometry.sh for #230: it now runs Pyron's (0x11) and Donovan's (0x13) standard throw beside Phobos's three throws over the same 18 roster victims, pins speed level 06 (from frame 2000) and RNG word 0000 (from frame 2363) on both legs as the 2026-09-25 ruling's equalised input (DECISIONS_HISTORY.md lines 1012-1019), moves every FROZEN tail to (0,0), and adds Pyron's arc set of 12 values with his Sasquatch residue (13,14) and Donovan's arc set {64,68} (gate.diff). Basis: the rewritten gate printed PASS with "CONTROL FIRED: unpinned-level — 18 of 18 victims diverge" on ERIS (ttg_new.log) and on the Mac (ttg_new_mac.log); run as CONTROL=unpinned-level it printed FAIL with the old tails (1, 0) and (0, 1) back (ttg_new_mode.log). Both hosts ran the same gate (sha256 9060b46b, provenance.txt) on the same merged build (set key f601342d on both, provenance.txt), the same three replays and the same replay.lua (provenance.txt). The FROZEN values were copied from the pinned scratch runs (ttg_pin_att11.log, ttg_pin_att13.log, ttg_pin3_att10.log); the unpinned ones (ttg_att11.log, ttg_att13.log) are the before. NOT TESTED: the scratch scripts staged here (ttg_std.sh, ttg_pin3.sh) are their pinned versions — the unpinned runs used ttg_std.sh without its pin line; per-state dwell equality (the gate reports a hold ratio only); Pyron's and Donovan's other throws (kick and air throws); whether the 14z-131 header prose below the SUPERSEDED marker still holds anywhere.
Artifacts (read every one, in full):
  - tests/audit_tenant_throw_geometry.sh
  - build/agent193/t230/gate.diff
  - build/agent193/t230/ttg_new.log
  - build/agent193/t230/ttg_new_mode.log
  - build/agent193/t230/ttg_new_mac.log
  - build/agent193/t230/ttg_att11.log
  - build/agent193/t230/ttg_att13.log
  - build/agent193/t230/ttg_pin_att11.log
  - build/agent193/t230/ttg_pin_att13.log
  - build/agent193/t230/ttg_pin3_att10.log
  - build/agent193/t230/provenance.txt
  - build/agent193/t230/ttg_std.sh
  - build/agent193/t230/ttg_pin3.sh
  - DECISIONS_HISTORY.md.lines-1012-1019 (lines 1012-1019 of DECISIONS_HISTORY.md)
