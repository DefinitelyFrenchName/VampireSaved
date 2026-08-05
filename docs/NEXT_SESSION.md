# NEXT SESSION — orientation (written at the close of 14z-62, 2026-08-06)

**Start here: M3a has ONE half left — the GFX half.** The select-records
half landed this session: at `--tenant-id 0x13` the generator composes the
tenant's own six select records, the six variant-half array rows are poked,
select_port does not run, and the host's select-family PROGRAM bytes are
vanilla again. Gated (`tests/test_tenant_select_records.sh`, in the
battery), measured in-emulator (the engine fetches the tenant's records on
cell 0x13), and both frozen references still rebuild exactly
(`ae701ffb` / `9bac6ee3`). Read STATE.md `14z-62` for the detail.

## The gfx half — what it is and what 14z-62 added to it

The tenant's tiles still occupy Jedah's bank-2 fighter band, so at `0x13`
the tenant renders correctly and **Jedah renders as the tenant** — and
14z-62 measured that this covers the SELECT SCREEN too: 89/92 of Jedah's
select-portrait tiles sit inside the placed band `[0xAD8F,0xEA3F]` (his
select art is bank-2 band art, not select-bank art). So visual
de-substitution everywhere hinges on the one move. It means:

- the WIDE bank encoding, which is **not** `bank << 13`: bank 4 = y-word
  `0x1000`, bank 5 = `0x3000` (bit 12 promoted after the list terminator —
  `docs/cps2_wide.md`);
- writing `vsw.31m/33m/35m/37m` (today zero fill from
  `build_wide_romset.py`) instead of vsav's group B, and getting them into
  `vsavjw.zip` rather than the patched `vsav.zip`;
- **group C descriptor CRCs become load-bearing** (queue item, now
  MANDATORY with content in group C): today the descriptor declares group C
  with pristine group B CRCs, so a user with a pristine `vsav.zip` parent
  would get `vsw.31m` resolved BY HASH to pristine group B — the 14z-60z
  bug class on the distributed artifact. Fix in the same change: two
  emulator rebuilds, `test_mame_parity.sh`, both profile gates;
- the four select placeholder tiles (name/p2 `0xB22C+0xB2A5`, highlight
  `0xB000`/`0xB129` — the lit name label) get real homes in group C, and
  `select_tiles.json` placements move off Jedah's bank-1 anchors.

Acceptance for M3a, unchanged: **legacy Jedah replays return to
bit-identical vanilla.** Then declare `id_by_profile = "cps2-wide-v1=0x13"`
in the manifest and RE-FREEZE the WIDE reference in the same change —
`tests/test_tenant_id.sh` guards exactly this and tells you so.

## Also open on the select screen at a variant id (measure BEFORE building)

- **Splash (VS screen), win-quote, select-palette mechanisms at 0x13.**
  The slot-0x0F in-place families are simply not applied on variant-id
  builds; those paths currently resolve 0x13 natively (folds → Victor-ish
  content — Donovan's portrait draws in Victor's colors). vs2 special-cases
  some (`cmpi #$13` in its palette uploader at `0x6B1A0`). Find the vsavj
  consumers first; some may need site thunks (engine-hook class).
- **P2-side runtime measurement**: the gate drives the P1 cursor only; a
  2P replay onto cell 0x13 would close the loop (statics already verify P2).

## What is already done (do not redo)

- **Select records at 0x13** (this session — see above). Checker:
  `tools/check_tenant_select.py`. Scratch build `build/m3a_selrec`
  (`dd88f343`) — program+records halves proven; NOT a candidate.
- **Program half of M3a** (14z-61): `--tenant-id` build input, 31 table
  rows at 0x13, no mirror pokes, variant-id-without-profile refused; now
  also 0x12/0x18 refused (reserved).
- **The WIDE reference is frozen and its suite is GREEN**: `9bac6ee3 ->
  donovan-m5w`, all 63 replays accounted for, §4 v4 `composite` ratified.
- **The WIDE sprite garble class is fixed and gated**
  (`test_wide_render_content.sh`, `audit_romset_identity.py` in the build).

## Ship state

| Track | Fingerprint | Packs as | Status |
|---|---|---|---|
| **WIDE** | `9bac6ee3` (`build/m5_wide`) | `vsavjw.zip` | frozen `donovan-m5w`, playtest-confirmed, suite GREEN |
| **stock** | `ae701ffb` (`build/m5_stock`) | `vsavj.zip` | frozen compatibility artifact; rebuilds exactly |
| scratch | `dd88f343` (`build/m3a_selrec`) | `vsavjw.zip` | 14z-62 select-records evidence build (tenant at 0x13); do not ship |
| ~~WIDE~~ | `ac52eeff` (`build/m5w`) | — | KNOWN-BAD (the garble), kept as evidence. Do not run |

```sh
tools/run_wide.sh build/m5_wide fbneo     # the frozen reference
MAME_BIN=~/.cache/vampire-saved/mame/cps2 \
MAME_ROMPATH="$PWD/build/m5_wide/rompath;$ROMDIR" tests/run_suite.sh vsavjw
# the M3a gates:
export ROMDIR=/Users/koneko/Developer/Vampire_Saved/ROMS
tests/test_tenant_id.sh
tests/test_tenant_select_records.sh build/m3a_selrec   # or no arg = fresh build
```

## Queue after M3a

1. Fightability: the arcade opponent list (`a5-0x61B8`, length `$138(a5)`).
   Selectable is not fightable.
2. Huitzil `0x10` and Pyron `0x11` (multi-tenant manifests are refused until
   M3 Phase 3 — one tenant at a time, by design).
3. Medallion art (deferred deliberately until after de-substitution).
4. Minor win-screen palette items from the round-66 playtest. Unrelated.

## Gotchas most likely to bite

- **"Inside the placed band window" means min/max bounds, not "overwritten"**
  — the band placement is sparse; intersect with the actual placed tiles
  before concluding (Jedah's name renders, his portrait doesn't: same
  window).
- **Compose the bank bits before dumping a tile band** — `tile = code |
  ((y & 0x6000) << 3)`. A clean null at the wrong address reads as
  exoneration. This cost two sessions.
- **A null result needs a negative control**, exactly as much as a positive
  one does.
- **A member carrying another member's pristine bytes shadows it** — both
  emulators resolve by HASH before NAME (`bzip.cpp:158`).
- Regenerate any rompath overlay built before the repo path lost its space;
  the symlinks in it are absolute and dangling.
- `run_replay_fbneo.sh` needs an **absolute** sandbox path; FBNeo has no
  `-rompath` and reads `roms/` relative to cwd.
- MAME write taps must be word-aligned, and MAME can segfault in teardown
  AFTER writing a complete log — assert on the `END` line, never the exit
  code.
