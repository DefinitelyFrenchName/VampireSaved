# NEXT SESSION — orientation (written at the close of 14z-85, 2026-08-13)

> ## START HERE
>
> **THE SPAWN-TIME OWNER TAG SHIPPED AND IS FULLY VERIFIED** (14z-85,
> the ruled option (a)): obj_hook 64-75 dispatch on the object's
> spawn-time tag (+0x7F of the **$FF9400** slot — NOT $FFB800, see the
> corrections below), 80 stamp sites detoured, 12 tag stubs, tripwire
> silent under 2,046 live family dispatches, solos bit-exact, merged
> legacy audit 14/14 verbatim.
>
> **FIRST ACT: hand the maintainer the rebuilt merged build for the
> FULL-SCOPE playtest** (they were waiting on this fix; the Piled Hell
> hitbox question likely closes with it) **and get the two 14z-85
> rulings** (STATE "Decisions pending"):
> 1. **Per-tenant sfx records** — the ACTUAL music-retrigger fix. The
>    14z-84 "unified mechanism" claim was PARTIALLY WRONG: the ring
>    inventory is identical before/after the tag. Measured mechanism:
>    donovan's [[sound_table]] un-stubs the per-node sfx helper
>    ENGINE-WIDE but repoints only HIS ptr row (0x0BF41A+4*char);
>    pyron's nodes fire vanilla row 0x11 → music id 0x729 every ~5s.
>    Recommended (a): pyr/hui record arrays, the don_sfx_records
>    keep/zero policy, curated tables into docs/project/tables/.
>    Guard until then: tests/audit_pyron_ring.sh (frozen known-open
>    diff: cosmo {0x110}; mash {0x110,0x111,0x112,0x31b,0x729}).
> 2. **Extend tag stubs to 59-63?** Single-resolver (donovan) entries;
>    H/P stamp those types at dead co-ported sites (solo builds
>    tripwire them and playtest green). Tags already emitted there;
>    recommended (a) ~5 stubs at the next op-count re-freeze.
>
> ## The 14z-85 corrections (read before trusting old pool claims)
>
> - The 14z-84 tag census measured the WRONG POOL: $FFB800/0x80 is the
>   0x5E542/114-120 family's; the 59-75 family lives in
>   **$FF9400/0x100** (walker 0x54458). Re-measured: +0x7F free there.
> - The $FFB800 "+0x7F free" was ALSO a word-offset tap artifact —
>   hole_b writes a word at +0x7E covering byte +0x7F. **Bucket write
>   taps by BYTE LANE** (GOTCHAS, platform).
>
> ## What shipped (all committed, d567b79..HEAD)
>
> - gen_donovan_patch: owner-tag pass (renumber-pass pattern, N>=2
>   gated, empty at N=1 — solos verified bit-exact), shape "tag" in
>   owner_dispatch_stub, tag_map.json side file.
> - Gates: tenant_loop 473/667 re-frozen + §4b decodes stubs per entry;
>   667 pins in build_merged/audit_merged_legacy; audit_pool_free_byte
>   REWRITTEN (both pools, pre/post-tag modes, FORCE_MODE negative
>   control — ground-truthed BOTH directions); dispatch-range §4-6
>   (0x54470 liveness + tripwire silence); NEW audit_pyron_ring.
> - Ladder: ALL GREEN end to end incl. legacy 14/14 (ratified 04+11).
> - Evidence: build/owner_tag_evidence/ (before/after ring traces).

## Current builds (registry)

| build | set | fingerprint |
|---|---|---|
| build/m3b_merged | UNREGISTERED (pending full-scope test + freeze) | 517feab1 this build (667 ops, owner tag) |
| build/m5_wide | donovan-m3a | 4b7d0dc7 |
| build/hui32 | **huitzil-m6** | db4bcd11 |
| build/pyron21 | **pyron-m3** | 6c7f7322 |
| build/hui31, hui30 | superseded m5/m4 (keep) | 38188bb1 / e66678d0 |

## Still open (the short list)

- **Per-tenant sfx records** (music retrigger — ruling pending, brief
  above; co-top with the full-scope test).
- 59-63 stub extension (ruling pending, cheap).
- Pyron's medallion whitening on 2P hover (row-0x1A family; palette-row
  design work).
- Phobos EX damage-data suspicion (maintainer will name move+numbers;
  rig = the native-vs2 damage-table A/B).
- H-vs-P stuck-direction (maintainer testing FBNeo leg; ~1/30, also vs
  legacy opponents — possibly emulator-side).
- Round-end flicker (parked; needs the maintainer's recording).
- The win-screen QUOTE (both tenants); pyron win-laugh distortion
  (M5-family); select medallions polish; region_space re-freeze
  (maintainer); op-tagging for test_shared_writes; the 14z-83 parked
  leg-b reference staleness notes.

## Build / validate

```sh
export ROMDIR=/path/to/reference/sets
tools/build_merged.sh build/m3b_merged     # ~15 min (667-op fixture)
tests/test_tenant_loop.sh                  # generator gate (473/667)
tests/test_m3a_reproducible.sh             # ~6 min (all four refs)
tests/audit_type_dispatch_range.sh build/m3b_merged   # ~15 min, §0-6
tests/audit_pool_free_byte.sh              # ~20 min (post-tag mode)
tests/audit_pyron_ring.sh                  # ~10 min (known-open frozen)
MERGED_OUT=build/m3b_merged MERGED_PREBUILT=1 \
  tests/audit_merged_legacy.sh             # ~45 min: 14/14
```
