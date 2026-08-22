# VAMPIRE SAVED — merged-m6 (in-game mark: "M6")

Full-roster Vampire Savior on the real CPS-2 engine: the 15+1 of vsavj plus
Donovan, Huitzil/Phobos and Pyron, and a hand-pickable Oboro Bishamon. Runs
on the CPS-2 WIDE profile (a patched FBNeo / MAME with the `vsavjw` driver —
see the project's docs/project/cps2_wide.md).

THIS PACKAGE CONTAINS NO ROM DATA. It is a set of xdelta3 patches computed
against the four reference dumps you must already own, plus a manifest and
an applier that rebuilds the romset from YOUR dumps and verifies every byte.

## You need
- Python 3 and `xdelta3` on your PATH (`brew install xdelta`,
  `apt install xdelta3`, or the Windows build from the xdelta project).
- A directory holding the four reference zips, unmodified, with these
  exact names: `vsavj.zip` (Japan 970519), `vsav.zip` (Europe 970519),
  `vsav2.zip` (Japan 970913), `vhunt2.zip` (Japan 970929). The applier
  checks every member's SHA-1 against the manifest before doing anything.

## Apply
    python3 apply_release.py --romdir /path/to/your/dumps --out ./rompath

`./rompath/` then holds vsav.zip, vsavjw.zip. Point your patched emulator's rom path at it
(the project's `tools/run_wide.sh <build> fbneo|mame` does exactly that).
The applier refuses to write if any rebuilt member's SHA-1 does not match
the manifest — a wrong or modified dump produces a clear error, never a
silently broken set.

## Identify the build
- In game: the mark `M6` at the bottom-right of the
  character-select screen.
- On disk: program fingerprint `64426955`;
  every member's SHA-1 is in `manifest.json`.

## What is patched
20 members are patched, 22 are copied pristine from your dumps.
The patches hold only bytes the port generates or authors (relocated code,
tables, the version glyphs); everything copied from the original games is
expressed as a reference into YOUR dumps, which is what keeps this package
free of copyrighted content.
