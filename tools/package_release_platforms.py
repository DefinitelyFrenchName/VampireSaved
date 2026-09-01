#!/usr/bin/env python3
"""package_release_platforms.py <build_rompath> <release_root> --romdir ROMDIR
                                --name NAME --version TEXT
                                [--mister-src DIR] [--bitstream DIR]
                                [--platforms fbneo,mame,mister]

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
    mister/   the romset patch set + the .mra files + jtcps2w.rbf +
              BITSTREAM.txt — the bitstream and its record come from the
              CANONICAL build resource release/bitstreams/<seed>/ (the seed
              named by release/bitstreams/CURRENT, or --bitstream DIR), and
              the .rbf is VERIFIED against the record's sha256 before it is
              copied. A release never copies a bitstream from another
              release (maintainer, 2026-08-28).

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
--no-rom — deterministic XML, no ROM content); the bitstream and its RECORD
are pulled from release/bitstreams/ and hash-verified, so a stale CURRENT or a
tampered file is a hard error, never a silently wrong release.

Rule 7: nothing here reads a reference ROM except through package_release.py
(which reads them only to compute deltas), and nothing ROM-derived is written.
Deterministic: two runs produce byte-identical trees.
"""
import argparse, os, re, shutil, subprocess, sys, tempfile

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


def resolve_bitstream(arg):
    """release/bitstreams/CURRENT names the seed dir unless --bitstream overrides."""
    if arg:
        return arg
    root = os.path.join(REPO, "release", "bitstreams")
    cur = os.path.join(root, "CURRENT")
    if not os.path.exists(cur):
        sys.exit(f"{cur} missing — no canonical bitstream to package (see docs/project/release_format.md)")
    return os.path.join(root, open(cur).read().strip())


def bitstream_side(dest, bdir):
    rec = os.path.join(bdir, "BITSTREAM.txt")
    rbfs = [f for f in os.listdir(bdir) if f.endswith(".rbf")]
    if not os.path.exists(rec) or len(rbfs) != 1:
        sys.exit(f"{bdir} must hold exactly one .rbf and a BITSTREAM.txt (found {rbfs})")
    import hashlib, re
    want = re.search(r"sha256\s+([0-9a-f]{64})", open(rec).read())
    if not want:
        sys.exit(f"{rec} carries no 'sha256 <64 hex>' line")
    rbf = os.path.join(bdir, rbfs[0])
    got = hashlib.sha256(open(rbf, "rb").read()).hexdigest()
    if got != want.group(1):
        sys.exit(f"REFUSING: {rbf} sha256 {got[:12]}… != the record's {want.group(1)[:12]}… — "
                 "a timing-failing seed emits an indistinguishable .rbf; fix the resource, not the release")
    shutil.copy(rbf, os.path.join(dest, rbfs[0]))
    shutil.copy(rec, os.path.join(dest, "BITSTREAM.txt"))
    print(f"  bitstream {rbfs[0]} from {bdir}: sha256 verified {got[:12]}…")


def mister_side(dest, src, name, bdir):
    if not src:
        sys.exit("mister: --mister-src DIR (holding the .mra files) is required for the mister platform")
    # WHAT SHIPS IS DECLARED BY SETNAME, NOT BY DIRECTORY LAYOUT (14z-126b).
    # jtframe files clones under _alternatives/<parent> and only setnames in
    # the core's parse.main_setnames land at the top level, so a listdir() of
    # the output dir silently depended on that layout: when cps2w made the
    # WIDE set main, the STOCK CONTROL leg moved into _alternatives and a
    # non-recursive scan would have dropped it from every release -- against
    # the ruling that it ships in each one (maintainer, 2026-08-29). Selecting
    # on the MRA's own <setname> is layout-independent and fails LOUDLY if one
    # goes missing, which a glob never would.
    SHIP = {"vsavjw": "the WIDE roster set",
            "vsavj":  "the [STOCK CONTROL] reference leg"}
    found, copied = {}, []
    for root, _dirs, files in os.walk(src):
        for f in sorted(files):
            if not f.endswith(".mra"):
                continue
            path = os.path.join(root, f)
            with open(path, encoding="utf-8", errors="replace") as fh:
                m = re.search(r"<setname>([^<]+)</setname>", fh.read())
            if not m or m.group(1) not in SHIP:
                continue
            if m.group(1) in found:
                sys.exit(f"mister: two MRAs claim setname {m.group(1)}: "
                         f"{found[m.group(1)]} and {path}")
            found[m.group(1)] = path
            shutil.copy(path, os.path.join(dest, f))
            copied.append(f)
    missing = [f"{k} ({v})" for k, v in SHIP.items() if k not in found]
    if missing:
        sys.exit(f"--mister-src {src} is missing: " + ", ".join(missing))
    bitstream_side(dest, bdir)
    text = f"""# {name} — MiSTer side

This directory is self-sufficient for MiSTer: the romset patch set
(`patches/`, `manifest.json`, `apply_release.py`, `README.md`), the `.mra`
files, the bitstream `jtcps2w.rbf` and its record `BITSTREAM.txt` (seed, slack,
sha256 — verified against the file when this directory was packaged).

## On the SD card
    _Arcade/<the .mra files here>
    _Arcade/cores/jtcps2w.rbf        <- in this directory (verify the sha256 in BITSTREAM.txt after copying)
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
    ap.add_argument("--mister-src", default="", help="dir holding the .mra files (the field bundle's _Arcade/, or mister_mra.sh --no-rom output)")
    ap.add_argument("--bitstream", default="", help="bitstream dir (an .rbf + BITSTREAM.txt); default: release/bitstreams/<CURRENT>")
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
            mister_side(dest, a.mister_src, a.name, resolve_bitstream(a.bitstream))
        n = sum(len(f) for _, _, f in os.walk(dest))
        print(f"  {p}: {n} files -> {dest}")
    print(f"packaged {a.name} for {', '.join(plats)} -> {root}")


if __name__ == "__main__":
    main()
