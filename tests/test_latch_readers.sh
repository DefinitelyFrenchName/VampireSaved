#!/bin/sh
# test_latch_readers.sh — WHO CAN READ THE SELECT-CONFIRM LATCH: the static census of every instruction naming a fighter block's +0x3BC/+0x3BD/+0x3C2/+0x3E0/+0x3E3 on vsav2, vsavj and the ported image, frozen (GitHub #151 step 3, 14z-161).
#
# MUST-FIRE: shadow-tool: blind-census — a copy of tools/audit_latch_readers.py whose disassembler never decodes the (d16,An) form must FAIL its own positive controls (in-gate: the tool's --selftest runs on both reference views and must PASS; mode: the shadow copy runs the same selftest and the gate's FAIL is its FAIL)
# MUST-FIRE: perturbed-copy: dropped-reader — the frozen inventory with one vsav2 reader row removed must FAIL the comparison (in-gate: the frozen file is compared against itself minus its first vs2 read row and must differ; mode: the gate compares the measured census against that perturbed expectation and FAILs)
#
# WHY. A forced-pick leg carries the CURSOR character's confirm-time latch in
# +0x3BD / +0x3C2 / +0x3E0 (tests/audit_forced_pick_fidelity.sh). Whether that
# can reach a gate's verdict is a question about the READERS of those bytes,
# and one rig's "never read in 3,400 frames" is absence on one path ([VSP-22]).
# tools/audit_latch_readers.py enumerates the readers BY FORM from the opcode
# views ([VSP-88]: every addressing form, not the one you remember), anchored on
# the extension word so a data table holding the value is not an instruction.
# The inventory is frozen here so a NEW reader — in a future port stage, or in a
# reading of the references this census had missed — is a finding, not a
# surprise: the frozen rows are the whole population the per-leg tap
# (tools/tap_latch_reads.sh, tests/audit_latch_reads.sh) can ever attribute a
# read to.
#
# What the census established (14z-161, and what the frozen file encodes):
#   - vs2 writes the flavor +0x3C2 at the confirm ONLY for cells 0x10 (00, or 01
#     with Start held) and 0x13 (01, or 00) — PRG:0x01F832 / PRG:0x01F86A — and
#     clears it at select entry (PRG:0x01F5C8); vsavj never writes it at all
#     (the port's init shim does, after any poke).
#   - the flavor's in-play readers are Phobos's (vs2 0x026322 every frame,
#     0x02595A / 0x02598A / 0x025B66 in the jump family) and Donovan's
#     (0x05A650 in the shared per-character code family, 0x065FE2 / 0x066020
#     in x065e5a); the ported image carries each tenant's relocated copy.
#   - the id copies' readers sit under the Shadow flag +0x3BC (the ladder base
#     0x00AF24, the byte table 0x00A782, 0x008FC2 / 0x00977A on vs2), in the
#     character-0x12 test 0x013194, and in the long copies 0x0130D0 / 0x01314C
#     (the HUD-name stager, [VSP-121]).
#   - the `movep` rows in the 0x3Axxxx-0x3Fxxxx range are the census's declared
#     NOISE: data regions whose words decode as movep with a matching
#     displacement; they are frozen so their count cannot grow unnoticed and
#     named so nobody chases them.
#
# Static tier: needs ROMDIR only on a cold decrypt cache (the views come from
# tests/lib/decrypt_cache.sh) and build/m3b_merged27/verify_op.bin for the ported image
# (SKIP without it, which --strict counts as failure).
#
# Usage: ROMDIR=... [FREEZE=1] tests/test_latch_readers.sh
set -eu
REPO="$(cd "$(dirname "$0")/.." && pwd)"
[ -n "${ROMDIR:-}" ] || { echo "FAIL: set ROMDIR"; exit 1; }
[ -d "$ROMDIR" ] && ROMDIR="$(cd "$ROMDIR" && pwd)"
CONTROL="${CONTROL:-}"
case "$CONTROL" in ""|blind-census|dropped-reader) ;; *) echo "REFUSED: no control named '$CONTROL' is declared by this gate"; exit 3 ;; esac
MERGED="${MERGED:-$REPO/build/m3b_merged27/verify_op.bin}"
[ -f "$MERGED" ] || { echo "SKIP: no ported opcode view at $MERGED"; exit 0; }
EXPECT="$REPO/tests/expected/latch_readers.tsv"
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT INT TERM
fail=0
ok()  { printf '  ok    %s\n' "$1"; }
bad() { printf '  FAIL  %s\n' "$1"; fail=1; }

echo "== 1. the opcode views (the decrypt cache, size-checked — tests/lib/decrypt_cache.sh)"
. "$REPO/tests/lib/decrypt_cache.sh"
for s in vsav2 vsavj; do
    decrypt_view "$s" "$W/$s.op" || bad "decrypt_view $s unavailable"
done
[ "$fail" = 0 ] || { echo "FAIL: test_latch_readers"; exit 1; }
ok "vsav2 and vsavj opcode views delivered from the cache"

echo "== 2. the census on each image, with the positive controls on the references"
TOOL="$REPO/tools/audit_latch_readers.py"
if [ "$CONTROL" = blind-census ]; then
    # the shadow tool: its (d16,An) recogniser is broken — it can only match the abs.l form
    sed 's/if val == off and f"\${off:x}(a" in o:/if False:/; s/elif val != off and f"\${val:x}(a5)" in o:/elif False:/' "$TOOL" > "$W/shadow_tool.py"
    TOOL="$W/shadow_tool.py"
fi
python3 "$TOOL" "$W/vsav2.op" --label vs2 --selftest vs2 --tsv "$W/vs2.tsv" > "$W/vs2.log" 2>&1 || bad "vs2 census: $(grep -E '^(FAIL|  FAIL)' "$W/vs2.log" | head -2 | tr '\n' ' ')"
python3 "$TOOL" "$W/vsavj.op" --label vsavj --selftest vsavj --tsv "$W/vsavj.tsv" > "$W/vsavj.log" 2>&1 || bad "vsavj census: $(grep -E '^(FAIL|  FAIL)' "$W/vsavj.log" | head -2 | tr '\n' ' ')"
python3 "$TOOL" "$MERGED" --label merged --tsv "$W/merged.tsv" > "$W/merged.log" 2>&1 || bad "merged census failed: $(tail -1 "$W/merged.log")"
if [ "$CONTROL" = blind-census ]; then
    if [ "$fail" = 1 ]; then echo "CONTROL FIRED: blind-census — the shadow tool fails its positive controls"; echo "FAIL: test_latch_readers (control mode)"; exit 1
    else echo "CONTROL DEAD: blind-census — the shadow tool passed its positive controls"; echo "FAIL: test_latch_readers"; exit 1; fi
fi
[ "$fail" = 0 ] || { echo "FAIL: test_latch_readers"; exit 1; }
ok "positive controls: $(grep -c '^  ok    control' "$W/vs2.log") vs2 + $(grep -c '^  ok    control' "$W/vsavj.log") vsavj known sites found with their class"

# the measured inventory: image, addr, offset, what, class, width, mnemonic, operands
{
    echo "# tests/expected/latch_readers.tsv — every instruction operand naming a fighter block's confirm-latch offset,"
    echo "# on the two reference opcode views and the ported image (tools/audit_latch_readers.py; test_latch_readers.sh)."
    echo "# Evidence class: static (the decrypted opcode views; the ported image is build/m3b_merged27/verify_op.bin)."
    echo "# Frozen 14z-161 with FREEZE=1; re-freeze after a port stage that relocates a reader, never to absorb a new one unread."
    echo "# Columns: image, addr, offset, what, class, width, mnemonic, operands"
    echo "#--"
    for img in vs2 vsavj merged; do awk -F'\t' -v i="$img" '!/^#/ && $1!="addr" {print i"\t"$0}' "$W/$img.tsv"; done
} > "$W/got.tsv"
n_vs2="$(grep -c '^vs2	' "$W/got.tsv" || true)"; n_vsj="$(grep -c '^vsavj	' "$W/got.tsv" || true)"; n_m="$(grep -c '^merged	' "$W/got.tsv" || true)"
echo "  measured: vs2 $n_vs2 rows, vsavj $n_vsj, merged $n_m"

echo "== 3. the frozen inventory"
if [ "${FREEZE:-0}" = 1 ]; then
    cp "$W/got.tsv" "$EXPECT"; echo "  FROZE  $(basename "$EXPECT") — VERIFY by re-running without FREEZE"; exit 0
fi
[ -f "$EXPECT" ] || { echo "FAIL: no frozen inventory at $EXPECT (FREEZE=1 to create it)"; exit 1; }
WANT="$EXPECT"
if [ "$CONTROL" = dropped-reader ]; then
    first="$(awk -F'\t' '!/^#/ && $1=="vs2" && $5=="read" {print NR; exit}' "$EXPECT")"
    awk -v n="$first" 'NR!=n' "$EXPECT" > "$W/perturbed.tsv"; WANT="$W/perturbed.tsv"
fi
grep -v '^#' "$WANT" > "$W/want.rows"; grep -v '^#' "$W/got.tsv" > "$W/got.rows"
if diff "$W/want.rows" "$W/got.rows" > "$W/diff.txt"; then
    ok "inventory as frozen ($n_vs2 + $n_vsj + $n_m rows)"
else
    bad "inventory differs from $(basename "$WANT"): $(grep -c '^[<>]' "$W/diff.txt") rows (a NEW reader is a finding — read it before re-freezing)"
    head -20 "$W/diff.txt"
fi
if [ "$CONTROL" = dropped-reader ]; then
    if [ "$fail" = 1 ]; then echo "CONTROL FIRED: dropped-reader — the inventory minus one vs2 read row fails the comparison"; echo "FAIL: test_latch_readers (control mode)"; exit 1
    else echo "CONTROL DEAD: dropped-reader — a missing row went unnoticed"; echo "FAIL: test_latch_readers"; exit 1; fi
fi

echo "== 4. must-fire controls (in-gate)"
# blind-census: the shadow tool must fail the vs2 selftest
sed 's/if val == off and f"\${off:x}(a" in o:/if False:/; s/elif val != off and f"\${val:x}(a5)" in o:/elif False:/' "$REPO/tools/audit_latch_readers.py" > "$W/shadow_tool.py"
if python3 "$W/shadow_tool.py" "$W/vsav2.op" --selftest vs2 > "$W/shadow.log" 2>&1; then
    echo "CONTROL DEAD: blind-census — a tool blind to the (d16,An) form passed its positive controls"; fail=1
else
    echo "CONTROL FIRED: blind-census — the (d16,An)-blind shadow tool fails $(grep -c '^  FAIL  control' "$W/shadow.log") of its positive controls"
fi
# dropped-reader: the frozen file minus one read row must differ from itself
first="$(awk -F'\t' '!/^#/ && $1=="vs2" && $5=="read" {print NR; exit}' "$EXPECT")"
grep -v '^#' "$EXPECT" > "$W/full.rows"; awk -v n="$first" 'NR!=n' "$EXPECT" | grep -v '^#' > "$W/minus.rows"
if [ -n "$first" ] && ! diff "$W/full.rows" "$W/minus.rows" > /dev/null; then
    echo "CONTROL FIRED: dropped-reader — removing the row at line $first is seen by the comparison"
else
    echo "CONTROL DEAD: dropped-reader — no vs2 read row to drop, or its removal went unseen"; fail=1
fi

if [ "$fail" = 0 ]; then echo "PASS: test_latch_readers"; else echo "FAIL: test_latch_readers"; exit 1; fi
