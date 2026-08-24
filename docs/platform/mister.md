# MiSTer — the jtcps2 core, as it concerns this port

Platform fact file (docs/README.md taxonomy: true whether or not the roster
hack exists). Opened 14z-106 (2026-08-22) when the MiSTer arc was framed.
Every figure below names its source; "read 2026-08-22" means the jtcores
tree at tag `v1.7.3` (commit `63688ce5`) unless stated.

> **THIS FILE IS A LOG, AND IT IS MEANT TO BE.** It records what was
> measured, when, and what each measurement retracted. The SYNTHESIS — the
> same material in CAUSAL order, stating what is true and why it follows —
> is `docs/project/mister_core.md`. Read that one first if you want the
> shape of the thing; read this one for the provenance of a number.
> Where the two disagree, **this file wins**: it is the measurement.

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
| the fork's commits | `b9d0565` `cores/cps2w` scaffold (14z-106) · `553dd56` sim work-RAM dumps · `6c32be8` sim SDRAM top address bit · `4f25cc7` sim model clock · `74ed17d` sim SDRAM stats · `38acc638` the WIDE machine entry + the MANDATORY QSound trim in the MRA (14z-107 (5), slice D0) · `4840df8a` **THE FIRST RTL COMMIT — the QSound sample-bank width, RUNTIME-GATED** (14z-107 (6), slice D1) · `692ba4d6` + `7cf1eedb` the frame writer made optional and its child made `_exit` (14z-107 (7)) · `519aff8b` the joystick top bits (14z-107 (8)) · `0df6f000` **THE SDRAM PLACEMENT** (14z-107 (9), slice D2). Commits 1-6 touched no RTL. The mirrored series is `emu/jtcores-patches/0001`-`0011` |
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
lists differ in exactly **eleven** entries — 4 out, and 6 overrides plus
1 new jtframe module in). `cores/cps1`, `cores/cps2` and `cores/cps15` are
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
two. cps2w's `game.yaml` is consequently 68 lines different from cps2's and
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
cps2w's `macros.def` differs by `CORENAME=JTCPS2W` only — and it stays that
way ON PURPOSE: **the WIDE profile is NOT a macro.** See "The runtime profile
gate" below.

## The runtime profile gate: MRA header byte 41 (slice D1, 14z-107 (6))

Maintainer ruling, 2026-08-23: the profile is selected at RUNTIME from a
spare MRA header bit, not by an `ifdef`. The consequence is the point —
**stock `vsavj` on `jtcps2w.rbf` runs with the widened behaviour CLEAR**, so
CLAUDE.md rule 1 v2's "profile-gated so stock `vsavj` is untouched BY
CONSTRUCTION" is a fact on FPGA rather than an inertness argument.

- **Which byte, and why it is free.** `jtcps1_prom_we.v` consumes header
  bytes 0-7 (the four region start words), 8-39 (`is_cps`, the CPS config
  registers, `REGSIZE=24` + `START_HEADER=16`) and 40 (`JOY_BYTE = 6'h28`);
  44-63 are the CPS-2 key (`CPS2_KEYS = 26'd44`). Bytes **41-43 fall through
  every branch of its decoder and are ignored**, which is what the file's own
  comment at `:52-54` ("6 are actually used and 10 are reserved") is
  describing. `JTFRAME_HEADER=44`, so byte 41 exists in every CPS-2 `.rom`.
- **ACTIVE LOW, and that is forced rather than chosen.**
  `cores/cps2/cfg/mame2mra.toml` declares `[header] fill=0xff`, so an
  unwritten header byte is `0xFF`; the stock `vsavj` MRA emitted by cps2w has
  to stay byte-identical to cps2's. Only a polarity in which the FILL means
  "profile off" can do that. jtframe's own `JOY_BYTE` has exactly this shape
  (0xFF = joystick mode 3; the games that want mode 0 write `fc`).
  So: **byte 41 bit 0 CLEAR = CPS-2 WIDE**, and the WIDE MRA writes `fe`.
- **How the row is scoped.** `RawData` embeds `Selectable`
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
- **THE LANE'S ANCHOR WAS VIDEO-SENSITIVE — ROOT-CAUSED AND FIXED
  14z-107 (7).** `tests/test_mister_sim_anchor.sh` went RED on cps2w at
  2609/463 for a reason that had nothing to do with the profile:
  `cores/cps2w/hdl` was missing `pal_lut.hex`, the core rendered a black
  screen, and `test.cpp` forks a child per CHANGED frame. D1's 2x2 factorial
  put the whole effect on the LUT axis and none on the RTL axis, and left
  the path from a black screen to one byte at `RAM:$FF8060` OPEN. **The path
  is now closed and it is not "the picture moved the 68k's timing": the
  forked child's `exit(0)` fclose()d the inherited `FILE*` behind the
  parent's `sim_inputs.hex` stream, which rewound the SHARED file offset, so
  the parent re-read input lines it had already consumed. The simulated
  CONTROLLER was being replayed, once per fork — and `$FF8060` is the START
  bitmask, an input-derived byte.** Fork commit 9 makes the child `_exit(0)`;
  fork commit 8 makes the writer suppressible and `--frame-output off` the
  lane's default. Full chain, controls and ground truth: "THE HARNESS'S
  FRAME WRITER CORRUPTED THE SIMULATED INPUT SCRIPT" below. The other
  consequence D1 drew still stands on its own merits: the anchor gate is a
  cross-IMPLEMENTATION oracle and `tests/test_mister_wide_inert.sh` (cps2 vs
  cps2w, bit-identical work RAM frame by frame) is the inertness
  instrument.
- **Clock domains, so it is not asked later.** The decoder runs on the game
  port's `clk`, which jtframe documents as "always matched to the SDRAM
  clock" (`jtframe_common_ports.inc:5`) and which on a `JTFRAME_CLK96` core
  like CPS-2 is the same 96 MHz net the QSound block's `clk96` is. Even if it
  were not, `wide_en` is a STATIC configuration bit: it is written only while
  the ROM streams, with the core (and the QSound DSP, `qsnd_rst`) held in
  reset, and is constant for the whole of play. There is nothing to
  synchronise.

## THE HARNESS'S FRAME WRITER CORRUPTED THE SIMULATED INPUT SCRIPT

**This is the root cause of "the anchor is video-sensitive" (opened D1,
closed 14z-107 (7)), and it is not what it looked like.** The picture never
reached the CPU. The HOST did: jtframe's Verilator harness forks a child per
changed frame, the child ended with `exit(0)`, and `exit()` rewound the
parent's *input script*.

**The chain, each link measured:**

1. **Frame output is ALWAYS ON upstream — `-video` is not what turns it on.**
   `bin/jtsim:460` runs `mkdir -p frames` unconditionally and the fork in
   `test.cpp`'s `video_dump()` is guarded by no macro; `-video` only defines
   `DUMP_VIDEO`, which `test.cpp` never reads. A run that never asked for
   pictures still forks once per CHANGED frame.
2. **`exit(0)` in the child runs the C stdio cleanup**, which flushes and
   closes every open C stream. **libc++'s `std::basic_filebuf` is a `FILE*`
   underneath**, so that includes the copy the child inherited of the
   parent's `sim_inputs.hex` stream.
3. **`fclose()` on a seekable READ stream repositions the underlying file
   description** to the stream's logical position (POSIX) — and that
   description is SHARED with the parent after `fork()`.
4. **So the parent's next buffer refill re-reads lines it had already
   consumed.** The simulated controller script is REPLAYED, once per fork,
   at every stdio buffer boundary.
5. **And the number of forks follows the PICTURE.** A core rendering the
   game forks hundreds of times; a core rendering black (the missing
   `pal_lut.hex`) forks about once. That is the whole of the "video
   sensitivity".

**THE CONTROL — a 2x2 on `cps2w` + stock `vsavj` + `05_timeout_idle`, work
RAM dumped every frame 2000-2680 (681 dumps per leg, every set asserted
COMPLETE), everything else held: same `.rom` (sha1 `f9dc2987…`), same
`sim_inputs.hex` (sha1 `1d6f8418…`), same 462-frame download, byte-identical
RTL file list.** Full log: `build/fork_rewind_14z107.log`.

| leg | fork()s (jpgs written) | match-start anchor |
|---|---|---|
| LUT present, frame output **OFF** | 0 | **2609** |
| LUT absent, frame output **OFF** | 0 | **2609** |
| LUT absent, frame output **FORK** | **1** | **2609** |
| LUT present, frame output **FORK** | **1,348** | **2502** |

- **OFF, LUT present vs absent: BIT-IDENTICAL, 681/681.** With the host doing
  nothing with the pixels, a black-screen core and a working core are the
  same machine — which is what the RTL says they must be.
- **Same core, frame output OFF vs FORK: 483 of 681 frames DIFFER, first
  divergence frame 2051, ONE byte, `RAM:$FF8060`, 0x40 vs 0x41.** That byte
  is the game's per-player **START bitmask**
  (`docs/game/atlas/character_tables.md:347`) — an INPUT-derived value, which
  is the mechanism signing its own work.
- **Black-screen core, OFF vs FORK: BIT-IDENTICAL, 681/681.** One fork, so
  nothing accumulates.
- **Fork mode run twice: BIT-IDENTICAL.** The corruption is DETERMINISTIC,
  not noise: the same picture forks at the same frames and rewinds by the
  same amounts. That is why D1's factorial reproduced so cleanly and looked
  like a property of the design.
- **AND IT INVERTS THE FROZEN NUMBER.** Every leg that forks once or not at
  all puts the round-1 match start at **2609** (skew **+463** against MAME's
  2146); only the 1,348-fork leg says 2502. So D1's RED anchor was the
  correct measurement and the green 2502/356 was the artifact. The gate is
  re-frozen at 2609/463, band unchanged at +/- 30.

**Ground truth for the mechanism, independent of any core** (and a gate,
`tests/test_sim_wram_contract.sh` 11/11c): a parent reading a 25 KB file
line by line while forking one child per line reads 3,000 lines and ends at
line 3000 with `_exit()` children — and ends at line **278**, with three
backward jumps, with `exit()` children. Check 10 covers the same cleanup's
other effect: N `exit()`ing children flush N copies of the parent's buffered
`stdout`, so a `$display` line appears once per child (measured live: 212
copies in a fork-mode log, one with frame output off).

**THE FIXES, both in the fork, no RTL:**

- **commit 9 — the child now `_exit(0)`s.** No stdio cleanup, no rewind, no
  log duplication. This is the actual repair, and it is one word.
- **commit 8 — `JTFRAME_SIM_NOVIDEO`** compiles the writer out entirely, and
  `tools/run_sim_jtcps2.sh --frame-output off` is the lane's DEFAULT. A
  state oracle should not be doing anything with the pixels in the first
  place, and with the macro it provably is not. Commit 8 also reaps the
  children (`waitpid(WNOHANG)`): upstream leaves one zombie per changed
  frame, and at `RLIMIT_NPROC` (2666 on a stock macOS account) `fork()`
  starts failing and frames stop being written with no diagnostic.

**What was NEVER at risk, and it matters because the alternative would have
been far worse:** the RAM dumps themselves. Every `wram/dump_*.bin` is
written by the PARENT, in `SDRAM::dump_range`, from a local `ofstream`
constructed and destroyed inside one call at the VS rising edge in
`clock()`. No dump descriptor is ever open across the `fork()`, so no dump
can be interleaved, truncated or written by a child. The corruption was of
the run's INPUT, not of its output.

**Which of the earlier numbers stand, then.** The §4 field agreement stands
(nothing was ever read from a corrupted file); the ANCHOR FRAME INDEX did
not, and is re-frozen above. `tests/test_mister_wide_inert.sh` stands by a
stronger argument still — it compares two cores rendering the SAME picture,
so both legs fork at the same frames and the comparison is invariant to the
corruption; only a gate whose other leg is MAME could see it. The per-bank
SDRAM traffic profile stands, and was audited rather than assumed: it is the
one instrument that parses a LOG, `build/sdram_bank_load_14z107.log` carries
zero duplicated stats rows, and its phase boundaries — which are keyed to
the anchor — were moved and the table re-derived from the same log, shifting
every figure by well under 1%. Full statement: STATE 14z-107 (7) section D.

**And the palette LUT itself is innocent.** `jtcps1_pal.v:62` instantiates
it with `we` tied low; `q` feeds `lut_r/g/b` and those feed
`red/green/blue` (`:105-122`), module outputs that `game_test.v` only wires
out and `test.cpp` reads only in `video_dump()`. `LVBL`/`LHBL` — which clock
`sim_inputs.next()` and the frame counter — come from `jtframe_sh` on
`vb`/`hb`. Verilator's `$readmemh` on a missing file is a `%Warning` that
leaves the array at zero (measured on 5.050), so a missing `pal_lut.hex`
changes exactly one thing: the picture. It was a fair 2x2 axis and a
completely misleading one.

## `SimInputs` HELD BUTTONS 5 AND 6 DOWN — FIXED 14z-107 (8), fork commit 10

**The second harness defect of the same family as the frame writer, and the
one that made the two legs of the §4 oracle run DIFFERENT INPUTS.** Found
while auditing in 14z-107 (7), recorded there and deliberately not fixed
(the fix moves the frozen anchor); measured and fixed here.

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

**And the fix's whole footprint at boot is those inputs.** Two otherwise
identical `cores/cps2` runs (stock `vsavj`, frames 560-620, frame output
off), one at each pin, differ in **8 bytes of 65,536** in every frame of
the window: `$FF8058`, `$FF805A`, `$FF805C`, `$FF805E` (0x60 -> 0x00) and
`$FF8060-$FF8063` (0x40 -> 0x00). Nothing else in work RAM moves that
early — which is exactly what a corrected INPUT should look like before the
game has had a chance to act on it. Downstream, at the match, it moves the
anchor: see `tests/test_mister_sim_anchor.sh`.

**AND AT THE MATCH, THE FOUR BUTTONS WERE DOING NOTHING BUT SITTING IN THE
INPUT WORDS.** The §4 window was re-run at BOTH pins — `cores/cps2`, stock
`vsavj`, the same `sim_inputs.hex` (sha1 `931e6caf…`), frames 2400-2800,
frame output off. Both reach the round-1 match start at **2609**, and over
all 401 frames the two runs differ in **29 addresses of 65,536**:

| what | addresses | frames it differs in |
|---|---|---|
| raw input mirror + its `$FF806x` derivative | `$FF8058/5A/5C/5E`, `$FF8060-63` | 401/401 |
| per-player struct input word (`+0x394`) | `$FF8794/96`, `$FF8B94/96` | 401/401 |
| in-match per-player input copies (`+0x122/124/12A/12C`) | `$FF8522/24/2A/2C`, `$FF8922/24/2A/2C` | ~190/401, from the match on |
| one-frame companions of the same words | `$FF8526`, `$FF85AC`, `$FF8926`, `$FF89AC` | 1/401 each |
| OBJ-builder secondary stack / dead-stack window (`atlas/ram.md`, the two documented phase classes) | `$FF06B0/B5/B9`, `$FF7FC4/C8` | 8/5/5, 1/1 |

No HP, position, timer, meter, character identity or anim cursor differs —
which is why the anchor did not move and why the §4 field verdict is
unchanged.

**THE FIX (fork commit `519aff8b`, `emu/jtcores-patches/0010-…`, pin
bumped, LOCAL ONLY):** `& ~0xf` instead of `& 0xf0` — keep every button bit
the port has, whatever `JTFRAME_BUTTONS` is — and `0x3ff` instead of `0xff`
for the four seeds. Unconditional, no macro, 1 file: this is a plain
upstream bug, not a profile change, and it would be a clean upstream report.
`tests/test_sim_wram_contract.sh` check 12 holds the pinned `test.cpp` to it
with a must-fire control.

**WHAT IT IS NOT.** It does not add P2 or button 5/6 SCRIPTING —
`tools/rpl2siminputs.py` still refuses `p2=` and `p1=4/5/6` loudly, and
`02_demitri_vs_cpu` / `04_select_fuzz` still do not translate. The
maintainer ruled that COVERAGE half "later" (STATE "Decisions pending"); the
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

## The QSound bank bit IS `dsp_ab[7]` — validated 14z-107 (6)

The width fix rests on this and `jtcps15_sound.v:416-417` shows the original
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

## jtframe's 8-bit SDRAM slot CAPS AT SDRAMW — measured 14z-107 (6)

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
  **CORRECTED 14z-107 (7), FIXED 14z-107 (8): buttons 5 and 6 did not "not
  exist" — THEY WERE HELD DOWN, and so were P2's.** `test.cpp`'s `&0xf0`
  direction mask and its `0xff` joystick seeds treated a `[9:0]` ACTIVE-LOW
  port as 8-bit, so from the first line of `sim_inputs.hex` the simulated P1
  had buttons 5 and 6 pressed and P2 had them pressed for the whole run.
  Fork commit 10 fixes both (`& ~0xf`, `0x3ff`); the measurement, the MAME
  differential that located the game's input mirror, and the before/after
  table are in "`SimInputs` HELD BUTTONS 5 AND 6 DOWN" above. It re-froze
  the §4 anchor, which is why it was its own slice.
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
   simulated frame. **Since 14z-107 (7) it runs with HOST FRAME OUTPUT OFF
   by default** (`--frame-output off|fork|collect`) and asserts the dump set
   it produced is complete — see "THE HARNESS'S FRAME WRITER CORRUPTED THE
   SIMULATED INPUT SCRIPT". Pass `--frame-output collect` when you actually
   want to LOOK at the picture; that is now safe as well, since fork commit
   9, but it is not what a state measurement should be doing.

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
  **[BOTH ABSOLUTES RETRACTED 14z-107 (7) — they were measured while the
  harness's frame writer was rewinding `sim_inputs.hex`; the clean anchor is
  2609 / skew 463. The five-frame MOVE and its mechanism stand: it was
  measured as a DIFFERENCE between two runs that shared the corruption.]**
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
`sdram_addr = addr + offset`. So **on the REFERENCE core `RAM:$FF0000-$FFFFFF`
= SDRAM bank 0 byte offset `0x600000`, 64 KB**. **QUALIFIED 14z-107 (9): THAT
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
the simulated core does it at GAME frame 71, i.e. absolute frame 533. So
**simulated absolute frame = MAME frame + 460** (the 462 download frames minus
a 2-frame lead) — but that is the BOOT-PHASE offset only. **CORRECTED
14z-107 (2): the round-1 match-start anchor of `05_timeout_idle` sits at MAME
**2146** / sim **2507**, i.e. skew +361, not +460** — the attract/select/VS
path costs ~99 fewer frames on the core. (**RE-MEASURED 14z-107 (3) on the
FIXED SDRAM model: 2502 / +356**; the five frames are the object pipeline's
blank-tile skip reacting to correct GFX, see the fix section above.)
**BOTH OF THOSE NUMBERS ARE RETRACTED — RE-MEASURED 14z-107 (7): MAME 2146 /
sim 2609, skew +463** — and re-measured a second time in 14z-107 (8), after
the harness stopped holding four buttons down, with the same answer.** 2507 and 2502 were measured on runs whose input
script the frame writer was replaying (see "THE HARNESS'S FRAME WRITER
CORRUPTED THE SIMULATED INPUT SCRIPT"); with the host doing nothing with the
pixels the anchor is 2609 in every leg that does not fork, and the "~99
frames earlier" reading above was the replayed script hurrying the select
screen along — the clean figure is 3 frames LATER than the boot offset, not
99 earlier. 2609/463 is what the gate freezes
(`tests/test_mister_sim_anchor.sh`) and what "THE ANCHOR MEASUREMENT" below
reports; an earlier "sim 2606 / skew 460" in this paragraph was the boot
offset applied to the wrong frame and is retracted.

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

**THE ANCHOR MEASUREMENT (stock `vsavj`, `05_timeout_idle`).** Round-1 match
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
[--frames N] [--wram FIRST LAST] [--core cps2|cps2w]
[--frame-output off|fork|collect]`, with `ROMDIR` and
`JTSIM_SCRATCH` in the environment. Every step is idempotent (clone, symlinks,
Go build, MRA, seed), it prints the sha1 of everything it reads, and it
REFUSES an out-dir inside the repo (rule 7) or a scratch clone inside it.
**Since 14z-107 (7) it also asserts the DUMP SET** — every `--wram` run ends
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

## THE WIDE ROMSET DOES NOT BOOT ON THE CORE YET (measured 14z-107 (10))

**This is the finding slice D3 was supposed to demonstrate against, and it is
the reason the demonstration is not green.** Everything the profile needs is
in the RTL — the object promote, the 6 MB program window, the placement, the
QSound width, all gated — and the `.rom` is byte-for-byte the map. The game
still does not get past its own boot sequence.

**The trace**, `11_pick_donovan` on `cps2w` with the real
`vsavjw.rom` (66,265,152 B, sha1 `d462e55a…`), SDRAM read probes on the two
group-C windows and on both vanilla obj banks:

| simulated frame | what the core is doing |
|---|---|
| 0-659 | the ROM transfer; core in reset |
| 660-925 | the CPS-2 RAM test draws, line by line (`WORK / CPS0 / CPS1 / CPS2 / OBJECT`) |
| 928-1560 | further boot screens, black between them |
| 1578-2241 | the QSound / Capcom legal screen, STATIC for 664 frames |
| **2242** | **the machine RESETS — the RAM test starts over at `WORK`** |

The cycle is ~1,580 frames (26 s) and it repeats. **No sprite is ever drawn**:
over 4,000 simulated frames the probe counts ZERO reads in SDRAM bank 2
(vanilla obj banks 0 and 2) and zero in both group-C windows, while bank 3
takes 94,692,120 word reads over **264 distinct 128-byte blocks**, all inside
its first 4 MB — a tiny scroll working set drawn over and over. The same probe
on the STOCK image counts **313,024 reads over 372 distinct blocks in bank 2**
and **2,482 distinct blocks in bank 3**, reaching `0x9C177E`. For comparison,
MAME running the SAME romset and the SAME replay is at the character-select
screen by frame 930.

**AND HERE IS THE SHARPEST FORM OF IT: THE TWO BOOTS ARE TRAFFIC-IDENTICAL
FOR 448 FRAMES AND THEN DIVERGE.** The same core (`cps2w`), the same replay,
the same probes, one on the stock image and one on the WIDE image, with the
frame counted FROM RESET (i.e. minus each image's own transfer length):

| core frame | stock `vsavj.rom` | WIDE `vsavjw.rom` |
|---|---|---|
| 1-83 | the RAM test draws, ramping 25,472 → 27,776 words/frame in bank 3 | **the same ramp, the same values, the same frames** |
| 87-264 | 26,848 steady (178 frames) | **26,848 steady (178 frames)** |
| 268-447 | 33,984 steady (180 frames) | **33,984 steady (180 frames)** |
| **462** | **48,928 — the TITLE SCREEN, "PRESS 1P OR 2P START", CREDITS:1** | — |
| **449-718** | — | **the RAM test draws AGAIN, the same ramp** |
| 721-900 | | 33,984 again |
| 919-1582 | | 26,944 for 664 frames, then RESET |

**The divergence is at core frame ~448**, at the end of the third boot phase,
where the stock image goes to the title and the WIDE image starts its boot
test over. Everything before that is identical to the frame. That is the
narrowest window this lane can currently put around the fault, and it is
where a work-RAM differential against MAME should be taken.

**WHAT IT IS NOT — the eliminations, which are the useful part.**

* **It is not any of the eight `wide_en`-gated sites.** The identical run with
  header byte 41 set to `0xFF` (profile OFF) produces a **frame-for-frame
  identical** traffic trace: the same transitions at the same frames, the same
  reset at 2242 — 94,691,928 bank-3 reads against 94,692,120. With the profile
  clear the promote is zero, the group-C redirect and read select are off, the
  QSound split is off and the 6 MB decode is off. All of that changes nothing.
  **AND THE WORK RAM SAYS THE SAME THING, ON THE PROJECT'S OWN MASKED BASIS.**
  Both legs dump `RAM:$FF0000-$FFFFFF` over frames 3400-3620. Of 221 frames,
  156 differ — and every differing byte is in one of the TWO WINDOWS CLAUDE.md
  §4 masks: the dead stack `$FF7F00-$FF7FFF`, and `$FF043C`, the 68k↔QSound
  handshake latch (28 frames, `08` against `04`, which `atlas/ram.md:65`
  records as a one-frame phase). Nowhere else, and never more than 64 bytes of
  65,536 in a frame. **On the masked basis the two profile states produce
  BIT-IDENTICAL work RAM**, which means the program never reaches the code
  that reads above 4 MB before it dies.
* **It is not the download.** `tests/test_mister_sdram_census.sh` compares all
  67,108,864 bytes of all four banks against the map on this exact image and
  core, and passes. The two parts of the image a census cannot see are the
  CPS-2 key and the DSP firmware, and both are byte-identical to the stock
  image's (header bytes 8-40 and 44-63 compare equal; the firmware region is
  8 KiB in both and is addressed by `{10'd0, bulk_addr[12:0]}`, which starts
  at 0 for both images).
* **It is not the romset.** MAME on the same `build/m3b_merged13/rompath`,
  the same replay and a fresh sandbox reaches the select screen with the full
  18-character wheel and the M6 mark.
* **It is not a black-screen artefact.** The pictures are real: the RAM test
  and the legal screen render correctly on the positive leg.
* **It is not the probe.** The same probe, the same binary and the same replay
  on the STOCK image count **313,024 reads over 372 distinct tiles in SDRAM
  bank 2**, first at simulated frame 1544. On the WIDE image the same window
  reads ZERO. A zero here is a fact about the core.
* **It is not the core.** `cps2w` carrying D3 and D4 runs the STOCK romset to
  the round-1 match start at the frozen anchor — MAME 2146 / sim 2609 / skew
  463, every mapped field agreeing, all controls firing
  (`tests/test_mister_sim_anchor.sh`) — and to a bit-identical work RAM
  against `cps2` frame by frame (`tests/test_mister_wide_inert.sh`). A match
  draws thousands of sprites, so the object engine, the promote chain and the
  program path are all exercised and all correct.

**AND THE PROFILE BIT IS PROVABLY LIVE**, which is what makes the first
elimination worth trusting: the same two legs render the legal screen
differently (see "the cheapest proof that the profile bit is live" below).

**WHERE TO LOOK NEXT.** The failure is shared between the two profile states
and specific to the WIDE image, so it is in a path that is the same in both
and differs between the images. The remaining candidates, in order:

1. **The sound path.** The legal screen is where the Capcom jingle plays, and
   the profile RELOCATED all twenty per-character sound record arrays above
   `CPU:$400000` (`cps2_wide.md` "B4 prg"). With the profile clear those reads
   return `0xFFFF`; with it set they return ROM. If the 68k blocks on the
   QSound handshake the picture would stand exactly like this. That the two
   legs behave identically argues against it — unless the sound path is
   reached only after the failure.
2. **A work-RAM differential against MAME.** The standard §4 bug report:
   dump `RAM:$FF0000-$FFFFFF` on the core across the legal screen and against
   MAME at the same game frames, and name the first divergent byte. MAME
   dumps for frames 200-760 of this replay are cheap to produce.
3. **The EEPROM.** The core's jt9346 starts blank; a first-boot path that
   differs from MAME's is a plausible source of extra boot phases, though not
   of a reset loop.
4. **Anything the boot test itself reads that a 6 MB image changes.** The
   divergence is at the END of the third boot phase, which is where the test
   sequence decides to hand over to the attract loop. The two images differ
   there only in what the program ROM contains above 4 MB and in the size of
   three declared regions.

**THE TRAFFIC MEASUREMENT WAS TAKEN ANYWAY, AND IT IS WORTH KEEPING**
(`tests/audit_sdram_bank_load.sh --core cps2w --wide build/m3b_merged13`,
2,800 frames, zero `SDRAM reads clashed`). Its phase labels are meaningless on
a looping boot, but the PEAK table depends on no boundary: **bank 0 peaks at
54,422 accesses per video frame = 44.0% of its all-miss ceiling**, bank 1 at
12,043 (9.7%), bank 3 at 8,548 (6.9%) — and **bank 2 at exactly ZERO**, which
is the boot failure in one number. Bank 0's figure is what the re-pack costs
WITHOUT any group-C obj traffic, because none exists to add.

**WHAT THIS DOES NOT INVALIDATE.** D3's promote is proven at the expression
level over its whole input space, and D3's destination is proven reachable by
construction (`rom0_bank[2]` is driven, the chain is three bits wide at every
port, `gfxc_sel` is the only gate). What is missing is the END-TO-END
demonstration, and it is blocked behind this.

## THE SDRAM READ PROBE: watching the core FETCH (14z-107 (10), fork commit 12)

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
- **Four slots, not two, and the reason is the instrument's own honesty.**
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

Worth keeping for the shape of it: a two-legged experiment whose legs differ by
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

## THE SDRAM IMAGE CENSUS: reading the download back out (14z-107 (9))

Platform mechanics, true of any jtcores core. Slice D2 places a romset in
SDRAM and changes no fetch at all, so the only thing that can be checked is
the IMAGE — and the image was already reachable; the lane was throwing it
away.

- **`test.cpp` dumps all four banks, once, the instant a FULL download
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
  WIDE set is a CLONE whose parent is the BUILD's `vsav.zip` while the stock
  leg needs the pristine one, and `jtframe mra` reads a hard-coded
  `$HOME/.mame/roms`. `run_sim_jtcps2.sh --wide <build>` delegates to that
  script, which stages a private `$HOME` per run.

## The per-bank SDRAM traffic profile (measured 14z-107 (3))

Stock `vsavj` on the stock `cps2` core, `05_timeout_idle`, 2,800 frames,
`tests/audit_sdram_bank_load.sh`; full table and verdict in
`build/sdram_bank_load_14z107.log`. Figures are PER VIDEO FRAME.

| phase | ba0 (68k+VRAM+ORAM+WRAM+snd) | ba1 (QSound PCM) | ba2 (obj) | ba3 (obj+scroll) | data bus |
|---|---|---|---|---|---|
| attract | 38,377 acc | 3,511 acc / 78.5% row miss | 0 | 9,485 / 25.3% | 12.8% |
| select+VS | 39,696 acc | 13,911 / **99.0%** | 303 / 74.6% | 12,348 / 36.1% | 16.5% |
| in-match | 40,976 acc | 13,926 / **98.3%** | 1,096 / 42.2% | 18,438 / **28.9%** | 18.5% |

**RE-DERIVED 14z-107 (7) from the SAME committed log**, after the match-start
anchor was corrected 2502 -> 2609 (the phase boundaries are keyed to it). The
figures moved by well under 1% — both phases were already steady-state — and
no conclusion below changes. The pre-correction table read 38,278 / 3,464 /
9,453 (attract), 39,635 / 13,856 / 261 / 12,079 (select+VS) and 40,797 /
14,132 / 1,017 / 17,467 (in-match).

**Read "acc" as READ+WRITE commands and the percentage as the ROW MISS
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
**Since 14z-107 (6) the twin is a TWO-PART claim and both parts are gated.**
The MRA twin above is unchanged and still exact. What changed is the CORE
DIR: cps2w carries RTL, so "identical modulo CORENAME" became "identical
modulo an ENUMERATED delta" — **six** files in `cores/cps2w/hdl` since slice
D2 (it was four at D1), a frozen line-by-line diff for the FOUR that override
shared files (`tests/test_mister_wide_gate.sh` check 1), `git diff` proving
`cores/cps1`, `cores/cps2`, `cores/cps15` never moved
(`tests/test_jtcores_twin.sh` 2e), and — added at D2, because D2 puts a file
OUTSIDE `cores/` for the first time — the fork's WHOLE-TREE `git diff
--name-status` held to a declared 18 paths (2f). The gate that used to say
"game.yaml identical (no RTL override)" was moved DELIBERATELY, the way check
2c was moved at D0.

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

- ~~**The Verilator lane's match-start anchor is VIDEO-SENSITIVE and the
  path is not explained** (opened 14z-107 (6) G6).~~ **CLOSED 14z-107 (7):**
  the forked frame writer's `exit(0)` rewound the parent's `sim_inputs.hex`,
  so the simulated CONTROLLER was replayed once per fork. Fixed at the root
  (fork commit 9, `_exit(0)`) and belt-and-braces (fork commit 8,
  `JTFRAME_SIM_NOVIDEO`, `--frame-output off` by default). **The frozen
  anchor was the artifact, not the red one: 2609 / skew 463.** Section
  "THE HARNESS'S FRAME WRITER CORRUPTED THE SIMULATED INPUT SCRIPT".
- ~~Whether `jtsim` runs at all on macOS~~ — ANSWERED 14z-106: it does, with
  the brew deps in the Recipe above.
- ~~Time per simulated CPS-2 frame~~ — ANSWERED: ~1.0-1.2 s/frame, so a
  select-reaching 2,600-frame run is ~45 min and the 12,120-frame
  `05_timeout_idle` is ~3.5-4 h. Fine for a gate that dumps at a few §4
  anchors; not a per-frame sweep of the 46-replay corpus.
- Input coverage: the v1.7.3 harness is P1-only with 4 buttons, so
  `02_demitri_vs_cpu` and `04_select_fuzz` still refuse. Extending
  `test.cpp`'s `SimInputs` (P2, buttons 5/6) is a further fork commit —
  **DECIDED (maintainer, 2026-08-23): later.**
  **THE FIDELITY HALF IS DONE (14z-107 (8), fork commit 10)** — buttons 5
  and 6 were not absent, they were stuck ON, and so were P2's; that was a
  BUG, it made the oracle's two legs run different inputs, and it is fixed
  and re-frozen. What remains deferred is the COVERAGE half: making them
  SCRIPTABLE so a 2P replay can pin the arcade-draw opponent.
- ~~The width surgery itself (SDRAMW 23 -> 24 and the bank/prog/ioctl bit)
  waits on the profile-shape ruling in STATE "Decisions pending".~~
  **SUPERSEDED 14z-107 (2).** The PROFILE ruling landed (WIDE v1 verbatim,
  one romset — unchanged and not reopened); what was wrong was the
  implementation assumption bundled with it. "SDRAMW 23 -> 24 and one more
  bit" is NOT the shape of the work: at our pin there is no 24-bit map to
  reach (row/column/pins are saturated), the 128 MB tier exists only
  upstream and only in the cache-lane branch, and the CPS-2 core carries
  format caps that no SDRAM tier lifts. ~~The route is now its own pending
  decision — **THE MiSTer MEMORY-MAP ROUTE** in STATE "Decisions pending":~~
  **RULED (maintainer, 2026-08-23) — option (2):**
  (1) uprev to upstream master + `JTFRAME_SDRAM_XL` + cache lanes, or
  **(2) stay at the pin and BANK-REPACK inside 64 MB** (tenant art into bank 1
  beside the PCM, reached by the promoted tile-code bit) — **measuring first,
  with XL as the FALLBACK.** The measurement returned **GO**
  (`tests/audit_sdram_bank_load.sh`) and the repack SHIPPED in slice D2. Either
  way the core-side format work of "What the CPS-2 CORE caps" is required.
- ~~**The Verilator SDRAM model's 8 MB-per-bank decode** (the caveat next to
  the Recipe) is a prerequisite for simulating any widened set, and is
  three constants. Not started.~~ **DONE 14z-107 (3), fork commit 3** — and
  it was NOT three constants: the dropped bit is `addr[22]` riding on
  `sdram_a[9]`, not `addr[9]`. See "THE LANE'S SDRAM MODEL WAS WRONG" above.
- ~~**The bank-repack question is MEASURED and the answer is GO** — see "The
  per-bank SDRAM traffic profile" above and
  `build/sdram_bank_load_14z107.log`. It bounds the headroom; proving the
  repacked design needs the same instrument on a `cps2w` core carrying the
  repacked map.~~ **THE SECOND HALF IS DONE 14z-107 (10):**
  `tests/audit_sdram_bank_load.sh --core cps2w --wide build/m3b_merged13`
  runs the same instrument on the repacked core with the WIDE romset, which
  is what `mister_map.md` §9 open question 1 asked for — only a core carrying
  the obj promote can produce group-C traffic at all. See that question for
  the numbers.
- **Input coverage's remaining half is unchanged**: `SimInputs` is still
  P1-only for buttons 5/6 and P2 (the FIDELITY defect is fixed; the
  SCRIPTABILITY is deferred by ruling).
