# atlas — sprite lists and the drawer (vsav / vsav2 / vhunt2)

The verified map of **how an object's animation becomes CPS-2 sprite
entries**. Companion to `ram.md` (object fields) and
`character_tables.md` (per-character data). The synthesis — what the
pieces mean and how they fail — is
`../engine_internals.md`, "The sprite-list drawer".

Everything here is measured on the decrypted opcode view
(`build/out/<set>_opcodes.bin`) and confirmed against live OBJ dumps
(`tests/lua/obj_records_dump.lua`). Provenance `VSAV`/`VS2`/`VH2`.

---

## 1. The drawer

One routine turns an object into sprite entries. It is entered per object,
per frame, from the pool walkers.

| set | drawer head | "list already in A0" entry | dispatch table |
|---|---|---|---|
| vsavj | `PRG:0x01AFA6` | `PRG:0x01AFAE` | `PRG:0x01AFBA` |
| vsav2 | `PRG:0x0199D4` | `PRG:0x0199DC` | `PRG:0x0199E8` |
| vhunt2 | `PRG:0x0199DA` | `PRG:0x0199E2` | `PRG:0x0199EE` |

```
01AFA6  movea.l 0x1C(a6),a0      ; the object's running ANIM NODE
01AFAA  movea.l 0x04(a0),a0      ; node +0x04 -> its SPRITE LIST
01AFAE  move.w  (a0)+,d0         ; the list's TYPE word   <- recursion entry
01AFB0  move.w  (0x08,pc,d0.w),d0
01AFB4  jmp     (0x04,pc,d0.w)   ; -> the type handler
```

The type word is a **byte-granular index in word units** (types are even:
0, 2, 4, …). Both the fetch and the jump are pc-relative, so on CPS-2 they
are served from the **opcodes** space — a `wpset` watchpoint is blind to
them (`../../platform/gotchas.md`).

### The table length is SELF-ENCODING

Handler code begins immediately after the last entry, so **entry 0's own
offset is the table size**:

| set | entry 0 | table bytes | types |
|---|---|---|---|
| vsavj | `0x000C` | 12 | 0, 2, 4, 6, 8, 10 (**six**) |
| vsav2 | `0x000E` | 14 | 0 … 12 (**seven**) |
| vhunt2 | `0x000E` | 14 | 0 … 12 |

Consequences, both load-bearing: the table **cannot grow in place**, and it
**cannot be relocated** (the dispatch is `(d8,PC,Xn)` — an 8-bit
displacement reaches nothing free). vsav's type-12 slot indexes two bytes
past the end and jumps into unrelated data.

### Handler targets

| type | vsavj | vsav2 | what it is |
|---|---|---|---|
| 0 | `0x01AFC6` | `0x0199F6` | coordinate list |
| 2 | `0x01B234` | `0x019C64` | coordinate list (the common one) |
| 4 | `0x01B61A` | `0x01A04A` | **procedural strip generator** |
| 6 | `0x01B6AA` | `0x01A0DA` | coordinate variant — **unused by vsav legacy** |
| 8 | `0x01B73E` | `0x01A16E` | coordinate variant |
| 10 | `0x01B7CC` | `0x01A236` | bare `rts` (a no-op list type) |
| 12 | — (absent) | `0x01A1FC` | **composite / group list** |

Legacy usage, measured on vanilla vsavj over replay 02
(`tests/audit_effect_class_rows.sh`, opcodes-space read watch on each
table slot):

| type | 0 | 2 | 4 | 6 | 8 | 10 |
|---|---|---|---|---|---|---|
| reads | 2260 | 4329 | 321 | **0** | **0** | 2702 |

Types 6 and 8 are dead in vanilla. Type 10 is a no-op handler but is
dispatched constantly — a bare `rts` is *not* evidence of a spare slot.

---

## 2. The per-list budget

Every handler opens with the same three instructions:

```
move.w (a0)+,d5      ; this list's declared sprite cost
cmp.w  d5,d7         ; d7 = the frame's remaining sprite budget
bcs    <skip>        ; not enough left -> the WHOLE list is skipped
sub.w  d5,d7
```

Skipping is all-or-nothing per list, so budget pressure makes whole pieces
of an effect vanish rather than degrade. `docs/game/gotchas.md` records the
coupling between this budget word and a one-byte work-RAM divergence.

---

## 3. List formats

Offsets are from the list's start; the type word at `+0` is consumed by the
drawer before the handler runs.

### Type 2 (and 0, 8) — coordinate list

| off | field |
|---|---|
| +0 | type word |
| +2 | budget (sprite cost) |
| +4 | count − 1 |
| +6 | pointer to a **separate coordinate stream** (x.w, y.w per sprite) |
| +10 | count × long: `(code.w, attr.w)` |

Positions come from the coordinate stream, offset by `d4` (the accumulated
composite offset). Crucially the handler takes its **bank bits from the
object**: `or.w 0x1A(a6),d0` (x word) and `or.w 0x18(a6),d1` (y word, which
carries the gfx bank — see `ram.md` and the per-char OBJ bank table).

### Type 4 — procedural strip

| off | field |
|---|---|
| +0 | type word |
| +2 | budget |
| +4 | count − 1 |
| +6 | count × 8 bytes: `(code.w, attr.w)` then `(coords.l)` |

A generator, not a coordinate list: it emits a run of tiles and flips them
by the runtime facing bit (`0x0B(a6)`). **Two constants in it are
game-specific — see §4.** It also **composes its own bank word**
(`ori.w #$2000` = bank 1) instead of taking the object's, which is why
type-4 art cannot be relocated to another bank by the record path.

### Type 12 — composite / group (vs2 and vh2 only)

| off | field |
|---|---|
| +0 | type word (`0x000C`) |
| +2 | count − 1 |
| +4 | count × 8 bytes: `(dx.w, dy.w, child-list.l)` |

Each child is drawn by **recursing into the drawer** at its "list already
in A0" entry, with `dx`/`dy` accumulated into `d4` and negated for facing.
Children may be any type, including another composite.

---

## 4. THE GAME-SPECIFIC CONSTANTS (the trap)

vsav and vsav2 do **not** interpret the same list data identically. Every
emitted tile code is biased by a constant, and the constant differs:

| type | vsavj | vsav2 | encoding |
|---|---|---|---|
| 0, 2 | — | — | identical (branch displacements aside) |
| **4** | `+0x3800` | `+0x4200` | `addi.l #$XX000000,d1` |
| **6** | `+0x3800` | `+0x4200` | `addi.w #$XX00,d2` |
| **8** | `+0x3800` | `+0x4200` | `addi.w #$XX00,d2` |

Ported vs2 list data run through vsav's handler therefore addresses tiles
**0x0A00 too low** and renders whatever art lives there. In types 4/6/8 the
routines are otherwise byte-identical — the difference is a single byte, at
`handler+0x7E` for type 4. Frozen by `tests/test_beam_list_type6.sh` §1c.

---

## 5. Multi-tile sprites

A sprite's `attr` carries its size: width−1 in bits 8-11, height−1 in bits
12-15. The hardware walks

```
tile = base + row*0x10 + ((base + col) & 0x0F)
```

— the column index **wraps within the base's row of 16**. Two consequences:
any tile-inventory work must expand `w×h` from the base (a base-only census
is how the 214+P ground explosion kept drawing a solid block), and any
relocation of such art must be **16-aligned** or the wrap breaks.

`tests/lua/obj_records_dump.lua` reports the BASE code only.

---

## 6. Worked example — Huitzil's freeze ray (vs2)

The beam is one type-12 composite per animation frame, three children:

| piece | child type | offset | notes |
|---|---|---|---|
| muzzle | 2 | `(0,0)` | 8-16 static sprites at the cannon |
| stretch | **4** | `-77` (`-183` for the ES) | procedural; absent on frame 0 |
| tip | 2 | marches `-109 → -397`, 32px per frame | 2 sprites (6 for the ES) |

Composite frames: P beam `0x251CD2`-`0x251E26` (14), ES `0x251E42`-`0x251F56`
(12). The strip's art is **bank 1** (`0x4EC0`/`0x4EE0`/`0x4F10`/`0x4F90`,
codes emitted after the +0x4200 bias) while the muzzle and tip are the
character's own **bank 3** band — one effect drawing from two gfx banks.

The strip's tile is **horizontally uniform** — each row a single colour —
and vs2 stores **16 identical copies** so a 16-wide sprite tiles seamlessly.
