#!/bin/sh
# audit_clone_beam_lines.sh — the GitHub #109 lock: Phobos' DF clone-mode
# attack must draw the BEAM-LINE sprites (effect-class row 31).
#
# THE MECHANISM (measured 14z-102, the whole chain on the issue): the
# clone attack spawns per-frame beam objects into the $FFD400 effect pool
# with class 31. vs2's effect-class table row 31 (0x0926E4) is the beam
# emitter — it builds the line composite (16x1+4x1 strips code raw
# 0x0CD0, pal 05, alternating-frame strobe = the visible beams). vsavj
# ships row 31 as a STUB (0x080B44), so on an unfixed build the objects
# EXIST, dispatch class 31 every frame of the mode (measured: constant
# slot reads at PC 0x080A9C, A0 = the stub), and draw nothing. The fix is
# the 14z-71 beam_effect_class16 pattern, second verse: port the row-31
# family (root 0x926e4:0x11e:t0x922f0) and point slot PRG:0x080B28 at it.
#
# TWO MODES (the #103-audit flip pattern; EXPECT_LINES follows the fix):
#   EXPECT_LINES=0  defect signature frozen: ZERO 16x1 entries in the
#                   whole beam window (the unfixed builds' measured state)
#   EXPECT_LINES=1  fix verification: >= MIN_LINES 16x1 line entries
#                   inside the beam window, at the native code family
#                   under our composition, pal 05
#
# MUST-FIRE CONTROL in both modes: the muzzle-burst set (code 4dd0,
# 6x2, pal 0a) must appear in the window — it is the part of the beam
# that ALWAYS drew, so its absence means the rig never produced the
# attack and the verdict would be about nothing (RH-15/RH-17).
#
# THE STROBE vs THE DUMP (the 14z-102 phase gotcha): the line objects are
# respawned on alternating frames and the dump reads the LIVE list while
# the screen shows the LATCHED one — so single-frame dumps miss them.
# This audit dumps EVERY frame of the window; do not "optimize" that.
#
# Usage: ROMDIR=... tests/audit_clone_beam_lines.sh [builddir]
set -eu
ROMDIR="${ROMDIR:?set ROMDIR}"
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
BUILD="${1:-build/m3b_merged16}"  # re-pointed 14z-110b
case "$BUILD" in /*) ;; *) BUILD="$REPO/$BUILD" ;; esac
[ -f "$BUILD/rompath/vsavjw.zip" ] || { echo "FAIL: no vsavjw.zip in $BUILD"; exit 1; }
EXPECT_LINES="${EXPECT_LINES:-1}"  # default flipped 14z-102: the row-31 fix is the shipped state
MIN_LINES="${MIN_LINES:-4}"
export MAME_BIN="${MAME_BIN:-$HOME/.cache/vampire-saved/mame/cps2}"
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT

# rig df/100's own poke set (its header); window = the measured first-attack
# beam frames on merged-m4 (entries live 3583-3599; dumped with margin)
PK="1400:ff8782:10;1450:ff8782:10;1500:ff8782:10;1400:ff8b82:03;1450:ff8b82:03;1500:ff8b82:03;3100:ff8509:03;3120:ff8509:03"
FR=$(python3 -c "print(','.join(str(f) for f in range(3576,3608)))")

REPLAY="$REPO/tests/replays/df/100_df_clone_beams.rpl" POKES="$PK" \
DUMP_FRAMES="$FR" FRAMES=3612 TRACE_OUT="$W/obj.txt" MAME_SANDBOX="$W/sbx" \
MAME_ROMPATH="$BUILD/rompath;$ROMDIR" \
tools/run_mame.sh vsavjw -autoboot_script "$REPO/tests/lua/obj_records_dump.lua" \
    > "$W/run.log" 2>&1 || { echo "FAIL: rig did not run"; tail -5 "$W/run.log"; exit 1; }

python3 - "$W/obj.txt" "$EXPECT_LINES" "$MIN_LINES" <<'PYEOF'
import sys
objtxt, expect, min_lines = sys.argv[1], int(sys.argv[2]), int(sys.argv[3])
burst = 0
lines = []
for line in open(objtxt):
    if not line.startswith('F') or ' B0 ' not in line: continue
    parts = dict(p.split('=') for p in line.split()[3:] if '=' in p)
    if parts.get('code') == '4dd0' and parts.get('sz') == '6x2':
        burst += 1
    if parts.get('sz') == '16x1':
        lines.append((line.split()[0], parts.get('code'), parts.get('pal'), parts.get('a19')))
print(f"  burst-control entries (4dd0 6x2): {burst}")
print(f"  16x1 line entries: {len(lines)}")
for fr, code, pal, a19 in lines[:8]:
    print(f"    {fr} code={code} pal={pal} a19={a19}")
if burst == 0:
    print("FAIL: must-fire control dead — the rig never produced the clone attack")
    sys.exit(1)
if expect == 0:
    if lines:
        print("FAIL: 16x1 line entries present but EXPECT_LINES=0 (defect signature broken"
              " — if the row-31 fix landed, flip EXPECT_LINES)")
        sys.exit(1)
    print("PASS: defect signature holds (beam lines absent; burst control fired)")
else:
    # two line families, measured on the fixed build 14z-102: the pal-05
    # 16x1 (raw 0x0CD0, native's 4ED0 twin) and the pal-0c 16x1 (raw
    # 0x0D90, the composite's second strip child)
    bad = [l for l in lines if l[2] not in ('05', '0c')]
    if len(lines) < min_lines:
        print(f"FAIL: expected >= {min_lines} line entries, got {len(lines)}")
        sys.exit(1)
    if bad:
        print(f"FAIL: line entries at wrong palette: {bad[:4]}")
        sys.exit(1)
    print("PASS: beam lines present at pal 05 (fix verified; burst control fired)")
PYEOF
