THE PACKET

Decision kind: expectation
Subject: 14z-180 #171 slices Q3-Q5: freezing tests/expected/gate_follows.tsv (199 declares / 0 undeclared over tests/ci_emulator.tsv) after writing # FOLLOWS: into all 199 emulator-tier gate headers, re-freezing tests/expected/gate_descriptions.tsv (383/0), tests/expected/must_fire_census.tsv (149 declaring) and tests/expected/module_refs_floor.txt (270 -> 284) for the three new gates and their imports, and rewriting tools/audit_lane_carry.py to derive from the declarations
Claim (the working agent's sentence): Every one of the 199 FOLLOWS declarations covers every repo path the gate's text, its sourced tests/lib libraries, the tools/run_*.sh and tools/tap_*.sh runners it calls and its registry args reference (tools/gate_follows.py --reconcile: 0 uncovered), and each was WIDENED beyond its text only by the rules build/gatequal180/follows_apply.py states (the emulator's patches and setup script for the emulator the gate runs, build/manifest/ when it takes or builds a romset, the core sources for the MiSTer lane, the rig generators), so the frozen census and the carry tool's derived subjects rest on the extractor's reach plus those rules; the four re-frozen files change only by the new gates and imports this sitting added (3 declaring gates, 14 module references). NOT tested: a path a gate reaches only inside a Python tool's own code (a data file name_moves.py or run_suite.sh reads) is outside the extractor and outside every declaration unless a widening rule named it; the extractor's text heuristics (a trailing-comment strip, the REPO/PWD substitutions, the :- default) were fixed from three misses found by reading the proposals against each gate's HOW field, and a fourth kind of miss would be invisible to the reconciliation; the staleness gate has no real run of record yet, so its verdict on this tree is only its scratch-repository section; the descriptions' correctness is the maintainer's review, not a measurement.
Artifacts (read every one, in full):
  - tests/expected/gate_follows.tsv
  - tools/gate_follows.py
  - tests/test_gate_follows.sh
  - build/gatequal180/follows_apply.py
  - build/gatequal180/follows_applied.txt
  - build/gatequal180/follows_review.txt
  - build/gatequal180/q3q4_gate_outputs_14z180.txt
  - tools/audit_lane_carry.py
  - tests/test_lane_carry.sh
  - tools/audit_emulator_staleness.py
  - tests/test_emulator_staleness.sh
  - tests/expected/module_refs_floor.txt
  - tests/expected/PROVENANCE.md
  - docs/project/gate_header_contract.md
