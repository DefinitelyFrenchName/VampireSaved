# NEXT SESSION — orientation (written at the close of 14z-83, 2026-08-12)

> ## START HERE
>
> **M3b PHASE 3 IS MEASURED COMPLETE. THE FIRST FULL-ROSTER BUILD WITH
> ART EXISTS AND PASSES EVERY GATE: `build/m3b_merged`** (built by
> `tools/build_merged.sh`, fingerprint moves with the generator — do not
> pin; unregistered ON PURPOSE until the freeze decision).
>
> **FIRST ACT: the maintainer playtest.**
> `tools/run_wide.sh build/m3b_merged fbneo` — all 18 characters
> selectable with art. Specifically wanted from the playtest:
> - the BEAM (Huitzil 214+K family): its strip art moved to bank-4
>   0x86A0-0x87BF in S3 (maintainer-approved relocation; every static
>   and render gate is green but the eye is the final instrument);
> - the usual sweep: each tenant picks/plays/wins, a legacy character or
>   two for feel, select screen, HUD/mugshots/names.
> After a clean playtest: the REGISTRY decision (row + name for the
> merged build — a maintainer freeze decision; run_suite refuses the
> build until then), then the tenant batteries on the merged build.
>
> ## What 14z-83 landed (one session, all committed, all gates green)
>
> 1. **The 04 ratification executed** → `audit_merged_legacy` FULL GREEN
>    — the project's first all-green merged measurement.
> 2. **S0** the merged group-C census (`audit_gfx_merged_census.sh`):
>    exactly ONE real collision existed (H's 288 strip dsts in P's band).
> 3. **S1** `place()` — same-source-or-fail on every gfx pass + ledger.
> 4. **S2** `--chain` — gfx links compose (`test_gfx_chain.sh`).
> 5. **S3** the strip relocation (maintainer-ruled option a): shift
>    0x3800, bias 0x7A00; **huitzil-m5 frozen** (38188bb1, build/hui31,
>    tag freeze/huitzil-m5); census now ZERO real collisions; FULL
>    3-tenant chain green; suite green on the carried set, zero .sha1
>    movers.
> 6. **S4** `tools/build_merged.sh` + multi-tenant verify/HUD checkers →
>    `build/m3b_merged`.
> 7. **S5** `test_merged_render_content.sh` — H/P's FIRST render gates —
>    all bands + strip serve the frozen solo art; empty-tiles green
>    (H 3 replays, P 2).
> 8. **S6** the gfx-carrying build passed the FULL legacy audit (leg (a)
>    14/14, leg (b) six guard-clean; `MERGED_OUT`/`MERGED_PREBUILT`).

## Current builds (registry)

| build | set | fingerprint |
|---|---|---|
| build/m3b_merged | **UNREGISTERED — pending playtest + freeze** | (moves; see its README) |
| build/m5_wide | donovan-m3a | 4b7d0dc7 |
| build/hui31 | **huitzil-m5** (14z-83 S3: strip relocation) | 38188bb1 |
| build/pyron21 | **pyron-m3** | 6c7f7322 |
| build/hui30 | superseded huitzil-m4 (keep) | e66678d0 |

## Still open, unchanged (pre-existing ledger)

- Phobos' own palette-seq block (KNOWN-OPEN RED on
  `tests/test_variant_dispatch.sh`, table 0x02a8a4 row 0x10).
- Pyron's Zodiac Fire has no rig (guard-cancel only — Claude's to rig).
- The win-screen QUOTE (both tenants; shared fold).
- M5-family sound: Phobos LK/HK trap silence; pyron win-laugh distortion.
- The three NEW select medallions: polish.
- `region_space` rows re-freeze — maintainer's call.
- Op-tagging for `test_shared_writes.sh`.
- NEW parked (14z-83): `audit_merged_legacy` leg-b's H reference names
  superseded hui30 (extract byte-identical, report-only) — update with
  the audit's next scheduled run. A Donovan empty-tiles rig with a
  measured frame window (H/P legs exist; D is covered by band
  equivalence + solo history, but has no dedicated leg).

## Build / validate

```sh
export ROMDIR=/path/to/reference/sets
tools/build_merged.sh build/m3b_merged     # ~15 min, the 3-tenant build
tests/test_m3a_reproducible.sh             # ~5 min (all four frozen refs)
tests/audit_gfx_merged_census.sh           # ~4 min, ZERO real collisions
tests/test_gfx_chain.sh                    # ~9 min, full chain + fixture
tests/test_merged_render_content.sh        # ~25 min, the render gate
MERGED_OUT=build/m3b_merged MERGED_PREBUILT=1 \
  tests/audit_merged_legacy.sh             # ~45 min, legacy re-verdict
```
