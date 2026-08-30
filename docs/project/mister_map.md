# MiSTer SDRAM placement map — the WIDE v1 romset on jtcps2w @ `v1.7.3`

Design + measurement, 14z-107 (4). **No RTL was written for this document.**
Every figure names its instrument; every RTL claim names `file:line` in the
pinned submodule `emu/jtcores` (jotego/jtcores `v1.7.3` + our fork commits;
the pin was `74ed17d` when this was designed, `63496069` at 14z-113 and `202fc3e6` at 14z-115 —
read it from `tools/setup_jtcores.sh`, the `file:line` references below
were taken at the design pin and the shared files they name are
byte-untouched since, `test_jtcores_twin` 2e). Platform facts live in `docs/platform/mister.md`; the
region-by-region content measurements live in `docs/project/mister_fit.md`;
the profile itself is `docs/project/cps2_wide.md`.

> **The SYNTHESIS of this material — what is true, in causal order, without
> the retraction history — is `docs/project/mister_core.md`.** This file is
> the derivation and stays the authority: where the two disagree, this one
> wins and the synthesis is the thing to fix.
> `tools/mk_mister_page.py --check` re-derives section 5's offsets and
> section 3's header words on every `tests/run_all_static.sh`.

**Verdict up front: IT FITS — with 0.125 MB of slack in 64 MB, and SDRAM
bank 1 EXACTLY FULL.** It does not fit the way the route was framed.
See §1 for the first correction, §5 for the map, §9 for what is still open.

**THE 0.708 MB THIS DOCUMENT USED TO CLAIM IS RETRACTED — measured by the
slice-D2 SDRAM image census, 14z-107 (9).** Every slack figure below was
computed from the group-C art's live ADDRESS FOOTPRINT (7.452 + 7.996 MB).
The download does not work that way: the MRA maps the WHOLE declared 48 MB
GFX region, so each group-C obj bank reserves its FULL 8 MB in SDRAM
regardless of what the art does inside it. Measured on the real image:
**bank 0 is used to `0xFE0000` (131,072 B free) and bank 1 to `0x1000000`
(ZERO free).** It still fits — and the fit is now decided by REGION SIZES
rather than by tile ceilings, which is a better place to be for the art (one
more tenant tile inside the existing 16 MB costs nothing) and a worse one for
headroom (the group-C romset region cannot grow past 16 MB at all). §5's
tables carry the correction in place.

**STATUS AT 14z-113 (this header's own claims below were 14z-107 (12)'s
and are superseded in place): D0-D5 ARE IN THE RTL; THE WIDE ROMSET BOOTS
ON THE CORE; BOTH GROUP-C OBJ BANKS ARE FETCHED (wheel 14z-107 (11), FIGHTER
14z-108: 1,735 codes in obj bank 4, 843 frames after match start); A TENANT
HAS BEEN SELECTED AND HAS FOUGHT ON THE CORE (14z-108, `test_mister_tenant_oracle`
agreeing on every mapped field); THE QSOUND EXTENSION IS FETCHED (14z-108);
AND ALL OF IT HAS RUN ON HARDWARE — field test PASSED 14z-109, re-confirmed
on bundle 14z112 (2026-08-28) with stock Vampire Savior coexisting on the
same card. `docs/project/mister_core.md` §12 is the ledger of what is STILL
never done (pixels and audio never MEASURED; timing a seed lottery).**

**SLICES D3, D4 AND D5 ARE IN THE RTL, THE WIDE ROMSET BOOTS ON THE CORE,
AND TENANT ART HAS BEEN FETCHED — obj bank 5 only (14z-107 (11)+(12)).**
The CPS-2 Turbo object promote
(`{ wide_en & table_y[12], table_y[14:13] }`, lifted into
`cores/cps2w/hdl/jtcps2w_obj_bank.v`) drives the third obj bank bit through a
chain widened to 3 bits and `rom0_bank[2]` is no longer tied low; D4, the
6 MB read decode plus the `one_wait` boundary, shipped in the same session;
and **D5** complements the CPS-2 key's encrypted-opcode RANGE word on its way
into `jtcps2_dec_ctrl`, profile-gated, which is what the boot failure below
turned out to be. With all three in, the core reaches the select screen and
the read probe counts **9,038,400 reads over 105 DISTINCT TILE CODES
`0x74D6-0xFE41` in group-C obj bank 5** — the select-wheel tenant art — with
the control leg at zero. **§9 open question 1 is ANSWERED, YES, WITH ROOM.**
**WHAT IS STILL NOT DONE, and it is not a slice: obj bank 4 — the FIGHTER
art — has never been fetched, and the reason is the HARNESS.** The simulator's
direction bits were **REVERSED end for end** (measured on all four against the
game's own `$FF8058` mirror, 14z-108: Up arrived as Right, Down as Left, Left
as Down, Right as Up), so the tenant-picking replay put the cursor on a legacy
character. **FIXED 14z-108** in `tools/rpl2siminputs.py`. ~~**No tenant has ever been in a match on the core, no frame has been
compared programmatically against MAME's, and nothing has run on hardware.**~~
**All three superseded — see the STATUS paragraph at the top of this file
(14z-113); what remains never done is a MEASURED frame or audio comparison.**
`docs/project/mister_core.md` §12 is the ledger of what has never been tried.
**[SUPERSEDED, kept because its ELIMINATIONS stand — the state before D5:**
"What has NOT happened is the end-to-end demonstration: the WIDE romset does
not get past its own boot sequence on the core (`docs/platform/mister.md` "The pre-D5 boot loop"; the eliminations verbatim in
`docs/platform/mister_history.md`), the read probe counts ZERO
reads in both group-C windows and zero in vanilla obj bank 2 as well, and the
boot fault reproduces frame-for-frame with the profile bit CLEAR." The last
clause is CORRECTED in place elsewhere: the two profile states are not
frame-for-frame identical — the profile-ON leg completes ten program-ROM reads
above `$400000` and the profile-CLEAR leg zero, and the instrument that said
"identical" could not see the window it was being asked about.**]**
§10's rows carry what each slice is actually held to.

**SLICE D2 IS DONE (14z-107 (9)): THE PLACEMENT IS IN THE RTL AND THE
IMAGE WAS COUNTED.** Fork commit `0df6f000` (pushed). The bank-0 re-pack,
the group-C GFX redirect, the QSound split across two banks and the two new
slot counts all ship; `cores/cps2w/hdl` grows from four files to six with
OVERRIDES of `jtcps1_sdram.v` and `jtcps1_prom_we.v`, and jtframe gains ONE
new file, `hdl/sdram/jtframe_ram1_7slots.v` (maintainer-ruled option A, §5;
open question 4 is answered). The obj PROMOTE is still D3: `rom0_bank[2]` is
tied low in the game top, so D2 changes no fetch at all — which is why its
evidence is an SDRAM IMAGE CENSUS and not a replay. Section 5's table was
measured byte for byte against a real download and is unchanged;
`tests/test_mister_sdram_census.sh` is the gate, and §10's D2 row carries the
numbers. Section 6, which said "None of this is implemented", is now the
as-built record.

**SLICE D1 IS DONE (14z-107 (6)): the QSound sample-bank width, RUNTIME-
GATED, and `cores/cps2w` now carries RTL.** Fork commit `4840df8a`. The
maintainer ruled 2026-08-23 that the profile is selected from a spare MRA
header bit rather than by `ifdef` (open question 8, below, is answered), so
stock `vsavj` on our own RBF runs with the widened behaviour CLEAR. Two
things the slice contradicted, both corrected in place below: **`PCM_AW`
23 → 24 DOES NOT COMPILE** (§7, §10 D1 row) and **the bank bit `dsp_ab[7]`
is now VALIDATED rather than assumed** (§9 Q3). Everything else in the map
stands. A third thing D1 found belongs to the LANE rather than the map and
is filed in `docs/platform/gotchas.md`: a new core missing `hdl/pal_lut.hex`
renders a BLACK SCREEN, and through the Verilator harness's
per-changed-frame `fork()` that video defect MOVED the simulated match-start
anchor by 107 frames — so a red anchor is not evidence about RTL until a
core-vs-core RAM comparison says it is. **ROOT-CAUSED 14z-107 (7): the
forked child's `exit(0)` rewound the parent's `sim_inputs.hex` (shared
`FILE*`, `fclose()` repositions the shared offset), so the simulated
CONTROLLER was replayed once per fork. Fixed in the fork (`_exit(0)`, plus
`JTFRAME_SIM_NOVIDEO` and `--frame-output off` as the lane's default), which
is what lets D2 change video output without the anchor going ambiguous.**

**SLICE D0 IS DONE (14z-107 (5)) AND THE MAP SURVIVED IT.** The MRA that
trims the image is written, the fork carries it (commit `38acc638`), and the
`.rom` it produces is **exactly** the §3 table — 66,265,152 B with header
words 6144 / 6400 / 15552 / 64704 — verified region by region against the
romset rather than recomputed. The §3 "mapped verbatim" numbers were
reproduced too, by the control: 73,670,720 B and a 71,936 KiB start word.
The stock `vsavj.rom` is BIT-IDENTICAL to the 14z-106 image (sha1
`f9dc2987…`). Nothing in the map moved. What DID change is §3's proposed TOML row, which
was wrong in a way that fails silently — corrected in place there.

---

## Index — where each slice's as-built paragraph is

This document is the DERIVATION (numbered sections, cited by the gates as
§3 / §5 / §9 — never renumber). Each slice's design lives here, its as-built
record in the section named, its measurement in `docs/platform/mister.md`,
and its status row in §10:

| slice | what | design here | as built | measured in `mister.md` | gate |
|---|---|---|---|---|---|
| D0 | the MRA + the `.rom` trim | §3 | §3 "The QSound trim, concretely — AS BUILT" | "HOW THE MRA AND THE `.rom` ARE MADE" | `tests/test_mister_mra_map.sh` |
| D1 | QSound sample-bank width, runtime-gated | §7, §9 Q3/Q8 | `mister_core.md` §8 | "The runtime profile gate", "The QSound bank bit IS `dsp_ab[7]`" | `tests/test_mister_wide_gate.sh` |
| D2 | the SDRAM placement (bank-0 re-pack, group-C redirect, QSound split) | §5, §6 | §6 "AS BUILT (slice D2)" | "THE SDRAM IMAGE CENSUS", "The per-bank profile of the WIDE image" | `tests/test_mister_sdram_census.sh`, `tests/audit_sdram_bank_load.sh` |
| D3 | the object promote (the 19th tile bit) | §6 | §6 "The promote — AS BUILT (slice D3)" | "THE SDRAM READ PROBE", "WITH SLICE D5 IN" | `tests/test_mister_gfxc_fetch.sh`, `tests/test_mister_obj_oracle.sh` |
| D4 | the 6 MB program window | §8 | §8 "The minimal, profile-gated proposal — IMPLEMENTED" | "CAN THE 68k READ ABOVE 4 MB?" | `tests/test_mister_prg_window.sh`, `tests/test_mister_prg_probe.sh` |
| D5 | the decryption range | §8 (retracted there), `mister_core.md` §7 | §10's D5 row | "THE MECHANISM: THE CPS-2 KEY'S RANGE WORD IS STORED COMPLEMENTED", "SLICE D5: THE FIX" | `tests/test_mister_wide_gate.sh` section 9 |
| the stock legs | the emulator superset on FPGA | §10 (every slice) | — | "The work-RAM oracle" (the anchor), "The runtime profile gate" | `tests/test_mister_sim_anchor.sh`, `tests/test_mister_wide_inert.sh` |
| the whole tier | does it fit | §1, §5, §11 | §5 "The whole-tier arithmetic" | "The numbers that bound a MiSTer-shaped profile" | `tests/audit_mister_map_fit.sh`, `tools/mk_mister_page.py --check` |

The holes — what has never been tried — are `mister_core.md` §12; the field
procedure is `mister_field.md`; the demand measurement is `mister_fit.md`.
The status paragraphs above this index are the slices' closing records as
written, newest first, each superseding the one below it in place.

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
| 5 (select/wheel art, ported effects) | 6,272 (6,271 until 14z-117: +1 glyph code, the M10 mark's third character at `0x1FE42`; 6,245 until 14z-115: +26 outline-tile codes at `0x1F800+`) | `0xFE42` (`0xFE41` until 14z-117) | `0xFFDB` (`patch/effect_c5.*.json`) | `0xFFDC × 128` = **`0x7FEE00`** = 7.995 MB |
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
  `rom_len` are the other four. **QUALIFIED 14z-107 (5): `parts=` puts every
  part of a region inside ONE `<interleave>` when `width>8`, so it can only
  express a MULTI-member 16-bit region if the members' maps are disjoint —
  which for CPS-2 QSound they are not. See §3.**
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

**[MSV-8]** **So the WIDE romset cannot be downloaded to MiSTer as a straight
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
- **MEASURED, not derived: this is byte-for-byte the `.rom` slice D0
  produces** (`tests/test_mister_mra_map.sh`). In the MRA the QSound row
  above is TWO adjacent regions, `qsound` (8 MB) then `qsoundw`
  (`0xF0000`) — only `qsound`'s start reaches the header, so the RTL sees
  the single 8.9375 MB region this table describes.

### The QSound trim, concretely — **AS BUILT, slice D0 landed 14z-107 (5)**

The QSound region is `{ name="qsound", width=16, reverse=true }`
(`mame2mra.toml:97`). Members: `vm3.11m` + `vm3.12m` (stock, 4 MB each) then
the profile's `vsw.21m` + `vsw.22m` (4 MB each). `vsw.22m` is empty and
`vsw.21m` is live only to `0xE57F0`.

**CORRECTED 14z-107 (5) — the row this section originally proposed does not
work, and it fails SILENTLY.** It read:

```toml
# WRONG — kept so it is not re-proposed. Do not use.
{ name="qsound", width=16, setname="vsavjw", parts=[
    { name="vm3.11m", crc="…", map="12", length=0x400000, offset=0 },
    { name="vm3.12m", crc="…", map="12", length=0x400000, offset=0 },
    { name="vsw.21m", crc="…",  map="12", length=0x0F0000, offset=0 },
] },
```

`parse_parts` puts **every** part of a region inside **one**
`<interleave output="16">` when `width > 8` (`corerom.go:462-479`), and
`interleave2rom` then resolves each output byte lane to the FIRST finger
whose map claims it (`mra2rom.go:238-249`). Three members that all carry
`map="12"` therefore collapse to `vm3.11m` alone, truncated to the shortest
finger — 0xF0000 bytes of the wrong file, no error. (The one in-tree user of
`parts=`, Pang!3 at `cores/cps1/cfg/mame2mra.toml:165-173`, has four
DISJOINT maps, which is why the limitation had never been hit.)

**[MSV-17]** **What shipped instead: the extension gets its OWN REGION.** The stock 8 MB
stays on the generic path, where it is emitted exactly as `cores/cps2` emits
it, and the trimmed member sits alone in a region where a single-part
`parts=` is correct:

```toml
{ name="qsoundw", skip=true },                       # every other set
{ name="qsoundw", width=16, setname="vsavjw", parts=[
    { name="vsw.21m", crc="f6c937e1", map="12", length=0x0F0000, offset=0 },
] },
```
with `"qsoundw"` inserted into `order` immediately after `"qsound"`. The
generic `skip=true` row is what keeps every stock MRA byte-identical: a
region with NO config at all is not skipped — it still emits its
`<!-- qsoundw - starts at 0x… -->` comment node into every MRA, which is
enough on its own to break the twin.

`vsw.22m` is simply not mapped; it stays in the romset for FBNeo and MAME.
`map="12"` is the reversed 16-bit map string the generic path produces for a
`wlen=2` member under `reverse=true` (`corerom.go:911-947` builds `"21"`,
`:842-857` reverses it) — **`parse_parts` does not apply `Reverse`, so the
TOML must spell the final map**.

**Q2 (§9) IS ANSWERED, MEASURED:** the trimmed region is a byte-for-byte
PURE TRUNCATION of the untrimmed one, and every other region of the produced
`.rom` equals the zips' content exactly. `tests/test_mister_mra_map.sh`
re-checks all of it.

### Three things D0 found that the design above did not know

1. **jtframe locates zip members by CRC32 and by NOTHING ELSE**
   (`mra2rom.go:163-172` — it walks the zips comparing `file.CRC32`, with no
   fallback to the name). FBNeo and MAME resolve by NAME and only warn on a
   hash mismatch, which is exactly why the WIDE members carry SENTINEL CRCs
   in both drivers (`vsw.41` = `dec0de41`, `vsw.21m` = `dec0de3a`, …). On
   MiSTer a sentinel is not a warning: it is `Warning: cannot find file … in
   zip` and no `.rom` at all. **So the MiSTer leg — unlike the other two —
   is pinned to the CRCs of one built romset**, and a rebuild that moves one
   must move the fork's catalogue entry and the `parts=` row with it.
   `tools/gen_vsavjw_xml.py` regenerates the entry from a zip and
   `tests/test_mister_mra_map.sh` fails if it is stale.
2. **[MSV-18]** **~~The WIDE set's PARENT is the BUILD's `vsav.zip`~~ CORRECTED 14z-112:
   the parent is the PRISTINE dump.** The four patched members
   `vm3.13m/15m/17m/19m` (tenant art inside vanilla's own 32 MB) now live
   INSIDE `vsavjw.zip`; builds pack no parent at all, so stock Vampire
   Savior and this profile can share one `games/mame/vsav.zip`. Historically
   a build's own patched parent carried them, and `run_wide.sh` overlaid it
   the same way for FBNeo and MAME.
   Since `jtframe mra` reads a HARD-CODED `$HOME/.mame/roms/<name>.zip`
   (`mrazip.go:23`), the stock leg and the WIDE leg cannot share one `$HOME`
   — `tools/mister_mra.sh` stages a PRIVATE one per run rather than writing
   into the user's.
3. **[MSV-15]** **`jtframe mra` needs the set to exist in `doc/mame.xml`**, which is
   jtframe's own reduced machine catalogue, not a MAME dump. The `vsavjw`
   entry added to the fork is `vsavj`'s verbatim except for the ROM map, the
   description and `sourcefile="capcom/cps2w.cpp"` — and that tag is the
   PROFILE GATE: `cores/cps2` parses `sourcefile=["cps2.cpp"]`, which does
   not match it, so the reference core cannot see the WIDE set at all.
   Measured: `jtframe mra cps2` → 316 MRAs, none WIDE; `jtframe mra cps2w`
   → 8, and the stock `vsavj` MRA is still byte-identical to `cps2`'s except
   `<rbf>`.

**This does not violate the profile.** `cps2_wide.md` requires QSound length
to stay a power of two because *FBNeo* does `rom_mask = nCpsQSamLen - 1`.
That binds the ROMSET, which remains 4 × 4 MB = 16 MB. It does not bind
MiSTer: `jtcps2` has **no mask of any kind** on the sample path — the size is
set purely by an address width (`PCM_AW`, `jtcps1_sdram.v:23`, feeding
`jtframe_rom_1slot` at `:334`), and `grep mask cores/cps15/hdl/jtcps15_sound.v`
is empty. That width is capped at `SDRAMW = 23` = 8 MB PER SLOT, though, so
the placed 8.9375 MB has to be two slots in two banks (§5, §7). See §7.

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

**[MSC-20]** Offsets in the RTL are 23-bit **word** constants (`jtcps1_sdram.v:158-164`
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
| `0x7E0000` | **GFX group C, obj bank 5** | `0x800000` (8 MB, of which `0x7FEE00` carries art) | NEW `GFXC5_OFFSET = 23'h3F0000` |
| `0xFE0000` | free | **131,072 B (0.125 MB)** | |

**[MSV-5]** Bank 0 is used to byte `0xFE0000` of `0x1000000`: **131,072 B free.**
**CORRECTED 14z-107 (9) by the census** — this table used to end obj bank 5
at `0xFDEE00` and claim a 135,680 B tail, because it sized the region by the
art's live footprint. The download writes the whole 8 MB region, art or no
art. The 32 KB alignment gap before `PCMH_OFFSET` is unchanged and real.

### Bank 1 — 16 MB, read-only

| byte offset | region | size | how it gets there |
|---|---|---|---|
| `0x000000` | **QSound PCM LOW** — DSP sample banks `0x00-0x7F` | 8 MB | `PCM_OFFSET = 0` (unchanged) |
| `0x800000` | **GFX group C, obj bank 4** | `0x800000` (8 MB, of which `0x773A00` carries art) | NEW `GFXC4_OFFSET = 23'h400000` |
| — | free | **0 B** | |

**Bank 1 is EXACTLY FULL: 8 MB of PCM + 8 MB of obj bank 4 = 16,777,216 B,
to the byte.** **CORRECTED 14z-107 (9) by the census** — this table used to
claim 574,976 B free, from the same footprint-vs-region error as bank 0's.
Nothing overflows, and nothing else can be added to bank 1 either.

### Banks 2 and 3 — 16 MB each, **UNCHANGED, byte-for-byte** (§4)

| bank | byte range | contents |
|---|---|---|
| 2 | `0x000000-0x7FFFFF` | GFX obj bank 0 |
| 2 | `0x800000-0xFFFFFF` | GFX obj bank 2 |
| 3 | `0x000000-0x7FFFFF` | GFX obj bank 1 **and** the scroll slot (same bytes, two address paths) |
| 3 | `0x800000-0xFFFFFF` | GFX obj bank 3 |

### The whole-tier arithmetic

**CORRECTED 14z-107 (9): the group-C rows are REGIONS, not footprints.**

```
  stock GFX (banks 2+3)                            32.000 MB   (measured: full)
  68k PRG, WIDE v1 declared                         6.000 MB   (mister_fit §1: live
                                                                to PRG:0x4D10F3 plus a
                                                                30-byte pin at 0x5FFF00)
  VRAM + OBJ RAM + work RAM + Z80 windows            0.844 MB   (slot geometries, §5)
  QSound: 8 MB in ba1 + a 1 MB window in ba0         9.000 MB   (.rom carries 8.9375 MB;
                                                                live to 0x8E57F0)
  GFX group C, obj bank 4 REGION                     8.000 MB   (art to 0xEE73 = 7.452 MB)
  GFX group C, obj bank 5 REGION                     8.000 MB   (art to 0xFFDB = 7.996 MB)
  + the 32 KB alignment gap before PCMH_OFFSET       0.031 MB
  ------------------------------------------------------------
  total reserved                                    63.875 MB
    (= banks 2+3 full, 32.000; bank 0 used to 0xFE0000, 15.875;
       bank 1 used to 0x1000000, 16.000)
  tier (JTFRAME_SDRAM_LARGE, 4 x 16 MB)             64.000 MB
  slack                                              0.125 MB   (ALL of it in ba0; ba1 is
                                                                exactly full)
```

The old figure was 63.292 MB placed / 0.708 MB slack. It counted the art's
address footprint where SDRAM reserves the whole region, and the census is
what caught it. What the footprints still tell you is how much of each 8 MB
region is dead — 0.548 MB in obj bank 4 and 0.004 MB in obj bank 5 — i.e.
what a group-C MRA trim could in principle recover. **That trim is NOT the
flat `length=` truncation the QSound one was**: the GFX region is a 4-way
64-bit interleave and the download scramble turns a contiguous tail of tile
codes into a NON-contiguous set of `.rom` offsets, so recovering the 0.548 MB
would need its own measurement. Unmeasured, and not needed today.

### The two moves that make it fit, stated plainly

1. **[MSV-6]** **The QSound region is SPLIT across two SDRAM banks on `pcm_addr[23]`.**
   *(D0 note, 14z-107 (5): the shipped MRA splits the region in TWO for the
   generator's sake — `qsound` then `qsoundw` — but they are adjacent and
   only `qsound`'s start goes in the header, so the RTL sees ONE region of
   0x8F0000 bytes and the extension lands at `pcm_addr` `0x800000`-`0x8EFFFF`,
   i.e. exactly `pcm_addr[23] = 1`. The split bit below works against the
   image D0 actually produces.)*
   DSP sample banks `0x00-0x7F` (the stock 8 MB) stay at bank 1 offset 0 —
   *byte-identical to stock jtcps2* — and banks `0x80+` (the WIDE extension,
   which is the part the profile added) go to bank 0. This is not cosmetic:
   with QSound whole in bank 1, bank 1's spare is 7.0625 MB and a group-C obj
   bank REGION is 8 MB. **Best case with QSound whole is an overflow of
   0.9375 MB**, and no rearrangement of PRG, Z80 or the RAM windows closes
   it, because the deficit is strictly bank 1's and PCM is the only thing in
   bank 1. (This paragraph used to say "the smaller obj bank needs 7.45 MB"
   and "overflow of 0.39 MB" — the same footprint-for-region error the census
   corrected everywhere else, 14z-107 (9). The conclusion is unchanged and
   the margin against it is now larger.) The split bit is exactly the
   stock/WIDE boundary, which is a nice property to have on the superset
   invariant.
2. **[MSV-7]** **Group C is split one obj bank per SDRAM bank**, keyed on
   `gfx_addr[23]` at download time and `rom0_bank[0]` at read time. Obj bank
   **4** — the three fighter bands, i.e. the in-match traffic — goes to
   **bank 1**, the bank whose headroom `tests/audit_sdram_bank_load.sh`
   actually measured. Obj bank **5** — select/wheel art, cold during a match
   — goes to **bank 0**, whose extra load therefore lands on the select
   screen rather than in a match.

### Slot count — the one place this needs a new jtframe file

| bank | slots after the change | module |
|---|---|---|
| 0 | 7 (RAM/VRAM/ORAM RW, VRAM-DMA, gfx-ORAM, main ROM, Z80, PCM-high, obj bank 5) | **`jtframe_ram1_7slots` did not exist** — upstream has `ram1_1..5slots` and `ram2_4..6slots`. **ADDED in D2** as `modules/jtframe/hdl/sdram/jtframe_ram1_7slots.v`, option A below |
| 1 | 2 (PCM low, obj bank 4) | `jtframe_rom_2slots` ✔ exists |

Two ways out, both honest:

- **(A, RULED AND SHIPPED — maintainer, 2026-08-23; landed in D2)** add
  `jtframe_ram1_7slots.v` to the fork — a mechanical member of an existing
  formulaic family. Keeps bank 1 to exactly the two streams (`PCM` + `obj`)
  that the GO measurement modelled.
- **(B)** move the Z80 to bank 1. Bank 0 drops to 6 slots
  (`jtframe_ram2_6slots`, second write port tied off) and bank 1 becomes
  `jtframe_rom_3slots` — zero new jtframe files, but bank 1 then carries
  three streams, which is beyond what was measured.

**[MSV-9]** **WHERE OPTION A PUT THE FILE, and why it is an addition rather than a
change.** `modules/jtframe/hdl/sdram/jtframe_ram1_7slots.v` — with the
family, so a reviewer can diff it against `jtframe_ram1_5slots.v` and see
that it is that file plus two `jtframe_romrq` instances and nothing else.
It is pulled by **`cores/cps2w/cfg/game.yaml` alone** and deliberately NOT
added to jtframe's own `hdl/sdram/jtframe_sdram64.yaml`: that list is
SHARED, and a line there would put the new module on every jtcores core's
compile list, including the reference `cps2`. Measured: `jtframe files sim
cps2` does not contain it and the two cores' file lists differ in exactly 11
entries (4 shared originals out, 6 overrides + 1 new jtframe module in).
`tests/test_mister_wide_gate.sh` 5b/7n hold both halves.

---

## 6. The download-side and read-side changes — **AS BUILT (slice D2)**

Declarative and profile-gated. **This section described a proposal until
14z-107 (9); it is now the as-built record, and the RTL below is what the
fork carries** (`cores/cps2w/hdl/jtcps1_prom_we.v`,
`cores/cps2w/hdl/jtcps1_sdram.v`, fork commit `0df6f000`). The sketch that
was here is reproduced verbatim because it survived contact: the shipped
expressions are the same ones, with `wide_en` spelled out and two details
the sketch left implicit (below).

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
— **that widening is D2's, at the `jtcps1_sdram` port; what is D3's is
DRIVING bit 2**, and until then the game top passes `{1'b0, rom0_bank}` so
`gfxc_sel` is constant 0 and the two group-C slots are provably unreachable.
**[D3 DRIVES IT, 14z-107 (10): the tie is gone and `rom0_bank` is the object
engine's own 3-bit bank. See "The promote — AS BUILT" below.]**

### The promote — **AS BUILT (slice D3)**

```verilog
// cores/cps2w/hdl/jtcps2w_obj_bank.v — the WHOLE behavioural surface of D3
assign bank = { wide_en & table_y[12], table_y[14:13] };

// cores/cps2w/hdl/jtcps2_obj_scan.v, in the ELSE arm of the :141 terminator
// test — which is UNCHANGED from the reference core, and has to be
st3_bank <= promoted_bank;
```

Four things about that, in the order they matter.

1. **[MSC-28]** **The order is the rule, not the bit.** `table_y[15]` is the sprite-list
   terminator and the test above is byte-identical to `cores/cps2`'s. Inside
   the `else` arm bit 15 is known to be 0, so promoting bit 12 into it and
   reading bits 15:13 reduces to `{ y[12], y[14:13] }`. Reading bit 15
   directly — the profile's first draft — would end the list at the first
   tenant sprite. `tests/test_mister_wide_gate.sh` 8b asserts BOTH halves:
   the terminator test is the reference core's verbatim, and the promote is
   read at a LATER LINE than it.
2. **The encoding is a contract with the build, and now it is checked.**
   `tools/gfx_tiles.py`'s `bank_word` emits `0x1000` for bank 4 and `0x3000`
   for bank 5, not `bank << 13` (which would be `0x8000` — a terminator).
   `tests/rtl/tb_obj_bank.v` transcribes that table and requires each of the
   six y-words to decode to its own bank, with a must-fire control that reads
   bit 2 from `y[15]` and fails it.
3. **It cost four override files for one expression**, because a 3-bit bank
   has to be three bits wide at every port between the frame table and SDRAM:
   `jtcps2_obj_scan.v` (the promote), `jtcps2_obj.v`, `jtcps1_obj_draw.v` and
   `jtcps1_video.v`. The last three change nothing but a width — and a width
   left at 2 in any of them would drop bank bit 2 and fetch vanilla art for
   every tenant sprite, which is a picture bug and not a build error. Gate
   checks 8c enumerate all six declarations.
4. **`wide_en` had to be routed into the video block to reach the scanner.**
   `gfxc_sel` already gates the destination, so an ungated promote would have
   been inert anyway; gating the source as well makes bank bit 2 *provably
   zero* with the profile clear rather than *harmlessly ignored*, and makes
   the expression exhaustively testable on its own (131,072 vectors, both
   profile states, bank[2] set 32,768 times wide / 0 stock).

### The three things the sketch left implicit, all settled in D2

1. **Every one of those expressions is ANDed with `wide_en`**:
   `is_gfxc = wide_en & gfx_addr[25]`, `is_pcmhi = wide_en & pcm_addr[23]`
   on the download side, `pcmh_sel = wide_en & pcm_addr[PCM_AW]` and
   `gfxc_sel = wide_en & rom0_bank[2]` on the read side. With the profile
   clear every expression collapses to the reference core's, character for
   character. `tests/test_mister_wide_gate.sh` 7i-7l re-read all four.
2. **The PCM-high window is MASKED to its 1 MB on BOTH sides** —
   `{4'd0, pcm_addr[19:1]} + PCMH_OFFSET` at download, `pcm_addr[19:0]` at
   the slot — which is §7's "mask the high window" recommendation, applied.
   A QSound region longer than `0x8FFFFF` therefore aliases INSIDE the
   extension instead of overwriting group-C art.
3. **`prog_ba`'s fall-through arm needed qualifying with `is_oki`.** The
   firmware (`is_qsnd`) region also falls through that arm, and its
   `pcm_addr` — a wrapped subtraction, not a real region offset — has bit 23
   SET, so an unqualified `is_pcmhi` would have re-banked it. It writes
   nothing (`prog_we` is 0 for `is_qsnd`, `prom_we` is 1), so it would never
   have been observable; it is qualified anyway, because a signal that is
   right only because its enable is off is a defect waiting for a refactor.

### The bank-0 re-pack is the ONE thing that is NOT gated, and why

`SLOTn_OFFSET` are elaboration-time parameters of the jtframe slot modules,
so VRAM/ORAM/WRAM/SND cannot move at run time. They move unconditionally on
CPS-2 (the CPS-1 arm of each ternary keeps the reference value). That is a
RELOCATION, not a behaviour change, and the argument is structural: the 68k
sees identical data at identical 68k addresses; VRAM/ORAM/WRAM are never
downloaded at all; the Z80 region's download and read take the SAME
constant; and bank 0 is the one bank carrying `JTFRAME_BA0_AUTOPRECH=1`
(`cores/cps1/cfg/common.def`), so `jtframe_sdram64_bank.v:170`'s row-match
short-circuit never applies to it and its per-access latency is
address-independent — no row-locality pattern can shift. It is also the one
claim in D2 that is MEASURED rather than constructed, by
`tests/test_mister_wide_inert.sh` (cps2 vs cps2w, bit-identical work RAM
frame by frame) and by the census's C-vs-D cross-check (banks 1, 2 and 3
byte-identical between the two cores on the same stock image; bank 0
differing, which is the control that keeps that comparison from being
vacuous).

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
  placed length works and 8.9375 MB is conformant — **provided no SINGLE
  8-bit slot is asked to address more than 8 MB**, which it cannot be
  (measured 14z-107 (6): that same `:74` expression does not ELABORATE at
  `AW > SDRAMW`; see the retraction below). 8.9375 MB is reached by TWO slots
  in two banks, §5.

**Do banks `0x80-0x8E` stay addressable after the width fix?** Yes.

- The defect: `jtcps15_sound.v:416` `qsnd_addr[22:16] <= dsp_ab[6:0];`
  keeps 7 bank bits, so bank `0x8N` aliases onto `0x0N` and *mis-plays legacy
  audio* rather than going silent (14z-86).
- The fix, **AS SHIPPED in slice D1** (fork `4840df8a`): `qsnd_addr`
  `[22:0] → [23:0]` and the latch `[6:0] → [7:0]`, the latter lifted into
  `cores/cps2w/hdl/jtcps2w_qsnd_bank.v` and gated by `wide_en` so that with
  the profile clear it is bit-for-bit the stock expression, reset value
  included. `dsp_ab` is 16 bits (`jtcps15_sound.v:84`) and only `dsp_ab[15]`
  is consumed as the latch strobe (`:415`), so bits 7..14 are free — 8 bank
  bits is not close to a limit.
- ~~and `PCM_AW` `23 → 24` (`jtcps1_sdram.v:23`)~~ — **WRONG, AND IT IS A
  BUILD FAILURE, NOT A TRADE (measured 14z-107 (6)).** jtframe's 8-bit SDRAM
  slot cannot be widened past `SDRAMW`: `jtframe_romrq_bcache.v:74` is
  `sdram_addr = offset + { {SDRAMW-AW{1'b0}}, addr_req>>(DW==8) }`, and
  `SDRAMW-AW` is a REPLICATION COUNT that goes negative at `AW=24`,
  `SDRAMW=23`. Verilator: *"Replication value of < 0 or X/Z not legal"*,
  exit 1 (AW=24 and AW=25 both measured on `jtframe_rom_1slot`). So a
  byte-addressed slot reaches 8 MB of a 16 MB bank — which is exactly WHY §5
  splits QSound across two banks rather than growing one slot, and the two
  halves of this document were inconsistent until now. D1 therefore leaves
  `PCM_AW` at 23 and feeds the slot `qsnd_addr[22:0]`; bit 23 is produced,
  gated, and routed by D2. `tests/test_mister_wide_gate.sh` 3d/3e keeps the
  wrong version from being re-proposed.
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

**[MSC-31]** **The objcfg port decodes a whole megabyte, not sixteen bytes** — the RTL is
looser than the hardware here — but because it is qualified with `!RnW`, a
*read* anywhere in `$400000-$4FFFFF` asserts nothing today and would assert
only `rom_cs` after the change. So there is no read collision at all, and a
write still reaches only `objcfg_cs`.

### The minimal, profile-gated proposal — **IMPLEMENTED, slice D4**

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

**AS SHIPPED (14z-107 (10), `cores/cps2w/hdl/jtcps2_main.v`) the three lines
are exactly the sketch above, with `CPS2W` spelled `wide_en`** — the runtime
profile bit, not a macro — and `SLOT3_AW` written `CPS==2 ? 22 : 21` so a
CPS-1 build of the same copy keeps the reference width. Two things the sketch
did not say and the slice had to settle:

* **"The extension is NOT decrypted, and that is correct rather than lucky" —
  RETRACTED 14z-107 (11). IT IS DECRYPTED, and that is what stopped the WIDE
  romset booting.** `jtcps2_dec_ctrl.v:44` is
  `en_latch <= op_fetch && en && (addr[14+:10] <= range[9:0])` — OPCODE
  fetches only, below the key header's range word — and the range word is
  stored **COMPLEMENTED**. MAME and FBNeo read it that way
  (`cps2_crpt.cpp:771`, `~decoded[9] & 0x3ff`); jtcps2 does not. For `vsavj`
  the word is `0x03C0`, so the emulators stop at `CPU:$0FFFFF` (63 blocks of
  16 KB) and the reference core runs on to `$F03FFF` (960). Every stock CPS-2
  game hides it — only Capcom's own encrypted code executes, and DATA reads
  are never decrypted on any implementation, which is also why 14z-56's
  B4 (prg) passed on FBNeo while relocating only data tables. **Measured
  14z-107 (11):** ten opcode fetches at `CPU:$4BE7C0-$4BE7C8`, raw words the
  `.rom`'s byte for byte, latched words the decryptor's. Fixed in **slice
  D5** by one profile-gated expression in
  `cores/cps2w/hdl/jtcps2_decrypt.v`; `jtcps2_dec_ctrl` itself is untouched.
  See `docs/platform/mister.md` "CAN THE 68k READ ABOVE 4 MB?".
  Unaffected by the retraction: the gate re-reads the `!RnW` qualifier on
  `objcfg_cs`, because the read decode is collision-free only while that
  qualifier stands.
* **`SLOT3_AW` had to move with `main_rom_addr` or the top address bit would
  be dropped silently** — a 22-bit address into a 21-bit slot port truncates.
  `tests/test_mister_wide_gate.sh` 8j/8k check both halves.

### Is the reserved 16 bytes enough? — yes, and it is now load-bearing three times

**[MSV-13]** `cps2_wide.md` reserves `$400000-$40000F` and forbids allocation there. With
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

1. ~~**Does bank 0 absorb obj bank 5's select-screen traffic?**~~
   **ANSWERED YES, 14z-107 (12), MEASURED ON A BOOTING WIDE IMAGE — bank 0
   does not come close to saturating, and the redirect costs it about 2.5%.**
   `tests/audit_sdram_bank_load.sh --core cps2w --wide build/m3b_merged13`,
   `05_timeout_idle`, 3,500 frames, transfer asserted at 659, the run's own
   match-start anchor measured at **2806** — exactly the frozen 2609 plus the
   197-frame transfer difference, so the four phase boundaries label the
   phases they name rather than being assumed to.

   | phase | ba0 | ba1 (PCM) | ba2 | ba3 | data bus |
   |---|---|---|---|---|---|
   | attract (661-1461) | 38,261 | 3,466 / 78.6% | 0 | 9,446 / 25.2% | 12.7% |
   | select+VS (1463-2805) | **40,717** | 13,870 / 99.0% | 357 / 84.1% | 10,917 / 37.1% | 16.4% |
   | in-match (2812-3499) | **41,535** | 13,890 / 98.0% | 296 / 39.9% | 17,335 / 34.2% | 18.2% |

   **The answer, in one line: bank 0 runs at 40,717 accesses/frame through the
   select screen — 32.9% of its 123,825 all-miss ceiling — with a whole-run
   PEAK of 54,363 (43.9%) and ZERO `SDRAM reads clashed` in 3,500 frames.**
   Against the stock baseline (`docs/platform/mister.md`, stock `vsavj` on
   `cores/cps2`: 39,696 select / 40,976 in-match) the redirect adds about
   **1,000 accesses/frame**, ~2.5%, which is what obj bank 5's wheel art costs
   when it is served out of bank 0 — the read probe counts 6,720 burst BEATS
   per select frame in that window, and at 4 words per BA0 access that is
   ~1,680 accesses, the right order for the delta measured here. The bus stays
   at 16-18%. **The repack's bank-0 half is GO on measurement, not on
   argument.**

   **WHAT THIS RUN DOES *NOT* BOUND, stated because the asymmetry matters:
   bank 1's group-C half was never fetched.** `05_timeout_idle` picks Demitri,
   a legacy character, so obj bank 4 (the fighter art) is never touched and
   ba1's 13,890 accesses/frame are PCM and nothing else — the same figure the
   stock core produces. **The half of the repack risk that this instrument was
   built to bound — obj fetches interleaving with the PCM stream inside bank
   1 — is therefore STILL UNMEASURED**, and it stays unmeasured until a
   tenant can be selected on the core (see the input defect in
   `docs/platform/mister.md`, "The simulated joystick's direction nibble is
   MSB-FIRST" — the bits arrive and are PERMUTED, the whole nibble end for
   end; they are not lost. Fixed 14z-108).
   *(Superseded text kept below; its eliminations stand.)*
   **[14z-107 (10): THE INSTRUMENT NOW HAS ITS SECOND LEG
   (`--core cps2w --wide build/m3b_merged13`) AND THE QUESTION IS STILL
   OPEN, for a reason that is not the instrument's.** The WIDE romset does
   not get past its own boot sequence on the core (`docs/platform/mister.md`
   "The pre-D5 boot loop"; `mister_history.md` for the trace), so a run on it never
   reaches a select screen or a match: its four frozen phase boundaries
   label a looping boot, and **no obj bank 5 traffic exists to measure**.
   The leg is written, gated on the transfer length, and prints a PEAK
   per-bank table that depends on no boundary at all — so the moment the
   boot failure is fixed the answer is one run away. Until then the honest
   status is UNMEASURED, and the D2-era headroom bound is all there is.
   **What the run DID measure, on the phases the core reaches: bank 0 peaks
   at 54,422 accesses/frame = 44.0% of its all-miss ceiling, bank 1 at
   12,043 (9.7%), bank 3 at 8,548 (6.9%), and bank 2 at exactly ZERO** —
   that last figure being the boot failure expressed as a number, since
   bank 2 is vanilla obj banks 0 and 2 and not one sprite is ever drawn.
   Zero `SDRAM reads clashed` in 2,800 frames.
   **The run also found a defect in the instrument**, which is now fixed:
   the reporter's lines are block-buffered into a log the frame counter also
   writes, so a TORN line can still parse with one spliced field. A phase
   figure survives that (it is a first/last difference over hundreds of
   intervals); a PEAK does not, and one bad row reported a bank-3 peak of
   16,870,809 accesses/frame — **13,624% of the physical ceiling** — without
   comment. The gate now requires the cumulative counters to be MONOTONIC as
   well as the timestamps, drops the rows that are not and says how many.]**
   **[CORRECTED 14z-107 (10): this paragraph carried 98.8% / 40,797, the
   figures measured BEFORE the anchor moved 2502 -> 2609. `mister.md`
   re-derived the whole table at 14z-107 (7) from the same committed log
   (`build/sdram_bank_load_14z107.log`) once the fork-rewind defect was
   fixed; in-match is 98.3% / 40,976. Every figure moved by well under 1%
   and NO conclusion changed — the GO verdict stands on the re-derived
   numbers. Found by `docs/project/mister_core.md`, which quotes the
   corrected pair.]**
2. ~~**Does `parts=` with `map="12"` reproduce the untrimmed qsound region
   byte-for-byte?**~~ **ANSWERED YES, 14z-107 (5), and it cost a design
   change on the way.** `parts=` on the WHOLE qsound region does not work at
   all (§3, corrected in place); with the extension split into its own
   `qsoundw` region the single-part window IS a pure truncation, measured
   byte-for-byte against the zip. Gate `tests/test_mister_mra_map.sh`.
3. ~~**Does `dsp_ab[7]` actually carry sample-bank bit 7 in the real
   `dl-1425.bin` program?**~~ **ANSWERED YES, 14z-107 (6), from MAME's
   low-level QSound device** (`emu/mame/src/devices/sound/qsound.cpp`): the
   DSP16A external ROM space is `map(0x0000,0x7fff).mirror(0x8000)`, the bank
   register is loaded `m_rom_bank = (m_rom_bank & 0x8000U) | offset;` — the
   external-space address STRAIGHT, no permutation, no gaps — and the sample
   byte is `read_byte((u32(m_rom_bank) << 16) | m_rom_offset)`. So the bank is
   a plain binary number in `ab[14:0]` and bit 7 is `ab[7]`. The commented-out
   permutation at `jtcps15_sound.v:416-417` (which also drops `ab[3]`) is a
   guess and is not what the hardware does. `tests/test_mister_wide_gate.sh`
   check 4 re-reads those three MAME lines on every run. *Recorded while
   there and NOT fixed: MAME models a ONE-READ bank latency that jtcps15 does
   not — a pre-existing difference in the reference core, unchanged by the
   width fix, out of D1's scope (`docs/platform/mister.md`).*
4. ~~**`jtframe_ram1_7slots` (new fork file) or move the Z80 to bank 1?**~~
   **RULED: option A (maintainer, 2026-08-23), and SHIPPED in D2.** The file
   is `modules/jtframe/hdl/sdram/jtframe_ram1_7slots.v` — with the family,
   mechanically derived from `jtframe_ram1_5slots.v`, and pulled by
   `cores/cps2w/cfg/game.yaml` alone so no other core's compile list moves.
   See §5, "Where option A put the file".
5. ~~**The fit has 0.708 MB of slack and depends on four frozen extents.**~~
   **RE-STATED 14z-107 (9), measured: the fit has 0.125 MB of slack, bank 1
   is EXACTLY FULL, and it does NOT depend on the tenant-art extents at
   all.** The MRA downloads the whole declared region, so each group-C obj
   bank reserves 8 MB whatever the art does inside it. Consequences, both
   ways round:
   * **Tenant art can grow freely inside the existing 16 MB** — a new tile
     above `0xEE73` or `0xFFDB` no longer overflows anything. The silent
     months-later bring-up failure this question was written about cannot
     happen by that route.
   * **[MSV-11]** **The group-C ROMSET REGION cannot grow at all.** A fifth group-C
     member, or widening it past 16 MB, overflows immediately and there is
     nowhere to put the excess: bank 1 has zero free and bank 0 has 131,072 B.
   * **[MSV-4]** The four extents stay frozen in `tests/audit_mister_map_fit.sh` because
     they bound the content and are what a group-C MRA trim would work from;
     they are no longer what decides the fit. That gate now models the banks
     from the PLACED offsets and lengths, with an overlap check, and its
     control B perturbs the REGION rather than the footprint.
6. **Does the MiSTer DDR staging path (`ddr_load=true`,
   `address="0x30000000"`, `corerom.go:23-35`) impose its own size limit at
   63.2 MB?** Unread.
7. **Does widening `main_rom_addr` interact with `jtcps2_dtack.v`?** Unread.
8. ~~**Should the profile be selected at RUNTIME from a spare header byte
   rather than by `ifdef` in `cps2w`?**~~ **RULED YES (maintainer,
   2026-08-23) AND IMPLEMENTED IN D1**: header byte 41, bit 0, ACTIVE LOW —
   `0xFF` = profile off, the WIDE MRA writes `0xFE`; measured end to end
   (`tests/test_mister_mra_map.sh`), decoded by `jtcps2w_profile.v` into
   `wide_en`. The full argument — why the polarity is forced, why the byte is
   free, how the row is scoped — is `docs/platform/mister.md` "The runtime
   profile gate", the canonical home.

---

## 10. The slice plan

Each slice is independently verifiable, carries its own gate and its own
must-fire control, and every one of them re-runs
`tests/test_mister_sim_anchor.sh` on **stock `vsavj`** as the emulator
superset leg (frozen MAME 2146 / sim **2609** / skew **463** ± 30 — re-measured 14z-107 (7); 2502/356 was measured while the harness replayed the input script,
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
| **D0 — DONE 14z-107 (5)**, fork commit `38acc638` | `cores/cps2w/cfg/mame2mra.toml`: the `qsoundw` trim region + the `cps2w.cpp` sourcefile opt-in, and the `vsavjw` entry in `doc/mame.xml`. **No RTL.** | DONE: `rom/vsavjw.rom` = **66,265,152 B**, header words **6144 / 6400 / 15552 / 64704**, every region start 1 KiB-aligned, every region byte-for-byte the romset's. | BOTH FIRED. (A) untrimmed → 73,670,720 B and `qsnd_start` 71,936 KiB, and the generator **silently writes the wrapped word 6400**. (B) `length` +0x400 → the frozen table fails. | HELD: stock `vsavj` MRA from `cps2w` is byte-identical to `cps2`'s except `<rbf>`, `cps2` emits **no** WIDE MRA at all, and stock `vsavj.rom` is still 46,407,744 B. Gates `test_jtcores_twin` + `test_mister_mra_map`. |
| **D1 — DONE 14z-107 (6)**, fork commit `4840df8a` | QSound sample-bank width, RUNTIME-GATED. `cores/cps2w/hdl/` gains `jtcps2w_profile.v` (header byte 41 → `wide_en`) and `jtcps2w_qsnd_bank.v` (the gated latch), plus OVERRIDES of the two SHARED files it needs (`jtcps15_sound.v` from cps15, `jtcps2_game.v` from cps2). `PCM_AW` STAYS 23 — 24 does not compile (§7). No placement change. | DONE, and stronger than the row planned: the gated latch is simulated over **all 65,536 values of `dsp_ab` in both profile states** — with `wide_en` low `qsnd_addr[23]` is stuck at 0 and bits [22:16] equal the stock expression; with it high, bit 23 moves (16,384 vectors). Plus: `jtframe files` resolves cps2w to our four files and to NEITHER shared original, and the frozen line-by-line override delta. | FOUR FIRED. (A) the latch with the gate bypassed fails the `wide_en`-low leg; (B) the profile byte moved to 40 (jtframe's `JOY_BYTE`) fails; (C) the polarity flipped — so a 0xFF-filled stock header would arm the profile — fails; (D) a one-width perturbation of an override breaks the frozen delta. Gate `test_mister_wide_gate` (ci_portable). | `tests/test_mister_sim_anchor.sh` runs on **cps2w**, stock `vsavj`, against the cps2 expectations. It went RED first, at 2609/463, and root-causing it is the story of the slice: a 2x2 factorial over {stock RTL, D1 RTL} x {`pal_lut.hex` present, absent} showed the RTL axis changes NOTHING and the missing palette LUT changes EVERYTHING. (**Completed 14z-107 (7)**: the palette LUT changed only the NUMBER OF FORKS, and each fork's `exit(0)` rewound the parent's `sim_inputs.hex` — the simulated controller was being replayed. Fixed in the fork.) The new instrument is `tests/test_mister_wide_inert.sh` — cps2 vs cps2w, same download, BIT-IDENTICAL work RAM frame by frame. See STATE 14z-107 (6) G4-G7. |
| **D2 — DONE 14z-107 (9)**, fork commit `0df6f000` | Placement, AS SHIPPED: bank-0 offsets re-packed for PRG 6 MB (VRAM `0x600000`, ORAM `0x640000`, WRAM `0x648000`, Z80 `0x658000`), the group-C redirect and the QSound split in `cores/cps2w/hdl/jtcps1_prom_we.v`, their read sides + the PCM-high slot + the two GFX slots in `cores/cps2w/hdl/jtcps1_sdram.v`, and `modules/jtframe/hdl/sdram/jtframe_ram1_7slots.v` (option A, pulled by cps2w's `game.yaml` alone). `rom0_bank` is 3 bits at the SDRAM port but bit 2 is TIED LOW — the promote is D3, so D2 changes no fetch. The frozen override delta grew from 2 files to 4. | **DONE, and it is a WHOLE-IMAGE census, not a spot check.** `tests/test_mister_sdram_census.sh` + `tools/mister_sdram_census.py` replay the download mapping (regions, the QSound split, the group-C redirect and the CPS-2 GFX scramble) and compare **all 67,108,864 bytes of all four banks** against §5. Result on the WIDE image (`vsavjw.rom`, 66,265,152 B, sha1 `d462e55a…`, transfer complete at simulated frame **659**): **PASS on every bank** — ba0 6,359,055 non-zero (37.9%), ba1 12,879,645 (76.8%), ba2 14,873,334 (88.7%), ba3 14,426,104 (86.0%). | FIRED. A 1 KiB shift of ANY placement constant is rejected: `z80` (206,536 bytes differ, first at `0x658000`), `pcm_hi` (714,457, first at `0x6E0002`), `gfxc5` (675,767, first at `0x7E0080`), `prg` (3,768,659, first at `0x0`), `pcm_lo` (bank 1). Plus the cross-checks in the gate: banks 1/2/3 byte-identical between cps2 and cps2w on the same stock image with bank 0 DIFFERING (the re-pack is confined to bank 0, and the comparison is not vacuous), and banks 2+3 DIFFERING between the two cores on the WIDE image (without the redirect group C aliases onto vanilla's art). | `tests/test_mister_sim_anchor.sh` GREEN on `cps2w` at MAME 2146 / sim 2609 / skew 463; `tests/test_mister_wide_inert.sh` GREEN (`cps2w` == `cps2`, bit-identical work RAM 540-640). **The census also CONTRADICTED this document and the census won** — see the retraction box at the top: the slack is 0.125 MB, not 0.708 MB, and bank 1 is exactly full. |
| **D3 — RTL DONE 14z-107 (10)**, fork commit `b9899fa8` | The obj promote, AS SHIPPED: the CPS-2 Turbo rule lifted into `cores/cps2w/hdl/jtcps2w_obj_bank.v` (`bank = { wide_en & table_y[12], table_y[14:13] }`) and read in the ELSE arm of the `:141` terminator check, which is the reference core's VERBATIM; `dr_bank`/`obj_bank`/`rom_bank`/`rom0_bank` widened to 3 bits across FOUR override files; the game top's `{1'b0, rom0_bank}` tie REMOVED so bit 2 reaches `gfxc_sel`. | **THE PROOF IS THE EXHAUSTIVE BENCH; THE FETCH HAS NOT HAPPENED.** ("DONE, and it is a REAL FETCH on the REAL ROMSET" — **RETRACTED 14z-107 (11)**: `tests/test_mister_gfxc_fetch.sh` is RED, and its own vanilla-obj-bank control reads zero too, because the WIDE romset never boots.) `tests/test_mister_gfxc_fetch.sh` counts the SDRAM reads the core issues into the two group-C windows (derived from the RTL, not typed in) while a tenant-picking replay runs, and checks the tile codes against the roster's frozen live extents. Plus the exhaustive bench: `jtcps2w_obj_bank` over all 65,536 y-words in both profile states, 131,072 vectors, bank[2] set 32,768 times wide / **0** stock, and the six `gfx_tiles.py` encodings each decoding to their own bank with none of them setting the terminator bit. | **THE CONTROL IS ONE BYTE.** The same `.rom` with header byte 41 changed from `0xFE` to `0xFF` must read ZERO from both group-C windows; two further probes on the VANILLA obj banks must be non-zero in BOTH legs, so a zero is evidence about the core and not about the probe. On the bench: the promote's gate bypassed, and the promote reading `y[15]` instead of `y[12]` — the profile's first draft — both fire. | `test_mister_sim_anchor` on `cps2w`, stock `vsavj`; `test_mister_wide_inert` (cps2 vs cps2w, bit-identical work RAM). **The planned canary was NOT built**: it was designed for a world where the WIDE set could not boot, and once D4 shipped in the same session the real romset became the better witness. |
| **D4 — RTL DONE 14z-107 (10)**, fork commit `dd242a65` | The PRG window, AS SHIPPED: `cores/cps2w/hdl/jtcps2_main.v` — `rom_cs` gains `wide_en & RnW & (A[23:21]==3'b010)`, `rom_addr` widens to `A[22:1]`, `one_wait`'s boundary becomes `wide_en ? 4'h6 : 4'h5`; `main_rom_addr` `[22:1]` and bank 0's `SLOT3_AW` `CPS==2 ? 22 : 21` follow it. | **THE DECODE DELIVERS — measured 14z-107 (11).** The original claim here, "the proof is that the WIDE set BOOTS AND PLAYS", was **RETRACTED** because it was not true when written; it is *now* true of the BOOT half — with D5 in, the WIDE romset boots to the select screen — and still false of "PLAYS": no tenant has ever been in a match on the core. The 68k program-ROM read probe caught the 68k fetching from `CPU:$4BE7C0-$4BE7C8` — ten reads, and every RAW word is the `.rom`'s byte for byte, against 54,961,148 reads below `$400000` as the must-fire control. What the CPU RECEIVED was the decryptor's output, which is slice D5's bug and not this decode's. The control leg (`wide_en` clear, one byte of `.rom` different) completes ZERO reads there. `docs/platform/mister.md` "CAN THE 68k READ ABOVE 4 MB?". | The `wide_en`-clear leg of the same pair: with the profile bit off the decode collapses to the stock flat 4 MB and the same replay produces no group-C fetch at all. | `test_mister_sim_anchor` on stock `vsavj` — this is the slice where a widened decode could most easily perturb legacy behaviour, and it is why the read decode is qualified `RnW` and the objcfg port's `!RnW` is re-read by the gate on every run. |

| **D5 — DONE 14z-107 (11)**, fork commit `c00d7ce7` | The DECRYPTION RANGE: `cores/cps2w/hdl/jtcps2_decrypt.v` complements the key's range word on its way into `jtcps2_dec_ctrl`, gated on `wide_en` — `rng_eff = wide_en ? { addr_rng[15:10], ~addr_rng[9:0] } : addr_rng`. `jtcps2_dec_ctrl` itself is NOT overridden; `dec_en` still comes from the uncomplemented word. | The 68k program-ROM read probe on the WIDE romset: ten opcode fetches at `CPU:$4BE7C0-$4BE7C8`, RAW words the `.rom`'s byte for byte and LATCHED words the decryptor's, against 54,961,148 reads below `$400000` whose 2,000-record sample verifies 2000/2000. `tests/test_mister_prg_window.sh` freezes the pair; `test_mister_wide_gate` section 9 re-reads the four lines and the REFERENCE comparison D5 corrects for. | The `wide_en`-clear leg of the same one-byte pair: ZERO completed reads above `$400000` and zero SDRAM reads in the same window, because the decode is gated. Plus the gate's 9G: strip `wide_en` from the range fix and the frozen delta must move; and 9e, which fails if anyone overrides `jtcps2_dec_ctrl`. | `test_mister_sim_anchor` on stock `vsavj` and `test_mister_wide_inert` — both untouched BY CONSTRUCTION, since `rng_eff` IS `addr_rng` with the profile clear. |

**Only after D0–D4 does a WIDE set boot — and that sentence turned out to be
the load-bearing one in this section.** It was written as a summary; it is
also the reason D3 could not be demonstrated on its own, because the select
screen's roster record is allocated above `CPU:$400000` and D3 without D4
leaves the core unable to read the table that names the tenant cells. The two
slices therefore shipped in the same session, as separate fork commits with
separate gates.

The first *whole-system* gate is `tests/audit_sdram_bank_load.sh` re-run on
the `cps2w` core carrying the map **and the WIDE romset**
(`--core cps2w --wide build/m3b_merged13`), which is both the answer to open
question 1 and the go/no-go the bank-repack ruling asked for.

---

## 11. If it did not fit — what the fallback implies

It does fit, by **0.125 MB (131,072 B), with bank 1 exactly full** —
0.708 MB is RETRACTED, see the box at the top and §5. Recorded here
anyway, because the margin is now thinner still:

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
