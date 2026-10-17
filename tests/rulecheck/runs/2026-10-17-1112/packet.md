THE PACKET

Decision kind: recommendation
Subject: #243 step 2 put to the maintainer: keep the whole tests/replays/ as the input of the 51 gates that compose a path there (option A), after steps 1 and 3
Claim (the working agent's sentence): Steps 1 and 3 are done (24 declarations narrowed to their text, reconcile PASS; the over-wide check and its control replays-rewidened in test_gate_follows, build/agent204/t243/gate.log, build/agent204/t243/ctl.log; a new top-level replay stales 51 gates instead of 75, build/agent204/t243/effect.txt), and option A is recommended for the remaining 51 because 5 of them read the corpus by glob and the rest compose the path from variables whose feeders were not traced (build/agent204/t243/bare_sources.txt), so a resolver (option B) risks an under-declaration the audit would carry, while A's cost is a NOTE at session (the audit's ruled 'NOTE at session, FAIL at freeze/release', build/agent204/t243/audit_emulator_staleness.py.txt). Not tested: whether a resolver would cover every composed name; the feeders of the 46 composed paths
Artifacts (read every one, in full):
  - build/agent204/t243/recommendation.md
  - build/agent204/t243/census.txt
  - build/agent204/t243/bare_sources.txt
  - build/agent204/t243/effect.txt
  - build/agent204/t243/gate.log
  - build/agent204/t243/ctl.log
  - build/agent204/t243/change.diff
  - build/agent204/t243/audit_emulator_staleness.py.txt
