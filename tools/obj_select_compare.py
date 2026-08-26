#!/usr/bin/env python3
"""Compare SELECT-SCREEN OBJ lists between the jtcps2w core and MAME.

WHY THE SELECT SCREEN IS THE STRONGER LEG. At a match anchor most of the OBJ
list is the CPU opponent's sprites, and that opponent is a SOUND-STATE-FED
LOTTERY (docs/game/atlas/ram.md:99) which genuinely differs between the two
implementations — so only the PROMOTED (group-C) subset can be asserted. At
the select screen NO OPPONENT HAS BEEN DRAWN YET, so that confound is absent
and the WHOLE list becomes comparable. The screen also carries content the
match anchor never shows: the wheel medallions and the authored version mark.

WHAT IT REPORTS, and the distinction matters:
  FRAMES       core frames examined
  DISTINCT     distinct core lists across the window. If this is 1 the screen
               is static and any agreement is CHEAP — the caller must fail on
               that rather than celebrate it.
  WHOLE        core frames whose ENTIRE list has an exact MAME twin
  PROMOTED     core frames whose PROMOTED subset has an exact MAME twin
  VERSIONMARK  the authored version string (palette row 0x19) and whether it
               matches

The frame correspondence is SEARCHED, never assumed: a core frame counts as
matched if ANY MAME frame in the window holds the same list. CPS-2 ORAM is
double-buffered with a runtime page select, so both pages are walked and
either may supply the match.

Usage: obj_select_compare.py <sim-wram-dir> <mame-obj-log>
"""
import struct, re, glob, os, sys


def walk(buf, base):
    out = []
    for i in range(0x400):
        off = base + i * 8
        if off + 8 > len(buf):
            break
        x, y, c, a = struct.unpack_from(">HHHH", buf, off)
        if y & 0x8000 or a >= 0xFF00:
            break
        out.append((x, y, c, a))
    return out


def promoted(L):
    return [e for e in L if e[1] & 0x1000]


def main():
    simdir, mlog = sys.argv[1], sys.argv[2]

    core = {}
    for p in sorted(glob.glob(os.path.join(simdir, "dump_*_700000.bin"))):
        f = int(os.path.basename(p).split("_")[1])
        b = open(p, "rb").read()
        core[f] = (walk(b, 0x0000), walk(b, 0x2000))
    if not core:
        print("REFUSING: no dump_*_700000.bin in %s" % simdir, file=sys.stderr)
        return 2

    mame = {}
    for line in open(mlog):
        m = re.match(r"F(\d+) B0 E(\d+) x=(\w+) y=(\w+) code=(\w+) attr=(\w+)", line)
        if m:
            f, i, x, y, c, a = m.groups()
            mame.setdefault(int(f), []).append(
                (int(x, 16), int(y, 16), int(c, 16), int(a, 16)))
    if not mame:
        print("REFUSING: no B0 records parsed from %s" % mlog, file=sys.stderr)
        return 2

    whole_set = set(tuple(v) for v in mame.values())
    prom_set = set(tuple(promoted(v)) for v in mame.values())

    distinct_core = len(set(tuple(v[0]) for v in core.values()))
    n = len(core)
    wh = sum(1 for v in core.values() if any(tuple(pg) in whole_set for pg in v))
    pr = sum(1 for v in core.values() if any(tuple(promoted(pg)) in prom_set for pg in v))

    print("FRAMES %d" % n)
    print("DISTINCT %d core / %d mame" % (distinct_core,
                                          len(set(tuple(v) for v in mame.values()))))
    print("WHOLE %d" % wh)
    print("PROMOTED %d" % pr)

    # the authored version string lives on palette row 0x19
    f0 = sorted(core)[0]
    cv = [e for e in core[f0][0] if (e[3] & 0x1F) == 0x19]
    hit = any([e for e in v if (e[3] & 0x1F) == 0x19] == cv for v in mame.values())
    print("VERSIONMARK %d %s" % (len(cv), "MATCH" if (hit and cv) else "NO"))
    for e in cv:
        print("   mark x=%04x y=%04x code=%04x attr=%04x" % e)
    return 0


if __name__ == "__main__":
    sys.exit(main())
