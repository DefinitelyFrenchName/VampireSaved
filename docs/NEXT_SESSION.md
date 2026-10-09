# NEXT SESSION — orientation (rewritten at the 14z-196 CLOSE, 2026-10-09)

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

Say so at the opener. Never spawn any agent at `max`. A recommendation leans only on the maintainer's OWN words.
**Before any long job, check whether PILOT (`ssh pilot`) or ERIS (`ssh eris`) is idle, and run independent work
there in parallel.**

## START HERE

0. **AT THE OPENER, RUN `python3 tools/agent/sweep.py`.** What the close found and did is in STATE 14z-196's CLOSE row.
1. **#245-#255 — the code-review findings, P2 first, then P3** (ruled: `DECISIONS_HISTORY.md` "Ruled 2026-10-09 (14z-196) — #245-#255: the triage's revised severities; worked next session, P1 to P3"). All eleven were re-checked VALID at `2979890c` (the triage report was untracked scratch, `build/agent196/triage245/REPORT.md`). Bug archaeology first ([VSP-14]); each fix gets its ground-truth test.
   - P2: #245 (the WIDE builder writes a source zip through its own symlink), #249, #251, #252, #253.
   - P3: #246, #247, #248, #250, #255.
2. **#228 — ASSESS FIRST, THEN STEP 4** (ruled: `DECISIONS_HISTORY.md` "Ruled 2026-10-09 (14z-196) — #228: step 4 does not start this session; whether it runs once or recurs is assessed first"). Steps 1-3 landed 14z-196: `tests/lua/pc_count.lua` counts the first frame, `tests/lua/clock_check.lua` measures drift per run, 24 at-risk gates drift and still PASS (`build/agent196/t228/step3/SUMMARY.txt`, untracked). Put the once-or-recurring question to the maintainer with its clock cost; a recurring run may be release-only or a scheduled night run.
   - **Carried to step 4 by decision:** seven code comments in six files still state the retracted "timeslicing" theory — `tests/lua/replay_guard.lua`, `tests/lua/inp_guard.lua`, `tools/run_replay_guarded.sh`, `tools/run_inp_guarded.sh`, `tools/run_inp_probe.sh`, `tests/test_crash_guard.sh` (`tests/rulecheck/retractions/14z-196.tsv` names them). Correct them with the clock fix.
3. **#118 — the chars gate, PARKED on branch `t118-196`** (ruled: `DECISIONS_HISTORY.md` "Ruled 2026-10-09 (14z-196) — #118's gates and every pristine-only gate move to an ONDEMAND scope; the chars gate parked"). `audit_mizuumi_chars` went through rule-checker runs 902-914 in the worktree `../wt_t118_196`; **914 is VIOLATED on Q1 and unresolved** (two facts frozen only in pooled lines). The struct gate merged 14z-196 (`8904dde2`, run 772 OK). The chars gate lands as `ondemand` (27 rows are `ondemand` since 14z-196: `tests/run_all_emulator.sh --scope ondemand`, HANDOFF [VSP-164]).
4. **bbh — settle who does what** (ruled: `DECISIONS_HISTORY.md` "Ruled 2026-10-09 (14z-196) — bbh is its own project: this session's three bbh commits dropped; test_bbh_fidelity ondemand until who-does-what is settled"). bbh (`~/Developer/blackbox-harness`) is its own project: make no change there from a Vampire Saved session. `tests/test_bbh_fidelity.sh` is static cadence `ondemand` until this is settled, and red if run: this tree has the #254 classifier rule and the cleanhost token, bbh no longer does.
5. **#260** — a check that every submodule pin exists on its remote before a push (filed 14z-196, the 14z-192 jtcores pin).
6. **Lowest priority:** #129, captures first (`DECISIONS_HISTORY.md` "Ruled 2026-10-08 (14z-196) — #129: captures first; the ticket stays the lowest priority of the open tickets").
7. **Open, scoped:** #229 (specials, supers and EX/ES moves next); #243, #244; the close's own tools #256, #257, #258, #259. Done, awaiting release: #236, #238, #239, #240.

## PARKED (not open work)

- #124, parked by the maintainer (`DECISIONS_HISTORY.md` "Ruled 2026-10-09 (14z-196) — #124 parked").

## INSTRUMENT FACTS LEARNED THIS SITTING (read before the work they bear on)

- **A `-debug` run's divergence was the debugger's boot-halt UI frame, not timeslicing.** A script counting `frame_done` calls runs one frame ahead; count emulated frames (`screen:frame_number()`). `tests/lua/clock_check.lua` (`CLOCK_OUT=<file>`) reports `uiframes` per run ([MFI-2], `docs/platform/gotchas.md`).
- **A merge packet compares the WORKING TREE the gate ran on, over the gate's WHOLE `# FOLLOWS:` header** (it wraps over several comment lines), never `git diff --cached` nor its first line (rule-checker runs 769 and 771).
- **"Failing as a mode" is shown by the mode's own FAIL lines and no `CONTROL DEAD:` line**, never by its exit status: a mode exits 1 whether its control fired or was dead (run 769).
- **`rulecheck prepare` picks the next free id after the ledger's highest**, which a fork's 901+ ids push up; pass `--id` to keep main's sequence (this sitting: 771, 772).
- **`tests/rulecheck/retractions/<session>.tsv` scans `docs/site/` too:** regenerate it (`python3 tools/mk_docs_site.py`) before the grep, or stale pages read as live carriers.

## WHAT CLOSED THIS SITTING (14z-196)

- **Closed `done`:** #254 (a control mode's own shell error is DIED at any exit; the close tier executed 350 controls, 0 died).
- **Filed:** #260.
- **Parked:** #124.
- **Ruled:** #129 lowest priority, captures first; the order of work (#228 first); #228 step 4 waits for its once-or-recurring assessment; #124 parked; #260 filed; #245-#255's revised severities; #254 closed at the close; the ONDEMAND scope for pristine-only gates, the chars gate parked; the pristine-only gates' scopes (a past break by a change of ours keeps a gate at release, a gate's own red does not; 23 rows to `ondemand`, audit_palette_seq_ids to release). Each in the maintainer's own words is its `DECISIONS_HISTORY.md` entry "Ruled 2026-10-08 (14z-196) — ..." (#129, the order of work) or "Ruled 2026-10-09 (14z-196) — ..." (the rest); `tools/agent/rulings_verbatim.py` checks those quotes.
