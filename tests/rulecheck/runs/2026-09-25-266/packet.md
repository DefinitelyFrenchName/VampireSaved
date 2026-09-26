THE PACKET

Decision kind: recommendation
Subject: #153: the tiers run immune to the working tree at a named commit — census, two controls, the snapshot cost, and the proposed design S1-S5 (after run 265)
Claim (the working agent's sentence): Measured by the agent's own runs (plan_153.md, 'What was measured'): in a bare clone of 12571807 the freeze-cadence static tier reads PASS 128 / SKIP 30 / FAIL 20; the same 50 non-passing gates all PASS in the working tree at that commit (control A), and all 50 PASS in the clone once only out-of-git inputs are supplied as copy-on-write copies (control B: 48, then 2 more after three inputs the census missed were added), so in these 50 the cause is the out-of-git input and nothing else clone-specific showed; a copy-on-write snapshot of all of build/ takes 9.2 s for 62,279 files. So the recommendation is plan_153.md's S1-S5: a clone at the named commit, verified whole; the whole of build/, the submodule checkouts and the declared siblings snapshotted by copy-on-write at the start (ROMDIR checksum-verified in place); the snapshot under ~/.cache outside the tmp reaper; a record of the commit, the start porcelain, the runner's log, the submodule and bbh commits, and a listing plus fingerprints of the snapshot; first slice the static tier at freeze and release cadence. Not tested: plan_153.md's 'Not tested' list (the full tier in a snapshot, inputs read only by controls, the emulator tier, completeness beyond build/ and the named siblings, a full-content hash's cost, the shared registry row of m5_stock19 and donovan6).
Artifacts (read every one, in full):
  - build/agent183b/plan_153.md
  - build/agent183b/probe153_static.log
  - build/agent183b/probe_nonpass.txt
  - build/agent183b/run50.sh
  - build/agent183b/run50_tree.txt
  - build/agent183b/run50_clone.txt
  - build/agent183b/run50_clone_rerun2.txt
  - build/agent183b/run50_clone_VOID_relative_outdir.txt
  - build/agent183b/build_dir_fingerprints.txt
  - build/agent183b/prior_art_reader.txt
