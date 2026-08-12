# NEXT SESSION — orientation (written at the close of 14z-83, 2026-08-12)

> ## START HERE
>
> **THE MERGED PROGRAM HALF IS DONE AND MEASURED: the 04 ratification is
> executed and `audit_merged_legacy` ran to FULL GREEN (exit 0) — the
> project's first all-green merged measurement.**
>
> - The ratified merged-04 expectation (`composite vsavj/masked-v2
>   1525,2005,2009,2195 889-1104`) lives INLINE in
>   `tests/audit_merged_legacy.sh`'s leg-(a) loop (the merged instrument
>   is unregistered by design; the single-tenant prior
>   `tests/expected/donovan-m3a/04_select_fuzz.masked` is untouched).
>   Every OTHER deviation still fails loudly — the carve-out is exactly
>   one signed expectation, mechanism named ($FF0460 sound-driver
>   record-pointer spill, `tests/audit_ff0460_writer.sh`).
> - Measured 14z-83: leg (a) 14/14 PASS (attract EXACT; 04 exactly the
>   ratified inventory, 1325 identical frames after), leg (b) all six
>   guard-clean. 593 ops, F2 shape asserted, all three char-inits
>   execute, merged determinism holds.
>
> **NEXT ARC: the gfx half (M3b Phase 3)** — the merge is program-only by
> decision; gfx is still single-tenant. Then the tenant batteries on a
> merged build. Before starting, read `docs/project/cps2_wide.md` and the
> HANDOFF gfx notes (group C sentinels, the hash-shadowing trap, the
> two-romsets rule).

## Current builds (registry)

| build | set | fingerprint |
|---|---|---|
| build/m5_wide | donovan-m3a | 4b7d0dc7 |
| build/hui30 | **huitzil-m4** | e66678d0 |
| build/pyron21 | **pyron-m3** | 6c7f7322 |
| build/hui29, build/pyron20 | superseded (pre-fix A/B baselines, keep) | 34c8b47d / 69e8c6f0 |

`build/merged1` is the LEGACY-ONLY instrument — never playtest, never
register; rebuilt by every `audit_merged_legacy` run (fingerprint moves
with the generator; do not pin it in docs).

## The .sha1 re-freeze attribution (read before touching those baselines)

Both suites moved EXACTLY the three don-mash `.sha1` self-baselines
(21/22/26) and nothing else in 14z-82c. Attribution was made ON THE
CHECKSUM TIMELINE with bytes: a full-RAM dump-diff at a divergent frame
shows 3 bytes, all in the $FF7Fxx dead-stack ghost window, zero live bytes
— the ratified hook-cycle class (masked entries all green). NOTE the
failed first attempt: -debug guard probes showed fire counts that
contradicted the divergence onsets — debug timelines do NOT transfer to
checksum timelines on vs-CPU/chaos content. Attribute with dumps, not
debug probes, on this replay class.

## Still open, unchanged

- Phobos' own palette-seq block (KNOWN-OPEN RED on
  `tests/test_variant_dispatch.sh`, table 0x02a8a4 row 0x10).
- Pyron's Zodiac Fire has no rig (guard-cancel only — Claude's to rig).
- The win-screen QUOTE (both tenants; shared fold).
- (14z-82d, maintainer playtest, M5-family sound bucket): Phobos' LK/HK
  Plasma Trap detonations have NO sound and never did (MK's was restored
  by (b'); maintainer filed for completeness, explicitly not a blocker
  before M5). Native-vs2 three-strength ring comparison decides
  faithful-vs-gap; 87's strength sweep is the ready rig.
- (14z-82d, maintainer playtest): pyron's win-pose voice (his laugh)
  renders DISTORTED — pre-existing (pyron20≡pyron21 ring A/B
  byte-identical), likely a vs2 sample id without its backing QSound
  sample in vsav (the M5 voice-arc family). Ring-tap the win pose for
  the id, compare sample data across the sets.
- The three NEW select medallions: polish.
- `region_space` rows re-freeze — maintainer's call.
- Op-tagging so `test_shared_writes.sh` can name what a new write is.
- Deferred with measurements attached: the 0x54470 family's FIRST-WINS
  notes; type 120 (no reachable stamp).

## Build / validate

```sh
export ROMDIR=/path/to/reference/sets
tests/test_m3a_reproducible.sh             # ~4 min (m4/m3 constants)
tests/test_tenant_loop.sh                  # ~17 s (261/207/439/593)
tests/audit_merged_vec3.sh                 # ~4 min: GREEN
tests/audit_merged_legacy.sh               # ~45 min: FULL GREEN as of
                                           # 14z-83 (any FAIL is a
                                           # regression — stop and
                                           # root-cause)
```
