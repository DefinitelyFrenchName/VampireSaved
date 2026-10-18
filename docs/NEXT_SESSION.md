# NEXT SESSION — orientation (rewritten at the 14z-205 CLOSE, 2026-10-18)

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
PILOT and ERIS were unavailable on 2026-10-17/18; check `ssh pilot` / `ssh eris` before relying on them.

**THE SESSION CLOSE:** `docs/project/session_close.md`, run by `python3 tools/close.py` (`start --key … --row - --prev
<results>`, then `next`, `done`, `status`). The run of record is named in STATE 14z-205's CLOSE section.

**THE STATIC TIER CHANGED THIS SITTING (14z-205; the page https://claude.ai/artifact/1DzrvoGUphYYmtyRKvhJtZ, private):**
109 gates of six families run at freeze cadence, pulled into a session only when their own code changes (`@code`,
#297); at a commit or close a gate's controls execute only when a program of its reach changed (#298); `--jobs N` runs
gates in parallel (#299, not yet a close's default).

## START HERE

0. **AT THE OPENER, RUN `python3 tools/agent/sweep.py`.**
1. **#299 — parallel gates: the full-tier comparison.** The portable tier without controls matched at 8 jobs (89 gates, 11 min 7 s → 4 min 54 s). Next: on one snapshot, the full tier with controls serially and at `--jobs 8`, every verdict compared, CPU and memory sampled (STATE 14z-205 (9) and its CLOSE section say how far this close got); then ask the maintainer whether a close runs at `--jobs 8`.
2. **#298 — measure the narrowed controls** on this close's tier (`build/agent205/close/tier_results.controls.tsv`, local) against 1,500-1,800 s of controls per close before; comment the figures on #298 and close it if the narrowing held.
3. **#296 — the sandbox inventory over the other emulator lanes** (step 1 is built: `MAME_SANDBOX_LOG`; the prereq lane's 324 runs were all fresh). Run the mame and fbneo lanes with the log on, on PILOT or ERIS when they are back, attribute every `reused` line, then step 2: refusal by default with `MAME_SANDBOX_REUSE=1` for a declared reuse.
4. **#295 — a vsavj-vs-ours leg for `audit_dmg_legacy_sweep`'s legacy hits.** Plan it and put the plan through the rule-checker before building (32 more MAME runs, judged exact against vsavj, a planted one-HP control).
5. **#291 — the capture sheets: S2 is complete.** Left: a note above each of the other 57 drawing gates (`docs/project/sheet_notes.md`, one written; each from the gate's header and the subject docs, never invented; #291's comment of 2026-10-18), then S3 (build from the commit, `--host pilot|eris`).
6. **#286 and #292, when PILOT is back:** the parked narrowings (`build/agent203/t286/narrowings_on259.patch`, local) and the planner's self-test reads, each scored on a PILOT trace (0 misses, #225).
7. **#297 stays open until a freeze has run the 109 moved gates green**; a freeze runs every gate anyway.
8. **Then ask the maintainer for the order of work.** The open tickets by their GitHub severity label:
   - high: #286, #292;
   - medium: #295, #296, #284, #257;
   - low: #118, #229, #244 (and #129, parked);
   - no severity label: #260, #262, #263, #266, #267, #273, #275, #276, #277, #289, #291, #297, #298, #299;
   - **release-only:** #278, #279, #280, #281.
9. **`tests/replays/118_chain.rpl`'s header names a leg of `audit_mizuumi_inputs` that gate never ran** (STATE_HISTORY 14z-198 finding (i)); the one-line correction rides a session that runs the emulator gates following `tests/replays/`.

## PARKED (not open work)

- #124 and #294 (Killshread's aura palette, filed parked by the maintainer 2026-10-18), and #121.
- **VampireSaved-Rebuilt#1** holds what is left of #120, closed 14z-205: the maintainer's review of `SPEC.md` v0.2, `CLAUDE.md` v0.1 and the carry ledgers' ten flags; phase 0 (the rule-5 extraction, in THIS repository, a ticket here when it starts).

## INSTRUMENT FACTS LEARNED THIS SITTING (read before the work they bear on)

- **The forced-pick census reads a script's comments:** the word `vsav2` in a poked gate's prose makes a native leg (`docs/project/gotchas.md`, paid twice, 14z-197 and 14z-205). In a `# SHEET:` line of a gate that pokes ids, write vs2.
- **A sandbox named after part of a run's identity is shared** (#293; `docs/project/gotchas.md`); `MAME_SANDBOX_LOG=<file>` now logs every run's sandbox as fresh or reused.
- **The no-ROM-bytes rule's line** (ruled 2026-10-18): addresses and discrete values are fine; whole graphics, sounds and algorithms are not.
- **A capture sheet's explanation** lives in `docs/project/sheet_notes.md`, never in the gate (writing one re-runs nothing).

## WHAT CLOSED THIS SITTING (14z-205)

- **#291 S2 complete** (`bf92acd2`): 58 gates draw, 174 declare, the EVENT-PROVEN basis and the `no-picture` kind; the debt list is empty.
- **#293 closed `done`** (`bf92acd2`): both carried-nvram gates give every run a fresh sandbox.
- **#120 closed `done`**: the rebuild's spec, CLAUDE.md, skills and swarm in `DefinitelyFrenchName/VampireSaved-Rebuilt`; the rest is its #1.
- **Filed:** #294 (by the maintainer), #295, #296, #297, #298, #299. **Ruled:** the census re-freeze, #295, the ROM-bytes line, #296, and the static tier's scope (`DECISIONS_HISTORY.md`, 2026-10-18 entries).
