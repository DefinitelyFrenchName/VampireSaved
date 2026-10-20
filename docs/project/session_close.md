# THE SESSION CLOSE — the one copy of the ritual, and the table its driver runs

**What this is (#282 item C, ruled 2026-10-15 — `DECISIONS_HISTORY.md` "Ruled 2026-10-15 (14z-201) — #282 item
C").** The close was written in 58 places across 30 files, none of them the whole procedure, and 8 sets of them
disagreed. The maintainer chose *"Doc + driver (Recommended)"*. This file is now the one copy: the STEP TABLE below is
the procedure, in order, and `tools/close.py` reads that same table. Every other place that described the close points
here, and a step changes here and nowhere else. A freeze or a release runs its own tier (HANDOFF "How to test"); the
rest of this table still applies to the sitting that makes it.

**CUT TO WHAT CHECKS THE WORK (#288, ruled 2026-10-15 — `DECISIONS_HISTORY.md` "Ruled 2026-10-15 (14z-202) — #288:
everything but the before-an-action check is cut; …").** #288 classed 360 VIOLATED rule-checker runs: the checks before an
action caught a real error in 24 of 57, the close's documentation packet in 21 of 192 (1 of 78 in its last two weeks), the
procedure check in 9 of 111. The maintainer: *"Then for now let's cut everything except the "before an action" and let's
open a ticket to revisit in the future when we have more data"* (#289). Cut from the close: the findings table, the
live-docs step (the tier runs those gates), the close checks with their inputs and render, the documentation packet, the
procedure check, the `--cap` read, and the final tier (the records were then committed before the one tier; since #290,
ruled 2026-10-16, 14z-203, they are STAGED, the tier runs on a snapshot of the staged tree, and the commit follows). Their tools stay
in the tree and their gates are `ondemand` (`tests/ci_cadence.tsv`). A rule-checker run is made only before an action
(`docs/project/rule_checker.md`). The one recurring real catch of the procedure check, a commit or close on a tier that
was not green, is #290's deterministic guard.

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
| sections | manual | - | - | every piece of work has its `### (N)` section; each earlier section the sitting resolves carries a pointer to where it was resolved; a `### CLOSE ({KEY}, <date>)` section is opened | [VSP-17] |
| next-session | manual | - | - | the previous opener moved VERBATIM to the top of `docs/NEXT_SESSION_HISTORY.md`; `docs/NEXT_SESSION.md` rewritten as the next opener, START HERE holding only open items | [VSP-17] |
| rollover | manual | - | - | every session group but this sitting's own moved VERBATIM to `STATE_HISTORY.md` with its ledger line (the rollover rule below); `STATE.md §` citations into it re-pointed | the rollover rule below |
| indexes | auto | `python3 tools/gen_history_index.py && python3 tools/tickets.py page && python3 tools/gen_gotchas_index.py` | exit 0 | the archives' indexes, the ticket page and the gotchas index regenerated | #282 item E, [VSP-12] |
| dashboard | manual | `python3 tools/session_metrics.py collect`, then `check`; upload the four JSON files | - | the four datasets re-collected and uploaded to the dashboard, each `datasets/<id>` pointed at its new asset | #264; kept 2026-10-15 (#288) |
| record | manual | - | - | the CLOSE section records every step's result up to here and names the tier's results file `{RUN}/tier_results.tsv`, the next close's `--prev` | [VSP-17] |
| stage | manual | `git add -u` plus every new path by name | - | the records staged, nothing committed yet; no `build/` path staged; `git status` shows none of the sitting's own new files untracked | gotcha "`git add -u` STAGES NO NEW FILE"; #290 |
| tier | auto | `ROMDIR={ROMDIR} STATIC_RESULTS_OUT={RUN}/tier_results.tsv tests/run_on_snapshot.sh --commit "$(git commit-tree "$(git write-tree)" -p HEAD -m '{KEY} close: the staged tree')" -- tests/run_all_static.sh --strict --jobs 8 --confirm {PREV}` | line ^GREEN | the tier on a snapshot of the STAGED tree, 8 gates at a time (#299), reads GREEN, and its row is in the green index (`.git/green_index.tsv`); a SKIP of a gate only another host can run is passed by hand with that host's PASS at the same tree; a red is fixed, re-staged and the tier re-run with `--confirm` on this run's results | #269, #286, #290, #299, [VSP-181] |
| commit | manual | `git commit -F -` (the message on a quoted heredoc) | - | committed; the pre-commit hook read the tier's row for the staged tree (`tools/git-hooks/green_guard.py`); `status` then marks the tier STALE, as it does `indexes`, because HEAD moved — the hook is what ties the run to the commit | #290 |
| pins | auto | `python3 tools/submodule_pins.py` | exit 0 | every submodule pin in HEAD, the commit the push sends, is served by the remote its `.gitmodules` names: a fetch by sha into an empty repository, what a fresh clone's `git submodule update` does (2.3 to 2.9 s, measured 2026-10-19). A MISSING pin is pushed to its own remote first, then the step re-run; an ERROR (the remote could not be asked) is never passed by hand without that remote's answer | #260, ruled 2026-10-19 (14z-205) |
| sweep | auto | `python3 tools/agent/sweep.py` | exit 0 | CLEAN, as the last command before the push: every survivor killed, leaves first, or declared with `--declare PID "REASON"` and named in the CLOSE section | C0.3, #172 S2 |
| push | manual | `git push origin main` | - | pushed; anything red, skipped or unresolved leaves the commits local and the CLOSE section says so | ruled 2026-09-10, [VSP-17] |
<!-- /CLOSE STEPS -->

## What the table settled

The eight disagreements the census found (2026-10-15), each settled by the ruling named:
1. **Which tier a close runs:** `--strict --confirm` on the previous close's results (#269, ruled 2026-10-12). A
   freeze or release runs every gate with every control. The "CLOSE runs all (the default)" wording elsewhere predates
   #269.
2. ~~**The checklist's steps 2, 4 and 5**~~ — CUT 2026-10-15 (#288): the close checks and their inputs are no longer
   close steps.
3. **Where the sweep sits:** once, as the last command before the push (since #288 the close has one tier).
4. **The dashboard:** a step, `dashboard`, before the record and the commit (kept by the maintainer, 2026-10-15).
5. **The rollover:** every group but this sitting's own (#282 item A). The indexes are regenerated after it.
6. ~~**The checks file**~~ — CUT 2026-10-15 (#288) with the close checks.
7. **The rule-checker at the close:** none since #288 (2026-10-15). The documentation packet and the procedure check are
   cut; a rule-checker run is made only before an action. **And no action is held for the close (ruled 2026-10-16,
   14z-203):** a ticket is closed and a recommendation put in the piece of work that finishes it, so its run happens
   there; a rule-checker run cited in a CLOSE section is the tell that one was held (`DECISIONS_HISTORY.md` "Ruled
   2026-10-16 (14z-203) — an action is checked when its work is done, never held for the close").
8. **Pushing:** only at the close, and only when everything is green ([VSP-17]). A mid-session push needs the
   maintainer's word.
9. **The submodule pins:** checked by the `pins` step, after the commit and before the sweep, so it reads the commit the
   push sends. It was a close-check row from 14z-197 and went with the close checks in #288; the maintainer brought it
   back as a step: *"#260 make it a close step"* (2026-10-19, 14z-205). Its logic is gated in every tier by
   `tests/test_submodule_pins.sh`.

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

**CUT 2026-10-15 (#288).** Kept below for the record; no step runs it since #288. Each finding's fact is still homed in its document when it is
paid for ([VSP-12]); the table of them, the checks over it and the packet are cut.

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

**(E) and (F) CUT 2026-10-15 (#288)** with the close checks; (D) stands.

Moved from STATE.md's header 2026-10-15. (E) a close's checks run through `tools/close_checks.py` from the rendered
checks file: a fix is iterated with `--only <check>`, and a rule-checker `prepare` cites a FULL run whose `status` exits
0; (F) a count a close states never includes `tests/rulecheck/runs/`: exclude it, or read the count at `prepare` and
say so; (D) doc edits are batched BEFORE a confirmation tier, no heavy job runs beside a tier, and the browser-driving
gate runs last in its tier (`# ORDER: last`).

### The push rule (ruled 2026-09-10)

Moved from STATE.md's header 2026-10-15. The last step of the close is the push, and only when every step above is
done: the tier GREEN at the commit being pushed and the sweep CLEAN (the procedure check and the `--cap` read were cut
2026-10-15, #288). Anything red or skipped leaves the commits local, and the close entry says so. The opener's sweep survivor is killed before the push
only on the maintainer's command (ruled 2026-09-25).
