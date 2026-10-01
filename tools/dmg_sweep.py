#!/usr/bin/env python3
"""dmg_sweep.py — the reader of tests/audit_dmg_legacy_sweep.sh (14z-187, GitHub #191).

Two commands, both reading every line of every field trace they are given:

  tables <vsavj data view> <vsav2 data view>
      The damage pipeline's TABLES compared between the two games in the DATA view (the view their An-relative
      reads see): the defense table (vsavj PRG:0x0B8940, vs2 PRG:0x0D2ABE, 32 B per char id), the attack table
      (0x0B8140 / 0x0D22BE, 1024 B) and the final 2D map (0x0B9140 / 0x0D32DE, 0x1080 B) — the addresses of
      docs/game/engine_internals.md "The DAMAGE pipeline". Prints the SHA-1 of each image, the ids whose rows
      differ, and equal/DIFF for the two tables; never a byte.

  records <vsavj data view> <vsav2 data view>
      THE MECHANISM (14z-187b, corrected by counterfactual): Demitri's three hits are nodes of his OWN a2 chains
      whose attack records differ between the games — HITS below, the nodes traced at each hit on both games
      (build/agent187b/t191n, the attacker's ff841c mapped through tools/audit_same_data_p2.py's node index). For
      each: the chain/node, the record's red-damage byte address in each data view and its value, equal/DIFF.
      Prints the addresses so the gate's counterfactual can set one game's bytes to the other's.

  nodes <data view> <vsavj|vsav2> <trace>
      Demitri's (P1) node at each victim red drop in one trace, mapped to (table, seq, node) — the gate's check
      that the counterfactual legs' hits are HITS' nodes.

  rows <work dir> <donovan rig json> [--perturb engines-agree|attacker-swapped]
      One row per hit of every leg the gate ran (traces <dir>/L.<side>.<victim>.<game>/f.ft and
      <dir>/D.<native|ours>/f.ft), on stdout, and every structural problem on stderr as `PROBLEM ...` (exit 1 if
      any): a trace with no FIELDSUMMARY line, a leg whose ids at 2300 are not the forced pair, a hit whose
      attacker (read at the victim's first red drop) is not Demitri 0x01. Legacy windows follow each HP pin:
      2HK [2950,3300), 5HP [3390,3700), 623HP [3790,4100); Donovan's are [f0, f0+120) per rig event.
      --perturb engines-agree: every vsavj row takes its vsav2 twin's red/white totals (what two engines that
      agreed would read). --perturb attacker-swapped: the attacker id is read as 0x03 at every hit (what a leg
      whose attacker was not Demitri would read). Both are the gate's must-fire controls.
"""
import hashlib
import json
import os
import sys

LEGACY_IDS = "00 01 02 03 04 05 06 07 08 09 0a 0c 0d 0e 0f 18".split()
WIN = (("2HK", 2950, 3300), ("5HP", 3390, 3700), ("623HP", 3790, 4100))
# which player is the victim on each side of the legacy sweep: side p1 = Demitri attacks from P1 (victim P2)
SIDE = {"p1": {"vic": "p2", "att": "id", "vid": "p2id"}, "p2": {"vic": "p1", "att": "p2id", "vid": "id"}}


def tables(jp, vp):
    j, v = open(jp, "rb").read(), open(vp, "rb").read()
    for p, b in ((jp, j), (vp, v)):
        print(f"read {p} sha1 {hashlib.sha1(b).hexdigest()}")
    diff = [i for i in range(0x20) if j[0x0B8940 + i * 32:0x0B8960 + i * 32] != v[0x0D2ABE + i * 32:0x0D2ADE + i * 32]]
    print("defense rows differing by id: " + " ".join(f"{i:02x}" for i in diff))
    print("attack table: " + ("equal" if j[0x0B8140:0x0B8540] == v[0x0D22BE:0x0D26BE] else "DIFF"))
    print("2D map: " + ("equal" if j[0x0B9140:0x0BA1C0] == v[0x0D32DE:0x0D435E] else "DIFF"))


def load(p):
    R, summ = {}, False
    with open(p) as fh:
        for line in fh:
            s = line.split()
            if s and s[0] == "F":
                R[int(s[1])] = {k: int(v) for k, v in (kv.split("=") for kv in s[2:])}
            elif "FIELDSUMMARY" in line:
                summ = True
    return R, summ


def drops(R, fld, lo, hi):
    out, prev = [], None
    for f in range(lo, hi):
        if f in R:
            v = R[f][fld]
            if prev is not None and v < prev:
                out.append((f, prev - v))
            prev = v
    return out


def rows(work, rig, perturb=None):
    out, probs = [], []
    hit = lambda R, vic, att, lo, hi: (lambda red, wh: (
        sum(d for _, d in red), sum(d for _, d in wh),
        red[0][0] if red else "-",
        (0x03 if perturb == "attacker-swapped" else R[red[0][0]][att]) if red else None,
        R[red[0][0]][f"{vic}cls"] if red else None))(drops(R, f"{vic}hp", lo, hi), drops(R, f"{vic}white", lo, hi))
    for side, m in SIDE.items():
        for vid in LEGACY_IDS:
            for g in ("vsavj", "vsav2"):
                p = f"{work}/L.{side}.{vid}.{g}/f.ft"
                if not os.path.exists(p):
                    probs.append(f"PROBLEM legacy {side} {vid} {g}: no trace")
                    continue
                R, summ = load(p)
                if not summ or 2300 not in R:
                    probs.append(f"PROBLEM legacy {side} {vid} {g}: incomplete trace (no FIELDSUMMARY or no frame 2300)")
                    continue
                if (R[2300][m["att"]], R[2300][m["vid"]]) != (0x01, int(vid, 16)):
                    probs.append(f"PROBLEM legacy {side} {vid} {g}: ids at 2300 attacker {R[2300][m['att']]:#04x} victim "
                                 f"{R[2300][m['vid']]:#04x}, not Demitri 0x01 against 0x{vid} — the forced picks did not land")
                for n, lo, hi in WIN:
                    red, wh, fr, att, cls = hit(R, m["vic"], m["att"], lo, hi)
                    if att is not None and att != 0x01:
                        probs.append(f"PROBLEM legacy {side} {vid} {g} {n}: the attacker at the first red drop is {att:#04x}, not Demitri 0x01")
                    out.append(["legacy", side, vid, g, n, str(red), str(wh), f"f{fr}" if fr != "-" else "-",
                                f"{att:#04x}" if att is not None else "-", f"{cls:#04x}" if cls is not None else "-"])
    ev = json.load(open(rig))["events"]
    for leg in ("native", "ours"):
        p = f"{work}/D.{leg}/f.ft"
        if not os.path.exists(p):
            probs.append(f"PROBLEM donovan {leg}: no trace")
            continue
        R, summ = load(p)
        if not summ or 2300 not in R:
            probs.append(f"PROBLEM donovan {leg}: incomplete trace")
            continue
        if (R[2300]["id"], R[2300]["p2id"]) != (0x13, 0x01):
            probs.append(f"PROBLEM donovan {leg}: ids at 2300 P1 {R[2300]['id']:#04x} P2 {R[2300]['p2id']:#04x}, not Donovan 0x13 against Demitri 0x01")
        for k, e in enumerate(ev):
            red, wh, fr, att, cls = hit(R, "p1", "p2id", e["frame"], e["frame"] + 120)
            if att is not None and att != 0x01:
                probs.append(f"PROBLEM donovan {leg} event {k}: the attacker at the first red drop is {att:#04x}, not Demitri 0x01")
            out.append(["donovan", "p2", "13", leg, str(k), str(red), str(wh),
                        f"+{fr - e['frame']}" if fr != "-" else "-", f"{att:#04x}" if att is not None else "-",
                        f"{cls:#04x}" if cls is not None else "-"])
    if perturb == "engines-agree":
        twin = {(r[1], r[2], r[4]): r for r in out if r[0] == "legacy" and r[3] == "vsav2"}
        out = [r[:5] + twin[(r[1], r[2], r[4])][5:7] + r[7:] if r[0] == "legacy" and r[3] == "vsavj"
               and (r[1], r[2], r[4]) in twin else r for r in out]
    return out, probs


HITS = (("2HK", "a2", "0x11", 2), ("5HP", "a2", "0x04", 2), ("623HP", "a2", "0x28", 1))


def _demitri(img, layout):
    """Demitri's (0x01) node index and walker chains, read with the census's own bank layout"""
    sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
    import audit_same_data_p2 as sd
    from hitbox_records import HitboxSet
    from anim_nodes import walk_table
    from pathlib import Path
    bank = sd.mt.loads((Path(__file__).resolve().parent.parent / "build/manifest/bank_map.toml").read_text())
    d = int(bank["origins"][layout]) - int(bank["origins"]["vsavj"])
    rows_ = {t["name"]: int(t["vsavj"]) for t in bank["table"]}
    hb = HitboxSet.from_image(img, sd.rd32(img, rows_["hitbox_base"] + d + 4), sd.rd32(img, rows_["hitbox_comp"] + d + 4))
    chains = lambda t: walk_table(img, 0, sd.rd32(img, rows_["anim_index_" + t] + d + 4))["chains"]
    return sd.node_index(img, rows_, d, 0x01), hb, chains


def records(jp, vp):
    out = []
    for g, p in (("vsavj", jp), ("vsav2", vp)):
        img = open(p, "rb").read()
        print(f"{g}: {p} sha1 {hashlib.sha1(img).hexdigest()}")
        _, hb, chains = _demitri(img, g)
        got = {}
        for name, t, seq, k in HITS:
            n = chains(t)[seq]["nodes"][k]
            r = hb.node_boxes(n["hb8"], n["hbA"])["attack"]
            got[name] = (int(r["addr"], 16) + 8, r["real"])
        out.append(got)
    for name, t, seq, k in HITS:
        (ja, jv), (va, vv) = out[0][name], out[1][name]
        print(f"record {name} {t}:{seq}#{k} vsavj {ja:#x}={jv} vsav2 {va:#x}={vv} {'equal' if jv == vv else 'DIFF'}")


def nodes(img_path, layout, trace):
    img = open(img_path, "rb").read()
    idx, _, _ = _demitri(img, layout)
    R, _ = load(trace)
    for f in sorted(R):
        if f - 1 in R and R[f]["p2hp"] < R[f - 1]["p2hp"]:
            w = idx.get(f"0x{R[f]['node']:x}")
            print(f"hit f{f} red -{R[f - 1]['p2hp'] - R[f]['p2hp']} node {w[0]}:{w[1]}#{w[2]}" if w else f"hit f{f} node UNMAPPED")


def main():
    if len(sys.argv) >= 4 and sys.argv[1] == "records":
        records(sys.argv[2], sys.argv[3])
        return
    if len(sys.argv) >= 5 and sys.argv[1] == "nodes":
        nodes(sys.argv[2], sys.argv[3], sys.argv[4])
        return
    if len(sys.argv) >= 4 and sys.argv[1] == "tables":
        tables(sys.argv[2], sys.argv[3])
        return 0
    if len(sys.argv) >= 4 and sys.argv[1] == "rows":
        pert = sys.argv[sys.argv.index("--perturb") + 1] if "--perturb" in sys.argv else None
        out, probs = rows(sys.argv[2], sys.argv[3], pert)
        for r in out:
            print("\t".join(r))
        for p in probs:
            print(p, file=sys.stderr)
        return 1 if probs else 0
    print(__doc__, file=sys.stderr)
    return 2


if __name__ == "__main__":
    sys.exit(main())
