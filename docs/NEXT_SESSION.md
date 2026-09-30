# NEXT SESSION — orientation (rewritten at the 14z-185 CLOSE, 2026-09-28)

> Rewritten at every session close ([VSP-17]). ROLLOVER: the previous opener
> moves VERBATIM to the top of `NEXT_SESSION_HISTORY.md` — this file holds ONLY
> the live orientation. Session state, not knowledge: facts belong in the docs,
> status in STATE.md.

## THE SETUP, RESTATED

A plain **Opus 5.5 session at effort High** (the ruled orchestrator — STATE 'Standing rulings') on the
#172 setup: every quoted figure from a `measurer` / `reader` spec (`docs/project/worker_spec.md`, the spec
text IN the prompt, no model), every freeze and recommendation through the pinned `rule-checker` with the
prompt files pasted VERBATIM, `record --session`, `resolve` on ONE line with one label per violated question
(never chained with the next `prepare`). Say so at the opener.

## START HERE

0. **AT THE OPENER, RUN `python3 tools/agent/sweep.py`.** What the 14z-185 close found and did is in its
   CLOSE row (STATE 14z-185).
1. **M21 IS FROZEN, NOT RELEASED** (tags `freeze/donovan-m25`, `huitzil-m32`, `pyron-m26`, `merged-m21`; the
   MiSTer romset lane re-run on the committed tree, its result in the CLOSE row). Whether and when to RELEASE
   M21 is the maintainer's.
2. **THE MAINTAINER'S QUEUE, given during the 14z-185 close, verbatim:** *"When everything is done, please do
   #184, #131, #133, #141, #150, #167"*. At 14z-185b #133 was UN-PARKED and #141 ruled `declined` (a
   measured FBNeo-vs-MAME disagreement on legacy content opens a NEW ticket; CLAUDE.md [VSP-24] and the port
   skill's [VSP-24] line say so since 14z-185b, applied at the maintainer's word). 14z-185b's order, verbatim: *"start with #187 and #188. Then we'll rule what to continue with"*.
   #188 route A (`tools/static_confirm.py`) is PROVISIONAL: backtested on three recorded reds, not wired; its
   trust waits for the traced tier on WSL2 (*"History for now, traced on WSL2 later"*, `DECISIONS_HISTORY.md`).
   The Windows box was reinstalled (the maintainer, 2026-09-29: *"it's technically available but there's all the
   WSL2 setup to do again"*): WSL2 per `docs/project/WSL2_SETUP.md` comes first. The full open list is `docs/project/tickets.md`. Opened in 14z-185: #183 (the parity gates'
   `0000` RNG pin is the RNG's fixed point) and #184 (the 28 never-entered a2 chains with no attack record, split
   from #174).
   Also during the close, verbatim: *"quick update  for after the close: workers (not the orchestrator, not the checkers) should preferably use Sonnet 5.5 at xhigh effort. No model used in the swarm is allowed to use max effort, under any circumstance"* (`DECISIONS_HISTORY.md`, 2026-09-29). The
   `measurer`/`reader` frontmatter change (their `effort: high` -> `xhigh`, edit-locked) was proposed at 14z-185b and
   SHELVED by the maintainer: *"The worker model and effort let's drop. I'll come back to it later."* — the change
   also needs `tests/test_agent_worker.sh`'s fixture re-recorded (its line 79 compares the recorded run to the live
   definition). Never spawn any agent at `max`.
3. **Put to the maintainer (measured, not ticketed — their call whether to ticket):**
   a. #159's fix moved two things outside the Summon, each attributed to #159 on the single-row probes, the
      mechanism NOT measured: Pyron's merged-vs-solo ring stream now agrees for the whole run (it diverged at
      f4742 on M20; `tests/audit_pyron_ring.sh` re-stated), and the arcade replay `110_don_arcade_mash` reads
      more defense rows from f8394 (`tests/audit_defense_row_reads.sh`). The candidate for both is the thunk's
      added cycles on the shared facing resolver.
   b. #143 retracted the 14z-91 clause "not in the window = not bit-identical, the design stops"; the walker
      relocation's safety rests on the legacy oracle's verdicts, and reverting the relocation was never among
      the options measured.
   c. `test_mister_gfxc_fetch` ran at 0.47 of its cap in the M21 battery (6,814 s of 14,400) and 0.41 on the
      re-run (5,895 s) — close to the HEADROOM rule's line.

## INSTRUMENT FACTS LEARNED THIS SITTING (read before the work they bear on)

- The next FREEZE runs `tools/freeze_expectation_set.py` (#150; its first real use): the registry rows first,
  then `ROMDIR=... python3 tools/freeze_expectation_set.py <build>:<set> ... --jobs 4`; the shape gate runs on its output.

- A "nothing the battery ran reads it" claim is a REACH question: `tools/battery_reach.py` (paths AND imports,
  extra roots, a strict set, a planted-reader control) — `docs/project/gotchas.md` "IS A REACH QUESTION".
- `--stale` re-runs only gates that PASSED: a freeze that re-freezes a FAILED gate's expectation re-runs that
  gate itself (`docs/project/gotchas.md`).
- A hand-seeded attribution root is part of its fix's landing (`docs/project/gotchas.md` "A SEEDED ATTRIBUTION
  ROOT OUTLIVES THE FIX IT NAMED"); which fix a build carries is read from its own image with
  `tools/patch_site_read.py`; a freeze's moved static pins are attributed by `tools/attr_placement_moves.py`.
- The ticket gate reads a SNAPSHOT: `python3 tools/tickets.py refresh` after closing an issue on GitHub.
- A new jtcores fork commit: add its name to `PATCH_NAMES` and let `tools/setup_jtcores.sh` write the patch
  (a hand-run `format-patch` carries git's signature).
- A Lua tap's `SP` is the supervisor stack; the game runs in user mode, its caller is at `USP`
  (`docs/platform/gotchas.md`).
- The 14z-185 procedure check's recurring finding (runs 449, 450, 452, 453): a step called done in a
  status message before the call that did it — once a ruling reported "recorded" to the maintainer before
  any write. Say "next I will", and say "done" only after the result is on screen.

## WHAT CLOSED THIS SITTING (14z-185)

**#182** and **#159**, both Design A, landed at the **M21 freeze**; **#178** `done` (Hop Kick in DF connects
alike); **#176** `done` (the RNG-draw gate; the tenants' random step timeout is host behaviour); **#174** split
and `done` (its eight attack chains gated; #184 opened); **#160** `done` (`prepare`'s id and late check);
**#155** `done` (the forced-pick gate's legs are the rig's); **#143** `done` (the walker instrument reads the
live stack). Ruled also: `audit_chains174`'s three poke rows OBSERVES with a landing check; the seven one-off
checkers let go.
