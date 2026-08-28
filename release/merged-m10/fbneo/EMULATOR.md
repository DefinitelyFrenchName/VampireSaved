# merged-m10 — FBNEO side

This directory is self-sufficient for FBNEO: the romset patch
set (`patches/`, `manifest.json`, `apply_release.py`, `README.md`) and the
emulator driver patch in `emulator/`. Nothing for any other platform is here.

## The emulator
Upstream: https://github.com/finalburnneo/FBNeo
Pinned commit: `79188379cc8442c54712acbe3b7e73dce157985f` (the exact tree the patch is known to apply to and
the project's gates were run against).

    git clone https://github.com/finalburnneo/FBNeo fbneo && cd fbneo && git checkout 79188379cc8442c54712acbe3b7e73dce157985f
    git apply /path/to/emulator/0002-cps2-wide-v1.patch
    make sdl2 SKIPDEPEND=1 -j8        # SKIPDEPEND=1 is mandatory (see the project's docs/GOTCHAS.md)

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
Apply `apply_release.py` per `README.md`, then point the patched emulator's
rom path at the output directory. The set is `vsavjw` (a clone of `vsav`);
keep your pristine `vsav.zip` in the rom path too — the loader resolves the
unmodified members from it.
