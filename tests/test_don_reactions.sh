#!/bin/sh
# test_don_reactions.sh — Change Immortal behavior gate (14z-26..28).
#
# GAMEPLAY LOCK (round-41, maintainer): 421P is a standing up-to-8-hit
# multi — it must MULTI-HIT and must NOT knock down a standing
# opponent. The 14z-27 class remap (0x4E -> 0x04) violated this
# (single-hit hard knockdown) and was reverted; this gate keeps any
# future fix honest on the move's core behavior.
#
# KNOWN-OPEN (14z-28): the match-end KO by this move shows the
# neutral-pose cosmetic bug (three class-0x4E consumers need vs2
# semantics: reaction property, death-path re-read, per-victim aura
# row — full map in STATE 14z-28). When the per-consumer fix lands,
# EXTEND this gate with the death-chain assertions (grounded node
# 0x158210 at f2950/f3030 with the HP=1 poke — see git history of
# this file for the exact form).
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
for f in frames:
    hp = int.from_bytes(open(os.path.join(work, f'dump_{f}_ff8850.bin'),'rb').read()[:2],'big')
    ob = open(os.path.join(work, f'dump_{f}_ff8800.bin'),'rb').read()
    node = int.from_bytes(ob[0x1c:0x20],'big')
    assert not (0x157F00 <= node <= 0x1586FF), (
        f"victim in knockdown-family node {node:#x} at f{f} — 421P must "
        f"not knock down a standing opponent (the 14z-27 regression)")
    if prev is not None and hp < prev: hits += 1
    prev = hp
assert hits >= 2, f"only {hits} damage steps — 421P must multi-hit"
print(f"  ok: 421P multi-hits ({hits} steps) with no knockdown on a standing opponent")
EOF2
echo "PASS: Donovan hit-class reaction gate"
