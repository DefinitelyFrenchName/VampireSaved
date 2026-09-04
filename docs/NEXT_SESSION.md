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
> ## # THREAD 1 — M16 IS BUILT, MEASURED AND UNREGISTERED
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
