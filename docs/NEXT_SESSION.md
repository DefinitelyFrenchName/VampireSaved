# NEXT SESSION — orientation (rewritten at the 14z-204 CLOSE, 2026-10-18)

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
guard. The run of record is named in STATE 14z-204's CLOSE section. `close.py start` needs `--row -` (it still looks for
the findings section #288 cut).

## START HERE

0. **AT THE OPENER, RUN `python3 tools/agent/sweep.py`.**
1. **#286 — three narrowings built, waiting for a trace score.** `build/agent203/t286/narrowings_on259.patch` (local; refreshed 14z-204 onto #259's planner change, `test_static_confirm` PASS with its 30 controls; the original `narrowings.patch` no longer applies; `git apply` it, then score with `tools/trace_static_reads.py all` on PILOT, 0 misses required, #225). Measured on 14z-203's tree: mid2's record-only change set 58 → 50 STALE, a new run record 33 → 31, none added (#286 comment). The remaining over-runs are R2 mentions in tools' self-tests (the trace or a call graph tells them apart). The done-when is amended (controls only for gates whose real inputs changed).
1b. **#292 — the planner's self-test reads, with #286, when PILOT is back:** a tool's self-test strings count as a direct read (`tools/battery_reach.py` names STATE.md), so 22 gates re-run with controls on every STATE.md change. Measure which hits are real reads, narrow, score on a PILOT trace (#225), then decide whether `test_static_runner`'s freeze row in `tests/ci_cadence.tsv` (14z-204) stays.
2. **#291 — the comparative capture sheets: S1 landed 14z-204, S2 next.** S2 retrofits the remaining comparing gates family by family: each gets its `# SHEET:` line and `tests/lib/sheet.sh` emission, and leaves `tests/expected/sheet_debt.txt` (228 rows; the census of what each one compares: `build/agent203/t291/census_all.tsv`, local). The grammar and the tool: `docs/project/gate_header_contract.md` § `# SHEET:`; draw with `ROMDIR=... python3 tools/proof_sheets.py run --gate G`. S3 (build from the commit, `--host pilot|eris`) follows.
3. **#289 — revisit the cut** of the audit layer when there is more data.
4. **Then ask the maintainer for the order of work.** The open tickets, by their GitHub severity label:
   - high: #286, #292 (both wait on PILOT, items 1 and 1b);
   - medium: #284 (the release package README; `test_readme_recording` fails until it is done), #257;
   - low: #118, #229, #244 (and #129, parked);
   - no severity label: #260, #262, #263, #266, #267, #273, #275, #276, #277, #289, #291;
   - **release-only** (worked at a release, not in a session): #278, #279, #280, #281.
5. **`tests/replays/118_chain.rpl`'s header names a leg of `audit_mizuumi_inputs` that gate never ran** (STATE_HISTORY 14z-198 finding (i)); make the one-line correction in a session that runs the 76 emulator gates following `tests/replays/`.

## PARKED (not open work)

- #124, parked by the maintainer (`DECISIONS_HISTORY.md` "Ruled 2026-10-09 (14z-196) — #124 parked"); #120 and #121 carry `parked` in the index and on GitHub.

## INSTRUMENT FACTS LEARNED THIS SITTING (read before the work they bear on)

- **A sourced sh helper's variable overwrites the caller's of the same name** (sh has no locals): `tests/lib/sheet.sh` uses only `__sheet_` names, and `test_sheet_census` checks it (`docs/project/gotchas.md`, 14z-204).
- **A rotation drawn once sees one element:** the rule-checker's plant rotation is now drawn at every position (`tests/test_rule_checker.sh` PLANT ROTATION), and a reader's Read is estimated at bytes / 2.0 + 2 per line, refused above 25,000 tokens or 256 KB (#258).
- **`test_static_runner` runs at freeze cadence** (with triggers) since 14z-204; its 13 controls were about 650-700 s of every tier.
- **The capture instrument draws every anchor a leg reaches;** a set `ANCHOR_MAX` is written and shown on the sheet (a silent cap of 16 was caught by rule-checker run 2026-10-18-1118).

## WHAT CLOSED THIS SITTING (14z-204)

- **#290 closed `done`** (`a2c4df94`): the install landed, 24 bypass cases, five edit-lock rules, two controls.
- **#259 closed `done`** (`9443f294`): the `--confirm` plan is 3.4x faster, with progress lines and a timing line.
- **#258 closed `done`** (`9443f294`, follow-up `c810e017`): `prepare` hands a reader nothing it cannot read whole. A correction comment covers the estimate and the rotation.
- **#243 closed `done`** (`c810e017`): 24 declarations narrowed, plus the over-wide check.
- **#291 S1 landed** at this close's commit (STATE 14z-204 (7)). **#292 filed**, and `test_static_runner` moved to freeze cadence.
- **Ruled:** #243's three answers and the `test_static_runner` cadence, in the maintainer's own words (`DECISIONS_HISTORY.md` "Ruled 2026-10-17 (14z-204) — #243: …"; STATE 14z-204 (5)).
