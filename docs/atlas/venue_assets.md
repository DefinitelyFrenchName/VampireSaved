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
two ids `docs/atlas/id_space.md` marks reserved, found there from hardcoded
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

- **This fold is invisible to the `$382` census.** `docs/atlas/id_space.md`
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
