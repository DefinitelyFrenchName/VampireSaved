#!/usr/bin/env python3
"""desktop_audio_check.py — the two sound verdicts of a desktop release run (#226, 14z-194).

  desktop_audio_check.py links  <pw-dump.json> <binary> [<sink>]
      Is the emulator's audio stream LINKED to the sink, and is pw-record linked to the sink's
      monitor? Nodes are matched by `application.process.binary` or `node.name` == <binary>
      (fbneo; MAME's binary is cps2), the sink by `node.name` (default auto_null), the recorder
      by `node.name` or `application.name` == pw-record. Prints
      `LINKS <binary> app_nodes=N app_to_sink_active=K sink_to_recorder_active=M`.
  desktop_audio_check.py signal <wav> <from_s> [<floor_dbfs> [<window_s>]]
      16-bit PCM, plain python (no numpy). Every FULL window starting at or after <from_s>
      (default floor -45 dBFS, window 5 s) must carry RMS above the floor. Prints each window,
      then `SIGNAL windows=N below_floor=B min_rms_dbfs=X`.
Exit 0 always: the gate judges the printed figures against its rule.
"""
import array, json, math, sys, wave


def links(dump, binary, sink="auto_null"):
    objs = json.load(open(dump))
    nodes = {}
    for o in objs:
        if o.get("type") == "PipeWire:Interface:Node":
            p = (o.get("info") or {}).get("props") or {}
            nodes[o["id"]] = p
    app = {i for i, p in nodes.items() if binary in (p.get("application.process.binary"), p.get("node.name"))}
    snk = {i for i, p in nodes.items() if p.get("node.name") == sink}
    recd = {i for i, p in nodes.items() if "pw-record" in (p.get("node.name"), p.get("application.name"))}
    a2s = s2r = 0
    for o in objs:
        if o.get("type") != "PipeWire:Interface:Link":
            continue
        inf = o.get("info") or {}
        if inf.get("state") != "active":
            continue
        out_n, in_n = inf.get("output-node-id"), inf.get("input-node-id")
        if out_n in app and in_n in snk:
            a2s += 1
        if out_n in snk and in_n in recd:
            s2r += 1
    print("LINKS %s app_nodes=%d app_to_sink_active=%d sink_to_recorder_active=%d" % (binary, len(app), a2s, s2r))


def signal(path, from_s, floor=-45.0, win=5.0):
    w = wave.open(path, "rb")
    ch, sw, rate, n = w.getnchannels(), w.getsampwidth(), w.getframerate(), w.getnframes()
    assert sw == 2, "16-bit only"
    a = array.array("h"); a.frombytes(w.readframes(n))
    if sys.byteorder == "big":
        a.byteswap()
    step = int(win * rate) * ch
    start = int(math.ceil(from_s * rate)) * ch
    nwin = below = 0; mn = None
    i = start
    while i + step <= len(a):
        s = a[i:i + step]
        rms = math.sqrt(sum(v * v for v in s) / len(s))
        db = -999.0 if rms <= 0 else 20 * math.log10(rms / 32768.0)
        print("  t=%6.1f-%6.1f s  RMS %7.1f dBFS" % (i / ch / rate, (i + step) / ch / rate, db))
        nwin += 1; below += db <= floor; mn = db if mn is None else min(mn, db)
        i += step
    print("SIGNAL windows=%d below_floor=%d min_rms_dbfs=%s (file %.1f s, from %.1f s, floor %.0f)"
          % (nwin, below, "none" if mn is None else "%.1f" % mn, n / rate, from_s, floor))


if __name__ == "__main__":
    if sys.argv[1] == "links":
        links(*sys.argv[2:])
    elif sys.argv[1] == "signal":
        args = sys.argv[2:]
        signal(args[0], float(args[1]), *(float(x) for x in args[2:]))
    else:
        sys.exit("usage: desktop_audio_check.py links|signal ...")
