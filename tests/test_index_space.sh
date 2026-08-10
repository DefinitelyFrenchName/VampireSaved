#!/bin/sh
# test_index_space.sh — THE OUT-OF-RANGE INDEX SWEEP (14z-76). Static, seconds.
#
# The class, named in 14z-75 after Pyron's Cosmo Disruption crash: vsavj's
# dispatch tables are SHORTER than vs2's, so a ported character carrying vs2's
# indices verbatim can dispatch past the end of vsavj's table. Pyron's
# sub-state 81 hit an 80-entry table and jumped into the table's own bytes.
# `test_variant_dispatch.sh` sweeps for the aliased-variant-row shape; this is
# the sweep for the other one, which docs/NEXT_SESSION.md asked for.
#
#   1. THE INVENTORY, with the sweep's own POSITIVE CONTROL — the known Cosmo
#      table must be re-derived at 80 entries against vs2's 84.
#   2. FROZEN COUNTS — tables found / twinned / NOT JUDGED / risky. The
#      unjudged count is part of the verdict on purpose: a matcher that
#      quietly stopped judging tables would otherwise read as "no risk".
#   3. NEGATIVE CONTROLS on the length derivation, which is the whole
#      instrument and which was WRONG in this sweep's first version.
#
# Usage: ROMDIR=... tests/test_index_space.sh
set -eu
ROMDIR="${ROMDIR:?set ROMDIR}"
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
fail=0

# frozen 14z-76 against vsavj 970519 + vsav2
EXP_TABLES=110
EXP_TWINNED=81
EXP_UNJUDGED=29
EXP_RISKY=3

python3 tools/cps2_decrypt.py "$ROMDIR/vsavj.zip" "$WORK/vj.bin" > /dev/null
python3 tools/cps2_decrypt.py "$ROMDIR/vsav2.zip" "$WORK/v2.bin" > /dev/null

echo "== 1. the sweep + its positive control (the known Cosmo table)"
if python3 tools/audit_index_space.py "$WORK/vj.bin" "$WORK/v2.bin" \
        --expect-known --json "$WORK/idx.json" > "$WORK/a.txt" 2>&1; then
    grep -E "^  0x|^ok:|TABLES WHERE" "$WORK/a.txt" | sed 's/^/  /'
else
    echo "  FAIL: the sweep does not re-derive the known Cosmo table:"
    sed 's/^/    /' "$WORK/a.txt"; fail=1
fi

echo "== 2. frozen counts"
chk() {
    got=$(grep -E "$2" "$WORK/a.txt" | head -1 | tr -dc '0-9 ' | awk '{print $NF}')
    [ -n "$got" ] || got=$(grep -E "$2" "$WORK/a.txt" | head -1 | grep -o '[0-9]\+' | head -1)
    if [ "$got" = "$3" ]; then echo "  ok: $1 = $3"
    else echo "  FAIL: $1 = ${got:-?}, frozen at $3 — the sweep's coverage moved"; fail=1; fi
}
python3 - "$WORK/a.txt" "$EXP_TABLES" "$EXP_TWINNED" "$EXP_UNJUDGED" "$EXP_RISKY" <<'PY'
import re, sys
txt = open(sys.argv[1]).read()
want = dict(zip(("tables", "twinned", "unjudged", "risky"), map(int, sys.argv[2:6])))
got = {
    "tables":   int(re.search(r"tables in vsavj\s*:\s*(\d+)", txt).group(1)),
    "twinned":  int(re.search(r"twinned in vs2\s*:\s*(\d+)", txt).group(1)),
    "unjudged": int(re.search(r"NOT JUDGED\)\s*:\s*(\d+)", txt).group(1)),
    "risky":    int(re.search(r"overrun \(gap >= \d+\):\s*(\d+)", txt).group(1)),
}
bad = 0
for k in want:
    if got[k] == want[k]:
        print(f"  ok: {k} = {got[k]}")
    else:
        print(f"  FAIL: {k} = {got[k]}, frozen at {want[k]}")
        bad = 1
sys.exit(bad)
PY
[ $? = 0 ] || fail=1

echo "== 3. negative controls on the length derivation"
python3 - "$WORK/vj.bin" <<'PY'
import sys
sys.path.insert(0, "tools")
from audit_index_space import table_len, dispatcher_anchors
img = open(sys.argv[1], "rb").read()
an = dispatcher_anchors(img)
bad = 0

# (a) the known table is exactly 80 — not 265 (bound (a) alone) and not 82
#     (the anchor placed 4 bytes late, which reads the NEXT dispatcher's
#     operand as an entry: both were real bugs in this sweep's first version)
n = table_len(img, 0x018468, an)
print(f"  {'ok' if n == 80 else 'FAIL'}: Cosmo table length = {n} (expect 80)")
bad |= n != 80

# (b) a table whose base sits after every anchor is UNBOUNDED and must be
#     refused (0), never guessed at
n = table_len(img, len(img) - 8, [])
print(f"  {'ok' if n == 0 else 'FAIL'}: no anchor after base -> NOT JUDGED ({n})")
bad |= n != 0

# (c) truncating the table by moving its terminating anchor closer must
#     shorten the derived count — i.e. the anchor bound is load-bearing
n = table_len(img, 0x018468, [a for a in an if a != 0x018508] + [0x0184A8])
print(f"  {'ok' if n == 32 else 'FAIL'}: anchor bound is load-bearing ({n}, expect 32)")
bad |= n != 32
sys.exit(bad)
PY
[ $? = 0 ] || fail=1

[ "$fail" = 0 ] && echo "PASS: test_index_space.sh" || echo "FAIL: test_index_space.sh"
exit "$fail"
