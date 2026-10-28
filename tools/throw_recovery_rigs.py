#!/usr/bin/env python3
"""throw_recovery_rigs.py — THE VSAVJ GROUND THROWS' RECOVERY AND THROW TECH (GitHub #330, 14z-211): when each fighter can
act again after every ground throw of tools/ground_throw_rigs.py, thrown and teched, and the tech window's edge.

  python3 tools/throw_recovery_rigs.py gen <ticks.tsv> <out dir> [--shift N] [--tech-token T] [--late-tech K] [--only RIG]
                                                       per event two rigs (tr_<RIG>_thrown, tr_<RIG>_teched; .rpl + .json)
  python3 tools/throw_recovery_rigs.py rows <rigs dir> <traces dir>       one row per event (JSON lines)
  python3 tools/throw_recovery_rigs.py freeze <rows.jsonl> <expected.tsv> the in-tree hashes, and the full lines OUTSIDE it
  python3 tools/throw_recovery_rigs.py expect <rows.jsonl> <expected.tsv> each event's clauses, and its frozen line
  python3 tools/throw_recovery_rigs.py ticks [<full.tsv>]                 the tick columns of the full lines (gen's input)

THE MEASUREMENT (build/agent211/t330/notes.md, probes 1-7b; DECISIONS_HISTORY.md "Ruled 2026-10-28 (14z-211) — #330"):
ACTIONABLE is the FIRST ACCEPTED INPUT — the first tick, counted from the throw's commit (P1's press frame, where the hold
starts), at which a ONE-frame LP starts the normal (the presser's +0x04 departs from its no-LP control ON the press
frame into seq 0x0A, mode 00), the tick before never doing so (the maintainer: "First accepted input"). No single
engine state marks it (the mode byte +0x05 returns to 00 up to 11 ticks early on 22 of 42 events; standing neutral
0x02000002 comes up to 25 late on 24 of 168 cases), so the ticks are MEASURED (probe 6's scan) and this tool RE-PROVES
each one every run: an LP at A-1 that never starts the normal and an LP at A that does, for both fighters, thrown and
teched. The rig is tools/ground_throw_rigs.py's (walk-in to pushbox contact, one toward/back + button; victim Victor,
Demitri for Victor; TR_VICTIM=<hex> another, with its own expectation and full lines) at speed level 0 (RAM:$FF8116 = 00: one engine pass per frame, so ticks are frames) with the RNG
pinned (RAM:$FF80D4 = 0000), events 624 frames apart (16 x name_moves.TICK_QUANTUM), each rig led by a SACRIFICIAL
event (a rig's first event stands at another stage x; Morrigan's K throw behaves differently there — probe 6).

THE TECH: P2 back + the throw's OWN button for one frame at k ticks after the commit (the air throws: after the air
press, P2 airborne). A k TECHS when the victim's red HP
loss differs from the thrown control's or its mode-byte tick (+0x05 first back to 00, plus one) moves by more than 10
(Demitri's K throw: a press at k = 8 shortens the throw 2 ticks at the same red damage — MASH, never a tech). Measured:
k = 1..7 tech on every ground event and k = 8..10 do not (probes 2, 4, 4b); on the air throws k = 1..7 on 26 of 28, Lei-Lei's
two untechable (air probe 4); the rigs carry k = 1 (the teched control), 7 and 8.

THE WINDOW is frozen per event (`1-7`, or `none` where no tech exists: Lei-Lei's air throw); the clauses hold k = 7 to
k = 1's outcome and k = 8 to no tech.

WHAT A ROW CARRIES: the four ticks (thrower and victim, thrown and teched), each with its two acceptance verdicts and
the control's +0x04 at that tick; the window's verdicts (k = 1 and 7 tech, k = 8 does not); the victim's red/white HP
loss thrown and teched. THE FULL LINE (sheet key input, the ticks, the states, the losses) is per-move frame data: it
lives OUTSIDE the tree (TR_FULL, ../charpages/framedata/throw_recovery_full.tsv — the 14z-126 frame-data ruling, #319),
the tree holding its 16-hex SHA-256 (tests/expected/throw_recovery.tsv). gen reads its ticks from the full lines, so
the rigs are made at run time and never committed (their press offsets ARE the ticks)."""
import hashlib
import json
import os
import re
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import ground_throw_rigs as gtr  # noqa: E402
import name_moves as nm  # noqa: E402

GAP = 624                 # 16 x name_moves.TICK_QUANTUM (#168), as the probes ran
L = 390                   # the comparison horizon: the next event's position pins land at +394 (GAP - 230)
ACCEPT_WIN = 60           # frames after an LP press in which a departure from the control is looked for
LEVEL, RNG = "00", "0000"
TECH_K = (1, 7)           # the k that must tech (k = 1 is the teched control)
NOTECH_K = 8              # the k that must not
FULL_DEFAULT = str(Path(__file__).resolve().parent.parent.parent / "charpages/framedata/throw_recovery_full.tsv")
COLS = ("thr_thrown", "vic_thrown", "thr_tech", "vic_tech")


def victim_tag():
    """TR_VICTIM (a hex id) runs the rigs on another victim (ground_throw_rigs' rule: the thrower's own id -> 0x01); the
    default, empty, is the rigs' own (Victor, Demitri for Victor) — the gate's frozen set (ruled 2026-10-28)"""
    v = os.environ.get("TR_VICTIM", "")
    return f"_v{int(v, 16):02x}" if v else ""


def family_tag():
    if os.environ.get("TR_FAMILY", "ground") == "command":
        return "_command"
    if os.environ.get("TR_FAMILY", "ground") != "air":
        return ""
    return "_air" + (f"_h{height():+d}" if height() else "")


def full_path():
    return os.environ.get("TR_FULL", FULL_DEFAULT.replace(".tsv", "").replace("throw_recovery_full", "throw_recovery" +
                                                                                      family_tag() + "_full") + victim_tag() + ".tsv")


def exp_path():
    return f"tests/expected/throw_recovery{family_tag()}{victim_tag()}.tsv"


# THE AIR THROWS AT LEVEL 0 (#330, 14z-211): tools/ground_throw_rigs.py's air rigs run at vsavj's default speed level (6),
# where the press at +14 frames is 17 engine ticks after P1's jump (Bulleta's +18 is 22, Victor's converging +16 is 20).
# At level 0 a frame is a tick, so the press goes at THOSE TICKS, P2's lead at 3: measured, every fighter's y and the
# pair's dx at the commit equal the level-6 rigs' on all 14 (build/agent211/t330 air_tune_gen.py, pa/ against pat/).
AIR_AT = {"BU": 22, "VI": 19}
# THE HEIGHT RANGE (the maintainer, 2026-10-28: "Against a height range"): an air throw's recovery moves with its height,
# so each is also frozen pressed 3 ticks earlier, 3 and 6 later (TR_HEIGHT=-3 / 3 / 6), every height that still throws:
# measured, these do not hold at all and are left out of that height (build/agent211/t330 air_height_gen.py, pah/)
AIR_HEIGHTS = (-3, 3, 6)
AIR_NOHOLD = {-3: {"DE", "LE", "LI", "MO"}, 3: {"VI"}, 6: {"VI"}}


def height():
    return int(os.environ.get("TR_HEIGHT", "0") or 0)


def air_l0(tab, b):
    at = AIR_AT.get(tab, 17) + height()
    if tab == "VI":   # the pair converging: P2 jumps toward 3 frames ahead (ground_throw_rigs._converge at level 0)
        return [(-5, -3, "UL", "p2"), (0, 2, "UR"), (at, at + 3, "R" + nm.B[b])]
    return [(-3, -1, "U", "p2"), (0, 2, "U"), (at, at + 3, "R" + nm.B[b])]


def events(family=None):
    """every event of the family (TR_FAMILY: `ground`, the default — tools/ground_throw_rigs.py's ground throws — or `air`,
    its air throws at level 0, air_l0), as (rig name, tab, key, input, recipe, the press offset in the recipe)"""
    fam = family or os.environ.get("TR_FAMILY", "ground")
    if fam == "command":
        for rig, tab, row, label, ev in cmd_events():
            yield rig, tab, row, label, ev, None
        return
    if fam == "air":
        for tab, evs in gtr.AIR.items():
            if tab in AIR_NOHOLD.get(height(), ()):
                continue
            for n, (key, inp, _rec) in enumerate(evs):
                b = re.search(r"6(MP|HP)", inp).group(1)
                yield f"{tab}_air_{n}", tab, key, inp, air_l0(tab, b), AIR_AT.get(tab, 17) + height()
        return
    for tab, evs in gtr.THROWS.items():
        for n, (key, inp, rec) in enumerate(evs):
            yield f"{tab}_{n}", tab, key, inp, rec, 0


def read_ticks(path):
    """{rig: {col: tick}} from a ticks TSV (rig input thr_thrown vic_thrown thr_tech vic_tech, header line `rig`) or
    from the full lines (sheet key input + the four ticks first)"""
    out, rigs = {}, {f"{t}|{k}|{i}": r for r, t, k, i, *_ in events()}
    for line in open(path):
        if line.startswith("#") or not line.strip() or line.startswith("rig\t"):
            continue
        f = line.rstrip("\n").split("\t")
        if f[0] in rigs.values():
            out[f[0]] = dict(zip(COLS, map(int, f[2:6])))
        else:
            out[rigs[f"{f[0]}|{f[1]}|{f[2]}"]] = dict(zip(COLS, map(int, f[3:7])))
    return out


def gen(ticks_path, out_dir, shift=0, tech_token=None, late_tech=NOTECH_K, only=None):
    """per event the THROWN rig [sacrificial, control, tech@late_tech, P1 LP@At-1, @At, P2 LP@Av-1, @Av] and the TECHED
    rig [sacrificial, control = tech@1, tech@7, the same four LP presses at the teched ticks, each with tech@1]"""
    ticks = read_ticks(ticks_path)
    out = Path(out_dir); out.mkdir(parents=True, exist_ok=True)
    victim = int(os.environ["TR_VICTIM"], 16) if os.environ.get("TR_VICTIM") else gtr.VICTIM
    n = 0
    for rig, tab, key, inp, rec, at0 in events():
        if only and rig not in only:
            continue
        t = ticks[rig]
        tok = tech_token or nm.B[re.search(r"[46](MP|HP|MK|HK)", inp).group(1)]

        # every offset below is from the COMMIT (the press, at0 into the recipe; the hold starts there)
        def tech(k):
            return [(at0 + k, at0 + k, "R" + tok, "p2")]

        def lp(who, o):
            return [(at0 + o, at0 + o, "1")] if who == "p1" else [(at0 + o, at0 + o, "1", "p2")]
        for case, extra, ctl_extra, more, at, av in (
                ("thrown", [], [], [("tech@%d" % late_tech, tech(late_tech))], t["thr_thrown"], t["vic_thrown"]),
                ("teched", tech(1), tech(1), [("tech@7", tech(7))], t["thr_tech"], t["vic_tech"])):
            at, av = at + shift, av + shift
            E = [(key, f"{inp} sacrificial first event", rec), (key, f"{inp} {case} control", rec + ctl_extra)]
            E += [(key, f"{inp} {case} {lab}", rec + r) for lab, r in more]
            for who, a in (("p1", at), ("p2", av)):
                for o in (a - 1, a):
                    E.append((key, f"{inp} {case} {who} LP@+{o} A={a}", rec + extra + lp(who, o)))
            saved = (gtr.GAP, gtr.THROWS, gtr.AIR, gtr.VICTIM)
            # the event's frame is its first token's offset 0; its press (the commit) is at0 later: gen records it
            try:
                gtr.GAP, gtr.THROWS, gtr.AIR, gtr.VICTIM = GAP, {tab: E}, {}, victim
                d = out / f"_{rig}_{case}"
                with open(os.devnull, "w") as dn:
                    _o, sys.stdout = sys.stdout, dn
                    try:
                        gtr.gen(d)
                    finally:
                        sys.stdout = _o
            finally:
                gtr.GAP, gtr.THROWS, gtr.AIR, gtr.VICTIM = saved
            j = json.load(open(d / f"gt_{tab}.json")); f = j["frames"]
            j["pokes"] += [f"2000-{f - 1}:ff8116:{LEVEL}", f"2363-{f - 1}:ff80d4:{RNG}"]
            j.update({"rig": rig, "case": case, "key": key, "input": inp})
            name = f"tr_{rig}_{case}"
            (out / f"{name}.json").write_text(json.dumps(j, indent=1) + "\n")
            (d / f"gt_{tab}.rpl").rename(out / f"{name}.rpl")
            for p in d.iterdir():
                p.unlink()
            d.rmdir()
            n += 1
    print(f"wrote {n} rigs to {out}")


def _trace(path):
    tr = {}
    for line in open(path):
        m = re.match(r"F (\d+) (.*)", line)
        if m:
            tr[int(m.group(1))] = {k: int(v) for k, v in (kv.split("=") for kv in m.group(2).split())}
    return tr


def _st(tr, f, who):
    return tr[f][who + "st"] & 0xffffffff


def _loss(tr, p):
    a, b = tr.get(p - 1), tr.get(p + L)
    return (a["p2red"] - b["p2red"], a["p2wht"] - b["p2wht"]) if a and b else None


def _mode_tick(tr, p, who):
    """the tick after the one in which +0x05 first reads 00 after the commit (the TECH criterion's victim figure)"""
    return next((f - p + 1 for f in range(p + 1, p + L) if f in tr and (tr[f][who + "st"] >> 16) & 0xff == 0), None)


def _accepted(tr, p, c, o, who):
    """did a one-frame LP at offset o START THE NORMAL: the presser departs from its control on the press frame, into
    seq 0x0A with mode 00 (+0x04 = 0x02000Axx)"""
    d = next((x for x in range(o, o + ACCEPT_WIN) if tr.get(p + x) is None or tr.get(c + x) is None
              or _st(tr, p + x, who) != _st(tr, c + x, who)), None)
    return d == o and tr.get(p + o) is not None and (_st(tr, p + o, who) & 0x00ffff00) == 0x00000a00


def rows(rigs_dir, traces_dir):
    rigs = {}
    for j in sorted(Path(rigs_dir).glob("tr_*.json")):
        s = json.loads(j.read_text()); tp = Path(traces_dir) / f"{j.stem}.txt"
        rigs.setdefault(s["rig"], {})[s["case"]] = (s, _trace(tp) if tp.exists() else None)
    for rig, cases in sorted(rigs.items()):
        r = {"rig": rig, "problems": []}
        sig = {}
        for case in ("thrown", "teched"):
            if case not in cases:
                r["problems"].append(f"no {case} rig"); continue
            s, tr = cases[case]
            r.update({"sheet": s["sheet"], "key": s["key"], "input": s["input"]})
            if tr is None:
                r["problems"].append(f"no trace for the {case} rig"); continue
            ev = s["events"]
            c = next(e["press"] for e in ev if e["input"].endswith(" control"))
            if c + L not in tr:
                r["problems"].append(f"the {case} trace ends before the control's +{L}"); continue
            if not (tr[c]["p1thr"] == 1 and tr[c]["p2thr"] in (255, -1)):
                r["problems"].append(f"the {case} control does not hold on its press frame")
            sig[case] = {"ctl": (_loss(tr, c), _mode_tick(tr, c, "p2"))}
            for e in ev:
                m = re.search(r" (p1|p2) LP@\+(\d+) A=(\d+)$", e["input"])
                if m:
                    who, o, a = m.group(1), int(m.group(2)), int(m.group(3))
                    k = f"{'thr' if who == 'p1' else 'vic'}_{'thrown' if case == 'thrown' else 'tech'}"
                    r[k] = a
                    r.setdefault("accept", {})[f"{k}@{'A-1' if o == a - 1 else 'A'}"] = _accepted(tr, e["press"], c, o, who)
                    if o == a:
                        r.setdefault("state", {})[k] = f"{_st(tr, c + a, who):08x}"
                m = re.search(r" tech@(\d+)$", e["input"])
                if m:
                    sig[case][int(m.group(1))] = (_loss(tr, e["press"]), _mode_tick(tr, e["press"], "p2"))
            r[f"loss_{case}"] = list(sig[case]["ctl"][0]) if sig[case]["ctl"][0] else None
        if "thrown" in sig and "teched" in sig:
            base = sig["thrown"]["ctl"]

            def techs(x):
                return x[0] is None or base[0] is None or x[0][0] != base[0][0] or x[1] is None or base[1] is None \
                    or abs(x[1] - base[1]) > 10
            r["window"] = {"k1": techs(sig["teched"]["ctl"]), "k7": techs(sig["teched"].get(7, (None, None))),
                           "k8": techs(sig["thrown"].get(NOTECH_K, (None, None))) if NOTECH_K in sig["thrown"]
                           else techs(next((v for k, v in sig["thrown"].items() if k != "ctl"), (None, None))),
                           "k7_as_k1": sig["teched"].get(7) == sig["teched"]["ctl"]}
        print(json.dumps(r))


def full_line(r):
    if r.get("family") == "command":
        return cmd_full_line(r)
    return _full_line(r)


def _full_line(r):
    """the event's full line: sheet key input, the four ticks, the controls' +0x04 at them, the losses (red/white)"""
    st = r.get("state", {})
    lt, lc = r.get("loss_thrown") or ["-", "-"], r.get("loss_teched") or ["-", "-"]
    return "\t".join(str(v) for v in (r.get("sheet"), r.get("key"), r.get("input"), *(r.get(c, "-") for c in COLS),
                                      *(st.get(c, "-") for c in COLS), f"{lt[0]}/{lt[1]}", f"{lc[0]}/{lc[1]}", window(r)))


def window(r):
    """the event's tech window as frozen: `1-7` when k = 1 techs (and, by the clauses, k = 7 as k = 1 and k = 8 not),
    `none` when k = 1 does not (Lei-Lei's air throw: no tech exists — the workbook's cell is empty)"""
    return "1-7" if r.get("window", {}).get("k1") else "none"


def hashed(full):
    return "\t".join(full.split("\t")[:3] + [hashlib.sha256(full.encode()).hexdigest()[:16]])


def clauses(r):
    """every clause one event must satisfy; a list of what failed"""
    if r.get("family") == "command":
        return cmd_clauses(r)
    bad = list(r.get("problems", []))
    acc = r.get("accept", {})
    for c in COLS:
        if acc.get(f"{c}@A-1") is not False:
            bad.append(f"{c}: the LP one tick before the frozen tick {'STARTED the normal' if acc.get(f'{c}@A-1') else 'was not read'}")
        if acc.get(f"{c}@A") is not True:
            bad.append(f"{c}: the LP on the frozen tick did not start the normal")
    w = r.get("window", {})
    if not w:
        bad.append("the tech window: not measured")
    elif w.get("k1") != w.get("k7") or not w.get("k7_as_k1"):
        bad.append(f"the tech window: k = 1 {'techs' if w.get('k1') else 'does not tech'}, k = 7 {'techs' if w.get('k7') else 'does not tech'}, "
                   "not ending alike (the window's outcome is not uniform)")
    if w.get("k8", True):
        bad.append("the tech window: k = 8 TECHS (the window is 1..7)")
    return bad


# ---------------------------------------------------------------- THE COMMAND THROWS AND GRABS (TR_FAMILY=command; #330)
# The maintainer, 2026-10-28: "Whiff recovery + techability" — the workbook's command-throw recovery is the WHIFF profile
# (startup / active / recovery) and its throw tech is empty on every row. Per event of tools/command_throw_rigs.py (its
# non-motion events that HOLD in #229's frozen expectation, tests/expected/command_throws.tsv): the WHIFF — the same input
# from the wide pins (the far pair 150 px further out each, no walk-in) — and its ACTIONABLE tick from the press (the
# first one-frame LP that starts the normal, the tick before never); the TECH — at contact, P2's back + HP and back + HK
# at 1 and 7 ticks after the hold, against the contact control. Level-0 re-timings (build/agent211/t330 cmd_feas_gen.py):
# Pit of Blame's sweep set-up and Victor's air 720 scaled by 17/14 (the level-6 ticks per frame); Cryptic Needle's whiff
# with P2 airborne when the rush arrives (from 476 px it still grabs). Pit of Blame has NO whiff: with no knocked-down
# victim an LP one tick after its press already starts the normal (its input draws no move). Gerdenheim 3 lands only on
# alternate slots (a landed grab swaps the sides, and the next air 720 misses), so its tech rig puts every measured
# event on a grabbing slot (fillers between).
CMD_WIDE = (402, 878)


def cmd_events():
    """[(rig, tab, row, label, event)]: the non-motion command events that hold in #229's frozen expectation"""
    import command_throw_rigs as ctr
    exp = Path(__file__).resolve().parent.parent / "tests/expected/command_throws.tsv"
    held = {(f[0], f[2]) for f in (l.rstrip("\n").split("\t") for l in open(exp) if l.strip() and not l.startswith("#"))
            if len(f) > 3 and f[3] == "yes"}
    out = []
    for tab, evs in ctr.THROWS.items():
        for i, e in enumerate([e for e in evs if not e[1].startswith("motion ")]):
            if (tab, e[1]) in held:
                out.append((f"{tab}_cmd_{i}", tab, e[0], e[1], e))
    return out


def cmd_recipe(tab, ev, ver):
    import command_throw_rigs as ctr
    row, label, rec, meter = ev[:4]
    poff = ev[5] if len(ev) > 5 else None
    if tab == "AN" and "sweep" in label or tab == "VI" and "720" in label:
        rec = [(round(r[0] * 17 / 14), round(r[0] * 17 / 14) + (r[1] - r[0])) + tuple(r[2:]) for r in rec]
        if poff is not None:
            poff = round(poff * 17 / 14)
    if ver == "wide" and tab == "MO" and "6,HP,MP,LP,6" in label:
        rec = rec + [(33, 35, "U", "p2")]        # airborne when the needle arrives (its hold lands 34 after the press)
    walk = (ev[4] if len(ev) > 4 else 150) if ver == "contact" else 0
    return rec, (ctr._press_off(rec) if poff is None else poff), walk, meter


def cmd_no_whiff(label):
    return "sweep" in label


def _cmd_write(path, tab, meta, items):
    """items: [(label, ver, rec, press offset, walk, meter)] -> <path>.{rpl,json}, events GAP apart, level 0, RNG pinned"""
    import command_throw_rigs as ctr
    import vanilla_frames as vf
    import vanilla_join_rig as vj
    cid = vf.CHARS[tab][0]
    vic = int(os.environ["TR_VICTIM"], 16) if os.environ.get("TR_VICTIM") else ctr.VICTIM
    vic = 0x01 if cid == vic else vic
    lines = [nm.REPLAY17_PROLOGUE.rstrip()]
    t = t0 = nm.FIRST_EVENT + vj.WALKIN_SHIFT
    pokes = [f"{f}:ff8782:{cid:02x}" for f in (1400, 1450, 1500)] + [f"{f}:ff8b82:{vic:02x}" for f in (1400, 1450, 1500)]
    sched = dict(meta, sheet=tab, victim=f"{vic:#04x}", events=[])
    for label, ver, rec, poff, walk, meter in items:
        x1, x2 = nm.PIN["far"] if ver == "contact" else CMD_WIDE
        pokes += [f"{t - 230}:ff8410:{x1:04x}", f"{t - 230}:ff8810:{x2:04x}",
                  f"{t - 20}:ff8850:01200120", f"{t - 20}:ff8509:{'09' if meter else '00'}0000"]
        if walk < 150:
            pokes += [f"{t - 50 - walk}:ff8410:{x1:04x}", f"{t - 50 - walk}:ff8810:{x2:04x}"]
        if walk:
            lines.append(f"{t - 40 - walk}-{t - 40} p1=R")
        for r in rec:
            lines.append(f"{t + r[0]}-{t + r[1]} {r[3] if len(r) > 3 else 'p1'}={r[2]}")
        sched["events"].append({"input": label, "ver": ver, "frame": t, "press": t + poff})
        t += GAP
    lines.append(f"{t + 100} wait")
    assert t + 100 - t0 < 7500, "a rig must fit inside one round"
    f = t + 150
    sched["pokes"] = pokes + [f"2000-{f - 1}:ff8116:{LEVEL}", f"2363-{f - 1}:ff80d4:{RNG}"]
    sched["frames"] = f
    Path(str(path) + ".rpl").write_text("\n".join(lines) + "\n")
    Path(str(path) + ".json").write_text(json.dumps(sched, indent=1) + "\n")


def cmd_read_ticks(path):
    """{rig: (hold, whiff A or None)} from a ticks TSV (rig label hold whiff) or the full lines (sheet rig label hold whiff ...)"""
    out = {}
    for line in open(path):
        if line.startswith("#") or not line.strip() or line.startswith("rig\t"):
            continue
        f = line.rstrip("\n").split("\t")
        o = 0 if "_cmd_" in f[0] else 1
        out[f[o]] = (int(f[o + 2]), None if f[o + 3] == "-" else int(f[o + 3]))
    return out


def cmd_gen(ticks_path, out_dir, shift=0, tech_token=None, only=None):
    ticks = cmd_read_ticks(ticks_path)
    out = Path(out_dir); out.mkdir(parents=True, exist_ok=True)
    n = 0
    for rig, tab, row, label, ev in cmd_events():
        if only and rig not in only:
            continue
        hold, a = ticks[rig]
        meta = {"rig": rig, "key": row, "input": label}
        rec, poff, walk, meter = cmd_recipe(tab, ev, "contact")
        h = poff + hold
        toks = [tech_token] if tech_token else [nm.B["HP"], nm.B["HK"]]
        techs = [(f"tech{tk}@{k}", rec + [(h + k, h + k, "R" + tk, "p2")]) for tk in toks for k in (1, 7)]
        base = [(f"{label} sacrificial first event", "contact", rec, poff, walk, meter)]
        meas = [(f"{label} teched control", "contact", rec, poff, walk, meter)] + \
               [(f"{label} teched {lab}", "contact", r, poff, walk, meter) for lab, r in techs]
        if tab == "VI" and "720" in label:     # every measured event on a grabbing slot (odd slots): fillers between
            items = base + [x for m in meas for x in ((f"{label} filler", "contact", rec, poff, walk, meter), m)]
        else:
            items = base + meas
        _cmd_write(out / f"tr_{rig}_teched", tab, dict(meta, case="teched"), items)
        n += 1
        if a is not None and not cmd_no_whiff(label):
            rec, poff, walk, meter = cmd_recipe(tab, ev, "wide")
            a += shift
            items = [(f"{label} sacrificial first event", "wide", rec, poff, walk, meter),
                     (f"{label} whiff control", "wide", rec, poff, walk, meter)]
            items += [(f"{label} whiff p1 LP@+{o} A={a}", "wide", rec + [(poff + o, poff + o, "1")], poff, walk, meter)
                      for o in (a - 1, a)]
            _cmd_write(out / f"tr_{rig}_whiff", tab, dict(meta, case="whiff"), items)
            n += 1
    print(f"wrote {n} rigs to {out}")


def cmd_rows(rigs_dir, traces_dir):
    rigs = {}
    for j in sorted(Path(rigs_dir).glob("tr_*.json")):
        s = json.loads(j.read_text()); tp = Path(traces_dir) / f"{j.stem}.txt"
        rigs.setdefault(s["rig"], {})[s["case"]] = (s, _trace(tp) if tp.exists() else None)
    for rig, cases in sorted(rigs.items()):
        r = {"family": "command", "rig": rig, "problems": []}
        for case in ("teched", "whiff"):
            if case not in cases:
                continue
            s, tr = cases[case]
            r.update({"sheet": s["sheet"], "key": s["key"], "input": s["input"]})
            if tr is None:
                r["problems"].append(f"no trace for the {case} rig"); continue
            ev = s["events"]
            c = next(e["press"] for e in ev if e["input"].endswith(" control"))
            if c + L not in tr:
                r["problems"].append(f"the {case} trace ends before the control's +{L}"); continue
            if case == "teched":
                hold = next((f - c for f in range(c - 5, c + 150) if tr[f]["p1thr"] == 1 and tr[f]["p2thr"] in (255, -1)), None)
                r["hold"] = hold
                if hold is None:
                    r["problems"].append("the contact control never holds")

                def sig(p):
                    return _loss(tr, p), next((f - p for f in range(p + 1, p + L) if _st(tr, f, "p2") == 0x02000002), None)
                base = sig(c)
                r["loss"] = list(base[0]) if base[0] else None
                w = {}
                for e in ev:
                    m = re.search(r" tech(\w+)@(\d+)$", e["input"])
                    if m:
                        x = sig(e["press"])
                        w.setdefault(int(m.group(2)), []).append(x[0] is None or base[0] is None or x[0][0] != base[0][0]
                                                                 or (x[1] is None) != (base[1] is None)
                                                                 or bool(x[1] and base[1] and abs(x[1] - base[1]) > 10))
                r["window"] = {"k1": any(w.get(1, [])), "k7": any(w.get(7, [])),
                               "k7_as_k1": w.get(1) == w.get(7), "k8": False}
            else:
                for e in ev:
                    m = re.search(r" p1 LP@\+(\d+) A=(\d+)$", e["input"])
                    if m:
                        o, a = int(m.group(1)), int(m.group(2))
                        r["whiff"] = a
                        r.setdefault("accept", {})[f"whiff@{'A-1' if o == a - 1 else 'A'}"] = _accepted(tr, e["press"], c, o, "p1")
                        if o == a:
                            r["state"] = f"{_st(tr, c + a, 'p1'):08x}"
        print(json.dumps(r))


def cmd_full_line(r):
    lo = r.get("loss") or ["-", "-"]
    return "\t".join(str(v) for v in (r.get("sheet"), r.get("rig"), r.get("input"), r.get("hold", "-"), r.get("whiff", "-"),
                                      r.get("state", "-"), f"{lo[0]}/{lo[1]}", window(r)))


def cmd_clauses(r):
    bad = list(r.get("problems", []))
    acc = r.get("accept", {})
    if "whiff" in r:
        if acc.get("whiff@A-1") is not False:
            bad.append("whiff: the LP one tick before the frozen tick STARTED the normal")
        if acc.get("whiff@A") is not True:
            bad.append("whiff: the LP on the frozen tick did not start the normal")
    w = r.get("window", {})
    if not w:
        bad.append("the tech window: not measured")
    elif not w.get("k7_as_k1"):
        bad.append(f"the tech window: k = 1 {'techs' if w.get('k1') else 'does not tech'}, k = 7 {'techs' if w.get('k7') else 'does not tech'}, "
                   "not ending alike (the window's outcome is not uniform)")
    return bad


HEADER = ("# tests/expected/throw_recovery.tsv — the vsavj ground throws' recovery and throw tech (#330, 14z-211), FROZEN by\n"
          "# `tools/throw_recovery_rigs.py freeze`. Columns: sheet key input sig — `sig` is the first 16 hex of SHA-256 over the\n"
          "# event's full line (thrower/victim ticks thrown and teched, the controls' +0x04 there, the victim's losses). The\n"
          "# per-move numbers are NOT in the tree (the 14z-126 frame-data ruling, #319): the full lines live outside it (TR_FULL).")


def freeze(rows_path, exp_path):
    rs = [json.loads(line) for line in open(rows_path) if line.strip()]
    bad = [(r["rig"], b) for r in rs for b in clauses(r)]
    if bad:
        for rig, b in bad:
            print(f"REFUSED {rig}: {b}")
        return 1
    fulls = [full_line(r) for r in rs]
    Path(full_path()).parent.mkdir(parents=True, exist_ok=True)
    Path(full_path()).write_text("# the FULL lines behind tests/expected/throw_recovery.tsv's hashes (outside the tree): sheet key "
                                 "input " + " ".join(COLS) + " " + " ".join("state_" + c for c in COLS) +
                                 " loss_thrown loss_teched window\n" + "\n".join(fulls) + "\n")
    Path(exp_path).write_text(HEADER + (f"\n# The victim: {os.environ['TR_VICTIM']} (TR_VICTIM; the thrower's own id -> 0x01)."
                                        if os.environ.get("TR_VICTIM") else "") + "\n" + "\n".join(hashed(f) for f in fulls) + "\n")
    print(f"froze {len(fulls)} events into {exp_path} (full lines: {full_path()})")
    return 0


def expect(rows_path, exp_path):
    want = {tuple(l.split("\t")[:3]): l.rstrip("\n") for l in open(exp_path) if l.strip() and not l.startswith("#")}
    wfull = {}
    if os.path.exists(full_path()):
        wfull = {tuple(l.split("\t")[:3]): l.rstrip("\n") for l in open(full_path()) if l.strip() and not l.startswith("#")}
    bad, seen = 0, set()
    for line in open(rows_path):
        if not line.strip():
            continue
        r = json.loads(line); full = full_line(r); got = hashed(full); k = tuple(got.split("\t")[:3]); seen.add(k)
        fails = clauses(r)
        fw = wfull.get(k, "").split("\t")
        wi = 7 if r.get("family") == "command" else 13
        if len(fw) > wi and fw[wi] != window(r):
            fails.append(f"the tech window reads {window(r)}, frozen {fw[wi]}")
        if got != want.get(k):
            fails.append(f"its line differs from the frozen one\n    got  {got}\n    want {want.get(k)}\n    run  {full}\n"
                         f"    was  {wfull.get(k, '(no full line outside the tree)')}")
        if fails:
            bad += 1
            for f in fails:
                print(f"BAD {k}: {f}")
        else:
            print(f"ok  {got}")
    for k in sorted(set(want) - seen):
        bad += 1; print(f"BAD {k}: frozen but not measured")
    print(f"{len(seen)} event(s), {bad} bad")
    return 1 if bad else 0


def main():
    a = sys.argv[1:]
    if not a:
        print(__doc__); return 2
    if a[0] == "gen":
        opts = {"shift": 0, "tech_token": None, "late_tech": NOTECH_K, "only": None}
        pos, i = [], 1
        while i < len(a):
            if a[i] == "--shift": opts["shift"] = int(a[i + 1]); i += 2
            elif a[i] == "--tech-token": opts["tech_token"] = a[i + 1]; i += 2
            elif a[i] == "--late-tech": opts["late_tech"] = int(a[i + 1]); i += 2
            elif a[i] == "--only": opts["only"] = set(a[i + 1].split(",")); i += 2
            else: pos.append(a[i]); i += 1
        if os.environ.get("TR_FAMILY") == "command":
            opts.pop("late_tech"); cmd_gen(pos[0], pos[1], **opts); return 0
        gen(pos[0], pos[1], **opts); return 0
    if a[0] == "rows":
        (cmd_rows if os.environ.get("TR_FAMILY") == "command" else rows)(a[1], a[2]); return 0
    if a[0] == "freeze":
        return freeze(a[1], a[2])
    if a[0] == "expect":
        return expect(a[1], a[2])
    if a[0] == "ticks":
        p = a[1] if len(a) > 1 else full_path()
        inp = {r: i for r, _t, _k, i, *_ in events()}
        print("rig\tinput\t" + "\t".join(COLS))
        for rig, t in sorted(read_ticks(p).items()):
            print(rig + "\t" + inp[rig] + "\t" + "\t".join(str(t[c]) for c in COLS))
        return 0
    print(__doc__); return 2


if __name__ == "__main__":
    sys.exit(main())
