# NEXT SESSION — 60-second orientation

Updated: session 14z-19 (2026-07-31).

## Where things stand

Round-35 playtest showed the 14z-18 blink fixes had FAILED — and the
statue "fix" was a silent **superset violation** (it overwrote VICTOR's
accent rows at 0x39B040; palette rows 0x10+ are the **P2 character's**
rows, not statue rows). Session 14z-19 reverted it, understood the real
mechanism (the engine MARCHES row 0x0C through accent slots T0/T1 —
overlapping windows, the slide is Jedah's glow animation), and fixed the
sword blink properly: both marched slots now hold vs2 row-C content.
Measured: row 0x0C steady + byte-equal to native vs2 over the idle
window; Victor's glow cycle restored. New permanent gate:
`tests/test_don_accent.sh` (static byte guards + behavioral steadiness +
Victor-cycle-alive). Full corrected model: STATE.md 14z-19; traps paid:
docs/GOTCHAS.md (P2-row attribution; A0 post-increment second payment).

## Next work, in order

1. **Await round-36 playtest** (build b80e0e67, pending battery):
   expect sword AND statue blink dead everywhere; statue accent pieces
   still steadily miscolored (blue/grey instead of vs2's red ramp) —
   that's the open row-0x0F item, tell the maintainer it's known.
2. **Row-0x0F fixture override port** (the statue miscolor): vs2 runs a
   per-char 2-row copy (vs2 0x3CB7DC → palette rows 0x0E/0x0F, red ramp
   at 0x3CB7FC) after the global venue fixture (vsavj analog 0x3B5940 —
   LEGACY, untouchable). vsavj has no per-char override path; needs a
   slot-0F-conditional upload hook (rows 0x0E/0x0F → 0x90C1C0 +
   0x91C1C0 bank, post-fade or via the $FF40xx staging). Data must be
   data_ported into a hole first.
3. **Table B 0x38C1D8 slot-0F repoint** (alt-color Donovan currently
   loads Jedah's block 0x390CA0): port vs2's table-B block or interim-
   repoint to the default block (0xCEAF0). Table family layout:
   STATE.md 14z-19.
4. Then the queue: select-screen sword (task #18), speed-mode PvP
   anomalies (not urgent per maintainer), win-quote/HUD palettes.

## Watch out

- Stage-6 dev builds need `GEN_FLAGS="--allow-plausible
  --tripwire-open"` (bare build fails on 58 open reconciliation refs).
- ROMDIR grew cfg/nvram + lost qsound_hle.zip (restored, byte-verified)
  — someone is playing from the reference dir; re-run the audit before
  trusting it.
- Palette data_ports are invisible to the masked RAM gate — every new
  one needs a static byte guard (test_don_accent.sh pattern).
