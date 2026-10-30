#!/bin/sh
# test_hui_air.sh — Huitzil air-movement gate (14z-66, playtest round-1
# item 3: float + air dash were DEAD).
#
# WHAT: Phobos's air movement is alive with its measured mode signatures: hold-8 rises then
#   HOVERS at a pinned height, and a dash input in the air engages the air dash (seq 0x14,
#   airborne) with a flat advance — not merely no crash.
# HOW: replay 75 (float) and replay 79 (air dash) on MAME against build/hui61 (another
#   build can be given; a stage-4 build until 14z-197), Y and X and the seq byte read from
#   dumps at the frames after the rise completes.
# EXPECTS: Y pinned >= 100px over f3350-f3370; seq 0x14 AIRBORNE (Y >= 100px) with X moving
#   >= 30px at near-constant height over f3322-f3337. A red is the float or dash dead again,
#   the dash on the ground, or a rise-speed change moving the sample window.
# FOLLOWS: build/manifest/ emu/mame-patches/ tests/lua/replay_guard.lua tests/lib/jobs.sh
#   tests/replays/hui/75_hui_air.rpl tests/replays/hui/79_hui_airdash.rpl
#   tests/lib/controls.sh tools/build_donovan.sh tools/run_mame.sh tools/run_replay_guarded.sh tools/setup_mame.sh
#
# SHEET: none — runs our build only, judged on its own; no reference leg and no frozen reference values
# MUST-FIRE: known-bad: ground-dash — replay 79 with every input from f3050 moved +5 frames (the re-time tried 14z-197) dashes ON THE GROUND on its first attempt (seq 0x14 over f3186-3196 at Y=40; sampled at f3186/f3195, inside the dash), and the dash check must miss it on height ALONE (in-gate: one extra run, MISSED: ground; mode: the section reads that copy and the gate FAILs)
#
# Mechanism (measured; STATE 14z-66): vs2 routes the class-02 jump seq
# BY CHAR ID at the engine head — id 0x10 gets his OWN per-char jump
# handler (float/air-action/restart bodies). The port clones that
# handler (region x02592a), thunk-routes tenant owners at vsavj's live
# twin head 0x22A0E (tenant_jump_seq), and rewrites the oracle-invisible
# pcrel escapes of both engine-style regions (pcrel_escape_fix).
#
# Sections (replay 75 float probe, replay 79 air-dash probe), each with
# an anti-coverage-loss assertion — the measured mode signature, not
# just "no crash":
#   1. FLOAT — hold-8 rises then HOVERS: Y at f3350..f3370 pinned to one
#      value >= 100px (the mover-bypass hold). Sample frames sit AFTER
#      the rise completes: with the jump_params port the native-speed
#      rise reaches the 121.1 ceiling at ~f3345 (the alias-physics
#      build reached 109.4 by ~f3320 — the original 3330-frame samples
#      were tuned to THAT rise and caught the new one mid-climb).
#   2. AIR DASH — replay 79's SECOND attempt (jump, then 44: the back air
#      dash): the air-dash seq byte 0x14 appears at +0x05, the body is
#      AIRBORNE (Y >= 100px), and X moves >= 30px (either direction)
#      across f3322..f3337 at near-constant height.
#   RE-TIMED 14z-197 (#228 step 4, maintainer-ruled "Move to hui61, re-time 2"): on the replays' own timing
#   (build/hui61, replay.lua, no debugger) neither section found its event: replay 75 never hovers and replay 79's
#   first attempt (f3160) is no air dash. Replay 75's inputs from f3050 on moved +5 frames for its float: it hovers
#   at Y=121.125 over f3335-3385 (native 121.12). Its first jump (f3065) stays eaten at +0 and +5 alike, and on
#   the native VS2 leg too (build/agent197/t228/s3/vs2/summary.txt) — not a one-frame miss, and this gate does not read
#   it. (Corrected 14z-197 before commit, rule-checker run 2026-10-11-808: this note first said the first jumps of
#   75 and 79 landed one frame before the character could act.) Replay 79 is UNCHANGED:
#   a +5 shift was tried and gave a GROUND dash (seq 0x14 at Y=40 — the jump still eaten), which this section,
#   having no height check then, passed; the gate now reads the replay's second attempt, which on its own timing
#   is an air dash: seq 0x14 over f3321-3340 at Y=121.1, X moving -116.3 px over f3322-3337 at dy 0
#   (build/agent197/t228/s3/air/).
#
# Usage: ROMDIR=... [JOBS=N] tests/test_hui_air.sh [builddir]   (default build/hui61)
#
# THE BUILD IS build/hui61 BY DEFAULT since 14z-197 (maintainer-ruled 2026-10-11, the four Huitzil stage gates "Move to
# hui61, re-time 2"; DECISIONS_HISTORY.md). Until then it self-built STAGE 4. Once replay_guard.lua counts emulated
# frames (#228 step 4) a rig plays on its own timing, and on that timing the fresh stage-4 build RESETS just after the
# match starts on the 2P-dummy rigs (80, 81: the state word and both ids zero by f2500; measured with replay.lua, no
# debugger), where the frame_done clock's one-frame lead had masked it; build/hui61 runs them with the native
# signatures. A stage-4 build can still be passed by hand.
#
# HANDOFF's gate-index note, moved into this header 14z-123 (verbatim; the
# documentation pass ruled a gate's WHY lives in the gate):
#   Huitzil air-movement gate (14z-66): the float hovers (Y pinned) and the
#   air dash engages (seq 0x14, flat advance) — mode signatures, not just no-
#   crash. Self-builds stage 4 unless given a build
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
cd "$REPO"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

. "$REPO/tests/lib/controls.sh"; vs_ctl_mode "$0"
set -- "${1:-build/hui61}"   # re-pointed 14z-197 (was: a fresh stage-4 build) — see THE BUILD above
if [ $# -ge 1 ]; then
    BUILD="$1"
    echo "== using existing build $BUILD"
else
    echo "== stage 4 build"
    TENANT_MANIFEST=build/manifest/huitzil.toml TENANT_CHAR=0x10 \
    GEN_FLAGS="--profile cps2-wide-v1 --allow-plausible --tripwire-open" \
        tools/build_donovan.sh 4 "$WORK/hui4" > "$WORK/build.log" 2>&1 \
        || { tail -15 "$WORK/build.log"; echo "FAIL: build"; exit 1; }
    BUILD="$WORK/hui4"
fi
case "$BUILD" in /*) ;; *) BUILD="$REPO/$BUILD" ;; esac
[ -f "$BUILD/rompath/vsavjw.zip" ] || { echo "FAIL: no vsavjw.zip (WIDE build required)"; exit 1; }
export MAME_BIN="${MAME_BIN:-$HOME/.cache/vampire-saved/mame/cps2}"

PK="1704:ff8782:10;1760:ff8782:10;1900:ff8782:10;2100:ff8782:10;2400:ff8782:10"

# The ground-dash copy of replay 79: every input from f3050 on moved +5 frames,
# the re-time tried 14z-197. Its FIRST attempt dashes ON THE GROUND (seq 0x14 at
# Y=40 over f3186-3196, measured; sampled at f3186/f3195, inside it) — exactly the dash the
# section once passed with no height check.
GROUND="$WORK/79_ground.rpl"
awk '{ if (match($0, /^[0-9]+(-[0-9]+)?/)) { r = substr($0, 1, RLENGTH); rest = substr($0, RLENGTH + 1)
         n = split(r, a, "-"); if (a[1] + 0 >= 3050) { r = (a[1] + 5) ""; if (n == 2) r = r "-" (a[2] + 5) }
         print r rest } else print }' tests/replays/hui/79_hui_airdash.rpl > "$GROUND"

# JOBS (#334 item 2, 14z-211): the three guarded runs — float, the air dash (or, in the ground-dash mode, the
# ground-dash copy) and the ground-dash control — are independent: each runs in its own $WORK/{float,ad,gd} (cwd,
# log, sandbox, dumps, captured output, exit status). So they go through tests/lib/jobs.sh's pool first, JOBS at a
# time (default min(4, CPUs/6)); the sections below judge them in the serial order with the same lines and exits.
. "$REPO/tests/lib/jobs.sh"; vs_jobs JOBS 4 6
air_exec() {  # air_exec <rpl> <dir> <dumps>: the guarded run in <dir>; exit status to <dir>/rc
    mkdir -p "$2"
    if ( cd "$2" && POKES="$PK" \
      DUMPS="$3" \
      MAME_ROMPATH="$BUILD/rompath;$ROMDIR" \
      "$REPO/tools/run_replay_guarded.sh" vsavjw "$1" \
          "$2/g.log" "$2/box" > "$2/g.out" 2>&1 ); then echo 0 > "$2/rc"; else echo "$?" > "$2/rc"; fi
}
air_ok() { [ "$(cat "$1/rc" 2>/dev/null)" = 0 ]; }
vs_pool_start "$JOBS"
vs_pool_run air_exec "$REPO/tests/replays/hui/75_hui_air.rpl" "$WORK/float" \
    "3350:ff8400-ff8420;3360:ff8400-ff8420;3370:ff8400-ff8420"
if vs_ctl_is ground-dash; then
    vs_pool_run air_exec "$GROUND" "$WORK/ad" "3186:ff8400-ff8420;3195:ff8400-ff8420"
else
    vs_pool_run air_exec "$REPO/tests/replays/hui/79_hui_airdash.rpl" "$WORK/ad" "3322:ff8400-ff8420;3337:ff8400-ff8420"
fi
vs_pool_run air_exec "$GROUND" "$WORK/gd" "3186:ff8400-ff8420;3195:ff8400-ff8420"
vs_pool_wait

echo "== float (replay 75)"
d="$WORK/float"
air_ok "$d" || {   # (the run itself ran in the pool, air_exec)
    echo "FAIL: float replay guard tripped:"
    grep -m2 -E "CRASH|REGS" "$d/g.log" || tail -5 "$d/g.out"
    exit 1
}
python3 - "$d" <<'EOF'
import struct, sys
d = sys.argv[1]
ys = []
for f in (3350, 3360, 3370):
    b = open("%s/dump_%d_ff8400.bin" % (d, f), 'rb').read()
    ys.append(struct.unpack('>i', b[0x14:0x18])[0])
same = ys[0] == ys[1] == ys[2]
high = ys[0] / 65536.0 >= 100
print("  hover Y: %s (%.1f px)" % ("CONSTANT" if same else "VARYING %s" % ys, ys[0]/65536.0))
if not (same and high):
    print("FAIL: no hover — the float did not engage")
    sys.exit(1)
EOF
echo "  ok: float hovers (mover bypassed, Y pinned)"

# dash_run <rpl> <dir> <f0> <f1>: run the rig, dump the body at f0 and f1 (15 frames
# apart), print the measured signature and every criterion that missed; exit 0 when
# all hold, 1 when one misses, 2 when the guard tripped
# (since #334 item 2 the run itself is air_exec's, in the pool above; dash_run judges it)
dash_run() {
    air_ok "$2" || {
        echo "FAIL: air-dash replay guard tripped:"
        grep -m2 -E "CRASH|REGS" "$2/g.log" || tail -5 "$2/g.out"
        return 2
    }
    python3 - "$2" "$3" "$4" <<'EOF'
import struct, sys
d, f0, f1 = sys.argv[1], int(sys.argv[2]), int(sys.argv[3])
rows = []
for f in (f0, f1):
    b = open("%s/dump_%d_ff8400.bin" % (d, f), 'rb').read()
    rows.append((b[0x06], struct.unpack('>i', b[0x10:0x14])[0],
                 struct.unpack('>i', b[0x14:0x18])[0]))
dx = (rows[1][1] - rows[0][1]) / 65536.0
dy = abs(rows[1][2] - rows[0][2]) / 65536.0
y = rows[0][2] / 65536.0
# AIRBORNE is part of the signature: a ground dash also shows seq 0x14 with a
# flat advance (Y=40, the 14z-197 +5 re-time that this check did not see)
missed = []
if not (rows[0][0] == 0x14 and rows[1][0] == 0x14): missed.append("seq")
if y < 100: missed.append("ground")
if abs(dx) < 30: missed.append("dx")
if dy >= 8: missed.append("dy")
print("  seq=%02x/%02x Y=%.1f px dx=%.1f px dy=%.1f px over %df" % (rows[0][0], rows[1][0], y, dx, dy, f1 - f0))
if missed:
    print("  MISSED: %s" % " ".join(missed))
    sys.exit(1)
EOF
}

# (GROUND, the ground-dash copy of replay 79, is made above, before the pool)
echo "== air dash (replay 79)"
if vs_ctl_is ground-dash; then
    echo "  CONTROL MODE: the section reads the ground-dash copy's first attempt (f3186/f3195)"
    dash_run "$GROUND" "$WORK/ad" 3186 3195 || { echo "FAIL: air dash did not engage (seq/trajectory off)"; exit 1; }
else
    dash_run "$REPO/tests/replays/hui/79_hui_airdash.rpl" "$WORK/ad" 3322 3337 \
        || { echo "FAIL: air dash did not engage (seq/trajectory off)"; exit 1; }
fi
echo "  ok: air dash engages (seq 0x14, airborne, flat accelerated dash)"

echo "== control: a GROUND dash must miss on height alone (ground-dash)"
_rc=0; dash_run "$GROUND" "$WORK/gd" 3186 3195 > "$WORK/gd.out" 2>&1 || _rc=$?
sed 's/^/  /' "$WORK/gd.out"
if [ "$_rc" = 1 ] && grep -qx '  MISSED: ground' "$WORK/gd.out"; then
    vs_ctl_fired ground-dash "the +5 copy's ground dash missed on height alone (MISSED: ground)"
else
    vs_ctl_dead ground-dash "the +5 copy did not miss on height alone (exit $_rc) — the airborne check is not what separates it" || exit 1
fi

echo "PASS: Huitzil air movement (float + air dash live)"
