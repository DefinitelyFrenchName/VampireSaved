# NEXT SESSION — orientation (rewritten at the 14z-201b CLOSE, 2026-10-15)

> Rewritten at every session close ([VSP-17]). ROLLOVER: the previous opener
> moves VERBATIM to the top of `NEXT_SESSION_HISTORY.md` (then `python3 tools/gen_history_index.py`
> regenerates its index, #282) — this file holds ONLY
> the live orientation, within 500 lines and 50,000 bytes (`tests/test_live_budget.sh`, #282). Session state, not knowledge: facts belong in the docs,
> status in STATE.md.

## THE SETUP, RESTATED

A plain **Opus 5.5 session at effort High** (the ruled orchestrator — STATE 'Standing rulings') on the
#172 setup:
- Every quoted figure comes from a `measurer` / `reader` spec (`docs/project/worker_spec.md`, the spec text IN the prompt, no model). The Bash tool's shell is zsh: write a revision and a path as `"${c}:path"`, never `$c:path` (`docs/project/gotchas.md`, 14z-201).
- Every freeze and recommendation goes through the pinned `rule-checker`, with the prompt files pasted VERBATIM.
- Then `record --session <transcript id>`, and `resolve` on ONE line with one label per violated question, only AFTER the work it names exists.
- Since #272, `rulecheck prepare` FLAGS figures, quotes and absolutes. Read its flags before spawning, and pass `--deliverable` for the report a packet puts forward.

Say so at the opener. Never spawn any agent at `max`. A recommendation leans only on the maintainer's OWN words.
**Before any long job, check whether PILOT (`ssh pilot`) or ERIS (`ssh eris`) is idle, and run independent work
there in parallel.** A long tier runs on a snapshot (`tests/run_on_snapshot.sh`), so the tree can be edited meanwhile.

**THE SESSION CLOSE IS ONE TABLE (#282, closed 2026-10-15):** `docs/project/session_close.md` holds every step in
order and `python3 tools/close.py` runs it (`start`, then `next`, `done`, `status`). The tier step is
`--strict --confirm` on the previous close's results; the last run of record is `build/agent201b/close/tier2_results.tsv` (STATE 14z-201b's CLOSE section). **A session
close needs no ERIS since #285:** `test_release_launcher_bat`'s Windows half is a NOTE off Windows below release cadence. **CLAUDE.md is now rule plus pointer (244 lines):** the long paragraphs live in
`docs/project/oracle_classes.md`, `docs/project/working_methods.md`, `docs/project/session_records.md` and
`docs/README.md` — read the one a rule points to before acting on it.

## START HERE

0. **AT THE OPENER, RUN `python3 tools/agent/sweep.py`.**
0b. **14z-201b's commits are LOCAL, not pushed** (the maintainer: *"honestly, stop here leave the commits local and the next session will push"*). Its close stopped before its tier went green (STATE 14z-201b (3) CLOSE): this session's own close runs the tier over them and pushes them with its own work.
0c. **Put to the maintainer (proposed at 14z-201b, not yet answered):** a cheaper final tier — when the only commits since a green close tier are the close's own record files (STATE, NEXT_SESSION, the rule-checker records), run only the gates that read them, without their controls. The 14z-201 close's final tier re-ran those with every control (costliest `test_static_runner` 202 s, `test_state_open_lists` 166 s, `test_tickets` 152 s). It loosens a standing rule, so it is the maintainer's; file it as a ticket if asked.
1. **#273 — THE REPLICATION THE MAINTAINER CHOSE** (`DECISIONS_HISTORY.md` "Ruled 2026-10-13 (14z-199) — #273: replicate before deciding; …").
   - Pre-registered in `build/agent199/t273/plan_replication.md`: two more readers per arm on the 15 that mattered and the 4 fixtures (76 pinned spawns, the same staged copies and prompts in `build/agent199/t273/stage/`), judged blind like `judge4/` beside a re-judging of the first readers' lines.
   - Write every check as a script whose output is an artifact BEFORE the rule-checker sees the report (`docs/project/gotchas.md` "A MEASUREMENT PUT TO THE RULE-CHECKER NEEDS EVERY CHECK'S OUTPUT SAVED").
   - Q1 of the checklist of record stays as it is until the maintainer rules on the replicated result.
2. **#275 — the negative fixture fidelity-14z160** (the maintainer: *"Look into it first (Recommended)"*, `DECISIONS_HISTORY.md` "Ruled 2026-10-13 (14z-199) — #273: replicate before deciding; …"). Its packet's gate carries the FREEZE gap the live gate has since fixed; whether its EXPECT OK stands is the maintainer's call, and #273's replication includes it.
3. **Then ask the maintainer for the order of work.** The open tickets, by their GitHub severity label:
   - high: #261 (`audit_effect_class_rows` section 4 checks a type-6 fallback inventory that was never frozen), #256 (the close's open-tickets check reads a cited ticket range as its two ends);
   - medium: #284 (the release package README: its clean-up, and the recording procedure moved into it — the requirements measured on ERIS are on the issue; `test_readme_recording` fails until it is done, `DECISIONS_HISTORY.md` "Ruled 2026-10-15 (14z-201) — the recording procedure moves to the release package README"), #243, #257, #258, #259;
   - low: #118, #129, #229, #244;
   - no severity label: #260, #262, #263, #266, #267, #273, #275, #276 (the session dashboard misses every tier run on a snapshot), #277 (the procedure check's extract), #283 (`tools/trace_static_reads.py` drops strace's split open lines);
   - **release-only** (the maintainer: *"All 4 have value but they also should be release-only"*, its `DECISIONS_HISTORY.md` entry of 2026-10-14 (14z-200), "… four release-only tickets filed; the close is run" — worked at a release, not in a session): #278, #279, #280, #281.
4. **#266 — PILOT's GNOME Shell segfaults under Wayland at every boot since 2026-10-09**, so `audit_release_linux_desktop` cannot run.
5. **`tests/replays/118_chain.rpl`'s header names a leg of `audit_mizuumi_inputs` that gate never ran** (STATE_HISTORY 14z-198 finding (i)). The one-line correction stales the 76 emulator gates that follow `tests/replays/`, so make it in a session that runs those gates.
6. **#118 — the chars gate, PARKED on branch `t118-196`.** **#129 stays the lowest priority**, captures first.

## PARKED (not open work)

- #124, parked by the maintainer (`DECISIONS_HISTORY.md` "Ruled 2026-10-09 (14z-196) — #124 parked"); #120 and #121 carry `parked` in the index and on GitHub.

## INSTRUMENT FACTS LEARNED THIS SITTING (read before the work they bear on)

- **A condensed rule drifts** (`docs/project/gotchas.md` "A CONDENSED RULE DRIFTS"): a short form quotes the original's clauses, and a reader compares them before anyone approves it.
- **MAME `-playback` does not exit at the end of the recording** (`docs/platform/gotchas.md`): pass `-exit_after_playback`.
- **ERIS for a player's-eye run:** its SSH shell is `cmd.exe`; there is no Windows Python (MSYS2's is `C:\msys64\mingw64\bin\python3.exe`); the dumps are in WSL at `/home/koneko/roms`. The 14z-201 run of the m23 Windows MAME package sits in `C:\Users\chaton\readme201`, its scripts in `C:\Users\chaton\m22logs\readme201_*`.
- **PILOT's state after 14z-201:** its clone is detached at `344ebc5e`; scratch in `~/t201`. `ROMDIR` is `/home/koneko/roms` and `.profile` does not set it.

## WHAT CLOSED THIS SITTING (14z-201, and 14z-201b after its close)

- **#282 closed `done`:** every history file indexed (E), STATE at most two groups (A), HANDOFF a map (B), the live budget gate (F), the close as one table and a driver (C), CLAUDE.md rule plus pointer (D).
- **#269 closed `done`** on its measured done-when.
- **Filed:** #283. **#284** (the maintainer's) got its index row and the recording procedure.
- **The root README** edited by the maintainer on GitHub (merged, never rebased); "The scale" re-measured.
- **#285 closed `done` (14z-201b):** cross-platform checks on demand or at release.
- **Ruled:** each in the maintainer's own words in `DECISIONS_HISTORY.md` "Ruled 2026-10-14/15 (14z-201, 14z-201b) — …".
