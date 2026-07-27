#!/bin/sh
# test_m2a_stage4_oracle.sh — M2a stage-4 behavior gate: ported Donovan on
# vsavj vs NATIVE Donovan on vsav2 (CLAUDE.md §4 dual-oracle for new
# content, same-emulator two-game form).
#
# Replay pair tests/replays/17_don_oracle_{vsav2,vsavj}.rpl: both games
# run IDENTICAL inputs (sibling engines traverse identical menu timelines
# — measured: both anchor at frame 2363), P1 Donovan, P2 Victor, then a
# scripted battery (normals, QCF+P, VS2-flavor QCB+K, DP, walk-in hits).
#
# Locks (session 8-9 measurements):
#   1. Match-start anchors equal (2363/2363).
#   2. NEUTRAL window (anchor..anchor+~140, all idle): compare_fields
#      --exact agrees on every mapped field, every frame (1100 frames).
#      ROM-pointer/id fields are skipped (relocated by design) — their
#      correctness is covered by the pick gate + the agreement of every
#      derived field (box ids, positions, HP).
#   3. COMBAT window: frame-exact cross-GAME comparison is impossible by
#      construction — the two ENGINES differ by ~1 frame of action
#      latency (proven by the 18_veteran_ctl control: vanilla Demitri
#      running the same battery on both games diverges MORE than ported
#      Donovan does). Locks used instead:
#      a. HP-decrease sanity: P2 HP-change event VALUE sequences are
#         EQUAL on both sides and end below 0x120 (hits land, same
#         damage).
#      b. Comparative bound: ported-Donovan mismatch count <= the native
#         veteran control's count on the same battery (the port may not
#         diverge across engines more than an untouched character does).
#
# Usage: ROMDIR=... tests/test_m2a_stage4_oracle.sh [rompath_dir]
#   rompath_dir default: build/donovan/rompath (an existing stage-4 build)
set -eu

ROMDIR="${ROMDIR:?set ROMDIR}"
REPO="$(cd "$(dirname "$0")/.." && pwd)"
RPDIR="${1:-$REPO/build/donovan/rompath}"
[ -d "$RPDIR" ] || { echo "no build at $RPDIR — run tools/build_donovan.sh 4 first"; exit 1; }
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
cd "$REPO"
fail=0

FIELDS="$REPO/tests/fields_m2a.tsv"
SKIP="p1_char_id,p1_hitbox_base,p2_hitbox_base,p1_ptr64,p2_ptr64,p1_anim_ptr,p2_anim_ptr,p1_word132,p2_word132"
ANCHOR_SPEC=$(python3 -c "print(';'.join(f'{f}:ff8000-ff8300;{f}:ff8400-ff8c00' for f in range(2300,2510)))")
BAT_SPEC=$(python3 -c "print(';'.join(f'{f}:ff8000-ff8300;{f}:ff8400-ff8c00' for f in range(2510,4300,2)))")

run_windows() { # $1=set $2=replay $3=outtag $4=rompath
    mkdir -p "$WORK/$3_anchor" "$WORK/$3_bat"
    DUMPS="$ANCHOR_SPEC" REPLAY="$REPO/tests/replays/$2" \
        CHECKSUM_OUT="$WORK/$3_anchor/c.log" MAME_SANDBOX="$WORK/$3_abox" \
        MAME_ROMPATH="$4" "$REPO/tools/run_mame.sh" "$1" \
        -autoboot_script "$REPO/tests/lua/replay.lua" > /dev/null 2>&1
    DUMPS="$BAT_SPEC" REPLAY="$REPO/tests/replays/$2" \
        CHECKSUM_OUT="$WORK/$3_bat/c.log" MAME_SANDBOX="$WORK/$3_bbox" \
        MAME_ROMPATH="$4" "$REPO/tools/run_mame.sh" "$1" \
        -autoboot_script "$REPO/tests/lua/replay.lua" > /dev/null 2>&1
}

echo "== dumps: native vsav2 / ported vsavj / veteran controls =="
run_windows vsav2 17_don_oracle_vsav2.rpl nat "$ROMDIR" &
run_windows vsavj 17_don_oracle_vsavj.rpl por "$RPDIR;$ROMDIR" &
wait
run_windows vsav2 18_veteran_ctl_vsav2.rpl cnat "$ROMDIR" &
run_windows vsavj 18_veteran_ctl_vsavj.rpl cpor "$ROMDIR" &
wait

echo "== 1. anchors =="
a_nat=$(python3 tools/compare_fields.py --list-anchors --fields "$FIELDS" "$WORK/nat_anchor")
a_por=$(python3 tools/compare_fields.py --list-anchors --fields "$FIELDS" "$WORK/por_anchor")
if [ "$a_nat" = "$a_por" ] && [ -n "$a_nat" ]; then
    echo "  ok: match-start anchors equal ($a_nat)"
else
    echo "FAIL: anchors differ (native '$a_nat' vs ported '$a_por')"; fail=1
fi

echo "== 2. neutral window: exact field agreement =="
if python3 tools/compare_fields.py --fields "$FIELDS" --exact \
    --skip-fields "$SKIP" "$WORK/nat_anchor" "$WORK/por_anchor" \
    > "$WORK/neutral.txt" 2>&1; then
    echo "  ok: $(tail -2 "$WORK/neutral.txt" | head -1)"
else
    echo "FAIL: neutral-window disagreement:"; head -8 "$WORK/neutral.txt"; fail=1
fi

echo "== 3a. HP-decrease sanity (battery) =="
hp_events() {
    python3 - "$1" <<'PY'
import os, sys, glob
d = sys.argv[1]
last, out = None, []
for p in sorted(glob.glob(f"{d}/dump_*_ff8400.bin"),
                key=lambda p: int(p.split("_")[-2])):
    b = open(p, "rb").read()
    hp = int.from_bytes(b[0x450:0x452], "big")
    if hp != last:
        out.append(hp); last = hp
print(",".join(str(h) for h in out))
PY
}
ev_nat=$(hp_events "$WORK/nat_bat")
ev_por=$(hp_events "$WORK/por_bat")
final_por="${ev_por##*,}"
if [ "$ev_nat" = "$ev_por" ] && [ "$final_por" -lt 288 ]; then
    echo "  ok: P2 HP trajectories equal and decreasing ($ev_nat)"
else
    echo "FAIL: HP trajectories: native [$ev_nat] vs ported [$ev_por]"; fail=1
fi

echo "== 3b. comparative bound vs native-veteran control =="
count_mm() {
    python3 tools/compare_fields.py --fields "$FIELDS" --exact \
        --skip-fields "$SKIP" "$1" "$2" 2>/dev/null \
        | grep -c "^MISMATCH" || true
}
mm_don=$(count_mm "$WORK/nat_bat" "$WORK/por_bat")
mm_ctl=$(count_mm "$WORK/cnat_bat" "$WORK/cpor_bat")
if [ "$mm_don" -le "$mm_ctl" ]; then
    echo "  ok: ported-Donovan battery mismatches ($mm_don) <= veteran control ($mm_ctl)"
else
    echo "FAIL: ported Donovan diverges MORE than a native veteran ($mm_don > $mm_ctl)"; fail=1
fi

[ "$fail" = 0 ] && echo "PASS: M2a stage-4 oracle gate" \
    || { echo "FAIL: M2a stage-4 oracle gate"; exit 1; }
