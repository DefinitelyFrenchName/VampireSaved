#!/bin/sh
# test_don_throw_mirror.sh — the 14z-2 mirror-victim fix (applied 14z-64
# in the M3a re-freeze bundle): in a BASE-SLOT mirror match (both players
# on slot 0x0F = Donovan there), the thrown victim must use the
# DONOVAN-victim keyframe block, not Jedah's.
#
# WHAT: in a base-slot mirror match (both players on slot 0x0F) the thrown victim uses the
#   DONOVAN-victim keyframe block, not Jedah's — the two-byte fix at PRG:0x0B1A16.
# HOW: static: the built image holds 0x0D88 at the blob's entry [0x0F]; runtime: replay 65
#   on MAME with the victim keyframe walker tapped for reads of the fixed block versus the
#   old one (206/0 on the candidate, 0/206 pre-fix).
#   THE INSTRUMENT'S ALIGNMENT (#228 step 4, maintainer-ruled 2026-10-10 "option A"): trace_writes.lua counts
#   EMULATED frames (tests/lua/emu_clock.lua); both tap runs' game clock RAM:$FF8080 at the last frame is held to
#   tests/expected/instr_gameclock/test_don_throw_mirror.tsv, frozen by `--freeze-clock` from a REFERENCE leg (no
#   watch, no debugger) held to replay.lua run live; one STAGING reference leg is held to replay.lua on every run
#   (tests/lib/instr_align.sh).
# EXPECTS: the word present and the walker reading only the fixed block. SKIPs on variant-id
#   builds, where the mirror is tenant-vs-tenant at 0x13 and correct by construction. Both tap runs on emulated
#   time at the frozen game clock, the staging leg on replay.lua's checksum.
# FOLLOWS: build/manifest/ emu/mame-patches/ tests/expected/instr_gameclock/ tests/lib/controls.sh tests/lib/jobs.sh
#   tests/lib/instr_align.sh tests/lua/emu_clock.lua tests/lua/replay.lua tests/lua/trace_writes.lua
#   tests/replays/65_don_mirror_throw.rpl tools/build_donovan.sh tools/run_mame.sh
#   tools/setup_mame.sh
#
# SHEET: none — runs our build only, judged on its own; no reference leg and no frozen reference values
#
# MUST-FIRE: known-bad: drift-clock — a tap run under the OLD frame_done clock (INSTR_CLOCK=frame_done, the [MFI-5] desync this gate ran on until 14z-197: 4,193 emulated frames of 4,400 counted) must miss its frozen game clock (in-gate: one extra run; mode: both tap runs run the old clock and the gate FAILs)
# MUST-FIRE: known-bad: first-frame-skip — the staging reference leg under the #213 first-frame skip (INSTR_CLOCK=skip_first) must miss replay.lua's checksum (in-gate; mode: the staging leg runs the skip and the gate FAILs)
#
# MECHANISM. The throw victim-keyframe blob (data_port
# throw_victim_keyframes, dst 0x0B19F8) carries a victim-id offset table;
# entry [0x0F] at blob+0x1E held 0x0B30 (the Jedah-victim block) and the
# fix makes it 0x0D88 (the Donovan-victim block) — in the mirror flavor,
# victim id 0x0F IS Donovan. Byte-attributed: the candidate differs from
# the pre-fix frozen build by EXACTLY these two bytes (PRG:0x0B1A16).
#
#   1. STATIC — the built image holds 0x0D88 at blob+0x1E, with the
#      blob's head bytes intact (the right blob, the right word).
#   2. RUNTIME — replay 65 (both players pick slot 0x0F, P1 throws):
#      the victim keyframe walker reads the FIXED block (0xB2780+) and
#      never the old one (0xB2528+). Measured 206/0 on the candidate
#      and 0/206 on the pre-fix build — a matched control pair.
#
# BASE-SLOT track only (on variant-id builds the host block stays
# vanilla and the mirror flavor is tenant-vs-tenant at 0x13, correct by
# construction — the gate SKIPs on those builds).
#
# Usage: ROMDIR=... [JOBS=N] tests/test_don_throw_mirror.sh [outbase] [--freeze-clock]
#
# HANDOFF's gate-index note, moved into this header 14z-123 (verbatim; the
# documentation pass ruled a gate's WHY lives in the gate):
#   the 14z-2 mirror-victim fix (applied 14z-64): base-slot mirror throws use
#   the Donovan-victim block — static 2-byte assertion + a matched runtime
#   control pair on replay 65. SKIPs on variant-id builds (correct by
#   construction)
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
fail=0
FREEZE_CLOCK=0
for a in "$@"; do [ "$a" = "--freeze-clock" ] && FREEZE_CLOCK=1; done
[ "${1:-}" = "--freeze-clock" ] && shift
. "$REPO/tests/lib/controls.sh"; vs_ctl_mode "$0"; MODE="${VS_CTL:-}"
. "$REPO/tests/lib/instr_align.sh"
CLOCKS="tests/expected/instr_gameclock/test_don_throw_mirror.tsv"
[ "$FREEZE_CLOCK" = 1 ] && [ -n "$MODE" ] && { echo "REFUSED: --freeze-clock in control mode"; exit 3; }
_clk=""; [ "$MODE" = drift-clock ] && _clk="INSTR_CLOCK=frame_done"

OUTBASE="${1:-}"
if [ -z "$OUTBASE" ]; then
    OUTBASE="$WORK/build"
    echo "== 0. building the base-slot track (fresh) =="
    GEN_FLAGS="--allow-plausible --tripwire-open" \
        tools/build_donovan.sh 6 "$OUTBASE" > "$WORK/build.log" 2>&1 || {
        echo "FAIL: build did not complete"; tail -20 "$WORK/build.log"
        exit 1; }
    tail -2 "$WORK/build.log" | sed 's/^/  /'
fi
if [ -f "$OUTBASE/patch/tenant.json" ] && \
   python3 -c "import json,sys; sys.exit(0 if json.load(open('$OUTBASE/patch/tenant.json'))['id'] >= 0x10 else 1)"; then
    echo "SKIP: variant-id build — the mirror flavor is correct by construction there"
    exit 0
fi

echo "== 1. static: the fixed word in the built image =="
python3 - "$OUTBASE/prg" <<'PY' || { echo "FAIL: static"; exit 1; }
import sys, os
sys.path.insert(0, "tools")
import cps2_decrypt as cps
d = sys.argv[1]
names = sorted((n for n in os.listdir(d) if cps._PRG_RE.search(n)),
               key=lambda n: int(cps._PRG_RE.search(n).group(1)))
blob = b"".join(open(os.path.join(d, n), "rb").read() for n in names)
img = bytes(cps.words_to_logical_bytes(cps.words_from_file_bytes(blob)))
BLOB = 0x0B19F8
vs2 = open("build/out/vsav2_data.bin", "rb").read()
SRC = 0x0CA1CA
assert img[BLOB:BLOB + 4] == vs2[SRC:SRC + 4], \
    f"blob head {img[BLOB:BLOB+4].hex()} != vs2 src head — wrong blob"
assert vs2[SRC + 0x1E:SRC + 0x20].hex() == "0b30", \
    "vs2 source entry [0x0F] is not 0b30 — the fix premise moved"
w = img[BLOB + 0x1E:BLOB + 0x20].hex()
assert w == "0d88", f"victim entry [0x0F] = {w}, expected 0d88 (the fix)"
print("  ok: vs2 blob in place, entry [0x0F] fixed 0b30 -> 0d88")
PY

echo "== 2. runtime: the mirror throw walks the fixed block =="
if [ "${SKIP_RUNTIME:-0}" = 1 ]; then
    echo "  SKIPPED (SKIP_RUNTIME=1)"
else
    # JOBS (#334 item 2, 14z-211):
    # the two watch runs are independent — each writes only $WORK/w_<w>.{txt,align} and its own sandbox
    # $WORK/sbx_<w> — so they go through tests/lib/jobs.sh's pool, JOBS at a time; default min(4, CPUs/6).
    # Their manifest rows are written first, serially, in the old order; the counts below read the traces after.
    FZ_JOBS="${JOBS:-4}"   # --freeze-clock's ia_freeze width, its default (4) kept as it was before the pool
    . "$REPO/tests/lib/jobs.sh"; vs_jobs JOBS 4 6
    one_watch() {  # one_watch <watch address>
        # shellcheck disable=SC2086
        env $_clk WATCH="$1,32,r" TRACE_OUT="$WORK/w_$1.txt" FRAMES=4400 ALIGN_OUT="$WORK/w_$1.align" \
        REPLAY="$REPO/tests/replays/65_don_mirror_throw.rpl" \
        MAME_SANDBOX="$WORK/sbx_$1" \
        MAME_ROMPATH="$OUTBASE/rompath;$ROMDIR" \
            tools/run_mame.sh vsavj -debug -debugger none \
            -autoboot_script tests/lua/trace_writes.lua \
            > /dev/null 2>&1 || true
    }
    for w in b2780 b2528; do
        ia_note "$WORK/manifest.tsv" base 65_don_mirror_throw vsavj "$OUTBASE/rompath;$ROMDIR" \
            "$REPO/tests/replays/65_don_mirror_throw.rpl" 4400 "WATCH=$w,32,r" "$WORK/w_$w.align"
    done
    vs_pool_start "$JOBS"
    for w in b2780 b2528; do
        vs_pool_run one_watch "$w"
    done
    vs_pool_wait
    NEW=$(($(grep -c '^frame' "$WORK/w_b2780.txt") - 1))
    OLD=$(($(grep -c '^frame' "$WORK/w_b2528.txt") - 1))
    if [ "$NEW" -ge 50 ] && [ "$OLD" -eq 0 ]; then
        echo "  ok: victim walker reads the FIXED block ($NEW reads), old block untouched"
    else
        echo "  FAIL: fixed-block reads=$NEW (want >=50), old-block reads=$OLD (want 0)"
        fail=1
    fi

    echo "== 3. the instrument's alignment (#228 step 4, option A) =="
    if [ "$FREEZE_CLOCK" = 1 ]; then
        [ "$fail" = 0 ] || { echo "REFUSED: sections 1-2 failed — nothing frozen"; exit 1; }
        ia_freeze "$REPO/tests/lua/trace_writes.lua" "$WORK/manifest.tsv" "$WORK/fz" "$FZ_JOBS" "$WORK/clocks.tsv" \
            > "$WORK/fz.txt" || { sed 's/^/  /' "$WORK/fz.txt"; echo "REFUSED: the alignment does not hold — nothing frozen"; exit 1; }
        mkdir -p "$(dirname "$CLOCKS")"
        { echo "# $CLOCKS — the game clock RAM:\$FF8080 at each run's last frame, frozen from REFERENCE legs (#228 step 4,"
          echo "# option A) by \`tests/test_don_throw_mirror.sh --freeze-clock\` at $(git rev-parse --short=8 HEAD) (base = the base-slot"
          echo "# track built fresh); every reference leg held to replay.lua run live, every tap run to its reference leg's game clock."
          echo "# leg<TAB>replay<TAB>frames<TAB>gameclock"
          cat "$WORK/clocks.tsv"; } > "$CLOCKS"
        echo "froze $(wc -l < "$WORK/clocks.tsv" | tr -d ' ') game clocks into $CLOCKS"
        exit 0
    fi
    if ia_check_manifest "$CLOCKS" "$WORK/manifest.tsv" > "$WORK/align_bad.txt"; then
        echo "  ok: both tap runs on emulated time, at the frozen game clock"
    else echo "  FAIL: $(wc -l < "$WORK/align_bad.txt" | tr -d ' ') problem(s) off the frozen alignment:"; head -8 "$WORK/align_bad.txt" | sed 's/^/        /'; fail=1; fi
    ia_stage test_don_throw_mirror "$CLOCKS" "$REPO/tests/lua/trace_writes.lua" "$WORK/manifest.tsv" 1 "$WORK/st" "$MODE" || fail=1
    if [ "$MODE" = drift-clock ] || [ "$MODE" = first-frame-skip ]; then
        [ "$fail" = 1 ] && { echo "FAIL: mirror-victim gate (control mode: $MODE)"; exit 1; }
        echo "FAIL: mirror-victim gate — control mode $MODE left the gate green"; exit 1
    fi
    if [ "$IA_DRIFT" = fired ]; then vs_ctl_fired drift-clock "$IA_DRIFT_MSG"; else vs_ctl_dead drift-clock "$IA_DRIFT_MSG" || fail=1; fi
    if [ "$IA_SKIP" = fired ]; then vs_ctl_fired first-frame-skip "$IA_SKIP_MSG"; else vs_ctl_dead first-frame-skip "$IA_SKIP_MSG" || fail=1; fi
fi

if [ "$fail" -ne 0 ]; then
    echo "FAIL: mirror-victim gate"
    exit 1
fi
echo "PASS: mirror-victim gate (the 2-byte fix, static + a matched"
echo "      runtime control on the mirror throw)"
