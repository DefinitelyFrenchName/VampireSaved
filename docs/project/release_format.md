# The release format — one release, one directory per platform

**Ruled by the maintainer, 2026-08-28 (14z-113).** Supersedes the single
`release/<name>/<name>/` patch package of 14z-105 for every release from
merged-m10 on; `release/merged-m6..m9/` keep the old layout as history.

## WHICH MRAs SHIP, AND WHY IT IS BY SETNAME (14z-126b, 2026-09-02)

A release's `mister/` carries exactly TWO MRAs: the WIDE roster set
(`vsavjw`) and the `[STOCK CONTROL]` reference leg (`vsavj`, run once per new
bitstream — maintainer, 2026-08-29).

`tools/package_release_platforms.py` selects them by reading each candidate
MRA's own `<setname>`, walking `--mister-src` RECURSIVELY, and FAILING if
either is absent. It does NOT glob a directory level, because the level an
MRA lands in is a jtframe layout decision: clones go to
`release/mra/_alternatives/<parent>/` unless their setname is in the core's
`parse.main_setnames`. When cps2w made the WIDE set main (so the roster stops
being buried in the MiSTer menu), the stock control leg MOVED into
`_alternatives` — and a non-recursive glob would have dropped it from every
release silently. Selecting on setname is layout-independent and loud.


## The rule

**[MSV-20]** `release/<name>/` holds **one subdirectory per platform**, and each one is
**self-sufficient: everything that platform needs and nothing else.** A
FBNeo user never sees a `.mra`; a MiSTer user never sees a driver patch.
**Every version releases every platform**, even when the change touched
only one of them — a release is a version of the whole project, not of the
part that moved.

```
release/bitstreams/                                             <- THE BUILD RESOURCE (one dir per fitter seed)
  CURRENT                                                       <- names the seed every release packages from
  18269/  jtcps2w.rbf  BITSTREAM.txt                            <- the bitstream + its record (seed, slack, sha256)
release/<name>/
  fbneo/    patches/ manifest.json apply_release.py README.md   <- the romset patch set
            emulator/0002-cps2-wide-v1.patch  EMULATOR.md       <- the driver patch + pin + recipe
  mame/     patches/ manifest.json apply_release.py README.md
            emulator/0002-cps2-wide-v1.patch  EMULATOR.md
  mister/   patches/ manifest.json apply_release.py README.md
            *.mra  jtcps2w.rbf  BITSTREAM.txt  MISTER.md        <- the MRAs, the bitstream (hash-verified copy), its record
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
* **[MSC-62]** **MiSTer ships the MRAs the release was verified with, the `.rbf` itself
  and its RECORD (`BITSTREAM.txt`: seed, slack, sha256, build date, fork
  pin, field history)** — ruled tracked in-tree, "as would any BPS or
  xdelta". **The bitstream is a BUILD RESOURCE with its own cadence**
  (unchanged 14z-108 → 14z-113 while the romset moved four times), so it
  lives ONCE, canonically, under **`release/bitstreams/<seed>/{jtcps2w.rbf,
  BITSTREAM.txt}`** with **`release/bitstreams/CURRENT`** naming the seed
  every release packages from (maintainer, 2026-08-28: "a common build
  resource, itself rebuildable with the correct environment, so that every
  release includes it — never copied from another release"). The packager
  resolves `CURRENT` (or `--bitstream DIR`), verifies the file's sha256
  against the record and REFUSES on mismatch, then copies both into
  `mister/`. A rebuilt bitstream (new seed, slice or pin) gets its own
  directory and a `CURRENT` bump — never an overwrite: a timing-failing
  seed emits an indistinguishable `.rbf`, and the same seed rebuilds to a
  different hash on a different day, so the record IS the identity. The
  `[STOCK CONTROL]` MRA is included and labelled "run when the bitstream
  changes".
* **No ROM content anywhere** (CLAUDE.md rule 7): patches are xdelta against
  the reference dumps, MRAs are XML metadata, the `.rbf` is GPL-3.0 output
  of a public fork.

## How it is produced

```sh
ROMDIR=... python3 tools/package_release_platforms.py build/<dir>/rompath release \
    --name <name> --version <mark> --mister-src <dir with the *.mra files> [--bitstream release/bitstreams/<seed>]
```

The MRAs come from the field bundle (`tools/mister_mra.sh --no-rom` produces
the same XML deterministically); the bitstream and its record come from
`release/bitstreams/<CURRENT>/` (the record is written by hand from the
synthesis log — `docs/platform/mister.md` "REPRODUCING THE SHIPPING
BITSTREAM" — when a new bitstream is added). **Gate:
`tests/test_release_roundtrip.sh`** — sections 1-3 are the 14z-105
guarantees on the patch set; **section 4 (14z-113) locks this layout** on
the tree's `release/<name>/`: the three platform directories present, each
with the four patch-set files, the three `manifest.json` byte-identical,
`emulator/0002-*.patch` identical to `emu/*-patches/0002`, `mister/`
holding at least one `.mra`, the `.rbf` whose sha256 EQUALS its
`BITSTREAM.txt`, that record byte-identical to the canonical
`release/bitstreams/<CURRENT>/` one, no cross-platform leakage, and a
must-fire control (a copy with `mame/emulator/` removed must fail). The
packager's own refusal (a record whose sha256 does not match the file) was
exercised by hand at 14z-113.

## Where a release's history is

The registry row in `HANDOFF.md` "Build registry", the annotated tag
`freeze/<name>`, and STATE's freeze entry. `release/<name>/` is the
distributable; the registry is the provenance.
