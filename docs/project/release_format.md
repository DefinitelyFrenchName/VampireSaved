# The release format — one release, one directory per platform

**Ruled by the maintainer, 2026-08-28 (14z-113).** Supersedes the single
`release/<name>/<name>/` patch package of 14z-105 for every release from
merged-m10 on; `release/merged-m6..m9/` keep the old layout as history.

## The rule

`release/<name>/` holds **one subdirectory per platform**, and each one is
**self-sufficient: everything that platform needs and nothing else.** A
FBNeo user never sees a `.mra`; a MiSTer user never sees a driver patch.
**Every version releases every platform**, even when the change touched
only one of them — a release is a version of the whole project, not of the
part that moved.

```
release/<name>/
  fbneo/    patches/ manifest.json apply_release.py README.md   <- the romset patch set
            emulator/0002-cps2-wide-v1.patch  EMULATOR.md       <- the driver patch + pin + recipe
  mame/     patches/ manifest.json apply_release.py README.md
            emulator/0002-cps2-wide-v1.patch  EMULATOR.md
  mister/   patches/ manifest.json apply_release.py README.md
            *.mra  BITSTREAM.txt  [jtcps2w.rbf]  MISTER.md       <- the MRAs, the bitstream record, the bitstream
```

* **The romset patch set is COPIED into each platform directory** (ruled:
  self-sufficiency beats de-duplication, ~2.5 MB × 3). All three copies are
  produced by the same `tools/package_release.py` run parameters and are
  asserted byte-identical by the gate, so the round-trip, refusal and rule-7
  guarantees of that tool hold for every copy.
* **FBNeo and MAME ship the driver PATCH and a build recipe, never a
  binary** (ruled). The patch is the reviewable trust surface
  (`emu/fbneo-patches/0002`, `emu/mame-patches/0002` — one profile expressed
  twice); the recipe names the pinned upstream commit.
* **MiSTer ships the MRAs the release was verified with, the bitstream
  RECORD (`BITSTREAM.txt`: seed, slack, sha256, build date, fork pin, field
  history), and the `.rbf` itself** — ruled tracked in-tree, "as would any
  BPS or xdelta". When the file is not on the packaging machine the record
  says so instead of the directory silently lacking it; the `.rbf` moves on
  its own cadence (unchanged 14z-108 → 14z-113 while the romset moved four
  times), so the record is what ties a romset release to the bitstream it
  was verified with. The `[STOCK CONTROL]` MRA is included and labelled
  "run when the bitstream changes".
* **No ROM content anywhere** (CLAUDE.md rule 7): patches are xdelta against
  the reference dumps, MRAs are XML metadata, the `.rbf` is GPL-3.0 output
  of a public fork.

## How it is produced

```sh
ROMDIR=... python3 tools/package_release_platforms.py build/<dir>/rompath release \
    --name <name> --version <mark> --mister-src <dir with *.mra, BITSTREAM.txt[, jtcps2w.rbf]>
```

The MRAs come from the field bundle (`tools/mister_mra.sh --no-rom` produces
the same XML deterministically); `BITSTREAM.txt` is written by hand from the
synthesis record (`docs/platform/mister.md` "REPRODUCING THE SHIPPING
BITSTREAM"). **Gate: `tests/test_release_roundtrip.sh`** — sections 1-3 are
the 14z-105 guarantees on the patch set; **section 4 (14z-113) locks this
layout** on the tree's `release/<name>/`: the three platform directories
present, each with the four patch-set files, the three `manifest.json`
byte-identical, `emulator/0002-*.patch` identical to `emu/*-patches/0002`,
`mister/` holding at least one `.mra` and `BITSTREAM.txt`, and a must-fire
control (a copy with `mame/emulator/` removed must fail).

## Where a release's history is

The registry row in `HANDOFF.md` "Build registry", the annotated tag
`freeze/<name>`, and STATE's freeze entry. `release/<name>/` is the
distributable; the registry is the provenance.
