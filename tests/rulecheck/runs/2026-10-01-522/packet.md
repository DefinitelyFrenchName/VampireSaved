THE PACKET

Decision kind: expectation
Subject: #191/#161 mechanism retracted; DMG-VSAVJ -> P2-RECORD re-freeze; #192 gate freeze (after runs 512-521)
Claim (the working agent's sentence): Three expectation changes rest on measured data swaps, each both ways with every byte write verified, and on each IMAGE a swap uses (pristine vsavj, pristine vs2, the merged build vsavjw) an own-value poke reproduces an unpoked trace byte for byte (on the #192 legs the whole field trace and the parsed rows) — the inert control is measured once per image and per gate leg family named below, not on every leg. (A) Demitri's 2HK/5HP/623HP damage differs between pristine vsavj and vs2 because vs2 lowered his own attack records (10/14/20 -> 9/13/18): each game given the other's three records takes the other game's frozen damage on 176 of 192 legacy rows (every legacy victim, both sides; the 16 others exactly Sasquatch 0x0A's and Oboro 0x18's) and on Donovan's own legs, 8 of 8; own-value pokes inert on victim 0x00's leg on vsavj and vs2 and on Donovan's legs on vsavjw and vs2 (r518/sweep2.log, PASS; the three controls FAIL the gate as modes on the final file, r518/mode_sweep_*.log, r518/final_sha.txt). (1) tests/expected/move_parity_attribution.tsv re-frozen: its six DMG-VSAVJ roots and six row lines (attr/freeze.diff) become P2-RECORD, computed from P2 Demitri's node at the hit mapped on both legs' images and that node's record (a2:0x04#2, 13 vs2 / 14 vsavj) lower on vs2 by exactly the HP difference; the gate re-measures it every run — each part's legs re-run with the byte swapped both ways (all six roots confirmed) and with the byte poked to its own value (8 of 8 legs identical to the unpoked trace, each swapped trace differing under the same comparison); control p2-record-unswapped FIRED and FAILs the gate as a mode (r518/attr.log PASS, r518/mode_attr_p2.log, r518/attr_tool.diff). (2) tests/expected/demitri_split.tsv frozen for #192: the rows are node-change frames and HP, measured at speed level 6 with the RNG word pinned 0000 (the gate's pins from 2000 and 2363) — at those conditions Chaos Flare's later nodes change 1-2 frames earlier on vsavj and its fireball takes one more HP, because vs2 lengthened the hold node a2:0x1e#5 (30 -> 32) and lowered the fireball's four records (12/12/12/15 -> 11/11/11/14): each game given the other's five bytes reads the other game's rows exactly, and each cause swapped ALONE moves only its own rows — the hold byte alone the node rows, the four records alone the hit rows, both games, both events, the games' node rows and hit rows both differing so each half can fail; the one frame (first event) against two (second) is counted on the hold node's tick counter +0x20: 30 ticks in 25 / 24 frames on vsavj, 32 in 26 / 26 on vs2, the two extra ticks costing one frame when one lands on a level-6 double-tick frame (+45, first event) and two when neither does (t192tick/gate2.log section 3, PASS; controls games-agree and cause-unswapped FIRED and each FAILs the gate as a mode on the unchanged file, t192tick/mode_*.log, t192tick/final_sha.txt; the frozen rows unchanged, section 4 'every row as frozen'). The timing a player could feel was put before the maintainer as captures before this freeze, both events (tools/demitri_split_sheet.sh; t192cap/ for the first event's sheets, t192cap3/ for both events and the zoomed strip of the second): on the first the maintainer answered "yes that's what I see, with also the fact that, maybe because it's one frame earlier, Demitri's aura is not the same shade" — the aura measured as a two-frame flash on the same frames in both games, so the shade is the pose offset meeting it; on the second, after a first answer about the wrong sheet that the maintainer corrected, "I agree, and can confirm the 2 frame difference" (t192cap3/maintainer_read.txt, verbatim, with the pose-change counts: vsavj +47 on both events, vs2 +48 and +49). NOT tested: speed levels other than 6 and RNG states other than the pinned 0000 (the one-or-two-frame offset is the 30-against-32-tick data at level 6's double-tick cadence; at another level it may differ); attackers other than Demitri; his moves beyond these three and Chaos Flare at LP (the MP/HP/EX variants' durations differ too, unswapped); FBNeo; the own-value poke on each of the 64 pristine sweep legs individually (once per image); why Victor's 2HK reads equal on both games (the swap reproduces it); why Sasquatch's rows stay apart with equal records (his defense row differs, not separated) and why Oboro's hits land differently (not measured); whether the engines differ on any record-equal hit (not claimed either way); the P2 guard's declared chains outside the ALL=1 parts.
Artifacts (read every one, in full):
  - tests/expected/move_parity_attribution.tsv
  - build/agent187b/attr/freeze.diff
  - build/agent187b/r518/attr_tool.diff
  - build/agent187b/r518/attr.log
  - build/agent187b/r518/mode_attr_p2.log
  - build/agent187b/r518/sweep_gate.diff
  - build/agent187b/r518/sweep2.log
  - build/agent187b/r518/mode_sweep_counterfactual-skipped.log
  - build/agent187b/r518/mode_sweep_engines-agree.log
  - build/agent187b/r518/mode_sweep_attacker-swapped.log
  - build/agent187b/r518/final_sha.txt
  - build/agent187b/t191n/sweep_cf_result.txt
  - tests/expected/dmg_legacy_sweep.tsv
  - tests/expected/demitri_split.tsv
  - tests/audit_demitri_split.sh
  - build/agent187b/t192tick/gate2.log
  - build/agent187b/t192tick/mode_games-agree.log
  - build/agent187b/t192tick/mode_cause-unswapped.log
  - build/agent187b/t192tick/final_sha.txt
  - tests/lua/rom_poke.lua
  - tools/demitri_split_sheet.sh
  - build/agent187b/t192cap/chaos_flare_release.png
  - build/agent187b/t192cap/chaos_flare_end.png
  - build/agent187b/t192cap3/chaos_flare_3000_release.png
  - build/agent187b/t192cap3/chaos_flare_3400_release.png
  - build/agent187b/t192cap3/chaos_flare_3400_zoom.png
  - build/agent187b/t192cap3/maintainer_read.txt
