#!/usr/bin/env python3
"""move_parity_p2x.py — P2's position, ours vs native, per parity EVENT (14z-221, #363; the census that found Phobos's ES
Plasma Beam sliding the victim 49 px further on ours). audit_move_parity compares the TENANT's state and P2's HP, never P2's
position; this reads it from that gate's kept traces.

The traces are audit_move_parity's legs, kept with KEEP= and traced with two fields added:
  ROMDIR=... ALL=1 KEEP=<dir> FIELDS_EXTRA=ff8810:w:p2x,ff8814:w:p2y tests/audit_move_parity.sh
  python3 tools/move_parity_p2x.py <dir> tests/expected/move_parity_events.tsv > p2x_events.tsv
p2x is RAM:$FF8810, p2y $FF8814. Measured 14z-221 on m3b_merged33 (0ddac362): 526 events, 24 with P2 moving differently;
with the tenant's own x identical (p1max 0) huitzil_4:0 and :1 (+49 each, tests/audit_beam_slide.sh) and pyron_1:26
(8 px, back to 0 by the window's end). A MEASUREMENT, not a gate: nothing here is frozen.
Each event is judged in its own window [its frame, the next event's frame), the way tools/move_parity.py does; frames
on which the rig itself writes $FF8810 or $FF8410 (its X pins) are dropped, and the window is cut at the first such
pin (after it, both legs are reset). Per event:
  d0      ours - native P2 x at the window's first frame (the offset carried in)
  first   the first frame where (ours - native) != d0, or '-'
  end     (ours - native) - d0 on the last frame before the pin (what the event added)
  max     the largest |(ours - native) - d0| in the window
  p1      the same 'max' for the TENANT's x (the gate's own compared x: 0 on an IDENT row)
  y       the largest |ours - native| P2 y difference in the window
Usage: move_parity_p2x.py <keep dir> <move_parity_events.tsv> > p2x_events.tsv
"""
import glob, json, os, sys

keep, expect = sys.argv[1], sys.argv[2]
REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
verdict = {}
for L in open(expect):
    if L.startswith("#") or not L.strip():
        continue
    f = L.rstrip("\n").split("\t")
    if len(f) >= 4 and f[1].isdigit():
        verdict[(f[0], int(f[1]))] = f[3]


def load(path):
    t = {}
    for L in open(path):
        f = L.split()
        if len(f) > 2 and f[0] == "F":
            t[int(f[1])] = {k: int(v) for k, v in (x.split("=", 1) for x in f[2:]) if v.lstrip("-").isdigit()}
    return t


print("part\tevent\tname\tverdict\td0\tfirst\tend\tmax\tp1max\tp2ymax\tframes")
for nat in sorted(glob.glob(os.path.join(keep, "tr_*_native.txt"))):
    tp = os.path.basename(nat)[3:-len("_native.txt")]
    ours = nat.replace("_native.txt", "_ours.txt")
    sched = os.path.join(REPO, "tests/replays/naming", tp + ".json")
    if not (os.path.exists(ours) and os.path.exists(sched)):
        continue
    n, o = load(nat), load(ours)
    j = json.load(open(sched))
    pins = sorted({int(p.split(":")[0].split("-")[0]) for p in j["pokes"] if p.split(":")[1].lower() in ("ff8810", "ff8410")})
    ev = j["events"]
    last = max(set(n) & set(o)) if set(n) & set(o) else 0
    for k, e in enumerate(ev):
        a = e["frame"]
        b = ev[k + 1]["frame"] if k + 1 < len(ev) else last + 1
        cut = next((p for p in pins if a < p < b), b)
        fr = [f for f in range(a, cut) if f in n and f in o and f not in pins]
        row = [tp, str(k), e["name"], verdict.get((tp, k), "?")]
        if not fr:
            print("\t".join(row + ["-"] * 6 + ["0"]))
            continue
        d0 = o[fr[0]]["p2x"] - n[fr[0]]["p2x"]
        first, mx, p1, py = "-", 0, 0, 0
        for f in fr:
            d = o[f]["p2x"] - n[f]["p2x"] - d0
            if d and first == "-":
                first = str(f)
            mx = max(mx, abs(d))
            p1 = max(p1, abs((o[f]["x"] - n[f]["x"]) - (o[fr[0]]["x"] - n[fr[0]]["x"])))
            py = max(py, abs(o[f]["p2y"] - n[f]["p2y"]))
        end = o[fr[-1]]["p2x"] - n[fr[-1]]["p2x"] - d0
        print("\t".join(row + [str(d0), first, str(end), str(mx), str(p1), str(py), str(len(fr))]))
