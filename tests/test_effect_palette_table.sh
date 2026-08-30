#!/bin/sh
# test_effect_palette_table.sh — the per-character palette POINTER tables are
# 32-row and id-indexed (14z-76). Static, no emulator, seconds.
#
# WHAT THIS PROTECTS. Pyron's effect palette was deferred for two sessions on
# the premise that PRG:0x38C218 "has only sixteen rows", so a tenant at a
# variant id would index PAST it and clobber a row vanilla uses. It does not:
# 0x38C198 and 0x38C218 are each ONE 32-row table indexed by the full
# character id, and 0x38C1D8 / 0x38C258 are their second halves, never used as
# a base. That measurement is what licenses repointing row 0x11, so it is
# frozen here rather than left in a session log.
#
#   1. THE AUDIT on vanilla vsavj + the build under test.
#   2. NEGATIVE CONTROLS — four, one per assertion the audit makes. A checker
#      that says PASS because it measured nothing is the failure mode this
#      project has paid for repeatedly (docs/GOTCHAS.md).
#
# Usage: ROMDIR=... tests/test_effect_palette_table.sh [build] [tenant]
#
# HANDOFF's gate-index note, moved into this header 14z-123 (verbatim; the
# documentation pass ruled a gate's WHY lives in the gate):
#   14z-76: the per-character palette POINTER tables are 32-row and id-
#   INDEXED. 0x38C198 (sprite) and 0x38C218 (effect) each hold 32 rows;
#   0x38C1D8/0x38C258 are their variant halves, never a base (0 refs in either
#   ROM view); both alias the base half except rows 0x12/0x18 (Oboro Bishamon
#   is real); and the 5 readers take the id byte UNMASKED. This is what
#   licenses repointing a tenant's row — the "only sixteen rows" reading
#   deferred Pyron's effect palette for two sessions. 4 negative controls (a
#   fold in the reader, a reference to the second half, a de-aliased variant
#   row, a build clobbering a base-half row).
#   tools/audit_effect_palette_table.py. Static, seconds
set -eu
ROMDIR="${ROMDIR:?set ROMDIR}"
REPO="$(cd "$(dirname "$0")/.." && pwd)"
. "$REPO/tests/lib/decrypt_cache.sh"   # GitHub #69
cd "$REPO"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
fail=0

BUILD="${1:-build/pyron21}"
TENANT="${2:-0x11}"
case "$BUILD" in /*) ;; *) BUILD="$REPO/$BUILD" ;; esac
OPIMG="$BUILD/verify_op.bin"
[ -f "$OPIMG" ] || { echo "FAIL: no $OPIMG"; exit 1; }

decrypt_view vsavj "$WORK/vj.bin" "$WORK/vjd.bin"

AUDIT="python3 $REPO/tools/audit_effect_palette_table.py"

echo "== 1. the audit on vanilla vsavj + $BUILD (tenant $TENANT)"
if $AUDIT "$WORK/vj.bin" "$WORK/vjd.bin" --build "$OPIMG" --tenant "$TENANT" \
        > "$WORK/a.txt" 2>&1; then
    sed 's/^/  /' "$WORK/a.txt"
else
    echo "  FAIL: the audit does not hold:"; sed 's/^/    /' "$WORK/a.txt"; fail=1
fi

# ctl <name> <expect-substring> -- runs the audit on the patched copies in
# $WORK/c_{op,da,build}.bin and requires it to FAIL for the stated reason.
ctl() {
    name="$1"; want="$2"
    if $AUDIT "$WORK/c_op.bin" "$WORK/c_da.bin" --build "$WORK/c_build.bin" \
            --tenant "$TENANT" > "$WORK/c.txt" 2>&1; then
        echo "  FAIL: $name — the audit passed a corrupted image"; fail=1
    elif grep -q "$want" "$WORK/c.txt"; then
        echo "  ok: $name caught ($(grep -m1 "$want" "$WORK/c.txt" | sed 's/^ *//' | cut -c1-64)...)"
    else
        echo "  FAIL: $name failed for the WRONG reason:"
        sed 's/^/    /' "$WORK/c.txt"; fail=1
    fi
}

reset_copies() {
    cp "$WORK/vj.bin" "$WORK/c_op.bin"
    cp "$WORK/vjd.bin" "$WORK/c_da.bin"
    cp "$OPIMG" "$WORK/c_build.bin"
}

echo "== 2. negative controls"

# (a) a FOLD appears above the table: the id is masked to 4 bits before it
#     indexes, which would make every variant row unreachable and silently
#     resolve a tenant onto a base-half character.
reset_copies
python3 - "$WORK/c_op.bin" <<'PY'
import sys
p = sys.argv[1]; b = bytearray(open(p, 'rb').read())
# at 0x02AFA2 the preamble is movea.l/moveq/move.b/lsl.w/movea.l; overwrite the
# lsl.w #2,d1 (e549) with andi.w #$000F,d1 (0241 000f is 3 words, so instead
# just corrupt the lsl into an and.w d0,d1 (c240) — any deviation must fail).
b[0x02AFA2 + 12:0x02AFA2 + 14] = bytes.fromhex('c240')
open(p, 'wb').write(bytes(b))
PY
ctl "a fold/edit in the reader preamble" "reader preamble changed"

# (b) something starts using 0x38C258 as a base — the "two 16-row tables"
#     world. If that is ever true, variant rows stop being spare.
reset_copies
python3 - "$WORK/c_op.bin" <<'PY'
import sys
p = sys.argv[1]; b = bytearray(open(p, 'rb').read())
b[0x300000:0x300004] = (0x38C258).to_bytes(4, 'big')
open(p, 'wb').write(bytes(b))
PY
ctl "a reference to the table's second half" "0x38c258 is referenced"

# (c) the alias shape moves: a variant row other than 0x12/0x18 stops
#     aliasing, i.e. vanilla started using it.
reset_copies
python3 - "$WORK/c_da.bin" <<'PY'
import sys
p = sys.argv[1]; b = bytearray(open(p, 'rb').read())
b[0x38C218 + 4 * 0x11:0x38C218 + 4 * 0x11 + 4] = (0x391BA0).to_bytes(4, 'big')
open(p, 'wb').write(bytes(b))
PY
ctl "a variant row that no longer aliases" "variant-half exceptions"

# (d) the build clobbers a base-half row — a real legacy break, and the one
#     the deferred premise feared. It must be caught.
reset_copies
python3 - "$WORK/c_build.bin" <<'PY'
import sys
p = sys.argv[1]; b = bytearray(open(p, 'rb').read())
b[0x38C218 + 4 * 0x01:0x38C218 + 4 * 0x01 + 4] = (0x3FABA0).to_bytes(4, 'big')
open(p, 'wb').write(bytes(b))
PY
ctl "a build clobbering a base-half row" "LEGACY CLOBBER"

[ "$fail" = 0 ] && echo "PASS: test_effect_palette_table.sh" \
                || echo "FAIL: test_effect_palette_table.sh"
exit "$fail"
