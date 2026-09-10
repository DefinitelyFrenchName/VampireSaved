#!/usr/bin/env python3
"""meter_gain.py — THE GAUGE COLUMN'S ARBITER (14z-146): what a vanilla normal
actually pays its attacker in METER, read off the engine on a CONNECT, against
our derivation (the record's +0x14 summed over the derived hit segments) and
the community workbook (its `guage hit` minus its `gauge whiff`).

THE INSTRUMENT IS THE STEP, NOT A WHIFF TWIN. P1's meter (+0x10A, the bar
fraction, 0x90 = one stock, plus +0x109 x 0x90) moves in discrete steps, and a
connecting event shows two kinds: the SWING COST on the press frame (0 / 3 / 6
by strength, before any hit) and one ON-HIT step per landed hit, on the frame
P2's HP drops. So one connect leg yields swing, hits and per-hit gain; a whiff
leg would only repeat the first step — and cannot even be produced for a move
that carries its attacker across the screen (Zabel's dive kicks connect at the
engine's 336 px separation clamp, whatever the rig pins).

  meter_gain.py <legs_dir> <vanilla.json> <vsavj_data.bin> [--sheet workbook.xlsx] [--cells]
    legs_dir holds <TAB>_<set>/t.txt and <TAB>_<set>.json per connecting leg
    (tools/vanilla_join_rig.py sets hit / hit_crouch / hit_jump / hit_jump_down).
Prints one ROW per (tab, set, button): swing, hits, the on-hit steps, net (their
sum), ours, segments; with --sheet the sheet's net and raw whiff; with --cells
only the CELLS table (the six deviating gauge cells and their controls) with a
VERDICT each — which side the ENGINE's net agrees with.
"""
import argparse, json, sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import vanilla_join_rig as R  # noqa: E402

SETS = {"hit": "5", "hit_crouch": "2", "hit_jump": "J.", "hit_jump_down": "J.2"}
# the six cells the page left unarbitrated, with a same-character EXACT cell as control
CELLS = [("SA", "hit", "HK"), ("SA", "hit", "MP"), ("SA", "hit_crouch", "HP"), ("BI", "hit_crouch", "HK"),
         ("FE", "hit", "MP"), ("ZA", "hit_jump_down", "HK"), ("ZA", "hit", "HK"), ("LE", "hit_jump", "HP"), ("LE", "hit", "HP")]


def steps(trace, sched):
    """Per event: the meter steps (frame offset, amount, P2 HP drop that frame) inside
    the event's window, from the last quiet frame to the window's end."""
    fr = R._samples(trace)
    out = {}
    for e in sched["events"]:
        t0, t1 = e["frame"], e["frame"] + e["gap"] - 70
        prev_m = prev_hp = None
        st = []
        for f in range(t0 - 2, t1):
            s = fr.get(f)
            if not s or "p1meter" not in s:
                continue
            m = s["p1meter"] + 0x90 * s["p1stock"]
            hp = s.get("p2hp")
            drop = prev_hp is not None and hp is not None and 0 < prev_hp - hp < 200
            if prev_m is not None and m != prev_m:
                st.append((f - t0, m - prev_m, drop))
            prev_m, prev_hp = m, hp
        out[e["name"]] = st
    return out


def derived(vanilla, tab, chain):
    """The per-hit meter of the chain the trace ENTERED (its `a2:0xNN` key) — never of
    the move NAME: at contact range a character enters its CL. variant where it has
    one (LE's near 5HP is a single 18-meter record, its far 5HP three of 6)."""
    c = vanilla["characters"][tab]["chains"].get(chain)
    if not c or "frame_data" not in c:
        return None, None, None, None, None
    d = c.get("damage_per_hit") or {}
    per = d["gauge_hit"] if d.get("gauge_hit") else [(c.get("damage") or {}).get("gauge_hit")]
    return sum(per), len(per), c["frame_data"]["notation"], per, c.get("move", chain)


def sheet_cells(sheet_path, vanilla):
    import crosscheck_framedata as C, xlsx_read
    cmp_ = C.compare(vanilla, sheet_path)
    net = {}
    for tab, ch in cmp_["characters"].items():
        for r in ch["columns"]["gauge_hit"]["rows"]:
            net[(tab, r["move"])] = r["sheet"]
    raw = {}
    wb = xlsx_read.Workbook(sheet_path)
    for tab in vanilla["characters"]:
        if tab not in wb.sheet_names:
            continue
        for r in wb.rows(tab):
            inp = str(r.get("input", "")).strip().upper().replace(" ", "")
            w = next((r[h] for h in C.GAUGE_WHIFF if r.get(h) not in (None, "")), None)
            h = next((r[h] for h in ("guage hit", "gauge hit") if r.get(h) not in (None, "")), None)
            raw[(tab, inp)] = (C.parse_total(w) if w is not None else None, str(h))
    return net, raw


def rows(legs, vanilla, img, sheet=None):
    net_sheet, raw_sheet = sheet_cells(sheet, vanilla) if sheet else ({}, {})
    out = []
    for f in sorted(legs.glob("*_*.json")):
        tab, st = f.stem.split("_", 1)
        if st not in SETS:
            continue
        sched = json.load(open(f))
        trace = legs / f.stem / "t.txt"
        ev = steps(trace, sched)
        entered = {r["button"]: r["entered"] for r in R.analyse(trace, sched, img, int(sched["char"], 16))}
        for btn in R.BUTTONS:
            mv = SETS[st] + btn
            s = ev.get(btn, [])
            on_hit = [a for _, a, d in s if d]
            swing = [a for _, a, d in s if not d]
            ours, segs, notation, per, chain_move = derived(vanilla, tab, entered.get(btn, ""))
            row = {"tab": tab, "set": st, "button": btn, "move": mv, "chain": entered.get(btn, "UNFIRED"),
                   "chain_move": chain_move,
                   "swing": swing[0] if len(swing) == 1 else (0 if not swing else None),
                   "stray_steps": len(swing) - 1 if len(swing) > 1 else 0,
                   "hits": len(on_hit), "on_hit": "+".join(map(str, on_hit)) or "-", "net": sum(on_hit),
                   "ours": ours, "segments": segs, "per_hit": per[0] if per and len(set(per)) == 1 else None,
                   "notation": notation,
                   "sheet_net": net_sheet.get((tab, mv)), "sheet_whiff": raw_sheet.get((tab, mv), (None, None))[0],
                   "sheet_hit_raw": raw_sheet.get((tab, mv), (None, None))[1]}
            out.append(row)
    return out


def verdict(r):
    """Which side the ENGINE agrees with on the net on-hit gain. VOID when the leg
    landed nothing (a leg with no event is neither pass nor fail, [VSP-170])."""
    if r["hits"] == 0:
        return "VOID"
    e, o, s = r["net"], r["ours"], r["sheet_net"]
    if o is None:
        return "NO-DERIVATION"
    a, b = e == o, (s is not None and e == s)
    return "BOTH" if a and b else "OURS" if a else "SHEET" if b else "NEITHER"


COLS = ("tab", "set", "button", "move", "chain", "chain_move", "swing", "stray_steps", "hits", "on_hit", "net", "ours",
        "segments", "per_hit", "sheet_net", "sheet_whiff")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("legs", type=Path)
    ap.add_argument("vanilla", type=Path)
    ap.add_argument("image", type=Path, help="the vsavj DATA view (node -> chain)")
    ap.add_argument("--sheet", type=Path)
    ap.add_argument("--cells", action="store_true")
    n = ap.parse_args()
    vanilla = json.loads(n.vanilla.read_text())
    rs = rows(n.legs, vanilla, n.image.read_bytes(), n.sheet)
    if n.cells:
        print("tab\tmove\tchain\tnotation\tswing\thits\ton_hit\tnet\tours(segs)\tsheet_net\tsheet_whiff\tverdict")
        for tab, st, btn in CELLS:
            r = next((x for x in rs if x["tab"] == tab and x["set"] == st and x["button"] == btn), None)
            if r is None:
                print(f"{tab}\t{SETS[st] + btn}\t-\tMISSING LEG"); continue
            print(f"{tab}\t{r['move']}\t{r['chain']}={r['chain_move']}\t{r['notation']}\t{r['swing']}\t{r['hits']}\t{r['on_hit']}\t{r['net']}"
                  f"\t{r['ours']}({r['segments']})\t{r['sheet_net']}\t{r['sheet_whiff']}\t{verdict(r)}")
        return
    print("\t".join(COLS) + "\tverdict")
    for r in rs:
        print("\t".join(str(r[k]) for k in COLS) + f"\t{verdict(r)}")


if __name__ == "__main__":
    main()
