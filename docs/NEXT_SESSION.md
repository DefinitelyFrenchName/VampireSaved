# NEXT SESSION — orientation (rewritten at the 14z-136 CLOSE (2), 2026-09-06)

> Rewritten at every session close ([VSP-17]). ROLLOVER: the previous opener
> moves VERBATIM to the top of `NEXT_SESSION_HISTORY.md` — this file holds ONLY
> the live orientation. Session state, not knowledge: facts belong in the docs,
> status in STATE.md.

## THE ORDER OF WORK IS THE MAINTAINER'S (2026-09-06): THE HARNESS, THEN LIVING DOCS, THEN THE OPEN ITEMS

*"I need the generic reusable test harness and the living documentation
effort. After that we'll tackle the open items lined up."* Both are SCOPED
(`docs/project/harness_scope.md`, `docs/project/living_docs_scope.md`);
harness slices H1-H4 are LANDED. Nothing in this tree's own harness
changes; it "stays as it is".

## WHERE THE HARNESS IS: H1-H4 LANDED (`803f372`, `ef7e899`, `c26ba45`, `81ad426`)

`~/Developer/blackbox-harness` (`bbh`), a SEPARATE repository, PUBLIC at
https://github.com/DefinitelyFrenchName/blackbox-harness (branch `main`;
pushing it is standing-authorised since 14z-135b). `bin/bbh run-static |
run-sweep | run-suite | fingerprint | rpl | classify | tier | config | demand-after-trap
| compare-* | check-diverge | describe-shape | doctor | selftest`. Read its
`README.md`, `docs/gate_contract.md`, `docs/config.md`, `drivers/README.md`
(THE DRIVER CONTRACT), `docs/method/oracle_classes.md`, `example/README.md`
(the fake machine, run green / break a control / freeze); the consumer
config for THIS tree is `example/consumers/bbh.vampire.toml`. `bbh selftest`
is 18 gates, 18 PASS (~3 min; the slice pre-commit is
`BBH_FIDELITY_F5=1 BBH_FIDELITY_F6=all BBH_FIDELITY_F7=all bbh selftest`
with `ROMDIR` set, ~15 min — do that at every slice). Fidelity so far: F1
identical, F3 exact, F4 exact, F5 exact (1,891/1,891), F6 exact, F7 exact — all in
`selftest/test_fidelity_vampire.sh`, which runs against this tree at every
selftest run; F2 is opt-in (`BBH_FIDELITY_F2=1`) and never beside another
gate run here.

## NEXT: H5 (expectation and gate hygiene) AND H7 (fields + dumps) — both depend only on H1; then H6

Read `harness_scope.md` §2.5 (E1-E3, E5-E7, R7), §2.2 C6-C7 and §4's rows
first.
- **H5** lifts E1 provenance (`tests/expected/PROVENANCE.md` +
  `test_expectation_provenance.sh`: the closed evidence-class vocabulary,
  completeness both ways), E2 header defaults
  (`tools/audit_header_defaults.py` + its gate; the backticked-token and
  `(verbatim; …)` exemptions), E3 reference rot (the predicate as a hook),
  E5/E6 `gate_header.py` + `gen_gate_index.py` with the families from
  config (the gate side only — the doc side stays here by decision 7), E7
  `shadow_tools.sh` (tools dir and link dirs from config), R7 the
  accounting rule; their five gates travel; then F9 (the generic
  equivalents with the consumer config, full stdout + exit diffed).
- **H7** lifts C6 `compare_fields.py` (the match-start anchor predicate and
  the p1/p2 bases into `[fields]`; the fields TSV may carry `# base p1=…`
  headers) and C7 `check_wram_dumps.py` → `check_dumps.py`; the fake
  machine's `DUMPS` already produce the input; ground truth
  `test_compare_fields_selfcheck.sh` on fake dumps + a new `test_check_dumps`.
- Then **H6** (the MAME Lua layer under a machine profile, `rpl_parse.lua`
  + the equality selftest with `rpl.py`, the MAME / guarded / FBNeo drivers,
  `bbh-inp-corpus`; F8 on the pinned MAME), **H9** (the fidelity gate HERE,
  `ci_static`), the harness SKILL, living docs L1 → L4 → L2 → L3, then the
  open items.

## OPEN, IN ORDER

1. **H5, H7** (above), then H6, H9, the skill, living docs
   (`living_docs_scope.md` §4), then the open items below.
2. The eight defaults of `harness_scope.md` §7 are open to VETO — none
   blocks H5 or H7.
3. **A finding about this tree, not fixed (14z-135):** `run_all_static.sh`
   has no exit-0-after-shell-error branch (the sweep runner has, since
   14z-134); the demand-after-trap lint is what prevents the shape. Fix it
   here only if the maintainer wants the two runners identical.
4. **A second finding about this tree, not fixed (14z-136):**
   `tests/lib/enumerate_expectations.sh` has no `diverge` case — a live
   `.diverge` expectation would be reported UNKNOWN-KIND by
   `audit_legacy_pairings`. Harmless today (zero live `.diverge` files);
   the harness's copy has the case.
5. The standing items unchanged: the deferred `audit_mask_window_ff42a2`
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
