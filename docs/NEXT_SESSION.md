# NEXT SESSION — orientation (written at the close of 14z-85b, 2026-08-13)

> ## START HERE
>
> **BOTH 14z-85 FIXES ARE SHIPPED, LADDER-GREEN, AND FIELD-CONFIRMED**
> (maintainer, first playtest): *"the music triggering is gone, Piled
> Hell has its hitbox — needs deeper testing but it does look very
> good."*
> 1. **The spawn-time OWNER TAG** (ruled option (a)): obj_hook 64-75
>    dispatch on the object's spawn-time tag (+0x7F of the **$FF9400**
>    slot), 80 stamp-site detours, 12 tag stubs, tripwire silent under
>    2,046 live dispatches.
> 2. **Per-tenant sfx records** (ruled option (a) — "the obvious
>    solution if it fits"; it fits): pyr/hui_sfx_records, the
>    don_sfx_records precedent, curation in
>    docs/project/tables/sfx_records.md. The music retrigger was NEVER
>    the 64-75 dispatch (ring identical before/after the tag) — it was
>    the per-node sfx helper reading RAW vs2 records through the
>    generic tail_data_ptr repoint.
>
> **FIRST ACT: support the maintainer's deeper full-scope testing** of
> `build/m3b_merged` (669 ops, gfx included; still UNREGISTERED pending
> the S6 freeze decision). Then:
> - **Ruling still pending: extend tag stubs to 59-63?** (explained to
>   the maintainer 14z-85: H/P stamp types 59/61-63 at dead co-ported
>   sites; a stub makes any future live spawn loud instead of silently
>   running donovan's copy. ~5 stubs, one op-count re-freeze, zero
>   behavior change on working paths. Recommended (a), not urgent.)
> - **The M5 voice-samples decision** is now the only thing between all
>   three tenants and their voice lines (their voice-bank ids are
>   zeroed = silent; restoring them = grow the QSound sample region —
>   WIDE has 16MB headroom, don's 14z-51 analysis lists the absent
>   samples).
>
> ## Corrections that must outlive this session (14z-85)
>
> - Pool attribution: $FFB800/0x80 = the 0x5E542/114-120 family;
>   **$FF9400/0x100 = the 0x54470/59-75 family** (walker 0x54458). The
>   14z-84 census had the wrong pool; retracted and re-measured.
> - **Bucket write taps by BYTE LANE** — a word write at +0x7E covers
>   byte +0x7F; word-offset bucketing invented the "$FFB800 +0x7F free"
>   claim (GOTCHAS, platform).
>
> ## New/changed suite members
>
> - tests/audit_pyron_ring.sh — merged-vs-solo ring diff frozen EMPTY.
> - tests/audit_pool_free_byte.sh — REWRITTEN: both pools, pre/post-tag
>   modes, FORCE_MODE negative control (ground-truthed both directions).
> - tests/audit_type_dispatch_range.sh — §4-6: 0x54470 family liveness +
>   tag-stub tripwire silence.
> - tests/test_tenant_loop.sh — 243/266/208 solo, 474/669 merged; §4b
>   decodes the tag stubs per entry.

## Current builds (registry)

| build | set | fingerprint |
|---|---|---|
| build/m3b_merged | UNREGISTERED (pending deeper test + S6 freeze) | moves with generator (669 ops) |
| build/m5_wide | donovan-m3a | 4b7d0dc7 |
| build/hui33 | **huitzil-m7** | 284e3b1c |
| build/pyron22 | **pyron-m4** | ac22418f |
| build/hui32, pyron21 | superseded m6/m3 (keep — pre-sfx A/B baselines; their extract dirs stay the tenant_loop/build_merged inputs) | db4bcd11 / 6c7f7322 |

## Still open (the short list)

- 59-63 stub extension (ruling pending, cheap).
- M5 voice samples (the standing decision; all three tenants' voice
  banks silenced until then).
- Pyron's medallion whitening on 2P hover (row-0x1A family).
- Phobos EX damage-data suspicion (maintainer will name move+numbers).
- H-vs-P stuck-direction (~1/30, possibly emulator-side).
- Round-end flicker (parked; needs the maintainer's recording).
- Win-screen QUOTE (both tenants); pyron win-laugh distortion
  (M5-family); select medallions polish; region_space re-freeze;
  op-tagging for test_shared_writes; 14z-83 leg-b staleness notes.

## Build / validate

```sh
export ROMDIR=/path/to/reference/sets
export MAME_BIN=~/.cache/vampire-saved/mame/cps2   # run_suite needs it
tools/build_merged.sh build/m3b_merged     # ~15 min (669-op fixture)
tests/test_tenant_loop.sh                  # generator gate (474/669)
tests/test_m3a_reproducible.sh             # ~6 min (all four refs)
tests/audit_type_dispatch_range.sh build/m3b_merged   # ~15 min, §0-6
tests/audit_pool_free_byte.sh              # ~20 min (post-tag mode)
tests/audit_pyron_ring.sh                  # ~10 min (EMPTY diff frozen)
MERGED_OUT=build/m3b_merged MERGED_PREBUILT=1 \
  tests/audit_merged_legacy.sh             # ~45 min: leg a verbatim
```
