#!/usr/bin/env python3
"""artifact_manifest.py — a per-member digest of an entire packed romset.

WHY IT EXISTS (14z-90, GitHub issue #8). tools/build_fingerprint.py --sha-only
is the reproducibility gate's assertion, and it hashes only the program members
matching cps2_decrypt._PRG_RE, from ONE resolved zip. Measured on build/don_m5:
12 of 21 members in vsavjw.zip, 6.00 MB of the 74.50 MB the set actually ships
= 8.1%. Uncovered: the tenant gfx members vsw.31m/33m/35m/37m (measured
tenant-SPECIFIC — Donovan, Huitzil and Pyron all differ), the WIDE overlay
members vsw.21m/22m, the authored QSound songs vsw.z01/z02, vsavj.key, and the
whole of the second packed zip vsav.zip, whose group-B members are patched in
every build. So "PASS: all four frozen references rebuild bit-exact" was a
claim about 8% of the artifact.

WHY NOT `build_fingerprint.py --full`. It is rompath-DEPENDENT, and that is
disqualifying for a frozen constant. Measured:

    --full "build/don_m5/rompath"           -> fee73055...  2 zips,  74.50 MB
    --full "build/don_m5/rompath;$ROMDIR"   -> 68caa5e3...  3 zips, 104.00 MB

The gate runs with the $ROMDIR chain appended, so a frozen --full digest would
bake 37 MB of the pristine reference set into the constant and change whenever
the chain changed. This tool enumerates `<dir>/*.zip` ONLY.

It is timestamp-free by construction: it hashes member NAMES and CONTENTS over
a sorted namelist, never zip mtimes. (A naive `shasum <zip>` would not be —
build_wide_romset.py and build_qs_songs.py write wall-clock timestamps, which
is GitHub issue #45.)

Usage:
  artifact_manifest.py <rompath-dir> [--verbose]
      prints one SHA-1 over the whole manifest, plus the member count
  artifact_manifest.py <rompath-dir> --list
      prints `<zip>/<member> <sha1>` per line, sorted — for diffing two builds

Exit 1 (never 0) if the directory holds no zip, so a missing artifact can
never read as agreement.
"""
import argparse
import hashlib
import sys
import zipfile
from pathlib import Path


def manifest_lines(rompath):
    d = Path(rompath)
    zips = sorted(p for p in d.glob("*.zip"))
    if not zips:
        sys.exit(f"artifact_manifest: no .zip under {d} — nothing to digest")
    out = []
    for z in zips:
        with zipfile.ZipFile(z) as zf:
            for name in sorted(zf.namelist()):
                h = hashlib.sha1(zf.read(name)).hexdigest()
                out.append(f"{z.name}/{name} {h}")
    return out


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("rompath", help="a build's rompath dir (NOT a ';' chain)")
    ap.add_argument("--list", action="store_true",
                    help="print every member digest instead of the summary")
    args = ap.parse_args()

    if ";" in args.rompath:
        sys.exit("artifact_manifest: pass ONE directory, not a rompath chain — "
                 "chaining $ROMDIR would fold the pristine reference set into "
                 "the digest (see the module docstring)")

    lines = manifest_lines(args.rompath)
    if args.list:
        print("\n".join(lines))
        return 0
    digest = hashlib.sha1("\n".join(lines).encode()).hexdigest()
    print(f"{digest} {len(lines)} members")
    return 0


if __name__ == "__main__":
    sys.exit(main())
