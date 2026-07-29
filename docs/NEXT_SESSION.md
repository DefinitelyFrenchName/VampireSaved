# NEXT SESSION — 60-second orientation (written 2026-07-29, session 14r end)

Dev head: **cf2109d8** (build/donovan6; `GEN_FLAGS="--allow-plausible
--tripwire-open" tools/build_donovan.sh 6 build/donovan6`; the overlay
manifest jsons are committed, the segment bins regenerate via
`tools/overlay_port.py <ROMDIR-parent> --ops-vsavj <vsavj opcode dump>
--emit --out build/manifest/overlay`). All gates green on cf2109d8:
double M2b stage-6 (masked legacy, full frozen flicker inventory),
M2a oracle, dual-emulator, flavor. Frozen builds: M2a a02aeeff,
M2b-core 71601263. AWAITING PLAYTEST of the overlay ship.

## What just happened (14r)

**THE COMPANION OVERLAY SHIPPED** (commit 52155b7): Anita renders
fully (dragging behind Donovan), sword on his back, clean win pose —
the Jedah-darkness blinking sword/statue is gone. Mechanism: object-
granular closure port of the vs2 overlay zone into Jedah's dead anim
areas + 22 thunked T-sites (match-active + slot-0x0F gated). Complete
stride-8 stream grammar in tools/overlay_port.py header comments.
Three measured crasher sites excluded (KILLER_SITES); fmtA composite
records carried opaque. Playtest watch-list below.

## Next work (priority)

1. **Overlay polish (playtest-driven)**: (a) the hat piece alternates
   per frame — determine vs2-authentic dither vs residue; (b) the 3
   excluded sites (0x5D8B8/0x5EE22/0x918F0 — indexing-variant decode:
   ±4-anchored table entries, site-biased ids) leave wrong-art residue
   on their features; (c) four 100%-dead tables (0x2A0862 family,
   win/vignette features partially live via whdr-strips); (d) the one
   accepted fmtA record renders vs2 tile codes (garbled bits where it
   draws). All safe-by-construction (no crash class left: guarded
   soaks + full battery green).
2. Win-quote palette (mechanism pinned earlier: table 0x7F196 +
   ramp blocks ~0x3A14xx; repoint-safe).
3. A5 work-var displacement audit sweep (same-value class #4).
4. Small cosmetics: quote text line, HUD name "Jedah", wheel hexagonal
   mugshot, attract palette.

## Method notes (hard-won this session — see GOTCHAS)

- Debugger bp/wp traces DESYNC replays (frame counter inflates while
  stopped). Frame-accurate evidence = replay.lua DUMPS + RAM reads
  only. Companion-slot cursors survive at frame-done (live flag clear).
- Record bank = drawing OBJECT property (+0x18), never record content.
- Breakpoint traces are samplers; close every set structurally.

## Decisions pending (maintainer)

- Roster access (select-screen redesign vs Oboro-pattern combined
  input; recommendation B recorded in STATE).
- Throw-damage magnitude: vsavj-scaling by design; oracle shows test
  throw equal to vs2. If vs2-equal damage is wanted EVERYWHERE, that
  is a rules decision (comparative measurement available on request).
