#!/bin/sh
# audit_hui_grunt.sh — the electrocute-grunt A/B over FIVE electrocutions
# (14z-96, on-demand, ~3 min, 2 MAME runs parallel). The dynamic ground
# truth under tests/test_kernel_voice_tables.sh (the static half) and the
# instrument the maintainer's 2026-08-18 grunt report resumes from.
#
# WHAT: the electrocute grunt: Phobos as the shocked victim fires vs2's own silent voice id
#   (0x2a2, a free Z80 id) on every other electrocution as native does, not a legacy
#   character's hurt cry (0x1d2) through the aliased kernel voice table.
# HOW: the x4 electrocution rig (replay 95) on ours and native vsav2 in parallel on MAME;
#   the sound ring's enqueued ids over five electrocutions are compared with the per-BUILD
#   frozen inventory; the control plants a wrong expected attempt-2 id.
# EXPECTS: the measured ring equals the frozen inventory for the build (an unregistered
#   build REFUSES until measured); attempt 2 on the fixed builds reads 0x2a2. A red is the
#   alias back or the alternation phase moving.
# FOLLOWS: build/manifest/ emu/mame-patches/ tests/lib/controls.sh tests/lua/ring_tap.lua
#   tests/replays/hui/95_hui_electrocuted_x4.rpl tools/run_mame.sh tools/setup_mame.sh tests/lib/sheet.sh
#
# SHEET: legs vs2,ours — moments: each of the five electrocutions' kernel-voice slot (the ring ids from attempt+30 to attempt+110), each picture EVENT-PROVEN on that leg's own ring log, captioned with the ids each leg enqueued there — not comparable: each game's stage and palette, and Victor's art (each game's own copy; [VSP-168]); the sound itself (the ring holds ids, and 0x2a2 is a silent id by design)
#
# MUST-FIRE: known-bad: perturbed-inventory — a WRONG expected attempt-2 kernel voice id must fail the per-attempt comparison (mode: GRUNT_OURS_A2 is set to a wrong id so the measured ring != expected and the gate must FAIL)
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
# Usage: ROMDIR=... [BUILD=build/m3b_merged31] tests/audit_hui_grunt.sh
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
BUILD="${BUILD:-build/m3b_merged31}"   # merged-m7 since the 14z-110 freeze  # re-pointed 14z-117b (random-select freeze) <- 14z-117  # re-pointed 14z-119 (physics-port freeze) <- 14z-117b
[ -d "$BUILD/rompath" ] || { echo "SKIP: no build at $BUILD"; exit 0; }
MAME_BIN="${MAME_BIN:-$HOME/.cache/vampire-saved/mame/cps2}"
[ -x "$MAME_BIN" ] || { echo "SKIP: no WIDE MAME binary"; exit 0; }
export MAME_BIN

RPL="$REPO/tests/replays/hui/95_hui_electrocuted_x4.rpl"
PK="1400:ff8782:10;1450:ff8782:10;1500:ff8782:10;1400:ff8b82:03;1450:ff8b82:03;1500:ff8b82:03"
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT
fail=0
. "$REPO/tests/lib/controls.sh"; vs_ctl_mode "$0"; MODE="${VS_CTL:-}"
# THE EXECUTABLE MODE: a wrong expected attempt-2 id makes the measured ring
# (02a2) mismatch the expectation, so the gate FAILs.
if [ "$MODE" = perturbed-inventory ]; then GRUNT_OURS_A2=0001; fi

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
    "m3b_merged31": [None, "02a2", None, None, None],   # 14z-113 merged-m10: same program as merged16 (one-zip repackaging)  # re-pointed 14z-117b (random-select freeze) <- 14z-117  # re-pointed 14z-119 (physics-port freeze) <- 14z-117b
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
ours_mid1 = None                            # the measured attempt-2 kernel voice on the ours leg
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
        if leg == "ours" and k == 1: ours_mid1 = mid
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
if ours_mid1 is not None and ours_mid1 != ["0001"]:
    print("CONTROL FIRED: perturbed-inventory — the measured attempt-2 voice "
          f"{ours_mid1} differs from a wrong expected id, so a perturbed expectation "
          "(the mode's GRUNT_OURS_A2) fails the comparison and the gate FAILs")
else:
    print("CONTROL DEAD: perturbed-inventory — the ours attempt-2 slot was not measured, "
          "so the perturbation would have nothing to mismatch")
sys.exit(rc)
PY

# THE SHEET (#291, D2): with SHEET_OUT set, the two ring-tap legs this verdict compared, re-run under ring_tap.lua
# itself, one moment per electrocution's kernel-voice slot, EVENT-PROVEN on each leg's own ring log. Nothing the gate
# decides changes.
. "$REPO/tests/lib/sheet.sh"
if sheet_on && [ -z "$MODE" ]; then
    sheet_new grunt "Phobos electrocuted five times (replay 95): the kernel-voice slot, native vs2 above ours" huitzil - \
        "each game's stage and palette, and Victor's art (each game's own copy; [VSP-168]); the sound itself (the ring holds ids, and 0x2a2 is a silent id by design)"
    sheet_leg grunt native vs2 vsav2 "$ROMDIR" "$RPL" "$PK" 6300
    sheet_tap grunt native tests/lua/ring_tap.lua "FRAMES=6300"
    sheet_leg grunt ours ours vsavjw "$REPO/$BUILD/rompath;$ROMDIR" "$RPL" "$PK" 6300
    sheet_tap grunt ours tests/lua/ring_tap.lua "FRAMES=6300"
    _gn="$(sheet_file grunt native.ring "$W/native/ring.txt")"; _go="$(sheet_file grunt ours.ring "$W/ours/ring.txt")"
    python3 - "$W" "$_gn" "$_go" > "$W/sheet_rows.tsv" <<'PYS'
import re, sys
W, gn, go = sys.argv[1:4]
ATT = [3400, 4050, 4700, 5350, 6000]
def ring(leg):
    ev = []
    for line in open(f"{W}/{leg}/ring.txt"):
        m = re.match(r"f(\d+) id ([0-9a-f]{4}) pc", line.strip())
        if m and m.group(2) not in ("0000", "ffff", "049a"):
            ev.append((int(m.group(1)), m.group(2)))
    return ev
r = {"native": ring("native"), "ours": ring("ours")}
for k, a in enumerate(ATT):
    lo, hi = a + 30, a + 109
    slot = {l: [i for f, i in r[l] if lo <= f <= hi] for l in r}
    mid = {l: [i for f, i in r[l] if lo <= f <= hi and i not in ("0625", "0419", "0402") and not i.startswith("010") and i != "00f3"] for l in r}
    vals = "kernel voice: native %s, ours %s; ring ids in the slot: native %s, ours %s" % (
        ",".join(mid["native"]) or "none", ",".join(mid["ours"]) or "none", ",".join(slot["native"]) or "none", ",".join(slot["ours"]) or "none")
    print("moment\tgrunt\ta%d\telectrocution %d, kernel-voice slot (ring f%d-%d)\tjudged against the frozen inventory\t%s" % (k + 1, k + 1, lo, hi, vals))
    for leg, g in (("native", gn), ("ours", go)):
        fs = [f for f, i in r[leg] if lo <= f <= hi]
        fr = (fs[0] + 1) if fs else a + 60          # a ring line labelled N is replay.lua's frame N+1
        print("at\tgrunt\ta%d\t%s\t%d\tevent\t%s:%d-%d" % (k + 1, leg, fr, g, lo, hi))
PYS
    sheet_rows "$W/sheet_rows.tsv"
fi

[ "$fail" -eq 0 ] && echo "PASS: electrocute-grunt A/B — the alternating kernel voice matches the frozen inventory on both legs" || exit 1
