# docs — the taxonomy

Split 2026-08-08 (14z-69) into knowledge about **the game**, knowledge
about **the platform**, and knowledge about **this project**. One
question decides where a fact goes:

> **Would this still be true if we abandoned the roster hack tomorrow?**

Yes, about Vampire Savior -> `game/`. Yes, about CPS-2 or the emulators
-> `platform/`. No -> `project/`.

| | what lives there | outlives the project? |
|---|---|---|
| [`game/`](game/) | how Vampire Savior works: engine subsystems, the ROM/RAM atlas, per-character data, modes and their costs | yes — useful to anyone working on `vsav`/`vsav2`/`vhunt2` |
| [`platform/`](platform/) | CPS-2 hardware, encryption and gfx addressing; MAME and FBNeo behaviour and their builds | yes — useful to any CPS-2 work |
| [`project/`](project/) | the port itself: build pipeline, patch notes and index, manifests, the WIDE profile, milestone plans, playtest records | no — dies with the project |

Entry points at this level, deliberately not in a bucket:
- [`NEXT_SESSION.md`](NEXT_SESSION.md) — 60-second orientation, rewritten
  at session end. Session state, not knowledge.
- [`GOTCHAS.md`](GOTCHAS.md) — the index of all 143 traps, grouped by
  bucket, linking to `*/gotchas.md`. ~195 places in the repo cite
  `docs/GOTCHAS.md`; they all still land somewhere useful.
- `checksums.txt` — machine-read by `tools/audit_roms.py`. A data
  manifest, not documentation; its path is deliberately stable.

## Contents

**`game/`**
- [`engine_internals.md`](game/engine_internals.md) — how the engine
  works, by subsystem. The document a stranger reads to understand the
  game. **Read the relevant section before touching any subsystem.**
- [`atlas/`](game/atlas/) — the verified ROM/RAM map per romset:
  `ram.md`, `character_tables.md`, `id_space.md`, `select_screen.md`,
  `sprite_lists.md`, `venue_assets.md`
- [`gotchas.md`](game/gotchas.md) — traps in the game itself

**`platform/`**
- [`mister.md`](platform/mister.md) — the jtcps2 core (jtcores fork, bus widths, the SDRAM ceiling at our pin vs upstream's 128 MB XL tier, the CPS-2 core's own format caps, the simulation lane, and the work-RAM oracle `JTFRAME_SIM_WRAMDUMP`)
- [`gotchas.md`](platform/gotchas.md) — traps in CPS-2 and the emulators

**`project/`**
- [`porting_code_regions.md`](project/porting_code_regions.md) — how to
  root a block of vs2/vh2 CODE so it still works after we move it:
  bounds, pc-relative data tables, branch escapes, and crypt placement.
  Four sessions of one mistake, as a checklist.
- [`porting_sprite_lists.md`](project/porting_sprite_lists.md) — what a
  tenant port must do so ported effects DRAW: the class row, the missing
  list type, the per-game code bias, and which gfx bank the art comes
  from. Read with `game/atlas/sprite_lists.md`.
- `patch_notes.md` / `patch_index.md` — per-change detail; the registry
- `cps2_wide.md` — the extended hardware profile we defined
- [`mister_fit.md`](project/mister_fit.md) — what merged-m6 needs vs what
  jtcps2 offers, per region; the bank-occupancy arithmetic (§6) behind the
  MiSTer memory-map route
- `tenant_manifest.md`, `tables/` — port config; community-reviewable
  behavioural tables
- `M1_acceptance.md`, `M2_feasibility.md`, `M3b_plan.md` — milestones
- `WSL2_SETUP.md`, `visual_smoke_tests.md`, `playtest_m3a_interims.md`
- [`gotchas.md`](project/gotchas.md) — traps in our pipeline and method

## Two rules that make the split pay off

**1. File by the FACT, not by the task.** A trap hit while porting
Huitzil is a `game/` gotcha if it is true of the game regardless of the
port. Filing by task is how knowledge becomes unfindable.

**2. A subsystem section must name the atlas rows it depends on.** This
is the rule the split alone would not have given us, and it is the one
that would have saved 14z-69: `game/atlas/ram.md` had documented since
14z-44 that `+0x109` is the banked stock count and that `+0x107 = 0xFE`
means "pair downgraded (no stock)" — exactly the fact needed to notice
that Dark Force was never activating. Three sessions of DF work missed
it because the Dark Force section of `engine_internals.md` never pointed
at those rows. Cross-link, or the fact may as well not be written down.
