# Next session — 60-second orientation

Build: 597ae55b (stage 6) — RESTORED byte-exact after the round-25
regression (see STATE 14z-4: both spark thunks convicted by pixel A/B,
staged to 99). Throw fix CONFIRMED by round-24 playtest.
Priority context (maintainer, recorded in STATE): the missing sword-swing
visual on armed normals is the one TRUE BLOCKER; palettes/blinking are
ship-compromisable.

## The one remaining step of the sword-swing fix (map is complete)

Read STATE "Session 14z-3" first. Everything up to the display processor
is done and verified live on build cfe757a1 (spark spawns, variant,
timing, tile-bank 0x4000, +0x9A=0x0F Donovan mark). The single missing
piece: the display-side number->record STRIP TABLE selection still
serves slot-0F vanilla (Jedah-family) tables — ported sparks walk
0x28391C+ instead of the already-ported sword-arc records at 0xF420C+.

Next concrete actions:
1. Find the display-processor site that picks the strip table for
   effect-class objects (start from tools/overlay_port.py
   VERIFIED_SITES = {0x5D8B8, 0x5EE22, 0x918F0} and the GOTCHAS entry
   "The companion overlay draws the HOST's records").
2. Design a discriminator that is PROVEN dead (round-25: +0x9A is NOT
   spare — it hid Anita; see GOTCHAS "pixel A/B"). Candidates: derive
   Donovan-ness display-side from the strip source itself, or find a
   byte proven unread by pixel A/B + code audit. Then apply the 14q
   site-thunk pattern ([[site_thunk]] is first-class, rows staged at 99
   ready to revive): serve a rebuilt Donovan effect table (vs2 family
   T=0x2B0786; self-relative words must be REBUILT against ported
   record placements — 16-bit offsets can't span to 0xF3F70). Tile
   bank 0x4000 (spark_bank_swap) must land in the SAME change.
3. Verify: replay 17 f3475+ anim walks 0xF420C+ (= vs2 0x2B8190+);
   pixel A/B on f3477-3481 (spark clean, ANITA PRESENT); full battery;
   then playtest.

## Also open
- 27 oracle re-freeze (throw connects at 3050/3650).
- Wrong-conviction cleanups: grab rows (stage 99) isolated re-test;
  0x248D80 zone attribution re-derivation. See prior NEXT_SESSION notes
  in git history.
- Palette family (non-blocker): quote/HUD row consumer undecoded.
- Sword/statue blink (non-blocker): parked overlay, needs byte-dead
  tile pool.
