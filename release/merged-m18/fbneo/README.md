# VAMPIRE SAVED — merged-m18 (in-game mark "M18")

Full-roster Vampire Savior on the real CPS-2 engine: the 15+1 of vsavj plus
Donovan, Huitzil/Phobos and Pyron, and a hand-pickable Oboro Bishamon. Runs
on the CPS-2 WIDE profile — an extended CPS-2 board that a patched FBNeo, a
patched MAME (driver `vsavjw`) or the `jtcps2w` MiSTer core implements.

**THIS PACKAGE CONTAINS NO ROM DATA AND NO COPYRIGHTED ASSET, EVER.** It is a
set of patches computed against the three reference dumps you must already
own, a manifest, and an applier that rebuilds the romset from YOUR dumps and
verifies every byte before writing anything. Nothing in it can be played
without your own dumps.

## What is in this package
- `patches/` — 20 VCDIFF patch files (xdelta3 format), one per rebuilt member
- `manifest.json` — every target member's SHA-1 and size, which members are
  copied pristine from which dump, the exact source recipe
- `apply_release.py` — the applier (Python 3, nothing else needed)
- this README, plus the platform notes beside it

## What you need
- **Python 3** (3.8 or newer). No other tool: the applier decodes the
  patches itself.
- **The three reference dumps, unmodified, with these exact names** in one
  directory: `vsavj.zip` (Vampire Savior, Japan 970519), `vsav.zip` (Europe
  970519), `vsav2.zip` (Vampire Savior 2, Japan 970913). Vampire Hunter 2 is
  NOT needed (it is the project's verification oracle, not a source of
  anything in the set). The applier checks every member's SHA-1
  against the manifest before doing anything, so a wrong, renamed or
  modified dump is reported by name, never silently patched over.

## Build the romset (one command)
    python3 apply_release.py --romdir /path/to/your/dumps --out ./rompath

`./rompath/` then holds `vsavjw.zip`. The applier refuses to write if any rebuilt
member's SHA-1 does not match the manifest. Keep your pristine `vsav.zip`
next to it when you play: the WIDE set is a clone of `vsav` and the emulator
resolves the unmodified members from the parent.

## Identify the build
- In game: the mark `M18` at the bottom-right of the
  character-select screen, and the boot name screen reads VAMPIRE SAVED.
- On disk: whole-set key `00f9cf13` (`manifest.json` has every member's SHA-1).

## If it does not work
- **"Unknown system: vsavjw" / "no such driver"** — the emulator is not the
  patched one. Use the prebuilt binary or the recipe in `EMULATOR.md`.
- **The game sits on the QSound / CAPCOM legal screen and never reaches the
  title** — you renamed the set to force it into an unpatched emulator. The
  stock 4 MB driver never loads the program extension, the sound driver or
  the QSound extension, so the boot handshake never completes (measured
  2026-09-11: no crash, no gameplay, the legal screen forever). It needs the
  patched emulator; renaming is never the fix.
- **"reference dumps do not match the manifest"** — a dump is wrong,
  modified or from another region; the message names the member.
- **Netplay** — every peer needs the same emulator build AND the same romset
  (compare the whole-set key above).

## What is patched
20 members are rebuilt, 5 are copied pristine from your dumps.
The patches hold only bytes the port generates or authors (relocated code,
tables, the version glyphs); everything that comes from the original games
is expressed as a reference into YOUR dumps, which is what keeps this package
free of copyrighted content — and a gate scans every patch for verbatim
reference-ROM bytes before a release is cut.

## Play on FBNEO
1. Get the patched emulator — EITHER a prebuilt binary (prebuilt binaries for: macos-arm64 — download `merged-m18-fbneo-<os-arch>.zip` from the GitHub release on tag `freeze/merged-m18` (https://github.com/DefinitelyFrenchName/VampireSaved/releases/tag/freeze/merged-m18); each zip carries a `BINARY.txt` (also here under `emulator/bin/<os-arch>/`) — verify every file's sha256 against it after unzipping), OR build it
   yourself from the pinned upstream with the driver patch: `EMULATOR.md` has
   the exact commands. Both are the same code; the patch is 0002-cps2-wide-v1.
2. Put `vsavjw.zip` (from the applier) AND your pristine `vsav.zip` in the
   emulator's rom directory (FBNeo has no rom-path option: it reads `roms/` next to the binary, or the dirs set in its config).
3. Start the set `vsavjw`. The boot name screen reads VAMPIRE SAVED and the
   select screen shows the mark M18.
