#!/bin/sh
# test_don_colors.sh — Donovan color-set gate (session 14z-21).
#
# Locks the round-36-queue "alt-color Donovan" item, resolved NO-BUG:
# the kick-color set is a fixed +0x180 offset INSIDE the char sprite
# block (ported whole, len 0x500), and the mirror-match alternate is
# composed by the shared engine from the same block — table B
# (0x38C1D8) is never consulted on Donovan's paths. Both were verified
# byte-identical to native vs2 (dumps, session 14z-21); this gate
# freezes those native-derived rows so palette/table work can't
# silently regress either path.
#
#   1. replay 41 (kick-button pick): P1 rows 0x0A-0x0D == frozen
#      native alt set.
#   2. replay 42 (Donovan mirror, P2 path U,U,U web-walked): P1 rows
#      0x0A-0x0F + P2 rows 0x10-0x13 == frozen native mirror rows
#      (vs2 ground truth via replay 43 on vsav2).
#
# Usage: ROMDIR=... tests/test_don_colors.sh [rompath_dir]
set -eu
ROMDIR="${ROMDIR:?set ROMDIR}"
REPO="$(cd "$(dirname "$0")/.." && pwd)"
RPDIR="${1:-$REPO/build/donovan6/rompath}"
[ -d "$RPDIR" ] || { echo "no build at $RPDIR"; exit 1; }
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
cd "$REPO"

run_case() { # $1=replay $2=outsub
    mkdir -p "$WORK/$2"
    DUMPS="2440:90c000-90c2ff;2450:90c000-90c2ff" \
        REPLAY="$REPO/tests/replays/$1" \
        CHECKSUM_OUT="$WORK/$2/c.log" MAME_SANDBOX="$WORK/$2" \
        MAME_ROMPATH="$RPDIR;$ROMDIR" tools/run_mame.sh vsavj \
        -autoboot_script "$REPO/tests/lua/replay.lua" > /dev/null 2>&1
}

run_case 41_don_altcolor_vsavj.rpl alt
run_case 42_don_mirror_vsavj.rpl mirror

python3 - "$WORK" <<'EOF'
import os, sys
work = sys.argv[1]
ALT = {  # native vs2 kick-color rows (frozen 14z-21)
    0x0a: 'f000fffffeb8fd97fb76f853f530fff0ffc0f008fc0ff90cf70af407f205f00c',
    0x0b: 'fd00ff40ff70ff90ffb0ffd0fff0fffafffff0aff0cff0effafffdfff111f00d',
    0x0c: 'f000ffffffefffcffc9cf758f536ffeafdb8fa86f864f653fdadf768fe00f00e',
    0x0d: 'f000fffffdbbfa77f844f600ff00ffdcfeb9fd87f754f432fd66fb44f922f00f',
}
MIR = {  # native vs2 Donovan-mirror rows (frozen 14z-21; replay 43 oracle)
    0x0a: 'f000fffffeb8fd97fb76f853f530fff4fec4f46bff00fc00fa00f700f500f000',
    0x0b: 'fd00ff40ff70ff90ffb0ffd0fff0fffafffff0aff0cff0effafffdfff111f001',
    0x0c: 'f000fffffdfffcdff9adf87af635ffeafdb8fa86f864f653fbcef88bfe00f002',
    0x0d: 'f000fffffcdff9adf87af635ff00ffdbfeb9fd87fa66f744ff89fd68fb46f003',
    0x0e: 'fd00fffffdddfbbbf33bf54ff65ff76ff216f111f112f113f115f216f228f000',
    0x0f: 'f01dfffffdddfbbbfa22fe32fe43fe54f500f000f100f200f400f500f611f001',
    0x10: 'f000fffffeb8fd97fb76f853f530ffc0ffa0fb45f45ff14cf00af007f005f004',
    0x11: 'fd00ff40ff70ff90ffb0ffd0fff0fffafffff0aff0cff0effafffdfff111f005',
    0x12: 'f000fffffceff9bef78df46af238ffeafdb8fa86f864f653f79ef56afe00f006',
    0x13: 'f000ffffffeaffd3fc80f860f04ffca8fa86f864f643f421f468f246f124f007',
}
def check(sub, rows, tag):
    p = os.path.join(work, sub, 'dump_2440_90c000.bin')
    assert os.path.exists(p), f"{tag}: no dump captured"
    d = open(p, 'rb').read()
    for row, exp in rows.items():
        got = d[row*0x20:(row+1)*0x20].hex()
        assert got == exp, f"{tag}: row {row:#04x} drifted:\n  got {got}\n  exp {exp}"
    print(f"  ok: {tag} rows match frozen native set ({len(rows)} rows)")
check('alt', ALT, 'kick-color pick')
check('mirror', MIR, 'Donovan mirror')
EOF
echo "PASS: Donovan color-set gate (alt + mirror native-locked)"

# ── 3. select-screen companion sword (session 14z-24) ────────────────
# The select venue's companion machinery (code_word + 4 thunks, STATE
# 14z-22/23/24) must produce the native composition: sword entries
# present, drawn BEHIND the body (all sword-band entries precede all
# body-band entries in the OBJ list — the owner +0x3C draw-behind flag,
# vs2-only instruction ported via the resolve thunks).
mkdir -p "$WORK/sel"
DUMPS="1290:708000-709000" REPLAY="$REPO/tests/replays/44_don_select_hover.rpl" \
    CHECKSUM_OUT="$WORK/sel/c.log" MAME_SANDBOX="$WORK/sel" \
    MAME_ROMPATH="$RPDIR;$ROMDIR" tools/run_mame.sh vsavj \
    -autoboot_script "$REPO/tests/lua/replay.lua" > /dev/null 2>&1

python3 - "$WORK/sel/dump_1290_708000.bin" <<'EOF2'
import sys
d = open(sys.argv[1],'rb').read()
seq = []
codes = set()
for i in range(0, len(d)-8, 8):
    code = int.from_bytes(d[i+4:i+6],'big')
    x = int.from_bytes(d[i:i+2],'big') & 0x3FF
    if x and x < 200:
        if 0xAD8F <= code <= 0xAD9F:
            seq.append('S'); codes.add(code)
        elif 0xBE00 <= code <= 0xBFFF or code == 0xEC5E:
            seq.append('b')
s = ''.join(seq)
assert s.count('S') >= 16, f"sword entries missing on select ({s.count('S')})"
assert 'bS' not in s, f"sword drawn OVER the body (order {s}) — +0x3C flag regressed"
FROZEN = {0xAD8F,0xAD90,0xAD91,0xAD92,0xAD93,0xAD98,0xAD99,0xAD9B,0xAD9C,0xAD9D}
assert codes == FROZEN, f"sword code set drifted: {sorted(hex(c) for c in codes)}"
print(f"  ok: select sword composed behind the body ({s.count('S')} entries, order {s[:12]}...)")
EOF2
echo "PASS: select companion sword gate"
