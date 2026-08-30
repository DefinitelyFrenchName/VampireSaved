#!/usr/bin/env python3
"""advancing_guard.py — reduce a field_trace of the ADVANCING GUARD rig
(tools/name_moves.py donovan_victim part 4) to one frozen line per event.

  python3 tools/advancing_guard.py <field_trace.txt> <schedule.json> <data_view.bin> <lists_hex> --ids P1,P2

  lists_hex   the PRG address of the push step-list word table (vs2 0x2797A,
              vsavj 0x2871C), read from the DATA view — the measured per-frame
              x steps of the pushed attacker are compared against the bytes the
              engine indexes, never against numbers typed into this file.

Per event (the attacker is P1 at $FF8400, the blocker/masher P2 at $FF8800):
  <event>  block=+<f>  win=<+0x1AB at the block>  taps=<n>  counter=<v0,v1,...>  push=+<f>|none
           idx=<+0x59>  face=<P1 +0x0B>/<+0x5D>  steps=<n>f/<px>px  list=MATCH|MISMATCH  flags=<+0x184>,<+0x171>,<+0x3B5>,<+0x5C>
  block    first frame P2's guard-mash window +0x1AB rises (the block landed); none = no block
  win      the window's opening value (14 on both games)
  taps     P2 new-press frames (+0x126 & 0x77) while the window was open
  counter  the distinct values P2's +0x170 takes during the event, in order
  push     first frame the attacker's +0x185 rises (the guard push fired); none = never
  idx      the attacker's +0x59 at that frame = the step list chosen (0/1/2)
  face     the attacker's flip_x +0x0B and step-sign +0x5D at that frame
  steps    frames with +0x185 set, and the sum of the attacker's per-frame x deltas
  list     the per-frame x deltas equal the chosen list's bytes (signed by +0x5D)
  flags    the blocker's +0x184 / +0x171 / +0x3B5 / +0x5C at the push frame
"""
import argparse
import json
import sys


def load(trace):
    rows = {}
    for l in open(trace):
        f = l.split()
        if len(f) < 3 or f[0] != "F":
            continue
        rows[int(f[1])] = {k: int(v) for k, v in (kv.split("=") for kv in f[2:])}
    return rows


def lists(img, base):
    d = open(img, "rb").read()
    out = []
    for i in range(3):
        off = int.from_bytes(d[base + 2 * i:base + 2 * i + 2], "big")
        p = base + off
        steps = []
        while d[p] < 0x80:
            steps.append(d[p]); p += 1
        out.append(steps)
    return out


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("trace"); ap.add_argument("sched"); ap.add_argument("image"); ap.add_argument("lists")
    ap.add_argument("--ids", required=True)
    a = ap.parse_args()
    rows = load(a.trace)
    ev = [e for e in json.load(open(a.sched))["events"] if not e["name"].startswith(("walk-in", "P2 blocks"))]
    L = lists(a.image, int(a.lists, 16))
    want = tuple(int(x, 16) for x in a.ids.split(","))
    ids = {(v["id"], v["p2id"]) for v in rows.values()}
    assert ids == {want}, f"ids {ids} != {want}"
    print(f"# ids={want[0]:#04x},{want[1]:#04x} lists@{a.lists}: " + " | ".join(f"{i}:{len(s)}f/{sum(s)}px" for i, s in enumerate(L)))
    for i, e in enumerate(ev):
        lo = e["frame"]
        hi = ev[i + 1]["frame"] if i + 1 < len(ev) else max(rows) + 1
        fr = [f for f in sorted(rows) if lo <= f < hi]
        block = next((f for f in fr if rows[f]["p2_1ab"] and not rows[f - 1]["p2_1ab"]), None) if fr else None
        if block is None:
            print(f"{e['name']}\tblock=none")
            continue
        win = rows[block]["p2_1ab"]
        open_frames = [f for f in fr if f >= block and rows[f]["p2_1ab"]]
        taps = sum(1 for f in open_frames if rows[f]["p2_126"] & 0x77)
        counter = []
        for f in fr:
            v = rows[f]["p2_170"]
            if not counter or counter[-1] != v:
                counter.append(v)
        push = next((f for f in fr if rows[f]["p1_185"]), None)
        head = f"{e['name']}\tblock=+{block - lo}\twin={win}\ttaps={taps}\tcounter={','.join(map(str, counter))}"
        if push is None:
            print(head + "\tpush=none")
            continue
        r = rows[push]
        span = [f for f in fr if rows[f]["p1_185"]]
        deltas = [rows[f]["p1x"] - rows[f - 1]["p1x"] for f in span]
        idx = r["p1_59"]
        expect = L[idx] if idx < len(L) else []
        sign = 1 if r["p1_5d"] else -1
        # TICK-AWARE: the game runs two engine ticks in one video frame periodically (the
        # speed setting), so a frame's x delta is the sum of the list bytes consumed between
        # successive samples of the step counter +0x1B0 — never assume one byte per frame.
        # The LAST byte can be consumed in the same frame as the terminator (two ticks:
        # step, then the negative byte clears +0x185 and +0x1B0), so the frame after the
        # flag drops belongs to the push when the list is not yet fully consumed.
        ok = bool(expect); prev = 0
        for f in span:
            c = rows[f]["p1_1b0"]
            if c < prev or c > len(expect):
                ok = False; break
            if rows[f]["p1x"] - rows[f - 1]["p1x"] != sign * sum(expect[prev:c]):
                ok = False; break
            prev = c
        if ok and prev < len(expect):
            f = span[-1] + 1
            if f in rows and rows[f]["p1_1b0"] == 0 and rows[f]["p1x"] - rows[f - 1]["p1x"] == sign * sum(expect[prev:]):
                span = span + [f]; deltas = deltas + [rows[f]["p1x"] - rows[f - 1]["p1x"]]; prev = len(expect)
        ok = ok and prev == len(expect)
        match = "MATCH" if ok else "MISMATCH"
        print(head + f"\tpush=+{push - lo}\tidx={idx}\tface={r['p1face']}/{r['p1_5d']}\tsteps={len(span)}f/{sum(deltas)}px\tlist={match}"
              f"\tflags={r['p2_184']},{r['p2_171']:#x},{r['p2_3b5']},{r['p2_5c']}")


if __name__ == "__main__":
    sys.exit(main())
