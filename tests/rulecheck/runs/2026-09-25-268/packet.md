THE PACKET

Decision kind: recommendation
Subject: #153: the tiers run immune to the working tree at a named commit — census, controls A-C, the snapshot cost, and the proposed design S1-S6 (after runs 265-267)
Claim (the working agent's sentence): Measured by the agent's own runs (plan_153.md, 'What was measured'): in a bare clone of 12571807 the freeze-cadence static tier reads PASS 128 / SKIP 30 / FAIL 20; with only out-of-git inputs supplied as copy-on-write copies the REAL runner in that clone reads PASS 177 / SKIP 0 / FAIL 1 (control C), the one FAIL (test_emulator_staleness, three stale gates) failing the same way in the working tree at freeze cadence, and test_fbneo_tree_integrity passing there against the tracked patch files; copy-on-write snapshots cost 8.91 s for all of build/ and under a second for each submodule, module dir and sibling. So the recommendation is plan_153.md's S1-S6: a plain clone with its own object store at the named commit, verified whole; all of build/, the submodule checkouts and the declared siblings snapshotted by copy-on-write at the start, ROMDIR checksum-verified; the snapshot under ~/.cache; a record of the commit, the start porcelain, the log, the submodule and bbh commits, and a listing plus fingerprints; a must-fire IMMUNITY control (S6) that perturbs the working tree during a snapshot run and must see no change, with a positive in-place leg; first slice the static tier at freeze and release cadence. Immunity is NOT claimed as shown: it is what S6 must prove once built. Not tested: plan_153.md's 'Not tested' list (immunity itself, a plain clone, the real runner in the tree at freeze cadence on this commit, inputs read only by controls, the release cadence's 5 gates, a commit other than HEAD, the emulator tier, completeness beyond build/ and the named siblings, a full-content hash's cost, the shared registry row of m5_stock19 and donovan6).
Artifacts (read every one, in full):
  - build/agent183b/plan_153.md
  - build/agent183b/probe153_static.log
  - build/agent183b/run50.sh
  - build/agent183b/run50_tree.txt
  - build/agent183b/run50_clone.txt
  - build/agent183b/run50_clone_rerun2.txt
  - build/agent183b/runner_clone_supplied.log
  - build/agent183b/staleness_tree_freeze.out
  - build/agent183b/staleness_clone_freeze.log
  - build/agent183b/clone_porcelain.txt
  - build/agent183b/snapshot_timing.txt
  - build/agent183b/snapshot_timing_submodules.txt
