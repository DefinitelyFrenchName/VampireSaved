THE PACKET

Decision kind: freeze
Subject: 14z-170 M19 freeze registry rows donovan-m23 huitzil-m30 pyron-m24 merged-m19 donovan-m23-stock donovan-m23-stage4 and their expectation sets (re-run after 2026-09-19-56's resolution)
Claim (the working agent's sentence): The six registry rows (registry.diff) name the fingerprints the M19 builds measure now (sets_and_fingerprints.txt), the tree rebuilds the four WIDE builds and the stock twin bit-exact (test_m3a_reproducible.log), each row's member list equals the zip members whose CRC moved against its M18 build (members.txt), and each row's delta note matches that build's op-by-op attribution against its M18 build by tools/attribute_patch_delta.py (attr_*.txt), whose RELOCATED class is backed by a content check on every relocated target (merged: 7406 of 7406 content-identical) and whose EDITs are checked byte for byte to be the designed edits on the registered builds themselves (edits_check_m18_m19.txt; the checker is a scratch script, build/rc170/delta_edits_check.py re-pointed at build/m3b_merged26 and build/m3b_merged27). The four WIDE expectation sets carry their predecessors' authored .masked, .skip and mask byte-identical (sets_and_fingerprints.txt) and were frozen, then verified SUITE GREEN on their builds, with the authored-.masked count equal to the predecessor's (the freeze and verify logs); merged-m19's 16 self-frozen tenant .sha1 were deleted after the freeze under the #111 ruling, whose words are in rulings.txt, leaving the predecessor's shape (sha1_moves.txt); the stock and stage-4 battery sets carry verbatim and verify 14/14 each through the battery's own masked leg (stock.log, stage4.log). NOT tested: the emulator-tier battery on these builds, including every gate behind the rows' behavioural sentences (the column, trap and EX paths equal native, no new zero-pass frame) — those were measured on the scratch build/fix170_b, program-identical (681ac3ad), and the battery re-runs them on build/m3b_merged27 before the tags; the MiSTer romset lane (running); the stage-4 image is a scratch build (build/rc170/freeze/stage4), which test_m3a_reproducible does not rebuild; and that a moved self-frozen tenant .sha1 moved for the fixes and nothing else (sha1_moves.txt gives only the first differing frame).
Artifacts (read every one, in full):
  - build/rc170/freeze/rc_freeze/registry.diff
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
  - build/rc170/freeze/rc_freeze/edits_check_m18_m19.txt
  - build/rc170/freeze/rc_freeze/donovan-m23.freeze.log
  - build/rc170/freeze/rc_freeze/donovan-m23.verify.log
  - build/rc170/freeze/rc_freeze/huitzil-m30.freeze.log
  - build/rc170/freeze/rc_freeze/huitzil-m30.verify.log
  - build/rc170/freeze/rc_freeze/pyron-m24.freeze.log
  - build/rc170/freeze/rc_freeze/pyron-m24.verify.log
  - build/rc170/freeze/rc_freeze/merged-m19.freeze.log
  - build/rc170/freeze/rc_freeze/merged-m19.verify.log
  - build/rc170/freeze/rc_freeze/stock.log
  - build/rc170/freeze/rc_freeze/stage4.log
  - build/rc170/freeze/rc_freeze/sha1_moves.txt
