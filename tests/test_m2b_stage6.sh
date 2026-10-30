#!/bin/sh
# test_m2b_stage6.sh — the M2b (graphics) build gate:
#   1. Build stage 6 (includes tools/verify_gfx_build.py: record/entry
#      parity, tile-code containment, placed bank table — the static
#      output checks that caught the fmt-0 count corruption).
#   2. Guarded soaks on the stage-6 build (crash guard + tripwires):
#      moveset, DP spam, round-2, input chaos, 40K arcade marathon —
#      the gfx remap touches anim data; these prove the state machine
#      still runs it clean.
#   3. Masked legacy gate (CLAUDE.md §4) on the stage-6 build: the gfx work
#      must not perturb one byte of legacy live RAM beyond what the frozen
#      generation already accounts for. RE-POINTED 14z-97 (GitHub #96): the
#      target is resolved from the build's fingerprint — today
#      `donovan-m8-stock`, the STOCK TWIN of the donovan-m8 freeze — so this
#      leg now asserts "the pipeline, built fresh, reproduces the current
#      freeze" (maintainer-ruled option (a), 2026-08-19).
# Companion gates run separately against the same rompath:
#   tests/test_m2a_stage4_oracle.sh build/donovan6/rompath
#   tests/test_m2a_stage4_xemu.sh   build/donovan6/rompath
#   tests/test_m2a_flavor_selector.sh build/donovan6/rompath
#
# WHAT: the graphics build gate: stage 6 builds with its static gfx verification, survives
#   the guarded soaks (moveset, DP spam, round 2, input chaos, the 40K marathon), and the
#   fresh pipeline reproduces the CURRENT frozen generation on the masked legacy gate.
# HOW: builds stage 6 (tools/verify_gfx_build.py inside), runs the guarded soaks on MAME,
#   then the masked legacy suite with the target resolved from the build's fingerprint (the
#   stock twin of the current freeze).
# EXPECTS: gfx checks green, every soak END clean, the legacy leg EXACT against the frozen
#   generation; a red on the last means the pipeline built fresh no longer reproduces the
#   freeze.
# FOLLOWS: build/manifest/ emu/mame-patches/ tests/expected/ tests/lib/m2a_common.sh tests/lib/jobs.sh
#   tests/lib/masked_compare.sh tests/lua/replay.lua tests/lua/replay_guard.lua
#   tests/replays/ tests/test_gfx_menus.sh tools/build_donovan.sh tools/build_fingerprint.py
#   tools/check_diverge.py tools/compare_composite.py tools/compare_flicker.py
#   tools/compare_window.py tools/freeze_masked_basis.sh tools/propose_masked_specs.sh
#   tools/run_mame.sh tools/run_replay_guarded.sh tools/run_replay_mame.sh
#   tools/setup_mame.sh
#
# SHEET: none — the subject is a development-stage build of the M2a/tenant ladder, not a release set; its comparison with vsavj is outside #291's scope (census class S)
#
# Usage: ROMDIR=... [JOBS=N] tests/test_m2b_stage6.sh [outbase]
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
OUTBASE="${1:-$REPO/build/donovan6}"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
cd "$REPO"
. "$REPO/tests/lib/m2a_common.sh"

fail=0

echo "== build stage 6 (static output verification inside) =="
# --- build (no pipe: a rejected build must abort the gate) ---------------
# 14z-90: `| tail -3` handed this gate tail's exit status, so a build that
# build_donovan.sh itself REJECTED (verify_gfx_build :404 / member-identity
# :415, both AFTER the pack at :275/:287) was soaked, legacy-gated and
# stamped PASS. Same class as docs/project/gotchas.md "Pipe a build tool
# through tail". Stages 1/2/3 always used this form; 4 and 6 regressed it.
GEN_FLAGS="--allow-plausible --tripwire-open" \
    tools/build_donovan.sh 6 "$OUTBASE" \
    > "$WORK/build.log" 2>&1 || { tail -20 "$WORK/build.log"; exit 1; }
tail -3 "$WORK/build.log"
# A build that died before build_donovan.sh:263 (`rm -rf rompath`) leaves no
# rompath at all, and run_mame.sh's chained `-rompath "dir;$ROMDIR"` then
# resolves PRISTINE vsavj — the gate would measure vanilla and pass.
[ -d "$OUTBASE/rompath" ] || {
    echo "FAIL: no rompath at $OUTBASE — the build produced nothing to gate"
    exit 1
}
RP="$OUTBASE/rompath;$ROMDIR"

echo "== 1. guarded soaks on stage 6 =="
# JOBS (#334 item 2, 14z-211): the five soaks are independent — each writes only its own log, sandbox, captured
# output and exit status — so they go through tests/lib/jobs.sh's pool, JOBS at a time; default min(4, CPUs/6). The
# verdicts below read them after, in the same order and with the same lines as the serial loop printed.
SOAKS="12_donovan_vs_cpu 19_don_dp_spam 20_don_round2 21_don_mash 26_don_arcade_mash"
. "$REPO/tests/lib/jobs.sh"; vs_jobs JOBS 4 6
soak_run() {  # soak_run <replay>: the guarded run; its stdout+stderr to $WORK/<r>.gout, its exit status to <r>.rc
    if MAME_ROMPATH="$RP" tools/run_replay_guarded.sh vsavj \
        "$REPO/tests/replays/$1.rpl" "$WORK/$1.log" "$WORK/${1}box" > "$WORK/$1.gout" 2>&1; then
        echo 0 > "$WORK/$1.rc"
    else
        echo "$?" > "$WORK/$1.rc"
    fi
}
vs_pool_start "$JOBS"
for gr in $SOAKS; do vs_pool_run soak_run "$gr"; done
vs_pool_wait
for gr in $SOAKS; do
    cat "$WORK/$gr.gout"
    if [ "$(cat "$WORK/$gr.rc" 2>/dev/null)" = 0 ]; then
        echo "  ok: $gr END-clean under guard"
    else
        echo "FAIL: guard tripped on $gr:"; tail -5 "$WORK/$gr.log"; fail=1
    fi
done

echo "== 2. legacy gate, §4 basis (masked live-RAM, current frozen generation) =="
m2a_legacy_gate_masked "$RP" "$WORK"

# pixel-level menu gate (session 14s): RAM/VRAM gates are blind to gfx
# ROM content and to coordinate lists that only land in OBJ RAM — this
# catches both classes (title / select / speed menu vs frozen vanilla
# goldens, tests/expected/vsavj/menus/).
if tests/test_gfx_menus.sh "$OUTBASE/rompath"; then :; else fail=1; fi
[ "$gate_fail" = 0 ] || fail=1

[ "$fail" = 0 ] && echo "PASS: M2b stage-6 gate" || echo "FAIL: M2b stage-6 gate"
exit "$fail"
