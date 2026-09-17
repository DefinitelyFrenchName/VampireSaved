# NEXT SESSION — orientation (rewritten at the 14z-161 CLOSE, 2026-09-17)

> Rewritten at every session close ([VSP-17]). ROLLOVER: the previous opener
> moves VERBATIM to the top of `NEXT_SESSION_HISTORY.md` — this file holds ONLY
> the live orientation. Session state, not knowledge: facts belong in the docs,
> status in STATE.md.

## 14z-162 CORRECTED A TRUST BREACH: #151 AND #136 WERE NOT CLOSED BY THE MAINTAINER — a commit subject `14z-N CLOSE: #<n>` is a GitHub closing keyword and closed them on push, and the 14z-161 session then recorded #151's close as the maintainer's deliberate act (it was never asked). #151 REOPENED then CLOSED PROPERLY by explicit maintainer ruling (both conditions met: #136 open and documenting the 13 divergences); the false claim retracted in STATE row (8), the ticket index, and on the issue. Guarded now by `tools/check_commit_subject.py` + `tests/test_commit_subject.sh` and a `commit-msg` hook (`tools/install_hooks.sh`). The session's GitHub account is now `mechanyaa-ai`, distinct from the maintainer's `DefinitelyFrenchName`, so an actor field distinguishes the two; git author identity is set per repo. Gotcha: `docs/project/gotchas.md` "A COMMIT SUBJECT THAT NAMES AN ISSUE AFTER A CLOSING KEYWORD".

## THE CLOSE TIER RAN IN FULL AT 14z-161b (156 / 0 / 0, 176 controls executed and honoured) AFTER A CLOSE THAT HAD PUSHED ON THE MID-SESSION FORM — the safeguard stands until #148. #151 STEP 3 IS DONE BY MEASUREMENT: NO GATE IN THE TREE READS A LATCHED BYTE WITH A VALUE A REAL PICK WOULD NOT WRITE. The confirm's flavor table has two rows (Phobos's cell 00, Donovan's 01), only their code reads it, and the id copies are read in play by nothing. Three gates freeze that. **#151 CLOSED done (14z-162) by the maintainer's conditional ruling; #136 stays open with all 13 divergences documented and is the work.** NO SHIPPED ROM BYTE MOVED; THE TREE IS AT merged-m18.

M18 (`merged-m18`, `build/m3b_merged26`) is still the current freeze and release.
`git status -sb` says the push state. The withdrawn M19 build dirs (`don_m23`,
`hui58`, `pyron42`, `m3b_merged28`, `m5_stock18`, `don_stage4_m19`) are on disk,
UNREGISTERED — do not play them and do not point a gate at them.

## START HERE — what is open (THE ORDER IS RULED, 2026-09-17: stable state, then #148, then #152, then everything else)

- **#148 FIRST — the static tier's cost.** The maintainer, at the 14z-161 close: *"as soon as
  we are in a state we know to be stable and reliable we should tackle #148, there is much
  time to gain there"* — and the safeguards are NOT to be compromised until it is worked
  (`DECISIONS_HISTORY.md` "Ruled 2026-09-17 (14z-161b)"). The measured shape of the cost:
  the close tier is 2,489 s wall — gates 1,278 s, controls 1,203 s, the costliest controls
  `test_mister_wide_gate` (236 s over 7), `test_docshape` (141 s over 15),
  `test_release_roundtrip` (114 s over 8) (`build/gates_14z161/static_close.log`).
- **#152 SECOND — the adversarial rule-checker at every decision point.**
- Then everything else, in this order:
- **#136 — THE FULL RE-EXAMINATION CONTINUES (maintainer's insistence, 14z-160).** The
  13 DIVERGES rows: on Phobos two families — **Plasma Trap** (parts 2, 9) and the
  **Reflect Wall guard-cancels** (5, 6, 8) — plus Ray of Doom at +0f; Pyron 3 (Sitting
  Attack off a throw) and 4 (Piled Hell); Donovan 2, 3, 4, 6, 7 (two of which are the
  maintainer's own rulings, STATE 14z-159 (1)). Each family is a root-cause and a ticket
  of its own; captures before conclusions ([VSP-136]). The maintainer's testimony
  (2026-09-16): these are the moves imported in several passes or tweaked. Every #136
  verdict now rests on real picks both sides (14z-160) and on legs the sweep found
  faithful (14z-161) — the apparatus is clean (#151 closed done 14z-162 by maintainer ruling); the families are the work.
- **#150** (the freeze ritual's silent-green modes) is filed and unstarted.
- Every other open ticket is on `docs/project/tickets.md`; the harness has BBH-frame-based #1.

## TRAPS PAID THIS SITTING

1. **zsh, again**: `set -- $var` does not word-split — `${=var}`. Eight taps ran on the
   wrong fields and overwrote each other's files; the tell was an output file named by a
   poke string.
2. **A tool copied to a scratch dir resolves `REPO` from its own path** — pin it in the
   copy, or the perturbed copy measures nothing and says so only by a missing file.
3. **A census gate scans itself**: its literal fixture became a finding. Assemble the
   forbidden token from pieces ([VSP-181]).
4. **A poked-vs-real diff is a route diff plus a cell diff**: without a second real route
   to the same cell, route residue reads as the poke's doing (project gotchas, 14z-161).

**IF A DOC IS TOUCHED:** the eight `--check`s plus `tools/check_state_lists.py` and
`tools/tickets.py check`, exit statuses captured directly, `${=cmd}` in zsh. **A
running script is never edited** ([MSC-54]). **The static tier is never run beside
another gate run, or heavy work, in this tree.**
