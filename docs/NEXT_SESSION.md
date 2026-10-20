# NEXT SESSION — orientation (rewritten at the 14z-205b CLOSE, 2026-10-20)

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
PILOT was back on 2026-10-20 (6 vCPU, 47 GB; its profile sets no ROMDIR: `ROMDIR=~/roms`, 76 of 76 verified); ERIS was not
tried. Work handed to either is a bundle of a COMMIT ("When to commit"); 14z-205b broke this twice with an rsync of
the working tree (STATE 14z-205b (5)).

**THE SESSION CLOSE:** `docs/project/session_close.md`, run by `python3 tools/close.py` (`start --key … --row - --prev
<results>`, then `next`, `done`, `status`). The run of record is named in STATE 14z-205b's CLOSE section.

**THE STATIC TIER CHANGED THIS SITTING (14z-205; the page https://claude.ai/artifact/1DzrvoGUphYYmtyRKvhJtZ, private):**
109 gates of six families run at freeze cadence, pulled into a session only when their own code changes (`@code`,
#297); at a commit or close a gate's controls execute only when a program of its reach changed (#298); `--jobs N` runs
gates in parallel (#299; a close runs `--jobs 8`, ruled 2026-10-19).

## START HERE

0. **AT THE OPENER, RUN `python3 tools/agent/sweep.py`.**
1. **#291 — the unfiltered S3 run, then close #291.** S3 is built (STATE 14z-205b (6)): `python3 tools/proof_sheets.py
   run <the 14z-205b close commit> --host pilot` builds that commit clean on PILOT and draws every declaring gate
   (estimated 2-3 h; the filtered proof took 319 s). Three gates will show NOT THE JUDGED RUN by design (they default to
   builds a commit does not make). Put the page to the maintainer, then the closure through the rule-checker.
2. **#229 — WAITING ON THE MAINTAINER; everything is listed on #229 (comment of 2026-10-20) and in STATE 14z-205b (1)-(5).**
   - **The work is LOCAL and UNTRACKED:** the six gates, their expectations, rigs and Lua (105 files,
     `build/agent205/t229/pending_gates_229.list`, backed up in `pending_gates_229.tar` beside it); the forks' reports,
     probes and sheets under `build/agent205/t229/`. Never `git clean`.
   - **The maintainer's docs (private):** questions https://claude.ai/artifact/88mHYGNsf1wyYZ2EFfzPCE, community
     cross-check https://claude.ai/artifact/Wfn7XUHignvbQphap3MwyK (#301). Read the questions doc for new answers first.
   - **Answered** (`DECISIONS_HISTORY.md` "Read 2026-10-20 (14z-205b) — #229"): Q3, Q4's per-row inputs; Q1 for the
     pursuits, the five light grabs, Hell's Gate and Ira Piano.
   - **Waiting:** Q1 for the rest of the specials, ES/EX, the guard cancels and the command throws (the flagged rows:
     `build/agent205/t229/look_first_index.md`); Q2 (the four 14z-194 pursuit claims; mid-screen does not explain them);
     Q4's (a) join under the engine's input or (b) leave unjoined; Q5, Q6, Q7; and whether to comment on #301 that its
     vswiki "inputs no rig could make fire" are answered (offered 2026-10-20, no answer yet).
   - **Then, in order:** fix the two wrong joins (F3's "ES Ira Pino" is ES Ira Spinta; F1's workbook row 38 is a 6+P,
     Tsuji Hayate needs Karame Dama first); Hell's Gate's rig shows little with LK (Zabel on the left), a stronger kick
     or the other side if the maintainer wants it; a rule-checker run before each freeze; register the six gates (then restore them as #301's repro in `docs/project/tickets.tsv`, `none` while untracked);
     `docs/project/tables/community_crosscheck.md`; the gotchas (the `-debug` pass skew, the MAME tap crash at exit,
     the `nm.hcf` backdash trap).
3. **#299 — the four items its comment of 2026-10-20 names** (the closure's rule-checker withdrew it, STATE 14z-205b
   (7)): per-gate output compared serial against `--jobs 8`, a cold decrypt cache under the pool, a collision control
   or census, wall-clock gates under load. The close's `--jobs 8` default stands.
4. **#260** — the close's `pins` step was to close it after a close's push passes it (rule-checker first); STATE
   14z-205b's CLOSE section says whether that happened.
5. **#298 — measure the narrowed controls** on a close's tier against 1,500-1,800 s of controls per close before
   (14z-205 commented 143 controls, 1,448 s); comment the figures on #298 and close it if the narrowing held.
6. **#296 — the sandbox inventory over the other emulator lanes** (step 1 is built: `MAME_SANDBOX_LOG`). Run the mame
   and fbneo lanes with the log on, on PILOT, attribute every `reused` line, then step 2: refusal by default with
   `MAME_SANDBOX_REUSE=1` for a declared reuse.
7. **#286 and #292, now that PILOT is back:** the parked narrowings (`build/agent203/t286/narrowings_on259.patch`,
   local) and the planner's self-test reads, each scored on a PILOT trace (0 misses, #225).
8. **#297 stays open until a freeze has run the 109 moved gates green**; a freeze runs every gate anyway.
9. **Then ask the maintainer for the order of work.** The open tickets by their GitHub severity label:
   - high: #286, #292;
   - medium: #296, #284;
   - low: #118, #229, #244, #301 (and #129, parked);
   - no severity label: #260, #262, #263, #266, #267, #277, #289, #291, #297, #298, #299;
   - **release-only:** #278, #279, #280, #281.
10. **`tests/replays/118_chain.rpl`'s header names a leg of `audit_mizuumi_inputs` that gate never ran** (STATE_HISTORY
    14z-198 finding (i)); the one-line correction rides a session that runs the emulator gates following `tests/replays/`.

## PARKED (not open work)

- #124 and #294 (Killshread's aura palette, filed parked by the maintainer 2026-10-18), and #121.
- **VampireSaved-Rebuilt#1** holds what is left of #120, closed 14z-205: the maintainer's review of `SPEC.md` v0.2, `CLAUDE.md` v0.1 and the carry ledgers' ten flags; phase 0 (the rule-5 extraction, in THIS repository, a ticket here when it starts).

## INSTRUMENT FACTS LEARNED THIS SITTING (read before the work they bear on)

- **A capture sheet for the maintainer's eye has at least 5 tiles per move, 9 preferred** (*"5 per move is the strict
  minimum and 9 is likely preferable"*, 2026-10-20), and a row to look at first carries a FILLED band and a thick frame
  plus an index of sheet and row (tinted text went unseen).
- **Light-strength command grabs exist on five moves** (SA Big Swing and Big Brunch, LI Mystic Arrow, JE Nero Fatica,
  QB Catch and Release); the other command throws mask light out. Confirmed by eye 2026-10-20.
- **The engine's motion trackers accept a prefix:** 4-1-2-3 + button also completes on 41236 (Karame Dama, Catch and
  Release, Hell's Gate).
- **`nm.hcf`'s gapped back taps are a backdash** on a character whose double back-tap dashes (Bishamon): the press then
  lands in the hop.
- **The forced-pick census reads a script's comments** (`docs/project/gotchas.md`); in a `# SHEET:` line of a gate that
  pokes ids, write vs2.

## WHAT CLOSED THIS SITTING (14z-205b, and 14z-205 after its close)

- **Closed `done`:** #300, #295, #257, #276, #275, #273 (STATE_HISTORY 14z-205, after the close).
- **Filed:** #300, #301. **Ruled:** #299's `--jobs 8` close, #262/#263/#277 parked under #289, #260 a close step,
  #273's re-scope and Q1 kept (`DECISIONS_HISTORY.md`, 2026-10-19 entries); #229's answers read 2026-10-20.
- **Built, not closed:** #291 S3 (the unfiltered run is START HERE 1); #229's six gates (unregistered, START HERE 2).
