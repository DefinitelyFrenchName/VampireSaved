#!/usr/bin/env python3
"""attr_placement_moves.py — IS EVERY ADDRESS A FREEZE MOVED IN A STATIC PIN THE PLACEMENT'S DOING?
(14z-185, the M21 freeze's tier reds; promoted from build/rc185/tierreds/attr_placement.py by the close
checklist's step 5.)

Usage:
  python3 tools/attr_placement_moves.py --old build/m3b_merged28 --new build/m3b_merged29 \
          --log build/rc185/tierreds/test_pointer_flow.log [--log ...] [--plant]

Each --log is a gate's output holding its printed diff: OLD lines ('<' or '-') and NEW lines ('>' or '+'),
paired in order. In each pair every hex address >= 0x400000 that differs is looked up:
  1. in OLD's placed regions (<old>/patch/placements.json: dst..dst+len): ok when NEW equals the SAME
     region's new dst plus the same offset;
  2. else in the merged build's MOVED ops (tools/attribute_patch_delta.py OLD NEW --moved, run here): ok
     when NEW equals that op's new address plus the same offset — this covers what placements.json does
     not (the site thunks' pool, the relocated walker copies);
  3. else (a pointer TARGET in an unplaced hole, test_pointer_flow's WIDE-HOLE class) against the nearest
     MOVED op starting at or below it within 0x1000: ok-HOLE when NEW keeps the same offset from that op's
     new start — a WEAKER attribution (offset preserved), printed as such.
A pair whose text differs in anything but those addresses is printed NON-ADDRESS (a count, a build row):
the reader attributes those. --plant moves one new address by +2, which must be reported UNATTRIBUTED
(the tool's control). Exit 1 on any UNATTRIBUTED or NON-ADDRESS line, or an UNPAIRED diff.
"""
import argparse, json, re, subprocess, sys, os
ap = argparse.ArgumentParser()
ap.add_argument("--old", required=True); ap.add_argument("--new", required=True)
ap.add_argument("--log", action="append", required=True); ap.add_argument("--plant", action="store_true")
A = ap.parse_args()
REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
P = lambda b: json.load(open(f"{b}/patch/placements.json"))["regions"]
old, new = P(A.old), P(A.new)
MOV = {}
moved = subprocess.run([sys.executable, os.path.join(REPO, "tools/attribute_patch_delta.py"), A.old, A.new, "--moved"], capture_output=True, text=True).stdout
for l in moved.split("\n"):
    m = re.match(r"\s*MOVED op\[(\d+)\] (\w+) 0x([0-9a-f]+) -> 0x([0-9a-f]+) len 0x([0-9a-f]+)", l)
    if m: MOV[f"op[{m.group(1)}]"] = {"dst": int(m.group(3), 16), "len": int(m.group(5), 16), "new": int(m.group(4), 16)}
print(f"# {A.old} -> {A.new}: {len(old)} placed regions, {len(MOV)} MOVED ops (attribute_patch_delta.py --moved)")
def region(a, regs):
    for n, r in regs.items():
        if r["dst"] <= a < r["dst"] + r["len"]: return n, a - r["dst"]
    return None, None
def moved_op(a):
    for n, r in MOV.items():
        if r["dst"] <= a < r["dst"] + r["len"]: return n, a - r["dst"], r["new"]
    return None, None, None
def hole_op(a):
    c = [(r["dst"], n, r) for n, r in MOV.items() if r["dst"] <= a <= r["dst"] + 0x1000]
    if not c: return None, None, None
    d, n, r = max(c)
    return n, a - d, r["new"]
HEX = re.compile(r"0x([0-9a-fA-F]{6,})|(?<![0-9a-fA-Fx$])([0-9a-fA-F]{6})(?![0-9a-fA-F])")
def addrs(s):
    out = []
    for m in HEX.finditer(s):
        v = int(m.group(1) or m.group(2), 16)
        if v >= 0x400000: out.append((m.start(), m.group(0), v))
    return out
plant = A.plant
tot = bad = nonaddr = 0
for g in A.log:
    L = open(g).read().split("\n")
    o = [l.strip()[1:].strip() for l in L if (l.strip().startswith("<") or l.strip().startswith("-")) and not l.strip().startswith("---")]
    n = [l.strip()[1:].strip() for l in L if (l.strip().startswith(">") or l.strip().startswith("+")) and not l.strip().startswith("+++")]
    print(f"== {g}: {len(o)} old / {len(n)} new diff lines")
    if len(o) != len(n): print("   UNPAIRED: old and new line counts differ"); bad += 1
    for a, b in zip(o, n):
        ao, an = addrs(a), addrs(b)
        if plant and tot == 0 and an: an[0] = (an[0][0], an[0][1], an[0][2] + 2)
        # the text with every address blanked must agree
        blank = lambda s, xs: re.sub(r"\s+", " ", HEX.sub(lambda m: "@" if int(m.group(1) or m.group(2), 16) >= 0x400000 else m.group(0), s))
        if blank(a, ao) != blank(b, an) or len(ao) != len(an):
            print(f"   NON-ADDRESS  {a[:110]}  ->  {b[:110]}"); nonaddr += 1; continue
        for (_, so, vo), (_, sn, vn) in zip(ao, an):
            if vo == vn: continue
            tot += 1
            rn, off = region(vo, old)
            if rn is not None:
                ok = rn in new and new[rn]["dst"] + off == vn
                print(f"   {'ok  ' if ok else 'UNATTRIBUTED'} {so} -> {sn}  region {rn} +0x{off:x}  (m20 dst 0x{old[rn]['dst']:x} -> m21 0x{new[rn]['dst']:x})")
            else:
                on, off, nb = moved_op(vo)
                if on is not None:
                    ok = nb + off == vn
                    print(f"   {'ok  ' if ok else 'UNATTRIBUTED'} {so} -> {sn}  MOVED {on} +0x{off:x}  (m20 0x{vo - off:x} -> m21 0x{nb:x})")
                else:
                    hn, off, nb = hole_op(vo)
                    ok = hn is not None and nb + off == vn
                    print(f"   {'ok-HOLE' if ok else 'UNATTRIBUTED'} {so} -> {sn}  " + (f"in no op: +0x{off:x} past the start of MOVED {hn} (m20 0x{vo - off:x} -> m21 0x{nb:x}), offset preserved" if hn else "(in no placed region, no MOVED op, no MOVED op within 0x1000 below)"))
            if not ok: bad += 1
print(f"moved addresses {tot}; unattributed {bad}; non-address line pairs {nonaddr}")
sys.exit(1 if (bad or nonaddr) else 0)
