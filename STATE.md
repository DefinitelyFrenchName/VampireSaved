# STATE — living progress log

## Session 14z-109 (4) — **THE #99 CRASH INVESTIGATED ON EMULATOR: a
## confirmed mechanism CLASS, real eliminations, and an HONEST GAP — no
## clean natural repro of the exact field crash yet.** Also surfaced: the
## standing crash-soak coverage has rotted, which is why nothing caught it.

**Maintainer's refined field data (2026-08-26):** 1P-vs-COM ARCADE ONLY,
Donovan P1 vs Phobos, crashes at SOME point in the match (not necessarily a
hit, not necessarily the start); **2P versus Donovan-vs-Phobos does NOT
crash**; first-fight Phobos crashed ~1/2, the ladder second-fight (after
beating Bishamon) is the 100% path.

### CONFIRMED BY DISASSEMBLY — the per-class sfx dispatcher is UNBOUNDED

`PRG:0x27F16`: `move.b (0x382,a6),d1` -> `lsl.w #2,d1` -> `lea 0x0BF41A,a0`
-> `movea.l (0,a0,d1.l),a0` -> jumps through `a0`. **No bounds check.** The
table has valid handler pointers for classes `0x00-0x27` (legacy + arcade +
the three tenants at `0x10`/`0x11`/`0x13` -> WIDE ext); beyond that it reads
non-pointer bytes. **Forcing an out-of-range class into `+0x382` crashes
exactly there** — probe J: class `0x20`/`0x30`/`0x40` -> `vec3` address
error at `~0x02adXX`; `0x12`/`0x14`/`0x18`/`0x28` safe.

### THE FIELD PATTERN FITS THIS, AND 2P-CLEAN IS THE KEY

The voice-class borrow (`PRG:0x0AEF2`, thunked to our `0x3FFC60`) runs in the
ARCADE path and writes `+0x382` from the opponent-candidate list; its value
is sound-fed (`$FF8110`), hence STOCHASTIC. 2P has no borrow, so `+0x382`
stays the char id (`0x13`/`0x10`, both valid) -> never crashes. A bad class
armed at match start FIRES on the next sfx event, which can be any time ->
"crashes at some point, not necessarily a hit". Every field observation is
consistent with a bad `+0x382` reaching the unbounded dispatcher.

### ELIMINATED: the #92 stage-`0x18` mechanism

The 14z-94 #92 crash was table-B stage `0x18` (vs2's 13th stage) indexing the
banner family past its end. **Measured: tenant table-B rows `0x10`/`0x11`/
`0x13` contain NO `0x18`** — the fix covered Donovan too. This is a DIFFERENT
bug in the same subsystem, NOT a #92 regression.

### THE HONEST GAP — no clean natural emulator repro

- probe J crashes but on a FORCED class (artificial).
- probe H crashed (`0x01850e`, a different PC — a state jump-table, not the
  sfx dispatcher) but had in-match class pokes; not trustworthy.
- first-fight-Phobos: 8 sound-state seeds, active Donovan, ZERO crashes.
- the committed `audit_continue_switch.sh` DRIFTED on merged13 — it ran clean
  but never reached the Donovan-vs-Phobos pairing (its trajectory is frozen
  to merged11), so its "clean" is vacuous here. **This also weakens the
  original #99 closure, which the 14z-100 note already flagged as "weak
  evidence".**
- **POSSIBILITY TO HOLD: the crash may be more readily reproducible on the
  CORE than on MAME** (user 100% vs my ~0% natural). Either a stochastic
  state my rigs missed, or a core-specific amplifier. 2P-clean on the core
  argues against a pure asset-streaming collision.

### WHY NOTHING CAUGHT IT — coverage rot (the recurring class)

- `26_don_arcade_mash` (the "Donovan arcade mash" soak) navigates U,U,R,
  which on the EXTENDED wheel lands on **Jedah `0x0F`**, not Donovan — the
  soak lost its nominal subject.
- `audit_continue_switch.sh`'s frozen trajectory no longer reaches the
  pairing. **No current gate exercises Donovan-vs-CPU-Phobos.** Same
  "check that stopped checking" class as 14z-94/95.

### ARTIFACT

`tests/replays/109_2p_don_vs_phobos.rpl` — the first 2P versus replay in the
tree (CLAUDE.md §4 has wanted "vs each of the 18, both sides"), P1 Donovan vs
P2 Phobos via the extended wheel, made possible by tonight's P2 scripting.
Verified P1=Donovan `0x3FA9D0` / P2=Phobos `0x4595B0` load on MAME.

### CORRECTION + SHARPENED LEAD (same session, after the candidate-row check)

**THE ARCADE-BORROW THEORY IS WEAKENED — stated plainly because it was the
banner above.** I checked Donovan/Phobos/Pyron candidate rows (table A) against
the dispatcher's handler table read from the RIGHT source (member 04d, not the
mis-byte-ordered data view): **every candidate value is `0x00-0x18`, and every
one of those has a valid dispatcher handler.** So the borrow cannot write a
crash-inducing class into `+0x382`. Probe J proved the dispatcher is UNBOUNDED,
but with inputs (`0x20`/`0x30`/`0x40`) the borrow can never actually produce.
Probe J is therefore the right MECHANISM with the wrong INPUT SOURCE.

**THE SHARPENED LEAD, and it fits the field data better: a specific PHOBOS
MOVE.** The maintainer's own refinement — "Phobos's attacks crash, Donovan's
never do", "5+MP or 6+MP", "at some point" — plus the crash signature (immediate
black screen -> the GAME reboots to its RAM test, NO prior graphical/sound
corruption = a clean jump through a bad pointer, not data rot) points at a
Phobos move whose execution dereferences a bad pointer. The CPU AI uses
Phobos's full moveset; a human in 2P may simply never have thrown the exact
move — which makes "2P clean" most likely a COINCIDENCE, exactly as the
maintainer cautioned, not a property of the 1P path.

**This is the 14z-73 grab-victim SHAPE** (a move indexing a per-victim
keyframe/effect table that, for one victim, reads a bad row), possibly UNIFIED
with the unbounded per-node sfx dispatcher (an anim node carrying an
out-of-range sfx class in its `+0x16` trigger -> `0x27F16` jumps through
`table[badclass]`). Both are "a specific move -> a bad pointer jump" and both
fit every observation.

**THE DISCRIMINATING TEST (maintainer, on hardware): 2P, HUMAN Phobos vs human
Donovan, deliberately spam Phobos's suspected move (5MP/6MP).** If it crashes,
the arcade path is IRRELEVANT and the bug is in Phobos's moveset vs a tenant
victim — chase Phobos's move/effect/keyframe data. If Phobos genuinely cannot
crash it in 2P no matter the move, the 1P-arcade path really is special and the
borrow/AI path comes back. Either answer halves the search.

### NEXT (measurement, not arbitrage — per the maintainer's standing ask)

Reach the pairing NATURALLY and TRACE the borrow's actual write to `+0x382`
for a Phobos opponent: re-measure the continue-switch trajectory for
merged13 (its header documents how) OR a fresh venue-steered marathon, then
tap `$FF8782`/`$FF8B82` through the Donovan-vs-Phobos match. If a class
whose `table[class]` is a bad pointer appears, that is the root cause and
the fix is either bounding the dispatcher or fixing what the borrow writes
for a tenant opponent. The 2P sim (core) is a cross-check, not the hunt.

## Session 14z-109 (3) — **THE FIELD TEST RAN, AND THE ARC'S QUESTION IS
## ANSWERED: THE CORE WORKS ON HARDWARE.** Tenants selectable and playable,
## TENANT VOICES PLAY (the one thing simulation could never answer), select
## screen emulator-identical. **AND ONE 100%-REPRODUCIBLE CRASH — which is
## #99 BACK FROM THE DEAD, now with a deterministic repro path it never had.**

**The maintainer's field report (MiSTer, DE10-Nano, 2026-08-26), verbatim in
substance — the primary artifact:**

- Boots; 1P vs COM plays well, general feel BETTER than emulator (likely
  input-lag/handling, the maintainer suggests).
- **Sound plays, INCLUDING THE NEW TENANTS' — all seems good.** ["Fetched is
  not heard" is retired: the QSound extension is now HEARD on hardware.]
- Select screen emulator-identical, usage-wise perfect (parked cosmetics
  aside, out of scope).
- All 3 tenants selectable, playable, no graphical or other issues before,
  during or after matches — with ONE exception:
- **A 100%-reproducible crash-reset: pick DONOVAN 1P in normal mode, first
  fight BISHAMON, WIN it -> second fight is ALWAYS PHOBOS (stage may vary,
  opponent never) -> crash-reset at the end of the character intro or just
  as the fight begins, regardless of input.** Not tried on emulator yet.
  Does NOT happen picking Phobos or Pyron as P1.
- 2P versus not yet tried; confidence high.

### THE CRASH IS #99, AND ITS CLOSURE DID NOT HOLD

Archaeology (CLAUDE.md §5, done BEFORE touching anything):
- **14z-94 (#99):** the SAME signature — Donovan vs CPU-Phobos, "crashed
  right after the character's intro at fight start" — on **MAME**, build
  merged9, reached via continue+switch to match 5. So the crash class is
  NOT MiSTer-specific.
- **14z-100:** `tests/audit_continue_switch.sh` reached the literal
  Donovan-vs-CPU-Phobos pairing at **match 4** on merged11 and ran clean —
  the basis for closing #99, with the caveat recorded at the time: "the
  clean pass is weak evidence" that #103's fix removed the trigger.
- **The field path is DIFFERENT and NEVER TESTED: match 2, reached by
  WINNING match 1 (vs Bishamon), no continue.** The 14z-100 rig cannot have
  exercised it.
- Also on the books: the 14z-94 LEAD, explicitly unmeasured then — the
  voice-class borrow (`ram.md:87`) writes a class from the OPPONENT'S
  candidate row into `+0x382` at match start; a tenant opponent makes that
  a tenant class; and the crash timing (right after the intro) is when the
  dispatcher first fires.

**In flight: an emulator repro attempt** on merged13/MAME under the crash
guard — if it reproduces, the full instrument set (write taps with PC
attribution, per-frame dumps) applies; if it does not, the difference
between implementations is itself the lead.

## Session 14z-109 (2026-08-25/26) — **THE FIELD TEST GAINED A NEGATIVE
## CONTROL IT DID NOT HAVE, AND THE OBJ LIST BECAME THE FIRST WORKING
## CROSS-IMPLEMENTATION VIDEO ORACLE.** Opened while the maintainer's
## hardware test was pending, so everything here is work that does not need
## the board. **IN FLIGHT AT THE TIME OF WRITING: the field test itself.**

**The session in one line:** it started as housekeeping during a wait, found
that the field test was about to be run WITHOUT a control, and ended by
making a video-determining surface agree across two unrelated codebases for
the first time.

### WHAT WAS ESTABLISHED

| | result |
|---|---|
| the field-test bundle | had **ONE MRA and no control**; now carries a STOCK CONTROL leg |
| MRA part resolution | **WIDE 31/31 resolve, STOCK 22/22** after the pristine swap — measured, not assumed |
| the bundle README | item 5 was **STALE**, corrected later in 14z-108 than the README was written |
| the fork README | brought to D0-D5 (was "slice D1", 5 files against the tree's 13) |
| the OBJ list as an oracle | **WORKS** — promoted subset 31 vs 31, field-for-field IDENTICAL |
| the walker | calibrated **1153/1153 lines** against the live-machine one BEFORE use |

### THE RESULT THAT MATTERS

At the frozen tenant anchor (`36_pick_tenant_cell`, MAME 2886 / sim 3546) the
**PROMOTED** subset of the OBJ list is **31 entries on BOTH legs, ORDERED AND
FIELD-FOR-FIELD IDENTICAL**, and the 19-bit tile addresses slice D3 computes
are the same set, **`0x4b0c4-0x4ecda`**. The promote, the group-C redirect and
the 3-bit bank are confirmed against an unrelated codebase at the sprite-list
level. **First cross-implementation agreement this project has on a
video-determining surface, and it is on the content the port exists to add.**
**STILL NOT PIXELS** — this is the LIST, not the rendered frame.

### THE CORRECTION, WHICH IS WORTH MORE THAN THE RESULT

The raw lists do NOT match: **40 entries vs 129**. I reported that mid-run as
"a real difference — the core genuinely holds a shorter list". **THAT WAS
WRONG.** A 1P replay's CPU opponent is the SOUND-STATE-FED LOTTERY
(`atlas/ram.md:99`) and genuinely differs between the legs —
`test_mister_tenant_oracle` **already excludes the P2 fields BY NAME for this
exact reason**, and I had that fact in front of me before I ran anything.
Most of the list is the opponent's sprites.

What rescues the surface: an OBJ list cannot be filtered "by P2" the way a
field table can — **sprites carry no owner** — but OUR content IS labelled.
**y bit 12, the CPS-2 Turbo promote, is set on exactly the group-C sprites
this port adds and on nothing vanilla can emit.** So the promoted subset is
ours, is lottery-free, and must agree exactly; the remainder is REPORTED,
never asserted.

**THE LEGACY CONTROL WAS RUN AND IS ALSO CONFOUNDED — recorded so it is never
read as evidence.** `05_timeout_idle` is 1P arcade too, so it draws different
opponents as well (counts agree 52/57 vs 61, codes barely overlap). **A clean
WHOLE-list comparison needs a PINNED OPPONENT, which needs P2 scripting in
`SimInputs` — still the deferred COVERAGE item, and now with a concrete
reason to want it.**

### THE FIELD TEST HAD NO CONTROL

The bundle shipped one MRA, so any failure — black screen, boot loop, wrong
art — would have been indistinguishable between "our profile is wrong" and
"the bitstream, the card, the SDRAM module or the video chain is wrong".
By this project's own standard that is not a measurement. Added (outside the
repo, rule 7): the **STOCK CONTROL MRA** (vanilla `vsavj` on the SAME `.rbf`
with the profile bit at the `0xFF` fill — verified, the file names
`<rbf>jtcps2w` and contains no `0xFE`), `games/mame/vsavj.zip`, and
`FIELD_TRIAGE.txt` (nine symptoms, each with meaning and next action).
**Measured on the way: pointed at the bundle as shipped the control MRA loses
8 of its 22 parts** — four patched art members AND four program members — and
jtframe `0xFF`-FILLS an unresolved part rather than refusing, so it would have
"run" and shown nonsense.
**The pre-D5 boot loop converted to something usable at a board: ~26.5 s** at
the real 59.6374 Hz (`8 MHz / (512*262)`, MAME `cps1.h:39-45`).

### RETRACTION DISCIPLINE — THE SWEEP HAS TO LEAVE THE TREE

The bundle README's item 5 called the identical 128 KB "scroll tilemap", said
the layer-enable registers were undocumented, and invited treating a
wrong-looking background as "the first hard evidence either way". All three
were corrected LATER in 14z-108 than the README was written. **The bundle
lives OUTSIDE the repo, so the CLAUDE.md §5 grep over `docs tests` could never
have found it.** When a claim is corrected, the sweep must reach artifacts
that have already left the tree.

### NEW INSTRUMENTS, all with must-fire controls

- `tools/check_mra_parts.py` + `tests/test_mra_parts.sh` (ci_portable, ROM-free)
- `tools/oram_obj_records.py` + `tests/test_obj_records.sh` (~2 min, MAME only)
- `tests/test_mister_obj_oracle.sh` (~65 min; `--sim-dir/--mame-log` re-analyse
  finished runs). **Its page selection does NOT hard-code a buffer:** CPS-2
  ORAM is double-buffered with a runtime page select
  (`main_addr_x[13] = main_ram_addr[15] ^ obank`), so it walks both and lets
  the comparison choose. Hard-coding a page is how a phase difference gets
  reported as a content difference.

### PUSH STATE

`origin/main` holds **`613db08`** (verified with `git ls-remote`, not a
tracking ref). The fork README commit `c97e3d14` was **deliberately NOT
pushed** at the maintainer's instruction, and the main-repo commit that bumps
the `emu/jtcores` pin to it is therefore held back too — publishing it would
point public `origin/main` at a fork commit the fork remote does not carry.
**Push the FORK first, then that commit — never that commit alone.**
**[RESOLVED 2026-08-26: the maintainer authorised the fork push. Done in
that order — fork `c97e3d14` first, then the pin bump. `origin/main` now
holds `10cf9ce` and NOTHING is local. The ordering rule above is kept
because it is the general lesson, not because anything is still stranded.]**
The two
commits were reordered (disjoint by file) so everything else could ship; the
resulting tree hash was verified byte-identical before each push.

### VERIFICATION

`tests/run_all_static.sh --strict` GREEN at the session open (PASS 107) and
after the changes (**PASS 108**, SKIP 0, FAIL 0, MISSING 0), with the tree
clean under the run — the 14z-108 discipline (commit first, then run, then do
not type) followed this time.

## Session 14z-108 CLOSE — ritual complete. **THE FUNCTIONAL CHAIN IS
## COMPLETE IN SIMULATION AND THE CORE FITS A CYCLONE V — BUT IT DOES NOT
## RELIABLY CLOSE TIMING.** A tenant FIGHTS on the core and fights
## CORRECTLY against MAME; the QSound extension is FETCHED; bank 1 under
## load is GO; scroll is structurally cleared; the CPS-2 video registers
## are documented for the first time. **AND THE SESSION'S OWN HEADLINE IS
## THAT FOUR OF ITS FINDINGS WERE CORRECTIONS OF THINGS PUBLISHED EARLIER
## THE SAME DAY** — three of them mine. **22 commits, ALL LOCAL.**

**The session in one line:** it opened on a two-data-point inference about
the simulator's joystick, proved that inference wrong by measuring all four
directions, and that one fix unblocked every remaining question in the arc.

### WHAT WAS ESTABLISHED, each with a control that fires

| | result |
|---|---|
| the input path | **REVERSED end for end**, not transposed in two — measured on all four against `RAM:$FF8058` |
| a tenant FIGHTING | obj bank 4: **9,388,928 reads / 1,735 tile codes**, 843 traffic frames INSIDE the match; control leg zero |
| fighting CORRECTLY | §4 oracle agrees with MAME field-for-field; `p1_hitbox_base 0x003FA9D0` on BOTH legs |
| the QSound EXTENSION | **210,180 reads in DSP bank `0x83`**; control leg zero while still streaming 54 M low-bank reads |
| bank 1 under load | peak 15,496 acc/frame = **12.5% of ceiling**, ZERO clashes |
| FIT on a Cyclone V | **+206 ALMs (+1.1%)**, RAM blocks / DSPs / PLLs unchanged |
| scroll | **structurally cleared** — D2 cannot have moved it, by construction |
| the video registers | documented in `atlas/ram.md` for the first time |

### THE ONE HARD RESULT

**`cps2w` does NOT reliably close timing: 4 of 12 seeds fail** (median
+0.038 ns against the control's +0.431; two "passes" clear by under 10 ps).
Every failing path is inside `jtframe_sdram64` — shared infrastructure the
fork does not touch — so it is not WIDE's logic being slow, it is WIDE
loading a cone that was already tight. **Ruled by the maintainer: A + B,
C in reserve, D acceptable, E opposed.** B is IMPLEMENTED: releases are
built from a NAMED seed with slack and sha256 verified.

### FOUR CORRECTIONS, WHICH IS THE PART THAT TRANSFERS

1. **"The main repo is NEVER pushed" was FALSE** — `git ls-remote` showed
   `origin/main` at the 14z-107 close. True when written, copied forward as
   standing fact, including by me into a banner an hour earlier.
   **A tracking ref is a claim about the last fetch; prose is a claim about
   the day it was written.**
2. **The jtseed claim was OVERSTATED, by me more than by its author.**
   `jtseed 4` retrying does NOT ship failing bitstreams (~99% of invocations
   pass) — **it hides FRAGILITY, not correctness. A green run certifies "one
   placement was found that closes", never "this design closes with
   margin".**
3. **I called unclaimed VRAM "scroll tilemap".** No layer base points above
   `$910000`; the agreement was real but misnamed, and the naming made the
   layers sound like they agreed when the opposite was true.
4. **The VRAM difference is NOT ours.** The legacy control — stock `vsavj`,
   vanilla replay, same core — reproduces the same pattern and magnitudes.
   **The useful negative: VRAM is not a viable cross-implementation video
   oracle**, because two implementations legitimately differ there by half
   the palette.

### INSTRUMENT DISCIPLINE

The lane's defect count reached **eight**, and 14z-108 added **five more
caught BEFORE use** — four in one new analysis block (cumulative counters
read as per-interval; a picosecond timestamp read as an index; a clash
counter matching this report's own PROSE; a "peak" that was the ROM
download) and one check that **passed because macOS awk lacks `and()`** and
exited into the `else` arm. A sixth was a control that fired for the WRONG
REASON: byte-swapped dumps have no anchor, so the field comparison never
ran. **A control that never reaches the code under test is not a control.**

### RITUAL

- **STATE**: this entry. **THE ROLLOVER EXECUTED on the SIZE arm** — the
  whole 14z-107 group (4 entries + the sub-entry pointer, 1,087 lines) moved
  BYTE-VERBATIM to `STATE_HISTORY.md` with its ledger line here, verified by
  sha256 and by the absence of any `## Session 14z-107` header.
  **STATE.md 207,725 -> 136,520 B — under the ~150 KB guide for the first
  time in this arc.**
- **`docs/NEXT_SESSION.md`**: rewritten. The opener is **THE FIELD TEST**,
  which is the maintainer's and is the only thing that moves the arc.
- **`HANDOFF.md`**: MiSTer block current, three new gate rows registered.
- **GOTCHAS**: six filed and all six indexed — the reversed directions,
  macOS awk, Quartus needing `--network host`, `git clone --recursive`
  resolving against the default branch, `xjtcore.sh` retrying until a seed
  passes, and the BUILD datestamp defeating hash reproduction.
- **THREE MAINTAINER RULINGS** taken and marked DECIDED in place: the
  timing-margin response, MiSTer packaging (option A now, B later), and the
  field test scheduled.
- **A STANDING WARNING I BROKE THREE TIMES TODAY, recorded because the
  pattern is the point.** "Do not touch the tree while something long is
  reading it" exists because `sh` reads scripts by byte offset — and while I
  never edited a script mid-run, I edited STATE.md/HANDOFF.md under a running
  `run_all_static.sh` three separate times, each of which made the suite
  report the working tree as DIRTIED. Harmless every time (the gates were
  clean; the dirt was mine), which is exactly why it kept happening: a
  warning whose violation is usually harmless is one that erodes. The
  discipline that actually works is the one 14z-107 used — **commit first,
  then run the suite, then do not type until it finishes.**
- **SCRATCH HYGIENE — one clone DELIBERATELY KEPT, against the 14z-107
  precedent.** `/tmp/vampire-saved-jtsim-14z108` (1.3 GB) is rebuild litter by
  the project's own standard and 14z-107 swept eleven such clones. **It is
  kept because a FIELD TEST is imminent and any surprise from it is most
  cheaply diagnosed by a follow-up simulation**, which this clone makes
  immediate instead of costing a full ROM build first. Stated rather than
  left silent so it is a decision and not an omission; sweep it once the
  field test has reported. The session scratchpad (163 MB of dumps, probe
  logs and comparison legs) is ephemeral by construction and every
  conclusion drawn from it is in this entry or the live docs.
  **`../mister_fieldtest_14z108/` (28 MB) is DURABLE and must not be swept**
  — it is the field-test bundle, and it lives outside the repo because it
  carries ROM content (rule 7).

## Session 14z-108 — **THE SIM HARNESS'S DIRECTION BITS WERE REVERSED END FOR
## END, NOT TRANSPOSED IN TWO — measured on all four before one bit was
## changed, and the half nobody had exercised is where the previous reading
## was wrong.** `tools/rpl2siminputs.py` fixed (one dict, no fork commit, no
## RTL), verified against the game's own input mirror on both
## implementations, and the gate rebuilt with a per-direction lock and a
## must-fire control. **One of the two frozen expectations the record said
## would move DID NOT MOVE AND COULD NOT** — which also means the frozen sim
## anchor could not move. **AND THE PAYOFF LANDED THE SAME SESSION: OBJ BANK 4
## — THE FIGHTER ART — IS FETCHED FOR THE FIRST TIME ON ANY FPGA
## IMPLEMENTATION, 843 OF ITS TRAFFIC FRAMES INSIDE A MATCH. A TENANT HAS
## FOUGHT ON THE CORE.** Bank 1 under load answered from the same run and it
## is GO. **Still never: HARDWARE — and no Quartus synthesis has ever been
## run, so resource fit and timing closure are unknown. That is now the
## largest gap in the arc.**

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

### THE PAYOFF: A TENANT HAS FOUGHT ON THE CORE

`tests/test_mister_gfxc_fetch.sh --rpl tests/replays/36_pick_tenant_cell.rpl
--frames 4400` — **PASS in full**, both halves, both controls, 93m26s a leg.

| probe | window | reads | distinct codes | first frame | codes | frozen extent |
|---|---|---|---|---|---|---|
| p0 **obj bank 4, FIGHTER art** | ba1 `800000` | **9,388,928** | **1,735** | 1781 | `0xAD8F-0xEE42` | `0xEE73` INSIDE |
| p1 obj bank 5, wheel art | ba0 `7E0000` | 19,246,336 | 206 | 1556 | `0x74D6-0xFE41` | `0xFFDB` INSIDE |

**Obj bank 4 had never been non-zero on any core.** 843 of its 2,331 traffic
frames are AFTER match start (absolute 3559 = MAME's replay-frame ~2900 plus
the 659-frame WIDE transfer), running to the replay's last frame.

**THE COHERENCE IS THE EVIDENCE, more than either count.** The two group-C
probes behave according to their CONTENT: the wheel art stops at the
select/VS boundary (last traffic frame 3498, zero after) and the fighter art
carries through the match. A promote addressing the wrong thing does not
produce that split.

**THE CONTROL LEG READS ZERO** from both group-C windows — the SAME `.rom`
with header byte 41 `0xFE`->`0xFF`, one byte, the runtime profile bit — while
still issuing 105,418,104 reads in bank 3, and its working set is the LOOPING
boot's 263 distinct blocks against the positive leg's 6,208. So the zero is
about the profile, not about the probe.

**AND THE REPLAY WAS CONFIRMED ON MAME FIRST**, before 2.5 hours of
simulation were spent on it: `36_pick_tenant_cell` on the WIDE romset under
the source-built MAME reaches **P1 `+0x382 = 0x13`** — the tenant's native
vs2 id — with hitbox base `+0x60.l = 0x03FA9D0` (relocated tenant data) and
the match live from replay frame ~2900. So a zero from the sim would have
been a finding about the CORE, not about the replay. That is the
rig-produces-the-real-event discipline, applied before the cost was paid
rather than after.

### BANK 1 UNDER LOAD: ANSWERED FROM THE SAME RUN, AND IT IS GO

`--stats` on the fetch gate's legs (14z-108) means the tenant match answers
`mister_core.md` §12's other open question without a third 70-minute run.
Whole run, 3,738 post-transfer frames:

| bank | acc/frame | peak | % ceiling at peak |
|---|---|---|---|
| ba0 | 40,985 | 54,363 | 43.9% |
| **ba1 (PCM + group-C obj bank 4)** | 11,905 | **15,496** | **12.5%** |
| ba2 | 149 | 3,336 | — |
| ba3 | 3,765 | 6,161 | — |

**ZERO `SDRAM reads clashed` warnings in 3,738 frames.** The 14z-107 (12) run
measured ba1 at 13,890/frame with PCM ALONE (it picked Demitri); the tenant's
fighter art now shares the bank and adds ~1,600 accesses/frame at peak
without contending. **The repack's bank-1 half is GO on measurement.**
Caveat: ONE replay, ONE tenant, one opponent.

### WHAT IS STILL NEVER

**HARDWARE.** Nothing in this lane has left Verilator, and — recorded here
because it had never been named as a gap — **no Quartus synthesis has ever
been run on any slice**, so neither RESOURCE FIT nor TIMING CLOSURE is known
for `cps2w` or, for that matter, for the reference `cps2` on the same
toolchain. Functional simulation says nothing about either. That is now the
largest unknown in the arc and it needs no hardware to answer: Jotego ships
the toolchain as a Docker image (`jotego/jtcore20x`,
`.github/workflows/q20.yaml:51`), so `xjtcore.sh cps2w mister` plus the same
for `cps2` as the REFERENCE LEG produces fmax and utilisation for both.
Quartus is Linux/Windows only, so it cannot run on this Mac. Also still
never: the QSound extension heard, the scroll path with a wide GFX map, and
any frame compared programmatically against MAME's.

### AND THE TENANT FIGHTS *CORRECTLY* — THE §4 ORACLE ON AUTHORED CONTENT

**Fetching art is plumbing; this is the first evidence the tenant BEHAVES.**
CLAUDE.md §4 requires new-character content — for which no vanilla oracle can
exist — to agree with a second implementation on mapped gameplay state at
sync anchors. That protocol had never been run on tenant content against the
core. It has now, and it AGREES.

`36_pick_tenant_cell`, the WIDE romset, MAME against `cps2w` under Verilator,
both dump sets integrity-checked (301 and 351 frames):

| | anchor | |
|---|---|---|
| MAME | **2886** | |
| sim (absolute) | **3546** | |
| skew | **660** | = the 659-frame WIDE transfer **PLUS ONE** |

**THAT +1 IS A RESULT IN ITSELF.** The legacy replay shows skew 463 on a
462-frame transfer — also +1. Two different replays, two different romset
sizes, the same one-frame offset: **the boot-phase difference between MAME
and the core is a CONSTANT, not a function of the content.**

**P1 IS THE TENANT ON BOTH SIDES, byte-identical:**

| field | MAME @2886 | `cps2w` @3546 | |
|---|---|---|---|
| `p1_hitbox_base` | `0x003FA9D0` | `0x003FA9D0` | the RELOCATED tenant record, in `wide_ext` |
| `p1_ptr64` | `0x003FA790` | `0x003FA790` | likewise |
| `p1_hp` / `p2_hp` / `p1_white_hp` | `0x0120` | `0x0120` | |
| timer / `p1_x` / `p1_y` / meter / word132 | — | — | all agree |
| `p2_hitbox_base` | `0x000ABD74` | `0x0009769E` | **EXCLUDED BY NAME** |

**The core did not merely fetch tenant tiles — it LOADED THE TENANT'S
RELOCATED CHARACTER RECORD from above `CPU:$400000` and ran the match on it.**
`compare_fields` reports "all compared fields agree".

**THE ONE DISAGREEMENT IS THE DOCUMENTED ONE, AND ITS BEING LIVE IS USEFUL.**
`p2_hitbox_base` differs because the CPU opponent is a SOUND-STATE-FED lottery
(`ram.md:99`, the #110 mechanism) — the same class as the legacy anchor's
`$0AE9D4` vs `$0A9518`. It is in the skip list for a measured reason. That it
FIRES here proves the field set is not passing vacuously.

**THE COMPARISON WAS PROVEN ABLE TO FAIL BEFORE ITS PASS WAS BELIEVED.** The
first control tried was a byte-swap of the sim dumps — it "fired", but for the
wrong reason: the swapped data has NO ANCHOR, so the field comparison never
ran at all. **A control that never reaches the code under test is not a
control.** Replaced with a perturbation of the TIMER — compared, but not an
input to the anchor predicate — which keeps both anchors intact and is then
caught and NAMED at all three follow offsets. Both controls are in the gate.

**CAPTURED AS A GATE**, per the persistent-suite doctrine:
`tests/test_mister_tenant_oracle.sh` (emulator tier, ~65 min), with the
anchors and skew frozen, the tenant-record assertion on both legs, and the two
controls above plus a third that removes the skip list and requires the legs
to disagree.

### FIRST CROSS-IMPLEMENTATION COMPARISON OF A VIDEO-DETERMINING SURFACE

**"Video compared against MAME" has been NEVER for the whole arc.** Pixels
need infrastructure neither side has, but `$900000-$93FFFF` is VRAM — the
palette and the scroll tilemaps, the data that DETERMINES the frame — and it
is dumpable on both: by address on MAME, and on the core because D2 maps it
to SDRAM bank 0 byte `0x600000` (`VRAM_OFFSET = 23'h30_0000`). 256 KB a
frame, 21 frames a leg, both integrity-checked, compared at the frozen
anchors (MAME 2886 / core 3546).

| region | differing bytes | |
|---|---|---|
| `$900000-$901FFF` | **0 / 8,192** | identical |
| `$902000-$903FFF` | 3,659 / 8,192 | 44.7% |
| `$904000-$907FFF` | 475 / 16,384 | 2.9% |
| `$908000-$90FFFF` | 6,140 / 32,768 | 18.7% |
| **`$910000-$91FFFF`** | **0 / 65,536** | **identical** |
| **`$920000-$92FFFF`** | **0 / 65,536** | **identical** |
| `$930000-$93FFFF` | 0 / 65,536 | zero on both |

**[CORRECTED LATER THE SAME SESSION — READ THE SUBSECTION BELOW. I called
the identical 128 KB "scroll tilemap"; the CPS-A registers say NO LAYER BASE
POINTS THERE at a match anchor, so it is UNCLAIMED VRAM. The agreement is
real and not vacuous — 32,407 nonzero bytes, identical — but it is not what
I said it was, and the regions that DO carry live layers are the ones that
DIFFER.]**

The first video-determining data this project has ever compared, cut at the
time along arbitrary 8/16/32 KB boundaries rather than along the layer map.

**AND `$930000-$93FFFF` IS ZERO ON BOTH** — which matches
`pre_vram_cs <= A[23:18]==6'b1001_00 && A[17:16]!=2'b11`, the RTL decoding
that quarter out. The two implementations agree on the region's SHAPE before
a byte of content is compared.

**THE DIFFERING WINDOW IS `$902000-$90FFFF`, 10,274 bytes = 3.92% of VRAM,
AND IT IS NOT A PHASE ARTEFACT.** Swept across ±20 frames of core dumps
against the fixed MAME anchor the count is FLAT (10,267-10,305), so it is not
the one-frame skew. Both legs are near-static there (a few dozen bytes move
over 20 frames). The word histograms are nearly IDENTICAL — `0x0000`
9,427 vs 9,578, `0x00c0` **4,096 vs 4,096**, `0x0060` 3,575 vs 3,576,
`0x0382` 2,464 vs 2,467 — so it is the same KIND of content in both, differing
in specifics across 1,114 contiguous runs. Where MAME holds `0x0020,0x0000`
pairs the core holds live tile codes (`0x0b91,0x018d`).

### THE VIDEO REGISTERS ARE NOW DOCUMENTED, AND THEY RE-CUT THE RESULT

**The atlas had no entry for layer control at all** — that gap WAS the reason
the VRAM window could not be judged. Closed in `docs/game/atlas/ram.md`,
"CPS-2 VIDEO REGISTERS", from MAME 0288 as authority: CPS-A is at
`$804100` and is **WRITE-ONLY** (so it cannot be captured with a bus dump —
it needs the emulator's `cps_a_regs` SHARE, which is how these were taken),
CPS-B layer control is `+26`, and **every CPS-2 game shares one config**
(`CPS_B_21_DEF`).

**MEASURED AT THE MATCH ANCHOR:** SCROLL1 `$900000`, SCROLL3 `$904000`,
SCROLL2 `$908000`, PALETTE `$90C000`, row-scroll `$90E800`, and
**layer_control `0x2d0e` — scroll1, scroll2 and scroll3 ALL ENABLED.**

**RE-CUTTING THE VRAM DIFF ALONG THOSE BOUNDARIES CHANGES THE READING:**

| region | differing | |
|---|---|---|
| scroll1 `$900000` | 3,659 / 16,384 | 22.3% |
| scroll3 `$904000` | 475 / 16,384 | 2.9% |
| scroll2 `$908000` | 2,901 / 16,384 | 17.7% |
| **palette `$90C000`** | **3,239 / 6,144** | **52.7%** |
| row-scroll `$90E800` | 0 / 2,048 | identical |
| unclaimed `$90D800`, `$90F000`, `$910000+` | 0 / 204,800 | identical, and NOT zero |

**TWO CORRECTIONS TO WHAT I WROTE EARLIER TODAY.**
1. **The identical 128 KB is NOT "scroll tilemap".** No layer base points
   above `$910000` at this frame. It is UNCLAIMED VRAM. The agreement is
   real — 32,407 nonzero bytes, byte-identical — but I named it wrong, and
   naming it "tilemap" made it sound like the layers agreed when the
   opposite is true.
2. **"Neither a defect nor benign" is no longer the right hedge.** The
   differences sit in THREE ENABLED SCROLL LAYERS AND THE PALETTE, with the
   palette the worst at 52.7%. Live surfaces, not dead ones.

**THE LEGACY CONTROL WAS RUN, AND IT SETTLES IT: THE DIFFERENCE IS NOT OURS.**
Same core (`cps2w`), same VRAM region, same comparison — but STOCK `vsavj`
and the LEGACY replay `05_timeout_idle`, with the roster nowhere in sight
(MAME 2146 vs core 2609, the frozen skew 463):

| region | LEGACY (stock) | tenant (WIDE) |
|---|---|---|
| scroll1 | **35.4%** | 22.3% |
| scroll3 | **3.8%** | 2.9% |
| scroll2 | **15.1%** | 17.7% |
| palette | **51.2%** | 52.7% |
| row-scroll | **0%** | 0% |
| unclaimed | **0%** | 0% |

**Same pattern, same magnitudes, on VANILLA CONTENT.** So the palette and
scroll differences are a GENERAL MAME-vs-jtcps2 implementation difference and
say **nothing** about CPS-2 WIDE, the roster, or any slice. The alarm in the
subsection above is answered in the benign direction, and the hedge was the
right call.

**THE USEFUL NEGATIVE RESULT: VRAM IS NOT A VIABLE CROSS-IMPLEMENTATION VIDEO
ORACLE.** Two unrelated implementations legitimately hold different bytes in
the palette and all three scroll tilemaps — the palette by HALF — so
comparing that surface can never distinguish "our port broke something" from
"these are different implementations". Any future attempt at "compare video
against MAME" must use a different surface: rendered frames, the OBJ list, or
the palette AFTER the hardware's own conversion. **This closes off an
approach that looked promising, which is worth more than the measurement
was.**

**AND ONE POSITIVE SIGNAL INSIDE IT:** row-scroll and every unclaimed region
are BYTE-IDENTICAL in BOTH runs — 204,800 bytes, non-zero, across two
different romsets and two different replays. So the VRAM transfer and the
dump path themselves are sound; the differences are real content
differences, not an artefact of how either side is captured.

**WHAT STILL STOPS IT BEING CALLED A DEFECT, stated so the next session does
not over-swing the other way.** Two things are unmeasured: whether the
differing bytes fall in the VISIBLE portion of each tilemap (the layers are
larger than the screen, and the scroll X/Y registers select the window), and
**whether this difference is specific to our content at all.** The obvious
control has not been run: **the same VRAM comparison on a LEGACY replay with
the stock romset.** If MAME and jtcps2 differ there too, this is a general
implementation difference and says nothing about the roster. That control is
the next step and it is one ~60-minute sim leg.

**NOT CALLED A DEFECT AND NOT CALLED BENIGN.** Whether stale or differing
tilemap content is VISIBLE depends on the layer-enable and scroll-base
registers, which VRAM does not carry and **which this project has never
documented** — `grep` for layer control across the atlas and
`engine_internals.md` returns nothing. That is the gap to close before the
window can be judged, and it is now the concrete next step for the video
question rather than "compare frames somehow".
**[RESOLVED LATER THE SAME SESSION — both halves of this paragraph are
answered by the two subsections immediately below, and it is kept only as
the reasoning that got there. The registers ARE now documented
(`atlas/ram.md`, "CPS-2 VIDEO REGISTERS"): at the match anchor
`layer_control 0x2d0e`, all three scroll layers ENABLED. And the control
this paragraph called for WAS run: the difference is NOT ours — stock
`vsavj` on a legacy replay reproduces the same pattern and magnitudes, so
VRAM is not a viable cross-implementation video oracle at all. Do not act
on "the gap to close" above; it is closed. Marked 14z-109.]**

### THE QSOUND EXTENSION IS FETCHED ON THE CORE — the last zero-coverage subsystem

**Stock CPS-2 cannot address these banks at all**: `qsnd_addr[22:16] <=
dsp_ab[6:0]` keeps seven bank bits, so bank `0x8N` plays as `0x0N`. Reaching
them needs slice **D1**'s sample-bank width fix AND slice **D2**'s QSound
split across two SDRAM banks. Until now nothing had ever fetched one on an
FPGA implementation.

`108_tenant_voice.rpl` (36's wheel walk to the tenant, then walk-forward and
mash so the tenant throws attacks that CONNECT), 4,400 frames, `cps2w` + the
WIDE romset:

| probe | window | positive | control (profile bit CLEAR) |
|---|---|---|---|
| **QSound HIGH — the extension** | ba0 `0x6E0000`, 1 MB | **210,180 reads / 76 distinct / first frame 3783** | **0** |
| QSound LOW (liveness) | ba1 `0`, 8 MB | 86,746,380 | **54,113,994** |
| bank 3 (liveness) | ba3 | 171,296,680 | 105,056,248 |

**The addresses are `0x830AA0-0x83FFFE` — DSP bank `0x83`**, inside the
ledger's extension range `0x80-0x8E` and overlapping 8 of its 58 samples. The
first read lands **224 frames INTO the match, during the mash** — where an
attack voice belongs, not at boot.

**THE CONTROL IS WHAT MAKES THE ZERO MEAN SOMETHING.** With `wide_en` clear
the core still issues **54 million** QSound LOW reads — the DSP is
demonstrably streaming samples — and **zero** into the extension. So the zero
is about the PROFILE, not about a silent DSP or a dead probe.

**AND IT CONFIRMS THE `SLOT5_AW=20` TRUNCATION IS SAFE IN PRACTICE, not just
on paper.** Quartus warning 10230 flags `pcmh_addr = pcm_addr[PCM_AW-1:0]`
narrowing 23 bits to 20; that is the window MASK, lossless only while the
extension stays inside 1 MB. **Every address observed has
`pcm_addr[22:20] == 0`**, which is exactly the condition, and the gate
asserts it rather than trusting the arithmetic.

**THE RIG WAS CONFIRMED ON MAME FIRST**, because `36_pick_tenant_cell`
presses nothing after the match starts and a tenant that never attacks would
have produced a meaningless zero — the same ambiguity that cost 14z-107 (12)
its obj-bank-4 measurement. On MAME the new replay drives P2's HP from
`0x120` to `0x00EC`. **Two instrument notes recorded in the replay header:
`p1_attack_id` at `+0x0A` reads 0 for the whole window even at PER-FRAME
sampling, so it is not the indicator to use — `anim_ptr` and the opponent's
HP are; and a 20-frame stride aliases the attacks away entirely and makes a
working rig look dead.** My first pass printed "WEAK RIG" from exactly that
aliased read while its own HP figures said otherwise.

**CAPTURED AS A GATE**: `tests/test_mister_qsound_ext.sh` (emulator tier, two
~75 min legs). It derives the window from the RTL (`PCMH_OFFSET`, `SLOT5_AW`,
and which `u_bankN` carries `pcmh_cs`) rather than hard-coding it, and
**PROVEN ABLE TO FAIL on four fabricated defects**: a control leg that leaks,
a positive leg reading zero, an address outside `0x80-0x8E`, and a dead
liveness probe.

### THE CORE SYNTHESISES AND FITS — BUT TIMING IS SEED-DEPENDENT AND TWO SEEDS IN FOUR MISS

> **[THE HEADLINE BELOW WAS WRITTEN FROM A SINGLE SEED AND IS SUPERSEDED.
> The seed sweep the maintainer approved the same day found that `cps2w`
> does NOT reliably close timing. The corrected verdict is the subsection
> "THE SEED SWEEP INVERTS THE TIMING HALF" further down; FIT is unaffected
> and stands. The single-seed measurement was not WRONG — it is a true
> report of that draw — but read alone it overstates the design's health,
> and the reason it could is `jtseed`, below.]**

**FIT is answered and unambiguous; TIMING is not.** Run on a Windows box by
a peer Claude session from `docs/project/quartus_brief.md`. The
original single-seed reading was taken at pin `7b9a0d2d`, Quartus Prime 20.1.1 Lite
via Jotego's `jotego/jtcore20x` image, device **Cyclone V 5CSEBA6U23I7**,
target mister. **`cps2` was built FIRST as the reference leg**, so every
figure below is an attribution and not just a number.

| resource | `cps2` (control) | `cps2w` | delta |
|---|---|---|---|
| ALMs | 18,258 / 41,910 (44%) | 18,464 / 41,910 (44%) | **+206 (+1.1%)** |
| Registers | 27,860 | 28,426 | +566 |
| Block memory bits | 1,095,825 / 5,662,720 (19%) | 1,097,873 (19%) | +2,048 |
| RAM blocks | 156 / 553 (28%) | 156 / 553 (28%) | 0 |
| DSP blocks | 38 / 112 (34%) | 38 / 112 (34%) | 0 |
| PLLs | 3 / 6 | 3 / 6 | 0 |

**The entire CPS-2 WIDE feature set costs 206 ALMs and 2,048 memory bits.**
Nothing overflowed; nothing is close to overflowing.

**TIMING, and this is the number to carry forward.** SDRAM 96 MHz domain,
setup, slow corner:

| | slack | Fmax |
|---|---|---|
| `cps2` (control) | **+0.144 ns** | 97.35 MHz |
| `cps2w` | **+0.066 ns** | 96.62 MHz |

Every other domain positive on both cores; TNS 0.000 for every domain and
every analysis type; hold/recovery/removal/min-pulse-width all positive;
**ZERO failing paths** (both `.sta.rpt` grepped for negative slack and for
"timing requirements not met"); fitter 0 errors, 0 critical warnings.

**THE HONEST FRAMING, IN THE MEASURING SESSION'S OWN WORDS: the SDRAM domain
is the critical path in BOTH cores, and WIDE eats 0.078 ns of the control's
0.144 ns — a little over half the margin. That is a PASS, NOT A WARNING. But
it is a thin pass on the domain that matters, and it is the number to
re-measure after any future slice.** `cps2` at +0.144 ns shows the margin was
already modest before WIDE touched it.

**CORNER, corrected by the measuring session rather than substituted
silently:** the brief asked for 1100 mV / 85 C. That corner does not exist for
this device — `5CSEBA6U23I7` is INDUSTRIAL grade, so Quartus's slow corner is
1100 mV / **100 C**, which is what the numbers above are. **More conservative
than what was asked for, not less.**

**WARNING (10230) at `jtcps1_sdram.v:284`, flagged by the measuring session
and ANSWERED here:** `assign pcmh_addr = pcm_addr[PCM_AW-1:0]` narrows 23
bits to a 20-bit target. **Benign and intentional.** `SLOT5_AW` is 20 because
the QSound HIGH window IS 1 MB (`PCMH_OFFSET = 23'h37_0000`), and
`mister_map.md:448` covers DSP sample banks `0x80-0x8F` of which `0x80-0x8E`
are downloaded — `0xF0000` B = 15 banks x 64 KB = 983,040 B against
1,048,576 B. **The truncation IS the mask**, the `lint_off WIDTH` pragma is
honest, and the arithmetic closes with exactly ONE spare bank. The constraint
it encodes — sample banks above `0x8F` alias silently — is the same
thin-margin story as the rest of the placement.

### THE SEED SWEEP INVERTS THE TIMING HALF — TWO SEEDS IN FOUR MISS

**Commissioned because the attribution showed a five-path cluster at the
limit on a term that is ROUTING, and routing is what seeds vary. It was the
right call: a single build would never have shown this.**

| core | seed | jtframe gate | SDRAM 96 MHz slack | TNS | ALMs |
|---|---|---|---|---|---|
| `cps2w` | 18269 (base) | **PASS** | +0.066 | 0.000 | 18,464 |
| `cps2w` | 1001 | **PASS** | +0.067 | 0.000 | 18,432 |
| `cps2w` | 2002 | **FAIL** | **-0.110** | -0.260 | 18,436 |
| `cps2w` | 3003 | **FAIL** | **-0.545** | -1.026 | 18,428 |
| `cps2` | 21287 (base) | PASS | +0.144 | 0.000 | 18,258 |
| `cps2` | 4004 | PASS | +0.431 | 0.000 | 18,226 |

**EXTENDED TO 17 BUILDS — `cps2w` n=12, `cps2` n=5 — and the failing
fraction is now PINNED DOWN rather than merely demonstrated:**

    cps2w (n=12):  -0.545 -0.313 -0.110 -0.039 | 0.008 0.009 0.066 0.067
                                                 0.147 0.167 0.202 0.396
    cps2  (n=5) :                                0.144 0.287 0.431 0.511 0.665
                                               ^ zero

    failed   cps2w 4/12          cps2 0/5
    median   cps2w +0.038        cps2 +0.431
    range    cps2w 0.941 ns      cps2 0.521 ns

**THREE COMPARISONS CARRY IT.** The BEST of twelve `cps2w` seeds (+0.396)
is worse than the MEDIAN of five `cps2` seeds (+0.431); `cps2`'s WORST
seed (+0.144) beats EIGHT of twelve `cps2w` seeds; and the medians differ
by more than an order of magnitude. **And two of the eight `cps2w` passes
are +0.008 and +0.009 — a quarter of the passing placements clear the gate
by under 10 PICOSECONDS, which is a pass in the report and not margin in
any engineering sense.**

Observed failure rate 4/12 = 33%, 95% CI roughly **14%-61%** at this n, so
the honest phrasing is "commonly, between about one seed in seven and
three in five", NOT "exactly a third". The DIRECTION is not in doubt.

**THE ATTRIBUTION HOLDS AT n=12, and this is a verified negative:** across
all twelve `cps2w` seeds **the number of failing paths OUTSIDE
`jtframe_sdram64` is ZERO** — checked by grepping every negative-slack row
of every seed's path report, not by sampling. The worst path is a
different register on nearly every seed (`post_act`, `in_busy`, `br`,
`st[0]`, `actd`, `rfsh|help`) landing on `sdram_a[7]`, `[8]` or `[11]`.

**THESE ARE REAL TIMING FAILURES, NOT CRASHES.** Quartus reported "Full
Compilation was successful, 0 errors" on both failing seeds — the fitter
placed and routed fine. **The FAIL verdict is jtframe's OWN timing gate**,
the same one that prints PASS on the passing seeds. It is jtcores'
pass/fail criterion, not an interpretation of a slack number.

**THE CLUSTER RESHUFFLES; IT DOES NOT MOVE AS A BODY.** Different source
register AND different destination pin every seed (`u_bank1|post_act` ->
`sdram_a[11]`; `u_prog|actd` -> `sdram_a[7]`; `u_bank2|post_act` ->
`sdram_a[8]`; `u_bank1|st[0]~DUPLICATE` -> `sdram_a[11]`). Every failing
path is still inside `jtframe_sdram64`, terminating at an SDRAM address
pin. **What is marginal is not one path but the SDRAM controller's
ADDRESS-GENERATION CONE AS A WHOLE.** WIDE loads that cone enough to lose
the seed lottery; the control keeps enough margin to absorb the same
variance.

**AND THE REASON A SINGLE BUILD LOOKED HEALTHY: `jtseed` RETRIES UNTIL IT
PASSES.** `xjtcore.sh` calls `jtseed 4`, which loops `jtcore --seed
$RANDOM` and **BREAKS ON FIRST SUCCESS**. The +0.066 baseline was such a
draw.

**BE PRECISE ABOUT WHAT THAT HIDES — the first statement of this, mine and
the measuring session's, was stronger than the evidence and was sharpened
at n=12.** It does NOT mean the flow ships failing bitstreams: at a 33%
per-seed failure rate the chance all four draws fail is ~1%, so **roughly
99% of invocations produce a gate-passing `.rbf`**. What it hides is
**FRAGILITY, not correctness** — the artifact is a CHERRY-PICKED
PLACEMENT, the first of up to four random draws that closed. **A green run
certifies "one placement was found that closes"; it never certifies "this
design closes with margin".** Only the second is a basis for building on.

**THE VERDICT, not forced into the brief's four boxes because it does not
fit one.** FIT is unambiguous — `cps2w` FITS at 44% ALMs, and (d) is firmly
excluded. TIMING is seed-dependent: (a) on passing seeds, (c) on failing
ones. **It is NEVER (b)** — the control closed on every seed tried, so
there is no inherited failure to attribute this to. The failure IS
attributable to the fork in the sense that the control does not exhibit it,
but it is **NOT located in WIDE's own logic**: every failing path is in
shared jtframe infrastructure the fork does not touch. With n=4 no pass
RATE is quoted; 2-of-4 is not "50%" at this sample size. **What is robust,
from two independent failures: `cps2w` does not reliably close timing at
96 MHz on this toolchain, and `cps2` does.**

**A HAZARD CAUGHT AND FIXED, and it bears on the field test.** **A FAILING
SEED STILL EMITS AN `.rbf`** — Quartus completes and writes a bitstream
even when jtframe's gate says FAIL. The sweep OVERWROTE
`release/mister/jtcps2w.rbf` with seed 3003's output, the worst-failing
seed at -0.545 ns. Anyone pulling that path for an SD card in that window
would have flashed a build that misses timing. The baselines were archived
before the sweep, restored afterwards, and re-hashed to the published
values (`46fc74af…` / `43b94cb1…`); the sweep bitstreams are preserved, not
discarded. **VERIFY THE HASH BEFORE FLASHING ANYTHING FROM THAT TREE.**

**CONSTRAINTS HELD:** only `--seed` varied, `set_global_assignment -name
seed <S>` confirmed in the `.qsf` each run, no fitter/physical-synthesis/
optimisation-effort changes, and **no failing seed was re-run hoping for a
pass**. HEAD `7b9a0d2d`, 0 tracked and 0 RTL files modified.

**WHAT IT MEANS, stated plainly.** It does NOT block shipping by itself: we
distribute a PREBUILT `.rbf`, and the baseline bitstream is a passing draw.
It DOES mean the +0.066 ns is not real headroom — **a future slice cannot
assume it**, any rebuild is a lottery, and a jtframe uprev or a Quartus
version change could move the design from mostly-passing to mostly-failing.
**Whether to spend margin back (pipelining the SDRAM address path, reducing
the load WIDE puts on that cone) is a DESIGN decision under Rule 1 v2 and
is the maintainer's**, not something to fix by seed-hunting.

**WHERE THE 0.078 ns WENT — ATTRIBUTED, AND THE ANSWER IS THE REASSURING
ONE.** Obtained by re-running `quartus_sta` with `report_timing -setup
-npaths 5 -detail full_path` against the EXISTING fitted netlist (6 s a core,
no re-synthesis, no re-fit, the same placement the numbers describe) — the
`.sta.rpt` itself carries only per-clock summaries and no path listing.

| # | `cps2` (control) | | `cps2w` | |
|---|---|---|---|---|
| 1 | **+0.144** | `all_dbusy` -> `sdram_a[11]` | **+0.066** | `u_bank1\|post_act` -> `sdram_a[11]` |
| 2 | +0.418 | `u_bank3\|in_busy~DUP` -> `sdram_a[7]` | +0.079 | `u_rfsh\|rfshing` -> `sdram_a[11]` |
| 3 | +0.427 | `all_dbusy` -> `sdram_a[11]~D1` | +0.103 | `u_bank0\|in_busy` -> `sdram_a[11]` |
| 4 | +0.436 | `all_dbusy` -> `sdram_a[11]` | +0.112 | `u_bank2\|post_act` -> `sdram_a[11]` |
| 5 | +0.449 | `u_bank1\|in_busy` -> `sdram_a[11]` | +0.131 | `u_bank3\|in_busy` -> `sdram_a[11]` |

**THE COST IS NOT IN ANY SLICE.** All ten paths live in `jtframe_sdram64` —
jtframe's own SDRAM controller, SHARED with the control and UNTOUCHED by the
fork. Grepping the table for `jtcps2w_obj_bank`, `jtcps2_main`,
`jtcps2_decrypt`, `jtcps2w_profile` or `jtcps2w_qsnd_bank` returns **zero
matches**, and path #1's full node chain traverses only `jtframe_mister` ->
`jtframe_board` -> `jtframe_sdram64` -> `jtframe_sdram64_bank`. **D2's
seven-slot arbiter, D3's third bank bit and D5's decrypt stage are NOT on the
critical path.**

Worst-path structure, control -> `cps2w`: **same destination pin, same
DDIOOUTCELL, same site** (`sdram_a[11]` via `DDIOOUTCELL_X62_Y0_N10`); data
delay 10.658 -> 10.758 ns (+0.100); combinational levels 6 -> 7 (**+1**); and
the **dominant term is UNCHANGED at ~4.22 ns** — a single interconnect hop
from the fabric (X46,Y26) to the I/O column (X62,Y0), **39% of the whole data
path, and it is routing distance to a pin rather than logic.** WIDE added one
level to the bank-arbitration cloud and did not touch what actually dominates.

**AND THE DISTRIBUTION MATTERS MORE THAN THE SCALAR, which is the finding:**

    cps2 :  0.144 | 0.418  0.427  0.436  0.449   one outlier, then a 0.27 ns gap
    cps2w:  0.066   0.079  0.103  0.112  0.131   FIVE paths inside 0.065 ns

In the control the margin is held by ONE path with room behind it. In `cps2w`
five bank-arbitration paths sit in a tight cluster at the limit. **WIDE did
not shift one path; it pulled a whole front down together.** The verdict is
unchanged — all positive, TNS 0.000 — but the RISK PROFILE is not: the
dominant delay term is routing to a pin, routing is exactly what varies
between fitter seeds, and a five-path cluster has five chances to go negative
where a lone outlier has one. **A single-seed +0.066 is least informative
precisely in this configuration.** A FITTER SEED SWEEP is therefore the
natural follow-up; it costs real build hours and is the maintainer's call.

**THE ARTIFACTS, AND THE SEED BEHIND THEM.** `release/mister/jtcps2w.rbf`, **3,111,944 B**, sha256
`46fc74afb6a6c5c6143db64d9c9f5d2e298cdd5c79449bb0370fbe9c2b3df66f`, built from **SEED 18269**, slack +0.066 ns,
gate PASS — jtseed's own RANDOM draw during the original run, not a chosen
seed, and **it IS the +0.066 row of the n=12 table**. So the artifact a field
test would use is a PASSING DRAW FROM THE DISTRIBUTION IN WHICH A THIRD
FAIL — not a separate or privileged build. Rebuild:
`jtcore cps2w -mister --nodbg --seed 18269`.
**BUT THE HASH WILL NOT REPRODUCE UNLESS IT IS THE SAME CALENDAR DAY.**
`modules/jtframe/target/mister/sys/build_id.tcl` compiles a `%y%m%d`
datestamp into the design (this bitstream carries `260825`; verified in our
own checkout, day granularity, rewritten only when the value changes). Same
seed reproduces the PLACEMENT and the TIMING exactly and a DIFFERENT hash.
**THE HASH IDENTIFIES THE ARTIFACT; THE SEED IDENTIFIES THE RESULT.** Never
read a hash mismatch as a failed reproduction — check the seed and the
reported slack. Control: control
`release/mister/jtcps2.rbf`, 3,162,828 B, sha256
`43b94cb1e4ca59606912ad638a7b1f45370c897f08f2d1100f10efcf0df0f15f`. Each
`release/` copy hashes identically to the fitter output under
`cores/<core>/mister/output_files/`, so `release/` is a true copy and not a
re-emit. **NOT transferred anywhere**; they live on the build machine. An
`.rbf` carries no ROM content — it is our own GPL-3.0 core — so unlike
everything else in this project it is an artifact that CAN be moved, and it
is what a field test needs on the SD card.

**PROVENANCE AND DISCLOSURE, recorded because it belongs in the record even
though it does not affect the answer.** The measuring session verified the
D0-D5 evidence independently rather than taking it on trust (all nine `cps2w`
commits, 13 `.v` files, all four characteristic expressions at the cited
lines, `README:35` stale as described). It also disclosed unprompted that it
touched the tree mid-run: an over-broad `rm -rf` while clearing master-only
submodule artifacts deleted the tracked `modules/jt680x` (restored with
`git checkout --`), and `modules/jttms` had staged deletions after a killed
clone (reset to `fabcbc36`). Both repaired and verified before the builds
ran; final state HEAD `7b9a0d2d`, 0 tracked files modified, 0 RTL files
modified, nothing pushed. **BETAKEY is NOT needed** (the flow warns and
assigns a random one). Full report on that machine at
`C:\Claude\VampireSaved\quartus_report.md`.

**WHAT THIS DOES AND DOES NOT SETTLE.** It settles BUILDABILITY: the design
fits a Cyclone V with room and meets its clock. It does NOT settle hardware —
nothing has been loaded onto a DE10-Nano, no MRA has been run on real
silicon, and no analog output has been seen. An `.rbf` existing is not a
field test.

### A STALE README IN THE PUBLIC FORK, FOUND BY THE QUARTUS SESSION

`emu/jtcores` `cores/cps2w/README.md` at pin `7b9a0d2d` still says
**"Status: slice D1 — the QSound sample-bank width"** and lists the
placement, the object promote and the 68k PRG window as "slices D2-D4 and
not here yet". Its file table lists FIVE `hdl/` files; the tree holds
THIRTEEN. It was written at `4840df8a` (D1) and never updated after
`0df6f000` (D2).

**Found by the Windows Quartus session, which stopped and asked before
building rather than trusting either document.** That is the right
instinct and the reason it matters: a synthesis report reading "slice D1"
would have been filed as a green light for a design four slices larger
than the one measured.

Verified against the tree, not from memory: five slice commits sit above D1
on `cores/cps2w`, and each slice's characteristic expression is present
(`jtcps1_sdram.v:221-222` the group-C offsets; `jtcps2w_obj_bank.v:64` the
promote; `jtcps2_main.v:240/219/116` the decode, the `one_wait` boundary and
the widened `rom_addr`; `jtcps2_decrypt.v:75` `rng_eff`). Stronger still,
this same pin demonstrably RAN the full design in the tenant-match
measurement above, which requires D2, D3, D4 and D5 jointly.

**NOT FIXED IN THIS SESSION, deliberately: a README commit moves the fork
pin out from under a build in flight.** It is queued for after the Quartus
numbers land. **This is the retraction rule pointing at our own public
artifact** — the fork's README is a header a stranger reads first, and it
is confidently wrong.

### RITUAL

- **SCRATCH HYGIENE: the 14z-107 direction evidence is SWEPT, 503 MB.**
  `docs/NEXT_SESSION.md` at the 14z-107 close said to keep
  `/tmp/vs14z107_*` — leg E's 811 work-RAM dumps, the MAME comparison legs
  and the two rendered frames — **until the direction fix was verified**.
  It is verified (all four directions match MAME post-fix), and the finding
  those dumps supported has been SUPERSEDED by the four-direction
  measurement, which has its own evidence. Swept after confirming the two
  rendered frames are committed under `docs/project/images/` (they are, and
  `git ls-files` says so — the durable copies, per rule 7 the dumps
  themselves could never be). `/tmp/vampire-saved-jtsim-14z108` was left
  alone: it is the live simulation clone.
- **THE ROLLOVER EXECUTED, exactly as the 14z-107 CLOSE (final) specified
  it**: the 14z-107 sub-entries **(1)-(9)**, nine sections and 1,582 lines,
  moved BYTE-VERBATIM to the top of `STATE_HISTORY.md`'s body. Verified
  lossless (identical sha256 in the archive; no rolled header remains here).
  **STATE.md 261,112 -> 160,634 B** — the first time since the split that it
  is near the ~150 KB the rule names. **First time a group's SUB-ENTRIES have
  rolled while the group stays live**, which the rule does not contemplate:
  it speaks of whole groups and THE LEDGER carries one line per group, so
  nothing was added to the ledger and a pointer paragraph names all nine.

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

- Session 14z-107 CLOSE (final) — THE WIDE ROMSET BOOTS ON THE CORE, draws our select screen and fetches our wheel art: six RTL slices D0-D5 (the MRA, the runtime profile gate + QSound width, the SDRAM placement, the CPS-2 Turbo object promote, the 6 MB program window, and D5 THE DECRYPTION RANGE — the CPS-2 key's encrypted-opcode range word is stored COMPLEMENTED and jtcps2_dec_ctrl reads it straight, which no stock CPS-2 game could ever expose); 105 distinct tenant tile codes out of obj bank 5 with the control leg at zero; bank 0's traffic under the redirect ANSWERED and GO; both stock legs green. **The arc's headline was methodological: SEVEN instrument and harness defects found in this lane, every one of which would have read as an RTL fault, with D5 the counter-example where the RTL genuinely was at fault.**  [+3 more entries]  [rolled 14z-108 close]
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

- **~~THE TIMING-MARGIN RESPONSE~~ DECIDED (maintainer, 2026-08-25).**
  `cps2w` fails 4 of 12 fitter seeds (14z-108). Options were laid out A-E.
  **RULED: A + B, with C IN RESERVE. D is ACCEPTABLE. E is OPPOSED unless
  there is no better choice.**
  * **A — do nothing to the RTL.** We distribute a PREBUILT `.rbf`, so the
    fragility is ours and not the users'.
  * **B — PIN THE SEED AT RELEASE.** Every shipped bitstream is built from a
    NAMED seed with its slack and sha256 recorded and verified, never from
    an `xjtcore.sh` random draw. The current baseline is **seed 18269,
    +0.066 ns, sha256 `46fc74af…`**. Costs nothing and converts "we got a
    lucky draw" into "we know which draw, and we check it".
  * **C — shed load on the SDRAM address cone** (bank 0 carries SEVEN slots
    since D2; the rejected 14z-107 alternative was moving the Z80 out).
    HELD IN RESERVE: it is the only fix that stays inside Rule 1 v2 and
    touches no shared infrastructure, but it would invalidate the bank-1
    bandwidth measurement, so it is not to be spent on headroom we do not
    currently need. **Revisit BEFORE the next RTL slice, not after.**
  * **D — pipeline the SDRAM address path.** ACCEPTABLE if C is not enough.
    Note it means overriding jtframe's shared controller in `cores/cps2w`.
  * **E — lower the SDRAM clock.** OPPOSED unless nothing else works: bank 0
    already peaks at 43.9% of its 96 MHz ceiling, so the clock is buying
    headroom we are using.

- **~~MiSTer PACKAGING: which MRA is MAIN, and how a release carries both
  `vsav.zip` flavours~~ DECIDED (maintainer, 2026-08-25): OPTION A, a
  WIDE-ONLY RELEASE, with option B as the eventual target.**
  **The collision, named exactly (14z-108):** the four ported-art members
  are `vm3.13m/.15m/.17m/.19m`, and they live in **`vsav.zip`, not
  `vsavjw.zip`**. So the WIDE MRA needs a PATCHED `vsav.zip` while every
  stock MRA needs the PRISTINE one — same filename, one `games/mame/`
  folder — and jtframe resolves members **by CRC32 alone**, so the wrong one
  is silently filled rather than refused.
  **Ruled: ship the WIDE MRA only.** The maintainer's reasoning, recorded
  because it settles the "which MRA is main" half too: **Jotego's own
  `jtcps2` core already runs vanilla**, so our core does not need to, and
  the stock regional MRAs are a development reference leg rather than a user
  feature. The generator currently makes the **Euro** set the main MRA and
  buries the WIDE entry in `_alternatives/`, which is backwards for a core
  whose purpose is the roster.
  **Option B stays the target shape "in time"**: move those four members
  INTO `vsavjw.zip` so `vsav.zip` can stay pristine and a user's existing
  romset folder works untouched. Not done now because it is a build-pipeline
  change touching the hash-shadowing class that cost two sessions in
  14z-60z/61, and it must not sit between the maintainer and a field test.

- **~~THE FIELD TEST~~ SCHEDULED (maintainer, 2026-08-25): "tonight unless
  I struggle building".** Bundle assembled and verified OUTSIDE the repo at
  `../mister_fieldtest_14z108/` — the WIDE MRA, `vsavjw.zip`, the PATCHED
  `vsav.zip`, `qsound.zip`, and a README. **All 31 CRC-identified parts the
  MRA declares were verified to resolve from those three zips**, because an
  unresolved part is filled with `0xFF` rather than refused. The `.rbf` is
  NOT in the bundle — it comes from the Windows box and its sha256 must be
  checked first, since a timing-FAILING seed emits a bitstream
  indistinguishable from a good one.


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
