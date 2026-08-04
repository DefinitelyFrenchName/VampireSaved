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
| layout-verified tables | 40 |
| variant rows that are byte-identical copies (`alias`) | 619 |
| variant rows holding their own data (`distinct`) | 21 |
| variant rows that do not exist (`out-of-range`) | **0** |

Zero out-of-range is the load-bearing number: every id `0x00-0x1F` has real
storage in all 40 tables. The per-character bank is physically 32 rows
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
> five-site folding list is a LOWER BOUND**, and the gate freezes it so
> growth is visible.

**How far the bound has been pushed.** A second, independent scan — running
*through* conditional branches and tracking the destination register until
it is redefined, 40 instructions deep instead of 10 — finds **exactly the
same five sites**. Two strategies with different failure modes agreeing is
the strongest evidence available short of a complete dataflow analysis.

What is still genuinely open: **62 of the 269 reads copy the id straight
into another memory field** rather than a data register, across 14 distinct
fields —

| field | sites | field | sites |
|---|---|---|---|
| `$a(a6)` | 16 | `$39(a6)` | 4 |
| `$a(a4)` | 13 | `$b1(a4)` / `$39(a4)` / `$9(a6)` | 2 each |
| `$b1(a6)` | 11 | `$3(a6)`, `$3e0(a6)`, `$3bd(a6)`, `$45(a6)`, `$9c(a4)` | 1 each |
| `$58(a4)` | 5 | | |

A complete folding census has to follow those fields to *their* consumers.
`$a(An)` is the owner-char-id an object carries, so its readers are the
likely place for further masks.

A **bounded** follow-up censused the three distinctive fields — `$b1`
(2 register reads), `$58` (26), `$9c` (6) — and found **no `andi` below
`#$10`** among them; the masks present are `#$1ff`/`#$3ff`/`#$7ff`
(position arithmetic) and `#$7700` (buttons). Treat that as suggestive, not
conclusive: **the same displacement on a different base register is a
different field**, so some of those 26 `$58` reads are not the `$58(a4)`
the id was written into. `$a(An)` and `$9(An)` were not censused at all —
displacements that small collide with every other struct field, so the scan
would be mostly noise. Closing this properly needs base-register-aware
dataflow, not a byte scan.

## The five vsavj folding sites

Each was decoded to its consumer; the fixes are not all the same shape.

| Site | What it computes | Why it folds | Fix class |
|---|---|---|---|
| `PRG:0x003E40` | `d1 = 0x360 + (id & 0x0F)`, then `bsr $4CE2` (the set-anim helper: `btst #0,$70(a6)` facing → `addi.w #$300,d1` → `jmp $3316`), wrapped in the kernel save/restore pair `$330E`/`$3306` | **the anim NUMBER BLOCK is genuinely 16 wide**: `0x360-0x36F` is one number per character, and `0x370` onward is already taken (the `0x04FFA8` table below holds `0x0370-0x03D7`). Widening to `#$1f` would run `0x360-0x37F` straight into it | **hard** — needs a free anim-number block, not a mask edit. vs2 **kept this fold** |
| `PRG:0x004082` | the same computation through `a4` | same | same as above |
| `PRG:0x00A43E` | `(id & 0x0F)` → `$130(a5)`, plus a struct pointer at `$13A(a5)` and a state kick (`$4(a5)=0x0A`, `$106(a5)=1`) | `$130(a5)` is written ONLY here and read at 15 sites clustered at `0x01BF9x-0x01C38x` and `0x021AC8-0x021C8E` — beside the select-screen code, i.e. the **per-slot venue-asset display family** (mugshot / name / medallion), whose arrays are 16-wide | **medium** — the same 16-wide per-slot arrays the project already ports for Donovan; extend those, then widen |
| `PRG:0x0409EC` | `(id & 0x0F)` compared against `#$06` — a behavioural special case for slot 6 (Anakaris) | not a table at all, just a slot test | **trivial** — a newcomer is only affected if it must inherit or avoid Anakaris' special case. vs2 **kept this fold** |
| `PRG:0x04FAC4` | `(id & 0x0F) * 24` into `PRG:0x04FFA8` — 12 words per character (6 pairs; `tst.b $bc(a5)` selects +0 or +2), values `0x0370-0x03D7` | **nothing structural.** Measured: that table is **32 rows × 24 bytes**, ending cleanly at `0x0502A8`, with rows `0x10-0x1F` byte-identical copies of `0x00-0x0F` | **easy** — the rows already exist; fill the tenant's row and widen the mask to `#$1f` |

So the five are not one problem. Two (`0x03E40`/`0x04082`) are constrained
by an anim-number block that is really 16 wide — and those are exactly the
two vs2 chose to keep, which is the strongest available evidence that
inheriting there is acceptable. One (`0x0409EC`) is a slot test. One
(`0x00A43E`) rides the venue-asset arrays already on the port's work list.
And one (`0x04FAC4`) is a free win: its table already has the rows.

> **Correction (same session).** The first pass of this page said
> `0x04FAC4` "folds because the table it indexes genuinely has 16 rows".
> That was wrong, and wrong in the familiar way — the table was read out of
> the OPCODE image, where a `lea (pc)` + `(An,Dn)` table is high-entropy
> noise, and 16 rows of noise look as much like 16 rows as like 32. Read
> from the DATA image it is plainly 32 aliased rows. The mask is a
> convention there, not a constraint.

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
   value (as vs2 does twice) or widen. The five are not equal work:
   `0x04FAC4` is a fill-the-row-and-widen (easy), `0x00A43E` rides the
   venue-asset arrays already on the port's list (medium), `0x0409EC` is a
   slot test (trivial), and `0x03E40`/`0x04082` need a free anim-number
   block because `0x360-0x36F` is genuinely 16 wide (hard — and the two
   vs2 left folded).
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
