# MiSTer — the jtcps2 core, as it concerns this port

Platform fact file (docs/README.md taxonomy: true whether or not the roster
hack exists). Opened 14z-106 (2026-08-22) when the MiSTer arc was framed.
Every figure below names its source; "read 2026-08-22" means the jtcores
tree at tag `v1.7.3` (commit `63688ce5`) unless stated.

> **STATUS (14z-123, the documentation rationalization pass): the platform
> RECORD.** What jtcps2, jtframe and the simulation lane do, MEASURED, one
> section per fact, each naming its instrument and session — and it is
> still the file of record for every MiSTer number: where it and the
> synthesis `docs/project/mister_core.md` disagree, **this file wins**.
> The problem→fix CHRONOLOGY (each defect as it was found, each reading as
> it was retracted) moved verbatim to `docs/platform/mister_history.md`;
> what stays here is the mechanism, the number and the gate. Read
> `mister_core.md` first for the shape of the thing.

## The ruling this file serves (maintainer, 2026-08-22)

The MiSTer deliverable is an **extension of Jotego's jtcps core** — a
SEPARATE core, so the reference CPS-II core stays separately usable — not
an FPGA re-implementation of the MAME emulation. jtcores and jtframe are
**GPL-3.0** ("you are obliged to publish your code if you use mine"), so
the fork is public and FOSS by obligation. Simulation is the gate;
hardware (MiSTer, 128 MB SDRAM, Jammix card → CRT at native timing) is the
field test. Distribution = MRA + RBF over the same release members as
`release/<name>/`, plus a stock-`vsav` reference-leg MRA. **(Status,
updated 14z-113: the field test has run — PASSED 14z-109 on a DE10-Nano,
re-confirmed on bundle 14z112 on 2026-08-28 with stock Vampire Savior
coexisting on the same card, then green on bundles 14z115 (M9), 14z117 (M10)
and 14z117b (M11, "behavior identical to emulation", 2026-08-29 — STATE
14z-118) and 14z119 (M12, "all green", 2026-08-30 — STATE 14z-121); the `[STOCK CONTROL]` reference-leg MRA ships
since 14z-109; the `.rbf` + MRAs are to be tracked in-tree under
`release/` by the maintainer's ruling of 2026-08-28 — format open in STATE.)**

## Where things are

| thing | where |
|---|---|
| the fork | https://github.com/DefinitelyFrenchName/jtcores, branch `vampire-saved`, from upstream tag `v1.7.3` = `63688ce5` |
| pinned here | **[MSC-4]** submodule `emu/jtcores` (branch `vampire-saved`); `tools/setup_jtcores.sh` checks the pin, inits the five modules the cps2 yaml chain pulls, and regenerates `emu/jtcores-patches/` as a PATCH SERIES, one file per fork commit (`modules/jtframe/target/pocket` is a PRIVATE ssh submodule — never init it) |
| the fork's commits (**28 at the 14z-119 pin `2bf41090`** — 0028 = the merged-m14 catalogue (three CRCs: `vm3j.04d`, `vsw.33m/37m`); 27 at the 14z-117b pin `f997cfe1` — 0027 = the merged-m13 catalogue; 26 at the 14z-117 pin `80e08111`; 25 at the 14z-115 pin `202fc3e6`; 24 at the 14z-113 pin `63496069`; this row had stopped at D2 until 14z-113) | `b9d0565` `cores/cps2w` scaffold (14z-106) · `553dd56` sim work-RAM dumps · `6c32be8` sim SDRAM top address bit · `4f25cc7` sim model clock · `74ed17d` sim SDRAM stats · `38acc638` the WIDE machine entry + the MANDATORY QSound trim in the MRA (14z-107 (5), slice D0) · `4840df8a` **THE FIRST RTL COMMIT — the QSound sample-bank width, RUNTIME-GATED** (14z-107 (6), slice D1) · `692ba4d6` + `7cf1eedb` the frame writer made optional and its child made `_exit` (14z-107 (7)) · `519aff8b` the joystick top bits (14z-107 (8)) · `0df6f000` **THE SDRAM PLACEMENT** (14z-107 (9), slice D2) · `17a5dc2b` the SDRAM READ PROBE · `b9899fa8` **THE OBJECT PROMOTE** (slice D3) · `fd454393` the frame writer's frame window · `dd242a65` **THE 6 MB PROGRAM WINDOW** (slice D4) · `72738d51` the sim-only 68k program-ROM read probe · `c00d7ce7` **THE DECRYPTION RANGE** (slice D5, 14z-107 (11)) · `7b9a0d2d` the D4 comment retraction · `c97e3d14` README brought to D0-D5 (14z-109) · `4dfc3734` **P2 SCRIPTABLE** in `sim_inputs.hex` (14z-109) · `68448ec5` / `fc04a8ec` / `f5a3391a` / `63496069` the `vsavjw` catalogue CRCs for the 14z-110 / M7 / 14z-110b / 14z-111 freezes (the MiSTer TAIL of each re-freeze). Commits 1-6 touched no RTL; the catalogue commits touch only `doc/mame.xml`. The mirrored series is `emu/jtcores-patches/0001`-`0024`, one file per commit |
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
and a file is copied into `cores/cps2w/hdl` only when it must differ; the
diff between the two core dirs IS the trust surface.

**SINCE SLICE D1 (14z-107 (6)) cps2w EXERCISES THAT MECHANISM, AND SLICE D2
(14z-107 (9)) DOUBLED IT.** Its `game.yaml` was cps2's verbatim through D0;
it now pulls SIX files from `cores/cps2w/hdl` — FOUR overrides of SHARED
files (`jtcps2_game.v` from cps2, `jtcps15_sound.v` from cps15,
`jtcps1_sdram.v` and `jtcps1_prom_we.v` from cps1) and two new ones — and
DROPS those four from the reference cores' lists, because `jtframe files`
deduplicates by full path and would otherwise compile both copies of the
same module (measured: `jtframe files sim cps2w` lists ours and NONE of the
four originals; `... cps2` lists the originals and none of ours; the two
lists differed in exactly **eleven** entries at D2 — 4 out, and 6 overrides plus
1 new jtframe module in — **and in 22 since D5 (fourteen files in
`cores/cps2w/hdl`: thirteen `.v` plus `pal_lut.hex`; the D2 figures in
this paragraph are that slice's record, updated 14z-113)**. `cores/cps1`, `cores/cps2` and `cores/cps15` are
BYTE-UNTOUCHED against upstream `v1.7.3` — `tests/test_jtcores_twin.sh` 2e
asserts it with `git diff`, 2f holds the fork's WHOLE-TREE delta to a
declared 18 paths, and `tests/test_mister_wide_gate.sh` freezes the override
delta line by line.

**THE COST OF AN OVERRIDE IS THE YAML THAT PULLED IT, AND IT COMPOUNDS.**
A file reachable only through a pulled yaml cannot be overridden and have
that yaml included: jtframe dedups by PATH, so both copies of the module
would compile. D1 paid this once — `cores/cps15/cfg/qsound.yaml` had to be
INLINED into cps2w's `game.yaml` minus `jtcps15_sound.v`. D2 paid it again
and larger: `jtcps1_sdram.v` and `jtcps1_prom_we.v` come from
`cores/cps1/cfg/common.yaml`, so that yaml is now inlined too, minus those
two. cps2w's `game.yaml` is consequently 68 lines different from cps2's at
D2 (**73 since D3-D5**, updated 14z-113) and
is frozen in `tests/expect/cps2w_game_yaml_delta.txt` rather than in a shell
string. **The rule to carry forward: overriding one shared file costs you
the whole yaml that pulled it, and the two copies then have to be kept in
step by hand at every uprev.**

**AND A NEW jtframe MODULE IS PULLED BY THE CORE, NOT BY jtframe.** D2 adds
`modules/jtframe/hdl/sdram/jtframe_ram1_7slots.v` (bank 0 needs seven
streams; upstream's `ram1_Nslots` family stops at five). jtframe's own
`hdl/sdram/jtframe_sdram64.yaml` lists that family — and it is SHARED, so a
line there would put the new module on EVERY jtcores core's compile list,
the reference `cps2` included. Instead cps2w's `game.yaml` pulls it with
`- from: sdram / get: - jtframe_ram1_7slots.v`, exactly the way
`cores/cps1/cfg/common.yaml` pulls `jtframe_romrq.v`. Measured: it is absent
from `jtframe files sim cps2`. Gate: `test_mister_wide_gate` 5b/7n.

`cfg/macros.def` (cps2): `include ../../cps1/cfg/common.def`, `CPS2`,
`GAMETOP=jtcps2_game`, `CORENAME=JTCPS2`, `JTFRAME_SDRAM_LARGE`,
`JTFRAME_HEADER=44`, `JTFRAME_IOCTL_RD=128`, `JTFRAME_DIPBASE=16`,
`JTFRAME_DIAL`, `CPS1_NOOBJ`, `JTFRAME_OSD_TEST`, MiSTer: `JTFRAME_MR_DDRLOAD`.
**[MSC-5]** cps2w's `macros.def` differs by `CORENAME=JTCPS2W` only — and it stays that
way ON PURPOSE: **the WIDE profile is NOT a macro.** See "The runtime profile
gate" below.

## The runtime profile gate: MRA header byte 41 (slice D1, measured 14z-107)

**[MSC-8]** Maintainer ruling, 2026-08-23: the profile is selected at RUNTIME from a
spare MRA header bit, not by an `ifdef`. The consequence is the point —
**stock `vsavj` on `jtcps2w.rbf` runs with the widened behaviour CLEAR**, so
CLAUDE.md rule 1 v2's "profile-gated so stock `vsavj` is untouched BY
CONSTRUCTION" is a fact on FPGA rather than an inertness argument.

- **[MSC-9]** **Which byte, and why it is free.** `jtcps1_prom_we.v` consumes header
  bytes 0-7 (the four region start words), 8-39 (`is_cps`, the CPS config
  registers, `REGSIZE=24` + `START_HEADER=16`) and 40 (`JOY_BYTE = 6'h28`);
  44-63 are the CPS-2 key (`CPS2_KEYS = 26'd44`). Bytes **41-43 fall through
  every branch of its decoder and are ignored**, which is what the file's own
  comment at `:52-54` ("6 are actually used and 10 are reserved") is
  describing. `JTFRAME_HEADER=44`, so byte 41 exists in every CPS-2 `.rom`.
- **[MSC-10]** **ACTIVE LOW, and that is forced rather than chosen.**
  `cores/cps2/cfg/mame2mra.toml` declares `[header] fill=0xff`, so an
  unwritten header byte is `0xFF`; the stock `vsavj` MRA emitted by cps2w has
  to stay byte-identical to cps2's. Only a polarity in which the FILL means
  "profile off" can do that. jtframe's own `JOY_BYTE` has exactly this shape
  (0xFF = joystick mode 3; the games that want mode 0 write `fc`).
  So: **byte 41 bit 0 CLEAR = CPS-2 WIDE**, and the WIDE MRA writes `fe`.
- **[MSC-11]** **How the row is scoped.** `RawData` embeds `Selectable`
  (`src/jtframe/mra/types.go`), so `{ setname="vsavjw", offset=41, data="fe" }`
  scores 3 for that set and 0 for everything else — no other MRA gains a byte.
  Measured end to end: the stock `.rom` byte 41 is `0xFF` and the WIDE
  `.rom`'s is `0xFE` (`tests/test_mister_mra_map.sh`).
- **Where it lands in RTL.** `cores/cps2w/hdl/jtcps2w_profile.v` snoops the
  ioctl stream in the game top and outputs `wide_en`; it re-defaults at the
  first byte of every download, ignores `ioctl_ram`, and is inert for every
  address but 41. Every gated site takes that wire — in D1 the QSound bank
  latch (`jtcps2w_qsnd_bank.v`), later the group-C redirect, the obj promote
  and the PRG window.
- **The lane's anchor gate is a cross-IMPLEMENTATION oracle**
  (`tests/test_mister_sim_anchor.sh`) and `tests/test_mister_wide_inert.sh`
  (cps2 vs cps2w, bit-identical work RAM frame by frame) is the inertness
  instrument. D1's "video-sensitive anchor" was the harness, not the
  profile — "The harness's forked frame writer rewound the simulated input
  script" below; the root-causing is in the history.
- **[MSC-12]** **Clock domains, so it is not asked later.** The decoder runs on the game
  port's `clk`, which jtframe documents as "always matched to the SDRAM
  clock" (`jtframe_common_ports.inc:5`) and which on a `JTFRAME_CLK96` core
  like CPS-2 is the same 96 MHz net the QSound block's `clk96` is. Even if it
  were not, `wide_en` is a STATIC configuration bit: it is written only while
  the ROM streams, with the core (and the QSound DSP, `qsnd_rst`) held in
  reset, and is constant for the whole of play. There is nothing to
  synchronise.

## The harness's forked frame writer REWOUND the simulated input script (root-caused 14z-107, fork commits 8-9)

**The mechanism** [M: 14z-107 (7), `build/fork_rewind_14z107.log`]: jtframe's
Verilator harness forks a child per CHANGED frame (unconditionally —
`bin/jtsim:460` `mkdir -p frames`, `video_dump()` guarded by no macro;
`-video` only defines a macro `test.cpp` never reads); the child ended with
`exit(0)`, whose stdio cleanup `fclose()`s the inherited copy of the parent's
`sim_inputs.hex` stream; on a seekable READ stream that repositions the
file description SHARED with the parent, so the parent's next buffer refill
re-reads lines it had consumed — **the simulated controller script was
replayed once per fork**, and the number of forks follows the PICTURE (a
black-screen core forks about once). That is the whole of D1's "video
sensitivity": the harness's frame writer corrupted the simulated input
script; the picture never reached the CPU.

**The 2x2 control** (`cps2w`, stock `vsavj`, `05_timeout_idle`, work RAM
dumped every frame 2000-2680, 681 dumps per leg, same `.rom` / inputs /
RTL list):

| leg | fork()s | match-start anchor |
|---|---|---|
| LUT present, frame output OFF | 0 | **2609** |
| LUT absent, frame output OFF | 0 | **2609** |
| LUT absent, frame output FORK | 1 | **2609** |
| LUT present, frame output FORK | **1,348** | **2502** |

OFF legs bit-identical 681/681 with the LUT present or absent; same core
OFF vs FORK differs in 483 of 681 frames from frame 2051, first byte
`RAM:$FF8060` (the per-player START bitmask — an input-derived value); fork
mode twice is bit-identical (the corruption is DETERMINISTIC, which is why
it looked like a property of the design). **The frozen 2502/356 was the
artifact and D1's red 2609/463 the measurement**; the gate is frozen at
2609/463, band ± 30. Ground truth independent of any core:
`tests/test_sim_wram_contract.sh` 10/11/11c (a forking line reader ends at
line 278 with `exit()` children and 3000 with `_exit()`; N `exit()`ing
children flush N copies of buffered stdout — 212 duplicate `$display`
lines measured).

**The fixes, both in the fork, no RTL:** commit 9 — the child `_exit(0)`s
(the repair, one word); commit 8 — `JTFRAME_SIM_NOVIDEO` compiles the
writer out and `tools/run_sim_jtcps2.sh --frame-output off` is the lane's
default, plus `waitpid(WNOHANG)` reaping (upstream leaves one zombie per
changed frame; at `RLIMIT_NPROC` = 2666 on a stock macOS account `fork()`
fails and frames stop with no diagnostic).

**What was never at risk:** the RAM dumps — written by the PARENT from a
local `ofstream` inside one call at the VS rising edge, no descriptor open
across the `fork()`. The §4 field agreement stands; the anchor frame index
is re-frozen above; `tests/test_mister_wide_inert.sh` compares two cores
rendering the SAME picture and is invariant to it; the per-bank profile
was re-derived from its committed log (figures moved < 1%). The palette
LUT is innocent (`jtcps1_pal.v` `we` tied low; a missing `pal_lut.hex` is
a Verilator `%Warning` that changes exactly the picture). The chain as it
was traced link by link is in `mister_history.md`.

## `SimInputs` HELD BUTTONS 5 AND 6 DOWN — an 8-bit mask on a 10-bit active-low port (measured and fixed 14z-107, fork commit 10)

The second harness defect of the same family as the frame writer, and the
one that made the two legs of the §4 oracle run DIFFERENT INPUTS.

**The bug, both halves.** `joystick1..4` are declared `[9:0]` in
`modules/jtframe/hdl/ver/game_test.v:51-54` and are ACTIVE LOW.
`SimInputs` treats them as 8-bit in two places:

1. `parse_inputs()` builds the word correctly —
   `dut.joystick1 = 0x30f | ((v>>4)&0xf0);` releases bits 9:8 (buttons 6
   and 5) — and throws it away on the next line,
   `dut.joystick1 = (dut.joystick1&0xf0) | (v&0xf);`. `&0xf0` keeps only
   buttons 1-4; bits 9:8 go to 0, which on an active-low port means
   PRESSED. All five `JTFRAME_JOY_*` orderings carry the same mask. Only
   EOF releases them (`next()`'s else-branch restores `0x3ff`), so a
   SHORTER input file changes the inputs — the opposite of what truncation
   should do.
2. The constructor seeds `joystick1..4` with `0xff` — bits 9:8 low again.
   `parse_inputs()` never writes `joystick2..4`, so **P2's buttons 5 and 6
   were held for the whole run on every core, with or without `-inputs`.**

Cores with 4 buttons or fewer never see it: `game_test.v:557-561` passes
`joystick*[GAME_BUTTONS+3:0]` to the game, so the bad bits are not wired.
On a 6-button core they are — `cores/cps2/hdl/jtcps2_main.v:266-268` wires
`joystick1[9:7]` into `in1[2:0]`, `joystick2[8:7]` into `in1[5:4]` and
`joystick2[9]` into `in2[14]`, which is exactly MAME's cps2 input map
(`tests/lua/replay.lua:76-85`: P1 buttons 5/6 in `:IN1`, P2 button 5 in
`:IN1`, P2 button 6 in `:IN2`).

**MEASURED AT THE PIN, NOT DEDUCED FROM THE SOURCE.** The observable is the
game's own input mirror, located by a MAME differential rather than
assumed: run `05_timeout_idle` twice, once with `p1=56` held for six
frames, and diff whole work RAM at the onset. 36 bytes move at frame 1000
and among them are **`RAM:$FF8058` (P1 held-buttons high byte) and
`RAM:$FF805A` (P1 new-press)**; the P2 twins are **`$FF805C`/`$FF805E`**
(same experiment with `p2=56`). Bit 0x40 = button 6, 0x20 = button 5. The
block goes live at MAME frame ~92-96, right after the RAM test — so a
~620-frame simulation reaches it, and a whole run is not needed to see it.

| leg (block `$FF8040-$FF8070`, aligned frames) | `$FF8058` | `$FF805A` | `$FF805C` | `$FF805E` |
|---|---|---|---|---|
| MAME, `05_timeout_idle` verbatim (nothing held) | 00 | 00 | 00 | 00 |
| MAME, same + `p1=56` held | **60** | **60** | 00 | 00 |
| MAME, same + `p2=56` held | 00 | 00 | **60** | **60** |
| MAME, same + `p1=56 p2=56` held | **60** | **60** | **60** | **60** |
| **sim BEFORE the fix** (cps2, stock `vsavj`, script presses nothing) | **60** | **60** | **60** | **60** |
| **sim AFTER fork commit 10** | 00 | 00 | 00 | 00 |

The before-fix simulation's whole 49-byte block is **byte-identical to the
MAME leg that physically holds P1 AND P2 buttons 5+6**, and differs from
the MAME leg running the same script. That is the defect end to end: the
harness, the port, the RTL and the game agree on what was pressed, and
nothing in `sim_inputs.hex` asked for it. After the fix the block is
byte-identical to MAME's no-input leg.

**The fix's footprint is the inputs and nothing else** [M: 14z-107 (8)]: at
boot two otherwise identical `cores/cps2` runs (frames 560-620) differ in
**8 bytes of 65,536** — `$FF8058/5A/5C/5E` (0x60 -> 0x00) and
`$FF8060-$FF8063` (0x40 -> 0x00); across the §4 window (frames 2400-2800,
same `sim_inputs.hex` sha1 `931e6caf…`) in **29 addresses**: the raw mirror
and its `$FF806x` derivative, the per-player input word `+0x394`, the
in-match copies `+0x122/124/12A/12C`, four one-frame companions, and the
two documented phase classes (`$FF06B0/B5/B9`, `$FF7FC4/C8`). No HP,
position, timer, meter, identity or anim cursor differs — which is why the
anchor stays 2609 and the §4 field verdict is unchanged. The address table
is in the history.

**THE FIX (fork commit `519aff8b`, `emu/jtcores-patches/0010-…`, pin
bumped, LOCAL ONLY):** `& ~0xf` instead of `& 0xf0` — keep every button bit
the port has, whatever `JTFRAME_BUTTONS` is — and `0x3ff` instead of `0xff`
for the four seeds. Unconditional, no macro, 1 file: this is a plain
upstream bug, not a profile change, and it would be a clean upstream report.
`tests/test_sim_wram_contract.sh` check 12 holds the pinned `test.cpp` to it
with a must-fire control.

**WHAT IT IS NOT.** It does not add P2 or button 5/6 SCRIPTING — that was
the COVERAGE half, ruled "later" at the time. **[DONE for P2 at 14z-109:
fork commit `4dfc3734` + `rpl2siminputs.py` emit P2 directions/buttons 1-3
into previously-unused file bits 12+, provably byte-identical for every
older replay (the frozen `eb3e1d04…` sha1 asserted unchanged). Buttons
4/5/6 remain refused. First real use: `109_2p_don_vs_phobos.rpl`.]** The
FIDELITY half is what shipped here, because it is a bug and it was making
the oracle's two legs run different inputs.

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
  **Re-verified 14z-107 against the v1.7.3 pin. FIXED 14z-107 (6) (slice
  D1): the latch is now 8 bits behind `wide_en`.** The bank bit is
  `dsp_ab[7]` — validated against MAME's LLE device, not assumed; see "The
  QSound bank bit" below. ~~16 MB of QSound FITS SDRAM bank 1 on the
  EXISTING 64 MB tier — PCM is alone in that 16 MB bank.~~ **RETRACTED:** the
  BANK has the room, the SLOT does not (8 MB cap, "jtframe's 8-bit SDRAM slot
  CAPS AT SDRAMW" below).

## The QSound bank bit IS `dsp_ab[7]` (validated against MAME's LLE device, 14z-107)

**[MSC-30]** The width fix rests on this and `jtcps15_sound.v:416-417` shows the original
author was unsure: it carries a commented-out alternative
`{ dsp_ab[2:0], dsp_ab[4], dsp_ab[5], dsp_ab[6], dsp_ab[7] }`, a 7-bit
permutation that drops `ab[3]` entirely. MAME's low-level QSound device
settles it (`emu/mame/src/devices/sound/qsound.cpp`, the `QSOUND_LLE` build
this project's oracle uses):

- `dsp_io_map`: `map(0x0000, 0x7fff).mirror(0x8000).r(dsp_sample_r)` — the
  DSP16A external ROM space is decoded on `ab[14:0]` with `ab[15]` as the
  mirror bit, which is the same qualifier jtcps15 uses;
- `dsp_sample_r`: `m_rom_bank = (m_rom_bank & 0x8000U) | offset;` — the bank
  register is loaded with that address STRAIGHT, no permutation and no gaps;
- the sample byte is `read_byte((u32(m_rom_bank) << 16) | m_rom_offset)`.

So the bank is a plain binary number in `ab[14:0]`, bit 7 is `ab[7]`, and the
latch can be widened one bit at a time. `dsp_ab` is 16 bits and only
`dsp_ab[15]` is consumed elsewhere, so bits 7..14 are all free — 8 bank bits
is not close to a limit. `tests/test_mister_wide_gate.sh` check 4 re-reads
those three MAME lines every run, so the evidence cannot rot silently.

**Recorded, NOT fixed, because it is pre-existing and out of D1's scope:**
MAME documents a ONE-READ LATENCY ("the bank applies to the next read, not
the current read... you need to set it on the channel before the desired
channel") and models it by updating `m_rom_bank` AFTER the fetch. jtcps15
latches the bank from `ab` on the cycle the external read is presented, i.e.
with no latency. That is a difference in the REFERENCE core, it is unchanged
by the width fix (which is bit-for-bit stock when `wide_en` is low), and
touching it would alter stock behaviour — so it is a finding for the audio
comparison to settle later, not a D1 edit.

## The SDRAM ceiling at our pin: 64 MB is PHYSICAL (measured 14z-107)

**[MSC-16]** At `v1.7.3` the 64 MB tier is not a default with a wider one behind it — it
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

  **[MSC-18]** **Consequence worth stating plainly: on a DE10-Nano the dual-CHIP SDRAM
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

**[THREE OF THE FOUR ARE NOW LIFTED IN `cores/cps2w`: the QSound width in
slice D1, the OBJECT PROMOTE in D3 and the PROGRAM WINDOW in D4 (14z-107
(10)). The paragraphs below stay as the READING of the reference core, which
is what they were; the as-built expressions are in
`docs/project/mister_map.md` §6 and §8.]**

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
- **QSound's bank latch is exactly as this project documented it — but
  `PCM_AW` 23 -> 24 IS NOT PART OF THE FIX, and that half is RETRACTED
  (measured 14z-107 (6); see "jtframe's 8-bit slot caps at SDRAMW" below).**
  `cores/cps15/hdl/jtcps15_sound.v:416` `qsnd_addr[22:16] <= dsp_ab[6:0];`
  discards `dsp_ab[14:7]`, so banks >= 0x80 alias onto 0x00-0x7F. The fix
  that stands is one bit (`qsnd_addr[23:16] <= dsp_ab[7:0]`) plus
  `qsnd_addr` -> `[23:0]`; it shipped in slice D1, gated by `wide_en`.
  ~~**16 MB of QSound fits SDRAM bank 1 on the EXISTING 64 MB tier**: PCM is
  alone in that 16 MB bank (`jtcps1_sdram.v:332-345`, `jtframe_rom_1slot`,
  `SLOT0_AW = PCM_AW`).~~ **FALSE.** The bank has the room, but the SLOT
  cannot address it: an 8-bit `jtframe_rom_1slot` is capped at
  `AW <= SDRAMW = 23`, i.e. 8 MB. That is why the placement map splits
  QSound across two banks instead of growing one slot.

## jtframe's 8-bit SDRAM slot CAPS AT SDRAMW (measured 14z-107)

`modules/jtframe/hdl/sdram/jtframe_romrq_bcache.v:74`:

    assign sdram_addr = offset + { {SDRAMW-AW{1'b0}}, addr_req>>(DW==8)};

`SDRAMW-AW` is a REPLICATION COUNT. At `SDRAMW=23` it is legal for
`AW <= 23` and NEGATIVE for anything wider, which is a hard error, not a
warning: Verilator 5.050 says *"Replication value of < 0 or X/Z not legal
(IEEE 1800-2023 11.4.12.1): '32'hffffffff'"* and exits 1 (`AW=24` and
`AW=25` both measured, `jtframe_rom_1slot` -> `rom_2slots` -> `romrq_bcache`
at `SDRAMW=23`, `DW=8`). So a byte-addressed slot reaches at most 2^23 = 8 MB
of a 16 MB bank, and every "just widen `PCM_AW`" plan is a build failure
rather than a design trade. `tests/test_mister_wide_gate.sh` 3d/3e keeps this
from being re-proposed.
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
  dip_test). **P1 only, 4 buttons** — P2 does not exist in that harness.
  (P1-only was the harness at the pin; buttons 5/6 — and P2's — were in fact
  HELD DOWN by the harness's 8-bit mask, fixed by fork commit 10:
  "`SimInputs` HELD BUTTONS 5 AND 6 DOWN" above.)
  **What is STILL true after the fix: the harness can express P1 only, with
  buttons 1-3** (bit 11 doubles as `dip_test`, so button 4 is refused).
  Buttons 5/6 and P2 are now RELEASED rather than held — they are still not
  SCRIPTABLE.
  `tools/rpl2siminputs.py` translates `.rpl` → `.hex` and
  REFUSES p2 / buttons 4-6 / service-test loudly (unchanged by commit 10 —
  releasing a button is not scripting it) (measured on four legacy
  replays: `01_attract_long` (7200 frames, no input) and `05_timeout_idle`
  (12000 frames, 13 active) translate; `04_select_fuzz` and
  `02_demitri_vs_cpu` REFUSE on P1 button 4). Gate
  `tests/test_rpl2siminputs.sh`. Extending the harness (P2, 6 buttons) is fork
  work on `test.cpp`, to be done when a refused replay is needed.
- **State out.** Neither `JTFRAME_SIM_IODUMP` nor `JTFRAME_SAVESDRAM` reaches
  68k work RAM on this core and simulator [M: 14z-107; the retracted
  "reachable out of the box" bullet is in the history]:
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
   private `pocket` target), builds the Go tool. **[MSC-37]** **Simulate in a SCRATCH
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
   `f9dc2987…`) — the `.rom` is ROM content: scratch only. **[MSV-19]** **Since
   14z-107 (5) do not do this by hand either:** `ROMDIR=...
   tools/mister_mra.sh --core cps2w [--wide build/m3b_merged16] --out <dir
   outside the repo>` (the current freeze's build — `m3b_merged13`, which
   the measurements further down this file name, was deleted in the
   14z-112 sweep; those records stay as written) does the clone, the private `$HOME` staging and the
   run, and prints the size + sha1 of every `.rom` it makes. `--wide` is
   what selects the WIDE leg's zips; without it you get the stock reference
   leg. **CORRECTED 14z-112: builds no longer pack a parent — the four patched members live INSIDE `vsavjw.zip` and BOTH legs use the PRISTINE dump, so one SD card can carry this profile and stock Vampire Savior.**
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
   simulated frame. **Since 14z-107 (7) it runs with HOST FRAME OUTPUT OFF
   by default** (`--frame-output off|fork|collect`) and asserts the dump set
   it produced is complete — see "The harness's forked frame writer REWOUND the simulated input
   script". Pass `--frame-output collect` when you actually
   want to LOOK at the picture; that is now safe as well, since fork commit
   9, but it is not what a state measurement should be doing.

## The Verilator SDRAM model dropped the TOP address bit — `addr[22]` rides on `sdram_a[9]` (measured and fixed 14z-107, fork commit 3)

**The symptom, unchanged:** at `JTFRAME_SDRAM_LARGE` the C++ SDRAM in
`modules/jtframe/hdl/ver/test.cpp` decoded only 22 of the 23 address bits,
so **the upper 8 MB of every bank aliased onto the lower 8 MB** — including
during the ROM download, which therefore never wrote the upper half at all
(it stayed at the constructor's `memset(0)`) and overwrote the lower half
with the upper half's content.

**The mechanism** (the first reading, "13 row + 9 column, fix three constants",
assumed the missing bit was `addr[9]` — it is not; history). In
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
  (The absolutes 2507/2502 were later retracted — the frame writer was
  replaying the input script; the clean anchor is 2609 / skew 463 — but the
  five-frame MOVE stands, a difference between two runs sharing the
  corruption.)
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

## The work-RAM oracle: `JTFRAME_SIM_WRAMDUMP` (measured 14z-107)

**Where 68k work RAM is, read from the RTL and then CONFIRMED against the
running core.** `jtcps1_sdram.v:158-164` `WRAM_OFFSET = 23'h30_0000` in 16-bit
WORDS; `jtcps2_main.v:127,185` `pre_ram_cs = &A[23:16]` (i.e. `$FFxxxx`) and
`addr = ram_cs ? {2'b0,A[15:1]} : A[17:1]`; `jtframe_ram_rq.v:94` composes
`sdram_addr = addr + offset`. So **on the REFERENCE core `RAM:$FF0000-$FFFFFF`
= SDRAM bank 0 byte offset `0x600000`, 64 KB**. **[MSV-12]** **QUALIFIED 14z-107 (9): THAT
OFFSET IS PER CORE NOW.** Slice D2 re-packed bank 0 to make room for a 6 MB
PRG region, so on `cores/cps2w` work RAM is at byte **`0x648000`**
(`WRAM_OFFSET` word `0x32_4000`) and `0x600000` is **VRAM**. The dump hook
addresses SDRAM, not the 68k bus, so the constant has to follow the core:
`tools/run_sim_jtcps2.sh` selects it from `--core` and prints which one it
used. Getting it wrong does not announce itself — VRAM is a perfectly
plausible-looking 64 KB of changing bytes, and it turned
`tests/test_mister_wide_inert.sh` red in 101 frames of 101 with the RTL
entirely innocent (measured 14z-107 (9)). Confirmed by dumping the WHOLE 16 MB bank at a
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
the simulated core does it at GAME frame 71 = absolute frame 533, so
**simulated absolute frame ≈ MAME frame + 460** during boot. The round-1
match-start anchor of `05_timeout_idle` is MAME **2146** / sim **2609**,
skew **+463** — three frames LATER than the boot offset, not earlier
(`tests/test_mister_sim_anchor.sh`; the retracted 2507 / 2502 / 2606
readings and what produced each are in the history).

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

**[MSV-23]** **THE ANCHOR MEASUREMENT (stock `vsavj`, `05_timeout_idle`).** Round-1 match
start: MAME frame **2146**, simulated frame **2609** — skew **+463**,
RE-MEASURED 14z-107 (7) with host frame output OFF, and measured four ways in
one 2x2: every leg that forks once or not at all reports 2609, and only the
leg that forks 1,348 times reports 2502. ~~2507 / +361 (14z-107), 2502 / +356
(14z-107 (3))~~ — both retracted; they were measured while the harness was
replaying the input script. **RE-MEASURED AGAIN 14z-107 (8) after the
joystick fix — 2146 / 2609 / +463, UNCHANGED**, and that is the result: every
earlier reading of this anchor was taken with the harness holding four
buttons down (P1's and P2's 5 and 6), and correcting them moves nothing here.
Mechanism, not luck: a button held from before boot produces no PRESS EDGE,
and this replay's only inputs are a coin, a start and one button-1 tap. The
re-measurement searched 2100-3000 rather than the gate's 2400-2800 so the
answer could not be boxed in by the window, and reports 2609 either way. Note that 463 is close to but not equal to the
boot offset (+460): the attract/select/VS path costs a few frames more on the
core than on MAME, which is why CLAUDE.md §4 compares mapped state at ANCHORS
rather than at fixed frame indices. At the anchor and at +60/+180,
every compared field agrees: `timer` 0x63, both HP 0x120, both white HP, both
meter fields, `p1_hitbox_base` **$093B6A on both** (Demitri — P1's pick
matches), `p1_ptr64`, `p1_word132`, `p1_x/y/flip/attack_id`, and even the
`phase` field `p1_anim_ptr` ($12CDF6 on both).

**[MSV-24]** **THE ONE DISAGREEMENT, AND IT IS THE GAME'S OWN LOTTERY.** The CPU opponent
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
[--frames N] [--wram FIRST LAST] [--core cps2|cps2w]
[--frame-output off|fork|collect]`, with `ROMDIR` and
`JTSIM_SCRATCH` in the environment. Every step is idempotent (clone, symlinks,
Go build, MRA, seed), it prints the sha1 of everything it reads, and it
REFUSES an out-dir inside the repo (rule 7) or a scratch clone inside it.
**[MSC-43]** **Since 14z-107 (7) it also asserts the DUMP SET** — every `--wram` run ends
with `tools/check_wram_dumps.py`, which requires every frame of
[FIRST..LAST] to exist, at exactly the requested length, with the requested
address in its name, and fails the run otherwise. That check exists because
`tools/compare_fields.py` GLOBS a directory: a dump that is never written
does not fail a comparison, it silently changes WHICH frames the anchor
search sees. The gates run the same tool on any dump directory they did not
produce (`test_mister_sim_anchor.sh` runs it on the MAME leg too,
with `--contiguous` available for a directory of unknown extent).

**Times measured on this machine (Apple Silicon, Verilator 5.050):**

| step | wall |
|---|---|
| ROM download (`-load`), EVERY run, 462 simulated frames | ~7-11' |
| incremental rebuild after a `test.cpp` edit or a macro change | ~4 s |
| simulation | **~0.98 s per frame** (540 frames incl. download in 8'50"; 330 frames in 5'41" on the preloaded path) |

Only `test.cpp` includes `defmacros.h`, so changing the dump window rebuilds
one object and relinks — it does NOT re-verilate the model. A per-window
rebuild is ~4 s, not minutes.

## The pre-D5 boot loop: the WIDE romset reset at core frame ~448 until the decryption range was fixed (measured 14z-107, resolved in slice D5)

Before D5 the WIDE image — `vsavjw.rom`, 66,265,152 B —
never left its boot sequence on `cps2w`: the RAM test, the boot screens,
the legal screen static for 664 frames, then a RESET (a ~1,580-frame,
26 s cycle); ZERO sprite reads in SDRAM bank 2 and in both group-C windows
while bank 3 served a 264-block scroll working set over and over; MAME on
the same romset and replay at the select screen by frame 930. Traffic was
IDENTICAL to the stock image for 447 core frames and diverged at ~448,
the end of the third boot phase. The eliminations that bracketed it — not
the eight `wide_en`-gated sites (on the masked basis profile-on and
profile-off produced bit-identical work RAM), not the download (the census
passed), not the romset, not a black-screen artefact, not the probe (the
stock image counted 313,024 bank-2 reads), not the core (stock content ran
to the frozen anchor and bit-identical against `cps2`) — and the §4
differential that named the SOUND DRIVER as the first divergent state (MAME
frame 266: `$FF025C/D`, `$FF0462/3`, `$FF04A1-B5`; 748 bytes at 461) are in
`mister_history.md` verbatim. The cause was the CPS-2 DECRYPTION RANGE, next
section. One elimination was wrong in a telling way: "profile-on and
profile-off are frame-for-frame identical" was true of bank-3 traffic and
masked RAM and FALSE of the program window — the profile-ON leg completed
ten program-ROM reads above `CPU:$400000`, the CLEAR leg zero, and the
instrument that said "identical" could not see the window it was asked
about.

## CAN THE 68k READ ABOVE 4 MB? YES — AND WHAT IT GETS IS THE DECRYPTOR'S OUTPUT (measured 14z-107)

**THE THREE-WAY DISCRIMINATOR WAS RUN AND THE ANSWER IS THE THIRD ONE.** The
question was whether slice D4's 6 MB program decode actually functions, because
if it did not, `wide_en` SET would behave exactly like `wide_en` CLEAR for every
read above `CPU:$400000` and the "profile-on and profile-off are frame-for-frame
identical" elimination would be explained by a DEAD DECODE rather than by an
innocent profile. It is neither: **the decode works, the SDRAM returns the
romset's bytes, and the CPS-2 DECRYPTOR corrupts them on the way to the 68k.**

**THE INSTRUMENT** is `JTCPS2W_PRGPROBE` in `cores/cps2w/hdl/jtcps2_main.v`
(fork commit 16), armed by `tools/run_sim_jtcps2.sh --prgprobe` and read by
`tools/prgprobe_verdict.py`. It is deliberately two instruments: an ADDRESS half
that classifies every 68k bus cycle by `A[23:21]` with no chip select in the
condition — which is what still speaks when `wide_en` is clear and `rom_cs`
cannot assert in the window at all — and a DATA half that logs every COMPLETED
program-ROM read with the word the CPU LATCHED (`rom_dec`, what `cpu_din`
takes) and the RAW SDRAM word behind it. Both legs also carried the SDRAM read
probe on bank 0 as an independent second layer.

**THE PAIR** (`11_pick_donovan`, `cps2w`, the real `vsavjw.rom` sha1
`d462e55a…`, 2,300 simulated frames = 1,641 after reset, so the boot's own
reset at 2242 is inside the window). The two legs differ by ONE BYTE of the
`.rom` — header byte 41, `0xFE` against `0xFF`:

| | `wide_en` = 1 | `wide_en` = 0 |
|---|---|---|
| 68k bus cycles, all | 71,326,093 | 71,315,522 |
| ...targeting `$400000-$5FFFFF`, READS | **10** | 4 |
| ...targeting `$400000-$5FFFFF`, WRITES | 7,198 | 7,198 |
| COMPLETED program-ROM reads above `$400000` | **10** | **0** |
| ...below `$400000` (the must-fire control) | 54,961,148 | 54,954,608 |
| SDRAM read probe, bank 0 `0x400000-0x600000` | **16 word reads**, 1 block, `0x4BE7C0-0x4BE7CE` | **0** |
| SDRAM read probe, bank 0 `0x000000-0x400000` | 62,934,136 reads, 277 blocks | 62,924,028, 277 |

**THE TEN RECORDS, AND THEY ARE THE WHOLE FINDING.** All ten are at
`CPU:$4BE7C0-$4BE7C8` — five at simulated frame **1119** and the same five again
at **2246**, i.e. once per turn of the boot loop. All ten carry **`fc = 2`,
USER PROGRAM: they are OPCODE FETCHES.** The 68k is EXECUTING from the program
extension. And:

* every one of the ten RAW words is the `.rom`'s byte for byte;
* every one of the ten LATCHED words is **different** — `7EDD` where memory
  holds `4DED`, and so on for all five.

**THE MUST-FIRE EVIDENCE, in the same run and the same counters.** 54,961,148
reads below `$400000`, of which the first 2,000 are logged with their bytes:
**2,000 of 2,000 match the `.rom`**, and they split exactly along the CPS-2
rule — `fc = 5` (supervisor DATA) 824 records, **none** decrypted; `fc = 6`
(supervisor PROGRAM) 1,176 records, **all** decrypted. A zero above the line
would have meant nothing without that; and the same sample is what CALIBRATES
the byte order (`rom[off+1]<<8 | rom[off]` scores 2000/2000, the other order
59/2000), so the comparison is derived rather than assumed.

### WITH SLICE D5 IN: THE BOOT SURVIVES, AND A TENANT TILE IS FETCHED

Same core, same `.rom`, same replay, 2,900 simulated frames, `cps2w` carrying
D5 (fork `c00d7ce7`). The read probe was re-armed on the FOUR windows
`tests/test_mister_gfxc_fetch.sh` uses, so this one run is both the boot
verdict and the D3 demonstration.

* **The same five opcodes at `$4BE7C0` now arrive as memory holds them** —
  `4ded 4ded`, `3800 3800`, `1b7c 1b7c`, `0020 0020`, `00b5 00b5` — and the
  68k keeps going instead of stopping at the fifth.
* Completed program-ROM reads above `$400000`: **10 → 1,189,750**, spanning
  `CPU:$412BA0-$4D100E`, which is `wide_ext` (`0x400010-0x4D1100`) to the byte.
* The boot passes the point it used to die at, reaches the title screen (bank 3
  at 48,928 words/frame — the STOCK image's own title-screen figure) and then
  the select screen.

| read probe window | reads | distinct 128-byte blocks | first frame | range |
|---|---|---|---|---|
| ba1 `0x800000+` — group C obj **bank 4** (fighter art) | 0 | 0 | — | — |
| ba0 `0x7E0000+` — group C obj **bank 5** (wheel art) | **9,038,400** | **105** | 1556 | `0xB86B00-0xFD20FE` |
| ba2 whole bank — vanilla obj banks 0/2 | 2,316,480 | **372** | 1741 | `0x817600-0xA3E4FE` |
| ba3 whole bank — vanilla obj banks 1/3 + scroll | 97,797,780 | 2,423 | 659 | `0x000000-0x9C177E` |

**Two things to read off that table.** The group-C bank-5 window — 8 MB of
SDRAM that had NEVER been read on any core — is being fetched from, 105
distinct tile codes, and every one of them is inside the roster's frozen live
extent for that bank (`0xFFDB`; the highest code touched is `≈0xEA41`). **That
is a tenant tile fetched on the core, and it is the first one ever.** And the
vanilla banks now read what the STOCK image reads on a healthy boot — **372
distinct blocks in bank 2 and bank 3 reaching `0x9C177E`, the same figures
recorded for the stock leg in the section below.** Obj bank 4 stays at zero
because this replay window ends before a match starts; the fighter art is the
next thing to reach.

**And the 105 tile codes were checked, not just counted.** Re-run through
`tests/test_mister_gfxc_fetch.sh --pos-log … --neg-log …`, the wheel-art half
is GREEN: codes **`0x74D6-0xFE41`**, all inside the roster's frozen live extent
`0xFFDB` for that bank, with the control leg at zero. **The fighter-art half
(obj bank 4) is still RED and stays red**: this replay window ends at the
select screen and no match starts, so no fighter sprite is emitted. A gate that
went green on evidence it does not have would be worse than a red one.

(The gate's own first real measurement found two defects in the gate — a
tile code computed from the absolute SDRAM address rather than the window
base, and a control leg required to show traffic it could never produce;
both fixed, record in the history.)

**The stock legs are unmoved, which is the superset invariant on the one change
that could have broken it.** `tests/test_mister_wide_inert.sh` PASSES — `cps2w`
against `cps2`, BIT-IDENTICAL work RAM in all 101 frames, control firing — and
`tests/test_mister_sim_anchor.sh` PASSES at **sim 2609 / MAME 2146 / skew 463**
(frozen 463 ± 30) with every mapped field agreeing and all four controls
firing. Both are true by construction as well as by measurement: `rng_eff` IS
`addr_rng` with `wide_en` clear.

### THE MECHANISM: THE CPS-2 KEY'S RANGE WORD IS STORED COMPLEMENTED

The CPS-2 key's last decoded word carries the encrypted-OPCODE range. **MAME
and FBNeo both read it complemented** — `cps2_crpt.cpp:771`:

```c
upper = (((~decoded[9] & 0x3ff) << 14) | 0x3fff) + 1;
```

**`jtcps2_dec_ctrl.v:44` does not:**

```verilog
en_latch <= op_fetch && en && (addr[14+:10] <= range[9:0]);
```

For `vsavj` the word is **`0x03C0`** (computed two independent ways from the
same 20 key bytes: jtframe's `jtcps2_keyload` permutation, and FBNeo's
`(317-b) % 160` permutation — they agree). So the two implementations disagree
by a factor of fifteen:

| | encrypted-opcode window | blocks of 16 KB |
|---|---|---|
| MAME / FBNeo | `CPU:$000000-$0FFFFF` | `~0x3C0 & 0x3FF` = **63** |
| jtcps2 (reference core) | `CPU:$000000-$F03FFF` | `0x3C0` = **960** |

**EVERY STOCK CPS-2 GAME HIDES THIS, and that is why it has survived.** The only
code that ever executes is the code Capcom encrypted, which is inside the real
window either way; the region above it holds DATA, and data reads are not opcode
fetches, so neither implementation decrypts them. **CPS-2 WIDE is the first
thing to put EXECUTABLE content above the window** — `build/m3b_merged13`
allocates `wide_ext` from `0x400010`, and `$4BE7C0` is inside it.

This also explains why 14z-56's **B4 (prg) passed on FBNeo**: B4 relocated
*data* tables (the twenty per-character sound record arrays) and data reads
bypass the decryptor on every implementation. Nothing had ever EXECUTED from
above 4 MB on a core that decrypts by address.

### SLICE D5: THE FIX, AND WHAT IT DOES NOT TOUCH

`cores/cps2w/hdl/jtcps2_decrypt.v` (fork commit 17) complements the range word
on its way IN, profile-gated:

```verilog
wire [15:0] rng_eff = wide_en ? { addr_rng[15:10], ~addr_rng[9:0] } : addr_rng;
```

* **`jtcps2_dec_ctrl.v` is NOT overridden.** The fix sits one level upstream of
  the comparison, so the comparison nobody has validated for the rest of the
  CPS-2 library is left exactly as it was.
* **`dec_en` is unaffected**: `jtcps2_keyload` computes it from the
  UNcomplemented word (`addr_rng != ~16'h0`) and still sees that word.
* With `wide_en` clear `rng_eff` IS `addr_rng`, so stock `vsavj` on our own RBF
  and every other CPS-2 game are untouched BY CONSTRUCTION (CLAUDE.md rule 1
  v2).
* It is gated rather than fixed outright because fixing it for the whole CPS-2
  library is a claim this project cannot validate. **It is a defect in the
  reference core and worth reporting upstream.**

`tests/test_mister_wide_gate.sh` section 9 re-reads all four lines, asserts
`jtcps2_dec_ctrl` is NOT overridden, re-reads the REFERENCE comparison D5
corrects for (so an upstream change surfaces instead of double-applying), and
carries a must-fire control: strip `wide_en` from the range fix and the frozen
delta must move.

### What D5 corrects in the other documents, and the two probe defects it cost

`mister_map.md` §8's "NOT DECRYPTED, AND THAT IS CORRECT … the two agree
without either being changed" was true of the HARDWARE, of MAME and of FBNeo,
and FALSE of jtcps2; the same sentence sits in slice D4's fork-commit message
and the `jtcps2_main.v` override header. Two probe defects were paid for on
the way, both caught by the data: a window split on `rom_addr[21]` (which is
`A[21]`, not bit 21 of a `[22:1]` bus) and a verdict tool that judged the RAW
word alone over ten fetches the CPU received as garbage —
`tools/prgprobe_verdict.py` now refuses records outside its labelled window
and requires the CPU to have latched the raw word, and
`tests/test_mister_prg_probe.sh` 4g freezes the real case as a fixture. The
record is in the history.

## THE SDRAM READ PROBE: watching the core FETCH (measured 14z-107, fork commit 12)

Platform mechanics, true of any jtcores core, and the natural companion to
the image census below: the census asks what is IN memory, the probe asks
what the core READ out of it.

- **The model already sees every read.** `SDRAM::update()` serves a burst
  beat with `read_bank( banks[k], ba_addr[k] )`, where `ba_addr[k]` is a
  16-bit WORD address inside bank `k`. `JTFRAME_SIM_RDPROBE` puts four
  optional counters on that one line: each takes a bank and a half-open BYTE
  window, and reports per frame and once at the end — reads, distinct blocks,
  the first frame and address, and the address range. Absent the macro every
  line compiles out.
- **The units are BURST BEATS, one 16-bit word each — NOT ACTIVATE
  commands**, which is what `jtframe_sdram_stats_sim` counts and what
  `tests/audit_sdram_bank_load.sh` reports. Do not compare the two without
  dividing by the burst length (4 words on ba0/2/3, 2 on ba1).
- **The distinct-block list is a TILE-CODE list on CPS-2 graphics.** The
  default granularity is 128 bytes, and a CPS-2 tile code IS its SDRAM
  address (the download scramble undoes the `.rom`'s interleave), so
  `rdprobe_<k>.txt` lists the tile codes the core fetched. That is what lets
  a fetch be checked against the roster's frozen extents rather than merely
  counted.
- **[MSC-48]** **Four slots, not two, and the reason is the instrument's own honesty.**
  Two of them arm the windows under test and two arm windows that MUST see
  traffic (the vanilla object banks). Without the second pair a zero on the
  first pair would be ambiguous between "the core did not fetch" and "the
  probe does not count" — and this lane has produced four false verdicts
  from instruments already.

### The cheapest proof that the profile bit is live: LOOK AT THE SCREEN

14z-107 (10). The two legs of `tests/test_mister_gfxc_fetch.sh` run the same
core on `.rom` images that differ in ONE BYTE — header byte 41, `0xFE` against
the generator's `0xFF` fill. At the QSound/Capcom legal screen the difference
is not subtle:

| leg | byte 41 | what the screen shows |
|---|---|---|
| positive | `0xFE` (WIDE on) | the legal screen, correct |
| control | `0xFF` (WIDE off) | a flat yellow field with only the CAPCOM logo left |

The mechanism is the D2 download redirect, running or not: with `wide_en` clear
`jtcps1_prom_we` computes group C's destination with the STOCK expression, so
the 16 MB of tenant art lands on `gfx_bank = {1'b1, gfx_addr[23]}` at
`{1'b0, gfx_addr[22:1]}` — i.e. it ALIASES over the low 8 MB of SDRAM banks 2
and 3, which is vanilla's obj banks 0 and 1 *and the whole scroll window*
(`SCR_OFFSET = 0`). Everything drawn from those tiles is then garbage.

**[MSC-49]** Worth keeping for the shape of it: a two-legged experiment whose legs differ by
one byte is worth building even when the verdict is a counter, because the
FIRST thing it produced was a picture that could not be misread.

## Bounding the frame writer: `JTFRAME_SIM_VIDEO_FIRST/_LAST/_STRIDE` (fork commit 14)

The harness forks an ImageMagick child per CHANGED frame, which is right for
a short run and wrong for a long one: a 4,000-frame simulation writes ~3,000
jpgs nobody asked for and the one frame the run was launched to look at is
somewhere in the middle. Three optional macros pick the frames the writer may
write; the defaults are 0 / INT_MAX / 1, i.e. exactly upstream's behaviour.
`STRIDE` gives a cheap filmstrip across a whole run —
`tools/run_sim_jtcps2.sh --frame-output fork --frame-window 0 999999 30`.
Nothing else changes: the frame buffers are still swapped and compared every
frame, so the simulation's state does not depend on which frames are written.

## THE SDRAM IMAGE CENSUS: reading the download back out (measured 14z-107)

Platform mechanics, true of any jtcores core. Slice D2 places a romset in
SDRAM and changes no fetch at all, so the only thing that can be checked is
the IMAGE — and the image was already reachable; the lane was throwing it
away.

- **[MSC-50]** **`test.cpp` dumps all four banks, once, the instant a FULL download
  ends.** `test.cpp:915` `if( dwn.FullDownload() ) sdram.dump();`, and
  `SDRAM::dump()` writes `sdram_bank0-3.bin` (4 x 16 MB under
  `_JTFRAME_SDRAM_BANKS`) into `cores/<core>/ver/game`. Because it fires at
  the end of the transfer and the core is held in reset until then, the image
  is PURE download: nothing the 68k does has happened yet.
  `tools/run_sim_jtcps2.sh --keep-banks` collects them; without it the tool
  still deletes them, because 64 MB of ROM-derived litter per run was the
  reason they were being deleted in the first place.
- **So a census run costs the download and NOTHING else.**
  `--post-frames 2` simulates two frames after the transfer, which is why the
  gate is ~10 min per leg rather than ~50. `--post-frames` exists because
  `--frames` is ABSOLUTE and assumes the 462-frame stock transfer; the WIDE
  image is 66 MB and takes about 660.
- **HOW A `.rom` BYTE REACHES A DUMP BYTE.** Three steps, each read from the
  source: `jtcps1_prom_we.v:137` `prog_mask <= !ioctl_addr[0] ? 2'b10 :
  2'b01` with ACTIVE-LOW masks, so an EVEN region byte goes to the LOW half
  of the 16-bit word; `write_bank16` stores through an `int16_t*` on a
  little-endian host, so word W's low byte is `banks[k][2W]`; and `dump()`
  writes `out[j^1] = banks[k][j]`. Composing them, a region byte at region
  offset `r` placed at 16-bit WORD offset `OFF` lands at dump index
  `2*OFF + (r ^ 1)` — i.e. **each region appears at its byte offset with the
  16-bit words byte-swapped**. That is the same composition that makes
  `sdram_bank0.bin == byteswap(rom body)` on a stock image, which this file
  already recorded as a cross-check; now it is the census's arithmetic.
- **The GFX scramble is contained in 2 MB and is therefore sixteen slice
  copies, not two million lookups.** `jtcps1_prom_we.v:105` is
  `g = { a[25:21], a[3], a[20:4], a[2:0] }`. Writing `g`'s low 21 bits as
  `(t, m, n) = (g[20], g[19:3], g[2:0])` gives `a = m*16 + t*8 + n`, so for a
  FIXED `n` both the source and destination indices are arithmetic
  progressions. `tools/mister_sdram_census.py:unscramble_block` does the
  whole permutation with 16 strided slice assignments per 2 MB block, which
  is what makes a full 67 MB byte-exact census a few seconds of pure Python
  with no numpy dependency.
- **`tools/mister_mra.sh` is what makes a WIDE leg possible at all.** The
  WIDE set is a CLONE set and `jtframe mra` reads its parent from a
  hard-coded `$HOME/.mame/roms`. Historically the parent was the build's
  own PATCHED `vsav.zip`; **CORRECTED 14z-112: builds no longer pack a
  parent — the four patched members live INSIDE `vsavjw.zip` and BOTH legs
  use the PRISTINE dump, so one SD card can carry this profile and stock
  Vampire Savior** (field-confirmed 2026-08-28). `run_sim_jtcps2.sh --wide
  <build>` delegates to that script, which stages a private `$HOME` per
  run. (This bullet had the 14z-112 correction spliced mid-sentence until
  14z-113 re-flowed it.)

## The per-bank SDRAM traffic profile (measured 14z-107)

Stock `vsavj` on the stock `cps2` core, `05_timeout_idle`, 2,800 frames,
`tests/audit_sdram_bank_load.sh`; full table and verdict in
`build/sdram_bank_load_14z107.log`. Figures are PER VIDEO FRAME.

| phase | ba0 (68k+VRAM+ORAM+WRAM+snd) | ba1 (QSound PCM) | ba2 (obj) | ba3 (obj+scroll) | data bus |
|---|---|---|---|---|---|
| attract | 38,377 acc | 3,511 acc / 78.5% row miss | 0 | 9,485 / 25.3% | 12.8% |
| select+VS | 39,696 acc | 13,911 / **99.0%** | 303 / 74.6% | 12,348 / 36.1% | 16.5% |
| in-match | 40,976 acc | 13,926 / **98.3%** | 1,096 / 42.2% | 18,438 / **28.9%** | 18.5% |

(Re-derived 14z-107 (7) from the same committed log after the anchor moved
2502 -> 2609 — both phases were steady-state, every figure moved by well
under 1% and no conclusion changed; the pre-correction table is in the
history.)

**[MSC-23]** **Read "acc" as READ+WRITE commands and the percentage as the ROW MISS
rate.** They are different quantities because only bank 0 sets
`JTFRAME_BA0_AUTOPRECH`: on banks 1-3 `jtframe_sdram64_bank.v:170`
(`row_match = match && actd && !AUTOPRECH[0]`) skips both the PRECHARGE and
the ACTIVE when a request hits the open row, so an ACTIVE there means a row
MISS. Bank 0's 100% is by construction, not by thrashing.

Facts that matter to the bank-repack arc:
- **QSound has essentially no row locality** — 98.3% miss in-match. It
  round-robins 16 channels at unrelated addresses, so nearly every fetch
  opens a new row. There is no locality in bank 1 for a repack to spoil.
- **Object/scroll traffic does** — 28.9% miss in bank 3. Tile fetches come in
  runs; that is what a repack into bank 1 would put at risk.
- **The bus is at 18.5%** of 96 MHz x 16 bit (30.7 MB/s useful) at the
  busiest measured point, and a repack cannot change it: it moves which bank
  serves a fetch, not how many fetches happen.
- **A single bank's all-miss ceiling is 123,825 transactions/frame**
  (STW = 13 clocks at 96 MHz), and **bank 0 already sustains 40,976 of them
  every frame** in stock configuration — more than any repack worst case.
- `WARNING: (test.cpp) SDRAM reads clashed`: **zero** in 2,800 frames.
- Bank 2 is nearly idle (1.4% share): vsav's object art sits overwhelmingly
  in the `rom0_bank[0]=1` half, i.e. bank 3.
- `jtframe_sdram64.v:536-542` with `BAPRIO=1` grants strictly
  ba0 > ba1 > ba2 > ba3, so objects moved into bank 1 would gain priority
  OVER the scroll left in bank 3 — a scheduling change, not just a
  placement change.

## The per-bank profile of the WIDE image, on `cps2w` (measured 14z-107)

The section above bounds the HEADROOM with stock content on the stock core.
This one is the repack itself, running: `cores/cps2w` with `wide_en` SET, the
real `vsavjw.rom`, `05_timeout_idle`, 3,500 frames,
`tests/audit_sdram_bank_load.sh --core cps2w --wide build/m3b_merged13 --log`.
The transfer is asserted at **659** by the script, and the run's own
match-start anchor measures **2806** — the frozen stock 2609 plus exactly the
197-frame transfer difference — so the four phase boundaries name the phases
they label instead of assuming them.

| phase | ba0 | ba1 (PCM) | ba2 | ba3 | data bus |
|---|---|---|---|---|---|
| ROM download (1-659) | 24,073 | 25,497 | 25,497 | 25,501 | 25.0% |
| attract (661-1461) | 38,261 | 3,466 / 78.6% | 0 | 9,446 / 25.2% | 12.7% |
| select+VS (1463-2805) | **40,717** | 13,870 / 99.0% | 357 / 84.1% | 10,917 / 37.1% | 16.4% |
| in-match (2812-3499) | **41,535** | 13,890 / 98.0% | 296 / 39.9% | 17,335 / 34.2% | 18.2% |

Peak per bank, after the download: ba0 **54,363** at frame 1488 (**43.9%** of
the 123,825 all-miss ceiling), ba1 14,499 (11.7%), ba2 3,848 (3.1%), ba3
18,910 (15.3%). **`WARNING: (test.cpp) SDRAM reads clashed`: zero in 3,500
frames.**

**THE ANSWER TO `mister_map.md` §9 OPEN QUESTION 1 IS YES, WITH ROOM.** Bank 0
carries seven streams including obj bank 5, and through the select screen — the
phase where the wheel art is actually being fetched out of it — it runs at
40,717 accesses/frame, **32.9% of its ceiling**, against the stock core's
39,696 in the same phase. The redirect therefore costs bank 0 about **1,000
accesses per frame, ~2.5%**. That is the right order for what the read probe
sees on the same screen: 6,720 burst BEATS per frame in the obj-bank-5 window,
which at four words per BA0 access is ~1,680 accesses. Nothing saturates and
nothing clashes.

**AND THE HALF IT DOES NOT ANSWER, which is the half this instrument was built
for.** `05_timeout_idle` picks Demitri. No tenant is ever in the match, obj
bank 4 is never fetched, and **ba1's 13,890 accesses/frame are the PCM stream
alone** — within 0.3% of the stock core's 13,926. The row-thrash risk the
repack actually creates — object fetches interleaving with QSound inside bank
1 — is still **UNMEASURED**, and it stays that way until a tenant can be
selected on the core. See "The simulated joystick's direction nibble is MSB-FIRST" below.

## The simulated joystick's direction nibble is MSB-FIRST — the translator had it reversed end for end (measured 14z-108)

**All four. The nibble is reversed end for end — Up arrives as Right, Down as
Left, Left as Down, Right as Up.** Measured on the game's own P1 input mirror
`RAM:$FF8058.w` on BOTH implementations, four single-direction presses on
STOCK `vsavj` (`tests/replays/107_four_directions.rpl`, attract only — no
coin, no start, no roster content), MAME against `cps2w` under Verilator, both
dump sets integrity-checked (151 and 176 frames, 20 nonzero on each leg =
exactly the 4 presses x 5 frames the replay scripts):

| the replay asked for | MAME's `$FF8058.w` | the CORE's `$FF8058.w` | what the core delivered |
|---|---|---|---|
| Up    | `0x0008` | **`0x0001`** | Right |
| Down  | `0x0004` | **`0x0002`** | Left |
| Left  | `0x0002` | **`0x0004`** | Down |
| Right | `0x0001` | **`0x0008`** | Up |

(The 14z-107 (12) reading — two data points, Left and Down, read as a
two-bit SWAP — is superseded; a two-bit fix would have left half the defect
in the tree and the gate would have frozen it. History.)

### VERIFIED AFTER THE FIX, ON THE SAME RIG

Same replay, same core, same stock romset, translator fixed — and the point of
re-running it is that the fix is confirmed against THE GAME, not against the
source that was misread in the first place:

| the replay asked for | MAME's `$FF8058.w` | the CORE, pre-fix | the CORE, post-fix |
|---|---|---|---|
| Up    | `0x0008` | `0x0001` (Right) | **`0x0008`** |
| Down  | `0x0004` | `0x0002` (Left)  | **`0x0004`** |
| Left  | `0x0002` | `0x0004` (Down)  | **`0x0002`** |
| Right | `0x0001` | `0x0008` (Up)    | **`0x0001`** |

Both sim legs: 176 dumps, frames 640-815, integrity asserted, **20 frames with
a nonzero mirror in each** — the same count before and after, and the same
count MAME produces. That is what rules out the fix having lost or doubled a
press rather than re-ordered the bits: only WHICH bit arrives changed.
`sim_inputs.hex` sha1 `7f5c2d9c…` -> `8e0de125…`.

### THE MECHANISM, DERIVED FROM THE BIT ORDER AND THEN CONFIRMED

`modules/jtframe/hdl/ver/test.cpp:380` copies the file's direction nibble
STRAIGHT onto the port — file bit4 -> `joystick1[0]`, bit5 -> `[1]`, bit6 ->
`[2]`, bit7 -> `[3]` — and jtframe's joystick port is **MSB-FIRST**:
`joy[3]=Up [2]=Down [1]=Left [0]=Right`
(`modules/jtframe/hdl/keyboard/jtframe_keyboard.v:107-110`, which is the
authoritative bit order; `_JTFRAME_JOY_RLDU` at `test.cpp:384` being a full
nibble reversal is only consistent with that reading). So the file's map is

    file bit4 = RIGHT   bit5 = LEFT   bit6 = DOWN   bit7 = UP

and `tools/rpl2siminputs.py` had it exactly end for end, having read the macro
NAME "UDLR" as "bit4=Up ... bit7=Right". The game's own mirror turns out to
use the SAME MSB-first order in its low nibble (`$FF8058` bit3=Up, bit2=Down,
bit1=Left, bit0=Right, measured above on MAME), which is why the observed
values are a clean mirror of the requested ones.

**THE FAULT IS OURS, NOT jtframe's** — unlike the three input-path defects
before it, which were upstream and were fixed in the fork. jtframe documents
no `sim_inputs.hex` direction spec; the file nibble is simply `joy[3:0]`, and
the translator invented an order from a macro name. **Fix: one dict in
`tools/rpl2siminputs.py`. No fork commit, no RTL.**

### The rule it left

The measurement built to prove obj bank 4 (the tenants' fighter art) is
fetched returned exactly ZERO reads with the RTL innocent in every respect —
the cursor moved on every press, just not where asked, landed on Victor,
and the core drew the character it was handed. The RENDERED frame cracked
it; every step of the input chain had read correct on paper, and the one
thing nobody checked was which END of the nibble the port counts from.
**An input path is measured against the game's own mirror, never reasoned
about.** (The full account is in the history.)

### GATE CONSEQUENCE — one frozen expectation moved, and one did NOT

`tests/test_rpl2siminputs.sh` freezes two values, and the record said a
bit-map fix would move both. **It moved one.**

* check 1's bit-map vector MOVED: `111 6ee 000 000 080` -> **`181 67e 000 000
  010`**, re-derived by hand from the measured map and stated in the gate
  header with the mechanism.
* check 3's `05_timeout_idle` sha1 **DID NOT MOVE and could not**:
  `eb3e1d04e58b3a2b7bf713d40c4d6ac4796e550c` before and after. That replay
  scripts a coin, a start and one button-1 tap — **no direction token** — so
  no direction bit is ever set in its translation. The gate now asserts that
  MECHANISM directly (check 6, with a positive control) rather than resting on
  the hash.
* **Therefore `test_mister_sim_anchor`'s frozen anchor cannot have moved
  either** (MAME 2146 / sim 2609 / skew 463): its replay is `05_timeout_idle`,
  whose `sim_inputs.hex` is byte-identical across the fix. It was not re-run
  for this change, and that is the reason.

The gate also gained a per-direction lock (check 5 — check 1 presses three
directions at once and would pass under any PERMUTATION of the four) and a
MUST-FIRE CONTROL that rebuilds the pre-14z-108 reversed map and requires
check 5 to reject it. **A first draft of check 6 passed for the wrong
reason** — it used gawk's `and()`/`strtonum()` on a BWK awk, so awk exited 2
and the `else` arm read as success. Caught by writing its positive control
before trusting it, which is THE INSTRUMENT PROTOCOL working as intended.

### The pictures

This was the fourth input-path defect in the lane and the seventh instrument
defect overall; three of the four were invisible until a replay first needed
the feature — **the sim input path is only ever as tested as the last replay
that used it** (`docs/platform/gotchas.md`).

**THE PICTURES.** `docs/project/images/mister_select_cps2w_f2400.jpg` (the
core, `cps2w` + the WIDE romset) and `mister_select_mame_f1741.png` (MAME, the
same romset and replay) are the select screen on both implementations, both
showing the extended 21-cell wheel and the authored "M6" mark. They are the
first pictures of this project's own content produced by an FPGA
implementation. **They are a naked-eye pair, not a verdict** — nothing
compares them programmatically — and the cursor sits on a different cell in
each, which is this defect drawn rather than counted.

## The twin proof: the MRA twin and the enumerated core-dir delta (measured 14z-106, gated since)

`jtframe mra cps2` emits 316 MRAs; `jtframe mra cps2w` emits 7 — the
Vampire Savior family only (Euro parent + Japan/USA/Asia/Brazil/Hispanic
+ the Phoenix bootleg). The `vsavj` MRA from the two cores is
BYTE-IDENTICAL except `<rbf>jtcps2</rbf>` → `<rbf>jtcps2w</rbf>` (diff
shown in STATE 14z-106 (3)). Gate: `tests/test_jtcores_twin.sh`.
**Since 14z-107 (5) `cps2w` emits EIGHT** — the WIDE set joined the family —
and the twin claim above is now a live gate rather than a one-off
measurement: `tests/test_mister_mra_map.sh` re-generates both cores' MRAs
and diffs them.
**Since 14z-107 (6) the twin is a TWO-PART claim and both parts are gated.**
The MRA twin above is unchanged and still exact. What changed is the CORE
DIR: cps2w carries RTL, so "identical modulo CORENAME" became "identical
modulo an ENUMERATED delta" — **six** files in `cores/cps2w/hdl` since slice
D2 (it was four at D1; **fourteen since D5** — thirteen `.v` plus
`pal_lut.hex`, whole-tree delta 25 paths, updated 14z-113), a frozen line-by-line diff for the FOUR that override
shared files (`tests/test_mister_wide_gate.sh` check 1), `git diff` proving
`cores/cps1`, `cores/cps2`, `cores/cps15` never moved
(`tests/test_jtcores_twin.sh` 2e), and — added at D2, because D2 puts a file
OUTSIDE `cores/` for the first time — the fork's WHOLE-TREE `git diff
--name-status` held to a declared 18 paths (2f). The gate that used to say
"game.yaml identical (no RTL override)" was moved DELIBERATELY, the way check
2c was moved at D0.

## HOW THE MRA AND THE `.rom` ARE MADE (measured 14z-107)

Everything here was learned building the WIDE download image
(`docs/project/mister_map.md` slice D0). It is platform behaviour, true of
any core.

- **[MSC-63]** **A set must exist in `$JTROOT/doc/mame.xml`** — jtframe's own REDUCED
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
- **[MSC-64]** **`mra2rom` locates every zip member by CRC32 and by NOTHING ELSE**
  (`mra2rom.go:163-172`: it walks the zips comparing `file.CRC32`; the
  `name` attribute is used only in the warning text). **This is a real
  divergence from FBNeo and MAME**, which resolve by name and merely warn on
  a hash mismatch — which is why this project's WIDE members carry SENTINEL
  CRCs in both of those drivers and why content there can change freely. On
  MiSTer a sentinel means `Warning: cannot find file … in zip` and no `.rom`.
  Consequence: **an MRA is pinned to the exact bytes of one romset build.**
- **[MSC-65]** **The zip search path is a HARD-CODED `$HOME/.mame/roms/<name>.zip`**
  (`mrazip.go:23`), so the tool's output is a function of the invoking
  user's home directory and there is no flag for it. `tools/mister_mra.sh`
  stages a PRIVATE `$HOME` per run instead of writing into the user's — and
  it had to, because the stock leg and the WIDE leg then needed DIFFERENT
  `vsav.zip` files (the merged build patched `vm3.13m/15m/17m/19m` into its
  own parent). **CORRECTED 14z-112: builds no longer pack a parent — the four patched members live INSIDE `vsavjw.zip` and BOTH legs use the PRISTINE dump, so one SD card can carry this profile and stock Vampire Savior.** The private `$HOME` staging stays: `jtframe`
  still hard-codes its lookup path.
- **[MSC-68]** **`jtframe mra -n` skips ROM generation entirely** — no zips are opened,
  `md5="None"`, and the MRA XML becomes a pure function of `doc/mame.xml`
  plus the core's TOML. That is the ROM-free mode a structural gate wants.
- **[MSC-66]** **`parts=` puts EVERY part of a region inside ONE `<interleave>` when
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
- **[MSC-67]** **Region starts in the MRA comments are the generator's `pos`, which
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

Everything this list once carried is closed and its closing recorded in the
section that measured it — the video-sensitive anchor (the frame writer), the
macOS lane, the per-frame cost, the memory-map route (RULED option 2, the
bank repack, GO on measurement), the SDRAM model and the repack's second
half; the struck items are in `mister_history.md` as written. What is CURRENT:

- **Input coverage:** P1 AND P2, directions + buttons 1-3 each
  (`rpl2siminputs.py`; P2 since 14z-109, fork `4dfc3734`, backward
  compatibility proven by the unchanged frozen sha1); **buttons 4/5/6
  REFUSED** (button 4's bit doubles as `dip_test`), so `02_demitri_vs_cpu`
  and `04_select_fuzz` still refuse. The FIDELITY half (buttons 5/6 stuck
  ON, P2's too) was a bug, fixed 14z-107 (8); SCRIPTABILITY of 4/5/6 is the
  deferred half.
- The holes ledger — what has never been tried — is
  `docs/project/mister_core.md` §12.

## SYNTHESISING THE CORE — the VERIFIED recipe (14z-108)

**Quartus is Linux/Windows only and the toolchain image is x86-64, so this
cannot run on the dev Mac.** It needs no hardware and no Quartus install:
Jotego ships the whole toolchain as a Docker image
(`.github/workflows/q20.yaml:51`).

**This sequence was RE-RUN FROM A CLEAN SLATE and the resulting tree checked
against the tree the numbers came from** — same HEAD `7b9a0d2d`, byte-identical
`git submodule status --recursive`, `diff -r cores/cps2w` clean but for build
artifacts. It is a tested recipe, not a tidied-up transcript of what actually
happened (which involved a hang, a kill and two repairs).

```sh
# 1. toolchain — elevated PowerShell on Windows 10 Home, then REBOOT
wsl --install -d Ubuntu

# then inside the distro, as root
apt-get update && apt-get install -y docker.io
systemctl start docker
usermod -aG docker <your-user>
docker pull jotego/jtcore20x

# 2. source — as your normal user, into the distro's ext4, NOT /mnt/c
git config --global url.https://github.com/.insteadOf git@github.com:
git clone https://github.com/DefinitelyFrenchName/jtcores ~/jtcores
cd ~/jtcores
git checkout 7b9a0d2d
git config submodule."modules/jtframe/target/pocket".update none
GIT_TERMINAL_PROMPT=0 git submodule update --init --recursive

# 3. build — the CONTROL FIRST, deliberately
docker run --rm --network host -v $HOME/jtcores:/jtcores jotego/jtcore20x xjtcore.sh cps2  mister
docker run --rm --network host -v $HOME/jtcores:/jtcores jotego/jtcore20x xjtcore.sh cps2w mister
```

**[MSC-57]** **FOUR LOAD-BEARING DETAILS, none cosmetic:**
1. **`git clone` is NOT `--recursive`, and `git checkout 7b9a0d2d` comes
   BEFORE the submodule pass.** `--recursive` resolves submodules against the
   DEFAULT BRANCH, and jtcores master registers `modules/jt539`, which does
   not exist — git then hangs FOREVER on a credential prompt with no error.
   The fix is ORDERING, not a flag. (`docs/platform/gotchas.md`.)
2. **`GIT_TERMINAL_PROMPT=0`** turns any other dead repository from a silent
   stall into a fast failure.
3. **`--network host` or `quartus_map` SEGFAULTS** in FlexLM's host-id path —
   and reports it as a MEMORY error at 487 MB peak against 15 GB free
   (`docs/platform/gotchas.md`).
4. **Build `cps2` FIRST.** It is the reference leg: without it a timing
   failure on `cps2w` cannot be attributed to our slices. Ordering it first
   also means a flow failure cannot be misread as a `cps2w` result.

**On the two `git config` lines:** `url.https://github.com/.insteadOf` needs
no quoting (git splits the key on the first and last dot, so the URL survives
as the subsection); the `submodule."…".update` line DOES need its quotes,
because of the slashes. The pocket skip is only needed while `jotego/pocket`
is inaccessible.

**`BETAKEY` is NOT required** — the flow warns "remote compilation with no
beta key. Assigning random one" and proceeds.

**REPRODUCING THE SHIPPING BITSTREAM, and the two ways that goes wrong.**
`xjtcore.sh` does NOT build a deterministic artifact: it calls `jtseed 4`,
which draws `--seed $RANDOM` and stops at the first success. To rebuild a
NAMED result, bypass it:

```sh
jtcore cps2w -mister --nodbg --seed 18269      # the 14z-108 shipping baseline
```

* **Seed 18269** produced `jtcps2w.rbf` sha256 `46fc74af…`, slack +0.066 ns,
  jtframe gate PASS. It was jtseed's own random draw, and it IS the +0.066
  row of the n=12 sweep — **a passing draw from a distribution in which a
  third fail, not a privileged build.**
* **THE HASH WILL NOT MATCH ON A DIFFERENT DAY.**
  `modules/jtframe/target/mister/sys/build_id.tcl` compiles a `%y%m%d`
  datestamp into the design; this bitstream carries `260825`. Same seed,
  same pin: the PLACEMENT and TIMING reproduce exactly, the bitstream and
  its hash do not. **The hash identifies the ARTIFACT; the seed identifies
  the RESULT.** Never read a hash mismatch as a failed reproduction — check
  the seed and the reported slack.
* **RELEASE POLICY, RULED 2026-08-25 (decision B): A SHIPPED BITSTREAM IS
  BUILT FROM A NAMED SEED, NEVER FROM AN `xjtcore.sh` DRAW.** Record the
  seed, the reported slack and the sha256 with the artifact, and verify the
  hash before it goes anywhere. `xjtcore.sh` is for development; releases
  use `jtcore <core> -mister --nodbg --seed <S>`. This costs nothing and is
  the whole of the project's answer to a design that wins the placement
  lottery about two times in three.
* **A FAILING SEED EMITS AN `.rbf` INDISTINGUISHABLE FROM A GOOD ONE** —
  same size class, same filename, same published path — and a sweep
  overwrites `release/mister/<core>.rbf` with whatever ran last. The only
  defences are the seed record and the hash. **Verify before flashing.**

## The tenant-content measurements: the tenant anchor, both group-C fetches, bank 1 under load, the QSound extension, the OBJ-list oracle, the synthesis fit (measured 14z-108/109, entered 14z-114)

Quotations from the gates' own outputs as recorded at 14z-108/109; each
names its gate, and the gate re-produces it. (They were entered here at
14z-114 because `tools/checkskills.py` refused numbers that lived only in
the synthesis and STATE — history.)

- **The tenant anchor** (`tests/test_mister_tenant_oracle.sh`, 14z-108;
  `36_pick_tenant_cell`, `cps2w` + the WIDE romset vs MAME on the same set):
  round-1 match start MAME **2886** / sim **3546** / skew **660** ± 30 — the
  659-frame WIDE transfer plus one, the same +1 the stock replay shows on its
  462-frame transfer. `p1_hitbox_base` **`0x003FA9D0`** on BOTH legs (the
  relocated record above `CPU:$400000`); `p2_hitbox_base` excluded by name
  (MAME `0x000ABD74` vs core `0x0009769E`, the sound-fed draw).
- **[MSV-25]** **Both group-C banks fetched** (`tests/test_mister_gfxc_fetch.sh`,
  14z-108, same replay, 4,400 frames): obj bank **4** (fighter art, SDRAM
  ba1 `0x800000+`) **9,388,928** reads over **1,735** distinct codes
  `0xAD8F-0xEE42`, first at frame 1781, traffic in **843 frames after match
  start**; obj bank **5** (wheel art, ba0 `0x7E0000+`) 19,246,336 reads over
  206 codes `0x74D6-0xFE41`, first at 1556, last at 3498 (the select/VS
  boundary). Control leg (header byte 41 `0xFE`->`0xFF`): **0** in both
  windows while still issuing 105,418,104 reads in bank 3.
- **[MSV-10]** **Bank 1 under load** (same run, `--stats`, 3,738 post-transfer frames):
  ba1 **11,905** accesses/frame, peak **15,496** = **12.5%** of the 123,825
  all-miss ceiling, with the fighter art sharing the bank with PCM; ba0
  peak 54,363 (43.9%), unchanged from stock; **zero** `SDRAM reads clashed`.
  ONE replay, ONE tenant, one opponent — stated as the caveat it is.
- **[MSV-26]** **The QSound extension fetched** (`tests/test_mister_qsound_ext.sh`,
  14z-108, `108_tenant_voice.rpl`): **210,180** reads over **76** distinct
  blocks in the 1 MB PCM-high window, first at frame **3783**, addresses
  `0x830AA0-0x83FFFE` = DSP bank **`0x83`**; control leg **0** while still
  issuing **54,113,994** QSound LOW reads; `pcm_addr[22:20] == 0`
  throughout (the `SLOT5_AW=20` mask lossless in practice).
- **[MSV-29]** **The OBJ-list oracle** (`tests/test_mister_obj_oracle.sh`, 14z-109): at
  the tenant anchor the PROMOTED subset (y bit 12) is **31** entries on both
  legs, ordered and field-for-field identical, 19-bit tile addresses the
  same set **`0x4b0c4-0x4ecda`**; raw lists 40 vs 129 (the opponent
  lottery, reported not asserted). Select screen: 81 core frames vs 111
  MAME frames, both non-constant (21 / 31 distinct lists); promoted subset
  exact on **all 81** frames with 67-72 promoted entries; whole list 55/81,
  every shortfall in the unpromoted part; the authored "M6" mark (codes
  `fe40`/`fe41`, palette row `0x19`) identical. Walker
  `tools/oram_obj_records.py` calibrated **1153/1153** lines against
  `tests/lua/obj_records_dump.lua` before any core data was read.
- **Synthesis fit** (14z-108, Quartus 20.1.1 Lite, Cyclone V 5CSEBA6U23I7,
  pin `7b9a0d2d`, `cps2` built first): `cps2w` **+206 ALMs** (+1.1%, 44% of
  **41,910**), **+2,048** block-memory bits; RAM blocks, DSPs, PLLs
  unchanged. The timing sweep is in "SYNTHESISING THE CORE" and
  `docs/platform/gotchas.md` (`xjtcore.sh` retries until a seed passes).
- **Field-test scale facts** used by the triage card
  (`docs/project/mister_field.md`): the pre-D5 boot loop is a ~1,580-frame
  cycle = about **26.5 s** at the real **59.6374 Hz**; the RAM-test pattern
  stands ~4.5 s and the legal screen arrives ~15 s after reset (simulated
  frame counts at native timing — the DOWNLOAD itself is not comparable,
  it runs at HPS speed on hardware).
