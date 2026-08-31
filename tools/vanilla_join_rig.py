#!/usr/bin/env python3
"""vanilla_join_rig.py — THE EMULATOR ARBITRATES THE JOIN (14z-125).

  python3 tools/vanilla_join_rig.py gen     <char_id> <near|far> <out.rpl> <out.json>
  python3 tools/vanilla_join_rig.py analyse <trace.txt> <sched.json> <image.bin> <char_id>

WHAT IT SETTLES, and what it OVERTURNED. Table a2's standing-normal slots were
first modelled as a fixed EVEN/ODD pair (even = the CLOSE proximity normal, odd
= the FAR one), inferred by fitting our derivation against the community
workbook. A fit against the very source being checked is CIRCULAR and cannot be
evidence, so this rig performs each standing normal on vanilla vsavj at two
measured distances and reads back WHICH CHAIN THE ENGINE ENTERS, from the
game's own anim node pointer (`+0x1C`).

**The fixed model was WRONG, and the measurement is what says so.** The layout
is PER CHARACTER and per BUTTON (`tests/expected/vanilla_normal_slots.tsv`,
all 15 measured):
  * AN, BI, JE, QB, ZA enter the SAME chain at both distances on every button —
    they have no proximity variants at all, and their standing normals are
    0x00/02/04/06/08/0a. Zabel was the whole reason: the fixed model gave him
    the odd slots, which are his `6`-prefixed COMMAND normals, and he came out
    INCONSISTENT on every column.
  * DE, MO, FE, SA, LE, LI take odd at far and even at near for MP..HK, but
    their LP is 0x01 at BOTH distances.
  * GA and VI are the same except LP is 0x00.
  * BU and AU additionally have no close variant for HP (and BU none for MK).
So slot 0x00 vs 0x01 for LP is character-dependent, and "even = close" is a
tendency, not a law. Nothing downstream may assume it.

A scripted input is not the move it names ([VSE-47]), so nothing here trusts
its own script: the verdict is the chain the fighter entered inside the event
window, mapped onto the graph `tools/anim_nodes.py` decodes, and a window with
no new chain is reported UNFIRED, never guessed.

TRAPS ALREADY PAID FOR, inherited from tools/name_moves.py rather than
rediscovered: a NEAR distance cannot be poked — poking the pair overlapped the
pushboxes and the engine resolved it by CROSSING the fighters, leaving P1
facing left for whole parts (14z-120 (2)) — so `near` is the far pin plus a
150-frame walk-in; `$FF8109` is a BINARY timer and must never be poked (a 0x99
poke ended the round); and each part is kept under one round.
"""
import argparse
import json
import re
import struct
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import anim_nodes  # noqa: E402
import name_moves  # noqa: E402
import vanilla_frames  # noqa: E402

BUTTONS = ["LP", "MP", "HP", "LK", "MK", "HK"]
# an EVENT SET is (recipe maker, gap, does it need the walk-in). `far`/`near` are the
# standing pair the join was settled with; `crouch` and `jump` extend the same
# measurement to the other twelve normal slots (14z-125b), and `hit` puts P2 inside
# range so the DEALT damage can be read off its HP instead of inferred from a record.
SETS = {"far":    ("stand",  300, False),
        "near":   ("stand",  480, True),
        "crouch": ("crouch", 300, False),
        "jump":   ("jump",   360, False),
        "hit":    ("stand",  480, True)}
GAP = {k: v[1] for k, v in SETS.items()}


def _recipe(kind, b):
    return {"stand": name_moves.stand, "crouch": name_moves.crouch, "jump": name_moves.jump}[kind](b)


def gen(cid, dist, out_rpl, out_sched):
    lines = [f"# vanilla join rig — char {cid:#04x}, {dist} distance",
             "# (tools/vanilla_join_rig.py gen; DO NOT hand-edit, regenerate).",
             "# Select prologue from replay 17 (the character is FORCED by the",
             "# early-window poke, so the cursor path does not matter).",
             name_moves.PROLOGUE.rstrip()]
    kind, gap, walkin = SETS[dist]
    x1, x2 = name_moves.PIN["far"]
    t = name_moves.FIRST_EVENT
    sched = {"char": f"{cid:#04x}", "distance": dist, "kind": kind, "events": [], "pokes": []}
    pins = []
    for b in BUTTONS:
        if walkin:
            pins += [f"{t - 230}:ff8410:{x1:04x}", f"{t - 230}:ff8810:{x2:04x}"]
            lines.append(f"{t - 190}-{t - 40} p1=R")      # walk in; never poke a near pair
        else:
            pins += [f"{t - 40}:ff8410:{x1:04x}", f"{t - 40}:ff8810:{x2:04x}"]
        for a, bb, tok in _recipe(kind, b):
            lines.append(f"{t + a}-{t + bb} p1={tok}")
        sched["events"].append({"name": b, "frame": t, "gap": gap})
        t += gap
    end = t + 200
    lines.append(f"{end} wait")
    assert end - name_moves.FIRST_EVENT < 7500, "a part must fit inside one round"
    pokes = [f"{f}:ff8782:{cid:02x}" for f in (1400, 1450, 1500)]
    pokes += [f"{f}:ff8b82:03" for f in (1400, 1450, 1500)]      # P2 = Victor, idle
    if dist == "hit":
        # re-pin P2's HP just BEFORE each event, never during one: the whole point is to
        # read the drop the move causes ([VSP-125]'s pin, moved off the event windows)
        pokes += [f"{e['frame'] - 20}:ff8850:01200120" for e in sched["events"]]
    else:
        pokes += [f"{f}:ff8850:01200120" for f in range(name_moves.FIRST_EVENT - 50, end, name_moves.HP_PIN_EVERY)]
    pokes += pins
    sched["pokes"] = pokes
    sched["frames"] = end + 50
    Path(out_rpl).write_text("\n".join(lines) + "\n")
    Path(out_sched).write_text(json.dumps(sched, indent=1) + "\n")
    print(f"wrote {out_rpl} ({len(BUTTONS)} events, {dist}, ends {end}) and {out_sched}")


def node_map(img, cid, detail=False):
    """{node address: 'table:seq'}, or with detail {addr: (chain, index, hbA, dur)}."""
    rows = vanilla_frames.bank_rows(Path(__file__).resolve().parent.parent / "build/manifest/bank_map.toml")
    out = {}
    for tn in ("a", "a2"):
        tbl = vanilla_frames.row_ptr(img, rows["anim_index_" + tn], cid)
        w = anim_nodes.walk_table(img, 0, tbl, len(img))
        for seq, c in w["chains"].items():
            for i, n in enumerate(c.get("nodes") or []):
                a = int(n["addr"], 16)
                if a not in out:
                    out[a] = (f"{tn}:{seq}", i, n["hbA"] >> 8, n["dur"]) if detail else f"{tn}:{seq}"
    return out


def _samples(trace):
    """{frame: {name: int}} from a field_trace log."""
    frames = {}
    for ln in Path(trace).read_text().splitlines():
        m = re.match(r"F (\d+) (.*)", ln)
        if not m:
            continue
        kv = {}
        for part in m.group(2).split():
            if "=" in part:
                k, v = part.split("=", 1)
                try:
                    kv[k] = int(v)
                except ValueError:
                    pass
        frames[int(m.group(1))] = kv
    return frames


def durations(trace, sched, img, cid, window=200):
    """MEASURE startup / active / recovery live, instead of deriving them from the
    node duration bytes. For each event: the frames the fighter actually spent on
    each node of the chain it entered, split at the ATTACK nodes (hbA != 0).

    This is the arbitration the maintainer's rule asks for — a data duration is a
    HYPOTHESIS about how long a node runs, and the engine can hold one ([VSE-25]:
    a hit-freeze holds the node timer via +0x5C). The rig whiffs on purpose so no
    freeze is in play; the `hit` set is where damage is read instead."""
    nm = node_map(img, cid, detail=True)
    fr = _samples(trace)
    out = []
    for e in sched["events"]:
        t0 = e["frame"]
        before = {nm.get(fr[f].get("node"), (None,))[0] for f in range(t0 - 30, t0) if f in fr}
        chain = None
        run = []          # [(chain, idx, hbA, frame)]
        for f in range(t0, t0 + window):
            d = nm.get(fr.get(f, {}).get("node"))
            if d is None:
                continue
            if chain is None:
                if d[0] in before:
                    continue
                chain = d[0]
            if d[0] != chain:
                break
            run.append(d)
        if chain is None:
            out.append({"button": e["name"], "chain": "UNFIRED"})
            continue
        atk = [i for i, d in enumerate(run) if d[2]]
        rec = {"button": e["name"], "chain": chain, "frames": len(run)}
        if atk:
            rec.update(startup=atk[0], active=sum(1 for d in run if d[2]),
                       span=atk[-1] - atk[0] + 1, recovery=len(run) - atk[-1] - 1,
                       records=sorted({d[2] for d in run if d[2]}))
        out.append(rec)
    return out


def damage(trace, sched, window=200):
    """Every DROP in P2's HP inside each event window: the dealt damage and the hit
    count, read off the game rather than inferred from the attack record's raw +8
    power (which the [VSE-40] scaler chain sits between)."""
    fr = _samples(trace)
    out = []
    for e in sched["events"]:
        t0 = e["frame"]
        hp = [(f, fr[f]["p2hp"]) for f in range(t0 - 10, t0 + window) if f in fr and "p2hp" in fr[f]]
        drops, prev = [], None
        for f, v in hp:
            if prev is not None and v < prev and prev - v < 200:
                drops.append(prev - v)
            prev = v
        out.append({"button": e["name"], "hits": len(drops), "damage": drops, "total": sum(drops)})
    return out


def analyse(trace, sched, img, cid, window=90):
    nm = node_map(img, cid)
    frames = {}
    for ln in Path(trace).read_text().splitlines():
        m = re.match(r"F (\d+) (.*)", ln)
        if not m:
            continue
        f = int(m.group(1))
        kv = dict(p.split("=", 1) for p in m.group(2).split() if "=" in p)
        if "node" in kv:
            frames[f] = int(kv["node"]) & 0xFFFFFFFF
    out = []
    for e in sched["events"]:
        t0 = e["frame"]
        before = {nm.get(frames[f]) for f in range(t0 - 30, t0) if f in frames}
        seen, first = [], None
        for f in range(t0, t0 + window):
            c = nm.get(frames.get(f))
            if c and c not in before and c not in seen:
                seen.append(c)
                if first is None:
                    first = c
        out.append({"button": e["name"], "frame": t0, "entered": first or "UNFIRED", "all": seen})
    return out


def main():
    a = sys.argv[1:]
    if a and a[0] == "gen":
        gen(int(a[1], 0), a[2], a[3], a[4])
        return
    ap = argparse.ArgumentParser()
    ap.add_argument("mode")
    ap.add_argument("trace", type=Path)
    ap.add_argument("sched", type=Path)
    ap.add_argument("image", type=Path)
    ap.add_argument("char")
    ap.add_argument("--window", type=int, default=90)
    ap.add_argument("--tab", default="", help="sheet tab, for --tsv rows")
    ap.add_argument("--tsv", action="store_true", help="one machine row per event")
    ap.add_argument("--durations", action="store_true", help="MEASURED startup/active/recovery per event")
    ap.add_argument("--damage", action="store_true", help="P2 HP drops per event (the `hit` set)")
    n = ap.parse_args()
    sched = json.loads(n.sched.read_text())
    if n.durations:
        for r in durations(n.trace, sched, n.image.read_bytes(), int(n.char, 0)):
            if "startup" in r:
                print(f"{n.tab or sched['char']}\t{sched['distance']}\t{r['button']}\t{r['chain']}"
                      f"\t{r['startup']}\t{r['active']}\t{r['recovery']}\t{r['frames']}")
            else:
                print(f"{n.tab or sched['char']}\t{sched['distance']}\t{r['button']}\t{r.get('chain','UNFIRED')}\t-\t-\t-\t-")
        return
    if n.damage:
        for r in damage(n.trace, sched):
            print(f"{n.tab or sched['char']}\t{sched['distance']}\t{r['button']}\t{r['hits']}\t{r['total']}\t{'+'.join(map(str, r['damage']))}")
        return
    res = analyse(n.trace, sched, n.image.read_bytes(), int(n.char, 0), n.window)
    for r in res:
        if n.tsv:
            print(f"{n.tab or sched['char']}\t{sched['distance']}\t{r['button']}\t{r['entered']}")
        else:
            extra = (" then " + " ".join(r["all"][1:])) if len(r["all"]) > 1 else ""
            print(f"{sched['distance']:5} {r['button']:3} f{r['frame']:<5} -> {r['entered']}{extra}")


if __name__ == "__main__":
    main()
