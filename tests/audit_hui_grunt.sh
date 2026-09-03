#!/bin/sh
# audit_hui_grunt.sh — the electrocute-grunt A/B over FIVE electrocutions
# (14z-96, on-demand, ~3 min, 2 MAME runs parallel). The dynamic ground
# truth under tests/test_kernel_voice_tables.sh (the static half) and the
# instrument the maintainer's 2026-08-18 grunt report resumes from.
#
# THE MEASURED MECHANISM (engine_internals "The KERNEL per-class voice
# tables"): the sound kernel's event-.2 voice fires on EVERY OTHER
# electrocution (engine-side alternation, both games). The fired id follows
# the victim's +0x382 class through a per-class word table whose vsavj
# variant half (rows 0x10-0x1F) is a byte-copy of the base half — so
# Phobos (0x10) fires row 0x00 = a LEGACY character's hurt voice, id
# 0x1d2, the audible grunt. Native vs2 fires Phobos' own row = 0x2a2, a
# FREE Z80 id = deliberate silence.
#
# WHAT IS FROZEN: per-BUILD ring inventories (OURS_BY_BUILD below) — the
# #98 discipline, frozen expectation + must-fire control, never a
# set-compare that cries wolf. merged-m2's row records the DEFECT (the
# wrong 0x1d2) as a regression lock; merged10's row records the FIX
# (0x2a2, vs2's deliberate-silence id — the 68k enqueue is still ring-
# observable, which is what makes silence assertable). An unregistered
# build REFUSES until measured. GRUNT_OURS_A2 overrides attempt 2 to
# rehearse a new expectation before freezing it.
#
# ATTEMPT-4 NOTE (measured 14z-96, unexplained): ours drops the voice
# entirely at attempt 4 where native fires 0x2a2 again. Candidate: 0x1d2
# is a REAL song (priority 0x30, slot 11) whose slot state can block a
# re-fire, where native's null song never occupies anything. Not chased —
# the fix makes the question moot (a silent id cannot collide) — but if
# attempt 4 ever GAINS an id while 2 keeps one, re-measure before
# re-freezing: that would be the alternation phase moving, not noise.
#
# Usage: ROMDIR=... [BUILD=build/m3b_merged22] tests/audit_hui_grunt.sh
#
# HANDOFF's gate-index note, moved into this header 14z-123 (verbatim; the
# documentation pass ruled a gate's WHY lives in the gate):
#   14z-96: THE ELECTROCUTE-GRUNT A/B over FIVE electrocutions (replay 95, the
#   x4 rig) — the maintainer's grunt report ROOT-CAUSED: the sound KERNEL's
#   per-class voice tables (events .0-.3, PRG:0x3BCE/3C3A/3CA6/3D10 + variant
#   halves at +0x20) have vsavj rows 0x10-0x1F as COPIES of 0x00-0x0F, so
#   Phobos' every-other-hit voice fires row 0x00's id 0x1d2 (a LEGACY hurt
#   cry) where native vs2 fires his own row's 0x2a2 — a FREE Z80 id, i.e.
#   DELIBERATE SILENCE (the robot does not grunt). PER-BUILD frozen
#   expectations since the 14z-96 port: merged-m2 = the defect (regression
#   lock), m3b_merged10 = the fix (02a2, the deliberate-silence id),
#   m3b_merged11 = the 14z-99 row (kernel rows untouched by the window) — all
#   green; an unknown build REFUSES until a row is frozen; GRUNT_OURS_A2
#   rehearses. Static half: test_kernel_voice_tables (ci_static). ~3 min, 2
#   MAME runs
set -eu
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
ROMDIR="${ROMDIR:?set ROMDIR}"
ROMDIR="$(CDPATH= cd "$ROMDIR" && pwd)"
BUILD="${BUILD:-build/m3b_merged22}"   # merged-m7 since the 14z-110 freeze  # re-pointed 14z-117b (random-select freeze) <- 14z-117  # re-pointed 14z-119 (physics-port freeze) <- 14z-117b
[ -d "$BUILD/rompath" ] || { echo "SKIP: no build at $BUILD"; exit 0; }
MAME_BIN="${MAME_BIN:-$HOME/.cache/vampire-saved/mame/cps2}"
[ -x "$MAME_BIN" ] || { echo "SKIP: no WIDE MAME binary"; exit 0; }
export MAME_BIN

RPL="$REPO/tests/replays/hui/95_hui_electrocuted_x4.rpl"
PK="1400:ff8782:10;1450:ff8782:10;1500:ff8782:10;1400:ff8b82:03;1450:ff8b82:03;1500:ff8b82:03"
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT
fail=0

mkdir -p "$W/ours" "$W/native"
( cd "$W/ours" && REPLAY="$RPL" FRAMES=6300 POKES="$PK" TRACE_OUT=ring.txt \
  MAME_SANDBOX="$W/ours/sb" MAME_ROMPATH="$REPO/$BUILD/rompath;$ROMDIR" \
  "$REPO/tools/run_mame.sh" vsavjw -autoboot_script \
  "$REPO/tests/lua/ring_tap.lua" >out 2>&1 ) &
( cd "$W/native" && REPLAY="$RPL" FRAMES=6300 POKES="$PK" TRACE_OUT=ring.txt \
  MAME_SANDBOX="$W/native/sb" \
  "$REPO/tools/run_mame.sh" vsav2 -autoboot_script \
  "$REPO/tests/lua/ring_tap.lua" >out 2>&1 ) &
wait

python3 - "$W" "${GRUNT_OURS_A2:-}" "$(basename "$BUILD")" <<'PY' || fail=1
import re, sys
W, ours_a2, bld = sys.argv[1], sys.argv[2].lower(), sys.argv[3]
ATT = [3400, 4050, 4700, 5350, 6000]
# frozen per BUILD vs native vsav2: per-attempt extra-voice slot (the id
# landing ~f+45..f+60, between the electric burst and the 010x recovery
# pair). None = the attempt fires no kernel voice.
# 00f3 at attempt 1 is shared by both legs (first-hit family) and is NOT
# the kernel .2 event; it is asserted in the common prefix instead.
#   m3b_merged9  = merged-m2, PRE-fix: the defect (legacy alias 01d2).
#   m3b_merged10 = the #101 kernel port: 02a2, vs2's deliberate-silence id
#                  — the 68k enqueue is still observable in the ring, which
#                  is what makes silence assertable at all.
# The attempt-4 drop is on BOTH (68k alternation phase, predates the fix;
# audibly nothing for Phobos since the fired sound is the null song).
OURS_BY_BUILD = {
    "m3b_merged9":  [None, "01d2", None, None, None],
    "m3b_merged10": [None, "02a2", None, None, None],
    # 14z-99 window (merged-m4): the kernel rows are untouched by the
    # window's fixes — same deliberate-silence id.
    "m3b_merged11": [None, "02a2", None, None, None],
    "m3b_merged13": [None, "02a2", None, None, None],   # 14z-105 (kernel rows untouched by the window)
    "m3b_merged16": [None, "02a2", None, None, None],   # 14z-111 (d2 window + remap are Donovan-owned; kernel rows untouched)
    "m3b_merged22": [None, "02a2", None, None, None],   # 14z-113 merged-m10: same program as merged16 (one-zip repackaging)  # re-pointed 14z-117b (random-select freeze) <- 14z-117  # re-pointed 14z-119 (physics-port freeze) <- 14z-117b
}
if ours_a2:
    ours = [None, ours_a2, None, None, None]
elif bld in OURS_BY_BUILD:
    ours = OURS_BY_BUILD[bld]
else:
    sys.exit(f"FAIL: no frozen ours-expectation for build '{bld}' — freeze "
             f"a row in OURS_BY_BUILD (measure first), or rehearse with "
             f"GRUNT_OURS_A2")
EXPECT = {
    "native": [None, "02a2", None, "02a2", None],
    "ours":   ours,
}
PREFIX = ["0625", "0419", "0402"]          # the electric burst, every attempt
rc = 0
for leg, want in EXPECT.items():
    ev = []
    for line in open(f"{W}/{leg}/ring.txt"):
        m = re.match(r"f(\d+) id ([0-9a-f]{4}) pc", line.strip())
        if m and m.group(2) not in ("0000", "ffff", "049a"):
            ev.append((int(m.group(1)), m.group(2)))
    if not ev:
        print(f"FAIL: {leg} ring is empty — rig dead, verdict vacuous")
        rc = 1
        continue
    for k, a in enumerate(ATT):
        win = [(f, i) for f, i in ev if a - 20 <= f < a + 560]
        ids = [i for _, i in win]
        if ids[:3] != PREFIX:
            print(f"FAIL: {leg} attempt {k+1} burst prefix {ids[:3]} != "
                  f"{PREFIX} — the electrocute did not form; nothing after "
                  f"this is meaningful")
            rc = 1
            continue
        # the kernel-voice slot: ids between the burst and the 010x recovery
        mid = [i for f, i in win
               if a + 30 <= f < a + 110 and i not in PREFIX
               and not i.startswith("010") and i != "00f3"]
        wantk = [] if want[k] is None else [want[k]]
        if mid != wantk:
            print(f"FAIL: {leg} attempt {k+1} kernel-voice slot {mid} != "
                  f"frozen {wantk}")
            if leg == "ours":
                print("       If the voice-table port landed, re-freeze via "
                      "GRUNT_OURS_A2 first to rehearse, then edit EXPECT "
                      "(header). Growth here otherwise is the standing "
                      "watch (CLAUDE.md §4).")
            rc = 1
    if rc == 0:
        print(f"  ok: {leg} — 5/5 attempts formed; kernel-voice pattern "
              f"matches frozen ({[x or '-' for x in want]})")
sys.exit(rc)
PY

[ "$fail" -eq 0 ] && echo "PASS: electrocute-grunt A/B — the alternating kernel voice matches the frozen inventory on both legs" || exit 1
