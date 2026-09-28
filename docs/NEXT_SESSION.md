# NEXT SESSION — orientation (rewritten at the 14z-184 CLOSE, 2026-09-27)

> Rewritten at every session close ([VSP-17]). ROLLOVER: the previous opener
> moves VERBATIM to the top of `NEXT_SESSION_HISTORY.md` — this file holds ONLY
> the live orientation. Session state, not knowledge: facts belong in the docs,
> status in STATE.md.

## THE SETUP, RESTATED

A plain **Opus 5.5 session at effort High** (the ruled orchestrator — STATE 'Standing rulings') on the
#172 setup: every quoted figure from a `measurer` / `reader` spec (`docs/project/worker_spec.md`, the spec
text IN the prompt, no model), every freeze and recommendation through the pinned `rule-checker` with the
prompt files pasted VERBATIM, `record --session`, `resolve` on ONE line. Say so at the opener.

## START HERE

0. **AT THE OPENER, RUN `python3 tools/agent/sweep.py`.** What the 14z-184 close found and did is in its
   CLOSE row (STATE 14z-184).
1. **#182 IS STEP ONE — staged by the maintainer.** At 14z-184 the session proposed three steps — (1) open a
   ticket for #182, (2) finish #174's gate, (3) *"Bring you a fix plan through the rule-checker before building"* —
   and asked *"Shall I go ahead with 1 and 2, and prepare the plan for 3?"*; the maintainer: *"yes"*. After 1 and 2
   landed, the maintainer: *"So you advise to close properly and stage step 3 for next session, right?"* — the
   session agreed, so step 3, the #182 fix plan, opens this session. Phobos's guard cancel from an AIR block never fires on ours: vs2's block
   entry opens the guard window `+0x158` in the air for fighter id 0x10 alone (`cmpi.b #$10,$382(a6)` at
   `0x022480`), vsavj's never does (`docs/game/engine_internals.md` "THE GUARD WINDOW ON AN AIR BLOCK").
   In order:
   a. **Promote the legacy control** into a tracked gate — IN PROGRESS 14z-185: `tests/audit_air_gc_legacy.sh`
      (corrected 14z-185: the air guard cancel is Phobos's alone, the maintainer; `engine_internals.md`
      "THE GUARD WINDOW ON AN AIR BLOCK").
   b. **Measure the two designs before recommending** (no shipped byte first): **A** — a hook in vsavj's
      block entry (`0x02393a`) doing vs2's id-0x10 check (exact native behaviour; every character's block
      runs the check, so the legacy oracle and the flicker inventory must be measured); **B** — a patch in
      Phobos's own ported guard-cancel check (legacy untouched by construction; vs2's 14-frame window must be
      reproduced or it is a feel difference). Probe builds, the legacy corpus for A, `audit_move_parity` and
      `audit_chains174` for both; then the plan through the rule-checker, then the maintainer.
2. **`tests/audit_chains174.sh` freezes #182 AS THE DEFECT** (the two air-block rows DIFF). A fix re-freezes
   those two rows by design; everything else in it is IDENT and must stay so.
3. **Open tickets in the maintainer's order (14z-185: "do #182, #176, #174, #159 in that order"):** **#159**; then
   #145, #170, #183 (the parity gates' `0000` RNG pin is the RNG's fixed point) and #184 (the 28 never-entered
   a2 chains with no attack record, split from #174); both opened 14z-185.
4. **The 14z-184 promise: the gates following the files edited for comments re-run at the next freeze.** The
   frame-label sentence was corrected in `tests/lua/read_tap.lua` and five more instruments (`bp_regs.lua`,
   `qs_sweep.lua`, `qs_table_trace.lua`, `ring_tap.lua`, `unmapped_probe.lua`) and in
   `tests/test_replay_stage_census.sh`; `tests/lua/trace_writes.lua` was edited for the retired m18 gate's
   pointer. Comments only; every gate whose `# FOLLOWS:` names one of these reads stale until the freeze's
   `--stale` re-run. 14z-185 adds `tests/audit_merged_legacy.sh` (two echo lines now print `$EXPECT`, the table
   actually read, instead of a fixed "tests/expected/merged1").
5. **Carried from 14z-183b, still open:** the three gate headers changed at the 14z-183 close re-run at the
   next freeze's `--stale`; M20 is frozen, not released.
6. **Instrument facts learned this sitting** (read before tapping): a `read_tap.lua` write labelled N is
   replay.lua's / `field_trace.lua`'s frame N+1 (`docs/platform/gotchas.md`); a rig event's outcome can
   depend on its absolute frame — keep measured frames with spacers (`docs/project/gotchas.md`).

## WHAT CLOSED THIS SITTING (14z-184)

**#181** (the emulator tier on a snapshot — ruled *"Copy the cache"*, *"Last-commit time"*, *"Copied back"*,
*"Private copies"*); **#180** `not-ours` (vs2's own ES throws; the third pair store is the applier's KO
branch); **#179** `not-ours` (on a shared wall vsavj pushes P1 out, vs2 P2 — documented, gated by
`tests/audit_shared_wall_push.sh`); **#177** `invalid` (the movement comparison existed; `movement-x`
proves it). Ruled also: `read_tap.lua`'s frame-label comment fixed now; `audit_x2b7ef4_reach_m18` retired;
#174's rigs in a dedicated gate. All in `DECISIONS_HISTORY.md` "Ruled 2026-09-27 (14z-184)".

## TRAPS PAID THIS SITTING

1. **Three legacy controls were wrong before one held (#179)** — a view-edge pin, then setups the games had
   already split; the maintainer designed the fourth. A cross-game control is the same setup until the
   event: find its first differing frame first (`docs/project/gotchas.md`).
2. **A coverage finding read from a gate's description (#177)** — the rigs were the movements all along.
3. **A recommendation that tried to prove a whole-tree negative (#174, rule-checker runs 299-306)** — seven
   rounds; the claim converged only when the negative was NAMED as untested instead of asserted.
4. **An expectation committed without its `PROVENANCE.md` row** (the #179 gate) — run
   `tests/test_expectation_provenance.sh` in the registration checklist of every new gate.
