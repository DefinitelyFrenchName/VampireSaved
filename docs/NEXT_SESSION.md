# NEXT SESSION — orientation (rewritten at the 14z-157 CLOSE, 2026-09-15)

> Rewritten at every session close ([VSP-17]). ROLLOVER: the previous opener
> moves VERBATIM to the top of `NEXT_SESSION_HISTORY.md` — this file holds ONLY
> the live orientation. Session state, not knowledge: facts belong in the docs,
> status in STATE.md.

## EVERY ITEM THE #75-#114 THREADS LEFT IS RULED AND CARRIED (#141 FILED), THE STALE LIVE CLAIMS ARE CORRECTED, AND RAM:$FF8130's WRITERS ARE MEASURED. NO SHIPPED ROM BYTE MOVED.

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
  **#136** (tenant move parity) waits behind it; it now also holds #109's clone-beam contact leg (14z-157).
- **THE README'S REMAINING DETAILS** — the maintainer takes them (*"I'll do item 2 later"*):
  the nine readability proposals of 14z-155, and capturing the README's MAME recording
  command as an emulator-tier gate ([VSP-18]).
- Every other open ticket is on `docs/project/tickets.md` ("Open and parked"), #138 and #140
  among them, and #141 (the full FBNeo legacy track, parked since 14z-157); the harness has
  BBH-frame-based #1.

## TRAPS PAID THIS SITTING

1. **A retraction grep that matches a claim's WORDING misses its paraphrases** — `id_space.md`'s
   "written ONLY here" and `ram.md`'s `$FF8114` "voice-class borrow pool" survived the first pass.
   Grep the FACT's other names (the address, the old label) as well as the sentence.
2. **A question a measurement can settle is measured, never asked** (maintainer, 2026-09-15; a
   "Standing rulings" line). The `$FF8130` writer count took one decode and three taps.
3. **Neither record of a field's writers was right**: a scan anchored on the displacement word
   misses a write that carries an immediate word first, and a word tap read without its mask
   reports the neighbour byte's writes.
4. **Changing text on one side of a copy moves the other side's gate** — bbh F9 compares the
   gate-index page prose — and **new atlas addresses move checkdocs_rom's denominator**; the
   first strict tier went 152 / 0 / 2 on both.

**IF A DOC IS TOUCHED:** the eight `--check`s plus `tools/check_state_lists.py` and
`tools/tickets.py check`, exit statuses captured directly, `${=cmd}` in zsh. **A
running script is never edited** ([MSC-54]). **The static tier is never run beside
another gate run, or heavy work, in this tree.**
