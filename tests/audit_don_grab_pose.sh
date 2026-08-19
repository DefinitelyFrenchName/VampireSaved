#!/bin/sh
# audit_don_grab_pose.sh — THE #104 LOCK (14z-98): Victor's 6+HP headbutt
# grab holds a tenant victim on THE WRONG ANIM RECORD. On-demand, ~5 min
# (2 MAME runs, parallel: the build + native vsav2).
#
# THE REPORT (maintainer, MAME field test 2026-08-19): a tenant victim of
# Victor's headbutting grab shows a half-right/half-squished HORIZONTAL
# pose. Reproduced same-day on replay 96 (four grab connects per run) and
# capture-confirmed ours-vs-native. THE MEASURED MECHANISM LEVEL: during
# the hold (victim stationary ~150f, hp ticking -2 per headbutt), the
# victim's +0x1C parks on
#     native vsav2:  0x287418   (upright held pose)
#     ours (mapped): 0x287370   (placed anim copy; renders horizontal)
# and the release records mismatch too (0x2879C8 vs 0x2873A0) — NOT a
# uniform shift, so the record CONTENT is fine (ported byte-exact, #103
# work) and the SELECTION is wrong. Suspect class: engine-generation
# drift in victim-reaction ids (the electric-shake 0x18/0x0B vs 0x0C/0x04
# precedent, ram.md +0x5C). Full plan on GitHub #104.
#
# LEG A (the build) freezes the DEFECT: the held record must map to vs2
# source 0x287370 while EXPECT_MATCH=0 (the #98 discipline — flip to
# EXPECT_MATCH=1 when the fix lands: held must then map to 0x287418).
# LEG B (native vsav2) is the ANCHOR + rig control: its held record must
# be exactly 0x287418, and BOTH legs must actually produce the hold
# (stationary victim + ticking hp) or nothing here is a measurement.
#
# The ours->vs2 mapping is DERIVED from the build's own
# patch/placements.json anim row (never hardcoded — placements move at
# every re-freeze; the 14z-98 fix window will move them).
#
# Usage: ROMDIR=... [MAME_BIN=...] [BUILD=build/m3b_merged10]
#        [EXPECT_MATCH=0] tests/audit_don_grab_pose.sh
set -eu
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
ROMDIR="${ROMDIR:?set ROMDIR}"
BUILD="${BUILD:-build/m3b_merged10}"
[ -d "$BUILD/rompath" ] || { echo "SKIP: no build at $BUILD"; exit 0; }
[ -f "$BUILD/patch/placements.json" ] || { echo "SKIP: no placements.json in $BUILD"; exit 0; }
MAME_BIN="${MAME_BIN:-$HOME/.cache/vampire-saved/mame/cps2}"
[ -x "$MAME_BIN" ] || { echo "SKIP: no WIDE MAME binary"; exit 0; }
export MAME_BIN
EXPECT_MATCH="${EXPECT_MATCH:-0}"

W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT
fail=0

RPL="$REPO/tests/replays/96_don_victor_grab.rpl"
PKO="1200:ff8782:03;1300:ff8782:03;1400:ff8782:03;1500:ff8782:03;1700:ff8782:03;1900:ff8782:03;2100:ff8782:03;1200:ff8b82:13;1300:ff8b82:13;1400:ff8b82:13;1500:ff8b82:13;1700:ff8b82:13;1900:ff8b82:13;2100:ff8b82:13"
DF="$(python3 -c "print(';'.join(f'{f}:ff8810-ff8816;{f}:ff8850-ff8856;{f}:ff881c-ff8824' for f in range(2900,4700,10)))")"

run_leg() { # tag set rompath
    d="$W/$1"; mkdir -p "$d/sbx"
    ( cd "$d" && REPLAY="$RPL" POKES="$PKO" DUMPS="$DF" CHECKSUM_OUT="$d/out.log" \
      MAME_SANDBOX="$d/sbx" MAME_ROMPATH="$3" \
      "$REPO/tools/run_mame.sh" "$2" \
      -autoboot_script "$REPO/tests/lua/replay.lua" > "$d/mame.log" 2>&1 ) &
}
run_leg ours   vsavjw "$REPO/$BUILD/rompath;$ROMDIR"
run_leg native vsav2  "$ROMDIR"
wait

# held_record <dir>: the modal +0x1C during the FIRST hold window
# (victim X stationary >= 100f while hp drops >= 3 times).
held_record() {
    python3 - "$1" <<'PY'
import glob, struct, re, sys, collections
d = sys.argv[1]
frames = sorted(int(re.search(r'dump_(\d+)_ff8850', f).group(1))
                for f in glob.glob(f"{d}/dump_*_ff8850.bin"))
if not frames:
    print("DEAD"); sys.exit(0)
rows = []
for f in frames:
    hp = struct.unpack(">H", open(f"{d}/dump_{f}_ff8850.bin","rb").read()[:2])[0]
    x  = struct.unpack(">H", open(f"{d}/dump_{f}_ff8810.bin","rb").read()[:2])[0]
    a  = struct.unpack(">I", open(f"{d}/dump_{f}_ff881c.bin","rb").read()[:4])[0]
    rows.append((f, hp, x, a))
# scan for a 10-sample (100f) window: victim near its held spot (x range
# <= 48px) with >= 2 hp drops. THE 48 IS MEASURED, NOT SLACK: the held
# victim SHAKES with each headbutt impact and the amplitude is
# PER-VICTIM — Donovan 874 <-> 906 (32px), Pyron 886 <-> 929 (43px) —
# so a tight window reads real native holds as NO-HOLD (the first two
# drafts, 0px then 4px, did exactly that; a 40px third draft missed
# native-Pyron by 3px). Ours sits rigidly still on the wrong record —
# the missing shake is itself part of the #104 symptom. Safe in THIS
# rig only because P2 is idle and the grab is the sole hp-dropping
# event; do not copy this window into a rig with other contacts.
for i in range(len(rows) - 10):
    win = rows[i:i+10]
    xs = [r[2] for r in win]
    drops = sum(1 for a, b in zip(win, win[1:]) if b[1] < a[1])
    if max(xs) - min(xs) <= 48 and drops >= 2:
        modal = collections.Counter(r[3] for r in win).most_common(1)[0][0]
        print(f"HELD {modal:#010x} at f{win[0][0]}")
        sys.exit(0)
print("NO-HOLD")
PY
}

A="$(held_record "$W/ours")";   echo "== leg A (build):  $A"
B="$(held_record "$W/native")"; echo "== leg B (native): $B"

# the build's anim placement, derived from its own placements.json
MAP="$(python3 - "$BUILD/patch/placements.json" <<'PY'
import json, sys
pl = json.load(open(sys.argv[1]))
r = pl["regions"]["anim"]
print(f"{r['dst']} {r['src']}")
PY
)"
DST="${MAP%% *}"; SRC="${MAP##* }"

case "$B" in
"HELD 0x00287418"*) echo "  ok: native anchor holds 0x287418 (the upright held pose)" ;;
NO-HOLD|DEAD) echo "FAIL: native leg produced no hold — the rig did not make the event"; fail=1 ;;
*) echo "FAIL: native held record moved ($B) — the anchor is wrong or vs2 changed; re-derive"; fail=1 ;;
esac

if [ "$fail" = 0 ]; then
    OURS_SRC="$(python3 -c "
a = int('${A#HELD }'.split()[0], 16) if '${A}'.startswith('HELD') else 0
print(f'{a - $DST + $SRC:#x}' if a else 'none')")"
    echo "   ours held maps to vs2 src $OURS_SRC (anim dst=$DST src=$SRC)"
    if [ "$EXPECT_MATCH" = 0 ]; then
        case "$OURS_SRC" in
        0x287370) echo "  ok: the frozen defect shape (wrong record 0x287370) is still present — #104 open" ;;
        0x287418) echo "FAIL: ours now matches native — if a fix landed, flip EXPECT_MATCH's"
                  echo "      default and record it; if none did, rule 6"; fail=1 ;;
        *) echo "FAIL: ours held record moved to $OURS_SRC — neither the frozen defect nor"
           echo "      the fix; re-measure before trusting anything"; fail=1 ;;
        esac
    else
        case "$OURS_SRC" in
        0x287418) echo "  ok: ours holds the same record as native — the fix holds" ;;
        *) echo "FAIL: still the wrong record ($OURS_SRC) — the fix does not hold"; fail=1 ;;
        esac
    fi
fi

[ "$fail" = 0 ] && echo "AUDIT PASS (defect state as expected)" \
    || { echo "AUDIT FAIL"; exit 1; }
