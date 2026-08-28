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
| [`platform/`](platform/) | CPS-2 hardware, encryption and gfx addressing; MAME, FBNeo and the MiSTer/jtcores core — their behaviour and their builds | yes — useful to any CPS-2 work |
| [`project/`](project/) | the port itself: build pipeline, patch notes and index, manifests, the WIDE profile, the MiSTer core we are building, milestone plans, playtest records | no — dies with the project |

**IF YOU WANT TO KNOW X, READ Y** (the routing table — start here rather
than guessing a filename):

| if you want to know… | read |
|---|---|
| where the project stands and what to do next | [`NEXT_SESSION.md`](NEXT_SESSION.md), then `../HANDOFF.md` |
| how the game works, by subsystem | [`game/engine_internals.md`](game/engine_internals.md) → the `game/atlas/` rows it names |
| what a specific address IS | [`game/atlas/`](game/atlas/) — `ram.md`, `character_tables.md`, `id_space.md`, `select_screen.md`, `sprite_lists.md`, `venue_assets.md` |
| **what is true about the MiSTer core and why** | **[`project/mister_core.md`](project/mister_core.md) — the synthesis, in causal order. Read it BEFORE any MiSTer work**; its logs are `project/mister_map.md` (the SDRAM placement), `project/mister_fit.md` (what the roster needs) and [`platform/mister.md`](platform/mister.md) (jtcores, the simulation lane). Where the synthesis and a log disagree, THE LOG WINS |
| what the extended hardware profile is and what rule 1 v2 permits | [`project/cps2_wide.md`](project/cps2_wide.md) |
| what a change did, byte by byte | `project/patch_notes.md`; the registry is `project/patch_index.md` |
| why something that "should work" does not | [`GOTCHAS.md`](GOTCHAS.md) — always check before re-deriving |

Entry points at this level, deliberately not in a bucket:
- [`NEXT_SESSION.md`](NEXT_SESSION.md) — 60-second orientation, rewritten
  at session end. Session state, not knowledge.
- [`GOTCHAS.md`](GOTCHAS.md) — the index of every trap paid for, grouped
  by bucket, linking to `*/gotchas.md` (304 entries across the three
  bucket files at the 14z-107 close: 46 game / 79 platform / 179 project —
  one `##` heading each, so `grep -c '^## '` is the count). ~195 places in
  the repo cite `docs/GOTCHAS.md`; they all still land somewhere useful.
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
- [`mister.md`](platform/mister.md) — the jtcps2 core (jtcores fork, bus widths, the SDRAM ceiling at our pin vs upstream's 128 MB XL tier, the CPS-2 core's own format caps, the simulation lane, the work-RAM oracle `JTFRAME_SIM_WRAMDUMP`, and how the MRA and the `.rom` download image are actually generated)
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
- [`mister_core.md`](project/mister_core.md) — **the MiSTer SYNTHESIS: what
  is TRUE about the core and why each fact follows from the one before it.**
  The roster's demand, the 64 MB ceiling and why it is physical, the three
  sizes of the same art (live bytes vs address footprint vs declared region —
  the confusion that produced three wrong published figures), the placement,
  the format caps no amount of memory lifts, the runtime profile gate, the
  instruments, D0-D4, and what would break it. **Read this one first**; the
  logs it quotes are `mister_fit.md`, `mister_map.md` and
  `platform/mister.md`, and where it and one of them disagree the log wins.
  Its diagrams are also drawn, by `tools/mk_mister_page.py` — generated by a
  committed tool, never committed itself
- [`release_format.md`](project/release_format.md) — **the release format
  (ruled 2026-08-28): one release, one SELF-SUFFICIENT directory per
  platform** (`fbneo/`, `mame/`, `mister/`), the patch set copied into
  each, the driver patch + recipe on the emulator side, the MRAs +
  bitstream record + `.rbf` on the MiSTer side; every version releases
  every platform. Producer `tools/package_release_platforms.py`, gate
  `tests/test_release_roundtrip.sh` section 4
- [`mister_scope.md`](project/mister_scope.md) — **the SCOPE of the MiSTer
  documentation/skill distillation** (14z-113, scope only, not the skills):
  the two-level split (CPS-II/WIDE core vs VS-specific) with each skill's
  boundary, sources and gates; which docs feed which; and the
  **known-stale inventory** (S1-S20, file:line) measured against all
  ~5,000 lines of the MiSTer sources — read it before quoting any MiSTer
  document's STATUS line
- [`mister_fit.md`](project/mister_fit.md) — what merged-m6 needs vs what
  jtcps2 offers, per region; the bank-occupancy arithmetic (§6) behind the
  MiSTer memory-map route
- [`mister_map.md`](project/mister_map.md) — the MiSTer SDRAM PLACEMENT MAP:
  which region lands in which bank at which offset and why it fits, the
  `.rom` layout against the 26-bit `ioctl_addr`, the QSound split, the 6 MB
  PRG decode proposal, and the RTL slice plan (**D0-D5 ALL DONE, 14z-107
  (5)-(11)** — the MRA trim, the runtime profile gate + QSound width, the
  placement whose whole-image census corrected this document's own slack
  figure from 0.708 MB to 0.125 MB, the obj promote, the 6 MB program
  window and the decryption range; **field-tested on hardware 14z-109 and
  14z-112**. The document is the DERIVATION and keeps its retraction
  history; its STATUS paragraph at the top is current as of 14z-113)
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
