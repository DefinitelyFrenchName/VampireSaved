# SCOPE — porting the beam's effect machine (14z-70g)

Status: **SUPERSEDED — the beam SHIPPED in 14z-71 (`build/hui25`,
maintainer-confirmed clean on all three variants).** Kept as the record of
how the port was scoped before building, and because several of its
measurements are still the reference. **But its central premise is wrong**:
it frames the port as needing the vs2-only routine at `0x093460` reached by
an "owner-gated diversion". The real cause was three stacked defects in the
sprite-list layer — a stub CLASS row, a missing LIST TYPE, and a
game-specific code BIAS — none of which this document anticipates.

**Read instead:** `../game/engine_internals.md` "The sprite-list DRAWER",
`../game/atlas/sprite_lists.md`, and `porting_sprite_lists.md`.

Original status line: *scoped, not built. Written for maintainer review
before any shipped byte changes (the standing "plan and scope first" rule).*

## What is broken, measured

The 236P freeze ray's visual object **exists on both legs but is never
DRIVEN into its beam states on ours**. The freeze itself works, which is
why the symptom is "muzzle orb and beam both missing while the opponent
still ices".

> **CORRECTION (open item B, run before building — this is why B went
> first).** An earlier reading of this said the object is "never
> created". That was wrong. The effect-type byte `$FFD404` is written
> **17 times on each leg at IDENTICAL frames** (1, 11, 12, 21, 22, 74,
> 469, 471, 473, 820, 824, 830, 893, 2074, 2308, 2310, 2366), with the
> PCs pairing cleanly (`0x015668`<->`0x016F56`,
> `0x015822`<->`0x0170DA`). The object is set up identically on both
> legs. The f3150+ header writes counted below are **sub-state updates
> on an existing object**, not creation — and none of them is a write to
> the effect-type byte on either leg.
>
> The machine still has to be ported (it is genuinely absent from our
> build), but the question it must answer changed: not "why is nothing
> created" but **"why is the existing object never dispatched into
> machine #7 during the move"**.

Rig: `tests/replays/hui/83b_hui_ray_2p.rpl` (maintainer-confirmed:
LP/MP/HP look identical; 236+2P is the girthier ES beam; 236+K is the low
beam). Measured on the pool the atlas already documents —
`docs/project/tables/reconciliation.md`, `$FFD400/0x80/cat14`,
"GEOMETRIES ARE IDENTICAL in both games, pool-for-pool", which is what
makes the address comparable across legs.

| | native | ours |
|---|---|---|
| beam sprite-list reads | 2 (`PC:0x019E0E`) | **0** |
| anim-pointer writes, f3160-3210 | 26 (`PC:0x01378A`) | **0** |
| pool-slot HEADER writes, f3150-3210 | 30 (`PC:0x0934B4`) | **0** |

## What has to be ported

**The creator is a vs2-only effect-object state machine.** Signature
`move.b 0x382(A4),D0 ; cmp.b 0x0A(A6),D0` (the id gate) appears:

```
vs2 (native)   : 4 machines   0x8FAD2   0x91562   0x934B4   0x937BA
vsavj pristine : 2 machines   0x813A8   0x82CD0
our build      : 2  (unchanged)
```

Paired by byte-identity of the machine bodies:

| vs2 | best vsavj match | identical | verdict |
|---|---|---|---|
| `0x8FAD2` | `0x813A8` | 96.6% | shared |
| `0x91562` | `0x82CD0` | 95.4% | shared |
| **`0x934B4`** | `0x813A8` (already claimed) | 94.9% | **vs2-only** — a duplicate of that family |
| **`0x937BA`** | `0x813A8` | 36.4% | **vs2-only** — structurally different |

Extents (entry = the sub-state `jmp`, body = through the last state):

| machine | entry | state table | states | body | size |
|---|---|---|---|---|---|
| beam | `0x0934A8` | `0x0934AC` | 2 | `0x0934B0-0x0934DE` | **0x36** |
| second | `0x0937AE` | `0x0937B2` | 2 | `0x0937B6-0x0937F8` | **0x4A** |

Both are tiny. Neither is inside any ported root: `x088512` ends at
`0x08C0AA`, the `0x905AE+0x300` root ends at `0x0908AE`.

## How it is entered

Outer dispatcher `jmp 0x08D4A4`, preceded by `move.b 0x04(A6),D0` — the
object's **effect TYPE** — indexing a 22-entry word table at `0x08D4A8`:

```
#4 -> 0928D6   #6 -> 091224   #7 -> 0934A8  <== the BEAM machine
#10 -> 08F4A8  #12 -> 0916D6  #20 -> 0950AF   #21 -> 092361
```

So the beam is **effect type 7**. The dispatcher is likewise outside every
ported root.

## THE CHAIN, resolved (14z-70h) — where the two builds part company

Walking down from the shared dispatcher, comparing both legs at each
link. **Most of this path already exists on our build**, which is the
good news and it shrinks the port considerably:

| link | native | ours | status |
|---|---|---|---|
| effect-type reader | `0x093080` (950 reads) | `0x0844F4` (950) | **shared** |
| its dispatch table | `0x093088`, 32 entries | `0x0844FC`, 32 entries | **shared, same shape** |
| entry #2 target | `0x093442` | `0x08471A` | **shared** — byte-identical for 0x1C bytes, both ending `jmp` to the paired engine tail (`$01581A` <-> `$0170D2`) |
| the next routine | **`0x093460`** | **absent** | **vs2-only** |
| beam machine | `0x0934A8` | absent | **vs2-only** |

The vs2-only routine is four instructions:

```
093460  movea.w 0x30(A6),A4      ; the OWNER pointer -> A4
093464  move.b  0x04(A6),D0      ; effect type
093468  move.w  (0x06,pc,D0.w),D1
09346C  jmp     (0x02,pc,D1.w)   ; table 0x093470, #22 -> the beam machine 0x0934A8
```

That `movea.w 0x30(A6),A4` is why the machine's id gate works: A4 is the
OWNER, so `move.b 0x382(A4),D0` reads the owner's character id.

Runtime confirmation of exactly this split: watching READS of the
effect-type byte `$FFD404`, native shows **950 from the shared reader
`0x093080` plus 60 from the vs2-only `0x093468`**; ours shows **950 from
`0x0844F4` and nothing else**. Our build walks the shared path every
frame and simply has nowhere to go for the beam.

**Consequence for the port — it is smaller than first scoped.** We do NOT
need to port the outer dispatcher or the type-2 routine; both exist. We
need the vs2-only routine at `0x093460` (a handful of bytes plus its
32-entry table at `0x093470`), the beam machine `0x0934A8` (0x36), and
whatever the machine's closure pulls in. The hook is a single
owner-gated diversion at the tail of the shared routine.

## OPEN — must be resolved before building

**A. RESOLVED by the chain table above** — and NOT the way it was
framed. There is no dead entry to repoint: the shared dispatcher and its
type-2 routine exist on both legs and are byte-identical, so the
divergence is a vs2-only routine that follows them. The hook is therefore
an **owner-gated diversion**, not a table edit: only objects whose owner
(`0x30(A6)` -> `+0x382`) is the tenant may take the new path, so legacy
dispatch is untouched by construction. Still to determine: exactly where
that diversion is safest to place, and how the vs2-only routine is
ENTERED on native (candidate `jmp 0x0930D6` table `0x0930DA`).

**B. RESOLVED — and it corrected the premise (see the correction above).**
The object exists and is stamped identically on both legs; nothing writes
the effect-type byte during the move on either leg. What remains open is
the successor question: **what selects machine #7 for that object during
the ray on native, and what does our build do instead at that moment?**
The type byte is set early and does not change, so the selector is either
another field of the object or the dispatcher's own input. Measure that
before rooting anything.

**C. Transitive closure of the machine bodies.** 0x36/0x4A bytes of code
will contain `jsr`/`jmp` to routines that may themselves be vs2-only.
`extract_char.py` resolves this once rooted, but the closure size is
unknown and could dominate the port.

**D. PARTLY RESOLVED — and it was a badly-posed question.** It was asked
of the maintainer as if it were a gameplay judgement; "same machine" is a
CODE fact and he can only report what it looks like. Measured instead,
with `tests/replays/hui/86_hui_beam_variants.rpl` (all three variants in
one run) on the native leg:

- **236+P and 236+K are the SAME art path.** The beam sprite list
  `0x2621D6` is read at f3165/f3167 (the P beam) *and* at f3465 (the K
  low beam) — same list, same emitter PC `0x019E0E`. The maintainer's
  99% visual read was right, and ONE port covers both.
- **236+2P (ES) RESOLVED — same art path.** The maintainer supplied the
  missing fact: ES consumes one meter stock, exactly like DF, and 236+2K
  is the SAME move as 236+2P (P hits high, K hits low, ES hits mid).
  Captured on native with stocks poked: Phobos takes the transformed blue
  shape, the stock counter drops 3 -> 2 (the state assertion — not just
  the input), and the girthy beam fires at f3785. Its sprites are
  **pal 0x0C in bank 3, H's own band**, same as P and K — it simply uses
  MORE of them (24 codes reaching 0x1F58, against 5 for P/K).
  The earlier "no read at the ES attempt" was ambiguous by construction:
  a girthier beam means different tiles, so a null read could not
  distinguish "did not fire" from "different list".

  **So ONE port covers all three variants.**

- **`0x0937AE` is NOT a beam variant.** Execution breakpoints across all
  three: `0x0934A8` runs 1129 times (constantly, from before the ray —
  it is the object's general per-frame machine, not beam-specific, so
  "the beam machine" was too strong a label), while `0x0937AE` fires only
  the frame-1 arming artefact. It is some other vs2-only effect and is
  OUT of this port's scope until something shows it is needed.

**E. pc-relative data tables.** `x088512` was 0x50 bytes too short for
exactly this reason (14z-70c). Run `census_regions.py` / the pcrel census
on any new root BEFORE freezing its length.

## Proposed order

1. **B** (one run, execution breakpoint on the type stamp) — may
   invalidate everything below.
2. **A** via the R1 map — decides hook shape.
3. Root the machine, let `extract_char.py` report the closure (**C**),
   with the pcrel census (**E**).
4. Hook per A; rebuild; verify against native on replay 83b.
5. Then **D**: check the ES and low-beam variants with the maintainer's
   inputs.

## Pre-check already done — the gfx side is READY

All **157** tiles the three variants draw (expanded for multi-tile
sprites, `base + row*0x10 + col`) are ALREADY present in our group C —
0 missing. So fixing the dispatch should yield a real beam, not the
fuchsia blocks the 214+P explosion produced. Run this check again after
the port, but the copy inventory is not expected to need extending.

## Verification when built

- the three counters at the top must move from 0 to native's numbers;
- snapshot A/B at f3176 (muzzle orb) and f3192 (beam) against native;
- legacy masked-v2 EXACT + `test_m3a_reproducible.sh`;
- the H behaviour gates;
- `tests/test_beam_anim_walk.sh` flips `BEAM_WALK_EXPECT=absent` ->
  `walks` — that flip IS the proof of fix, and it already exists.
