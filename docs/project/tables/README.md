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
| `donovan.md` | `build/don_m18` (donovan-m18) | `python3 tools/tables_char_md.py build/don_m18/extract docs/project/tables/donovan.md` |
| `huitzil.md` | `build/hui52` (huitzil-m25) | `python3 tools/tables_char_md.py build/hui52/extract docs/project/tables/huitzil.md` |
| `pyron.md` | `build/pyron36` (pyron-m19) | `python3 tools/tables_char_md.py build/pyron36/extract docs/project/tables/pyron.md` |

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

## The character-data MAP (14z-118) — `chars/`

| file | what | regenerate |
|---|---|---|
| `chars/<tenant>.json` | the MACHINE map: every decoded per-character structure with `vs2` / `ours` / `vh` (reserved) per field and an attribution for every difference | `python3 tools/charmap_gen.py build/<solo> docs/project/tables/chars/<tenant>.json` |
| `chars/<tenant>.md` | the HUMAN page rendered from it | `python3 tools/charmap_md.py docs/project/tables/chars/<tenant>.json docs/project/tables/chars/<tenant>.md` |
| `../charpages/<tenant>_internal.html` (ABOVE the working tree — git cannot add, commit or push it from here; `CHARPAGES_OUT` overrides) | the INTERNAL character page WITH SPRITES (14z-121 (6), (7)): the same page with the character's own sprite at each chain's first active frame drawn in ONE figure with its hurt/push/hit boxes OUTLINED over it (world→OBJ-screen placement `KX=64, KY=262`, calibrated on Donovan's walk / 5LP / 2LK captures) beside the box diagram — captured from the native game's OBJ list and palette page at the frame the naming rigs reach it (`tests/lua/sprite_capture.lua`), drawn from `$ROMDIR/vsav2.zip`'s tiles (`tools/sprite_render.py`). Rendered art stays out of the tree and off the artifacts by the maintainer's word. **Anyone with their own reference dumps can regenerate them**: the script audits `$ROMDIR` against `docs/checksums.txt`, builds the pinned MAME, the WIDE overlay and the three solo builds when absent, then runs the capture/render pipeline (`tools/charpages_frames.py` picks each move's frame — the first active frame, or for a move that hits through an object it OWNS, the first probe frame that object is live; the page draws the object's box too) | `ROMDIR=/path/to/your/dumps tools/charpages_internal.sh` (~15 min after the one-time builds) |
| `chars/<tenant>.html` | the CHARACTER PAGE (14z-121 (5)): a wiki-style rendering — physics, every move of the move list with frame data, damage, meter, class, pushback, the move's own hit/hurt/push box diagram and the maintainer's notes, projectiles, reactions as the victim, provenance. Published as artifacts: Donovan https://claude.ai/code/artifact/85d7fd52-9b14-4b19-b3a1-d76334f2cb3e · Huitzil https://claude.ai/code/artifact/f0dddc83-5b9b-4139-a637-91c55695fdf7 · Pyron https://claude.ai/code/artifact/ad618f12-5166-4a88-94e8-d89625a3500e | `python3 tools/charmap_html.py <tenant> build/<solo> docs/project/tables/chars/<tenant>.html` (regenerate with the map) |
| `../../../build/manifest/charmap_<tenant>.toml` | the ONE hand-written file: overrides (`[[override]]`), compiled into the tenant manifest by `tools/charmap_compile.py` | `python3 tools/charmap_compile.py docs/project/tables/chars/<tenant>.json build/manifest/charmap_<tenant>.toml build/manifest/<tenant>.toml` |

Gates: `tests/test_charmap_current.sh` (ci_static) and `tests/test_charmap_overrides.sh`
(ci_portable). The page's "What is NOT decoded" section is the worklist for the
later phases (anim node chains + move names, hitbox rectangles + attack records,
stun/projectile params) — see `docs/project/doc_audit_14z118.md` and STATE 14z-118.

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
