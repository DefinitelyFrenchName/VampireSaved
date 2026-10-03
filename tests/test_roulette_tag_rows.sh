#!/usr/bin/env bash
# test_roulette_tag_rows.sh — the arcade-ladder map's opponent TAG rows per character id, in
# vsavj and vs2 (14z-189, GitHub #124). ci_static: ROMDIR only.
#
# WHAT: the tag (name + mini-art beside the current opponent) is drawn from ROW id of the
#   long array the sub-0x08 child's init names (vsavj 0x26752A), placed by two word tables
#   (0x0603DE / 0x06041E) and coloured from pool 0x3A3CA0; in vsavj the array and both width
#   tables carry rows 0x10-0x13 as COPIES of rows 0x00-0x03, so a tenant at 0x10 draws
#   Bulleta's tag. vs2 carries its own rows at 0x10/0x11/0x13 (0x12 aliases, as Dark Gallon
#   must). The "4-bit-folded consumer" of #124 is this data, not code.
# HOW: static over the decrypted views (ROMDIR only), tools/audit_roulette_tag_rows.py, which
#   LOCATES the array, the tables and the pool by instruction pattern in each image.
# EXPECTS: the rows below; the control (a vsavj copy with array row 0x10 changed) fails.
#
# MUST-FIRE: perturbed-copy: unalias-row — a copy of vsavj's data view with array row 0x10 pointed at row 0x0F's record must change the frozen ARRAY row (the gate reads the rows from the image, not from constants)
#
# WHY. #124 was filed (14z-123) as "a 4-bit-folded consumer" from the screen alone. Measured
# 14z-189 on merged-m22 (replay 111, CPU Phobos and CPU Bishamon legs, effect pool dumped at
# the map frame): the Phobos rung's sub-0x08 child carries +0x0A = 0x10 and +0x1C = 0x267566,
# the builder's `movea.l $1c(a6),a0 / movea.l 4(a0),a0` (PRG:0x01AFA6) draws row 0x10, and
# that row equals row 0x00. The same model as the shipped select_records rows (the sibling
# arrays 0x2675AA / 0x26762A, repointed from vs2 0x2A08E2 / 0x2A0962), one array earlier.
# The fix's scope is recorded in docs/game/engine_internals.md beside test_ladder_tenant_vs_palette.
#
# Usage: ROMDIR=... tests/test_roulette_tag_rows.sh
set -eu
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
ROMDIR="${ROMDIR:?set ROMDIR}"
if [ -d "$ROMDIR" ]; then ROMDIR="$(cd "$ROMDIR" && pwd)"; fi
. "$REPO/tests/lib/decrypt_cache.sh"   # GitHub #69: never re-decrypt directly
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT
fail=0
note() { printf '%s\n' "$*"; }
chk() { # label expected actual
    if [ "$2" = "$3" ]; then note "  ok   $1"; else note "  FAIL $1: expected [$2] got [$3]"; fail=1; fi
}
decrypt_view vsavj "$W/vj_op.bin" "$W/vj_data.bin"
decrypt_view vsav2 "$W/v2_op.bin" "$W/v2_data.bin"
. "$REPO/tests/lib/controls.sh"; vs_ctl_mode "$0"

python3 - "$W/vj_data.bin" "$W/vj_data_bad.bin" <<'EOF'
import sys
d = bytearray(open(sys.argv[1], 'rb').read()); A = 0x26752A
d[A + 4 * 0x10:A + 4 * 0x11] = d[A + 4 * 0x0F:A + 4 * 0x10]
open(sys.argv[2], 'wb').write(bytes(d))
EOF
VJD="$W/vj_data.bin"
vs_ctl_is unalias-row && VJD="$W/vj_data_bad.bin"

T=tools/audit_roulette_tag_rows.py
python3 "$T" vsavj "$W/vj_op.bin" "$VJD" > "$W/vj.txt" || { note "  FAIL: tool errored (vsavj)"; fail=1; }
python3 "$T" vsav2 "$W/v2_op.bin" "$W/v2_data.bin" > "$W/v2.txt" || { note "  FAIL: tool errored (vsav2)"; fail=1; }
grep -v '^#' "$W/vj.txt" "$W/v2.txt" | sed 's/^[^:]*:/    /'
row() { grep "^$1 $2" "$W/$3.txt"; }

note "1. vsavj: rows 0x10-0x13 are copies of 0x00-0x03 (the tenant draws a base character's tag)"
chk "vsavj array" "ARRAY vsavj site 0x05fc1c base 0x26752a 10:272f08:ALIAS 11:272f16:ALIAS 12:272f24:ALIAS 13:272f32:ALIAS" "$(row ARRAY vsavj vj)"
chk "vsavj width tables" "WIDTH vsavj table 0x0603de 10:0010:ALIAS 11:0010:ALIAS 12:0010:ALIAS 13:0014:ALIAS
WIDTH vsavj table 0x06041e 10:ffdf:ALIAS 11:ffe0:ALIAS 12:ffe0:ALIAS 13:ffe2:ALIAS" "$(row WIDTH vsavj vj)"
chk "vsavj pool" "POOL vsavj site 0x00b0a0 base 0x3a3ca0 10:34e13a:OWN 11:b16977:OWN 12:548883:OWN 13:834707:OWN" "$(row POOL vsavj vj)"
note "2. vs2: its own rows at 0x10/0x11/0x13; 0x12 (Dark Gallon) aliases Gallon"
chk "vs2 array" "ARRAY vsav2 site 0x06bdb2 base 0x2a0862 10:2a73a8:OWN 11:2a7664:OWN 12:2a732a:ALIAS 13:2a7672:OWN" "$(row ARRAY vsav2 v2)"
chk "vs2 width tables" "WIDTH vsav2 table 0x06c7f2 10:0010:ALIAS 11:0010:ALIAS 12:0010:ALIAS 13:000e:OWN
WIDTH vsav2 table 0x06c832 10:ffe0:OWN 11:ffe0:ALIAS 12:ffe0:ALIAS 13:ffde:OWN" "$(row WIDTH vsav2 v2)"
chk "vs2 pool" "POOL vsav2 site 0x009910 base 0x3bb3dc 10:34e13a:OWN 11:b16977:OWN 12:d9621e:OWN 13:63d52c:OWN" "$(row POOL vsav2 v2)"

note "3. verdict control (must fire)"
if [ -z "${VS_CTL:-}" ]; then
    python3 "$T" vsavj "$W/vj_op.bin" "$W/vj_data_bad.bin" > "$W/bad.txt" || true
    if grep -q '10:272f08:ALIAS' "$W/bad.txt"; then
        vs_ctl_dead unalias-row "the ARRAY row did not move with the image"; fail=1
    else
        vs_ctl_fired unalias-row "$(grep '^ARRAY' "$W/bad.txt" | cut -c1-80)"
    fi
fi

if [ "$fail" -eq 0 ]; then note "PASS test_roulette_tag_rows"; else note "FAIL test_roulette_tag_rows"; exit 1; fi
