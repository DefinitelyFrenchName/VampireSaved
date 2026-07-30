# Next session — 60-second orientation

Build: 597ae55b (stage 6). The throw victim-teleport is ROOT-CAUSED and
fixed: slot-0F victim-keyframe table (0xBE27A -> 0xB19F8) now carries vs2
Donovan's table via the new [[data_port]] manifest construct. Awaiting
round-24 playtest confirmation of: throw cinematic clean (incl. visual),
no regressions elsewhere.

Wrong-conviction post-mortem is in GOTCHAS ("Disabling a heuristic
CLASS...") — grab rows and winpal copies were both innocent of the
teleport; convictions by build-timeline correlation, refuted by the tap
trace. Consequences to revisit:
1. Grab-pointer rows (stage 99): rolled back on the belief they broke
   the throw. They may be legitimate — BUT round-20's report came from a
   build where the keyframe table had just reverted, so their effect was
   never observed in isolation. Re-test them only deliberately, one
   change alone, with 27+30 gates watching.
2. Winpal copies (0x248D80 zone): still forbidden as a HOME (the zone is
   Jedah throw-cinematic data per the atlas conviction — REVISIT whether
   that attribution also came from the timeline error; the copies were
   convicted of THIS bug, which they did not cause. The zone may in fact
   be safe. Re-derive from the atlas before reusing.) Palette family
   still open: quote/HUD rows' true consumer undecoded.
3. Throw-oracle 27 re-freeze still queued (throw connects at 3050/3650).

Open visual items: sword/statue red-purple flicker (parked overlay), 6HP
armed sword swing not rendered, HUD name "Jedah", loss-path quote art,
HUD mini-portrait palette, win-quote palette.

Tools: tests/lua/tap_writes.lua (hot-field write attribution without
replay desync), dump_opcodes.lua for ANY code-region analysis (GOTCHAS:
zips store code encrypted).
