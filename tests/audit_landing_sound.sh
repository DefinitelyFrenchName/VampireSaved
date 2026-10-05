#!/bin/sh
# audit_landing_sound.sh — THE TENANTS' LANDING SOUND: vs2 gives Phobos the big-body landing and Donovan the ordinary
# one; ours the other way round (GitHub #223, measured in play and by ear 14z-191). Emulator tier (MAME), ~4 min.
#
# WHAT: the landing-sound site (ours PRG:0x00395E, vs2 0x003994) is reached on the same frames on both games for
#   Phobos (huitzil_1) and Donovan (donovan_1), always for the tenant on P1; and at the first landing (after Jump [8])
#   the two games' audio differs by over 4x what it differs a second earlier, with native the louder landing for Phobos
#   and ours the louder for Donovan (the +1 big-body id swapped). That is the frozen expectation (the gap) until a build
#   takes vs2's mask (#223).
# HOW: per tenant, two non-debug read taps (tests/lua/read_tap.lua on both fighters' +0x382, RPCS the site's own read)
#   and two -wavwrite runs to the landing + 120 frames, native vs2 and merged-m22, under the ruled level and RNG pins;
#   tools/landing_sound_ab.py compares the hits and the two one-second windows (control, landing).
# EXPECTS: PASS. A red is the gap gone (a build changed the mask — re-read #223), a hit-frame difference (the landing
#   moved), or a control window that differs (the two games' audio diverged before the landing: the comparison no
#   longer isolates the landing).
#
# MUST-FIRE: perturbed-copy: same-landing — ours' landing window replaced by native's must FAIL the gap (mode: section 2 compares the planted window)
# FOLLOWS: build/manifest/ emu/mame-patches/ tests/lib/controls.sh tests/lua/read_tap.lua tests/lua/field_trace.lua
#   tests/replays/naming/ tools/build_fingerprint.py tools/landing_sound_ab.py tools/name_moves.py tools/run_mame.sh
#   tools/setup_mame.sh
#
# Usage: ROMDIR=... [MAME_BIN=...] [BUILD=build/m3b_merged30] [KEEP=<dir>] tests/audit_landing_sound.sh
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
echo "== audit_landing_sound (#223): build $BUILD ($(python3 tools/build_fingerprint.py "$BUILD/rompath" --set vsavjw --sha-only 2>/dev/null | cut -c1-8))"
cur() { awk -v p="$2" '/^1104-1106 p2=R$/ && !done { t=1100; n=split(p, m, " "); for (i=1;i<=n;i++){ printf "%d-%d p1=%s\n", t, t+2, m[i]; t+=60 }; done=1 }
     /^(1100|1160|1220|1280)-[0-9]+ p1=/ { next } { print }' "$1"; }
leg() {  # leg <tenant> <native|ours> <tap|wav> <frames>
    t=$1; side=$2; kind=$3; fr=$4; J="tests/replays/naming/${t}_1.json"
    pk="$(python3 -c "import json;print(';'.join(json.load(open('$J'))['pokes']))");2000-$((fr - 1)):ff8116:06;2363-$((fr - 1)):ff80d4:0000"
    if [ "$side" = native ]; then s=vsav2; rp="$ROMDIR"; R="$REPO/tests/replays/naming/${t}_1.rpl"; pcs=399a
    else s=vsavjw; rp="$REPO/$BUILD/rompath;$ROMDIR"; R="$W/${t}_1.ours.rpl"; pcs=3964; fi
    d="$W/run_$t.$side.$kind"; rm -rf "$d"; mkdir -p "$d"   # never the name of an output file (14z-191: the .wav became this dir)
    if [ "$kind" = tap ]; then
        ( cd "$d" && MAME_SANDBOX="$d/sb" MAME_ROMPATH="$rp" REPLAY="$R" POKES="$pk" RTAP="ff8782,2;ff8b82,2" RPCS="$pcs" \
            WINDOW="2300,$fr" TRACE_OUT="$W/tap_$t.$side.txt" FRAMES="$fr" "$REPO/tools/run_mame.sh" "$s" \
            -autoboot_script "$REPO/tests/lua/read_tap.lua" > "$d/mame.log" 2>&1; rm -rf "$d/sb" ) < /dev/null
    else
        ( cd "$d" && SDL_AUDIODRIVER=dummy MAME_SANDBOX="$d/sb" MAME_ROMPATH="$rp" REPLAY="$R" POKES="$pk" FIELDS="ff8782:b:id" \
            FIELD_OUT="$d/f.txt" FIELD_FROM=2300 FIELD_TO="$fr" FRAMES="$fr" "$REPO/tools/run_mame.sh" "$s" \
            -autoboot_script "$REPO/tests/lua/field_trace.lua" -sound auto -wavwrite "$W/$t.$side.wav" > "$d/mame.log" 2>&1
          rm -rf "$d/sb" ) < /dev/null
    fi
}
cur tests/replays/naming/huitzil_1.rpl "D D D" > "$W/huitzil_1.ours.rpl"
cur tests/replays/naming/donovan_1.rpl "D D DR DR" > "$W/donovan_1.ours.rpl"
echo "== 1. the site's hits, both games, both tenants"
for t in huitzil donovan; do
    fr="$(python3 -c "import json;print(json.load(open('tests/replays/naming/${t}_1.json'))['frames'])")"
    leg $t native tap "$fr" & leg $t ours tap "$fr" &
done
wait
fail=0
for t in huitzil:10 donovan:13; do
    n=${t%%:*}; id=${t#*:}; echo "  -- $n"
    python3 tools/landing_sound_ab.py hits "tests/replays/naming/${n}_1.json" "$W/tap_$n.native.txt" "$W/tap_$n.ours.txt" "$id" > "$W/hits_$n.txt" 2>&1 || fail=1
    sed 's/^/  /' "$W/hits_$n.txt"
done
[ "$fail" = 0 ] || { echo "FAIL: audit_landing_sound (the hits)"; exit 1; }
echo "== 2. the first landing by ear: native against ours"
for n in huitzil donovan; do
    land="$(sed -n 's/^LANDING //p' "$W/hits_$n.txt")"; eval "LAND_$n=$land"
    leg $n native wav $((land + 120)) & leg $n ours wav $((land + 120)) &
done
wait
PL=""; vs_ctl_is same-landing && PL="--plant-same"
for t in huitzil:native donovan:ours; do
    n=${t%%:*}; lo=${t#*:}; eval "land=\$LAND_$n"; echo "  -- $n (the louder landing should be $lo's)"
    python3 tools/landing_sound_ab.py wav "$W/$n.native.wav" "$W/$n.ours.wav" "$land" $((land + 120)) "$lo" $PL || fail=1
done
if vs_ctl_is same-landing; then
    [ "$fail" = 1 ] && { echo "FAIL: audit_landing_sound (control mode: the planted same landing broke the gap)"; exit 1; }
    echo "FAIL: audit_landing_sound — the planted same landing still read as a gap"; exit 1
fi
echo "== 3. control"
python3 tools/landing_sound_ab.py wav "$W/huitzil.native.wav" "$W/huitzil.ours.wav" "$LAND_huitzil" $((LAND_huitzil + 120)) native --plant-same > "$W/ctl.txt" 2>&1
if grep -q 'MISMATCH' "$W/ctl.txt"; then vs_ctl_fired same-landing "$(grep -m1 MISMATCH "$W/ctl.txt" | sed 's/^ *//')"
else vs_ctl_dead same-landing "no MISMATCH on the planted window (a pass, or a crash: $(tail -1 "$W/ctl.txt" | cut -c1-100))"; fail=1; fi
[ "$fail" = 0 ] && echo "PASS: audit_landing_sound — the landing sound's big-body +1 falls on Phobos on vs2 and on Donovan on ours (#223)" \
                || echo "FAIL: audit_landing_sound"
exit "$fail"
