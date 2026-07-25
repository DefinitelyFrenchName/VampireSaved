# RAM atlas — 68k work RAM ($FF0000-$FFFFFF), vsavj

Evidence classes: [C] community (mame-rr cps2-hitboxes.lua family entry,
verified where noted), [D] differential dump experiment, [T] write-trace,
[V] visually verified via snapshot. Every entry lists its evidence.

## System / match globals

| Address | Meaning | Evidence |
|---|---|---|
| `RAM:$FF8004.l` / `$FF8008.l` | match-active check: both == 0x40000 → in-match (alt: $FF8008.w==2 && $FF800A.w>0) | [C] |
| `RAM:$FF0CC9` | EEPROM-derived bootup-count byte (differs per boot count; the FBNeo determinism bug tell) | [D] |
| `RAM:$FF811B` | P1 select-screen cursor slot (changes by ±1 per cursor step) | [D] |
| `RAM:$FF8203` | P1 match-config byte, char-correlated but NOT the char ID (00 Demitri / 02 Victor / 02 Bulleta) | [D] |
| `RAM:$FF8290` | screen left edge (camera) | [C] |
| `RAM:$FF05xx` | sound-driver work area (differs between MAME/FBNeo boot phase) | [D] |

## Player structs — P1 `$FF8400`, P2 `$FF8500` (0x100 apart) [C, verified D/T]

| Offset | Meaning | Evidence |
|---|---|---|
| +0x0B | flip_x (facing) | [C] |
| +0x0A | attack id (shift 5 for hitbox lookup) | [C] |
| +0x1C | anim ptr | [C] |
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
variant. vsavj: slot 0x01 = Demitri, 0x03 = Victor ([T,D,V]); variant space
differs only at slot 0x08 (Dark Talbain) — all other alt slots alias the
base table. Full slot→name map: ring experiment (in progress).
