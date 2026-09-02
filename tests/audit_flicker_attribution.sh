#!/bin/sh
# audit_flicker_attribution.sh — WHY is each of these flicker frames in a
# frozen expectation? Re-derives the attribution instead of trusting the
# commit message that first made it.
#
# WHY (14z-91). The legacy-regression fix re-measured 139 specs, and two of
# them GAINED a flicker frame:
#
#   donovan-m7/41_don_altcolor_vsavj  +2313
#   donovan-m7/37_victor_ko_vsavj     +7168
#
# A gained frame is a claim about the build, and the rule this session
# worked to was that one is not written into a spec until it is attributed.
# Both attributed to the palette-fade STAGING BUFFER — the family at
# $FF3F02 + row*0x20, which docs/game/engine_internals.md ("The palette-fade
# staging buffer") records as display-only and transient because the
# destination venue's palette overwrites the staged rows. 41 lands in row
# 0x0C, which build/manifest/donovan.toml:862 documents this build patching
# (the P1 weapon-row march); 37 lands in row 0x0A.
#
# THAT ATTRIBUTION IS NOW LOAD-BEARING: it is the reason two `composite`
# specs carry a flicker frame rather than being root-caused. So it is a
# rerunnable measurement, not a sentence in a log. If the differing bytes
# ever move OUTSIDE the named windows, the specs are describing something
# else and must be re-opened.
#
# THE WINDOWS ARE NAMED, WHICH IS THE POINT. "The two builds differ, and
# that's expected" is the absence of a verdict. Every differing byte must
# fall in a window someone can name, and tools/attribute_ramdiff.py prints
# the strays when one does not.
#
# Usage: ROMDIR=... [MAME_BIN=...] [BUILD=build/don_m18] \
#          tests/audit_flicker_attribution.sh
# ~3 min (4 MAME runs, 2 legs x 2 replays).
#
# HANDOFF's gate-index note, moved into this header 14z-123 (verbatim; the
# documentation pass ruled a gate's WHY lives in the gate):
#   14z-91: WHY is each gained flicker frame in a frozen spec? The legacy re-
#   freeze added exactly two (donovan-m7 41 +2313, 37 +7168) and the rule was
#   that a gained frame is not written until it is attributed. Both are the
#   palette-fade STAGING BUFFER ($FF3F02 + row*0x20, display- only per
#   engine_internals): 41 in row 0x0C, which donovan.toml:862 documents this
#   build patching, and 37 in row 0x0A. Re-derives it via
#   tools/attribute_ramdiff.py against NAMED windows, so a byte landing
#   outside one re-opens the specs rather than widening a window. Also fails
#   on an IDENTICAL pair — these frames are in the specs BECAUSE they differ,
#   so identity means the rig died, not that the build improved. ~3 min, 4
#   MAME runs
set -eu
REPO="$(cd "$(dirname "$0")/.." && pwd)"; cd "$REPO"
ROMDIR="${ROMDIR:?set ROMDIR}"
MAME_BIN="${MAME_BIN:-$HOME/.cache/vampire-saved/mame/cps2}"; export MAME_BIN
BUILD="${BUILD:-build/don_m18}"  # re-pointed 14z-117b (random-select freeze) <- 14z-117  # re-pointed 14z-119 (physics-port freeze) <- 14z-117b
[ -f "$BUILD/rompath/vsavjw.zip" ] || { echo "SKIP: no $BUILD/rompath/vsavjw.zip"; exit 0; }
# The mask comes from the BUILD's own expectation set, resolved through
# registry.tsv (the #96 mechanism) — 14z-103: this was pinned to
# tests/expected/donovan-m7/mask, whose set dir no longer exists, so the
# audit had been SKIPping quietly while the m10 specs still carry both
# frozen frames (41: 2313; 37: 6962,7168).
SET="$(python3 tools/build_fingerprint.py "$BUILD/rompath;$ROMDIR" --set vsavjw 2>/dev/null)" \
    || { echo "FAIL: $BUILD's fingerprint is not in tests/expected/registry.tsv"; exit 1; }
MASKF="tests/expected/$SET/mask"
[ -f "$MASKF" ] || { echo "FAIL: no $MASKF (set resolved as $SET)"; exit 1; }
MASK="$(cat "$MASKF")"
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT
fail=0

# The named windows. The first four are the ratified mask (so they are
# invisible to the legacy comparison anyway); the last two are the staging
# rows this gate exists to pin.
WINDOWS="--window 043C-043D:qsound-handshake-latch
         --window 4182-41A2:masked-staging-row-0x14
         --window 41C2-41E2:masked-staging-row-0x16
         --window 4222-4262:masked-staging-rows-0x18-0x19
         --window 7F00-7FFF:dead-stack
         --window 4042-4061:staging-row-0x0A
         --window 4082-40A1:staging-row-0x0C"

# frozen (replay, frame, which row it must land in)
CASES="41_don_altcolor_vsavj:2313:staging-row-0x0C
       37_victor_ko_vsavj:7168:staging-row-0x0A"

for c in $CASES; do
    rpl="${c%%:*}"; rest="${c#*:}"; frame="${rest%%:*}"; want="${rest##*:}"
    echo "== $rpl frame $frame — expect the unmasked diff in $want =="
    mkdir -p "$W/van_$rpl" "$W/new_$rpl"
    DUMPS="$frame:ff0000-ffffff" MASK_RANGES="$MASK" MAME_ROMPATH="$ROMDIR" \
        tools/run_replay_mame.sh vsavj "tests/replays/$rpl.rpl" \
        "$W/van_$rpl/a.log" "$W/sbv_$rpl" >/dev/null 2>&1 &
    DUMPS="$frame:ff0000-ffffff" MASK_RANGES="$MASK" \
    MAME_ROMPATH="$PWD/$BUILD/rompath;$ROMDIR" \
        tools/run_replay_mame.sh vsavjw "tests/replays/$rpl.rpl" \
        "$W/new_$rpl/b.log" "$W/sbn_$rpl" >/dev/null 2>&1 &
    wait
    if [ ! -f "$W/van_$rpl/a.log" ] || [ ! -f "$W/new_$rpl/b.log" ]; then
        echo "  FAIL: a leg did not complete"; fail=1; continue
    fi
    out="$(python3 tools/attribute_ramdiff.py "$W/van_$rpl/a.log" \
             "$W/new_$rpl/b.log" "$frame" $WINDOWS 2>&1)" && st=0 || st=$?
    printf '%s\n' "$out" | sed 's/^/    /'
    if [ "$st" != 0 ]; then
        echo "  FAIL: a differing byte fell OUTSIDE every named window."
        echo "        The frozen specs that carry this flicker frame are"
        echo "        describing something other than the staging buffer —"
        echo "        re-open them rather than widening a window."
        fail=1
        continue
    fi
    # a zero-diff would make the attribution vacuous: the frame is in the
    # spec BECAUSE it differs, so an identical pair means the rig moved.
    if printf '%s' "$out" | grep -qi "identical\|0 differing"; then
        echo "  FAIL: the two legs are identical at f$frame — this frame is a"
        echo "        frozen flicker frame, so an identical pair means the rig"
        echo "        no longer reproduces it, not that the build improved."
        fail=1
        continue
    fi
    if printf '%s' "$out" | grep -q "$want"; then
        echo "  ok: attributed, and $want is among the windows hit"
    else
        echo "  FAIL: nothing landed in $want — the mechanism moved rows."
        fail=1
    fi
done

echo
[ "$fail" = 0 ] && echo "FLICKER ATTRIBUTION: PASS" || echo "FLICKER ATTRIBUTION: FAIL"
exit "$fail"
