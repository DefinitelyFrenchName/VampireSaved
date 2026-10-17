# NEXT SESSION — orientation (rewritten at the 14z-203 CLOSE, 2026-10-17)

> Rewritten at every session close ([VSP-17]). ROLLOVER: the previous opener
> moves VERBATIM to the top of `NEXT_SESSION_HISTORY.md` (then `python3 tools/gen_history_index.py`
> regenerates its index, #282) — this file holds ONLY
> the live orientation, within 500 lines and 50,000 bytes (`tests/test_live_budget.sh`, #282). Session state, not knowledge: facts belong in the docs,
> status in STATE.md.

## THE SETUP, RESTATED

A plain **Opus 5.5 session at effort High** (the ruled orchestrator — STATE 'Standing rulings') on the
#172 setup:
- Every quoted figure comes from a `measurer` / `reader` spec (`docs/project/worker_spec.md`, the spec text IN the prompt, no model). The Bash tool's shell is zsh: write a revision and a path as `"${c}:path"`, never `$c:path`.
- **The rule-checker runs ONLY BEFORE AN ACTION** (a freeze, a build, an expectation, a recommendation, a ticket closure; `docs/project/rule_checker.md`), **as soon as that action's work is done, never held for the close** (ruled 2026-10-16). The pinned `rule-checker`, the prompt files pasted VERBATIM, then `record --session <the CURRENT transcript's prefix>` (after a resume the transcript id changes: 14z-203 recorded run 1107 against the old one first) and `resolve` on ONE line.
- **THE GREEN GUARD (#290, live since 14z-203):** `tools/git-hooks/pre-commit` refuses a commit unless the staged tree has a strict GREEN whole-tier row (`.git/green_index.tsv`); tier the STAGED tree on a snapshot (`tests/run_on_snapshot.sh --commit "$(git commit-tree "$(git write-tree)" -p HEAD -m …)"`), then commit. Base a `--confirm` on the newest run that EXECUTED its controls.
- **WHEN TO COMMIT (ruled 2026-10-17, `docs/project/working_methods.md` "When to commit"):** only at a ticket closure, a freeze or release, work handed to PILOT or ERIS, or the close. Before EVERY tier, regenerate the generated files and run the bookkeeping gates the change touches; all four red tiers of 14z-203 were those gates.
- **Never edit a script while it runs** ([MJC-54]): 14z-203 did it twice; both runs were discarded.

Say so at the opener. Never spawn any agent at `max`. A recommendation leans only on the maintainer's OWN words.
**PILOT and ERIS are unavailable for a few days** (the maintainer, 2026-10-17); check `ssh pilot` / `ssh eris` before relying on them.

**THE SESSION CLOSE:** `docs/project/session_close.md`, run by `python3 tools/close.py` (`start`, then `next`, `done`,
`status`). The records are STAGED, the one tier runs on a snapshot of the staged tree, then the commit through the
guard. The run of record is named in STATE 14z-203's CLOSE section.

## START HERE

0. **AT THE OPENER, RUN `python3 tools/agent/sweep.py`.**
1. **#286 — three narrowings built, waiting for a trace score.** `build/agent203/t286/narrowings.patch` (local; `git apply` it, then score with `tools/trace_static_reads.py all` on PILOT, 0 misses required, #225). Measured on 14z-203's tree: mid2's record-only change set 58 → 50 STALE, a new run record 33 → 31, none added (#286 comment). The remaining over-runs are R2 mentions in tools' self-tests (the trace or a call graph tells them apart). The done-when is amended (controls only for gates whose real inputs changed).
2. **#291 — the comparative capture sheets: build S1** as ruled (`DECISIONS_HISTORY.md` "Ruled 2026-10-17 (14z-203) — #261 freeze as measured, …"; the design on #291): the `# SHEET:` grammar and its census gate, `tests/lib/sheet.sh`, the capture-and-prove step and its ground-truth gate, the page, and three exemplars (`audit_move_parity`, `test_gfx_menus`, `audit_merged_legacy`). The census of all 231 emulator gates: `build/agent203/t291/census_all.tsv` (local).
3. **#289 — revisit the cut** of the audit layer when there is more data.
4. **Then ask the maintainer for the order of work.** The open tickets, by their GitHub severity label:
   - medium: #284 (the release package README; `test_readme_recording` fails until it is done), #243, #257, #258, #259;
   - low: #118, #129, #229, #244;
   - no severity label: #260, #262, #263, #266, #267, #273, #275, #276, #277;
   - **release-only** (worked at a release, not in a session): #278, #279, #280, #281.
5. **`tests/replays/118_chain.rpl`'s header names a leg of `audit_mizuumi_inputs` that gate never ran** (STATE_HISTORY 14z-198 finding (i)); make the one-line correction in a session that runs the 76 emulator gates following `tests/replays/`.

## PARKED (not open work)

- #124, parked by the maintainer (`DECISIONS_HISTORY.md` "Ruled 2026-10-09 (14z-196) — #124 parked"); #120 and #121 carry `parked` in the index and on GitHub.

## INSTRUMENT FACTS LEARNED THIS SITTING (read before the work they bear on)

- **A static-runner readout can count what it did not do:** until 14z-203 the "executed:" line added carried controls, and the plan listed cadence-deferred gates as re-runs (both fixed, `tests/run_all_static.sh`; `tests/test_static_runner.sh` section 22).
- **`audit_effect_class_rows` section 4 needs an absolute `BUILD`** for its reference legs, which run from their own directories (`tests/lib/instr_align.sh` `_ia_leg`); the gate makes it absolute and keeps the given form for the frozen headers.
- **A frozen inventory under `build/manifest/` needs its keys classified in `tools/audit_rule5.py`** or `test_rule5_census` fails (14z-203's red tier7).

## WHAT CLOSED THIS SITTING (14z-203)

- **#290 built** (`a36dd6d3`). **#291 filed, its census and design ruled.**
- **#261 closed `done`** (the type-6 inventory frozen on merged-m23, `bd620817`) and **#256 closed `done`** (open-tickets reads ranges), at `937ac1b3` through rule-checker run 2026-10-17-1107.
- **Ruled:** an action is checked when its work is done; #290's four answers; #291's eight answers; #261, #256, #286; when to commit — each in the maintainer's own words in `DECISIONS_HISTORY.md` "Ruled 2026-10-16/17 (14z-203) — …".
