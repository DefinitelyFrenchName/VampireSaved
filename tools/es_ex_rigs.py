#!/usr/bin/env python3
"""es_ex_rigs.py — the vsavj ES SPECIALS and EX SUPERS for the community cross-check (GitHub #229, 14z-205, fork F3).

  python3 tools/es_ex_rigs.py gen <out dir>                       two rigs per vanilla character (far, near): .rpl + .json
  python3 tools/es_ex_rigs.py rows <rig.json> <trace> <vsavj_data.bin>   one JSON row per event (the measurement)
  python3 tools/es_ex_rigs.py snaps <rig.json> <rows.jsonl>       SNAP_FRAMES for the capture leg (two per event)
  python3 tools/es_ex_rigs.py sheet <out.png> <rig.json> <rows.jsonl> <snap dir>   one character's capture sheet
  python3 tools/es_ex_rigs.py rowset <workbook.xlsx>              EVENTS against the workbook's ES/EX rows, by `type`
  python3 tools/es_ex_rigs.py signature <rows.jsonl>              the identity lines a gate freezes

THE ROW SET. The workbook rows whose `type` is `es special`, `es special projectile`, `ex`, `ex projectile` or
`ex unblockable` (111 rows on the 15 sheets). One EVENT per distinct input; a row whose outcome depends on a state the
rig does not set (Lilith's Gloomy Puppet by points, Lei-Lei's three Tenraiha outcomes, Bulleta's two Cool Hunting
outcomes) shares its event with its siblings and is joined only on what the event shows. A row that needs another
family's rig shape is declared, never measured here (NOT_HERE: Demitri's ES Demon Cradle GC is a guard cancel, #229's
F5).

THE RIG (tools/vanilla_join_rig.py's forced pick and pins, tools/name_moves.py's tokens): P1 the character FORCED by
the early-window poke, P2 Victor (0x03; Demitri 0x01 when P1 is Victor), idle; REPLAY17's prologue. Two legs per
character: FAR — both fighters pinned to (552, 728) at t-40, the input at t (whiffs, projectiles); NEAR — pinned at
t-230, P1 walks right t-190..t-40 to pushbox contact, a 40-frame pause, the input at t (connects). Before each event
P1's banked stock +0x109 is poked to 9 at t-60 (an ES or EX with an empty bank degrades SILENTLY to the plain move,
[VSP-170]) and P2's two HP words to 288 at t-20 ([VSP-125]). Charge inputs charge on DOWN-BACK (DL), which counts as
back AND down and does not walk P1 away from contact.

A scripted input is not the move it names ([VSE-47]). A row is measured from what the ENGINE did, inside the event's
window from the button press: the first anim chain P1 ENTERS that was not entered before the press and is not a
baseline chain (tables a/a2/b/c decoded by tools/anim_nodes.py from the vsavj image), every chain until P1 is back on
a baseline chain, the STOCK the event paid (+0x109 at the press minus its minimum in the window), the meter fraction
+0x10A's change, P2's falls on +0x50 (the record's red) and +0x52 (red + white, the sheet's red), and the frames P1
spent on attack nodes (hbA != 0) — startup, active and recovery counted on frames, from the first entered node. A
window that enters no new chain is UNFIRED (a node outside the decoded tables counts, as `OFF:<addr>`); one that enters a chain but pays no stock is FIRED-NO-STOCK (the plain
version, or a move that is not an ES/EX). Projectiles carry their hits on an OBJECT, not on P1's nodes, so their
startup/active are not read from P1's nodes (reported `proj` when P2 fell with no P1 attack node live).
"""
import json
import os
import re
import struct
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import anim_nodes  # noqa: E402
import name_moves as nm  # noqa: E402
import vanilla_frames as vf  # noqa: E402
import vanilla_join_rig as vj  # noqa: E402

GAP = 600
FAR_LEAD = 40
NEAR_LEAD = 230
VICTIM = 0x03
FIELDS = ("ff841c:l:node,ff8410:w:p1x,ff8414:w:p1y,ff840b:b:face,ff8509:b:p1stock,ff850a:w:p1meter,"
          "ff8850:w:p2hp,ff8852:w:p2wh,ff8810:w:p2x,ff8814:w:p2y,ff8081:b:pass")

# ------------------------------------------------------------------ recipes (P1 faces RIGHT; tokens: replay grammar)
BT = {"LP": "1", "MP": "2", "HP": "3", "LK": "4", "MK": "5", "HK": "6",
      "PP": "13", "KK": "46", "PPP": "123", "LK+MK": "45", "LK+HK": "46", "MK+HK": "56", "K": "4"}


def _sh(rec, d):
    return [(a + d, b + d) + tuple(r) for (a, b, *r) in rec]


def QCF(t): return [(0, 1, "D"), (2, 3, "DR"), (4, 8, "R"), (5, 9, t)]                       # 236
def DP(t):  return [(0, 2, "R"), (4, 6, "D"), (8, 11, "DR" + t)]                             # 623
def QCB(t): return [(0, 4, "D"), (5, 9, "DL"), (10, 18, "L"), (14, 20, t)]                   # 214
# 41236 / 63214 CONTIGUOUS (14z-205 F3, measured): name_moves.hcf's one-frame release between L and DL re-reads as a
# second BACK tap, and Felicia, Bishamon, Gallon and Sasquatch BACKDASHED (P1 airborne from +9, a jump normal entered)
# — the trap name_moves.hcb_cont already names for 63214.
def HCF(t): return [(0, 3, "L"), (4, 7, "DL"), (8, 11, "D"), (12, 15, "DR"), (16, 21, "R"), (18, 22, t)]   # 41236
def HCB(t): return [(0, 3, "R"), (4, 7, "DR"), (8, 11, "D"), (12, 15, "DL"), (16, 21, "L"), (18, 22, t)]   # 63214
def HCB_GAP(t): return [(0, 2, "R"), (4, 6, "DR"), (8, 10, "D"), (12, 14, "DL"), (16, 22, "L"), (18, 22, t)]   # name_moves.hcb: in the AIR no backdash can be read
def DD(t):  return [(0, 2, "D"), (6, 9, "D" + t)]                                            # 22
def R632(t): return [(0, 2, "R"), (4, 6, "DR"), (8, 11, "D" + t)]                           # 632
def CBF(t): return [(0, 60, "DL"), (61, 64, "R" + t)]                                       # [4],6 (charged on DL)
def CDU(t): return [(0, 60, "DL"), (61, 64, "U" + t)]                                       # [2],8 (charged on DL)
def D_U(t): return [(0, 3, "D"), (5, 9, "U" + t)]                                           # 2[8]
def BF(t):  return [(0, 3, "L"), (5, 9, "R" + t)]                                           # 46
def FB(t):  return [(0, 3, "R"), (5, 9, "L" + t)]                                           # 6[4]
def DASH_DP(t): return [(0, 1, "R"), (4, 5, "R")] + _sh(DP(t), 12)                          # 66,623
def C720(t):
    ring = ["R", "DR", "D", "DL", "L", "UL", "U", "UR"]
    seq = ring + ring[:7]
    out = [(2 * i, 2 * i + 1, d) for i, d in enumerate(seq)]
    a = 2 * (len(seq) - 1)
    return out[:-1] + [(a, a + 3, seq[-1] + t)]
def SEQ(toks, gap=4): return [(i * gap, i * gap + 1, tk) for i, tk in enumerate(toks)]
def J(rec, at=12, up="U"): return [(0, 2, up)] + _sh(rec, at)                               # J.<motion>
def FOLLOW(rec, tok, at): return rec + [(at, at + 2, tok)]                                   # x~y


def START_HCF():
    r = HCF("")
    return [x for x in r if x[2]] + [(18, 22, "S1", "sys")]


# EVENTS: tab -> [(event key, [workbook move names it stands for], input as written, recipe, leg set)]
# leg set "both" = far and near; the default. Names are the workbook's own `move` cells (BI's are None: keyed by input).
E = lambda key, moves, inp, rec: (key, moves, inp, rec)
EVENTS = {
    "FE": [E("236PP", ["ES BUCKLER"], "236LPP", QCF(BT["PP"])),
           E("236LP~PP", ["ES UPPERCUT"], "236LP~PP", FOLLOW(QCF(BT["LP"]), BT["PP"], 20)),
           E("623PP", ["ES CAT SPIKE"], "623PP", DP(BT["PP"])),
           E("623KK", ["ES DELTA KICK"], "623KK", DP(BT["KK"])),
           E("22PP", ["ES TOY TOUCH"], "22PP", DD(BT["PP"])),
           E("41236PP", ["DANCING FLASH"], "412[6]PP", HCF(BT["PP"])),
           E("41236LK+MK", ["LK MK PLEASE HELP ME"], "412[6]LK+MK", HCF(BT["LK+MK"])),
           E("41236LK+HK", ["LK HK PLEASE HELP ME"], "412[6]LK+HK", HCF(BT["LK+HK"])),
           E("41236MK+HK", ["MK HK  PLEASE HELP ME"], "412[6]MK+HK", HCF(BT["MK+HK"]))],
    "AN": [E("22PP", ["ES COFFIN DANCE"], "22PP or 22KK", DD(BT["PP"])),
           E("22KK", ["ES COFFIN DANCE"], "22PP or 22KK", DD(BT["KK"])),
           E("J.236PP", ["ES ROYAL JUDGEMENT"], "J.236PP", J(QCF(BT["PP"]), up="UR")),
           E("46PP", ["ES COBRA BLOW"], "46PP", BF(BT["PP"])),
           E("41236KK", ["THE PIT TO THE UNDERWORLD"], "412[6]KK", HCF(BT["KK"])),
           E("PHARAOH", ["PHAROAH MAGIC LEVEL 1"], "HK,MP,LK,2,LP,MK,HP", SEQ(["6", "2", "4", "D", "1", "5", "3"]))],
    "AU": [E("[4]6PP", ["ES SONIC WAVE"], "[4],6PP", CBF(BT["PP"])),
           E("[4]6KK", ["ES POISION CLOUD"], "[4],6KK", CBF(BT["KK"])),
           E("623KK", ["ES TRICK FISH"], "623KK", DP(BT["KK"])),
           E("632PP", ["P AQUA SPREAD"], "632PP", R632(BT["PP"])),
           E("632KK", ["K AQUA SPREAD"], "632KK", R632(BT["KK"])),
           E("41236PP", ["SEA RAGE"], "412[6]PP", HCF(BT["PP"])),     # before Water Jail: after it, P2 was not back by the next walk-in (gap -144)
           E("623PP", ["WATER JAIL"], "623PP", DP(BT["PP"])),
           E("22PPP", ["DIRECT SCISSORS"], "22PPP", DD(BT["PPP"]))],
    "BI": [E("41236PP", [None], "412[6]PP", HCF(BT["PP"])),
           E("J.41236PP", [None], "J.412[6]PP", J(HCF(BT["PP"]))),
           E("236PP", [None], "236PP", QCF(BT["PP"])),
           E("623PP", [None], "623PP", DP(BT["PP"])),
           E("[4]6PP", [None], "[4],6PP", CBF(BT["PP"])),
           E("[4]6KK", [None], "[4],6KK", CBF(BT["KK"])),
           E("41236KK", [None], "412[6]KK", HCF(BT["KK"])),
           E("22PP", [None], "22PP", DD(BT["PP"]))],
    "BU": [E("[4]6PP", ["ES HIGH SMILE & MISSILE"], "[4],6PP", CBF(BT["PP"])),
           E("[4]6KK", ["ES LOW SMILE & MISSILE"], "[4],6KK", CBF(BT["KK"])),
           E("[2]8PP", ["ES HOP & MISSLE"], "[2]8PP", CDU(BT["PP"])),
           E("623PP", ["ES CHEER & FIRE"], "623PP", DP(BT["PP"])),
           E("214PP", ["ES SHYNESS & STRIKE"], "214PP", QCB(BT["PP"])),
           E("41236PP", ["COOL HUNTING CHARACTER", "COOL HUNTING HUNTERS"], "412[6]PP", HCF(BT["PP"])),
           E("41236KK", ["BEAUTIFUL MEMORY"], "412[6]KK", HCF(BT["KK"])),
           E("63214KK", ["APPLE FOR YOU"], "632[4]KK", HCB(BT["KK"]))],
    "DE": [E("236PP", ["ES CHAOS FLARE"], "236PP", QCF(BT["PP"])),
           E("623PP", ["ES DEMON CRADLE"], "623PP", DP(BT["PP"])),
           E("66,623PP", ["ES DASH DEMON CRADLE"], "66,623PP", DASH_DP(BT["PP"])),
           E("214KK", ["ES BAT SPIN"], "214KK", QCB(BT["KK"])),
           E("623KK", ["DEMON BILLION"], "623KK", DP(BT["KK"]))],
    "GA": [E("236PP", ["ES BEAST CANNON"], "236PP", QCF(BT["PP"])),
           E("623PP", ["ES DIAGONAL BEAST CANNON"], "623PP", DP(BT["PP"])),
           E("J.236PP", ["ES AIR BEAST CANNON"], "J.236PP", J(QCF(BT["PP"]))),
           E("2[8]KK", ["ES CLIMB RAZOR"], "2[8]KK", D_U(BT["KK"])),
           E("214PP", ["ES MILLION FLICKER"], "214PP", QCB(BT["PP"])),
           E("41236KK", ["DRAGON CANNON"], "412[6]KK", HCF(BT["KK"])),
           E("MOMENT", ["MOMENT SLICE"], "LP,MP,Towards,LK,MK", SEQ(["1", "2", "R", "4", "5"]))],
    "JE": [E("236PP", ["ES DIO SEGA"], "236PP", QCF(BT["PP"])),
           E("J.63214K~PP", ["ES IRA PINO"], "J.632[4]K~PP", FOLLOW(J(HCB(BT["K"])), BT["PP"], 50)),   # the workbook's spelling (DISPLAY)
           E("22PP", ["FINALE ROSSO"], "22PP", DD(BT["PP"]))],
    "LE": [E("236PP", ["ES ANKIHOU"], "236PP", QCF(BT["PP"])),
           E("214PP", ["ES HENKYOUKI"], "214PP", QCB(BT["PP"])),
           E("J.214PP", ["AIR ES HENKYOUKI"], "J.214PP", J(QCB(BT["PP"]))),
           E("623PP", ["ES SENPUUBU"], "623PP", DP(BT["PP"])),
           E("41236KK", ["CHIREITOU"], "412[6]KK", HCF(BT["KK"])),
           E("TENRAIHA", ["TENRAIHA ANVIL", "TENRAIHA EARTHQUAKE", "TENRAIHA SPIKED BALLS"], "LK,HK,8,MP,MP",
             SEQ(["4", "6", "U", "2", "2"])),
           E("41236PP", ["CHUUKADAN"], "412[6]PP", HCF(BT["PP"]))],
    "LI": [E("236PP", ["ES SOUL FLASH"], "236PP", QCF(BT["PP"])),
           E("J.236PP", ["AIR ES SOUL FLASH"], "J.236PP", J(QCF(BT["PP"]))),
           E("623PP", ["ES SHINING BLADE"], "623PP", DP(BT["PP"])),
           E("214KK", ["ES MERRY TURN"], "214KK", QCB(BT["KK"])),
           E("623KK", ["SPLENDOR LOVE"], "623KK", DP(BT["KK"])),
           E("LUMINOUS", ["LUMINOUS ILLUSION"], "LP,LP,Towards,LK,HP", SEQ(["1", "1", "R", "4", "3"])),
           E("J.LUMINOUS", ["AIR LUMINOUS ILLUSION"], "J.LP,LP,Towards,LK,HP", J(SEQ(["1", "1", "R", "4", "3"]))),
           E("41236KK", ["GLOOMY PUPPET 0 TO 24 POINTS", "GLOOMY PUPPET 25 TO 49  POINTS", "GLOOMY PUPPET 50 TO 74  POINTS",
                         "GLOOMY PUPPET 75 TO 94  POINTS", "GLOOMY PUPPET 95 OR MORE  POINTS"], "412[6]KK", HCF(BT["KK"]))],
    "MO": [E("236PP", ["ES SOUL FIST"], "236PP", QCF(BT["PP"])),
           E("J.236PP", ["AIR ES SOUL FIST"], "J.236PP", J(QCF(BT["PP"]))),
           E("623PP", ["ES SHADOW BLADE"], "623PP", DP(BT["PP"])),
           E("63214K~K", ["VALKYRIE TURN"], "632[4]K~K", FOLLOW(HCB(BT["K"]), BT["K"], 30)),
           E("DARKNESS", ["DARKNESS ILLUSION"], "LP,LP,Towards,LK,HP", SEQ(["1", "1", "R", "4", "3"])),
           E("J.DARKNESS", ["FINISHING SHOWER"], "J.LP,LP,Towards,LK,HP", J(SEQ(["1", "1", "R", "4", "3"])))],
    "QB": [E("214KK", ["ES DELTA A"], "214KK", QCB(BT["KK"])),
           E("J.214KK", ["AIR ES DELTA A"], "J.214KK", J(QCB(BT["KK"]))),
           E("SXP", ["HK SXP"], "K,K,K,K,HK", SEQ(["4", "4", "4", "4", "6"], 3)),
           E("J.SXP", ["AIR HK SXP"], "J.K,K,K,K,HK", J(SEQ(["4", "4", "4", "4", "6"], 3))),
           E("623PP", ["QUEEN JELLY"], "623PP", DP(BT["PP"])),
           E("J.623PP", ["AIR QUEEN JELLY"], "J.623PP", J(DP(BT["PP"]))),
           E("41236KK", ["+B"], "412[6]KK", HCF(BT["KK"])),
           E("J.41236KK", ["AIR +B"], "J.412[6]KK", J(HCF(BT["KK"])))],
    "SA": [E("236PP", ["ES BIG BREATH"], "236PP", QCF(BT["PP"])),
           E("623PP", ["ES BIG BLOW"], "623PP", DP(BT["PP"])),
           E("623KK", ["ES BIG TYPHOON"], "623KK", DP(BT["KK"])),
           E("22PP", ["ES BIG TOWERS"], "22PP", DD(BT["PP"])),
           E("41236PP", ["BIG FREEZER"], "412[6]PP", HCF(BT["PP"])),
           E("41236KK", ["BIG EISBAHN "], "412[6]KK", HCF(BT["KK"])),
           E("720KK", ["BIG SLEDGE"], "720+KK", C720(BT["KK"])),
           E("41236START", ["BIG BANANA"], "412[6]START", START_HCF())],
    "VI": [E("[4]6PP", ["ES GIGA FOREHEAD"], "[4],6PP", CBF(BT["PP"])),
           E("[2]8PP", ["ES GIGA STAKE"], "[2],8PP", CDU(BT["PP"])),
           E("623KK", ["ES GIGA BURN"], "623KK", DP(BT["KK"])),
           E("214PP", ["ES GYRO CRUSH"], "214PP", QCB(BT["PP"])),
           E("[2]8KK", ["THUNDER BREAK"], "[2],8KK", CDU(BT["KK"]))],
    "ZA": [E("214KK", ["ES DEATH HURRICANE"], "214KK", QCB(BT["KK"])),
           E("J.214KK", ["AIR ES DEATH HURRICANE"], "J.214KK", J(QCB(BT["KK"]))),
           E("2[8]KK", ["ES SKULL STING"], "2[8]KK", D_U(BT["KK"])),
           E("J.2[8]KK", ["AIR ES SKULL STING"], "J.2[8]KK", J(D_U(BT["KK"]))),
           E("6[4]PP", ["EVIL SCREAM"], "6[4]PP", FB(BT["PP"])),
           E("63214KK", ["DEATH VOLTAGE"], "632[4]KK", HCB(BT["KK"])),
           E("J.63214KK", ["AIR DEATH VOLTAGE"], "J.632[4]KK", J(HCB(BT["KK"]))),
           E("623PP", ["HELL DUNK"], "623PP", DP(BT["PP"]))],
}
# declared, not measured here: (tab, workbook move) -> why
NOT_HERE = {("DE", "ES DEMON CRADLE GC"): "a guard cancel (blockstun input): #229's guard-cancel family (fork F5)"}
FAMILY = {"es special", "es special projectile", "ex", "ex projectile", "ex unblockable"}
LEGS = ("far", "near")


def press_offset(rec):
    """The first frame of the event's BUTTON (a token carrying a digit, or the Start press)."""
    return min((a for a, b, tok, *w in rec if any(ch.isdigit() for ch in tok)), default=0)


def gen(out_dir):
    out = Path(out_dir); out.mkdir(parents=True, exist_ok=True)
    n = 0
    for tab, evs in EVENTS.items():
        cid = vf.CHARS[tab][0]
        vic = 0x01 if cid == VICTIM else VICTIM
        x1, x2 = nm.PIN["far"]
        for leg in LEGS:
            lines = [f"# #229 ES/EX rig — {tab} ({cid:#04x}) on vsavj, {leg} leg, victim {vic:#04x}",
                     "# (tools/es_ex_rigs.py gen; DO NOT hand-edit, regenerate). Select prologue from replay 17",
                     "# (the characters are FORCED by the early-window poke, so the cursor path does not matter).",
                     nm.REPLAY17_PROLOGUE.rstrip()]
            t = t0 = nm.FIRST_EVENT + (vj.WALKIN_SHIFT if leg == "near" else 0)
            sched = {"char": f"{cid:#04x}", "sheet": tab, "leg": leg, "victim": f"{vic:#04x}", "gap": GAP, "events": []}
            pokes = [f"{f}:ff8782:{cid:02x}" for f in (1400, 1450, 1500)] + [f"{f}:ff8b82:{vic:02x}" for f in (1400, 1450, 1500)]
            for key, moves, inp, rec in evs:
                if leg == "near":
                    pokes += [f"{t - NEAR_LEAD}:ff8410:{x1:04x}", f"{t - NEAR_LEAD}:ff8810:{x2:04x}"]
                    lines.append(f"{t - 190}-{t - 40} p1=R")
                else:
                    pokes += [f"{t - FAR_LEAD}:ff8410:{x1:04x}", f"{t - FAR_LEAD}:ff8810:{x2:04x}"]
                pokes += [f"{t - 60}:ff8509:09", f"{t - 20}:ff8850:01200120"]
                for a, b, tok, *who in rec:
                    lines.append(f"{t + a}-{t + b} {(who[0] if who else 'p1')}={tok}")
                sched["events"].append({"key": key, "moves": moves, "input": inp, "frame": t,
                                        "press": t + press_offset(rec)})
                t += GAP
            end = t + 100
            lines.append(f"{end} wait")
            assert end - nm.ROUND_START < 7500, f"{tab} {leg}: a rig must fit inside one round ({end - nm.ROUND_START})"
            for p in pokes:
                f = int(p.split(":")[0])
                assert f >= 1400, p
            sched["pokes"] = pokes
            sched["frames"] = end + 50
            (out / f"esex_{tab}_{leg}.rpl").write_text("\n".join(lines) + "\n")
            (out / f"esex_{tab}_{leg}.json").write_text(json.dumps(sched, indent=1) + "\n")
            n += 1
    print(f"wrote {n} rigs to {out}")


# ------------------------------------------------------------------ measurement
BASELINE = {f"a:0x{i:02x}" for i in range(0x11)}
NORMALS = {f"a2:0x{i:02x}" for i in range(0x1e)}   # the plain normals' slots (vanilla_join_rig: standing, crouching, both aerial sets)


NEGATIVE = {}   # table label -> [seq, ...] whose offset is NEGATIVE (filled by node_map, reported by `negatives`)


def walk_signed(img, table):
    """{seq: [node addr, ...]} for one anim index table, the word offsets read SIGNED, as the engine adds them (a
    68000 word add). COPIED from tools/specials_b_rigs.py walk_signed (#229 fork F2, 14z-205), which measured the
    defect: tools/anim_nodes.py walk_table reads the offsets UNSIGNED, so an entry that points BELOW its table is
    walked at table + 0xF8xx (garbage) — and in a first-claimant-wins node map that garbage can take real nodes. The
    same node rules (flags bit 7 = link at +0x18, bit 6 = hold, else sequential); the entry count bounded by the
    smallest POSITIVE offset. ESEX_UNSIGNED=1 reads them unsigned (the known-bad control).
    RESOLVED #318 (14z-210): tools/anim_nodes.py's walk_table reads the offsets SIGNED too since #318, so the
    "reads them unsigned" above describes the tool before it. This local walk stays: the frozen #229 identities
    were measured with it, and its entry bound differs from the tool's (it skips odd words instead of ending)."""
    signed = os.environ.get("ESEX_UNSIGNED") != "1"
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


def node_map(img, cid):
    """{node address: (chain 'table:seq', index, hbA high byte, dur)} over the fighter tables a2, a, b, c (a2 first,
    as vanilla_join_rig.node_map: an unterminated table-a chain runs on into a2's region), offsets read SIGNED."""
    rows = vf.bank_rows(Path(__file__).resolve().parent.parent / "build/manifest/bank_map.toml")
    out = {}
    for tn in ("a2", "a", "b", "c"):
        tbl = vf.row_ptr(img, rows["anim_index_" + tn], cid)
        for seq, nodes in walk_signed(img, tbl).items():
            if nodes and nodes[0] < tbl:
                NEGATIVE.setdefault(f"{cid:#04x} {tn}", []).append(seq)
            for i, a in enumerate(nodes):
                if a not in out:
                    out[a] = (f"{tn}:{seq:#04x}", i, img[a + 10], img[a])
    return out


def _frames(trace):
    fr = {}
    for ln in Path(trace).read_text().splitlines():
        m = re.match(r"F (\d+) (.*)", ln)
        if not m:
            continue
        kv = {}
        for part in m.group(2).split():
            if "=" in part:
                k, v = part.split("=", 1)
                try:
                    kv[k] = int(v)
                except ValueError:
                    pass
        fr[int(m.group(1))] = kv
    return fr


def rows(sched_path, trace, img_path):
    sched = json.loads(Path(sched_path).read_text())
    cid = int(sched["char"], 16)
    nmap = node_map(Path(img_path).read_bytes(), cid)
    fr = _frames(trace)
    lead = NEAR_LEAD if sched["leg"] == "near" else FAR_LEAD
    out = []
    for e in sched["events"]:
        t, p = e["frame"], e["press"]
        hi = t + sched["gap"] - lead - 5              # before the next event's pins (the RIG's gap: a sweep's is 420)
        def ch(f):
            if f not in fr or "node" not in fr[f]:
                return None
            a = fr[f]["node"] & 0xFFFFFFFF
            # a node no decoded table claims is reported by its address, never dropped (14z-205: two Sasquatch ES
            # moves paid their stock and entered nothing the map knew)
            return nmap.get(a) or (f"OFF:{a:#x}", 0, 0, 0)
        before = {c[0] for f in range(t - 30, p) for c in [ch(f)] if c}
        first, chains, run, entry = None, [], [], None
        for f in range(p, hi):
            c = ch(f)
            if c is None:
                continue
            if first is None:
                if c[0] in before or c[0] in BASELINE:
                    continue
                first, entry = c[0], f
            if c[0] in BASELINE:
                break
            if c[0] not in chains:
                chains.append(c[0])
            run.append((f, c))
        s0 = fr.get(p - 1, {}).get("p1stock")
        smin = min((fr[f]["p1stock"] for f in range(p, hi) if f in fr and "p1stock" in fr[f]), default=None)
        m0 = fr.get(p - 1, {}).get("p1meter")
        m1 = fr.get(hi - 1, {}).get("p1meter")
        # P2's falls, per frame, on both HP words (re-pinned to 288 at t-20, before the press)
        falls = []
        for f in range(p, hi):
            a, b = fr.get(f - 1, {}), fr.get(f, {})
            if "p2hp" in a and "p2hp" in b:
                d50, d52 = a["p2hp"] - b["p2hp"], a["p2wh"] - b["p2wh"]
                if (d50 > 0 or d52 > 0) and d50 < 200 and d52 < 200:
                    falls.append((f - p, d50, d52))
        # THE MOVE: the first chain in the window that is neither baseline, nor seen before the press, nor a PLAIN
        # NORMAL (a2:0x00-0x1d) — a button-sequence super (LP,LP,6,LK,HP) enters the first button's normal before it
        # (14z-205 F3: Pharaoh Magic, Moment Slice and both Illusions read `a2:0x00`/`0x0a` as their first chain)
        move, mentry, mrun = None, None, []
        for f in range(p, hi):
            c = ch(f)
            if c is None:
                continue
            if move is None:
                if c[0] in before or c[0] in BASELINE or c[0] in NORMALS:
                    continue
                move, mentry = c[0], f
            if c[0] in BASELINE:
                break
            mrun.append((f, c))
        if move is not None and move != first:
            run, entry = mrun, mentry
        atk = [i for i, (f, c) in enumerate(run) if c[2]]
        dur = {}
        if run:
            dur["frames"] = len(run)
            dur["latency"] = entry - p
            if atk:
                dur.update(startup=atk[0], active=sum(1 for f, c in run if c[2]), span=atk[-1] - atk[0] + 1,
                           recovery=len(run) - atk[-1] - 1)
        # ENGINE TICKS (14z-205 follow-up): RAM:$FF8081, the game task's PASS counter (+1 per logic pass, +2 on a
        # turbo double-pass frame), mod 256, between frame boundaries — the unit the page compares timing in (its
        # pursuits: "Frame data in ENGINE TICKS"); the method of tools/specials_b_rigs.py `passes` (#229 F2), so the
        # forks count alike. From the MOVE's entry; the move ENDS at the return to idle (a:0x00 two frames running,
        # F2's rule: a move may pass through baseline chains on its way); each boundary is read at frame
        # resolution, so a node change inside a double-pass frame is +-1 tick. Also the DURATION BYTES along the
        # observed path (the page's confirmed instrument for normals). These fields are REPORTED, never frozen.
        tick = {}
        st = mentry if mentry is not None else entry
        if st is not None:
            pas = lambda a, b: (None if "pass" not in fr.get(a, {}) or "pass" not in fr.get(b, {})
                                else (fr[b]["pass"] - fr[a]["pass"]) % 256)
            cha = lambda f: ch(f)[0] if ch(f) else None
            stop = next((f for f in range(st, hi) if cha(f) == "a:0x00" and cha(f + 1) == "a:0x00"), hi)
            act = [f for f in range(st, stop) if ch(f) and ch(f)[2]]
            tick["frames_t"] = pas(st, stop)
            if act:
                tick.update(startup_t=pas(st, act[0]), active_t=pas(act[0], act[-1] + 1), recovery_t=pas(act[-1] + 1, stop))
                # a double-pass frame can walk a 1-tick node unseen: a gap between two observations inside ONE chain
                # is filled with that chain's own nodes in order (as F2's analyse does)
                order = {}
                for a_, v in nmap.items():
                    order.setdefault(v[0], {})[v[1]] = v
                path, prev = [], None
                for f in range(st, stop):
                    n = fr.get(f, {}).get("node")
                    if n is None or n == prev:
                        continue
                    prev = n
                    cur = nmap.get(n & 0xFFFFFFFF, (None, 0, 0, 0))
                    if path and cur[0] and path[-1][0] == cur[0] and cur[1] > path[-1][1] + 1:
                        path += [order[cur[0]][i] for i in range(path[-1][1] + 1, cur[1]) if i in order[cur[0]]]
                    path.append(cur)
                hbs = [x[2] for x in path]
                i0 = next(i for i, h in enumerate(hbs) if h)
                i1 = len(hbs) - 1 - next(i for i, h in enumerate(hbs[::-1]) if h)
                tick.update(startup_d=sum(x[3] for x in path[:i0]), active_d=sum(x[3] for x in path[i0:i1 + 1] if x[2]))
        y0 = fr.get(t - 5, {}).get("p1y")
        yp = fr.get(p, {}).get("p1y")
        paid = not (s0 is None or smin is None or s0 - smin <= 0)
        status = ("UNFIRED" if first is None else "FIRED-NO-STOCK" if not paid else
                  "FIRED" if move is not None else "PAID-NORMAL-ONLY")
        out.append({"sheet": sched["sheet"], "leg": sched["leg"], "key": e["key"], "moves": e["moves"], "input": e["input"],
                    "frame": t, "press": p, "status": status, "first": first, "move": move,
                    "move_at": None if mentry is None else mentry - p, "chains": chains,
                    "stock_before": s0, "stock_paid": None if s0 is None or smin is None else s0 - smin,
                    "meter_change": None if m0 is None or m1 is None else m1 - m0,
                    "meter_change_from_move": (None if m1 is None or fr.get((mentry if mentry is not None else p) - 1, {}).get("p1meter") is None
                                               else m1 - fr[(mentry if mentry is not None else p) - 1]["p1meter"]),
                    "airborne": None if y0 is None or yp is None else yp != y0,
                    "falls": falls, "dur": dur, "tick": tick, "face": fr.get(p, {}).get("face"),
                    "gap_px": None if p not in fr else fr[p].get("p2x", 0) - fr[p].get("p1x", 0)})
    for r in out:
        print(json.dumps(r))


APPLIERS = ("0189ea", "02979a")   # the fighter applier and the object-hit applier (projectiles), as ground_throw_rigs


def records(sched_path, legdir, img_path):
    """Per event, every record a probe leg's logging breakpoint saw at each applier inside the event window: the
    frame from the press, the applier, A3, and A3's power CLASSES (+8 real, +9 white; hitbox_records.power, #241)
    with the no-kill flag. The leg dirs are <legdir>/<applier>/run.log. A probe stop can move the game ([MFI-2]), so
    a record list is compared with the trace leg's falls by COUNT, never by frame."""
    sys.path.insert(0, str(Path(__file__).resolve().parent))
    import hitbox_records as hr
    sched = json.loads(Path(sched_path).read_text())
    img = Path(img_path).read_bytes()
    lead = NEAR_LEAD if sched["leg"] == "near" else FAR_LEAD
    probes = {}
    for ap in APPLIERS:
        lg = Path(legdir) / ap / "run.log"
        ended = lg.exists() and any(l.startswith("END ") for l in open(lg, errors="replace"))
        probes[ap] = ([], ended)
        if not lg.exists():
            continue
        for line in open(lg, errors="replace"):
            if line.startswith("PROBE "):
                f = int(line.split()[1])
                a3 = next((int(x[3:], 16) for x in line.split() if x.startswith("A3=")), None)
                if a3 is not None:
                    probes[ap][0].append((f, a3))
    for e in sched["events"]:
        p, hi = e["press"], e["frame"] + sched["gap"] - lead - 5
        recs = []
        for ap in APPLIERS:
            for f, a3 in probes[ap][0]:
                if p <= f < hi and 0 <= a3 < len(img) - 0x20:
                    r, w = hr.power(img[a3 + 8]), hr.power(img[a3 + 9])
                    recs.append({"rel": f - p, "applier": ap, "a3": f"{a3:#x}", "real": r["class"], "white": w["class"],
                                 "nokill": r["nokill"] or w["nokill"]})
        recs.sort(key=lambda x: x["rel"])
        print(json.dumps({"sheet": sched["sheet"], "leg": sched["leg"], "key": e["key"],
                          "ended": {ap: probes[ap][1] for ap in APPLIERS}, "records": recs}))


def freeze(rows_path, recs_path):
    """The gate's frozen line per event: sheet, leg, key, status, the MOVE chain, the first chain, the stock paid,
    the number of staged records from the move's entry, and a HASH of that record list (applier, real and white
    class, no-kill, in frame order). Per-move damage values never enter a tracked file (frame data stays out of the
    tree): the hash pins them without stating them; the values are in the measurement's own build dir."""
    import hashlib
    recs = {(r["sheet"], r["leg"], r["key"]): r["records"] for r in map(json.loads, open(recs_path))}
    for r in map(json.loads, open(rows_path)):
        mv = r.get("move_at") or 0
        rc = [x for x in recs[(r["sheet"], r["leg"], r["key"])] if x["rel"] >= mv - 1]
        h = hashlib.sha1(";".join(f"{x['applier']}:{x['real']}/{x['white']}:{int(x['nokill'])}" for x in rc).encode()).hexdigest()[:12]
        print("\t".join([r["sheet"], r["leg"], r["key"], r["status"], r.get("move") or "-", r["first"] or "-",
                         str(r["stock_paid"]), str(len(rc)), h if rc else "-"]))


def signature(rows_path):
    """The identity a gate freezes: per (sheet, leg, key) the status, the first chain, the chains in order and the
    stock paid. Damage and frame counts are reported, not frozen here (they are what the cross-check compares)."""
    for ln in open(rows_path):
        r = json.loads(ln)
        print("\t".join([r["sheet"], r["leg"], r["key"], r["status"], r["move"] or "-", r["first"] or "-",
                         str(r["stock_paid"])]))


def snaps(sched_path, rows_path):
    """Two snapshot frames per event: the first fall (else chain entry + 20) and 30 frames later."""
    sched = json.loads(Path(sched_path).read_text())
    by = {json.loads(l)["key"]: json.loads(l) for l in open(rows_path) if l.strip()}
    out = []
    for e in sched["events"]:
        r = by.get(e["key"])
        if not r:
            continue
        mv = r.get("move_at") or 0                    # from the MOVE's entry, never a leading normal's hit
        falls = [f for f in r["falls"] if f[0] >= mv]
        if falls:
            a = r["press"] + falls[0][0]
        elif r["status"] != "UNFIRED":
            a = r["press"] + mv + 20
        else:
            a = r["press"] + 20
        out += [a, a + 30]
    print(",".join(map(str, out)))


def sheet(out_png, sched_path, rows_path, snap_dir):
    from PIL import Image, ImageDraw
    sched = json.loads(Path(sched_path).read_text())
    rws = [json.loads(l) for l in open(rows_path) if l.strip()]
    frames = [int(x) for x in __import__("subprocess").run([sys.executable, __file__, "snaps", sched_path, rows_path],
                                                          capture_output=True, text=True).stdout.strip().split(",") if x]
    shots = sorted(Path(snap_dir).rglob("*.png"))
    if len(shots) != len(frames):
        sys.exit(f"sheet: {len(shots)} snapshots for {len(frames)} frames")
    by = {r["key"]: r for r in rws}
    tiles = []
    for i, e in enumerate(sched["events"]):
        r = by[e["key"]]
        for j in range(2):
            fno = frames[2 * i + j]
            nm_ = (DISPLAY.get(str(e["moves"][0]), str(e["moves"][0])) + (f" (+{len(e['moves']) - 1} rows)" if len(e["moves"]) > 1 else "")) if any(e["moves"]) else e["input"]
            lab = f"{sched['sheet']} {nm_} [{e['key']}] {r['status']} {r['move'] or '-'} st{r['stock_paid']} f{fno} (+{fno - e['press']})"
            tiles.append((lab, Image.open(shots[2 * i + j]).convert("RGB")))
    w, h = tiles[0][1].size
    cols = 4
    nrow = (len(tiles) + cols - 1) // cols
    im = Image.new("RGB", (cols * (w + 8) + 8, nrow * (h + 22) + 8), (20, 20, 20))
    d = ImageDraw.Draw(im)
    for i, (lab, t) in enumerate(tiles):
        x, y = 8 + (i % cols) * (w + 8), 8 + (i // cols) * (h + 22)
        d.text((x, y), lab, fill=(255, 255, 255))
        im.paste(t, (x, y + 14))
    im.save(out_png)
    print(f"wrote {out_png} ({len(tiles)} snapshots)")


def rowset(xlsx):
    import xlsx_read
    wb = xlsx_read.Workbook(xlsx)
    got = []
    for tab in wb.sheet_names:
        for d in wb.rows(tab):
            t = (d.get("type") or "").strip().lower()
            if t in FAMILY:
                got.append((tab, d.get("move"), str(d.get("input"))))
    ours = {}
    for tab, evs in EVENTS.items():
        for key, moves, inp, rec in evs:
            for mv in moves:
                ours.setdefault((tab, mv, inp), []).append(key)
    bad = 0
    seen = set()
    for tab, mv, inp in got:
        k = (tab, mv, inp)
        if (tab, mv) in NOT_HERE:
            print(f"DECLARED not measured here: {tab} {mv!r} — {NOT_HERE[(tab, mv)]}")
            continue
        if k not in ours:
            print(f"MISSING from the rigs: {tab} {mv!r} {inp!r}"); bad = 1
        seen.add(k)
    for k in ours:
        if k not in seen:
            print(f"NOT IN the workbook: {k}"); bad = 1
    print(f"workbook ES/EX rows {len(got)}; events {sum(len(v) for v in EVENTS.values())}; rows mapped {len(seen)}")
    return bad


# ------------------------------------------------------------------ the INPUT SWEEP
# For an event whose recipe fired the plain version (no stock paid) or nothing, the far leg is run with several
# input variants as separate events; the engine says which one fires the move (stock paid, a chain that is not the
# plain version's). The variant chosen is recorded beside the event (CHOSEN), never assumed.
def _dd(t):
    return {"dd1": [(0, 1, "D"), (3, 5, "D" + t)],
            "dd2": [(0, 2, "D"), (5, 8, "D"), (7, 9, t)],
            "dd3": [(0, 3, "D"), (7, 10, "D"), (9, 11, t)],
            "dd4": [(0, 1, "D"), (4, 5, "D"), (6, 7, t)],
            "dd5": [(0, 2, "D"), (4, 6, "D" + t)],
            "dd6": [(0, 1, "D"), (3, 4, "D" + t)],
            "dd7": [(0, 1, "D"), (2, 3, "D"), (4, 5, t)]}


def _dp(t):
    return {"dp1": [(0, 2, "R"), (3, 5, "D"), (6, 9, "DR" + t)],
            "dp2": [(0, 2, "R"), (3, 4, "DR"), (5, 6, "D"), (7, 10, "DR" + t)],
            "dp3": [(0, 3, "R"), (4, 7, "D"), (8, 11, "DR"), (10, 13, t)],
            "r632": R632(t), "qcf": QCF(t), "hcb": HCB(t), "hcf": HCF(t)}


def _632(t):
    return {"a1": [(0, 2, "R"), (3, 5, "DR"), (6, 9, "D" + t)],
            "a2": [(0, 2, "R"), (3, 5, "DR"), (6, 8, "D"), (9, 11, t)],
            "a3": [(0, 2, "R"), (3, 5, "DR"), (6, 8, "D"), (9, 12, "DL" + t)],
            "a4": HCB(t),
            "a5": [(0, 2, "R"), (3, 5, "DR"), (6, 8, "D"), (9, 12, "DR" + t)],
            "a6": [(0, 3, "R"), (4, 7, "DR"), (8, 12, "D"), (10, 13, t)]}


def _seq(toks):
    return {f"g{g}h{h}": [(i * g, i * g + h - 1, tk) for i, tk in enumerate(toks)] for g in (2, 3, 5, 6) for h in (1, 2) if h < g}


def _720(t):
    ring = ["R", "DR", "D", "DL", "L", "UL", "U", "UR"]
    v = {}
    for name, start in (("r", 0), ("d", 2)):
        seq = (ring[start:] + ring[:start]) * 2
        seq = seq[:15]
        v[f"{name}1"] = [(i, i, d) for i, d in enumerate(seq[:-1])] + [(14, 16, seq[-1] + t)]
        v[f"{name}2"] = [(2 * i, 2 * i + (0 if "U" in d else 1), d) for i, d in enumerate(seq[:-1])] + [(28, 31, seq[-1] + t)]
    return v


VARIANTS = {
    ("AN", "22PP"): _dd(BT["PP"]), ("AN", "22KK"): _dd(BT["KK"]), ("AU", "22PPP"): _dd(BT["PPP"]),
    ("BI", "22PP"): _dd(BT["PP"]), ("FE", "22PP"): _dd(BT["PP"]), ("JE", "22PP"): _dd(BT["PP"]),
    ("SA", "22PP"): _dd(BT["PP"]),
    ("BI", "623PP"): _dp(BT["PP"]),
    ("DE", "623KK"): {**_dp(BT["KK"]), **{f"{k}_45": v for k, v in _dp("45").items() if k in ("dp1", "r632")},
                      **{f"{k}_56": v for k, v in _dp("56").items() if k in ("dp1", "r632")}},
    ("AU", "632PP"): _632(BT["PP"]), ("AU", "632KK"): _632(BT["KK"]),
    ("BI", "236PP"): {"p13": QCF("13"), "p12": QCF("12"), "p23": QCF("23"), "p123": QCF("123"),
                      "slow13": [(0, 3, "D"), (4, 7, "DR"), (8, 12, "R"), (10, 13, "13")]},
    ("FE", "236LP~PP"): {f"f{a}": FOLLOW(QCF(BT["LP"]), BT["PP"], a) for a in (8, 12, 16, 26, 32, 40)},
    ("JE", "J.63214K~PP"): {**{f"f{a}": FOLLOW(J(HCB_GAP(BT["K"])), BT["PP"], a) for a in (36, 42, 58, 66, 76)},
                            **{f"c{a}": FOLLOW(J(HCB(BT["K"])), BT["PP"], a) for a in (42, 58)}},
    ("LE", "TENRAIHA"): _seq(["4", "6", "U", "2", "2"]),
    ("QB", "SXP"): {"m4": SEQ(["4", "4", "4", "4", "6"], 2), "m45": SEQ(["4", "5", "4", "5", "6"], 2),
                    "m456": SEQ(["456", "456", "456", "456", "6"], 2), "m4x8": SEQ(["4"] * 8 + ["6"], 2),
                    "m45x3": SEQ(["4", "5", "4", "5", "6"], 3), "m5x6": SEQ(["5"] * 6 + ["6"], 2)},
    ("QB", "J.SXP"): {"m45": J(SEQ(["4", "5", "4", "5", "6"], 2)), "m456": J(SEQ(["456", "456", "456", "456", "6"], 2)),
                      "m4x8": J(SEQ(["4"] * 8 + ["6"], 2))},
    ("SA", "720KK"): _720(BT["KK"]),
    ("ZA", "J.63214KK"): {"gap": J(HCB_GAP(BT["KK"])), "gap14": J(HCB_GAP(BT["KK"]), at=14), "gap10": J(HCB_GAP(BT["KK"]), at=10)},
}
# the SECOND sweep (after the first): the grabs at contact (near), and wider input families
VARIANTS2 = {
    ("BI", "22PP", "near"): _dd(BT["PP"]),
    ("FE", "22PP", "near"): _dd(BT["PP"]),
    ("DE", "623KK", "far"): {"41236": HCF(BT["KK"]), "22": _dd(BT["KK"])["dd2"], "214": QCB(BT["KK"]),
                             "236_45": QCF("45"), "236_56": QCF("56"), "j623": J(DP(BT["KK"])),
                             "j236": J(QCF(BT["KK"])), "623_btn_after": [(0, 2, "R"), (3, 5, "D"), (6, 9, "DR"), (10, 12, BT["KK"])]},
    ("FE", "236LP~PP", "near"): {f"es{a}": FOLLOW(QCF(BT["PP"]), BT["PP"], a) for a in (12, 20, 30)} |
                                {f"lp{a}": FOLLOW(QCF(BT["LP"]), BT["PP"], a) for a in (14, 22)},
    ("JE", "J.63214K~PP", "far"): {"jkk": J(HCB_GAP(BT["KK"])), "jk_kk40": FOLLOW(J(HCB_GAP(BT["K"])), BT["KK"], 42),
                                   "jpp": J(HCB_GAP(BT["PP"])), "jk_pp30": FOLLOW(J(HCB_GAP(BT["K"])), BT["PP"], 30),
                                   "jk_pp50h": [(0, 2, "U")] + _sh(HCB_GAP(BT["K"]), 12) + [(50, 56, BT["PP"])]},
    ("LE", "TENRAIHA", "far"): {"hold3": [(0, 2, "4"), (3, 5, "6"), (6, 8, "U"), (9, 11, "2"), (13, 15, "2")],
                                "chord": [(0, 2, "4"), (2, 4, "46"), (5, 7, "U"), (8, 9, "2"), (11, 12, "2")],
                                "slow8": SEQ(["4", "6", "U", "2", "2"], 8), "fast1": SEQ(["4", "6", "U", "2", "2"], 1)},
    ("QB", "SXP", "far"): {"kk": SEQ(["46", "46", "46", "46", "6"], 3), "k6": SEQ(["4", "5", "6", "4", "5", "6"], 2),
                           "hk5": SEQ(["6"] * 5, 2), "lk6": SEQ(["4"] * 4 + ["46"], 2)},
    ("BI", "236PP", "far"): {**{f"shift{d}": _sh(QCF(BT["PP"]), d) for d in range(0, 6)},
                             **{f"hold4_shift{d}": _sh([(0, 1, "D"), (2, 3, "DR"), (4, 9, "R"), (5, 9, BT["PP"])], d) for d in range(0, 3)}},
    ("SA", "720KK", "far"): {"noU": [(i, i, d) for i, d in enumerate(["R", "DR", "D", "DL", "L", "UL", "UR", "R", "DR", "D", "DL", "L", "UL"])] + [(13, 16, "UR46")],
                             "noU2": [(2 * i, 2 * i + 1, d) for i, d in enumerate(["R", "DR", "D", "DL", "L", "UL", "UR", "R", "DR", "D", "DL", "L", "UL"])] + [(26, 29, "UR46")],
                             "noU_end_r": [(i, i, d) for i, d in enumerate(["L", "DL", "D", "DR", "R", "UR", "UL", "L", "DL", "D", "DR", "R", "UR"])] + [(13, 16, "UL46")]},
}
# THE INPUTS THE SWEEPS CHOSE (14z-205 F3, build/agent205/t229/f3_es_ex/sweep_reanalysed.out): (tab, first key) ->
# (key, recipe, why). A variant is chosen only when it PAID stock and its first chain is not a plain normal
# (a2:0x00-0x1d); the first-listed of equal variants is taken.
CHOSEN = {
    ("AN", "22PP"): ("22PP", _dd(BT["PP"])["dd2"], "dd2: D 0-2, D 5-8, buttons 7-9 (a press WITH the second D is a crouching normal)"),
    ("AN", "22KK"): ("22KK", _dd(BT["KK"])["dd2"], "dd2"),
    ("AU", "22PPP"): ("22PPP", _dd(BT["PPP"])["dd2"], "dd2"),
    ("JE", "22PP"): ("22PP", _dd(BT["PP"])["dd2"], "dd2"),
    ("SA", "22PP"): ("22PP", _dd(BT["PP"])["dd2"], "dd2"),
    ("AU", "632PP"): ("632PP", _632(BT["PP"])["a1"], "a1: R 0-2, DR 3-5, D+buttons 6-9 contiguous"),
    ("AU", "632KK"): ("632KK", _632(BT["KK"])["a1"], "a1"),
    ("ZA", "J.63214KK"): ("J.63214KK", J(HCB_GAP(BT["KK"])), "the gapped 63214 in the air (the contiguous one enters a jump normal)"),
    # NOT AN IDENTIFICATION (corrected the same session): the ES Buckler ALONE enters a2:0x3c -> 0x3d -> 0x3f, so this
    # follow-up enters no chain of its own and is the ES Buckler again; the sheet's 236LP~PP never pays. ES UPPERCUT
    # stays UNRESOLVED (UNRESOLVED below); the event is kept so the gate freezes what the input does.
    ("FE", "236LP~PP"): ("236PP~PP", FOLLOW(QCF(BT["PP"]), BT["PP"], 20),
                         "the sheet's 236LP~PP never pays; 236PP~PP pays but enters the ES Buckler's own chains"),
    # CORRECTED 14z-205c (#229; the maintainer on the capture: "What  I see is ES Ira Spinta (J.6324+KK) not the ES
    # follow-up."): J.63214KK alone pays into a2:0x36>0x37>0x39>0x65>0x66, ES IRA SPINTA (the workbook's JE row 24, a
    # command throw: F4's family), so 14z-205's choice joined this row to the wrong move. The ES Piano is that KK then
    # the PP follow-up: it pays into 0x36>0x68>0x6a>0x6b (P2, build/agent205/t229/p2_es_ex/REPORT.md section 7: +36 to
    # +60, far and near; +44 is the offset P2 ran on both legs).
    ("JE", "J.63214K~PP"): ("J.63214KK~PP", FOLLOW(J(HCB_GAP(BT["KK"])), BT["PP"], 44),
                            "the sheet's J.632[4]K~PP never pays at any follow-up offset; J.63214+KK alone is ES Ira "
                            "Spinta; J.63214+KK then PP at +44 pays into Piano's chains"),
}
# OUR display names where the workbook's own spelling is a typo: the workbook spells JE row 26 "ES IRA PINO" (the move
# is ES Ira Piano, JE row 25 "IRA PIANO"; the maintainer, 14z-205c: "Ira Pino is a typo, it should be Ira Piano").
# The workbook key stays verbatim in EVENTS (rowset joins on it); the sheets print DISPLAY's name.
DISPLAY = {"ES IRA PINO": "ES IRA PIANO (workbook: ES IRA PINO)"}
# the events no input found (both sweeps, build/agent205/t229/f3_es_ex/sweep_reanalysed.out): (tab, key) -> why
UNRESOLVED = {
    ("BI", "22PP"): "every 22 timing (7, far and near) enters a crouching LP and pays nothing",
    ("BI", "236PP"): "enters a2:0x1e and pays nothing at every phase shift 0-5 and hold (9 variants)",
    ("BI", "623PP"): "every 623 timing enters a crouching LP; the 63214/41236 variants pay but are other moves",
    ("DE", "623KK"): "every 623+KK timing and pair enters a crouching kick; 21 variants, none enters a new chain and pays",
    ("FE", "22PP"): "every 22 timing (7, far and near) enters a crouching LP and pays nothing",
    ("FE", "236PP~PP"): "the sheet's 236LP~PP never pays; 236PP~PP enters only the ES Buckler's chains",
    ("LE", "TENRAIHA"): "LK,HK,8,MP,MP at gaps 1-8, holds 1-3 and a chord: a standing LK, nothing paid",
    ("QB", "SXP"): "K,K,K,K,HK as mashes of 4-9 presses at gaps 2-3, any kicks: a standing normal, nothing paid",
    ("QB", "J.SXP"): "the same in the air: a jump normal, nothing paid",
    ("SA", "720KK"): "every 720 (7 variants, with and without a pure U) makes Sasquatch JUMP; nothing paid",
}
# an UNRESOLVED event that PAYS but enters only another event's chains (so it is that move again): (tab, key) -> the
# other event's key; the gate asserts the two read the same chains on each leg
SAME_AS = {("FE", "236PP~PP"): "236PP"}
for (tab, k0), (k1, rec, why) in CHOSEN.items():
    evs = EVENTS[tab]
    i = next(i for i, e in enumerate(evs) if e[0] == k0)
    evs[i] = (k1, evs[i][1], evs[i][2], rec)
SWEEP_GAP = 420


def gen_sweep(out_dir, second=False):
    out = Path(out_dir); out.mkdir(parents=True, exist_ok=True)
    table = {(tb, key, leg): vs for (tb, key, leg), vs in VARIANTS2.items()} if second else \
        {(tb, key, "far"): vs for (tb, key), vs in VARIANTS.items()}
    n = 0
    for tab, leg in sorted({(tb, lg) for tb, _, lg in table}):
        cid = vf.CHARS[tab][0]
        vic = 0x01 if cid == VICTIM else VICTIM
        x1, x2 = nm.PIN["far"]
        evs = [(f"{key}#{lab}", key, rec) for (tb, key, lg), vs in table.items() if tb == tab and lg == leg for lab, rec in vs.items()]
        per = 8 if leg == "near" else 14          # a part must fit inside one round
        for part in range((len(evs) + per - 1) // per):
            chunk = evs[part * per:(part + 1) * per]
            lines = [f"# #229 ES/EX INPUT SWEEP — {tab} ({cid:#04x}) on vsavj, {leg} leg, part {part}",
                     "# (tools/es_ex_rigs.py sweep; DO NOT hand-edit, regenerate).", nm.REPLAY17_PROLOGUE.rstrip()]
            t = t0 = nm.FIRST_EVENT + (vj.WALKIN_SHIFT if leg == "near" else 0)
            gap = GAP if leg == "near" else SWEEP_GAP
            sched = {"char": f"{cid:#04x}", "sheet": tab, "leg": leg, "victim": f"{vic:#04x}", "gap": gap, "events": []}
            pokes = [f"{f}:ff8782:{cid:02x}" for f in (1400, 1450, 1500)] + [f"{f}:ff8b82:{vic:02x}" for f in (1400, 1450, 1500)]
            for ek, key, rec in chunk:
                if leg == "near":
                    pokes += [f"{t - NEAR_LEAD}:ff8410:{x1:04x}", f"{t - NEAR_LEAD}:ff8810:{x2:04x}"]
                    lines.append(f"{t - 190}-{t - 40} p1=R")
                else:
                    pokes += [f"{t - FAR_LEAD}:ff8410:{x1:04x}", f"{t - FAR_LEAD}:ff8810:{x2:04x}"]
                pokes += [f"{t - 60}:ff8509:09", f"{t - 20}:ff8850:01200120"]
                for a, b, tok, *who in rec:
                    lines.append(f"{t + a}-{t + b} {(who[0] if who else 'p1')}={tok}")
                sched["events"].append({"key": ek, "moves": [], "input": key, "frame": t, "press": t + press_offset(rec)})
                t += gap
            end = t + 100
            lines.append(f"{end} wait")
            assert end - nm.ROUND_START < 7500, (tab, part)
            sched["pokes"] = pokes
            sched["frames"] = end + 50
            (out / f"sweep_{tab}_{leg}_{part}.rpl").write_text("\n".join(lines) + "\n")
            (out / f"sweep_{tab}_{leg}_{part}.json").write_text(json.dumps(sched, indent=1) + "\n")
            n += 1
    print(f"wrote {n} sweep rigs to {out}")


def main():
    a = sys.argv[1:]
    if a[:1] == ["gen"] and len(a) == 2:
        return gen(a[1])
    if a[:1] == ["sweep"] and len(a) == 2:
        return gen_sweep(a[1])
    if a[:1] == ["sweep2"] and len(a) == 2:
        return gen_sweep(a[1], second=True)
    if a[:1] == ["rows"] and len(a) == 4:
        return rows(*a[1:])
    if a[:1] == ["snaps"] and len(a) == 3:
        return snaps(*a[1:])
    if a[:1] == ["sheet"] and len(a) == 5:
        return sheet(*a[1:])
    if a[:1] == ["rowset"] and len(a) == 2:
        return rowset(a[1])
    if a[:1] == ["records"] and len(a) == 4:
        return records(*a[1:])
    if a[:1] == ["freeze"] and len(a) == 3:
        return freeze(a[1], a[2])
    if a[:1] == ["signature"] and len(a) == 2:
        return signature(a[1])
    sys.exit(__doc__)


if __name__ == "__main__":
    sys.exit(main() or 0)
