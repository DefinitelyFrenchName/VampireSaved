# NEXT SESSION — orientation (rewritten at the 14z-177 CLOSE, 2026-09-23)

> Rewritten at every session close ([VSP-17]). ROLLOVER: the previous opener
> moves VERBATIM to the top of `NEXT_SESSION_HISTORY.md` — this file holds ONLY
> the live orientation. Session state, not knowledge: facts belong in the docs,
> status in STATE.md.

## THREE HOOKS NOW BIND YOU, AND THIS SESSION CAN SPAWN THE NEW WORKERS

`.claude/settings.json` (tracked, edit-locked) runs, before every tool call of its kind:
`pre_bash.py` (a detaching Bash call is refused), `pre_push.py` (a push of this repo needs a
passed or resolved `procedure` run covering a commit in the range) and, **since 14z-177,
`pre_agent.py` on every Agent call**: a `model` above Opus-class, a `model` on a DEFINED worker,
NO model on a type that would inherit yours (`general-purpose`, `Plan`, anything unknown —
`Explore` and forks excepted), or a worker spec missing a template heading is REFUSED with the
allowed form. **So a rule-checker reader is spawned `general-purpose` with `model: "opus"` —
as always — and a `measurer`/`reader` with NO model and a spec from `docs/project/worker_spec.md`.**
This session started after `.claude/agents/measurer.md` and `reader.md` existed, so it can spawn
them (the 14z-177 session could not: a session loads its agent list at START).

The close is unchanged since 14z-176: checklist, strict tier with every control, the sweep, the
procedure check, the push (STATE.md's header). The tree is still at `build/m3b_merged27`
(merged-m19, released); no ROM byte moved.

## START HERE

0. **AT THE OPENER, RUN `python3 tools/agent/sweep.py`**, not a `ps` grep.
1. **#172 S4 STEP 4 — the pinned rule-checker, ruled (`DECISIONS_HISTORY.md` "Ruled 2026-09-23
   (14z-177)", four entries):** a `.claude/agents/rule-checker.md` (`opus`, effort `high` — the
   value every Opus 5.5 calibration ran at — tools Read, Grep, Glob), spawned as a SUBAGENT
   (*"Subagents"*); **its FIRST act is to measure whether a reader sees `CLAUDE.md`** (the option the
   maintainer chose said so; their #172 ask gives the checker *"no project-specific context"*,
   and the 14z-175 ruling chose a checklist + transcript extract; unmeasured for both routes); then the procedure checklist
   gains QP3-for-workers and QP5 SPEC-CONFORMANCE (the return answers the TASK, the worker ran
   the COMMANDS named, did nothing forbidden), a planted QP5 fixture, and ONE recalibration of
   all eight fixtures plus the new one on the pinned definition. `agent_defs.py`'s `REQUIRED`
   and the call gate's cases then learn the new definition. **And a controlled probe leg for a
   BACKGROUND worker's report** (the `[Subagent hand-back]` form is known from one transcript read
   only — promised in rule-checker run `2026-09-23-112`'s resolution). Then **S5**, the orchestrator.
2. **#171 — qualify every gate.** Unchanged: `tools/audit_lane_carry.py`'s subject lists are
   hardcoded and known incomplete, so its `MAY CARRY` is NECESSARY, NOT SUFFICIENT.
3. **#145 Windows binaries**, **no Windows launcher**, **#170**, **#161**, **#169**,
   **#157 / #159 / #163** — unchanged, the maintainer's to schedule. (**#158** now has an
   effort half as well as its model half: `rule_checker.md` "The effort".)

## TRAPS PAID THIS SITTING (14z-177)

1. **A definition's cap is not a cap.** The Agent call's `model` beats it; an omitted model or
   effort follows the CALLER; a frontmatter `hooks:` block does not fire. `probe_agents.sh`
   A1-A12 re-measures all of it (`docs/platform/gotchas.md`).
2. **A "delivered" check that matches a token the spec itself contains passes vacuously** —
   the output token must be one the spec cannot supply, matched only in THAT call's result.
3. **A raw session transcript carries the user's identity** (e-mail, context) — never commit
   one; `tools/agent/cut_worker_fixture.py` cuts and refuses an address.
4. **`${=var}` is zsh; a `#!/bin/sh` script needs plain `$var`**, and `sh -n` does not catch it.
5. **A figure quoted in a proposal from an inline script is unproduced** — promote the script
   into the proof, or the rule-checker will (run 111 did).

**IF A DOC IS TOUCHED:** the doc gates (`test_checkdocs`, `test_docshape`,
`test_doc_anchor_census`, `test_checkskills`, `test_gotchas_index_current`,
`test_gate_index_current`, `test_state_open_lists`, `test_tickets`) plus
`tools/check_state_lists.py` and `tools/tickets.py check`, exit statuses captured
directly, `${=cmd}` in zsh. **A running script is never edited** ([MSC-54]).
