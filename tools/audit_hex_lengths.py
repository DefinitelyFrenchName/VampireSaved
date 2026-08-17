#!/usr/bin/env python3
"""audit_hex_lengths.py — every manifest byte-edit must replace as many bytes
as it verifies (14z-94, GitHub #20).

WHY. Manifests are the sanctioned way to express a byte edit (CLAUDE.md rule
5) and a hex-count typo is the most likely manifest error there is. Two
generator sites write `new` over bytes verified as `old`:

    [[port_patch]]        old_hex / new_hex
    [[data_port]] fixes   "off:old:new,..."

Both write a span sized by `len(new)` after checking a span sized by
`len(old)`. When those differ the write is PARTLY UNVERIFIED — it either
clobbers bytes past the checked window or leaves a tail of the old ones — and
the emitted note/atlas line records the wrong span, so the provenance atlas is
wrong too (rule 4).

**A CORRECTION TO THE ISSUE AS FILED.** #20 says the mismatch "CHANGES THE
BYTEARRAY'S LENGTH" and overruns into the next allocation. It does not: the
slice is `blob[off:off + len(new)]`, so assigning `len(new)` bytes is
length-preserving. The defect is the unverified write and the wrong
provenance, not a resize. Recorded here so nobody re-derives the resize story
from the issue text.

The generator now hard-fails on a mismatch. This tool is the STATIC half —
it answers "is any tracked manifest carrying one today?" without a build, so
the answer is available in CI and in review rather than only at generate time.

Usage: audit_hex_lengths.py [manifest.toml ...]   (default: build/manifest/*.toml)
Exit 0 if every row is balanced; 1 naming each offender.
"""
import glob
import re
import sys

# The manifests are read as TEXT on purpose. _minitoml/tomllib disagree by
# host (GitHub #42), and this check must give the same answer everywhere; the
# two keys are simple quoted scalars, so a line scan is both sufficient and
# parser-independent.
PORT_OLD = re.compile(r'^\s*old_hex\s*=\s*"([0-9a-fA-F]*)"')
PORT_NEW = re.compile(r'^\s*new_hex\s*=\s*"([0-9a-fA-F]*)"')
FIXES = re.compile(r'^\s*fixes\s*=\s*"([^"]*)"')
ROW = re.compile(r'^\s*\[\[')


def audit(path):
    """Return a list of (line, message) for unbalanced edits in one manifest."""
    bad = []
    old = old_line = None
    for n, line in enumerate(open(path), 1):
        if ROW.match(line):
            old = old_line = None          # a new row: forget the previous pair
        m = PORT_OLD.match(line)
        if m:
            old, old_line = m.group(1), n
            continue
        m = PORT_NEW.match(line)
        if m and old is not None:
            if len(m.group(1)) != len(old):
                bad.append((n, f"port_patch new_hex {len(m.group(1))//2} bytes "
                               f"vs old_hex {len(old)//2} (line {old_line})"))
            old = None
            continue
        m = FIXES.match(line)
        if m:
            for fx in m.group(1).split(","):
                fx = fx.strip()
                if not fx:
                    continue
                parts = fx.split(":")
                if len(parts) != 3:
                    bad.append((n, f"fixes entry {fx!r} is not off:old:new"))
                    continue
                _, o, nw = parts
                if len(o) != len(nw):
                    bad.append((n, f"fixes {fx!r}: new {len(nw)//2} bytes vs "
                                   f"old {len(o)//2}"))
    return bad


def main():
    paths = sys.argv[1:] or sorted(glob.glob("build/manifest/*.toml"))
    if not paths:
        sys.exit("no manifests given and build/manifest/*.toml matched nothing")
    rc = 0
    total = 0
    for p in paths:
        bad = audit(p)
        total += 1
        for n, msg in bad:
            print(f"FAIL {p}:{n}: {msg}")
            rc = 1
    print(f"{'FAIL' if rc else 'ok'}: scanned {total} manifest(s) for "
          f"unbalanced byte edits")
    sys.exit(rc)


if __name__ == "__main__":
    main()
