#!/usr/bin/env python3
"""audit_qs_voice_batch.py — resolve a batch of vs2 sound ids to their
sample windows and classify their portability to vsavj (14z-86, the M5
voice-block batch).

Usage:
    audit_qs_voice_batch.py <vsav2.zip> <vsav.zip> [--ids 0x700-0x71f,0x735,...]
        [--json out.json]

Per id (driver format facts: engine_internals "The QSound Z80 driver";
stream grammar measured 14z-86 from the 0x1186 dispatch table):
  * resolve the song block (extents = gap to the next song start),
  * parse each track's command stream (STRICT: an unknown shape flags the
    song MANUAL rather than guessing — RH-14),
  * resolve cmd-08 note entries through the track's cmd-1F-selected note
    table -> sample records -> sample windows in the vs2 QSound image,
  * content-search vsav's 8 MB image for each window,
  * classify: ONE_NOTE_FOUND (authorable as a type-C song on content
    already in vsav's image), ONE_NOTE_ABSENT (needs the QSound
    extension), MULTI_NOTE_* (needs stream-faithful authoring — the
    chirp class), MANUAL (parser refused).

Prints the SHA-1 of every member read.
"""
import argparse, hashlib, json, os, struct, sys, zipfile

# The QSound sample-window endpoint law, shared with build_qs_songs.py's
# contract and check_qs_voice_batch.py (14z-93, GitHub #82).
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import qs_window  # noqa: E402

# stream grammar: cmd -> operand byte count; measured from the handler
# table @0x1186 (byte-identical interpreters both games, 14z-86)
OPS = {0x00: 0, 0x01: 0, 0x02: 0, 0x03: 0, 0x04: 2, 0x05: 2, 0x06: 1,
       0x07: 1, 0x08: 1, 0x09: 1, 0x0A: 1, 0x0B: 1, 0x0C: 1, 0x0D: 1,
       0x0E: 1, 0x0F: 1, 0x10: 1, 0x11: 1, 0x12: 0, 0x13: 0, 0x14: 0,
       0x15: 0, 0x16: 2, 0x17: 0, 0x18: 1, 0x19: 1, 0x1A: 1, 0x1B: 1,
       0x1C: 1, 0x1D: 1, 0x1E: 1, 0x1F: 1}


def load_driver(zpath, prefix):
    z = zipfile.ZipFile(zpath)
    data = b""
    for n in (prefix + ".01", prefix + ".02"):
        b = z.read(n)
        print(f"read {zpath}:{n} sha1 {hashlib.sha1(b).hexdigest()}")
        data += b
    return data


def anchors(d):
    hdr = struct.unpack_from("<H", d, 0x3B00)[0]
    mod = struct.unpack_from(">H", d, hdr)[0]
    rec = struct.unpack_from("<H", d, 0x3B02)[0]
    # the pointer array runs from 0x3B04 to table 0's own start — vsavj
    # has 7 slots, vs2 has EIGHT (slot 7 = its voice note table, which
    # vsavj lacks; measured 14z-86)
    t0 = struct.unpack_from("<H", d, 0x3B04)[0]
    nslots = (t0 - 0x3B04) // 2
    ntp = [struct.unpack_from("<H", d, 0x3B04 + 2 * i)[0]
           for i in range(nslots)]
    return hdr + 6, mod, rec, ntp


def parse_track(d, pos, table_ptrs, rec_base):
    """Walk one track stream. Returns dict or raises ValueError."""
    nt = table_ptrs[0]          # init default = ptr[0]
    out = {"entries": [], "samples": [], "pitches": [], "vols": [],
           "notes": 0, "waits": 0, "cmds": [], "len": 0}
    start = pos
    for _ in range(4096):
        c = d[pos]; pos += 1
        if c >= 0x20:
            out["waits"] += 1
            continue
        out["cmds"].append(c)
        if c == 0x17:
            out["len"] = pos - start
            return out
        if c == 0x16:
            raise ValueError(f"stream jump (cmd 16) at {pos-1:#x}")
        n = OPS[c]
        ops = d[pos:pos + n]; pos += n
        if c == 0x1F:
            if ops[0] >= len(table_ptrs):
                raise ValueError(f"cmd 1F phantom slot {ops[0]:#x}")
            nt = table_ptrs[ops[0]]
        elif c == 0x08:
            e = ops[0] & 0x7F
            o = nt + e * 4
            smp = struct.unpack_from("<H", d, o)[0] & 0x7FFF
            instr = d[o + 3] & 0x7F
            out["entries"].append({"table": table_ptrs.index(nt), "e": e,
                                   "sample": smp, "instr": instr,
                                   "ixd": d[o + 2]})
            out["samples"].append(smp)
        elif c == 0x07:
            out["pitches"].append(ops[0])
        elif c == 0x19:
            out["vols"].append(ops[0])
    raise ValueError("track never terminated")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("vs2_zip")
    ap.add_argument("vsav_zip")
    ap.add_argument("--ids", default="0x700-0x71f,0x750-0x757,0x735-0x74e,"
                                     "0x720-0x72f")
    ap.add_argument("--json")
    a = ap.parse_args()

    ids = []
    for tok in a.ids.split(","):
        if "-" in tok:
            lo, hi = tok.split("-")
            ids += list(range(int(lo, 16), int(hi, 16) + 1))
        else:
            ids.append(int(tok, 16))

    v2 = load_driver(a.vs2_zip, "vs2")
    zv = zipfile.ZipFile(a.vsav_zip)
    z2 = zipfile.ZipFile(a.vs2_zip)
    q2 = z2.read("vs2.11m") + z2.read("vs2.12m")
    qs = zv.read("vm3.11m") + zv.read("vm3.12m")
    print(f"vs2 image sha1 {hashlib.sha1(q2).hexdigest()}")
    print(f"vsav image sha1 {hashlib.sha1(qs).hexdigest()}")

    table, mod, rec_base, ntp = anchors(v2)
    # song extents: sorted unique starts
    starts = sorted({(v2[table + i * 4] << 16) | (v2[table + i * 4 + 1] << 8)
                     | v2[table + i * 4 + 2]
                     for i in range(mod)} - {0})

    def flat(addr24):
        return addr24          # logical == flat (14z-86)

    results = []
    for i in ids:
        row = table + (i % mod) * 4
        addr = (v2[row] << 16) | (v2[row + 1] << 8) | v2[row + 2]
        r = {"id": i, "addr": addr}
        if addr == 0:
            r["class"] = "FREE"
            results.append(r); continue
        song = flat(addr)
        hdr = v2[song]
        slots = [struct.unpack_from(">H", v2, song + 1 + 2 * k)[0]
                 for k in range(16)]
        live = [(k, w) for k, w in enumerate(slots) if w]
        r["priority"] = hdr
        r["tracks"] = []
        manual = None
        for k, w in live:
            try:
                t = parse_track(v2, song + w, ntp, rec_base)
                t["slot"] = k
                r["tracks"].append(t)
            except ValueError as e:
                manual = str(e)
        if manual:
            r["class"] = "MANUAL"
            r["reason"] = manual
            results.append(r); continue
        # resolve sample windows + content search
        wins = []
        for t in r["tracks"]:
            for s in t["samples"]:
                ro = rec_base + s * 8
                bank, st, lo_, en = (v2[ro],
                                     struct.unpack_from("<H", v2, ro + 1)[0],
                                     struct.unpack_from("<H", v2, ro + 3)[0],
                                     struct.unpack_from("<H", v2, ro + 5)[0])
                # END-INCLUSIVE (packing law #3). CORRECTED 14z-93
                # (GitHub #82) — this read `q2[w0:w1]` and justified it
                # with: "end-EXCLUSIVE: the byte at the end address sits
                # outside the audible window (measured: the chirp differs
                # cross-game in exactly that boundary byte and nothing
                # else, 14z-86)". THAT BELIEF WAS SUPERSEDED AT 14z-87b
                # and the correction never reached this file: the record's
                # `end` is played/looped INCLUSIVE, proven by field width
                # (native windows end at 0xFFFF) and by the sword-plant
                # beep — an exclusive COPY left each packed sample's last
                # played byte holding the next blob's first byte, a
                # ~1.8kHz impulse train to keyoff. build_qs_songs.py:247
                # was fixed then; this audit was not, so the single byte
                # that caused the beep sat OUTSIDE the audit surface and
                # corruption confined to it passed every batch check.
                # The +1 is on the absolute index; `en` may be 0xFFFF, in
                # which case the window ends exactly at the bank boundary.
                # The law lives in tools/qs_window.py (shared with
                # check_qs_voice_batch.py and ground-truthed by
                # tests/test_qs_window_law.sh) so these cannot drift apart
                # again — drifting apart is exactly what happened here.
                w0, w1 = (bank << 16) | st, (bank << 16) | en
                try:
                    blob = qs_window.window(q2, w0, w1)
                except ValueError as exc:
                    sys.exit(f"sample {s:#x}: {exc}")
                at = qs.find(blob) if blob else -1
                wins.append({"sample": s, "rec": v2[ro:ro + 8].hex(),
                             "win": [w0, w1],
                             "size": qs_window.length(w0, w1),
                             "in_vsav": at})
        r["windows"] = wins
        # "one note" here = one pitch event and one sample per song —
        # authorable as a flat type-C record (cmd 01 is a toggle; the
        # sustained note is the wait bytes)
        notes = max((len(t["pitches"]) for t in r["tracks"]), default=0)
        found = all(w["in_vsav"] >= 0 for w in wins) if wins else False
        if not wins:
            r["class"] = "NO_SAMPLE"
        elif notes <= 1 and len(wins) == 1:
            r["class"] = "ONE_NOTE_" + ("FOUND" if found else "ABSENT")
        else:
            r["class"] = "MULTI_" + ("FOUND" if found else "ABSENT")
        results.append(r)

    from collections import Counter
    c = Counter(r["class"] for r in results)
    print("classes:", dict(c))
    absent = sum(w["size"] for r in results for w in r.get("windows", [])
                 if w["in_vsav"] < 0)
    print(f"absent sample bytes total: {absent} ({absent/1024:.0f} KB)")
    for r in results:
        if r["class"] in ("MANUAL", "NO_SAMPLE"):
            print(f"  id {r['id']:#x}: {r['class']} {r.get('reason','')}")
    if a.json:
        json.dump(results, open(a.json, "w"), indent=1)
        print(f"wrote {a.json}")


if __name__ == "__main__":
    main()
