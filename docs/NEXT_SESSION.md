# NEXT SESSION — orientation (rewritten at the 14z-155 CLOSE, 2026-09-14)

> Rewritten at every session close ([VSP-17]). ROLLOVER: the previous opener
> moves VERBATIM to the top of `NEXT_SESSION_HISTORY.md` — this file holds ONLY
> the live orientation. Session state, not knowledge: facts belong in the docs,
> status in STATE.md.

## THE 74 AUDIT ROWS ARE ANSWERED, TWO TEST-INTEGRITY HARDENINGS ARE IN, AND THE README HAS ITS PLAY, REPORT AND READ-MORE SECTIONS — BUT THE CLOSE TIER WENT RED ON A HARNESS FLAKE AND NOTHING OF 14z-155 IS PUSHED. NO SHIPPED ROM BYTE MOVED.

M18 (`merged-m18`, `build/m3b_merged26`) is still the current freeze and
release. `git status -sb` says the push state.

## START HERE — what is open

- **FIRST: THE 14z-155 CLOSE WAS NOT GREEN, AND NOTHING OF IT IS PUSHED** (maintainer, 2026-09-14:
  *"Commit, don't push"*). Local `main` carries the three 14z-155 commits, the two README merges,
  the README commit and the close commit. The one red, `test_bbh_fidelity` F1: both runners
  order the `(costliest controls: …)` list by whole seconds per gate, and F1's `norm()` masks the
  figures (`Ns`) but not the order they produce, so the list reorders whenever a synthetic control
  crosses a second boundary in one run only (the gate re-run alone passed). Fix it in bbh
  (`selftest/test_fidelity_vampire.sh`: mask the costliest-controls list in F1's comparison, with a
  dated line in its `docs/rebaselines.md`; bbh selftest and fidelity green; push bbh), then run
  `tests/run_all_static.sh --strict` again with every control, and push `main` on green.
- **THEN: THE README'S REMAINING DETAILS** (maintainer, 2026-09-14: *"Let's finish
  working on the other details of the README in the next session"*). The readability
  proposals given at the 14z-155 close, none applied, for the maintainer to take or
  leave one by one:
  1. the thank-you line is a `###` heading: a paragraph, or a "Thanks" section at the end;
  2. a short title (`# Vampire Saved`) plus a one-line subtitle;
  3. the order: summary, Get it and play it, Status, Report a problem, the "about this
     project" disclaimer, the docs map, Licence;
  4. "Implementation specifics" split into how the three were brought in, known
     limitations, and extras;
  5. "shell" defined once in plain words, and the "HOWEVER !" bullet broken into sentences;
  6. internal jargon out ("maintainer-ruled 2026-08-22", "CLAUDE.md rule 7", "not a gate");
  7. one spelling of CPS-2; VS and VS2 spelled out once; Huitzil/Phobos named once;
  8. "byte-for-byte" becomes "identical, within a few small measured tolerances";
  9. typos: "would have borderline impossible", "officila", "a competitive-ready",
     "forward of back", "Japan - 970519", missing full stops.
  **And capture the README's MAME recording command as an emulator-tier gate.** The 14z-155
  smoke test (record and playback exit 0 on the release macOS `cps2` with the M18 build)
  was run by hand, and [VSP-18] does not let a check stay manual.
- **ASK THE MAINTAINER: file the static runner's controls-ledger defect?** Seen 14z-155,
  not filed. `vs_classify` (`tests/lib/classify.sh`) reads a gate's controls only on PASS,
  and `tests/run_all_static.sh` then re-adds the PREVIOUS gate's counts for a failing gate:
  `fired 175 / declared 175` on a NOT GREEN run whose headers give 172. Verdicts and green
  runs are unaffected; the harness's `lib/sh/classify.sh` and `bin/bbh-run-static` carry the
  same lines.
- **THE BACKFILL, SECOND HALF: #75-#114** (40 rows in `tests/expected/tickets_debt.txt`).
  The method is in commit `fcf8ff1a`'s message: each thread read to its closing comment and
  checked at HEAD, sessions from the commits a thread cites, `learned`/`wrong` to live
  documents only, the TSV written by a script and checked on a copy first.
- **#135**, the VS-vs-VS2 tick cadence; **#136** (tenant move parity) waits behind it.
- Every other open ticket is on `docs/project/tickets.md` ("Open and parked"), #138 among
  them; the harness has BBH-frame-based #1.

## TRAPS PAID THIS SITTING

1. **A strict tier started inside a background task dies with it** — start it from a
   foreground call and wait from a separate task (now a project gotcha).
2. **A watcher must print what was logged after its last poll** — a red run's second FAIL
   went unreported.
3. **A text lint matches its banned pattern inside a printed message** — describe the
   construct in words (now a project gotcha).
4. **A dispositions TABLE is a snapshot** — 41 "open" rows had all been closed on GitHub
   since; read each issue's closing comment.
5. **"Recorded nowhere" is a claim about a search's scope** — the orange P2 sword is the
   medallion fix's accepted trade in `docs/project/patch_index.md`, a file the search skipped.

**IF A DOC IS TOUCHED:** the eight `--check`s plus `tools/check_state_lists.py` and
`tools/tickets.py check`, exit statuses captured directly, `${=cmd}` in zsh. **A
running script is never edited** ([MSC-54]). **The static tier is never run beside
another gate run, or heavy work, in this tree.**
