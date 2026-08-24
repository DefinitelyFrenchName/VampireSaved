#!/usr/bin/env python3
"""rpl2siminputs.py — translate a tests/replays/*.rpl input script into
jtframe's Verilator `sim_inputs.hex` (14z-106, the MiSTer simulation lane).

FORMAT (jtframe v1.7.3, modules/jtframe/hdl/ver/test.cpp `SimInputs`):
one hex word per line = one video frame, applied when the core ENTERS
vertical blanking (`sim_inputs.next()` on LVBL falling edge). Active-HIGH
bits in the file (test.cpp inverts): bit0 coin1, bit1 coin2, bit2 start1,
bit3 start2, bits4-7 P1 directions (see below), bits8-11 P1 buttons 1-4,
bit11 is ALSO dip_test in that harness (so button 4 = test switch — refused
here).

THE DIRECTION NIBBLE IS MSB-FIRST, AND GETTING THAT BACKWARDS COST THE
MiSTer ARC A SESSION (14z-108). `test.cpp:380` copies the file's bits 4-7
STRAIGHT ONTO `joystick1[3:0]` — file bit4 -> joy[0], bit5 -> [1], bit6 ->
[2], bit7 -> [3] — and jtframe's joystick port is MSB-FIRST: `joy[3]=Up
[2]=Down [1]=Left [0]=Right` (`modules/jtframe/hdl/keyboard/
jtframe_keyboard.v:107-110`, the authoritative bit order; the
`JTFRAME_JOY_*` macro NAMES list directions MSB-first too, which is why
`_JTFRAME_JOY_RLDU` at test.cpp:384 is a full nibble reversal). So:

    file bit4 = RIGHT   bit5 = LEFT   bit6 = DOWN   bit7 = UP

THIS FILE HAD IT REVERSED FROM BIRTH — it read the macro NAME "UDLR" as
"bit4=Up ... bit7=Right" and every direction a replay ever asked the
simulator for arrived as its OPPOSITE. Measured 14z-108 on the game's own
P1 input mirror `RAM:$FF8058.w`, four presses on stock `vsavj`,
`tests/replays/107_four_directions.rpl`, MAME vs `cps2w` under Verilator:

    asked   MAME    core (pre-fix)   the core actually delivered
    Up      0x0008  0x0001           Right
    Down    0x0004  0x0002           Left
    Left    0x0002  0x0004           Down
    Right   0x0001  0x0008           Up

14z-107 (12) had seen only the Left/Down half and INFERRED a two-bit swap
that left Up and Right untouched. That inference was WRONG and a two-bit
fix would have left half the defect in place. Derive an input map from the
bit ORDER and confirm it against the game's own mirror; never from a macro
name (docs/platform/gotchas.md, THE INSTRUMENT PROTOCOL).

P2 and buttons 5/6 are NOT EXPRESSIBLE in that harness: a replay that uses
them is refused LOUDLY rather than silently truncated (the 14z-102 gotcha:
identify moves by measured effects, never by what the script was meant
to say). Extending the harness is fork work and a separate change —
maintainer-ruled "later" (STATE, Decisions pending).

NOT EXPRESSIBLE IS NOT THE SAME AS NOT PRESSED, and at v1.7.3 they were
PRESSED: `test.cpp` masked the joystick word with `&0xf0` and seeded
`joystick1..4 = 0xff` on a `[9:0]` ACTIVE-LOW port, so P1's buttons 5 and 6
and P2's were held DOWN for every frame of every run. Fork commit 10
(14z-107 (8)) releases them; measured before/after in
docs/platform/mister.md, "`SimInputs` HELD BUTTONS 5 AND 6 DOWN". This
translator is unchanged by that fix — releasing a button is not scripting
it, and the refusals below still fire.

.rpl grammar (tests/lua/replay.lua): `<frame>[-<end>] who=tokens ...`,
who in p1/p2/sys; p1 tokens U D L R 1-6; sys S1 S2 C1 C2 SV TS; lines OR
together; frame 1 = first emulated frame. `<frame> wait` extends.

Usage: rpl2siminputs.py <in.rpl> <out.hex> [--frames N] [--offset K]
  --frames N  emit exactly N lines (pad with 0 / truncate); default = the
              replay's last frame.
  --offset K  shift every .rpl frame by K lines (K may be negative) to
              align the MAME frame index with the simulator's — MEASURE it
              (docs/platform/mister.md); default 0.
Prints the sha1 of what it read and wrote.
"""
import argparse, hashlib, re, sys

# MSB-FIRST: file bit7=Up bit6=Down bit5=Left bit4=Right. Measured, not
# assumed — see "THE DIRECTION NIBBLE IS MSB-FIRST" above.
DIRS = {"U": 1 << 7, "D": 1 << 6, "L": 1 << 5, "R": 1 << 4}
BTNS = {"1": 1 << 8, "2": 1 << 9, "3": 1 << 10}
SYS = {"C1": 1 << 0, "C2": 1 << 1, "S1": 1 << 2, "S2": 1 << 3}
TOK = re.compile(r"^(\d+)(?:-(\d+))?\s+(.*)$")


def parse(text):
    """-> (dict frame->bits, last_frame). Raises on anything the harness
    cannot express."""
    frames, last = {}, 0
    for ln, raw in enumerate(text.splitlines(), 1):
        line = raw.split("#", 1)[0].strip()
        if not line:
            continue
        m = TOK.match(line)
        if not m:
            raise SystemExit(f"line {ln}: cannot parse: {raw!r}")
        a, b, rest = int(m.group(1)), m.group(2), m.group(3).strip()
        b = int(b) if b else a
        last = max(last, b)
        if rest == "wait":
            continue
        bits = 0
        for item in rest.split():
            who, _, toks = item.partition("=")
            if who == "p1":
                for t in toks:
                    if t in DIRS: bits |= DIRS[t]
                    elif t in BTNS: bits |= BTNS[t]
                    elif t in "456":
                        raise SystemExit(f"line {ln}: p1 button {t} is not expressible "
                                         "in jtframe v1.7.3 sim_inputs.hex (buttons 1-3 only; "
                                         "4 doubles as dip_test) — refusing")
                    else:
                        raise SystemExit(f"line {ln}: unknown p1 token {t!r}")
            elif who == "p2":
                raise SystemExit(f"line {ln}: p2 input is not expressible in jtframe v1.7.3 "
                                 "sim_inputs.hex (P1 only) — refusing")
            elif who == "sys":
                for t in re.findall(r"S1|S2|C1|C2|SV|TS", toks):
                    if t in SYS: bits |= SYS[t]
                    else:
                        raise SystemExit(f"line {ln}: sys token {t} (service/test) not expressible — refusing")
                if re.sub(r"S1|S2|C1|C2|SV|TS", "", toks):
                    raise SystemExit(f"line {ln}: unknown sys tokens in {toks!r}")
            else:
                raise SystemExit(f"line {ln}: unknown who {who!r}")
        for f in range(a, b + 1):
            frames[f] = frames.get(f, 0) | bits
    return frames, last


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("rpl"); ap.add_argument("out")
    ap.add_argument("--frames", type=int); ap.add_argument("--offset", type=int, default=0)
    a = ap.parse_args()
    data = open(a.rpl, "rb").read()
    print(f"read {a.rpl} sha1 {hashlib.sha1(data).hexdigest()}")
    frames, last = parse(data.decode())
    n = a.frames if a.frames is not None else last
    lines = []
    for i in range(1, n + 1):           # line i = sim frame i (1-based like .rpl)
        lines.append(f"{frames.get(i - a.offset, 0):03x}")
    out = ("\n".join(lines) + "\n").encode()
    open(a.out, "wb").write(out)
    held = sum(1 for v in frames.values() if v)
    print(f"wrote {a.out} sha1 {hashlib.sha1(out).hexdigest()} frames={n} "
          f"active={held} offset={a.offset}")


if __name__ == "__main__":
    main()
