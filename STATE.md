# STATE — living progress log

## Session 14z-108 — **THE SIM HARNESS'S DIRECTION BITS WERE REVERSED END FOR
## END, NOT TRANSPOSED IN TWO — measured on all four before one bit was
## changed, and the half nobody had exercised is where the previous reading
## was wrong.** `tools/rpl2siminputs.py` fixed (one dict, no fork commit, no
## RTL), verified against the game's own input mirror on both
## implementations, and the gate rebuilt with a per-direction lock and a
## must-fire control. **One of the two frozen expectations the record said
## would move DID NOT MOVE AND COULD NOT** — which also means the frozen sim
## anchor could not move. Obj bank 4 is unblocked and running.

**The opener, and it was the whole point of doing it in the stated order.**
`docs/NEXT_SESSION.md` said: measure all four directions BEFORE changing
anything, because what existed was two data points and the inference on the
table was an inference. It was wrong, and the order caught it.

### THE MEASUREMENT

`tests/replays/107_four_directions.rpl` — U, D, L, R one at a time, 5 frames
each, 40 frames apart, **attract only: no coin, no start, no roster
content**, so this is a property of the INSTRUMENT and runs on stock `vsavj`
in ~15 min instead of a boot-to-select run on the WIDE image. Read off the
game's own P1 input mirror `RAM:$FF8058.w` on both implementations, MAME
against `cps2w` under Verilator, both dump sets integrity-checked (151 and
176 frames), **20 nonzero frames on each leg = exactly the 4 presses x 5
frames the replay scripts**:

| asked | MAME | core, pre-fix | delivered | core, post-fix |
|---|---|---|---|---|
| Up    | `0x0008` | `0x0001` | Right | **`0x0008`** |
| Down  | `0x0004` | `0x0002` | Left  | **`0x0004`** |
| Left  | `0x0002` | `0x0004` | Down  | **`0x0002`** |
| Right | `0x0001` | `0x0008` | Up    | **`0x0001`** |

**THE NIBBLE IS REVERSED END FOR END.** 14z-107 (12) had seen only Left and
Down — the only directions `36_pick_tenant_cell` presses — and inferred a
two-bit SWAP leaving Up and Right untouched, on the strength of the
translator's own docstring. **Up is not untouched: it arrives as Right.** A
two-bit fix would have left half the defect in the tree and the gate would
have frozen it.

**MECHANISM, derived from the bit ORDER and then confirmed.**
`test.cpp:380` copies the file's bits 4-7 straight onto `joystick1[3:0]`, and
jtframe's joystick port is **MSB-FIRST** — `joy[3]=Up [2]=Down [1]=Left
[0]=Right` (`jtframe_keyboard.v:107-110`, the authoritative order;
`_JTFRAME_JOY_RLDU` being a full nibble reversal is only consistent with
that). So the file map is `bit4=Right bit5=Left bit6=Down bit7=Up`, and the
translator had read the macro NAME "UDLR" as "bit4=Up … bit7=Right".

**FAULT ATTRIBUTION: OURS, NOT jtframe's** — unlike the three input-path
defects before it, which were upstream and fixed in the fork. jtframe
documents no `sim_inputs.hex` direction spec; the nibble is simply
`joy[3:0]`. **Fix = one dict. No fork commit, no RTL.** The fork pin is
unchanged at `7b9a0d2d`.

### THE FROZEN EXPECTATIONS: ONE MOVED, ONE COULD NOT

The record said in FIVE places that a bit-map fix would move both of
`test_rpl2siminputs`'s frozen values. **It moved one.**

* check 1's vector: `111 6ee 000 000 080` -> **`181 67e 000 000 010`**,
  re-derived by hand with the mechanism named in the gate header.
* check 3's `05_timeout_idle` sha1 `eb3e1d04e58b3a2b7bf713d40c4d6ac4796e550c`
  **did not move and cannot**: that replay scripts a coin, a start and one
  button-1 tap and **no direction token**.
* **Therefore `test_mister_sim_anchor`'s frozen anchor (MAME 2146 / sim 2609 /
  skew 463) could not move either** — its replay is `05_timeout_idle`, whose
  `sim_inputs.hex` is byte-identical across the fix. It was NOT re-run, and
  the gate header states that as the reason rather than leaving it to be
  assumed. That is a 45-minute gate not run on evidence, not on convenience.

Corrected in place in `STATE.md` (the 14z-107 entry), `NEXT_SESSION`,
`docs/platform/mister.md`, `docs/platform/gotchas.md`, `docs/GOTCHAS.md` and
`HANDOFF.md`. **It mattered: "expect it to move" is how a hash gets re-frozen
without anyone asking why.**

### THE GATE, REBUILT (11 checks, all green)

* **check 5** locks each direction to its measured file bit individually.
  Check 1 presses three directions at once and would pass under ANY
  permutation of the four — which is exactly how the reversal survived.
* **check 5b** is a MUST-FIRE CONTROL: it rebuilds the pre-14z-108 reversed
  map and requires check 5 to reject it.
* **check 6** asserts the anchor-independence MECHANISM directly (05 sets no
  direction bit) instead of resting on a hash, with **6b** its positive
  control.
* **AND 6 PASSED FOR THE WRONG REASON IN ITS FIRST DRAFT** — it used gawk's
  `and()`/`strtonum()` on a BWK awk, so awk exited 2 and the `else` arm read
  as success. Caught by writing the control before trusting the check. THE
  INSTRUMENT PROTOCOL, working on the session that wrote it into a gate.

### THE BANK-LOAD AUDIT CAN NOW TAKE A REPLAY, AND REFUSES TO MISLABEL IT

`tests/audit_sdram_bank_load.sh --rpl FILE` (+ `--stats` on both legs of
`test_mister_gfxc_fetch`), so the tenant match answers the FETCH question and
the BANK-1-UNDER-LOAD question from ONE simulation instead of a third
70-minute run. The four phase boundaries are absolute frames keyed to
`05_timeout_idle`'s anchor, so with `--rpl` the phase table is **REFUSED**
and whole-run figures + the clash count are reported instead.

**THE NEW BLOCK WAS WRONG FOUR TIMES AND EVERY ONE WAS CAUGHT BEFORE USE** —
cumulative counters read as per-interval (means in the tens of millions);
`t` read as a reporter index rather than picoseconds (frame numbers in the
billions); the bare substring `SDRAM reads clashed` counted, which scores
this report's OWN PROSE as evidence (and
`build/sdram_bank_load_14z107.log` is exactly such a file — it is a REPORT,
not a `jtsim.log`); and a "peak" of 100,614 acc/frame IDENTICAL on all four
banks, which is the ROM DOWNLOAD — one write command per byte at a constant
rate to one bank at a time. Validated by construction on synthetic logs
(rates of exactly 10/5/2/3 per frame read back exactly; a pre-transfer
sample that must be dropped, and is; 3 real WARNING lines counted as 3, the
same text as prose counted as 0), and the default path still reproduces the
frozen 14z-107 table unchanged.

### RITUAL

- **THE ROLLOVER EXECUTED, exactly as the 14z-107 CLOSE (final) specified
  it**: the 14z-107 sub-entries **(1)-(9)**, nine sections and 1,582 lines,
  moved BYTE-VERBATIM to the top of `STATE_HISTORY.md`'s body. Verified
  lossless (identical sha256 in the archive; no rolled header remains here).
  **STATE.md 261,112 -> 160,634 B** — the first time since the split that it
  is near the ~150 KB the rule names. **First time a group's SUB-ENTRIES have
  rolled while the group stays live**, which the rule does not contemplate:
  it speaks of whole groups and THE LEDGER carries one line per group, so
  nothing was added to the ledger and a pointer paragraph names all nine.

## Session 14z-107 CLOSE (final) — ritual complete. **THE WIDE ROMSET BOOTS
## ON THE CORE, DRAWS OUR SELECT SCREEN AND FETCHES OUR WHEEL ART — AND NO
## TENANT HAS EVER FOUGHT ON IT.** Six RTL slices are in (D0-D5), the boot
## failure is root-caused and fixed, obj bank 5's 105 tenant tile codes are
## measured, bank 0's traffic under the redirect is ANSWERED, and obj bank 4
## is still zero for a reason that is the HARNESS.
## **THE ARC'S HEADLINE IS METHODOLOGICAL: SEVEN INSTRUMENT AND HARNESS
## DEFECTS HAVE BEEN FOUND IN THIS LANE, AND EVERY ONE OF THEM WOULD HAVE
## READ AS AN RTL FAULT. D5 IS THE COUNTER-EXAMPLE, WHERE THE RTL GENUINELY
## WAS AT FAULT.**
## This is the SECOND close of 14z-107; the first (below) covered slices
## D0-D2, and FOURTEEN commits stand between them.

**The session since the first close, in one line:** the MiSTer arc went from
"the placement is in the RTL and nothing has ever driven it" to "the WIDE
romset boots, the select screen renders with our extended wheel and our
authored M6 mark on it, and 105 distinct tenant tile codes come out of SDRAM"
— and the last thing between it and a tenant FIGHTING on the core turned out
to be two swapped bits in the simulator's joystick.

### THE HEADLINE, BECAUSE IT IS THE PART THAT TRANSFERS

**Seven defects in the MEASURING APPARATUS, every one of which presented as a
defect in the thing being measured.** The first close reported three; the
count is now seven, and four of them are the INPUT PATH alone.

| # | the instrument | the false verdict it would have supported | how it was caught |
|---|---|---|---|
| 1 | the Verilator SDRAM model dropped `addr[22]` — it rides `sdram_a[9]` as the tenth COLUMN bit, not `addr[9]` (14z-107 (3)) | "jtcps2's GFX addressing is faithful"; no video or sprite result from the lane was trustworthy for wide GFX at all | derive from the RTL, not from the SIZE — *a size tells you how many bits are missing, never which one* |
| 2 | the forked frame writer `exit(0)`'d, `fclose()`ing the parent's inherited `sim_inputs.hex` `FILE*`; POSIX rewinds the SHARED offset (14z-107 (7)) | "D1's RTL moved the anchor" — four 50-minute runs blamed the RTL, and the FROZEN number was the artifact | a 2x2 factorial on `pal_lut.hex` x frame-output, 681 dumps a leg: the RTL axis moved nothing, the HOST axis moved everything |
| 3 | jtframe's `SimInputs` held P1's **and P2's** buttons 5 and 6 down — two 8-bit constants on a `[9:0]` ACTIVE-LOW port (14z-107 (8)) | every agreement the §4 oracle had ever reported was an agreement about a different machine | a MAME hold-vs-not differential located the game's own input mirror `$FF8058`, and the pre-fix sim block was BYTE-IDENTICAL to MAME with four buttons held |
| 4 | `JTFRAME_SIM_WRAMDUMP_OFF` hard-coded to bank 0 byte `0x600000` — work RAM on `cps2`, **VRAM on `cps2w` after D2's re-pack** (14z-107 (9)) | "`test_mister_wide_inert` is red, so D2 broke inertness" — 101 frames of 101, comparing one core's work RAM against the other's VRAM | VRAM is a plausible 64 KB of changing bytes, so the non-constancy check passed; **any instrument naming a PHYSICAL address is invalidated by a memory-map change, and a placement slice IS one** |
| 5 | the PRG probe's first draft split its window on `rom_addr[21]` — `rom_addr` is `[22:1]` driven `A[22:1]`, so its INDEX is the address bit and `[21]` is `A[21]` (14z-107 (11)) | "2,560 reads above `$400000`" — a healthy-looking COUNT at `$38C2A0-$3D8256`, which is the third megabyte | only the ADDRESSES contradicted the label, and only because the probe logged them beside the classification |
| 6 | `tools/prgprobe_verdict.py` judged only the RAW SDRAM word (14z-107 (11)) | **"D4 WORKS"** — over ten fetches the CPU received as garbage. A verdict bug of exactly the kind CLAUDE.md §4 forbids | the DATA half of the probe logged the latched word too, so the tool could be caught disagreeing with itself |
| 7 | the sim harness's DIRECTION BITS are REVERSED end for end — measured on all four 14z-108; 14z-107 (12) saw only the Left/Down half and inferred a two-bit swap | **"D3 does not fetch"** — the obj-bank-4 measurement returned exactly zero reads, in-match included, with the RTL innocent in every respect | the RENDERED frame: a VS screen showing a LEGACY character against a replay that asks for a tenant. The counters alone said the promote was dead |

**Two more were found INSIDE a gate on its own first real measurement**
(`test_mister_gfxc_fetch`, 14z-107 (11)), both fixed: the tile code computed
from the ABSOLUTE SDRAM address instead of relative to the armed window's base
(a correct promote read as `0x170D6-0x1FA41`), and a liveness control that
demanded vanilla obj traffic in the CONTROL leg — an image that cannot boot by
construction, because with the profile clear its group-C art aliases over
vanilla's obj banks.

**AND D5 IS THE COUNTER-EXAMPLE, WHICH IS WHY THE STANDING RULE IS "SUSPECT
THE INSTRUMENT", NOT "BLAME THE INSTRUMENT".** There the reference RTL
genuinely was at fault, and no amount of instrument hygiene would have found
it — only a byte-level comparison of what the CPU LATCHED against what memory
HELD.

**The protocol distilled from all of it** is `docs/project/gotchas.md` "THE
INSTRUMENT PROTOCOL" (adopted 14z-107 (11), maintainer-directed): the author
of an instrument cannot judge its own output; prove it FIRES and prove it
FAILS before its first real use; log the raw quantity beside the
classification; a hard-coded physical constant is a check with an unwritten
expiry date.

### WHAT SHIPPED SINCE THE FIRST CLOSE

- **D3, the CPS-2 Turbo object promote** (fork `b9899fa8`) —
  `cores/cps2w/hdl/jtcps2w_obj_bank.v`,
  `assign bank = { wide_en & table_y[12], table_y[14:13] };` read in the ELSE
  arm of the sprite-list terminator test, which is the reference core's
  VERBATIM (the ORDER is the rule: `table_y[15]` IS the terminator).
  `rom0_bank[2]` UNTIED and the bank three bits wide at every port from the
  frame table to SDRAM — four override files for one expression, three of them
  nothing but a width. **Swept exhaustively:** 131,072 vectors, bank[2] set
  32,768 times wide and **0** stock, the six `gfx_tiles.py` encodings each
  decoding to their own bank with none setting y bit 15. Two must-fire
  controls fire.
- **D4, the 6 MB program window** (fork `dd242a65`) —
  `wide_en & RnW & (A[23:21]==3'b010)`,
  `rom_addr`/`main_rom_addr`/`SLOT3_AW` 21->22, and the `one_wait` boundary
  `wide_en ? 4'h6 : 4'h5`. **Shipped WITH D3 because D3 cannot be demonstrated
  without it:** the select screen's roster record is allocated in `wide_ext`
  above `CPU:$400000`, so a 4 MB decode cannot read the table that names the
  tenant cells and the promote has nothing to promote.
- **D5, THE DECRYPTION RANGE — the finding of the arc** (fork `c00d7ce7`).
  The CPS-2 key's encrypted-opcode RANGE word is stored **COMPLEMENTED**
  (`upper = (((~decoded[9] & 0x3ff) << 14) | 0x3fff) + 1`, FBNeo
  `cps2_crpt.cpp:771`; MAME the same) and `jtcps2_dec_ctrl.v:44` compares
  against it UNCOMPLEMENTED, so for `vsavj` (range word `0x03C0`, computed two
  independent ways from the same 20 key bytes) the reference core decrypts
  opcode fetches to `CPU:$F03FFF` where MAME and FBNeo stop at `$0FFFFF`.
  **Every stock CPS-2 game hides it, for two reasons that stack:** the only
  code that ever executes is the code Capcom encrypted, which is inside the
  real window either way; and DATA reads are not opcode fetches, so no
  implementation decrypts them at any address. **CPS-2 WIDE is the first thing
  in thirty years to put EXECUTABLE code above the window.**
  The fix is ONE gated expression in a new
  `cores/cps2w/hdl/jtcps2_decrypt.v`:
  `rng_eff = wide_en ? { addr_rng[15:10], ~addr_rng[9:0] } : addr_rng`.
  **`jtcps2_dec_ctrl` is deliberately NOT overridden** — the fix sits one
  level upstream of the comparison, so the comparison nobody has validated for
  the rest of the CPS-2 library is left exactly as it was, and `dec_en` still
  comes from the uncomplemented word.
  **WHY IT IS GATED AT ALL, since the maintainer asked:** with `wide_en` clear
  `rng_eff` IS `addr_rng`, so stock `vsavj` and every other CPS-2 game are
  untouched BY CONSTRUCTION and the stock leg stays a TRUE CONTROL. The buggy
  path is unreachable on stock content, so the gate costs nothing and buys a
  reference leg that is provably the reference core. Fixing it for the whole
  CPS-2 library is a claim this project cannot validate.
  **FRAMING RULED (maintainer, 2026-08-24): a LATENT IMPLEMENTATION
  DIVERGENCE, not a defect** — no software in thirty years created the
  condition that exposes it. Worth reporting upstream on those terms.
- **The 68k program-ROM read probe** (fork `72738d51`, sim-only, compiled out
  unless `JTCPS2W_PRGPROBE` is defined) — deliberately TWO instruments: an
  ADDRESS half classifying every 68k bus cycle by `A[23:21]` with **no chip
  select in the condition** (which is what still speaks when `wide_en` is
  clear and `rom_cs` cannot assert at all), and a DATA half logging every
  COMPLETED read with the word the CPU LATCHED beside the RAW SDRAM word.
- **The retraction commit** (fork `7b9a0d2d`, comment only) — the
  `jtcps2_main.v` override header still claimed the extension is not
  decrypted. **THE PIN IS `7b9a0d2d`, EIGHTEEN commits, PUBLIC AND CURRENT.**

### WHAT WAS MEASURED

**THE BOOT, AND THE FIRST TENANT TILE EVER FETCHED ON AN FPGA
IMPLEMENTATION.** With D5 in: the ten fetches at `CPU:$4BE7C0-$4BE7C8` arrive
as memory holds them; completed program-ROM reads above `$400000` go from
**10** to **1,189,750** over the full run, spanning `CPU:$412BA0-$4D100E`
which is `wide_ext` (`0x400010-0x4D1100`) to the byte, with **20,000 of
20,000** sampled records showing `cpu_word == raw_word == the .rom`; the boot
passes the point it used to die at, reaches the title screen (bank 3 at 48,928
words/frame, the stock image's own figure) and then the select screen; and the
group-C read probe counts **9,038,400 reads over 105 DISTINCT TILE CODES
`0x74D6-0xFE41` in obj bank 5** — the select-wheel tenant art — first at
simulated frame 1556, every code inside the roster's frozen live extent
`0xFFDB`, control leg at zero. The vanilla banks read what the STOCK image
reads on a healthy boot (372 distinct blocks in bank 2, bank 3 reaching
`0x9C177E`).

**AND THERE IS A PICTURE.** `docs/project/images/mister_select_cps2w_f2400.jpg`
is the core's select screen — the extended wheel, the tenant cells, and the
authored **"M6"** mark bottom-right — the first image of this project's own
content produced by an FPGA implementation; `mister_select_mame_f1741.png` is
MAME's frame of the same screen beside it. **They are a naked-eye pair, not a
verdict:** nothing compares them programmatically, there is no golden and no
gate, and §12 records them as such. (Rendered frames are outside rule 7,
CLAUDE.md §2, ruled 14z-91 — which is why they are committed.)

**BOTH STOCK LEGS GREEN WITH D5 IN**, which is the FPGA superset invariant on
the one change that could have moved it: `tests/test_mister_wide_inert.sh`
bit-identical work RAM in **101 frames of 101** with its control firing, and
`tests/test_mister_sim_anchor.sh` at **sim 2609 / MAME 2146 / skew 463**
(frozen 463 ± 30), every mapped field agreeing, all four controls firing. Both
are true by construction as well as by measurement.

**BANK 0 UNDER THE REDIRECT: ANSWERED, AND IT IS GO** (14z-107 (12);
`mister_map.md` §9 open question 1, open since the map was written).
`audit_sdram_bank_load --core cps2w --wide build/m3b_merged13` on a BOOTING
WIDE image, `05_timeout_idle`, 3,500 frames:

| phase | ba0 | ba1 (PCM) | ba2 | ba3 | data bus |
|---|---|---|---|---|---|
| attract (661-1461) | 38,261 | 3,466 / 78.6% | 0 | 9,446 / 25.2% | 12.7% |
| select+VS (1463-2805) | **40,717** | 13,870 / 99.0% | 357 / 84.1% | 10,917 / 37.1% | 16.4% |
| in-match (2812-3499) | **41,535** | 13,890 / 98.0% | 296 / 39.9% | 17,335 / 34.2% | 18.2% |

Bank 0 runs at **32.9% of its 123,825 all-miss ceiling** through the select
screen — the phase where the wheel art is actually being fetched out of it —
with a whole-run PEAK of 54,363 (**43.9%**) and **ZERO `SDRAM reads clashed`
in 3,500 frames**. Against the stock baseline (39,696 select / 40,976
in-match) the redirect costs about **1,000 accesses/frame, ~2.5%**, which is
the right order for the 6,720 burst BEATS per select frame the read probe sees
in that window (~1,680 BA0 accesses at four words each). **The repack's bank-0
half is GO on measurement, not on argument.**

**AND THE INSTRUMENT VERIFIED ITS OWN PHASE BOUNDARIES**, which is why the
figures can be trusted: the transfer was asserted at **659** from the run's
own log, and the run's own match-start anchor measured **2806** — exactly the
frozen 2609 plus the 197-frame WIDE/stock transfer difference. The four phase
boundaries label the phases they name rather than being assumed to.

**THE HALF IT DOES NOT ANSWER, stated because the asymmetry matters.**
`05_timeout_idle` picks Demitri, so obj bank 4 is never fetched and ba1's
13,890 accesses/frame are the PCM stream ALONE — within 0.3% of stock. **The
repack risk this instrument was actually built for — obj fetches interleaving
with QSound INSIDE bank 1 — is still UNMEASURED**, and stays so until a tenant
can be selected on the core.

### OBJ BANK 4 IS STILL UNPROVEN, AND THE REASON IS A HARNESS DEFECT

`tests/test_mister_gfxc_fetch.sh`'s WHEEL half is GREEN and its FIGHTER half
is RED. The replay was written and run — `36_pick_tenant_cell` on `cps2w` with
the WIDE romset, into a match — and it fetched **exactly zero** from obj bank
4. **The simulator's direction bits are TRANSPOSED** *[CORRECTED 14z-108: REVERSED END FOR END — all four, not two; see the correction block below]*, measured on the core's
own copy of the game's input mirror (leg E: 811 integrity-checked work-RAM
dumps across the cursor-press window):

| the replay asked for | MAME's `$FF8058.w` | the CORE's `$FF8058.w` |
|---|---|---|
| Left (replay frames 1000, 1040) | `0x0002` | **`0x0004`** |
| Down (replay frames 1080, 1120) | `0x0004` | **`0x0002`** |

The bits ARRIVE and are PERMUTED — they are not lost, and 12 of the 811 frames
carry a direction, exactly the count the replay scripts. The cursor moved on
every press, just not where asked; it landed on Victor; and the core drew the
legacy character it was handed. **The zero is a true reading of a run that
never selected a tenant.** The likely cause is INFERENCE from two data points
(`tools/rpl2siminputs.py` emits U/D/L/R per its own docstring where the
harness appears to consume U/L/D/R, which swaps Down and Left and leaves Up
and Right untouched) — **Up and Right are NOT exercised by those samples and
that half is untested. Measure all four before changing one bit.** The whole
chain checks out on paper, which is the point.

> **[CORRECTED 14z-108 — the inference in this paragraph is REFUTED, and the
> instruction above it was right.** Measured on all four directions
> (`tests/replays/107_four_directions.rpl`, stock `vsavj`, MAME vs `cps2w`,
> both dump sets integrity-checked): the nibble is **REVERSED END FOR END**,
> not swapped in two. Up arrives as `0x0001` (Right) and Right as `0x0008`
> (Up), so the "leaves Up and Right untouched" half is false and a two-bit fix
> would have left half the defect in the tree. Mechanism: jtframe's joystick
> port is MSB-FIRST (`jtframe_keyboard.v:107-110`) while `test.cpp:380` copies
> file bits 4-7 straight onto `joystick1[3:0]`, so the file map is
> bit4=Right … bit7=Up. Fixed in `tools/rpl2siminputs.py`; no fork commit.
> **Also corrected: "A bit-map fix MOVES BOTH" below is wrong** — only the
> vector moved. See the 14z-108 entry.]**

**GATE CONSEQUENCE, recorded so it cannot be done quietly:**
`tests/test_rpl2siminputs.sh` freezes the bit-map vector `111 6ee 000 000 080`
and the `05_timeout_idle` translation sha1
`eb3e1d04e58b3a2b7bf713d40c4d6ac4796e550c`. A bit-map fix MOVES BOTH, and they
must be re-derived DELIBERATELY with the mechanism named in the gate header.
**[CORRECTED 14z-108: it moved ONE.** The vector became `181 67e 000 000 010`;
the sha1 did NOT move and cannot, because `05_timeout_idle` scripts no
direction token — which is also why the frozen sim anchor could not move.]**

**A TENANT HAS STILL NEVER FOUGHT ON THE CORE, and nothing in this lane has
ever run on HARDWARE.** Everything above is Verilator.

### WORKING DISCIPLINE ADDED THIS SESSION

- **THE INSTRUMENT PROTOCOL** (`e92faf9`, maintainer-directed) —
  `docs/project/gotchas.md`, indexed in `docs/GOTCHAS.md`.
- **A replay's name is a claim about the build** (`7ef3b13`) —
  `11_pick_donovan` picks Jedah on every post-M3a build; the filename outlived
  the substitution.
- **`pgrep -f` waiters match their own command line and never exit**
  (`e6bcd9e`) — paid four times in one task; wait on a recorded PID with
  `kill -0`, or on a marker file. Finally in the tree.
- **§12 gained the SILICON ASSUMPTION D5 rests on** (`8be8d15`) — that real
  CPS-2 silicon decrypts only the first 1 MB is **INFERRED, never measured**,
  and MAME and FBNeo share one research heritage rather than being two
  independent witnesses. It matters beyond MiSTer: WIDE puts executable code
  above the window, so a real CPS-2 board must also leave that region
  undecrypted for the roster to run on hardware.
- **The transposed direction bits** (`34c7feb`) — `docs/platform/gotchas.md`,
  indexed.

### RITUAL

- **STATE**: this entry, plus session entries 14z-107 (10) and (11) written
  during the session. The 14z-107 (12) work — the bank-0 answer and the
  transposed directions — has no separate entry and is recorded HERE, which is
  where "STATE 14z-107 (12)" references (in `mister_core.md` §12,
  `mister_map.md` §9 and `docs/platform/mister.md`) resolve.
  **The ROLLOVER executed as the first close PREDICTED IT WOULD**: that entry
  recorded "14z-106 rolls at the next close", and it did — the whole 14z-106
  group (4 entries, 175 lines: the CLOSE, (4) slice C, (3) slice A, and the
  HOUSEKEEPING entry) moved VERBATIM to the top of `STATE_HISTORY.md`'s body
  with its ledger line here. **Verified lossless**: the extracted block is
  byte-verbatim in the archive and the string `## Session 14z-106` no longer
  occurs in this file. 14z-105 rolled at the first close, so **exactly ONE
  session group is now kept — 14z-107 — plus THE LEDGER and the standing
  sections.** The GROUP arm of the rule is therefore satisfied with two
  groups to spare. **The SIZE arm is NOT, and it cannot be:** this file is
  **252 KiB** against the ~150 KB the rule names, and the only group left to
  roll is the CURRENT session's own, which the rule does not contemplate and
  which would put the live state in the archive. **Recorded here so the next
  session does not re-derive it: the next close should roll the 14z-107
  group's OLDER sub-entries** — the (1)-(9) blocks, whose findings are all
  restated in this entry, in the first close, or in the live docs — and keep
  the two closes plus (10)-(12). That is the first time this project has hit
  the rule's edge, and the edge is real: one session produced 15 entries.
- **`docs/NEXT_SESSION.md`**: rewritten. The opener is THE DIRECTION-BIT FIX
  in three ordered steps (measure all four first; the two frozen expectations
  the fix moves; then the tenant match, which answers obj bank 4 and bank 1's
  group-C traffic in one run). The banner also carries the honest state (boots,
  draws, fetches the wheel art / no tenant has fought / no hardware), the seven
  instrument defects with D5 as the counter-example, the frozen anchor
  (2146 / 2609 / 463 ± 30), the 659-frame WIDE transfer and its 197-frame
  consequence, the per-core `--wram` offset, the fork pin and the push policy,
  the thin margins, the two standing warnings, and where the `/tmp` evidence
  is with a warning that `/tmp` is volatile.
- **`HANDOFF.md`**: the MiSTer block brought current. **Two things it asserted
  that this session made false are fixed**: "NO TENANT TILE HAS BEEN FETCHED
  ON ANY CORE, EVER" and "the WIDE romset does not boot" — both true when
  written, both false now — replaced with the fetch result AND the three
  things that are still never (bank 4, a tenant in a match, hardware). The
  fork commit list goes SEVENTEEN -> EIGHTEEN with `7b9a0d2d` named and the
  pin stated. Gate rows updated with tier and runtime: `test_rpl2siminputs`
  now carries the WARNING that the bit map it freezes is wrong and that both
  frozen values move when it is fixed; `audit_sdram_bank_load` carries the
  WIDE leg's real answer; `test_mister_gfxc_fetch` carries the split verdict
  and the two defects it found in itself; `test_mister_prg_probe` names
  `tools/prgprobe_verdict.py` as the verdict logic under test.
- **`docs/project/mister_core.md` §12 (the holes)**: made accurate.
  **Bank 0's traffic moves OUT** — struck and marked ANSWERED with the
  numbers, kept in place so the question's provenance stays findable.
  **Obj bank 4 stays IN, with the HARNESS reason** (the old text said "a
  replay to write, not a slice"; the replay exists and ran). **Three rows
  added or rewritten**: "A tenant SELECTED on the core" (blocked by the
  transposed directions, with the measured table and the untested half named),
  "A tenant FIGHTING on the core" (never; everything below it in the stack is
  proven), and "A tenant sprite DRAWN, and checked as a picture" (DRAWN, NOT
  CHECKED — the two committed images named as a naked-eye pair).
  `tools/mk_mister_page.py --check` re-run after the edits.
- **GOTCHAS**: every trap this session paid for is filed in
  `docs/{platform,project}/gotchas.md` AND indexed in `docs/GOTCHAS.md` —
  verified at the close, all four of the new ones present in both places.
- **RETRACTIONS AND INCONSISTENCIES FIXED AT THE CLOSE** (grep'd for the
  CLAIM, not for the files I remembered):
  * `mister_map.md` §9 referenced a `docs/platform/mister.md` section titled
    "THE SIMULATED JOYSTICK'S DIRECTIONS NEVER REACH THE GAME" **that did not
    exist**, and whose title asserts something the measurement contradicts —
    the directions DO reach the game, permuted. The section now exists as
    **"THE SIMULATED JOYSTICK'S DIRECTIONS ARE TRANSPOSED"** with the measured
    table, the cost, the inference, the gate consequence and the pictures; the
    map's reference is corrected; `grep -rn "DIRECTIONS NEVER REACH"` is
    empty.
  * `docs/platform/mister.md`'s own bank-0 section said "See the input defect
    below" with nothing below it. Now points at the section by name.
  * **The two committed images were referenced NOWHERE** — a durable artifact
    with no prose route to it. Now named in `mister_core.md` §12,
    `docs/platform/mister.md` and `HANDOFF.md`.
- **SCRATCH HYGIENE**: **ELEVEN jtcores scratch CLONES swept, 9.5 GB** —
  `/tmp/vs14z107_{A,B,C,D,stage}` and `/tmp/vampire-saved-jtsim-{ab,d1,inert,mra,ord,pal}`.
  Pure rebuild litter: every one is remade by `run_sim_jtcps2.sh`, and leg E's
  launch record confirms its outputs were COLLECTED out of the clone before it
  was touched. **251 MB of EVIDENCE kept until the direction fix is verified**:
  `/tmp/vs14z107_out` (leg E's **811** work-RAM dumps at `E/wram`, integrity
  asserted 1640-2450 x 65,536 B at `$FF0000`; its 34 rendered frames at
  `E/frames`; every leg's `.launch` and `jtsim.log`; the bank-load TSV), the
  two rendered frames `/tmp/vs14z107_keep_{select,match}.jpg`, and the MAME
  legs `/tmp/vs14z107_mame{36,inp,11,pre,sel,snap}` that are the other half of
  the transposition comparison. **`/tmp` IS VOLATILE and NEXT_SESSION says so
  — the durable copies of the two pictures are the ones committed under
  `docs/project/images/`.**

**GATES RUN AT THE CLOSE:**
- `ROMDIR=... tests/run_all_static.sh --strict` — **PASS 107 / SKIP 0 /
  FAIL 0 / MISSING 0**, registry coverage clean (every emulator-free gate
  registered). Run TWICE, once mid-documentation-pass and once on the final
  tree, with the same result. *(The first run's working-tree check flagged
  `docs/NEXT_SESSION.md` as "dirtied by the run" — that was ME editing it
  while the run was in flight, not a gate writing into a tracked path. The
  second run is clean. It is also a small demonstration of standing warning
  (2): do not touch the tree while something long is reading it.)*
- `python3 tools/audit_roms.py $ROMDIR` — **76 of 76 members match
  `docs/checksums.txt`**.
- `python3 tools/mk_mister_page.py --check` — **PASS, all 17 figures
  re-derived** (run after the §12 edits).
- `tests/test_jtcores_twin.sh` standalone — **PASS**: pin `7b9a0d2d`, the
  series is **18 files == 18 commits** with each `== format-patch -1`, the
  fork's whole-tree delta exactly the declared 25 paths, `cores/cps2w/hdl`
  exactly the declared override set, and `cores/cps1`/`cps2`/`cps15`
  BYTE-UNTOUCHED vs v1.7.3. Both must-fire controls fired.
- `git ls-remote` confirms `origin/vampire-saved` = the submodule pin =
  `7b9a0d2d05eedf7fc9625df9ca6ea1d0278f8ef1`. **The fork is public and
  current; the main repo is not pushed.**

**COMMITS**: **FOURTEEN** of session work since the first close,
`516ad9f`..`34c7feb` (`git rev-list --count cd0c614..HEAD`), plus this close =
fifteen. Counting from the 14z-106 close the branch is **36 commits ahead of
`origin/main`** — the 21 of the first close plus these 15. **ALL LOCAL: the
main repo is NEVER pushed**, and every commit in the range is MiSTer work, so
none qualifies for the pre-MiSTer push exception. The FORK is public and
current: `origin/vampire-saved` = the submodule pin =
`7b9a0d2d05eedf7fc9625df9ca6ea1d0278f8ef1`, **eighteen** commits, confirmed
with `git ls-remote`.

**NEXT OPENER: THE DIRECTION-BIT FIX**, in the order `docs/NEXT_SESSION.md`
states it. Measure all four directions first.

**STILL OPEN FOR THE MAINTAINER:** MiSTer PACKAGING (which MRA is the core's
MAIN one; how a release carries both `vsav.zip` flavours). **FUTURE,
UNSCHEDULED (maintainer, 2026-08-24):** the LIVING-DOCUMENTATION effort (of
which `mister_core.md` + `mk_mister_page.py` are the pilot) and DISTILLING AI
SKILLS from the project's learnings, scoped by subject. Both follow MiSTer.

## Session 14z-107 (11) — **THE WIDE ROMSET'S BOOT FAILURE IS ROOT-CAUSED AND
## FIXED. The CPS-2 key's ENCRYPTED-OPCODE RANGE WORD IS STORED COMPLEMENTED,
## and `jtcps2_dec_ctrl` reads it straight — so the reference core decrypts
## opcode fetches to `CPU:$F03FFF` where MAME and FBNeo stop at `$0FFFFF`.**
## Every stock CPS-2 game hides it. CPS-2 WIDE is the first thing to put
## EXECUTABLE content above the window, and the first ten opcodes it fetched
## there arrived as the decryptor's output. Slice **D5** (fork `c00d7ce7`)
## complements the word, profile-gated. **AND THE PAYOFF LANDED WITH IT: a
## TENANT TILE HAS BEEN FETCHED ON THE CORE, for the first time ever.**
## (This section post-dates the 14z-107 CLOSE below.)

**THE TASK WAS ONE QUESTION WITH THREE POSSIBLE ANSWERS**, recorded in the
14z-107 (10) review commit `eac3a73`: does slice D4's 6 MB program decode
actually FUNCTION? Because if it does not, `wide_en` SET behaves exactly like
`wide_en` CLEAR for every read above `CPU:$400000`, and the "profile-on and
profile-off are frame-for-frame identical" elimination is explained by a DEAD
DECODE rather than by an innocent profile. **The answer is the third one, in a
form nobody listed: the decode works, SDRAM returns the romset's bytes, and
something BETWEEN SDRAM AND THE 68k corrupts them.**

### THE MEASUREMENT

A sim-only probe on the 68k program-ROM read path
(`cores/cps2w/hdl/jtcps2_main.v`, `JTCPS2W_PRGPROBE`, fork commit 16),
deliberately TWO instruments: an ADDRESS half that classifies every 68k bus
cycle by `A[23:21]` with **no chip select in the condition** — which is what
still speaks when `wide_en` is clear and `rom_cs` cannot assert in the window
at all — and a DATA half that logs every COMPLETED read with the word the CPU
LATCHED and the RAW SDRAM word behind it. `11_pick_donovan`, `cps2w`, the real
`vsavjw.rom` (sha1 `d462e55a…`), 2,300 simulated frames so the boot's own
reset at 2242 is inside the window. The two legs differ by ONE BYTE — header
byte 41, `0xFE` against `0xFF`:

| | `wide_en` = 1 | `wide_en` = 0 |
|---|---|---|
| 68k bus READ cycles into `$400000-$5FFFFF` | **10** | 4 |
| ...WRITE cycles (the objcfg port at `$400000-$40000A`) | 7,198 | 7,198 |
| COMPLETED program-ROM reads above `$400000` | **10** | **0** |
| ...below `$400000` (the must-fire control) | 54,961,148 | 54,954,608 |
| SDRAM read probe, bank 0 `0x400000-0x600000` | **16 words**, `0x4BE7C0-0x4BE7CE` | **0** |

**The ten records ARE the finding.** All at `CPU:$4BE7C0-$4BE7C8`, five at
simulated frame **1119** and the same five at **2246** — once per turn of the
boot loop. All ten carry **`fc = 2`, USER PROGRAM: they are OPCODE FETCHES**,
so the 68k is EXECUTING from the extension. Every raw word is the `.rom`'s
byte for byte; **every latched word is different.**

**The must-fire evidence is in the same counters.** 54.9 M reads below
`$400000`, first 2,000 logged with bytes: **2000/2000 match the `.rom`**, and
they split exactly along the CPS-2 rule — `fc=5` (supervisor DATA) 824
records, none decrypted; `fc=6` (supervisor PROGRAM) 1,176, all decrypted. The
same sample CALIBRATES the byte order (`rom[off+1]<<8|rom[off]` 2000/2000, the
other order 59/2000), so the comparison is derived rather than assumed.

### THE MECHANISM, AND WHY IT SURVIVED THIRTY YEARS OF CPS-2 EMULATION

FBNeo `cps2_crpt.cpp:771`: `upper = (((~decoded[9] & 0x3ff) << 14) | 0x3fff) + 1`.
`jtcps2_dec_ctrl.v:44`: `en_latch <= op_fetch && en && (addr[14+:10] <= range[9:0])`
— **no complement.** For `vsavj` the word is `0x03C0` (computed two
independent ways from the same 20 key bytes — jtframe's `jtcps2_keyload`
permutation and FBNeo's `(317-b)%160` — and they agree), so MAME/FBNeo decrypt
`$000000-$0FFFFF` (63 blocks of 16 KB) and jtcps2 runs on to `$F03FFF` (960).

**Every stock CPS-2 game hides it, for two reasons that stack:** the only code
that ever executes is the code Capcom encrypted, which is inside the real
window either way; and DATA reads are not opcode fetches, so no implementation
decrypts them at any address. **That also retroactively weakens 14z-56's
B4 (prg)**: it relocated DATA tables, and data reads bypass the decryptor
everywhere. Nothing had ever EXECUTED from above 4 MB on a core that decrypts
by address.

### SLICE D5, AND WHAT IT DELIBERATELY DOES NOT TOUCH

`cores/cps2w/hdl/jtcps2_decrypt.v` (fork `c00d7ce7`), one gated expression:
`rng_eff = wide_en ? { addr_rng[15:10], ~addr_rng[9:0] } : addr_rng`.
`jtcps2_dec_ctrl` is **not** overridden — the fix sits one level upstream of
the comparison, so the comparison nobody has validated for the rest of the
CPS-2 library is left exactly as it was. `dec_en` is unaffected (keyload still
sees the uncomplemented word). With `wide_en` clear `rng_eff` IS `addr_rng`,
so stock `vsavj` and every other CPS-2 game are untouched BY CONSTRUCTION.
**Gated rather than fixed outright because fixing it for the whole CPS-2
library is a claim this project cannot validate — it is a defect in the
reference core and worth reporting upstream.**

### WHAT THE FIX PRODUCED — AND IT IS THE THING THE ARC HAS BEEN AFTER

Same core, same romset, same replay, with D5 in:

* **the same five opcodes at `$4BE7C0` now arrive as memory holds them**
  (`4ded 4ded`, `3800 3800`, …) and the 68k keeps going;
* completed reads above `$400000` go from **10** to **343,806** by frame 1789,
  spanning `$412BA0-$4D100E` — which is `wide_ext` (`0x400010-0x4D1100`) to
  the byte;
* the boot **passes the point it used to die at**, reaches the title screen
  (bank 3 at 48,928 words/frame, the stock image's own title-screen figure)
  and then the select screen;
* **and the group-C read probe lights up. Over 2,900 simulated frames:
  9,038,400 reads over 105 DISTINCT TILE CODES in obj bank 5 (the select-wheel
  tenant art), first at frame 1556, every code inside the roster's frozen live
  extent for that bank. A TENANT TILE HAS BEEN FETCHED ON THE CORE, for the
  first time in the arc.** The vanilla banks now read what the STOCK image
  reads on a healthy boot — 372 distinct blocks in bank 2, bank 3 reaching
  `0x9C177E` — which are the same figures the stock leg produced. Obj bank 4
  (the fighter art) is still zero: this replay window ends before a match
  starts.
* completed program-ROM reads above `$400000` over the full run: **1,189,750**,
  spanning `CPU:$412BA0-$4D100E`, and **20,000 of 20,000 sampled records have
  `cpu_word == raw_word == the .rom`** — the CPU now receives exactly what
  memory holds.
* **`tests/test_mister_gfxc_fetch.sh`'s WHEEL half is GREEN**: codes
  `0x74D6-0xFE41`, all inside the frozen extent `0xFFDB`, control at zero.
  **Its FIGHTER half (obj bank 4) is still RED and stays red** — this replay
  ends at the select screen and no match starts, so no fighter sprite is
  emitted. A gate green on evidence it does not have is worse than a red one.
  **Its first real measurement found two defects IN THE GATE**, both fixed:
  the tile code was computed from the ABSOLUTE SDRAM address instead of
  relative to the armed window's base (a correct promote read as
  `0x170D6-0x1FA41`), and its liveness control demanded vanilla obj traffic in
  the CONTROL leg — an image that cannot boot by construction, because with
  the profile clear its group-C art aliases over vanilla's obj banks.
* `tests/test_mister_prg_window.sh` freezes the pair and PASSES;
  `tests/run_all_static.sh --strict` is **GREEN at PASS 107 / SKIP 0 / FAIL
  0** (106 before, plus `test_mister_prg_probe`).

**BOTH STOCK LEGS ARE GREEN WITH D5 IN**, which is the superset invariant on
the one change that could have moved it: `tests/test_mister_wide_inert.sh`
PASSES (`cps2w == cps2`, BIT-IDENTICAL work RAM in all 101 frames, control
firing) and `tests/test_mister_sim_anchor.sh` PASSES at **sim 2609 / MAME 2146
/ skew 463** (frozen 463 ± 30), every mapped field agreeing, all four controls
firing. Both are true by construction as well as by measurement — `rng_eff` IS
`addr_rng` with `wide_en` clear.

### TWO INSTRUMENT DEFECTS, BOTH CAUGHT BY THE DATA (this lane's total is now SIX)

1. **The probe's first draft split the window on `rom_addr[21]`.** `rom_addr`
   is declared `[22:1]` and driven `A[22:1]`, so its INDEX is the address bit
   and `[21]` is `A[21]` — set for `$200000-$3FFFFF`. It reported **2,560
   reads "above `$400000`" at `$38C2A0-$3D8256`** in the first frame it fired.
   The COUNT looked healthy; only the addresses contradicted the label, and
   only because the probe logged them.
2. **The verdict tool judged only the RAW word and reported "D4 WORKS"** over
   ten fetches the CPU received as garbage — a verdict bug of exactly the kind
   CLAUDE.md §4 forbids.

Both are now REFUSALS in `tools/prgprobe_verdict.py` and fixtures in
`tests/test_mister_prg_probe.sh` (4e and 4g), the second built from the real
numbers. **Generalisation worth keeping: log the raw quantity beside the
classification, so the instrument can be caught disagreeing with itself; and
when a second implementation reads the same configuration word, DIFF THE
EXPRESSION, not the result.**

### WHAT WAS RETRACTED

* `mister_map.md` §8 "the extension is NOT decrypted, and that is correct" —
  true of the hardware, MAME and FBNeo; FALSE of jtcps2. Corrected in place,
  and in the `jtcps2_main.v` override header (fork `7b9a0d2d`, comment only).
* `mister_map.md` §10 D4 "the proof is that the WIDE set BOOTS AND PLAYS" and
  D3 "it is a REAL FETCH on the REAL ROMSET" — neither was true when written.
* `HANDOFF.md` "SINCE D3+D4 THE CORE FETCHES TENANT ART" and `mister_map.md`'s
  §0 header of the same claim.
* **One elimination CORRECTED rather than withdrawn:** the two profile states
  are NOT frame-for-frame identical. They are identical in bank-3 traffic and
  in masked work RAM — which is what was measured — but the profile-ON leg
  issues ten completed reads above `$400000` and the profile-CLEAR leg zero.
  The instrument that said "identical" could not see the window it was being
  asked about.

## Session 14z-107 CLOSE — ritual complete. THE MiSTer ARC'S THREE
## PLACEMENT SLICES ARE DONE (D0 the MRA, D1 the runtime profile gate +
## QSound width, D2 the SDRAM placement), the CLAUDE.md §4 oracle now runs
## on a THIRD implementation and AGREES, and the most transferable result
## of the session is a methodological one: **THREE SEPARATE INSTRUMENTS
## PRODUCED FALSE VERDICTS WHILE THE THING UNDER TEST WAS INNOCENT.**
## Twenty commits of session work plus this close = **21, ALL LOCAL** —
## every one is MiSTer work, so none qualifies for the pre-MiSTer push
## exception. The FORK is fully public:
## `origin/vampire-saved` = the pin = `0df6f000`, eleven commits.

**The session, in one line:** the MiSTer arc went from "the oracle might
be buildable" to "the WIDE romset has a byte-exact place in 64 MB of
SDRAM, gated at runtime, with every byte of the image counted" — and it
got there by fixing its own instruments three times, each of which had
already published a wrong number.

**THE LESSON FIRST, BECAUSE IT IS THE PART THAT TRANSFERS.** In one
session, three defects in the MEASURING APPARATUS produced verdicts about
things that were not defective. None was found by theorising; each was
found by changing ONLY the instrument and re-running.

| # | the instrument | the false verdict it produced | the innocent subject | how it was caught |
|---|---|---|---|---|
| 1 | the Verilator SDRAM model dropped `addr[22]` (it rides `sdram_a[9]` as the tenth COLUMN bit; `addr[9]` is a ROW bit) — 14z-107 (3) | GFX banks 2/3 were HALF-ALIASED, so 14z-106 slice C's "frames showed sprites" read as evidence that GFX addressing was faithful when it only proved the core runs — no video or sprite result from the lane was trustworthy for wide GFX at all | jtcps2's GFX addressing, and the lane's own credibility | derive from the RTL instead of from the SIZE — *a size tells you how many bits are missing, never which one* |
| 2 | the forked frame writer `exit(0)`'d, `fclose()`ing the parent's inherited `sim_inputs.hex` `FILE*`; POSIX rewinds the SHARED offset — 14z-107 (7) | slice D1's anchor read RED (2609/463) against a frozen 2502/356, and the RTL was blamed for four 50-minute runs | `cores/cps2w`'s D1 RTL — and the FROZEN number was the artifact, not the red one | a 2x2 factorial on `pal_lut.hex` x frame-output, 681 dumps a leg: the RTL axis moved nothing, the HOST axis moved everything |
| 3 | jtframe's `SimInputs` held P1's **and P2's** buttons 5 and 6 down — two 8-bit constants on a `[9:0]` ACTIVE-LOW port — 14z-107 (8) | the two legs of the §4 oracle had never run the same inputs, so every agreement it reported was an agreement about a different machine | both legs; the fields agreed anyway | a MAME hold-vs-not differential located the game's own input mirror (`$FF8058/5A/5C/5E`) and the pre-fix sim block was BYTE-IDENTICAL to MAME with four buttons held |

**And a fourth, in D2, of the same family:** `JTFRAME_SIM_WRAMDUMP_OFF`
was hard-coded to bank 0 byte `0x600000` — work RAM on `cps2`, **VRAM on
`cps2w` after the re-pack** — so `test_mister_wide_inert` went red in 101
frames of 101 while comparing one core's work RAM against the other's
VRAM. It does not announce itself: VRAM is a plausible 64 KB of changing
bytes, so the window was non-constant and every other assertion passed.
**Any instrument that names a PHYSICAL address is invalidated by a
memory-map change, and a placement slice IS a memory-map change.**
The standing rule that came out of all four, now in
`docs/platform/gotchas.md` and in the NEXT_SESSION banner: **suspect the
instrument before the RTL** — and never blame a red anchor on RTL until a
core-vs-core RAM comparison says so, which is what
`test_mister_wide_inert` exists for.

**AND THE HONEST LIMIT ON D2, STATED BEFORE THE ACHIEVEMENTS.** D2's
evidence is the SDRAM IMAGE, not a replay, and it has to be:
`rom0_bank[2]` is tied low until D3, `gfxc_sel` is therefore constant 0,
the two group-C read slots are provably unreachable, and **no tenant art
has ever been FETCHED on the core.** D2 built the destination and the
plumbing; nothing has driven them yet. The bandwidth verdict is the same
shape: it BOUNDS the headroom (only stock traffic is measurable — a WIDE
romset does not load on the stock core), it does not prove the repacked
design.

**WHAT THE SESSION SHIPPED, slice by slice**
- **The §4 oracle on a third implementation** (entry at the bottom of this
  group): work RAM had NO dump path on this core, so one was built —
  `JTFRAME_SIM_WRAMDUMP`, 64 macro-gated lines in the Verilator TESTBENCH.
  MAME and stock jtcps2 agree on every mapped field at the round-1
  match-start anchor of `05_timeout_idle`; the single disagreement is the
  game's own sound-state-fed 1P arcade draw, excluded by name.
- **Two 14z-106 claims RETRACTED** (`JTFRAME_SIM_IODUMP` reaches the
  EEPROM, not work RAM; `JTFRAME_SAVESDRAM` is Verilog-model-only), and
  later a **retraction-of-a-retraction**: the XL tier does not exist at
  our pin and DOES exist upstream. *A grep proves a fact about the tree you
  grepped, and a pin is a tree.*
- **The memory-map truth** — at `v1.7.3`, 64 MB is PHYSICAL;
  `JTFRAME_SDRAM_XL` is real, upstream-only, two chips on nCS polarity, and
  reachable only inside the `JTFRAME_SDRAM_CACHE` branch (setting it today
  would compile, validate and silently alias). **RULED: BANK REPACK at the
  pin, XL as fallback.**
- **The bandwidth measurement: GO** — bank 1's PCM is already at a 98.8%
  in-match row-miss rate, so it has no locality left to lose; the worst
  case runs at 26.3% of one bank against the **32.9% bank 0 already
  sustains in stock shipping configuration**.
- **The placement map** (`docs/project/mister_map.md`) + `audit_mister_map_fit`.
- **D0** — the MRA trim that makes the WIDE image downloadable at all:
  `vsavjw.rom` = **66,265,152 B**, header words **6144/6400/15552/64704**,
  every region verified byte-for-byte against the romset. Stock leg still
  **46,407,744 B / sha1 `f9dc2987…`**, bit-identical.
- **D1** — the QSound sample-bank width fix behind a **RUNTIME** profile
  gate (MRA header byte 41, bit 0, ACTIVE LOW: the generator's own
  `fill=0xff` means profile OFF, the WIDE MRA writes `0xfe`). That is what
  makes rule 1 v2's "profile-gated ... stock `vsavj` untouched BY
  CONSTRUCTION" a FACT on FPGA rather than an inertness argument.
- **D2** — the placement in RTL (bank-0 re-pack, group-C GFX redirect,
  QSound split on `pcm_addr[23]`, two new slot counts, ONE new jtframe file
  `hdl/sdram/jtframe_ram1_7slots.v`), gated by a census over **all
  67,108,864 bytes of all four banks**, four legs, every control firing.
- **The synthesis document + its generator** — `docs/project/mister_core.md`
  states what is TRUE about the core in CAUSAL order and names the logs as
  its provenance; `tools/mk_mister_page.py` draws the geometry rather than
  asserting it, with `--check` re-deriving all 17 figures. The
  maintainer's requested living-documentation pilot.
- Throughout: `cores/cps1`, `cores/cps2` and `cores/cps15` are
  **BYTE-UNTOUCHED**, and since D1 that is a `git diff` assertion
  (`test_jtcores_twin` 2e), with the fork's whole-tree delta held to a
  declared 18 paths (2f).

**THE PLACEMENT'S MARGINS ARE THIN, and the census is why we know:** the
map claimed 0.708 MB of slack and the truth is **0.125 MB — SDRAM bank 1
is EXACTLY FULL** (8 MB PCM + 8 MB obj bank 4 = 16,777,216 B to the byte)
and bank 0 has **131,072 B** free. The error was of KIND, not arithmetic:
the map sized the group-C obj banks by the art's ADDRESS FOOTPRINT
while the MRA downloads the WHOLE declared region, so each obj bank
reserves its full 8 MB whatever the art does inside it. **Three sizes of
the same art — live bytes (6.39 MB), address footprint (15.45 MB),
declared region (16 MB) — and this project has now published a wrong
figure from each of the first two.** Both consequences point opposite
ways: tenant art may grow freely inside the existing 16 MB, and the
group-C ROMSET REGION cannot grow at all.

**MAINTAINER RULINGS TAKEN THIS SESSION** (all marked DECIDED in place in
Decisions pending): the MEMORY-MAP ROUTE (bank repack, measuring first;
XL fallback); the BANK-0 SLOT COUNT (option A — add `jtframe_ram1_7slots`
so bank 1 stays at the two streams the GO measurement modelled); the
PROFILE SELECTED AT RUNTIME from a spare MRA header bit rather than by
`ifdef`; SOURCE SEPARATION (the core stays unmixed; the shared `tools/`
and `tests/` stay as they are and are not to be tidied later);
FORK-PUSH STANDING AUTHORISATION (2026-08-24; the main repo is still never
pushed). Plus two FUTURE DIRECTIONS recorded, nothing scheduled: the
LIVING-DOCUMENTATION EFFORT (and the option it creates — a rebuild from
the docs after the MiSTer core is finished) and DISTILLING AI SKILLS from
the project's learnings, scoped by subject.

**RITUAL**
- **STATE**: this entry, session entries (1)-(9), the two FUTURE-direction
  entries, and every ruling marked DECIDED in place. **The ROLLOVER
  executed**: three groups were kept by the group rule (14z-107, 14z-106,
  14z-105), so nothing was DUE by it — but the file stood at **208 KiB
  against the ~150 KB the rule names**, so the SIZE arm applied and the
  oldest kept group, **14z-105 and only it** (4 entries, 235 lines), moved
  VERBATIM to the top of `STATE_HISTORY.md`'s body with its ledger line
  here. Verified lossless: the extracted block is byte-verbatim in the
  archive and absent from this file. 14z-107 and 14z-106 stay. **This file
  is STILL over the size guide** — 211 KiB with this entry written, because
  the 14z-107 group alone is 1,803 lines / 113 KiB — **so 14z-106 rolls at
  the next close.**
  Recorded here so the next session does not have to re-derive it.
- **`docs/NEXT_SESSION.md`**: rewritten. The banner carries the arc state
  (D0-D2 done, **D3 the obj promote is the opener**), the frozen anchor
  (MAME 2146 / sim 2609 / skew 463 ± 30), the fork pin and the push
  policy, the placement's thin margins, and the two standing warnings —
  suspect the instrument before the RTL, and never edit a script while a
  run is in flight.
- **`HANDOFF.md`**: the MiSTer block brought current — it now opens on
  `mister_core.md` rather than `platform/mister.md`; the SIX tools this
  session added (`run_sim_jtcps2.sh`, `mister_mra.sh`, `gen_vsavjw_xml.py`,
  `check_wram_dumps.py`, `mister_sdram_census.py`, `mk_mister_page.py`) are
  all named with their commands, and the gate table carries tier and runtime
  for all **eleven** MiSTer gates (`test_mister_page` was the row the
  synthesis commit had not added). **Two things it asserted that this
  session made false are fixed:** it still called THE MiSTer MEMORY-MAP
  ROUTE a pending decision, and it still framed the GFX overflow as
  "~6.4 MB into bank 1's spare" — the three-sizes correction.
- **`docs/README.md`**: `mister_core.md` was already indexed (the synthesis
  commit did that), but it was NOT DISCOVERABLE — neither bucket
  description named MiSTer, so a reader who did not already know the file
  existed had no route to it. Fixed by adding an **IF YOU WANT TO KNOW X,
  READ Y routing table** at the entry point (the shape the
  living-documentation direction asks for), with the MiSTer row naming the
  synthesis first and its three logs after it, and by naming MiSTer in the
  `platform/` and `project/` bucket descriptions. Also fixed: the stale
  trap count (145 -> a measured 304).
- **GOTCHAS**: every trap this session paid for is filed in
  `docs/{platform,project}/gotchas.md` and indexed — the in-flight script
  edit (paid THREE times, the third on a COMMENT-ONLY edit), the
  forked-child stream rewind, IODUMP-is-the-EEPROM, the 32 MB Verilator
  SDRAM model, XL-without-cache silent aliasing, jtframe resolving zip
  members by CRC32 alone, the missing `pal_lut.hex` black screen, the
  `jtframe files` path-dedup bill, the SDRAM-addressed dump hook, the
  `prog_ba` fall-through, and the three sizes of the same art.
- **GATES RUN AT THE CLOSE**: `run_all_static.sh --strict` **PASS 106 /
  SKIP 0 / FAIL 0 / MISSING 0** — run TWICE, once before the documentation
  pass and once after it on the final tree, with the same result;
  `tools/audit_roms.py` **76/76 members match `docs/checksums.txt`**;
  `tools/mk_mister_page.py --check` **PASS, all 17 figures re-derived**;
  `tests/test_jtcores_twin.sh` standalone **PASS** (pin `0df6f000`, the
  series 11 files == 11 commits with each `== format-patch -1`, the fork's
  whole-tree delta exactly the declared 18 paths, and
  `cores/cps1`/`cps2`/`cps15` BYTE-UNTOUCHED vs v1.7.3). Only `STATE.md`
  and `docs/README.md` moved after the second full run — no gate reads
  either (grep'd) — and `--tier portable` was re-run afterwards anyway:
  **PASS 51/0/0**.
- **COMMITS**: twenty of session work, `a2585bb`..`3dc9604`, plus this
  close = 21, **all LOCAL** (`git log 4156283..HEAD`). Fork:
  eleven commits, **all PUSHED** (`origin/vampire-saved` = `0df6f000` =
  the submodule pin, verified with `git ls-remote`).

**RETRACTIONS EXECUTED AT THE CLOSE (grep'd for the CLAIM, not for the
files I remembered).** The route ruling of 2026-08-23 had been recorded in
STATE and acted on in D2, but **four live documents still called it a
PENDING DECISION** — `HANDOFF.md`, `docs/project/mister_fit.md`,
`docs/platform/mister.md` and `docs/project/cps2_wide.md` — plus the
14z-107 (2) banner block in `NEXT_SESSION.md`. All five marked DECIDED in
place, superseded text kept and struck. Also fixed in place: HANDOFF's
"only GFX overflows by ~6.4 MB" (the three-sizes correction); the 14z-107
(4) slice-plan line still telling every slice to re-run the anchor gate at
`2146 / 2502 / 356` (the numbers were retracted in (7), the instruction
stands); `mister.md`'s SDRAM-model control paragraph, which stated the
2507 -> 2502 move without its retraction beside it (the MOVE and its
mechanism stand — it was measured as a DIFFERENCE between two runs that
shared the corruption — only the absolutes fall); the 14z-107 (1) and
14z-106 CLOSE lines still calling the PROFILE SHAPE ruling pending; the
five `NEXT_SESSION` banner blocks that all still claimed to be "NEWEST
FIRST"; and `docs/README.md`'s trap count, stale at 145 against a measured
304. **Re-grepped afterwards: every surviving hit is inside a struck span
or an explicitly historical entry.**

**NEXT OPENER: SLICE D3 — THE OBJ PROMOTE.**
`jtcps2_obj_scan.v:152` `st3_bank <= {table_y[12], table_y[14:13]}` (the
CPS-2 Turbo rule, the MiSTer twin of the ratified 19-bit promote WIDE v1
already makes in FBNeo's `Cps2ObjDraw`), plus the
`dr_bank`/`obj_bank`/`rom_bank`/`rom0_bank` chain widened to 3 bits. It
lands on the destination and the plumbing D2 built, and it is the slice
that first DRIVES `rom0_bank[2]` — i.e. the first time tenant art is
fetched on the core at all. Gate: the MiSTer twin of the FBNeo B4 canary.
D4 (the 6 MB PRG window) follows.

**STILL OPEN FOR THE MAINTAINER:** MiSTer PACKAGING (which MRA is the
core's MAIN one; how a release carries both `vsav.zip` flavours) — neither
blocks D3/D4, both must be answered before a release.

## Session 14z-107 (10) — MiSTer SLICES D3 AND D4: THE CPS-2 TURBO OBJECT
## PROMOTE GOES LIVE AND THE 6 MB PROGRAM WINDOW WITH IT. `rom0_bank[2]` is
## untied, the third obj bank bit runs end to end from the frame table to
## SDRAM, and the 68k can read `CPU:$400000-$5FFFFF`. Fork commits
## `17a5dc2b` (the harness SDRAM READ PROBE), `b9899fa8` (**D3**),
## `fd454393` (the harness frame window) and `dd242a65` (**D4**); the pin is
## `dd242a65`, FIFTEEN commits.

### D3 AND D4 SHIPPED TOGETHER, AND THE REASON IS A FACT ABOUT THE ROMSET

The slice plan queued D4 after D3. It cannot be run that way, and the reason
was already written in `mister_map.md` §10 as a summary sentence — "only
after D0-D4 does a WIDE set boot" — without anyone noticing it was
load-bearing. **The select screen's roster record is allocated in
`wide_ext`, above `CPU:$400000`** (`build/manifest/*.toml`
`[[select_wheel]] roster21`, `hole = "wide_ext"`; `build/m3b_merged13/gen.log`
puts `wide_ext` at `0x400010-0x4D1100`). With only the stock 4 MB decode the
core cannot READ the table that names the tenant cells, so no tenant sprite
is ever emitted and **the promote has nothing to promote**. D3 is PROVABLE on
its own — the expression is swept exhaustively — but it is not DEMONSTRABLE
on its own. The two are separate fork commits with separate gate sections;
they are one session's work.

`mister_map.md` §10 had planned a synthetic canary for D3 (the MiSTer twin of
FBNeo's B4 canary: a test flag ORing `0x1000` into bank-2/3 sprites with
group C loaded as a byte copy of group B, on the STOCK rom). **It was not
built.** It was designed for a world in which the WIDE set could not boot;
with D4 in the same session the real romset is the better witness, and the
canary would have proved a weaker statement about a doctored image.

### THE RTL, AND WHY ONE EXPRESSION COST FIVE FILES

**D3** — `cores/cps2w/hdl/jtcps2w_obj_bank.v` is the whole behavioural
surface:

```verilog
assign bank = { wide_en & table_y[12], table_y[14:13] };
```

read in the ELSE arm of `jtcps2_obj_scan`'s sprite-list terminator test,
which is the reference core's VERBATIM. **The order is the rule, not the
bit**: `table_y[15]` IS the terminator, so the profile's first draft (read
bits 15:13 as the bank) would have ended the list at the first tenant sprite.
Capcom solved it the same way on CPS-2 Turbo. Inside the else arm bit 15 is
known to be 0, so the promoted bank is exactly `{ y[12], y[14:13] }` — which
is why `tools/gfx_tiles.py`'s `bank_word` emits `0x1000` for bank 4 and
`0x3000` for bank 5 and not `bank << 13` (= `0x8000`, a terminator).

That one expression pulled in FOUR override files, three of which change
nothing but a WIDTH: `jtcps2_obj_scan.v`, `jtcps2_obj.v`,
`jtcps1_obj_draw.v`, `jtcps1_video.v`. A 3-bit bank has to be three bits wide
at every port between the frame table and SDRAM, and **Verilog answers a
3-bit signal driving a 2-bit port with a warning at worst** — the failure it
produces is a PICTURE (every tenant sprite fetching vanilla art), which looks
like a content bug and sends you to the romset. New platform gotcha; gate
check 8c asserts all six declarations by name.

**D4** — `cores/cps2w/hdl/jtcps2_main.v`, three lines, all gated:
`rom_cs` gains `wide_en & RnW & (A[23:21]==3'b010)`; `rom_addr` widens to
`A[22:1]` (with `main_rom_addr` and bank 0's `SLOT3_AW` following); and
`one_wait`'s boundary becomes `wide_en ? 4'h6 : 4'h5` — the defect found
while reading for D2, where the second megabyte of the extension would have
run ZERO-wait while every other byte of program ROM is one-wait. **The read
decode is collision-free only because `objcfg_cs` is qualified `!RnW`**, so
the gate re-reads that qualifier on every run (8i). And the extension is NOT
decrypted, correctly: `jtcps2_dec_ctrl` decodes only OPCODE fetches below the
key header's range word, which for this game ends at `$0FFFFF`, and the
profile writes extension content RAW for exactly that reason. The two halves
agreed without either being touched.

**EIGHT `wide_en` SITES NOW**, all re-read verbatim by
`tests/test_mister_wide_gate.sh`, and three ungated WIDTH changes declared
rather than hidden (the bank wires 2->3 bits, `rom_addr`/`main_rom_addr`/
`SLOT3_AW` 21->22): each is behaviourally identical with the profile clear
because the extra bit is driven to 0 by a gated expression.
**THE PROMOTE IS GATED AT BOTH ENDS DELIBERATELY.** `gfxc_sel` already ANDs
`wide_en`, so an ungated promote would have been inert anyway — obj bank 4
selects the same read slot as bank 0. Gating the SOURCE too makes bank bit 2
*provably zero* with the profile clear rather than *harmlessly ignored*, and
it is what makes the expression testable on its own.

### THE INSTRUMENTS BUILT FOR THIS SLICE

- **`JTFRAME_SIM_RDPROBE`** (fork commit 12), the harness's SDRAM READ PROBE:
  four optional counters on the one line in `SDRAM::update()` that serves a
  burst beat. Each takes a bank and a half-open byte window and reports reads,
  DISTINCT 128-byte blocks (which on CPS-2 graphics is a TILE-CODE list,
  because a tile code is its own SDRAM address), the first frame and address
  and the range. No RTL; absent the macro every line compiles out — the
  `JTFRAME_SIM_WRAMDUMP` precedent exactly. **Four slots and not two, on
  purpose:** two arm the windows under test and two arm windows that MUST see
  traffic, so a zero is evidence about the CORE and not about the probe.
  Units are burst BEATS, not ACTIVATE commands — do not compare them with
  `--stats` numbers without dividing by the burst length.
- **`JTFRAME_SIM_VIDEO_FIRST/_LAST/_STRIDE`** (fork commit 14): the frame
  writer forks an ImageMagick child per CHANGED frame, which is right for a
  short run and wrong for a 4,000-frame one. Defaults are upstream's.
- **`tests/rtl/tb_obj_bank.v`**: 131,072 vectors — all 65,536 y-words in both
  profile states. bank[2] set **32,768 times wide / 0 stock**; bank[1:0]
  equal to `y[14:13]` throughout; and the six `gfx_tiles.py` encodings each
  decode to their own bank with **none of them setting y bit 15**. Two
  must-fire controls fire: the gate bypassed, and bit 2 read from `y[15]`.
- **`tests/test_mister_gfxc_fetch.sh`**: the demonstration gate. Derives its
  windows FROM THE RTL (`GFXC4_OFFSET`/`GFXC5_OFFSET` and the bank each
  group-C slot sits in) because an instrument that names a physical address is
  invalidated by a memory-map change — the rule 14z-107 (9) paid for twice.
- **`tests/audit_sdram_bank_load.sh --core cps2w --wide BUILD`**: the second
  leg of the traffic instrument, plus a **PEAK per-bank table** derived from
  the run's own reporter intervals, because saturation is a property of the
  worst interval and not of a phase average.

### THE STOCK LEG IS GREEN — THE FPGA SUPERSET INVARIANT HOLDS WITH THE
### PROMOTE AND THE PROGRAM WINDOW IN

- `tests/test_mister_sim_anchor.sh` **PASS** on `cps2w` with stock `vsavj`:
  MAME **2146** / sim **2609** / skew **463** (band ±30, untouched), every
  mapped §4 field agreeing, and all four controls firing (byte-swapped dumps
  rejected, a lost dump rejected before any anchor is computed, no `wram/`
  without the macro, the window non-constant). **A round-1 match start means
  thousands of sprites were drawn through the widened bank chain**, so D3's
  four override files are exercised rather than merely compiled.
- `tests/test_mister_wide_inert.sh` **PASS**: `cps2w` == `cps2`, bit-identical
  work RAM in **101 frames of 101**, with the one-frame-shift control firing.
- `test_jtcores_twin`, `test_mister_wide_gate` (six controls),
  `test_mister_mra_map`, `audit_mister_map_fit`, `mk_mister_page --check` all
  PASS; `tests/run_all_static.sh --strict` **GREEN, 106/0/0**.

### THE DEMONSTRATION IS RED, AND IT IS RED FOR A REASON THAT IS NOT D3's

**No tenant tile has been fetched. No tile of ANY kind has.**
`11_pick_donovan` on `cps2w` with the real `vsavjw.rom`, four SDRAM read
probes armed, 4,000 simulated frames:

| simulated frame | what the core is doing |
|---|---|
| 0-659 | the ROM transfer (the WIDE image takes 659 frames, not the stock 462) |
| 660-925 | the CPS-2 RAM test draws line by line — `WORK / CPS0 / CPS1 / CPS2 / OBJECT` |
| 928-1107 | a second boot screen |
| 1108-1377 | **the test screen draws AGAIN** |
| 1380-1559 | the second screen again |
| 1578-2241 | the QSound / Capcom legal screen, static for 664 frames |
| **2242** | **the machine RESETS — the RAM test starts over.** The cycle repeats |

**Zero reads in SDRAM bank 2 across the whole run** — vanilla obj banks 0 and
2, so not one sprite of any kind is drawn — and zero in both group-C windows.
Bank 3 sees 94,692,120 word reads over **264 distinct 128-byte blocks**, all
inside its first 4 MB: a tiny scroll working set drawn over and over. The same
probe on the STOCK image counts **313,024 reads over 372 distinct blocks in
bank 2** and 2,482 distinct blocks in bank 3, reaching `0x9C177E`.

**THE SHARPEST FORM OF IT: THE STOCK AND WIDE BOOTS ARE TRAFFIC-IDENTICAL FOR
448 FRAMES AND THEN DIVERGE.** Same core, same replay, same probes, frames
counted from reset: the RAM-test ramp is the same values at the same frames,
then 178 frames of 26,848, then 180 frames of 33,984 — identical — and at core
frame **462 the stock image shows the TITLE SCREEN with `CREDITS:1`** while at
core frame **449 the WIDE image starts its boot test over**. The divergence is
at the end of the third boot phase, and that is the narrowest window this lane
can put around the fault today.

**THE ELIMINATIONS ARE THE USEFUL PART.**

* **Not the profile, AND THE WORK RAM SAYS SO ON THE PROJECT'S OWN MASKED
  BASIS.** The identical run with header byte 41 set to `0xFF` produces a
  frame-for-frame identical trace — the same transitions at the same frames,
  the same reset at 2242, 94,691,928 bank-3 reads against 94,692,120. Both
  legs also dump `RAM:$FF0000-$FFFFFF` over frames 3400-3620: of 221 frames
  156 differ, and **every differing byte is in one of the two windows
  CLAUDE.md §4 masks** — the dead stack `$FF7F00-$FF7FFF`, and `$FF043C`, the
  68k↔QSound handshake latch (28 frames, `08` against `04`, which
  `atlas/ram.md:65` records as a one-frame phase). Nowhere else, never more
  than 64 bytes of 65,536. **None of the eight gated sites is the cause —
  which also means the failure exists at the D2 pin and has simply never been
  visible**, because nothing had ever run the WIDE image past the download.
* **Not the core.** `cps2w` runs the STOCK romset to the frozen match-start
  anchor and to bit-identical work RAM against `cps2` (above).
* **Not the download.** `test_mister_sdram_census` compares all 67,108,864
  bytes of all four banks against the map on this exact image and core, and
  passes. The two things a census cannot see — the CPS-2 key and the DSP
  firmware — are byte-identical to the stock image's.
* **Not the romset.** MAME on the same `build/m3b_merged13/rompath`, the same
  replay and a fresh sandbox is at the character-select screen with the full
  18-character wheel and the M6 mark by frame 930.
* **Not the probe.** The same probe, the same binary and the same replay on
  the STOCK image count **313,024 reads over 372 distinct tiles in SDRAM
  bank 2**, first at simulated frame 1544. On the WIDE image that window reads
  zero. A zero here is a fact about the core.

**AND THE PROFILE BIT IS PROVABLY LIVE — VISUALLY, WHICH IS WHY THE FIRST
ELIMINATION CAN BE TRUSTED.** The two legs render the same legal screen
differently: correct with byte 41 = `0xFE`, and **a flat yellow field with only
the CAPCOM logo left** with `0xFF`, because without the download redirect the
16 MB of tenant art aliases over vanilla's obj banks 0/1 *and the whole scroll
window* (`SCR_OFFSET = 0`). A two-legged experiment whose legs differ by ONE
BYTE, and the first thing it produced was a picture that cannot be misread.

### AND THE ROOT-CAUSE PROBE WAS TAKEN: THE SOUND DRIVER, AT MAME FRAME 266

The §4 differential ran before the session closed. `cps2w` + the WIDE image,
`RAM:$FF0000-$FFFFFF` at simulated frames 900-1400 (core 241-741), against
MAME on the same romset and replay at the same game frames, masking the two
windows §4 masks:

| MAME frame | live bytes differing (of 65,536) |
|---|---|
| 241-265 | **2** — `$FF8003` and `$FF8080` only, a constant counter/RNG phase |
| **266** | **14 — the onset** |
| 267 | 42 |
| 281-441 | back to 2-3 |
| **461** | **748** |
| 541-741 | ~870, steady |

**The onset is entirely in the SOUND DRIVER**: `$FF025C/D` (a `$FF02xx`
channel record), `$FF0462/3` (the current-record pointer spill `$FF0460.l` —
MAME resting at `…043C`, the core reading `…025C`, i.e. mid-scan),
`$FF04DB-$FF04E5`, and the two counter bytes that were already off. At frame
267 the per-channel arrays at `$FF04A1-$FF04B5` diverge outright. **Nothing
outside the sound area moves until frame 461**, when it explodes and the boot
is lost.

Two independent instruments now bracket the same fault from opposite sides:
the SDRAM traffic diverges at core frame ~448, and the 68k STATE diverges at
core frame 266 and stays contained in the sound driver for ~180 frames first.
And the sound path is exactly what the profile touched hardest — WIDE v1
relocated **all twenty per-character sound record arrays** above
`CPU:$400000`. **Caution before acting on that**: the pos/neg comparison says
the 6 MB decode changes nothing on the masked basis, so either the boot
jingle uses a record still inside the base 4 MB, or the fault is upstream of
the relocation. Measure first.

### THE BANK-0 TRAFFIC ANSWER: STILL OPEN, AND NOW FOR A NAMED REASON

`mister_map.md` §9 open question 1 asked whether bank 0 absorbs obj bank 5's
select-screen traffic. The instrument's second leg exists and ran
(`--core cps2w --wide build/m3b_merged13`, 2,800 frames, **zero `SDRAM reads
clashed`**), but a run on a looping boot never reaches a select screen, so
**there is no obj bank 5 traffic to measure and the question stays open**.
What the run did measure, from its own reporter intervals and no frozen
boundary: **bank 0 peaks at 54,422 accesses per video frame = 44.0% of its
all-miss ceiling**, bank 1 at 12,043 (9.7%), bank 3 at 8,548 (6.9%) — and
**bank 2 at exactly ZERO**, the boot failure expressed as a number.

**AND THE RUN FOUND A DEFECT IN THE INSTRUMENT, now fixed.** The reporter's
lines are block-buffered into a log the frame counter also writes, so a TORN
line can still match the regex with one spliced field. A phase figure survives
that; a PEAK does not, and one bad row reported a bank-3 peak of **16,870,809
accesses/frame — 13,624% of the physical ceiling** — without comment. The gate
now requires the cumulative counters to be MONOTONIC as well as the
timestamps, drops the rows that are not, and says how many. The peak table is
also restricted to AFTER the download, which is one command per byte and
saturates every bank by construction (81.3% of the ceiling — a command-rate
baseline, not a load the running game produces).

### WHAT IS NOW TRUE, AND WHAT THE NEXT SESSION OPENS ON

**All five RTL slices are in.** `cores/cps2w/hdl` holds TWELVE files — nine
overrides of shared modules and three of our own — the fork's whole-tree delta
is a declared 24 paths, `cores/cps1`/`cps2`/`cps15` are BYTE-UNTOUCHED, and
the override delta is frozen line by line. The profile is complete: every
format cap CPS-2 WIDE v1 needs is lifted, gated, and proven at the expression
level.

**The next session opens on a BUG HUNT, not a slice — and it opens with a
LEAD, not a blank page.** The WIDE romset loops on its own boot; the
eliminations rule out the profile, the core, the download, the romset and the
probe; and the §4 differential names the **68k SOUND DRIVER at MAME frame
266** as the first live divergence, contained there for ~180 frames before it
becomes fatal. **[DONE 14z-107 (11) — THE DISCRIMINATOR RAN AND IT ANSWERED
THREE: the decode works, the raw words are the `.rom`'s, and the CPS-2
DECRYPTOR corrupts every opcode fetched above `$0FFFFF`. Slice D5 fixes it;
the driver trace was never needed. See the 14z-107 (11) section at the top
of this file.]** **BEFORE the driver trace, run the THREE-WAY DISCRIMINATOR (added
14z-107 (10) review) — it is one probe and it can invalidate the trace.**
The report reads "profile-on and profile-off are frame-for-frame identical"
as ELIMINATING the profile. A third reading fits the same evidence and was
not named: **if D4's 6 MB decode does not actually function, then `wide_en`
set behaves exactly like `wide_en` clear for every read above `CPU:$400000`,
and the two runs are identical FOR THAT REASON.** This matters because
WIDE v1 relocated all twenty per-character sound record arrays above
`$400000`, and the sound driver is precisely the subsystem that diverges.
The census proves the DATA is placed; nothing yet proves the 68k can READ
it. So instrument `rom_cs`/`main_rom_addr` for `A >= $400000` across the
boot window with `wide_en` SET, and split three ways:
  * **zero such reads** -> the relocation is not implicated in the boot
    fault, the fault is elsewhere, and D4 stays UNPROVEN (a §12 hole);
  * **reads occur, bytes correct** -> D4 works, the sound path is the
    right hunt, proceed to the trace;
  * **reads occur, bytes wrong** -> **D4 IS THE BUG** and the sound-driver
    divergence is a downstream symptom; the trace would have burned hours
    on a consequence.
Only after that, start at `PRG:0x0011DE` (the driver's dispatch prologue,
`atlas/ram.md:66`) and at what the boot jingle's record chain reads.

**AND THE HONEST HEADLINE:** D3 was scoped as "the payoff slice — the first
time a tenant tile is fetched on the core". It is not that. It is the slice
that makes the fetch POSSIBLE and proves the mechanism exhaustively; the fetch
itself is blocked behind a fault that predates it and that this session
located, bracketed and eliminated four candidates for.

**STILL OPEN FOR THE MAINTAINER:** MiSTer PACKAGING (which MRA is the core's
MAIN one; how a release carries both `vsav.zip` flavours) — unchanged, and
still not blocking.

**THE 14z-107 SUB-ENTRIES (1)-(9) ARE IN `STATE_HISTORY.md`** — rolled at the
14z-108 close, exactly as the 14z-107 CLOSE (final) said they should be:
their findings are all restated in the two CLOSE entries above, in (10)-(12),
or in the live docs. Nine sections, 1,582 lines, moved BYTE-VERBATIM to the
top of the archive's body: slice D2 (9), the four held buttons (8), the
video-sensitive anchor (7), slice D1 (6), slice D0 (5), the placement map (4),
the SDRAM model's dropped address bit (3), the memory-map truth (2), and the
session that first ran the §4 oracle on a third implementation (1).
**This is the first time a group's SUB-ENTRIES have been rolled while the
group itself stays live**, which the rollover rule does not contemplate: the
rule speaks of whole groups and THE LEDGER carries one line per group, so
nothing was added to the ledger — 14z-107 is still a live group here. Look
them up by section name in `STATE_HISTORY.md`, as with any archived entry.

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

- Session 14z-106 CLOSE — ritual complete: HOUSEKEEPING executed (the 14z-105 evidence logs + the guard-corpus TSV committed, the rehearsal probes attic'd, `../build_attic_14z102` 8.1 GB deleted under the standing policy, `emu/fbneo`'s modified content verified as patches 0001+0002) and THE MiSTer ARC OPENED with no RTL touched — the framing RULED (an EXTENSION OF JOTEGO'S jtcps CORE, not an FPGA re-implementation of MAME) and all five alignment questions answered the same day (separate core, GPL-3.0 fork, measure-then-choose profile, sim = gate / hardware = field test, MRA+RBF with a stock-vsavj reference leg); LICENSE = GPL-3.0; slice A landed the public fork `DefinitelyFrenchName/jtcores@vampire-saved` with the separate core `cores/cps2w` -> `jtcps2w.rbf`, pinned as submodule `emu/jtcores` + `tools/setup_jtcores.sh` + gate `test_jtcores_twin`, and the twin proof MEASURED (the vsavj MRA byte-identical to stock cps2's except `<rbf>`); slice B measured the fit (`mister_fit.md`: PRG 4.82 MB, QSound banks 0x80-0x8E all aliasing, GFX 52,347 roster codes / 6.39 MB against 4,028 blank tiles / 0.49 MB in ALL of vanilla's 32 MB — a wider GFX tier REQUIRED) and slice C proved THE VERILATOR SIMULATION LANE ON macOS (stock jtcps2 running vsavj, ~1.4 s/frame, the full recipe in `docs/platform/mister.md`, the `.rpl` -> `sim_inputs.hex` translator gated)  [+3 more entries]  [rolled 14z-107 close (final)]
- Session 14z-105 CLOSE (final) — THE MAINTAINER-DIRECTED WINDOW EXECUTED END TO END and field-confirmed: W1 the OBORO SELECT HOOK (cursor on Bishamon + hold START -> vanilla vsavj's Oboro, id 0x18, P1 and P2, vanilla's own Gallon-variant idiom one cell over) and W2 the VERSION STRING ("M6" at the select screen, the naked-eye A/B tell CLAUDE.md §5 had wanted since 14z-92, authored glyphs pixel-exact) — frozen as donovan-m11 / huitzil-m20 / pyron-m14 / merged-m6 with the stock twin m5_stock6 = `883e7d17` BIT-IDENTICAL, every gate and both soaks green, pushed 2026-08-22; the GFX TILE CODEC was found MIRRORED on the way (plane bit i draws at pixel 7-i; 14 sessions old, nothing had ever read pixel ORDER until the first authored tile) and the 14z-104 prediction that more sprites would move the select-window specs DIED by measurement over all 148 specs; RELEASE PACKAGING landed (`release/merged-m6/`, xdelta3 against the reference dumps, no ROM byte in the package) and was ruled IN-TREE until MiSTer  [+3 more entries]  [rolled 14z-107 close]
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
