# NEXT SESSION — orientation (rewritten at the 14z-205c CLOSE, 2026-10-21)

> Rewritten at every session close ([VSP-17]). ROLLOVER: the previous opener
> moves VERBATIM to the top of `NEXT_SESSION_HISTORY.md` (then `python3 tools/gen_history_index.py`
> regenerates its index, #282) — this file holds ONLY
> the live orientation, within 500 lines and 50,000 bytes (`tests/test_live_budget.sh`, #282). Session state, not knowledge: facts belong in the docs,
> status in STATE.md.

## THE SETUP, RESTATED

A plain **Opus 5.5 session at effort High** (the ruled orchestrator — STATE 'Standing rulings') on the
#172 setup:
- Every quoted figure comes from a `measurer` / `reader` spec (`docs/project/worker_spec.md`, the spec text IN the prompt, no model). The Bash tool's shell is zsh: write a revision and a path as `"${c}:path"`, never `$c:path`. An adapting worker that is not `measurer`/`reader` is called `general-purpose` with `model: opus` (the call gate refuses it without a model).
- **The rule-checker runs ONLY BEFORE AN ACTION** (a freeze, a build, an expectation, a recommendation, a ticket closure; `docs/project/rule_checker.md`), **as soon as that action's work is done, never held for the close** (ruled 2026-10-16). The pinned `rule-checker`, the prompt files pasted VERBATIM, then `record --session <the CURRENT transcript's prefix>` and `resolve` on ONE line answering every violated question by its label.
- **THE GREEN GUARD (#290):** a commit needs a strict GREEN whole-tier row for the staged tree; tier the STAGED tree on a snapshot (`tests/run_on_snapshot.sh --commit "$(git commit-tree "$(git write-tree)" -p HEAD -m …)"`), then commit. Base a `--confirm` on a recent run of record: confirming against an old base cost 14z-205's first tier a 2 h 21 min plan.
- **WHEN TO COMMIT (ruled 2026-10-17):** only at a ticket closure, a freeze or release, work handed to PILOT or ERIS, or the close. Before EVERY tier, regenerate the generated files and run the bookkeeping gates the change touches (`docs/project/working_methods.md` "When to commit"); 14z-205's own pre-tier pass caught two stale indexes.
- **Never edit a script while it runs** ([MJC-54]); the emulator runner reports a tracked file changed during its run.

Say so at the opener. Never spawn any agent at `max`. A recommendation leans only on the maintainer's OWN words.
PILOT (6 vCPU, 47 GB, display VirtIO-GPU since 2026-10-20) and ERIS both carried work in 14z-205c; neither profile sets
ROMDIR (`ROMDIR=~/roms`). Work handed to either is a bundle of a COMMIT ("When to commit"), e.g. `main ^<last pushed>`
(bare SHAs fail); 14z-205b broke this twice with an rsync of the working tree (STATE_HISTORY 14z-205b (5)).

**THE SESSION CLOSE:** `docs/project/session_close.md`, run by `python3 tools/close.py` (`start --key … --row - --prev
<results>`, then `next`, `done`, `status`). The run of record is named in STATE 14z-205c's CLOSE section.

**THE STATIC TIER CHANGED THIS SITTING (14z-205; the page https://claude.ai/artifact/1DzrvoGUphYYmtyRKvhJtZ, private):**
109 gates of six families run at freeze cadence, pulled into a session only when their own code changes (`@code`,
#297); at a commit or close a gate's controls execute only when a program of its reach changed (#298); `--jobs N` runs
gates in parallel (#299; a close runs `--jobs 8`, ruled 2026-10-19).

## START HERE

0. **AT THE OPENER, RUN `python3 tools/agent/sweep.py`.**
1. **#291 — S4: S4-A..F landed (`a8fa5350`, `8b82d5d2`), S4-G ran and was reviewed** (STATE 14z-206 (1); the plan
   and answers: `build/agent206/t291/PLAN.md`, `DECISIONS_HISTORY.md` "Ruled 2026-10-21 (14z-206) — #291 S4: …" and
   "Ruled 2026-10-22 (14z-206) — #291 S4-G reviewed …"). In the working tree: each gate's characters read from the
   game (c1/c2/lv) and one `Setup: ` line per gate in `docs/project/sheet_notes.md`. Next: run `test_proof_sheets`
   (section 6b, control `who-swapped`), build a gate-declared variant in the clean checkout
   (`# SHEET-VARIANT:`, ruled 2026-10-22 "Built in checkout, stated": `test_tenant_select_records`' `tenant_build_13`),
   re-run S4-G, show the maintainer; then the closure through the rule-checker.
2. **#229 — WAITING ON THE MAINTAINER, Q2 especially** (*"I still have answers to provide for Q2 especially"*,
   2026-10-21); everything is listed on #229 (comment of 2026-10-20) and in STATE_HISTORY 14z-205b (1)-(5).
   - **The work is LOCAL and UNTRACKED:** the six gates, their expectations, rigs and Lua (105 files,
     `build/agent205/t229/pending_gates_229.list`, backed up in `pending_gates_229.tar` beside it); the forks' reports,
     probes and sheets under `build/agent205/t229/`. Never `git clean`.
   - **The maintainer's docs (private):** questions https://claude.ai/artifact/88mHYGNsf1wyYZ2EFfzPCE, community
     cross-check https://claude.ai/artifact/Wfn7XUHignvbQphap3MwyK (#301). Read the questions doc for new answers first.
   - **Answered** (`DECISIONS_HISTORY.md` "Read 2026-10-20 (14z-205b) — #229", the 14z-205c "Read … #229" entries): Q3,
     Q4's per-row inputs; Q1 for the pursuits, the five light grabs, Hell's Gate, Ira Piano, Bulleta's and Lei-Lei's
     guard cancels, Direct Scissors, ES Cool Hunting, ES Please Help Me, and Jedah's row (ES Ira Spinta); **the two
     re-rigged joins confirmed 2026-10-21** ("both are correct": F3's ES Ira Piano `J.63214KK~PP`, F1's row 38 Tsuji
     Hayate; STATE 14z-205c (9), (12)); row 38's startup reads 6 against the workbook's 7, not looked into.
   - **Waiting:** Q1 for the rest of the specials, ES/EX, the guard cancels and the command throws (the flagged rows:
     `build/agent205/t229/look_first_index.md`); Q2 (the four 14z-194 pursuit claims; mid-screen does not explain them);
     Q4's (a) join under the engine's input or (b) leave unjoined; Q5, Q6, Q7; and whether to comment on #301 that its
     vswiki "inputs no rig could make fire" are answered (offered 2026-10-20, no answer yet).
   - **Then, in order:** Hell's Gate's rig shows little with LK (Zabel on the left), a stronger kick
     or the other side if the maintainer wants it; a rule-checker run before each freeze; register the six gates (then restore them as #301's repro in `docs/project/tickets.tsv`, `none` while untracked);
     `docs/project/tables/community_crosscheck.md` (the three gotchas were written 14z-205c).
3. **#266 — done, awaiting release** (rule-checker run `2026-10-20-1154` withdrew the closure; its comment of
   2026-10-20): it closes when the next release's battery records `audit_release_linux_desktop` PASSING on PILOT. Ask
   the maintainer to be logged in to PILOT's desktop before that battery runs: the login screen still starts on X11,
   and with no user session the gate SKIPs and exits 0.
4. **#284 — done, awaiting release** (14z-206, STATE 14z-206 (2)): the template is in the pipeline
   (`tools/package_release_readme.template.md`); it closes when the next release ships the new READMEs and
   `test_readme_recording` runs its Windows and Linux legs.
5. **#298 — measure the narrowed controls** on a close's tier against 1,500-1,800 s of controls per close before
   (14z-205 commented 143 controls, 1,448 s); comment the figures on #298 and close it if the narrowing held.
6. **#286 — the scorer judges as `predict()` does; the narrowings plus N-F-LINK are applied** (14z-206, STATE 14z-206
   (5); PILOT's rescore 0 misses, rule-checker run `2026-10-22-1169` OK). What is left is the done-when itself: a
   record-only commit's `--confirm` tier measured, re-running only the gates that open a record file, controls only
   where real inputs changed, with the before/after figures on the ticket.
7. **#297 stays open until a freeze has run the 109 moved gates green**; a freeze runs every gate anyway.
8. **Then ask the maintainer for the order of work.** The open tickets by their GitHub severity label:
   - high: #286;
   - medium: #284;
   - low: #118, #229, #244, #301, #308, #309, #310, #311 (and #129, parked);
   - no severity label: #266, #267, #289, #291, #297, #298, #302, #303, #304, #305, #306, #307, #312;
   - **release-only:** #278, #279, #280, #281.
9. **`tests/replays/118_chain.rpl`'s header names a leg of `audit_mizuumi_inputs` that gate never ran** (STATE_HISTORY
    14z-198 finding (i)); the one-line correction rides a session that runs the emulator gates following `tests/replays/`.

## PARKED (not open work)

- #124 and #294 (Killshread's aura palette, filed parked by the maintainer 2026-10-18), and #121.
- **VampireSaved-Rebuilt#1** holds what is left of #120, closed 14z-205: the maintainer's review of `SPEC.md` v0.2, `CLAUDE.md` v0.1 and the carry ledgers' ten flags; phase 0 (the rule-5 extraction, in THIS repository, a ticket here when it starts).

## INSTRUMENT FACTS LEARNED THIS SITTING (read before the work they bear on)

- **Every capture sheet: ~9 tiles per move** (several pages when one gets too big), every tile showing the fighters (no
  flash, no blank), every tag defined on the sheet (the maintainer on #291's S3 page and on the #229 sheets, 2026-10-20).
- **Before tightening a verdict rule, census it over every log it will judge:** a gate's own `CONTROL DEAD` is the
  honoured mode of four gates (`docs/project/gotchas.md` "A GATE'S OWN `CONTROL DEAD` IS SOME GATES' HONOURED MODE").
- **The planner names one reason per stale gate**, so a false re-run can be over-determined; read every layer before
  narrowing one (#292, `docs/project/gotchas.md`).
- **`tools/trace_static_reads.py`'s scorer does not judge reads as `predict()` does** (no N-F-CHANGE skip): a 0-miss
  score of a narrowed predictor is not proof (#286, START HERE 8).
- **Remote handoff:** a bundle needs a ref range (`main ^<sha>`), not bare SHAs; an ssh that launches a `setsid` job can
  time out (exit 124) while the job runs — poll the job, not the ssh.

## WHAT CLOSED THIS SITTING (14z-205c)

- **Closed:** #292 `declined` (its narrowing saves no gate); #277, #262, #263 `done` (the agent extractor's rounding,
  dedupe and W§ fixes, `tools/agent/extract.py`).
- **Filed:** #302, #303, #304. **Ruled:** #299's lock; #292 closed, code out; #277/#263's fixes and the rounding rule; #229's
  Q1 answers and the two sheets; #284 stays open (`DECISIONS_HISTORY.md`, 2026-10-20 and 2026-10-21 entries).
- **Done, awaiting release:** #266 (closes when the next release records `audit_release_linux_desktop` PASSING on PILOT).
- **Withdrawn by the rule-checker:** #266's closure (run 1154), #286's narrowings (run 1156).
