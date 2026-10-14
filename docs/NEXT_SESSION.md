# NEXT SESSION — orientation (rewritten at the 14z-200 CLOSE, 2026-10-14)

> Rewritten at every session close ([VSP-17]). ROLLOVER: the previous opener
> moves VERBATIM to the top of `NEXT_SESSION_HISTORY.md` — this file holds ONLY
> the live orientation. Session state, not knowledge: facts belong in the docs,
> status in STATE.md.

## THE SETUP, RESTATED

A plain **Opus 5.5 session at effort High** (the ruled orchestrator — STATE 'Standing rulings') on the
#172 setup:
- Every quoted figure comes from a `measurer` / `reader` spec (`docs/project/worker_spec.md`, the spec text IN the prompt, no model).
- Every freeze and recommendation goes through the pinned `rule-checker`, with the prompt files pasted VERBATIM.
- Then `record --session <transcript id>`, and `resolve` on ONE line with one label per violated question, only AFTER the work it names exists.
- Since #272, `rulecheck prepare` FLAGS figures, quotes and absolutes. Read its flags before spawning, and pass `--deliverable` for the report a packet puts forward.

Say so at the opener. Never spawn any agent at `max`. A recommendation leans only on the maintainer's OWN words.
**Before any long job, check whether PILOT (`ssh pilot`) or ERIS (`ssh eris`) is idle, and run independent work
there in parallel.** A long tier runs on a snapshot (`tests/run_on_snapshot.sh`), so the tree can be edited meanwhile.

**THE SESSION CLOSE CHANGED (#269, 14z-200):** a session close runs `ROMDIR=... tests/run_all_static.sh --strict
--confirm <the previous close's results.tsv>` (HANDOFF "How to test"). It re-runs the gates whose followed paths
changed, the `# CONFIRM: always` core (`test_commit_subject`, `test_close_tools`, `test_rule_checker`) and any gate
whose controls the base did not execute, and carries the rest by name. A freeze and a release still run everything;
`--confirm` is refused there. The 14z-200 close's run of record is named in STATE 14z-200's CLOSE row.

## START HERE

0. **AT THE OPENER, RUN `python3 tools/agent/sweep.py`.** Then put #269's closing to the maintainer: its done-when
   (a session close ran the predicted set and the core, its readout names what it carried, a freeze/release run is
   unchanged, the predictor's miss rate measured) — STATE 14z-200's CLOSE row says what the first confirm close showed.
1. **#273 — THE REPLICATION THE MAINTAINER CHOSE** (`DECISIONS_HISTORY.md` "Ruled 2026-10-13 (14z-199) — #273: replicate before deciding; …").
   - Pre-registered in `build/agent199/t273/plan_replication.md`: two more readers per arm on the 15 that mattered and the 4 fixtures (76 pinned spawns, the same staged copies and prompts in `build/agent199/t273/stage/`), judged blind like `judge4/` beside a re-judging of the first readers' lines.
   - Write every check as a script whose output is an artifact BEFORE the rule-checker sees the report (`docs/project/gotchas.md` "A MEASUREMENT PUT TO THE RULE-CHECKER NEEDS EVERY CHECK'S OUTPUT SAVED" — paid again at 14z-200, twelve runs for one report).
   - Q1 of the checklist of record stays as it is until the maintainer rules on the replicated result.
2. **#275 — the negative fixture fidelity-14z160** (the maintainer: *"Look into it first (Recommended)"*, `DECISIONS_HISTORY.md` "Ruled 2026-10-13 (14z-199) — #273: replicate before deciding; …"). Its packet's gate carries the FREEZE gap the live gate has since fixed; whether its EXPECT OK stands is the maintainer's call, and #273's replication includes it.
3. **Then ask the maintainer for the order of work.** The open tickets, by their GitHub severity label:
   - high: #261 (`audit_effect_class_rows` section 4 checks a type-6 fallback inventory that was never frozen), #256 (the close's open-tickets check reads a cited ticket range as its two ends);
   - medium: #243, #257, #258, #259;
   - low: #118, #129, #229, #244;
   - no severity label: #260, #262, #263, #266, #267, #269, #273, #275, #276 (the session dashboard misses every tier run on a snapshot), #277 (the procedure check's extract: a figure written to fewer decimals reads unsourced; a part cut hides a step's evidence);
   - **release-only** (maintainer, 2026-10-14 — worked at a release, not in a session): #278 (a census of locale-sorted compares), #279 (xdelta3 3.0.11 release patches carry verbatim reference-ROM runs; PILOT is the Linux release builder), #280 (`test_applier_page` 3b on Python 3.12), #281 (`test_applier_page_browser`'s control under strace).
4. **#266 — PILOT's GNOME Shell segfaults under Wayland at every boot since 2026-10-09**, so `audit_release_linux_desktop` cannot run. At 14z-199 it was the one red/SKIP row of the release-cadence staleness audit (not re-read at 14z-200).
5. **`tests/replays/118_chain.rpl`'s header names a leg of `audit_mizuumi_inputs` that gate never ran** (STATE_HISTORY 14z-198 finding (i)). The one-line correction stales the 76 emulator gates that follow `tests/replays/`, so make it in a session that runs those gates.
6. **#118 — the chars gate, PARKED on branch `t118-196`.** **#129 stays the lowest priority**, captures first.

## PARKED (not open work)

- #124, parked by the maintainer (`DECISIONS_HISTORY.md` "Ruled 2026-10-09 (14z-196) — #124 parked"); #120 and #121 carry `parked` in the index and on GitHub.

## INSTRUMENT FACTS LEARNED THIS SITTING (read before the work they bear on)

- **A trace scores only the gates it could run** (`docs/project/gotchas.md` "A TRACE SCORES ONLY THE GATES IT COULD RUN"): before a predictor narrowing rests on a trace's 0, re-trace the gates that SKIPped or exited non-zero under it with their tools, and re-trace after gates are added.
- **A control mode that catches nothing must exit 0** (`docs/project/gotchas.md` "A CONTROL MODE THAT CATCHES NOTHING MUST EXIT 0"); check it with a dead copy through the runner.
- **A packet re-run in a later sitting cannot use `resolve --recheck`** (`docs/project/gotchas.md` "A DOCUMENTATION PACKET RE-RUN IN A LATER SITTING CANNOT USE").
- **PILOT's state after 14z-200:** its clone is detached at `24c548fe` with `emu/jtcores` on its pin; node, Chromium and xdelta3 from apt (the snap Chromium cannot run under strace); node 22 and Chrome for Testing in `~/opt` (the trace script sets `PATH` and `CHROME_BIN`, `build/agent200/trace3/trace9.sh`); the community workbook copied to `~/community`; `ROMDIR` is `/home/koneko/roms` and `.profile` does not set it. Copied scratch (`build/rulecheck`, `build/agent199`) sits in its clone beside PILOT's own `build/static_runs` and `build/snapshot_runs`.

## WHAT CLOSED THIS SITTING (14z-200)

- **The 14z-199 documentation packet** passed over the final state (rule-checker run 2026-10-14-1042).
- **#274 built and closed `done`:** the narrowed predictor, its N-C fix found by the #269 re-trace, and three gate fixes on the way.
- **#269 built** on the maintainer's *"C first"*, with the three-gate core; open until its done-when is put to the maintainer.
- **Filed, release-only:** #278, #279, #280, #281.
- **Ruled:** each in the maintainer's own words in `DECISIONS_HISTORY.md` "Ruled 2026-10-14 (14z-200) — …".
