#!/usr/bin/env python3
"""mizuumi_chars.py — the analysis of tests/audit_mizuumi_chars.sh (14z-196, GitHub #118, HOMING item 5).

    python3 tools/mizuumi_chars.py --work <gate work dir> --replays tests/replays --legs <work>/legs.txt \\
        [--pert none|absent-move|wrong-owner|pool-miscount] --out <counts.tsv>

Reads the gate's legs (per tag: <tag>.fields from tests/lua/field_trace.lua, <tag>.tap and read_<tag>.tap from
tests/lua/read_tap.lua) and judges K1-K12 (the gate's WHAT), each against a quantity read independently of the field
judged: the projectile pool ($FF9400 + n*0x100: +0x00 alive, +0x02 type, +0x30 owner word), both HP words, the character
id +0x382, the engine pass counter $FF8081, the replay's input script. Prints one `  ok    [Kn] ...` or `  FAIL  [Kn] ...`
line per judgement, writes the frozen counts to --out, exits 1 on any FAIL. Plain python (no numpy). The character
names come from tools/vanilla_frames.py's CHARS (held to the atlas by tools/audit_charid_names.py).

--pert applies one control's perturbation to the real traces (the gate's MUST-FIRE lines):
  absent-move    every move detector emptied (no own/opponent type-4 projectile, no Gallon Dark Force, no taunt press,
                 no D,D,D before a confirm) — K1 K3 K4 K7 K10 K11 must fail;
  wrong-owner    one non-clear writer PC of the ownership census credited to a second character — K12 must fail;
  pool-miscount  K2's type-41 count shifted by one — K2 must fail;
  passes-inflated   K6 judged against each frame's engine passes + 1 — K6 must fail;
  fall-shifted      K9's P2 HP falls moved 30 frames later — K9 must fail;
  taps-as-dashes    K5's script count taking every tap for a dash — K5 must fail;
  other-side-credit K8's writes credited to the OPPOSITE block's character — K8 must fail.
(rule-checker run 2026-10-08-902 Q4: the last four, each judged check passed unchanged under the first three.)
"""
import argparse
import collections
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import vanilla_frames  # noqa: E402

NAMES = {i: n for i, n in vanilla_frames.CHARS.values()}
BASE = {1: 0xff8400, 2: 0xff8800}
OWNW = {1: 0x8400 - 0x10000, 2: 0x8800 - 0x10000}   # the pool owner word, read SIGNED by field_trace
FLARE, QBEE = 4, 41            # pool types: Demitri's flare (14z-194: P1 Demitri's 105 flares), Q-Bee's projectile
# +0x149's COUNTED pool type per character — MEASURED 14z-196 on this gate's 18 legs (every in-match side-frame tabulated
# as (own live types, +0x149)): the shared spawn/despawn pair PRG:0x05475A / PRG:0x054770 raises and lowers it for ONE
# type per character; Anakaris's reaches 2 and 3 with 2 and 3 of his type-19 objects. K1 holds the map on every leg.
TYPE149 = {"Demitri": {4}, "Bulleta": {2}, "Jedah": {56}, "Bishamon": {28}, "Aulbath": {30}, "Q-Bee": {44},
           "Anakaris": {18, 19}}
DEMITRI, GALLON = 0x01, 0x02
BTN = set("123456")
# CLEAR writers of the 14z-194 pilot's census (analyze_census.CLEAR): the boot RAM fill (0x000Dxx), the block init
# (0x016E4C/E), the per-round reset 0x0222DA and the attack-start resets (0x026Exx / 0x026Fxx). The ownership census
# (K12) judges every OTHER writer.
def clear(pc):
    return pc.startswith("000d") or pc in ("016e4c", "016e4e", "0222da") or pc.startswith("026e") or pc.startswith("026f")
# the per-character slots atlas/ram.md rows name an owner for (mizuumi's "Character Specific Ram slot" family);
# widths: +0x36 and +0x378 are words
NAMED = {0x34: ["Lilith"], 0x35: ["Morrigan"], 0x36: [], 0x360: ["Gallon"], 0x364: ["Gallon", "Morrigan"],
         0x366: ["Gallon"], 0x368: ["Gallon"], 0x369: ["Gallon"], 0x36A: ["Gallon"], 0x36B: ["Gallon"],
         0x36C: ["Sasquatch"], 0x36E: [], 0x370: ["Anakaris"], 0x371: ["Q-Bee"], 0x373: [], 0x374: ["Anakaris"],
         0x378: ["Bishamon"], 0x37F: ["Felicia"]}
SIZE = {0x36: 2, 0x378: 2}

ap = argparse.ArgumentParser()
ap.add_argument("--work", required=True)
ap.add_argument("--replays", required=True)
ap.add_argument("--legs", required=True)
ap.add_argument("--pert", default="none", choices=("none", "absent-move", "wrong-owner", "pool-miscount", "passes-inflated",
                                                   "fall-shifted", "taps-as-dashes", "other-side-credit"))
ap.add_argument("--out", required=True)
A = ap.parse_args()
W, PERT = A.work, A.pert
ABSENT = PERT == "absent-move"
bad, counts = [], []
def res(c, t, m):
    print(f"  {'ok  ' if c else 'FAIL'}  [{t}] {m}")
    if not c:
        bad.append(t)
def cnt(k, v):
    counts.append(f"{k}\t{v}")
def name(c):
    return NAMES.get(c, f"id{c:02x}")

LEGS = []
for l in open(A.legs):
    tag, rpl, fr, pk = l.split()
    LEGS.append((tag, rpl, int(fr)))

def load(tag):
    T = []
    for l in open(f"{W}/{tag}.fields"):
        if l.startswith("F "):
            q = l.split(); d = {"f": int(q[1])}
            for kv in q[2:]:
                k, v = kv.split("="); d[k] = int(v)
            T.append(d)
    return T
def staged(rpl):
    """frame -> {1: tokens, 2: tokens, 'sys': tokens} — field_trace.lua's grammar (one char per token; sys two)"""
    S = collections.defaultdict(lambda: {1: set(), 2: set(), "sys": set()})
    for line in open(os.path.join(A.replays, rpl + ".rpl")):
        body = line.split("#")[0].strip()
        if not body:
            continue
        rng, *specs = body.split()
        a, _, b = rng.partition("-"); a = int(a); b = int(b) if b else a
        for sp in specs:
            m = re.match(r"^(p[12]|sys)=(\S+)$", sp)
            if not m:
                continue
            who = "sys" if m.group(1) == "sys" else int(m.group(1)[1])
            toks = [m.group(2)[i:i + 2] for i in range(0, len(m.group(2)), 2)] if who == "sys" else list(m.group(2))
            for fr in range(a, b + 1):
                S[fr][who] |= set(toks)
    return S
def taps(tag, kind="W"):
    """[(trace frame, pc, byte address, value)] for every byte a tap line covers (W writes, R reads)"""
    out = []
    path = f"{W}/{tag}.tap" if kind == "W" else f"{W}/read_{tag}.tap"
    for l in open(path):
        if l.startswith(kind + " "):
            q = l.split(); f, pc, a, data, mask = int(q[1]), q[3], int(q[5], 16), int(q[7], 16), int(q[9], 16)
            if mask & 0xff00:
                out.append((f + 1, pc, a, (data >> 8) & 0xff))
            if mask & 0x00ff:
                out.append((f + 1, pc, a + 1, data & 0xff))
    return out
def inmatch(d):
    return d["hp1"] > 0 and d["hp2"] > 0 and d["x1"] and d["x2"]
def spans(T, pred):
    out, cur = [], None
    for d in T:
        if pred(d):
            cur = [d["f"], d["f"]] if cur is None else [cur[0], d["f"]]
        elif cur:
            out.append(tuple(cur)); cur = None
    if cur:
        out.append(tuple(cur))
    return out
def own_live(d, s, typ):
    if ABSENT:
        return 0
    return sum(1 for n in range(32) if d.get(f"alive{n}") and d.get(f"own{n}") == OWNW[s] and d.get(f"type{n}") == typ)
def drops(T, s):
    return [b["f"] for a, b in zip(T, T[1:]) if 0 <= b[f"hp{s}"] < a[f"hp{s}"]]
def wfield(tw, s, off):
    a = BASE[s] + off
    return [(f, pc, v) for f, pc, b, v in tw if b == a]

T = {tag: load(tag) for tag, _, _ in LEGS}
S = {tag: staged(rpl) for tag, rpl, _ in LEGS}
TW = {tag: taps(tag) for tag, _, _ in LEGS}
BYF = {tag: {d["f"]: d for d in T[tag]} for tag in T}

# K0 the forced picks of the two rigs read back from +0x382 in the match (POKES, never the cursor)
for tag, want in (("mokt", 0x05), ("anak", 0x06)):
    got = sorted({d["char1"] for d in T[tag] if inmatch(d)})
    cnt(f"pick_{tag}", ",".join(f"{c:02x}" for c in got))
    res(got == [want], "K0", f"{tag}: P1's in-match character {[name(c) for c in got]} (forced {name(want)})")

# K1 +0x149: never above the side's live count of its character's counted type (TYPE149; 0 for a character not in the
# map), and it rises on the frame each object of that type appears (offset frozen)
def own_types(d, s, types):
    if ABSENT:
        return 0
    return sum(1 for n in range(32) if d.get(f"alive{n}") and d.get(f"own{n}") == OWNW[s] and d.get(f"type{n}") in types)
n1 = viol1 = 0; offs1 = collections.Counter(); per1 = collections.Counter()
for tag in T:
    for s in (1, 2):
        Tl = T[tag]
        for d in Tl:
            ty = TYPE149.get(name(d[f"char{s}"]), set())
            if d[f"pact{s}"] > own_types(d, s, ty):
                viol1 += 1
        for a, b in zip(Tl, Tl[1:]):
            ty = TYPE149.get(name(b[f"char{s}"]), set())
            if ty and own_types(b, s, ty) > own_types(a, s, ty):
                n1 += 1; per1[name(b[f"char{s}"])] += 1
                offs1["rise" if b[f"pact{s}"] > a[f"pact{s}"] else "no rise"] += 1
res(n1 > 0 and viol1 == 0 and set(offs1) == {"rise"}, "K1",
    f"+0x149: {n1} new objects of the counted type {dict(per1)}, +0x149 rising on the same frame {dict(offs1)}; side-frames where it exceeds the live count: {viol1}")
cnt("pact_spawns", " ".join(f"{k}:{v}" for k, v in sorted(per1.items())))
# how long each Demitri flare outlives his +0x149 (frames from +0x149's last nonzero frame to the flare's last live frame)
outl = []
for tag in T:
    for s in (1, 2):
        Tl = T[tag]
        for a, b in spans(Tl, lambda d: d[f"char{s}"] == DEMITRI and own_types(d, s, {FLARE}) > 0):
            last = max((d["f"] for d in Tl if a <= d["f"] <= b and d[f"pact{s}"]), default=None)
            outl.append(f"{tag}:P{s}:{a}-{b}:{b - last if last is not None else '-'}")
cnt("pact_demitri_flare_outlives", " ".join(outl))
mx1 = collections.Counter()
for tag in T:
    for s in (1, 2):
        for d in T[tag]:
            c = name(d[f"char{s}"]); mx1[c] = max(mx1[c], d[f"pact{s}"])
cnt("pact_max_by_char", " ".join(f"{k}:{v}" for k, v in sorted(mx1.items()) if v))
w149 = collections.Counter((pc, v) for tag in T for s in (1, 2) for f, pc, v in wfield(TW[tag], s, 0x149) if not clear(pc))
cnt("pact_writers", " ".join(f"{pc}={v}:{n}" for (pc, v), n in sorted(w149.items())))

# K2 +0x14B == the side's live type-41 count on every in-match frame
sh = 1 if PERT == "pool-miscount" else 0
n2 = mism = 0; nz2 = collections.Counter(); hi2 = 0
for tag in T:
    for s in (1, 2):
        for d in T[tag]:
            if not inmatch(d):
                continue
            q = own_live(d, s, QBEE) + sh
            n2 += 1; mism += d[f"c14b{s}"] != q
            if d[f"c14b{s}"]:
                nz2[name(d[f"char{s}"])] += 1; hi2 = max(hi2, d[f"c14b{s}"])
cnt("c14b_nonzero_by_char", " ".join(f"{k}:{v}" for k, v in sorted(nz2.items())))
cnt("c14b_max", hi2)
res(n2 > 0 and mism == 0 and sum(nz2.values()) > 0, "K2",
    f"+0x14B equals the side's live type-41 count{' + 1 (mode pool-miscount)' if sh else ''} on {n2 - mism}/{n2} in-match side-frames; nonzero side-frames by character {dict(nz2)}, max {hi2}")

# K3 +0x0AC: every nonzero writer PC is credited to ONE character (character move code); and Demitri's: each 0x03018A
# write is followed within 20 frames by a new own flare, and each new own flare is preceded within 20 frames by one
by0ac = collections.defaultdict(set); n3 = miss3 = 0; lead3 = collections.Counter()
for tag in T:
    for s in (1, 2):
        ws = [(f, pc, v) for f, pc, v in wfield(TW[tag], s, 0xAC) if v and not clear(pc) and f in BYF[tag]]
        for f, pc, v in ws:
            by0ac[pc].add(name(BYF[tag][f][f"char{s}"]))
        dem = [f for f, pc, v in ws if pc == "03018a"]
        fl = [a for a, b in spans(T[tag], lambda d: own_live(d, s, FLARE) > 0)]
        for f in dem:
            n3 += 1
            nxt = next((g for g in fl if f <= g <= f + 20), None)
            if nxt is None:
                miss3 += 1
            else:
                lead3[nxt - f] += 1
        for g in fl:
            if not any(g - 20 <= f <= g for f in dem):
                miss3 += 1
cnt("pind_writers", " ".join(f"{pc}:{'/'.join(sorted(c))}" for pc, c in sorted(by0ac.items())))
cnt("pind_flare_lead", " ".join(f"{k}:{v}" for k, v in sorted(lead3.items())))
dem3 = []   # each span Demitri's 0x03018A opens: its length and the PC that clears it
for tag in T:
    for s in (1, 2):
        ws = wfield(TW[tag], s, 0xAC)
        for f, pc, v in ws:
            if pc == "03018a" and v:
                end = next(((g, p) for g, p, u in ws if g > f and u == 0), (None, None))
                dem3.append(f"{tag}:P{s}:{f}:{(end[0] - f) if end[0] else '-'}:{end[1]}")
cnt("pind_demitri_spans", " ".join(dem3))
res(by0ac and all(len(c) == 1 for c in by0ac.values()) and n3 > 0 and miss3 == 0, "K3",
    f"+0x0AC: {len(by0ac)} nonzero writer PCs, each with one character: {sorted({next(iter(c)) for c in by0ac.values() if len(c) == 1})}; "
    f"shared {sorted(pc for pc, c in by0ac.items() if len(c) > 1)}; Demitri's 0x03018A writes {n3} -> flare {dict(lead3)} (frames), unpaired {miss3}")

# K4 +0x192: every span on a side starts 0-1 frames after that side's HP fell while the OPPONENT owned a live flare,
# every such fall starts one, each span lasts 37 frames
n4 = miss4 = 0; off4 = collections.Counter(); len4 = collections.Counter()
for tag in T:
    for s in (1, 2):
        Tl = T[tag]; o = 3 - s
        hit = [f for f in drops(Tl, s) if f - 1 in BYF[tag] and (own_live(BYF[tag][f], o, FLARE) or own_live(BYF[tag][f - 1], o, FLARE))]
        sp = spans(Tl, lambda d: d[f"cfl{s}"] != 0)
        used = set()
        for a, b in sp:
            n4 += 1; len4[b - a + 1] += 1
            h = next((h for h in hit if 0 <= a - h <= 1 and h not in used), None)
            if h is None:
                miss4 += 1
            else:
                used.add(h); off4[a - h] += 1
        miss4 += len([h for h in hit if h not in used])
        if sp or hit:
            cnt(f"cfl_{tag}_P{s}", f"spans {sp} flare-hit falls {hit}")
res(n4 > 0 and miss4 == 0 and set(len4) == {37}, "K4",
    f"+0x192: {n4} spans, offset from the flare-hit HP fall {dict(off4)}, lengths {dict(len4)}; unpaired spans or falls {miss4}")
w192 = collections.Counter((pc, v) for s in (1, 2) for f, pc, v in wfield(TW["proj"], s, 0x192) if not clear(pc))
cnt("cfl_writers_proj", " ".join(f"{pc}={v}:{n}" for (pc, v), n in sorted(w192.items())))

# K5 +0x372: every 0x030EF4 write is 2 or 3; nonzero only on a Demitri side; 118_dash's P1 has as many 0x030EF4 writes as
# its script has dashes. The 14z-194 row's "2 opponent to the right, 3 to the left" is NOT judged: measured 14z-196 it
# holds on 6 of 7 writes, and 07_mash_storm's P1 write at f2980 reads 3 with the opponent to the right, P1 facing right
# and moving right — each write's side, facing and value are frozen (dash_write_*), its meaning is not established
n5 = bad5 = nondem = 0; side5 = collections.Counter()
for tag in T:
    for s in (1, 2):
        for f, pc, v in wfield(TW[tag], s, 0x372):
            if pc == "030ef4" and f in BYF[tag]:
                d = BYF[tag][f]; n5 += 1
                bad5 += v not in (2, 3); side5[(v, "right" if d[f"x{3 - s}"] > d[f"x{s}"] else "left")] += 1
                x30 = BYF[tag].get(f + 30, d)[f"x{s}"]
                cnt(f"dash_write_{tag}_P{s}_f{f}", f"value {v} x {d[f'x{s}']} opponent x {d[f'x{3 - s}']} face {d[f'face{s}']} dx30 {x30 - d[f'x{s}']}")
        nondem += sum(1 for d in T[tag] if d[f"dash{s}"] and d[f"char{s}"] != DEMITRI)
def dashes(Sd, s):
    taps_ = [f for f in sorted(Sd) if (Sd[f][s] & set("LR")) and not (Sd.get(f - 1, {s: set()})[s] & set("LR"))]
    if PERT == "taps-as-dashes":
        return len(taps_)
    n, i = 0, 0
    while i + 1 < len(taps_):
        a, b = taps_[i], taps_[i + 1]
        if b - a <= 8 and (Sd[a][s] & set("LR")) == (Sd[b][s] & set("LR")):
            n += 1; i += 2
        else:
            i += 1
    return n
dd = dashes(S["dash"], 1); dw = sum(1 for f, pc, v in wfield(TW["dash"], 1, 0x372) if pc == "030ef4")
w372 = collections.Counter((pc, v) for tag in T for s in (1, 2) for f, pc, v in wfield(TW[tag], s, 0x372) if not clear(pc))
cnt("dash_writers", " ".join(f"{pc}={v}:{n}" for (pc, v), n in sorted(w372.items())))
cnt("dash_writes", f"030ef4 writes {n5}, not 2 or 3 {bad5}; (value, opponent side) {dict(sorted(side5.items()))}; 118_dash P1 script dashes {dd} writes {dw}; nonzero on non-Demitri side-frames {nondem}")
res(n5 > 0 and bad5 == 0 and nondem == 0 and dd == dw and dd > 0, "K5",
    f"+0x372: {n5} 0x030EF4 writes, {bad5} neither 2 nor 3 — (value, opponent side) {dict(sorted(side5.items()))}, reported; nonzero on {nondem} non-Demitri side-frames; 118_dash P1 dashes in the script {dd}, writes {dw}")

# K6 +0x15C spans: fall by at least the frame's engine passes, never rise inside, no HP loss and no attack start
n6 = bad6 = 0
for tag in T:
    for s in (1, 2):
        Tl = T[tag]
        for a, b in spans([d for d in Tl if inmatch(d)], lambda d: d[f"c15c{s}"] > 0):
            n6 += 1; B = BYF[tag]; frames = [f for f in range(a + 1, b + 1) if f in B and f - 1 in B]
            pinc = 1 if PERT == "passes-inflated" else 0
            short = sum(1 for f in frames if (B[f - 1][f"c15c{s}"] - B[f][f"c15c{s}"]) < ((B[f]["pass"] - B[f - 1]["pass"]) & 0xff) + pinc)
            hpl = sum(1 for f in frames if B[f][f"hp{s}"] < B[f - 1][f"hp{s}"])
            atk = sum(1 for f in frames if B[f][f"atk{s}"] > B[f - 1][f"atk{s}"])
            bad6 += short + hpl + atk
            cnt(f"c15c_{tag}_P{s}", f"span {a}-{b} start {B[a][f'c15c{s}']} {name(B[a][f'char{s}'])}; frames falling less than the passes {short}; hp falls {hpl}; attack starts {atk}")
w15c = collections.Counter(pc for tag in T for s in (1, 2) for f, pc, v in wfield(TW[tag], s, 0x15D) if not clear(pc))
cnt("c15c_writers", " ".join(f"{pc}:{n}" for pc, n in sorted(w15c.items())))
res(n6 > 0 and bad6 == 0, "K6", f"+0x15C: {n6} nonzero spans; frames that fall less than the passes, HP falls and attack starts inside: {bad6}")

# K7 +0x1A2 nonzero on exactly a Gallon side's Dark Force frames, 0 through every other character's Dark Force
gal = oth = mism7 = 0
for tag in T:
    for s in (1, 2):
        for d in T[tag]:
            if not inmatch(d):
                continue
            g = d[f"dfm{s}"] != 0 and d[f"char{s}"] == GALLON and not ABSENT
            gal += g; oth += d[f"dfm{s}"] != 0 and d[f"char{s}"] != GALLON
            mism7 += (d[f"c1a2{s}"] != 0) != g
gsp = [f"{tag}:P{s}:{a}-{b}" for tag in T for s in (1, 2)
       for a, b in spans([d for d in T[tag] if inmatch(d)], lambda d: d[f"c1a2{s}"] != 0)]
cnt("c1a2_spans", " ".join(gsp))
cnt("c1a2", f"Gallon Dark Force side-frames {gal}, other Dark Force side-frames {oth}, mismatches {mism7}")
res(gal > 0 and oth > 0 and mism7 == 0, "K7", f"+0x1A2: nonzero on exactly the {gal} Gallon Dark Force side-frames; {oth} other characters' Dark Force side-frames read 0; mismatches {mism7}")

# K8 +0x154: every nonzero write is by a writer PC credited to ONE character; the read legs' reader PCs
def credit(s):   # the block whose character a write is credited to (other-side-credit: the opposite one)
    return 3 - s if PERT == "other-side-credit" else s
by154 = collections.defaultdict(set); fr154 = collections.Counter()
for tag in T:
    for s in (1, 2):
        for f, pc, v in wfield(TW[tag], s, 0x154):
            if v and not clear(pc) and f in BYF[tag]:
                by154[pc].add(name(BYF[tag][f][f"char{credit(s)}"]))
        for d in T[tag]:
            if d[f"c154{s}"]:
                fr154[name(d[f"char{s}"])] += 1
cnt("c154_writers", " ".join(f"{pc}:{'/'.join(sorted(c))}" for pc, c in sorted(by154.items())))
cnt("c154_frames", " ".join(f"{k}:{v}" for k, v in sorted(fr154.items())))
res(by154 and all(len(c) == 1 for c in by154.values()), "K8", f"+0x154 nonzero writers {dict((k, sorted(v)) for k, v in by154.items())}; nonzero side-frames {dict(fr154)}")
# K8b +0x136 and +0x19A the same way over every leg (the rows say "character move code only"): every nonzero writer PC
# credited to ONE character; +0x19A's nonzero side-frames outside 118_mo_kthrow counted (the row: "never set in 13 census
# legs")
for off, fld in ((0x136, "c136"), (0x19A, "c19a")):
    byw = collections.defaultdict(set)
    for tag in T:
        for s in (1, 2):
            for f, pc, v in wfield(TW[tag], s, off):
                if v and not clear(pc) and f in BYF[tag]:
                    byw[pc].add(name(BYF[tag][f][f"char{credit(s)}"]))
    elsewhere = sum(1 for tag in T if tag != "mokt" for s in (1, 2) for d in T[tag] if d[f"{fld}{s}"])
    cnt(f"{fld}_writers", " ".join(f"{pc}:{'/'.join(sorted(c))}" for pc, c in sorted(byw.items())) + f"; nonzero side-frames outside 118_mo_kthrow {elsewhere}")
    res(byw and all(len(c) == 1 for c in byw.values()), "K8",
        f"+0x{off:03X} nonzero writers {dict((k, sorted(v)) for k, v in sorted(byw.items()))}; nonzero side-frames outside 118_mo_kthrow {elsewhere}")
for tag in ("proj", "c128"):
    rd = collections.Counter()
    for f, pc, a, v in taps(tag, "R"):
        for s in (1, 2):
            o = a - BASE[s]
            if o in (0x154, 0xac):
                rd[(f"+0x{o:03X}", pc)] += 1
    cnt(f"readers_{tag}", " ".join(f"{o}@{pc}:{n}" for (o, pc), n in sorted(rd.items())))

# K9 118_mo_kthrow: each P2 +0x19A 0xFF span holds a P2 HP fall; P1's +0x136 rises on the frame each ends
Tl = T["mokt"]
s19a = spans(Tl, lambda d: d["c19a2"] == 0xff)
s136 = spans(Tl, lambda d: d["c1361"] == 1)
fsh = 30 if PERT == "fall-shifted" else 0
hit9 = [next((f + fsh - b for f in drops(Tl, 2) if b <= f + fsh <= b + 1), None) for a, b in s19a]   # the throw's damage lands as the flag clears
link9 = [next((p - (b + 1) for p, q in s136 if p >= b), None) for a, b in s19a]
cnt("kthrow", f"+0x19A spans {s19a} with a P2 hp fall {hit9}; +0x136 spans {s136} (lengths {[q - p + 1 for p, q in s136]}); +0x136 rise - +0x19A end {link9}")
w9 = collections.Counter((pc, v) for s in (1, 2) for off in (0x136, 0x19A) for f, pc, v in wfield(TW["mokt"], s, off) if not clear(pc))
cnt("kthrow_writers", " ".join(f"{pc}={v}:{n}" for (pc, v), n in sorted(w9.items())))
res(len(s19a) >= 2 and all(x is not None for x in hit9) and len(s136) == len(s19a) and all(x == 0 for x in link9), "K9",
    f"118_mo_kthrow: {len(s19a)} P2 +0x19A spans (lengths {[b - a + 1 for a, b in s19a]}), a P2 HP fall 0-1 frames after each one's last frame {hit9}; P1 +0x136 spans {len(s136)}, rise - (+0x19A end + 1) {link9}")

# K10 +0x1BB: on 118_anak_taunt one rise, 0-2 frames after the first START+LP+MP+HP press in the match; 0 elsewhere
def taunts(Sd, s, m0):
    return [f for f in sorted(Sd) if f >= m0 and "S1" in Sd[f]["sys"] and set("123") <= Sd[f][s]
            and not ("S1" in Sd.get(f - 1, {"sys": set()})["sys"] and set("123") <= Sd.get(f - 1, {s: set()})[s])]
Tl = T["anak"]; m0 = next(d["f"] for d in Tl if inmatch(d))
tp = [] if ABSENT else taunts(S["anak"], 1, m0)
sbb = spans(Tl, lambda d: d["c1bb1"] != 0)
off10 = [sbb[0][0] - tp[0]] if (sbb and tp) else None
other10 = sum(1 for tag in T if tag != "anak" for s in (1, 2) for d in T[tag] if d[f"c1bb{s}"])
cnt("taunt", f"presses {tp} +0x1BB spans {sbb} (lengths {[b - a + 1 for a, b in sbb]}); nonzero side-frames on other legs {other10}")
w10 = collections.Counter((pc, v) for f, pc, v in wfield(TW["anak"], 1, 0x1BB) if not clear(pc))
cnt("taunt_writers", " ".join(f"{pc}={v}:{n}" for (pc, v), n in sorted(w10.items())))
res(len(sbb) == 1 and off10 is not None and 0 <= off10[0] <= 2 and other10 == 0, "K10",
    f"118_anak_taunt: +0x1BB spans {sbb}, rise - first taunt press {off10}; other legs' nonzero side-frames {other10}")

# K11 +0x3C1 reads 1 only on the side whose script moves D,D,D before its select confirm, from that confirm
n11 = bad11 = 0; det = []
for tag in T:
    for s in (1, 2):
        Sd = S[tag]
        pr = [(f, Sd[f][s]) for f in sorted(Sd) if Sd[f][s] and not (Sd.get(f - 1, {s: set()})[s] & Sd[f][s])]
        conf = next((f for f, t in pr if t & BTN), None)
        dd3 = conf is not None and sum(1 for f, t in pr if f < conf and "D" in t) >= 3 and not ABSENT
        on = [d["f"] for d in T[tag] if d[f"c3c1{s}"]]
        if dd3:
            n11 += 1; det.append(f"{tag} P{s} confirm f{conf} first 1 f{on[0] if on else '-'}")
            bad11 += not on or not (0 <= on[0] - conf <= 3)
        else:
            bad11 += bool(on)
            if on:
                det.append(f"{tag} P{s} UNEXPECTED first 1 f{on[0]}")
cnt("random_flag", "; ".join(det))
res(n11 > 0 and bad11 == 0, "K11", f"+0x3C1: {n11} D,D,D sides — {det}; violations {bad11}")
w11 = collections.Counter((pc, v) for f, pc, v in wfield(TW["rnd"], 1, 0x3C1))
cnt("random_writers", " ".join(f"{pc}={v}:{n}" for (pc, v), n in sorted(w11.items())))

# K12 THE SLOT OWNERSHIP CENSUS over every leg: each non-clear writer PC of the named slots seen with ONE character
owners = collections.defaultdict(lambda: collections.defaultdict(collections.Counter))
vals = collections.defaultdict(lambda: collections.defaultdict(set))
pcchars = collections.defaultdict(set)
played = collections.Counter()
for tag in T:
    for d in T[tag]:
        if inmatch(d):
            for s in (1, 2):
                played[name(d[f"char{s}"])] += 1
    for f, pc, b, v in TW[tag]:
        if clear(pc) or f not in BYF[tag]:
            continue
        for s in (1, 2):
            off = b - BASE[s]
            for o in NAMED:
                if o <= off < o + SIZE.get(o, 1):
                    ch = name(BYF[tag][f][f"char{s}"])
                    owners[o][ch][pc] += 1; pcchars[pc].add(ch); vals[o][ch].add(v)
if PERT == "wrong-owner":   # one writer PC credited to a second character
    pc0 = sorted(pcchars)[0]
    pcchars[pc0].add("Planted" if pcchars[pc0] != {"Planted"} else "Planted2")
shared = sorted(pc for pc, c in pcchars.items() if len(c) > 1)
for o, named in NAMED.items():
    w = owners[o]; verdict = []
    for n in named:
        if n in w:
            verdict.append(f"{n} WRITES {'NONZERO' if any(vals[o][n]) else 'ZERO ONLY'}")
        elif played[n]:
            verdict.append(f"{n} PLAYED {played[n]} NEVER WROTE")
        else:
            verdict.append(f"{n} NOT PLAYED")
    cnt(f"slot_{o:03x}", f"{' | '.join(verdict) or 'no named owner'}; writers {'; '.join(f'{ch}:' + ','.join(sorted(c)) for ch, c in sorted(w.items())) or 'none'}")
cnt("played", " ".join(f"{k}:{v}" for k, v in sorted(played.items())))
res(pcchars and not shared, "K12", f"the ownership census: {len(pcchars)} non-clear writer PCs over {len(NAMED)} slots, each with one character; shared {shared}")

open(A.out, "w").write("\n".join(counts) + "\n")
sys.exit(1 if bad else 0)
