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
  - P2 is a LEGACY character — VS's copy on our leg and VS2's on the native
    one — so his node is never evidence about the port ([VSP-168]). His HP is a
    number and is compared by the caller where it is meaningful. P2 is DEMITRI
    since 14z-165 (maintainer-ruled 2026-09-17; Victor until then): his data
    differs between the games on three chains only (tests/expected/same_data_p2.tsv
    — b:0x10, b:0x71, b:0x74); `p2check` (below) asserts from each leg's own trace
    that he never enters the two ATTACK records (b:0x71/b:0x74, which would corrupt
    his compared HP) and REPORTS his frame count in the pose b:0x10 (the held-pose
    push box every legacy character gained on vs2), which the gate asserts equal on
    both legs — he enters it identically, so its datum difference is a bounded,
    named positional confound for the family pass, not a divergence in what he does.
  - The INTRO (match anchor .. the rig's first event) is excluded: the intro
    variant is an RNG draw at char load, so the two legs play different intros
    unless the RNG is pinned through the load — and pinning it there prevents the
    match loading at all (measured 14z-159, the gate's `pin-through-load` note).

ONLY THE FIRST DIVERGENCE IS INDEPENDENT EVIDENCE — per PART, in `compare`. Once
two legs desynchronise, later events are downstream of the first failure and
are reported as UNKNOWN, not as findings — which is why the part verdict names
the first divergent event and the counts after it are diagnostics.

PER-EVENT VERDICTS (`events`, 14z-164, GitHub #136 proposition 2026-09-17,
maintainer-agreed). The rig re-pins both fighters' X before every event, so
each event is compared IN ITS OWN WINDOW [its frame, the next event's frame)
and judged on its own: IDENT, DIFF (first differing frame and fields), VOID (no
live frames). Two more fields join the tenant's: METER (`RAM:$FF850A`, the
meter fraction — a stock crossing was the only way a meter difference showed
before) and P2HP (`RAM:$FF8850`, P2's HP — damage dealt); these two, the
stock and the tenant's own HP are CUMULATIVE and are compared as their change
from the previous sample; and EVERY compared field the rig itself writes (its
per-event X pin, which lands 40 frames before the next event and so inside the
current window; its P2 HP pin; its stock poke) is excluded ON THE PIN FRAMES,
so an earlier difference is neither carried into every later event as a
constant offset nor turned into a DIFF at the pin frame that resets it, and
agreement on a pinned frame is never counted. The number of excluded samples
is a column of every row (`excluded`), and the gate's `pins-ignored` control
runs the comparison with the exclusion off. A window that
reads IDENT after an earlier DIFF in the same part is reported with
`coupled=after:<k>`: the 14z-164 census measured a one-frame idle-phase
offset persisting through a part, so identical-after-divergence is evidence
only where the window is bit-identical, and a DIFF after one may be downstream.
AND EVERY "in DF" EVENT IS ASSERTED IN DARK FORCE: the DF flag (`RAM:$FF802E`)
must be 1 on at least 90% of the window's frames on BOTH legs, or the verdict
is NOT-IN-DF — 21 of the 24 "in DF" events of Donovan's part 6 ran with the
flag 0 on both legs before this (DF lasts 360 frames; the battery spans 3,850).
An event that ACTIVATES DF (its name carries a DF move: Slay Shred, Ray of
Doom, Shining Gemini) must see the flag rise on both legs, or DF-NOT-ENTERED.

P2CHECK (14z-165). `p2check <trace> <data image> --layout vsav2|vsavj --id 01
--never b:0x71,b:0x74 --report b:0x10 [--from FRAME]` maps P2's sampled anim node pointer
(`p2node`, RAM:$FF881C) onto P2's OWN chain graph as decoded from that leg's
game image (the vs2 data view for the native leg, the build's data view for
ours — tools/audit_same_data_p2.py's node index under the game's bank
layout), asserts P2's id (`p2id`, RAM:$FF8B82) at the first sampled frame, and
FAILS if any sampled frame lies in a chain named by --never. The chains
entered and their frame counts are printed, so the assertion is a printed
number, never an assumption.
"""
import argparse
import json
import sys

TENANT_FIELDS = ("node", "seq", "sub", "cnt", "x", "y", "stock", "face", "df", "p1hp")
EVENT_FIELDS = TENANT_FIELDS + ("meter", "p2hp")
# cumulative fields are compared as their PER-FRAME CHANGE (value minus the value
# at the previous sample), never as absolutes: the meter fraction and HP carry any
# earlier difference forward as a constant offset, and the first freeze read 79 of
# 151 DIFF rows as "meter at +0" — the offset, masking everything behind it. And a
# frame on which the RIG ITSELF writes the field (its P2 HP pin every 400 frames,
# its stock poke) is EXCLUDED for that field: both legs jump to the pinned value
# from possibly different values, so the change differs there by construction —
# a change-from-window-start comparison froze a DIFF against the event that
# happened to hold the pin (rule-checker run 2026-09-17-24, Q4). The pin frames
# come from the rig's own schedule json (`pokes`), per address.
CUMULATIVE = ("meter", "p2hp", "stock", "p1hp")
# every compared field the rig can write, by address: a frame on which the schedule
# writes it is excluded for that field, cumulative or not — the per-event X pin at
# $FF8410 lands 40 frames BEFORE the next event, i.e. inside the current window, and
# an absolute x compared on that frame agrees by the pin's doing (run 2026-09-17-25 Q3)
FIELD_ADDR = {"meter": 0xFF850A, "p2hp": 0xFF8850, "stock": 0xFF8509, "p1hp": 0xFF8450, "x": 0xFF8410, "y": 0xFF8414}
DF_MOVES = ("Slay Shred", "Ray of Doom", "Shining Gemini")
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


def compare_events(tenant, native, ours, placements, events, pokes, exclude_pins=True):
    """one verdict per event, each in its own window; returns a list of dicts.
    `pokes` is the rig's own schedule (`frame:addr:value` strings, REQUIRED — a
    schedule without the key is refused, an empty list is fine): a frame on which
    the rig writes a compared field is excluded for that field. `exclude_pins=False`
    is the gate's `pins-ignored` control. Every result carries `excluded`, the
    number of (frame, field) samples the exclusion removed, so its liveness is
    a printed number, never an assumption."""
    tr, (dst, src, ln) = translator(placements, tenant)
    n, o = load_trace(native), load_trace(ours)
    fr = sorted(set(n) & set(o))
    pinned = {}  # addr -> set of frames the rig writes it
    if exclude_pins:
        for pk in pokes:
            f, addr, _ = pk.split(":")
            pinned.setdefault(int(addr, 16), set()).add(int(f))
    prev = {f: fr[i - 1] for i, f in enumerate(fr) if i > 0}
    excluded_total = 0
    out = []
    first_diff_k = None
    for k, e in enumerate(events):
        lo = e["frame"]; hi = events[k + 1]["frame"] if k + 1 < len(events) else (fr[-1] + 1 if fr else lo)
        win = [f for f in fr if lo <= f < hi]
        live = [f for f in win if n[f]["node"] and o[f]["node"]]
        row = {"k": k, "name": e["name"], "frames": len(live), "coupled": ("after:%d" % first_diff_k) if first_diff_k is not None else "-", "excluded": 0}
        if not live:
            row.update(verdict="VOID", first="-", fields="-"); out.append(row); continue
        # the DF assertions come first: a mislabelled window is not compared as the move it names
        dfn = sum(1 for f in win if n[f]["df"] == 1); dfo = sum(1 for f in win if o[f]["df"] == 1)
        if "in DF" in e["name"] and (dfn < 0.9 * len(win) or dfo < 0.9 * len(win)):
            row.update(verdict="NOT-IN-DF", first="-", fields="df native %d/%d ours %d/%d" % (dfn, len(win), dfo, len(win))); out.append(row); continue
        if any(m in e["name"] for m in DF_MOVES):
            rose_n = any(n[f]["df"] == 1 for f in win) and n[win[0]]["df"] != 1
            rose_o = any(o[f]["df"] == 1 for f in win) and o[win[0]]["df"] != 1
            if not (rose_n and rose_o):
                row.update(verdict="DF-NOT-ENTERED", first="-", fields="rose native %s ours %s" % (rose_n, rose_o)); out.append(row); continue
        bad = {}
        excluded = 0
        for key in EVENT_FIELDS:
            pins = pinned.get(FIELD_ADDR.get(key, -1), set())
            use = [f for f in live if f not in pins]
            excluded += len(live) - len(use)
            if key == "node":
                b = [f for f in use if n[f]["node"] != tr(o[f]["node"])]
            elif key in CUMULATIVE:
                b = [f for f in use if f in prev
                     and n[f][key] - n[prev[f]][key] != o[f][key] - o[prev[f]][key]]
            else:
                b = [f for f in use if n[f][key] != o[f][key]]
            if b: bad[key] = (len(b), b[0])
        row["excluded"] = excluded; excluded_total += excluded
        if bad:
            f0 = min(v[1] for v in bad.values())
            keys = sorted(k2 for k2, v in bad.items() if v[1] == f0)
            row.update(verdict="DIFF", first="+%d" % (f0 - lo), fields=",".join(keys))
            if first_diff_k is None: first_diff_k = k
        else:
            row.update(verdict="IDENT", first="-", fields="-")
        out.append(row)
    return out


def p2_chain_index(image_path, layout, cid, bank_map=None):
    """{node address: (table, seq)} for one legacy character under one game's
    bank layout — tools/audit_same_data_p2.py's index, normalised to ints."""
    import os
    sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
    import _minitoml
    import audit_same_data_p2 as sd
    bank_map = bank_map or os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "build", "manifest", "bank_map.toml")
    bank = _minitoml.loads(open(bank_map).read())
    orig = {"vsavj": int(bank["origins"]["vsavj"]), "vsav2": int(bank["origins"]["vsav2"])}
    delta = orig[layout] - orig["vsavj"]
    rows = {t["name"]: int(t["vsavj"]) for t in bank["table"]}
    img = open(image_path, "rb").read()
    out = {}
    for addr, (table, seq, _k) in sd.node_index(img, rows, delta, cid).items():
        a = int(addr, 16) if isinstance(addr, str) else int(addr)
        q = int(seq, 0) if isinstance(seq, str) else int(seq)
        out[a] = (table, q)
    return out


def p2check(trace, image, layout, cid, never, first, report=()):
    """P2's identity and chain history from one leg's trace; returns (ok, lines).
    `never` chains FAIL (attack records that would corrupt P2's compared HP);
    `report` chains are counted and printed as `P2REPORT: <chain>=<n>` for the
    caller to assert equal on both legs — a pose whose datum differs (b:0x10 the
    held-pose push box) is entered legitimately, and equal counts prove the
    difference is the datum, not a behavioural cascade (run 2026-09-17-29 Q4)."""
    t = load_trace(trace)
    frames = sorted(f for f in t if f >= first)
    lines = []
    if not frames:
        return False, ["FAIL: no sampled frame at or after %d" % first]
    f0 = frames[0]
    if "p2id" not in t[f0] or "p2node" not in t[f0]:
        return False, ["FAIL: the trace carries no p2id/p2node field (sample RAM:$FF8B82 and RAM:$FF881C)"]
    got = t[f0]["p2id"]
    lines.append("p2 id at f%d: %#04x (want %#04x)" % (f0, got, cid))
    ok = got == cid
    idx = p2_chain_index(image, layout, cid)
    seen = {}
    unmapped = 0
    for f in frames:
        n = t[f]["p2node"] & 0xFFFFFFFF
        k = idx.get(n)
        if k is None:
            if n: unmapped += 1
            continue
        seen[k] = seen.get(k, 0) + 1
    names = {"%s:0x%02x" % k: v for k, v in seen.items()}
    lines.append("p2 chains entered over %d frames (%d unmapped non-zero nodes): %s" % (
        len(frames), unmapped, " ".join("%s=%d" % kv for kv in sorted(names.items()))))
    for nv in never:
        if nv in names:
            ok = False
            lines.append("FAIL: P2 entered %s on %d frame(s) — a chain whose data differs between the games" % (nv, names[nv]))
    rep = " ".join("%s=%d" % (r, names.get(r, 0)) for r in report)
    if report:
        lines.append("P2REPORT: " + rep)
    if unmapped > 0.05 * len(frames):
        ok = False
        lines.append("FAIL: %d of %d frames hold a P2 node outside P2's decoded graph — the image or layout is not this leg's" % (unmapped, len(frames)))
    return ok, lines


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("mode", choices=["compare", "events", "p2check"])
    ap.add_argument("tenant", help="compare/events: the tenant; p2check: the TRACE file")
    ap.add_argument("part", help="compare/events: the part; p2check: the game's DATA IMAGE for P2's leg")
    ap.add_argument("native", nargs="?")
    ap.add_argument("ours", nargs="?")
    ap.add_argument("placements", nargs="?")
    ap.add_argument("--first-event", type=int)
    ap.add_argument("--layout", choices=("vsav2", "vsavj"), help="p2check: the bank layout the image is read with")
    ap.add_argument("--id", help="p2check: P2's character id, hex (Demitri 01)")
    ap.add_argument("--never", default="b:0x71,b:0x74", help="p2check: attack-record chains P2 must NEVER enter (they carry P2 damage, a compared field; comma-separated table:0xNN)")
    ap.add_argument("--report", default="b:0x10", help="p2check: pose chains whose data differs but which P2 may enter — their frame count is PRINTED as P2REPORT for the caller to assert equal on both legs (comma-separated table:0xNN)")
    ap.add_argument("--from", dest="from_frame", type=int, default=0, help="p2check: first frame to judge (default: every sampled frame)")
    ap.add_argument("--events", help="the rig's schedule json, to name the divergent event")
    ap.add_argument("--tsv", action="store_true")
    ap.add_argument("--no-pin-exclusion", action="store_true", help="events: compare on the rig's pin frames too (the gate's pins-ignored control)")
    a = ap.parse_args()
    if a.mode == "p2check":
        if not (a.layout and a.id):
            print("p2check needs --layout and --id", file=sys.stderr); return 2
        ok, lines = p2check(a.tenant, a.part, a.layout, int(a.id, 16), [x for x in a.never.split(",") if x], a.from_frame, [x for x in a.report.split(",") if x])
        print("\n".join(lines))
        return 0 if ok else 1
    if a.tenant not in ANIM_KEY:
        print("unknown tenant %s" % a.tenant, file=sys.stderr); return 2
    if a.first_event is None or not (a.native and a.ours and a.placements):
        print("%s needs <native> <ours> <placements> --first-event N" % a.mode, file=sys.stderr); return 2
    name = "%s_%s" % (a.tenant, a.part)
    if a.mode == "events":
        if not a.events:
            print("events mode needs --events <schedule.json>", file=sys.stderr); return 2
        sched = json.load(open(a.events))
        if "pokes" not in sched:
            print("%s: the schedule has no `pokes` key — refusing (the pin exclusion would be silently empty)" % name, file=sys.stderr); return 2
        rows = compare_events(a.tenant, a.native, a.ours, a.placements, sched["events"], sched["pokes"], exclude_pins=not a.no_pin_exclusion)
        for r in rows:
            print("%s\t%d\t%s\t%s\t%s\t%s\t%d\t%s\t%d" % (name, r["k"], r["name"], r["verdict"], r["first"], r["fields"], r["frames"], r["coupled"], r["excluded"]))
        return 0 if all(r["verdict"] == "IDENT" for r in rows) else 1
    r = compare(a.tenant, a.native, a.ours, a.placements, a.first_event)
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
