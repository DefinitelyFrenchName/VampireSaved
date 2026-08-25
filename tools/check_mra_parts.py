#!/usr/bin/env python3
"""Check that every CRC-identified <part> an MRA declares resolves from the
zips it names.

WHY THIS EXISTS: jtframe resolves zip members by CRC32 ALONE, and an
unresolved part is FILLED WITH 0xFF rather than refused. So a bundle can
look complete and silently ship a ROM with holes in it.

Usage: check_mra_parts.py <file.mra> <dir-holding-the-zips> [...more dirs]
Exit 0 only if every CRC-identified part resolves.
"""
import sys, zipfile, os, re
import xml.etree.ElementTree as ET


def crc_index(dirs):
    """crc32 (lowercase hex, no leading zeros stripped) -> [zipname/member]"""
    idx = {}
    for d in dirs:
        if not os.path.isdir(d):
            continue
        for fn in sorted(os.listdir(d)):
            if not fn.lower().endswith(".zip"):
                continue
            p = os.path.join(d, fn)
            try:
                with zipfile.ZipFile(p) as z:
                    for info in z.infolist():
                        if info.is_dir():
                            continue
                        key = "%08x" % (info.CRC & 0xFFFFFFFF)
                        idx.setdefault(key, []).append("%s/%s" % (fn, info.filename))
            except zipfile.BadZipFile:
                print("  WARN: not a zip: %s" % p)
    return idx


def main():
    if len(sys.argv) < 3:
        print(__doc__)
        return 2
    mra, dirs = sys.argv[1], sys.argv[2:]

    tree = ET.parse(mra)
    root = tree.getroot()

    zips = set()
    for el in root.iter():
        z = el.get("zip")
        if z:
            for name in z.split("|"):
                zips.add(name.strip())

    idx = crc_index(dirs)

    parts = [el for el in root.iter("part") if el.get("crc")]
    print("MRA        : %s" % os.path.basename(mra))
    print("names zips : %s" % ", ".join(sorted(zips)))
    print("CRC parts  : %d" % len(parts))

    missing = []
    for el in parts:
        crc = el.get("crc").lower().strip()
        crc = "%08x" % int(crc, 16)          # normalise width
        if crc not in idx:
            missing.append((crc, el.get("name") or "<unnamed>"))

    if missing:
        print("\nUNRESOLVED — these would be 0xFF-FILLED, not refused:")
        for crc, name in missing:
            print("  crc=%s  name=%s" % (crc, name))
        print("\nFAIL: %d of %d parts do not resolve" % (len(missing), len(parts)))
        return 1

    print("\nPASS: all %d CRC-identified parts resolve" % len(parts))
    return 0


if __name__ == "__main__":
    sys.exit(main())
