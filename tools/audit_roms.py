#!/usr/bin/env python3
"""audit_roms.py — inventory and verify the reference romsets in ROMDIR.

Usage:
    python3 tools/audit_roms.py <romdir>            # verify against docs/checksums.txt
    python3 tools/audit_roms.py <romdir> --freeze   # (re)write docs/checksums.txt

Walks every .zip in <romdir>, hashes every member (size, CRC32, SHA-1), and
either compares the inventory against the frozen manifest or freezes it.
Membership is compared both ways: a missing OR extra file is a failure.

The manifest is per-member, not per-zip, so repackaging (zip tool, order,
compression level) never matters — only content does (STATE.md decision,
2026-07-25).

Hard expectations (from the resolved ROM audit, STATE.md 2026-07-25):
  - vhunt2.key must be present in BOTH vhunt2.zip and vhunt2r1.zip, CRC 61306b20
  - qsound_hle.zip must contain dl-1425.bin, CRC d6cf5ef5
Exit status: 0 clean, 1 any failure.
"""

import argparse
import hashlib
import sys
import zipfile
import zlib
from pathlib import Path

MANIFEST = Path(__file__).resolve().parent.parent / "docs" / "checksums.txt"

# (zip name, member name, expected CRC32) — packaging fixes that must hold.
HARD_EXPECTATIONS = [
    ("vhunt2.zip", "vhunt2.key", 0x61306B20),
    ("vhunt2r1.zip", "vhunt2.key", 0x61306B20),
    ("qsound_hle.zip", "dl-1425.bin", 0xD6CF5EF5),
]

# Sets the project requires (CLAUDE.md §3). vsav.zip is the parent of vsavj
# (holds shared gfx/qsound), qsound_hle is the shared device set.
REQUIRED_ZIPS = ["qsound_hle.zip", "vhunt2.zip", "vhunt2r1.zip", "vsav.zip", "vsavj.zip"]
EXPECTED_MISSING = ["vsav2.zip"]  # flagged in STATE.md; needed from M1 on


def inventory(romdir: Path):
    """{ 'zip/member': (size, crc32, sha1hex) } for every member of every zip."""
    inv = {}
    for zpath in sorted(romdir.glob("*.zip")):
        with zipfile.ZipFile(zpath) as zf:
            for info in zf.infolist():
                if info.is_dir():
                    continue
                data = zf.read(info.filename)
                inv[f"{zpath.name}/{info.filename}"] = (
                    len(data),
                    zlib.crc32(data) & 0xFFFFFFFF,
                    hashlib.sha1(data).hexdigest(),
                )
    return inv


def render(inv):
    lines = [
        "# Frozen reference-set manifest — per-member, packaging-independent.",
        "# Regenerate ONLY by decision recorded in STATE.md:",
        "#   python3 tools/audit_roms.py $ROMDIR --freeze",
        "# path  size  crc32  sha1",
    ]
    for path, (size, crc, sha) in sorted(inv.items()):
        lines.append(f"{path}  {size}  {crc:08x}  {sha}")
    return "\n".join(lines) + "\n"


def parse_manifest(text):
    inv = {}
    for line in text.splitlines():
        if not line or line.startswith("#"):
            continue
        path, size, crc, sha = line.rsplit(None, 3)
        inv[path] = (int(size), int(crc, 16), sha)
    return inv


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("romdir", type=Path)
    ap.add_argument("--freeze", action="store_true", help="write docs/checksums.txt")
    args = ap.parse_args()

    ok = True
    inv = inventory(args.romdir)

    present = {p.split("/")[0] for p in inv}
    for z in REQUIRED_ZIPS:
        if z not in present:
            print(f"FAIL missing required set: {z}")
            ok = False
    for z in EXPECTED_MISSING:
        tag = "present (update audit_roms.py + STATE.md)" if z in present else "absent (known gap, see STATE.md)"
        print(f"note {z}: {tag}")

    for zname, member, crc in HARD_EXPECTATIONS:
        got = inv.get(f"{zname}/{member}")
        if got is None:
            print(f"FAIL {zname}/{member}: absent")
            ok = False
        elif got[1] != crc:
            print(f"FAIL {zname}/{member}: crc {got[1]:08x} != expected {crc:08x}")
            ok = False
        else:
            print(f"ok   {zname}/{member} crc {crc:08x}")

    if args.freeze:
        if not ok:
            print("refusing to freeze a failing inventory")
            return 1
        MANIFEST.write_text(render(inv))
        print(f"froze {len(inv)} entries -> {MANIFEST}")
    else:
        if not MANIFEST.exists():
            print(f"FAIL no manifest at {MANIFEST}; run with --freeze once audited")
            return 1
        frozen = parse_manifest(MANIFEST.read_text())
        for path in sorted(frozen.keys() | inv.keys()):
            if path not in inv:
                print(f"FAIL missing vs manifest: {path}")
                ok = False
            elif path not in frozen:
                print(f"FAIL not in manifest (new file): {path}")
                ok = False
            elif frozen[path] != inv[path]:
                print(f"FAIL checksum mismatch: {path}")
                print(f"     manifest: {frozen[path]}")
                print(f"     on disk : {inv[path]}")
                ok = False
        if ok:
            print(f"verified {len(inv)} members against {MANIFEST.name}: all match")

    print(f"\nread {len(inv)} members from {args.romdir}")
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
