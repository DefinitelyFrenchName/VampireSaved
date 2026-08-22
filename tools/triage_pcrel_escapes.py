#!/usr/bin/env python3
"""triage_pcrel_escapes.py — H3.1 (14z-100): for every UNCOVERED word-form
pc-rel branch escape in the tenants' extracts, where does it land on the
MERGED image, and is that the right content?

Verdicts (structural, per site):
  ADJACENT-OK      lands in a region placed at the SAME delta — the pc-rel
                   arithmetic resolves to the identical vs2 content;
  FOREIGN-REGION   lands inside another placed region at a different delta
                   (the #103 shape) — LIVE unless the site is a reviewed
                   census false positive (mis-framed immediate/jump-table
                   data; see the manifests' reviewed-not-rowed blocks);
  VANILLA-LANDING / WIDE / OFF — review.

14z-100 sweep result: ZERO live escapes. The 20-site huitzil cluster is
ADJACENT-OK by construction; x028122+0x112 (all tenants) is the reviewed
jump-table framing ambiguity; x068c78+0x1ca (hui/pyr) is the immediate-word
false-positive class, frame-anchored in the manifests' notes.
`--all-regions` includes COVERED regions too (their raw escapes then show
non-OK verdicts — the gate's must-fire control).
"""
import argparse
import json, struct, sys

UNCOVERED = {
    "donovan": ["x028122"],                    # x065c22/x088512 already reviewed-benign
    "huitzil": ["x028122", "code", "x068c78"],
    "pyron":   ["x028122", "x068c78"],
}
SOLO = {"donovan": "don_m11", "huitzil": "hui47", "pyron": "pyron31"}

mp = json.load(open("build/m3b_merged13/patch/placements.json"))["regions"]

def merged_key(tenant, region):
    return region if tenant == "donovan" else f"{region}@{tenant}"

def find_placed_by_dst(a):
    for k, v in mp.items():
        if v["dst"] <= a < v["dst"] + v["len"]:
            return k, v
    return None, None

def scan_escapes(blob, src, length):
    out = []
    for i in range(0, length - 3, 2):
        op = (blob[i] << 8) | blob[i+1]
        word_branch = (op & 0xFF00) in {0x6000, 0x6100} and (op & 0x00FF) == 0 \
            or ((op & 0xF000) == 0x6000 and (op & 0x00FF) == 0 and (op >> 8) & 0x0F >= 2)
        dbcc = (op & 0xF0F8) == 0x50C8
        if not (word_branch or dbcc):
            continue
        disp = struct.unpack(">h", blob[i+2:i+4])[0]
        t = src + i + (4 if dbcc else 2) + disp
        # census-2 convention: branch target = pc+2+disp for Bcc/BRA/BSR word
        if word_branch:
            t = src + i + 2 + disp
        if not (src <= t < src + length):
            out.append((i, op, t))
    return out

ap = argparse.ArgumentParser()
ap.add_argument("--all-regions", action="store_true")
args = ap.parse_args()

for tenant, regions in UNCOVERED.items():
    if args.all_regions:
        regions = list(json.load(open(f"build/{SOLO[tenant]}/extract/regions.json"))["regions"])
    solo = SOLO[tenant]
    rj = json.load(open(f"build/{solo}/extract/regions.json"))["regions"]
    # per-tenant source-region span map with merged deltas
    src_spans = []
    for rname, meta in rj.items():
        k = merged_key(tenant, rname)
        if k in mp:
            src_spans.append((meta["src"], meta["src"] + meta["len"], rname,
                              mp[k]["dst"] - meta["src"]))
    for region in regions:
        meta = rj.get(region)
        if meta is None:
            print(f"{tenant}/{region}: NOT IN regions.json"); continue
        k = merged_key(tenant, region)
        if k not in mp:
            print(f"{tenant}/{region}: NOT PLACED in merged"); continue
        delta = mp[k]["dst"] - meta["src"]
        blob = open(f"build/{solo}/extract/region_{region}.bin", "rb").read()
        for off, op, t_src in scan_escapes(blob, meta["src"], meta["len"]):
            t_new = t_src + delta
            qk, qv = find_placed_by_dst(t_new)
            srcq = next(((s, e, n, d) for s, e, n, d in src_spans if s <= t_src < e), None)
            if srcq and abs(srcq[3] - delta) == 0:
                verdict = f"ADJACENT-OK (lands in {srcq[2]}, same delta)"
            elif qk:
                verdict = f"FOREIGN-REGION **LIVE RISK** (lands in placed {qk}, delta mismatch)"
            elif t_new < 0x400000:
                verdict = "VANILLA-LANDING (review: does it hit the vsavj twin?)"
            elif t_new < 0x600000:
                verdict = "WIDE **check fill**"
            else:
                verdict = "OFF/IO **LIVE RISK**"
            print(f"{tenant}/{region}+{off:#x}: op {op:04x} -> src {t_src:#x} "
                  f"=> merged {t_new:#x}  {verdict}")
