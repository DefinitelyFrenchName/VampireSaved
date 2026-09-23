# THE WORKER SPEC — the template every task handed to a worker is written from

**What this is (GitHub #172, slice S4, ruled 2026-09-23 — `DECISIONS_HISTORY.md` "Ruled
2026-09-23 (14z-177)").** A worker is a named, capped definition under `.claude/agents/`
(`measurer`, `reader`) that the orchestrator drives by a SPEC — a prompt written from this
template, nothing else. The template exists for two readers besides the worker: the procedure
check (C1, `docs/project/rule_checker.md` "THE PROCEDURE FAMILY") reads the SPEC against the
worker's RETURN, and the call gate — ruled, a proposal until the maintainer installs it — will refuse a call to
a defined worker whose prompt lacks the headings below. So the headings are fixed, spelled exactly, and each on its own line.

**Why a spec and not a request.** The maintainer's ask (#172): *"workers: specialized, driven by
very precise specifications and directives given by the orchestrator"*. The blind spot it names
— the orchestrator's framing propagating into every worker — is answered by making the framing
INSPECTABLE: what the worker was told, what it ran, and what it returned are three things C1 can
put side by side.

## The template

Copy it, fill every section, delete nothing. A section with nothing to say says `none`.

```
TASK: <one sentence: the question the worker answers — a question, not a conclusion to confirm>

INPUTS:
- <path, commit, build dir or session id the commands read; each pinned where it can move>

COMMANDS:
C1: <the exact command, as it is to be run>
C2: <...>

RETURN:
FIG <name> = <value> <- C<n>
NOT MEASURED: <what> — <why>
(nothing else: no conclusion, no recommendation, no summary line)

MUST NOT:
- infer, estimate or recall a figure: every FIG comes from a command's output
- run a command that is not in COMMANDS; if one is needed, stop and say which and why
- edit, create or delete a tracked file; launch a detached job; spawn an agent
- <anything else this task forbids>

STOP:
- at the first command that fails or prints something the task did not expect: report the
  command and its output verbatim, and return what was measured before it
```

## What each section is for

- **TASK** is a QUESTION. "Confirm that X is 12" hands the worker the answer; "how many rows does
  X have" does not. QP5 (ruled 2026-09-23; not yet in the checklist) will ask whether the return
  answers the question asked, so the question has to be written down.
- **INPUTS** pins what can move. A figure from `HEAD` is a figure about a commit nobody named; a
  figure from `git show <sha>:<path>` is reproducible forever (the S4 gate, step 2 of the ruled
  order, is to rely on exactly that).
- **COMMANDS** are numbered so each figure can name its source. The worker runs them as written;
  a worker that improvises a better command has answered a different question, and says so under
  STOP instead.
- **RETURN** is one line per figure, `FIG <name> = <value> <- C<n>`, because a figure without its
  command cannot be re-derived and a figure QP3 cannot find in the worker's own tool results will be
  VIOLATED once QP3 is widened to workers (ruled 2026-09-23; not yet in the checklist). `NOT MEASURED` lines are how a worker says what it could not do without guessing.
- **MUST NOT** is where the orchestrator writes what the task forbids beyond the four standing
  items. The standing items restate rules the hooks and the definitions already enforce (C0.1
  is a project hook, and A7 of `tools/agent/probe_agents.sh` measured that a project hook sees a
  worker's own calls; and the
  definitions carry no Write, Edit or Agent tool, which `tests/test_agent_defs.sh` holds); they are
  repeated so C1 can hold the return to them. Bash can still write a file: that one is held by the spec and by C1, not by a tool.
- **STOP** makes a failed command a report rather than a detour.

## What a spec does not do

- It does not make a figure RIGHT. It makes it traceable: the command that produced it, run again,
  must reproduce it (the S4 gate, to be built), and whether that command answers the TASK is C1's to judge.
- It does not bind a fork. A fork is the orchestrator continuing (ruled 2026-09-23), not a worker,
  and C1 reads a fork's return like the orchestrator's own statements.
