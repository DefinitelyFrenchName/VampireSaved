#!/usr/bin/env python3
"""classify_pool_spawns.py — read one `type_write_census.lua` tap log and
count the DANGEROUS-TYPE spawns into the projectile pool (14z-93).

WHY THIS EXISTS. `tests/audit_hitclass_map_cost.sh` section 3 measures how
often a tenant ENTERS the projectile hit-class map. When that comes back
zero the number is ambiguous on its own: the hit sweep is POOL-vs-POOL, so
zero can mean "the tenant never stamps a dangerous type" or "it stamps them
constantly and nothing ever collided with one". Those license opposite
rulings on whether `hitclass_map_extend` is still load-bearing.

This tool supplies the other half: how many objects of type >= 64 were put
into the `$FF9400` projectile pool at all. Map entries near zero WITH
spawns well above zero means the exposure is live and the gap is CONTACT —
i.e. a missing RIG, not a missing defect.

That is exactly what it measured (14z-93): 0 entries against 121 spawns,
on which the maintainer ruled **KEEP the thunk** (2026-08-16). The question
is DECIDED; this tool is now the regression instrument behind that ruling,
so a later run reporting 0 spawns means the rigs stopped exercising the
tenant's projectile machine — not that the exposure went away.

THE SLOT ARITHMETIC. The projectile pool is `$FF9400`, 0x100 stride, type
byte at +0x02 (docs/game/atlas/ram.md; walker 0x54458). The tap logs word
writes as `W frame <n> PC <pc> addr <a> data <d> mask <m>` and its own
filter is `(addr & 0x7F) == 2`, which also admits the 0x80-stride
`$FFB800` pool and mid-slot +0x82 coincidences — so THIS tool re-selects
by pool rather than trusting the tap's coarser lane filter.

**THE TYPE IS THE HIGH LANE, AND THAT IS NOT A STYLE CHOICE.** The tap
logs WORD-aligned writes; the type byte sits at the slot's +0x02, an EVEN
address, which on a big-endian 68000 is the HIGH byte of that word. The
tap's own header says the same thing ("TT in the high lane"). Measured
confirmation on Pyron's satellite:

    addr ff9402  data 00004040  mask 0000ff00   -> type 0x40 = 64
    addr ff9402  data 00004343  mask 0000ff00   -> type 0x43 = 67
    addr ffb882  data 00003f00  mask 0000ffff   -> type 0x3f = 63

Note the trap in the first two: both lanes carry the same value, so a
LOW-lane reading returns the right answer by coincidence — and the third
line, where the lanes differ, is rejected either way because 63 < 64. A
first version of this tool read the low lane and produced exactly the
right output for exactly the wrong reason. The verdict controls in
`tests/test_classify_pool_spawns.sh` pin the lane with unequal lanes so
that cannot recur.

We also require the write to actually COVER the high lane (`mask & 0xFF00`);
a low-lane-only byte write at this address is not a type stamp.

Counting is per WRITE, not per object: a slot restamped on a later frame is
a new spawn, which is the quantity that matters (each is an independent
chance to collide).

Usage:
    classify_pool_spawns.py <tap log> [--pool ff9400] [--end ffb800]
                            [--bound 64]
Prints:  <STATUS> spawns=<n> types=<csv> slots=<csv> other_pool=<n>
Exit: 0 = OK, 1 = DEAD (no END line — the run died, not a zero).
"""

import re
import sys

W = re.compile(r"^W\s+frame\s+(\d+)\s+PC\s+([0-9a-fA-F]+)\s+"
               r"addr\s+([0-9a-fA-F]+)\s+data\s+([0-9a-fA-F]+)\s+"
               r"mask\s+([0-9a-fA-F]+)")


def classify(text, pool=0xFF9400, pool_end=0xFFB800, bound=64):
    """-> (status, spawns, sorted types, sorted slots, other_pool count)"""
    spawns = 0
    types = set()
    slots = set()
    other = 0
    complete = False
    for line in text.splitlines():
        if line.startswith("END "):
            complete = True
            continue
        m = W.match(line)
        if not m:
            continue
        addr = int(m.group(3), 16)
        data = int(m.group(4), 16)
        mask = int(m.group(5), 16)
        # +0x02 is EVEN, so on this big-endian CPU the type byte is the
        # HIGH lane of the logged word. Require the write to cover it.
        if not (mask & 0xFF00):
            continue
        val = (data >> 8) & 0xFF
        if val < bound:
            continue
        # The projectile pool: 0x100 stride, type at +0x02.
        if pool <= addr < pool_end and (addr & 0xFF) == 0x02:
            spawns += 1
            types.add(val)
            slots.add(addr)
        else:
            # Same dangerous value, a DIFFERENT pool. Reported separately
            # rather than dropped: it is not the over-index vector, but a
            # silent drop would hide a stamp landing somewhere unexpected.
            other += 1
    status = "OK" if complete else "DEAD"
    return status, spawns, sorted(types), sorted(slots), other


def main(argv):
    pool, pool_end, bound = 0xFF9400, 0xFFB800, 64
    args = []
    i = 1
    while i < len(argv):
        if argv[i] == "--pool":
            pool = int(argv[i + 1], 16); i += 2
        elif argv[i] == "--end":
            pool_end = int(argv[i + 1], 16); i += 2
        elif argv[i] == "--bound":
            bound = int(argv[i + 1], 0); i += 2
        else:
            args.append(argv[i]); i += 1
    if len(args) != 1:
        sys.exit(__doc__)
    try:
        with open(args[0]) as fh:
            text = fh.read()
    except OSError:
        text = ""
    status, spawns, types, slots, other = classify(text, pool, pool_end, bound)
    print("%s spawns=%d types=%s slots=%s other_pool=%d"
          % (status, spawns,
             ",".join(str(t) for t in types) or "-",
             ",".join("%06x" % s for s in slots) or "-",
             other))
    return 0 if status == "OK" else 1


if __name__ == "__main__":
    sys.exit(main(sys.argv))
