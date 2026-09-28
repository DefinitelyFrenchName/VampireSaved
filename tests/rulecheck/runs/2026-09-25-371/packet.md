THE PACKET

Decision kind: recommendation
Subject: #159: rule Design A (the probe measured) and stage it for M21 on top of #182's staged patch
Claim (the working agent's sentence): Recommend to the maintainer, for #159: rule DESIGN A as the fix, and stage it for the M21 freeze the way #182's Design A is staged. The maintainer asked for the probe ("Build the probe now (Recommended)", maintainer_159_probe.txt), whose question said "Like #182, nothing would be frozen: the change would be staged for M21". The maintainer read the capture first: "Probe plays like native".
THE ROW. One [[site_thunk]] in build/manifest/donovan.toml. Only Donovan carries rule 5 (issue159_rule5_records.txt: "Phobos and Pyron carry no rule-5 record in the decoded tables"). It is the probe's row (manifest_diff.txt), renamed without "probe159_". site 0x01886C, old_hex b129005d6046, patch "jmp". Thunk: cmpi.b #5,d0; beq.s +6; eor.b d0,$5d(a1); rts; then vs2's rule-5 branch, byte for byte (thunk_bytes.txt: the rule-5 half equals vs2 0x171D6-0x171E5; the eor equals vsavj's 0x1886C bytes; the rts equals vsavj's 0x188B8, the fall-through's bra target; the resolver's other bytes 0x018854-0x0188B9 equal pristine vsavj). site_thunk_dis.txt disassembles the probe's site and thunk.
MEASURED ON THE PROBE (build/agent185/probe159/out, fingerprint e4d712eb; shipped M20 = build/m3b_merged28, 2dca438d):
- The facing gate: tests/audit_facing_rule.sh with BUILD= the probe (facing_rule_probe.log). Ours writes 1, 1, 1, 0, 0, 0 at 0x3FFD76, the thunk's rule-5 store, at native's six frames, and Demitri's x at 3946 is 755. Native writes the same and reads 755 there (tests/expected/facing_rule.tsv rows 12-25). The gate FAILs against its frozen defect rows, as a fix must. Its rule5-resolved control reads DEAD on the probe, because native's values change nothing in rows that already equal them.
- 32 geometries: probe_sweep_ours.sh ran the probe with the native sweep's pokes and legs. sweep_compare.log: every +0x5D write is the same as native's on 32 of 32 legs. The rule-5 stores are the same on 32 of 32 (frame, node, attacker x, velocity, victim x, value): 192 stores.
- The legacy oracle: tests/audit_merged_legacy.sh (MERGED_PREBUILT=1, MERGED_EXPECT=tests/expected/merged-m20). A probe copy relaxes only the op-count check (oracle_diff.txt). It PASSes with "53/53 legacy pairings evaluated", and its per-replay and verdict lines equal a fresh run on shipped M20 (oracle_probe_vs_m20.diff, empty). The full-log diff (oracle_fulllog.diff) is only the build path, the fingerprint, the op count (837 vs 835), three relocated char-init addresses and temp-file paths.
- The thunk runs on legacy content: facecount/controls.log, fighters' +0x5D byte writes by PC over those 53 replays. The fall-through wrote 1091 times: from the thunk (0x3FFD66) on the probe, and from 0x1886C on shipped M20 and on pristine vsavj. The count is the same on each of the 53 replays across all three. On the probe, 0x1886C writes 0 times and the rule-5 store 0x3FFD76 writes 0 times. Every tap ended (53 of 53 on each).
- The frame cost: tests/audit_lag_budget.sh, BUILD= the probe, REF= shipped M20 (lag_budget_probe.log). PASS: "no part has a zero-pass frame the reference lacks (1 on the build, 1 on the reference, over 44 parts)". Its lag-planted control fired.
- The capture: sheet/summon_sheet.png and sheet/summon_slide_full.png show native, shipped M20 and the probe on the same frames. The maintainer: "Probe plays like native" (maintainer_159_probe.txt).
THE STAGING, not yet made. build/manifest/staged/159_designA.patch will be made ON TOP of 182_designA.patch, because both re-freeze tests/test_tenant_loop.sh's op counts. Its op counts will be measured by tests/test_tenant_loop.sh in a scratch worktree with both applied. It carries the row, those counts, and the donovan table page's manifest hash, as 182's carries huitzil's. At M21 it is applied after 182's. The freeze then rebuilds every track, re-freezes tests/audit_facing_rule.sh (ours' rows to the measured values, and its rule5-resolved control redesigned so it can fire on a fixed build) and the reproducibility fingerprints, and deletes the file.
The probe moved other placed code: adding the thunk body shifted the first-fit placement of later bodies, so 364 shipped ops are not in the probe's op list (ops_diff.txt). The oracle and the lag gate above ran on those shifted bytes.
NOT tested:
- the other four rule-5 records (0xCA1CA, 0xCA1EA, 0xD17C2, 0xD1822): the thunk takes vs2's branch for any rule-5 record, but their moves were not run;
- rule 5 with a fighter rather than a projectile as the attacker;
- Donovan on the P2 side;
- FBNeo and MiSTer;
- the combination with #182's row (measured by the M21 freeze battery, not here);
- legacy content outside the oracle's 53 replays and the lag gate's 44 parts;
- idle-time margin short of a lost pass (the lag gate's own named gap).
Artifacts (read every one, in full):
  - build/agent185/probe159/maintainer_159_probe.txt
  - build/agent185/probe159/issue159_rule5_records.txt
  - build/agent185/probe159/manifest_diff.txt
  - build/agent185/probe159/builder_diff.txt
  - build/agent185/probe159/thunk_bytes.txt
  - build/agent185/probe159/site_thunk_dis.txt
  - build/agent185/probe159/facing_rule_probe.log
  - build/agent185/probe159/probe_sweep_ours.sh
  - build/agent185/probe159/sweep_compare.py
  - build/agent185/probe159/sweep_compare.log
  - build/agent185/probe159/oracle_diff.txt
  - build/agent185/probe159/oracle_probe_vs_m20.diff
  - build/agent185/probe159/oracle_fulllog.diff
  - build/agent185/probe159/merged_legacy_probe159.log
  - build/agent185/probe159/merged_legacy_m20base.log
  - build/agent185/probe159/facecount/run.sh
  - build/agent185/probe159/facecount/controls.log
  - build/agent185/probe159/lag_budget_probe.log
  - build/agent185/probe159/ops_diff.txt
  - build/agent185/probe159/sheet/run.sh
  - build/agent185/probe159/sheet/summon_sheet.png
  - build/agent185/probe159/sheet/summon_slide_full.png
  - tests/expected/facing_rule.tsv.lines-12-25 (lines 12-25 of tests/expected/facing_rule.tsv)
