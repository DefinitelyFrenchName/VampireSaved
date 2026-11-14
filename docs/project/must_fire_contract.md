# The must-fire contract — a control is DECLARED, FIRED and EXECUTABLE

**What this document is.** The specification of record for how a gate in this
tree declares its must-fire controls, how it reports them, how a runner reads
them, and what the executable form proves. It is the tree's COPY of BBX's R10
grammar (plus R29, the executable form, and R30, the header rule) — a copy
kept by hand, never a dependency, under the maintainer's ruling that the two
are *independent but compatible* (2026-09-08). **Since 2026-10-10 (14z-197, maintainer-ruled:
bbh is its own project) the copy evolves on its own**, kept while it delivers value to this
project; nothing here is held to bbh's text any more. The law it serves is
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
| HONOURED | exit non-zero, no class below, and the log carries `CONTROL CAUGHT: <this control> — ` (printed only by `vs_ctl_caught`) | the gate's own check found the perturbation's finding (#369, 14z-224); a gate on the debt list `tests/expected/ctl_caught_debt.tsv` is HONOURED without the line until it is migrated |
| LIES | exit 0, or a SKIP | the perturbation left the gate green — the control tests nothing |
| REFUSED | the gate printed `REFUSED: CONTROL=` | declared in the header, never read by the gate |
| DIED | the shell's own error line, or a traceback | a crash is not a verdict ([VSP-108]) |
| DIED | an environment error anywhere in the log (`No space left on device`, `mktemp: `, `cannot create …`, `Permission denied`, `Read-only file system`, `Too many open files`, `Cannot allocate memory`, `Disk quota exceeded`: `tests/lib/classify.sh` `VS_ENV_ERR`) | the host stopped the run, not its perturbation (#321, 14z-210: 28 modes read HONOURED on a full `/tmp`) |
| DIED | no `NOT JUDGED: ` line, the log ENDS on a tool's own error lines (`awk: can't open file`, `sed: …`, `cp: …: No such file or directory`, ` source line number N`: `tests/lib/classify.sh` `VS_TOOL_ERR`), and the line before them is not the gate's own FAIL | the gate died under `set -e` on a tool's failure before its own verdict — not the perturbation; a gate that printed its FAIL and then ran a diagnostic that failed exited by its own hand (GitHub #367, 14z-223; a `set -e` death that prints nothing is not caught) |
| UNJUDGED | a FAIL whose log has a line starting `NOT JUDGED: ` | the mode run measured nothing (#310, 14z-210) |
| UNJUDGED | a FAIL with none of the above and no `CONTROL CAUGHT: <this control> — ` line, the gate not on the debt list | no positive evidence from its own check (#369, 14z-224) |
| TIMEOUT | the wrapper's exits | as for any gate |

Anything but HONOURED is a failure of the run, named `<gate>(control:<name>:<verdict>)`.

**WRITE `NOT JUDGED: <why>` ON EVERY PATH THAT ENDS A RUN WITHOUT A VERDICT ABOUT WHAT THE GATE MEASURES** (#310,
14z-210): a browser run that did not complete, an instrument that never armed, an out-of-tree input that is absent, a
mode whose failure lacks its own finding. Without it, any non-zero exit with no crash reads HONOURED — a control that
measured nothing certified as caught (measured 14z-206: `test_applier_page_browser`'s `broken-page` stalled under load
and read HONOURED). Print it at the start of a line, before the FAIL, and never on the path where the control is
honoured; a control mode whose own outcome IS "not judged" (a starved leg) prints the words without the marker. Gates
that carry it, as worked examples: `test_applier_page_browser`, `test_docshape`, `test_annotations_current`,
`test_emulator_staleness@moved-input`, `audit_guard_cancels` (`table-absent`). The class is held by
`tests/test_emulator_runner.sh` section 14c (control `unjudged-honoured`). #310's census of every control
(`build/agent210/t310/`, local, and the ticket's comment) lists the paths in other gates that still lack it.

**A MODE THAT LEAVES THE GATE GREEN SAYS `CONTROL DEAD: <its name>`, NEVER ONLY WORDS** (#310, 14z-215): a mode run
that reaches the gate's green end calls `vs_ctl_left_green <mode> <FAIL line>` (`tests/lib/controls.sh`), which prints
the DEAD line the classifier reads LIES and exits 1. "Control mode X left the gate green" in words with `exit 1` read
HONOURED in 44 gates until then. `tests/test_dead_exit_census.sh` (`tools/dead_exit_census.py`) names any new one in
the copied shapes; a dead branch phrased otherwise is its stated known gap. The instrument-alignment library prints
`NOT JUDGED:` for a dead leg under a mode (`tests/lib/instr_align.sh`, held by `tests/test_instr_align_unjudged.sh`), and
a runner test's wall-clock checks count only in its plain run and under the mode they belong to.

**A PERTURBED COPY THAT CRASHED IS NOT ITS PERTURBATION CAUGHT** (#310 group 5, 14z-215): a gate whose mode (or in-gate
twin) runs a copy of a tool or script keeps the copy's whole output and, when the run did not give the expected answer,
calls `vs_ctl_show_err <output> [<expected exception>|-] [<copy script>]` (`tests/lib/controls.sh`): a traceback is
re-printed at column 0 (the mode reads DIED), a SyntaxError or the shell's own error line about the copy prints
`NOT JUDGED:` (UNJUDGED); where a crash IS the honoured outcome only that exception passes. A twin reads absence as
fired only after a positive line from the copy. Printing `tail -N`, a joined excerpt or nothing of the copy's output read
a crash HONOURED in the 21 gates #310's group-5 census found, and in the three runner tests it could not tell
(test_static_runner, test_emulator_runner, test_release_reuse: a planted shadow crash read HONOURED, 14z-215), whose
shadow runners' stderr is now handed to the helper under a mode; `tests/test_ctl_show_err.sh` holds the helper on planted
copies.

**A DEAD EMULATOR LEG IS NOT THE CONTROL FIRING** (#310 group 7, 14z-221): beside each liveness check (an emulator that
exited non-zero, a trace with no END line, no samples, a reducer's VOID about a leg that never ran) a gate calls
`vs_ctl_nj <why>` (`tests/lib/controls.sh`), which under a mode prints `NOT JUDGED: under control mode <mode>, <why>`
(UNJUDGED) and in a plain run prints nothing; the mode is `VS_CTL`, else `CONTROL`, so a gate that parses `CONTROL` itself
only sources the library. It is not called for a mode whose honoured outcome IS a dead or VOID leg. A mode close prints
`CONTROL FIRED` on its own finding, never on any fail flag. Batched by #310's re-census; each batch's rows are held by
`tests/test_dead_leg_unjudged.sh` (`tests/expected/dead_leg_unjudged.tsv`): with `MAME_BIN=/usr/bin/false` (and the row's
dead instrument, its fifth column: `FBNEO_BIN` for an FBNeo leg, batch 2, 14z-221c) every row reads UNJUDGED, its plain run
is red and silent, and its gate with the `# #310 g7 NJ` lines neutered reads its frozen stripped class (the pre-fix class,
or HONOURED where the batch also added the liveness check the pre-fix gate lacked and crashed without).

## #369 — a mode is honoured only on positive evidence from its own check

Ruled 2026-11-08 (14z-224, the maintainer: *"A1, B1, c1"* on `build/agent224/t369/design.md`). Until then the
classifier's fall-through read any non-zero exit with no crash as HONOURED, and #310 spent seven batches naming the
other ways a mode run fails (a dead leg, a refusal, a SKIP, a crash it could not see). Now the run must carry its own
evidence:

- **`vs_ctl_caught <output file> <ERE>`** (`tests/lib/controls.sh`, the ONE printer of `CONTROL CAUGHT:`). Call it where
  a mode run ends in the gate's FAIL, on the file holding the gate's MAIN check output, with an ERE matching only the
  finding that mode's perturbation must produce. Under a mode it prints `CONTROL CAUGHT: <mode> — <first matching line>`
  or `NOT JUDGED: under control mode <mode>, the check failed without its finding '<ERE>'`; in a plain run it does
  nothing. A catch-all ERE (`''`, `.`, `.*`, `FAIL`, `^FAIL`, `^ *FAIL`) is refused at run time too.
- **`vs_ctl_fired` under a mode prints `NOT JUDGED`** in a gate off the debt list: a firing line printed during a mode
  run comes from the gate's built-in control section (its own copy, whatever the main check did) or names the mode
  unconditionally. In a plain run it prints `CONTROL FIRED:` as before, and the plain-run contract above is unchanged.
- **The class names stay** (ruling B1): a crash beside a CAUGHT line is still DIED, a `NOT JUDGED` beside it still
  UNJUDGED, its own `CONTROL DEAD` still LIES, exit 0 with it LIES. A `CONTROL CAUGHT` line in a plain PASS turns the
  controls block RED.
- **The debt list** (ruling C1): `tests/expected/ctl_caught_debt.tsv` lists every gate that declared a mode at
  8464fa3f and is not yet migrated; a listed gate keeps the old fall-through and its `vs_ctl_fired`. It only shrinks.
  #369 and #310 closed with its 100 rows left, as #369's stated limit (ruled 2026-11-13, 14z-227): no batch migrates
  them; a listed gate migrated for its own reasons still leaves the list in that commit. **What the 100 cost to leave,
  measured (14z-227):** 348 of their 352 declared modes were read blind by eight readers from their latest logs (the
  4 MiSTer modes not measured), with 18 hidden controls of known own and known foreign reds, all read right (batches 3
  and 4, 88 real items, carried own-red controls only, so a false OWN there is uncontrolled). 343 were read as red from
  the check the declaration names (one of them #373's crash, not the declared one); the other 5 (4 OTHER, 1 CANNOT-TELL) are not shown to have (for four of them the
  same control fires in-gate on the plain run, which shows the check sees its fault there, not why the mode run
  went red). The one defect found is #373: a firing line that claims a result the gate never checks; fixed 14z-227 by
  migrating that gate (`audit_guard_corpus`: its rig re-timed for the emulated clock, its mode HONOURED only on the
  tripwire's own line, its in-gate control run on every plain run), so the list holds 99 rows. What stays open: a
  listed gate's mode is still HONOURED on any red, so a later change that turns one red for a foreign reason is not
  caught by the classifier.

`tests/test_control_classifier.sh` holds the classifier (control `fallthrough-honoured`), `tests/test_controls_contract.sh`
section 7 the helpers (`fired-under-mode`, `plain-caught-green`), and `tests/test_ctl_caught_lint.sh`
(`tools/ctl_caught_lint.py`) the static half: the literal printed only through the helper [a] (the ground-truth gates
that write synthetic logs may carry it, never in an echo or printf whose stdout is not sent to a file, nor at the start
of a line, the body of a multi-line string or a heredoc), no catch-all ERE [b], no
`vs_ctl_fired "$VS_CTL"` off the list [c], every mode-declaring gate calls the helper or is listed [d], several modes
compute the ERE per mode [e], and the list only shrinks [debt]: a gate absent at 8464fa3f never joins it, and every row
must be on the list's first version (its blob pinned in the gate as `ORIGIN_BLOB`) and on every committed version since,
so a migrated gate, or a deleted row, never comes back (rule-checker run 2026-11-09-1743).

**NOT HELD BY ANY LINT, HELPER OR RUN-TIME RULE — review each gate as it migrates:** a `vs_ctl_caught` call handed a file
other than the main check's output (a copy's, or the in-gate section's), a per-mode ERE that still matches any
failure of the check, and THE STATED LIMIT of rule [a] in the six ground-truth gates (maintainer, 2026-11-09: "Land
with a stated limit (Recommended)", after rule-checker runs 2026-11-09-1743, -1744 and -1745 each found a way past a
text check of shell source): the lint covers echo or printf written on one line, sent to stdout or stderr; any other
printer (awk, cat of a file, tee), a line assembled at run time (the literal split, or built in a variable, a function,
a command substitution or a format) are review. Stated by the session and accepted by the maintainer 2026-11-09 (14z-225: "(a) Accept them as stated limits."): the reader is
textual — it reads each statement as written, never as the shell evaluates it — so a one-line echo or printf it
mis-splits, a redirect target held in a variable, a later redirect that overrides an earlier one, eval, aliases and
functions pass too (rule-checker runs 2026-11-09-1748 and -1749). Every other gate stays under
the strict rule: the literal may not appear anywhere in a code file under tests/ or tools/, at any depth. In every file
a literal assembled at run time (split, formatted, built in a variable) passes the lint, which reads the literal written
whole, and code outside tests/ and tools/ is not read, nor a data file a gate prints (a fixture, a kept mode log):
review (rule-checker runs 2026-11-09-1746 and -1747; stated by the session and accepted by the maintainer 2026-11-09 (14z-225: "(a) Accept them as stated limits.")).

**Migrating a gate:**

1. The main check writes its findings to a file (`… | tee -a "$W/main.log"`, or the tool's own output file).
2. Where a mode run ends in FAIL, call `vs_ctl_caught "$W/main.log" "$WANT"`, `WANT` set per mode (the `EXPECT` of the
   `perturb` function below is the natural source). Retire `vs_ctl_fired "$VS_CTL"` closes and fail-flag closes.
3. Run the in-gate control section only in a plain run (`[ -n "${VS_CTL:-}" ] || …`).
4. Make the check non-vacuous: a check that judged zero items prints `NOT JUDGED` (`vs_ctl_nj`), never its FAIL — a
   dead leg that wrote nothing never reaches the check, but a leg that ran and judged nothing does
   (`tests/audit_extra_pass.sh`'s E1 failed at `n == 0` with the mode's own finding). Keep every liveness `vs_ctl_nj` line.
5. A crash that IS the honoured outcome: `vs_ctl_show_err <copy output> <exception>` and then `vs_ctl_caught` on the
   same output with the exception's ERE.
6. Accept it: the plain run PASS with every control fired; every mode HONOURED on its own CAUGHT line; and, where they
   can be built, a dead-instrument run (the leg that wrote nothing) and a starved run (a live instrument, zero judged
   items) both UNJUDGED. Where a starved input cannot be built, say so: review only.
7. Delete the gate's debt row in the same commit. A gate with rows in `tests/expected/crash_sweep.tsv` (its `kb` leg) or
   the dead-leg tables (their stripped class) changes those classes when it migrates (#369 piece 5, maintainer-ruled
   2026-11-09 "Name the speaker (Recommended)"): the real run must stay UNJUDGED on the gate's OWN line, and the
   neutered leg's frozen class becomes UNJUDGED-CAUGHT — UNJUDGED by #369's backstop alone (`vs_ctl_caught`'s NOT
   JUDGED, or a FAIL with no CAUGHT line), the class word `tests/lib/classify.sh` `vs_ctl_class_word` writes. Re-measure
   those rows in the batch that migrates the gate.

## The pattern that makes the mode cheap to write

Write each perturbation as ONE function the control section and the mode both
call (`perturb <name> <copy>` setting `EXPECT`, the substring the failure must
carry). Under the mode the perturbed copy becomes the INPUT the main check
reads (`ROOT`, `MANIFEST`, `REGISTRY`, `PAGE`, `SIDE_B`, the tool path for a
shadow tool); the control section, in a plain run only, builds its own copy and prints the
FIRED/DEAD line, and the mode's FAIL calls `vs_ctl_caught` on the main check's output with
`EXPECT` (#369). What the mode proves is then exactly what the control claims,
and the two cannot drift. A mode may run ONLY the section its perturbation
reaches (`tests/test_close_tools.sh` since #268, 14z-199, where eight of its ten
modes each re-ran a ~8-minute section none of them perturbed, 482-495 s a mode
at the 14z-198 close): the verdict is still the
gate's own, and a section reading inputs the perturbation does not touch adds
only time. A gate whose control cannot run on a machine (a
bench needing Verilator) REFUSES the mode there rather than passing it.

## The runners

`tests/run_all_static.sh` reads every gate's block for free and EXECUTES each
declared control after a PASS — `--exec-controls all|portable|none`, default
`all` — and prints a readout: `fired N / declared N`, the none and undeclared
counts, and `executed N honoured N lies N refused N died N` and, when controls ran, `time: gates Ns controls Ns wall Ns (costliest
controls: …)` (2026-09-14) — printed only when
the tier declared or executed anything (so over a declaration-free tree the
runner's output stayed byte-identical to bbh's, which bbh's fidelity test F1
compared until 14z-197; the reader was lifted into bbh at 14z-148 as a copy).
**That comparison is no longer a constraint** (maintainer-ruled 2026-10-10:
`test_bbh_fidelity` deleted, the runners' output this project's own). The
readout's header is `== must-fire controls ==`, and a controls-red FAIL row
reads `(controls RED: …)`. Its ground truth
is `tests/test_static_runner.sh` sections 11-13. **WHEN (maintainer-ruled
2026-09-14):** a mid-session commit runs `--exec-controls none` plus
`CONTROL=<name> tests/<gate>.sh` for every declared control of a gate the
commit adds or changes; the session close ran the default `all` until #269 (below). The
condition, the cost and the revisit clause: `DECISIONS_HISTORY.md` "Ruled
2026-09-14 (14z-154)". **Since #269 (14z-200; ruled 2026-10-12, the tier
turned around)** the session close runs `--strict --confirm <the previous
close's results.tsv>`: it RE-RUNS the gates whose followed paths changed
(`tools/static_confirm.py`), the `# CONFIRM: always` core, any gate absent from
the base or not PASS there, and any gate whose controls the base did not
execute, while a CARRIED gate keeps the control counts of the run it is carried
from. **Since #286 (c) and #298 (14z-202, narrowed 14z-205; ruled 2026-10-15 and
2026-10-18)** a re-run gate EXECUTES its controls only when it is absent from the
base, not PASS there, its base controls were not all executed, or a PROGRAM of
its reach changed (R1: its script, a library it sources, a runner or tool it
calls, a module it imports); re-run for a data change alone, it carries them.
Measured (#298) on the five closes from 14z-205 to 14z-207, whose recorded
tiers differ by base: 14z-205's is based on that sitting's own tier 2, 14z-205b's
and 14z-205c's on their own earlier passes (11 controls in 180 s; 19 in 71 s;
the earlier passes kept no controls file), 14z-206's on its own whole tier,
and 14z-207's, the only one, on the previous close's run. The 14z-205 close
executed 143 controls in 1,448 s and the 14z-207 close 161 in 3,941 s, against
1,500-1,800 s of controls at a close before the rule; in both `test_static_runner` re-ran with every
control, the runner's own cost (871 s over 14; 3,172 s over 23, the gate absent
from the 14z-206 base), and without it 129 controls in 577 s and 138 in 769 s
(`build/agent205/close/`, `build/agent207/close/tier_results.controls.tsv`,
local). The 14z-206 close records no figure under the rule: its tier of record
was the whole tier without `--confirm` (#313), and the `--confirm` run based on
it kept a controls file byte-identical to that run's. Control SECONDS are not
load-normalised: the 14z-207 controls ran in #312's pools, the portable tier's
with 7.1 of 8 slots busy on average and the static tier's with 3.1, and one
portable-tier control (`test_emulator_staleness` `keys-ignored`) took 48 s there
against 18 s at 14z-205; the load-free figure is the COUNT executed (161, 214
carried). The 14z-207 tier's wall, 832 s against those 3,941 s, is #312's pool,
which runs controls as jobs of their own. A freeze and a release still run every
gate and every control (`--confirm` is refused at their cadence). Ground
truth: `tests/test_static_runner.sh` sections 18-23 (22-23 the controls rule,
controls `controls-always` and `controls-never`).

`tests/run_all_emulator.sh` reads every block on every run and executes the
controls only under `--controls` (one more run per declared name; its rows are
`<gate>@<name>` with PASS = honoured, in the tally and under `--strict`). It is
off by default because it multiplies a tier measured in hours; RULED
2026-09-10 (maintainer, 14z-148): it is part of every RELEASE run, not of the
freeze sweep (HANDOFF "THE EMULATOR-TIER COMMAND" carries the invocation). Ground
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
