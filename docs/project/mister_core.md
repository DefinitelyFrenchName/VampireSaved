# CPS-2 WIDE on MiSTer — the core, synthesised

**What this is.** Why the full roster fits in 64 MB of SDRAM, where every byte
of it goes, and which limits no amount of memory can buy off. It is organised
in **causal order** — each section exists because the one above it forces it —
rather than in the order any of it was discovered. Read it to answer "why is
the map shaped like that, and what would break it?"

**How it relates to the other docs.** `docs/platform/mister.md` is the
platform LOG: what jtcps2 and jtframe do, measured, with every retraction
still visible. `docs/project/mister_map.md` is the PLACEMENT with its
derivations, slice plan and open questions. `docs/project/mister_fit.md` is
the DEMAND measurement — what the roster needs, region by region.
`docs/project/cps2_wide.md` is the profile itself, of which MiSTer is the
third implementation. Those four are logs and are meant to be; this file
keeps the conclusions and names them as the provenance.

> **STALENESS ORDERING RULE.** Where this document and one of those four
> disagree, **the log wins and this document is the thing to fix.** A number
> here is a quotation, never a measurement; every figure below names the
> document or the gate it came from. If you cannot find the citation, treat
> the figure as unverified and say so rather than propagating it.

**Ground truth.** jtcores fork `DefinitelyFrenchName/jtcores` branch
`vampire-saved`, pinned at `emu/jtcores` = `dd242a653c2797d3` (upstream tag
`v1.7.3` = `63688ce5`, plus fifteen fork commits). The romset is the merged
build `build/m3b_merged13`. Two download images anchor everything measured
here: stock `vsavj.rom` **46,407,744 B** sha1 `f9dc2987…`, and the WIDE
`vsavjw.rom` **66,265,152 B** sha1 `d462e55a…`.

---

## 0. The one thing to understand first

**Nothing about the game changes on MiSTer. What changes is where bytes are
put.** The romset is the same romset FBNeo and MAME load — same members, same
CRCs, one profile — and the MiSTer deliverable is an extension of Jotego's
`jtcps2`, not an FPGA re-implementation of what the emulators do. The whole
of the work below is a *mapping* problem plus a small set of *format* fixes.

Two consequences run through every section that follows.

* **The superset invariant becomes structural rather than tested.** Vanilla's
  32 MB of graphics is placed in SDRAM banks 2 and 3 by expressions the
  profile does not touch, and the profile itself is a runtime bit that stock
  `vsavj` never sets. "Untouched by construction" is a property of the
  circuit here, not a conclusion drawn from a passing test — and the tests
  then confirm it rather than establish it (§4, §6, §8).
* **Everything that is still hard is a FORMAT limit, and formats are not
  bought off with memory.** A 128 MB module would not lift one of the four
  caps in §7. That is the finding that retired "MiSTer work = width plumbing
  only", and it is why the arc is five RTL slices rather than a parameter
  change.

One habit for anyone reading further: **when a number here is a size, ask
which of the three sizes in §5 it is.** Conflating them has produced a wrong
published figure three times in this project, and it is the single hardest
thing on this page to hold in the head.

---

## 1. What we are building

A MiSTer FPGA core that runs the full-roster romset, built as a **separate
core** — `cores/cps2w` in the fork, emitted as `jtcps2w.rbf` — so the
reference CPS-II core stays installed and usable beside it. That was the
maintainer's ruling of 2026-08-22, and it is the reason none of the work
below is allowed to edit `cores/cps1`, `cores/cps2` or `cores/cps15`: those
three are held byte-untouched against upstream `v1.7.3` by
`tests/test_jtcores_twin.sh`.

jtcores and jtframe are **GPL-3.0**, so the fork is public by obligation
rather than by preference. Simulation is the gate; hardware — MiSTer, a
128 MB SDRAM module, a Jammix card into a CRT at native timing — is the field
test. Distribution is MRA + RBF over the same release members as
`release/<name>/`, plus a stock-`vsav` reference-leg MRA.

**The separate-core mechanism is jtcores' own, not something we invented.**
`cores/cps2`'s `cfg/game.yaml` pulls the CPS-1 video/SDRAM/tilemap pipeline
from `cores/cps1` and the QSound block from `cores/cps15`; `cores/cps15`
exists the same way. A file is copied into `cores/cps2w/hdl` only when it
must differ, and **the diff between the two core directories IS the trust
surface**. As of slice D4 that diff is twelve files — nine overrides of shared modules
plus three new ones — and one addition to jtframe, all enumerated and frozen
line by line (§9).

That mechanism has a price, and it compounds: **overriding one shared file
costs you the whole `.yaml` that pulled it.** `jtframe files` deduplicates by
full path, so a core cannot both include a yaml and override a file that yaml
pulls — both copies would compile. Slice D1 paid this once for
`qsound.yaml` (one file transcribed); slice D2 paid it again for
`common.yaml` (twenty files transcribed to override two). `cps2w`'s
`game.yaml` is consequently 73 lines different from `cps2`'s, frozen in
`tests/expect/cps2w_game_yaml_delta.txt`, and the two copies have to be kept
in step by hand at every uprev.

**And the price is paid per FILE, which is what makes the trust surface grow
in steps rather than smoothly.** Slice D3 needed ONE expression in the object
scanner, and it cost FOUR override files: the scanner, the object wrapper
around it, the drawer it hands the bank to, and the video block the bank
leaves through. A 3-bit bank has to be three bits wide at every port between
the frame table and SDRAM, and a width left at 2 anywhere in between would
silently drop bank bit 2 and fetch vanilla art for every tenant sprite. Three
of those four files change nothing but a width, and the fourth is the
promote.

---

## 2. What the roster needs

Three of CPS-2's four downloadable regions have to grow to hold eighteen
characters instead of fifteen. The numbers come from `mister_fit.md`, whose
instruments are named there; each is re-checked by
`tests/audit_mister_map_fit.sh`.

| region | stock CPS-2 | WIDE v1 declares | what is actually live |
|---|---|---|---|
| 68k program | 4 MB (`main_rom_addr[20:0]`) | **6 MB** | to `PRG:0x4D10F3`, plus a 30-byte pin at `PRG:0x5FFF00` |
| GFX | 32 MB (2-bit obj bank) | **48 MB** | vanilla's 32 MB + group C |
| QSound samples | 8 MB (7-bit DSP bank latch) | **16 MB** | 8 MB stock + 918 KB extension, to region offset `0x8E57F0` |
| Z80 program | 256 KB | 256 KB | unchanged (`vsw.z01`/`z02`, 2 × 128 KB) |

**The program deficit is 836 KB and it is not negotiable by rearranging
things.** Live content reaches `PRG:0x4D10F3`; jtcps2 decodes a flat 4 MB;
the shortfall is `0xD10F4`. That is consistent with the 14z-85 finding that
Donovan and Huitzil alone overflow 4 MB by ~310 KB. The 30-byte facing-alias
thunk pinned at `PRG:0x5FFF00` is a fixed manifest address rather than
allocator output, so it sits at the top of the declared 6 MB with 1.1 MB of
`0xFF` fill beneath it.

**And the graphics conclusion is the one that forced this whole arc.** Group
C — the two WIDE obj banks holding the three tenants' art — carries
**6.39 MB** of live tiles. Every blank tile in the whole of vanilla's 32 MB
adds up to **0.49 MB**, and blank is only an upper bound because a blank tile
may still be referenced as transparent filler. The roster's art is **13×
larger than every spare tile in vanilla put together**, and the smallest
single tenant band (Pyron, 14,037 codes = 1.7 MB) is on its own 3.5× the
blank total. There is no "fit it in the stock 32 MB" variant and no
tenant-dropping variant: **a MiSTer build of this roster requires a GFX map
wider than 32 MB.** (`mister_fit.md` §3.)

> **Two counts of "group C live codes" are in circulation, and they are
> different quantities.** `mister_fit.md` §3 reports **45,737 + 6,610 =
> 52,347 codes / 6.39 MB** from the as-built *write set* — what the build
> writes. `mister_map.md` §1 and `tests/audit_mister_map_fit.sh` report
> **45,736 + 6,245 = 51,981 codes / 6.345 MB** from a *non-blank census* of
> the shipped members. The 366-code difference is tiles the build writes that
> are all-`00`/all-`FF`, 365 of them in obj bank 5. Neither document says so,
> which is how the two get quoted as if they were the same measurement. The
> figure that governs placement is neither of them — see §5.

---

## 3. What the hardware gives

jtcps2 addresses its SDRAM as **four banks of 16 MB — 64 MB**, and at our
pinned version of jtframe that ceiling is **physical, not a setting anyone
forgot to raise**. Every link in the chain says so, and all of it is read out
of the pinned tree (`mister.md`, "The SDRAM ceiling at our pin").

* **jtframe's own table stops there.**
  `jtframe_sdram_bank_core.v:32-34` lists `AW 22 | 4 MBx2 = 8MB | 32 MB` and
  `AW 23 | 8 MBx2 = 16MB | 64 MB`. There is no row for 24.
* **The row/column geometry saturates at `SDRAMW=23`.**
  `jtframe_sdram64_bank.v:75-76` is `localparam ROW=13, COW= AW==22 ? 9 : 10;`
  — a two-arm ternary with no arm for 24. An `AW=24` build would drive row
  `addr[22:10]` and column `{addr[23], addr[8:0]}`, so **`addr[9]` would
  never reach the bus at all** and every address would alias with
  `addr ^ 0x200`. Quiet per-512-word corruption, not a build error.
* **The pins are not there either.** The MiSTer target declares
  `SDRAM_A[12:0]`, `SDRAM_BA[1:0]` and ONE `SDRAM_nCS`; `sys/sys.tcl` assigns
  exactly thirteen address pins, two bank pins and one chip select. Thirteen
  row bits plus ten column bits across four internal banks, sixteen bits
  wide, is 64 MB. Saturated.
* **No single chip is bigger.** jtframe's own SDRAM catalogue lists every
  128 MB module as **two or four units**; the largest single-chip entry is
  64 MB. 128 MB on MiSTer is definitionally more than one chip.

**And the vendored dual-SDRAM support is unreachable at this pin, for a
reason worth stating plainly: on a DE10-Nano the dual-CHIP SDRAM path and the
ANALOG I/O board are mutually exclusive.** `sys/sys_analog.tcl` and
`sys/sys_dual_sdram.tcl` claim the same physical pins (`PIN_Y15` is
`LED_USER` in one and `SDRAM2_DQ[0]` in the other, and three more like it),
and `mister.qsf` sources the analog pair. That is not academic here: the
field test in §1 is Jammix into a CRT, i.e. analog video. **Any 128 MB route
that needs two physically separate modules is also a route that gives up the
CRT field test.**

So the problem is exactly this: WIDE v1 declares 6 + 48 + 16 MB of content,
the tier holds 64 MB total, and 32 MB of that is already spoken for by
vanilla's own graphics.

---

## 4. The one escape, and why it is the fallback

A 128 MB tier **does** exist — upstream, added long after our pin, as
`JTFRAME_SDRAM_XL` (`SDRAMW=24`). Its mechanism is genuinely neat: a 128 MB
MiSTer module is **two chips on one board** sharing every address pin, and
the core picks between them with the top address bit by inverting the
**polarity** of the chip select —
`{sdram_ncs, …} <= { sel_cmd_r[3] ^ sel_chip_r, … }`, so the addressed chip
sees its command while the other sees DESELECT. The init sequence runs twice,
once per chip, and the Verilator model matches. It is real and it ships:
`cores/cps3` sets the macro and `sfiii3n` runs at ~80 MB.

It is the fallback rather than the plan for three reasons, none of them
aesthetic.

1. **No release tag carries it.** `v1.7.3` (2024-01-18) is the newest version
   tag in the repository's 532 tags; XL landed in 2026. `master` is
   `ahead_by` **3057** commits. Adopting XL means pinning a bare master
   commit — trading a tag for a moving target.
2. **XL is not reachable by a flag.** It lives only in the
   `JTFRAME_SDRAM_CACHE` branch of the SDRAM front end
   (`jtframe_board_sdram.v:158`); the other arm instantiates
   `jtframe_sdram64`, which was never taught XL. CPS-2 has no `cfg/mem.yaml`
   — it wires explicit slot modules — so taking XL means converting CPS-2's
   hand-written memory interface, shared with CPS-1 and CPS-1.5, to a
   generated one.
3. **Nothing enforces that pairing, and the failure is silent.** jtframe's
   macro validator rejects XL together with `JTFRAME_SDRAM_LARGE` and
   together with any `JTFRAME_BAx_START`, but **nothing requires
   `JTFRAME_SDRAM_CACHE` alongside XL**. Setting the macro on `cores/cps2w`
   as it stands today would compile, pass validation, and silently produce
   the `addr[9]`-aliased map of §3. Filed in `docs/platform/gotchas.md` so it
   is not discovered during a bring-up.

The repack needs none of that and runs on a 64 MB module as well as a 128 MB
one. **And XL would not shorten the arc**: every core-side format change in
§7 is required on either tier. XL buys headroom, not work avoided.

> **A retraction worth carrying, because it is the ordinary lesson in a new
> place.** 14z-106 recorded "NO XL SDRAM tier exists" from a grep over
> `modules/jtframe` that returned zero hits. That was **true at our pin and
> false as a claim about jtframe**. A grep proves a fact about the tree you
> grepped, and a pin is a tree.

---

## 5. Three sizes of the same art

**This section exists because conflating these three numbers has produced a
wrong answer three separate times, twice in published figures.** They are not
interchangeable, and each one governs a different decision.

| | group C, obj bank 4 | group C, obj bank 5 | total | what it governs |
|---|---|---|---|---|
| **live bytes** — art that exists | 45,736 codes | 6,245 codes | **6.345 MB** (write set: 6.39 MB) | the ROMSET. Nothing else |
| **address footprint** — the span the codes reach | to `0xEE73` → `0x773A00` = 7.452 MB | to `0xFFDB` → `0x7FEE00` = 7.996 MB | **15.447 MB** | how much ADDRESS SPACE must exist |
| **declared region** — what the MRA downloads | 8.000 MB | 8.000 MB | **16.000 MB** | **what consumes an SDRAM bank** |

**The middle row is a property of CPS-2, not of our art: a tile code IS its
address.** `jtcps1_prom_we.v:105` applies the CPS-2 GFX address scramble at
download time, and composed with the `.rom`'s 4-way 64-bit interleave the
scramble **undoes the interleave** — the SDRAM address of tile code `c` is
exactly `c * 128 + (byte within tile)`, contiguous and monotonic in `c`. That
is proven rather than argued: for all 131,072 tiles of a group, the set of
addresses the download writes for tile `t` is exactly `[t*128, t*128+128)`,
verified exhaustively at 14z-107 (4) and re-sampled by
`tests/audit_mister_map_fit.sh` with a control that fails the check when the
scramble is removed. **The art is sparse *within* 15.45 MB of address space,
and it cannot be compacted without renumbering tile codes — which is game
data.**

```
   0 MB     2        4        6        8       10       12       14       16 MB
   |-------|-------|-------|-------|-------|-------|-------|-------|
D  ################################################################  16.000  what SDRAM reserves
F  ##############################··################################  15.447  what the codes reach
L  .++##############   .+########  ##+       .   .....+.+++    .  .   6.345  what actually exists
   |-------|-------|-------|-------|-------|-------|-------|-------|
   ^ obj bank 4 (0-8 MB)                 ^ obj bank 5 (8-16 MB)

   D = declared region   F = address footprint   L = live art, cell by cell
   (each L cell spans 2,048 tile codes; '#' means most of them carry art,
    '+' some, '.' a handful, ' ' none. The drawn page resolves 128 cells.)
```

**Which number governs what.** *Live bytes* tell you how much art exists —
useful for the romset, useless for placement. The *address footprint* tells
you the span the codes reach and therefore how much address space must exist.
The *declared region* is what the MRA downloads, so it is what SDRAM reserves
whether or not the art fills it — **and it is the only one of the three that
consumes a bank.**

That is the relation the rest of this document depends on, and it points in
two directions at once:

* **Adding tenant art costs nothing**, as long as the codes stay inside the
  existing 16 MB, because the space is already reserved. A new tile above
  `0xEE73` or `0xFFDB` overflows nothing.
* **The declared region cannot grow at all.** A fifth group-C member, or
  anything past 16 MB, overflows immediately and there is nowhere to put the
  excess — §6 shows why.

What the footprints still tell you is how much of each region is *dead*:
**574,976 B in obj bank 4 and 4,608 B in obj bank 5**, which is what a
group-C MRA trim could in principle recover. That trim is **not** the flat
`length=` truncation the QSound one was: the GFX region is a 4-way 64-bit
interleave and the download scramble turns a contiguous tail of tile codes
into a non-contiguous set of `.rom` offsets. Unmeasured, recorded, not needed
today.

> **How this was caught, once, the expensive way.** `mister_map.md` claimed
> 0.708 MB of slack for four sessions. It had sized the two group-C obj banks
> by their live address footprint. The slice-D2 SDRAM image census counted the
> real download and found **0.125 MB**, with bank 1 exactly full — a factor
> of six. The error was one of KIND, not arithmetic, and it is the reason
> this section exists at all.

---

## 6. Where every byte goes

Vanilla's 32 MB of graphics stays exactly where stock jtcps2 puts it, in
banks 2 and 3, untouched to the byte. Everything the roster adds is placed
around it. The map below is `mister_map.md` §5, measured byte for byte
against a real download image by `tests/test_mister_sdram_census.sh`.

```
 byte offset     0        2        4        6        8       10       12       14      16 MB
                 |-------|-------|-------|-------|-------|-------|-------|-------|
 SDRAM bank 0    PPPPPPPPPPPPPPPPwwwwwwwwsssQQQQ55555555555555555555555555555555.
 SDRAM bank 1    qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqq44444444444444444444444444444444
 SDRAM bank 2    ================================================================
 SDRAM bank 3    ================================================================
                 |-------|-------|-------|-------|-------|-------|-------|-------|

   ^ 4 cells = 1 MB, one scale for all four banks. Adjacent regions sharing a
     glyph are merged, so bank 0's four system windows and their 32 KB
     alignment gap are one 's' run; the drawn page separates them.

   P  68k PRG, the stock 4 MB the core already decodes
   w  the WIDE program extension, CPU:$400000-$5FFFFF — live to PRG:0x4D10F3,
      then 0xFF fill, plus the 30-byte facing-alias pin at PRG:0x5FFF00
   s  VRAM 256K + OBJ RAM 32K + work RAM 64K + the 512K Z80 window + a 32K gap
   Q  QSound PCM HIGH — a 1 MB window, DSP sample banks 0x80-0x8F, 0xF0000 loaded
   5  GFX group C, obj bank 5 — an 8 MB REGION (select/wheel art; cold in a match)
   q  QSound PCM LOW — the stock 8 MB, DSP banks 0x00-0x7F, at offset 0 as on stock
   4  GFX group C, obj bank 4 — an 8 MB REGION (the fighter bands; in-match traffic)
   =  vanilla GFX, byte-for-byte where the stock core puts it — obj banks 0/2 in
      ba2, obj banks 1/3 in ba3 (bank 1's bytes are also the scroll slot)
   .  free — 131,072 B in bank 0 and NOTHING ANYWHERE ELSE
```

| bank | byte offset | region | size | how it gets there |
|---|---|---|---|---|
| 0 | `0x000000` | 68k PRG, `CPU:$000000-$5FFFFF` | 6 MB | `ROM_OFFSET = 0`; slot 3, `SLOT3_AW` 21 → 22 |
| 0 | `0x600000` | VRAM | 256 KB | `VRAM_OFFSET = 23'h300000` |
| 0 | `0x640000` | OBJ RAM | 32 KB | `ORAM_OFFSET = 23'h320000` |
| 0 | `0x648000` | work RAM, `RAM:$FF0000-$FFFFFF` | 64 KB | `WRAM_OFFSET = 23'h324000` |
| 0 | `0x658000` | Z80 window (256 KB downloaded) | 512 KB | `SND_OFFSET = 23'h32C000` |
| 0 | `0x6D8000` | alignment gap | 32 KB | — |
| 0 | `0x6E0000` | QSound PCM high (`0xF0000` downloaded) | 1 MB | new `PCMH_OFFSET = 23'h370000` |
| 0 | `0x7E0000` | GFX group C, obj bank 5 | 8 MB | new `GFXC5_OFFSET = 23'h3F0000` |
| 0 | `0xFE0000` | **free** | **131,072 B** | |
| 1 | `0x000000` | QSound PCM low | 8 MB | `PCM_OFFSET = 0`, unchanged |
| 1 | `0x800000` | GFX group C, obj bank 4 | 8 MB | new `GFXC4_OFFSET = 23'h400000` |
| 1 | — | **free** | **0 B** | **bank 1 is EXACTLY FULL** |
| 2 | `0x000000` / `0x800000` | GFX obj banks 0 / 2 | 8 + 8 MB | **unchanged** |
| 3 | `0x000000` / `0x800000` | GFX obj banks 1 / 3 | 8 + 8 MB | **unchanged**; bank 1's bytes are also the scroll slot |

```
  stock GFX (banks 2+3)                            32.000 MB   measured full
  68k PRG, WIDE v1 declared                         6.000 MB
  VRAM + OBJ RAM + work RAM + Z80 windows           0.844 MB
  + the 32 KB alignment gap before PCMH_OFFSET      0.031 MB
  QSound: 8 MB in ba1 + a 1 MB window in ba0        9.000 MB
  GFX group C, obj bank 4 REGION                    8.000 MB
  GFX group C, obj bank 5 REGION                    8.000 MB
  ------------------------------------------------------------
  total reserved                                   63.875 MB
  tier (JTFRAME_SDRAM_LARGE, 4 x 16 MB)            64.000 MB
  slack                                             0.125 MB   ALL of it in bank 0
```

### Why vanilla's 32 MB cannot move, read from the placement code

This is the claim that makes the superset invariant **structural** on MiSTer.
Download: `jtcps1_prom_we.v:141-142` computes
`prog_addr <= … is_gfx ? {gfx_addr[24], gfx_addr[22:1]} + GFX_OFFSET` with
`gfx_bank = { 1'b1, gfx_addr[23] }`, and `GFX_OFFSET` is **not overridden**
at the instantiation, so it keeps its `23'h0` default. Read:
`objgfx_cs = {2{rom0_cs}} & { rom0_bank[0], ~rom0_bank[0] }` with both slots
at `ZERO_OFFSET`. **For every GFX byte below 32 MB — i.e. `gfx_addr[25] == 0`,
which is all of groups A and B by construction, because group C begins at
exactly 32 MB — the bank and the word address are computed by expressions the
profile does not touch.** The only way group C could disturb them is if the
redirect mis-fired, and its condition is `gfx_addr[25]`.

### The two placements that are not obvious

1. **QSound is SPLIT across two banks, on `pcm_addr[23]`.** The stock 8 MB
   stays at bank 1 offset 0 — byte-identical to stock jtcps2 — and DSP sample
   banks `0x80+`, which is precisely the part the profile added, go to bank 0.
   This is not cosmetic. With QSound whole in bank 1, bank 1's spare is
   7.0625 MB against an 8 MB region: **a best-case overflow of 0.9375 MB**,
   and no rearrangement of PRG, Z80 or the RAM windows closes it, because the
   deficit is strictly bank 1's and PCM is the only thing in bank 1. The
   split bit lands exactly on the stock/WIDE boundary, which is a pleasant
   property to have on the superset invariant.
   *(It is also forced from the other side: a jtframe 8-bit SDRAM slot caps
   at `SDRAMW` — §7 — so one region wider than 8 MB was never expressible.)*
2. **Group C's two obj banks are deliberately separated, one per SDRAM
   bank.** Obj bank **4** — the three fighter bands, i.e. the in-match
   traffic — goes to bank **1**, the bank whose headroom was actually
   measured. Obj bank **5** — select/wheel art, cold during a match — goes to
   bank **0**, so its extra load lands on the select screen rather than in a
   match.

### Why bank 1 can take the load

Object graphics and sound samples now share a bank, which sounds like the
kind of decision that ruins frame timing. **It was measured before it was
chosen** (`tests/audit_sdram_bank_load.sh`, stock `vsavj`, 2,800 frames;
figures per video frame, in-match phase, re-derived 14z-107 (7)):

| | ba0 (68k+VRAM+ORAM+WRAM+snd) | ba1 (QSound PCM) | ba2 (obj) | ba3 (obj+scroll) |
|---|---|---|---|---|
| accesses / frame | **40,976** | 13,926 | 1,096 | 18,438 |
| row-miss rate | 100% by construction | **98.3%** | 42.2% | 28.9% |

* **QSound has essentially no row locality.** It round-robins sixteen
  channels at unrelated addresses, so nearly every fetch opens a new row.
  There is no locality in bank 1 for a repack to spoil.
* **Object and scroll traffic does** — 28.9% miss in bank 3. Tile fetches
  come in runs; that is what a repack risks.
* **The headroom is large.** A single bank's all-miss ceiling is **123,825
  transactions per frame** (STW = 13 clocks at 96 MHz). Bank 1's worst case
  is PCM's 13,926 plus *every* object fetch the game makes today
  (1,096 + 18,438 = 19,534) = **33,460, or 27% of the ceiling** — while bank
  0 already sustains **40,976, or 33%**, in stock configuration.
* **The data bus is at 18.5%** of 96 MHz × 16 bit at the busiest measured
  point, and a repack cannot change it: it moves which bank serves a fetch,
  not how many fetches happen.
* Bank arbitration is strictly `ba0 > ba1 > ba2 > ba3` (`BAPRIO=1`), so
  objects moved into bank 1 **gain** priority over the scroll left in bank 3.
  That is a scheduling change, not only a placement change.

**What this bounds and what it does not.** It bounds the *headroom*; it does
not prove the repacked design. **The repacked design's bank-0 half is now
MEASURED, and it is GO** (14z-107 (12), `mister_map.md` open question 1):
`audit_sdram_bank_load --core cps2w --wide` on a BOOTING WIDE image runs bank
0 at **40,717 accesses/frame through the select screen — 32.9% of its 123,825
all-miss ceiling** — 41,535 in-match, whole-run peak 54,363 (43.9%), data bus
16-18%, and **ZERO `SDRAM reads clashed` in 3,500 frames**. The redirect costs
bank 0 about **1,000 accesses/frame, ~2.5%**, against the stock core's 39,696
in the same phase. **Bank 1's half is still UNMEASURED**: that replay picks a
legacy character, so obj bank 4 is never fetched and ba1's 13,890
accesses/frame are the PCM stream alone. The row-thrash risk this instrument
was actually built for — obj fetches interleaving with QSound *inside bank 1*
— needs a tenant in a match, which needs the direction-bit defect in §12
fixed first.

---

## 7. What no amount of memory would fix

Widening SDRAM does not widen the core. **Four caps live in the CPS-2 RTL
itself, and three of them are FORMAT rather than memory.** Each one is a
change CPS-2 WIDE v1 already makes on FBNeo and MAME, so the core is
expressing a ratified profile in a third implementation rather than inventing
anything.

| the cap | why it caps | what the profile does | precedent |
|---|---|---|---|
| **GFX stops at 32 MB** | a 16-bit tile code plus a 2-bit bank taken from the object table's y-word (`st3_bank <= table_y[14:13]`) = 2¹⁸ codes × 128 B | Capcom's own CPS-2 Turbo rule: **after** the end-of-list test, promote y-word bit 12 into bit 15 and read a **3-bit** bank — a 19-bit tile address | `cps2_wide.md` Correction A2; the ratified promote in FBNeo's `Cps2ObjDraw`, mirrored in MAME |
| **program stops at 4 MB** | `rom_cs <= A[23:22] == 2'b00` — flat, with the OBJ config port at `$400000`, QSound at `$600000`, ORAM at `$700000`, I/O at `$800000` above it | a **read-only** decode extending into `$400000-$5FFFFF`; the objcfg port is qualified `&& !RnW`, so there is no read collision | the FBNeo/MAME B3 + B4(prg) steps, both PASS with a firing negative control |
| **samples alias above 8 MB** | `qsnd_addr[22:16] <= dsp_ab[6:0]` keeps seven bank bits, so DSP bank `0x8N` plays as `0x0N` and **mis-plays legacy audio** rather than going silent | latch the eighth bit — `qsnd_addr[23:16] <= dsp_ab[7:0]` | the 14z-86 finding; the bit is `dsp_ab[7]`, **validated** against MAME's low-level QSound device, not assumed |
| **scroll stops at 8 MB** | `rom1_addr[19:0]` → `gfx1_addr = {rom1_addr, rom1_half, 1'b0}` = 22 bits, with `SCR_OFFSET = 0` and **no bank input anywhere in the chain** | nothing — scroll is not part of WIDE v1 and does not need to grow | — |
| **the ENCRYPTED-OPCODE window is fifteen times too wide** (added 14z-107 (11)) | the CPS-2 key's range word is stored **COMPLEMENTED** and `jtcps2_dec_ctrl.v:44` compares against it uncomplemented: `addr[14+:10] <= range[9:0]`. For `vsavj` the word is `0x03C0`, so the core decrypts opcode fetches to `CPU:$F03FFF` where the hardware stops at `$0FFFFF` | complement it, profile-gated, on its way in: `rng_eff = wide_en ? { addr_rng[15:10], ~addr_rng[9:0] } : addr_rng` | MAME and FBNeo already do it — `cps2_crpt.cpp:771` `~decoded[9] & 0x3ff`. This cap is a DEFECT IN THE REFERENCE CORE rather than a hardware format, and it is the only one of the five that is |

**FOUR of those five are now IMPLEMENTED on the core**: the QSound width in
slice D1, the object promote in D3, the program window in D4 and the
decryption range in D5. §10 has the slice records; the rest of this section is
why each one is shaped the way it is, and stays true whether or not it has
shipped.

**THE FIFTH CAP IS THE ONE NOBODY PREDICTED, AND IT IS WORTH THE PARAGRAPH.**
Four of these are FORMAT: the hardware genuinely stops there and Capcom's own
CPS-2 Turbo lifted the same limits. The decryption range is not — it is a
one-token disagreement between the reference core and both emulators, and
**every stock CPS-2 game hides it** because the only code that ever executes is
the code Capcom encrypted, and DATA reads are never decrypted on any
implementation. CPS-2 WIDE is the first thing to put EXECUTABLE content above
the window. It is also why 14z-56's B4 (prg) passed on FBNeo and proved less
than it looked: B4 relocated DATA tables, and data reads bypass the decryptor
everywhere. **Nothing had ever EXECUTED from above 4 MB on a core that
decrypts by address**, and the first time anything did — ten opcode fetches at
`CPU:$4BE7C0`, simulated frame 1119 — the boot lost itself nine frames later.

**Two more constraints that look like memory questions and are not.**

* **A jtframe 8-bit SDRAM slot caps at `SDRAMW`, and past it the build
  fails.** `jtframe_romrq_bcache.v:74` is
  `sdram_addr = offset + { {SDRAMW-AW{1'b0}}, addr_req>>(DW==8) }`, and
  `SDRAMW-AW` is a **replication count** that goes negative at `AW=24`,
  `SDRAMW=23`. Verilator: *"Replication value of < 0 or X/Z not legal"*,
  exit 1 (`AW=24` and `AW=25` both measured). So a byte-addressed slot
  reaches at most 8 MB of a 16 MB bank — which is why §6 splits QSound
  across two banks rather than growing one slot, and why every "just widen
  `PCM_AW`" plan is a build failure rather than a design trade.
  `tests/test_mister_wide_gate.sh` 3d/3e keeps it from being re-proposed.
* **The download image itself has two independent ceilings**, and mapped
  verbatim the WIDE romset overflows both. At 6 + 0.25 + 16 + 48 MB the
  `.rom` is **73,670,720 B (70.26 MB)**, past the 26-bit `ioctl_addr` the
  game port declares (64 MB); and `qsnd_start` would be 71,936 KiB, which
  does not fit the **16-bit** region-start word — **and it is written
  WRAPPED, with no warning**, as 6400, the same value `qsound`'s start
  already has. Trimming the declared-but-empty QSound tail at the MAPPING
  layer brings the image to **66,265,152 B (63.196 MB)** with header words
  6144 / 6400 / 15552 / 64704, all legal. **The trim is mandatory, not an
  optimisation**, and it changes no romset byte: `vsw.22m` is simply not
  mapped and stays in the set for FBNeo and MAME.

```
  tile code path, AS BUILT (slice D3)

    OBJ table y-word          15 14 13 12 | 11 ................ 0
                              T  B1 B0 P  |   y position, 10 bits
                              |  |  |  |
    (1) terminator test ------+  |  |  |     if bit15: end of list  <- FIRST
    (2) promote --------------+<-|--|--+     if bit12: set bit15
    (3) bank = {y12,y14,y13} -----+--+       3 bits, 0..7 (WIDE declares 0..5)

    tile address = bank<<16 | code           19 bits -> 64 MB reach
    byte address = tile address * 128        48 MB declared

    bank 0 -> SDRAM ba2 @ 0x000000  \
    bank 1 -> SDRAM ba3 @ 0x000000   |  vanilla, untouched, computed by
    bank 2 -> SDRAM ba2 @ 0x800000   |  expressions the profile does not reach
    bank 3 -> SDRAM ba3 @ 0x800000  /
    bank 4 -> SDRAM ba1 @ 0x800000  \  group C: gfx_addr[25] selects,
    bank 5 -> SDRAM ba0 @ 0x7E0000  /  gfx_addr[23] picks the bank
```

The promote must come **after** the terminator test, and the order is the
whole of Correction A2: the first draft of the profile proposed widening the
mask to use y-word bit **15** directly, which is the CPS-2 sprite-list
**terminator** — setting it on a sprite ends the list and drops every later
sprite. Capcom hit the same wall on CPS-2 Turbo and solved it by promoting
bit 12 after the check. Vanilla `vsav` never sets bit 12 on a live sprite
(measured across the full legacy corpus, with a control proving the probe was
not blind), so the bit is free and bank values 4 and 5 are ones vanilla
cannot produce.

---

## 8. How the profile is switched on, and why it is a runtime bit

The wide behaviour is selected at **runtime**, from one bit in the MRA
header, and not by an `ifdef` — maintainer's ruling, 2026-08-23. `cps2w`'s
`macros.def` differs from `cps2`'s by `CORENAME` alone, and it stays that
way on purpose: **the WIDE profile is not a macro.**

* **Which byte, and why it is free.** `jtcps1_prom_we.v` consumes header
  bytes 0-7 (the region start words), 8-39 (`is_cps` and the CPS config
  registers) and 40 (`JOY_BYTE`); 44-63 are the CPS-2 key. Bytes **41-43
  fall through every branch of its decoder**, which is what the file's own
  comment ("6 are actually used and 10 are reserved") describes.
  `JTFRAME_HEADER=44`, so byte 41 exists in every CPS-2 `.rom`.
* **Active low, and that is forced rather than chosen.** `mame2mra.toml`
  declares `[header] fill=0xff`, so an unwritten header byte is `0xFF` — and
  the stock `vsavj` MRA emitted by `cps2w` has to stay byte-identical to
  `cps2`'s. Only a polarity in which the fill means "profile off" can do
  that. **Byte 41 bit 0 CLEAR = CPS-2 WIDE**, and the WIDE MRA writes `fe`.
  jtframe's own `JOY_BYTE` has exactly this shape.
* **How the row is scoped.** `RawData` embeds `Selectable`, so
  `{ setname="vsavjw", offset=41, data="fe" }` scores 3 for that set and 0
  for everything else. No other MRA gains a byte. Measured end to end: the
  stock `.rom`'s byte 41 is `0xFF` and the WIDE `.rom`'s is `0xFE`.
* **Where it lands in RTL.** `cores/cps2w/hdl/jtcps2w_profile.v` snoops the
  ioctl stream in the game top and outputs `wide_en`; it re-defaults at the
  first byte of every download, ignores `ioctl_ram`, and is inert for every
  address but 41. It is a *static configuration bit*: written only while the
  ROM streams with the core held in reset, constant for the whole of play,
  and on the same 96 MHz net as everything that consumes it. There is nothing
  to synchronise.

**The consequence is the point.** Stock `vsavj` on **our** RBF runs with the
bit clear, so every gated expression collapses to the reference core's,
character for character. CLAUDE.md rule 1 v2's *"profile-gated so stock
`vsavj` is untouched BY CONSTRUCTION"* is a fact about the circuit on FPGA,
not an inertness argument — exactly as the driver flag makes it one on FBNeo.
**Nine sites are gated as of slice D5**, and `tests/test_mister_wide_gate.sh`
re-reads every one of them verbatim:

| site | where | slice |
|---|---|---|
| `bank <= wide_en ? dsp_ab[7:0] : {1'b0, dsp_ab[6:0]}` | `jtcps2w_qsnd_bank.v` | D1 |
| `is_gfxc  = wide_en & gfx_addr[25]` | `jtcps1_prom_we.v`, download | D2 |
| `is_pcmhi = wide_en & pcm_addr[23]` | `jtcps1_prom_we.v`, download | D2 |
| `pcmh_sel = wide_en & pcm_addr[PCM_AW]` | `jtcps1_sdram.v`, read | D2 |
| `gfxc_sel = wide_en & rom0_bank[2]` | `jtcps1_sdram.v`, read | D2 |
| `bank = { wide_en & table_y[12], table_y[14:13] }` | `jtcps2w_obj_bank.v` | D3 |
| `rom_cs \|= wide_en & RnW & (A[23:21]==3'b010)` | `jtcps2_main.v` | D4 |
| `one_wait` boundary `wide_en ? 4'h6 : 4'h5` | `jtcps2_main.v` | D4 |
| `rng_eff = wide_en ? { addr_rng[15:10], ~addr_rng[9:0] } : addr_rng` | `jtcps2_decrypt.v` | D5 |

**The obj promote is gated at BOTH ends and that is deliberate.** `gfxc_sel`
already ANDs `wide_en`, so an ungated promote would still have been inert —
bank 4 would select the same slot as bank 0. Gating it at the source as well
makes the third bank bit *provably zero* with the profile clear rather than
*harmlessly ignored*, which is the difference between rule 1 v2's "untouched
by construction" and an inertness argument. It also makes the promote
exhaustively testable on its own (§9).

**The one ungated change is declared rather than hidden: the bank-0
re-pack.** `SLOTn_OFFSET` are elaboration-time parameters and cannot switch
at run time, so VRAM/ORAM/WRAM/Z80 move unconditionally on CPS-2. That is a
RELOCATION with no behavioural surface — the 68k sees identical data at
identical 68k addresses, VRAM/ORAM/WRAM are never downloaded at all, the Z80
region's download and read take the same constant, and bank 0 is the one bank
carrying `JTFRAME_BA0_AUTOPRECH=1`, so its per-access latency is
address-independent and no row-locality pattern can shift. It is also the one
D2 claim that is **measured** rather than constructed, by
`tests/test_mister_wide_inert.sh`.

**A second profile gate operates one layer up, in the mapping tool.**
`[parse] sourcefile` is a regex list matched against the machine's source
file, so the WIDE machine entry tagged `sourcefile="capcom/cps2w.cpp"` is
**invisible** to a core declaring `sourcefile=["cps2.cpp"]`. Measured:
`jtframe mra cps2` emits 316 MRAs and none of them is the WIDE set;
`jtframe mra cps2w` emits 8. The reference core cannot even *build* the WIDE
download image — which is how the census gate's leg B was written wrong and
caught on its first run.

---

## 9. How any of this is known to be true

Every claim above is held by an instrument that fails loudly, and every
instrument carries a control that proves it can still fail.

| gate | tier | the claim it holds | its must-fire control |
|---|---|---|---|
| `test_mister_prg_probe` | ci_portable | the 68k program-ROM read probe's contract: it is INERT unless `JTCPS2W_PRGPROBE` is defined; its window bit IS the decode's window bit, both re-read from the RTL; its ADDRESS half carries no chip select, which is what makes it speak on the profile-CLEAR leg; and `tools/prgprobe_verdict.py`'s verdict logic, on synthetic logs whose answer is known by construction | seven: a line hoisted above the guard; and all three answers plus **four refusals** — a silent control, a control whose bytes do not verify, a probe whose HI records sit BELOW `$400000` (the defect the first draft shipped with), and raw-right/latched-wrong, which the first version of the tool scored as a PASS |
| `test_mister_prg_window` | emulator | the measured pair itself, frozen: with the profile ON the 68k completes ten reads above `CPU:$400000` and SDRAM serves 16 words there; with it CLEAR, zero and zero — on `.rom` images that differ in ONE BYTE | the control leg is the must-fire, and the gate additionally REFUSES to conclude anything unless the below-`$400000` count is in the tens of millions and its sampled bytes verify |
| `test_jtcores_twin` | ci_portable | the three reference cores are byte-untouched, the fork's whole-tree delta is 18 declared paths, and the stock `vsavj` MRA from `cps2w` is `cps2`'s except `<rbf>` | the delta list is exact — an undeclared path fails |
| `test_mister_wide_gate` | ci_portable | every gated site, re-read verbatim; the placement constants in BYTES against §6; the gated QSound latch AND the gated obj promote each simulated over **all 65,536 of their inputs in both profile states**; the promote read AFTER a terminator test proven identical to the reference core's; the 3-bit bank asserted at every port between the frame table and SDRAM; the new jtframe module absent from the reference core's file list | six: gate bypassed (D1), byte moved to 40, polarity flipped, a one-width perturbation of an override, the PROMOTE's gate bypassed (D3), and the promote reading `y[15]` instead of `y[12]` — the profile's first draft, which would end the sprite list at the first tenant sprite |
| `test_sim_wram_contract` | ci_portable | the work-RAM dump hook's naming, byte order, skew absorption and rule-7 refusals, and a static proof that every added line sits inside its `#ifdef` | two, plus the fork-rewind ground truth (a parent reading a file while forking `exit()`ing children ends at line 278 of 3,000; with `_exit()`, at 3000) |
| `test_rpl2siminputs` | ci_portable | the replay→`sim_inputs.hex` translator and its loud refusals (P2, buttons 4-6, service-test) | the refusals are asserted to fire |
| `audit_mister_map_fit` | ci_static | the fit itself, the four frozen content extents, and the scramble∘interleave identity §5 rests on | three: the untrimmed image must overflow **both** ceilings; +1 MB of the obj-bank-5 REGION must overflow bank 0; the identity must FAIL with the scramble removed |
| `test_mister_mra_map` | ci_static | the `.rom` is byte-for-byte the map, region by region, against the romset — not recomputed | two: untrimmed → 73,670,720 B and a silently wrapped header word; `length` +0x400 → the frozen table breaks |
| `test_mister_gfxc_fetch` | emulator | **the payoff**: the core ISSUES SDRAM READS into the group-C destinations, with the tile codes inside the roster's frozen live extents. Two legs whose `.rom` files differ by ONE BYTE — header byte 41, `0xFE` vs the `0xFF` fill — so the control is the profile bit itself and nothing else | the control leg must read ZERO from both group-C windows; and two further probes on the VANILLA obj banks must be non-zero **in both legs**, so a zero is evidence about the core and not about the probe |
| `test_mister_sdram_census` | emulator | **all 67,108,864 bytes of all four banks** against §6, on four legs (our core + WIDE image, reference core + WIDE image, our core + stock image, reference core + stock image) | a 1 KiB shift of **any** placement constant is rejected; plus two cross-checks that do not use the tool's model at all |
| `test_mister_wide_inert` | emulator | with the profile bit clear, `cps2w` and `cps2` produce **bit-identical work RAM frame by frame** | the window must be non-constant, and a one-frame shift must fail |
| `test_mister_sim_anchor` | emulator | MAME and the core agree on every mapped gameplay field at the round-1 match-start anchor and at +60/+180, on stock content — MAME 2146 / sim **2609** / skew **+463**, band ±30 | the dump set must be complete and non-constant |
| `audit_sdram_bank_load` | emulator | the per-bank traffic profile §6's viability rests on | zero `SDRAM reads clashed` in 2,800 frames |
| `test_mister_page` | ci_portable | **this document** — every placement offset, the frozen extents, the `.rom` arithmetic and the ASCII figures above are re-derived from `mister_map.md` and the fit gate, and the drawn page is rendered and structurally checked | three: move a placement constant, move a frozen extent, change one ASCII glyph — each must turn `--check` red |

**Two of those instruments have produced a false red, and both times the RTL
was innocent. Neither is history: both are standing warnings.**

1. **The harness's frame writer was rewinding the simulated controller.**
   jtframe's Verilator harness forks a child per *changed* frame; the child
   ended with `exit(0)`; `exit()` runs the C stdio cleanup, which `fclose()`s
   the copy the child inherited of the parent's `sim_inputs.hex` stream; and
   POSIX `fclose()` on a seekable read stream repositions the **shared** file
   description. So the parent re-read lines it had already consumed — **the
   simulated controller was replayed, once per fork.** The number of forks
   follows the *picture*, which is why a core missing `pal_lut.hex` and
   rendering black looked like a timing property of the design. The frozen
   anchor was the artifact and the red one was correct: 2609/463, not
   2502/356. Fixed at the root (`_exit(0)`) and belt-and-braces
   (`JTFRAME_SIM_NOVIDEO`, and `--frame-output off` as the lane's default).
2. **A dump hook kept reading the address where work RAM used to live.**
   `test_mister_wide_inert` reported "cps2w differs from cps2 in 101 of 101
   frames". The hook addresses **SDRAM, not the 68k bus**, and slice D2 moved
   work RAM from `0x600000` to `0x648000` — so the gate was comparing cps2's
   work RAM against cps2w's **VRAM**. It does not announce itself: VRAM is a
   perfectly plausible 64 KB of changing bytes, so the window was
   non-constant and every other assertion passed. **The rule this bought:
   any instrument that names a PHYSICAL address is invalidated by a
   memory-map change, and a placement slice IS a memory-map change.**

A third defect of the same family is worth carrying because it made the
oracle's two legs run **different inputs**: jtframe v1.7.3's `SimInputs`
treated a `[9:0]` **active-low** joystick port as 8-bit in two places, so P1's
buttons 5 and 6 — and all of P2's — were held down from before boot on every
6-button core. It was located at the pin rather than deduced from the source:
a MAME differential found the game's own input mirror at `RAM:$FF8058/5A/5C/5E`,
and the pre-fix simulation's 49-byte block was **byte-identical to the MAME
leg that physically holds P1 and P2 buttons 5+6**. Fixed unconditionally
(`& ~0xf`, `0x3ff`); the anchor was re-measured afterwards and did not move,
because a button held from before boot produces no press edge.

**The standing discipline, then: when a MiSTer measurement disagrees with
expectation, suspect the instrument first and hold the RTL fixed while you
check.** That has now paid three times.

---

## 10. Where the work stands

Each slice is independently verifiable, carries its own gate and its own
must-fire control, and re-runs `test_mister_sim_anchor` on **stock `vsavj`**
as the emulator superset leg.

```
  D0  the MRA          trim the declared-but-empty QSound tail so the image
      no RTL           downloads at all: 70.26 MB -> 63.196 MB          DONE
       |
       v
  D1  QSound width     the RUNTIME profile bit + the 8th bank bit;
      the first RTL    cores/cps2w stops being cfg-only                 DONE
       |
       v
  D2  placement        every region where the map says, checked across
      no fetch moves   all 67,108,864 bytes of the image                DONE
       |
       v
  D3  the promote      the 3-bit obj bank going live — the slice that
      the destination  makes a tenant FETCH possible                    DONE
       |
       v
  D4  the PRG window   the 6 MB read decode, and one_wait with it       DONE
       |               (the decode PROVEN 14z-107 (11): ten fetches
       |                above $400000, raw words byte-perfect)
       v
  D5  the decrypt      the CPS-2 key's RANGE word is stored COMPLEMENTED
      range            and the reference core reads it straight — so
      NOT a format     every opcode the 68k fetched from the extension
                       reached it as the DECRYPTOR'S output             DONE
```

> **D3 AND D4 SHIPPED TOGETHER, AND THE REASON IS A FACT ABOUT THE ROMSET
> RATHER THAN ABOUT THE RTL.** They are separate fork commits and separate
> gates, but D3 cannot be *demonstrated* alone: the select screen's roster
> record is allocated in `wide_ext`, i.e. above `CPU:$400000`
> (`build/manifest/*.toml` `[[select_wheel]] roster21`, `hole = "wide_ext"`;
> `build/m3b_merged13/gen.log` puts `wide_ext` at `0x400010-0x4D1100`). With
> only a 4 MB decode the core cannot READ the table that names the tenant
> cells, so no tenant sprite is ever emitted and the promote has nothing to
> promote. `mister_map.md` §10 had said as much in one line — "only after
> D0–D4 does a WIDE set boot" — and prescribed a synthetic canary for D3
> instead. The canary was not needed once D4 was in: the real romset is the
> better witness.

| slice | scope | what proves it | status |
|---|---|---|---|
| **D0** | `mame2mra.toml`: the `qsoundw` trim region and the `cps2w.cpp` sourcefile opt-in; the `vsavjw` entry in `doc/mame.xml`. No RTL | the `.rom` is 66,265,152 B with header words 6144 / 6400 / 15552 / 64704, every region byte-for-byte the romset's | **DONE**, fork `38acc638` |
| **D1** | the QSound sample-bank width, runtime-gated: `jtcps2w_profile.v` + `jtcps2w_qsnd_bank.v`, plus overrides of the two shared files they need. `PCM_AW` **stays 23** | the gated latch over all 65,536 `dsp_ab` values in both profile states | **DONE**, fork `4840df8a` |
| **D2** | the bank-0 re-pack, the group-C redirect, the QSound split, two new slot counts, and `jtframe_ram1_7slots.v` — bank 0 needs seven streams and upstream's family stops at five | the whole-image SDRAM census, four legs | **DONE**, fork `0df6f000` |
| **D3** | the obj promote, lifted into `jtcps2w_obj_bank.v` and read in the ELSE arm of the terminator test; the bank widened to 3 bits across four override files; `rom0_bank[2]` untied | the expression over its WHOLE input space — 131,072 vectors, both profile states, bank[2] set 32,768 times wide and **0** stock, plus the six `gfx_tiles.py` encodings each decoding to their own bank with none of them setting y bit 15. Two must-fire controls: the gate bypassed, and bit 2 read from `y[15]` | **DONE**, fork `b9899fa8` |
| **D4** | the PRG window: `rom_cs` / `rom_addr` / `one_wait` gated on `wide_en`, `main_rom_addr` and `SLOT3_AW` 22 | **the 68k program-ROM read probe, on the real romset** (14z-107 (11)): ten fetches at `CPU:$4BE7C0-$4BE7C8`, every RAW word the `.rom`'s byte for byte, against 54,961,148 reads below `$400000` as the must-fire control and a `wide_en`-clear leg that completes zero | **DONE**, fork `dd242a65`; the decode PROVEN 14z-107 (11) |
| **D5** | the decryption range: `jtcps2_decrypt.v` complements the key's range word on its way into `jtcps2_dec_ctrl`, gated on `wide_en`. `jtcps2_dec_ctrl` itself untouched, and `dec_en` still comes from the uncomplemented word | the same probe: all ten of those fetches reached the CPU as the decryptor's output rather than as memory's, and all ten carry `fc = 2` — an OPCODE fetch, which is exactly what `jtcps2_dec_ctrl` gates on | **DONE**, fork `c00d7ce7` |

**What D2 deliberately left stubbed, and D3 unstubbed.** `rom0_bank` was
three bits at the `jtcps1_sdram` port with the game top driving
`{1'b0, rom0_bank}`, so `gfxc_sel` was constant 0 and the two group-C read
slots were provably unreachable — which is why D2's evidence is an image
census and not a replay. D3 removes the tie and drives the bank from the
object engine, so the slots are reachable and the profile is complete.

> **AND THE END-TO-END DEMONSTRATION WAS MISSING FOR A REASON THAT IS NOT
> D3's — AND 14z-107 (11) NAMED IT.** The paragraph below is the state before
> slice D5; read it for the eliminations, which stand, and then read
> `docs/platform/mister.md` "CAN THE 68k READ ABOVE 4 MB?" for the cause.
> **One correction to it in place: the two profile states are NOT
> frame-for-frame identical.** They are identical in bank-3 traffic and in
> masked work RAM, which is what was measured — but the profile-ON leg issues
> **ten** completed program-ROM reads above `CPU:$400000` and the
> profile-CLEAR leg **zero**, and the SDRAM read probe on the same window
> counts 16 word reads against 0. The instrument that said "identical" could
> not see the window it was being asked about.
>
> **AND THE END-TO-END DEMONSTRATION IS STILL MISSING, FOR A REASON THAT IS
> NOT D3's.** With every slice in, the WIDE romset does not get past its own
> boot sequence on the core: the CPS-2 RAM test draws, the QSound/Capcom legal
> screen stands for ~660 frames, and the machine RESETS and starts over — a
> ~1,580-frame cycle. **No sprite is drawn at all** — the SDRAM read probe
> counts zero reads in vanilla obj bank 2 as well as in both group-C windows —
> so no tenant tile has been fetched on any core, ever. The same run with the
> profile bit CLEAR is frame-for-frame identical, which eliminates all eight
> gated sites; the whole-image census passes on the same image and core, which
> eliminates the download; and MAME on the same romset and replay reaches the
> select screen. `docs/platform/mister.md` "THE WIDE ROMSET DOES NOT BOOT ON
> THE CORE YET" carries the trace, the eliminations and the next probe. **This
> is the first thing to fix, and it is a bug hunt rather than a slice.**

**Two findings recorded while reading, not acted on.** The wait-state line
`jtcps2_main.v:167` gives `A[23:20] < 4'h5` one wait state, so the second
megabyte of the PRG extension would run at a *different* bus timing from
every other byte of program ROM — the gated `4'h6` must ship in the same
slice as the decode. And MAME's low-level QSound models a **one-read bank
latency** that jtcps15 does not; that is a difference in the *reference*
core, unchanged by the width fix, and a question for the audio comparison
rather than a D1 edit.

---

## 11. What would break it

* **A fourth graphics group, or any growth of the declared group-C region.**
  Bank 1 has **zero** free and bank 0 has **131,072 B**. A fifth group-C
  member, or widening the region past 16 MB, overflows immediately and there
  is nowhere for the excess to go. Note the asymmetry §5 sets up: art may
  grow freely *inside* the existing 16 MB — a code above `0xEE73` or `0xFFDB`
  costs nothing — but `audit_mister_map_fit` will still go RED, because those
  extents are FROZEN and a moved extent has to be re-derived and re-frozen
  deliberately rather than absorbed.
* **A re-freeze of the romset.** `jtframe`'s `mra2rom` locates every zip
  member **by CRC32 and by nothing else** — the `name` attribute appears only
  in the warning text. FBNeo and MAME resolve by name and merely warn on a
  hash mismatch, which is why the WIDE members carry sentinel CRCs in both
  drivers and why content there can change freely. **On MiSTer a sentinel is
  not a warning: it is "cannot find file … in zip" and no `.rom` at all.** So
  the MiSTer leg is pinned to the exact bytes of one romset build, and a
  rebuild that moves one CRC must move the fork's catalogue entry and the
  `parts=` row with it. `tools/gen_vsavjw_xml.py` regenerates the entry and
  `test_mister_mra_map` fails if it is stale.
* **A regeneration of jtframe's machine catalogue.** `doc/mame.xml` is a
  *generated* file upstream (`jtframe mra --reduce`), so an uprev or a
  regeneration can drop the `vsavjw` entry we added. Nothing warns; the MRA
  simply stops being emitted. `test_mister_mra_map` says so loudly.
* **An upstream uprev.** Everything here is measured against one pinned
  version. `hdl/ver/test.cpp` is split and moved, `jtframe_emu.sv` moved,
  `bin/jtsim` rewritten, `game.yaml` → `files.yaml` with a changed schema,
  `mraauthor` → `author`, input bit 1 changed from coin2 to service, and
  `-inputs` now takes a `.cab` cabinet script — which orphans
  `sim_inputs.hex`, `tools/rpl2siminputs.py`, `tools/run_sim_jtcps2.sh`, one
  fork commit and both simulation gates. The inlined-yaml transcriptions of
  §1 are re-paid by hand on the same day.
* **Setting `JTFRAME_SDRAM_XL` without the cache lanes.** It compiles, it
  validates, and it silently produces a map that drops `addr[9]`. §4.

---

## 12. The holes — what has never been tried

**A map that hides its gaps is worse than no map.** §9 lists the instruments
and what each one holds; this section lists what NOTHING holds. It exists
because its absence cost a session: D3's demonstration was planned from §9 and
§10 on the reasonable-looking assumption that the lane was proven end to end,
and it was not — **nothing had ever run the WIDE image past the ROM download.**
Read this section before planning any measurement, and add to it whenever a
slice reveals a new hole.

| what | status |
|---|---|
| **The WIDE romset booting on the core** | **ROOT-CAUSED AND FIXED 14z-107 (11), SLICE D5 — the WIDE romset now boots to the select screen.** The 68k EXECUTES from the program extension (ten opcode fetches at `CPU:$4BE7C0-$4BE7C8`, simulated frame 1119) and receives the CPS-2 DECRYPTOR'S OUTPUT, because the key's range word is stored complemented and `jtcps2_dec_ctrl` reads it straight. The eliminations from 14z-107 (10) all stand and none of them covered this: they were measured on bank-3 traffic and masked work RAM, neither of which can see ten reads in a 2 MB window. **One of them is CORRECTED in place: the two profile states are not frame-for-frame identical** — ten completed reads above `$400000` against zero. |
| **A tenant sprite FETCHED on the core** | **BOTH HALVES HAPPENED — the wheel 14z-107 (11), THE FIGHTER 14z-108.** With the input path fixed, `36_pick_tenant_cell` on `cps2w` + the WIDE romset over 4,400 frames: **obj bank 4 (the FIGHTER art) 9,388,928 reads over 1,735 distinct tile codes `0xAD8F-0xEE42`, first at frame 1781**, and obj bank 5 (the wheel) 19,246,336 reads over 206 codes `0x74D6-0xFE41`, first at 1556. Every code inside its frozen live extent (`0xEE73` / `0xFFDB`). The control leg — the SAME image with header byte 41 `0xFE`->`0xFF` — reads **0** from both windows while still issuing 105,418,104 reads in bank 3, so the zero is about the profile and not about the probe. `tests/test_mister_gfxc_fetch.sh` PASSES in full. |
| **A tenant sprite DRAWN, and checked as a picture** | **DRAWN 14z-107 (12) — NOT CHECKED.** The core renders the EXTENDED SELECT WHEEL, tenant cells and the authored "M6" mark included: `docs/project/images/mister_select_cps2w_f2400.jpg` is the first picture of this project's own content produced by an FPGA implementation, and `mister_select_mame_f1741.png` is MAME's frame of the same screen beside it. **They are a naked-eye pair, not a verdict** — nothing compares them programmatically, there is no golden and no gate, and the cursor sits on a DIFFERENT cell in each because of the direction-bit defect two rows down. Every cross-implementation verdict in this lane is still work-RAM fields at a sync anchor. |
| ~~**Bank 0's traffic under the redirect**~~ **OUT OF THIS LIST** | **ANSWERED 14z-107 (12), and it is GO — kept here struck so the question's provenance stays findable.** `audit_sdram_bank_load --core cps2w --wide` on a BOOTING WIDE image (`05_timeout_idle`, 3,500 frames, transfer asserted at 659, the run's own anchor at **2806** = the frozen 2609 + the 197-frame transfer difference, so the phase boundaries are checked rather than assumed): bank 0 runs **40,717 accesses/frame through the select screen** and 41,535 in-match — **32.9% of its 123,825 all-miss ceiling**, whole-run peak 54,363 (43.9%), data bus 16-18%, and **ZERO `SDRAM reads clashed` in 3,500 frames**. The redirect costs bank 0 about **1,000 accesses/frame (~2.5%)** against the stock baseline. `mister_map.md` §9 open question 1. |
| ~~**Bank 1's group-C half under load**~~ **ANSWERED 14z-108, AND IT IS GO** | Struck, kept so the question's provenance stays findable. The 14z-108 tenant-match run carries `--stats`, so the fetch gate's own positive leg answers this: over 3,738 post-transfer frames **ba1 runs at 11,905 accesses/frame with a peak of 15,496 — 12.5% of its ceiling — and there are ZERO `SDRAM reads clashed` warnings.** The 14z-107 (12) run put ba1 at 13,890/frame with PCM ALONE because it picked Demitri; the tenant's fighter art now shares the bank and adds ~1,600 accesses/frame at peak without contending. ba0 peaks at 54,363 (43.9%), unchanged from the stock figure. **The repack's bank-1 half is GO on measurement.** Caveat stated: ONE replay, ONE tenant, one opponent. |
| **A tenant SELECTED on the core** | **HAPPENED 14z-108.** The block was the harness, not the RTL: the simulator's direction bits were REVERSED end for end (measured on all four against the game's own `RAM:$FF8058.w` mirror, `tests/replays/107_four_directions.rpl`), so the tenant-picking replay walked the cursor onto Victor. Fixed in `tools/rpl2siminputs.py`; MAME confirms the same replay reaches P1 `+0x382 = 0x13` — the tenant's native vs2 id — with the match live from replay frame ~2900. |
| **A tenant FIGHTING on the core** | **HAPPENED 14z-108, and it is the thing the whole arc was after.** Obj bank 4 carries traffic in **843 frames AFTER match start**, continuing to the replay's last frame. The two group-C probes behave according to their CONTENT, which is stronger evidence than either count alone: the wheel art stops at the select/VS boundary (last frame 3498) and the fighter art runs through the match. Everything below it in the stack is proven — the promote (D3), the program window (D4), the decryption range (D5), the placement (D2) and the download (D0). **Still never: on HARDWARE.** |
| **The QSound extension FETCHED** | **HAPPENED 14z-108.** `108_tenant_voice.rpl`, `cps2w` + the WIDE romset: **210,180 reads over 76 distinct blocks in the 1 MB QSound HIGH window**, first at frame 3783 (224 frames into the match, during the mash), addresses `0x830AA0-0x83FFFE` = **DSP bank `0x83`**, inside the ledger's `0x80-0x8E` and overlapping 8 of its 58 samples. **Control leg (same image, header byte 41 `0xFE`->`0xFF`) reads ZERO while still issuing 54,113,994 QSound LOW reads**, so the zero is about the profile and not a silent DSP. Confirms D1's width fix and D2's split end to end, and that the `SLOT5_AW=20` mask is lossless in practice (`pcm_addr[22:20] == 0` throughout — Quartus warning 10230). Gate: `tests/test_mister_qsound_ext.sh`. **Still NOT 'heard': no audio has been rendered or compared. Fetched is not heard.** |
| **The scroll path with a wide GFX map** | **STRUCTURALLY CLEARED 14z-108; RENDERING STILL UNTESTED.** Scroll is capped at 8 MB with no bank input anywhere in its chain (§7) — `rom1_addr` is `[19:0]` and `gfx1_addr = {rom1_addr, rom1_half, 1'b0}` is 22 bits. **D2 did not touch that chain:** every scroll-path line in `cps2w`'s `jtcps1_sdram.v` override (`SCR_OFFSET = 23'h00_0000`, `rom1_cs`, `rom1_addr`, `gfx1_addr`, the `slot1_*` bindings) is byte-identical to the shared `cores/cps1` original, and the scroll slot still sits in `u_bank2` and `u_bank3` in BOTH. The only slot1 the fork adds anywhere is `gfxc4_cs` on `u_bank1` — a DIFFERENT bank. So the repack cannot have moved scroll by construction. **What is still untested is RENDERING**: no scroll layer has been compared against MAME's, and bank 3's 171 M reads / 6,169 distinct blocks per run are healthy traffic but not a correctness check. |
| **Video compared against MAME** | **FIRST COMPARISON MADE 14z-108, on the DATA rather than the pixels.** VRAM `$900000-$93FFFF` (palette + scroll tilemaps — what DETERMINES the frame) dumped from both at the frozen anchors: **the CPS-A/CPS-B video registers were documented the same session** (`atlas/ram.md`, "CPS-2 VIDEO REGISTERS") and the diff re-cut along the real layer map: **scroll1 22.3% differing, scroll3 2.9%, scroll2 17.7%, and the PALETTE 52.7%** — with `layer_control 0x2d0e`, i.e. **all three scroll layers ENABLED**. Row-scroll and every UNCLAIMED region (204,800 bytes, and not zero) are byte-identical. **An earlier reading of this that called the identical 128 KB "scroll tilemap" was WRONG — no layer base points there; it is unclaimed VRAM.** So the differences are in LIVE surfaces. **THE LEGACY CONTROL SETTLES IT: NOT OURS.** The same comparison on STOCK `vsavj` with the legacy replay `05_timeout_idle` gives the SAME pattern and magnitudes (scroll1 35.4%, scroll3 3.8%, scroll2 15.1%, palette 51.2%, row-scroll and unclaimed 0%) — on vanilla content, with the roster nowhere in sight. So this is a GENERAL MAME-vs-jtcps2 implementation difference and says nothing about the profile. **The useful negative result: VRAM is NOT a viable cross-implementation video oracle** — two unrelated implementations legitimately differ there, the palette by half, so the surface cannot distinguish a port defect from an implementation difference. A future video oracle needs rendered frames, the OBJ list, or the post-conversion palette. Row-scroll and all unclaimed VRAM are byte-identical in BOTH runs, so the transfer and dump paths are sound. PIXELS are still never compared, and **the two committed select-screen images do not change that.** **AND THE SUCCESSOR SURFACE WAS FOUND AND IT AGREES — 14z-109, THE OBJ LIST.** That row above names "the OBJ list" as a candidate; it was tried and it WORKS, because the OBJ list is what the 68k BUILDS rather than something each implementation stages its own way. ORAM is dumpable on both (MAME by address; the core because D2 maps it to SDRAM bank 0 byte `0x640000`), and `tools/oram_obj_records.py` walks it into the same records `tests/lua/obj_records_dump.lua` prints from the live machine — **byte for byte, 1153/1153 lines, verified before any core data was read**. **THE TRAP, AND IT IS NOT VRAM'S:** a 1P replay's CPU opponent is the SOUND-STATE-FED LOTTERY (`atlas/ram.md:99`), so the two legs fight DIFFERENT opponents and the raw lists cannot be compared whole — at the tenant anchor the totals are 40 vs 129. An OBJ list cannot be filtered "by P2" the way `fields_m2a.tsv` is, because sprites carry no owner. **BUT OUR OWN CONTENT IS LABELLED: y bit 12, the CPS-2 Turbo promote (slice D3), is set on exactly the group-C sprites this port adds and on nothing vanilla can emit.** **RESULT AT THE FROZEN TENANT ANCHOR (MAME 2886 / sim 3546): the promoted subset is 31 entries on BOTH legs, ORDERED AND FIELD-FOR-FIELD IDENTICAL, and the 19-bit tile addresses slice D3 computes are the SAME SET, `0x4b0c4-0x4ecda`.** That is the first cross-implementation agreement this project has on a video-determining surface, and it is on the content the port exists to add — the promote, the group-C redirect and the 3-bit bank, confirmed end to end against an unrelated codebase. The unpromoted remainder (9 vs 98) is the lottery and is REPORTED, never asserted. Gate: `tests/test_mister_obj_oracle.sh`. **Still not pixels: this is the sprite LIST, not the rendered frame.** |
| **SYNTHESIS — does it FIT** | **ANSWERED 14z-108: YES, and comfortably.** Quartus Prime 20.1.1 Lite (Jotego's `jotego/jtcore20x` image), Cyclone V **5CSEBA6U23I7**, target mister, pin `7b9a0d2d`, with **`cps2` built FIRST as the reference leg** so the figures are an attribution. `cps2w` costs **+206 ALMs (+1.1%, 44% -> 44% of 41,910)** and **+2,048 block-memory bits**; RAM blocks, DSP blocks and PLLs all UNCHANGED. **SDRAM 96 MHz domain, slow corner (1100 mV / 100 C — industrial grade, MORE conservative than the 85 C originally specified): `cps2` +0.144 ns / 97.35 MHz, `cps2w` +0.066 ns / 96.62 MHz.** Zero failing paths, TNS 0.000 every domain, 0 fitter errors and 0 critical warnings, `.rbf` produced for both. **TIMING IS A SEPARATE ROW NOW, AND IT IS NOT A PASS — see below.** The single-seed +0.066 ns reading here is a true report of ONE draw and is superseded as a claim about the design. **ATTRIBUTED (14z-108, `report_timing` against the fitted netlist): the cost is NOT in any slice.** All ten top paths on both cores live in `jtframe_sdram64` — jtframe's own SDRAM controller, SHARED with the control and UNTOUCHED by the fork; `jtcps2w_obj_bank`, `jtcps2_main`, `jtcps2_decrypt`, `jtcps2w_profile` and `jtcps2w_qsnd_bank` appear in NONE of them. Worst path is the same pin, cell and site in both (`sdram_a[11]` via `DDIOOUTCELL_X62_Y0_N10`); WIDE adds ONE combinational level and the dominant ~4.22 ns term is UNCHANGED — a single interconnect hop to the I/O column, 39% of the path, routing rather than logic. **AND THE DISTRIBUTION IS THE REAL RESULT: the control's margin is held by ONE path with a 0.27 ns gap behind it (0.144 | 0.418 …), while `cps2w` has FIVE bank-arbitration paths inside 0.065 ns (0.066 0.079 0.103 0.112 0.131). WIDE pulled a whole front down together rather than shifting one path** — five chances to go negative where the control has one, on a term that is routing and therefore seed-dependent. A FITTER SEED SWEEP is the indicated follow-up; single-seed slack is least informative in exactly this configuration. Artifact: `release/mister/jtcps2w.rbf`, 3,111,944 B, sha256 `46fc74af…`. |
| **SYNTHESIS — does it CLOSE TIMING** | **NO, NOT RELIABLY (14z-108 seed sweep, n=12).** `cps2w` twelve seeds span **-0.545..+0.396 with FOUR FAILING**, median **+0.038**; `cps2` five seeds span **+0.144..+0.665 with NONE failing**, median **+0.431**. The BEST cps2w seed is worse than the MEDIAN cps2 seed, cps2's WORST beats eight of twelve cps2w seeds, and two cps2w "passes" clear by under **10 picoseconds**. Failure rate 4/12, 95% CI ~14-61% — say "commonly", not "a third". The FAILs are **jtframe's own timing gate** on runs Quartus reported as "Full Compilation successful, 0 errors". **`xjtcore.sh` calls `jtseed 4`, which retries and BREAKS ON FIRST SUCCESS — and be precise about what that hides: NOT correctness (~99% of invocations produce a passing `.rbf`) but FRAGILITY. A green run certifies "one placement was found that closes", never "this design closes with margin".** Every failing path is in `jtframe_sdram64` at an SDRAM address pin and RESHUFFLES between seeds: the marginal thing is that controller's ADDRESS-GENERATION CONE as a whole, shared infrastructure the fork does not touch — **not WIDE's own logic**. Never verdict (b): the control closed on every seed tried. Does not block shipping (we distribute a prebuilt `.rbf` and the baseline is a passing draw) but **+0.066 is not headroom a future slice may assume**. **A FAILING SEED STILL EMITS AN `.rbf`** — verify the hash before flashing. |
| **Any of this on HARDWARE** | never — **and synthesis does not change this**. An `.rbf` exists (14z-108) but nothing has been loaded onto a DE10-Nano, no MRA has run on real silicon, and no analog output has been seen. The MiSTer field test is the ruling's second half and has not begun.
| **The rest of the CPS-2 library under D5's range fix** | untested and deliberately unreached: D5 is profile-gated, so `wide_en` clear leaves `jtcps2_dec_ctrl` fed the same word the reference core feeds it. Whether the reference core's uncomplemented comparison breaks any OTHER CPS-2 game is an upstream question this project has not asked. |
| **The 68k EXECUTING from the extension after D5** | the probe proves the ten fetches happen and that the raw words are right; what it cannot say is whether the code at `CPU:$4BE7C0` then does the right thing. That needs the boot to survive it. |
| **That real CPS-2 silicon decrypts only the first 1 MB** | **INFERRED, never measured.** D5 rests on it: MAME (`~decoded[9] & 0x3ff`) and FBNeo (`cps2_crpt.cpp:771`) complement the key's range word, jtcps2 does not, and for `vsavj` the two readings give `$000000-$0FFFFF` versus `$000000-$F03FFF`. The complemented reading is almost certainly the hardware's — it yields exactly 1 MB, a plausible designed boundary, where the other sweeps regions that are not program ROM at all — and the CPS-2 cipher was reverse-engineered against real boards. But **this project has not measured silicon**, and both emulators share that research's heritage, so they are not two independent witnesses. **Why it matters beyond MiSTer:** WIDE puts EXECUTABLE code above the window, so a real CPS-2 board must also leave that region undecrypted for the roster to run on hardware. If the silicon ever proved to behave as jtcps2 does, the profile would be depending on behaviour real CPS-2 lacks. Framing note (maintainer, 2026-08-24): jtcps2's reading is best called a latent implementation divergence, not a defect — no software in thirty years created the condition that exposes it. |
| **The 128 MB module's chip select** | the XL fallback (§4) assumes the module inverts chip 1's `/CS`. That is INFERRED from jtframe's RTL, never seen on a schematic. If XL is ever taken, confirm which module is in hand first. |
| **The three ungated width changes** | declared inert and measured so by `test_mister_wide_inert` — but only on STOCK content, which is the only content that currently boots. |

## Where to go from here

| if you want | read |
|---|---|
| the provenance of any figure above | `docs/platform/mister.md` — the platform log, with every retraction still visible |
| the placement's derivations, open questions and slice plan | `docs/project/mister_map.md` |
| what the roster demands, region by region, and how it was measured | `docs/project/mister_fit.md` |
| the profile itself, in all three implementations | `docs/project/cps2_wide.md` |
| the traps this arc has already paid for | `docs/platform/gotchas.md`, `docs/project/gotchas.md` |
| the drawn version of §5, §6, §7 and §10 | `python3 tools/mk_mister_page.py` — a standalone HTML page. **Generated, never committed**: a hand-copied artifact goes stale silently, and this one draws a map whose slack is 0.2% of the tier. `--check` re-derives everything it draws, and `tests/test_mister_page.sh` runs that on every `tests/run_all_static.sh` |
