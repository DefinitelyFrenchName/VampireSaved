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
| `RAM:$FF0460.l` (and `$FF045C.l`) | the SOUND DRIVER's current-record pointer spill (and its SP spill): the driver's dispatch prologue at `PRG:0x0011DE/0x0011E2` (`move.l sp,(-$7BA4,A5); move.l a0,(-$7BA0,A5)`, A5=$FF8000) saves A0 = whichever record it is servicing — the $FF02xx channel records (0x20-stride: $025C/$027C/$029C/$02BC/$02DC…$033C) or the $FF043C latch — dozens of times per frame (FBNEO_HTAP: one writer PC, 415k writes over 04_select_fuzz). At a frame-done sample it normally rests at $00FF043C; a hook-cycle-skewed frame can sample it MID-SCAN (the 14z-81 merged flicker at f2005 read $00FF02DC) — one-frame pointer-phase, no gameplay surface. This retires the WITHDRAWN "sound-queue drain cursor" speculation with a measured owner | phase | [D: FBNEO_HTAP ff0460-ff0463 on vanilla 04_select_fuzz + opcode-view disassembly of 0x11D6-0x11EC, 14z-82] |
| `RAM:$FF4182-$FF41A1` | palette-fade staging buffer: the 0x20-byte slot where select palette-block-A row 14 lands when a venue fade stages block-A rows (buffer family: `$FF4182 + row*0x20`, F-bright applied at staging). The 14z-49 medallion recolor changes that ROM row by design (data_port `med_pal_row14_a`: vsavj `0x3A3A80` ← vs2 `0x3BAFDC`), so the slot's content legitimately differs from vanilla on this build. Display-only (buffer → 90C000; the destination venue overwrites row 14 — legacy win screens pixel-compare 0-diff at f9200/f9400). Masked 14z-49, **maintainer-ratified 2026-08-02 (round 64)**. Expected content while masked — vanilla: `fffcfdc8fb96f973fcfffbcffa9df97af768f658f447f326ff00fc00f800f014`; this build: `fffffda8fc86fb75fa64f743f532f322facef78df458ffd6fb84fc22f922f005` (= vs2's live select row 05). **Audit on suspicion:** `tests/audit_mask_window_ff4182.sh` — reruns the original attribution measurement (05_timeout_idle f9126, vanilla + patched) and asserts the window holds exactly the expected row on each side AND the surrounding buffer bytes (`$FF4140-$FF41DF` outside the window) still match vanilla — i.e., the blind spot hides the designed diff and nothing else. Rerun it whenever: a new divergence lands near `$FF41xx`, row 14's source is retuned, or a new palette-block port is added (Huitzil/Pyron — extend the window per-slot then, never pre-widen) | designed content (this build) | [D: 05_timeout_idle f9126 byte-for-byte attribution + win-screen pixel A/B, session 14z-49; scripted audit added 14z-49d] |

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
| +0x382 (`$FF8782`/`$FF8B82`) | selected character ID at select/commit — but IN MATCH it is the **VOICE-FLAVOR CLASS** for the per-node sfx dispatcher (`PRG:0x27F16` → table `0x0BF41A`), and the engine REASSIGNS it mid-match: the voice-class borrow (sequencer event → `PRG:0x0AEF6`) writes a class from the opponent-row candidate list, so a match-time read is NOT the char id (measured 0x06/0x0C/… on a Donovan P1; 14z-87, engine_internals "third pass"). Select-time behavior unchanged: updates live with the hovered slot (verified both emulators); write 0x18 = Oboro (TCRF cheat) | [C:tcrf, D, 14z-87] |
| +0x392.w (`$FF8792`) | special-meter gauge CANDIDATE (steps 0→0x500→0x1400 while attacking; semantics unconfirmed) | [D] |
| — voice-class borrow block (14z-87, `A5=$FF8000` frame): | pool `RAM:$FF1E48` (8 candidate classes, copied per event from ROM `0x00B268` row `(0x382,opponent)<<6 + $FF8121`), voice-number list `RAM:$FF1E50` (from ROM `0x00BB68`), in-use mask `RAM:$FF8110.l` (bit = class; sound-state-fed — the run-to-run lottery), chosen index `RAM:$FF8114.w`, scan bound `RAM:$FF8138.w` (=6 measured), venue byte `RAM:$FF8121` | [D, 14z-87] |

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
| +0x102 | resolved strength/flavor byte (written by the ES/strength resolver — ported code 0xCF598 on our build) | [D: 14z-44] |
| +0x105 | ~48f transient raised by performing any special (gauge-blink family; NOT the stock) | [D: 14z-44] |
| +0x107 | resolver marker: 0xFF = single-button, 0xFE = pair downgraded (no stock); NOT meter consumption | [D: 14z-44] |
| +0x109 | **BANKED STOCK COUNT** (cap 0x63=99; the displayed stocks). The ES resolver tests this for two-button presses — poke it (ff8509 P1) to script ES moves | [D: 14z-44, disasm] |
| +0x10A.w | current meter-bar fraction; full bar = 0x90 units -> converts to +1 stock (gauge adder caps/converts here) | [D: 14z-44, disasm] |
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
docs/game/atlas/character_tables.md.

## The palette staging area — $FF3F02 + row*0x20 (14z-64)

The round-64 masked window `$FF4182-$FF41A1` was ratified as "the
palette-fade staging slot" for the 14z-49 row-0x14 port. 14z-64
identified the WHOLE structure: the engine stages palette-block rows
into per-row work-RAM slots at

    slot(row) = $FF3F02 + row * 0x20     (row 0x00 -> $FF3F02,
                row 0x14 -> $FF4182 = the ratified window,
                row 0x16 -> $FF41C2, 0x19 -> $FF4222, 0x1A -> $FF4242)

Venue events (screen transitions, the game-over sequence at ~f9126 of
replay 05, fades) stage block-A rows here and the copies PERSIST until
the slot is next reused — so any ROM edit to a block-A row shows a
sticky designed diff in its slot on the masked live-RAM basis. The V2
basis (14z-64, pending bundle ratification) masks the slots of the
three medallion rows the WIDE track edits (0x16/0x19/0x1A), exactly as
round 64 masked row 0x14's. Two measured hazards recorded with it:
- block-A row 0x00 is NOT select-private: the game-over starfield
  renders from it (a row-0 edit leaked visible pixels — reverted);
- the slots are the DETECTOR for such leaks: a slot diff plus a pixel
  diff means a shared row; a slot diff alone is the ratified-invisible
  class.

## 14z-66 additions — object physics, air system, servants [D: measured]

| Field | Meaning | Evidence |
|---|---|---|
| +0x0A (pre-engage) | INTRO-ANIMATION VARIANT, RNG-drawn at char load (table16[rand&15] in the per-char init; per-opponent downgrade branch). Becomes the attack id once play starts | [D: oracle gate] |
| +0x40.l / +0x44.l | X velocity / Y velocity (16.16) | [D: mover disasm] |
| +0x48.l / +0x4C.l | X accel / Y accel (gravity) — the mover 0x27E-family integrates +0x48->+0x40->+0x10 and +0x4C->+0x44->+0x14 | [D] |
| +0x06/+0x07 (of +0x04.l) | seq id byte / sub-state byte (class-02 seqs: stepper 0x225C4, table 0x225EE; jump = seq 06 -> handler 0x22A0E; air dash = seq 0x14) | [D] |
| +0x20/+0x21 | anim node timer / node header flags — bit 7 of +0x21 = the FLOAT LICENSE, installed per node from the header long (node stride 0x18; +0xC low 13 bits = shadow-seq id) | [D] |
| +0x1C0.w | float duration timer (armed 0x78 by the float conversion) | [D] |
| +0x179 | air-action resource counter (0x10 at load; float start decrements) | [D] |
| $FF80D4/D5 | the engine RNG state (routine vsavj 0x14E8A) — poke to determinize cross-game comparisons | [D: oracle gate] |
| +0x2A/+0x2C (extended block) | registered SHADOW/REFLECTION servant slots (the class-0x0C trio per player; installer 0x8237E) — shared shadow tables 0x2083BC/0x2087CA (row space 0x40E each, hardcoded at 0x823E2/0x823F2), sequence data from 0x208BD8 | [D: 14z-66 FG arc] |

Per-char tables decoded (bank scheme: vs2 = vsavj + (0xD7298-0xBD0FA)):
`PRG:0x0BDB7A` jump_params — id*0x30, THREE 0x10 rows (neutral/fwd/back
jump) of (xv,xacc,yv,gravity); RAW id, no fold; 32-row with 0x10-0x1F
byte-aliasing 0x00-0x0F; consumer = the installer every seq-0600
starter bsr's (vsavj 0x27A34 / vs2 0x26C86). Capture-pose per-victim
sets at `PRG:0x0BCE7A/0x0BCEFA/0x0BCF7A/0x0BCFFA` (the Midnight-Bliss
family; 32 rows x 4 bytes each), read by the capture-victim installer
(indexed by VICTIM id, seq id from the ATTACKER's code).

## Fighter + effect-pool fields (14z-67, measured on the H effect arc)

Fighter object ($FF8400 P1 / $FF8800 P2):
- +0x40 xv, +0x44 yv, +0x48 xacc, +0x4C gravity — 16.16 physics block
  (written together by the physics-row installer vj 0x28386; measured
  live on throw launches).
- +0x54 seq-related id fields (context-dependent; the effect machine
  reads its object's +0x54 as the EFFECT id).
- +0x318 / +0x320 / +0x330 / +0x340 — per-fighter effect-channel
  sub-structs (his handler passes a4 = &fighter+0x3n0 to the channel
  subs 0x28EE6/0x29124/0x29134/0x2916C-family).
- +0x382 char id (the per-char dispatch index — the seq-D head and
  the effect stage-2 record installer both read it).

Effect-piece pool $FFB800-$FFC7FF (32 × 0x80-stride slots; range
CORRECTED 14z-85 — the walker's own count byte is `move.b #0x20,($B5,A5)`
= 32 slots, this row used to say $FFBFFF/16 and understated the pool by
half):
- +0x00 alive/header (fleet spawner writes 0x01000800),
- **+0x02 TYPE byte** — the pool walker 0x5E52A's dispatch index
  (`move.b (2,a6),d0; *4` into the table at 0x5E556); written by header
  longs `move.l #$01xxTTss,(A4)` or byte stamps `move.b #type,(2,A4)`
  (the full frozen inventory: build/manifest/type_stamps.toml, 14z-82).
  On multi-tenant builds, non-first tenants' extended types (114-119)
  are RENUMBERED per tenant (engine_internals "Per-tenant TYPE
  NUMBERS"),
- +0x03 owner id / sub-state (written with the type by the spawn
  idiom; usage differs by family — pods: owner id, effects: sub-state),
- +0x0A subtype (fleet pieces 0x25/0x26),
- +0x1C record chain (head ptr; [head+4] = OBJ record — NULL until
  the anim stepper 0x1378A-family installs it),
- +0x18 bank word (fleet spawner inits 0; the subtype's first tick
  sets the real bank),
- +0x30 owner link (movea.w-compatible fighter pointer),
- +0x54 effect id / +0x56 sub-id,
- +0x7C-+0x7F: OUR hole_b code writes WORDS at +0x7C/+0x7E (PC
  0x3FFFD6) — a word at +0x7E covers byte +0x7F, so +0x7F is NOT free
  on this pool (14z-85; the 14z-84 "free" reading was a word-offset tap
  accounting artifact).

Projectile pool $FF9400-$FFB3FF (32 × 0x100-stride slots; expanded
14z-85 from the one-line row above): the 0x54470-site walker's pool
(head 0x54458: `lea ($1400,A5),A6`, stride `lea ($100,A6),A6`, live
test `tst.b (A6)`). Same layout family as $FFB800 for the low fields:
- +0x00 alive (the walker's own liveness test),
- +0x02 TYPE byte — walker 0x54458's dispatch index into the table at
  0x54484 (59 vanilla entries; extended 59-75 on tenant builds; the
  59-75 stamp inventory: build/manifest/type_stamps.toml),
- **+0x7F OWNER TAG (14z-85, tenant builds only)**: written at spawn by
  the detoured 59-75 stamp sites (`move.b #tenant_id,(0x7F,A4)` in the
  tag thunks; tag_map.json lists the writer PCs), read by the obj_hook
  64-75 tag stubs (`cmpi.b #id,(0x7F,A6)`). Measured free on vanilla
  paths: 804 live-slot obs, zero writes (byte-lane accounting), 3 legs
  incl. live family content — tests/audit_pool_free_byte.sh. Nothing
  clears it; stale tags in reused slots are unread by design.

Local pool $FFC800-$FFCFFF (24 × 0x80-stride slots; 14z-82): walked by
an embedded dispatcher INSIDE the x088512 span (src 0x8B988 =
x088512+0x3476, hui/pyron copies) with its OWN table at x088512+0x3494 —
its +0x02 type bytes are a SEPARATE small numbering space (0..~23),
nothing to do with the 0x5E556 table's numbers.
