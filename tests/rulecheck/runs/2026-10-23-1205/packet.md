THE PACKET

Decision kind: expectation
Subject: freeze four poked_legs rows and three poke_readback rows (14z-207), after runs 2026-10-23-1203 and -1204
Claim (the working agent's sentence): Two frozen expectations change in this session's commit, after its commit tier (4dfd9fd3) failed them (tier.log: test_poked_legs and test_poke_readback FAIL), and after runs 2026-10-23-1203 and -1204. tests/expected/poked_legs.tsv gains four test_proof_sheets rows (poked_legs.diff): P1 poked 0x10 (Phobos) over the replays' P1 cell 01 (Demitri), native and ours, replays 02_demitri_vs_cpu and hui/90_hui_oracle, class CROSS-INERT, by the tool's rule (poked_legs_rule.txt: FLAVOR_CELLS at :70, flavor_on at :76-77, classify at :80-91: flavor_on(0x01) and flavor_on(0x10) are both 0x00, and an ours leg is never CROSS-FLAVOR); the gate requires an accepted measurement only for CROSS-FLAVOR (poked_legs_header.txt). tests/expected/poke_readback.tsv gains three rows (poke_readback.diff) classed by the maintainer, whose words are quoted (ruling_poke_readback.txt): audit_trap_air_hit's p1x READS-BACK, labelled in the gate's header as a rig record (trap_air_hit_label.diff), because its frozen steps read 3500:540 on every row, the pinned park (trap_air_hit_steps.txt; the pins at trap_air_hit_lines2.txt :91-92), after the first OBSERVES ruling was superseded on that fact; vx OBSERVES, its first step 3500:695 the pinned start and its later steps 696-698 the game's pushback (trap_air_hit_steps.txt); test_proof_sheets' c1 CROSS-LEG (proof_sheets_lines.txt: the poked vsav2 leg samples ff8410/ff8810 at :446-447; c1 is sampled at :476 on a leg with no POKES). Both gates PASS after (poked_legs_after.log, poke_readback_after.log). Not tested: the CROSS-INERT class of the new rows and of test_hui_oracle's agree because one rule classes both, so that agreement is one method, not a second check; the rule's two facts (what the confirm writes per cell, who reads the latch in play) are the tool's 14z-161 measurements as its docstring states them, not re-measured; no control plants a wrong class (the census gate's controls cover a new CROSS-FLAVOR pairing and a dropped row only); the census pairs per script, so the two rows pairing the Phobos pokes with replays/02_demitri_vs_cpu.rpl may be pairings the gate never runs; the controls were read from the after-logs, not re-planted; no emulator ran, and audit_trap_air_hit's header change is a comment its run does not read.
Artifacts (read every one, in full):
  - build/agent207/commit_tier/poked_legs.diff
  - build/agent207/commit_tier/poke_readback.diff
  - build/agent207/commit_tier/hui_oracle_rows.txt
  - build/agent207/commit_tier/poked_legs_rule.txt
  - build/agent207/commit_tier/poked_legs_header.txt
  - build/agent207/commit_tier/poked_legs_after.log
  - build/agent207/commit_tier/poke_readback_after.log
  - build/agent207/commit_tier/trap_air_hit_lines2.txt
  - build/agent207/commit_tier/trap_air_hit_steps.txt
  - build/agent207/commit_tier/trap_air_hit_label.diff
  - build/agent207/commit_tier/proof_sheets_lines.txt
  - build/agent207/commit_tier/ruling_poke_readback.txt
  - build/agent207/commit_tier/tier.log
