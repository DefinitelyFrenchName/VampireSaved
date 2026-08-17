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

# CPS-2 DOES NOT RUN AT 60 Hz (14z-94, GitHub #85). The sweep schedules its
# injections by emulated FRAME (tests/lua/qs_sweep.lua: frame >= firstf and
# (frame - firstf) % stepf == 0); this file converts those frames to WAV
# sample offsets. Doing that at a literal 60 accumulates error against the
# real cadence, and the error is one-directional:
#
#     voice  0  frame  1050   60Hz 17.500s   real 17.606s   drift +0.106s
#     voice 40  frame 10650   60Hz 177.500s  real 178.579s  drift +1.079s
#     voice 79  frame 20010   60Hz 333.500s  real 335.528s  drift +2.028s
#
# The window is 200 frames = 3.354s wide, so by the end of an 80-id sweep the
# examined window has slipped more than HALF A WINDOW off the injection it is
# supposed to measure. A late voice that is shortened, delayed or missing can
# then be "verified" against residual audio from a neighbouring event.
#
# Derived from MAME's own constants (emu/mame/src/mame/capcom/cps1.h:39-45,
# used by cps2.cpp:1765 set_raw) rather than pasted as 59.637405, so the
# derivation is checkable and a re-pin of the emulator is visible here.
CPS_PIXEL_CLOCK = 16_000_000 / 2
CPS_HTOTAL, CPS_VTOTAL = 512, 262
CPS_HZ = CPS_PIXEL_CLOCK / (CPS_HTOTAL * CPS_VTOTAL)   # 59.637405...

# The sweep's schedule, matching tests/lua/qs_sweep.lua's defaults and the
# STEP=240 the audits pass. Shared so the audit's verdict control cannot
# compute a different window than the checker it is testing — which is
# exactly what a second literal 60 did.
FIRST_FRAME, STEP_FRAMES, WINDOW_FRAMES = 1050, 240, 200


def window(i, rate, frames=WINDOW_FRAMES):
    """(start, end) sample offsets of voice `i`'s window at WAV rate `rate`."""
    f0 = FIRST_FRAME + STEP_FRAMES * i
    return int(f0 / CPS_HZ * rate), int((f0 + frames) / CPS_HZ * rate)


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
    # Both windows are computed at `ro` below, so a rate mismatch would slice
    # the native leg at the wrong place and compare unrelated audio. Same
    # class as the frame-rate drift above, so it is checked rather than
    # assumed (both legs come from MAME -wavwrite today).
    if ro != rn:
        sys.exit(f"sample-rate mismatch: ours {ro} Hz, native {rn} Hz — the "
                 f"window for one leg would be wrong")
    led = json.load(open(sys.argv[3]))
    sus, rows = [], 0
    for i, v in enumerate(led["voices"]):
        a, b = window(i, ro)
        mo, mn = metrics(so, a, b), metrics(sn, a, b)
        if mo[0] < 50 and mn[0] < 50:
            continue
        rows += 1
        q_o = mo[1] / mo[0] if mo[0] else 0
        q_n = mn[1] / mn[0] if mn[0] else 0
        if q_n > 0 and (q_o < 0.6 * q_n or q_o > 1.5 * q_n
                        or mo[0] < 0.5 * mn[0] or mo[0] > 2 * mn[0]):
            # BOTH directions: collapsed high band = the truncation
            # class; ELEVATED high band = the byte-lane ("PC-speaker")
            # class the first version missed — the maintainer's ear
            # caught what a low-only threshold passed (14z-86)
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
