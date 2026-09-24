# GATE QUALIFICATION — scope, before the work (GitHub #171)

> **STATUS (14z-180, 2026-09-24): SCOPED, MEASURED AND RULED — SEVEN SLICES, Q0 ADDED BY
> THE MAINTAINER AT THE HEAD; Q1 LANDED THIS SITTING.** The four failure shapes the M19
> release tier exposed were re-measured against the tree at `97d84268` (§1); what already
> exists for each is listed with what it does not cover (§2, §3); the six proposed slices
> (§4, §5) were ruled *"As proposed WITH THIS ADDITION"* — a human-readable description in
> every gate (§4 Q0, the maintainer's words in §6) — and the six questions of §6 were each
> answered (`DECISIONS_HISTORY.md` "Ruled 2026-09-24 (14z-180) — #171 gate qualification").
> Order: **Q0, Q1, Q3+Q4 (Q5 inside), Q2, Q6.** Q1's gate is `tests/test_module_refs.sh`.

**Why this document exists:** the same reason `harness_scope.md`,
`applier_app_scope.md` and `agent_architecture_scope.md` do — a direction the
maintainer ordered, wide enough (199 emulator-tier gates, 174 static gates) that
starting it blind would waste sittings, with design questions that are the
maintainer's to rule. The ticket is the story (#171, [VSP-182]); this is the plan.

**The ask (maintainer, 2026-09-22), verbatim from the ruling that opened the ticket
(`DECISIONS_HISTORY.md` "Ruled 2026-09-22 (14z-174)"):**

> *"Option 1 and ticket to qualify all gates in the future because either the gates
> are moving silently or they never were validated and in both cases that's a lot of
> both uncertainty and wasted time"*

The ticket's own definition of "qualified" is a PROPOSAL, not a ruling — *"the shape
is the maintainer's to set"*. This document measures each part of that proposal
against the tree and turns it into slices the maintainer can accept, reorder or
strike.

## 1. THE FAILURE, MEASURED

**What happened — every figure in this table is the RECORD's, not a measurement of this
sitting:** the 14z-174 session row (12) (`STATE_HISTORY.md` line 293, cut verbatim into
`build/gatequal180/sources_14z180.txt`), the ruling of that day
(`build/gatequal180/ruling_14z174.txt`) and the ticket's own text
(`build/gatequal180/issue_171.txt`). The M19 release run of the emulator tier came back
`PASS 275, SKIP 1, FAIL 8, TIMEOUT 1` after 6 h 24 min, and none of the eight reds was a
defect in the romset. Four shapes:

| shape | what it was | how long it hid |
|---|---|---|
| **1 — a gate that cannot run passes** | `tools/vanilla_join_rig.py` referenced `name_moves.PROLOGUE`, deleted at `e01ae8de` (2026-09-17). Three gates died at 0 s on `AttributeError`; two measured **0 rows** and compared an empty table whose sha256 is the hash of the empty string | 2026-09-17 to 2026-09-22: "Four days, nine sessions" in the record, every close GREEN |
| **2 — an expectation stale behind a rig that moved** | three frozen tables (killshread, reaction_class_live, defense_row_reads) left behind by rig changes at 14z-171 and 14z-172; the gates' substantive assertions still passed, only the recorded tables drifted | the same window; nothing connected "the rig moved" to "these consumers must re-run" |
| **3 — a control killed by its own timeout** | `test_release_binaries@flipped-library-byte` capped at 300 s (a quiet-machine number); the gate alone takes 234 s under `--jobs 4`, the control 210 s standalone | every release run since the control was written; the control had never run |
| **4 — a column that reads the rig's own poke back** | `tools/name_moves.py:802` pokes `ff8509 := 09` before every event; `tests/test_killshread_es.sh:50` samples `ff8509` as the `stock` column, so the ES-versus-normal stock-drop discriminator ([VSP-170]) is neutralised in that rig | since the rig gained the per-event poke (14z-171); found by the rule-checker (run `2026-09-22-91` Q3), not by the gate |

**The common factor**, stated in the ruling: **the emulator tier runs only at a freeze
or a release**, so breakage accumulates between sweeps and surfaces during the most
expensive run there is.

**What the tree shows today (14z-180, measured by five `measurer` workers from specs —
every FIG line and every command in `build/gatequal180/measurer_returns_14z180.txt`; one
worker figure was wrong and is corrected there; the defaults and header lines the
table leans on are cut into `build/gatequal180/sources_14z180.txt`):**

| question | figure | command |
|---|---|---|
| cross-module Python references (`tools/*.py` + `tests/**/*.py` into `tools/` modules) | **270 references over 108 (file, module) pairs, 174 files, 161 modules; every one resolves today**, above a floor of 1 | `tools/audit_module_refs.py` (E/C2; A/C2 on the first form) |
| does the instrument catch the historical case, AS WRITTEN? | the caller as it stood at `e01ae8de^` (its line 110, `name_moves.PROLOGUE.rstrip()`) is parsed through the same extractor and the reference is reported unresolved, exit 1 — the first form appended the tuple after parsing and proved only the resolve step (rule-checker run `2026-09-24-141` Q4) | `--plant` (E/C3, E/C6) |
| is an empty census a pass? | no: 0 references over 0 files fails the floor, exit 1; and 270 against a floor of 271 fails | `--plant-empty`, `--floor 271` (E/C4-C5) |
| gates that compare a produced table by sha256 | **7**; 6 mention a row count somewhere, 1 does not (`test_build_environment_entry`) — a text heuristic, not a verdict | A/C4-C6 |
| emulator-tier registry rows | **199**, every row's script present | B/C1, B/C8 |
| rows whose `args` name a path | **1** (`test_mister_gfxc_fetch`, a replay); 2 more carry `%MERGED%` | B/C2-C3 |
| emulator gates whose script names `tests/replays` / `tests/expected` / `tools/*.py|sh` / `build/manifest` | **189 / 63 / 197 / 31** of 199 | B/C4-C7 |
| what the emulator runner records about the commit it ran on | **nothing**: `results.tsv` is `gate lane scope verdict seconds detail`; the runner snapshots `git status` before and after (a tree-clean check), never `HEAD` | B/C9-C10 |
| a trigger notion in the emulator runner | **0 mentions**; the static tier's `tests/ci_cadence.tsv` has 17 rows with path triggers | B/C11-C12 |
| files under `tests/expected` vs distinct `tests/expected/…` paths named by gates | **5,270 files; 95 paths named** (the sets are per-build directories) | B/C14-C15 |
| `tests/expected/PROVENANCE.md` | **63 file rows** (136 non-comment lines, prose included), each row carrying an `owner gate` column — for FILES directly under `tests/expected/` only | E/C7 (B/C16 counted lines, not rows) |
| `tools/audit_lane_carry.py mister --since 97d84268` on the unchanged tree | MAY CARRY, exit 0, printing its two known omissions | B/C13 |
| the 2026-09-22 release run: gate rows / control rows / verdicts | **190 / 92 / PASS 281, SKIP 1**; gate seconds 18,303 (5.1 h serial), control seconds 6,631 | C/C1-C3 |
| headroom against timeouts on that run | **no gate and no control at or above half its timeout**; the closest is `test_release_binaries` 342 s of 900 (0.38) and its control 325 s (0.36) — AFTER the 300 -> 900 fix | C/C3 |
| rows with an explicit timeout | **14** (9 MiSTer, 5 at 900 s); the other 185 rows have six columns and take the runner's default, `TMO=5400` (`run_all_emulator.sh:114`, `ci_emulator.tsv:16`) | C/C5-C6, re-derived; `sources_14z180.txt` |
| emulator-tier run directories under `build/`; the newest | **31**; `emu_sweep_20260922_111835` — no run since, **6 sittings** (14z-175..180) | C/C7-C9 |
| gates that poke / that sample / that do both | **109 / 79 / 46** (by the mechanism tokens `POKES= POKE= FBNEO_HPOKE` and `DUMPS= FBNEO_DUMPS FBNEO_HTAP WATCH=`) | D/C1-C4 |
| addresses `tools/name_moves.py` pokes, and how many gates read each | `ff8410` 20, `ff8509` 35, `ff8782` 99, `ff8810` 17, `ff8850` 33, `ff8b82` 62 | D/C5-C6 |
| gates driven by the naming rigs; of those, reading `ff8509` | **27; 4** (`audit_df_moves`, `audit_move_parity`, `test_killshread_es`, `test_move_naming`) | D/C7-C10 |

What these figures say, shape by shape: (1) the extractor finds the historical reference
in the file that carried it, and resolves every reference the tree carries today — so
the same check, in the session tier, would have gone red on 2026-09-17 rather than at
the release; the empty-table half has a small surface (7 gates) but no class in the verdict
vocabulary. (2) Almost every emulator gate follows replays and tools, a third follows
frozen expectations, and NOTHING records which commit a gate last passed on or which
paths it follows — so staleness is undetectable by construction, not by oversight.
(3) The one measured breach is fixed and the run shows headroom everywhere; the gap is
that nothing CHECKS headroom, so the next quiet-machine number will hide the same way.
(4) The read-back surface is 46 gates that both poke and sample, and 4 naming-rig
gates that read the stock byte the generator pokes; only one of the four is known to
be a read-back, the other three are UNMEASURED.

## 2. WHAT EXISTS

- **The verdict classifier** (`tests/lib/classify.sh`, one copy): exit status first;
  exit 0 with the shell's own error line is FAIL ([VSP-176]); SKIP is exit 0 plus the
  marker. It cannot see a 0-row table — that is a number inside a PASS.
- **The must-fire contract** ([VSP-181], `docs/project/must_fire_contract.md`): a
  control is DECLARED in the header, FIRED at run time, EXECUTABLE as a mode; the
  runners read it, the census freezes three classes. It is the grammar this document
  proposes to imitate, not extend — a second header grammar with its own reader keeps
  the two contracts independent.
- **The static tier's cadence** (`tests/ci_cadence.tsv`, 14z-162, #148): a gate
  declares the path prefixes it follows and runs when any of them changed since
  `origin/main` or in the working tree. Exactly the mechanism shape 2 needs, for the
  static tier only.
- **The provenance register** (`tests/expected/PROVENANCE.md`, `test_expectation_provenance.sh`):
  one row per FILE under `tests/expected/`, with its `owner gate`, `subject`, `rests
  on`, `re-freeze` command. It is the consumer map for the 63 files it covers; the
  per-build expectation SETS are covered by `registry.tsv` and the freeze tags instead.
- **`tools/audit_lane_carry.py`** (14z-174): may a lane's green be carried forward?
  Hardcoded subject lists, two known omissions, its `MAY CARRY` printing the caveat —
  NECESSARY, NOT SUFFICIENT (the ticket's first comment).
- **`tools/attribute_expectation.sh`** (14z-174): a red expectation attributed to the
  rig or the subject by restoring named paths and re-running — the triage tool once a
  staleness is found, not the detector.
- **`tools/audit_module_refs.py`** (14z-180, this scope's census instrument,
  UNTRACKED): every cross-module name resolved by AST at module top level, scope-aware
  for shadowed aliases; two controls — `--plant` parses the historical caller
  (`git show e01ae8de^:tools/vanilla_join_rig.py`) through the extractor and must report
  its reference, `--plant-empty` runs the census over no files and must fail the floor.

## 3. WHAT IT DOES NOT COVER

| shape | the gap, precisely |
|---|---|
| 1a | no static check resolves a Python name across `tools/` modules; a deleted symbol is found when the emulator gate runs, which is at a freeze or a release |
| 1b | a gate whose measurement produced 0 rows and whose compare therefore passed trivially is a PASS with a small number inside it; no runner, classifier or control reads that number |
| 2 | no emulator gate declares what it follows; the runner records no commit; `results.tsv` has no `HEAD`; so "did any input of gate G move since G last passed" cannot be asked of the tree at all |
| 2 (carry) | `audit_lane_carry.py` cannot derive its subjects, so it cannot reconcile them against the registry — the control the ticket's comment names as "the substance of the fix" |
| 3 | timeouts are set by a rule in `ci_emulator.tsv`'s header (measured × ~1.5) that nothing checks after the fact; a run's own `seconds` column is never compared with the row's cap |
| 4 | no census relates what a gate's rig POKES to what the gate SAMPLES; the one known read-back is labelled by hand in its header and in PROVENANCE (14z-174's Option 1) |

## 4. THE RECOMMENDATION — MAKE EVERY GATE DECLARE WHAT IT FOLLOWS, THEN LET THE TREE ASK THE CHEAP QUESTIONS EVERY SESSION

**The principle:** the emulator tier cannot run every session (5.1 h of gates serial
on the release run), but every question in §3 except the read-back census is a
STATIC question about the tree — a name resolves or not, a table has rows or not, a
path moved since a commit or not, a duration sits under a cap or not. Static
questions belong in the session-cadence tier, where they cost seconds and run at
every close. The one real-time question (which gates ARE stale) then names the
emulator gates a session should re-run, so the expensive tier is exercised WHERE IT
MOVED, between sweeps, rather than all at once at a release.

### Q0 — every gate carries a human-readable description (the maintainer's addition, ruled first)

Three fields in every gate's leading comment block, each on its own line and spelled
exactly: `# WHAT: <what it tests>`, `# HOW: <how — the legs, the instrument, the rig, the
compare>`, `# EXPECTS: <the expected result, and what a red means>`. Written by READING
each script, never from its name or its registry note; one reader beside the must-fire
reader; `tools/gen_gate_coverage.py` renders the three fields per gate, grouped by family,
into the GENERATED `docs/project/gate_coverage.md` (its own page, because bbh's fidelity
gate F9 renders `gate_index.md` byte-identically with a lifted copy of the index
generator) — that rendered page is the functional-coverage view the maintainer reviews,
family by family, as each batch lands. A census
(`tests/test_gate_descriptions.sh`) freezes `declares` (grows only) against `undeclared`
(shrinks only), the must-fire census's pattern, so a description cannot be dropped and
the retrofit's progress is a number. 377 scripts. The maintainer's rationale, verbatim,
is in §6 (1): supervision of whether a test is *"practically correct or relevant in a way
that is invisible to you"*, and knowing *"the functional coverage that we have, not just
the technical one"*.

### Q1 — the module-reference gate (shape 1a) — LANDED

Landed at the 14z-180 sitting on *"Land it now"*. `tests/test_module_refs.sh` (ci_portable, seconds) runs `tools/audit_module_refs.py`
with `--floor` pinned to the frozen reference count; its must-fire controls are the
`--plant` mode (the historical caller parsed, its reference reported) and the
`--plant-empty` mode (an empty census fails). Grow-only: a new unresolved reference is a
red, never a widened allowance, and the floor only rises.
The tool is built and measured (§1); the slice is its gate, its `doc_shape`/HANDOFF
rows and the census freeze.

### Q2 — an empty measurement is a verdict (shape 1b)

A second declared/fired pair beside the must-fire contract, with its own reader and no
change to `classify.sh`'s four verdicts (the 14z-139 rule): a gate that compares a
produced table declares `# MEASURES: <name> — <floor>` in its header and prints
`MEASURED: <name> = <n>` at run time; the runners' reader turns a PASS whose declared
measurement is absent or below its floor into FAIL, exactly as a declared control
that did not fire does. Surface: the 7 hashed-table gates first (the two that measured
0 rows at 14z-174 are among them), then any gate that freezes a table. Alternative,
cheaper and weaker: a floor assertion inside each of the 7 gates and a census that
they have one — no grammar, no reader, but nothing stops the 8th gate omitting it.
**Recommended: the grammar** — it is what made the must-fire contract stick.

### Q3 — every emulator gate declares what it FOLLOWS (shape 2, and the carry)

A header line `# FOLLOWS: <repo path prefixes>` on every emulator-tier gate (its own
script is implied, as `ci_cadence.tsv` implies it), read by one reader
(`tests/lib/follows.sh`). Two static gates: a CENSUS (`declares` grows only,
`undeclared` shrinks only — the must-fire census's three-class pattern) and a
RECONCILIATION control: the paths a gate's script TEXT references (`tests/replays/…`,
`tests/expected/…`, `tools/<x>.py`, `build/manifest`, plus its `ci_emulator.tsv`
`args`) must each be covered by a declared prefix, or the gate is red — so a
declaration cannot be narrower than what the script demonstrably reads. Then
`audit_lane_carry.py` DERIVES a lane's subjects as the union of its gates' FOLLOWS
plus `tests/ci_emulator.tsv` itself, deletes its hardcoded lists and known-omissions
table, and gains the control the ticket asked for: a gate whose declaration is not
covered by the derived set fails the carry. Alternative: a `follows` COLUMN in
`ci_emulator.tsv` instead of a header line. **Recommended: the header** — a gate's
WHY lives in the gate (the 14z-123 ruling), and the registry row is already six
columns wide.

### Q4 — the runner records its commit; a session gate names STALE emulator gates (shape 2)

`run_all_emulator.sh` writes `HEAD` (and the dirty-tree state it already snapshots)
into the run directory as `commit.txt`, and every `results.tsv` row gains nothing —
the commit is per run. A new session-cadence static gate,
`tests/test_emulator_staleness.sh`, reads the NEWEST run under `build/` (or the
freeze's recorded run, once a freeze records one) and, for every emulator gate that
PASSED there, diffs its FOLLOWS since that commit: every gate with a moved input is
named STALE. What the verdict is at each cadence is the maintainer's (§6): the
recommendation is a NOTE-class line at session cadence (the list is information a
session acts on) and a FAIL at freeze and release cadence (a freeze or release runs
the tier anyway, so a stale list there means the run was not on the commit it
should have been). And the actionable half: `run_all_emulator.sh --stale` runs
exactly the gates that gate names, so a session can retire its staleness in minutes
instead of carrying it to the release. Shape 2 at 14z-174 would have read: "3 gates
stale since 14z-171" at the 14z-171 close.

### Q5 — headroom is checked, not assumed (shape 3)

The same staleness gate reads the newest run's `seconds` against each row's cap (the
7th column or 5,400) for gates AND controls (a control shares its gate's cap), and
fails any row at or above **half** its cap — the release run's own contention roughly
halved the 300 s control's headroom, and a 0.5 ratio is where a measured number stops
being a safe cap. The current run has none (max 0.38). A control mode plants a
`seconds` value above the threshold into a copy of the results.

### Q6 — the poke read-back census (shape 4)

`tools/audit_poke_readback.py`: for every gate, the ADDRESSES its rig pokes (resolved
through `name_moves.py`'s schedule for the 27 naming-rig gates; the `POKES=`/`POKE=`/
`FBNEO_HPOKE` tokens for the rest) intersected with the addresses it SAMPLES or asserts
(`DUMPS=`, `FBNEO_HTAP`, `WATCH=`, the columns its reducers read). Every intersection
is a finding: a value poked BEFORE the event and read AFTER it can be a legitimate
observation (the poke sets the stage, the game changes it, the gate measures the
change), so the census reports (gate, address, poke frame, sample frame) and a human
classifies each as OBSERVES / READS-BACK. A READS-BACK column is either dropped from
the compare or labelled in the header and PROVENANCE as a rig record (Option 1's form,
generalised). Frozen as a table under `tests/expected/`, grow-only for OBSERVES,
shrink-only for READS-BACK; its gate re-derives the intersections. This is the one
slice that needs the maintainer per finding, because dropping a column changes what a
gate claims.

## 5. THE SLICES — each landed only with its gate

| slice | what | the gate that proves it | cost |
|---|---|---|---|
| **Q0** | `# WHAT:` / `# HOW:` / `# EXPECTS:` in every gate's header; the reader; the coverage page rendering them per family; batches by family for the maintainer's review | `tests/test_gate_descriptions.sh`: the census (declares grows only, undeclared shrinks only), a control dropping one field from a copy must FAIL, a control with the fields outside the block must FAIL; `tests/test_gate_coverage_current.sh` holds the page to the headers | several sittings — 377 scripts read one by one, the reading being the point |
| **Q1** | `tools/audit_module_refs.py` (built) + `tests/test_module_refs.sh` | the gate itself, controls `planted-prologue` (the `--plant` mode) and `empty-census` (`--plant-empty`), the floor frozen | one sitting's hour |
| **Q2** | the MEASURES/MEASURED grammar, its reader, the runners reading it, the 7 gates declaring | `tests/test_controls_contract.sh`'s twin for the new reader; a control where a declared measurement is missing and one where it is below floor; the 7 gates' own controls unchanged | a sitting |
| **Q3** | `# FOLLOWS:` on 199 gates, `tests/lib/follows.sh`, the census gate, the reconciliation control; `audit_lane_carry.py` rewritten on it | the census (three classes frozen), the reconciliation control (a declaration narrower than the script's references must fail), the carry tool's control (an uncovered gate must fail the carry) | two sittings — the 199 declarations are read from each script, not guessed, and the reconciliation control is what proves them |
| **Q4** | `commit.txt` per run; `tests/test_emulator_staleness.sh`; `run_all_emulator.sh --stale` | the staleness gate over a planted run dir (a moved input must name its gate; an unmoved one must not); `test_emulator_runner.sh` gains the `--stale` selection and the commit record | a sitting |
| **Q5** | the headroom check inside Q4's gate | a planted `seconds` at 0.5 of cap must fail; the real run must not | inside Q4 |
| **Q6** | `tools/audit_poke_readback.py`, the frozen classification table, the per-finding rulings | the census gate re-deriving every intersection; the killshread `stock` column must appear as READS-BACK (the known case is the positive control) | a sitting for the census; the rulings as they come |

**Order RULED (2026-09-24):** Q0 first (the maintainer's addition — the foundation of the
supervision), then Q1 (landed this sitting, *"Land it now"*), Q3 and Q4 together (the
declarations are useless until something reads them, and the staleness gate is useless
without declarations), Q5 inside Q4, Q2, then Q6 last because it is the one that needs
rulings per finding. Q3 is the largest and the one the ticket's comment already names as
the substance of the fix.

## 6. THE RULINGS — RULED, verbatim in `DECISIONS_HISTORY.md`

Ruled 2026-09-24 at the 14z-180 sitting; the entry is `DECISIONS_HISTORY.md` "Ruled
2026-09-24 (14z-180) — #171 gate qualification".

1. **Is this the shape of "qualified"?** — *"As proposed WITH THIS ADDITION: I want for
   each test a human-readable description of the test (at least what it tests, how it
   tests and what is the expected result). The rationale for this is human supervision:
   you have done remarkably well on your own but at the moment there are many tests that
   may of may not be practically correct or relevant in a way that is invisible to you.
   Furthermore, this allows me to know the functional coverage that we have, not just the
   technical one. That human supervision may require further work and tickets but the
   qualification of the tests should be the foundation"*. The form put and chosen: *"That
   form, first, by family"* — §4 Q0.
2. **Declaration form for what a gate follows** — *"Header line"*, after the pros and
   cons of both forms were put inside the question (the first asking hid them above the
   dialog: *"I don't see the pros and cons anywhere"*).
3. **The staleness verdict** — *"NOTE at session, FAIL at freeze/release"*.
4. **Empty measurements** — *"Declared/fired grammar"*.
5. **The headroom threshold** — *"Half the cap"*.
6. **May Q1 land this sitting?** — *"Land it now"*.

Still open, by design: Q6's per-finding classifications (OBSERVES / READS-BACK), which
are put to the maintainer as the census produces them.

## 7. WHAT IT WILL NOT CATCH

- A gate whose assertion is WRONG but runs and produces rows (the 14z-127 "native ==
  10" from testimony): that is the provenance register's question, not this one.
- A Python name resolved dynamically (`getattr`, `__dict__`), or a symbol reached
  from a shell gate through `python3 -c`: `audit_module_refs.py`'s docstring lists
  what it does not see.
- An input a gate reads that its script text does not name — a path built at run time
  from a variable — is invisible to Q3's reconciliation control; the declaration is
  still hand-written for it, and only a red at a run finds the omission.
- A read-back that goes through an intermediate (poke `A`, the game copies it to `B`,
  the gate reads `B`): Q6 compares addresses, not dataflow.
- A stale gate nobody re-runs: Q4 names it; running it is a session's decision, and
  the freeze and release cadences are where the name becomes a red.
