# NEXT SESSION — orientation (rewritten at the 14z-156 CLOSE, 2026-09-15)

> Rewritten at every session close ([VSP-17]). ROLLOVER: the previous opener
> moves VERBATIM to the top of `NEXT_SESSION_HISTORY.md` — this file holds ONLY
> the live orientation. Session state, not knowledge: facts belong in the docs,
> status in STATE.md.

## THE BACKFILL IS COMPLETE (DEBT 0), THE F1 FLAKE IS FIXED, #140 IS FILED, AND #135 HAS ITS FIRST MEASUREMENT: VSAV2 DOUBLES ITS LOGIC PASS EVERY THIRD FRAME, VSAVJ EVERY FOURTH OR FIFTH. NO SHIPPED ROM BYTE MOVED.

M18 (`merged-m18`, `build/m3b_merged26`) is still the current freeze and
release. `git status -sb` says the push state.

## START HERE — what is open

- **#135 CONTINUES.** Steps 1-2 landed at 14z-156 (`tests/audit_tick_cadence.sh`, the 14z-156 addendum in
  `docs/game/engine_internals.md`, the issue comment). Next, cheapest first:
  1. the DECIDER of the second pass — a debugger call chain from the tick site
     (`PRG:0x027F70` / vs2 `0x0271C4`) up to the loop that runs the pass twice, on a
     throwaway run (the debugger desyncs replays; the chain, not the timing, is wanted);
  2. the play-mode byte (NORMAL / TURBO / AUTO) read back on both legs, with TURBO as the
     positive control, and each game's EEPROM defaults;
  3. constancy across content, Demitri / Morrigan / Bishamon, FBNeo — the frame counter, a
     single `$FF8000-$FF83FF` bit or value and a work-RAM accumulator are already ruled out
     (section B of the audit, each search finding its plant);
  4. then the one section with its rule anchor, every carrier corrected in the same commit
     ([VSE-84] and its skill line, the six `[VSE-83]` citations, "four characters",
     `test_don_immortal_native.sh`'s header).
  **#136** (tenant move parity) waits behind it.
- **THE README'S REMAINING DETAILS** — the maintainer takes them (*"I'll do item 2 later"*):
  the nine readability proposals of 14z-155, and capturing the README's MAME recording
  command as an emulator-tier gate ([VSP-18]).
- Every other open ticket is on `docs/project/tickets.md` ("Open and parked"), #138 and #140
  among them; the harness has BBH-frame-based #1.

## TRAPS PAID THIS SITTING

1. **A selection made by wall-clock durations is not verdict text either** — masking the
   figures left the picks and their order compared (bbh F1, fixed).
2. **A search that finds nothing is not a result until a planted case has been found by it**
   — the accumulator search's control never ran (no numpy here), and two sibling searches
   were quoted with no plant at all; caught at the close check and re-run in plain python
   with plants, all three still find nothing. And **MAME's "Average speed … (48 seconds)" is
   EMULATED time** — a runtime read from it was ~10× too long.
3. **An accumulator can pause** — a constant-step-on-every-frame test rejects one that stops
   on zero-tick frames.

**IF A DOC IS TOUCHED:** the eight `--check`s plus `tools/check_state_lists.py` and
`tools/tickets.py check`, exit statuses captured directly, `${=cmd}` in zsh. **A
running script is never edited** ([MSC-54]). **The static tier is never run beside
another gate run, or heavy work, in this tree.**
