# NEXT SESSION — 60-second orientation (written 2026-07-29, session 14s end)

Shipping build: **37269fff** (build/donovan6; `GEN_FLAGS="--allow-plausible
--tripwire-open" tools/build_donovan.sh 6 build/donovan6`). All gates
green — double M2b stage-6 (masked legacy + THE NEW PIXEL MENU GATE),
M2a oracle, dual-emulator, flavor. Frozen: M2a a02aeeff, M2b-core
71601263. AWAITING PLAYTEST (round 17): menus must be clean again, and
the speed-menu TURBO/AUTO text is now pixel-vanilla (it had been 8px
off since the select work — nobody ever noticed).

## Round-16 outcome (why the overlay is parked again)

The overlay build corrupted title/select/menu graphics: its tile pool
used OBJ-dead positions whose BYTES back scroll-layer art (CPS-2
scroll1/2/3 decode the same ROM bytes — see GOTCHAS "GFX and
coordinate data are INVISIBLE to every RAM-basis gate", rules 1-4).
Overlay WIP parked in build/manifest/overlay.wip (rename to overlay/ +
regenerate segments to activate). The in-match rendering itself was
CORRECT (Anita, sword-on-back, win pose) — only the tile pool and the
unpoked-family flicker (red/purple over the grey sword/statue) remain.

## Next work (priority)

1. **Overlay tile pool redesign (byte-dead)**: the pool must be dead
   for EVERY decoder, not just OBJ. Safe classes so far: bytes of art
   the port itself replaced (Jedah's group-B band minus any
   scroll-shared spans — needs a scroll-usage census over his band),
   0xFF padding runs. Census method suggestion: MAME tilemap/gfx
   viewer dumps, or a static scan of scroll tilemap data in ROM for
   tile indices whose byte ranges intersect candidate positions.
   Then re-activate the overlay and re-probe (donprobe harness in
   STATE 14q/14r).
2. **The red/purple sword/statue flicker**: unpoked table families
   (0x2675AA/0x26772A/0x26775A zero-poked; 0x267112/0x2672AA
   deliberately excluded; three KILLER_SITES) — needs the
   indexing-variant decode (±4-anchored entries, site-biased ids;
   see STATE 14q analysis of the dead-entry dumps).
3. Win-quote palette (mechanism pinned: table 0x7F196 + ramp blocks
   ~0x3A14xx; repoint-safe).
4. A5 work-var displacement audit sweep (same-value class #4).
5. Small cosmetics: quote text line, HUD name "Jedah", wheel
   hexagonal mugshot, attract palette.

## Decisions pending (maintainer)

- Roster access (recommendation B, combined input — in STATE).
- Throw-damage magnitude (vsavj scaling by design; measured equal on
  the oracle throw).
