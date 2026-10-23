THE PACKET

Decision kind: expectation
Subject: freeze four poked_legs rows and three poke_readback rows (14z-207 commit tier)
Claim (the working agent's sentence): Two frozen expectations change in this session's commit, after its commit tier (4dfd9fd3) failed them (tier.log: test_poked_legs and test_poke_readback FAIL). tests/expected/poked_legs.tsv gains four test_proof_sheets rows (poked_legs.diff), each the poke "P1 - 01 Demitri 10 CROSS-INERT" on native and ours of replays/02_demitri_vs_cpu.rpl and replays/hui/90_hui_oracle.rpl, the same class as test_hui_oracle's frozen rows for the same pokes on the same replay (hui_oracle_rows.txt); CROSS-INERT needs no accepted measurement (the gate's header in poked_legs_after.log's gate is not staged; the class rule is the tool's). tests/expected/poke_readback.tsv gains three rows (poke_readback.diff) classed by the maintainer (ruling_poke_readback.txt, the maintainer's words quoted): audit_trap_air_hit ff8410 p1x and ff8810 vx OBSERVES, on trap_air_hit_lines.txt (pins 3470-3489 at :266, the trace required to be 3500..3530 at :135, steps compared from 3500 at :139-140); test_proof_sheets ff8782 c1 CROSS-LEG, on proof_sheets_lines.txt (the poked vsav2 leg samples ff8410/ff8810 at :446-447; c1 is sampled on a leg with no POKES at :476). Both gates PASS after (poked_legs_after.log, poke_readback_after.log). Not tested: whether the static census's pairing of test_proof_sheets' Phobos pokes with replays/02_demitri_vs_cpu.rpl is a pairing the script executes (the census pairs per script, not per leg, so two of the four rows may be pairings the gate never runs); the gates' must-fire controls were taken from the after-logs, not re-planted; no emulator ran.
Artifacts (read every one, in full):
  - build/agent207/commit_tier/poked_legs.diff
  - build/agent207/commit_tier/poke_readback.diff
  - build/agent207/commit_tier/hui_oracle_rows.txt
  - build/agent207/commit_tier/poked_legs_after.log
  - build/agent207/commit_tier/poke_readback_after.log
  - build/agent207/commit_tier/trap_air_hit_lines.txt
  - build/agent207/commit_tier/proof_sheets_lines.txt
  - build/agent207/commit_tier/ruling_poke_readback.txt
  - build/agent207/commit_tier/tier.log
