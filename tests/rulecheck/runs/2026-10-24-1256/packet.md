THE PACKET

Decision kind: recommendation
Subject: #304 closed done: all four adopted recommendations met (item 2 built and compared, 14z-208), after runs 2026-10-24-1254 and -1255
Claim (the working agent's sentence): #304 can close done (build/agent208/t304/closing_304.md; docs/project/tickets.tsv line 85): the maintainer adopted four recommendations (DECISIONS_HISTORY.md 2026-10-23 entries, build/agent207/t304/recommendation.md) and ruled item 2's two choices (the 2026-10-24 entry); items 1 and 3 were built in 14z-207 (STATE.md 14z-207 section (4)); item 2 is built here (fork U2, build/agent208/U2/REPORT.md; build/agent208/t304/run_on_snapshot.diff and snapshot_runs.diff), resting on fork U's census (build/agent208/U/REPORT.md); the with/without comparison the ruling required was made (build/agent208/U2/compare.txt, setup about 1,112 s against 95 s; the emulator --dry-run pair identical, build/agent208/U2/emu_dryrun.diff), and because most of that comparison's rows were carried from one shared --confirm base, every gate was then run without scratch: a full freeze-cadence strict tier with no --confirm and every control executed, on a scratch-free snapshot of this sitting's batch tree 2b6d703c — PASS 215, 421 controls executed and honoured, 16 release/ondemand gates deferred, FAIL 3, each traced to a cause other than scratch (build/agent208/t304/fulltier_noscratch.txt: run 2026-10-24-1254 then unresolved, its resolution shown from the ledger in build/agent208/t304/staleness_with_without.txt; a bug in #307's new tool caught by its own gate; test_emulator_staleness at freeze cadence, which run again with and without scratch reports the same counts, 178 stale and 1 red, and the same 221 gate names, its 122 differing path-list lines naming no scratch directory and coming from the main tree's untracked #229 files, build/agent208/t304/staleness_with_without.txt); the gate test_run_on_snapshot passes with all 12 controls firing as modes (build/agent208/U2/modes.txt); item 4 (sharding only if still too slow) is judged not needed by the orchestrator, with no threshold set by the maintainer: the planner's step took 51.7 s with scratch and 9.6 s without, and the snapshot's setup 95 s without scratch (build/agent208/t304/plan_times.txt). NOT TESTED: no trace of scratch reads exists on the Mac (fork I's strace was PILOT's, where the Mac's scratch does not exist), so a static gate reading scratch only under a condition the full tier did not reach would not be seen; the 16 release- and ondemand-cadence static gates did not run without scratch; no emulator tier was run without scratch (the dry-run pair only, as ruled); a relative scratch --confirm base was exercised end to end only in section 5's test world; the new copy loop ran on macOS only; test_run_on_snapshot's controls were not re-traced for the concurrent list (it is off the list until the freeze's re-trace); of the full tier's three FAILs two were reproduced in a fresh scratch-free snapshot and the staleness one compared with and without scratch, none re-run inside the same tier; item 4's 'not too slow' is a judgement, not a measured threshold.
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
  - STATE.md.lines-129-150 (lines 129-150 of STATE.md)
  - DECISIONS_HISTORY.md.lines-7748-7769 (lines 7748-7769 of DECISIONS_HISTORY.md: its INDEX entry "## Ruled 2026-10-23 (14z-207) — #304: the four recommendations adopted", and the entries after it up to line 7769)
  - DECISIONS_HISTORY.md.lines-7892-7901 (lines 7892-7901 of DECISIONS_HISTORY.md: its INDEX entry "## Ruled 2026-10-24 (14z-208) — #304 item 2: a relative scratch `--confirm` base is copied in; the e")
