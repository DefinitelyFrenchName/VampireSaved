#!/usr/bin/env python3
"""gc_rigs.py — the vsavj GUARD CANCELS for the community cross-check (GitHub #229, 14z-205 fork F5).

  python3 tools/gc_rigs.py gen <out dir>                        two rigs per character (.rpl + .json): gc_<TAB>, ref_<TAB>
  python3 tools/gc_rigs.py rows <rig.json> <trace.txt> <vsavj_data.bin>   one JSON row per event (the measurement)
  python3 tools/gc_rigs.py snaps <rows.jsonl>                   SNAP_FRAMES of a capture leg (the frame each GC lands)
  python3 tools/gc_rigs.py sheet <out.png> <rows.jsonl> <snap dir> ...      the capture sheet
  python3 tools/gc_rigs.py rowset <workbook.xlsx>               the workbook's GC rows against GC_ROWS

THE RIG (tools/ground_throw_rigs.py's walk-in, tools/name_moves.py's guard-cancel recipe gc_v): the character FORCED on
P1 by the early-window poke, P2 DEMITRI (0x01; no GC row is Demitri's, so he is never P1 here); per EVENT both fighters
pinned to the far pair (552, 728) at t-230, P1 walks right t-190..t-40 to pushbox contact, a 40-frame pause, then:
  gc_<TAB>  — P2 presses HP at t..t+3; P1 holds BACK (L) from t-4 to t+11, then 623+button from t+12 (gc_v(b, 11, 12),
              the recipe that fired Phobos's Reflect Wall on native vsav2: tests/expected/move_naming_huitzil.txt part 7);
  ref_<TAB> — the same walk-in and the same 623+button at t+12, with NO P2 attack and no back held: the special from
              neutral, so the GC event's chain can be told from the plain special's at the same position.
Before each event P2's two HP words are re-pinned to 288 ([VSP-125]) and P1's stock to 2, meter 0 (an ES GC needs a
stock; the stock left at the event's end says what the GC cost). Buttons: LP MP HP LK MK HK and the two ES pairs
(PP = LP+HP, KK = LK+HK, name_moves.B).

WHAT A ROW CARRIES (rows): the BLOCK — P1's chains entered between P2's press and the 623 input (the block reaction on
vs2 is a:0x13 then b:0x0c), and whether P1 was in a block chain on the frame the motion starts (the identity of a GUARD
cancel: the input comes out of guard, never out of neutral); the GC CHAIN — the first chain entered from the motion's
start that was not entered before it (a window with none is UNFIRED, never guessed — [VSE-47]); the chains after it;
MEASURED timing on that chain (the frames P1 spent on its nodes, split at the attack nodes hbA != 0, as
vanilla_join_rig.durations); P2's red and white HP falls in the window (the dealt damage, on P2 recovering from his HP);
P1's stock at the end (the cost) and the meter (the gain).

THE DEALT KIND (#229 Q5 (a), ruled 2026-10-24, 14z-208): dealt_<TAB>_<BTN> is the gc rig of a committing button with
P2 re-poked to a victim whose defense row is -3 — GALLON (0x02), or ZABEL (0x04) for Gallon's own rows — because the
workbook's guard-cancel damage is the dealt figure on such a victim: on Demitri (-2, the gc rigs' P2) it reads one
below the sheet on 13 of 49 rows, on Gallon it equals the sheet on 45 of 45 (fork X, 14z-208, build/agent208/X/q5v/).
The RECORD (the power class, an index into the attack table) does not depend on the victim and stays on the gc rows;
the dealt rows carry the victim and its first fall, the figure compared with the sheet."""
import json
import re
import struct
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import anim_nodes  # noqa: E402
import hitbox_records  # noqa: E402
import name_moves as nm  # noqa: E402
import vanilla_frames as vf  # noqa: E402
import vanilla_join_rig as vj  # noqa: E402

VICTIM = 0x01                    # Demitri
DEALT_VICTIM, DEALT_VICTIM_GA = 0x02, 0x04   # Gallon, and Zabel for Gallon's own rows (both defense row -3; Q5 (a))
BUTTONS = ["LP", "MP", "HP", "LK", "MK", "HK", "PP", "KK"]
GC_AT = 12                       # the 623 starts at +12 (gc_v(b, 11, 12))
WINDOW = 200                     # frames from the motion's start in which the GC chain and its falls are read
FIELDS = ("ff841c:l:node,ff8410:w:p1x,ff8414:w:p1y,ff840b:b:p1face,ff881c:l:p2node,"
          "ff8850:w:p2hp,ff8852:w:p2white,ff8509:b:p1stock,ff850a:w:p1meter,ff845c:b:freeze")
# the write taps (tests/lua/read_tap.lua, non-debug): P1's +0x3B4 word (+0x3B5.b, the GUARD-CANCEL COMMIT mark := 6,
# written by vsavj 0x029C6E — docs/game/atlas/ram.md) and P1's +0x158 word (the guard window, := 0x0E on a block)
RTAP = "ff87b4,2;ff8558,2"
COMMIT_PC = 0x029C6E
KINDS = ("gc", "ref", "noblock")
TABS = ["FE", "AN", "AU", "BI", "BU", "GA", "JE", "LE", "LI", "MO", "QB", "SA", "VI", "ZA"]


def gc_recipe(b):
    return [(0, 3, "3", "p2"), (-4, 11, "L"), (GC_AT, GC_AT + 1, "R"), (GC_AT + 2, GC_AT + 3, "D"),
            (GC_AT + 4, GC_AT + 7, "DR" + nm.B[b])]


def ref_recipe(b):
    return [(GC_AT, GC_AT + 1, "R"), (GC_AT + 2, GC_AT + 3, "D"), (GC_AT + 4, GC_AT + 7, "DR" + nm.B[b])]


def noblock_recipe(b):   # the CONTROL: P2's HP and the same 623+button, P1 never holds back (no block, no guard window)
    return [(0, 3, "3", "p2")] + ref_recipe(b)


def whiff_recipe(b):
    """The WHIFF leg (14z-205 follow-up): P2 throws Chaos Flare (236+HP at t..t+9) from across the screen, P1 holds back
    and blocks it (the guard pose a:0x13 from +17, the projectile's block b:0x0c at +57 for 20 frames, measured on
    Felicia), then 623+button from +60 INSIDE that blockstun — a guard cancel that cannot reach P2 (~360 px away), so
    its active and recovery are read on a whiff, not on a hit. Prototype: +58 and +62 committed, +66 did not, +28..+44
    (inside the guard pose, before the hit) did not."""
    return [(0, 1, "D", "p2"), (2, 3, "DL", "p2"), (4, 8, "L", "p2"), (5, 9, "3", "p2"), (-4, WHIFF_AT - 1, "L"),
            (WHIFF_AT, WHIFF_AT + 1, "R"), (WHIFF_AT + 2, WHIFF_AT + 3, "D"), (WHIFF_AT + 4, WHIFF_AT + 7, "DR" + nm.B[b])]


WHIFF_AT = 60
WHIFF_PIN = (0x1F0, 0x340)       # P1 at 496 (the stage edge holds it at 471), P2 at 832: ~360 px apart
RECIPES = {"gc": gc_recipe, "ref": ref_recipe, "noblock": noblock_recipe, "whiff": whiff_recipe, "dealt": gc_recipe}
# THE COMMITTING BUTTONS, as measured 14z-205 (53 of 112 gc events commit; 0 of 112 noblock): DATA the gate checks the
# measurement against, as tools/ground_throw_rigs.py's THROWS is. The whiff and noblock rigs are run for these only.
GC_BUTTONS = {"FE": "LK MK HK KK", "AN": "PP", "AU": "LK MK HK KK", "BI": "LP MP HP PP", "BU": "LK MK HK KK",
              "GA": "LP MP HP PP", "JE": "LP MP HP PP", "LE": "LP MP HP PP", "LI": "LP MP HP PP", "MO": "LP MP HP PP",
              "QB": "LK MK HK KK", "SA": "LK MK HK KK", "VI": "LK MK HK KK", "ZA": "LK MK HK KK"}
# THE WHIFFS THAT CONNECT ANYWAY, as measured 14z-205 (the whiff rig's ~360 px is about as far apart as the camera lets
# two fighters stand): Felicia's ES Delta Kick and Lei-Lei's four Senpuubu GCs travel and reach P2. Their ticks are
# still a whiff's (a hit-freeze writes no tick); the gate holds the set to this data.
WHIFF_CONNECTS = "FE_KK LE_LP LE_MP LE_HP LE_PP"


def gen_rig(tab, kind, b):
    """ONE event per rig: an event that crosses the fighters (a GC that hits can) never leaves the next one facing the
    wrong way (the first, eight-event rigs read two UNFIRED events that way on Felicia, 14z-205)."""
    cid = vf.CHARS[tab][0]
    x1, x2 = nm.PIN["far"]
    victim = (DEALT_VICTIM_GA if tab == "GA" else DEALT_VICTIM) if kind == "dealt" else VICTIM
    vname = {0x01: "Demitri", 0x02: "Gallon", 0x04: "Zabel"}[victim]
    lines = [f"# #229 guard-cancel rig ({kind}, {b}) — {tab} ({cid:#04x}) on vsavj, P2 {vname} {victim:#04x}",
             "# (tools/gc_rigs.py gen; DO NOT hand-edit, regenerate). Select prologue from replay 17",
             "# (the characters are FORCED by the early-window poke, so the cursor path does not matter).",
             nm.REPLAY17_PROLOGUE.rstrip()]
    t = nm.FIRST_EVENT + vj.WALKIN_SHIFT
    sched = {"char": f"{cid:#04x}", "sheet": tab, "kind": kind, "button": b, "victim": f"{victim:#04x}", "events": []}
    pokes = [f"{f}:ff8782:{cid:02x}" for f in (1400, 1450, 1500)] + [f"{f}:ff8b82:{victim:02x}" for f in (1400, 1450, 1500)]
    if kind == "whiff":
        x1, x2 = WHIFF_PIN
    pokes += [f"{t - 230}:ff8410:{x1:04x}", f"{t - 230}:ff8810:{x2:04x}",
              f"{t - 20}:ff8850:01200120", f"{t - 20}:ff8509:020000"]
    if kind != "whiff":
        lines.append(f"{t - 190}-{t - 40} p1=R")
    for item in RECIPES[kind](b):
        a, bb, tok = item[:3]
        who = item[3] if len(item) > 3 else "p1"
        lines.append(f"{t + a}-{t + bb} {who}={tok}")
    at = WHIFF_AT if kind == "whiff" else GC_AT
    sched["events"].append({"button": b, "frame": t, "motion": t + at})
    end = t + at + WINDOW + 20
    lines.append(f"{end} wait")
    sched["pokes"] = pokes
    sched["frames"] = end + 10
    return "\n".join(lines) + "\n", sched


def rig_name(kind, tab, b):
    return f"{kind}_{tab}_{b}"


def gen(out_dir, tabs=None, kinds=None):
    out = Path(out_dir); out.mkdir(parents=True, exist_ok=True)
    n = 0
    for tab in tabs or TABS:
        for kind in kinds or KINDS:
            for b in (BUTTONS if kind in ("gc", "ref") or kinds is None else GC_BUTTONS[tab].split()):
                rpl, sched = gen_rig(tab, kind, b)
                (out / f"{rig_name(kind, tab, b)}.rpl").write_text(rpl)
                (out / f"{rig_name(kind, tab, b)}.json").write_text(json.dumps(sched, indent=1) + "\n")
                n += 1
    print(f"wrote {n} rigs to {out}")


def walk_signed(img, table):
    """{seq: [(node addr, hbA high byte, dur), ...]} for one anim index table, its word offsets read SIGNED, as the
    engine adds them (a 68000 word add). Copied from tools/specials_b_rigs.py walk_signed (#229 F2, 14z-205): some
    tables carry NEGATIVE offsets (chains below their index table) and tools/anim_nodes.py's walk_table reads them
    unsigned — it is not edited here (the #229 parallel run's brief); the defect is F2's to report. The same node
    rules: flags bit 7 = follow the link at +0x18, bit 6 = hold, else the next node; entries bounded by the smallest
    positive offset. GC_UNSIGNED=1 reads them unsigned (the comparison that says which GC chains it changed).
    RESOLVED #318 (14z-210): tools/anim_nodes.py's walk_table reads the offsets SIGNED too since #318, so the
    "reads them unsigned" above describes the tool before it. This local walk stays: the frozen #229 identities
    were measured with it, and its entry bound differs from the tool's (it skips odd words instead of ending)."""
    import os
    words, k = [], 0
    while k < 1024:
        w = int.from_bytes(img[table + 2 * k:table + 2 * k + 2], "big", signed=os.environ.get("GC_UNSIGNED") != "1")
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
            nodes.append((a, img[a + 10], img[a]))
            if fl & 0x80:
                a = int.from_bytes(img[a + 0x18:a + 0x1C], "big")
            elif fl & 0x40:
                break
            else:
                a += anim_nodes.NODE
        out[seq] = nodes
    return out


NEGATIVE = {}   # (cid, table) -> [seq, ...] whose offset is negative


def node_map(img, cid):
    """{node address: (chain 'table:seq', node index, hbA high byte, dur)} over tables a2, a, b and c (a2 first, as
    vanilla_join_rig.node_map: a table-a chain without a terminator runs on into a2's region), offsets SIGNED."""
    rows = vf.bank_rows(Path(__file__).resolve().parent.parent / "build/manifest/bank_map.toml")
    out = {}
    for tn in ("a2", "a", "b", "c"):
        tbl = vf.row_ptr(img, rows["anim_index_" + tn], cid)
        for seq, nodes in walk_signed(img, tbl).items():
            if nodes and nodes[0][0] < tbl:
                NEGATIVE.setdefault((cid, tn), []).append(seq)
            for i, (a, hb, dur) in enumerate(nodes):
                if a not in out:
                    out[a] = (f"{tn}:{seq:#04x}", i, hb, dur)
    return out


def samples(trace):
    fr = {}
    for ln in Path(trace).read_text().splitlines():
        m = re.match(r"F (\d+) (.*)", ln)
        if m:
            kv = {}
            for p in m.group(2).split():
                k, _, v = p.partition("=")
                try:
                    kv[k] = int(v)
                except ValueError:
                    pass
            fr[int(m.group(1))] = kv
    return fr


HSET = None
BASELINE = {"a:0x00"}    # standing idle: the move is over when P1 is back in it (or any chain seen before the event)


def taps(path):
    """The tap log -> [(frame, pc, field, value)] for the two tapped bytes: +0x3B5 (low byte of the +0x3B4 word) and
    +0x158 (high byte of its word, an even offset). A log with no END line is VOID (a dead tap is not evidence)."""
    out, ended = [], False
    for l in open(path):
        t = l.split()
        if not t:
            continue
        if t[0] == "END":
            ended = True
        if t[0] == "W" and len(t) >= 10:
            f, pc, off, data, mask = int(t[1]), int(t[3], 16), int(t[5], 16), int(t[7], 16), int(t[9], 16)
            if off == 0xff87b4 and mask & 0x00ff:
                out.append((f, pc, "commit3b5", data & 0xff))
            if off == 0xff8558 and mask & 0xff00:
                out.append((f, pc, "window158", (data >> 8) & 0xff))
    return out if ended else None


def runs(flags):
    """[True/False per frame] -> the workbook's active grammar from OUR frames: 'a(g)b(g)c' (attack runs, gaps)."""
    parts, cur, val = [], 0, None
    for x in flags:
        if val is None or x == val:
            cur += 1; val = x
        else:
            parts.append((val, cur)); cur, val = 1, x
    if val is not None:
        parts.append((val, cur))
    while parts and not parts[0][0]:
        parts.pop(0)
    while parts and not parts[-1][0]:
        parts.pop()
    return "".join(f"{n}" if v else f"({n})" for v, n in parts) or "-"


def event_row(e, fr, nmap, kind, tap):
    t0, mo = e["frame"], e["motion"]
    node = lambda f: nmap.get(fr.get(f, {}).get("node", 0) & 0xFFFFFFFF)
    chain_at = lambda f: (node(f) or (None,))[0]
    pre = []                         # chains entered from P2's press up to the motion's start (the block, on gc)
    for f in range(t0 - 30, mo):
        c = chain_at(f)
        if c and (not pre or pre[-1] != c):
            pre.append(c)
    before = set(pre) | {chain_at(f) for f in range(t0 - 30, t0)}
    rec = {"sheet": None, "kind": kind, "button": e["button"], "frame": t0, "motion": mo,
           "pre": pre, "at_motion": chain_at(mo), "face": fr.get(mo, {}).get("p1face")}
    first = start = None
    for f in range(mo, mo + WINDOW):
        c = chain_at(f)
        if c and c not in before:
            first, start = c, f
            break
    rec["gc_chain"] = first or "UNFIRED"
    seq, frames = [], []             # the MOVE: every frame from its entry until P1 is back in a baseline chain
    if first:
        rec["enter_offset"] = start - mo
        for f in range(start, mo + WINDOW):
            d = node(f)
            if d is None:
                continue
            if d[0] in BASELINE or (d[0] in before and d[0] != first):
                rec["end_offset"] = f - mo
                break
            frames.append((f, d, fr.get(f, {}).get("freeze", 0)))
            if not seq or seq[-1] != d[0]:
                seq.append(d[0])
        rec["move_chains"] = seq
        live = [(f, d) for f, d, z in frames if not z]          # hit-freeze frames held the node timer ([VSE-25])
        fa = next((k for k, (f, d, z) in enumerate(frames) if d[2]), None)
        rec["first_attack_frame"] = frames[fa][0] if fa is not None else None
        rec["freeze_frames"] = sum(1 for _, _, z in frames if z)
        atk = [i for i, (f, d) in enumerate(live) if d[2]]
        rec["move_frames"] = len(live)
        if atk:
            rec["startup"] = atk[0]
            rec["active_runs"] = runs([bool(d[2]) for _, d in live][atk[0]:atk[-1] + 1])
            rec["active"] = sum(1 for _, d in live if d[2])
            rec["recovery"] = len(live) - atk[-1] - 1
            rec["records"] = sorted({d[2] for _, d in live if d[2]})
            # each ATTACK RUN (consecutive live attack frames) with every record in it, in order, decoded from the
            # character's own attack table as tools/vanilla_frames.derive_char does: the power CLASS (#241), the
            # record's meter, its hit id
            def dec(a3):
                try:
                    r = HSET.record(a3)
                    return {"idx": a3, "real": r["real_class"], "white": r["white_class"], "meter": r["meter"],
                            "hit_id": r["hit_id"], "flags": [r["real_flags"], r["white_flags"]]}
                except (IndexError, KeyError):
                    return {"idx": a3, "real": None}
            rr, cur, prevatk = [], None, False
            for _, d in live:
                if d[2]:
                    if not prevatk:
                        cur = []; rr.append(cur)
                    if d[2] not in cur:
                        cur.append(d[2])
                prevatk = bool(d[2])
            rec["run_records"] = [[dec(x) for x in run] for run in rr]
    falls, prev = [], None
    for f in range(t0, mo + WINDOW):
        s = fr.get(f, {})
        cur = (s.get("p2hp"), s.get("p2white"))
        if prev and None not in prev and None not in cur and (cur[0] < prev[0] or cur[1] < prev[1]):
            falls.append([f, max(prev[0] - cur[0], 0), max(prev[1] - cur[1], 0)])
        prev = cur
    rec["falls_before_motion"] = [x for x in falls if x[0] < mo]
    rec["falls"] = [x for x in falls if x[0] >= mo]
    for x in rec["falls"]:
        ids = [node(f)[2] for f in (x[0], x[0] - 1, x[0] - 2) if node(f) and node(f)[2]]
        x.append(ids[0] if ids else None)            # [frame, red-word fall, white-word fall, the record carried]
    endf = mo + WINDOW - 1
    s0, s1 = fr.get(mo - 1, {}), fr.get(endf, {})
    rec["stock_before"], rec["stock_end"] = s0.get("p1stock"), s1.get("p1stock")
    rec["meter_before"], rec["meter_end"] = s0.get("p1meter"), s1.get("p1meter")
    if tap is None:
        rec["tap"] = "VOID"
    else:
        ev = [x for x in tap if t0 - 10 <= x[0] < mo + WINDOW]
        rec["commits"] = [[f, f"{pc:06x}"] for f, pc, fld, v in ev if fld == "commit3b5" and v == 6]
        rec["window_open"] = [[f, v] for f, pc, fld, v in ev if fld == "window158" and v]
        rec["tap"] = "ok"
    rec["gc"] = bool(rec.get("commits")) and any(int(pc, 16) == COMMIT_PC for _, pc in rec["commits"]) and first is not None
    return rec


def rows(sched_path, trace, img_path, tap_path=None):
    sched = json.loads(Path(sched_path).read_text())
    img = Path(img_path).read_bytes()
    cid = int(sched["char"], 16)
    nmap = node_map(img, cid)
    global HSET
    bank = vf.bank_rows(Path(__file__).resolve().parent.parent / "build/manifest/bank_map.toml")
    HSET = hitbox_records.HitboxSet.from_image(img, vf.row_ptr(img, bank["hitbox_base"], cid),
                                              vf.row_ptr(img, bank["hitbox_comp"], cid))
    fr = samples(trace)
    tp = taps(tap_path) if tap_path and Path(tap_path).exists() else None
    for e in sched["events"]:
        r = event_row(e, fr, nmap, sched["kind"], tp)
        r["sheet"] = sched["sheet"]
        print(json.dumps(r))

# THE JOIN (the community cross-check's rule, docs/project/tables/community_crosscheck.md): a workbook GC row joins the
# events of the buttons its INPUT names that COMMITTED a guard cancel; `623P` / `623K` name every strength (each is its
# own pair, as tools/ground_throw_rigs.py ran both buttons of a "6MP or 6HP" row); `623KH` (Aulbath) is read as HK and
# said so. A row whose buttons committed nothing is UNJOINED, with that reason.
GC_TYPES = ("special gc", "es special gc", "gc", "es gc")
INPUT_BUTTONS = {"LP": ["LP"], "MP": ["MP"], "HP": ["HP"], "LK": ["LK"], "MK": ["MK"], "HK": ["HK"], "KH": ["HK"],
                 "P": ["LP", "MP", "HP"], "K": ["LK", "MK", "HK"], "PP": ["PP"], "KK": ["KK"]}


def wb_rows(xlsx):
    import xlsx_read
    wb = xlsx_read.Workbook(xlsx)
    out = []
    for tab in wb.sheet_names:
        for i, d in enumerate(wb.rows(tab)):
            if (d.get("type") or "").strip().lower() in GC_TYPES:
                out.append((tab, i, d))
    return out


def first_num(cell):
    m = re.match(r"\s*\(?\s*(\d+)", str(cell or ""))
    return int(m.group(1)) if m else None


def recovery_total(cell):
    """'landing 14', '19 + landing 8', '26 + landing 4 + turn 1', '86.0' -> the summed frames; prose -> None."""
    t = str(cell or "").replace(".0", "").strip().lower()
    if not t or not re.fullmatch(r"[0-9+\s]*(landing|turn|[0-9+\s])*", t):
        return None
    ns = [int(x) for x in re.findall(r"\d+", t)]
    return sum(ns) if ns else None


def ours_cols(r):
    """One measured GC event -> our value per compared column."""
    rr = r.get("run_records") or []
    first = rr[0][0] if rr and rr[0] else None
    landed = [x[3] for x in r.get("falls", []) if x[3] is not None]
    meter_of = {x["idx"]: x["meter"] for run in rr for x in run}
    gain = (r["meter_end"] - r["meter_before"]) if None not in (r.get("meter_end"), r.get("meter_before")) else None
    # a fall P1's own chain carried no record for (the hit came from another object: Lei-Lei's Senpuubu) leaves the
    # landed meter unknown, so the whiff gain is not read (UNCOMPARABLE, never the whole gain)
    known = all(x[3] is not None for x in r.get("falls", []))
    gw = gain - sum(meter_of.get(i, 0) for i in landed) if gain is not None and known and all(i in meter_of for i in landed) else None
    f1 = (r.get("falls") or [None])[0]
    return {"dealt_red": f1[2] if f1 else None, "dealt_white": (f1[2] - f1[1]) if f1 else None,
            "startup": r.get("startup"), "active": r.get("active"), "recovery": r.get("recovery"),
            "red": (first["real"] + first["white"]) if first and first.get("real") is not None else None,
            "white": first["white"] if first and first.get("real") is not None else None,
            "gauge_whiff": gw, "gauge_hit": (gw + first["meter"]) if gw is not None and first else None,
            "stock_cost": (r["stock_before"] - r["stock_end"]) if None not in (r.get("stock_before"), r.get("stock_end")) else None}


def sheet_cols(d):
    from crosscheck_framedata import parse_runs, num
    g = lambda k: d.get(k)
    return {"startup": num(g("startup")) if g("startup") not in (None, "") else None, "active": parse_runs(g("active")),
            "recovery": recovery_total(g("recovery")), "red": first_num(g("red damage")), "white": first_num(g("white damage")),
            "dealt_red": first_num(g("red damage")), "dealt_white": first_num(g("white damage")),
            "gauge_whiff": first_num(g("gauge whiff")), "gauge_hit": first_num(g("guage hit"))}


def join(legs_dir, xlsx):
    from crosscheck_framedata import classify
    rows_by = {}
    for p in Path(legs_dir).glob("gc_*/rows.jsonl"):
        for l in open(p):
            r = json.loads(l)
            rows_by[(r["sheet"], r["button"])] = r
    out, pairs = [], {}
    for tab, i, d in wb_rows(xlsx):
        inp = str(d.get("input") or "").strip().upper()
        m = re.fullmatch(r"623([A-Z]+)", inp)
        btns = INPUT_BUTTONS.get(m.group(1)) if m else None
        note = "input 623KH read as 623HK" if m and m.group(1) == "KH" else ""
        ev = [rows_by.get((tab, b)) for b in (btns or [])]
        fired = [r for r in ev if r and r.get("gc")]
        row = {"sheet": tab, "row": i, "move": d.get("move"), "input": inp, "type": d.get("type"), "buttons": btns,
               "fired": [r["button"] for r in fired], "note": note}
        if not btns:
            row["status"] = f"UNJOINED: the input cell {inp!r} names no 623 button set"
        elif not fired:
            row["status"] = "UNJOINED: no button of the input committed a guard cancel (" + ", ".join(
                f"{b}:{'no event' if r is None else r['gc_chain']}" for b, r in zip(btns, ev)) + ")"
        else:
            row["status"] = "JOINED"
            sc = sheet_cols(d)
            row["chains"] = {r["button"]: r["gc_chain"] for r in fired}
            row["cols"] = {}
            for r in fired:
                oc = ours_cols(r)
                for k, sv in sc.items():
                    ov = oc.get(k)
                    row["cols"].setdefault(k, []).append([r["button"], sv, ov])
                    if sv is not None and ov is not None:
                        pairs.setdefault(k, []).append((f"{tab} {d.get('move')} {r['button']}", sv, ov))
                row["cols"].setdefault("stock_cost", []).append([r["button"], None, oc["stock_cost"]])
        out.append(row)
    verdicts = {k: classify(v) for k, v in pairs.items()}
    return out, verdicts, pairs


def main_join(legs_dir, xlsx, out_json=None):
    out, verdicts, pairs = join(legs_dir, xlsx)
    for r in out:
        print(f"{r['sheet']} {str(r['move'])[:28]:28} {r['input']:7} {r['type']:14} {r['status'][:120]}")
    print("--- verdicts over the joined pairs (sheet - ours)")
    for k, (v, det) in verdicts.items():
        print(f"{k:12} {v:16} {det}")
    if out_json:
        Path(out_json).write_text(json.dumps({"rows": out, "verdicts": verdicts,
                                              "pairs": {k: v for k, v in pairs.items()}}, indent=1) + "\n")

# THE CAPTURE (the maintainer confirms identity BY EYE before any verdict is final): for every event that committed a
# guard cancel, two snapshots — the GC's first attack frame and 10 frames later — taken by a replay_guard capture leg
# (GUARD_DEBUG=0) that also DUMPS P1's node pointer +0x1C at both frames, so each picture is shown to be the chain the
# trace leg read there (`capcheck`).
def cap_frames(r):
    if not r.get("gc"):
        return []
    if r.get("first_attack_frame"):
        return [r["first_attack_frame"], r["first_attack_frame"] + 10]
    # a GC chain with no attack node on P1 (Bulleta's Jealousy & Fake; Lei-Lei's Senpuubu, whose hits come from
    # another object): 6 and 20 frames after the chain's entry
    f0 = r["motion"] + r["enter_offset"]
    return [f0 + 6, f0 + 20]


def cap_spec(rows_path):
    r = json.loads(open(rows_path).readline())
    fs = cap_frames(r)
    return ",".join(map(str, fs)), ";".join(f"{f}:ff841c-ff841f" for f in fs)


def capcheck(rows_path, trace, cap_dir):
    """Each snapshot frame's dumped +0x1C equals the trace's node on that frame."""
    r = json.loads(open(rows_path).readline())
    fr = samples(trace)
    out = []
    for f in cap_frames(r):
        p = Path(cap_dir) / f"dump_{f}_ff841c.bin"
        got = struct.unpack(">I", p.read_bytes()[:4])[0] if p.exists() and p.stat().st_size >= 4 else None
        want = fr.get(f, {}).get("node", 0) & 0xFFFFFFFF
        out.append((f, got == want, got, want))
    return out


def sheet(out_png, legs_dir, tabs):
    from PIL import Image, ImageDraw
    rowsd = []
    for tab in tabs:
        tiles = []
        for b in BUTTONS:
            d = Path(legs_dir) / f"gc_{tab}_{b}"
            rp = d / "rows.jsonl"
            if not rp.exists():
                continue
            r = json.loads(rp.read_text().splitlines()[0])
            shots = sorted((d / "cap" / "sb" / "snap").rglob("*.png")) if (d / "cap").exists() else []
            for f, pth in zip(cap_frames(r), shots):
                ok = [c for c in capcheck(rp, d / "trace" / "t.txt", d / "cap") if c[0] == f]
                tag = "" if ok and ok[0][1] else " [NODE MISMATCH]"
                tiles.append((f"{tab} 623{b} GC -> {r['gc_chain']}  f{f} (+{f - r['motion']}){tag}", Image.open(pth).convert("RGB")))
        if tiles:
            rowsd.append(tiles)
    if not rowsd:
        sys.exit("sheet: no snapshots")
    w, h = rowsd[0][0][1].size
    cols = max(len(t) for t in rowsd)
    im = Image.new("RGB", (cols * (w + 8) + 8, len(rowsd) * (h + 22) + 8), (20, 20, 20))
    dr = ImageDraw.Draw(im)
    for j, tiles in enumerate(rowsd):
        for i, (lab, t) in enumerate(tiles):
            x, y = 8 + i * (w + 8), 8 + j * (h + 22)
            dr.text((x, y), lab, fill=(255, 255, 255))
            im.paste(t, (x, y + 14))
    im.save(out_png)
    print(f"wrote {out_png} ({sum(len(t) for t in rowsd)} snapshots, {len(rowsd)} characters)")

# ===================================================================================================================
# THE ALIGNED LEGS (14z-205 follow-up, #228 option A): every leg counts EMULATED frames.
#   trace  — tests/lua/trace_writes.lua (-debug): watchpoints on P1's +0x1C (the node pointer), +0x20 (the node timer)
#            and +0x3B4 (the GC commit mark), armed at WATCH_FROM; SAMPLE of +0x1C at every frame. A stop's PC is the
#            instruction AFTER the write: 0x027F74 is the tick (0x027F70 `subq.b #1,$20(a6)`, one write = one ENGINE
#            TICK — engine_internals "THE ENGINE TICK IS DIRECTLY OBSERVABLE"), 0x027EEC the walker's node write (A0 =
#            the new node; its second word is 0x027EF0), 0x029C74 the commit (0x029C6E `+0x3B5 := 6`). Only stops with
#            A6 = P1's block (0xFF8400) count. Measured on Felicia's LK GC: 295 ticks, 88 node writes, 1 commit.
#   nostop — tests/lua/replay_guard.lua without the debugger, DUMPS of P1's 0xFF8408-0xFF845F, 0xFF8508-0xFF850B and
#            P2's 0xFF8850-0xFF8853 on every frame of the event window: the falls, stock, meter and the chain sequence
#            on the undisturbed timeline (a stop can move the game, [MFI-2]; the two legs must agree on the chains).
TRACE_WATCH = "ff841c,4,w;ff8420,2,w;ff87b4,2,w"
TICK_PC, NODE_PC, COMMIT_STOP_PC = 0x027F74, 0x027EEC, 0x029C74
P1 = 0xFF8400


def trace_env(sched):
    e = sched["events"][0]
    return {"WATCH": TRACE_WATCH, "WATCH_FROM": str(e["frame"] - 40), "SAMPLE": "ff841c,4"}


def nostop_dumps(sched):
    e = sched["events"][0]
    out = []
    for f in range(e["frame"] - 30, e["motion"] + WINDOW):
        out += [f"{f}:ff8408-ff845f", f"{f}:ff8508-ff850b", f"{f}:ff8850-ff8853"]
    return ";".join(out)


def trace_events(path):
    """-> (events, samples, ended): events in execution order [(frame, 'tick'|'node'|'commit', node or None)] for P1's
    stops; samples {frame: +0x1C} from the SAMPLE lines (the value as the frame begins)."""
    ev, smp, ended = [], {}, False
    for l in open(path, errors="replace"):
        t = l.split()
        if not t:
            continue
        if t[0] == "END":
            ended = True
        elif t[0] == "S" and len(t) == 3:
            smp[int(t[1])] = int(t[2], 16)
        elif t[0] == "frame" and len(t) >= 20:
            f, pc = int(t[1]), int(t[3], 16)
            reg = {t[i]: int(t[i + 1], 16) for i in range(4, len(t) - 1, 2)}
            if reg.get("A6") != P1:
                continue
            if pc == TICK_PC:
                ev.append((f, "tick", None))
            elif pc == NODE_PC:
                ev.append((f, "node", reg["A0"]))
            elif pc == COMMIT_STOP_PC:
                ev.append((f, "commit", None))
    return ev, smp, ended


def dump_samples(d, frames):
    """{frame: fields} from a nostop leg's dumps (the names event_row reads)."""
    fr = {}
    for f in frames:
        a, b, c = (Path(d) / f"dump_{f}_{x}.bin" for x in ("ff8408", "ff8508", "ff8850"))
        if not (a.exists() and b.exists() and c.exists()):
            continue
        A, B, C = a.read_bytes(), b.read_bytes(), c.read_bytes()
        if len(A) < 0x58 or len(B) < 4 or len(C) < 4:
            continue
        sw = lambda x: x - 0x10000 if x >= 0x8000 else x
        fr[f] = {"node": struct.unpack(">I", A[0x14:0x18])[0], "p1face": A[3], "p1x": sw(struct.unpack(">H", A[8:10])[0]),
                 "p1y": sw(struct.unpack(">H", A[12:14])[0]), "freeze": A[0x54], "p1stock": B[1],
                 "p1meter": struct.unpack(">H", B[2:4])[0], "p2hp": sw(struct.unpack(">H", C[0:2])[0]),
                 "p2white": sw(struct.unpack(">H", C[2:4])[0])}
    return fr


def tick_measure(e, ev, smp, nmap):
    """The GC on the trace leg, in ENGINE TICKS: the commit, the first node after it in a chain P1 was not in before the
    motion, and per node of the move (until P1 is back standing or in a chain from before) its ticks — the tick stops
    between its write and the next node write. A hit-freeze holds +0x20 (no tick is written), so freeze is outside by
    construction. Also the node writes' agreement with the SAMPLE trace inside the window (a +0x1C writer other than
    the walker would show as a disagreement)."""
    t0, mo = e["frame"], e["motion"]
    win = [x for x in ev if t0 - 30 <= x[0] < mo + WINDOW]
    commits = [x[0] for x in win if x[1] == "commit"]
    rec = {"commit_frames": commits}
    chain = lambda a: (nmap.get(a) or (None,))[0]
    before = {chain(n) for f, k, n in win if k == "node" and f < mo} | {chain(smp[f]) for f in smp if t0 - 30 <= f <= mo}
    # SAMPLE agreement: every sample in the window equals the last walker write labelled BEFORE its frame or the last
    # labelled AT it (a stop's label and a sample's fall either side of a frame boundary: measured on Felicia's LK GC,
    # a write labelled 2842 shows in the sample labelled 2842, one labelled 2815 first in 2816); a sample equal to
    # neither is a +0x1C writer the walker watch did not see
    writes = [(f, n) for f, k, n in ev if k == "node"]
    def last_before(fr, incl):
        v = None
        for f, n in writes:
            if f < fr or (incl and f == fr):
                v = n
            else:
                break
        return v
    # a frame can carry TWO walker writes (the engine's two passes) and its sample can fall between them (measured 14z-205:
    # Aulbath's LK GC writes 0x1d98e8 then 0x1d9888 in frame 2876, the sample reads the first) — so a sample is explained
    # by ANY walker write labelled at its frame, or by the last one before it
    at = {}
    for f, n in writes:
        at.setdefault(f, set()).add(n)
    rec["sample_mismatch"] = sum(1 for f, v in smp.items() if t0 - 30 <= f < mo + WINDOW
                                 and v != last_before(f, False) and v not in at.get(f, set()))
    if not commits:
        return rec
    nodes, cur, started = [], None, False
    for f, k, n in win:
        if f < commits[0]:
            continue
        if k == "node":
            c = chain(n)
            if not started:
                if c is None or c in before:
                    continue
                started = True; first = c
            elif c is None or c in BASELINE or (c in before and c != first):
                break
            cur = [n, c, nmap[n][2], 0, f]; nodes.append(cur)
        elif k == "tick" and cur is not None:
            cur[3] += 1
    if not nodes:
        return rec
    rec["t_chain"] = nodes[0][1]
    seq = []
    for n in nodes:
        if not seq or seq[-1] != n[1]:
            seq.append(n[1])
    rec["t_move_chains"] = seq
    rec["t_enter_frame"] = nodes[0][4]
    atk = [i for i, n in enumerate(nodes) if n[2]]
    rec["t_ticks"] = sum(n[3] for n in nodes)
    if atk:
        rec["t_startup"] = sum(n[3] for n in nodes[:atk[0]])
        parts, run, gap = [], 0, 0
        for n in nodes[atk[0]:atk[-1] + 1]:
            if n[2]:
                if gap:
                    parts.append(f"({gap})"); gap = 0
                run += n[3]
            else:
                if run:
                    parts.append(str(run)); run = 0
                gap += n[3]
        if run:
            parts.append(str(run))
        rec["t_active_runs"] = "".join(parts)
        rec["t_active"] = sum(n[3] for n in nodes[atk[0]:atk[-1] + 1] if n[2])
        rec["t_recovery"] = sum(n[3] for n in nodes[atk[-1] + 1:])
    return rec


def rows2(sched_path, legs, img_path):
    """One row per event from the ALIGNED legs: <legs>/trace/trace.txt (always) and <legs>/nostop/ (where run)."""
    sched = json.loads(Path(sched_path).read_text())
    img = Path(img_path).read_bytes()
    cid = int(sched["char"], 16)
    nmap = node_map(img, cid)
    global HSET
    bank = vf.bank_rows(Path(__file__).resolve().parent.parent / "build/manifest/bank_map.toml")
    HSET = hitbox_records.HitboxSet.from_image(img, vf.row_ptr(img, bank["hitbox_base"], cid),
                                              vf.row_ptr(img, bank["hitbox_comp"], cid))
    e = sched["events"][0]
    ev, smp, ended = trace_events(Path(legs) / "trace" / "trace.txt")
    tm = tick_measure(e, ev, smp, nmap)
    ns = Path(legs) / "nostop"
    if ns.is_dir():
        fr = dump_samples(ns, range(e["frame"] - 30, e["motion"] + WINDOW))
        r = event_row(e, fr, nmap, sched["kind"], None)
        r["dumped"] = len(fr); r["dump_need"] = e["motion"] + WINDOW - (e["frame"] - 30)
    else:
        r = {"kind": sched["kind"], "button": e["button"], "frame": e["frame"], "motion": e["motion"], "gc_chain": "-"}
    r["sheet"] = sched["sheet"]
    r["victim"] = sched.get("victim")
    r.update(tm)
    r["trace_ended"] = ended
    # the GC: the trace leg's commit by the commit routine AND a chain entered after it there
    r["gc"] = bool(tm.get("commit_frames")) and tm.get("t_chain") is not None
    if ns.is_dir():
        # THE LEGS AGREE on the GC chain, and the nostop leg's a2 chains (the move's own) are a SUBSEQUENCE of the trace's:
        # a frame-rate view can miss a chain visited for less than a frame (Lei-Lei's a2:0x3c between 0x3d and 0x3f) but
        # cannot invent one; the a:/b: chains at the move's end are where the two legs' end rules differ (measured 14z-205)
        def sub(a, b):
            it = iter(b)
            return all(x in it for x in a)
        a2 = lambda xs: [x for x in (xs or []) if x.startswith("a2:")]
        r["legs_agree"] = (not r["gc"]) or (r.get("gc_chain") == tm.get("t_chain") and sub(a2(r.get("move_chains")), a2(tm.get("t_move_chains"))))
    print(json.dumps(r))


def table2(rows):
    """The hashed body: one line per event — identity, the move in TICKS, the records, the stock cost; the gc kind's
    first dealt fall (the workbook's damage reading) and the whiff kind's meter gain (its gauge whiff)."""
    out = []
    for r in rows:
        g = r["gc"]
        recs = ";".join(",".join(f"{x['idx']}:{x.get('real')}/{x.get('white')}:{x.get('meter')}:{x.get('hit_id')}" for x in run)
                        for run in r.get("run_records", [])) if g else "-"
        f1 = (r.get("falls") or [None])[0]
        extra = "-"
        if g and r["kind"] in ("gc", "dealt"):
            extra = f"fall {f1[1]}/{f1[2]}" if f1 else "no fall"
            if r["kind"] == "dealt":
                extra += f" on {r.get('victim')}"
        if g and r["kind"] == "whiff":
            extra = f"gain {r['meter_end'] - r['meter_before']}" if None not in (r.get("meter_end"), r.get("meter_before")) else "gain -"
        out.append("\t".join(str(v) for v in (r["kind"], r["sheet"], r["button"], "GC" if g else "no",
              r.get("t_chain", "-") if g else "-", ">".join(r.get("t_move_chains", [])) if g else "-",
              r.get("t_startup", "-") if g else "-", r.get("t_active_runs", "-") if g else "-",
              r.get("t_recovery", "-") if g else "-", recs,
              (r["stock_before"] - r["stock_end"]) if g and None not in (r.get("stock_before"), r.get("stock_end")) else "-",
              extra)))
    return "\n".join(out) + "\n"


def join2(rows_path, xlsx, kind):
    """The workbook's GC rows against the gate's rows (rows_path, each with its `rig`), timing in ENGINE TICKS, from the
    events of <kind> (whiff or gc): startup, active (total over the runs; the runs string is reported), recovery."""
    from crosscheck_framedata import classify
    rows = {r["rig"]: r for r in map(json.loads, open(rows_path))}
    pairs, lines = {}, []
    for tab, i, d in wb_rows(xlsx):
        inp = str(d.get("input") or "").strip().upper()
        m = re.fullmatch(r"623([A-Z]+)", inp)
        btns = INPUT_BUTTONS.get(m.group(1)) if m else []
        sc = sheet_cols(d)
        for b in btns:
            r = rows.get(f"{kind}_{tab}_{b}")
            if not r or not r.get("gc"):
                continue
            ours = {"startup": r.get("t_startup"), "active": r.get("t_active"), "recovery": r.get("t_recovery")}
            cells = []
            for k, ov in ours.items():
                sv = sc.get(k)
                cells.append(f"{k} {sv}/{ov}" + (f"({sv - ov:+g})" if None not in (sv, ov) else ""))
                if None not in (sv, ov):
                    pairs.setdefault(k, []).append((f"{tab} {d.get('move')} {b}", sv, ov))
            lines.append(f"{tab} {str(d.get('move'))[:26]:26} {b} sheet active {str(d.get('active')).replace('.0', '')!r:16} ours {r.get('t_active_runs')}  " + "  ".join(cells))
    return lines, {k: classify(v) for k, v in pairs.items()}, pairs


def main():
    a = sys.argv[1:]
    if a[:1] == ["gen"] and len(a) == 2:
        return gen(a[1])
    if a[:1] == ["rows"] and len(a) in (4, 5):
        return rows(*a[1:])
    if a[:1] == ["join"] and len(a) in (3, 4):
        return main_join(*a[1:])
    if a[:1] == ["capspec"] and len(a) == 2:
        print("\n".join(cap_spec(a[1]))); return 0
    if a[:1] == ["sheet"] and len(a) >= 4:
        return sheet(a[1], a[2], a[3:])
    if a[:1] == ["gen2"] and len(a) == 2:
        return gen(a[1], kinds=["gc", "noblock", "whiff", "dealt"])
    if a[:1] == ["rows2"] and len(a) == 4:
        return rows2(*a[1:])
    if a[:1] == ["table2"] and len(a) == 2:
        sys.stdout.write(table2([json.loads(l) for l in open(a[1])])); return 0
    if a[:1] == ["traceenv"] and len(a) == 2:
        print(" ".join(f"{k}={v}" for k, v in trace_env(json.loads(Path(a[1]).read_text())).items())); return 0
    if a[:1] == ["dumps"] and len(a) == 2:
        print(nostop_dumps(json.loads(Path(a[1]).read_text()))); return 0
    if a[:1] == ["join2"] and len(a) == 4:
        lines, verdicts, pairs = join2(a[1], a[2], a[3])
        print("\n".join(lines)); print("--- verdicts (sheet - ours, ENGINE TICKS, kind " + a[3] + ")")
        for k, (v, det) in verdicts.items():
            print(f"{k:10} {v:16} {det}")
        import collections
        from crosscheck_framedata import classify
        for k in ("startup", "active", "recovery"):
            per = collections.defaultdict(list)
            for n, sv, ov in pairs.get(k, []):
                per[n.split()[0]].append((n, sv, ov))
            print(k, "per character:", " ".join(f"{t}={classify(v)[0].replace('CONSTANT OFFSET', 'OFF')}" + (f"({classify(v)[1].split(' on')[0].replace('sheet = ours ', '')})" if classify(v)[0] == "CONSTANT OFFSET" else "") for t, v in per.items()))
        return 0
    if a[:1] == ["whiffconnects"]:
        print(WHIFF_CONNECTS); return 0
    if a[:1] == ["gcbuttons"]:
        print(" ".join(f"{t}_{b}" for t in TABS for b in GC_BUTTONS[t].split())); return 0
    if a[:1] == ["rtap"]:
        print(RTAP); return 0
    if a[:1] == ["fields"]:
        print(FIELDS); return 0
    sys.exit(__doc__)


if __name__ == "__main__":
    sys.exit(main() or 0)
