THE PACKET

Decision kind: freeze
Subject: 14z-170 M19 freeze registry rows donovan-m23 huitzil-m30 pyron-m24 merged-m19 donovan-m23-stock donovan-m23-stage4 and their expectation sets
Claim (the working agent's sentence): The six registry rows (registry.diff) name the fingerprints the M19 builds measure now (sets_and_fingerprints.txt), and the tree rebuilds those builds bit-exact (test_m3a_reproducible.log); each row's delta note matches its build's op-by-op attribution against the M18 build of its track (delta_*.txt, stage4_delta.txt). The four WIDE expectation sets carry their predecessors' authored .masked, .skip and mask byte-identical (sets_and_fingerprints.txt), and each was frozen and then verified SUITE GREEN on its build, with the authored-.masked count equal to its predecessor's (the freeze and verify logs). merged-m19's 16 self-frozen tenant .sha1 were deleted after the freeze per the #111 ruling, so the set has the predecessor's shape (sha1_moves.txt). The stock and stage-4 battery sets carry verbatim and verify 14/14 each through the battery's own masked leg (stock.log, stage4.log). NOT tested: the emulator-tier battery on these builds (it runs before the tags); the MiSTer romset lane (running); that a moved self-frozen tenant .sha1 moved for the fixes and nothing else (sha1_moves.txt gives only the first differing frame); the stage-4 image is a scratch build (build/rc170/freeze/stage4), since the battery rebuilds its own.
Artifacts (read every one, in full):
  - build/rc170/freeze/rc_freeze/registry.diff
  - build/rc170/freeze/rc_freeze/sets_and_fingerprints.txt
  - build/rc170/freeze/rc_freeze/test_m3a_reproducible.log
  - build/rc170/freeze/rc_freeze/delta_don_m23.txt
  - build/rc170/freeze/rc_freeze/delta_hui57.txt
  - build/rc170/freeze/rc_freeze/delta_pyron42.txt
  - build/rc170/freeze/rc_freeze/delta_m5_stock18.txt
  - build/rc170/freeze/rc_freeze/stage4_delta.txt
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
