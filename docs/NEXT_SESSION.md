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

0. **Round-36 CONFIRMED green** (sword+statue blink dead, electrocute
   clean). New tracked item from it: the electric effect around the
   SWORD during electrocute is red instead of vs2's yellow (body is
   correct). Not a blocker; maintainer flags possible non-cosmetic
   side-effects. Hypotheses + measurement plan: STATE.md 14z-19
   addendum — investigate alongside item 1 (same setup, likely same
   root: a palette row resolved through an un-repointed path).
1. **DONE 14z-20 — awaiting playtest:** row-0x0F fixture override
   shipped (site_thunk pair at 0x1C586/0x1C59A, hole-"b" embedded vs2
   block; STATE 14z-20). Expect: statue accents vs2-correct (red ramp)
   in match intro + attract. Sword-shock red-vs-yellow = engine-global
   vsavj styling — now a Decisions-pending item (recommend accept), NOT
   a bug. If the maintainer reports statue still wrong on some OTHER
   screen (win/continue), measure which fixture site serves it and add
   that site to the hook set.
2. **Table B 0x38C1D8 slot-0F repoint** (alt-color Donovan currently
   loads Jedah's block 0x390CA0): port vs2's table-B block or interim-
   repoint to the default block (0xCEAF0). Table family layout:
   STATE.md 14z-19.
3. Then the queue: select-screen sword (task #18), speed-mode PvP
   anomalies (not urgent per maintainer), win-quote/HUD palettes.

## Watch out

- Stage-6 dev builds need `GEN_FLAGS="--allow-plausible
  --tripwire-open"` (bare build fails on 58 open reconciliation refs).
- ROMDIR grew cfg/nvram + lost qsound_hle.zip (restored, byte-verified)
  — someone is playing from the reference dir; re-run the audit before
  trusting it.
- Palette data_ports are invisible to the masked RAM gate — every new
  one needs a static byte guard (test_don_accent.sh pattern).
