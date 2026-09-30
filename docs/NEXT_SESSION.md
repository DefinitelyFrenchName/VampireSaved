# NEXT SESSION — orientation (rewritten at the 14z-185b CLOSE, 2026-09-30)

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

## START HERE

0. **AT THE OPENER, RUN `python3 tools/agent/sweep.py`.** What the 14z-185b close found and did is in its
   CLOSE row (STATE 14z-185b).
1. **M21 IS FROZEN, NOT RELEASED.** Whether and when to release it is the maintainer's.
2. **THE OPEN QUEUE.** #184 is IN PROGRESS: phases 1-2 done (STATE 14z-185b row (15), the issue's comment,
   scratch `build/agent185b/t184_notes.md`); next are focused rigs for Donovan a2:0x2b (Pyron a2:0x49 was passage through j.LP, corrected 14z-186) compared
   ours-vs-native through the #174 machinery, then the handler reading for the other 28. Still queued from the
   14z-185 close: #133 (un-parked; needs a wider host — WSL2 first). Opened at 14z-185b, each with its rulings in
   `DECISIONS_HISTORY.md`: #187/#188 (built D, E, F and route A, PROVISIONAL),
   #189 (built), #190 (P1, P2, P4 built; P3 kept for later). The full list is `docs/project/tickets.md`.
3. **WAITING ON THE WINDOWS BOX.** It was reinstalled (the maintainer, 2026-09-29: *"it's technically available but
   there's all the WSL2 setup to do again"*): WSL2 per `docs/project/WSL2_SETUP.md` comes first, then #188 route
   A's traced tier (*"History for now, traced on WSL2 later"*) and #133.
4. **SHELVED BY THE MAINTAINER:** the measurer/reader frontmatter change to Sonnet 5.5 at `xhigh` (*"The worker
   model and effort let's drop. I'll come back to it later."*); when it returns, `tests/test_agent_worker.sh`'s
   fixture needs re-recording too.

## INSTRUMENT FACTS LEARNED THIS SITTING (read before the work they bear on)

- A close's checks now run through `tools/close_checks.py` from a checks TSV under `build/` (STATE's header,
  "THE CLOSE LOOP'S OWN COST"): iterate with `--only`, and cite a FULL run whose `status` exits 0. The close's
  figure spec is `tools/figure_check.py`'s, its quotes are checked by `tools/agent/rulings_verbatim.py`, its
  scratch by `tools/scratch_census.py`; see this close's `build/agent185b/close/` for a worked example.
- The next FREEZE runs `tools/freeze_expectation_set.py` (#150; its first real use): the registry rows first,
  then `ROMDIR=... python3 tools/freeze_expectation_set.py <build>:<set> ... --jobs 4`; the shape gate runs on
  its output. `tests/test_superseded_pins.sh` (#167) catches a pinned superseded fingerprint in this tree.
- Both runners now write a run record (`tools/run_record.py`): `compare <start> <end|--now>` answers "the tree
  then vs now" and "what changed during the run". A test run of the emulator driver becomes
  `test_emulator_staleness`'s run of record — remove it after (`docs/project/gotchas.md`).
- A perturbed-copy control whose edit does not compile reads DEAD; `tests/test_freeze_set_shape.sh` names that
  case CRASHED. Check a new control's copy runs before trusting its verdict.

## WHAT CLOSED THIS SITTING (14z-185b)

**#131** `declined` (kept as a case-specific instrument); **#141** `declined` (a measured legacy disagreement
opens a new ticket; CLAUDE.md [VSP-24] amended at the maintainer's word); **#150** and **#167** `done`. Built
without closing: #187/#188 (D, E, F; route A provisional), #189, #190 (P1, P2, P4), stage 4 in the
reproducibility gate. Ruled: #143's oracle-backed basis accepted for now; #159's side moves clean.
