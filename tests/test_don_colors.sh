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
# 14z-132: ABSOLUTE. Gates `cd` into work dirs and then compose paths that
# still contain $ROMDIR (e.g. MAME_ROMPATH="...;$ROMDIR"); a RELATIVE value —
# which is how the runners invoke everything (ROMDIR=../ROMS) — then resolves
# against the WORK dir and silently finds no reference members. Kept as a
# VARIABLE (forks set their own); only made absolute, and only if it exists,
# so a gate that means to SKIP on a missing ROMDIR still does.
if [ -d "$ROMDIR" ]; then ROMDIR="$(cd "$ROMDIR" && pwd)"; fi
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
# MIR row 0x0f RE-FROZEN 14z-99: the THIRD copy of the stale row-0x0F
# literal (the 14z-91 fixture-override deletion traded vs2's red statue
# ramp for vsavj's own row content, recorded then as an accepted
# cosmetic; test_don_accent carried two more copies, all three surfaced
# by the window battery). Measured identical on the pre- and post-window
# stock twins, so it is the 14z-91 state, not a window change.
MIR = {  # native vs2 Donovan-mirror rows (frozen 14z-21; replay 43 oracle)
    0x0a: 'f000fffffeb8fd97fb76f853f530fff4fec4f46bff00fc00fa00f700f500f000',
    0x0b: 'fd00ff40ff70ff90ffb0ffd0fff0fffafffff0aff0cff0effafffdfff111f001',
    0x0c: 'f000fffffdfffcdff9adf87af635ffeafdb8fa86f864f653fbcef88bfe00f002',
    0x0d: 'f000fffffcdff9adf87af635ff00ffdbfeb9fd87fa66f744ff89fd68fb46f003',
    0x0e: 'fd00fffffdddfbbbf33bf54ff65ff76ff216f111f112f113f115f216f228f000',
    0x0f: 'fd00fffffdddfbbbf33bf54ff65ff76ffd00f111f112f113f115f216f228f001',
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
# 14z-31: the accent march must be COLOR-AWARE — kick-color row 0x0C
# steady across frames (the round-44 grey blink = punch-color accent
# slots cycling against alt bases; fixed by the accent_color_aware
# thunks reading the object's cached block ptr).
d0 = open(os.path.join(work, 'alt', 'dump_2440_90c000.bin'), 'rb').read()
d1 = open(os.path.join(work, 'alt', 'dump_2450_90c000.bin'), 'rb').read()
assert d0[0x180:0x1A0] == d1[0x180:0x1A0] == bytes.fromhex(ALT[0x0c]), \
    "kick-color row 0x0C blinks or drifted (accent not color-aware)"
print("  ok: kick-color sword row steady (color-aware accent)")
check('mirror', MIR, 'Donovan mirror')
EOF
# ── 4. select POST-CONFIRM accent lock (14z-47; the 14z-32 blink).
#      Replay 58 confirms with HK; rows 0x0A-0x0D must be steady
#      across consecutive frames AND equal the frozen native vs2 set
#      (select R,R + confirm 6, f1500).
mkdir -p "$WORK/pc"
DUMPS="1500:90c140-90c1c0;1501:90c140-90c1c0;1502:90c140-90c1c0;1500:90c280-90c2a0;1500:708000-708500" \
    REPLAY="$REPO/tests/replays/58_don_select_confirm.rpl" \
    CHECKSUM_OUT="$WORK/pc/c.log" MAME_SANDBOX="$WORK/pc" \
    MAME_ROMPATH="$RPDIR;$ROMDIR" tools/run_mame.sh vsavj \
    -autoboot_script "$REPO/tests/lua/replay.lua" > /dev/null 2>&1
python3 - "$WORK/pc" <<'EOF2'
import sys, os
work = sys.argv[1]
FROZEN = "f000fcecffdafea8fd99fb78f967f856f605f666f888faaafd87ffa8fffff00af320fdddfa98f876f765f654f543fff1ffb1fd81fc62ff11f37ff13cf128f00bf333ffcaffa7fd84fa52fffffdddfaaaf777faeff5aef66cf549fc36f2b6f00cf222fff3ffb5ff85ff43fb32f821f9def6abf589f367f245fdddfaaaf777f00d"
dumps = [open(os.path.join(work, f'dump_{f}_90c140.bin'),'rb').read()[:0x80] for f in (1500,1501,1502)]
assert dumps[0] == dumps[1] == dumps[2], (
    "post-confirm accent rows not steady (the 14z-32 blink is back; "
    "check the accent_color_aware owner-link fallback)")
assert dumps[0].hex() == FROZEN, (
    "post-confirm accent rows diverge from the frozen native vs2 set "
    "(punch-color fallback? check accent_color_aware venue branch)")
print("  ok: select post-confirm accents steady + native-locked (rows 0x0A-0x0D)")
# 14z-49 select-wheel medallion lock. Donovan's cell = JEDAH's old
# wheel cell (code 0xB526 attr 0x1214 pal 14 at 236,57 — the cell the
# cursor ring centers on; measured, session 14z-49). Locks:
#   1. pal row 14 == the ported vs2 Donovan-icon row (src 0x3BAFDC,
#      live-verified equal to vs2's select row 05);
#   2. the wheel record entry intact (art replacement is build-time
#      byte-asserted; this locks the record + palette plumbing);
#   3. GALLON's big 3x3 cell (b4e3 attr 2207 at 264,64) untouched —
#      the first 14z-49 attempt wrongly retuned it; never again.
row14 = open(os.path.join(work, 'dump_1500_90c280.bin'), 'rb').read()[:0x20]
FROZEN14 = "fffffda8fc86fb75fa64f743f532f322facef78df458ffd6fb84fc22f922f005"
assert row14.hex() == FROZEN14, (
    f"select pal row 14 (Donovan medallion) drifted:\n  got {row14.hex()}\n  exp {FROZEN14}")
d = open(os.path.join(work, 'dump_1500_708000.bin'), 'rb').read()
ents = set()
for i in range(0, len(d) - 8, 8):
    x = int.from_bytes(d[i:i+2], 'big') & 0x3FF
    y = int.from_bytes(d[i+2:i+4], 'big') & 0x3FF
    code = int.from_bytes(d[i+4:i+6], 'big')
    attr = int.from_bytes(d[i+6:i+8], 'big')
    ents.add((x, y, code, attr))
assert (236, 57, 0xB526, 0x1214) in ents, \
    "Donovan medallion cell (b526 3x2 pal 14 at 236,57) missing from wheel record"
assert (264, 64, 0xB4E3, 0x2207) in ents, \
    "Gallon's 3x3 cell (b4e3 2207 at 264,64) altered — wrong-cell retune is back"
print("  ok: select medallion native-locked (row 14 + wheel record + Gallon intact)")
EOF2
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
