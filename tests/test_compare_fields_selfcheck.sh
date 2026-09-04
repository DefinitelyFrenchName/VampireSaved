#!/bin/sh
# test_compare_fields_selfcheck.sh — ground truth for the dual-emulator field
# comparator (verdict-logic doctrine): its verdicts are trusted only after it
# agrees on known-good content and disagrees on known-different content.
#
#   1. Positive control (first real exercise of the amended CLAUDE.md §4
#      protocol on known-good content): 16_xemu_2p on MAME vs patched FBNeo
#      must agree on all mapped fields at the match-start anchor and shortly
#      after. 16 is the dual-emulator-safe replay: both characters scripted
#      with generous menu margins, no in-match inputs. Replays NOT authored
#      to those rules genuinely diverge cross-emulator (CPU-chosen opponents
#      differ; menu presses near transitions land on opposite sides of an
#      input-accept boundary — docs/GOTCHAS.md).
#   2. Negative control: 16 (MAME) vs 02_demitri_vs_cpu (MAME) — different
#      content — must FAIL (exit 3).
#
# Usage: ROMDIR=... tests/test_compare_fields_selfcheck.sh
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
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
fail=0

FIELDS="$REPO/tests/fields_m2a.tsv"
RPL="$REPO/tests/replays/16_xemu_2p.rpl"
cf() { python3 "$REPO/tools/compare_fields.py" "$@"; }

# full-field dump spec (anchor predicate + all mapped fields)
window_spec() { # $1=first frame, $2=last frame
    python3 - "$1" "$2" <<'PY'
import sys
a, b = int(sys.argv[1]), int(sys.argv[2])
print(";".join(f"{f}:ff8000-ff8300;{f}:ff8400-ff8c00" for f in range(a, b + 1)))
PY
}
# predicate-only dump spec (narrow: FBNeo's -hdump buffer is 8KB), with a
# stride for coarse scans — max ~130 sampled frames per run
probe_spec() { # $1=first $2=last $3=stride
    python3 - "$1" "$2" "${3:-1}" <<'PY'
import sys
a, b, s = int(sys.argv[1]), int(sys.argv[2]), int(sys.argv[3])
print(";".join(f"{f}:ff8000-ff8010;{f}:ff8450-ff8452;{f}:ff8850-ff8852"
               for f in range(a, b + 1, s)))
PY
}

# --- MAME wide run: anchor + full window in one pass -------------------------
mkdir -p "$WORK/mame16"
DUMPS="$(window_spec 2200 3200)" \
    "$REPO/tools/run_replay_mame.sh" vsavj "$RPL" \
    "$WORK/mame16/out.log" "$WORK/m16box"
AM=$(cf "$WORK/mame16" --list-anchors 2>/dev/null | head -1)
[ -n "$AM" ] || { echo "FAIL: no MAME match-start anchor in frames 2200-3200"; exit 1; }
echo "  ok: MAME anchor at frame $AM"

# --- FBNeo anchor: coarse stride-8 scan, then fine contiguous probe ---------
mkdir -p "$WORK/fbcoarse"
FBNEO_DUMPS="$(probe_spec $((AM - 60)) $((AM + 900)) 8)" \
    "$REPO/tools/run_replay_fbneo.sh" vsavj "$RPL" \
    "$WORK/fbcoarse/out.log" "$WORK/fcbox"
AC=$(cf "$WORK/fbcoarse" --list-anchors 2>/dev/null | head -1)
[ -n "$AC" ] || { echo "FAIL: no FBNeo anchor within MAME anchor -60..+900"; exit 1; }
mkdir -p "$WORK/fbfine"
FBNEO_DUMPS="$(probe_spec $((AC - 16)) $((AC + 40)))" \
    "$REPO/tools/run_replay_fbneo.sh" vsavj "$RPL" \
    "$WORK/fbfine/out.log" "$WORK/ffbox"
AF=$(cf "$WORK/fbfine" --list-anchors 2>/dev/null | head -1)
[ -n "$AF" ] || { echo "FAIL: fine probe found no stable rising edge near $AC"; exit 1; }
echo "  ok: FBNeo anchor at frame $AF (skew $((AF - AM)))"

# --- FBNeo full-field run around its own anchor ------------------------------
# Mixed spec to fit the 8KB -hdump buffer: contiguous predicate-only dumps
# for anchor confirmation + debounce, plus full-field dumps at exactly the
# compared offsets (+0, +120, +240).
mkdir -p "$WORK/fb16"
FBNEO_DUMPS="$(probe_spec $((AF - 4)) $((AF + 40)));$(window_spec $AF $AF);$(window_spec $((AF + 120)) $((AF + 120)));$(window_spec $((AF + 240)) $((AF + 240)))" \
    "$REPO/tools/run_replay_fbneo.sh" vsavj "$RPL" \
    "$WORK/fb16/out.log" "$WORK/f16box"

# --- 1. positive control -----------------------------------------------------
# stable fields at +0; settled fields (positions, facing, attack id) join at
# +120/+240 once the round is in neutral idle
if cf "$WORK/mame16" "$WORK/fb16" --fields "$FIELDS" --follow 0,120,240 \
        --label-a mame --label-b fbneo > "$WORK/pos.out" 2>&1; then
    echo "  ok: positive control — MAME/FBNeo agree ($(grep '^anchors:' "$WORK/pos.out"))"
else
    echo "FAIL: positive control disagreed:"; cat "$WORK/pos.out"; fail=1
fi

# --- 2. negative control (exact mode: same absolute frames, different
#     content — verdict must be disagreement) ---------------------------------
mkdir -p "$WORK/mame02"
DUMPS="$(window_spec 2300 2360)" \
    "$REPO/tools/run_replay_mame.sh" vsavj \
    "$REPO/tests/replays/02_demitri_vs_cpu.rpl" "$WORK/mame02/out.log" "$WORK/m02box"
rc=0
cf "$WORK/mame16" "$WORK/mame02" --fields "$FIELDS" --exact \
    > "$WORK/neg.out" 2>&1 || rc=$?
if [ "$rc" = "3" ]; then
    echo "  ok: negative control — different replays flagged as disagreeing"
else
    echo "FAIL: negative control rc=$rc (expected 3):"; cat "$WORK/neg.out"; fail=1
fi

[ "$fail" = 0 ] && echo "PASS: field-comparator verdicts validated against ground truth" \
    || { echo "SUITE RED"; exit 1; }
