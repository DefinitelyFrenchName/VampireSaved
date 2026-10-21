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
1. **#291 — S4: every tile a human can confirm, ~9 per move** (the maintainer on the unfiltered S3 page,
   `DECISIONS_HISTORY.md` "Read 2026-10-20 (14z-205c) — #291's unfiltered page"; STATE 14z-205c (6)). The S3 run at
   `b91532d8` drew 58 gates on PILOT (page `build/sheets/b91532d88bf3/`, local). To do: tiles drawn where the fighters
   are on screen (136 of 3,753 pictures are a flash or a blank, a floor; stage-only frames too), ~9 per move with
   several pages when one gets too big, and the six non-passing gates on a clean checkout (four need builds or a basis
   the commit does not make, `audit_dmg_legacy_sweep`'s MAME-opened-zip check read 0 of 32, `audit_grenade_ground_tiles`'
   PASS line). Plan it and show the plan first; then the closure through the rule-checker.
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
4. **#284 — the README drafts, edited by the maintainer** (`build/agent205c/t284/README.{mame,fbneo,mister}.md`,
   `README.template.md`, local; *"mostly removing the deliverables section"*, 2026-10-21). Read their edits first, then
   propose how the template enters the release pipeline; nothing goes beyond draft without the maintainer's validation.
   Answered: `apply_release.html` needs no Python (it is self-contained; `apply_release.py` is the fallback).
5. **#299 — two of its four items are done** (STATE 14z-205c (11), (12)): the MRA lock and the dead-control scoring
   (the own-`CONTROL DEAD`-beside-an-exception rule; a foreign failure without both signs still reads HONOURED) land
   with the 14z-205c close. Open: five gates that read `build/out/*.bin` directly fail under the pool with a cold cache
   (build the views first, or route the 27 direct readers through `decrypt_view`); serial cold not measured. Then the
   closure through the rule-checker.
6. **#298 — measure the narrowed controls** on a close's tier against 1,500-1,800 s of controls per close before
   (14z-205 commented 143 controls, 1,448 s); comment the figures on #298 and close it if the narrowing held.
7. **#296 — step 1's inventory is done** (ERIS, STATE 14z-205c (10)): 24 of 4,437 runs reused, all
   `audit_wide_phase_a` (a sandbox named by replay alone). Next: apply the proposed key fix and step 2's refusal
   (`build/agent205c/t296/proposals/`, with a refusal section and a must-fire control in
   `tests/test_mame_sandbox_log.sh`), then run the mame and fbneo lanes green with refusal on (#296's "done when"; ERIS
   carried them in ~2 h at `--jobs 8`). Seen there: `audit_marionette_cost`'s drift is #302.
8. **#286 — the narrowings did NOT land** (STATE 14z-205c (2); rule-checker run `2026-10-20-1156` withdrew them). On a
   re-trace at `b91532d8` both predictors scored 0 misses, but the scorer (`tools/trace_static_reads.py` `_score_one`)
   never applies `predict()`'s N-F-CHANGE skip; measured with `build/agent205c/t286/nf_change_check.py`, the narrowed
   N-F carries one real read: `test_tickets` opens a run record and is no runs reader once the planner's own text is
   dropped. To do, in order: make the scorer judge reads as `predict()` does (N-F-CHANGE included) with a control that
   fires on a carried run-record read; find what makes `test_tickets` read run records and let N-F see it; rescore on
   the PILOT traces (`~/t205/x2/tr`, kept); then a rule-checker packet that names the copied `build/`, shows the scored
   patch equals the landed diff, carries `test_trace_static_reads`' log and quotes #298's ruling from
   `DECISIONS_HISTORY.md`.
9. **#297 stays open until a freeze has run the 109 moved gates green**; a freeze runs every gate anyway.
10. **Then ask the maintainer for the order of work.** The open tickets by their GitHub severity label:
   - high: #286;
   - medium: #296, #284;
   - low: #118, #229, #244, #301 (and #129, parked);
   - no severity label: #266, #267, #289, #291, #297, #298, #299, #302, #303, #304;
   - **release-only:** #278, #279, #280, #281.
11. **`tests/replays/118_chain.rpl`'s header names a leg of `audit_mizuumi_inputs` that gate never ran** (STATE_HISTORY
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
