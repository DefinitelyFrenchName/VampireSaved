#!/bin/sh
# test_pointer_flow.sh — the composed-output pointer/flow comb as a gate
# (14z-100, the hardening program's H1; maintainer-directed 2026-08-20).
#
# tools/audit_pointer_flow.py classifies EVERY address the patch introduces
# (op extents, poke32 repoint values, code abs.l operands, data bare longs)
# against the op map + the SHIPPED image bytes (the vsw.* members carry
# gfx-channel PRG content patch.json never writes — measured; that is why
# "hole" is decided on the artifact, not the op list). Frozen per build in
# tests/expected/pointer_flow/<set>.txt: STRONG findings verbatim (each
# REVIEWED — the two shipping ones are the win_pal sparse-block BIASED
# BASES, verified benign via the 5*row palette markers), WEAK volume by
# count. Growth EITHER way fails: a new STRONG finding is an unreviewed
# pointer into fill space; a moved count means the build is not the frozen
# one.
#
# ROM-free in the rule-7 sense (reads build outputs only); needs the
# build dirs on disk, SKIPs per absent build.
set -eu
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
fail=0

echo "== section 0: verdict controls (the classifier must be able to fire)"
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT
mkdir -p "$W/bad/patch" "$W/clean/patch"
python3 - "$W" <<'PY'
import json, sys, os
w = sys.argv[1]
json.dump({"ops": [
    {"op": "code", "addr": "0x4d0000", "hex": "207c004e00004e75"},
    {"op": "data", "addr": "0x5ffffe", "hex": "00112233"},
]}, open(os.path.join(w, "bad/patch/patch.json"), "w"))
json.dump({"ops": [
    {"op": "code", "addr": "0xc0000", "hex": "4e714e75"},
]}, open(os.path.join(w, "clean/patch/patch.json"), "w"))
PY
BAD="$(python3 tools/audit_pointer_flow.py "$W/bad")"
echo "$BAD" | grep -q "STRONG	code:movea_imm.*WIDE-HOLE" \
    && echo "$BAD" | grep -q "STRONG	op-extent.*OFF-IMAGE" \
    && echo "   ok: both synthetic defects flagged STRONG" \
    || { echo "FAIL: synthetic defects not flagged"; fail=1; }
CLEAN="$(python3 tools/audit_pointer_flow.py "$W/clean")"
echo "$CLEAN" | grep -q "FLAGGED: 0" \
    && echo "   ok: clean synthetic flags nothing" \
    || { echo "FAIL: clean synthetic produced flags"; fail=1; }

echo "== section 1: frozen baselines on the current freeze artifacts"
for pair in "build/m3b_merged17:merged-m10" "build/don_m14:donovan-m14" \
            "build/hui48:huitzil-m21" "build/pyron32:pyron-m15"; do   # re-pointed 14z-113 (merged-m10: one-zip repackaging of merged-m9, same program)
    b="${pair%%:*}"; n="${pair##*:}"
    if [ ! -f "$b/patch/patch.json" ]; then
        echo "   SKIP: $b absent"
        continue
    fi
    if python3 tools/audit_pointer_flow.py "$b" \
         --baseline "tests/expected/pointer_flow/$n.txt" > "$W/$n.out" 2>&1; then
        echo "   ok: $n matches its frozen pointer-flow baseline"
    else
        echo "FAIL: $n pointer-flow drift:"
        grep -E "^FAIL|^  [+-]" "$W/$n.out" | head -12
        fail=1
    fi
done

[ "$fail" = 0 ] && echo "PASS: pointer-flow comb green" || { echo "FAIL"; exit 1; }
