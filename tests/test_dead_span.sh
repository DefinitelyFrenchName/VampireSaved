#!/bin/sh
# test_dead_span.sh — THE SIX-BYTE SPANS #294'S AND #363'S PORTS ARE PLACED ON ARE PROVEN DEAD IN PRISTINE vsavj
# (14z-216, GitHub #294; 14z-221c, GitHub #363).
#
# WHAT: PRG:0x024024-0x024029 of pristine vsavj — a `moveq #$4b,d0 / bra.w $27ec0` tail wedged between rows 0x20 and
#   0x21 of the victim reaction dispatch (table PRG:0x02385C), after row 0x20's own `bra.w` — can be neither executed
#   nor read, so a jump placed there for #294 (the per-frame palette table PRG:0x02ADEC's row 0x13, whose 16-bit word
#   reaches only PRG:0x022DEC-0x032DEB) touches nothing legacy content reaches. Its twins in vsav2 (PRG:0x022C20) and
#   vhunt2 (PRG:0x022C4E) sit in the same place, after the same `bra.w` — the look of a leftover in all three builds —
#   but the tool does NOT prove them dead (vsav2: two data longs and a palette-offset table's op-view rows; vhunt2: a
#   base from data decoded as code; all over-approximations it cannot exclude), so they are not judged here.
#   AND (14z-221c, #363) PRG:0x029CBA-0x029CBF — `move.b #4,$3B5(a6)`, an unreferenced entry fragment whose next
#   instruction `bra.b 0x029C74` joins the routine above it, after that routine's `jmp $73f6a.l` — where #363 puts the
#   jump to its freeze handler (the victim reaction table PRG:0x02385C's row 0x4F, a 16-bit word reaching only
#   PRG:0x01B85C-0x02B85B). Only the six bytes of the one instruction are claimed; the `bra.b` after it stays.
# HOW: tools/audit_dead_span.py on the decrypted views (tests/lib/decrypt_cache.sh): no instruction decoded at ANY
#   even address of the code window names a span byte (A), no 32-bit value at any 2-aligned offset of either full
#   view equals one (C), no table row inside the jump-table extent gives one (T), and the span is FENCED by reached
#   code — an unconditional transfer ends exactly at its start and the byte after it is reached (L); and since 14z-221c
#   no PC-indexed DATA read can land in it (D: every `(d8,PC,Xn)` base within 0x100 of a span byte, on either side, is a
#   reference; R the same for a register-loaded base; addresses read as the 68000's 24-bit bus does: the tool's header).
#   RULE D CHANGED #294'S PROOF: the byte table PRG:0x023F84, read by `move.b $23f84(pc,d0.w),d0` at PRG:0x023F68
#   with d0 the victim's +0x56 (unmasked, after `moveq #0`), reaches PRG:0x024024 at index 0xA0. The pre-221c tool had
#   no rule for a data read through a PC-indexed base. That base is ACCEPTED here at its one reader (--allow-pcidx
#   23f84@23f68) on its corpus bound, not on a static proof: tests/audit_dead_span_exec.sh counts executions of
#   PRG:0x023F68 over the 64-replay legacy corpus (14z-221c); with rules R and T two more references are accepted at
#   their sites, and #363's span carries three bases above it, accepted the same way (ACC294 and ACC363 below).
# EXPECTS: VERDICT DEAD for both spans on vsavj, each accepted reference named at exactly its sites. A red names the reference (instruction, long or table row) or the
#   missing fence. Stated, not tested: an address formed at run time from no constant anywhere (the tool's header);
#   the runtime bound (build/agent216/rc294/dead/exec_bound.sh, 14z-216: 0 executions over the 64-replay legacy
#   corpus on MAME) is a separate, weaker instrument — the corpus never reaches the neighbouring rows 0x20/0x21 either.
#   What reaches the span on OUR build after the port is a different question, for the port's own gate.
#
# MUST-FIRE: perturbed-copy: plant-jsr — vsavj with a `jsr $24024.l` planted in memory at the top of the code window must be judged NOT DEAD (rule A; mode: the tool's --plant jsr)
# MUST-FIRE: perturbed-copy: plant-long — vsavj with the span start planted as a long near the end of the data view must be judged NOT DEAD (rule C; mode: --plant long)
# MUST-FIRE: perturbed-copy: plant-table — vsavj with a PC-indexed word table whose row 0 gives the span start, planted 0x200 bytes past it, must be judged NOT DEAD (rule T; mode: --plant table)
# MUST-FIRE: perturbed-copy: plant-lea — vsavj with a `lea <span start - 0x10>.l,a0` planted in memory where the jsr plant goes must be judged NOT DEAD by rule R (14z-221c; mode: --plant lea)
# MUST-FIRE: known-bad: byte-table — PRG:0x0236CE-0x0236D3, entries 10-15 of the byte table PRG:0x0236C4 read by `move.b $236c4(pc,d0.w),d0` after `andi.w #$f,d0` at PRG:0x023694, which passes rules A, C, T and L (its data decodes as a reached `bra.w` that fences it — the pre-221c tool judged it DEAD, 14z-221c), must be judged NOT DEAD (rule D; in-gate; mode: the gate run on that span)
# MUST-FIRE: known-bad: live-span — the same idiom at PRG:0x024888-0x02488D, reached by FALL-THROUGH from PRG:0x024882, must be judged NOT DEAD (rule L: reached inside, no fence; mode: the gate run on that span)
# FOLLOWS: tools/audit_dead_span.py tests/lib/decrypt_cache.sh tests/lib/controls.sh tests/audit_dead_span_exec.sh
#
# SHEET: none — reads pristine reference images only; no leg of our build
#
# Usage: ROMDIR=... tests/test_dead_span.sh       static tier (decrypted views, no emulator); ~35 s on the MacBook
set -u
REPO="$(cd "$(dirname "$0")/.." && pwd)"; cd "$REPO"
. "$REPO/tests/lib/controls.sh"; vs_ctl_mode "$0"
[ -n "${ROMDIR:-}" ] || { echo "SKIP: ROMDIR not set"; exit 0; }
python3 -c "import capstone" 2>/dev/null || { echo "SKIP: python capstone not installed"; exit 0; }
W="$(mktemp -d)" || { echo "FAIL: test_dead_span — mktemp -d failed (W)"; exit 2; }; trap 'rm -rf "$W"' EXIT; trap 'exit 130' INT; trap 'exit 143' TERM
. "$REPO/tests/lib/decrypt_cache.sh"
decrypt_view vsavj "$W/vsavj_op.bin" "$W/vsavj_data.bin" || { echo "FAIL: test_dead_span (no vsavj view)"; exit 1; }
TOOL="python3 tools/audit_dead_span.py"
# #294's span's ACCEPTED references (14z-221c; each checked below by its listed sites, never by count alone):
#   D  the byte table PRG:0x023F84, read only at PRG:0x023F68 (0 executions over the 64-replay corpus,
#      tests/audit_dead_span_exec.sh);
#   R  the value 0x00024000 loaded at PRG:0x0433B8 (`move.l #$24000,d1`, then `neg.l d1`) and PRG:0x077516
#      (`move.l #$24000,$40(a6)` beside `move.l #$10000,$44(a6)`): 16.16 speeds, not addresses;
#   T  row 0x8A of PRG:0x02A646, an 8-byte record loaded into a3 by `lea $2a646(pc),a3` at PRG:0x029DFA in a run of
#      such leas eight bytes apart (PRG:0x029DEA-0x029E0A, each followed by `bra.w 0x029F4A`): its words read as offsets
#      give odd and far targets (rows 1 and 2: PRG:0x030A99, PRG:0x02F429), so row 0x8A's PRG:0x024029 is not a jump row.
#      Seen only since 14z-221c fixed the tool's lea/pea match (capstone names them lea.l/pea.l).
ACC294="--allow-pcidx 23f84@23f68 --allow-pcidx 24000@433b8/77516 --allow-table 02A646:8A@29dfa"
# #363's span's ACCEPTED references, all three bases ABOVE it, seen since rules D and R read 0x100 on BOTH sides of a
# base (14z-221c, rule-checker run 2026-11-06-1664: an index or displacement may be negative):
#   R  PRG:0x029CC2, `lea $29cc2(pc),a1` at PRG:0x029944, read by `move.w (a1,d0.w),d0` after `andi.w #$3e,d0`
#      (PRG:0x029940): its index is 0..0x3E, never negative, so it never reaches below the base;
#   R  PRG:0x029D02, the same idiom at PRG:0x029966 (`andi.w #$3e,d0` at PRG:0x029962);
#   D  PRG:0x029D92 at PRG:0x029D82, `and.w $29d92(pc,d3.l),d5`: the every-even-address decode of DATA (the word tables
#      above), not an instruction the recursive descent reaches (rule L's reached set, measured 14z-221c).
#   Each rests on reading the code, not on a runtime bound; each is accepted only at its named site.
ACC363="--allow-pcidx 29cc2@29944 --allow-pcidx 29d02@29966 --allow-pcidx 29d92@29d82"
fail=0; ok() { echo "  ok    $*"; }; bad() { echo "  FAIL  $*"; fail=1; }
VJ="$W/vsavj_op.bin $W/vsavj_data.bin"

for c in plant-jsr plant-long plant-table plant-lea; do
    if vs_ctl_is "$c"; then
        echo "== MODE $c: vsavj's span with a planted reference"
        # rule D's accepted base is passed too (14z-221c, rule-checker run 2026-11-05-1651 Q4), so the plant's own rule decides
        $TOOL $VJ --span 024024-024029 $ACC294 --plant "${c#plant-}"; rc=$?
        [ "$rc" -eq 0 ] && vs_ctl_left_green "$c" "FAIL: the planted reference was not seen"
        echo "FAIL (mode): as required — the planted reference made the span NOT DEAD"; exit 1
    fi
done
if vs_ctl_is byte-table; then
    echo "== MODE byte-table: the gate's check run on the byte-table tail PRG:0x0236CE-0x0236D3"
    $TOOL $VJ --span 0236ce-0236d3; rc=$?
    [ "$rc" -eq 0 ] && vs_ctl_left_green byte-table "FAIL: a PC-indexed byte table's tail was judged DEAD"
    echo "FAIL (mode): as required — the byte table's tail was judged NOT DEAD"; exit 1
fi
if vs_ctl_is live-span; then
    echo "== MODE live-span: the gate's check run on the fall-through twin PRG:0x024888-0x02488D"
    $TOOL $VJ --span 024888-02488d; rc=$?
    [ "$rc" -eq 0 ] && vs_ctl_left_green live-span "FAIL: a span reached by fall-through was judged DEAD"
    echo "FAIL (mode): as required — the live span was judged NOT DEAD"; exit 1
fi

echo "== 1. the spans"
# #294's: its three accepted references (the header), each checked by its sites below
out="$($TOOL $VJ --span 024024-024029 $ACC294 2>&1)"; rc=$?
echo "$out" | grep -E '^(#|REF|LIVE|FENCE|VERDICT)' | sed 's/^/        /'
if [ "$rc" -eq 0 ]; then ok "vsavj PRG:0x024024-0x024029 DEAD (its three references accepted at their named sites, the header)"; else bad "vsavj PRG:0x024024-0x024029 is not proven dead"; fi
# the acceptance holds only while PRG:0x023F68 is the base's ONLY reader — the one site tests/audit_dead_span_exec.sh
# counts (14z-221c, rule-checker run 2026-11-05-1653): a second instruction reading through PRG:0x023F84 fails here
st="$(echo "$out" | grep '^ALLOW D base PRG:0x023F84' | sed 's/.*every site reading through it: //')"
if [ "$st" = "PRG:0x023F68" ]; then ok "the accepted base PRG:0x023F84 has one reader, PRG:0x023F68, the site its runtime bound counts"
else bad "the accepted base PRG:0x023F84's readers are '$st', not exactly PRG:0x023F68 (the site audit_dead_span_exec counts)"; fi
st="$(echo "$out" | grep '^ALLOW R base PRG:0x024000' | sed 's/.*every site loading it: //')"
if [ "$st" = "PRG:0x0433B8, PRG:0x077516" ]; then ok "the accepted value 0x00024000 is loaded at PRG:0x0433B8 and PRG:0x077516 only, the two speeds read above"
else bad "the accepted value 0x00024000's sites are '$st', not exactly PRG:0x0433B8, PRG:0x077516"; fi
st="$(echo "$out" | grep '^ALLOW T table PRG:0x02A646' | head -1)"
case "$st" in *"site PRG:0x029DFA) row 0x8A -> PRG:0x024029"*) ok "the accepted row: PRG:0x02A646 row 0x8A from the lea at PRG:0x029DFA, the odd target PRG:0x024029";;
    *) bad "the accepted row PRG:0x02A646:0x8A is not the one named (site PRG:0x029DFA, target PRG:0x024029): '$st'";; esac
out="$($TOOL $VJ --span 029cba-029cbf $ACC363 2>&1)"; rc=$?
echo "$out" | grep -E '^(REF|LIVE|FENCE|VERDICT)' | sed 's/^/        /'
if [ "$rc" -eq 0 ]; then ok "vsavj PRG:0x029CBA-0x029CBF DEAD (#363), its three bases above it accepted at their sites"; else bad "vsavj PRG:0x029CBA-0x029CBF is not proven dead"; fi
for x in "R:029CC2:PRG:0x029944" "R:029D02:PRG:0x029966" "D:029D92:PRG:0x029D82"; do
    ru="${x%%:*}"; r2="${x#*:}"; b="${r2%%:*}"; want="${r2#*:}"
    st="$(echo "$out" | grep "^ALLOW $ru base PRG:0x$b" | sed 's/.*every site [a-z ]*it: //')"
    if [ "$st" = "$want" ]; then ok "#363's accepted base PRG:0x$b (rule $ru) is named at $want only"
    else bad "#363's accepted base PRG:0x$b (rule $ru): sites '$st', not exactly $want"; fi
done

echo "== 2. controls: each must fire in-gate (the modes above prove them as modes)"
# Each control must fail the span by ITS OWN rule (14z-221c, rule-checker run 2026-11-05-1651 Q4): with rule D, a
# bare "NOT DEAD" on #294's span would fire through the byte table PRG:0x023F84 whether or not rule A, C or T works,
# so the plants run with that base accepted, as section 1 does, and each needs its rule's count non-zero.
for c in jsr:A long:C table:T lea:R; do
    pl="${c%%:*}"; ru="${c#*:}"
    out="$($TOOL $VJ --span 024024-024029 $ACC294 --plant "$pl" 2>&1)"; rc=$?
    v="$(echo "$out" | grep '^VERDICT' | head -1)"
    if [ "$rc" -ne 0 ] && echo "$v" | grep -q 'NOT DEAD' && echo "$v" | grep -qE " $ru [1-9]"; then vs_ctl_fired "plant-$pl" "$v"
    else vs_ctl_dead "plant-$pl" "the planted $pl reference did not fail the span by rule $ru ($v)"; fail=1; fi
done
out="$($TOOL $VJ --span 0236ce-0236d3 --expect live 2>&1)"; rc=$?
v="$(echo "$out" | grep '^VERDICT' | head -1)"
if [ "$rc" -eq 0 ] && echo "$out" | grep -q '^REF D' && echo "$v" | grep -q 'NOT DEAD'; then vs_ctl_fired byte-table "PRG:0x0236CE-0x0236D3: $v"
else vs_ctl_dead byte-table "the byte table's tail was not judged NOT DEAD by rule D ($v)"; fail=1; fi
out="$($TOOL $VJ --span 024888-02488d --expect live 2>&1)"; rc=$?
v="$(echo "$out" | grep '^VERDICT' | head -1)"
# rule L's own evidence (a reached instruction inside, or no fence), not rule D's references to the same bytes
if [ "$rc" -eq 0 ] && echo "$v" | grep -q 'NOT DEAD' && echo "$v" | grep -qE 'live inside [1-9]|fenced no'; then vs_ctl_fired live-span "PRG:0x024888-0x02488D: $v"
else vs_ctl_dead live-span "the fall-through twin was judged DEAD ($v)"; fail=1; fi

[ "$fail" -eq 0 ] && echo "PASS" || echo "FAIL"
exit "$fail"
