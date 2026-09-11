# merged-m18 — MAME side

This directory is self-sufficient for MAME: the romset patch
set (`patches/`, `manifest.json`, `apply_release.py`, `README.md`) and the
emulator driver patch in `emulator/`. Nothing for any other platform is here.

## The emulator
Upstream: https://github.com/mamedev/mame
Pinned commit: `27a8d9e85b58058965907d1d8a7a92f8ed039348` (the exact tree the patch is known to apply to and
the project's gates were run against).

    git clone https://github.com/mamedev/mame mame && cd mame && git checkout 27a8d9e85b58058965907d1d8a7a92f8ed039348     # tag mame0288
    git apply /path/to/emulator/0002-cps2-wide-v1.patch
    make SOURCES=src/mame/capcom/cps2.cpp SUBTARGET=cps2 -j8    # CPS-2-only build, minutes not hours
    ./cps2 -verifyroms vsavjw                                   # must say: romset vsavjw [vsav] is good

The patch is 164 lines added and exactly ONE line removed (the sprite
tile-code composition, gated on `m_cps2_wide`, a driver member only the
`vsavjw` machine config sets). It adds the `vsavjw` ROM descriptor, one
`GAME()` row and one `mame.lst` row. A Homebrew/distribution MAME binary
cannot load this romset — it has no `vsavjw` driver — so a source build is
required. MAME's own `-verifyroms vsavjw` is the independent check that the
romset the applier produced is the one the driver expects.

## The romset
Apply `apply_release.py` per `README.md`, then point the patched emulator's
rom path at the output directory. The set is `vsavjw` (a clone of `vsav`);
keep your pristine `vsav.zip` in the rom path too — the loader resolves the
unmodified members from it.

## Prebuilt binaries
None in this release yet (ruled 2026-09-11: releases ship the recipe AND prebuilt binaries per OS; the binaries are a build resource under `release/emulators/` in the project tree and are added as each host builds them). The recipe above is complete.

## If it does not work
- "Unknown system: vsavjw" — this binary does not carry the driver patch.
- The set, RENAMED to `vsavj.zip` to force it into a stock emulator, sits on
  the QSound / CAPCOM legal screen forever (measured 2026-09-11: the stock 4 MB
  driver never loads the program extension, the sound driver or the QSound
  extension; no crash, no gameplay). Renaming is never the fix.
