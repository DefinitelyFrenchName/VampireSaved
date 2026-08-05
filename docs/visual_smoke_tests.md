# Visual smoke tests — checking the OUTPUT, not the internal state

**Origin: maintainer, 2026-08-05**, from the Sailor Moon SNES project —
end-to-end emulator testing is paramount, but in some cases the internal
monitoring is green and only the *standard output* shows the fault. Their
case: the data loaded was correct, but loaded in a wrong MANNER, so the
visuals were corrupt while every internal check passed.

**The WIDE sprite garble (14z-60y) is a fresh instance of exactly that.**
The decoded tile buffer was byte-identical to the known-good stock build,
zero `0xFF` fill — internal state perfect — while Donovan rendered as
garbage, because the tile ADDRESS composition at draw time was wrong. The
buffer is internal state; the screen is the output.

We cannot cover everything. The proposal is narrower and achievable: **a few
smoke tests over visuals that have broken BEFORE and whose check we already
know how to perform.** Past breakage is the best available predictor, and
this repo documents every one of them.

## The inventory — each already broke once, each has a known repro

| # | Visual | Broke as | Where the repro is |
|---|---|---|---|
| 1 | Menus / select screen tiles | overlay placement corrupted title, select and speed menus while the full masked battery stayed green, twice | `tests/test_gfx_menus.sh` (exists — the model for the rest) |
| 2 | **New-character in-match sprites** | the current WIDE garble; also the round-25 spark-bank regression that passed the whole battery | replay 17 frames 3477-3481 (the ready-made spark probe) |
| 3 | Companion overlay (sword / statue) | Jedah's overlay animating where Donovan's sword and statue belong | the sword gate's anim node; playtest rounds 8-11 |
| 4 | Anita's feet strip (bank-2 records) | solid green, then +0x47 garble, from bank misattribution | `tests/lua/obj_record_bank_trace.lua`, rounds 10-13 |
| 5 | Electric-hit darken / VS-fade curtain | stale OBJ buckets rendered as garble; the fix once REMOVED the darken entirely | ~10-frame window, **odd-frame sampling required** (even-frame sampling missed it for three sessions) |
| 6 | Win-quote screen palettes | the 14t palette port, reverted by the gate; a minor instance is open now | win-quote replay 28 |
| 7 | Select medallion / portrait / mugshot | wrong character's art on the cell (14z-49) | pick + snapshot at the select screen |

## Design rules, learned the hard way

- **Compare OUTPUT.** Framebuffer checksums (`FBNEO_HVIDEO`, MAME
  `VIDEO_OUT`) or snapshot pixels — never a RAM checksum, which is
  structurally blind to all seven rows above.
- **A/B against a reference build**, not a frozen absolute hash, wherever
  possible. Frozen pixel hashes rot the moment anything legitimately
  changes; an A/B states the invariant ("the port renders the same on both
  tracks") directly.
- **Align by anchor or displayed record, never raw frame index.** Different
  drivers and different games skew a frame or two, and same-frame snapshots
  then compare different anim poses — that produced two false "garble"
  verdicts in one session (14z-9).
- **Sample the whole cycle of a cyclic effect.** Row 5 hid behind
  even-frame-only sampling for three sessions.
- **Run the vanilla control FIRST.** The round-27/29 odyssey cost five wrong
  models before someone ran it; it would have ended the investigation in one
  session.
- **Never run pixel probes in parallel with a battery** — three concurrent
  MAME instances flaked a replay into a different attract phase.

## Priority

Row 2 first, as part of closing the open bug: a Donovan replay compared
stock-vs-WIDE at sync anchors would have caught it automatically, and the
instruments already exist. Rows 1 and 7 are cheap extensions of the existing
menu pixel gate. Rows 3-6 are worth adding as their subsystems are next
touched, rather than all at once.
