#!/usr/bin/env python3
"""hitbox_parity.py — THE HITBOXES IN PLAY, ours vs native: the reducer of
tests/audit_hitbox_parity.sh (14z-181, GitHub #136).

What "hitboxes in play" reduces to on this engine (tests/test_hitbox_encoding.sh,
14z-120 (5)): every frame the fighter block carries the five RESOLVED table
pointers +0x80..+0x90 (vuln x3, push, attack — base + base[k]), the hitbox base
and family table +0x60/+0x64, and the node's box ids +0x94 (three vuln ids and
the attack id, from the node's hbA word). The boxes the engine tests are those
tables' rows at those ids. So the tenant's hitboxes in play are IDENTICAL on
two legs when, frame for frame from the rig's first event, the node pointer
(translated), the seven pointers (translated out of the build's placements)
and the box-id word are equal — the table BYTES being the ported copy of the
same data (the charmap gates). This tool compares exactly that.

Modes:
  compare <part> <tenant> <native.ft> <ours.ft> <placements.json> --first F [--raw]
      rows: hb <part> <field> SAME|DIFFER n=<differing>/<node-equal frames> first=+<offset> native=<v> ours=<v>
      and a final `hb <part> frames <n> node-equal=<m>` row; --raw skips the translation (the no-translation control)
  plant <ft in> <ft out>      a perturbed copy: one frame's +0x8C (attack table) pointer moved by 0x20
  plant-ids <ft in> <ft out>  a perturbed copy: one frame's box-id word with its attack id +1
"""
import json
import sys

PTR_FIELDS = ("t0", "t1", "t2", "t3", "t4", "hbase", "hcomp")
FIELDS = ("node",) + PTR_FIELDS + ("boxes",)


def load_trace(path):
    out = {}
    for line in open(path):
        f = line.split()
        if len(f) >= 3 and f[0] == "F":
            out[int(f[1])] = {k: int(v) for k, v in (kv.split("=") for kv in f[2:])}
    return out


def write_trace(rows, path):
    with open(path, "w") as fo:
        for f in sorted(rows):
            fo.write("F %d %s\n" % (f, " ".join("%s=%d" % kv for kv in rows[f].items())))


def translator(placements, tenant):
    """ours -> native address over EVERY region placed for the tenant (the merged
    build keys Donovan's regions bare and the others' `<name>@<tenant>`)."""
    regs = json.load(open(placements))["regions"]
    suffix = "" if tenant == "donovan" else "@" + tenant
    spans = []
    for k, r in regs.items():
        if (suffix == "" and "@" not in k) or (suffix and k.endswith(suffix)):
            spans.append((r["dst"], r["dst"] + r["len"], r["src"], k))
    spans.sort()

    def tr(v):
        v &= 0xFFFFFFFF
        for lo, hi, src, _k in spans:
            if lo <= v < hi:
                return v - lo + src
        return v
    return tr, spans


def compare(part, tenant, native, ours, placements, first, raw=False):
    """rows over the NODE-EQUAL frames only: where the two legs are on the same
    node (translated), are the seven resolved pointers (translated) and the box-id
    word equal? A frame whose nodes differ is tests/audit_move_parity.sh's business
    (its DIFF rows, attributed there) and is counted, not compared, here."""
    tr, spans = translator(placements, tenant)
    # --raw (the no-translation control) leaves the POINTER fields untranslated; the node-equal
    # frame set is always found through the translation, or the raw compare would be vacuous
    # (no two raw node pointers ever match across the legs — 14z-181, the first bring-up read a
    # DEAD control on 0/0 frames)
    ptr = (lambda v: v & 0xFFFFFFFF) if raw else tr
    n, o = load_trace(native), load_trace(ours)
    frames = [f for f in sorted(set(n) & set(o)) if f >= first]
    same_node = [f for f in frames if (n[f]["node"] & 0xFFFFFFFF) == tr(o[f]["node"]) and n[f]["node"]]
    rows = []
    for k in FIELDS[1:]:
        get = (lambda f, k=k: o[f][k] & 0xFFFFFFFF) if k == "boxes" else (lambda f, k=k: ptr(o[f][k]))
        bad = [f for f in same_node if (n[f][k] & 0xFFFFFFFF) != get(f)]
        if bad:
            f0 = bad[0]
            rows.append("hb\t%s\t%s\tDIFFER\tn=%d/%d\tfirst=+%d\tnative=%#x\tours=%#x(raw %#x)" % (
                part, k, len(bad), len(same_node), f0 - first, n[f0][k] & 0xFFFFFFFF, get(f0), o[f0][k] & 0xFFFFFFFF))
        else:
            rows.append("hb\t%s\t%s\tSAME\tn=0/%d\tfirst=-\tnative=-\tours=-" % (part, k, len(same_node)))
    rows.append("hb\t%s\tframes\t%d\tnode-equal=%d\tregions=%d" % (part, len(frames), len(same_node), len(spans)))
    return rows


def plant(src, out, what):
    rows = load_trace(src)
    live = [f for f in sorted(rows) if rows[f]["node"]]
    f = live[len(live) // 2]
    if what == "ptr":
        rows[f]["t3"] = (rows[f]["t3"] + 0x20) & 0xFFFFFFFF
    else:
        rows[f]["boxes"] = (rows[f]["boxes"] & 0xFFFFFF00) | ((rows[f]["boxes"] + 1) & 0xFF)
    write_trace(rows, out)
    print("planted %s at f%d" % (what, f))


if __name__ == "__main__":
    a = sys.argv[1:]
    if a[0] == "compare":
        first = int(a[a.index("--first") + 1])
        print("\n".join(compare(a[1], a[2], a[3], a[4], a[5], first, raw="--raw" in a)))
    elif a[0] == "plant":
        plant(a[1], a[2], "ptr")
    elif a[0] == "plant-ids":
        plant(a[1], a[2], "ids")
    else:
        raise SystemExit(__doc__)
