#!/usr/bin/env python3
"""audit_z80_space.py — Z80 sound-driver ROM free-space census (WIDE A4).

The QSound sample region can be grown by descriptor alone (rom_mask =
nCpsQSamLen-1), but that is pointless if the Z80 driver has no room for
the bank/start/end table rows the new samples need. This is the only ROM
region the project had never measured.

Prints the blank-fill inventory and the largest contiguous runs, then a
DECISION line. Takes "path/to/set.zip:prefix" so it works on any of the
three reference sets; prints the SHA-1 of what it read (project rule).
"""
import hashlib
import sys
import zipfile

MIN_RUN = 256


def scan(path, prefix):
    z = zipfile.ZipFile(path)
    parts = []
    for member in (f"{prefix}.01", f"{prefix}.02"):
        data = z.read(member)
        print(f"  read {member} sha1 {hashlib.sha1(data).hexdigest()} "
              f"({len(data)} B)")
        parts.append(data)
    return b"".join(parts)


def runs(img):
    out, start, fill = [], None, None
    for i, b in enumerate(img):
        if b in (0x00, 0xFF) and (fill is None or b == fill):
            if start is None:
                start, fill = i, b
        else:
            if start is not None and i - start >= MIN_RUN:
                out.append((start, i, fill))
            start = i if b in (0x00, 0xFF) else None
            fill = b if b in (0x00, 0xFF) else None
    if start is not None and len(img) - start >= MIN_RUN:
        out.append((start, len(img), fill))
    return out


def main():
    if len(sys.argv) != 2 or ":" not in sys.argv[1]:
        sys.exit("usage: audit_z80_space.py <set.zip>:<prefix>   (e.g. vsav.zip:vm3)")
    path, prefix = sys.argv[1].rsplit(":", 1)
    img = scan(path, prefix)
    free = runs(img)
    total = sum(e - s for s, e, _ in free)
    print(f"  {len(img)//1024} KB image, {len(free)} blank runs >= {MIN_RUN} B, "
          f"{total} B free ({total*100//len(img)}%)")
    for s, e, fill in sorted(free, key=lambda r: -(r[1] - r[0]))[:6]:
        print(f"    {s:05x}-{e:05x}  {e-s:6d} B  fill {fill:02x}")
    biggest = max((e - s for s, e, _ in free), default=0)
    if biggest >= 4096:
        print(f"  DECISION A4: Z80 is NOT a blocker — largest free run {biggest} B "
              f"({biggest//1024} KB) is ample for extra sample-table rows")
    else:
        print(f"  DECISION A4: Z80 IS TIGHT — largest free run only {biggest} B; "
              f"sample-table growth needs a relocation plan")


if __name__ == "__main__":
    main()
