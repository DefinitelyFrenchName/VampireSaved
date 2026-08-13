# NEXT SESSION — orientation (written at the close of 14z-85e, 2026-08-13)

> ## FIELD VERDICT FIRST
>
> Deeper testing (maintainer): **NO REGRESSIONS** — 95% movelist
> coverage for Donovan/Pyron/Phobos, ~50% for Bulleta/Victor/Demitri/
> Morrigan, on the 677-op merged build. Two NON-regression parity items,
> both advanced to measured mechanisms (STATE 14z-85e):
> 1. **FINAL GUARDIAN (623+2K) damage**: ~10/288 HP on our build
>    (1-2/tick; EX-firing verified by stock decrement). The port is
>    BYTE-FAITHFUL and the power byte is 2 in vs2's own data — the
>    divergence is the per-game SCALER (damage-class tables, live-reg
>    candidates 0x0ABFxx/walker 0xB91C0) or native hit-count. NEXT:
>    compare the scaler tables against vs2's twins (reconciliation for
>    0x18108's twin) + a retuned native replay for vs2's number. Fix
>    shape if class-table: variant-gated extension (hitclass precedent),
>    NEVER vanilla-row edits.
> 2. **Plasma-trap detonation sound**: SYSTEMATIC on native vs2 vs
>    proximity-gated on ours — the 14z-84 closure reopened (it compared
>    our build against itself). The id IS enqueued even when silent →
>    volume/pan ring-entry params hypothesis; rig = full 16-byte entry
>    A/B near/far, ours vs native.


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
> `build/m3b_merged` (677 ops, gfx included; still UNREGISTERED pending
> the S6 freeze decision) — "prod comes first", so the voice arc below
> starts in parallel. Then:
> - ~~Extend tag stubs to 59-63~~ **DONE 14z-85c** (ruled + executed:
>   the foreign-stamper rule; 59/61/62/63 donovan-only stubs, 60 direct;
>   counts 490/677; ladder green).
> - **THE M5 VOICE-SAMPLES ARC IS RULED GO** ("cleverly, MiSTer-aware —
>   core tweaks acceptable"). The measured design brief is in STATE
>   14z-85c: ~616 KB+ of vs2 sample windows into the WIDE QSound
>   image's free upper 8 MB (banks 0x80+ — MAME's LLE bank register is
>   15-bit, measured in qsound.cpp); Z80 driver has 27,727 B free for
>   the new id rows (WIDE A4). **THE Z80 RE IS UNDERWAY — read STATE
>   14z-85d before touching it** (id table @FILE 0x11006 4B/id both
>   games; interpreter/track/channel state mapped; kabuki disasm =
>   MAME debugger dasm; instrument tests/lua/qs_table_trace.lua).
>   NEXT CONCRETE STEPS: (1) decode the 0x02E5 id-entry consumption
>   (the captured qtrace flow has it) → entry format + the sample
>   bank/start/end ROM source; (2) free-id census with the CORRECT
>   entry decode; (3) longer-window keyon re-sweep (~36 scoped ids
>   attack-blind); (4) packer + Z80 rows + record remaps (NOTE: the
>   restored ids CANNOT keep their vs2 numbers — 0x700+ are vanilla
>   MUSIC ids; new ids from free space + remap in our record arrays);
>   (5) verify jtcores' QSound region growth for MiSTer.
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
> - tests/test_tenant_loop.sh — 243/266/208 solo, 490/677 merged; §4b
>   decodes all 16 tag stubs per entry (59-75 family, 14z-85c).

## Current builds (registry)

| build | set | fingerprint |
|---|---|---|
| build/m3b_merged | UNREGISTERED (pending deeper test + S6 freeze) | moves with generator (677 ops) |
| build/m5_wide | donovan-m3a | 4b7d0dc7 |
| build/hui33 | **huitzil-m7** | 284e3b1c |
| build/pyron22 | **pyron-m4** | ac22418f |
| build/hui32, pyron21 | superseded m6/m3 (keep — pre-sfx A/B baselines; their extract dirs stay the tenant_loop/build_merged inputs) | db4bcd11 / 6c7f7322 |

## Still open (the short list)

- THE M5 VOICE-SAMPLES ARC (ruled GO; brief in STATE 14z-85c — the
  next big implementation).
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
tools/build_merged.sh build/m3b_merged     # ~15 min (677-op fixture)
tests/test_tenant_loop.sh                  # generator gate (490/677)
tests/test_m3a_reproducible.sh             # ~6 min (all four refs)
tests/audit_type_dispatch_range.sh build/m3b_merged   # ~15 min, §0-6
tests/audit_pool_free_byte.sh              # ~20 min (post-tag mode)
tests/audit_pyron_ring.sh                  # ~10 min (EMPTY diff frozen)
MERGED_OUT=build/m3b_merged MERGED_PREBUILT=1 \
  tests/audit_merged_legacy.sh             # ~45 min: leg a verbatim
```
