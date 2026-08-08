#!/usr/bin/env python3
"""check_df_style.py — verdict logic for the Dark Force STYLE A/B (14z-69).

Compares a native-vsav2 leg against a tenant-build leg over the replay-85
windows and decides whether the tenant's Dark Force PRESENTATION differs
from native. Split out of tests/test_hui_df_style.sh so the verdicts can be
ground-truthed against synthetic corruptions (CLAUDE.md §4: a test's
classification code is validated before it is trusted — the SMS project
shipped a wrong conclusion from a verdict bug, not a game bug).

Input is a work directory holding one subdirectory per leg, each with the
dump files the MAME harness writes:
    <work>/<leg>/dump_<frame>_ff8400.bin    fighter block (0x400 bytes)
    <work>/<leg>/dump_<frame>_90c140.bin    sprite palette row 0x0A
    <work>/<leg>/obj.txt                    obj_records_dump.lua output

Checks, in order (all must hold):
  0. NOT VACUOUS — both legs really are Huitzil (+0x382 = 0x10), Dark Force
     really latches (+0x1b5/+0x1b9 clear on the control dash, set on every
     DF anchor), and the air dash really engages (seq 0x14) in each window.
  1. PALETTE — row 0x0A byte-identical to native at every sampled frame.
     The reported symptom is a per-frame recolour; it cannot survive this.
  2. SPRITE SET — the fighter's own pal-0x0A draws (code + size multiset)
     match native's within a +/-2 frame skew window. Afterimages are extra
     draws of his own art, so a trailing copy appears as a duplicated code.

Usage: check_df_style.py <work> --anchors F.. --pal F.. --obj F..
"""
import argparse
import collections
import os
import re
import sys

# The HUD mugshot cell is a DESIGNED difference (native 0x47A0 vs our HUD
# free-pool art 0xBE9A) and is not part of the fighter's own draws.
HUD_MUG = {0x47A0, 0xBE9A}

# fighter-block offsets (docs/atlas/ram.md + measured 14z-69)
OFF_SEQ = 0x006
OFF_ID = 0x382
OFF_DF_A = 0x1B5   # latch at DF activation, persist for the mode
OFF_DF_B = 0x1B9


def blk(work, leg, frame):
    with open(os.path.join(work, leg, "dump_%d_ff8400.bin" % frame), "rb") as fh:
        return fh.read()


def pal(work, leg, frame):
    with open(os.path.join(work, leg, "dump_%d_90c140.bin" % frame), "rb") as fh:
        return fh.read()


def objs(work, leg):
    """frame -> Counter of (code, size) for the fighter's pal-0x0A draws."""
    pat = re.compile(r"F(\d+) \S+ \S+ x=(\S+) y=(\S+) code=(\S+) attr=(\S+) "
                     r"pal=(\S+) sz=(\S+)")
    out = collections.defaultdict(collections.Counter)
    with open(os.path.join(work, leg, "obj.txt")) as fh:
        for line in fh:
            m = pat.match(line)
            if not m:
                continue
            code, palette = int(m.group(4), 16), int(m.group(6), 16)
            if palette != 0x0A or code == 0 or code in HUD_MUG:
                continue
            out[int(m.group(1))][(code, m.group(7))] += 1
    return out


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("work")
    ap.add_argument("--anchors", required=True, help="fighter-block frames")
    ap.add_argument("--pal", required=True, help="palette-sampled frames")
    ap.add_argument("--obj", required=True, help="obj-dumped frames")
    ap.add_argument("--control", type=int, default=3190,
                    help="the pre-DF control dash frame")
    ap.add_argument("--quiet", action="store_true")
    a = ap.parse_args()
    anchors = [int(x) for x in a.anchors.split()]
    palfr = [int(x) for x in a.pal.split()]
    objfr = [int(x) for x in a.obj.split()]
    df_anchors = [f for f in anchors if f > a.control + 10]
    say = (lambda *x: None) if a.quiet else print

    fail = []

    say("== 0. rig sanity (character / DF latched / air dash engaged)")
    for leg in ("native", "ours"):
        ids = {blk(a.work, leg, f)[OFF_ID] for f in anchors}
        if ids != {0x10}:
            fail.append("%s: char id is not 0x10 at every anchor (%s)"
                        % (leg, sorted(hex(i) for i in ids)))
        ctrl = blk(a.work, leg, a.control)
        if ctrl[OFF_DF_A] or ctrl[OFF_DF_B]:
            fail.append("%s: DF fields already set during the CONTROL dash "
                        "(the control is not a control)" % leg)
        for f in df_anchors:
            b = blk(a.work, leg, f)
            if not (b[OFF_DF_A] and b[OFF_DF_B]):
                fail.append("%s: DF not active at f%d (+1b5=%02x +1b9=%02x)"
                            % (leg, f, b[OFF_DF_A], b[OFF_DF_B]))
        dashed = [f for f in anchors if blk(a.work, leg, f)[OFF_SEQ] == 0x14]
        if not any(f <= a.control + 10 for f in dashed):
            fail.append("%s: air dash never engaged in the control window" % leg)
        if not any(f in dashed for f in df_anchors):
            fail.append("%s: air dash never engaged during Dark Force" % leg)
        say("   %-6s id=0x10, DF latched on %d anchors, dashes engaged"
            % (leg, len(df_anchors)))

    say("== 1. sprite palette row 0x0A vs native (%d frames)" % len(palfr))
    ndiff = [f for f in palfr if pal(a.work, "native", f) != pal(a.work, "ours", f)]
    if ndiff:
        for f in ndiff[:3]:
            say("   f%d native=%s ours=%s"
                % (f, pal(a.work, "native", f).hex(), pal(a.work, "ours", f).hex()))
        fail.append("palette row 0x0A differs from native on %d/%d frames "
                    "(a DF recolour looks exactly like this)"
                    % (len(ndiff), len(palfr)))
    else:
        say("   byte-identical on all %d frames" % len(palfr))

    say("== 2. fighter pal-0x0A sprite set vs native (skew window +/-2)")
    nat, our = objs(a.work, "native"), objs(a.work, "ours")
    for f in objfr:
        want = our.get(f, collections.Counter())
        hit = next((g for g in (f, f - 1, f + 1, f - 2, f + 2)
                    if g in nat and nat[g] == want), None)
        dup = sum(c - 1 for c in want.values() if c > 1)
        if hit is None:
            near = nat.get(f, collections.Counter())
            extra = [("%04x" % c, s) for (c, s) in sorted(want - near)]
            missing = [("%04x" % c, s) for (c, s) in sorted(near - want)]
            fail.append("f%d: sprite set has no native match within +/-2 "
                        "(ours-only %s, native-only %s, duplicated codes %d)"
                        % (f, extra[:6], missing[:6], dup))
        else:
            say("   f%d n=%2d dup=%d  == native f%d"
                % (f, sum(want.values()), dup, hit))

    if fail:
        print("FAIL:")
        for x in fail:
            print("  - " + x)
        return 1
    print("PASS: Dark Force presentation matches native vsav2 "
          "(palette frame-exact, no extra draws of his own art)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
