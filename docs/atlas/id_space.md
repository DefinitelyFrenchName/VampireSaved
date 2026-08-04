# The character-id space — is the variant half architectural or conventional?

Measured 2026-08-04 (session 14z-60). Gate: `tests/test_id_space.sh`.
Tool: `tools/audit_id_space.py`. Companion: `docs/atlas/select_screen.md`.

**THE ANSWER: conventional.** The id is a 5-bit value everywhere it is
stored and in every layout-verified table; vsavj simply fills the upper 16
rows with copies. The only architectural narrowing is a small, enumerable
set of *consumer sites* that mask the id to 4 bits — and vsav2, which ships
three characters on variant ids, shows the fix is to widen those sites.

Consequence for the roster: **option 1 needs no indirection between wheel
cell and character id.** The three newcomers can hold real ids, and the
work is a finite list of code sites rather than a new abstraction.

## What was measured

Two halves, because the question has two.

### 1. Data — do the upper rows exist?

Row `0x10+k` compared against row `k` for every id-indexed table.

| vsavj | count |
|---|---|
| layout-verified tables | 39 |
| variant rows that are byte-identical copies (`alias`) | 603 |
| variant rows holding their own data (`distinct`) | 21 |
| variant rows that do not exist (`out-of-range`) | **0** |

Zero out-of-range is the load-bearing number: every id `0x00-0x1F` has real
storage in all 39 tables. The per-character bank is physically 32 rows
throughout — 64 tables packed back-to-back, each table's entry 31 ending
exactly where the next begins. The two tables outside the bank agree: the
OBJ bank table `PRG:0x0282D4` is 32 words ending exactly where code resumes
at `0x028314`, and the wheel adjacency table `PRG:0x0211E4` is 32 rows
(`docs/atlas/select_screen.md`).

The 21 `distinct` rows are **not** noise:

- **`0x18` in 20 bank tables** — Oboro Bishamon, the documented vsavj
  variant dataset (`character_tables.md`).
- **`word_pos_a[0x16] = 0x0018`** — every character holds `0x0010` except
  Anakaris (`0x06` = `0x0020`), whose variant id `0x16` holds a third
  value. So vsavj already uses a variant row differentially somewhere
  other than slot 8. The upper half is live storage, not padding.

Not counted as evidence, and reported apart by the tool: `auto` gap rows
(no decoded consumer — `GOTCHAS`, "Never write an unverified gap") and
`rec8`/`byte2d` rows whose per-id entry LAYOUT is unverified (`GOTCHAS`,
"Per-char table entries are PAIRS more often than you think" — a 16-char
table of 8-byte pairs and a 32-char table of 8-byte values have identical
spacing). Those need a decoded consumer each before their variant rows mean
anything.

### 2. Code — how wide is the id where it is consumed?

Every read of the id field `$382(An)` located, the destination register
tracked forward, and the first mask or compare applied to it recorded.

| classification | vsavj | vsav2 |
|---|---|---|
| `andi #$0f` — **folds** `0x1x` onto `0x0x` | **5** | **2** |
| `andi #$1f` — full 5-bit | 3 | 6 |
| `andi #$3e` — 5-bit, pre-scaled ×2 | 1 | 1 |
| `cmpi #$10` | 0 | 1 |
| indexes a table with no mask | 34 | 36 |
| no mask seen in window | 226 | 258 |
| **read sites total** | **269** | **305** |

**vsav2 folds at 2 sites where vsavj folds at 5, and masks to 5 bits at 6
sites where vsavj does at 3.** That is Capcom widening the consumers that
needed to tell a variant character from its base — the direct evidence that
this is a per-site data question, not a wall.

> **CAVEAT, stated because it bounds the claim.** `none` means no
> mask/compare was seen within 10 instructions of the read, stopping at the
> first branch. It is not proof that those sites never narrow the id. **The
> five-site folding list is a LOWER BOUND.** Closing it means deepening the
> walk and following branches; the gate freezes what is known so growth is
> visible.

## The five vsavj folding sites

| Site | What it does | vs2 |
|---|---|---|
| `PRG:0x003E40` | `d1 = 0x360 + (id & 0x0F)` → `bsr $4CE2` — a per-character **sound id** in a 16-wide range | same code at `0x003E76` — **vs2 kept the fold** |
| `PRG:0x004082` | the same computation reached through `a4` | pattern absent (refactored) |
| `PRG:0x00A43E` | `(id & 0x0F)` → `$130(a5)` work var, with a struct pointer at `$13A(a5)` | pattern absent (changed) |
| `PRG:0x0409EC` | `(id & 0x0F)` compared against `#$06` — a per-character special case on slot 6 | same code at `0x041BDC` — **vs2 kept the fold** |
| `PRG:0x04FAC4` | `(id & 0x0F) * 24` into the 16-row record table at `PRG:0x04FFA8` | pattern absent (changed) |

Two of the five are folds vs2 *deliberately kept* — a newcomer sharing its
base character's sound-id base and slot-6 special case was acceptable to
Capcom. The other three vs2 changed, which is where the porting work is.

`0x04FAC4` is the instructive one: the fold is there because the table it
indexes genuinely has 16 rows. Widening that site means growing a table,
not deleting an `andi` — the mask is a symptom of the structure behind it.
Every site needs that judgement made individually.

## What a per-tenant manifest must declare

Falls straight out of the above:

1. **`id`** — the character id, 5-bit. Using each newcomer's **native vs2
   id** (`Huitzil 0x10`, `Pyron 0x11`, `Donovan 0x13`) means every ported
   bank row lands at its own index with no renumbering, and matches the
   wheel cells vs2 already ships.
2. **`wheel_cell`** — equal to `id` (there is no indirection), plus the
   TABLE B row and the neighbouring rows edited to make it reachable.
3. **Tables the tenant owns rows in** — the 39 layout-verified tables all
   have a row at the tenant's id.
4. **Folding sites the tenant needs widened** — from the list above, per
   tenant, with a decision recorded for each: inherit the base character's
   value (as vs2 does twice) or widen.
5. **Tables whose per-id layout is still unverified** (`rec8`, `byte2d`,
   `auto` gaps) — these must be resolved by decoding a consumer before a
   tenant is declared to own a row in them. Writing a speculative row into
   one is precisely the Felicia wall-jump defect.

## Re-measuring

```sh
export ROMDIR=/path/to/reference/sets
tests/test_id_space.sh
python3 tools/audit_id_space.py --set vsavj \
    --op build/out/vsavj_opcodes.bin --dat build/out/vsavj_data.bin
```

Bank addresses are rebased per set from the origin delta
(`bank_map.toml`); reading vsavj addresses out of a vs2 image compares
unrelated bytes and invents findings.
