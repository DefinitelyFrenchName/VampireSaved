#!/bin/sh
# audit_don_lilith_ko.sh — A DONOVAN P1 DEATH IN ARCADE STALLS THE LOSE FLOW
# ~8,000 FRAMES (14z-97, GitHub #103). On-demand, ~5 min (2 MAME runs,
# parallel). The FILENAME keeps the Lilith pairing because that is the
# natural, poke-free repro this audit runs (Lilith is index 1 of Donovan's
# own ladder) — but the defect is NOT Lilith-specific; see the corrected
# controls below.
#
# THE DEFECT, measured on merged-m3 AND merged-m2 (so it predates the #101
# batch): P1 Donovan loses a round to CPU Lilith in arcade -> his HP
# underflows, he falls, Anita walks to his body, Lilith holds her win pose --
# and the round-end judge does not fire. The round timer FREEZES and the KO
# tableau holds for ~7,980 frames (~2 min 14 s) before some timeout path
# finally rescues it into the game-over flow. The normal lose flow, measured
# on the same rig, is 580 frames from KO to the stage word moving --
# IDENTICAL on the merged build and pristine vanilla for a legacy P1. So the
# player-visible symptom is a two-minute freeze after losing to Lilith, which
# any player reads as a hang and resets out of.
#
# NATIVE CONTROL (14z-97 (9)): vs2 walks the loser's +0x1C to EXACTLY the
# record our build parks on (0x287BA8 = our 0x0DB6D0) and CLEARS it at
# KO+240. ROOT-CAUSED 14z-98 (#103 comment): the round judge kills on the
# SIGN OF WHITE HP (+0x52); a pc-rel escape in Donovan's x026142 pins his
# hp to 1 with white ~200, so the next hit underflows hp while white stays
# positive — unjudgeable by construction. Kill-chain lock + PC attribution:
# tests/audit_don_ko_writer.sh. Fix = [[pcrel_escape_fix]] x026142 (probe-
# confirmed FLOWED 560); rides the re-freeze window.
#
# ("Never judges" was this audit's first wording, and it is RETRACTED: two
# stacked instrument artifacts -- a too-narrow field tuple and dumps ending
# inside the stall -- read the long stall as a permanent freeze. The
# wide-slice re-measure shows every run flowing on at ~KO+8000. The defect
# is the STALL.)
#
# FIELD-REACHABLE WITH NO POKES: Lilith sits at index 1 of Donovan's own
# ladder row, so "lose your second arcade match as Donovan" is the recipe.
#
# CONTROLS THAT BOUND IT (14z-97, all on the same rig):
#   Victor KO'd by Lilith   -> 580-frame lose flow (not "losing to Lilith")
#   ... on pristine vsavj   -> 580 frames, same    (vanilla never stalls here)
#   merged-m2 vs merged-m3  -> identical stall     (not a #101 regression)
#   Donovan KO'd by Q-Bee   -> ALSO PARKS UN-JUDGED 2,300+ frames on the
#                              same record (measured 14z-97 (9) on the
#                              +0x1C/HP-reset signal). This line FIRST said
#                              "judged fine" — RETRACTED: that verdict was
#                              read off ladder-mask movement under continuous
#                              100f-cadence HP pokes, instrument noise. The
#                              defect is OPPONENT-INDEPENDENT for Donovan
#                              (the mechanism fires from HIS OWN move —
#                              14z-98). "Phobos KO'd by Bishamon stalls
#                              too" is RETRACTED TO UNVERIFIED (14z-98
#                              (2)): that rig's HP poke may have
#                              manufactured the state itself — see
#                              audit_kill_poke_shape.sh. So the shape is
#                              "lose any round AS DONOVAN in arcade ->
#                              ~2-minute freeze", deterministic, NOT a
#                              race; Phobos awaits the maintainer's
#                              no-poke MAME retest.
# FBNeo: NOT reproduced and NOT clean -- the in-use mask is sound-state-fed
# ("the run-to-run lottery", ram.md), FBNeo's sound state differs, and its
# ladder routed around Lilith in both attempts. Unproduced, not negative.
#
# THIS AUDIT LOCKS THE DEFECT AS A REGRESSION MARKER (the #98/audit_hui_grunt
# discipline): leg A asserts the STALL IS STILL THERE on the current merged
# build, so the eventual fix flips this file knowingly rather than silently;
# leg B (Victor, same rig) asserts the instrument can tell a stall from the
# normal lose flow -- without it, leg A's verdict is unfalsifiable.
#
# THE SIGNAL is the gap from the first P1 HP underflow to the next change of
# the ladder stage word $FF8100 (the game-over transition moves it). Measured
# inventory: Donovan/Lilith 7,980; Victor/Lilith 580 on both merged and
# vanilla. Threshold 3000 -- over 5x the healthy flow, under half the stall.
#
# Usage: ROMDIR=... [MAME_BIN=...] [BUILD=build/m3b_merged10]
#        [EXPECT_STALL=1] tests/audit_don_lilith_ko.sh
#   EXPECT_STALL=0 rehearses the post-fix state: leg A's gap must then be
#   under the threshold like leg B's. Flip the default when the fix lands.
set -eu
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
ROMDIR="${ROMDIR:?set ROMDIR}"
BUILD="${BUILD:-build/m3b_merged10}"
[ -d "$BUILD/rompath" ] || { echo "SKIP: no build at $BUILD"; exit 0; }
MAME_BIN="${MAME_BIN:-$HOME/.cache/vampire-saved/mame/cps2}"
[ -x "$MAME_BIN" ] || { echo "SKIP: no WIDE MAME binary"; exit 0; }
export MAME_BIN
EXPECT_STALL="${EXPECT_STALL:-1}"

W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT
fail=0

# One source for the inputs: the committed marathon, truncated at f18000.
# The hang is fully established by ~f16000 and a full 40,620-frame run would
# triple the wall clock for nothing. Derived at run time, not committed — a
# second copy of 19k input lines is the drift class #48 was about.
RPL="$W/marathon_head.rpl"
awk -F'[- ]' '/^[0-9]/ { if ($1 + 0 > 18000) exit } { print }' \
    "$REPO/tests/replays/26_don_arcade_mash.rpl" > "$RPL"

run_leg() { # tag p1class
    d="$W/$1"; mkdir -p "$d/s1"
    PK="1704:ff8782:$2;1760:ff8782:$2;1900:ff8782:$2;2100:ff8782:$2;2400:ff8782:$2"
    DF="$(python3 -c "print(';'.join(f'{f}:ff8000-ff8180;{f}:ff8450-ff8456' for f in range(6000,17960,40)))")"
    ( cd "$d" && MAME_ROMPATH="$REPO/$BUILD/rompath;$ROMDIR" \
      POKES="$PK" DUMPS="$DF" GUARD_DEBUG=0 \
      "$REPO/tools/run_replay_guarded.sh" vsavjw "$RPL" out.log s1 >emu 2>&1 ) &
}
run_leg don 13
run_leg victor 03
wait

# classify <dir> -> "STALL <gap>" / "FLOWED <gap>" / "NO-KO" / "UNRESOLVED <floor>"
# gap = frames from the first P1 HP underflow to the next change of the
# ladder stage word $FF8100. UNRESOLVED (KO'd, stage never moved inside the
# dump window) counts as a stall at least as long as the window remainder.
classify() {
    python3 - "$1" <<'PY'
import glob, struct, re, sys
d = sys.argv[1]
frames = sorted(int(re.search(r'dump_(\d+)_ff8000', f).group(1))
                for f in glob.glob(f"{d}/dump_*_ff8000.bin"))
if not frames:
    print("NO-DATA"); sys.exit(0)
ko = ko_stage = resolved = None
for f in frames:
    b = open(f"{d}/dump_{f}_ff8000.bin", "rb").read()
    p1 = struct.unpack(">H", open(f"{d}/dump_{f}_ff8450.bin", "rb").read()[:2])[0]
    stage = struct.unpack(">H", b[0x100:0x102])[0]
    if p1 > 60000 and ko is None:
        ko, ko_stage = f, stage
    if ko is not None and resolved is None and stage != ko_stage:
        resolved = f
if ko is None:
    print("NO-KO")
elif resolved is None:
    print(f"UNRESOLVED {frames[-1] - ko} (KO @{ko}, stage never moved in-window)")
else:
    gap = resolved - ko
    print(f"{'STALL' if gap >= 3000 else 'FLOWED'} {gap} (KO @{ko} -> stage change @{resolved})")
PY
}

echo "== leg A: Donovan, natural mash, his own ladder reaches Lilith at idx 1"
A="$(classify "$W/don")"
echo "   $A"
echo "== leg B: Victor, same rig -- the instrument control"
B="$(classify "$W/victor")"
echo "   $B"

case "$B" in
FLOWED*) echo "  ok: control lose flow is under the threshold -- a stall is distinguishable" ;;
NO-KO)  echo "FAIL: the control leg produced no P1 KO -- the rig did not make the event"
        fail=1 ;;
*)  echo "FAIL: the CONTROL leg did not flow ($B) -- the classifier cannot be"
    echo "      trusted in either direction; fix the instrument first"
    fail=1 ;;
esac

if [ "$fail" = 0 ]; then
    if [ "$EXPECT_STALL" = 1 ]; then
        case "$A" in
        STALL*|UNRESOLVED*) echo "  ok: the stall is still present (expected until the fix lands -- #103)" ;;
        NO-KO) echo "FAIL: Donovan leg produced no P1 KO -- the rig did not make the event"; fail=1 ;;
        *)  echo "FAIL: Donovan leg FLOWED ($A) -- the stall is GONE. If a fix landed,"
            echo "      flip EXPECT_STALL's default and record the transition;"
            echo "      if none did, something moved unattributed (rule 6)."
            fail=1 ;;
        esac
    else
        case "$A" in
        FLOWED*) echo "  ok: Donovan leg flows -- the fix holds" ;;
        *)  echo "FAIL: still stalling ($A) -- the fix does not hold"; fail=1 ;;
        esac
    fi
fi

[ "$fail" = 0 ] && echo "AUDIT PASS (defect state as expected)" \
    || { echo "AUDIT FAIL"; exit 1; }
