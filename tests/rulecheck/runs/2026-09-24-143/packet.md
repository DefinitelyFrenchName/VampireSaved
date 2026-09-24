THE PACKET

Decision kind: expectation
Subject: 14z-180 #171 slice Q2: the MEASURES contract — tests/lib/measures.sh read inside tests/lib/classify.sh, tests/test_measures_contract.sh, and six measurement floors declared on five hashed-table gates (charmap-anim-rows 12922, meter-gain-rows 49, slot-map-rows 180, hit-damage-rows 90, zip-members 20, binary-record-rows 2); the must-fire and description censuses re-frozen by the one new gate
Claim (the working agent's sentence): Each declared floor is the count the gate itself printed in a real run this sitting (charmap_current, meter_gain on MAME, vanilla_frame_join on MAME, release_os_metadata, and the contract gate's own dogfood) read back through the shipped reader as OK, except binary-record-rows, whose floor of 2 was NOT measured by a run (test_release_binaries is an emulator-lane gate with boot legs and did not run) and rests only on the shape of the tracked BINARY.txt records — one sha256 row per record at the least, the macOS records carrying 4 and 2; the reader turns a missing, below-floor or undeclared measurement into FAIL through vs_classify on a PASS only, after the controls read, with the three runner ground truths unchanged and green. NOT tested: the classifier now sources a second library and bbh's fidelity gate carries its own copy of the classifier, so a gate declaring MEASURES would be read differently by the two harnesses only when its measurement is red (F1 compares stub gates that declare no measurement); the two gates named as declaring nothing (test_build_environment_entry, test_release_roundtrip) were excluded by reading their sha256 uses, not by a rule; a floor equal to today's count makes any legitimate shrink a red until the floor is edited; the release_binaries count sums check_dir's rows over sections 1 and 2 only and the MEASURED line prints before the control sections, which was verified by reading, not by a run.
Artifacts (read every one, in full):
  - tests/lib/measures.sh
  - tests/lib/classify.sh
  - tests/test_measures_contract.sh
  - tests/test_charmap_current.sh
  - tests/test_meter_gain.sh
  - tests/test_vanilla_frame_join.sh
  - tests/test_release_binaries.sh
  - tests/test_release_os_metadata.sh
  - build/gatequal180/q2_evidence_14z180.txt
  - build/gatequal180/meter_gain_q2.log
  - build/gatequal180/frame_join_q2.log
  - docs/project/gate_header_contract.md
  - tests/expected/must_fire_census.tsv
  - tests/expected/gate_descriptions.tsv
