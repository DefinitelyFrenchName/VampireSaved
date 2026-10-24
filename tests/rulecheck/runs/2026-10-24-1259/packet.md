THE PACKET

Decision kind: recommendation
Subject: #304 closed done: all four adopted recommendations met (item 2 built and compared, 14z-208), after runs 2026-10-24-1254 to -1258
Claim (the working agent's sentence): #304 can close done (build/agent208/t304/closing_304.md; docs/project/tickets.tsv line 85): the maintainer adopted four recommendations (DECISIONS_HISTORY.md 2026-10-23 entries, build/agent207/t304/recommendation.md) and ruled item 2's two choices (the 2026-10-24 entry); items 1 and 3 were built in 14z-207 (STATE.md 14z-207 section (4)); item 2 is built and committed (47c118e4; fork U2, build/agent208/U2/REPORT.md; build/agent208/t304/run_on_snapshot.diff and snapshot_runs.diff), resting on fork U's census (build/agent208/U/REPORT.md), with one departure from the adopted text — the recommendation kept build/static_runs, the build leaves it out — ruled 'Leave it out (Recommended)' (the DECISIONS_HISTORY.md entry '#304 item 2: build/static_runs stays out of the snapshot'); the with/without comparison the ruling required was made (build/agent208/U2/compare.txt, setup about 1,112 s against 95 s; the emulator --dry-run pair's resolved commands identical, build/agent208/U2/emu_dryrun.diff, its with-scratch leg run in the main tree and so also listing the six untracked #229 gates, each on #229's file list and none tracked, build/agent208/t304/batch_tier_noscratch.txt); because most of that comparison's rows were carried from one shared --confirm base, every gate was then run without scratch twice: a full freeze-cadence strict tier of batch tree 2b6d703c, PASS 215, 421 controls honoured, FAIL 3, each traced to a cause other than scratch (build/agent208/t304/fulltier_noscratch.txt; the staleness FAIL's counts, gate names and every differing path accounted for with and without scratch, build/agent208/t304/staleness_with_without.txt and staleness_paths.txt), and a full session-cadence strict tier of the fixed batch tree d24d8ff4, committed as 47c118e4, GREEN, PASS 106, 390 controls honoured, test_build_retention, test_run_on_snapshot, test_emulator_staleness and test_rule_checker PASS (build/agent208/t304/batch_tier_noscratch.txt); the gate test_run_on_snapshot passes with all 12 controls firing as modes (build/agent208/U2/modes.txt); item 4 (sharding only if still too slow) is judged not needed by the orchestrator, with no threshold set by the maintainer: the planner's step took 51.7 s with scratch and 9.6 s without, and the snapshot's setup 95 s without scratch (build/agent208/t304/plan_times.txt). NOT TESTED: no trace of scratch reads exists on the Mac (fork I's strace was PILOT's, where the Mac's scratch does not exist), so a static gate that reads a scratch path built from data and passes vacuously on an empty input when scratch is absent would read PASS in the scratch-free tiers too, and no control separates it — the same for a gate reading scratch only under a condition the tiers did not reach; the 16 release- and ondemand-cadence static gates did not run without scratch; no emulator tier was run without scratch (the dry-run pair only, as ruled); the with-scratch legs of the staleness comparison and the dry-run pair ran in the main tree, not in a snapshot that kept scratch, so they differ from their scratch-free legs by #229's untracked files as well as by scratch; a relative scratch --confirm base was exercised end to end only in section 5's test world; the new copy loop ran on macOS only; test_run_on_snapshot's controls were not re-traced for the concurrent list (it is off the list until the freeze's re-trace); item 4's 'not too slow' is a judgement, not a measured threshold.
Artifacts (read every one, in full):
  - build/agent208/t304/issue304_body.md
  - build/agent208/t304/issue304.md
  - build/agent208/t304/closing_304.md
  - docs/project/tickets.tsv.lines-85-85 (lines 85-85 of docs/project/tickets.tsv)
  - build/agent207/t304/recommendation.md
  - build/agent208/U/REPORT.md
  - build/agent208/U2/REPORT.md
  - build/agent208/U2/compare.txt
  - build/agent208/U2/emu_dryrun.diff
  - build/agent208/U2/modes.txt
  - build/agent208/t304/run_on_snapshot.diff
  - build/agent208/t304/snapshot_runs.diff
  - build/agent208/t304/plan_times.txt
  - build/agent208/t304/fulltier_noscratch.txt
  - build/agent208/t304/staleness_with_without.txt
  - build/agent208/t304/staleness_paths.txt
  - build/agent208/t304/batch_tier_noscratch.txt
  - STATE.md.lines-129-150 (lines 129-150 of STATE.md)
  - DECISIONS_HISTORY.md.lines-7749-7770 (lines 7749-7770 of DECISIONS_HISTORY.md: its INDEX entry "## Ruled 2026-10-23 (14z-207) — #304: the four recommendations adopted", and the entries after it up to line 7770)
  - DECISIONS_HISTORY.md.lines-7893-7902 (lines 7893-7902 of DECISIONS_HISTORY.md: its INDEX entry "## Ruled 2026-10-24 (14z-208) — #304 item 2: a relative scratch `--confirm` base is copied in; the e")
  - DECISIONS_HISTORY.md.lines-7960-7966 (lines 7960-7966 of DECISIONS_HISTORY.md: its INDEX entry "## Ruled 2026-10-24 (14z-208) — #304 item 2: build/static_runs stays out of the snapshot")
