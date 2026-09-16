#!/usr/bin/env python3
"""move_parity.py — THE TENANT-MOVE COMPARATOR: ours vs native vsav2, per rig part
(GitHub #136, 14z-159).

  python3 tools/move_parity.py compare <tenant> <part> <native.txt> <ours.txt> \
      <placements.json> [--first-event N] [--tsv]

WHAT IT COMPARES. The rigs of tools/name_moves.py already perform every move of
the maintainer's move lists on the tenant's NATIVE game. This runs the SAME rig on
a port build and compares the TENANT's own state frame by frame:

    node seq sub cnt x y stock face df p1hp

THE TRANSLATION. Our anim node pointer lives in the PLACED copy of the tenant's
anim region, so it is translated back into vs2's address space
(`ours - dst + src`) before comparison; both legs then speak one vocabulary. A
node that falls in no placed region is reported, never silently compared
([VSP-166]: say what the expectation is anchored to).

WHAT IS EXCLUDED, AND WHY.
  - P2 is VICTOR, a LEGACY character — VS's Victor on our leg and VS2's on the
    native one — so his node is never evidence about the port ([VSP-168]). His HP
    is a number and is compared by the caller where it is meaningful.
  - The INTRO (match anchor .. the rig's first event) is excluded: the intro
    variant is an RNG draw at char load, so the two legs play different intros
    unless the RNG is pinned through the load — and pinning it there prevents the
    match loading at all (measured 14z-159, the gate's `pin-through-load` note).

ONLY THE FIRST DIVERGENCE IS INDEPENDENT EVIDENCE. Once two legs desynchronise,
later events are downstream of the first failure and are reported as UNKNOWN, not
as findings — which is why the verdict names the first divergent event and the
counts after it are diagnostics.
"""
import argparse
import json
import sys

TENANT_FIELDS = ("node", "seq", "sub", "cnt", "x", "y", "stock", "face", "df", "p1hp")
ANIM_KEY = {"donovan": "anim", "huitzil": "anim@huitzil", "pyron": "anim@pyron"}


def load_trace(path):
    out = {}
    with open(path) as fh:
        for line in fh:
            if not line.startswith("F "):
                continue
            f = line.split()
            out[int(f[1])] = {k: int(v) for k, v in (kv.split("=") for kv in f[2:])}
    return out


def translator(placements, tenant):
    reg = json.load(open(placements))["regions"][ANIM_KEY[tenant]]
    dst, src, ln = reg["dst"], reg["src"], reg["len"]

    def tr(v):
        return v - dst + src if dst <= v < dst + ln else v

    return tr, (dst, src, ln)


def compare(tenant, native, ours, placements, first_event):
    tr, (dst, src, ln) = translator(placements, tenant)
    n, o = load_trace(native), load_trace(ours)
    frames = [f for f in sorted(set(n) & set(o))
              if f >= first_event and n[f]["node"] and o[f]["node"]]
    res = {"tenant": tenant, "frames": len(frames), "first": None, "fields": {},
           "outside": sum(1 for f in frames if not (dst <= o[f]["node"] < dst + ln))}
    if not frames:
        res["void"] = "no live frames in the window"
        return res
    for k in TENANT_FIELDS:
        get = (lambda f: tr(o[f]["node"])) if k == "node" else (lambda f, k=k: o[f][k])
        bad = [f for f in frames if n[f][k] != get(f)]
        if bad:
            res["fields"][k] = (len(bad), bad[0])
    if res["fields"]:
        f = min(v[1] for v in res["fields"].values())
        res["first"] = (f, sorted(k for k, v in res["fields"].items() if v[1] == f))
    return res


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("mode", choices=["compare"])
    ap.add_argument("tenant", choices=sorted(ANIM_KEY))
    ap.add_argument("part")
    ap.add_argument("native")
    ap.add_argument("ours")
    ap.add_argument("placements")
    ap.add_argument("--first-event", type=int, required=True)
    ap.add_argument("--events", help="the rig's schedule json, to name the divergent event")
    ap.add_argument("--tsv", action="store_true")
    a = ap.parse_args()
    r = compare(a.tenant, a.native, a.ours, a.placements, a.first_event)
    name = "%s_%s" % (a.tenant, a.part)
    if r.get("void"):
        print("%s\tVOID\t%s" % (name, r["void"]) if a.tsv else "%s: VOID (%s)" % (name, r["void"]))
        return 2
    if r["outside"]:
        print("%s: %d frames hold a node outside the placed anim region — NOT compared blind"
              % (name, r["outside"]), file=sys.stderr)
    if not r["fields"]:
        print("%s\tIDENTICAL\t-\t%d" % (name, r["frames"]) if a.tsv
              else "%s: IDENTICAL over %d frames" % (name, r["frames"]))
        return 0
    f, keys = r["first"]
    ev = "-"
    if a.events:
        events = json.load(open(a.events))["events"]
        before = [e for e in events if e["frame"] <= f]
        if before:
            ev = "%s+%df" % (before[-1]["name"], f - before[-1]["frame"])
    if a.tsv:
        print("%s\tDIVERGES\t%s\t%d\t%s" % (name, ev, r["frames"], ",".join(keys)))
    else:
        print("%s: DIVERGES at f%d (%s) fields %s; %d frames compared"
              % (name, f, ev, ",".join(keys), r["frames"]))
        for k, (cnt, ff) in sorted(r["fields"].items(), key=lambda x: -x[1][0]):
            print("    %-6s %d frames differ, first f%d" % (k, cnt, ff))
    return 1


if __name__ == "__main__":
    sys.exit(main())
