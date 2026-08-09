#!/usr/bin/env python3
# check_grab_victim.py — the cross-leg A/B verdict for Phobos' grab-victim
# placement (14z-72/73).
#
# WHAT IT MEASURES. During a grab the VICTIM's on-screen position is written
# every frame by the ATTACKER's capture-pose data. The reported defect is a
# mid-animation teleport of the victim. The two legs run different games
# (native vsav2 vs our vsavjw), so their ABSOLUTE positions differ by a
# fixed camera/origin offset (measured ~21px) — comparing absolute victim-x
# is meaningless and is exactly what stalled 14z-72. This checker compares
# the VICTIM OFFSET RELATIVE TO THE ATTACKER (dx = p2x-p1x, dy = p2y-p1y),
# which cancels the global shift and is the physically meaningful quantity.
#
# REFUSE-TO-JUDGE (the DF-style discipline). A rig that did not actually
# grab measures nothing. The checker FAILS unless BOTH legs show the grab
# seq (P1 +0x06 == 0x0E) and the victim taking damage (P2 hp +0x50 drops by
# >= 0x13). A silent "looks fine" on a whiffed rig is the trap this guards.
#
# ANCHOR. The two legs are aligned on the grab-seq ONSET frame (first frame
# P1 seq == 0x0E), not on absolute frame number — the standard §4
# dual-emulator anchoring.
#
# THE FROZEN QUANTITY is the HORIZONTAL capture-pose placement during the
# on-ground HOLD phase (onset .. onset+HOLD_LEN). The vertical LAUNCH after
# release is governed by the throw-arc tables, a SEPARATE known-open issue
# (replay-80 header: "only the victim throw-arc HEIGHT differs"), so it is
# reported informationally but not gated here.
#
# Usage: check_grab_victim.py <workdir> [--expect differs|matches]
#                             [--onset-seq 0x0E] [--quiet]
#   <workdir> holds native/field.txt and ours/field.txt (field_trace.lua out).
#   --expect differs (default): asserts the defect is PRESENT (the OPEN state).
#   --expect matches:           asserts ours tracks native (post-fix target).

import argparse
import os
import sys

HOLD_LEN = 12          # frames of the on-ground hold to gate on
DIVERGE_MIN = 30       # |Δdx| this large over the hold == defect present
MATCH_TOL = 4          # |Δdx| this small over the hold == tracks native
FRAME_SKEW = 2         # ± frames of cross-emulator phase tolerance (§4: the
                       # two emulators traverse identical states on slightly
                       # different frame indices; the victim's hold keyframes
                       # match native's sequence exactly but ~1 frame apart)
HP_START = 0x120
DMG_MIN = 0x13


def load(path):
    rows = {}
    with open(path) as fh:
        for line in fh:
            if not line.startswith("F "):
                continue
            p = line.split()
            f = int(p[1])
            d = {}
            for kv in p[2:]:
                k, v = kv.split("=")
                d[k] = int(v)
            rows[f] = d
    return rows


def onset(rows, seq):
    for f in sorted(rows):
        if rows[f].get("p1seq") == seq:
            return f
    return None


def connected(rows):
    """(ok, msg): grab seq seen AND victim took >= DMG_MIN damage."""
    seqs = [r.get("p1seq") for r in rows.values()]
    if 0x0E not in seqs:
        return False, "P1 never entered grab seq 0x0E"
    hps = [r["p2hp"] for r in rows.values() if "p2hp" in r]
    if not hps:
        return False, "no p2hp field logged"
    if HP_START - min(hps) < DMG_MIN:
        return False, ("victim HP never dropped by 0x%02X (start 0x%X, min 0x%X)"
                       % (DMG_MIN, HP_START, min(hps)))
    return True, "grab seq 0x0E present, victim took 0x%X damage" % (HP_START - min(hps))


def reloff(row):
    return row["p2x"] - row["p1x"], row["p2y"] - row["p1y"]


def analyse(nat, our, seq):
    n0, o0 = onset(nat, seq), onset(our, seq)
    if n0 is None or o0 is None:
        return None
    shift = o0 - n0                       # map native frame f -> ours f+shift
    hold = []                             # per native hold frame, the PHASE-
    for k in range(HOLD_LEN + 1):         # TOLERANT best match on our leg
        fn = n0 + k
        if fn not in nat:
            continue
        ndx, ndy = reloff(nat[fn])
        # compare native frame fn against the best-aligned ours frame within
        # ±FRAME_SKEW (cross-emulator phase); the residual is the closest one
        best = None
        for j in range(-FRAME_SKEW, FRAME_SKEW + 1):
            fo = o0 + k + j
            if fo not in our:
                continue
            odx, ody = reloff(our[fo])
            cand = (abs(odx - ndx), odx - ndx, ody - ndy, odx, ody)
            if best is None or cand[0] < best[0]:
                best = cand
        if best is None:
            continue
        hold.append((k, best[1], best[2], ndx, best[3], ndy, best[4]))
    return {"n0": n0, "o0": o0, "shift": shift, "hold": hold}


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("workdir")
    ap.add_argument("--expect", choices=("differs", "matches"), default="differs")
    ap.add_argument("--onset-seq", default="0x0E")
    ap.add_argument("--quiet", action="store_true")
    a = ap.parse_args()
    seq = int(a.onset_seq, 0)

    def log(*x):
        if not a.quiet:
            print(*x)

    nat = load(os.path.join(a.workdir, "native", "field.txt"))
    our = load(os.path.join(a.workdir, "ours", "field.txt"))

    # 1. refuse to judge unless BOTH legs actually grabbed
    for tag, rows in (("native", nat), ("ours", our)):
        ok, msg = connected(rows)
        log("  %s: %s" % (tag, msg))
        if not ok:
            print("  - REFUSE TO JUDGE: %s leg did not connect (%s)" % (tag, msg))
            sys.exit(2)

    res = analyse(nat, our, seq)
    if res is None:
        print("  - REFUSE TO JUDGE: no grab-seq onset on one leg")
        sys.exit(2)
    log("  onset: native f%d / ours f%d (align shift %+d)"
        % (res["n0"], res["o0"], res["shift"]))

    peak_dx = max((abs(h[1]) for h in res["hold"]), default=0)
    peak_dy = max((abs(h[2]) for h in res["hold"]), default=0)
    log("  hold phase (onset..+%d): peak |Δdx|=%d  peak |Δdy|=%d"
        % (HOLD_LEN, peak_dx, peak_dy))
    if not a.quiet:
        h0 = res["hold"][0]
        print("    at onset: native reldx=%+d ours reldx=%+d  (Δ=%+d)"
              % (h0[3], h0[4], h0[1]))

    if a.expect == "differs":
        if peak_dx >= DIVERGE_MIN:
            log("  VERDICT: defect PRESENT — victim mis-placed by %dpx horizontally "
                "during the hold (expected)" % peak_dx)
            sys.exit(0)
        print("  - expected the teleport (|Δdx|>=%d) but hold matched within %dpx"
              % (DIVERGE_MIN, peak_dx))
        sys.exit(1)
    else:  # matches
        if peak_dx <= MATCH_TOL:
            log("  VERDICT: victim tracks native (peak |Δdx|=%d <= %d)"
                % (peak_dx, MATCH_TOL))
            sys.exit(0)
        print("  - victim still mis-placed: peak |Δdx|=%d > %d" % (peak_dx, MATCH_TOL))
        sys.exit(1)


if __name__ == "__main__":
    main()
