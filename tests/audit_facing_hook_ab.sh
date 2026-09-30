#!/bin/sh
# audit_facing_hook_ab.sh — #159'S FACING HOOK SPLIT INTO ITS CYCLES AND ITS LOGIC: which of the two moved each of its side moves (GitHub #186, 14z-186).
#
# WHAT: #159 routes vsavj's facing resolver's fall-through (CPU:$01886C) through a `jmp` to a thunk that adds vs2's
#   rule 5. The M21 freeze that landed it moved two things outside the Summon it fixes: Pyron's mash ring stream on the
#   merged build (tests/audit_pyron_ring.sh: it diverged from solo at f4742, and now agrees for the whole run) and
#   110_don_arcade_mash's defense reads (tests/audit_defense_row_reads.sh's suite leg, from f8394). This gate says WHICH
#   PART of the hook moves each: executing the hook (its cycles) or the rule-5 branch (its logic).
# HOW: two probe variants of the merged build, made by tools/facing_hook_ab.py FROM THE BUILD'S OWN patch.json (the
#   thunk found through the hook's `jmp`, so the placement is the build's): `logicoff` (the thunk's `cmpi.b #5,d0` made
#   `cmpi.b #$FF,d0` — the hook runs, rule 5 is never taken) and `unhooked` (the site op dropped — the thunk placed,
#   the site pristine), plus `ctl` (the patch unfiltered, whose program must equal the build's). Each variant is read
#   back from its decrypted opcode view. Ten MAME runs: Pyron's mash ring stream (tests/lua/ring_tap.lua, the ring gate's
#   pokes and length) on the build, both variants and solo Pyron; a write tap on both fighters' +0x5C word (the +0x5D
#   facing byte, by writer PC: the fall-through eor or the rule-5 store) on the mash and on 110_don_arcade_mash, the
#   latter with the defense gate's own read tap (its RTAP ranges and RPCS pcs) in the same run, 9000 frames.
# EXPECTS: THE READING — Pyron mash: the build and `logicoff` agree with solo for the whole run while `unhooked` diverges,
#   and rule 5 never fires on it (so the hook's EXECUTION moves it, not its logic and not the placement);
#   110_don_arcade_mash: `logicoff` reads the same defense rows and writes the same facing bytes as `unhooked`, and the
#   build's first facing write that differs from them is a rule-5 store (so the rule-5 LOGIC moves it); every row
#   equal to tests/expected/facing_hook_ab.tsv; every control fails.
# FOLLOWS: build/manifest/ emu/mame-patches/ tests/expected/facing_hook_ab.tsv tests/lib/controls.sh
#   tests/lua/read_tap.lua tests/lua/ring_tap.lua tests/replays/110_don_arcade_mash.rpl tests/replays/pyron/70_pyron_mash.rpl
#   tools/audit_roms.py tools/build_fingerprint.py tools/cps2_decrypt.py tools/facing_hook_ab.py tools/patch_prg.py tools/run_mame.sh
#   tools/setup_mame.sh
#
# MUST-FIRE: perturbed-copy: variant-inert — the `logicoff` variant built WITHOUT its edit (the thunk left as the build's) must fail the check that its thunk reads `cmpi.b #$FF,d0`, so the variant the reading rests on is proven to be the variant built (in-gate: an unedited copy is built beside the real ones and must fail that check; mode: the real `logicoff` is built unedited and the gate FAILs)
# MUST-FIRE: perturbed-copy: stream-shifted — `logicoff`'s mash ring stream with its middle event moved a frame earlier must break its whole-run agreement with solo, so "agrees with solo" is a comparison that can fail (in-gate: the shifted copy must be caught; mode: the real stream is shifted and the gate FAILs)
# MUST-FIRE: perturbed-copy: read-dropped — `unhooked`'s defense-read stream with its middle read deleted must break "logicoff reads what unhooked reads", so that identity is read read by read (in-gate: the copy must be caught; mode: the real stream loses the read and the gate FAILs)
# MUST-FIRE: perturbed-copy: r5-planted — the build's mash facing writes with one fall-through write relabelled a rule-5 store must fail "rule 5 never fires on the mash", so that absence is read from the rule-5 store's PC (in-gate: the planted copy must be caught; mode: the real writes carry the plant and the gate FAILs)
#
# NOT COVERED: WHY the hook's cycles move the mash stream frame by frame — the marginal frame and the event it pushes
#   across a boundary ([VSP-39]) are not located; the mash and the arcade replay only (the corpus's other replays are the
#   M21 freeze's battery); MAME only; the reading holds at the build under test and each replay's length here (8400,
#   9000 frames); the variants swap PROGRAM members only (the build's graphics and sound members are copied).
#
# Usage: ROMDIR=... [MAME_BIN=...] [BUILD=build/m3b_merged29] [SOLO=build/pyron44] [JOBS=5] [FREEZE=1] [KEEP=<dir>] tests/audit_facing_hook_ab.sh
#   emulator tier, MAME; ~6 min at JOBS=5 (10 runs)
set -eu
[ -n "${ROMDIR:-}" ] || { echo "FAIL: set ROMDIR"; exit 1; }
[ -d "$ROMDIR" ] && ROMDIR="$(cd "$ROMDIR" && pwd)"
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
MAME_BIN="${MAME_BIN:-$HOME/.cache/vampire-saved/mame/cps2}"; export MAME_BIN
BUILD="${BUILD:-build/m3b_merged29}"; case "$BUILD" in /*) ;; *) BUILD="$REPO/$BUILD" ;; esac
SOLO="${SOLO:-build/pyron44}"; case "$SOLO" in /*) ;; *) SOLO="$REPO/$SOLO" ;; esac
JOBS="${JOBS:-5}"
EXPECT="$REPO/tests/expected/facing_hook_ab.tsv"
. "$REPO/tests/lib/controls.sh"
vs_ctl_mode "$0"
[ -x "$MAME_BIN" ] || { echo "SKIP: no MAME at $MAME_BIN"; exit 0; }
[ -f "$ROMDIR/vsavj.zip" ] || { echo "SKIP: no vsavj.zip in $ROMDIR"; exit 0; }
[ -f "$BUILD/rompath/vsavjw.zip" ] && [ -f "$BUILD/patch/patch.json" ] || { echo "SKIP: no merged build with its patch at $BUILD"; exit 0; }
[ -f "$SOLO/rompath/vsavjw.zip" ] || { echo "SKIP: no solo Pyron build at $SOLO"; exit 0; }
python3 tools/audit_roms.py "$ROMDIR" > /dev/null || { echo "FAIL: ROM audit (CLAUDE.md §3)"; exit 1; }
if [ -n "${KEEP:-}" ]; then W="$KEEP"; mkdir -p "$W"; else W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT INT TERM; fi
W="$(cd "$W" && pwd)"
echo "== audit_facing_hook_ab: build $BUILD ($(python3 tools/build_fingerprint.py --set vsavjw --sha-only "$BUILD/rompath" 2>/dev/null || echo ?)), solo $SOLO"

_inert=""; vs_ctl_is variant-inert && _inert=--inert
python3 tools/facing_hook_ab.py variants "$BUILD" "$W" "$ROMDIR/vsavj.zip" $_inert
python3 tools/facing_hook_ab.py variants "$BUILD" "$W/inert" "$ROMDIR/vsavj.zip" --inert > "$W/inert.log"

PK="1400:ff8782:11;1450:ff8782:11;1500:ff8782:11;3000:ff8509:03;3020:ff8509:03"   # the ring gate's pokes (P2's forced pick, the meter)
leg() {  # leg <dir> <rompath dir> <kind ring|mash|arc110>
    _d="$W/$1"; mkdir -p "$_d"
    case $3 in
    ring)   ( cd "$_d" && MAME_SANDBOX="$_d/sb" MAME_ROMPATH="$2/rompath;$ROMDIR" POKES="$PK" \
                REPLAY="$REPO/tests/replays/pyron/70_pyron_mash.rpl" FRAMES=8400 TRACE_OUT="$_d/ring.txt" \
                "$REPO/tools/run_mame.sh" vsavjw -autoboot_script "$REPO/tests/lua/ring_tap.lua" > "$_d/mame.log" 2>&1 ) ;;
    mash)   ( cd "$_d" && MAME_SANDBOX="$_d/sb" MAME_ROMPATH="$2/rompath;$ROMDIR" POKES="$PK" \
                RTAP="ff845c,2;ff885c,2" WINDOW="0,0" \
                REPLAY="$REPO/tests/replays/pyron/70_pyron_mash.rpl" FRAMES=8400 TRACE_OUT="$_d/t.tap" \
                "$REPO/tools/run_mame.sh" vsavjw -autoboot_script "$REPO/tests/lua/read_tap.lua" > "$_d/mame.log" 2>&1 ) ;;
    arc110) ( cd "$_d" && MAME_SANDBOX="$_d/sb" MAME_ROMPATH="$2/rompath;$ROMDIR" POKES="" \
                RTAP="ff8782,2;ff8b82,2;ff8460,4;ff8860,4;ff845c,2;ff885c,2" RPCS="018c10,018c78,018c40" \
                REPLAY="$REPO/tests/replays/110_don_arcade_mash.rpl" FRAMES=9000 TRACE_OUT="$_d/t.tap" \
                "$REPO/tools/run_mame.sh" vsavjw -autoboot_script "$REPO/tests/lua/read_tap.lua" > "$_d/mame.log" 2>&1 ) ;;
    esac
    rm -rf "$_d/sb"
}
i=0
for spec in ring_build:"$BUILD":ring ring_logicoff:"$W/v_logicoff":ring ring_unhooked:"$W/v_unhooked":ring ring_solo:"$SOLO":ring \
            tap_mash_build:"$BUILD":mash tap_mash_logicoff:"$W/v_logicoff":mash tap_mash_unhooked:"$W/v_unhooked":mash \
            tap_arc110_build:"$BUILD":arc110 tap_arc110_logicoff:"$W/v_logicoff":arc110 tap_arc110_unhooked:"$W/v_unhooked":arc110; do
    n="${spec%%:*}"; rest="${spec#*:}"; b="${rest%:*}"; k="${rest##*:}"
    leg "$n" "$b" "$k" </dev/null &
    i=$((i + 1)); [ $((i % JOBS)) = 0 ] && wait
done
wait

fail=0
_fz=""; [ -n "${FREEZE:-}" ] && [ -z "${VS_CTL:-}" ] && _fz=--freeze
python3 tools/facing_hook_ab.py check "$W" "$EXPECT" --control "${VS_CTL:-}" $_fz || fail=1

if [ -n "${VS_CTL:-}" ]; then
    if [ "$fail" = 1 ]; then vs_ctl_fired "$VS_CTL" "the perturbed real input fails the gate"; echo "FAIL: audit_facing_hook_ab (control mode)"; exit 1
    else vs_ctl_dead "$VS_CTL" "the perturbed real input still passed" || true; echo "FAIL: audit_facing_hook_ab"; exit 1; fi
fi
if [ "$fail" = 0 ]; then echo "PASS: audit_facing_hook_ab"; else echo "FAIL: audit_facing_hook_ab"; exit 1; fi
