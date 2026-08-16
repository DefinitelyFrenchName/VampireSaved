#!/bin/sh
# test_classify_pool_spawns.sh — ground truth for the projectile-pool spawn
# classifier (14z-93). No ROMs, no emulator, ~1s.
#
# WHY THIS EXISTS. `tools/classify_pool_spawns.py` supplies the denominator
# that makes a zero from the hit-class map census interpretable: "the tenant
# never stamps a dangerous type" and "it stamps them constantly and nothing
# ever collided" are the same zero on the map probe and opposite rulings on
# whether `hitclass_map_extend` is still load-bearing. CLAUDE.md §4 requires
# the classification code be validated before its verdicts are trusted.
#
# THE CASE THAT MATTERS MOST is the LANE. The tap logs word writes; the type
# byte is at +0x02, an EVEN address, hence the HIGH lane on this big-endian
# CPU. The real captures happen to carry the SAME value in both lanes
# (`data 00004040`), so a low-lane reading returns the right answer for the
# wrong reason — which is what the first version of the tool did. Every lane
# case below therefore uses UNEQUAL lanes, where only one reading can pass.
set -eu
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
CLS="python3 tools/classify_pool_spawns.py"
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT
fail=0

mk() { printf '%s\n' "$2" > "$W/$1"; }
ck() {   # ck <name> <want-rc> <want-substring> <what it proves>
    rc=0; out="$($CLS "$W/$1" 2>&1)" || rc=$?
    if [ "$rc" = "$2" ] && (printf '%s' "$out" | grep -q -- "$3"); then
        echo "  ok $1: $4"
    else
        echo "  FAIL $1: rc=$rc want $2; got [$out] want [$3] — $4"
        fail=1
    fi
}

echo "== 1: the measured shape =="

# Pyron's satellite, verbatim from the 14z-93 capture on build/pyron26.
mk real 'W frame 3381 PC 0bff32 addr ff9402 data 00004040 mask 0000ff00
W frame 4601 PC 0c0f2c addr ff9402 data 00004343 mask 0000ff00
W frame 4681 PC 0bff32 addr ff9502 data 00004040 mask 0000ff00
W frame 2885 PC 02fa3e addr ffb882 data 00003f00 mask 0000ffff
END 11100 hits 4'
ck real 0 'OK spawns=3 types=64,67 slots=ff9402,ff9502 other_pool=0' \
    'the real capture reproduces: 3 projectile-pool spawns, types 64/67'

echo "== 2: THE LANE — unequal lanes, so only one reading can pass =="

# High lane 0x44 = 68 (a Huitzil type), low lane 0x0b = 11 (in-domain).
# A low-lane reader sees 11, drops it, and reports spawns=0 — a confident
# "no exposure" on a slot that holds a dangerous object.
mk lane_hi 'W frame 100 PC 0bff32 addr ff9402 data 0000440b mask 0000ff00
END 200 hits 1'
ck lane_hi 0 'OK spawns=1 types=68' 'the HIGH lane is the type (0x44=68), not the low one'

# The mirror image: high lane 0x0b (in-domain), low lane 0x44. A low-lane
# reader would MANUFACTURE a dangerous spawn out of an ordinary one.
mk lane_lo 'W frame 100 PC 0bff32 addr ff9402 data 00000b44 mask 0000ff00
END 200 hits 1'
ck lane_lo 0 'OK spawns=0 types=- ' 'a dangerous value in the LOW lane is not a type stamp'

# A write that does not cover the high lane cannot be a type stamp at all.
mk lane_mask 'W frame 100 PC 0bff32 addr ff9402 data 00004444 mask 000000ff
END 200 hits 1'
ck lane_mask 0 'OK spawns=0' 'a low-lane-only byte write is rejected (mask must cover +0x02)'

echo "== 3: pool selection and the bound =="

# The $FFB800 pool carries the same family values but is NOT the
# over-index vector. Counted separately, never dropped silently.
mk otherpool 'W frame 100 PC 02fa3e addr ffb882 data 00004400 mask 0000ffff
END 200 hits 1'
ck otherpool 0 'spawns=0 types=- slots=- other_pool=1' \
    'a dangerous type in a DIFFERENT pool is reported apart, not dropped'

# Only +0x02 of a 0x100-stride slot is the type lane. +0x82 is a mid-slot
# coincidence the tap admits and this tool must reject.
mk midslot 'W frame 100 PC 0bff32 addr ff9482 data 00004400 mask 0000ff00
END 200 hits 1'
ck midslot 0 'spawns=0 types=- slots=- other_pool=1' \
    'the +0x82 mid-slot coincidence is not a projectile-pool type stamp'

# 63 is vanilla's last type and fits the map — not an exposure.
mk inbound 'W frame 100 PC 0bff32 addr ff9402 data 00003f00 mask 0000ff00
END 200 hits 1'
ck inbound 0 'OK spawns=0' 'type 63 fits vanilla map and is not counted'

mk atbound 'W frame 100 PC 0bff32 addr ff9402 data 00004000 mask 0000ff00
END 200 hits 1'
ck atbound 0 'OK spawns=1 types=64' 'type 64 is the first over-indexing type'

echo "== 4: the states that are NOT a zero =="

mk dead 'W frame 100 PC 0bff32 addr ff9402 data 00004040 mask 0000ff00'
ck dead 1 'DEAD' 'no END line = DEAD, so the run is not a measurement'

ck absent 1 'DEAD spawns=0' 'an absent log is DEAD, not a silent zero'

mk empty 'END 11100 hits 0'
ck empty 0 'OK spawns=0 types=- ' 'a complete run with no stamps is a real zero'

echo "== 5: counting is per WRITE, not per slot =="

# Each restamp is an independent chance to collide, so the same slot
# stamped three times is three spawns — collapsing by slot would understate
# the exposure by the reuse factor.
mk restamp 'W frame 100 PC 0bff32 addr ff9402 data 00004000 mask 0000ff00
W frame 200 PC 0bff32 addr ff9402 data 00004000 mask 0000ff00
W frame 300 PC 0bff32 addr ff9402 data 00004000 mask 0000ff00
END 400 hits 3'
ck restamp 0 'OK spawns=3 types=64 slots=ff9402' \
    'a reused slot counts once per STAMP, not once per slot'

echo
if [ "$fail" = 0 ]; then
    echo "PASS: the spawn classifier's verdicts are ground-truthed."
else
    echo "FAIL: spawn verdicts are NOT trustworthy — do not read a census."
fi
exit "$fail"
