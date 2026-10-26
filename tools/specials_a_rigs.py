#!/usr/bin/env python3
"""specials_a_rigs.py — THE VANILLA SPECIALS NAMING RIG, F1's half (GitHub #229, 14z-205, fork F1: FE AN AU BI BU DE GA JE): which anim chain
each motion special, special projectile and movement special of the community workbook ENTERS on pristine
vsavj, what it spawns, and how its derived frame data compares with the workbook row.

  python3 tools/specials_a_rigs.py gen      <tab> <out.rpl> <out.json> [x1 x2]   (default the far pin; WIDE = 488 820)
  python3 tools/specials_a_rigs.py analyse  <tab> <trace.txt> <rig.json> <image.bin> [--json out]
  python3 tools/specials_a_rigs.py join     <results.json ...> --image <image.bin> [--sheet <xlsx>] [--json out]
  python3 tools/specials_a_rigs.py snaps    <rig.json> <analysis.json>     SNAP_FRAMES: each fired event's capture frame
  python3 tools/specials_a_rigs.py table    <analysis.json ...>            the identity rows a gate freezes
  python3 tools/specials_a_rigs.py values-hash <join.json>                 sha256 of the joined per-move values
  python3 tools/specials_a_rigs.py tick-agreement <join.json>              live ticks vs the duration-byte derivation
  python3 tools/specials_a_rigs.py sheet    <out.png> <tab:snapdir:analysis.json> ...

METHOD (the cross-check page's and #229's). A scripted input is not the move it names ([VSE-47]): the rig never
trusts its own script. It samples P1's anim node pointer +0x1C every frame (tests/lua/field_trace.lua) and maps
it onto the decoded chain graph (tools/anim_nodes.py, through tools/vanilla_join_rig.node_map, tables a2 then
a); the FIRST new chain after the button is the candidate, every chain after it is listed, and a window with
no new chain is UNFIRED, never guessed. The projectile pool (RAM:$FF9400 + n*0x100, 32 slots: +0x00 alive,
+0x02 type — docs/game/atlas/ram.md) is traced too, so a projectile row is named by the object it spawns as
well as by the fighter's chain. The motion cadences are tools/name_moves.py's (the ones that already fired
natively); the rig layout is tools/vanilla_join_rig.py's: P1 forced by the early-window poke of $FF8782, P2 =
Victor idle (his HP re-pinned every name_moves.HP_PIN_EVERY frames, never inside an event), both fighters
pinned to the far pair 40 frames before each event so P1 faces right and a motion is never mirrored, the first
event after the round intro (name_moves.FIRST_EVENT), one part under one round.

WHAT IS COMPARED. `join` reads the workbook rows each event documents (by sheet ROW INDEX, never by a fit
against the sheet), takes OUR frame data from tools/vanilla_frames.derive_char for the chain the event
entered (startup/active/recovery from the node duration bytes of the node WALK the event made — every node occurrence from its first new chain to the first baseline chain, the page's quantities in engine ticks; the
first attack record's power classes and meter), and classifies each column with the page's own classifier
(tools/crosscheck_framedata.classify) and its own cell grammar (parse_runs / parse_total / num). A chain with
no attack node (a projectile thrown by the fighter, a movement special) has no fighter-side active frames:
those cells are UNCOMPARABLE with that reason, never filled from the object. Nothing here is a final verdict
before the maintainer has confirmed identity on the capture sheet (#229's method).
"""
import argparse
import json
import re
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import name_moves as nm          # noqa: E402
import vanilla_join_rig as vjr   # noqa: E402
import vanilla_frames            # noqa: E402

B = nm.B
TAB_ID = {"BU": 0x00, "DE": 0x01, "GA": 0x02, "VI": 0x03, "ZA": 0x04, "MO": 0x05, "AN": 0x06, "FE": 0x07,
          "BI": 0x08, "AU": 0x09, "SA": 0x0A, "QB": 0x0C, "LE": 0x0D, "LI": 0x0E, "JE": 0x0F}
POOL = [0xFF9400 + n * 0x100 for n in range(32)]
FIELDS = ",".join(["ff841c:l:node", "ff8414:w:p1y", "ff840b:b:p1face", "ff8850:w:p2hp", "ff8420:b:cnt", "ff8109:b:tmr"]
                  + [f"{a:06x}:l:o{n}" for n, a in enumerate(POOL)])


# ---------------------------------------------------------------- recipes
# (a, b, tok[, who]) — frames relative to the event; P1 faces RIGHT (R = toward, L = back).
def qcf(b):   return nm.qcf(b)
def dp(b):    return nm.dp(b)
def qcb(b):   return nm.qcb(b)
def chg_bf(b): return nm.charge_bf(b)          # [4] 60 f, then 6+button
def chg_du(b): return nm.charge_du(b)          # [2] 60 f, then 8+button
def stand(b): return nm.stand(b)
def crouch(b): return nm.crouch(b)
def jump(b):  return nm.jump(b)
def dfwd(b):  return [(0, 3, "DR" + B[b])]
def air_qcf(b): return nm.air_qcf(b)
def air_qcb(b): return nm.air_qcb(b)
def dd(b):    return [(0, 2, "D"), (5, 7, "D"), (6, 8, B[b])]                       # 22+button (a release between)
def bf(b):    return [(0, 3, "L"), (5, 8, "R"), (6, 8, B[b])]                       # 46+button (no charge)
def dash_dp(b): return nm.dash_f() + [(a + 12, bb + 12, t) for a, bb, t in nm.dp(b)]  # 66, then 623+button
def qcf_then(b, p, at):                                                            # 236+b, then p at +at
    return nm.qcf(b) + [(at, at + 2, B[p])]
def start_fwd(b=None): return [(0, 6, "R"), (1, 3, "S1", "sys")]                    # 6+Start (Felicia's Cat Hug)
def k412_6(b):  # 4,1,2, then [6] held with the button (Bishamon's 412[6]P)
    return [(0, 2, "L"), (3, 5, "DL"), (6, 8, "D"), (9, 40, "R"), (10, 12, B[b])]
def air_412_6(b):
    return [(0, 2, "U")] + [(a + 12, bb + 12, t) for a, bb, t in k412_6(b)]
def air_632_4(b, p):  # J.632[4]K~P (Jedah's Ira Piano): jump, 6 3 2 then [4] held with K, then P
    return [(0, 2, "U"), (12, 13, "R"), (14, 15, "DR"), (16, 17, "D"), (18, 44, "L"), (19, 21, B[b]), (36, 38, B[p])]


# ---------------------------------------------------------------- the schedule
# (key, workbook row indices, recipe, gap). Each key names what the rig PRESSES, never what it got.
# A workbook row that names one input for every strength ("236P") is run with ALL THREE strengths, so the
# sheet's one-row claim is measured (the ground-throw rigs' rule); the rows are joined to each.
G, A = 300, 360   # gap after a ground / an aerial event
EVENTS = {
    "FE": [("236LP", [28], lambda: qcf("LP"), G), ("236LP~LP", [29], lambda: qcf_then("LP", "LP", 20), G),
           ("236MP", [30], lambda: qcf("MP"), G), ("236MP~MP", [31], lambda: qcf_then("MP", "MP", 20), G),
           ("236HP", [32], lambda: qcf("HP"), G), ("236HP~HP", [33], lambda: qcf_then("HP", "HP", 20), G),
           ("623LP", [36], lambda: dp("LP"), G), ("623MP", [37], lambda: dp("MP"), G), ("623HP", [38], lambda: dp("HP"), G),
           ("623LK", [40], lambda: dp("LK"), G), ("623MK", [41], lambda: dp("MK"), G), ("623HK", [42], lambda: dp("HK"), G),
           ("22LP", [48], lambda: dd("LP"), G), ("22MP", [48], lambda: dd("MP"), G), ("22HP", [48], lambda: dd("HP"), G),
           ("6+Start", [27], start_fwd, G)],
    "AN": [("22LP", [26], lambda: dd("LP"), G), ("22LK", [26], lambda: dd("LK"), G),
           ("j.236LP", [28], lambda: air_qcf("LP"), A), ("j.236MP", [29], lambda: air_qcf("MP"), A),
           ("j.236HP", [30], lambda: air_qcf("HP"), A),
           ("214LK", [32], lambda: qcb("LK"), G), ("j.214LK", [32], lambda: air_qcb("LK"), A),
           ("236LK", [33], lambda: qcf("LK"), G),
           ("46LP", [34], lambda: bf("LP"), G), ("46MP", [35], lambda: bf("MP"), G), ("46HP", [36], lambda: bf("HP"), G)],
    "AU": [("[4]6LP", [26], lambda: chg_bf("LP"), G), ("[4]6MP", [27], lambda: chg_bf("MP"), G),
           ("[4]6HP", [28], lambda: chg_bf("HP"), G),
           ("[4]6LK", [30], lambda: chg_bf("LK"), G), ("[4]6MK", [31], lambda: chg_bf("MK"), G),
           ("[4]6HK", [32], lambda: chg_bf("HK"), G),
           ("623LK", [34], lambda: dp("LK"), G), ("623MK", [35], lambda: dp("MK"), G), ("623HK", [36], lambda: dp("HK"), G)],
    "BI": [("412[6]LP", [], lambda: k412_6("LP"), G), ("412[6]MP", [], lambda: k412_6("MP"), G),
           ("412[6]HP", [], lambda: k412_6("HP"), G),
           ("j.412[6]LP", [], lambda: air_412_6("LP"), A), ("j.412[6]MP", [], lambda: air_412_6("MP"), A),
           ("j.412[6]HP", [], lambda: air_412_6("HP"), A),
           # NOT row 38 (CORRECTED 14z-205c, #229): from neutral these are a 6+P (a2:0x1e-0x20) — the maintainer: "even if
           # the input was 236+P, it only results in 6+P"; Tsuji Hayate needs a connecting Karame Dama (the "BI^" part)
           ("236LP", [], lambda: qcf("LP"), G), ("236MP", [], lambda: qcf("MP"), G), ("236HP", [], lambda: qcf("HP"), G),
           ("623LP", [40], lambda: dp("LP"), G), ("623MP", [41], lambda: dp("MP"), G), ("623HP", [42], lambda: dp("HP"), G),
           ("[4]6LP", [48], lambda: chg_bf("LP"), G), ("[4]6MP", [49], lambda: chg_bf("MP"), G),
           ("[4]6HP", [50], lambda: chg_bf("HP"), G),
           ("[4]6LK", [52], lambda: chg_bf("LK"), G), ("[4]6MK", [53], lambda: chg_bf("MK"), G),
           ("[4]6HK", [54], lambda: chg_bf("HK"), G)],
    "BU": [("5HK", [5], lambda: stand("HK"), G), ("2HK", [15], lambda: crouch("HK"), G),
           ("j.HK", [21], lambda: jump("HK"), A), ("3HK", [27], lambda: dfwd("HK"), G),
           ("[4]6LP", [30], lambda: chg_bf("LP"), G), ("[4]6MP", [30], lambda: chg_bf("MP"), G),
           ("[4]6HP", [30], lambda: chg_bf("HP"), G),
           ("[4]6LK", [32], lambda: chg_bf("LK"), G), ("[4]6MK", [32], lambda: chg_bf("MK"), G),
           ("[4]6HK", [32], lambda: chg_bf("HK"), G),
           ("[2]8LP", [34], lambda: chg_du("LP"), G), ("[2]8MP", [34], lambda: chg_du("MP"), G),
           ("[2]8HP", [34], lambda: chg_du("HP"), G),
           ("623LP", [36], lambda: dp("LP"), G), ("623MP", [37], lambda: dp("MP"), G), ("623HP", [38], lambda: dp("HP"), G),
           ("214LP", [40], lambda: qcb("LP"), G), ("214MP", [41], lambda: qcb("MP"), G), ("214HP", [42], lambda: qcb("HP"), G)],
    "DE": [("236LP", [21], lambda: qcf("LP"), G), ("236MP", [21], lambda: qcf("MP"), G), ("236HP", [21], lambda: qcf("HP"), G),
           ("623LP", [23], lambda: dp("LP"), G), ("623MP", [24], lambda: dp("MP"), G), ("623HP", [25], lambda: dp("HP"), G),
           ("66,623LP", [], lambda: dash_dp("LP"), G), ("66,623MP", [], lambda: dash_dp("MP"), G),
           ("66,623HP", [], lambda: dash_dp("HP"), G),
           ("214LK", [35], lambda: qcb("LK"), G), ("214MK", [35], lambda: qcb("MK"), G), ("214HK", [35], lambda: qcb("HK"), G)],
    "GA": [("236LP", [24], lambda: qcf("LP"), G), ("236MP", [24], lambda: qcf("MP"), G), ("236HP", [24], lambda: qcf("HP"), G),
           ("623LP", [26], lambda: dp("LP"), G), ("623MP", [26], lambda: dp("MP"), G), ("623HP", [26], lambda: dp("HP"), G),
           ("j.236LP", [30], lambda: air_qcf("LP"), A), ("j.236MP", [30], lambda: air_qcf("MP"), A),
           ("j.236HP", [30], lambda: air_qcf("HP"), A),
           ("[2]8LK", [32], lambda: chg_du("LK"), G), ("[2]8MK", [33], lambda: chg_du("MK"), G),
           ("[2]8HK", [34], lambda: chg_du("HK"), G),
           ("214LP", [36], lambda: qcb("LP"), G), ("214MP", [37], lambda: qcb("MP"), G), ("214HP", [38], lambda: qcb("HP"), G)],
    "JE": [("236LP", [19], lambda: qcf("LP"), G), ("236MP", [19], lambda: qcf("MP"), G), ("236HP", [19], lambda: qcf("HP"), G),
           ("j.632[4]LK~LP", [25], lambda: air_632_4("LK", "LP"), A),
           ("j.632[4]MK~MP", [25], lambda: air_632_4("MK", "MP"), A),
           ("j.632[4]HK~HP", [25], lambda: air_632_4("HK", "HP"), A)],
}
def k4123(b):  # 4,1,2,3+button (Bishamon's Karame Dama, mizuumi "4123P" = the sheet's 412[6]P rows)
    return [(0, 2, "L"), (3, 5, "DL"), (6, 8, "D"), (9, 12, "DR"), (10, 12, B[b])]
def air_4123(b):
    return [(0, 2, "U")] + [(a + 12, bb + 12, t) for a, bb, t in k4123(b)]
def dp_slow(b):   # 623 with longer holds
    return [(0, 3, "R"), (5, 8, "D"), (10, 14, "DR"), (11, 14, B[b])]
def dp_tight(b):  # 623 with no gap between the directions
    return [(0, 2, "R"), (3, 5, "D"), (6, 9, "DR"), (6, 9, B[b])]
def dp_zig(b):    # 6 3 2 3+button (the dragon-punch shortcut)
    return [(0, 2, "R"), (3, 5, "DR"), (6, 8, "D"), (9, 12, "DR"), (10, 12, B[b])]
def dp_late(b):   # 623, the button two frames after DR arrives
    return [(0, 2, "R"), (4, 6, "D"), (8, 14, "DR"), (12, 14, B[b])]
def dash_dp_at(b, at):  # 66, then 623+button starting `at` frames after the second tap
    return nm.dash_f() + [(a + at, bb + at, t) for a, bb, t in nm.dp(b)]


# SECOND PARTS (a tab with a "+": the same character, events measured after the first pass named a recipe
# that did not fire the move it was written for; the first pass's events are kept as measured facts, with NO
# rows: BI's 412[6]P entered a2:0x1e-0x20 with no spawn, the chains 236P enters, while 4123P (mizuumi's input
# for Karame Dama) enters a2:0x45 and spawns a type-0x1C projectile at +8 on both legs; DE's 66,623P at +12
# entered a2:0x31 (LP, HP) or a2:0x2c (MP), and the +6..+22 sweep below enters a2:0x2b/0x2c/0x2d by strength,
# then a2:0x2f, at every offset but +9 (a2:0x31) — the +22 events, which whiff on both legs, carry the rows).
EVENTS["BI+"] = [("4123LP", [30], lambda: k4123("LP"), G), ("4123MP", [31], lambda: k4123("MP"), G),
                 ("4123HP", [32], lambda: k4123("HP"), G),
                 ("j.4123LP", [34], lambda: air_4123("LP"), A), ("j.4123MP", [35], lambda: air_4123("MP"), A),
                 ("j.4123HP", [36], lambda: air_4123("HP"), A),
                 ("623LP slow", [40], lambda: dp_slow("LP"), G), ("623MP slow", [41], lambda: dp_slow("MP"), G),
                 ("623HP slow", [42], lambda: dp_slow("HP"), G),
                 ("623LP tight", [40], lambda: dp_tight("LP"), G), ("623MP tight", [41], lambda: dp_tight("MP"), G),
                 ("623HP tight", [42], lambda: dp_tight("HP"), G),
                 ("6323LP zig", [40], lambda: dp_zig("LP"), G), ("6323MP zig", [41], lambda: dp_zig("MP"), G),
                 ("623LP late", [40], lambda: dp_late("LP"), G)]
EVENTS["DE+"] = [(f"66,623{b} +{at}", [r] if at == 22 else [], (lambda b=b, at=at: dash_dp_at(b, at)), G)
                 for b, r in (("LP", 31), ("MP", 32), ("HP", 33)) for at in (6, 9, 16, 22)]
TAB_ID["BI+"] = TAB_ID["BI"]; TAB_ID["DE+"] = TAB_ID["DE"]
# HIT ARBITRATION PARTS (a tab with a "~": WALK-IN to contact, as vanilla_join_rig's `near`/`hit` sets — a near
# pair cannot be poked, the pushboxes cross the fighters, 14z-120): the moves whose hit COUNT the sheet and our
# derivation disagree on, and which whiff at the 128 px pin. They name no rows: they count P2's HP drops only.
H = 480
def chg_dbf(b):  # [1] (down-back) 60 f, then 6+button: a back charge that does NOT walk P1 away from contact
    return [(0, 60, "DL"), (61, 64, "R" + B[b])]
EVENTS["BI~"] = [(k, [], r, H) for k, r in (("[1]6LP", lambda: chg_dbf("LP")), ("[1]6MP", lambda: chg_dbf("MP")),
                                            ("[1]6HP", lambda: chg_dbf("HP")), ("[1]6LK", lambda: chg_dbf("LK")),
                                            ("[1]6MK", lambda: chg_dbf("MK")), ("[1]6HK", lambda: chg_dbf("HK")))]
EVENTS["DE~"] = [(k, [], r, H) for k, r in (("623LP", lambda: dp("LP")), ("623MP", lambda: dp("MP")), ("623HP", lambda: dp("HP")))]
EVENTS["GA~"] = [(k, [], r, H) for k, r in (("[2]8LK", lambda: chg_du("LK")), ("[2]8MK", lambda: chg_du("MK")),
                                            ("[2]8HK", lambda: chg_du("HK")))]
TAB_ID["BI~"] = TAB_ID["BI"]; TAB_ID["DE~"] = TAB_ID["DE"]; TAB_ID["GA~"] = TAB_ID["GA"]
# STATE PARTS (a tab with a "^", 14z-205c, #229): WALK-IN to contact like a "~" part, but its events CARRY ROWS: the
# move exists only in a state contact makes. BI's Tsuji Hayate (row 38, 236P): CPU:$041A04 stamps command 0x16 only
# while the opponent is in the state a connecting Karame Dama leaves (P2, build/agent205/t229/p2_es_ex/REPORT.md: its
# 4123LP~236LP@30 at contact entered a2:0x38>0x39); from neutral 236P is a 6+P (the "BI" part, no row).
def then_at(first, second, at):   # `first`, then `second` starting `at` frames after `first` starts
    return first + [(a + at, bb + at, t) for a, bb, t in second]
EVENTS["BI^"] = [(f"4123{b}~236{b}@30", [38], (lambda b=b: then_at(k4123(b), qcf(b), 30)), H) for b in ("LP", "MP", "HP")]
TAB_ID["BI^"] = TAB_ID["BI"]


# The rows of this family the schedule does NOT run, each with its reason (reported by `join`).
NOT_RUN = {
    ("AN", 47): "an EX super by its sheet input (HK,MP,2,MK,HP) — fork F3's family",
    ("AN", 48): "an EX super by its sheet input (MK,LP,2,LK,MP) — fork F3's family",
    ("BI", 19): "typed `?`: J.MP, a jumping normal (#117's aerial join), not a special",
    ("DE", 27): "a guard-cancel row typed `special` (DEMON CRADLE GC) — fork F5's family",
    ("DE", 28): "a guard-cancel row typed `special` (DEMON CRADLE GC) — fork F5's family",
    ("DE", 29): "a guard-cancel row typed `special` (DEMON CRADLE GC) — fork F5's family",
}
# Rows that ARE run but cannot join on an idle standing victim, with the reason (measured on the first pass).
UNJOINABLE = {
    ("FE", 48): "TOY TOUCH 22P is an OTG move (mizuumi lists it under Felicia's pursuits): on an idle standing victim 22+P "
                "entered her crouching normals a2:0x0c-0x0e on both legs — it needs a downed victim (fork F6's rigs)",
    ("AN", 33): "SPELL OF TURNING (RELEASE) 236K releases an ABSORBED projectile: P2 (Victor, idle) throws none, and 236LK "
                "entered a standing normal (a2:0x06) on both legs",
}


WIDE = (488, 820)   # 332 px: the WHIFF leg, inside the engine's 336 px separation clamp (tests/test_meter_gain.sh)


def gen(tab, out_rpl, out_sched, pins=None):
    cid = TAB_ID[tab]
    lines = [f"# vanilla specials rig — {tab} (char {cid:#04x}) (tools/specials_a_rigs.py gen; DO NOT hand-edit,",
             "# regenerate). Select prologue from replay 17; the character is FORCED by the early-window poke.",
             nm.REPLAY17_PROLOGUE.rstrip()]
    x1, x2 = pins or nm.PIN["far"]
    t0 = t = nm.FIRST_EVENT
    sched = {"tab": tab, "char": f"{cid:#04x}", "pins": [x1, x2], "events": [], "pokes": []}
    pins = []
    walkin = tab[-1] in "~^"   # "~" hit parts and "^" state parts walk in to contact
    if walkin:
        t0 = t = nm.FIRST_EVENT + vjr.WALKIN_SHIFT     # the round intro eats a first walk-in (vanilla_join_rig, #134)
    for key, rows, rec, gap in EVENTS[tab]:
        if walkin:
            pins += [f"{t - 230}:ff8410:{x1:04x}", f"{t - 230}:ff8810:{x2:04x}"]
            lines.append(f"{t - 190}-{t - 40} p1=R")    # walk in to contact; never poke a near pair
        else:
            pins += [f"{t - 40}:ff8410:{x1:04x}", f"{t - 40}:ff8810:{x2:04x}"]
        r = rec()
        press = max(a for a, bb, tok, *w in r if any(ch.isdigit() for ch in tok) or tok == "S1")
        for a, bb, tok, *who in r:
            lines.append(f"{t + a}-{t + bb} {(who[0] if who else 'p1')}={tok}")
        sched["events"].append({"key": key, "rows": rows, "frame": t, "press": t + press, "gap": gap})
        t += gap
    end = t + 200
    lines.append(f"{end} wait")
    assert end - t0 < 7500, f"{tab}: a part must fit inside one round ({end - t0})"
    pokes = [f"{f}:ff8782:{cid:02x}" for f in (1400, 1450, 1500)]
    pokes += [f"{f}:ff8b82:03" for f in (1400, 1450, 1500)]          # P2 = Victor, idle
    ev = [e["frame"] for e in sched["events"]]
    for f in range(t0 - 50, end, nm.HP_PIN_EVERY):                   # the HP pin, moved off every event window
        if all(not (e - 20 <= f < e + 200) for e in ev):
            pokes.append(f"{f}:ff8850:01200120")
    pokes += [f"{e - 20}:ff8850:01200120" for e in ev]
    pokes += pins
    sched["pokes"] = pokes
    sched["frames"] = end + 50
    sched["fields"] = FIELDS
    Path(out_rpl).write_text("\n".join(lines) + "\n")
    Path(out_sched).write_text(json.dumps(sched, indent=1) + "\n")
    print(f"wrote {out_rpl} ({len(sched['events'])} events, ends {end}) and {out_sched}")


def node_map_signed(img, cid):
    """{node addr: (chain, idx, hbA record, dur)} over the fighter tables a2, a, b, c (first table to claim a node
    keeps it, a2 first as tools/vanilla_join_rig.node_map), the index tables' word offsets read SIGNED: the engine
    adds them sign-extended, and some tables carry NEGATIVE offsets that tools/anim_nodes.walk_table reads unsigned
    (#229, found by fork F2: Sasquatch's a2 0x24/0x25, and negative entries in BU a2 0x5e-0x60, GA a2 0x75, AN a2
    0x42/0x56, DE c 0x2e-0x2f, FE b 0x6e). A local copy of F2's walk_signed (tools/specials_b_rigs.py: same node
    rules — flags bit 7 = link at +0x18, bit 6 = hold, else sequential; the entry count bounded by the smallest
    positive offset), never an edit of the shared tool. SPECIALS_A_UNSIGNED=1 reads the offsets unsigned (the
    first pass's reading), so the two readings can be compared."""
    import anim_nodes, os
    rows = vanilla_frames.bank_rows(Path(__file__).resolve().parent.parent / "build/manifest/bank_map.toml")
    signed = os.environ.get("SPECIALS_A_UNSIGNED") != "1"
    out = {}
    for tn in ("a2", "a", "b", "c"):
        table = vanilla_frames.row_ptr(img, rows["anim_index_" + tn], cid)
        words, k = [], 0
        while k < 1024:
            w = int.from_bytes(img[table + 2 * k:table + 2 * k + 2], "big", signed=signed)
            pos = [x for x in words if x > 0]
            if pos and k * 2 >= min(pos):
                break
            words.append(w); k += 1
        for seq, w in enumerate(words):
            if w == 0 or w & 1:
                continue
            a, seen, i = table + w, set(), 0
            while a not in seen and 0 <= a < len(img) - 0x1C and i < anim_nodes.MAX_NODES:
                seen.add(a)
                out.setdefault(a, (f"{tn}:{seq:#04x}", i, img[a + 10], img[a]))
                fl = img[a + 1]; i += 1
                if fl & 0x80:
                    a = int.from_bytes(img[a + 0x18:a + 0x1C], "big")
                elif fl & 0x40:
                    break
                else:
                    a += anim_nodes.NODE
    return out


def _pool_alive(kv, n):
    v = kv.get(f"o{n}")
    if v is None:
        return None, None
    v &= 0xFFFFFFFF
    return (v >> 24) & 0xFF, (v >> 8) & 0xFF      # +0x00 alive, +0x02 type


def analyse(tab, trace, sched_path, img_path, window=150):
    sched = json.loads(Path(sched_path).read_text())
    img = Path(img_path).read_bytes()
    cid = TAB_ID[tab]
    nmap = node_map_signed(img, cid)
    fr = vjr._samples(trace)
    # THE TICK LOG (tests/lua/specials_trace.lua's tick tap): "T <frame> <node>", one line per engine tick of P1's
    # animation countdown, in the order the game ran them; the frame is the one whose field line shows its result
    tks = []
    for ln in Path(trace).read_text().splitlines():
        if ln.startswith("T "):
            _, a_, b_ = ln.split()
            tks.append((int(a_), int(b_) & 0xFFFFFFFF))
    out = []
    for e in sched["events"]:
        t0, obs = e["frame"], e["press"]
        chain_at = lambda f: (nmap.get(fr.get(f, {}).get("node", -1) & 0xFFFFFFFF) or (None,))[0]
        before = {chain_at(f) for f in range(t0 - 30, obs) if f in fr}
        seen, first, first_f = [], None, None
        for f in range(obs, obs + window):
            c = chain_at(f)
            if c and c not in before and c not in [s[0] for s in seen]:
                seen.append((c, f - obs))
                if first is None:
                    first, first_f = c, f - obs
        # projectiles: a slot that turns alive inside the window (alive at none of the 5 frames before the press)
        spawned = []
        for n in range(32):
            pre = [_pool_alive(fr.get(f, {}), n)[0] for f in range(obs - 5, obs)]
            if any(x for x in pre if x):
                continue
            for f in range(obs, obs + window):
                al, ty = _pool_alive(fr.get(f, {}), n)
                if al:
                    spawned.append({"slot": n, "type": ty, "at": f - obs})
                    break
        # live: frames contiguous in the first chain, and the attack nodes within them
        live = None
        if first:
            run, f = [], obs + first_f
            while f < obs + window:
                d = nmap.get(fr.get(f, {}).get("node", -1) & 0xFFFFFFFF)
                if not d or d[0] != first:
                    break
                run.append(d); f += 1
            atk = [i for i, d in enumerate(run) if d[2]]
            live = {"frames": len(run), "first_attack": (first_f + atk[0]) if atk else None,
                    "attack_frames": len(atk)}
        # THE MOVE'S NODE WALK, for the derivation: from the move's first new chain to the first BASELINE chain
        # (idle/walk/crouch/jump/landing, name_moves.BASELINE = table a 0x00-0x10). One entry per node OCCURRENCE:
        # a new occurrence when the node pointer changes OR the node counter +0x20 reloads (rises), so a node
        # that loops on itself is counted each time, never collapsed. Each entry is (addr, chain, idx, rec, dur).
        walk, seqc, end_chain = [], [], None
        if first:
            prev_a = prev_c = None
            for f in range(obs + first_f, e["frame"] + e["gap"] - 20):
                s_ = fr.get(f, {}); a_ = s_.get("node", -1) & 0xFFFFFFFF; d = nmap.get(a_)
                if not d:
                    continue
                tn, sq = d[0].split(":")
                if (tn, int(sq, 16)) in nm.BASELINE:
                    end_chain = d[0]
                    break
                cnt = s_.get("cnt")
                if a_ != prev_a or (cnt is not None and prev_c is not None and cnt > prev_c):
                    walk.append([a_, d[0], d[1], d[2], d[3]])
                    if not seqc or seqc[-1] != d[0]:
                        seqc.append(d[0])
                prev_a, prev_c = a_, cnt
        # LIVE ENGINE TICKS of the move: from the first tick on its first new chain (at or after the press) to the
        # first tick on a baseline chain or the event's end — startup = ticks before the first tick on an attack node,
        # active = ticks on attack nodes, recovery = ticks after the last attack tick (frame_data.derive's definitions,
        # counted on the engine's own ticks instead of summed from duration bytes)
        ticks = None
        if first and tks:
            seg, started = [], False
            for tf, tn_ in tks:
                if tf < obs + first_f or tf >= t0 + e["gap"] - 20:
                    continue
                d = nmap.get(tn_)
                if not started:
                    if d and d[0] == first:
                        started = True
                    else:
                        continue
                if d:
                    tn, sq = d[0].split(":")
                    if (tn, int(sq, 16)) in nm.BASELINE:
                        break
                seg.append(d[2] if d else 0)
            at = [i for i, r in enumerate(seg) if r]
            ticks = {"total": len(seg), "startup": at[0] if at else None, "active": len(at) if at else None,
                     "recovery": (len(seg) - at[-1] - 1) if at else None}
        hp = [fr[f]["p2hp"] for f in range(obs, obs + window) if f in fr and "p2hp" in fr[f]]
        hits = sum(1 for a, b in zip(hp, hp[1:]) if b < a and a - b < 200)
        face = fr.get(obs, {}).get("p1face")
        out.append({"key": e["key"], "rows": e["rows"], "frame": t0, "press": obs,
                    "entered": first or "UNFIRED", "entered_at": first_f, "all": seen, "seq": seqc, "walk": walk, "end_chain": end_chain, "ticks": ticks,
                    "spawned": spawned, "live": live, "p2_hits": hits, "p1_faces_right": face == 1 if face is not None else None})
    return {"tab": tab, "char": sched["char"], "events": out}


def _sheet_rows(sheet):
    import xlsx_read
    wb = xlsx_read.Workbook(sheet)
    return {t: wb.rows(t) for t in wb.sheet_names}


def join(results, image, sheet, out_json=None):
    import crosscheck_framedata as cf
    img = Path(image).read_bytes()
    rows_map = vanilla_frames.bank_rows(Path(__file__).resolve().parent.parent / "build/manifest/bank_map.toml")
    sh = _sheet_rows(sheet)
    joined, pairs = [], {}
    # rows joined by MORE THAN ONE event (a one-row-for-every-strength cell like "236P", run with each strength)
    multi = {}
    for rp in results:
        res = json.loads(Path(rp).read_text())
        for e in res["events"]:
            for ri in e["rows"]:
                multi.setdefault((res["tab"].rstrip("+^"), ri), []).append(e["key"])
    for rp in results:
        res = json.loads(Path(rp).read_text())
        tab = res["tab"].rstrip("+^"); cid = TAB_ID[res["tab"]]
        import frame_data, hitbox_records
        H = hitbox_records.HitboxSet.from_image(img, vanilla_frames.row_ptr(img, rows_map["hitbox_base"], cid),
                                                vanilla_frames.row_ptr(img, rows_map["hitbox_comp"], cid))
        def rec_of(a):
            try:
                return H.record(a)
            except IndexError:
                return None
        for e in res["events"]:
            for ri in e["rows"]:
                srow = sh[tab][ri]
                rec = {"tab": tab, "row": ri, "move": srow.get("move"), "input": srow.get("input"),
                       "type": srow.get("type"), "key": e["key"], "entered": e["entered"],
                       "spawned": [s["type"] for s in e["spawned"]], "cols": {}}
                w = e.get("walk") or []
                hid = {x[3]: (rec_of(x[3]) or {}).get("hit_id") for x in w if x[3]}
                fd = frame_data.derive([x[4] for x in w], [x[3] for x in w], hid) if w else None
                dm = None
                if fd:
                    hits = [rec_of(r["records"][0]) for r in fd["runs"] if r["kind"] == "hit"]
                    if hits and all(hits):
                        dm = {"red": sum(h["real_class"] for h in hits), "white": sum(h["white_class"] for h in hits),
                              "gauge_hit": sum(h["meter"] for h in hits), "hits": len(hits)}
                rec["seq"] = e.get("seq"); rec["ours"] = ({k: fd[k] for k in ("startup", "active", "recovery", "notation")}
                                                        if fd else None)
                rec["p2_hits"] = e.get("p2_hits")
                normal_row = (srow.get("type") or "").strip().lower() in ("projectile", "jumping projectile")
                ent = e["entered"]
                entered_normal = (ent.startswith("a2:") and int(ent.split(":")[1], 16) < 0x1E) or (ent.startswith("a:") and
                                  ("a", int(ent.split(":")[1], 16)) in nm.BASELINE)
                why_out = UNJOINABLE.get((tab, ri))
                for col, heads, _ in cf.COLUMNS:
                    cell = next((srow.get(h) for h in heads if srow.get(h) not in (None, "")), None)
                    if ent == "UNFIRED":
                        rec["cols"][col] = ("UNCOMPARABLE", "the event did not fire"); continue
                    if why_out:
                        rec["cols"][col] = ("UNJOINABLE", why_out); continue
                    if entered_normal and not normal_row:
                        rec["cols"][col] = ("UNCOMPARABLE", f"the event entered {ent}, a plain normal or baseline chain: the special did not fire"); continue
                    if col in ("startup", "active", "recovery"):
                        ours = fd.get(col) if fd else None
                        tk = e.get("ticks")
                        if tk is not None and fd is not None:
                            rec.setdefault("derived_vs_ticks", {})[col] = (fd.get(col), tk.get(col))
                            ours = tk.get(col)          # the LIVE engine ticks are what is compared
                        sv = cf.parse_runs(cell) if col == "active" else cf.num(cf._plain(cell)) if cell is not None else None
                        if col in ("recovery", "active") and (e.get("p2_hits") or 0) > 0:
                            rec["cols"][col] = ("UNCOMPARABLE", f"the move connected ({e['p2_hits']} hit(s))" + (" at contact (a state part)" if res["tab"].endswith("^") else " even at the 332 px whiff pin") + ": the walk took the on-hit branch")
                            continue
                        if col == "recovery" and sv is None and cell is not None:
                            m = re.match(r"^\s*(\d+)\s*\+\s*landing\s*(\d+)\s*$", str(cell))
                            if m:
                                # our walk stops at a baseline chain: when that is the landing (a:0x0c / a:0x0f) the
                                # landing is NOT in ours, so the sheet's pre-landing X compares; otherwise the landing is
                                # an a2 chain inside the walk and X + Y compares
                                excl = e.get("end_chain") in ("a:0x0c", "a:0x0f")
                                sv = float(m.group(1)) if excl else float(m.group(1)) + float(m.group(2))
                                rec.setdefault("notes", []).append(f"recovery: sheet {'X' if excl else 'X+Y'} of {cell!r} (walk ended at {e.get('end_chain')})")
                        if ours is None:
                            rec["cols"][col] = ("UNCOMPARABLE", "the move's walk has no attack node (a projectile thrown by the fighter, or a movement): no fighter-side frame data")
                            continue
                    else:
                        ours = None
                        if dm:
                            ours = {"white": dm["white"], "gauge_hit": dm["gauge_hit"], "red": dm["red"] + dm["white"]}[col]   # summed over the hit runs
                        sv = cf.parse_total(cell) if cell is not None else None
                        if col == "gauge_hit" and sv is not None:
                            wf = next((srow.get(h) for h in cf.GAUGE_WHIFF if srow.get(h) not in (None, "")), None)
                            w = cf.parse_total(wf) if wf is not None else 0
                            sv = sv - (w or 0)
                        if ours is None:
                            rec["cols"][col] = ("UNCOMPARABLE", "the move's walk carries no attack record"); continue
                    if sv is None:
                        rec["cols"][col] = ("UNCOMPARABLE", f"sheet cell {cell!r} is prose or empty"); continue
                    rec["cols"][col] = ("PAIR", sv, ours)
                    if len(e["rows"]) == 1 and sum(1 for x in multi.get((tab, ri), [])) <= 1:
                        pairs.setdefault((tab, col), []).append((f"{srow.get('input')}/{e['key']}", sv, ours))
                joined.append(rec)
    # THE ONE-ROW CLAIMS: does the sheet's single value hold for every strength? (the ground-throw rigs' rule)
    claims = []
    for (t, ri), keys in sorted(multi.items()):
        if len(keys) < 2:
            continue
        rs = [r for r in joined if r["tab"] == t and r["row"] == ri]
        for col in ("startup", "active", "recovery", "red", "white", "gauge_hit"):
            vals = [(r["key"], r["cols"].get(col)) for r in rs]
            pr = [(k, v[1], v[2]) for k, v in vals if v and v[0] == "PAIR"]
            if pr:
                claims.append({"tab": t, "row": ri, "col": col, "sheet": pr[0][1], "ours_by_key": {k: o for k, _, o in pr},
                               "strength_invariant": len({o for _, _, o in pr}) == 1})
    verdicts = {f"{t}\t{c}": cf.classify(p) for (t, c), p in sorted(pairs.items())}
    allcols = {}
    for (t, c), p in pairs.items():
        allcols.setdefault(c, []).extend(p)
    overall = {c: cf.classify(p) for c, p in sorted(allcols.items())}
    out = {"joined": joined, "verdicts": verdicts, "overall": overall, "one_row_claims": claims,
           "not_run": [{"tab": t, "row": r, "why": w} for (t, r), w in NOT_RUN.items()],
           "unjoinable": [{"tab": t, "row": r, "why": w} for (t, r), w in UNJOINABLE.items()]}
    if out_json:
        Path(out_json).write_text(json.dumps(out, indent=1) + "\n")
    for k, v in verdicts.items():
        print(k, *v, sep="\t")
    print("OVERALL")
    for k, v in overall.items():
        print(k, *v, sep="\t")
    return out


def snap_frame(e, lag=12):
    """The frame a capture shows for one fired event: a projectile's spawn + 8 (the object on screen), else the
    move's first attack frame (live), else its entry + `lag`."""
    if e["spawned"]:
        return e["press"] + e["spawned"][0]["at"] + 8
    if e.get("live") and e["live"].get("first_attack") is not None:
        return e["press"] + e["live"]["first_attack"]
    return e["press"] + e["entered_at"] + lag


def snaps(sched_path, analysis_path):
    """SNAP_FRAMES for the capture: one frame per fired event (snap_frame), ascending."""
    an = json.loads(Path(analysis_path).read_text())
    print(",".join(str(f) for f in sorted(snap_frame(e) for e in an["events"] if e["entered"] != "UNFIRED")))


def sheet(out_png, specs):
    """The capture sheet: one block of tiles per part, each captioned with the key PRESSED, the chain sequence
    entered, what it spawned and the frame shown; this picture is what the maintainer confirms identity on.
    MAME numbers its snapshots in order, so they are matched to the ascending snap frames by sorted order."""
    from PIL import Image, ImageDraw
    blocks = []
    for spec in specs:
        tab, snapdir, an_path = spec.split(":")
        an = json.loads(Path(an_path).read_text())
        fired = sorted((snap_frame(e), e) for e in an["events"] if e["entered"] != "UNFIRED")
        shots = sorted(Path(snapdir).rglob("*.png"))
        if len(shots) != len(fired):
            sys.exit(f"sheet: {tab}: {len(shots)} snapshots for {len(fired)} fired events")
        tiles = []
        for (f, e), p in zip(fired, shots):
            sp = ",".join(f"t{x['type']:02x}@{x['at']}" for x in e["spawned"]) or "-"
            tiles.append((f"{tab} {e['key']}  f{f} (+{f - e['press']})", f"{'>'.join(e['seq']) or e['entered']}  obj {sp}",
                          Image.open(p).convert("RGB")))
        blocks.append((tab, tiles))
    W, Hh, CAP, PER = 384, 224, 34, 4
    height = sum(24 + ((len(t) + PER - 1) // PER) * (Hh + CAP) for _, t in blocks)
    im = Image.new("RGB", (W * PER, height), (24, 24, 24)); d = ImageDraw.Draw(im); y = 0
    for tab, tiles in blocks:
        d.text((6, y + 6), f"{tab} - vsavj, P1 forced, P2 Victor idle, 332 px whiff pin (tools/specials_a_rigs.py)", fill=(255, 220, 120))
        y += 24
        for i, (c1, c2, tile) in enumerate(tiles):
            x = (i % PER) * W; yy = y + (i // PER) * (Hh + CAP)
            im.paste(tile.resize((W, Hh)), (x, yy + CAP))
            d.text((x + 4, yy + 3), c1[:62], fill=(240, 240, 240)); d.text((x + 4, yy + 17), c2[:62], fill=(160, 220, 255))
        y += ((len(tiles) + PER - 1) // PER) * (Hh + CAP)
    im.save(out_png)
    print(f"wrote {out_png} ({sum(len(t) for _, t in blocks)} tiles)")


def table(paths):
    """THE IDENTITY ROWS the gate freezes, one per event: tab, key, the chain sequence entered (or UNFIRED),
    the object types it spawned, P2's HP drops in its window, and whether P1 faced right at the press. Naming
    facts (as tests/expected/vanilla_command_slots.tsv), never frame values."""
    for p in paths:
        an = json.loads(Path(p).read_text())
        for e in an["events"]:
            seq = ">".join(e["seq"]) or e["entered"]
            sp = ",".join(sorted({f"{x['type']:02x}" for x in e["spawned"]})) or "-"
            print(f"{an['tab']}\t{e['key']}\t{seq}\t{sp}\t{e['p2_hits']}\t{'R' if e['p1_faces_right'] else 'L'}")


def values_hash(join_json):
    """sha256 of every joined PAIR (row, column, sheet, ours) — the per-move values are frozen by hash only."""
    import hashlib
    j = json.loads(Path(join_json).read_text())
    lines = sorted(f"{r['tab']}\t{r['row']}\t{r['key']}\t{c}\t{v[1]}\t{v[2]}" for r in j["joined"]
                   for c, v in r["cols"].items() if v[0] == "PAIR")
    print(hashlib.sha256("\n".join(lines).encode()).hexdigest(), len(lines))


def tick_agreement(join_json):
    """Per timing column: on how many joined row-events the LIVE engine ticks equal the duration-byte derivation of
    the same node walk (a difference is game logic cutting a node short — a landing, a jump — which the bytes
    cannot see). One line: TICKS-AGREE<TAB>startup a/n, active a/n, recovery a/n."""
    j = json.loads(Path(join_json).read_text())
    parts = []
    for c in ("startup", "active", "recovery"):
        pr = [r["derived_vs_ticks"][c] for r in j["joined"] if c in (r.get("derived_vs_ticks") or {})
              and r["derived_vs_ticks"][c][0] is not None and r["derived_vs_ticks"][c][1] is not None]
        parts.append(f"{c} {sum(1 for d, t in pr if d == t)}/{len(pr)}")
    print("TICKS-AGREE\t" + ", ".join(parts))


def main():
    a = sys.argv[1:]
    if a[:1] == ["gen"] and len(a) in (4, 6):
        return gen(a[1], a[2], a[3], (int(a[4]), int(a[5])) if len(a) == 6 else None)
    if a[:1] == ["table"]:
        return table(a[1:])
    if a[:1] == ["tick-agreement"] and len(a) == 2:
        return tick_agreement(a[1])
    if a[:1] == ["values-hash"] and len(a) == 2:
        return values_hash(a[1])
    if a[:1] == ["snaps"] and len(a) == 3:
        return snaps(a[1], a[2])
    if a[:1] == ["sheet"] and len(a) >= 3:
        return sheet(a[1], a[2:])
    ap = argparse.ArgumentParser()
    ap.add_argument("mode", choices=["analyse", "join"])
    ap.add_argument("args", nargs="+")
    ap.add_argument("--json")
    ap.add_argument("--image")
    ap.add_argument("--sheet", default=str(Path(__file__).resolve().parent.parent.parent / "community/vsav-framedata.xlsx"))
    n = ap.parse_args()
    if n.mode == "analyse":
        tab, trace, sched, image = n.args
        res = analyse(tab, trace, sched, image)
        if n.json:
            Path(n.json).write_text(json.dumps(res, indent=1) + "\n")
        for e in res["events"]:
            sp = ",".join(f"t{s['type']:02x}@{s['at']}" for s in e["spawned"]) or "-"
            rest = " ".join(f"{c}@{f}" for c, f in e["all"][1:])
            print(f"{tab}\t{e['key']}\t{e['entered']}\t{e['entered_at']}\t{sp}\thits={e['p2_hits']}\tR={e['p1_faces_right']}\t{rest}")
        return
    join(n.args, n.image, n.sheet, n.json)


if __name__ == "__main__":
    main()
