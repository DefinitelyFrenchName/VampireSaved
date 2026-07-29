#!/bin/sh
# test_gfx_menus.sh — pixel-level menu/UI regression gate (session 14s).
#
# WHY THIS EXISTS: every RAM-basis gate is blind to graphics. The
# session-14r overlay tile placements corrupted the title screen,
# select screen and speed menu (bank-1 "OBJ-dead" positions back
# SCROLL-layer tiles — CPS-2 scroll1/2/3 decode the same ROM bytes),
# and the full masked legacy battery stayed green. Playtest was the
# only detector. This gate snapshots three menu screens on the build
# under test and compares PIXELS against frozen vanilla goldens:
#   frame  650  title screen
#   frame  950  character select (Demitri hovered; slot-0x0F art is
#               not drawn on this path — full-frame compare is valid
#               until the wheel mugshot itself is ported, then this
#               needs a mask)
#   frame 1250  speed-select menu
# Regenerate goldens (vanilla): tests/test_gfx_menus.sh --freeze
set -e
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
: "${ROMDIR:?set ROMDIR}"
GOLD="tests/expected/vsavj/menus"
SB="$(mktemp -d)"
trap 'rm -rf "$SB"' EXIT

ROMPATH="$REPO/build/donovan6/rompath;$ROMDIR"
[ "$1" = "--freeze" ] && ROMPATH="$ROMDIR"

SNAP_FRAMES="650,950,1250" REPLAY="$REPO/tests/replays/02_demitri_vs_cpu.rpl" \
CHECKSUM_OUT="$SB/r.log" MAME_SANDBOX="$SB" MAME_ROMPATH="$ROMPATH" \
    tools/run_mame.sh vsavj -autoboot_script "$REPO/tests/lua/replay.lua" \
    > /dev/null 2>&1

if [ "$1" = "--freeze" ]; then
    i=0
    for f in 650 950 1250; do
        cp "$SB/snap/vsavj/000$i.png" "$GOLD/frame_$f.png"
        i=$((i+1))
    done
    echo "goldens frozen from vanilla into $GOLD"
    exit 0
fi

python3 - "$SB/snap/vsavj" "$GOLD" <<'EOF'
import sys, os
from PIL import Image
snapdir, gold = sys.argv[1], sys.argv[2]
frames = [650, 950, 1250]
fail = 0
for i, fr in enumerate(frames):
    a = Image.open(os.path.join(snapdir, f"000{i}.png")).convert("RGB")
    b = Image.open(os.path.join(gold, f"frame_{fr}.png")).convert("RGB")
    if a.size != b.size or a.tobytes() != b.tobytes():
        diff = sum(1 for pa, pb in zip(a.getdata(), b.getdata()) if pa != pb) \
            if a.size == b.size else -1
        print(f"  FAIL frame {fr}: {diff} pixels differ")
        fail += 1
    else:
        print(f"  ok: frame {fr} pixel-identical")
sys.exit(1 if fail else 0)
EOF
echo "PASS: menu gfx gate"
