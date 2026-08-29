# The character-id space — is the variant half architectural or conventional?

Measured 2026-08-04 (session 14z-60). Gate: `tests/test_id_space.sh`.
Tool: `tools/audit_id_space.py`. Companion: `docs/game/atlas/select_screen.md`.

*Currency (14z-118 audit): the gate PASSES on today's tree (44 tables, 25
distinct variant rows, 7 folding sites — unchanged since 14z-111's +4 AI
tables). Everything this page predicted has since SHIPPED and is measured
elsewhere: the three tenants on `0x10`/`0x11`/`0x13` (14z-64/65/8x), the
21-cell wheel with cell == id (`select_screen.md` "The measured extension",
14z-63; repositioned 14z-115), the port's own `0x18` route
(`oboro_select_hook`, 14z-105), the tenants' ladder rows and AI script
roots (14z-111), random select listing the tenants (`roster_subst`,
14z-117), and the full attract roster (`test_attract_roster.sh`, 14z-118).
The sections below are the MEASUREMENT that licensed those; status notes
mark where a later session settled a question they left open.*

**[VSE-10]** **THE ANSWER: conventional.** The id is a 5-bit value everywhere it is
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
(`docs/game/atlas/select_screen.md`).

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

Every read of `$382(An)` located, the destination register
tracked forward, and the first mask or compare applied to it recorded.

| classification | vsavj | vsav2 |
|---|---|---|
| `andi #$0f` via a register — **folds** `0x1x` onto `0x0x` | **5** | **2** |
| `andi.b #$0f,$382(An)` — folds, applied DIRECTLY in memory | **2** | 0 |
| **total folding sites** | **7** | **2** |
| `andi #$1f` — full 5-bit | 3 | 6 |
| `andi #$3e` — 5-bit, pre-scaled ×2 | 1 | 1 |
| `cmpi #$10` | 0 | 1 |
| indexes a table with no mask | 34 | 36 |
| no mask seen in window | 226 | 258 |
| **read sites total** | **269** | **305** |

**vsav2 folds at 2 sites where vsavj folds at 7, and masks to 5 bits at 6
sites where vsavj does at 3.** That is Capcom widening the consumers that
needed to tell a variant character from its base — the direct evidence that
this is a per-site data question, not a wall.

> **CAVEAT, stated because it bounds the claim.** `none` means no
> mask/compare was seen within 10 instructions of the read, stopping at the
> first branch. It is not proof that those sites never narrow the id. **The
> folding list is a LOWER BOUND**, and the gate freezes it so growth is
> visible — it has already grown once, from five to seven, see below.

**How far the bound has been pushed — and where it broke.** A second,
independent scan (through conditional branches, tracking the register to
redefinition, 40 instructions deep) finds exactly the same five
register-path sites. Then a **sixth and seventh turned up that neither
walker could ever have seen**:

```
vsavj 010E28  addq.b  #$1, $382(a4)      vsav2 00F48E  addq.b  #$1, $382(a4)
      010E2C  andi.b  #$0f,$382(a4)            00F492  andi.b  #$1f,$382(a4)
      010E36  subq.b  #$1, $382(a4)            00F4AE  subq.b  #$1, $382(a4)
      010E3A  andi.b  #$0f,$382(a4)            00F4B2  andi.b  #$1f,$382(a4)
```

This is the **id-cycling selector** — step the character id up or down and
wrap it. vsavj wraps to `0-15`; **vsav2 wraps to `0-31`.** The same
instruction in both games, one nibble apart: Capcom widening this exact
site is what let their cycling selector reach characters in the variant
half.

**[VSE-11]** Both walkers missed it because both keyed on *register* dataflow, and these
instructions read-modify-write memory with no destination register. Found
by disassembling the selector by hand. The lesson generalises: **a dataflow
walk over registers cannot see a mask applied straight to a memory field**,
and the tool now scans for that class separately (`direct_masks`).

vs2's selector also carries `andi.b #$01,$382(a4)` on a second path, chosen
by a flag at `a5-0x50B8` — a 2-value toggle over ids 0/1 for another menu
context. That is a **range restriction, not a fold**, and an earlier
"`imm < 0x10` means folding" test miscounted it; `mask_class()` now
distinguishes `#$0f` (folds the variant half), `#$1f` (full 5-bit) and
everything else.

What is still genuinely open: **62 of the 269 reads copy the id straight
into another memory field** rather than a data register, across 14 distinct
fields —

| field | sites | field | sites |
|---|---|---|---|
| `$a(a6)` | 16 | `$39(a6)` | 4 |
| `$a(a4)` | 13 | `$b1(a4)` / `$39(a4)` / `$9(a6)` | 2 each |
| `$b1(a6)` | 11 | `$3(a6)`, `$3e0(a6)`, `$3bd(a6)`, `$45(a6)`, `$9c(a4)` | 1 each |
| `$58(a4)` | 5 | | |

**One such fold is now measured**, and it matters: `PRG:0x00A43E` stores
the folded id at `$130(a5)`, and `PRG:0x01BF98` masks it to 4 bits AGAIN on
the way into the select/VS palette-block tables
(`docs/game/atlas/venue_assets.md`). So **the folding-site count on this page is
PER-FIELD** — it counts folds applied to `$382(An)`, and derived fields
carry their own. Do not read "7 sites" as "7 places in the game".

A complete folding census has to follow those fields to *their* consumers.
`$a(An)` is the owner-char-id an object carries, so its readers were the
obvious place to look for further masks — and the bounded census that
follows found none.

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

## The seven vsavj folding sites

Each was decoded to its consumer; the fixes are not all the same shape. The
first five narrow the id through a register; the last two mask the field
directly in memory.

| Site | What it computes | Why it folds | Fix class |
|---|---|---|---|
| `PRG:0x003E40` | `d1 = 0x360 + (id & 0x0F)`, then `bsr $4CE2` (the set-anim helper: `btst #0,$70(a6)` facing → `addi.w #$300,d1` → `jmp $3316`), wrapped in the kernel save/restore pair `$330E`/`$3306` | **the anim NUMBER BLOCK is genuinely 16 wide**: `0x360-0x36F` is one number per character, and `0x370` onward is already taken (the `0x04FFA8` table below holds `0x0370-0x03D7`). Widening to `#$1f` would run `0x360-0x37F` straight into it | **hard** — needs a free anim-number block, not a mask edit. vs2 **kept this fold** |
| `PRG:0x004082` | the same computation through `a4` | same | same as above |
| `PRG:0x00A43E` | `(id & 0x0F)` → `$130(a5)`, plus a struct pointer at `$13A(a5)` and a state kick (`$4(a5)=0x0A`, `$106(a5)=1`) | `$130(a5)` is written ONLY here and read at 15 sites clustered at `0x01BF9x-0x01C38x` and `0x021AC8-0x021C8E` — beside the select-screen code, i.e. the **per-slot venue-asset display family** (mugshot / name / medallion), whose arrays are 16-wide | **medium** — the same 16-wide per-slot arrays the project already ports for Donovan; extend those, then widen |
| `PRG:0x0409EC` | `(id & 0x0F)` compared against `#$06` — a behavioural special case for slot 6 (Anakaris) | not a table at all, just a slot test | **trivial** — a newcomer is only affected if it must inherit or avoid Anakaris' special case. vs2 **kept this fold** |
| `PRG:0x04FAC4` | `(id & 0x0F) * 24` into `PRG:0x04FFA8` — 12 words per character (6 pairs; `tst.b $bc(a5)` selects +0 or +2), values `0x0370-0x03D7` | **nothing structural.** Measured: that table is **32 rows × 24 bytes**, ending cleanly at `0x0502A8`, with rows `0x10-0x1F` byte-identical copies of `0x00-0x0F` | **easy** — the rows already exist; fill the tenant's row and widen the mask to `#$1f` |
| `PRG:0x010E2C` | `andi.b #$0f,$382(a4)` after `addq.b #$1` — the id-cycling selector, stepping up | nothing structural; vsav2 does the identical thing with `#$1f` | **easy** — one nibble, exactly as vsav2 shipped it |
| `PRG:0x010E3A` | the same after `subq.b #$1` — stepping down | same | same |

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

## Which ids vanilla ever assigns (measured over the corpus)

Audit: `tests/audit_id_writers.sh` (on-demand, 22 MAME runs). Both player
structs are tapped — `RAM:$FF8782` and `RAM:$FF8B82` — because the CPU
opponent, the attract assignment and the challenger path write **only** to
P2, and a P1-only tap misses all three.

Measured over **11 legacy replays × 2 fields = 22 tap logs**, every one
carrying its `END` summary line:

| writer | ids written | what it is |
|---|---|---|
| `PRG:0x020A80` | `00 01 03 05 06 08` | the select commit (cursor cell) |
| `PRG:0x00AEF6` | `0A 0C 0E` | the CPU-opponent picker |
| `PRG:0x005BF4` | `02 0F` | attract assignment, P1 — the corpus's two minutes of attract reach demos 0-1 only; the writer's FULL range is the 8-row table `PRG:0x005C08` (P1 `0F 02 0C 0E 06 01 09 0D`, P2 `03 00 08 04 0A 05 07 06`), decoded and frozen 14z-118 (`test_attract_roster.sh`): still not one variant-half id |
| `PRG:0x005BFA` | `00 03` | attract assignment, P2 — same table, second byte |
| `PRG:0x008A86` | `05` | challenger / 2P join |
| `PRG:0x009008` | `01` | P1 init |
| `0x000D34` `0x000D3A` `0x000DD8` `0x016E4C` `0x016E4E` | `00`, `FF` | boot RAM clear |

**[VSE-14]** Union of ids written by any gameplay path:
`00 01 02 03 05 06 08 0A 0C 0E 0F` — **not one value in `0x10-0x1F`.**

**Why this matters.** If no legacy gameplay path can produce a variant-half
id, a tenant at `0x13` occupies rows **no legacy content can reach**, and
the superset invariant holds *by construction* rather than by in-place
surgery. The current slot-`0x0F` port needs that surgery precisely because
legacy cursors visit Jedah's cell and legacy code reads his records — see
the three superset traps in `GOTCHAS`. Moving a tenant onto a variant id
should therefore make the invariant EASIER to hold, not harder.

**The gap, stated plainly — and it is bigger than first written.** Vanilla
CAN produce a variant-half id: `0x12`, via the Gallon-variant select path
above (found after this audit, by a different method). No replay in the
corpus triggers it, so the audit's PASS stands as measured — but the claim
it supports is "no legacy replay HERE writes the variant half", never
"vanilla cannot". Likewise `0x18` (Oboro Bishamon) *is* a variant id
vanilla uses — four sites compare against it (`PRG:0x018F9A`, `0x026FBE`,
`0x0293A8`, `0x043000`) — and **no replay in this corpus reaches it**. So
what is established is "no legacy replay in the corpus writes the variant
half", not "vanilla cannot". A tenant must still avoid `0x18`, and the
Oboro entry path is worth characterising before the argument is leaned on
harder. Nothing static was found that sets bit 4 of the id directly. **The
`$43`/`$45` confirm-path override has since been decoded and ruled out**
(`select_screen.md`): `$45` can only hold `$ff` or a copy of the current
cursor cell, so it cannot introduce a variant id. ~~Oboro's entry path is
still unlocated, and it is the one remaining hole in this argument.~~
**CLOSED 14z-116 (marked 14z-118): there is no vanilla entry path — no
vsavj code writes `0x18` to `$382` (the only immediate id writes are
`0x02`, `0x04`, `0x0B`, `0x12`); the four compare sites read a value only
the port's own hook can produce. The hole is measured shut, not assumed.**
**14z-105 note: that sentence is about VANILLA's own route to `0x18`
(the boss-encounter logic), which stays unlocated ~~and no longer matters~~ — and at 14z-116 was measured NOT TO EXIST (see the closure above; marked 14z-118)
for the port — the WIDE build now carries ITS OWN player-facing path,
the profile-gated `oboro_select_hook` (Bishamon's cell + Start held at
confirm, vanilla's Gallon-variant idiom at `PRG:0x020B9C` one cell over;
`select_screen.md`, gate `tests/test_oboro_select.sh`). The id stays
RESERVED for tenants exactly as before: it is Oboro's.**

The audit's verdict logic is ground-truthed in both directions: an injected
variant-half write from a gameplay PC fails it, and a tap log missing its
`END` line fails it (MAME can segfault in teardown *after* writing a
complete log — the exit code is deliberately ignored, the `END` line is the
artifact that decides).

## The arcade-opponent path (a fourth roster work item)

**[VSE-15]** "Selectable" is not "fightable". Tapping the **P2** id field `RAM:$FF8B82`
found three gameplay writers the P1 tap never sees:

| writer | what it is |
|---|---|
| `PRG:0x00AEF6` | the CPU-opponent picker |
| `PRG:0x005BFA` | attract-demo character assignment |
| `PRG:0x008A86` | the challenger / 2P-join path |
| `PRG:0x020A80` | the same select commit, with `a6` = P2's struct |

The picker (`PRG:0x00AED8`) reads well for our purposes:

```
00AED8  moveq   #$ff,d0          ; index = -1
00AEDA  move.l  $110(a5),d2      ; 32-bit "already fought" mask
00AEDE  lea     -$61b8(a5),a2    ; opponent ORDER LIST (work RAM)
00AEE2  addq.w  #$1,d0
00AEE4  move.b  (a2,d0.w),d1     ; candidate id
00AEE8  cmp.w   $138(a5),d0      ; list LENGTH
00AEEC  bcc.b   $aef2
00AEEE  btst.l  d1,d2            ; used?  <- LONG btst: bits 0-31
00AEF0  bne.b   $aee2
00AEF6  move.b  d1,$382(a1)      ; commit the opponent
```

Two things follow:

- **The used-mask is already 32 bits wide** (`btst.l`), so it accommodates
  5-bit ids with no change. One less thing to widen.
- The candidate ids come from an **order list in work RAM at `a5-0x61B8`
  with its length at `$138(a5)`**. Adding newcomers to the arcade ladder
  means extending that list and its length — a distinct work item from the
  select wheel, and easy to forget because the wheel is the visible half.

Downstream, `PRG:0x00B094` takes the picked list index, reads the id, and
does `id * 32` into a palette-source pool at `PRG:0x3A3CA0` (the opponent's
VS-screen palette). That pool holds **real, non-aliased data at variant
ids** and continues past 32 entries, so a tenant at `0x13` lands on real
memory rather than out of bounds — the entry there is currently a
placeholder-looking grayscale ramp, i.e. content the tenant must supply
rather than a bound to fix.

## RESERVED IDS — vanilla does use part of the variant half

Found by scanning for `move.b #imm,$382(An)` (a hardcoded id stored into
the id field; `$382` is a distinctive displacement, unlike small offsets
like `$3` which collide with every other struct):

| set | reserved variant ids | where |
|---|---|---|
| **vsavj** | **`0x12`** | `PRG:0x020BB6`, `PRG:0x020BC6` |
| **vsav2** | `0x19` | `PRG:0x01F864` |

vsavj's `0x12` is the **Gallon variant** path, on the select screen:

```
020B9C  cmpi.b #$2,$382(a6)   ; cursor is on id 0x02 (Gallon / J. Talbain)
020BA4  btst   #$7,$394(a6)   ; a specific input bit held
020BAC  bsr    $20c18         ; d0 in {300,500,600,700}  = 2-3 PUNCHES
020BB6  move.b #$12,$382(a6)  ; -> id 0x12          (d1 = 0)
020BBC  bsr    $20c38         ; d0 in {3000,5000,6000,7000} = 2-3 KICKS
020BC6  move.b #$12,$382(a6)  ; -> id 0x12          (d1 = 1)
```

Id `0x12`'s per-character rows are **byte-identical aliases of `0x02`** in
the four tables this audit covers (hitbox base, dispatch, anim index,
`word132` all verified equal) — **but NOT in the two palette pointer tables
`0x38C198`/`0x38C218`, where `0x12` owns its rows** (`character_tables.md`
"Both variant halves alias the base half except at rows 0x12 and 0x18";
frozen by `tests/test_effect_palette_table.sh` assertion 2). Same moveset,
own palette: that IS Dark Gallon. *(Until 14z-118 this paragraph stopped at
"same character under a different id" and called the Dark Talbain link
"very likely … nobody has selected it and watched".)* It was selected and
watched: the trigger was decoded 14z-116 (`PRG:0x020C18`) and the maintainer
played it on the board 2026-08-28 — the `character_tables.md` "open item" is
RESOLVED.

vsav2's `0x19` is its second Oboro-class dataset, exactly as
`character_tables.md` documents; its neighbouring sites `0x01F5A8`/`0x01F5BC`
write `#$08`, which is the match-init id normalisation the atlas already
places at `PRG:0x01F5A0`. Two independent records agreeing is why this scan
is trusted.

**[VSE-13]** **Consequence for the roster.** The free-id set is smaller than "everything
above `0x0F`":

- **taken:** `0x00-0x0F` (the wheel), `0x12` (Gallon variant), `0x18`
  (Oboro — vanilla ships its DATA complete; **measured 14z-116: NO vanilla
  path writes `0x18` to `$382` — the only immediate id writes in vsavj are
  `0x02`, `0x04`, `0x0B`, `0x12` — so there is no vanilla entry path to
  locate; the port's 14z-105 `oboro_select_hook` is the only one.** *(This
  line said "vanilla's entry path still unlocated" until 14z-118.)*)
- **free, and what the plan targets:** `0x10`, `0x11`, `0x13` — **taken by
  Huitzil / Pyron / Donovan since 14z-65/8x; the reserved set is locked by
  `test_id_space.sh` and no further id is free below `0x1F` without a
  ruling (`0x14-0x17`, `0x19-0x1F` alias their base rows in vsavj)**

The plan survives unchanged, but only because it happened to pick around
`0x12`. `tests/test_id_space.sh` now locks the reserved set, so growth
fails the gate instead of surfacing after a build.

## What a per-tenant manifest must declare

Falls straight out of the above:

1. **`id`** — the character id, 5-bit. Using each newcomer's **native vs2
   id** (`Huitzil 0x10`, `Pyron 0x11`, `Donovan 0x13`) means every ported
   bank row lands at its own index with no renumbering, and matches the
   wheel cells vs2 already ships.
2. **`wheel_cell`** — equal to `id` (there is no indirection), plus the
   TABLE B row and the neighbouring rows edited to make it reachable.
   *(Shipped exactly so at 14z-63: cells `0x10/0x11/0x13`, inbound edges from
   `0x0B`/`0x08`/`0x09` — `select_screen.md`; the random cell's draw table
   lists them since 14z-117.)*
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
5. **Arcade-ladder membership** — the opponent order list at `a5-0x61B8`
   and its length `$138(a5)`, plus the VS palette block at
   `PRG:0x3A3CA0 + id*32`. Selectable is not fightable. *(Status 14z-118:
   the tenants' OWN ladder rows and AI script roots shipped 14z-111 (#99);
   a tenant is a CPU opponent only when the player is a tenant — ladder
   table A rows 16/17/19 — and no legacy character ever meets one in 1P,
   ruled NOT A PROBLEM 2026-08-28 (STATE). The VS palette block for a
   tenant is STILL UNSUPPLIED — the placeholder ramp; single-player,
   cosmetic, never reported from the board.)*
6. **Tables whose per-id layout is still unverified** (`rec8`, `byte2d`,
   `auto` gaps) — these must be resolved by decoding a consumer before a
   tenant is declared to own a row in them. Writing a speculative row into
   one is precisely the Felicia wall-jump defect.

## Re-measuring

```sh
export ROMDIR=/path/to/reference/sets
tests/test_id_space.sh
python3 tools/audit_id_space.py --set vsavj \
    --op build/out/vsavj_opcodes.bin --dat build/out/vsavj_data.bin
tests/audit_id_writers.sh          # on-demand, 22 MAME runs: every id vanilla writes
tests/test_attract_roster.sh       # the attract writer's full range (14z-118)
tests/test_effect_palette_table.sh # the two palette tables' 0x12/0x18 exceptions
```

Bank addresses are rebased per set from the origin delta
(`bank_map.toml`); reading vsavj addresses out of a vs2 image compares
unrelated bytes and invents findings.
