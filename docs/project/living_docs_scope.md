# LIVING DOCUMENTATION SCOPE — what "referenced, never stale, never lost" means here, and the slices that deliver it

> **STATUS (written 14z-135, 2026-09-06): THE PLAN BEFORE THE WORK.** The
> maintainer RULED at the plan stage (2026-09-06) that the effort takes ALL
> THREE forms put to them: a rendered, navigable site; routing enforcement in
> the markdown; and fact tables with provenance. It started AFTER the generic
> harness slices and the harness skill
> (`harness_scope.md` §4), by the maintainer's order of 2026-09-06: "the
> generic reusable test harness and the living documentation effort. After
> that we'll tackle the open items". Slice status is tracked in §4's table,
> updated in place. **The harness and its skill are DONE and the effort is
> RUNNING: L1 LANDED 14z-140 (2026-09-07) — its plan, ground truth and
> rulings are §8 — and L4 the rendered site is next. Each slice writes its
> own plan section (§8 L1, §9 L4, §10 L2, §11 L3) and STOPS for the
> maintainer's rulings before any tool is written, as every harness slice
> did. L4's plan is §9, written 14z-140, its nine decisions OPEN.**

Written 14z-135 as the scope of the maintainer's direction of 2026-08-24
(STATE "Decisions pending"), in their words: an effort *"not replacing your
logs, but creating a living documentation that can easily be referenced by
you or me, doesn't go stale or lost in a statistically never read file."*
The SailorMoonS project's documentation AND work discipline are the
reference; formats, document types and visualisations are to be chosen as
the best fit for THIS project rather than copied. The direction also opened
an option, explicitly a possibility to preserve and not a commitment: after
the MiSTer core, "go back to the canvas, with all the documentation, and
redo the project from the docs". This document scopes the effort; it does
not schedule the rebuild.

It is the sibling of `mister_scope.md`, `skills_scope.md` and
`harness_scope.md`. What was read in full for it: `docs/README.md` (186
lines), `docs/doc_shape.tsv` (104), `docs/doc_locks.tsv`, the eight doc
tools' headers (`tools/checkdocshape.py` 565 lines, `doc_anchor_census.py`
278, `checkdocs.py` 247, `checkskills.py` 382, `gen_annotations.py` 323,
`gen_gate_index.py` 255, `gen_gotchas_index.py` 139, `gen_skill_guide.py`
199), `tools/mk_mister_page.py`'s `--check` contract, the STATE direction
entry, `docs/project/doc_audit_14z118.md` and `inferred_claims.md` (the two
records of the last documentation pass), and the SailorMoonS reference's
`tools/checkdocs.py`, `tools/docaddrs.py`, `tools/health.sh` and its
`docs/` tree. Every number below was measured at the 14z-135 opener.

**Ground truth at the time of writing** (read the tree, not this
paragraph, once a slice lands): 66 hand-written markdown documents under
`docs/` (the generated character pages excluded), 41,597 lines; the shape
census 31 REFERENCE / 3 REGISTER / 3 LOG / 19 HIST / 3 INDEX / 7 GENERATED
/ 1 ORIENT, zero PENDING; `docs/annotations.md` 2,970 address rows
(GENERATED, address → carrier file + section, no line numbers); 19 rows in
`docs/doc_locks.tsv`; 31 manifests under `build/manifest/` (30,406 lines);
`docs/project/tables/` holds 9 documents, 4 of them GENERATED; one rendered
page exists (`mister_core.html`, gitignored, 17 figures re-derived by its
generator's `--check`) — and it stays the only DRAWN page after L4, which
renders the markdown corpus and deliberately does not absorb it (§9.8
decision 4).

---

## 1. What "living" means, split into its three problems

The direction names two problems and STATE already separates them:

1. **Staleness** — a claim that was true when written and is not now.
   Defeated by ENFORCEMENT, never by format: a number reaches a document
   only with a run that produced it; a generator's `--check` mode
   re-derives what it drew; a lock fails when two documents disagree.
2. **Being lost** — a true claim in a file nobody opens. Defeated by
   ROUTING: "if you want to know X, read Y" at every entry point, every
   synthesis document naming its journal twin and vice versa, and one
   place a reader can navigate from.
3. **Being unreadable** — a true, routed claim that is a wall of prose or a
   number in a table nobody can picture. Defeated by RENDERING: pages a
   human can browse and diagrams a generator draws from the same constants
   the gates freeze.

The maintainer's three forms map onto the three problems one to one:
routing enforcement (2), fact tables with provenance (1, and the
rebuild's precondition), the rendered site (3, and the carrier of 2).

## 2. What exists, and the one thing the SMS reference has that we do not

### 2.1 Enforcement already in the tree

| mechanism | what it catches | tool / gate |
|---|---|---|
| declared SHAPE per document; a new document must be classified at birth; session-shaped headers barred from reference material; a history twin must exist and be HIST; HIST carries no anchors; **and since 14z-140 (L1) ROUTING** — every declared document listed in `docs/README.md`'s `## Contents` with its declared shape (a directory entry counts for the members it NAMES; an `entry-point` row is exempt from Contents but must still be named in the README), and a history twin two-way | chronology re-accreting into a reference; an unclassified document; **a true claim in a document the map does not reach** | `tools/checkdocshape.py`, `docs/doc_shape.tsv`, `tests/test_docshape.sh` (`--no-pending`, 15 must-fire controls) |
| every skill rule anchored `**[PFX-N]**` at the paragraph it distils, locked both ways; a number a skill quotes must appear in a LOG; level-0/1 skills may not name a game token | a rule whose fact moved; a skill inventing a number | `tools/checkskills.py`, `tests/test_checkskills.sh` |
| the frozen anchor census (id / file / section / status) — a moved anchor is a reviewed row | an anchored paragraph silently relocated or deleted | `tools/doc_anchor_census.py`, `tests/expected/doc_anchor_census.tsv` |
| cross-document number LOCKS — every listed file quotes the canonical value; no rival value beside the key | two documents disagreeing on one number | `tools/checkdocs.py`, `docs/doc_locks.tsv` (19 rows) |
| the three GENERATED indexes regenerated in the commit that changes what they index | a stale index | `gen_gate_index`, `gen_gotchas_index`, `gen_annotations`, each with `--check`; `gen_skill_guide` for the level-0 guides |
| a rendered page whose every figure is re-derived from the constants the gates freeze; the HTML never committed | a diagram drifting from the fit it depicts | `tools/mk_mister_page.py --check` (17 figures), `tests/test_mister_page.sh` |
| a gate's header states the default its code uses; a path default must not rot | prose describing a build that is not the one measured | `test_header_defaults.sh`, `test_build_ref_rot.sh` |
| every frozen expectation names what it rests on | a number presented as measured that was testimony | `tests/expected/PROVENANCE.md`, `test_expectation_provenance.sh` |

### 2.2 Routing already in the tree

`docs/README.md`'s routing table ("IF YOU WANT TO KNOW X, READ Y", 17
rows), "The documents, by role", and the Contents list with each shape;
CLAUDE.md §5 points at the README as the map; every `engine_internals.md`
section names its atlas rows and gates; `_history.md` twins are declared
one way (live → twin) in `doc_shape.tsv`. **Measured gaps (14z-135, the
count CORRECTED 14z-140):** the Contents list was a CONVENTION —
`checkdocshape` verified only that its links resolve, not that every
declared document is listed. **FOUR were not, where this paragraph said two
until 14z-140** (§8.1 has the census): `docs/project/gate_scoping_method.md`
(the method document the port skill cites for eight rules, named NOWHERE in
`docs/README.md`), `docs/project/tables/community_crosscheck.md`,
`HANDOFF_HISTORY.md` and `docs/project/harness_hardening_history.md` — the
two HIST rows were missed because the first census looked at the buckets and
not at the HIST group. L1 lists all four and makes the completeness a CHECK.
The twin declaration is one-way in the table, though every twin's text
does name its live document today (measured: zero missing back-links, still
true at 14z-140).
`HANDOFF.md` and `docs/game/atlas/README.md` carry no routing table of
their own.

### 2.3 The SMS reference, and the difference that matters

`~/Developer/SailorMoonS/tools/checkdocs.py` re-derives documented claims
FROM THE CARTRIDGE: each check quotes the claim from the document (so an
edited document fails loudly instead of testing a claim nobody makes),
derives the same fact from the ROM, and compares; three kinds — hand-written
checks for claims worth arguing about, a registry of table structures with
shape validators, and generated doc-mention assertions; `--uncovered`
prints every documented address no check reaches. `tools/docaddrs.py` is
the address census those checks are built on. `tools/health.sh` is the
one command that answers "is this tree consistent?", with FAIL / SKIP /
NOTE — NOTE being a convention count reported and never fatal, where "a
number that moves in the wrong direction is the signal".

Ours has the health command (`tests/run_all_static.sh`), the generators'
`--check` modes, the shape lint and the locks — and the locks are the
difference: `checkdocs.py` here verifies documents AGAINST EACH OTHER. No
tool re-derives an atlas claim from the decrypted image. The 2,970 rows of
`annotations.md` are a census of where addresses are CLAIMED, not of which
claims are CHECKED. That is the enforcement gap this effort closes (§4, L3).

## 3. The measurable question behind the rebuild option

STATE's second hold: a rebuild-from-docs is unusually provable here because
the harness compares ROM BEHAVIOUR, not source — a rebuilt artifact has an
acceptance test that already exists (bit-identical to vanilla on the legacy
corpus, field-identical to the current build on tenant content). What
decides feasibility is how much of the build is DATA versus CODE: the
artifact encodes hundreds of measured facts (reconciliation rows, planted
tripwires, pc-rel escapes, the re-point defaults, the op-count freezes), and
CLAUDE.md rule 5 already requires behavioural values to live in documented
tables. Feasibility is therefore the degree to which rule 5 has been
honoured, and that is a CENSUS, not an estimate: for every value in the 31
manifests and the generators that defines behaviour, is it in
`docs/project/tables/` with its provenance, or baked in? L2 measures it
first and moves values into tables second.

## 4. The slices

| slice | what it delivers | measured start | ends when |
|---|---|---|---|
| **L1 routing enforcement (markdown)** — **LANDED 14z-140** (2026-09-07), commits `45f116ab` the checks, `a32b9138` HANDOFF's table, `38757605` the atlas README's; the plan and its measured ground truth are §8 | `checkdocshape.py` gains two checks: README COMPLETENESS (every `doc_shape.tsv` row is listed in `docs/README.md` Contents, with its declared shape; a directory-level entry counts for the members it NAMES; a row declared `entry-point` is exempt from Contents but must still be named somewhere in the README) and TWO-WAY TWINS (a HIST twin names its live document and the live document names its twin). Routing tables at the two entry points that lack one: `HANDOFF.md` ("if you want to DO X, read/run Y") and `docs/game/atlas/README.md` ("if you want to know what ADDRESS X is, read Y"). The unlisted documents listed. | 4 unlisted docs (§8.1 — this column said 2 until the 14z-140 census); twins one-way in the table; 2 entry points without routing | the two new checks have must-fire controls on a perturbed copy (`--root`), the static tier is green, and the README lists every declared document |
| **L4 the rendered site** — **LANDED 14z-140** (2026-09-07); the plan, the census and the rulings are §9 | `tools/mk_docs_site.py`: a generated HTML site under a gitignored directory (the `mister_core.html` precedent — never committed): the landing page IS the routing table; every document rendered with cross-links resolved; an ADDRESS INDEX from `annotations.md` (address → every carrier, one click); the gate index, the gotcha index and the skill guides as pages; the two tracked images; a search box over headings, document titles and the 555 anchor IDs (client-side, no server). Markdown renderer: stdlib-only, the subset this corpus uses (headings, lists, tables, fenced code, bold/italic, links, strikethrough, blockquotes) — **measured 14z-140 over the 74 files that render** (62 hand-written + 10 GENERATED + the 2 skill GUIDEs; this row said 66 documents until then), so the subset is a census and unsupported constructs FAIL the generator rather than render wrong. A portable gate runs the generator over the tree and fails on any unresolved link or unsupported construct; the HTML is the artifact, the generator is what is reviewed. | `mk_mister_page.py` is the pattern; no site exists | `tests/test_docs_site.sh` (ci_portable) green; the maintainer has opened the site |
| **L2 fact tables with provenance** | `tools/audit_rule5.py`: the census — every behavioural value in `build/manifest/*.toml` and in the generators (damage, timings, meter, variant selection, re-point defaults, thresholds, frozen op counts) classified IN-TABLE (present in `docs/project/tables/` with provenance) / BAKED (in a manifest row or a generator constant only) / DERIVED (computed from a table at build time); the ratio reported as a NOTE-class number in the static tier first (never fatal — "a number that moves in the wrong direction is the signal"), then a gate freezing the BAKED inventory so it can only shrink. Then, value by value where the census says BAKED: a table row with provenance (measured / derived / testimony, the session, the rig), the manifest reading the table rather than carrying the value. | rule 5 honoured to an unmeasured degree; `tables/` has 9 documents | the ratio is measured and frozen; the BAKED inventory shrinks per session with a ledger |
| **L3 ROM re-derivation (the SMS `checkdocs` class)** | `tools/checkdocs_rom.py`: for atlas claims with a CHECKABLE SHAPE — the opcode word or instruction at a `PRG:` address (the disassembler already exists), a table's row count / stride / entry values, a pointer's target, a string's bytes — quote the claim from the document (assert it is still there), derive the fact from the decrypted image (`build/out/vsavj_opcodes.bin` / `_data.bin` via `tests/lib/decrypt_cache.sh`), compare; `--uncovered` lists every `annotations.md` tier-0 address no check reaches, as the coverage number. Seeded from the atlas (tier 0) first — `ram.md` claims are RAM and need the emulator, so the ROM tier is `character_tables.md`, `id_space.md`, `select_screen.md`, `sprite_lists.md`, `venue_assets.md` — then `engine_internals.md`. Static tier (needs ROMDIR), NOTE-class coverage first, then frozen. | zero claims re-derived from the image today; 2,970 address rows claimed | the coverage number is measured, reported and frozen; every hand-written check quotes its claim |

Order: **L1 → L4 → L2 → L3.** Enforcement first (STATE's own hold), and L1
is cheap; L4 next because it is what makes every document REFERENCED — the
site carries the routing and is where the maintainer reads; L2 before L3
because its census is the rebuild's precondition and it needs no ROM; L3
last because it is the largest and the one that needs the decrypted image
in the static tier.

## 5. Where the boundaries are NOT clean

1. **The site is a projection, never a source.** Every fact it shows is a
   markdown document's; editing must happen in the markdown and the gate
   must refuse a site that was hand-edited (the `gen_skill_guide` rule).
   Publishing it as a claude.ai artifact is a SEPARATE decision each time
   (rule 7: the site renders no ROM bytes, but the goldens and the address
   tables are derived work and stay within the ruling that exempts them).
2. **A markdown subset renderer is a second implementation of markdown.**
   Its census over the 66 documents is the guard; a construct outside the
   subset fails the generator loudly rather than rendering wrong.
3. **L2's classification has judgement in it.** "Behavioural value" is
   CLAUDE.md rule 5's phrase; a re-point default is not a gameplay value
   but it IS a measured fact the rebuild needs. The census classifies BOTH
   and reports them in separate columns; only the gameplay column is rule
   5's obligation.
4. **L3 can only re-derive ROM-shaped claims.** RAM claims (`ram.md`) are
   emulator facts; their re-derivation is the persistent suite (`tests/`)
   and stays there. `--uncovered` must say which class a documented address
   belongs to, so a RAM address is not reported as an unchecked ROM claim.
5. **`annotations.md` deliberately drops line numbers.** L4's address
   index links to the SECTION, as the census does; a line-level link would
   rot on every edit.
6. **The doc tools stay in this tree** (harness_scope.md §2.7): they are
   this discipline's mechanisms. Whether they become a sibling package for
   other projects is a question for after L1-L4, not before.

## 6. Decisions — taken under stated assumptions, open to veto

1. **RULED (maintainer, 2026-09-06): all three forms.**
2. **The site is generated LOCALLY into a gitignored directory** and is
   never committed. Veto → commit the rendered site (it would then need
   `--check` currency like every generated index, at ~40 k lines of HTML per
   regeneration).
3. **The renderer is stdlib-only**, a measured subset. Veto → a vendored
   markdown library (a dependency the pre-commit tier does not have today).
4. **L2 is a census before it is a migration**: the ratio is reported
   NOTE-class first and frozen second; values move into tables one at a
   time with provenance, never in bulk. Veto → bulk extraction.
5. **L3 starts at the atlas's ROM tier**, `engine_internals.md` second,
   `ram.md` never (it is the suite's). Veto → a different seed.
6. **The rebuild-from-docs is NOT scheduled by this document.** L2's
   number is what makes it decidable; the decision is the maintainer's when
   the number exists.

## 7. Cost

L1: half a session (two checks with controls, three routing tables). L4:
one to two sessions (the renderer census, the generator, the address index,
the gate). L2: one session for the census and the frozen inventory, then
open-ended ledger work at a value or two per session. L3: two sessions for
the framework and the atlas ROM tier, then open-ended coverage. Total before
the effort is "delivered" in all three forms: four to five sessions after
the harness.

## 8. L1 — ROUTING ENFORCEMENT: scope (the plan before the work)

**STATUS: LANDED 14z-140 (2026-09-07).** All six decisions were settled at
the STOP — three RULED by the maintainer, three taken as the stated default
and not vetoed — and §8.8 executed under them the same sitting: the
staleness pass, the two checks with six new must-fire controls, the seven
documents listed, and both routing tables. The rest of this section is the
plan as ruled — the per-slice shape every harness slice ran under
(`harness_scope.md` §9): measure, write the plan, STOP for the rulings,
execute in a fixed order.

L1 is §4's first row: two new checks in `tools/checkdocshape.py`, routing
tables at the two entry points that lack one, and the documents the map does
not reach, listed. It adds no new gate file — both checks live in an existing
tool that `tests/test_docshape.sh` (ci_portable) already runs, so there is no
`ci_portable.txt` row, no `gate_index.tsv` row and no HANDOFF "What exists"
row to add; what grows is the control list.

### 8.1 Ground truth (measured 14z-140, 2026-09-07)

Measured by a throwaway census over `docs/doc_shape.tsv` and
`docs/README.md`, not read off §2.2 — and it disagrees with §2.2, which is
staleness row S1 below. Re-measure at each opener; the figures date.

| figure | measured |
|---|---|
| `docs/doc_shape.tsv` rows | 69 — 33 REFERENCE / 19 HIST / 7 GENERATED / 3 REGISTER / 3 LOG / 3 INDEX / 1 ORIENT. `CLAUDE.md` has no row: `walk_docs()` walks `HANDOFF.md` plus `docs/**/*.md` only |
| hand-written documents under `docs/` | 60 — 70 `.md`, minus the three generated `tables/chars/*.md`, minus the 7 GENERATED rows |
| the `## Contents` block | `docs/README.md` lines 107-176 (70 lines): one entry per document, in four bucket groups plus an untagged HIST group, and ONE directory-level entry |
| listed in `## Contents` | **60 of the 69 rows** |
| NOT listed | **9** — five are the level-0 entry points the Contents preamble excludes by design (*"Level-0 files are the entry points above"*), **four are real gaps** |
| shape tags | 43 Contents entries carry a `**<SHAPE>**` tag and **zero disagree with the declaration**; the other 17 are the HIST group, untagged by design (19 HIST rows less the two unlisted) |
| the directory-entry model | one line: a `](game/atlas/)` link whose text names all seven members in backticks. All seven are REFERENCE, so the line's single `**REFERENCE**` tag is coherent — a rule that a directory entry's tag must equal EVERY member's class is satisfiable today |
| twins | 9 rows declare one, and **all 9 are two-way today**. Every twin names its live document in its own `# ` line (`# X — HISTORY (blocks moved verbatim from ...)`); the live side names the twin anywhere in the body (lines 4, 6, 8, 12, 14, 21, 344, 545) |
| `docs/project/tables/chars/` | 3 `.md` + 3 `.json`, generated by `tools/charmap_gen.py`, EXCLUDED by `walk_docs()` (a hard-coded prefix) and carrying no shape rows. They are DIFFERENT documents from `tables/{donovan,huitzil,pyron}.md` — the extraction manifests, which are declared GENERATED and listed |
| `HANDOFF.md` routing table | none — `grep 'IF YOU WANT' HANDOFF.md` is empty |
| `docs/game/atlas/README.md` routing table | none — 37 lines, its file list a prose paragraph naming the six subject files |

**The four real gaps:**

| document | class | where `docs/README.md` names it |
|---|---|---|
| `docs/project/gate_scoping_method.md` | REFERENCE | **NOWHERE** — and it carries `[VSP-167]`..`[VSP-174]` and sits in `tools/checkskills.py`'s `_PORT_DOCS`: a document the port skill rests on that the map does not reach |
| `docs/project/tables/community_crosscheck.md` | GENERATED | **NOWHERE** |
| `HANDOFF_HISTORY.md` | HIST | **NOWHERE** — and it is `HANDOFF.md`'s declared twin |
| `docs/project/harness_hardening_history.md` | HIST | the entry-points block above Contents; absent from the HIST group |

**The five deliberate exclusions:** `HANDOFF.md` (named backticked in "The
documents, by role"), `docs/README.md` (itself), `docs/GOTCHAS.md`,
`docs/NEXT_SESSION.md` and `docs/annotations.md` (all three linked from the
entry-points block). `docs/project/gate_index.md` is in that block AND in
Contents, so the block is not an alternative to Contents — it is prose about
five files, four of which are also listed.

### 8.2 What the two checks assert

- `check_readme_completeness(root, shape_rows)` — parse `docs/README.md`
  from `## Contents` to the next `## `; every shape row is listed there,
  with its declared shape. Messages:
  `README CONTENTS MISSING: <path> (declared <SHAPE>)`,
  `README CONTENTS SHAPE MISMATCH: <path> listed as X, declared Y`,
  `README ENTRY POINT NOT ON THE MAP: <path>`.
- `check_twins_two_way(root, shape_rows)` — the twin's text names the live
  document's basename and the live document's text names the twin's.
  Messages: `TWIN BACK-LINK MISSING: <twin> does not name <live>` and the
  reverse.

Both take `root`, as every check in the file does, so the controls run on a
perturbed COPY and never on the tree — the rule `tests/test_docshape.sh`'s
own `mkcopy` and `control` helpers already embody.

### 8.3 What counts as "listed" — the matcher, and the level-0 problem

**The matcher is not free to be loose, and that is measured.** A matcher
accepting any backticked basename anywhere produced FALSE POSITIVES on this
tree: it resolved `docs/README.md` from the atlas line's `README.md` token
and `docs/GOTCHAS.md` / `docs/NEXT_SESSION.md` from routing-table prose,
turning three rows green that Contents does not list at all. So the matcher
is the one §4 already names, and no other: **a `](path)` link target, or a
directory-level link whose SAME LINE names the member's basename in
backticks.** Under it, 60 of 69 rows resolve.

That leaves the five entry points, which Contents excludes on purpose.
Three mechanisms:

- **(a) A declared exemption.** `doc_shape.tsv`'s `requires` column is
  already a comma list (`-` × 60, `banner` × 8, `banner,atlas-rows` × 1);
  `entry-point` joins it. An exempt row need not be in Contents but MUST be
  named somewhere in `docs/README.md` (a link, or a backticked repo- or
  docs-relative path), so it is still on the map; `docs/README.md` itself is
  exempt from both in code, since a document need not list itself.
  Measured: `HANDOFF.md` passes on the backticked `../HANDOFF.md` of "The
  documents, by role"; the other three pass on the entry-points block. Cost:
  5 TSV cells, 4 Contents lines.
- **(b) Accept a listing anywhere in `docs/README.md`.** No declaration, but
  the check stops being about Contents — one mention in a routing-table cell
  would satisfy it, and Contents could rot unseen. And it is not even
  sufficient: five rows are still named nowhere, so exemptions are needed
  anyway.
- **(c) List all 69 in Contents, no exemptions.** A "Level 0 — the entry
  points" group at the top of Contents. Cost: the preamble's sentence
  changes and five files are described twice, which is what that sentence
  was avoiding.

**Recommendation, and the plan below assumes it: (a).** The exemption is
DECLARED, so it is reviewable in a diff and a new entry point must claim it
explicitly rather than inherit silence.

**One inconsistency to settle with it.** §4's row says the check covers
"every `doc_shape.tsv` row that is not GENERATED-wholesale", which reads as
the `tables/chars/` directory — generated wholesale, no shape rows. It does
NOT mean the GENERATED class: four GENERATED rows are listed in Contents
today, and `community_crosscheck.md` — a GENERATED row — is one of the two
gaps §2.2 itself names. The check therefore covers every shape row of every
class; `tables/chars/` is outside it because it has no rows (decision 2).

### 8.4 The routing tables

Both are REFERENCE-class prose: no session-shaped header, no bold paragraph
opening with a session token.

- **`HANDOFF.md`** — `**IF YOU WANT TO DO X, READ/RUN Y**` directly under
  the opening paragraph, ~12 rows, each right cell naming a HANDOFF section
  or the command itself: build a set · run a WIDE build · run the pre-commit
  · run the emulator tier · freeze a build · package a release · record a
  field report · find a gate · find a tool · regenerate an index · rebuild
  the reference emulators · run the MiSTer lane.
- **`docs/game/atlas/README.md`** — `**IF YOU WANT TO KNOW WHAT ADDRESS X
  IS, READ Y**`, ~8 rows: a `RAM:$FF8xxx` field → `ram.md`; a per-character
  table → `character_tables.md`; an id or variant slot → `id_space.md`; the
  select wheel or cursor → `select_screen.md`; a sprite list or drawer entry
  → `sprite_lists.md`; a venue asset → `venue_assets.md`; any other `PRG:`
  address → `docs/annotations.md` (generated, every carrier); the mechanism
  behind an address → `docs/game/engine_internals.md`.

### 8.5 The gate — the controls, all must-fire

`tests/test_docshape.sh` carries nine controls today (a-i), each `mkcopy` +
`sed -i.bak` + a `cmp -s` proof the perturbation applied + `control`. L1
adds six, and the count is deliberate: the two checks have four failure
messages between them, and two of the six exist to prove a mechanism cannot
wave a document through.

| control | perturbation | expected |
|---|---|---|
| j | a listed document's Contents line deleted | `README CONTENTS MISSING` |
| k | a Contents shape tag flipped | `README CONTENTS SHAPE MISMATCH` |
| l | a twin's back-link removed | `TWIN BACK-LINK MISSING: <twin> does not name <live>` |
| m | the live document's mention of its twin removed | the reverse message — the check is two-way or it is one check |
| n | a directory entry's member basename removed from its backtick list | `README CONTENTS MISSING` — the directory entry covers the members it NAMES, never the directory |
| o | an `entry-point` row's only README mention removed | `README ENTRY POINT NOT ON THE MAP` — the exemption is from Contents, not from the map |

`selftests()` in `checkdocshape.py` (23 assertions today, on a synthetic
tree) gains one per check in both directions: a clean synthetic README
passes, a perturbed one fails.

### 8.6 The staleness pass — before the checks land, one commit

Every row is a claim this tree already contradicts, found while measuring
§8.1. S1 is the one that shapes the work; S3-S5 are counts in the document
L1 edits, none of them re-derived by anything.

| # | claim | true now |
|---|---|---|
| S1 | §2.2 of this document: "two are not (`docs/project/gate_scoping_method.md` ... and `docs/project/tables/community_crosscheck.md`)" | **FOUR are** — the two HIST rows `HANDOFF_HISTORY.md` and `docs/project/harness_hardening_history.md` were missed. Corrected in place, with the [VSP-13] grep over the wording across `docs HANDOFF.md STATE.md STATE_HISTORY.md DECISIONS_HISTORY.md tests build/manifest` |
| S2 | §2.2: "the Contents list is a CONVENTION — `checkdocshape` verifies only that its links resolve, not that every declared document is listed" | true until L1 lands; the sentence becomes the statement of what the check enforces, in the same commit as the check |
| S3 | `docs/README.md`: the port skill "(`[VSP-NN]`, 161 rules ...)" | **178** rules. A count in a document nothing re-derives |
| S4 | `docs/README.md`: "304 entries across the three bucket files at the 14z-107 close: 46 game / 79 platform / 179 project" | **57 / 111 / 221 = 389** today. The figure is DATED, so it is not false — but HANDOFF's own "DOCS ARE SPLIT THREE WAYS" section dropped exactly this count because "it was stale by 25 within a few sessions". The README carries what HANDOFF deliberately does not |
| S5 | `docs/README.md`: "~195 places in the repo cite `docs/GOTCHAS.md`" | **141 occurrences across 81 tracked files** (150 for any `GOTCHAS.md` form) |
| S6 | this document's "Ground truth at the time of writing": 66 documents, `annotations.md` 2,970 rows, `tables/` 9 documents | 60 / 2,958 / 10. The paragraph is DATED and tells the reader to read the tree instead, so it STAYS as the 14z-135 snapshot; only the live claims are corrected |

### 8.7 Decisions — taken under stated assumptions, open to veto

1. **RULED (maintainer, 2026-09-07): (a) — the level-0 exemption is
   DECLARED in `doc_shape.tsv`** (§8.3): an `entry-point` token in the
   `requires` column exempts a row from Contents but still demands it be
   named somewhere in `docs/README.md`; `docs/README.md` itself is exempt in
   code. ~~Veto → (b), accept a listing anywhere in the README (weaker, and
   still needs exemptions for five rows), or (c), list all 69 in Contents
   (five files described twice).~~
2. **RULED (maintainer, 2026-09-07): `docs/project/tables/chars/*.md` get
   declared** — one `doc_shape.tsv` row each as GENERATED, and one Contents
   directory entry under `project/tables/` naming the three in backticks
   (the atlas model), which removes a hard-coded path exclusion from
   `walk_docs()` and makes a fourth tenant's page fail until it is listed.
   The `.json` files are machine files, not documents. ~~Veto → keep the
   `walk_docs()` exclusion and record the reason in the TSV header.~~
3. **TAKEN AS THE STATED DEFAULT at the STOP (2026-09-07, not vetoed): a
   directory entry's shape tag must equal EVERY member's declared class**,
   so a directory entry cannot smuggle a differently classed document in.
   Satisfiable today (all seven atlas members are REFERENCE). Veto → tag the
   directory entry only for uniform directories and skip the check
   otherwise.
4. **TAKEN AS THE STATED DEFAULT at the STOP (2026-09-07, not vetoed):
   two-way twins are a HARD failure**, not advisory — zero missing today, so
   the check costs nothing and only catches regressions. Veto → advisory.
5. **RULED (maintainer, 2026-09-07): the three uncheckable counts of
   S3-S5 are DROPPED from `docs/README.md`**, not re-derived — the rule
   count is a `grep` away and the gotcha count already has its recipe in the
   same sentence (`grep -c '^## '`). ~~Veto → make them generated (a fourth
   `--check` generator over the README, which is the L4 site's job, not
   L1's).~~
6. **TAKEN AS THE STATED DEFAULT at the STOP (2026-09-07, not vetoed):
   the routing tables' WORDING is the maintainer's to amend** — both are
   drafted from §8.4 and the maintainer edits. Veto → the maintainer
   dictates the rows.

Defaults taken WITHOUT a ruling (CLAUDE.md, §6 above, or the harness's
ruled conventions already decide them): the two checks and their six
controls; listing the four missing documents; stdlib-only; must-fire
controls on every check; one commit per document.

**No CLAUDE.md edit.** The check is `checkdocshape`'s business and [VSP-12]
already points at `docs/README.md` as the map; the HANDOFF routing table
points at the tool. If a rule is wanted in the law, it is a seventh decision
and the maintainer's alone: the law is never reworded unprompted.

### 8.8 Sequencing and cost

1. `14z-140 (1)` — this section, with the measured ground truth. Battery
   green, commit, **STOP for decisions 1-6**.
2. `(2)` — the staleness pass S1-S5 (one commit, before the checks, so the
   claims the checks enforce are true when they land).
3. `(3)` — `checkdocshape.py`: the two checks, the `entry-point` token, the
   selftests; `tests/test_docshape.sh` controls j-o; the four Contents
   additions and the `chars/` rows if ruled. Battery, commit.
4. `(4)` — the two routing tables, one commit per document (the doc-pass
   method).
5. `(5)` — §4's L1 row marked LANDED with the commit; this section's STATUS
   line updated in place; the STATUS banner at the top of this document;
   any gotcha paid for appended to `docs/project/gotchas.md` with the index
   regenerated; the static tier run ALONE and green; close.

Cost: half a session. **Ends when** the six controls fire on a perturbed
copy, `python3 tools/checkdocshape.py --no-pending` is green, the static
tier is green, and `docs/README.md` reaches every declared document.

## 9. L4 — THE RENDERED SITE: scope (the plan before the work)

**STATUS: LANDED 14z-140 (2026-09-07).** All nine decisions were ruled at the
STOP — seven as recommended, decision 4 STRICTER (no link to the drawn MiSTer
page, so the gate's href walk stays absolute) and decision 5 WIDER (the search
indexes the 555 anchor IDs too) — and §9.9 executed under them the same
sitting: the staleness pass, `md_subset.py` + its gate, the `_pagestyle` move,
and `mk_docs_site.py` + `tests/test_docs_site.sh`. **The site is 80 pages and
6.6 MB, with 2,958 address rows and 1,639 search entries.** Same four beats as L1 (§8):
measure, write the plan, STOP for the rulings, execute in a fixed order.

### 9.1 What it delivers

L4 is §4's second row: `tools/mk_docs_site.py`, a generated and never
committed HTML site — the landing page is `docs/README.md` rendered (its
routing table first), every document rendered with cross-links resolved, an
ADDRESS INDEX, the generated indexes and the two skill GUIDEs as pages, a
client-side heading search, and a stdlib-only markdown-SUBSET renderer whose
subset is a CENSUS rather than a guess. Gate `tests/test_docs_site.sh`
(ci_portable, family `docs`).

### 9.2 Ground truth — the construct census (measured 14z-140, 2026-09-07)

Measured over every `doc_shape.tsv` document plus the two skill GUIDEs —
**74 files, 50,705 lines, 3.8 MB of markdown**. First by a throwaway
block-level parser, then **RE-MEASURED by `tools/md_subset.py --census`
itself, which is the authority and which moved several of these numbers** (a
throwaway counts what it can see; the real parser counts what it renders).
The table below is the tool's. `tests/test_md_subset.sh` prints it on every
run, so it cannot go quietly stale.

**The corpus splits three ways** (the renderer sees all of it): 62
hand-written documents (42,241 lines, 2,902 KB), 10 GENERATED (6,908 lines,
817 KB — `GOTCHAS.md`, `annotations.md`, `gate_index.md`,
`community_crosscheck.md`, `tables/{donovan,huitzil,pyron}.md` and the three
`tables/chars/*.md` declared at L1), and the 2 skill GUIDEs (1,556 lines,
129 KB).

| construct | measured | rendering decision |
|---|---|---|
| headings | **h1 100 / h2 1,029 / h3 307, and NO h4+** | `h1`-`h3`. Consecutive same-level heading lines with no blank between are ONE wrapped header — **122 of them** — as `checkdocshape.h2_sections` and `gen_gotchas_index` already merge them |
| tables | **337 blocks / 7,655 rows**; none nested; **7 ragged rows**, normalised and counted; **ZERO without a delimiter row** | header + delimiter + rows. **Findings 2-6: a naive cell split is wrong four separate ways** |
| fenced code | 145 blocks in 27 files; info strings `sh` 31, `bash` 11, `verilog` 7, `c` 4, `powershell` 4, `toml` 4, `ini` 1, `json` 1, the rest bare | `<pre><code class="lang-x">`, escaped verbatim (the box-drawing diagrams stay) |
| lists | ul **2,090** + 53 nested; ol **484** + 9 nested; continuation lines indented 2 | `ul`/`ol`, continuations JOINED, one nesting level |
| inline | code spans **31,658**; bold 7,229; italic 431; strike **137, load-bearing** | precedence code-span > link > strike > bold > italic; everything else escaped. **Code-span content is escaped and never parsed** |
| links | **138** `[text](target)`, of which 120 `.md`, 2 `https://`, 16 other (directory targets and in-page `#fragments`) | `.md` → `.html`; a directory target → that directory's `README.md` page; `https://` untouched |
| blockquotes | **225** blocks | `<blockquote>` |
| `---` rules | 77 in 21 files | `<hr>` |
| HTML comments | 8 | stripped |
| **footnotes, images, task lists, autolinks, reference-link definitions, setext headings, 4-space code blocks, h4+** | **0 — all of them** | outside the subset → strict FAIL with `file:line:construct`, each with a must-fire control |
| raw HTML | **8 `<details>`/`<summary>` blocks** (accepted, decision 7) and **26 `<word>` placeholders in prose** (text, decision 8) — see finding 4 | — |
| duplicate heading slugs | 3, all in `docs/NEXT_SESSION_HISTORY.md` (`open-in-order` six times) | `-2`, `-3`, … suffixes |
| tracked images | 2 (`mister_select_cps2w_f2400.jpg`, `mister_select_mame_f1741.png`), 96.5 KB | copied |
| rendered size | markdown 3.8 MB → HTML ~6 MB, plus the address index | — |

### 9.3 The structural findings — six, each one changing the renderer

1. **A CODE SPAN CAN WRAP ACROSS A LINE BREAK, and a line-based scan splits
   it.** The first census was line-based and reported **76 raw-HTML
   violations**; joining each paragraph's lines before the inline pass drops
   that to **42**, because the rest were `<name>`-shaped placeholders inside
   a code span whose backticks sat on different source lines. **So the block
   split and the line join come FIRST and the inline pass second** — not an
   optimisation, a correctness requirement, and the reason the census
   instrument had to be rewritten before its numbers were worth anything.
2. **ESCAPED PIPES `\|` — 21 in 8 files.** A naive split of a table row on
   `|` counts them and reads **15 tables in 9 files as RAGGED** (cell counts
   like `[2, 3]` or `[3, 4, 5, 8]`). Every one is a false alarm: `\|` inside
   a cell is an escaped pipe, and the plan's "a row whose cell count differs
   from the header FAILS" would have failed nine live documents on its first
   run. The splitter honours `\|`.
3. **A TABLE ROW MAY HAVE NO LEADING PIPE — 22 rows in 4 files**, and one of
   them is load-bearing: `HANDOFF.md:45` opens with two bold `[CPE-32]` /
   `[MFI-32]` anchor markers BEFORE the first pipe, then `| FBNeo | …`. GitHub
   treats a leading pipe as optional; a strict parser ends the table there
   and reads the rest as a new table with no separator row (measured: 3
   such). Decision 9.
4. **REAL RAW HTML EXISTS, in exactly one place: `<details><summary>` in the
   three generated `tables/chars/*.md`** (16 tags), emitted by
   `tools/charmap_md.py` to fold long per-move tables. The other 26
   raw-HTML hits are `<word>` PLACEHOLDERS in prose — `<name>`, `<build>`,
   `<tenant>`, `<seed>`, `<tmp>`, `<dir outside the repo>` — across 22
   files and 20 distinct words. Escaping renders them correctly; a strict
   FAIL on "a `<` followed by a letter outside a code span" would fail 22
   documents for writing English. Decisions 7 and 8.
5. **A PIPE INSIDE A CODE SPAN IN A CELL IS CONTENT** — `WATCH=addr,len[,r|w|rw]`,
   `who ∈ p1|p2|sys`, `|| true`, all written inside a code span inside a table
   cell. GFM would split there (it demands `\|` even inside a code span) and
   so did the first strict pass, which is **four of the seven ragged rows it
   reported**. The splitter is backtick-aware, which renders the author's
   obvious intent and is the only reading under which those documents are
   right. **A ragged row is then NORMALISED as GFM does and COUNTED, never
   fatal** — seven remain, two of them in ARCHIVES that are never rewritten
   ([VSP-17]), so a hard failure was never available.
6. **A TABLE NEEDS ITS DELIMITER ROW.** Without that rule, any prose line
   containing a pipe and ending in one opens a table — which is how a `bbh`
   subcommand list written inside a WRAPPED code span
   (`docs/NEXT_SESSION_HISTORY.md:109-112`) became a 7-cell table, and how
   the first census reported three "tables with no separator row". With the
   rule, **that count is ZERO over the whole corpus.** Finding 6 also cost
   the one bug of this slice: requiring the delimiter made a table-shaped
   line fall through to the paragraph branch, whose loop broke on
   `is_table_row` before consuming anything — an infinite loop on the first
   run. The paragraph branch now always consumes its first line.

### 9.4 The address index — the plan's parse is unsound, and the module is not

**Do not parse the rendered `annotations.md`.** Measured: its `where` cell
is ambiguous by construction — **688 headings in the corpus contain ` — `**
(the file/section separator) and **103 contain `;`** (the carrier
separator); `gen_annotations.cell()` rewrites every backtick to `'`, so a
section name with code in it can never slugify back; and `MAX_CARRIERS = 6`
truncates the rest to `+N more`. Parsing that page resolves **540 of 825
carrier pairs to no heading** — all four causes being properties of the
rendering, not of the data.

**Import `gen_annotations.collect(root)` instead** (the plan's own "reuse,
never copy" rule; the module is import-safe — its work sits under
`if __name__ == "__main__"`). It returns `addr -> {(tier, relpath, section,
hint)}` with section names intact. Measured through it: **2,958 addresses,
6,776 carrier entries** (tier 0 atlas 570, 1 engine_internals 654, 2 other
docs 1,265, 3 manifests 2,853, 4 code 1,434), **329 distinct document-tier
`(file, section)` pairs — and ZERO of them fail to slugify to a heading in
their file.** So the plan's hoped-for enforcement — *a section name that
resolves to no emitted id FAILS the generator* — **is implementable and
green today**, but only from the module. Tier-3 and tier-4 carriers are a
manifest row name and a filename; they render as plain text, never links.
The site therefore shows EVERY carrier where the rendered page shows six.

### 9.5 Architecture

- **`tools/md_subset.py`** (new, stdlib, ~400 lines): `blocks(lines)` FIRST
  (fence / comment / heading + wrapped / rule / table / blockquote / list /
  paragraph, continuations joined — finding 1), then `inline(text) -> html`;
  `census(text) -> Counter`; `SubsetError(file, line, construct)` in strict
  mode. Selftests: one per supported construct, one per forbidden construct,
  and one per rule of §9.3 as a regression case. **LANDED 14z-140**, with
  `tests/test_md_subset.sh` (ci_portable, family `docs`, ~3 s): all 74 files
  parse, nine forbidden constructs each have a must-fire control, nine shapes
  the corpus DOES write each have a must-NOT-fire control, and the gate prints
  the census on every run so it cannot go quietly stale.
- **`tools/mk_docs_site.py`** — **LANDED 14z-140**, 80 pages / 6.6 MB, gate
  `tests/test_docs_site.sh` (ci_portable, family `docs`, ~25 s): `--root`, `--out` (default
  `docs/site/`), `--check` (parse and resolve, write nothing — the gate's
  mode), `--census`, `--verify DIR`. Reads `docs/doc_shape.tsv` for the
  document set and shapes; builds `index.html` from the README,
  `addresses.html` from `collect()`, pages for `gate_index.md`,
  `GOTCHAS.md` and the two GUIDEs; copies the two images; one CSS file;
  refuses to write into any tracked path. **The page for
  `project/mister_core.md` opens with a note naming
  `tools/mk_mister_page.py` and the drawn page it produces — a NOTE, never a
  link (decision 4), so every `href` the site emits is a file the site
  wrote.**
- **Search**: `search.json` carries every h1-h3, one entry per document
  title, and one per `**[PFX-N]**` anchor (1,554 + 74 + 555, decision 5), and
  one inline `<script>` per page does a substring filter over it — no `src=`,
  no URL. A query matching `ADDR_RE` jumps to that address's row in the
  index; a query matching an anchor ID jumps to the rule's paragraph.
- **Slugs**: one function shared by the renderer and the address index —
  strip inline markup and `**[PFX-N]**` tokens, lower-case, non-alnum → `-`,
  collapse, trim; duplicates get `-2`, `-3`. A `**[PFX-N]**` anchor also
  emits `id="PFX-N"` so a skill citation deep-links. A wrapped header emits
  the merged slug AND one empty `<a id>` per constituent line, because
  `gen_annotations.HDR_RE` records a single constituent as the section name.
- **Theme — LANDED 14z-140.** `mk_mister_page.py` **executes at import**
  (`ARGV = sys.argv[1:]`), so the shared layer MOVED into
  `tools/_pagestyle.py` and both generators import that — never
  `import mk_mister_page`. **What moved is the VALUES, not the CSS text**:
  the palette, the colour maths (`mix` / `desat` / `contrast` / `label_ink`)
  and two theme dicts. Each generator keeps its own stylesheet, because the
  MiSTer page interleaves one custom property per region ROLE and a doc site
  has no roles — and `--warn` is the case that proves the split is real
  (`FLAME` on light, `WARM_L` on dark, since red on a dark ground is
  unreadable), so a page that copied the light block and swapped a few values
  would get it wrong silently. **Proof the lift is neutral: the gate is green
  before and after, and the drawn page is BYTE-IDENTICAL to the one the
  pre-move script produced.** Two things it cost: the gate COPIES the
  generator to a temp dir for its controls, so the module is resolved from
  `--repo`'s `tools/` as well as from beside the file; and `_pagestyle`'s own
  self-tests run from `test_mister_page.sh` section 0, the theme's oldest
  consumer, where they also assert the two themes define the SAME properties
  (one defined only in light is how a page borrows its host's theme).
- **Reuse**: `gen_annotations.ADDR_RE / CARRIERS / collect / scan_doc /
  HDR_RE`; `checkdocshape.read_shape` for the TSV.

### 9.6 The gate `tests/test_docs_site.sh` (ci_portable, family `docs`, ~10 s)

The census printed; `--check` exits 0; a render into `$WORK/site` asserting
the page set, the image set, the extension set (`.html .css .json .png
.jpg`), no `http://`, no `<script src`, no external `<link`, no reference to
`build/out`, and — by an INDEPENDENT walk, not the generator's own check —
every in-tree `href` resolving to a written file, **with no exemptions: that
is what decision 4 bought by declining to link the drawn MiSTer page.** Determinism is the
hand-edit invariant's real form: two renders into two temp dirs, `diff -r`
empty. `git check-ignore -q docs/site` (guarded like the runner's
not-a-checkout branch) is decision 1's tripwire.

**MEASURED at the landing:** 82 written files (80 pages + `search.json` +
`style.css`) and 2 images, 6.6 MB; **0 unresolved in-tree hrefs**, **0
external loads**, two renders byte-identical, 2,958 address rows and 1,639
search entries. Two content links to the outside world survive, both written
by documents on purpose (a claude.ai artifact and a GitHub issue) — a link a
reader clicks is not a LOAD, and the assertion is that the page fetches
nothing.

**Three of this gate's own checks were wrong before they were right, all the
same mistake — reading TEXT where the invariant is about an ATTRIBUTE:** a
`no http://` grep fired on escaped prose and on this document's own control
examples; a `no build/out` grep fired on HANDOFF and the atlas README for
QUOTING a filename in a command; and the href walk read the search box's
`'<a href="'+BASE+…` string concatenation as 80 broken links. The walk strips
`<script>` first, and the other two ask about `src=`/`href=`. **And the
address-index control was dead twice** before it fired: its fixture sat where
`gen_annotations.CARRIERS` does not look (`collect()` returned nothing), and
an address in a document's preamble does not give section `(top)` — the `# `
title has already set it. What finally fires it is a real parser
disagreement: an UNCLOSED CODE SPAN swallows the headings after it, so
`md_subset` emits no heading while `gen_annotations`' line-based `HDR_RE`
records one and files the address under it. Nothing else in the tree catches
that.

**Must-fire controls** on `mkcopy` + `--root`, each with its `sed` proven to
have applied: `#### h4` → unsupported construct; `[x](nope.md)` →
unresolved link; `[x](ram.md#no-such)` → dangling anchor; an
`annotations.md` carrier naming a section that does not exist → address
index: no heading; a table row whose cell count differs from the header
AFTER `\|` handling → ragged row. **And three NEGATIVE controls, one per
finding, because each is a way this gate could over-fire on the live
corpus**: a code span wrapped across a line break → PASS; a cell containing
`\|` → PASS; a `<name>` placeholder in prose → PASS.

### 9.7 Staleness pass

| # | claim | true now |
|---|---|---|
| S1 | §2 of this document: "one rendered page exists (`mister_core.html`, gitignored, 17 figures)" | true until L4 lands, and it stays true in a narrower sense after: decision 4 keeps the DRAWN page separate and UNLINKED, so the site renders the markdown corpus without absorbing it. Dated in §2 |
| S2 | `tests/test_mister_page.sh`'s header says **ci_portable** (twice) while it is registered in `tests/ci_static.txt`, and its comment block sits ORPHANED in `ci_portable.txt` beside no row | **FIXED 14z-140 — and the measurement INVERTED the plan's assumption.** The first reading, `env -u ROMDIR` on this machine, returned rc=0 and said the header was right. That is the "the verdict never changed on the machine it ran on" trap: this host HAS the build dirs. Re-measured in a REAL clean checkout (`git archive HEAD`), the gate exits 0 and re-derives 15 figures, **but prints the generator's two `  SKIP:` lines** (no WIDE romset, no decrypted image) — and `tests/lib/classify.sh` matches `^ *SKIP`, so the whole gate classifies SKIP, which `ci_portable` treats as a FAILURE by design (*"a gate that SKIPs for want of `build/out/vsavj_opcodes.bin` is not portable, it is silent"*). **So the REGISTRATION was right and the HEADER was wrong**: the header now says ci_static with the reason, and the orphaned comment block moved to `ci_static.txt` beside its row |
| S3 | §4's L4 row: "measured over the 66 documents" | **FIXED 14z-140**: 74 files render — 62 hand-written + 10 GENERATED + the 2 skill GUIDEs. Corrected in §4's row |
| S4 | §5.2: "a construct outside the subset fails the generator loudly rather than rendering wrong" | still the rule, but the census found TWO constructs the corpus actually uses that the plan listed as absent (raw HTML, and the table shapes of findings 2-3). The sentence stands; the subset is what changes |

### 9.8 Decisions — taken under stated assumptions, open to veto

1. **RULED (maintainer, 2026-09-07): output directory `docs/site/`, gitignored as a
   directory**, with a short rationale beside `.gitignore:143`'s
   `docs/project/mister_core.html` — the only precedent, and it puts rendered
   docs beside the docs. ~~Veto → `build/docs_site/` (the ROM-artefact swamp
   the triage prunes).~~
2. **RULED (maintainer, 2026-09-07): the two auto-links ON, but SCOPED** — a backticked
   `*.md` token links only when it resolves UNAMBIGUOUSLY to one rendered
   document
   (repo-relative or `docs/`-relative); a bare basename with more than one
   candidate stays a code span. Measured: **1,568 backticked `*.md` code
   spans against 138 markdown links**, so this is how the corpus actually
   routes — and **777 resolve as written**, so half do not, which is the
   same ambiguity that made L1's matcher unsound. Address tokens (**4,052**)
   link to their address-index row. ~~Veto → markdown links only, and the
   site loses most of its cross-linking.~~
3. **RULED (maintainer, 2026-09-07): the palette and `css()` MOVE into
   `tools/_pagestyle.py`**, imported by both generators — `mk_mister_page.py`
   executes at import, so importing IT is not an option. One definition of
   the theme, so the site and the drawn page cannot drift;
   `test_mister_page.sh` green before and after is the proof. ~~Veto → copy
   the ~30 variable lines with a `# lifted from` note.~~
4. **RULED (maintainer, 2026-09-07), against the recommendation, and the stricter
   answer): the site does NOT link `mister_core.html`.** It renders
   `mister_core.md` as an ordinary page whose top note names the command that
   draws the 17-figure version. **The reason is the gate's own invariant:**
   `mister_core.html` is gitignored and built on demand, so on a fresh
   checkout it does not exist — linking it means either weakening the href
   walk (*every in-tree `href` resolves to a written file*, §9.6, the one
   assertion that catches a broken site) or carving a named exemption into
   it. The walk stays ABSOLUTE and there are no exemptions; the cost is one
   command to see the diagrams. ~~Recommendation was a link with a named,
   must-fire-controlled exemption; embedding via subprocess was refused for
   the two-producers risk — a second invocation path to an artefact
   `test_mister_page.sh` locks, which is the class 14z-139 closed for verdict
   classifiers.~~
5. **RULED (maintainer, 2026-09-07), EXTENDING the recommendation): search over headings,
   document titles AND every `**[PFX-N]**` anchor ID** — 1,554 headings + 74
   titles + **555 anchors**, negligible extra size. Typing `VSP-167` or
   `MSC-32` lands on the rule's paragraph, which is how the skills cite and
   therefore how a reader arrives. ~~Veto → headings plus each document's
   first line (a full-text index the browser's own Ctrl-F already gives per
   page).~~
6. **RULED (maintainer, 2026-09-07): publishing stays a SEPARATE decision each time**
   (§5.1); the maintainer opens the local site, and building never implies
   publishing. ~~Veto → publish at every landing, which would make a rule-7
   judgement standing rather than per-artefact.~~
7. **RULED (maintainer, 2026-09-07): `tables/chars/*.md` are rendered, and the subset is
   taught ONE pair** — `<details>`/`<summary>`, the only real HTML in the
   corpus, emitted by a generator we own and serving a purpose the site wants
   (folding a 2,000-row table). Every other tag stays a strict FAIL.
   ~~Veto (a) → change `tools/charmap_md.py` to emit a heading plus the
   table, which re-freezes `tests/expected/charmap_pages.sha256` and would
   introduce the corpus's first `####`; veto (b) → skip the chars pages.~~
8. **RULED (maintainer, 2026-09-07): a `<word>` in prose is TEXT, not a construct** — the
   renderer escapes `<…>` and FAILS only on a KNOWN HTML tag name outside a
   code span (decision 7's pair, plus the tags a browser would act on).
   Measured: 26 placeholders across 22 files and 20 distinct words, so the
   plan's "`<` followed by a letter outside a code span is a strict FAIL"
   would fail 22 documents for writing English. ~~Veto → FAIL on all and
   backtick the 26 sites (a 22-document edit reaching two GENERATED GUIDEs,
   whose real sites are their source paragraphs); or escape everything and
   never fail, which makes a real `<script>` render as visible text with
   nobody told.~~
9. **RULED (maintainer, 2026-09-07): a table row's LEADING PIPE is optional**, as it is on
   GitHub — 22 rows in 4 files rely on it, including `HANDOFF.md:45`, whose
   row opens with its two bold anchor markers before the first pipe.
   ~~Veto → fix the four documents, which moves two anchor markers inside a
   cell and needs `doc_anchor_census.py --freeze` in the same commit — and
   could not be uniform anyway: 16 of the 22 rows are in
   `docs/NEXT_SESSION_HISTORY.md`, an ARCHIVE that is never rewritten
   ([VSP-17]).~~

Defaults (no ruling): the subset census as the source of truth over the
plan's table, strict FAIL for a genuinely unsupported construct, the gate's
sections, determinism as the hand-edit invariant, `--verify` on demand, and
the address index built from `gen_annotations.collect()` rather than from
the rendered page (§9.4 — a measured correction, not a choice).

### 9.9 Sequencing and cost

1. `14z-140 (8)` — this section with the measured census. Battery, commit,
   **STOP for decisions 1-9**.
2. `(9)` — the staleness pass: S2's registration move with the gate index
   regenerated, S1/S3/S4 reworded. One commit.
3. `(10)` — `tools/md_subset.py` + `tests/test_md_subset.sh` (ci_portable,
   family `docs`): every construct renders as expected, every forbidden one
   raises, the four findings have regression cases, and the tree census
   matches §9.2 or §9.2 is corrected in the same commit.
4. `(11)` — the `_pagestyle.py` move, `test_mister_page.sh` green before and
   after.
5. `(12)` — `tools/mk_docs_site.py` + the `.gitignore` line +
   `tests/test_docs_site.sh` + the registrations + the regenerated gate
   index.
6. `(13)` — the maintainer opens the site; HANDOFF gains a "What exists" row
   and a routing-table row; `docs/README.md` names the generator; the
   [VSP-13] grep for "one rendered page exists"; §4's row LANDED; the static
   tier ALONE; close.

Cost: one to two sessions. **Ends when** `tests/test_docs_site.sh` is green
in ci_portable and the maintainer has opened the site.
