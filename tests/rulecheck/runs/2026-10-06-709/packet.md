THE PACKET

Decision kind: expectation
Subject: #230: audit_tenant_throw_geometry re-frozen at the matched level with Pyron and Donovan as throwers (after run 708)
Claim (the working agent's sentence): Re-freeze tests/audit_tenant_throw_geometry.sh for #230, after rule-checker run 2026-10-06-708 (VIOLATED Q1 Q4, resolved by work): it now runs Pyron's (0x11) and Donovan's (0x13) standard throw beside Phobos's three throws over the same 18 roster victims, pins speed level 06 (from frame 2000) and RNG word 0000 (from frame 2363) on both legs as the 2026-09-25 ruling's equalised input (DECISIONS_HISTORY.md lines 1012-1019), moves every FROZEN tail to (0,0), adds Pyron's arc set of 12 values with his Sasquatch residue (13,14) and Donovan's arc set {64,68}, and asserts on every captured frame that the attacker is the named thrower in one frozen seq per throw (Phobos 2, 14, 16; Pyron 2; Donovan 4) (gate.diff). Basis: the final gate printed PASS with five attacker-seq ok lines (ttg_final.log lines quoting "the attacker is 0x10 in seq [2]" and so on) and "CONTROL FIRED: unpinned-level — 18 of 18 victims diverge" on ERIS (ttg_final.log) and on the Mac (ttg_final_mac.log); run as CONTROL=unpinned-level on ERIS it printed FAIL with the old tails (1, 0) and (0, 1) back (ttg_final_mode.log). provenance.sh run on both hosts (provenance2_mac.txt, provenance2_eris.txt): the same gate sha256 54bb2b9e, the set key f601342d over build/m3b_merged31/rompath, the same per-member sha1 list f372e61d of the vsavjw.zip the ours leg loads, the same three replays, replay.lua, pokes_spec.lua and run_mame.sh; the HEADs differ (Mac 5acfdf37 with the gate modified in the working tree, ERIS a94d7309 running it as a scratch copy) and so do the MAME binaries (each host's own build). The FROZEN tails, arcs and damage cells were copied from the pinned scratch runs (ttg_pin_att11.log, ttg_pin_att13.log, ttg_pin3_att10.log); the seqs from the final run's first pass. NOT TESTED: that each frozen seq is the move NAMED (it rests on 02_throw.rpl's input, a forward 6+HP at point-blank on a dummy that cannot tech, not on a move table); whether the two MAME builds differ in anything the gate reads (they agree on every verdict line); the scratch scripts staged (ttg_std.sh, ttg_pin3.sh) are their pinned versions — the unpinned runs used ttg_std.sh without its pin line; per-state dwell equality (a hold ratio is reported only); Pyron's and Donovan's other throws (kick and air throws); whether the 14z-131 header prose below the SUPERSEDED marker still holds anywhere.
Artifacts (read every one, in full):
  - tests/audit_tenant_throw_geometry.sh
  - build/agent193/t230/gate.diff
  - build/agent193/t230/ttg_final.log
  - build/agent193/t230/ttg_final_mode.log
  - build/agent193/t230/ttg_final_mac.log
  - build/agent193/t230/ttg_att11.log
  - build/agent193/t230/ttg_att13.log
  - build/agent193/t230/ttg_pin_att11.log
  - build/agent193/t230/ttg_pin_att13.log
  - build/agent193/t230/ttg_pin3_att10.log
  - build/agent193/t230/provenance.sh
  - build/agent193/t230/provenance2_mac.txt
  - build/agent193/t230/provenance2_eris.txt
  - build/agent193/t230/ttg_std.sh
  - build/agent193/t230/ttg_pin3.sh
  - tests/replays/judge/02_throw.rpl
  - DECISIONS_HISTORY.md.lines-1012-1019 (lines 1012-1019 of DECISIONS_HISTORY.md)
