# NEXT SESSION — orientation (rewritten at the 14z-124 close, 2026-08-31)

> Rewritten at every session close ([VSP-17]). ROLLOVER (since 14z-122):
> the previous opener moves VERBATIM to the top of `NEXT_SESSION_HISTORY.md`
> — this file holds ONLY the live orientation. Session state, not knowledge:
> facts belong in the docs, status in STATE.md.

> ## **START HERE. NOTHING IS RED. NO BUILD CHANGED — the tree is still the
> ## M12 freeze (merged-m14 `6649523a`, `build/m3b_merged21`), FIELD-VERIFIED
> ## GREEN. Four commits are LOCAL past the pushed `719c560` (14z-124) — push
> ## at the maintainer's word; check `git status -sb`, not this line.**
> ##
> ## **THE DOCUMENTATION RATIONALIZATION PASS IS DONE (14z-124, G7 closed).**
> ## `docs/doc_shape.tsv` has ZERO PENDING rows and `tests/test_docshape.sh`
> ## now runs `checkdocshape --no-pending` — a new document is classified at
> ## birth or the suite goes red; the ci floor is `n >= 60` portable gates.
> ## `engine_internals.md` is REFERENCE (STATUS banner, Atlas rows + Gates on
> ## every `##`; its chronology is `engine_internals_history.md`).
> ## `inferred_claims.md` is CLOSED (row 11 alone ruled-parked, #113).
> ##
> ## **NOTHING IS QUEUED AS WORK. TWO RULINGS WAIT** (STATE "Decisions
> ## pending"): (1) **CLAUDE.md PASS 2** — the structural cut (the oracle-class
> ## spec [VSP-27..31] to `docs/project/oracle_classes.md`; the §5 taxonomy
> ## list to `docs/README.md`; the recordings how-to to HANDOFF); it moves
> ## anchored law out of the constitution, so it is the maintainer's call —
> ## if ruled, the method is the pass's (a restructure script, per-hunk
> ## review, census re-freeze, checkskills green). (2) the **ZABEL j.LK
> ## PROXIMITY GUARD** — its own session; a LEGACY-content patch needing its
> ## own track/flag and expectation class; START WITH A RECORDING ([VSP-20]),
> ## then archaeology ([VSP-14]), then measure vanilla's proximity-guard test
> ## on every other normal before touching a byte.
> ##
> ## **IF A DOC IS TOUCHED:** the per-commit battery is census `--check`
> ## (`--freeze` only after reviewing renames) + `checkdocshape --no-pending`
> ## + checkdocs + checkskills + `gen_annotations.py` regenerated from a CLEAN
> ## WORKTREE of the commit's files + `gen_gate_index.py --check`, exit
> ## statuses captured directly; wrapped `##` headers are house style and any
> ## new section-level check must be wrap-aware (14z-124's tooling fix).
> ##
> ## **OPEN, unchanged:** the 1:1 wheel mockup; #112/#113 parked; the FBNeo
> ## two-run-family question; the tenant CPU AI "lackluster" note; win quotes
> ## forgone; the COSMETIC BACKLOG (incl. the 1P roulette-tag row).
> ## `test_random_select_tenants.sh`'s CONTROL is still `build/m3b_merged19`;
> ## `test_hui_df_style.sh`'s header still describes its 14z-79 `differs`
> ## expectation (a stale gate header, not a defect — the DF section says so).
> ##
> ## **STATE OF THE BUILDS:** unchanged — play `tools/run_wide.sh
> ## build/m3b_merged21 fbneo`; current + one back: `don_m17/m18`,
> ## `hui51/52`, `pyron35/36`, `m3b_merged20/21` (+ `merged19` control),
> ## `m5_stock12/13`.
