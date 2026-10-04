# NEXT SESSION — orientation (rewritten at the 14z-189 CLOSE, 2026-10-04)

> Rewritten at every session close ([VSP-17]). ROLLOVER: the previous opener
> moves VERBATIM to the top of `NEXT_SESSION_HISTORY.md` — this file holds ONLY
> the live orientation. Session state, not knowledge: facts belong in the docs,
> status in STATE.md.

## THE SETUP, RESTATED

A plain **Opus 5.5 session at effort High** (the ruled orchestrator — STATE 'Standing rulings') on the
#172 setup: every quoted figure from a `measurer` / `reader` spec (`docs/project/worker_spec.md`, the spec
text IN the prompt, no model), every freeze and recommendation through the pinned `rule-checker` with the
prompt files pasted VERBATIM, `record --session`, `resolve` on ONE line with one label per violated question
(never chained with the next `prepare`). Say so at the opener. Never spawn any agent at `max`.
A recommendation leans only on the maintainer's OWN words. When no ruling covers it, ask plainly instead.
**Before any long job, check whether PILOT (`ssh pilot`) or ERIS (`ssh eris`) is idle and run independent
work there in parallel** (the maintainer, 14z-189, STATE 14z-189 row 10).

## START HERE

0. **AT THE OPENER, RUN `python3 tools/agent/sweep.py`.** What the 14z-189 close found and did is in its
   CLOSE row (STATE 14z-189 row 14).
1. **QUESTIONS WAITING FOR THE MAINTAINER (none blocks work; ask them early):**
   (a) #162 — the column flash is the palette reload keeping vsavj's mask without Donovan's bit; the one-bit
   fix needs a capture before any build (`tests/audit_column_flash_cause.sh`); its census also found Phobos's
   air-attack height row (`0x10`) and the sound-id sites;
   (b) #128 — Marionette's measured cost (`tests/audit_marionette_cost.sh`): build it or keep it parked;
   (c) #129 and #117 — five `poke_readback` rows are UNCLASSIFIED (`ff8109`, `ff8116`, `ff8450`, `ff8850`
   for #129; `ff8850` for #117): classify them;
   (d) #216 — Lei-Lei 6HP (one hit measured at 128 px, the workbook says three) and the other #117 gaps,
   to check against the Japanese community wiki.
2. **#188 — MEASURE WHAT `--confirm` SAVED AT THIS CLOSE** (STATE 14z-189 row 14), then close it or keep it.
3. **#204, #206, #207 WERE USED FOR THE FIRST TIME AT THIS CLOSE** (`tools/close_standing.py`,
   `tests/close_standing_checks.tsv`): read how many documentation-packet runs the close took (row 14) against
   12, 8 and 7 before them, and put closing them to the maintainer.
4. **#214 — the MiSTer README still says the package holds an emulator.** It shipped in merged-m22; fix the
   generator, extend `tests/test_release_launcher_bat.sh`'s check, and it goes out with the next release.
5. **#219 — `tests/run_all_emulator.sh --dry-run` writes a run record that hides staleness.** Until it is
   fixed, never dry-run before a `--stale` run without re-reading `python3 tools/audit_emulator_staleness.py
   --names` (`docs/project/gotchas.md`, by a DRY RUN).
6. **PILOT on Verilator 5.020:** the two MiSTer oracles pass against the 5.050 expectations
   (`docs/platform/mister.md`, On another host); the rest of the lane has not run there. The known-good
   environment entry for PILOT (`docs/project/build_environments.md`) needs a real release build and gate
   on it first.
7. **Smaller open tickets from this sitting:** #215 (the applier's zip `create_system` differs by host),
   #217 (rule-checker throughput), #218 (`tools/audit_poked_legs.py`'s id map is shifted).
8. **SHELVED BY THE MAINTAINER:** the measurer/reader frontmatter change to Sonnet 5.5 at `xhigh`.

## INSTRUMENT FACTS LEARNED THIS SITTING (read before the work they bear on)

- A DOC-ONLY or comment-only edit after a whole-tier run does not need the whole tier again: re-run the gates
  that read the edited files and name "whole tier not re-run" in the claim (the maintainer agreed, 14z-189).
- `tests/test_emulator_staleness.sh` takes its cadence ONLY from `VS_CADENCE`; a `--cadence` argument is
  ignored (`docs/project/gotchas.md`).
- Never export a runner's knobs (`STATIC_RESULTS_OUT`) around a tier: they reach every gate, and a gate that
  compares two runners goes red (`docs/project/gotchas.md`).
- A worktree that holds rule-checker records is never reset or cleaned before they are committed or copied
  out — run 602's record was lost that way (`docs/project/gotchas.md`).
- A big rule-checker claim draws a new finding every round: 22 rounds for one commit this sitting. Keep the
  claim to the commit's own facts; split unrelated repairs into their own commits and packets.
- Read `docs/project/tickets.tsv` before filing: #220 was opened and closed as a duplicate of #214.

## WHAT CLOSED THIS SITTING (14z-189)

**#130**, **#133**, **#196**, **#203**, **#205**, **#208**, **#209** `done`; **#202** `declined`; **#220**
`duplicate`; **#145** and **#212** with the merged-m22 release (STATE 14z-189 row 14). Frozen: **M22**
(donovan-m26, huitzil-m33, pyron-m27, merged-m22). Corrected: the minimum air-attack height (24, Lei-Lei,
fifteen callers). Filed: #214-#219.
