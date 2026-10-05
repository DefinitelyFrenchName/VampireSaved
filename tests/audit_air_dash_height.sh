#!/bin/sh
# audit_air_dash_height.sh — PHOBOS'S AIR DASH UNDER vs2's MINIMUM HEIGHT: native refuses it, ours performs it
# (GitHub #222, measured in play 14z-191). Emulator tier (MAME), ~2 min.
#
# WHAT: Phobos jumps straight up and inputs the air dash j.66 with the second R at +5..+16 frames; at +5 (height 21,
#   under vs2's table row 0x10 = 24) native vs2 does not dash and merged-m22 dashes; at every later event (height 34
#   and up) both dash on the same frame at the same height. That is the frozen expectation (--expect gap) until a
#   build takes vs2's row (#222), when the expectation becomes --expect same.
# HOW: tools/air_dash_rigs.py generates the rig on tools/name_moves.py's machinery (Phobos by his real cursor path on
#   native, the merged wheel's D D D on ours — HANDOFF [VSP-123]); both legs traced by tests/lua/field_trace.lua under
#   the ruled level and RNG pins; the comparer refuses a leg whose low event is not under 24 or whose high events did
#   not dash on native (VOID).
# EXPECTS: PASS under --expect gap. A red is either the gap gone (a build changed Phobos's air dash — re-read #222) or
#   a difference above the row, which no measurement here has shown.
#
# MUST-FIRE: perturbed-copy: native-dash-planted — native's trace with a dash planted at the low event must FAIL the gap compare (mode: the compare reads the planted native leg)
# FOLLOWS: build/manifest/ emu/mame-patches/ tests/lib/controls.sh tests/lua/field_trace.lua tools/air_dash_rigs.py
#   tools/build_fingerprint.py tools/name_moves.py tools/run_mame.sh tools/select_paths.py tools/setup_mame.sh
#
# Usage: ROMDIR=... [MAME_BIN=...] [BUILD=build/m3b_merged30] [KEEP=<dir>] tests/audit_air_dash_height.sh
set -u
REPO="$(cd "$(dirname "$0")/.." && pwd)"; cd "$REPO"
. "$REPO/tests/lib/controls.sh"; vs_ctl_mode "$0"
: "${ROMDIR:?set ROMDIR}"
BUILD="${BUILD:-build/m3b_merged30}"
MAME_BIN="${MAME_BIN:-$HOME/.cache/vampire-saved/mame/cps2}"; export MAME_BIN
[ -x "$MAME_BIN" ] || { echo "FAIL: no MAME binary at $MAME_BIN (tools/setup_mame.sh)"; exit 1; }
[ -f "$BUILD/rompath/vsavjw.zip" ] || { echo "FAIL: no $BUILD/rompath/vsavjw.zip"; exit 1; }
W="${KEEP:-$(mktemp -d)}"; mkdir -p "$W"
[ -n "${KEEP:-}" ] || trap 'rm -rf "$W"' EXIT INT TERM
echo "== audit_air_dash_height (#222): build $BUILD ($(python3 tools/build_fingerprint.py "$BUILD/rompath" --set vsavjw --sha-only 2>/dev/null | cut -c1-8))"
python3 tools/air_dash_rigs.py gen "$W" > /dev/null || { echo "FAIL: rig generation"; exit 1; }
J="$W/h222.json"
fr="$(python3 -c "import json;print(json.load(open('$J'))['frames'])")"
pk="$(python3 -c "import json;print(';'.join(json.load(open('$J'))['pokes']))");2000-$((fr - 1)):ff8116:06;2363-$((fr - 1)):ff80d4:0000"
FIELDS="$(python3 -c 'import sys; sys.path.insert(0,"tools"); import air_dash_rigs as a; print(a.FIELDS)')"
awk '/^1104-1106 p2=R$/ && !done { t=1100; n=split("D D D", m, " "); for (i=1;i<=n;i++){ printf "%d-%d p1=%s\n", t, t+2, m[i]; t+=60 }; done=1 }
     /^(1100|1160|1220|1280)-[0-9]+ p1=/ { next } { print }' "$W/h222.rpl" > "$W/h222.ours.rpl"
for side in native ours; do
    if [ $side = native ]; then s=vsav2; rp="$ROMDIR"; R="$W/h222.rpl"; else s=vsavjw; rp="$REPO/$BUILD/rompath;$ROMDIR"; R="$W/h222.ours.rpl"; fi
    d="$W/$side"; rm -rf "$d"; mkdir -p "$d"
    ( cd "$d" && MAME_SANDBOX="$d/sb" MAME_ROMPATH="$rp" REPLAY="$R" POKES="$pk" FIELDS="$FIELDS" FIELD_OUT="$W/tr_$side.txt" \
        FIELD_FROM=2300 FIELD_TO="$fr" FRAMES="$fr" "$REPO/tools/run_mame.sh" "$s" -autoboot_script "$REPO/tests/lua/field_trace.lua" > "$d/mame.log" 2>&1
      rm -rf "$d/sb" ) < /dev/null &
done
wait
fail=0
for side in native ours; do grep -q FIELDSUMMARY "$W/tr_$side.txt" 2>/dev/null || { echo "FAIL: $side: no complete trace ($W/$side/mame.log)"; fail=1; }; done
[ "$fail" = 0 ] || exit 1
PL=""; vs_ctl_is native-dash-planted && PL="--plant-native-dash"
echo "== 1. the low event refused on native and performed on ours; identical above vs2's row"
python3 tools/air_dash_rigs.py compare "$J" "$W/tr_native.txt" "$W/tr_ours.txt" --expect gap $PL; rc=$?
[ "$rc" = 0 ] || fail=1
if vs_ctl_is native-dash-planted; then
    [ "$fail" = 1 ] && { echo "FAIL: audit_air_dash_height (control mode: the planted native dash broke the gap)"; exit 1; }
    echo "FAIL: audit_air_dash_height — the planted native dash still read as a gap"; exit 1
fi
echo "== 2. control"
python3 tools/air_dash_rigs.py compare "$J" "$W/tr_native.txt" "$W/tr_ours.txt" --expect gap --plant-native-dash > "$W/ctl.txt" 2>&1
if grep -q 'MISMATCH' "$W/ctl.txt"; then vs_ctl_fired native-dash-planted "$(grep -m1 MISMATCH "$W/ctl.txt" | sed 's/^ *//')"
else vs_ctl_dead native-dash-planted "no MISMATCH with the native dash planted (a pass, or a crash: $(tail -1 "$W/ctl.txt" | cut -c1-100))"; fail=1; fi
[ "$fail" = 0 ] && echo "PASS: audit_air_dash_height — under vs2's row native refuses Phobos's air dash and ours performs it (#222); identical above" \
                || echo "FAIL: audit_air_dash_height"
exit "$fail"
