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
| the fork's commits | `b9d0565` `cores/cps2w` scaffold (14z-106) · `553dd56` `jtframe/sim: optional work-RAM dumps out of the Verilator SDRAM model` (14z-107). No RTL touched by either |
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
   `f9dc2987…`) — the `.rom` is ROM content: scratch only.
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
a 2-frame lead), and the round-1 match-start anchor of `05_timeout_idle` sits
at MAME **2146** / sim **2606**.

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
simulated frame **2507** — skew **+361**. Note that this is NOT the boot
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

## Measured 14z-106: the twin proof

`jtframe mra cps2` emits 316 MRAs; `jtframe mra cps2w` emits 7 — the
Vampire Savior family only (Euro parent + Japan/USA/Asia/Brazil/Hispanic
+ the Phoenix bootleg). The `vsavj` MRA from the two cores is
BYTE-IDENTICAL except `<rbf>jtcps2</rbf>` → `<rbf>jtcps2w</rbf>` (diff
shown in STATE 14z-106 (3)). Gate: `tests/test_jtcores_twin.sh`.

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
- The width surgery itself (SDRAMW 23 -> 24 and the bank/prog/ioctl bit)
  waits on the profile-shape ruling in STATE "Decisions pending".
