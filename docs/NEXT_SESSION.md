# NEXT SESSION — orientation (rewritten at the 14z-190 CLOSE, 2026-10-04)

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
work there in parallel.**

## START HERE

0. **AT THE OPENER, RUN `python3 tools/agent/sweep.py`.** What the 14z-190 close found and did is in its
   CLOSE row (STATE 14z-190 row (11)).
1. **PILOT'S LINUX RELEASE BINARIES — THE MAINTAINER'S TO RULE** (STATE 14z-190 row (11)): built and gated on PILOT
   at the 14z-190 close (glibc 2.39, the release floor; `docs/project/build_environments.md` "PILOT, Ubuntu 24.04
   VM"), not published. Put to the maintainer whether PILOT's `BINARY.txt` records (copies in
   `build/agent190/pilot_rel/`) replace the tree's WSL2 ones for the next release.
2. **#206 — JUDGED AT THE 14z-190 CLOSE** (STATE 14z-190 row (11)): put closing it to the maintainer with the
   close's own figures (the table existed before the close; how many documentation-packet runs it took).
3. **#188 — OPTION B IN THE PREDICTOR SINCE 14z-190** (STATE 14z-190 rows (7), (11)): compare what the 14z-190
   close's `--confirm` carried with the modelled 1,035 of 5,449 s, then put closing #188 to the maintainer;
   `test_close_tools`'s 1,424 s of controls re-run by design. Promoting the traced test that scored B is #225.
4. **#214 — SHIP THE GENERATOR FIX WITH THE NEXT RELEASE, THEN CLOSE IT** (STATE 14z-190 row (10)): merged-m22's
   published MiSTer README still claims an emulator; `tests/test_release_launcher_bat.sh` holds the generator.
5. **ERIS'S CLONE** (STATE 14z-190 row (9)): its 14 uncommitted files hold nothing unique (the 6 lines found in no
   commit are early drafts of committed content); resetting `~/vampire-saved` there to `main` is the
   maintainer's call (untracked files were not compared).
6. **QUESTION WAITING FOR THE MAINTAINER (it blocks nothing):** #216 — Lei-Lei 6HP (one hit measured at 128 px,
   the workbook says three) and the other #117 gaps, to check against the Japanese community wiki.
7. **#219 — `tests/run_all_emulator.sh --dry-run` writes a run record that hides staleness.** Until it is fixed,
   never dry-run before a `--stale` run without re-reading `python3 tools/audit_emulator_staleness.py --names`.
8. **Smaller open tickets:** #215 (the applier's zip `create_system` differs by host), #217 (rule-checker
   throughput), #218 (`tools/audit_poked_legs.py`'s id map is shifted), #221 (`--prune` stops at an unreleased
   tag; merged-m19's zips stay hosted until it is fixed — ruled), #222 (Phobos's minimum air-attack height,
   static), #223 (two sound-request sites, static), #224 (an anchor holding the findings table's separator is
   SKIPped silently), #225 (promote #188's traced test).
9. **SHELVED BY THE MAINTAINER:** the measurer/reader frontmatter change to Sonnet 5.5 at `xhigh`.

## INSTRUMENT FACTS LEARNED THIS SITTING (read before the work they bear on)

- The static runner keeps each executed control's seconds as `results.controls.tsv` beside `results.tsv`; a
  close tier's controls cost more than its gates (3,396 s against 2,053 s), `test_close_tools` alone 1,424 s.
- Narrowing a predictor rule can remove coverage another rule never gave: B's `build/` narrowing missed 15 reads
  that only the bare directory had caught (`tools/static_confirm.py`'s docstring, "the trace of B as first
  built"). A narrowing is scored on a trace of every gate's reads, with an over-narrowed control that must
  miss, before it lands.
- `tests/test_tickets.sh` needs every session key in a row to resolve in STATE: open the session's group (rolling
  the oldest) before indexing a ticket under the new key.
- `tests/test_state_open_lists.sh` refuses a closed marker (`LANDED`, `DONE`, `FIXED`, `CLOSED`) in START HERE.
- `tools/findings_add.py` refuses a `(x)` letter form inside a finding; a home anchor must not contain ` — ` (#224);
  an ambiguous bare document name in a finding fails `tools/homes_tracked.py`.
- A promise-class key must not start with `#` (the classes file reads it as a comment).
- A gate header's WHAT/HOW/EXPECTS edit needs `python3 tools/gen_gate_coverage.py` in the same commit (paid twice).
- PILOT traces all 203 static gates under strace in about 7 minutes at 6 jobs.

## WHAT CLOSED THIS SITTING (14z-190)

**#204** and **#207** `done`; **#128** and **#162** kept parked; the five poke read-back rows ruled "as read";
**#188** option B landed (0 misses on a PILOT trace); **#214** fixed in the generator. Filed: #222-#225.
