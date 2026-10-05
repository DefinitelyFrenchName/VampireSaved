#!/usr/bin/env python3
"""air_dash_rigs.py — PHOBOS'S AIR DASH AT LOW HEIGHT, ours against native vs2 (GitHub #222, 14z-191).

vs2's air-dash check (vs2 PRG:0x0214E4, mask $28112810) sends character id 0x10 (Phobos) through the minimum-height
routine (vs2 0x026DD2, table row 0x10 = 24): above the row, with the dash latch +0x113|+0x114 set, it enters seq 0x14
(the air dash, `move.l #$02001400,4(a6)`); below it, no dash. Ours runs vsavj's check (PRG:0x022AF2, mask $28102810,
no bit 0x10) and vsavj's table (row 0x10 = 0), so Phobos dashes at any height (docs/game/engine_internals.md, the
MINIMUM AIR-DASH HEIGHT paragraph). This rig makes that a measurement in play.

The rig, on tools/name_moves.py's machinery (outside the naming corpus, like pursuit_rigs.py; name_moves.py is not
edited — the schedule is installed into name_moves.SCHEDULES at run time): Phobos jumps straight up (U at +0..1) and
inputs the air dash j.66 — R at +(k-3), R at +k (the naming rigs' Air Dash input) — one event per k in KS.

  python3 tools/air_dash_rigs.py gen <out dir>                        write h222.rpl + h222.json
  python3 tools/air_dash_rigs.py rows <h222.json> <trace>              one row per event (k, height, the dash)
  python3 tools/air_dash_rigs.py compare <h222.json> <native> <ours> --expect gap|same [--plant-native-dash]

A row: k, P1's height (+0x14 - +0x3A) at the second R, and whether and from which frame P1 is in seq 0x14 within 60
frames. `--expect gap` (today's build): on the LOW event (k=5, height under vs2's 24) native does NOT dash and ours
DOES; on every other event both dash on the same frame at the same height. `--expect same` (a build that takes vs2's
row): every row equal. Refused (VOID, never a pass): a leg whose height at the low event is not under 24, or whose
HIGH events did not dash on native — the rig did not produce the event. `--plant-native-dash` gives native a dash at
the low event (the gate's must-fire control: the gap must then fail)."""
import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import name_moves as nm  # noqa: E402

KS = (5, 6, 7, 8, 9, 10, 12, 16)
LOW = 5                  # the one event whose second R lands under vs2's row (height 21, measured 14z-191)
ROW = 24                 # vs2's table row 0x10 (0x0018) — tests/test_air_attack_height.sh reads vsavj's twin table
EVENTS = [(f"jump U, air dash 66 completed at +{k}", [(0, 1, "U"), (k - 3, k - 3, "R"), (k, k, "R")], 150) for k in KS]
FIELDS = "ff8414:w:y,ff843a:w:floor,ff8438:b:air,ff8406:b:seq,ff8407:b:sub,ff8782:b:id,ff8513:b:b113,ff8514:b:b114"


def gen(out):
    out = Path(out); out.mkdir(parents=True, exist_ok=True)
    nm.SCHEDULES["huitzil"]["h222"] = EVENTS
    nm.gen("huitzil", "h222", str(out / "h222.rpl"), str(out / "h222.json"))


def load(p):
    R, done = {}, False
    for line in open(p):
        if line.startswith("F "):
            f = line.split()
            R[int(f[1])] = dict(kv.split("=", 1) for kv in f[2:])
        elif "FIELDSUMMARY" in line:
            done = True
    if not done:
        raise SystemExit(f"FAIL: {p}: no FIELDSUMMARY — the trace did not complete")
    return R


def rows(js, trace, plant_dash=False):
    j = json.load(open(js)); R = load(trace); out = []
    for k, e in zip(KS, j["events"]):
        f0 = e["frame"]; fp = f0 + k
        def h(f):
            r = R.get(f)
            return None if r is None else int(r["y"]) - int(r["floor"])
        dash = [f for f in range(f0, f0 + 60) if R.get(f, {}).get("seq") == "20"]
        if plant_dash and k == LOW and not dash:
            dash = [fp]
        d0 = dash[0] if dash else None
        out.append({"k": k, "id": R.get(fp, {}).get("id"), "air": R.get(fp, {}).get("air"), "h": h(fp),
                    "dash": None if d0 is None else d0 - f0, "dash_h": None if d0 is None else h(d0)})
    return out


def fmt(r):
    d = "no dash" if r["dash"] is None else f"dash from +{r['dash']} at height {r['dash_h']}"
    return f"k={r['k']:2d} id {r['id']} air {r['air']} height at the 2nd R {r['h']} | {d}"


def compare(js, nat, ours, expect, plant=False):
    a, b = rows(js, nat, plant), rows(js, ours)
    bad = []
    for x, y in zip(a, b):
        print(f"  native {fmt(x)}\n  ours   {fmt(y)}")
        for side, r in (("native", x), ("ours", y)):
            if r["id"] != "16" or r["air"] != "1":
                raise SystemExit(f"VOID: {side} k={r['k']}: P1 is not an airborne Phobos at the 2nd R (id {r['id']}, air {r['air']})")
        if x["k"] == LOW:
            if x["h"] is None or x["h"] >= ROW or y["h"] is None or y["h"] >= ROW:
                raise SystemExit(f"VOID: the low event's height is not under {ROW} (native {x['h']}, ours {y['h']}) — the rig moved")
            if expect == "gap" and not (x["dash"] is None and y["dash"] is not None):
                bad.append(f"k={LOW}: expected native no dash and ours a dash, got native {x['dash']} ours {y['dash']}")
            if expect == "same" and x != y:
                bad.append(f"k={LOW}: native and ours differ")
        else:
            if x["dash"] is None:
                raise SystemExit(f"VOID: native k={x['k']} did not dash at height {x['h']} — the rig did not produce the event")
            if x != y:
                bad.append(f"k={x['k']}: native and ours differ above the row")
    for m in bad:
        print(f"  MISMATCH {m}")
    print(("PASS" if not bad else "FAIL") + f": --expect {expect}, {len(a)} events")
    return 0 if not bad else 1


def main(a):
    if a[:1] == ["gen"] and len(a) == 2:
        gen(a[1]); return 0
    if a[:1] == ["rows"] and len(a) == 3:
        for r in rows(a[1], a[2]):
            print(fmt(r))
        return 0
    if a[:1] == ["compare"] and len(a) >= 6 and a[4] == "--expect" and a[5] in ("gap", "same"):
        return compare(a[1], a[2], a[3], a[5], "--plant-native-dash" in a[6:])
    print(__doc__); return 2


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
