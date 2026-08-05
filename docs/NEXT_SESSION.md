# NEXT SESSION — orientation (written at the close of 14z-61, 2026-08-06)

**Start here: M3a has two halves left, both content PLACEMENT.** Everything
else is green — read this page, then STATE.md `14z-61` for the detail. The
maintainer tests frequently and reports precisely; their reports are the
project's best instrument, and 14z-61 is the proof (no automated gate saw
the bug they found).

## Where to start, concretely

**Do the select records first.** It is the smaller half, it is independently
testable against a gate that already exists, and it makes Jedah's select
screen vanilla again — half of de-substitution, visible immediately.

```sh
export ROMDIR=/Users/koneko/Developer/Vampire_Saved/ROMS
tests/test_select_arrays.sh          # ~13s — the measured model you are building on
KEY_SET=vsavj GEN_FLAGS="--allow-plausible --tripwire-open \
    --profile cps2-wide-v1 --tenant-id 0x13" tools/build_donovan.sh 6 build/m3a
```

The mechanism is measured and frozen (`docs/atlas/select_screen.md`): the
tenant at `0x13` owns **six longs**, two per UI piece —

| piece | P1 | P2 |
|---|---|---|
| big portrait | `PRG:0x267476` | `PRG:0x2674F6` |
| name banner | `PRG:0x2675F6` | `PRG:0x267676` |
| cursor highlight | `PRG:0x268A4E` | `PRG:0x268ACE` |

— all currently Victor aliases, all in the variant half no legacy id can
index. **The pointer math is not the work.** The work is that
`tools/select_port.py` writes the tenant's record BYTES over Jedah's records
in place, and at `0x13` those bytes need their own home. Picking an address
by hand is the "never write an unverified gap" trap (GOTCHAS). It has to
come from the generator's space model — and `gen_donovan_patch.py` runs
BEFORE `select_port.py` in `tools/build_donovan.sh`, so either the
allocation is emitted for `select_port` to consume (check what the `image`
block in `patch/patch.json` already records), or the records move into the
generator. **That ordering decision is the first thing to settle.**

**Then the gfx half — treat it as its own session.** The tenant's tiles
still sit in Jedah's band, so at `0x13` the tenant renders correctly and
**Jedah renders as the tenant**. Moving them into group C means:

- the WIDE bank encoding, which is **not** `bank << 13`: bank 4 = y-word
  `0x1000`, bank 5 = `0x3000` (bit 12 promoted after the list terminator —
  `docs/cps2_wide.md`);
- writing `vsw.31m/33m/35m/37m` (today zero fill from
  `build_wide_romset.py`) instead of vsav's group B, and getting them into
  `vsavjw.zip` rather than the patched `vsav.zip`;
- **and it makes queue item 4 below MANDATORY, not optional.** The
  descriptor still declares group C with the PRISTINE group B CRCs. Ship
  real content there and a user running against a pristine `vsav.zip`
  parent gets `vsw.31m` resolved BY HASH to pristine group B — the
  14z-60z bug class again, on the distributed artifact. Fix the descriptor
  CRCs in the same change: two emulator rebuilds, `test_mame_parity.sh`,
  and both profile gates.

Acceptance for M3a, unchanged: **legacy Jedah replays return to
bit-identical vanilla.** Not claimable until both halves land.
`build/m3a` (`f4769b55`) is a scratch build proving the program half only.

## What is already done (do not redo)

- **Program half of M3a.** The id is a build input (`--tenant-id`); all 31
  slot-indexed table rows move to `0x13`; the 30 `0x1F` mirror pokes are
  gone (Victor's `0x03` untouched by construction); a variant-id tenant
  without a profile is refused. Gate: `tests/test_tenant_id.sh`.
- **The frozen references still rebuild EXACTLY** — WIDE `9bac6ee3`, stock
  `ae701ffb` — which is why the manifest does not yet declare
  `id_by_profile`. Declare it in the same change that finishes M3a and
  re-freezes; `tests/test_tenant_id.sh` guards that and tells you so.
- **The WIDE sprite garble is fixed, playtested and gated** (a romset
  member shadowing a patched one; both emulators resolve by hash before
  name). `tests/test_wide_render_content.sh` is the rendering gate that was
  missing, `tools/audit_romset_identity.py` runs inside the build.
- **The WIDE reference is frozen and its suite is GREEN**: `9bac6ee3 ->
  donovan-m5w`, all 63 replays accounted for, CLAUDE.md §4 gained the
  ratified `composite` class.

## Ship state

| Track | Fingerprint | Packs as | Status |
|---|---|---|---|
| **WIDE** | `9bac6ee3` (`build/m5_wide`) | `vsavjw.zip` | frozen `donovan-m5w`, playtest-confirmed, suite GREEN |
| **stock** | `ae701ffb` (`build/m5_stock`) | `vsavj.zip` | frozen compatibility artifact; rebuilds exactly |
| ~~WIDE~~ | `ac52eeff` (`build/m5w`) | — | KNOWN-BAD (the garble), kept as evidence. Do not run |

```sh
tools/run_wide.sh build/m5_wide fbneo     # NOT build/m5w
MAME_BIN=~/.cache/vampire-saved/mame/cps2 \
MAME_ROMPATH="$PWD/build/m5_wide/rompath;$ROMDIR" tests/run_suite.sh vsavjw
```

## Queue after M3a

1. Fightability: the arcade opponent list (`a5-0x61B8`, length `$138(a5)`).
   Selectable is not fightable.
2. Huitzil `0x10` and Pyron `0x11` (multi-tenant manifests are refused until
   M3 Phase 3 — one tenant at a time, by design).
3. Medallion art (deferred deliberately until after de-substitution).
4. Group C descriptor CRCs — see above; **stops being optional the moment
   group C carries content.**
5. Minor win-screen palette items from the round-66 playtest. Unrelated.

## Gotchas most likely to bite

- **Compose the bank bits before dumping a tile band** — `tile = code |
  ((y & 0x6000) << 3)`. A dump at the wrong address returns a clean null
  that reads as exoneration. This cost two sessions.
- **A null result needs a negative control**, exactly as much as a positive
  one does.
- **A member carrying another member's pristine bytes shadows it** — both
  emulators resolve by HASH before NAME (`bzip.cpp:158`).
- Regenerate any rompath overlay built before the repo path lost its space;
  the symlinks in it are absolute and dangling.
- Audit manifests, not just code: `donovan.toml` carries hand-authored 68k
  in `thunk_hex`; a slot id hid there as `000f`.
- `run_replay_fbneo.sh` needs an **absolute** sandbox path; FBNeo has no
  `-rompath` and reads `roms/` relative to cwd.
- MAME write taps must be word-aligned, and MAME can segfault in teardown
  AFTER writing a complete log — assert on the `END` line, never the exit
  code.
