#!/bin/sh
# test_m2a_stage4_xemu.sh — M2a stage-4 dual-emulator gate (CLAUDE.md §4):
# the PATCHED build runs 17_don_oracle_vsavj (both picks scripted, 16_xemu
# authoring rules) on MAME and on patched FBNeo; mapped gameplay fields
# must agree at the match-start anchor and pre-battery follow offsets.
#
# Follow offsets stay BEFORE the in-match battery (absolute frame 2600,
# anchor ~2363): the two emulators reach the anchor a few frames apart, so
# anchor-relative frames after scripted inputs land on different content —
# the §4 protocol compares mapped state at anchors, which the neutral
# window covers. Same-emulator combat verification is the oracle gate;
# cross-emulator crash-freedom is the FBNeo run itself completing.
#
# Recipe (validated by tests/test_compare_fields_selfcheck.sh): MAME wide
# window; FBNeo coarse stride-8 anchor scan then fine probe (8KB -hdump
# buffer); mixed spec full-field dumps at the compared offsets.
#
# Usage: ROMDIR=... tests/test_m2a_stage4_xemu.sh [rompath_dir]
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
RPL="$REPO/tests/replays/17_don_oracle_vsavj.rpl"
FOLLOW="0,60,180"
cf() { python3 "$REPO/tools/compare_fields.py" "$@"; }

window_spec() {
    python3 - "$1" "$2" <<'PY'
import sys
a, b = int(sys.argv[1]), int(sys.argv[2])
print(";".join(f"{f}:ff8000-ff8300;{f}:ff8400-ff8c00" for f in range(a, b + 1)))
PY
}
probe_spec() {
    python3 - "$1" "$2" "${3:-1}" <<'PY'
import sys
a, b, s = int(sys.argv[1]), int(sys.argv[2]), int(sys.argv[3])
print(";".join(f"{f}:ff8000-ff8010;{f}:ff8450-ff8452;{f}:ff8850-ff8852"
               for f in range(a, b + 1, s)))
PY
}

echo "== MAME (patched) wide window =="
mkdir -p "$WORK/mame"
DUMPS="$(window_spec 2300 2620)" MAME_ROMPATH="$RPDIR;$ROMDIR" \
    "$REPO/tools/run_replay_mame.sh" vsavj "$RPL" \
    "$WORK/mame/out.log" "$WORK/mbox"
AM=$(cf "$WORK/mame" --list-anchors --fields "$FIELDS" 2>/dev/null | head -1)
[ -n "$AM" ] || { echo "FAIL: no MAME anchor in 2300-2620"; exit 1; }
echo "  ok: MAME anchor at frame $AM"

echo "== FBNeo (patched) anchor scan =="
mkdir -p "$WORK/fbcoarse"
FBNEO_DUMPS="$(probe_spec $((AM - 60)) $((AM + 900)) 8)" FBNEO_ROMPATH="$RPDIR" \
    "$REPO/tools/run_replay_fbneo.sh" vsavj "$RPL" \
    "$WORK/fbcoarse/out.log" "$WORK/fcbox"
AC=$(cf "$WORK/fbcoarse" --list-anchors --fields "$FIELDS" 2>/dev/null | head -1)
[ -n "$AC" ] || { echo "FAIL: no FBNeo anchor within MAME anchor -60..+900"; exit 1; }
mkdir -p "$WORK/fbfine"
FBNEO_DUMPS="$(probe_spec $((AC - 16)) $((AC + 40)))" FBNEO_ROMPATH="$RPDIR" \
    "$REPO/tools/run_replay_fbneo.sh" vsavj "$RPL" \
    "$WORK/fbfine/out.log" "$WORK/ffbox"
AF=$(cf "$WORK/fbfine" --list-anchors --fields "$FIELDS" 2>/dev/null | head -1)
[ -n "$AF" ] || { echo "FAIL: no stable FBNeo rising edge near $AC"; exit 1; }
echo "  ok: FBNeo anchor at frame $AF (skew $((AF - AM)))"

echo "== FBNeo full-field dumps at follow offsets =="
mkdir -p "$WORK/fb"
FBNEO_DUMPS="$(probe_spec $((AF - 4)) $((AF + 40)));$(window_spec $AF $AF);$(window_spec $((AF + 60)) $((AF + 60)));$(window_spec $((AF + 180)) $((AF + 180)))" \
    FBNEO_ROMPATH="$RPDIR" \
    "$REPO/tools/run_replay_fbneo.sh" vsavj "$RPL" \
    "$WORK/fb/out.log" "$WORK/fbox"

echo "== field agreement at anchors (follow $FOLLOW) =="
if cf "$WORK/mame" "$WORK/fb" --fields "$FIELDS" --follow "$FOLLOW" \
        --label-a mame --label-b fbneo > "$WORK/agree.out" 2>&1; then
    echo "  ok: MAME/FBNeo agree on the patched build ($(grep '^anchors:' "$WORK/agree.out" || true))"
else
    echo "FAIL: dual-emulator disagreement:"; cat "$WORK/agree.out"; fail=1
fi

[ "$fail" = 0 ] && echo "PASS: M2a stage-4 dual-emulator gate" \
    || { echo "FAIL: M2a stage-4 dual-emulator gate"; exit 1; }
