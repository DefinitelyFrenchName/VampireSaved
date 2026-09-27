THE PACKET

Decision kind: recommendation
Subject: item 5: class audit_chains174's three poke read-back rows OBSERVES and add a pins-ignored control
Claim (the working agent's sentence): Recommend to the maintainer: rule audit_chains174's three UNCLASSIFIED rows in tests/expected/poke_readback.tsv (x at ff8410, stock at ff8509, P2 HP at ff8850) OBSERVES, the class 14z-181 gave the same three fields of audit_move_parity (poke_rows.txt), and add to audit_chains174 a pins-ignored must-fire control like audit_move_parity's. The rows it would classify were measured on this gate's own traces, one field at a time (probe.py, probe.log; the traces kept by a gate run that PASSed, gate.log). For every tenant, each field's rig pins fall inside compared (non-spacer) event windows: x 5/1/3, stock 5/1/3, p2hp 6/2/2 for huitzil/donovan/pyron. tools/move_parity.py, which the gate calls (audit_chains174.sh.lines-150-156), excludes a field's own pin frames from the compare and compares stock and p2hp as frame-to-frame changes (move_parity.py.lines-40-100). With the exclusion ON, perturbing OUR trace on exactly the pin frames moves 0 verdicts for every field and tenant: x altered on the pin frames, stock and p2hp as a step from each pin frame on, which is what a pin does to a cumulative field. With it OFF (--no-pin-exclusion) the same perturbation moves the verdicts (8/8, 2/2, 3-4 of 4). So the exclusion is live, and the pin frames are what it removes. Unperturbed, switching the exclusion off moves no verdict today. NOT tested: that the absolute x after an in-window pin frame is not equalised by the pin for the rest of that window (the same shared-write shape audit_move_parity's OBSERVES ruling accepted: x compared every frame except the pin frames); the pins' effect on fields other than these three; any rig other than the chains174 rigs. The perturbation's values (x +7, stock +1 per pin, p2hp -5 per pin) are arbitrary.
Artifacts (read every one, in full):
  - build/agent185/poke5/probe.py
  - build/agent185/poke5/probe.log
  - build/agent185/poke5/gate.log
  - build/agent185/poke5/poke_rows.txt
  - build/agent185/poke5/move_parity_pins_ignored.txt
  - tools/move_parity.py.lines-40-100 (lines 40-100 of tools/move_parity.py)
  - tests/audit_chains174.sh.lines-150-156 (lines 150-156 of tests/audit_chains174.sh)
  - tests/expected/poke_readback.tsv.lines-1-15 (lines 1-15 of tests/expected/poke_readback.tsv)
