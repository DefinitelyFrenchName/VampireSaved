THE PACKET

Decision kind: recommendation
Subject: test_static_runner moves to freeze cadence, pulled into a session tier by triggers on what it runs and reads (the maintainer: 'freeze/release with triggers')
Claim (the working agent's sentence): The row in tests/ci_cadence.tsv (build/agent204/cad/cadence.diff) defers test_static_runner at session cadence unless a trigger path changed: run on the real runner with only STATE.md changed it is deferred (GREEN, PASS 120, build/agent204/cad/state_only2.log), with tools/battery_reach.py changed it is pulled in and passes (GREEN, PASS 121, build/agent204/cad/trigger2.log); its controls executed at all four recorded tiers (653-706 s) because tools/battery_reach.py names STATE.md only in its self-test and usage text, and the gate's own script never names STATE.md (build/agent204/cad/evidence.txt); the triggers are the files the gate copies, links or runs and the registries its section 7 parses, plus the tools the runner calls (build/agent204/cad/evidence.txt; the gate's lines 1-130, 232-283 and 665-700). Not tested: whether the trigger list misses a real input the gate reaches indirectly (a miss would let a runner-affecting change escape until the next freeze, which always runs it); the triggers are judged against origin/main, so after a runner change every tier until the push runs it
Artifacts (read every one, in full):
  - build/agent204/cad/cadence.diff
  - build/agent204/cad/evidence.txt
  - build/agent204/cad/state_only2_lines.txt
  - build/agent204/cad/trigger2_lines.txt
  - build/agent204/cad/state_only2.log
  - build/agent204/cad/trigger2.log
  - tests/test_static_runner.sh.lines-1-130 (lines 1-130 of tests/test_static_runner.sh)
  - tests/test_static_runner.sh.lines-232-283 (lines 232-283 of tests/test_static_runner.sh)
  - tests/test_static_runner.sh.lines-665-700 (lines 665-700 of tests/test_static_runner.sh)
