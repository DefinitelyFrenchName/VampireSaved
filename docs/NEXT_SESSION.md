# NEXT SESSION — orientation (written at the close of 14z-84, 2026-08-13)

> ## START HERE
>
> **FIRST ACT: implement the spawn-time OWNER TAG for the 59-75 object
> family** (maintainer ruled option (a), 2026-08-13; STATE 14z-84 has
> the full brief + measurements). This is the last known merged
> program-behavior defect class — it is what makes Pyron's specials
> start MUSIC on the merged build (his family-64-75 objects run
> HUITZIL's handler copies by declaration-order luck; solo builds
> structurally cannot show it).
>
> The foundation is MEASURED AND SUITE-CAPTURED:
> - **The tag byte: +0x7F of the $FFB800 pool slot** — zero values in
>   1,342 live-slot observations AND zero writes (PC-attributed tap,
>   liveness proven), both tenants. Guard:
>   `tests/audit_pool_free_byte.sh` (extend it when the tag ships:
>   +0x7F writes from OUR emitted stamp sites become expected).
>   **[CORRECTED 14z-85, 2026-08-13: WRONG POOL — $FFB800/0x80 is the
>   0x5E542/114-120 family's pool; the 59-75 family lives in
>   $FF9400/0x100 (walker 0x54458). Re-measured there: +0x7F free,
>   804 live-slot obs, zero writes under BYTE-LANE accounting. And the
>   $FFB800 +0x7F "freeness" was itself an artifact — hole_b's word
>   write at +0x7E covers that byte lane.]**
> - Near-candidates +0x7C/+0x7E are DISQUALIFIED (one write each from
>   our own hole_b code at PC 0x3FFFD6).
>
> The implementation, in order:
> 1. TAG EMISSION at every frozen stamp-inventory site for types 59-75
>    (`build/manifest/type_stamps.toml` enumerates them; the 14z-82
>    renumber machinery is the precedent — it rewrote stamp immediates,
>    this adds a tag write per site; the two stamp FORMS are documented
>    there). Verify each site's position relative to slot init.
> 2. OWNER-DISPATCH STUBS on obj_hook entries 64-75, keyed on
>    (0x7F,A4), with a ZERO-TAG TRIPWIRE (an untagged family object = a
>    missed stamp site, loud by design — nothing clears +0x7F, so
>    stale tags in legacy-reused slots are unread but a missing fresh
>    stamp must never dispatch by luck). The stub builder exists and is
>    battle-tested: `owner_dispatch_stub()` (14z-81c; its DISPATCH-TIME
>    OWNER READ approach was withdrawn for two measured timing failure
>    modes — the spawn-time tag avoids both, which is the whole design).
> 3. THE LADDER: solo fingerprints bit-exact (test_m3a_reproducible —
>    tag rows must be merged-relevant only OR the solos re-freeze;
>    decide deliberately), tenant_loop counts, merged rebuild,
>    audit_merged_vec3 + audit_type_dispatch_range, legacy audit
>    (prebuilt, expect 14/14 with the TWO ratified merged expectations
>    04 + 11), and **the ring-tap on Pyron's specials as the fix's own
>    before/after** (music ids on the current build → correct sfx
>    after; tests/lua/ring_tap.lua + replay pyron/71).
> 4. Then the maintainer's FULL-SCOPE test (they are waiting for this
>    fix to make it worthwhile) — likely closes the Piled Hell hitbox
>    question too.
>
> ## The 14z-84 day (all committed; 8ad4a84..f6fcf59 + close)
>
> Seven playtest findings triaged: the select/VS name + win-portrait
> class ROOT-CAUSED AND FIXED (displaced-head chain shape; the three
> movea-head bank gates were deduping to tenant 0's compare) —
> field-confirmed; Bulleta DF closed NOT-A-BUG (purple IS Savior; VS2
> comparison error; probe-free cross-build A/B gotcha paid); trap
> "silence" closed NOT-A-BUG (proximity-triggered, maintainer-confirmed
> all three variants); **PHOBOS' DF GOLD SHIPPED (huitzil-m6, db4bcd11,
> build/hui32, tag freeze/huitzil-m6)** — variant_dispatch GREEN first
> time since 14z-74; two lessons paid (PC-relative table words need
> code_word, not aux_poke — watchdog reset caught by capture; the
> shared_writes pins had rotted two freezes — now toml-driven, hitclass
> backfills surfaced); merged-11 flicker RATIFIED + encoded → legacy
> audit FULL GREEN 14/14; the flicker rig cannot reproduce the
> round-end event (558 frames, brightness-level — parked awaiting the
> maintainer's recording).
>
> New suite members this session: audit_select_bank_gates,
> audit_pool_free_byte, audit_df_gold (the shipped gold's guard;
> its first version compared raw bytes and called a working upload
> dead — the uploader ORs the alpha nibble; compare 0x0FFF-masked).

## Current builds (registry)

| build | set | fingerprint |
|---|---|---|
| build/m3b_merged | UNREGISTERED (pending full-scope test + freeze) | 3cf7541a this build |
| build/m5_wide | donovan-m3a | 4b7d0dc7 |
| build/hui32 | **huitzil-m6** | db4bcd11 |
| build/pyron21 | **pyron-m3** | 6c7f7322 |
| build/hui31, hui30 | superseded m5/m4 (keep) | 38188bb1 / e66678d0 |

## Still open (the short list)

- **Pyron merged music/handlers** — the owner-tag arc above IS the fix.
- Pyron's medallion whitening on 2P hover (the documented row-0x1A
  residual family; belongs with proper palette-row design work).
- Phobos EX damage-data suspicion (maintainer will name move+numbers;
  rig = the native-vs2 damage-table A/B).
- H-vs-P stuck-direction (maintainer testing FBNeo leg; ~1/30, also vs
  legacy opponents — possibly emulator-side).
- Round-end flicker (parked; needs the maintainer's recording for a
  frame window; post-round only, not a blocker).
- The win-screen QUOTE (both tenants); pyron win-laugh distortion
  (M5-family); select medallions polish; region_space re-freeze
  (maintainer); op-tagging for test_shared_writes; the 14z-83 parked
  leg-b reference staleness notes.

## Build / validate

```sh
export ROMDIR=/path/to/reference/sets
tools/build_merged.sh build/m3b_merged     # ~15 min (597-op fixture)
tests/test_m3a_reproducible.sh             # ~6 min (all four refs)
tests/audit_df_gold.sh                     # ~10 min (the gold guard)
tests/audit_pool_free_byte.sh              # ~15 min (the tag byte)
MERGED_OUT=build/m3b_merged MERGED_PREBUILT=1 \
  tests/audit_merged_legacy.sh             # ~45 min: FULL GREEN 14/14
```
