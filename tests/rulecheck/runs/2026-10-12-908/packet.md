THE PACKET

Decision kind: recommendation
Subject: the merged-m23 release run: audit_legacy_pairings FAIL on eight #118 replays with no merged-m23 expectation — .skip them (A) or make them legacy oracles (B)
Claim (the working agent's sentence): Recommend option A, a .skip with a stated reason in tests/expected/merged-m23 for 118_chain, 118_input_sweep and 118_sel_b1..b6, put to the maintainer beside option B, resting on the ERIS audit log (build/agent198/skip118/audit_legacy_pairings.eris.log), the replay facts (build/agent198/skip118/replays_118.txt: added 2026-10-08/09 after the c884e6d8 freeze, named by ondemand #118 gates), the 14z-196 ondemand ruling and the post-freeze .skip precedent (27_don_throw_vsavj, 37_pick_huitzil_cell, 40_pick_pyron_cell); NOT TESTED: whether another merged-m23 .masked replay already covers select confirms with buttons 2-6, and whether the eight would pass a masked comparison on merged-m23.
Artifacts (read every one, in full):
  - build/agent198/skip118/RECOMMENDATION.md
  - build/agent198/skip118/replays_118.txt
  - build/agent198/skip118/audit_legacy_pairings.eris.log
  - tests/audit_legacy_pairings.sh.lines-1-60 (lines 1-60 of tests/audit_legacy_pairings.sh)
  - DECISIONS_HISTORY.md.lines-559-590 (lines 559-590 of DECISIONS_HISTORY.md)
  - tests/expected/merged-m23/27_don_throw_vsavj.skip
  - tests/expected/merged-m23/37_pick_huitzil_cell.skip
  - tests/expected/merged-m23/40_pick_pyron_cell.skip
  - tests/expected/merged-m23/03_two_player_vs.masked
  - tests/ci_emulator.tsv.lines-325-340 (lines 325-340 of tests/ci_emulator.tsv)
