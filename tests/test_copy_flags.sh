#!/usr/bin/env bash
# test_copy_flags.sh — the copy-character flags and their arming counters in the three sets
# (14z-189, GitHub #128 Marionette scoping). ci_static: ROMDIR only.
#
# WHAT: vsavj has ONE copy flag (+0x3BC, Shadow; armed by 5 START presses, cmpi #5,$42 at
#   PRG:0x020CB0) and no +0x3C3 anywhere in code; vs2 and vh2 add a SECOND flag, +0x3C3, armed
#   by a second counter — exactly 7 START presses on the "?" cell (cmpi #7,$48: vs2
#   PRG:0x01F948, vh2 0x01F940) and set at confirm (vs2 0x01F6AC). That flag is Marionette's,
#   and its 28 vs2 code sites are what a port would have to carry.
# HOW: static over the decrypted opcode views (ROMDIR only), tools/audit_copy_flags.py — a
#   linear disassembly census of the code region; the counts are what that framing finds.
# EXPECTS: the per-game counts and sites below, and each game's ALTFORMS list — every textual match of the
#   OTHER ways to name the flags (a5-relative at the second block, $7c3/$bc3/$7bc/$bbc(aN), or the absolute
#   $FF87xx/$FF8Bxx): vsavj's one is an immediate (#$8bc3), vs2's a negative displacement, vh2's two branch
#   targets — none an access; and each game's WIDE list — every .b/.w/.l-suffixed or movep access at a NEIGHBOURING
#   displacement whose bytes cover a flag (bit ops on memory counted as byte-sized; a multi-register movem, an
#   absolute word/long, an index-register or computed address are NOT read): vsavj's one covers +0x7BC
#   through a7 (the stack pointer), none covers +0x3C3; the controls (a vsavj copy with one +0x3BC test turned into a +0x3C3 test, or
#   into an a5-relative +0x3C3 test) fail the run.
#
# MUST-FIRE: perturbed-copy: plant-3c3 — a copy of vsavj's opcode view with the copy itself (`tst.b $3bc(a0)` at PRG:0x009BB2) re-encoded as `tst.b $3c3(a0)` must change both vsavj counts (the census reads the image, so "vsavj has no Marionette flag" is a measurement, not a constant)
# MUST-FIRE: perturbed-copy: plant-alt-form — the same vsavj site re-encoded as `tst.b $7c3(a5)` (the field named a5-relative at the SECOND block, +0x400 from P1's — rule-checker run 2026-10-03-595 Q4) must appear in vsavj's ALTFORMS list, so "no +0x3C3 access" covers that form, not only `$3c3(aN)`
# MUST-FIRE: perturbed-copy: plant-wide — the same vsavj site re-encoded as `tst.w $3c2(a0)` (a WORD access at the neighbouring displacement, which covers +0x3C3 without naming it — rule-checker run 2026-10-03-599 Q4) must appear in vsavj's WIDE list tagged ->3c3, so the census is width-aware
#
# WHY. select_screen.md (14z-116) recorded that whatever arms Marionette in vs2 "is NOT this
# counter and has not been located". 14z-189 located it: vs2's select carries a second START
# counter helper (vs2 0x01F930, called beside the Shadow helper at 0x01F656) whose 7th press
# latches $49, and the confirm path turns $49 into +0x3C3. The scope of a port is in
# docs/game/atlas/select_screen.md "THE MARIONETTE FLAG".
#
# Usage: ROMDIR=... tests/test_copy_flags.sh
set -eu
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
ROMDIR="${ROMDIR:?set ROMDIR}"
if [ -d "$ROMDIR" ]; then ROMDIR="$(cd "$ROMDIR" && pwd)"; fi
python3 -c "import capstone" 2>/dev/null || { echo "SKIP: python3 capstone not available"; exit 0; }
. "$REPO/tests/lib/decrypt_cache.sh"   # GitHub #69: never re-decrypt directly
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT
fail=0
note() { printf '%s\n' "$*"; }
chk() { # label expected actual
    if [ "$2" = "$3" ]; then note "  ok   $1"; else note "  FAIL $1: expected [$2] got [$3]"; fail=1; fi
}
decrypt_view vsavj "$W/vj_op.bin"
decrypt_view vsav2 "$W/v2_op.bin"
decrypt_view vhunt2 "$W/vh_op.bin"
. "$REPO/tests/lib/controls.sh"; vs_ctl_mode "$0"

python3 - "$W/vj_op.bin" "$W/vj_op_bad.bin" <<'EOF'
import sys
d = bytearray(open(sys.argv[1], 'rb').read())
assert d[0x9BB2:0x9BB6] == bytes.fromhex("4a2803bc"), d[0x9BB2:0x9BB6].hex()
d[0x9BB2:0x9BB6] = bytes.fromhex("4a2803c3")
open(sys.argv[2], 'wb').write(bytes(d))
d[0x9BB2:0x9BB6] = bytes.fromhex("4a2d07c3")   # tst.b $7c3(a5)
open(sys.argv[2].replace("_bad", "_alt"), 'wb').write(bytes(d))
d[0x9BB2:0x9BB6] = bytes.fromhex("4a6803c2")   # tst.w $3c2(a0): covers +0x3C2..+0x3C3
open(sys.argv[2].replace("_bad", "_wide"), 'wb').write(bytes(d))
EOF
VJ="$W/vj_op.bin"
vs_ctl_is plant-3c3 && VJ="$W/vj_op_bad.bin"
vs_ctl_is plant-alt-form && VJ="$W/vj_op_alt.bin"
vs_ctl_is plant-wide && VJ="$W/vj_op_wide.bin"

T=tools/audit_copy_flags.py
python3 "$T" vsavj "$VJ" > "$W/vj.txt" || { note "  FAIL: tool errored (vsavj)"; fail=1; }
python3 "$T" vsav2 "$W/v2_op.bin" > "$W/v2.txt" || { note "  FAIL: tool errored (vsav2)"; fail=1; }
python3 "$T" vhunt2 "$W/vh_op.bin" > "$W/vh.txt" || { note "  FAIL: tool errored (vhunt2)"; fail=1; }
cat "$W/vj.txt" "$W/v2.txt" "$W/vh.txt" | grep -v '^#' | sed 's/^/    /'
got() { grep -v '^#' "$W/$1.txt" | tr '\n' ';' | sed 's/;$//'; }

note "1. vsavj: one copy flag (Shadow), one counter (5)"
chk "vsavj" 'SITES vsavj $3bc 19;SITES vsavj $3c3 0;ALTFORMS vsavj 00f566:addi.w#$8bc3,(a0);WIDE vsavj 0a7692:movep.l$7ba(a7),d1->3bc;ARM vsavj 020cb0:cmpi.b#$5,$42(a6);SET vsavj 020ab4:st.b$3bc(a6)' "$(got vj)"
note "2. vs2 / vh2: a second flag +0x3C3 (Marionette), armed by a second counter (7)"
chk "vsav2" 'SITES vsav2 $3bc 20;SITES vsav2 $3c3 28;ALTFORMS vsav2 0a3ea4:or.b-$bc3(a2),d7;WIDE vsav2 00550c:movep.ld0,$3b6(a6)->3bc 00552a:movep.ld0,$3b6(a6)->3bc 0a1650:move.l$3bb(a5),-(a1)->3bc;ARM vsav2 01f8d6:cmpi.b#$5,$42(a6) 01f948:cmpi.b#$7,$48(a6);SET vsav2 01f67e:st.b$3bc(a6) 01f6ac:st.b$3c3(a6)' "$(got v2)"
chk "vhunt2" 'SITES vhunt2 $3bc 21;SITES vhunt2 $3c3 31;ALTFORMS vhunt2 00879a:beq.b$87bc 0087ae:beq.b$87bc;WIDE vhunt2 005516:movep.ld0,$3b6(a6)->3bc 005534:movep.ld0,$3b6(a6)->3bc 0a9348:move.l$3c1(a3),-(a4)->3c3 0afd30:move.l-$6839(a4),$bc1(a1)->3c3;ARM vhunt2 01f8ce:cmpi.b#$5,$42(a6) 01f940:cmpi.b#$7,$48(a6);SET vhunt2 01f66a:st.b$3bc(a6) 01f698:st.b$3c3(a6)' "$(got vh)"

note "3. verdict control (must fire)"
if [ -z "${VS_CTL:-}" ]; then
    python3 "$T" vsavj "$W/vj_op_bad.bin" > "$W/bad.txt" || true
    if grep -q '^SITES vsavj \$3c3 0$' "$W/bad.txt"; then
        vs_ctl_dead plant-3c3 "the census did not see the planted +0x3C3 test"; fail=1
    else
        vs_ctl_fired plant-3c3 "$(grep '^SITES' "$W/bad.txt" | tr '\n' ' ')"
    fi
    python3 "$T" vsavj "$W/vj_op_alt.bin" > "$W/alt.txt" || true
    if grep -q '^ALTFORMS vsavj .*009bb2:tst.b\$7c3(a5)' "$W/alt.txt"; then
        vs_ctl_fired plant-alt-form "$(grep '^ALTFORMS' "$W/alt.txt")"
    else
        vs_ctl_dead plant-alt-form "the census did not list the planted a5-relative +0x3C3 test"; fail=1
    fi
    python3 "$T" vsavj "$W/vj_op_wide.bin" > "$W/wide.txt" || true
    if grep -q '^WIDE vsavj .*009bb2:tst.w\$3c2(a0)->3c3' "$W/wide.txt"; then
        vs_ctl_fired plant-wide "$(grep '^WIDE' "$W/wide.txt")"
    else
        vs_ctl_dead plant-wide "the census did not list the planted word access covering +0x3C3"; fail=1
    fi
fi

if [ "$fail" -eq 0 ]; then note "PASS test_copy_flags"; else note "FAIL test_copy_flags"; exit 1; fi
