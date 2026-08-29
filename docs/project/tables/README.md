# tables — behavioral data tables (community-reviewable)

Every tunable a player could feel (damage, timings, meter rules, variant
selection) lives here in documented table form, extracted by rerunnable
scripts in `tools/` (CLAUDE.md §2 rule 5). Nothing gameplay-affecting hides
in code or manifests.

*(Rewritten 14z-118. Until then this README opened with "Empty until a
ported character exists" over a populated directory and promised
per-character manifests for three tenants while holding one, hand-written
on 2026-08-09 and never refreshed — the documentation audit's specimen for
this directory. Maintainer-ruled 2026-08-29: generate all three.)*

## The per-character tables — GENERATED, gated

| file | build it follows | regenerate |
|---|---|---|
| `donovan.md` | `build/don_m17` (donovan-m17) | `python3 tools/tables_char_md.py build/don_m17/extract docs/project/tables/donovan.md` |
| `huitzil.md` | `build/hui51` (huitzil-m24) | `python3 tools/tables_char_md.py build/hui51/extract docs/project/tables/huitzil.md` |
| `pyron.md` | `build/pyron35` (pyron-m18) | `python3 tools/tables_char_md.py build/pyron35/extract docs/project/tables/pyron.md` |

Each page is rendered by `tools/tables_char_md.py` from the build's
`extract/regions.json` (what `tools/extract_char.py` measured: source and
oracle sets, input SHA-1s, shifts, regions with SHA-1s, dispatch targets,
VS2-vs-VH2 variant sites, and the per-character VALUE rows — the tunables)
plus `build/manifest/bank_map.toml` (the vsavj row addresses). **Gate:
`tests/test_tables_current.sh` (ci_static) regenerates from the current
solo builds and fails on any drift**, so the committed page is a measurement
of the shipped build, not a transcription. The freeze ritual's re-point
sweep moves the build names above; regenerate the three pages in the same
freeze commit.

Reading the value rows: `value8/16/32`, `rec8` (two longs) and `byte2d`
(30 bytes, a 2-D table row) are COPIED into the build unchanged — these are
the numbers the community can review and, through the manifest, adjust.
`*_ptr` rows are the source-set pointers the port repoints to the relocated
copy. Consumers and semantics: `docs/game/atlas/character_tables.md`.

## The other tables

- `reconciliation.md` — per-instance record of every VS2-vs-vanilla-vsav
  engine-rule reconciliation (SPEC §3.2): which rule won, what value, why.
- `defense_rows.md` — the tenants' DEFENSE-side rows: maintainer-ruled
  14z-85f to keep the vanilla vsavj approximation (the ruling and its
  measurement).
- `qs_voice_map.md` — the M5 voice-block id map (14z-86): every restored
  voice id, its block and its source.
- `sfx_records.md` — the per-tenant sfx record tables (the `[[sound_table]]`
  rows the per-node sfx helper reads).

## History

The 2026-08-09 hand-written `donovan.md` (M2-era region manifest, the R1
reconciliation worklist and its prose) is in git history at
`git show 2a6ebc3:docs/project/tables/donovan.md`; its variant-delta
findings are now the generated "VS2-vs-VH2 variant sites" section.
