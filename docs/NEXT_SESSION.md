# NEXT SESSION — orientation (rewritten at the 14z-140 CLOSE (2), 2026-09-07)

> Rewritten at every session close ([VSP-17]). ROLLOVER: the previous opener
> moves VERBATIM to the top of `NEXT_SESSION_HISTORY.md` — this file holds ONLY
> the live orientation. Session state, not knowledge: facts belong in the docs,
> status in STATE.md.

## THE ORDER OF WORK IS THE MAINTAINER'S (2026-09-06): THE HARNESS, THEN LIVING DOCS, THEN THE OPEN ITEMS

*"I need the generic reusable test harness and the living documentation
effort. After that we'll tackle the open items lined up."* **The harness and
its skill are DONE (14z-135..139). LIVING DOCS IS HALF DONE: L1 and L4 landed
14z-140; L2 the rule-5 census is next, then L3 the ROM re-derivation.**

## ONE THING WAITS ON YOU: OPEN THE SITE

```sh
python3 tools/mk_docs_site.py && open docs/site/index.html
```

**80 pages, 6.6 MB, generated locally and gitignored** — the whole corpus
cross-linked, an ADDRESS INDEX with all 2,958 addresses and EVERY carrier
(where `annotations.md` shows six), and a search over 1,639 headings,
document titles and `**[PFX-N]**` rule IDs — type `VSP-167` and land on the
rule. That is L4's "ends when": the gate is green, the maintainer opening it
is what closes the slice.

## WHERE LIVING DOCS IS: L1 AND L4 LANDED, L2 NEXT — scope it first, then STOP for the rulings

The record is **`docs/project/living_docs_scope.md`**: §4's slice table
(status in place), §6 the standing decisions, and one plan section per slice
— **§8 L1 and §9 L4, both LANDED 14z-140**; §10 L2 and §11 L3 are written at
their own slices' openers.

**THE EXECUTION PLAN IS STILL THE BRIEF: `build/living_docs_plan_14z139.md`**
(untracked, a copy of `~/.claude/plans/well-i-m-almost-out-glimmering-koala.md`).
**Read it in full after this file.** §0 is the standing frame every
living-docs session runs inside — the opener, the eight-check doc battery
with exit codes captured directly, the ALONE rule, the four beats (measure →
write the slice's plan section into `living_docs_scope.md` → **STOP for the
rulings** → execute in a fixed order), the close, and eleven paid-for traps.
§3 is L2's section: the `audit_rule5.py` census, the frozen BAKED inventory,
the ledger, seven decisions.

**RE-MEASURE AT THE OPENER RATHER THAN READING THE SCOPE DOCUMENT. Both
14z-140 censuses disagreed with it** — L1's found FOUR unlisted documents
where §2.2 said two, and L4's found SIX structural constructs where the plan
had listed four, one of which (the address index built from the rendered
`annotations.md`) would not have worked at all. §0.6 lists what dates.

## WHAT L1 AND L4 LEFT THE NEXT SLICE

- **A new document now needs three things in ONE commit** and the third is
  enforced: its `docs/doc_shape.tsv` row, its `docs/README.md` `## Contents`
  line with the declared SHAPE, and — if it is a `_history.md` twin — a
  mention of its live document, which must mention it back.
  `tests/test_docshape.sh` carries 15 must-fire controls.
- **Anything a document writes must parse inside the subset**
  (`tools/md_subset.py`): h1-h3 only, no raw HTML but `<details>`/`<summary>`,
  no footnotes/images/task lists/autolinks/reference definitions. A `<word>`
  in prose is fine; a real tag name outside a code span is not.
  `tests/test_md_subset.sh` and `tests/test_docs_site.sh` are both
  ci_portable, so the portable tier catches it in ~30 s.
- **`tools/_pagestyle.py` is the one definition of the page theme.** Import
  it; never `import mk_mister_page` (it parses ARGV at module scope).

## OPEN, IN ORDER

1. **L2 the rule-5 census**, then **L3 the ROM re-derivation** — each scoped
   first, each stopping for the rulings.
   **The one CROSS-SLICE decision, due at L2's STOP at the latest:** no NOTE
   verdict exists (`tests/lib/classify.sh` knows PASS / SKIP / FAIL / TIMEOUT
   and all three runners source it), so the recommendation is a
   `NOTE: <key> <value>` marker surfaced by an advisory block in
   `run_all_static.sh` — never a fifth verdict in the shared classifier.
   Plan §5 has the argument. L4 already produces a number that wants it:
   `test_md_subset` prints 7 ragged table rows, normalised and never fatal.
2. Then the open items below.

## OPEN ITEMS, unchanged

The deferred `audit_mask_window_ff42a2` ruling (deprecated or case-specific),
`test_header_defaults` and the positional `[name]` default,
`release/merged-m15` never packaged, Pyron's row 0x11 (mechanism not
established; no port recommendation), the Phobos ±1 residue (a knowledge
item), the community cross-check aerials, the Zabel j.LK session, #112
option (B).

**IF A DOC IS TOUCHED:** `doc_anchor_census --check` + `checkdocshape
--no-pending` + `checkdocs` + `checkskills` + `gen_annotations --check` +
`gen_gate_index --check` + `gen_gotchas_index --check` + `gen_skill_guide
--check`, exit statuses captured directly — and in zsh, loop with `${=cmd}`.
**A running script is never edited — not in the main tree, not in a
worktree** ([MSC-54]). **The static tier is never run beside another gate
run in this tree, and nothing here is edited while it runs.**
