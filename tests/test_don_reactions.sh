#!/bin/sh
# test_don_reactions.sh — Change Immortal behavior gate (14z-26..28).
#
# GAMEPLAY LOCK (round-41, maintainer): 421P is a standing up-to-8-hit
# multi — it must MULTI-HIT and must NOT knock down a standing
# opponent. The 14z-27 class remap (0x4E -> 0x04) violated this
# (single-hit hard knockdown) and was reverted; this gate keeps any
# future fix honest on the move's core behavior.
#
# STRENGTHENED 14z-36: the sworded deity's records are remapped to
# type 0x06 (vs2-alias-proven: vs2 word[0x4E]==word[0x06]) = native
# class-8 electric — section 2 asserts the complete death chain on a
# fatal hit (grounded node 0x158210), closing the round-39
# neutral-pose bug for the sworded variant too.
#
# STRENGTHENED 14z-42 (hit-freeze fix, ls_freeze_vs2_* thunks): the
# no-mash HP version at this spacing is NATIVE-CLASS — total damage
# <= 10 (native == 10: 5-point initial sword hit + 5 deity ticks;
# the pre-fix build dealt 22) and the last damage lands by f2700
# (native window ends ~2689; the slow pre-fix build hit until ~2797
# — a layout-independent duration proxy for the cadence). Mash
# extension verified native-equal separately (3 -> 4 loop
# iterations on both games, session 14z-42).
#
# Usage: ROMDIR=... tests/test_don_reactions.sh [rompath_dir]
set -eu
ROMDIR="${ROMDIR:?set ROMDIR}"
REPO="$(cd "$(dirname "$0")/.." && pwd)"
RPDIR="${1:-$REPO/build/donovan6/rompath}"
[ -d "$RPDIR" ] || { echo "no build at $RPDIR"; exit 1; }
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
cd "$REPO"

DUMPS=$(python3 -c "print(';'.join(f'{f}:ff8850-ff8854;{f}:ff8800-ff8830' for f in range(2630,2760,10)))")
DUMPS="$DUMPS" REPLAY="$REPO/tests/replays/48_don_immortal_ko.rpl" \
    CHECKSUM_OUT="$WORK/c.log" MAME_SANDBOX="$WORK" \
    MAME_ROMPATH="$RPDIR;$ROMDIR" tools/run_mame.sh vsavj \
    -autoboot_script "$REPO/tests/lua/replay.lua" > /dev/null 2>&1

python3 - "$WORK" <<'EOF2'
import sys, os, glob
work = sys.argv[1]
frames = sorted(int(os.path.basename(p).split('_')[1])
                for p in glob.glob(os.path.join(work, 'dump_*_ff8850.bin')))
assert len(frames) >= 10, f"only {len(frames)} dumps"
prev = None; hits = 0
hp_first = hp_last = None; last_hit_frame = None
for f in frames:
    hp = int.from_bytes(open(os.path.join(work, f'dump_{f}_ff8850.bin'),'rb').read()[:2],'big')
    ob = open(os.path.join(work, f'dump_{f}_ff8800.bin'),'rb').read()
    node = int.from_bytes(ob[0x1c:0x20],'big')
    assert not (0x157F00 <= node <= 0x1586FF), (
        f"victim in knockdown-family node {node:#x} at f{f} — 421P must "
        f"not knock down a standing opponent (the 14z-27 regression)")
    if hp_first is None: hp_first = hp
    if prev is not None and hp < prev:
        hits += 1; last_hit_frame = f
    prev = hp; hp_last = hp
assert hits >= 2, f"only {hits} damage steps — 421P must multi-hit"
total = hp_first - hp_last
assert total <= 10, (
    f"{total} total damage no-mash — exceeds the native total of 10 "
    f"(hit-freeze regression: the pre-14z-42 build dealt 22)")
assert last_hit_frame is not None and last_hit_frame <= 2700, (
    f"last damage step at f{last_hit_frame} — past the native-class window "
    f"(<=2700); the move is running slow (hit-freeze regression)")
print(f"  ok: 421P multi-hits ({hits} steps, {total} total, last at "
      f"f{last_hit_frame}) native-class, no knockdown on a standing opponent")
EOF2
# ── 2. fatal: the full native electric death chain ───────────────────
mkdir -p "$WORK/ko"
POKES="2600:ff8850:00010001" \
DUMPS="2950:ff8800-ff8830;3030:ff8800-ff8830" \
    REPLAY="$REPO/tests/replays/48_don_immortal_ko.rpl" \
    CHECKSUM_OUT="$WORK/ko/c.log" MAME_SANDBOX="$WORK/ko" \
    MAME_ROMPATH="$RPDIR;$ROMDIR" tools/run_mame.sh vsavj \
    -autoboot_script "$REPO/tests/lua/replay.lua" > /dev/null 2>&1

python3 - "$WORK/ko" <<'EOF2'
import sys, os
work = sys.argv[1]
for fr in (2950, 3030):
    d = open(os.path.join(work, f'dump_{fr}_ff8800.bin'), 'rb').read()
    node = int.from_bytes(d[0x1c:0x20], 'big')
    assert node == 0x158210, (
        f"victim node at f{fr} = {node:#x}, expected grounded death "
        f"0x158210 (idle loop = the round-39 neutral-pose bug)")
print("  ok: deity KO runs the full native electric death (grounded at 0x158210)")
EOF2
echo "PASS: Donovan hit-class reaction gate"
