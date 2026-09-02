#!/usr/bin/env python3
"""crosscheck_framedata.py — OUR derived vanilla frame data vs the community
frame-data workbook, classified by the maintainer's rule (14z-125).

  python3 tools/crosscheck_framedata.py [--sheet ../community/vsav-framedata.xlsx]
        [--vanilla <vanilla_frames.json>] [--tsv out.tsv] [--md out.md] [--check]

THE RULE (maintainer, 2026-08-31, verbatim in substance): "measurement is king,
not a source that we don't know how it was measured; however, community
information is precious: if it aligns perfectly or with a constant offset, then
we know the measure is good; if we find an inconsistent pattern, then we must
search whether the measurement is correctly done or not."

So every (character, column) pair is classified:
  EXACT            every joined move agrees
  CONSTANT OFFSET  every delta is the same non-zero k — a COUNTING CONVENTION
                   difference; name it, do not "fix" either side
  CONSTANT RATIO   every quotient is the same r — a UNITS difference (the same
                   kind of evidence as an offset: it validates both sides)
  INCONSISTENT     neither — somebody's measurement is wrong, and OURS is the
                   one we can inspect, so ours is re-measured in-emulator first
  UNCOMPARABLE     the sheet cell is prose we do not parse, or our side is
                   structurally not the same quantity (an aerial's `recovery`
                   when our chain ends in a LOOP, not a hold — the tail is then
                   the data's, not the move's)

The join is the 18 core normal slots of anim table a2 only (tools/vanilla_frames.py
header says why, and why the command-normal slots are excluded).

NEITHER SOURCE IS IN THE TREE. The workbook is third-party work and is read
from `../community/`; we commit only this comparison and cite it.
"""
import argparse
import json
import re
import statistics
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import xlsx_read  # noqa: E402

REPO = Path(__file__).resolve().parent.parent
DEFAULT_SHEET = REPO.parent / "community" / "vsav-framedata.xlsx"

# our column -> the sheet's header(s). The workbook misspells two of them
# ('guage'), and `AN` carries a different 20-column schema, so every lookup is
# by NAME with fallbacks, never by position.
COLUMNS = [
    ("startup",   ["startup"],                    "frames before the first active frame"),
    ("active",    ["active"],                     "frames the attack box exists"),
    ("recovery",  ["recovery"],                   "frames after the last active frame"),
    ("white",     ["white damage"],               "the attack record's +9 white power"),
    ("gauge_hit", ["guage hit", "gauge hit"],     "the attack record's +0x14 attacker meter gain"),
    ("red",       ["red damage"],                 "the attack record's +8 real power PLUS its +9 white — the move's total"),
]

# `gauge hit` is not our quantity: the workbook's on-hit gauge INCLUDES the meter the
# swing itself pays (its own `gauge whiff` column), while the record's +0x14 is only
# the on-connect part. Measured over the joined corpus: sheet(hit) - sheet(whiff)
# equals our +0x14 on 255 of 287 moves, and the residue is the multi-hit rows, where
# the sheet totals every hit and we carry the records per hit. So the comparison
# SUBTRACTS the whiff column, which is a definitional correction, not a fudge.
GAUGE_WHIFF = ["gauge whiff", "guage whiff"]

# `red damage` is the record's +8 PLUS its +9 — the move's TOTAL damage, not the red
# half alone. Comparing it against +8 by itself made the column look UNCOMPARABLE and
# invited a wrong explanation: a first pass concluded "different quantity, ours is raw
# power and theirs is damage DEALT through the [VSE-40] scaler", on the evidence that
# +8 alone does not determine the sheet value (+8 = 3 appears against {5,6,7,8}). True,
# and beside the point — +9 is the rest of the sum. MEASURED (14z-125b, the hit rig):
# on a live connect the DEALT drops are neither figure (P2's +0x50 fell 9 where the
# record reads 11, its +0x52 fell 14), so the workbook is quoting ROM RECORD values
# exactly as we do, not play measurements — which is also why its `white damage`
# column matches our +9 to the byte. 266 of 281 joined moves agree on the sum; the
# residue is a HIT-COUNT question, not a damage one.
RED_IS_SUM = True
QUANTITY_DIFFERS = {}

NUM = re.compile(r"^-?\d+(\.\d+)?$")


def _plain(s):
    """Normalise a sheet cell for grammar parsing: strip spaces and the NBSP the
    workbook leaves in one cell, fold the full-width tilde, and turn the float
    spellings the workbook stores ('3.0', '12.0') back into plain integers — a
    first pass rejected every such cell as prose and compared only Sasquatch,
    the one sheet that stores its numbers as TEXT."""
    t = str(s).replace("\xa0", " ").strip().replace("\uff5e", "~").replace(" ", "")
    return re.sub(r"(\d+)\.0+(?!\d)", r"\1", t)


def num(s):
    s = str(s).strip().replace(" ", "")
    return float(s) if NUM.match(s) else None


def parse_runs(s):
    """The sheet's `active` grammar -> total active frames, or None if prose.
    Handles  3 · 2,2 · 2(4)3 · 2(4)3,2 · 3x9,2 · 3{(3)3}x6 · {2(1)}x12,2 · 3(3)3・2
    by summing every HIT chunk and ignoring the parenthesised GAPS."""
    s = _plain(s).replace("・", ",")
    if not s or not re.fullmatch(r"[0-9(){}x,\s]+", s):
        return None                      # prose: 'until landing', 'variable', 'off screen'

    def expand(t):
        """-> list of hit chunk sizes; gaps in ( ) contribute nothing."""
        out, i = [], 0
        while i < len(t):
            ch = t[i]
            if ch in " ,":
                i += 1
            elif ch == "(":                       # a gap
                j = t.index(")", i)
                i = j + 1
            elif ch == "{":                       # a braced group, repeated by a following xN
                j, depth = i + 1, 1
                while j < len(t) and depth:
                    depth += (t[j] == "{") - (t[j] == "}")
                    j += 1
                inner = expand(t[i + 1:j - 1])
                m = re.match(r"x(\d+)", t[j:])
                rep = int(m.group(1)) if m else 1
                out += inner * rep
                i = j + (m.end() if m else 0)
            else:
                m = re.match(r"(\d+)(?:x(\d+))?", t[i:])
                if not m:
                    return None
                out += [int(m.group(1))] * (int(m.group(2)) if m.group(2) else 1)
                i += m.end()
        return out

    try:
        chunks = expand(s)
    except (ValueError, IndexError):
        return None
    return sum(chunks) if chunks else None


def parse_total(s):
    """A damage/gauge cell -> total, or None if prose/unbounded.
    Handles  12 · 7+7+11 · 24,18 · 8x10 · (11,9)+(7,6) · 4xn (unbounded -> None)."""
    if re.search(r"x\s*n\b|[~\uff5e]|hit|projectile|/\d+f|every", str(s), re.I):
        return None                       # unbounded, a mash range, or prose
    s = _plain(s)
    if not s or not re.fullmatch(r"[0-9+,()x\s]+", s):
        return None
    tot, i = 0, 0
    t = s.replace(" ", "")
    while i < len(t):
        if t[i] in "+,()":
            i += 1
            continue
        m = re.match(r"(\d+)(?:x(\d+))?", t[i:])
        if not m:
            return None
        tot += int(m.group(1)) * (int(m.group(2)) if m.group(2) else 1)
        i += m.end()
    return tot


def classify(pairs):
    """pairs = [(move, sheet, ours)] -> (verdict, detail)."""
    if not pairs:
        return "NO DATA", ""
    deltas = [s - o for _, s, o in pairs]
    if all(d == 0 for d in deltas):
        return "EXACT", f"{len(pairs)}/{len(pairs)}"
    if len(set(deltas)) == 1:
        return "CONSTANT OFFSET", f"sheet = ours {deltas[0]:+g} on all {len(pairs)}"
    ratios = [s / o for _, s, o in pairs if o]
    if len(ratios) == len(pairs) and len(set(round(r, 6) for r in ratios)) == 1:
        return "CONSTANT RATIO", f"sheet = ours x{ratios[0]:g} on all {len(pairs)}"
    mode = statistics.mode(deltas)
    agree = sum(1 for d in deltas if d == mode)
    return "INCONSISTENT", f"most common delta {mode:+g} on {agree}/{len(pairs)}; spread {min(deltas):+g}..{max(deltas):+g}"


def compare(vanilla, sheet_path):
    wb = xlsx_read.Workbook(sheet_path)
    result = {"sheet": str(sheet_path), "characters": {}}
    for tab, ch in sorted(vanilla["characters"].items()):
        if tab not in wb.sheet_names:
            continue
        ours = {c["move"]: c for c in ch["chains"].values() if "move" in c and "frame_data" in c}
        rows = {}
        for r in wb.rows(tab):
            inp = str(r.get("input", "")).strip().upper().replace(" ", "")
            if inp in ours and inp not in rows:      # first row wins; duplicates are reported
                rows[inp] = r
        per_col, moves = {}, {}
        for key, headers, _ in COLUMNS:
            pairs, uncomparable = [], []
            for mv, r in sorted(rows.items()):
                o = ours[mv]
                cell = next((r[h] for h in headers if r.get(h) not in (None, "")), "")
                fd = o["frame_data"]
                if key == "startup":
                    ov, sv = fd["startup"], num(cell)
                elif key == "active":
                    ov, sv = fd["active"], parse_runs(cell)
                elif key == "recovery":
                    ov, sv = fd["recovery"], num(cell)
                    if o["end"] != "hold":
                        uncomparable.append((mv, str(cell), ov, "our chain LOOPS — the tail is the data's, not the move's"))
                        continue
                    if mv.startswith("J."):
                        # An AERIAL's recovery is bounded by the LANDING, a physics event, not by
                        # the chain's remaining node durations — which is why the workbook writes
                        # those cells as 'until landing' / 'landing 1' where it does not give a
                        # number. Measured: 42 of the 55 recovery outliers were jumping normals and
                        # every one had ours LARGER, by 5..13 frames. Not our quantity; not compared.
                        uncomparable.append((mv, str(cell), ov, "AERIAL: recovery ends at the landing, a physics event, not at the chain's last node"))
                        continue
                else:
                    d = o.get("damage_per_hit") or {}
                    if key == "red" and RED_IS_SUM:      # the sheet's red = +8 plus +9
                        if d.get("red"):
                            ov = sum(d["red"]) + sum(d.get("white") or [])
                        else:
                            dm = o.get("damage") or {}
                            ov = None if dm.get("red") is None else dm["red"] + dm["white"]
                    else:
                        ov = sum(d[key]) if d.get(key) else (o.get("damage") or {}).get(key)
                    sv = parse_total(cell)
                    if key == "gauge_hit" and sv is not None:
                        whiff = next((parse_total(r[h]) for h in GAUGE_WHIFF if r.get(h) not in (None, "")), 0)
                        sv = None if whiff is None else sv - whiff   # see GAUGE_WHIFF
                if ov is None or sv is None:
                    uncomparable.append((mv, str(cell), ov, "sheet cell not a parsed number" if sv is None else "no value on our side"))
                    continue
                pairs.append((mv, sv, ov))
                moves.setdefault(mv, {})[key] = (sv, ov)
            verdict, detail = classify(pairs)
            if key in QUANTITY_DIFFERS:
                verdict, detail = "UNCOMPARABLE", QUANTITY_DIFFERS[key]
            per_col[key] = {"verdict": verdict, "detail": detail, "n": len(pairs),
                            "uncomparable": uncomparable,
                            "rows": [{"move": m, "sheet": s, "ours": o, "delta": s - o} for m, s, o in pairs]}
        result["characters"][tab] = {"name": ch["name"], "id": ch["char_id"],
                                     "joined": len(rows), "columns": per_col}
    return result


def render_md(vanilla, cmp_, full=False):
    """full=False (the in-tree page): verdicts, mechanisms, counts and "What is NOT
    known" ONLY — no per-move number of ours or the workbook's. full=True: the whole
    comparison, written OUT of the tree (../charpages/framedata/) by
    tools/framedata_pages.sh. THE RULE (maintainer, 2026-08-31, STATE 14z-126): per-move
    ROM-derived frame data — ours and third-party alike — is generator output kept out
    of the public repository; the tree ships the readers and the verdicts."""
    L = []
    A = L.append
    A("# Community cross-check — our derived frame data vs the community sources")
    A("")
    A("**GENERATED** by `tools/crosscheck_framedata.py` from `tools/vanilla_frames.py`'s")
    A("derivation and the maintainer's workbook. Do not hand-edit; regenerate.")
    A("Gate: `tests/test_community_crosscheck.sh`.")
    if not full:
        A("")
        A("**THIS IS THE VERDICT-ONLY PAGE.** Per-move frame data — ours and the workbook's")
        A("alike — stays out of the public tree (maintainer-ruled 2026-08-31, STATE 14z-126:")
        A("the tree ships the READERS and the VERDICTS; the numbers are regenerated from the")
        A("romsets). The full comparison, move by move, is `../charpages/framedata/")
        A("community_crosscheck_full.md`, written above the working tree by")
        A("`tools/framedata_pages.sh` for anyone holding the reference dumps and the workbook.")
    A("")
    A("## The rule this page applies")
    A("")
    A("Maintainer, 2026-08-31, verbatim in substance: *\"measurement is king, not a")
    A("source that we don't know how it was measured; however, community information")
    A("is precious: if it aligns perfectly or with a constant offset, then we know the")
    A("measure is good; if we find an inconsistent pattern, then we must search whether")
    A("the measurement is correctly done or not.\"*")
    A("")
    A("| verdict | meaning | what it obliges |")
    A("|---|---|---|")
    A("| EXACT | every joined move agrees | nothing; both measurements are corroborated |")
    A("| CONSTANT OFFSET | every delta is the same non-zero k | a COUNTING CONVENTION difference — name it, change neither side |")
    A("| CONSTANT RATIO | every quotient is the same r | a UNITS difference — same evidential value as an offset |")
    A("| INCONSISTENT | neither | somebody's measurement is wrong; **re-measure OURS in-emulator first** |")
    A("| UNCOMPARABLE | the sheet cell is prose, or the quantities differ structurally | state why, compare nothing |")
    A("")
    A("## The sources (both OUTSIDE the tree, cited not committed)")
    A("")
    A("- `../community/vsav-framedata.xlsx` — 15 sheets, one per vanilla character,")
    A("  730 data rows. Read by `tools/xlsx_read.py` (stdlib only; validated cell for")
    A("  cell against `openpyxl` — 28,234 cells, the only 4 differences being the")
    A("  date-corrupted `VI!U43:U46` `Invuln` cells, a column this page does not compare).")
    A("- `../community/mizuumi_reverse_engineering.txt` — the mizuumi wiki's Reverse")
    A("  Engineering page (`oldid 416342`, 2025-07-31). It carries **no per-move frame")
    A("  data** — it is a RAM/ROM map — so it is not a source for this page. Its")
    A("  player-struct table is a separate, queued comparison against `atlas/ram.md`.")
    A("")
    A("## What is compared, and what is not")
    A("")
    A("| sheet column | ours | source of ours |")
    A("|---|---|---|")
    for key, headers, why in COLUMNS:
        A(f"| `{headers[0]}` | `{key}` | {why} |")
    A("")
    A("Not compared, because nothing in the tree derives them yet: `on hit`,")
    A("`renda on hit`, `on block`, `renda on block`, `throw tech`, `cancel`, `guard`,")
    A("`hit reaction`, `Invuln`, `type`, `gauge whiff`, `guage block`. Frame advantage")
    A("needs the victim's stun length beside the attacker's recovery; `tests/test_reactions.sh`")
    A("measures the raw material for the tenants only.")
    A("")
    A("## The join is MEASURED, not assumed — and the first model was wrong")
    A("")
    A("Which anim chain a standing normal enters is **per character and per button**,")
    A("because the engine picks by PROXIMITY. It was measured on vanilla vsavj by")
    A("`tools/vanilla_join_rig.py`: each button performed at a far pin and again after a")
    A("150-frame walk-in, the verdict read off the game's own node pointer `+0x1C` and")
    A("mapped onto the chain graph. All 15 characters, 180 rows, frozen in")
    A("`tests/expected/vanilla_normal_slots.tsv`, gated by `tests/test_vanilla_frame_join.sh`.")
    A("")
    A("**A fixed layout was tried first and the measurement overturned it.** The model")
    A("was \"even slot = close normal, odd slot = far normal\" for everyone, inferred by")
    A("fitting our numbers against this very workbook — which is circular, and wrong:")
    A("")
    A("- **AN, BI, JE, QB, ZA** enter the same chain at both distances on every button:")
    A("  no proximity variants at all. Zabel is why it mattered — the fixed model handed")
    A("  him the odd slots, which are his `6`-prefixed COMMAND normals, and he came out")
    A("  INCONSISTENT on all five columns. On the measured join he is clean on all five.")
    A("- **DE, MO, FE, SA, LE, LI** take odd at far / even at near for MP..HK, but LP is")
    A("  `0x01` at both distances; **GA, VI** the same with LP at `0x00`; **BU** and **AU**")
    A("  additionally have no close variant for HP (BU none for MK).")
    A("")
    A("The **crouching** (`0x0c-0x11`) and **jumping** (`0x12-0x17`) slots are the layout")
    A("measured on the three TENANTS by `tools/name_moves.py` (gate `tests/test_move_naming.sh`),")
    A("carried over and **not** re-measured per vanilla character — a stated bound, not a claim.")
    A("Specials, supers and the `6`-prefixed command normals are not joined at all.")
    A("")
    A("## The headline: per-move agreement")
    A("")
    A("A column is called INCONSISTENT if even ONE joined move deviates, which is a")
    A("deliberately strict test. The rate that says whether our derivation is sound is")
    A("per MOVE, over all 15 characters:")
    A("")
    A("| column | convention | moves agreeing |")
    A("|---|---|---|")
    conv = {"startup": (1, "the sheet counts the first active frame as startup; ours counts the frames before it"),
            "active": (0, "identical"),
            "recovery": (2, "a 2-frame tail the sheet counts and our last node does not"),
            "white": (0, "identical — the record's +9 is the dealt white damage, unscaled"),
            "gauge_hit": (0, "identical once the sheet's own `gauge whiff` is subtracted")}
    for key, _, _ in COLUMNS:
        if key not in conv:
            continue
        k, why = conv[key]
        ok = bad = 0
        for c in cmp_["characters"].values():
            for r in c["columns"][key]["rows"]:
                ok += r["delta"] == k
                bad += r["delta"] != k
        if ok + bad:
            A(f"| `{key}` | sheet = ours {k:+d} — {why} | **{ok}/{ok + bad}** ({100 * ok // (ok + bad)}%) |")
    A("")
    A("So the two measurements corroborate each other on ~96% of every column we can")
    A("compare, under one stated convention per column. The residue is the worklist below.")
    A("")
    A("## Verdicts, per character and column")
    A("")
    A("| character | joined | " + " | ".join(k for k, _, _ in COLUMNS) + " |")
    A("|---|---|" + "---|" * len(COLUMNS))
    for tab, c in sorted(cmp_["characters"].items()):
        cells = []
        for key, _, _ in COLUMNS:
            v = c["columns"][key]
            cells.append(f"{v['verdict']}" + (f" ({v['detail']})" if v["verdict"] in ("CONSTANT OFFSET", "CONSTANT RATIO") else "") + f" · n={v['n']}")
        A(f"| **{tab}** {c['name']} `{c['id']}` | {c['joined']} | " + " | ".join(cells) + " |")
    A("")
    A("## The arbitration — what the emulator said about the residue")
    A("")
    A("The rule obliges us to re-measure OURS before concluding anything about the")
    A("workbook. Three rigs were run on vanilla vsavj (`tools/vanilla_join_rig.py`,")
    A("gate `tests/test_vanilla_frame_join.sh`), and they split the residue into three")
    A("families, two of which are now settled.")
    A("")
    A("### 1. The duration bytes are the engine's — CONFIRMED, and the instrument's limit is measured")
    A("")
    A("Tracing the engine's own node countdown `+0x20` beside the node pointer: the")
    A("first value observed on a node equals the duration byte we read on **334 of 380**")
    A("nodes. So the derivation's INPUT is what the engine loads, measured directly.")
    A("")
    A("But the same trace shows **16% of sampled frames advance that counter by two**")
    A("ticks, not one — `field_trace` samples at `frame_done`, and the engine does not")
    A("run one tick per video frame. **A frame-rate trace therefore cannot arbitrate a")
    A("ONE-frame convention difference**: its resolution is the size of the thing being")
    A("measured. That is why the `startup +1` and `recovery +2` offsets stay *named")
    A("conventions* rather than being declared right or wrong here; settling them needs")
    A("a tick-accurate instrument (a `-debug` trace or a Lua hook on the tick), which")
    A("this session did not build.")
    A("")
    A("### 2. The damage residue is the WORKBOOK double-counting — SETTLED")
    A("")
    A("Every move whose `white` and `red` read about HALF the workbook's has the same")
    A("shape: the chain carries **two or more attack records that share hit id 1**, the")
    A("engine's own multi-hit dedup key (record `+0x10`). Records sharing a hit id are")
    A("alternative boxes for ONE hit — the victim's recent-hit ring refuses the second")
    A("([VSE-43]) — so only one of them can land. We take one; **the workbook sums them**:")
    A("")
    if not full:
        A("Five moves carry it (MO 5HK, QB 2HK, SA 5HP, VI 2HP, JE 5HK — two or more attack")
        A("records sharing hit id 1; the per-record values are on the full page).")
    full and A("| move | records (id, red/white) | workbook white | ours |")
    full and A("|---|---|---|---|")
    full and A("| MO 5HK | 17 (id 1, 14/7), 99 (id 1, 12/7) | 14 = 7+7 | 7 |")
    full and A("| QB 2HK | 13 (id 1, 11/9), 14 (id 1, 9/7) | 16 = 9+7 | 9 |")
    full and A("| SA 5HP | 7 (id 1, 15/9), 8 (id 1, 12/8) | 17 = 9+8 | 9 |")
    full and A("| VI 2HP | 15 (id 1, 15/8), 16 (id 1, 14/8) | 16 = 8+8 | 8 |")
    full and A("| JE 5HK | 8, 9, 56 — all id 1 | 13 = 7+6 | 7 |")
    A("")
    A("**The hit rig confirms our reading and not theirs.** P1 performs each normal on a")
    A("victim whose HP is re-pinned before every event, and each DROP in P2's `+0x50` is")
    A("counted: our dedup-aware run count matches the engine's hit count on **75 of 78**")
    A("connecting events (the measurement is hashed in `tests/expected/vanilla_hit_damage.sha256`; the values live out of tree, `../charpages/framedata/vanilla_hit_damage.tsv`). Summing every record,")
    A("as the workbook does, would not. So on this family ours is right and the")
    A("workbook is wrong, and the mechanism says why.")
    A("")
    A("The same rig also showed the workbook is a **ROM-derived** source, not a")
    A("play-measured one: on a live connect the DEALT drops are neither figure")
    if full:
        A("(P2's `+0x50` fell 9 where the record reads 11, its `+0x52` fell 14), yet the workbook")
    else:
        A("(the worked example is on the full page), yet the workbook")
    A("quotes the record values to the byte. That is why its `white damage` matches our")
    A("`+9` exactly, and it is the best evidence available about a method the page")
    A("itself never states.")
    A("")
    A("### 3. Jedah's crouching recovery — CLOSED 2026-09-02: THE RESIDUE IS THE WORKBOOK'S")
    A("")
    A("All six of Jedah's crouching normals (and Lilith's `2MK`) read `+3` where every")
    A("other character reads `+2`. ~~by finding 1 the available instrument cannot resolve")
    A("a one-frame question. Left open rather than guessed.~~ **ARBITRATED IN THE EMULATOR,")
    A("IN ENGINE TICKS.** The instrument that entry said did not exist does: a write tap")
    A("fires per WRITE, and `PRG:0x027F70` (`subq.b #$1,$20(a6)`) IS one engine tick, so")
    A("the multi-tick frames that defeat a frame-rate trace are fully visible.")
    A("")
    A("**MEASURED: 18 of 18 derived totals equal the engine's tick count EXACTLY** (JE, LI,")
    A("DE crouching normals, no tolerance — `tools/tick_durations.py`,")
    A("`tests/test_tick_durations.sh`). Jedah's six: 13/29/66/13/29/57 derived, and the")
    A("same six measured.")
    A("")
    A("**THE ARBITRATION.** Our `startup` and `active` are not flagged for these characters")
    A("— they agree with the workbook under its own stated conventions — and the TOTAL is")
    A("now ground truth. Since total = startup + active + recovery, our recovery is right,")
    A("and the workbook's for those seven moves sits one frame below its own convention.")
    A("Measurement is king: a source whose method we cannot see loses to a tick count")
    A("taken from the engine itself.")
    A("")
    A("## Every INCONSISTENT column" + (", move by move" if full else " — per character (the moves are on the full page)"))
    A("")
    any_bad = False
    for tab, c in sorted(cmp_["characters"].items()):
        for key, _, _ in COLUMNS:
            v = c["columns"][key]
            if v["verdict"] != "INCONSISTENT":
                continue
            any_bad = True
            A(f"### {tab} {c['name']} — `{key}` — {v['detail']}")
            A("")
            if not full:
                A(f"{len(v['rows'])} move(s) deviate; the per-move table is on the full page.")
                A("")
                continue
            A("| move | sheet | ours | delta |")
            A("|---|---|---|---|")
            for r in v["rows"]:
                A(f"| {r['move']} | {r['sheet']:g} | {r['ours']:g} | {r['delta']:+g} |")
            A("")
    if not any_bad:
        A("None.")
        A("")
    A("## What is NOT known")
    A("")
    A("- **The startup `+1` and recovery `+2` offsets are NAMED, not adjudicated.** The")
    A("  instrument available samples at video-frame rate and 16% of its frames carry two")
    A("  engine ticks, so it cannot resolve a one-frame question. A tick-accurate")
    A("  instrument would settle whether either side is counting wrongly; neither is")
    A("  assumed to be.")
    A("- ~~**Jedah's crouching recovery (+3, not +2) is unexplained**~~ **CLOSED 2026-09-02:")
    A("  measured in engine ticks, 18/18 exact — the residue is the WORKBOOK'S, not ours**")
    A("  — see the arbitration section. Lilith's `2MK` behaves the same way.")
    A("- **The aerial outliers — PART-RESOLVED 2026-09-02, and the likely cause is NAMED**")
    A("  (BI `J.HP`/`J.LP`, BU `J.MP`, VI `J.HP`, FE `J.HK`/`J.LK`, SA `J.MP`).")
    A("  `tools/tick_durations.py` separates the move from the jump for chains that LOOP:")
    A("  an aerial repeats until landing, back to its start (BI `J.LP`) or to a late node")
    A("  (BI `J.MP`). **BI measures 5/6 exact** and the miss is a flagged move — `J.HP`")
    A("  derives 28 where the engine spends 27; BU `J.LK`/`J.LP` are exact. STILL NOT")
    A("  SEPARABLE: aerials whose last node HOLDS with no further pointer write before")
    A("  landing (VI, FE, SA) still report AIRTIME — identical numbers across a")
    A("  character's moves are the tell, not a result. **LIKELY CAUSE, from the community")
    A("  corpus and NOT yet measured:** mizuumi distinguishes NEUTRAL- from FORWARD-jump")
    A("  variants of the same button (`8J.LP` vs `9J.LP`) where our slot map carries ONE")
    A("  chain per aerial button. Needs a two-direction jump rig.")
    A("- **Specials, supers, EX/ES moves, throws, pursuits and the `6`-prefixed command")
    A("  normals are not joined.** Each needs its own measured naming rig on vsavj, the way")
    A("  `tools/name_moves.py` did for the tenants. That is the bulk of the workbook's 730")
    A("  rows and it is untouched here.")
    A("- **Seven workbook columns have no counterpart in the tree**: `on hit`, `on block`,")
    A("  `renda on hit`, `renda on block`, `throw tech`, `cancel`, `Invuln`. Frame advantage")
    A("  needs the victim's stun beside the attacker's recovery; nothing computes it.")
    A("- **The crouching and jumping slot layout was not re-measured on vanilla characters**")
    A("  — it is the tenants' measured layout, carried.")
    A("- **Slot `a2:0x00` on the characters that do not use it for LP** has no established")
    A("  role; the rig never entered it there.")
    A("- **AN OPEN QUESTION THIS RAISES ABOUT THE TENANTS.** `build/manifest/moves_huitzil.toml`")
    A("  labels `a2:0x01/03/05` as `6LP` / `6MP` / `6HP`, filled by `tools/name_moves.py`")
    A("  performing `6`+button at a FAR pin. On vanilla characters those odd slots are the")
    A("  FAR standing normal, and the maintainer's own note on those rows reads *\"Alternate")
    A("  attack: different from 5LP (usually longer reach and different data)\"* — which")
    A("  describes a far normal exactly. So the tenants' `6XX` labels may be a naming")
    A("  artifact of the rig's input choice rather than distinct command normals.")
    A("  **Not measured, not corrected here**: settling it means running the two-distance")
    A("  rig on native vs2 for the three tenants. Nothing in the shipped build depends on")
    A("  the label — it is documentation.")
    A("- **The workbook's own defects are not corrected**, only avoided: `AN` row 48 is")
    A("  shifted one column from `gauge whiff` on, `AN` rows 49-50 carry no frame data,")
    A("  `AN!K50` reads `[1+0x8+1x5+7`, and `VI!U43:U46` were eaten by Excel into dates.")
    A("  Duplicate move names exist in `FE`, `BU` and `JE`; the join takes the first row.")
    A("")
    return "\n".join(L) + "\n"


def render_tsv(cmp_):
    out = ["character\tcolumn\tverdict\tn\tdetail"]
    for tab, c in sorted(cmp_["characters"].items()):
        for key, _, _ in COLUMNS:
            v = c["columns"][key]
            out.append(f"{tab}\t{key}\t{v['verdict']}\t{v['n']}\t{v['detail']}")
    return "\n".join(out) + "\n"


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--sheet", type=Path, default=DEFAULT_SHEET)
    ap.add_argument("--vanilla", type=Path, help="tools/vanilla_frames.py --json output (else derived on the fly)")
    ap.add_argument("--image", type=Path)
    ap.add_argument("--tsv", type=Path)
    ap.add_argument("--md", type=Path, help="the VERDICT-ONLY page (the one committed in the tree)")
    ap.add_argument("--md-full", type=Path, help="the full move-by-move page — write it OUT of the tree (tools/framedata_pages.sh)")
    ap.add_argument("--json", type=Path)
    a = ap.parse_args()

    if not a.sheet.exists():
        sys.exit(f"SKIP-SOURCE: {a.sheet} is absent (the community workbook is third-party and lives outside the tree)")

    if a.vanilla:
        vanilla = json.loads(a.vanilla.read_text())
    else:
        import vanilla_frames
        img_path = a.image or vanilla_frames.DEFAULT_IMAGE
        img = Path(img_path).read_bytes()
        rows = vanilla_frames.bank_rows(REPO / "build/manifest/bank_map.toml")
        vanilla = {"characters": {}}
        for tab, (cid, name) in vanilla_frames.CHARS.items():
            d = vanilla_frames.derive_char(img, rows, cid)
            d["name"], d["tab"] = name, tab
            vanilla["characters"][tab] = d

    cmp_ = compare(vanilla, a.sheet)
    if a.tsv:
        a.tsv.write_text(render_tsv(cmp_))
        print(f"wrote {a.tsv}")
    if a.md:
        a.md.write_text(render_md(vanilla, cmp_))
    if a.md_full:
        a.md_full.write_text(render_md(vanilla, cmp_, full=True))
        print(f"wrote {a.md}")
    if a.json:
        a.json.write_text(json.dumps(cmp_, indent=1, sort_keys=True) + "\n")
        print(f"wrote {a.json}")
    if not (a.tsv or a.md or a.json):
        sys.stdout.write(render_tsv(cmp_))


if __name__ == "__main__":
    main()
