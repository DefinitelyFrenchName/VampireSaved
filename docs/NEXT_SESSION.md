# NEXT SESSION — orientation (updated mid-14z-83, 2026-08-12: Phase 3 underway)

> ## START HERE
>
> **THE GFX ARC (M3b Phase 3) IS UNDERWAY — S0-S2 landed, S3 is BLOCKED
> on ONE maintainer ruling** (STATE.md "Decisions pending — 14z-83"):
> relocate Huitzil's 288-tile beam strip (shift 0x1000 → 0x3800, dst
> 0x86A0-0x87BF, handler bias 0x5200 → 0x7A00) and re-freeze huitzil-m4
> → m5. The S0 census proved this is the ONLY real collision in the
> whole 3-tenant merged gfx write set — everything else is byte-proven
> same-source. **If the ruling is in: execute S3 first** (three sites:
> `strip_tiles/0x10.json` shift, the `068152000000` bias inside
> `beam_list_type6.thunk_hex` in huitzil.toml, and
> `test_beam_list_type6.sh`'s byte lock; + `gfx_layout3.toml` [[strip]]
> row + pool-1 ledger split; + flip `test_gfx_chain.sh` section 4 to
> full-chain success), then the H battery + beam gates + playtest →
> ratify huitzil-m5, update `test_m3a_reproducible.sh` EXPECT_HUI +
> registry.
>
> Landed this session (all committed, all gates green):
> - **The 04 ratification EXECUTED** → `audit_merged_legacy` FULL GREEN
>   (14/14 + six guard-clean) — the first all-green merged measurement.
>   The merged-04 expectation lives inline in the audit script.
> - **S0**: `tests/audit_gfx_merged_census.sh` — the complete merged
>   group-C write-set census, 2 comparator controls. ONE real collision
>   (the strip); occupancy 45,449/65,536; pools EMPTY; plan A holds.
> - **S1**: `place()` — same-source-or-fail on EVERY gfx pass (was 2/8)
>   + the `gfx_written.json` ledger. `tests/test_gfx_collision_gate.sh`.
> - **S2**: `--chain` — links compose over members + cumulative ledger.
>   `tests/test_gfx_chain.sh` (solo byte-identical / idempotent / D->H
>   cumulative / P-onto-H must-fail).
> - All four frozen fingerprints rebuilt bit-exact after every step.
>
> **After S3: S4** (driver merged-gfx mode → `build/m3b_merged`;
> verify_gfx_build/check_tenant_hud multi-tenant — design them against
> the driver's real layout), **S5** (merged render gates — H/P's first —
> + audit_empty_tiles), **S6** (merged legacy re-verdict + registry +
> playtest). Plan: `/Users/koneko/.claude/plans/vectorized-riding-lerdorf.md`;
> read `docs/project/cps2_wide.md` + HANDOFF gfx notes first (sentinels,
> hash-shadowing, the two-romsets rule).

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
