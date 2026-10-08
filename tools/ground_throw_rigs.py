#!/usr/bin/env python3
"""ground_throw_rigs.py — the vsavj GROUND THROWS for the community cross-check (GitHub #229, 14z-195).

  python3 tools/ground_throw_rigs.py gen <out dir>                      one rig per vanilla character (.rpl + .json)
  python3 tools/ground_throw_rigs.py rows <rig.json> <leg dir> <site=probe.log,...> <vsavj_data.bin>
                                                                       one row per event (JSON lines)
  python3 tools/ground_throw_rigs.py dumps <rig.json>                   the DUMPS= spec a rig's applier leg runs with
  python3 tools/ground_throw_rigs.py freeze <rows.jsonl>                the frozen signature, one line per event
  python3 tools/ground_throw_rigs.py expect <rows.jsonl> <expected.tsv> each event against its frozen line
                                                                       (+ the liveness and identity clauses)

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
    """The DUMPS= line for a rig: per event window, P2's HP words, both +0x134, P1's stock+meter and seq."""
    parts = []
    for lo, hi in sched["dumps"]:
        for f in list(range(lo, hi)):
            parts += [f"{f}:ff8850-ff8853", f"{f}:ff8934-ff8934", f"{f}:ff8534-ff8534", f"{f}:ff8509-ff850b"]
    for f in sched["ends"]:
        parts += [f"{f}:ff8850-ff8853", f"{f}:ff8509-ff850b", f"{f}:ff8410-ff8411", f"{f}:ff8810-ff8811"]
    return ";".join(parts)


def _rd(d, f, a):
    p = os.path.join(d, f"dump_{f}_{a}.bin")
    return open(p, "rb").read() if os.path.exists(p) else b""


def rows(sched_path, leg, probe_log, img_path):
    sched = json.loads(Path(sched_path).read_text())
    img = Path(img_path).read_bytes()
    cid = int(sched["char"], 16)
    bank = vf.bank_rows(Path(__file__).resolve().parent.parent / "build/manifest/bank_map.toml")
    H = hitbox_records.HitboxSet.from_image(img, vf.row_ptr(img, bank["hitbox_base"], cid),
                                            vf.row_ptr(img, bank["hitbox_comp"], cid))
    # THE OWN-TABLE BOUND: the attack table runs from its base to the nearest start of ANY table of ANY character
    # above it (hitbox_records' table_len stops only at the same character's next table, and the attack table is
    # each character's last, so it ran to the end of the image — every record anywhere read "own").
    starts = set()
    for c in range(0x20):
        try:
            Hc = hitbox_records.HitboxSet.from_image(img, vf.row_ptr(img, bank["hitbox_base"], c),
                                                     vf.row_ptr(img, bank["hitbox_comp"], c))
            starts |= set(Hc.tables.values())
        except Exception:
            continue
    lo_tab = H.tables["attack"]
    hi_tab = min([x for x in starts if x > lo_tab] + [len(img)])
    probes = []   # <probe.log> may be several, comma-separated, each `<site>=<path>` (the applier probed)
    for spec in probe_log.split(","):
        site, _, path = spec.rpartition("=")
        for line in open(path, errors="replace"):
            if line.startswith("PROBE "):
                f = int(line.split()[1])
                a3 = next((int(x[3:], 16) for x in line.split() if x.startswith("A3=")), None)
                probes.append((f, a3, site or "0189ea"))
    out = []
    for e in sched["events"]:
        t, press = e["frame"], e["press"]
        win = range(t - 5, t + sched["gap"] - 20)          # the probes' window: the whole event
        hwin = range(t - 5, t + HOLD_WIN)
        end_f = sched["ends"][sched["events"].index(e)]
        hold = next((f for f in hwin if _rd(leg, f, "ff8534")[:1] == b"\x01" and _rd(leg, f, "ff8934")[:1] == b"\xff"), None)
        dumped = sum(1 for f in hwin if _rd(leg, f, "ff8850")) + (1 if _rd(leg, end_f, "ff8850") else 0)
        recs = []
        for f, a3, site in probes:
            if f in win and a3 is not None:
                b = img[a3:a3 + 0x20]
                recs.append({"frame": f, "site": site, "a3": f"{a3:#x}", "own": lo_tab <= a3 < hi_tab,
                             "idx": (a3 - lo_tab) // hitbox_records.REC if lo_tab <= a3 < hi_tab else None,
                             "real": b[8] & 0x1F, "white": b[9] & 0x1F, "flags": [b[8] & 0xE0, b[9] & 0xE0], "meter": b[0x14]})
        last = end_f if _rd(leg, end_f, "ff8509") else None
        m_end = struct.unpack(">H", _rd(leg, last, "ff8509")[1:3])[0] if last is not None else None
        hp0 = _rd(leg, t - 5, "ff8850")
        hpl = _rd(leg, last, "ff8850") if last is not None else b""
        drop = (struct.unpack(">hh", hp0)[0] - struct.unpack(">hh", hpl)[0],
                struct.unpack(">hh", hp0)[1] - struct.unpack(">hh", hpl)[1]) if len(hp0) == 4 and len(hpl) == 4 else None
        xs = (struct.unpack(">h", _rd(leg, end_f, "ff8410")[:2])[0], struct.unpack(">h", _rd(leg, end_f, "ff8810")[:2])[0]) \
            if len(_rd(leg, end_f, "ff8410")) >= 2 and len(_rd(leg, end_f, "ff8810")) >= 2 else None
        out.append({"sheet": sched["sheet"], "key": e["key"], "input": e["input"], "frame": t, "press": press, "x_end": xs,
                    "dumped": dumped, "hold": hold, "press_to_hold": (hold - press) if hold is not None else None,
                    "records": recs, "meter_end": m_end, "dealt_hp_white": drop})
    for r in out:
        print(json.dumps(r))


def signature(r):
    """One event as its frozen line: sheet, key, input, press-to-hold, the side P2 ends on (R/L of P1), the meter
    paid, and the damage records in frame order as site:index:real/white:flags:meter (frames are NOT frozen —
    an MP and an HP leg of one throw differ by a frame; the order and the records are the throw)."""
    side = "-" if not r.get("x_end") else ("R" if r["x_end"][1] > r["x_end"][0] else "L")
    recs = ";".join(f"{x['site']}:{x['idx']}:{x['real']}/{x['white']}:{x['flags'][0] | x['flags'][1]:#x}:{x['meter']}"
                    for x in sorted(r["records"], key=lambda x: x["frame"]))
    return "\t".join(str(v) for v in (r["sheet"], r["key"], r["input"], r["press_to_hold"], side, r["meter_end"], recs))


def freeze(rows_path):
    print("# tests/expected/ground_throws.tsv — the vsavj ground throws (#229, 14z-195), FROZEN by")
    print("# `tools/ground_throw_rigs.py freeze`; columns: sheet key input press_to_hold p2_side meter_paid records")
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
    for l in open(rows_path):
        r = json.loads(l)
        k = (r["sheet"], r["key"], r["input"]); seen.add(k)
        if r["hold"] is None:
            print(f"BAD {k}: NO HOLD in the hold window (dumped {r['dumped']} of {HOLD_WIN + 6}) — the leg is VOID"); bad += 1; continue
        if r["dumped"] != HOLD_WIN + 6:
            print(f"BAD {k}: {r['dumped']} of {HOLD_WIN + 6} dump frames present — a leg not proven live"); bad += 1; continue
        alien = [x["a3"] for x in r["records"] if not x["own"]]
        if alien:
            print(f"BAD {k}: damage record(s) {alien} outside the thrower's own attack table"); bad += 1; continue
        if not any(x["real"] or x["white"] for x in r["records"]):
            print(f"BAD {k}: no damage record staged"); bad += 1; continue
        got = signature(r)
        if got != want.get(k):
            print(f"BAD {k}: got  {got}\n    want {want.get(k)}"); bad += 1
        else:
            print(f"ok  {got}")
    for k in sorted(set(want) - seen):
        print(f"BAD {k}: frozen but not measured"); bad += 1
    print(f"{len(seen)} event(s), {bad} bad")
    return 1 if bad else 0


def main():
    a = sys.argv[1:]
    if a[:1] == ["gen"] and len(a) == 2:
        return gen(a[1])
    if a[:1] == ["dumps"] and len(a) == 2:
        print(dumps_spec(json.loads(Path(a[1]).read_text())))
        return 0
    if a[:1] == ["rows"] and len(a) == 5:
        return rows(*a[1:])
    if a[:1] == ["freeze"] and len(a) == 2:
        return freeze(a[1])
    if a[:1] == ["expect"] and len(a) == 3:
        return expect(a[1], a[2])
    sys.exit(__doc__)


if __name__ == "__main__":
    sys.exit(main() or 0)
