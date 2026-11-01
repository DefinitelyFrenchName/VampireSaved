#!/bin/sh
# test_dead_span.sh — THE SIX BYTES #294'S PORT IS PLACED ON ARE PROVEN DEAD IN PRISTINE vsavj (14z-216, GitHub #294).
#
# WHAT: PRG:0x024024-0x024029 of pristine vsavj — a `moveq #$4b,d0 / bra.w $27ec0` tail wedged between rows 0x20 and
#   0x21 of the victim reaction dispatch (table PRG:0x02385C), after row 0x20's own `bra.w` — can be neither executed
#   nor read, so a jump placed there for #294 (the per-frame palette table PRG:0x02ADEC's row 0x13, whose 16-bit word
#   reaches only PRG:0x022DEC-0x032DEB) touches nothing legacy content reaches. Its twins in vsav2 (PRG:0x022C20) and
#   vhunt2 (PRG:0x022C4E) sit in the same place, after the same `bra.w` — the look of a leftover in all three builds —
#   but the tool does NOT prove them dead (vsav2: two data longs and a palette-offset table's op-view rows; vhunt2: a
#   base from data decoded as code; all over-approximations it cannot exclude), so they are not judged here.
# HOW: tools/audit_dead_span.py on the decrypted views (tests/lib/decrypt_cache.sh): no instruction decoded at ANY
#   even address of the code window names a span byte (A), no 32-bit value at any 2-aligned offset of either full
#   view equals one (C), no table row inside the jump-table extent gives one (T), and the span is FENCED by reached
#   code — an unconditional transfer ends exactly at its start and the byte after it is reached (L).
# EXPECTS: VERDICT DEAD for vsavj's span. A red names the reference (instruction, long or table row) or the
#   missing fence. Stated, not tested: an address formed at run time from no constant anywhere (the tool's header);
#   the runtime bound (build/agent216/rc294/dead/exec_bound.sh, 14z-216: 0 executions over the 64-replay legacy
#   corpus on MAME) is a separate, weaker instrument — the corpus never reaches the neighbouring rows 0x20/0x21 either.
#   What reaches the span on OUR build after the port is a different question, for the port's own gate.
#
# MUST-FIRE: perturbed-copy: plant-jsr — vsavj with a `jsr $24024.l` planted in memory at the top of the code window must be judged NOT DEAD (rule A; mode: the tool's --plant jsr)
# MUST-FIRE: perturbed-copy: plant-long — vsavj with the span start planted as a long near the end of the data view must be judged NOT DEAD (rule C; mode: --plant long)
# MUST-FIRE: perturbed-copy: plant-table — vsavj with a PC-indexed word table whose row 0 gives the span start, planted 0x200 bytes past it, must be judged NOT DEAD (rule T; mode: --plant table)
# MUST-FIRE: known-bad: live-span — the same idiom at PRG:0x024888-0x02488D, reached by FALL-THROUGH from PRG:0x024882, must be judged NOT DEAD (rule L: reached inside, no fence; mode: the gate run on that span)
# FOLLOWS: tools/audit_dead_span.py tests/lib/decrypt_cache.sh tests/lib/controls.sh
#
# SHEET: none — reads pristine reference images only; no leg of our build
#
# Usage: ROMDIR=... tests/test_dead_span.sh       static tier (decrypted views, no emulator); ~35 s on the MacBook
set -u
REPO="$(cd "$(dirname "$0")/.." && pwd)"; cd "$REPO"
. "$REPO/tests/lib/controls.sh"; vs_ctl_mode "$0"
[ -n "${ROMDIR:-}" ] || { echo "SKIP: ROMDIR not set"; exit 0; }
python3 -c "import capstone" 2>/dev/null || { echo "SKIP: python capstone not installed"; exit 0; }
W="$(mktemp -d)" || { echo "FAIL: test_dead_span — mktemp -d failed (W)"; exit 2; }; trap 'rm -rf "$W"' EXIT INT TERM
. "$REPO/tests/lib/decrypt_cache.sh"
decrypt_view vsavj "$W/vsavj_op.bin" "$W/vsavj_data.bin" || { echo "FAIL: test_dead_span (no vsavj view)"; exit 1; }
TOOL="python3 tools/audit_dead_span.py"
fail=0; ok() { echo "  ok    $*"; }; bad() { echo "  FAIL  $*"; fail=1; }
VJ="$W/vsavj_op.bin $W/vsavj_data.bin"

for c in plant-jsr plant-long plant-table; do
    if vs_ctl_is "$c"; then
        echo "== MODE $c: vsavj's span with a planted reference"
        $TOOL $VJ --span 024024-024029 --plant "${c#plant-}"; rc=$?
        [ "$rc" -eq 0 ] && vs_ctl_left_green "$c" "FAIL: the planted reference was not seen"
        echo "FAIL (mode): as required — the planted reference made the span NOT DEAD"; exit 1
    fi
done
if vs_ctl_is live-span; then
    echo "== MODE live-span: the gate's check run on the fall-through twin PRG:0x024888-0x02488D"
    $TOOL $VJ --span 024888-02488d; rc=$?
    [ "$rc" -eq 0 ] && vs_ctl_left_green live-span "FAIL: a span reached by fall-through was judged DEAD"
    echo "FAIL (mode): as required — the live span was judged NOT DEAD"; exit 1
fi

echo "== 1. the span"
out="$($TOOL $VJ --span 024024-024029 2>&1)"; rc=$?
echo "$out" | grep -E '^(#|REF|LIVE|FENCE|VERDICT)' | sed 's/^/        /'
if [ "$rc" -eq 0 ]; then ok "vsavj PRG:0x024024-0x024029 DEAD"; else bad "vsavj PRG:0x024024-0x024029 is not proven dead"; fi

echo "== 2. controls: each must fire in-gate (the modes above prove them as modes)"
for c in jsr long table; do
    out="$($TOOL $VJ --span 024024-024029 --plant "$c" 2>&1)"; rc=$?
    v="$(echo "$out" | grep '^VERDICT' | head -1)"
    if [ "$rc" -ne 0 ] && echo "$v" | grep -q 'NOT DEAD'; then vs_ctl_fired "plant-$c" "$v"
    else vs_ctl_dead "plant-$c" "the planted $c reference left the span DEAD ($v)"; fail=1; fi
done
out="$($TOOL $VJ --span 024888-02488d --expect live 2>&1)"; rc=$?
v="$(echo "$out" | grep '^VERDICT' | head -1)"
if [ "$rc" -eq 0 ] && echo "$v" | grep -q 'NOT DEAD'; then vs_ctl_fired live-span "PRG:0x024888-0x02488D: $v"
else vs_ctl_dead live-span "the fall-through twin was judged DEAD ($v)"; fail=1; fi

[ "$fail" -eq 0 ] && echo "PASS" || echo "FAIL"
exit "$fail"
