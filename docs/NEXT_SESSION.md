# NEXT SESSION — orientation (rewritten at the 14z-175 CLOSE, 2026-09-23)

> Rewritten at every session close ([VSP-17]). ROLLOVER: the previous opener
> moves VERBATIM to the top of `NEXT_SESSION_HISTORY.md` — this file holds ONLY
> the live orientation. Session state, not knowledge: facts belong in the docs,
> status in STATE.md.

## THIS SESSION RUNS UNDER A HOOK. A Bash call that detaches a job is REFUSED

`.claude/settings.json` (tracked) runs `tools/agent/hooks/pre_bash.py` before every Bash
call. `nohup`, `setsid`, `disown`, a backgrounding `&` with no later `wait`, or a loop on
`pgrep` is **denied with a reason** — relaunch the job with the Bash tool's
`run_in_background: true` in the FOREGROUND form (no nohup, no trailing `&`); the harness
tracks it and its completion wakes you. That is the point: 14z-174 lost hours to twelve
`nohup` launches no notification could ever report (`docs/project/agent_architecture_scope.md`).
**The settings, `tools/agent/hooks/**` and `tools/agent/agentlib.py` are edit-locked**
(`permissions.deny`): only the maintainer changes the enforcement. A write through Bash
is not blocked by the lock — do not use that gap; propose the change as a file under
`build/` with its proof, and ask (14z-175 did exactly that for the classifier fix).

The tree is still at `build/m3b_merged27` (merged-m19, released); no ROM byte moved.

## START HERE

1. **#172 — FINISH IT (the maintainer: *"best finish #172 first"*).** Ruled: *"S1 alone
   first"* — this sitting is the FIRST that runs under S1 from its first command, so
   measure it as you go: `python3 tools/agent/transcript_gaps.py --refusals <session>`
   lists every C0.1 refusal (a false positive is a finding: add it to
   `tests/agent/c01_commands.jsonl` as must-allow, fix through the maintainer),
   `--tasks <session>` every tracked job. Then, in the scope doc's order (§5):
   **S2** the close-time process sweep (C0.3 — the 35-hour Chrome and the 17-day
   `tail -F` are its ground truth), **S3** the procedural model checker C1 (its
   checklist now carries C0.2's two questions — said-vs-done and every job accounted
   for; fixtures from the 14z-174 transcript; calibrated like `rulecheck`; bound to
   `git push` by a hook — ruled *"Every push + every close"*), **S4** worker
   definitions, **S5** the orchestrator (Fable 5.1 at `high` per the ticket — reachable,
   `probe_hooks.sh` P5). **Every change to a locked file is the maintainer's to apply.**
   Rulings: `DECISIONS_HISTORY.md` "Ruled 2026-09-23 (14z-175)" (two entries).
2. **#171 — qualify every gate.** Unchanged from 14z-174: `tools/audit_lane_carry.py`'s
   subject lists are hardcoded and known incomplete, so a `MAY CARRY` from it is
   NECESSARY, NOT SUFFICIENT; widening them and the control that reconciles them
   against the registry is part of the ticket.
3. **#145 Windows binaries**, **no Windows launcher**, **#170**, **#161**, **#169**,
   **#157 / #159 / #163** — unchanged, the maintainer's to schedule.

## TRAPS PAID THIS SITTING (14z-175)

1. **A pattern classifier over shell text needs a must-stay-quiet corpus cut from REAL
   commands.** Three census cuts in one sitting, each wrong in a way its output hid
   (`&&`, heredoc bodies, multi-line quotes, `& … wait`); the real-data diff over 4,624
   commands found what thinking did not (`docs/project/gotchas.md`).
2. **A stripper that fails by removing too much hides exactly what the classifier looks
   for.** The heredoc stripper swallowed every line after an unterminated `<<` — a
   `nohup` below `<<<word` passed, and a quoted program lost its closing quote so a
   quoted `&` was refused. Fail toward keeping text.
3. **Never grep a transcript** — it embeds the system prompt, which names the markers.
   Parse records by type; a completion notification has TWO forms (a user message when
   idle, a `queued_command` attachment mid-turn).
4. **The rule-checker was right four runs out of four about my own figures** (97-100):
   counters, an unmeasured "short", a probe that proved the report and not the effect,
   and a live defect. Promoting inline counts into tools found a fifth (a wrong split in
   my own commit message, corrected in STATE 14z-175 row (8)).
5. **A recipe's boundary marker goes stale; the assertion does not.** STATE has no `---`
   above `# STANDING SECTIONS` any more — the rollover slice ends at that heading.

**IF A DOC IS TOUCHED:** the doc gates (`test_checkdocs`, `test_docshape`,
`test_doc_anchor_census`, `test_checkskills`, `test_gotchas_index_current`,
`test_gate_index_current`, `test_state_open_lists`, `test_tickets`) plus
`tools/check_state_lists.py` and `tools/tickets.py check`, exit statuses captured
directly, `${=cmd}` in zsh. **A running script is never edited** ([MSC-54]).
