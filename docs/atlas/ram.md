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

## Masked windows for hooked-build legacy comparison (CLAUDE.md §4 amendment, 2026-07-25)

The ONLY two work-RAM windows excluded from legacy comparison on builds
carrying engine hooks (`MASK_RANGES="043c-043d,7f00-8000"`). Mechanism and
measurements: docs/GOTCHAS.md "Engine hooks on hot paths". Additions to
this list require a measured mechanism + maintainer sign-off.

| Address | Meaning | Class | Evidence |
|---|---|---|---|
| `RAM:$FF7F00-$FF7FFF` | system stack reserve; SP rests at $FF8000 at the frame-done sample point, so everything below is dead (stale return addresses, abandoned exception frames, interrupt-time register saves). Hook cycle-skew makes these bytes differ while live state is identical. Observed divergence extent: $FF7FA0-$FF7FFF | ghost (dead at sample) | [D: frame-boundary dumps vanilla vs hooked, session 7] |
| `RAM:$FF043C` | 68k↔QSound handshake latch (values 04/08, toggles per frame); phase-shifts one frame under hook cycle skew — same family as the $FF1CF0 latch under `-debug` (GOTCHAS) | phase | [D: single-byte diff isolation, session 7] |

## System / match globals

| Address | Meaning | Evidence |
|---|---|---|
| `RAM:$FF8004.l` / `$FF8008.l` | match-active check: both == 0x40000 → in-match (alt: $FF8008.w==2 && $FF800A.w>0) | [C] |
| `RAM:$FF0CC9` | EEPROM-derived bootup-count byte (differs per boot count; the FBNeo determinism bug tell) | [D] |
| `RAM:$FF811B` | P1 select-screen cursor slot (changes by ±1 per cursor step) — CAUTION: also observed oscillating every few frames during select (session 3 comparator work); prefer player block +0x382, which tracks the hovered character id live during select | [D] |
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
| +0x382 (`$FF8782`/`$FF8B82`) | selected character ID (write 0x18 = Oboro Bishamon — TCRF cheat). Updates live with the hovered slot during character select (verified: P2 cursor R,R = 0x05→0x01→0x03 on both emulators); a not-joined side shows a different block signature entirely | [C:tcrf, D] |
| +0x392.w (`$FF8792`) | special-meter gauge CANDIDATE (steps 0→0x500→0x1400 while attacking; semantics unconfirmed) | [D] |

## Combat struct (player block +0x000) [C, verified D/T]

| Offset | Meaning | Evidence |
|---|---|---|
| +0x0B | flip_x (facing) | [C] |
| +0x0A | attack id (shift 5 for hitbox lookup) | [C] |
| +0x10.w | X position (signed) | [C: script default, matches update_object] |
| +0x14.w | Y position (signed) | [C] |
| +0x1C | anim ptr (node write: vs2 walker PC 0x2713C / vsavj 0x27EE8 family / ported walker 0xCE38A) | [C] |
| +0x20 | anim node timer (node duration byte countdown; held while +0x5C runs) | [D: 14z-42] |
| +0x32.w | attacker/owner attribution link (word addr, sign-extends to the player block; reaction handlers deref it for attacker-side writes) | [D: 14z-26/42] |
| +0x5C | hit-freeze counter (blocks +0x20 decrement; set per hit on BOTH victim and attacker by the reaction handlers — electric-shake pair: vsavj 0x23AC8 writes 0x18/0x0B where vs2 0x226E0 writes 0x0C/0x04; engine-generation drift, see engine_internals) | [D: 14z-42] |
| +0x50.w | current HP (round start = 0x120 = 288) | [D] |
| +0x52.w | white/displayed HP (regenerating damage) | [D] |
| +0x60.l | per-character hitbox data base (ROM ptr; Demitri 0x93B6A, Victor 0x9769E) | [T,D] |
| +0x64.l | per-character ptr from table PRG:0x0BD9FA | [T] |
| +0x80/84/88/8C/90.l | hitbox addr tables: base + word offsets base[0..8] (push=+0x90, vuln=+0x80/84/88, attack=+0x8C) | [C,T] |
| +0x94..0x97 | current box ids (vuln×3, push) | [C] |
| +0x98 | throw box id | [C] |
| +0x11E,+0x134,+0x145,+0x1A4 | invulnerability/status flags | [C] |
| +0x147 | multi-hit RE-HIT GATE (victim-side; vs2's electric-shake handler sets 0x0C per hit -> ~10f hit period; vsavj's handler never writes it — without it the victim freeze doubles as the gate) | [D: 14z-42, measured 7f/10f/12f periods] |
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
