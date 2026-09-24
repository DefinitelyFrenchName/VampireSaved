# NEXT SESSION — orientation (rewritten at the 14z-179 CLOSE, 2026-09-24)

> Rewritten at every session close ([VSP-17]). ROLLOVER: the previous opener
> moves VERBATIM to the top of `NEXT_SESSION_HISTORY.md` — this file holds ONLY
> the live orientation. Session state, not knowledge: facts belong in the docs,
> status in STATE.md.

## #172 IS CLOSED — WHAT NOW BINDS EVERY SITTING

The agent architecture is complete. Its last gate, the 14z-179 close, read green on every item of the
ruling's list — hook refusals 0, six workers all Opus-class with no fallback, the orchestrator on Fable 5.1 at
`high` over its whole transcript, tier green, sweep clean, procedure check resolved — and #172 was closed on
*"Close it on green"* (STATE 14z-179).
What binds you, all of it standing: **three hooks** — `pre_bash.py` (no detached jobs), `pre_push.py`
(a push needs a passed or resolved `procedure` run in the range), `pre_agent.py` (a `model` above
Opus-class, a `model` on a DEFINED worker, or none on a type that would inherit yours is refused) —
and **the close's steps in STATE.md's header**: the checklist, the tier with every control executed,
the sweep, the procedure check (`extract.py`, then a `procedure` run), and — ruled 14z-179, *"Standing step"* —
the worker cap read, `python3 tools/agent/transcript_gaps.py --subagents <session> --cap` (exit 0). **The rule-checker's
readers are the pinned `rule-checker` definition** (claude-opus-5-5, `high`, Read/Grep/Glob,
`omitClaudeMd: true`), spawned with NO model, then `python3 tools/rulecheck.py record <id> --session
<prefix>`, which spawn-checks every reader from its own transcript and refuses a run whose readers fail.

## START HERE

0. **AT THE OPENER, RUN `python3 tools/agent/sweep.py`**, not a `ps` grep.
0b. **CARRIED FROM 14z-179:** its procedure check (run `2026-09-24-140`) stopped at the check itself, so the
   span after it — the results written, the #172 close, the commit and the push — was never read by C1: cut
   `extract.py --session 8037cb8c --from 721` and put it through this close's procedure check too.
1. **#171 — qualify every gate.** Unchanged: `tools/audit_lane_carry.py`'s subject lists are
   hardcoded and known incomplete, so its `MAY CARRY` is NECESSARY, NOT SUFFICIENT.
2. **#145 Windows binaries**, **no Windows launcher**, **#170**, **#161**, **#169**,
   **#157 / #159 / #163** — unchanged, the maintainer's to schedule.

## TRAPS PAID THIS SITTING (14z-179)

1. **A mid-sitting read is a SNAPSHOT, not "every record".** A claim about the whole session (its
   model, its refusals) made from a read taken partway through is an inference; read again at the
   close, over the whole transcript, and say when each read was taken.
2. **The ledger has TWO line forms** (`- Session KEY — …` and `- **KEY** (date) — …`), and a
   pattern copied from the gate matched only one: a "missing line" finding was a matcher artifact,
   and the gate itself had never checked the four lines in the second form. Fixed with a control.
3. **`tail -N` of a control mode's output shows whichever control printed LAST**, not the mode you
   ran: a log labelled "the old mode" carried the new control's line. Keep a mode's full output;
   its exit status is the verdict.
4. **A rule you can state is not a rule anyone ruled.** "The gate's ruled rule is key resolution"
   was how the check was written, not a ruling; the checker asked for the quote and there was none.

**IF A DOC IS TOUCHED:** the doc gates (`test_checkdocs`, `test_docshape`,
`test_doc_anchor_census`, `test_checkskills`, `test_gotchas_index_current`,
`test_gate_index_current`, `test_state_open_lists`, `test_tickets`) plus
`tools/check_state_lists.py` and `tools/tickets.py check`, exit statuses captured
directly, `${=cmd}` in zsh. **A running script is never edited** ([MSC-54]).
