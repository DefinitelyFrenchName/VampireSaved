#!/usr/bin/env python3
"""check_df_style.py — verdict logic for the Dark Force STYLE A/B (14z-69).

Compares a native-vsav2 leg against a tenant-build leg over the replay-85
windows and decides whether the tenant's Dark Force PRESENTATION differs
from native. Split out of tests/test_hui_df_style.sh so the verdicts can be
ground-truthed against synthetic corruptions (CLAUDE.md §4: a test's
classification code is validated before it is trusted).

READ THIS FIRST — DARK FORCE MUST ACTUALLY BE ACTIVE. The first version of
this rig compared two matches in which DF never activated, and reported the
symptom as "does not reproduce". DF consumes one banked stock; with an
empty meter the P+K pair is DOWNGRADED to a single button and play
continues normally (that downgrade is seq 0x0A — it is NOT Dark Force).
Section 0 therefore refuses to judge anything unless BOTH legs show:
    +0x1F4 == 0x08      the shared DF-active flag (0 before, 8 during)
    +0x109 decremented  a stock was actually spent
and unless the control frame shows DF *off*. A rig that cannot enter the
mode fails here rather than passing vacuously.

THE FLAG WAS CHOSEN BY MEASUREMENT, NOT BY INSPECTION. A first attempt
used a fighter-block byte that looked right and turned out to be set by
JUMPING (+0x1F4). $FF802E was picked by dumping all of work RAM at five
phases on BOTH games and keeping only bytes that are off before DF, off
during a plain jump, on for the whole mode, and off again at expiry, with
identical values on both games — 18 bytes qualify and this is one of
them. It is a match-level flag (DF changes the background globally), so
it is paired with the per-player stock decrement to attribute the mode to
P1.

MEASURED SHAPE OF THE DEFECT (hui11 vs vsav2, 14z-69) — the tenant inherits
the HOST character's DF style, in two visible parts:
  * RECOLOUR: sprite palette row 0x0A ($90C140) holds a purple ramp for the
    whole mode (ours) where native holds his gold, slightly brightened.
  * AFTERIMAGES: his own art is drawn ~4x over (29-32 pal-0x0A draws vs
    native's 7-8) as trailing copies.
Native additionally does NOT enter the transform seq 0x18 and spends a
different number of stocks — i.e. native Huitzil's DF is a different TYPE,
not the same type styled differently.

--expect differs (default) freezes that shape: the gate is green while the
defect is open and goes red if it CHANGES, in either direction. Flip to
--expect matches when the fix lands; that asserts native-equality instead.

Usage: check_df_style.py <work> --anchors F.. --pal F.. --obj F..
                                [--control F] [--expect differs|matches]
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
OFF_STOCK = 0x109    # banked stock count
OFF_ID = 0x382
# match-level DF-active flag $FF802E (dumped as ff8020-ff805f, offset 0x0E):
# 0 before, 1 for the whole mode, 0 at expiry, identical on both games.
DF_DUMP, DF_OFF, DF_ON = "ff8020", 0x0E, 0x01
# the ratio at which "he is drawn several times over" is unambiguous;
# measured 3.6-4.6x, and 1.0x before DF on both legs.
GHOST_RATIO = 2.5


def blk(work, leg, frame):
    with open(os.path.join(work, leg, "dump_%d_ff8400.bin" % frame), "rb") as fh:
        return fh.read()


def df_on(work, leg, frame):
    """the match-level Dark Force flag at this frame"""
    p = os.path.join(work, leg, "dump_%d_%s.bin" % (frame, DF_DUMP))
    with open(p, "rb") as fh:
        return fh.read()[DF_OFF] == DF_ON


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
    ap.add_argument("--control", type=int, required=True,
                    help="a frame BEFORE Dark Force (the in-replay control)")
    ap.add_argument("--expect", choices=("differs", "matches"), default="differs")
    ap.add_argument("--quiet", action="store_true")
    a = ap.parse_args()
    anchors = [int(x) for x in a.anchors.split()]
    palfr = [int(x) for x in a.pal.split()]
    objfr = [int(x) for x in a.obj.split()]
    say = (lambda *x: None) if a.quiet else print

    fail = []

    # ── 0. the rig really is in Dark Force (never skip this) ───────────
    say("== 0. rig validity: right character, DF ACTUALLY active")
    df_anchors = []
    for leg in ("native", "ours"):
        ids = {blk(a.work, leg, f)[OFF_ID] for f in anchors}
        if ids != {0x10}:
            fail.append("%s: char id is not 0x10 at every anchor (%s)"
                        % (leg, sorted(hex(i) for i in ids)))
        ctrl = blk(a.work, leg, a.control)
        if df_on(a.work, leg, a.control):
            fail.append("%s: DF already active at the control frame f%d "
                        "(the control is not a control)" % (leg, a.control))
        on = [f for f in anchors if df_on(a.work, leg, f)]
        if not on:
            fail.append("%s: Dark Force NEVER ACTIVATED ($FF802E never 1). "
                        "DF costs a banked stock — poke +0x109 ($FF8509) or the "
                        "P+K pair is downgraded to a single button and nothing "
                        "measured here means anything." % leg)
        spent = ctrl[OFF_STOCK] - min(blk(a.work, leg, f)[OFF_STOCK] for f in anchors)
        if spent < 1:
            fail.append("%s: no stock was spent (%d -> %d): DF did not engage"
                        % (leg, ctrl[OFF_STOCK],
                           min(blk(a.work, leg, f)[OFF_STOCK] for f in anchors)))
        say("   %-6s id=0x10, DF on %d/%d anchors, %d stock spent, seq in DF %s"
            % (leg, len(on), len(anchors), spent,
               sorted({"%02x" % blk(a.work, leg, f)[OFF_SEQ] for f in on})))
        df_anchors.append(set(on))
    if fail:                       # nothing below is meaningful without this
        print("FAIL:")
        for x in fail:
            print("  - " + x)
        return 1
    shared_df = sorted(df_anchors[0] & df_anchors[1])
    if not shared_df:
        print("FAIL:\n  - the legs are never in Dark Force at the same anchor")
        return 1

    # ── 1. palette row 0x0A ────────────────────────────────────────────
    say("== 1. sprite palette row 0x0A vs native (%d frames)" % len(palfr))
    diff = [f for f in palfr if pal(a.work, "native", f) != pal(a.work, "ours", f)]
    if diff:
        say("   differs on %d/%d frames, e.g. f%d:" % (len(diff), len(palfr), diff[0]))
        say("     native %s" % pal(a.work, "native", diff[0]).hex())
        say("     ours   %s" % pal(a.work, "ours", diff[0]).hex())
    else:
        say("   byte-identical on all %d frames" % len(palfr))

    # ── 2. how many times his own art is drawn ─────────────────────────
    say("== 2. fighter pal-0x0A draws, ours vs native")
    nat, our = objs(a.work, "native"), objs(a.work, "ours")
    ghosted, compared = [], []
    for f in objfr:
        n = sum(nat.get(f, collections.Counter()).values())
        o = sum(our.get(f, collections.Counter()).values())
        if not n:
            continue
        ratio = o / float(n)
        in_df = df_on(a.work, "native", f) and df_on(a.work, "ours", f)
        compared.append((f, n, o, ratio, in_df))
        if in_df and ratio >= GHOST_RATIO:
            ghosted.append(f)
        say("   f%-5d native=%2d ours=%2d  x%.1f%s"
            % (f, n, o, ratio, "   <-- DF" if in_df else ""))

    # ── verdict ────────────────────────────────────────────────────────
    if a.expect == "matches":
        if diff:
            fail.append("palette row 0x0A differs from native on %d/%d frames"
                        % (len(diff), len(palfr)))
        for f in objfr:
            want = our.get(f, collections.Counter())
            if not want:
                continue
            hit = next((g for g in (f, f - 1, f + 1, f - 2, f + 2)
                        if g in nat and nat[g] == want), None)
            if hit is None:
                fail.append("f%d: sprite set has no native match within +/-2 "
                            "(%d draws vs native's %d)"
                            % (f, sum(want.values()),
                               sum(nat.get(f, collections.Counter()).values())))
    else:   # differs — freeze the measured shape of the open defect
        if not diff:
            fail.append("expected the DF RECOLOUR (palette row 0x0A differing "
                        "from native) and found none — if this is the fix, "
                        "rerun with --expect matches")
        if not ghosted:
            fail.append("expected the AFTERIMAGES (>=%.1fx native's draws of "
                        "his own art while in DF) and found none — if this is "
                        "the fix, rerun with --expect matches" % GHOST_RATIO)
        pre = [c for c in compared if not c[4]]
        if pre and max(c[3] for c in pre) >= GHOST_RATIO:
            fail.append("the control frames are ALSO ghosted (x%.1f) — the "
                        "extra draws are not DF-specific and this rig no "
                        "longer isolates the symptom"
                        % max(c[3] for c in pre))

    if fail:
        print("FAIL:")
        for x in fail:
            print("  - " + x)
        return 1
    if a.expect == "matches":
        print("PASS: Dark Force presentation matches native vsav2")
    else:
        print("PASS: the open DF-style defect is present with its frozen shape "
              "(host recolour on %d/%d palette frames, %s ghosted while the "
              "control frames are clean)" % (len(diff), len(palfr),
                                             " ".join("f%d" % f for f in ghosted)))
    return 0


if __name__ == "__main__":
    sys.exit(main())
