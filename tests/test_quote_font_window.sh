#!/usr/bin/env bash
# test_quote_font_window.sh — the win-quote glyph font WHERE THE EMITTER DRAWS IT, and the
# tenant blocks' glyph cost against it (14z-189, GitHub #123). ci_static: ROMDIR only.
#
# WHAT: the system-text emitter's font base and bank are immediates (vsavj 0x3800 / vs2 0x4200,
#   both bank 0x2000), so a quote code draws tile 0x10000 + base + (code & 0xFFF); at those
#   bases the three vs2 tenant blocks' 331 codes need only 39 new glyphs (0xB13-0xB3B), all at
#   codes whose vsavj tile is blank — not the ~330 the 14z-116 bank-0 comparison reported.
# HOW: static over the decrypted opcode/data views and the reference gfx (ROMDIR only), via
#   tools/audit_quote_font_window.py, which READS the bases from the opcode views.
# EXPECTS: the emitter rows, the window's blank count and the census as frozen below; the
#   control (vs2's base immediate moved) changes the census and fails the run.
#
# MUST-FIRE: perturbed-copy: emitter-base — a copy of vs2's opcode view with both emitter base immediates moved from 0x4200 to 0x4300 must change the census (the tool derives the base from the image, so a gate that only echoed constants would not notice)
#
# WHY. tools/audit_quote_font.py (14z-116) compared every code at tile 0x3800 + code, gfx
# bank 0, in both games; that window is character art in both, so its "326 of 327 codes draw a
# different glyph" compared art against art. Measured 14z-189 on merged-m22 (replay 61, the
# tenant win-quote screen): the quote's OBJ entries carry y = 0x20b0 (bank 1) and tiles
# 0x13ee5..., written by PC 0x01BABE inside the emitter at 0x01BA6A — whose y bank is the
# immediate `ori.w #$2000,d1` (0x01BAA8 / 0x01BAE4), not the object's +0x18 (poking the text
# object's +0x18 to 0x3000 changed 0 px). docs/game/engine_internals.md "THE GLYPHS ARE THE
# REAL BLOCKER" carries the correction.
#
# Usage: ROMDIR=... tests/test_quote_font_window.sh
set -eu
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
ROMDIR="${ROMDIR:?set ROMDIR}"
if [ -d "$ROMDIR" ]; then ROMDIR="$(cd "$ROMDIR" && pwd)"; fi
[ -f "$ROMDIR/vsav.zip" ] && [ -f "$ROMDIR/vsav2.zip" ] || { echo "SKIP: no vsav.zip/vsav2.zip in ROMDIR"; exit 0; }
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

# The control image: vs2's opcode view with both emitter base immediates moved.
python3 - "$W/v2_op.bin" "$W/v2_op_bad.bin" <<'EOF'
import sys
d = bytearray(open(sys.argv[1], 'rb').read()); pat = bytes.fromhex("806e001a341806424200"); n = 0
a = d.find(pat)
while a >= 0:
    d[a + 8:a + 10] = (0x4300).to_bytes(2, 'big'); n += 1; a = d.find(pat, a + 1)
assert n == 2, n
open(sys.argv[2], 'wb').write(bytes(d))
EOF
V2OP="$W/v2_op.bin"
vs_ctl_is emitter-base && V2OP="$W/v2_op_bad.bin"

run() { python3 tools/audit_quote_font_window.py "$W/vj_op.bin" "$W/vj_data.bin" "$1" "$W/v2_data.bin" "$ROMDIR" 2>/dev/null; }
run "$V2OP" > "$W/out.txt" || { note "  FAIL: the audit tool errored"; fail=1; }
cat "$W/out.txt" | grep -v '^#' | sed 's/^/    /'
row() { grep "^$1" "$W/out.txt" | tr '\n' ';' | sed 's/;$//'; }

note "1. the emitter's font base and bank, read from each opcode view"
chk "vsavj emitter" "EMITTER vsavj site 0x01bab4 base 0x3800 bank 0x2000;EMITTER vsavj site 0x01baf0 base 0x3800 bank 0x2000" "$(row 'EMITTER vsavj')"
chk "vs2 emitter (bases)" "base 0x4200 bank 0x2000;base 0x4200 bank 0x2000" \
    "$(grep '^EMITTER vsav2' "$W/out.txt" | sed 's/.* base/base/' | tr '\n' ';' | sed 's/;$//')"
note "2. vsavj's real font window"
chk "window blank count" "WINDOW vsavj tiles 0x13800-0x147ff blank 403/4096" "$(row WINDOW)"
note "3. the tenant blocks' glyph census at each game's own base"
chk "census" "CENSUS codes 331 SAME 289 ELSEWHERE 1 ABSENT 39 VS2-BLANK 2" "$(row 'CENSUS codes')"
chk "per tenant" "CENSUS tenant 0x10 codes 146 absent 21 absent-uses 34;CENSUS tenant 0x11 codes 145 absent 10 absent-uses 12;CENSUS tenant 0x13 codes 129 absent 8 absent-uses 8" "$(row 'CENSUS tenant')"
chk "absent block" "ABSENT 0xb13-0xb3b n=39" "$(row 'ABSENT ')"
chk "absent at blank slots" "ABSENT-AT-BLANK-SLOT 39/39 (vsavj's tile at the same code is blank)" "$(row 'ABSENT-AT')"

note "4. verdict control (must fire)"
if [ -z "${VS_CTL:-}" ]; then
    run "$W/v2_op_bad.bin" > "$W/bad.txt" || true
    if grep -q '^CENSUS codes 331 SAME 289 ' "$W/bad.txt"; then
        vs_ctl_dead emitter-base "the census did not move with vs2's base immediate"; fail=1
    else
        vs_ctl_fired emitter-base "$(grep '^CENSUS codes' "$W/bad.txt")"
    fi
fi

if [ "$fail" -eq 0 ]; then note "PASS test_quote_font_window"; else note "FAIL test_quote_font_window"; exit 1; fi
