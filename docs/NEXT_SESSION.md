# NEXT SESSION — orientation (written at the close of 14z-82c, 2026-08-12)

> ## START HERE
>
> **The 14z-82 day closed with THREE fixes shipped and the merged
> instrument crash-free.**
>
> 1. **Per-tenant TYPE NUMBERS** (14z-82, commit 33c2c70): the merged
>    Huitzil vec3 + F2, measured through the full ladder.
> 2. **The hit-class map extension** (14z-82b root-cause, 14z-82c
>    ADOPTED): vsavj's projectile-pool hit sweep maps type bytes through
>    a 64-entry map at `PRG:0x1A888`; vs2's has 80. This ONE vanilla map
>    was THREE defects — pyron's f7997 (latent in frozen pyron-m2 SOLO),
>    the `80_pyron_cosmo_pairsweep` reset open since 14z-75 (same
>    signature, measured with a control), and Huitzil's unexercised 68/72
>    exposure. **Frozen: `huitzil-m4` (e66678d0, build/hui30) and
>    `pyron-m3` (6c7f7322, build/pyron21)** — playtest these.
> 3. **audit_merged_legacy is now: leg (a) 13/14 VERBATIM, leg (b) ALL
>    SIX guard-clean** (pyron/70 END 11017 on the merged build). The
>    only FAIL anywhere is 04's held-un-ratified flicker inventory.
>
> **Both verification suites are GREEN** (hui30, pyron21 at 55 PASS),
> all decisions are in: decision 2 DECIDED (keep vanilla's zeros) and
> **THE 04 INVENTORY IS RATIFIED (maintainer, 2026-08-12)** — {1525,
> 2005, 2009, 2195}, composite, window 889-1104, mechanism named.
> **FIRST ACT NEXT SESSION: execute the ratification** — encode the
> ratified merged-04 expectation in audit_merged_legacy (the merged
> instrument is unregistered by design, so its expectation lives in the
> audit script; its own printed "proposed:" line is the spec verbatim)
> and run the audit to FULL GREEN — the first all-green merged
> measurement in the project. Then the gfx half (M3b Phase 3).

## The .sha1 re-freeze attribution (read before touching those baselines)

Both suites moved EXACTLY the three don-mash `.sha1` self-baselines
(21/22/26) and nothing else. Attribution was made ON THE CHECKSUM
TIMELINE with bytes: a full-RAM dump-diff at a divergent frame shows 3
bytes, all in the $FF7Fxx dead-stack ghost window, zero live bytes — the
ratified hook-cycle class (masked entries all green). NOTE the failed
first attempt: -debug guard probes showed fire counts that contradicted
the divergence onsets — debug timelines do NOT transfer to checksum
timelines on vs-CPU/chaos content. Attribute with dumps, not debug
probes, on this replay class.

## Then, in order

2. ~~The 04/2005 ratification decision~~ **RATIFIED (2026-08-12)** —
   execution per the START HERE block above.
3. ~~Decision 2~~ DECIDED (keep zeros, 2026-08-12): Donovan's
   map[61]/[62] stay vanilla; revisit only on playtest feel.
4. **Then the gfx half** (M3b Phase 3) and the tenant batteries on a
   merged build — the program half now has NO known crash.
5. Deferred with measurements attached: the 0x54470 family's FIRST-WINS
   notes; type 120 (no reachable stamp).

## Current builds (registry)

| build | set | fingerprint |
|---|---|---|
| build/m5_wide | donovan-m3a | 4b7d0dc7 |
| build/hui30 | **huitzil-m4** | e66678d0 |
| build/pyron21 | **pyron-m3** | 6c7f7322 |
| build/hui29, build/pyron20 | superseded (pre-fix A/B baselines, keep) | 34c8b47d / 69e8c6f0 |

## Instruments added across 14z-82/-82b/-82c (all in the suite)

```sh
tests/test_type_stamp_census.sh     # static stamp census vs frozen inventory
tests/audit_type_writes.sh          # dynamic writer-PC census
tests/audit_type_dispatch_range.sh  # merged: zero original-range dispatches
tests/audit_ff0460_writer.sh        # the $FF0460 owner lock
tests/test_hitclass_map_thunk.sh    # hit-class fix reconstruction gate
tests/audit_hitclass_map_cost.sh    # hit-class adoption numbers, rerunnable
tests/audit_trap_sound.sh           # MK trap fires AND sounds (14z-82d lock)
```
`GUARD_PROBE_HIST` fires at CRASH time too; `audit_merged_legacy` leg-b
always measures the REF leg on a crash (MERGE-SPECIFIC vs LATENT).

## Still open, unchanged

- Phobos' own palette-seq block (KNOWN-OPEN RED on
  `tests/test_variant_dispatch.sh`, table 0x02a8a4 row 0x10).
- Pyron's Zodiac Fire has no rig (guard-cancel only — Claude's to rig).
- The win-screen QUOTE (both tenants; shared fold).
- NEW (14z-82d, maintainer playtest, M5-family sound bucket): Phobos'
  LK/HK Plasma Trap detonations have NO sound and never did (MK's was
  restored by (b'); maintainer filed for completeness, explicitly not a
  blocker before M5). Native-vs2 three-strength ring comparison decides
  faithful-vs-gap; 87's strength sweep is the ready rig.
- NEW (14z-82d, maintainer playtest): pyron's win-pose voice (his
  laugh) renders DISTORTED — pre-existing (pyron20≡pyron21 ring A/B
  byte-identical), likely a vs2 sample id without its backing QSound
  sample in vsav (the M5 voice-arc family). Ring-tap the win pose for
  the id, compare sample data across the sets.
- The three NEW select medallions: polish.
- `region_space` rows re-freeze — maintainer's call.
- Op-tagging so `test_shared_writes.sh` can name what a new write is.

## Build / validate

```sh
export ROMDIR=/path/to/reference/sets
tests/test_m3a_reproducible.sh             # ~4 min (m4/m3 constants)
tests/test_tenant_loop.sh                  # ~17 s (261/207/439/593)
tests/audit_merged_vec3.sh                 # ~4 min: GREEN
tests/audit_merged_legacy.sh               # ~45 min (fails ONLY on 04's
                                           # held inventory, by design)
```
