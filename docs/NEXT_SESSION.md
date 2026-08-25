# NEXT SESSION — orientation (rewritten at the 14z-108 CLOSE, 2026-08-25)

> ## **START HERE. THE ARC IS MiSTer. A TENANT HAS FOUGHT ON THE CORE,
> ## AND THE CORE FITS A CYCLONE V AND CLOSES TIMING.**
> ## Download -> boot -> select -> the extended wheel -> a tenant picked ->
> ## a tenant FIGHTING, with its fighter art coming out of SDRAM. Six RTL
> ## slices (D0-D5), the stock legs green, every control firing — and as of
> ## 14z-108 it SYNTHESISES, with +206 ALMs and +0.066 ns of slack.
> ## **WHAT HAS NEVER HAPPENED IS HARDWARE.** No `.rbf` has been loaded
> ## onto a DE10-Nano, no MRA has run on real silicon, no analog output
> ## has been seen. Read those two halves together: the design is proven
> ## CORRECT in simulation and BUILDABLE on the toolchain, and it has
> ## never been switched on.
> ##
> ## **QUARTUS IS DONE — 14z-108, AND THE ANSWER IS (a): IT FITS AND
> ## CLOSES TIMING.** Cyclone V 5CSEBA6U23I7, Quartus 20.1.1 Lite via
> ## `jotego/jtcore20x`, pin `7b9a0d2d`, **`cps2` built FIRST as the
> ## reference leg**. WIDE costs **+206 ALMs (+1.1%)** and +2,048 memory
> ## bits; RAM blocks, DSPs and PLLs unchanged; nothing near overflow.
> ## **SDRAM 96 MHz, slow corner: `cps2` +0.144 ns / `cps2w` +0.066 ns.**
> ## Zero failing paths, TNS 0.000 everywhere, `.rbf` produced for both.
> ## **CARRY THIS NUMBER: the SDRAM domain is the critical path in BOTH
> ## cores and WIDE eats 0.078 ns of the control's 0.144 — over half the
> ## margin. A PASS, NOT A WARNING, and the figure ANY FUTURE SLICE MUST
> ## RE-MEASURE.** `cps2` at +0.144 shows the margin was modest already.
> ##
> ## **THE OPENER IS NOW HARDWARE — AND IT IS THE MAINTAINER'S, NOT
> ## MINE.** Synthesis settles BUILDABILITY and nothing else: no `.rbf`
> ## has been loaded onto a DE10-Nano, no MRA has run on real silicon, no
> ## analog output has been seen. That is a field test (`mister_core.md`
> ## §1: MiSTer + 128 MB module + Jammix -> CRT at native timing) and it
> ## needs the maintainer at the board. **Before it: MiSTer PACKAGING is
> ## still unanswered** — which MRA is the core's MAIN one, and how a
> ## release carries both `vsav.zip` flavours (STATE "Decisions
> ## pending"). Both must be settled before anything ships.
> ##
> ## **THE §4 TENANT ORACLE IS DONE — 14z-108, AND IT AGREES.** A tenant
> ## does not merely fetch art on the core, it FIGHTS CORRECTLY: MAME
> ## anchor 2886, sim 3546, skew 660 (= the 659-frame transfer PLUS ONE,
> ## the same +1 the legacy replay shows on a 462-frame transfer, so the
> ## boot offset is a CONSTANT). **`p1_hitbox_base` is `0x003FA9D0` on
> ## BOTH legs** — the core loaded the tenant's RELOCATED character record
> ## from above `CPU:$400000`. HP, white HP, timer, position, meter,
> ## `ptr64` and `word132` all agree; the only disagreement is
> ## `p2_hitbox_base`, the sound-fed CPU draw, excluded by name for a
> ## measured reason and proven LIVE by a control. Gate:
> ## `tests/test_mister_tenant_oracle.sh` (emulator, ~65 min).
> ##
> ## **WHAT IS LEFT IN SIMULATION, in value order.** The QSound extension
> ## HEARD (banks `0x80-0x8E` are placed and now proven to FIT the 1 MB
> ## window — `SLOT5_AW` 20 against `0xF0000` of samples — but no sample
> ## from them has ever played); the scroll path with a wide GFX map
> ## (untouched, capped at 8 MB with no bank input anywhere in its chain);
> ## and a frame compared PROGRAMMATICALLY against MAME's (never — the
> ## committed select-screen images are a naked-eye pair, not a verdict).
> ##
> ## **PENDING OFF-MACHINE: a FITTER SEED SWEEP** (3 `cps2w` seeds + 1
> ## `cps2` control), maintainer-approved 2026-08-25 and running on the
> ## Windows box. It exists because the attribution showed `cps2w` has
> ## FIVE bank-arbitration paths inside 0.065 ns where the control has ONE
> ## outlier with a 0.27 ns gap behind it, and the dominant delay term is
> ## ROUTING to a pin — which is exactly what varies between seeds. A
> ## single-seed +0.066 ns is least informative in that configuration. The
> ## control seed is the one to keep if only some run: without it a
> ## `cps2w` spread cannot be told from a TOOL spread.
> ##
> ## **QUEUED, ONE FORK COMMIT: `cores/cps2w/README.md` IS STALE.** It
> ## still says "Status: slice D1" and calls D2-D4 "not here yet", with a
> ## file table of FIVE `hdl/` files against the tree's THIRTEEN — written
> ## at `4840df8a` and never updated after `0df6f000`. Found by the
> ## Quartus session, which stopped and asked before building. Not fixed
> ## during 14z-108 because a README commit moves the pin out from under
> ## a build in flight; do it once the synthesis numbers land.
> ##
> ## **WHAT 14z-108 MEASURED, so it is not re-measured.**
> ## **(1) THE SIM HARNESS'S DIRECTION BITS WERE REVERSED END FOR END**,
> ## not transposed in two. Measured on ALL FOUR against the game's own P1
> ## mirror `RAM:$FF8058.w` (`tests/replays/107_four_directions.rpl`,
> ## attract-only on STOCK `vsavj`, MAME vs `cps2w`, both dump sets
> ## integrity-checked): Up arrived as Right, Down as Left, Left as Down,
> ## Right as Up. 14z-107 (12) had two data points and inferred a two-bit
> ## SWAP leaving Up and Right untouched — **that was wrong, and a two-bit
> ## fix would have left half the defect in the tree.** Mechanism:
> ## `test.cpp:380` copies file bits 4-7 straight onto `joystick1[3:0]`
> ## and jtframe's port is MSB-FIRST (`jtframe_keyboard.v:107-110`), so
> ## the file map is `bit4=Right bit5=Left bit6=Down bit7=Up`. Fault is
> ## OURS, not jtframe's — one dict in `tools/rpl2siminputs.py`, no fork
> ## commit, no RTL. **The fork pin is unchanged at `7b9a0d2d`.**
> ## **(2) A TENANT FIGHTING.** `test_mister_gfxc_fetch --rpl
> ## 36_pick_tenant_cell --frames 4400` PASSES in full: obj bank 4
> ## **9,388,928 reads / 1,735 distinct codes `0xAD8F-0xEE42`**, 843
> ## traffic frames after match start; obj bank 5 206 codes; both inside
> ## their frozen extents; the control leg (header byte 41 `0xFE`->`0xFF`)
> ## at ZERO on both windows while still reading 105 M in bank 3.
> ## **(3) BANK 1 UNDER LOAD: GO.** Same run, `--stats`: ba1 peaks at
> ## 15,496 acc/frame (**12.5%** of ceiling) with the fighter art sharing
> ## the bank with QSound, and **ZERO `SDRAM reads clashed` in 3,738
> ## frames**. ba0 peaks 54,363 (43.9%), unchanged from stock.
> ##
> ## **THE ANCHOR DID NOT MOVE, AND THAT WAS PROVEN RATHER THAN ASSUMED.**
> ## `test_rpl2siminputs` freezes two values and the record said a bit-map
> ## fix moved BOTH. **It moved one.** `05_timeout_idle` scripts NO
> ## direction token, so its sha1 `eb3e1d04…` cannot change — and since
> ## that is `test_mister_sim_anchor`'s replay, its `sim_inputs.hex` is
> ## byte-identical across the fix and the frozen anchor (MAME 2146 / sim
> ## 2609 / skew 463) **could not move**. The 45-minute gate was NOT
> ## re-run, and the gate header states that as the reason. Corrected in
> ## five documents.
> ##
> ## **STANDING WARNINGS. ALL PAID FOR AGAIN THIS SESSION.**
> ## **(1) SUSPECT THE INSTRUMENT BEFORE THE RTL** — the count is now
> ## EIGHT, and 14z-108 added four more caught BEFORE use, all in one new
> ## analysis block: cumulative counters read as per-interval; a
> ## picosecond timestamp read as an index; a clash counter matching this
> ## report's OWN PROSE about clashes; and a "peak" that was the ROM
> ## DOWNLOAD on all four banks at once. A fifth — a `05`-independence
> ## check that PASSED because gawk's `and()`/`strtonum()` do not exist on
> ## BWK awk, so awk exited 2 and the `else` arm read as success — was
> ## caught only by writing its positive control first. **THE INSTRUMENT
> ## PROTOCOL (`docs/project/gotchas.md`) IS THE MOST LOAD-BEARING
> ## DOCUMENT IN THIS LANE.**
> ## **(2) NEVER EDIT A SCRIPT WHILE A RUN IS IN FLIGHT** — `sh` reads by
> ## byte offset. `tests/` and `tools/` were frozen for the whole 2.5-hour
> ## tenant run and all edits were made before it launched.
> ## **(3) CONFIRM THE RIG ON MAME BEFORE PAYING FOR THE SIM.**
> ## `36_pick_tenant_cell` was verified to reach P1 `+0x382 = 0x13` under
> ## MAME (a ~2-minute run) BEFORE the 2.5-hour simulation, so a zero from
> ## the sim would have been a finding about the CORE rather than about
> ## the replay.
> ##
> ## **AFTER QUARTUS, IN ORDER.** The QSound extension has never been
> ## heard; the scroll path with a wide GFX map is untouched; no frame has
> ## ever been compared programmatically against MAME's (the two committed
> ## select-screen images are a naked-eye pair, not a verdict);
> ## `mister_core.md` §12 is the honest ledger of all of it. **And the
> ## placement's margins remain thin: 0.125 MB of slack in 64 MB, SDRAM
> ## bank 1 EXACTLY FULL, and the group-C ROMSET REGION cannot grow at
> ## all** — tenant art may grow freely inside the existing 16 MB, but a
> ## fifth group-C member has nowhere to go.
> ##
> ## **STILL OPEN FOR THE MAINTAINER: MiSTer PACKAGING** — which MRA is
> ## the core's MAIN one, and how a release carries both `vsav.zip`
> ## flavours (STATE "Decisions pending"). Both must be answered before a
> ## release; nothing above blocks on them. **FUTURE, UNSCHEDULED:** the
> ## LIVING-DOCUMENTATION effort and DISTILLING AI SKILLS from the
> ## project's learnings. Both follow MiSTer.
> ##
> ## **THE GAME SIDE IS PARKED AND GREEN.** 14z-105 frozen as donovan-m11
> ## / huitzil-m20 / pyron-m14 / merged-m6, field-confirmed and pushed
> ## 2026-08-22; play with `tools/run_wide.sh build/m3b_merged13 fbneo`.
> ## Release packaging is done (`release/merged-m6/`).
> ##
> ## **THE LANE, IN TWO COMMANDS** (`HANDOFF.md` "MiSTer" has the rest;
> ## `export JTSIM_SCRATCH=/tmp/vampire-saved-jtsim`, NEVER inside the
> ## repo; ~1 s per simulated frame; the WIDE transfer is **659** frames
> ## and the stock one 462, so every absolute frame moves by 197; and
> ## `--wram` dumps an SDRAM address — `RAM:$FF0000` is bank 0 byte
> ## `0x600000` on `cps2`, **`0x648000` on `cps2w`**):
> ## `tools/run_sim_jtcps2.sh <rpl> <outdir> --frames N --wram A B` and
> ## `tools/mister_mra.sh --core cps2w --wide build/m3b_merged13 --out <dir OUTSIDE the repo>`.
> ## **THE FORK: `DefinitelyFrenchName/jtcores@vampire-saved`, pin
> ## `7b9a0d2d`, EIGHTEEN commits, PUBLIC AND CURRENT** — unchanged by
> ## 14z-108, which touched no RTL. Fork pushes are standing-authorised;
> ## **THE MAIN REPO'S PUSH STATE, CORRECTED 14z-108 BY CHECKING THE
> ## REMOTE RATHER THAN THE RECORD:** `origin/main` HAS been pushed and
> ## holds `a93e071`, the 14z-107 CLOSE (final) — `git ls-remote`
> ## confirms it and the reflog says `update by push`. The 14z-107 close
> ## recorded "36 commits ahead, ALL LOCAL, the main repo is NEVER
> ## pushed", which was true WHEN WRITTEN and is not true now; a push
> ## happened after it. **Only 14z-108's FIVE commits are local.** Push
> ## policy is the maintainer's call and nothing was pushed by this
> ## session — but do not repeat the "never pushed" figure from prose.
> ## CHECK `git ls-remote` INSTEAD: a tracking ref is a claim about the
> ## last fetch, and prose is a claim about the day it was written.


> ## **SLICE LOG — 14z-107 (11)+(12): THE BOOT FAILURE ROOT-CAUSED AND
> ## FIXED (D5), THE FIRST TENANT TILE EVER FETCHED, BANK 0 ANSWERED, AND
> ## THE FIGHTER HALF BLOCKED BY THE HARNESS.**
> ## **D3 — the CPS-2 Turbo object promote** (fork `b9899fa8`),
> ## `cores/cps2w/hdl/jtcps2w_obj_bank.v`:
> ## `assign bank = { wide_en & table_y[12], table_y[14:13] };` read in the
> ## ELSE arm of the sprite-list terminator test, which is the reference
> ## core's VERBATIM (the ORDER is the rule: `table_y[15]` IS the
> ## terminator). `rom0_bank[2]` UNTIED, the bank three bits wide at every
> ## port from the frame table to SDRAM — which cost FOUR override files,
> ## three of them nothing but a width. **Swept over its whole input
> ## space:** 131,072 vectors, bank[2] set 32,768 times wide / **0** stock,
> ## the six `gfx_tiles.py` encodings each decoding to their own bank, none
> ## of them setting y bit 15. Two must-fire controls fire.
> ## **D4 — the 6 MB program window** (fork `dd242a65`):
> ## `wide_en & RnW & (A[23:21]==3'b010)`,
> ## `rom_addr`/`main_rom_addr`/`SLOT3_AW` 21->22, and the `one_wait`
> ## boundary `wide_en ? 4'h6 : 4'h5`. **It shipped WITH D3 because D3
> ## cannot be demonstrated without it:** the select screen's roster record
> ## is allocated in `wide_ext` above `CPU:$400000`, so a 4 MB decode
> ## cannot read the table that names the tenant cells and the promote has
> ## nothing to promote.
> ## **D5 — THE DECRYPTION RANGE, and it is the finding of the arc** (fork
> ## `c00d7ce7`; the retraction of D4's old claim is `7b9a0d2d`). See the
> ## banner above. The measurement that produced it is the 68k
> ## program-ROM read probe (`JTCPS2W_PRGPROBE`, fork `72738d51`,
> ## sim-only): ten completed reads above `$400000`, all at
> ## `CPU:$4BE7C0-$4BE7C8`, all `fc = 2` (USER PROGRAM — opcode fetches),
> ## every RAW word the `.rom`'s byte for byte and **every latched word
> ## different**; 54,961,148 reads below `$400000` as the must-fire
> ## control; a `wide_en`-clear leg completing zero. With D5 in, the same
> ## fetches arrive as memory holds them, completed reads above `$400000`
> ## go to **1,189,750** spanning `CPU:$412BA0-$4D100E` (= `wide_ext` to
> ## the byte) with 20,000/20,000 sampled records matching the `.rom`, and
> ## the boot reaches the select screen.
> ## **THE PAYOFF: 9,038,400 reads over 105 DISTINCT TILE CODES
> ## `0x74D6-0xFE41` in group-C obj bank 5** — the select-wheel tenant art
> ## — first at simulated frame 1556, every code inside the roster's frozen
> ## live extent `0xFFDB`, control leg at zero.
> ## `tests/test_mister_gfxc_fetch.sh`'s WHEEL half is GREEN.
> ## **BOTH STOCK LEGS GREEN WITH D5 IN** (the FPGA superset invariant on
> ## the one change that could have moved it): `test_mister_wide_inert`
> ## bit-identical work RAM 101/101 with its control firing, and
> ## `test_mister_sim_anchor` at 2609 / 2146 / 463. True by construction as
> ## well as by measurement — `rng_eff` IS `addr_rng` with `wide_en` clear.
> ## **BANK 0 UNDER THE REDIRECT: ANSWERED, GO** (14z-107 (12),
> ## `mister_map.md` §9 open question 1). 40,717 accesses/frame through the
> ## select screen = **32.9%** of its 123,825 all-miss ceiling, 41,535
> ## in-match, whole-run peak 54,363 (**43.9%**), data bus 16-18%, **ZERO
> ## `SDRAM reads clashed` in 3,500 frames**; the redirect costs ~1,000
> ## accesses/frame (~2.5%) against stock. The instrument verified its own
> ## phase boundaries — the run's anchor at **2806** = the frozen 2609 +
> ## the 197-frame WIDE/stock transfer difference.
> ## **OBJ BANK 4 IS STILL UNPROVEN AND THE REASON IS THE HARNESS** — see
> ## the opener. A tenant has still never fought on the core.
> ## **FOUR NEW GATES / INSTRUMENTS:**
> ## `tests/test_mister_prg_probe.sh` (ci_portable, ~3 s) — the probe's
> ## contract and `tools/prgprobe_verdict.py`'s VERDICT LOGIC, on synthetic
> ## logs whose answer is known by construction: three answers plus FOUR
> ## refusals, two of them frozen from the real defects.
> ## `tests/test_mister_prg_window.sh` (emulator, ~2 x 40 min) — the
> ## measured pair, frozen, two `.rom` images differing in ONE BYTE.
> ## `tests/test_mister_gfxc_fetch.sh` (emulator, ~2 x 65 min) — the
> ## demonstration; its first real measurement found TWO defects IN ITSELF
> ## (the tile code computed from the ABSOLUTE SDRAM address rather than
> ## relative to the armed window's base; a liveness control demanding
> ## vanilla obj traffic in a leg that cannot boot by construction).
> ## `tests/audit_sdram_bank_load.sh` gained the WIDE leg's real run.
> ## **AND TWO HARNESS INSTRUMENTS FROM (10), still the workhorses:**
> ## `JTFRAME_SIM_RDPROBE` (fork `17a5dc2b`) — FOUR SDRAM read counters,
> ## each a bank plus a half-open byte window, reporting reads / DISTINCT
> ## 128-byte blocks (which on CPS-2 graphics IS a tile-code list) / first
> ## frame / address range. Four slots and not two ON PURPOSE: two arm the
> ## windows under test and two arm windows that MUST see traffic, so a
> ## zero is evidence about the CORE and not about the probe. Units are
> ## burst BEATS, not ACTIVATEs. `JTFRAME_SIM_VIDEO_FIRST/_LAST/_STRIDE`
> ## (fork `fd454393`) bounds the frame writer, so a 4,000-frame run
> ## writes a filmstrip instead of ~3,000 jpgs.

> ## **SLICE LOG (history) — 14z-107 (9): MiSTer SLICE D2 IS DONE. THE WIDE ROMSET
> ## HAS A PLACE IN SDRAM AND EVERY BYTE OF IT WAS COUNTED.** Fork commit
> ## `0df6f000`, **PUSHED** (fork pushes are standing-authorised now; the
> ## MAIN repo is still never pushed *[CORRECTED 14z-108: not true any
> ## more — see the banner]*). `cores/cps1`/`cps2`/`cps15`
> ## BYTE-UNTOUCHED.
> ## **WHAT SHIPPED:** the bank-0 re-pack (VRAM `0x600000`, ORAM `0x640000`,
> ## WRAM `0x648000`, Z80 `0x658000`, making room for a 6 MB PRG), the
> ## group-C GFX redirect (obj bank 4 → SDRAM bank 1, obj bank 5 → bank 0),
> ## the QSound split across two banks on `pcm_addr[23]`, the PCM-high slot
> ## and the two GFX slots, and **ONE new jtframe file**
> ## `hdl/sdram/jtframe_ram1_7slots.v` — a mechanical sibling of
> ## `ram1_5slots.v`, pulled by `cores/cps2w`'s own `game.yaml` and NOT added
> ## to jtframe's shared `jtframe_sdram64.yaml` (that list is included by
> ## every core). `cores/cps2w/hdl` goes from four files to six.
> ## **EVERYTHING BEHAVIOURAL IS GATED — five `wide_en` sites now.** The one
> ## exception is declared, not hidden: the bank-0 re-pack is unconditional
> ## because `SLOTn_OFFSET` are elaboration-time parameters. It is a
> ## RELOCATION with no behavioural surface, and `test_mister_wide_inert`
> ## measures that (`cps2w` == `cps2`, bit-identical work RAM 540-640).
> ## **THE EVIDENCE IS AN SDRAM IMAGE CENSUS, NOT A REPLAY** — and it has to
> ## be: `rom0_bank[2]` is TIED LOW until D3, so D2 changes no fetch at all.
> ## `tools/mister_sdram_census.py` replays the download mapping (regions,
> ## the QSound split, the group-C redirect, the CPS-2 GFX scramble) and
> ## compares **all 67,108,864 bytes of all four banks**. PASS on every bank
> ## on the WIDE image (66,265,152 B, transfer complete at simulated frame
> ## 659). Controls: a 1 KiB shift of any constant is rejected; banks 1/2/3
> ## byte-identical between the two cores on a stock image with bank 0
> ## differing; banks 2+3 DIFFERING between them on the WIDE image, because
> ## without the redirect group C aliases onto vanilla's art.
> ## **AND THE CENSUS CONTRADICTED THE MAP. THE CENSUS WON.** The fit's slack
> ## is **0.125 MB, not 0.708**, and **SDRAM bank 1 is EXACTLY FULL**. The map
> ## sized the group-C obj banks by the art's live FOOTPRINT; the MRA
> ## downloads the whole declared region, so each reserves its full 8 MB.
> ## Both consequences point opposite ways: tenant art may now grow freely
> ## inside the existing 16 MB (one more tile overflows nothing), and the
> ## group-C ROMSET REGION cannot grow at all. Corrected in place in
> ## `mister_map.md` and in `tests/audit_mister_map_fit.sh`.
> ## **STOCK LEG GREEN:** `test_mister_sim_anchor` 2146 / 2609 / 463 on
> ## `cps2w`; `test_mister_wide_inert` bit-identical.
> ## **NEXT: slice D3** — the obj promote (`jtcps2_obj_scan.v:152`
> ## `st3_bank <= {table_y[12], table_y[14:13]}`, the CPS-2 Turbo rule) and
> ## the `dr_bank`/`obj_bank`/`rom_bank`/`rom0_bank` chain widened to 3 bits.
> ## D2 built the destination and the plumbing; D3 drives `rom0_bank[2]`.



> ## **SLICE LOG (history) — 14z-107 (8): THE SIMULATED CONTROLLER WAS PRESSING
> ## FOUR BUTTONS NOBODY SCRIPTED.** jtframe v1.7.3's `SimInputs` held
> ## **P1's AND P2's buttons 5 and 6 DOWN** on every 6-button core — two
> ## 8-bit constants on a `[9:0]` **ACTIVE-LOW** port: `parse_inputs()`
> ## masks with `&0xf0` (throwing away the bits the line above released) and
> ## the constructor seeds `joystick1..4 = 0xff`, which `parse_inputs()`
> ## never corrects for players 2-4. So the MAME leg and the sim leg of the
> ## §4 oracle had never been running the same inputs — a FIDELITY defect in
> ## the instrument, recorded in 14z-107 (7) and FIXED here.
> ## **VERIFIED BEFORE IT WAS FIXED, AGAINST A SECOND IMPLEMENTATION, NOT
> ## AGAINST THE SOURCE.** A MAME hold-vs-not differential located the
> ## game's own input mirror — `RAM:$FF8058`/`$FF805A` (P1 held / new-press)
> ## and `$FF805C`/`$FF805E` (P2), 0x40 = button 6, 0x20 = button 5, live
> ## from MAME frame ~92. The **pre-fix sim's `$FF8040-$FF8070` block is
> ## byte-identical to MAME running the same ROM with P1 AND P2 buttons 5+6
> ## physically held**; after the fix it is byte-identical to MAME's
> ## no-input leg. The fix's whole boot footprint is **8 bytes of 65,536**
> ## (`$FF8058/5A/5C/5E` 0x60→0x00, `$FF8060-63` 0x40→0x00).
> ## **FIX: fork commit `519aff8b` — `& ~0xf` and `0x3ff`, one file, no RTL,
> ## no macro, LOCAL ONLY** (push authorisation still held). It is a plain
> ## upstream bug and the commit reads as a clean upstream report; nothing
> ## was filed. Gate: `test_sim_wram_contract` check 12 (+ its control).
> ## **THE RE-FREEZE: NOTHING MOVED, AND THAT IS THE RESULT.** MAME 2146 /
> ## sim **2609** / skew **463**, re-measured on the REFERENCE core over
> ## 2100-3000 so the window could not box the answer in; band untouched at
> ## ±30. Mechanism: a button held from before boot produces no PRESS EDGE,
> ## and this replay's only inputs are a coin, a start and one button-1 tap.
> ## Every §4 field still agrees, and the sound-state-fed arcade draw is the
> ## same pair as before (MAME `$0AE9D4` / sim `$0A9518`).
> ## **`audit_sdram_bank_load`'s phase boundaries are keyed to the anchor
> ## and therefore did NOT move** (2608 / 2614); re-deriving the table from
> ## `build/sdram_bank_load_14z107.log` reproduces it exactly.
> ## **STILL DEFERRED (maintainer): the COVERAGE half** — making buttons 5/6
> ## and P2 SCRIPTABLE. `tools/rpl2siminputs.py` still refuses them loudly.
> ## **NEXT: slice D2** (bank-0 repack, the group-C GFX redirect, the QSound
> ## bank split on `qsnd_addr[23]`, `jtframe_ram1_7slots`, the two new GFX
> ## slots).


> ## **SLICE LOG (history) — 14z-107 (7): THE "VIDEO-SENSITIVE ANCHOR" IS
> ## ROOT-CAUSED, AND IT INVERTED A VERDICT.** The picture never touched
> ## the CPU. jtframe's Verilator harness forks an ImageMagick child per
> ## CHANGED frame — ALWAYS, `-video` is not what enables it — and that
> ## child ended with **`exit(0)`**, which runs the C stdio cleanup.
> ## **libc++'s `basic_filebuf` is a `FILE*`**, so the child `fclose()`d the
> ## copy it inherited of the parent's `sim_inputs.hex` stream, and POSIX
> ## makes `fclose()` on a read stream REWIND THE SHARED FILE OFFSET. The
> ## parent then re-read input lines it had already consumed: **the
> ## simulated CONTROLLER was being replayed, once per fork** — and the
> ## number of forks follows the PICTURE.
> ## **THE 2x2 (681 dumps per leg, all four sets asserted complete):** frame
> ## output OFF, LUT present vs absent → **bit-identical 681/681**; same
> ## core, frame output OFF vs FORK → **483 of 681 differ**, first at frame
> ## **2051**, ONE byte, `RAM:$FF8060`, the **START bitmask**; black-screen
> ## core OFF vs FORK → bit-identical (it forks once, not 1,348 times); fork
> ## mode run twice → bit-identical, so the corruption is DETERMINISTIC.
> ## **THE FROZEN ANCHOR WAS THE ARTIFACT: re-measured MAME 2146 / sim
> ## 2609 / skew 463**, and every leg that does not fork agrees on 2609.
> ## D1's RED 2609/463 was right; the green 2502/356 was the corrupted run.
> ## Band unchanged at +/- 30 — the centre moved onto a named mechanism.
> ## **FIXES (fork, LOCAL ONLY):** `7cf1eedb` the child now `_exit(0)`s (the
> ## real repair, one word); `692ba4d6` adds `JTFRAME_SIM_NOVIDEO` + reaps
> ## the children, and `tools/run_sim_jtcps2.sh --frame-output off` is the
> ## lane's DEFAULT so a state oracle does nothing with the pixels at all.
> ## **INTEGRITY:** `tools/check_wram_dumps.py` — `compare_fields.py` GLOBS,
> ## so a lost dump used to just move the anchor. Every `--wram` run now
> ## asserts its set is complete, and the anchor gate checks BOTH legs and
> ## asserts the frame-output mode from the run's own log banner.
> ## **THE DUMPS WERE NEVER CORRUPTED** — they are written by the PARENT
> ## from an `ofstream` opened and closed inside one call, with no
> ## descriptor open across the fork. The INPUTS were.
> ## **AND ONE NEW FINDING, RECORDED NOT FIXED: v1.7.3's `SimInputs` HOLDS
> ## P1 BUTTONS 5 AND 6 DOWN** (`test.cpp:201`'s `& 0xf0` drops bits 9:8;
> ## active low; `jtcps2_main.v:266` wires them in). The MAME and sim legs
> ## are therefore not running identical inputs. The one-line fix moves the
> ## anchor again, so it belongs with the queued P2/6-button fork commit —
> ## that pending item is upgraded from COVERAGE to FIDELITY.
> ## **[FIXED 14z-107 (8), fork commit `519aff8b` — and P2's buttons 5/6
> ## were held too. The anchor did NOT move. See the newest block above.]**
> ## **NEXT: slice D2** (bank-0 repack, the group-C GFX redirect, the QSound
> ## bank split on `qsnd_addr[23]`, `jtframe_ram1_7slots`, the two new GFX
> ## slots) — and it can now change video output without the anchor going
> ## ambiguous, which was the whole point of this session.

> ## **SLICE LOG (history) — 14z-107 (6): MiSTer SLICE D1 IS DONE, and it is the
> ## slice where `cores/cps2w` STOPS BEING cfg-ONLY.** The QSound
> ## sample-bank width fix ships behind a **RUNTIME** profile gate: **MRA
> ## header byte 41, bit 0, ACTIVE LOW** (`0xFF` fill = profile OFF, the
> ## WIDE MRA writes `0xFE`). So stock `vsavj` on `jtcps2w.rbf` is a STOCK
> ## MACHINE by construction, which is what makes rule 1 v2's
> ## "profile-gated" a fact on FPGA rather than an inertness argument.
> ## Fork commit `4840df8a` — **LOCAL ONLY, NOT PUSHED** (the maintainer has
> ## not re-confirmed push authorisation; every other fork commit is
> ## public).
> ## **`cores/cps2w/hdl` now holds FOUR files** — two new
> ## (`jtcps2w_profile.v`, `jtcps2w_qsnd_bank.v`) and two OVERRIDES of
> ## SHARED files (`jtcps15_sound.v` from cps15, `jtcps2_game.v` from
> ## cps2). `cores/cps1`, `cores/cps2` and `cores/cps15` are BYTE-UNTOUCHED
> ## and that is now a `git diff` assertion (`test_jtcores_twin` 2e).
> ## **THREE THINGS THAT CHANGE HOW TO WORK HERE:**
> ## **(1) `PCM_AW` 23 → 24 DOES NOT COMPILE** and three documents said it
> ## did. `jtframe_romrq_bcache.v:74` replicates `SDRAMW-AW` zeroes, which
> ## goes NEGATIVE past `AW = SDRAMW = 23` — Verilator refuses to elaborate.
> ## An 8-bit jtframe slot reaches **8 MB of a 16 MB bank**, which is why
> ## the map splits QSound across two banks. Struck in place everywhere.
> ## **(2) `jtframe files` DEDUPS BY FULL PATH**, so overriding a shared
> ## file means DELETING it from the original core's list — and a `.yaml`
> ## pulled with `get:` drags the shared file with it, so cps2w had to
> ## INLINE cps15's `qsound.yaml` instead of pulling it.
> ## **(3) The bank bit IS `dsp_ab[7]`, validated against MAME's LLE
> ## qsound device** (`map(0x0000,0x7fff).mirror(0x8000)` +
> ## `m_rom_bank = (m_rom_bank & 0x8000U) | offset`), not against the
> ## commented-out permutation jtcps15 carries.
> ## **NEXT: slice D2** — the placement: bank-0 repack, the group-C GFX
> ## redirect in `jtcps1_prom_we`, the QSound bank split on
> ## `qsnd_addr[23]` (already produced and gated, just unrouted),
> ## `jtframe_ram1_7slots.v` (maintainer-ruled option A) and the two new
> ## GFX slots.
> ## **(4) A NEW CORE WITHOUT `hdl/pal_lut.hex` RENDERS A BLACK SCREEN**,
> ## `*.hex` is gitignored in jtcores so `git add` refuses it silently, and
> ## — through the Verilator harness's per-changed-frame `fork()` — that
> ## VIDEO defect MOVED the simulated match-start anchor by 107 frames and
> ## turned `test_mister_sim_anchor` RED. Four 50-minute runs to find. A
> ## 2x2 factorial put the whole effect on the `.hex` and none on the RTL.
> ## **So: never blame a red anchor on RTL until a core-vs-core RAM
> ## comparison says so** — that is what `test_mister_wide_inert` is for.
> ## **Gates:** `test_mister_wide_gate` (ci_portable, 22 s) is the RTL
> ## trust surface — a frozen line-by-line override delta, the missing-asset
> ## check that would have caught pal_lut, and two Verilator benches with
> ## four must-fire controls; `test_mister_wide_inert` (emulator, ~22 min) is
> ## the INERTNESS instrument (cps2 vs cps2w, bit-identical work RAM);
> ## `test_mister_sim_anchor` runs on **cps2w** by default
> ## (`SIM_CORE=cps2` for the reference leg) and is a cross-IMPLEMENTATION
> ## oracle, not an inertness test.

> ## **SLICE LOG (history) — 14z-107 (5): MiSTer SLICE D0 IS DONE.** The MRA that
> ## makes the WIDE image downloadable at all is written, pushed to the fork
> ## (`38acc638`) and gated. `rom/vsavjw.rom` = **66,265,152 B**, header
> ## words **6144 / 6400 / 15552 / 64704** — `docs/project/mister_map.md`
> ## §3 to the byte, verified region by region against the romset. The
> ## stock leg is untouched and now GATED: the `vsavj` MRA from `cps2w` is
> ## byte-identical to `cps2`'s except `<rbf>`, `cps2` emits NO WIDE MRA,
> ## and stock `vsavj.rom` is still 46,407,744 B.
> ## **Build it:** `ROMDIR=... tools/mister_mra.sh --core cps2w --wide
> ## build/m3b_merged13 --out <dir OUTSIDE the repo>`.
> ## **THREE THINGS D0 FOUND, all of which change how to work here:**
> ## **(1) The map's own proposed TOML row was WRONG and wrong SILENTLY** —
> ## `parts=` collapses a whole region into ONE `<interleave>`, so three
> ## QSound members all mapping "12" become the first one truncated. The
> ## fix is a SEPARATE `qsoundw` region (with a generic `skip=true` row, or
> ## the stock MRAs gain a comment line and the twin breaks). Corrected in
> ## place in §3, wrong row kept and labelled.
> ## **(2) jtframe finds zip members by CRC32 ALONE** (`mra2rom.go:163-172`)
> ## — FBNeo and MAME resolve by NAME and only warn, which is why our WIDE
> ## members carry SENTINEL CRCs there. **So the MiSTer MRA is pinned to one
> ## romset BUILD**: `tools/gen_vsavjw_xml.py` generates the fork's
> ## catalogue entry from the zip, and a romset rebuild that moves a CRC
> ## needs a new fork commit. `tests/test_mister_mra_map.sh` says so loudly.
> ## **(3) The WIDE set's PARENT is the BUILD's `vsav.zip`,** not the
> ## pristine dump (the merged build patches `vm3.13m/15m/17m/19m`), and
> ## `jtframe mra` reads a hard-coded `$HOME/.mame/roms/` — hence the
> ## private-`$HOME` staging in `tools/mister_mra.sh`.
> ## ~~**NEXT: slice D1** (the QSound width fix, `jtcps15_sound.v:47,416` +
> ## `PCM_AW` 24)~~ — **DONE, see the 14z-107 (6) block above; and `PCM_AW`
> ## 24 was wrong.**
> ## Two SHIPPING questions D0 surfaced, for the maintainer, in STATE
> ## "Decisions pending": which MRA is the core's MAIN one, and how a
> ## release carries both `vsav.zip` flavours.


> ## **14z-107 (4): THE MiSTer SDRAM PLACEMENT MAP EXISTS
> ## AND IT FITS, by 0.125 MB of 64 (0.708 MB RETRACTED 14z-107 (9) —
> ## see below).** Read `docs/project/mister_map.md`
> ## before any MiSTer RTL. Three things in it change what earlier
> ## entries below say:
> ## **(1) "6.39 MB of tenant art into bank 1's 7.1 MB spare" IS WRONG.**
> ## 6.39 MB is a LIVE-BYTE count; a CPS-2 tile code IS its SDRAM address
> ## (the download scramble at `jtcps1_prom_we.v:105` undoes the .rom's
> ## 4-way interleave), and the roster runs to code `0xEE73` in group-C
> ## obj bank 4 and `0xFFDB` in bank 5 -> **an ADDRESS FOOTPRINT of
> ## 15.45 MB**, needing the spare of BOTH banks 0 and 1.
> ## **(2) THE WIDE `.rom` DOES NOT DOWNLOAD AS DECLARED** — 70.26 MB
> ## overflows the 26-bit `ioctl_addr` GAME port
> ## (`jtframe_mem_ports.inc:1`) AND the 16-bit header start word. The
> ## MRA must trim QSound to 8.9375 MB; `mra2rom.go:177-196` +
> ## `parts=[...]` do that from the MRA alone, so the ONE-ROMSET ruling
> ## holds. **DONE in D0 — but NOT with the row §3 proposed; see the
> ## 14z-107 (5) block above.** QSound is then SPLIT across SDRAM banks 0 and 1 on
> ## `pcm_addr[23]` — without that split the map overflows bank 1 by
> ## 0.39 MB and nothing else closes it.
> ## **(3) THE PRG WINDOW IS RESOLVED:** `objcfg_cs` is WRITE-ONLY
> ## (`jtcps2_main.v:190 && !RnW`), so a 6 MB `rom_cs` gated on `RnW`
> ## has NO read collision; the 16-byte `$400000-$40000F` reservation is
> ## enough. Bonus defect found: `:167` would leave `$500000-$5FFFFF`
> ## ZERO-wait while all other ROM is one-wait.
> ## **Slice plan D0-D4 with a gate + must-fire control each is in §10.**
> ## New gate `tests/audit_mister_map_fit.sh` (ci_static, ~5 s) freezes
> ## the four extents the fit rests on; **one new tenant tile above
> ## `0xEE73`/`0xFFDB` breaks the map**, and this is what catches it.
> ## **Open for the maintainer: the bank-0 slot count** (add
> ## `jtframe_ram1_7slots` vs move the Z80 to bank 1) — Decisions
> ## pending.

> ## **THE STATE IN ONE BREATH: the 14z-105 window is FROZEN as
> ## donovan-m11 / huitzil-m20 / pyron-m14 / merged-m6 (stock twin
> ## m5_stock6 = `883e7d17`, UNCHANGED). PLAY:
> ## `tools/run_wide.sh build/m3b_merged13 fbneo`. FIELD-CONFIRMED and
> ## PUSHED 2026-08-22 (Oboro + the M6 mark both confirmed; Oboro's long
> ## intro is vanilla's own boss intro — accepted, not tournament-legal).**
>
> ## **WHAT THE WINDOW SHIPPED (both profile-gated, both inside the
> ## ratified select-window class):**
> ## **W1 — THE OBORO SELECT HOOK:** cursor on BISHAMON, hold START,
> ## confirm with any button -> vanilla vsavj's Oboro (id 0x18, base
> ## 0x0B3450; the pale colorway; HUD name stays "Bishamon" — aliased
> ## rows). P1 and P2. Without Start: plain Bishamon. The mechanism is
> ## vanilla's own Gallon-variant idiom at PRG:0x020B9C one cell over
> ## (`btst #7,$394(a6)` IS the Start test — measured before authoring).
> ## Gate `tests/test_oboro_select.sh` (5 legs incl. P2 and the stock
> ## twin). Atlas: select_screen.md "The Oboro select hook".
> ## **W2 — THE VERSION STRING:** "M6" at the select screen's bottom-
> ## right — THE NAKED-EYE A/B TELL (CLAUDE.md §5, open since 14z-92,
> ## now implemented). Two authored glyph sprites on the roster21 wheel
> ## record, tiles in group C 0x1FE40/41, pal row 0x19. Knobs on
> ## `[[select_wheel]] roster21` in all three manifests — **BUMP
> ## `version_text` AT EVERY FREEZE** (it names the generation). Gate
> ## `tests/test_version_string.sh` (pixel-exact snapshot). Font:
> ## `build/manifest/version_font.json` (0-9 A-Z - . space; add glyphs
> ## there if the text needs more).
>
> ## **THE FINDING ON THE WAY — the tile codec was mirrored.**
> ## `gfx_tiles.decode` had mapped plane bit i to pixel i since it was
> ## written; the hardware draws bit i at pixel 7-i of each 8-px half,
> ## and the transparent pen is 15. Nothing had ever consumed pixel
> ## ORDER until the first authored tile. Fixed both ways, gate
> ## `tests/test_gfx_tile_codec.sh`, platform gotcha. RULE: a
> ## synthesized tile is verified at the RENDER layer, never by a byte
> ## round-trip alone.
>
> ## **A PREDICTION THAT DIED:** the 14z-104 close said the select-window
> ## specs would MOVE with two more sprites. Measured over all 148
> ## window/composite specs: UNCHANGED. The window end is the VS-phase
> ## re-init, not the sprite count.
>
> ## **THE NEXT SESSION starts clean — the field test passed and the
> ## push is done.** Nothing is queued — every verification
> ## the 14z-102 freeze had is green on 14z-105 (incl. audit_merged_
> ## legacy 47/47 + leg b, and the guard-corpus soak 316/316, run while
> ## the maintainer tested; the Oboro pick also agrees on FBNeo, leg F).
> ## **RELEASE PACKAGING IS DONE (14z-105 (2)):** `release/merged-m6/`
> ## — xdelta3 patches against the four reference dumps, manifest,
> ## applier, README; gate `test_release_roundtrip.sh` (round trip
> ## byte-identical, applier refusals, rule-7 scan). Re-package at every
> ## freeze with `tools/package_release.py build/<merged>/rompath release
> ## --romdir $ROMDIR --name merged-mN --version <mark>`. RULED
> ## (maintainer, 2026-08-22): stays IN-TREE until MiSTer; a tagged GitHub
> ## release is cut then, covering both. MiSTer core surgery is next.
> ## **14z-106 (2026-08-22): housekeeping DONE** (w6 evidence logs +
> ## guard-corpus TSV committed; probes attic'd to `../build_attic_14z105`;
> ## `../build_attic_14z102` DELETED per policy; fbneo submodule content
> ## verified = patches 0001+0002). **MiSTer FRAMING RECORDED (maintainer):
> ## the deliverable is an EXTENSION OF JOTEGO'S jtcps CORE, not an FPGA
> ## re-implementation of the MAME emulation.** Before any RTL: the
> ## alignment questions in STATE "Decisions pending — MiSTer alignment"
> ## — ALL FIVE RULED 2026-08-22: separate core (GPL-3.0 fork of jtcores,
> ## own RBF), measure-then-choose profile, sim = gate / hardware = field
> ## test, MiSTer + Jammix available (SDRAM SIZE TO CONFIRM), MRA+RBF with
> ## a stock-vsavj reference-leg MRA. LICENSE: GPL-3.0 (done).
> ## **14z-106 (3): MiSTer SLICE A DONE** — fork `DefinitelyFrenchName/
> ## jtcores@vampire-saved` (core `cores/cps2w` → `jtcps2w.rbf`), submodule
> ## `emu/jtcores` + `tools/setup_jtcores.sh` + gate `test_jtcores_twin`;
> ## the vsavj reference-leg MRA measured byte-identical to stock except
> ## `<rbf>`. ("NO XL SDRAM tier exists" — TRUE OF OUR PIN ONLY; see
> ## the 14z-107 (2) block below.)
> ## **SLICE B MEASURED (`docs/project/mister_fit.md`): the roster's art
> ## is 6.39 MB vs 0.49 MB blank in vanilla's 32 MB — a wider GFX tier is
> ## REQUIRED; PRG needs 4.82 MB (+ a 30-B pin at 0x5FFF00); QSound ext =
> ## banks 0x80-0x8E (all aliasing → width fix required). ~~PENDING RULING:
> ## WIDE v1 VERBATIM on a 128 MB tier (recommended) vs a tighter MiSTer
> ## profile.~~ **RULED 2026-08-23: WIDE v1 VERBATIM. The "128 MB tier"
> ## half is superseded — see 14z-107 (2) below.** **SLICE C: THE SIM LANE WORKS** (stock jtcps2 + vsavj under
> ## Verilator on this Mac, ~1 s/frame, recipe in mister.md; `.rpl` →
> ## `sim_inputs.hex` translator gated).**
> ## **14z-107 (2026-08-23): THE MiSTer ORACLE IS REAL — the §4
> ## dual-emulator protocol now runs on a THIRD implementation and
> ## AGREES.** Fork commit 2 `553dd56` = `JTFRAME_SIM_WRAMDUMP`, 64
> ## macro-gated lines in the Verilator TESTBENCH `test.cpp` (no RTL);
> ## `emu/jtcores` pin bumped and the patch mirror is now a SERIES.
> ## `tools/run_sim_jtcps2.sh` is the whole lane in one command; gates
> ## `test_sim_wram_contract` (ci_portable) + `test_mister_sim_anchor`
> ## (emulator tier, ~55 min). MEASURED: work RAM = SDRAM bank 0 byte
> ## `0x600000`, 64 KB, 68k byte order; `05_timeout_idle` round-1
> ## match-start anchor MAME **2146** / sim **2502**, skew **+356** [RETRACTED 14z-107 (7): 2609 / +463]
> ## (NOT the +460 boot offset — the attract/select/VS path costs ~99
> ## fewer frames on the core, which is why §4 anchors exist). Every
> ## compared field agrees, P1 = Demitri `$093B6A` on both.
> ## **THE ONE DISAGREEMENT IS THE GAME'S OWN LOTTERY:** the 1P arcade
> ## draw is sound-state-fed (`ram.md:99`, the #110 mechanism), so the
> ## CPU opponent differs (`$0AE9D4` MAME vs `$0A9518` core) and the
> ## P2-identity fields are excluded BY NAME. Pinning it needs a 2P
> ## replay -> P2 SCRIPTING in `SimInputs` -> a queued fork commit
> ## [still queued at 14z-107 (8): commit 10 RELEASED P2's buttons, it did
> ## not make P2 scriptable; the draw is the same pair after the fix].
> ## **TWO RETRACTIONS:** `JTFRAME_SIM_IODUMP` dumps the EEPROM on CPS-2
> ## and `JTFRAME_SAVESDRAM` is Verilog-model-only — work RAM was never
> ## "reachable"; and **`-load` is MANDATORY** (the download latches the
> ## decryption key into core registers, so a preloaded run boots into
> ## ciphertext — 1,841 frames of ALL-ZERO RAM that still "agreed" with
> ## MAME on 99.2% of sampled bytes. Check NON-CONSTANCY first.)
> ## **14z-107 (2) — THE MEMORY-MAP TRUTH (docs + STATE only; no code, no
> ## RTL). The profile ruling STANDS (WIDE v1 verbatim, one romset); the
> ## implementation assumption attached to it is RETRACTED: "MiSTer work =
> ## width plumbing only" is FALSE and the 128 MB tier is NOT a flag away.**
> ## At our pin `v1.7.3` **64 MB is PHYSICAL** — jtframe's table stops at
> ## `AW 23`, the bank geometry has no AW=24 arm (`addr[9]` would never be
> ## driven, aliasing with `addr ^ 0x200`), and only 13 A / 2 BA / 1 nCS
> ## pins are assigned. **`JTFRAME_SDRAM_XL` (128 MB) IS real — UPSTREAM,
> ## 3057 commits away, untagged** — as TWO CHIPS on one module with chip
> ## select on **nCS POLARITY**, and reachable ONLY inside the
> ## `JTFRAME_SDRAM_CACHE` branch: setting it on `cps2w` today would
> ## compile, validate and silently alias (platform gotcha). That
> ## **partially UN-RETRACTS** 14z-106's "no XL tier" — true of the pin,
> ## false of jtframe; `cps2_wide.md` now carries the version qualifier.
> ## **The CPS-2 CORE caps GFX at 32 MB in the OBJECT FORMAT** (16-bit code
> ## + 2-bit bank — the SAME 19-bit promote WIDE v1 already makes on FBNeo),
> ## the 68k at a flat 4 MB `rom_cs` (with a real collision against the
> ## objcfg window at `0x400000`), scroll at 8 MB, QSound at a 7-bit latch.
> ## No SDRAM tier lifts any of them.
> ## **AND THE ROSTER FITS 64 MB BY TOTAL — ~56.1 MB** (`mister_fit.md` §6):
> ## PRG 6 MB fits bank 0 TODAY, QSound 16 MB fits bank 1 TODAY (PCM is
> ## alone in a 16 MB bank), and ONLY GFX overflows, by ~6.4 MB — into
> ## bank 1's ~7.1 MB of spare. ~~**NEW PENDING DECISION: THE MiSTer
> ## MEMORY-MAP ROUTE** — (1) uprev to untagged master + XL + `mem.yaml`
> ## cache lanes, or (2) stay at the pin and BANK-REPACK inside 64 MB.
> ## **Recommendation (2)**~~ **DECIDED (maintainer, 2026-08-23): (2), the
> ## BANK REPACK, measuring first; XL is the FALLBACK. Measured GO the same
> ## day and SHIPPED in D2.** And the "~6.4 MB into bank 1's ~7.1 MB spare"
> ## framing is RETRACTED twice over: 6.39 MB is LIVE BYTES, the address
> ## footprint is 15.45 MB, and the DECLARED REGION the download reserves is
> ## 16 MB — see the top banner.
> ## **THE SIM LANE'S SDRAM MODEL IS FIXED (14z-107 (3), fork commit 3).**
> ## It dropped `addr[22]` — which rides on `sdram_a[9]` as the tenth COLUMN
> ## bit, NOT `addr[9]` — so GFX banks 2/3 were half-aliased. The "~3
> ## constants / widen the column to 0x3ff" fix named earlier was WRONG.
> ## The anchor oracle never moved (bank 0 is entirely below WORD 0x400000)
> ## and still passes; the anchor moved 2507 -> 2502 (skew 361 -> 356) [both absolutes RETRACTED 14z-107 (7): the clean anchor is 2609]
> ## because `jtcps1_obj_draw.v:137` skips blank tiles, so OBJECT TIMING
> ## DEPENDS ON GFX CONTENT. Two more harness bugs had to be
> ## fixed before `-stats` produced anything (commits 4 and 5).
> ## NEXT OPENER: ~~**the MEMORY-MAP ROUTE ruling**~~ [TAKEN 2026-08-23 —
> ## bank repack], then the core-side format
> ## work; phase B (the round-transition anchor on the full 12,120-frame
> ## replay, ~3.5 h), the Verilator 8 MB-per-bank fix and P2/6-button
> ## `SimInputs` are the queued follow-ups. [8 MB-per-bank done 14z-107 (3);
> ## `SimInputs` FIDELITY done 14z-107 (8), COVERAGE still queued.]
> ## The N-2 build-dir
> ## deletion policy applies at the NEXT freeze (m10/m19/m13/merged-m5
> ## dirs are now one-back; m9/m18/m12/merged-m4 + m5_stock4 are N-2 and
> ## fall).

## What 14z-105 did (the whole arc, one screen)

**Measure first:** Start held on the vanilla select screen -> struct
`+0x394` = `$8000`, `$FF8060` = 1 (both live at select; the template
bit is Start). **W1** authored as a 30-byte profile-gated site_thunk
(every manifest, deduped; +2 ops), rehearsed on a merged probe, gated
five ways. Stock twin rebuilt = `883e7d17` bit-identical (the profile
gate measured, not argued). **W2** authored as `version_*` knobs + a
5x7 font + `gfx_tiles.encode` + an `"authored"` list in
`wheel_bank5.json`; the first probe rendered mirrored glyphs in a black
box -> the OBJ list proved the sprites right and the TILE BYTES wrong ->
codec fixed both ways -> re-probe pixel-exact (0 mismatches). **The
freeze:** tenant_loop op counts re-frozen (325/365/298; 600/652;
806/907), five artifacts built from the tree (merged13 bit-for-bit the
probe), sets carried-renamed + registry rows, m3a pins + whole-artifact
manifests moved with member attribution (program + the four GROUP C
members = the glyph tiles; no QSound), the standing re-point sweep
executed (~70 defaults), placements +0x10 (hui) / +0x30 (pyron) ->
bases.tsv, pcrel [merged_*], pointer_flow baselines re-derived;
region_overlap section 5 still 2033. Every gate run at the freeze:
STATE 14z-105 CLOSE.

## What 14z-103/104 did — see STATE; the coverage matrix is fully green
(docs/project/coverage_matrix.md), #110 fixed, the A4 pin-cleanup done.

# HISTORY BELOW — carried for reference, not current

Everything from here down was written at the close of 14z-104 and
earlier. Kept because the eliminations and traps stay valid; read the
section above for the current state.

## What 14z-103 did (the whole arc, one screen)

**The A4 pin-cleanup pass executed end to end** — every stale build-dir
reference re-pointed and run green, ruled a deliberate pin (don_m5 =
walker_repoint's un-relocated negative control; pyron26 + hui41 =
decode_stage_banners' frozen #92 carriers), or reclassed operational;
disposition table in `docs/project/build_dir_triage.md`. Findings: the
gate_failures litter class (the flicker-gate fixture wrote deliberate-
FAIL stubs into the evidence dir on every static run — fixed at the
root with M2A_KEEP_DIR, 141 files purged by content signature);
**GitHub #110** — audit_fg_damage + audit_pool_free_byte red since
14z-87 because that batch RE-ROLLED THE ARCADE DRAW (m6: char 0x0C /
stage 0x12; m7+: char 0x00 / 0x0E) — fixed by pinning the opponent
(2P-dummy rigs hui/74+75, EXPECT 69/69 bit-identical across
generations; pcosmo -> 106_pyron_cosmo_clash) and CLOSED; the 14z-88
self-frozen-sha1 hole live again on replays 94/103/105/106 — promoted
to `window vsavj/masked-v2 889 2091` (103 per-leg: tenant on don,
.legacy-exempt on hui/pyron); grab_victim's default was the pre-14z-73
expectation since birth (now `matches`, Δ=0); flicker_attribution had
been SKIPping on a removed set dir (now fingerprint-resolved). The
Circuit Scrapper report was measured NOT REPRODUCED (six-run A/B, MP/
HP/mash) and the maintainer confirmed it fine. Everything pushed
(bb79e18); suites GREEN x3, statics 97/0/0 strict.

## What 14z-102 did (the whole arc, one screen)

**The #107+#109 window frozen end to end** as donovan-m10 / huitzil-m19
/ pyron-m13 / merged-m5 (maintainer "go"; beams field-confirmed on the
rehearsal probe first; gold tint KEPT). #107 = the verified
reconciliation row 0x0448a6 -> 0x04367a (shared map — stock moved too).
#109 = the clone-beam fix: vsavj ships effect-class ROW 31 as a stub
(the DF clone-mode beam emitter); ported root 0x926e4:0x11e:t0x922f0 +
code_ptr at PRG:0x080B28; the root changed extraction (hui placements
shifted, op counts re-frozen 363/804, tenant bases re-derived). Every
verification green: run_suite x6, battery effectively 24/24,
guard-corpus soak 316/316 zero vectors, statics 97/0/0 strict.
PUSHED with #107/#109/#50 closed. Post-freeze rulings: DF durations
kept categorically (vsavj per-character, 1 stock); tint confirmed good;
#50 closed as standing policy; build-dir triage EXECUTED (85 dirs /
8.1 GB -> ../build_attic_14z102, reversible; N-2 generation-roll now
standing policy at every freeze).

## What 14z-101 did (the whole arc, one screen)

**The agreed #108→#107→#106 sequence, all executed windowless:** #108
INVERTED by the writer hunt (not-a-defect; the -debug "paradox" was a
pristine-table misread; audit re-framed to NATIVE PARITY + anchor leg);
#107 twin-anchored statically (both games' own farms bind slot-for-slot;
0x45FCC eliminated — next slot's routine; tie-refusal policy landed in
reconcile_batch + gate §6, live control: fresh 0x448a6 refuses as
TIE-4x0.94-w0x20; m3a bit-exact); #106 closed (verify_pcrel_data
--extract/--placement-suffix; merged inventories IDENTICAL to solos,
frozen by reference with a must-fire control; also fixed the tool's
listdir-accident zip pick).

**New standing instruments:** `audit_guard_corpus.sh` (79 replays × 4
legs under guard, 316/316 green, hui41-crash must-fire control);
`tools/enum_biased_lists.py`; rigs `df/97-102` (DF framework mechanics,
clone-attack discriminators, the NATIVE clone-mode reference).

**DF mechanics measured** (the field pass's named unknown): the GAMES'
DF frameworks differ by design — vs2 = 2-stock universal buff, uniform
332f (maintainer-confirmed); vsavj = 1-stock per-character modes
(legacy sweep spans 269-540f); ours == pristine vsavj EXACTLY on the
legacy control. Phobos' 0x18 clone-train mode is a legitimate vsavj DF
class (legacy 0x0C/0x0F use it at the same 377).

**#109 found and fully root-caused through the confirmation loop** (two
intermediate readings retracted in place — the layered-correction arc is
itself instructive: identify moves by measured EFFECTS, never the
script's input name — vs2's buffer folds 6236 to 236; gotcha paid).
The clone-mode EX = 263+2P (1 stock); the ES = 236+2P.

**The FOREIGN-DRAW class named** (register §5): audit_empty_tiles
measured PASSING on the #109 event — it audits group-C blanks, this
class draws from the WRONG SPACE; exposure census-bounded 26/1/0, the
paired-draw census queued as the instrument. [The #109 instance of the
class dissolved with the 14z-102 re-derivation (the beam draws
correctly); the CLASS and the census stay valid for the B-sweep
carries.]

**Also:** the ~200-build-dirs decision package delivered
(`docs/project/build_dir_triage.md`); the stale "#10 ripe" banner claim
retired; strengths/timeout-wins field items closed.

# HISTORY BELOW — carried for reference, not current

Everything from here down was written at the close of 14z-98 and
earlier. Kept because the eliminations and traps stay valid; read the
section above for the current state.

## What 14z-98 did

**#103 root-caused and causally confirmed; no shipped byte moved.** The
banner's consumer trace ran and ELIMINATED its own suspect (both spaces,
live controls), which moved the hunt one level up: the KO-recognition
step (phase 6->8) never fires for a Donovan death because the judge
tests WHITE HP's sign and his white never goes negative — a ported
pc-rel escape pins his hp to 1 mid-match. Chain, instruments, fix design
and rehearsals: STATE 14z-98; the issue carries the full write-up.

**New instruments:** `tests/audit_don_ko_writer.sh` (the root-cause
lock, both modes rehearsed); `trace_writes.lua` DUMPS (self-documenting
-debug runs). **New gotchas (project bucket):** every -debug watch
configuration is its own TIMELINE; GUARD_PROBE's RET (SP) lies for
jmp-reached code. **Atlas:** +0x52 judge note, +0x54, +0x11F rows;
engine_internals "THE ROUND JUDGE" section. **Retractions executed:**
the "author the four per-char rows" fix shape (issue, STATE (9) marker,
bank_map.toml trace note).

---

# HISTORY BELOW — carried for reference, not current

Everything from here down was written at the close of 14z-97 and
earlier. Kept because the eliminations and traps stay valid; read the
section above for the current state.

## What 14z-97 did

**Closed: #96** (maintainer-ruled option (a), executed). One arc, no build
bytes touched.

**The battery's legacy target now FOLLOWS THE BUILD.** It resolves the
expectation set from the build's own program fingerprint through
`tests/expected/registry.tsv` — the same auto-detecting mechanism
`run_suite.sh` has always used — so nothing in the gate names a generation,
and at the next freeze the registry row moves and the gate follows with no
edit. An unregistered fingerprint is now the rule-6 signal by construction,
and it stops the gate BEFORE any replay runs.

**First measurement, and it settles the ticket: the pipeline DOES reproduce
the freeze.** Rebuilt clean, stage 6 -> `a054de5c` (the stock twin named in
the donovan-m8 freeze record), stage 4 -> `22c804c8`. Every #96 symptom was
the dated `donovan-m2c` pin, exactly as the ruling said.

**The one open item, `08_challenger_join`'s 3807, is ATTRIBUTED:** full-RAM
dump diff at 3507 AND 3807 shows one differing live byte, **`$FF06E1`** —
the byte `docs/game/atlas/ram.md:62` names verbatim (OBJ-builder secondary
stack, "execution POSITION, not state"). Corroborated twice: `donovan-m2b`
measured the same pair one generation EARLIER than the pin, and on the WIDE
track that frame is a select-window onset (the challenger join re-enters
select). Not growth of an unknown kind.

**Constants that disappeared AS constants:** the V1 mask string (#70's other
half), the V1 basis path, `M2A_FLICKER_SPECS=donovan-m2c`, the two
generation-dependent class lists, and 700 / 4278 / 1080 (from the MASKED
gate — 4278 rightly stays in the unmasked stages-1-3 one, where it is a fact
about vanilla's attract demo). Those three are `.masked` `diverge` specs now,
which is STRICTER — `check_diverge.py` also asserts line-identity before the
frame.

**A PREDICATE WAS INVERTED, deliberately.** 14z-90 (#2) made the flicker
check fail on growth and merely ADVISE on shrink, because the battery ran on
UNFROZEN dev builds. That premise is gone: the target is a frozen
generation, so a shrink means the fresh build is not the frozen one, and
drift either way now fails. If you find yourself "fixing" that back, read
`tests/test_m2a_flicker_gate.sh`'s header first.

**The §4 vocabulary has ONE implementation:** `tests/lib/masked_compare.sh`
(exact/flicker/diverge/window/composite + the #62 baseset-mask guard),
shared by `run_suite.sh` and the battery. Proven three ways — textual
identity of every checker call and verdict string with the pre-lift block, a
synthetic ground truth over all five classes in both directions, and a
real-data re-check of `window`+`composite` on the shipping WIDE build.

**Two real defects found on the way, both of the "measured the wrong thing
quietly" class:** `tools/propose_masked_specs.sh` measured PRISTINE VANILLA
when given an absolute builddir (it existence-checked one path and handed
MAME another), and the lifted `diverge` branch would have reported
NO-BASE-LOG on every diverge spec (`check_diverge.py` derives the base log
from the spec FILE's stem). Both fixed, both gated. Also: a verdict control
in `test_baseset_mask_invariant.sh` was briefly passing because it CRASHED.

**Where the tenants stand:** unchanged. No build moved; the 14z-96 freeze
stands.

## What 14z-95 did

**Closed: #24, #27, #43(a), #52, #97, #98, #100.** Advanced: #96 (symptom
fixed, three items separated, root-caused to one constant), #99 (parked with a
cold-resume record), #100 (mechanism localised, then closed WON'T FIX under
the standing cosmetic ruling and re-scoped beyond MiSTer).

**Five new gates**, all with must-fire controls:

| gate | what it locks |
|---|---|
| `test_tenant_pairings.sh` | tenant-vs-tenant, all SIX orderings — the CLAUDE.md §4 coverage the suite never had, and the gap #99 walked through |
| `test_hui_electrocute.sh` | the FIRST electrocute rig in the project's history (STATE said twice no replay produced one) |
| `test_merged_inputs.sh` | the merged build's inputs are PRODUCED, not demanded — rule 3 is one command |
| `test_reconcile_matcher.sh` | one matcher, pinned inert (1640/1640 probes), parameters proven load-bearing |
| `audit_ladder_selector.sh` | the #99 ladder probe, and a regression lock on a hypothesis that DIED |

**THE SESSION'S REAL LESSON, worth more than any single fix: FOUR separate
defects were checks that had STOPPED CHECKING**, and each read as green or
quiet rather than red —

| what | how it hid |
|---|---|
| `test_dualtrack` | red for 11 days; no runner executed it |
| `audit_pyron_ring` | compared two builds that stop being comparable at f4741 |
| `test_m2a_stage4_code` | asserted a constant a ratified change had invalidated |
| `test_reconcile_matcher` | **mine** — disarmed itself the moment I committed the change it polices |

The last was caught ONLY because `run_all_static` counts SKIP as a third
outcome (#29/#30). That is an argument for spending time on gate
VERIFICATION, not only on gate COVERAGE.

**Generalise from the fourth:** any gate that reconstructs a "before" state
from git is dated by its own commit. `git log -S` answers "where did this
change", NOT "the last version that HAD this".

## Where the tenants stand

Unchanged this session — no build byte moved. `build/m3b_merged9` =
**merged-m2** (`081e2e53`, 752 ops), solos `hui43` = huitzil-m16
(`da734d49`) and `pyron27` = pyron-m10 (`e29cac23`), `build/don_m7` =
donovan-m7 (`c90b60c3`, unchanged since 14z-91). Maintainer playtest of
merged-m2: **no regression**, one crash (#99), one cosmetic (#100, now
won't-fix).

---

(Deeper history, 14z-92/93/94, follows — same caveat as above.)

## What changed in the triage, in one screen

Almost none of these were wrong logic. They were **checks that stopped
existing** under an ordinary condition — an env var, a wrong argument, a
phantom CLI option, a stale marker file, a literal constant — and in each case
the thing that should have caught it was disabled by the same stroke.

| # | the switch | what it turned off |
|---|---|---|
| 79 | `python -O` | `assert` is REMOVED, not weakened. Six tools, incl. the cipher round-trip self-check. |
| 76 | a wrong 2nd argument | `outdir == romdir` deletes the reference set. No undo (rule 7). |
| 80 | `MAME_BUILD_ROOT` | `rsync --delete` into any caller-supplied path. |
| 86 | a late replay failure | the oracle trust root left half old, half new. |
| 89 | `--dry-run`, which never existed | voice ids rebuilt from `wide0`, reported as a verdict on another build. |
| 88 | a leftover `.diverge` | the freeze you just took, silently ungoverned. |
| 85 | the literal `60` | 2.03 s drift by voice 79, against a 3.35 s window. |
| 83 | an absent TSV row | meter, which CLAUDE.md §4 names explicitly. |
| 81 | SIGKILL / a second terminal | tracked `gen_donovan_patch.py`, left perturbed. |
| 87 | nothing reading the field | `gfx_layout3.toml`'s bank words, collision rule and scatter bounds. |
| 77 | one mistyped `.rpl` frame | `nScriptFrames + 2` wraps -> `calloc(1,4)` with a ~4 GB write past it. |

**Three were hiding a second defect** — #87's scatter bound had already
drifted (huitzil: 246 codes outside it, re-measured to `0x0AF5`), #85's
control was aimed at the one window where the drift is smallest, #81's
self-check compared against a snapshot it took itself. **Two were latent**
(#89, #51): real defects that currently produce right answers, which is
exactly why they needed gates and not rebuilds.

**THE SUITE IS GREEN.** `test_dualtrack` — the one red thing — is fixed and
is now a STRONGER gate (**#95**, closed). It was never a regression: it
asserted two things the project had *deliberately* made false, and **no
runner ran it**, so nobody saw it go red 11 days ago.

| its claim | what invalidated it |
|---|---|
| 11 legacy replays bit-identical stock↔WIDE | **14z-64 M3a de-substitution** — the two builds carry DIFFERENT ROSTERS by construction (`m5_stock` id 0x0F over Jedah; `m5_wide` id 0x13, Jedah restored), so every select-reaching replay must differ |
| attract diff = 57 bytes, 0 gameplay, at frame 4400 | **14z-86 M5 voice block** — the WIDE sound delta grew and now propagates |

Re-derived: section 1 asserts **bit-identical up to select entry** with the
onset frozen per replay (890 ×9, 3190 for the mid-attract one, none for
`06_test_mode`) — the same constants §4 v3 ratifies, which corroborates that
it is select entry. Section 3 attributes the **onset**, not a late frame:
3 bytes at 4267, all in the P1 effect-channel record pointer. New section 4
is the load-bearing one — **the same writer PC on both legs**, so it is DATA,
not control flow; a different writer set is what would mean the profile
leaked into engine flow.

**DECIDED 2026-08-17 (maintainer):** the re-scoped section 1 is ratified —
*"agreed this is why wide exists and now that it exists we must take it into
account."* Nothing about it is open. `CLAUDE.md`'s FBNeo clause was updated
the same day, since it names this gate as one of FBNeo's three guarantees
and said "dual-track inertness" with no scope.

**AND THE REAL LESSON, worth more than the fix:** `grep -rn test_dualtrack`
finds no runner — only docs and **CLAUDE.md:112, which names it as one of
FBNeo's three guarantees.** A rule was resting on a gate nobody executed.
That is GitHub #30, and it is now the highest-value open issue.

**Three new tickets, deliberately NOT folded in:** **#93**
`audit_qs_voice_batch`'s keyon failure (proven pre-existing — identical under
both input stagings), **#94** `audit_pyron_ring`'s dead `build/pyron22` (the
FOURTH reference-rot instance, so it asks for a standing check rather than a
fourth one-line repair), and **#95**, now CLOSED. #94 remains: audits pinned to
untracked build dirs with nothing to notice.

**#30 IS DONE.** There is now ONE pre-commit command:

    ROMDIR=... tests/run_all_static.sh        # PASS 88 / SKIP 0 / FAIL 0
                                              # (measured 2026-08-18; the count
                                              #  moves — read the runner, not this)

It counts PASS/SKIP/FAIL separately (#29 — a SKIP is not a pass) and names any
emulator-free gate that is in neither registry, so the orphan problem cannot
regrow. On its FIRST full run it found three gates stale for weeks
(`test_census_regions`, `test_voice_row_range`, `test_phasec_spaces` — all
fixed, all detailed in STATE 14z-94 (9)) and a fourth now filed as **#96**.

**(history) Start here next time: #96** — [14z-95: the named symptom is FIXED; two items remain, see the top] — `test_m2a_stage4_code`'s `06_test_mode`
divergence disappeared (expected 700, got none). Either a stale constant or
something live gone inert; name the mechanism before touching the number.
**RULED 2026-08-18 (maintainer), so this list has moved:** **#24 CLOSED**;
**#52 fixed and landed** (14z-95); **#27 ruled — ONE COMMAND**, a documented
procedure only if a single command cannot work; **#43 ruled — SPLIT**, land
the inert refactor now and ship the row movement at the next re-freeze.
Remaining maintainer-owned: **#57**. Architecture backlog:
#47/#48/#49/#50, #69, #71, #46, #93, #94. None blocks the re-freeze.
**#99 is PARKED (see the banner). The Phobos sfx thread is measured but
NOT closed** — the extra voices found are at the PRE-MATCH phase, not at the
end of the electrocute where the report puts them, and a `+0x382` poke
confound is open. Both are on the issue and in STATE 14z-95.

## (HISTORY, 14z-94) Where it stood then

| leg (40,620-frame arcade marathon, forced pick, sparse probe at `0x05ffb6`) | verdict |
|---|---|
| `pyron26` pre-fix (FROZEN) | **CRASH 15079** `vec3 PC 01afb6` — #92 |
| `pyron27` post-fix | **END 40620** |
| `hui41` pre-fix (FROZEN) | **CRASH 18337** `vec4 PC 0fb6e0` — #91 |
| `hui43` post-fix | **END 40620** |
| `m3b_merged8` + Huitzil (FROZEN) | **CRASH 8887** `vec4 PC 456930` — #91 |
| `m3b_merged9`, all three tenants | **END 40620** |

**MERGED GATE SET, all green on `m3b_merged9` (752 ops, `081e2e53`):**
`audit_merged_legacy` AUDIT-EXIT 0 (leg a 47/47 with 0 NOT-EVALUATED, leg b
6/6 guard-clean), `test_merged_render_content` PASS,
`audit_trap_parity` PASS, `audit_fg_parity` PASS,
`audit_select_bank_gates` PASS, `verify_gfx_build` + `check_tenant_hud` PASS
on all three tenants.

The probe fired on every leg, so it is armed rather than dead: 3 hits on the
three legs that ran to 40,620, and 2 on `hui41` — which crashed at 18337,
before the third firing. New builds `hui43` `da734d49` / `pyron27`
`e29cac23`, both UNREGISTERED and UNFROZEN; `hui41`/`pyron26` are untouched.

`tests/test_voice_row_range.sh` is now GREEN on the new builds (it stays RED
on the frozen ones, correctly). The historical shape it caught:

```
hui41/hui42 row 0x10: 0x18 at +0x01, +0x1a, +0x29, +0x31
pyron26     row 0x11: 0x18 at +0x01, +0x1a, +0x29, +0x31
don_m7      row 0x13: clean  (his row never lists his own class 0x13)
```

All eight are ONE shape: the paired table-A byte is class `0x13` (Donovan)
every time, 4/4 on both tenants and 0/12 elsewhere. Across vs2's 32 rows,
`0x18` appears 50 times and **all 50** sit opposite class `0x13`.

Vanilla never emits above **`0x16`** across all 1024 bytes of table B, and
`0x16` is exactly what the downstream table can service (derived
independently; the gate cross-checks the two and fails if they disagree).

**DECIDED 2026-08-17 (maintainer): ABARAYA (`0x0a`)** — "any stage except
Fetus of God, take the one that implies the least impact". Applied.
`tools/decode_stage_banners.py` names the twelve vsav stages, and poking the
word changes the venue on screen (measured: same match, same frame, different
stage). Chosen on three measured grounds — ABARAYA is one of only four values
already reachable in every affected group (so no rung gains a stage it could
not already produce), it is not another character's venue in these ladders
(`0x14` is Pyron's, `0x16` Jedah's), and it is the shortest banner record in
the family at 7 glyph sprites. **DONE:** `huitzil.toml` + `pyron.toml` patched
via the data_port `fixes` key, gate green, crash gone on the marathon with a
live control; the merged op-count constant re-frozen (-1, attributed) and
every merged gate green. **REMAINING:** only the re-freeze itself — registry
rows for huitzil + pyron + merged, which is a STATE decision.

**CORRECTED 14z-94 — the 14z-93 close called this "a voice, so it is
audible" and predicted the round-end flashing would correlate with voice
events.** It is not a voice. `$FF8100` is the ladder's STAGE index: it drives
the stage-name banner on the arcade map screen AND the venue you then fight
in. The flashing prediction rested on the voice reading and does not follow
from the corrected one — treat it as open, not as supported.

## The chain, if you need to re-derive it

```
authored table-B row (0x18) -> stage list $FF1E50
  -> selector loop (0x00aee2) picks index 2 -> $FF8100 = 24
  -> 0x05ffa6: A0 = 0x26775A + 2*24 - 4 = banner-table row 0x1A, STORED to $1c(a6)
  -> consumer derefs the FOLLOWING row = 0x00400000, that table's TERMINATOR
  -> [0x400000] reads 0x7080 -> jmp (4,PC,D0.w) -> vec3
```

vsav's banner family is rows `0x0F..0x1A` (12 stages, values `0x00..0x16`);
vs2's is rows `0x13..0x1F` (13, values `0x00..0x18`). **Both games number
`v=0x00` at their own first row, so the twelve shared stages are identical at
identical values and the port owes NO renumber** — which is why the defect is
four bytes and not a whole table. Every ENGINE site is vanilla and unpatched;
only the authored ROW is ours.

**THE ANCHOR IS THE TRAP.** Each game's site anchors at the address of its
family's FIRST ROW, not the pointer table base (vsavj `0x26775a` = table+0x3C;
vs2 `0x2a0a96` = table+0x4C). Decoding vs2 from its base invents a tidy "+8
renumber between the games" that does not exist — believed for part of 14z-94
until both code sites were read. `tests/test_decode_stage_banners.sh` section
3 reproduces that mistake and requires it to fail loudly.

## Do not repeat these — five of my conclusions died by measurement

| published | killed by |
|---|---|
| "element-table base is 4 bytes low" | a probe at that writer got ZERO hits while the crash reproduced |
| "0x400000 is a stock sentinel WIDE makes live" | stock and WIDE both read `0x7080` |
| "the crash is HUITZIL-ONLY" | **Pyron crashes identically** under a sparse probe — it is a RACE |
| "the selector loop exhausts" | selector 2 < bound 6; it found a real candidate |
| "the value is tenant-specific" | Pyron computes the same pointer; the SLOT differs |

**Method traps that produced those, all now in GOTCHAS:** probes must stay
SPARSE (one firing 17,616 times made the crash vanish); `l@()` memory
conditions silently do not work in `GUARD_PROBE_COND`; never cross-correlate
frames between `-debug` and non-debug runs; do not use `bp_regs.lua` on a
timing question (it is a #10 +1 staging deviant); An-relative reads inside the
crypt window need the DATA view.

**"Huitzil-only" was also my argument for retracting the 14z-85f Sasquatch
link. Since Pyron IS in that recipe, that link is OPEN again.**

## Also settled in 14z-93

- **hitclass thunk: KEEP** (maintainer). Tenant census: **0 map entries over
  37 rigs against 121 pooled type >= 64 objects** — the gap is CONTACT.
- **#78 ratified**, **#90 fixed**, **#44 fixed**, **#41 CI added**, **#82
  fixed**, **#84 closed**, **H-vs-P stuck direction closed**.
- **#10** re-verified: NOT fixed, deliberately, now `deferred-with-reason`
  and gated. Its precondition (the legacy re-freeze) HAS been met, so it is
  ripe. Budget the RE-MEASUREMENT of five gates' frame constants, not the
  one-line edits. **Re-freeze nothing** — replay.lua is untouched.

## What 14z-92 was, in one line

**Five instruments had quietly stopped measuring**, and four of them were
GREEN or unrun rather than red. A decayed gate does not fail — it stops
disagreeing.

| instrument | broken since | presented as |
|---|---|---|
| `obj_records.walk` pointer pass | fired 14z-86 | a build defect (#75) |
| `test_merged_render_content` H legs | 14z-86 | a CONTENT REGRESSION |
| `audit_hitclass_map_cost` reference | 14z-86 / 14z-82c | would have blamed the thunk |
| `test_pyron_ladder` tenant selection | always | **built Donovan**, green (#84) |
| `test_pyron_blink` guard | 14z-87 | could false-REFUSE |

If you read one thing before touching a gate: **`docs/project/gotchas.md`,
"A frozen build stops being a usable REFERENCE when the profile bumps"** —
three references rotted this session (`hui31`, `pyron20`, `pyron17`).

## Two beliefs that changed

1. **Legacy DOES enter the hit-class map — 230 times, not zero.** The old
   census was two replays, both of which score zero. The fix is still sound
   (all indices far below 64, so legacy reads vanilla's own bytes); the
   ARGUMENT was wrong and is corrected everywhere it appeared.
2. **The tree contradicted itself on the QSound terminal byte** (#82):
   `build_qs_songs.py` says INCLUSIVE (packing law #3 — the sword-plant
   beep), `audit_qs_voice_batch.py` still justifies EXCLUSIVE with the
   pre-14z-87b belief.

## Do not repeat these

- #75's blocker **had already dissolved** before the fix — merged8 verifies
  green with the pre-fix tool. The fix removed a dice roll, not a blocker.
- "It may feel better" was **emulator-sided**. The project has NO measured
  performance-positive result. Do not cite the obj_hook cycles for it.

## (HISTORY, 14z-94) The open list as it stood then — SEE THE TOP FOR THE CURRENT ONE

### THE REQUALIFIED AUDIT BACKLOG (maintainer cleared `contested`, 2026-08-16)

Eleven findings from the 2026-08-15 adversarial review are now ACCEPTED.
Ordered by severity, and split by whether they can be started without a
ruling. The 21 still carrying `contested` are NOT in this list.

**~~NEEDS A RULING FIRST — 3 items~~ ALL THREE RULED 2026-08-18 (maintainer).
The rulings are inline below; nothing in this block is open.**

- ~~**#30 + #24 + #29 ARE ONE CLUSTER, not three tickets.**~~ **ALL THREE
  CLOSED** — #30 and #29 in 14z-94, **#24 closed 2026-08-17 (maintainer)**.
  `tests/run_all_static.sh` is the runner the cluster needed, and
  `run_battery_m2.sh` now tallies PASS/SKIP and refuses GREEN at any skip.
  The original analysis, kept because the eliminations stay valid: #29 (~28 gates
  `exit 0` when their build inputs are absent) and #24 (the battery prints
  `BATTERY GREEN` anyway) are the same defect seen from both ends, which is
  why #24 carries `duplicate`; and BOTH fixes need the thing #30 says does
  not exist — a runner. Both handoffs propose the same mechanism: give SKIP
  a distinct exit (77, the automake convention) and have a runner tally
  PASS/SKIP/FAIL and refuse GREEN when anything skipped.
  **The ruling needed is #30's:** what runs the suite? The 14z-93 CI covers
  the 18 ROM-free gates and already fails on SKIP, so the pattern exists —
  the open question is the ~90 gates that need `$ROMDIR`, which CI cannot
  run. Note the blast radius both handoffs flag: flipping `exit 0` -> 77
  changes the contract for every existing caller, including HANDOFF's own
  documented command lines.
- **#27 — RULED 2026-08-18 (maintainer): ONE COMMAND.** *"It should be one
  command; the procedure should be considered only if a single command cannot
  work."* So rule 3's "reproduce from pristine inputs" is NOT satisfied by a
  documented procedure a human follows. `build_merged.sh` regenerates its own
  missing inputs — the three `build/*/extract` dirs and `build/wide0` — and
  keeps using existing ones when present so the common path stays fast. No
  ROM-derived byte gets tracked, so rule 7 is untouched.
  **The constraint to respect while implementing:** this direction unfreezes
  the same pinned dirs #26's track-mismatch guard protects, so regeneration
  must be CREATE-IF-ABSENT and never rebuild-over, and the regenerated extract
  must be proven byte-identical to the pinned one — otherwise the merged
  fingerprint moves and that is rule 6, not a build convenience.
- **#43 — RULED 2026-08-18 (maintainer): SPLIT IT, land the inert half now.**
  The ticket bundles two things with different risk, and only one of them is
  rule-6 territory:
  **(a) the refactor** — move the matcher into `find_equiv.py` with
  `hit_cap`/`allow_fallback`, delete `reconcile_batch.masked_search`, import
  it. With `allow_fallback=False` it must reproduce all 271 rows exactly, so
  ZERO built bytes move. Rule 6 does not reach a change that provably moves
  nothing, which is why a clean freeze is not a precondition for it.
  **(b) flipping the fallback on** — moves 3 rows (`0x028122`, `0x1e744e`,
  `0x0448a6`) and therefore built bytes. Rides the next re-freeze.
  Why (a) goes first rather than after: #91 was a missing reconciliation row
  that crashed the shipping build in extended play, every build ships planted
  tripwires standing in for unresolved rows (merged-m2 ~69), and #99 is a
  crash on a path no rig has executed — so if #99 is a tripwire fire, the
  canonical matcher is what names the row. Waiting is also circular: the
  freeze waits on the crash, and the tool that may diagnose the crash would
  wait on the freeze.
  **Honest condition on (a):** it is inert *if* the 271-row control holds. If
  reproducing them exactly turns out to need drifted behaviour not yet
  enumerated, that is a finding — stop and report, do not nudge rows to make
  the control green.
  **Lands regardless of timing:** `reconcile_batch.py:14` says
  `--allow-plausible` is "for experiment builds only" while
  `tools/build_merged.sh:41` hardcodes it, so plausible rows ship in the
  artifact that gets played.

**MEDIUM — no ruling needed**

- **#28** — `build_merged.sh` reads `$ROMDIR` without the mandatory
  `audit_roms.py` checksum gate. CLAUDE.md §3 is explicit; a builder that
  skips it can produce an artifact from an unaudited dump, unattributable
  under rule 4. Small, self-contained.
- **#38** — `run_replay_fbneo.sh` leaves a stale overlay `roms/` dir on the
  non-overlay branch. Same class as the 14z-90 runner-hygiene fix.
- **#42** — `_minitoml.loads()` silently switches parser by host Python and
  the guard exists in 1 of 11 manifest consumers. Rule 3 again: a
  host-dependent manifest parser makes "the build" a function of the
  developer's interpreter. Hit live this session — `tomllib` is absent on
  this box's python3. Fix without a ruling: a gate asserting both parsers
  agree on every tracked manifest.

**LOW — no ruling needed**

- **#18** — `patch_prg.py` applies every op with no expected-old-bytes and
  no source-set identity check. The old-byte verification lives in the
  GENERATOR against cached decrypted views; nothing joins that image to the
  one actually patched. Adding the check is inert if the tree is sound —
  and a finding if it is not.
- **#20** — `port_patch`/`data_port` do not assert `len(new) == len(old)`,
  so a hex-count typo silently resizes the emitted blob. Same shape: cheap
  assertion, possible finding.
- **#19** — `_PRG_RE` matches gfx members `vsw.41m`/`vsw.43m`, which the
  documented `--gfx 8` growth path creates. Inert today, wrong at the next
  member count the project has already written down.
- **#25** — `audit_wide_phase_a` A3 lets a dead measurement stand as a
  `note` and then publishes the permissive decision — against the rule the
  file's own A1 comment states.
- **#31** — `replay_guard.lua` ignores `MASK_RANGES` and has no
  input-integrity check while its header claims it "can substitute for
  replay.lua in any gate". Cheapest correct fix per the handoff is to make
  the claim TRUE (abort loudly when `MASK_RANGES`/`NO_INPUT_CHECK` is set)
  rather than porting the mask reader. Named blast radius:
  `test_crash_guard.sh` compares a guarded log to an UNMASKED expectation,
  so masking must stay opt-in or that gate goes red.

**DEFERRED WITH A REASON, AND NOW RIPE — #10 (severity HIGH)**
*"10 of 21 replay instruments feed inputs a frame later than replay.lua."*
Re-verified at HEAD 14z-93 and CONFIRMED maintainer-deliberate: the finding
is correct, it is mitigated, and the fix is deferred for a real reason.
Label `deferred-with-reason`; it stays open and stays `contested` by
decision, not by neglect.

- **State:** 21 replay-driving instruments, **10 deviant / 11 canonical** —
  the same 10 files, same two flavours the issue lists. Nothing fixed.
- **Why deferred:** the frame constants of the consuming gates
  (`test_beam_variants` DUMP_FRAMES, `test_tenant_hud` 3100/3110,
  `test_hui_df_style` OBJFR/PALFR, `audit_trap_parity` WINDOWS,
  `audit_voice_borrow` WINDOW=3985,4005) were tuned UNDER the drifted
  timing. Correcting the staging alone does not make them right, it
  silently RE-DATES them. The staging fix and the re-measurement are ONE
  change — which is also this issue's own handoff.
- **THE PRECONDITION IS NOW MET.** The gotcha scheduled it "after the
  legacy re-freeze"; that completed in 14z-91. It is ripe, not blocked —
  waiting on scheduling and on #91/#92 clearing under rule 6. **When it is
  scheduled, budget the re-measurement, not the one-line edits:** the code
  fix is one line per file in two flavours (group (i) stage
  `held[frame + 1]`; group (ii) parse `held[fr]`), and all the cost is in
  re-deriving those five gates' constants.
- **Mitigation is now real** (it was not): the gotcha promised every
  drifted instrument carried a banner and THREE did not — `bp_regs.lua`
  (none, and its header asserted the opposite), `ring_tap.lua` (none, and
  its output is frame-addressed), `read_tap.lua` (backwards direction).
  Fixed 14z-93.
- **Gated:** `tests/test_replay_stage_census.sh` pins the split at 10/11, a
  NEW instrument copying the wrong flavour FAILS, every deviant must carry
  the banner, and `replay.lua` must stay canonical. Set `EXPECT_DEVIANT=0`
  when the fix lands and it flips to asserting uniformity. **Strip Lua
  comments before censusing** — the banners quote `held[frame + 1]`, so a
  naive grep reads a drifted file as canonical (measured: it turned 10
  deviants into 3).
- **Do NOT re-freeze anything from this fix.** `replay.lua` and
  `replay_guard.lua` are both canonical and untouched, so no frozen log
  moves.

**STILL CONTESTED — 20 further items, deliberately not scheduled.** #22
(medium, `verify_pcrel_data.py` run by nothing), #77, and 18 low items.


- **#91 — A PLANTED ILLEGAL IS REACHABLE ON `merged-m1`. RULE 6: this is
  the only forward task until it is green.** Deterministic and reproduced:
  `hui41` CRASH 14767 and `m3b_merged8` CRASH 8887, both the tripwire for
  **unresolved vs2 `0x494de`**. **NOT Huitzil-only** — that was retracted
  14z-93: Pyron and Donovan's clean `END 40620` legs are a TIMING accident,
  and under a sparse probe Pyron crashes identically (#92). It is a RACE. Rig: `26_don_arcade_mash` (40,620-frame
  arcade marathon) with the forced pick — the suite's tenant rigs are too
  short to reach it and that replay picks a legacy character on its own,
  which is why this was invisible.
  **`0x494de` is a 32-bit software DIVIDE helper** (11 callers in vs2) and
  **vsavj has the byte-identical routine at `0x47fb6`** — a missing
  reconciliation row, not a missing feature. Choose the LIVE twin by
  tracing (it appears twice; content-twin trap). Do NOT remove or widen the
  tripwire — it is the detector, and 51 other deferred targets sit behind it.
  Costs a huitzil + merged re-freeze, so the row is a maintainer decision.
  Instrument: `tests/audit_tripwire_reach.sh`. **NOT the 14z-85f flaky crash
  reset** for the TRIPWIRE half (#91): Phobos was not in that recipe and the
  tripwire is Huitzil-only. **But #92 (the `0x1afb6` vec3) reproduces on
  PYRON, who IS in that recipe — so a 14z-85f/#92 link is OPEN.**

- ~~**GitHub #75 — `build_merged.sh` ABORTS on huitzil.**~~ **CLOSED 14z-92.**
  It was a VERIFIER artifact, not a build defect: `obj_records.walk`'s pointer
  pass re-derived record structure from the relocated image, so a straddled
  datum inside a real record became a valid record head under the merged
  placement window (+1 record, +67 entries, 34 out-of-band tiles). Fixed with
  the same `ptr_allow` treatment 14z-74 gave the sweep pass; gated by
  `tests/test_obj_record_walk.sh` (4 verdict controls, ROM-free, in
  ci_portable).
  **Read this part too:** the abort had ALREADY stopped happening. 14z-91
  moved `anim@huitzil` 0x41a7e0 -> 0x41a6e0 and the coincidence dissolved —
  merged8 verifies green with the pre-fix tool too (measured). Nobody knew
  because nobody re-ran `build_merged.sh` after 14z-91. **`build/m3b_merged8`
  (`952fc731`, 753 ops) now exists** and is the first merged build carrying
  the 14z-91 legacy fix — UNREGISTERED, and no merged CONTENT gate has run on
  it. That is the S6 list below.
- ~~THE BEAM VISUAL ON A MERGED IMAGE~~ **CLOSED** (maintainer,
  2026-08-16): *"beam visual is 100% clean, as is its sound."* The S6
  carry-forward is done, and the effect family — three defects, three
  root causes across 14z-70/71 — is closed end to end on the shipping
  artifact.
- **PHOBOS' HISTORICALLY-DEFECTIVE MOVESET IS FIELD-CONFIRMED ON THE
  MERGED BUILD** (maintainer, 2026-08-16): 236+P, 236+K, jump214+K,
  236+2K, 214+2K "in the variants that broke or were incomplete in the
  past and their ES variants". That is the beam family (14z-70/71, three
  root causes) and the Plasma Trap (out-of-range entry 82, the LOUD one),
  ES included — and an ES that fires is a stronger statement than it
  looks, because an empty meter silently downgrades.
  Combined with the rigs, the whole danger set for table 0x018468 is
  covered by whichever instrument can reach it: entry 82 by the
  maintainer AND `audit_trap_parity`; entry 83 (Reflect Wall, SILENT) by
  `test_hui_pairs` only — it is guard-cancel-only, so a rig is the ONLY
  way it can ever be confirmed. `test_index_space` /
  `test_variant_dispatch` / `test_index_window_thunk` all PASS on
  merged8 besides. **Remaining L/M/H strengths are unknown-unknowns, not
  a named mechanism — a nice-to-have, not a risk item.**
- ~~"IT MAY FEEL BETTER"~~ **CLOSED (maintainer, 2026-08-16): it was
  EMULATOR-SIDED**, not the ROM. No headroom/overrun A/B is needed and the
  obj_hook-cycle mechanism is NOT the explanation. Recorded so nobody
  re-opens it as a performance claim: the project has no measured
  performance-positive result, and this was not one.
- **`build/m3b_merged8` IS FROZEN as `merged-m1` (14z-92):**
  render-content, trap parity, FG parity, select-bank-gates and
  `audit_merged_legacy` (AUDIT-EXIT 0, leg a 47/47, leg b 6/6) all PASS.
  Frozen by TAG + HANDOFF row with **no `registry.tsv` row on purpose** —
  the legacy-only instrument `build/merged1` shares its program
  fingerprint, so a row would register the blanks build too. Read the
  `tests/expected/registry.tsv` header before touching that.
  Repaired in the process: `test_merged_render_content` named `build/hui31`
  as its huitzil reference — a pre-WIDE-v1.1 build MAME refuses — so H/P's
  only render gate had produced **no huitzil measurement since 14z-86**, and
  printed the dead leg as a content mismatch. Now points at `hui41` and
  reports an empty operand as a DEAD LEG. **D and P still name `m5_wide` /
  `pyron21`; re-point a row whenever that tenant is re-frozen.**
- ~~OPTIONAL, ~2 h: `tests/audit_merged_legacy.sh`~~ **RUN at the freeze,
  AUDIT-EXIT 0** (leg a 47/47 with 0 NOT-EVALUATED, leg b 6/6 guard-clean
  vs don_m7 / hui41 / pyron26). It was a re-run on this tree by
  construction; what it bought is the determinism confirmation — it
  rebuilt its instrument from scratch and reproduced 753 ops and the same
  fingerprint.
- The merged build now has its own class table, `tests/expected/merged1/` —
  read its README before touching a spec there, and do not copy a tenant
  set's line into it: the two tables are measurably not interchangeable,
  which is why it exists.
- ~~M4: `audit_hitclass_map_cost.sh` over the FULL corpus~~ **RUN 14z-92 —
  AND IT FALSIFIED THE CLAIM IT WAS FILED TO CHECK.** `hitclass_map_extend`'s
  adoption rested on "legacy never enters the map", measured over TWO
  replays — both of which happen to score zero. Corpus-wide (46) legacy
  enters **230 times** (`26_don_arcade_mash` 228, `24_don_winmash` 2). The
  fix is still sound: every legacy index is 0x02/0x04/0x09/0x0b, far below
  64, so legacy reads VANILLA's own bytes out of the thunk. The argument is
  now "legacy enters and gets vanilla answers". Section 1: 43/46
  bit-identical, 3 transient re-convergent, 0 dead. Claim retracted in
  engine_internals, HANDOFF, and both manifests.
- ~~**OPEN from #78 — two FBNeo-only phase classes.**~~ **RATIFIED
  2026-08-16 (maintainer) and implemented 14z-93.** Both are now a named §4
  class bounded by a FROZEN offset inventory (`$FF055B-D`; `$FF06D1`,
  `$FF06D4-D5`, `$FF06D9`, `$FF06DB-DD`), measured rather than transcribed —
  the 14z-92 note had recorded only the first byte of each run. Gate green.
  `ram.md:62` extended: the class is NOT tenant-content-only. Original entry: The new
  `tests/test_fbneo_legacy_oracle.sh` (the agreed partial) found, on its
  first run, differences that MAME does NOT show at the same frames:
  `$FF055B-$FF055D` (sound-driver work area, ram.md:74) and
  `$FF06D1/D4/DB` (OBJ-builder secondary stack, ram.md:62 "execution
  POSITION, not state"). Both are attributed and bounded to two named
  windows; neither is gameplay state. They are reported as `open:` lines,
  NOT as tolerances. **The ruling needed:** ram.md:62 records that class as
  appearing only on tenant-content replays where no vanilla oracle applies —
  it appears here on LEGACY content under FBNeo, which extends it. Per §4 a
  new tolerance needs sign-off. `FBNEO_ORACLE_EXPECT=exact` is the
  post-ruling target.
- ~~**OPEN from M4 — is the thunk still load-bearing?**~~ **DECIDED
  2026-08-16 (maintainer): KEEP `hitclass_map_extend`, at least for now** —
  *"we have more to lose by dropping it than keeping it."* Nothing to do; the
  row stays in `huitzil.toml` + `pyron.toml` and no build moves. The measured
  basis follows, and the ONE thing that would reopen it is named at the end.
  The tenant enters the map **0 times** over all 37
  hui+pyron rigs — while putting **121 objects of type >= 64 into the
  projectile pool** (9 distinct types, 64-72, in 22 of the 37 rigs). The gap
  is CONTACT, not absence: the sweep is POOL-vs-POOL, so a tenant projectile
  hitting a FIGHTER never transits the map. Each of those 121 is one
  collision away from indexing past vanilla's 64 entries.
  **The dead crash control is diagnosed, not mysterious** (section 4): the
  soak rig reaches the map 0 times, so the no-thunk twin has nothing to crash
  on — yet that same rig still spawns 13 type-64/67 objects. A RIG failure.
  Do NOT drop the row on it, and do not re-point it at a new crash address.
  **Count the rows carefully:** 93 stamp rows carry `type >= 64`, but only
  **36** are in the 64-75 projectile-pool band that can over-index this map;
  the other 57 are the 114-120 obj_hook family (owner-tag served, never
  reaches the sweep). 93 overstates the exposure 2.6x.
  **WHAT WOULD REOPEN IT (the "for now" clause):** a pool-vs-pool contact rig
  that section 3 then measures at 0 extension entries. Nothing else — and
  specifically not the dead crash control, which is a rig artefact.
- **OPTIONAL, and no longer blocking anything: author a pool-vs-pool contact
  rig.** No rig in the corpus produces one, which is why the census reads 0.
  `tests/replays/hui/88_hui_plasma_trap_contact.rpl`'s header names what is
  needed — "an opposing PROJECTILE to clash with, e.g. P2 Victor doing a
  pool-object move into the mine — not a walking fighter". Pyron's cosmo rigs
  are the richest source (17-28 type-66 spawns each), so a Pyron-vs-
  projectile-character pairing is the likeliest route. It would buy two
  things: the tenant census gets a real denominator, and section 0's crash
  control becomes revivable. With KEEP decided, this is coverage work rather
  than a decision blocker.
- The M5 sfx odds (0x112/0x14a/0x173/0x31B family — machinery ready).
- FLAKY CRASH RESET (Sasquatch intro; rig designed, STATE 14z-85f).
- ~~Round-end flicker~~ **CLOSED 2026-08-18 (maintainer).** It was carried
  as "parked, needs the maintainer's recording"; the merged-m2 playtest
  did NOT observe it and the maintainer ruled it closed. Not carried
  forward. If it ever resurfaces the first question is which build and
  which emulator — the 14z-93 prediction that it would correlate with
  voice events rested on the `$FF8100`-is-a-voice reading, which 14z-94
  corrected to the ladder STAGE index, so that link does not follow.
- OPTIONAL / cosmetic (maintainer 2026-08-15): the merged-only
  P2-ring-on-Donovan medallion whitening; win-screen QUOTE (both tenants);
  region_space re-freeze; op-tagging for test_shared_writes. **Donovan's
  venue palette row 0x0F** joins this list — change A traded vs2's red
  statue ramp for vsavj's, which the scope ruling makes optional; the
  cost-neutral route back (init shim → the engine's own copy helper
  `0x1C3A4` → staging row 0x0F, i.e. the fade's SOURCE) is written up in
  `build/manifest/donovan.toml` above the retired rows.
- ~~H-vs-P stuck-direction (~1/30)~~ **CLOSED 2026-08-16 (maintainer):
  never reproduced on FBNeo at all, and not reproduced on any recent build.**
  Surmised to be either an emulator-side artefact or a symptom of the period
  when Pyron and Phobos SHARED code — which they no longer do (the 14z-85
  spawn-time owner tag gave the 0x54470 family per-tenant resolution, and the
  type_renumber path did the same for 114-119). Not carried forward. If it
  ever resurfaces, the first question is which emulator, and the second is
  whether any shared-resolver path has been reintroduced.
- Then MiSTer core surgery (stretch, DECIDED) — after the roster.
- **BEYOND MiSTer (scope extension, maintainer 2026-08-18):** **GitHub
  #100**, the next-stage screen showing Donovan with a Victor name and a
  blank portrait. Closed WON'T FIX for now under the standing cosmetic
  ruling (cosmetic + single-player-only surfaces are nice-to-have) and
  re-scoped to after MiSTer. **The mechanism is already measured, so
  whoever picks it up starts from the fix, not the hunt:** one writer
  (`PRG:0x00A446`, `andi.w #$000F` at `0x00A442`) feeding `RAM:$FF8130`,
  and FOURTEEN readers — eight of which RE-FOLD, so widening the writer
  alone changes nothing. Full detail on the issue and in STATE 14z-95.

## Build / validate

(paths refreshed to the 14z-99 freeze generation at the post-freeze close —
the commands are operational, not historical, even though they sit below the
history marker)

```sh
export ROMDIR=/path/to/reference/sets
export MAME_BIN=~/.cache/vampire-saved/mame/cps2

# the canary — safe as written since 14z-91
VERIFY_BASIS=16_xemu_2p tools/freeze_masked_basis.sh \
  tests/expected/vsavj/masked-v2 "$(cat tests/expected/donovan-m9/mask)" 16_xemu_2p

MAME_ROMPATH="$PWD/build/don_m9/rompath;$ROMDIR" tests/run_suite.sh vsavjw
tests/test_m3a_reproducible.sh                 # ~6 min, all five, hard on content
tests/audit_walker_ghost.sh                    # ~5 min — the mask assumption
tests/audit_walker_repoint.sh build/don_m9     # ~5 min — caller completeness
tests/test_obj_walker_relocation.sh build/don_m9   # seconds, ROM-free
tests/audit_legacy_pairings.sh                 # ~30 min — the coverage gate
tests/test_obj_record_walk.sh                  # seconds, ROM-free — the #75 gate
tools/build_merged.sh build/m3b_merged11       # ~1 min
```

## Rebuild recipes

```sh
KEY_SET=vsavj WIDE_ROMSET="$PWD/build/wide0/rompath/vsavjw.zip" \
  GEN_FLAGS="--allow-plausible --tripwire-open --profile cps2-wide-v1" \
  tools/build_donovan.sh 6 build/don_m9
TENANT_MANIFEST=build/manifest/huitzil.toml TENANT_CHAR=0x10 ... build/hui45
TENANT_MANIFEST=build/manifest/pyron.toml   TENANT_CHAR=0x11 ... build/pyron29
GEN_FLAGS="--allow-plausible --tripwire-open" tools/build_donovan.sh 6 build/m5_stock4
```
