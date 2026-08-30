#!/usr/bin/env python3
"""check_pyron_blink.py — verdict logic for the Pyron sprite/HUD BLINK
(14z-75), kept out of the shell so it can be controlled directly.

THE DEFECT (FIXED in build/pyron16; this checker now guards the fix).
Palette RAM row 10 (0x90C140) is Pyron's sprite palette AND his in-match
HUD mugshot palette, so both blinked. It ALTERNATED every frame between
his correct colours and vsavj palette-seq row 0x26; native vsav2 holds it
constant. Root cause was a DEAD ROW: the per-character palette-routine
table at 0x2A8A4 aliases rows 0x10-0x1F onto 0x00-0x0F, so id 0x11 ran
row 0x01's animated-palette handler where vs2's row 0x11 is the default
no-op. Fixed by one word at 0x2A8C6 (008E -> 0040).

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
                            [--expect-base native=0xHEX,ours=0xHEX]
  --expect-base (14z-123): each leg's ONE base must EQUAL the given value —
  the tenant's own row of that game's hitbox_base table (vs2 data view
  0xD7B18 row 0x11; the build's prg/vm3j.04d @ 0x3D97A row 0x11). Without
  it the guard only rules out "no fighter" and "fighter changed"; WITH it a
  wrong character that WAS loaded is refused too (the wrongchar control).
  <dir>/dump_<f>_90c140.bin  palette row 10 per frame (DUMPS grammar)
  <dir>/dump_<f>_ff8400.bin  P1 fighter block (+0x60.l = hitbox base)
"""

import sys
from pathlib import Path

SEQ_ROW_26 = 0x39ADC0        # vsavj palette-seq table 0x39A900 + 0x26*0x20
# 14z-92 (GitHub #16). This used to read +0x382 as "the character id" at
# frames 3200/3400/3600 — all IN MATCH. 14z-87 proved that byte is the
# fighter's VOICE-FLAVOR CLASS in match: the engine reassigns it at a
# match-sequencer event by BORROWING from the opponent's row of candidate
# table 0x00B268 (PRG:0x0AEF6). Our build is protected by the shipped
# voice_borrow_keep_tenant thunk; the NATIVE leg is not, so a borrow there
# produced a false REFUSE. Zero recorded firings, but a guard that can stop
# measuring for the wrong reason is a guard that will eventually lie.
# The id-stable signature is +0x60.l, the per-character HITBOX BASE — the
# same one audit_legacy_pairings.sh uses, and for the same reason.
HB_OFF = 0x60                # fighter block +0x60.l = per-character hitbox base


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
    # +0x60.l per sampled fighter-block frame. Compared as a SET: the
    # character must not change mid-window, and it must be a real base.
    bases = set()
    for b in sorted(d.glob("dump_*_ff8400.bin")):
        raw = b.read_bytes()
        bases.add(int.from_bytes(raw[HB_OFF:HB_OFF + 4], "big"))
    return vals, sorted(bases)


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
    want_base = {}
    if "--expect-base" in sys.argv:
        for kv in sys.argv[sys.argv.index("--expect-base") + 1].split(","):
            k, v = kv.split("=")
            want_base[k.strip()] = int(v, 16)
    nat_d, our_d, vj_path, lo, hi = a[0], a[1], a[2], int(a[3]), int(a[4])
    vj = Path(vj_path).read_bytes()

    nat, nat_ids = leg(nat_d, lo, hi)
    our, our_ids = leg(our_d, lo, hi)
    n_win = hi - lo

    # 1. REFUSE TO JUDGE unless Pyron is actually in on BOTH legs. A
    #    character that was never picked is the standing trap here: an
    #    unpicked leg shows a perfectly constant palette and would read
    #    as "native is fine".
    # The two legs run DIFFERENT games (native vsav2 vs our vsavjw), so
    # their hitbox bases are different addresses by construction — this
    # cannot compare them to each other or to one constant. What it CAN
    # require, and what actually rules out the trap, is that each leg holds
    # ONE non-zero base for the whole window: a character that was never
    # picked reads zero, and a character that changed mid-window reads two.
    for tag, bases in (("native", nat_ids), ("ours", our_ids)):
        if len(bases) != 1 or bases[0] == 0:
            die(f"{tag}: P1 +0x{HB_OFF:02X}.l = {[hex(b) for b in bases]} "
                f"over the sampled frames — expected exactly one non-zero "
                f"hitbox base. Zero means no character was loaded; two or "
                f"more means the fighter changed mid-window. Either way the "
                f"palette says nothing.")
    print(f"  ok: both legs hold ONE non-zero fighter for the whole window "
          f"(+0x{HB_OFF:02X}.l native {nat_ids[0]:#08x}, ours {our_ids[0]:#08x})")
    # 1b. (14z-123) and that fighter is PYRON: the base must equal the
    #     tenant's own row of each game's hitbox_base table. A loaded WRONG
    #     character has a real, constant base and passed 1. above.
    for tag, bases in (("native", nat_ids), ("ours", our_ids)):
        if tag in want_base and bases[0] != want_base[tag]:
            die(f"{tag}: P1 +0x{HB_OFF:02X}.l = {bases[0]:#08x} is not Pyron's "
                f"row of this game's hitbox_base table ({want_base[tag]:#08x}) "
                f"— a different character was loaded; the palette says nothing")
    if want_base:
        print(f"  ok: both bases are Pyron's own table rows "
              f"({', '.join(f'{k} {v:#08x}' for k, v in want_base.items())})")

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
