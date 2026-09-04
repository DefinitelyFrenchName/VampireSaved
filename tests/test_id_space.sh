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
# The frozen facts (vsavj, measured 14z-60 — docs/game/atlas/id_space.md):
#   * 0 out-of-range variant rows across the layout-verified tables: every
#     id 0x00-0x1F has real storage in all of them — including anim_pairs
#     (PRG:0x04FFA8), whose consumer masks to 4 bits anyway, so that mask is
#     convention and not structure.
#   * exactly 7 sites fold the id to 4 bits: 5 reached through a register,
#     plus 2 that mask the id field DIRECTLY in memory (the id-cycling
#     selector). The direct pair is invisible to register dataflow and was
#     missed by two walkers before being found by hand — hence the explicit
#     lock on both classes and on the total.
#   * the only variant rows holding their OWN data are 0x18 (Oboro
#     Bishamon) and word_pos_a[0x16] (Anakaris).
#   * RESERVED IDS: vanilla writes 0x12 outright (the Gallon-variant /
#     Dark Talbain select path at PRG:0x020BB6/0x020BC6), so 0x12 is not
#     free for a tenant. Growth of this set invalidates a roster plan that
#     assumes 0x10/0x11/0x13 are available.
# And for vsav2, which ships three characters on variant ids:
#   * its bank rows are distinct at 10 11 13 18 19, and it folds at only 2
#     sites — the evidence that widening the folding sites is the fix.
#
# Usage: ROMDIR=... tests/test_id_space.sh
#
# HANDOFF's gate-index note, moved into this header 14z-123 (verbatim; the
# documentation pass ruled a gate's WHY lives in the gate):
#   freezes the id space: 0 out-of-range variant rows, the 5 sites that fold
#   the id to 4 bits, and vsav2's 2-fold/6-widened reference shape
set -eu
ROMDIR="${ROMDIR:?set ROMDIR}"
# 14z-132: ABSOLUTE. Gates `cd` into work dirs and then compose paths that
# still contain $ROMDIR (e.g. MAME_ROMPATH="...;$ROMDIR"); a RELATIVE value —
# which is how the runners invoke everything (ROMDIR=../ROMS) — then resolves
# against the WORK dir and silently finds no reference members. Kept as a
# VARIABLE (forks set their own); only made absolute, and only if it exists,
# so a gate that means to SKIP on a missing ROMDIR still does.
if [ -d "$ROMDIR" ]; then ROMDIR="$(cd "$ROMDIR" && pwd)"; fi
REPO="$(cd "$(dirname "$0")/.." && pwd)"
. "$REPO/tests/lib/decrypt_cache.sh"   # GitHub #69
cd "$REPO"
WORK="$(mktemp -d)"        # GitHub #68: not a predictable name
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
    decrypt_view $s "$WORK/${s}_op.bin" "$WORK/${s}_dat.bin" || {
        echo "  FAIL  decrypt $s"; tail -5 "$WORK/dec.txt"; exit 1; }
    python3 tools/audit_id_space.py --set "$s" --op "$WORK/${s}_op.bin" \
        --dat "$WORK/${s}_dat.bin" >"$WORK/$s.txt" 2>&1 || {
        echo "  FAIL  audit $s"; tail -10 "$WORK/$s.txt"; exit 1; }
done

echo "== vsavj: every id has storage, and the folding set is known =="
want "no variant row is out-of-range" "$WORK/vsavj.txt" \
     "45 tables x 16 variant ids: 695 alias, 25 distinct, 0 out-of-range"   # 14z-130: +1 table (bank_map gap_be27a + gap_be2ba, two kind=auto rows the audit could not classify, corrected to ONE `capture_kf_ptr` data_ptr row) = +16 alias / +0 distinct in VANILLA — and that is an INDEPENDENT confirmation of the correction, not bookkeeping: the audit reads the ROM and finds all 16 variant rows of the new table are ALIASES of the base half, which is exactly what the model says (rows 0x10-0x1F byte-identical to 0x00-0x0F, tests/test_capture_kf_ownership.sh section 1). (was 44 / 679 / 25; 14z-111: +4 tables ai_script_0..3 = +60 alias / +4 distinct, was 40 / 619 / 21)
want "the 5 register-path folding sites" "$WORK/vsavj.txt" \
     "mask #\$0f: 003E40 004082 00A43E 0409EC 04FAC4"
want "the 2 direct-to-memory folds (id cycling)" "$WORK/vsavj.txt" \
     "direct-to-memory: 010E2C 010E3A"
want "7 folding sites in total" "$WORK/vsavj.txt" \
     "TOTAL FOLDING SITES: 7"
want "variant rows with own data: 0x18 only, in the bank" "$WORK/vsavj.txt" \
     "hitbox_base        0BD97A  distinct at 18"
want "the Anakaris variant outlier word_pos_a[0x16]" "$WORK/vsavj.txt" \
     "word_pos_a         0BE1BA  distinct at 16"

# RESERVED IDS. vanilla writes id 0x12 outright at two sites (the Gallon
# variant / Dark Talbain path), so 0x12 is NOT free for a tenant. If this
# set ever grows, a roster plan built on "0x10/0x11/0x13 are free" must be
# re-checked BEFORE anything is built on it.
want "vsavj reserves id 0x12 (two hardcoded writes)" "$WORK/vsavj.txt" \
     "variant-half ids vanilla can produce by immediate: 12"
want "  the two 0x12 sites are where they were" "$WORK/vsavj.txt" \
     "020BB6  move.b #\$12,\$382(a6)"

echo "== vsav2: the roster-on-variant-ids reference =="
want "bank rows distinct at 10 11 13 18 19" "$WORK/vsav2.txt" \
     "dispatch_00        0D7298  distinct at 10 11 13 18 19"
want "folds at only 2 sites (widened elsewhere)" "$WORK/vsav2.txt" \
     "TOTAL FOLDING SITES: 2"
want "vs2 widened the id-cycling mask to #\$1f" "$WORK/vsav2.txt" \
     "00F492  andi.b #\$1f,\$382(a4)   full 5-bit"
want "vs2 reserves 0x19 (its second Oboro dataset)" "$WORK/vsav2.txt" \
     "variant-half ids vanilla can produce by immediate: 19"

if [ "$fail" = 0 ]; then echo "ID SPACE: PASS"; else echo "ID SPACE: FAIL"; fi
exit "$fail"
