# MiSTer SDRAM placement map — the WIDE v1 romset on jtcps2w @ `v1.7.3`

Design + measurement, 14z-107 (4). **No RTL was written for this document.**
Every figure names its instrument; every RTL claim names `file:line` in the
pinned submodule `emu/jtcores` (jotego/jtcores `v1.7.3` + our fork commits,
pin `74ed17d`). Platform facts live in `docs/platform/mister.md`; the
region-by-region content measurements live in `docs/project/mister_fit.md`;
the profile itself is `docs/project/cps2_wide.md`.

**Verdict up front: IT FITS — with 0.708 MB of slack in 64 MB, and only if
four things hold at once.** It does not fit the way the route was framed.
See §1 for the correction, §5 for the map, §9 for what is still open.

---

## 0. The one-paragraph answer

The MiSTer download image (`.rom`) is built from the SAME romset by the MRA
alone — `jtframe mra` can emit a **partial** zip member (`offset=`/`length=`
on a `<part>`), so the declared-but-empty tail of the 16 MB QSound region can
be trimmed at the MAPPING layer without touching the romset (§2). That trim
is **not an optimisation, it is mandatory**: mapped verbatim the WIDE `.rom`
is 70.26 MB, which overflows both the 26-bit `ioctl_addr` the game port
declares and the 16-bit region-start word in the header (§3). With QSound
placed at 8.9375 MB the image is 63.2 MB and every header word is legal.
Vanilla's 32 MB of GFX then stays byte-for-byte in SDRAM banks 2+3 **by
construction** (§4), and the ~15.4 MB of tenant art splits one obj bank per
bank into the spare of banks 0 and 1 — which requires moving the QSound
extension (DSP sample banks `0x80+`) out of bank 1 and into bank 0 (§5).

---

## 1. THE CORRECTION THAT DECIDES THE DESIGN: 6.39 MB is not the footprint

The route was framed as "6.39 MB of group-C tenant art into bank 1's ~7.1 MB
of spare". **That does not work, and the reason is not throughput.**

`6.39 MB` (mister_fit §3) is the count of tenant tiles that carry content —
a LIVE-BYTE figure. What SDRAM has to reserve is the **address footprint**,
and on CPS-2 a tile code IS its address:

- `cores/cps1/hdl/jtcps1_prom_we.v:105` applies the CPS-2 GFX address
  scramble `gfx_addr = { gfx_addr[25:21], gfx_addr[3], gfx_addr[20:4],
  gfx_addr[2:0] }` at download time. Composed with the `.rom`'s 4-way
  64-bit interleave (`[rom] { name="gfx", width=64 }`,
  `cores/cps2/cfg/mame2mra.toml:105`), the scramble **undoes the
  interleave**: the SDRAM address of tile code `c` is exactly
  `c * 128 + (byte within tile)`, contiguous and monotonic in `c`.
- **Proven, not argued:** for all 131,072 tiles of a 16 MB group, the set of
  SDRAM byte addresses the download writes for tile `t` is exactly
  `[t*128, t*128+128)`. (Forward check: take the four member byte-slices
  `tools/gfx_tiles.py:112 tile_bytes()` reads, map each back to its `.rom`
  linear address through `ROMX_LOAD GROUPWORD|SKIP(6)`, apply the scramble.
  Zero mismatches. `tests/audit_mister_map_fit.sh` re-checks a 2,163-code
  sample plus the boundary codes, with a control that fails the check when
  the scramble is removed.)
- Verified, not asserted: re-deriving the tile→member mapping the naive way
  and running vanilla's blank-tile census gave 978/722/775/977; running it
  through the project's canonical `tools/gfx_tiles.py:112 tile_bytes()`
  gave **418 / 2917 / 51 / 642** — the exact figures `mister_fit.md` §3
  froze. The canonical mapping is the right one and my first derivation was
  wrong. (Instrument: `tools/gfx_tiles.py` over pristine `$ROMDIR/vsav.zip`.)

So the footprint is set by the HIGHEST tile code the roster uses, not by how
many codes it uses. Measured on the shipped merged build
(`build/m3b_merged13/rompath/vsavjw.zip`, group C members
`vsw.31m/33m/35m/37m`):

| group C obj bank | non-blank codes | highest **non-blank** code | highest code in the **manifests** | address footprint |
|---|---|---|---|---|
| 4 (fighter bands, effects, strips) | 45,736 | `0xEE73` | `0xEE73` (`patch/effect_map.json`) | `0xEE74 × 128` = **`0x773A00`** = 7.452 MB |
| 5 (select/wheel art, ported effects) | 6,245 | `0xFE41` | `0xFFDB` (`patch/effect_c5.*.json`) | `0xFFDC × 128` = **`0x7FEE00`** = 7.995 MB |
| | | | **total** | **15.45 MB** |

`0xEE73` is not a coincidence — it is exactly the top of Donovan's frozen
band+shelf in the ratified group-C layout (`cps2_wide.md` "Group C 3-tenant
layout"). The art is *sparse within* 15.45 MB of address space; it cannot be
compacted without renumbering tile codes, which is game data.

**Consequence: the tenant art needs 15.45 MB of SDRAM, not 6.39 MB, and no
single bank has that. It must be split, one obj bank per SDRAM bank.**

---

## 2. Can the same romset be mapped differently on MiSTer? — YES, from the code

The maintainer's ruling is ONE profile and ONE romset across FBNeo / MAME /
MiSTer. A solution that changes the romset breaks it; a solution that changes
only the MRA honours it. Read from
`emu/jtcores/modules/jtframe/src/jtframe/mra/`:

- **The `.mra` is the only source of truth.** `mra2rom.go` re-reads the XML
  tree the generator built and materialises the `.rom` from the zips; the
  reader honours exactly `index, zip, name, crc, repeat, offset, length,
  map, output` and **locates each member by CRC32, not by name**
  (`mra2rom.go:163-172`).
- **Partial members are supported.** `mra2rom.go:177-196` implements a byte
  window: `offset` = first byte inside the member, `length` = byte count
  (clamped to the member size; absent ⇒ "rest of file"). No alignment
  constraint. It works identically inside `<interleave>`.
- **Five TOML routes reach it.** The general one is `parts=[{name, crc, map,
  length, offset}]` (`types.go:114-117`, emitted by `corerom.go:462-479`),
  which bypasses MAME's file list entirely; it is already used in-tree to
  map the SAME file twice at two offsets (`cores/cps1/cfg/mame2mra.toml:165-173`,
  Pang!3). `splits`, `singleton`, the automatic interleave chunker and
  `rom_len` are the other four.
- **Region configs are per-setname.** `RegCfg` embeds `Selectable`
  (`types.go:83`) and `find_region_cfg` (`corerom.go:390-412`) scores
  setname 3 / cloneof 2 / generic 1 — so a `{ name="qsound", setname="vsavjw",
  parts=[…] }` row changes the WIDE set's mapping and leaves stock `vsavj`
  byte-identical.
- **Padding is `0xFF`, from `<part repeat="0xN"> FF</part>`**
  (`corerom.go:376-388`). There is no zero-fill option for ROM regions.
- **The header words follow the layout automatically.** `[header]
  offset={bits=10, regions=[…], reverse=true}` writes, for each named region,
  `start >> 10` as a big-endian 16-bit word byte-swapped by `reverse`
  (`corerom.go:174-183, 200-256`). `bits=10` ⇒ 1 KiB units, which is exactly
  what `jtcps1_prom_we.v:83-85` reconstructs with `{ snd_start, 10'd0 }`.
- **`rom_len` must NOT be used to shrink.** `corerom.go:562-577` advances
  `pos` by the full file size regardless, so a shrinking `rom_len`
  desynchronises every later header word from the real `.rom`. Shortening is
  `parts=` or `splits`.

> **The trap underneath the header, recorded so it is not re-learned.** The
> Go generator's `pos` counts the 20-byte `key` region, while the RTL's
> `bulk_addr` starts *after* it (`FULL_HEADER = 26'd64` = 44 header + 20 key,
> `jtcps1_prom_we.v:58`). The two agree **only because every region start is
> 1 KiB-aligned and 20 < 1024.** Any CPS-2 region start that is not a
> multiple of 1 KiB silently puts the header word off by one KiB block. Every
> length in §3 is therefore a multiple of 1024, deliberately.

**Answer: yes. Trimming declared-but-empty tails is a mapping-layer change,
expressible in `cores/cps2w/cfg/mame2mra.toml` against `setname="vsavjw"`,
and the romset is untouched.**

---

## 3. The `.rom` image, and why the trim is MANDATORY

`order` for CPS-2 is `key, maincpu, audiocpu, qsound, gfx, firmware`
(`cores/cps2/cfg/mame2mra.toml:111-117`); `JTFRAME_HEADER=44`
(`cores/cps2/cfg/macros.def`).

### Mapped verbatim (WIDE v1 declared sizes) — TWO INDEPENDENT OVERFLOWS

| region | declared | start as RTL `bulk_addr` (= `ioctl_addr - 64`) |
|---|---|---|
| header + key | 44 + 20 B | consumed before `bulk_addr` starts (`FULL_HEADER = 26'd64`) |
| maincpu | 6 MB | 0 |
| audiocpu | 256 KB | 6,291,456 |
| qsound | **16 MB** | 6,553,600 |
| gfx | 48 MB | 23,330,816 |
| firmware | 8 KB | **73,662,464** |
| | **total 70.26 MB** | |

1. `modules/jtframe/hdl/inc/jtframe_mem_ports.inc:1` declares the game-side
   port as `input [25:0] ioctl_addr` — **64 MB**. (The MiSTer target itself
   carries 27 bits, `jtframe_emu.sv:334`, so the bit exists; the *game* port
   is the cap.) 70.26 MB wraps.
2. `qsnd_start` would be `73,662,464 / 1024 = 71,936`, which does not fit the
   **16-bit** header word (`corerom.go:174-183`,
   `jtcps1_prom_we.v:73-76`). Max representable start is 65,535 KiB.

**So the WIDE romset cannot be downloaded to MiSTer as a straight
concatenation, on any SDRAM tier. The MRA has to trim.**

### As mapped (the proposal)

QSound is placed to the **top of DSP sample bank `0x8E`**, i.e. `0x8F0000`
= 8.9375 MB — banks `0x00-0x8E` inclusive. Live content ends at region offset
`0x8E57F0` (mister_fit §2: 8 MB stock + 918 KB extension, occupying DSP banks
`0x80-0x8E`), so the placement covers every live byte, ends on a sample-bank
boundary, and is 1 KiB-aligned as §2 requires.

| region | placed length | body offset | header word (KiB) |
|---|---|---|---|
| header | 44 B | — | — |
| key | 20 B | — | — |
| maincpu | `0x600000` (6 MB) | 0 | — |
| audiocpu | `0x40000` (256 KB) | `0x600000` | `snd_start` = **6144** |
| qsound | `0x8F0000` (8.9375 MB) | `0x640000` | `pcm_start` = **6400** |
| gfx | `0x3000000` (48 MB) | `0xF30000` | `gfx_start` = **15552** |
| firmware | `0x2000` (8 KB) | `0x3F30000` | `qsnd_start` = **64704** |

- file size = 44 + 20 + 66,265,088 = **66,265,152 B = 63.196 MB**, i.e.
  843,712 B (0.80 MB) under the 64 MB `ioctl_addr` ceiling.
- every header word < 65,536 ✔ ; every region start is 1 KiB-aligned ✔ .

### The QSound trim, concretely

The QSound region is `{ name="qsound", width=16, reverse=true }`
(`mame2mra.toml:97`). Members: `vm3.11m` + `vm3.12m` (stock, 4 MB each) then
the profile's `vsw.21m` + `vsw.22m` (4 MB each, sentinel CRCs
`0xdec0de3a/3b`). `vsw.22m` is empty and `vsw.21m` is live only to
`0xE57F0`. The WIDE-set row becomes:

```toml
{ name="qsound", width=16, setname="vsavjw", parts=[
    { name="vm3.11m", crc="…", map="12", length=0x400000, offset=0 },
    { name="vm3.12m", crc="…", map="12", length=0x400000, offset=0 },
    { name="vsw.21m", crc="dec0de3a", map="12", length=0x0F0000, offset=0 },
] },
```

`vsw.22m` is simply not mapped; it stays in the romset for FBNeo and MAME.
`map="12"` is the reversed 16-bit map string the generic path produces for a
`wlen=2` member under `reverse=true` (`corerom.go:911-947` builds `"21"`,
`:842-857` reverses it) — **`parse_parts` does not apply `Reverse`, so the
TOML must spell the final map**. Confirming that byte-for-byte is open
question Q2 (§9).

**This does not violate the profile.** `cps2_wide.md` requires QSound length
to stay a power of two because *FBNeo* does `rom_mask = nCpsQSamLen - 1`.
That binds the ROMSET, which remains 4 × 4 MB = 16 MB. It does not bind
MiSTer: `jtcps2` has **no mask of any kind** on the sample path — the size is
set purely by an address width (`PCM_AW`, `jtcps1_sdram.v:23`, feeding
`jtframe_rom_1slot` at `:334`), and `grep mask cores/cps15/hdl/jtcps15_sound.v`
is empty. See §7.

---

## 4. Why vanilla's 32 MB stays put, verified against the placement code

This is the claim that makes the emulator superset invariant **structural**
on MiSTer rather than a test result. Read from the RTL, not assumed:

- Download, `jtcps1_prom_we.v:141-142`:
  `prog_addr <= … is_gfx ? {gfx_addr[24], gfx_addr[22:1]} + GFX_OFFSET …`
  and `prog_ba <= … is_gfx ? gfx_bank …`, with
  `gfx_bank = { 1'b1, gfx_addr[23] }` (`:106`).
- `GFX_OFFSET` is **not overridden** at the instantiation
  (`jtcps1_sdram.v:227-232` passes only `CPU_OFFSET`, `PCM_OFFSET`,
  `SND_OFFSET`), so it keeps its `23'h0` default (`:22`).
- Read, `jtcps1_sdram.v:357-358`:
  `objgfx_cs = {2{rom0_cs}} & { rom0_bank[0], ~rom0_bank[0] }` and
  `cps2_gfx0 = { rom0_bank[1], gfx0_addr }`, with both bank-2 and bank-3
  slots at `ZERO_OFFSET` (`:364-386` u_bank2, no OFFSET given; `:401-408` u_bank3
  `SLOT0_OFFSET( ZERO_OFFSET )`).

So for every GFX byte address below 32 MB — i.e. `gfx_addr[25] == 0`, which
is *all* of groups A and B by construction, because group C begins at exactly
32 MB — the bank and the word address are computed by expressions that the
profile does not touch. The obj-bank ↔ SDRAM mapping is:

| obj bank (`table_y` bits) | SDRAM bank | word range | byte range in bank |
|---|---|---|---|
| 0 | 2 | `0x000000-0x3FFFFF` | 0 – 8 MB |
| 1 (shared with the scroll slot, `SCR_OFFSET=0`, `jtcps1_sdram.v:179,415`) | 3 | `0x000000-0x3FFFFF` | 0 – 8 MB |
| 2 | 2 | `0x400000-0x7FFFFF` | 8 – 16 MB |
| 3 | 3 | `0x400000-0x7FFFFF` | 8 – 16 MB |

**Banks 2 and 3 are exactly full with vanilla's own art and are not touched
by this design at all.** The only way group C could disturb them is if the
redirect condition mis-fired, and its condition is `gfx_addr[25]`, which is
0 for the whole stock 32 MB. That is a construction argument, and it is what
`test_mister_sim_anchor.sh` then confirms empirically on stock `vsavj`.

---

## 5. THE MAP

Offsets in the RTL are 23-bit **word** constants (`jtcps1_sdram.v:158-164`
for bank 0's family, per-slot `SLOTn_OFFSET` for the read side); the tables
below give bytes and the word constant. jtframe applies offsets as an ADD,
not an OR — `jtframe_romrq_bcache.v:74`
`sdram_addr = offset + { …, addr_req >> (DW==8) }` — so placement is
arbitrary at word granularity, with no power-of-two alignment requirement.

### Bank 0 — 16 MB, the only read/**write** bank (`ba_wr[3:1] = 0`, `:215`)

| byte offset | region | size | how it gets there |
|---|---|---|---|
| `0x000000` | 68k PRG, `CPU:$000000-$5FFFFF` | 6 MB | `ROM_OFFSET = 0`; slot 3, `SLOT3_AW` 21 → **22** |
| `0x600000` | VRAM | 256 KB | `VRAM_OFFSET = 23'h300000` |
| `0x640000` | OBJ RAM | 32 KB | `ORAM_OFFSET = 23'h320000` |
| `0x648000` | work RAM (`RAM:$FF0000-$FFFFFF`) | 64 KB | `WRAM_OFFSET = 23'h324000` |
| `0x658000` | Z80 program | 512 KB | `SND_OFFSET = 23'h32C000` |
| `0x6E0000` | **QSound PCM HIGH** — a 1 MB window for DSP sample banks `0x80-0x8F`, of which `0x80-0x8E` (`0xF0000` B) are downloaded | 1 MB | NEW `PCMH_OFFSET = 23'h370000` |
| `0x7E0000` | **GFX group C, obj bank 5** | `0x7FEE00` (7.995 MB) | NEW `GFXC5_OFFSET = 23'h3F0000` |
| `0xFDEE00` | free | 135,680 B (0.129 MB) | |

Bank 0, sum of regions: **16,608,768 of 16,777,216 B** (168,448 B
unallocated). With the 32 KB alignment gap before `PCMH_OFFSET` the highest
byte used is `0xFDEDFF`, so the free tail is 135,680 B.

### Bank 1 — 16 MB, read-only

| byte offset | region | size | how it gets there |
|---|---|---|---|
| `0x000000` | **QSound PCM LOW** — DSP sample banks `0x00-0x7F` | 8 MB | `PCM_OFFSET = 0` (unchanged) |
| `0x800000` | **GFX group C, obj bank 4** | `0x773A00` (7.452 MB) | NEW `GFXC4_OFFSET = 23'h400000` |
| `0xF73A00` | free | 574,976 B (0.548 MB) | |

Bank 1, sum of regions: **16,202,240 of 16,777,216 B** (574,976 B free
at the top).

### Banks 2 and 3 — 16 MB each, **UNCHANGED, byte-for-byte** (§4)

| bank | byte range | contents |
|---|---|---|
| 2 | `0x000000-0x7FFFFF` | GFX obj bank 0 |
| 2 | `0x800000-0xFFFFFF` | GFX obj bank 2 |
| 3 | `0x000000-0x7FFFFF` | GFX obj bank 1 **and** the scroll slot (same bytes, two address paths) |
| 3 | `0x800000-0xFFFFFF` | GFX obj bank 3 |

### The whole-tier arithmetic

```
  stock GFX (banks 2+3)                            32.000 MB   (measured: full)
  68k PRG, WIDE v1 declared                         6.000 MB   (mister_fit §1: live
                                                                to PRG:0x4D10F3 plus a
                                                                30-byte pin at 0x5FFF00)
  VRAM + OBJ RAM + work RAM + Z80 windows            0.844 MB   (slot geometries, §5)
  QSound: 8 MB in ba1 + a 1 MB window in ba0         9.000 MB   (.rom carries 8.9375 MB;
                                                                live to 0x8E57F0)
  GFX group C, obj bank 4                            7.452 MB   (highest code 0xEE73)
  GFX group C, obj bank 5                            7.995 MB   (highest code 0xFFDB)
  ------------------------------------------------------------
  total placed                                      63.292 MB
  tier (JTFRAME_SDRAM_LARGE, 4 x 16 MB)             64.000 MB
  slack                                              0.708 MB   (0.161 in ba0, 0.548 in ba1)
```

### The two moves that make it fit, stated plainly

1. **The QSound region is SPLIT across two SDRAM banks on `pcm_addr[23]`.**
   DSP sample banks `0x00-0x7F` (the stock 8 MB) stay at bank 1 offset 0 —
   *byte-identical to stock jtcps2* — and banks `0x80+` (the WIDE extension,
   which is the part the profile added) go to bank 0. This is not cosmetic:
   with QSound whole in bank 1, bank 1's spare is 7.06 MB and the SMALLER of
   the two group-C obj banks needs 7.45 MB. **Best case with QSound whole is
   an overflow of 0.39 MB**, and no rearrangement of PRG, Z80 or the RAM
   windows closes it, because the deficit is strictly bank 1's and PCM is
   the only thing in bank 1. The split bit is exactly the stock/WIDE
   boundary, which is a nice property to have on the superset invariant.
2. **Group C is split one obj bank per SDRAM bank**, keyed on
   `gfx_addr[23]` at download time and `rom0_bank[0]` at read time. Obj bank
   **4** — the three fighter bands, i.e. the in-match traffic — goes to
   **bank 1**, the bank whose headroom `tests/audit_sdram_bank_load.sh`
   actually measured. Obj bank **5** — select/wheel art, cold during a match
   — goes to **bank 0**, whose extra load therefore lands on the select
   screen rather than in a match.

### Slot count — the one place this needs a new jtframe file

| bank | slots after the change | module |
|---|---|---|
| 0 | 7 (RAM/VRAM/ORAM RW, VRAM-DMA, gfx-ORAM, main ROM, Z80, PCM-high, obj bank 5) | **`jtframe_ram1_7slots` does not exist** — upstream has `ram1_1..5slots` and `ram2_4..6slots` |
| 1 | 2 (PCM low, obj bank 4) | `jtframe_rom_2slots` ✔ exists |

Two ways out, both honest:

- **(A, recommended)** add `jtframe_ram1_7slots.v` to the fork — a mechanical
  member of an existing formulaic family. Keeps bank 1 to exactly the two
  streams (`PCM` + `obj`) that the GO measurement modelled.
- **(B)** move the Z80 to bank 1. Bank 0 drops to 6 slots
  (`jtframe_ram2_6slots`, second write port tied off) and bank 1 becomes
  `jtframe_rom_3slots` — zero new jtframe files, but bank 1 then carries
  three streams, which is beyond what was measured.

---

## 6. The download-side and read-side changes this map implies

Declarative, profile-gated, and listed here so the RTL arc can be costed.
**None of this is implemented.**

```verilog
// jtcps1_prom_we.v, in the `always @(*)` at :102-110  — GROUP C REDIRECT
//   obj bank value = gfx_addr[25:23]; group C is 3'b100 and 3'b101
//   (gfx_addr[24] is 0 across the whole 32-48 MB window by construction)
if (CPS2W && gfx_addr[25]) begin
    gfxc_ba   = gfx_addr[23] ? 2'd0 : 2'd1;                       // b5->ba0, b4->ba1
    gfxc_addr = {1'b0, gfx_addr[22:1]} +
                (gfx_addr[23] ? GFXC5_OFFSET : GFXC4_OFFSET);
end

// jtcps1_prom_we.v:141-142  — QSOUND SPLIT (is_oki is the PCM region on CPS-2)
prog_ba   <= is_oki ? (pcm_addr[23] ? 2'd0 : 2'd1) : …;
prog_addr <= is_oki ? (pcm_addr[23] ? ({1'b0, pcm_addr[22:1]} + PCMH_OFFSET)
                                    :  (pcm_addr[23:1]        + PCM_OFFSET )) : …;
```

Read side: `jtcps1_sdram.v` gains one slot in bank 0 (obj bank 5, `SLOT_AW`
22, `DW` 32, `OFFSET = GFXC5_OFFSET`) and one in bank 1 (obj bank 4, same
shape, `OFFSET = GFXC4_OFFSET`), plus the PCM-high slot in bank 0
(`AW` 20 byte, `DW` 8, `OFFSET = PCMH_OFFSET`). `rom0_bank` widens to 3 bits
(slice D3, §10) and `rom0_bank[2]` selects the group-C pair.

---

## 7. QSound: the decision, and the two questions answered

**How much of the declared 16 MB is placed:** `0x8F0000` = 8.9375 MB —
DSP sample banks `0x00` through `0x8E` inclusive. Live content ends at
`0x8E57F0`, inside bank `0x8E`, so the placement ends on the first sample-bank
boundary above the last live byte and **7.0625 MB of the declared region is
never downloaded.** (The 1 MB window reserved in SDRAM bank 0 covers banks
`0x80-0x8F`; only `0x80-0x8E` are written into it.) The romset keeps all four 4 MB
members.

**Is the power-of-two rule a jtcps2 constraint?** No — it is FBNeo-only.

- FBNeo: `rom_mask = nCpsQSamLen - 1`, so the length must be a power of two.
  Unchanged; the ROMSET is still 16 MB.
- MAME: `qsound_device` is a `device_rom_interface<24>`, i.e. a 24-bit
  address space; 16 MB is its exact ceiling (`cps2_wide.md` B5).
- **jtcps2: no mask anywhere.** The sample path is
  `jtcps15_sound.v:47 output reg [22:0] qsnd_addr, // max 8 MB` →
  `jtcps2_game.v:392,498` → `jtcps1_sdram.v:334 .SLOT0_AW(PCM_AW)` on a
  `jtframe_rom_1slot`, which computes `offset + (addr >> 1)`
  (`jtframe_romrq_bcache.v:74`). `grep -n "mask" cores/cps15/hdl/jtcps15_sound.v`
  returns nothing. The 8 MB cap is an **address width**, not a mask, so any
  placed length works and 8.9375 MB is conformant.

**Do banks `0x80-0x8E` stay addressable after the width fix?** Yes.

- The defect: `jtcps15_sound.v:416` `qsnd_addr[22:16] <= dsp_ab[6:0];`
  keeps 7 bank bits, so bank `0x8N` aliases onto `0x0N` and *mis-plays legacy
  audio* rather than going silent (14z-86).
- The fix: `qsnd_addr` `[22:0] → [23:0]`, the latch `[6:0] → [7:0]`, and
  `PCM_AW` `23 → 24` (`jtcps1_sdram.v:23`). `dsp_ab` is 16 bits
  (`jtcps15_sound.v:84`) and only `dsp_ab[15]` is consumed as the
  latch strobe (`:415`), so bits 7..14 are free — 8 bank bits is not close to
  a limit.
- After the fix, bank `0x80+` means `qsnd_addr[23] = 1`, which is precisely
  the split bit routing to bank 0's PCM-high window. Banks `0x80-0x8F` are
  addressable; **banks `0x90-0xFF` are placed nowhere**, and with a widened
  latch the DSP could name them. Recommendation (declarative, profile-gated):
  mask the high window to its 1 MB, so a stray high bank aliases inside the
  extension instead of reading group-C art as PCM.

---

## 8. The PRG window: what has to be decoded, and what it collides with

`jtcps2_main.v:183-184`:
```verilog
rom_addr    <= A[21:1];            // 21-bit word address = 4 MB
rom_cs      <= A[23:22] == 2'b00;  // CPU $000000-$3FFFFF, flat
```
WIDE v1 needs `CPU:$000000-$5FFFFF`, i.e. one more megabyte-pair.

### Everything else `jtcps2_main.v` decodes, and whether it collides

| line | signal | window | collides with `$400000-$5FFFFF`? |
|---|---|---|---|
| `:190` | `objcfg_cs` | `dec_en ? $400000-$4FFFFF : $FFFFF0-$FFFFFF`, **and `&& !RnW`** | overlaps the first megabyte — but it is **WRITE-ONLY** |
| `:192` | `main2qs_cs` | `$600000-$61FFFF` | no |
| `:187` | `pre_oram_cs` | `$700000-$7FFFFF` (masked by `oram_base`) | no |
| `:188` | `io_cs` | `$800000-$87FFFF` | no |
| `:186` | `pre_vram_cs` | `$900000-$93FFFF` | no |
| `:185` | `pre_ram_cs` | `$FF0000-$FFFFFF` | no |
| — | (nothing) | `$500000-$5FFFFF` | window is entirely undecoded |

**The objcfg port decodes a whole megabyte, not sixteen bytes** — the RTL is
looser than the hardware here — but because it is qualified with `!RnW`, a
*read* anywhere in `$400000-$4FFFFF` asserts nothing today and would assert
only `rom_cs` after the change. So there is no read collision at all, and a
write still reaches only `objcfg_cs`.

### The minimal, profile-gated proposal (NOT implemented)

```verilog
// jtcps2_main.v:183-184
rom_addr <= A[22:1];                                     // 22-bit word = 8 MB reach, 6 MB loaded
rom_cs   <= (A[23:22] == 2'b00)
          | (CPS2W & RnW & (A[23:21] == 3'b010));        // $400000-$5FFFFF, READS ONLY

// jtcps2_main.v:167 — see below
one_wait  = !ASn && BGACKn && (A[23:20] < (CPS2W ? 4'h6 : 4'h5) || A[23:20] >= 4'h8);
```
plus `main_rom_addr` `[21:1] → [22:1]` (`jtcps2_game.v:35`) and `SLOT3_AW`
`21 → 22` (`jtcps1_sdram.v:274`).

### Is the reserved 16 bytes enough? — yes, and it is now load-bearing three times

`cps2_wide.md` reserves `$400000-$40000F` and forbids allocation there. With
the change, a read at those addresses returns **ROM** on jtcps2w. FBNeo
read-shadows them with ROM already; MAME keeps them readable as CPS2 output
registers. That is now a **three-way** divergence, unobservable only because
nothing may live there. `build/m3b_merged13/gen.log` confirms the allocator
honours it (`wide_ext` starts at `0x400010`, mister_fit §1). The reservation
is enough — but it must be re-stated in `cps2_wide.md` as a MiSTer
requirement too, not just an FBNeo/MAME one.

### A real finding while reading it: the wait-state line

`jtcps2_main.v:167` gives `A[23:20] < 4'h5` one wait state — so the whole
existing 4 MB of ROM **and** `$400000-$4FFFFF` are one-wait, while
`$500000-$5FFFFF` is **zero-wait**. Left alone, the second megabyte of the
PRG extension would run at a *different* bus timing from every other byte of
program ROM. Today the profile puts only the 30-byte facing-alias thunk at
`$5FFF00` there, so nothing would be seen — which is exactly how this kind
of defect survives. The gated `4'h6` above fixes it and must ship in the same
slice as the decode.

---

## 9. Open questions, stated as questions

1. **Does bank 0 absorb obj bank 5's select-screen traffic?**
   `tests/audit_sdram_bank_load.sh` bounded **bank 1** (PCM has 98.8% row
   misses, so no locality to lose). Bank 0 already sustains 40,797
   accesses/frame = 32.9% of its all-miss ceiling, and the select+VS phase
   adds up to ~12k obj accesses/frame. Unmeasured. The instrument exists; it
   needs a `cps2w` core carrying the map.
2. **Does `parts=` with `map="12"` reproduce the untrimmed qsound region
   byte-for-byte?** The trim must be a pure truncation. Provable before any
   RTL: generate both MRAs and diff the leading bytes of the `.rom`.
3. **Does `dsp_ab[7]` actually carry sample-bank bit 7 in the real
   `dl-1425.bin` program?** The width fix assumes it. Must-fire control: a
   sample placed at bank `0x80` must play the extension content, not bank
   `0x00`'s.
4. **`jtframe_ram1_7slots` (new fork file) or move the Z80 to bank 1?**
   §5 option A vs B. This is a maintainer call about fork surface.
5. **The fit has 0.708 MB of slack in 64 MB and depends on four frozen
   extents** (obj bank 4 ≤ `0xEE73`, obj bank 5 ≤ `0xFFDB`, QSound live
   ≤ `0x8E57F0`, PRG live ≤ `0x5FFF1E`). Any growth in tenant art breaks the
   map silently, months before a bring-up would notice.
   `tests/audit_mister_map_fit.sh` (added this session, static tier) freezes
   all four, re-checks the scramble identity §1 rests on, and carries three
   must-fire controls.
6. **Does the MiSTer DDR staging path (`ddr_load=true`,
   `address="0x30000000"`, `corerom.go:23-35`) impose its own size limit at
   63.2 MB?** Unread.
7. **Does widening `main_rom_addr` interact with `jtcps2_dtack.v`?** Unread.
8. **Should the profile be selected at RUNTIME from a spare header byte
   rather than by `ifdef` in `cps2w`?** A compile-time gate means stock
   `vsavj` on our RBF gets the widened PRG decode and the 3-bit obj bank. Both
   are provably inert for stock content (`cps2_wide.md` A1/A2 measured zero
   reads above 4 MB and `bit12` never set), but a runtime bit from the header
   would make the *MRA* the profile selector and restore
   gating-by-construction. The header has reserved bytes
   (`jtcps1_prom_we.v:52-54`, "6 are actually used and 10 are reserved").

---

## 10. The slice plan

Each slice is independently verifiable, carries its own gate and its own
must-fire control, and every one of them re-runs
`tests/test_mister_sim_anchor.sh` on **stock `vsavj`** as the emulator
superset leg (frozen MAME 2146 / sim 2502 / skew 356 ± 30,
`tests/test_mister_sim_anchor.sh:87-90`).

### Critique of the straw-man ordering

The proposed D1→D4 is right about D2-before-D3 (you cannot prove the promote
until the art is placed) and right that the QSound width fix is the most
self-contained piece. Two changes:

- **A slice D0 has to come first.** The mapping layer is the only part that
  can fail for a reason no RTL can fix — the 64 MB `ioctl_addr` and the
  16-bit header word (§3). It is also the cheapest thing in the arc and needs
  no simulator.
- **The QSound *split* is not part of D1.** D1 is the width fix, which is
  self-contained and inert on a stock set. The split is a placement change
  and belongs with the rest of the placement in D2.

### The slices

| # | scope | smallest thing that proves it | must-fire control | superset leg |
|---|---|---|---|---|
| **D0** | `cores/cps2w/cfg/mame2mra.toml`: the `vsavjw` region rows (QSound `parts` trim). **No RTL.** | Generate the MRA + `.rom` for the WIDE set: file size < 64 MB, all four header words < 65,536, every region start 1 KiB-aligned, and each word equals the §3 table. | Restore the untrimmed row → generation must produce a `qsnd_start` that does **not** fit 16 bits (i.e. the gate must be able to fail). | `test_jtcores_twin`: the stock `vsavj` MRA from `cps2w` stays byte-identical to stock `cps2`'s except `<rbf>`. |
| **D1** | QSound width: `jtcps15_sound.v:47,416` (`qsnd_addr[23:0]`, latch `[7:0]`) + `PCM_AW` 24. No format change, no placement change. | A sim run of a replay that triggers an M5 voice from DSP bank `0x80` fetches from PCM byte `0x800000`, not `0x000000`. | The same run on the *unfixed* core must fetch `0x000000` — the aliasing defect reproduced as a fixture (this is what makes the pass mean something). | anchor gate unchanged on stock `vsavj`. |
| **D2** | Placement: bank-0 offsets re-packed for PRG 6 MB, the group-C redirect in `jtcps1_prom_we`, the QSound bank split, the two new GFX slots + the PCM-high slot, `jtframe_ram1_7slots`. | An SDRAM image census after download: dump all four banks and assert every region begins at its §5 offset, that banks 2+3 are **byte-identical to the stock `cps2` core's** on the same romset, and that the group-C obj banks are non-zero where the manifests say tiles are. | Perturb one offset constant by 1 KiB → the census must fail. And: zero-fill group C in the romset → banks 2+3 must still be byte-identical (isolates the redirect from the content). | anchor gate unchanged on stock `vsavj`; banks 2+3 byte-identical is itself the structural leg. |
| **D3** | The obj promote: `jtcps2_obj_scan.v:152` `st3_bank <= {table_y[12], table_y[14:13]}` (the CPS-2 Turbo rule, applied *after* the `:141` terminator check), `dr_bank`/`obj_bank`/`rom_bank`/`rom0_bank` widened to 3 bits, `rom0_bank[2]` routed to the group-C slots. | **The MiSTer twin of the FBNeo B4 canary**: a test-only flag that ORs `0x1000` into the y-word of bank-2/3 sprites, with group C loaded as a byte copy of group B, running the STOCK rom. Work RAM is bit-identical by construction; the *frames* must be pixel-identical. | Zero-fill group C → the frames must DIFFER. (`cps2_wide.md` records that FBNeo's first attempt passed this test vacuously because the member never arrived; the control is the whole point.) | RAM identity is guaranteed by the canary design; the anchor gate still runs. |
| **D4** | The PRG window: `rom_cs`/`rom_addr`/`one_wait` (§8), `main_rom_addr`, `SLOT3_AW` 22. | Relocate a real data block above `CPU:$400000` and repoint one pointer — RAM must stay identical, and the zeros variant must diverge (the B4-prg discipline: a pass with no negative control is not evidence). | The same rows pointed at zero fill → RAM MUST diverge. | anchor gate unchanged on stock `vsavj` — this is the slice where a widened decode could most easily perturb legacy behaviour. |

Only after D0–D4 does a WIDE set boot; the first *whole-system* gate is
`tests/audit_sdram_bank_load.sh` re-run on the `cps2w` core carrying the map,
which is both the answer to open question 1 and the go/no-go the bank-repack
ruling asked for.

---

## 11. If it did not fit — what the fallback implies

It does fit, by 0.708 MB (743,424 B). Recorded here anyway, because the margin is thin and
open question 5 is a real risk:

`JTFRAME_SDRAM_XL` (`jtframe_emu.sv:175-181` on upstream master) is a 128 MB
tier built from **two chips on one module**, chip-selected by nCS polarity. It
is **not at our pin** — `v1.7.3` predates it by ~2.4 years and 3057 commits —
and it is not a flag: it lives only in the `JTFRAME_SDRAM_CACHE` branch, and
setting it without that branch compiles, validates and silently produces an
aliased map (`docs/platform/gotchas.md`). Adopting it means pinning a bare
master commit and paying the uprev bill catalogued in
`docs/platform/mister.md` "What an uprev to upstream master would cost":
`hdl/ver/test.cpp` split and moved, `jtframe_emu.sv` moved,
`bin/jtsim` rewritten, `game.yaml` → `files.yaml` with a changed schema,
`mraauthor` → `author`, and `-inputs` replaced by a `.cab` cabinet script
which orphans `sim_inputs.hex`, `tools/rpl2siminputs.py`,
`tools/run_sim_jtcps2.sh`, fork commit 2 and both sim gates. It also requires
the maintainer to own the 128 MB module. **And it would not remove any of
§6–§8: every core-side format change in this document is required on either
tier.** XL buys headroom, not a shorter arc.
