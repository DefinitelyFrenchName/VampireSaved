#!/bin/sh
# test_latch_readers.sh — WHO CAN READ THE SELECT-CONFIRM LATCH: the static census of every instruction naming a fighter block's +0x3BC/+0x3BD/+0x3C2/+0x3E0/+0x3E3 on vsav2, vsavj and the ported image, frozen (GitHub #151 step 3, 14z-161).
#
# WHAT: who CAN read the select-confirm latch: the static census of every instruction naming
#   a fighter block's +0x3BC/+0x3BD/+0x3C2/+0x3E0/+0x3E3 on vsav2, vsavj and the ported
#   image, by addressing form, frozen — the whole population the per-leg tap
#   (audit_latch_reads) can ever attribute a read to, with the census's data-region `movep`
#   noise frozen and named.
# HOW: tools/audit_latch_readers.py over the decrypted opcode views and
#   build/m3b_merged30/verify_op.bin, anchored on the extension word so a data table is not
#   an instruction, its --selftest on both reference views first (an immediate store among its
#   positive controls since #197); controls: a shadow copy of the tool blind to the (d16,An) form,
#   a copy with the pre-#197 nearest-decodable scan, and the frozen inventory minus one vs2 reader row;
#   a PLANTED 44-byte opcode image carries one site of each form (abs.l immediate, abs.l register, (d16,An)
#   immediate), since no abs.l site exists in any real image.
# EXPECTS: the frozen inventory equal (vs2's confirm writers and clears, the tenants'
#   in-play flavour readers and their relocated copies, the Shadow-flag readers); the blind
#   tool fails its selftest, the planted image gives exactly its three write rows, the pre-#197 copy
#   misses the immediate store vs2 PRG:0x00712A and both planted immediates, the
#   dropped row fails the compare.
#
# MUST-FIRE: shadow-tool: blind-census — a copy of tools/audit_latch_readers.py whose disassembler never decodes the (d16,An) form must FAIL its own positive controls (in-gate: the tool's --selftest runs on both reference views and must PASS; mode: the shadow copy runs the same selftest and the gate's FAIL is its FAIL)
# MUST-FIRE: shadow-tool: nearest-decode — a copy of tools/audit_latch_readers.py that stops at the nearest DECODABLE opcode (the pre-#197 scan) instead of the nearest decode NAMING the offset must FAIL its immediate-store positive control (in-gate: that copy's --selftest on the vs2 view must FAIL on PRG:0x00712A; mode: the copy is the census tool and the gate FAILs)
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
# tests/lib/decrypt_cache.sh) and build/m3b_merged30/verify_op.bin for the ported image
# (SKIP without it, which --strict counts as failure).
#
# Usage: ROMDIR=... [FREEZE=1] tests/test_latch_readers.sh
set -eu
REPO="$(cd "$(dirname "$0")/.." && pwd)"
[ -n "${ROMDIR:-}" ] || { echo "FAIL: set ROMDIR"; exit 1; }
[ -d "$ROMDIR" ] && ROMDIR="$(cd "$ROMDIR" && pwd)"
CONTROL="${CONTROL:-}"
case "$CONTROL" in ""|blind-census|dropped-reader|nearest-decode) ;; *) echo "REFUSED: no control named '$CONTROL' is declared by this gate"; exit 3 ;; esac
MERGED="${MERGED:-$REPO/build/m3b_merged30/verify_op.bin}"
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
nearest_copy() {  # nearest_copy <out> — the pre-#197 scan: the nearest DECODABLE opcode wins, named or not
    python3 - "$REPO/tools/audit_latch_readers.py" "$1" <<'PY'
import sys; src, out = sys.argv[1:3]; s = open(src).read()
a = "            if named:\n                break\n"
assert s.count(a) == 1, "the named-break is gone from the tool"
open(out, "w").write(s.replace(a, "            break  # CONTROL nearest-decode\n"))
PY
}
TOOL="$REPO/tools/audit_latch_readers.py"
if [ "$CONTROL" = blind-census ]; then
    # the shadow tool: its (d16,An) recogniser is broken — it can only match the abs.l form
    sed 's/if val == off and f"\${off:x}(a" in o:/if False:/; s/elif val != off and f"\${val:x}(a5)" in o:/elif False:/' "$TOOL" > "$W/shadow_tool.py"
    TOOL="$W/shadow_tool.py"
fi
if [ "$CONTROL" = nearest-decode ]; then nearest_copy "$W/nearest_tool.py"; TOOL="$W/nearest_tool.py"; fi
python3 "$TOOL" "$W/vsav2.op" --label vs2 --selftest vs2 --tsv "$W/vs2.tsv" > "$W/vs2.log" 2>&1 || bad "vs2 census: $(grep -E '^(FAIL|  FAIL)' "$W/vs2.log" | head -2 | tr '\n' ' ')"
python3 "$TOOL" "$W/vsavj.op" --label vsavj --selftest vsavj --tsv "$W/vsavj.tsv" > "$W/vsavj.log" 2>&1 || bad "vsavj census: $(grep -E '^(FAIL|  FAIL)' "$W/vsavj.log" | head -2 | tr '\n' ' ')"
python3 "$TOOL" "$MERGED" --label merged --tsv "$W/merged.tsv" > "$W/merged.log" 2>&1 || bad "merged census failed: $(tail -1 "$W/merged.log")"
if [ "$CONTROL" = nearest-decode ]; then
    if grep -q '^  FAIL  control PRG:0x00712A' "$W/vs2.log"; then echo "CONTROL FIRED: nearest-decode — the pre-#197 scan misses the immediate store vs2 PRG:0x00712A"; echo "FAIL: test_latch_readers (control mode)"; exit 1
    else echo "CONTROL DEAD: nearest-decode — the pre-#197 scan found the immediate store"; echo "FAIL: test_latch_readers"; exit 1; fi
fi
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
    echo "# Evidence class: static (the decrypted opcode views; the ported image is build/m3b_merged30/verify_op.bin)."
    echo "# Frozen 14z-161 with FREEZE=1; re-freeze after a port stage that relocates a reader, never to absorb a new one unread."
    echo "# Columns: image, addr, offset, what, class, width, mnemonic, operands"
    echo "#--"
    for img in vs2 vsavj merged; do awk -F'\t' -v i="$img" '!/^#/ && $1!="addr" {print i"\t"$0}' "$W/$img.tsv"; done
} > "$W/got.tsv"
n_vs2="$(grep -c '^vs2	' "$W/got.tsv" || true)"; n_vsj="$(grep -c '^vsavj	' "$W/got.tsv" || true)"; n_m="$(grep -c '^merged	' "$W/got.tsv" || true)"
echo "  measured: vs2 $n_vs2 rows, vsavj $n_vsj, merged $n_m"

echo "== 2b. a PLANTED image: one site of every operand form the census claims (#197, rule-checker run 2026-10-01-525)"
# No abs.l site exists in any of the three images, so the abs.l path had no positive control: a 44-byte opcode image
# planted with move.b #$1,$ff87bd.l (abs.l IMMEDIATE), move.b d0,$ff8bc2.l (abs.l register, P2's block) and
# move.b #$5,$3e0(a6) ((d16,An) IMMEDIATE), padded with nops, must give exactly those three write rows.
python3 - "$W/planted.op" <<'PY'
import struct, sys
w = [0x4e71]*4 + [0x13fc, 0x0001, 0x00ff, 0x87bd] + [0x4e71]*2 + [0x13c0, 0x00ff, 0x8bc2] + [0x4e71]*2 + [0x1d7c, 0x0005, 0x03e0] + [0x4e71]*4
open(sys.argv[1], "wb").write(struct.pack(f">{len(w)}H", *w))
PY
planted_rows() { python3 "$1" "$W/planted.op" --label planted --tsv "$2" > /dev/null 2>&1; grep '^0x' "$2" | cut -f1,2,4 | tr '\t' ' ' | tr '\n' '|'; }
want='0x000008 0x3BD write|0x000014 0x3C2 write|0x00001E 0x3E0 write|'
got="$(planted_rows "$TOOL" "$W/planted.tsv")"
[ "$got" = "$want" ] && ok "every planted form found: abs.l immediate, abs.l register, (d16,An) immediate" \
    || bad "the planted image reads [$got], not [$want]"
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
# nearest-decode (#197): the pre-fix scan must miss the immediate store vs2 PRG:0x00712A
nearest_copy "$W/nearest_tool.py"
if python3 "$W/nearest_tool.py" "$W/vsav2.op" --selftest vs2 > "$W/nearest.log" 2>&1; then
    echo "CONTROL DEAD: nearest-decode — the pre-#197 scan passed its positive controls"; fail=1
elif grep -q '^  FAIL  control PRG:0x00712A' "$W/nearest.log"; then
    echo "CONTROL FIRED: nearest-decode — $(grep '^  FAIL  control PRG:0x00712A' "$W/nearest.log" | sed 's/^ *//')"
    pr="$(planted_rows "$W/nearest_tool.py" "$W/planted_nearest.tsv")"
    [ "$pr" = "0x000014 0x3C2 write|" ] && echo "  ok    nearest-decode on the planted image: only the register form found ($pr) — both immediate forms missed" \
        || { echo "  FAIL  nearest-decode on the planted image reads [$pr]"; fail=1; }
else echo "CONTROL DEAD: nearest-decode — the copy failed, but not on the immediate store: $(grep -m1 FAIL "$W/nearest.log")"; fail=1; fi
# dropped-reader: the frozen file minus one read row must differ from itself
first="$(awk -F'\t' '!/^#/ && $1=="vs2" && $5=="read" {print NR; exit}' "$EXPECT")"
grep -v '^#' "$EXPECT" > "$W/full.rows"; awk -v n="$first" 'NR!=n' "$EXPECT" | grep -v '^#' > "$W/minus.rows"
if [ -n "$first" ] && ! diff "$W/full.rows" "$W/minus.rows" > /dev/null; then
    echo "CONTROL FIRED: dropped-reader — removing the row at line $first is seen by the comparison"
else
    echo "CONTROL DEAD: dropped-reader — no vs2 read row to drop, or its removal went unseen"; fail=1
fi

if [ "$fail" = 0 ]; then echo "PASS: test_latch_readers"; else echo "FAIL: test_latch_readers"; exit 1; fi
