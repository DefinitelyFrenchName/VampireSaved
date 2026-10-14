# THE SESSION CLOSE — the one copy of the ritual, and the table its driver runs

**What this is (#282 item C, ruled 2026-10-15 — `DECISIONS_HISTORY.md` "Ruled 2026-10-15 (14z-201) — #282 item
C").** The close was written in 58 places across 30 files, none of them the whole procedure, and 8 sets of them
disagreed. The maintainer chose *"Doc + driver (Recommended)"*. This file is now the one copy: the STEP TABLE below is
the procedure, in order, and `tools/close.py` reads that same table. Every other place that described the close points
here, and a step changes here and nowhere else. A freeze or a release runs its own tier (HANDOFF "How to test"); the
rest of this table still applies to the sitting that makes it.

## How to run it

    python3 tools/close.py start --key 14z-N --prev <the previous close's tier results.tsv>   # once
    python3 tools/close.py next              # runs the auto steps in order; stops at a red or a manual step
    python3 tools/close.py done <step> "<evidence>"   # a manual step done, with where it shows
    python3 tools/close.py status            # every step, its state, and the NEXT one

`start` writes the close's run directory (`build/agent<N>/close/` by default; `--run DIR` to choose) with the
parameters the commands use. `next` runs each auto step's command from the repository root, logs it to
`<run>/steps/<step>.log`, and judges it by the step's verdict: `exit 0`, or a line the log must hold (the static
runners exit 0 on a red, so the tier is judged by its GREEN line). A red stops the walk and shows the log's tail.
A manual step stops the walk and prints what it needs. A red auto step can be passed only with `done` and written
evidence (a SKIP covered on another host, say), and `status` shows it as passed by hand. The tier step ran
2,488 s and 2,619 s at the 14z-200 close, so `next` is started in the background there. A step's state records the commit it ran at, and
`status` marks an auto step STALE once HEAD has moved past it.

Placeholders: `{KEY}` the session key; `{RUN}` the run directory (absolute); `{ROW}` the findings section's title
(`(N) THE FINDINGS TABLE`); `{PREV}` the previous close's tier results; `{TRANSCRIPT}` the transcript's id;
`{ROMDIR}` the reference sets (the environment's `ROMDIR`; `start` refuses without it).

## The steps

<!-- CLOSE STEPS: tools/close.py reads this table; one row per step, in order. Columns: step | kind | command | verdict | done when | from -->
| step | kind | command | verdict | done when | from |
|---|---|---|---|---|---|
| findings | manual | `python3 tools/findings_add.py` (as each finding is paid) | - | the TSV holds every finding of the sitting, each with a live home and a test, `#N (open)` or `none (<reason>)` | checklist step 1, #206 |
| sections | manual | - | - | every piece of work has its `### (N)` section; each earlier row the sitting resolves carries a pointer to where it was resolved; a `### CLOSE ({KEY}, <date>)` section is opened | checklist step 3 |
| next-session | manual | - | - | the previous opener moved VERBATIM to the top of `docs/NEXT_SESSION_HISTORY.md`; `docs/NEXT_SESSION.md` rewritten as the next opener, START HERE holding only open items | [VSP-17] |
| rollover | manual | - | - | every session group but this sitting's own moved VERBATIM to `STATE_HISTORY.md` with its ledger line (the rollover rule below); `STATE.md §` citations into it re-pointed | the rollover rule below |
| indexes | auto | `python3 tools/gen_history_index.py && python3 tools/tickets.py page && python3 tools/gen_gotchas_index.py` | exit 0 | the archives' indexes, the ticket page and the gotchas index regenerated | #282 item E, [VSP-12] |
| live-docs | auto | `sh tests/test_state_open_lists.sh && sh tests/test_live_budget.sh && sh tests/test_history_index.sh && sh tests/test_tickets.sh` | exit 0 | the open lists, the budgets, the indexes and the ticket anchors hold | [VSP-17], #282 item F |
| inputs | auto | `python3 tools/close.py inputs` | exit 0 | the four close-time files exist: `{RUN}/classes.tsv` (every scratch program classed, step 5), `{RUN}/promises.tsv` (every promise classed, step 4), `{RUN}/rulings_exempt.tsv`, `tests/rulecheck/retractions/{KEY}.tsv` | checklist steps 4-5, #190 |
| render | auto | `python3 tools/close_standing.py render --key {KEY} --row "{ROW}" --run {RUN} && python3 tools/close_standing.py row-copy --row "{ROW}" --copy {RUN}/findings_row.txt --write` | exit 0 | the standing checks rendered for this close; the row copy the packet reads written | #204, #207 |
| checks | auto | `python3 tools/close_checks.py run {RUN}/checks.tsv --out {RUN}/out && python3 tools/close_checks.py status {RUN}/checks.tsv --out {RUN}/out` | exit 0 | a FULL run with every check as expected (step 2: missing homes, tracked homes, anchors, none reasons, retractions, promises, scratch classes, rulings verbatim, open tickets) | checklist step 2, close-loop rule E |
| packet | manual | `python3 tools/close_standing.py claim ...`, then `python3 tools/rulecheck.py prepare --decision recommendation --deliverable ...` | - | the documentation packet's run OK, or every VIOLATED question resolved in writing; a presentation-only finding fixed, the checks re-run FULL, then `resolve --recheck` | checklist step 6, #270 |
| commit | manual | `git add -u` plus every new path by name | - | committed; no `build/` path staged; `git status` shows none of the sitting's own new files untracked | gotcha "`git add -u` STAGES NO NEW FILE" |
| tier | auto | `ROMDIR={ROMDIR} STATIC_RESULTS_OUT={RUN}/tier_results.tsv tests/run_on_snapshot.sh -- tests/run_all_static.sh --strict --confirm {PREV}` | line ^GREEN | the tier on a snapshot of HEAD reads GREEN; a SKIP of a gate only another host can run is passed by hand with that host's PASS at the same commit | #269 (ruled 2026-10-12), [VSP-181] |
| sweep | auto | `python3 tools/agent/sweep.py` | exit 0 | CLEAN: every survivor killed, leaves first, or declared with `--declare PID "REASON"` and named in the CLOSE section | C0.3, #172 S2 |
| procedure | manual | `python3 tools/agent/extract.py`, then `python3 tools/rulecheck.py prepare --decision procedure` per part | - | every part's run OK or resolved; `tools/agent/hooks/pre_push.py` refuses the push until one covers a commit in the pushed range | C1, #172 S3 |
| cap | auto | `python3 tools/agent/transcript_gaps.py --subagents {TRANSCRIPT} --cap` | exit 0 | no worker above Opus-class, none without a model, none fallen back (a /btw fork is exempt and named) | ruled 2026-09-24 *"Standing step"* |
| dashboard | manual | `python3 tools/session_metrics.py collect`, then `check`; upload the four JSON files | - | the four datasets re-collected and uploaded to the dashboard, each `datasets/<id>` pointed at its new asset | #264 |
| record | manual | - | - | the CLOSE section records every step's result; committed | [VSP-17] |
| final-tier | auto | `ROMDIR={ROMDIR} STATIC_RESULTS_OUT={RUN}/tier2_results.tsv tests/run_on_snapshot.sh -- tests/run_all_static.sh --strict --confirm {RUN}/tier_results.tsv` | line ^GREEN | the tier over the commits made since step `tier` reads GREEN | the push rule below |
| sweep-last | auto | `python3 tools/agent/sweep.py` | exit 0 | CLEAN, as the last command before the push | the push rule below |
| push | manual | `git push origin main` | - | pushed; anything red, skipped or unresolved leaves the commits local and the CLOSE section says so | ruled 2026-09-10, [VSP-17] |
<!-- /CLOSE STEPS -->

## What the table settled

The eight disagreements the census found (2026-10-15), each settled by the ruling named:
1. **Which tier a close runs:** `--strict --confirm` on the previous close's results (#269, ruled 2026-10-12). A
   freeze or release runs every gate with every control. The "CLOSE runs all (the default)" wording elsewhere predates
   #269.
2. **The checklist's steps 2, 4 and 5:** step 2 is the FULL close-check run, which includes the promise and scratch
   checks. Steps 4 and 5 write those checks' inputs (`inputs`). The promises are classed in `promises.tsv` and the
   scratch programs in `classes.tsv`.
3. **Where the sweep sits:** after each tier, and again as the last command before the push.
4. **The dashboard:** a step, `dashboard`, after the procedure check.
5. **The rollover:** every group but this sitting's own (#282 item A). The indexes are regenerated after it.
6. **The checks file:** rendered from the standing set `tests/close_standing_checks.tsv`, never copied from an
   earlier close (#204).
7. **The rule-checker at the close:** the documentation packet and the procedure check are the two runs a close
   makes. "Never at the session end" in `docs/project/rule_checker.md` concerns decisions, not these two.
8. **Pushing:** only at the close, and only when everything is green ([VSP-17]). A mid-session push needs the
   maintainer's word.

## The rules the steps carry

### The rollover rule

Moved from STATE.md's header 2026-10-15 (#282 item C), shortened, its substance unchanged: after writing the close entry, move
every session group but the newest (this sitting's own) to the TOP of STATE_HISTORY.md's body in newest-first order
(below THE LEDGER, above the first archived `## Session` heading OLDER than the group) and add their one-line entries
at the top of THE LEDGER there, composed from the group's own banner headers, then regenerate the archives' indexes
(`python3 tools/gen_history_index.py`). If STATE.md still exceeds its budget (`tests/test_live_budget.sh`), roll the
oldest kept group early. The standing sections never roll.
**Then re-point what cited the rolled group (added 14z-173, after it bit):** a rollover silently breaks every
`STATE.md § <section>` citation into the group it moved, and `tests/test_tickets.sh` is what notices. After moving a
group, re-point those citations to `STATE_HISTORY.md § <section>` and regenerate the page with
`python3 tools/tickets.py page` — for ALL rows, not just the one the gate stops at.

### The close checklist (ruled 2026-09-18, 14z-167b)

Moved from STATE.md's header 2026-10-15. Six steps, between the close entry and the tier: (1) the findings table,
appended as each finding is paid (`tools/findings_add.py`, #206), so the close reviews it rather than reconstructing it;
(2) the close checks — every GAP homed, every REVIEW answered by a home or an open item, never by reclassifying the
finding; a clean result is never cited as completeness; (3) a pointer on every earlier row the sitting resolves; (4)
the promises, each fulfilled or made an open item; (5) scratch scripts whose figures a document or STATE section
quotes are promoted into `tools/` or `tests/` (ON TRIAL: record how many and how many were promoted); (6) the
documentation packet through the rule-checker (`recommendation`, the table as the claim), its verdict resolved like
any run — a finding that is only a figure, a quote or a wording on an item the checks cover is fixed and re-checked by
a FULL close-checks run, then resolved with `resolve --recheck` (#270, `docs/project/rule_checker.md` [VSP-184]).

### The close loop's own cost (ruled 2026-09-29, 14z-185b, #187/#188)

Moved from STATE.md's header 2026-10-15. (E) a close's checks run through `tools/close_checks.py` from the rendered
checks file: a fix is iterated with `--only <check>`, and a rule-checker `prepare` cites a FULL run whose `status` exits
0; (F) a count a close states never includes `tests/rulecheck/runs/`: exclude it, or read the count at `prepare` and
say so; (D) doc edits are batched BEFORE a confirmation tier, no heavy job runs beside a tier, and the browser-driving
gate runs last in its tier (`# ORDER: last`).

### The push rule (ruled 2026-09-10)

Moved from STATE.md's header 2026-10-15. The last step of the close is the push, and only when every step above is
done: the tier GREEN, the sweep CLEAN, the procedure check passed or resolved and the `--cap` read clean. Anything red
or skipped leaves the commits local, and the close entry says so. The opener's sweep survivor is killed before the push
only on the maintainer's command (ruled 2026-09-25).
