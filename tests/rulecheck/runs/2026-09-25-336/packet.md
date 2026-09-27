THE PACKET

Decision kind: build
Subject: #182: commit the Design A row to build/manifest/huitzil.toml and re-freeze test_tenant_loop's op counts, re-checked after run 335
Claim (the working agent's sentence): Commit the #182 fix: add the Design A row (air_block_guard_window, a [[site_thunk]] at CPU:$02393A) to build/manifest/huitzil.toml, and re-freeze tests/test_tenant_loop.sh by +2 ops in every composition carrying huitzil (solo 375 -> 377, 2-tenant 622 -> 624, 3-tenant 835 -> 837). The maintainer answered "Design A. This being said is design A a purely character specific hook or dose it carry any risk of side effect?" (maintainer_14z185.txt; recorded in decisions.diff). The row equals Probe A's in every field but its name (row_vs_probe.txt). The merged build from the tracked manifests fingerprints f9f6f2fc, identical to Probe A, where the shipped merged-m20 is 2dca438d (fingerprints.txt), so the Probe A measurements that rule-checker run 2026-09-25-334 read as OK (run334_verdict_real.txt, plan182.md) apply to this build unchanged. test_tenant_loop passes at the new counts (tenant_loop.log, tenant_loop.diff), and tests/test_rule5_census.sh passes with the row (rule5.log). The Dark Force glitch, measured first as the maintainer asked ("Measure first (Recommended)"): one native vs2 P+K Power run (dfglitch run.sh, dfglitch_ft_native_power.txt), in which the air guard cancel fired in Power and Phobos walked and attacked after landing; ours' P+K entered the flight form, where the rig's jump-in produced no air block (dfglitch_ft_probeA_change.txt, dfglitch_ft_m20_change.txt). The maintainer placed the glitch in "P+K Power". That P+K on ours is vsav's Change, not vs2's Power, is our reading from the 14z-168 Dark Force ruling, not a ruling of this session. NOT tested: the glitch at any other timing, and whether Phobos can air-block in his flight form (the glitch is not reproduced, and not excluded); any other state a Design B could key on; the cycle cost (estimated at about 50 cycles per block entry, not measured); FBNeo and the MiSTer lane; the solo huitzil track built with the row (only its generation and op count, by test_tenant_loop); Phobos as P2; any air block other than the two chains174 events; the static tier on this commit (it runs before the commit); the freeze battery; and the audit_chains174 re-freeze of its two air-block rows to IDENT, deferred to the freeze because the gate's default build is the frozen M20.
Artifacts (read every one, in full):
  - build/agent185/buildcommit/manifest.diff
  - build/agent185/buildcommit/tenant_loop.diff
  - build/agent185/buildcommit/row_vs_probe.txt
  - build/agent185/buildcommit/fingerprints.txt
  - build/agent185/buildcommit/tenant_loop.log
  - build/agent185/buildcommit/rule5.log
  - build/agent185/buildcommit/decisions.diff
  - build/agent185/buildcommit/run334_verdict_real.txt
  - build/agent185/plan182.md
  - build/agent185/air_gc/maintainer_14z185.txt
  - build/agent185/dfglitch/run.sh
  - build/agent185/buildcommit/dfglitch_ft_native_power.txt
  - build/agent185/buildcommit/dfglitch_ft_probeA_change.txt
  - build/agent185/buildcommit/dfglitch_ft_m20_change.txt
  - build/agent185/buildcommit/dfglitch_native_power.build.txt
  - build/agent185/buildcommit/dfglitch_probeA_change.build.txt
  - build/agent185/buildcommit/dfglitch_m20_change.build.txt
  - build/agent185/resolve_335.txt
