# Community cross-check — our derived frame data vs the community sources

**GENERATED** by `tools/crosscheck_framedata.py` from `tools/vanilla_frames.py`'s
derivation and the maintainer's workbook. Do not hand-edit; regenerate.
Gate: `tests/test_community_crosscheck.sh`.

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

The **crouching** (`0x0c-0x11`) and **jumping** (`0x12-0x17`) slots are the layout
measured on the three TENANTS by `tools/name_moves.py` (gate `tests/test_move_naming.sh`),
carried over and **not** re-measured per vanilla character — a stated bound, not a claim.
Specials, supers and the `6`-prefixed command normals are not joined at all.

## The headline: per-move agreement

A column is called INCONSISTENT if even ONE joined move deviates, which is a
deliberately strict test. The rate that says whether our derivation is sound is
per MOVE, over all 15 characters:

| column | convention | moves agreeing |
|---|---|---|
| `startup` | sheet = ours +1 — the sheet counts the first active frame as startup; ours counts the frames before it | **274/281** (97%) |
| `active` | sheet = ours +0 — identical | **271/281** (96%) |
| `recovery` | sheet = ours +2 — a 2-frame tail the sheet counts and our last node does not | **190/197** (96%) |
| `white` | sheet = ours +0 — identical — the record's +9 is the dealt white damage, unscaled | **268/281** (95%) |
| `gauge_hit` | sheet = ours +0 — identical once the sheet's own `gauge whiff` is subtracted | **274/281** (97%) |

So the two measurements corroborate each other on ~96% of every column we can
compare, under one stated convention per column. The residue is the worklist below.

## Verdicts, per character and column

| character | joined | startup | active | recovery | white | gauge_hit | red |
|---|---|---|---|---|---|---|---|
| **AN** Anakaris `0x06` | 15 | CONSTANT OFFSET (sheet = ours +1 on all 15) · n=15 | EXACT · n=15 | CONSTANT OFFSET (sheet = ours +2 on all 12) · n=12 | INCONSISTENT · n=15 | EXACT · n=15 | INCONSISTENT · n=15 |
| **AU** Aulbath `0x09` | 19 | INCONSISTENT · n=19 | INCONSISTENT · n=19 | CONSTANT OFFSET (sheet = ours +2 on all 12) · n=12 | EXACT · n=19 | EXACT · n=19 | EXACT · n=19 |
| **BI** Bishamon `0x08` | 18 | INCONSISTENT · n=17 | INCONSISTENT · n=17 | CONSTANT OFFSET (sheet = ours +2 on all 12) · n=12 | INCONSISTENT · n=17 | INCONSISTENT · n=17 | INCONSISTENT · n=17 |
| **BU** Bulleta `0x00` | 18 | INCONSISTENT · n=18 | INCONSISTENT · n=18 | CONSTANT OFFSET (sheet = ours +2 on all 13) · n=13 | EXACT · n=18 | EXACT · n=18 | INCONSISTENT · n=18 |
| **DE** Demitri `0x01` | 21 | CONSTANT OFFSET (sheet = ours +1 on all 21) · n=21 | EXACT · n=21 | CONSTANT OFFSET (sheet = ours +2 on all 15) · n=15 | EXACT · n=21 | EXACT · n=21 | EXACT · n=21 |
| **FE** Felicia `0x07` | 19 | CONSTANT OFFSET (sheet = ours +1 on all 19) · n=19 | INCONSISTENT · n=19 | CONSTANT OFFSET (sheet = ours +2 on all 13) · n=13 | EXACT · n=19 | INCONSISTENT · n=19 | EXACT · n=19 |
| **GA** Gallon `0x02` | 18 | CONSTANT OFFSET (sheet = ours +1 on all 18) · n=18 | EXACT · n=18 | CONSTANT OFFSET (sheet = ours +2 on all 12) · n=12 | EXACT · n=18 | EXACT · n=18 | EXACT · n=18 |
| **JE** Jedah `0x0f` | 18 | CONSTANT OFFSET (sheet = ours +1 on all 18) · n=18 | EXACT · n=18 | INCONSISTENT · n=12 | INCONSISTENT · n=18 | EXACT · n=18 | INCONSISTENT · n=18 |
| **LE** Lei-Lei `0x0d` | 19 | CONSTANT OFFSET (sheet = ours +1 on all 19) · n=19 | INCONSISTENT · n=19 | CONSTANT OFFSET (sheet = ours +2 on all 13) · n=13 | INCONSISTENT · n=19 | INCONSISTENT · n=19 | INCONSISTENT · n=19 |
| **LI** Lilith `0x0e` | 21 | CONSTANT OFFSET (sheet = ours +1 on all 21) · n=21 | EXACT · n=21 | INCONSISTENT · n=16 | INCONSISTENT · n=21 | EXACT · n=21 | INCONSISTENT · n=21 |
| **MO** Morrigan `0x05` | 21 | CONSTANT OFFSET (sheet = ours +1 on all 21) · n=21 | EXACT · n=21 | CONSTANT OFFSET (sheet = ours +2 on all 15) · n=15 | INCONSISTENT · n=21 | EXACT · n=21 | INCONSISTENT · n=21 |
| **QB** Q-Bee `0x0c` | 15 | CONSTANT OFFSET (sheet = ours +1 on all 15) · n=15 | EXACT · n=15 | CONSTANT OFFSET (sheet = ours +2 on all 10) · n=10 | INCONSISTENT · n=15 | EXACT · n=15 | INCONSISTENT · n=15 |
| **SA** Sasquatch `0x0a` | 19 | INCONSISTENT · n=19 | EXACT · n=19 | CONSTANT OFFSET (sheet = ours +2 on all 13) · n=13 | INCONSISTENT · n=19 | INCONSISTENT · n=19 | INCONSISTENT · n=19 |
| **VI** Victor `0x03` | 23 | INCONSISTENT · n=23 | INCONSISTENT · n=23 | CONSTANT OFFSET (sheet = ours +2 on all 17) · n=17 | INCONSISTENT · n=23 | EXACT · n=23 | INCONSISTENT · n=23 |
| **ZA** Zabel `0x04` | 18 | CONSTANT OFFSET (sheet = ours +1 on all 18) · n=18 | EXACT · n=18 | CONSTANT OFFSET (sheet = ours +2 on all 12) · n=12 | EXACT · n=18 | EXACT · n=18 | EXACT · n=18 |

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
alternative boxes for ONE hit — the victim's recent-hit ring refuses the second
([VSE-43]) — so only one of them can land. We take one; **the workbook sums them**:

| move | records (id, red/white) | workbook white | ours |
|---|---|---|---|
| MO 5HK | 17 (id 1, 14/7), 99 (id 1, 12/7) | 14 = 7+7 | 7 |
| QB 2HK | 13 (id 1, 11/9), 14 (id 1, 9/7) | 16 = 9+7 | 9 |
| SA 5HP | 7 (id 1, 15/9), 8 (id 1, 12/8) | 17 = 9+8 | 9 |
| VI 2HP | 15 (id 1, 15/8), 16 (id 1, 14/8) | 16 = 8+8 | 8 |
| JE 5HK | 8, 9, 56 — all id 1 | 13 = 7+6 | 7 |

**The hit rig confirms our reading and not theirs.** P1 performs each normal on a
victim whose HP is re-pinned before every event, and each DROP in P2's `+0x50` is
counted: our dedup-aware run count matches the engine's hit count on **75 of 78**
connecting events (`tests/expected/vanilla_hit_damage.tsv`). Summing every record,
as the workbook does, would not. So on this family ours is right and the
workbook is wrong, and the mechanism says why.

The same rig also showed the workbook is a **ROM-derived** source, not a
play-measured one: on a live connect the DEALT drops are neither figure (P2's
`+0x50` fell 9 where the record reads 11, its `+0x52` fell 14), yet the workbook
quotes the record values to the byte. That is why its `white damage` matches our
`+9` exactly, and it is the best evidence available about a method the page
itself never states.

### 3. Jedah's crouching recovery — OPEN

All six of Jedah's crouching normals (and Lilith's `2MK`) read `+3` where every
other character reads `+2`. Their chains are structurally ordinary — `hold`-ended,
nothing distinctive in node count or attack position — so nothing in our data
explains it, and by finding 1 the available instrument cannot resolve a one-frame
question. Left open rather than guessed.

## Every INCONSISTENT column, move by move

### AN Anakaris — `white` — most common delta +0 on 14/15; spread +0..+5

| move | sheet | ours | delta |
|---|---|---|---|
| 2HK | 8 | 8 | +0 |
| 2HP | 9 | 9 | +0 |
| 2LK | 5 | 5 | +0 |
| 2LP | 5 | 5 | +0 |
| 2MK | 7 | 7 | +0 |
| 2MP | 11 | 6 | +5 |
| 5HK | 10 | 10 | +0 |
| 5HP | 9 | 9 | +0 |
| 5LK | 5 | 5 | +0 |
| 5LP | 5 | 5 | +0 |
| 5MK | 9 | 9 | +0 |
| 5MP | 8 | 8 | +0 |
| J.HP | 10 | 10 | +0 |
| J.LP | 4 | 4 | +0 |
| J.MP | 9 | 9 | +0 |

### AN Anakaris — `red` — most common delta +0 on 14/15; spread +0..+15

| move | sheet | ours | delta |
|---|---|---|---|
| 2HK | 19 | 19 | +0 |
| 2HP | 20 | 20 | +0 |
| 2LK | 9 | 9 | +0 |
| 2LP | 9 | 9 | +0 |
| 2MK | 16 | 16 | +0 |
| 2MP | 33 | 18 | +15 |
| 5HK | 25 | 25 | +0 |
| 5HP | 22 | 22 | +0 |
| 5LK | 9 | 9 | +0 |
| 5LP | 9 | 9 | +0 |
| 5MK | 19 | 19 | +0 |
| 5MP | 18 | 18 | +0 |
| J.HP | 24 | 24 | +0 |
| J.LP | 10 | 10 | +0 |
| J.MP | 19 | 19 | +0 |

### AU Aulbath — `startup` — most common delta +1 on 18/19; spread +1..+2

| move | sheet | ours | delta |
|---|---|---|---|
| 2HK | 8 | 7 | +1 |
| 2HP | 7 | 6 | +1 |
| 2LK | 5 | 4 | +1 |
| 2LP | 5 | 4 | +1 |
| 2MK | 7 | 6 | +1 |
| 2MP | 6 | 5 | +1 |
| 5HK | 8 | 7 | +1 |
| 5HP | 11 | 9 | +2 |
| 5LK | 5 | 4 | +1 |
| 5LP | 5 | 4 | +1 |
| 5MK | 6 | 5 | +1 |
| 5MP | 6 | 5 | +1 |
| CL.5HK | 7 | 6 | +1 |
| J.HK | 9 | 8 | +1 |
| J.HP | 8 | 7 | +1 |
| J.LK | 5 | 4 | +1 |
| J.LP | 5 | 4 | +1 |
| J.MK | 7 | 6 | +1 |
| J.MP | 6 | 5 | +1 |

### AU Aulbath — `active` — most common delta +0 on 17/19; spread -1..+9

| move | sheet | ours | delta |
|---|---|---|---|
| 2HK | 4 | 4 | +0 |
| 2HP | 6 | 6 | +0 |
| 2LK | 3 | 3 | +0 |
| 2LP | 3 | 3 | +0 |
| 2MK | 6 | 6 | +0 |
| 2MP | 6 | 6 | +0 |
| 5HK | 4 | 4 | +0 |
| 5HP | 17 | 18 | -1 |
| 5LK | 3 | 3 | +0 |
| 5LP | 3 | 3 | +0 |
| 5MK | 3 | 3 | +0 |
| 5MP | 18 | 9 | +9 |
| CL.5HK | 4 | 4 | +0 |
| J.HK | 6 | 6 | +0 |
| J.HP | 6 | 6 | +0 |
| J.LK | 6 | 6 | +0 |
| J.LP | 6 | 6 | +0 |
| J.MK | 6 | 6 | +0 |
| J.MP | 5 | 5 | +0 |

### BI Bishamon — `startup` — most common delta +1 on 14/17; spread +0..+5

| move | sheet | ours | delta |
|---|---|---|---|
| 2HK | 11 | 10 | +1 |
| 2HP | 9 | 8 | +1 |
| 2LK | 5 | 4 | +1 |
| 2LP | 5 | 4 | +1 |
| 2MK | 6 | 5 | +1 |
| 2MP | 6 | 5 | +1 |
| 5HK | 7 | 6 | +1 |
| 5HP | 8 | 7 | +1 |
| 5LK | 5 | 4 | +1 |
| 5LP | 5 | 4 | +1 |
| 5MK | 5 | 5 | +0 |
| 5MP | 10 | 9 | +1 |
| J.HK | 8 | 7 | +1 |
| J.HP | 11 | 6 | +5 |
| J.LK | 5 | 4 | +1 |
| J.LP | 7 | 5 | +2 |
| J.MK | 6 | 5 | +1 |

### BI Bishamon — `active` — most common delta +0 on 15/17; spread -3..+0

| move | sheet | ours | delta |
|---|---|---|---|
| 2HK | 8 | 8 | +0 |
| 2HP | 4 | 4 | +0 |
| 2LK | 3 | 3 | +0 |
| 2LP | 3 | 3 | +0 |
| 2MK | 6 | 6 | +0 |
| 2MP | 3 | 3 | +0 |
| 5HK | 3 | 3 | +0 |
| 5HP | 9 | 9 | +0 |
| 5LK | 3 | 3 | +0 |
| 5LP | 3 | 3 | +0 |
| 5MK | 1 | 1 | +0 |
| 5MP | 12 | 12 | +0 |
| J.HK | 5 | 5 | +0 |
| J.HP | 3 | 6 | -3 |
| J.LK | 6 | 6 | +0 |
| J.LP | 3 | 6 | -3 |
| J.MK | 6 | 6 | +0 |

### BI Bishamon — `white` — most common delta +0 on 15/17; spread -8..+0

| move | sheet | ours | delta |
|---|---|---|---|
| 2HK | 15 | 15 | +0 |
| 2HP | 8 | 8 | +0 |
| 2LK | 3 | 3 | +0 |
| 2LP | 3 | 3 | +0 |
| 2MK | 8 | 8 | +0 |
| 2MP | 7 | 7 | +0 |
| 5HK | 8 | 8 | +0 |
| 5HP | 12 | 12 | +0 |
| 5LK | 4 | 4 | +0 |
| 5LP | 4 | 4 | +0 |
| 5MK | 7 | 7 | +0 |
| 5MP | 9 | 9 | +0 |
| J.HK | 9 | 9 | +0 |
| J.HP | 10 | 18 | -8 |
| J.LK | 4 | 4 | +0 |
| J.LP | 4 | 8 | -4 |
| J.MK | 7 | 7 | +0 |

### BI Bishamon — `gauge_hit` — most common delta +0 on 14/17; spread -18..+6

| move | sheet | ours | delta |
|---|---|---|---|
| 2HK | 42 | 36 | +6 |
| 2HP | 18 | 18 | +0 |
| 2LK | 6 | 6 | +0 |
| 2LP | 6 | 6 | +0 |
| 2MK | 12 | 12 | +0 |
| 2MP | 12 | 12 | +0 |
| 5HK | 18 | 18 | +0 |
| 5HP | 18 | 18 | +0 |
| 5LK | 6 | 6 | +0 |
| 5LP | 6 | 6 | +0 |
| 5MK | 12 | 12 | +0 |
| 5MP | 12 | 12 | +0 |
| J.HK | 18 | 18 | +0 |
| J.HP | 18 | 36 | -18 |
| J.LK | 6 | 6 | +0 |
| J.LP | 6 | 12 | -6 |
| J.MK | 12 | 12 | +0 |

### BI Bishamon — `red` — most common delta +0 on 15/17; spread -18..+0

| move | sheet | ours | delta |
|---|---|---|---|
| 2HK | 34 | 34 | +0 |
| 2HP | 19 | 19 | +0 |
| 2LK | 6 | 6 | +0 |
| 2LP | 6 | 6 | +0 |
| 2MK | 15 | 15 | +0 |
| 2MP | 15 | 15 | +0 |
| 5HK | 19 | 19 | +0 |
| 5HP | 22 | 22 | +0 |
| 5LK | 8 | 8 | +0 |
| 5LP | 8 | 8 | +0 |
| 5MK | 15 | 15 | +0 |
| 5MP | 17 | 17 | +0 |
| J.HK | 20 | 20 | +0 |
| J.HP | 23 | 41 | -18 |
| J.LK | 8 | 8 | +0 |
| J.LP | 8 | 15 | -7 |
| J.MK | 16 | 16 | +0 |

### BU Bulleta — `startup` — most common delta +1 on 17/18; spread -1..+1

| move | sheet | ours | delta |
|---|---|---|---|
| 2HK | 7 | 6 | +1 |
| 2HP | 9 | 8 | +1 |
| 2LK | 4 | 3 | +1 |
| 2LP | 4 | 3 | +1 |
| 2MK | 6 | 5 | +1 |
| 2MP | 6 | 5 | +1 |
| 5HP | 9 | 8 | +1 |
| 5LK | 6 | 5 | +1 |
| 5LP | 4 | 3 | +1 |
| 5MK | 8 | 7 | +1 |
| 5MP | 6 | 5 | +1 |
| CL.5LK | 5 | 4 | +1 |
| CL.5MP | 9 | 8 | +1 |
| J.HP | 13 | 12 | +1 |
| J.LK | 5 | 4 | +1 |
| J.LP | 5 | 4 | +1 |
| J.MK | 7 | 6 | +1 |
| J.MP | 5 | 6 | -1 |

### BU Bulleta — `active` — most common delta +0 on 16/18; spread +0..+1

| move | sheet | ours | delta |
|---|---|---|---|
| 2HK | 3 | 3 | +0 |
| 2HP | 21 | 21 | +0 |
| 2LK | 4 | 4 | +0 |
| 2LP | 4 | 4 | +0 |
| 2MK | 3 | 3 | +0 |
| 2MP | 3 | 3 | +0 |
| 5HP | 21 | 21 | +0 |
| 5LK | 4 | 4 | +0 |
| 5LP | 4 | 4 | +0 |
| 5MK | 6 | 6 | +0 |
| 5MP | 3 | 3 | +0 |
| CL.5LK | 5 | 5 | +0 |
| CL.5MP | 4 | 4 | +0 |
| J.HP | 6 | 6 | +0 |
| J.LK | 2 | 2 | +0 |
| J.LP | 6 | 6 | +0 |
| J.MK | 7 | 6 | +1 |
| J.MP | 4 | 3 | +1 |

### BU Bulleta — `red` — most common delta +0 on 16/18; spread -1..+0

| move | sheet | ours | delta |
|---|---|---|---|
| 2HK | 17 | 17 | +0 |
| 2HP | 49 | 49 | +0 |
| 2LK | 7 | 7 | +0 |
| 2LP | 7 | 7 | +0 |
| 2MK | 15 | 15 | +0 |
| 2MP | 16 | 16 | +0 |
| 5HP | 49 | 49 | +0 |
| 5LK | 7 | 7 | +0 |
| 5LP | 7 | 7 | +0 |
| 5MK | 17 | 17 | +0 |
| 5MP | 16 | 16 | +0 |
| CL.5LK | 7 | 7 | +0 |
| CL.5MP | 17 | 17 | +0 |
| J.HP | 18 | 18 | +0 |
| J.LK | 8 | 8 | +0 |
| J.LP | 8 | 8 | +0 |
| J.MK | 16 | 17 | -1 |
| J.MP | 16 | 17 | -1 |

### FE Felicia — `active` — most common delta +0 on 17/19; spread -1..+2

| move | sheet | ours | delta |
|---|---|---|---|
| 2HK | 2 | 2 | +0 |
| 2HP | 6 | 6 | +0 |
| 2LK | 3 | 3 | +0 |
| 2LP | 3 | 3 | +0 |
| 2MK | 3 | 3 | +0 |
| 2MP | 4 | 4 | +0 |
| 5HK | 6 | 6 | +0 |
| 5HP | 7 | 7 | +0 |
| 5LK | 4 | 4 | +0 |
| 5LP | 3 | 3 | +0 |
| 5MK | 3 | 3 | +0 |
| 5MP | 3 | 3 | +0 |
| CL.5HK | 5 | 5 | +0 |
| J.HK | 6 | 4 | +2 |
| J.HP | 6 | 6 | +0 |
| J.LK | 4 | 5 | -1 |
| J.LP | 6 | 6 | +0 |
| J.MK | 6 | 6 | +0 |
| J.MP | 8 | 8 | +0 |

### FE Felicia — `gauge_hit` — most common delta +0 on 18/19; spread -10..+0

| move | sheet | ours | delta |
|---|---|---|---|
| 2HK | 18 | 18 | +0 |
| 2HP | 18 | 18 | +0 |
| 2LK | 6 | 6 | +0 |
| 2LP | 6 | 6 | +0 |
| 2MK | 12 | 12 | +0 |
| 2MP | 12 | 12 | +0 |
| 5HK | 18 | 18 | +0 |
| 5HP | 18 | 18 | +0 |
| 5LK | 6 | 6 | +0 |
| 5LP | 6 | 6 | +0 |
| 5MK | 12 | 12 | +0 |
| 5MP | 2 | 12 | -10 |
| CL.5HK | 18 | 18 | +0 |
| J.HK | 18 | 18 | +0 |
| J.HP | 18 | 18 | +0 |
| J.LK | 6 | 6 | +0 |
| J.LP | 6 | 6 | +0 |
| J.MK | 12 | 12 | +0 |
| J.MP | 12 | 12 | +0 |

### JE Jedah — `recovery` — most common delta +3 on 6/12; spread +2..+3

| move | sheet | ours | delta |
|---|---|---|---|
| 2HK | 34 | 31 | +3 |
| 2HP | 44 | 41 | +3 |
| 2LK | 8 | 5 | +3 |
| 2LP | 10 | 7 | +3 |
| 2MK | 14 | 11 | +3 |
| 2MP | 16 | 13 | +3 |
| 5HK | 36 | 34 | +2 |
| 5HP | 38 | 36 | +2 |
| 5LK | 7 | 5 | +2 |
| 5LP | 10 | 8 | +2 |
| 5MK | 26 | 24 | +2 |
| 5MP | 19 | 17 | +2 |

### JE Jedah — `white` — most common delta +0 on 17/18; spread +0..+6

| move | sheet | ours | delta |
|---|---|---|---|
| 2HK | 8 | 8 | +0 |
| 2HP | 9 | 9 | +0 |
| 2LK | 4 | 4 | +0 |
| 2LP | 3 | 3 | +0 |
| 2MK | 7 | 7 | +0 |
| 2MP | 7 | 7 | +0 |
| 5HK | 13 | 7 | +6 |
| 5HP | 9 | 9 | +0 |
| 5LK | 3 | 3 | +0 |
| 5LP | 3 | 3 | +0 |
| 5MK | 6 | 6 | +0 |
| 5MP | 7 | 7 | +0 |
| J.HK | 9 | 9 | +0 |
| J.HP | 9 | 9 | +0 |
| J.LK | 4 | 4 | +0 |
| J.LP | 4 | 4 | +0 |
| J.MK | 7 | 7 | +0 |
| J.MP | 7 | 7 | +0 |

### JE Jedah — `red` — most common delta +0 on 17/18; spread +0..+16

| move | sheet | ours | delta |
|---|---|---|---|
| 2HK | 21 | 21 | +0 |
| 2HP | 24 | 24 | +0 |
| 2LK | 8 | 8 | +0 |
| 2LP | 8 | 8 | +0 |
| 2MK | 17 | 17 | +0 |
| 2MP | 16 | 16 | +0 |
| 5HK | 36 | 20 | +16 |
| 5HP | 24 | 24 | +0 |
| 5LK | 8 | 8 | +0 |
| 5LP | 8 | 8 | +0 |
| 5MK | 17 | 17 | +0 |
| 5MP | 16 | 16 | +0 |
| J.HK | 23 | 23 | +0 |
| J.HP | 24 | 24 | +0 |
| J.LK | 9 | 9 | +0 |
| J.LP | 9 | 9 | +0 |
| J.MK | 17 | 17 | +0 |
| J.MP | 16 | 16 | +0 |

### LE Lei-Lei — `active` — most common delta +0 on 18/19; spread -1..+0

| move | sheet | ours | delta |
|---|---|---|---|
| 2HK | 6 | 6 | +0 |
| 2HP | 14 | 14 | +0 |
| 2LK | 3 | 3 | +0 |
| 2LP | 3 | 3 | +0 |
| 2MK | 3 | 3 | +0 |
| 2MP | 6 | 6 | +0 |
| 5HK | 4 | 4 | +0 |
| 5HP | 12 | 12 | +0 |
| 5LK | 3 | 3 | +0 |
| 5LP | 3 | 3 | +0 |
| 5MK | 8 | 8 | +0 |
| 5MP | 3 | 3 | +0 |
| CL.5HP | 3 | 3 | +0 |
| J.HK | 5 | 5 | +0 |
| J.HP | 11 | 12 | -1 |
| J.LK | 6 | 6 | +0 |
| J.LP | 6 | 6 | +0 |
| J.MK | 6 | 6 | +0 |
| J.MP | 10 | 10 | +0 |

### LE Lei-Lei — `white` — most common delta +0 on 18/19; spread -9..+0

| move | sheet | ours | delta |
|---|---|---|---|
| 2HK | 8 | 8 | +0 |
| 2HP | 7 | 7 | +0 |
| 2LK | 4 | 4 | +0 |
| 2LP | 3 | 3 | +0 |
| 2MK | 7 | 7 | +0 |
| 2MP | 6 | 6 | +0 |
| 5HK | 7 | 7 | +0 |
| 5HP | 6 | 6 | +0 |
| 5LK | 3 | 3 | +0 |
| 5LP | 3 | 3 | +0 |
| 5MK | 6 | 6 | +0 |
| 5MP | 6 | 6 | +0 |
| CL.5HP | 8 | 8 | +0 |
| J.HK | 8 | 8 | +0 |
| J.HP | 9 | 18 | -9 |
| J.LK | 4 | 4 | +0 |
| J.LP | 4 | 4 | +0 |
| J.MK | 7 | 7 | +0 |
| J.MP | 6 | 6 | +0 |

### LE Lei-Lei — `gauge_hit` — most common delta +0 on 18/19; spread -18..+0

| move | sheet | ours | delta |
|---|---|---|---|
| 2HK | 18 | 18 | +0 |
| 2HP | 18 | 18 | +0 |
| 2LK | 6 | 6 | +0 |
| 2LP | 6 | 6 | +0 |
| 2MK | 12 | 12 | +0 |
| 2MP | 12 | 12 | +0 |
| 5HK | 18 | 18 | +0 |
| 5HP | 18 | 18 | +0 |
| 5LK | 6 | 6 | +0 |
| 5LP | 6 | 6 | +0 |
| 5MK | 12 | 12 | +0 |
| 5MP | 12 | 12 | +0 |
| CL.5HP | 18 | 18 | +0 |
| J.HK | 18 | 18 | +0 |
| J.HP | 18 | 36 | -18 |
| J.LK | 6 | 6 | +0 |
| J.LP | 6 | 6 | +0 |
| J.MK | 12 | 12 | +0 |
| J.MP | 12 | 12 | +0 |

### LE Lei-Lei — `red` — most common delta +0 on 18/19; spread -21..+0

| move | sheet | ours | delta |
|---|---|---|---|
| 2HK | 20 | 20 | +0 |
| 2HP | 18 | 18 | +0 |
| 2LK | 7 | 7 | +0 |
| 2LP | 7 | 7 | +0 |
| 2MK | 15 | 15 | +0 |
| 2MP | 16 | 16 | +0 |
| 5HK | 20 | 20 | +0 |
| 5HP | 18 | 18 | +0 |
| 5LK | 7 | 7 | +0 |
| 5LP | 7 | 7 | +0 |
| 5MK | 17 | 17 | +0 |
| 5MP | 16 | 16 | +0 |
| CL.5HP | 22 | 22 | +0 |
| J.HK | 20 | 20 | +0 |
| J.HP | 21 | 42 | -21 |
| J.LK | 8 | 8 | +0 |
| J.LP | 8 | 8 | +0 |
| J.MK | 17 | 17 | +0 |
| J.MP | 16 | 16 | +0 |

### LI Lilith — `recovery` — most common delta +2 on 15/16; spread +2..+3

| move | sheet | ours | delta |
|---|---|---|---|
| 2HK | 27 | 25 | +2 |
| 2HP | 24 | 22 | +2 |
| 2LK | 10 | 8 | +2 |
| 2LP | 8 | 6 | +2 |
| 2MK | 24 | 21 | +3 |
| 2MP | 18 | 16 | +2 |
| 5HK | 30 | 28 | +2 |
| 5HP | 26 | 24 | +2 |
| 5LK | 8 | 6 | +2 |
| 5LP | 7 | 5 | +2 |
| 5MK | 16 | 14 | +2 |
| 5MP | 17 | 15 | +2 |
| CL.5HK | 27 | 25 | +2 |
| CL.5HP | 22 | 20 | +2 |
| CL.5LK | 10 | 8 | +2 |
| CL.5MP | 22 | 20 | +2 |

### LI Lilith — `white` — most common delta +0 on 18/21; spread -1..+7

| move | sheet | ours | delta |
|---|---|---|---|
| 2HK | 8 | 8 | +0 |
| 2HP | 8 | 8 | +0 |
| 2LK | 2 | 2 | +0 |
| 2LP | 3 | 3 | +0 |
| 2MK | 6 | 6 | +0 |
| 2MP | 6 | 6 | +0 |
| 5HK | 10 | 10 | +0 |
| 5HP | 6 | 6 | +0 |
| 5LK | 4 | 4 | +0 |
| 5LP | 3 | 3 | +0 |
| 5MK | 6 | 6 | +0 |
| 5MP | 6 | 6 | +0 |
| CL.5HK | 8 | 8 | +0 |
| CL.5HP | 7 | 7 | +0 |
| CL.5LK | 4 | 4 | +0 |
| CL.5MP | 6 | 6 | +0 |
| J.HK | 14 | 7 | +7 |
| J.HP | 8 | 8 | +0 |
| J.LK | 4 | 2 | +2 |
| J.LP | 4 | 4 | +0 |
| J.MP | 6 | 7 | -1 |

### LI Lilith — `red` — most common delta +0 on 18/21; spread -1..+18

| move | sheet | ours | delta |
|---|---|---|---|
| 2HK | 18 | 18 | +0 |
| 2HP | 20 | 20 | +0 |
| 2LK | 5 | 5 | +0 |
| 2LP | 6 | 6 | +0 |
| 2MK | 15 | 15 | +0 |
| 2MP | 15 | 15 | +0 |
| 5HK | 26 | 26 | +0 |
| 5HP | 19 | 19 | +0 |
| 5LK | 7 | 7 | +0 |
| 5LP | 6 | 6 | +0 |
| 5MK | 15 | 15 | +0 |
| 5MP | 15 | 15 | +0 |
| CL.5HK | 24 | 24 | +0 |
| CL.5HP | 20 | 20 | +0 |
| CL.5LK | 7 | 7 | +0 |
| CL.5MP | 16 | 16 | +0 |
| J.HK | 38 | 20 | +18 |
| J.HP | 20 | 20 | +0 |
| J.LK | 8 | 5 | +3 |
| J.LP | 8 | 8 | +0 |
| J.MP | 16 | 17 | -1 |

### MO Morrigan — `white` — most common delta +0 on 20/21; spread +0..+7

| move | sheet | ours | delta |
|---|---|---|---|
| 2HK | 7 | 7 | +0 |
| 2HP | 8 | 8 | +0 |
| 2LK | 3 | 3 | +0 |
| 2LP | 2 | 2 | +0 |
| 2MK | 6 | 6 | +0 |
| 2MP | 5 | 5 | +0 |
| 5HK | 14 | 7 | +7 |
| 5HP | 6 | 6 | +0 |
| 5LK | 3 | 3 | +0 |
| 5LP | 3 | 3 | +0 |
| 5MK | 6 | 6 | +0 |
| 5MP | 6 | 6 | +0 |
| CL.5HK | 8 | 8 | +0 |
| CL.5HP | 7 | 7 | +0 |
| CL.5MP | 6 | 6 | +0 |
| J.HK | 7 | 7 | +0 |
| J.HP | 7 | 7 | +0 |
| J.LK | 3 | 3 | +0 |
| J.LP | 3 | 3 | +0 |
| J.MK | 6 | 6 | +0 |
| J.MP | 6 | 6 | +0 |

### MO Morrigan — `red` — most common delta +0 on 20/21; spread +0..+19

| move | sheet | ours | delta |
|---|---|---|---|
| 2HK | 17 | 17 | +0 |
| 2HP | 20 | 20 | +0 |
| 2LK | 5 | 5 | +0 |
| 2LP | 6 | 6 | +0 |
| 2MK | 15 | 15 | +0 |
| 2MP | 14 | 14 | +0 |
| 5HK | 40 | 21 | +19 |
| 5HP | 19 | 19 | +0 |
| 5LK | 6 | 6 | +0 |
| 5LP | 6 | 6 | +0 |
| 5MK | 15 | 15 | +0 |
| 5MP | 15 | 15 | +0 |
| CL.5HK | 24 | 24 | +0 |
| CL.5HP | 20 | 20 | +0 |
| CL.5MP | 16 | 16 | +0 |
| J.HK | 20 | 20 | +0 |
| J.HP | 19 | 19 | +0 |
| J.LK | 7 | 7 | +0 |
| J.LP | 7 | 7 | +0 |
| J.MK | 15 | 15 | +0 |
| J.MP | 16 | 16 | +0 |

### QB Q-Bee — `white` — most common delta +0 on 14/15; spread +0..+7

| move | sheet | ours | delta |
|---|---|---|---|
| 2HK | 16 | 9 | +7 |
| 2LK | 2 | 2 | +0 |
| 2LP | 3 | 3 | +0 |
| 2MK | 6 | 6 | +0 |
| 2MP | 6 | 6 | +0 |
| 5HK | 8 | 8 | +0 |
| 5LK | 3 | 3 | +0 |
| 5LP | 3 | 3 | +0 |
| 5MK | 6 | 6 | +0 |
| 5MP | 7 | 7 | +0 |
| J.HK | 8 | 8 | +0 |
| J.LK | 4 | 4 | +0 |
| J.LP | 3 | 3 | +0 |
| J.MK | 6 | 6 | +0 |
| J.MP | 7 | 7 | +0 |

### QB Q-Bee — `red` — most common delta +0 on 14/15; spread +0..+16

| move | sheet | ours | delta |
|---|---|---|---|
| 2HK | 36 | 20 | +16 |
| 2LK | 6 | 6 | +0 |
| 2LP | 7 | 7 | +0 |
| 2MK | 16 | 16 | +0 |
| 2MP | 16 | 16 | +0 |
| 5HK | 24 | 24 | +0 |
| 5LK | 7 | 7 | +0 |
| 5LP | 7 | 7 | +0 |
| 5MK | 17 | 17 | +0 |
| 5MP | 16 | 16 | +0 |
| J.HK | 22 | 22 | +0 |
| J.LK | 8 | 8 | +0 |
| J.LP | 8 | 8 | +0 |
| J.MK | 17 | 17 | +0 |
| J.MP | 16 | 16 | +0 |

### SA Sasquatch — `startup` — most common delta +1 on 18/19; spread +0..+1

| move | sheet | ours | delta |
|---|---|---|---|
| 2HK | 10 | 9 | +1 |
| 2HP | 7 | 6 | +1 |
| 2LK | 5 | 4 | +1 |
| 2LP | 5 | 4 | +1 |
| 2MK | 6 | 5 | +1 |
| 2MP | 6 | 5 | +1 |
| 5HK | 8 | 7 | +1 |
| 5HP | 8 | 7 | +1 |
| 5LK | 5 | 4 | +1 |
| 5LP | 5 | 4 | +1 |
| 5MK | 7 | 6 | +1 |
| 5MP | 6 | 5 | +1 |
| CL.5LK | 5 | 4 | +1 |
| J.HK | 8 | 7 | +1 |
| J.HP | 10 | 9 | +1 |
| J.LK | 5 | 4 | +1 |
| J.LP | 5 | 4 | +1 |
| J.MK | 6 | 5 | +1 |
| J.MP | 5 | 5 | +0 |

### SA Sasquatch — `white` — most common delta +0 on 18/19; spread +0..+8

| move | sheet | ours | delta |
|---|---|---|---|
| 2HK | 8 | 8 | +0 |
| 2HP | 17 | 17 | +0 |
| 2LK | 4 | 4 | +0 |
| 2LP | 4 | 4 | +0 |
| 2MK | 8 | 8 | +0 |
| 2MP | 7 | 7 | +0 |
| 5HK | 16 | 16 | +0 |
| 5HP | 17 | 9 | +8 |
| 5LK | 4 | 4 | +0 |
| 5LP | 5 | 5 | +0 |
| 5MK | 8 | 8 | +0 |
| 5MP | 7 | 7 | +0 |
| CL.5LK | 4 | 4 | +0 |
| J.HK | 8 | 8 | +0 |
| J.HP | 9 | 9 | +0 |
| J.LK | 5 | 5 | +0 |
| J.LP | 5 | 5 | +0 |
| J.MK | 7 | 7 | +0 |
| J.MP | 8 | 8 | +0 |

### SA Sasquatch — `gauge_hit` — most common delta +0 on 17/19; spread -18..+0

| move | sheet | ours | delta |
|---|---|---|---|
| 2HK | 18 | 18 | +0 |
| 2HP | 18 | 36 | -18 |
| 2LK | 6 | 6 | +0 |
| 2LP | 6 | 6 | +0 |
| 2MK | 12 | 12 | +0 |
| 2MP | 12 | 12 | +0 |
| 5HK | 18 | 36 | -18 |
| 5HP | 18 | 18 | +0 |
| 5LK | 6 | 6 | +0 |
| 5LP | 6 | 6 | +0 |
| 5MK | 12 | 12 | +0 |
| 5MP | 12 | 12 | +0 |
| CL.5LK | 6 | 6 | +0 |
| J.HK | 18 | 18 | +0 |
| J.HP | 18 | 18 | +0 |
| J.LK | 6 | 6 | +0 |
| J.LP | 6 | 6 | +0 |
| J.MK | 12 | 12 | +0 |
| J.MP | 12 | 12 | +0 |

### SA Sasquatch — `red` — most common delta +0 on 18/19; spread +0..+20

| move | sheet | ours | delta |
|---|---|---|---|
| 2HK | 18 | 18 | +0 |
| 2HP | 43 | 43 | +0 |
| 2LK | 7 | 7 | +0 |
| 2LP | 8 | 8 | +0 |
| 2MK | 17 | 17 | +0 |
| 2MP | 17 | 17 | +0 |
| 5HK | 44 | 44 | +0 |
| 5HP | 44 | 24 | +20 |
| 5LK | 9 | 9 | +0 |
| 5LP | 9 | 9 | +0 |
| 5MK | 18 | 18 | +0 |
| 5MP | 17 | 17 | +0 |
| CL.5LK | 9 | 9 | +0 |
| J.HK | 22 | 22 | +0 |
| J.HP | 21 | 21 | +0 |
| J.LK | 9 | 9 | +0 |
| J.LP | 9 | 9 | +0 |
| J.MK | 17 | 17 | +0 |
| J.MP | 18 | 18 | +0 |

### VI Victor — `startup` — most common delta +1 on 22/23; spread +1..+4

| move | sheet | ours | delta |
|---|---|---|---|
| 2HK | 14 | 13 | +1 |
| 2HP | 11 | 10 | +1 |
| 2LK | 6 | 5 | +1 |
| 2LP | 5 | 4 | +1 |
| 2MK | 10 | 9 | +1 |
| 2MP | 9 | 8 | +1 |
| 5HK | 13 | 12 | +1 |
| 5HP | 13 | 12 | +1 |
| 5LK | 6 | 5 | +1 |
| 5LP | 5 | 4 | +1 |
| 5MK | 9 | 8 | +1 |
| 5MP | 9 | 8 | +1 |
| CL.5HK | 16 | 15 | +1 |
| CL.5HP | 11 | 10 | +1 |
| CL.5LK | 5 | 4 | +1 |
| CL.5MK | 11 | 10 | +1 |
| CL.5MP | 9 | 8 | +1 |
| J.HK | 15 | 14 | +1 |
| J.HP | 12 | 8 | +4 |
| J.LK | 6 | 5 | +1 |
| J.LP | 9 | 8 | +1 |
| J.MK | 9 | 8 | +1 |
| J.MP | 10 | 9 | +1 |

### VI Victor — `active` — most common delta +0 on 22/23; spread +0..+1

| move | sheet | ours | delta |
|---|---|---|---|
| 2HK | 2 | 2 | +0 |
| 2HP | 6 | 6 | +0 |
| 2LK | 3 | 3 | +0 |
| 2LP | 3 | 3 | +0 |
| 2MK | 2 | 2 | +0 |
| 2MP | 3 | 3 | +0 |
| 5HK | 6 | 6 | +0 |
| 5HP | 3 | 3 | +0 |
| 5LK | 3 | 3 | +0 |
| 5LP | 2 | 2 | +0 |
| 5MK | 3 | 3 | +0 |
| 5MP | 3 | 3 | +0 |
| CL.5HK | 3 | 3 | +0 |
| CL.5HP | 4 | 4 | +0 |
| CL.5LK | 3 | 3 | +0 |
| CL.5MK | 3 | 3 | +0 |
| CL.5MP | 3 | 3 | +0 |
| J.HK | 2 | 2 | +0 |
| J.HP | 6 | 5 | +1 |
| J.LK | 5 | 5 | +0 |
| J.LP | 5 | 5 | +0 |
| J.MK | 4 | 4 | +0 |
| J.MP | 5 | 5 | +0 |

### VI Victor — `white` — most common delta +0 on 21/23; spread -1..+8

| move | sheet | ours | delta |
|---|---|---|---|
| 2HK | 8 | 8 | +0 |
| 2HP | 16 | 8 | +8 |
| 2LK | 4 | 4 | +0 |
| 2LP | 4 | 4 | +0 |
| 2MK | 6 | 6 | +0 |
| 2MP | 6 | 6 | +0 |
| 5HK | 8 | 8 | +0 |
| 5HP | 8 | 8 | +0 |
| 5LK | 4 | 4 | +0 |
| 5LP | 4 | 4 | +0 |
| 5MK | 7 | 7 | +0 |
| 5MP | 6 | 6 | +0 |
| CL.5HK | 9 | 9 | +0 |
| CL.5HP | 9 | 9 | +0 |
| CL.5LK | 5 | 5 | +0 |
| CL.5MK | 8 | 8 | +0 |
| CL.5MP | 7 | 7 | +0 |
| J.HK | 8 | 8 | +0 |
| J.HP | 7 | 8 | -1 |
| J.LK | 4 | 4 | +0 |
| J.LP | 4 | 4 | +0 |
| J.MK | 7 | 7 | +0 |
| J.MP | 6 | 6 | +0 |

### VI Victor — `red` — most common delta +0 on 21/23; spread -4..+22

| move | sheet | ours | delta |
|---|---|---|---|
| 2HK | 20 | 20 | +0 |
| 2HP | 45 | 23 | +22 |
| 2LK | 8 | 8 | +0 |
| 2LP | 9 | 9 | +0 |
| 2MK | 17 | 17 | +0 |
| 2MP | 18 | 18 | +0 |
| 5HK | 23 | 23 | +0 |
| 5HP | 23 | 23 | +0 |
| 5LK | 9 | 9 | +0 |
| 5LP | 9 | 9 | +0 |
| 5MK | 19 | 19 | +0 |
| 5MP | 18 | 18 | +0 |
| CL.5HK | 26 | 26 | +0 |
| CL.5HP | 25 | 25 | +0 |
| CL.5LK | 10 | 10 | +0 |
| CL.5MK | 21 | 21 | +0 |
| CL.5MP | 20 | 20 | +0 |
| J.HK | 22 | 22 | +0 |
| J.HP | 20 | 24 | -4 |
| J.LK | 9 | 9 | +0 |
| J.LP | 9 | 9 | +0 |
| J.MK | 18 | 18 | +0 |
| J.MP | 18 | 18 | +0 |

## What is NOT known

- **The startup `+1` and recovery `+2` offsets are NAMED, not adjudicated.** The
  instrument available samples at video-frame rate and 16% of its frames carry two
  engine ticks, so it cannot resolve a one-frame question. A tick-accurate
  instrument would settle whether either side is counting wrongly; neither is
  assumed to be.
- **Jedah's crouching recovery (+3, not +2) is unexplained** — see the arbitration
  section. Lilith's `2MK` behaves the same way.
- **The aerial startup/active outliers are untouched** (BI `J.HP`/`J.LP`, BU `J.MP`,
  VI `J.HP`, FE `J.HK`/`J.LK`, SA `J.MP`). A jumping normal's chain is entered from
  the jump, and no rig here separated the two.
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

