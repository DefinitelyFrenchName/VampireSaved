#!/usr/bin/env python3
"""command_throw_rigs.py — the vsavj COMMAND THROWS and GRABS for the community cross-check (GitHub #229, 14z-205,
fork F4 of the parallel run; build/agent205/t229/BRIEF.md). Re-rigged 14z-208b on the maintainer's answers to F4's
sheets (STATE 14z-208b (6)): the air throws moved to tools/ground_throw_rigs.py, Pit of Blame after a knockdown,
Prova di Servo's second K, Ira Spinta HK's cadence, Mega Spike (not in the workbook), and THE MOTION TEST.

  python3 tools/command_throw_rigs.py gen <out dir>                         the rigs (.rpl + .json), parts of <= 6 events
  python3 tools/command_throw_rigs.py fields                                the FIELDS= spec of the trace leg
  python3 tools/command_throw_rigs.py analyse <rig.json> <trace.txt> <vsavj_data.bin>   one JSON row per event (trace leg)
  python3 tools/command_throw_rigs.py dumps <rig.json>                      the DUMPS= spec of the two applier legs
  python3 tools/command_throw_rigs.py records <rig.json> <leg dir> <vsavj_data.bin>     one JSON row per event (records)
  python3 tools/command_throw_rigs.py snaps <rows.jsonl>                    SNAP_FRAMES (+ DUMPS) for the capture leg
  python3 tools/command_throw_rigs.py sheet <out.png> <legs root> <rows.jsonl>          the capture sheet
  python3 tools/command_throw_rigs.py rowset <workbook.xlsx>                THROWS against the workbook's rows
  python3 tools/command_throw_rigs.py join <trace rows> <records> <workbook.xlsx>         the per-row, per-column verdicts
  python3 tools/command_throw_rigs.py expect <legs root> <rigs dir> <expected.tsv> [--freeze] [--perturb=<control>]
                                                                            every event against its frozen line

THE RIG is tools/ground_throw_rigs.py's (the walk-in of tools/vanilla_join_rig.py, the tokens and motion cadences of
tools/name_moves.py): the character FORCED on P1 by the early-window poke, victim Victor (Demitri when Victor throws),
replay 17's prologue; per EVENT both fighters pinned to the far pair at t-230, P1 walks right t-190..t-40 to pushbox
contact, a 40-frame pause, then ONE input at t (a motion + button, or a jump and an air input). Before each event P2's
HP words are re-pinned to 288 and P1's stock/meter to 0 (9 stocks for a meter event: ES, EX).

A scripted input is not the move it names ([VSE-47]): nothing here trusts its own script. THE TRACE LEG
(tests/lua/field_trace.lua, no debugger) reads per frame P1's anim node (+0x1C, mapped onto tools/anim_nodes.py's graph
by vanilla_join_rig.node_map), both fighters' throw indicators (+0x134: P1 0x01 executing a throw, P2 0xFF being
thrown), P2's red/white HP words, P1's stock (+0x109) and meter (+0x10A), positions and facing: the CHAIN the fighter
entered from the button frame, whether and when the hold started, every fall of P2's HP, the stock it spent. THE TWO
APPLIER LEGS (tools/run_replay_guarded.sh, one logging breakpoint each, PRG:0x0189EA and PRG:0x02979A, as
tests/audit_ground_throws.sh) give the damage records the GAME staged, each required to lie in the thrower's own attack
table and to LAND on that leg's own HP dumps. THE CAPTURE LEG (the guard without -debug) takes a snapshot at each
event's first fall, and its P2 HP at that frame must equal the trace leg's (the two instruments on one clock).
"""
import json
import os
import re
import struct
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import ground_throw_rigs as gt  # noqa: E402
import hitbox_records  # noqa: E402
import name_moves as nm  # noqa: E402
import vanilla_frames as vf  # noqa: E402
import vanilla_join_rig as vj  # noqa: E402
import anim_nodes  # noqa: E402

GAP = 624            # = 16 x 39 (name_moves.TICK_QUANTUM, GitHub #168): every event at the first event's double-pass phase. At
                     # 600 the outcome of the timing-tight grabs moved with the event's slot (Ira Spinta HK, the Mummy Drops,
                     # the air throws: measured 14z-205), as #168 found for the naming rigs
END_AT = 340          # an event's END frame offset from its PRESS (bounded by the next event's pins at t+GAP-230)
HOLD_WIN = 150        # frames after the press in which a hold may start (Jedah's Ira Spinta starts late)
PER_PART = 6          # events per rig (the applier legs' DUMPS spec stays under the environment's limit)
VICTIM = 0x03
B = nm.B


# ---------------------------------------------------------------- recipes (P1 faces RIGHT; tokens replay.lua grammar)
def hcb(b):  return nm.hcb_cont(b)                       # 632[4] / 6324 = 63214, no release between R and DR
def qcf(b):  return nm.qcf(b)                            # 236
def qcb(b):  return nm.qcb(b)                            # 214
def dp(b):   return nm.dp(b)                             # 623
def hcf(b):  return nm.hcf(b)                            # 412[6] = 41236
def d63(b):  return [(0, 2, "D"), (3, 5, "R"), (6, 9, "DR" + B[b])]          # 263, literally
def air_hcb(b):  # J.632[4]: jump, then 63214 + button on the way
    return [(0, 2, "U"), (12, 14, "R"), (14, 16, "DR"), (16, 18, "D"), (18, 20, "DL"), (20, 26, "L"), (22, 26, B[b])]
def air_qcf(b):  return nm.air_qcf(b)                     # J.236
def air_hcf(b):  # J.41236: jump, then 4 1 2 3 6 + button on the way
    return [(0, 2, "U"), (12, 14, "L"), (14, 16, "DL"), (16, 18, "D"), (18, 20, "DR"), (20, 26, "R"), (22, 26, B[b])]
def motion(dirs, b, start=0, pre=()):
    """a motion as hcb_cont writes 63214 (THE MOTION TEST, #229, 14z-208b): each direction 2 frames with no release, the
    last held 6 with the button from its third frame; `pre` (a jump) before it, the directions from `start`"""
    toks, n = list(pre), len(dirs)
    toks += [(start + 2 * i, start + 2 * i + 2, d) for i, d in enumerate(dirs[:-1])]
    s = start + 2 * (n - 1)
    return toks + [(s, s + 6, dirs[-1]), (s + 2, s + 6, B[b])]


# the half-circle spellings the maintainer asked to be measured (2026-10-25: "63214, 6324, 6321, 6214 or 624 ... This is
# the mirror test to the half circle forward test"), P1 facing right; the forward ones are their mirrors
HCB_SPELL = {"63214": ["R", "DR", "D", "DL", "L"], "6324": ["R", "DR", "D", "L"], "6321": ["R", "DR", "D", "DL"],
             "6214": ["R", "D", "DL", "L"], "624": ["R", "D", "L"]}
_MIR = {"R": "L", "L": "R", "DR": "DL", "DL": "DR", "D": "D"}
HCF_SPELL = {f: [_MIR[d] for d in HCB_SPELL[m]] for f, m in
             (("41236", "63214"), ("4126", "6324"), ("4123", "6321"), ("4236", "6214"), ("426", "624"))}


def seq(*toks, gap=3):  # a button/direction sequence, each held 2 frames
    return [(i * gap, i * gap + 2, B.get(t, t)) for i, t in enumerate(toks)]


# THE ROW SET: per workbook sheet, (workbook row id, our label, recipe, meter event[, walk-in frames]). The row id is
# the workbook's `move`, or its `input` when the move cell is empty (Bishamon). A row whose input names a strength
# class without a strength ("632[4]P") is run with all three buttons of the class, so which strengths throw is
# measured; a row naming a strength is run with that strength. Where the workbook's input is not the engine's (vsavj's command handlers, decoded from the eval table at
# CPU:$0BD57A — build/agent205/t229/f4_throws/handlers.out), the engine's input is run and the label says which:
# Sasquatch's Big Swing (the rotation tracker is kick-masked, the sheet writes 360+P), Q-Bee's Catch and Release (her
# handler has no 236 tracker; the 41236+P one starts it), Victor's 720 (entered in the air: on the ground the first
# 8 jumps).
def _str(row, kind, mk, buttons, meter=False, walk=150):
    """one event per strength: the row's input with each of `buttons` (a generic "P"/"K" row is run with all three, so
    which strengths throw is measured — on vsavj the throw branches mask the new press, e.g. Bulleta's 6324+P branch
    `andi.b #$6` = MP or HP only, Felicia's 6324+K `andi.b #$60` = MK or HK; tools/command_throw_rigs.py's report)"""
    return [(row, f"{kind} {x}", mk(x), meter, walk) for x in buttons]


P3, K3 = ("LP", "MP", "HP"), ("LK", "MK", "HK")


def rot(b):  # 360 = the rotation tracker (dispatcher CPU:$02A1B4): cardinals 6 2 4 8, the 8 held 2 frames and the button
    # pressed 1 frame after it (measured 14z-205 on Demitri and Bishamon: with the button ON the 8's first frame the
    # previous run's back direction made it a BACK THROW; one frame later the rotation completes, before the jump)
    return [(0, 3, "R"), (3, 6, "D"), (6, 9, "L"), (9, 11, "U"), (10, 12, B[b])]


def air720(b):  # 720 = "rotate 6 steps": entered in the air after a neutral jump (6 2 4 8 6 2 4 8), the button on the
    # landing (the completion check CPU:$0290B2 accepts the landing state 0x0604; on the ground the first 8 jumps).
    # Measured 14z-205: KK at +44 completes it (+42 completed the 623K tracker's ES instead, +46..+52 nothing)
    return [(0, 2, "U")] + [(28 + 2 * i, 30 + 2 * i, d) for i, d in enumerate(["R", "D", "L", "U", "R", "D", "L"])] + \
           [(42, 44, "U"), (44, 46, B[b])]


def qb_air(b):  # Q-Bee's air 41236 grab: P2 jumps 2 frames ahead, then her fast air 41236 (measured 14z-205: the grab
    # lands on a P2 in the air; against a grounded P2 every strength whiffed)
    return [(-2, 0, "U", "p2"), (0, 2, "U"), (6, 8, "L"), (8, 10, "DL"), (10, 12, "D"), (12, 14, "DR"), (14, 18, "R"), (15, 18, B[b])]


_SWEEP = [(0, 3, "D" + B["HK"], "p2")]                    # Victor sweeps Anakaris (the knockdown Pit of Blame needs)
_late = lambda rec, d: [(d + r[0], d + r[1], r[2]) for r in rec]
_PIT_P2 = [("P2 walk +41..+61, pursuit +62", [(41, 61, "L", "p2"), (62, 65, "U" + B["HP"], "p2")]),
           ("P2 jumps toward +50", [(50, 53, "UL", "p2")])]
_PROVA = [(0, 2, "L"), (2, 4, "DL"), (4, 6, "D"), (6, 9, "DR"), (7, 9, B["KK"])]           # 4123+KK, the install


THROWS = {
    "FE": _str("HELL CAT", "632[4]", hcb, K3) + [("ES HELL CAT", "632[4]KK", hcb("KK"), True)],
    # Mummy Drop is RANGED: at contact no strength grabs (14z-205); LP grabbed from a 20-frame walk-in, MP and HP
    # only from the far pin (the 20/10/30-frame walk-ins missed), the ES from the 20-frame one
    "AN": [("LP MUMMY DROP", "236LP walk20", qcf("LP"), False, 20)] + [(f"{x} MUMMY DROP", f"236{x} far", qcf(x), False, 0) for x in ("MP", "HP")]
          + [("ES MUMMY DROP", "236PP walk20", qcf("PP"), True, 20)]
          # the press is the 623K's (+20): from the sweep, Victor's own sweep record (on Anakaris) would fall in the window
          + [(row, f"P2 sweep ~623{b}+20, {how}", _SWEEP + _late(dp(b), 20) + rec, b == "KK", 150, 20)
             for row, b in (("PIT OF BLAME", "HK"), ("ES PIT OF BLAME", "KK")) for how, rec in _PIT_P2]
          + [("PIT OF BLAME", "P2 sweep, no 623K, P2 jumps toward +50 (control)", _SWEEP + [(50, 53, "UL", "p2")], False, 150, 20)],
    "AU": _str("CRYSTAL LANCER", "6324", hcb, P3) + [("ES CRYSTAL LANCER", "6324PP", hcb("PP"), True)]
          + _str("GEMS ANGER", "6324", hcb, K3) + [("ES GEMS ANGER", "6324KK", hcb("KK"), True)],
    "BI": [(f"360+{x}", f"KIRISUTE GOMEN 360{x}", rot(x), False) for x in P3]
          + [("360+PP", "ES KIRISUTE GOMEN 360PP", rot("PP"), True), ("632[4]PP", "ONI KUBI HINERI 632[4]PP", hcb("PP"), True)],
    "BU": _str("SENTIMENTAL TYPHOON", "632[4]", hcb, P3) + [("ES SENTIMENTAL TYPHOON", "632[4]PP", hcb("PP"), True)],
    "DE": _str("NEGATIVE STOLEN", "360", rot, P3) + [("MIDNIGHT BLISS", "263PP", d63("PP"), True),
           ("MIDNIGHT PLEASURE", "LP,MP,6,MK,MK", seq("LP", "MP", "R", "MK", "MK", gap=6), True)],
    "GA": _str("WILD CIRCULAR", "632[4]", hcb, K3) + [("ES WILD CIRCULAR", "632[4]KK", hcb("KK"), True)],
    "JE": _str("NERO FATICA", "214", qcb, P3) + [("ES NERO FATICA", "214PP", qcb("PP"), True)]
          + _str("IRA SPINTA", "j.632[4]", air_hcb, ("LK", "MK"))
          + [("IRA SPINTA", "j.632[4] HK at16", motion(HCB_SPELL["63214"], "HK", start=16, pre=[(0, 2, "U")]), False),
             ("ES IRA SPINTA", "j.632[4]KK", air_hcb("KK"), True)]
          + _str("SAN BASSALE", "632[4]", hcb, K3),
    "LE": _str("HOUTENGEKI", "632[4]", hcb, P3),
    "LI": _str("MYSTIC ARROW", "632[4]", hcb, P3) + [("ES MYSTIC ARROW", "632[4]PP", hcb("PP"), True)],
    "MO": _str("VECTOR DRAIN", "632[4]", hcb, P3) + [("ES VECTOR DRAIN", "632[4]PP", hcb("PP"), True),
           # from the FAR pin: after any walk-in the sequence's HP lands as a standing HP first (measured 14z-205)
           ("CRYPTIC NEEDLE", "6,HP,MP,LP,6 far", seq("R", "HP", "MP", "LP", "R"), True, 0)],
    "QB": [(f"{x} CATCH AND RELEASE", f"41236{x}", hcf(x), False) for x in P3] + [("ES CATCH AND RELEASE", "41236PP", hcf("PP"), True)]
          + [(f"AIR {x} CATCH AND RELEASE", f"j.41236{x} p2 jumps", qb_air(x), False) for x in P3]
          + [("AIR ES CATCH AND RELEASE", "j.41236PP p2 jumps", qb_air("PP"), True)]
          + _str("O.M.", "632[4]", hcb, P3) + [("ES O.M.", "632[4]PP", hcb("PP"), True)],
    "SA": _str("BIG BRUNCH", "632[4]", hcb, P3) + [("ES BIG BRUNCH", "632[4]PP", hcb("PP"), True)]
          + _str("BIG SWING", "360", rot, K3) + [("ES BIG SWING", "360KK", rot("KK"), True),
                                                 ("BIG SWING", "control: 360 HP (a punch reaches Big Brunch)", rot("HP"), False)],
    "VI": [("GIGA SHOCK", "236LK", qcf("LK"), False), ("GIGA SHOCK", "236HK", qcf("HK"), False),
           ("GERDENHEIM 3", "j.720KK on landing", air720("KK"), True)]
          + [("MEGA SPIKE", f"360{x}", rot(x), x == "PP") for x in ("LP", "MP", "HP", "PP")],
    "ZA": _str("SKULL PUNISH", "632[4]", hcb, P3) + [("ES SKULL PUNISH", "632[4]PP", hcb("PP"), True)],
}
# THE MOTION TEST (the maintainer's third and fourteenth answers, 2026-10-25): every half-circle throw with the
# spellings of HCB_SPELL / HCF_SPELL, one strength that grabs, in motion()'s encoding. The hcb sheets' full 63214 is
# their own row (hcb_cont == motion(63214)); the hcf rows' full motion is added, their own rows using another cadence.
MOTION_ROWS = [("AU", "CRYSTAL LANCER", "HP", 0, {}), ("AU", "GEMS ANGER", "HK", 0, {}), ("BI", "632[4]PP", "PP", 0, {}),
               ("BU", "SENTIMENTAL TYPHOON", "HP", 0, {}), ("FE", "HELL CAT", "HK", 0, {}),
               ("GA", "WILD CIRCULAR", "HK", 0, {}), ("JE", "SAN BASSALE", "HK", 0, {}),
               ("JE", "IRA SPINTA", "LK", 0, dict(start=12, pre=[(0, 2, "U")])), ("LE", "HOUTENGEKI", "HP", 0, {}),
               ("LI", "MYSTIC ARROW", "HP", 0, {}), ("MO", "VECTOR DRAIN", "HP", 0, {}), ("QB", "O.M.", "HP", 0, {}),
               ("SA", "BIG BRUNCH", "HP", 0, {}), ("ZA", "SKULL PUNISH", "HP", 0, {}),
               ("QB", "LP CATCH AND RELEASE", "LP", 1, {}),
               ("QB", "AIR LP CATCH AND RELEASE", "LP", 1, dict(start=6, pre=[(-2, 0, "U", "p2"), (0, 2, "U")])),
               ("JE", "PROVA DI SERVO", "KK", 1, {})]
for _tab, _row, _b, _fwd, _kw in MOTION_ROWS:
    for _name, _dirs in (HCF_SPELL if _fwd else HCB_SPELL).items():
        if _name == "63214":
            continue
        THROWS[_tab].append((_row, f"motion {'j.' if _kw else ''}{_name}{_b}", motion(_dirs, _b, **_kw), _b in ("PP", "KK")))

# Prova di Servo LAST on Jedah's sheet, so its two events open a rig (part 5, slots 1-2): a "far" event's position pins
# (t-230) do not hold when the previous event is a throw still running — after San Bassale HK Jedah stood 64 px from
# Victor, not 176, and the hand passed him (the maintainer, 2026-10-25, on the re-rig sheet: "Victor is too close to get
# grabbed by the blood hand so the second part whiffs"; measured on the trace, 14z-208b)
THROWS["JE"] += [("PROVA DI SERVO", "4123KK ~HK+30 far", _PROVA + [(37, 39, B["HK"])], True, 0, 7),
                 ("PROVA DI SERVO", "4123KK, no second K, far (control)", _PROVA, True, 0)]

# per-sheet overrides: a recipe that the first pass found does not fire is retried by a variant here, the first
# pass's result kept in the report (never silently replaced)
VARIANTS = {}


def _press_off(rec):
    """the frame offset of the COMPLETING input: the start of the last token that carries a button digit"""
    return max(r[0] for r in rec if any(ch.isdigit() for ch in r[2]))


def _parts(tab):
    evs = THROWS[tab] + VARIANTS.get(tab, [])
    return [evs[i:i + PER_PART] for i in range(0, len(evs), PER_PART)]


def gen(out_dir):
    out = Path(out_dir); out.mkdir(parents=True, exist_ok=True)
    n = 0
    for tab in THROWS:
        cid = vf.CHARS[tab][0]
        vic = 0x01 if cid == VICTIM else VICTIM
        x1, x2 = nm.PIN["far"]
        for pi, evs in enumerate(_parts(tab), 1):
            lines = [f"# #229 command/air throw rig — {tab} ({cid:#04x}) part {pi} on vsavj, victim {vic:#04x}",
                     "# (tools/command_throw_rigs.py gen; DO NOT hand-edit, regenerate). Select prologue from replay 17",
                     "# (the characters are FORCED by the early-window poke, so the cursor path does not matter).",
                     nm.REPLAY17_PROLOGUE.rstrip()]
            t = t0 = nm.FIRST_EVENT + vj.WALKIN_SHIFT
            sched = {"char": f"{cid:#04x}", "sheet": tab, "part": pi, "victim": f"{vic:#04x}", "gap": GAP, "events": []}
            pokes = [f"{f}:ff8782:{cid:02x}" for f in (1400, 1450, 1500)] + [f"{f}:ff8b82:{vic:02x}" for f in (1400, 1450, 1500)]
            for ev in evs:
                row, label, rec, meter = ev[:4]
                walk = ev[4] if len(ev) > 4 else 150      # the walk-in's length; 150 = pushbox contact, 0 = the far pin
                poff = ev[5] if len(ev) > 5 else None     # the press offset when the event has more than one press
                pokes += [f"{t - 230}:ff8410:{x1:04x}", f"{t - 230}:ff8810:{x2:04x}",
                          f"{t - 20}:ff8850:01200120", f"{t - 20}:ff8509:{'09' if meter else '00'}0000"]
                if walk < 150:   # RE-PLACED just before the walk (14z-208b, ruled "Fix all, re-show"): the t-230 pins do
                    # not hold while the previous event's throw still runs (after San Bassale HK Jedah stood 64 px from
                    # Victor, not 176) — a walk to contact absorbs that, a short or no walk does not
                    pokes += [f"{t - 50 - walk}:ff8410:{x1:04x}", f"{t - 50 - walk}:ff8810:{x2:04x}"]
                if walk:
                    lines.append(f"{t - 40 - walk}-{t - 40} p1=R")
                for r in rec:
                    who = r[3] if len(r) > 3 else "p1"
                    lines.append(f"{t + r[0]}-{t + r[1]} {who}={r[2]}")
                press = t + (_press_off(rec) if poff is None else poff)
                # the END frame: 340 after the press, never at or past the next event's pins (t + GAP - 230) —
                # Gerdenheim 3's last hit lands at press +328 (measured 14z-205; a fixed t + 360 cut it off)
                sched["events"].append({"row": row, "label": label, "meter": meter, "frame": t,
                                        "press": press, "end": min(press + END_AT, t + GAP - 235)})
                t += GAP
            end = t + 100
            lines.append(f"{end} wait")
            assert end - t0 < 7500, "a rig must fit inside one round"
            sched["pokes"] = pokes
            sched["frames"] = end + 50
            name = f"ct_{tab}_{pi}"
            (out / f"{name}.rpl").write_text("\n".join(lines) + "\n")
            (out / f"{name}.json").write_text(json.dumps(sched, indent=1) + "\n")
            n += 1
    print(f"wrote {n} rigs ({sum(len(v) for v in THROWS.values())} events) to {out}")


def _walk_signed(img, table, signed=True):
    """{seq: [node addr, ...]} for one anim index table, the word offsets read SIGNED as the game adds them (a 68000
    word add sign-extends). tools/anim_nodes.py's walk_table reads them unsigned, which mislabels the chains below
    their index table (found by #229 fork F2, 14z-205; its walker is tools/specials_b_rigs.py's walk_signed — copied
    here, not imported, per the parallel run's brief): the same node rules (flags bit 7 = link at +0x18, bit 6 = hold,
    else sequential), the entry count bounded by the smallest positive offset."""
    words, k = [], 0
    while k < 1024:
        w = int.from_bytes(img[table + 2 * k:table + 2 * k + 2], "big", signed=signed)
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


def node_map_signed(img, cid, signed=True, starts=False):
    """{node address: 'table:seq'} over the fighter tables a2, a, b, c (a2 first, as vanilla_join_rig.node_map), offsets
    read signed (signed=False reproduces the unsigned read, for the comparison the report prints). With starts=True,
    {chain START node: label} only: a chain with no terminator walks on into the chains above it (Sasquatch's a2:0x37,
    read signed, runs through 0x39-0x3d), so a membership label is first-claimant-wins; the START a fighter reaches
    names the chain it was put into."""
    rows = vf.bank_rows(Path(__file__).resolve().parent.parent / "build/manifest/bank_map.toml")
    out = {}
    for tn in ("a2", "a", "b", "c"):
        tbl = vf.row_ptr(img, rows["anim_index_" + tn], cid)
        for seq, nodes in _walk_signed(img, tbl, signed).items():
            for a in (nodes[:1] if starts else nodes):
                out.setdefault(a, f"{tn}:{seq:#04x}")
    return out


FIELDS = ("ff841c:l:node,ff881c:l:p2node,ff8534:b:p1thr,ff8934:b:p2thr,ff8850:w:p2red,ff8852:w:p2white,"
          "ff8509:b:stock,ff850a:w:meter,ff8410:w:p1x,ff8414:w:p1y,ff8810:w:p2x,ff8814:w:p2y,ff840b:b:p1face,"
          "ff8505:b:trig,ff8506:b:cmd,ff8404:l:st")


def analyse(sched_path, trace, img_path):
    """One row per event from the TRACE leg: the chain entered from the button frame (and every chain after it in the
    window), the hold (first frame from the press with P1 +0x134 = 0x01 and P2's = 0xFF; whether it was set on the
    frame before the press), P2's falls (frame, red, white), P1's stock at the press-1 and END frames and its meter at
    END, the airborne flag at the press, P1's facing at the press, both x at END."""
    sched = json.loads(Path(sched_path).read_text())
    img = Path(img_path).read_bytes()
    cid = int(sched["char"], 16)
    nmap = node_map_signed(img, cid)
    umap = vj.node_map(img, cid)        # the unsigned read (tools/anim_nodes.py), kept beside it for the comparison
    smap = node_map_signed(img, cid, signed=os.environ.get("CT_UNSIGNED") != "1", starts=True)   # chain STARTS
    # (signed: the identity the report uses; CT_UNSIGNED=1 reads them unsigned — the gate's control `unsigned-chain`)
    fr = vj._samples(trace)
    out = []
    for e in sched["events"]:
        t0, press, end = e["frame"], e["press"], e["end"]
        g = lambda f, k: fr.get(f, {}).get(k)
        node = lambda f: nmap.get((g(f, "node") or 0) & 0xFFFFFFFF)
        unode = lambda f: umap.get((g(f, "node") or 0) & 0xFFFFFFFF)
        ubefore = {unode(f) for f in range(t0 - 30, press) if f in fr}
        ufirst = next((unode(f) for f in range(press, end + 1) if unode(f) and unode(f) not in ubefore), None)
        snode = lambda f: smap.get((g(f, "node") or 0) & 0xFFFFFFFF)
        sbefore = {snode(f) for f in range(t0 - 30, press) if f in fr} - {None}
        sfirst, sall = None, []
        for f in range(press, end + 1):
            c = snode(f)
            if c and c not in sbefore and (not sall or sall[-1][0] != c):
                sall.append((c, f - press)); sfirst = sfirst or (c, f - press)
        before = {node(f) for f in range(t0 - 30, press) if f in fr}
        chains, first = [], None
        for f in range(press, end + 1):
            c = node(f)
            if c and c not in before and (not chains or chains[-1][0] != c):
                chains.append((c, f - press))
                first = first or (c, f - press)
        held = lambda f: g(f, "p1thr") == 1 and g(f, "p2thr") == 255
        hold = next((f for f in range(press, press + HOLD_WIN) if held(f)), None)
        drops, prev = [], (g(press - 1, "p2red"), g(press - 1, "p2white"))
        for f in range(press, end + 1):
            cur = (g(f, "p2red"), g(f, "p2white"))
            if None in cur or None in prev:
                prev = cur; continue
            dr, dw = prev[0] - cur[0], prev[1] - cur[1]
            if dr > 0 or dw > 0:
                drops.append((f, max(dr, 0), max(dw, 0)))
            prev = cur
        trig = next((f for f in range(t0, end + 1) if g(f, "trig") == 1 and g(f - 1, "trig") != 1), None)
        # THE MOVE'S OWN START: the first frame from 10 before the press whose state long (+0x04) is a special (seq
        # 0x0E), an ES (0x10), an EX (0x12) or a throw (class word 0x0204) — so a normal that is PART of the input
        # (Cryptic Needle's HP, Midnight Pleasure's LP and MP) is not counted as the move's damage
        def _mv(f):
            v = (g(f, "st") or 0) & 0xFFFFFFFF
            return (v >> 16) == 0x0204 or ((v >> 16) == 0x0200 and ((v >> 8) & 0xFF) in (0x0E, 0x10, 0x12))
        move_start = next((f for f in range(press - 10, end + 1) if _mv(f)), None)
        if move_start is None:
            move_kind = "-"
        else:
            _v = (g(move_start, "st") or 0) & 0xFFFFFFFF
            move_kind = "throw" if (_v >> 16) == 0x0204 else {0x0E: "special", 0x10: "ES", 0x12: "EX"}[(_v >> 8) & 0xFF]
        # falls of P2's HP from the event frame to the move's start: the input's own normals landing first
        pre_falls = 0
        if move_start is not None:
            for f in range(t0, move_start):
                a_, b_ = (g(f - 1, "p2red"), g(f - 1, "p2white")), (g(f, "p2red"), g(f, "p2white"))
                if None not in a_ + b_ and (b_[0] < a_[0] or b_[1] < a_[1]):
                    pre_falls += 1
        ground = g(t0 - 5, "p1y")
        out.append({"sheet": sched["sheet"], "part": sched["part"], "row": e["row"], "label": e["label"],
                    "meter": e["meter"], "frame": t0, "press": press, "end": end,
                    "sampled": sum(1 for f in range(t0 - 30, end + 1) if f in fr), "need": end + 1 - (t0 - 30),
                    "entered": first[0] if first else "UNFIRED", "entered_at": first[1] if first else None,
                    "entered_unsigned": ufirst or "UNFIRED",
                    "entered_start": sfirst[0] if sfirst else "UNFIRED", "entered_start_at": sfirst[1] if sfirst else None,
                    "starts": [f"{c}@+{o}" for c, o in sall],
                    "chains": [f"{c}@+{o}" for c, o in chains],
                    "hold": hold, "press_to_hold": (hold - press) if hold is not None else None,
                    "pre_hold": held(press - 1), "drops": drops,
                    "stock_before": g(press - 1, "stock"), "stock_end": g(end, "stock"), "meter_end": g(end, "meter"),
                    "airborne_press": (g(press, "p1y") != ground) if ground is not None and g(press, "p1y") is not None else None,
                    "face_press": g(press, "p1face"), "x_end": (g(end, "p1x"), g(end, "p2x")),
                    "trig": (trig - press) if trig is not None else None,
                    "move_start": move_start, "move_kind": move_kind, "falls_before_move": pre_falls,
                    "cmd": g(trig + 1, "cmd") if trig is not None else None,
                    "st": f"{(g(trig + 1, 'st') or 0) & 0xFFFFFFFF:08x}" if trig is not None else None})
    for r in out:
        print(json.dumps(r))


def dumps_spec(sched):
    """The applier legs' DUMPS: P2's two HP words on every frame from the press-1 to the END frame, per event (the
    landed check judges each leg's records on ITS OWN falls, as audit_ground_throws.sh's run-728 rule)."""
    parts = []
    for e in sched["events"]:
        for f in range(e["press"] - 1, e["end"] + 1):
            parts.append(f"{f}:ff8850-ff8853")
    return ";".join(parts)


def proj_bounds(img, bank, cid):
    """the thrower's PROJECTILE attack table (bank rows proj_hitbox_base/comp), from its base to the nearest start of any
    table of any character's projectile set above it — as ground_throw_rigs.own_bounds bounds the fighter's. Aulbath's
    Gems Anger stages its gems' records there (measured 14z-205: CPU:$0B6366, outside his fighter table). None if the
    character has no projectile table."""
    try:
        H = hitbox_records.HitboxSet.from_image(img, vf.row_ptr(img, bank["proj_hitbox_base"], cid),
                                                vf.row_ptr(img, bank["proj_hitbox_comp"], cid))
    except Exception:
        return None, None
    starts = set()
    for c in range(0x20):
        for base, comp in (("proj_hitbox_base", "proj_hitbox_comp"), ("hitbox_base", "hitbox_comp")):
            try:
                Hc = hitbox_records.HitboxSet.from_image(img, vf.row_ptr(img, bank[base], c), vf.row_ptr(img, bank[comp], c))
                starts |= set(Hc.tables.values())
            except Exception:
                continue
    lo = H.tables.get("attack")
    if lo is None:
        return None, None
    return lo, min([x for x in starts if x > lo] + [len(img)])


def records(sched_path, leg, img_path):
    """One row per event from ONE applier leg: every record its probe saw inside [press, END], each with its A3, its
    place in the thrower's own attack table (or not), its power CLASS (real, white: bits 0-4 of +8/+9; flags bits 5-7,
    #241), its +0x14 meter, and LANDED (a fall of P2's HP on this leg's own dumps within gt.LAND frames after it)."""
    sched = json.loads(Path(sched_path).read_text())
    img = Path(img_path).read_bytes()
    cid = int(sched["char"], 16)
    bank = vf.bank_rows(Path(__file__).resolve().parent.parent / "build/manifest/bank_map.toml")
    lo, hi = gt.own_bounds(img, bank, cid)
    plo, phi = proj_bounds(img, bank, cid)
    probes = gt._probes(os.path.join(leg, "run.log"))
    for e in sched["events"]:
        drops, prev = set(), gt._hp(leg, e["press"] - 1)
        dumped = 0
        for f in range(e["press"], e["end"] + 1):
            cur = gt._hp(leg, f)
            dumped += cur is not None
            if cur is not None and prev is not None and (cur[0] < prev[0] or cur[1] < prev[1]):
                drops.add(f)
            prev = cur
        recs = []
        for f, a3 in probes:
            if not (e["press"] <= f <= e["end"]):
                continue
            bb = img[a3:a3 + 0x20]
            tab = "attack" if lo <= a3 < hi else ("proj" if plo is not None and plo <= a3 < phi else None)
            recs.append({"frame": f, "a3": f"{a3:#x}", "own": tab is not None, "table": tab,
                         "idx": (a3 - (lo if tab == "attack" else plo)) // hitbox_records.REC if tab else None,
                         "real": bb[8] & 0x1F, "white": bb[9] & 0x1F, "flags": (bb[8] | bb[9]) & 0xE0, "meter": bb[0x14],
                         "landed": any(f < d <= f + gt.LAND for d in drops)})
        print(json.dumps({"sheet": sched["sheet"], "part": sched["part"], "label": e["label"], "press": e["press"],
                          "dumped": dumped, "need": e["end"] + 1 - e["press"], "falls": sorted(drops), "records": recs}))


def snap_frame(r):
    """the frame a capture shows: the event's first fall, else its hold frame + 8, else the first chain + 8"""
    if r["drops"]:
        return r["drops"][0][0]
    if r["hold"] is not None:
        return r["hold"] + 8
    if r["entered_at"] is not None:
        return r["press"] + r["entered_at"] + 8
    return r["press"] + 20


def snaps(rows_path):
    fs = [snap_frame(json.loads(l)) for l in open(rows_path) if l.strip()]
    print("SNAP_FRAMES=" + ",".join(map(str, fs)))
    print("DUMPS=" + ";".join(f"{f}:ff8850-ff8853" for f in fs))


def sheet(out_png, legs_root, rows_path, title=None):
    """The capture sheet: every event at its snap frame (taken by the capture leg), labelled with the row, our input,
    the chain entered, and the frame."""
    from PIL import Image, ImageDraw
    rows = [json.loads(l) for l in open(rows_path) if l.strip()]
    tiles = []
    by_rig = {}
    for r in rows:
        by_rig.setdefault(f"ct_{r['sheet']}_{r['part']}", []).append(r)
    for rig, rs in by_rig.items():
        shots = sorted(Path(legs_root, rig, "cap", "sb", "snap").rglob("*.png"))
        if len(shots) != len(rs):
            sys.exit(f"sheet: {rig} has {len(shots)} snapshots for {len(rs)} events")
        for r, p in zip(rs, shots):
            lab = f"{r['sheet']} {r['row']} [{r['label']}]  {r['entered']}  f{snap_frame(r)} (+{snap_frame(r) - r['press']})"
            tiles.append((lab, Image.open(p).convert("RGB")))
    if not tiles:
        sys.exit("sheet: no snapshots found")
    w, h = tiles[0][1].size
    cols = 4
    nrows = (len(tiles) + cols - 1) // cols
    head = 20 if title else 0
    im = Image.new("RGB", (cols * (w + 8) + 8, nrows * (h + 22) + 8 + head), (20, 20, 20))
    d = ImageDraw.Draw(im)
    if title:
        d.text((8, 4), title, fill=(255, 255, 0))
    for i, (lab, t) in enumerate(tiles):
        x, y = 8 + (i % cols) * (w + 8), 8 + head + (i // cols) * (h + 22)
        d.text((x, y), lab[:int((w + 8) / 6)], fill=(255, 255, 255))
        im.paste(t, (x, y + 14))
    im.save(out_png)
    print(f"wrote {out_png} ({len(tiles)} snapshots)")


def _norm_type(t):
    return (t or "").strip().lower().replace("comand", "command")


def wanted(t):
    """a command throw or grab row of the workbook. Its AIR throws are not: they are the game's plain throw and moved
    to the normal throws, tools/ground_throw_rigs.py (the maintainer, 2026-10-25: "Remove all, Victor too, but add them
    to the normal throws!")"""
    t = _norm_type(t)
    return ("throw" in t and "ground" not in t and t != "air throw") or "grab" in t


# rows the maintainer supplied that the workbook does not list (2026-10-25: "Victor's sheet does not list Giga Spike,
# which is 360+P"; "Giga Spike is apparently Mega Spike in the Japanese version (input is 360+P, no ES version, command
# throw)"); vsavj's command table has it (VI `rotate 2 steps + P`, build/agent205/t229/f4_throws/handlers.out)
NOT_IN_WORKBOOK = {("VI", "MEGA SPIKE")}


def rowset(xlsx):
    import xlsx_read
    wb = xlsx_read.Workbook(xlsx)
    got = set()
    for tab in wb.sheet_names:
        for d in wb.rows(tab):
            if wanted(d.get("type")):
                mv = d.get("move")
                got.add((tab, (str(mv).strip() if mv not in (None, "None", "") else str(d.get("input")).strip()).upper()))
    ours = {(tab, ev[0].upper()) for tab, evs in THROWS.items() for ev in evs} - NOT_IN_WORKBOOK
    print(f"workbook command-throw rows {len(got)}; rigs cover {len(ours & got)} (+{len(NOT_IN_WORKBOOK)} the maintainer supplied)")
    for x in sorted(got - ours):
        print(f"MISSING from the rigs: {x}")
    for x in sorted(ours - got):
        print(f"NOT IN the workbook: {x}")
    return 0 if got == ours else 1

# ---------------------------------------------------------------- the join against the workbook (provisional until the
# maintainer confirms identity on the capture sheets)
def parse_series(cell):
    """a workbook damage cell -> [(value, min count, max count)] or None (prose): `27`, `4+4+19`, `3x3+18`, `21+2x3`,
    `5x(1～4)+16`, `4x(3~13)` (a parenthesised count is a RANGE: the unmashed count must lie inside it)"""
    import re as _re
    if cell is None:
        return None
    t = str(cell).strip().replace(" ", "").replace("～", "~").replace("\u3000", "")
    if t.endswith(".0"):
        t = t[:-2]
    out = []
    for part in t.split("+"):
        m = _re.fullmatch(r"(\d+)(?:x(\d+|\((\d+)~(\d+)\)))?", part)
        if not m:
            return None
        v = int(m.group(1))
        if m.group(2) is None:
            out.append((v, 1, 1))
        elif m.group(3):
            out.append((v, int(m.group(3)), int(m.group(4))))
        else:
            out.append((v, int(m.group(2)), int(m.group(2))))
    return out


def match_series(terms, hits):
    """greedy: each term consumes between min and max consecutive hits equal to its value (as many as it can). ->
    (verdict, detail): EXACT when every term is fixed and all hits consumed; IN RANGE when a ranged term's count fell
    inside its range; INCONSISTENT otherwise."""
    i, ranged = 0, False
    for v, lo, hi in terms:
        n = 0
        while i < len(hits) and n < hi and hits[i] == v:
            i += 1; n += 1
        if n < lo:
            return "INCONSISTENT", f"sheet {terms} vs ours {hits}"
        ranged |= lo != hi
    if i != len(hits):
        return "INCONSISTENT", f"sheet {terms} vs ours {hits} ({len(hits) - i} hit(s) of ours left over)"
    return ("IN RANGE" if ranged else "EXACT"), f"ours {hits}"


def join(trace_rows, records_path, xlsx):
    """one line per workbook row: the events that ran it, which of them GRABBED (P2 held, +0x134), and per column the
    verdict — red (per hit: the record's real + white power class, #241), white (per hit), gauge hit (P1's meter at
    the event's END, pinned to 0 before it: the swing plus the on-hit steps), startup (the press-to-hold frames; the
    sheet's startup is compared as an offset). The hits are the LANDED records of both applier legs merged in frame
    order. Prints JSON lines."""
    import xlsx_read
    wb = xlsx_read.Workbook(xlsx)
    tr = [json.loads(l) for l in open(trace_rows) if l.strip()]
    rec = {}
    for l in open(records_path):
        r = json.loads(l)
        rec.setdefault((r["sheet"], r["part"], r["label"]), []).extend(
            dict(x, leg=r["leg"]) for x in r["records"] if (x["real"] or x["white"]) and x["landed"] and x["own"])
    for tab in wb.sheet_names:
        for d in wb.rows(tab):
            if not wanted(d.get("type")):
                continue
            mv = d.get("move")
            rid = (str(mv).strip() if mv not in (None, "None", "") else str(d.get("input")).strip()).upper()
            evs = [r for r in tr if r["sheet"] == tab and r["row"].upper() == rid and not r["label"].startswith("control")]
            grabs = [r for r in evs if r["hold"] is not None]
            row = {"sheet": tab, "row": rid, "type": d.get("type"), "input": d.get("input"),
                   "events": [r["label"] for r in evs], "grabbed": [r["label"] for r in grabs]}
            if grabs:
                seqs = []
                for r in grabs:
                    hs = sorted(rec.get((r["sheet"], r["part"], r["label"]), []), key=lambda x: (x["frame"], x["leg"]))
                    pre = []
                    if r.get("move_start") is not None:   # the move's own records: from its start (applier legs skew <= 2)
                        pre = [x for x in hs if x["frame"] < r["move_start"] - 2]
                        hs = [x for x in hs if x["frame"] >= r["move_start"] - 2]
                    row["input_normals_landed"] = row.get("input_normals_landed", 0) + len(pre) + (r.get("falls_before_move") or 0)
                    seqs.append(([x["real"] + x["white"] for x in hs], [x["white"] for x in hs], r["meter_end"], r["press_to_hold"],
                                 r["stock_before"] - r["stock_end"] if None not in (r["stock_before"], r["stock_end"]) else None))
                row["strengths_agree"] = all(x == seqs[0] for x in seqs)
                red, white, gauge, hold, stock = seqs[0]
                row["ours"] = {"red": red, "white": white, "gauge": gauge, "press_to_hold": hold, "stock_spent": stock}
                # white over the hits that carry white: the sheet lists only non-zero whites (Midnight Bliss's 17 zero-white
                # hits and one of 9 read `9`)
                for col, key, ours in (("red", "red damage", red), ("white", "white damage", [w for w in white if w])):
                    t = parse_series(d.get(key))
                    row[col] = ("UNCOMPARABLE", f"sheet cell {d.get(key)!r}") if t is None else match_series(t, ours)
                gh = d.get("guage hit")
                gt_ = parse_series(gh)
                if row.get("input_normals_landed"):   # the input's own normals landed first and built meter too
                    row["gauge"] = ("UNCOMPARABLE", f"sheet {gh}; ours {gauge} includes the input's own normals "
                                    f"({row['input_normals_landed']} record(s) before the move's start)")
                elif gt_ is not None and all(lo == hi for _, lo, hi in gt_):   # a fixed series (`14+2x2`): its sum
                    g = sum(v * lo for v, lo, _ in gt_)
                    row["gauge"] = ("EXACT" if g == gauge else "INCONSISTENT", f"sheet {gh} (= {g:g}) ours {gauge}")
                else:
                    row["gauge"] = ("UNCOMPARABLE", f"sheet cell {gh!r}")
                try:
                    st = float(d.get("startup"))
                    row["startup"] = ("OFFSET", f"sheet {st:g} - ours {hold} = {st - hold:+g}") if hold is not None else ("-", "")
                except (TypeError, ValueError):
                    row["startup"] = ("UNCOMPARABLE", f"sheet cell {d.get('startup')!r}")
            print(json.dumps(row))


# ---------------------------------------------------------------- the gate's frozen signature (tests/audit_command_throws.sh)
def _cap_hp(cap_leg, f):
    p = os.path.join(cap_leg, f"dump_{f}_ff8850.bin")
    b = open(p, "rb").read() if os.path.exists(p) else b""
    return list(struct.unpack(">hh", b)) if len(b) == 4 else None


def _trace_hp(trace, f):
    for ln in open(trace):
        if ln.startswith(f"F {f} "):
            kv = dict(x.split("=") for x in ln.split()[2:])
            return [int(kv["p2red"]), int(kv["p2white"])]
    return None


def signature(r, recs):
    """one event's FULL numeric signature (kept OUTSIDE the tree, the frame-data ruling): press-to-hold, the move's start
    from the press, the entered chain START (signed offsets), P2's falls (count, red sum, white sum, the first fall's
    offset), P1's meter at END, and the records of both legs in frame order as leg:table:index:real/white:flags
    (frames not frozen: the two -debug legs skew by 1-2)"""
    dr = sum(d[1] for d in r["drops"]); dw = sum(d[2] for d in r["drops"])
    first = (r["drops"][0][0] - r["press"]) if r["drops"] else "-"
    rs = ";".join(f"{x['leg']}:{x['table']}:{x['idx']}:{x['real']}/{x['white']}:{x['flags']:#x}"
                  for x in sorted(recs, key=lambda x: (x["frame"], x["leg"])) if x["real"] or x["white"])
    ms = (r["move_start"] - r["press"]) if r.get("move_start") is not None else "-"
    return "\t".join(str(v) for v in (r["press_to_hold"] if r["hold"] is not None else "-", ms, r.get("entered_start", "-"),
                                       len(r["drops"]), dr, dw, first, r["meter_end"], rs))


def identity(r):
    """the event's IDENTITY, in the clear: sheet, part, label, whether P2 was HELD, the stock it spent, the move's kind
    (its own state: throw 0x0204xx, special 0x0E, ES 0x10, EX 0x12, or - when none began)"""
    spent = (r["stock_before"] - r["stock_end"]) if None not in (r["stock_before"], r["stock_end"]) else "-"
    return [r["sheet"], str(r["part"]), r["label"], "yes" if r["hold"] is not None else "no", str(spent), r.get("move_kind", "-")]


def frozen_line(r, recs):
    import hashlib
    full = signature(r, recs)
    return "\t".join(identity(r) + [hashlib.sha256(full.encode()).hexdigest()[:16]]), "\t".join(identity(r) + [full])


SIG_HEADER = ("# tests/expected/command_throws.tsv — the vsavj command throws and grabs (#229, 14z-205, fork F4; air throws: audit_ground_throws),\n"
              "# FROZEN by `tools/command_throw_rigs.py expect --freeze`. Columns: sheet part label held stock_spent move_kind sig\n"
              "# (held: P2 held, +0x134; move_kind: the move's own state, throw 0x0204xx / special 0x0E / ES 0x10 / EX 0x12 / -);\n"
              "# `sig` is the first 16 hex of SHA-256 over the event's numeric signature (tools/command_throw_rigs.py signature:\n"
              "# press-to-hold, move start, chain start, falls, meter, records): the per-move numbers are NOT in the tree —\n"
              "# the full lines are written beside the frame data, outside it (CT_FULL), and a red prints the run's own.")
FULL_DEFAULT = str(Path(__file__).resolve().parent.parent.parent / "charpages/framedata/command_throws_full.tsv")


def expect(legs_root, rigs_dir, exp_path, freeze=False, perturb=""):
    """every event: both applier legs dumped every frame [press, END]; every damaging record in the thrower's own
    attack or projectile table and LANDED on its own leg's dumps; the capture leg's P2 HP at the snap frame equal to
    the trace leg's; the signature equal to its frozen line; the event set equal to the frozen one. `perturb` applies
    one control's perturbation to what is read (the gate's controls; the mode reads the same function)."""
    rows_all, lines, fulls, bad = [], [], [], 0
    full_path = os.environ.get("CT_FULL", FULL_DEFAULT)

    def no(k, why):
        nonlocal bad
        print(f"BAD {k}: {why}"); bad += 1

    for j in sorted(Path(rigs_dir).glob("ct_*.json")):
        rig = j.stem
        rows = [json.loads(l) for l in open(Path(legs_root, rig, "trace", "rows.jsonl")) if l.strip()]
        recs = {}
        for leg in ("0189ea", "02979a"):
            ldir = Path(legs_root, rig, "p" + leg)          # the gate's leg names (p0189ea, p02979a); bare names before
            ldir = ldir if ldir.exists() else Path(legs_root, rig, leg)
            out = os.popen(f"{sys.executable} {__file__} records {j} {ldir} "
                           f"{os.environ.get('CT_IMAGE', 'build/out/vsavj_data.bin')}").read()
            for l in out.splitlines():
                x = json.loads(l)
                recs.setdefault(x["label"], {"recs": [], "short": []})
                if x["dumped"] != x["need"]:
                    recs[x["label"]]["short"].append(f"{leg} {x['dumped']}/{x['need']}")
                recs[x["label"]]["recs"] += [dict(y, leg=leg) for y in x["records"]]
        trace = Path(legs_root, rig, "trace", "t.txt")
        for r in rows:
            k = (r["sheet"], str(r["part"]), r["label"])
            rows_all.append(k)
            rr = recs.get(r["label"], {"recs": [], "short": ["no record rows"]})
            if perturb == "foreign-record":
                rr = dict(rr, recs=[dict(x, own=False) if (x["real"] or x["white"]) else x for x in rr["recs"]])
            if perturb == "phantom-record":
                dmg = [x for x in rr["recs"] if x["real"] or x["white"]]
                if dmg:
                    rr = dict(rr, recs=rr["recs"] + [dict(dmg[0], frame=r["press"] + 300, landed=False)])
            if perturb == "stock-blind":
                r = dict(r, stock_end=r["stock_before"])
            if rr["short"]:
                no(k, f"dump frames missing {rr['short']} — a leg not proven live"); continue
            alien = [x["a3"] for x in rr["recs"] if (x["real"] or x["white"]) and not x["own"]]
            if alien:
                no(k, f"damage record(s) {alien} outside the thrower's own attack and projectile tables"); continue
            unl = [f"{x['leg']}@{x['frame']}" for x in rr["recs"] if (x["real"] or x["white"]) and not x["landed"]]
            if unl:
                no(k, f"staged record(s) {unl} with no fall of P2's HP within {gt.LAND} frames — damage the victim never took"); continue
            f = snap_frame(r)
            cap = _cap_hp(Path(legs_root, rig, "cap"), f)
            tr = _trace_hp(trace, f - 1 if perturb == "cap-off-by-one" else f)
            if cap is None or cap != tr:
                no(k, f"the capture leg's P2 HP {cap} at its snap frame {f} differs from the trace leg's {tr}"); continue
            fl, full = frozen_line(r, rr["recs"])
            lines.append(fl); fulls.append(full)
    if freeze:
        if bad:
            print(f"REFUSED: {bad} event(s) failed a clause — nothing frozen"); return 1
        Path(exp_path).parent.mkdir(parents=True, exist_ok=True)
        Path(exp_path).write_text(SIG_HEADER + "\n" + "\n".join(lines) + "\n")
        Path(full_path).parent.mkdir(parents=True, exist_ok=True)
        Path(full_path).write_text("# the FULL lines behind tests/expected/command_throws.tsv's hashes (outside the tree): "
                                   "sheet part label held stock_spent move_kind press_to_hold move_start chain_start falls "
                                   "red_fall white_fall first_fall meter_end records\n" + "\n".join(fulls) + "\n")
        print(f"FROZE {exp_path} ({len(lines)} events) and {full_path}")
        return 0
    want = {tuple(l.split("\t")[:3]): l for l in open(exp_path).read().splitlines() if l and not l.startswith("#")}
    wfull = {}
    if os.path.exists(full_path):
        wfull = {tuple(l.split("\t")[:3]): l for l in open(full_path).read().splitlines() if l and not l.startswith("#")}
    seen = set()
    for l, full in zip(lines, fulls):
        k = tuple(l.split("\t")[:3]); seen.add(k)
        if want.get(k) != l:
            no(k, f"got  {l}\n    want {want.get(k)}\n    run  {full}\n    was  {wfull.get(k, '(no full line outside the tree)')}")
    for k in sorted(set(want) - set(rows_all)):
        no(k, "frozen but not measured")
    print(f"{len(lines)} event(s) checked, {bad} bad")
    return 1 if bad else 0


def main():
    a = sys.argv[1:]
    if a[:1] == ["gen"] and len(a) == 2:
        return gen(a[1])
    if a[:1] == ["fields"]:
        print(FIELDS); return 0
    if a[:1] == ["analyse"] and len(a) == 4:
        return analyse(*a[1:])
    if a[:1] == ["dumps"] and len(a) == 2:
        print(dumps_spec(json.loads(Path(a[1]).read_text()))); return 0
    if a[:1] == ["records"] and len(a) == 4:
        return records(*a[1:])
    if a[:1] == ["snaps"] and len(a) == 2:
        return snaps(a[1])
    if a[:1] == ["sheet"] and len(a) in (4, 5):
        return sheet(*a[1:])
    if a[:1] == ["rowset"] and len(a) == 2:
        return rowset(a[1])
    if a[:1] == ["join"] and len(a) == 4:
        return join(*a[1:])
    if a[:1] == ["expect"] and len(a) >= 4:
        fz = "--freeze" in a
        pt = next((x.split("=", 1)[1] for x in a if x.startswith("--perturb=")), "")
        return expect(a[1], a[2], a[3], freeze=fz, perturb=pt)
    sys.exit(__doc__)


if __name__ == "__main__":
    sys.exit(main() or 0)
