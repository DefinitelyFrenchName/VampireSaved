THE PACKET

Decision kind: expectation
Subject: #230: audit_tenant_throw_geometry re-frozen at the matched level with Pyron and Donovan as throwers (after runs 708-711)
Claim (the working agent's sentence): Re-freeze tests/audit_tenant_throw_geometry.sh for #230, after rule-checker runs 2026-10-06-708 (VIOLATED Q1 Q4), 2026-10-06-709 (VIOLATED Q1 Q2 Q3 Q4), 2026-10-06-710 (VIOLATED Q1) and 2026-10-06-711 (VIOLATED Q1 Q4), each resolved by work: it runs Pyron's (0x11) and Donovan's (0x13) standard throw beside Phobos's three throws over the same 18 roster victims; pins speed level 06 (from frame 2000) and RNG word 0000 (from frame 2363) on both legs as the 2026-09-25 ruling's equalised input (DECISIONS_HISTORY.md lines 1012-1019); moves every FROZEN tail to (0,0); compares each victim's post-release arc between the legs victim by victim and freezes the set of values per throw (Pyron's 12 values, Donovan's {64,68}), with Pyron's Sasquatch residue (13,14); and checks, as two separate verdict lines, that on each captured frame the attacker holds the named thrower's own +0x60 character-data base as the game loaded it (RAM:$FF8460; ours from tests/expected/roster_pairings/bases.tsv, native from vsav2's table PRG:0x0D7B18), and, at the hold's first captured frame only, that its seq is one frozen value per throw (Phobos 2, 14, 16; Pyron 2; Donovan 4) (gate.diff). Basis: the gate printed PASS on ERIS (ttg_v6.log) and on the Mac (ttg_v6_mac.log), each with five 'ok: identity' lines whose MEASURED bases equal the table values (ours 0x45a770, 0x4ae91c, 0x3fa9d0; native 0xc4370, 0xc75fe, 0xc8df8), five 'ok: seq' lines, five victim-by-victim arc ok lines over 18 victims, "CONTROL FIRED: unpinned-level — 18 of 18 victims diverge" and "CONTROL FIRED: wrong-thrower — Victor in Donovan's slot: 183 held frames, 183 with a base other than Donovan's (0x9769e)" and "CONTROL FIRED: arc-swap — two native arcs exchanged on Pyron's throw: per-victim check flags ['00', '01'], the legs' sets still equal"; as CONTROL=unpinned-level it printed FAIL with the old tails (1, 0) and (0, 1) back (ttg_v6_mode_unpinned-level.log); as CONTROL=wrong-thrower it printed 'FAIL: identity' for Donovan while his 'ok: seq' line still read [4] (ttg_v6_mode_wrong-thrower.log); as CONTROL=arc-swap it printed "FAIL: post-release arc peak differs between legs for victims {'00': (101, 81), '01': (81, 101)}" (ttg_v6_mode_arc-swap.log) — Victor's standard throw also enters seq 4, so the seq does not identify the thrower; the measured base does. provenance.sh on both hosts (provenance6_mac.txt, provenance6_eris.txt): the same gate sha256 e08cab99, the set key f601342d over build/m3b_merged31/rompath, the same per-member sha1 list f372e61d of that vsavjw.zip, the same per-member sha1 list 4468c42f of each host's $ROMDIR/vsav2.zip (the native leg's set), the same sha256s of build/out/vsav2_data.bin, build/out/vsavj_data.bin, build/m3b_merged31/patch/placements.json and tests/expected/roster_pairings/bases.tsv, the same replays, replay.lua, pokes_spec.lua and run_mame.sh; the HEADs differ (Mac 5acfdf37 with the gate modified in the working tree, ERIS a94d7309 running it as a scratch copy) and so do the MAME binaries (each host's own build). The tails, arcs and damage cells were copied from the pinned scratch runs (ttg_pin_att11.log, ttg_pin_att13.log, ttg_pin3_att10.log), the seqs from the measuring run whose frozen seq sets were empty (ttg_seq.log). The maintainer read three keyframe-matched capture sheets of the standard throw (capture_11_03.png, capture_13_03.png, capture_13_10.png): "yes, they look identical" (maintainer_read.txt). NOT TESTED: that each frozen seq is the move NAMED (it rests on 02_throw.rpl's input, a forward 6+HP at point-blank on a dummy that cannot tech, not on a move table); the capture sheets run each game at its default speed level and match by keyframe, so the read covers where and how the victim is held, not the hold's timing; whether the two MAME builds differ in anything the gate reads (they agree on each verdict line); the scratch scripts staged (ttg_std.sh, ttg_pin3.sh) are their pinned versions — the unpinned runs used ttg_std.sh without its pin line; per-state dwell equality (a hold ratio is reported only); Pyron's and Donovan's other throws (kick and air throws); whether the 14z-131 header prose below the SUPERSEDED marker still holds anywhere.
Artifacts (read every one, in full):
  - tests/audit_tenant_throw_geometry.sh
  - build/agent193/t230/gate.diff
  - build/agent193/t230/ttg_v6.log
  - build/agent193/t230/ttg_v6_mac.log
  - build/agent193/t230/ttg_v6_mode_unpinned-level.log
  - build/agent193/t230/ttg_v6_mode_wrong-thrower.log
  - build/agent193/t230/ttg_v6_mode_arc-swap.log
  - build/agent193/t230/ttg_seq.log
  - build/agent193/t230/ttg_att11.log
  - build/agent193/t230/ttg_att13.log
  - build/agent193/t230/ttg_pin_att11.log
  - build/agent193/t230/ttg_pin_att13.log
  - build/agent193/t230/ttg_pin3_att10.log
  - build/agent193/t230/provenance.sh
  - build/agent193/t230/provenance6_mac.txt
  - build/agent193/t230/provenance6_eris.txt
  - build/agent193/t230/maintainer_read.txt
  - build/agent193/t230/capture_11_03.png
  - build/agent193/t230/capture_13_03.png
  - build/agent193/t230/capture_13_10.png
  - build/agent193/t230/ttg_std.sh
  - build/agent193/t230/ttg_pin3.sh
  - tests/replays/judge/02_throw.rpl
  - tests/expected/roster_pairings/bases.tsv
  - DECISIONS_HISTORY.md.lines-1012-1019 (lines 1012-1019 of DECISIONS_HISTORY.md)
