THE PACKET

Decision kind: freeze
Subject: 14z-183 M20 freeze: registry rows donovan-m24 huitzil-m31 pyron-m25 merged-m20 donovan-m24-stock (donovan-m23-stage4 carried) and their expectation sets (after runs 245-247)
Claim (the working agent's sentence): The five new registry rows (registry.diff) name the keys the M20 builds measure now and each build resolves to its own row, the stage-4 image to the carried donovan-m23-stage4 (sets_and_fingerprints.txt). Against the M19 builds — each baseline directory at its retired M19 pin and resolving to its M19 row (baseline_fingerprints.txt), every compared image byte-identical to a fresh decrypt of its own zip (images_vs_zip.txt) — the M20 delta is the designed one and nothing else: every pair moved exactly its designed members, nothing appeared or vanished (members_check.py/.txt, its plant failing: members_check_plant.txt); every changed group-C byte lies in the two re-authored mark glyphs, each equal to the generator's authored bytes (gfx_mark_check.py/.txt, plant: gfx_mark_check_plant.txt); and every differing program word in both decrypted views, on all five tracks, sits at a #157 port_patch row's displacement address, the opcode view carrying the rows' old/new values and every row's word moved (delta_attr.py/.txt, plant: delta_attr_plant.txt; also deltas_measurer.txt). Every track rebuilds bit-exact from the tracked manifests with its member manifest matching (m3a_repro.log, the re-pins in pin_edits.diff). The four WIDE sets carry every authored .masked/.skip/mask byte-identical and verify SUITE GREEN with no FAIL, the merged set holding no .sha1, and the stock set (carried byte-identical) and the stage-4 set pass the battery's masked leg 14/14 (carry_and_suite.txt). The emulator battery's pass-1 reds were re-frozen through rule-checker runs 238-244, the last OK (ledger_238_244.txt) — the nine MAME gates re-run all PASS (battery_p1_results.tsv, battery_p2_results.tsv), and the MiSTer romset lane's test_mister_prg_window re-frozen from that lane's own measurement (mister_romset_results.tsv, prg_window_refreeze.txt). The MiSTer tail and the release package check out (release_gates.txt). Of the freeze-cadence tier's five reds, two are fixed by the re-pins and three clear only by this freeze's order — the tags, this rulecheck row, and a --stale emulator re-run on the committed tree (tier_reds.txt and the three failure logs). The maintainer ruled the freeze and the two in-freeze calls in their own words (decisions_lines_30_68.txt) after playing the probe (maintainer_playtest.txt). NOT tested: that the tags, the --stale re-run and the tier re-run come out green (they follow this check and the commit); the re-frozen prg_window pair was not re-run (a 2 x ~55 min Verilator gate), and its move is measured, not explained; #179 (open, ticketed); the third store pair (never observed writing); the two stock-spend throws that pay the thrower 0 on both M19 and M20 (unexplained); the whole-RAM A/B's reach to M20 assumes the probe's mark glyphs change no execution.
Artifacts (read every one, in full):
  - build/rc183/freeze/registry.diff
  - build/rc183/freeze/sets_and_fingerprints.txt
  - build/rc183/freeze/baseline_fingerprints.txt
  - build/rc183/freeze/images_vs_zip.txt
  - build/rc183/freeze/deltas_measurer.txt
  - build/rc183/freeze/members_check.py
  - build/rc183/freeze/members_check.txt
  - build/rc183/freeze/members_check_plant.txt
  - build/rc183/freeze/gfx_mark_check.py
  - build/rc183/freeze/gfx_mark_check.txt
  - build/rc183/freeze/gfx_mark_check_plant.txt
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
  - build/rc183/freeze/prg_window_refreeze.txt
  - build/rc183/freeze/ledger_238_244.txt
  - build/rc183/freeze/release_gates.txt
  - build/rc183/freeze/decisions_lines_30_68.txt
  - build/rc183/freeze/maintainer_playtest.txt
