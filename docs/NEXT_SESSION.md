# NEXT SESSION — orientation (rewritten at the 14z-140 CLOSE, 2026-09-07)

> Rewritten at every session close ([VSP-17]). ROLLOVER: the previous opener
> moves VERBATIM to the top of `NEXT_SESSION_HISTORY.md` — this file holds ONLY
> the live orientation. Session state, not knowledge: facts belong in the docs,
> status in STATE.md.

## THE ORDER OF WORK IS THE MAINTAINER'S (2026-09-06): THE HARNESS, THEN LIVING DOCS, THEN THE OPEN ITEMS

*"I need the generic reusable test harness and the living documentation
effort. After that we'll tackle the open items lined up."* **The harness
and its skill are DONE (14z-135..139). LIVING DOCS IS RUNNING: L1 LANDED
14z-140; L4 the rendered site is next.**

## WHERE LIVING DOCS IS: L1 LANDED, L4 NEXT — scope it first, then STOP for the rulings

The record is **`docs/project/living_docs_scope.md`**: §4's slice table
(status in place), §6 the standing decisions, and one plan section per slice
in the harness precedent's form — **§8 is L1, LANDED 14z-140**; §9 L4, §10
L2, §11 L3 are written at their own slices' openers.

**THE EXECUTION PLAN IS STILL THE BRIEF: `build/living_docs_plan_14z139.md`**
(untracked, a copy of `~/.claude/plans/well-i-m-almost-out-glimmering-koala.md`).
**Read it in full after this file.** §0 is the standing frame every
living-docs session runs inside — the opener, the eight-check doc battery
with exit codes captured directly, the ALONE rule, the four beats (measure →
write the slice's plan section into `living_docs_scope.md` → **STOP for the
rulings** → execute in a fixed order), the close, and eleven paid-for traps.
§2 is L4's section: the construct census over the corpus before the renderer
is written, the architecture, `tests/test_docs_site.sh`, seven decisions, the
staleness rows, the sequencing. **Its figures date — §0.6 lists what to
re-measure at the opener, and at 14z-140 the L1 census disagreed with the
scope document on the one number the slice turned on.**

**L1, for what the next slice inherits:** `tools/checkdocshape.py` now
asserts ROUTING — every `doc_shape.tsv` row is listed in `docs/README.md`'s
`## Contents` with its declared shape (a directory entry counts for the
members its own line NAMES; a row whose `requires` carries `entry-point` is
exempt from Contents but must still be named somewhere in the README), and a
history twin is TWO-WAY. `tests/test_docshape.sh` carries 15 must-fire
controls. So **a new document now needs its `doc_shape.tsv` row AND its
`docs/README.md` Contents line in the same commit**, or the portable tier
goes red on its author — L4 will add none, but L2 and L3 will.

## OPEN, IN ORDER

1. **L4 the rendered site**, then L2 the rule-5 census, then L3 the ROM
   re-derivation — each scoped first, each stopping for the rulings.
   **The one CROSS-SLICE decision, ruled once at L2's STOP at the latest:**
   no NOTE verdict exists (`tests/lib/classify.sh` knows PASS / SKIP / FAIL /
   TIMEOUT and all three runners source it), so the recommendation is a
   `NOTE: <key> <value>` marker surfaced by an advisory block in
   `run_all_static.sh` — never a fifth verdict in the shared classifier.
   Plan §5 has the argument and the ground truth it needs.
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
