# NEXT SESSION — orientation (rewritten at the 14z-202 CLOSE, 2026-10-16)

> Rewritten at every session close ([VSP-17]). ROLLOVER: the previous opener
> moves VERBATIM to the top of `NEXT_SESSION_HISTORY.md` (then `python3 tools/gen_history_index.py`
> regenerates its index, #282) — this file holds ONLY
> the live orientation, within 500 lines and 50,000 bytes (`tests/test_live_budget.sh`, #282). Session state, not knowledge: facts belong in the docs,
> status in STATE.md.

## THE SETUP, RESTATED

A plain **Opus 5.5 session at effort High** (the ruled orchestrator — STATE 'Standing rulings') on the
#172 setup:
- Every quoted figure comes from a `measurer` / `reader` spec (`docs/project/worker_spec.md`, the spec text IN the prompt, no model). The Bash tool's shell is zsh: write a revision and a path as `"${c}:path"`, never `$c:path` (`docs/project/gotchas.md`, 14z-201).
- **The rule-checker runs ONLY BEFORE AN ACTION since #288 (2026-10-15):** a freeze, a build, an expectation, a recommendation, a ticket closure (`docs/project/rule_checker.md`). The pinned `rule-checker`, the prompt files pasted VERBATIM, then `record` and `resolve` on ONE line. Read `prepare`'s flags before spawning; pass `--deliverable` for what a packet puts forward. **A diagnosis put to the maintainer with proposals in it is a recommendation** (14z-202 finding (e)).
- There is no documentation packet, no procedure check and no `--cap` read at the close any more, and no push hook: the maintainer installed the settings change that unwired `pre_push.py` (2026-10-16).

Say so at the opener. Never spawn any agent at `max`. A recommendation leans only on the maintainer's OWN words.
**Before any long job, check whether PILOT (`ssh pilot`) or ERIS (`ssh eris`) is idle, and run independent work
there in parallel.** A long tier runs on a snapshot (`tests/run_on_snapshot.sh`), so the tree can be edited meanwhile.

**THE SESSION CLOSE IS TEN STEPS (cut by #288):** `docs/project/session_close.md`, run by `python3 tools/close.py`
(`start`, then `next`, `done`, `status`). The records are committed BEFORE the one tier (`--strict --confirm` on the
previous close's results), so there is no second pass. The run of record is named in STATE 14z-202's CLOSE section.
**Since #286, a `--confirm` re-run gate executes its controls only when its own code reads a changed file directly**,
and an unchanged dirty `emu/fbneo` no longer counts as changed.

## START HERE

0. **AT THE OPENER, RUN `python3 tools/agent/sweep.py`.**
1. **THE MAINTAINER'S DIRECT PRIORITY: the close's cost (#286, #289, #290).**
   - **#290 — the deterministic green guard** (no commit or push on a tier that did not read GREEN; it replaces the procedure check's one recurring real catch). **Its design goes to the maintainer BEFORE it is built**, through a recommendation rule-checker run. The guard is a hook or a gate: hooks are edit-locked, so a hook change is drafted under `build/` for the maintainer to install.
   - **#286 — stays open on its done-when:** a record-only pass measured, re-running only gates that open a record file, no control executed. The close no longer has a record-only pass, so the cheapest measurement is a mid-session `--confirm` after a doc-only commit; put the restated done-when to the maintainer if that is not what they want. The 14z-202 close's tier figures are on #286.
   - **#289 — revisit the cut** of the audit layer when there is more data; nothing to do until then except keep the before-an-action runs' resolutions classifiable (W/S/R/N, `build/agent202/t288/summary.md`, local).
2. **Then ask the maintainer for the order of work.** The open tickets, by their GitHub severity label:
   - high: #261 (`audit_effect_class_rows` section 4 checks a type-6 fallback inventory that was never frozen), #256 (the close's open-tickets check reads a cited ticket range as its two ends; that check is no longer a close step since #288, so ask whether it still matters);
   - medium: #284 (the release package README: its clean-up, and the recording procedure moved into it; `test_readme_recording` fails until it is done), #243, #257, #258, #259;
   - low: #118, #129, #229, #244;
   - no severity label: #260, #262, #263, #266, #267, #273 and #275 (rule-checker Q1 replication; the maintainer chose to replicate before deciding, `DECISIONS_HISTORY.md` "Ruled 2026-10-13 (14z-199) — #273: replicate before deciding; …"; plan in `build/agent199/t273/plan_replication.md`), #276 (the session dashboard misses every tier run on a snapshot), #277 (the procedure check's extract; the procedure check is cut, so ask whether it still matters);
   - **release-only** (worked at a release, not in a session): #278, #279, #280, #281.
3. **#266 — PILOT's GNOME Shell segfaults under Wayland at every boot since 2026-10-09**, so `audit_release_linux_desktop` cannot run.
4. **`tests/replays/118_chain.rpl`'s header names a leg of `audit_mizuumi_inputs` that gate never ran** (STATE_HISTORY 14z-198 finding (i)). The one-line correction stales the 76 emulator gates that follow `tests/replays/`, so make it in a session that runs those gates.
5. **#118 — the chars gate, PARKED on branch `t118-196`.** **#129 stays the lowest priority**, captures first.

## PARKED (not open work)

- #124, parked by the maintainer (`DECISIONS_HISTORY.md` "Ruled 2026-10-09 (14z-196) — #124 parked"); #120 and #121 carry `parked` in the index and on GitHub.

## INSTRUMENT FACTS LEARNED THIS SITTING (read before the work they bear on)

- **A staleness predictor is scored both ways** (`docs/project/gotchas.md` "A STALENESS PREDICTOR SCORED ONLY ON ITS MISSES…"): its misses on a trace, and its over-runs on a real change set.
- **A data file a gate reads with `cat` is not in its reach** (`docs/project/gotchas.md` "A DATA FILE A GATE READS WITH `cat`…"): the control trigger is `direct_read`, never R1 alone.
- **PILOT's state after 14z-202:** its clone is detached at `1c59a7cd`; scratch in `~/t202` (the traces of all 225 gates in `~/t202/tr`). `ROMDIR` is `/home/koneko/roms` and `.profile` does not set it.

## WHAT CLOSED THIS SITTING (14z-202)

- **#286 (a), (b), (c) built** (`1c59a7cd`, `f1b732e5`); the ticket stays open on its done-when (START HERE 1).
- **#283 closed `done`**, **#287 closed `declined`** (superseded by the #288 ruling), **#288 closed `done`**: the close cut to ten steps.
- **Filed:** #289, #290.
- **14z-201b's and 14z-202's commits pushed** at this close (STATE 14z-202 CLOSE).
- **Ruled:** each in the maintainer's own words in `DECISIONS_HISTORY.md` "Ruled 2026-10-15 (14z-202) — …".
