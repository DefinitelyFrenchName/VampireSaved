#!/usr/bin/env python3
"""check_qs_voice_wav.py — ear-level spectral A/B of paired voice-sweep
WAV captures (14z-86). usage:
    check_qs_voice_wav.py <ours.wav> <native.wav> <ledger.json>

Per injection window (240-frame spacing, FIRST=1050): RMS + first-difference
high-band energy. A window is SUSPECT when ours' hi/rms ratio collapses
below 0.6x native's or RMS departs 2x either way — the signature of the
half-bank truncation class this instrument CAUGHT (a sample window
straddling bank offset 0x8000 dies at once under the DSP's SIGNED 16-bit
pointer compare; register- and content-level A/Bs were BLIND to it, since
the records and bytes were all "correct").
"""
import json, math, struct, sys, wave


def load(path):
    w = wave.open(path)
    r, n = w.getframerate(), w.getnframes()
    raw = w.readframes(n)
    s = struct.unpack("<%dh" % (len(raw) // 2), raw)
    if w.getnchannels() == 2:
        s = [(s[i] + s[i + 1]) // 2 for i in range(0, len(s) - 1, 2)]
    return r, s


def metrics(s, a, b):
    seg = s[a:b]
    if len(seg) < 2:
        return 0.0, 0.0
    rms = math.sqrt(sum(x * x for x in seg) / len(seg))
    hi = math.sqrt(sum((seg[i] - seg[i - 1]) ** 2
                       for i in range(1, len(seg))) / len(seg))
    return rms, hi


def main():
    ro, so = load(sys.argv[1])
    rn, sn = load(sys.argv[2])
    led = json.load(open(sys.argv[3]))
    sus, rows = [], 0
    for i, v in enumerate(led["voices"]):
        f0 = 1050 + 240 * i
        a, b = int(f0 / 60 * ro), int((f0 + 200) / 60 * ro)
        mo, mn = metrics(so, a, b), metrics(sn, a, b)
        if mo[0] < 50 and mn[0] < 50:
            continue
        rows += 1
        q_o = mo[1] / mo[0] if mo[0] else 0
        q_n = mn[1] / mn[0] if mn[0] else 0
        if q_n > 0 and (q_o < 0.6 * q_n or mo[0] < 0.5 * mn[0]
                        or mo[0] > 2 * mn[0]):
            sus.append((v["vs2_id"], mo, mn))
    print(f"{rows} sounding windows; {len(sus)} suspects")
    for vid, mo, mn in sus:
        print("  vs2 %03x: RMS %.0f/%.0f hi/rms %.3f/%.3f"
              % (vid, mo[0], mn[0],
                 mo[1] / mo[0] if mo[0] else 0,
                 mn[1] / mn[0] if mn[0] else 0))
    sys.exit(1 if sus else 0)


if __name__ == "__main__":
    main()
