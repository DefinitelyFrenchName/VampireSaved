# STATE — living progress log

## Session 14z-107 (9) — MiSTer SLICE D2: THE PLACEMENT IS IN THE RTL AND
## THE SDRAM IMAGE WAS COUNTED, ALL 67,108,864 BYTES OF IT. The bank-0
## re-pack, the group-C GFX redirect, the QSound split across two banks and
## two new slot counts ship behind `wide_en`; jtframe gains ONE new file.
## Fork commit `0df6f000`, **PUSHED** (fork pushes are standing-authorised
## now; the main repo is still never pushed). `cores/cps1`/`cps2`/`cps15`
## BYTE-UNTOUCHED. **THE CENSUS CONTRADICTED THE MAP'S SLACK BY A FACTOR OF
## SIX (section E), AND THE INERT GATE WENT RED FOR A REASON THAT WAS NOT
## THE RTL (section D).**

**The one line:** the WIDE romset now has a place in SDRAM, every byte of it
was checked against the map rather than argued for, and the checking found
two things the design did not know — one about the map, one about the
instrument.

**A. WHAT SHIPPED, AND WHAT IS AN ADDITION VS A COPY.**

| file | new or copied | why |
|---|---|---|
| `modules/jtframe/hdl/sdram/jtframe_ram1_7slots.v` | **NEW — an ADDITION to jtframe** | bank 0 needs seven streams (RAM/VRAM/ORAM RW, VRAM DMA, gfx-ORAM, main ROM, Z80, QSound high, group-C obj bank 5) and upstream's `ram1_Nslots` family stops at five. Mechanically `ram1_5slots.v` plus two `jtframe_romrq` instances and nothing else, so a reviewer diffs it against its sibling. Maintainer-ruled option A (`mister_map.md` §5). |
| `cores/cps2w/hdl/jtcps1_sdram.v` | **COPIED from `cores/cps1/hdl`** | the bank-0 re-pack, the QSound read split, the group-C read select, the two new slot counts. SHARED with cps1/cps15/cps2, so it cannot be edited in place. |
| `cores/cps2w/hdl/jtcps1_prom_we.v` | **COPIED from `cores/cps1/hdl`** | the DOWNLOAD-side group-C redirect and QSound split. Same reason. |
| `cores/cps2w/hdl/jtcps2_game.v` | already a copy (D1); extended | `wide_en` routed to the SDRAM block, the full 24-bit `qsnd_addr` handed over for the split, `rom0_bank` presented as `{1'b0, rom0_bank}`. |
| `cores/cps2w/cfg/game.yaml` | rewritten | `cores/cps1/cfg/common.yaml` INLINED minus the two overridden files, plus the new jtframe module. 68 lines of delta, frozen in `tests/expect/cps2w_game_yaml_delta.txt`. |

**WHERE THE NEW jtframe FILE WENT, AND WHY IT IS AN ADDITION AND NOT A
MODIFICATION.** With its family in `modules/jtframe/hdl/sdram/`, so it can be
read side by side with `jtframe_ram1_5slots.v` — but pulled by
**`cores/cps2w/cfg/game.yaml` alone** and deliberately NOT added to jtframe's
own `hdl/sdram/jtframe_sdram64.yaml`, which is SHARED and would have put the
module on every jtcores core's compile list, the reference `cps2` included.
Measured: `jtframe files sim cps2` does not contain it, and the two cores'
lists differ in exactly **11** entries (4 shared originals out; 6 overrides +
1 new jtframe module in). Gate: `test_mister_wide_gate` 5a/5b/5c/7n.

**B. EVERYTHING WITH A BEHAVIOURAL SURFACE IS GATED — five sites now.**
`is_gfxc = wide_en & gfx_addr[25]` and `is_pcmhi = wide_en & pcm_addr[23]`
(download), `pcmh_sel = wide_en & pcm_addr[PCM_AW]` and
`gfxc_sel = wide_en & rom0_bank[2]` (read), plus D1's bank latch. With
`wide_en` low every expression collapses to the reference core's, character
for character; `test_mister_wide_gate` 7i-7l re-read all four verbatim, and
7 re-reads every placement constant in BYTES against `mister_map.md` §5.
**THE ONE UNGATED CHANGE IS DECLARED, NOT HIDDEN:** the bank-0 re-pack.
`SLOTn_OFFSET` are elaboration-time parameters and cannot switch at run time.
It is a RELOCATION with no behavioural surface — identical data at identical
68k addresses, nothing downloaded to VRAM/ORAM/WRAM, one constant shared by
the Z80 region's download and read, and `JTFRAME_BA0_AUTOPRECH=1` making bank
0's per-access latency address-independent — and it is the one D2 claim that
is MEASURED rather than constructed (section D).

**C. THE CENSUS — D2's core evidence, and it is a WHOLE-IMAGE check.**
`tools/mister_sdram_census.py` (new) replays the download mapping in Python —
regions, the QSound split on `pcm_addr[23]`, the group-C redirect, and the
CPS-2 GFX address scramble, which it un-permutes with sixteen strided slice
copies per 2 MB block — and compares **all 67,108,864 bytes of all four
banks**. Pure stdlib; a full census is under a second. The instrument is the
EXISTING lane: `tools/run_sim_jtcps2.sh` gained `--wide BUILD` (delegates the
`.rom` to `tools/mister_mra.sh`), `--post-frames N` (counted from the END of
the transfer, because `--frames` assumes the 462-frame stock download and the
66 MB WIDE image takes **659**) and `--keep-banks` (collects the four bank
images `test.cpp` dumps the instant a FULL download completes). A census run
therefore costs the download and nothing else, ~11 min.

**FOUR LEGS, `tests/test_mister_sdram_census.sh`, ALL GREEN:**

| leg | core + image | vs map | verdict |
|---|---|---|---|
| A | `cps2w` + WIDE `vsavjw.rom` (66,265,152 B, sha1 `d462e55a…`) | wide | **PASS, all four banks** — ba0 6,359,055 non-zero (37.9%), ba1 12,879,645 (76.8%), ba2 14,873,334 (88.7%), ba3 14,426,104 (86.0%) |
| B | `cps2` + the SAME WIDE image | stock | **PASS, all four banks** — the reference core places it the reference way, group-C aliasing included |
| B | `cps2` + the SAME WIDE image | wide | **FAILS, all four banks** (1,516,787 / 5,524,983 / 6,714,491 / 6,529,272 bytes) — as it must |
| C | `cps2w` + stock `vsavj.rom` | wide | **PASS** — PRG at 0, Z80 at the NEW `0x658000`, no group C, no PCM high, banks 2+3 exactly vanilla |
| D | `cps2` + stock `vsavj.rom` | stock | **PASS** — the calibration leg: the tool checked against a mapping nobody changed |

Region by region, every one at its §5 offset: 68k PRG ba0 `0x000000` 6 MB;
Z80 ba0 `0x658000` 256 KB; QSound PCM low ba1 `0x000000` 8 MB; QSound PCM
high ba0 `0x6E0000` `0xF0000` B; GFX group C obj bank 5 ba0 `0x7E0000` 8 MB;
obj bank 4 ba1 `0x800000` 8 MB; GFX obj banks 0/2 in ba2 and 1/3 in ba3 at
`0x000000`/`0x800000`. The firmware region is `prom_we`, never SDRAM, and the
census asserts that by expecting ZERO everywhere nothing is placed.

**EVERY CONTROL FIRED.** A 1 KiB shift of any placement constant is rejected:
`z80` 206,536 bytes differ (first at `0x658000`), `pcm_hi` 714,457 (first at
`0x6E0002`), `gfxc5` 675,767 (first at `0x7E0080`), `prg` 3,768,659 (first at
`0x0`), `pcm_lo` in bank 1. And the two cross-checks that do not depend on the
tool's model at all: **banks 1, 2 and 3 BYTE-IDENTICAL between `cps2` and
`cps2w` on the same stock image** with bank 0 DIFFERING (the re-pack is
confined to bank 0, and the comparison is not vacuous), and **banks 2+3
DIFFERING between the two cores on the WIDE image** — without the redirect
group C aliases onto vanilla's own art, which is what the redirect exists to
prevent.

**C2. AND THE GATE'S FIRST RUN FOUND THAT THE REFERENCE CORE CANNOT *BUILD*
THE WIDE IMAGE.** Leg B was written as `mister_mra.sh --core cps2 --wide` and
got *no `vsavjw.rom` was produced*. That is slice D0's profile gate working
exactly as designed: `cores/cps2` parses `sourcefile=["cps2.cpp"]` and the
WIDE machine entry is tagged `cps2w.cpp`, so the reference core emits no WIDE
MRA at all. `run_sim_jtcps2.sh --wide` now always GENERATES the image with
`cps2w` and only SIMULATES with `--core` — the right shape for a control
anyway: "hand the reference core the WIDE download image", not "ask it to
build one". Two more gate defects were found the same way and fixed: the
`--perturb` wrapper expected the wrong exit polarity (the tool exits 0 when
its own control fires), and the A-vs-B cross-check would have passed
VACUOUSLY on the missing leg, because `cmp -s` on an absent file reports
"differ".

**D. THE INERT GATE WENT RED IN 101 FRAMES OF 101 — AND THE RTL WAS
INNOCENT.** `test_mister_wide_inert` reported "cps2w differs from cps2 in 101
of 101 frames — the D1 profile is NOT inert". Root cause, found by reading the
run's own command line rather than by theorising: **the RAM-dump hook
addresses SDRAM, not the 68k bus, and D2 MOVED work RAM.**
`JTFRAME_SIM_WRAMDUMP_OFF` was the hard-coded `0x600000`, which is where
`RAM:$FF0000` lives on the reference core — and on `cps2w`, after the bank-0
re-pack, `0x600000` is **VRAM** and work RAM is at `0x648000`. The gate was
comparing cps2's work RAM against cps2w's VRAM. It does not announce itself:
VRAM is a perfectly plausible 64 KB of changing bytes, so the window was
NON-CONSTANT and every other assertion passed.
**Fixed in `tools/run_sim_jtcps2.sh`** (the offset is selected from `--core`
and PRINTED, so the run's own log says what it dumped), and **re-run with
nothing else changed: `cps2w` == `cps2`, BIT-IDENTICAL work RAM in all 101
frames of 540-640**, window non-constant, one-frame-shift control firing.
That is the direct measurement of the un-gated re-pack's inertness, and
changing only the instrument is what makes it a measurement rather than a
story. Filed in `docs/platform/gotchas.md`: **any instrument that names a
PHYSICAL address is invalidated by a memory-map change, and a placement slice
IS a memory-map change.**

**D2. AND THE IN-FLIGHT-EDIT TRAP WAS PAID A THIRD TIME, ON A COMMENT.**
Two comment lines added to `tools/run_sim_jtcps2.sh` while a gate was blocked
inside it moved every byte after the interpreter's saved offset; when the
simulation returned, the shell resumed mid-token and died with `line 440:
unexpected EOF while looking for matching '"'`. **The MEASUREMENT survived** —
the Verilator run had already written its four 16 MB bank images into the
core's `ver/game` — so the leg was recovered by copying them out by hand
instead of paying another 11 minutes, and the census gate then went green on
the recovered images. Reverting the edit at once re-aligned the interpreter
and the two runs that had not yet resumed reading were untouched. Recorded in
`docs/platform/gotchas.md` with that recovery, because the recovery is the
part that was not obvious.

**E. THE CENSUS CONTRADICTED THE MAP, AND THE CENSUS WON.**
`mister_map.md` said the fit had **0.708 MB** of slack. It has **0.125 MB**,
and **SDRAM bank 1 is EXACTLY FULL** (8 MB PCM + 8 MB obj bank 4 =
16,777,216 B to the byte). Bank 0 is used to `0xFE0000`, leaving 131,072 B.
The error was one of KIND, not arithmetic: the map sized the two group-C obj
banks by the art's live ADDRESS FOOTPRINT (7.452 + 7.996 MB), and the MRA
downloads the WHOLE declared 48 MB GFX region, so each obj bank reserves its
full 8 MB whatever the art does inside it. Corrected in place in
`mister_map.md` (the up-front verdict, both §5 bank tables, the whole-tier
arithmetic, the "two moves" argument, open question 5, §11),
`mister_fit.md`, `NEXT_SESSION.md`, `HANDOFF.md`, `tests/ci_static.txt` and
`tests/audit_mister_map_fit.sh` — which now models the banks from the PLACED
offsets and lengths with an overlap check, and whose control B perturbs the
REGION rather than the footprint.

**Both consequences, because they point opposite ways:**
- **Tenant art can now grow freely inside the existing 16 MB.** A new tile
  above `0xEE73` or `0xFFDB` no longer overflows anything — the silent
  months-later bring-up failure open question 5 was written about cannot
  happen by that route.
- **The group-C ROMSET REGION cannot grow at all.** A fifth group-C member,
  or anything past 16 MB, overflows immediately and there is nowhere to put
  it: bank 1 has zero free and bank 0 has 131,072 B.
- What the footprints still say is how much of each region is DEAD — 0.548 MB
  in obj bank 4, 0.004 MB in obj bank 5 — i.e. what a group-C MRA trim could
  recover. **That trim is not the flat `length=` truncation QSound's was:**
  the GFX region is a 4-way 64-bit interleave and the download scramble turns
  a contiguous tail of tile codes into a NON-contiguous set of `.rom` offsets.
  Unmeasured, recorded, not needed today.

**F. TWO MORE THINGS THE SLICE PAID FOR, both in `docs/platform/gotchas.md`.**
1. **Overriding one shared file costs you the whole `.yaml` that pulled it.**
   `jtframe files` dedups by full path, so a core cannot include a yaml and
   override a file that yaml pulls. D1 paid it for `qsound.yaml` (1 file); D2
   paid it for `common.yaml` (20 files transcribed to override 2). The bill is
   the transcription, and it is re-paid by hand at every uprev.
2. **A new jtframe module must be pulled by the CORE**, never added to
   jtframe's shared `jtframe_sdram64.yaml` — that list is included by every
   core. Assert the ABSENCE from the reference core's file list, not just the
   presence in yours.
   Plus a smaller one: `jtcps1_prom_we`'s `prog_ba` fall-through arm is
   reached by the FIRMWARE region as well as QSound, whose region-relative
   `pcm_addr` is a wrapped subtraction with bit 23 SET — so an unqualified
   `pcm_addr[23] ? …` silently re-banks it. Harmless (`prog_we` is 0 there)
   and qualified with `is_oki` anyway: a signal that is right only because
   its enable is off is a defect waiting for a refactor.

**G. WHAT IS STUBBED UNTIL D3, stated plainly.** `rom0_bank` is three bits at
the `jtcps1_sdram` port, but the game top drives `{1'b0, rom0_bank}`. So
`gfxc_sel` is constant 0, the two group-C read slots are provably unreachable,
and **D2 changes no fetch in the running game at all** — which is exactly why
its evidence is the image and not a replay. D3 is the obj promote
(`jtcps2_obj_scan.v:152` `st3_bank <= {table_y[12], table_y[14:13]}`, the
CPS-2 Turbo rule, plus the `dr_bank`/`obj_bank`/`rom_bank`/`rom0_bank` chain
widened to 3 bits); it lands on the destination and the plumbing D2 built.

## Session 14z-107 (8) — THE SIMULATED CONTROLLER WAS PRESSING FOUR BUTTONS
## NOBODY SCRIPTED, AND NOW IT ISN'T. jtframe v1.7.3's `SimInputs` held P1's
## AND P2's buttons 5 and 6 down on every 6-button core — two 8-bit
## constants on a `[9:0]` ACTIVE-LOW port. Fork commit `519aff8b`,
## **LOCAL ONLY** (push authorisation still held). The §4 anchor is
## re-measured and re-frozen at **sim 2609 / skew 463 — UNCHANGED**, band
## untouched at +/- 30. That is the first reading of this anchor taken on
## inputs that match the MAME leg's.

**The one line:** the MAME leg and the sim leg of the §4 oracle had never
been running the same inputs, and the proof is that the sim's work RAM was
byte-identical to a MAME run with four buttons physically held.

**A. THE DEFECT, BOTH HALVES.** `joystick1..4` are `[9:0]` in
`modules/jtframe/hdl/ver/game_test.v:51-54` and ACTIVE LOW.
1. `parse_inputs()` builds the word right — `0x30f | ((v>>4)&0xf0)` releases
   bits 9:8 — and destroys it on the next line: `(dut.joystick1&0xf0) |
   (v&0xf)`. `&0xf0` drops bits 9:8, and 0 on an active-low port is
   PRESSED. All five `JTFRAME_JOY_*` orderings carry the same mask. Only
   EOF released them (`next()`'s else-branch restores `0x3ff`), so a
   SHORTER input file changed the inputs.
2. The constructor seeds `joystick1..4 = 0xff` — bits 9:8 low again — and
   `parse_inputs()` NEVER writes `joystick2..4`. **So P2's buttons 5 and 6
   were held for the whole run, on every core, with or without `-inputs`.**
   That half was not in the 14z-107 (7) write-up; the measurement found it.

Cores with <=4 buttons never see it (`game_test.v:557-561` passes
`joystick*[GAME_BUTTONS+3:0]`). On CPS-2 they are wired:
`jtcps2_main.v:266-268` puts `joystick1[9:7]` in `in1[2:0]`,
`joystick2[8:7]` in `in1[5:4]` and `joystick2[9]` in `in2[14]` — the same
map MAME uses (`tests/lua/replay.lua:76-85`).

**B. VERIFIED BEFORE IT WAS FIXED, AND NOT FROM THE SOURCE.** The task
required showing what the CORE sees, so the observable was located by
experiment rather than assumed. A MAME differential — `05_timeout_idle`
with `1000-1005 p1=56` against the same replay verbatim, whole work RAM
dumped at frames 995-1012 — moves 36 bytes at frame 1000, among them
**`RAM:$FF8058`** (P1 held-buttons high byte) and **`$FF805A`** (P1
new-press). The `p2=56` twin names **`$FF805C`/`$FF805E`**. Bit 0x40 =
button 6, 0x20 = button 5; the block is live from MAME frame ~92-96 (right
after the RAM test), so a ~620-frame simulation reaches it.

| leg, block `$FF8040-$FF8070` at aligned frames | `$FF8058` | `$FF805A` | `$FF805C` | `$FF805E` |
|---|---|---|---|---|
| MAME, replay verbatim (nothing held) | 00 | 00 | 00 | 00 |
| MAME + `p1=56` | **60** | **60** | 00 | 00 |
| MAME + `p2=56` | 00 | 00 | **60** | **60** |
| MAME + `p1=56 p2=56` | **60** | **60** | **60** | **60** |
| **sim at the OLD pin** (cps2, stock `vsavj`, frames 560-620) | **60** | **60** | **60** | **60** |
| **sim at the NEW pin** | 00 | 00 | 00 | 00 |

The pre-fix simulation's whole 49-byte block is **byte-identical to the
MAME leg holding P1 AND P2 buttons 5+6** and differs from the leg running
the actual script; after the fix it is byte-identical to the no-input leg.
**And the fix's whole footprint at boot is those inputs:** two otherwise
identical `cores/cps2` runs, one per pin, differ in **8 bytes of 65,536**
in every frame of 560-620 — `$FF8058/5A/5C/5E` (0x60 -> 0x00) and
`$FF8060-$FF8063` (0x40 -> 0x00), nothing else.

**C. THE FIX.** Fork commit `519aff8b` (`emu/jtcores-patches/0010-…`, pin
bumped, **NOT PUSHED**), one file, no RTL, no macro, unconditional:
`& ~0xf` instead of `& 0xf0` (keep every button bit the port has, whatever
`JTFRAME_BUTTONS` is) and `0x3ff` instead of `0xff` for the four seeds.
This is a plain upstream bug and the commit message is written as a clean
upstream report; nothing was filed. `tests/test_sim_wram_contract.sh` check
12 holds the PINNED `test.cpp` to it (12a the patch shape, 12b no 8-bit
mask and no 8-bit seed left, 12c the must-fire control on a softened copy).

**D. THE RE-FREEZE — AND NOTHING MOVED, WHICH IS ITSELF THE RESULT.**
Measured on the REFERENCE core (`test_mister_sim_anchor`'s design: the
expectations are the `cps2` numbers and are never re-measured on `cps2w`),
stock `vsavj`, frame output off, and over frames **2100-3000** rather than
the gate's 2400-2800 so the window could not box the answer in:

|  | before (14z-107 (7)) | after the fix |
|---|---|---|
| MAME anchor | 2146 | **2146** |
| sim anchor (absolute) | 2609 | **2609** |
| skew | 463 | **463** |
| band | +/- 30 | **+/- 30, untouched** |

The anchor reads 2609 whether the search starts at 2100 or at 2400. So the
gate is re-frozen at its existing values — **measured for the first time on
inputs that match the MAME leg's.** WHY it did not move, mechanism rather
than luck: a button held from before the game boots produces no PRESS EDGE,
and `05_timeout_idle`'s only inputs are a coin, a start and one button-1
tap. The gate's header carries this as "THE SECOND RE-FREEZE".

**E. WHAT WAS RE-CHECKED, AND BY HOW MUCH IT MOVED.**
- **`tests/audit_sdram_bank_load.sh` — phase boundaries UNCHANGED** because
  they are keyed to the anchor and the anchor did not move: `DL_END` 462,
  `ATTRACT_END` 1265, `SELECT_END` 2608, `MATCH_START` 2614. Re-deriving the
  table from the committed `build/sdram_bank_load_14z107.log` reproduces the
  published figures EXACTLY — attract 38,377 / 3,511 (78.5% row miss) / 0 /
  9,485 (25.3%), select+VS 39,696 / 13,911 (99.0%) / 303 / 12,348 (36.1%),
  in-match 40,976 / 13,926 (98.3%) / 1,096 / 18,438 (28.9%), data bus
  12.8 / 16.5 / 18.5%. **Every figure moved by zero and no conclusion
  changed.** Recorded in the script: that log was produced BEFORE the fix,
  i.e. with the four buttons held — which is why the boundaries were
  re-checked rather than assumed.
- **`tests/test_mister_wide_inert.sh` re-run at the new pin: PASS.**
  `cps2w` == `cps2`, BIT-IDENTICAL work RAM in all 101 frames of 540-640,
  window non-constant, and the one-frame-shift control fired (100
  comparisons differ).
- **`tests/test_jtcores_twin.sh`: PASS** — pin `519aff8b`, the series is 10
  files == 10 commits, `cores/cps1`/`cps2`/`cps15` still BYTE-UNTOUCHED.
- **`tests/test_rpl2siminputs.sh`: PASS**, all four refusals still fire.
- **`tests/test_mister_sim_anchor.sh` end to end on `cps2w`: PASS.** MAME
  dump set complete and anchor 2146; the sim leg reporting HOST FRAME OUTPUT
  DISABLED and producing no `frames/`, both asserted; its dump set complete
  (2400-2800, 64 KB each) and NON-CONSTANT; **sim anchor 2609, skew 463
  (frozen 463 +/- 30)**; every mapped field agreeing at the anchor and at
  +60/+180; P1 record base `$093B6A` on both sides; whole 64 KB at anchor+60
  differing in 1,524 bytes; and all three controls firing (byte-swapped
  dumps rejected, a punched hole rejected before any anchor is computed, no
  `wram/` without the hook macro). Wall 53 min for the sim leg.

**F. THE §4 FIELD VERDICT: UNCHANGED, AND NO FIELD VALUE MOVED.**
With the corrected inputs, MAME and `jtcps2` agree on every compared field
at the anchor and at +60/+180. And the VALUES are the same ones the pre-fix
measurement recorded, field by field: `timer` 0x63, all four HP words
0x0120, both meter pairs 0, `p1_hitbox_base` **$093B6A on both** (Demitri —
so the 3-button confirm the held buttons made at the pick did NOT select a
different variant), `p1_ptr64` $093AAA, `p1_word132` 0x0018,
`p1_x/y` 0x01A8/0x0028, `p1_flip` 1, `p1_attack_id` 0, and even the `phase`
field `p1_anim_ptr` — $12CD4A at the anchor, **$12CDF6 at +60**, which is
the exact value 14z-107 (7) published. Whole 64 KB at anchor+60 differs in
**1,524** of 65,536 bytes (the record's "~1,500").
**The single most sensitive observable is the one that mattered most, and
it did not move either:** the 1P arcade draw is SOUND-STATE-FED
(`atlas/ram.md:99`), the project's own named run-to-run lottery — and it
drew the same pair as before, MAME `$0AE9D4` vs sim `$0A9518`. The
P2-identity fields (`p2_hitbox_base`, `p2_ptr64`, `p2_x`, `p2_y`, and the
`phase` fields `p2_anim_ptr`/`p2_box_ids`) differ for that documented
reason and stay excluded by name; `p2_hp`, `p2_white_hp` and the two p2
meter fields are compared and agree.

**F2. AND THE BEFORE/AFTER WAS MEASURED, NOT INFERRED.** The §4 window was
re-run at the PREVIOUS pin (`7cf1eedb`, buttons held) as well as the new
one — same core `cps2`, same stock `vsavj`, same `sim_inputs.hex` sha1
`931e6caf…`, frames 2400-2800 both. **The pre-fix run's anchor is also
2609**, and across all 401 frames the two runs differ in **29 addresses of
65,536**, every one of them accounted for:

| what | addresses | frames | pre -> post |
|---|---|---|---|
| the raw input mirror + its `$FF806x` derivative | `$FF8058/5A/5C/5E`, `$FF8060-63` | 401/401 | 60 -> 00, 40 -> 00 |
| the per-player struct input words (P1 `+0x394`, P2) | `$FF8794/96`, `$FF8B94/96` | 401/401 | 60 -> 00 |
| the in-match per-player input copies (block `+0x122/124/12A/12C`) | `$FF8522/24/2A/2C`, `$FF8922/24/2A/2C` | ~190/401 (from the match) | 60 -> 00 |
| one-frame companions of the same words | `$FF8526`, `$FF85AC`, `$FF8926`, `$FF89AC` | 1/401 each | — |
| the OBJ-builder secondary stack + the dead-stack window (`atlas/ram.md`, the two documented phase classes) | `$FF06B0/B5/B9`, `$FF7FC4/C8` | 8/5/5 and 1/1 | execution position |

**So the four held buttons were doing exactly one thing: sitting in the
input words.** Not one byte of gameplay state — no HP, no position, no
timer, no meter, no character identity, no anim cursor — differs between
the two pins at the match. That is why the anchor did not move, and it is
the plain answer to "did the corrected inputs change the §4 verdict": no.
(The pre-fix leg is archaeology, run once by hand at a pinned-back scratch
clone; the persistent form of this measurement is the gate itself.)

**G. WHAT DID NOT CHANGE.** `tools/rpl2siminputs.py` still REFUSES `p2=`,
`p1=4/5/6` and `sys=TS` loudly — releasing a button is not scripting it, and
`02_demitri_vs_cpu` / `04_select_fuzz` still do not translate. The pending
item "THE SIM HARNESS'S P2 / 6-BUTTON EXTENSION" is marked: its FIDELITY
half is DONE, its COVERAGE half stays deferred by the maintainer's ruling
("agreed, we can do it later").

**PUSH STATE, MEASURED not assumed (`git ls-remote`, 2026-08-24):
`origin/vampire-saved` is at `7cf1eedb`** — fork commits 1-9 ARE public. The
push landed 2026-08-23 22:36 (`git reflog show origin/vampire-saved`), which
RETRACTS the 14z-107 (7) line "4840df8a, 692ba4d6 and 7cf1eedb are all
local-only; origin/vampire-saved still ends at 38acc638": that was true when
written and is not now. **PUSH PENDING is exactly one commit: `519aff8b`
(commit 10), held local as instructed.**

## Session 14z-107 (7) — THE "VIDEO-SENSITIVE ANCHOR" ROOT-CAUSED: THE
## FORKED FRAME WRITER WAS REWINDING THE SIMULATED CONTROLLER. Not a
## timing mystery, not a dump problem — `exit(0)` in a child `fclose()`s
## the parent's `sim_inputs.hex` and POSIX rewinds the SHARED offset. Fork
## commits `692ba4d6` + `7cf1eedb`, **LOCAL ONLY** (push authorisation
## still held). The lane now runs with host frame output OFF by default and
## asserts its own dump sets.

**The one line:** the picture never touched the CPU — the HOST did, and the
byte that gave it away was `RAM:$FF8060`, the START bitmask.

**A. THE MECHANISM, LINK BY LINK.**
1. `bin/jtsim:460` runs `mkdir -p frames` unconditionally and the `fork()`
   in `test.cpp`'s `video_dump()` is guarded by NO macro — **frame output is
   always on, `-video` is not what enables it** (it only defines
   `DUMP_VIDEO`, which `test.cpp` never reads).
2. The child ended with `exit(0)`. `exit()` runs the C stdio cleanup, which
   flushes and closes every open C stream — and **libc++'s
   `std::basic_filebuf` is a `FILE*` underneath**, so that includes the copy
   the child inherited of the parent's `sim_inputs.hex` `ifstream`.
3. **POSIX makes `fclose()` on a seekable READ stream reposition the
   underlying file description to the stream's logical position** — and that
   description is SHARED with the parent after `fork()`.
4. So the parent's next stdio buffer refill re-read lines it had already
   consumed. **The simulated controller script was being REPLAYED, once per
   fork, at every buffer boundary.**
5. And the number of forks follows the PICTURE. A core rendering the game
   forks hundreds of times; a core rendering black (D1's missing
   `pal_lut.hex`) forks about once. That is the entire "video sensitivity".

**B. THE CONTROL — a 2x2, work RAM compared frame by frame from frame 2000,
`cps2w` + stock `vsavj` + `05_timeout_idle`, everything else pinned
(`.rom` sha1 `f9dc2987…` and `sim_inputs.hex` sha1 `1d6f8418…` identical in
all legs, download 462 frames in all legs).**

| | `pal_lut.hex` present | `pal_lut.hex` absent |
|---|---|---|
| frame output **OFF** | A | B |
| frame output **FORK** | C | D |

- **A vs B: BIT-IDENTICAL, 681 of 681 frames.** With the host doing nothing
  with the pixels, a black-screen core and a working core are the same
  machine — which is what the RTL says they must be.
- **C vs D: 483 of 681 frames DIFFER**, first divergence frame **2051**, ONE
  byte, **`RAM:$FF8060`, 0x41 vs 0x40** — D1's report reproduced exactly.
- **A vs C (same core, ONLY the host's frame output differs): 483 of 681
  differ, same first divergence.** This is the pair that names the culprit:
  the RTL, the ROM and the input file are identical, and the ONLY difference
  is what the host does with the pixels.
- **B vs D: BIT-IDENTICAL, 681 of 681.** ~1 fork, nothing accumulates.
- **C vs a repeat of C: BIT-IDENTICAL.** The corruption is DETERMINISTIC —
  same picture, same fork frames, same rewinds — which is why D1's factorial
  reproduced so cleanly and looked like a property of the design.
- `RAM:$FF8060` is the per-player **START bitmask**
  (`docs/game/atlas/character_tables.md:347`), i.e. an INPUT-derived byte.
  The mechanism signed its own work.

**B2. THE FOUR LEGS, AS NUMBERS.** 681 dumps each, every set asserted
COMPLETE by `tools/check_wram_dumps.py`; `.rom` sha1 `f9dc2987…` and
`sim_inputs.hex` sha1 `1d6f8418…` identical in all four; download 462 frames
in all four; jpgs written: **1,348** (LUT present + fork) vs **1** (LUT
absent + fork) vs 0 / 0 (frame output off).

| leg | jpgs | match-start anchor | vs the clean pair |
|---|---|---|---|
| LUT present, frame output OFF | 0 | **2609** | — |
| LUT absent, frame output OFF | 0 | **2609** | bit-identical, 681/681 |
| LUT absent, frame output FORK | 1 | **2609** | bit-identical, 681/681 |
| LUT present, frame output FORK | **1,348** | **2502** | 483 of 681 differ |

**Only the leg that forks 1,348 times deviates.** MAME's anchor is 2146 in
both this session's measurement and the frozen one, so the clean skew is
**463** — and slice D1's "RED" 2609/463 was the CORRECT reading while the
"green" 2502/356 was the artifact. The gate is re-frozen at 2609/463 with
the band UNCHANGED at +/- 30: the centre moved onto a measurement with a
named mechanism, which is what the standing watch asks for.

**C. GROUND TRUTH, core-free, and now a gate.** A parent reading a 25 KB
file line by line while forking one child per line reads 3,000 lines and
ends at line **3000** when the children call `_exit()` — and ends at line
**278**, with three backward jumps, when they call `exit()`.
`tests/test_sim_wram_contract.sh` 11/11c. Check 10 covers the same cleanup's
other effect: N `exit()`ing children flush N copies of the parent's buffered
`stdout` (3→4, 7→8), which is why a fork-mode jtsim log carried **212**
copies of one `$display` line against **one** with frame output off.

**D. DO THE EARLIER DUMP-BASED NUMBERS STAND? THE DUMPS WERE NEVER AT RISK —
THE INPUTS WERE.** Stated precisely, because the two have very different
consequences:
- **Not a dump problem.** Every `wram/dump_*.bin` is written by the PARENT,
  in `SDRAM::dump_range`, from a local `ofstream` constructed and destroyed
  inside one call at the VS rising edge in `clock()`. No dump descriptor is
  ever open across the `fork()`, so no dump can be interleaved, truncated or
  written by a child. Nothing that was ever reported from a dump file was
  reading a corrupted file.
- **`tests/test_mister_wide_inert.sh` STANDS**, and the argument does not
  depend on how far the rewind had got: it compares `cps2` against `cps2w`
  on the SAME replay, both rendering the SAME picture, so both legs fork at
  the same frames and suffer the IDENTICAL corruption. A cross-core
  comparison is invariant to it by construction — which is not true of the
  anchor gate, whose other leg is MAME. Its verdict was also re-measured
  this session from the other direction: with frame output off, two cps2w
  builds that render completely different pictures are bit-identical over
  681 frames. And it now runs with frame output off by default anyway.
- **The §4 anchor oracle: the FIELD AGREEMENT stands, the FRAME INDEX was
  measured on a run whose input script was being replayed.** MAME 2146 is
  re-measured this session and unchanged, on a dump set now asserted
  complete (301 frames). The FROZEN NUMBER, however, was measured under
  the corruption and is now RETRACTED: **sim 2502 / skew 356 -> sim 2609 /
  skew 463**, re-measured four ways (B2). Slice D1's red anchor was right and
  the green one was the artifact. Every downstream carrier of 2502/356 was
  re-pointed (`mister.md` x3, `mister_map.md`, `cps2_wide.md`, `HANDOFF.md`,
  `NEXT_SESSION.md`, the gate). `tests/audit_sdram_bank_load.sh`'s phase
  boundaries are keyed to that anchor, so they moved too, and the per-bank
  table was RE-DERIVED from the same committed log: every figure shifted by
  well under 1% and no conclusion changed.
- **The per-bank SDRAM traffic profile (14z-107 (3)) stands, and was
  audited rather than assumed.** It is the one instrument that parses a LOG,
  which is exactly what the fork duplicates. `build/sdram_bank_load_14z107.log`
  carries 350 well-formed `SDRAM_STATS_RAW` rows, **zero duplicates**,
  strictly increasing timestamps; re-analysing it reproduces the published
  table. The audit now de-duplicates by `t=` and requires monotonic time
  anyway, and passes `--frame-output off`.

**E. THE HARDENING.**
- **Fork commit `7cf1eedb` — THE ACTUAL REPAIR, and it is one word.** The
  forked child now calls **`_exit(0)`** instead of `exit(0)`: no stdio
  cleanup, so no `fclose()`, so no rewind of the parent's input stream and
  no duplicated log lines. The child's one diagnostic moves to stderr, which
  is unbuffered and therefore survives `_exit`. This is upstream-worthy on
  its own.
- **Fork commit `692ba4d6`** (`emu/jtcores-patches/0008-…`, pin bumped,
  **LOCAL ONLY**), 26 added lines in `test.cpp`, no RTL:
  `JTFRAME_SIM_NOVIDEO` skips the per-frame image writer entirely (no
  `dump.diff()` scan, no `fork()`, no ImageMagick), the children are reaped
  with `waitpid(WNOHANG)`, and the run states its frame-output mode on
  stderr so a gate can assert it. Absent the macro the writer is upstream's
  code byte for byte — the patch DELETES no line, which
  `test_sim_wram_contract` 9b checks.
- **`tools/run_sim_jtcps2.sh --frame-output off|fork|collect`, default
  `off`.** Every state measurement in the lane now runs with the host doing
  nothing at all with the pixels. `--video` is an alias for `collect`.
- **`tools/check_wram_dumps.py`** — the integrity assertion the task asked
  for. `compare_fields.py` GLOBS, so a dump that is never written does not
  fail a comparison, it silently changes WHICH frames the anchor search
  sees. The new tool requires every frame of a range, at an exact length,
  with an exact address in the name (or `--contiguous` for a directory of
  unknown extent), and `run_sim_jtcps2.sh` runs it on every `--wram` run —
  the producer is the only place that knows what SHOULD be there.
- **`tests/test_mister_sim_anchor.sh`** now asserts the frame-output
  configuration it was frozen under (the log banner, plus "no frames/ was
  produced"), runs the integrity check on BOTH legs before computing any
  anchor, and carries a control that a hole punched in a copy of the sim
  dumps is rejected.
- **`tests/test_sim_wram_contract.sh`** gained checks 8 (integrity, six
  cases: hole, truncation, stray frame, wrong address, `--contiguous` and
  its hole), 9 (the lane's frame-output default with a flipped-default
  control, the shape of patch 0008, that the PINNED `test.cpp` has no plain
  `exit(0)` left in a forked child, and a control that a softened copy is
  detected), 10 (the fork-flush ground truth, N→N+1 copies) and 11 (the
  REWIND ground truth, `exit()` vs `_exit()`, with its control).
- **`tests/audit_sdram_bank_load.sh`** is the one instrument that READS a
  log, so it now de-duplicates the reporter's lines by their own `t=`
  timestamp, says so loudly when it has to, and requires the timestamps to
  be strictly increasing. It also passes `--frame-output off` explicitly.
  Re-analysing the committed `build/sdram_bank_load_14z107.log` reproduces
  the published table exactly, and that log carries **zero** duplicated
  stats lines.

**F. AND ONE MORE HARNESS DEFECT, FOUND WHILE AUDITING, RECORDED NOT
FIXED: jtframe v1.7.3's `SimInputs` HOLDS P1 BUTTONS 5 AND 6 DOWN.**
`test.cpp:201` is
`dut.joystick1 = (dut.joystick1&0xf0) | (v&0xf);` and `&0xf0` discards bits
9:8, which the line above had just set to 1. Joystick is ACTIVE LOW and
`jtcps2_main.v:266` wires `joystick1[9:7]` into `in1`, so from the first
line of `sim_inputs.hex` the simulated P1 has buttons 5 and 6 pressed — and
only EOF releases them, so a SHORTER input file changes the inputs. It has
not derailed `05_timeout_idle` (the MAME leg, which does not hold them,
agrees on every mapped field and picks the same P1 record base), but the two
legs of the oracle are not running identical inputs. The one-line fix
(`& ~0xf`) moves the frozen anchor, so it belongs with the already-queued
P2/6-button fork commit — that pending item is upgraded from COVERAGE to
FIDELITY.
**[FIXED 14z-107 (8), fork commit `519aff8b`. Two corrections to this
paragraph, both measured there: P2's buttons 5 and 6 were held too (the
constructor's `joystick1..4 = 0xff` seed, which `parse_inputs()` never
corrects for players 2-4), and the fix did NOT move the frozen anchor —
2146 / 2609 / 463, unchanged, because a button held from before boot
produces no press edge.]**

**G. THE FIX VERIFIED IN THE LANE, not just in a toy.** A fifth run:
`cps2w`, stock `vsavj`, **frame output FORK** (1,349 jpgs written — the
picture is fully rendered), at the pin WITH commit 9's `_exit(0)`.
Result: **anchor 2609** — the clean value — and **BIT-IDENTICAL to the
no-fork leg in all 681 frames**, while differing from the UNFIXED fork leg
in 483 of 681 starting at frame 2051. The log-side effect is gone with it:
**1** copy of the `$display` line where the unfixed run had **1,349**
(= 1,348 children + the parent). So the repair restores the simulation
while leaving the frame writer doing its job.

**G2. AND THE RE-FREEZE IS THE REFERENCE CORE'S NUMBER, not cps2w's.**
`test_mister_sim_anchor`'s design says the expectations are measured on the
REFERENCE core and never re-measured on `cps2w` — reproducing them is the
whole assertion — so a sixth run measured it there: **`cores/cps2`, stock
`vsavj`, frame output OFF: anchor 2609**, dump set complete, and its work
RAM **BIT-IDENTICAL to `cps2w`'s in all 681 frames**. That last number is
the FPGA superset invariant over a window that INCLUDES the match start;
`test_mister_wide_inert`'s own window is 540-640.

**G3. AND THE GATE ITSELF IS GREEN ON THE RE-FROZEN NUMBER.** A clean
`tests/test_mister_sim_anchor.sh` run on `cps2w` (the whole tree frozen for
its duration — see H): MAME dump set complete and anchor **2146**; the sim
leg reporting **HOST FRAME OUTPUT DISABLED** and producing no `frames/` at
all, both asserted; its dump set complete (2400-2800, 64 KB each) and
NON-CONSTANT; **sim anchor 2609, skew 463 (frozen 463 +/- 30)**; MAME and
jtcps2w agreeing on **every mapped §4 field** at the anchor and at +60/+180,
with P1's record base `$093B6A` on both sides; and all three controls
firing — byte-swapped dumps rejected, a punched hole in the dump set
rejected before any anchor is computed, and no `wram/` when the hook macro
is absent. The only disagreement is the documented one, the 1P arcade draw
(`$0AE9D4` vs `$0A9518`), whose fields are excluded by name.

**H. A SELF-INFLICTED LESSON, RECORDED BECAUSE IT COST THREE RUNS.** The
runner's header was rewritten WHILE three 45-minute simulations and the
anchor gate were mid-flight. `sh` reads a script by BYTE OFFSET, so a
comment-only edit is enough: all four died at their next statement with
`syntax error near unexpected token 'else'`. The MEASUREMENTS survived —
the Verilator sims are separate processes and had already written their
dumps into the scratch clone, so each was recovered by copying
`cores/<core>/ver/game/wram` out by hand — but the gate's verdict had to be
discarded and the gate re-run from scratch on a frozen tree.
`docs/project/gotchas.md` + the index.

**PUSH PENDING:** `4840df8a`, `692ba4d6` and `7cf1eedb` are all local-only;
`origin/vampire-saved` still ends at `38acc638`.
**[SUPERSEDED — all three were pushed 2026-08-23 22:36; `origin/vampire-saved`
is at `7cf1eedb`, measured 14z-107 (8) with `git ls-remote`.]**

**HOUSEKEEPING NOTE for the next CLOSE:** STATE.md is ~176 KB, past the
~150 KB the rollover rule names — it was already over before this entry.
Three groups are kept (14z-107, 14z-106, 14z-105), so no rollover is DUE by
the group rule; the size rule says roll the oldest kept group early at the
next close.

## Session 14z-107 (6) — MiSTer SLICE D1 DONE, and it is a GOVERNANCE
## MILESTONE: `cores/cps2w` STOPS BEING cfg-ONLY. The QSound sample-bank
## width fix ships behind a **RUNTIME** profile gate — MRA header byte 41 —
## so stock `vsavj` on our own RBF is a stock machine BY CONSTRUCTION.
## `cores/cps2` and `cores/cps15` BYTE-UNTOUCHED. Fork commit `4840df8a`,
## **LOCAL ONLY** (push authorisation held).

**The one line:** the four-line width fix the docs had promised for three
sessions turned out to be a three-line fix plus a wrong fourth line that
would have stopped the build — and the interesting work was not the fix, it
was making "profile-gated" mean something on an FPGA.

**A. WHAT SHIPPED.** Fork commit `4840df8a` (mirrored as
`emu/jtcores-patches/0007-cps2w-qsound-width-runtime-gate.patch`, pin bumped,
NOT PUSHED). `cores/cps2w/hdl/` now exists, with FOUR files:

| file | why it must differ |
|---|---|
| `jtcps2w_profile.v` (new) | decodes MRA header byte 41 into `wide_en` |
| `jtcps2w_qsnd_bank.v` (new) | the QSound sample-bank latch, gated: `wide_en ? dsp_ab[7:0] : {1'b0, dsp_ab[6:0]}` |
| `jtcps15_sound.v` (**override** of `cores/cps15/hdl`) | `qsnd_addr` 23→24 bits; the latch replaced by the module above; new `wide_en` input. SHARED with cps15 — editing in place would change the reference core |
| `jtcps2_game.v` (**override** of `cores/cps2/hdl`) | 24-bit `qsnd_addr`, the profile instance, `wide_en` routed, PCM slot fed `qsnd_addr[22:0]`. SHARED with cps2 |
| `pal_lut.hex` (copied from `cores/cps2/hdl`) | **added after the anchor went red** — every core instantiating `jtcps1_pal` carries one, and without it the core RENDERS A BLACK SCREEN. See G5 |

plus `cfg/game.yaml` (pulls the four from `cps2w` and DROPS the two shared
originals — jtframe dedups by full path, so both copies would otherwise
compile), the `{ setname="vsavjw", offset=41, data="fe" }` header row, and
`ver/game/` so the simulation lane can run the core.

**B. THE PROFILE GATE — header byte 41, ACTIVE LOW, and the polarity is
FORCED.** `jtcps1_prom_we.v` consumes header bytes 0-7 (region starts), 8-39
(`is_cps`), 40 (`JOY_BYTE`) and 44-63 (the CPS-2 key); **41-43 fall through
every branch and are ignored** — which is what its own `:52-54` comment ("6
are actually used and 10 are reserved") describes. `[header] fill=0xff` means
an unwritten byte is `0xFF`, and the stock `vsavj` MRA from `cps2w` must stay
byte-identical to `cps2`'s, so the ONLY polarity that works is one where the
FILL means profile OFF. (jtframe's own `JOY_BYTE` is the same shape: `0xFF` =
mode 3, games wanting mode 0 write `fc`.) `RawData` embeds `Selectable`, so
the row scores 3 for `vsavjw` and 0 for everything else. **Measured end to
end: the stock `.rom`'s byte 41 is `0xFF`, the WIDE `.rom`'s is `0xFE`**, and
the stock image is still bit-identical (46,407,744 B, sha1 `f9dc2987…`).

**C. THE BANK BIT IS `dsp_ab[7]` — VALIDATED, NOT ASSUMED.**
`jtcps15_sound.v:416-417` carries a commented-out alternative
`{dsp_ab[2:0], dsp_ab[4], dsp_ab[5], dsp_ab[6], dsp_ab[7]}` — a permutation
that also DROPS `ab[3]` — so the original author was unsure. MAME's LLE
QSound device settles it: `dsp_io_map` is
`map(0x0000,0x7fff).mirror(0x8000)`, the bank latch is
`m_rom_bank = (m_rom_bank & 0x8000U) | offset;` (the external-space address
STRAIGHT), and the sample byte is
`read_byte((u32(m_rom_bank) << 16) | m_rom_offset)`. A plain binary bank in
`ab[14:0]`; bit 7 is `ab[7]`. `test_mister_wide_gate` check 4 re-reads those
three lines every run so the evidence cannot rot.
**Recorded, NOT fixed:** MAME models a ONE-READ bank latency that jtcps15
does not. Pre-existing in the reference core, unchanged by a fix that is
bit-for-bit stock when `wide_en` is low, and touching it would alter stock
behaviour — a finding for the audio comparison, not a D1 edit.

**D. THE BRIEF'S FOURTH LINE IS WRONG, AND IT IS A BUILD FAILURE.**
`PCM_AW` 23 → 24 does not compile. `jtframe_romrq_bcache.v:74` is
`sdram_addr = offset + { {SDRAMW-AW{1'b0}}, addr_req>>(DW==8) }`, and
`SDRAMW-AW` is a REPLICATION COUNT: at `AW=24, SDRAMW=23` it is `-1` and
Verilator 5.050 refuses to elaborate (*"Replication value of < 0 or X/Z not
legal"*, exit 1; AW=24 and AW=25 both measured). **So a byte-addressed
jtframe slot reaches 8 MB of a 16 MB bank** — which is precisely why
`mister_map.md` §5 splits QSound across two banks, and the two halves of that
document had been inconsistent since 14z-86. Struck in place in
`cps2_wide.md`, `mister.md`, `mister_fit.md`, `mister_map.md` §7/§10 and
STATE 14z-107 (2)/(4). D1 leaves `PCM_AW` at 23 and feeds the slot
`qsnd_addr[22:0]`; bit 23 is produced, gated and routed by D2.

**E. THE CONTROLS — five, all firing.** The gated latch is ONE expression, so
it is exercised over its WHOLE input space rather than sampled inside a
45-minute core run: `tests/rtl/tb_qsnd_bank.v` drives all 65,536 `dsp_ab`
values in BOTH profile states — **`qsnd_addr[23]` set 16,384 times with
`wide_en` high and ZERO times with it low**, and `[22:16]` equal to the stock
expression throughout. `tests/rtl/tb_profile.v` drives real 64-byte header
streams. Must-fire: (A) the latch with the gate bypassed FAILS the
`wide_en`-low leg; (B) the profile byte moved to 40 — jtframe's `JOY_BYTE`,
the off-by-one that would collide silently — FAILS; (C) the polarity flipped
FAILS on "a 0xFF-filled header turned the profile ON", which is the
superset-invariant failure stated as an assertion; (D) a one-width
perturbation of an override breaks the frozen delta; and control A of
`test_mister_mra_map` doubles as the header row's own control (un-match the
setname and byte 41 returns to the fill).

**F. REACHABILITY, because a gate on unreachable RTL asserts nothing.**
`jtframe files sim cps2w` lists our four files and NEITHER shared original;
`... cps2` lists the originals and none of ours; the two lists differ in
exactly six entries. And the core BUILDS AND RUNS: the whole cps2w core
elaborates under Verilator and simulates.

**G. THE FPGA SUPERSET LEG — IT WENT RED FIRST, AND ROOT-CAUSING IT IS THE
REST OF THE SESSION. IT IS GREEN NOW (G8), AND THE CAUSE WAS NOT THE RTL.** `tests/test_mister_sim_anchor.sh` was pointed at
**`cps2w`** (`SIM_CORE=cps2` re-runs the reference leg), stock `vsavj`,
against the UNCHANGED `cps2` expectations. Result: **sim anchor 2609, skew
463 — OUTSIDE the frozen 356 ± 30. FAIL.** Every mapped §4 field still
agreed at that anchor, P1's record base was identical and the arcade draw
picked the same opponent as the frozen measurement; only the FRAME INDEX
moved, by 107. Per the standing watch: root-cause, do not widen.

**G1. THE CONTROL SAYS IT IS NOT THE ENVIRONMENT.** The same gate, same
fresh scratch clone, same `.rom` (sha1 `f9dc2987…`) and same
`sim_inputs.hex`, with `SIM_CORE=cps2`: **PASS at 2502 / skew 356**, the
frozen numbers exactly. So the fresh clone, the tooling and the MAME leg are
all exonerated and the difference is between the two CORES.

**G2. AND YET THE CORES ARE BIT-IDENTICAL WHERE IT WAS MEASURED.** A direct
A/B — both cores, same stock download, work RAM dumped every frame of
540-640 — is **identical=101 differing=0**. The window is non-constant (all
101 dumps distinct) and consecutive frames differ in 100 of 100 pairs, so
the comparison would catch a one-frame skew. Captured as a gate:
`tests/test_mister_wide_inert.sh` (emulator tier), which is a BETTER
inertness instrument than the anchor — the anchor sits 2,500 frames
downstream of the sound-state-fed arcade draw (`atlas/ram.md:99`), which is
a fine cross-IMPLEMENTATION oracle and a poor inertness test.

**G3. AND THE D1 RTL CANNOT CHANGE THE ADDRESS THE SDRAM SEES, IN EITHER
PROFILE STATE.** `pcm_addr` is fed `qsnd_addr[22:0]` =
`{qsnd_bank[6:0], qsnd_lo}`, and `qsnd_bank[6:0]` is `dsp_ab[6:0]` whether
`wide_en` is set or clear — the gate only decides `bank[7]`, i.e.
`qsnd_addr[23]`, which D1 does not route anywhere. So by construction the
sample-fetch address stream is bit-for-bit the reference core's.

**G4. ROOT-CAUSED, BY A 2x2 FACTORIAL, AND IT IS NOT THE RTL.** Four
50-minute runs, work RAM compared frame by frame:

| RTL in `cores/cps2w/hdl` | `pal_lut.hex` | vs the reference core, frames 2490-2620 |
|---|---|---|
| BYTE-PRISTINE copies | absent | **131 of 131 frames DIFFER** |
| our D1 RTL | absent | **131 of 131 DIFFER — and bit-identical to the pristine variant (0/131)** |
| our D1 RTL | present | **0 of 131 differ — BIT-IDENTICAL to the reference** |

So the RTL axis changes NOTHING and the `pal_lut.hex` axis changes
EVERYTHING. With the file in place, cps2w reproduces the frozen anchor
**2502** exactly. The wide A/B also gave the first divergent frame in the
standard format: **frame 2051, ONE byte, `RAM:$FF8060`, 0x41 vs 0x40**,
cascading to 423 of 1981 frames.

**G5. THE DEFECT: `cores/cps2w/hdl` WAS MISSING `pal_lut.hex`, AND THE CORE
RENDERED A BLACK SCREEN.** `jtcps1_pal.v:62` instantiates
`jtframe_ram #(.SYNFILE("pal_lut.hex"))`; `jtframe_ram` resolves that by BARE
NAME and `jtsim` supplies it by symlinking `$CORES/<core>/hdl/*.hex`, which
is why cps1, cps15 and cps2 each carry their own copy. Missing, `$readmemh`
fails with one `%Warning` among dozens, the LUT reads zero and
`red/green/blue` are pinned to 0. Measured: the reference core rendered 12
changed frames in 640 (frame 465 mean brightness 146), ours rendered exactly
ONE, mean 0. **And `*.hex` is in jtcores' own `.gitignore`, so `git add`
refused it silently** — it is force-added in the amended commit.

**G6. HOW A PALETTE LUT MOVED THE 68k's TIMING — ATTRIBUTED, NOT YET
EXPLAINED, AND RECORDED AS OPEN.** *[RESOLVED 14z-107 (7), marked in place:
the forked child's `exit(0)` `fclose()`d the inherited `FILE*` behind the
parent's `sim_inputs.hex` stream, and POSIX rewinds the SHARED offset — so
the simulated CONTROLLER was replayed once per fork. The attribution below
is correct; the missing link was the file descriptor. And the verdict
inverts: **2609 was the CLEAN anchor and 2502 was the artifact.**]* The LUT feeds only `red/green/blue`
(`jtcps1_pal.v:105-122`) and there is no path back into the CPU, so the
perturbation is not in the design — the factorial says so directly. It is in
the HARNESS: `modules/jtframe/hdl/ver/test.cpp:989-1005` forks a child per
CHANGED frame to run ImageMagick, **with no `wait()`**, so a black-screen
core forks about once where a live one forks hundreds of times, and those
children share the parent's file table. The exact path from that to one byte
at `RAM:$FF8060` on frame 2051 is NOT pinned down. Two consequences are
already actionable and are now written down: **`test_mister_sim_anchor` is a
cross-IMPLEMENTATION oracle, not a clean inertness instrument**, and a red
anchor must be root-caused with a core-vs-core RAM comparison before
anything is blamed on the RTL.

**G7. WHAT THE GATES SAY NOW.** `pal_lut.hex` is in the fork (commit
amended, pin `4840df8a`), `tests/test_mister_wide_gate.sh` gained check
**3g** — every `hdl/*.hex` the reference cores carry must exist in cps2w's,
byte-identical, with its control verified — and `tests/test_jtcores_twin.sh`
2a lists it in the declared set.

**G8. GREEN, ON BOTH INSTRUMENTS.**
`tests/test_mister_sim_anchor.sh` on **cps2w**, stock `vsavj`, against the
UNCHANGED reference-core expectations: **PASS — sim anchor 2502, skew 356**,
every mapped §4 field agreeing at the anchor and at +60/+180, P1's record
base `$093B6A` on both sides, and both controls firing.
`tests/test_mister_wide_inert.sh`: **PASS — cps2w == cps2, BIT-IDENTICAL
work RAM in all 101 frames**, window non-constant, and the one-frame-shift
control differing in 100 of 100 comparisons. The FPGA superset invariant is
measured, not argued.

**H. GATES.** New `tests/test_mister_wide_gate.sh` (ci_portable, 22 s) — the
frozen line-by-line override delta (`tests/expect/cps2w_rtl_delta.txt`), the
profile byte agreeing in all three copies plus the two jtframe facts the
polarity rests on, the widths, the `PCM_AW` refusal, the MAME evidence, the
file-list reachability, **check 3g (the missing-asset rule that would have
caught `pal_lut.hex`, control verified)**, and the two Verilator benches with
four controls. New `tests/test_mister_wide_inert.sh` (emulator, ~22 min) —
cps2 vs cps2w on the same stock download, BIT-IDENTICAL work RAM frame by
frame, with the window's non-constancy asserted first and a control that
re-compares the dumps SHIFTED BY ONE FRAME (which must fail, proving the gate
would see a one-frame skew: measured 100 differing pairs of 100).
**Moved deliberately:** `test_jtcores_twin` check 2a — "game.yaml identical
(no RTL override)" became an ENUMERATED override set plus a frozen game.yaml
delta, with new check 2e (`git diff` proving `cores/cps1`, `cores/cps2`,
`cores/cps15` never moved) and two controls; check 2c gained the header row.
`test_mister_mra_map` gained the profile bit in the MRAs and in both `.rom`s.
`tools/run_sim_jtcps2.sh` now fetches the LOCAL submodule before `origin`
(a fork commit held back from a push exists nowhere else) and rebuilds the
`.rom` when the core changes (a cached one from the other core would hide
exactly the bug this lane exists to catch).

**NOT DONE / STILL OPEN.** No placement change — the QSound SPLIT, the
group-C redirect, `jtframe_ram1_7slots` and the two new GFX slots are D2, as
planned. `qsnd_addr[23]` is produced and gated but not yet routed anywhere.
The MiSTer packaging questions from D0 are still open.
**AND ONE THING IS OPEN THAT WAS NOT OPEN THIS MORNING: the Verilator lane's
match-start anchor is VIDEO-SENSITIVE** (G6). The attribution is solid and
the practical rule is written down, but the path from a black screen to one
byte at `RAM:$FF8060` on frame 2051 is not explained. Worth an hour when the
arc allows, because it bounds how far `test_mister_sim_anchor` can ever be
trusted as an inertness signal — and the honest answer today is "not at all;
that is `test_mister_wide_inert`'s job".
*[CLOSED 14z-107 (7), marked in place: the mechanism is the forked child's
`exit(0)` rewinding the parent's `sim_inputs.hex`; fixed in the fork
(`_exit(0)` + `JTFRAME_SIM_NOVIDEO`, frame output off by default). And the
frozen anchor was WRONG, not the red one: 2609/463 is the clean value.]*
**PUSH PENDING: `4840df8a` is the only fork commit that is not public.** The
brief for this slice held outward pushes until the maintainer re-confirms
authorisation, so the fork's `origin/vampire-saved` still ends at `38acc638`.
Everything in this repo is consistent with the local pin;
`tools/run_sim_jtcps2.sh` was taught to fetch the LOCAL submodule so the
simulation lane works while that is true.

## Session 14z-107 (5) — MiSTer SLICE D0 DONE: the MRA that makes the WIDE
## image DOWNLOADABLE AT ALL. `rom/vsavjw.rom` = **66,265,152 B**, header
## words **6144 / 6400 / 15552 / 64704** — the placement map's numbers, to
## the byte, verified region by region against the romset rather than
## recomputed. Stock leg untouched. **No RTL.**

**The one line:** the trim works, the map survived contact with the real
generator (its "mapped verbatim" table was reproduced too, by the control),
and the ONE thing that turned out wrong was the map's own proposed TOML row
— which fails SILENTLY, so finding it here rather than at a bring-up is the
point of putting D0 first.

**A. WHAT SHIPPED.** Fork commit `38acc638` (pushed,
`DefinitelyFrenchName/jtcores@vampire-saved`; mirrored as
`emu/jtcores-patches/0006-cps2w-wide-mra-trim.patch`, pin bumped):
- `doc/mame.xml` gains a `vsavjw` machine entry — `vsavj`'s VERBATIM except
  the ROM map, the description, and `sourcefile="capcom/cps2w.cpp"`;
- `cores/cps2w/cfg/mame2mra.toml` gains `sourcefile=[ "cps2.cpp",
  "cps2w.cpp" ]`, a `qsoundw` region (`skip=true` generically, a one-part
  `parts=` byte window for `setname="vsavjw"`), and `"qsoundw"` in `order`
  right after `"qsound"`.
```toml
{ name="qsoundw", skip=true },
{ name="qsoundw", width=16, setname="vsavjw", parts=[
    { name="vsw.21m", crc="f6c937e1", map="12", length=0x0F0000, offset=0 },
] },
```

**B. THE MAP'S OWN TOML ROW WAS WRONG, AND WRONG SILENTLY.**
`mister_map.md` §3 proposed one `parts=` row carrying all THREE qsound
members. `parse_parts` puts every part of a region inside **ONE**
`<interleave>` when `width>8` (`corerom.go:462-479`), and `interleave2rom`
resolves each output lane to the FIRST finger claiming it
(`mra2rom.go:238-249`) — so three members all carrying `map="12"` collapse
to `vm3.11m` alone, truncated to the shortest finger. No error. The one
in-tree user of `parts=` (Pang!3) has four DISJOINT maps, which is why the
limitation had never been hit. **The fix is a SEPARATE REGION**, which also
leaves the stock 8 MB on the generic path where it is emitted exactly as
`cores/cps2` emits it. Corrected in place in the map, with the wrong row
kept and labelled so it is not re-proposed.

**C. THE MEASUREMENT.** `.rom` = **66,265,152 B** (63.196 MB), 843,712 B
under the 64 MB `ioctl_addr` ceiling; header words **6144 / 6400 / 15552 /
64704**, all < 65,536; every region start 1 KiB-aligned in `bulk_addr`
terms. Every region compared byte-for-byte against the zips —
key / maincpu 0x600000 / audiocpu 0x40000 / qsound+qsoundw 0x8F0000 /
gfx 0x3000000 / firmware 0x2000 — all equal, **and the trimmed QSound region
is a PURE TRUNCATION of the untrimmed one** (`mister_map.md` open question
**Q2: ANSWERED YES**). QSound live to `0x8E57F0`, placed to `0x8F0000`.

**D. BOTH CONTROLS FIRED, AND CONTROL A CROSS-CHECKED THE MAP.** Undo the
trim (extension back in `qsound`, `vsw.22m` too — exactly
`ROM_START(vsavjw)`): the image is **73,670,720 B and the firmware start is
73,662,464 = 71,936 KiB** — which is `mister_map.md` §3's "mapped verbatim"
table exactly, derived on paper and now reproduced by the real generator.
**And the generator writes the WRAPPED word 6400 and says nothing** — the
same value `qsound` carries. A `.rom` that overflows the header does not
fail to build; it builds wrong. Control B: `length` +0x400 → the frozen
region table fails.

**E. THREE PLATFORM FINDINGS, all in `docs/platform/mister.md` "How the MRA
and the `.rom` are made".**
1. **jtframe locates zip members by CRC32 and by NOTHING ELSE**
   (`mra2rom.go:163-172`). FBNeo and MAME resolve by NAME and only warn,
   which is why our WIDE members carry SENTINEL CRCs in both drivers
   (`dec0de41`, `dec0de3a`, …). On MiSTer a sentinel is `cannot find file …
   in zip` and no `.rom` at all. **So the MiSTer MRA is pinned to the exact
   bytes of one romset build** — a genuine three-way divergence, and the
   reason `tools/gen_vsavjw_xml.py` generates the catalogue entry from the
   zip and a gate fails when it goes stale.
2. **The WIDE set's PARENT is the BUILD's `vsav.zip`, not the pristine
   dump** — `build/m3b_merged13/rompath/vsav.zip` differs in
   `vm3.13m/15m/17m/19m`. Since `jtframe mra` reads a hard-coded
   `$HOME/.mame/roms/<name>.zip` (`mrazip.go:23`), the stock leg and the
   WIDE leg cannot share one `$HOME`; `tools/mister_mra.sh` stages a private
   one per run rather than writing into the user's.
3. **`[parse] sourcefile` is the profile gate.** Tagging the entry
   `capcom/cps2w.cpp` makes it INVISIBLE to `cores/cps2`
   (`sourcefile=["cps2.cpp"]`, regex-matched on the basename), so the
   reference core needed no edit at all. Measured: `jtframe mra cps2` → 316
   MRAs, **none WIDE**; `jtframe mra cps2w` → 8.

**F. THE STOCK LEG IS UNTOUCHED, now as a GATE rather than a 14z-106
measurement:** the `vsavj` MRA from `cps2w` is byte-identical to `cps2`'s
except `<rbf>`, `cps2` emits no WIDE MRA, and the stock `vsavj.rom` built
from the pristine sets is **BIT-IDENTICAL** to the 14z-106 image —
46,407,744 B, sha1 `f9dc29870c871355c5c0fa06c6ad8bea9236ba28`. (Size alone
would not have noticed a remapped region; the gate checks the hash.)

**G. WRITTEN:** `tools/gen_vsavjw_xml.py` (generates/`--check`s the
catalogue entry from a built zip), `tools/mister_mra.sh` (the whole MRA lane
as one idempotent command, private `$HOME`, refuses a `.rom` out-dir inside
the repo), `tests/test_mister_mra_map.sh` (new gate, ci_static, ~15 s, five
generator runs + two must-fire controls), `tests/ci_static.txt`. **Moved
deliberately:** `tests/test_jtcores_twin.sh` check 2c — the declared cfg
delta grew from "the vsav mustbe only" to the D0 set, comments and blanks
filtered and the build CRC normalised away (that CRC is
`test_mister_mra_map`'s job, not the twin's).

**NOT DONE / STILL OPEN.** No RTL — D1 (QSound width) is next and is
unchanged. Two things D0 surfaced that are shipping decisions, not code:
the WIDE MRA lands in `_alternatives/` (the Euro parent is still the "main"
MRA for the core), and a released romset cannot carry both the pristine
`vsav.zip` and the build's under one name — the same overlay question
`run_wide.sh` already answers for FBNeo/MAME, but the MiSTer packaging has
not been designed. Recorded here, not guessed at.

## Session 14z-107 (4) — THE MiSTer SDRAM PLACEMENT MAP: it FITS, by
## **0.708 MB of 64**, but NOT the way the route was framed — "6.39 MB of
## tenant art into bank 1's 7.1 MB spare" is a LIVE-BYTE count against an
## ADDRESS FOOTPRINT of **15.45 MB**; and the WIDE `.rom` mapped verbatim
## does not download AT ALL. Design + measurement only; no RTL

**The one line:** the repack works, but it takes the spare of BOTH banks 0
and 1, it needs the QSound region trimmed at the MRA and SPLIT across two
SDRAM banks, and the thing that decides all of it is that **a CPS-2 tile
code IS its SDRAM address**.

**A. THE PREMISE CORRECTION (`docs/project/mister_map.md` §1).**
`jtcps1_prom_we.v:105`'s CPS-2 GFX scramble, composed with the `.rom`'s 4-way
64-bit interleave, **undoes the interleave**: tile code `c` lands at
`c*128` inside its obj bank, contiguous and monotonic. So the SDRAM cost is
set by the HIGHEST code the roster uses, not by how many it uses. Measured on
`build/m3b_merged13/rompath/vsavjw.zip`: group C obj bank 4 runs to `0xEE73`
(= the top of Donovan's frozen band+shelf) and obj bank 5 to `0xFFDB`
(`patch/effect_c5.*.json`) — **7.452 + 7.995 = 15.45 MB of address space
holding 6.39 MB of art.** It cannot be compacted without renumbering tile
codes, which is game data. **I got the tile↔member mapping wrong on the first
derivation and the project's own blank-tile census caught it**: my mapping
gave 978/722/775/977, `tools/gfx_tiles.py:112 tile_bytes()` gives
**418/2917/51/642** — the exact figures `mister_fit.md` §3 froze. *A derived
address map is worth nothing until it reproduces a number somebody already
measured.*

**B. THE WIDE `.rom` DOES NOT DOWNLOAD AS DECLARED — two independent
overflows**, and neither is about SDRAM. Mapped verbatim the image is
**70.26 MB**: (i) the GAME-side port is `input [25:0] ioctl_addr` = 64 MB
(`modules/jtframe/hdl/inc/jtframe_mem_ports.inc:1` — the MiSTer target
carries 27 bits at `jtframe_emu.sv:334`, the game port is the cap), and
(ii) `qsnd_start` would be 71,936 KiB against a **16-bit** header word. So
the MRA MUST trim, on any SDRAM tier.

**C. THE MRA CAN DO IT WITHOUT TOUCHING THE ROMSET — read from the Go, not
hoped.** `mra2rom.go:177-196` implements a byte window into a zip member
(`offset`/`length`, no alignment constraint), reached from TOML by
`parts=[{name,crc,map,length,offset}]` (`types.go:114-117`,
`corerom.go:462-479`) — already used in-tree to map one file twice at two
offsets (`cores/cps1/cfg/mame2mra.toml:165-173`, Pang!3). Region configs are
`Selectable` by setname (`corerom.go:390-412`), so a `setname="vsavjw"` row
retunes the WIDE mapping and leaves stock `vsavj` byte-identical. **The
maintainer's one-romset ruling is honoured: the change is in the MRA.**
Two traps recorded: `rom_len` must NOT be used to shrink (it advances `pos`
by the full file size, desynchronising every later header word,
`corerom.go:562-577`), and the generator's `pos` counts the 20-byte key while
the RTL's `bulk_addr` does not — **they agree only because every CPS-2 region
start is 1 KiB-aligned.**

**D. THE MAP** (full table, arithmetic and every `file:line` in
`docs/project/mister_map.md` §5). Banks 2+3 keep vanilla's 32 MB
**byte-for-byte, by construction** — `GFX_OFFSET` is left at its `23'h0`
default and `gfx_bank = {1'b1, gfx_addr[23]}`, so the redirect condition
(`gfx_addr[25]`) is 0 across the whole stock region; verified against the
placement code rather than asserted. The other two banks:
- **bank 0** = PRG 6 MB, VRAM/ORAM/WRAM/Z80 windows (0.84 MB), **the QSound
  EXTENSION (DSP sample banks 0x80-0x8F, 1 MB)**, and **group C obj bank 5**
  (7.995 MB) — 16,608,768 of 16,777,216 B;
- **bank 1** = QSound stock 8 MB at offset 0 (byte-identical to stock
  jtcps2) and **group C obj bank 4** (7.452 MB) — 16,202,240 B.
- `.rom` = 63.196 MB; header words 6144 / 6400 / 15552 / 64704, all legal.

**E. THE MOVE THAT MAKES IT FIT, AND WHY THERE IS NO ALTERNATIVE.** With
QSound whole in bank 1, bank 1's spare is 7.06 MB and the SMALLER group-C obj
bank needs 7.452 — **an overflow of 0.39 MB that no rearrangement of PRG,
Z80 or the RAM windows closes, because the deficit is strictly bank 1's and
PCM is the only thing in bank 1.** So the QSound region is split on
`pcm_addr[23]` — which is exactly the stock/WIDE boundary. Cost: bank 0 goes
to **7 slots** and upstream's family stops at `jtframe_ram1_5slots`. Two
ways out, both in Decisions pending.

**F. THE PRG WINDOW, RESOLVED.** `jtcps2_main.v:190` decodes `objcfg_cs`
over the WHOLE `$400000-$4FFFFF` (not 16 bytes) but qualifies it `&& !RnW`,
so **there is no read collision at all**, and `$500000-$5FFFFF` is decoded by
nothing. Minimal proposal: `rom_cs <= (A[23:22]==0) | (CPS2W & RnW &
A[23:21]==3'b010)`, `rom_addr <= A[22:1]`, `SLOT3_AW` 22. The 16-byte
reservation IS enough — and it is now load-bearing in a THIRD implementation.
**Found while reading it:** `jtcps2_main.v:167` gives `A[23:20] < 4'h5` one
wait state, so `$500000-$5FFFFF` would run **zero-wait** while every other
byte of program ROM runs one-wait. Gated fix `4'h6` in the same slice.

**G. QSOUND, ANSWERED.** The power-of-two rule is **FBNeo's**
(`rom_mask = nCpsQSamLen - 1`) and binds the ROMSET, not the placement:
jtcps2 has **no mask anywhere** on the sample path (`grep mask
cores/cps15/hdl/jtcps15_sound.v` = 0 hits; the cap is the `PCM_AW` address
width), so 8.9375 MB is conformant. After the width fix
(`qsnd_addr[23:0]`, latch `dsp_ab[7:0]`, ~~`PCM_AW` 24~~ — **CORRECTED
14z-107 (6): `PCM_AW` 24 does NOT COMPILE; an 8-bit jtframe slot caps at
`SDRAMW`=23=8 MB, `jtframe_romrq_bcache.v:74`**) banks `0x80-0x8E`
are addressable — `qsnd_addr[23]` is precisely the split bit. Banks
`0x90-0xFF` are placed nowhere; recommend masking the high window to 1 MB so
a stray bank aliases inside the extension instead of reading GFX as PCM.

**H. WRITTEN:** `docs/project/mister_map.md` (new — the map, the arithmetic,
the `.rom` layout, the PRG decode proposal, the D0-D4 slice plan with a gate
and a must-fire control each, and eight open questions);
`tests/audit_mister_map_fit.sh` (new gate, ci_static, ~5 s — freezes the four
extents, checks the `.rom` against the 26-bit `ioctl_addr` and the 16-bit
header words, and carries two must-fire controls that both fire);
`tests/ci_static.txt`, `HANDOFF.md` gate table, `docs/README.md`;
retractions marked in place in `docs/project/mister_fit.md` §3/§6,
`docs/project/cps2_wide.md` (three places) and STATE 14z-107 (2).

**THE SLICE PLAN, in one line each** (§10): **D0** the MRA rows alone — the
only slice that can fail for a reason no RTL can fix; **D1** the QSound
width fix, with the aliasing defect reproduced as the must-fire fixture;
**D2** placement (offsets, group-C redirect, QSound split, new slots), gated
by an SDRAM image census whose control is a 1 KiB offset perturbation;
**D3** the obj promote, gated by the MiSTer twin of the FBNeo B4 canary;
**D4** the PRG window, gated by the B4-prg relocate-and-repoint control.
Every slice re-runs `tests/test_mister_sim_anchor.sh` on stock `vsavj`
(2146 / 2502 / 356 ± 30) as the emulator superset leg.

**NOT DONE, deliberately:** no RTL, no MRA row written, no core built. The
brief said design and measure.

## Session 14z-107 (3) — THE SIM LANE'S SDRAM MODEL WAS WRONG AND IS NOW
## RIGHT (it dropped `addr[22]`, not `addr[9]` — the "~3 constants" fix
## would have made a DIFFERENT wrong map), `jtsim -stats` made to work at
## all, and THE BANK-REPACK MEASUREMENT: **GO**, with the headroom bounded
## rather than the design proven

**The one line:** the maintainer ruled "attempt repack (measuring first)";
the measuring is done, the answer is GO — bank 1's PCM stream is already at
a **98.8% row-miss rate**, so it has no locality left to lose, and the
worst-case repacked bank 1 would run at **26.3%** of a single bank's
capacity against the **32.9% that bank 0 already sustains today**.

**DECIDED (maintainer, 2026-08-23), marked in Decisions pending:** the
MiSTer memory-map route is the **BANK REPACK** at our `v1.7.3` pin —
vanilla's 32 MB of GFX stays exactly where it is in banks 2+3, the ~6.4 MB
of tenant art goes into bank 1 alongside the QSound PCM, reached by the
profile-gated promoted tile-code bit; `JTFRAME_SDRAM_XL` (two chips,
128 MB) is the FALLBACK if the repack fails.

**A. THE MODEL FIX (fork commit 3) — AND 14z-107 (2)'s PROPOSED FIX WAS
WRONG, which is the part worth keeping.** That entry recorded "13 row +
9 column = 22 bits" and "~3 constants: `<< 10`, `0x7fffff`, `0x3ff`", i.e.
it assumed the missing bit was `addr[9]`. Derived from the RTL instead
(`jtframe_sdram64_bank.v:75-76,127,219`): at AW=23 the row is `addr[21:9]`
— exactly what `SDRAM_A << 9` already reconstructed — and the column is
`{ addr[22], addr[8:0] }`. **The tenth column bit is the TOP ADDRESS BIT
riding on `sdram_a[9]`; `addr[9]` is a ROW bit.** Widening the column mask
would have folded `addr[22]` onto `addr[9]`. The fix rebuilds bit 22 from
`sdram_a[9]` on READ/WRITE, `#ifdef _JTFRAME_SDRAM_LARGE` (at AW=22 that
pin carries `addr[21]`, already a row bit and a don't-care at COW=9, so
32 MB-module cores are byte-for-byte unaffected), and leaves the burst
column counter 9-bit. **A SIZE tells you how many bits are missing, never
which one.**

**B. BOTH CONTROLS FIRED** (`build/sdram_model_fix_14z107.log`).
- **Must-fire:** same replay, same 620-frame window, before vs after —
  **71-78% of every INKED pixel changed** on frames 466/480/494/508/522/
  524/527, and the SET of rendered frames differs (`test.cpp` writes a jpg
  only when the frame changed). The CPS-2 boot self-test went from garbled
  glyphs to legible `WORK / CPS0 / CPS1 / CPS2 / OBJECT / Q SOUND ... RAM
  OK`. Frame 1 (pre-download black) stayed byte-identical — the run's own
  negative control. Banks 2/3's upper 8 MB measure 87.6% / 90.1% non-zero,
  memory the old model could not address at all.
- **Regression: the oracle is GREEN but the ANCHOR MOVED FIVE FRAMES**,
  2507 -> 2502, skew +361 -> +356. **Reported rather than absorbed**, and
  the mechanism is source-verified: `cores/cps1/hdl/jtcps1_obj_draw.v:137`
  `if( &rom_data ) begin // skip blank pixels` — the object pipeline skips
  its 8-pixel draw loop when the fetched GFX word is all-ones, so **OBJECT
  TIMING IS A FUNCTION OF GFX ROM CONTENT**. With the aliased map the core
  skipped whichever tiles the corruption made blank. Five frames in 2,502
  is 0.2%, it is INSIDE the frozen +/- 30 band (nothing widened — the band
  is unchanged and the centre re-measured), every mapped field agrees
  exactly at the anchor and at +60/+180, and the P1/P2 record bases are
  identical to 14z-107's ($093B6A; $0AE9D4 vs $0A9518). `EXP_SKEW` moved
  to 356 with the pin named. **Carry this into the WIDE arc: tenant art can
  shift core timing by the same route.**
- Bank 0's and bank 1's upper 8 MB measure **0.0% non-zero** — never
  addressed — which is why the work-RAM oracle could not have moved for the
  addressing reason, and is also the empty space the repack wants.

**C. `jtsim -verilator -stats` DID NOT WORK AT ALL, for THREE stacked
reasons**, each hiding the next, all upstream: nothing puts
`hdl/sdram/jtframe_sdram_stats_sim.v` on the compile list although the macro
is defined and the module instantiated; Verilator 5 refuses `#` delays
without `--timing`; and `test.cpp` never advanced
`VerilatedContext::time()`, so `$time` read 0 forever and no delay deadline
was reachable (fork commit 4 — **and the naive form of that fix ABORTS the
run**, because a delay deadline is not on the clock grid, so the step must
land on each pending slot via `eventsPending()`/`nextTimeSlot()`). **A
feature with a flag, a help line and an instantiation is not necessarily a
feature that works.**

**D. THE REPORTER COUNTED THE WRONG THING (fork commit 5).** Its two lines
are truncated deltas and cumulative running percentages, so no log of them
can be differenced per phase — and it counted only ACTIVE commands. Only
bank 0 sets `JTFRAME_BA0_AUTOPRECH`; on banks 1-3
`jtframe_sdram64_bank.v:170` skips both PRECHARGE and ACTIVE on a row hit,
so **ACTIVE is the ROW MISS count and the reporter's "Data ... kiB/s" line
is a row-miss figure wearing bandwidth units.** READ/WRITE are now counted
per bank, so the denominator exists.

**E. THE MEASUREMENT** (`tests/audit_sdram_bank_load.sh`, new manual/
emulator gate; evidence `build/sdram_bank_load_14z107.log`, 2,800 frames of
`05_timeout_idle` on the stock `cps2` core, 63m36s). Per VIDEO FRAME:

| phase | ba0 | ba1 (PCM) | ba2 (obj) | ba3 (obj+scroll) | bus |
|---|---|---|---|---|---|
| attract | 38,278 acc | 3,464 acc / 78.6% miss | 0 | 9,453 acc / 25.2% miss | 12.7% |
| select+VS | 39,635 acc | 13,856 / **99.0%** miss | 261 | 12,079 / 36.8% miss | 16.4% |
| in-match | 40,797 acc | 14,132 / **98.8%** miss | 1,017 / 42.6% | 17,467 / **28.8%** miss | 18.2% |

30.2 MB/s of useful data in-match; **zero** `SDRAM reads clashed` warnings
in 2,800 frames.

**F. THE VERDICT: GO.**
1. A repack moves WHICH bank serves a fetch; it creates none. **Total bus
   load is invariant by construction** — 18.2% before and after.
2. **The row-thrash risk in bank 1 is empirically void: the PCM stream has
   no locality to lose** (98.8% row-miss in-match — QSound round-robins 16
   channels at unrelated addresses).
3. What the repack costs is the OBJECT stream's locality (28.8% miss in
   bank 3 today, degrading toward 100% beside PCM). Priced at STW-HIT = 6
   clocks per lost hit: **4.9% of a frame** even charging ALL of banks 2+3.
4. **Worst case** (both fighters tenants AND all of banks 2+3 redirects,
   scroll included, AND every access a miss): bank 1 = 32,616 accesses/
   frame = 424,008 of 1,609,728 clocks = **26.3%** of the single-bank
   all-miss ceiling (123,825/frame at STW=13 @ 96 MHz). **Existence proof:
   bank 0 already carries 40,797 all-miss accesses/frame = 32.9%, i.e.
   1.25x that, in stock shipping configuration.** Per scanline the worst
   case is 1,618 of 6,144 clocks (26%).
5. **Watch items for the bring-up:** `jtframe_sdram64.v:536-542` with
   `BAPRIO=1` grants strictly ba0 > ba1 > ba2 > ba3, so obj moved into
   bank 1 gains priority OVER the scroll left in bank 3 — a scheduling
   change, not just a placement one; and bank 2 is nearly idle today
   (1.4% share), vsav's obj art sitting overwhelmingly in the
   `rom0_bank[0]=1` half.

**THE ASSUMPTION, STATED PLAINLY.** Only STOCK traffic is measurable — a
WIDE romset does not load on the stock core. **This BOUNDS THE HEADROOM; it
does not prove the repacked design.** Proven: the traffic that would be
relocated, its locality, and that one bank on this core already sustains
more than the relocation's worst case. Not proven: arbitration once bank 1
carries two streams. Structurally reassuring on fetch COUNT: at most two
fighters are on screen either way, so a 21-character roster does not raise
the per-match sprite count, and the promoted tile-code bit adds address
bits, not fetches. What would prove it: this same instrument on a `cps2w`
core carrying the repacked map — i.e. this measurement is the go/no-go the
ruling asked for AND the gate for the repack itself.

**WRITTEN:** `tests/audit_sdram_bank_load.sh` (new gate, manual/emulator
tier, indexed in HANDOFF); `tools/run_sim_jtcps2.sh` `--video` / `--stats`
(plus the `-e`-not-`-d` submodule-gitfile fix); `tests/run_all_static.sh`
learns `run_sim_jtcps2.sh` marks a gate emulator-tier;
`tests/test_mister_sim_anchor.sh` re-frozen at 2502/356 with the mechanism;
fork commits 3/4/5 pushed and mirrored as patches 0003-0005, pin
`74ed17d`; `build/sdram_model_fix_14z107.log` +
`build/sdram_bank_load_14z107.log`; `docs/platform/mister.md`,
`docs/platform/gotchas.md` (+2 entries), `docs/GOTCHAS.md`,
`HANDOFF.md`, `docs/NEXT_SESSION.md`.

**UPSTREAM-WORTHY, DELIBERATELY NOT FILED** (recorded in each fork commit
message): all four defects are jtframe's, not the fork's, and affect every
`JTFRAME_SDRAM_LARGE` core simulated under Verilator.

**NOT DONE:** no RTL, no repack. The ruling was "measure first" and that is
what this is.

## Session 14z-107 (2) — THE MEMORY-MAP TRUTH: at our pin 64 MB is
## PHYSICAL, the 128 MB tier is REAL but UPSTREAM-ONLY and not a flag,
## and the CPS-2 core caps GFX/PRG/scroll/QSound in FORMAT regardless —
## "MiSTer work = width plumbing only" RETRACTED. Docs + STATE only; no
## code, no RTL, no tools touched

**The one line:** the 128 MB tier that the profile ruling assumed was a
flag away does not exist at our pin at all, exists upstream 3057 commits
away as a TWO-CHIP scheme, and would not by itself be enough anyway — so
the roster's route through memory is now its own pending decision, and the
numbers say it may not need 128 MB.

**THE PROFILE RULING IS NOT REOPENED.** WIDE v1 verbatim, one romset across
FBNeo/MAME/MiSTer (maintainer, 2026-08-23) STANDS. What is retracted is the
IMPLEMENTATION ASSUMPTION that travelled with it. Marked in place in the
Decisions entry below.

**A. AT `v1.7.3` THE 64 MB CEILING IS PHYSICAL, not a default.**
- `jtframe_sdram_bank_core.v:32-34` — the tree's own table stops at
  `AW 23 | 8 MBx2 = 16MB | 64 MB`. No row 24.
- `jtframe_sdram64_bank.v:75-76` `localparam ROW=13, COW= AW==22 ? 9 : 10;`
  (a two-arm ternary), `:127` addr_row, `:219` `{..., addr[AW-1], addr[8:0]}`
  — at AW=24 the row would be `addr[22:10]` and the column
  `{addr[23], addr[8:0]}`, so **`addr[9]` is never driven** and every address
  aliases with `addr ^ 0x200`.
- `target/mister/jtframe_emu.sv:101-106` = `SDRAM_A[12:0]`, `SDRAM_BA[1:0]`,
  ONE `SDRAM_nCS`; `sys/sys.tcl` assigns exactly 13 A pins, 2 BA, one nCS
  (`:60-72,73-74,97`). 13 + 10 + 4 banks = 64 MB. Saturated.
- `modules/jtframe/doc/sdram.md` "SDRAM Catalogue" (`:222-233`): every 128 MB
  module is **2 or 4 UNITS**; no single chip above 64 MB.
- **The vendored dual-SDRAM support is UNREACHABLE**: `jtframe_emu.sv`
  declares no `SDRAM2_*` port (grep = 0), and `mister.qsf:51-52` sources
  `sys.tcl` + `sys_analog.tcl`, NOT `sys_dual_sdram.tcl` — which it could not,
  because those two CONFLICT ON PINS: PIN_Y15 `LED_USER`/`SDRAM2_DQ[0]`,
  PIN_AG28 `LED_POWER`/`DQ[4]`, PIN_AH27 `VGA_EN`/`DQ[15]`, PIN_AG25
  `BTN_OSD`/`DQ[13]`. **Consequence: on a DE10-Nano the dual-CHIP path and
  the ANALOG I/O board are mutually exclusive — and the field-test plan is
  Jammix -> CRT, i.e. analog video.** (The two-chips-on-ONE-module scheme
  below does not have this problem; it uses the single socket.)

**B. THE 128 MB TIER IS REAL UPSTREAM — PARTIAL UN-RETRACTION.**
`jotego/jtcores` master:
`modules/jtframe/target/mister/hdl/jtframe_emu.sv:175-181`
`` `ifdef JTFRAME_SDRAM_XL / localparam SDRAMW=24; // 128 MB ``.
**Mechanism = TWO CHIPS on one module, selected by the top address bit, with
chip select carried on nCS POLARITY**: `jtframe_burst_io.v:158`
`{sdram_ncs,...} <= { sel_cmd_r[3] ^ sel_chip_r, sel_cmd_r[2:0] };` (the other
chip sees DESELECT); `jtframe_burst_sdram.v:70-71` `localparam XL = AW == 24;
localparam PAW = XL ? 23 : AW;` (64 MB per chip), `:103` `prog_chip = XL ?
prog_addr[AW-1] : 1'b0`; `jtframe_sdram64_init.v` inits twice; the Verilator
model instantiates a second SDRAM with `invert_ncs`. **INFERRED (no schematic
in-repo): that the physical module inverts chip 1's /CS.** Real consumer:
`cores/cps3/cfg/macros.def:6` sets XL, `cores/cps3/cfg/mem.yaml` places lanes
`at: { chip: 1, bank: 3 }`, CPS-3 README = 128 MB / sfiii3n ~80 MB.
**RETRACTION-OF-A-RETRACTION:** 14z-106 (3) and `cps2_wide.md` recorded "NO XL
SDRAM tier exists (grep, 0 hits) — the cps2_wide.md claim RETRACTED". That is
**TRUE of our pin and FALSE of jtframe**; the original cps2_wide.md claim was
right about the framework and wrong about the version we pinned. Both
documents now carry the version qualifier. A grep proves a fact about the
tree you grepped, and a pin is a tree.

**C. XL IS NOT REACHABLE BY A FLAG, AND THERE IS A SILENT TRAP.** XL logic
lives ONLY in the burst/cache branch: `jtframe_board_sdram.v:158` forks on
`JTFRAME_SDRAM_CACHE` -> `jtframe_burst_sdram` (`:164`, XL-aware) else
`jtframe_sdram64` (`:225`, never taught XL — `.chip()` unconnected). The
validator `src/jtframe/macros/public.go:131-140` rejects XL+LARGE and
XL+`BAx_START` but **nothing requires `JTFRAME_SDRAM_CACHE` alongside XL**.
CPS-2 has no `cfg/mem.yaml` (explicit slot modules), so setting
`JTFRAME_SDRAM_XL` on `cps2w` today would compile, validate and silently
produce the bit-9-aliased map of A. **Filed as a platform gotcha.**

**D. UPSTREAM DISTANCE.** `gh api .../compare/v1.7.3...master` -> **ahead_by
3057**, behind_by 0. **No TAG carries XL**: `v1.7.3` (2024-01-18) is the
newest version tag of the repo's 532, while XL is `5981db26` "feat(jtframe):
add SDRAM XL support" (2026-06-19) + `e555e01a` (validation fix, 2026-06-20)
— adopting it means pinning a BARE MASTER COMMIT. Paths we depend on moved:
`hdl/ver/test.cpp` -> `verilator/test.cpp` (split into sdram.cpp/.h,
cabinet.cpp/.h, ...); `target/mister/jtframe_emu.sv` -> `target/mister/hdl/`;
`bin/jtsim` rewritten (848 -> 658 lines); `cores/cps2/cfg/game.yaml` ->
`files.yaml` (changed schema); `mame2mra.toml` `mraauthor` -> `author`;
**`-inputs` now takes a `.cab` cabinet script — `sim_inputs.hex` is ORPHANED
upstream** — and input bit 1 changed coin2 -> service. So the mister.md
recipe, `rpl2siminputs.py`, `run_sim_jtcps2.sh`, fork commit 2 and both sim
gates are all uprev work. **And upstream never widened CPS-1/2's own
`jtcps1_sdram.v`** — the `[22:0]` literals and `// change this when moving to
8MB+ GFX` are still there on master.

**E. THE CORE-SIDE CAPS THAT SURVIVE ANY SDRAM TIER — this is what kills
"MiSTer work = width plumbing only".**
- **GFX is capped at 32 MB by the OBJECT FORMAT**: 16-bit tile code + a 2-bit
  bank from `table_y[14:13]` (`jtcps2_obj_scan.v:47,152`) = 2^18 codes x
  128 B. Spare bits exist (`table_y[12:10]`, `table_x[12:10]` — positions are
  only 10 bits). **This is the SAME extension WIDE v1 already makes on
  FBNeo** (the ratified 19-bit promote in `Cps2ObjDraw`, rule 1 v2) — on
  MiSTer it is the profile expressed in RTL, not a new invention.
- **The 68k map has no 6 MB ROM window**: `jtcps2_main.v:184`
  `rom_cs <= A[23:22] == 2'b00;` (flat 4 MB), with objcfg at
  `0x400000-0x4FFFFF`, QSound `0x600000`, ORAM `0x700000`, I/O `0x800000`.
  WIDE's `wide_ext` lives at `0x400000+` -> same profile-gated remap the
  emulators got, and **the collision with the objcfg window is a real design
  question for the RTL arc**.
- **Scroll: 8 MB, no bank input anywhere** (`jtcps1_sdram.v:121` `[19:0]`,
  `:209`, `:179` `SCR_OFFSET` at bank-3 offset 0).
- **QSound is exactly as documented**: `jtcps15_sound.v:416`
  `qsnd_addr[22:16] <= dsp_ab[6:0];` discards `dsp_ab[14:7]`. One-bit fix +
  `qsnd_addr[23:0]` + ~~`PCM_AW` 23->24~~. ~~**16 MB of QSound fits bank 1
  on the EXISTING 64 MB tier** (PCM is alone in that 16 MB bank).~~
  **BOTH STRUCK 14z-107 (6), measured:** an 8-bit jtframe slot cannot be
  widened past `SDRAMW`=23 (`{SDRAMW-AW{1'b0}}`,
  `jtframe_romrq_bcache.v:74`, a negative replication that will not
  elaborate), so ONE slot reaches 8 MB of the 16 MB bank. The bank has the
  room; the slot does not. The width fix that DID ship (slice D1, fork
  `4840df8a`) is `qsnd_addr[23:0]` + the 8-bit latch, profile-gated.
- Free resource: both star slots are tied off (`jtcps2_game.v:521-528`), so
  two 22-bit slots of bank 3 are available.

**F. THE FIT THAT CHANGES THE OPTIONS — the roster FITS 64 MB by TOTAL; the
constraint is bank PLACEMENT** (`docs/project/mister_fit.md` section 6).
Bank map (`jtcps1_sdram.v:158-164` offsets in WORDS; slots `:258-282`,
`:332-345`, `:365-381`, `:403-426`): bank 0 = PRG 0-4 MB + VRAM@4 + ORAM@5 +
WRAM@6 + SND@7 = ~8 of 16 MB; bank 1 = PCM ALONE, 8 of 16; banks 2+3 = GFX,
32 of 32. Content (this project's own measurements): PRG live **4.82 MB** +
RAM/VRAM/ORAM/SND windows **4 MB** + QSound **8.9 MB** (8 stock + 0.918 ext)
+ GFX **38.4 MB** (32 stock + 6.39 group C) = **~56.1 MB against a 64 MB
tier**. So: **PRG 6 MB fits bank 0 today** (bank 0 goes to ~10 of 16),
**QSound 16 MB fits bank 1 today**, and **ONLY GFX overflows, by ~6.4 MB**.

**G. A CAVEAT ON OUR OWN SIM LANE (affects trust in a shipped gate).** The
Verilator SDRAM model at our pin is a **32 MB module — 8 MB per bank**, not
the 64 MB tier cps2 declares: `hdl/ver/test.cpp:54-58` sizes the BUFFER from
the macro (`BANK_LEN = 0x100'0000` = 16 MB) but `:605-606`
`ba_addr[cur_ba] = dut.SDRAM_A << 9; // 32MB module` / `&= 0x3fffff` decodes
only 22 bits, with 9-bit column masks at `:609-610` and `:642`/`:646`.
- **The 14z-107 anchor oracle is UNAFFECTED, precisely**: bank 0 holds PRG
  0-4 MB, VRAM@4, ORAM@5, work RAM@6, sound@7 — the whole bank is under the
  8 MB line, and the dumped window is bank 0 byte `0x600000`.
- **What IS affected: GFX.** Banks 2/3 are 16 MB each and HALF-ALIASED, so no
  video/sprite result from this lane is trustworthy for wide GFX, and
  14z-106 slice C's "frames showed sprites" is **weaker evidence than it
  read** — it proves the core runs, not that GFX addressing is faithful.
- ~~Fixing it is ~3 constants (`<< 10`, `0x7fffff`, `0x3ff`)~~ **CORRECTED
  AND FIXED 14z-107 (3): NOT those constants, and they would have made a
  DIFFERENT wrong map.** The dropped bit is `addr[22]`, which
  `jtframe_sdram64_bank.v:219` puts on `sdram_a[9]` as the tenth COLUMN bit;
  `addr[9]` is a ROW bit. Fork commit 3 rebuilds bit 22, LARGE-gated. It was
  a PREREQUISITE to simulating any widened set and is now done — see
  14z-107 (3) at the top of this file.

**WRITTEN:** `docs/platform/mister.md` (five new sections: the v1.7.3 ceiling
incl. the dual-SDRAM/analog pin conflict; the upstream XL tier + its two-chip
mechanism with the INFERRED part flagged; the XL-without-cache trap; the
uprev cost table; the core-side format caps — plus the sim-model caveat next
to the Recipe); `docs/project/mister_fit.md` section 6 (the bank-occupancy
table and the arithmetic, with sections 3 and 5's superseded claims marked in
place); `docs/project/cps2_wide.md` "Known limits" (the retraction-of-a-
retraction with the version qualifier, and the format-vs-tier refinement);
`docs/platform/gotchas.md` + `docs/GOTCHAS.md` (two entries); this entry; the
profile-shape Decisions correction; the new pending decision **THE MiSTer
MEMORY-MAP ROUTE**; `docs/NEXT_SESSION.md`; `HANDOFF.md`.

**CORRECTED IN PASSING (retraction discipline, found while writing):**
`HANDOFF.md`'s gate table and one paragraph of `docs/platform/mister.md` still
carried **"MAME 2146 / sim 2606, skew 460 ± 30"** for
`test_mister_sim_anchor.sh`. The gate froze **2146 / 2507, skew 361 ± 30**
(**RE-MEASURED 14z-107 (3) on the fixed SDRAM model: 2146 / 2502, skew
356 ± 30** — the object pipeline's blank-tile skip reacts to GFX content)
(`tests/test_mister_sim_anchor.sh:73-75`) — +460 is the BOOT offset, not the
match-start anchor, and the 14z-107 entry above has it right. Both fixed in
place.

**TWO SMALL FACT CORRECTIONS to the brief this session recorded** (measured
while writing, both harmless to the conclusions): jtcores has **532 tags**,
not three — the load-bearing fact is that `v1.7.3` is the NEWEST version tag
and predates XL by ~2.4 years; and in `sys_dual_sdram.tcl` the analog-pin
collisions are `SDRAM2_DQ[0]/[4]/[15]/[13]` (lines 4/8/13/15), not
`[0]/[2]/[4]/[15]/[13]` — `DQ[2]` is PIN_AA15, which `sys_analog.tcl` does
not claim. Four conflicting pins, not five.

**NOT DONE, deliberately:** no RTL, no code, no new tools — this was a
recording pass on findings already measured. The Verilator 8 MB-per-bank fix,
the core-side format work, and the route choice are all queued behind the
pending decision.

## Session 14z-107 — THE MiSTer ORACLE IS REAL: stock jtcps2 under
## Verilator and MAME compared at a §4 sync anchor on the same legacy
## replay, on a work-RAM path that had to be BUILT (two 14z-106 claims
## retracted); no RTL touched

**The one line:** the CLAUDE.md §4 dual-emulator protocol now runs on a
THIRD implementation — Jotego's RTL — and it agrees.

**THE TWO RETRACTIONS FIRST** (docs/platform/mister.md "State out", marked
in place; STATE 14z-106 (4) annotated):
- `JTFRAME_SIM_IODUMP` does **not** reach work RAM on CPS-2. It writes over
  the IOCTL READ path, which on cps2 is driven only by the serial EEPROM
  (`cores/cps1/hdl/jtcps1_sdram.v:462-478`; cps2 has no `cfg/mem.yaml`), and
  `JTFRAME_IOCTL_RD=128` is the 64 EEPROM words — `dump.bin` is a 128-byte
  NVRAM image.
- `JTFRAME_SAVESDRAM` exists **only** in the Verilog SDRAM model
  (`modules/jtframe/hdl/ver/mt48lc16m16a2.v:193-209`). The Verilator harness
  never references it: there the C++ `SDRAM` class IS the SDRAM and its
  `dump()` fires once, right after a full ROM download.
So "the per-frame 68k work-RAM window the MAME oracle checksums is
reachable" was false in both halves. It had to be built.

**FORK COMMIT 2 — `JTFRAME_SIM_WRAMDUMP`** (`553dd56`, pushed;
`emu/jtcores` pin bumped `b9d0565` → `553dd56`). 64 added lines in
`modules/jtframe/hdl/ver/test.cpp` — the Verilator TESTBENCH, not RTL and
not a core file — adding `SDRAM::dump_range()` and one call at the VS
rising edge next to the IODUMP hook. Writes `wram/dump_<frame>_<addr6>.bin`
with the same `j^1` swap `SDRAM::dump()` applies, i.e. **68k big-endian**,
i.e. exactly the glob `tools/compare_fields.py` already consumes. **Inert
unless `_JTFRAME_SIM_WRAMDUMP` is defined** (the emulator-superset shape in
its simulation edition), and the block to dump is fully macro-parameterised
(`_BANK/_OFF/_LEN/_ADDR/_END`) so jtframe stays core-agnostic and the CPS-2
numbers live in `tools/run_sim_jtcps2.sh`.
- Work RAM's address, read from the RTL: `jtcps1_sdram.v:158-164`
  `WRAM_OFFSET = 23'h30_0000` **words** and `jtcps2_main.v:127,185`
  `addr = ram_cs ? {2'b0,A[15:1]}` → **`RAM:$FF0000-$FFFFFF` = bank 0 byte
  `0x600000`, 64 KB**.
- `tools/setup_jtcores.sh` and `tests/test_jtcores_twin.sh` now mirror the
  fork as a **patch SERIES** (one file per commit, names declared once in
  `PATCH_NAMES`, the gate checking each against `format-patch -1`, the
  series length against the commit count, and the directory contents against
  the declared list). `0001-cps2w-scaffold.patch` came out **byte-identical**
  through the new path. Gate PASS 10/10.

**THE `-setname` QUESTION, ANSWERED — AND THE TRAP UNDERNEATH IT.**
`-setname` IS the re-download (`jtsim:503-506` compares a RELATIVE `readlink
rom.bin`, made with `ln -srf`, against an ABSOLUTE `$ROMFILE`, so the test is
true on every run; it re-links and calls `enable_load()`, which defines
`LOADROM` **and moves `sdram_bank?.bin` into `sdram.old/`**). But the obvious
follow-on — drop `-load` too and preload the banks — **is wrong on CPS-2, and
it cost a 1,841-frame run to find out.** The transfer also latches the
DECRYPTION KEY into core registers (`jtcps1_prom_we` → `cps2_key_we` →
`jtcps2_keyload`); no SDRAM image restores that, so a preloaded run boots into
ciphertext. Measured: **68k work RAM ALL ZEROS at every one of 1,841
frames**. The plan's premise ("drop both") is RETRACTED; 14z-106's own note
("CPS-2 DOES transform — the encryption key load — so use `-load`") was right.
So the recipe is **`-load`, no `-setname`**, ~462 simulated download frames
(~7-11 min) on every run, and the bank dumps are useless on this core.

**THE NEAR-MISS, RECORDED AS A GOTCHA:** those all-zero dumps agreed with
MAME's work RAM on **99.2% of sampled bytes** — because most of a 64 KB
work-RAM image is zero. That number was the first "byte-order proof" I wrote
down, and it was worthless. **The first check on any new dump path is that it
is NON-CONSTANT** (two frames of one run must differ), before any agreement
number means anything. `tests/test_mister_sim_anchor.sh` now asserts exactly
that, before it compares anything.

**WHERE WORK RAM ACTUALLY IS, CONFIRMED AGAINST THE RUNNING CORE** (not just
read off the RTL): the whole 16 MB of bank 0 was dumped at a boot frame and
diffed against the post-download image — the only regions the 68k had touched
were `0x400000-0x42FFFF` (VRAM/ORAM) and **exactly 297 bytes at `0x600000`**,
the same 297 bytes MAME's `$FF0000-$FFFFFF` carries at the same point of the
boot memory test.

**BYTE ORDER, PROVEN ON LIVE DATA:** the sim's work RAM at game frames
74/76/78 differs from MAME's at frames 76/78/80 in **1-2 bytes of 65,536**;
the byte-SWAPPED comparison differs in **416**.

**THE BOOT SKEW, MEASURED AT THE RAM-TEST ONSET:** MAME first writes work RAM
at frame 73, the core at GAME frame 71 — so **simulated ABSOLUTE frame = MAME
frame + 460** (462 download frames minus a 2-frame lead).

**AND THE DOWNLOAD BURNS INPUT LINES.** `sim_inputs.next()` fires on every
LVBL fall from t=0, download frames included, while the core is held in reset
— so the `.rpl` must be shifted by the download length
(`rpl2siminputs.py --offset 462`, which is what that flag was added for and
what `run_sim_jtcps2.sh` defaults to). Everything else (`--wram`, dump names,
anchors) uses the ABSOLUTE frame counter, so a MAME frame `f` sits near
simulated frame `f + 462`.

**`tools/run_sim_jtcps2.sh`** — the whole lane as one idempotent command
(scratch clone at the pin, `~/.mame/roms` symlinks, jtframe env + Go build,
MRA/.rom, `rom.bin`/`core.mod` by hand instead of `-setname`, `.rpl`
translation with the download offset, the run, collection). `--frames` and
`--wram` are ABSOLUTE (download included); `--no-load` and
`--region BANK OFF LEN ADDR` exist for diagnostics. Prints the sha1 of
everything it reads; **REFUSES an out-dir inside the repo (rule 7) and a
scratch clone inside it**.

**THE MEASUREMENT (stock `cps2` core, stock `vsavj`, `05_timeout_idle`):**
| | MAME | jtcps2 (Verilator) |
|---|---|---|
| round-1 match-start anchor | frame **2146** | frame **2507** (absolute) |
| skew (sim − MAME) | — | **+361** |

**RE-MEASURED 14z-107 (3): sim 2502, skew +356** on the fixed Verilator
SDRAM model — `jtcps1_obj_draw.v:137` skips a tile whose fetched GFX word is
all-ones, so object timing is a function of GFX ROM CONTENT and the corrupt
map was skipping the wrong tiles. Band unchanged at ± 30.
- **THE SKEW IS NOT THE BOOT OFFSET.** At the RAM-test onset the two are
  **+460** apart; by the match start they are **+361** — the
  attract/select/VS path costs ~99 fewer frames on the core. That is §4's
  own rationale, measured on a third implementation.
- **EVERY COMPARED FIELD AGREES** at the anchor and at +60/+180 (and at
  +33/+240, checked): `timer` 0x63, both HP 0x120, both white HP, both meter
  fields, **`p1_hitbox_base` $093B6A on BOTH** (Demitri — P1's pick matches),
  `p1_ptr64`, `p1/p2_word132`, `p1_x/y/flip/attack_id`, and even the `phase`
  field `p1_anim_ptr` ($12CDF6 on both). 0 disagreements.
- **THE ONE DISAGREEMENT IS THE GAME'S OWN LOTTERY, NOT A DEFECT.** The CPU
  opponent differs: MAME drew record base **$0AE9D4**, jtcps2 **$0A9518**.
  `05_timeout_idle` is a 1P ARCADE match and the ladder's in-use mask
  `RAM:$FF8110.l` is SOUND-STATE-FED (`atlas/ram.md:99` — the run-to-run draw
  that cost GitHub #110 two frozen audits in 14z-103), so the opponent is
  implementation-dependent by construction. Every field that is a function of
  WHICH character P2 is (`p2_hitbox_base`, `p2_ptr64`, `p2_word132`,
  `p2_x/y`, `p2_attack_id`, `p2_flip`) is excluded BY NAME in the gate, with
  the mechanism in its header; `p2_hp`, `p2_white_hp` and the p2 meter fields
  stay compared and agree. **Pinning the opponent needs a 2P replay → P2 in
  `SimInputs` → the queued fork commit, which now has a concrete motivation.**
- Informational (never a verdict — §4 says whole-RAM equality across
  codebases is unachievable): the full 64 KB at anchor+60 differs in **1,511
  of 65,536** bytes, nearly all of it the other opponent's state
  (`$FF41xx-$FF44xx` 491 bytes, `$FF57xx-$FF58xx` 96).

**GATES**
- `tests/test_sim_wram_contract.sh` (**ci_portable**, ROM-free, ~1 s): dump
  naming, the 68k byte-order contract, anchor-mode skew absorption, TWO
  must-fire controls (a byte-swapped side must be rejected; a perturbed
  non-predicate field must be reported), the two rule-7 refusals, a static
  proof that every code line the harness patch adds sits inside the
  `#ifdef` — with its OWN control (a hoisted line must be rejected) — and an
  RTL cross-check of the CPS-2 constants against the pinned submodule.
- `tests/test_mister_sim_anchor.sh` (**emulator tier, ~55 min**, indexed in
  HANDOFF): the live oracle above with the anchors (2146/2507) and the skew
  band (361 ± 30) frozen and the P2-identity exclusion named, and THREE
  controls — the dumped window must be **NON-CONSTANT** before anything is
  compared (the near-miss, made into a gate), a byte-swapped sim side must be
  rejected, and a run WITHOUT `--wram` must produce no `wram/` at all.
  **RUN END TO END: PASS** (2026-08-23 02:24-03:17, sim wall 52'05";
  `build/mister_sim_anchor_14z107.log`). The gate ran TWICE with a one-line
  fix between (the inertness control had called the runner without
  `--no-load`, so the tool rightly refused "--frames 5 is inside the
  462-frame download"); **both runs produced the SAME sim anchor 2507 and the
  SAME skew 361** — the lane is deterministic run to run.

**TIMES on this machine** (Apple Silicon, Verilator 5.050): the ROM download
is **462 simulated frames on EVERY run** (~7-8 min); incremental rebuild after
a `test.cpp` edit or a macro change **~4 s** (only `test.cpp` includes
`defmacros.h` — the model is not re-verilated, so a new dump window is cheap);
simulation **~0.98 s per frame** (540 frames incl. download in 8'50"; the
2,800-frame gate run is ~47 min). A 12,120-frame replay is ~3.4 h.

**A GOTCHA PAID FOR IN 55 MINUTES:** editing a shell script WHILE it runs
corrupts the running execution — `sh` keeps a byte offset into the file, so a
COMMENT-ONLY rewrite of `run_sim_jtcps2.sh`'s header turned the first gate run
into `syntax error near unexpected token '('` **after** its 2,880-frame
simulation had finished. `sh -n` passes throughout; the corruption lives only
in the running process. Recovered only because collection is the last step, so
the dumps were still in the scratch clone. Filed in platform gotchas.

**NOT DONE, and why**
- Phase B (the full 12,120-frame run with windows at the round-1 timeout and
  the fade, for the round-transition anchor §4 also names) — ~3.5 h; phase A
  had to agree first and it only just did.
- P2 / buttons 5-6 in `SimInputs` (would un-refuse `02_demitri_vs_cpu` and
  `04_select_fuzz`) — recommended as its own fork commit later; this session
  was about the oracle, not input coverage.
- The MiSTer PROFILE SHAPE ruling is still **pending** (recommendation
  unchanged: WIDE v1 verbatim on a 128 MB tier). No RTL was touched.

## Session 14z-106 CLOSE — ritual complete

The session, in one line: housekeeping executed (evidence committed,
probes attic'd, the 14z-102 attic deleted); the MiSTer framing and all
five alignment questions ruled and recorded; the arc OPENED with no RTL
touched — GPL-3.0 licence, the public jtcores fork with the separate
`jtcps2w` core pinned and gated (twin proof: the vsavj MRA identical to
stock except `<rbf>`), the fit numbers measured (a wider GFX tier is
unavoidable: 6.39 MB of roster art vs 0.49 MB blank in vanilla; no XL
tier exists — retracted), and the Verilator lane proven on macOS at
~1.4 s/frame with the `.rpl` translator gated.

Ritual: STATE (this + entries (2)-(4)); NEXT_SESSION rewritten (banner
carries the whole arc state + the opener); HANDOFF MiSTer block + docs
index; GOTCHAS: none paid beyond what mister.md's recipe records
(four failed sim attempts, each a missing GNU tool or module — recorded
there rather than as a gotcha because the recipe IS the fix); suite
`run_all_static --strict` PASS 100/0/0 at the slice-A commit (the
translator gate registered after that run; it passes alone — counts
next run, 101). Four commits LOCAL (b4a7d15, 1622522, 0d16a0b, ad25cdc);
PUSH pending the maintainer's word.

**Decisions pending for the maintainer:** THE MiSTer PROFILE SHAPE
(recommendation: WIDE v1 verbatim on a 128 MB tier). Next opener: the
RAM comparison at a §4 anchor on the STOCK core (mister.md recipe; the
`-setname`/sdram-reuse question first). Model note (maintainer asked):
the opener is mechanical — any current model; the RTL width surgery
waits on the ruling anyway.

## Session 14z-106 (4) — SLICE C: THE SIMULATION LANE WORKS ON macOS
## (stock jtcps2 running vsavj under Verilator, frames rendered, ~1.4 s
## per frame); the translator + its gate landed; the oracle COMPARISON
## itself is the next session's opener

- **Recipe proven** (`docs/platform/mister.md` "Recipe"): brew go coreutils
  gnu-sed xmlstarlet verilator imagemagick; modules fx68k/jt12/jt51/
  jteeprom/jtdsp16 (setup_jtcores.sh now inits all five); `~/.mame/roms`
  symlinks to `$ROMDIR` (outside the tree); `jtframe mra cps2w` builds
  `rom/vsavj.rom` (scratch only); `jtsim -verilator -sysname cps2 -setname
  vsavj -load -video N` from `cores/cps2/ver/game` IN A SCRATCH CLONE
  (never inside `emu/jtcores` — jtsim litters the core dir). Four
  attempts to get there, each a missing GNU tool or module, all recorded.
- **Measured:** Verilator builds the core; the ROM download takes 462
  simulated frames (10'43" wall, once — dumps `sdram_bank0-3.bin`); a
  492-frame run = 11'20" → **~1.4 s/frame**; `frame_00480.jpg` shows
  sprites — vsavj runs. The harness prints `ERROR: SDRAM rd/wr inputs
  should be zero during initialization` every run and continues (upstream
  behaviour; noted, not chased).
- **`tools/rpl2siminputs.py` + `tests/test_rpl2siminputs.sh`** (ci_
  portable): `.rpl` → jtframe v1.7.3 `sim_inputs.hex` (one hex word per
  frame, applied entering blanking; P1 + 3 usable buttons — button 4
  doubles as dip_test; NO P2). Refuses what the harness cannot express,
  loudly. Of the legacy replays, `01_attract_long` and `05_timeout_idle`
  translate; `04_select_fuzz` / `02_demitri_vs_cpu` refuse on button 4.
  Extending `test.cpp` (P2, 6 buttons) is fork work when needed.
- **NOT DONE — the comparison:** running a translated replay to a §4 sync
  anchor with `JTFRAME_SIM_IODUMP`, extracting the 68k work-RAM window
  and comparing against the MAME expectation. Hours of simulation; it is
  the next opener, with the `-setname`/reload question first.
  **CORRECTED 14z-107 (in place, entry not rewritten): `JTFRAME_SIM_IODUMP`
  does NOT reach work RAM on CPS-2 — it dumps the 128-byte EEPROM. The
  comparison needed a new harness hook (`JTFRAME_SIM_WRAMDUMP`, fork
  commit 2). Both the `-setname` question and the comparison are ANSWERED
  in the 14z-107 entry; `docs/platform/mister.md` carries the retraction.**

## Session 14z-106 (3) — THE MiSTer ARC OPENED: slice A (fork scaffold +
## licence) DONE and gated; the twin proof measured; no RTL touched

**Slice A, executed (maintainer rulings 2026-08-22: 128 MB SDRAM; GPL-3.0
for everything; fork under their GitHub; core name `jtcps2w`):**
- `LICENSE` (GPL-3.0, FSF text) + README "Licence"; the pending decision
  marked DECIDED.
- **The fork:** https://github.com/DefinitelyFrenchName/jtcores (public,
  GPL-3.0), branch `vampire-saved` from upstream tag `v1.7.3` =
  `63688ce5`; one commit `b9d0565` = `cores/cps2w/` — `cfg/` a twin of
  `cores/cps2/cfg` with `CORENAME=JTCPS2W`, `game.yaml` VERBATIM (every
  `from: cps2` still resolves to cps2's hdl — the cps15 precedent), the
  MRA set restricted by `mustbe.machines=["vsav"]`, msg + README.
- **Pinned here:** submodule `emu/jtcores` (branch `vampire-saved`, 235 MB;
  jtdsp16 `87fef51d` inited; `modules/jtframe/target/pocket` is a PRIVATE
  ssh submodule — never init it); `tools/setup_jtcores.sh` (literal pin +
  pristine check + jtdsp16 init + Go build + regenerates the mirror
  `emu/jtcores-patches/0001-cps2w-scaffold.patch` = `format-patch
  v1.7.3..pin`); gate `tests/test_jtcores_twin.sh` (ci_portable: pin,
  game.yaml identical, macros/toml deltas EXACT, patch mirror == format-
  patch, must-fire control) PASS 7/7.
- **THE TWIN PROOF (measured):** jtframe's Go tool built (`go build`;
  the bash wrapper needs GNU coreutils — call the binary; env JTROOT/
  JTFRAME/JTBIN/CORES/ROM). `jtframe mra cps2` → 316 MRAs; `jtframe mra
  cps2w` → 7 (the vsav family only). The `vsavj` MRA from the two cores
  is byte-identical except `<rbf>jtcps2</rbf>` → `<rbf>jtcps2w</rbf>` —
  the reference-leg MRA exists and binds stock vsavj to OUR rbf, which is
  the stock leg of the emulator superset invariant on FPGA.
- **Facts read from the tree** (`docs/platform/mister.md`, new; indexed in
  docs/README.md): jtframe is VENDORED at v1.7.3 (not a submodule); the
  RBF name is `"jt"+<core dir>`; `JTFRAME_SDRAM_LARGE` = `SDRAMW=23` (64 MB)
  and **there is NO XL tier** (RTL grep, 0 hits — the cps2_wide.md claim
  RETRACTED in place)
  **[CORRECTED 14z-107 (2), in place, entry not rewritten: TRUE OF THE PIN,
  and 64 MB there is PHYSICAL — but FALSE as a claim about jtframe.
  Upstream master carries `JTFRAME_SDRAM_XL` / `SDRAMW=24` (two chips on one
  module, nCS polarity), so the cps2_wide.md claim is PARTIALLY
  UN-RETRACTED with a version qualifier. See 14z-107 (2).]**;
  MiSTer's HPS exposes `ioctl_addr[26:0]` (128 MB)
  while the core-facing port is `[25:0]`; 68k ROM bus `[20:0]` = 4 MB;
  stock vsav already uses the full 32 MB GFX on jtcps2; the sim lane has
  per-frame `.cab` input scripts + IOCTL/SDRAM dumps (the `.rpl`/RAM-
  checksum twin) and jtcores' own `reg.yaml` regression lists `vsav`.
- Go installed (`brew install go`, 1.27). Static suite re-run at close.

**SLICE B EXECUTED — `docs/project/mister_fit.md`, the numbers:**
- PRG: live extension `0x400010-0x4D10F3` (+ the 30-byte facing-alias
  thunk PINNED at `0x5FFF00`, which is why `vsw.44` is written while
  `vsw.43` is empty) → the image needs **4.82 MB**, deficit vs jtcps2's
  4 MB bus **836 KB**.
- QSound: extension content 918 KB = banks **0x80-0x8E**, all in the
  jtcps15 aliasing class → the width fix is REQUIRED, not optional.
- GFX — **THE DECISIVE NUMBER:** the roster's group C is **52,347 live
  codes = 6.39 MB** (bank 4 45,737 + bank 5 6,610, `audit_gfx_merged_
  census` PASS); vanilla's entire 32 MB holds **4,028 blank tiles =
  0.49 MB** (per-bank census via `gfx_tiles.BLANK`; bank 1's 2,917
  reproduces the 14z-62e figure). 13x short — and no tenant-dropping
  variant fits either (the smallest band alone is 3.5x the blank total).
  **A MiSTer build of this roster REQUIRES a GFX tier wider than 32 MB.**
- Recommendation (Decisions pending below): **WIDE v1 VERBATIM on MiSTer**
  on the 128 MB module — the MiSTer work becomes pure WIDTH (SDRAMW
  23→24 + bank/prog/ioctl +1 bit + the core's buses), no content
  re-layout, one romset for all three implementations, zero gameplay
  consequence.

Instruments the exploration located, for the record: `tests/audit_gfx_merged_
census.sh` (as-built bank4 45,737 / bank5 6,610 of 65,536; all four pools
empty), `build/m3b_merged13/gen.log` (wide_ext high-water `0x4D1100`,
1.24 MB spare — but `vsw.44` is WRITTEN while `vsw.43` is empty, so the
extent is NOT the cursor; measure before quoting 5 MB), `tools/obj_
records.py` / `build/manifest/gfx_layout3.toml` for the static bands.

## Session 14z-106 — HOUSEKEEPING (maintainer-ruled), then the MiSTer
## alignment brief (no core work until the questions below are answered)

**Housekeeping, each item ruled by the maintainer 2026-08-22:**
- The 14z-105 verification evidence committed: 15 `build/*_w6*.log` +
  `merged13_gates*.log` (suite x3, static x3, battery, soak, m3a,
  propose, freeze builds) and `build/guard_corpus/m3b_merged13.
  1787401830.tsv` (the 316/316 soak) — precedent: freeze-evidence logs
  and the merged11/12 guard TSVs are tracked.
- The rehearsal probes `build/merged_probe_w6` (155 MB) +
  `build/probe_stock_w6` (71 MB) moved to **`../build_attic_14z105`**
  (reversible; 0 tracked files inside; every reference is prose and now
  annotated — HANDOFF x2, patch_notes, test_m3a_reproducible's comment).
- **`../build_attic_14z102` (8.1 GB) DELETED** — the 14z-102 policy
  condition ("after the next playtest cycle confirms nothing is missed")
  was met twice (14z-103, 14z-105). Recoverable via git history + tags.
- `emu/fbneo` "modified content" is NOT litter: `git apply --check -R`
  reverses both `emu/fbneo-patches/0001` and `0002` cleanly, so the
  submodule carries exactly the applied harness + WIDE patches.
- One-back dirs (don_m10 / hui46 / pyron30 / m3b_merged12 / m5_stock5)
  stay — the N-2 policy fires at the NEXT freeze.
- Tracker check: every ticket the NEXT_SESSION history tail still lists
  as open backlog (#10/#18/#19/#20/#22/#25/#28/#31/#38/#42/#77/#93/#94/
  #100) is CLOSED on GitHub; `gh issue list` is empty. Nothing queued.
- Verification: ROM audit 76/76 clean; `run_all_static --strict` on the
  pruned tree **PASS 99 / SKIP 0 / FAIL 0** (strict makes a lost input
  fatal — nothing depended on either attic). Log: `build/static_14z106.log`.

**DECIDED (maintainer, 2026-08-22): THE MiSTer FRAMING.** The MiSTer
deliverable is an **EXTENSION OF JOTEGO'S jtcps CORE** — not an FPGA
re-implementation of the MAME emulation. This agrees with and sharpens
the 2026-08-15 ruling (STATE_HISTORY "MiSTer = CORE SURGERY ONLY": PRG-cap
lift + the QSound width fix + a MiSTer-shaped WIDE profile, GFX <= 32 MB).
The alignment questions are under "Decisions pending — MiSTer alignment";
no RTL is touched before they are answered.

## Session 14z-105 CLOSE (final) — ritual complete

The session, in one line: the maintainer-directed window executed end to
end — the Oboro select hook (vanilla's Gallon-variant idiom one cell
over; the Start bit measured before authoring) and the "M6" version mark
(authored glyphs, pixel-exact; the tile codec's 14-session half-mirror
found and fixed on the way) — frozen as donovan-m11 / huitzil-m20 /
pyron-m14 / merged-m6 with every gate and both soaks green, field-
confirmed ("Tests confirm Oboro Bishamon and the M6 mark") and pushed;
then RELEASE PACKAGING landed the same session (`release/merged-m6/`, no
ROM bytes, deterministic, verifying applier, gated), ruled in-tree until
MiSTer, pushed.

The ritual's items, each done this close:
- **STATE**: this entry; the ROLLOVER executed (the 14z-102 group, 7
  entries, moved verbatim to STATE_HISTORY with a ledger line; verified
  lossless by byte-verbatim + size accounting).
- **NEXT_SESSION**: rewritten (the window shipped, the codec finding, the
  dead prediction, packaging done + the in-tree ruling; MiSTer next).
- **HANDOFF**: current-builds block, registry row, gate rows, the release
  packaging section, SUITE_ONLY.
- **GOTCHAS**: one paid (platform: the gfx_tiles half-mirror / pen 15 /
  OBJ->screen offsets).
- **patch docs**: patch_notes 14z-105 section; patch_index rows + the
  packaging tooling paragraph.
- **Issues**: none opened; tracker clean.
- **Suite**: run_all_static --strict PASS 99/0/0 at close (97 -> 99:
  test_gfx_tile_codec, test_release_roundtrip).
- Everything pushed; the tree is clean.

Where the next session starts: NEXT_SESSION's banner — MiSTer core
surgery (the maintainer's sequencing: packaging first, done).

## Session 14z-105 (2) — RELEASE PACKAGING (maintainer: packaging
## before MiSTer; "why not this session") — `release/merged-m6/` built,
## gated, deterministic; no ROM byte in the package

**The design constraint first (rule 7):** the WIDE members (`vsw.*`) are
NEW files made largely of vs2/vhunt2 content, so a patch "against
nothing" would embed ROM bytes. Every delta is therefore computed by
xdelta3 against ONE source blob — the four reference dumps' members
concatenated in a fixed documented order (sha1 954d883c…) — so copies
out of any dump are copy instructions and only generated/authored bytes
are literal. Secondary compression OFF so the scan below sees the
payload. Measured: 20 patched members (the four vm3j program members,
the twelve vsw.* WIDE members, and vm3.13m/15m/17m/19m — four GROUP-A
gfx members the effect-tail anchors write, so the rompath `vsav.zip` is
NOT entirely pristine; the 14z-62e option-A prose that said so is
corrected in place) + 22 pristine copies; 2,592,654 patch bytes total.

**Tools:** `tools/package_release.py` (deterministic — two runs byte-
identical), `tools/apply_release.py` (shipped in the package; verifies
every reference member, rebuilds the source, applies, refuses to write
unless every target sha1 matches). **Gate `tests/test_release_roundtrip.sh`
(ci_static) PASS:** 42/42 members byte-identical after the round trip,
fingerprint 64426955 + whole-artifact manifest reproduced; corrupted
patch / wrong target sha1 / one-bit-wrong dump each REFUSED with nothing
written; rule-7 scan: 2.59 MB of patch bytes against 1,384,723 indexed
64-byte reference chunks, zero hits, must-fire control caught (2 hits).
Dependency: `xdelta3` (brew install xdelta) — the gate SKIPs without it.

**Release unit decision (mine, open to veto):** merged-m6 only — the
solos are instruments, the stock twin is never distributed.
**RULED (maintainer, 2026-08-22): the package stays IN-TREE until
MiSTer; a tagged GitHub release then covers both.** Pushed.

## Session 14z-105 CLOSE — the freeze is GREEN end to end; commits
## LOCAL, awaiting the maintainer's field test before push

**Every verification of the 14z-105 freeze, final:**
- run_suite: the three solo sets re-frozen (SUITE_ONLY targeted freeze of
  the 9/10/11 self-frozen `.sha1` replays — every select-reaching tenant
  replay moved, as the two added sprites require) and then the FULL
  unfiltered verify on don_m11 / hui47 / pyron31: **SUITE GREEN x3**, 0
  FAIL, 0 NONDETERMINISTIC; all 148 window/composite specs on their
  frozen lines.
- test_m3a_reproducible: all five artifacts rebuild bit-exact on the new
  pins; whole-artifact manifests match (42/30/42/42/42).
- Merged gates on m3b_merged13: test_version_string, test_oboro_select,
  test_wheel_bank5 (AUTHORED 2), audit_select_bank_gates,
  audit_roster_pairings 111/111, test_tenant_pairings 6/6, audit_trap_
  parity, audit_fg_parity (native-parity), audit_clone_beam_lines,
  audit_hui_grunt, test_dualtrack (frozen onsets held), test_fbneo_
  legacy_oracle (frozen offset inventories held), test_merged_render_
  content (bands byte-equal to the NEW solos) — ALL PASS.
- Static: test_pcrel_escapes (solo + merged, control alive),
  test_region_overlap (2033 held), test_pointer_flow (4 new baselines),
  test_escape_triage (re-frozen, verdicts identical), test_manifest_merge
  (re-pinned), test_tenant_loop (re-pinned), test_gfx_tile_codec (new).
- run_all_static --strict: **PASS 98 / SKIP 0 / FAIL 0** (the suite grew
  97 -> 98: test_gfx_tile_codec). An earlier run showed 2 FAILs that were
  a RACE with my in-flight edits (the manifest_merge pin landing mid-run;
  tenant_row_owner edits the generator in place) — both PASS alone and
  in the clean re-run.
- run_battery_m2: 23 PASS + the wide-render self-skip, which was then
  run directly on the m5_stock6/don_m11 pair: PASS (the 14z-102 shape —
  effectively 24/24).
- audit_guard_corpus and audit_merged_legacy: run AFTER the close entry
  while the maintainer tested — both PASS (see the post-freeze note).

**Post-freeze, while the maintainer tests (2026-08-22):** the Oboro pick
measured on FBNeo too — id 0x18 / base 0x0B3450 with Start, 0x08 /
0x0A6418 without, field-for-field what MAME reads (the §4 dual-emulator
agreement for new content); frozen as leg F of test_oboro_select.sh.
The two long soaks were then run: **audit_merged_legacy PASS (rc=0)** —
leg a 47/47 legacy replays on their exact frozen classes, leg b guard-
clean vs the new solos; **audit_guard_corpus PASS — 316/316 guarded runs, zero vectors** on merged-m6 under every tenant forcing. Every verification the 14z-102 freeze had is now green on 14z-105 too.

**FIELD-CONFIRMED AND PUSHED (maintainer, 2026-08-22):** "Tests confirm
Oboro Bishamon and the M6 mark." Observation recorded: Oboro's pre-match
INTRO is very long — vanilla vsavj's own boss intro, not ours, and he is
not tournament-legal, so accepted as-is (no item). main + the four
freeze tags pushed (cfb6bd3..f1db172).

**Where the maintainer looks:** `tools/run_wide.sh build/m3b_merged13
fbneo` — "M6" bottom-right on select; Bishamon + Start held -> Oboro.

## Session 14z-105 — THE WINDOW EXECUTED: W1 THE OBORO SELECT HOOK +
## W2 THE VERSION STRING, one freeze — donovan-m11 / huitzil-m20 /
## pyron-m14 / merged-m6 (maintainer "happy with the plan, I'll test
## before we push", 2026-08-22). Every gate that has finished is GREEN;
## the suite re-freeze and the long merged batch run at close.

**The opening measurement (RH-1, before a byte was authored):** on
vanilla vsavj, with P1 Start held on the select screen, the player
struct's input word `+0x394` reads `$8000` (`$0000` without) — so the
`btst #7,$394(a6)` in vanilla's Gallon-variant confirm path at
`PRG:0x020B9C` IS the Start test, and the template is exact; `$FF8060`
reads 1 at the same time (the 14z-104 "is it live at select?" question:
yes). The committed id stays 0x08 on vanilla (no Oboro path, as
expected).

**W1 — `oboro_select_hook`:** a 30-byte profile-gated `site_thunk`
displacing the `cmpi.b #$2,$382(a6)` at 0x020B9C: Bishamon? / Start? /
`move.b #$18,$382(a6)` / re-execute the displaced cmpi (its flags feed
vanilla's `bne`) / rts. Declared identically in all three manifests
(ENGINE-SITE, deduped to one; +2 ops at every N). Generator gained a
`profile` key on site_thunk (mirrors select_wheel/sound_table; inert
for every existing row) and `id_literal_ok` carries the deliberate
0x08/0x02 compares. MEASURED on the probe and frozen as
`tests/test_oboro_select.sh` (5 legs): P1 hold -> 0x18 + base
`0x0B3450` in-match; no-hold -> 0x08 / `0x0A6418`; Start on Demitri ->
0x01; P2 (default cell 0x05, D D L L) -> 0x18 / `0x0B3450`, P1
untouched; STOCK twin -> 0x08. Stock rebuilt under the new rows =
`883e7d17` = m5_stock5, whole-artifact manifest identical (30/30).

**W2 — the version string:** `version_text/font/x/y/pal/base` knobs on
`[[select_wheel]] roster21` (all three manifests, identical); the
generator appends one 1x1 glyph entry per character to the copied
wheel record (count 20 -> 22, budget 0x55 carried over and now
asserted >= entries) and encodes `build/manifest/version_font.json`
(5x7, 0-9 A-Z - . space, authored, NEW provenance) 2x into 16x16
tiles handed to build_gfx through `wheel_bank5.json["authored"]`
(place() same-source-or-fail; audit_gfx_merged + check_wheel_bank5
know the kind). "M6" at screen (340,202) — the empty bottom-right
corner, chosen from snapshots — pal row 0x19 (Phobos' medallion row,
thunk-re-asserted every select frame, ink pen 7 = 0xFF8), codes
0x1FE40/41 (free in the merged-m5 group C ledger). 0 ops.

**THE CODEC FINDING (platform gotcha, gate `test_gfx_tile_codec.sh`):**
the first probe drew the glyphs MIRRORED per 8-pixel half inside an
opaque black box. The OBJ list had the sprites exactly where intended
(x=0x194/0x1a4, y=0xCA, bank 5, pal 0x19, codes fe40/fe41), so the
defect was in the tile bytes: `gfx_tiles.decode` had mapped plane bit i
to pixel i since the module was written, and nothing had ever consumed
pixel ORDER (cmd_match and BLANK compare raw bytes) — the first tile
this project ever SYNTHESIZED exposed it, and only because "M6" is not
symmetric ("M" looked right). Fixed both ways (bit i = pixel 7-i),
transparent pen 15, and the OBJ->screen transform measured as
(x-64, y-16). Re-probed: the MAME snapshot pixel-matches the intended
bitmap with ZERO mismatches at (340,202) and zero opaque pen-0 pixels
(`tests/test_version_string.sh` §2 — the render-layer check that a byte
round-trip cannot replace).

**The freeze (the 14z-99/102 rhythm):** op counts re-frozen with
attribution (325/365/298; 600/652; 806/907); `build/merged_probe_w6`
rehearsed, then don_m11 `1de9a027` (325) / hui47 `24a27940` (365) /
pyron31 `6bf265ab` (298) / m5_stock6 `883e7d17` (UNCHANGED) /
m3b_merged13 `64426955` (806, BIT-FOR-BIT the probe) built from the
tree; expectation sets carried-renamed m10->m11, m19->m20, m13->m14 +
registry rows; m3a pins + whole-artifact manifests moved (attributed:
program members + the four GROUP C members = the glyph tiles; no
QSound member). **Placements moved:** the thunk allocates per tenant
iteration ahead of the regions, so every huitzil placement is +0x10
and every pyron one +0x30 — bases.tsv re-derived from merged13's own
table (phobos 0x4595b0, pyron 0x4ac90c, donovan held), pcrel
[merged_*] + solo sections re-pointed (inventory unchanged 69/10/10),
pointer_flow baselines re-frozen for all four (the +1 `data:long` is
the record's count word; the merged pairs had silently stayed on
merged11 since 14z-100 — the #94 class, now current). The standing
re-point sweep executed: ~70 BUILD defaults (the m3b_merged11
one-back set, the 14z-103/104 audits, tripwire/guard-corpus/
projectile-clash, dualtrack, render-content D/H/P, region_overlap trio
(section 5 re-measured: still 2033), identity PLAY pin, battery stock
path, voice_row_range, hui_grunt per-build row, decode_stage_banners'
donovan clean leg).

**Green so far on the new artifacts:** test_oboro_select,
test_version_string, test_wheel_bank5 (AUTHORED 2), audit_select_bank_
gates, test_pcrel_escapes (solo + merged, control alive),
test_region_overlap, test_pointer_flow, test_tenant_loop, test_gfx_
tile_codec; m3a_reproducible and the long merged batch (roster
pairings, tenant pairings, trap/FG parity, clone-beam lines, hui grunt,
dualtrack, FBNeo oracle, render content) + the three run_suite
re-freezes run at close — results in the CLOSE entry below.

**Re-freezes the window forced, each attributed:** `test_manifest_merge`
site_thunk counts (19,14,6)/30/5 -> (20,15,7)/31/6 (one row per manifest,
dedupes to one); `tests/expected/escape_triage.txt` re-frozen in the
gate's sorted form — the 25 verdicts are IDENTICAL, only the merged
addresses moved (+0x10/+0x30) and with them the sort order;
`test_region_overlap` section 5 re-measured UNCHANGED (2033).
**The select-window specs did NOT move:** `propose_masked_specs` over
all 148 window/composite specs of the three carried sets proposed the
frozen line verbatim — the 14z-104 prediction ("more sprites shift the
window end") is retracted; the end is the VS-phase re-init. Only the
self-frozen `.sha1` replays were re-frozen, via a new `SUITE_ONLY=`
authoring filter on `run_suite.sh` (prints FILTERED; never a verdict —
the acceptance is the unfiltered verify run, which ran for all three
builds at close).

**N-2 policy applied (the 14z-102 standing rule):** build/don_m9,
don_m9_s4, hui45, pyron29, m3b_merged11, m5_stock4 deleted (tracked
metadata removed in this commit; recoverable via git history + the
freeze tags); every live reference had been re-pointed first (only a
per-build history row in audit_hui_grunt and a docstring still name
them). The rehearsal probes merged_probe_w6 / probe_stock_w6 stay
(evidence; the next attic pass takes them). [DONE 14z-106: moved to
`../build_attic_14z105`.]

**Retractions executed (grep'd):** "no in-game version string" (platform
gotcha §3 + test_build_identity_distinct header); "Oboro's entry path
is unlocated" qualified in id_space.md / select_screen.md — VANILLA's
stays unlocated and irrelevant; the port has its own. 0x18 stays
RESERVED for tenants (it is Oboro's).

**SPLIT 2026-08-20 (14z-99 post-freeze close, maintainer-approved): this
file holds the RECENT session groups + THE LEDGER; the full detail of every
older session lives verbatim in `STATE_HISTORY.md`.** How to work with it:
- **Lookup**: "STATE 14z-XX" references resolve here first, then in
  STATE_HISTORY.md — section names are preserved verbatim in the archive.
- **Claim-greps MUST include STATE_HISTORY.md** (the CLAUDE.md §5
  retraction-discipline command names it).
- **ROLLOVER RULE (part of the session-close ritual)**: after writing the
  close entry, move session groups beyond the newest THREE to the TOP of
  STATE_HISTORY.md's body (below its header) and append their one-line
  entries to THE LEDGER below, composed from the group's own banner
  headers. If this file still exceeds ~150 KB, roll the oldest kept group
  early. Standing sections at the bottom of this file (decisions pending,
  the deadness register, open bugs, findings log) are CURRENT STATE — they
  never roll to the archive; entries within them are marked DECIDED/FIXED
  in place, as always.

# THE LEDGER — archived sessions, one line each (newest first)

Full detail for every line: `STATE_HISTORY.md` (verbatim; grep the session
tag or any phrase below). `[+N more entries]` = the group has N further
session records in the archive beyond the headline shown.

- Session 14z-104 CLOSE — THE §4 COVERAGE DEBT TACKLED end to end (maintainer-directed): the mandate measured cell by cell, six new audits built and green on merged-m5 and the matrix documented as a maintained artifact; THE PURSUIT answered and instrumented (audit_pursuit_leap); coverage gap 1 (tech roll + throw tech, both directions) and gap 2 closed; THE OBORO QUESTION answered with a live demonstration; the 14z-105 window (Oboro hook + version string) prepped in NEXT_SESSION  [+4 more entries]  [rolled 14z-107 close]
- Session 14z-103 — THE A4 PIN-CLEANUP PASS EXECUTED (every stale reference re-pointed, run green, or ruled a deliberate pin) plus the three findings it surfaced (the gate_failures litter class, GitHub #110, four LEGACY replays promoted off self-frozen .sha1); #110 FIXED AND CLOSED — the mechanism was the ARCADE DRAW, not cycle drift, both audits re-derived on pinned-opponent rigs and green on merged-m5; the Circuit Scrapper report measured and not reproduced  [+1 more entry]  [rolled 14z-107 close]
- Session 14z-102 CLOSE — THE #107+#109 WINDOW frozen as donovan-m10/huitzil-m19/pyron-m13/merged-m5 (#109 re-derived from scratch to effect-class ROW 31, the DF clone-mode beam emitter vsavj stubbed; #107 row flip; gold tint kept; build-dir triage 8.1 GB atticked; N-2 deletion policy adopted)  [+6 more entries]  [rolled 14z-105 close]
- Session 14z-101 CLOSE — the agreed #108->#107->#106 sequence executed windowless (#108 INVERTED to not-a-defect: the satellite word is our own bank row, native satellites equally sweep-inert; #107 twin-anchored statically + tie-refusal landed; #106 closed via verify_pcrel_data --extract); guard-corpus built 316/316; DF mechanics measured ours-vs-native (frameworks differ BY DESIGN; ours == pristine vsavj on the legacy control); #109 found, root-caused through two in-place retractions, and fully prepped  [+9 more entries]  [rolled 14z-104 close]
- Session 14z-100 CLOSE — THE HARDENING PROGRAM opened and executed same-session (pointer/flow comb H1, escape triage H2, the #99 continue-switch lock H3, the contact rig H4 with the -debug/non-debug instrument paradox left to 14z-101); #99 CLOSED (maintainer); #106/#107/#108 filed; the build-dir decision package delivered  [+3 more entries]  [rolled 14z-104 close]
- Session 14z-99 FREEZE + field-confirmation — THE WINDOW EXECUTED END TO END (donovan-m9/huitzil-m18/pyron-m12/merged-m4; #43(b)+#103+#104+#105; merged BIT-FOR-BIT the rehearsal; stock twin moved by design); field pass CLOSED all three tickets same day (incl. transformation throws) and un-parked #99; the skipped close ritual caught up post-freeze  [+7 more entries]  [rolled 14z-102 close]
- Session 14z-98 CLOSE — #103 root-caused+staged (window = uncomment+battery), #102 answered (vanilla's own continue), #104 found/reproduced/mechanism-closed-then-14z-99-corrected, #105 filed + AUTO selection solved, "instance 2" retracted (the 2-byte-poke class); NO SHIPPED BYTE MOVED  [+9 more entries]  [rolled 14z-101 close]
- Session 14z-97 CLOSE — #96 CLOSED (the battery's target FOLLOWS THE BUILD via registry.tsv); the §4 masked-compare vocabulary unified to ONE implementation (tests/lib/masked_compare.sh, proven 3 ways); the #99 continue rig BUILT and blocked one screen short by #103 (instance 2); #102 filed (arcade chaining quirks); 08_challenger_join's 3807 attributed to $FF06E1 (ram.md:62); two measured-wrong-thing defects fixed (propose_masked_specs absolute-builddir trap; the lifted diverge branch)  [+9 more entries]  [rolled 14z-100 close]
- Session 14z-96 CLOSE — ritual complete  [+7 more entries]
- Session 14z-95 — FOUR MAINTAINER RULINGS TAKEN, #52 LANDED, and the Phobos sfx report corrected from "a sound missing" to "a WRONG sound"
- Session 14z-94 (11) — THE MERGED-M2 PLAYTEST RESULT (maintainer, 2026-08-18, build/m3b_merged9 on MAME). NO REGRESSION — and one CRASH.  [+11 more entries]
- Session 14z-93 CLOSE — ritual complete  [+3 more entries]
- Session 14z-92 CLOSE — ritual complete  [+6 more entries, incl. GitHub #75 closed — the merged gfx-verify abort was a verifier artifact]
- Session 14z-91 CLOSE — THE LEGACY REGRESSION FIXED (obj_hook de-thunked: walker relocated, callers repointed; fixture-override deletion; type-6 change), m5/m13/m7 -> m7/m15/m9 re-freeze, EIGHT maintainer rulings applied (Rule 1 v2 retitle #35, PNG goldens ruled outside rule 7 #73, CI drafted #41...). THIS GROUP ALSO HOLDS, as ### sub-entries: 14z-90 (the 2026-08-15 adversarial audit re-judged, tier 1 complete), 14z-83..89 (Phobos DF gold block huitzil-m6, M5 voice samples design + Z80 driver RE, the 14z-85 owner-tag family, 14z-86 M5 voice batch, 14z-87 voice-class borrow + 87b beep/medallion, 14z-88 medallion revert, 14z-89 QSound ledger binding)
- Session 14z-82d — the playtest reports, measured  [+3 more entries]
- Session 14z-81 — THE MERGED-LEGACY MEASUREMENT: legacy safe, tenants not
- Session 14z-80 — THE N-TENANT LOOP: `main()` iterates, and the three traps that were not in the spec
- Session 14z-79 — (b') LANDED, AND BULLETA'S DARK FORCE WAS BROKEN FOR TEN SESSIONS
- Session 14z-71 — THE BEAM: row 16 of the effect-class table is a STUB in vsav, and underneath it vsav has no list-type 12
- Session 14z-76 — Pyron's EFFECT PALETTE ported; the "16-row hazard" retracted
- Session 14z-78 — `anim` MOVES: M3b's blocker was a hex literal
- Session 14z-77 — M3b slice C: rows get an OWNER, and the gating family asks it instead of the build scalar
- Session 14z-75 — PYRON FROZEN as `pyron-m1` (d8b282da)  [+1 more entries]
- Session 14z-74 — PYRON's render rung OPENED (Steps 0/1/3 landed), and a GENERATOR BUG found under it  [+1 more entries]
- Session 14z-73 — the grab victim: FIXED and MAINTAINER-CONFIRMED (both grabs, MAME + FBNeo). The victim's capture-pose keyframe-pointer table row for H aliased character 0's block; ported H's own block. Also: the FG "slowness" was the broken GFX, not timing — resolved by observation.  [+1 more entries]
- Session 14z-71 CLOSE — ritual complete  [+6 more entries]
- RESOLVED the same session — TAKE OVER THE DEAD LIST-TYPE 6 (maintainer-approved; build/hui20, fingerprint 40cc10b1)
- Session 14z-70 — THE BEAM IS AN ANIM-SELECTION DEFECT: our build never walks the beam anim nodes (measured, both legs, one emulator)  [+3 more entries]
- Session 14z-69 CLOSE — ritual complete  [+8 more entries]
- Session 14z-68 (the effect-flow closure — root cause found)
- Session 14z-67 (D4: the Phobos gfx vertical)
- Session 14z-66 (playtest round-1 worklist)
- Session 14z-65 (M3b OPENED 2026-08-07 — plan + decisions register)
- Session 14z-64 SESSION CLOSE (2026-08-07)  [+3 more entries]
- Session 14z-63 (phase 3 item 1: the wheel bank-5 move — REAL MEDALLION ART, vanilla cells pixel-identical by construction)
- Sessions 14z-62j/62k (same day — OPTION A PHASES 1-2 LANDED and PLAYTEST-VALIDATED: the select family serves from group C bank 5; Jedah confirmed indistinguishable from vanilla by human playtest)  [+1 more entries]
- Session 14z-61 (WIDE GARBLE FIXED — a shadowed ROM member, not the emulator; and the rendering gate that should have caught it)
- Session 14z-60 (select cursor MEASURED; the id space is CONVENTIONAL)
- Session 14z-59l (ROSTER ACCESS decided; the vs2 wheel measured properly)  [+1: 14z-59j dual-track invariant established — later SUPERSEDED 14z-94 (#95), see the archive's marked banner]
- Session 14z-59i (M5 SOUND IS AUDIBLE; WIDE build registered; a false fingerprint corrected)  [+5 more entries]
- Session 14z-49 (rounds 61-62: HUD MUGSHOT + NAME + SELECT MEDALLION — the whole per-slot venue-asset family fixed)
- Session 14z-58e (handoff hygiene: reproducibility PROVEN)  [+1 more entries]
- Session 14z-57 (WIDE B4 attempt 2 — clean fail, narrowed to the loader)
- Session 14z-56 (WIDE B4 attempt 1: an invalid canary, honestly)
- Session 14z-55 (WIDE B2 — the 19-bit tile address; and the gate's video blind spot)
- Session 14z-54 (WIDE Phase B0+B1: the first two regions grown and proven inert)
- Session 14z-53 (RE-CONTEXTUALIZED: from "fit in the holes" to CPS-2 WIDE; Phase A measurements complete)
- Session 14z-52 (M5 phase 1: music bug root-caused; 13 rows restored; the rest is a SPACE problem)
- Session 14z-51 (M5 sounds: discovery phase — the id-space myth dies)
- Session 14z-50 (round 65: M2b+ASSETS FREEZE at b91647c7)
- Session 14z-49d (round 64: mask window RATIFIED; recolor necessity proven; audit script)  [+2 more entries]
- Session 14z-48b (rounds 59-60: HC moves maintainer-CONFIRMED; HUD portrait = wrong ART not palette; select medallion re-listed)  [+1 more entries]
- Session 14z-47 (SELECT POST-CONFIRM BLINK FIXED — accent thunks gain the owner-link venue fallback; battery pending at entry time)
- Session 14z-46 (SWORDLESS-DEITY PALETTE FIXED — the state_hook seq-id synthesis was wrong for 8 of 12 stubs; battery pending at entry time)
- Session 14z-45b (round 56 on 4f69589d: win screen maintainer-CONFIRMED; lose/continue NO-ISSUE)  [+1 more entries]
- Session 14z-44c (round 55: WIN-screen item corrected + sharpened)  [+2 more entries]
- Session 14z-43b (round 52 on 22ada38e: THE NEUTRAL-POSE TRIGGER FOUND — it's the ES FINISH; death-path class consumer = the suspect)  [+1 more entries]
- Session 14z-42c (round 51: LP/MP closed as native; ES = the known class-0x51 interim, UPGRADED to accuracy item; win-screen art item added; KO bug parked)  [+2 more entries]
- Session 14z-21 (queue: alt-color item closed NO-BUG; mirror native-exact; 2026-07-31)  [+1 more entries]
- Session 14z-41 (call-pair audit: pair 3 = the known sound stub; PAIR 1 = the real suspect — a lost spawner)
- Session 14z-40 (mash bridge: the walker block audited clean — divergence narrowed to three reconciled engine-call pairs)
- Session 14z-39 (round 49: maintainer clarifications — the Lightning Sword reference data)
- Session 14z-38 (mash bridge: three fields exonerated; theory sharpened to the input-struct read)
- Session 14z-37 (round 48: shock CONFIRMED with a caveat — hit counts maxed; mash mechanic mapped to the doorstep)
- Session 14z-36 (SWORDED-421P SHOCK + DEATH FIXED — the final reconcile; the class-0x4E saga closes)
- Session 14z-35 (type-0x51 cluster resolved — the engines RENUMBERED the copy-class record family; latent crash preempted)
- Session 14z-34 (round 46: crash fix CONFIRMED + swordless shock RESTORED — the record-type insight reframes the remaining queue)
- Session 14z-33 (COLUMN CRASH FIXED — record-type dispatch aliases; permanent guarded gate)
- Session 14z-32 (round 45: blink fix CONFIRMED everywhere but the select screen; column-crash fix session)
- Session 14z-31 (round 44: BLINK ROOT-CAUSED + FIXED (color-aware accent); CRASH REPRODUCED + PINPOINTED)
- Session 14z-30 (round 43: crash triage — repro scaffold built, blocked on the plant input; classification of the other reports)
- Session 14z-29 (consumer-trace session: supplementary facts; repo stays at the 14z-28 interim)
- Session 14z-28 (round 41: 14z-27 class remap REVERTED — gameplay regression; three-consumer map final; deity palette item confirmed)
- Session 14z-27 (round 40: CHANGE IMMORTAL KO FULLY FIXED — native class remap; aura palettes explained)
- Session 14z-26 (round 39: 421P correction -> ROOT CAUSE FOUND + partial fix shipped; collapse handoff remains)
- Session 14z-25 (round 38: select-sword CONFIRMED by maintainer; 421K match-end KO bug logged + repro hunt banked)
- Session 14z-24 (SELECT-SWORD FIXED — draw-behind flag; machinery live at stage 6, battery pending)
- Session 14z-23 (select-sword: diagnosis CORRECTED — offset+priority, not missing art; still staged 99)
- Session 14z-22 (select-sword: machinery BUILT+VERIFIED, staged 99 pending the record-walk-gap fix)
- Session 14z-21c (select-sword: FULL activation chain reverse-engineered; fix ready to implement)  [+1 more entries]
- Session 14z-20 (row-0x0F fixture override SHIPPED; sword-shock aura resolved as engine-global; 2026-07-31)
- Session 14z-19 addendum (round 36 CONFIRMED, 2026-07-31)  [+1 more entries]
- Session 14z-18 (round 34: accent super-cycle completed; statue rows found and fixed; two new items logged) — CONCLUSIONS CORRECTED IN 14z-19
- Session 14z-17 (THE SWORD/STATUE BLINK IS FIXED — build f4a7e00e)
- Session 14z-16 (blink: vs2 STEADY confirmed; the complete fix design)
- Session 14z-15 (blink driver FULLY mapped: the stage palette-anim refresh system)
- Session 14z-14 (sword-blink fix session: driver mapped to the palette-JOB system; third table repointed; ONE tap from the finish)
- Session 14z-13 (round 33: electrocute FULLY CONFIRMED incl. yellow; sword blink mechanism DECODED)
- Session 14z-12 (round 32: X-ray STRUCTURE confirmed; effect-palette block ported; purple-vs-yellow = DECISION)
- Session 14z-11 (round 31: the X-RAY OVERLAY — offset-computed records swept; build 6f96f45b)
- Session 14z-10 (THE GARBLE FIX SHIPPED: protected-tile policy + exception pool)
- Session 14z-9c (ROUND-29 ROOT CAUSE, FINAL AND PHYSICAL: the Jedah-band tile window is NOT dead)  [+2 more entries]
- Session 14z-8 (round 28: the 14z-7 clear was a PHANTOM FIX — reverted; the real shock-garble mechanism characterized)
- Session 14z-7 (Victor-shock garble FIXED — stale-OBJ countdown clear)
- Session 14z-6 (round 27: sword CONFIRMED; Victor-shock garble scoped)
- Session 14z-5 (round 26 continuation: SWORD SWING FIXED — build 2da7d910)
- Round 26 (2026-07-30, maintainer): 597ae55b re-confirmed clean
- Session 14z-4 (round 25: spark-thunk visual regression; full rollback to 597ae55b)
- Session 14z-3 (the sword-swing BLOCKER: mechanism fully mapped, fix staged)
- Maintainer priority statement (round 24, 2026-07-30)
- Session 14z-2 (throw teleport ROOT-CAUSED and fixed: victim-keyframe table)
- Session 14z (round 22: winpal copies convicted and fully reverted)
- Session 14x (round 20: throw rollback per maintainer; sword-attack rendering logged)
- Session 14w-c resolution (ALL GREEN at d6a751cb)  [+4 more entries]
- Session 14v (grab-pointer work vars fixed — the Felicia float)
- Session 14u (win-quote palette SHIPPED at 1f5fa38e — pending playtest)
- Session 14t (win-quote palette: decoded, port REVERTED by the gate)
- Session 14s (playtest round 16: overlay REVERTED; pixel gate born)
- Session 14r (overlay port COMPLETED to a 22-site shipping config)
- Session 14q (stage-7 overlay port: architecture PROVEN, closure blocked)
- Session 14p (feet fixed; blink mechanism = Jedah's overlay records)
- Session 14 highlights (M2a FROZEN)
- Session 14o (THROW DAMAGE FIXED — the fourth same-value class found)
- Session 14n (round 12: revert validated; two new items scoped)
- Session 14m (f8eda2ca REVERTED — regression + board reset)
- (reverted) Session 14l (bank-attribution fix)
- Session 14k-b (blink TRULY root-caused: per-record bank attribution)
- (superseded analysis) Session 14k (OBJ budget saturation theory)
- Session 14j (THE EFFECT TAIL SHIPPED — elemental swords restored)
- (earlier) Session 14i-b (round-9 mechanisms pinned)
- (earlier same session) Playtest round 9 diagnosis
- Session 14h highlights (win-quote portrait ported; HUD name found)
- Session 14g highlights (VS splash SHIPPED; three superset traps caught and fixed)
- Session 14f highlights (select palettes fixed; splash/win specified)
- Session 14e highlights (select phase 2 SHIPPED: portrait + name on screen)  [+1 more entries]
- Session 14d highlights (select-screen port: phase 1 = negative result, map corrected)
- Session 14c highlights (select-screen pipeline mapped)
- Session 14b highlights (M2b static phase — R2 cracked)
- Session 7 highlights (M2a stage 4 — frontier closed; the crash was ours)
- Sessions 5-6 highlights (M2a stage 4 — the port runs)
- Session 4 highlights (M2a — the real Donovan port)
- Session 3 highlights
- Early standing sections (Current milestone / Next actions / Open items / Decisions made) — 2026-07-era snapshots, STALE, kept verbatim in the archive; the closed early decisions (base revision vsavj, per-member checksums, byte-order convention) are all recorded in CLAUDE.md/HANDOFF too
- OPEN BUG (14z-60y): WIDE renders Donovan/Anita with WRONG TILES — FIXED 14z-61 (the shadowed-ROM-member hash-resolution trap); header kept as written

---

# STANDING SECTIONS (current state — never archived)

## Decisions made (maintainer, 2026-08-05): two ratifications

**1. CLAUDE.md §4 comparison class v3 — "bounded re-convergent window".**
Ratified for the select screen, which the roster deliberately alters. A
replay qualifies only when all four hold, frozen per replay: a single
CONTIGUOUS run, a fixed ONSET frame, full RE-CONVERGENCE, and match state
UNTOUCHED. Measured over five replays before the ruling (onset 890 in every
one, one run each, 2469-10498 identical frames afterwards including a full
timeout match). It is STRICTER than the frozen first-divergence constant it
sits beside, which never re-converges at all — a narrower licence for one
screen, not a loosening. §4 amended; checker `tools/compare_window.py`,
ground-truthed both directions by `tests/test_compare_window.sh` including
that a bit-identical pair is NOT a silent pass (the expectation asserts the
divergence exists).

**2. The `[[tenant]]` schema.** Ratified, and already implemented for a
single tenant (14z-60t/u) byte-identically on both tracks with the tenant
still at `0x0F`. `docs/project/tenant_manifest.md` moves PROPOSAL -> RATIFIED; its
wheel/ladder/folds sub-tables stay proposal-only because that work is not
done.

Maintainer: "I validate the two items, I don't need testing to see that they
hold on principle." The measurements above were taken before the ruling
regardless — the class's four clauses are what was measured, not what was
hoped for.

## STANDING PRINCIPLE (maintainer, 2026-08-05): vanilla wins ties

"vsav vanilla is always better when we can." **When a console port and
arcade vsav differ and both would work, take vanilla.** A console port's
choice is not evidence that vanilla is wrong; it is evidence of what that
port's designers preferred.

This is a general rule, not a one-off: the PS1 capture is a reference for
what is POSSIBLE and for data we cannot otherwise obtain (cell placement,
the adjacency of NEW cells), not a style guide for content vsav already
defines. Paired with the maintainer's other statement — "as long as we can
select characters it's good" — the test is: does keeping vanilla still let
the feature work? If yes, keep vanilla.

Applied immediately, twice:
- **`Bishamon DL` and `Aulbath DR` stay vanilla** (Anakaris / Sasquatch).
  PS1 sets both to "no move"; neither is needed for reachability, so
  vanilla stands.
- **Horizontal wrap stays vanilla.** Vsav wraps left/right (cell `0x01`
  Left goes to `0x05`, measured and confirmed in-emulator); the PS1 report
  of "no wrapping" reflects untested extremes. We touch none of those
  cells, so nothing to decide.

Judgment applied under the same rule, open to veto: the three inbound edges
from `0x0B` (`D`/`DL`/`DR` into the new row) DO diverge from vanilla, and
strictly they are not required — Phobos and Donovan are already reachable
via `Bishamon D` and `Aulbath D`, and Pyron through them. They are kept
because without them, pressing Down on the cell directly above the new row
does nothing while three medallions are visible below it, which is the UX
failure "as long as we can select characters" is meant to exclude. Dropping
them would reduce the legacy footprint from 5 bytes to 2.

## Decision made (maintainer, 2026-08-05): new cells SNAP to vsav's lattice

"It feels safer to conform to arcade vsav and snap to it. As long as the UX
is good enough, I don't even mind if the look is not great." So the three
appended cells take positions derived from vsav's own hexagon rather than
PS1's pixel coordinates.

Derived layout (`build/manifest/wheel_layout_proposed.json`): vsav's wheel
is a clean hexagon, rows 1-2-3-4-3-2-1 at y=64..144 every 16, then a single
centre-line cell at y=152 (+8). Mirroring that bottom signature downward:

| cell | id | position |
|---|---|---|
| random (unchanged) | `0x0B` | (248, 152) |
| Huitzil/Phobos | `0x10` | (224, 168) |
| Donovan | `0x13` | (272, 168) |
| Pyron | `0x11` | (248, 176) |

This is geometrically IDENTICAL to the PS1 port's shape (pair, then single
on the centre line); only the id assignment differs, per the maintainer's
amendment — random keeps its vsav cell and Pyron goes to the very bottom.
28 bytes of TABLE B change. Adjacency is still a geometric DRAFT pending
the cursor-movement video.

## Decision made (maintainer, 2026-08-05): 0x360+id anim block = INHERIT

Option A: the newcomers inherit their base character's animation from the
shared 16-wide block `0x360-0x36F` (a tenant at `0x13` plays `0x363`),
exactly as vsav2 ships — Capcom left both those folds in place. Sites
`PRG:0x003E40` / `PRG:0x004082` therefore stay folded, recorded as
`inherit` in `docs/project/tenant_manifest.md`. **Fallback, if a playtest shows the
inherited animation is wrong for a newcomer: option B**, relocate the block
to a free 32-wide anim-number range and widen both masks.

## Decision made (maintainer, 2026-08-04): M5 voice samples = A then B

"A then B, gates stay strict, option C is rejected." Ship the unfaithful
voice lines silent now; revisit growing the QSound region at M3 within the
measured 16 MB `device_rom_interface<24>` ceiling; never overwrite vsav
content for sample room. Recorded in full under "Decisions pending" above,
where the option analysis lives.

## Decision made (maintainer, 2026-07-31): electrocute arc colors

Keep vsavj-native shock styling for all victims including Donovan
(option A of the 14z-20 write-up): the arcs/glow are engine-global and
victim-independent; vs2's yellow was a game-wide re-theme, not per-char
data. "Less work, less risk, and we can always come back to it after
all the more important work." LOCKED in tests/test_don_accent.sh
section 3 (shock-window vanilla lock, frozen from a vanilla run) —
revisiting requires changing that gate deliberately.

## Decision made (maintainer, 2026-08-02, round 65): M2b+ASSETS freeze

Freeze `b91647c7` as `donovan-m2c` before starting M5 sounds —
"mechanically sound as far as we can tell" (rounds 52-64 playtest
arc + full battery + suite). Frozen basis: three masked windows.

## Decision made (maintainer, 2026-08-02, round 64): third mask window

`RAM:$FF4182-$FF41A1` (palette-fade staging slot for select block-A
row 14) RATIFIED into the masked legacy basis — option A of the
14z-49b write-up, after the recolor-necessity A/B (14z-49d) showed
options B and C strictly worse. Condition attached and honored:
detailed documentation + a standing confirmation path
(`tests/audit_mask_window_ff4182.sh`; spec in docs/game/atlas/ram.md).
Extension policy stands: future palette-block ports extend the
window per measured slot, never pre-widen.

## Decision made (maintainer, 2026-08-06): select art = option A

Option A of the 14z-62e write-up: the per-hover bank thunk for the
portrait-record object + the tenant's select art in WIDE group C at
native codes; `vsav.zip` leaves the rompath entirely pristine [**14z-105:
not quite — the later effect-tail pass writes four GROUP-A members
(vm3.13m/15m/17m/19m); measured by the release packager**]. Blank-pool
relocation (option B) remains the fallback if the measured hook cost
violates the standing flicker watch. Maintainer also flagged suspected
graphical corruption in the session captures — playtest of `39597268`
in progress; the expected-interim inventory is in
docs/project/playtest_m3a_interims.md so the report can classify against it.
Original write-up kept below.

## Decisions pending (human)

- **DISTILL AI SKILLS FROM THE PROJECT'S LEARNINGS (maintainer direction,
  2026-08-24).** Recorded as FUTURE, UNPLANNED work — nothing scheduled.
  As was done for Sailor Moon S, distil the project's learnings into agent
  SKILLS, **scoped by subject rather than by task**. The maintainer's sketch:
  at least a **CPS-II** skill separate from a **VS / VS2 / VH2** skill, and
  **MiSTer** separate from **emulation**; exact scopes to be agreed. Stated
  rationale: they make further work markedly easier.
  **The precedent is concrete and observable from inside a session** — the
  SMS project produced `romhacking-methodology` (general RE/patch discipline)
  and `snes-romhacking` (platform-specific hard rules), and both load into
  Claude Code sessions on this machine today.
  **Three observations to carry into the scoping conversation:**
  1. **The split the maintainer proposes is the one `docs/README.md` already
     uses.** "Would this still be true if we abandoned the roster hack
     tomorrow?" separates `platform/` (CPS-2, MAME, FBNeo, MiSTer) from
     `game/` (Vampire Savior itself) from `project/` (this port) — and it is
     the same question that separates a CPS-II skill from a VS/VS2/VH2 skill
     from a port skill. A skill that mixes those scopes fails the same way a
     doc filed by task instead of by fact does.
  2. **A skill is loaded BEFORE the work, so it must carry what you need to
     know before you know you need it** — laws, traps and negative controls,
     not reference data. SMS made this split explicitly:
     `sms_hacking_playbook.md` quotes ZERO addresses on purpose and points at
     the checked docs instead. Skill = the discipline; docs = the facts.
     Candidate content from this project, all paid for: measure-don't-infer,
     probe sparsity, the negative-control rule, "identify moves by measured
     EFFECTS not the script's input name", "a gate that stops checking reads
     GREEN not RED", "suspect the instrument before the thing under test",
     and the §4 vocabulary of frozen non-exact classes.
  3. **Skills go stale exactly like docs, and need the same enforcement.**
     SMS ships `tools/checkskills.py`, which ID-locks the human playbook to
     the agent skill so the two cannot drift. Whatever is distilled here
     should ship with its checker in the same commit.
  Sequencing: this naturally follows the living-documentation effort above
  (a skill is a distillation, so it wants the synthesis to exist first), and
  both follow MiSTer.

- **THE LIVING-DOCUMENTATION EFFORT, and the option it creates (maintainer
  direction, 2026-08-24).** Recorded as DIRECTION, not as a task — nothing is
  scheduled and MiSTer stays the current arc. In their words: an important
  documentation effort is coming, "not replacing your logs, but creating a
  living documentation that can easily be referenced by you or me, doesn't go
  stale or lost in a statistically never read file." The SailorMoonS project's
  documentation AND WORK DISCIPLINE are the reference; formats, document types
  and visualisations are to be chosen as the best fit for THIS project rather
  than copied. Motivation: the emulator side is now essentially fully mapped.
  **The option it opens:** after the MiSTer core is finished, potentially
  "go back to the canvas, with all the documentation, and redo the project
  from the docs, because it might create a cleaner, more consistent extended
  codebase." Explicitly a possibility to preserve, not a commitment.
  **Two things worth holding on to when it is scheduled:**
  1. **Staleness is defeated by ENFORCEMENT, not by format.** What keeps the
     SMS docs alive is `tools/checkdocs.py` re-deriving documented addresses
     from the cartridge, `--check` modes on every generator, `health.sh` in
     CI, and the rule that no number reaches a doc without a run that produced
     it in that session ("an unquoted address is a claim nobody can falsify").
     The prose should be shaped so it CAN be checked. Being lost in an unread
     file is a SEPARATE problem with a separate fix — routing: "if you want to
     know X, read Y" tables at every entry point, and every synthesis document
     naming its journal twin and vice versa.
  2. **A rebuild here is unusually provable, and its feasibility is
     MEASURABLE TODAY.** The harness compares ROM BEHAVIOUR, not source
     structure, so a rebuilt artifact has a real acceptance test that already
     exists: bit-identical to vanilla on the legacy corpus, field-identical to
     the current build on tenant content, same replays, same frozen
     expectations. What decides it is not the docs but **how much of the build
     is DATA versus CODE** — the artifact encodes hundreds of measured facts
     (reconciliation rows, planted tripwires, pc-rel escapes, the ~70 re-point
     defaults, the op-count freezes), and a rebuild that does not carry them
     re-pays every debugging session that produced them. CLAUDE.md rule 5
     already requires behavioural values to live in documented tables rather
     than in code, so feasibility is essentially the degree to which rule 5
     has been honoured — which can be MEASURED rather than estimated.
     RECOMMENDATION when the effort is scheduled: make the first structural
     deliverable the EXTRACTION of measured facts from manifests/generators
     into reviewable tables with provenance. It makes the current codebase
     auditable whether or not the rebuild happens, and it is the precondition
     that turns the rebuild from a hope into an option.

- ~~**MiSTer SOURCE SEPARATION — how far does "unmixed" reach? (14z-107 (8))**~~
  **DECIDED (maintainer, 2026-08-23): the CORE stays unmixed; SHARED
  `tools/` and `tests/` STAY AS THEY ARE** — *"shared /tools and /tests are
  a bit messy but acceptable, especially since it's not 100% risk-free."*
  The standing rule the maintainer set: the MiSTer core must not be MIXED
  with the other sources — same repo is fine, same subfolder is not.
  **Already satisfied, and asserted rather than claimed:** our RTL lives in
  `cores/cps2w/hdl` while `cores/cps1`, `cores/cps2` and `cores/cps15` are
  BYTE-UNTOUCHED (`tests/test_jtcores_twin.sh` check 2e is a `git diff`
  assertion, added in D1 — the slice that first added RTL); in this tree
  `emu/fbneo`, `emu/mame` and `emu/jtcores` are separate submodules with
  their patch mirrors in parallel `emu/*-patches/` dirs.
  **NOT to be "tidied" later:** the MiSTer tools (`run_sim_jtcps2.sh`,
  `setup_jtcores.sh`, `mister_mra.sh`, `gen_vsavjw_xml.py`,
  `rpl2siminputs.py`, `check_wram_dumps.py`) and gates (`test_mister_*`,
  `test_jtcores_twin`, `audit_sdram_bank_load`, `test_sim_wram_contract`)
  STAY in the shared `tools/` and `tests/`. A move would touch
  `tests/ci_portable.txt`, `tests/ci_static.txt`, `run_all_static.sh`'s
  orphan check and every doc path naming them — i.e. it risks the
  "checks that stopped checking" class (14z-95, four instances) for zero
  functional gain. Ruled acceptable-as-is; do not re-open it as housekeeping.

- **MiSTer PACKAGING — two questions slice D0 surfaced (14z-107 (5), NEW).**
  Neither blocks D1-D4; both must be answered before a release.
  1. **Which MRA is the core's MAIN one?** `jtframe mra cps2w` puts the Euro
     `vsav` parent at `release/mra/` and everything else — including the
     WIDE set — under `_alternatives/`. For a core whose whole purpose is
     the WIDE set that is backwards. *Recommendation: make the WIDE MRA the
     main one and keep the stock `vsavj` reference leg in `_alternatives/`;*
     it is a `[parse] main_setnames` change in the fork's toml, and it moves
     nothing in the images.
  2. **How does a release carry BOTH `vsav.zip` flavours?** The WIDE romset
     is a CLONE set whose parent is the BUILD's `vsav.zip` (the merged build
     patches `vm3.13m/15m/17m/19m`), while the stock reference-leg MRA needs
     the PRISTINE dump — and both MRAs name the parent zip `vsav.zip`. On
     FBNeo/MAME `run_wide.sh` resolves this by OVERLAYING a rompath, a
     runtime notion MiSTer's MRA does not have. *Options: (a) ship only the
     WIDE MRA and drop the reference leg from the MiSTer package (it lives
     on in the sim gate either way); (b) rename the WIDE parent to a
     distinct set (`vsavw.zip`) via `[parse] parents`, which costs a
     zip-name divergence from the FBNeo/MAME package; (c) make the WIDE
     romset self-contained by carrying its own copies of the eight GFX and
     two QSound parent members — +40 MB of zip, and it stops being a clone
     set. Recommendation: (b), which keeps one romset directory able to feed
     all three emulators. NOT decided; it is a distribution-shape call.*

- ~~**THE BANK-0 SLOT COUNT — a fork-surface call (14z-107 (4), NEW).**~~
  **DECIDED (maintainer, 2026-08-23): option (A), add `jtframe_ram1_7slots.v`
  to the fork.** SDRAM bank 1 stays at exactly the two streams
  (PCM + group-C obj bank 4) that `tests/audit_sdram_bank_load.sh` modelled
  when it returned GO, so the measurement keeps covering the shipped design.
  **AND THE RELATED QUESTION IS RULED TOO — the profile is selected at
  RUNTIME from a spare MRA header bit, NOT by `ifdef`** (maintainer,
  2026-08-23). Consequence, and the reason it matters: stock `vsavj` on our
  own RBF then runs with the wide decode CLEAR, so Rule 1 v2's "profile-gated
  ... so stock `vsavj` is untouched BY CONSTRUCTION" holds on FPGA as a FACT
  rather than as an inertness argument, and the reference-leg MRA becomes a
  real stock leg. It also mirrors the FBNeo shape (a flag set from the driver
  entry). Every gated site takes a `wide_en` wire off that header bit — D1's
  QSound latch is the first.
  **IMPLEMENTED 14z-107 (6): the bit is MRA header byte 41, bit 0, ACTIVE
  LOW** (`0xFF` — the generator's own `[header] fill` — means profile OFF;
  the WIDE MRA writes `0xFE`). The polarity is forced, not chosen: any other
  would change every stock MRA this core emits. RTL
  `cores/cps2w/hdl/jtcps2w_profile.v`; measured end to end in
  `tests/test_mister_mra_map.sh` and exhaustively simulated with three
  must-fire controls in `tests/test_mister_wide_gate.sh`. **Option (A),
  `jtframe_ram1_7slots.v`, is NOT yet written — it is D2's need, not D1's,
  and D1 confirmed it: D1 changes no placement and adds no slot.**
  Original entry:
  **THE BANK-0 SLOT COUNT — a fork-surface call (14z-107 (4), NEW).** The
  placement map (`docs/project/mister_map.md` §5) puts seven consumers in
  SDRAM bank 0 (RAM/VRAM/ORAM, VRAM-DMA, gfx-ORAM, main ROM, Z80, the QSound
  high window, group-C obj bank 5) and upstream's family stops at
  `jtframe_ram1_5slots` (`ram2_4..6slots` are the only 6-slot variants and
  they carry two write ports).
  - **(A) add `jtframe_ram1_7slots.v` to the fork** — a mechanical member of
    an existing formulaic family. Keeps SDRAM bank 1 to exactly the two
    streams (PCM + obj) that `tests/audit_sdram_bank_load.sh` modelled when
    it returned GO.
  - **(B) move the Z80 program to bank 1** — bank 0 drops to six slots
    (`jtframe_ram2_6slots`, second write port tied off) and bank 1 becomes
    `jtframe_rom_3slots`. Zero new jtframe files, but bank 1 then carries
    THREE streams, which is beyond what was measured, and bank 1 lands at
    15.95 of 16 MB.
  - **Recommendation: (A).** The GO verdict is a statement about a two-stream
    bank 1; option (B) spends that evidence to save one boilerplate file.
  Related and unresolved either way: **should the profile be selected at
  RUNTIME from a spare header byte** (`jtcps1_prom_we.v:52-54` — "6 are
  actually used and 10 are reserved") rather than by `ifdef` in `cps2w`? A
  compile-time gate means stock `vsavj` on our RBF gets the widened PRG
  decode and the 3-bit obj bank; both are provably inert for stock content
  (`cps2_wide.md` A1/A2), but a header bit would restore
  gating-by-construction and make the MRA the profile selector.


- ~~**THE MiSTer MEMORY-MAP ROUTE (14z-107 (2)) — NEW, and it is the arc's
  next fork in the road.**~~ **DECIDED (maintainer, 2026-08-23): option (2),
  the BANK REPACK, measuring first; XL is the FALLBACK** — the ruling was
  *"attempt repack (measuring first)"*, with `JTFRAME_SDRAM_XL` (two chips,
  128 MB) kept in reserve if the repack fails. Vanilla's 32 MB of GFX stays
  exactly where it is in banks 2+3 and the ~6.4 MB of tenant art goes into
  bank 1 alongside the QSound PCM, reached by the profile-gated promoted
  tile-code bit. **The measurement the ruling required was taken the same
  day and says GO** — bank 1's PCM is already at a 98.8% row-miss rate so it
  has no locality to lose, and the worst case runs at 26.3% of a single
  bank against the 32.9% bank 0 already sustains
  (`tests/audit_sdram_bank_load.sh`, `build/sdram_bank_load_14z107.log`,
  verdict in STATE 14z-107 (3)). It bounds the headroom; it does not prove
  the repacked design. Original text kept below.

  **THE MiSTer MEMORY-MAP ROUTE (14z-107 (2)) — the arc's next fork in the
  road.** The profile ruling (WIDE v1 verbatim, one romset)
  is NOT in question here; only HOW the bytes reach the FPGA. The facts that
  opened it (all measured 14z-107, `docs/platform/mister.md`): at our pin
  `v1.7.3` **64 MB is PHYSICAL**, not a default — jtframe's own table stops
  at `AW 23 = 64 MB`, the bank geometry `COW = AW==22 ? 9 : 10` has no AW=24
  arm (an AW=24 build never drives `addr[9]`, aliasing every address with
  `addr ^ 0x200`), and `sys.tcl` assigns exactly 13 A pins, 2 BA and one nCS.
  The `JTFRAME_SDRAM_XL` 128 MB tier IS real, but UPSTREAM only (added
  2026-06-19, `5981db26`), implemented as **two chips on one module selected
  by the top address bit with chip select on nCS POLARITY**, and reachable
  only inside the `JTFRAME_SDRAM_CACHE` branch. Meanwhile the fit numbers
  (`docs/project/mister_fit.md` §6) say the roster's **total is ~56.1 MB
  against a 64 MB tier** — PRG 6 MB fits bank 0 today, QSound 16 MB fits
  bank 1 today, and only GFX overflows, by ~6.4 MB. The question is
  placement, not capacity.

  **(1) UPREV to upstream master + `JTFRAME_SDRAM_XL` + convert CPS-2 to
  `cfg/mem.yaml` cache lanes.** The architecturally "correct" long-term path:
  the tier is real, CPS-3 already ships on it at ~80 MB, and it leaves room
  for anything later. Cost: a **3057-commit** jump to an **UNTAGGED moving
  target** (v1.7.3, 2024-01-18, is the newest version tag and predates XL by
  ~2.4 years); re-basing our two fork commits; rewriting the whole simulation
  recipe (`test.cpp` -> `verilator/test.cpp` split, `bin/jtsim` rewritten,
  `game.yaml` -> `files.yaml`, `-inputs` now a `.cab` script so
  `sim_inputs.hex` and `tools/rpl2siminputs.py` are orphaned, input bit 1
  coin2 -> service); converting CPS-2 to `mem.yaml`; and **widening the
  shared CPS-1/2 `jtcps1_sdram.v` `[22:0]` code that upstream never widened**
  (its `// change this when moving to 8MB+ GFX` comment is still there on
  master). Requires the 128 MB module.

  **(2) STAY at the `v1.7.3` pin and fit inside 64 MB by BANK REPACK.**
  Vanilla's 32 MB of GFX stays exactly where it is in banks 2+3, so the
  superset invariant is untouched by construction, and the ~6.4 MB of tenant
  art goes into **bank 1, above the PCM** — which after a 16 MB-capable
  QSound carrying 8.9 MB of real content has **~7.1 MB spare** — reached by
  the promoted tile-code bit,
  [**CORRECTED 14z-107 (4): "~6.4 MB into bank 1" is wrong — that is the
  LIVE-BYTE count. The ADDRESS FOOTPRINT is 15.45 MB and needs BOTH banks'
  spare; see `docs/project/mister_map.md` §1.**] i.e. the RTL expression of the profile-gated
  19-bit promote WIDE v1 already makes on FBNeo. No framework uprev, no
  second chip, no `mem.yaml` conversion, and it would run on a 64 MB module
  as well as on the maintainer's 128 MB one. **Risk, named honestly:** object
  reads would share bank 1 with PCM streaming, on the throughput path jtframe
  hand-tunes per target (`jtcps1_sdram.v:167-175`, `OBJ_LATCH` 0 on MiSTer
  "to increase object throughput"), and it is **UNMEASURED**. Measuring it
  also needs the Verilator SDRAM model fixed first (it decodes 8 MB per bank,
  so bank 1 above 8 MB currently aliases in simulation — ~3 constants).
  **BOTH DONE 14z-107 (3): the model is fixed (fork commit 3 — and it was NOT
  ~3 constants; the dropped bit is `addr[22]` on `sdram_a[9]`, not
  `addr[9]`), and the traffic IS now measured** —
  `tests/audit_sdram_bank_load.sh`, `build/sdram_bank_load_14z107.log`.

  **RECOMMENDATION: (2)**, with (1) as the long-term path if upstream ever
  tags again. Rationale: (2) keeps a pinned, reproducible framework and a
  working simulation gate, needs no dual-chip inference, and widens the
  hardware audience rather than narrowing it; (1) trades all of that for
  headroom we do not need at 56.1 MB. **Both options still require the
  core-side FORMAT work either way** — the GFX tile-code promote, the 68k
  `rom_cs` window (including the `0x400000` objcfg collision), and the
  QSound latch/width fix. Gameplay-visible consequence: none under either
  option; the only player-facing difference is that (2) may drop the 128 MB
  hardware requirement to 64 MB.

- ~~**THE SIM HARNESS'S P2 / 6-BUTTON EXTENSION (14z-107, NOT blocking).**~~
  **DECIDED (maintainer, 2026-08-23): option A, LATER** — *"agreed, we can
  do it later"*.
  **SPLIT AND HALF-CLOSED 14z-107 (8). The FIDELITY half is DONE; the
  COVERAGE half remains deferred by the ruling above.**
  * **FIDELITY — SHIPPED, fork commit `519aff8b` (LOCAL ONLY).** It was a
    BUG, not a gap: `SimInputs` held P1's AND P2's buttons 5 and 6 DOWN
    (`&0xf0` and a `0xff` seed on a `[9:0]` ACTIVE-LOW port), so the two
    legs of `test_mister_sim_anchor` were not running identical inputs.
    Measured before the fix against MAME (`RAM:$FF8058/5A/5C/5E`) and fixed
    with `& ~0xf` / `0x3ff`. The anchor was re-measured and did NOT move
    (2146 / 2609 / 463); every §4 field still agrees and the arcade draw is
    the same pair. Session 14z-107 (8).
  * **COVERAGE — STILL DEFERRED, unchanged by the above.** Making buttons
    5/6 and P2 SCRIPTABLE is still fork work nobody has done;
    `tools/rpl2siminputs.py` still refuses `p2=` and `p1=4/5/6` loudly, so
    `02_demitri_vs_cpu` and `04_select_fuzz` still do not translate, and the
    P2-identity fields are still excluded by name in the anchor gate. The
    motivating case is unchanged: a 2P replay would pin the arcade-draw
    opponent. Nothing here is blocked on it.

  Original 14z-107 (7) framing, kept: **UPGRADED FROM COVERAGE TO FIDELITY,
  and the maintainer may want to re-time it: `SimInputs` does not merely
  LACK buttons 5 and 6, it HOLDS THEM DOWN.** `test.cpp:201` is
  `dut.joystick1 = (dut.joystick1&0xf0) | (v&0xf);` and `&0xf0` discards
  bits 9:8 that the line above had just released; joystick is ACTIVE LOW and
  `jtcps2_main.v:266` wires `joystick1[9:7]` into `in1`. So every simulated
  run this lane has taken had P1 holding buttons 5 and 6 from the first
  input line to the last — and only EOF releases them, so a SHORTER input
  file changes the inputs. The MAME leg does not do this, so the two legs of
  `test_mister_sim_anchor` are not running identical inputs; they still
  agree on every mapped field and pick the same P1 record base, so nothing
  measured is invalidated. The fix is one line (`& ~0xf`) in the SAME commit
  as the P2/6-button work, and it WILL move the frozen anchor again — which
  is why it is a deliberate slice and was not done in 14z-107 (7).
  [DONE 14z-107 (8) — and the anchor did not move; P2's buttons 5/6 were
  held too, by the `0xff` seed `parse_inputs()` never corrects.]
  So the fork's third commit is queued, not open: extend
  `test.cpp`'s `SimInputs` (P2 joystick + buttons 5/6, `dip_test` off
  button 4) when a refused replay is actually needed — the motivating one
  being a 2P replay that pins the arcade-draw opponent and retires the
  P2-identity exclusion in `test_mister_sim_anchor.sh`. Original entry:
  **THE SIM HARNESS'S P2 / 6-BUTTON EXTENSION (14z-107, NOT blocking).**
  jtframe v1.7.3's `SimInputs` is P1-only with 4 buttons (bit 11 doubles as
  `dip_test`), so `02_demitri_vs_cpu` and `04_select_fuzz` still REFUSE
  translation — and 14z-107 gave the question a concrete cost: the only §4
  field disagreement on the MiSTer oracle is the 1P ARCADE DRAW picking a
  different CPU opponent (sound-state-fed, `atlas/ram.md:99`), which a 2P
  replay would pin. Options: **(A) extend `test.cpp`'s `SimInputs` in the
  fork now** (a third commit, same macro-gated shape as the WRAM hook — P2
  joystick + buttons 5/6, and a bit for `dip_test` that is not button 4);
  **(B) leave it and keep excluding the P2-identity fields by name**, as the
  gate does today. **RECOMMENDATION: A, but AFTER the profile-shape ruling
  lands** — it is input coverage, not the oracle, and the oracle is green.
  Gameplay consequence: none (test harness only).

- ~~**THE MiSTer PROFILE SHAPE (14z-106, slice B measured).**~~
  **DECIDED (maintainer, 2026-08-23): OPTION A — WIDE v1 VERBATIM on the
  128 MB tier.** *"verbatim indeed: 128MB always was the target."* So there
  is ONE profile and ONE romset across FBNeo / MAME / MiSTer, and the MiSTer
  work is width plumbing only; the 128 MB module is a stated hardware
  requirement in the README.
  **CORRECTION 14z-107 (2), MARKED IN PLACE — THE RULING STANDS, THE
  IMPLEMENTATION ASSUMPTION DOES NOT.** The PROFILE decision above (WIDE v1
  verbatim, one romset, one release artifact) is unchanged and is not
  reopened. Two things attached to it are now measured false:
  (a) ~~"the MiSTer work is width plumbing only"~~ — the CPS-2 core caps GFX
  at 32 MB in the OBJECT FORMAT (16-bit code + 2-bit bank,
  `jtcps2_obj_scan.v:47,152`), the 68k at a flat 4 MB
  (`jtcps2_main.v:184`), scroll at 8 MB with no bank input, and QSound at a
  7-bit latch. **No SDRAM tier lifts any of them**; the GFX one is the same
  19-bit tile promote WIDE v1 already ratified on FBNeo, so it is the
  profile in RTL rather than a new invention — but it is core work, not
  plumbing. (b) ~~the 128 MB tier being a bit-width away~~ — at our pin
  (`v1.7.3`) 64 MB is PHYSICAL (table, row/column geometry, and pin
  assignments all saturate; `docs/platform/mister.md` "The SDRAM ceiling at
  our pin"), and the `JTFRAME_SDRAM_XL` tier exists only upstream, 3057
  commits away, in a branch that also requires `JTFRAME_SDRAM_CACHE`.
  The route is now its own pending decision, **THE MiSTer MEMORY-MAP
  ROUTE**, above. Option B (a tighter MiSTer-only profile) was
  killed by measurement, not preference: 14z-107 read the bank allocation
  (`jtcps1_sdram.v:158-164`, `:332-410`) and GFX ALONE forces the tier —
  bank 0 has ~8 MB spare (so PRG 6 MB fits the CURRENT tier) and bank 1
  holds PCM alone in 16 MB (so QSound 16 MB fits too), while banks 2+3 are
  full at 32 MB. Any GFX above 32 MB needs banks > 16 MB = `SDRAMW` 24 =
  the same 128 MB module, so B buys zero hardware compatibility while
  forking the romset into a second generation. The only route that would
  keep a 64 MB module is a bank-1 repack (GFX sharing the PCM bank, ~6.4 MB
  of its 8 MB spare) — rejected as arbiter surgery on the object-throughput
  path jtframe already hand-tunes per target (`jtcps1_sdram.v:167-175`),
  and it drags a MiSTer-only layout back in anyway. **That repack, not B,
  is the fallback if the 128 MB tier proves unreachable.** ~~OPEN AND BEING
  MEASURED (14z-107, maintainer: *"as to IF we can address... only one way
  to find out!"*): whether `SDRAMW` 24 is parameter plumbing or controller
  surgery in jtframe at v1.7.3, and whether the physical 128 MB module is
  addressable by its SDRAM controller.~~ **ANSWERED 14z-107 (2): NEITHER —
  at `v1.7.3` `SDRAMW=24` is not reachable at all** (no table row, no AW=24
  arm in the bank geometry, `addr[9]` undriven, 13 A pins / 2 BA / 1 nCS
  assigned); the 128 MB tier is upstream-only, is TWO CHIPS on one module
  selected by nCS polarity, and lives only in the cache-lane controller.
  Two knock-ons for the reasoning above: the repack fallback is now a
  first-class option rather than a last resort (**the total FITS 64 MB** —
  ~56.1 MB measured, `mister_fit.md` §6), and the "arbiter surgery"
  objection to it is still the right one to weigh, but so is a 3057-commit
  uprev to an untagged master. Original entry:
  **THE MiSTer PROFILE SHAPE (14z-106, slice B measured).** The numbers
  (`docs/project/mister_fit.md`) remove the roster trade-off: the group-C
  art (6.39 MB) cannot fit vanilla's 32 MB GFX (0.49 MB blank, upper
  bound), so any MiSTer build needs a wider GFX tier than jtcps2's
  documented 64 MB `JTFRAME_SDRAM_LARGE`. Options: **(A) WIDE v1 verbatim
  (PRG 6 / GFX 48 / QSound 16 MB) on a 128 MB SDRAM tier** — one profile
  and one romset across FBNeo/MAME/MiSTer, MiSTer work = width plumbing
  only (jtframe `SDRAMW` 23→24 and +1 bank/prog/ioctl bit, the core's
  `main_rom_addr`/gfx/`qsnd_addr` buses, the 14z-86 QSound latch fix), no
  content change; cost: framework surgery, profile-gated in the fork,
  ONE hardware requirement (the 128 MB module the maintainer has — users
  with 32/64 MB modules cannot run it, which the README must say). **(B)
  a tighter MiSTer-only profile** (e.g. PRG 5 MB / GFX 40 MB / QS 9 MB):
  saves nothing architecturally — every bus still widens by one bit, and
  it forks the romset/manifests/tests into a second generation for no
  gain. **RECOMMENDATION: A.** Gameplay-visible consequence: none; the
  only player-facing fact is the 128 MB requirement.

- ~~**MiSTer ALIGNMENT (14z-106) — five questions before any RTL.**~~
  **ALL FIVE RULED (maintainer, 2026-08-22).** Rulings, then what each
  one commits us to; the original brief follows unchanged.
  1. **Base tree — RULED: a SEPARATE CORE**, so the reference CPS-II
     core stays separately usable; ours respects Jotego's licence(s) and
     is FOSS "if the licensing scheme allows"; the exact fork mechanism
     is left to my proposal. **Facts (jtcores README, checked
     2026-08-22):** jtcores and jtframe are **GPL-3.0** ("you are
     obliged to publish your code if you use mine") — so our core is
     FOSS by obligation, not just preference, and must ship its source.
     **PROPOSAL (my recommendation, open to veto):** (a) a PUBLIC fork of
     `jotego/jtcores` under the maintainer's GitHub, GPL-3.0 retained,
     branched from a pinned upstream tag; (b) a NEW core directory
     (working name `cores/cps2w`, final name TBD) that reuses the cps2
     RTL the way cps1/cps15/cps2 already share it through jtframe
     macros, producing its OWN RBF (`jtcps2w.rbf`) — the stock
     `jtcps2.rbf` is never rebuilt or touched; (c) pinned here as
     submodule `emu/jtcores` on the fork branch, with the fork's diff
     mirrored as `emu/jtcores-patches/0001-*.patch` for review — the
     MAME/FBNeo pattern, and what keeps Rule 1 v2's "small,
     human-reviewable set of declarative lines" honest on a third
     implementation; (d) upstream PR later, at the maintainer's
     discretion — the separate-core shape is what makes one possible.
     FIRST TASK of the arc: read the fork and VERIFY (b)'s sharing
     mechanism — it is my reading of the tree layout, not a measurement.
     **LICENCE GAP SURFACED:** this repository carries NO LICENSE file.
     The core fork is GPL-3.0 by obligation; the licence of THIS tree
     (tools, patches, docs, authored assets) is the maintainer's call and
     is now a pending decision (below).
  2. **Profile shape — RULED: measure first, choose on numbers** (the
     recommendation adopted). Arc task: merged-m6 GFX occupancy per
     group/bank + the real PRG extent, then the fit options.
  3. **Governance/oracle — RULED: the recommendation adopted** — Rule 1
     v2 extends verbatim; jtframe/Verilator SIMULATION is the gate,
     HARDWARE is the field test (the MAME-oracle / playtest split).
  4. **Environment — RULED: MiSTer with a single SDRAM module, plus a
     Jammix extension card**
     **AMENDED (maintainer, 2026-08-23): DUAL SDRAM IS OFF THE TABLE** —
     *"I don't own any nor plan to"*. This forecloses MiSTer's DUAL-SLOT
     path (`SDRAM2_*` / `sys_dual_sdram.tcl`), which was already
     unreachable in jtframe (no `SDRAM2_*` ports on `jtframe_emu`) and
     which conflicts on pins with the analog I/O board the Jammix CRT
     field test needs. **It does NOT foreclose the upstream XL tier:**
     XL is TWO CHIPS INSIDE ONE MODULE in the ONE slot, selected by the
     top address bit with chip-select carried on nCS POLARITY
     (`jtframe_burst_io.v:158`) — i.e. exactly what a standard MiSTer
     128 MB module is (doc/sdram.md catalogue IDs 1/4/8/9 = 2 units).
     Caveat carried: that the module inverts chip 1's /CS is INFERRED
     from the RTL, never measured — so if the XL fallback is ever taken,
     confirm WHICH 128 MB module is in hand first. The chosen primary
     route (the bank repack) needs no such confirmation: it fits a
     64 MB tier and is module-agnostic. (CRT at original resolution/frequencies —
     the field test can be made on real video timing). **OPEN DETAIL:
     which module size?** jtcps2's own docs: CPS2 games with >= 16 MB GFX
     need a 64 MB module; a MiSTer-shaped WIDE (GFX up to 32 MB + PRG +
     QSound 16 MB) needs at least 64 MB and likely 128 MB
     (JTFRAME_SDRAM_LARGE). Confirm before the profile numbers are fixed.
  5. **Distribution — RULED: MRA + RBF over the same release members**,
     covered by the tagged release; stock `vsavj` in the MRA "if
     necessary and/or makes sense — argue for/against". **ARGUMENT:**
     an MRA binds one romset to one RBF, so a stock-`vsavj` MRA aimed at
     OUR RBF is not redundant with the official core's — it is the
     STOCK LEG of the emulator superset invariant on FPGA (the patched
     core running unmodified vsavj must behave as the reference core
     does), i.e. a test instrument that must exist in-tree regardless.
     Shipping it in the release too costs one small XML and buys players
     a same-RBF A/B and a sanity check that their dump is good. Against:
     a second menu entry people may pick by mistake. RECOMMENDATION:
     ship BOTH, the stock one labelled "(stock vsavj — reference leg)".

  ORIGINAL BRIEF: **MiSTer ALIGNMENT (14z-106) — five questions before any RTL.** Built
  only from what the record already measured (`docs/project/cps2_wide.md`
  "Known limits", source-verified 14z-86 at jtcores @1ae053f3 + jtdsp16
  @71fa564a; STATE_HISTORY 14z-85/86). The facts: jtcps15 QSound is LLE
  (jtdsp16 + the real dl-1425), but its sample path is 23-bit with a
  7-bit bank latch, so content in our QSound extension (banks 0x80+)
  would ALIAS onto legacy samples — a ~4-line RTL width fix; the stock
  core caps 68k PRG at 4 MB and GFX at 32 MB (2 x 16 MB) inside a 64 MB
  SDRAM_LARGE map, so WIDE v1 (PRG 6 / GFX 48 / QS 16) does NOT fit and a
  MiSTer-shaped profile is required; a 17-character variant is impossible
  (ruled 2026-08-15 — full roster or nothing).
  1. **Base tree.** Fork jotego/jtcores at which tag/commit, and is the
     intent an upstreamable separate machine (the `vsavjw` pattern — a
     new MRA/core variant leaving stock `vsav` untouched) or a private
     fork? RECOMMENDATION: pin a tag as a submodule under `emu/jtcores`
     exactly as MAME/FBNeo are pinned, carry our change as a patch file
     in `emu/jtcores-patches/`, and shape it as a separate machine so
     the emulator superset invariant has a stock leg to compare against.
  2. **Profile shape (gameplay-visible, yours).** PRG target: 6 MB as
     WIDE v1, or the measured minimum (D+H alone overflow 4 MB by ~310 KB;
     the three-tenant merged image's real extent should be re-measured
     before picking)? GFX must come back from 48 MB to <= 32 MB: which
     tenant tiles get per-slot exclusivity/banking, i.e. what art may
     not coexist on screen? RECOMMENDATION: measure the merged-m6 GFX
     occupancy per group/bank first (the 14z-62/66 census tooling) and
     present the fit options with numbers; do not choose blind.
  3. **Governance and the oracle.** Rule 1 v2 (profile-gated, stock
     `vsavj` bit-identical on the patched core, ratified per profile
     version) should extend verbatim — but MiSTer has no headless
     per-frame work-RAM harness. Is the gate a Verilator/jtframe
     simulation of the core (slow but deterministic and scriptable), a
     hardware capture protocol (the maintainer plays; no RAM checksum),
     or both? RECOMMENDATION: simulation as the gate, hardware as the
     field test — same split as MAME (oracle) vs playtest today.
  4. **Environment.** Does the maintainer have a MiSTer (with the 128 MB
     SDRAM module — JTFRAME_SDRAM_LARGE needs it) and the Quartus
     toolchain, or is simulation the only lane this side? This decides
     who builds the RBF and how fast the confirmation loop is.
  5. **Distribution.** MRA + RBF over the SAME release members as
     `release/merged-m6/` (the patch artifact does not change shape); the
     tagged GitHub release ruled 14z-105 then covers both. Confirm, and
     whether the MRA should also carry the stock-profile `vsavj` entry.

- ~~**ADOPT THE HIT-CLASS MAP EXTENSION + RE-FREEZE huitzil & pyron
  (14z-82b).**~~ **DECIDED 2026-08-12 (maintainer): ADOPTED** — shipped as
  huitzil-m4 (e66678d0) + pyron-m3 (6c7f7322), 14z-82c. Original entry: The generated `hitclass_map_extend` site_thunk fixes a
  playtest-reachable crash LATENT IN BOTH FROZEN TENANT BUILDS (pyron's
  satellite type-64 contact = the f7997 vec3, measured on pyron-m2 solo;
  Huitzil's 68/72 share the pool). Numbers, all measured on a probe build
  (tests/audit_hitclass_map_cost.sh, rerunnable): fix holds through the
  11,017-frame soak that crashes the frozen build; LEGACY BIT-IDENTICAL
  over 30,284 frames on four replays, with a fire census showing legacy
  never enters the map at all [**THAT FIGURE IS RETRACTED — 14z-92 M4
  measured 230 legacy entries corpus-wide; the adoption still stands and
  the argument is "legacy enters and gets vanilla answers"**]. Cost of
  adoption: the row goes in
  huitzil.toml + pyron.toml (shared, dedups on the merge) → BOTH
  verticals re-freeze (new fingerprints; registry rows; their frozen
  masked legacy self-logs re-measured — expected unchanged given the
  zero-fire census, but measured is the standard). Donovan/stock
  untouched. RECOMMENDATION: adopt — it is the third instance of the
  "vs2 widened an index consumer" class (14z-26, 14z-35 precedents) and
  the crash needs one satellite contact to fire in a real match.
- ~~**DONOVAN's map entries 61/62 (14z-82b, separate and smaller).**~~
  **DECIDED 2026-08-12 (maintainer): (a) KEEP VANILLA'S ZEROS** — his
  sword-companion objects' hit-class reactions stay as every shipped
  build has had them; measured unexercised (0 map entries in his
  replays). Revisit only if his satellite hits ever feel wrong in
  playtest — then it is 2 bytes in the generator's policy + a Donovan
  re-freeze. Original entry:
  MEASURED SINCE: his types 59-63 are the projectile-pool objects his
  SWORD-COMPANION machine spawns (61 = the sword-routine region
  x065e5a's family; spawns measured in both his replays), and they enter
  the hit-class map ZERO times in his replays — the missing reaction is
  UNEXERCISED, so (a) costs nothing observable today. Original entry: vs2
  gives his satellite types 61/62 hit classes 0x0E/0x04 where vsavj
  holds the do-nothing 0 — so his type-61/62 projectile hits currently
  produce NO hit-class reaction on every shipped build, and always have.
  The fix above deliberately keeps vanilla's zeros (donovan-m3a
  byte-untouched). Options: (a) keep zeros — shipped behavior, nothing
  moves; (b) adopt vs2's two bytes in the same thunk body — vs2-faithful
  hit reactions for his satellite, at the cost of a Donovan re-freeze
  and a battery re-measure. If (b) is ever wanted, it is a 2-byte change
  to the generator's policy plus the measurements; playtest feel decides
  whether the missing reaction is real. RECOMMENDATION: (a) for now;
  revisit if his satellite hits ever feel wrong in playtest.

- **IF `anim` CANNOT LEAVE THE CRYPT WINDOW — the fallback order is set
  (maintainer, 2026-08-10).** Framing recorded verbatim in effect: *"we'll see
  if and how we can grow the crypt window and still have everything work, or
  if we need to cut down access to a character (in which case I'll leave Pyron
  aside, but that's kind of a last resort)"*.

  So the ladder, best to worst:
  1. **Make `anim` movable** — root-cause the odd pointer. If this works, no
     decision is needed at all, which is why it is the active task.
  2. **Grow the crypt window in the WIDE profile.** A profile change, so
     maintainer-approved by construction, and it must be shown not to break
     anything (the profile's whole justification is the emulator superset
     invariant — `tests/test_wide_profile.sh` / `test_mame_wide.sh` are the
     gates, plus `test_crypt_boundary.sh` since the window's EDGE is what
     would move). Deficit to cover if nothing else changes: **125,560 bytes**.
  3. **Ship two tenants, Pyron aside.** Explicitly a LAST RESORT. Note the
     measured irony: Pyron's reach-constrained set is **0 bytes** — he is the
     cheapest tenant on every axis except his `anim` (111,872). Dropping any
     one tenant frees roughly its own anim, so on space grounds alone the
     choice between them is close to arbitrary; it is a roster decision, not
     an engineering one.

- ~~**THE MERGED BUILD'S `[init_shim]`: ONE SHIM, THREE TENANTS (14z-77)**~~
  **DECIDED 2026-08-10 (maintainer): the recommendation below, in full** —
  adopt phase mode, dispatch flavor per id, gate the write so Pyron stays
  untouched until his polarity is measured against native, then run Donovan's
  battery on a phase-mode build before trusting the merge. **IMPLEMENTED as
  slice G** (14z-77e); the two measurements it names remain OPEN and are
  listed there. Original entry follows.

  Surfaced by slice F's collision measurement — it was one of the three real
  merge blockers, and unlike the other two it was not purely mechanical.

  **The mechanics, measured.** The shim is emitted ONCE per build at ONE site
  (`dispatch_00`'s seed hook, `seed_entry = 0x016C64` — identical in both
  manifests that declare it). It (a) seeds the object pool if the latch is
  clear, and (b) writes the VS2/VH2 **flavor** byte to `+0x3C2` of the player
  struct being initialised, or `flavor_held` when that player's Start is held.

  Three things follow, and only the first is mechanical:

  1. **Flavor polarity is per tenant and already ratified.** D1 (VS2 default)
     means `0x01` for Donovan and `0x00` for Phobos — the polarity differs
     because the engine branch each character tests differs (14z-66 measured
     it against native). A merged shim must write the id-appropriate byte,
     i.e. the same N-way dispatch the thunks need. No decision required.
  2. **`latch_mode = "phase"` is NOT per tenant — the seeder is shared, so a
     merged build either has the gate or does not.** Phobos NEEDS it: without
     it his ecosystem drains pool 0 and the round-2 char re-init re-runs the
     seeder over LIVE pools (14z-65 measured the f4890 wipe, orphaned queues,
     and a freed slot dispatched into palette space). He is in the merged
     build, so **the merged build must carry the gate**, and Donovan's shim
     bytes therefore change — the generator's own comment says his frozen
     bytes stand "until his own re-freeze adopts the mode". The gate only
     narrows WHEN the seed runs (to `$FF800C == 0x40000`, the char-load
     phase), and Donovan's first init is at that phase, so it SHOULD be inert
     for him — but that is an argument, not a measurement, and this project
     does not ship arguments. **Required before the merged build is trusted:
     Donovan's replay battery on a phase-mode build, compared to
     donovan-m3a.**
  3. **Pyron declares NO `[init_shim]` at all.** In a merged build the shim
     runs at char-init for whatever the hosted dispatch covers, so he could
     be given a `+0x3C2` flavor byte he has never had. Whether he reads that
     byte is UNMEASURED. Options: give him an explicit row (needs his own
     polarity measured against native vs2, the 14z-66 procedure), or gate the
     flavor write so only tenants that declare one receive it.

  **Recommendation:** adopt phase mode for the merged build (2 is forced),
  dispatch the flavor bytes per id (1), and gate the write so Pyron is
  untouched until his polarity is measured (3, the conservative half) — then
  measure Donovan's battery before trusting the merged build. The alternative
  worth the maintainer's attention: if Donovan's battery DOES move under phase
  mode, the fallback is a per-id gate on the phase check itself, which is more
  emitted code at a shared site and wants explicit sign-off.

- ~~**THE BEAM'S LIST-TYPE 12: FLATTEN, OR RATIFY THE HOOK? (14z-71)**~~
  **DECIDED 2026-08-09 (maintainer): NEITHER — take over the dead
  list-type 6**, with the explicit condition that the deadness assumption
  must not be load-bearing. Built as `build/hui20`; see the 14z-71
  RESOLVED section. The maintainer's framing, kept because it generalises:
  *"there is almost always a chance it actually wasn't dead and we just
  missed how it was used... if we encounter regressions in vanilla
  assets/engine, this is one of the first places to check, and should we
  ever encounter something that uses list-type 6 that we didn't know of,
  we should stop, analyse and assess the situation before continuing."*
  That is now enforced by construction (the vanilla fallback) and by a
  gate (the `$FF010C` tripwire), not by memory. See THE DEADNESS REGISTER
  below.

- **THE 14z-62e SELECT-ART ANALYSIS (decided above).** The
  last visual-de-substitution piece: the tenant's select-art subset (101
  bank-1 tiles + 4 placeholder label tiles + the 6-tile medallion) still
  overwrites Jedah's bank-1 select-figure art, garbling his select-screen
  BODY (face/name/match art are all back). Two measured options:

  **A — a per-hover bank thunk + group C (recommended).** The select
  FIGURE object's bank already follows the hovered char through the
  engine table (measured: `PRG:0x05F9EC` jsr's the bank helper; hovering
  the tenant writes 0x1000 and his standing figure draws from group C
  TODAY). The PORTRAIT-record object instead gets bank 1 ONCE at venue
  init (`PRG:0x07C428`). Option A thunks the per-hover record-pointer
  consumers (`PRG:0x05F328`/`0x06C0E0`) to also set that object's bank:
  hovered==tenant -> 0x1000, else -> 0x2000 (the value it already holds,
  so pure-legacy RAM is byte-identical; after a tenant visit the restore
  re-converges). Select art then lives in group C at native codes — NO
  fit problem — and `vsav.zip` leaves the rompath ENTIRELY PRISTINE.
  Cost: a new engine hook on the select path (cycle-only for legacy; the
  ratified hook class, but the re-freeze's flicker/window inventory must
  be re-measured with it in — the standing watch applies). The name/
  highlight-piece objects' banks need the same treatment (their sites
  are one measurement away, same method).

  **B — relocate into blank bank-1 space, no hooks.** Vanilla bank 1 has
  2,917 blank tiles (largest runs: 881 at 0xBE90-0xC200, 460 at 0x3634,
  357 at 0x6C9C — measured). Placing the ~117 tiles there needs a NEW
  greedy fit (block-geometry aware), a reference-exclusivity proof for
  the chosen ranges (blank != unreferenced: a legacy record could use
  blank tiles as transparent filler, and art there would APPEAR — the
  proof method is the medallion's whole-image scan), and `vsav.zip`
  stays patched-but-additive (nothing of Jedah's overwritten). Zero
  engine hooks, zero legacy cycle cost.

  **Recommendation: A.** It finishes the artifact story (pristine
  vsav.zip — the strongest possible provenance), reuses the established
  thunk pattern and the already-poked bank table, and avoids a new fit +
  exclusivity-proof toolchain for a one-off. The hook's legacy cost is
  cycles only, in the class the basis already tolerates; it will be
  measured before the re-freeze ratifies anything. B stays the fallback
  if the measured hook cost violates the standing watch.


- ~~**RATIFY A COMPOSITE §4 CLASS? (14z-61)**~~ **RATIFIED 2026-08-06
  (maintainer: "Your proposal is ratified").** CLAUDE.md §4 amended: the
  `composite` class is the strict CONJUNCTION of flicker-tolerated and
  bounded re-convergent window, adding no tolerance to either. The seven
  `.pending` expectations became `.masked` `composite` specs carrying the
  shapes they had already printed, and the WIDE reference freeze is
  complete — `run_suite.sh` on `donovan-m5w` is GREEN, all 63 replays
  validated or explicitly skipped. Original entry below.

- **RATIFY A COMPOSITE §4 CLASS? (14z-61) — the analysis behind the
  decision above.** Seven legacy replays measure as the frozen
  hook-flicker inventory PLUS one bounded re-convergent window per
  select-screen ENTRY (table in 14z-61). Both halves are already ratified —
  `flicker` (§4 v2) and `window` (§4 v3) — but no single class expresses
  their conjunction, so those replays cannot be frozen without either a new
  class or a fudge. They are `.pending` and fail the suite meanwhile.

  **Proposal: `composite <baseset> <flicker-csv> <window-list>`**, defined
  as the strict CONJUNCTION of the two: every divergent run must be
  accounted for by name, the flicker set must match the frozen inventory
  exactly, the window list must match exactly, and the run must fully
  re-converge. It tolerates nothing that `flicker` and `window` do not each
  tolerate, and it is strictly stronger than either alone.

  Implemented and ground-truthed ahead of the decision so ratification is
  one word rather than a session: `tools/compare_composite.py`,
  `tests/test_compare_composite.sh` (7 synthetic cases + a no-loophole
  check — extra flicker frame FAILS, missing flicker frame FAILS, onset
  moved one frame FAILS, no re-convergence FAILS, bit-identical FAILS, an
  unfrozen second window FAILS). **Nothing validates against it until you
  say so**: accepting means turning each `.pending` file into a `.masked`
  one carrying the spec it already prints.

  **Recommendation: ratify.** The alternative readings are worse — calling
  these replays `skip` hides a real comparison, and widening `flicker` to
  swallow a 900-frame run would be the loosening §4's standing watch exists
  to prevent.

- ~~**FREEZE THE WIDE TRACK? (14z-61).**~~ **DONE 2026-08-05 (maintainer:
  "yes freeze and register as wide reference first, then we resume").**
  `9bac6ee3 -> donovan-m5w`; see 14z-61. Original entry below.

- **FREEZE THE WIDE TRACK? (14z-61) — the analysis behind the decision.** `build/m5_wide` (`9bac6ee3`) is now
  playtest-confirmed with and without Donovan, both WIDE profile gates are
  green, and the new rendering + member-identity gates are green. The
  registry convention is that rows are added at FREEZE time as a STATE.md
  decision, so this is not mine to do.
  **Recommendation: freeze and register it** as the WIDE reference
  (`donovan-m5w` alongside `donovan-m2c`), for one specific reason beyond
  bookkeeping: M3a moves the tenant from `0x0F` to `0x13` and will churn
  the select records, the thunk id and the bank-table row at once. Without
  a registered WIDE reference, a regression during that work has nothing to
  bisect against on this track — which is exactly the position that made
  the sprite garble expensive.
  Cost if we skip it: none today; the risk is only felt later, and by then
  the build may not be reproducible from the tree.

- **THE SELECT SCREEN AND THE SUPERSET INVARIANT (14z-60r).** Drawing three
  new medallions requires the wheel OBJ record to grow from 18 to 21
  entries and its coordinate list likewise. Measured: neither can grow in
  place (another record starts immediately at `0x272ABA`; the coord list is
  immediately followed by the shared global pool), so both must relocate —
  cheap, one referrer at `PRG:0x2689FE`. **The problem is not placement, it
  is the invariant.**

  The record's `count` word changes and its `budget` word is debited from
  the OBJ emitter's shared per-frame budget — GOTCHAS records that exact
  coupling flipping a borderline skip decision into a one-byte work-RAM
  divergence. Three more sprites also render. **So any legacy replay that
  reaches the select screen will diverge in RAM.** M2b's select work avoided
  this by strict in-place replacement preserving the host's budget word;
  adding CELLS makes that impossible by construction.

  CLAUDE.md §1 covers "any match, **menu path**, or attract sequence", so
  this needs an explicit ruling rather than an assumption:

  **A — a bounded select-screen carve-out (recommended).** Legacy replays
  are compared as today up to select entry, and the select-screen
  divergence is MEASURED, mechanism-attributed and frozen per replay, in
  the same style as the existing `diverge` constants and masked windows.
  Rationale: the invariant's purpose is that vanilla *gameplay* is
  untouched, and a select screen that offers three more characters is by
  definition content that involves them. Condition: the divergence is
  measured and frozen BEFORE acceptance, never accepted blind, and must not
  extend past the select screen into match state.

  **B — keep the wheel vanilla**, reach the newcomers by another mechanism
  (the option-2 hold-Start alternates the maintainer already ranked lower).
  Preserves the invariant literally; costs the decided roster UX.

  **C — attempt a RAM-neutral extension.** Not viable: the budget word must
  cover the entries actually emitted, and three extra sprites change OBJ RAM
  regardless. Recorded so it is not re-proposed.

  **Recommendation: A**, with the measurement done first so the ruling is
  made on a number rather than on a prediction.

  **MEASURED 2026-08-05 (14z-60s), and the number is good.** Built
  (`select_wheel roster21`) and compared against the previous WIDE build on
  the masked basis, so the wheel change is the only variable:

  | replay | frames | divergent | window | after |
  |---|---|---|---|---|
  | `04_select_fuzz` | 3520 | 162 | 890-1051 | 2469 identical |
  | `02_demitri_vs_cpu` | 5520 | 733 | 890-1622 | 3898 identical |
  | `03_two_player_vs` | 5320 | 913 | 890-1802 | 3518 identical |
  | `09_mirror_pick` | 4720 | 993 | 890-1882 | 2838 identical |
  | `05_timeout_idle` | 12120 | 733 | 890-1622 | 10498 identical |

  Every replay: **onset at frame 890 — select-screen entry — exactly ONE
  contiguous run, and FULL RE-CONVERGENCE.** Match state is bit-identical
  in all five, including a complete timeout match (10,498 identical frames
  after the window closes). The divergence is confined to the screen we
  deliberately changed and reaches nothing else.

  That is a **stronger** guarantee than the existing frozen-`diverge`
  class, which never re-converges at all. The proposal for ratification is
  therefore a new comparison class: **"bounded select-screen window,
  re-convergent"** — onset frame, window end and run-count frozen per
  replay, with re-convergence and match-state identity as the assertions.
  Mechanism: select-screen init caches the record pointer we repointed
  (`GOTCHAS` class 4), which is why onset is identical across replays.

- ~~**THE `0x360+id` ANIM BLOCK (14z-60)**~~ **DECIDED 2026-08-05
  (maintainer): option A, INHERIT — "since we can. If it fails, we'll
  fall back to option B (relocation)."** So a newcomer at `0x13` plays
  anim `0x363` from the shared `0x360-0x36F` block, exactly as vsav2
  ships; sites `PRG:0x003E40` and `PRG:0x004082` stay folded and are
  recorded as `inherit` in the tenant manifest. Fallback if playtest shows
  the inherited animation is wrong for a newcomer: relocate the block to a
  free 32-wide anim-number range and widen both masks. Original write-up
  kept below.

- **THE `0x360+id` ANIM BLOCK (14z-60) — the analysis behind the decision
  above** — of the seven sites that fold the
  character id to 4 bits, five are ordinary porting work; two
  (`PRG:0x003E40`, `PRG:0x004082`) compute a per-character anim number in a
  block that is genuinely 16 wide (`0x360-0x36F`, with `0x370+` already
  occupied). **Option A: inherit** — a newcomer at `0x13` plays `0x363`,
  which is exactly what vsav2 ships, Capcom having left both folds in
  place. **Option B: relocate** the block to a free 32-wide range and widen
  both sites — a numbering audit plus shared-engine edits, for a family we
  cannot yet name. **Recommendation: A**, on the strength of vs2 being a
  shipped existence proof; revisit only if a playtest shows the inherited
  animation is wrong for a newcomer. Detail in session 14z-60 and
  `docs/game/atlas/id_space.md`.

- ~~**M5 SOUND NEEDS A DATA HOME (14z-52)**~~ **SETTLED 2026-08-04 by the
  dual-track decision below: it lives in `wide_ext`.** Two corrections to
  the record that got it there:
  **(a) Option B was DEAD and the recommendation was wrong.** It proposed
  reclaiming the "inert since 14z-31" `weapon_accent_t0/_t1/rowd_slot`
  rows. Measured 14z-59g: those are `data_port` rows writing 0x20 bytes
  each to `0x39FBE0-0x39FC40`, which is in NEITHER hole (`hole_a`
  `0x0BF6A0-0x100000`, `hole_b` `0x3EC720-0x400000`). They are in-place
  palette overwrites, not hole allocations, so reclaiming them frees
  **zero** of the 352 bytes needed. The original entry mistook them for
  hole tenants.
  **(b) Option C stopped being expensive.** It was rejected as "larger
  blast radius" before WIDE existed; WIDE is now demonstrated on both
  emulators, so it is the cheap option — and option A (Jedah's anim
  region) keeps its unaudited dead space AND stays available for the
  ported select web, which was its earmarked purpose all along.

- ~~**M5 VOICE SAMPLES (14z-51)**~~ **DECIDED 2026-08-04 (maintainer):
  "A then B, gates stay strict, option C is rejected."** Ship M5 with those
  specific sounds silent now (option A — it matches the current
  silent-by-design behaviour for exactly the sounds that cannot be
  faithful); revisit growing the QSound sample region (option B) at M3,
  when Huitzil and Pyron force the same question at scale, inside the
  measured 16 MB ceiling. **Option C (overwriting low-value vsav content)
  is rejected** and may not be re-proposed — it is superset-invariant-
  adjacent. Original entry with the full option analysis kept below.

- **M5 VOICE SAMPLES (14z-51) — the analysis behind the decision above:**
  6-8 of Donovan's sounds (his voice
  lines / vs2-new sfx: ids 0x71D/0x73E/0x753-0x756, likely the "Change
  Immortal" family) do not exist in vsav's sample ROMs, which are
  byte-full. Options: A) ship M5 with those specific sounds silent
  (shared sfx all restorable regardless); B) grow the QSound sample
  region via driver descriptor (vm3.11m/12m from 4MB->8MB members or
  add members; CLAUDE.md rule 1 permits load-map changes; MiSTer
  impact unknown); C) overwrite low-value vsav content (risky,
  superset-invariant-adjacent). Recommendation: A now (matches the
  current "silent by design" behavior for exactly the sounds that
  cannot be faithful), revisit B at M3 when Huitzil/Pyron force the
  same question at scale.
  **UPDATED 14z-59f — option B now has a measured hard ceiling.** CPS-2
  WIDE v1 already declares QSound at **16 MB, which is MAME's maximum**
  (`qsound_device` is a `device_rom_interface<24>`, 24 address bits). So
  B is available and proven on both emulators up to 16 MB and NOT ONE
  BYTE further: growing past it would mean widening a SHARED MAME device,
  which is outside Rule 1 v2. If Donovan + Huitzil + Pyron voice banks do
  not fit in the 8 MB the profile adds, the answer has to be exclusivity
  or banking, not more region. Worth sizing that before committing to B
  at M3. (Two duplicate copies of this entry were merged here.)

- ~~**ROSTER ACCESS MECHANISM**~~ **DECIDED 2026-08-04: option 1, an
  altered select screen keeping the existing cells and appending the three
  newcomers; hold-Start alternates are the fallback. See 14z-59l.**
- See SPEC §7 for the rest. Nothing blocks current work.

- ~~**THE REPOSITORY LICENCE (14z-106).**~~ **DECIDED (maintainer,
  2026-08-22): GPL-3.0 for everything** — `LICENSE` added (the FSF text
  verbatim), README "Licence" section. Original entry: The tree has no LICENSE file.
  The jtcores fork is GPL-3.0 by obligation; the licence of THIS tree
  (tools, patches, docs, authored assets — never ROM bytes, rule 7) is
  undecided. Options: GPL-3.0 across the board (simplest, one licence
  for the whole deliverable); MIT/BSD for tools + GPL-3.0 only for the
  core fork (more permissive tooling, two licences to explain); CC for
  docs/assets on top of either. RECOMMENDATION: GPL-3.0 for the whole
  tree — one licence, compatible with the core by construction, and the
  maintainer's stated wish is FOSS. Maintainer's call.

## THE DEADNESS REGISTER (opened 14z-71, maintainer's standing instruction)

Every claim of the form **"legacy never reaches this, so we may reuse
it"**. Each is measured by ABSENCE, which is the weakest kind of evidence
we accept, so each is listed here with its guard. **These are the FIRST
PLACES TO CHECK for any unexplained regression in vanilla assets, engine
behaviour or rendering** — before anything else is suspected.

| Reused resource | Claim | Guard | Fallback if wrong |
|---|---|---|---|
| ~~palette-seq ids 0x1E-0x21 (`0x39ACC0`)~~ **CLAIM FALSE, ROW WITHDRAWN 14z-79 (they are Bulleta's DF block)** | vanilla only ever requests 0x26/0x27 | `tests/audit_palette_seq_ids.sh` (10,504 sampled calls) | none — the palette path never transits work RAM, so the audit is the ONLY guard |
| effect-class row 16 (`0x080AEC`) | vanilla never dispatches class 16 | `tests/audit_effect_class_rows.sh` §1, 0 reads vs a 1760-hit control | none needed: the row was a stub (`rts`), so a wrong claim costs at most the old no-op |
| ~~drawer list-type 6 (`0x01B6AA`)~~ **CLAIM FALSE (measured 14z-89) — LEGACY LISTS DO REACH TYPE 6** | vanilla has no type-6 sprite lists | `audit_effect_class_rows.sh` §1/§4 + `tests/test_beam_list_type6.sh` | **THE FALLBACK HELD — this is what a safe-and-loud design buys.** 14z-89 measured the tripwire ARMED on legacy content on huitzil-m13: `21_don_mash` 387 times and `26_don_arcade_mash` 948 times, PC-attributed to inside the thunk body (0x0FD060). Rendering stayed correct throughout (the fallback runs vsav's own type-6 code, reproduced instruction-for-instruction), so nothing rendered wrong and no playtest ever saw it — exactly the outcome the register's "prefer designs where being wrong is safe and loud" rule was written for. WHY IT WAS MISSED: the deadness measurement was sound but its COVERAGE was four replays (`02/07/09/30`), and the gate has always run on that default set; the two replays that arm it are long mash/arcade rigs nobody pointed it at. COST TODAY: `$FF010C/$FF010D` is a live work-RAM counter vanilla does not keep, so both replays diverge permanently from the vanilla masked basis — they are `.pending` on huitzil-m13 pending the maintainer's ruling. OPEN: does the fallback need to stop counting (make the tripwire diagnostic-only / move it out of work RAM), or is the counter acceptable? See "Decisions pending — 14z-89" |

Rules for adding a row: the claim must be measured with a POSITIVE CONTROL
on the same instrument and leg (a blind instrument and a real zero look
identical — paid for three times in 14z-71); it must name its guard; and
it must say what happens if the claim is wrong. Prefer designs where being
wrong is *safe and loud* over designs that are merely well-measured.

## Open bugs

- ~~**WIDE sprite garble (14z-60y)**~~ **FIXED 2026-08-05 (14z-61).** Not a
  rendering defect: the shipped WIDE romset carried group C as byte copies
  of the stock group B, so those copies held group B's CRCs and the loader
  — which resolves by hash before name — served PRISTINE tiles for the
  members the build had patched. Fixed in the pipeline (shippable overlay
  zero-filled, canary romset separated, `tools/audit_romset_identity.py`
  wired into the build), verified on both emulators with pristine and
  stock-track controls, and gated by `tests/test_wide_render_content.sh`
  (pixel A/B vs the stock track + a positive control) and
  `tests/test_romset_identity.sh`. Full write-up: session 14z-61.
  **CLOSED — maintainer playtest of `build/m5_wide` (`9bac6ee3`) confirms
  it**, with and without Donovan: no regression, graphics good, gameplay
  genuine, sounds good.
- ~~Minor win-screen palette issues~~ **FIXED 14z-68m** (build/hui11):
  the palette source is the OPCODE-view remap table, and the portrait
  position row needed vs2's own values. Gate: `tests/test_hui_winscreen.sh`.
- **OPEN (cosmetic):** Huitzil's win QUOTE text — root-caused, not built.
  The consumer's `lea -4(a0,d0.w)` bias means it reads index 0x60+id-1.
- **OPEN:** FG pacing — untouched.

## Findings log

- 2026-07-25: key masters — vsavj `0xfa8f4e33a4b881b9` (watchdog
  `cmpi.l #$726A4BAF, D0`), vsav2 `0xd681e4f460371edf`, vhunt2
  `0x36c1eba326b10f18` (vsav2/vhunt2 share watchdog
  `cmpi.l #$06920760, D0` — sibling builds). All three: encrypted range
  `PRG:0x000000-0x0FFFFF` only (first 1MB of 4MB). Decryption of all three
  proven bit-identical to MAME (`tests/test_decrypt_oracle.sh <set>`).
- 2026-07-25: ROM file byte order ≠ 68k logical order; cost ~1h; conventions
  locked and oracle-tested (docs/GOTCHAS.md).
- 2026-07-25: MAME 0.288 vsavj boots and runs attract deterministically
  headless (`-video none -sound none`, fresh sandbox per run).

## Integration notes — SMS docs (imported 2026-07-24)

Conventions live in CLAUDE.md §4/§5 now; taxonomy files exist as of this
session. Still to mine when relevant (park, don't re-derive):
- SMS `coltest.lua` pattern (scripted char-select navigation → saved match
  state) for generating the 18×18 matrix states in M4.
- `trace.lua`/`trace_plan.lua` config shape for the CPS-2 input logger.
