THE PACKET

Decision kind: expectation
Subject: test_m3a_reproducible: add the stage-4 image (EXPECT_STAGE4 2fa7c2f1..., MANI_STAGE4 c4535aa3... 9 members) as a sixth frozen reference (14z-185b)
Claim (the working agent's sentence): The stage-4 expectation is anchored OUTSIDE the tool that now checks it: its fingerprint equals the registry's donovan-m23-stage4 row (written by the M19 freeze and carried unchanged since), and the gate, rebuilding stage 4 from the tree with the stock flags, reproduced that fingerprint and the 9-member manifest measured on the M21 freeze's own stage-4 build. Not tested: whether the stage-4 build is deterministic across machines (measured here on this Mac only), and the added runtime of the stage-4 rebuild inside the gate (not isolated; the whole gate ran 4 min 13 s).
Artifacts (read every one, in full):
  - build/agent185b/m3a_stage4.diff
  - build/agent185b/m3a_stage4.log
  - build/agent185b/registry_stage4_row.txt
  - build/agent185b/stage4_manifest.txt
