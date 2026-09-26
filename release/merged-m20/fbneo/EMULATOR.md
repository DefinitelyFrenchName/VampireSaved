# merged-m20 — FBNEO side

This directory is self-sufficient for FBNEO: the romset patch
set (`patches/`, `manifest.json`, `apply_release.py`, `apply_release.html`,
`README.md`) and the
emulator driver patch in `emulator/`. Nothing for any other platform is here.

## The emulator
Upstream: https://github.com/finalburnneo/FBNeo
Pinned commit: `79188379cc8442c54712acbe3b7e73dce157985f` (the exact tree the patch is known to apply to and
the project's gates were run against).

    git clone https://github.com/finalburnneo/FBNeo fbneo && cd fbneo && git checkout 79188379cc8442c54712acbe3b7e73dce157985f
    git apply /path/to/emulator/0002-cps2-wide-v1.patch
    make sdl2 SKIPDEPEND=1 -j8 -k     # SKIPDEPEND=1 is mandatory (see the project's docs/GOTCHAS.md);
    make sdl2 SKIPDEPEND=1 -j8        # TWICE on a fresh clone: the parallel first pass stops on burn.o
                                      # until the driver list is generated (-k lets it finish the rest)

The patch adds the `vsavjw` driver (the CPS-2 WIDE profile: 6 MB program,
48 MB GFX via the CPS-2 Turbo bit-12 tile promote, 16 MB QSound) as a new
driver entry beside `vsavj`. Stock `vsavj` and every other CPS-2 game are
untouched by construction — the only emulation-logic change is one widened
condition in `cps_obj.cpp`, gated on the `Cps2Wide` flag that only the new
driver sets. The project's other FBNeo patch (0001, the replay harness) is a
frontend-only test instrument and is NOT needed to play.
NETPLAY: this is a custom build — every peer needs the same binary AND the
same romset (the patched build's fingerprint is in ../manifest.json).

## The romset
Apply the patch set per `README.md` — double-click `apply_release.html`, or run
`apply_release.py` — then point the patched emulator's
rom path at the output directory. The set is `vsavjw` and it is STANDALONE:
the applier copies in every member the loader asks for, the parent's and
MAME's QSound BIOS member included, so the output directory needs nothing
beside it.

## Prebuilt binaries — the other route

**You are reading the build route.** If you would rather not build, the
release on tag `freeze/merged-m20` (https://github.com/DefinitelyFrenchName/VampireSaved/releases/tag/freeze/merged-m20) also publishes
`merged-m20-fbneo-<os-arch>.zip`: the SAME package as this one, with a
prebuilt patched emulator in place of this patch and recipe. It is complete
too — romset patches and applier included — so it replaces this download
rather than joining it.

Built so far for: macos-arm64, windows-x86_64. Each carries a `BINARY.txt` naming every file with its sha256, the upstream pin and the sha1 of the driver patch beside this file — the binary is exactly the recipe above, run on one host, and the record says which. Only the latest freeze keeps its assets; the binaries are never files in the repository (ruled 2026-09-11).

## If it does not work
- "Unknown system: vsavjw" — this binary does not carry the driver patch.
- The set, RENAMED to `vsavj.zip` to force it into a stock emulator, sits on
  the QSound / CAPCOM legal screen forever (measured 2026-09-11: the stock 4 MB
  driver never loads the program extension, the sound driver or the QSound
  extension; no crash, no gameplay). Renaming is never the fix.
