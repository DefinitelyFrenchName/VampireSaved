# NEXT SESSION — orientation (written at the close of 14z-80, 2026-08-11)

> ## START HERE
>
> **A 3-tenant merged PATCH now applies.** `gen_donovan_patch.py` emits
> Donovan + Phobos + Pyron into one program image, 590 ops, zero op
> collisions, and `patch_prg` writes the 12 members. That is the PROGRAM half.
>
> **Next, in this order:** (1) the gfx half, which is still single-tenant and
> is M3b_plan Phase 3, still undesigned; (2) `build_donovan.sh`, which needs
> one extraction per tenant; (3) RUN a merged image — nothing merged has been
> in an emulator, and no legacy gate has seen one.
>
> Nothing shipped in a ROM this session. All four frozen builds are unchanged
> and rebuild bit-exact.

## The state in one paragraph

`main()`'s body is a loop over the tenants; the `>1 tenant` refusal is gone.
Four defects were found and fixed under it, each measured first — and three of
them were invisible to every gate that existed at the time. For one tenant
everything is byte-identical: donovan-m3a, m5_stock, huitzil-m3 and pyron-m2
all rebuild bit-exact, and the generator's output directory matches the
pre-slice generator for all three manifests.

## What the four defects were, because the SHAPES recur

| # | defect | why no gate saw it |
|---|---|---|
| 1 | shared rows naming a `region` patched only tenant 0's COPY — H's and P's x05c800/x088512 kept vs2's OBJ bank | a blob patch emits no op, so no count moved |
| 2 | shared rows whose address is `table + stride*dst_slot` wrote DONOVAN'S entry for everyone | looked like an ordinary op collision |
| 3 | `obj_hook` resolved only tenant 0's handlers — 12 of Huitzil's secondary objects pointed at planted ILLEGALs | tripwires are a legitimate output; only the COUNT was wrong |
| 4 | the last collisions were AGREEMENTS (identical bytes, different mechanisms) | they were real, just not conflicts |

The lesson under all four: **"identical row text" is not "identical effect"**
once N tenants exist. A row's effect can depend on which tenant applies it
(its own copy of a region, its own slot, its own placements), and the merge's
dedup was throwing that information away.

## Open, in the order it blocks a playable merged build

1. **The gfx half** (M3b_plan Phase 3). `build_gfx_donovan.py` is
   single-tenant: per-tenant band/delta/bank must come from the manifest, the
   group-C pass must chain, and a cross-tenant tile-collision gate is needed.
   The generator already emits the per-tenant inputs
   (`select_tiles.<tenant>.json`, `wheel_bank5.<tenant>.json`, `tenants.json`).
   Phase 3 says MEASURE first: do the three bands pack into bank 4's 0x10000
   codes, or does group C have to grow to 8 members?
2. **`build_donovan.sh` is single-tenant** — one extraction per tenant, then
   `--extract`/`--port` pairs in order. Small, but it is what makes a merged
   build reachable from the command line at all.
3. **RUN one.** The legacy suite on a merged build first (`run_suite.sh`
   against its own fingerprint), then each tenant's behaviour battery. Until
   then "the merge works" means "the program image composes", nothing more.
4. **`region_space` on the manifests, deliberately.** Three tenants fit today
   only because `alloc()`'s fallback chain spills into `wide_ext` — hole_a and
   hole_b come out exactly full. A spill is not a placement design. Adding the
   rows moves the frozen huitzil/pyron placements, so it is a re-freeze and
   the maintainer's call.

## Still open from 14z-79, unchanged

- **Phobos' own palette-seq block** — the proper fix for his Dark Force.
  Census done (`docs/game/engine_internals.md` "THE DARK FORCE PALETTE-SEQUENCE
  BLOCKS"). Two caveats: the resolver masks to 12 bits, so a block must live in
  `0x39A900-0x3BA8E0` and CANNOT go in `wide_ext`; and "nobody requests id N"
  does not make row N free.
- **Pyron's Zodiac Fire has no rig** (236+P, ES 236+2P) — guard-cancel only.
- `80_pyron_cosmo_pairsweep.rpl` still resets at f4840 — independent, low.
- The three NEW select medallions: polish, not rework.
- Tagging each op with its emitting mechanism, so `test_shared_writes.sh` can
  say WHAT a new write is, not just that it appeared.

## KNOWN-OPEN RED — do not "explain it away" again

`tests/test_variant_dispatch.sh` FAILS on table `0x02a8a4` row 0x10
(`ours 0x004a`, vs2 `0x0040`). Real defect: the aliased row that puts Phobos on
Bulleta's palette routine. Red until Phobos gets his own block.

## Rules this session paid for

- **A shared NAMESPACE with per-tenant CONTENT is a silent-corruption shape.**
  Side files are named after regions; seven region names are shared; the
  op-overlap assertion compares ADDRESSES. One tenant can never expose it.
- **Check that the per-tenant CONTEXT actually carries a per-tenant key.**
  `tenant_context()` copies a fixed key list and `recon_overlay` was not on
  it, so every tenant after the first built against the shared map. Found by
  RUNNING a 2-tenant build, not by reading.
- **Measure the defect before fixing it, and measure the ATTRIBUTION.** "17 of
  17 placed" is worth nothing without "and 64-75 land in HUITZIL'S copies" —
  with four shared region names, a wrong-tenant target still looks placed.
- **Read the body before declaring a design decision.** The N-way dispatch
  form was carried as an open design question for three sessions; both bodies
  were already chain elements and the answer was concatenation.
- **A control that changes nothing reports success.** `set() or {...}` is
  falsy and returns the comprehension; that control passed while perturbing
  nothing, and only failed because it was written to require a specific
  observable change.
- **Freeze what is still broken — until it is fixed, then make it a
  regression.** The collision inventory was a work list at 10 pairs and is
  now `assert zero`.
- **Do a mechanical re-indent in its own commit and review it with
  `git diff -w`.** 3,723 lines moved; under `-w` the diff was the loop header
  and five bindings.

## Build / validate

```sh
export ROMDIR=/path/to/reference/sets
tests/test_tenant_loop.sh                  # ~17s, the merge gate (5 controls)
tests/test_tenant_row_owner.sh             # ~9s, the threading gate
tests/test_m3a_reproducible.sh             # ~4 min, all four fingerprints
tools/run_wide.sh build/hui29 fbneo        # play Phobos
```

Run all three after EVERY M3b machinery commit — they ask three different
questions (did the values move / is the threading live / does the merge
compose) and no one of them substitutes for another.
