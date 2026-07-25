# NEXT_SESSION — 60-second orientation (rewritten every session end)

As of 2026-07-25, end of session 3.

**Where we are:** M1 nearly complete. Harness: done (both emulators,
deterministic, 10-replay suite green/frozen). Mapping: the character-data
system is cracked wide open —

- vsavj slot→character map **16/16 pick-verified** (incl. Aulbath L,L,D).
- **Donovan 0x13 / Pyron 0x11 / Huitzil 0x10** pick-verified in BOTH vsav2
  and vhunt2 (variant-half IDs, selectable on the wheel; hitbox bases and
  bank[0] handler code addresses recorded per set).
- Per-character table bank semantically labeled (14 dispatch tables +
  hitbox pairs for player/projectile paths + parameter tables); bank
  layout identical across the three sets (same deltas from per-set origin).
- RAM atlas solid: player blocks 0x400 apart (P1 $FF8400 / P2 $FF8800 —
  the 0x100 spacing belief was WRONG, see corrected ram.md), select char
  IDs at +0x382, HP +0x50/+0x52 (max 0x120), X/Y +0x10/+0x14, timer
  $FF8109, meter candidate $FF8792.

**M1 acceptance gaps (the remaining work):**
1. Manifest columns not yet mapped: **animation scripts** (trace struct
   +0x1C anim-ptr writes), **tile ranges** (follow anim data → sprite/tile
   ids; R2 risk item — check index field widths while there), **palettes**
   (trace CPS2 palette upload for a character), **sound cues** (trace
   QSound command writes during a move).
2. Start-hold flavor mechanism in VS2/VH2 (hitbox data identical across
   both games — flavor deltas live in other tables/code; find the toggle).
3. Variant slot 0x19 occupant in vsav2/vhunt2 (variant of slot 9).
4. Confirm meter semantics; rounds-won location.

**Then M1 exit review** against SPEC §4 acceptance, and on to M2: Donovan
into vsavj by slot replacement — the located tables + bank layout make the
injection points obvious (replace a vsavj slot's rows across the bank,
inject handler code + data, then reconciliation begins).

**Read:** STATE.md, docs/atlas/character_tables.md, docs/atlas/ram.md,
docs/GOTCHAS.md. All tools/tests self-documenting; suite:
`ROMDIR=... tests/run_suite.sh`.
