# NEXT SESSION — orientation (rewritten at the 14z-160 CLOSE, 2026-09-16)

> Rewritten at every session close ([VSP-17]). ROLLOVER: the previous opener
> moves VERBATIM to the top of `NEXT_SESSION_HISTORY.md` — this file holds ONLY
> the live orientation. Session state, not knowledge: facts belong in the docs,
> status in STATE.md.

## #151 STEPS 1 AND 2 ARE DONE: A POKED NATIVE LEG GETS EXACTLY THREE BYTES WRONG, THE #136 VERDICTS ARE RE-FROZEN ON REAL CURSOR PICKS BOTH SIDES (14 IDENTICAL / 13 DIVERGES), AND #149 AND #147 ARE CLOSED INVALID. NO SHIPPED ROM BYTE MOVED; THE TREE IS AT merged-m18.

M18 (`merged-m18`, `build/m3b_merged26`) is still the current freeze and release.
`git status -sb` says the push state. The withdrawn M19 build dirs (`don_m23`,
`hui58`, `pyron42`, `m3b_merged28`, `m5_stock18`, `don_stage4_m19`) are on disk,
UNREGISTERED — do not play them and do not point a gate at them.

## START HERE — what is open

- **#151 STEP 3 — the sweep.** 37 gates still run a poked native leg (the list is in
  STATE 14z-160; the victim rigs alone feed eight). For each: does it read anything the
  confirm latches (`+0x3C2` flavor, `+0x3BD`/`+0x3E0` id copies)? Where the subject can
  depend on those, switch to a real path — vsav2 P1: Phobos L,L,L / Pyron R,R,R /
  Donovan R,R; P2: Victor R,R / Phobos L,L / Pyron L,L,UL / Donovan R,R,R; merged wheel
  P1: Phobos D,D,D / Pyron D,D,D,D / Donovan D,D,DR,DR — and re-freeze with the
  change named. The victim rigs (`name_moves.py` `*_victim`) are the natural first
  batch: give them `path`/`path_p2` and re-freeze their eight consumers together.
- **#136 — THE FULL RE-EXAMINATION CONTINUES (maintainer's insistence, 14z-160).** The
  13 remaining DIVERGES rows are now real: on Phobos two families — **Plasma Trap**
  (parts 2, 9) and the **Reflect Wall guard-cancels** (5, 6, 8) — plus Ray of Doom at
  +0f; Pyron 3 (Sitting Attack off a throw) and 4 (Piled Hell); Donovan 2, 3, 4, 6, 7
  (two of which are the maintainer's own rulings, STATE 14z-159 (1)). Each family is a
  root-cause and a ticket of its own; captures before conclusions ([VSP-136]). The
  maintainer's testimony (2026-09-16): these are the moves that were imported in several
  passes or tweaked, so a divergence there is expected — the first place to look.
- **#152** (the adversarial rule-checker), **#150** (the freeze ritual's silent-green
  modes) and **#148** (the static tier's cost) are filed and unstarted.
- Every other open ticket is on `docs/project/tickets.md`; the harness has BBH-frame-based #1.

## TRAPS PAID THIS SITTING

1. **The tap's mask column names the byte** (`ff00` = the even address, `00ff` = its odd
   neighbour): the first reading of the confirm's writers named the writers of `+0x3C3`
   and `+0x3BC`. Query mask-aware before naming a writer.
2. **zsh, twice more**: `for path in …` empties `PATH` (`path` is the tied array), and
   `for m in $route` iterates ONCE — `${=route}`. A probe contradicted a correct gate
   until the second was fixed.
3. **A reducer's diagnostics on stdout became its verdict line**; a difference that exists
   only before the poke was filed as in-play; a latched byte set the first in-play frame
   to the window's start. Each was caught by reading the MEASURE output, not by a gate.
4. **A census gate with no freeze switch and a `head -20` on its diff** would have hidden
   a hunk; it has `FREEZE=1` now.

**IF A DOC IS TOUCHED:** the eight `--check`s plus `tools/check_state_lists.py` and
`tools/tickets.py check`, exit statuses captured directly, `${=cmd}` in zsh. **A
running script is never edited** ([MSC-54]). **The static tier is never run beside
another gate run, or heavy work, in this tree.**
