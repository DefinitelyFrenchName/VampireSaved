#!/usr/bin/env python3
"""crosscheck_229.py — #229's COLUMN CLASSIFICATION for the families the cross-check page did not yet classify on the
current gates (14z-209, the maintainer: "Classify all, then close"): specials B (LE LI MO QB SA VI ZA), ES/EX, the
command throws, the guard cancels and the normal throws ground and air (the air rows moved there 14z-208c), each read
from a KEPT run of its own gate against the maintainer's workbook,
under the page's classifier (tools/crosscheck_framedata.py `classify`: EXACT / CONSTANT OFFSET / CONSTANT RATIO /
INCONSISTENT, sheet minus ours) and its conventions (timing in ENGINE TICKS; red = the record's real + white power
class, #241; a column with no comparable pair is NO DATA, a row without a comparable cell is UNCOMPARABLE and counted).

The rulings it applies (DECISIONS_HISTORY.md, #229): Q4 — a row whose workbook input differs joins under the ENGINE's
input (the rig tools' event tables carry the join); Q5 — guard-cancel damage is compared as DEALT on a -3 victim
(Gallon, Zabel on Gallon's own rows: the gate's `dealt_*` events, their first fall); Q6 — a guard cancel's timing of
record is the HIT (the gate's `gc_*` events, P2 Demitri), never the whiff; Q2 — nothing here re-reads the pursuits.
#331 — a row the workbook NAMES a guard cancel ("... GC") but types otherwise (Demitri's four DEMON CRADLE GC rows,
typed `special` / `es special`) is in the guard cancels' row set (tools/gc_rigs.py is_gc_row) and joins like any other;
until 14z-210 it was printed NOT RUN with its reason (gc_named_untyped, retired when the gate began running Demitri).

Each family is a loader (fam_*: the files) over a PURE function (classify_es, aggregate_ct, classify_gc, classify_gt;
specials B uses tools/specials_b_rigs.py verdicts) so the verdict logic runs on fixtures: tests/test_crosscheck_229.sh
holds every class it can return on cases whose verdict is known ([VSP-19]).

Every per-move value stays OUT of the tree (the 14z-126 frame-data ruling): `--pairs DIR` writes the joined pairs
there (sheet, ours, delta per move), outside the repository; stdout carries verdicts and counts only.

  python3 tools/crosscheck_229.py sb <specials_b KEEP dir> <vsavj data image> [--sheet X] [--pairs DIR]
  python3 tools/crosscheck_229.py es <es_ex OUT dir> [--sheet X] [--pairs DIR]
  python3 tools/crosscheck_229.py ct <command_throws OUT dir> <vsavj data image> [--sheet X] [--pairs DIR]
  python3 tools/crosscheck_229.py gc <guard_cancels OUT dir> [--sheet X] [--pairs DIR]
  python3 tools/crosscheck_229.py gt-ground|gt-air <ground_throws OUT dir> [--sheet X] [--pairs DIR]
  python3 tools/crosscheck_229.py tr-ground <full lines> [<full lines, another victim> ...] [--sheet X] [--pairs DIR]
                                   (#330: tests/audit_throw_recovery.sh's full lines, the gate's own victim first)
  python3 tools/crosscheck_229.py tr-air <full lines> [<full lines, another height> ...] [--sheet X] [--pairs DIR]
  python3 tools/crosscheck_229.py tr-command <full lines> [--sheet X] [--pairs DIR]

Output: one line per (family, scope, column): `FAMILY<TAB>scope<TAB>column<TAB>verdict<TAB>detail<TAB>compared N<TAB>
uncomparable M`, scope ALL then each character; then `ROWS` lines (row statuses with counts)."""
import collections
import contextlib
import io
import json
import os
import re
import subprocess
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import crosscheck_framedata as cf  # noqa: E402

REPO = Path(__file__).resolve().parent.parent


def emit(fam, pairs, unc, order=None):
    """pairs: column -> [(row id 'TAB ...', sheet, ours)]; unc: column -> Counter(reason) -> lines."""
    out = []
    cols = order or sorted(set(pairs) | set(unc))
    tabs = sorted({p[0].split()[0] for ps in pairs.values() for p in ps} | {k[1] for c in unc for k in unc[c]})
    for scope in ["ALL"] + tabs:
        for c in cols:
            ps = [p for p in pairs.get(c, []) if scope == "ALL" or p[0].split()[0] == scope]
            un = sum(n for (why, t), n in unc.get(c, {}).items() if scope == "ALL" or t == scope)
            v, det = cf.classify(ps)
            out.append(f"{fam}\t{scope}\t{c}\t{v}\t{det}\tcompared {len(ps)}\tuncomparable {un}")
    return out


def uncount(unc, c, why, tab):
    unc.setdefault(c, collections.Counter())[(why, tab)] += 1


def write_pairs(d, fam, pairs, extra=None):
    if not d:
        return
    Path(d).mkdir(parents=True, exist_ok=True)
    with open(Path(d) / f"{fam}_pairs.tsv", "w") as f:
        for c, ps in pairs.items():
            for rid, s, o in ps:
                f.write(f"{c}\t{rid}\t{s:g}\t{o:g}\t{s - o:+g}\n")
    if extra:
        (Path(d) / f"{fam}_rows.json").write_text(json.dumps(extra, indent=1) + "\n")


def unc_lines(fam, unc):
    out = []
    for c in sorted(unc):
        for (why, tab), n in sorted(unc[c].items()):
            out.append(f"UNCOMPARABLE\t{fam}\t{c}\t{tab}\t{n}\t{why}")
    return out


# ---------------------------------------------------------------- specials B: tools/specials_b_rigs.py's join + verdicts
def fam_sb(keep, image, sheet, pairs_dir):
    import specials_b_rigs as sb
    rows = sb.join(keep, image, sheet, gate=True)
    lines = sb.verdicts(rows)
    st = collections.Counter(r["status"] for r in rows)
    out = [f"SB\t{l}" for l in lines]
    out.append(f"ROWS\tSB\t{len(rows)} workbook rows\t" + ", ".join(f"{k} {v}" for k, v in sorted(st.items())))
    out.append(f"ROWS\tSB\tCONTACT (timing not classified: the whiff event touched P2)\t"
               f"{sum(1 for r in rows if r.get('status') == 'FIRED' and r.get('contact'))}")
    if pairs_dir:
        pr = collections.defaultdict(list)
        for r in rows:
            for c, v in (r.get("cols") or {}).items():
                if v["sheet"] is not None and v["ours"] is not None:
                    pr[c].append((f"{r['tab']} {r['move']}", v["sheet"], v["ours"]))
        write_pairs(pairs_dir, "SB", pr)
    return out


# ---------------------------------------------------------------- ES/EX: fork F3's compare.py (14z-205), on the gate's rows
def fam_es(outdir, sheet, pairs_dir):
    import xlsx_read
    import es_ex_rigs as ex
    rows = {(r["sheet"], r["leg"], r["key"]): r for r in map(json.loads, open(Path(outdir) / "rows.jsonl"))}
    recs = {(r["sheet"], r["leg"], r["key"]): r for r in map(json.loads, open(Path(outdir) / "recs.jsonl"))}
    pairs, unc, st = classify_es(xlsx_read.Workbook(sheet), rows, recs, ex.EVENTS, ex.FAMILY,
                                 getattr(ex, "NOT_HERE", {}), getattr(ex, "UNRESOLVED", {}))
    write_pairs(pairs_dir, "ES", pairs)
    out = emit("ES", pairs, unc, ES_COLS)
    out.append("ROWS\tES\t" + ", ".join(f"{k} {v}" for k, v in sorted(st.items())))
    return out + unc_lines("ES", unc)


ES_COLS = ["red", "white", "gauge_hit", "startup", "active", "recovery"]


def classify_es(wb, rows, recs, events, family, not_here, unresolved):
    """PURE (no file read): the workbook (`sheet_names`, `rows(tab)`) against the gate's rows and records keyed
    (sheet, leg, key) -> (pairs, uncomparable, row statuses). The join is by (tab, move, input) through the rig
    tool's EVENTS (Q4: an input the engine reads differently is listed there under the engine's)."""
    ex = type("ex", (), {"FAMILY": family, "NOT_HERE": not_here, "UNRESOLVED": unresolved})
    key_of = {}
    for tab, evs in events.items():
        for key, moves, inp, _rec in evs:
            for mv in moves:
                key_of.setdefault((tab, mv, inp), []).append(key)

    def first_num(cell):
        m = re.match(r"\s*\(?\s*(\d+)", str(cell))
        return int(m.group(1)) if m else None

    def num(cell):
        s = cf._plain(cell) if cell is not None else ""
        return float(s) if re.fullmatch(r"-?\d+(\.\d+)?", s) else None

    pairs, unc, st = collections.defaultdict(list), {}, collections.Counter()
    COLS = ES_COLS
    for tab in wb.sheet_names:
        for d in wb.rows(tab):
            t = (d.get("type") or "").strip().lower()
            if t not in ex.FAMILY:
                continue
            mv, inp = d.get("move"), str(d.get("input"))
            if (tab, mv) in getattr(ex, "NOT_HERE", {}):
                st["NOT HERE (another family's row)"] += 1; continue
            keys = key_of.get((tab, mv, inp), [])
            if not keys:
                st["UNJOINED (no event)"] += 1
                for c in COLS:
                    uncount(unc, c, "row not joined", tab)
                continue
            key = keys[0]
            if (tab, key) in getattr(ex, "UNRESOLVED", {}):
                st["UNRESOLVED"] += 1
                for c in COLS:
                    uncount(unc, c, "row unresolved", tab)
                continue
            if (tab, "near", key) not in rows:
                st["NO ROW in the gate's run"] += 1
                for c in COLS:
                    uncount(unc, c, "no row in the run", tab)
                continue
            _mv = rows[(tab, "near", key)].get("move_at") or 0
            leg = "near" if any(x["rel"] >= _mv - 1 for x in recs[(tab, "near", key)]["records"]) else "far"
            r, rc = rows[(tab, leg, key)], recs[(tab, leg, key)]["records"]
            rc = [x for x in rc if r.get("move_at") is None or x["rel"] >= r["move_at"] - 1]
            if not str(r.get("status", "")).startswith("FIRED"):
                st[f"status {r.get('status')}"] += 1
                for c in COLS:
                    uncount(unc, c, f"event {r.get('status')}", tab)
                continue
            st["JOINED"] += 1
            rid = f"{tab} {mv} [{inp}] ({leg})"
            proj = "projectile" in t
            if rc:
                for c, s, o in (("red", first_num(d.get("red damage")), rc[0]["real"] + rc[0]["white"]),
                                ("white", first_num(d.get("white damage")), rc[0]["white"])):
                    pairs[c].append((rid, s, o)) if s is not None else uncount(unc, c, "prose or empty sheet cell", tab)
            else:
                for c in ("red", "white"):
                    uncount(unc, c, "no record staged", tab)
            s, o = cf.parse_total(d.get("guage hit")), r.get("meter_change_from_move")
            pairs["gauge_hit"].append((rid, s, o)) if None not in (s, o) else uncount(
                unc, "gauge_hit", "prose sheet cell" if s is None else "meter not read", tab)
            tk = r.get("tick") or {}
            if proj or "startup_t" not in tk:
                for c in ("startup", "active", "recovery"):
                    uncount(unc, c, "projectile (P1 carries no attack node)" if proj else "no attack node on P1", tab)
            else:
                for c, k, parse in (("startup", "startup_t", num), ("active", "active_t", cf.parse_runs),
                                    ("recovery", "recovery_t", num)):
                    sv = parse(d.get(c))
                    pairs[c].append((rid, sv, tk[k])) if sv is not None and tk.get(k) is not None else uncount(
                        unc, c, "prose or empty sheet cell" if sv is None else "not measured", tab)
    return pairs, unc, st


# ---------------------------------------------------------------- command throws: tools/command_throw_rigs.py's join
def fam_ct(outdir, image, sheet, pairs_dir):
    import command_throw_rigs as ctr
    legs, rigs = Path(outdir) / "legs", REPO / "tests/replays/command_throws"
    tr_rows, rec_rows = [], []
    for j in sorted(rigs.glob("ct_*.json")):
        rig = j.stem
        rows = [json.loads(l) for l in open(legs / rig / "trace" / "rows.jsonl") if l.strip()]
        tr_rows += rows
        by_label = {r["label"]: r for r in rows}
        for leg in ("0189ea", "02979a"):
            ldir = legs / rig / ("p" + leg)
            out = subprocess.run([sys.executable, str(REPO / "tools/command_throw_rigs.py"), "records", str(j), str(ldir),
                                  image], capture_output=True, text=True, check=True).stdout
            for l in out.splitlines():
                x = json.loads(l)
                r = by_label.get(x["label"])
                if r:
                    rec_rows.append({"sheet": r["sheet"], "part": r["part"], "label": x["label"], "leg": leg,
                                     "records": x["records"]})
    tmp = Path(pairs_dir or os.environ.get("TMPDIR", "/tmp")) / "ct_join_inputs"
    tmp.mkdir(parents=True, exist_ok=True)
    (tmp / "trace_rows.jsonl").write_text("".join(json.dumps(r) + "\n" for r in tr_rows))
    (tmp / "records.jsonl").write_text("".join(json.dumps(r) + "\n" for r in rec_rows))
    buf = io.StringIO()
    with contextlib.redirect_stdout(buf):
        ctr.join(tmp / "trace_rows.jsonl", tmp / "records.jsonl", sheet)
    joined = [json.loads(l) for l in buf.getvalue().splitlines() if l.strip()]
    pairs, unc, st, series, series_tab = aggregate_ct(joined)
    write_pairs(pairs_dir, "CT", pairs, joined)
    return render_ct(pairs, unc, st, series, series_tab)


def aggregate_ct(joined):
    """PURE: tools/command_throw_rigs.py join's rows (one per workbook row, each column's per-row verdict from
    match_series) -> (startup pairs, uncomparable, statuses, per-column verdict counts, the same per character)."""
    pairs, unc, st = collections.defaultdict(list), {}, collections.Counter()
    series = {c: collections.Counter() for c in ("red", "white", "gauge")}
    series_tab = collections.defaultdict(collections.Counter)
    for row in joined:
        tab = row["sheet"]
        if not row["events"]:
            st["NOT RUN (no rig event)"] += 1; continue
        if not row["grabbed"]:
            st["RUN, NEVER GRABBED"] += 1
            for c in ("red", "white", "gauge", "startup"):
                uncount(unc, c, "the row's events never held P2", tab)
            continue
        st["GRABBED"] += 1
        if not row.get("strengths_agree", True):
            st["GRABBED, strengths differ (first grab compared)"] += 1
        for c in ("red", "white", "gauge"):
            v, det = row[c]
            series[c][v] += 1
            series_tab[(c, tab)][v] += 1
            if v == "UNCOMPARABLE":
                uncount(unc, c, "prose sheet cell" if "sheet cell" in det else "includes the input's own normals", tab)
        v, det = row.get("startup", ("-", ""))
        m = re.match(r"sheet (\S+) - ours (\S+)", det)
        if v == "OFFSET" and m:
            pairs["startup (press to hold)"].append((f"{tab} {row['row']}", float(m.group(1)), float(m.group(2))))
        else:
            uncount(unc, "startup (press to hold)", "prose sheet cell" if v == "UNCOMPARABLE" else "no hold frame", tab)
    return pairs, unc, st, series, series_tab


def render_ct(pairs, unc, st, series, series_tab):
    out = emit("CT", pairs, unc, ["startup (press to hold)"])
    for c in ("red", "white", "gauge"):
        out.append(f"CT\tALL\t{c} (per row: the hit series, match_series)\t" + ", ".join(
            f"{k} {v}" for k, v in sorted(series[c].items())))
        for (cc, tab), cnt in sorted(series_tab.items()):
            if cc == c:
                out.append(f"CT\t{tab}\t{c} (per row)\t" + ", ".join(f"{k} {v}" for k, v in sorted(cnt.items())))
    out.append("ROWS\tCT\t" + ", ".join(f"{k} {v}" for k, v in sorted(st.items())))
    return out + unc_lines("CT", unc)


# ---------------------------------------------------------------- guard cancels: tools/gc_rigs.py, Q5 + Q6
def fam_gc(outdir, sheet, pairs_dir):
    import gc_rigs as gc
    rows_path = Path(outdir) / "rows.jsonl"
    rows = {r["rig"]: r for r in map(json.loads, open(rows_path))}
    pairs, unc, st, victims = classify_gc(gc.wb_rows(sheet), rows)
    write_pairs(pairs_dir, "GC", pairs)
    out = emit("GC", pairs, unc, GC_COLS)
    out.append("ROWS\tGC\t" + ", ".join(f"{k} {v}" for k, v in sorted(st.items())) +
               "\tdealt victims " + ", ".join(f"{k} {v}" for k, v in sorted(victims.items())))
    return out + unc_lines("GC", unc)


GC_COLS = ["startup", "active", "recovery", "red (dealt, -3 victim)", "white (dealt, -3 victim)", "gauge_whiff", "gauge_hit"]


def classify_gc(wb_rows, rows, timing_kind="gc", damage_kind="dealt"):
    """PURE: the workbook's guard-cancel rows [(tab, i, row)] against the gate's rows keyed by rig name ->
    (pairs, uncomparable, statuses, dealt victims). Q6: the timing is read from the `timing_kind` events, the HIT
    (gc); Q5: the damage from the `damage_kind` events, DEALT on the -3 victim. The two kinds are parameters only so
    the verdict test can show that feeding another kind changes the verdict; the tool always passes the ruled ones."""
    import gc_rigs as gc
    pairs, unc, st = collections.defaultdict(list), {}, collections.Counter()
    for tab, _i, d in wb_rows:
        inp = str(d.get("input") or "").strip().upper()
        m = re.fullmatch(r"623([A-Z]+)", inp)
        btns = gc.INPUT_BUTTONS.get(m.group(1)) if m else None
        if not btns:
            st["UNJOINED (no 623 button set)"] += 1; continue
        sc = gc.sheet_cols(d)
        fired = [b for b in btns if (rows.get(f"{timing_kind}_{tab}_{b}") or {}).get("gc")]
        if not fired:
            st["UNJOINED (no button committed)"] += 1; continue
        st["JOINED"] += 1
        for b in fired:
            rid = f"{tab} {d.get('move')} {b}"
            g = rows[f"{timing_kind}_{tab}_{b}"]
            # Q6: the timing of record is the HIT (the gc event), in engine ticks
            for c, k in (("startup", "t_startup"), ("active", "t_active"), ("recovery", "t_recovery")):
                sv, ov = sc.get(c), g.get(k)
                pairs[c].append((rid, sv, ov)) if None not in (sv, ov) else uncount(
                    unc, c, "prose or empty sheet cell" if sv is None else "no attack on P1 (another object hits, or none)", tab)
            # Q5: damage DEALT on the -3 victim (the dealt event's first fall); its victim named per pair
            dl = rows.get(f"{damage_kind}_{tab}_{b}") or {}
            oc = gc.ours_cols(dl) if dl.get("gc") else {}
            for c, sk in (("red (dealt, -3 victim)", "dealt_red"), ("white (dealt, -3 victim)", "dealt_white")):
                sv, ov = sc.get(sk), oc.get(sk)
                pairs[c].append((rid, sv, ov)) if None not in (sv, ov) else uncount(
                    unc, c, "prose or empty sheet cell" if sv is None else ("no dealt event" if not dl else "no fall on the victim"), tab)
            # gauge: the whiff event's own gain (nothing landed), and the hit cell as the page's 2b rule (swing + record)
            wh = rows.get(f"whiff_{tab}_{b}") or {}
            ow = gc.ours_cols(wh) if wh.get("gc") else {}
            og = gc.ours_cols(g)
            for c, sk, ov in (("gauge_whiff", "gauge_whiff", ow.get("gauge_whiff")), ("gauge_hit", "gauge_hit", og.get("gauge_hit"))):
                sv = sc.get(sk)
                pairs[c].append((rid, sv, ov)) if None not in (sv, ov) else uncount(
                    unc, c, "prose or empty sheet cell" if sv is None else "not readable (a fall with no record of P1's)", tab)
    victims = collections.Counter((r.get("victim") or "?") for k, r in rows.items() if k.startswith(damage_kind + "_") and r.get("gc"))
    return pairs, unc, st, victims


# ---------------------------------------------------------------- the normal throws, ground and air: tools/ground_throw_rigs.py
GT_COLS = ["startup (press to hold)"]


def classify_gt(wb, rows, scope):
    """PURE: the workbook's normal-throw rows of `scope` ("ground" or "air") against the gate's event rows
    (tests/audit_ground_throws.sh rows.jsonl) -> (startup pairs, uncomparable, statuses, per-column verdict counts,
    the same per character). The page's ground-throw rules: a row's events are its rig's events of that move key
    (ground_throw_rigs.MOVE_KEY; the air rows' key is AIR, run as j.6MP and j.6HP); the first HELD event is compared,
    the others must stage the same hits and pay the same gauge; damage is every LANDED damaging record's power class
    (real + white for red, white where non-zero, #241) in frame order, compared as the sheet cell's hit series
    (tools/command_throw_rigs.py parse_series / match_series: a ranged count must contain ours); gauge is the meter
    paid (P1's meter at the event's end, pinned to 0 before it) against the sheet's `guage hit` when it is a fixed
    series; startup is press-to-hold against the sheet's startup, classified by the page's classify."""
    import command_throw_rigs as ctr
    import ground_throw_rigs as gtr
    pairs, unc, st = collections.defaultdict(list), {}, collections.Counter()
    series = {c: collections.Counter() for c in ("red", "white", "gauge")}
    series_tab = collections.defaultdict(collections.Counter)
    for tab in wb.sheet_names:
        for d in wb.rows(tab):
            ty = str(d.get("type") or "").strip().lower()
            is_air = ty == "air throw"
            if not (("ground throw" in ty) or is_air) or (scope == "air") != is_air:
                continue
            mv = "AIR THROW" if is_air else str(d.get("move") or "").strip().upper()
            if (tab, mv) in gtr.NOT_MEASURED:
                st["DECLARED NOT MEASURED"] += 1; continue
            key = gtr.MOVE_KEY.get(mv)
            if key is None and not mv and len({k for k, _, _ in gtr.THROWS.get(tab, [])}) == 1:
                # an empty move cell (Bishamon's ground throw): the tab's one ground-throw key, both buttons of it
                key = next(k for k, _, _ in gtr.THROWS[tab]); st["JOINED BY THE TAB'S ONE KEY (empty move cell)"] += 1
            if key is None:
                st["UNMAPPED workbook row"] += 1; continue
            evs = sorted((r for r in rows if r["sheet"] == tab and r["key"] == key), key=lambda r: r["press"])
            if not evs:
                st["NOT RUN"] += 1; continue
            held = [r for r in evs if r.get("press_to_hold") is not None]
            if not held:
                st["NEVER HELD"] += 1
                for c in ("red", "white", "gauge", "startup (press to hold)"):
                    uncount(unc, c, "no event held P2", tab)
                continue
            st["HELD"] += 1

            def hits(r):
                h = sorted((x for x in r["records"] if (x["real"] or x["white"]) and x["landed"]),
                           key=lambda x: (x["frame"], x["site"]))
                return [x["real"] + x["white"] for x in h], [x["white"] for x in h if x["white"]], r.get("meter_end")
            sig = [hits(r) for r in held]
            if any(x != sig[0] for x in sig):
                st["HELD, events differ (first compared)"] += 1
            red, white, gauge = sig[0]
            for c, cell, ours in (("red", d.get("red damage"), red), ("white", d.get("white damage"), white)):
                t = ctr.parse_series(cell)
                v = ("UNCOMPARABLE", "prose sheet cell") if t is None else ctr.match_series(t, ours)
                # THE PAGE'S WHITE RULE (the ground-throw section, 14z-195): a MULTI-HIT throw's white cell that does not
                # decompose into our per-hit whites is UNCOMPARABLE, not a disagreement (VI 4, ZA 7, DE 4+2, FE 2+2)
                if c == "white" and v[0] == "INCONSISTENT" and len(red) > 1:
                    v = ("UNCOMPARABLE", "a multi-hit throw's white cell does not decompose into per-hit whites")
                series[c][v[0]] += 1; series_tab[(c, tab)][v[0]] += 1
                if v[0] == "UNCOMPARABLE":
                    uncount(unc, c, v[1], tab)
            gt_ = ctr.parse_series(d.get("guage hit"))
            if gt_ is not None and all(lo == hi for _, lo, hi in gt_) and gauge is not None:
                gv = "EXACT" if sum(v * lo for v, lo, _ in gt_) == gauge else "INCONSISTENT"
            else:
                gv = "UNCOMPARABLE"; uncount(unc, "gauge", "prose sheet cell or no meter read", tab)
            series["gauge"][gv] += 1; series_tab[("gauge", tab)][gv] += 1
            sv = cf.num(cf._plain(d.get("startup"))) if d.get("startup") is not None else None
            if sv is not None:
                pairs["startup (press to hold)"].append((f"{tab} {mv} ({held[0]['input']})", sv, held[0]["press_to_hold"]))
            else:
                uncount(unc, "startup (press to hold)", "prose sheet cell", tab)
    return pairs, unc, st, series, series_tab


def fam_gt(outdir, sheet, scope, pairs_dir):
    import xlsx_read
    rows = [json.loads(l) for l in open(Path(outdir) / "rows.jsonl") if l.strip()]
    pairs, unc, st, series, series_tab = classify_gt(xlsx_read.Workbook(sheet), rows, scope)
    fam = "GT-" + scope.upper()
    write_pairs(pairs_dir, fam, pairs)
    out = emit(fam, pairs, unc, GT_COLS)
    for c in ("red", "white", "gauge"):
        out.append(f"{fam}\tALL\t{c} (per row: the hit series, match_series)\t" + ", ".join(
            f"{k} {v}" for k, v in sorted(series[c].items())))
        for (cc, tab), cnt in sorted(series_tab.items()):
            if cc == c:
                out.append(f"{fam}\t{tab}\t{c} (per row)\t" + ", ".join(f"{k} {v}" for k, v in sorted(cnt.items())))
    out.append(f"ROWS\t{fam}\t" + ", ".join(f"{k} {v}" for k, v in sorted(st.items())))
    return out + unc_lines(fam, unc)


# ---------------------------------------------------------------- the ground throws' recovery and throw tech: tools/throw_recovery_rigs.py (#330)
TR_COLS = ["recovery (thrower, thrown)", "throw tech (victim - thrower, teched)"]


def _tr_cell(c):
    """a workbook recovery / throw tech cell -> ('n', v) | ('range', lo, hi) | None (prose): "N + landing 1" is N + 1, the
    landing frame counted in (the thrower can act on it: tools/throw_recovery_rigs.py's ticks land there)"""
    t = cf._plain(c) if c is not None else ""
    m = re.fullmatch(r"\s*(-?\d+)(?:\.0)?\s*(\+\s*landing\s*(\d+))?\s*", t or "")
    if m:
        return ("n", int(m.group(1)) + (int(m.group(3)) if m.group(2) else 0))
    m = re.fullmatch(r"\s*(\d+)\s*-\s*(\d+)\s*", t or "")
    return ("range", int(m.group(1)), int(m.group(2))) if m else None


def classify_tr(wb, victims):
    """PURE: the workbook's ground-throw rows against the gate's full lines — victims is [(tag, {(sheet, key, input): row})],
    the FIRST the gate's own victim (Victor, Demitri for Victor), a row = {thr_thrown, vic_thrown, thr_tech, vic_tech}.
    The rulings (DECISIONS_HISTORY.md, 2026-10-28, #330): `recovery` against the thrower's first accepted tick when
    thrown, on the gate's victim — EXACT, OFF by d, or, against a range cell, INSIDE THE SHEET'S RANGE; `throw tech`
    against the advantage after a tech (victim minus thrower, teched) — EXACT on the gate's victim, INSIDE THE VICTIM
    RANGE when it lies within the victims' figures, otherwise INCONSISTENT by the distance to the nearest. A row's events
    (both buttons) must agree on every victim, else the row is UNCOMPARABLE. -> (pairs, per-row verdict counter per
    column, row statuses, the deltas per column)"""
    import ground_throw_rigs as gtr
    pairs, verdicts, st = collections.defaultdict(list), {c: collections.Counter() for c in TR_COLS}, collections.Counter()
    deltas = {c: [] for c in TR_COLS}
    for tab in wb.sheet_names:
        for d in wb.rows(tab):
            ty = str(d.get("type") or "").strip().lower()
            if "ground throw" not in ty:
                continue
            mv = str(d.get("move") or "").strip().upper()
            if (tab, mv) in gtr.NOT_MEASURED:
                st["DECLARED NOT MEASURED"] += 1; continue
            key = gtr.MOVE_KEY.get(mv) if mv else next((k for k, _, _ in gtr.THROWS.get(tab, [])), None)
            evs = [(tab, k, i) for k, i, _ in gtr.THROWS.get(tab, []) if k == key]
            per = []
            for _tag, rows in victims:
                vals = {(rows[e]["thr_thrown"], rows[e]["vic_tech"] - rows[e]["thr_tech"]) for e in evs if e in rows}
                per.append(vals)
            if not evs or not per[0]:
                st["NOT RUN"] += 1; continue
            if any(len(v) != 1 for v in per):
                st["EVENTS DIFFER"] += 1
                for c in TR_COLS:
                    verdicts[c]["UNCOMPARABLE"] += 1
                continue
            st["COMPARED"] += 1
            name = f"{tab} {mv or 'the tab one throw'}"
            (rec, adv), others = next(iter(per[0])), [next(iter(v))[1] for v in per[1:]]
            cell = _tr_cell(d.get("recovery"))
            c = TR_COLS[0]
            if cell is None:
                verdicts[c]["UNCOMPARABLE"] += 1
            elif cell[0] == "range":
                verdicts[c]["INSIDE THE SHEET'S RANGE" if cell[1] <= rec <= cell[2] else "OUTSIDE THE SHEET'S RANGE"] += 1
            else:
                pairs[c].append((name, cell[1], rec)); deltas[c].append(cell[1] - rec)
                verdicts[c]["EXACT" if cell[1] == rec else "OFF"] += 1
            cell = _tr_cell(d.get("throw tech"))
            c = TR_COLS[1]
            if cell is None or cell[0] != "n":
                verdicts[c]["UNCOMPARABLE"] += 1
            else:
                v = cell[1]; allv = [adv] + others
                pairs[c].append((name, v, adv)); deltas[c].append(v - adv)
                if v == adv:
                    verdicts[c]["EXACT"] += 1
                elif min(allv) <= v <= max(allv):
                    verdicts[c]["INSIDE THE VICTIM RANGE"] += 1
                else:
                    verdicts[c]["INCONSISTENT"] += 1
    return pairs, verdicts, st, deltas


def fam_tr(full_paths, sheet, pairs_dir):
    """the gate's full lines, one file per victim (the gate's own first), outside the tree"""
    import xlsx_read
    victims = []
    for p in full_paths:
        rows = {}
        for line in open(p):
            if line.startswith("#") or not line.strip():
                continue
            f = line.rstrip("\n").split("\t")
            rows[(f[0], f[1], f[2])] = dict(zip(("thr_thrown", "vic_thrown", "thr_tech", "vic_tech"), map(int, f[3:7])))
        victims.append((Path(p).stem, rows))
    pairs, verdicts, st, deltas = classify_tr(xlsx_read.Workbook(sheet), victims)
    write_pairs(pairs_dir, "TR-GROUND", pairs)
    out = emit("TR-GROUND", pairs, {}, TR_COLS)
    for c in TR_COLS:
        sp = collections.Counter(deltas[c])
        out.append(f"TR-GROUND\tALL\t{c} (per row)\t" + ", ".join(f"{k} {v}" for k, v in sorted(verdicts[c].items())) +
                   "\tsheet - ours: " + ", ".join(f"{k:+d} x{v}" for k, v in sorted(sp.items())))
    out.append("ROWS\tTR-GROUND\t" + ", ".join(f"{k} {v}" for k, v in sorted(st.items())))
    out.append(f"VICTIMS\tTR-GROUND\t{len(victims)}: " + ", ".join(t for t, _ in victims))
    return out


def _tr_sum(c):
    """an air throw's recovery cell -> the sum of its terms ("40 + 23 + landing 1" = 64, "79 + 1 + turn 1" = 81), or None
    when a term is prose ("variable + landing 1")"""
    t = cf._plain(c) if c is not None else ""
    terms = [x.strip() for x in re.split(r"\+", t or "") if x.strip()]
    if not terms:
        return None
    vals = []
    for x in terms:
        m = re.fullmatch(r"(?:[a-z ]*?)\s*(-?\d+)(?:\.0)?\s*(?:[a-z ]*)", x)
        if not m:
            return None
        vals.append(int(m.group(1)))
    return sum(vals)


def classify_tr_air(wb, heights):
    """PURE: the workbook's air-throw rows against the gate's air full lines at several HEIGHTS — heights is [(tag, {(sheet,
    key, input): row})], the rig's own height FIRST (the maintainer, 2026-10-28: "Against a height range"). recovery (the
    cell's terms summed) against the thrower's first accepted tick when thrown; throw tech against the advantage after a
    tech: EXACT at the rig's height, INSIDE THE HEIGHT RANGE within the heights' figures, otherwise INCONSISTENT; a prose
    or empty cell UNCOMPARABLE; a height a character does not throw at is absent from its range."""
    import ground_throw_rigs as gtr
    verdicts, st, deltas = {c: collections.Counter() for c in TR_COLS}, collections.Counter(), {c: [] for c in TR_COLS}
    for tab in wb.sheet_names:
        for d in wb.rows(tab):
            if str(d.get("type") or "").strip().lower() != "air throw":
                continue
            evs = [(tab, k, i) for k, i, _ in gtr.AIR.get(tab, [])]
            per = []
            for _tag, rows in heights:
                vals = {(rows[e]["thr_thrown"], rows[e]["vic_tech"] - rows[e]["thr_tech"]) for e in evs if e in rows}
                if vals:
                    per.append(vals)
            if not per:
                st["NOT RUN"] += 1; continue
            if any(len(v) != 1 for v in per):
                st["EVENTS DIFFER"] += 1
                for c in TR_COLS:
                    verdicts[c]["UNCOMPARABLE"] += 1
                continue
            st["COMPARED"] += 1
            ours = [next(iter(v)) for v in per]
            for ci, (c, cell) in enumerate(((TR_COLS[0], _tr_sum(d.get("recovery"))),
                                            (TR_COLS[1], (_tr_cell(d.get("throw tech")) or (None, None))[1]))):
                if cell is None:
                    verdicts[c]["UNCOMPARABLE"] += 1; continue
                allv = [o[ci] for o in ours]
                deltas[c].append(cell - allv[0])
                verdicts[c]["EXACT" if cell == allv[0] else "INSIDE THE HEIGHT RANGE" if min(allv) <= cell <= max(allv)
                           else "INCONSISTENT"] += 1
    return verdicts, st, deltas


def _tr_active(c):
    """a command throw's active cell -> frames: "1(5)1" = 7 (the bracket a gap the profile counts), a number, or None"""
    t = cf._plain(c) if c is not None else ""
    if re.fullmatch(r"\s*\d+(?:\.0)?\s*", t or ""):
        return int(float(t))
    m = re.fullmatch(r"\s*(\d+)\((\d+)\)(\d+)\s*", t or "")
    return sum(map(int, m.groups())) if m else None


def classify_tr_cmd(wb, rows):
    """PURE: the workbook's command-throw rows against the gate's command full lines — rows is {(sheet, row id, input):
    {whiff, window}}, the row id the command rigs' (tools/command_throw_rigs.py THROWS). The maintainer, 2026-10-28:
    "Whiff recovery + techability": the WHIFF profile startup + active + recovery against our whiff tick (the first
    accepted input from the press), one pair per event that whiffs (sheet minus ours, the page's classify); the throw
    tech cell against our window — the cells are empty on every row, so the window is counted, never classified."""
    pairs, st = collections.defaultdict(list), collections.Counter()
    win = collections.Counter()
    for tab in wb.sheet_names:
        # ONE row per event: the row whose move is the event's row id, else whose input is (Bishamon's empty move cells)
        by_move, by_input = {}, {}
        for d in wb.rows(tab):
            by_move.setdefault(str(d.get("move") or "").strip().upper(), d)
            by_input.setdefault(str(d.get("input") or "").strip().upper(), d)
        joined = collections.defaultdict(list)
        for k, v in rows.items():
            if k[0] == tab:
                d = by_move.get(k[1]) or by_input.get(k[1])
                if d is not None:
                    joined[id(d)].append((k, v, d))
        for evs in joined.values():
            d = evs[0][2]; evs = [(k, v) for k, v, _ in evs]
            st["JOINED"] += 1
            s, a, r = cf.num(cf._plain(d.get("startup"))), _tr_active(d.get("active")), cf.num(cf._plain(d.get("recovery")))
            for (t_, rid, inp), v in evs:
                win[v["window"]] += 1
                if v["whiff"] is None:
                    st["NO WHIFF (the input draws no move)"] += 1; continue
                if None in (s, a, r):
                    st["UNCOMPARABLE (a prose startup / active / recovery)"] += 1; continue
                pairs["whiff (startup + active + recovery)"].append((f"{tab} {rid} ({inp})", s + a + r, v["whiff"]))
            tc = d.get("throw tech")
            st["THROW TECH CELL EMPTY" if tc in (None, "") else "THROW TECH CELL GIVEN"] += 1
    return pairs, st, win


def fam_tr_air(full_paths, sheet, pairs_dir):
    import xlsx_read
    heights = []
    for p in full_paths:
        rows = {}
        for line in open(p):
            if line.startswith("#") or not line.strip():
                continue
            f = line.rstrip("\n").split("\t")
            rows[(f[0], f[1], f[2])] = dict(zip(("thr_thrown", "vic_thrown", "thr_tech", "vic_tech"), map(int, f[3:7])))
        heights.append((Path(p).stem, rows))
    verdicts, st, deltas = classify_tr_air(xlsx_read.Workbook(sheet), heights)
    out = []
    for c in TR_COLS:
        sp = collections.Counter(deltas[c])
        out.append(f"TR-AIR\tALL\t{c} (per row)\t" + ", ".join(f"{k} {v}" for k, v in sorted(verdicts[c].items())) +
                   "\tsheet - ours at the rig's height: " + ", ".join(f"{k:+d} x{v}" for k, v in sorted(sp.items())))
    out.append("ROWS\tTR-AIR\t" + ", ".join(f"{k} {v}" for k, v in sorted(st.items())))
    out.append(f"HEIGHTS\tTR-AIR\t{len(heights)}: " + ", ".join(t for t, _ in heights))
    return out


def fam_tr_cmd(full_path, sheet, pairs_dir):
    import xlsx_read
    rows = {}
    for line in open(full_path):
        if line.startswith("#") or not line.strip():
            continue
        f = line.rstrip("\n").split("\t")
        import command_throw_rigs as ctr
        tab, rig, inp = f[0], f[1], f[2]
        idx = int(rig.split("_")[-1]); ev = [e for e in ctr.THROWS[tab] if not e[1].startswith("motion ")][idx]
        rows[(tab, ev[0].upper(), inp)] = {"whiff": None if f[4] == "-" else int(f[4]), "window": f[7]}
    pairs, st, win = classify_tr_cmd(xlsx_read.Workbook(sheet), rows)
    write_pairs(pairs_dir, "TR-COMMAND", pairs)
    out = emit("TR-COMMAND", pairs, {}, ["whiff (startup + active + recovery)"])
    out.append("ROWS\tTR-COMMAND\t" + ", ".join(f"{k} {v}" for k, v in sorted(st.items())))
    out.append("WINDOW\tTR-COMMAND\t" + ", ".join(f"{k} {v}" for k, v in sorted(win.items())))
    return out


def main():
    a = sys.argv[1:]
    sheet = str(cf.DEFAULT_SHEET)
    pairs_dir = None
    if "--sheet" in a:
        i = a.index("--sheet"); sheet = a[i + 1]; del a[i:i + 2]
    if "--pairs" in a:
        i = a.index("--pairs"); pairs_dir = a[i + 1]; del a[i:i + 2]
        if Path(pairs_dir).resolve().is_relative_to(REPO.resolve()) and "build" not in Path(pairs_dir).resolve().relative_to(REPO.resolve()).parts[:1]:
            sys.exit("REFUSED: --pairs must lie outside the tree (or under build/): per-move values never enter it")
    if a[:1] == ["sb"] and len(a) == 3:
        out = fam_sb(a[1], a[2], sheet, pairs_dir)
    elif a[:1] == ["es"] and len(a) == 2:
        out = fam_es(a[1], sheet, pairs_dir)
    elif a[:1] == ["ct"] and len(a) == 3:
        out = fam_ct(a[1], a[2], sheet, pairs_dir)
    elif a[:1] == ["gc"] and len(a) == 2:
        out = fam_gc(a[1], sheet, pairs_dir)
    elif a[:1] in (["gt-ground"], ["gt-air"]) and len(a) == 2:
        out = fam_gt(a[1], sheet, a[0].split("-")[1], pairs_dir)
    elif a[:1] == ["tr-ground"] and len(a) >= 2:
        out = fam_tr(a[1:], sheet, pairs_dir)
    elif a[:1] == ["tr-air"] and len(a) >= 2:
        out = fam_tr_air(a[1:], sheet, pairs_dir)
    elif a[:1] == ["tr-command"] and len(a) == 2:
        out = fam_tr_cmd(a[1], sheet, pairs_dir)
    else:
        sys.exit(__doc__)
    print("\n".join(out))
    return 0


if __name__ == "__main__":
    sys.exit(main())
