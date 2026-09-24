# NEXT SESSION — orientation (rewritten at the 14z-178 CLOSE, 2026-09-24)

> Rewritten at every session close ([VSP-17]). ROLLOVER: the previous opener
> moves VERBATIM to the top of `NEXT_SESSION_HISTORY.md` — this file holds ONLY
> the live orientation. Session state, not knowledge: facts belong in the docs,
> status in STATE.md.

## #172 S4 IS DONE; S5 IS THIS KIND OF SITTING — A PLAIN SESSION ON FABLE 5.1

Ruled 14z-178 (*"Plain session"*, *"That gate"*): the orchestrator is NOT a definition — under
`claude --agent` Claude Code's default system prompt is replaced by the definition's body (probe
A16) — but a plain session the maintainer STARTS on Fable 5.1 (`claude --model claude-fable-5-1`,
or the settings `model` key); its effort comes from the per-model settings (`high`, probe A17). Its
gate is that sitting's close: the C0/C1 record, and **`python3 tools/agent/transcript_gaps.py
--subagents <session> --cap`** — every worker at most Opus-class, none fallen back. If this sitting
is not on Fable, S5's gate is still open; say so at the opener.

**Three hooks and the pinned reader bind you.** `pre_bash.py` (no detached jobs), `pre_push.py` (a push
needs a passed or resolved `procedure` run in the range) and `pre_agent.py` (a `model` above
Opus-class, a `model` on a DEFINED worker, or none on a type that would inherit yours is refused).
**The rule-checker's readers are the pinned `rule-checker` definition** (claude-opus-5-5, `high`,
Read/Grep/Glob, `omitClaudeMd: true`), spawned with NO model; then
**`python3 tools/rulecheck.py record <id> --session <prefix>`** — it spawn-checks every reader from
its own transcript (model, effort, fallback, context, prompt verbatim) and collects the verdicts;
it refuses a run whose readers fail. `--a/--b` files are for pre-pinning runs only.

## START HERE

0. **AT THE OPENER, RUN `python3 tools/agent/sweep.py`**, not a `ps` grep.
1. **#172 S5's gate** — this sitting, if it runs on Fable 5.1: work as usual, and at the close add
   `transcript_gaps.py --subagents <session> --cap` to the checklist.
2. **#171 — qualify every gate.** Unchanged: `tools/audit_lane_carry.py`'s subject lists are
   hardcoded and known incomplete, so its `MAY CARRY` is NECESSARY, NOT SUFFICIENT.
3. **#145 Windows binaries**, **no Windows launcher**, **#170**, **#161**, **#169**,
   **#157 / #159 / #163** — unchanged, the maintainer's to schedule.

## TRAPS PAID THIS SITTING (14z-178)

1. **A subagent is handed CLAUDE.md and (interactively) the memory index** — the docs deny the
   second. `omitClaudeMd: true` removes both. Read the `instructions` attachment's `files`
   list; a text match over the record missed every one.
2. **A worker can finish on another model**: a safety-classifier stop triggers a silent
   FALLBACK, recorded only as a `fallback` content block. Read the model REQUESTED.
3. **Transcripts older than 30 days are deleted** (and a probe's `claude -p` runs can trigger it
   mid-sitting): date every census figure; cut evidence into the tree before it ages out.
4. **`claude --agent` replaces Claude Code's default system prompt**; `--append-system-prompt` adds.
5. **A headless worker's report arrives as its notification's `<result>`** — the third form.
6. **A discriminator must be something the model cannot get elsewhere**: "the first sentence of
   your system prompt" and "the working directory" both failed before the IMPORTANT line worked.
7. **A rule glossed in a ruling's "What it means" is not the maintainer's words** — quote theirs.

**IF A DOC IS TOUCHED:** the doc gates (`test_checkdocs`, `test_docshape`,
`test_doc_anchor_census`, `test_checkskills`, `test_gotchas_index_current`,
`test_gate_index_current`, `test_state_open_lists`, `test_tickets`) plus
`tools/check_state_lists.py` and `tools/tickets.py check`, exit statuses captured
directly, `${=cmd}` in zsh. **A running script is never edited** ([MSC-54]).
