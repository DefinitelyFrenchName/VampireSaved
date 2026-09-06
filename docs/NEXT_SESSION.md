# NEXT SESSION — orientation (rewritten at the 14z-135b CLOSE, 2026-09-06)

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

`~/Developer/blackbox-harness` (`bbh`), a SEPARATE repository, PUBLIC at
https://github.com/DefinitelyFrenchName/blackbox-harness (branch `main`; pushing it is
standing-authorised since 14z-135b — clone or fork it from there). H1 is
at `803f372`: `bin/bbh run-static | classify | tier | config |
demand-after-trap | doctor | selftest`; `selftest/run.sh` is its pre-commit
gate (7/0/0 at the close). Read its `README.md`, `docs/gate_contract.md`,
`docs/config.md`; the consumer config for THIS tree is
`example/consumers/bbh.vampire.toml` (kept there by decision 8 of the scope).
`selftest/test_fidelity_vampire.sh` proves F1 (identical runner output) and
F3 (the tier classifier reproduces both registries) against this tree at
every selftest run; F2 (the whole portable tier through both runners) is
opt-in with `BBH_FIDELITY_F2=1` and never beside another gate run here.

## WHERE THE HARNESS IS NOW: H1 + H2 LANDED (`803f372`, `ef7e899`)

`bbh selftest` is 13 gates, 13 PASS (~1 min; `BBH_FIDELITY_F5=1` runs F5
over all 1,891 masked specs, ~4 min — do that at every slice's pre-commit).
Fidelity so far: F1 identical, F3 exact, F5 exact (1,891/1,891). The
comparison classes are `lib/py/bbh/compare_*.py` + `thresholds.py` +
`logfmt.py`; the vocabulary is `lib/sh/masked_compare.sh`; the method
document is `docs/method/oracle_classes.md`.

## NEXT: SLICE H3 — fingerprint, the suite runner, the fake driver

The largest slice; it designs the example MACHINE. Read `harness_scope.md`
§2.3, §2.4 (I2 the driver contract), §3.4 (fakesys) and §4's H3 row first.
Lift `tools/build_fingerprint.py` → `fingerprint.py` (`[fingerprint]`: kind,
set glob, member regex, parent sets, region rules — no `cps2_decrypt`),
`tests/run_suite.sh` → `bin/bbh-run-suite` (fingerprint → set; every replay
run `runs_per_replay` times; dispatch `.skip` → `.pending` FAIL → `.masked` →
`.diverge` → `.sha1` → NO-EXPECTATION FAIL; `--freeze`; the hermetic env
scrub; the driver named by `[suite].driver`), `drivers/README.md` (THE
CONTRACT: `<set> <replay.rpl> <out.log> [sandbox]` + env; a driver that
cannot honour a variable REFUSES), `drivers/fake.sh` + `example/fakesys/
fakesys.py` (§3.4's env-selected shapes: base / hook / select / both /
attract / FAKE_NONDET / FAKE_CRASH_AT; MASK_RANGES, DUMPS, POKES, SNAP_FRAMES,
VIDEO_OUT, INPUT_INJECT_TEST), the example's replays + expected tree
(registry.tsv, base/{MASK,logs/}, build-a, build-b differing in one
non-program member — the dual-key case — and an unregistered third).
Ground truth: `test_suite_dispatch.sh` §1/1b on synthetic zips, §2; NEW
`test_suite_dispatch` over the fake driver; `test_driver_contract`. Then
F6 (fingerprint on `$ROMDIR` + every `build/*/rompath`, and the synthetic
twin) and F7 (suite dispatch over `tests/expected/<set>/` with the fake
driver via a shadow root). Rule 1 of the fidelity contract still holds:
`run_suite.sh`'s printed verdict lines are frozen text.

## OPEN, IN ORDER

1. **H3** (above), then H4/H5/H7, H6, H9 (the fidelity gate here,
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
