#!/usr/bin/env python3
"""name_moves.py — THE NAMING STEP of the character-data map (phase 1):
attribute each move of build/manifest/moves_<tenant>.toml to the anim chain
(table, seq) the engine ENTERS when the move is performed on the tenant's
NATIVE game.

  python3 tools/name_moves.py gen  <tenant> <part> <out.rpl> <schedule.json>
  python3 tools/name_moves.py analyse <schedule.json> <field_trace.txt> <chains_dir> [--json out]
  python3 tools/name_moves.py expect  <schedule.json> <field_trace.txt> <chains_dir>   # the gate's frozen lines

METHOD. A scripted input is NOT the move it names ([VSE-47]): the buffer
folds directions and a strength may downgrade. So the rig never trusts its
own script — it samples P1's anim node pointer obj+0x1C every frame
(tests/lua/field_trace.lua, the instrument test_anim_node_walk.sh verified
against 3,638 native frames) and maps each pointer onto the decoded chain
graph (tools/anim_nodes.py). The CHAIN the fighter enters inside a window
after the scheduled input is the measurement; a move whose window shows no
new chain is reported UNFIRED, never guessed.

THE SCHEDULE is data in this file (per tenant, per part): each event is
(name, recipe) and the generator lays events out at fixed spacing on top
of replay 17's select prologue (P1 = the tenant at the native game's
default-cursor R,R, P2 Victor R,R, both human, P2 idle). Recipes are the
input cadences of rigs that ALREADY fired the move natively (59 for
41236, 60 for 63214, 19 for 623, 48/56 for 421, 50 for 214, 27 for the
toward-throw). Parts keep each replay under a round's timer.

WHAT THE OUTPUT MEANS. For each event: the chains entered in
[t, t+window), in order, with the entry frame and how the walker got
there (`jump` = a new sequence begun by game logic = the move's own
chain; `edge` = the walker following the graph). The FIRST jump after
the input is the candidate; everything after it (recovery, landing) is
listed so a multi-chain move is visible. Baseline chains (idle, walk,
crouch, jump) are named by the movement events and shown greyed on
later events so a whiff's return to idle is not read as a move.
"""
import argparse
import json
import sys
from pathlib import Path

# ---------------------------------------------------------------- prologue
# replay 17's select prologue on vsav2 (P1 = default cursor R,R = the tenant
# on its native game for Donovan; P2 Victor R,R). Match anchor 2363,
# actionable ~2463 on both games (test_m2a_stage4_oracle.sh).
PROLOGUE = """300-305 sys=C1
420-425 sys=C2
800-803 sys=S1
940-943 sys=S2
1100-1102 p1=R
1160-1162 p1=R
1104-1106 p2=R
1164-1166 p2=R
1300-1302 p1=1
1360-1362 p2=1
"""
FIRST_EVENT = 2600
# P2 HP re-pin (both words, [VSP-125]) so a projectile-fed Victor never dies.
HP_PIN_EVERY = 400

# ---------------------------------------------------------------- recipes
# A recipe is a list of (start_offset, end_offset, tokens) relative to the
# event frame; tokens in replay.lua grammar (U D L R 1-6). P1 faces RIGHT.
B = {"LP": "1", "MP": "2", "HP": "3", "LK": "4", "MK": "5", "HK": "6",
     "PP": "13", "KK": "46"}  # PP/KK = any two: LP+HP / LK+HK (ES resolver takes any pair)


def stand(b):      return [(0, 2, B[b])]
def crouch(b):     return [(0, 3, "D" + B[b])]
def jump(b):       return [(0, 2, "U"), (14, 17, B[b])]
def fwd(b):        return [(0, 3, "R" + B[b])]
def air_down(b):   return [(0, 2, "U"), (16, 19, "D" + B[b])]
def qcf(b):        return [(0, 1, "D"), (2, 3, "DR"), (4, 8, "R"), (5, 9, B[b])]            # 236
def dp(b):         return [(0, 2, "R"), (4, 6, "D"), (8, 11, "DR" + B[b])]                  # 623 (replay 19)
def qcb(b):        return [(0, 4, "D"), (5, 9, "DL"), (10, 18, "L"), (14, 20, B[b])]        # 214 (replay 50)
def hcf(b):        return [(0, 2, "L"), (4, 6, "DL"), (8, 10, "D"), (12, 14, "DR"), (16, 20, "R"), (18, 22, B[b])]  # 41236 (59)
def hcb(b):        return [(0, 2, "R"), (4, 6, "DR"), (8, 10, "D"), (12, 14, "DL"), (16, 22, "L"), (18, 22, B[b])]  # 63214 (60)
def rdp(b):        return [(0, 2, "L"), (4, 6, "D"), (8, 12, "DL"), (10, 14, B[b])]        # 421 (replays 48/56)
def air_qcb(b):    return [(0, 2, "U"), (12, 16, "D"), (17, 21, "DL"), (22, 30, "L"), (26, 32, B[b])]
def air_qcf(b):    return [(0, 2, "U"), (12, 13, "D"), (14, 15, "DR"), (16, 20, "R"), (17, 21, B[b])]
def air_dp(b):     return [(0, 2, "U"), (12, 14, "R"), (16, 18, "D"), (20, 23, "DR" + B[b])]
def air_rdp(b):    return [(0, 2, "U"), (12, 14, "L"), (16, 18, "D"), (20, 24, "DL"), (22, 26, B[b])]
def walk_in(n):    return [(0, n, "R")]
def throw_fwd(b):  return [(0, 3, "R" + B[b])]
def pair(b):       return [(0, 4, b)]                                                       # DF: same-strength P+K
def dash_f():      return [(0, 1, "R"), (4, 5, "R")]
def dash_b():      return [(0, 1, "L"), (4, 5, "L")]
def seq_buttons(bs, gap=3):
    return [(i * gap, i * gap + 1, B[b] if b in B else b) for i, b in enumerate(bs)]


def air_qcb_fast(b):  # the motion right off the jump, button overlapping L
    return [(0, 2, "U"), (6, 8, "D"), (9, 11, "DL"), (12, 18, "L"), (14, 18, B[b])]


def throw_then_pursuit(b):
    # toward-MP throw up close (replay 27's cadence), then U+button pressed
    # at several offsets across the victim's fall/flat window ([VSE-72]);
    # a press that misses the window reads as a plain jump (a:0x0e) and is
    # visible as such.
    return [(0, 3, "R2")] + [(o, o + 2, "U" + B[b]) for o in (50, 65, 80, 95, 110)]


def pursuit(b):
    # sweep (2HK) up close then U+button during the FALL ([VSE-72]: the
    # window is the fall + first flat frames). 2HK's active frames + the
    # victim's fall: press U+b 18f after the sweep and again 10f later.
    return [(0, 3, "D6"), (18, 20, "U" + B[b]), (28, 30, "U" + B[b])]


# ---------------------------------------------------------------- schedules
# (event name, recipe, spacing-after). Names match moves_<tenant>.toml
# rows; a row with several inputs is measured per input as "<row> [input]".
DONOVAN = {
    "1": [  # movement + plain normals + command normals (no meter)
        ("Walk forward", walk_in(40), 120),
        ("Walk back", [(0, 40, "L")], 120),
        ("Crouch", [(0, 30, "D")], 120),
        ("Jump [8]", [(0, 2, "U")], 120),
        ("Jump [9]", [(0, 2, "UR")], 120),
        ("Jump [7]", [(0, 2, "UL")], 120),
        ("Forward dash", dash_f(), 150),
        ("Back dash", dash_b(), 150),
        ("5LP", stand("LP"), 120), ("5MP", stand("MP"), 120), ("5HP", stand("HP"), 150),
        ("5LK", stand("LK"), 120), ("5MK", stand("MK"), 120), ("5HK", stand("HK"), 150),
        ("2LP", crouch("LP"), 120), ("2MP", crouch("MP"), 120), ("2HP", crouch("HP"), 150),
        ("2LK", crouch("LK"), 120), ("2MK", crouch("MK"), 120), ("2HK", crouch("HK"), 150),
        ("j.LP", jump("LP"), 150), ("j.MP", jump("MP"), 150), ("j.HP", jump("HP"), 150),
        ("j.LK", jump("LK"), 150), ("j.MK", jump("MK"), 150), ("j.HK", jump("HK"), 150),
        ("Hop Kick", fwd("HK"), 150),
        ("Killshread Surf [j.2LK]", air_down("LK"), 150),
        ("Killshread Surf [j.2MK]", air_down("MK"), 150),
        ("Killshread Dive [j.2HK]", air_down("HK"), 150),
    ],
    "2": [  # specials, no meter; then the close-range family
        ("Blizzard Sword [LP]", hcf("LP"), 220),
        ("Blizzard Sword [MP]", hcf("MP"), 220),
        ("Blizzard Sword [HP]", hcf("HP"), 220),
        ("Ifrit Sword [LP]", dp("LP"), 200),
        ("Ifrit Sword [MP]", dp("MP"), 200),
        ("Ifrit Sword [HP]", dp("HP"), 200),
        ("Lightning Sword [LP]", rdp("LP"), 260),
        ("Lightning Sword [MP]", rdp("MP"), 260),
        ("Lightning Sword [HP]", rdp("HP"), 260),
        ("Killshread [LK]", qcb("LK"), 200),
        ("Killshread Lightning [LP]", qcb("LP"), 240),
        ("Killshread Summon [LK]", qcb("LK"), 220),
        ("Killshread [HK]", qcb("HK"), 200),
        ("Killshread Summon [j.214K]", air_qcb("MK"), 220),
        ("walk-in", walk_in(220), 240),
        ("Sharirum Luna [6MP]", throw_fwd("MP"), 260),
        ("walk-in", walk_in(120), 140),
        ("Sharirum Luna [6HP]", throw_fwd("HP"), 260),
        ("walk-in", walk_in(120), 140),
        ("Sword Grapple [MP]", hcb("MP"), 260),
        ("walk-in", walk_in(120), 140),
        ("Sword Grapple [HP]", hcb("HP"), 260),
        ("walk-in", walk_in(100), 120),
        ("Foot Stab [8P]", pursuit("LP"), 260),
        ("walk-in", walk_in(100), 120),
        ("Foot Stab [8K]", pursuit("LK"), 260),
    ],
    "3": [  # meter: ES rows, EX, Dark Force (stock poked at part start + midway)
        ("Blizzard Sword (ES)", hcf("PP"), 240),
        ("Ifrit Sword (ES)", dp("PP"), 220),
        ("Lightning Sword (ES)", rdp("PP"), 300),
        ("Killshread (ES)", qcb("KK"), 220),
        ("Killshread Lightning (ES)", qcb("PP"), 260),
        ("Killshread Summon (ES)", qcb("KK"), 240),
        ("Press of Death [LK]", hcf("LK"), 260),
        ("Press of Death [MK]", hcf("MK"), 260),
        ("Press of Death [HK]", hcf("HK"), 260),
        ("Change Immortal", seq_buttons(["MP", "LP", "L", "LK", "MK"]), 400),
        ("walk-in", walk_in(100), 120),
        ("Foot Stab (ES) [8PP]", pursuit("PP"), 260),
        ("walk-in", walk_in(100), 120),
        ("Foot Stab (ES) [8KK]", pursuit("KK"), 260),
        ("Slay Shred [MP+MK]", pair("25"), 500),
    ],
    "4": [  # the disambiguations: stance family, grapple with sword IN HAND, pursuit off a throw, DF flag
        ("Killshread [MK]", qcb("MK"), 200),                         # plants
        ("Killshread Lightning [MP]", qcb("MP"), 240),               # in stance
        ("Killshread Summon [LK] (2)", qcb("LK"), 220),              # summons back
        ("Killshread [LK] (2)", qcb("LK"), 200),                     # plants
        ("Killshread Lightning [HP]", qcb("HP"), 240),               # in stance
        ("Killshread Summon [HK]", qcb("HK"), 220),                  # summons back
        ("Killshread [HK] (2)", qcb("HK"), 200),                     # plants
        ("Killshread Summon [j.214LK]", air_qcb_fast("LK"), 220),    # in stance, air
        ("Killshread Summon [MK]", qcb("MK"), 220),                  # summons back if the air one missed
        ("walk-in", walk_in(220), 240),
        ("Sword Grapple [MP] (sword in hand)", hcb("MP"), 260),
        ("walk-in", walk_in(120), 140),
        ("Sword Grapple [HP] (sword in hand)", hcb("HP"), 260),
        ("walk-in", walk_in(120), 140),
        ("Foot Stab [8P] off throw", throw_then_pursuit("LP"), 320),
        ("walk-in", walk_in(160), 180),
        ("Foot Stab [8K] off throw", throw_then_pursuit("LK"), 320),
        ("walk-in", walk_in(160), 180),
        ("Foot Stab (ES) [8PP] off throw", throw_then_pursuit("PP"), 320),
        ("walk-in", walk_in(160), 180),
        ("Foot Stab (ES) [8KK] off throw", throw_then_pursuit("KK"), 320),
        ("Slay Shred [LP+LK]", pair("14"), 400),
        ("5LP in DF", stand("LP"), 200),
    ],
    "5": [  # grapple with the sword NEVER planted; close normals; Change Immortal's 2/8 control
        ("walk-in", walk_in(220), 240),
        ("Sword Grapple [MP]", hcb("MP"), 260),
        ("walk-in", walk_in(120), 140),
        ("Sword Grapple [HP]", hcb("HP"), 260),
        ("walk-in", walk_in(120), 140),
        ("5LP close", stand("LP"), 120), ("5MP close", stand("MP"), 120), ("5HP close", stand("HP"), 150),
        ("5LK close", stand("LK"), 120), ("5MK close", stand("MK"), 120), ("5HK close", stand("HK"), 150),
        ("2LP close", crouch("LP"), 120), ("2MP close", crouch("MP"), 120), ("2HP close", crouch("HP"), 150),
        ("2LK close", crouch("LK"), 120), ("2MK close", crouch("MK"), 120), ("2HK close", crouch("HK"), 150),
        ("Change Immortal + 2/8", seq_buttons(["MP", "LP", "L", "LK", "MK"]) + [(40, 70, "D"), (80, 110, "U")], 400),
    ],
    "6": [  # what a2:0x1e/0x21 are: U+button in neutral vs the normals INSIDE Dark Force
        ("U+LP neutral", [(0, 2, "U1")], 150),
        ("U+LK neutral", [(0, 2, "U4")], 150),
        ("Slay Shred [LP+LK]", pair("14"), 120),
        ("5LP in DF", stand("LP"), 120), ("5MP in DF", stand("MP"), 120), ("5HP in DF", stand("HP"), 150),
        ("5LK in DF", stand("LK"), 120), ("5MK in DF", stand("MK"), 120), ("5HK in DF", stand("HK"), 150),
        ("2LP in DF", crouch("LP"), 120), ("2MP in DF", crouch("MP"), 120), ("2HP in DF", crouch("HP"), 150),
        ("2LK in DF", crouch("LK"), 120), ("2MK in DF", crouch("MK"), 120), ("2HK in DF", crouch("HK"), 150),
        ("j.LP in DF", jump("LP"), 150), ("j.MP in DF", jump("MP"), 150), ("j.HP in DF", jump("HP"), 150),
        ("j.LK in DF", jump("LK"), 150), ("j.MK in DF", jump("MK"), 150), ("j.HK in DF", jump("HK"), 150),
        ("Hop Kick in DF", fwd("HK"), 150),
        ("Blizzard Sword [LP] in DF", hcf("LP"), 220),
        ("Ifrit Sword [LP] in DF", dp("LP"), 200),
        ("Lightning Sword [LP] in DF", rdp("LP"), 260),
        ("Killshread [LK] in DF", qcb("LK"), 220),
        ("Killshread Summon [LK] in DF", qcb("LK"), 220),
        ("idle to DF expiry", [], 600),
    ],
    "7": [  # SWORDLESS: plant the sword (Killshread), then the whole set without it
        ("Killshread [LK] (plant)", qcb("LK"), 200),
        ("5LP swordless", stand("LP"), 120), ("5MP swordless", stand("MP"), 120), ("5HP swordless", stand("HP"), 150),
        ("5LK swordless", stand("LK"), 120), ("5MK swordless", stand("MK"), 120), ("5HK swordless", stand("HK"), 150),
        ("2LP swordless", crouch("LP"), 120), ("2MP swordless", crouch("MP"), 120), ("2HP swordless", crouch("HP"), 150),
        ("2LK swordless", crouch("LK"), 120), ("2MK swordless", crouch("MK"), 120), ("2HK swordless", crouch("HK"), 150),
        ("j.LP swordless", jump("LP"), 150), ("j.MP swordless", jump("MP"), 150), ("j.HP swordless", jump("HP"), 150),
        ("j.LK swordless", jump("LK"), 150), ("j.MK swordless", jump("MK"), 150), ("j.HK swordless", jump("HK"), 150),
        ("Hop Kick swordless", fwd("HK"), 150),
        ("Killshread Surf [j.2LK] swordless", air_down("LK"), 150),
        ("Killshread Dive [j.2HK] swordless", air_down("HK"), 150),
        ("Blizzard Sword [LP] swordless", hcf("LP"), 220),
        ("Ifrit Sword [LP] swordless", dp("LP"), 220),
        ("Lightning Sword [LP] swordless", rdp("LP"), 260),
        ("Lightning Sword [HP] swordless", rdp("HP"), 260),
        ("Press of Death [LK] swordless", hcf("LK"), 260),
        ("Forward dash swordless", dash_f(), 150),
        ("walk-in", walk_in(220), 240),
        ("Sharirum Luna [6MP] swordless", throw_fwd("MP"), 260),
        ("walk-in", walk_in(120), 140),
        ("Foot Stab [8P] swordless off throw", throw_then_pursuit("LP"), 320),
        ("Slay Shred [LP+LK] swordless", pair("14"), 200),
    ],
    "8": [  # the back throw; Change Immortal with 8 held through the transformation
        ("walk-in", walk_in(220), 240),
        ("Sharirum Luna [4MP]", [(0, 3, "L2")], 260),
        ("walk-in", walk_in(120), 140),
        ("Sharirum Luna [4HP]", [(0, 3, "L3")], 260),
        ("Change Immortal + 8 held", seq_buttons(["MP", "LP", "L", "LK", "MK"]) + [(20, 200, "U")], 400),
        ("Change Immortal + 2 held", seq_buttons(["MP", "LP", "L", "LK", "MK"]) + [(20, 200, "D")], 400),
    ],
}
SCHEDULES = {"donovan": DONOVAN}
# stock pokes for the meter parts: frame -> 9 stocks (each ES/EX/DF spends 1)
METER_PARTS = {"3", "4", "5", "6", "7", "8"}


def gen(tenant, part, out_rpl, out_sched):
    ev = SCHEDULES[tenant][part]
    lines = [f"# naming rig — {tenant} part {part} (tools/name_moves.py gen; DO NOT hand-edit,",
             "# regenerate). Native-game select prologue from replay 17; events from the",
             "# schedule in the tool. Analyse with: name_moves.py analyse <schedule.json>.",
             PROLOGUE.rstrip()]
    sched = {"tenant": tenant, "part": part, "events": [], "pokes": []}
    t = FIRST_EVENT
    for name, recipe, gap in ev:
        for a, b, tok in recipe:
            lines.append(f"{t + a}-{t + b} p1={tok}")
        # a MOVEMENT event (no button in its recipe) is measured by the baseline
        # family itself (idle/walk/crouch/jump), which other events filter out
        movement = not any(ch.isdigit() for _, _, tok in recipe for ch in tok)
        sched["events"].append({"name": name, "frame": t, "gap": gap, "movement": movement})
        t += gap
    end = t + 200
    lines.append(f"{end} wait")
    # pokes: P2 HP pin every HP_PIN_EVERY frames from the first event; stocks
    pokes = [f"{f}:ff8850:01200120" for f in range(FIRST_EVENT - 50, end, HP_PIN_EVERY)]
    # NO timer poke: $FF8109 is BINARY (99, one tick per ~82 frames = ~8,100
    # frames per round); a 0x99 poke read as 153 ENDED the round (measured
    # 14z-120). Parts are kept under a round instead.
    assert end - FIRST_EVENT < 7500, f"part {part} exceeds a round ({end - FIRST_EVENT} frames)"
    if part in METER_PARTS:
        pokes += [f"{FIRST_EVENT - 60}:ff8509:09", f"{FIRST_EVENT + (end - FIRST_EVENT) // 2}:ff8509:09"]
    sched["pokes"] = pokes
    sched["frames"] = end + 50
    Path(out_rpl).write_text("\n".join(lines) + "\n")
    Path(out_sched).write_text(json.dumps(sched, indent=1))
    print(f"wrote {out_rpl} ({len(ev)} events, ends {end}) and {out_sched}")


# ---------------------------------------------------------------- analyse
def hx(v):
    return int(v, 16) if isinstance(v, str) else int(v)


def load_graph(chains_dir):
    node2chain, starts, edges = {}, {}, {}
    for name in ("a", "a2", "b", "c", "proj"):
        j = json.load(open(Path(chains_dir) / f"{name}.json"))
        for seq, c in j["chains"].items():
            key = (name, int(seq, 0) if isinstance(seq, str) else seq)
            ns = c["nodes"]
            if c.get("start") is None or not ns:
                continue                      # an empty / out-of-region entry
            starts[hx(c["start"])] = key
            for i, n in enumerate(ns):
                a = hx(n["addr"])
                node2chain.setdefault(a, key)
                nxt = None
                if n.get("link") and (n["flags"] & 0x80):
                    nxt = hx(n["link"])
                elif not (n["flags"] & 0x40) and i + 1 < len(ns):
                    nxt = hx(ns[i + 1]["addr"])
                if nxt is not None:
                    edges.setdefault(a, set()).add(nxt)
    return node2chain, starts, edges


def analyse(sched_path, trace_path, chains_dir, out_json=None, window=None):
    sched = json.load(open(sched_path))
    node2chain, starts, edges = load_graph(chains_dir)
    rows = []
    for line in open(trace_path):
        f = line.split()
        if len(f) < 3 or f[0] != "F":
            continue
        d = dict(kv.split("=") for kv in f[2:])
        rows.append((int(f[1]), {k: int(v) for k, v in d.items()}))
    # per-frame chain + transition kind
    frames = {}
    prev = None
    for fr, d in rows:
        node = d["node"]
        key = node2chain.get(node)
        kind = ""
        if prev is not None and node != prev:
            if node in edges.get(prev, ()):
                kind = "edge"
            elif node in starts:
                kind = "jump"
            elif key:
                kind = "jump-mid"      # entered a chain NOT at its start (a2 reaction chains enter by index)
            else:
                kind = "OFF-GRAPH"
        frames[fr] = (node, key, kind, d)
        prev = node
    events = sched["events"]
    report = []
    for i, e in enumerate(events):
        t = e["frame"]
        w = window or e["gap"]
        entered = []
        for fr in range(t, t + w):
            if fr not in frames:
                continue
            node, key, kind, d = frames[fr]
            if kind in ("jump", "jump-mid", "OFF-GRAPH"):
                entered.append({"frame": fr, "rel": fr - t, "chain": key and f"{key[0]}:0x{key[1]:02x}",
                                "kind": kind, "node": f"0x{node:x}", "stock": d.get("stock"),
                                "seq": d.get("seq"), "x": d.get("x"), "y": d.get("y"), "df": d.get("df"), "p2x": d.get("p2x")})
        report.append({"name": e["name"], "frame": t, "entered": entered})
    # baseline chains = those the movement events enter; then print
    base = set()
    for r in report:
        if r["name"] in ("Walk forward", "Walk back", "Crouch") or r["name"].startswith("Jump"):
            base |= {x["chain"] for x in r["entered"]}
    idle = None
    if frames:
        first = frames[min(frames)]
        idle = first[1] and f"{first[1][0]}:0x{first[1][1]:02x}"
    print(f"idle chain at first sampled frame: {idle}; baseline (movement) chains: {sorted(x for x in base if x)}")
    for r in report:
        print(f"\n== {r['name']}  @f{r['frame']}")
        if not r["entered"]:
            print("   UNFIRED: no chain entered in the window")
        for x in r["entered"]:
            tag = "  (baseline)" if x["chain"] in base or x["chain"] == idle else ""
            print(f"   +{x['rel']:4d} f{x['frame']}  {x['kind']:8s} {x['chain'] or '??':10s} node={x['node']} seq={x['seq']} stock={x['stock']} x={x['x']} y={x['y']} df={x['df']} p2x={x['p2x']}{tag}")
    off = sum(1 for v in frames.values() if v[2] == "OFF-GRAPH")
    print(f"\nframes sampled {len(frames)}, off-graph transitions {off}")
    if out_json:
        Path(out_json).write_text(json.dumps({"idle": idle, "baseline": sorted(x for x in base if x), "events": report}, indent=1))


BASELINE = {("a", i) for i in range(0x11)}   # idle/walk/crouch/jump family — never a move


def expect(sched_path, trace_path, chains_dir):
    """One line per event: `<part>\t<event>\t<chain chain ...>` — the non-baseline
    chains ENTERED (jump / jump-mid) in the event's window, deduplicated in
    order. This is what tests/test_move_naming.sh freezes."""
    sched = json.load(open(sched_path))
    node2chain, starts, edges = load_graph(chains_dir)
    rows = []
    for line in open(trace_path):
        f = line.split()
        if len(f) < 3 or f[0] != "F":
            continue
        d = dict(kv.split("=") for kv in f[2:])
        rows.append((int(f[1]), int(d["node"])))
    ent = {}
    prev = None
    for fr, node in rows:
        if prev is not None and node != prev and node not in edges.get(prev, ()):
            key = node2chain.get(node)
            ent[fr] = key if key else ("OFF", node)
        prev = node
    out = []
    for e in sched["events"]:
        seen = []
        for fr in range(e["frame"], e["frame"] + e["gap"]):
            k = ent.get(fr)
            if k and (e.get("movement") or k not in BASELINE) and k not in seen:
                seen.append(k)
        out.append(f"{sched['part']}\t{e['name']}\t" + " ".join(f"{t}:0x{q:02x}" if t != "OFF" else f"OFF:{q:#x}" for t, q in seen))
    return out


def main():
    ap = argparse.ArgumentParser()
    sub = ap.add_subparsers(dest="cmd", required=True)
    g = sub.add_parser("gen"); g.add_argument("tenant"); g.add_argument("part"); g.add_argument("out_rpl"); g.add_argument("out_sched")
    a = sub.add_parser("analyse"); a.add_argument("sched"); a.add_argument("trace"); a.add_argument("chains"); a.add_argument("--json"); a.add_argument("--window", type=int)
    x = sub.add_parser("expect"); x.add_argument("sched"); x.add_argument("trace"); x.add_argument("chains")
    args = ap.parse_args()
    if args.cmd == "gen":
        gen(args.tenant, args.part, args.out_rpl, args.out_sched)
    elif args.cmd == "expect":
        print("\n".join(expect(args.sched, args.trace, args.chains)))
    else:
        analyse(args.sched, args.trace, args.chains, args.json, args.window)


if __name__ == "__main__":
    main()
