#!/bin/sh
# test_id_space.sh — freeze the shape of the character-id space.
#
# WHY. The roster plan puts three newcomers on ids in the variant half
# (0x10-0x1F), which is only sound if (a) the per-character tables really
# have rows there and (b) the small set of code sites that narrow the id to
# 4 bits is known and does not grow behind our backs. Both are measured by
# tools/audit_id_space.py; this pins the numbers so a table edit that
# changes what an id MEANS fails here instead of in a playtest.
#
# The frozen facts (vsavj, measured 14z-60 — docs/atlas/id_space.md):
#   * 0 out-of-range variant rows across the layout-verified tables: every
#     id 0x00-0x1F has real storage in all of them.
#   * exactly 5 sites fold the id to 4 bits, at known addresses.
#   * the only variant rows holding their OWN data are 0x18 (Oboro
#     Bishamon) and word_pos_a[0x16] (Anakaris).
# And for vsav2, which ships three characters on variant ids:
#   * its bank rows are distinct at 10 11 13 18 19, and it folds at only 2
#     sites — the evidence that widening the folding sites is the fix.
#
# Usage: ROMDIR=... tests/test_id_space.sh
set -eu
ROMDIR="${ROMDIR:?set ROMDIR}"
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
WORK="${TMPDIR:-/tmp}/id_space_$$"
mkdir -p "$WORK"
trap 'rm -rf "$WORK"' EXIT
fail=0

want() {  # want <label> <file> <string>
    if grep -qF -- "$3" "$2"; then
        echo "  PASS  $1"
    else
        echo "  FAIL  $1"
        echo "        expected to find: $3"
        fail=1
    fi
}

python3 tools/audit_roms.py "$ROMDIR" >"$WORK/audit.txt" 2>&1 || {
    echo "  FAIL  ROM audit"; cat "$WORK/audit.txt"; exit 1; }
echo "  PASS  ROM audit"

for s in vsavj vsav2; do
    python3 tools/cps2_decrypt.py "$ROMDIR/$s.zip" "$WORK/${s}_op.bin" \
        --data-out "$WORK/${s}_dat.bin" >"$WORK/dec.txt" 2>&1 || {
        echo "  FAIL  decrypt $s"; tail -5 "$WORK/dec.txt"; exit 1; }
    python3 tools/audit_id_space.py --set "$s" --op "$WORK/${s}_op.bin" \
        --dat "$WORK/${s}_dat.bin" >"$WORK/$s.txt" 2>&1 || {
        echo "  FAIL  audit $s"; tail -10 "$WORK/$s.txt"; exit 1; }
done

echo "== vsavj: every id has storage, and the folding set is known =="
want "no variant row is out-of-range" "$WORK/vsavj.txt" \
     "603 alias, 21 distinct, 0 out-of-range"
want "exactly the 5 known folding sites" "$WORK/vsavj.txt" \
     "mask #\$0f: 003E40 004082 00A43E 0409EC 04FAC4"
want "variant rows with own data: 0x18 only, in the bank" "$WORK/vsavj.txt" \
     "hitbox_base        0BD97A  distinct at 18"
want "the Anakaris variant outlier word_pos_a[0x16]" "$WORK/vsavj.txt" \
     "word_pos_a         0BE1BA  distinct at 16"

echo "== vsav2: the roster-on-variant-ids reference =="
want "bank rows distinct at 10 11 13 18 19" "$WORK/vsav2.txt" \
     "dispatch_00        0D7298  distinct at 10 11 13 18 19"
want "folds at only 2 sites (widened elsewhere)" "$WORK/vsav2.txt" \
     "mask #\$0f: 003E76 041BDC"

if [ "$fail" = 0 ]; then echo "ID SPACE: PASS"; else echo "ID SPACE: FAIL"; fi
exit "$fail"
