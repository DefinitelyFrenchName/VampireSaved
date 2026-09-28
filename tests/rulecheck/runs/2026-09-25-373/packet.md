THE PACKET

Decision kind: expectation
Subject: tests/expected/facing_sweep.tsv frozen on merged-m20 (new gate tests/audit_facing_sweep.sh, #159's 32-geometry sweep promoted; re-checked after 372, build5 rows added)
Claim (the working agent's sentence): Freeze tests/expected/facing_sweep.tsv as measured on merged-m20 (build/m3b_merged28), and commit the new gate tests/audit_facing_sweep.sh with its reader tools/facing_sweep.py and instrument tests/lua/facing_tap.lua. This promotes the #159 sweep this session ran from build/ into the suite ([VSP-18]).
WHAT IT FREEZES (facing_sweep_frozen.tsv, 126 rows). There are 32 legs: the donovan_3 rig's Killshread Summon (ES), with P1/P2 x poked over 3790-3800 to 16 separations on each side, each run on native vs2 and on the build.
- One leg row per geometry: every write to Demitri's +0x5C word as (frame, mask, value), native and build, count and sha; all 32 read DIFF on M20, the #159 defect.
- One rule5 row per leg: native's rule-5 values in order.
- One build5 row per leg: the build's last +0x5D value on each of native's rule-5 frames. On M20: 4,4,4,4,4,4 on all 16 side-L legs (1 XOR 5); on side R, 5 at every contact on 12 legs (0 XOR 5), and on 4 legs 5 at the first contact or two and "-" after (no build write on those frames).
- One node row per native anim node: which vsavj facing rule, computed from native's logged state at each contact, equals native's value at every contact of that node; nodes-nofit 13 of 29.
THE RUNS (all on this commit's gate, M20 unless named):
- FREEZE=1 wrote 126 rows (gate_freeze.log).
- A plain run PASSes with both in-gate controls FIRED: flip ("native's values inverted change the node rows (18 rows)") and perturb ("one build write XORed changes the L_60 row") (gate_plain.log).
- CONTROL=flip and CONTROL=perturb each FAIL the gate: "CONTROL FIRED: ... the planted read fails the gate" (gate_ctl_flip.log, gate_ctl_perturb.log).
- BUILD= probe 159: all 32 legs SAME and nodes-nofit 13 of 29, and the gate FAILs against the M20 rows (gate_probe159.log). That is the change the M21 freeze will re-freeze. Probe 159 is the staged row in a copy of donovan.toml (manifest_diff.txt; the row in build/manifest/staged/159_designA.patch). Its build fingerprint e4d712eb (probe159_build.log) equals the build made from the staged row in the tracked donovan.toml (merged_159.log).
THE NODE TABLE'S INPUTS. They are computed from native's logged state, not executed on vsavj. Two cross-checks were made on the probe_geo legs (build/agent185/t159/probe_geo.sh). First, ours' state equalled native's at every same-frame, same-node contact on every input the rules read (13 of 13, pre_check.log). Second, vsavj's negative rule, EXECUTED on ours (both Summon records patched to it), equalled the computed position sign on 30 of 30 contacts (geo_analysis.log). The swept legs' own inputs on ours were not compared.
THE RULING the gate's header quotes: maintainer_159_probe.txt and the DECISIONS_HISTORY.md #159 entry carry the question and the maintainer's answer, "Design A, stage for M21 (Recommended)", verbatim.
NOT covered (the gate's header says so): P2 standing only; Donovan as P1 only; the other four rule-5 records; a node STRUCTURE change as a data fix; FBNeo and MiSTer; separations the engine clamps (the far/mirror_far pokes of probe_geo did not move P2).
Artifacts (read every one, in full):
  - build/agent185/t159/facing_sweep_frozen.tsv
  - build/agent185/t159/gate_freeze.log
  - build/agent185/t159/gate_plain.log
  - build/agent185/t159/gate_ctl_flip.log
  - build/agent185/t159/gate_ctl_perturb.log
  - build/agent185/t159/gate_probe159.log
  - build/agent185/t159/pre_check.py
  - build/agent185/t159/pre_check.log
  - build/agent185/t159/geo.py
  - build/agent185/t159/geo_analysis.log
  - build/agent185/t159/probe_geo.sh
  - build/agent185/t159/probe159_build.log
  - build/agent185/t159/merged_159.log
  - build/agent185/t159/manifest_diff.txt
  - build/agent185/t159/maintainer_159_probe.txt
  - tests/audit_facing_sweep.sh
  - tools/facing_sweep.py
  - tests/lua/facing_tap.lua
  - build/manifest/staged/159_designA.patch
  - DECISIONS_HISTORY.md.lines-30-39 (lines 30-39 of DECISIONS_HISTORY.md)
