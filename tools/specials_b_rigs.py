#!/usr/bin/env python3
"""specials_b_rigs.py — the VANILLA SPECIALS naming rigs, F2's half (GitHub #229, 14z-205, fork F2): which chain each
workbook special of Lei-Lei, Lilith, Morrigan, Q-Bee, Sasquatch, Victor and Zabel ENTERS on vsavj, and the
frame data the engine then plays, measured live.

  python3 tools/specials_b_rigs.py gen <tab> <set> <out.rpl> <out.json>     set = whiff | hit
  python3 tools/specials_b_rigs.py analyse <trace> <sched.json> <image.bin> [--json out]
  python3 tools/specials_b_rigs.py fields                                   the FIELDS string the legs trace

METHOD (#229's body; [VSE-47]): a scripted motion is NOT the move it names, so nothing here trusts its own
script. Each event performs one workbook row's input; the verdict is what the ENGINE did inside the event
window: the first chain P1's node pointer +0x1C entered that is not in the baseline family (table a 0x00-0x10:
idle, walk, crouch, jump — tools/name_moves.py BASELINE), mapped onto tools/anim_nodes.py's graph of every
table of the character (a, a2, b, c, proj). A window that enters no new chain is UNFIRED, never guessed; one
that enters a plain-normal slot (a2 0x00-0x1D) reads DEGRADED — the motion was not read as the special.

WHAT IS MEASURED PER EVENT, live, from the trace (never from node duration bytes):
  * the chains P1 walks from the first non-baseline entry back to a baseline chain, in order;
  * P1's own attack frames: a frame is ACTIVE when P1's current node carries an attack box (hbA != 0);
    startup = frames from the first non-baseline frame to the first active one; active = active frames;
    recovery = frames from the last active one to the return to baseline (the page's convention for normals,
    docs/project/tables/community_crosscheck.md, ours side);
  * PROJECTILES: the first projectile slot ($FF9400 + n*0x100, +0x00 alive) that comes alive in the window —
    P2 is idle, so it is P1's — its type (+0x02), its first ACTIVE frame (its own node +0x1C mapped onto the
    character's proj table, hbA != 0), its active frames and its lifetime;
  * on the `hit` set (P2 inside contact range, HP re-pinned just before each event, never during): every P2
    HP drop (+0x50) in the window — hit count and dealt damage — and P1's meter gain (+0x10A plus 0x90 x the
    stocks +0x109).

THE SCHEDULE is data in this file, one list per character, each event (workbook move name, input as the
workbook writes it, recipe, gap, kind): kind `g` = on the ground at the pin, `a` = the recipe starts with its
own jump. The recipes are tools/name_moves.py's (the cadences that ALREADY fired natively) where one exists;
the ones added here are named and their source given beside them.

THE PINS. `whiff` pins P1 and P2 WIDE apart (X_WIDE) so a ground special does not reach P2 and no hit-freeze
holds a node ([VSE-25]); `hit` walks P1 in from the far pin (a near pair cannot be poked — the fighters cross,
vanilla_join_rig.py's header). P2 is Victor (0x03, poked), idle; P1 the character by the early-window poke
(replay 17's prologue, [VSP-120]). The round intro holds the fighters until ~f2546, so the first event is at
name_moves.FIRST_EVENT + 200 = 2800 (vanilla_join_rig.py's WALKIN_SHIFT, #134).
"""
import argparse
import json
import os
import re
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import anim_nodes  # noqa: E402
import name_moves as nm  # noqa: E402
import vanilla_frames  # noqa: E402

CHARS = {"LE": 0x0D, "LI": 0x0E, "MO": 0x05, "QB": 0x0C, "SA": 0x0A, "VI": 0x03, "ZA": 0x04}
B = nm.B
FIRST = nm.FIRST_EVENT + 200
X_FAR = nm.PIN["far"]          # (552, 728): 176 px, the join rigs' far pin
X_WIDE = (440, 800)            # 360 px: the whiff pin (measured to hold: the analyse step reports both xs)
POOL, STRIDE, NSLOT = 0xFF9400, 0x100, 8


# ---- recipes added here (each a list of (start, end, tokens[, who]) as tools/name_moves.py's)
def down_down(b):      # 22+button: D, release, D HELD and the button pressed during it (Sasquatch's Big Towers)
    # promoted from the probe set (14z-205): D then D+button on the same frame, at any spacing tried (2-6 f of
    # neutral), played the crouching normal; the button 2 f into the second D fired a2:0x2e
    return [(0, 2, "D"), (5, 9, "D"), (7, 9, B[b])]


def hold_dp(b, hold):  # 623 with the button HELD for `hold` frames (Sasquatch's Big Blow levels)
    return [(0, 2, "R"), (4, 6, "D"), (8, 11, "DR"), (8, 8 + hold, B[b])]


def kmash(b, n=5, gap=2, air=False):   # K,K,K,K,b: one-frame taps `gap` apart, the last one the strength
    # gap 2 (promoted from the probe set, 14z-205): at gap 3 and 4 Q-Bee only ever played the standing kick;
    # at gap 1-2 with five or more taps the kick is followed by a2:0x61 > 0x62 > 0x67 (the mash special)
    o = 12 if air else 0
    r = [(0, 2, "U")] if air else []
    return r + [(o + i * gap, o + i * gap, B[b]) for i in range(n)]


def down_uphold(b, air=False):   # 2[8]+K: D, then U held, the button pressed while U is held (Zabel's Skull Sting)
    o = 12 if air else 0
    r = [(0, 2, "U")] if air else []
    return r + [(o, o + 3, "D"), (o + 5, o + 20, "U"), (o + 8, o + 10, "U" + B[b])]


def hells_gate(b):     # 412[6]+K: L, DL, D, then R held with the button (Zabel's Hell's Gate)
    return [(0, 2, "L"), (3, 5, "DL"), (6, 8, "D"), (10, 30, "R"), (12, 14, "R" + B[b])]


def air(rec):          # name_moves' air motions start with their own jump; the ground ones do not
    return rec


def _p(strengths, fn, name, inp, gap, kind="g"):
    return [(f"{s} {name}", inp.replace("x", s), fn(s), gap, kind) for s in strengths]


P3, K3 = ("LP", "MP", "HP"), ("LK", "MK", "HK")
FAMILY = {"special", "special projectile", "movement special"}   # the workbook `type`s this rig owns (the brief: F2)
SCHED = {
    "LE": _p(P3, nm.qcf, "ANKIHOU", "236x", 240) + _p(P3, nm.qcb, "HENKYOUKI", "214x", 240)
          + [(f"AIR {s} HENKYOUKI", f"J.214{s}", nm.air_qcb(s), 260, "a") for s in P3]
          + _p(P3, nm.dp, "SENPUUBU", "623x", 300),
    "LI": _p(P3, nm.qcf, "SOUL FLASH", "236x", 240)
          + [(f"AIR {s} SOUL FLASH", f"J.236{s}", nm.air_qcf(s), 260, "a") for s in P3]
          + _p(P3, nm.dp, "SHINING BLADE", "623x", 240)
          + [(f"{p} MERRY TURN", f"214{k}", nm.qcb(k), 240, "g") for p, k in zip(P3, K3)],
    "MO": _p(P3, nm.qcf, "SOUL FIST", "236x", 240)
          + [(f"AIR {s} SOUL FIST", f"J.236{s}", nm.air_qcf(s), 260, "a") for s in P3]
          + _p(P3, nm.dp, "SHADOW BLADE", "623x", 240),
    "QB": _p(K3, nm.qcb, "DELTA A", "214x", 260)
          + [(f"AIR {s} DELTA A", f"J.214{s}", nm.air_qcb(s), 280, "a") for s in K3]
          + [(f"{s} SXP", f"K,K,K,K,{s}", kmash(s), 220, "g") for s in ("LK", "MK")]
          + [(f"AIR {s} SXP", f"J.K,K,K,K,{s}", kmash(s, air=True), 240, "a") for s in ("LK", "MK")],
    "SA": _p(P3, nm.qcf, "BIG BREATH", "236x", 240)
          + [("LVL1 BIG BLOW", "623P", nm.dp("LP"), 260, "g"),
             ("LVL2 BIG BLOW", "623[P] hold 40", hold_dp("LP", 40), 300, "g"),
             ("LVL3 BIG BLOW", "623[P] hold 80", hold_dp("LP", 80), 340, "g")]
          + _p(K3, nm.dp, "BIG TYPHOON", "623x", 260)
          + _p(P3, down_down, "BIG TOWERS", "22x", 240),
    "VI": _p(P3, nm.charge_bf, "GIGA FOREHEAD", "[4],6x", 300) + _p(P3, nm.charge_du, "GIGA STAKE", "[2],8x", 300)
          + [(f"{p} GIGA BURN", f"623{k}", nm.dp(k), 260, "g") for p, k in zip(P3, K3)]
          + _p(P3, nm.qcb, "GYRO CRUSH", "214x", 260),
    "ZA": _p(K3, nm.qcb, "DEATH HURRICANE", "214x", 260)
          + [(f"AIR {s} DEATH HURRICANE", f"J.214{s}", nm.air_qcb(s), 280, "a") for s in K3]
          + [(f"{s} SKULL STING", f"2[8]{s}", down_uphold(s), 260, "g") for s in K3]
          + [(f"AIR {s} SKULL STING", f"J.2[8]{s}", down_uphold(s, air=True), 280, "a") for s in K3]
          + [("HELLS GATE", "412[6]K (as 41236LK)", nm.hcf("LK"), 300, "g")],   # 412 then R held + K played the
          # standing kick at +10 and +30 (probe set); 41236+K and 4123-6+K both entered a2:0x3d (14z-205)
}



# THE PROBE SET (14z-205): alternative cadences for the rows whose schedule recipe did not fire the special, and
# the controls that decide what a chain is. Each is named for what it varies; the first one that fires the row's
# special is promoted into SCHED with its source given. `set = probe` runs these instead of SCHED.
def _taps(bs, gap, o=0):
    return [(o + i * gap, o + i * gap, B[b]) for i, b in enumerate(bs)]


PROBES = {
    "QB": [("SXP gap2 x5 LK", "LKx5 @2", _taps(["LK"] * 5, 2), 200, "g"),
           ("SXP gap4 x5 LK", "LKx5 @4", _taps(["LK"] * 5, 4), 200, "g"),
           ("SXP gap2 x8 LK", "LKx8 @2", _taps(["LK"] * 8, 2), 200, "g"),
           ("SXP alt K x5", "LK MK HK LK LK @2", _taps(["LK", "MK", "HK", "MK", "LK"], 2), 200, "g"),
           ("SXP alt K x5 end MK", "LK HK LK HK MK @2", _taps(["LK", "HK", "LK", "HK", "MK"], 2), 200, "g"),
           ("SXP gap1 x5 LK", "LKx5 @1 (release between)", [(i * 2, i * 2, "4") for i in range(5)], 200, "g")],
    "SA": [("TOWERS D n4 D+P", "2 . 2+LP", [(0, 3, "D"), (8, 11, "D1")], 200, "g"),
           ("TOWERS D n2 D then P", "2 . 2 LP", [(0, 2, "D"), (5, 9, "D"), (7, 9, "1")], 200, "g"),
           ("TOWERS DD fast", "22LP fast", [(0, 1, "D"), (3, 4, "D1")], 200, "g"),
           ("TOWERS D n6 D+P", "2 .. 2+LP", [(0, 4, "D"), (11, 15, "D1")], 200, "g")],
    "ZA": [("HELL 412 R hold K@+10", "412[6]LK", [(0, 2, "L"), (3, 5, "DL"), (6, 8, "D"), (9, 40, "R"), (19, 21, "R4")], 220, "g"),
           ("HELL 412 R hold K@+30", "412[6]LK late", [(0, 2, "L"), (3, 5, "DL"), (6, 8, "D"), (9, 50, "R"), (39, 41, "R4")], 240, "g"),
           ("HELL 41236 K", "41236LK", nm.hcf("LK"), 220, "g"),
           ("HELL 412 DR R K", "4123 6+LK", [(0, 2, "L"), (3, 5, "DL"), (6, 8, "D"), (9, 10, "DR"), (11, 30, "R"), (13, 15, "R4")], 220, "g")],
    "MO": [("JUMP no button", "8", [(0, 2, "U")], 200, "a"),
           ("JUMP then 236 no button", "8, 236", [(0, 2, "U"), (12, 13, "D"), (14, 15, "DR"), (16, 20, "R")], 200, "a"),
           ("AIR LP SOUL FIST late", "J.236LP late", [(0, 2, "U"), (20, 21, "D"), (22, 23, "DR"), (24, 28, "R"), (25, 29, "1")], 220, "a")],
}

def fields():
    f = ["ff8081:b:pass", "ff8116:b:lvl", "ff841c:l:node", "ff8410:w:p1x", "ff8414:w:p1y", "ff8810:w:p2x", "ff8850:w:p2hp",
         "ff850a:w:p1meter", "ff8509:b:p1stock"]
    for n in range(NSLOT):
        a = POOL + n * STRIDE
        f += [f"{a:06x}:b:s{n}", f"{a + 2:06x}:b:t{n}", f"{a + 0x1c:06x}:l:n{n}"]
    return ",".join(f)


def gen(tab, setname, out_rpl, out_sched):
    cid = CHARS[tab]
    lines = [f"# vanilla specials rig — {tab} ({cid:#04x}), set {setname} (tools/specials_b_rigs.py gen; DO NOT hand-edit,",
             "# regenerate). Select prologue from replay 17; P1 and P2 forced by the early-window poke.",
             nm.REPLAY17_PROLOGUE.rstrip()]
    sched = {"tab": tab, "char": f"{cid:#04x}", "set": setname, "events": []}
    pins, t = [], FIRST
    for name, inp, rec, gap, kind in (PROBES[tab] if setname == "probe" else SCHED[tab]):
        if setname == "hit":
            gap = max(gap, 420)
            x1, x2 = X_FAR
            pins += [f"{t - 230}:ff8410:{x1:04x}", f"{t - 230}:ff8810:{x2:04x}"]
            lines.append(f"{t - 190}-{t - 40} p1=R")
        else:
            x1, x2 = X_WIDE
            pins += [f"{t - 40}:ff8410:{x1:04x}", f"{t - 40}:ff8810:{x2:04x}"]
        for r in rec:
            a, b, tok = r[:3]
            who = r[3] if len(r) > 3 else "p1"
            lines.append(f"{t + a}-{t + b} {who}={tok}")
        btn = [a for a, b, tok, *w in rec if any(ch.isdigit() for ch in tok)]
        btn = btn or [0]
        sched["events"].append({"name": name, "input": inp, "frame": t, "press": t + max(btn), "first_button": t + min(btn),
                                "gap": gap, "kind": kind})
        t += gap
    end = t + 200
    lines.append(f"{end} wait")
    assert end - nm.ROUND_START < 7500, f"{tab} {setname}: {end - nm.ROUND_START} frames exceed a round"
    pokes = [f"{f}:ff8782:{cid:02x}" for f in (1400, 1450, 1500)] + [f"{f}:ff8b82:03" for f in (1400, 1450, 1500)]
    if setname == "hit":
        pokes += [f"{e['frame'] - 20}:ff8850:01200120" for e in sched["events"]]
    else:
        pokes += [f"{f}:ff8850:01200120" for f in range(FIRST - 50, end, nm.HP_PIN_EVERY)]
    pokes += pins
    sched["pokes"], sched["frames"] = pokes, end + 50
    Path(out_rpl).write_text("\n".join(lines) + "\n")
    Path(out_sched).write_text(json.dumps(sched, indent=1) + "\n")
    print(f"wrote {out_rpl} ({len(sched['events'])} events, ends {end}) and {out_sched}")


def walk_signed(img, table):
    """{seq: [(node addr, hbA high byte), ...]} for one anim index table, the table's word offsets read SIGNED.

    THE ENGINE ADDS THE OFFSET SIGN-EXTENDED (a 68000 word add), and some tables carry NEGATIVE offsets — chains
    that sit BELOW their index table: Sasquatch's a2 seq 0x24 (-1960) and 0x25 (-1768), his Big Breath and Big
    Blow, measured 14z-205 (#229 F2). tools/anim_nodes.py's walk_table reads them UNSIGNED, so it walks those
    seqs at table + 0xF858 (garbage) and this rig's first pass read every Big Breath and Big Blow UNFIRED. This
    is a local walk with the SAME node rules (flags bit 7 = link at +0x18, bit 6 = hold, else sequential), the
    entry count bounded by the smallest POSITIVE offset as anim_nodes.py does; the shared tool is not edited
    here (the #229 parallel run's brief) and the defect is reported."""
    words, k = [], 0
    while k < 1024:
        # SPECIALS_UNSIGNED=1 reads them UNSIGNED, as tools/anim_nodes.py does: the gate's known-bad control
        # `unsigned-offsets` (Sasquatch's Big Breath and Big Blow then read UNFIRED, as the first pass did)
        w = int.from_bytes(img[table + 2 * k:table + 2 * k + 2], "big", signed=os.environ.get("SPECIALS_UNSIGNED") != "1")
        pos = [x for x in words if x > 0]
        if pos and k * 2 >= min(pos):
            break
        words.append(w)
        k += 1
    out = {}
    for seq, w in enumerate(words):
        if w == 0 or w & 1:
            continue
        a, seen, nodes = table + w, set(), []
        while a not in seen and 0 <= a < len(img) - 0x1C and len(nodes) < anim_nodes.MAX_NODES:
            seen.add(a)
            fl = img[a + 1]
            nodes.append((a, img[a + 10]))
            DUR[a] = img[a]
            if fl & 0x80:
                a = int.from_bytes(img[a + 0x18:a + 0x1C], "big")
            elif fl & 0x40:
                break
            else:
                a += anim_nodes.NODE
        out[seq] = nodes
    return out


DUR = {}        # node addr -> its duration byte (+0), filled by walk_signed
NEGATIVE = {}   # (cid, table) -> [seq, ...] whose offset is negative: filled by node_maps, printed by `negatives`


def node_maps(img, cid):
    """({addr: (chain, hbA)} for the fighter tables a2, a, b, c; same for proj), offsets read signed."""
    rows = vanilla_frames.bank_rows(Path(__file__).resolve().parent.parent / "build/manifest/bank_map.toml")
    fighter, proj = {}, {}
    STARTS.clear(); MEMBERS.clear(); CHAIN_ORDER.clear()
    for tn in ("a2", "a", "b", "c", "proj"):
        tbl = vanilla_frames.row_ptr(img, rows["anim_index_" + tn], cid)
        tgt = proj if tn == "proj" else fighter
        for seq, nodes in walk_signed(img, tbl).items():
            if nodes and nodes[0][0] < tbl:
                NEGATIVE.setdefault((cid, tn), []).append(seq)
            lab = f"{tn}:{seq:#04x}"
            if tn != "proj" and nodes:
                STARTS.setdefault(nodes[0][0], lab)
                MEMBERS[lab] = {a for a, hb in nodes}
                CHAIN_ORDER[lab] = [a for a, hb in nodes]
            for a, hb in nodes:
                tgt.setdefault(a, (lab, hb))
    return fighter, proj


STARTS, MEMBERS, CHAIN_ORDER = {}, {}, {}   # chain start node -> label (first table to claim it); label -> its node set


def labels(fr, fm, f0, f1):
    """{frame: (chain, hbA)} over [f0, f1) by the WALKER'S OWN RULE: a chain BEGINS only where the node pointer
    lands on a chain's start node (the seq select); while it walks that chain's nodes it STAYS in it, so a node
    several chains share (Morrigan's jump-arc tail 0x179A0A sits inside a2:0x32-0x35, a:0x12 and two more —
    measured 14z-205) is labelled by the chain the pointer came from, not by whichever table claimed it first.
    A node outside the current chain that starts none falls back to the first claimant."""
    out, cur = {}, None
    for f in range(f0, f1):
        n = fr.get(f, {}).get("node")
        if n is None:
            continue
        n &= 0xFFFFFFFF
        hb = fm.get(n, (None, 0))[1]
        if n in STARTS:
            cur = STARTS[n]
        elif cur is None or n not in MEMBERS.get(cur, ()):
            cur = fm.get(n, (None, 0))[0]
        if cur:
            out[f] = (cur, hb)
    return out


def samples(trace):
    fr = {}
    for ln in Path(trace).read_text().splitlines():
        m = re.match(r"F (\d+) (.*)", ln)
        if m:
            kv = {}
            for part in m.group(2).split():
                if "=" in part:
                    k, v = part.split("=", 1)
                    try:
                        kv[k] = int(v)
                    except ValueError:
                        pass
            fr[int(m.group(1))] = kv
    return fr


def passes(fr, a, b):
    """ENGINE TICKS elapsed between the settled states of frames a and b (b > a): RAM:$FF8081, the game task's
    PASS counter (+1 per logic pass, +2 on a turbo double-pass frame — atlas/ram.md), mod 256. The page compares
    timing in engine ticks (docs/project/tables/community_crosscheck.md, the pursuits: "Frame data in ENGINE
    TICKS"); a video-frame count runs ~0.8 of the sheet on every long run at this speed level (measured 14z-205).
    Each boundary is read at frame resolution, so a node change inside a double-pass frame makes it +-1 tick."""
    pa, pb = fr.get(a, {}).get("pass"), fr.get(b, {}).get("pass")
    return None if pa is None or pb is None else (pb - pa) % 256


BASELINE = {f"a:{i:#04x}" for i in range(0x11)}
IDLE = {"a:0x00"}   # the rest chain between events, measured: 386 of 390 pre-event frames on Zabel, 270 of 270 on Morrigan
# the PLAIN-NORMAL slots: a2 0x00-0x1D (standing, close, crouching, both jump sets — tools/vanilla_join_rig.py's
# header and tests/expected/vanilla_normal_slots.tsv). Table a2 ALSO holds specials (Morrigan's Soul Fist enters
# a2:0x2e, measured 14z-205), so a special that enters a2 is not degraded; one that enters a normal slot is.
NORMAL_SLOTS = {f"a2:{i:#04x}" for i in range(0x1e)}


def analyse(trace, sched, img):
    cid = int(sched["char"], 16)
    fm, pm = node_maps(img, cid)
    fr = samples(trace)
    out = []
    for e in sched["events"]:
        t0, t1 = e["frame"], e["frame"] + e["gap"] - 20
        lab = labels(fr, fm, t0 - 40, t1 + 2)
        ch = lambda f: lab.get(f)
        rec = {"name": e["name"], "input": e["input"], "kind": e["kind"], "frame": t0, "press": e["press"], "gap": e["gap"],
               "p1x": fr.get(e["press"], {}).get("p1x"), "p2x": fr.get(e["press"], {}).get("p2x")}
        # THE WINDOW OPENS AT THE FIRST BUTTON TOKEN (14z-205): a special cannot start before its button, and the
        # chains the motion (or an air move's own jump) walks before it — Zabel's a:0x29 nine frames before his
        # 214K's button, the jump a:0x12 — are excluded, as tools/vanilla_join_rig.py's `before` set does.
        fb = e.get("first_button", e["press"])
        if os.environ.get("SPECIALS_WINDOW") == "event":   # the known-bad control `window-at-event`: the first pass's
            fb = t0                                        # window, which read Zabel's 214K as a:0x29 (the motion)
        before = BASELINE | {ch(f)[0] for f in range(t0 - 30, fb) if ch(f)}
        start = next((f for f in range(fb, t1) if ch(f) and ch(f)[0] not in before), None)
        if start is None:
            rec["entered"] = "UNFIRED"
        else:
            # THE MOVE ENDS AT THE RETURN TO IDLE (a:0x00, two frames running) or the window's end: a special may
            # pass through baseline chains on its way (Zabel's Death Hurricane lands through a:0x0f; a launch
            # through a jump chain), so stopping at the first baseline chain cut it short (the first pass).
            chains, f = [], start
            while f < t1 and not (ch(f) and ch(f)[0] in IDLE and ch(f + 1) and ch(f + 1)[0] in IDLE):
                c = ch(f)[0] if ch(f) else "?"
                if not chains or chains[-1][0] != c:
                    chains.append([c, 0])
                chains[-1][1] += 1
                f += 1
            stop = f
            act = [g for g in range(start, stop) if ch(g) and ch(g)[1]]
            spec = next((c for c, k in chains if c not in NORMAL_SLOTS and c not in BASELINE), None)
            # `special`: the first chain of the run that is neither a plain-normal slot nor baseline. A mash
            # special FOLLOWS the normal its first press plays (Q-Bee's SXP: a2:0x06 > a2:0x61 ...), so the row
            # is DEGRADED only when the run holds no such chain at all
            rec.update(entered=chains[0][0], special=spec, chains=chains, start_off=start - e["press"],
                       frames=stop - start, degraded=spec is None)
            if act:
                rec.update(startup=act[0] - start, active=len(act), span=act[-1] - act[0] + 1,
                           recovery=stop - act[-1] - 1)
                rec.update(startup_t=passes(fr, start, act[0]), active_t=passes(fr, act[0], act[-1] + 1),
                           recovery_t=passes(fr, act[-1] + 1, stop))
            rec["frames_t"] = passes(fr, start, stop)
            # THE DURATION BYTES ALONG THE OBSERVED PATH (the page's confirmed instrument for normals, section 1):
            # the distinct nodes P1 showed from the special's first frame, each gap between two consecutive
            # observations inside one chain filled with that chain's own nodes (a double-pass frame can walk a
            # 1-tick node unseen); startup_d = the durations before the first attack node, active_d = the
            # durations of the attack nodes up to the last one. Holds and game-logic exits are not in the bytes,
            # so recovery stays live (recovery_t).
            path, prev = [], None
            for g in range(start, stop):
                n = (fr.get(g, {}).get("node") or 0) & 0xFFFFFFFF
                if n == prev:
                    continue
                c = ch(g)[0] if ch(g) else None
                if path and c and path[-1][1] == c:
                    order = sorted(MEMBERS.get(c, ()))
                    order = CHAIN_ORDER.get(c, order)
                    if prev in order and n in order and order.index(n) > order.index(prev) + 1:
                        path += [(m, c) for m in order[order.index(prev) + 1:order.index(n)]]
                path.append((n, c))
                prev = n
            hbs = [fm.get(n, (None, 0))[1] for n, c in path]
            if any(hbs):
                i0 = hbs.index(next(h for h in hbs if h))
                i1 = len(hbs) - 1 - hbs[::-1].index(next(h for h in hbs[::-1] if h))
                rec["startup_d"] = sum(DUR.get(n, 0) for n, c in path[:i0])
                rec["active_d"] = sum(DUR.get(n, 0) for n, c in path[i0:i1 + 1] if fm.get(n, (None, 0))[1])
                rec["span_d"] = sum(DUR.get(n, 0) for n, c in path[i0:i1 + 1])
            # the FIRST idle frame too (not two running): a move can touch a:0x00 for one frame and leave it again
            # (Morrigan's Shadow Blade: a:0x0f > a:0x00(1) > a:0x0c(6)); both boundaries are reported
            first_idle = next((g for g in range(start, t1) if ch(g) and ch(g)[0] in IDLE), stop)
            rec["frames_first_idle_t"] = passes(fr, start, first_idle)
            if act:
                rec["recovery_first_idle_t"] = passes(fr, act[-1] + 1, first_idle)
        # projectiles: the first slot that comes alive after the event start
        alive0 = {n for n in range(NSLOT) if fr.get(t0 - 1, {}).get(f"s{n}")}
        pj = None
        for f in range(t0, t1):
            for n in range(NSLOT):
                if n not in alive0 and fr.get(f, {}).get(f"s{n}"):
                    pj = (n, f)
                    break
            if pj:
                break
        if pj:
            n, f0 = pj
            life = [g for g in range(f0, t1 + 200) if fr.get(g, {}).get(f"s{n}")]
            run = []
            for g in range(f0, t1 + 200):
                if not fr.get(g, {}).get(f"s{n}"):
                    break
                run.append(g)
            pact = [g for g in run if pm.get(fr[g].get(f"n{n}", 0) & 0xFFFFFFFF, (None, 0))[1]]
            pchains = []
            for g in run:
                c = pm.get(fr[g].get(f"n{n}", 0) & 0xFFFFFFFF, ("?", 0))[0]
                if not pchains or pchains[-1] != c:
                    pchains.append(c)
            rec["proj"] = {"slot": n, "type": fr[f0].get(f"t{n}"), "spawn_off": f0 - (start if start else e["press"]),
                           "life": len(run), "chains": pchains,
                           "first_active_off": (pact[0] - start) if (pact and start) else None, "active": len(pact)}
            if pact and start:
                rec["proj"].update(first_active_t=passes(fr, start, pact[0]), active_t=passes(fr, pact[0], pact[-1] + 1))
        # P2 HP drops and P1 meter (meaningful on the hit set)
        drops, prev = [], None
        for f in range(t0 - 10, t1):
            v = fr.get(f, {}).get("p2hp")
            if v is None:
                continue
            if prev is not None and v < prev and prev - v < 200:
                drops.append(prev - v)
            prev = v
        rec["hits"], rec["damage"] = len(drops), drops

        def tot(f):
            s = fr.get(f, {})
            return s["p1meter"] + 0x90 * s["p1stock"] if "p1meter" in s and "p1stock" in s else None
        a, b = tot(t0 - 1), tot(t1)
        rec["meter_gain"] = None if a is None or b is None else b - a
        out.append(rec)
    return out




# ------------------------------------------------------------------ the tick-accurate re-check (14z-205, follow-up)
PASS_PC = 0x008E14          # just past vsavj PRG:0x008E10 addq.b #1,$81(a5): one hit = one logic pass
P1_ENTRY, P1_TICK = 0x027EF0, 0x027F74     # just past PRG:0x027EEC (node entry) / 0x027F70 (one tick), engine_internals
PJ_ENTRY, PJ_TICK = 0x0545C6, 0x054574     # the projectile walker's (measured 14z-205: entry loads the duration, then
                                           # one decrement per tick, the next entry in the tick of the last one)


def read_tap(path):
    """The tap stream in order -> [(pass index, frame, pc, object, node)]: the pass index is the number of pass-counter
    hits seen before the hit (a pass's addq is at the top of the pass, so every hit inside pass k carries k)."""
    out, k = [], 0
    for l in Path(path).read_text().splitlines():
        p = l.split()
        if not p or p[0] != "T":
            continue
        pc, obj = int(p[2], 16), int(p[3], 16)
        # TICKS_CLOCK=p1 (the known-bad control `p1-clock`): P1's own tick-writes as the clock instead of the pass
        # counter — the reading measured wrong 14z-205 (the walker skips passes on holds: 4-10 per event on Morrigan)
        if (pc == PASS_PC) if os.environ.get("TICKS_CLOCK") != "p1" else (pc == P1_TICK and obj == 0xFF8400):
            k += 1
            if pc == PASS_PC:
                continue
        out.append((k, int(p[1]), pc, obj, int(p[4], 16)))
    return out, k


def ticks(tap, res, img, cid):
    """Per event (res = this leg's analyse() output): startup / active / recovery in EXACT ENGINE PASSES, from the
    ordered tap — never from a per-frame sample. A node VISIT is one entry hit; it lasts until the object's next entry
    hit (holds included: the walker skips decrements on holds, the pass counter does not). The special starts at P1's
    first entry inside its special chain at or after the frame the field samples saw it; idle = P1's first entry into
    a node of a:0x00 after the move's last attack visit. A projectile row: the first projectile object whose entries
    begin after the special's start, its nodes labelled through the character's proj table."""
    fm, pm = node_maps(img, cid)
    stream, npass = read_tap(tap)
    if npass == 0:
        raise SystemExit("ticks: the tap holds NO pass-counter hit — the clock is missing (TAP_PASS=0?)")
    idle_nodes = MEMBERS.get("a:0x00", set())
    out = []
    for r in res:
        row = {"name": r["name"]}
        if r["entered"] == "UNFIRED" or r.get("degraded"):
            out.append(row); continue
        spec = r.get("special") or r["entered"]
        f0 = r["press"] + r["start_off"]
        fend = r["frame"] + r["gap"]                       # the event's own window: never into the next event
        p1 = [(k, f, n) for k, f, pc, o, n in stream if o == 0xFF8400 and pc == P1_ENTRY and f0 - 2 <= f < fend]
        si = next((i for i, (k, f, n) in enumerate(p1) if n in MEMBERS.get(spec, ())), None)
        if si is None:
            row["error"] = "no P1 entry inside the special chain"; out.append(row); continue
        S = p1[si][0]
        vis = []
        for i in range(si, len(p1)):
            k, f, n = p1[i]
            if i > si and n in idle_nodes:   # the move ends at P1's entry into idle (a projectile row has no P1 attack)
                vis.append((k, None, 0, 0)); break
            nxt = p1[i + 1][0] if i + 1 < len(p1) else None
            vis.append((k, n, (nxt - k) if nxt is not None else None, fm.get(n, (None, 0))[1]))
        if vis and vis[-1][1] is None:
            row["total"] = vis[-1][0] - S             # the special's first entry to P1's entry into idle
        atk = [i for i, v in enumerate(vis) if v[3]]
        if atk:
            i0, i1 = atk[0], atk[-1]
            row.update(startup=vis[i0][0] - S, active=sum(vis[i][2] or 0 for i in range(i0, i1 + 1) if vis[i][3]),
                       span=(vis[i1][0] + (vis[i1][2] or 0)) - vis[i0][0],
                       recovery=(vis[-1][0] - (vis[i1][0] + (vis[i1][2] or 0))) if vis[-1][1] is None else None)
        # a projectile: the first object other than P1 whose entry hits begin after S, inside the event's window
        f1 = fend - 20
        objs = []
        for k, f, pc, o, n in stream:
            if o != 0xFF8400 and pc == PJ_ENTRY and k >= S and f <= f1 and o not in objs:
                objs.append(o)
        if objs:
            o = objs[0]
            pv = [(k, n) for k, f, pc, oo, n in stream if oo == o and pc == PJ_ENTRY and k >= S and f <= f1]
            lastk = max((k for k, f, pc, oo, n in stream if oo == o and pc in (PJ_ENTRY, PJ_TICK) and k >= S and f <= f1), default=None)
            seg = []
            for j, (k, n) in enumerate(pv):
                nxt = pv[j + 1][0] if j + 1 < len(pv) else (lastk + 1 if lastk is not None else None)
                if j and n == pv[0][1] and k > pv[j - 1][0] + 300:
                    break          # a later, unrelated life of the same slot
                seg.append((k, n, (nxt - k) if nxt is not None else None, pm.get(n, (None, 0))[1]))
            pa = [v for v in seg if v[3]]
            if pa:
                row["proj"] = {"object": f"{o:06x}", "startup": pa[0][0] - S, "active": sum(v[2] or 0 for v in pa),
                               "first_node": f"{pv[0][1]:06x}"}
        out.append(row)
    return out

# ------------------------------------------------------------------ the join (14z-205)
COLS = ("startup", "startup_d", "active", "active_d", "recovery", "recovery_first_idle", "red", "white", "gauge_whiff", "gauge_hit")


def _first_int(cell):
    m = re.match(r"\s*\[?(\d+)", str(cell or "").replace(".0", ""))
    return int(m.group(1)) if m else None


def join(legs_dir, image, sheet, gate=False):
    """Every workbook row of the family against what was measured. Per column, OURS is:
      startup / active / recovery — live, from the WHIFF leg: P1's own attack frames, or for a projectile row
        (P1's run carries no attack node) the projectile's: startup = frames from P1's first special frame to
        the projectile's first active frame, active = its active frames, recovery = P1's frames after that
        first active frame until idle. A row whose whiff event touched P2 (hits > 0) is CONTACT: a hit-freeze
        holds the attacker's node ([VSE-25]), so its frame data is reported and NOT classified;
      red / white — the first active ATTACK RECORD's real + white class and white class (the page's rule:
        the workbook quotes record values, its red = +8 plus +9), from the fighter's hitbox set for P1's boxes
        and from proj_hitbox_base for a projectile's (measured 14z-205: Morrigan's Soul Fist box 1 reads 11 + 6
        = 17 / 6 there, the sheet's 17 / 6; through the fighter set it read 4 + 3);
      gauge_whiff — P1's meter gain over the WHIFF event (none when it touched P2);
      gauge_hit — the sheet's `guage hit` minus its `gauge whiff` against the record's meter (+0x14): the page's
        rule for normals (2b: the hit cell = the swing's gain + the record's per landed hit).
    The sheet's cells are read by tools/crosscheck_framedata.py's grammar where a total is wanted; a cell that
    lists hits (`23,16`, `5xn`, `14x2`) is compared on its FIRST hit, as ours is the first record."""
    import crosscheck_framedata as cf
    import hitbox_records
    import xlsx_read
    img = Path(image).read_bytes()
    rows = vanilla_frames.bank_rows(Path(__file__).resolve().parent.parent / "build/manifest/bank_map.toml")
    wb = xlsx_read.Workbook(sheet)
    out = []
    for tab, cid in CHARS.items():
        H = hitbox_records.HitboxSet.from_image(img, vanilla_frames.row_ptr(img, rows["hitbox_base"], cid),
                                                vanilla_frames.row_ptr(img, rows["hitbox_comp"], cid))
        HP_ = hitbox_records.HitboxSet.from_image(img, vanilla_frames.row_ptr(img, rows["proj_hitbox_base"], cid),
                                                  vanilla_frames.row_ptr(img, rows["proj_hitbox_comp"], cid))
        fm, pm = node_maps(img, cid)
        if gate:   # the gate's KEEP layout: <legs>/<tab>/res.json (identity leg), id/t.txt, ticks.json (the tap)
            res = {r["name"]: r for r in json.loads((Path(legs_dir) / f"{tab}/res.json").read_text())}
            fr = samples(Path(legs_dir) / f"{tab}/id/t.txt")
            tk = {r["name"]: r for r in json.loads((Path(legs_dir) / f"{tab}/ticks.json").read_text())}
        else:
            res = {r["name"]: r for r in json.loads((Path(legs_dir) / f"{tab}_whiff/res.json").read_text())}
            fr = samples(Path(legs_dir) / f"{tab}_whiff/t.txt")
            tk = None
        sheetrows = {r["move"]: r for r in wb.rows(tab) if (r.get("type") or "").strip().lower() in FAMILY}
        for mv, sr in sheetrows.items():
            r = res.get(mv)
            row = {"tab": tab, "move": mv, "input": sr.get("input"), "type": sr.get("type")}
            if r is None:
                row["status"] = "NOT SCHEDULED"; out.append(row); continue
            if r.get("degraded") or r["entered"] == "UNFIRED":
                row["status"] = "UNFIRED" if r["entered"] == "UNFIRED" else "DEGRADED"; out.append(row); continue
            row.update(status="FIRED", chain=r.get("special") or r["entered"], contact=r["hits"] > 0)
            ours = {}
            pj = r.get("proj")
            # the first active record: P1's first active node, else the projectile's first active node
            start = r["press"] + r["start_off"]
            rec = None
            if r.get("special") and r["special"] != r["entered"]:
                # a MASH special follows the normal its first press plays (Q-Bee's SXP): its records and frame data
                # start at the special chain, not at the kick before it
                lab_ = labels(fr, fm, start, start + r["frames"])
                start = next(f for f in sorted(lab_) if lab_[f][0] == r["special"])
                act = [f for f in sorted(lab_) if f >= start and lab_[f][1]]
                stop = start + r["frames"] - (start - (r["press"] + r["start_off"]))
                r = dict(r, startup_t=passes(fr, start, act[0]), active_t=passes(fr, act[0], act[-1] + 1),
                         recovery_t=passes(fr, act[-1] + 1, stop)) if act else r
            if "startup" in r:
                for f in range(start, start + r["frames"]):
                    lab = fm.get(fr.get(f, {}).get("node", 0) & 0xFFFFFFFF)
                    if lab and lab[1]:
                        rec = ("fighter", lab[1], H.record(lab[1])); break
                ours.update(startup_d=r.get("startup_d"), active_d=r.get("active_d"))
                ours.update(startup=r.get("startup_t"), active=r.get("active_t"), recovery=r.get("recovery_t"),
                            recovery_first_idle=r.get("recovery_first_idle_t"))
            elif pj and pj.get("first_active_off") is not None:
                n = pj["slot"]
                for f in range(start, start + 400):
                    nd = fr.get(f, {}).get(f"n{n}")
                    lab = pm.get((nd or 0) & 0xFFFFFFFF)
                    if lab and lab[1]:
                        rec = ("proj", lab[1], HP_.record(lab[1])); break
                ours.update(startup=pj.get("first_active_t"), active=pj.get("active_t"),
                            recovery=(r["frames_t"] - pj["first_active_t"]) if pj.get("first_active_t") is not None else None,
                            recovery_first_idle=(r["frames_first_idle_t"] - pj["first_active_t"]) if pj.get("first_active_t") is not None else None)
            if rec:
                ours.update(red=rec[2]["real_class"] + rec[2]["white_class"], white=rec[2]["white_class"],
                            gauge_hit=rec[2]["meter"])
                row["record"] = f"{rec[0]}:{rec[1]}"
            if not r["hits"] and r.get("meter_gain") is not None:
                ours["gauge_whiff"] = r["meter_gain"]
            if tk is not None:
                # THE TICK-ACCURATE TIMING (the tap, exact passes): P1's own attack where it has one, else the
                # projectile's from the proj table, its recovery P1's total minus the projectile's startup
                k = tk.get(mv, {})
                for c in ("startup", "active", "recovery", "recovery_first_idle", "startup_d", "active_d"):
                    ours.pop(c, None)
                if "startup" in k:
                    ours.update(startup=k["startup"], active=k["active"], recovery=k.get("recovery"))
                elif k.get("proj"):
                    ours.update(startup=k["proj"]["startup"], active=k["proj"]["active"],
                                recovery=(k["total"] - k["proj"]["startup"]) if k.get("total") is not None else None)
                row["timing_from"] = "tap:p1" if "startup" in k else ("tap:proj" if k.get("proj") else "none")
            _rc = cf.num(cf._plain(sr.get("recovery"))) if sr.get("recovery") is not None else None
            sheet_v = {"startup": _first_int(sr.get("startup")), "active": cf.parse_runs(sr.get("active")),
                       "startup_d": _first_int(sr.get("startup")), "active_d": cf.parse_runs(sr.get("active")),
                       "recovery": _rc, "recovery_first_idle": _rc,
                       "red": _first_int(sr.get("red damage")), "white": _first_int(sr.get("white damage")),
                       "gauge_whiff": cf.num(cf._plain(sr.get("gauge whiff"))) if sr.get("gauge whiff") is not None else None}
            # THE HIT CELL'S GRAMMAR (14z-205): a cell that writes its terms (`18+6xn`, `21+3+3+3`) is the swing's
            # gain plus the per-hit term, so the per-hit value is the term after the first `+`; a single number is
            # the total, so the per-hit value is that number minus the whiff cell (the page's 2b rule for normals)
            ghc, gw = cf._plain(sr.get("guage hit") or ""), sheet_v["gauge_whiff"]
            m = re.match(r"(\d+)\+(\d+)", ghc)
            if m:
                sheet_v["gauge_hit"] = int(m.group(2))
            else:
                gh = _first_int(ghc)
                sheet_v["gauge_hit"] = (gh - gw) if (gh is not None and gw is not None) else None
            row["cols"] = {c: {"sheet_raw": str(sr.get({"startup": "startup", "startup_d": "startup", "active": "active", "active_d": "active", "recovery": "recovery", "recovery_first_idle": "recovery",
                                                          "red": "red damage", "white": "white damage",
                                                          "gauge_whiff": "gauge whiff", "gauge_hit": "guage hit"}[c])),
                               "sheet": sheet_v[c], "ours": ours.get(c)} for c in COLS}
            out.append(row)
    return out


def verdicts(rows):
    cols = [c for c in COLS if any(r.get("cols", {}).get(c, {}).get("ours") is not None for r in rows)]
    import crosscheck_framedata as cf
    lines = []
    for scope in ["ALL"] + list(CHARS):
        for c in cols:
            pairs, unc = [], 0
            for r in rows:
                if r.get("status") != "FIRED" or (scope != "ALL" and r["tab"] != scope):
                    continue
                if c in ("startup", "startup_d", "active", "active_d", "recovery", "recovery_first_idle") and r.get("contact"):
                    unc += 1; continue
                v = r["cols"][c]
                if v["sheet"] is None or v["ours"] is None:
                    unc += 1; continue
                pairs.append((r["move"], v["sheet"], v["ours"]))
            verdict, detail = cf.classify(pairs)
            lines.append(f"{scope}\t{c}\t{verdict}\t{detail}\tcompared {len(pairs)}\tuncomparable {unc}")
    return lines

def main():
    a = sys.argv[1:]
    if a and a[0] == "gen":
        return gen(a[1], a[2], a[3], a[4])
    if a and a[0] == "fields":
        return print(fields())
    if a and a[0] == "passeq":    # passeq <legs dir> <tab>...: the tap leg's pass clock against the identity leg's
        # THE INVARIANT (measured 14z-205, all 7 characters): the tap leg's pass counter equals the identity leg's on
        # every frame EXCEPT isolated frames where it reads exactly ONE pass behind — a stop landing as the screen frame
        # number moves gets that frame's sample read before its last pass's addq (LE 110, LI 44, MO 58, QB 0 such
        # frames, every one isolated, the next frame equal) — and both legs END equal; and the TAP STREAM holds exactly
        # as many pass hits from its arming frame to the end as the identity leg's counter steps over the same frames
        # (the stream is not sampled, so no skew reaches it). A divergence breaks one of these.
        out, bad, ok_ = [], 0, []
        for t in a[2:]:
            def pas(p):
                try:
                    return {int(l.split()[1]): int(re.search(r"pass=(\d+)", l).group(1)) for l in open(p) if l.startswith("F ")}
                except OSError:
                    return {}
            x, y = pas(f"{a[1]}/{t}/id/t.txt"), pas(f"{a[1]}/{t}/tap/t.txt")
            if not x or not y:
                bad = 1; out.append(f"{t}: a leg has no samples"); continue
            d = sorted(f for f in x if x[f] != y.get(f))
            wrong = [f for f in d if (y.get(f, -1) - x[f]) % 256 != 255 or f - 1 in d or f + 1 in d]
            last = max(x)
            armed = None
            hits = 0
            for l in open(f"{a[1]}/{t}/tap/tap.txt"):
                p_ = l.split()
                if p_ and p_[0] == "ARMED":
                    armed = int(p_[1])
                elif p_ and p_[0] == "T" and int(p_[2], 16) == PASS_PC:
                    hits += 1
            # THE BRACKET: a stop is tagged with the LAST COMPLETED frame (emu_clock's C.frame()), so the passes run during
            # frames armed+1..last are all in the stream — except those of the final frame whose stop comes after the run
            # exits (on_end): the stream holds at least the counter's steps through last-1 and at most its steps through
            # last (measured 14z-205: 3 legs one short of the second figure, 4 equal to it)
            lo = sum((x[f] - x[f - 1]) % 256 for f in range(armed + 1, last)) if armed else None
            steps = lo + (x[last] - x[last - 1]) % 256 if armed else None
            if wrong or x[last] != y.get(last) or not (lo is not None and lo <= hits <= steps):
                bad = 1
                out.append(f"{t}: {len(wrong)} non-skew differences (first {wrong[:3]}), end {x[last]}/{y.get(last)}, stream {hits} passes vs counter steps {lo}..{steps}")
            else:
                ok_.append(f"{t} {len(d)} skew frames, {hits} passes in {lo}..{steps}")
        print("; ".join(out) if bad else "the tap legs' pass clocks equal the identity legs' (skew frames only: one pass behind, isolated; equal at the end; every stream's pass count inside the counter's bracket): " + ", ".join(ok_))
        sys.exit(bad)
    if a and a[0] == "ticks":     # ticks <tap> <res.json> <image> <tab> <out.json>
        r = ticks(a[1], json.loads(Path(a[2]).read_text()), Path(a[3]).read_bytes(), CHARS[a[4]])
        Path(a[5]).write_text(json.dumps(r, indent=1) + "\n")
        for x in r:
            print(a[4], x)
        return
    if a and a[0] == "join":      # join <legs dir> <image> <sheet.xlsx> <out.json> <verdicts.tsv> [gate]
        rows = join(a[1], a[2], a[3], gate=len(a) > 6 and a[6] == "gate")
        Path(a[4]).write_text(json.dumps(rows, indent=1) + "\n")
        v = verdicts(rows)
        Path(a[5]).write_text("\n".join(v) + "\n")
        st = {}
        for r in rows:
            st[r["status"]] = st.get(r["status"], 0) + 1
        print("rows", len(rows), st)
        print("\n".join(l for l in v if l.startswith("ALL")))
        return
    ap = argparse.ArgumentParser()
    ap.add_argument("mode")
    ap.add_argument("trace", type=Path)
    ap.add_argument("sched", type=Path)
    ap.add_argument("image", type=Path)
    ap.add_argument("--json", type=Path)
    n = ap.parse_args()
    sched = json.loads(n.sched.read_text())
    res = analyse(n.trace, sched, n.image.read_bytes())
    if n.json:
        n.json.write_text(json.dumps(res, indent=1) + "\n")
    for r in res:
        pj = r.get("proj")
        ps = f" proj t{pj['type']} spawn+{pj['spawn_off']} act@{pj['first_active_off']} x{pj['active']} life{pj['life']}" if pj else ""
        tm = f" st{r['startup']} ac{r['active']} rc{r['recovery']}" if "startup" in r else ""
        cs = " > ".join(f"{c}({k})" for c, k in r.get("chains", []))
        print(f"{sched['tab']}\t{r['name']}\t{r['input']}\t{r.get('special') or r['entered']}{' DEGRADED' if r.get('degraded') else ''}"
              f"\t{cs}\t{tm.strip()}\t{ps.strip()}\thits {r['hits']} {'+'.join(map(str, r['damage']))}\tmeter {r['meter_gain']}"
              f"\tx {r['p1x']}/{r['p2x']}")


if __name__ == "__main__":
    main()
