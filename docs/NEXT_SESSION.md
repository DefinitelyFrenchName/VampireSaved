# NEXT SESSION — orientation (session 14z-60, 2026-08-05)

Read STATE.md **14z-60y first** (the open bug), then `14z-60..60x` for what
this session built. The maintainer tests frequently and reports precisely —
their reports are the project's best instrument.

## STOP HERE FIRST — the open bug (CLAUDE.md §6)

**WIDE renders Donovan and Anita with WRONG TILES**, character select
through match. Maintainer playtest of `build/m5w` (`ac52eeff`, built Aug 4 —
nothing from this session; `run_wide.sh` only launches, it never builds).
Mechanically sound otherwise: no gameplay issue, shapes/specials/hit- and
hurtboxes all align. Minor win-screen palette issues, tracked separately.

**§6 says a failing regression is the only task until it is green.** The
`0x13` move waits.

Two hypotheses are already **excluded by measurement**, so do not re-run
them:

- *the patched gfx never reaches the WIDE set* — false. `build/m5w`'s
  `vm3.13m` differs from pristine; `vsw.3xm` are extension banks (zero
  fill), not where the art lives.
- *the FBNeo CRC trap (0xFF fill, logged as OK)* — false. `FBNEO_HGFX`
  dumped the DECODED tile buffer at Donovan's band (tile `0xAD8F` → byte
  `0x56C780`) from WIDE and from the known-good stock build `donovan6`:
  both `sha1 f3cb6aa95b294b9506206d93e335f8a09f43347e`, zero `0xFF` bytes.
  Tiles load correctly and identically on both tracks.

**So the fault is tile ADDRESSING at draw time** — the one line the WIDE
profile removes in `cps_obj.cpp` (sprite tile-code composition for 19-bit
addressing). Fits the symptom (record geometry right, fetch displaced) and
fits it being the same on FBNeo and MAME, which share the patch.

**Suspect, unconfirmed:** GOTCHAS records the free tile-address bit as
**y-word bit 12** (CPS-2 Turbo precedent) — but bit 12 is also a legitimate
Y-coordinate bit. A sprite at such a Y gets its tile address shifted a 64K
page under WIDE. Would also explain the B4 canary passing: it proved
LEGACY replays pixel-identical, and legacy content may never sit at such a
Y. New content does.

**Next measurement:** dump OBJ RAM for a Donovan sprite on the WIDE build,
check his entries' y-words for bit 12, then A/B that frame's framebuffer
against stock. Reproduce the gfx dump with:

```sh
export ROMDIR=/Users/koneko/Developer/Vampire_Saved/ROMS
FBNEO_BIN=<repo>/emu/fbneo/fbneo \
FBNEO_ROMPATH=<repo>/build/m5w/rompath \
FBNEO_HGFX="0056c780-0056cf7f" \
tools/run_replay_fbneo.sh vsavjw tests/replays/11_pick_donovan.rpl \
    /ABSOLUTE/out.log /ABSOLUTE/sandbox      # sandbox MUST be absolute
```

If confirmed it is a defect in **our emulator profile**, not the port —
Rule 1 territory, and it blocks the WIDE track.

### And once it is green: build the gate that should have caught it

Worth stating bluntly, because it is the real lesson of this bug. **Every
automated gate was GREEN while Donovan rendered as garbage.** The RAM gates
are structurally blind to rendering (14z-55), the pixel gate
`tests/test_gfx_menus.sh` covers MENUS on the stock track, and the WIDE
track has no rendering gate at all — so a human playtest was the only
detector. That is a coverage failure, not a testing-cadence one.

Both instruments already exist: `FBNEO_HVIDEO` and MAME's `VIDEO_OUT` give
per-frame framebuffer checksums, and the B4 canary already A/Bs framebuffers
between emulator binaries. The missing gate is the same idea applied to
CONTENT: a Donovan replay whose framebuffer is compared stock-vs-WIDE at
sync anchors, so "the port renders differently on the WIDE track" fails a
gate instead of waiting for someone to look at it.

Mind the known trap when building it: the two tracks are different drivers
and skew by a frame or two, so compare at anchors (or by displayed record),
never by raw frame index — see the cross-emulator and cross-game alignment
entries in GOTCHAS.

## THE PATH CHANGED — `Vampire Saved` → `Vampire_Saved`

The repo now lives at `/Users/koneko/Developer/Vampire_Saved/VampireSaved`
(the space is gone). Consequences:

- Commits were unaffected, but an in-flight worktree pinned to the old
  absolute path was orphaned mid-session (GOTCHAS entry added). **Commit
  before anything that moves the tree.**
- A fresh worktree branches from `origin/main`, which trails local `main`
  badly — `git reset --hard main` right after creating one.
- **Opportunity, not yet taken:** `tools/setup_mame.sh` builds from an
  rsync'd mirror under `~/.cache/vampire-saved/` *only because MAME's GENie
  could not handle the space*. That constraint is gone. Simplifying it would
  remove a whole class of drift, but it changes the INSTRUMENT, so it needs
  `tests/test_mame_parity.sh` green before and after.

## Ship state

| Track | Fingerprint | Packs as | Status |
|---|---|---|---|
| **stock** | `ae701ffb` | `vsavj.zip` | playtested clean to round 65 |
| **WIDE** | `ac52eeff` (m5w) | `vsavjw.zip` | **sprite garble — open bug** |

## What this session landed (14z-60..60y)

- **Select wheel EXTENDED**: three cells at `0x10`/`0x11`/`0x13`, adjacency
  measured from the maintainer's PS1 video and translated by position, 28
  bytes of TABLE B, record + coord list copied to `wide_ext` with one
  pointer repointed. Nothing shifted. `docs/atlas/select_screen.md`.
- **Id space ANSWERED**: conventional. `0x10`/`0x11`/`0x13` free; `0x12`
  (Dark Talbain) and `0x18` (Oboro) RESERVED. 7 folding sites on `$382`,
  and the count is PER-FIELD — derived fields carry their own (see
  `venue_assets.md`). `docs/atlas/id_space.md`.
- **`[[tenant]]` schema RATIFIED and implemented** for one tenant,
  byte-identical on both tracks at `id = 0x0F`. The gfx half is
  tenant-driven too (`patch/tenant.json`).
- **CLAUDE.md §4 class v3 RATIFIED**: "bounded re-convergent window", for
  the select screen. STRICTER than the class beside it. Checker
  `tools/compare_window.py`, ground-truthed by `tests/test_compare_window.sh`.
- **Venue assets measured**: sprite palettes are CLEAN for a variant tenant
  (32-row pointer table, repoint one row); select/VS palette blocks are
  folded and cosmetic. `docs/atlas/venue_assets.md`.

## Queued, after the bug

1. **M3a de-substitution**: tenant `0x0F` → `0x13`. Prep is done — the
   19 executable slot assumptions are enumerated (14z-60w), the thunk id is
   now tenant-driven, the bank-table row is explicit. Remaining unknown:
   `select_port.py` replaces Jedah's select records IN PLACE, so at `0x13`
   the tenant needs its OWN records — that mechanism changes shape.
   Acceptance criterion: legacy Jedah replays return to **bit-identical
   vanilla**.
2. Fightability: the arcade opponent list (`a5-0x61B8`, length `$138(a5)`).
3. Huitzil `0x10` and Pyron `0x11`.
4. Medallion art (deferred deliberately until after de-substitution).

## Gotchas most likely to bite next session

- **Audit manifests, not just code**: `donovan.toml` carries hand-authored
  machine code in `thunk_hex`; a slot id hid there as `000f`. Grep the
  ENCODED form too.
- A generator and its validator written by the same hand share a blind
  spot — the validator must encode what the ENGINE does, not what the
  generator meant.
- `run_replay_fbneo.sh` needs an **absolute** sandbox path (it `cd`s there).
- FBNeo has **no `-rompath`**; it reads `roms/` relative to cwd.
- MAME write taps must be word-aligned; MAME can segfault in teardown AFTER
  writing a complete log, so assert on the `END` line, never the exit code.
