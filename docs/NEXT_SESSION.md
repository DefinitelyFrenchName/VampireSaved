# NEXT SESSION — orientation (session 14z-61, 2026-08-05)

Read STATE.md **14z-61 first** (the bug that blocked everything is closed),
then `14z-60..60z` for the roster work it was blocking. The maintainer tests
frequently and reports precisely — their reports are the project's best
instrument, and this bug is the proof: no automated gate saw it.

## THE OPEN BUG IS CLOSED — and it was not what it looked like

**WIDE rendered Donovan and Anita with vanilla art** because the shipped
WIDE romset carried gfx group C as **byte copies of the stock group B**
(the B4 canary shape, which the documented build recipe passed to every
content build). Copies carry the originals' CRCs, and **both emulators
resolve a ROM entry by HASH before falling back to its NAME** — so group
B's declared CRC matched those copies and the loader served PRISTINE tiles
for the members the build had patched. Right geometry, wrong pixels, no
error, no `0xFF` fill, every RAM gate green.

Not the emulator. The OBJ records are bit-identical between the two tracks
(2,277 live entries, zero differences), y-word bit 12 is never set on this
content, and the drawn Y is masked to `0x03FF` so bit 12 was never a
coordinate bit either. The 14z-60y measurement that "cleared" the tile data
was taken at tile `0xAD8F` — the sprite's code word **without its bank
bits**; the real address is `0x2AD8F`.

Fixed in the pipeline, not in a file:

- `build/wide0/rompath` = shippable overlay (group C zero fill);
  `build/wide_canary/rompath` = the canary. The profile gates read
  `CANARY_ROMPATH` so the split costs no coverage.
- `tools/audit_romset_identity.py` — no member may carry the pristine bytes
  of a member the build patched. Wired into `build_donovan.sh` (hard fail)
  and `pack_build.sh`. Ground truth: `tests/test_romset_identity.sh`.
- `tests/test_wide_render_content.sh` — the missing rendering gate: pixel
  A/B of a Donovan replay, stock track vs WIDE, **3,721/3,721 frames
  identical**, plus a positive control that poisons a set back into the
  failing shape (it diverges on 2,542 frames) and a tile-band check with a
  pristine negative control. ~60 s.

## Playtest CONFIRMED — the WIDE track is unblocked

Maintainer, 2026-08-05, on `build/m5_wide` (`9bac6ee3`): *"Initial tests with
and without Donovan look good. No obvious regression, all graphics look good,
gameplay feels genuine, all present sounds are good."* That covers both the
ported content and the legacy path, and it also puts the 14z-60 select-wheel
extension (`PRG:0x2689FE`, `PRG:0x021227`, 148 bytes in the extension member,
absent from `m5w`) in a human's hands for the first time.

```sh
export ROMDIR=/Users/koneko/Developer/Vampire_Saved/ROMS
tools/run_wide.sh build/m5_wide fbneo     # NOT build/m5w — that is the known-bad artifact
```

Still open and still unrelated: the minor win-screen palette items from the
original playtest. **One decision waiting** in STATE "Decisions pending":
whether to freeze/register `9bac6ee3` as the WIDE reference before M3a
churns the tenant's records (recommended — M3a would otherwise have nothing
to bisect against on this track).

## Ship state

| Track | Fingerprint | Packs as | Status |
|---|---|---|---|
| **stock** | `ae701ffb` (`build/m5_stock`) | `vsavj.zip` | playtested clean to round 65; rebuild reproduces the fingerprint exactly |
| **WIDE** | `9bac6ee3` (`build/m5_wide`) | `vsavjw.zip` | garble FIXED, gated, and **playtest-confirmed**; freeze/register pending |
| ~~WIDE~~ | `ac52eeff` (`build/m5w`) | — | KNOWN-BAD, kept as evidence. Do not run |

## Queued (the roster work the bug was blocking)

1. **M3a de-substitution**: tenant `0x0F` → `0x13`. Prep is done — the 19
   executable slot assumptions are enumerated (14z-60w), the thunk id is
   tenant-driven, the bank-table row explicit. Remaining unknown:
   `select_port.py` replaces Jedah's select records IN PLACE, so at `0x13`
   the tenant needs its OWN records — that mechanism changes shape.
   Acceptance: legacy Jedah replays return to **bit-identical vanilla**.
2. Fightability: the arcade opponent list (`a5-0x61B8`, length `$138(a5)`).
3. Huitzil `0x10` and Pyron `0x11`.
4. Medallion art (deferred deliberately until after de-substitution).
5. Optional hygiene, now that the descriptor is provably load-bearing: the
   WIDE driver descriptors still declare group C with the PRISTINE group B
   CRCs while we ship zero fill. Harmless today (nothing addresses group C)
   but it is the same ambiguity class — declare what we ship. Costs two
   emulator rebuilds plus `test_mame_parity.sh` and both profile gates.

## Gotchas most likely to bite next session

- **Compose the bank bits before dumping a tile band** — `tile = code |
  ((y & 0x6000) << 3)`. A dump at the wrong address returns a clean null
  that reads as exoneration.
- **A null result needs a negative control**, exactly as much as a positive
  one does.
- Audit manifests, not just code: `donovan.toml` carries hand-authored
  machine code in `thunk_hex`; a slot id hid there as `000f`.
- A generator and its validator written by the same hand share a blind spot.
- `run_replay_fbneo.sh` needs an **absolute** sandbox path (it `cd`s there).
- FBNeo has **no `-rompath`**; it reads `roms/` relative to cwd.
- MAME write taps must be word-aligned; MAME can segfault in teardown AFTER
  writing a complete log, so assert on the `END` line, never the exit code.
