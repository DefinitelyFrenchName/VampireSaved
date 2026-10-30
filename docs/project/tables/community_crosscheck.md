# Community cross-check — our derived frame data vs the community sources

**GENERATED** by `tools/crosscheck_framedata.py` from `tools/vanilla_frames.py`'s
derivation and the maintainer's workbook. Do not hand-edit; regenerate.
Gate: `tests/test_community_crosscheck.sh`.

**THIS IS THE VERDICT-ONLY PAGE.** Per-move frame data — ours and the workbook's
alike — stays out of the public tree (maintainer-ruled 2026-08-31, STATE 14z-126:
the tree ships the READERS and the VERDICTS; the numbers are regenerated from the
romsets). The full comparison, move by move, is `../charpages/framedata/
community_crosscheck_full.md`, written above the working tree by
`tools/framedata_pages.sh` for anyone holding the reference dumps and the workbook.

## The rule this page applies

Maintainer, 2026-08-31, verbatim in substance: *"measurement is king, not a
source that we don't know how it was measured; however, community information
is precious: if it aligns perfectly or with a constant offset, then we know the
measure is good; if we find an inconsistent pattern, then we must search whether
the measurement is correctly done or not."*

| verdict | meaning | what it obliges |
|---|---|---|
| EXACT | every joined move agrees | nothing; both measurements are corroborated |
| CONSTANT OFFSET | every delta is the same non-zero k | a COUNTING CONVENTION difference — name it, change neither side |
| CONSTANT RATIO | every quotient is the same r | a UNITS difference — same evidential value as an offset |
| INCONSISTENT | neither | somebody's measurement is wrong; **re-measure OURS in-emulator first** |
| UNCOMPARABLE | the sheet cell is prose, or the quantities differ structurally | state why, compare nothing |

## The sources (both OUTSIDE the tree, cited not committed)

- `../community/vsav-framedata.xlsx` — 15 sheets, one per vanilla character,
  820 data rows, every one with an input (counted 14z-194; the "730" this line carried
  from 14z-125 was never a count: the reader then and now returns 820 from the unchanged
  workbook). Read by `tools/xlsx_read.py` (stdlib only; validated cell for
  cell against `openpyxl` — 28,234 cells, the only 4 differences being the
  date-corrupted `VI!U43:U46` `Invuln` cells, a column this page does not compare).
- `../community/mizuumi_reverse_engineering.txt` — the mizuumi wiki's Reverse
  Engineering page (`oldid 416342`, 2025-07-31). It carries **no per-move frame
  data** — it is a RAM/ROM map — so it is not a source for this page. Its
  player-struct table is compared against `atlas/ram.md` separately (#118: 14z-189 and 14z-194
  measured its candidates into the atlas, each name adopted only as "consistent with").

## What is compared, and what is not

| sheet column | ours | source of ours |
|---|---|---|
| `startup` | `startup` | frames before the first active frame |
| `active` | `active` | frames the attack box exists |
| `recovery` | `recovery` | frames after the last active frame |
| `white damage` | `white` | the attack record's +9 white power CLASS (bits 0-4; bits 5-7 are flags, #241) |
| `guage hit` | `gauge_hit` | the attack record's +0x14 attacker meter gain |
| `red damage` | `red` | the attack record's +8 real power class PLUS its +9 white class — the move's total |

Not compared, because nothing in the tree derives them yet: `on hit`,
`renda on hit`, `on block`, `renda on block`, `throw tech`, `cancel`, `guard`,
`hit reaction`, `Invuln`, `type`, `gauge whiff`, `guage block`. Frame advantage
needs the victim's stun length beside the attacker's recovery; `tests/test_reactions.sh`
measures the raw material for the tenants only.

## The join is MEASURED, not assumed — and the first model was wrong

Which anim chain a standing normal enters is **per character and per button**,
because the engine picks by PROXIMITY. It was measured on vanilla vsavj by
`tools/vanilla_join_rig.py`: each button performed at a far pin and again after a
150-frame walk-in, the verdict read off the game's own node pointer `+0x1C` and
mapped onto the chain graph. All 15 characters, 180 rows, frozen in
`tests/expected/vanilla_normal_slots.tsv`, gated by `tests/test_vanilla_frame_join.sh`.

**A fixed layout was tried first and the measurement overturned it.** The model
was "even slot = close normal, odd slot = far normal" for everyone, inferred by
fitting our numbers against this very workbook — which is circular, and wrong:

- **AN, BI, JE, QB, ZA** enter the same chain at both distances on every button:
  no proximity variants at all. Zabel is why it mattered — the fixed model handed
  him the odd slots, which are his `6`-prefixed COMMAND normals, and he came out
  INCONSISTENT on all five columns. On the measured join he is clean on all five.
- **DE, MO, FE, LE, LI** take odd at far / even at near on every button, LP included;
  **SA** the same, his HP a knife edge at the rig's near separation (0x04 at 59 px,
  0x05 at 60); **GA, VI** have no close LP (`0x00` at both), GA none for MK either;
  **BU** has no close variant for HP, MK or HK, **AU** none for HP. (Until 14z-183,
  GitHub #134, this read "LP is `0x01` at both distances": the rig's first event, LP,
  was pressed at mid range because the round intro ate its walk-in.)

The **crouching** (`0x0c-0x11`) slots are the layout measured on the three TENANTS by
`tools/name_moves.py` (gate `tests/test_move_naming.sh`), carried over and **not**
re-measured per vanilla character — a stated bound, not a claim.

**The jumping slots are TWO sets, and the workbook's row is the forward one (measured
14z-145).** A NEUTRAL jump attack enters `0x12-0x17` and a FORWARD jump attack
`0x18-0x1D`, measured on all 15 characters by the same rig with the jump direction as
the variable (`tests/test_vanilla_aerial_join.sh`, `tests/expected/vanilla_aerial_slots.tsv`).
Where a character has no forward variant the `0x18-0x1D` entry aliases the neutral
chain and the game enters the same address (VI on everything but HP, BU on LP/LK/HK,
LI on HP). The workbook keeps ONE row per aerial button (Lilith's `J.HK` twice); WHICH
variant a row documents is a fact about the workbook, taken from mizuumi's move lists —
which name the pair `8J.x` / `9J.x` — and never from which chain's numbers fit better
(`FORWARD_ROWS` in the comparator: BI LP/HP, BU MP/HP/MK/HK, FE LK/HK, VI HP, LI's second
`J.HK`; Bishamon's `J.HP8` is his neutral HP by its own name; Zabel's `J.x` rows are his
neutral chain). The seven aerial outliers of 14z-125 were exactly the split moves joined to
the wrong variant. **The second set is not the same thing on every character:** a third
direction, neutral jump then D+button, showed that Zabel's `0x18-0x1D` are his D+button
aerials (the workbook's `J.2LP`..`J.2HK`, now joined by name), Aulbath's `J.2HK` is `a2:0x51`,
and Anakaris's D+button leaves his hover into `a:0x36` on every button. Anakaris has no
neutral-jump attacks at all: his neutral jump is a hover (`a:0x12`) that takes no normal.

**The command normals are measured too (14z-189, GitHub #117).** The same rig performs
each button with toward held (`6x`) and with down-toward held (`3x`) at the far pin, out
of throw range (`tests/test_vanilla_command_join.sh`, `tests/expected/vanilla_command_slots.tsv`,
180 rows). A `6x` entering a chain other than the far standing one, or a `3x` one other
than the crouching one, names that chain. The measurement found **19 such chains — 18
`6x` and Bulleta's `3HK` — and they are exactly the workbook's 19 `6x`/`3x` rows**, by
character and button: BU `6MP`/`6MK`/`3HK`, GA `6MK`, ZA all six (his odd slots,
`0x01`-`0x0b`), AN `6MK`, BI all six, LE `6MP`/`6HP`. On the other 72 `6x` and 89 `3x`
presses the game enters the plain far or crouching normal. Bulleta's `3HK` joins by name
and compares nothing: the workbook types it `projectile` (as it types her `5HK`), and the
chain the rig recorded carries no attack window in its records — the hit is the MINE the
move spawns, confirmed by the maintainer (2026-10-05, GitHub #216): *"the hit is the mine
spawned, it is technically a trap/projectile with a disjointed hitbox from the character's
sprite"*. The specials, supers, EX/ES moves, throws, pursuits and guard cancels are joined by rigs of their own
and classified in their own sections below (#229), each frozen by its gate.

## The headline: per-move agreement

A column is called INCONSISTENT if even ONE joined move deviates, which is a
deliberately strict test. The rate that says whether our derivation is sound is
per MOVE, over all 15 characters:

| column | convention | moves agreeing |
|---|---|---|
| `startup` | sheet = ours +1 — the sheet counts the first active frame as startup; ours counts the frames before it | **311/314** (99%) |
| `active` | sheet = ours +0 — identical | **306/309** (99%) |
| `recovery` | sheet = ours +2 — a 2-frame tail the sheet counts and our last node does not | **213/220** (96%) |
| `white` | sheet = ours +0 — identical — the record's +9 power class, the ROM value the workbook quotes (not the damage dealt, which the scaler chain produces) | **302/314** (96%) |
| `gauge_hit` | sheet = ours +0 — identical once the sheet's own `gauge whiff` is subtracted | **308/314** (98%) |

So the two measurements corroborate each other on ~96% of every column we can
compare, under one stated convention per column. The residue is the worklist below.

## Verdicts, per character and column

| character | joined | startup | active | recovery | white | gauge_hit | red |
|---|---|---|---|---|---|---|---|
| **AN** Anakaris `0x06` | 17 | CONSTANT OFFSET (sheet = ours +1 on all 17) · n=17 | EXACT · n=16 | CONSTANT OFFSET (sheet = ours +2 on all 13) · n=13 | INCONSISTENT · n=17 | EXACT · n=17 | INCONSISTENT · n=17 |
| **AU** Aulbath `0x09` | 20 | INCONSISTENT · n=20 | INCONSISTENT · n=19 | CONSTANT OFFSET (sheet = ours +2 on all 12) · n=12 | EXACT · n=20 | EXACT · n=20 | EXACT · n=20 |
| **BI** Bishamon `0x08` | 25 | INCONSISTENT · n=24 | EXACT · n=24 | CONSTANT OFFSET (sheet = ours +2 on all 18) · n=18 | EXACT · n=24 | INCONSISTENT · n=24 | EXACT · n=24 |
| **BU** Bulleta `0x00` | 21 | CONSTANT OFFSET (sheet = ours +1 on all 21) · n=21 | EXACT · n=21 | CONSTANT OFFSET (sheet = ours +2 on all 16) · n=16 | EXACT · n=21 | EXACT · n=21 | EXACT · n=21 |
| **DE** Demitri `0x01` | 21 | CONSTANT OFFSET (sheet = ours +1 on all 21) · n=21 | EXACT · n=21 | CONSTANT OFFSET (sheet = ours +2 on all 15) · n=15 | EXACT · n=21 | EXACT · n=21 | EXACT · n=21 |
| **FE** Felicia `0x07` | 19 | CONSTANT OFFSET (sheet = ours +1 on all 19) · n=19 | EXACT · n=19 | CONSTANT OFFSET (sheet = ours +2 on all 13) · n=13 | EXACT · n=19 | INCONSISTENT · n=19 | EXACT · n=19 |
| **GA** Gallon `0x02` | 19 | CONSTANT OFFSET (sheet = ours +1 on all 19) · n=19 | EXACT · n=19 | CONSTANT OFFSET (sheet = ours +2 on all 13) · n=13 | EXACT · n=19 | EXACT · n=19 | EXACT · n=19 |
| **JE** Jedah `0x0f` | 18 | CONSTANT OFFSET (sheet = ours +1 on all 18) · n=18 | EXACT · n=18 | INCONSISTENT · n=12 | INCONSISTENT · n=18 | EXACT · n=18 | INCONSISTENT · n=18 |
| **LE** Lei-Lei `0x0d` | 22 | CONSTANT OFFSET (sheet = ours +1 on all 22) · n=22 | INCONSISTENT · n=22 | CONSTANT OFFSET (sheet = ours +2 on all 16) · n=16 | INCONSISTENT · n=22 | INCONSISTENT · n=22 | INCONSISTENT · n=22 |
| **LI** Lilith `0x0e` | 23 | CONSTANT OFFSET (sheet = ours +1 on all 23) · n=23 | EXACT · n=23 | INCONSISTENT · n=17 | INCONSISTENT · n=23 | EXACT · n=23 | INCONSISTENT · n=23 |
| **MO** Morrigan `0x05` | 22 | CONSTANT OFFSET (sheet = ours +1 on all 22) · n=22 | EXACT · n=22 | CONSTANT OFFSET (sheet = ours +2 on all 16) · n=16 | INCONSISTENT · n=22 | EXACT · n=22 | INCONSISTENT · n=22 |
| **QB** Q-Bee `0x0c` | 15 | CONSTANT OFFSET (sheet = ours +1 on all 15) · n=15 | EXACT · n=15 | CONSTANT OFFSET (sheet = ours +2 on all 10) · n=10 | INCONSISTENT · n=15 | EXACT · n=15 | INCONSISTENT · n=15 |
| **SA** Sasquatch `0x0a` | 20 | INCONSISTENT · n=20 | EXACT · n=20 | CONSTANT OFFSET (sheet = ours +2 on all 14) · n=14 | INCONSISTENT · n=20 | INCONSISTENT · n=20 | INCONSISTENT · n=20 |
| **VI** Victor `0x03` | 23 | CONSTANT OFFSET (sheet = ours +1 on all 23) · n=23 | EXACT · n=23 | CONSTANT OFFSET (sheet = ours +2 on all 17) · n=17 | INCONSISTENT · n=23 | EXACT · n=23 | INCONSISTENT · n=23 |
| **ZA** Zabel `0x04` | 30 | CONSTANT OFFSET (sheet = ours +1 on all 30) · n=30 | EXACT · n=27 | CONSTANT OFFSET (sheet = ours +2 on all 18) · n=18 | EXACT · n=30 | INCONSISTENT · n=30 | EXACT · n=30 |

## The arbitration — what the emulator said about the residue

The rule obliges us to re-measure OURS before concluding anything about the
workbook. Three rigs were run on vanilla vsavj (`tools/vanilla_join_rig.py`,
gate `tests/test_vanilla_frame_join.sh`), and they split the residue into three
families, two of which are now settled.

### 1. The duration bytes are the engine's — CONFIRMED, and the instrument's limit is measured

Tracing the engine's own node countdown `+0x20` beside the node pointer: the
first value observed on a node equals the duration byte we read on **334 of 380**
nodes. So the derivation's INPUT is what the engine loads, measured directly.

But the same trace shows **16% of sampled frames advance that counter by two**
ticks, not one — `field_trace` samples at `frame_done`, and the engine does not
run one tick per video frame. **A frame-rate trace therefore cannot arbitrate a
ONE-frame convention difference**: its resolution is the size of the thing being
measured. That is why the `startup +1` and `recovery +2` offsets stay *named
conventions* rather than being declared right or wrong here; settling them needs
a tick-accurate instrument (a `-debug` trace or a Lua hook on the tick), which
this session did not build.

### 2. The damage residue is the WORKBOOK double-counting — SETTLED

Every move whose `white` and `red` read about HALF the workbook's has the same
shape: the chain carries **two or more attack records that share hit id 1**, the
engine's own multi-hit dedup key (record `+0x10`). Records sharing a hit id are
alternative boxes for ONE hit — the victim's recent-hit slot refuses the second
([VSE-43]) — so only one of them can land. We take one; **the workbook sums them**.
The rule itself was MEASURED 14z-146 (`tests/test_rehit_ring.sh`): the slot holds the
last landed id and the engine clears it on every tick the attacker's node has no
attack record, so consecutive attack nodes sharing an id land once and a same-id
record lands again after any gap node — JE 5HP `2(5)2(5)2` lands three times, and
SA CL.5HK `2(2)3` lands once for a different reason (its first hit launches the
victim and the juggle gate refuses the second: a victim-state effect, not the chain's).


Five moves carry it (MO 5HK, QB 2HK, SA 5HP, VI 2HP, JE 5HK — two or more attack
records sharing hit id 1; the per-record values are on the full page).

**A sixth, of the same family, came with the command normals (14z-189): LE `6HP`.**
Its one active run carries seven records, all hit id 1, and the workbook lists THREE
hits whose values are those of the first three records to the byte, so its `white` and
`red` cells are the only two misses of the 18 joined command normals.
Measured on one rig, not inferred: on the idle standing victim at 128 px (the only
distance measured) the move lands **one** hit (`tests/test_vanilla_command_join.sh`
section 5, P2's `+0x50` drops once) — consecutive same-id attack nodes land once, the
rule `tests/test_rehit_ring.sh` measured. **The Japanese wiki agrees with the
measurement (ANSWERED 2026-10-05, 14z-192):** the maintainer, reading seesaawiki
vswiki, *"Japanese wiki (seesaa) confirms 5HP is multi-hit, while 6HP is a one hit
up-forward diagonal move"* — so the workbook's three hits are wrong for `6HP`, as
the maintainer had recalled on seeing the capture (2026-10-03). Which move the
workbook's three-hit row was taken from is not checked (GitHub #216; its other gaps
stay open there).

**The hit rig confirms our reading and not theirs.** P1 performs each normal on a
victim whose HP is re-pinned before every event, and each DROP in P2's `+0x50` is
counted: our dedup-aware run count matches the engine's hit count on **75 of 78**
connecting events (the measurement is hashed in `tests/expected/vanilla_hit_damage.sha256`; the values live out of tree, `../charpages/framedata/vanilla_hit_damage.tsv`). Summing every record,
as the workbook does, would not. So on this family ours is right and the
workbook is wrong, and the mechanism says why.

The same rig also showed the workbook is a **ROM-derived** source, not a
play-measured one: on a live connect the DEALT drops are neither figure
(the worked example is on the full page), yet the workbook
quotes the record values to the byte. That is why its `white damage` matches our
`+9` exactly, and it is the best evidence available about a method the page
itself never states.

### 2b. The gauge column — ARBITRATED 14z-146: the residue is HITS LANDED, never meter

`tests/test_meter_gain.sh` reads the attacker's meter (+0x10A) frame by frame on
connecting rigs (P2 idle, HP re-pinned) for the five characters with an
unarbitrated `gauge_hit` cell. The bar moves in STEPS: the SWING COST on the
press frame — 0 / 3 / 6 by button strength, whiff or hit alike, equal to the
workbook's `gauge whiff` on every move read — and ONE on-hit step per LANDED hit,
equal to the record's `+0x14` (our per-hit value) on every connecting event. So
neither side's per-hit meter is wrong; what differs is how many windows LAND on
an idle standing victim at one geometry: SA CL.5HK and 2HP land 1 of their 2
(the juggle gate, `tests/test_rehit_ring.sh`), LE J.HP 3 of 6, BI 2HK 1 of 2 (its
sheet cell `24(24)` is a CONDITIONAL second hit and is now read as one). Ours
counts the chain's WINDOWS — its capacity — and the workbook what its author saw
land. Two sheet defects fell out: FE 5MP's `guage hit` 5 is a typo for 15 (ours =
engine = 12), and ZA J.2HK's row carries M-strength numbers (whiff 3, hit 15) on
an H move (engine: swing 6, on-hit 18 = ours). A whiff twin was tried and
dropped: it repeats the swing step, and no whiff geometry exists for Zabel's
dive kicks, which reach across the engine's 336 px separation clamp.

### 3. Jedah's crouching recovery — CLOSED 2026-09-02: THE RESIDUE IS THE WORKBOOK'S

All six of Jedah's crouching normals (and Lilith's `2MK`) read `+3` where every
other character reads `+2`. ~~by finding 1 the available instrument cannot resolve
a one-frame question. Left open rather than guessed.~~ **ARBITRATED IN THE EMULATOR,
IN ENGINE TICKS.** The instrument that entry said did not exist does: a write tap
fires per WRITE, and `PRG:0x027F70` (`subq.b #$1,$20(a6)`) IS one engine tick, so
the multi-tick frames that defeat a frame-rate trace are fully visible.

**MEASURED: 18 of 18 derived totals equal the engine's tick count EXACTLY** (JE, LI,
DE crouching normals, no tolerance — `tools/tick_durations.py`,
`tests/test_tick_durations.sh`). Jedah's six: 13/29/66/13/29/57 derived, and the
same six measured.

**THE ARBITRATION.** Our `startup` and `active` are not flagged for these characters
— they agree with the workbook under its own stated conventions — and the TOTAL is
now ground truth. Since total = startup + active + recovery, our recovery is right,
and the workbook's for those seven moves sits one frame below its own convention.
Measurement is king: a source whose method we cannot see loses to a tick count
taken from the engine itself.

### 3b. The last three timing cells — ARBITRATED 14z-146, in engine ticks

`tests/test_tick_durations.sh` gained Aulbath's standing and Lei-Lei's jumping
normals, per node. **AU 5MP**: the sheet's active `6x3` (18) against our `6,3`
(9) — the attack nodes spend 3+3+3 = 9 ticks; the sheet's cell is a notation
slip for `6,3`. **AU 5HP**: the sheet's startup 11 against our 9 — node 0 to the
first attack node is 9 ticks, so under the sheet's own +1 the cell should read
10; it is one high. **LE J.HP**: the sheet's `2,2,2,2,2,1` (11) against our
`2,2,2,2,2,2` (12) — the pass LEAVES the chain inside its window at the LANDING
after 10 of the data's 12 attack ticks (13 of 14 nodes entered): the sheet's 11 is
a landing-cut figure at its author's jump timing, ours the chain's capacity —
the aerial-recovery rule (a physics event bounds the chain) applied to active.
**AN J.2K**: his three D+kick rows join for the first time — a forward jump then
D+kick enters ONE chain, `a2:0x1e` (`tests/test_vanilla_aerial_join.sh`'s fourth
direction); startup 8 (+1 = the sheet's 9), red 16 = 8+8, white 8: EXACT.

## Every INCONSISTENT column — per character (the moves are on the full page)

### AN Anakaris — `white` — most common delta +0 on 16/17; spread +0..+5

17 move(s) deviate; the per-move table is on the full page.

### AN Anakaris — `red` — most common delta +0 on 16/17; spread +0..+15

17 move(s) deviate; the per-move table is on the full page.

### AU Aulbath — `startup` — most common delta +1 on 19/20; spread +1..+2

20 move(s) deviate; the per-move table is on the full page.

### AU Aulbath — `active` — most common delta +0 on 17/19; spread -1..+9

19 move(s) deviate; the per-move table is on the full page.

### BI Bishamon — `startup` — most common delta +1 on 23/24; spread +0..+1

24 move(s) deviate; the per-move table is on the full page.

### BI Bishamon — `gauge_hit` — most common delta +0 on 23/24; spread -18..+0

24 move(s) deviate; the per-move table is on the full page.

### FE Felicia — `gauge_hit` — most common delta +0 on 18/19; spread -10..+0

19 move(s) deviate; the per-move table is on the full page.

### JE Jedah — `recovery` — most common delta +3 on 6/12; spread +2..+3

12 move(s) deviate; the per-move table is on the full page.

### JE Jedah — `white` — most common delta +0 on 17/18; spread +0..+6

18 move(s) deviate; the per-move table is on the full page.

### JE Jedah — `red` — most common delta +0 on 17/18; spread +0..+16

18 move(s) deviate; the per-move table is on the full page.

### LE Lei-Lei — `active` — most common delta +0 on 21/22; spread -1..+0

22 move(s) deviate; the per-move table is on the full page.

### LE Lei-Lei — `white` — most common delta +0 on 20/22; spread -9..+9

22 move(s) deviate; the per-move table is on the full page.

### LE Lei-Lei — `gauge_hit` — most common delta +0 on 21/22; spread -18..+0

22 move(s) deviate; the per-move table is on the full page.

### LE Lei-Lei — `red` — most common delta +0 on 20/22; spread -21..+27

22 move(s) deviate; the per-move table is on the full page.

### LI Lilith — `recovery` — most common delta +2 on 16/17; spread +2..+3

17 move(s) deviate; the per-move table is on the full page.

### LI Lilith — `white` — most common delta +0 on 19/23; spread -1..+7

23 move(s) deviate; the per-move table is on the full page.

### LI Lilith — `red` — most common delta +0 on 19/23; spread -1..+18

23 move(s) deviate; the per-move table is on the full page.

### MO Morrigan — `white` — most common delta +0 on 21/22; spread +0..+7

22 move(s) deviate; the per-move table is on the full page.

### MO Morrigan — `red` — most common delta +0 on 21/22; spread +0..+19

22 move(s) deviate; the per-move table is on the full page.

### QB Q-Bee — `white` — most common delta +0 on 14/15; spread +0..+7

15 move(s) deviate; the per-move table is on the full page.

### QB Q-Bee — `red` — most common delta +0 on 14/15; spread +0..+16

15 move(s) deviate; the per-move table is on the full page.

### SA Sasquatch — `startup` — most common delta +1 on 19/20; spread +0..+1

20 move(s) deviate; the per-move table is on the full page.

### SA Sasquatch — `white` — most common delta +0 on 19/20; spread +0..+8

20 move(s) deviate; the per-move table is on the full page.

### SA Sasquatch — `gauge_hit` — most common delta +0 on 18/20; spread -18..+0

20 move(s) deviate; the per-move table is on the full page.

### SA Sasquatch — `red` — most common delta +0 on 19/20; spread +0..+20

20 move(s) deviate; the per-move table is on the full page.

### VI Victor — `white` — most common delta +0 on 22/23; spread +0..+8

23 move(s) deviate; the per-move table is on the full page.

### VI Victor — `red` — most common delta +0 on 22/23; spread +0..+22

23 move(s) deviate; the per-move table is on the full page.

### ZA Zabel — `gauge_hit` — most common delta +0 on 29/30; spread -6..+0

30 move(s) deviate; the per-move table is on the full page.

## The pursuits — named and compared for all 15 characters (14z-194, #229)

First measured on vsavj on ERIS with scratch rigs of the #229 fork (14z-194); the method was rebuilt as a gate
(14z-205, registered 14z-209): `tests/audit_vanilla_pursuits.sh` (each event's frozen line and hashes
`tests/expected/vanilla_pursuits.tsv`, the connect-band edges `tests/expected/vanilla_pursuit_bands.tsv`, the rigs
`tools/vanilla_pursuit_rigs.py`; its row set equals the workbook's 30 pursuit rows). The column verdicts below are
14z-194's reading as the Q2 rulings amended it, not re-classified from the gate's run (`tools/crosscheck_229.py`
does not read the pursuits, Q2); the per-move figures stay out of the tree with the rest of the frame data.
**Scope first**: of the
workbook's rows not joined above, the #229 fork grouped 440 by what each needs that the
vanilla join rig lacks — motion specials 166, guard-cancel rows 42, command throws and
grabs 54, ES specials 61, EX supers 50, ground throws 23, air throws 14, and the 30
pursuit and ES-pursuit rows measured here.

**The rig**: walk in to contact, knock the victim down (2HK, which knocks down for all
but Jedah, whose 2HK never enables a pursuit — his 5HK does), then one U+button press at a
swept offset, one leg per offset. **Identity**: on every character the pursuit fires only
on a downed victim — the same press at the same offset with no knockdown enters the
standing LP on every leg (the control) — each ES version spends exactly one stock at its
entry frame, and 8P and 8K enter the same chain, as the sheet's single row says. The
maintainer confirmed all 15 pursuits and ES pursuits by eye on capture sheets
(`DECISIONS_HISTORY.md` "Read 2026-10-07 (14z-194) — #229"). Frame data in ENGINE TICKS
from a write tap over `+0x1C..+0x23` (the chains loop or hold on game logic, so a
frame-rate trace cannot measure them).

| column | verdict over the 15 |
|---|---|
| gauge | **EXACT** on all 15, P and ES: the game pays the sheet's hit gauge over the hits landed (the first hits of a series), measured from the gauge word; ES pays 0, as the sheet says |
| red / white damage | **EXACT** on 15 of 15 for P and 14 of 15 for ES under this page's rule (red = real + white, first hit; each record's power CLASS — Zabel's pursuit records carry the no-kill flag in bit 7, decoded since 14z-195, #241). ~~The one ES miss is Demitri's first hit~~ RETRACTED 14z-208 (#229 Q2, maintainer-ruled 2026-10-24): EXACT on 15 of 15 for ES too; his ES pursuit lands 1 hit and then 4, the sheet's `8+1x4` |
| active | **NOT REPRODUCED, METHOD UNKNOWN** (#229 Q2, maintainer-ruled 2026-10-24): the 14z-194 reading "the sheet reads ours +1 on 12 of 15 (P) and 11 of 15 (ES)" is not reproduced by the 14z-205 gate, counted two ways, and what the sheet counts as active is open |
| startup | **INCONSISTENT, in two families**: the sheet reads ours +1 for DE FE AU SA QB LE and +2 for BU GA VI AN BI LI JE; MO +4 and ZA +9 (both leap chains loop on game logic). OURS re-checked first: Demitri's count equals its duration-byte derivation, every count is the same across P, K and ES and between connecting and whiffing legs, and the hit reader passes its control. What the sheet counts as a pursuit's startup is OPEN |
| recovery | **UNCOMPARABLE**: the sheet writes prose ("landing 1", "32 + landing 1") |

**The workbook's side, measured:** Gallon's 2HK knocks Victor down though the workbook
lists it as knockback; Jedah's 2HK never enables a pursuit. RETRACTED 14z-208 (#229 Q2,
maintainer-ruled 2026-10-24, on two capture sheets and an 8K sweep): ~~8K opens later than
8P~~ — 8K and 8KK open on the frame 8P and 8PP do for all 15 characters, and an early press
enters the same chain as 8P; ~~Morrigan lands 2 hits where the sheet says 4, Bulleta and
Lei-Lei fewer~~ — Morrigan lands 4 (ES 8), Bulleta 6 (ES 12), Lei-Lei 4 (ES 8), the sheet's
counts. **Not covered:** the ES pursuits' extra hits compared as records, the hit counts
on other victims, the active-column exceptions, what the startup offset counts, FBNeo.

## The normal throws, ground and air (14z-195; air 14z-208c, classified 14z-209, #229)

Measured on vsavj on PILOT; the gate is `tests/audit_ground_throws.sh` (its frozen hashes
`tests/expected/ground_throws.tsv`, the figures outside the tree since #319; the rigs `tools/ground_throw_rigs.py`). **Scope**: the
workbook's 23 ground-throw rows — 22 measured on the 14 characters that have one (Anakaris
has none), each "6MP or 6HP" row run with both buttons (42 events); Victor's Graviton
Knuckle (a follow-up input during his MP throw) is not measured. The rigs' row set is checked
against the workbook's own `type` column (`ground_throw_rigs.py rowset`).

**The rig**: walk in to pushbox contact, one toward or back + button, the victim Victor
(Demitri for Victor). **Identity**: every throw HOLDS from its press frame and not on the
frame before (P1's `+0x134` = 0x01 with P2's = 0xFF); every damage record is the one the
GAME staged, read at the fighter applier (`PRG:0x0189EA`) and the object-hit applier
(`PRG:0x02979A`), lies in the thrower's own attack table, and LANDS (P2's HP falls within 2
frames, read from the dumps, not from the record). The maintainer confirmed all 42 throws on a
capture sheet of each throw at its first damage frame: *"They are the throws and Buletta is
actually in frame but barely visible as her sprite goes behind her target's during the
throw"* (2026-10-08). Damage is each record's power CLASS (#241), red = real + white as above.

| column | verdict over the 22 |
|---|---|
| gauge | **EXACT** on all 22: 9 for every throw, 0 for Zabel's two, as the sheet says |
| red / white damage | single-hit throws with a number in the sheet: red **EXACT** on 13 of 15 — Victor's 6K and Zabel's 6K read the sheet one ABOVE ours (25 against 24, 28 against 27); white **EXACT** on 13 of 15 — Lei-Lei's and Lilith's read 9 where ours is 7 and 6. Multi-hit throws (DE 6K, FE 6P, VI 6MP/6HP, ZA 6P): every hit equals the sheet's per-hit value and the unmashed hit count lies inside its range; Q-Bee's two hits are the sheet's `14+9` / `5+3` in order |
| startup | **CONSTANT OFFSET**: the hold starts ON the press frame for all 42 events and the sheet writes 1 for every throw — the sheet counts the hold frame as frame 1 |
| recovery (#330) | per row, against the thrower's first accepted tick when thrown (below): **EXACT** on 17 of 21 — 14 as written, 3 more with the sheet's `+ landing 1` counted in (Felicia's and Gallon's K throws, Q-Bee's); Morrigan's K throw lies **inside** the sheet's range (its bottom); **off** on 4: Felicia's and Zabel's P throws and Bulleta's (sheet = ours -2; Bulleta's figure moves with the victim and the sheet's equals ours on Demitri), Aulbath's back throw (+24 — our rig's 4P is his forward throw in every field, the sheet's a two-hit throw we do not produce). By the page's classify: INCONSISTENT |
| throw tech (#330) | the advantage after a tech (the victim's first accepted tick minus the thrower's), per row against three victims (the maintainer: *"Against the 3-victim range"*): **EXACT** on 10 of 22 with Victor; **inside the victim range** on 5 (Bulleta, Demitri's K throw, Gallon's P throw, Morrigan's K throw, Zabel's P throw); **INCONSISTENT** on 7, by 1 from the nearest victim — Felicia's P and K throws, Jedah's, Q-Bee's, and Victor's three (sheet = ours -1 on all three, a constant on that character). The sheet's own victim is unknown |
| invuln | not measured |

**Recovery and the throw tech, measured (#330, 14z-211; the gate `tests/audit_throw_recovery.sh`, its frozen hashes
`tests/expected/throw_recovery*.tsv`, the ticks outside the tree; the rigs `tools/throw_recovery_rigs.py`; classified by
`tools/crosscheck_229.py tr-ground`).** ACTIONABLE is the maintainer's *"First accepted input"* (2026-10-28): the first
tick from the throw's commit (the press frame) at which a one-frame LP starts the normal, the tick before never doing
so, for each fighter, thrown and teched, at speed level 0 (ticks are frames) with the RNG pinned. No single engine
state marks it: the mode byte `+0x05` returns to 00 up to 11 ticks before the thrower can act on 22 of 42 events
(a one-pass neutral before a landing, or a neutral held 2-12 passes — Victor's), and standing neutral comes up to 25
late on 24 of 168 (the thrower attacks from the air or the landing). **The tech**: the victim's back + the throw's
button for one frame techs at k = 1..7 ticks after the commit and not at k = 8, on all 42 events and three victims
(the community's "7 frames (turbo 0)"); a press at k = 8 on Demitri's K throw is MASH (the throw two ticks shorter,
the same damage), not a tech. A tech lowers the damage but on Aulbath's and Morrigan's P throws. The victim moves the
advantage after a tech by up to 4 ticks (the air and command throws: below). **Not covered:** mashed throws, other
speed levels, other stage positions (every event at the rig's one walk-in place; a first event at another stage x
moved Morrigan's K throw by 6 ticks) and the corner, FBNeo.

**The workbook's side, measured:** every "6MP or 6HP" row is one throw (the two buttons stage
the same records, pay the same gauge and land the victim on the same side). Aulbath's back
throw (`4P`) stages ONE hit, 17 red / 6 white — the sheet's second part — where the sheet
writes `10+17` / `4+6`; the victim lands behind him, as it does after Bulleta's P throw and
Demitri's and Gallon's K throws. The multi-hit throws' single white cell (VI 4, ZA 7, DE `4+2`,
FE `2+2`) does not decompose into our per-hit whites (2, 2, 2, 1) and is left UNCOMPARABLE.
**Not covered:** Graviton Knuckle, mashed hit counts, other victims (but the throw tech's three), the
characters picked by the cursor (they are forced by poke), FBNeo.

### The air throws (14z-208c, classified 14z-209)

Since 14z-208c the same gate measures the workbook's 14 air-throw rows, moved here from the command throws (the
maintainer: *"Remove all, Victor too, but add them to the normal throws!"*, 2026-10-25): one `gt_XX_air` rig per
character, toward+MP and toward+HP after a jump (28 events), Victor's with the two jumps converging. **Identity** as
above: every air throw HOLDS from its press frame and not before, and its records lie in the thrower's own table and
land. Classified by `tools/crosscheck_229.py gt-air` over a kept run of the gate; `gt-ground` re-derives the ground
rows above the same way and reproduces their verdicts (22 rows: startup, gauge, red and white as stated).

| column | verdict over the 14 |
|---|---|
| gauge | **EXACT** on all 14 |
| red | **EXACT** on all 14 |
| white | **EXACT** on 13 of 14 — Morrigan's row writes the same figure in its white cell as in its red, where ours stages a white part of that total |
| startup | **CONSTANT OFFSET**: sheet = ours +1 on all 14, as on the ground |
| recovery (#330) | the cell's terms summed (`40 + 23 + landing 1`) against the thrower's first accepted tick when thrown, per row against FOUR heights — the rig's, and pressed 3 ticks earlier, 3 and 6 later, every height that still throws (the maintainer: *"Against a height range"*): **EXACT** on 2 of 14 at the rig's height, **inside the height range** on 4, **INCONSISTENT** on 8 (sheet - ours at the rig's height, -4..+4) |
| throw tech (#330) | the advantage after a tech, the same way, and against the three victims at the rig's height too (the maintainer: *"Measure them too"*): **EXACT** on 5 of 12, **inside the height range** on 4, **inside the victim range** on 1 (Bulleta: Lilith's figure), **INCONSISTENT** on 2 (Jedah, Q-Bee: 1 from the nearest figure); Lei-Lei's and Victor's cells are empty — Lei-Lei's air throw has no tech, Victor's tech lowers the damage and moves neither fighter's recovery |

**Recovery and the throw tech in the air (#330, 14z-211; the same gate, `tests/audit_throw_recovery.sh`, family `air`).**
Measured at speed level 0 like the ground throws; the air rigs press at the TICK the level-6 rig reaches its press in
(every fighter's height and the pair's distance at the commit equal the level-6 rig's). The tech techs at k = 1..7
ticks after the air press on 26 of 28 events, not at 8. An air throw's recovery moves with the HEIGHT it is made at
(by up to 9 ticks on 10 of 14 characters), and the sheet's heights are unknown: hence the range. **Other victims**
(14z-212): the air throws are also frozen on Demitri (28 events) and Lilith (20: the air throws of Aulbath, Gallon,
Jedah and Victor never hold on her at the rig's height and are left out, as a height that does not throw is); the
throw tech is classified against their figures too. The command throws are frozen on all three victims as well.

## The specials, FE AN AU BI BU DE GA JE (14z-205, frozen 14z-209, #229, page section #331)

Measured on vsavj; the gate is `tests/audit_vanilla_specials_a.sh` (its frozen identity map
`tests/expected/vanilla_specials_a.tsv`, its column verdicts, live-vs-derived tick agreement and a hash of the
joined values `tests/expected/vanilla_specials_a_verdicts.tsv`, which the table below is rendered from; the rigs
`tools/specials_a_rigs.py`). **Scope**: 80 workbook rows run on the eight characters (each named by the chains the
engine entered and the projectile types it spawned, never by the input) and 6 declared for other families
(`NOT_RUN`: Anakaris's two EX supers, Demitri's three Demon Cradle GC rows, Bishamon's `J.MP`). Rows with no
comparable cell: the projectiles and movements (the fighter's walk has no attack node; a projectile's own frames
are not counted), Bishamon's Kienzen `623P` (it never fires under five cadences: declared, open), and the two
`UNJOINABLE` rows (Felicia's Toy Touch, an OTG move; Anakaris's Spell of Turning release, which needs an absorbed
projectile). **Identity**: the maintainer read F1's capture sheets (Q1, `DECISIONS_HISTORY.md` "Read 2026-10-25
(14z-209) — #229 Q1"). **Timing** in LIVE ENGINE TICKS from a write tap on P1's countdown (`PRG:0x027F70`); a
move that connects even at the 332 px whiff pin reads its active and recovery UNCOMPARABLE. Red / white / gauge are
summed over the move's hit runs; three moves were performed at contact to count their hits (Demitri's Demon
Cradle and Gallon's Climb Razor land one, Bishamon's Iai Giri two at every strength). Classified by the gate itself
(`tools/specials_a_rigs.py join`, under this page's classify), over the rows joined by ONE event.

| column | verdict over the rows joined by one event (sheet - ours) |
|---|---|
| startup | **INCONSISTENT**: most common delta +1 on 34/40; spread +0..+2 — EXACT AU; CONSTANT OFFSET +1 FE AN BI BU DE; INCONSISTENT GA; no verdict JE |
| active | **INCONSISTENT**: most common delta +0 on 19/33; spread -2..+2 — EXACT AN BU GA; CONSTANT OFFSET +1 AU DE; INCONSISTENT FE BI; no verdict JE |
| recovery | **INCONSISTENT**: most common delta +2 on 18/33; spread +0..+7 — EXACT AU; CONSTANT OFFSET +2 AN DE; CONSTANT OFFSET +3 GA; INCONSISTENT FE BI BU; no verdict JE |
| white | **INCONSISTENT**: most common delta +0 on 24/40; spread -3..+24 — EXACT FE AU; CONSTANT OFFSET +4 DE GA; INCONSISTENT AN BI BU; no verdict JE |
| gauge hit | **INCONSISTENT**: most common delta +0 on 34/40; spread -3..+3 — EXACT AN AU BU DE GA; INCONSISTENT FE BI; no verdict JE |
| red | **INCONSISTENT**: most common delta +0 on 23/40; spread -8..+20 — EXACT FE AN AU; INCONSISTENT BI BU DE GA; no verdict JE |

Live engine ticks equal the duration-byte derivation of the same node walk on
startup 36/61, active 31/61, recovery 27/61 joined row-events (a difference is game logic cutting a node short — a
landing, a jump — which the bytes cannot see); the 301 joined values are frozen as one hash, never in the tree.

**Jedah has no row in the table: every Jedah cell is UNCOMPARABLE as a column verdict.** Both of his workbook rows,
Dio Sega (`236P`) and Ira Piano (`J.632[4]K~P`), write one value for every strength, so the rig runs all three
strengths and each row joins THREE events; the per-character verdicts take only rows joined by one event, and a
row joined by several is tested as a one-row claim instead (does the sheet's single value hold for every strength,
the ground-throw rigs' rule). Dio Sega is a projectile: on every event the fighter's walk has no attack node and
carries no attack record, so all six of its cells are uncomparable as well. Ira Piano's `active` is prose; its
other five cells pair on every event (they are in the values hash), ours is the same for all three strengths on
each, and the sheet equals ours on recovery, red, white and gauge. Its startup reads far above ours: the workbook
counts from the K press that starts Ira Spinta, ours from Piano's own entry — a counting convention, measured
14z-205b (`STATE_HISTORY.md`, "Ira Piano's startup"), not a disagreement.

## The specials, LE LI MO QB SA VI ZA (14z-205, classified 14z-209, #229)

Measured on vsavj; the gate is `tests/audit_vanilla_specials_b.sh` (its frozen identity map
`tests/expected/vanilla_specials_b.tsv`, its timing as a hash, `tests/expected/vanilla_specials_b_ticks.sha256`;
the rigs `tools/specials_b_rigs.py`). **Scope**: the workbook's 80 motion-special, special-projectile and
movement-special rows of the seven characters, every one FIRED (the chain it entered is the join). **Identity**: the
maintainer read F2's capture sheets (9 tiles per move): *"they do but for F4"* (Q1, `DECISIONS_HISTORY.md`).
**Timing** is in exact engine passes from a `-debug` tap leg (each sample tagged with its pass, `passeq`); the 17 rows
whose whiff event touched P2 are CONTACT, their timing reported and not classified. Red / white / gauge are the first
active record's (the page's rule). Classified by `tools/crosscheck_229.py sb` over a kept run of the gate.

| column | verdict over the joined rows (sheet - ours) |
|---|---|
| startup | **INCONSISTENT**: +1 on 46 of 62 (spread -16..+4); CONSTANT OFFSET +1 for LE and VI, the other five INCONSISTENT; 18 uncomparable (CONTACT, prose) |
| active | **INCONSISTENT**: +0 on 31 of 56 (spread -94..+1); EXACT for MO, SA, VI, CONSTANT OFFSET +1 for ZA, INCONSISTENT LE LI QB; 24 uncomparable |
| recovery | **INCONSISTENT**: +2 on 17 of 32 (spread -4..+3); EXACT MO, CONSTANT OFFSET LI +1 and QB +2, INCONSISTENT LE SA VI, ZA no data; 48 uncomparable (mostly prose) |
| red / white | **INCONSISTENT** but near: red +0 on 75 of 79 (the residue: Lei-Lei's LP Henkyouki and Victor's three Giga Stakes), white +0 on 76 of 79 (Lei-Lei's LP Henkyouki and Victor's LP and MP Giga Stakes) |
| gauge whiff / gauge hit | **INCONSISTENT** but near: whiff +0 on 59 of 63 (Q-Bee's two MK SXP, Sasquatch's HK Big Typhoon and Lvl 2 Big Blow), hit +0 on 73 of 79 (LE LP Henkyouki, SA Lvl 2/3 Big Blow, VI's three Giga Stakes) |

## The ES specials and EX supers (14z-205, classified 14z-209, #229)

Measured on vsavj; the gate is `tests/audit_es_ex.sh` (its frozen identity map and record hashes
`tests/expected/es_ex.tsv`; the rigs `tools/es_ex_rigs.py`). **Scope**: the workbook's 111 ES/EX rows: 98 joined
to an event that FIRED (each named by the chain it entered and the stock it spent, never by the
input; a workbook input the engine reads differently joins under the engine's, Q4); 12 rows on 10 inputs are
UNRESOLVED and named with the reason in `tools/es_ex_rigs.py` UNRESOLVED (every timing tried enters a normal or pays
nothing on vsavj: BI 22PP / 236PP / 623PP, DE 623KK, FE 22PP and 236PP~PP, LE Tenraiha, QB SXP and air SXP, SA 720KK);
Demitri's ES Demon Cradle GC is declared for the guard cancels (`NOT_HERE`), which measure it (#331, 14z-210).
**Identity**: the maintainer read F3's sheets
(Q1), and Jedah's re-rigged ES row is ES Ira Spinta, ES Ira Piano being `J.63214KK~PP` (*"both are correct"*,
2026-10-21). **Timing** in engine ticks from the field leg's pass counter, from the move's entry; a projectile or a
move with no attack node on P1 is uncomparable. Classified by `tools/crosscheck_229.py es`.

| column | verdict over the joined rows (sheet - ours) |
|---|---|
| startup | **INCONSISTENT**: +1 on 30 of 44 (spread +0..+3) — close to the page's +1 for normals; 66 uncomparable (projectiles, no attack node on P1, unresolved) |
| active | **INCONSISTENT**: +0 on 5 of 43 (spread -200..+13) — unresolved: ours counts attack-node ticks, the sheet's cell is not that for most supers |
| recovery | **INCONSISTENT**: +1 on 5 of 20 (spread -63..+3); 90 uncomparable (mostly prose) |
| red / white (first hit) | **INCONSISTENT** but near: red +0 on 75 of 87, white +0 on 76 of 87; the residue of the two sits on a few moves (Lilith's Gloomy Puppet rows, Aulbath's Sea Rage, Bulleta's Cool Hunting Hunters, Gallon's ES Beast Cannons, Jedah's ES Dio Sega, Lilith's ES Merry Turn, Anakaris's ES Cobra Blow and Pharaoh Magic, Bishamon's [4]6KK) |
| gauge hit | **INCONSISTENT** but near: +0 on 97 of 98 (Lei-Lei's Chuukadan the one) |

## The command throws and grabs (14z-205, re-rigged 14z-208c, classified 14z-209, #229)

Measured on vsavj; the gate is `tests/audit_command_throws.sh` (identity in the clear and a signature hash per event
in `tests/expected/command_throws.tsv`, the full lines outside the tree; the rigs `tools/command_throw_rigs.py`).
**Scope**: the workbook's 54 command-throw and grab rows, plus Victor's Mega Spike, which the workbook does not list
(the maintainer supplied it); the air throws left this family for the normal throws (*"Remove all, Victor too, but add
them to the normal throws!"*, 2026-10-25). 53 rows GRAB (P2 held, `+0x134`); Bishamon's 360+LP never does — LP
Kirisute Gomen holds nothing on vsavj, as the confirmed sheet shows. **Identity**: the maintainer confirmed every row
on 18-tile sheets after the re-rig (*"all good"*, 2026-10-25). **Damage** is each landed record's power class (#241),
compared as the whole HIT SERIES against the sheet's cell (`4+4+19`, `5x(1~4)+16`: a ranged count must contain the
unmashed count); **gauge** is P1's meter at the event's end from 0; **startup** is press-to-hold. Classified by
`tools/crosscheck_229.py ct`.

| column | verdict over the 53 grabbing rows |
|---|---|
| red (hit series) | **EXACT** on 44, **IN RANGE** on 6 (a mashed count inside the sheet's range), **INCONSISTENT** on 3: Demitri's Negative Stolen and Midnight Pleasure, Q-Bee's O.M. |
| white (hit series) | **EXACT** on 47, **IN RANGE** on 5, **INCONSISTENT** on 1: Anakaris's ES Mummy Drop |
| gauge | **EXACT** on 47, **INCONSISTENT** on 5 (Anakaris's Pit of Blame and ES Pit of Blame, Gallon's Wild Circular, Morrigan's Cryptic Needle, Victor's Giga Shock), **UNCOMPARABLE** on 1 (Midnight Pleasure: its input's own normals land first) |
| startup (press to hold) | **INCONSISTENT**: +1 on 19 of 53 (spread -44..+8); CONSTANT OFFSET +1 for BU FE GA LE SA VI ZA (the ground throws' offset), +8 for LI, INCONSISTENT for AN AU BI DE JE MO QB — what the sheet counts for a motion grab is open |
| recovery (whiff, #330) | the WHIFF profile summed (startup + active + recovery, a `1(5)1` bracket counted) against our whiff tick — the first accepted input after the button press, each grab made to whiff from pins 150 px wider each (the maintainer: *"Whiff recovery + techability"*): sheet = ours **+1** on 32 of 41 compared events — **CONSTANT OFFSET +1** for Anakaris, Demitri, Lilith, Q-Bee, Sasquatch, Victor and Zabel (the ground throws' offset); **INCONSISTENT** for Aulbath's ES grabs (-27, -22), Bishamon (+1..+7), Bulleta (-34..-18), Jedah (-29..+1) and Lei-Lei (-1..+6); 9 rows' cells are prose (UNCOMPARABLE). **No whiff exists on 28 events** (the maintainer: *"No whiff"*, 2026-10-28): Pit of Blame draws no move without a knocked-down victim, and 24 grabs start their move only when the engine's throw check passes — out of range, or against a victim it refuses, the 632[4] / 6324 grabs of Aulbath, Felicia, Gallon, Jedah, Morrigan, Q-Bee and Zabel give the button's plain normal and Bishamon's and Demitri's 360 MP / HP a jump, so the sheet's whiff cells on those rows describe nothing vsavj does (their ES versions do whiff: *"Yes, it is the whiff"*) |
| throw tech (#330) | the workbook's cell is empty on all 53 rows; measured (the victim's back + HP and back + HK at 1 and 7 ticks into the hold), the hold techs on 2 of 82 events — Victor's Giga Shock, both strengths, where the game shows TECH. HIT — and on none of the other 80 |

## The guard cancels (14z-205, classified 14z-209 on the Q5/Q6 basis, #229)

Measured on vsavj; the gate is `tests/audit_guard_cancels.sh` (its 291-event table as a hash,
`tests/expected/guard_cancels.sha256`, the table outside the tree; the rigs `tools/gc_rigs.py`). **Scope**: the
workbook's 46 guard-cancel rows — the 42 TYPED as one (`special GC`, `es special GC`, `GC`, `es GC`: `tools/gc_rigs.py`
GC_TYPES) and Demitri's four Demon Cradle GC rows, NAMED one but typed `special` / `es special` (`is_gc_row`, #331) —
on the 15 characters the rigs run, joined by their 623+button set:
57 buttons commit the game's own guard cancel (P1's `+0x3B5` := 6 by `PRG:0x029C6E`). **Identity**: the maintainer
read F5's sheets (Q1); Bulleta's guard cancel has no attack (*"this is indeed her correct GC"*); Demitri's, on P1
against a mirror Demitri and against Gallon, on 18-tile pages showing the game's guard-cancel banner (*"Enough,
integrate"*, 14z-210, #331); his kicks commit none. **Timing** is the
HIT's, the gc event's (Q6, *"(b) Keep the hit timing as the record. -> yes"*), in engine ticks; Bulleta's (no attack)
and Lei-Lei's (her hits come from another object) are uncomparable. **Damage** is what is DEALT on a defense-row -3
victim (Q5): Gallon, Zabel on Gallon's own rows, the first fall of P2's HP. **Gauge**: the whiff event's own gain, and
the hit cell as the page's 2b rule (the swing plus the record). Classified by `tools/crosscheck_229.py gc`.

| column | verdict over the joined events (sheet - ours) |
|---|---|
| startup | **INCONSISTENT**: +1 on 45 of 49 (spread +0..+1) — CONSTANT OFFSET +1 for 12 characters (the page's convention), EXACT for Aulbath, Bulleta and Lei-Lei no data |
| active | **INCONSISTENT**: +0 on 28 of 49 (spread -12..+21); EXACT for AN BI JE MO QB SA VI, CONSTANT OFFSET +1 for DE and +2 for FE, INCONSISTENT AU GA LI ZA |
| recovery | **INCONSISTENT**: +2 on 16 of 49 (spread -23..+23); a CONSTANT OFFSET for 9 characters but not one value (+2 DE FE QB SA, +3 AN BI LI, +5 MO, -4 VI), INCONSISTENT AU GA JE ZA |
| red / white (dealt, -3 victim) | **INCONSISTENT** but near: red +0 on 52 of 53 (Gallon's ES Diagonal Beast Cannon GC reads the sheet one above), white +0 on 52 of 53 (Q-Bee's ES R.M. one below); Bulleta's three deal nothing |
| gauge whiff | **INCONSISTENT** but near: +0 on 50 of 51 (Sasquatch's HK Big Typhoon GC the one) |
| gauge hit | **EXACT** on all 49 |

**Not covered (the four families):** FBNeo; victims other than the rigs'; the characters as picked by the cursor (they
are forced by poke);
per-move values, which stay outside the tree (`../charpages/framedata/crosscheck_229/`, `--pairs`).

## What is NOT known

- **The startup `+1` and recovery `+2` offsets are NAMED, not adjudicated.** The
  instrument available samples at video-frame rate and 16% of its frames carry two
  engine ticks, so it cannot resolve a one-frame question. A tick-accurate
  instrument would settle whether either side is counting wrongly; neither is
  assumed to be.
- ~~**Jedah's crouching recovery (+3, not +2) is unexplained**~~ **CLOSED 2026-09-02:
  measured in engine ticks, 18/18 exact — the residue is the WORKBOOK'S, not ours**
  — see the arbitration section. Lilith's `2MK` behaves the same way.
- ~~**The aerial outliers**~~ **RESOLVED 14z-145 — the workbook's aerial row is the
  FORWARD-jump variant and our join sent it to the NEUTRAL chain.** Two aerial slot
  sets exist (`0x12-0x17` neutral, `0x18-0x1D` forward), measured on every character;
  the join above now follows the measurement and the verdict table is what remains.
  *(The entry as it stood before, kept for the trail.)* PART-RESOLVED 2026-09-02, and the likely cause is NAMED
  (BI `J.HP`/`J.LP`, BU `J.MP`, VI `J.HP`, FE `J.HK`/`J.LK`, SA `J.MP`).
  `tools/tick_durations.py` separates the move from the jump for chains that LOOP:
  an aerial repeats until landing, back to its start (BI `J.LP`) or to a late node
  (BI `J.MP`). **BI measures 5/6 exact** and the miss is a flagged move — `J.HP`
  derives 28 where the engine spends 27; BU `J.LK`/`J.LP` are exact. STILL NOT
  SEPARABLE: aerials whose last node HOLDS with no further pointer write before
  landing (VI, FE, SA) still report AIRTIME — identical numbers across a
  character's moves are the tell, not a result. **LIKELY CAUSE, from the community
  corpus and NOT yet measured:** mizuumi distinguishes NEUTRAL- from FORWARD-jump
  variants of the same button (`8J.LP` vs `9J.LP`) where our slot map carries ONE
  chain per aerial button. Needs a two-direction jump rig.
- ~~**Specials, supers, EX/ES moves and throws are not joined**~~ **JOINED (#229, 14z-194 to
  14z-209):** every family of the workbook's rows has its own measured rig on vsavj, its own gate and
  its own section above. The rows with no measured event to compare are named in those sections
  with the reason: the specials' declared rows
  (Felicia's Toy Touch, Anakaris's Spell of Turning release, Bishamon's Kienzen), the ES/EX
  family's UNRESOLVED rows, Bishamon's LP Kirisute Gomen, Victor's Graviton Knuckle.
- **Seven workbook columns have no counterpart in the tree**: `on hit`, `on block`,
  `renda on hit`, `renda on block`, `throw tech`, `cancel`, `Invuln`. Frame advantage
  needs the victim's stun beside the attacker's recovery; nothing computes it.
- **The crouching and jumping slot layout was not re-measured on vanilla characters**
  — it is the tenants' measured layout, carried.
- **Slot `a2:0x00` on the characters that do not use it for LP** has no established
  role; the rig never entered it there.
- **AN OPEN QUESTION THIS RAISES ABOUT THE TENANTS.** `build/manifest/moves_huitzil.toml`
  labels `a2:0x01/03/05` as `6LP` / `6MP` / `6HP`, filled by `tools/name_moves.py`
  performing `6`+button at a FAR pin. On vanilla characters those odd slots are the
  FAR standing normal, and the maintainer's own note on those rows reads *"Alternate
  attack: different from 5LP (usually longer reach and different data)"* — which
  describes a far normal exactly. So the tenants' `6XX` labels may be a naming
  artifact of the rig's input choice rather than distinct command normals.
  **Not measured, not corrected here**: settling it means running the two-distance
  rig on native vs2 for the three tenants. Nothing in the shipped build depends on
  the label — it is documentation.
- **The workbook's own defects are not corrected**, only avoided: `AN` row 48 is
  shifted one column from `gauge whiff` on, `AN` rows 49-50 carry no frame data,
  `AN!K50` reads `[1+0x8+1x5+7`, and `VI!U43:U46` were eaten by Excel into dates.
  Duplicate move names exist in `FE`, `BU` and `JE`; the join takes the first row.

