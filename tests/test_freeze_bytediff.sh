#!/bin/sh
# test_freeze_bytediff.sh — the newest freeze's whole program change is RECORDED byte range by byte range, and
# the record equals a fresh measurement (`tools/freeze_bytediff.py`, 14z-193, GitHub #231 part 2).
#
# WHAT: the record tests/expected/freeze_bytediff/<newest merged set>.txt exists and equals
#   `tools/freeze_bytediff.py render`: the four tracks' newest registry rows against the row before, each set's
#   build dir from its tag, every differing range in the opcode and data views of each build's own decrypted
#   romset (ranges and whole-image sha1s, never bytes).
# HOW: one render (~66 s: eight romsets decrypted) compared with the committed record; the instrument is shown
#   live on the M21 -> M22 pyron pair (build/pyron44 -> build/pyron45), whose data view must list #194's byte at
#   0x0FDF69 inside a placed file — the class op sets cannot see; the control drops one RANGE line from a copy
#   of the record, which must differ from the same render.
# EXPECTS: the record equal, 0x0FDF69 listed, the control's copy unequal. A freeze that adds registry rows
#   without a reviewed record leaves this red: `python3 tools/freeze_bytediff.py render`, review every range
#   against the freeze's design, then `freeze`.
#
# MUST-FIRE: perturbed-copy: dropped-range — a copy of the record with one RANGE line removed must differ from the fresh render, and the gate must FAIL (mode: the gate compares that copy)
#
# Usage: tests/test_freeze_bytediff.sh      # ci_static (needs the build dirs and the freeze tags), ~85 s
set -eu
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
. "$REPO/tests/lib/controls.sh"; vs_ctl_mode "$0"
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT
fail=0

echo "== test_freeze_bytediff: #231 — the newest freeze's program change, recorded and re-measured =="
python3 tools/freeze_bytediff.py plan > "$W/plan.tsv" 2> "$W/plan.err" || { echo "FAIL: no plan: $(tail -1 "$W/plan.err")"; exit 1; }
while IFS="$(printf '\t')" read -r _t _o _n _od _nd; do
    for _d in "$_od" "$_nd"; do
        [ -f "$_d/rompath/vsavjw.zip" ] || [ -f "$_d/rompath/vsavj.zip" ] || { echo "SKIP: no romset under $_d/rompath (track $_t)"; exit 0; }
    done
    echo "  $_t: $_o -> $_n  ($_od -> $_nd)"
done < "$W/plan.tsv"
for _d in build/pyron44 build/pyron45; do
    [ -f "$_d/rompath/vsavjw.zip" ] || { echo "SKIP: no romset under $_d/rompath (the M21 -> M22 instrument pair)"; exit 0; }
done
MERGED="$(awk -F'\t' '$1 == "merged" {print $3}' "$W/plan.tsv")"
REC="tests/expected/freeze_bytediff/$MERGED.txt"

python3 tools/freeze_bytediff.py render > "$W/got.txt" 2> "$W/render.err" || { echo "FAIL: render: $(tail -1 "$W/render.err")"; exit 1; }
CMP="$REC"
if vs_ctl_is dropped-range; then
    awk '/^RANGE / && !d {d = 1; next} {print}' "$REC" > "$W/dropped.txt"; CMP="$W/dropped.txt"
fi

echo "-- 1. the record against a fresh measurement"
if [ ! -f "$CMP" ]; then
    echo "  FAIL: no record $REC for the newest freeze $MERGED — review \`python3 tools/freeze_bytediff.py render\`, then \`freeze\`"; fail=1
elif cmp -s "$CMP" "$W/got.txt"; then
    echo "  ok: $REC equals the render ($(grep -c '^RANGE ' "$W/got.txt" | tr -d ' ') ranges over $(grep -c '^TRACK ' "$W/got.txt" | tr -d ' ') tracks)"
else
    echo "  FAIL: the record differs from the render:"; diff "$CMP" "$W/got.txt" | head -12 | sed 's/^/      /'; fail=1
fi

echo "-- 2. the instrument sees a byte inside a placed file (M21 -> M22, #194 at 0x0FDF69)"
python3 tools/program_bytediff.py --record build/pyron44 build/pyron45 > "$W/m22.txt" 2>&1 || true
if grep -q '^RANGE data 0x0fdf69-0x0fdf69 len 1$' "$W/m22.txt"; then
    echo "  ok: data 0x0fdf69 listed ($(grep -c '^RANGE ' "$W/m22.txt" | tr -d ' ') ranges on the pair)"
else
    echo "  FAIL: 0x0FDF69 not listed on pyron44 -> pyron45:"; head -4 "$W/m22.txt" | sed 's/^/      /'; fail=1
fi

if [ -z "${VS_CTL:-}" ] && [ -f "$REC" ]; then
    echo "-- 3. control: a record with one RANGE line dropped must differ from the render"
    awk '/^RANGE / && !d {d = 1; next} {print}' "$REC" > "$W/dropped.txt"
    if cmp -s "$W/dropped.txt" "$W/got.txt"; then
        vs_ctl_dead dropped-range "the copy without a range still equals the render" || fail=1
    else
        vs_ctl_fired dropped-range "the copy without '$(grep -m1 '^RANGE ' "$REC")' differs from the render"
    fi
fi

if [ "$fail" -eq 0 ]; then echo "PASS: test_freeze_bytediff"; else echo "FAIL: test_freeze_bytediff"; exit 1; fi
