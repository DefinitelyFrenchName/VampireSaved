#!/usr/bin/env python3
"""tick_durations.py — MEASURE A CHAIN'S DURATION IN ENGINE TICKS, not frames
(14z-126b).

WHY IT EXISTS.  `field_trace` samples once per FRAME, and ~16% of frames
advance the anim node countdown by TWO ticks (some by three or four), so a
frame-rate trace CANNOT adjudicate a one-frame convention -- which is what
left Jedah's crouching recovery (+3 where every other character reads +2)
open at 14z-125b.  A memory WRITE TAP fires per WRITE, so it sees every tick.

THE INSTRUMENT, one tap over `+0x1C..+0x23` of a fighter block:
  PRG:0x027EE8  move.l ...,$1c(a6)   the ANIM POINTER  (node entry, pair 1/2)
  PRG:0x027EEC  move.l (a0),$20(a6)  the node's DURATION + ptr (pair 2/2)
  PRG:0x027F70  subq.b #$1,$20(a6)   ONE ENGINE TICK
  PRG:0x027F88  st.b   $21(a6)       a different byte -- ignored
(engine_internals "THE ENGINE TICK IS DIRECTLY OBSERVABLE".)

TWO TRAPS THIS TOOL EXISTS TO AVOID, both paid for:
  * TAP ON AN EVEN, WORD-ALIGNED RANGE.  A 1-byte tap on this 16-bit bus
    returns a CLEAN ZERO for a field written ~1.5x per frame
    (docs/platform/gotchas.md).
  * SEGMENT BY THE ANIM POINTER.  The crouch IDLE animation ticks
    continuously, so ticks counted over a rig window measure the IDLE, not the
    move -- every move comes out identical, which is what a wrong reading
    looks like.

Usage:
  tools/tick_durations.py <tap.txt> <derived.json> <CHAR> [--set crouch]
`derived.json` is `tools/vanilla_frames.py --json` output; each chain there
carries its `start` (the chain's first node address) and `nodes` count.
"""
import argparse, json, re, sys
from collections import defaultdict

PC_PTR, PC_DUR, PC_TICK = "027ee8", "027eec", "027f70"


def parse(path, base):
    """-> ordered events: ('ptr', frame, value) and ('tick', frame, None)."""
    hi, ev = {}, []
    for ln in open(path):
        if not ln.startswith("frame"):
            continue
        p = ln.split()
        fr, pc, off, data = int(p[1]), p[3], int(p[5], 16), int(p[7], 16) & 0xFFFF
        if pc == PC_TICK and off == base + 0x20:
            ev.append(("tick", fr, None))
        elif pc == PC_PTR:
            # the longword lands as two word writes: +0x1C (high), +0x1E (low)
            if off == base + 0x1C:
                hi[fr] = data
            elif off == base + 0x1E and fr in hi:
                ev.append(("ptr", fr, (hi.pop(fr) << 16) | data))
    return ev


NODE_STRIDE = 0x18          # measured: consecutive in-chain node pointers


def durations(ev, starts, nodes):
    """Ticks consumed by ONE FORWARD PASS through each chain.

    A pass is closed by whichever comes first:
      * a BACKWARD STEP inside the chain -- the chain looped. An aerial normal
        repeats until landing, back to the start (BI J.LP) or to a late node
        (BI J.MP, 0x1c6ed6 -> 0x1c6ebe).
      * the pointer LEAVING the chain's address range -- the ordinary ending
        for a grounded normal, and the condition that reproduces the engine
        EXACTLY on all 18 grounded chains measured.

    WHAT DOES NOT WORK, both tried and both leaving a signature:
      * range-exit ALONE measures the crouch IDLE (grounded, if the chain is
        re-entered) or the AIRTIME (aerial), reporting the SAME number for
        every move -- identical numbers across different moves are the tell.
      * closing after the Nth node entry stops before the last node's duration
        is consumed and under-reports every grounded chain by ~2 ticks.

    KNOWN LIMIT, stated rather than hidden: an aerial whose last node HOLDS
    without the pointer moving again before landing (VI, FE, SA) is closed by
    neither condition, and still reports airtime. Those are not separable by
    this instrument as it stands.
    """
    out = defaultdict(list)
    rng = {m: (s, s + nodes[m] * NODE_STRIDE) for m, s in starts.items()}
    cur, ticks, prev = None, 0, None
    for kind, fr, val in ev:
        if kind == "tick":
            if cur is not None:
                ticks += 1
            continue
        if cur is not None:
            lo, hi = rng[cur]
            if (lo <= val < hi and prev is not None and val < prev) or not (lo <= val < hi):
                out[cur].append(ticks)
                cur, ticks = None, 0
        if cur is None:
            for m, st in starts.items():
                if val == st:
                    cur, ticks = m, 0
                    break
        prev = val
    if cur is not None:
        out[cur].append(ticks)
    return out


def main():
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("tap"); ap.add_argument("derived"); ap.add_argument("char")
    ap.add_argument("--base", default="ff8400", help="fighter block (default P1)")
    ap.add_argument("--prefix", default="2", help="move-name prefix to report")
    a = ap.parse_args()
    base = int(a.base, 16)
    d = json.load(open(a.derived))
    ch = d["characters"][a.char]["chains"]
    starts, derived = {}, {}
    for k, c in ch.items():
        mv = c.get("move", "")
        if not mv.startswith(a.prefix) or not c.get("frame_data"):
            continue
        starts[mv] = int(c["start"], 16)
        fd = c["frame_data"]
        derived[mv] = (fd.get("startup"), fd.get("active"), fd.get("recovery"),
                       c.get("frames"), c.get("nodes"))
    if not starts:
        sys.exit(f"no chains with prefix {a.prefix!r} for {a.char}")
    ev = parse(a.tap, base)
    ticks = sum(1 for e in ev if e[0] == "tick")
    ptrs = sum(1 for e in ev if e[0] == "ptr")
    print(f"# {a.tap}: {ticks} ticks, {ptrs} node entries, base 0x{base:06x}")
    got = durations(ev, starts, {m: derived[m][4] for m in starts})
    print(f"{'move':6} {'derived s/a/r':16} {'total':>6} {'nodes':>5}   measured ticks")
    for mv in sorted(starts):
        s, act, r, tot, n = derived[mv]
        seen = got.get(mv, [])
        print(f"  {mv:5} {str(s)+'/'+str(act)+'/'+str(r):16} {str(tot):>6} {str(n):>5}   "
              f"{seen if seen else 'NOT ENTERED'}")
    missing = [m for m in starts if m not in got]
    if missing:
        print("\nNOT ENTERED (the rig never ran these, or the chain start moved): "
              + ", ".join(sorted(missing)))
    return 0


if __name__ == "__main__":
    sys.exit(main())
