#!/usr/bin/env python3
"""chains174_rigs.py — the rigs of GitHub #174: the tenants' never-entered a2 chains that carry
attack records, one rig per tenant (14z-184).

WHY A SEPARATE GENERATOR. #174's rigs live OUTSIDE the naming corpus (tests/replays/chains174/,
maintainer-ruled 2026-09-27, "Dedicated gate (Recommended)"): the 19 tracked files that glob
tests/replays/naming/ follow it, and 14z-181's two added naming parts turned three of them red.
This tool builds its rigs with tools/name_moves.py's own machinery — the select prologue, the
position pins, the HP pin, the per-event stock poke, the round-start guard — by installing its
schedules into name_moves.SCHEDULES at run time under the part name "c174". name_moves.py
itself is not edited, so nothing that follows it moves.

THE SCHEDULES ARE HYPOTHESES (build/agent184/t174_hypotheses.md, from a static reading of vs2's
command handlers): each event is a way the reading says the chain is entered, several timings
per hypothesis because which one enters is what the native leg measures. An event that enters
nothing new on native is a refuted or mistimed hypothesis, never a comparison.

Usage:
  python3 tools/chains174_rigs.py gen <tenant> <out.rpl> <out.json>
  python3 tools/chains174_rigs.py all <out dir>      # <tenant>_c174.rpl / .json for the three
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import name_moves as nm  # noqa: E402

B = nm.B
PART = "c174"


def shift(recipe, k):
    return [(a + k, b + k) + tuple(r) for a, b, *r in recipe]


def gc_crouch(b, at):
    # the guard cancel from a CROUCHING block: P2's 5HP at 0; P1 holds DOWN-BACK through the
    # block, then 623+b from `at` (the standing recipe, gc_v, holds plain back)
    return [(0, 3, "3", "p2"), (-4, at - 1, "DL"), (at, at + 1, "R"), (at + 2, at + 3, "D"), (at + 4, at + 7, "DR" + B[b])]


def gc_air(b, p1_at, p2_hit, at):
    # the guard cancel from an AIR block: P2 jumps toward P1 at 0 and presses j.HP at `p2_hit`; P1 jumps
    # straight up at `p1_at` and holds back from 3 frames later; P1's 623+b from `at`, still in the air
    # (a GROUNDED 5HP hit the jumping P1 instead of being blocked, 14z-184 first probe: b:0x03 / b:0x23)
    return [(0, 2, "UL", "p2"), (p2_hit, p2_hit + 3, "3", "p2"), (p1_at, p1_at + 2, "U"), (p1_at + 3, at - 1, "L"),
            (at, at + 1, "R"), (at + 2, at + 3, "D"), (at + 4, at + 7, "DR" + B[b])]


def gv_catch(k):
    # P2 jumps toward P1 at 0; P1's Genocide Vulcan (ES), 421+PP, from +k
    return [(0, 2, "UL", "p2")] + shift(nm.rdp("PP"), k)


# THE SCHEDULES, as measured (14z-184, build/agent184/t174/): every event below ENTERED its target chain on native
# vs2 at vs2's default play mode (probes p1-p6), and again at the gate's level 6 (Genocide Vulcan retimed: from +16
# entered at level 8 but not at 6; +19 neither; +22, +25 and +28 at 6); the variants that entered nothing were dropped. Two per chain, so
# one timing moving is visible without losing the chain. TARGET is what the gate requires each event to enter.
SCHED = {
    "huitzil": [
        ("Reflect Wall [crouch block, 623LP at hit+2]", gc_crouch("LP", 12), 240, "near"),
        ("Reflect Wall [crouch block, 623HP at hit+2]", gc_crouch("HP", 12), 240, "near"),
        # a SPACER where the +19 timing stood (it entered nothing at level 6): the catch is PHASE-SENSITIVE — with the
        # spacer removed every later event moves and +22 stopped entering (14z-184) — so the spacer keeps the
        # measured frames; it has no target and the entry check skips it
        ("spacer (keeps the Genocide Vulcan events on their measured frames)", [], 300, "far"),
        ("Genocide Vulcan (ES) [421PP] vs a jump-in, from +22", gv_catch(22), 300, "far"),
        ("Genocide Vulcan (ES) [421PP] vs a jump-in, from +25", gv_catch(25), 300, "far"),

        # the AIR-block guard cancels LAST: ours diverges there (#182), and every later event of the part would read coupled
        # a SPACER in the first air slot: at that slot no air timing entered on native at level 6 (three tried, 14z-184);
        # at the next two they do, so the spacer keeps them there
        ("spacer (keeps the air-block events on their measured frames)", [], 260, "near"),
        ("Reflect Wall [air block, P1 j.8 at +2, P2 j.HP at +14, 623LP at +26]", gc_air("LP", 2, 14, 26), 260, "near"),
        ("Reflect Wall [air block, P1 j.8 at +4, P2 j.HP at +16, 623LP at +28]", gc_air("LP", 4, 16, 28), 260, "near"),
    ],
    "donovan": [
        # the maintainer, 2026-09-27: "it connects after 63214+MP/HP but not after regular throw (4/6+MP/HP). The only
        # setup I have that conceistently works for me is Foot Stab after 63214+MP/HP" (Sword Grapple); the grapple
        # holds the victim to about +101, so the pursuit is pressed after the release
        ("Foot Stab (ES) [8KK] off Sword Grapple [63214HP], press at +104", nm.hcb_cont("HP") + [(104, 106, "U46")], 320, "near"),
        ("Foot Stab (ES) [8KK] off Sword Grapple [63214HP], press at +112", nm.hcb_cont("HP") + [(112, 114, "U46")], 320, "near"),
    ],
    "pyron": [
        ("Piled Hell [623 KKK]", nm.dp("LK")[:-1] + [(8, 11, "DR456")], 300, "far"),
        ("Piled Hell [623 KKK] near", nm.dp("LK")[:-1] + [(8, 11, "DR456")], 300, "near"),
        ("6MP far", [(0, 3, "R2")], 160, "far"),
        ("6HP far", [(0, 3, "R3")], 160, "far"),
    ],
}
TARGET = {   # event name -> the never-entered a2 chain (GitHub #174) the event must enter on native
    "Reflect Wall [crouch block, 623LP at hit+2]": "a2:0x4b", "Reflect Wall [crouch block, 623HP at hit+2]": "a2:0x4b",
    "Reflect Wall [air block, P1 j.8 at +2, P2 j.HP at +14, 623LP at +26]": "a2:0x4d",
    "Reflect Wall [air block, P1 j.8 at +4, P2 j.HP at +16, 623LP at +28]": "a2:0x4d",
    "Genocide Vulcan (ES) [421PP] vs a jump-in, from +22": "a2:0x50 a2:0x29",
    "Genocide Vulcan (ES) [421PP] vs a jump-in, from +25": "a2:0x50 a2:0x29",
    "Foot Stab (ES) [8KK] off Sword Grapple [63214HP], press at +104": "a2:0x4f",
    "Foot Stab (ES) [8KK] off Sword Grapple [63214HP], press at +112": "a2:0x4f",
    "Piled Hell [623 KKK]": "a2:0x48", "Piled Hell [623 KKK] near": "a2:0x48",
    "6MP far": "a2:0x03", "6HP far": "a2:0x05",
}


def gen(tenant, out_rpl, out_json):
    nm.SCHEDULES[tenant][PART] = SCHED[tenant]
    nm.METER_PARTS[tenant].add(PART)   # the ES events spend a stock; the per-event poke keeps 9
    nm.gen(tenant, PART, out_rpl, out_json)


def main(argv):
    if len(argv) == 4 and argv[0] == "gen":
        gen(argv[1], argv[2], argv[3]); return 0
    if len(argv) == 2 and argv[0] == "all":
        os.makedirs(argv[1], exist_ok=True)
        for t in SCHED:
            gen(t, os.path.join(argv[1], f"{t}_{PART}.rpl"), os.path.join(argv[1], f"{t}_{PART}.json"))
        return 0
    print(__doc__.split("Usage:")[1], file=sys.stderr)
    return 2


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
