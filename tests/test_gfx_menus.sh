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
#   frame  950  character select (Demitri hovered). 14z-49: the wheel
#               medallion IS now ported (Donovan icon + row-14 recolor
#               on Jedah's cell), so frames 950/1250 mask the cell box
#               — screen (172,41)-(219,72), the 48x32 OBJ at raw
#               (236,57) — and compare everything else pixel-exact.
#               The masked box's correctness is covered by
#               test_don_colors' medallion locks (row-14 freeze +
#               record assert + build-time byte-exact art placement).
#   frame 1250  speed-select menu (wheel visible behind it: same mask)
# Regenerate goldens (vanilla): tests/test_gfx_menus.sh --freeze
set -e
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
: "${ROMDIR:?set ROMDIR}"
GOLD="tests/expected/vsavj/menus"
SB="$(mktemp -d)"
trap 'rm -rf "$SB"' EXIT

# 14z-90 (GitHub issue #9/#6): the rompath was hardcoded to build/donovan6 while
# the caller built into $OUTBASE, so on any non-default outbase the soaks and
# the masked legacy gate measured one build and this gate measured another.
# It takes the rompath as an argument now (after --freeze, which keeps $1).
#
# THE SET IS DELIBERATELY NOT PARAMETERISED. The goldens under
# tests/expected/vsavj/menus/ are renders of VANILLA vsavj. The WIDE wheel adds
# three medallions at (212,161)/(236,169)/(260,161) — none inside this gate's
# single MEDALLION mask — on frames 950 and 1250, which are both wheel-visible.
# Pointing this gate at vsavjw would therefore FAIL BY DESIGN, and stock MAME
# cannot load that set anyway. WIDE rendering is covered by
# tests/test_wide_render_content.sh (docs/project/visual_smoke_tests.md rows 1
# and 2 file them as separate items). The battery cannot produce a WIDE build
# at any outbase either: test_m2b_stage6.sh's prefix GEN_FLAGS assignment
# carries no --profile, so build_donovan.sh always packs vsavj.
SET=vsavj
FREEZE=0
[ "${1:-}" = "--freeze" ] && { FREEZE=1; shift; }
RPDIR="${1:-$REPO/build/donovan6/rompath}"
if [ "$FREEZE" = 1 ]; then
    ROMPATH="$ROMDIR"
else
    # The check is on the SET ZIP, not the directory. build/don_m5/rompath and
    # build/hui40/rompath both EXIST and hold vsavjw.zip only, so a -d test
    # passes and drops straight into run_mame.sh's chained-rompath fall-through,
    # where MAME resolves the members by hash out of $ROMDIR and this gate
    # compares vanilla against vanilla-frozen goldens — a permanent pass that
    # proves nothing (docs/platform/gotchas.md: "a chained rompath makes MAME a
    # LIAR about member identity").
    [ -f "$RPDIR/$SET.zip" ] || {
        echo "FAIL: no $SET.zip under $RPDIR — build first, or pass the rompath"
        echo "      of a stock build. This gate is vsavj-only by design."
        exit 1
    }
    ROMPATH="$RPDIR;$ROMDIR"
fi

SNAP_FRAMES="650,950,1250" REPLAY="$REPO/tests/replays/02_demitri_vs_cpu.rpl" \
CHECKSUM_OUT="$SB/r.log" MAME_SANDBOX="$SB" MAME_ROMPATH="$ROMPATH" \
    tools/run_mame.sh "$SET" -autoboot_script "$REPO/tests/lua/replay.lua" \
    > /dev/null 2>&1

if [ "$FREEZE" = 1 ]; then
    i=0
    for f in 650 950 1250; do
        cp "$SB/snap/$SET/000$i.png" "$GOLD/frame_$f.png"
        i=$((i+1))
    done
    echo "goldens frozen from vanilla into $GOLD"
    exit 0
fi

python3 - "$SB/snap/$SET" "$GOLD" <<'EOF'
import sys, os
from PIL import Image
snapdir, gold = sys.argv[1], sys.argv[2]
frames = [650, 950, 1250]
# 14z-49: Donovan medallion cell (raw OBJ 236,57 3x2 -> screen box) is an
# INTENDED diff on wheel-visible frames; masked here, locked elsewhere
# (test_don_colors medallion section + build-time art assert).
MEDALLION = (172, 41, 220, 73)   # l, t, r, b (exclusive)
MASKED = {950: [MEDALLION], 1250: [MEDALLION]}
fail = 0
for i, fr in enumerate(frames):
    a = Image.open(os.path.join(snapdir, f"000{i}.png")).convert("RGB")
    b = Image.open(os.path.join(gold, f"frame_{fr}.png")).convert("RGB")
    for box in MASKED.get(fr, []):
        if a.size == b.size:
            black = Image.new("RGB", (box[2] - box[0], box[3] - box[1]))
            a.paste(black, (box[0], box[1]))
            b.paste(black, (box[0], box[1]))
    if a.size != b.size or a.tobytes() != b.tobytes():
        diff = sum(1 for pa, pb in zip(a.getdata(), b.getdata()) if pa != pb) \
            if a.size == b.size else -1
        print(f"  FAIL frame {fr}: {diff} pixels differ")
        fail += 1
    else:
        tag = " (medallion box masked)" if fr in MASKED else ""
        print(f"  ok: frame {fr} pixel-identical{tag}")
sys.exit(1 if fail else 0)
EOF
echo "PASS: menu gfx gate"
