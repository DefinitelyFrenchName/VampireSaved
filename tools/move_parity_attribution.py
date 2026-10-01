#!/usr/bin/env python3
"""move_parity_attribution.py — ATTRIBUTE EVERY DIFF ROW OF THE #136 MOVE-PARITY TABLE (14z-168).

tests/audit_move_parity.sh judges each event of each naming-rig part in its own window, ours vs
native vs2, but a DIFF after an earlier DIFF in the same part may be DOWNSTREAM of it (the frozen
`coupled` column). This tool separates the causes by ABLATION and names each root by a MEASURED
SIGNATURE:

  step 0  the committed rigs, both legs; the verdict rows must equal the frozen table
          (tests/expected/move_parity_events.tsv) for every part it runs — else the build or
          the rigs moved and nothing below is evidence (VOID).
  step E  THE OPENING FIX: a part whose first X pin ($FF8410) lands before the round start
          (2545, docs/game/engine_internals.md "The round-start ENTRANCE") is regenerated with
          its first event at 2800; rows that vanish are class ENTRANCE (a rig artifact).
  step N  ITERATIVE ABLATION: for every part still carrying a DIFF, the first DIFF event's INPUTS
          are removed (tools/name_moves.gen with that recipe emptied — every other event's frame,
          pin and poke unchanged) and both legs re-run; rows that vanish are that root's.
          A part's root may be SEEDED (SEED below) when the table cannot see it. donovan_3's was
          seeded at event 5 (Killshread Summon (ES), GitHub #159: its own fields read IDENT because
          P2's x is not compared) until the M21 freeze (14z-185) landed #159's fix: the seeded root
          then read no P2-x difference from native in its window (class OTHER), on merged-m21 and on
          the #159-only probe alike, where the #182-only probe still read P2-DISPLACEMENT — and the
          seed was retired.
  classify each root on the traces of the step where it was still a DIFF (see SIGNATURES).

SIGNATURES (each a measured property of the root's own window, never its name alone):
  SLOWDOWN       a zero-pass frame (RAM:$FF8081 does not step) on exactly one leg, at or before
                 the first DIFF frame — a CPU-budget overrun (engine timing, not a port cost)
  METER-SWAP     on the first frame the gauge steps differ, native pays (a, b) to (P1, P2) and
                 ours (b, a), a != b — GitHub #157
  DF-STOCK       a Dark Force activation whose first DIFF (+0) carries `stock` — the ruled cost
                 (DECISIONS_HISTORY.md "DARK FORCE STOCK COST FOR THE TENANTS")
  TRAP-REMAP     P2's reaction class 0x52 natively, 0x06 on ours, on a Phobos part — the 14z-85g(2)
                 remap, recorded "DECIDED (maintainer, 2026-08-14): OPTION (a)" (STATE_HISTORY.md
                 "Decisions — 14z-85g(2)"; the maintainer's own words were not kept); its attacker-freeze
                 deviation WITHDRAWN 2026-09-18 — the class takes vs2's 0x52 rule (tests/audit_trap_shock.sh)
  COLUMN-SHOCK   the same class pair on a Donovan part — the column's 14z-33 remap meeting the
                 14z-42 Lightning Sword thunks (tests/audit_column_shock.sh)
  REACTION-51-OPEN P2's reaction class 0x51 natively, 0x4F on ours, first differing at or before the first DIFF
                 frame or one frame after it (the TRAP-REMAP window, `cl <= f0 + 1`) — Pyron's
                 Cosmo Disruption record remapped 0x51 -> 0x4F at 14z-75 (build/manifest/pyron.toml): the victim
                 takes a plain hit reaction where native takes the fire / knockdown one, the maintainer's read of
                 the captures "Same reading: defect" (14z-186, #194, OPEN — the remap is the candidate cause)
  GUARD-REENTRY  the first DIFF is P1's node on, or one frame after, the frame both legs leave the
                 block freeze (seq 0 -> 2) — vsavj re-enters the block animation (tests/audit_guard_reentry.sh)
  DEFENSE-ROW    the first DIFF is P1's HP alone, Phobos the victim, ours taking MORE (measured 11/13 on
                 Demitri's 5HP, 1 more on Victor's at 14z-164) — the vsavj defender rows, recorded
                 "DECIDED (maintainer, 2026-08-14): OPTION (b)" (the maintainer's own words were not kept),
                 SUPERSEDED 2026-09-18: "take the vs2 rows" (docs/project/tables/defense_rows.md)
  P2-DISPLACEMENT a seeded root whose own fields are IDENT while P2's x differs in its window — #159
                 (fixed at M21, 14z-185; no seed carries it since)
  P2-RECORD      the DEFENSE-ROW signature (P1's HP alone, the tenant the victim, ours taking MORE) on a build
                 whose defense row is ALREADY vs2's, AND P2 Demitri on the SAME node at the hit on both legs (mapped
                 on each leg's own image) with that node's attack record LOWER on vs2 by exactly what the tenant took
                 less: vs2 lowered Demitri's own data, and ours runs vsavj's Demitri — not the port. Re-measured every run
                 by swapping the record byte both ways (p2check; the gate's section 1b); Phobos 11 native / 12 ours,
                 Donovan and Pyron 12 / 13, all from his 5HP (a2:0x04#2, 13 vs2 / 14 vsavj). #161 RULED not-ours
                 2026-09-25 (14z-182, DECISIONS_HISTORY.md). REPLACES (14z-187b) DMG-VSAVJ, whose reading "vsavj's
                 OWN damage pipeline" was RETRACTED — the legacy control it rested on (Demitri's 5HP on Victor,
                 12/11) is the same record; before it, PHOBOS-DMG-OPEN (14z-170) and DMG-OPEN (14z-181)
  WALL-PUSH-VSAVJ the first DIFF is the tenant's x ALONE, on a frame where native's x holds and ours moves,
                 and within two frames native's facing flips while ours does not — vsavj's OWN shared-wall
                 push rule, not the port: with both fighters clamped at one wall the push-apart pushes P1 out
                 on vsavj and P2 out on vs2 (vs2's view clamp flags +0x148, vsavj's does not), and a LEGACY
                 pursuit splits the same way (Lilith on Victor, pristine vsavj vs vs2 —
                 tests/audit_shared_wall_push.sh; docs/game/engine_internals.md "THE PUSH-APART AT A SHARED
                 WALL"). Phobos's Sitting Attack landing after a throw, huitzil_3 events 8/9: native stays at
                 x 1000 and turns, ours is pushed 31 px and keeps facing. RULED 2026-09-27 (14z-184): #179
                 closed as not-ours, "Close not-ours (Recommended)" (DECISIONS_HISTORY.md); until then the open
                 class LANDING-TURN-OPEN (14z-183)
  OTHER          none of the above: an UNATTRIBUTED root (the gate fails on it)

Usage: move_parity_attribution.py run --build DIR --romdir DIR --work DIR [--jobs 6] [--no-ablate]
                                      [--parts "p1 p2"] > rows.tsv
  --no-ablate is the gate's shadow control: roots are never removed, so nothing can be attributed.
Rows: `root <part> <event> <class> <step> vanished=<events>` and `row <part> <event> <root> <class>`.
"""
import argparse, json, os, subprocess, sys
from concurrent.futures import ThreadPoolExecutor

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ROW_NATIVE = {}   # tenant -> are its defense-curve row AND rally-threshold byte in the build vs2's own; set in main() from the build under test
sys.path.insert(0, os.path.join(REPO, "tools"))
import move_parity as mp  # noqa: E402
import name_moves as nm   # noqa: E402

ROUND_START = 2545
OURS_PATH = {"donovan": "D D DR DR", "huitzil": "D D D", "pyron": "D D D D"}
SEED = {}   # RETIRED 14z-185 (M21): was {"donovan_3": [5]} — GitHub #159, Killshread Summon (ES) displacing P2, whose x the
           # table does not compare; #159 landed at M21 and the seeded root read OTHER ("seeded root with no P2 displacement")
FIELDS = ("ff841c:l:node,ff8420:b:cnt,ff8406:b:seq,ff8407:b:sub,ff8509:b:stock,ff8410:w:x,ff8414:w:y,"
          "ff8450:w:p1hp,ff8782:b:id,ff802e:b:df,ff840b:b:face,ff8116:b:lvl,ff850a:w:meter,ff8850:w:p2hp,"
          "ff8852:w:p2white,ff8452:w:p1white,"   # both white HP words, compared by tools/move_parity.py since #193 (14z-186)
          
          "ff881c:l:p2node,ff8b82:b:p2id,ff8081:b:pc,ff890a:w:p2meter,ff8854:b:p2cls,ff8810:w:p2x,ff845c:b:frz")


def rows_of(path):
    out = {}
    for l in open(path):
        if l.startswith("#") or not l.strip():
            continue
        r = l.rstrip("\n").split("\t")
        out[(r[0], int(r[1]))] = r
    return out


def gen(part, outdir, ablate=(), first_event=None):
    tenant, p = part.rsplit("_", 1)
    sch = nm.SCHEDULES[tenant]; orig = sch[p]; fe = nm.FIRST_EVENT
    try:
        sch[p] = [tuple([e[0], [] if k in ablate else e[1]] + list(e[2:])) for k, e in enumerate(orig)]
        if first_event is not None:
            nm.FIRST_EVENT = first_event
        import contextlib, io
        with contextlib.redirect_stdout(io.StringIO()):
            nm.gen(tenant, p, f"{outdir}/{part}.rpl", f"{outdir}/{part}.json")
    finally:
        sch[p] = orig; nm.FIRST_EVENT = fe


def run_leg(a, part, leg, rigdir, outdir, rompoke="", suffix=""):
    tenant = part.rsplit("_", 1)[0]
    j = json.load(open(f"{rigdir}/{part}.json")); fr = j["frames"]
    pokes = ";".join(j["pokes"] + [f"{2000}-{(fr)-1}:ff8116:06"] + [f"{2363}-{(fr)-1}:ff80d4:0000"])
    rpl = open(f"{rigdir}/{part}.rpl").read().splitlines(True)
    if leg == "ours":   # the merged wheel's path replaces P1's prologue (tests/audit_move_parity.sh rpl_for)
        new, done = [], False
        for line in rpl:
            if line.startswith("1104-1106 p2=R") and not done:
                t = 1100
                for m in OURS_PATH[tenant].split():
                    new.append(f"{t}-{t + 2} p1={m}\n"); t += 60
                done = True
            if any(line.startswith(f"{s}-") and " p1=" in line for s in (1100, 1160, 1220, 1280)):
                continue
            new.append(line)
        rpl = new
    L = f"{leg}{suffix}"
    os.makedirs(f"{outdir}/run_{part}_{L}", exist_ok=True)
    rp = f"{outdir}/rpl_{part}_{L}.rpl"; open(rp, "w").writelines(rpl)
    env = dict(os.environ, ROMDIR=a.romdir, MAME_BIN=a.mame_bin, MAME_SANDBOX=f"{outdir}/run_{part}_{L}/sb",
               MAME_ROMPATH=a.romdir if leg == "native" else f"{a.build}/rompath;{a.romdir}",
               REPLAY=rp, POKES=pokes, FIELDS=FIELDS, FIELD_OUT=f"{outdir}/tr_{part}_{L}.txt",
               FIELD_FROM="2300", FIELD_TO=str(fr), FRAMES=str(fr), ROMPOKE=rompoke)
    script = "rom_poke.lua" if rompoke else "field_trace.lua"   # rom_poke.lua chains field_trace.lua
    with open(f"{outdir}/run_{part}_{L}/mame.log", "w") as log:
        r = subprocess.run([f"{REPO}/tools/run_mame.sh", "vsav2" if leg == "native" else "vsavjw",
                            "-autoboot_script", f"{REPO}/tests/lua/{script}"],
                           env=env, cwd=f"{outdir}/run_{part}_{L}", stdout=log, stderr=subprocess.STDOUT)
    subprocess.run(["rm", "-rf", f"{outdir}/run_{part}_{L}/sb"])
    # MAME can segfault at TEARDOWN after the log is closed (docs/platform/gotchas.md): the leg is judged
    # by field_trace's own summary line, the exit status only when that line is missing (14z-168)
    tr = f"{outdir}/tr_{part}_{L}.txt"
    done = os.path.exists(tr) and any(l.startswith("FIELDSUMMARY") for l in open(tr))
    if not done:
        raise SystemExit(f"VOID: {part} {leg} exited {r.returncode} and its trace has no FIELDSUMMARY line")


def step(a, name, specs):
    """specs: {part: (ablate list, first_event or None)} -> {(part, k): row}, traces kept in the step dir"""
    rig = f"{a.work}/{name}/rig"; out = f"{a.work}/{name}"; os.makedirs(rig, exist_ok=True)
    for part, (abl, fe) in specs.items():
        gen(part, rig, abl, fe)
    with ThreadPoolExecutor(max_workers=a.jobs) as ex:
        list(ex.map(lambda pl: run_leg(a, pl[0], pl[1], rig, out), [(p, l) for p in specs for l in ("native", "ours")]))
    rows = {}
    for part in specs:
        tenant, p = part.rsplit("_", 1)
        j = json.load(open(f"{rig}/{part}.json"))
        pl = f"{a.build}/patch/placements.json"
        for r in mp.compare_events(tenant, f"{out}/tr_{part}_native.txt", f"{out}/tr_{part}_ours.txt", pl, j["events"], j["pokes"]):
            rows[(part, r["k"])] = [part, str(r["k"]), r["name"], r["verdict"], r["first"], r["fields"], str(r["frames"]), r["coupled"], str(r["excluded"])]
    return rows, out, rig


IMG = {}   # "native" / "ours": the data views P2's node is mapped on (set in main(): vs2's, and the build's own)


def p2_record(n, o, f0):
    """(native red power, ours red power, "table:seq#node") of P2 Demitri's attack node at the hit frame f0 (or the
    frame before, the node whose record exists), mapped on each leg's own image — None unless both legs are on the
    SAME node and it carries an attack record on both"""
    if not IMG:
        return None
    import dmg_sweep
    got = {}
    for leg, d, layout in (("native", n, "vsav2"), ("ours", o, "vsavj")):
        idx, hb, chains = dmg_sweep._demitri(IMG[leg], layout)
        for t in (f0, f0 - 1):
            w = idx.get(f"0x{d[t]['p2node']:x}") if t in d else None
            if w:
                nd = chains(w[0])[w[1]]["nodes"][w[2]]
                rec = hb.node_boxes(nd["hb8"], nd["hbA"])["attack"]
                if rec:
                    got[leg] = (rec["real"], f"{w[0]}:{w[1]}#{w[2]}", int(rec["addr"], 16) + 8); break
    if len(got) == 2 and got["native"][1] == got["ours"][1]:
        return got["native"][0], got["ours"][0], got["native"][1], got["native"][2], got["ours"][2]
    return None


P2REC = {}   # "part:event" -> the p2_record of a P2-RECORD root (the counterfactual's bytes)


def classify(part, k, trdir, rigdir, row):
    n, o = mp.load_trace(f"{trdir}/tr_{part}_native.txt"), mp.load_trace(f"{trdir}/tr_{part}_ours.txt")
    ev = json.load(open(f"{rigdir}/{part}.json"))["events"]
    lo = ev[k]["frame"]; hi = ev[k + 1]["frame"] if k + 1 < len(ev) else lo + ev[k]["gap"]
    tenant = part.rsplit("_", 1)[0]
    if row[3] != "DIFF":   # a seeded root: its own fields are IDENT
        if any(n[f]["p2x"] != o[f]["p2x"] for f in range(lo, hi) if f in n and f in o):
            return "P2-DISPLACEMENT", "P2's x differs in the window while the tenant's fields are IDENT"
        return "OTHER", "seeded root with no P2 displacement"
    f0 = lo + int(row[4]); fields = row[5].split(",")
    zp = lambda d: [f for f in range(lo, f0 + 1) if f in d and f - 1 in d and (d[f]["pc"] - d[f - 1]["pc"]) % 256 == 0]
    zn, zo = zp(n), zp(o)
    if bool(zn) != bool(zo):
        return "SLOWDOWN", f"zero-pass frame native {zn} ours {zo}"
    fr = [f for f in range(lo + 1, hi) if f in n and f in o and f - 1 in n and f - 1 in o]
    step_ = lambda d, f: (d[f]["meter"] - d[f - 1]["meter"], d[f]["p2meter"] - d[f - 1]["p2meter"])
    md = [f for f in fr if step_(n, f) != step_(o, f)]
    if md:
        a_, b_ = step_(n, md[0]), step_(o, md[0])
        if a_[0] != a_[1] and a_ == (b_[1], b_[0]):
            return "METER-SWAP", f"at {md[0]} native (P1,P2) {a_} ours {b_}"
    if any(m in ev[k]["name"] for m in mp.DF_MOVES) and row[4] == "+0" and "stock" in fields:
        return "DF-STOCK", f"stock {n[lo]['stock']} native vs {o[lo]['stock']} ours at the activation"
    cl = next((f for f in range(lo, hi) if f in n and f in o and n[f]["p2cls"] != o[f]["p2cls"]), None)
    if cl is not None and (n[cl]["p2cls"], o[cl]["p2cls"]) == (0x52, 0x06) and cl <= f0 + 1:
        return ("TRAP-REMAP" if tenant == "huitzil" else "COLUMN-SHOCK"), f"P2 class 0x52 native / 0x06 ours at {cl}"
    if cl is not None and (n[cl]["p2cls"], o[cl]["p2cls"]) == (0x51, 0x4F) and cl <= f0 + 1:
        # 14z-186, found under #193: Pyron's Cosmo Disruption record class 0x51 remapped to 0x4F (14z-75) — the victim
        # takes a plain hit reaction where native takes the fire / knockdown one (#194, open: the remap is the
        # candidate cause, unmeasured as the cause)
        return "REACTION-51-OPEN", f"P2 class 0x51 native / 0x4F ours at {cl} (#194)"
    if fields == ["node"] or fields == ["cnt", "node"]:
        for t in (f0, f0 - 1):   # the node differs on the freeze-end frame or the one after it
            if t - 1 in n and n[t - 1]["seq"] == 0 and n[t]["seq"] == 2 and o[t - 1]["seq"] == 0 and o[t]["seq"] == 2:
                return "GUARD-REENTRY", f"node differs at {f0}, both legs leaving the block freeze at {t} (seq 0 -> 2)"
    # the tenant the VICTIM, ours taking more. Since #193 (14z-186) the white word is compared too, and a hit lowers
    # both words on the same frame, so the signature reads p1hp alone OR p1hp with p1white — the white word then
    # required to show the same direction (ours taking more), never merely present
    white_ok = fields == ["p1hp"] or (fields == ["p1hp", "p1white"]
                                      and 0 < n[f0 - 1]["p1white"] - n[f0]["p1white"] < o[f0 - 1]["p1white"] - o[f0]["p1white"])
    if fields in (["p1hp"], ["p1hp", "p1white"]) and white_ok:
        dn = n[f0 - 1]["p1hp"] - n[f0]["p1hp"]; do = o[f0 - 1]["p1hp"] - o[f0]["p1hp"]
        if 0 < dn < do:
            who = "Phobos" if tenant == "huitzil" else tenant
            if not ROW_NATIVE.get(tenant):   # vsavj's row indexes lower unless the vs2 row is in
                return "DEFENSE-ROW", f"{who} takes {dn} native / {do} ours"
            # 14z-187b (P2-RECORD replaces DMG-VSAVJ, whose "vsavj's own pipeline" was RETRACTED): with the
            # victim's rows already vs2's, the extra point is the ATTACKER's own data — P2 Demitri's node at the hit,
            # mapped on each leg's own image, must be the SAME node, and its attack record lower on vs2 by exactly
            # what the tenant took less. Its mechanism is re-measured on every run: each root's legs re-run with that record
            # byte swapped both ways (p2check below; tests/audit_move_parity_attribution.sh section 1b; the legacy sweep's own
            # swap is tests/audit_dmg_legacy_sweep.sh section 5; docs/game/engine_internals.md "DEMITRI'S DATA DIFFERS BETWEEN VSAVJ AND VS2"). Records equal
            # leaves the row OTHER: no class may claim an engine difference without a measurement.
            pr = p2_record(n, o, f0)
            if pr and pr[1] - pr[0] == do - dn:
                P2REC[f"{part}:{k}"] = pr
                return "P2-RECORD", f"{who} takes {dn} native / {do} ours: P2 Demitri's attack record {pr[2]} red power {pr[0]} native / {pr[1]} ours (vs2 lowered it; ours runs vsavj's Demitri, #161/#191)"
    if fields == ["x"] and f0 - 1 in n and f0 - 1 in o and f0 + 2 in n and f0 + 2 in o:
        # 14z-183, #179 (closed not-ours 14z-184, vsavj's shared-wall rule): native's x holds on the first DIFF frame while ours moves, and native turns
        # within two frames while ours keeps facing — a measured signature, never the part's name
        if n[f0]["x"] == n[f0 - 1]["x"] and o[f0]["x"] != o[f0 - 1]["x"] \
           and any(n[g]["face"] != n[f0]["face"] for g in (f0 + 1, f0 + 2)) \
           and all(o[g]["face"] == o[f0]["face"] for g in (f0 + 1, f0 + 2)):
            return "WALL-PUSH-VSAVJ", f"native x holds at {n[f0]['x']} and turns; ours is pushed {o[f0 - 1]['x']} -> {o[f0]['x']} and keeps facing (vsavj's shared-wall rule, #179)"
    return "OTHER", f"first DIFF {row[4]} on {row[5]}"


def p1_drops(trace, lo, hi):
    R = {}
    for l in open(trace):
        t = l.split()
        if t and t[0] == "F": R[int(t[1])] = {kv.split("=")[0]: int(kv.split("=")[1]) for kv in t[2:]}
    return [(f - lo, R[f - 1]["p1hp"] - R[f]["p1hp"], R[f - 1]["p1white"] - R[f]["p1white"])
            for f in range(lo, hi) if f in R and f - 1 in R and R[f]["p1hp"] != R[f - 1]["p1hp"]]


def p2check(a, roots, rig, base):
    """14z-187b (rule-checker run 2026-10-01-516): every P2-RECORD root's MECHANISM, measured: the part's two legs re-run
    from the committed rig with P2 Demitri's attack-record byte set to the OTHER game's value (tests/lua/rom_poke.lua,
    each write verified through the program space) — ours given vs2's, native given vsavj's — and each swapped leg's
    tenant HP drops in the root event's window must equal the OTHER leg's unpoked drops (step 0's traces). The control
    p2-record-unswapped: the unpoked legs must DIFFER (else the equality is vacuous); --p2check-unswapped (the gate's
    CONTROL mode) puts the unpoked traces in place of the swapped ones, and the check must then fail. The inert control
    (run 2026-10-01-518): each leg re-run with the byte poked to its OWN value must reproduce its unpoked trace exactly."""
    out = []
    todo = [r_ for r_, _, cls, _, _ in roots if cls == "P2-RECORD"]
    parts = sorted({r_.split(":")[0] for r_ in todo})
    jobs, same = [], []
    for part in parts:
        pr = next(P2REC[r_] for r_ in todo if r_.startswith(part + ":"))
        jobs += [(part, "ours", f"{pr[4]:x}:{pr[0]:02x}"), (part, "native", f"{pr[3]:x}:{pr[1]:02x}")]
        # the inert control (rule-checker run 2026-10-01-518 Q1/Q4): each leg's byte poked to its OWN value must
        # reproduce that leg's unpoked trace byte for byte, on the merged image as on vs2's
        same += [(part, "ours", f"{pr[4]:x}:{pr[1]:02x}"), (part, "native", f"{pr[3]:x}:{pr[0]:02x}")]
    with ThreadPoolExecutor(max_workers=a.jobs) as ex:
        list(ex.map(lambda j: run_leg(a, j[0], j[1], rig, f"{a.work}/p2check", rompoke=j[2], suffix=j[3]),
                    [j + ("_swap",) for j in jobs] + [j + ("_same",) for j in same]))
    for (part, leg, rp), sfx in [(j, "_swap") for j in jobs] + [(j, "_same") for j in same]:
        log = open(f"{a.work}/p2check/run_{part}_{leg}{sfx}/mame.log").read()
        out.append(f"poke\t{part}\t{leg}{sfx}\t{rp}\t{'verified' if 'ROMPOKE ok' in log and 'ROMPOKE FAIL' not in log else 'NOT VERIFIED'}")
    for part, leg, rp in same:
        t0, t1, t2 = (open(f).read() for f in (f"{base}/tr_{part}_{leg}.txt", f"{a.work}/p2check/tr_{part}_{leg}_same.txt",
                                                f"{a.work}/p2check/tr_{part}_{leg}_swap.txt"))
        # the comparison can refuse: the same file comparison sees the SWAPPED leg's trace as different
        out.append(f"inert\t{part}\t{leg}\t{rp}\t{'identical' if t0 == t1 else 'CHANGED'}\t"
                   f"swapped trace {'differs' if t0 != t2 else 'IDENTICAL'}")
    other = {"ours": "native", "native": "ours"}
    differ = 0
    for r_ in todo:
        part, k = r_.split(":"); e = json.load(open(f"{rig}/{part}.json"))["events"][int(k)]
        lo, hi = e["frame"], e["frame"] + e["gap"]
        bd = {leg: p1_drops(f"{base}/tr_{part}_{leg}.txt", lo, hi) for leg in ("ours", "native")}
        differ += bd["ours"] != bd["native"]
        for leg in ("ours", "native"):
            sw = bd[leg] if a.p2check_unswapped else p1_drops(f"{a.work}/p2check/tr_{part}_{leg}_swap.txt", lo, hi)
            v = "confirmed" if sw == bd[other[leg]] else "MISMATCH"
            out.append(f"check\t{r_}\t{leg}\t{v}\tswapped {sw} | {other[leg]} unpoked {bd[other[leg]]}")
    out.append(f"control\tp2-record-unswapped\t{'fired' if todo and differ == len(todo) else 'dead'}\tunpoked legs differ on {differ} of {len(todo)} roots")
    open(a.p2check_out, "w").write("\n".join(out) + "\n")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("mode", choices=["run"])
    ap.add_argument("--build", required=True); ap.add_argument("--romdir", required=True); ap.add_argument("--work", required=True)
    ap.add_argument("--jobs", type=int, default=6); ap.add_argument("--no-ablate", action="store_true")
    ap.add_argument("--p2check-out", help="write the P2-RECORD counterfactual check here (never to stdout, the frozen table)")
    ap.add_argument("--p2check-unswapped", action="store_true", help="the gate's p2-record-unswapped CONTROL mode")
    ap.add_argument("--parts", default="")
    ap.add_argument("--mame-bin", default=os.path.expanduser("~/.cache/vampire-saved/mame/cps2"))
    a = ap.parse_args()
    a.build = os.path.abspath(a.build); a.romdir = os.path.abspath(a.romdir); a.work = os.path.abspath(a.work)
    # is each tenant's defense-curve row (vsavj 0x0B8940 + id*32) in THIS build vs2's own (vs2 0x0D2ABE + id*32)?
    # Phobos 0x10 (ported at M19), Donovan 0x13 (ported at M19), Pyron 0x11 (identical in every game)
    global ROW_NATIVE
    try:
        _bimg = open(f"{a.build}/verify_data.bin", "rb").read()
        _vimg = open(os.path.join(REPO, "build/out/vsav2_data.bin"), "rb").read()
        # BOTH tables the damage chain indexes by the victim's id: the 32-byte curve row AND the rally-threshold
        # byte (vsavj PRG:0x0BCC80 + id, vs2 PRG:0x0D6E1E + id) — rule-checker run 2026-09-25-157 Q1: the first
        # form read the curve row alone and called the rows "already vs2's"
        for _t, _id in (("huitzil", 0x10), ("donovan", 0x13), ("pyron", 0x11)):
            _b = _bimg[0x0B8940 + _id * 32:0x0B8940 + _id * 32 + 32]; _v = _vimg[0x0D2ABE + _id * 32:0x0D2ABE + _id * 32 + 32]
            _tb = _bimg[0x0BCC80 + _id:0x0BCC80 + _id + 1]; _tv = _vimg[0x0D6E1E + _id:0x0D6E1E + _id + 1]
            ROW_NATIVE[_t] = len(_b) == 0x20 and _b == _v and len(_tb) == 1 and _tb == _tv
        IMG.update({"native": _vimg, "ours": _bimg})
    except OSError:
        ROW_NATIVE = {}
    frozen = rows_of(f"{REPO}/tests/expected/move_parity_events.tsv")
    parts = a.parts.split() if a.parts else sorted({k[0] for k, r in frozen.items() if r[3] == "DIFF"},
                                                   key=lambda s: (s.split("_")[0], int(s.split("_")[1])))
    # the generator must reproduce the committed rigs, or the ablations are of a different rig
    os.makedirs(f"{a.work}/genchk", exist_ok=True)
    for part in parts:
        gen(part, f"{a.work}/genchk")
        for ext in ("rpl", "json"):
            if open(f"{a.work}/genchk/{part}.{ext}").read() != open(f"{REPO}/tests/replays/naming/{part}.{ext}").read():
                raise SystemExit(f"VOID: tools/name_moves.gen no longer reproduces tests/replays/naming/{part}.{ext}")
    # step 0: the committed rigs reproduce the frozen table
    base, d0, r0 = step(a, "s0", {p: ((), None) for p in parts})
    for key, r in base.items():
        if frozen.get(key) != r:
            raise SystemExit(f"VOID: step 0 does not reproduce the frozen row {key}: got {r[3:6]} frozen {frozen.get(key, ['-'] * 6)[3:6]}")
    cur = dict(base); where = {p: (d0, r0) for p in parts}
    diff_base = sorted(k for k, r in base.items() if r[3] == "DIFF")
    ever = set(diff_base)
    root_of, roots = {}, []
    # step E: the opening fix
    shifted = []
    for p in parts:
        j = json.load(open(f"{REPO}/tests/replays/naming/{p}.json"))
        pins = [int(x.split(":")[0]) for x in j["pokes"] if x.split(":")[1].lower() == "ff8410"]
        if pins and min(pins) < ROUND_START:
            shifted.append(p)
    fe_of = {p: (2800 if p in shifted else None) for p in parts}
    if shifted:
        got, dE, rE = step(a, "sE", {p: ((), 2800) for p in shifted})
        for p in shifted:
            before = {k for k, r in cur.items() if k[0] == p and r[3] == "DIFF"}
            now = {k for k, r in got.items() if k[0] == p and r[3] == "DIFF"}
            for key in before - now:
                root_of[key] = (f"{p}:opening", "ENTRANCE")
            ever |= now
            where[p] = (dE, rE)
        cur = {k: r for k, r in cur.items() if k[0] not in shifted}; cur.update(got)
        roots.append(("opening", "shifted " + " ".join(shifted), "ENTRANCE", "E", ""))
    abl = {p: [] for p in parts}
    for n_ in range(1, 40):
        todo = {}
        for p in parts:
            d = sorted(k[1] for k, r in cur.items() if k[0] == p and r[3] == "DIFF")
            if not d:
                continue
            seed = [e for e in SEED.get(p, []) if e not in abl[p]]
            nxt = seed[0] if seed else d[0]
            if nxt in abl[p] or a.no_ablate and n_ > 1:
                continue
            todo[p] = nxt
        if not todo:
            break
        # classify each root on the traces where it is still a DIFF (or the seeded one's own IDENT window)
        for p, k in todo.items():
            trd, rgd = where[p]
            row = cur.get((p, k)) or base[(p, k)]
            cls, why = classify(p, k, trd, rgd, row)
            roots.append((f"{p}:{k}", row[2], cls, str(n_), why))
            if not a.no_ablate:
                abl[p] = abl[p] + [k]
        if a.no_ablate:
            break
        got, dN, rN = step(a, f"s{n_}", {p: (abl[p], fe_of[p]) for p in todo})
        for p, k in todo.items():
            before = {kk for kk, r in cur.items() if kk[0] == p and r[3] == "DIFF"}
            now = {kk for kk, r in got.items() if kk[0] == p and r[3] == "DIFF"}
            for key in before - now:
                root_of[key] = (f"{p}:{k}", next(c for r_, _, c, _, _ in roots if r_ == f"{p}:{k}"))
            ever |= now
            where[p] = (dN, rN)
        cur = {kk: r for kk, r in cur.items() if kk[0] not in todo}; cur.update(got)
    if a.p2check_out:
        p2check(a, roots, r0, d0)
    for r_, name, cls, st, why in roots:
        print(f"root\t{r_}\t{name}\t{cls}\tstep={st}\t{why}")
    for key in sorted(ever, key=lambda x: (x[0].split("_")[0], int(x[0].split("_")[1]), x[1])):
        rt, cls = root_of.get(key, ("UNATTRIBUTED", "OTHER"))
        tag = "base" if key in diff_base else "surfaced"
        print(f"row\t{key[0]}\t{key[1]}\t{tag}\t{rt}\t{cls}")


if __name__ == "__main__":
    main()
