#!/bin/sh
# test_m2a_flicker_gate.sh — ground truth for the battery's masked flicker gate
# (14z-90, GitHub issue #2).
#
# WHY. tests/lib/m2a_common.sh branched on compare_flicker.py's EXIT CODE
# alone. That code cannot encode inventory equality — compare_flicker takes no
# inventory argument — so ANY verdict inside the class thresholds printed
# "ok:", including a wholly different set of divergent frames. Meanwhile
# run_battery_m2.sh:12 advertises the gate as carrying a "frozen flicker
# inventory — watch for growth: standing maintainer watch".
#
# WHY NOT STRING EQUALITY (this is the case the fix turns on). Frozen
# inventories legitimately MOVE between builds on the same track:
#     donovan-m2b 08_challenger_join -> flicker vsavj/masked 2 3507,3807
#     donovan-m2c 08_challenger_join -> flicker vsavj/masked 1 3507
# and this helper gates UNFROZEN dev builds. Pinning one build's numbers would
# turn a permissive gate into a false-RED one on the gate that guards the
# superset invariant — and a spurious red there reads as a rule-6 halt. So the
# predicate is the standing watch's literal text: fail on GROWTH, advise on
# shrink, and refuse to invent an inventory where none is frozen.
#
# Case 3 is that exact m2b->m2c shrink. If it ever fails, someone has replaced
# growth-detection with equality and the gate will start reddening healthy
# builds.
#
# Usage: tests/test_m2a_flicker_gate.sh   (no ROMs, no emulator, ~2s)
set -eu
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
fail=0

RPL=03_two_player_vs
BASIS="$REPO/tests/expected/vsavj/masked/logs/$RPL.log"
SPEC="$REPO/tests/expected/donovan-m2c/$RPL.masked"
[ -f "$BASIS" ] || { echo "FAIL: no frozen basis log at $BASIS"; exit 1; }
[ -f "$SPEC" ]  || { echo "FAIL: no frozen spec at $SPEC"; exit 1; }
FROZEN=$(awk '{ for (i=4;i<=NF;i++) printf "%s%s", $i, (i<NF?" ":"") }' "$SPEC")
echo "frozen inventory for $RPL: $FROZEN"

# mkflip <out> <frames...> — the basis with those frames' hashes flipped
mkflip() {
    _o="$1"; shift
    FR="$*" python3 - "$BASIS" "$_o" <<'PY'
import os, sys
bad = set(os.environ["FR"].split())
out = []
for line in open(sys.argv[1]):
    f = line.split()
    if len(f) >= 2 and f[0] in bad:
        out.append(f"{f[0]} ffffffffffffffff")
    else:
        out.append(line.rstrip("\n"))
open(sys.argv[2], "w").write("\n".join(out) + "\n")
PY
}

# run_gate <log> -> OUT (only the line for $RPL; the gate's other sections are
# not under test here and are not asserted on)
run_gate() {
    cp "$1" "$WORK/injected.log"
    OUT=$(
        REPO="$REPO"
        . "$REPO/tests/lib/m2a_common.sh"
        M2A_MASKED_EXACT=""
        M2A_MASKED_FLICKER="$RPL"
        # stub the emulator: hand the gate the log under test, and for the
        # gate's own first-divergence replays hand back the frozen basis.
        m2a_run_masked() {
            _dst="$3"
            if [ "$(basename "$_dst")" = "$RPL.log" ]; then
                cp "$WORK/injected.log" "$_dst"
            else
                _b="$REPO/tests/expected/vsavj/masked/logs/$(basename "$_dst")"
                if [ -f "$_b" ]; then cp "$_b" "$_dst"; else : > "$_dst"; fi
            fi
        }
        m2a_legacy_gate_masked "unused-rompath" "$WORK" 2>&1 || true
    )
    printf '%s\n' "$OUT" | grep -- "$RPL" || true
}

echo "== 1. inventory GROWS (the standing watch's case) =="
mkflip "$WORK/grown.log" 500 1500 2500 3500
got=$(run_gate "$WORK/grown.log")
# NB: match "GREW" alone — the full message wraps onto a second line, and the
# per-replay filter above keeps only the first. Asserting the whole phrase
# silently never matched.
if printf '%s' "$got" | grep -q "GREW"; then
    echo "  ok: growth is a loud FAIL"
else
    echo "FAIL: a drifted inventory did not trip the growth check"
    printf '%s\n' "$got" | head -3; fail=1
fi

echo "== 2. inventory unchanged =="
mkflip "$WORK/same.log" $(printf '%s' "$FROZEN" | tr ',' ' ')
got=$(run_gate "$WORK/same.log")
if printf '%s' "$got" | grep -q "within frozen" && \
   ! printf '%s' "$got" | grep -q "GREW"; then
    echo "  ok: the frozen inventory passes plainly"
else
    echo "FAIL: the frozen inventory did not pass cleanly"
    printf '%s\n' "$got" | head -3; fail=1
fi

echo "== 3. inventory SHRINKS (the m2b->m2c case) =="
first=$(printf '%s' "$FROZEN" | cut -d, -f1)
mkflip "$WORK/shrunk.log" "$first"
got=$(run_gate "$WORK/shrunk.log")
if printf '%s' "$got" | grep -q "GREW"; then
    echo "FAIL: a SHRINKING inventory was treated as growth — this is the"
    echo "      false-RED failure mode the fix exists to avoid"
    printf '%s\n' "$got" | head -3; fail=1
else
    echo "  ok: a shrink is not a failure"
fi

echo "== 4. bit-identical: the divergence is GONE, not grown =="
got=$(run_gate "$BASIS")
if printf '%s' "$got" | grep -q "GREW"; then
    echo "FAIL: a bit-identical pair was treated as growth"; fail=1
else
    echo "  ok: EXACT is not a failure (14z-89's decided fix may legitimately"
    echo "      drive the inventory to zero)"
fi

[ "$fail" = 0 ] && echo "PASS: masked flicker gate watches GROWTH (4 cases incl. the m2b->m2c shrink)" \
    || { echo "FAIL: masked flicker gate"; exit 1; }
