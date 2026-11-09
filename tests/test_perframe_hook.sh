#!/bin/sh
# test_perframe_hook.sh — #294'S PER-FRAME PALETTE PORT ON THE BUILT IMAGE IS EXACTLY vs2's ROUTINE, RE-POINTED, AND NOTHING ELSE (14z-216, GitHub #294).
#
# WHAT: the generator's [perframe_hook] section (tools/gen_donovan_patch.py; build/manifest/donovan.toml) ports vs2's
#   per-frame palette routine PRG:0x02A316 (+0x160) for Donovan: the per-frame table PRG:0x02ADEC's row 0x13 points at
#   the dead span PRG:0x024024 (tests/test_dead_span.sh), which jumps to the placed body; the body's 26 external
#   references are re-pointed to stubs, its records (vs2's sequence ids 0x2D4-0x341) placed beside it.
# HOW: tools/audit_perframe_hook.py on each build's verify_op.bin against vsavj's and vs2's decrypted views
#   (tests/lib/decrypt_cache.sh). It finds the routine's external references by decoding the SOURCE (never from the
#   manifest), compares the body instruction for instruction (capstone mnemonic + operand text), each re-pointed
#   reference against the stub its target maps to, the inline tables (opcode view), the appended lea tables (data
#   view) and the records (data view), and checks the other 31 table rows equal vsavj's.
# EXPECTS: STATE hooked and VERDICT OK on the merged build and on the Donovan solo build. A red names the check.
#   Stated, not tested: what the routine DOES at run time (tests/audit_don_row0c.sh, the emulator gate against native
#   vs2); the stock twin and the Phobos/Pyron solo builds (the section is only_variant_slot, Donovan's manifest only).
#
# MUST-FIRE: perturbed-copy: unmapped-escape — the merged image with one re-pointed branch given back vs2's displacement must FAIL (check B; mode: the tool's --plant unmapped-escape)
# MUST-FIRE: perturbed-copy: insn-flip — the merged image with one bit of an ordinary instruction's immediate flipped must FAIL (check B on the operand text; mode: --plant insn-flip)
# MUST-FIRE: perturbed-copy: table-flip — the merged image with one bit of the first inline PC-indexed table flipped must FAIL (check D; mode: --plant table-flip)
# MUST-FIRE: perturbed-copy: record-flip — the merged image with one bit of the records block flipped must FAIL (check D; mode: --plant record-flip)
# MUST-FIRE: perturbed-copy: row-default — the merged image with vsavj's word written back into row 0x13 must FAIL (STATE half; mode: --plant row-default)
# MUST-FIRE: perturbed-copy: half-hook — the merged image with the dead span's vsavj bytes restored must FAIL (STATE half; mode: --plant half-hook)
# FOLLOWS: tools/audit_perframe_hook.py tools/_minitoml.py build/manifest/donovan.toml tests/lib/decrypt_cache.sh tests/lib/controls.sh
#
# SHEET: none — a static comparison of program bytes; the picture is audit_don_row0c's capture sheets
#
# Usage: ROMDIR=... tests/test_perframe_hook.sh [MERGED_BUILD] [SOLO_BUILD]   static tier; seconds
# SHARES: none — its 6 control modes were write-traced apart (tests/controls_concurrent.txt, pilot:413e9b92) and its plain run always pooled (#370 A1, 14z-225)
set -u
REPO="$(cd "$(dirname "$0")/.." && pwd)"; cd "$REPO"
. "$REPO/tests/lib/controls.sh"; vs_ctl_mode "$0"
[ -n "${ROMDIR:-}" ] || { echo "SKIP: ROMDIR not set"; exit 0; }
python3 -c "import capstone" 2>/dev/null || { echo "SKIP: python capstone not installed"; exit 0; }
if [ -d "$ROMDIR" ]; then ROMDIR="$(cd "$ROMDIR" && pwd)"; fi
BUILD="${1:-build/m3b_merged34}"
SOLO="${2:-build/don_m30}"
case "$BUILD" in /*) ;; *) BUILD="$REPO/$BUILD" ;; esac
case "$SOLO" in /*) ;; *) SOLO="$REPO/$SOLO" ;; esac
for b in "$BUILD" "$SOLO"; do
    [ -f "$b/verify_op.bin" ] || { echo "FAIL: test_perframe_hook (no $b/verify_op.bin)"; exit 1; }
done
W="$(mktemp -d)" || { echo "FAIL: test_perframe_hook — mktemp -d failed (W)"; exit 2; }; trap 'rm -rf "$W"' EXIT; trap 'exit 130' INT; trap 'exit 143' TERM
. "$REPO/tests/lib/decrypt_cache.sh"
decrypt_view vsavj "$W/vj_op.bin" "$W/vj_data.bin" || { echo "FAIL: test_perframe_hook (no vsavj view)"; exit 1; }
decrypt_view vsav2 "$W/v2_op.bin" "$W/v2_data.bin" || { echo "FAIL: test_perframe_hook (no vsav2 view)"; exit 1; }
TOOL="python3 tools/audit_perframe_hook.py"
REF="$W/vj_op.bin $W/v2_op.bin $W/v2_data.bin"
PLANTS="unmapped-escape insn-flip table-flip record-flip row-default half-hook"
fail=0; ok() { echo "  ok    $*"; }; bad() { echo "  FAIL  $*"; fail=1; }

# hooked_ok <output> <rc>: the state is hooked AND every check passed
hooked_ok() { [ "$2" -eq 0 ] && echo "$1" | grep -q '^STATE hooked' && echo "$1" | grep -q '^VERDICT OK'; }

for c in $PLANTS; do
    if vs_ctl_is "$c"; then
        echo "== MODE $c: the merged image with the $c plant"
        out="$($TOOL "$BUILD/verify_op.bin" $REF --plant "$c" 2>&1)"; rc=$?
        echo "$out" | grep -E '^(STATE|VERDICT|FAIL)' | sed 's/^/        /'
        hooked_ok "$out" "$rc" && vs_ctl_left_green "$c" "FAIL: the $c plant still read hooked and OK"
        echo "FAIL (mode): as required — the $c plant was caught"; exit 1
    fi
done

echo "== 1. the port on each build"
for b in "$BUILD" "$SOLO"; do
    out="$($TOOL "$b/verify_op.bin" $REF 2>&1)"; rc=$?
    echo "$out" | grep -E '^(#|STATE|VERDICT|FAIL)' | sed 's/^/        /'
    if hooked_ok "$out" "$rc"; then ok "${b#$REPO/}: STATE hooked, VERDICT OK"
    else bad "${b#$REPO/}: not hooked-and-OK (rc $rc)"; fi
done

echo "== 2. controls: each must fire in-gate (the modes above prove them as modes)"
for c in $PLANTS; do
    out="$($TOOL "$BUILD/verify_op.bin" $REF --plant "$c" 2>&1)"; rc=$?
    v="$(echo "$out" | grep -E '^(STATE half|FAIL|VERDICT)' | head -1)"
    if ! hooked_ok "$out" "$rc" && [ "$rc" -ne 0 ]; then vs_ctl_fired "$c" "rc $rc: $v"
    else vs_ctl_dead "$c" "the $c plant left the image hooked and OK"; fail=1; fi
done

[ "$fail" -eq 0 ] && echo "PASS" || echo "FAIL"
exit "$fail"
