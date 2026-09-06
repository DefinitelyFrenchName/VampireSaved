# LIVING DOCUMENTATION SCOPE — what "referenced, never stale, never lost" means here, and the slices that deliver it

> **STATUS (written 14z-135, 2026-09-06): THE PLAN BEFORE THE WORK.** The
> maintainer RULED at the plan stage (2026-09-06) that the effort takes ALL
> THREE forms put to them: a rendered, navigable site; routing enforcement in
> the markdown; and fact tables with provenance. Nothing is built yet. It
> starts AFTER the generic harness slices and the harness skill
> (`harness_scope.md` §4), by the maintainer's order of 2026-09-06: "the
> generic reusable test harness and the living documentation effort. After
> that we'll tackle the open items". Slice status is tracked in §4's table,
> updated in place.

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
generator's `--check`).

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
| declared SHAPE per document; a new document must be classified at birth; session-shaped headers barred from reference material; a history twin must exist and be HIST; HIST carries no anchors | chronology re-accreting into a reference; an unclassified document | `tools/checkdocshape.py`, `docs/doc_shape.tsv`, `tests/test_docshape.sh` (`--no-pending`) |
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
one way (live → twin) in `doc_shape.tsv`. **Measured gaps:** the Contents
list is a CONVENTION — `checkdocshape` verifies only that its links resolve,
not that every declared document is listed; two are not
(`docs/project/gate_scoping_method.md`, the method document the port skill
cites for eight rules, and `docs/project/tables/community_crosscheck.md`).
The twin declaration is one-way in the table, though every twin's text
does name its live document today (measured: zero missing back-links).
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
| **L1 routing enforcement (markdown)** | `checkdocshape.py` gains two checks: README COMPLETENESS (every `doc_shape.tsv` row that is not GENERATED-wholesale is listed in `docs/README.md` Contents, with its declared shape, and a directory-level entry counts for its members) and TWO-WAY TWINS (a HIST twin names its live document and the live document names its twin). Routing tables at the two entry points that lack one: `HANDOFF.md` ("if you want to DO X, read/run Y") and `docs/game/atlas/README.md` ("if you want to know what ADDRESS X is, read Y"). The two unlisted documents listed. | 2 unlisted docs; twins one-way in the table; 2 entry points without routing | the two new checks have must-fire controls on a perturbed copy (`--root`), the static tier is green, and the README lists every declared document |
| **L4 the rendered site** | `tools/mk_docs_site.py`: a generated HTML site under a gitignored directory (the `mister_core.html` precedent — never committed): the landing page IS the routing table; every document rendered with cross-links resolved; an ADDRESS INDEX from `annotations.md` (address → every carrier, one click); the gate index, the gotcha index and the skill guides as pages; the two tracked images; a search box over headings (client-side, no server). Markdown renderer: stdlib-only, the subset this corpus uses (headings, lists, tables, fenced code, bold/italic, links, strikethrough, blockquotes) — measured over the 66 documents before writing it, so the subset is a census and unsupported constructs FAIL the generator rather than render wrong. A portable gate runs the generator over the tree and fails on any unresolved link or unsupported construct; the HTML is the artifact, the generator is what is reviewed. | `mk_mister_page.py` is the pattern; no site exists | `tests/test_docs_site.sh` (ci_portable) green; the maintainer has opened the site |
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
