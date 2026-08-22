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
| pinned here | submodule `emu/jtcores` (branch `vampire-saved`); `tools/setup_jtcores.sh` checks the pin and inits ONLY `modules/jtdsp16` (`modules/jtframe/target/pocket` is a PRIVATE ssh submodule — never init it) |
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
  documented tier (`modules/jtframe/doc/macros.md:152`). `jtcps1_sdram.v`
  exposes four 23-bit WORD bank buses (`ba0..ba3_addr[22:0]` = 16 MB each),
  `ioctl_addr[25:0]` (64 MB) and `prog_addr[22:0]`. The maintainer's
  128 MB module is physically twice that; using it means widening those
  buses in jtframe + the core — framework surgery to be SIZED in the arc,
  not assumed. **MEASURED 14z-106: no `JTFRAME_SDRAM_XL` exists anywhere in
  jtframe at v1.7.3** (`grep -rn SDRAM_XL modules/jtframe` = 0 hits; the
  cps2_wide.md claim is retracted there). What exists: `localparam
  SDRAMW = 23 (LARGE) / 22` in `target/mister/jtframe_emu.sv:168`, the
  `[22:0]`/`[21:0]` bank ports in `hdl/inc/jtframe_mem_ports.inc`, and
  `jtframe_sdram_bank #(AW)`; MiSTer's HPS already exposes
  `ioctl_addr[26:0]` ("up to 128MB", `jtframe_emu.sv:334`) while the
  core-facing port is `[25:0]`. So a 128 MB tier = SDRAMW 24 + one more
  bank-address bit through the framework + the core's own buses.
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
- **State out:** `JTFRAME_SIM_IODUMP=<frame>` (the `.cab` `dump` word is
  post-pin)
  writes `scenes/<frame>/dump.bin` over the IOCTL read path
  (`JTFRAME_IOCTL_RD` set — cps2 has 128); `JTFRAME_SAVESDRAM` (+
  `DUMP_START`) dumps the whole SDRAM at each frame's VBL. Work RAM lives
  in SDRAM bank 0 on this core ("RAM/VRAM/M68000 ROM"), so the per-frame
  68k work-RAM window the MAME oracle checksums is reachable.
- **jtcores' own regression:** `cores/cps2/cfg/reg.yaml` lists
  `vsav: video: 2200` (frames to render) and sets like `dstlk` carry
  `ver/dstlk/reg.cab` (`1330 / 1 coin / 6 / 1 1P`); `run_regression.sh
  --check` compares against reference `frames.zip`/`audio.wav` under
  `$REGRUNS`. Our gate reuses the shape: a `.cab` per replay, a dump at the
  §4 sync anchors, field-level comparison against the MAME expectation.
- jtframe's MiSTer *target* does not simulate cleanly (sys files); the
  Verilator path simulates the game top, which is what we need.

## Measured 14z-106: the twin proof

`jtframe mra cps2` emits 316 MRAs; `jtframe mra cps2w` emits 7 — the
Vampire Savior family only (Euro parent + Japan/USA/Asia/Brazil/Hispanic
+ the Phoenix bootleg). The `vsavj` MRA from the two cores is
BYTE-IDENTICAL except `<rbf>jtcps2</rbf>` → `<rbf>jtcps2w</rbf>` (diff
shown in STATE 14z-106 (3)). Gate: `tests/test_jtcores_twin.sh`.

## Open / to verify in the arc

- Whether `jtsim` runs at all on macOS (the wrappers are bash + GNU
  coreutils; Verilator via brew) or needs a Linux box/container — decide
  from the first attempt, record the recipe here.
- Time per simulated CPS-2 frame → the gate's budget.
