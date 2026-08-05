# Select screen — cursor navigation and the cell↔id identity

Re-derived and **measured** 2026-08-04 (session 14z-60). Supersedes the
session-log-only record of 14z-59l/59n, which had the commit address wrong
by one instruction and existed nowhere a reader could check.

Gate: `tests/test_select_wheel.sh` (static decode + all 128 navigation
transitions measured in MAME). Tools: `tools/select_wheel.py`,
`tools/check_wheel_walk.py`.

## The routine

vsavj `PRG:0x020A34`; the vs2 twin is `PRG:0x01F5FC` (same fields, same
shape, table moved). Direction handling proper starts at `PRG:0x020A58`:

```
020A3E  move.w  $396(a6),d0      ; previous input
020A42  not.w   d0
020A44  and.w   $394(a6),d0      ; d0 = NEWLY pressed bits (edge-triggered)
020A4C  tst.b   $39(a6)          ; lockout timer: while nonzero, skip the
020A50  bne.b   $20a58           ;   button test (no confirm), still navigate
020A52  andi.w  #$7700,d0        ; buttons -> confirm path at $20A90
020A56  bne.b   $20a90
020A58  andi.w  #$f,d2           ; direction nibble
020A5C  lea     $211d4(pc),a0    ; TABLE A
020A62  move.b  (a0,d2.w),d1     ; direction index 0-7, or $ff
020A66  bmi.b   $20a84           ; $ff -> illegal combination, no move
020A6A  move.b  $3(a6),d0        ; CURRENT cursor cell
020A6E  lsl.w   #3,d0            ; *8   <-- NO MASK
020A70  lea     $211e4(pc),a0    ; TABLE B
020A74  lea     (a0,d0.w),a0     ; row base = TABLE_B + cell*8
020A78  move.b  (a0,d1.w),d0     ; new cell = row[direction]
020A7C  move.b  d0,$3(a6)        ; commit: cursor cell
020A80  move.b  d0,$382(a6)      ; commit: CHARACTER ID  (same value)
```

Movement is **edge-triggered**: `d0` is current-and-not-previous input, so
one press produces exactly one navigation event. Holding a direction does
not repeat.

Related sites, both measured in the same tap run:

| Address | What |
|---|---|
| `PRG:0x0209DA` | writes the DEFAULT cursor cell `0x01` (Demitri) at select entry |
| `PRG:0x020AA6` | `clr.b $3(a6)` on the confirm path |
| `PRG:0x020A98` | `cmpi.b #$b,$3(a6)` — cell `0x0B` is special-cased at confirm (sets `$3C1(a6)`) |

**`PRG:0x020A84` is NOT the commit site.** It is the `bsr.w $20C98` that
follows, and the `bmi` target for the no-move path. The two commit stores
are `PRG:0x020A7C` and `PRG:0x020A80`. Measured: every navigation write to
the cell byte comes from `0x020A7C` (145/145 presses).

## The tables

Both are reached by `lea`/`movea.l` and then read `(An,Dn)` — **DATA
space**. They do not exist in the opcode image; reading them there yields
plausible garbage (docs/GOTCHAS.md, PC-relative vs An-relative reads).

| Table | vsavj | vsav2 | Size |
|---|---|---|---|
| A — nibble → direction | `PRG:0x0211D4` | `PRG:0x01FE2C` | 16 B |
| B — 8-way adjacency | `PRG:0x0211E4` | `PRG:0x01588E` | 8 B × **32 rows** |

### TABLE A — `ff 00 01 ff 02 04 05 ff 03 06 07 ff ff ff ff ff`

Byte-identical in vsavj and vsav2. Indexed by the 4-bit direction nibble;
`$ff` on every impossible combination (both bits of an opposing pair, and
the neutral 0). The 8 legal combinations map bijectively onto 0-7.

**Nibble bits: 0=Right, 1=Left, 2=Down, 3=Up.** This is *not* derivable
from TABLE A — its structure is symmetric under swapping which bit-pair is
vertical. It is pinned by two independently recorded cursor paths, which
have a unique joint solution over all 8 labellings × 16 start cells:

- `11_pick_donovan.rpl`: U,U,R from the default → `0x0F` (Jedah)
- `character_tables.md`: L,L,D from the default → `0x09` (Aulbath)

Direction index order is therefore **0=R 1=L 2=D 3=U 4=DR 5=DL 6=UR 7=UL**.

### TABLE B — the adjacency graph

Row = cursor cell, column = direction index, value = destination cell.
`$ff` marks a cell that is not a cursor position at all.

vsavj (all 16 base cells navigable; cell 0x0B is the special slot):

```
cell |   R   L   D   U  DR  DL  UR  UL        cell |   R   L   D   U  DR  DL  UR  UL
  00 |  0C  06  08  07  0D  06  0C  03          08 |  0D  06  0B  00  0B  06  0D  06
  01 |  03  05  06  03  06  05  03  05          09 |  0A  0B  0B  0E  0A  0B  0A  0D
  02 |  04  0C  0E  0F  04  0C  04  0F          0A |  05  0E  09  04  05  09  05  0E
  03 |  00  01  06  07  00  01  07  01          0B |  09  08  0B  0D  09  08  09  08
  04 |  05  0E  0A  02  05  0E  05  02          0C |  0E  00  0D  0F  0E  00  02  07
  05 |  01  0A  0A  04  01  0A  01  04          0D |  0E  00  0B  0C  09  08  0E  00
  06 |  00  01  08  03  08  01  00  01          0E |  04  0D  09  02  0A  0D  04  0C
  07 |  0F  03  00  0F  0C  03  0F  0F          0F |  02  07  0C  0F  02  07  02  07
```

Rows `0x10-0x1F` are a **verbatim copy** of rows `0x00-0x0F`.

## The identity that matters: cell index IS character id

Both commit stores take the same `d0`. `$382(a6)` is the character-id field
of the player struct (`a6` = `RAM:$FF8400` P1 / `$FF8800` P2, so the live
cursor cell is `RAM:$FF8403` and the id `RAM:$FF8782`). There is no
translation layer between "which cell the cursor is on" and "which
character you get".

Cell → character is therefore exactly the slot map in
`character_tables.md`: `0x00` Bulleta … `0x0F` Jedah, with `0x0B` the
special slot the confirm path singles out.

## Why cells ≥ 0x10 work: the index is unmasked

`move.b $3(a6),d0; lsl.w #3,d0` indexes with the **whole byte**. Nothing
clamps it to 4 bits. That is why TABLE B is 32 rows rather than 16, and it
means a cursor cell in the variant half `0x10-0x1F` is addressable by
construction — the table already has physical rows for it.

vsavj never navigates there (no row targets `0x10+`), so its upper half is
inert duplication. **vsav2 does.** Its table is the same routine's table
with a different roster wired into it:

| | vsavj | vsav2 |
|---|---|---|
| navigable cells | 16 (`0x00-0x0F`) | 16 (`00 01 03 04 05 06 07 08 0B 0C 0D 0E 0F` + **`10 11 13`**) |
| entry-only | `0x10-0x1F` (copies) | `0x18` (row identical to cell `0x08`) |
| dead (`$ff` rows) | none | `02 09 0A 12 14-17 19-1F` |

`0x10`/`0x11`/`0x13` are Huitzil, Pyron and Donovan's character ids
(`character_tables.md`). The three base-half cells vs2 vacated — `0x02`,
`0x09`, `0x0A` — are Gallon, Aulbath and Sasquatch: **exactly the three
characters Vampire Savior 2 dropped**. The public roster swap falls out of
the adjacency bytes alone, which is independent confirmation that the cell
index is the character id.

`0x18` being entry-only is the flavor mechanism showing through: nothing
navigates to it, but the Start-hold variant path can put that id in
`$3(a6)`, and its row then has to behave like cell `0x08`'s — which it
does, byte for byte. vsavj's 16 duplicate rows are the same idea applied
uniformly.

## Where the cells are on screen (measured)

Positions cannot be read statically: the wheel record lists 18 OBJ entries
in **drawing order**, not cell order, so no static mapping assigns a
coordinate to a cell. Measured instead by parking the cursor on each cell
and reading the cursor ring — **palette `0x1E`** — out of OBJ RAM at
`0x708000`. Tool: `tools/wheel_positions.py`; frozen in section 4 of the
gate.

| cell | centre | | cell | centre |
|---|---|---|---|---|
| `00` | (224, 112) | | `08` | (224, 144) |
| `01` | (160, 112) | | `09` | (272, 144) |
| `02` | (280,  80) | | `0A` | (304, 128) |
| `03` | (192,  96) | | `0B` | (248, 152) |
| `04` | (304,  96) | | `0C` | (248,  96) |
| `05` | (336, 112) | | `0D` | (248, 128) |
| `06` | (192, 128) | | `0E` | (272, 112) |
| `07` | (208,  80) | | `0F` | (248,  64) |

Corroborated independently: 14z-49 identified Jedah's medallion (`0xB526`)
at (236, 57) by rendering candidate art; cell `0x0F` measures (248, 64)
here — the same cell reached by a different method, offset by the ring's
size (the earlier figure is a sprite corner, this is the ring centre).

### The adjacency is HAND-TUNED — do not generate it from geometry

Worth knowing before someone builds an auto-generator. Fitting the shipped
TABLE B with "step to the nearest cell inside this direction's sector"
reproduces at best **100 of 128 transitions (78%)** — with horizontal wrap
(period 184; the wheel wraps left↔right, cell `01` at x=160 goes L to `05`
at x=336) , no vertical wrap, and ±65° sectors. Every simpler variant does
worse; plain nearest-in-sector with no wrap manages 67%.

So ~22% of Capcom's entries are deliberate hand choices that no simple rule
predicts. **Adding cells means AUTHORING their rows and the neighbouring
edits, then verifying** — `tools/select_wheel.py` checks the result
(targets live, graph connected, nothing orphaned) and
`tests/test_select_wheel.sh` measures it in the emulator. A generated table
would be plausibly wrong in a way only playtesting would catch.

### Consequence for the roster (option 1)

Appending three cells needs **no indirection and no new mechanism**. It is
what vs2 already does: give each newcomer a live TABLE B row at its own id
and edit neighbouring rows so the three are reachable. See
`docs/atlas/id_space.md` for which ids are actually free to take, which is
a different question and the constraint that governs.

## The confirm-path id override ($43 / $45) — decoded, and NOT the Oboro path

At confirm, `PRG:0x020AAE` can replace the committed id:

```
020AAE  tst.b   $43(a6)          ; override armed?
020AB2  beq.b   $20ac2
020AB8  move.b  $45(a6),d0       ; the replacement id
020ABC  bmi.b   $20ac2           ; $ff = none, skip
020ABE  move.b  d0,$382(a6)
```

Both inputs are produced on the select screen, and both are now decoded:

```
020C98  cmpi.b #$b,$3(a6)        ; ON the special cell 0x0B
020CAC  addq.b #$1,$42(a6)       ; held...
020CB0  cmpi.b #$5,$42(a6)       ; ...5 frames
020CB8  st.b   $43(a6)           ; -> arm the override
020CBE  clr.b  $42(a6) / 020CC2  clr.b $43(a6)   ; otherwise disarm

020CD8  cmpi.b #$b,$3(a6)        ; NOT on cell 0x0B
020CE4  cmp.b  $46(a6),d0        ; same cell as last frame?
020CF6  cmpi.b #$3,$44(a6)       ; hovered 3 frames
020CFE  move.b $382(a6),$45(a6)  ; -> $45 = the CURRENT cursor id
020D0A  st.b   $45(a6)           ; else $45 = $ff
```

**`$45` can only ever hold `$ff` or a copy of the current cursor cell**, and
TABLE B constrains that to `0x00-0x0F`. So this override — the one dynamic
id-rewrite in the select code — **cannot introduce a variant-half id**. It
is therefore *not* the route by which vanilla reaches `0x18` (Oboro
Bishamon), and that entry path remains unlocated.

Measured alongside: across `03`/`04`/`09` neither `0x020CB8` nor
`0x020CFE` ever fires — no replay holds a button on the select screen long
enough — so the mechanism is present but unexercised by the corpus.

> **Caution: `$42-$45` on the player struct are SHARED SCRATCH.** The same
> bytes are reused by in-match code for unrelated purposes — `0x0273E6`
> writes a stepped ramp (`00 08 10 … F8`), `0x02F6D4` writes `0x28`,
> `0x031132`/`0x03113E` write `0x80`/`0xFB`. A value of `0x28` in `$45`
> would be outside the 5-bit id space entirely, and is harmless only
> because the confirm path runs during SELECT, not during a match. Any
> claim about these bytes has to be qualified by phase — reading them
> without that qualifier is the in-struct version of the
> displacement-collision trap.

## The Gallon variant path — vanilla's one immediate variant-half id

`PRG:0x020B9C`, on the select screen: with the cursor on Gallon (id `0x02`),
an input bit held (`btst #$7,$394(a6)`), and a confirm of **2-3 punches**
(`d0` in `300/500/600/700`) or **2-3 kicks** (`3000/5000/6000/7000`), the id
is overwritten with **`0x12`** — Gallon's variant — with `d1` recording
which of the two. Id `0x12`'s per-character data rows are byte-identical to
`0x02`'s, so it is the same character under a different id.

This is the only place vanilla writes a variant-half id as an immediate,
and it makes `0x12` **reserved**: no tenant may take it
(`docs/atlas/id_space.md`). It is also the likely resolution of the
"Dark Talbain rides a different mechanism" open item in
`character_tables.md`.

## Consuming a console capture: `tools/wheel_layout.py`

The console ports' select screen is the reference for where three new cells
go. Two modes:

```sh
# 1. map capture pixel coords into the arcade frame
tools/wheel_layout.py fit --refs refs.json

# 2. draft + validate a layout, and print the exact byte diff
tools/wheel_layout.py propose --data build/out/vsavj_data.bin --layout layout.json
```

**`fit` is why capture geometry barely matters.** It least-squares an
affine map from the capture's pixels to the arcade frame using the 16 cells
whose arcade positions are already measured. Independent horizontal and
vertical scale means non-square pixels, an arbitrary crop, and **a
field-only deinterlace that halves vertical resolution** are all just
coefficients — nothing to correct beforehand. Ground-truthed on a simulated
512×448 capture with halved vertical resolution and ±1px measurement noise:
the three unknown cells came back within **0.3 arcade px**, RMS residual
0.65. The tool prints the residual, so a bad reference set is visible
rather than silent.

**`propose` drafts adjacency but does not trust it.** The draft uses the
geometric model (wrap 184, ±65° sectors) that reaches only 100/128 against
Capcom's own table, and every drafted direction is labelled `DRAFT` so a
human corrects it. What the tool *does* enforce: every target is a live
cell, each new cell is reachable from the default cell `0x01` (not merely
the target of something — three new cells pointing only at each other form
an island, and that is caught), and no **reserved** id is used
(`docs/atlas/id_space.md`: `0x12`, `0x18`). Output is the byte diff against
vanilla TABLE B, ready to become a manifest row.

## The PS1 console-port reference (captures, 2026-08-05)

Three JPEG captures supplied by the maintainer (kept OUTSIDE the repo — they
show copyrighted art). The cursor is a **colour-cycling outline** around the
selected medallion, and the filenames say which character each player is on,
so correspondence comes from the cursor, not from identifying faces.

**ESTABLISHED — the topology.** The PS1 port did **not** rearrange vsav's
wheel; it kept the 16-cell hexagon (rows 1-2-3-4-3-2-1) and extended it
downward. An affine fit of six perimeter cells maps the capture onto the
arcade frame with **RMS 1.28 arcade px**, which is what "not rearranged"
means quantitatively. Its layout:

```
        ...the vsav hexagon, unchanged...
                 Pyron              <- takes the bottom-centre cell where
            Phobos   Donovan           vsav has RANDOM (0x0B)
                  ?                 <- random pushed to a new bottom row
```

**MAINTAINER'S AMENDMENT:** vsav's wheel is to be preserved exactly, so
**random stays at `0x0B` (248,152) and Pyron goes to the very bottom** —
i.e. swap Pyron and `?` relative to the PS1 arrangement. No image editing
needed; this is just which coordinate each id gets.

**PROVISIONAL — the coordinates.** Fitted arcade positions:

| cell | fitted arcade | confidence |
|---|---|---|
| Pyron (PS1 slot) | (240, 158) | ±10 |
| Phobos | (212, 179) | ±10 |
| Donovan | (271, 182) | ±10 |
| `?` (PS1 slot) | (238, 189) | ±10 |

**Do not build from these yet.** Held-out validation exposes the problem:
cells excluded from the fit (`0x08`, `0x06`) predict ~11 arcade px off,
because in the dense interior the medallions touch and a centroid read
drifts toward a brighter neighbour. The perimeter fit is trustworthy; the
interior reads that anchor the *downward* extrapolation are not. Two
symptoms of the same thing: the four new cells all land ~7-10px left of the
wheel's centre line (`x=248`), which the geometry says they should
straddle.

What would settle it, in order of value:
1. **A video capture of the cursor moving** — the outline is unambiguous, so
   every cell it visits yields an exact centre, AND the sequence gives the
   **adjacency**, which no still can provide and which is 22% unpredictable
   from geometry (see above).
2. A lossless PNG rather than JPEG, so medallion borders survive and blob
   detection works without hand-seeded points.

## The measured extension (PS1 video, 2026-08-05)

Adjacency for the three appended cells, and the inbound edges, **measured
from the console port** — the maintainer probed each cell direction by
direction on video and supplied the readings; the landing cells were
independently confirmed frame-by-frame from the recording.

**Mutual validation before use.** Where the report overlaps vsav's own
table it agrees: Lei-Lei's whole row is unchanged, and 5 of 11 probes on
the existing cells reproduce vanilla exactly (`Bishamon R`, `Bishamon DR`,
`Aulbath L`, `Aulbath DL`, plus all of Lei-Lei). Two independent sources —
a console recording and a table measured out of the arcade ROM — agreeing
is what licenses using the rest.

Translated BY POSITION, because PS1 puts Pyron in vsav's random cell and
random at the very bottom, while we keep random at `0x0B`:

| our cell | id | row (R L D U DR DL UR UL) |
|---|---|---|
| Phobos | `0x10` | `11 06 11 08 11 10 0B 06` |
| Donovan | `0x13` | `09 11 11 09 13 11 09 0B` |
| Pyron | `0x11` | `13 10 11 0B 13 10 13 10` |

Inbound edges (the only changes to EXISTING cells): `0x08 D -> 0x10`,
`0x09 D -> 0x13`, `0x0B D -> 0x11`, `0x0B DL -> 0x10`, `0x0B DR -> 0x13`.

**28 bytes total, of which only 5 touch a pre-existing row** — the minimum
legacy footprint that still makes the three cells reachable. Layout:
`build/manifest/wheel_layout_proposed.json`.

### Two PS1 changes deliberately NOT adopted — RATIFIED

PS1 also sets `Bishamon DL` and `Aulbath DR` to "no move", where vanilla
sends them to Anakaris and Sasquatch. Neither is needed for reachability,
so both stay vanilla. **Maintainer, 2026-08-05: "vsav vanilla is always
better when we can"** — now a standing principle (STATE): when a console
port and arcade vsav differ and both work, take vanilla. The capture is a
reference for what is possible and for data vsav does not contain, not a
style guide for content vsav already defines.

### A note on wrapping

The maintainer reports the PS1 grid does not wrap at any edge. Vertically
that matches vanilla exactly (`0x0B` Down and `0x0F` Up both self-reference,
and the new bottom cell `0x11` Down does the same). **Horizontally, vanilla
vsav DOES wrap**: cell `0x01` (x=160, leftmost) Left goes to `0x05` (x=336,
rightmost) — measured in the table and confirmed in-emulator by the
128-transition walk. Nothing in this change touches those cells, so the
behaviours coexist.

## Re-measuring

```sh
export ROMDIR=/path/to/reference/sets
tests/test_select_wheel.sh            # static + measured, 9 checks
# or by hand:
python3 tools/select_wheel.py build/out/vsavj_data.bin --set vsavj \
        --walk-rpl /tmp/w.rpl --walk-expect /tmp/w.json
REPLAY=/tmp/w.rpl TAP=ff8402,2 FRAMES=1450 TRACE_OUT=/tmp/tap.txt \
        tools/run_mame.sh vsavj -autoboot_script tests/lua/tap_writes.lua
python3 tools/check_wheel_walk.py /tmp/tap.txt /tmp/w.json
```

The walk is generated from the table, visits **every** (cell, direction)
pair, and states what each press must produce; the checker requires the
emulator to produce exactly that, from the commit PC, with a constant frame
offset. Its verdict logic carries four negative controls — one of which is
feeding it the old `0x020A84` address, which must fail.

Tap ranges must be word-aligned (`ff8402,2`, not `ff8403,1`) or MAME
refuses to install the tap.
