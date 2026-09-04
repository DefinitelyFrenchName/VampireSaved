# NEXT SESSION — orientation (rewritten mid-session 14z-132, 2026-09-04)

> Rewritten at every session close ([VSP-17]). ROLLOVER: the previous opener
> moves VERBATIM to the top of `NEXT_SESSION_HISTORY.md` — this file holds ONLY
> the live orientation. Session state, not knowledge: facts belong in the docs,
> status in STATE.md.

> ## **WORK IS IN FLIGHT. THIS IS NOT A CLEAN OPENER.** Written mid-session
> ## against context pressure, so a cold start loses nothing. Three threads,
> ## none finished, none blocked on anything but sequence.
> ##
> ## **STATE.md IS 204 KB AND OWES A ROLLOVER AT CLOSE** (~150 KB threshold;
> ## the slice boundary is the `**SPLIT 2026-08-20` paragraph, ledger between).
> ##
> ## # THREAD 1 — M16 IS FROZEN. STATIC IS GREEN. THE EMULATOR TIER IS NOT RUN.
> ##
> ## **DONE 14z-132 (1)-(5):** the mark set and measured, B1 shipped, the three
> ## solo rows registered on WHOLE-SET keys, the 162-line re-point sweep, the
> ## MiSTer CRC tail (fork `ff5dee9d8`, pushed), the whole-artifact manifests
> ## re-frozen, all four `freeze/*` tags, patch_notes 14z-132.
> ## **STATIC TIER 130/0/0/0 GREEN.**
> ##
> ## **WHAT M16 IS:** `version_text` M13 -> M16, i.e. ONE CHARACTER of ONE
> ## authored glyph. Delta measured on all five tracks: exactly `vsw.33m` +
> ## `vsw.37m` on the four WIDE tracks, **ZERO on the stock twin**, program
> ## untouched everywhere. Builds `don_m20` / `hui54` / `pyron38` /
> ## `m3b_merged23` / `m5_stock15`.
> ##
> ## **THE THREE THINGS LEFT, none blocked:**
> ## 1. **THE FREEZE SUITE** — emulator tier, ~2h44m at romset cadence
> ##    (`tests/run_all_emulator.sh --freeze`). NOT RUN. Expect pure carries:
> ##    no program byte moved on any track.
> ## 2. **`release/merged-m16/`** — `tools/package_release_platforms.py`.
> ## 3. **THE CARD BUNDLE** — `tools/mister_mra.sh --core cps2w --wide
> ##    build/m3b_merged23 --out <dir outside the repo>` plus the zips. **The
> ##    maintainer is waiting on this to field-test; the CRC tail it needed is
> ##    DONE, so nothing else gates it.**
> ##
> ## # THREAD 1b (superseded detail) — M16'S REGISTRATION
> ##
> ## **DONE 14z-132 (2)/(3): B1 shipped and the three SOLO rows registered.**
> ## `donovan-m20` / `huitzil-m27` / `pyron-m21` carry WHOLE-SET keys
> ## (`52756b2f` / `e1ed7d9f` / `1264ca1f`); expectation sets copied from
> ## m19/m26/m20; `donovan-m19-stock` and `donovan-m19-stage4` CARRY (both
> ## measured unchanged by rebuild). Old builds still resolve to old names,
> ## new builds to new names, **and no predecessor row had to be commented
> ## out — the first freeze in four.**
> ## **THE RE-POINT SWEEP IS THE NEXT BIG THING AND IT IS NOT STARTED: 134
> ## files name `don_m19` / `hui53` / `pyron37` / `m3b_merged22` /
> ## `m5_stock14`** (14z-130's was 137 and it walked into the documented
> ## history-rewriting trap, needing 13 dated records restored — a dated log
> ## entry saying "measured on build/don_m18" must NOT be re-pointed).
> ## **ALSO OUTSTANDING:** the four `freeze/*` tags; patch_notes 14z-132;
> ## the merged row (see the question below); the freeze suite; the MiSTer
> ## CRC tail; `release/merged-m16/`; the bundle.
> ##
> ## **ONE QUESTION FOR THE MAINTAINER, DELIBERATELY NOT DECIDED:** what
> ## expectation set does the `merged-m16` row name? `tests/expected/merged1/`
> ## is the BLANKS-ONLY instrument's class table (47 `.masked`), and pointing
> ## the shipped merged build at it changes what `run_suite` does with a build
> ## it currently refuses BY DESIGN — the thing `registry.tsv`'s header warns
> ## about at length. Options: (a) reuse `merged1`; (b) a new
> ## `tests/expected/merged-m16/` seeded from it; (c) DEFER the merged row to
> ## B2, where the three legacy-oracle gates that need it are re-pointed and
> ## the set can be decided with them. **Recommendation: (c)** — the row's
> ## whole purpose is to unblock those gates, and registering it now creates a
> ## row nothing uses while forcing the set question early.
> ##
> ## # THREAD 1 (original) — WHAT M16 IS
> ##
> ## The version-numbering ruling (option A: the wheel mark IS the merged build
> ## number) is EXECUTED as far as building. Five tracks on disk:
> ## `don_m20` / `hui54` / `pyron38` / `m5_stock15` / `m3b_merged23`.
> ## **Delta measured: exactly `vsw.33m` + `vsw.37m` on the four WIDE tracks and
> ## ZERO members on the stock twin.** Every program fingerprint UNCHANGED.
> ## `test_version_string` PASS on all four WIDE tracks (pixel-exact snapshot,
> ## both verdict controls fired). Static tier **128/0/2** — both reds
> ## (`test_m3a_reproducible`, `test_charmap_current`) are freeze bookkeeping
> ## owed by the registration, both predicted, neither a defect.
> ## **STILL OWED:** the version-mark gate (anchor RULED: the newest annotated
> ## `freeze/merged-m<N>` tag); registration; freeze suite; MiSTer CRC tail
> ## (the two glyph members moved, so the fork catalogue needs a new `vsavjw`
> ## entry or no `.rom` builds); `release/merged-m16/`; the card bundle.
> ## **The maintainer is waiting to field-test and asked to be unblocked** —
> ## the bundle needs only the MiSTer tail, NOT registration and NOT thread 2.
> ##
> ## # THREAD 2 — THE DISPATCH KEY (B1 then B2), RULED, NOT STARTED
> ##
> ## Forward-only promotion of the whole-set fingerprint, merged rows
> ## FULL-SET-KEYED ONLY. Full spec, measurements and the plan split:
> ## STATE "THE DISPATCH KEY". **B1 is mechanism-only and its acceptance is
> ## "everything resolves exactly as today"; B2 re-points three gates and is
> ## open-ended. B1 goes BEFORE M16's registration** so M16 lands natively
> ## instead of needing a fourth comment-out row.
> ## **The one detail that will bite if forgotten: the key is computed over the
> ## BUILD'S OWN rompath directory and a `;` chain is REFUSED** — `--full` is
> ## chain-dependent (`fcc83fc3` vs `544990c4` for one build).
> ##
> ## # THREAD 3 — THE MERGED/SOLO WALK, 2 OF 25
> ##
> ## The general rule is ruled and is now [VSP-175] +
> ## `docs/project/gate_scoping_method.md` §9: a gate is solo-specific only if a
> ## single-tenant build is the SUBJECT of its assertion. Solo-specific => out
> ## of release scope; no meaningful merged form => deprecate permanently, keep
> ## as history. **Gate 1 `test_dualtrack` RULED stock-vs-merged. Gate 2
> ## `audit_legacy_pairings` is NOT a re-point** — it and the other two
> ## legacy-oracle gates resolve their expectation set by fingerprint and wait
> ## on thread 2. The inventory, the groups and the standing prediction (the
> ## exception clause may have ZERO members) are in STATE "MERGED-VS-SOLO TEST
> ## SCOPING". **The maintainer wants this walked ONE GATE AT A TIME, with the
> ## analysis put in front of them before anything is touched — they expect to
> ## catch errors I cannot see, and did so on gate 1.**
> ## **Flagged, not yet walked:** `audit_trap_sound` is release-scope and
> ## defaults to `build/hui30`, a 14z-82c build — a release gate asserting about
> ## something we do not ship, independent of the merged question.
> ##
> ## # OPEN, OPTIONAL, ONE LINE TO ADOPT
> ##
> ## Call a freeze by a single GENERATION number equal to the merged build's, so
> ## one number resolves to all five tracks. Offered 14z-132, not ruled. The
> ## build-directory counter runs at four different offsets from the freeze name
> ## (donovan +0, merged +7, pyron +17, huitzil +27, verified over six freezes);
> ## renaming dirs is REFUSED (~55 gates reference the paths).
> ##
> ## **IF A DOC IS TOUCHED:** census `--check` + `checkdocshape --no-pending` +
> ## checkdocs + checkskills + `gen_annotations --check` + `gen_gate_index
> ## --check` + `gen_gotchas_index --check` + `doc_anchor_census --check`,
> ## exit statuses captured directly. **Adding an anchored `**[VSP-N]**` obliges
> ## the skill to DEFINE it — checkskills fails otherwise, and the census must be
> ## re-frozen (`doc_anchor_census.py --freeze`).**
