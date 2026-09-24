# The gate header contract — what a gate DECLARES about itself, and who reads it

> **STATUS: REFERENCE (opened 14z-180, GitHub #171).** The declarations a gate script
> carries in its LEADING COMMENT BLOCK beside the must-fire lines, each with one reader
> and one census. Today: the DESCRIPTION (`# WHAT:` / `# HOW:` / `# EXPECTS:`, slice Q0,
> ruled and live). Ruled and NOT YET BUILT: `# FOLLOWS:` (slice Q3) and `# MEASURES:`
> (slice Q2); their sections say so. The must-fire contract has its own document
> (`must_fire_contract.md`, a copy of BBX's grammar) and is not restated here.

## Why the header

The maintainer ruled (14z-123) that a gate's WHY lives in the gate; `tools/gen_gate_index.py`
renders each script's header into the GENERATED gate index instead of a hand-written fence.
Every declaration below follows that rule: it sits beside the code it describes, so a change to
the gate and to its declaration are one diff and one review, and it is read by ONE reader that
the index and the census both import — two parsers would drift.

**The leading comment block** is every `#` line after the shebang up to the first non-comment
line; a bare `#` continues it (the must-fire reader's definition, BBX R30).

## The description — `# WHAT:` / `# HOW:` / `# EXPECTS:` (slice Q0, live)

**The ruling (2026-09-24, verbatim):** *"I want for each test a human-readable description of
the test (at least what it tests, how it tests and what is the expected result). The rationale
for this is human supervision: you have done remarkably well on your own but at the moment there
are many tests that may of may not be practically correct or relevant in a way that is invisible
to you. Furthermore, this allows me to know the functional coverage that we have, not just the
technical one. That human supervision may require further work and tickets but the qualification
of the tests should be the foundation"* — and, on the form: *"That form, first, by family"*.

**The grammar**, read by `tools/gate_descriptions.py`:

```
# WHAT: <what the gate tests — the property, in the game's or the tree's terms>
# HOW: <how it tests it — the legs, the instrument, the rig, the compare>
# EXPECTS: <the expected result, and what a red means>
```

- Each field starts at column 0 as `# NAME:`, spelled exactly, once, in this order, inside
  the leading comment block.
- A field CONTINUES on following lines that are `#` followed by at least two spaces
  (`#   the rest…`); it ENDS at the next `# NAME:` line, a bare `#`, or a `#` line with a
  single space.
- A gate DECLARES when all three are present, in order and non-empty; anything else is
  UNDECLARED with a reason (missing, empty, duplicate, out of order, outside the block).

**Written by READING the script**, never from its name, its registry note or its family: the
description is for a reader who has not opened the script, and its value to the maintainer is
that it can be WRONG in a way a gate cannot tell — that is what the review is for. Say what is
compared with what, on which leg, and what a red means in the game's terms where the gate has
them.

**Who reads it.** `tools/gen_gate_coverage.py` renders the three fields per family into the
GENERATED `gate_coverage.md`, "What each gate tests", the functional-coverage view (one entry per
gate; gates without them named at the family's end so the remainder is on the page; the site
renders it as `docs/site/project/gate_coverage.html`). The technical index `gate_index.md` is left
exactly as the generic harness renders it (bbh's fidelity gate F9 requires byte-identity). `tests/test_gate_descriptions.sh` freezes the census
in `tests/expected/gate_descriptions.tsv` — `declares` grows only, `undeclared` shrinks only —
with two controls (a dropped field; the fields moved outside the block). The retrofit lands by
FAMILY, each family's rendered page put to the maintainer as it lands.

## `# FOLLOWS:` — the paths a gate's verdict depends on (slice Q3, RULED, NOT BUILT)

Ruled 2026-09-24 (*"Header line"*): `# FOLLOWS: <repo path prefixes>` on every emulator-tier
gate, its own script implied; one reader; a census (declares grows only) and a RECONCILIATION
control — the paths the script's text references (`tests/replays/…`, `tests/expected/…`,
`tools/<x>.py`, `build/manifest`, plus the registry row's `args`) must each be covered by a
declared prefix. `tools/audit_lane_carry.py` then derives a lane's subjects from these. The
staleness gate of slice Q4 reads them against the newest recorded emulator run. Spec:
`gate_qualification_scope.md` §4 Q3-Q4.

## `# MEASURES:` — a measurement that must not be empty (slice Q2, RULED, NOT BUILT)

Ruled 2026-09-24 (*"Declared/fired grammar"*): `# MEASURES: <name> — <floor>` in the header and
`MEASURED: <name> = <n>` at run time; the runners' reader turns a PASS whose declared measurement
is absent or below its floor into FAIL, as a declared control that did not fire does; no change to
the four verdicts. Spec: `gate_qualification_scope.md` §4 Q2.
