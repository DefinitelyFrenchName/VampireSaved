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
GAP = {"far": 300, "near": 480}


def gen(cid, dist, out_rpl, out_sched):
    lines = [f"# vanilla join rig — char {cid:#04x}, {dist} distance",
             "# (tools/vanilla_join_rig.py gen; DO NOT hand-edit, regenerate).",
             "# Select prologue from replay 17 (the character is FORCED by the",
             "# early-window poke, so the cursor path does not matter).",
             name_moves.PROLOGUE.rstrip()]
    x1, x2 = name_moves.PIN["far"]
    t, gap = name_moves.FIRST_EVENT, GAP[dist]
    sched = {"char": f"{cid:#04x}", "distance": dist, "events": [], "pokes": []}
    pins = []
    for b in BUTTONS:
        if dist == "near":
            pins += [f"{t - 230}:ff8410:{x1:04x}", f"{t - 230}:ff8810:{x2:04x}"]
            lines.append(f"{t - 190}-{t - 40} p1=R")      # walk in; never poke a near pair
        else:
            pins += [f"{t - 40}:ff8410:{x1:04x}", f"{t - 40}:ff8810:{x2:04x}"]
        lines.append(f"{t}-{t + 2} p1={name_moves.B[b]}")
        sched["events"].append({"name": b, "frame": t, "gap": gap})
        t += gap
    end = t + 200
    lines.append(f"{end} wait")
    assert end - name_moves.FIRST_EVENT < 7500, "a part must fit inside one round"
    pokes = [f"{f}:ff8782:{cid:02x}" for f in (1400, 1450, 1500)]
    pokes += [f"{f}:ff8b82:03" for f in (1400, 1450, 1500)]      # P2 = Victor, idle
    pokes += [f"{f}:ff8850:01200120" for f in range(name_moves.FIRST_EVENT - 50, end, name_moves.HP_PIN_EVERY)]
    pokes += pins
    sched["pokes"] = pokes
    sched["frames"] = end + 50
    Path(out_rpl).write_text("\n".join(lines) + "\n")
    Path(out_sched).write_text(json.dumps(sched, indent=1) + "\n")
    print(f"wrote {out_rpl} ({len(BUTTONS)} events, {dist}, ends {end}) and {out_sched}")


def node_map(img, cid):
    """{node address: 'table:seq'} for the character's a and a2 chains."""
    rows = vanilla_frames.bank_rows(Path(__file__).resolve().parent.parent / "build/manifest/bank_map.toml")
    out = {}
    for tn in ("a", "a2"):
        tbl = vanilla_frames.row_ptr(img, rows["anim_index_" + tn], cid)
        w = anim_nodes.walk_table(img, 0, tbl, len(img))
        for seq, c in w["chains"].items():
            for n in c.get("nodes") or []:
                out.setdefault(int(n["addr"], 16), f"{tn}:{seq}")
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
    n = ap.parse_args()
    sched = json.loads(n.sched.read_text())
    res = analyse(n.trace, sched, n.image.read_bytes(), int(n.char, 0), n.window)
    for r in res:
        if n.tsv:
            print(f"{n.tab or sched['char']}\t{sched['distance']}\t{r['button']}\t{r['entered']}")
        else:
            extra = (" then " + " ".join(r["all"][1:])) if len(r["all"]) > 1 else ""
            print(f"{sched['distance']:5} {r['button']:3} f{r['frame']:<5} -> {r['entered']}{extra}")


if __name__ == "__main__":
    main()
