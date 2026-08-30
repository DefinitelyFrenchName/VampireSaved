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
# The native game is vsav2 for all three; Donovan is the default cursor's
# R,R pick, the other two are FORCED by the early-window poke ([VSP-120]:
# 1400-1500 only, the idiom of audit_clone_beam_lines.sh). The chains are
# decoded from each tenant's vs2 extract (the solo build dir).
TENANTS = {"donovan": {"id": None, "build": "build/don_m18"},
           # PHASE 3 (reactions): the tenant on the VICTIM side (P2) — P1 is Victor (0x03), both by the early-window pokes
           "donovan_victim": {"id": "03", "id_p2": "13", "build": "build/don_m18"},
           "huitzil_victim": {"id": "03", "id_p2": "10", "build": "build/hui52"},
           "pyron_victim":   {"id": "03", "id_p2": "11", "build": "build/pyron36"},
           "huitzil": {"id": "10", "build": "build/hui52"},
           "pyron":   {"id": "11", "build": "build/pyron36"}}
# P2 HP re-pin (both words, [VSP-125]) so a projectile-fed Victor never dies.
HP_PIN_EVERY = 400

# ---------------------------------------------------------------- recipes
# A recipe is a list of (start_offset, end_offset, tokens[, who]) relative to
# the event frame; tokens in replay.lua grammar (U D L R 1-6), who = p1
# (default) or p2 (the idle Victor, scripted only for an air throw's jump
# and the guard-cancel setup). P1 faces RIGHT.
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


def air_throw(b):   # both jump from contact; P1 presses toward+button at the apex
    return [(0, 2, "U"), (0, 2, "U", "p2"), (14, 17, "R" + B[b])]
def hold_pair(motion, pair, hold):  # an EX whose pair is HELD then released
    r = motion("LP")[:-1]; a, bb, _ = motion("LP")[-1]
    return r + [(a, a + hold, pair)]
def rushing_punch():  # while dashing, 6+P
    return [(0, 1, "R"), (4, 5, "R"), (9, 12, "R1")]
def guard_cancel(b, hit_at):
    # P2 (Victor, at contact) presses HP; P1 blocks (holds back through the
    # hit) then inputs 623+b inside blockstun. hit_at = frames from P2's press
    # to the block, tried at several values by separate events.
    return [(0, 3, "3", "p2"), (-4, hit_at + 4, "L"), (hit_at + 5, hit_at + 7, "R"), (hit_at + 8, hit_at + 10, "D"), (hit_at + 11, hit_at + 14, "DR" + B[b])]


def air_qcb_late(b):  # the motion at the apex (Pyron's high jump)
    return [(0, 2, "U"), (18, 20, "D"), (21, 23, "DL"), (24, 30, "L"), (26, 30, B[b])]
def rdp_slow(b):      # 421 with longer holds, button on the DL
    return [(0, 4, "L"), (6, 10, "D"), (12, 18, "DL"), (14, 18, B[b])]
def rdp_end_d(b):     # 4 2 1 then the button on a final D (some trackers want 4-2-1-2)
    return [(0, 2, "L"), (4, 6, "D"), (8, 10, "DL"), (12, 16, "D"), (13, 16, B[b])]
def gc_fast(b, at):   # guard cancel: P2 HP at 0; P1 holds back through the block, then a 6-frame 623+b at `at`
    return [(0, 3, "3", "p2"), (-4, at + 1, "L"), (at, at + 1, "R"), (at + 2, at + 3, "D"), (at + 4, at + 7, "DR" + B[b])]


def hcb_cont(b):      # 63214 with no release between R and DR (a release re-reads as a dash tap)
    return [(0, 2, "R"), (2, 4, "DR"), (4, 6, "D"), (6, 8, "DL"), (8, 14, "L"), (10, 14, B[b])]
def charge_du(b):     # charge D then U+button
    return [(0, 60, "D"), (61, 64, "U" + B[b])]
def charge_bf(b):     # charge back then F+button
    return [(0, 60, "L"), (61, 64, "R" + B[b])]
def gc_v(b, l_end, at):  # guard cancel variant: back held until l_end, 623+b from `at`
    return [(0, 3, "3", "p2"), (-4, l_end, "L"), (at, at + 1, "R"), (at + 2, at + 3, "D"), (at + 4, at + 7, "DR" + B[b])]


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
        ("Killshread Summon (ES)", qcb("KK"), 240),  # NOT a TOML row since 14z-121 (no ES, maintainer-confirmed): kept as the measured negative control — enters 0x47, no stock
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
        ("5LP (swordless)", stand("LP"), 120), ("5MP (swordless)", stand("MP"), 120), ("5HP (swordless)", stand("HP"), 150),
        ("5LK (swordless)", stand("LK"), 120), ("5MK (swordless)", stand("MK"), 120), ("5HK (swordless)", stand("HK"), 150),
        ("2LP swordless", crouch("LP"), 120), ("2MP (swordless)", crouch("MP"), 120), ("2HP (swordless)", crouch("HP"), 150),
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
    "9": [  # PHASE 2 hit rig (no pokes: the -debug write tap cannot poke): walk to contact, then normals that CONNECT; a projectile at range
        ("walk-in", walk_in(60), 90),
        ("5LP hit", stand("LP"), 150), ("5MP hit", stand("MP"), 150), ("5HP hit", stand("HP"), 200),
        ("2MK hit", crouch("MK"), 150), ("2HK hit", crouch("HK"), 300),
        ("walk-in", walk_in(60), 90),
        ("j.HP hit", jump("HP"), 200),
        ("Walk back", [(0, 90, "L")], 120),
        ("Blizzard Sword [LP] hit", hcf("LP"), 300),
        ("walk-in", walk_in(80), 100),
        ("5MP whiff-to-hit ladder 0", stand("MP"), 120), ("step", walk_in(4), 40), ("5MP ladder 1", stand("MP"), 120),
        ("step", walk_in(4), 40), ("5MP ladder 2", stand("MP"), 120), ("step", walk_in(4), 40), ("5MP ladder 3", stand("MP"), 120),
        ("step", walk_in(4), 40), ("5MP ladder 4", stand("MP"), 120), ("step", walk_in(4), 40), ("5MP ladder 5", stand("MP"), 120),
    ],
    "10": [  # PHASE 2 projectile / multi-hit rig (no pokes): the object-hit applier's path
        ("Blizzard Sword [LP] at range", hcf("LP"), 300), ("Blizzard Sword [MP] at range", hcf("MP"), 300), ("Blizzard Sword [HP] at range", hcf("HP"), 300),
        ("walk-in", walk_in(60), 90),
        ("Lightning Sword [LP] hit", rdp("LP"), 300),
        ("walk-in", walk_in(30), 60),
        ("Ifrit Sword [LP] hit", dp("LP"), 300),
        ("walk-in", walk_in(30), 60),
        ("Killshread [LK] plant on P2", qcb("LK"), 300),
        ("Killshread Lightning [LP] column", qcb("LP"), 300),
    ],
    "11": [  # PHASE 2 (2): the same contacts BLOCKED — P2 holds back the whole part
        ("P2 blocks", [(0, 3000, "R", "p2")], 0),   # P2 faces LEFT: away = R
        ("walk-in", walk_in(60), 90),
        ("5LP blocked", stand("LP"), 150), ("5MP blocked", stand("MP"), 150), ("5HP blocked", stand("HP"), 200),
        ("2MK blocked", crouch("MK"), 150), ("2HK blocked", crouch("HK"), 300),
        ("walk-in", walk_in(60), 90),
        ("Lightning Sword [LP] blocked", rdp("LP"), 300),
        ("walk-in", walk_in(30), 60),
        ("Ifrit Sword [LP] blocked", dp("LP"), 300),
        ("Walk back", [(0, 90, "L")], 120),
        ("Blizzard Sword [LP] blocked", hcf("LP"), 300),
    ],
    "12": [  # KILLSHREAD (ES) — the maintainer's ruling 14z-121: the ES plant's effect plays DURING THE SUMMON (the sword
             # attacks going away AND coming back; the plain summon one way). P2 (Victor, idle) pinned in the sword's path.
        ("Killshread [214LK] plant", qcb("LK"), 260, "far"),
        ("Killshread Summon [214LK] after plain", qcb("LK"), 320, "far"),
        ("Killshread (ES) plant", qcb("KK"), 260, "far"),
        ("Killshread Summon [214LK] after ES", qcb("LK"), 320, "far"),
        ("Killshread [214HK] plant", qcb("HK"), 260, "far"),
        ("Killshread Summon [214HK] after plain", qcb("HK"), 320, "far"),
        ("Killshread (ES) plant (2)", qcb("KK"), 260, "far"),
        ("Killshread Summon [214HK] after ES", qcb("HK"), 320, "far"),
    ],
}
NORMALS = [(n, f, g) for n, f, g in (
    ("5LP", stand("LP"), 120), ("5MP", stand("MP"), 120), ("5HP", stand("HP"), 150),
    ("5LK", stand("LK"), 120), ("5MK", stand("MK"), 120), ("5HK", stand("HK"), 150),
    ("2LP", crouch("LP"), 120), ("2MP", crouch("MP"), 120), ("2HP", crouch("HP"), 150),
    ("2LK", crouch("LK"), 120), ("2MK", crouch("MK"), 120), ("2HK", crouch("HK"), 150),
    ("j.LP", jump("LP"), 150), ("j.MP", jump("MP"), 150), ("j.HP", jump("HP"), 150),
    ("j.LK", jump("LK"), 150), ("j.MK", jump("MK"), 150), ("j.HK", jump("HK"), 150))]
MOVEMENT = [
    ("Walk forward", walk_in(40), 120), ("Walk back", [(0, 40, "L")], 120), ("Crouch", [(0, 30, "D")], 120),
    ("Jump [8]", [(0, 2, "U")], 120), ("Jump [9]", [(0, 2, "UR")], 120), ("Jump [7]", [(0, 2, "UL")], 120),
    ("Forward dash", dash_f(), 150), ("Back dash", dash_b(), 150)]

PYRON = {
    "1": [(n, r, g, "far") for n, r, g in MOVEMENT + NORMALS] + [
        ("Rushing Punch", rushing_punch(), 200, "far"),
        ("Diving Punch [j.2LP]", air_down("LP"), 150, "far"), ("Diving Punch [j.2MP]", air_down("MP"), 150, "far"), ("Diving Punch [j.2HP]", air_down("HP"), 150, "far"),
    ],
    "2": [
        ("Sol Smasher [LP]", qcf("LP"), 200, "far"), ("Sol Smasher [MP]", qcf("MP"), 200, "far"), ("Sol Smasher [HP]", qcf("HP"), 200, "far"),
        ("Sol Smasher [j.236LP]", air_qcf("LP"), 200, "far"), ("Sol Smasher [j.236HP]", air_qcf("HP"), 200, "far"),
        ("Zodiac Fire [LP]", dp("LP"), 200, "far"), ("Zodiac Fire [MP]", dp("MP"), 200, "far"), ("Zodiac Fire [HP]", dp("HP"), 200, "far"),
        ("Orbital Blaze [j.214LK]", air_qcb_fast("LK"), 200, "far"), ("Orbital Blaze [j.214MK]", air_qcb_fast("MK"), 200, "far"), ("Orbital Blaze [j.214HK]", air_qcb_fast("HK"), 200, "far"),
        ("Orbital Blaze [j.214LK] late", air_qcb_late("LK"), 200, "far"), ("Orbital Blaze [j.214HK] late", air_qcb_late("HK"), 200, "far"),
        ("Galaxy Trip [421LP]", rdp("LP"), 200, "far"), ("Galaxy Trip [421MP]", rdp("MP"), 200, "far"), ("Galaxy Trip [421HP]", rdp("HP"), 200, "far"),
        ("Galaxy Trip [421LK]", rdp("LK"), 200, "far"), ("Galaxy Trip [421MK]", rdp("MK"), 200, "far"), ("Galaxy Trip [421HK]", rdp("HK"), 200, "far"),
        ("Galaxy Trip [421LK] slow", rdp_slow("LK"), 200, "far"), ("Galaxy Trip [421HK] slow", rdp_slow("HK"), 200, "far"),
        ("Galaxy Trip [j.421LP]", air_rdp("LP"), 200, "far"), ("Galaxy Trip [j.421MP]", air_rdp("MP"), 200, "far"), ("Galaxy Trip [j.421HP]", air_rdp("HP"), 200, "far"),
        ("Galaxy Trip [j.421LK]", air_rdp("LK"), 200, "far"), ("Galaxy Trip [j.421MK]", air_rdp("MK"), 200, "far"), ("Galaxy Trip [j.421HK]", air_rdp("HK"), 200, "far"),
    ],
    "3": [
        ("Corona Whip [6MP]", throw_fwd("MP"), 260, "near"), ("Corona Whip [6HP]", throw_fwd("HP"), 260, "near"),
        ("Corona Whip [4MP]", [(0, 3, "L2")], 260, "near"),
        ("Planet Burning [MP]", hcb("MP"), 300, "near"), ("Planet Burning [HP]", hcb("HP"), 300, "near"),
        ("Planet Burning [MP] far (whiff)", hcb("MP"), 260, "far"),
        ("Galactic Throw [j.6MP]", air_throw("MP"), 220, "near"), ("Galactic Throw [j.6HP]", air_throw("HP"), 220, "near"),
        ("Sitting Attack [8P] off throw", throw_then_pursuit("LP"), 320, "near"),
        ("Sitting Attack [8K] off throw", throw_then_pursuit("LK"), 320, "near"),
    ],
    "4": [  # meter
        ("Sol Smasher (ES)", qcf("PP"), 220, "far"), ("Sol Smasher (ES) [air]", air_qcf("PP"), 220, "far"),
        ("Zodiac Fire (ES)", dp("PP"), 220, "far"),
        ("Orbital Blaze (ES)", air_qcb_fast("KK"), 220, "far"), ("Orbital Blaze (ES) late", air_qcb_late("KK"), 220, "far"),
        ("Cosmo Disruption [PP held]", hold_pair(hcf, "13", 40), 400, "far"),
        ("Cosmo Disruption [KK held]", hold_pair(hcf, "46", 40), 400, "far"),
        ("Cosmo Disruption [PP tap]", hcf("PP"), 400, "far"),
        ("Piled Hell [623KK]", dp("KK"), 300, "far"), ("Piled Hell [j.623KK]", air_dp("KK"), 300, "far"),
        ("Planet Burning (ES)", hcb("PP"), 300, "near"),
        ("Sitting Attack (ES) [8PP] off throw", throw_then_pursuit("PP"), 320, "near"),
        ("Shining Gemini [LP+LK]", pair("14"), 200, "far"),
        ("5LP in DF", stand("LP"), 200, "far"), ("Sol Smasher [LP] in DF", qcf("LP"), 300, "far"),
    ],
    "5": [  # the maintainer's challenge (14z-120): ES Planet Burning by 63214 + MP&HP up close; does Cosmo's tracker discriminate 41236 from 63214?
        ("Planet Burning [MP] step back (control)", [(0, 2, "L"), (30, 32, "R"), (32, 34, "DR"), (34, 36, "D"), (36, 38, "DL"), (38, 44, "L"), (40, 44, "2")], 320, "near"),
        ("Planet Burning (ES) [63214 MP+HP] step back", [(0, 2, "L"), (30, 32, "R"), (32, 34, "DR"), (34, 36, "D"), (36, 38, "DL"), (38, 44, "L"), (40, 44, "23")], 320, "near"),
        ("Planet Burning (ES) [63214 LP+HP] step back", [(0, 2, "L"), (30, 32, "R"), (32, 34, "DR"), (34, 36, "D"), (36, 38, "DL"), (38, 44, "L"), (40, 44, "13")], 320, "near"),
        ("Planet Burning (ES) [63214 LP+MP] step back", [(0, 2, "L"), (30, 32, "R"), (32, 34, "DR"), (34, 36, "D"), (36, 38, "DL"), (38, 44, "L"), (40, 44, "12")], 320, "near"),
        ("Planet Burning (ES) [63214 MP+HP] slow, step back", [(0, 2, "L"), (30, 34, "R"), (34, 38, "DR"), (38, 42, "D"), (42, 46, "DL"), (46, 54, "L"), (49, 54, "23")], 320, "near"),
        ("Planet Burning (ES) [63214 MP+HP] pair AFTER the motion", [(0, 2, "L"), (30, 32, "R"), (32, 34, "DR"), (34, 36, "D"), (36, 38, "DL"), (38, 42, "L"), (43, 46, "23")], 320, "near"),
        ("Cosmo Disruption [41236 PP] far", hcf("PP"), 400, "far"),
        ("Cosmo Disruption [63214 PP] far, no dash", [(0, 2, "L"), (30, 32, "R"), (32, 34, "DR"), (34, 36, "D"), (36, 38, "DL"), (38, 44, "L"), (40, 44, "13")], 400, "far"),
        ("Cosmo Disruption [63214 MP+HP] far, no dash", [(0, 2, "L"), (30, 32, "R"), (32, 34, "DR"), (34, 36, "D"), (36, 38, "DL"), (38, 44, "L"), (40, 44, "23")], 400, "far"),
        ("Cosmo Disruption [41236 MP+HP] far", hcf("MP")[:-1] + [(18, 22, "23")], 400, "far"),
    ],
}
HUITZIL = {
    "1": [(n, r, g, "far") for n, r, g in MOVEMENT + NORMALS] + [
        ("6LP", fwd("LP"), 150, "far"), ("6MP", fwd("MP"), 150, "far"), ("6HP", fwd("HP"), 150, "far"),
        ("6LK", fwd("LK"), 150, "far"), ("6MK", fwd("MK"), 150, "far"), ("6HK", fwd("HK"), 150, "far"),
        ("Air Dash [j.66] early", [(0, 2, "U"), (8, 9, "R"), (12, 13, "R")], 200, "far"),
        ("Air Dash [j.66] mid", [(0, 2, "U"), (14, 15, "R"), (18, 19, "R")], 200, "far"),
        ("Air Dash [j.66] apex", [(0, 2, "U"), (24, 25, "R"), (28, 29, "R")], 200, "far"),
        ("Air Dash [j.44] mid", [(0, 2, "U"), (14, 15, "L"), (18, 19, "L")], 200, "far"),
        ("Air Dash [j.66] fwd jump", [(0, 2, "UR"), (14, 15, "R"), (18, 19, "R")], 200, "far"),
        ("Float [j.8 hold]", [(0, 2, "U"), (10, 90, "U")], 250, "far"),
        ("Float [j.8 re-press]", [(0, 2, "U"), (20, 80, "U")], 250, "far"),
        ("Float [j.9 hold]", [(0, 2, "UR"), (8, 80, "UR")], 250, "far"),
        ("Float [j.7 hold at apex]", [(0, 2, "U"), (28, 90, "UL")], 250, "far"),
    ],
    "2": [
        ("Plasma Beam [LP]", qcf("LP"), 220, "far"), ("Plasma Beam [MP]", qcf("MP"), 220, "far"), ("Plasma Beam [HP]", qcf("HP"), 220, "far"),
        ("Plasma Beam [LK]", qcf("LK"), 220, "far"), ("Plasma Beam [MK]", qcf("MK"), 220, "far"), ("Plasma Beam [HK]", qcf("HK"), 220, "far"),
        ("Mighty Launcher [LP]", qcb("LP"), 220, "far"), ("Mighty Launcher [MP]", qcb("MP"), 220, "far"), ("Mighty Launcher [HP]", qcb("HP"), 220, "far"),
        ("Mighty Launcher [j.214LP]", air_qcb_fast("LP"), 220, "far"), ("Mighty Launcher [j.214HP]", air_qcb_fast("HP"), 220, "far"),
        ("Genocide Vulcan [LK]", rdp("LK"), 220, "far"), ("Genocide Vulcan [MK]", rdp("MK"), 220, "far"), ("Genocide Vulcan [HK]", rdp("HK"), 220, "far"),
        ("Genocide Vulcan [LK] slow", rdp_slow("LK"), 220, "far"), ("Genocide Vulcan [LK] end-D", rdp_end_d("LK"), 220, "far"),
        ("Genocide Vulcan [LK] near", rdp("LK"), 220, "near"),
        ("Plasma Trap [j.214LK]", air_qcb_fast("LK"), 220, "far"), ("Plasma Trap [j.214MK]", air_qcb_fast("MK"), 220, "far"), ("Plasma Trap [j.214HK]", air_qcb_fast("HK"), 220, "far"),
        ("Plasma Trap [j.214HK] late", air_qcb_late("HK"), 220, "far"),
    ],
    "3": [
        ("Magnet Slam [6MP]", throw_fwd("MP"), 260, "near"), ("Magnet Slam [6HP]", throw_fwd("HP"), 260, "near"),
        ("Magnet Slam [4MP]", [(0, 3, "L2")], 260, "near"),
        ("Circuit Scrapper [MP]", hcb("MP"), 300, "near"), ("Circuit Scrapper [HP]", hcb("HP"), 300, "near"),
        ("Circuit Scrapper [MP] far (whiff)", hcb("MP"), 260, "far"),
        ("Sky Capture [j.6MP]", air_throw("MP"), 220, "near"), ("Sky Capture [j.6HP]", air_throw("HP"), 220, "near"),
        ("Sitting Attack [8P] off throw", throw_then_pursuit("LP"), 320, "near"),
        ("Sitting Attack [8K] off throw", throw_then_pursuit("LK"), 320, "near"),
    ],
    "4": [  # meter
        ("Plasma Beam (ES) [PP]", qcf("PP"), 240, "far"), ("Plasma Beam (ES) [KK]", qcf("KK"), 240, "far"),
        ("Mighty Launcher (ES)", qcb("PP"), 240, "far"), ("Mighty Launcher (ES) [air]", air_qcb_fast("PP"), 240, "far"),
        ("Genocide Vulcan (ES)", rdp("KK"), 240, "far"),
        ("Plasma Trap (ES)", air_qcb_fast("KK"), 240, "far"),
        ("Final Guardian Beta", dp("KK"), 320, "far"),
        ("Erasing Sphere [KK held]", hold_pair(rdp, "46", 40), 400, "far"), ("Erasing Sphere [KK tap]", rdp("KK"), 400, "far"),
        ("Circuit Scrapper (ES)", hcb("PP"), 300, "near"),
        ("Sitting Attack (ES) [8PP] off throw", throw_then_pursuit("PP"), 320, "near"),
        ("Ray of Doom [LP+LK]", pair("14"), 200, "far"),
        ("5LP in DF", stand("LP"), 200, "far"), ("Plasma Beam [LP] in DF", qcf("LP"), 300, "far"),
    ],
    "5": [  # Reflect Wall = the guard cancel: P2 Victor HP at contact, P1 blocks then 623+button inside blockstun
        ("Reflect Wall [gc LP at hit+2]", gc_fast("LP", 12), 220, "near"),
        ("Reflect Wall [gc LP at hit+6]", gc_fast("LP", 16), 220, "near"),
        ("Reflect Wall [gc LP at hit+10]", gc_fast("LP", 20), 220, "near"),
        ("Reflect Wall [gc LP at hit+14]", gc_fast("LP", 24), 220, "near"),
        ("Reflect Wall [gc HP at hit+6]", gc_fast("HP", 16), 220, "near"),
        ("Reflect Wall [gc LK at hit+6]", gc_fast("LK", 16), 220, "near"),
        ("Reflect Wall [gc HK at hit+6]", gc_fast("HK", 16), 220, "near"),
        ("Reflect Wall [gc PP at hit+6]", gc_fast("PP", 16), 220, "near"),
        ("Reflect Wall [gc LP at hit+6] (control: no block)", [(0, 3, "3", "p2"), (16, 17, "R"), (18, 19, "D"), (20, 23, "DR1")], 220, "near"),
    ],
    "6": [  # the three holes: Genocide Vulcan's input, the grapple without a dash tap, guard-cancel variants
        ("Circuit Scrapper [MP] cont", hcb_cont("MP"), 300, "near"), ("Circuit Scrapper [HP] cont", hcb_cont("HP"), 300, "near"),
        ("Circuit Scrapper (ES) cont", hcb_cont("PP"), 300, "near"),
        ("Genocide Vulcan [214LK ground]", qcb("LK"), 220, "far"), ("Genocide Vulcan [623LK]", dp("LK"), 220, "far"),
        ("Genocide Vulcan [41236LK]", hcf("LK"), 220, "far"), ("Genocide Vulcan [63214LK]", hcb_cont("LK"), 220, "far"),
        ("Genocide Vulcan [charge 2-8 LK]", charge_du("LK"), 220, "far"), ("Genocide Vulcan [charge 4-6 LK]", charge_bf("LK"), 220, "far"),
        ("Genocide Vulcan [22LK]", [(0, 2, "D"), (4, 6, "D"), (5, 8, "4")], 220, "far"),
        ("Genocide Vulcan [421LK near, slow]", rdp_slow("LK"), 220, "near"),
        ("Genocide Vulcan [421LK air]", air_rdp("LK"), 220, "far"),
        ("Reflect Wall [gc v: L to hit+1, 623LP at hit+2]", gc_v("LP", 11, 12), 220, "near"),
        ("Reflect Wall [gc v: L to hit+1, 623LP at hit+6]", gc_v("LP", 11, 16), 220, "near"),
        ("Reflect Wall [gc v: L to hit+1, 623HP at hit+2]", gc_v("HP", 11, 12), 220, "near"),
        ("Reflect Wall [gc v: L to hit+1, 623LK at hit+2]", gc_v("LK", 11, 12), 220, "near"),
        ("Reflect Wall [gc v: 623 buffered pre-hit, LP at hit+2]", [(0, 3, "3", "p2"), (-4, 4, "L"), (5, 6, "R"), (7, 8, "D"), (9, 10, "DR"), (12, 15, "1")], 220, "near"),
        ("Reflect Wall [gc v: P2 HK, L to hit+1, 623LP at hit+4]", [(0, 3, "6", "p2"), (-4, 13, "L"), (14, 15, "R"), (16, 17, "D"), (18, 21, "DR1")], 220, "near"),
        ("Reflect Wall [gc v: P2 HK, 623LP at hit+10]", [(0, 3, "6", "p2"), (-4, 13, "L"), (20, 21, "R"), (22, 23, "D"), (24, 27, "DR1")], 220, "near"),
    ],
    "7": [  # the guard cancel by button; the plain grapple with a later button; Vulcan with punches / vs an airborne P2
        ("Reflect Wall [gc LP]", gc_v("LP", 11, 12), 240, "near"), ("Reflect Wall [gc MP]", gc_v("MP", 11, 12), 240, "near"),
        ("Reflect Wall [gc HP]", gc_v("HP", 11, 12), 240, "near"), ("Reflect Wall [gc LK]", gc_v("LK", 11, 12), 240, "near"),
        ("Reflect Wall [gc MK]", gc_v("MK", 11, 12), 240, "near"), ("Reflect Wall [gc HK]", gc_v("HK", 11, 12), 240, "near"),
        ("Reflect Wall [gc PP]", gc_v("PP", 11, 12), 240, "near"),
        ("Reflect Wall [623LP neutral]", dp("LP"), 220, "far"),
        ("Circuit Scrapper [MP] late button", [(0, 2, "R"), (2, 4, "DR"), (4, 6, "D"), (6, 8, "DL"), (8, 18, "L"), (14, 18, "2")], 300, "near"),
        ("Circuit Scrapper [HP] late button", [(0, 2, "R"), (2, 4, "DR"), (4, 6, "D"), (6, 8, "DL"), (8, 18, "L"), (14, 18, "3")], 300, "near"),
        ("Circuit Scrapper [MP] motion then button", [(0, 2, "R"), (2, 4, "DR"), (4, 6, "D"), (6, 8, "DL"), (8, 12, "L"), (13, 16, "2")], 300, "near"),
        ("Genocide Vulcan [421LP]", rdp("LP"), 220, "far"), ("Genocide Vulcan [421MP]", rdp("MP"), 220, "far"), ("Genocide Vulcan [421HP]", rdp("HP"), 220, "far"),
        ("Genocide Vulcan [421LK vs airborne P2]", [(0, 2, "U", "p2")] + [(a + 10, b + 10, t) for a, b, t in rdp("LK")], 220, "far"),
        ("Genocide Vulcan [421HK vs airborne P2]", [(0, 2, "U", "p2")] + [(a + 10, b + 10, t) for a, b, t in rdp("HK")], 220, "far"),
        ("Genocide Vulcan [421KK vs airborne P2]", [(0, 2, "U", "p2")] + [(a + 10, b + 10, t) for a, b, t in rdp("KK")], 220, "far"),
        ("Genocide Vulcan [421LK near vs airborne P2]", [(0, 2, "U", "p2")] + [(a + 10, b + 10, t) for a, b, t in rdp("LK")], 220, "near"),
    ],
    "8": [  # Vulcan's ES (421PP), the grapple with pairs and at a step more distance, the GC's stock cost with meter
        ("Genocide Vulcan (ES) [421PP]", rdp("PP"), 260, "far"),
        ("Genocide Vulcan [421LP] (2)", rdp("LP"), 260, "far"),
        ("Circuit Scrapper [63214 MP+HP]", [(0, 2, "R"), (2, 4, "DR"), (4, 6, "D"), (6, 8, "DL"), (8, 14, "L"), (10, 14, "23")], 300, "near"),
        ("Circuit Scrapper [63214 LP+MP]", [(0, 2, "R"), (2, 4, "DR"), (4, 6, "D"), (6, 8, "DL"), (8, 14, "L"), (10, 14, "12")], 300, "near"),
        ("Circuit Scrapper [63214 LP+HP] (ES, meter)", hcb_cont("PP"), 300, "near"),
        ("Circuit Scrapper [63214MP] step back", [(0, 2, "L"), (30, 32, "R"), (32, 34, "DR"), (34, 36, "D"), (36, 38, "DL"), (38, 44, "L"), (40, 44, "2")], 300, "near"),
        ("Circuit Scrapper [63214MP] no-pin walk", [(0, 60, "R"), (90, 92, "R"), (92, 94, "DR"), (94, 96, "D"), (96, 98, "DL"), (98, 104, "L"), (100, 104, "2")], 300, "far"),
        ("Reflect Wall [gc MP] (meter)", gc_v("MP", 11, 12), 240, "near"),
        ("Reflect Wall [gc HP] (meter)", gc_v("HP", 11, 12), 240, "near"),
    ],
}
DONOVAN_VICTIM = {   # P1 = Victor attacks P2 = Donovan; every contact class the naming rigs reached, plus the knockdowns
    "1": [  # HITS (P2 idle)
        ("walk-in", walk_in(70), 90),
        ("V 5LP", stand("LP"), 160), ("V 5MP", stand("MP"), 160), ("V 5HP", stand("HP"), 220),
        ("V 2LK", crouch("LK"), 160), ("V 2MK", crouch("MK"), 160), ("V 2HK sweep", crouch("HK"), 320),
        ("walk-in", walk_in(60), 80),
        ("V j.HP", jump("HP"), 220),
        ("walk-in", walk_in(40), 60),
        ("V 6MP throw", throw_fwd("MP"), 320),
        ("walk-in", walk_in(80), 100),
        ("V 623LP (DP)", dp("LP"), 260),
        ("walk-in", walk_in(60), 80),
        ("V 236LP", qcf("LP"), 260),
    ],
    "2": [  # BLOCKED (P2 holds away = R, since P2 faces left) — the walk-ins are longer because P2 retreats
        ("P2 blocks", [(0, 3200, "R", "p2")], 0),
        ("walk-in", walk_in(90), 100),
        ("V 5LP", stand("LP"), 150), ("walk-in", walk_in(30), 40), ("V 5MP", stand("MP"), 150), ("walk-in", walk_in(30), 40), ("V 5HP", stand("HP"), 200),
        ("walk-in", walk_in(30), 40), ("V 2MK", crouch("MK"), 150), ("walk-in", walk_in(30), 40), ("V 2HK", crouch("HK"), 250),
        ("walk-in", walk_in(40), 50), ("V 623LP (DP)", dp("LP"), 260),
        ("walk-in", walk_in(40), 50), ("V j.HP", jump("HP"), 220),
    ],
    "3": [  # AIR HITS: P2 scripted to jump, P1 anti-airs
        ("walk-in", walk_in(60), 80),
        ("V 5HP vs jumping P2", [(0, 2, "U", "p2"), (12, 14, "3")], 260),
        ("V 623LP vs jumping P2", [(0, 2, "U", "p2")] + [(a + 6, b + 6, t) for a, b, t in dp("LP")], 300),
        ("V 2HK vs landing P2", [(0, 2, "U", "p2"), (30, 33, "D6")], 300),
    ],
}
SCHEDULES = {"donovan": DONOVAN, "pyron": PYRON, "huitzil": HUITZIL,
             "donovan_victim": DONOVAN_VICTIM, "huitzil_victim": DONOVAN_VICTIM, "pyron_victim": DONOVAN_VICTIM}
NO_POKE_PARTS = {("donovan", "9"), ("donovan", "10"), ("donovan", "11")}   # parts the -debug write tap must be able to replay: no HP pin, no stock poke
PHASE2_PARTS = NO_POKE_PARTS | {("donovan", "12")}   # the hitbox rigs (tests/test_hitbox_encoding.sh) and the Killshread (ES) rig (tests/test_killshread_es.sh) — NOT naming parts: test_move_naming.sh skips them
# stock pokes for the meter parts: frame -> 9 stocks (each ES/EX/DF spends 1)
METER_PARTS = {"donovan": {"3", "4", "5", "6", "7", "8", "12"}, "pyron": {"4", "5"}, "huitzil": {"4", "5", "6", "7", "8"}, "donovan_victim": set(), "huitzil_victim": set(), "pyron_victim": set()}


# Per-event POSITION PINS (the 14z-120 fix for the Pyron/Huitzil first pass):
# after a throw P2 may land BEHIND P1, P1 turns, and every motion mirrors
# (623 <-> 421, 41236 <-> 63214) — half the first pass measured the mirror
# move. A schedule entry may carry a 4th field "far" / "near": 40 frames
# before the event both fighters' X (+0x10.w) are poked — far = the natural
# round-start spacing, near = pushbox contact — so P1 always faces RIGHT
# and no walk-in (whose trailing R + the motion's R made a DASH) is needed.
PIN = {"far": (552, 728)}
# "near" is NOT a poked pair: 880/925 and then 861/925 both OVERLAPPED the
# pushboxes (Pyron's is wide) and the engine resolved the overlap by
# CROSSING the fighters five frames later — P1 faced LEFT for whole parts
# (14z-120 (2)). A near event is the far pin, a 150-frame walk-in to pushbox
# contact, then a 40-frame pause (past the dash-tap window) before the input.
# The facing byte +0x0B (flip_x: 1 = P1 faces RIGHT) is sampled and `expect`
# marks an event whose P1 faces left at its frame, so a flipped rig can
# never freeze silently.


def gen(tenant, part, out_rpl, out_sched):
    ev = SCHEDULES[tenant][part]
    lines = [f"# naming rig — {tenant} part {part} (tools/name_moves.py gen; DO NOT hand-edit,",
             "# regenerate). Native-game select prologue from replay 17; events from the",
             "# schedule in the tool. Analyse with: name_moves.py analyse <schedule.json>.",
             PROLOGUE.rstrip()]
    sched = {"tenant": tenant, "part": part, "events": [], "pokes": []}
    t = FIRST_EVENT
    tid = TENANTS[tenant]["id"]
    pin_pokes = []
    for e in ev:
        name, recipe, gap = e[:3]
        if len(e) > 3 and e[3] == "near":
            gap = max(gap, 420)   # the NEXT event's pin lands 230 f later; a throw here must be over by then
        if len(e) > 3:
            x1, x2 = PIN["far"]
            if e[3] == "near":
                pin_pokes += [f"{t - 230}:ff8410:{x1:04x}", f"{t - 230}:ff8810:{x2:04x}"]
                lines.append(f"{t - 190}-{t - 40} p1=R")
            else:
                pin_pokes += [f"{t - 40}:ff8410:{x1:04x}", f"{t - 40}:ff8810:{x2:04x}"]
        for r in recipe:
            a, b, tok = r[:3]; who = r[3] if len(r) > 3 else "p1"
            lines.append(f"{t + a}-{t + b} {who}={tok}")
        # a MOVEMENT event (no button in its recipe) is measured by the baseline
        # family itself (idle/walk/crouch/jump), which other events filter out
        movement = not any(ch.isdigit() for r in recipe for ch in r[2])
        sched["events"].append({"name": name, "frame": t, "gap": gap, "movement": movement})
        t += gap
    end = t + 200
    lines.append(f"{end} wait")
    # pokes: P2 HP pin every HP_PIN_EVERY frames from the first event; stocks
    pokes = [] if (tenant, part) in NO_POKE_PARTS else [f"{f}:ff8850:01200120" for f in range(FIRST_EVENT - 50, end, HP_PIN_EVERY)]
    if tid:
        pokes = [f"{f}:ff8782:{tid}" for f in (1400, 1450, 1500)] + pokes
    if TENANTS[tenant].get("id_p2"):
        pokes = [f"{f}:ff8b82:{TENANTS[tenant]['id_p2']}" for f in (1400, 1450, 1500)] + pokes
    pokes += pin_pokes
    # NO timer poke: $FF8109 is BINARY (99, one tick per ~82 frames = ~8,100
    # frames per round); a 0x99 poke read as 153 ENDED the round (measured
    # 14z-120). Parts are kept under a round instead.
    assert end - FIRST_EVENT < 7500, f"part {part} exceeds a round ({end - FIRST_EVENT} frames)"
    if part in METER_PARTS[tenant]:
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
    rows = []; facing = {}; ids = {}
    want_id = int(TENANTS[sched["tenant"]]["id"] or "13", 16)   # Donovan = 0x13, the default cursor's pick
    for line in open(trace_path):
        f = line.split()
        if len(f) < 3 or f[0] != "F":
            continue
        d = dict(kv.split("=") for kv in f[2:])
        rows.append((int(f[1]), int(d["node"])))
        if "face" in d: facing[int(f[1])] = int(d["face"])
        if "id" in d: ids[int(f[1])] = int(d["id"])
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
        # +0x0B (flip_x) = 1 when P1 faces RIGHT (measured: every far-pinned event, P2 on the right, reads 1)
        mark = "  FACING-LEFT" if (e["frame"] in facing and facing[e["frame"]] == 0) else ""
        if e["frame"] in ids and ids[e["frame"]] != want_id:
            mark += f"  WRONG-ID:{ids[e['frame']]:#x}"   # the wrong character is on P1 — the line can never match a sane freeze
        out.append(f"{sched['part']}\t{e['name']}\t" + " ".join(f"{t}:0x{q:02x}" if t != "OFF" else f"OFF:{q:#x}" for t, q in seen) + mark)
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
