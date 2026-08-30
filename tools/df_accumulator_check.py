#!/usr/bin/env python3
"""df_accumulator_check.py — the checker behind tests/audit_df_accumulator.sh.

  python3 tools/df_accumulator_check.py --legs DIR --render   # DIR/<leg>/field.txt -> frozen lines
  python3 tools/df_accumulator_check.py --selftest FIELD.txt  # ground-truth the classifier

Reads field_trace.lua output (F <frame> k=v ...). For the armor leg it
renders one line per CONTACT (a frame where p1_hp drops while df == 1):
the hp delta, +0x161 / +0x162 after the contact, whether +0x54 was written
(a reaction class) and whether seq changed within 12 frames — "react" — and
the running verdict: an armored contact must show acc = previous sum +
increment with decay 240 and no reaction; the contact whose sum passes 60
must react and clear. Then the arming and DF-end lines.

The classifier is ground-truth tested ([VSP-19]) by --selftest, which
perturbs a real armor trace so the third contact's accumulator reads 90
without clearing and asserts the deviation is reported.
"""
import argparse
import sys
from pathlib import Path

THRESHOLD = 60


def load(path):
    rows = {}
    for line in open(path, encoding="utf-8"):
        f = line.split()
        if len(f) < 3 or f[0] != "F":
            continue
        rows[int(f[1])] = {k: int(v) for k, v in (kv.split("=") for kv in f[2:])}
    return rows


def contacts(rows):
    frames = sorted(rows)
    out = []
    for i, fr in enumerate(frames[1:], 1):
        r, p = rows[fr], rows[frames[i - 1]]
        if r["p1_hp"] < p["p1_hp"] and r["df"] == 1:
            react = any(rows[g]["p1seq"] != p["p1seq"] for g in frames[i:i + 12])
            out.append({"frame": fr, "dhp": p["p1_hp"] - r["p1_hp"], "acc": r["p1_161"],
                        "decay": r["p1_162"], "cls": r["p1_54"], "react": react,
                        "acc_before": p["p1_161"]})
    return out


def analyse_armor(rows):
    lines, errs = [], []
    frames = sorted(rows)
    dfon = [f for f in frames if rows[f]["df"] == 1]
    if not dfon:
        return ["armor: DF never entered"], ["armor: DF never entered ($FF802E never 1)"]
    armed = [f for f in frames if rows[f]["p1_15e"] != 0]
    if not armed:
        return ["armor: +0x15E never armed"], ["armor: +0x15E never armed"]
    a0 = armed[0]
    lines.append(f"armor df_on {dfon[0]} armed {a0} 15e={rows[a0]['p1_15e']:#x} 18f={rows[a0]['p1_18f']}")
    if rows[a0]["p1_15e"] != 0x1FF or rows[a0]["p1_18f"] != 0:
        errs.append(f"armor: first armed sample {rows[a0]['p1_15e']:#x}/18f={rows[a0]['p1_18f']} (expected 0x1FF, 18f 0)")
    # monotone countdown while armed and in DF
    prev = None
    for f in frames:
        if f < a0 or rows[f]["df"] != 1:
            continue
        v = rows[f]["p1_15e"]
        if prev is not None and v > prev:
            errs.append(f"armor: +0x15E rose {prev}->{v} at {f} (re-armed mid-mode)"); break
        prev = v
    running = 0
    for c in contacts(rows):
        if c["frame"] < a0:
            continue
        if c["acc"] == 0 and c["decay"] == 0:
            kind = "BREAK" if c["react"] else "cleared-no-react"
            if not c["react"] or c["cls"] == 0:
                errs.append(f"armor: contact {c['frame']} cleared the sum without a reaction/class")
            if c["acc_before"] > THRESHOLD:
                errs.append(f"armor: sum {c['acc_before']} already past {THRESHOLD} before contact {c['frame']}")
            running = 0
        else:
            kind = "armored"
            inc = c["acc"] - running
            if c["react"] or c["cls"] != 0:
                errs.append(f"armor: contact {c['frame']} reacted while accumulating (acc {c['acc']})")
            # the reload is 240; a frame_done sample sees 239 when the timers
            # block ran after the contact inside the same frame (measured
            # 14z-123: one contact in five)
            if c["decay"] not in (239, 240):
                errs.append(f"armor: contact {c['frame']} decay {c['decay']} not the 240 reload")
            if c["acc"] > THRESHOLD:
                errs.append(f"armor: sum {c['acc']} past {THRESHOLD} at {c['frame']} without clearing")
            if inc <= 0:
                errs.append(f"armor: contact {c['frame']} added {inc}")
            running = c["acc"]
            kind = f"armored +{inc}"
        lines.append(f"armor contact {c['frame']} hp-{c['dhp']} acc={c['acc']} decay={c['decay']} cls={c['cls']} react={'yes' if c['react'] else 'no'} {kind}")
    dfoff = [f for f in frames if f > dfon[0] and rows[f]["df"] == 0]
    if dfoff:
        e = dfoff[0]
        lines.append(f"armor df_off {e} 15e={rows[e]['p1_15e']} acc={rows[e]['p1_161']} decay={rows[e]['p1_162']}")
        if rows[e]["p1_15e"] != 0 or rows[e]["p1_161"] != 0:
            errs.append(f"armor: DF end did not clear +0x15E/+0x161 at {e}")
    else:
        errs.append("armor: DF still active at the last sample — window too short")
    return lines, errs


def analyse_negative(name, rows, expect_df):
    lines, errs = [], []
    frames = sorted(rows)
    dfon = [f for f in frames if rows[f]["df"] == 1]
    if expect_df and not dfon:
        errs.append(f"{name}: DF never entered")
    if not expect_df and dfon:
        errs.append(f"{name}: DF entered without stocks — the downgrade did not happen")
    m15e = max(rows[f]["p1_15e"] for f in frames)
    m161 = max(rows[f]["p1_161"] for f in frames)
    cs = contacts(rows) if expect_df else [c for c in _all_contacts(rows)]
    reacted = sum(1 for c in cs if c["react"])
    lines.append(f"{name} df={'yes' if dfon else 'no'} 15e_max={m15e} acc_max={m161} contacts={len(cs)} reacted={reacted}")
    if m15e or m161:
        errs.append(f"{name}: armed/accumulated (15e {m15e}, acc {m161}) — expected none")
    if cs and reacted != len(cs):
        errs.append(f"{name}: {len(cs) - reacted} contacts did not react")
    return lines, errs


def _all_contacts(rows):
    frames = sorted(rows)
    out = []
    for i, fr in enumerate(frames[1:], 1):
        r, p = rows[fr], rows[frames[i - 1]]
        if r["p1_hp"] < p["p1_hp"] and 3300 <= fr <= 3650:
            react = any(rows[g]["p1seq"] != p["p1seq"] for g in frames[i:i + 12])
            out.append({"frame": fr, "react": react})
    return out


def render(legdir):
    lines, errs = [], []
    for name, fn in (("armor", analyse_armor),
                     ("hphk", lambda r: analyse_negative("hphk", r, True)),
                     ("nodf", lambda r: analyse_negative("nodf", r, False))):
        p = Path(legdir) / name / "field.txt"
        if not p.exists():
            errs.append(f"{name}: no field trace — dead leg"); continue
        rows = load(p)
        if not rows:
            errs.append(f"{name}: empty field trace — dead leg"); continue
        l, e = fn(rows)
        lines += l; errs += e
    return lines, errs


def selftest(field):
    rows = load(field)
    _, errs = analyse_armor(rows)
    if errs:
        print("selftest: the real trace must be clean first:", errs); return 1
    # perturb: at the BREAK contact, make the sum read 90 and stay (no clear)
    frames = sorted(rows)
    brk = [c for c in contacts(rows) if c["acc"] == 0 and c["decay"] == 0]
    if not brk:
        print("selftest: no break contact in the trace"); return 1
    f0 = brk[0]["frame"]
    for f in frames:
        if f >= f0:
            rows[f]["p1_161"] = 90; rows[f]["p1_162"] = 240
    _, errs = analyse_armor(rows)
    if not any("past 60" in e or "without clearing" in e for e in errs):
        print("selftest: a sum of 90 that never cleared was NOT reported:", errs); return 1
    print("  ok    selftest: a sum past 60 that does not clear is reported")
    return 0


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--legs"); ap.add_argument("--render", action="store_true")
    ap.add_argument("--selftest")
    a = ap.parse_args()
    if a.selftest:
        return selftest(a.selftest)
    lines, errs = render(a.legs)
    for l in lines:
        print(l)
    for e in errs:
        print("DEVIATION:", e)
    return 1 if errs else 0


if __name__ == "__main__":
    sys.exit(main())
