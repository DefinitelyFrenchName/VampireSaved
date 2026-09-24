#!/bin/sh
# test_df_field_readers.sh — EVERY PLACED INSTRUCTION THAT NAMES ONE OF vs2's DARK FORCE POWER FIELDS BY DISPLACEMENT, with the access it makes, frozen (14z-168, GitHub #136 / #157's Dark Force tail): our host engine runs Dark Force Change, which never sets +0x1C3/+0x1C4/+0x1C6/+0x1C7/+0x1C8, so every READ row is a tenant instruction that sees "not in Dark Force" inside our Dark Force.
#
# WHAT: every PLACED instruction of the build that names one of vs2's Dark Force POWER
#   fields (+0x1C3/+0x1C4/+0x1C6/+0x1C7/+0x1C8) by displacement, with its access class (read
#   / write / rmw / addr) and base register, frozen — the candidates of the class the ruled
#   'no gauge in DF' rule found, since our host engine never sets those fields.
# HOW: tools/audit_df_field_readers.py over the build's opcode image and placements (code
#   regions and code ops only), its --selftest of hand-assembled encodings and two decoys
#   first; the control re-addresses the first +0x1C3 row to +0x111 in a copy of the image.
# EXPECTS: the frozen row, count and access rows equal; the selftest's decoys absent; the
#   re-addressed copy loses a row and fails. What each reader does in our Dark Force is not
#   measured here; a missed reader is audit_df_field_readers_live's question.
#
# MUST-FIRE: shadow-tool: planted — a copy of the build's opcode image with the FIRST +0x1C3 row re-addressed to +0x111 (what a fix of that reader looks like) must lose one row and FAIL the frozen compare, so the census reads the image it is given (in-gate: the planted copy must census differently; mode: the gate censuses the planted copy and FAILs)
#
# WHY. tests/audit_df_meter.sh measures ONE of these readers changing play (the placed
# copy of vs2's meter adder pays the tenants' start-up gauge inside Dark Force Change).
# The maintainer ruled the gauge rule (2026-09-18, 14z-168: "it makes sense that you
# can't build meter during DF"), so every other READ row is a candidate of the same
# class; this census freezes the full list so none is forgotten. What each reader does in
# our Dark Force is NOT measured here. Tool: tools/audit_df_field_readers.py (its
# docstring has the method, the data-region skip and what it cannot see).
#
# WHAT THE ROWS ARE (corrected 14z-168 after rule-checker run 2026-09-18-46 Q4: the first
# freeze called all 44 rows "readers" though 18 are writes, and had no control for a false
# row or a missed reader): each row carries its ACCESS (read / write / rmw / addr) and its
# BASE register. Step 1 runs the tool's --selftest, hand-assembled 68000 encodings of
# every access class plus two decoys that must NOT appear (an immediate that equals a
# field, field words inside a data region) — the false-row control. A MISSED reader is
# controlled only where the #136 corpus executes: tests/audit_df_field_readers_live.sh
# taps both fighter blocks and fails on any executed access from placed code that is not
# a row here. The a4-based rows are NOT shown to address a fighter block (no corpus run
# executes them).
#
# FROZEN: tests/expected/df_field_readers.tsv — `<access> <field> <addr> <region> <base>
# <insn>` rows, one `count` row (per field) and one `access` row (per class). A build that
# moves a placed region moves these addresses: re-freeze at every freeze (FREEZE=1),
# reviewing the diff.
#
# Usage: [BUILD=build/m3b_merged27] [FREEZE=1] tests/test_df_field_readers.sh
#   static tier (a build dir, no emulator); measured 14z-168 on this MacBook: ~6 s
set -eu
REPO="$(cd "$(dirname "$0")/.." && pwd)"
BUILD="${BUILD:-build/m3b_merged27}"
case "$BUILD" in /*) ;; *) BUILD="$REPO/$BUILD" ;; esac
EXPECT="$REPO/tests/expected/df_field_readers.tsv"
CONTROL="${CONTROL:-}"
for f in verify_op.bin patch/placements.json patch/patch.json; do
    [ -f "$BUILD/$f" ] || { echo "SKIP: no $f in $BUILD"; exit 0; }
done
python3 -c "import capstone" 2>/dev/null || { echo "SKIP: python capstone not installed"; exit 0; }
case "$CONTROL" in ""|planted) ;; *) echo "REFUSED: no control named '$CONTROL' is declared by this gate"; exit 3 ;; esac
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT INT TERM
fail=0
ok()  { printf '  ok    %s\n' "$1"; }
bad() { printf '  FAIL  %s\n' "$1"; fail=1; }
TOOL="$REPO/tools/audit_df_field_readers.py"
IMG="$BUILD/verify_op.bin"
if [ "$CONTROL" = planted ]; then
    python3 "$TOOL" "$IMG" "$BUILD/patch/placements.json" "$BUILD/patch/patch.json" --plant-first 1c3 --plant-out "$W/planted.bin" 2> "$W/plant.err" \
        || { echo "REFUSED: $(cat "$W/plant.err")"; exit 3; }
    IMG="$W/planted.bin"
fi

echo "== 1. the classifier's ground truth, then the census"
python3 "$TOOL" --selftest > "$W/selftest.log" 2>&1 && ok "$(tail -1 "$W/selftest.log")" || { bad "the classifier fails its fixtures:"; sed 's/^/        /' "$W/selftest.log"; }
python3 "$TOOL" "$IMG" "$BUILD/patch/placements.json" "$BUILD/patch/patch.json" --tsv > "$W/got.tsv" 2> "$W/err" || { bad "tool: $(tail -1 "$W/err")"; }
[ "$fail" = 0 ] || { echo "FAIL: test_df_field_readers"; exit 1; }
# THE KNOWN READER, anchored OUTSIDE our build (reworked 14z-170): until the M19 freeze this
# line required the x028122 meter-adder copy, the reader tests/audit_df_meter.sh measured —
# and the ruled gauge fix moved exactly that operand to +0x111, vsavj's own adder's field. The
# anchor is now vs2's OWN code: its POWER activation's "already in Power" test at vs2
# 0x02617A (`tst.b $1c3(a6)`, read here in vs2's pristine opcode view), which every tenant's
# placed x026142 copy carries at placement + (0x2617A - src). Each must be a census row.
. "$REPO/tests/lib/decrypt_cache.sh"
decrypt_view vsav2 "$W/vsav2.op" || { bad "decrypt_view vsav2 unavailable"; echo "FAIL: test_df_field_readers"; exit 1; }
_anchor="$(python3 -c "import sys; print(open(sys.argv[1],'rb').read()[0x2617A:0x2617E].hex())" "$W/vsav2.op")"
[ "$_anchor" = 4a2e01c3 ] || bad "vs2's 0x02617A is not tst.b \$1c3(a6) (read $_anchor) — the anchor moved, the reading is wrong"
_want="$(python3 - "$BUILD/patch/placements.json" <<'PY'
import json, sys
R = json.load(open(sys.argv[1]))["regions"]
for k, v in sorted(R.items()):
    if k.split("@")[0] == "x026142" and v["src"] <= 0x2617A < v["src"] + v["len"]:
        print("%#08x\t%s" % (v["dst"] + 0x2617A - v["src"], k))
PY
)"
[ "$(printf '%s\n' "$_want" | grep -c .)" = 3 ] || bad "expected three placed x026142 copies (one per tenant), found: $(printf '%s' "$_want" | tr '\n' ' ')"
printf '%s\n' "$_want" | while IFS="$(printf '\t')" read -r _a _r; do
    [ -n "$_a" ] || continue
    awk -F'\t' -v a="$_a" -v r="$_r" '$1=="read" && $2=="+0x1c3" && $3==a && $4==r' "$W/got.tsv" | grep -q . \
        || { echo "  FAIL  the known reader (vs2 0x02617A's copy in $_r at $_a) is not a census row — the census is blind"; echo x >> "$W/anchor.bad"; }
done
[ -f "$W/anchor.bad" ] && fail=1
[ -f "$W/anchor.bad" ] || ok "the known reader, vs2 0x02617A's tst.b \$1c3(a6), is a row in every placed x026142 copy ($(printf '%s\n' "$_want" | grep -c .))"
# THE RULED GAUGE FIX, asserted: no +0x1C3 read in any x028122 copy (the adder tests +0x111)
awk -F'\t' '$2=="+0x1c3" && $4 ~ /^x028122/' "$W/got.tsv" | grep -q . && bad "an x028122 copy reads +0x1C3 again — the M19 gauge fix (the adder tests +0x111, as vsavj's) regressed"
ok "$(grep -c -v -E '^(count|access)' "$W/got.tsv" | tr -d ' ') rows; $(grep '^access' "$W/got.tsv" | cut -f2- | tr '\t' ' '); $(grep '^count' "$W/got.tsv" | cut -f2- | tr '\t' ' ')"

echo "== 2. the frozen rows"
if [ "${FREEZE:-0}" = 1 ]; then
    {
        echo "# tests/expected/df_field_readers.tsv — placed instructions of the merged build that name one of vs2's Dark Force POWER"
        echo "# fields (+0x1C3 +0x1C4 +0x1C6 +0x1C7 +0x1C8) by displacement, never set by our host engine's Dark Force Change, with the"
        echo "# access each makes and its base register (tests/test_df_field_readers.sh; tools/audit_df_field_readers.py). Evidence class:"
        echo "# static. First frozen 14z-168; this freeze with FREEZE=1 on $(basename "$BUILD"). The x028122 meter adder copies, the one reader"
        echo "# measured to change play, test +0x111 since the M19 gauge fix (tests/audit_df_meter.sh) and are no rows; the rest are"
        echo "# unmeasured. Columns: <access> <field> <addr> <region> <base> <insn>."
        echo "# Re-freeze at every freeze (placed addresses move), reviewing the diff."
        echo "#--"
        cat "$W/got.tsv"
    } > "$EXPECT"
    echo "  FROZE  $(basename "$EXPECT") ($(wc -l < "$W/got.tsv" | tr -d ' ') rows) — VERIFY by re-running without FREEZE"; exit 0
fi
[ -f "$EXPECT" ] || { echo "FAIL: no frozen expectation at $EXPECT (FREEZE=1 to create it)"; exit 1; }
grep -v '^#' "$EXPECT" > "$W/want.tsv"
if diff "$W/want.tsv" "$W/got.tsv" > "$W/diff.txt"; then ok "every row as frozen"
else bad "differs from the frozen rows"; sed 's/^/        /' "$W/diff.txt"; fi

echo "== 3. must-fire control"
if [ "$CONTROL" = planted ]; then
    if [ "$fail" = 1 ]; then echo "CONTROL FIRED: planted — the re-addressed row leaves the census"; echo "FAIL: test_df_field_readers (control mode)"; exit 1
    else echo "CONTROL DEAD: planted — the census did not change"; echo "FAIL: test_df_field_readers"; exit 1; fi
fi
python3 "$TOOL" "$BUILD/verify_op.bin" "$BUILD/patch/placements.json" "$BUILD/patch/patch.json" --plant-first 1c3 --plant-out "$W/ctl.bin" 2>/dev/null \
    && python3 "$TOOL" "$W/ctl.bin" "$BUILD/patch/placements.json" "$BUILD/patch/patch.json" --tsv > "$W/ctl.tsv" 2>/dev/null || true
_nc="$(grep -c -v -E '^(count|access)' "$W/ctl.tsv" 2>/dev/null | tr -d ' ')"; _ng="$(grep -c -v -E '^(count|access)' "$W/got.tsv" | tr -d ' ')"
if [ -s "$W/ctl.tsv" ] && [ "$_nc" -lt "$_ng" ]; then
    echo "CONTROL FIRED: planted — the planted image censuses $_nc rows against $_ng"
else echo "CONTROL DEAD: planted — the planted row was still counted"; fail=1; fi

if [ "$fail" = 0 ]; then echo "PASS: test_df_field_readers"; else echo "FAIL: test_df_field_readers"; exit 1; fi
