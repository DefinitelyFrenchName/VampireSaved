# NEXT SESSION — orientation (rewritten at the 14z-124 close, 2026-08-31)

> Rewritten at every session close ([VSP-17]). ROLLOVER (since 14z-122):
> the previous opener moves VERBATIM to the top of `NEXT_SESSION_HISTORY.md`
> — this file holds ONLY the live orientation. Session state, not knowledge:
> facts belong in the docs, status in STATE.md.

> ## **START HERE. NOTHING IS RED. NO BUILD CHANGED — the tree is still the
> ## M12 freeze (merged-m14 `6649523a`, `build/m3b_merged21`), FIELD-VERIFIED
> ## GREEN. Five commits are LOCAL past the pushed `719c560` (14z-124) — push
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
> ## **CLAUDE.md PASS 2 IS DONE TOO** (ruled and executed 2026-08-31): 344
> ## lines; the oracle-class spec of record is `docs/project/oracle_classes.md`
> ## ([VSP-27..30] live there — edit a class THERE, never in §4); the document
> ## roster is `docs/README.md` "The documents, by role".
> ##
> ## **OPEN THE SESSION WITH THE COMMUNITY CROSS-CHECK (item 2 below —
> ## the maintainer's order, 2026-08-31: "start with item 2 to get proper
> ## confirmed data").** First steps, in order: load `vampire-savior-engine`
> ## + `cps2-emulation`; read STATE "Decisions pending" → the cross-check
> ## entry (the rule, both sources, the first-pass inventory); (a) the
> ## VANILLA derivation — make `tools/charmap_gen.py` (or a sibling) walk a
> ## vsavj vanilla character's bank and emit the same per-chain
> ## startup/active/recovery the tenants' `chars/<t>_anim.md` carries;
> ## (b) a comparator against `../community/vsav-framedata.xlsx` (tab =
> ## first two letters of the Japanese name; the id map is in STATE) that
> ## classifies every column's deltas EXACT / CONSTANT OFFSET / INCONSISTENT
> ## per character; (c) the INCONSISTENT rows measured in-emulator on a
> ## vanilla replay (`field_trace`, hitbox state per frame) — the emulator
> ## arbitrates; (d) the wiki's player-struct map (146 offsets, 94 not in
> ## `ram.md`) against the atlas the same way, starting with the two
> ## disagreements (`+0x161`, `0x2246E`). Deliverable
> ## `docs/project/tables/community_crosscheck.md` + a gate; both sources
> ## stay OUT of the tree (cite them). Then item (1), whose lead — `+0x1B3`
> ## "Dark Force Startup" — the cross-check will have measured.
> ##
> ## **THREE ITEMS ARE QUEUED (maintainer, 2026-08-31), none started** —
> ## all in STATE "Decisions pending": (1) **DF-STARTUP INVINCIBILITY FOR
> ## THE TENANTS** — measure the [VSE-69] seam (shared activation body vs
> ## the per-character seq-0x16 handler) on replay 97's rig with a hit timed
> ## into the window, Demitri control + a positive control; (2) **THE
> ## COMMUNITY CROSS-CHECK** — our DERIVED tenant frame data
> ## (`chars/<tenant>_anim.md`) and a vanilla derivation to build vs the
> ## maintainer's `../community/vsav-framedata.xlsx` (15 vanilla characters,
> ## inventoried) and the mizuumi RE page (received as a PDF, text at
> ## `../community/mizuumi_reverse_engineering.txt`, inventoried — 146
> ## player-struct offsets, 94 not in `ram.md`; `+0x1B3` "Dark Force
> ## Startup" is item (1)'s lead; the 14z-123 advancing guard is their
> ## "Tech Hit", field for field); UNBLOCKED. THE RULE: EXACT or a
> ## CONSTANT OFFSET validates ours, an INCONSISTENT pattern means re-measure
> ## OURS in-emulator — the emulator arbitrates, never the sheet; (3) the
> ## **ZABEL j.LK
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
