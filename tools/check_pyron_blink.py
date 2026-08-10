#!/usr/bin/env python3
"""check_pyron_blink.py — verdict logic for the Pyron sprite/HUD BLINK
(14z-75), kept out of the shell so it can be controlled directly.

THE DEFECT. Palette RAM row 10 (0x90C140) is Pyron's sprite palette AND
his in-match HUD mugshot palette. On our build it ALTERNATES every frame
between his correct colours and a second value; native vsav2 holds it
constant. Both the sprite and the mugshot blink, and the mugshot showed
Demitri's art in Pyron's colours before the HUD art landed (14z-75).

WHY THIS IS MEASURED PER LEG AND NOT FRAME-BY-FRAME. The two games are
not at the same point on the same frame, so a frame-indexed native/ours
diff is meaningless — that is exactly what confounded 14z-74's "ours 543
calls / native 0" figure, whose hits were in the SELECT screen where the
flows genuinely diverge. The property measured here is phase-independent:
the NUMBER OF DISTINCT row-10 values over a window of CONSECUTIVE
in-match frames. Native = 1 (constant). Ours = 2 (the blink).

ATTRIBUTION, not just symptom. Section 3 requires ours' two values to be
NAMED: one must be bit-identical to native's constant, and the other must
be vsavj palette-seq table row 0x26 (0x39ADC0) under the uploader's
0xF000 OR — the transform that turns a stored 0x0RGB into a palette-RAM
0xFRGB. A blink that failed this would be a DIFFERENT defect wearing the
same symptom.

Usage: check_pyron_blink.py <nativedir> <oursdir> <vsavj_data.bin>
                            <lo> <hi> [--expect blinks|fixed]
  <dir>/dump_<f>_90c140.bin  palette row 10 per frame (DUMPS grammar)
  <dir>/dump_<f>_ff8400.bin  P1 fighter block (+0x382 = character id)
"""

import sys
from pathlib import Path

SEQ_ROW_26 = 0x39ADC0        # vsavj palette-seq table 0x39A900 + 0x26*0x20
PYRON_ID = 0x11
ID_OFF = 0x382               # fighter block +0x382 (docs/game/atlas/ram.md)


def die(msg):
    print(f"FAIL: {msg}")
    sys.exit(1)


def seq_to_palette(row):
    """The uploader's stored->palette-RAM transform: 0x0RGB -> 0xFRGB."""
    out = bytearray(row)
    for i in range(0, len(out), 2):
        out[i] |= 0xF0
    return bytes(out)


def leg(d, lo, hi):
    d = Path(d)
    vals = []
    for f in range(lo, hi):
        p = d / f"dump_{f}_90c140.bin"
        if not p.exists():
            die(f"{d.name}: missing palette dump for frame {f}")
        vals.append(p.read_bytes())
    ids = sorted({b.read_bytes()[ID_OFF]
                  for b in d.glob("dump_*_ff8400.bin")})
    return vals, ids


def distinct(vals):
    out = []
    for v in vals:
        if v not in out:
            out.append(v)
    return out


def main():
    a = [x for x in sys.argv[1:] if not x.startswith("--")]
    expect = "blinks"
    if "--expect" in sys.argv:
        expect = sys.argv[sys.argv.index("--expect") + 1]
    nat_d, our_d, vj_path, lo, hi = a[0], a[1], a[2], int(a[3]), int(a[4])
    vj = Path(vj_path).read_bytes()

    nat, nat_ids = leg(nat_d, lo, hi)
    our, our_ids = leg(our_d, lo, hi)
    n_win = hi - lo

    # 1. REFUSE TO JUDGE unless Pyron is actually in on BOTH legs. A
    #    character that was never picked is the standing trap here: an
    #    unpicked leg shows a perfectly constant palette and would read
    #    as "native is fine".
    for tag, ids in (("native", nat_ids), ("ours", our_ids)):
        if ids != [PYRON_ID]:
            die(f"{tag}: P1 +0x382 = {[hex(i) for i in ids]}, expected "
                f"[{PYRON_ID:#04x}] — Pyron was not in this match, so the "
                f"palette says nothing")
    print(f"  ok: both legs have Pyron in (+0x{ID_OFF:X} = {PYRON_ID:#04x})")

    # 2. the phase-independent property
    nd, od = distinct(nat), distinct(our)
    nch = sum(1 for i in range(1, n_win) if nat[i] != nat[i - 1])
    och = sum(1 for i in range(1, n_win) if our[i] != our[i - 1])
    print(f"  native: {len(nd)} distinct row-10 value(s), {nch} changes "
          f"over {n_win} consecutive frames")
    print(f"  ours  : {len(od)} distinct row-10 value(s), {och} changes "
          f"over {n_win} consecutive frames")
    if len(nd) != 1 or nch != 0:
        die("native does NOT hold row 10 constant — the reference leg is "
            "not the reference this gate assumes; re-derive before "
            "trusting any verdict here")

    if expect == "fixed":
        if len(od) != 1:
            die(f"expected the blink FIXED: ours still shows {len(od)} "
                f"values / {och} changes")
        if od[0] != nd[0]:
            die("ours is constant but does NOT match native's colours")
        print("  ok: ours holds row 10 constant AND matches native")
        print("OK")
        return
    if expect != "blinks":
        die(f"unknown --expect {expect!r} (blinks|fixed)")

    # the frozen OPEN shape
    if len(od) != 2:
        die(f"expected the frozen 2-value blink, got {len(od)} distinct "
            f"value(s) — the defect changed shape; re-measure, do not "
            f"relax this gate")
    if och != n_win - 1:
        die(f"expected a change on EVERY frame ({n_win - 1}), got {och}")
    print(f"  ok: ours alternates every frame between exactly 2 values")

    # 3. ATTRIBUTION — both values named, or this is a different defect
    if nd[0] not in od:
        die("neither of ours' two values is native's — ours is not "
            "'correct palette alternating with an intruder'")
    intruder = [v for v in od if v != nd[0]]
    if len(intruder) != 1:
        die("could not isolate a single intruder value")
    want = seq_to_palette(vj[SEQ_ROW_26:SEQ_ROW_26 + 0x20])
    if intruder[0] != want:
        die(f"the intruder is NOT vsavj palette-seq row 0x26 under the "
            f"0xF000 OR.\n  intruder: {intruder[0].hex()}\n  seq 0x26 : "
            f"{want.hex()}\nThe symptom matches but the MECHANISM does "
            f"not — re-attribute before reusing this gate's name")
    print(f"  ok: value A == native's constant; value B == vsavj "
          f"palette-seq row 0x26 @{SEQ_ROW_26:#x} (0xF000 OR)")
    print("OK")


if __name__ == "__main__":
    main()
