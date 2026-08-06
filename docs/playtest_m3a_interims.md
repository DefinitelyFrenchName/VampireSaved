# Playtest guide — build `39597268` (tenant at 0x13): expected interims vs real bugs

For the 14z-62f playtest of `build/m3a_selrec`. Everything in the first
table is a DOCUMENTED interim with a known mechanism and a queued fix —
seeing it is expected and needs no report. Anything in the second table,
or anything not listed at all, is a real finding: please report it with
where/when it appeared (screen, characters, rough timing), roughly in the
replay-script style when possible.

Run it with:

```sh
export ROMDIR=/Users/koneko/Developer/Vampire_Saved/ROMS
tools/run_wide.sh build/m3a_selrec fbneo
```

## EXPECTED — do not report (each was visible in the session captures)

| What you will see | Where | Why (mechanism + fix queue) |
|---|---|---|
| A garbled RED/ORANGE BAR left of the wheel while hovering Donovan's cell (and through the speed menu) | select screen | The "lit name label" (his highlight piece) keeps its vs2 tile codes as PLACEHOLDERS — the four label tiles (0xB000/0xB129/0xB22C/0xB2A5) have no art home until the option-A select-art move. The ratified medallion policy. |
| The three BOTTOM-ROW medallions (Phobos/Pyron/Donovan cells) show wrong/garbage-ish art in off colors | select screen | The wheel-extension entries carry vs2-native tile codes as placeholders ("imperfect medallion art is acceptable" — your 14z-60s ruling). Rides the option-A move. |
| JEDAH's select-screen BODY figure garbles below his (correct) face while hovering his cell | select screen | The tenant's select-art subset still occupies Jedah's bank-1 hover-figure anchors. THE thing option A fixes. His face, name banner, and all his MATCH art are already back (his match measured pixel-identical to vanilla). |
| Donovan's HUD name plate reads "VICTOR" in-match | match HUD | The HUD name table is 16-wide and its consumer folds the id (0x13 -> 0x03). Queued with the 0x00A43E fold work. His select-screen name banner correctly reads "Donovan". |
| Donovan's WIN-SCREEN portrait/palette off-colored | win screen | The win-pal block is (color*17+id)-indexed; id 0x13 lands in a neighboring color block. The sparse-block fix is designed (STATE 14z-62c), queued behind option A. |
| Donovan's HUD mugshot possibly odd | match HUD | Mugshot art was placed into Jedah's cells for the 0x0F track; the venue family folds at 0x13. Same queue as the name plate. |
| Sounds: some Donovan voice lines silent | anywhere | Your M5 "A then B" decision — unfaithful lines ship silent. Unchanged. |

## REAL BUG — report immediately

| Symptom | Why it matters |
|---|---|
| ANY legacy character (not Donovan/Jedah-select-figure) rendering wrong: art, colors, positions | Legacy art is supposed to be fully pristine on this build — group B is untouched and Jedah's match measured pixel-identical to vanilla. Any legacy visual defect is new information. |
| Donovan IN-MATCH rendering wrong (art or colors) | His band serves from WIDE group C now; in-match he measured pixel-correct. A defect here implicates the group-C path. |
| Donovan's SELECT PORTRAIT (the big bust) in wrong colors | Fixed in 62f (the palette thunk) — it should show his real colors. Wrong colors = the thunk misbehaving on your machine/path. |
| Jedah's select-screen FACE (upper portrait) or NAME garbled | Only his body figure is expected-garbled; face and name measured clean. |
| Anything on the select screen when hovering LEGACY cells (portraits, names, highlights of the 15+1) | Those paths are vanilla records + pristine bank-2 art + untouched palette grid — must look exactly vanilla. |
| Crashes, freezes, wrong characters loading, input weirdness | Always. |

## The two captures from the session, classified

- **Select-screen capture**: the red bar = the label placeholder (row 1
  of the expected table); the bottom medallions = row 2. Donovan's
  portrait colors are CORRECT in that capture (the 62f fix).
- **In-match capture (vs Q-Bee)**: expected-clean apart from the "VICTOR"
  name plate. If you saw corruption in the fighters themselves there,
  that is a real finding — please say where.
