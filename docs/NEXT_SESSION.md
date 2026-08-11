# NEXT SESSION — orientation (written at the close of 14z-80, 2026-08-11)

> ## START HERE
>
> **A 3-tenant merged PATCH now applies.** `gen_donovan_patch.py` emits
> Donovan + Phobos + Pyron into one program image, 590 ops, zero op
> collisions, and `patch_prg` writes the 12 members. That is the PROGRAM half.
>
> **FIRST PRIORITY (maintainer, 14z-80 close): prove a merged image does not
> perturb LEGACY, before any gfx design work.** It can be done with PRISTINE
> graphics — legacy characters do not read group C — so it does not wait on
> M3b_plan Phase 3, and it is the first evidence the merge behaves rather than
> merely composes. Full recipe below; it is deliberately ahead of the gfx half
> in the list.
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

## 1. THE MERGED-LEGACY MEASUREMENT — first priority

**The question:** does a program image carrying all three tenants' hooks
perturb vanilla behaviour? Nothing merged has ever run. This answers the one
thing that would invalidate the whole merge, and it needs **no tenant art**,
so it does not wait on Phase 3.

**Why pristine gfx is legitimate here.** Tenant art lives in group C; vanilla
characters read groups A/B, and on a variant-id build vsav's group B stays
PRISTINE by construction (the de-substitution invariant). A merged image
packed against the zero-filled `build/wide0/rompath/vsavjw.zip` therefore
renders every LEGACY character correctly and the three tenants as blanks. That
is exactly the right instrument for a legacy verdict, and useless for anything
else — say so in the build log, because such a build must never reach a
playtest.

**The four constraints, all confirmed by reading the code (not yet by
running it):**

1. **The driver is single-tenant.** `tools/build_donovan.sh` takes
   `TENANT_MANIFEST`/`TENANT_CHAR` and one extraction. It needs one extraction
   per tenant and `--extract`/`--port` pairs in `--port` order — the generator
   already checks the pairing and refuses a mismatch.
2. **Skip the gfx stage, do NOT lower the stage.** The gfx work is
   `build_donovan.sh:285-396`, the whole `if [ "$STAGE" -ge 6 ]` block
   including `verify_gfx_build.py`. The PACK step above it (:263-279) is
   independent and already merges the WIDE overlay, so a merged program image
   packs as `vsavjw` with group C empty. The generator must still run at
   **stage 6** — its `select_records`/`site_thunk` rows are stage-6 gated — so
   this is a `SKIP_GFX=1` escape on that block, not a lower stage.
   `audit_romset_identity.py` runs unconditionally after it (:406) and still
   guards the merged romset, which is what you want.
3. **`run_suite.sh` CANNOT judge this build.** It fails on an unregistered
   fingerprint (`tests/run_suite.sh:53-54`) and registry rows are added only
   at freeze time. The verdict has to be a **LIVE A/B between two builds** —
   `tests/audit_phase_mode_cost.sh` is the template, and its header explains
   this exact constraint.
4. **Section 0 must prove the merged image BOOTS and forms matches** before
   any "identical" is believed. The audit_phase_mode_cost lesson, verbatim:
   without a rig that produces the event, every replay compares identical and
   the green measures nothing.

**Two legs, in this order:**

- **(a) vs VANILLA, masked-v2 basis** — the superset-invariant question and
  the confidence being sought. Expect the §4 classes that already apply to
  hook-carrying builds: the frozen flicker inventories, the §4 v3 bounded
  select-screen window, and most likely §4 v4 **composite**, since a merged
  build carries all three tenants' hooks AND the extended wheel. Any class
  that does not match must be mechanism-attributed before it is accepted
  (CLAUDE.md §4) — a merged build is exactly where "we widened the tolerance"
  would be easiest and worst.
- **(b) vs the three frozen single-tenant builds** — does MERGING change what
  each tenant's own build did? A differential, cheap once (a)'s rig exists,
  and the sharper signal about the merge specifically.

**Expected non-issue, state it up front:** with group C zero-filled,
`audit_empty_tiles.sh` will report the tenants drawing blank tiles. That is
correct and is not a defect of this build — it is why the build is
legacy-only.

## Then, in order

2. **The gfx half** (M3b_plan Phase 3). `build_gfx_donovan.py` is
   single-tenant: per-tenant band/delta/bank from the manifest, a chaining
   group-C pass, and a cross-tenant tile-collision gate. The generator already
   emits the per-tenant inputs (`select_tiles.<tenant>.json`,
   `wheel_bank5.<tenant>.json`, `tenants.json`). Phase 3 says MEASURE first:
   do the three bands pack into bank 4's 0x10000 codes, or must group C grow
   to 8 members? The second answer bumps the CPS-2 WIDE profile version and
   touches BOTH emulator descriptor patches — Rule 1 v2 and
   `docs/project/cps2_wide.md` governance, i.e. a maintainer decision.
3. **Then run the tenants for real** — each behaviour battery on a merged
   build with its own art, then a playtest.
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
