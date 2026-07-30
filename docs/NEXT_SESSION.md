# Next session — 60-second orientation

Build: cfe757a1 (stage 6). Throw fix CONFIRMED by round-24 playtest.
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
2. Apply the proven 14q site-thunk pattern ([[site_thunk]] construct is
   now first-class): gate on the spark's +0x9A==0x0F mark (per-object,
   no slot ambiguity) and serve a rebuilt Donovan effect table; the vs2
   source family is T=0x2B0786 (self-relative words; must be REBUILT
   against the ported record placements, not copied — 16-bit offsets
   can't span to 0xF3F70).
3. Verify: replay 17 f3475+ anim must walk 0xF420C+ (= vs2 0x2B8190+);
   then full battery; then playtest (the arc should be VISIBLE — tiles
   are already in the build).

## Also open
- 27 oracle re-freeze (throw connects at 3050/3650).
- Wrong-conviction cleanups: grab rows (stage 99) isolated re-test;
  0x248D80 zone attribution re-derivation. See prior NEXT_SESSION notes
  in git history.
- Palette family (non-blocker): quote/HUD row consumer undecoded.
- Sword/statue blink (non-blocker): parked overlay, needs byte-dead
  tile pool.
