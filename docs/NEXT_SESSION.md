# NEXT SESSION — orientation (rewritten at the 14z-158 CLOSE, 2026-09-15)

> Rewritten at every session close ([VSP-17]). ROLLOVER: the previous opener
> moves VERBATIM to the top of `NEXT_SESSION_HISTORY.md` — this file holds ONLY
> the live orientation. Session state, not knowledge: facts belong in the docs,
> status in STATE.md.

## #135 IS CLOSED: THE EXTRA LOGIC PASS IS THE PLAY MODE'S SPEED LEVEL, AND A CROSS-GAME COMPARISON NEEDS A MATCHED LEVEL AND A PINNED RNG ([VSE-84]). #142 CLOSED INVALID. NO SHIPPED ROM BYTE MOVED.

M18 (`merged-m18`, `build/m3b_merged26`) is still the current freeze and
release. `git status -sb` says the push state.

## START HERE — what is open

- **#136 (tenant move parity) is unblocked.** Compare every leg at a pinned speed level (`RAM:$FF8116`)
  and a pinned RNG (`RAM:$FF80D4-D5`), proven from each leg's dump —
  `tests/test_don_immortal_native.sh` is the worked form. It also holds #109's clone-beam contact leg.
- **#143 — `tests/lua/walker_sp.lua` reads the supervisor stack**, and two walker audits consume its
  ranges. Ruled 2026-09-16: solve it CAUTIOUSLY — measure which stack is live at the walker sites
  before changing the instrument (the issue carries the order).
- Every other open ticket is on `docs/project/tickets.md` ("Open and parked"), #138, #140 and #141
  among them; the harness has BBH-frame-based #1.

## TRAPS PAID THIS SITTING

1. **A comparison that never touches a game's own menu inherits its DEFAULTS** — vsav2's default play
   mode is TURBO and vsavj's NORMAL, and one session's "engine difference" was that. Before calling two
   legs' behaviour a game difference, list every setting each leg chose by default.
2. **A second confound can hide behind the first** — matched modes left one difference, and it was the
   RNG. Pin both, then compare to the frame.
3. **MAME 0.288's M68000 has no `A7` state and its `SP` is the supervisor stack** — a Lua stack read in
   this game's user-mode code walks the idle stack, and inside a write tap a nil state dies silently.
4. **Load the project's skills before rewriting a gate** — they carried three rule lines restating the
   claim being retracted.
5. **A fact held from outside the tree is unmeasured, however sure it feels** — I told the maintainer
   "Huitzil is the Japanese name" from memory; vsav2 (Japan) shows **Phobos** on its select screen and
   HUD (captured 2026-09-16). The maintainer uses the Japanese names.

**IF A DOC IS TOUCHED:** the eight `--check`s plus `tools/check_state_lists.py` and
`tools/tickets.py check`, exit statuses captured directly, `${=cmd}` in zsh. **A
running script is never edited** ([MSC-54]). **The static tier is never run beside
another gate run, or heavy work, in this tree.**
