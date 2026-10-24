THE PACKET

Decision kind: recommendation
Subject: #304 closed done: all four adopted recommendations met (item 2 built and compared, 14z-208)
Claim (the working agent's sentence): #304 can close done (build/agent208/t304/closing_304.md; docs/project/tickets.tsv line 85): the maintainer adopted four recommendations (DECISIONS_HISTORY.md 2026-10-23 entries, build/agent207/t304/recommendation.md) and ruled item 2's two choices (the 2026-10-24 entry); items 1 and 3 were built in 14z-207 (STATE.md 14z-207 section (4)); item 2 is built here (fork U2, build/agent208/U2/REPORT.md; build/agent208/t304/run_on_snapshot.diff and snapshot_runs.diff), resting on fork U's census (build/agent208/U/REPORT.md) that no gate of either tier reads an input under a scratch directory; the with/without comparison the ruling required was made — the static tier with scratch (the commit tier of d181bcd1) against without (b74ce71e) on the same --confirm base, no verdict differing and every other row difference explained by the change set (build/agent208/U2/compare.txt), setup about 1,112 s against 95 s, and the emulator tier's --dry-run pair with identical resolved commands (build/agent208/U2/emu_dryrun.diff); the gate test_run_on_snapshot passes with all 12 controls firing as modes (build/agent208/U2/modes.txt); item 4 (sharding only if still too slow) is judged not needed by the orchestrator, with no threshold set by the maintainer: the planner's step took 51.7 s with scratch and 9.6 s without, and the snapshot's setup 95 s without scratch (build/agent208/t304/plan_times.txt). NOT TESTED: fork U's census is a reading of code text plus fork I's 14z-207 static strace — no emulator-tier gate was traced, so a runtime read through a data-built path under scratch would not be seen; no emulator tier was run without scratch (the dry-run pair only, as ruled); no freeze- or release-cadence static tier ran without scratch; a relative scratch --confirm base was exercised end to end only in section 5's test world; the new copy loop ran on macOS only; test_run_on_snapshot's controls were not re-traced for the concurrent list (it is off the list until the freeze's re-trace); the with-scratch leg is a different commit (d181bcd1) from the without-scratch leg (b74ce71e), so the comparison is of two trees, the differences attributed to the change set by the planner's reasons; item 4's 'not too slow' is a judgement, not a measured threshold.
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
  - STATE.md.lines-129-150 (lines 129-150 of STATE.md)
  - DECISIONS_HISTORY.md.lines-7747-7768 (lines 7747-7768 of DECISIONS_HISTORY.md: its INDEX entry "## Ruled 2026-10-23 (14z-207) — #304: the four recommendations adopted", and the entries after it up to line 7768)
  - DECISIONS_HISTORY.md.lines-7891-7898 (lines 7891-7898 of DECISIONS_HISTORY.md: its INDEX entry "## Ruled 2026-10-24 (14z-208) — #304 item 2: a relative scratch `--confirm` base is copied in; the e")
