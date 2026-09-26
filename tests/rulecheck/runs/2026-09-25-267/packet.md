THE PACKET

Decision kind: recommendation
Subject: #153: the tiers run immune to the working tree at a named commit — census, controls A-C, the snapshot cost, and the proposed design S1-S5 (after runs 265-266)
Claim (the working agent's sentence): Measured by the agent's own runs (plan_153.md, 'What was measured'): in a bare clone of 12571807 the freeze-cadence static tier reads PASS 128 / SKIP 30 / FAIL 20; with only out-of-git inputs supplied as copy-on-write copies, the REAL runner in that clone reads PASS 177 / SKIP 0 / FAIL 1 (control C), and the one FAIL (test_emulator_staleness, three gates stale since d4cd4d51) fails identically in the working tree at freeze cadence; controls A and B (run50.sh, per gate) agree except on that gate, because run50.sh omitted the runner's VS_CADENCE — so run50.sh is not the runner, and control C is the one that decides. A copy-on-write snapshot of all of build/ takes 8.91 s real for 62,298 files (snapshot_timing.txt). So the recommendation is plan_153.md's S1-S5: a clone at the named commit verified whole (tracked porcelain empty except submodules carrying their tracked patches, checked against the patch files); all of build/, the submodule checkouts and the declared siblings snapshotted by copy-on-write at the start, ROMDIR checksum-verified in place; the snapshot under ~/.cache outside the tmp reaper; a record of the commit, the start porcelain, the runner's log, the submodule and bbh commits, and a listing plus fingerprints of the snapshot; first slice the static tier at freeze and release cadence. Not tested: plan_153.md's 'Not tested' list (inputs read only by controls, the release cadence's 5 gates, a commit other than HEAD, the emulator tier, completeness beyond build/ and the named siblings, a full-content hash's cost, the shared registry row of m5_stock19 and donovan6).
Artifacts (read every one, in full):
  - build/agent183b/plan_153.md
  - build/agent183b/probe153_static.log
  - build/agent183b/probe_nonpass.txt
  - build/agent183b/run50.sh
  - build/agent183b/run50_tree.txt
  - build/agent183b/run50_clone.txt
  - build/agent183b/run50_clone_rerun2.txt
  - build/agent183b/runner_clone_supplied.log
  - build/agent183b/staleness_tree_freeze.out
  - build/agent183b/clone_porcelain.txt
  - build/agent183b/snapshot_timing.txt
  - build/agent183b/build_dir_fingerprints.txt
