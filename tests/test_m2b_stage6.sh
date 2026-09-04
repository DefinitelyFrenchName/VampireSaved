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
# Usage: ROMDIR=... tests/test_m2b_stage6.sh [outbase]
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
for gr in 12_donovan_vs_cpu 19_don_dp_spam 20_don_round2 21_don_mash \
          26_don_arcade_mash; do
    if MAME_ROMPATH="$RP" tools/run_replay_guarded.sh vsavj \
        "$REPO/tests/replays/$gr.rpl" "$WORK/$gr.log" "$WORK/${gr}box"; then
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
