THE PACKET

Decision kind: freeze
Subject: 14z-183 M20 freeze: registry rows donovan-m24 huitzil-m31 pyron-m25 merged-m20 donovan-m24-stock (donovan-m23-stage4 carried) and their expectation sets
Claim (the working agent's sentence): The five new registry rows (registry.diff) name the keys the M20 builds measure now and each build resolves to its own row, the stage-4 image to the carried donovan-m23-stage4 (sets_and_fingerprints.txt); the M20 program delta against M19 is exactly #157's rows — every differing word in both decrypted views sits at a port_patch row's displacement address in that build's x028122 placements, the opcode view carrying the rows' old/new values, every row's word moved, and a planted byte is flagged (delta_attr.py/.txt, delta_attr_plant.txt) — with the member moves vm3j.04d + the mark's vsw.33m/37m per solo track, + vsw.41 on merged, vm3j.04d alone on the stock twin (deltas_measurer.txt); every track rebuilds bit-exact from the tracked manifests with its member manifest matching (m3a_repro.log, the re-pins in pin_edits.diff); the four WIDE sets and the stock set carry every authored .masked/.skip/mask byte-identical and verify SUITE GREEN with no FAIL, the merged set holding no .sha1, and the stock and stage-4 masked legs pass 14/14 (carry_and_suite.txt); the emulator battery's pass-1 reds were each re-frozen through rule-checker runs 238-244 (the last OK) and pass 2 is all PASS (battery_p1_results.tsv, battery_p2_results.tsv), the MiSTer romset lane's red being the re-frozen prg_window pair (mister_romset_results.tsv); the MiSTer tail and the release package check out (release_gates.txt); and of the freeze-cadence tier's five reds, two are fixed by the re-pins and three clear only by this freeze's order — the tags, this rulecheck row, and a --stale emulator re-run on the committed tree (tier_reds.txt with the three failure logs). The maintainer ruled the freeze and the two in-freeze calls in their own words (decisions_lines_30_68.txt) after playing the probe (maintainer_playtest.txt). NOT tested: that the tags, the --stale re-run and the tier re-run come out green (they follow this check and the commit); the prg_window pair's move (measured, not explained); #179 (open, ticketed); the third store pair (never observed writing); the two stock-spend throws that pay the thrower 0 on both M19 and M20 (unexplained); the whole-RAM A/B's reach to M20 assumes the probe's mark glyphs change no execution.
Artifacts (read every one, in full):
  - build/rc183/freeze/registry.diff
  - build/rc183/freeze/sets_and_fingerprints.txt
  - build/rc183/freeze/deltas_measurer.txt
  - build/rc183/freeze/delta_attr.py
  - build/rc183/freeze/delta_attr.txt
  - build/rc183/freeze/delta_attr_plant.txt
  - build/rc183/freeze/carry_and_suite.txt
  - build/rc183/freeze/m3a_repro.log
  - build/rc183/freeze/pin_edits.diff
  - build/rc183/freeze/tier_reds.txt
  - build/rc183/freeze/tag_coverage_fail.log
  - build/rc183/freeze/rule_checker_fail.log
  - build/rc183/freeze/staleness_fail.log
  - build/rc183/freeze/battery_p1_results.tsv
  - build/rc183/freeze/battery_p2_results.tsv
  - build/rc183/freeze/mister_romset_results.tsv
  - build/rc183/freeze/release_gates.txt
  - build/rc183/freeze/decisions_lines_30_68.txt
  - build/rc183/freeze/maintainer_playtest.txt
