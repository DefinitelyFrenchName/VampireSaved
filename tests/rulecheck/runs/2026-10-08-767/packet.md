THE PACKET

Decision kind: expectation
Subject: #228: audit_marionette_cost re-frozen after tests/lua/pc_count.lua counts the first frame and gains #213's alignment (after run 766)
Claim (the working agent's sentence): tests/expected/marionette_cost.tsv is to be re-frozen from the run in build/agent196/t228/marionette_aligned (pristine vsavj, the pinned reference MAME, 57 breakpoint legs) because tests/lua/pc_count.lua now counts the first frame_done as replay.lua does and the gate now checks #213's alignment (every breakpoint leg covered its counted frames in emulated time; 57 reference legs reproduced a replay.lua checksum at their anchor, 56 against the frozen masked-v2 basis and the witness 128_shadow_vs_legacy_vsavj against replay.lua run live on it by the gate; every leg's RAM:$FF8080 equalled its reference leg's; controls drift-clock, first-frame-skip and site-removed fired), and only the 13 per-site HIT rows in build/agent196/t228/marionette_freeze_diff.txt change while the static census, the asset rows and the worst-frame cost (14 executions, 812 modelled cycles) are identical; not tested: FBNeo, hook points the corpus never executes, the oracle-class cost of built hooks, vs2 code of hers that never names +0x3C3, her character data beyond the three records, and vh2's 3 extra sites (vs2 is the measured source).
Artifacts (read every one, in full):
  - tests/audit_marionette_cost.sh
  - tests/lua/pc_count.lua
  - tests/expected/marionette_cost.tsv
  - build/agent196/t228/marionette_aligned/got.tsv
  - build/agent196/t228/marionette_freeze_diff.txt
  - build/agent196/t228/marionette_aligned.log
  - build/agent196/t228/marionette_aligned/rl_128_shadow_vs_legacy_vsavj.log.lines-9000-9000 (lines 9000-9000 of build/agent196/t228/marionette_aligned/rl_128_shadow_vs_legacy_vsavj.log)
  - build/agent196/t228/marionette_aligned/ref_128_shadow_vs_legacy_vsavj.txt
