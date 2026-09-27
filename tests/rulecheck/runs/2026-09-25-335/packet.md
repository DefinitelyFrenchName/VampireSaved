THE PACKET

Decision kind: build
Subject: #182: commit the Design A row to build/manifest/huitzil.toml and re-freeze test_tenant_loop's op counts
Claim (the working agent's sentence): Commit the #182 fix: add the Design A row (air_block_guard_window, a [[site_thunk]] at CPU:$02393A) to build/manifest/huitzil.toml, and re-freeze tests/test_tenant_loop.sh by +2 ops in every composition carrying huitzil (solo 375 -> 377, 2-tenant 622 -> 624, 3-tenant 835 -> 837). The maintainer ruled "Design A" (decisions.diff, quoting maintainer_14z185.txt). The row equals Probe A's row in every field but its name (row_vs_probe.txt), and the merged build from the tracked manifests fingerprints f9f6f2fc, identical to Probe A, where the shipped merged-m20 is 2dca438d (fingerprints.txt). So the Probe A measurements that rule-checker run 2026-09-25-334 read as OK (run334_verdict_real.txt, plan182.md) apply to this build unchanged. test_tenant_loop passes at the new counts (tenant_loop.log, tenant_loop.diff). NOT tested: the solo huitzil track built with the row (only its generation and op count, by test_tenant_loop); FBNeo and the MiSTer lane; the static tier on this commit (it runs before the commit); the freeze battery; and the audit_chains174 re-freeze of its two air-block rows to IDENT, deferred to the freeze because the gate's default build is the frozen M20.
Artifacts (read every one, in full):
  - build/agent185/buildcommit/manifest.diff
  - build/agent185/buildcommit/tenant_loop.diff
  - build/agent185/buildcommit/row_vs_probe.txt
  - build/agent185/buildcommit/fingerprints.txt
  - build/agent185/buildcommit/tenant_loop.log
  - build/agent185/buildcommit/decisions.diff
  - build/agent185/buildcommit/run334_verdict_real.txt
  - build/agent185/plan182.md
  - build/agent185/air_gc/maintainer_14z185.txt
