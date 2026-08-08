# Per-slot presentation assets — what a tenant on a variant id inherits

Measured 2026-08-05 (14z-60v), to de-risk moving a tenant from slot `0x0F`
to id `0x13`. The question: which per-character *presentation* assets follow
a tenant to a variant id, and which silently fall back to the base
character's?

**Summary: the in-match sprite palettes are clean; the select/VS-screen
palettes are not.** The first is a 32-row pointer table with an unmasked
consumer — repoint one row and done. The second is folded to 4 bits, so a
tenant at `0x13` shows Victor's colours there until it is widened. That is
cosmetic, and matches the maintainer's standing bar (imperfect art
acceptable, mechanical soundness not).

## 1. Sprite palettes — CLEAN, one row to repoint

```
01C3E4  move.w  $100(a5),d0     ; NOT the folded $130(a5)
01C3E8  subi.w  #$20,d0         ; bounded at 32, not 16
01C3EC  bcc.b   $1c43a
01C3FE  lea     $38c198.l,a0    ; palette POINTER table
01C404  move.w  $100(a5),d0
01C408  add.w   d0,d0
01C40A  movea.l (a0,d0.w),a0    ; no mask anywhere
01C40E  lea     $90c140.l,a1    ; -> palette RAM
```

`PRG:0x38C198` is **32 rows of longs**, every one a ROM-plausible pointer,
and the consumer bounds the index against `#$20`. So a variant id is a
first-class row here, not an over-read.

| row | pointer | |
|---|---|---|
| `0x03` | `0x38D1A0` | Victor |
| `0x0F` | `0x390CA0` | Jedah — the row the port repoints today |
| **`0x12`** | **`0x3911A0`** | **its own** — Dark Talbain |
| **`0x13`** | `0x38D1A0` | alias of `0x03`, i.e. **free to repoint** |
| **`0x18`** | **`0x3916A0`** | **its own** — Oboro Bishamon |
| other `0x1x` | = base row | aliases |

**Independent corroboration of the reserved ids.** `0x12` and `0x18` — the
two ids `docs/game/atlas/id_space.md` marks reserved, found there from hardcoded
`move.b #imm,$382(An)` writes — are exactly the two variant rows carrying
their own palette pointer here. Two unrelated tables agreeing is why the
reserved set is trusted.

**Consequence for the move:** a tenant at `0x13` gets its own sprite
palettes by repointing row `0x13`, exactly as the port repoints `0x0F`
today. Victor's row `0x03` is untouched, so no superset risk.

## 2. Select / VS-screen palette blocks — FOLDED to 4 bits

`PRG:0x00A43E` masks the id to 4 bits and stores it at `$130(a5)`, read at
14 sites. Eight of them index four per-character palette-block tables:

```
01BF94  move.b $130(a5),d0
01BF98  andi.w #$f,d0        ; <-- the fold
01BF9C  ror.w  #$6,d0        ; = id * 0x400
01BF9E  lea    $3a4400.l,a0
```

| table | blocks |
|---|---|
| `PRG:0x3A4400` | 1 KB per character |
| `PRG:0x3C13C8` | " |
| `PRG:0x3D25F0` | " |
| `PRG:0x3E6938` | " |

These are the four ROM palette-source pages `character_tables.md` records
(A5+`0x7404`/`0x7408`/`0x740C`/`0x7410`).

Two important details:

- **This fold is invisible to the `$382` census.** `docs/game/atlas/id_space.md`
  counts folds applied to the id FIELD; this one is applied to a *derived*
  work var. It is a concrete instance of that page's own caveat that 62
  reads forward the id elsewhere. **The folding-site count is per-field, and
  the derived fields have their own.**
- **Two consumers do NOT mask** — `PRG:0x021C64` and `PRG:0x021C8E`, the
  select-screen sites, read `$130(a5)` unmasked with the same `ror #6`
  scaling. At `id = 0x13` that lands `0x4C00` past the base. Measured: the
  pool continues past 16 blocks with real palette-looking data, so the
  result is **wrong colours, not an out-of-bounds crash**.

**Consequence for the move:** a tenant at `0x13` shows Victor's colours at
the masked sites and some other pool block's at the unmasked ones. Cosmetic,
and fixable later by widening those sites to `#$1f` and placing the tenant's
blocks at pool index `0x13` — **but only after confirming what occupies
index `0x13` in each of the four tables.** The pool is dense; writing a
speculative block into it is the Felicia wall-jump trap in a new costume.

## Re-measuring

```sh
python3 build/scratch/venue.py  build/out/vsavj_opcodes.bin   # the 14 consumers
python3 build/scratch/palptr.py build/out/vsavj_data.bin      # the 32-row table
```

(Scratch analysis scripts, not build tools — regenerate them from this page
if `build/` has been cleaned.)

## 3. HUD mugshot + name plate — NOT folded; 32-row aliased tables (14z-63)

The in-match "VICTOR"/wrong-mugshot symptom at a variant id was attributed
to the `$130(a5)` fold on this page's earlier reading. Measured: **wrong
family.** Neither HUD consumer reads `$130(a5)` at all:

```
mugshot stager  PRG:0x8937C..  move.b $782(a5)/$b82(a5),d0 ; add.b d0,d0
                               move.w (a0,d0.w),(a1)+      ; a0 = 0x89884
name stager     PRG:0x89684    move.b $382(a4),d0 ; ext.w ; lsl #3
                               lea $898C4(pc),a0 ; lea (a0,d0.w),a0
```

Both index UNMASKED, and both tables are **32-row aliased** (rows
0x10-0x1F byte-copies — the engine convention, verified in the data
image): mugshot `PRG:0x89884` (word/char, +0x3800 stager base), name
`PRG:0x898C4` (8B/char). So id 0x13 read row 0x03's alias — Victor —
and the fix is pure row work, no mask widening:

- `hud_mug_entry_13` poke16 `0x898AA <- 0x8690` (= 0xBE90 - 0x3800);
- `hud_name_entry_13_hi/lo` poke32 `0x8995C/0x89960 <- 0x868C0202 /
  0xFFE80003` (same vs2-derived row shape as the 0x0F fix);
- mugshot art: effect_tail `place_variant_slot` `0x4D62,2,2 -> 0xBE90`
  (free pool: blank + unprotected, verified in vanilla AND built
  members) — variant builds only, so Jedah's own 0x3DC8 cells stay
  pristine. Name art is the unconditional 0xBE8C placement.

All three pokes are `only_variant_slot` (the inverse of the 62c gate).
Live-verified in-match (replay 36 f3100): mugshot code 0xBE90 2x2 attr
0x112A at (200,32), name 0xBE8C 3x1 attr 0x0202 at (144,40), opponent
mugshot still staging from the vanilla 0x3Dxx page. Gate:
`tests/test_tenant_hud.sh`.

**What the `$130(a5)` fold still owns:** the select/VS palette-block
family in section 2 (Donovan's wrong COLOURS there), and its two
unmasked 0x021C64/0x021C8E siblings. That work is separate and still
open — see section 2's consequence paragraph.

## §2 addendum (14z-64): the fold path is DORMANT in every measured flow

The concern above presupposed the `0x00A43E` fold executing on tenant
surfaces. Audited (14z-64), it does not:

- **Dynamic**: write-taps on `$FF8130` across seven flows — boot,
  attract, 1P select, 2P select, VS, match, KO, bonus tally, 2P victory
  screen, arcade win-quote — the fold write NEVER fires. The field's
  live writers are the screen init (0, PC 0x2033E) and the cursor
  commit (1, PC 0x20AE8): in these flows `$130(a5)` is a context flag,
  not an id.
- **Static**: ZERO jsr/bsr/jmp/table references to `0x00A43E` in the
  whole first MB — it is fall-through-interior code of a routine whose
  trigger lies outside every measured flow (plausibly ending/gallery
  content).
- Twelve maintainer playtest rounds surfaced no color fault on any
  tenant screen.

**Verdict: no tenant-visible surface reads a folded block today; no
widening or block placement is needed.** RESIDUAL: the deep-arcade
ENDING flow (finishing the game with the tenant) is unmeasured — if it
ever shows Victor-colored elements, re-run this audit's taps on that
flow; the fix pattern (win_pal-style sparse block + TT thunks at the
consumers) is established.
