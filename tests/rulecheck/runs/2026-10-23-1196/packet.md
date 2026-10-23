THE PACKET

Decision kind: recommendation
Subject: #304 planner review: recommendations to the maintainer (14z-207), after runs 2026-10-23-1194 and -1195
Claim (the working agent's sentence): I put the four recommendations of recommendation.md to the maintainer for #304 (issue304.md), resting on fork I's analysis (REPORT.md) and the re-checks after run 2026-10-23-1194 (recheck/): a tracked list classing each build/ top-level directory with a census gate, because the registry names none of the seven emu_* directories the PILOT trace read (recheck/emu_in_registry.tsv, ur.txt); a snapshot without scratch, because setup grows with the files copied across the recorded runs (recheck/setup_vs_files.txt) and scratch is 5,182,386 of 5,241,597 listed files (snapshot_listing_prefixes.txt); a pruned listing whose 19651 paths equal the full listing filtered by the planner's scratch rule on today's tree (recheck/pruned_vs_filtered.txt) but not by construction — on planted paths the glob prunes build/agent7-x/ and build/agent7.d/, which the rule keeps (recheck/plant_prune.txt, plant_prune.sh; no live directory has that shape, recheck/live_agent_shapes.txt) — so both are to be generated from the one list; a 4-process gate loop whose verdicts equal the 1-process loop's and the serial profiler's on one base (recheck/par2.log, recheck/cmp_par2_1_vs_4.txt, recheck/cmp_prof_vs_par2.txt, recheck/prof_tf.log); tracked-first ordering (prof/old_base_f_noscr_1.log, prof/old_base_f_noscr_tf_1.log); and sharding last. Not tested: how the 29 whole-tree R4 readers keep seeing scratch once it is pruned (always re-run, or a scratch-changed check: neither built nor measured); tiers with and without scratch in the snapshot, and so which gates fail or SKIP without it; a read trace on the Mac (the trace is PILOT's, from lane F's unlanded #313 fix, which these figures assume); the emulator tier's build/ needs; the parallel loop on PILOT or ERIS; whether par_plan2.py and prof_plan.py both reproduce tools/static_confirm.py's own predict() — they copy its loop body and were compared with each other, not with a planner run; the per-file copy cost spread over 5.24 M files is an extrapolation; the 5,000-path refusal threshold is a proposal from normals of 53 and 405 (prof/f_head_1.log, prof/old_base_f_head_1.log); Mac timings ran beside the #291 sheet run (recheck/load_start.txt, recheck/load_end.txt).
Artifacts (read every one, in full):
  - build/agent207/t304/recommendation.md
  - build/agent207/t304/REPORT.md
  - build/agent207/t304/issue304.md
  - build/agent207/t304/ur.txt
  - build/agent207/t304/build_needs.txt
  - build/agent207/t304/build_names_in_code.txt
  - build/agent207/t304/snapshot_listing_prefixes.txt
  - build/agent207/t304/snapsteps.txt
  - build/agent207/t304/r4_readers.txt
  - build/agent207/t304/prof/f_head_1.log
  - build/agent207/t304/prof/old_base_f_head_1.log
  - build/agent207/t304/prof/old_base_f_noscr_1.log
  - build/agent207/t304/prof/old_base_f_noscr_tf_1.log
  - build/agent207/t304/par_plan.py
  - build/agent207/t304/par_plan2.py
  - build/agent207/t304/prof_plan.py
  - build/agent207/t304/recheck/emu_in_registry.tsv
  - build/agent207/t304/recheck/setup_vs_files.txt
  - build/agent207/t304/recheck/pruned_vs_filtered.txt
  - build/agent207/t304/recheck/plant_prune.txt
  - build/agent207/t304/recheck/live_agent_shapes.txt
  - build/agent207/t304/plant_prune.sh
  - build/agent207/t304/recheck/par2.log
  - build/agent207/t304/recheck/prof_tf.log
  - build/agent207/t304/recheck/cmp_par2_1_vs_4.txt
  - build/agent207/t304/recheck/cmp_prof_vs_par2.txt
  - build/agent207/t304/recheck/cmp_par_1_vs_4.txt
  - build/agent207/t304/recheck/prof_vs_par_old.diff
  - build/agent207/t304/recheck/load_start.txt
  - build/agent207/t304/recheck/load_end.txt
  - build/agent207/t304/recheck.sh
  - build/agent207/t304/recheck_static.sh
