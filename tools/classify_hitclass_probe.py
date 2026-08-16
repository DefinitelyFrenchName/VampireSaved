#!/usr/bin/env python3
"""classify_hitclass_probe.py — read one guarded-run log from the hit-class
map probe and classify it (14z-93).

THE MEASUREMENT. `tests/audit_hitclass_map_cost.sh` arms a logging
breakpoint at the PLACED `hitclass_map_extend` thunk body, so every hit is
one lookup in the projectile hit-class byte map. `replay_guard.lua` writes

    PROBE <frame> D0=<8 hex> D1=... A0=... A6=... RET <8 hex>[ MEM...]

and **D0 is the RAW map index**, not index*4: the body is
`cmpi.w #80,d0 / bcc ILLEGAL / move.b (4,PC,D0.w),d0 / rts`, so D0.w
indexes the map directly. (Contrast the obj_hook sites, where D0 = type*4
and `dispatch_census.lua` divides by four. Getting this wrong would scale
every index by 4 and turn vanilla's 0x0b into a phantom over-index.)

THE SPLIT THAT MATTERS. vsavj's map has 64 entries; vs2's has 80. An index
>= 64 is what over-indexes vanilla and is the whole reason the thunk exists
(the f7997 vec3). So a log is summarised as:

    total  — every map lookup
    ext    — lookups in [BOUND, TRAP): the vs2 EXTENSION entries. These are
             the ones that make the thunk load-bearing — without it each is
             a wild jump; with it each gets vs2's own defined class.
    trap   — lookups at >= TRAP (80): past vs2's map too, so the thunk's
             planted ILLEGAL fires. Loud by design, and a different finding
             from `ext` — it means a type nobody has a class for.

Keeping `ext` and `trap` apart matters because they license opposite
conclusions: `ext > 0` says "keep the thunk", `trap > 0` says "something is
stamping a type outside BOTH engines' domains — go find it".

INDEX WIDTH: the guard prints the whole 32-bit register, but the body
compares `cmpi.w` and indexes with `D0.w`, so the low WORD is the index and
the high word is stale. Masking is therefore part of the measurement, not a
tidy-up: an unmasked reading manufactures over-indexes out of leftover bits.

WHY THIS IS A TOOL AND NOT A `grep` IN THE AUDIT. Four states have to stay
distinguishable and only one of them is "zero":

    DEAD    the run never completed (no `END` line). Its zero is not
            evidence — the trap this project has paid for repeatedly.
    CRASH   the guard tripped. On the FIX build that is a finding, not a
            dead rig, so it must not be folded into DEAD: an f7997-class
            wild jump IS what an unhandled over-index looks like.
    CAPPED  `GUARD_PROBE_MAX` was reached, the guard cleared the
            breakpoint and wrote `PROBE-CAP`. `total` is a FLOOR, not a
            count, and the `^END` check cannot see this.
    OK      the run completed and the breakpoint stayed armed throughout.

Collapsing CAPPED into OK would silently under-report exactly the busy
tenant rigs most likely to reach the extension.

Usage:
    classify_hitclass_probe.py <log> [--bound 64] [--trap 80]
Prints one line:
    <STATUS> total=<n> ext=<n> trap=<n> vals=<comma-separated hex>
Exit: 0 = OK, 1 = DEAD, 2 = CAPPED, 3 = CRASH.
"""

import re
import sys

PROBE = re.compile(r"^PROBE\s+\d+\s+D0=([0-9a-fA-F]+)\b")


def classify(text, bound=64, trap=80):
    """-> (status, total, ext, trap, sorted list of distinct indices)"""
    total = 0
    ext = 0
    n_trap = 0
    seen = set()
    complete = False
    capped = False
    crashed = False
    for line in text.splitlines():
        if line.startswith("END "):
            complete = True
            continue
        if line.startswith("PROBE-CAP"):
            capped = True
            continue
        if line.startswith(("CRASH ", "END-CRASH ", "PCWEEDS ", "SOFTRESET ")):
            crashed = True
            continue
        m = PROBE.match(line)
        if not m:
            continue
        # D0 is printed as a full 32-bit register; the map read is D0.w and
        # the guard compares the word, so mask before judging. A stale high
        # word would otherwise read as a wild over-index.
        d0 = int(m.group(1), 16) & 0xFFFF
        total += 1
        seen.add(d0)
        if d0 >= trap:
            n_trap += 1
        elif d0 >= bound:
            ext += 1
    # CRASH outranks DEAD: a crashed run did not reach `END`, but "the rig
    # died" and "the machine took a wild jump" are opposite findings.
    if crashed:
        status = "CRASH"
    elif not complete:
        status = "DEAD"
    elif capped:
        status = "CAPPED"
    else:
        status = "OK"
    return status, total, ext, n_trap, sorted(seen)


def main(argv):
    bound = 64
    trap = 80
    args = []
    i = 1
    while i < len(argv):
        if argv[i] == "--bound":
            bound = int(argv[i + 1], 0)
            i += 2
        elif argv[i] == "--trap":
            trap = int(argv[i + 1], 0)
            i += 2
        else:
            args.append(argv[i])
            i += 1
    if len(args) != 1:
        sys.exit(__doc__)
    try:
        with open(args[0]) as fh:
            text = fh.read()
    except OSError:
        text = ""          # a leg that never opened its log is DEAD, not an
                           # error — the caller counts it, same as an empty one
    status, total, ext, n_trap, seen = classify(text, bound, trap)
    print("%s total=%d ext=%d trap=%d vals=%s"
          % (status, total, ext, n_trap,
             ",".join("%x" % v for v in seen) or "-"))
    return {"OK": 0, "DEAD": 1, "CAPPED": 2, "CRASH": 3}[status]


if __name__ == "__main__":
    sys.exit(main(sys.argv))
