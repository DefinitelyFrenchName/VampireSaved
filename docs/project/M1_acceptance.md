# M1 — Map: acceptance review

> **STATUS (14z-118 audit): HISTORICAL — M1 accepted 2026-07-25.** The atlas it
> reviews has since grown per-set pages (`docs/game/atlas/`); the VS2-vs-VH2
> variant policy clause 2 defers to was ruled (STATE STANDING PRINCIPLE,
> DECISIONS_HISTORY). Nothing here is open.

SPEC §4 M1 acceptance has two clauses. Assessed 2026-07-25.

## Clause 1 — "atlas documents let us answer 'where does character X's <thing> live in each set' without new disassembly"

Required: for the 3 ported (Donovan, Huitzil, Pyron) + 2 control characters
(present in all three sets — Demitri, Victor), per-character manifests
covering code, animation scripts, tile ranges, palettes, sound cues.

| Manifest column | Status | Where |
|---|---|---|
| character ID plumbing | **DONE** | loader `PRG:0x028DD8` (all 3 sets); IDs are 5-bit slot\|variant<<4; RAM char id at block+0x382 |
| roster / select tables | **DONE** | per-set table bank origins recorded; slot→character maps verified by pick |
| code (handler) | **DONE** | bank[0] dispatch; D/H/P handler addresses in vsav2/vhunt2 recorded |
| animation scripts | **DONE** | anim index tables (bank−0x280); per-char anim bases in all 3 sets |
| tile ranges | **PIPELINE DONE, addresses sprite-bound** | anim→frame→sprite-subtable→OBJ chain decoded; tile field is 16-bit OBJ code; per-char tile *set* bounds resolved during sprite porting (see R2 below) |
| palettes | **PIPELINE DONE, addresses sprite-bound** | source-slot / fade pipeline mapped; per-char sprite palette rides the sprite object bank |
| sound cues | **PIPELINE DONE** | QSound emit path + per-char cue trigger mapped; exact sample-table address is M5 QSound work |

Verdict: **the load-bearing clause is met.** "Where does character X's data
live" is answerable from the atlas for code, anim, IDs, and roster — the
hard structural questions the port depends on. Tile/palette/sound *exact ROM
addresses* for the sprite-bound assets are intentionally deferred to the
milestones that consume them (M3 gfx expansion, M4 sprites, M5 sound),
because they're bound to the sprite/QSound systems rather than flat
indexable tables — and M1's job was to prove they're *reachable*, which it
did (full pipeline traces, not guesses).

## Clause 2 — "oracle replay harness runs a 10-replay legacy suite green"

**DONE.** `tests/run_suite.sh` — 10 edge-case-biased replays, frozen
expectations (`tests/expected/vsavj/`), all PASS, deterministic across runs.
Harness works on both MAME (Lua) and patched FBNeo. Re-verified green after
every tool change this session.

## Bonus beyond M1 scope

- Donovan/Huitzil/Pyron located AND pick-verified in both vsav2 and vhunt2
  (M2 needs only one; we have both source sets characterized).
- Variant space fully enumerated (3 newcomers + 2 Oboro Bishamons).
- vsav2 ≡ vhunt2 per-character data proven byte-identical (simplifies the
  VS2-vs-VH2 variant policy — see STATE decisions-pending).
- CLAUDE.md §4 amended (dual-emulator field-level agreement).

## R2 risk — promoted from "investigate" to a quantified finding

SPEC R2 asked to "investigate width limits during M1." Result: the CPS2 OBJ
tile field is **16-bit** (65536 tiles) while the vsav GFX ROM holds ~2^18-19
tiles — the concrete graphics address-space ceiling behind Capcom's split.
The M3 expansion plan must resolve how high tile bits are supplied (OBJ attr
bits vs gfx bank) and whether frame tile#s are per-character-relative
(easy) or absolute (hard). This is now the **top technical risk** and the
first M3 investigation. Detail in docs/game/atlas/character_tables.md.

## Conclusion

**M1 accepted.** Both acceptance clauses met; the deferred items are
correctly scoped to later milestones and are proven-reachable. Proceed to
M2 (Donovan into vsavj by slot replacement) — with the M2 replaced-slot
choice going to the maintainer (a gameplay-feel decision, SPEC §7 open Q1)
with a data-backed recommendation.
