#!/usr/bin/env python3
"""vanilla_pursuit_rigs.py — the vsavj PURSUITS for the community cross-check (GitHub #229; rebuilt 14z-205 from the
14z-194 method, whose scratch rigs were lost with ERIS's files).

  python3 tools/vanilla_pursuit_rigs.py sweep <out dir>                 discovery rigs: per character and button, the
                                                                       knockdown then ONE U+button press per event at
                                                                       a swept offset (the press window measured)
  python3 tools/vanilla_pursuit_rigs.py sweeprows <rig.json> <trace>    one row per sweep event (JSON lines)

THE RIG (tools/ground_throw_rigs.py's walk-in, tools/name_moves.py's tokens): the character FORCED on P1 by the
early-window poke, P2 Victor 0x03 (Demitri 0x01 when P1 is Victor), REPLAY17's prologue; per EVENT both fighters
pinned to the far pair at t-230, P1 walks right t-190..t-40 to contact, a 40-frame pause, the KNOCKDOWN at t (2HK —
Jedah's 5HK, since his 2HK never enables a pursuit, page "The pursuits"), then ONE U+button press (held 3 frames) at
t+offset. Before each event P2's two HP words are re-pinned to 288 and P1's stock and meter to 0 (1 stock for an ES
event). The instrument is tests/lua/field_trace.lua (no debugger: its frame_done count is the emulated count).

WHAT A SWEEP ROW CARRIES: P2's +0x117 (the downed flag the attacker-side pursuit check reads, vsavj 0x27B0E — the
low byte of the word at +0x116) at the press frame, P1's distinct (seq, sub) states from the press in order (a
pursuit STARTS when P1 enters seq 0x0E), P2's red/white HP falls from the press, and P1's stock at the press and
40 frames after it (the stock BEFORE the press: an ES pursuit spends it on the press frame)."""
import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import name_moves as nm  # noqa: E402
import vanilla_frames as vf  # noqa: E402
import vanilla_join_rig as vj  # noqa: E402

VICTIM = 0x03
GAP = 450
OFFSETS = list(range(26, 86, 4))   # 15 offsets, frames after the knockdown press
PURSUIT_SEQ = 0x0E   # P1's seq on a pursuit (8P / 8K)
ES_PURSUIT_SEQ = 0x10   # on an ES pursuit (8PP / 8KK), measured 14z-205 on Demitri: entered on the press frame,
                        # the stock spent on that same frame
FIELDS = ("ff841c:l:node,ff8406:b:seq,ff8407:b:sub,ff8509:b:stock,ff850a:w:meter,ff8410:w:x,ff8414:w:y,"
          "ff8850:w:p2hp,ff8852:w:p2white,ff8806:b:p2seq,ff8916:w:p2f116,ff8810:w:p2x")
KNOCK = {"JE": ("5HK", [(0, 2, nm.B["HK"])])}
DEFAULT_KNOCK = ("2HK", [(0, 3, "D" + nm.B["HK"])])
BUTTONS = {"P": "LP", "K": "LK", "PP": "PP", "KK": "KK"}


def victim_for(cid):
    return 0x01 if cid == VICTIM else VICTIM


def build(tab, events, title):
    """events: [(name, offset, button key, stock)] -> (rpl text, schedule dict)."""
    cid = vf.CHARS[tab][0]
    vic = victim_for(cid)
    x1, x2 = nm.PIN["far"]
    kname, krec = KNOCK.get(tab, DEFAULT_KNOCK)
    lines = [f"# #229 {title} — {tab} ({cid:#04x}) on vsavj, victim {vic:#04x}",
             "# (tools/vanilla_pursuit_rigs.py; DO NOT hand-edit, regenerate). Select prologue from replay 17",
             "# (the characters are FORCED by the early-window poke, so the cursor path does not matter).",
             nm.REPLAY17_PROLOGUE.rstrip()]
    t = t0 = nm.FIRST_EVENT + vj.WALKIN_SHIFT
    sched = {"char": f"{cid:#04x}", "sheet": tab, "victim": f"{vic:#04x}", "gap": GAP, "knock": kname, "events": []}
    pokes = [f"{f}:ff8782:{cid:02x}" for f in (1400, 1450, 1500)] + [f"{f}:ff8b82:{vic:02x}" for f in (1400, 1450, 1500)]
    for name, off, bk, stock in events:
        pokes += [f"{t - 230}:ff8410:{x1:04x}", f"{t - 230}:ff8810:{x2:04x}",
                  f"{t - 20}:ff8850:01200120", f"{t - 20}:ff8509:{stock:02x}0000"]
        lines.append(f"{t - 190}-{t - 40} p1=R")
        for a, bb, tok in krec:
            lines.append(f"{t + a}-{t + bb} p1={tok}")
        if off is not None:
            lines.append(f"{t + off}-{t + off + 2} p1=U{nm.B[BUTTONS[bk]]}")
        sched["events"].append({"name": name, "frame": t, "press": None if off is None else t + off,
                                "offset": off, "button": bk, "stock": stock})
        t += GAP
    end = t + 100
    lines.append(f"{end} wait")
    assert end - t0 < 7500, "a rig must fit inside one round"
    sched["pokes"] = pokes
    sched["frames"] = end + 50
    return "\n".join(lines) + "\n", sched


def sweep(out_dir):
    out = Path(out_dir); out.mkdir(parents=True, exist_ok=True)
    n = 0
    for tab in vf.CHARS:
        for bk, stock in (("P", 0), ("K", 0), ("PP", 1)):
            evs = [(f"{bk}@{o}", o, bk, stock) for o in OFFSETS]
            rpl, sched = build(tab, evs, f"pursuit sweep {bk}")
            (out / f"sw_{tab}_{bk}.rpl").write_text(rpl)
            (out / f"sw_{tab}_{bk}.json").write_text(json.dumps(sched, indent=1) + "\n")
            n += 1
    print(f"wrote {n} sweep rigs to {out}")


def trace(path):
    fr = {}
    done = False
    for ln in open(path, errors="replace"):
        if ln.startswith("FIELDSUMMARY"):
            done = True
        if not ln.startswith("F "):
            continue
        p = ln.split()
        kv = {}
        for x in p[2:]:
            if "=" in x:
                k, v = x.split("=", 1)
                try:
                    kv[k] = int(v)
                except ValueError:
                    pass
        fr[int(p[1])] = kv
    if not done:
        raise SystemExit(f"FAIL: {path}: no FIELDSUMMARY — the trace did not complete")
    return fr


def event_view(fr, e, span=200):
    """One event from the trace: the flag at the press, P1's (seq, sub) states from the press, P2's falls."""
    press = e["press"] if e["press"] is not None else e["frame"] + 20
    states, prev = [], None
    for f in range(press, press + span):
        s = fr.get(f)
        if not s:
            continue
        cur = (s.get("seq"), s.get("sub"))
        if cur != prev:
            states.append((f - press, cur[0], cur[1]))
            prev = cur
    falls, ph = [], None
    for f in range(press - 1, press + span):
        s = fr.get(f)
        if not s:
            continue
        hp = (s.get("p2hp"), s.get("p2white"))
        if ph is not None and None not in hp and None not in ph:
            dr, dw = ph[0] - hp[0], ph[1] - hp[1]
            if (dr > 0 or dw > 0) and dr < 200 and dw < 200:
                falls.append((f - press, max(dr, 0), max(dw, 0)))
        ph = hp
    flag = (fr.get(press, {}).get("p2f116", 0) or 0) & 0xFF
    st = lambda f: fr.get(f, {}).get("stock")
    want = ES_PURSUIT_SEQ if e.get("button") in ("PP", "KK") else PURSUIT_SEQ
    started = next((o for o, sq, _ in states if sq == want), None)
    other = next((o for o, sq, _ in states if sq in (PURSUIT_SEQ, ES_PURSUIT_SEQ) and sq != want), None)
    return {"press": press, "flag": flag, "started": started, "states": states[:12], "falls": falls,
            "other_pursuit": other, "stock_press": st(press - 1), "stock_after": st(press + 40)}


def sweeprows(sched_path, trace_path):
    sched = json.loads(Path(sched_path).read_text())
    fr = trace(trace_path)
    for e in sched["events"]:
        v = event_view(fr, e)
        knock = [x for x in event_view(fr, dict(e, press=e["frame"]), span=e["offset"] or 40)["falls"]]
        print(json.dumps({"sheet": sched["sheet"], "name": e["name"], "offset": e["offset"], "knock_falls": knock, **v}))


def finesweep(summary_path, out_dir):
    """1-frame sweeps across each coarse connect band (from sweep_summary.out): offsets from the first connecting
    offset - 4 to the last + 4, split into rigs of at most 15 events."""
    import re
    out = Path(out_dir); out.mkdir(parents=True, exist_ok=True)
    n = 0
    for ln in open(summary_path):
        m = re.match(r"sw_(\w\w)_(P|K|PP|KK)\s.*connected \[([0-9, ]*)\]", ln)
        if not m or not m.group(3).strip():
            continue
        tab, bk = m.group(1), m.group(2)
        con = [int(x) for x in m.group(3).split(",")]
        offs = list(range(con[0] - 4, con[-1] + 5))
        for part in range(0, len(offs), 15):
            chunk = offs[part:part + 15]
            evs = [(f"{bk}@{o}", o, bk, 1 if bk in ("PP", "KK") else 0) for o in chunk]
            rpl, sched = build(tab, evs, f"pursuit fine sweep {bk}")
            name = f"fs_{tab}_{bk}_{part // 15}"
            (out / f"{name}.rpl").write_text(rpl)
            (out / f"{name}.json").write_text(json.dumps(sched, indent=1) + "\n")
            n += 1
    print(f"wrote {n} fine-sweep rigs to {out}")


def walk_signed(img, table):
    """{seq: [node addr, ...]} for one anim index table, its word offsets read SIGNED, as the engine adds them (a
    68000 word add). COPIED from tools/specials_b_rigs.py walk_signed (#229 F2, 14z-205), which measured negative
    offsets on 11 characters; tools/anim_nodes.py's walk_table reads them unsigned and is not edited here (the #229
    parallel run's brief). Same node rules: flags bit 7 = link at +0x18, bit 6 = hold, else sequential; the entry
    count bounded by the smallest POSITIVE offset.
    RESOLVED #318 (14z-210): tools/anim_nodes.py's walk_table reads the offsets SIGNED too since #318, so the
    "reads them unsigned" above describes the tool before it. This local walk stays: the frozen #229 identities
    were measured with it, and its entry bound differs from the tool's (it skips odd words instead of ending)."""
    import anim_nodes
    words, k = [], 0
    while k < 1024:
        w = int.from_bytes(img[table + 2 * k:table + 2 * k + 2], "big", signed=True)
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
            nodes.append(a)
            fl = img[a + 1]
            if fl & 0x80:
                a = int.from_bytes(img[a + 0x18:a + 0x1C], "big")
            elif fl & 0x40:
                break
            else:
                a += anim_nodes.NODE
        out[seq] = nodes
    return out


def chain_members(img, cid):
    """{node: 'table:seq'} over the fighter tables a2, a, b, c, offsets read SIGNED; a2 first and the first chain
    to claim a node names it (tools/vanilla_join_rig.py node_map's order, which an overrunning table-a chain made
    necessary). By MEMBERSHIP, not by start node: a chain's first node can last one tick, and the frame_done sample
    steps past it (Sasquatch's 8K entered a2:0x45 at its second node, 14z-205)."""
    rows = vf.bank_rows(Path(__file__).resolve().parent.parent / "build/manifest/bank_map.toml")
    out = {}
    for tn in ("a2", "a", "b", "c"):
        tbl = vf.row_ptr(img, rows["anim_index_" + tn], cid)
        for seq, nodes in walk_signed(img, tbl).items():
            for n in nodes:
                out.setdefault(n, f"{tn}:{seq:#04x}")
    return out


TAP = "ff841c,8"    # P1 +0x1C..+0x23: the anim pointer and the node countdown (tools/tick_durations.py's instrument)


def ticks(tap_path, sched_path, field_trace, img_path):
    """STARTUP and ACTIVE in ENGINE TICKS per event (14z-194's method, rebuilt): a write tap over P1 +0x1C..+0x23
    (tests/lua/tap_writes.lua, no debugger) sees every node entry (PRG:0x027EE8/0x027EEC) and every tick
    (PRG:0x027F70 `subq.b #1,$20(a6)`), parsed by tools/tick_durations.py. From the first node entry into the
    pursuit's chain (its start, from the FIELD leg) to the frame P1 leaves the pursuit state (seq 0x0E / 0x10):
    STARTUP = the ticks spent on non-attack nodes before the first attack node (node +10 != 0, the attack-box
    index), ACTIVE = the ticks spent on attack nodes, with the RUNS of consecutive attack ticks (a multi-hit's
    shape). A frame-rate trace cannot measure these: ~16% of frames advance the countdown by two or more ticks
    (tests/test_tick_durations.sh), and the leap chains hold on game logic."""
    import tick_durations as td
    sched = json.loads(Path(sched_path).read_text())
    img = Path(img_path).read_bytes()
    cid = int(sched["char"], 16)
    members = chain_members(img, cid)
    fr = trace(field_trace)
    ev = td.parse(tap_path, 0xFF8400)
    out = []
    for e in sched["events"]:
        v = event_view(fr, e, SPAN)
        rec = {"sheet": sched["sheet"], "event": e["name"], "startup_ticks": None, "active_ticks": None, "runs": None}
        if v["started"] is None:
            out.append(rec); continue
        f0 = e["press"] + v["started"]
        n0 = (fr.get(f0, {}).get("node") or 0) & 0xFFFFFFFF
        chain = members.get(n0)
        f_end = next((f for f in range(f0 + 1, f0 + 400) if fr.get(f, {}).get("seq") not in (PURSUIT_SEQ, ES_PURSUIT_SEQ)), f0 + 400)
        i0 = next((i for i, (k, f, val) in enumerate(ev) if k == "ptr" and f0 - 1 <= f <= f_end and members.get(val) == chain), None)
        if i0 is None:
            rec["error"] = f"no node entry into {chain} near f{f0}"; out.append(rec); continue
        cur, startup, active, seen, runs, run = ev[i0][2], 0, 0, False, [], 0
        for k, f, val in ev[i0 + 1:]:
            if f >= f_end:
                break
            if k == "ptr":
                cur = val
                continue
            if img[cur + 10]:
                seen = True; active += 1; run += 1
            else:
                if run:
                    runs.append(run); run = 0
                if not seen:
                    startup += 1
        if run:
            runs.append(run)
        rec.update(startup_ticks=startup if seen else None, active_ticks=active, runs=runs, chain=chain,
                   start_frame=f0, end_frame=f_end)
        out.append(rec)
    for r in out:
        print(json.dumps(r))


# BANDS[tab][button] = (lo, hi): the CONNECT band. 8P and 8PP: the SINGLE-OFFSET edges (one press per run, 14z-205,
# build/agent205/t229/f6_pursuits/edge_summary.out: all 30 clean, 8PP's equal to 8P's), which the gate's band legs
# freeze. 8K and 8KK: the multi-event 1-frame sweeps' bands (fine_summary.out, fine_summary_kk.out; Felicia's top
# from a sweep to +52) — NOT single-offset, not frozen. In a multi-event rig an edge moves 1-2 frames with the events
# before it (39 of 60 bands missed no/yes/yes/no there; the single-offset edges differ from the multi-event ones on
# BI BU DE SA VI's low edge and MO SA's high edge by one frame).
BANDS = {"AN": {"P": (39, 49), "K": (39, 49), "PP": (39, 49), "KK": (39, 49)}, "AU": {"P": (35, 49), "K": (35, 49), "PP": (35, 51), "KK": (35, 51)}, "BI": {"P": (46, 57), "K": (45, 57), "PP": (46, 57), "KK": (45, 57)}, "BU": {"P": (33, 46), "K": (32, 46), "PP": (33, 46), "KK": (32, 46)}, "DE": {"P": (37, 50), "K": (36, 50), "PP": (37, 50), "KK": (36, 50)}, "FE": {"P": (32, 46), "K": (32, 45), "PP": (32, 46), "KK": (32, 45)}, "GA": {"P": (40, 46), "K": (40, 46), "PP": (40, 46), "KK": (40, 46)}, "JE": {"P": (62, 79), "K": (62, 79), "PP": (62, 79), "KK": (62, 79)}, "LE": {"P": (53, 63), "K": (53, 63), "PP": (53, 63), "KK": (53, 63)}, "LI": {"P": (48, 57), "K": (48, 57), "PP": (48, 57), "KK": (48, 57)}, "MO": {"P": (38, 46), "K": (38, 45), "PP": (38, 46), "KK": (38, 45)}, "QB": {"P": (40, 46), "K": (40, 46), "PP": (40, 46), "KK": (40, 46)}, "SA": {"P": (41, 55), "K": (40, 54), "PP": (41, 55), "KK": (40, 54)}, "VI": {"P": (41, 52), "K": (40, 52), "PP": (41, 52), "KK": (40, 52)}, "ZA": {"P": (40, 48), "K": (40, 48), "PP": (40, 48), "KK": (40, 48)}}


def band_events(tab, buttons):
    return [(f"{bk}@{o}", o, bk, 1 if bk in ("PP", "KK") else 0) for bk in buttons
            for lo, hi in [BANDS[tab][bk]] for o in (lo - 1, lo, hi, hi + 1)]


BAND_BUTTONS = ("P", "PP")   # 8K / 8KK's bands equal 8P / 8PP's in every multi-event sweep; their single-offset
                              # edges are not measured, so not frozen


def genbands(out_dir):
    """The gate's BAND legs: one SINGLE-OFFSET rig (single()) per (character, 8P / 8PP, offset) at lo-1, lo, hi,
    hi+1 — 120 rigs, written by the gate into its work dir from BANDS (deterministic; this file is their source)."""
    n = 0
    for tab in BANDS:
        for bk in BAND_BUTTONS:
            lo, hi = BANDS[tab][bk]
            for o in (lo - 1, lo, hi, hi + 1):
                single(tab, bk, o, out_dir, "pb"); n += 1
    print(f"wrote {n} band rigs to {out_dir}")


def bandrows(sched_path, trace_path):
    """One row per band event: sheet, button, offset, connected (the pursuit started and P2's HP fell after it)."""
    sched = json.loads(Path(sched_path).read_text())
    fr = trace(trace_path)
    for e in sched["events"]:
        v = event_view(fr, e, SPAN)
        con = v["started"] is not None and any(f[0] >= v["started"] for f in v["falls"])
        print("\t".join((sched["sheet"], e["button"], str(e["offset"]), "yes" if con else "no")))


BAND_HEADER = ("# tests/expected/vanilla_pursuit_bands.tsv — the vsavj pursuit CONNECT-band edges (#229, 14z-205), FROZEN by\n"
               "# `tools/vanilla_pursuit_rigs.py` bandrows over the gate's single-offset band rigs (genbands): per character and 8P/8PP, the\n"
               "# outcome (connected: the pursuit started and P2's HP fell after it) at lo-1, lo, hi, hi+1 frames after the\n"
               "# knockdown press. Columns: sheet button offset connected. An edge that moves flips a row.")


def bandexpect(got_path, exp_path):
    want = {tuple(l.split("\t")[:3]): l.rstrip("\n") for l in open(exp_path) if l.strip() and not l.startswith("#")}
    got = {tuple(l.split("\t")[:3]): l.rstrip("\n") for l in open(got_path) if l.strip()}
    bad = [k for k in sorted(set(want) | set(got)) if want.get(k) != got.get(k)]
    for k in bad:
        print(f"BAD {k}: got {got.get(k)!r} want {want.get(k)!r}")
    shape = {}
    for k, l in got.items():
        shape.setdefault(k[:2], []).append((int(k[2]), l.split("\t")[3]))
    clean = sum(1 for v in shape.values() if [o for _, o in sorted(v)] == ["no", "yes", "yes", "no"])
    print(f"{len(got)} band event(s), {len(bad)} bad; {clean} of {len(shape)} bands read no/yes/yes/no at lo-1/lo/hi/hi+1")
    return 1 if bad else 0



def single(tab, bk, off, out_dir, prefix):
    """ONE event per rig — the knockdown then U+button at `off` — so every offset is measured from the SAME context
    (the rig's first event). Measured 14z-205: in a multi-event rig a band edge moves by 1-2 frames with the events
    before it (39 of 60 bands missed no/yes/yes/no at the 1-frame sweep's edges when probed later in one rig); the
    14z-194 rigs were "one leg per offset" for that reason."""
    out = Path(out_dir); out.mkdir(parents=True, exist_ok=True)
    rpl, sched = build(tab, [(f"{bk}@{off}", off, bk, 1 if bk in ("PP", "KK") else 0)], "pursuit single-offset rig")
    name = f"{prefix}_{tab}_{bk}_{off}"
    (out / f"{name}.rpl").write_text(rpl)
    (out / f"{name}.json").write_text(json.dumps(sched, indent=1) + "\n")
    return name


def edgesweep(out_dir):
    """The single-offset sweep around each P and PP band's edges: lo-2..lo+2 and hi-2..hi+2."""
    n = 0
    for tab in BANDS:
        for bk in ("P", "PP"):
            lo, hi = BANDS[tab][bk]
            for o in sorted(set(range(lo - 2, lo + 3)) | set(range(hi - 2, hi + 3))):
                single(tab, bk, o, out_dir, "es"); n += 1
    print(f"wrote {n} single-offset rigs to {out_dir}")


# ---------------------------------------------------------------- the GATE rigs (one per character)
# PRESS[tab] = (P offset, K offset): frames after the knockdown press, each INSIDE the band where the pursuit both
# STARTS and CONNECTS on the sweep (build/agent205/t229/f6_pursuits/sweep_summary.out; the band's edges are in that
# file, not frozen here). The ES events press at the same offsets with one stock.
PRESS = {"AN": (44, 44), "AU": (42, 42), "BI": (51, 51), "BU": (39, 39), "DE": (43, 43), "FE": (39, 39), "GA": (43, 43), "JE": (71, 71), "LE": (58, 58), "LI": (53, 53), "MO": (42, 42), "QB": (43, 43), "SA": (47, 47), "VI": (46, 46), "ZA": (44, 44)}   # the 1-frame band middles, 14z-205 (fine_summary.out)
SPAN = 200          # frames from the press read for an event (the longest pursuit, Zabel's, lands inside it)
LAND = 2            # a staged record lands on its probe frame + 1 (ground_throw_rigs.LAND, measured there)
APPLIER = "0189ea"


def gate_events(tab):
    p, k = PRESS[tab]
    return [("P", p, "P", 0), ("K", k, "K", 0), ("ES_PP", p, "PP", 1), ("ES_KK", k, "KK", 1), ("CONTROL", p, "P", 0)]


def gen(out_dir):
    """One rig per character: P, K, ES (PP), ES (KK) after the knockdown, then the CONTROL — the same U+LP at the
    same offset with NO knockdown (the event's knockdown tokens are dropped)."""
    out = Path(out_dir); out.mkdir(parents=True, exist_ok=True)
    for tab in PRESS:
        rpl, sched = build(tab, gate_events(tab), "pursuit gate rig")
        # the CONTROL event: drop its knockdown lines (the last event's knockdown tokens, after its walk-in line)
        ctl = sched["events"][-1]
        kname, krec = KNOCK.get(tab, DEFAULT_KNOCK)
        drop = {f"{ctl['frame'] + a}-{ctl['frame'] + bb} p1={tok}" for a, bb, tok in krec}
        lines = [l for l in rpl.splitlines() if l not in drop]
        assert len(lines) == len(rpl.splitlines()) - len(krec), "the control's knockdown was not found"
        ctl["knockdown"] = False
        for e in sched["events"][:-1]:
            e["knockdown"] = True
        sched["dumps"] = [[e["press"] - 1, e["press"] + SPAN] for e in sched["events"]]
        (out / f"pu_{tab}.rpl").write_text("\n".join(lines) + "\n")
        (out / f"pu_{tab}.json").write_text(json.dumps(sched, indent=1) + "\n")
    print(f"wrote {len(PRESS)} rigs to {out}")


def dumps_spec(sched):
    """The probe leg's DUMPS: P2's two HP words on every frame of every event's window (LANDED is judged on the
    probe leg's OWN falls — a breakpoint stop skews its timeline, [VSP-129])."""
    return ";".join(f"{f}:ff8850-ff8853" for lo, hi in sched["dumps"] for f in range(lo, hi + 1))


def snaps(sched_path, rows_path):
    """SNAP_FRAMES: each event's first fall in the FIELD leg (no debugger), else its press + 30."""
    sched = json.loads(Path(sched_path).read_text())
    rows = {json.loads(l)["event"]: json.loads(l) for l in open(rows_path) if json.loads(l)["sheet"] == sched["sheet"]}
    out = []
    for e in sched["events"]:
        r = rows.get(e["name"])
        out.append(str(e["press"] + (r["falls"][0][0] if r and r["falls"] else 30)))
    print(",".join(out))


def _hp(d, f):
    import struct
    p = Path(d) / f"dump_{f}_ff8850.bin"
    b = p.read_bytes() if p.exists() else b""
    return struct.unpack(">hh", b) if len(b) == 4 else None


def own_proj_bounds(img, bank, cid):
    """The attacker's own PROJECTILE hitbox set: from her proj_hitbox_comp / proj_hitbox_base row (the lower of
    the two) to the nearest start of ANY character's projectile or fighter hitbox row above it, or of any bank
    row TABLE itself (the shape of tools/ground_throw_rigs.py own_bounds). The bank tables bound the LAST set
    (Jedah's): no character's row lies above it, and without them its bound ran to the end of the image, so the
    foreign-record control's shifted A3 read "own" on his four events (14z-205)."""
    mine = [vf.row_ptr(img, bank[k], cid) for k in ("proj_hitbox_base", "proj_hitbox_comp")]
    lo = min(mine)
    starts = {v["vsavj"] for v in bank.values()}
    for c in range(0x20):
        for k in ("proj_hitbox_base", "proj_hitbox_comp", "hitbox_base", "hitbox_comp"):
            try:
                starts.add(vf.row_ptr(img, bank[k], c))
            except Exception:
                continue
    return lo, min([x for x in starts if x > max(mine)] + [len(img)])


def rows(sched_path, field_trace, probe_dir, img_path, probe_extra="", tap_path=""):
    """One row per event: the FIELD leg (tests/lua/field_trace.lua, no debugger) gives the start, the flag, the
    chain, P2's falls, P1's meter and stock; the PROBE leg (replay_guard.lua -debug, a logging breakpoint at the
    fighter applier's record read PRG:0x0189EA) gives the records the game staged, each judged OWN (inside the
    attacker's attack table) and LANDED (a fall of P2's HP in the probe leg's own dumps within LAND frames)."""
    import ground_throw_rigs as gt
    import hitbox_records
    sched = json.loads(Path(sched_path).read_text())
    img = Path(img_path).read_bytes()
    cid = int(sched["char"], 16)
    bank = vf.bank_rows(Path(__file__).resolve().parent.parent / "build/manifest/bank_map.toml")
    lo_tab, hi_tab = gt.own_bounds(img, bank, cid)
    lo_pj, hi_pj = own_proj_bounds(img, bank, cid)
    members = chain_members(img, cid)
    nmap = vj.node_map(img, cid, signed=False)   # the pre-#318 UNSIGNED reader's label (tools/anim_nodes.py signed=False), kept only to report where the two differ
    fr = trace(field_trace)
    log = Path(probe_dir) / "run.log"
    probes = gt._probes(str(log)) if log.exists() else []     # absent while the FIELD leg dates the snapshots
    if probe_extra:   # `+<off>:<a3 hex>` or `+<off>:auto` (the rig's own first damaging record, planted where no fall is)
        off, a3s = probe_extra.split(":")
        if a3s == "auto":
            cand = [a3 for _, a3 in probes if (img[a3 + 8] & 0x1F) or (img[a3 + 9] & 0x1F)]
            a3s = f"{cand[0]:x}" if cand else ""
        if a3s:
            for e in sched["events"]:
                probes.append((e["press"] + int(off), int(a3s, 16)))
    tk = {}
    if tap_path and Path(tap_path).exists():
        import contextlib, io
        buf = io.StringIO()
        with contextlib.redirect_stdout(buf):
            ticks(tap_path, sched_path, field_trace, img_path)
        tk = {json.loads(l)["event"]: json.loads(l) for l in buf.getvalue().splitlines()}
    for e in sched["events"]:
        v = event_view(fr, e, SPAN)
        press = e["press"]
        t = tk.get(e["name"], {})
        # THE CHAIN the pursuit entered: the chain the node pointer sits in on the start frame, by the SIGNED walk;
        # `chain_unsigned` is what the pre-#318 unsigned walk (tools/anim_nodes.py signed=False) names at that node
        chain = chain_u = None
        if v["started"] is not None:
            n = (fr.get(press + v["started"], {}).get("node") or 0) & 0xFFFFFFFF
            chain, chain_u = members.get(n), nmap.get(n)
        # the METER FRACTION gained over the event (+0x10A; the ES stock spend is the separate stock clause — the
        # P events start at a fraction the knockdown paid, far below one stock, so no gain rolls into a stock)
        tot = lambda f: fr.get(f, {}).get("meter", 0) or 0
        # the probe leg's own falls
        pf, prev = set(), _hp(probe_dir, press - 1)
        dumped = 0
        for f in range(press, press + SPAN + 1):
            cur = _hp(probe_dir, f)
            dumped += cur is not None
            if cur and prev and (cur[0] < prev[0] or cur[1] < prev[1]):
                pf.add(f)
            prev = cur
        recs = []
        for f, a3 in probes:
            if not (press <= f <= press + SPAN):
                continue
            bb = img[a3:a3 + 0x20]
            # OWN: the attacker's own attack table, or her own PROJECTILE hitbox set — Bulleta's ES pursuit lands its
            # 12th hit from a record 0x27A into hers (14z-205), staged at the fighter applier all the same
            in_atk, in_pj = lo_tab <= a3 < hi_tab, lo_pj <= a3 < hi_pj
            recs.append({"frame": f, "a3": f"{a3:#x}", "own": in_atk or in_pj,
                         "idx": (a3 - lo_tab) // hitbox_records.REC if in_atk else (f"proj+{a3 - lo_pj:#x}" if in_pj else None),
                         "real": bb[8] & 0x1F, "white": bb[9] & 0x1F, "flags": (bb[8] | bb[9]) & 0xE0, "meter": bb[0x14],
                         "landed": any(f < d <= f + LAND for d in pf)})
        print(json.dumps({"sheet": sched["sheet"], "event": e["name"], "knockdown": e.get("knockdown"), "press": press,
                          "offset": e["offset"], "stock_set": e["stock"], **v, "chain": chain, "chain_unsigned": chain_u,
                          "meter_gain": tot(press + SPAN) - tot(press - 1), "probe_dumped": dumped,
                          "probe_need": SPAN + 1, "records": recs, "tap": bool(tk),
                          "startup_ticks": t.get("startup_ticks"), "active_ticks": t.get("active_ticks"),
                          "runs": t.get("runs")}))


def signature(r):
    """The numeric signature of one event — HASHED in the tree, never written there (memory: frame data stays out
    of the public repo): start offset, chain, the falls (count, red, white), the meter gained, the stock spent, the
    staged records in frame order (index:real/white:flags:meter, landed)."""
    recs = ";".join(f"{x['idx']}:{x['real']}/{x['white']}:{x['flags']:#x}:{x['meter']}:{'L' if x['landed'] else 'u'}"
                    for x in sorted(r["records"], key=lambda x: x["frame"]))
    spent = (r["stock_press"] or 0) - (r["stock_after"] or 0)
    return "|".join(str(x) for x in (r["sheet"], r["event"], r["started"], r["chain"], len(r["falls"]),
                                     sum(f[1] for f in r["falls"]), sum(f[2] for f in r["falls"]), r["meter_gain"],
                                     spent, recs))


def tick_signature(r):
    """The ENGINE-TICK signature of one event, hashed in the tree like `signature`: startup ticks, active ticks,
    the runs of consecutive attack ticks."""
    return "|".join(str(x) for x in (r["sheet"], r["event"], r.get("startup_ticks"), r.get("active_ticks"), r.get("runs")))


def identity(r):
    """The NON-numeric clauses, frozen in the clear: did the pursuit start (P1 seq 0x0E) — required on every
    knockdown event, forbidden on the CONTROL; the downed flag at the press; the ES stock spend."""
    spent = (r["stock_press"] or 0) - (r["stock_after"] or 0)
    return {"started": r["started"] is not None, "flag": r["flag"], "es_spent": spent if r["event"].startswith("ES") else "-"}


HEADER = ("# tests/expected/vanilla_pursuits.tsv — the vsavj pursuits (#229; rebuilt 14z-205), FROZEN by\n"
          "# `tools/vanilla_pursuit_rigs.py freeze`. Columns: sheet event started flag es_spent chain_as_pair sig tsig\n"
          "# (chain_as_pair: 8K's chain is 8P's, 8KK's is 8PP's); `sig` is the first 16 hex of SHA-256 over the event's numeric signature (tools/vanilla_pursuit_rigs.py\n"
          "# signature: start offset, chain, falls, meter, stock, records), `tsig` the same over the ENGINE-TICK signature\n"
          "# (tick_signature: startup ticks, active ticks, attack-tick runs): the per-move numbers are NOT in the tree.")


def _lines(rows_path):
    import hashlib
    rs = [json.loads(l) for l in open(rows_path)]
    # 8K is compared with 8P and 8KK with 8PP (the sheet's one row each); 8PP's own chain differs from 8P's on six
    # characters (AU DE FE LE QB SA, measured 14z-205) and is in the signature, not this column
    ref = {(r["sheet"], r["event"]): r["chain"] for r in rs if r["event"] in ("P", "ES_PP")}
    pair = {"K": "P", "ES_KK": "ES_PP"}
    out = {}
    for r in rs:
        i = identity(r)
        same = "-" if r["event"] not in pair else ("yes" if r["chain"] and r["chain"] == ref.get((r["sheet"], pair[r["event"]])) else "no")
        sig = hashlib.sha256(signature(r).encode()).hexdigest()[:16]
        tsig = "-" if r["started"] is None else hashlib.sha256(tick_signature(r).encode()).hexdigest()[:16]
        out[(r["sheet"], r["event"])] = "\t".join(str(x) for x in (r["sheet"], r["event"], "yes" if i["started"] else "no",
                                                                 i["flag"], i["es_spent"], same, sig, tsig))
    return rs, out


def freeze(rows_path):
    print(HEADER)
    for k, l in sorted(_lines(rows_path)[1].items()):
        print(l)


def expect(rows_path, exp_path):
    want = {tuple(l.split("\t")[:2]): l.rstrip("\n") for l in open(exp_path) if l.strip() and not l.startswith("#")}
    rs, got = _lines(rows_path)
    bad = 0

    def no(k, why):
        nonlocal bad
        print(f"BAD {k}: {why}"); bad += 1

    for r in rs:
        k = (r["sheet"], r["event"])
        if r["probe_dumped"] != r["probe_need"]:
            no(k, f"probe-leg dump frames {r['probe_dumped']}/{r['probe_need']} — a leg not proven live"); continue
        if r["event"] == "CONTROL":
            if r["started"] is not None:
                no(k, "the CONTROL (no knockdown) entered the pursuit — the start clause cannot tell a pursuit from a press"); continue
        else:
            if r["started"] is None:
                no(k, "NO PURSUIT started after the knockdown"); continue
            if r["flag"] != 1:
                no(k, f"P2's downed flag +0x117 is {r['flag']} at the press"); continue
            dealt = [x for x in r["records"] if x["real"] or x["white"]]
            alien = [x["a3"] for x in r["records"] if not x["own"]]
            if alien:
                no(k, f"record(s) {alien} outside the attacker's own attack table"); continue
            if not dealt:
                no(k, "no damage record staged at the fighter applier"); continue
            unl = [x["frame"] for x in dealt if not x["landed"]]
            if unl:
                no(k, f"staged record(s) at {unl} with no fall of P2's HP within {LAND} frames — damage the victim never took"); continue
            if not r.get("tap") or r.get("startup_ticks") is None or not r.get("active_ticks"):
                no(k, f"no engine-tick reading (tap {r.get('tap')}, startup {r.get('startup_ticks')}, active {r.get('active_ticks')}) — the tap leg not proven live"); continue
            if r["event"].startswith("ES") and identity(r)["es_spent"] != 1:
                no(k, f"the ES pursuit spent {identity(r)['es_spent']} stock(s), not 1"); continue
        if got[k] != want.get(k):
            no(k, f"got  {got[k]}\n    want {want.get(k)}\n    sig  {signature(r)}")
        else:
            print(f"ok  {got[k]}")
    for k in sorted(set(want) - set(got)):
        no(k, "frozen but not measured")
    print(f"{len(rs)} event(s), {bad} bad")
    return 1 if bad else 0


def series(cell):
    """The workbook's hit-series grammar -> per-hit values: '6' [6]; '5+1x6' [5,1,1,1,1,1,1]; '2x4' [2,2,2,2];
    '4+4+12' [4,4,12]; anything else (prose, '2(11)2') None."""
    import re
    c = str(cell).strip().replace(" ", "")
    if re.fullmatch(r"\d+(\.0)?", c):
        return [int(float(c))]
    out = []
    for part in c.split("+"):
        m = re.fullmatch(r"(\d+)x(\d+)", part)
        if m:
            out += [int(m.group(1))] * int(m.group(2))
        elif part.isdigit():
            out.append(int(part))
        else:
            return None
    return out


def rowset(xlsx):
    """The workbook's pursuit rows (type `pursuit` / `es pursuit`, one per sheet each) against the rigs' events."""
    import xlsx_read
    wb = xlsx_read.Workbook(xlsx)
    got = set()
    for tab in wb.sheet_names:
        for d in wb.rows(tab):
            t = str(d.get("type") or "").strip().lower()
            if t == "pursuit":
                got.add((tab, "P"))
            elif t == "es pursuit":
                got.add((tab, "ES"))
    ours = {(t, k) for t in PRESS for k in ("P", "ES")}
    print(f"workbook pursuit rows {len(got)}; the rigs cover {len(ours)} (each row's 8P/8K or 8PP/8KK both run)")
    for x in sorted(got - ours):
        print(f"MISSING from the rigs: {x}")
    for x in sorted(ours - got):
        print(f"NOT IN the workbook: {x}")
    return 0 if got == ours else 1


def crosscheck(rows_path, xlsx):
    """The page's comparison, re-measured: per sheet, P and ES against the workbook — the gauge the game paid
    (P1's meter gain over the event) against the sheet's `guage hit` series summed; the hits (landed records) against
    the series length; the FIRST landed record's power classes (red = real + white, white = white, the page's rule)
    against the series' first values. Prints one line per (sheet, row) and the verdict counts; never writes a file."""
    import xlsx_read
    wb = xlsx_read.Workbook(xlsx)
    sheet = {}
    for tab in wb.sheet_names:
        for d in wb.rows(tab):
            t = str(d.get("type") or "").strip().lower()
            if t in ("pursuit", "es pursuit"):
                sheet[(tab, "P" if t == "pursuit" else "ES")] = d
    rs = {(json.loads(l)["sheet"], json.loads(l)["event"]): json.loads(l) for l in open(rows_path)}
    tally = {}
    for (tab, kind), d in sorted(sheet.items()):
        r = rs.get((tab, "P" if kind == "P" else "ES_PP"))
        if not r:
            print(f"{tab} {kind}: not measured"); continue
        landed = [x for x in sorted(r["records"], key=lambda x: x["frame"]) if (x["real"] or x["white"]) and x["landed"]]
        red_s, white_s, g_s = series(d.get("red damage")), series(d.get("white damage")), series(d.get("guage hit"))
        res = {}
        if landed and red_s and white_s:
            res["red"] = "EXACT" if landed[0]["real"] + landed[0]["white"] == red_s[0] else f"sheet {red_s[0]} ours {landed[0]['real'] + landed[0]['white']}"
            res["white"] = "EXACT" if landed[0]["white"] == white_s[0] else f"sheet {white_s[0]} ours {landed[0]['white']}"
        else:
            res["red"] = res["white"] = "UNCOMPARABLE"
        res["hits"] = ("EXACT" if red_s and len(landed) == len(red_s) else f"sheet {len(red_s) if red_s else '?'} ours {len(landed)}")
        if g_s is not None:
            res["gauge"] = "EXACT" if r["meter_gain"] == sum(g_s) else f"sheet {sum(g_s)} ours {r['meter_gain']}"
        else:
            res["gauge"] = "UNCOMPARABLE"
        for k, v in res.items():
            tally.setdefault((kind, k), {}).setdefault("EXACT" if v == "EXACT" else ("UNCOMPARABLE" if v == "UNCOMPARABLE" else "DIFFERS"), []).append(tab)
        print(f"{tab} {kind}: " + "  ".join(f"{k} {v}" for k, v in res.items()))
    # THE TICK COLUMNS: the sheet's startup / active against ours in engine ticks — per row the delta sheet - ours;
    # the column's verdict by the page's rule: EXACT (all 0), CONSTANT OFFSET (one delta), else INCONSISTENT with the
    # deltas listed. `active` is read two ways: the attack-node ticks in total, and the first run of them.
    deltas = {}
    for (tab, kind), d in sorted(sheet.items()):
        r = rs.get((tab, "P" if kind == "P" else "ES_PP"))
        if not r or r.get("startup_ticks") is None:
            continue
        for col, ours in (("startup", r["startup_ticks"]), ("active_total", r["active_ticks"]),
                          ("active_first_run", (r.get("runs") or [None])[0])):
            sv = series(d.get("startup" if col == "startup" else "active"))
            if sv is None or len(sv) != 1 or ours is None:
                deltas.setdefault((kind, col), []).append((tab, "UNCOMPARABLE")); continue
            deltas.setdefault((kind, col), []).append((tab, sv[0] - ours))
    for (kind, col), v in sorted(deltas.items()):
        num = [d for _, d in v if d != "UNCOMPARABLE"]
        verdict = "EXACT" if num and all(d == 0 for d in num) else ("CONSTANT OFFSET" if num and len(set(num)) == 1 else "INCONSISTENT")
        print(f"TICKS {kind} {col}: {verdict} — " + " ".join(f"{t}{d:+d}" if d != "UNCOMPARABLE" else f"{t}:?" for t, d in v))
    for (kind, k), v in sorted(tally.items()):
        print(f"TALLY {kind} {k}: " + "; ".join(f"{a} {len(b)} {''.join('' if a == 'EXACT' else ' '.join(b))}".rstrip() for a, b in sorted(v.items())))


def sheet(out_png, legs_root, rigs_dir, rows_path):
    """The capture sheet: each rig's no-stop snapshots (one per event, at its first fall in the FIELD leg, else
    press + 30), one row per character, labelled with the event, the frame and what the FIELD leg read."""
    import glob as _g
    from PIL import Image, ImageDraw
    rs = {(json.loads(l)["sheet"], json.loads(l)["event"]): json.loads(l) for l in open(rows_path)}
    tiles = []
    for j in sorted(Path(rigs_dir).glob("pu_*.json")):
        sched = json.loads(j.read_text())
        shots = sorted(_g.glob(str(Path(legs_root, j.stem, "nostop", "sb", "snap", "*", "*.png"))))
        for e, p in zip(sched["events"], shots):
            r = rs.get((sched["sheet"], e["name"]), {})
            st = "pursuit" if r.get("started") is not None else "NO pursuit"
            hits = sum(1 for x in r.get("records", []) if (x["real"] or x["white"]) and x["landed"])
            tiles.append((f"{sched['sheet']} {e['name']} f{e['press']}  {st}, {hits} hit(s)", Image.open(p).convert("RGB")))
    if not tiles:
        sys.exit("sheet: no snapshots found")
    w, h = tiles[0][1].size
    cols = 5
    rowsn = (len(tiles) + cols - 1) // cols
    im = Image.new("RGB", (cols * (w + 8) + 8, rowsn * (h + 22) + 8), (20, 20, 20))
    d = ImageDraw.Draw(im)
    for i, (lab, t) in enumerate(tiles):
        x, y = 8 + (i % cols) * (w + 8), 8 + (i // cols) * (h + 22)
        d.text((x, y), lab, fill=(255, 255, 255))
        im.paste(t, (x, y + 14))
    im.save(out_png)
    print(f"wrote {out_png} ({len(tiles)} snapshots)")


def main():
    a = sys.argv[1:]
    if a[:1] == ["sweep"] and len(a) == 2:
        return sweep(a[1])
    if a[:1] == ["sweeprows"] and len(a) == 3:
        return sweeprows(a[1], a[2])
    if a[:1] == ["edgesweep"] and len(a) == 2:
        return edgesweep(a[1])
    if a[:1] == ["genbands"] and len(a) == 2:
        return genbands(a[1])
    if a[:1] == ["bandrows"] and len(a) == 3:
        return bandrows(a[1], a[2])
    if a[:1] == ["bandexpect"] and len(a) == 3:
        return bandexpect(a[1], a[2])
    if a[:1] == ["ticks"] and len(a) == 5:
        return ticks(*a[1:])
    if a[:1] == ["sheet"] and len(a) == 5:
        return sheet(*a[1:])
    if a[:1] == ["rowset"] and len(a) == 2:
        return rowset(a[1])
    if a[:1] == ["crosscheck"] and len(a) == 3:
        return crosscheck(a[1], a[2])
    if a[:1] == ["finesweep"] and len(a) == 3:
        return finesweep(a[1], a[2])
    if a[:1] == ["gen"] and len(a) == 2:
        return gen(a[1])
    if a[:1] == ["dumps"] and len(a) == 2:
        print(dumps_spec(json.loads(Path(a[1]).read_text())))
        return 0
    if a[:1] == ["snaps"] and len(a) == 3:
        return snaps(a[1], a[2])
    if a[:1] == ["rows"] and len(a) >= 5:
        kw = {"probe_extra": "", "tap_path": ""}
        rest = a[5:]
        while rest:
            if rest[0] == "--tap":
                kw["tap_path"] = rest[1]; rest = rest[2:]
            else:
                kw["probe_extra"] = rest[0]; rest = rest[1:]
        return rows(*a[1:5], **kw)
    if a[:1] == ["freeze"] and len(a) == 2:
        return freeze(a[1])
    if a[:1] == ["expect"] and len(a) == 3:
        return expect(a[1], a[2])
    sys.exit(__doc__)


if __name__ == "__main__":
    sys.exit(main() or 0)
