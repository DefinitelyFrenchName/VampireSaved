THE PACKET

Decision kind: expectation
Subject: M21 freeze: re-freeze chains174.tsv (#182's two air-block rows IDENT), facing_rule.tsv (ours = native's rule-5 values, control rule5-flipped) and facing_sweep.tsv (32/32 SAME) on build/m3b_merged29
Claim (the working agent's sentence): Re-freeze three expectations on the M21 merged build (build/m3b_merged29, program aacc7e71, deltas_measurer.txt), which the maintainer's "Run the M21 freeze now" (maintainer_queue_14z185.txt) makes the build under test. The two ruled fixes it carries are #182 (maintainer_14z185.txt, "Design A") and #159 (maintainer_159_probe.txt, "Design A, stage for M21 (Recommended)").
WHAT MOVES, read from each gate's plain run on M21 before any freeze.
- tests/expected/chains174.tsv (audit_chains174.log): exactly two rows move. The two Phobos air-block Reflect Wall events, huitzil_c174 events 6 and 7, go from DIFF at +30 / +32 to IDENT. Every other row is unchanged, the entry and pin-landing checks read ok, and the five in-gate controls FIRED.
- tests/expected/facing_rule.tsv (audit_facing_rule.log): the six ours rows at 0x01886C writing 04 become rows at 0x3FFD76 (the merged thunk, a placement address) writing 01 01 01 00 00 00. These are native's rule-5 values at the same frames (the frozen native rows). Ours' x at 3946 goes from 835 to 755, native's value. The static, legacy and native rows and ours' 0x01884E caller rows are unchanged.
- The gate's rule5-resolved control (native's values over ours) read DEAD on M21, as the #159 staging predicted. It is replaced by rule5-flipped (facing_rule_gate.diff): ours' facing values with bit 0 flipped must differ. It FIRED in-gate (facing_rule_newctl.log, 12 rows); branch-planted FIRED. The header now states the fixed state and keeps the defect as history.
- tests/expected/facing_sweep.tsv (audit_facing_sweep2.log, sweep_keep/got.tsv, sweep_keep/diff.txt): all 32 legs read SAME (native and build write sequences identical). The diff against the frozen file is exactly the 32 leg rows and 32 build5 rows. No geom, masks, rule5, node or nodes-nofit row moves. The in-gate controls flip and perturb FIRED. Header: facing_sweep_gate.diff.
- audit_air_gc_legacy (the legacy control for #182) PASSes on M21 unchanged (audit_air_gc_legacy.log).
HOW each re-freeze is made: FREEZE=1 with each gate's own writer, then a plain verify run, then every CONTROL=<name> mode run against the new file. (The modes run before the freeze, facing_*_ctl_*.log, fail trivially against the old defect rows and are not evidence.) chains174.tsv's kept header gets a dated note of the move.
NOT TESTED, named:
- The captures the maintainer read were of the single-fix probes (Probe A for #182, phobos_air_gc_sheet; probe 159 for #159, summon_sheet), not of M21. M21's merged program equals the 14z-185 probe built with both staged rows (aacc7e71), which no capture showed.
- The rest of the M21 freeze battery (the legacy oracle on M21, the suite, FBNeo, MiSTer) is not part of these re-freezes and has not run yet.
- Donovan's other rule-5 records (0xCA1CA/0xCA1EA, 0xD17C2/0xD1822) and P2-side tenants are outside audit_facing_rule (its header says so).
- Other air guard cancels, beyond Lei-Lei's and Zabel's legacy control and Phobos's two rig events, are not covered.
Artifacts (read every one, in full):
  - build/agent185/maintainer_queue_14z185.txt
  - build/agent185/air_gc/maintainer_14z185.txt
  - build/agent185/t159/maintainer_159_probe.txt
  - build/agent185/m21/deltas_measurer.txt
  - build/agent185/m21/edit_check.txt
  - build/rc185/moved/audit_chains174.log
  - build/rc185/moved/audit_facing_rule.log
  - build/rc185/moved/facing_rule_newctl.log
  - build/rc185/moved/facing_rule_gate.diff
  - build/rc185/moved/audit_facing_sweep2.log
  - build/rc185/moved/sweep_keep/got.tsv
  - build/rc185/moved/sweep_keep/diff.txt
  - build/rc185/moved/facing_sweep_gate.diff
  - build/rc185/moved/audit_air_gc_legacy.log
  - tests/expected/chains174.tsv
  - tests/expected/facing_rule.tsv
  - tests/expected/facing_sweep.tsv
