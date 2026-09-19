THE PACKET

Decision kind: freeze
Subject: 14z-170 M19 freeze registry rows donovan-m23 huitzil-m30 pyron-m24 merged-m19 donovan-m23-stock donovan-m23-stage4 and their expectation sets (re-run after 2026-09-19-58's resolution)
Claim (the working agent's sentence): The six registry rows (registry.diff) name the fingerprints the M19 builds measure now (sets_and_fingerprints.txt); every comparison's M18 baseline is the registered predecessor image (baselines.txt); the tree rebuilds the four WIDE builds and the stock twin bit-exact (test_m3a_reproducible.log); each row's member list equals the zip members whose CRC moved (members.txt); each row's delta note matches its build's op-by-op attribution against its M18 build by tools/attribute_patch_delta.py (attr_*.txt), whose RELOCATED class is backed by a content check on every relocated target; on EVERY track, every EDIT and INSERTED op is recognised by content as one of the design's edit kinds, 0 unexplained, by a checker that fails on a planted wrong byte (edits_check_*.txt, edits_check_plant_*.txt); and every x2b7ef4 repair — both standalone Donovan copies and the three merged copies — is checked byte for byte against vs2's own source bytes, 0 unexplained, with a planted wrong byte flagged (x2b7ef4_sites_check*.txt; both checkers are scratch scripts). The four WIDE expectation sets carry their predecessors' authored .masked, .skip and mask byte-identical (sets_and_fingerprints.txt) and were frozen, then verified SUITE GREEN on their builds, with the authored-.masked count equal to the predecessor's (the freeze and verify logs); merged-m19's 16 self-frozen tenant .sha1 were then deleted under the #111 ruling (words in rulings.txt), and the committed set reads PASS 53, SKIP 19, NO-EXPECTATION 16, FAIL 0 (merged-m19.committed.verify.log) — the shipped shape; the stock and stage-4 battery sets carry verbatim and verify 14/14 each through the battery's own masked leg (stock.log, stage4.log). NOT tested: the emulator-tier battery on these builds, including every gate behind the rows' behavioural sentences (the column, trap and EX paths equal native, no new zero-pass frame) — those were measured on the scratch build/fix170_b, program-identical (681ac3ad), and the battery re-runs them on build/m3b_merged27 before the tags; one MiSTer romset gate (test_mister_gfxc_fetch, running); the stage-4 image is a scratch build (build/rc170/freeze/stage4), which test_m3a_reproducible does not rebuild; and that a moved self-frozen tenant .sha1 moved for the fixes and nothing else (sha1_moves.txt gives only the first differing frame).
Artifacts (read every one, in full):
  - build/rc170/freeze/rc_freeze/registry.diff
  - build/rc170/freeze/rc_freeze/baselines.txt
  - build/rc170/freeze/rc_freeze/sets_and_fingerprints.txt
  - build/rc170/freeze/rc_freeze/members.txt
  - build/rc170/freeze/rc_freeze/rulings.txt
  - build/rc170/freeze/rc_freeze/test_m3a_reproducible.log
  - build/rc170/freeze/rc_freeze/attr_don_m23.txt
  - build/rc170/freeze/rc_freeze/attr_hui57.txt
  - build/rc170/freeze/rc_freeze/attr_pyron42.txt
  - build/rc170/freeze/rc_freeze/attr_m3b_merged27.txt
  - build/rc170/freeze/rc_freeze/attr_m5_stock18.txt
  - build/rc170/freeze/rc_freeze/attr_stage4.txt
  - build/rc170/freeze/rc_freeze/edits_check_don_m23.txt
  - build/rc170/freeze/rc_freeze/edits_check_hui57.txt
  - build/rc170/freeze/rc_freeze/edits_check_pyron42.txt
  - build/rc170/freeze/rc_freeze/edits_check_m3b_merged27.txt
  - build/rc170/freeze/rc_freeze/edits_check_m5_stock18.txt
  - build/rc170/freeze/rc_freeze/edits_check_stage4.txt
  - build/rc170/freeze/rc_freeze/edits_check_plant_0x0fff53.txt
  - build/rc170/freeze/rc_freeze/edits_check_plant_0x0bf6a0.txt
  - build/rc170/freeze/rc_freeze/x2b7ef4_sites_check.txt
  - build/rc170/freeze/rc_freeze/x2b7ef4_sites_check_solo.txt
  - build/rc170/freeze/rc_freeze/x2b7ef4_sites_check_stock.txt
  - build/rc170/freeze/rc_freeze/x2b7ef4_sites_check_plant.txt
  - build/rc170/freeze/rc_freeze/donovan-m23.freeze.log
  - build/rc170/freeze/rc_freeze/donovan-m23.verify.log
  - build/rc170/freeze/rc_freeze/huitzil-m30.freeze.log
  - build/rc170/freeze/rc_freeze/huitzil-m30.verify.log
  - build/rc170/freeze/rc_freeze/pyron-m24.freeze.log
  - build/rc170/freeze/rc_freeze/pyron-m24.verify.log
  - build/rc170/freeze/rc_freeze/merged-m19.freeze.log
  - build/rc170/freeze/rc_freeze/merged-m19.verify.log
  - build/rc170/freeze/rc_freeze/merged-m19.committed.verify.log
  - build/rc170/freeze/rc_freeze/stock.log
  - build/rc170/freeze/rc_freeze/stage4.log
  - build/rc170/freeze/rc_freeze/sha1_moves.txt
