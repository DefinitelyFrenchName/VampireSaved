#!/bin/sh
# test_m2a_stage1_nullreloc.sh — M2a stage-1 gate: the null relocation.
#
# WHAT: the M2a stage-1 null relocation: Jedah's own hitbox block copied into hole A and
#   repointed, two dispatch entries routed through jmp-back trampolines, with zero Donovan
#   bytes — picking slot 0x0F loads the relocated base, Jedah's match is field-identical to
#   vanilla but for the two relocated pointers, legacy replays bit-identical, the pick
#   replay diverging exactly at 2886, the -debug guard clean.
# HOW: the stage-1 build on MAME: the pick replay, compare_fields against vanilla, the
#   legacy suite, the attract and pick divergence frames, the crash guard.
# EXPECTS: every gate as listed; any failure is allocator/copy/repoint/encrypt tooling,
#   nothing else.
# FOLLOWS: build/manifest/ emu/mame-patches/ tests/expected/ tests/fields_m2a.tsv tests/lib/jobs.sh
#   tests/lib/m2a_common.sh tests/lib/masked_compare.sh tests/lua/replay.lua
#   tests/lua/replay_guard.lua tests/replays/ tools/build_donovan.sh
#   tools/build_fingerprint.py tools/check_diverge.py tools/compare_composite.py
#   tools/compare_fields.py tools/compare_flicker.py tools/compare_window.py
#   tools/freeze_masked_basis.sh tools/propose_masked_specs.sh tools/run_mame.sh
#   tools/run_replay_guarded.sh tools/run_replay_mame.sh tools/setup_mame.sh
#
# SHEET: none — the subject is a development-stage build of the M2a/tenant ladder, not a release set; its comparison with vsavj is outside #291's scope (census class S)
#
# Stage 1 copies Jedah's OWN player-path hitbox block into free hole A
# (data raw inside the encrypted zone) and repoints the +0x60/+0x64 pair
# (slots 0x0F+0x1F), plus routes two dispatch entries through jmp-back
# trampolines (one re-encrypted in hole A, one raw in hole B). Zero Donovan
# bytes, zero R1 ambiguity — any failure here is allocator/copy/repoint/
# encrypt tooling, nothing else.
#
# Gates:
#   1. Live effect: picking slot 0x0F loads the RELOCATED base (0x0BF7A0)
#      at RAM:$FF8460.
#   2. Behavior-identical: Jedah's match on the stage-1 build is
#      frame-exact field-identical to vanilla (same emulator) for all
#      mapped fields except the two legitimately-relocated pointers.
#   3. Superset invariant: non-slot-0x0F replays bit-identical; attract
#      diverges exactly at 4278; the pick replay diverges exactly at 2886
#      (where slot-0x0F pointers first land in RAM — measured, pinned).
#   4. Crash guard (-debug) clean on the pick replay.
#
# Usage: ROMDIR=... [JOBS=N] tests/test_m2a_stage1_nullreloc.sh
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
. "$REPO/tests/lib/m2a_common.sh"
WORK="$(mktemp -d)"   # the stage build lives HERE (14z-133b): build/donovan was an M2a-era dir the
                      # build-dir policy pruned around, and pack_build.sh rightly refused an empty prg/ (RED 14z-128)
trap 'rm -rf "$WORK"' EXIT
fail=0

RELOC_BASE=000bf7a0      # hitbox_base[0x0F] after stage-1 relocation
PICK_DIVERGE=2886        # first frame slot-0x0F pointer state hits RAM

# --- build (no pipe: a generator failure must abort the gate) ------------
ROMDIR="$ROMDIR" "$REPO/tools/build_donovan.sh" 1 "$WORK/donovan" \
    > "$WORK/build.log" 2>&1 || { tail -15 "$WORK/build.log"; exit 1; }
tail -2 "$WORK/build.log"
RP="$WORK/donovan/rompath;$ROMDIR"

# JOBS (#334 item 2, 14z-211): this file's own four runs — the pick (section 1), the vanilla and stage-1 field pair
# (section 2) and the guarded run (section 4) — are independent: each writes only its own log, sandbox and dumps
# (the pick's dump in $WORK, the pair's in $WORK/fv and $WORK/fs), plus its own captured output and exit status. So
# they go through tests/lib/jobs.sh's pool first, JOBS at a time (default min(4, CPUs/6)), and the sections below
# read them in the serial order. A run that failed ends the gate where the serial run would have (set -e then, an
# explicit exit with its status now), with the same output. m2a_legacy_gate (section 3) stays the shared helper's.
SPEC=$(python3 -c "print(';'.join(f'{f}:ff8000-ff8300;{f}:ff8400-ff8c00' for f in range(2900,3140,10)))")
mkdir -p "$WORK/fv" "$WORK/fs"
. "$REPO/tests/lib/jobs.sh"; vs_jobs JOBS 4 6
st1_run() {  # st1_run <tag> <cmd...>: run it; its exit status to $WORK/<tag>.rc
    _t="$1"; shift
    if "$@"; then echo 0 > "$WORK/$_t.rc"; else echo "$?" > "$WORK/$_t.rc"; fi
}
st1_pick() {
    DUMPS="3600:ff8460-ff8464" MAME_ROMPATH="$RP" \
        REPLAY="$REPO/tests/replays/11_pick_donovan.rpl" \
        CHECKSUM_OUT="$WORK/pick.log" MAME_SANDBOX="$WORK/pickbox" \
        "$REPO/tools/run_mame.sh" vsavj \
        -autoboot_script "$REPO/tests/lua/replay.lua" > /dev/null 2>&1
}
st1_fv() {
    DUMPS="$SPEC" "$REPO/tools/run_replay_mame.sh" vsavj \
        "$REPO/tests/replays/11_pick_donovan.rpl" "$WORK/fv/out.log" "$WORK/fvbox" > "$WORK/fv.out" 2>&1
}
st1_fs() {
    DUMPS="$SPEC" MAME_ROMPATH="$RP" "$REPO/tools/run_replay_mame.sh" vsavj \
        "$REPO/tests/replays/11_pick_donovan.rpl" "$WORK/fs/out.log" "$WORK/fsbox" > "$WORK/fs.out" 2>&1
}
st1_guard() {
    MAME_ROMPATH="$RP" "$REPO/tools/run_replay_guarded.sh" vsavj \
        "$REPO/tests/replays/11_pick_donovan.rpl" "$WORK/guard.log" \
        "$WORK/guardbox" > "$WORK/guard.out" 2>&1
}
vs_pool_start "$JOBS"
for _r in pick fv fs guard; do vs_pool_run st1_run "$_r" "st1_$_r"; done
vs_pool_wait
st1_rc() { cat "$WORK/$1.rc" 2>/dev/null || echo 1; }

# --- 1. live effect ------------------------------------------------------
_rc="$(st1_rc pick)"; [ "$_rc" = 0 ] || exit "$_rc"
HB=$(xxd -p "$WORK/dump_3600_ff8460.bin")
case "$HB" in
    ${RELOC_BASE}*) echo "  ok: slot 0x0F loads relocated base 0x0BF7A0" ;;
    *) echo "FAIL: hitbox base $HB (expected $RELOC_BASE)"; fail=1 ;;
esac

# --- 2. behavior-identical (field trace vs vanilla, frame-exact) ---------
# (the field pair ran in the pool above; its output is shown here, where the serial gate printed it)
cat "$WORK/fv.out"; _rc="$(st1_rc fv)"; [ "$_rc" = 0 ] || exit "$_rc"
cat "$WORK/fs.out"; _rc="$(st1_rc fs)"; [ "$_rc" = 0 ] || exit "$_rc"
if python3 "$REPO/tools/compare_fields.py" "$WORK/fv" "$WORK/fs" \
        --fields "$REPO/tests/fields_m2a.tsv" --exact \
        --skip-fields p1_hitbox_base,p1_ptr64 \
        --label-a vanilla --label-b stage1 > "$WORK/fields.out" 2>&1; then
    echo "  ok: Jedah plays frame-exact identical (24 frames, all fields but the 2 relocated ptrs)"
else
    echo "FAIL: behavior fields diverged:"; cat "$WORK/fields.out"; fail=1
fi

# --- 3. superset gate ----------------------------------------------------
m2a_legacy_gate "$RP" "$WORK"
[ "$gate_fail" = 0 ] || fail=1
if m2a_diverge "$WORK/pick.log" 11_pick_donovan "$PICK_DIVERGE" > /dev/null; then
    echo "  ok: pick replay diverges exactly at $PICK_DIVERGE"
else
    echo "FAIL: pick replay divergence not exactly at $PICK_DIVERGE"
    m2a_diverge "$WORK/pick.log" 11_pick_donovan "$PICK_DIVERGE" || true
    fail=1
fi

# --- 4. crash guard ------------------------------------------------------
# (the guarded run ran in the pool above)
if [ "$(st1_rc guard)" = 0 ]; then
    echo "  ok: guarded run clean (both trampolines executed, no exceptions)"
else
    echo "FAIL: crash guard tripped:"; cat "$WORK/guard.out"; fail=1
fi

[ "$fail" = 0 ] && echo "PASS: stage 1 null relocation proven" \
    || { echo "SUITE RED"; exit 1; }
