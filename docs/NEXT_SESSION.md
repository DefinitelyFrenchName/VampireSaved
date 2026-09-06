# NEXT SESSION — orientation (rewritten at the 14z-135 CLOSE, 2026-09-06)

> Rewritten at every session close ([VSP-17]). ROLLOVER: the previous opener
> moves VERBATIM to the top of `NEXT_SESSION_HISTORY.md` — this file holds ONLY
> the live orientation. Session state, not knowledge: facts belong in the docs,
> status in STATE.md.

## THE ORDER OF WORK IS THE MAINTAINER'S (2026-09-06): THE HARNESS, THEN LIVING DOCS, THEN THE OPEN ITEMS

*"I need the generic reusable test harness and the living documentation
effort. After that we'll tackle the open items lined up."* Both are SCOPED
(`docs/project/harness_scope.md`, `docs/project/living_docs_scope.md`) and
the harness's first slice is LANDED. Nothing in this tree's own harness
changes; it "stays as it is".

## WHERE THE HARNESS IS

`~/Developer/blackbox-harness` (`bbh`), a SEPARATE repository, git-initialised
locally, **NO REMOTE** — creating one and pushing are the maintainer's. H1 is
at `803f372`: `bin/bbh run-static | classify | tier | config |
demand-after-trap | doctor | selftest`; `selftest/run.sh` is its pre-commit
gate (7/0/0 at the close). Read its `README.md`, `docs/gate_contract.md`,
`docs/config.md`; the consumer config for THIS tree is
`example/consumers/bbh.vampire.toml` (kept there by decision 8 of the scope).
`selftest/test_fidelity_vampire.sh` proves F1 (identical runner output) and
F3 (the tier classifier reproduces both registries) against this tree at
every selftest run; F2 (the whole portable tier through both runners) is
opt-in with `BBH_FIDELITY_F2=1` and never beside another gate run here.

## NEXT: SLICE H2 — the comparators and the masked vocabulary

Lift `tools/{compare_flicker,compare_window,compare_composite,check_diverge,
s4_thresholds}.py` into `lib/py/bbh/` with ONE `logfmt.py` for the three
private `load()` copies and the thresholds from `[thresholds]`; lift
`tests/lib/masked_compare.sh` and `enumerate_expectations.sh` with their
VERDICT STRINGS UNTOUCHED (rule 1 of the fidelity contract — `masked_check`'s
text is what F5 diffs); bring `test_compare_{flicker,window,composite}.sh`,
`test_s4_thresholds.sh`, `test_masked_compare.sh` (their fixtures are already
synthetic). Then F5: every `.masked` spec (1,891) paired with a DIFFERENT
set's frozen log of the same stem, verdict strings byte for byte. H3 after
(fingerprint + suite + the fake driver `fakesys.py`); the order and each
slice's file list are `harness_scope.md` §4.

## OPEN, IN ORDER

1. **H2** (above), then H3, then H4/H5/H7, H6, H9 (the fidelity gate here,
   `ci_static`), then the harness SKILL, then living docs L1 → L4 → L2 → L3
   (`living_docs_scope.md` §4), then the open items below.
2. The eight defaults of `harness_scope.md` §7 are open to VETO — read them
   once; none blocks H2.
3. **A finding about this tree, not fixed (14z-135):** `run_all_static.sh`
   has no exit-0-after-shell-error branch (the sweep runner has, since
   14z-134); the demand-after-trap lint is what prevents the shape. Fix it
   here only if the maintainer wants the two runners identical.
4. The standing items unchanged: the deferred `audit_mask_window_ff42a2`
   ruling (deprecated or case-specific), `test_header_defaults` and the
   positional `[name]` default, `release/merged-m15` never packaged
   (recorded, not owed), Pyron's row 0x11 (measured; the port decision is
   the maintainer's; the pose-installer question first), the Phobos ±1
   residue, the community cross-check aerials, the Zabel j.LK session, #112
   option (B).

**IF A DOC IS TOUCHED:** `doc_anchor_census --check` + `checkdocshape
--no-pending` + `checkdocs` + `checkskills` + `gen_annotations --check` +
`gen_gate_index --check` + `gen_gotchas_index --check` + `gen_skill_guide
--check`, exit statuses captured directly — and in zsh, loop with `${=cmd}`.
**A running script is never edited — not in the main tree, not in a
worktree** ([MSC-54]). **The static tier is never run beside another gate
run in this tree, and nothing here is edited while it runs.**
