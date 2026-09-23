# THE AGENT ARCHITECTURE — scope, before the work (GitHub #172)

> **STATUS (14z-175, 2026-09-23): RULED; SLICE S1 INSTALLED.** The maintainer ruled
> all four questions of §6 the same day (`DECISIONS_HISTORY.md` "Ruled 2026-09-23
> (14z-175) — #172"), adding one constraint that binds every slice: **a block stops
> the task at fault, never the session.** S1 is live as **C0.1** in the tracked
> `.claude/settings.json`, with **C0.4**'s edit lock on it; **C0.2 moved to C1** on
> measurement (§4, and the ruling "— #172 slice S1"). **S2 LANDED 14z-176:** C0.3 is
> `tools/agent/sweep.py`, gated by `tests/test_agent_sweep.sh`, and it is a step of the
> close (STATE.md's header); on its first live run it found an 18-day orphan of the
> 14z-133 session that the by-hand check for #172 had missed (§4). **S3 LANDED 14z-176
> (ruled *"Build it as described"*):** C1 is the rule-checker's `procedure` family —
> `tools/agent/extract.py`, the QP1-QP4 checklist in `docs/project/rule_checker.md`, four
> fixtures calibrated on Opus 5.5 (runs `2026-09-23-101..104`); its push binding is a PROVEN
> PROPOSAL awaiting the maintainer (`build/agent172/proposal_pre_push/`), so until then the close
> carries the step. Next: S4 (worker definitions).

**Why this document exists:** the same reason `harness_scope.md` and
`applier_app_scope.md` do — a direction the maintainer ordered, big enough that
starting it blind would waste a sitting, with open design questions that are the
maintainer's to rule. The ticket is the story (#172, [VSP-182]); this is the plan.

**The ask (maintainer, 2026-09-22), verbatim from #172:**

> *"the worrying part is not that you have not polled you own background work, it's
> that you explicitly chose earlier to poll to avoid waiting forever for tasks you
> would never see finish either because they finished too fast or because of how they
> reported. Polling is likely the good option. The problem is actually doing it."*

> * **orchestrator: fable 5.1 agent**, free to choose how best to work **BUT cannot
>   go against the will of checker agents**
> * **checker: one or more opus agents** (could be lowered to sonnet if no adverse
>   effects), **only knows the rules and ways of working, no project-specific context
>   to have no bias there**: only purpose is to check if the discipline is applied
>   (e.g. are the values measured, not inferred by the workers? is the orchestrator
>   applying the procedures it should?)
> * **workers: specialized, driven by very precise specifications and directives
>   given by the orchestrator.** There should be as few or many as deemed adequate by
>   the orchestrator at any given moment. By default they should be limited to a
>   small context (and they should be at most opus-class or maybe even sonnet if
>   context is small and specs clear and precise)
> * **max acceptable effort for fable is high, for Opus and Sonnet is xHigh**

## 1. THE FAILURE, MEASURED FROM THE TRANSCRIPTS

Every session's transcript is on disk (`~/.claude/projects/<project>/<session>.jsonl`).
`tools/agent/transcript_gaps.py` (re-derives this table; `--selftest`; `--detail <id>`
lists one session's gaps) reads the last eleven sessions before this one, counting
every gap of 20 minutes or more that began after the agent's own turn, and
classifying what ended it. A "status" ender is a message of at most 80 characters
matching a status keyword: a first cut without the length bound counted three long
messages as status questions — one of them #172's own origin message — and every
message the bound reclassified was read and confirmed not a status question.

| session | start (UTC) | gaps ≥ 20 min | ended by "what's the status" | ended by a notification | other | detached launches | harness-tracked tasks |
|---|---|---|---|---|---|---|---|
| 4404c66f | 09-17 15:31 | 0 | 0 | 0 | 0 | 16 | 0 |
| b402dba6 | 09-17 19:10 | 1 | 0 | 0 | 1 | 0 | 2 |
| 35f352b6 | 09-17 20:55 | 3 | 0 | 1 | 2 | 9 | 12 |
| 21b7a712 | 09-18 06:29 | 2 | 0 | 2 | 0 | 0 | 6 |
| 82693a92 | 09-18 10:21 | 4 | 0 | 1 | 3 | 10 | 8 |
| 92e58f46 | 09-18 17:37 | 2 | 0 | 0 | 2 | 9 | 0 |
| b0c1cbc9 | 09-18 22:34 | 6 | 0 | 3 | 3 | 23 | 10 |
| 4724b8d7 | 09-19 22:51 | 5 | 2 | 0 | 3 | 13 | 11 |
| 5b2495dc | 09-20 12:30 | 2 | 0 | 0 | 2 | 5 | 6 |
| 5d6dd31f | 09-20 16:28 | 4 | 0 | 2 | 2 | 0 | 36 |
| **d5b070d5 (14z-174)** | 09-21 08:37 | **17** | **11** | **1** | 5 | **12** | **5** |

"Detached" is a Bash call (not `run_in_background`) whose command carries `nohup`,
`setsid`, `disown` or a single command-ending `&` — not half of `&&`, not a `>&`
redirect. "Tracked" is a task the harness reports running in the background: a
`run_in_background` launch, or a call it moved there at the 120 s timeout. **The
14z-174 gaps that the maintainer's status question ended total 1,623 minutes.
That is an UPPER BOUND on waste, not the waste:** part of each gap was a job
genuinely still running. The maintainer's own figure for the finished-and-idle
part is 2.5 h, 1.5 h and 1.5 h (#172).

**CORRECTED BEFORE THE MAINTAINER SAW IT (rule-checker run `2026-09-23-97`, Q1 and
Q4, both true).** The first cut of this table read 14z-174 as **97 detached, 0
tracked**. Both figures were wrong: the detach pattern also matched `cmd && echo …`
(85 of the 97), and the tracked count read only `run_in_background`, missing the five
calls the harness moved to the background at the 120 s timeout. The table above is
the re-measure; `transcript_gaps.py --selftest` now carries a must-stay-quiet case
for each defect. **Re-measured again when S1 began** — the census now counts through
the SAME classifier the hooks use (`tools/agent/agentlib.py`), which also clears a
backgrounding `&` inside a heredoc body or a quoted string and one followed by `wait`
(a foreground parallel run). Over the 4,624 Bash commands of the eleven sessions it
flags nothing the census's PREVIOUS pattern (the one written after run `2026-09-23-97`)
did not, and every one of the 59 it clears has a reason — heredoc body 30, `& … wait`
28, quoted 1 (`transcript_gaps.py --classifier-audit`, which exits non-zero on any
command only the new classifier flags or any clearance it cannot explain). A first,
inline count of the same comparison reported the split as 30 / 25 / `&&` 3 / 1 and
called the baseline "the first classifier"; both were corrected when the count was
promoted into the tool (the three were `& … wait` runs that also contained `&&`).
14z-174's row does not move; the other sessions' detached counts fall.

**The mechanism the table points at.** A job launched with `nohup … &` inside an
ordinary Bash call is invisible to the harness: it cannot produce a completion
notification, so once the agent ends its turn, the only things that can end the
wait are the agent's own poll, which it cannot make while idle, and the
maintainer. **In 14z-174 all twelve detached launches were `nohup` launches of the
jobs the sitting's own record describes as long** — the static tier twice, the release emulator tier twice, the close tier
three times, a control measurement, the rig attribution, the re-freeze diff capture,
the re-freeze and the release upload (2 + 2 + 3 + 5 = 12), read one by one from the
transcript (`transcript_gaps.py --detached d5b070d5`). Their DURATIONS are not measured
here — a detached job leaves no end record in the transcript; the 14z-174 record gives the
release emulator tier's as 6 h 24 min (STATE_HISTORY/STATE 14z-174, row (11)). Its five TRACKED tasks, each timed from its move to the background to its
completion notification (`transcript_gaps.py --tasks d5b070d5`, which reads both
notification forms — §2): two ended within a minute; two ran 45 and
39 minutes and were WAITER LOOPS (`for i …; do ps -p <pid> … sleep 55; done`, the
commands `--tasks` prints) around a detached job — and the one 14z-174 gap
a notification ended is the first of them, so where a long detached job WAS wrapped in
a tracked waiter, the agent was woken; the fifth was the netlog Chrome of #172's
comment, whose task ended 2,113 minutes (35 h) after it was moved. Across the eleven
sessions the correlation is weaker than that one session: several sessions detached
many launches and were rarely chased for status. So what is measured is that **every
long job the costliest session launched for its result was detached, and the harness
saw one only where the agent wrapped a tracked waiter around it**; that the invisibility
CAUSED the gaps is not tested, and §5's slice S1 replay is where it is.

**The second shape (#172's comment):** two processes survived their sessions — a
headless Chrome for 1 d 11 h and a `tail -F` orphaned for 17 days. In both cases
the agent checked the OUTPUT it wanted and never the PROCESS it had started.

## 2. WHAT THE PLATFORM OFFERS — MEASURED WHERE IT MATTERS

The design rests on these rows. "Measured" means a probe in a scratch project
(`claude -p`, Claude Code 2.1.280, 2026-09-23), not the documentation;
`tools/agent/probe_hooks.sh` re-measures every MEASURED row in about a minute (P1-P3
the mechanisms, P5 the models when `PROBE_MODELS` names them, P6 the prompt embedding
itself), with two controls — P1c,
the deny switched off, must create the marker P1 requires absent, and P4, the P1/P2
record counts must read zero on a run with no denial and no block — and exits non-zero
if any has changed.

| mechanism | status | what it gives |
|---|---|---|
| **PreToolUse hook denies a Bash call with a reason** | **MEASURED** (P1, P1c) | the agent received `PreToolUse:Bash hook error: <reason>` as the tool result, and the denied command NEVER RAN: the marker file it would have created is absent, while the same prompt with the deny switched off creates it (P1c, the must-fire leg) |
| **Stop hook blocks the end of a turn** | **MEASURED** | `{"decision":"block","reason":…}` → the transcript records `Stop hook feedback: <reason>` and the agent continues; the next Stop arrives with `stop_hook_active: true` (the loop guard) |
| **the transcript records every background task** | **MEASURED** | a tracked launch's result reads `Command running in background with ID: <id>. Output is being written to: <path>`; a 120 s timeout reads `moved to the background (ID: <id>)`; completion is a `<task-notification>` with `<status>` — **in TWO forms**: a user message when it arrives while the agent is idle, and a `queued_command` ATTACHMENT (with `queue-operation` records) when it arrives mid-turn. A first reading that parsed only the first form reported three of 14z-174's five tracked tasks as never notified; all five were (rule-checker run `2026-09-23-98`). C0.2 parses both |
| **a headless run exits with a tracked task still running** | **MEASURED** (P3b) | the probe agent said *"I'll wait for the completion notification"* and the session ended about 6 s in (5,939 ms on the recorded run) with its 20 s task still running and no notification received. Interactively the notification wakes the agent; headless, nothing does |
| **a transcript embeds the system prompt** | **MEASURED** | a `grep` for `task-notification` over a transcript MATCHES in a run that received none — the prompt snapshot the transcript records mentions the tag. The probe script's first version failed on exactly this, and P6 now shows it directly (a bare grep matches a run with no notification). **Every C0 check parses records by type; none greps a transcript** |
| `--agent <name>` runs the MAIN session as a defined agent | CLI help (`claude --help`, 2.1.280) | the orchestrator can be a definition carrying its own model, effort and prompt. (The documentation summary this session obtained said no such flag exists; the binary says otherwise, which is why the row is sourced from the binary.) |
| subagent definitions `.claude/agents/<name>.md` with `model`, `effort`, `tools`, `disallowedTools`, `hooks` | documented | workers and checkers as named, capped definitions; a hook scoped to one agent |
| `type: "prompt"` / `type: "agent"` hooks (a model judges the event) | documented; agent hooks EXPERIMENTAL, default model Haiku, 30/60 s default timeouts | a model checker at Stop without the orchestrator's cooperation — see §4, C1 |
| permissions `deny` on `Edit`/`Write` of `.claude/settings.json` | documented | the enforcement cannot be edited away by the agent it binds |
| an event when a background Bash task finishes | **documented as ABSENT** — NOT exercised | so the Stop hook must reconstruct task state from the transcript. C0.2 rests on this row; if an event exists after all, C0.2 gets simpler, not wrong |
| **a tool call's shell is a SESSION LEADER and a direct child of the Claude process** | **MEASURED** 2026-09-23 (14z-176) | every Bash call, foreground or tracked, runs in `/bin/zsh -c source ~/.claude/shell-snapshots/…` with `sid == pid` and `ppid == $CLAUDE_PID`; Claude Code's own `caffeinate` is a child but NOT a leader. So "under a leader child of Claude" is what a tool call started, and C0.3's ATTACHED half needs no transcript to find it |
| **a tracked task's output file names its session and task** | **MEASURED** (14z-176) | the task shell's stdout is `<scratch>/<session-uuid>/tasks/<id>.output` (`lsof -d 1`), so a live process is labelled with its task id — and an orphan still writing there with its session |
| **an orphan keeps its working directory, not its lineage** | **MEASURED** (14z-176) | a job whose tool shell exits is reparented to launchd (`ppid 1`); its session id is the DEAD tool shell's pid, so neither parent nor session ties it back to Claude. Its cwd and streams do (`lsof -d cwd,0,1,2`) |
| **the environment (`CLAUDE_CODE_SESSION_ID`) is readable only for some binaries** | **MEASURED** (14z-176) | inherited by every tool-call process, and readable (`ps -E`) for a CLT Python and Homebrew's `ugrep` — but NOT for Apple platform binaries (`tail`, `sleep`, `zsh`: `KERN_PROCARGS2` returns 38 bytes of arguments) nor for Google Chrome (hardened). Both ground-truth leftovers are those shapes, so C0.3 cannot rest on it (`docs/platform/gotchas.md`) |
| Fable 5.1, Opus 5.5, Sonnet 5 reachable on this account | **MEASURED** 2026-09-23 (P5) | each answered a one-line probe as itself (`modelUsage` names the model); the 2026-09-18 spend-limit failure on Fable 5.1 is not current |

## 3. WHAT EXISTS AND WHAT IT DOES NOT COVER

`tools/rulecheck.py` ([VSP-183], [VSP-184]) is already the CHECKER tier for
EVIDENCE: fresh agents, artifacts only, five fixed questions, a planted known
violation every run, a VIOLATED verdict that stops the action until each question is
answered in writing. Recalibrated on Opus 5.5 this sitting (ledger runs
`2026-09-23-93..96`). Its own spec names the gap: *"Operational slips. A waiter
wedged for hours is not a rule-application failure; it was not looking. The checker
does not fix that."* Nothing checks PROCEDURE — whether the agent did what it said
it would, and what the rules require of the working method itself.

## 4. THE RECOMMENDATION — BIND WHAT CAN BE BOUND MECHANICALLY, JUDGE THE REST

**The principle: a check that needs no judgement should not be given to a model.**
The costliest failures in §1 are mechanically detectable from the transcript and
the process table; a hook that detects them cannot be argued with, forgotten, or
talked round, which is the strongest available reading of *"cannot go against the
will of checker agents"*. A model checker is kept for what needs judgement.

### C0 — the deterministic checker (hooks; no model)

- **C0.1 no invisible jobs (PreToolUse, Bash).** Deny a command that detaches
  (`nohup`, `setsid`, `disown`, a trailing `&`) or waits on a process-table query
  (`until … pgrep`, `while pgrep` — the self-matching waiter,
  `never-wait-on-pgrep`), with the reason naming the tracked alternative:
  `run_in_background: true`, which notifies, or `Monitor` for a condition. A job the
  harness tracks is a job whose end wakes the agent.
- **C0.2 — MEASURED BEFORE BUILDING, AND NEITHER DETERMINISTIC FORM SURVIVED (14z-175,
  slice S1).** Both were run over the eleven archived transcripts with the S1 parser
  (`agentlib.tasks`, both notification forms) before any hook was written; the
  figures below re-derive with `transcript_gaps.py --c02`.
  *"A finished task whose result no later tool call looked at"* flagged 26 tasks in one
  session, and every case read by hand was a result the agent HAD used — acted on from
  the notification, polled from its log before the notification, or read through a
  `$VAR` path no matcher resolves. *"A promise to wait or report with no tracked task
  running"* failed the other way: in 14z-174 the netlog Chrome's task stayed "running"
  for 35 hours and masked nearly every promise the session made while its detached jobs
  ran. Whether a running thing is RELEVANT to a promise is judgement, so under this
  document's own principle C0.2 is carried by the procedural checker (C1, QP1 and QP4),
  pending the maintainer's word. The original design, kept for the record:
  **C0.2 no finished job left unread (Stop).** At every Stop, reconstruct the
  session's tasks from the transcript. A task whose completion notification arrived
  and whose output has not been read since → BLOCK, naming the task and its output
  file. A task still running → allowed, because a tracked task will notify (C0.1 is
  what makes that true).
- **C0.3 no process outlives its purpose (the close).** A sweep tool lists every
  process the session started that is still alive (tracked task ids from the
  transcript, plus a process-table scan for the project's own tools), and the close
  checklist requires the list to be empty or each survivor declared in writing. The
  Chrome case of #172 is the ground truth.
  **AS BUILT (14z-176, slice S2): `tools/agent/sweep.py`**, in two halves because §2's
  measurements say one cannot see both. **ATTACHED** — every subtree under a
  session-leader child of `$CLAUDE_PID` except the sweep's own tool shell, labelled with
  its task id from the output file. **ORPHAN** — every process of this user reparented to
  launchd/init that points into the project: its cwd, a standard stream or its command
  line names a project root (the repo, the session scratchpad, `~/.cache/vampire-saved`,
  `/tmp/vampire-saved-*`), or it is an orphaned Claude tool shell (`.claude/shell-snapshots/`
  on its command line), or its readable environment carries the swept session id.
  Orphans are listed WHATEVER session left them: nothing tracks an orphan, so the close
  that sees it owns it. The transcript supplies OPEN TASK lines (a tracked task with no
  completion notification yet) as a cross-check, never the verdict. The instrument must
  see ITSELF (its own pid and cwd) before it may print CLEAN, and a declaration
  (`--declare PID "REASON"`, `build/agent_hooks/declared.tsv`) is keyed on pid AND start
  time, so a reused pid inherits nothing. The kill hint lists each subtree LEAVES FIRST,
  because killing a parent reparents its child — paid for this sitting (§7).
  **FIRST LIVE RUN (2026-09-23): TWO SURVIVORS, both real** — `tail -n +1 -F
  build/emu_sweep_14z133/results.tsv | ugrep …`, started 2026-09-04 23:01, alive
  **18 days 15 h**, left by session `b4735532` (14z-133) — a SECOND pipeline beside the
  `emu_sweep_14z133b` one #172's comment reported. The by-hand check that produced that
  comment missed it; the cwd rule found the `tail` half (whose environment is hidden)
  and the environment named the `ugrep` half's session. Killed after the evidence was
  kept (`build/agent172/sweep_first_live_14z176.txt`). The measurement taken BEFORE the
  tool was written — the cwd rule alone over the user's 283 launchd children, 198 of them
  at cwd `/` — matched exactly three: this pipeline's two processes and a `tail` this
  sitting's own probe had leaked a minute earlier (`docs/platform/gotchas.md`, the `$!`
  entry), killed before the tool's first run. No false positive among the other 280.
- **C0.4 the enforcement protects itself.** `permissions.deny` on editing
  `.claude/settings.json` and the hook scripts; only the maintainer changes them.

### C1 — the procedural checker (a model, context-free, alongside `rulecheck`)

`rulecheck` asks whether a CLAIM is supported. C1 asks whether the PROCEDURE was
followed. It reads the rules and the session's own record, never the project's
history:

- **Input:** a generic ways-of-working checklist (distilled from the project-agnostic
  `bbx` skill and this document — not CLAUDE.md, which is project-specific) plus an
  EXTRACT of the session transcript produced by a tool: the agent's statements of
  intent, the tool calls, the task events, the reports made to the maintainer.
- **Questions (draft; each written from a paid failure):** QP1 SAID-VS-DONE — every
  intent the agent stated ("I'll poll", "I'll report when", "I'll carry forward") has
  a later action that discharges it (14z-174: polling chosen and not done; "I'd
  carry it forward" not written down, `b5b1f1c9`). QP2 CLAIMED-VS-RUN — every ritual
  step the agent reports done has a tool call that did it (14z-174: `6e01c5f4`, *"the
  ritual check found TWO steps I had claimed and not done"*). QP3 PRODUCED-NOT-INFERRED
  — every number reported to the maintainer appears in a tool output in the extract.
  QP4 ACCOUNTED — every background job has a disposition.
- **Binding:** the same as `rulecheck` — fixed six-line answers, a planted known
  violation each run (fixtures cut from the 14z-174 transcript, which holds real
  instances of all four), VIOLATED stops the action until resolved in writing. The
  mechanical binding is a PreToolUse hook on `git push`: the push is denied unless the
  ledger holds an OK procedural run for the commits being pushed — the way
  `test_rule_checker.sh` binds a freeze.

### O — the orchestrator

The main session as `--agent orchestrator` (or the `agent` setting): the model the
maintainer names (Fable 5.1 per #172) at effort `high`, carrying the C0 hooks.
Changing the orchestrator's model does not touch the checker's calibration — that is
bound to the CHECKER's model, per the standing ruling "a change of model is a
recalibration".

### W — the workers

Named definitions under `.claude/agents/` with model and effort capped as ruled
(at most Opus-class, effort at most `xhigh`), each with a narrow toolset and, where
it fits, a scoped hook (a measuring worker may not edit tracked files). A spec
TEMPLATE the orchestrator fills: inputs, the exact commands, the return format
(raw figures WITH the command that produced each), and what the worker must NOT
infer. The blind-spot question in #172 — what stops the orchestrator's framing
propagating into every worker — is answered by C1 reading the SPEC against the
RETURN, not by a second orchestrator.

## 5. THE SLICES — each landed only with its gate

| slice | what | the gate that proves it |
|---|---|---|
| **S1** | C0.1 (+ C0.2, moved to C1 on measurement — §4) as scripts under `tools/agent/` + the project `.claude/settings.json` wiring + C0.4. **C0.1 LANDED 14z-175:** `tools/agent/agentlib.py` (the one classifier, also behind the census), `tools/agent/hooks/pre_bash.py`, gate `tests/test_agent_hooks.sh`; wiring verified in a scratch project, then INSTALLED here (ruled "Install + protect"): a live `nohup` launch denied, its marker never created, an Edit of the settings refused | `tests/test_agent_hooks.sh` (ci_portable): the hook over `tests/agent/c01_commands.jsonl` — 44 rows cut from real transcripts and synthetic edge cases: 14z-174's twelve launches and the over-strip cases must be DENIED, the real look-alikes and this sitting's live false positive ALLOWED — plus the fail-open path, the installed wiring, and three controls (`blind-classifier`, `greedy-heredoc`, `no-heredoc-strip`). (The plan said this gate would replay C0.2 too; C0.2 moved to C1, so it replays C0.1 only.) **The close's rule-checker run `2026-09-23-100` found the stripper over-matched** — `<<<word` and `1<<3` read as heredoc operators, and an unterminated one swallowed every later line, hiding a real `nohup` below it and, live in this sitting, un-closing a quoted program so its `&` was refused. The fix (terminated heredocs only, a tag that starts with a letter, no third `<`) changes no verdict on the 4,624 archived commands and is applied by the maintainer, the file being edit-locked |
| **S2** | C0.3 — the close sweep, and its step in STATE.md's close checklist. **LANDED 14z-176:** `tools/agent/sweep.py`, the close step before the push (STATE.md's header) | `tests/test_agent_sweep.sh` (ci_portable, ~12 s): a planted world — a fake Claude with a tool shell that must be named ATTACHED with its child and a non-leader helper that must stay quiet; six orphans, one per signal (cwd twice, once as a `sh`+`tail` pair, argv, stream, env, Claude tool shell) that must each be named WITH that signal; a quiet orphan; the sweep's own shell. Then every survivor declared -> CLEAN, then every plant killed -> CLEAN with no survivor. Three controls (`blind-orphans`, `blind-cwd`, `blind-leaders`), each reaching FAIL as a mode |
| **S3** | C1 — `tools/proccheck.py` (or a `rulecheck` decision kind), the transcript extractor, the checklist, fixtures from 14z-174, calibration, the push binding. **LANDED 14z-176 as a `rulecheck` FAMILY** (`procedure`): `tools/agent/extract.py`, the checklist, fixtures `proc-promise-14z174` (REAL), `proc-planted-claim-14z176` and `proc-planted-figure-14z176` (PLANTED into a real clean span — the real 14z-174 QP2 case needs ritual knowledge a context-free reader is ruled not to have, and no real QP3 case survived a check of 14z-174), `proc-clean-14z176` (negative). The push binding is proven (14 cases) and awaits the maintainer | runs `2026-09-23-101..104`: each positive caught — the real one on BOTH QP1 and QP4, with a second instance the fixture's notes had not named — and the negative OK beside a caught plant; `tests/test_rule_checker.sh` (+ `cross-family-plant`) and `tests/test_agent_extract.sh` (two controls) |
| **S4** | W — worker definitions and the spec template | a worker run on a known task returns figures each traceable to a command |
| **S5** | O — the orchestrator definition and model switch | one real sitting under it, the C0/C1 record read at its close |

S1 alone addresses the measured failure. It is small, it needs no model, and it can
be replayed against history — which is why it goes first.

## 6. THE RULINGS (the ticket's open questions — RULED 2026-09-23)

**All four recommendations below were taken** (items 1-3 and 5; item 4 rides on
item 3's checkpoints). The maintainer's words on item 1 add the constraint every
slice must meet: *"Hard block + written resolve is fine but that doesn't mean that
the session should grind to a halt: it means the task at fault should be redone or
corrected, and when it is, it is checked and again and if green things are
unblocked … the point of this agent architecture is to minimize the risk while
keeping the system going forward autonomously (until user input is required of
course)"*. So: a denied tool call is redone in the allowed form; a blocked Stop is
answered by doing the outstanding thing; a denied push waits while the rest of the
work continues. No check is built whose only exit is the maintainer, except where
user input is genuinely required. The verbatim rulings are in `DECISIONS_HISTORY.md`.
The questions as put:

1. **"Cannot go against the will of checker agents", mechanically.** Recommended: a
   HARD BLOCK for the deterministic checks (C0 — the harness refuses; only the
   maintainer can change the hook), and BLOCK-UNTIL-RESOLVED-IN-WRITING for the model
   checker (C1 — like `rulecheck`, because a model checker has false positives and an
   unresolvable block would deadlock; the resolution is recorded for the maintainer to
   audit).
2. **The context split.** Recommended: the checker gets a generic procedure checklist
   plus the session's transcript extract, never CLAUDE.md or the project's history.
3. **What triggers a check.** Recommended: C0 on every tool call and every Stop
   (cheap, deterministic); C1 at declared checkpoints — every `git push` (bound
   mechanically) and every close — not on a timer, which the platform does not offer
   outside `/loop`.
4. **Worker specs.** Recommended: the orchestrator writes them from a template; C1
   checks the spec against the return at the next checkpoint.
5. **The order.** Recommended: S1 first and alone, measured for a sitting, before
   the model tiers.

## 7. WHAT IT WILL NOT CATCH

- **A job the agent never launches through a tool** — the hooks see only tool calls.
- **An intent the agent never states** — QP1 can only hold the agent to what it said.
- **A statement the transcript never recorded** — measured 14z-176: every report that ENDS a
  turn is kept, but mid-turn narration just before a tool call is sometimes absent (at least
  12 statements in one span of that sitting). C1 can only miss on it, never flag falsely.
- **The maintainer's time outside the session** — a notification wakes the agent;
  nothing here wakes the maintainer, except the push notifications already enabled.
- **An orphan that points nowhere into the project** — C0.3 finds orphans by where they
  point; a job started from `/` with no project path in its arguments or streams, as an
  Apple binary whose environment is hidden, is invisible to it (the gate's quiet orphan
  is that shape, on purpose). A job re-parented under anything but launchd/init (a
  subreaper, a surviving parent) is not an orphan to it either, and is listed only while
  it sits under this session's tool shells.
- **A C0 pattern it does not list** — C0.1 is a denylist of launch forms, so a new
  detaching form passes until it is added; the S1 replay over every archived
  transcript is how new forms are found.
