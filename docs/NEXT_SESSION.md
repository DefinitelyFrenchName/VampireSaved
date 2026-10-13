# NEXT SESSION — orientation (rewritten at the 14z-199 CLOSE, 2026-10-13)

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

## START HERE

0. **AT THE OPENER, RUN `python3 tools/agent/sweep.py`.** What the close found and did is in STATE 14z-199's CLOSE row.
1. **#273 — THE REPLICATION THE MAINTAINER CHOSE** (`DECISIONS_HISTORY.md` "Ruled 2026-10-13 (14z-199) — #273: replicate before deciding; …").
   - Pre-registered in `build/agent199/t273/plan_replication.md`: two more readers per arm on the 15 that mattered and the 4 fixtures (76 pinned spawns, the same staged copies and prompts in `build/agent199/t273/stage/`), judged blind like `judge4/` beside a re-judging of the first readers, with the reading rule fixed there.
   - Write every check as a script whose output is an artifact BEFORE the rule-checker sees the report (`docs/project/gotchas.md` "A MEASUREMENT PUT TO THE RULE-CHECKER NEEDS EVERY CHECK'S OUTPUT SAVED"). The first report took thirteen spawned rule-checker runs.
   - Q1 of the checklist of record stays as it is until the maintainer rules on the replicated result.
2. **#275 — the negative fixture fidelity-14z160** (the maintainer: look into it first). Its packet's gate carries the FREEZE gap the live gate has since fixed; whether its EXPECT OK stands is the maintainer's call, and #273's replication includes it.
3. **#269 waits on #274** (narrow `tools/static_confirm.py`'s R3 and its change set, scored on a fresh trace). Until then a session close runs the static tier as before: every gate, every control executed.
4. **Then ask the maintainer for the order of work.** The open tickets, by their GitHub severity label:
   - high: #261 (`audit_effect_class_rows` section 4 checks a type-6 fallback inventory that was never frozen), #256 (the close's open-tickets check reads a cited ticket range as its two ends);
   - medium: #243, #257, #258, #259;
   - low: #118, #129, #229, #244;
   - no severity label: #260, #262, #263, #266, #267, #269, #270, #273, #274, #275, #276 (the session dashboard misses every tier run on a snapshot).
5. **#266 — PILOT's GNOME Shell segfaults under Wayland at every boot since 2026-10-09**, so `audit_release_linux_desktop` cannot run. It is now the one red/SKIP row of the release-cadence staleness audit (`audit_mask_window_ff42a2` moved to `ondemand` this sitting).
6. **`tests/replays/118_chain.rpl`'s header names a leg of `audit_mizuumi_inputs` that gate never ran** (STATE 14z-198 finding (i)). The one-line correction stales the 76 emulator gates that follow `tests/replays/`, so make it in a session that runs those gates anyway.
7. **#118 — the chars gate, PARKED on branch `t118-196`.** **#129 stays the lowest priority**, captures first.

## PARKED (not open work)

- #124, parked by the maintainer (`DECISIONS_HISTORY.md` "Ruled 2026-10-09 (14z-196) — #124 parked").

## INSTRUMENT FACTS LEARNED THIS SITTING (read before the work they bear on)

- **Two readers of one rubric are one classification** (`docs/project/gotchas.md` "A CLASSIFICATION BY TWO READERS OF ONE RUBRIC").
- **A blind judging is only as right as the script that builds its items.** Assert each item's row, class and cells. Check a judge's alarming report against its own transcript before acting on it (`docs/project/gotchas.md` "A BLIND JUDGING IS ONLY AS RIGHT").
- **An approval kept in prose is asked again, and no tool can read it.** Put such a decision in a column or scope the tools read (`docs/project/gotchas.md` "AN APPROVAL KEPT IN PROSE IS ASKED AGAIN"). The runner now selects an `instrument:` row in no scope.
- **`tools/rulecheck.py resolve --recheck`** (#270): a documentation-packet finding that is only a figure, a quote or a wording on a checked item is re-checked by a FULL close-checks run, not by a new packet run (`docs/project/rule_checker.md` [VSP-184]).

## WHAT CLOSED THIS SITTING (14z-199)

- **Built and closed:** #268 (`test_close_tools` cut back), #271 (readers, the recurrence alarm, `resolve`), #272 (the pre-prepare check, flags only), #265 (`audit_mask_window_ff42a2` to `ondemand`, `instrument:`).
- **Built:** #270 (`resolve --recheck`); its "done when" is this close's own packet loop, measured after the packet and recorded, with #270's closure or not, in STATE 14z-199's CLOSE row.
- **Measured and ruled:** #269 (narrow the predictor first; #274 filed); #273 (replicate first; #275 filed).
- **Ruled:** each in the maintainer's own words in `DECISIONS_HISTORY.md` "Ruled 2026-10-12 (14z-199) — …" and "Ruled 2026-10-13 (14z-199) — …".
