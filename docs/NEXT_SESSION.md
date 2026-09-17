# NEXT SESSION — orientation (rewritten at the 14z-161 CLOSE, 2026-09-17)

> Rewritten at every session close ([VSP-17]). ROLLOVER: the previous opener
> moves VERBATIM to the top of `NEXT_SESSION_HISTORY.md` — this file holds ONLY
> the live orientation. Session state, not knowledge: facts belong in the docs,
> status in STATE.md.

## #151 STEP 3 IS DONE BY MEASUREMENT: NO GATE IN THE TREE READS A LATCHED BYTE WITH A VALUE A REAL PICK WOULD NOT WRITE. The confirm's flavor table has two rows (Phobos's cell 00, Donovan's 01), only their code reads it, and the id copies are read in play by nothing. Three gates freeze that. NO SHIPPED ROM BYTE MOVED; THE TREE IS AT merged-m18.

M18 (`merged-m18`, `build/m3b_merged26`) is still the current freeze and release.
`git status -sb` says the push state. The withdrawn M19 build dirs (`don_m23`,
`hui58`, `pyron42`, `m3b_merged28`, `m5_stock18`, `don_stage4_m19`) are on disk,
UNREGISTERED — do not play them and do not point a gate at them.

## START HERE — what is open

- **#151 — steps 1-3 are done; closing it is the maintainer's call.** Step 3's
  answer is in STATE 14z-161 and on the issue: the census (`tests/test_poked_legs.sh`),
  the reader population (`tests/test_latch_readers.sh`) and the per-leg taps
  (`tests/audit_latch_reads.sh`). If a rig ever needs a real path,
  `tools/select_paths.py --rpl-prologue <p1 cell> <p2 cell>` emits it for either wheel.
- **#136 — THE FULL RE-EXAMINATION CONTINUES (maintainer's insistence, 14z-160).** The
  13 DIVERGES rows: on Phobos two families — **Plasma Trap** (parts 2, 9) and the
  **Reflect Wall guard-cancels** (5, 6, 8) — plus Ray of Doom at +0f; Pyron 3 (Sitting
  Attack off a throw) and 4 (Piled Hell); Donovan 2, 3, 4, 6, 7 (two of which are the
  maintainer's own rulings, STATE 14z-159 (1)). Each family is a root-cause and a ticket
  of its own; captures before conclusions ([VSP-136]). The maintainer's testimony
  (2026-09-16): these are the moves imported in several passes or tweaked. Every #136
  verdict now rests on real picks both sides (14z-160) and on legs the sweep found
  faithful (14z-161) — the apparatus is clean; the families are the work.
- **#152** (the adversarial rule-checker), **#150** (the freeze ritual's silent-green
  modes) and **#148** (the static tier's cost) are filed and unstarted.
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
