THE PACKET

Decision kind: recommendation
Subject: #317 closed done: snapshot setup measured and cut, change 2 dropped (ruled), the re-run after a red based on the red run (14z-208), after run 2026-10-24-1266
Claim (the working agent's sentence): #317 can close done (build/agent208/t317/closing_317.md; docs/project/tickets.tsv line 74): its done-when (build/agent208/t317/issue317_body.md) — the remaining setup measured by part (fork S2, build/agent208/S2/REPORT.md: 74-80 s, about 26 s of it git status slowed by a stale emu/mame index.lock, removed — docs/project/gotchas.md 'A STALE SUBMODULE'), the incremental re-snapshot built with a gate — replaced by the maintainer's ruling to drop it after its cost was measured (the two DECISIONS_HISTORY.md #317 entries, quoted), the close basing a re-run on the red run (tools/close.py, docs/project/session_close.md, test_session_close's control red-base-ignored, which covers a re-run based on {PREV} again; build/agent208/t317/close_change.diff), and a measured red-then-green tier against a full one (build/agent208/t317/red_green_pair.txt: the red full freeze-cadence tier 24 s setup and 1,279 s in all, the green --confirm re-run on its results 25 s setup and 249 s in all; the runner seconds 1,245 and 213 are each record's start-to-end) — is met, the setup change committed in dd1154f5 (build/agent208/t317/snapshot_change.diff; docs/project/snapshot_runs.md). NOT TESTED: the pair's two tiers ran at different cadences (freeze, then session), so 249 s is not a same-cadence re-run's cost; the green re-run was launched by hand with the red run's results, not through tools/close.py's new path, which only its self-test exercised; that path's fallback ({PREV} when a red run wrote no results) has a self-test case and no control, so a fallback picking the wrong base would not fire a control; no control removes the wait on the background build/ copy, nor the wait on the background working-tree git status before the first submodule git dir is copied (a status refreshes those dirs' index files), so a race there would not fire a control — both orderings read from the code; the stale lock's origin is a likely one (test_close_tools's controls take that lock), not measured; setup on Linux or PILOT and with emulator inputs; S2's own setup timings were taken with the Mac loaded (load 4-12).
Artifacts (read every one, in full):
  - build/agent208/t317/issue317_body.md
  - build/agent208/t317/closing_317.md
  - docs/project/tickets.tsv.lines-74-74 (lines 74-74 of docs/project/tickets.tsv)
  - build/agent208/S2/REPORT.md
  - build/agent208/t317/red_green_pair.txt
  - build/agent208/t317/close_change.diff
  - build/agent208/t317/snapshot_change.diff
  - docs/project/snapshot_runs.md.lines-126-195 (lines 126-195 of docs/project/snapshot_runs.md)
  - docs/project/gotchas.md.lines-7564-7574 (lines 7564-7574 of docs/project/gotchas.md)
  - DECISIONS_HISTORY.md.lines-7987-7994 (lines 7987-7994 of DECISIONS_HISTORY.md: its INDEX entry "## Ruled 2026-10-24 (14z-208) — #317: snapshot setup measured, incremental re-snapshot after a red, ")
  - DECISIONS_HISTORY.md.lines-7995-8001 (lines 7995-8001 of DECISIONS_HISTORY.md: its INDEX entry "## Ruled 2026-10-24 (14z-208) — #317: change 2 (incremental re-snapshot) measured and dropped")
