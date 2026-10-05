#!/usr/bin/env python3
"""landing_sound_ab.py — THE TENANTS' LANDING SOUND, native vs2 against ours (GitHub #223, 14z-191).

The landing-sound request (vsavj PRG:0x00395E, vs2 0x003994; requests 0x10a, or 0x10c when +0x11f is set) adds +1 to
the id for the characters its mask names — the big bodies. vsavj's mask $04480448 and vs2's $04410448 share the low
half (Victor 0x03, Anakaris 0x06, Sasquatch 0x0A); in the high half vsavj sets bit 0x13 (Victor's +0x10 mirror on
vsavj) and vs2 sets bit 0x10 (Phobos) in its place, 0x13 being Donovan there. Ours runs vsavj's mask, so Phobos lands
with the ordinary sound and Donovan with the big-body one: vs2 the other way round. The second site with the same mask
(vsavj 0x003B36, vs2 0x003B6C; request 0x17c, keyed on the character at +0x32) is not reached by these rigs.

  python3 tools/landing_sound_ab.py hits <naming json> <native tap> <ours tap> <tenant id hex>
        the read-tap hits of the site (tests/lua/read_tap.lua, RPCS = the site's +0x382 read): the same frames on both
        games, every P1 hit on the tenant's id, and the first `Jump [8]` hit (the landing the audio check cuts at).
  python3 tools/landing_sound_ab.py wav <native.wav> <ours.wav> <landing frame> <run frames> <louder: native|ours>
        [--plant-same]
        two one-second windows: CONTROL (1.25 to 0.25 s before the landing, no landing sound) and LANDING (0.25 s before
        to 0.75 s after). PASS when the landing difference is over 4x the control difference and the leg named
        `louder` has the higher landing RMS. `--plant-same` copies native's landing window over ours' (the must-fire
        control: the gap must then fail).
"""
import array
import json
import math
import sys
import wave


def hits(js, nat, ours, tid):
    ev = json.load(open(js))["events"]
    def read(p):
        out = []
        for l in open(p):
            if l.startswith("R "):
                f = l.split()
                out.append((int(f[1]), f[5], f[7]))     # frame, address, data
        if not any(l.startswith("END") for l in open(p)):
            raise SystemExit(f"FAIL: {p}: no END line — the tap did not complete")
        return out
    a, b = read(nat), read(ours)
    fa, fb = [x[0] for x in a], [x[0] for x in b]
    p1 = [x for x in a if x[1] == "ff8782"]
    bad = []
    if not p1:
        bad.append("no P1 hit on native: the rig produced no landing")
    if fa != fb:
        bad.append(f"hit frames differ: native {len(fa)}, ours {len(fb)}")
    want = f"0000{int(tid, 16):02x}00"
    wrong = [x for x in a + b if x[1] == "ff8782" and x[2].lower() != want]
    if wrong:
        bad.append(f"{len(wrong)} P1 hit(s) not on id {tid}: {wrong[:2]}")
    j8 = [e for e in ev if e["name"] == "Jump [8]"][0]["frame"]
    land = [f for f, ad, _ in p1 if j8 <= f < j8 + 60]
    print(f"  {len(fa)} hits on both games ({len(p1)} P1), the same frames: {fa == fb}; Jump [8] landing at "
          f"{land[0] if land else 'NONE'}")
    for m in bad:
        print(f"  MISMATCH {m}")
    if not land:
        print("  MISMATCH no landing hit after Jump [8]"); return 1, None
    return (1 if bad else 0), land[0]


def window(path, frame, run_frames, off):
    w = wave.open(path); rate = w.getframerate(); fps = run_frames / (w.getnframes() / rate)
    w.setpos(int((frame / fps + off) * rate)); d = array.array("h", w.readframes(rate)); w.close()
    return d


def rms(v):
    return math.sqrt(sum(x * x for x in v) / len(v))


def diff(a, b):
    m = min(len(a), len(b))
    return math.sqrt(sum((a[i] - b[i]) ** 2 for i in range(m)) / m)


def wav(nat, ours, frame, run_frames, louder, plant=False):
    cn, co = window(nat, frame, run_frames, -1.25), window(ours, frame, run_frames, -1.25)
    ln, lo = window(nat, frame, run_frames, -0.25), window(ours, frame, run_frames, -0.25)
    if plant:
        lo = ln
    dc, dl = diff(cn, co), diff(ln, lo)
    rn, ro = rms(ln), rms(lo)
    print(f"  control window difference rms {dc:.0f}; landing window difference rms {dl:.0f}; "
          f"landing rms native {rn:.0f}, ours {ro:.0f}")
    bad = []
    if not dl > 4 * max(dc, 1):
        bad.append(f"the landing window is not over 4x the control's difference ({dl:.0f} vs {dc:.0f})")
    if (rn > ro) != (louder == "native"):
        bad.append(f"the louder landing is not {louder}'s")
    for m in bad:
        print(f"  MISMATCH {m}")
    return 1 if bad else 0


def main(a):
    if a[:1] == ["hits"] and len(a) == 5:
        rc, land = hits(*a[1:5])
        if land is not None:
            print(f"LANDING {land}")
        return rc
    if a[:1] == ["wav"] and len(a) >= 6 and a[5] in ("native", "ours"):
        return wav(a[1], a[2], int(a[3]), int(a[4]), a[5], "--plant-same" in a[6:])
    print(__doc__); return 2


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
