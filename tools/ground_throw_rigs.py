#!/usr/bin/env python3
"""ground_throw_rigs.py — the vsavj GROUND THROWS for the community cross-check (GitHub #229, 14z-195).

  python3 tools/ground_throw_rigs.py gen <out dir>                      one rig per vanilla character (.rpl + .json)
  python3 tools/ground_throw_rigs.py rows <rig.json> <rig legs dir> <vsavj_data.bin> [<+off>:<a3 hex>]
                                                                       one row per event (JSON lines); the legs dir
                                                                       holds 0189ea/ and 02979a/, each with run.log + dumps
  python3 tools/ground_throw_rigs.py dumps <rig.json>                   the DUMPS= spec BOTH applier legs run with
  python3 tools/ground_throw_rigs.py freeze <rows.jsonl>                the frozen signature, one line per event
  python3 tools/ground_throw_rigs.py expect <rows.jsonl> <expected.tsv> each event against its frozen line, after the
                                                                       hold / pre-press / liveness / leg-agreement /
                                                                       identity / landed clauses
  python3 tools/ground_throw_rigs.py snaps <rig.json> <expected.tsv>    SNAP_FRAMES at each event's first fall
  python3 tools/ground_throw_rigs.py sheet <out.png> <legs root> <rigs dir> <expected.tsv>   the capture sheet
  python3 tools/ground_throw_rigs.py rowset <workbook.xlsx>             THROWS against the workbook's ground-throw rows

THE RIG (tools/vanilla_join_rig.py's walk-in, tools/name_moves.py's tokens): the character FORCED on P1 by the
early-window poke (P1 0x01's cell; P2 Victor 0x03, or Demitri 0x01 when Victor throws), REPLAY17's prologue; per
EVENT both fighters pinned to the far pair (552, 728) at t-230, P1 walks right t-190..t-40 to pushbox contact, a
40-frame pause, then ONE throw input at t (toward or back + the button, held 4 frames). Before each event P2's two
HP words are re-pinned to 288 (both words, [VSP-125]) and P1's stock and meter to 0. Events are GAP frames apart (a
Victor MP throw runs ~250 frames).

WHAT A ROW CARRIES (rows): HOLD — the first frame in the event window where P1's +0x134 is 0x01 (executing a throw)
and P2's is 0xFF (being thrown), RAM:$FF8534/$FF8934 (atlas/ram.md +0x134); no such frame is NO-HOLD (a VOID leg for
the comparison, never a verdict); DAMAGE — every logging-breakpoint hit at the fighter applier's record read
(PRG:0x0189EA `move.b $8(a3),d2`, tests/lua/replay_guard.lua GUARD_PROBE) inside the window, A3 decoded through
tools/hitbox_records.py's power() (the CLASS is the damage figure, bits 5-7 flags — #241) and IDENTIFIED: A3 must lie
inside the THROWER's own attack table (its hitbox_base row on vsavj), which the game chose — a record outside it is
reported, never counted; GAUGE — P1's +0x10A.w meter at the hold start and at the event end (re-pinned to 0 before,
so the end value is what the throw paid — any later normal would add to it, so the event carries one press only);
PRESS-TO-HOLD — hold frame minus press frame (the sheet's `startup` 1 counts the hold frame as frame 1)."""
import json
import os
import struct
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import hitbox_records  # noqa: E402
import name_moves as nm  # noqa: E402
import vanilla_frames as vf  # noqa: E402
import vanilla_join_rig as vj  # noqa: E402

GAP = 600
HOLD_WIN = 40      # frames after the event in which the hold must start (the press is the event frame)
END_AT = 360       # the event's END frame offset: after its last damage record, before the next event's pins
APPLIER = 0x0189EA
VICTIM = 0x03
# (sheet key, recipe) per vanilla character: the workbook's ground-throw rows (type `ground throw`, `p ground
# throw`, `k ground throw`), each "6MP or 6HP" row run with BOTH buttons so the sheet's one-row claim is measured.
TOWARD = lambda b: [(0, 3, "R" + nm.B[b])]
BACK = lambda b: [(0, 3, "L" + nm.B[b])]
THROWS = {
    "BU": [("P", "6MP", TOWARD("MP")), ("P", "6HP", TOWARD("HP"))],
    "DE": [("P", "6MP", TOWARD("MP")), ("P", "6HP", TOWARD("HP")), ("K", "6MK", TOWARD("MK")), ("K", "6HK", TOWARD("HK"))],
    "GA": [("P", "6MP", TOWARD("MP")), ("P", "6HP", TOWARD("HP")), ("K", "6MK", TOWARD("MK")), ("K", "6HK", TOWARD("HK"))],
    "VI": [("MP", "6MP", TOWARD("MP")), ("HP", "6HP", TOWARD("HP")), ("K", "6MK", TOWARD("MK")), ("K", "6HK", TOWARD("HK"))],
    "ZA": [("P", "6MP", TOWARD("MP")), ("P", "6HP", TOWARD("HP")), ("K", "6MK", TOWARD("MK")), ("K", "6HK", TOWARD("HK"))],
    "MO": [("P", "6MP", TOWARD("MP")), ("P", "6HP", TOWARD("HP")), ("K", "6MK", TOWARD("MK")), ("K", "6HK", TOWARD("HK"))],
    "FE": [("P", "6MP", TOWARD("MP")), ("P", "6HP", TOWARD("HP")), ("K", "6MK", TOWARD("MK")), ("K", "6HK", TOWARD("HK"))],
    "BI": [("P", "6MP", TOWARD("MP")), ("P", "6HP", TOWARD("HP"))],
    "AU": [("P", "6MP", TOWARD("MP")), ("P", "6HP", TOWARD("HP")), ("PB", "4MP", BACK("MP")), ("PB", "4HP", BACK("HP"))],
    "SA": [("P", "6MP", TOWARD("MP")), ("P", "6HP", TOWARD("HP"))],
    "QB": [("P", "6MP", TOWARD("MP")), ("P", "6HP", TOWARD("HP"))],
    "LE": [("P", "6MP", TOWARD("MP")), ("P", "6HP", TOWARD("HP"))],
    "LI": [("P", "6MP", TOWARD("MP")), ("P", "6HP", TOWARD("HP"))],
    "JE": [("P", "6MP", TOWARD("MP")), ("P", "6HP", TOWARD("HP"))],
}


def gen(out_dir):
    out = Path(out_dir); out.mkdir(parents=True, exist_ok=True)
    for tab, evs in THROWS.items():
        cid = vf.CHARS[tab][0]
        vic = 0x01 if cid == VICTIM else VICTIM
        x1, x2 = nm.PIN["far"]
        lines = [f"# #229 ground-throw rig — {tab} ({cid:#04x}) on vsavj, victim {vic:#04x}",
                 "# (tools/ground_throw_rigs.py gen; DO NOT hand-edit, regenerate). Select prologue from replay 17",
                 "# (the characters are FORCED by the early-window poke, so the cursor path does not matter).",
                 nm.REPLAY17_PROLOGUE.rstrip()]
        t = t0 = nm.FIRST_EVENT + vj.WALKIN_SHIFT
        sched = {"char": f"{cid:#04x}", "sheet": tab, "victim": f"{vic:#04x}", "gap": GAP, "events": []}
        pokes = [f"{f}:ff8782:{cid:02x}" for f in (1400, 1450, 1500)] + [f"{f}:ff8b82:{vic:02x}" for f in (1400, 1450, 1500)]
        for key, inp, rec in evs:
            pokes += [f"{t - 230}:ff8410:{x1:04x}", f"{t - 230}:ff8810:{x2:04x}",
                      f"{t - 20}:ff8850:01200120", f"{t - 20}:ff8509:000000"]
            lines.append(f"{t - 190}-{t - 40} p1=R")
            for a, bb, tok in rec:
                lines.append(f"{t + a}-{t + bb} p1={tok}")
            sched["events"].append({"key": key, "input": inp, "frame": t, "press": t + rec[0][0]})
            t += GAP
        end = t + 100
        lines.append(f"{end} wait")
        assert end - t0 < 7500, "a rig must fit inside one round"
        sched["pokes"] = pokes
        sched["frames"] = end + 50
        # per event: every frame of the hold window (the hold starts on the press frame) and the event's END frame
        # (the meter and HP it closed on) — a whole-window dump of four events overran the environment (E2BIG)
        sched["dumps"] = [[e["frame"] - 5, e["frame"] + HOLD_WIN] for e in sched["events"]]
        # the END frame lands BEFORE the next event's position pins (t + GAP - 230): read later, an event's x is the
        # next walk-in's, not the throw's (14z-195's first freeze read every non-last event's side as R that way).
        # The longest throw stages its last record at +186 (Victor's MP), so +360 closes every throw.
        sched["ends"] = [e["frame"] + END_AT for e in sched["events"]]
        (out / f"gt_{tab}.rpl").write_text("\n".join(lines) + "\n")
        (out / f"gt_{tab}.json").write_text(json.dumps(sched, indent=1) + "\n")
    print(f"wrote {len(THROWS)} rigs to {out}")


def dumps_spec(sched):
    """The DUMPS= line for a rig (BOTH applier legs run with it — run 2026-10-08-728 Q1a): per event, the hold
    window from 5 frames before the press (both +0x134, P2's HP words, P1's stock+meter); P2's two HP words on EVERY
    frame from the press to the END frame (the drops measured independently of the record reader — run 728 Q3/Q4);
    and at the END frame the meter and both fighters' x."""
    parts = []
    for (lo, hi), e, end in zip(sched["dumps"], sched["events"], sched["ends"]):
        for f in range(lo, hi):
            parts += [f"{f}:ff8850-ff8853", f"{f}:ff8934-ff8934", f"{f}:ff8534-ff8534", f"{f}:ff8509-ff850b"]
        for f in range(hi, end):
            parts.append(f"{f}:ff8850-ff8853")
        parts += [f"{end}:ff8850-ff8853", f"{end}:ff8509-ff850b", f"{end}:ff8410-ff8411", f"{end}:ff8810-ff8811"]
    return ";".join(parts)


def _rd(d, f, a):
    p = os.path.join(d, f"dump_{f}_{a}.bin")
    return open(p, "rb").read() if os.path.exists(p) else b""


def _hp(d, f):
    b = _rd(d, f, "ff8850")
    return struct.unpack(">hh", b) if len(b) == 4 else None


def _probes(path):
    out = []
    for line in open(path, errors="replace"):
        if line.startswith("PROBE "):
            f = int(line.split()[1])
            a3 = next((int(x[3:], 16) for x in line.split() if x.startswith("A3=")), None)
            if a3 is not None:
                out.append((f, a3))
    return out


def own_bounds(img, bank, cid):
    """The thrower's attack table: from its base to the nearest start of ANY table of ANY character above it
    (hitbox_records' table_len stops only at the same character's next table, and the attack table is each
    character's last, so it ran to the end of the image — every record anywhere read "own")."""
    H = hitbox_records.HitboxSet.from_image(img, vf.row_ptr(img, bank["hitbox_base"], cid),
                                            vf.row_ptr(img, bank["hitbox_comp"], cid))
    starts = set()
    for c in range(0x20):
        try:
            Hc = hitbox_records.HitboxSet.from_image(img, vf.row_ptr(img, bank["hitbox_base"], c),
                                                     vf.row_ptr(img, bank["hitbox_comp"], c))
            starts |= set(Hc.tables.values())
        except Exception:
            continue
    lo = H.tables["attack"]
    return lo, min([x for x in starts if x > lo] + [len(img)])


def leg_event(leg, e, end_f):
    """One leg's own view of one event, from ITS OWN dumps: the frame before the press (no hold allowed there), the
    hold frame (searched FROM the press — run 728 Q3), the dump completeness, and every frame where P2's red
    (+0x50) or white (+0x52) HP word FELL, with the fall — the victim's actual damage, measured without the
    record reader."""
    press = e["press"]
    pre = (_rd(leg, press - 1, "ff8534")[:1] == b"\x01" and _rd(leg, press - 1, "ff8934")[:1] == b"\xff")
    hwin = range(press, press + HOLD_WIN)
    hold = next((f for f in hwin if _rd(leg, f, "ff8534")[:1] == b"\x01" and _rd(leg, f, "ff8934")[:1] == b"\xff"), None)
    need = [press - 1] + list(range(press, end_f + 1))
    dumped = sum(1 for f in need if _hp(leg, f) is not None)
    drops, prev = [], _hp(leg, press - 1)
    for f in range(press, end_f + 1):
        cur = _hp(leg, f)
        if cur is None or prev is None:
            prev = cur
            continue
        dr, dw = prev[0] - cur[0], prev[1] - cur[1]
        if dr > 0 or dw > 0:
            drops.append((f, max(dr, 0), max(dw, 0)))
        prev = cur
    return {"pre_hold": pre, "hold": hold, "dumped": dumped, "need": len(need), "drops": drops}


LAND = 2   # a staged record's damage lands on its probe frame + 1 (measured: DE 6HP probe 3063, HP lower at 3064) — +2 tolerated


def rows(sched_path, rig_legs, img_path, probe_extra=""):
    """One row per event, joining the rig's two applier legs <rig_legs>/0189ea and <rig_legs>/02979a. Each leg is
    judged on its OWN dumps (run 728 Q1a): its hold, its pre-press frame, its drops; each record a leg's probe saw is
    LANDED only if that same leg's P2 HP fell within LAND frames after the probe frame (run 728 Q4); the two legs
    must agree on the hold frame and on every drop. `probe_extra` (the phantom-record control) appends PROBE lines
    to every leg's log as read."""
    sched = json.loads(Path(sched_path).read_text())
    img = Path(img_path).read_bytes()
    cid = int(sched["char"], 16)
    bank = vf.bank_rows(Path(__file__).resolve().parent.parent / "build/manifest/bank_map.toml")
    lo_tab, hi_tab = own_bounds(img, bank, cid)
    legs = {s: os.path.join(rig_legs, s) for s in ("0189ea", "02979a")}
    probes = {s: _probes(os.path.join(d, "run.log")) for s, d in legs.items()}
    if probe_extra:   # `+<off>:<a3 hex>` or `+<off>:auto` (the rig's own first damaging record, planted where no fall is)
        off, a3s = probe_extra.split(":")
        if a3s == "auto":
            cand = [a3 for s in probes for _, a3 in probes[s] if (img[a3 + 8] & 0x1F) or (img[a3 + 9] & 0x1F)]
            a3s = f"{cand[0]:x}" if cand else ""
        if a3s:
            for s in probes:
                for e in sched["events"]:
                    probes[s].append((e["press"] + int(off), int(a3s, 16)))
    out = []
    for i, e in enumerate(sched["events"]):
        end_f = sched["ends"][i]
        lv = {s: leg_event(d, e, end_f) for s, d in legs.items()}
        a, b = lv["0189ea"], lv["02979a"]
        # THE LEGS AGREE ON THE HOLD FRAME AND ON THE FALLS' AMOUNTS IN ORDER — NOT ON THE FALLS' FRAMES. Measured
        # (14z-195, the run-728 rework on PILOT): the two -debug legs (one breakpoint each) hold on the same frame on
        # all 42 events, and their falls carry the same amounts in the same order on 42 of 42, but land 1-2 frames
        # apart, the gap growing inside a long throw (DE 6MK 4009/4011 ... 4111/4117) — a breakpoint stop skews the
        # timeline ([VSP-129]), so a join by frame is wrong. Each leg's records are judged on its own falls.
        agree = a["hold"] == b["hold"] and [d[1:] for d in a["drops"]] == [d[1:] for d in b["drops"]]
        recs = []
        for s in ("0189ea", "02979a"):
            dframes = {f for f, _, _ in lv[s]["drops"]}
            for f, a3 in probes[s]:
                if not (e["press"] <= f <= end_f):
                    continue
                bb = img[a3:a3 + 0x20]
                real, white = bb[8] & 0x1F, bb[9] & 0x1F
                recs.append({"frame": f, "site": s, "a3": f"{a3:#x}", "own": lo_tab <= a3 < hi_tab,
                             "idx": (a3 - lo_tab) // hitbox_records.REC if lo_tab <= a3 < hi_tab else None,
                             "real": real, "white": white, "flags": [bb[8] & 0xE0, bb[9] & 0xE0], "meter": bb[0x14],
                             "landed": any(f < d <= f + LAND for d in dframes)})
        m = _rd(legs["0189ea"], end_f, "ff8509")
        m_end = struct.unpack(">H", m[1:3])[0] if len(m) >= 3 else None
        x1, x2 = _rd(legs["0189ea"], end_f, "ff8410"), _rd(legs["0189ea"], end_f, "ff8810")
        xs = (struct.unpack(">h", x1[:2])[0], struct.unpack(">h", x2[:2])[0]) if len(x1) >= 2 and len(x2) >= 2 else None
        out.append({"sheet": sched["sheet"], "key": e["key"], "input": e["input"], "press": e["press"],
                    "legs": {s: {"hold": v["hold"], "pre_hold": v["pre_hold"], "dumped": v["dumped"], "need": v["need"],
                                 "drops": v["drops"]} for s, v in lv.items()},
                    "legs_agree": agree, "hold": a["hold"], "pre_hold": a["pre_hold"] or b["pre_hold"],
                    "press_to_hold": (a["hold"] - e["press"]) if a["hold"] is not None else None,
                    "drops": a["drops"], "records": recs, "meter_end": m_end, "x_end": xs})
    for r in out:
        print(json.dumps(r))


def signature(r):
    """One event as its frozen line: sheet, key, input, press-to-hold, the side P2 ends on, the meter paid, the
    MEASURED damage (P2's summed red and white falls, the number of falls, the first fall's offset from the press —
    read from the dumps, never from the record reader, run 728 Q4), and the staged records in frame order as
    site:index:real/white:flags:meter (frames not frozen: an MP and an HP leg of one throw differ by a frame)."""
    side = "-" if not r.get("x_end") else ("R" if r["x_end"][1] > r["x_end"][0] else "L")
    dr = sum(x[1] for x in r["drops"]); dw = sum(x[2] for x in r["drops"])
    first = (r["drops"][0][0] - r["press"]) if r["drops"] else "-"
    recs = ";".join(f"{x['site']}:{x['idx']}:{x['real']}/{x['white']}:{x['flags'][0] | x['flags'][1]:#x}:{x['meter']}"
                    for x in sorted(r["records"], key=lambda x: (x["frame"], x["site"])))
    return "\t".join(str(v) for v in (r["sheet"], r["key"], r["input"], r["press_to_hold"], side, r["meter_end"],
                                      dr, dw, len(r["drops"]), first, recs))


HEADER = ("# tests/expected/ground_throws.tsv — the vsavj ground throws (#229, 14z-195), FROZEN by\n"
          "# `tools/ground_throw_rigs.py freeze`; columns: sheet key input press_to_hold p2_side meter_paid\n"
          "# red_fall white_fall n_falls first_fall_offset records (falls = P2's HP words read from the dumps)")


def freeze(rows_path):
    print(HEADER)
    for l in open(rows_path):
        print(signature(json.loads(l)))


def expect(rows_path, exp_path):
    want = {}
    for l in open(exp_path):
        if l.startswith("#") or not l.strip():
            continue
        f = l.rstrip("\n").split("\t")
        want[tuple(f[:3])] = l.rstrip("\n")
    bad, seen = 0, set()

    def no(k, why):
        nonlocal bad
        print(f"BAD {k}: {why}"); bad += 1

    for l in open(rows_path):
        r = json.loads(l)
        k = (r["sheet"], r["key"], r["input"]); seen.add(k)
        lg = r["legs"]
        if any(v["hold"] is None for v in lg.values()):
            no(k, f"NO HOLD from the press on a leg ({ {s: v['hold'] for s, v in lg.items()} }) — the leg is VOID"); continue
        if r["pre_hold"]:
            no(k, "the hold is already set on the frame BEFORE the press — the press did not start it"); continue
        short = {s: f"{v['dumped']}/{v['need']}" for s, v in lg.items() if v["dumped"] != v["need"]}
        if short:
            no(k, f"dump frames missing {short} — a leg not proven live"); continue
        if not r["legs_agree"]:
            no(k, f"the two applier legs disagree (hold { {s: v['hold'] for s, v in lg.items()} }, fall amounts "
                  f"{ {s: [tuple(d[1:]) for d in v['drops']] for s, v in lg.items()} })"); continue
        alien = [x["a3"] for x in r["records"] if not x["own"]]
        if alien:
            no(k, f"damage record(s) {alien} outside the thrower's own attack table"); continue
        dealt = [x for x in r["records"] if x["real"] or x["white"]]
        if not dealt:
            no(k, "no damage record staged"); continue
        unlanded = [f"{x['site']}@{x['frame']}" for x in dealt if not x["landed"]]
        if unlanded:
            no(k, f"staged record(s) {unlanded} with no fall of P2's HP within {LAND} frames — damage the victim never took"); continue
        if (len(r["drops"]) > 0) != (len(dealt) > 0):
            no(k, "falls and staged damage disagree"); continue
        got = signature(r)
        if got != want.get(k):
            no(k, f"got  {got}\n    want {want.get(k)}")
        else:
            print(f"ok  {got}")
    for k in sorted(set(want) - seen):
        no(k, "frozen but not measured")
    print(f"{len(seen)} event(s), {bad} bad")
    return 1 if bad else 0


def snaps(sched_path, exp_path):
    """SNAP_FRAMES for a rig's capture: each event's press + its FROZEN first-fall offset (the frame the damage
    lands). The run that takes them is held to the same expectation, so a PASS means each snapshot is the frame
    that run's own first fall landed on."""
    sched = json.loads(Path(sched_path).read_text())
    want = {}
    for l in open(exp_path):
        if not l.startswith("#") and l.strip():
            f = l.rstrip("\n").split("\t")
            if len(f) >= 11:   # an expectation in an older column form carries no first-fall offset: no snapshot
                want[tuple(f[:3])] = f[9]
    out = []
    for e in sched["events"]:
        off = want.get((sched["sheet"], e["key"], e["input"]))
        if off and off != "-":
            out.append(str(e["press"] + int(off)))
    print(",".join(out))


def sheet(out_png, legs_root, rigs_dir, exp_path):
    """The capture sheet: every rig's snapshots (taken by the 0x0189EA leg at its events' first-fall frames), one
    row per character, labelled with the event and the frame."""
    from PIL import Image, ImageDraw
    tiles = []
    for j in sorted(Path(rigs_dir).glob("gt_*.json")):
        sched = json.loads(j.read_text())
        frames = [int(x) for x in os.popen(f"python3 {__file__} snaps {j} {exp_path}").read().strip().split(",") if x]
        shots = sorted(Path(legs_root, j.stem, "0189ea", "sb", "snap").rglob("*.png"))
        evs = {e["press"]: e for e in sched["events"]}
        for fr, p in zip(frames, shots):
            e = next(ev for pr, ev in evs.items() if pr <= fr < pr + GAP)
            tiles.append((f"{sched['sheet']} {e['input']}  frame {fr} (press {e['press']} +{fr - e['press']})", Image.open(p).convert("RGB")))
    if not tiles:
        sys.exit("sheet: no snapshots found")
    w, h = tiles[0][1].size
    cols = 4
    rowsn = (len(tiles) + cols - 1) // cols
    im = Image.new("RGB", (cols * (w + 8) + 8, rowsn * (h + 22) + 8), (20, 20, 20))
    d = ImageDraw.Draw(im)
    for i, (lab, t) in enumerate(tiles):
        x, y = 8 + (i % cols) * (w + 8), 8 + (i // cols) * (h + 22)
        d.text((x, y), lab, fill=(255, 255, 255))
        im.paste(t, (x, y + 14))
    im.save(out_png)
    print(f"wrote {out_png} ({len(tiles)} snapshots)")


# THE ROW SET (run 728 Q1c): the workbook's ground-throw rows, by its own `type` column, against THROWS. Graviton
# Knuckle (a follow-up input during Victor's MP throw) is declared NOT MEASURED.
MOVE_KEY = {"P THROW": "P", "K THROW": "K", "P THROW BACK": "PB", "MP THROW": "MP", "HP THROW": "HP"}
NOT_MEASURED = {("VI", "GRAVITON KNUCKLE")}


def rowset(xlsx):
    import xlsx_read
    wb = xlsx_read.Workbook(xlsx)
    got, unknown = set(), []
    for tab in wb.sheet_names:
        for d in wb.rows(tab):
            d = {k.lower(): str(v).strip() for k, v in d.items()}
            if "ground throw" not in d.get("type", "").lower():
                continue
            mv = d.get("move", "").upper()
            if (tab, mv) in NOT_MEASURED:
                continue
            if mv not in MOVE_KEY:
                unknown.append((tab, mv)); continue
            got.add((tab, MOVE_KEY[mv]))
    ours = {(tab, k) for tab, evs in THROWS.items() for k, _, _ in evs}
    print(f"workbook ground-throw rows {len(got)} (+{len(NOT_MEASURED)} declared not measured); rigs cover {len(ours)}")
    for x in sorted(got - ours):
        print(f"MISSING from the rigs: {x}")
    for x in sorted(ours - got):
        print(f"NOT IN the workbook: {x}")
    for x in unknown:
        print(f"UNMAPPED workbook row: {x}")
    return 0 if got == ours and not unknown else 1


def main():
    a = sys.argv[1:]
    if a[:1] == ["gen"] and len(a) == 2:
        return gen(a[1])
    if a[:1] == ["dumps"] and len(a) == 2:
        print(dumps_spec(json.loads(Path(a[1]).read_text())))
        return 0
    if a[:1] == ["rows"] and len(a) in (4, 5):
        return rows(*a[1:])
    if a[:1] == ["freeze"] and len(a) == 2:
        return freeze(a[1])
    if a[:1] == ["expect"] and len(a) == 3:
        return expect(a[1], a[2])
    if a[:1] == ["snaps"] and len(a) == 3:
        return snaps(a[1], a[2])
    if a[:1] == ["sheet"] and len(a) == 5:
        return sheet(*a[1:])
    if a[:1] == ["rowset"] and len(a) == 2:
        return rowset(a[1])
    sys.exit(__doc__)


if __name__ == "__main__":
    sys.exit(main() or 0)
