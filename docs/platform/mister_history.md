# MiSTer — HISTORY (blocks moved verbatim from `docs/platform/mister.md`)

Moved by the documentation rationalization pass (14z-123, G4). Rules:
historical entries are not rewritten (CLAUDE.md §5 [VSP-13] step 4); a
correction is made where the live claim lives, in `mister.md`, and marked
here only if it was already marked when the block moved. Each block is
headed by the section it left. These are the lane's problem→fix
narratives as they were written — a "RESOLVED", "RETRACTED" or "where to
look next" here is the status AS IT WAS; `mister.md` carries the current
fact and the gate. This file is a LOG for `tools/checkskills.py` (MSC/MSV
numbers may live here). No `**[PFX-N]**` anchor lives in this file.

## [14z-123 G4] from «The runtime profile gate — the 'video-sensitive anchor' bullet»

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

## [14z-123 G4] from «THE HARNESS'S FRAME WRITER CORRUPTED THE SIMULATED INPUT SCRIPT — the whole section»

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

## [14z-123 G4] from «SimInputs — the 'found while auditing, deliberately not fixed' opener»

**The second harness defect of the same family as the frame writer, and the
one that made the two legs of the §4 oracle run DIFFERENT INPUTS.** Found
while auditing in 14z-107 (7), recorded there and deliberately not fixed
(the fix moves the frozen anchor); measured and fixed here.

## [14z-123 G4] from «SimInputs — the boot-footprint and match-window address tables»

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

## [14z-123 G4] from «The simulation lane — the scripted-inputs CORRECTED/FIXED narrative»

**CORRECTED 14z-107 (7), FIXED 14z-107 (8): buttons 5 and 6 did not "not
  exist" — THEY WERE HELD DOWN, and so were P2's.** `test.cpp`'s `&0xf0`
  direction mask and its `0xff` joystick seeds treated a `[9:0]` ACTIVE-LOW
  port as 8-bit, so from the first line of `sim_inputs.hex` the simulated P1
  had buttons 5 and 6 pressed and P2 had them pressed for the whole run.
  Fork commit 10 fixes both (`& ~0xf`, `0x3ff`); the measurement, the MAME
  differential that located the game's input mirror, and the before/after
  table are in "`SimInputs` HELD BUTTONS 5 AND 6 DOWN" above. It re-froze
  the §4 anchor, which is why it was its own slice.

## [14z-123 G4] from «The simulation lane — the 'State out — RETRACTED AND REPLACED' opener»

- **State out — RETRACTED AND REPLACED 14z-107.** This bullet used to say
  that `JTFRAME_SIM_IODUMP` plus `JTFRAME_SAVESDRAM` made "the per-frame 68k
  work-RAM window the MAME oracle checksums" reachable out of the box. **Both
  halves are false on this core and on this simulator**, measured 14z-107:

## [14z-123 G4] from «SDRAM model — the 'RESOLVED / the caveat this section used to carry' opener»

**RESOLVED.** The caveat this section used to carry ("the Verilator SDRAM
model is a 32 MB MODULE", 14z-107 (2)) was RIGHT about the symptom and WRONG
about the mechanism, and the fix it proposed would have broken the map in a
new way. Both are recorded below because the eliminations still hold.

## [14z-123 G4] from «SDRAM model — 'What this retires'»

**What this retires.** 14z-106 slice C's "`frame_00480.jpg` shows sprites"
was weaker evidence than it read, and 14z-107 (2) said so; now the lane
actually renders from a faithful tile map, and simulating a widened set is
no longer blocked on this.

## [14z-123 G4] from «The work-RAM oracle — the boot-skew paragraph with its three retractions»

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

## [14z-123 G4] from «THE WIDE ROMSET DOES NOT BOOT ON THE CORE YET — the symptom, the traffic bracket, the eliminations, THE FIRST DIVERGENT BYTE, where to look next»

## THE WIDE ROMSET DOES NOT BOOT ON THE CORE YET — **RESOLVED 14z-107 (11),
## SLICE D5.** (measured 14z-107 (10))

> **THE CAUSE WAS THE CPS-2 DECRYPTION RANGE, and the section below is the
> symptom and the eliminations, kept verbatim.** With slice D5 in
> (`cores/cps2w/hdl/jtcps2_decrypt.v`, fork `c00d7ce7`) the WIDE romset boots
> to the select screen and the core FETCHES tenant art. See "CAN THE 68k READ
> ABOVE 4 MB?" below for the measurement.
>
> **ONE ELIMINATION BELOW IS CORRECTED IN PLACE, not withdrawn:** "the same
> `.rom` with byte 41 = `0xFF` produces a frame-for-frame identical traffic
> trace" is true of bank-3 traffic and of masked work RAM, which is what was
> measured — and the two legs are NOT identical. The profile-ON leg completes
> **ten** program-ROM reads above `CPU:$400000` and the profile-CLEAR leg
> **zero**. The instrument that said "identical" could not see the window it
> was being asked about.

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

### THE FIRST DIVERGENT BYTE: THE SOUND DRIVER, AT MAME FRAME 266

**The §4 differential was taken and it names a subsystem.** `cps2w` with the
WIDE image, `RAM:$FF0000-$FFFFFF` dumped at simulated frames 900-1400 (core
frames 241-741), against MAME on the same romset and replay at the same game
frames, masking the two windows CLAUDE.md §4 masks:

| MAME frame | live bytes differing (of 65,536) |
|---|---|
| 241-265 | **2** — `$FF8003` and `$FF8080` only, a constant frame-counter/RNG phase |
| **266** | **14, and this is the onset** |
| 267 | 42 |
| 281-441 | back to 2-3 |
| **461** | **748** |
| 541-741 | ~870, steady |

**The onset is entirely in the SOUND DRIVER.** At MAME frame 266 the fourteen
bytes are `$FF025C/D` (a `$FF02xx` channel record — `atlas/ram.md:66` names
the 0x20-stride records at `$025C/$027C/$029C…`), `$FF0462/3` (the driver's
current-record pointer spill `$FF0460.l`: MAME rests at `…043C`, the core
reads `…025C`, i.e. mid-scan), `$FF04DB-$FF04E5`, and the two counter bytes
that were already off. At frame 267 the driver's per-channel arrays at
`$FF04A1-$FF04B5` diverge outright — the core holding `C0` where MAME holds
an alternating `00/01`. Nothing outside the sound area moves until frame 461,
when the divergence explodes and the boot is lost.

**That is the strongest single lead in this file**, and it corroborates the
traffic bracket from the other side: the traffic divergence is at core frame
~448 and the STATE divergence starts at core frame 266 in the sound driver
and stays contained there for ~180 frames before it becomes fatal. The 68k
sound path is also exactly what the profile touched hardest — WIDE v1
relocated **all twenty per-character sound record arrays** above
`CPU:$400000` (`cps2_wide.md` "B4 prg").

**One caution before acting on it.** The pos/neg comparison shows the 6 MB
decode changes nothing on the masked basis, so if the driver were failing
*because* it cannot read a relocated array, turning the decode on ought to
have changed something. Either the boot jingle uses a record still inside the
base 4 MB, or the fault is upstream of the relocation. Measure before
theorising; the dumps to do it with are one command each (below).

**WHERE TO LOOK NEXT.** The failure is shared between the two profile states
and specific to the WIDE image, so it is in a path that is the same in both
and differs between the images. The remaining candidates, in order:

1. **The sound path — NOW THE MEASURED LEAD, see above.** The legal screen is where the Capcom jingle plays, and
   the profile RELOCATED all twenty per-character sound record arrays above
   `CPU:$400000` (`cps2_wide.md` "B4 prg"). With the profile clear those reads
   return `0xFFFF`; with it set they return ROM. If the 68k blocks on the
   QSound handshake the picture would stand exactly like this. That the two
   legs behave identically argues against it — unless the sound path is
   reached only after the failure.
2. **A work-RAM differential against MAME — THE RECOMMENDED NEXT PROBE, and
   both halves of it are one command each.** The standard §4 bug report: dump
   `RAM:$FF0000-$FFFFFF` on the core across the divergence and against MAME at
   the same game frames, and name the first divergent byte. Core frame =
   simulated frame minus 659, and the divergence is at core frame ~448, so a
   window of core 240-740 brackets it:

   ```sh
   # the core leg, ~25 min
   ROMDIR=... tools/run_sim_jtcps2.sh tests/replays/11_pick_donovan.rpl OUT \
       --core cps2w --wide build/m3b_merged13 --frames 1450 --wram 900 1400
   # the MAME leg, ~1 min
   DUMPS="$(python3 -c "print(';'.join(f'{f}:ff0000-ffffff' for f in range(200,760)))")" \
   MAME_BIN=$HOME/.cache/vampire-saved/mame/cps2 \
   MAME_ROMPATH="$PWD/build/m3b_merged13/rompath;$ROMDIR" \
       tools/run_replay_mame.sh vsavjw tests/replays/11_pick_donovan.rpl OUT2/log OUT2/sb
   ```

   Compare core frame `f` against MAME frame `f-659`, masking the two windows
   CLAUDE.md §4 masks (`$FF7F00-$FF7FFF` and `$FF043C`) — the pos-vs-neg
   comparison above shows those are the only places two runs of this boot
   legitimately differ.
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

## [14z-123 G4] from «WITH SLICE D5 IN — the gate's two defects»

**THE GATE'S OWN FIRST REAL MEASUREMENT FOUND TWO DEFECTS IN THE GATE**, which
is what a gate that has never actually fired should be expected to produce:
* it computed the tile code from the **absolute** SDRAM address rather than
  relative to the armed window's base, so a correct promote reported
  `0x170D6-0x1FA41` against an extent of `0xFFDB` and read as a defect;
* its instrument-liveness control demanded vanilla obj traffic in the CONTROL
  leg — an image whose group-C art ALIASES over vanilla's obj banks by
  construction (the download redirect is off), which therefore cannot boot and
  never could. The control leg is now held to what it can be held to: the probe
  counting millions of reads in bank 3, and a working set that is the LOOPING
  boot's (263 distinct blocks against the positive leg's 2,423).

## [14z-123 G4] from «TWO INSTRUMENT DEFECTS PAID FOR ON THE WAY»

### TWO INSTRUMENT DEFECTS PAID FOR ON THE WAY, BOTH CAUGHT BY THE DATA

Recorded because they are the session's transferable part, and because this
lane has now produced six.

1. **The probe's first draft split the window on `rom_addr[21]`.** `rom_addr`
   is declared `[22:1]` and driven `A[22:1]`, so its INDEX is the address bit
   and `[21]` is `A[21]` — set for `$200000-$3FFFFF`. It reported **2,560 reads
   "above `$400000`" at addresses `$38C2A0-$3D8256`**, in the very first frame
   it fired. Nothing about the COUNT looked wrong; only the addresses
   contradicted the label, and only because the probe logged them.
   `tools/prgprobe_verdict.py` now REFUSES any record outside the window its
   label claims, before any verdict.
2. **The verdict tool judged only the RAW word and reported "D4 WORKS"** over
   ten fetches the CPU received as garbage. It now requires BOTH — the raw word
   is the `.rom`'s AND the CPU received that raw word — and names the decryptor
   when the failing records are all opcode fetches.
   `tests/test_mister_prg_probe.sh` 4g freezes the real case as a fixture.

**WHAT THIS RETRACTS.** `mister_map.md` §8's "NOT DECRYPTED, AND THAT IS
CORRECT … the two agree without either being changed" was true of the HARDWARE,
of MAME and of FBNeo, and FALSE of jtcps2. The same sentence is in slice D4's
fork-commit message and in the `jtcps2_main.v` override header.

## [14z-123 G4] from «The per-bank SDRAM traffic profile — the RE-DERIVED paragraph»

**RE-DERIVED 14z-107 (7) from the SAME committed log**, after the match-start
anchor was corrected 2502 -> 2609 (the phase boundaries are keyed to it). The
figures moved by well under 1% — both phases were already steady-state — and
no conclusion below changes. The pre-correction table read 38,278 / 3,464 /
9,453 (attract), 39,635 / 13,856 / 261 / 12,079 (select+VS) and 40,797 /
14,132 / 1,017 / 17,467 (in-match).

## [14z-123 G4] from «The simulated joystick — the 'THIS SUPERSEDES' paragraph»

**THIS SUPERSEDES THE 14z-107 (12) READING, WHICH WAS RIGHT ABOUT THE HALF IT
SAW AND WRONG ABOUT THE HALF IT DID NOT.** That measurement had two data
points — Left and Down, from `36_pick_tenant_cell` — and inferred a two-bit
SWAP that left Up and Right untouched, on the strength of the translator's
docstring. **Up is not untouched: it arrives as Right.** A two-bit fix would
have left half the defect in the tree, and the gate would have frozen it.
The prose that called this a TRANSPOSITION is corrected throughout; the
measurement that named only Left and Down stands as far as it went.

## [14z-123 G4] from «The simulated joystick — WHAT IT COST»

### WHAT IT COST, and why it is the lane's most instructive defect yet

The measurement built to prove obj bank 4 — the tenants' FIGHTER art — is
fetched returned **exactly zero** reads, in-match included. The RTL was
innocent in every respect: the promote fired, the window decoded, the
placement held. The cursor moved on every press, just not in the direction
asked; it landed on Victor; and the core faithfully drew the character it was
handed. **The RENDERED frame is what cracked it** — a VS screen showing
Demitri vs Victor, against a replay that asks for a tenant. The counters alone
read as "D3 does not fetch", which is a conclusion about the RTL drawn from a
defect in the harness.

**THE CHAIN CHECKED OUT ON PAPER, WHICH IS THE POINT.** The translator's bit
map matched `test.cpp`'s `parse_inputs` line for line; neither `cps2` nor
`cps2w` defines a `JTFRAME_JOY_*` override, so the default path applies;
`in0 <= {joystick2[7:0], joystick1[7:0]}` puts the directions on `in0[3:0]`.
Every step reads correct and the result was still wrong — because the one
thing nobody checked was which END of the nibble the port counts from. An
input path is measured against the game's own mirror, never reasoned about.

## [14z-123 G4] from «The simulated joystick — THE FOURTH INPUT-PATH DEFECT (the count paragraph)»

### THE FOURTH INPUT-PATH DEFECT IN THIS LANE

After the forked frame writer rewinding `sim_inputs.hex`, P1's buttons 5/6
held down and P2's held too — and the seventh instrument defect overall. Three
of the four were invisible until a replay first needed the feature: **the sim
input path is only ever as tested as the last replay that used it.** Index
entry: `docs/platform/gotchas.md`.

## [14z-123 G4] from «Open / to verify in the arc — the struck-through closed items»

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
- Input coverage — **CURRENT STATE (14z-113 rewrite of the lead): P1 AND
  P2, directions + buttons 1-3 each; buttons 4/5/6 REFUSED by
  `rpl2siminputs.py`** (button 4's bit doubles as `dip_test`), so
  `02_demitri_vs_cpu` and `04_select_fuzz` still refuse. History: the
  v1.7.3 harness was P1-only with 4 buttons; extending
  `test.cpp`'s `SimInputs` (P2, buttons 5/6) was a further fork commit —
  **DECIDED (maintainer, 2026-08-23): later — and "later" ARRIVED at
  14z-109 (maintainer-ruled during the #99 crash hunt): P2 IS SCRIPTABLE**
  (fork `4dfc3734`, file bits 12+, backward compatibility proven by the
  unchanged frozen sha1). Buttons 4/5/6 remain unexpressible/refused.
  **THE FIDELITY HALF was already done (14z-107 (8), fork commit 10)** —
  buttons 5 and 6 were not absent, they were stuck ON, and so were P2's;
  that was a BUG, fixed and re-frozen.
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

## [14z-123 G4] from «THE 14z-108/109 MEASUREMENTS — 'Why this section exists'»

**Why this section exists.** This file is the LOG and the synthesis's own
staleness rule says a number must be traceable to it — yet the tenant
oracle, the bank-1 load, the QSound extension fetch, the OBJ-list oracle and
the synthesis fit were recorded only in `mister_core.md` §12, the HANDOFF
gate table and STATE 14z-108/109. The skill checker (`tools/checkskills.py`,
"a number a skill quotes must appear in a log") refused every one of them,
which is exactly the gap it was built to find. The figures below are
quotations from the gates' own outputs as recorded at 14z-108/109; each names
its gate, and the gate re-produces it.
