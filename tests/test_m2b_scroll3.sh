#!/bin/sh
# test_m2b_scroll3.sh — scroll3-vs-OBJ-band exclusivity check (M2b).
# The Donovan tile placement overwrites vsav bank-2 OBJ positions
# 0x2AD8F-0x2EEBB (Jedah's band). scroll1/2 cannot address bank 2
# (measured: CPS2 draw path, no mapper, offsets pin them to bank 1);
# scroll3 CAN (absolute = 0x10000 + 4*code). This check runs replays
# with tests/lua/scroll3_watch.lua and asserts NO frame ever has a
# scroll3 tile code mapping into the placement window — i.e. no stage
# art was overwritten. Static evidence already: the band is 99.3%
# saturated by Jedah's own OBJ records and renders as sprite art.
#
# Replays chosen for stage coverage: the attract (all demo stages incl
# Jedah's own demo), the arcade-mode marathon (stage rotation), and the
# standard match replays.
#
# Usage: ROMDIR=... tests/test_m2b_scroll3.sh [rompath_dir]
set -eu

ROMDIR="${ROMDIR:?set ROMDIR}"
REPO="$(cd "$(dirname "$0")/.." && pwd)"
RPDIR="${1:-$REPO/build/donovan6/rompath}"
[ -d "$RPDIR" ] || { echo "no build at $RPDIR"; exit 1; }
RPDIR="$(cd "$RPDIR" && pwd)"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
cd "$REPO"

fail=0
for r in 01_attract_long 26_don_arcade_mash 12_donovan_vs_cpu 21_don_mash; do
    SB="$WORK/${r}box"; mkdir -p "$SB"
    SCROLL3_OUT="$WORK/$r.s3" \
    REPLAY="$REPO/tests/replays/$r.rpl" \
    CHECKSUM_OUT="$WORK/$r.log" \
    MAME_SANDBOX="$SB" \
    MAME_ROMPATH="$RPDIR;$ROMDIR" \
        tools/run_mame.sh vsavj \
        -autoboot_script "$REPO/tests/lua/scroll3_watch.lua" \
        > "$SB/mame.log" 2>&1 || true
    if [ ! -f "$WORK/$r.s3" ]; then
        echo "FAIL: $r produced no scroll3 report"; fail=1; continue
    fi
    summary=$(grep SCROLL3SUMMARY "$WORK/$r.s3" || echo none)
    danger=$(printf '%s' "$summary" | sed -n 's/.*danger_frames=\([0-9]*\).*/\1/p')
    if [ "$danger" = "0" ]; then
        echo "  ok: $r — no scroll3 code in the placement window ($summary)"
    else
        echo "FAIL: $r — scroll3 touches the placement window: $summary"
        head -5 "$WORK/$r.s3"; fail=1
    fi
done

[ "$fail" = 0 ] && echo "PASS: scroll3 exclusivity" || echo "FAIL: scroll3 exclusivity"
exit "$fail"
