# SCOPE — porting the beam's effect machine (14z-70g)

Status: **scoped, not built.** Written for maintainer review before any
shipped byte changes (the standing "plan and scope first" rule).

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

## OPEN — must be resolved before building

**A. Where is vsavj's twin of the outer dispatcher, and what does its
type-7 entry point to?** This decides the whole shape of the fix:
- if vsavj's entry #7 is **dead/unused**, we repoint it at the ported
  machine — tenant-only by construction, exactly the 14z-67 precedent
  where ids 0x4E-0x53 "read ZERO on vsavj";
- if it is **live**, the hook must be an owner-gated `site_thunk` so
  legacy behaviour is untouched.

Not resolvable by pattern search: the dispatch idiom
(`102e0004 323b0006 4efb1002`) occurs **348 times** in vs2. Use the R1
map / `reconcile_batch.py`.

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

**D. Is `0x0937AE` one of the maintainer's variants?** He reports three
beams (236P, 236+2P ES girthier, 236+K low). Two vs2-only machines and
three variants do not obviously line up — worth knowing before scoping
the second one in or out.

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

## Verification when built

- the three counters at the top must move from 0 to native's numbers;
- snapshot A/B at f3176 (muzzle orb) and f3192 (beam) against native;
- legacy masked-v2 EXACT + `test_m3a_reproducible.sh`;
- the H behaviour gates;
- `tests/test_beam_anim_walk.sh` flips `BEAM_WALK_EXPECT=absent` ->
  `walks` — that flip IS the proof of fix, and it already exists.
