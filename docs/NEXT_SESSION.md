# NEXT SESSION — orientation (rewritten at the 14z-176 CLOSE, 2026-09-23)

> Rewritten at every session close ([VSP-17]). ROLLOVER: the previous opener
> moves VERBATIM to the top of `NEXT_SESSION_HISTORY.md` — this file holds ONLY
> the live orientation. Session state, not knowledge: facts belong in the docs,
> status in STATE.md.

## THE CLOSE HAS TWO NEW STEPS, AND A BASH CALL THAT DETACHES A JOB IS STILL REFUSED

`.claude/settings.json` (tracked) runs `tools/agent/hooks/pre_bash.py` before every Bash
call: `nohup`, `setsid`, `disown`, a backgrounding `&` with no later `wait`, or a loop on
`pgrep` is **denied with a reason** — relaunch with `run_in_background: true` in the
foreground form. **The settings, `tools/agent/hooks/**` and `tools/agent/agentlib.py` are
edit-locked; a COPY of a locked file is refused too (measured 14z-176) — propose a change as
a NEW file under `build/` with its proof, and ask.**

**The close (STATE.md's header) now also requires, after the tier and before the push:**
(1) the PROCESS SWEEP clean — `python3 tools/agent/sweep.py` exits 0, every survivor killed
leaves first or `--declare`d; (2) the PROCEDURE CHECK passed or resolved —
`python3 tools/agent/extract.py --session <id> --out build/agent172/extract_<id>.txt`, then a
`procedure` run of `tools/rulecheck.py` on that file (`docs/project/rule_checker.md` "THE
PROCEDURE FAMILY"), every VIOLATED question answered by `resolve`.

The tree is still at `build/m3b_merged27` (merged-m19, released); no ROM byte moved.

## START HERE

0. **AT THE OPENER, RUN `python3 tools/agent/sweep.py`, NOT A `ps` GREP** — twenty openers in a row
   reported "nothing running" beside an 18-day orphan, because a grep for `tail -F` cannot match
   `tail -n +1 -F`; this sitting's own procedure check caught the twentieth.
1. **WAITING ON THE MAINTAINER — two proven proposals under `build/agent172/`.** The first
   was put to them (*"it'll be in a while"*); the second was first put to them at the 14z-176
   close, with no answer recorded yet. (a) `apply_launchfix.py` — the `agentlib.tasks` phantom-task fix
   (`--prove`: 794 -> 791 tasks, removals only, 44 C0.1 verdicts unchanged; `--apply`). After
   it lands, make `tools/agent/extract.py` call `agentlib.tracked_launch` instead of its own
   copy, and re-run `tests/test_agent_extract.sh` and `tests/test_agent_hooks.sh`. (b)
   `proposal_pre_push/` — C1's push hook (`prove.py`, 14/14; `INSTALL.md`). After it lands,
   move `prove.py`'s cases into `tests/test_agent_hooks.sh` and add `pre_push.py` to its
   installed-wiring check; the close's procedure step then becomes a hook, not a promise.
2. **#172 — S4, the worker definitions** (scope doc §4 W, §5): named `.claude/agents/`
   definitions with model and effort capped as ruled (at most Opus-class, effort at most
   `xhigh`), a spec TEMPLATE, and C1 reading the SPEC against the RETURN; its gate is a worker
   run on a known task returning figures each traceable to a command. Then **S5**, the
   orchestrator. Rulings: `DECISIONS_HISTORY.md` "Ruled 2026-09-23" (14z-175 two, 14z-176 one).
3. **#171 — qualify every gate.** Unchanged: `tools/audit_lane_carry.py`'s subject lists are
   hardcoded and known incomplete, so its `MAY CARRY` is NECESSARY, NOT SUFFICIENT.
4. **#145 Windows binaries**, **no Windows launcher**, **#170**, **#161**, **#169**,
   **#157 / #159 / #163** — unchanged, the maintainer's to schedule.

## TRAPS PAID THIS SITTING (14z-176)

1. **A process's environment is unreadable for macOS's own binaries and for Chrome** — the
   session variable cannot find a leftover `tail`, `sleep`, `zsh` or browser; its working
   directory can (`docs/platform/gotchas.md`).
2. **`$!` after `cd x && cmd &` is the SUBSHELL** — killing it orphans `cmd`. Kill a tree
   leaves first; the sweep's hint does.
3. **A marker QUOTED in a tool result is not the event** — three tools read it as one this
   sitting (`--refusals`, `agentlib.tasks`, and my own phrase search). A real event is an
   ERROR result or a result that STARTS with the marker; build a search token by
   concatenation so the search cannot match itself.
4. **The transcript drops some mid-turn narration** (every end-of-turn report is kept). Put
   every promise and every claim in the report that ENDS the turn, or C1 cannot hold you to it.
5. **A fix applied to "the run" is applied to one call site** — the browser gate's control
   leg kept 14z-174's lie after its main leg was fixed.

**IF A DOC IS TOUCHED:** the doc gates (`test_checkdocs`, `test_docshape`,
`test_doc_anchor_census`, `test_checkskills`, `test_gotchas_index_current`,
`test_gate_index_current`, `test_state_open_lists`, `test_tickets`) plus
`tools/check_state_lists.py` and `tools/tickets.py check`, exit statuses captured
directly, `${=cmd}` in zsh. **A running script is never edited** ([MSC-54]).
