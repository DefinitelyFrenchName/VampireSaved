# MiSTer — the jtcps2 core, as it concerns this port

Platform fact file (docs/README.md taxonomy: true whether or not the roster
hack exists). Opened 14z-106 (2026-08-22) when the MiSTer arc was framed.
Every figure below names its source; "read 2026-08-22" means the jtcores
tree at tag `v1.7.3` (commit `63688ce5`) unless stated.

## The ruling this file serves (maintainer, 2026-08-22)

The MiSTer deliverable is an **extension of Jotego's jtcps core** — a
SEPARATE core, so the reference CPS-II core stays separately usable — not
an FPGA re-implementation of the MAME emulation. jtcores and jtframe are
**GPL-3.0** ("you are obliged to publish your code if you use mine"), so
the fork is public and FOSS by obligation. Simulation is the gate;
hardware (MiSTer, 128 MB SDRAM, Jammix card → CRT at native timing) is the
field test. Distribution = MRA + RBF over the same release members as
`release/<name>/`, plus a stock-`vsav` reference-leg MRA.

## Where things are

| thing | where |
|---|---|
| the fork | https://github.com/DefinitelyFrenchName/jtcores, branch `vampire-saved`, from upstream tag `v1.7.3` = `63688ce5` |
| pinned here | submodule `emu/jtcores` (branch `vampire-saved`); `tools/setup_jtcores.sh` checks the pin, inits the five modules the cps2 yaml chain pulls, and regenerates `emu/jtcores-patches/` as a PATCH SERIES, one file per fork commit (`modules/jtframe/target/pocket` is a PRIVATE ssh submodule — never init it) |
| the fork's commits | `b9d0565` `cores/cps2w` scaffold (14z-106) · `553dd56` sim work-RAM dumps · `6c32be8` sim SDRAM top address bit · `4f25cc7` sim model clock · `74ed17d` sim SDRAM stats · `38acc638` **the WIDE machine entry + the MANDATORY QSound trim in the MRA** (14z-107 (5), slice D0). **No RTL touched by any of them.** The mirrored series is `emu/jtcores-patches/0001`-`0006` |
| the new core | `cores/cps2w/` in the fork → RBF `jtcps2w.rbf` (jtframe names the RBF `"jt" + <core dir>`; `CORENAME=JTCPS2W` is what the MRA's `<rbf>` is matched against, upper-cased) |
| the reference core | `cores/cps2/` — untouched, by design |
| jtframe | `modules/jtframe` is VENDORED in the jtcores tree at v1.7.3 (not a submodule); its Go tool builds with `cd modules/jtframe/src/jtframe && go build -o jtframe .` (Go ≥ 1.2x; `brew install go`). The `bin/jtframe` wrapper uses GNU `date -d` / `stat -c` and needs coreutils on macOS — call the built binary directly instead |
| env the tools expect | `JTROOT=<jtcores>`, `JTFRAME=$JTROOT/modules/jtframe`, `JTBIN=$JTROOT/release`, `CORES=$JTROOT/cores`, `ROM=$JTROOT/rom` (what `setprj.sh` exports) |

## How the CPS-2 core is put together (read 2026-08-22)

`cores/cps2` is thin. Its own RTL is `hdl/jtcps2_{game,main,obj,objram,
obj_frame,obj_scan,colmix,raster,dtack}.v` plus the encryption blocks
(`keyload, decrypt, fn1, fn2, fn_sbox, sbox, dec_ctrl`). Everything else is
pulled by `cfg/game.yaml`: `from: cps1 → common.yaml` (the CPS-1 video/
SDRAM/tilemap/object pipeline, `jtcps1_sdram.v` included) and
`from: cps15 → qsound.yaml` (`jtcps15_sound.v` + jtdsp16). **That is the
separate-core mechanism**: `cores/cps15` exists exactly this way (its
`game.yaml` pulls `jtcps1_obj.v`, `jtcps1_main.v`, `common.yaml` from cps1),
and `cores/cps2w/cfg/game.yaml` is cps2's verbatim — every `from: cps2`
entry still resolves to `cores/cps2/hdl`. A file is copied into
`cores/cps2w/hdl` only when it must differ; the diff between the two core
dirs IS the trust surface.

`cfg/macros.def` (cps2): `include ../../cps1/cfg/common.def`, `CPS2`,
`GAMETOP=jtcps2_game`, `CORENAME=JTCPS2`, `JTFRAME_SDRAM_LARGE`,
`JTFRAME_HEADER=44`, `JTFRAME_IOCTL_RD=128`, `JTFRAME_DIPBASE=16`,
`JTFRAME_DIAL`, `CPS1_NOOBJ`, `JTFRAME_OSD_TEST`, MiSTer: `JTFRAME_MR_DDRLOAD`.
cps2w differs by `CORENAME=JTCPS2W` only.

## The numbers that bound a MiSTer-shaped profile

- **SDRAM tier.** `JTFRAME_SDRAM_LARGE` "enables 64 MB access" is the only
  tier at our pin (`modules/jtframe/doc/macros.md:152`). `jtcps1_sdram.v`
  exposes four 23-bit WORD bank buses (`ba0..ba3_addr[22:0]` = 16 MB each),
  `ioctl_addr[25:0]` (64 MB) and `prog_addr[22:0]`; `localparam SDRAMW = 23
  (LARGE) / 22` sits in `target/mister/jtframe_emu.sv:168-172`, the matching
  `[22:0]`/`[21:0]` bank ports in `hdl/inc/jtframe_mem_ports.inc`. MiSTer's
  HPS already exposes `ioctl_addr[26:0]` ("up to 128MB",
  `jtframe_emu.sv:334`) while the core-facing port is `[25:0]`.
  **At v1.7.3 64 MB is the PHYSICAL ceiling, not a configuration choice** —
  see "The SDRAM ceiling at our pin" below. **CORRECTED 14z-107:
  `JTFRAME_SDRAM_XL` DOES exist — UPSTREAM, not here.** The 14z-106 grep
  (`grep -rn SDRAM_XL modules/jtframe` = 0 hits) was right about the PIN and
  wrong as a statement about jtframe: upstream master carries a `SDRAMW=24`
  128 MB tier added 2026-06-19. See "The 128 MB tier EXISTS upstream" below;
  `docs/project/cps2_wide.md` carries the matching correction.
- **68k PRG.** `main_rom_addr[20:0]` words = **4 MB**, the cap the 14z-85
  ruling measured against (D+H alone overflow it by ~310 KB). The merged-m6
  image's wide_ext high-water mark is `0x4D1100` with `vsw.44`
  (`0x580000-0x5FFFFF`) also written — the real extent is measured in
  slice B (`docs/project/mister_fit.md`).
- **GFX.** Banks 2+3 = 32 MB, and stock `vsav` ALREADY uses 32 MB on jtcps2
  (`cores/cps2/README.md` ROM table: VSav 1 = 4.0 MB CPU / 256 kB Z80 /
  32 MB GFX / 8 MB Q-Sound). On the documented tier there is NO free GFX
  bank for group C: tenant art fits only INSIDE vanilla's 32 MB (blank /
  unreferenced codes, the 14z-62e option-B measurement generalised) or on
  a widened tier.
- **QSound.** Stock 8 MB; the sample path is 23-bit with a 7-bit bank
  latch (`jtcps15_sound.v:47,361-367`, source-verified 14z-86 at jtcores
  `1ae053f3` + jtdsp16 `71fa564a`; v1.7.3 pins jtdsp16 at `87fef51d` — the
  14z-86 reading is re-verified against THAT pin before any RTL is touched),
  so banks ≥ 0x80 ALIAS onto 0x00-0x7F. ~4-line RTL width fix; content
  restored below bank 0x80 (the 14z-86 pilot at bank 0x18) is MiSTer-
  compatible as-is. 16 MB QSound is also MAME's ceiling (cps2_wide.md).
  **Re-verified 14z-107 against the v1.7.3 pin, and with one addition that
  matters: 16 MB of QSound FITS SDRAM bank 1 on the EXISTING 64 MB tier** —
  PCM is alone in that 16 MB bank. See "What the CPS-2 core caps" below.

## The SDRAM ceiling at our pin: 64 MB is PHYSICAL (measured 14z-107)

At `v1.7.3` the 64 MB tier is not a default with a wider one behind it — it
is the largest map the pin can address, and every link in the chain says so.

- **jtframe's own table stops there.**
  `modules/jtframe/hdl/sdram/jtframe_sdram_bank_core.v:32-34`:
  `AW 22 | 4 MBx2 = 8MB | 32 MB` and `AW 23 | 8 MBx2 = 16MB | 64 MB`.
  There is no row for 24.
- **Row/column geometry saturates at SDRAMW=23.**
  `jtframe_sdram64_bank.v:75-76` `localparam ROW=13, COW= AW==22 ? 9 : 10;`
  — a two-arm ternary with no arm for AW=24. With `:127`
  `addr_row = AW==22 ? addr[AW-1:AW-ROW] : addr[AW-2:AW-1-ROW]` and `:219`
  `{ ..., addr[AW-1], addr[8:0] }`, an AW=24 build would drive row
  `addr[22:10]` and column `{addr[23], addr[8:0]}` — **`addr[9]` is never
  driven onto the bus at all**, so every address would alias with
  `addr ^ 0x200`. Quiet per-512-word corruption, not a build error.
- **The pins are not there either.** `target/mister/jtframe_emu.sv:101-106`
  declares `SDRAM_A[12:0]`, `SDRAM_BA[1:0]` and ONE `SDRAM_nCS`; `sys/sys.tcl`
  assigns exactly 13 A pins (`:60-72`), 2 BA pins (`:73-74`) and one nCS
  (`:97`). 13 row + 10 column + 4 internal banks x 16 bits = 64 MB. Saturated.
- **No single chip is bigger.** `modules/jtframe/doc/sdram.md` "SDRAM
  Catalogue" (`:222-233`): every 128 MB module listed is **2 or 4 UNITS**
  (chips); the largest single-chip entry is 64 MB (ID 6, 2 x AS4C32M8SA).
  128 MB on MiSTer is definitionally more than one chip.
- **And the vendored MiSTer dual-SDRAM support is UNREACHABLE at this pin.**
  `jtframe_emu.sv` declares no `SDRAM2_*` port at all (grep = 0 hits), and
  `mister.qsf:51-52` sources `sys/sys.tcl` + `sys/sys_analog.tcl` and NOT
  `sys/sys_dual_sdram.tcl`. Those last two **cannot both be sourced** — they
  claim the same physical pins:

  | pin | `sys_analog.tcl` | `sys_dual_sdram.tcl` |
  |---|---|---|
  | PIN_Y15  | `LED_USER` (`:61`)  | `SDRAM2_DQ[0]` (`:4`) |
  | PIN_AG28 | `LED_POWER` (`:63`) | `SDRAM2_DQ[4]` (`:8`) |
  | PIN_AH27 | `VGA_EN` (`:43`)    | `SDRAM2_DQ[15]` (`:13`) |
  | PIN_AG25 | `BTN_OSD` (`:66`)   | `SDRAM2_DQ[13]` (`:15`) |

  **Consequence worth stating plainly: on a DE10-Nano the dual-CHIP SDRAM
  path and the ANALOG I/O board are mutually exclusive.** That is not
  academic here — the field test in the ruling at the top of this file is
  Jammix -> CRT, i.e. analog video. Any 128 MB route that needs two
  physically separate modules is also a route that gives up the CRT field
  test. The two-chips-on-ONE-module route below does not have this problem:
  it uses the single SDRAM socket and the same 13 address pins.

## The 128 MB tier EXISTS UPSTREAM, and it is sound (read 2026-08-23)

Source: `jotego/jtcores` **master** (not our pin). **This partially
UN-RETRACTS the 14z-106 retraction** — see the box at the end of the section.

- `modules/jtframe/target/mister/hdl/jtframe_emu.sv:175-181` (note the path
  MOVED upstream — `target/mister/` gained an `hdl/` level):

      `ifdef JTFRAME_SDRAM_XL
          localparam SDRAMW=24; // 128 MB
      `elsif JTFRAME_SDRAM_LARGE
          localparam SDRAMW=23; // 64 MB

- **The mechanism is TWO CHIPS ON ONE MODULE, selected by the top address
  bit, with the chip select carried on /CS POLARITY.**
  `modules/jtframe/hdl/sdram/jtframe_burst_io.v:158`:
  `{sdram_ncs, sdram_nras, sdram_ncas, sdram_nwe} <= { sel_cmd_r[3] ^ sel_chip_r, sel_cmd_r[2:0] };`
  — the addressed chip sees its command while the other sees DESELECT, over
  the same 13 address pins and the same single nCS net.
  `jtframe_burst_sdram.v:70-71` `localparam XL = AW == 24;` and
  `localparam PAW = XL ? 23 : AW;` (23 bits = 64 MB **per chip**), `:103`
  `assign prog_chip = XL ? prog_addr[AW-1] : 1'b0;`.
  `jtframe_sdram64_init.v` runs the init sequence twice, once per chip. The
  Verilator model matches: a second SDRAM instantiated with inverted nCS
  (`modules/jtframe/verilator/sdram.cpp`, `sdram.h` `invert_ncs`).
- **INFERRED, flagged as such:** that the PHYSICAL module inverts chip 1's
  /CS. There is no schematic in the repo; the RTL only proves what jtframe
  DRIVES. Circumstantial support exists even at our own pin —
  `jtframe_sdram64_bank.v:67-70` already comments that A[12:11] and the DQM
  lines are driven so they "can be joined together thru an OR operation at a
  higher level ... as done in the MiSTer 128MB module", i.e. the framework
  already knows that module as a pin-shorting multi-chip part.
- **It has a real consumer, not just a macro.** `cores/cps3/cfg/macros.def:6`
  sets `JTFRAME_SDRAM_XL`; `cores/cps3/cfg/mem.yaml` places lanes with
  `at: { chip: 1, bank: 3, length: 8MB }`; the CPS-3 README lists MiSTer
  SDRAM = 128 MB and `sfiii3n` at ~80 MB. The tier is exercised by a shipped
  core at roughly the size this port needs.

**THE RETRACTION-OF-A-RETRACTION, stated exactly.** STATE 14z-106 (3) and
`docs/project/cps2_wide.md` recorded *"NO XL SDRAM tier exists (RTL grep, 0
hits) — the cps2_wide.md claim RETRACTED"*. The correct reading is:

- **TRUE at our pin.** There is no XL tier in jtframe at `v1.7.3`, and the
  ceiling there is physical (previous section). Nothing about the v1.7.3
  measurement changes.
- **FALSE as a claim about jtframe.** The original `cps2_wide.md` sentence,
  which named a 128 MB tier as something jtframe has, was right about the
  FRAMEWORK and wrong about the VERSION we pinned.

Both documents now carry the version qualifier. The lesson is the ordinary
one, in a new place: **a grep proves a fact about the tree you grepped**, and
a pin is a tree.

## XL is NOT reachable by a flag — and there is a SILENT trap

XL support lives ONLY in the burst/cache branch of the SDRAM front end.
`modules/jtframe/hdl/jtframe_board_sdram.v:158` forks on
`JTFRAME_SDRAM_CACHE`: the `ifdef` arm instantiates `jtframe_burst_sdram`
(`:164`, `AW = SDRAMW`, the XL-aware controller above), and the `else` arm
instantiates `jtframe_sdram64` (`:225`) — which was **never taught XL**: its
`init`/`rfsh` instances leave `.chip()` unconnected
(`hdl/sdram/jtframe_sdram64.v:265,279`).

The macro validator does not close the gap.
`modules/jtframe/src/jtframe/macros/public.go:131-140` rejects
`JTFRAME_SDRAM_XL` together with `JTFRAME_SDRAM_LARGE`, and rejects
`JTFRAME_SDRAM_XL` together with any `JTFRAME_BAx_START` — but **nothing
requires `JTFRAME_SDRAM_CACHE` alongside XL.**

CPS-2 has no `cfg/mem.yaml`; it wires explicit slot modules in
`jtcps1_sdram.v`. So setting `JTFRAME_SDRAM_XL` on `cores/cps2w` **as it
stands today** would compile, pass validation, and silently produce the
bit-9-aliased map of the section above. Filed in `docs/platform/gotchas.md`
so it is not discovered during a bring-up.

## What an uprev to upstream master would cost (read 2026-08-23)

- **Distance.** `gh api repos/jotego/jtcores/compare/v1.7.3...master` ->
  `ahead_by` **3057**, `behind_by` 0.
- **No TAG carries XL.** `v1.7.3` (2024-01-18) is the newest VERSION tag in
  the repo's 532 tags — the listing runs `works`, `v.15`, `v1.7.3`, `v1.7.2`,
  ... down through per-game date tags that stop in early 2024 — while XL
  landed in `5981db26` "feat(jtframe): add SDRAM XL support" (2026-06-19),
  followed by `e555e01a` "fix(jtframe): support XL SDRAM validation"
  (2026-06-20). **Adopting XL therefore means pinning a bare master commit**:
  trading a tag for a moving target.
- **Paths we depend on have MOVED. THE RECIPE BELOW DOES NOT SURVIVE AN
  UPREV VERBATIM:**

  | at our pin (v1.7.3) | upstream master |
  |---|---|
  | `modules/jtframe/hdl/ver/test.cpp` — the file fork commit 2 patches | `modules/jtframe/verilator/test.cpp`, split into `sdram.cpp/.h`, `cabinet.cpp/.h`, ... |
  | `modules/jtframe/target/mister/jtframe_emu.sv` | `modules/jtframe/target/mister/hdl/jtframe_emu.sv` |
  | `bin/jtsim` (848 lines) | rewritten (658 lines) |
  | `cores/cps2/cfg/game.yaml` | `cores/cps2/cfg/files.yaml`, changed schema |
  | `mame2mra.toml` key `mraauthor` | `author` |
  | `jtsim -inputs` + `sim_inputs.hex` | `-inputs` takes a `.cab` CABINET SCRIPT; `sim_inputs.hex` is ORPHANED |
  | input bit 1 = coin2 | input bit 1 = service |

  So `tools/rpl2siminputs.py`, `tools/run_sim_jtcps2.sh`, fork commit 2 and
  both simulation gates are all uprev work, on top of re-basing the fork's
  two commits.
- **And upstream did NOT do the CPS-1/2 side for us.** `jtcps1_sdram.v` on
  master still carries the `[22:0]` offsets and still carries
  `localparam [22:0] SCR_OFFSET = 23'h00_0000; // change this when moving to
  8MB+ GFX`. Widening CPS-1/2 for a bigger GFX map is OUR work either way.

## What the CPS-2 CORE caps, on ANY SDRAM tier (measured 14z-107)

**This is the finding that retires "MiSTer work = width plumbing only".**
Widening SDRAM does not widen the core. Four caps live in the CPS-2 RTL
itself, and three of them are FORMAT, not memory.

- **GFX is capped at 32 MB by the OBJECT FORMAT, not by memory.** The tile
  code is 16 bits plus a 2-bit bank taken from the object table
  (`cores/cps2/hdl/jtcps2_obj_scan.v:47` `output reg [1:0] dr_bank`; `:152`
  `st3_bank <= table_y[14:13]`) = 2^18 codes x 128 B = 32 MB. Spare bits DO
  exist in the table words: positions are only 10 bits (`:148-149`
  `table_x[9:0]` / `table_y[9:0]`), so `table_y[12:10]` and `table_x[12:10]`
  are unused. **Note what this is — the SAME extension CPS-2 WIDE v1 already
  makes on FBNeo**, the ratified 19-bit tile promote in `Cps2ObjDraw`
  (CLAUDE.md rule 1 v2; `docs/project/cps2_wide.md` "Correction A2"). On
  MiSTer it is the profile expressed in RTL, not a novel invention, and it is
  profile-gated the same way.
- **The 68k map has no 6 MB ROM window.** `cores/cps2/hdl/jtcps2_main.v:184`
  `rom_cs <= A[23:22] == 2'b00;` — a flat 4 MB. Immediately above it sit the
  OBJ config port (`objcfg_cs`, `A[23:20] == 4'h4`, i.e.
  `0x400000-0x4FFFFF`), QSound at `0x600000`, ORAM at `0x700000` and I/O at
  `0x800000`. WIDE's `wide_ext` lives at `0x400000+`, so the core needs the
  same profile-gated remap the emulators got — **and the collision with the
  objcfg window is a real design question for the RTL arc**, not a formality.
- **Scroll is capped at 8 MB with NO bank input anywhere in the chain:**
  `jtcps1_sdram.v:121` `input [19:0] rom1_addr`, `:209`
  `gfx1_addr = {rom1_addr, rom1_half, 1'b0}` (22 bits), and `:179`
  `SCR_OFFSET = 23'h00_0000` anchors it at bank-3 offset 0.
- **QSound is exactly as this project documented it.**
  `cores/cps15/hdl/jtcps15_sound.v:416` `qsnd_addr[22:16] <= dsp_ab[6:0];`
  discards `dsp_ab[14:7]`, so banks >= 0x80 alias onto 0x00-0x7F. The fix is
  one bit (`qsnd_addr[23:16] <= dsp_ab[7:0]`) plus `qsnd_addr` -> `[23:0]`
  and `PCM_AW` 23 -> 24 (`jtcps1_sdram.v:23`). **16 MB of QSound fits SDRAM
  bank 1 on the EXISTING 64 MB tier**: PCM is alone in that 16 MB bank
  (`jtcps1_sdram.v:332-345`, `jtframe_rom_1slot`, `SLOT0_AW = PCM_AW`).
- **A free resource, for the record.** `cores/cps2/hdl/jtcps2_game.v:521-528`
  ties BOTH star slots off (`star0_addr = 13'd0`, `star0_cs = 1'b0`, likewise
  star1), so bank 3's `jtframe_rom_4slots` carries two 22-bit slots
  (`jtcps1_sdram.v:419-426`) that CPS-2 never uses.

The fit consequence of all this — that the roster fits 64 MB by TOTAL and is
blocked only by bank PLACEMENT — is worked out in
`docs/project/mister_fit.md` section 6.

## The simulation lane (the gate), read from `modules/jtframe/doc/sim.md`

- `jtsim` drives Verilator (game top only, no target), iverilog, or
  ModelSim. Benchmark on a small core: Verilator 12-30 s for 10 frames
  incl. ROM load; CPS-2 will be far heavier — **measure before promising**.
- ROM: `jtsim -setname vsav -load` builds `rom/vsav.rom` from the MRA +
  the zips the MRA tool reads from **`$HOME/.mame/roms/<set>.zip`**
  (`src/jtframe/mra/mrazip.go:23`, hard-coded — point a symlink there at
  `$ROMDIR`, outside the tree), links `rom.bin`, and produces `sdram_bank?.bin` once;
  `jtutil sdram` splits faster for cores with no download-time
  transformation (CPS-2 DOES transform — the encryption key load — so use
  `-load`). Nothing ROM-derived is ever committed (rule 7).
- **Scripted inputs — AT v1.7.3 (the pin) it is `jtsim -inputs` +
  `sim_inputs.hex`**, not the `.cab` scripts upstream's current `sim.md`
  describes (that grammar is newer than the pin). `hdl/ver/test.cpp`
  `SimInputs`: one hex word per line = one frame, applied when the core
  ENTERS blanking; active-high in the file; bit0/1 coin1/2, bit2/3
  start1/2, bits4-7 P1 U/D/L/R, bits8-11 P1 buttons 1-4 (bit11 doubles as
  dip_test). **P1 only, 4 buttons** — P2 and buttons 5/6 do not exist in
  that harness. `tools/rpl2siminputs.py` translates `.rpl` → `.hex` and
  REFUSES p2 / buttons 4-6 / service-test loudly (measured on four legacy
  replays: `01_attract_long` (7200 frames, no input) and `05_timeout_idle`
  (12000 frames, 13 active) translate; `04_select_fuzz` and
  `02_demitri_vs_cpu` REFUSE on P1 button 4). Gate
  `tests/test_rpl2siminputs.sh`. Extending the harness (P2, 6 buttons) is fork
  work on `test.cpp`, to be done when a refused replay is needed.
- **State out — RETRACTED AND REPLACED 14z-107.** This bullet used to say
  that `JTFRAME_SIM_IODUMP` plus `JTFRAME_SAVESDRAM` made "the per-frame 68k
  work-RAM window the MAME oracle checksums" reachable out of the box. **Both
  halves are false on this core and on this simulator**, measured 14z-107:
  * `JTFRAME_SIM_IODUMP=<frame>` writes `scenes/<frame>/dump.bin` over the
    IOCTL READ path. On CPS-2 that path is driven only by the serial EEPROM
    (`cores/cps1/hdl/jtcps1_sdram.v:462-478`; cps2 has no `cfg/mem.yaml`), and
    `JTFRAME_IOCTL_RD=128` is the 64 EEPROM words — so `dump.bin` is a
    **128-byte NVRAM image**, not RAM.
  * `JTFRAME_SAVESDRAM` exists ONLY in the Verilog SDRAM model
    (`modules/jtframe/hdl/ver/mt48lc16m16a2.v:193-209`, iverilog/ModelSim).
    The Verilator harness `modules/jtframe/hdl/ver/test.cpp` never references
    it: in a Verilator run the C++ `SDRAM` class IS the SDRAM, and its
    `dump()` (`test.cpp:474-499`) fires exactly once, right after a full ROM
    download.
  The true statement that survives: work RAM DOES live in SDRAM bank 0 on this
  core. Getting it out needs the harness hook below.
- **jtcores' own regression:** `cores/cps2/cfg/reg.yaml` lists
  `vsav: video: 2200` (frames to render) and sets like `dstlk` carry
  `ver/dstlk/reg.cab` (`1330 / 1 coin / 6 / 1 1P`); `run_regression.sh
  --check` compares against reference `frames.zip`/`audio.wav` under
  `$REGRUNS`. Our gate reuses the shape: a `.cab` per replay, a dump at the
  §4 sync anchors, field-level comparison against the MAME expectation.
- jtframe's MiSTer *target* does not simulate cleanly (sys files); the
  Verilator path simulates the game top, which is what we need.

## Recipe: the simulation lane on macOS (measured 14z-106, works)

1. `brew install go coreutils gnu-sed xmlstarlet verilator imagemagick`
   (jtframe's bash tooling needs GNU `realpath --relative-to`, `sed -i`,
   `stat -c`, `date -d`; `getset.sh` needs xmlstarlet; frame output needs
   ImageMagick `convert`).
2. `tools/setup_jtcores.sh` — pins `emu/jtcores`, inits the modules the
   cps2 yaml chain pulls (`fx68k jt12 jt51 jteeprom jtdsp16`; never the
   private `pocket` target), builds the Go tool. **Simulate in a SCRATCH
   CLONE of the fork, never inside `emu/jtcores`** — jtsim writes
   `obj_dir/`, `sdram_bank?.bin`, `frames/`, `rom.bin` into
   `cores/<core>/ver/game/`, which would dirty the pinned submodule.
3. ROM access for the MRA tool: `mkdir -p ~/.mame/roms` and SYMLINK
   `vsav.zip`, `vsavj.zip` and `qsound.zip -> qsound_hle.zip` (it holds
   `dl-1425.bin`) from `$ROMDIR`. Outside the tree; nothing copied.
4. Environment (what `setprj.sh` exports; it needs `python`, so export by
   hand): `JTROOT=<clone> JTFRAME=$JTROOT/modules/jtframe CORES=$JTROOT/cores
   ROM=$JTROOT/rom RLS=$JTROOT/release JTBIN=$RLS MRA=$RLS/mra
   POCKET=$JTFRAME/target/pocket MODULES=$JTROOT/modules MAME=$JTROOT/doc/mame`
   and `PATH=<gnubin dirs>:$PATH:.:$JTFRAME/bin`.
5. `jtframe mra cps2w` (binary at `$JTFRAME/src/jtframe/jtframe`) → the
   MRAs in `release/mra/` AND `rom/vsavj.rom` (46,407,744 bytes, sha1
   `f9dc2987…`) — the `.rom` is ROM content: scratch only. **Since
   14z-107 (5) do not do this by hand either:** `ROMDIR=...
   tools/mister_mra.sh --core cps2w [--wide build/m3b_merged13] --out <dir
   outside the repo>` does the clone, the private `$HOME` staging and the
   run, and prints the size + sha1 of every `.rom` it makes. `--wide` is
   what selects the BUILD's `vsav.zip` as the parent instead of the pristine
   one; without it you get the stock reference leg.
6. First run, from `cores/cps2/ver/game`:
   `jtsim -verilator -sysname cps2 -setname vsavj -load -video 3` —
   Verilator builds the core and the ROM download runs in simulated time
   (`ROM file transfered (frame 462)`), dumping `sdram_bank0-3.bin`
   (4 × 16 MB). **10'43" wall on this machine.** **CORRECTED 14z-107: it is
   NOT "once".** The transfer also latches the CPS-2 decryption key into core
   registers, so it must run on EVERY simulation; the bank dumps are useless
   on this core. Drop `-setname` (it only re-links and re-runs `getset.sh`),
   keep `-load`. The harness prints `ERROR: SDRAM
   rd/wr inputs should be zero during initialization` at start and
   continues — upstream's own runs show it too; not ours to chase unless
   it correlates with a divergence.
7. **Per-frame cost, measured:** a second run (`-video 30`, no `-load`)
   STILL re-ran the download (`ROM file transfered (frame 462)` again) and
   finished in 11'20" for 492 simulated frames → ~1.4 s per frame on this
   machine (Apple Silicon, Verilator 5.050). Frames:
   `frames/frame_00480.jpg` shows sprites on screen by frame 480 (18 frames
   after the load) — the core runs vsavj. **ANSWERED 14z-107: the re-download
   is `-setname`, not `-load`** — see "The work-RAM oracle" below for the
   mechanism (`ln -srf` vs an absolute `$ROMFILE`) and for the current
   numbers (~0.98 s/frame). Logs: scratchpad
   `jtsim_fourth.log` / `jtsim_fifth.log` (not committed; they carry no ROM
   bytes but are run litter).
8. **Since 14z-107 you do not run jtsim by hand:**
   `ROMDIR=... JTSIM_SCRATCH=... tools/run_sim_jtcps2.sh
   tests/replays/05_timeout_idle.rpl <outdir> --frames 2900 --wram 2500 2900`
   performs steps 2-7 idempotently and collects `wram/`, the log and
   `sim_inputs.hex` into `<outdir>`. `--frames` and `--wram` are ABSOLUTE
   (the 462 download frames included) and the `.rpl` is shifted by
   `--offset` (default 462). Run it detached and poll the PID; ~1 s per
   simulated frame.

## THE LANE'S SDRAM MODEL WAS WRONG — FIXED 14z-107 (3), fork commit 3

**RESOLVED.** The caveat this section used to carry ("the Verilator SDRAM
model is a 32 MB MODULE", 14z-107 (2)) was RIGHT about the symptom and WRONG
about the mechanism, and the fix it proposed would have broken the map in a
new way. Both are recorded below because the eliminations still hold.

**The symptom, unchanged:** at `JTFRAME_SDRAM_LARGE` the C++ SDRAM in
`modules/jtframe/hdl/ver/test.cpp` decoded only 22 of the 23 address bits,
so **the upper 8 MB of every bank aliased onto the lower 8 MB** — including
during the ROM download, which therefore never wrote the upper half at all
(it stayed at the constructor's `memset(0)`) and overwrote the lower half
with the upper half's content.

**The mechanism, corrected.** 14z-107 (2) recorded "13 row + 9 column =
22 bits" and "the fix is three constants: `<< 10`, `& 0x7fffff`, `0x3ff`",
i.e. it assumed the missing bit was `addr[9]`. **It is not.**
`modules/jtframe/hdl/sdram/jtframe_sdram64_bank.v`:

    :75-76  localparam ROW=13, COW= AW==22 ? 9 : 10;
    :127    addr_row = AW==22 ? addr[AW-1:AW-ROW] : addr[AW-2:AW-1-ROW];
    :219    sdram_a[10:0] = { precharge_flag, addr[AW-1], addr[8:0] };

At AW=23 the row is `addr[21:9]` — 13 bits, which is exactly what
`SDRAM_A << 9` already reconstructed — and the column is
`{ addr[22], addr[8:0] }`. **The TOP address bit rides on `sdram_a[9]`;
`addr[9]` is a ROW bit.** Widening the column mask to `0x3ff` would have
folded `addr[22]` onto `addr[9]` and produced a different wrong map.

**The fix** (`emu/jtcores-patches/0003-jtframe-sim-sdram-top-address-bit.patch`):
rebuild bit 22 from `sdram_a[9]` on the READ/WRITE command, `#ifdef
_JTFRAME_SDRAM_LARGE`. LARGE-only is not a convenience — at AW=22 that same
pin carries `addr[AW-1] = addr[21]`, which is already part of `addr_row` and
is a don't-care at COW=9, so 32 MB-module cores must keep ignoring it and are
byte-for-byte unaffected. The burst column counter stays 9-bit on purpose:
SDRAM burst addressing wraps inside the burst-length-aligned block and never
carries into column bit 9. No allocation change was needed — `BANK_LEN` is
already 16 MB under the macro and `read_bank`/`write_bank16` already mask
with `(BANK_LEN>>1)-1 = 0x7fffff`.

**BOTH CONTROLS, measured (`build/sdram_model_fix_14z107.log`):**

- **Regression — the oracle still passes, and the anchor moved FIVE FRAMES
  (2507 -> 2502, skew +361 -> +356), which is a real finding.**
  `tests/test_mister_sim_anchor.sh` is GREEN: the shift is inside the frozen
  +/- 30 band (not widened — the band is unchanged and the centre was
  re-measured), every mapped field agrees exactly at the anchor and at
  +60/+180, and the P1/P2 record bases are identical to the 14z-107
  measurement ($093B6A / $0AE9D4 vs $0A9518). **The mechanism is
  source-verified, not noise:** `cores/cps1/hdl/jtcps1_obj_draw.v:137`
  `if( &rom_data ) begin // skip blank pixels` — the object pipeline SKIPS
  its 8-pixel draw loop when the fetched GFX word is all-ones, so **OBJECT
  TIMING IS A FUNCTION OF GFX ROM CONTENT.** With the aliased map the core
  skipped whichever tiles the corruption made blank; now it skips the ones
  that really are, the SDRAM contention pattern differs slightly, and 2,500
  frames of that is worth five. Worth carrying into the WIDE arc: tenant art
  can shift core timing by the same route.
  What did NOT move is the part that matters: every bank-0
  region sits below word address `0x400000`, i.e. bit 22 is 0 for all of it
  — PRG `0`, VRAM `0x200000`, ORAM `0x280000`, WRAM `0x300000`, SND
  `0x380000` (`jtcps1_sdram.v:158-164`, offsets in 16-bit WORDS), and the
  68k ROM window is `main_rom_addr[20:0]`. Work RAM at bank 0 byte
  `0x600000` was never aliased, so the oracle was never affected — which is
  exactly what 14z-107 (2) predicted.
- **Must-fire — the rendered frames CHANGED.** Same replay, same 620-frame
  window, stock `cps2` core, before and after the fix.
  Frame 1 (the pre-download black screen) is BYTE-IDENTICAL — the
  run's own negative control. Frames 466 / 480 / 494 / 508 / 522 / 524 / 527
  all DIFFER, in 106 / 311 / 526 / 731 / 980 / 1241 / 1361 pixels of 86,016
  — 0.12-1.58% of the frame, but **71-78% of every INKED (non-black) pixel**,
  because what is on screen there is the mostly-black CPS-2 boot self-test.
  The SET of rendered frames differs too (`test.cpp` writes a jpg only when
  the frame CHANGED): 465 appears only in the fixed run, 543/544/547/548 only
  in the broken one. And the change is legibility — the self-test went from
  garbled glyphs to `WORK / CPS0 / CPS1 / CPS2 / OBJECT / Q SOUND ... RAM OK`.
- **And the SDRAM image itself:** the post-download bank images of the FIXED run measure bank 0
  and bank 1's upper 8 MB at **0.0% non-zero** — never addressed, which is
  the regression control above turned into a measurement — and banks 2 and 3's
  upper 8 MB at **87.6% / 90.1% non-zero**, memory the old model could not
  reach at all. (Bank 1's empty upper half is, incidentally, exactly the space
  the BANK REPACK ruling wants for tenant art.)

**What this retires.** 14z-106 slice C's "`frame_00480.jpg` shows sprites"
was weaker evidence than it read, and 14z-107 (2) said so; now the lane
actually renders from a faithful tile map, and simulating a widened set is
no longer blocked on this.

## The work-RAM oracle: `JTFRAME_SIM_WRAMDUMP` (measured 14z-107)

**Where 68k work RAM is, read from the RTL and then CONFIRMED against the
running core.** `jtcps1_sdram.v:158-164` `WRAM_OFFSET = 23'h30_0000` in 16-bit
WORDS; `jtcps2_main.v:127,185` `pre_ram_cs = &A[23:16]` (i.e. `$FFxxxx`) and
`addr = ram_cs ? {2'b0,A[15:1]} : A[17:1]`; `jtframe_ram_rq.v:94` composes
`sdram_addr = addr + offset`. So **`RAM:$FF0000-$FFFFFF` = SDRAM bank 0 byte
offset `0x600000`, 64 KB**. Confirmed by dumping the WHOLE 16 MB bank at a
boot frame and diffing it against the post-download image: the only regions
the 68k had touched were `0x400000-0x42FFFF` (VRAM/ORAM) and **exactly 297
bytes at `0x600000`** — the same 297 bytes MAME's `$FF0000-$FFFFFF` carries at
the same point of the boot memory test.

**Byte order, proven on live data.** `test.cpp` swaps bytes symmetrically: the
SDRAM constructor loads `banks[k][j] = file[j^1]` and `SDRAM::dump()` writes
`out[j^1] = banks[k][j]`, so the dump is **big-endian 68k order** — the same
byte string `tests/lua/replay.lua:206` hashes on MAME. Measured: the sim's
work RAM at game frame 74/76/78 differs from MAME's at frame 76/78/80 in
**1-2 bytes of 65,536**, while the byte-SWAPPED comparison differs in **416**.
(A weaker cross-check that also holds: `sdram_bank0.bin` equals
`byteswap(rom/vsavj.rom @ offset 64)`, the CPS-2 `ROM_LOAD16_WORD_SWAP`
convention.) **What does NOT prove byte order:** an early attempt reported
99.2% agreement on sampled bytes from a dump path that was emitting a
CONSTANT all-zero buffer — most of a work-RAM image is zero. Check
non-constancy first; `tests/test_mister_sim_anchor.sh` does.

**The boot skew.** MAME first writes work RAM at frame 73 (0 -> 257 bytes);
the simulated core does it at GAME frame 71, i.e. absolute frame 533. So
**simulated absolute frame = MAME frame + 460** (the 462 download frames minus
a 2-frame lead) — but that is the BOOT-PHASE offset only. **CORRECTED
14z-107 (2): the round-1 match-start anchor of `05_timeout_idle` sits at MAME
**2146** / sim **2507**, i.e. skew +361, not +460** — the attract/select/VS
path costs ~99 fewer frames on the core. (**RE-MEASURED 14z-107 (3) on the
FIXED SDRAM model: 2502 / +356**; the five frames are the object pipeline's
blank-tile skip reacting to correct GFX, see the fix section above.)
2502/356 is what the gate freezes
(`tests/test_mister_sim_anchor.sh:87-89`) and what "THE ANCHOR MEASUREMENT"
below reports; an earlier "sim 2606 / skew 460" in this paragraph was the
boot offset applied to the wrong frame and is retracted.

**The hook.** Fork commit 2 (`emu/jtcores-patches/0002-jtframe-sim-wramdump.patch`,
64 added lines in `modules/jtframe/hdl/ver/test.cpp`, no RTL) adds
`SDRAM::dump_range()` and calls it at the VS rising edge next to the IODUMP
hook, writing `wram/dump_<frame>_<addr6>.bin` — exactly the glob
`tools/compare_fields.py` consumes. It is **inert unless
`_JTFRAME_SIM_WRAMDUMP` is defined**, which is the emulator-superset shape in
its simulation edition, and the block to dump is described entirely by macros
(`..._BANK/_OFF/_LEN/_ADDR`, plus `..._END` for the last frame) so jtframe
stays core-agnostic and the CPS-2 numbers live in `tools/run_sim_jtcps2.sh`.
Gates: `tests/test_sim_wram_contract.sh` (ROM-free — naming, byte order,
skew-absorption, the two must-fire controls, the rule-7 refusals, and a
static proof that every added code line sits inside the `#ifdef`) and
`tests/test_mister_sim_anchor.sh` (the live end-to-end oracle).

**THE DOWNLOAD IS NOT SKIPPABLE ON CPS-2 — and the SDRAM dumps are a trap.**
Two facts, both measured 14z-107, and the second cost a 1,841-frame run:
1. **`-setname` always re-downloads AND moves your dumps away.**
   `jtsim:503-506` tests `` `readlink rom.bin` != "$ROMFILE" ``; `rom.bin` is
   made with `ln -srf` so `readlink` returns a RELATIVE path while `$ROMFILE`
   is absolute — the test is true on every run. It re-links and calls
   `enable_load()` (`jtsim:249-258`), which defines `LOADROM` **and moves
   `sdram_bank?.bin` into `sdram.old/`**. That is why 14z-106 saw the
   462-frame download twice.
2. **Dropping `-load` gives you the ROM content and a DEAD 68k.** Without it
   `test.cpp:611-651` preloads the four banks at t=0 and shortens the
   download to 32 bytes (`test.cpp:263-281`) — but the CPS-2 **decryption key
   is not in SDRAM**. It is latched into core REGISTERS while the transfer
   streams (`jtcps1_prom_we` → `cps2_key_we` → `jtcps2_keyload`), so a
   preloaded run boots into ciphertext. **Measured: 1,841 frames with the
   banks preloaded, 68k work RAM ALL ZEROS at every single frame** — a
   constant, which is exactly what a dead CPU writes. (14z-106's own note
   "CPS-2 DOES transform — the encryption key load — so use `-load`" was
   right, and the 14z-107 plan's "drop both" was wrong.)

So the recipe is **`-load`, no `-setname`**: `tools/run_sim_jtcps2.sh` makes
the `rom.bin` symlink and copies `core.mod` itself, deletes the useless bank
dumps, and pays the transfer every run (**462 simulated frames, ~7-8 min**).

**THE DOWNLOAD CONSUMES INPUT LINES.** `sim_inputs.next()` fires on every
LVBL fall from t=0, download frames included, while the core is held in reset
until the transfer ends — so line 1 of `sim_inputs.hex` is burnt on sim frame
0, not on the game's first frame. The `.rpl` must be shifted by the download
length: `rpl2siminputs.py --offset 462` (that is what `--offset` was added
for, and `run_sim_jtcps2.sh` defaults it to the download length). Everything
else — `--wram FIRST LAST`, the dump file names, the anchors below — uses the
ABSOLUTE frame counter, so a MAME frame `f` corresponds to a simulated frame
near `f + 462`.

**Rule-7 note:** with the download mandatory the `sdram_bank?.bin` files have
no purpose at all; the tool removes them, so a long series of runs no longer
accumulates 64 MB of ROM-derived litter per run.

**THE ANCHOR MEASUREMENT (stock `cps2` core, stock `vsavj`,
`05_timeout_idle`, 14z-107).** Round-1 match start: MAME frame **2146**,
simulated frame **2507** — skew **+361** (**2502 / +356 since the SDRAM
model fix, 14z-107 (3)**). Note that this is NOT the boot
offset (+460): the attract/select/VS path costs ~99 fewer frames on the core
than on MAME, which is exactly why CLAUDE.md §4 compares mapped state at
ANCHORS rather than at fixed frame indices. At the anchor and at +60/+180,
every compared field agrees: `timer` 0x63, both HP 0x120, both white HP, both
meter fields, `p1_hitbox_base` **$093B6A on both** (Demitri — P1's pick
matches), `p1_ptr64`, `p1_word132`, `p1_x/y/flip/attack_id`, and even the
`phase` field `p1_anim_ptr` ($12CDF6 on both).

**THE ONE DISAGREEMENT, AND IT IS THE GAME'S OWN LOTTERY.** The CPU opponent
differs: MAME drew the character whose record base is **$0AE9D4**, jtcps2 drew
**$0A9518**. `05_timeout_idle` is a 1P arcade match and the ladder's in-use
mask `RAM:$FF8110.l` is SOUND-STATE-FED (`docs/game/atlas/ram.md:99` — the
run-to-run draw that cost GitHub #110 two frozen audits in 14z-103), so the
opponent is implementation-dependent by construction. Every field that is a
function of WHICH character P2 is (`p2_hitbox_base`, `p2_ptr64`,
`p2_word132`, `p2_x/y`, `p2_attack_id`, `p2_flip`) is therefore excluded BY
NAME in `tests/test_mister_sim_anchor.sh`; `p2_hp`, `p2_white_hp` and the two
p2 meter fields stay compared and agree. Pinning the opponent needs a 2P
replay, which needs P2 in the v1.7.3 `SimInputs` harness — a queued fork
commit. Informational, never a verdict: the whole 64 KB differs in ~1,500 of
65,536 bytes at anchor+60, nearly all of it the other opponent's state
(`$FF41xx-$FF44xx`, `$FF57xx-$FF58xx`).

**The lane as one command:** `tools/run_sim_jtcps2.sh <replay.rpl> <outdir>
[--frames N] [--wram FIRST LAST] [--core cps2|cps2w]`, with `ROMDIR` and
`JTSIM_SCRATCH` in the environment. Every step is idempotent (clone, symlinks,
Go build, MRA, seed), it prints the sha1 of everything it reads, and it
REFUSES an out-dir inside the repo (rule 7) or a scratch clone inside it.

**Times measured on this machine (Apple Silicon, Verilator 5.050):**

| step | wall |
|---|---|
| ROM download (`-load`), EVERY run, 462 simulated frames | ~7-11' |
| incremental rebuild after a `test.cpp` edit or a macro change | ~4 s |
| simulation | **~0.98 s per frame** (540 frames incl. download in 8'50"; 330 frames in 5'41" on the preloaded path) |

Only `test.cpp` includes `defmacros.h`, so changing the dump window rebuilds
one object and relinks — it does NOT re-verilate the model. A per-window
rebuild is ~4 s, not minutes.

## The per-bank SDRAM traffic profile (measured 14z-107 (3))

Stock `vsavj` on the stock `cps2` core, `05_timeout_idle`, 2,800 frames,
`tests/audit_sdram_bank_load.sh`; full table and verdict in
`build/sdram_bank_load_14z107.log`. Figures are PER VIDEO FRAME.

| phase | ba0 (68k+VRAM+ORAM+WRAM+snd) | ba1 (QSound PCM) | ba2 (obj) | ba3 (obj+scroll) | data bus |
|---|---|---|---|---|---|
| attract | 38,278 acc | 3,464 acc / 78.6% row miss | 0 | 9,453 / 25.2% | 12.7% |
| select+VS | 39,635 acc | 13,856 / **99.0%** | 261 / 82.7% | 12,079 / 36.8% | 16.4% |
| in-match | 40,797 acc | 14,132 / **98.8%** | 1,017 / 42.6% | 17,467 / **28.8%** | 18.2% |

**Read "acc" as READ+WRITE commands and the percentage as the ROW MISS
rate.** They are different quantities because only bank 0 sets
`JTFRAME_BA0_AUTOPRECH`: on banks 1-3 `jtframe_sdram64_bank.v:170`
(`row_match = match && actd && !AUTOPRECH[0]`) skips both the PRECHARGE and
the ACTIVE when a request hits the open row, so an ACTIVE there means a row
MISS. Bank 0's 100% is by construction, not by thrashing.

Facts that matter to the bank-repack arc:
- **QSound has essentially no row locality** — 98.8% miss in-match. It
  round-robins 16 channels at unrelated addresses, so nearly every fetch
  opens a new row. There is no locality in bank 1 for a repack to spoil.
- **Object/scroll traffic does** — 28.8% miss in bank 3. Tile fetches come in
  runs; that is what a repack into bank 1 would put at risk.
- **The bus is at 18.2%** of 96 MHz x 16 bit (30.2 MB/s useful) at the
  busiest measured point, and a repack cannot change it: it moves which bank
  serves a fetch, not how many fetches happen.
- **A single bank's all-miss ceiling is 123,825 transactions/frame**
  (STW = 13 clocks at 96 MHz), and **bank 0 already sustains 40,797 of them
  every frame** in stock configuration — more than any repack worst case.
- `WARNING: (test.cpp) SDRAM reads clashed`: **zero** in 2,800 frames.
- Bank 2 is nearly idle (1.4% share): vsav's object art sits overwhelmingly
  in the `rom0_bank[0]=1` half, i.e. bank 3.
- `jtframe_sdram64.v:536-542` with `BAPRIO=1` grants strictly
  ba0 > ba1 > ba2 > ba3, so objects moved into bank 1 would gain priority
  OVER the scroll left in bank 3 — a scheduling change, not just a
  placement change.

## Measured 14z-106: the twin proof

`jtframe mra cps2` emits 316 MRAs; `jtframe mra cps2w` emits 7 — the
Vampire Savior family only (Euro parent + Japan/USA/Asia/Brazil/Hispanic
+ the Phoenix bootleg). The `vsavj` MRA from the two cores is
BYTE-IDENTICAL except `<rbf>jtcps2</rbf>` → `<rbf>jtcps2w</rbf>` (diff
shown in STATE 14z-106 (3)). Gate: `tests/test_jtcores_twin.sh`.
**Since 14z-107 (5) `cps2w` emits EIGHT** — the WIDE set joined the family —
and the twin claim above is now a live gate rather than a one-off
measurement: `tests/test_mister_mra_map.sh` re-generates both cores' MRAs
and diffs them.

## HOW THE MRA AND THE `.rom` ARE MADE (measured 14z-107 (5))

Everything here was learned building the WIDE download image
(`docs/project/mister_map.md` slice D0). It is platform behaviour, true of
any core.

- **A set must exist in `$JTROOT/doc/mame.xml`** — jtframe's own REDUCED
  machine catalogue, committed in the repo, not a MAME `-listxml` dump.
  `jtframe mra` streams it (`mamegame.go:167-250`) and everything else keys
  off what it finds there. A romset with no machine entry produces no MRA,
  whatever the TOML says. **Hazard worth naming: that catalogue is a
  GENERATED file upstream** (`jtframe mra --reduce <mame.xml>`), so a future
  uprev or regeneration can drop an entry we added. Nothing warns; the MRA
  simply stops being emitted. `tests/test_mister_mra_map.sh` fails with
  "cores/cps2w did not emit the WIDE MRA at all" if that happens, and
  `tools/gen_vsavjw_xml.py` re-emits the entry.
- **`[parse] sourcefile` is a REGEX list matched against
  `filepath.Base(machine.sourcefile)`.** That makes it a usable PROFILE
  GATE: an entry tagged `sourcefile="capcom/cps2w.cpp"` is invisible to a
  core declaring `sourcefile=["cps2.cpp"]` (the `.` matches any character,
  but the string is one char short and never aligns). This is how the WIDE
  set is reachable from `cores/cps2w` and unreachable from `cores/cps2`
  without editing the reference core at all.
- **`mra2rom` locates every zip member by CRC32 and by NOTHING ELSE**
  (`mra2rom.go:163-172`: it walks the zips comparing `file.CRC32`; the
  `name` attribute is used only in the warning text). **This is a real
  divergence from FBNeo and MAME**, which resolve by name and merely warn on
  a hash mismatch — which is why this project's WIDE members carry SENTINEL
  CRCs in both of those drivers and why content there can change freely. On
  MiSTer a sentinel means `Warning: cannot find file … in zip` and no `.rom`.
  Consequence: **an MRA is pinned to the exact bytes of one romset build.**
- **The zip search path is a HARD-CODED `$HOME/.mame/roms/<name>.zip`**
  (`mrazip.go:23`), so the tool's output is a function of the invoking
  user's home directory and there is no flag for it. `tools/mister_mra.sh`
  stages a PRIVATE `$HOME` per run instead of writing into the user's — and
  it has to, because the stock leg and the WIDE leg need DIFFERENT
  `vsav.zip` files: the WIDE romset is a clone set whose parent is the
  BUILD's `vsav.zip` (the merged build patches `vm3.13m/15m/17m/19m`), while
  the stock `vsavj` reference leg needs the pristine dump.
- **`jtframe mra -n` skips ROM generation entirely** — no zips are opened,
  `md5="None"`, and the MRA XML becomes a pure function of `doc/mame.xml`
  plus the core's TOML. That is the ROM-free mode a structural gate wants.
- **`parts=` puts EVERY part of a region inside ONE `<interleave>` when
  `width > 8`** (`corerom.go:462-479`), and `interleave2rom` resolves each
  output byte lane to the FIRST finger claiming it (`mra2rom.go:238-249`).
  So `parts=` can express a multi-member 16-bit region only if the members'
  maps are DISJOINT (Pang!3's four 64-bit lanes are; three CPS-2 QSound
  members all carrying `map="12"` are not — they silently collapse to the
  first, truncated to the shortest). The way out is one region per
  differently-mapped group, with a generic `{ name=…, skip=true }` row so
  every other set skips it — **a region with no config at all still emits
  its `<!-- … starts at … -->` comment**, which is enough to break a
  byte-identity twin.
- **Region starts in the MRA comments are the generator's `pos`, which
  INCLUDES the 20-byte `key` region; the RTL's `bulk_addr` does not.** On
  CPS-2 every region therefore starts at `<1 KiB-aligned> + 0x14`, and the
  `>> 10` header word is right only because `0x14 < 1024`. Measured on the
  stock `vsavj` MRA: `maincpu` at `0x14`, `audiocpu` at `0x400014`,
  `qsound` at `0x440014`, `gfx` at `0xC40014`, `firmware` at `0x2C40014`.
- **An oversized region start is written WRAPPED, with no warning.**
  `set_header_offset` stores the low 16 bits of `start >> 10`. Measured on
  the untrimmed WIDE image: a firmware start of 71,936 KiB was emitted as
  **6400** — the same value as `qsound`'s. A `.rom` that overflows the
  header does not fail to build; it builds wrong.
- **Reference numbers, this machine, 14z-107 (5):** stock `vsavj.rom`
  46,407,744 B; WIDE `vsavjw.rom` 66,265,152 B; a full `jtframe mra cps2`
  run (316 sets, `-n`) plus a `cps2w` run and two `.rom` builds is ~15 s.

## Open / to verify in the arc

- ~~Whether `jtsim` runs at all on macOS~~ — ANSWERED 14z-106: it does, with
  the brew deps in the Recipe above.
- ~~Time per simulated CPS-2 frame~~ — ANSWERED: ~1.0-1.2 s/frame, so a
  select-reaching 2,600-frame run is ~45 min and the 12,120-frame
  `05_timeout_idle` is ~3.5-4 h. Fine for a gate that dumps at a few §4
  anchors; not a per-frame sweep of the 46-replay corpus.
- Input coverage: the v1.7.3 harness is P1-only with 4 buttons, so
  `02_demitri_vs_cpu` and `04_select_fuzz` still refuse. Extending
  `test.cpp`'s `SimInputs` (P2, buttons 5/6) is a further fork commit —
  recommended once the anchor gate has run a while, not before.
- ~~The width surgery itself (SDRAMW 23 -> 24 and the bank/prog/ioctl bit)
  waits on the profile-shape ruling in STATE "Decisions pending".~~
  **SUPERSEDED 14z-107 (2).** The PROFILE ruling landed (WIDE v1 verbatim,
  one romset — unchanged and not reopened); what was wrong was the
  implementation assumption bundled with it. "SDRAMW 23 -> 24 and one more
  bit" is NOT the shape of the work: at our pin there is no 24-bit map to
  reach (row/column/pins are saturated), the 128 MB tier exists only
  upstream and only in the cache-lane branch, and the CPS-2 core carries
  format caps that no SDRAM tier lifts. The route is now its own pending
  decision — **THE MiSTer MEMORY-MAP ROUTE** in STATE "Decisions pending":
  (1) uprev to upstream master + `JTFRAME_SDRAM_XL` + cache lanes, or
  (2) stay at the pin and BANK-REPACK inside 64 MB (tenant art into bank 1
  beside the PCM, reached by the promoted tile-code bit). Either way the
  core-side format work of "What the CPS-2 CORE caps" is required.
- ~~**The Verilator SDRAM model's 8 MB-per-bank decode** (the caveat next to
  the Recipe) is a prerequisite for simulating any widened set, and is
  three constants. Not started.~~ **DONE 14z-107 (3), fork commit 3** — and
  it was NOT three constants: the dropped bit is `addr[22]` riding on
  `sdram_a[9]`, not `addr[9]`. See "THE LANE'S SDRAM MODEL WAS WRONG" above.
- **The bank-repack question is MEASURED and the answer is GO** — see "The
  per-bank SDRAM traffic profile" above and
  `build/sdram_bank_load_14z107.log`. It bounds the headroom; proving the
  repacked design needs the same instrument on a `cps2w` core carrying the
  repacked map.
