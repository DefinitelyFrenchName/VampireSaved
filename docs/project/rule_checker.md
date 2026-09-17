# THE RULE-CHECKER — an independent adversarial check at every decision point

**What this document is.** The specification of record for the rule-checker:
the fresh agent that reads the ARTIFACTS behind a proposed action and answers
five fixed questions before the action is taken. It is redundancy for rule
APPLICATION the way a second emulator is redundancy for a measurement
(GitHub #152, proposed by the maintainer: *"what if you spun an independent
adversarial agent to ensure some redundancy of the rules being applied? … if
the agent's only role is to check the rules applications it's probably quite
reliable since it carries little bias."*). The tool is `tools/rulecheck.py`,
the ledger is `tests/rulecheck/ledger.tsv`, the gate is
`tests/test_rule_checker.sh`, and the checklist below is read by the tool
from THIS file between its markers, so the prompt cannot drift from the spec.

## The failure it exists to catch

Rules are applied reliably when they are procedural and cue-triggered, and
unreliably when they require doubting a result at the moment it looks
strongest. Two paid cases, each a fixture under `tests/rulecheck/fixtures/`:

- **A comparison whose two legs shared a premise** (`forced-pick-14z159`,
  GitHub #147/#151, `docs/project/gotchas.md` "A FORCED-PICK NATIVE LEG
  MEASURES THE RIG"). Ours-vs-native read frame-identical over a whole rig
  part because BOTH legs forced the character with the same poke, after the
  select confirm had already latched another character's flavor. The rules
  that would have stopped it were loaded and cited in the same session; a
  manifest value was flipped, five tracks rebuilt and a freeze assembled on
  the strength of the result, and the maintainer's field report withdrew it.
- **A decision inferred from a timestamp** (`inferred-decision-14z162`,
  GitHub #151, `docs/project/gotchas.md` "A COMMIT SUBJECT THAT NAMES AN
  ISSUE AFTER A CLOSING KEYWORD"). A ticket's close event landed at the
  second of the session's own push; the session recorded it as the
  maintainer's deliberate act and followed it in the tree. The maintainer
  was never asked.

The common shape: the working agent holds a result that looks settled and
writes the sentence that turns it into an action. The checker is a second
reader with no stake in the result and no memory of how it was reached.

## **[VSP-183]** THE PROTOCOL — artifacts in, a structured verdict out, before the action

**When.** Before a measurement becomes the basis for an action, never at the
session end where the sunk cost already exists. The four decision kinds, and
each is a `--decision` of `tools/rulecheck.py prepare`:

| kind | the action about to be taken |
|---|---|
| `build` | a manifest row or a generator change made on the strength of a measurement (anything that moves a shipped byte) |
| `freeze` | a freeze — registry rows, expectation sets, the tag |
| `expectation` | freezing, re-freezing or re-classifying a frozen expectation |
| `recommendation` | a report or recommendation to the maintainer that proposes an action, closes a question, or attributes a decision to anyone |

**What goes in.** The packet is the decision kind, a SUBJECT, ONE claim
sentence written by the working agent — what is claimed, what it rests on,
and what was NOT tested — and the ARTIFACTS by repo-relative path: the diff,
the gate script, the log, the expectation file, the issue timeline. Never a
narrative: handed a summary the checker inherits its framing, and two
methods with one premise are one method ([VSP-148]). The claim sentence is
the one narrative element, and it is required because the checker can only
test whether a premise is STATED. The tool stages the artifacts under
`build/rulecheck/<id>/` and records each one's SHA-1 in the run dir; a line
range `path:a-b` stages under its own name (`path.lines-a-b`), because two
ranges of one file used to collapse onto one staged copy while the manifest
listed both (GitHub #156, 14z-164: a reader answered Q5 from the range that
had overwritten the ruling it was asked to find). **A
packet is complete when the artifacts can settle every premise the claim
names**: the first calibration of the negative fixture handed the checker a
claim about shared pokes without the file that lists them, and the checker
returned `VIOLATED` on exactly that — correctly, since as handed over the
premise was unverifiable. An incomplete packet is a stop, not noise.

**Who reads it.** A FRESH agent — never a fork, which inherits the working
agent's context and therefore its framing — given the prompt file verbatim
and nothing else. It reads the files with its own tools. It runs nothing and
modifies nothing.

**What comes out.** Six lines and nothing else: the five questions, each
`VIOLATED`, `OK` or `N-A` with evidence as a path and line or a verbatim
quote, then `VERDICT: VIOLATED|OK`. `tools/rulecheck.py record` refuses
prose, a missing question, or a verdict that disagrees with its answers — a
prose verdict is unfalsifiable and gets rationalised away.

## The checklist of record

The five questions, verbatim as the tool hands them to the checker. Three to
five questions, not the rulebook: a sweep of two hundred rules produces noise
nobody reads. Each question names the failure it was written from.

<!-- CHECKLIST BEGIN -->
THE FIVE QUESTIONS

Q1 STATED BASIS — Does the claim state what it rests on that was NOT tested, and do the artifacts confirm those are the only untested premises? A claim that names no untested premise is VIOLATED unless the artifacts show there is none. (Written from a comparison that "proved" a fix while resting on a rig both legs shared.)

Q2 CAPTURE — If the claim draws a conclusion about behaviour a player could feel (how a move plays, its timing, a float, a hold, a hit), was a capture — an image or a recording — produced and put before the maintainer BEFORE the conclusion was drawn? A number alone is not a capture. N-A when no such conclusion is drawn.

Q3 SHARED PREMISE — If two legs are compared (ours against native, before against after, A against B), do they share a rig, a tool, an input path, a poke, or a premise that the artifacts SHOW can write or select the compared state, such that a defect in it would make them AGREE? Two agreeing methods sharing a premise are one method. A mechanism no artifact shows is not a finding: name the line that shows the shared thing reaching the compared state, or answer OK. N-A when there is no comparison.

Q4 CONTROL FOR THIS FAILURE — Does the instrument carry a control that would fire on the specific way THIS claim could be wrong — not merely some control? Name the control and the failure mode it covers. A failure mode that the CLAIM ITSELF names as untested or uncovered is OK here: a named gap is the working agent's to accept in writing, not the checker's to find. VIOLATED only for a failure mode that is neither controlled nor named by the claim; name it. A control that proves the instrument sees a different thing than the claim rests on does not count as covering it.

Q5 DECISION SOURCE — If the packet attributes a decision, an approval, a ruling or a closure to the maintainer or to any person, is that person's OWN STATEMENT quoted in the artifacts? An inference from a timestamp, an event log, an actor field, a coincidence or a silence is VIOLATED. N-A when no decision is attributed to anyone.

ANSWER FORMAT — output EXACTLY these six lines and nothing else: no preamble, no closing remark, no code fence. Evidence is a repo-relative path with a line number, or a verbatim quote in double quotes.
Q1: <VIOLATED|OK|N-A> — <evidence>
Q2: <VIOLATED|OK|N-A> — <evidence>
Q3: <VIOLATED|OK|N-A> — <evidence>
Q4: <VIOLATED|OK|N-A> — <evidence>
Q5: <VIOLATED|OK|N-A> — <evidence>
VERDICT: <VIOLATED if any question is VIOLATED, otherwise OK>
<!-- CHECKLIST END -->

## **[VSP-184]** THE BINDING AND THE MUST-FIRE — a verdict that stops the action, a plant that proves the checker alive

**The binding half is on the working agent.** A `VIOLATED` verdict STOPS
the action until the violation is resolved and the resolution recorded
(`tools/rulecheck.py resolve <id> --how "..."`; the gate fails on a
`VIOLATED` row with no resolution). The resolution answers EACH violated
question by its label (`Q1: … Q4: …`) — what changed, or why the finding is
accepted — and the tool refuses one that does not (maintainer-ruled, option
C: the questions are bounded AND what they still find is answered in
writing). The checker's output is reported to the
maintainer VERBATIM, never summarised — paraphrase is where softening
happens — and the run dir keeps it verbatim.

**The must-fire half, like every control in this tree ([VSP-181]).** A
checker that has never failed anything is a dead control. So every real run
is PAIRED with a planted known violation: the tool draws a fixture by
rotation, labels the two prompts `a` and `b` at random, and the working
agent spawns two fresh agents in one message, neither told which packet is
the plant. A plant that is not caught VOIDS the real verdict — it licenses
nothing, and the run is repeated with fresh agents; a plant that is never
caught means the checker is dead, not the plant. A fixture may serve as a
plant only once it is CALIBRATED — a positive one run alone (`prepare
--calibrate`) and caught; a NEGATIVE one (expected `OK`) run BESIDE a
calibrated plant, blind, so that a reader quiet because it is dead cannot
read as a clean packet (the first real run found the negative calibrations
had carried no plant) — and at least one negative fixture proves the
checker stays quiet on a clean packet: an instrument is proven to fire on a
known positive and stay quiet on a known negative before its first real use
([VSP-19]). Calibration is repeated when the checklist changes or the model
changes, because either moves the instrument.

**The mechanical binding: a freeze.** Every row of
`tests/expected/registry.tsv` after the checker's birth row (the M18 merged
row) must be named by an `OK` `freeze` run in the ledger, or
`tests/test_rule_checker.sh` fails. The other three decision kinds cannot be
bound by a file the tree can see; they are bound by the rule above, and the
ledger is what the maintainer audits.

## What the first runs measured

The record is the ledger; this is what it showed at birth (the STATE record
of the session that built the checker has the figures). Every plant put to a
reader was caught, and every false statement put to a reader — the
false-statement fixture, and the working agent's own claim sentences on the
negative fixture, which were corrected three times on readers' findings — was
caught and cited to the artifact line that contradicts it. The negative
fixture, an honest packet about a real gate, did NOT read OK by every reader:
Q3 and Q4 as worded admit mechanisms no artifact shows and failure modes no
real gate covers, so a reader can always find one more, and the readers' spread
on the same packet is a property of the instrument. The maintainer ruled BOTH:
Q3 counts only a shared thing the artifacts show reaching the compared state,
Q4 reads OK for a failure mode the claim itself names, and what the bounded
questions still find is answered question by question through `resolve`.
Every fixture was recalibrated on that wording; the ledger shows the
before and after.

**The first real runs under the bounded questions (14z-164, runs 22-28,
seven in one sitting; GitHub #152 closed on them by ruling 2026-09-17).** Two
recommendation packets and five expectation packets, every plant caught
(7/7), every `VIOLATED` resolved by work: the checker found two instrument
defects in the comparator the session itself had just written (a cumulative
field compared from the window start turned the rig's periodic HP pin into a
DIFF at the pin frame; the per-event X pin compared as an absolute inside the
previous window), a silent fallback and a collapsed link comparison in a new
static audit, a chain counted as a content difference when it was live on one
game and invalid on the other, the working agent's own figures (a cross-part
count written as one part's, one character's stock values copied from
another's, "five" tables that were six, counts quoted from the previous
freeze), and a defect in this tool's own staging (two line ranges of one file
collapsed onto one copy, #156). The last three runs read Q2-Q5 `OK` and Q1 on
claim accuracy alone. Cost: two fresh agents per run, 50k-260k tokens and
30 s to 8 min each; the readers that read the most (the expectation packets,
60+ artifacts) took 4-8 min.

## What it will not catch

- **Operational slips.** A waiter wedged for hours is not a rule-application
  failure; it was not looking. The checker does not fix that.
- **A premise nobody wrote down.** It can only ask whether the premise is
  STATED, which is why the claim sentence is required: produce the sentence,
  so there is something to check.
- **Its own silence.** Hence the plant on every run.
- **A violation outside the five questions.** The checklist is short by
  design; a new failure class earns a question only after it has been paid
  for, and the change re-calibrates every fixture.

## The fixtures

| fixture | expected | the violation it plants |
|---|---|---|
| `forced-pick-14z159` | `VIOLATED` on Q3 or Q4 | the #136 rig at the commit before the M19 freeze: both legs of ours-vs-native force the tenant by the same poke after the confirm; no control proves the native leg faithful |
| `inferred-decision-14z162` | `VIOLATED` on Q5 | the issue timeline, the two close commits and the STATE row that recorded a maintainer decision from the close event's timing |
| `fidelity-14z160` | `OK` | the gate that measured what a forced pick gets wrong: every untested premise stated, the negative control named, no behavioural conclusion drawn |
| `fidelity-14z160-false-statement` | `VIOLATED` on Q1 | the same packet with ONE false statement in a clean-shaped claim (the SELF leg called a changed-value write, which the gate's own header contradicts) — the failure mode the first real run named as covered by nothing |

A fixture's `files/` are snapshots, never live paths, so the plant does not
move when the tree does; gate scripts are stored with a `.txt` suffix so no
registry or census counts them as gates. A new fixture is a paid case: it
names its incident, its ticket and the question it exercises, and its `NOTES`
(never handed to the checker) records its calibration history and says of
every firing beyond `EXPECT` whether it was true of the packet or noise.

## The ledger

`tests/rulecheck/ledger.tsv`, append-only, one row per run: id, date,
session, decision, subject, the plant, whether the plant was CAUGHT or DEAD,
the verdict (`OK`, `VIOLATED`, or `VOID` when the plant was dead), the
questions violated, the resolution, and the model the checker ran on. The
run dir `tests/rulecheck/runs/<id>/` holds the packet, the artifact SHA-1s,
the plant's name and slot, and both verdicts verbatim. The gate reads all of
it: every row well-formed, every run dir complete, every verdict file
structured and agreeing with its row, every fixture calibrated, every
`VIOLATED` resolved, every freeze since the birth named.
