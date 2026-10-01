# NEXT SESSION — orientation (rewritten at the 14z-186 CLOSE, 2026-09-30)

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

0. **AT THE OPENER, RUN `python3 tools/agent/sweep.py`.** What the 14z-186 close found and did is in its
   CLOSE row (STATE 14z-186).
1. **WSL2 IS NEARLY READY** (the maintainer, 2026-09-30: *"On my end the WSL2 is almost ready so we'll be able to
   continue, likely in the next session, with that."*). Work it by SSH from this Mac session, never a separate
   session on the box; `docs/project/WSL2_SETUP.md`. What waits on it: #133 and #188 route A's traced tier.
2. **M21 IS FROZEN, NOT RELEASED.** Whether and when to release it is the maintainer's.
3. **THE OPEN QUEUE, by what 14z-186 left:** #194 (Pyron's Cosmo Disruption: the victim's plain hit reaction
   where native's is fire / knockdown; P2 class `0x51` native / `0x4F` ours; the candidate cause is the 14z-75
   remap in `build/manifest/pyron.toml`, unmeasured as the cause — the next step is a probe build with the byte
   restored, checked for the 14z-75 watchdog reset and against the captures; any fix changes how the move plays,
   so it goes to the maintainer), #191 (Donovan's 2HK damage; next, a second legacy victim; it was filed on rule-checker run 464, whose
   reader grepped its six traces instead of reading them (procedure run 2026-10-01-498), so re-measure its
   9-against-8 before relying on it), #192 (Demitri's
   Chaos Flare, vsavj against vsav2). Still queued: #133, #187/#188 (route A provisional), #189, #190 (P3 kept
   for later). The full list is `docs/project/tickets.md`.
4. **SHELVED BY THE MAINTAINER:** the measurer/reader frontmatter change to Sonnet 5.5 at `xhigh`.

## INSTRUMENT FACTS LEARNED THIS SITTING (read before the work they bear on)

- `tools/move_parity.py` compares both white HP words now, excludes a pin from every BYTE it writes, and refuses a
  trace missing a compared field; `tests/audit_move_parity.sh` has `KEEP=<dir>` (the control part's real native
  trace is kept as `tr_<part>_native.real.txt` — the `unpinned-level` control overwrites the plain one).
- The three parity gates take an `RNG_WORD` / `RNG_UNTIL` probe knob (FREEZE refuses it); `tests/audit_rng_forms.sh`
  re-measures what the `0000` pin hides (#183, kept as the basis).
- `tools/facing_hook_ab.py` splits a hook into its cycles, its logic and its placement from the build's own patch;
  a side move of a fix is attributed by that split, never by one candidate for all.
- `tools/homes_tracked.py`'s second positional is an OUTPUT file: pass the state file with `--state`.
- A variant is compared against a control of the same script on the same build, never against a frozen table.
- The close packet's checks are rebuilt at every close: start the next one from `build/agent186/close/checks.tsv`
  and its four scripts (gotcha "THE CLOSE PACKET'S CHECKS ARE REBUILT AT EVERY CLOSE"); a reader may grep a
  large artifact instead of reading it, so hand it the window the claim rests on (`docs/project/rule_checker.md`).

## WHAT CLOSED THIS SITTING (14z-186)

**#184** `done` (all 31 seqs answered, the ten measurable gated by `tests/audit_chains184.sh`), **#186** `done`
(#159's side moves: the mash by the hook's execution, the arcade replay by its rule-5 logic), **#183** `done`
(the `0000` pin kept), **#193** `done` (the white HP compared). Opened: #191, #192, #193 (closed), #194.
