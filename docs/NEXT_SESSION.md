# NEXT SESSION — 60-second orientation

Updated: session 14z-19 (2026-07-31).

## Where things stand

Round-46: the column crash is CONFIRMED FIXED and the swordless 421P
has its shock back (the record-type remaps route presentation too —
STATE 14z-34). Every blocker is closed. The shipped build f500a6bc
carries: select-screen sword, color-aware accent (no blinking any
color, in-match), correct auras, column KO clean.

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
2. **CLOSED 14z-21 (no bug):** alt-color + Donovan mirror are
   byte-identical to native vs2; table B is never consulted on
   Donovan's paths. Locked in tests/test_don_colors.sh.
2b. **Sworded-421P shock + death (supersedes the consumer-2/3 plan):**
   port vs2's small dedicated type-0x51 handler (dispatch+0xBA in
   vs2) and route type 0x51 to it (thunk at the dispatch's
   `d040 303b 0006`, testing d0==0xA2). Full analysis: STATE 14z-34.
   Then re-evaluate whether the hit-class property extension is still
   needed. Remaining cosmetics after: swordless-deity palette,
   select-screen post-confirm blink (tracked minor).

3. Then the queue: speed-mode PvP
   anomalies (not urgent per maintainer), win-quote/HUD palettes.

## Watch out

- Stage-6 dev builds need `GEN_FLAGS="--allow-plausible
  --tripwire-open"` (bare build fails on 58 open reconciliation refs).
- ROMDIR grew cfg/nvram + lost qsound_hle.zip (restored, byte-verified)
  — someone is playing from the reference dir; re-run the audit before
  trusting it.
- Palette data_ports are invisible to the masked RAM gate — every new
  one needs a static byte guard (test_don_accent.sh pattern).
