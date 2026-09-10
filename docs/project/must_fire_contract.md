# The must-fire contract — a control is DECLARED, FIRED and EXECUTABLE

**What this document is.** The specification of record for how a gate in this
tree declares its must-fire controls, how it reports them, how a runner reads
them, and what the executable form proves. It is the tree's COPY of BBX's R10
grammar (plus R29, the executable form, and R30, the header rule) — a copy
kept by hand, never a dependency, under the maintainer's ruling that the two
are *independent but compatible* (2026-09-08). The law it serves is
CLAUDE.md §4 "Verdict logic is itself tested" ([VSP-19]); the rule it distils
is [VSP-181] in `HANDOFF.md` "How to test". The reader is
`tests/lib/controls.sh`, the classifier that turns a red block into FAIL is
`tests/lib/classify.sh`, and the ground truth for both is
`tests/test_controls_contract.sh`. The status of the retrofit is
`tests/expected/must_fire_census.tsv` (three classes, below).

## The declaration

A gate that asserts a property declares every must-fire control it runs as
one line in its HEADER — the leading comment block, every `#` line after the
shebang up to the first non-comment line; a bare `#` does not end it — in
exactly this grammar:

```
# MUST-FIRE: <shape>: <name> — <what must fail, and why that proves the gate can fail>
```

`<shape>` is one of `perturbed-copy` (one byte or one value of a copied
artifact changed), `shadow-tool` (a copy of a tool with a line stripped, under
a throwaway root — the tracked tool is never written), `known-bad` (a
synthetic input or a reference known to be wrong). `<name>` is `[a-z0-9-]+`,
unique within the gate. The separator is the em dash. A gate that asserts
nothing (a fixture generator, a registry lister) says
`# MUST-FIRE: none — <why this gate asserts no property>` so silence is
distinguishable from omission.

The header is read by ONE function, `vs_ctl_declared`, and the regex is the
only reader: `^# MUST-FIRE: (perturbed-copy|shadow-tool|known-bad): ([a-z0-9-]+) — (.+)$`.
A line below the first code line is not a declaration; a wrong shape, a name
with a capital or an underscore, a hyphen where the em dash belongs — none of
these declare anything, and the census (below) will not count them.

## The firing

When a declared control fails for its stated reason, the gate prints, at
column 0, `CONTROL FIRED: <name> — <evidence>`. When it does not — it passed,
or failed for another reason — the gate prints `CONTROL DEAD: <name> — <what
happened>`. An indented line is prose, not a firing.

Every runner hands the classifier the gate SCRIPT beside the log
(`vs_classify <exit> <log> <width> <script>`), and for a PASSING gate the
classifier compares declared against fired. A declared control that did not
fire, a `CONTROL DEAD:` line, or a firing no header declares turns the verdict
into plain **FAIL** — there is no fourth verdict (maintainer, 2026-09-10:
*"NO fourth verdict"*). A gate with no declaration is left alone and COUNTED
as undeclared; a `none` declaration is counted as such. SKIP and FAIL are
never touched: a skipped gate ran nothing, a failed gate is already red.

## The executable form

`CONTROL FIRED` is the gate's SELF-report, and a control can print it while
testing nothing — it wrote a value and asserted the value was not something
else (14z-144, the case the maintainer raised). So a declared name is also a
MODE: `CONTROL=<name> tests/<gate>.sh` applies that control's perturbation to
the gate's REAL input and runs to the gate's OWN verdict, which must be FAIL.
The gate announces the mode (`CONTROL MODE: <name> — …`) and refuses a name
its header does not declare: `REFUSED: CONTROL=<name> is not a mode of this
gate`, exit 3.

The runner's verdict on a control run (`vs_classify_control`, one copy, in
`tests/lib/classify.sh` so no runner carries a second shell-error regex):

| verdict | when | meaning |
|---|---|---|
| HONOURED | exit non-zero, no crash | the perturbation was caught |
| LIES | exit 0, or a SKIP | the perturbation left the gate green — the control tests nothing |
| REFUSED | the gate printed `REFUSED: CONTROL=` | declared in the header, never read by the gate |
| DIED | the shell's own error line, or a traceback | a crash is not a verdict ([VSP-108]) |
| TIMEOUT | the wrapper's exits | as for any gate |

Anything but HONOURED is a failure of the run, named `<gate>(control:<name>:<verdict>)`.

## The pattern that makes the mode cheap to write

Write each perturbation as ONE function the control section and the mode both
call (`perturb <name> <copy>` setting `EXPECT`, the substring the failure must
carry). Under the mode the perturbed copy becomes the INPUT the main check
reads (`ROOT`, `MANIFEST`, `REGISTRY`, `PAGE`, `SIDE_B`, the tool path for a
shadow tool); the control section still builds its own copy and prints the
FIRED/DEAD line. What the mode proves is then exactly what the control claims,
and the two cannot drift. A gate whose control cannot run on a machine (a
bench needing Verilator) REFUSES the mode there rather than passing it.

## The runners

`tests/run_all_static.sh` reads every gate's block for free and EXECUTES each
declared control after a PASS — `--exec-controls all|portable|none`, default
`all` — and prints a readout: `fired N / declared N`, the none and undeclared
counts, and `executed N honoured N lies N refused N died N` — printed only when
the tier declared or executed anything, so over a declaration-free tree the
runner's output is byte-identical to bbh's (fidelity F1; lifting the reader into
bbh is the follow-up, and F2 carries the delta until then). Its ground truth
is `tests/test_static_runner.sh` sections 11-13.

`tests/run_all_emulator.sh` reads every block on every run and executes the
controls only under `--controls` (one more run per declared name; its rows are
`<gate>@<name>` with PASS = honoured, in the tally and under `--strict`). It is
off by default because it multiplies a tier measured in hours; the release
checklist decides its cadence (STATE "Decisions pending", 14z-147). Ground
truth: `tests/test_emulator_runner.sh` section 14.

`tests/run_battery_m2.sh` reads the block through `bat`
(`tests/test_battery_accounting.sh` sections 7-8).

## The census — three frozen classes

`tests/test_must_fire_census.sh` freezes, in `tests/expected/must_fire_census.tsv`:

- `declares` — gates whose header carries an R10 declaration. Grows only.
- `header-only` — declaring gates whose non-comment code prints no
  `CONTROL FIRED:` / `CONTROL DEAD:` line. Shrinks only.
- `retrofit-debt` — gates that mention a must-fire control in a pre-grammar
  spelling and declare nothing. Shrinks only. This is the inventory the
  retrofit works down, tier by tier, each pass ending with one strict run of
  the tier as the identity bar (every verdict unchanged before and after).

## What the contract does not do

It does not prove a control is RIGHT — a control that fires on a perturbation
unrelated to the property is a control that lies about what it guards. That
judgement is a review per control ([VSP-19]); the contract makes each control
findable, its silence loud, and its self-report checkable by execution.
