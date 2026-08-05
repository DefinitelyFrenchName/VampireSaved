#!/usr/bin/env python3
"""audit_romset_identity.py — catch members that SHADOW a patched member.

The 14z-60z bug in one sentence: both emulators resolve a ROM entry by
HASH before falling back to its NAME, so if any file in the set carries the
PRISTINE bytes of a member this build patched, the loader may quietly load
that file instead — the patch silently reverts, with no error and no
0xFF-fill tell.

That is exactly what the CPS-2 WIDE romset did. Its group C members
(`vsw.31m/33m/35m/37m`) were byte copies of the stock group B members
(`vm3.14m/16m/18m/20m`, the B4 canary shape), so they carried group B's
CRCs. The build patched group B to hold Donovan's tiles; the loader matched
group B's declared CRC against the canary copies and loaded PRISTINE tiles.
Donovan rendered with vanilla art — right geometry, wrong pixels — while
every RAM gate stayed green.

The rule this audit enforces:

    For every member this build PATCHED, no OTHER member of the set may
    carry that member's pristine bytes.

Content-identical duplicates that shadow nothing (e.g. several zero-filled
placeholders) are fine and are reported, not failed: they cannot revert a
patch because no patched member has those bytes.

Usage:
    audit_romset_identity.py <rompath_dir> [--romdir DIR] [--quiet]

Exit 0 = clean, 1 = shadow found, 2 = usage/IO problem.
"""
import argparse
import hashlib
import os
import sys
import zipfile
from collections import defaultdict


def members(zip_dir):
    """name -> list of (zipname, size, crc, sha1). Follows symlinked zips."""
    out = defaultdict(list)
    if not os.path.isdir(zip_dir):
        raise SystemExit(f"not a directory: {zip_dir}")
    for zn in sorted(os.listdir(zip_dir)):
        if not zn.endswith(".zip"):
            continue
        path = os.path.join(zip_dir, zn)
        try:
            zf = zipfile.ZipFile(path)
        except (OSError, zipfile.BadZipFile) as exc:
            print(f"  WARN: unreadable zip {zn}: {exc}")
            continue
        for info in zf.infolist():
            if info.is_dir():
                continue
            data = zf.read(info.filename)
            out[info.filename].append(
                (zn, info.file_size, info.CRC, hashlib.sha1(data).hexdigest()))
    return out


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("rompath", help="the build's rompath dir (its zips front $ROMDIR)")
    ap.add_argument("--romdir", default=os.environ.get("ROMDIR"),
                    help="reference sets, for the pristine comparison (default $ROMDIR)")
    ap.add_argument("--quiet", action="store_true")
    a = ap.parse_args()
    if not a.romdir:
        raise SystemExit("set ROMDIR or pass --romdir")

    build = members(a.rompath)
    ref = members(a.romdir)

    # A build member is PATCHED when a member of the same name exists in the
    # reference sets and its bytes differ.
    patched = {}       # name -> pristine (size, crc, sha1)
    for name, entries in sorted(build.items()):
        if name not in ref:
            continue
        b_size, b_crc, b_sha = entries[0][1], entries[0][2], entries[0][3]
        r_size, r_crc, r_sha = ref[name][0][1], ref[name][0][2], ref[name][0][3]
        if (b_size, b_sha) != (r_size, r_sha):
            patched[name] = (r_size, r_crc, r_sha)

    # Any OTHER member carrying those pristine bytes can shadow the patch.
    shadows = []
    for name, (p_size, p_crc, p_sha) in sorted(patched.items()):
        for other, entries in sorted(build.items()):
            if other == name:
                continue
            for zn, size, crc, sha in entries:
                if size == p_size and (crc == p_crc or sha == p_sha):
                    shadows.append((name, other, zn, p_crc, sha == p_sha))

    # Content-identical duplicates that shadow nothing — reported only.
    by_bytes = defaultdict(list)
    for name, entries in build.items():
        for zn, size, crc, sha in entries:
            by_bytes[(size, sha)].append(f"{zn}:{name}")
    benign = [v for v in by_bytes.values() if len(set(v)) > 1]

    if not a.quiet:
        print(f"  rompath  {a.rompath}")
        print(f"  romdir   {a.romdir}")
        print(f"  members  {sum(len(v) for v in build.values())} in "
              f"{len({e[0] for v in build.values() for e in v})} zips")
        print(f"  patched  {len(patched)}"
              + (": " + ", ".join(sorted(patched)) if patched else ""))
        for group in benign:
            print(f"  note: byte-identical members (harmless — shadow nothing): "
                  f"{', '.join(sorted(set(group)))}")

    if shadows:
        print()
        print("FAIL: a member SHADOWS a patched member — the loader matches by")
        print("      hash before name, so the patch can silently revert:")
        for name, other, zn, crc, exact in shadows:
            print(f"  {name}: patched, but {zn}:{other} carries its pristine bytes "
                  f"(crc {crc:08x}{'' if exact else ', crc-only match'})")
        print()
        print("  Fix: never ship a byte copy of a stock member under a different")
        print("  name in the same set (that is the B4 canary shape — canary")
        print("  romsets are built separately and never merged into a build).")
        return 1

    if not a.quiet:
        print("PASS: no member shadows a patched member")
    return 0


if __name__ == "__main__":
    sys.exit(main())
