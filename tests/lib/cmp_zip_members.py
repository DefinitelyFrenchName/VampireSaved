#!/usr/bin/env python3
"""cmp_zip_members.py — are two zips the same SET of members with the same
CONTENT? (14z-95, GitHub #27)

Deliberately compares MEMBERS, not the container: zip archives carry
timestamps and ordering that differ between two runs of the same producer, so
a file-level `cmp` reports a difference that no loader can see. Both emulators
resolve a ROM entry by member, which is the level a claim about "the same
romset" has to be made at.

Usage: cmp_zip_members.py <a.zip> <b.zip>   ->  prints a summary, exit 0/1
"""
import hashlib
import sys
import zipfile


def main():
    if len(sys.argv) != 3:
        sys.exit("usage: cmp_zip_members.py <a.zip> <b.zip>")
    a, b = (zipfile.ZipFile(p) for p in sys.argv[1:3])
    na, nb = set(a.namelist()), set(b.namelist())
    if na != nb:
        print(f"MEMBER INVENTORY DIFFERS: only a={sorted(na - nb)} "
              f"only b={sorted(nb - na)}")
        return 1
    diff = [n for n in sorted(na)
            if hashlib.sha1(a.read(n)).digest()
            != hashlib.sha1(b.read(n)).digest()]
    if diff:
        print(f"MEMBERS DIFFER: {diff}")
        return 1
    print(f"IDENTICAL: {len(na)} members, same names and same bytes")
    return 0


if __name__ == "__main__":
    sys.exit(main())
