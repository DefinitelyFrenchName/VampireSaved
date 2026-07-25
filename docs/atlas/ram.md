# RAM atlas — 68k work RAM ($FF0000-$FFFFFF), vsavj

Evidence classes: [C] community (mame-rr cps2-hitboxes.lua family entry,
verified where noted), [D] differential dump experiment, [T] write-trace,
[V] visually verified via snapshot. Every entry lists its evidence.

## Attract-mode demo roster (superset-invariant note)

The attract sequence includes CPU demo matches that feature real characters.
Verified: `01_attract_long` (7200-frame attract, zero input) runs a **Jedah
(id 0x0F) vs Victor** demo starting at **frame ~4278**. Consequence for
patched builds: any change to a character that appears in an attract demo
will alter that attract from the demo's start frame — this is *correct*
superset behavior (the attract "involves" the modified character), not a
violation. The auto-detecting regression runner must treat attract
expectations as build-fingerprint-dependent when a demo-featured slot is
modified. (Full attract demo roster: TODO — enumerate all demo matchups so
the runner knows which builds legitimately change attract.)

## System / match globals

| Address | Meaning | Evidence |
|---|---|---|
| `RAM:$FF8004.l` / `$FF8008.l` | match-active check: both == 0x40000 → in-match (alt: $FF8008.w==2 && $FF800A.w>0) | [C] |
| `RAM:$FF0CC9` | EEPROM-derived bootup-count byte (differs per boot count; the FBNeo determinism bug tell) | [D] |
| `RAM:$FF811B` | P1 select-screen cursor slot (changes by ±1 per cursor step) | [D] |
| `RAM:$FF8203` | P1 match-config byte, char-correlated but NOT the char ID (00 Demitri / 02 Victor / 02 Bulleta) | [D] |
| `RAM:$FF8290` | screen left edge (camera) | [C] |
| `RAM:$FF8109` | round timer (counts down ~1/sec during match) | [D] |
| `RAM:$FF05xx` | sound-driver work area (differs between MAME/FBNeo boot phase) | [D] |

## Player blocks — P1 `$FF8400`, P2 `$FF8800` (0x400 apart) [D, corrected]

**Correction (session 3):** the community "P2 = player + 0x100" refers to
sub-object slots; the actual P2 player block is `$FF8800` (verified: 2P
run shows Victor's hitbox base at `$FF8860`, `$FF8500` zeroed). Each block
is 0x400 bytes; combat struct at +0x000, further state above +0x100.

| Extended-block offset | Meaning | Evidence |
|---|---|---|
| +0x382 (`$FF8782`/`$FF8B82`) | selected character ID (write 0x18 = Oboro Bishamon — TCRF cheat) | [C:tcrf, D] |
| +0x392.w (`$FF8792`) | special-meter gauge CANDIDATE (steps 0→0x500→0x1400 while attacking; semantics unconfirmed) | [D] |

## Combat struct (player block +0x000) [C, verified D/T]

| Offset | Meaning | Evidence |
|---|---|---|
| +0x0B | flip_x (facing) | [C] |
| +0x0A | attack id (shift 5 for hitbox lookup) | [C] |
| +0x10.w | X position (signed) | [C: script default, matches update_object] |
| +0x14.w | Y position (signed) | [C] |
| +0x1C | anim ptr | [C] |
| +0x50.w | current HP (round start = 0x120 = 288) | [D] |
| +0x52.w | white/displayed HP (regenerating damage) | [D] |
| +0x60.l | per-character hitbox data base (ROM ptr; Demitri 0x93B6A, Victor 0x9769E) | [T,D] |
| +0x64.l | per-character ptr from table PRG:0x0BD9FA | [T] |
| +0x80/84/88/8C/90.l | hitbox addr tables: base + word offsets base[0..8] (push=+0x90, vuln=+0x80/84/88, attack=+0x8C) | [C,T] |
| +0x94..0x97 | current box ids (vuln×3, push) | [C] |
| +0x98 | throw box id | [C] |
| +0x11E,+0x134,+0x145,+0x147,+0x1A4 | invulnerability/status flags | [C] |
| +0x132.w | per-character word from table PRG:0x0BE17A | [T] |

## Projectiles

| Address | Meaning | Evidence |
|---|---|---|
| `$FF9400` + n*0x100 | projectile objects, 32 slots, same object layout family | [C] |

## Character ID space (from the per-character tables, see per-set atlas)

IDs are 5-bit: low 4 bits = character slot (16 slots), bit 4 = hidden/alt
variant. vsavj: variant space differs only at slot 0x08 (Bishamon → Oboro
Bishamon); all other alt slots alias the base table. Slot→name map:
docs/atlas/character_tables.md.
