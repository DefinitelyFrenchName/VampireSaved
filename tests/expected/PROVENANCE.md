# Frozen expectations — WHERE EACH NUMBER CAME FROM

**STATUS: REGISTER (opened 14z-128). One row per file directly under
`tests/expected/`. Completeness is enforced both ways by
`tests/test_expectation_provenance.sh`: a file with no row fails, a row naming
a file that is gone fails.**

## Why this exists

The maintainer's rule for adjudicating a red gate (2026-09-02):

> *"to know if we should fix the gate or what it caught, we must use data we
> can trust, and that means measuring or relying on data that is known to be
> true for it was vetted by measurements."*

**A RED GATE IS A QUESTION, NOT AN ANSWER**, and the first thing the question
needs is which side rests on a measurement. Measured at the 14z-127 close: 30
of 45 frozen expectation files declare their provenance somewhere; 15 do not —
and several of those have it in a gate header or a STATE entry, which is not
where a triage is looking. **The file is what a triage opens.** This page is
that answer, kept beside the files.

The worked warning is 14z-127's own: `test_don_reactions.sh` was GREEN on
`native == 10`, a constant of PLAYTEST TESTIMONY presented as a measurement. It
happened to be correct. That is luck, not method.

## How to read a row

- **subject** — what the numbers describe. THE DISCRIMINATOR FOR RELEASE SCOPE
  is this column, not the romsets the gate touches (`tests/ci_emulator.tsv`).
- **rests on** — the class of evidence:
  - `in-emulator` — produced by running the game and reading its own state.
    The strongest thing here.
  - `derived` — computed from ROM tables by a tool. Only as good as the
    reader; both 14z-125 defects were interpretation defects, and a
    regenerated page would have reproduced them.
  - `static` — read off the image or the tree without running anything.
  - `hash-lock` — a digest of generator output. Locks CURRENCY, never
    correctness ([VSP-12]).
  - `registry` — a ledger of decisions, not a measurement.
- **re-freeze** — the invocation that legitimately regenerates it. A file with
  no re-freeze path is hand-maintained, and changing it is a decision.

| file | owner gate | subject | rests on | re-freeze | since |
|---|---|---|---|---|---|
| `advancing_guard.txt` | `test_advancing_guard.sh` | the advancing guard (guard push) on NATIVE vs2 and on vsavj — the engine's own mechanic, both games | in-emulator | `FREEZE=1 tests/test_advancing_guard.sh` | 14z-123 |
| `charmap_pages.sha256` | `test_charmap_current.sh` | the six regenerated character pages under `../charpages/framedata` | hash-lock | regenerate with `tools/framedata_pages.sh`, then re-hash | 14z-126 |
| `community_crosscheck.txt` | `test_community_crosscheck.sh` | the VERDICT rows (EXACT / CONSTANT OFFSET / INCONSISTENT) of our vanilla frame data against the community workbook — never the workbook's values ([VSP-8]-adjacent, the 2026-08-31 privacy ruling) | derived, arbitrated in-emulator where it disagreed | `FREEZE=1 tests/test_community_crosscheck.sh` | 14z-125 |
| `df_accumulator.txt` | `audit_df_accumulator.sh` | `+0x161` as SASQUATCH's Dark Force armor — a vanilla character's engine behaviour | in-emulator | `FREEZE=1 tests/audit_df_accumulator.sh` | 14z-123 |
| `df_palette_seq_census.txt` | `audit_palette_seq_ids.sh` | which palette-seq ids each character requests in Dark Force, over the corpus | in-emulator | `CHARS="…" tests/audit_palette_seq_ids.sh` | 14z-118 |
| `df_startup_invuln.tsv` | `audit_df_startup_invuln.sh` | the DF startup invincibility window `+0x147`, per character, all 15 vanilla + the three tenants | in-emulator | `FREEZE=1 tests/audit_df_startup_invuln.sh` | 14z-126 |
| `doc_anchor_census.tsv` | `test_doc_anchor_census.sh` | WHERE each skill anchor lives (file + section) | static | `python3 tools/doc_anchor_census.py --freeze` | 14z-126b |
| `escape_triage.txt` | `test_escape_triage.sh` | the H3.1 verdicts on uncovered word-form pc-relative escapes in the tenant builds | static | `FREEZE=1 tests/test_escape_triage.sh` | 14z-100 |
| `front_comparator.txt` | `audit_front_comparator.sh` | what `RAM:$FF8127` is and what its input byte `+0x10` is, on vanilla vsavj | in-emulator | `FREEZE=1 tests/audit_front_comparator.sh` | 14z-123 |
| `killshread_es.txt` | `test_killshread_es.sh` | the ES stance change's effect during the summon, on NATIVE vs2 — the maintainer's 14z-121 ruling, measured | in-emulator | `FREEZE=1 tests/test_killshread_es.sh` | 14z-121 |
| `ladder_tenant_vs_palette.txt` | `test_ladder_tenant_vs_palette.sh` | the arcade-ladder VS palette pool (`PRG:0x3A3CA0 + id*32`) for a TENANT opponent, read ON SCREEN | in-emulator | `FREEZE=1 tests/test_ladder_tenant_vs_palette.sh` | 14z-123 |
| `move_naming_donovan.txt` | `test_move_naming.sh` | which anim CHAIN each of Donovan's named moves enters, measured on NATIVE vs2 — the naming the whole character-data map is indexed by | in-emulator | `FREEZE=1 TENANTS=donovan tests/test_move_naming.sh` | 14z-120 |
| `move_naming_huitzil.txt` | `test_move_naming.sh` | the same for Huitzil/Phobos | in-emulator | `FREEZE=1 TENANTS=huitzil tests/test_move_naming.sh` | 14z-120 |
| `move_naming_pyron.txt` | `test_move_naming.sh` | the same for Pyron | in-emulator | `FREEZE=1 TENANTS=pyron tests/test_move_naming.sh` | 14z-120 |
| `palette_seq_ids_corpus.txt` | `audit_palette_seq_ids.sh` | which palette-seq ids LEGACY ever requests, over the replay corpus — the deadness evidence a tenant block rests on ([VSP-22], [VSP-151]) | in-emulator | `tests/audit_palette_seq_ids.sh` | 14z-79b |
| `projectile_census.txt` | `test_projectile_census.sh` | which `$FF9400`-pool types each TENANT's moves spawn, replayed on native vs2 | in-emulator | see the gate header (no `FREEZE` flag: it writes the census directly) | 14z-120 |
| `projectile_params.txt` | `test_projectile_params.sh` | each projectile type's inline parameter tables, decoded from the type HANDLER and confirmed on the live spawn | derived + in-emulator confirmation | `FREEZE=1 tests/test_projectile_params.sh` | 14z-121 |
| `reactions_donovan.txt` | `test_reactions.sh` | which chains Donovan runs AS THE VICTIM per reaction class, and how long | in-emulator | `FREEZE=1 TENANTS=donovan tests/test_reactions.sh` | 14z-120 |
| `reactions_huitzil.txt` | `test_reactions.sh` | the same for Huitzil/Phobos | in-emulator | `FREEZE=1 TENANTS=huitzil tests/test_reactions.sh` | 14z-120 |
| `reactions_pyron.txt` | `test_reactions.sh` | the same for Pyron | in-emulator | `FREEZE=1 TENANTS=pyron tests/test_reactions.sh` | 14z-120 |
| `registry.tsv` | `tools/build_fingerprint.py` (+ `run_suite.sh`) | which program fingerprint maps to which expectation set — the auto-detecting runner's dispatch | registry | rows are added AT FREEZE TIME as a decision recorded in STATE, never by a tool | M2a |
| `vanilla_hit_damage.sha256` | `test_vanilla_frame_join.sh` | the regenerated per-move vanilla hit/damage table, which lives OUT of the tree | hash-lock | regenerate under `ROMDIR`, then re-hash | 14z-126 |
| `vanilla_normal_slots.tsv` | `test_vanilla_frame_join.sh` | which anim chain each VANILLA character's standing normals enter at two distances, measured on vsavj — the JOIN that overturned a fitted even/odd model | in-emulator | `FREEZE=1 tests/test_vanilla_frame_join.sh` | 14z-125 |

## What this page does NOT cover

The 43 DIRECTORIES under `tests/expected/` are the per-build expectation sets
(`donovan-m18/`, `merged1/`, `vsavj/`, …). Their provenance is
`tests/expected/registry.tsv` — one row per frozen build, fingerprint to
expectation set — plus the `freeze/<name>` git tag at the commit that froze it
([VSP-94]). A set is regenerated only by `run_suite.sh --freeze`, at a freeze,
as a decision recorded in STATE.

## The honest limit

A row here says HOW a file was produced, not that it is right. `in-emulator`
is the strongest class in this project and it is still only as good as the rig
that produced it — every entry in `[VSP-119]`..`[VSP-152]` is a way one of
these rigs has lied. What the row buys is the first question of a triage,
answered in seconds instead of an archaeology session.
