# merged-m23 — MAME side

This directory is self-sufficient for MAME: the romset patch
set (`patches/`, `manifest.json`, `apply_release.py`, `apply_release.html`,
`README.md`) and the
emulator driver patch in `emulator/`. Nothing for any other platform is here.

## The emulator
Upstream: https://github.com/mamedev/mame
Pinned commit: `27a8d9e85b58058965907d1d8a7a92f8ed039348` (the exact tree the patch is known to apply to and
the project's gates were run against).

Install these first (the packages the project's own build hosts carry; a
missing one stops the build):

- **Linux (Ubuntu 24.04 / Debian):** `sudo apt install git build-essential python3 libsdl2-dev libsdl2-ttf-dev libfontconfig-dev qmake6`
  — `qmake6` is the tool only, no Qt is linked: MAME's Linux build asks it for a
  folder, and without it the build fails minutes in with `char8_t` errors.
- **macOS:** the Command Line Tools (`xcode-select --install`), then Homebrew
  `brew install sdl3 pkgconf`
- **Windows:** MSYS2, in its MINGW64 shell:
  `pacman -S git make patch mingw-w64-x86_64-gcc mingw-w64-x86_64-pkgconf mingw-w64-x86_64-python`

    git clone https://github.com/mamedev/mame mame && cd mame && git checkout 27a8d9e85b58058965907d1d8a7a92f8ed039348     # tag mame0288
    git apply /path/to/emulator/0002-cps2-wide-v1.patch
    make SOURCES=src/mame/capcom/cps2.cpp SUBTARGET=cps2 -j8                  # macOS, Windows (MSYS2 MINGW64)
    make SOURCES=src/mame/capcom/cps2.cpp SUBTARGET=cps2 USE_QTDEBUG=0 -j8    # LINUX: MAME turns its Qt debugger
                                                                 # ON there by default, then stops on a missing `moc`;
                                                                 # USE_QTDEBUG=0 turns it off (no Qt is linked)
    ./cps2 -verifyroms vsavjw -rompath "/your/built/set"   # says "is bad" BY DESIGN: it lists every member the
                                                           # port rewrites or adds as INCORRECT CHECKSUM (the driver
                                                           # carries the stock CRCs for the members the port rewrites
                                                           # and sentinel CRCs for the new ones); the members copied
                                                           # unchanged from your dumps are not listed. Nothing may be
                                                           # NOT FOUND. "is good" is not reachable on this set.
    ./cps2 vsavjw -rompath "/your/built/set" -skip_gameinfo   # PLAY: -skip_gameinfo removes one of the two
                                                              # screens that wait for a key; the red box is the other

The patch is 164 lines added and exactly ONE line removed (the sprite
tile-code composition, gated on `m_cps2_wide`, a driver member only the
`vsavjw` machine config sets). It adds the `vsavjw` ROM descriptor, one
`GAME()` row and one `mame.lst` row. A Homebrew/distribution MAME binary
cannot load this romset — it has no `vsavjw` driver — so a source build is
required. MAME's own `-verifyroms vsavjw` is the independent check that the
romset the applier produced is the one the driver expects.

## The romset
Apply the patch set per `README.md` — double-click `apply_release.html`, or run
`apply_release.py` — then point the patched emulator's
rom path at the output directory. The set is `vsavjw` and it is STANDALONE:
the applier copies in every member the loader asks for, the parent's and
MAME's QSound BIOS member included, so the output directory needs nothing
beside it.

## Prebuilt binaries — the other route

**You are reading the build route.** If you would rather not build, the
release on tag `freeze/merged-m23` (https://github.com/DefinitelyFrenchName/VampireSaved/releases/tag/freeze/merged-m23) also publishes
`merged-m23-mame-<os-arch>.zip`: the SAME package as this one, with a
prebuilt patched emulator in place of this patch and recipe. It is complete
too — romset patches and applier included — so it replaces this download
rather than joining it.

Built so far for: linux-x86_64, macos-arm64, windows-x86_64. Each carries a `BINARY.txt` naming every file with its sha256, the upstream pin and the sha1 of the driver patch beside this file — the binary is exactly the recipe above, run on one host, and the record says which. Only the latest freeze keeps its assets; the binaries are never files in the repository (ruled 2026-09-11).

## If it does not work
- "Unknown system: vsavjw" — this binary does not carry the driver patch.
- The set, RENAMED to `vsavj.zip` to force it into a stock emulator, sits on
  the QSound / CAPCOM legal screen forever (measured 2026-09-11: the stock 4 MB
  driver never loads the program extension, the sound driver or the QSound
  extension; no crash, no gameplay). Renaming is never the fix.
- Four "Driver is a clone of nonexistent driver megaman" errors at every start
  (`mmancp2u`, `mmancp2ur1`, `mmancp2ur2`, `rmancp2j`) are expected and harmless:
  the build is filtered to the CPS-2 drivers and their parent lives outside them.
- The red "One or more ROMs/disk images for this system are incorrect" box at every
  start is expected and harmless: press any key. The driver carries the stock CRCs
  for the members the port rewrites and sentinel CRCs for the new ones (the
  `-verifyroms` note above), and MAME 0.288 never lets `-skip_warnings` skip a
  ROM-load warning (`src/frontend/mame/ui/ui.cpp`, `display_startup_screens`).
  The applier has already verified every member's sha1 (#234).
