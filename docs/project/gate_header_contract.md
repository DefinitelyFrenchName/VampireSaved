# The gate header contract — what a gate DECLARES about itself, and who reads it

> **STATUS: REFERENCE (opened 14z-180, GitHub #171).** The declarations a gate script
> carries in its LEADING COMMENT BLOCK beside the must-fire lines, each with one reader
> and one census. Today: the DESCRIPTION (`# WHAT:` / `# HOW:` / `# EXPECTS:`, slice Q0,
> ruled and live), `# FOLLOWS:` (slice Q3, live) and `# MEASURES:` (slice Q2, live). The must-fire contract has its own document
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

## `# FOLLOWS:` — the paths a gate's verdict depends on (slice Q3, live)

Ruled 2026-09-24 (*"Header line"*). On every emulator-tier gate (every `tests/ci_emulator.tsv`
row), one field, in the leading comment block:

    # FOLLOWS: <prefix> <prefix> ...
    #   <prefix> ...                      (continuation: `#` + at least two spaces)

Each token is a repo-relative PATH PREFIX in `tests/ci_cadence.tsv`'s sense — a directory
(`tests/replays/`), a file (`tools/run_replay_mame.sh`) or a stem (`tools/gen_`); a directory
prefix also covers the bare path (a submodule pointer such as `emu/fbneo` moves as the bare
path). Two paths are IMPLIED and never written: the gate's own script and
`tests/ci_emulator.tsv`. A gate DECLARES when the field is present once with at least one
token.

**The one reader** is `tools/gate_follows.py` (it imports the leading-block definition from
`gate_descriptions.py`, so the two fields cannot disagree about where a header ends). It also
extracts what a gate's TEXT references: every `tests/…`, `tools/…`, `docs/…`, `emu/…`,
`build/manifest…` token in a non-comment line of the script and, transitively, of the RUN-TIME
HARNESS it reaches — the `tests/lib/*.sh` it sources and the `tools/run_*.sh` / `tools/tap_*.sh`
runners it calls (not the build chain, whose subject is the romset) — plus its registry row's
`args`. A reference composed from a variable is cut at the variable, so `tests/replays/$r.rpl`
demands a declaration at least as wide as `tests/replays/`; untracked build outputs are not
references.

**The reconciliation** (`tests/test_gate_follows.sh`, ci_portable) has THREE classes, and a
declaration must satisfy all of them. TEXT: every reference must be COVERED by a declared prefix
— a declaration may be wider than the text shows but never narrower than what the script
demonstrably reads. RULE: the WIDENING RULES the reader carries (`gate_follows.required`) name
what a gate follows beyond its text, and the declaration must carry them — the emulator's patch
directory and setup script for the emulator the gate reaches (through the harness runners or
`MAME_BIN`; a gate that runs a bare `mame` from PATH, `test_decrypt_oracle` and
`test_patch_prg`, reaches no binary this tree builds and is not widened), `build/manifest/` for
a gate that takes or builds a romset, the core sources for the MiSTer lane, the rig generator
for a generated rig. PROSE: every replay the gate's own `# WHAT:` / `# HOW:` names (by number or
stem) must resolve to a covered file — an INDEPENDENT extractor, because the text class checks
the extractor against itself (a path the regex cannot see is absent from both sides and they
agree; rule-checker run `2026-09-24-142`, Q3): the description was written by reading the gate,
so it is the second witness. The same gate freezes the census
(`tests/expected/gate_follows.tsv`: `declares` grows only, `undeclared` shrinks only) and runs
two controls (a dropped declaration, a narrowed one). **Who reads the declarations:**
`tools/audit_lane_carry.py` derives a lane's carry subjects from them (an undeclared gate makes
the lane MUST RE-RUN by construction; ground truth `tests/test_lane_carry.sh`), and
`tests/test_emulator_staleness.sh` diffs them against the commit the newest emulator run
recorded (`build/emu_*/commit.txt`). Spec: `gate_qualification_scope.md` §4 Q3-Q4.

## `# MEASURES:` — a measurement that must not be empty (slice Q2, live)

Ruled 2026-09-24 (*"Declared/fired grammar"*). A gate that compares a PRODUCED table (a hashed
body, a frozen row set) declares what it measures and a floor, and prints the measurement:

    # MEASURES: <name> — <floor> <what the number counts>       (header; name [a-z0-9-]+, floor an integer)
    MEASURED: <name> = <n>                                       (run time, column 0)

**The one reader** is `tests/lib/measures.sh` (`vs_meas_declared`, `vs_meas_read`), sourced by
`tests/lib/classify.sh`: on a PASS, after the controls read, a declared name that was not printed,
a value below its floor, or a printed name no header declares turns the verdict into plain FAIL —
no fifth verdict, exactly as a declared control that did not fire does. A gate declaring nothing is
untouched. Ground truth `tests/test_measures_contract.sh` (two known-bad controls). **Why:** at the
M19 release tier two gates measured 0 rows and compared an empty table whose sha256 is the hash of
the empty string, and every close for four days was green — a hash says the table is the frozen
one, nothing said it had anything in it. **The surface (14z-180):** the hashed-table gates —
`test_charmap_current` (the anim pages' rows), `test_meter_gain` (the meter table's rows),
`test_vanilla_frame_join` (the slot map's and the hit-damage body's rows), `test_release_binaries`
(the BINARY.txt rows verified), `test_release_os_metadata` (the zip members read back); of the
seven the scope's text heuristic named, `test_build_environment_entry` and `test_release_roundtrip`
compare no produced table (a synthetic record's stub hash; release records whose files may be
absent by ruling) and declare nothing. A floor is the count at the freeze it was written against,
and is lowered only by a reviewed edit; `test_release_binaries`' floor is STRUCTURAL (one row per
record, which the gate already enforces) and its header says so — its MEASURED value is the
reviewable figure. **The freeze guard** (`vs_meas_guard <script> <name> <n>`, rule-checker run
`2026-09-24-143`): under `FREEZE=1` a gate hands its measurement to the guard BEFORE writing the
frozen file, and a value below the floor prints `REFUSED FREEZE:` and returns 1 — the M19 shape was
not a red table but a FROZEN empty one, and a reader over the run cannot stop a freeze. Every
freezing gate on the surface calls it; `test_charmap_current`'s control `empty-page-frozen` runs the
shape on a real gate (one page emptied after generation, `FREEZE=1` against a scratch copy of the
hashes: refused). **Two witnesses for a floor:** the count the gate prints and a count of a DIFFERENT
file by a different expression (the frozen row set, the record's own text, the out-of-tree copy) —
the first alone agrees with itself by construction. Spec: `gate_qualification_scope.md` §4 Q2.

