THE PACKET

Decision kind: recommendation
Subject: #182: recommend Design A (a Phobos-only guard window at vsavj's block entry), re-checked after runs 331-333
Claim (the working agent's sentence): Recommend to the maintainer Design A for #182 (plan182.md). Design A is one [[site_thunk]] row in build/manifest/huitzil.toml at vsavj's block entry CPU:$02393A. It performs the original +0x140 := 0x12 store and, for fighter id TT = 0x10 only, sets +0x158 := 0x0E and +0x1AB := 0x0E before returning to 0x023940; this is vs2's own id-0x10 branch (disasm_gc.txt: vs2 0x022480/0x0224C4). The recommendation rests on Probe A: that row added to a copy of huitzil.toml (manifest_diff.txt), built by a copy of tools/build_merged.sh (builder_diff.txt; 837 ops, build.log), with its patched site and thunk shown from the built image (controls.log). The results on Probe A: (1) Phobos's two air-block events of tests/replays/chains174/huitzil_c174 match native vs2 on 540/540 frames on ten traced fields, and again 540/540 in a NOGC=1 variant that holds back instead of the 623 motion (the full window), where merged-m20 matches on 34 and 517; every trace run fresh, its end line required, its fingerprint named (compare.log, build.txt: Probe A f9f6f2fc, merged-m20 2dca438d); (2) a capture of both events on native, merged-m20 and Probe A (phobos_air_gc_sheet.png) was read by the maintainer, "Same, confirmed" (maintainer_14z185.txt); (3) tests/audit_chains174.sh turns its two air-block rows from DIFF to IDENT and leaves every other row as frozen (chains174.log, headed by the Probe A fingerprint f9f6f2fc); (4) tests/audit_air_gc_legacy.sh passes (air_gc_legacy.log); (5) tests/audit_merged_legacy.sh, through a probe copy that only overrides the op-count check (oracle_diff.txt), against merged-m20's 53-spec class table (expect_table.log), passes 53/53 with every per-replay line identical to the same run on the shipped merged-m20 (merged_legacy_probeA.log, merged_legacy_m20base.log). That oracle exercises the hook: 171 block entries in 8 of the 53 replays go through the thunk on Probe A (0 through the replaced 0x02393A), the same counts per replay as pristine vsavj and merged-m20 (the out_*/summary.txt files, controls.log). Design B, a patch in Phobos's own check, is not built and is not recommended, on the reading that the window is written only at block entry and on one measurement: its one considered form, keyed on the air-block state, would open for 28 and 27 frames against native's full window of 12 and 11, both measured with no guard cancel attempted (airblock_lengths.log). NOT tested: any other state a Design B could key on (B never built or captured); the cycle cost (estimated at about 50 cycles per block entry, not measured); FBNeo and the MiSTer lane on Probe A; the solo Phobos track built with the row; Phobos as P2; any air block other than these two events; the static tier and the freeze battery on the probe; how the rule-5 census classifies the row; and the vs2 Dark Force air-guard-cancel glitch, which the plan asks to measure before building.
Artifacts (read every one, in full):
  - build/agent185/plan182.md
  - build/agent185/probeA/manifest_diff.txt
  - build/agent185/probeA/builder_diff.txt
  - build/agent185/probeA/oracle_diff.txt
  - build/agent185/probeA/build.log
  - build/agent185/phobos_trace/run.sh
  - build/agent185/phobos_trace/compare.py
  - build/agent185/phobos_trace/compare.log
  - build/agent185/phobos_trace/probeA/build.txt
  - build/agent185/phobos_trace/m20/build.txt
  - build/agent185/phobos_trace/nogc_probeA/build.txt
  - build/agent185/phobos_trace/nogc_m20/build.txt
  - build/agent185/phobos_trace/airblock_lengths.log
  - build/agent185/phobos_sheet/run.sh
  - build/agent185/phobos_sheet/phobos_air_gc_sheet.png
  - build/agent185/probeA/chains174.log
  - build/agent185/probeA/air_gc_legacy.log
  - build/agent185/probeA/merged_legacy_probeA.log
  - build/agent185/probeA/merged_legacy_m20base.log
  - build/agent185/probeA/expect_table.log
  - build/agent185/probeA/blockcount/run.sh
  - build/agent185/probeA/blockcount/out_probeA/summary.txt
  - build/agent185/probeA/blockcount/out_vsavj/summary.txt
  - build/agent185/probeA/blockcount/out_m20/summary.txt
  - build/agent185/probeA/blockcount/controls.log
  - build/agent185/air_gc/disasm_gc.txt
  - build/agent185/air_gc/maintainer_14z185.txt
  - build/agent185/resolve_331.txt
  - build/agent185/resolve_332.txt
  - build/agent185/resolve_333.txt
