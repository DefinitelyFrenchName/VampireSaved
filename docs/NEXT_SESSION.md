# NEXT SESSION — orientation (written at the close of 14z-80, 2026-08-11)

> ## START HERE
>
> **The N-tenant loop LANDED. M3b's remaining milestone is now the SHARED-ROW
> UNION plus the N-way dispatch FORM** — items 1 and 2 below, in that order.
> Both are named, both have a measured work list rather than a description,
> and `tests/test_tenant_loop.sh` section 4 is the number they have to move.
>
> Nothing shipped in a ROM this session. All four frozen builds are unchanged
> and still rebuild bit-exact.

## The state in one paragraph

`gen_donovan_patch.py`'s `main()` body is now the body of a loop over the
tenants, the `>1 tenant` refusal is deleted, and a three-manifest merge
**generates**: 612 ops, GENERATION OK. It does not **apply** — `patch_prg.py`
refuses it at the first op overlap, and the whole inventory is 10 op pairs /
36 bytes. For one tenant everything is byte-identical: donovan-m3a, m5_stock,
huitzil-m3 and pyron-m2 all rebuild bit-exact, and the generator's output
DIRECTORY is identical to the pre-slice generator for all three manifests.

## What to do next, and why in this order

1. **Shared-row union.** Rows every manifest declares identically merge to
   `_owner=None` and the iteration gate emits them on iteration 0 — where only
   tenant 0's `placed`/`regions` exist. `obj_hook` resolves each ported handler
   through exactly those (`gen_donovan_patch.py`, the `tenant_rows("obj_hook")`
   section — the limit is commented there and in `row_here()`'s docstring), so
   a merged build sends the other tenants' extra handlers to their tripwires.
   Loud at runtime, not silent. The fix is a union pass AFTER the loop, against
   every tenant's placements. This blocks a merged build being *correct*.
2. **The N-way dispatch FORM** — slice E's deferred design decision, and now
   four measured collisions: `0x5F1B6` ×2 and `0x5F146` ×2, 6 bytes each, where
   each tenant emits its own thunk at one engine site. One thunk whose body
   tests N ids. This blocks a merged build being *applicable*.
3. **The remaining 6 shared-span op collisions** (`x028122`, `0x282FA`,
   `0x5F24C`, `0xBE88A`) — fields two or more tenants write differently.
   14z-77h's conflicting set, now with exact addresses.
4. **`region_space` on the manifests, deliberately.** Not a blocker — three
   tenants fit today because `alloc()`'s fallback chain spills into `wide_ext`
   on its own (`hole_a`/`hole_b` come out exactly full, 0x145AA0 spare). But a
   spill is not a placement DESIGN. Adding the rows moves the frozen
   huitzil/pyron placements, so it is a re-freeze and the maintainer's call.
5. Then the driver and gfx halves, which are single-tenant by decision.

## Still open from 14z-79, unchanged

- **Phobos' own palette-seq block** — the proper fix for his Dark Force. Census
  done (`docs/game/engine_internals.md` "THE DARK FORCE PALETTE-SEQUENCE
  BLOCKS"). Two caveats before allocating: the resolver masks to 12 bits, so a
  block must live in `0x39A900-0x3BA8E0` and CANNOT go in `wide_ext`; and
  "nobody requests id N" does not make row N free.
- **Pyron's Zodiac Fire has no rig** (236+P, ES 236+2P) — guard-cancel only.
- `80_pyron_cosmo_pairsweep.rpl` still resets at f4840 — independent, low.
- The three NEW select medallions: polish, not rework.
- Tagging each op with its emitting mechanism in the generator, so
  `test_shared_writes.sh` can say WHAT a new write is, not just that it
  appeared.

## KNOWN-OPEN RED — do not "explain it away" again

`tests/test_variant_dispatch.sh` FAILS on table `0x02a8a4` row 0x10
(`ours 0x004a`, vs2 `0x0040`). Real defect: the aliased row that puts Phobos on
Bulleta's palette routine. Red until Phobos gets his own block.

## Rules this session paid for

- **A shared NAMESPACE with per-tenant CONTENT is a silent-corruption shape,
  and no existing net sees it.** The side files are named after regions; seven
  region names are shared across tenants; the op-overlap assertion compares
  ADDRESSES, which differ. One tenant can never expose it.
- **When a key is per-tenant configuration, check that the per-tenant CONTEXT
  actually carries it.** `tenant_context()` copies a fixed key list;
  `recon_overlay` was not on it, so every tenant after the first built against
  the shared map. Found by RUNNING a 2-tenant build, not by reading.
- **Do the mechanical re-indent in its own commit and review it with
  `git diff -w`.** 3,723 lines moved; the diff under `-w` was the loop header
  and five bindings, and that is the only reason it was reviewable.
- **Freeze what is still broken, by name.** The merged patch's collision
  inventory is the next slice's work list, and a shrinking number is how that
  slice will report progress. Omitting it would have made the gate read as
  "merged builds work".
- **A frozen count that moves for a good reason should be re-frozen with the
  reason, promptly.** `test_manifest_merge.sh` had been red since 14z-79 added
  the (b') thunk row — a legitimate addition nobody re-froze.

## Build / validate

```sh
export ROMDIR=/path/to/reference/sets
tests/test_tenant_loop.sh                  # ~6s, the loop gate
tests/test_tenant_row_owner.sh             # ~9s, the threading gate
tests/test_m3a_reproducible.sh             # ~4 min, all four fingerprints
tools/run_wide.sh build/hui29 fbneo        # play Phobos
```

Run `test_m3a_reproducible.sh` together with `test_tenant_row_owner.sh` and
`test_tenant_loop.sh` after EVERY M3b machinery commit — they ask three
different questions (did the values move / is the threading live / does the
loop iterate) and no one of them substitutes for another.
