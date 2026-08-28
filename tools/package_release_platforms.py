#!/usr/bin/env python3
"""package_release_platforms.py <build_rompath> <release_root> --romdir ROMDIR
                                --name NAME --version TEXT
                                [--mister-src DIR] [--platforms fbneo,mame,mister]

THE PER-PLATFORM RELEASE (maintainer-ruled 2026-08-28, 14z-113; the format
is docs/project/release_format.md).  One release = release/<NAME>/ with ONE
SUBDIRECTORY PER PLATFORM, each SELF-SUFFICIENT — everything that platform
needs and nothing else — and every version releases ALL platforms even when
only one of them changed:

  release/<NAME>/
    fbneo/    the romset patch set (package_release.py output, FLAT) +
              emulator/0002-cps2-wide-v1.patch + EMULATOR.md (pin + recipe)
    mame/     the romset patch set + emulator/0002-cps2-wide-v1.patch +
              EMULATOR.md (pin + recipe)
    mister/   the romset patch set + the .mra files + BITSTREAM.txt (+ the
              jtcps2w.rbf itself whenever it is present in --mister-src)

The romset patch set is COPIED into each platform directory rather than
shared (ruled: self-sufficiency beats de-duplication; ~2.5 MB x 3).  It is
produced by tools/package_release.py — this script never computes a patch
itself, so the round-trip / refusal / rule-7 guarantees of that tool hold
unchanged for every copy, and the three copies are asserted IDENTICAL
(manifest.json byte-for-byte) by tests/test_release_roundtrip.sh section 4.

The emulator side ships the driver PATCH and a build recipe, never a binary
(ruled: the patch is the reviewable trust surface; binaries are host-specific
and MAME's is a SOURCES-filtered build).  The MiSTer side ships the MRAs the
release was verified with (from the field bundle or tools/mister_mra.sh
--no-rom — deterministic XML, no ROM content) and the bitstream RECORD; the
.rbf is copied when --mister-src holds one, and its absence is stated in
BITSTREAM.txt rather than hidden.

Rule 7: nothing here reads a reference ROM except through package_release.py
(which reads them only to compute deltas), and nothing ROM-derived is written.
Deterministic: two runs produce byte-identical trees.
"""
import argparse, os, shutil, subprocess, sys, tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.dirname(HERE)
PLATFORMS = ("fbneo", "mame", "mister")

EMU = {
    "fbneo": dict(
        patch="emu/fbneo-patches/0002-cps2-wide-v1.patch",
        submodule="emu/fbneo",
        upstream="https://github.com/finalburnneo/FBNeo",
        recipe="""\
    git clone {upstream} fbneo && cd fbneo && git checkout {pin}
    git apply /path/to/emulator/0002-cps2-wide-v1.patch
    make sdl2 SKIPDEPEND=1 -j8        # SKIPDEPEND=1 is mandatory (see the project's docs/GOTCHAS.md)
""",
        note="""\
The patch adds the `vsavjw` driver (the CPS-2 WIDE profile: 6 MB program,
48 MB GFX via the CPS-2 Turbo bit-12 tile promote, 16 MB QSound) as a new
driver entry beside `vsavj`. Stock `vsavj` and every other CPS-2 game are
untouched by construction — the only emulation-logic change is one widened
condition in `cps_obj.cpp`, gated on the `Cps2Wide` flag that only the new
driver sets. The project's other FBNeo patch (0001, the replay harness) is a
frontend-only test instrument and is NOT needed to play.
NETPLAY: this is a custom build — every peer needs the same binary AND the
same romset (the patched build's fingerprint is in ../manifest.json).
""",
    ),
    "mame": dict(
        patch="emu/mame-patches/0002-cps2-wide-v1.patch",
        submodule="emu/mame",
        upstream="https://github.com/mamedev/mame",
        recipe="""\
    git clone {upstream} mame && cd mame && git checkout {pin}     # tag mame0288
    git apply /path/to/emulator/0002-cps2-wide-v1.patch
    make SOURCES=src/mame/capcom/cps2.cpp SUBTARGET=cps2 -j8    # CPS-2-only build, minutes not hours
    ./cps2 -verifyroms vsavjw                                   # must say: romset vsavjw [vsav] is good
""",
        note="""\
The patch is 164 lines added and exactly ONE line removed (the sprite
tile-code composition, gated on `m_cps2_wide`, a driver member only the
`vsavjw` machine config sets). It adds the `vsavjw` ROM descriptor, one
`GAME()` row and one `mame.lst` row. A Homebrew/distribution MAME binary
cannot load this romset — it has no `vsavjw` driver — so a source build is
required. MAME's own `-verifyroms vsavjw` is the independent check that the
romset the applier produced is the one the driver expects.
""",
    ),
}


def run_packager(rompath, romdir, name, version, dest):
    """package_release.py writes <out>/<name>/; we want it FLAT at <dest>."""
    with tempfile.TemporaryDirectory() as tmp:
        subprocess.run([sys.executable, os.path.join(HERE, "package_release.py"),
                        rompath, tmp, "--romdir", romdir, "--name", name,
                        "--version", version], check=True, stdout=subprocess.DEVNULL)
        src = os.path.join(tmp, name)
        if os.path.exists(dest):
            shutil.rmtree(dest)
        shutil.copytree(src, dest)


def pin_of(submodule):
    out = subprocess.run(["git", "-C", REPO, "submodule", "status", submodule],
                         capture_output=True, text=True).stdout.strip()
    return out.lstrip(" +-").split()[0] if out else "?"


def emulator_side(platform, dest, name):
    e = EMU[platform]
    edir = os.path.join(dest, "emulator")
    os.makedirs(edir, exist_ok=True)
    shutil.copy(os.path.join(REPO, e["patch"]), os.path.join(edir, os.path.basename(e["patch"])))
    pin = pin_of(e["submodule"])
    text = f"""# {name} — {platform.upper()} side

This directory is self-sufficient for {platform.upper()}: the romset patch
set (`patches/`, `manifest.json`, `apply_release.py`, `README.md`) and the
emulator driver patch in `emulator/`. Nothing for any other platform is here.

## The emulator
Upstream: {e['upstream']}
Pinned commit: `{pin}` (the exact tree the patch is known to apply to and
the project's gates were run against).

{e['recipe'].format(upstream=e['upstream'], pin=pin)}
{e['note']}
## The romset
Apply `apply_release.py` per `README.md`, then point the patched emulator's
rom path at the output directory. The set is `vsavjw` (a clone of `vsav`);
keep your pristine `vsav.zip` in the rom path too — the loader resolves the
unmodified members from it.
"""
    open(os.path.join(dest, "EMULATOR.md"), "w").write(text)


def mister_side(dest, src, name):
    if not src:
        print("  mister: no --mister-src given; MRAs/BITSTREAM not copied", file=sys.stderr)
        return
    copied = []
    for f in sorted(os.listdir(src)):
        if f.endswith(".mra") or f == "BITSTREAM.txt" or f.endswith(".rbf"):
            shutil.copy(os.path.join(src, f), os.path.join(dest, f))
            copied.append(f)
    if not any(f.endswith(".mra") for f in copied):
        sys.exit(f"--mister-src {src} holds no .mra file")
    if "BITSTREAM.txt" not in copied:
        sys.exit(f"--mister-src {src} holds no BITSTREAM.txt (seed / slack / sha256 record)")
    has_rbf = any(f.endswith(".rbf") for f in copied)
    text = f"""# {name} — MiSTer side

This directory is self-sufficient for MiSTer: the romset patch set
(`patches/`, `manifest.json`, `apply_release.py`, `README.md`), the `.mra`
files, and the bitstream record `BITSTREAM.txt`{' plus the bitstream itself' if has_rbf else ''}.

## On the SD card
    _Arcade/<the .mra files here>
    _Arcade/cores/jtcps2w.rbf        {'<- in this directory' if has_rbf else '<- NOT in this directory: see BITSTREAM.txt for the sha256 to verify against'}
    games/mame/vsavjw.zip            <- from apply_release.py
    games/mame/vsav.zip              <- your PRISTINE dump (the WIDE set is a clone of it)
    games/mame/vsavj.zip             <- your PRISTINE dump (the STOCK CONTROL MRA)
    games/mame/qsound.zip            <- dl-1425.bin

The WIDE MRA runs the full roster on `jtcps2w.rbf`. The `[STOCK CONTROL]`
MRA runs stock `vsavj` on the SAME bitstream with the profile bit at its
`0xFF` fill: it is the superset invariant on silicon and only needs running
when the BITSTREAM changes (new seed, slice or pin), not per release. Stock
Vampire Savior on Jotego's own `jtcps2.rbf` keeps working from the same
`vsav.zip` — the two coexist on one card (field-verified 2026-08-28).

VERIFY THE BITSTREAM'S sha256 BEFORE FLASHING: a timing-failing fitter seed
emits an .rbf indistinguishable from a passing one.
"""
    open(os.path.join(dest, "MISTER.md"), "w").write(text)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("rompath")
    ap.add_argument("release_root", help="e.g. release — the tree is written at release/<name>/")
    ap.add_argument("--romdir", required=True)
    ap.add_argument("--name", required=True)
    ap.add_argument("--version", required=True, help="the in-game mark, e.g. M8")
    ap.add_argument("--mister-src", default="", help="dir holding the .mra files, BITSTREAM.txt and (optionally) the .rbf")
    ap.add_argument("--platforms", default=",".join(PLATFORMS))
    a = ap.parse_args()
    plats = [p for p in a.platforms.split(",") if p]
    bad = [p for p in plats if p not in PLATFORMS]
    if bad:
        sys.exit(f"unknown platform(s): {bad}")
    root = os.path.join(a.release_root, a.name)
    os.makedirs(root, exist_ok=True)
    for p in plats:
        dest = os.path.join(root, p)
        run_packager(a.rompath, a.romdir, a.name, a.version, dest)
        if p in EMU:
            emulator_side(p, dest, a.name)
        else:
            mister_side(dest, a.mister_src, a.name)
        n = sum(len(f) for _, _, f in os.walk(dest))
        print(f"  {p}: {n} files -> {dest}")
    print(f"packaged {a.name} for {', '.join(plats)} -> {root}")


if __name__ == "__main__":
    main()
