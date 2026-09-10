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
  730 data rows. Read by `tools/xlsx_read.py` (stdlib only; validated cell for
  cell against `openpyxl` — 28,234 cells, the only 4 differences being the
  date-corrupted `VI!U43:U46` `Invuln` cells, a column this page does not compare).
- `../community/mizuumi_reverse_engineering.txt` — the mizuumi wiki's Reverse
  Engineering page (`oldid 416342`, 2025-07-31). It carries **no per-move frame
  data** — it is a RAM/ROM map — so it is not a source for this page. Its
  player-struct table is a separate, queued comparison against `atlas/ram.md`.

## What is compared, and what is not

| sheet column | ours | source of ours |
|---|---|---|
| `startup` | `startup` | frames before the first active frame |
| `active` | `active` | frames the attack box exists |
| `recovery` | `recovery` | frames after the last active frame |
| `white damage` | `white` | the attack record's +9 white power |
| `guage hit` | `gauge_hit` | the attack record's +0x14 attacker meter gain |
| `red damage` | `red` | the attack record's +8 real power PLUS its +9 white — the move's total |

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
- **DE, MO, FE, SA, LE, LI** take odd at far / even at near for MP..HK, but LP is
  `0x01` at both distances; **GA, VI** the same with LP at `0x00`; **BU** and **AU**
  additionally have no close variant for HP (BU none for MK).

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
Specials, supers and the `6`-prefixed command normals are not joined at all.

## The headline: per-move agreement

A column is called INCONSISTENT if even ONE joined move deviates, which is a
deliberately strict test. The rate that says whether our derivation is sound is
per MOVE, over all 15 characters:

| column | convention | moves agreeing |
|---|---|---|
| `startup` | sheet = ours +1 — the sheet counts the first active frame as startup; ours counts the frames before it | **288/291** (98%) |
| `active` | sheet = ours +0 — identical | **283/286** (98%) |
| `recovery` | sheet = ours +2 — a 2-frame tail the sheet counts and our last node does not | **190/197** (96%) |
| `white` | sheet = ours +0 — identical — the record's +9 is the dealt white damage, unscaled | **280/291** (96%) |
| `gauge_hit` | sheet = ours +0 — identical once the sheet's own `gauge whiff` is subtracted | **285/291** (97%) |

So the two measurements corroborate each other on ~96% of every column we can
compare, under one stated convention per column. The residue is the worklist below.

## Verdicts, per character and column

| character | joined | startup | active | recovery | white | gauge_hit | red |
|---|---|---|---|---|---|---|---|
| **AN** Anakaris `0x06` | 16 | CONSTANT OFFSET (sheet = ours +1 on all 16) · n=16 | EXACT · n=15 | CONSTANT OFFSET (sheet = ours +2 on all 12) · n=12 | INCONSISTENT · n=16 | EXACT · n=16 | INCONSISTENT · n=16 |
| **AU** Aulbath `0x09` | 20 | INCONSISTENT · n=20 | INCONSISTENT · n=19 | CONSTANT OFFSET (sheet = ours +2 on all 12) · n=12 | EXACT · n=20 | EXACT · n=20 | EXACT · n=20 |
| **BI** Bishamon `0x08` | 19 | INCONSISTENT · n=18 | EXACT · n=18 | CONSTANT OFFSET (sheet = ours +2 on all 12) · n=12 | EXACT · n=18 | INCONSISTENT · n=18 | EXACT · n=18 |
| **BU** Bulleta `0x00` | 18 | CONSTANT OFFSET (sheet = ours +1 on all 18) · n=18 | EXACT · n=18 | CONSTANT OFFSET (sheet = ours +2 on all 13) · n=13 | EXACT · n=18 | EXACT · n=18 | EXACT · n=18 |
| **DE** Demitri `0x01` | 21 | CONSTANT OFFSET (sheet = ours +1 on all 21) · n=21 | EXACT · n=21 | CONSTANT OFFSET (sheet = ours +2 on all 15) · n=15 | EXACT · n=21 | EXACT · n=21 | EXACT · n=21 |
| **FE** Felicia `0x07` | 19 | CONSTANT OFFSET (sheet = ours +1 on all 19) · n=19 | EXACT · n=19 | CONSTANT OFFSET (sheet = ours +2 on all 13) · n=13 | EXACT · n=19 | INCONSISTENT · n=19 | EXACT · n=19 |
| **GA** Gallon `0x02` | 18 | CONSTANT OFFSET (sheet = ours +1 on all 18) · n=18 | EXACT · n=18 | CONSTANT OFFSET (sheet = ours +2 on all 12) · n=12 | EXACT · n=18 | EXACT · n=18 | EXACT · n=18 |
| **JE** Jedah `0x0f` | 18 | CONSTANT OFFSET (sheet = ours +1 on all 18) · n=18 | EXACT · n=18 | INCONSISTENT · n=12 | INCONSISTENT · n=18 | EXACT · n=18 | INCONSISTENT · n=18 |
| **LE** Lei-Lei `0x0d` | 19 | CONSTANT OFFSET (sheet = ours +1 on all 19) · n=19 | INCONSISTENT · n=19 | CONSTANT OFFSET (sheet = ours +2 on all 13) · n=13 | INCONSISTENT · n=19 | INCONSISTENT · n=19 | INCONSISTENT · n=19 |
| **LI** Lilith `0x0e` | 22 | CONSTANT OFFSET (sheet = ours +1 on all 22) · n=22 | EXACT · n=22 | INCONSISTENT · n=16 | INCONSISTENT · n=22 | EXACT · n=22 | INCONSISTENT · n=22 |
| **MO** Morrigan `0x05` | 21 | CONSTANT OFFSET (sheet = ours +1 on all 21) · n=21 | EXACT · n=21 | CONSTANT OFFSET (sheet = ours +2 on all 15) · n=15 | INCONSISTENT · n=21 | EXACT · n=21 | INCONSISTENT · n=21 |
| **QB** Q-Bee `0x0c` | 15 | CONSTANT OFFSET (sheet = ours +1 on all 15) · n=15 | EXACT · n=15 | CONSTANT OFFSET (sheet = ours +2 on all 10) · n=10 | INCONSISTENT · n=15 | EXACT · n=15 | INCONSISTENT · n=15 |
| **SA** Sasquatch `0x0a` | 19 | INCONSISTENT · n=19 | EXACT · n=19 | CONSTANT OFFSET (sheet = ours +2 on all 13) · n=13 | INCONSISTENT · n=19 | INCONSISTENT · n=19 | INCONSISTENT · n=19 |
| **VI** Victor `0x03` | 23 | CONSTANT OFFSET (sheet = ours +1 on all 23) · n=23 | EXACT · n=23 | CONSTANT OFFSET (sheet = ours +2 on all 17) · n=17 | INCONSISTENT · n=23 | EXACT · n=23 | INCONSISTENT · n=23 |
| **ZA** Zabel `0x04` | 24 | CONSTANT OFFSET (sheet = ours +1 on all 24) · n=24 | EXACT · n=21 | CONSTANT OFFSET (sheet = ours +2 on all 12) · n=12 | EXACT · n=24 | INCONSISTENT · n=24 | EXACT · n=24 |

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

### AN Anakaris — `white` — most common delta +0 on 15/16; spread +0..+5

16 move(s) deviate; the per-move table is on the full page.

### AN Anakaris — `red` — most common delta +0 on 15/16; spread +0..+15

16 move(s) deviate; the per-move table is on the full page.

### AU Aulbath — `startup` — most common delta +1 on 19/20; spread +1..+2

20 move(s) deviate; the per-move table is on the full page.

### AU Aulbath — `active` — most common delta +0 on 17/19; spread -1..+9

19 move(s) deviate; the per-move table is on the full page.

### BI Bishamon — `startup` — most common delta +1 on 17/18; spread +0..+1

18 move(s) deviate; the per-move table is on the full page.

### BI Bishamon — `gauge_hit` — most common delta +0 on 17/18; spread -18..+0

18 move(s) deviate; the per-move table is on the full page.

### FE Felicia — `gauge_hit` — most common delta +0 on 18/19; spread -10..+0

19 move(s) deviate; the per-move table is on the full page.

### JE Jedah — `recovery` — most common delta +3 on 6/12; spread +2..+3

12 move(s) deviate; the per-move table is on the full page.

### JE Jedah — `white` — most common delta +0 on 17/18; spread +0..+6

18 move(s) deviate; the per-move table is on the full page.

### JE Jedah — `red` — most common delta +0 on 17/18; spread +0..+16

18 move(s) deviate; the per-move table is on the full page.

### LE Lei-Lei — `active` — most common delta +0 on 18/19; spread -1..+0

19 move(s) deviate; the per-move table is on the full page.

### LE Lei-Lei — `white` — most common delta +0 on 18/19; spread -9..+0

19 move(s) deviate; the per-move table is on the full page.

### LE Lei-Lei — `gauge_hit` — most common delta +0 on 18/19; spread -18..+0

19 move(s) deviate; the per-move table is on the full page.

### LE Lei-Lei — `red` — most common delta +0 on 18/19; spread -21..+0

19 move(s) deviate; the per-move table is on the full page.

### LI Lilith — `recovery` — most common delta +2 on 15/16; spread +2..+3

16 move(s) deviate; the per-move table is on the full page.

### LI Lilith — `white` — most common delta +0 on 18/22; spread -1..+7

22 move(s) deviate; the per-move table is on the full page.

### LI Lilith — `red` — most common delta +0 on 18/22; spread -1..+18

22 move(s) deviate; the per-move table is on the full page.

### MO Morrigan — `white` — most common delta +0 on 20/21; spread +0..+7

21 move(s) deviate; the per-move table is on the full page.

### MO Morrigan — `red` — most common delta +0 on 20/21; spread +0..+19

21 move(s) deviate; the per-move table is on the full page.

### QB Q-Bee — `white` — most common delta +0 on 14/15; spread +0..+7

15 move(s) deviate; the per-move table is on the full page.

### QB Q-Bee — `red` — most common delta +0 on 14/15; spread +0..+16

15 move(s) deviate; the per-move table is on the full page.

### SA Sasquatch — `startup` — most common delta +1 on 18/19; spread +0..+1

19 move(s) deviate; the per-move table is on the full page.

### SA Sasquatch — `white` — most common delta +0 on 18/19; spread +0..+8

19 move(s) deviate; the per-move table is on the full page.

### SA Sasquatch — `gauge_hit` — most common delta +0 on 17/19; spread -18..+0

19 move(s) deviate; the per-move table is on the full page.

### SA Sasquatch — `red` — most common delta +0 on 18/19; spread +0..+20

19 move(s) deviate; the per-move table is on the full page.

### VI Victor — `white` — most common delta +0 on 22/23; spread +0..+8

23 move(s) deviate; the per-move table is on the full page.

### VI Victor — `red` — most common delta +0 on 22/23; spread +0..+22

23 move(s) deviate; the per-move table is on the full page.

### ZA Zabel — `gauge_hit` — most common delta +0 on 23/24; spread -6..+0

24 move(s) deviate; the per-move table is on the full page.

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
- **Specials, supers, EX/ES moves, throws, pursuits and the `6`-prefixed command
  normals are not joined.** Each needs its own measured naming rig on vsavj, the way
  `tools/name_moves.py` did for the tenants. That is the bulk of the workbook's 730
  rows and it is untouched here.
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

