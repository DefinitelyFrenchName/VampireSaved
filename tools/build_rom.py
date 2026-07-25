#!/usr/bin/env python3
"""build_rom.py — assemble an output romset zip from a build manifest.

Usage:
    python3 tools/build_rom.py <romdir> <out.zip> [--manifest build/manifest/vsavj.toml]

Chainable (src, out) builder per CLAUDE.md build conventions: <romdir> may be
any directory holding the source zips the manifest references, so builders can
run against pristine references or a previous builder's output directory.

The output zip is deterministic: fixed member order (manifest order), fixed
timestamp, fixed compression — two runs from identical inputs are
byte-identical, and member SHA-1s are printed for the registry.

Today this implements the null patch only (straight member copies). Patch
application (assembled hooks, table injections) lands here in M2; the
manifest schema already carries per-file provenance for the atlas.
"""

import argparse
import hashlib
import sys
import zipfile
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from _minitoml import loads  # noqa: E402

# Fixed metadata so builds are byte-reproducible regardless of clock/platform.
ZIP_DATE = (1997, 5, 19, 0, 0, 0)  # vsavj revision date, cosmetic only


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("romdir", type=Path, help="directory holding source zips")
    ap.add_argument("out", type=Path, help="output romset zip")
    ap.add_argument("--manifest", type=Path,
                    default=Path(__file__).resolve().parent.parent / "build" / "manifest" / "vsavj.toml")
    args = ap.parse_args()

    manifest = loads(args.manifest.read_text())
    files = manifest.get("file", [])
    if not files:
        raise SystemExit(f"{args.manifest}: no [[file]] entries")

    sources = {}  # zip name -> open ZipFile
    args.out.parent.mkdir(parents=True, exist_ok=True)
    try:
        with zipfile.ZipFile(args.out, "w") as out:
            for entry in files:
                src_zip, _, member = entry["source"].partition("/")
                if src_zip not in sources:
                    path = args.romdir / src_zip
                    print(f"open {path}  sha1 {hashlib.sha1(path.read_bytes()).hexdigest()}")
                    sources[src_zip] = zipfile.ZipFile(path)
                data = sources[src_zip].read(member)
                info = zipfile.ZipInfo(entry["name"], date_time=ZIP_DATE)
                info.compress_type = zipfile.ZIP_DEFLATED
                out.writestr(info, data)
                print(f"  {entry['name']:<12} {len(data):>8}  sha1 {hashlib.sha1(data).hexdigest()}"
                      f"  [{entry.get('provenance', '?')}]")
    finally:
        for zf in sources.values():
            zf.close()

    print(f"wrote {args.out}  sha1 {hashlib.sha1(args.out.read_bytes()).hexdigest()}")


if __name__ == "__main__":
    main()
