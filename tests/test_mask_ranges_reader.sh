#!/bin/sh
# test_mask_ranges_reader.sh — the MASK_RANGES reader must mask exactly what
# the spec says (14z-94, GitHub #61). ~1 min, needs ROMDIR + a WIDE build.
#
# WHY IT MATTERS. The mask string IS the definition of the ratified comparison
# basis (CLAUDE.md §4, docs/game/atlas/ram.md). Every `.masked` expectation
# cites one. freeze_masked_basis.sh grew three guards in 14z-89 because a
# mismatched mask makes every expectation citing it meaningless — while the
# READER itself validated nothing.
#
# THE DEFECT. Ranges are sorted by START, and the walk did `pos = r[2]`
# unconditionally. A NESTED or overlapping window therefore rewinds `pos`:
# with `1000-2000,1500-1800`, pos goes 0x2000 -> 0x1800 and the tail read
# re-includes 0x1800-0x2000 — bytes the spec asked to EXCLUDE. The log line
# still names the full mask, so the comparison runs against a basis nobody
# ratified and nothing looks wrong.
#
# INERT ON EVERY FROZEN SET: all seven live masks are disjoint and ascending,
# where max(pos, r[2]) == r[2]. Section 1 proves the equivalence directly
# rather than resting on that argument.
set -eu
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
ROMDIR="${ROMDIR:?set ROMDIR}"
MAME_BIN="${MAME_BIN:-$HOME/.cache/vampire-saved/mame/cps2}"
export MAME_BIN
BUILD="${MASK_BUILD:-build/hui47}"
[ -x "$MAME_BIN" ] || { echo "SKIP: no WIDE MAME binary"; exit 0; }
[ -f "$BUILD/rompath/vsavjw.zip" ] || { echo "SKIP: no $BUILD/rompath/vsavjw.zip"; exit 0; }

T="$(mktemp -d)"; trap 'rm -rf "$T"' EXIT INT TERM
RP="$PWD/$BUILD/rompath;$ROMDIR"
rc=0
fail() { echo "  FAIL: $*"; rc=1; }

# a short replay: the reader is per-frame, so a few hundred frames suffice
awk '{ l=$0; sub(/#.*/,"",l)
       if (match(l, /^[ \t]*[0-9]+/)) { n=int(substr(l,RSTART,RLENGTH)); if (n<=400) print }
       else print }' tests/replays/11_pick_donovan.rpl > "$T/short.rpl"

run() { # run <tag> <mask>
    MASK_RANGES="$2" MAME_ROMPATH="$RP" \
      tools/run_replay_mame.sh vsavjw "$T/short.rpl" "$T/$1.log" \
      > "$T/$1.out" 2>&1 && return 0 || return $?
}

echo "== 1. a NESTED range must not unmask anything =="
# 1500-1800 lies wholly inside 1000-2000, so it can only be redundant.
run plain  "1000-2000" || fail "the plain mask run failed"
run nested "1000-2000,1500-1800" || fail "the nested mask run failed"
if [ -s "$T/plain.log" ] && cmp -s "$T/plain.log" "$T/nested.log"; then
    echo "  ok: nesting a window inside another changes nothing"
else
    fail "a nested window changed the checksum — bytes inside an excluded"
    fail "      window were re-included (the #61 defect):"
    diff "$T/plain.log" "$T/nested.log" 2>/dev/null | head -3 | sed 's/^/        /'
fi

echo "== 2. CONTROL — the comparison is sensitive to a real mask change =="
# Without this, section 1 would pass on a reader that ignored MASK_RANGES
# entirely, or on two empty logs.
run wider "1000-2000,3000-3100" || fail "the wider mask run failed"
if cmp -s "$T/plain.log" "$T/wider.log"; then
    fail "adding a DISJOINT masked window changed nothing — the reader is not"
    fail "      masking at all, so section 1 proves nothing"
else
    echo "  ok: a disjoint extra window does change the checksum"
fi

echo "== 3. an OVERLAPPING (not nested) range is also handled =="
# 1800-2500 overlaps 1000-2000 on the right. The union is 1000-2500, so this
# must equal a single 1000-2500 window.
run overlap "1000-2000,1800-2500" || fail "the overlap run failed"
run union   "1000-2500" || fail "the union run failed"
if cmp -s "$T/overlap.log" "$T/union.log"; then
    echo "  ok: overlapping windows mask their union"
else
    fail "overlapping windows do not equal their union"
fi

echo "== 4. VALIDATION CONTROLS — a malformed mask must be REFUSED =="
for spec in "2000-1000" "f000-20000" ; do
    if run bad "$spec"; then
        fail "MASK_RANGES='$spec' was ACCEPTED"
    else
        echo "  ok: '$spec' refused — $(grep -o 'MASK_RANGES:.*' "$T/bad.out" | head -1)"
    fi
done
# A non-empty spec that parses to nothing would silently produce a WHOLE-RAM
# checksum under a name promising a masked one.
if run typo "not-hex-at-all!"; then
    fail "a spec that parses to no ranges was accepted as 'no mask'"
else
    echo "  ok: an unparseable spec is refused, not treated as unmasked"
fi

echo "== 5. every frozen mask still parses and is disjoint-ascending =="
for m in tests/expected/*/mask; do
    [ -f "$m" ] || continue
    python3 - "$m" <<'PY' || rc=1
import sys
spec = open(sys.argv[1]).read().strip()
rs = []
for part in spec.split(","):
    lo, hi = part.split("-")
    rs.append((int(lo, 16), int(hi, 16)))
bad = [r for r in rs if r[0] > r[1] or r[1] > 0x10000]
if bad:
    print(f"  FAIL {sys.argv[1]}: malformed {bad}"); sys.exit(1)
srt = sorted(rs)
for a, b in zip(srt, srt[1:]):
    if b[0] < a[1]:
        print(f"  note {sys.argv[1]}: {a} and {b} overlap — now handled, but"
              f" the pre-fix reader would have unmasked bytes here")
PY
done
echo "  ok: all frozen masks are well-formed"

echo
if [ "$rc" = 0 ]; then
    echo "PASS: the mask reader masks exactly the spec, and refuses nonsense."
else
    echo "FAIL: see above."
fi
exit $rc
