#!/bin/sh
# freeze_masked_basis.sh — (re)generate a VANILLA masked-basis log set.
#
# The hooked-build legacy oracle (CLAUDE.md §4) compares live work RAM
# with a set of ratified windows EXCLUDED from the per-frame checksum
# (tests/lua/replay.lua MASK_RANGES: offsets from $FF0000, end exclusive,
# masked bytes are SKIPPED from the checksummed stream). That means the
# vanilla side of every masked comparison must be checksummed under the
# SAME mask as the build under test — so whenever the ratified window list
# grows, the vanilla masked logs are regenerated under the new mask into a
# NEW basis dir (v1 = tests/expected/vsavj/masked, round 64; v2 =
# masked-v2, 14z-64; v3 = masked-v3, 14z-88 — the row-0x1D staging slot).
# Older basis dirs are kept: superseded expectation sets still cite them.
#
# Deterministic and re-derivable from $ROMDIR: each replay runs TWICE on
# vanilla vsavj and the pair must be bit-identical before it is written.
#
# THREE GUARDS, all added 14z-89 when this tool was first used to EXTEND an
# existing basis rather than create a new one (the legacy-pairing promotion).
# Extending is the dangerous direction: the names already frozen are not
# re-run, so nothing else would notice a mask that does not match them.
#   1. MASK RECORD. A basis dir carries its mask in $DEST/MASK. If one is
#      present and differs from the argument, this REFUSES — the result
#      would be a silently MIXED basis (some logs under mask A, some under
#      mask B) and every expectation citing it would be meaningless.
#      BASIS_FORCE_MASK=1 overrides, deliberately awkwardly.
#   2. INSTRUMENT CONTROL. VERIFY_BASIS=<already-frozen-name> re-freezes
#      that name into a scratch dir FIRST and requires it to reproduce the
#      frozen log bit-for-bit. That is the only real proof that the mask you
#      passed is the mask the existing logs were frozen under (v1 and v2
#      predate the MASK record, so guard 1 cannot speak for them). Nothing
#      is written if it fails. Use it on EVERY extension.
#   3. ENVIRONMENT SCRUB. POKES/DUMPS/SNAP_FRAMES/TAIL_FRAMES/VIDEO_OUT/
#      INPUT_OUT left exported in a shell would silently change what gets
#      frozen; they are cleared for the runs.
#
# Usage: ROMDIR=... [JOBS=1] [VERIFY_BASIS=<name>] [BASIS_FORCE_MASK=1] \
#          tools/freeze_masked_basis.sh <basis-dir> <mask> <replay-name>...
#   e.g. tools/freeze_masked_basis.sh tests/expected/vsavj/masked-v3 \
#          "043c-043d,4182-41a2,41c2-41e2,4222-4262,42a2-42c2,7f00-8000" \
#          01_attract_long 02_demitri_vs_cpu ...
# Writes <basis-dir>/logs/<name>.log + <basis-dir>/<name>.sha1 and a
# <basis-dir>/MASK record of the mask string used. Honours MAME_BIN.
set -eu
ROMDIR="${ROMDIR:?set ROMDIR}"
REPO="$(cd "$(dirname "$0")/.." && pwd)"
DEST="${1:?basis dir}"; MASK="${2:?mask string}"; shift 2
[ $# -ge 1 ] || { echo "no replay names given"; exit 2; }
case "$DEST" in /*) ;; *) DEST="$REPO/$DEST" ;; esac
JOBS="${JOBS:-1}"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

# guard 3: nothing from the caller's shell may reach the frozen logs
unset POKES DUMPS SNAP_FRAMES TAIL_FRAMES VIDEO_OUT INPUT_OUT INPUT_INJECT_TEST NO_INPUT_CHECK || true

# guard 1: a basis dir has ONE mask
if [ -f "$DEST/MASK" ]; then
    have="$(cat "$DEST/MASK")"
    if [ "$have" != "$MASK" ]; then
        echo "REFUSING: $DEST is frozen under a DIFFERENT mask"
        echo "  recorded: $have"
        echo "  argument: $MASK"
        echo "  A basis is a mask PLUS its logs; mixing two masks in one dir makes"
        echo "  every expectation citing it meaningless. Freeze a NEW basis dir"
        echo "  (masked-v4, ...) or fix the argument. BASIS_FORCE_MASK=1 overrides."
        [ "${BASIS_FORCE_MASK:-0}" = 1 ] || exit 1
        echo "  BASIS_FORCE_MASK=1 — proceeding anyway"
    fi
fi

# one replay, two runs, bit-identical or nothing is written.
# $1 name  $2 dest-dir-or-empty (empty = verify only, write to $WORK/verify)
freeze_one() {
    _n="$1"; _d="${2:-}"
    _rpl="$REPO/tests/replays/$_n.rpl"
    _o="$WORK/out_$_n"
    if [ ! -f "$_rpl" ]; then echo "$_n: no such replay" > "$_o"; touch "$WORK/fail_$_n"; return 0; fi
    for _i in 1 2; do
        if ! MASK_RANGES="$MASK" MAME_ROMPATH="$ROMDIR" \
             "$REPO/tools/run_replay_mame.sh" vsavj "$_rpl" "$WORK/$_n.$_i.log" \
             "$WORK/sb_${_n}_$_i" >"$WORK/mame_${_n}_$_i.log" 2>&1; then
            { printf '%-24s ' "$_n"; echo "RUN-FAIL ($_i)"; } > "$_o"
            touch "$WORK/fail_$_n"; return 0
        fi
    done
    if ! cmp -s "$WORK/$_n.1.log" "$WORK/$_n.2.log"; then
        { printf '%-24s ' "$_n"; echo "NONDETERMINISTIC — not written"; } > "$_o"
        touch "$WORK/fail_$_n"; return 0
    fi
    _sha="$(shasum "$WORK/$_n.1.log" | cut -d' ' -f1)"
    if [ -n "$_d" ]; then
        cp "$WORK/$_n.1.log" "$_d/logs/$_n.log"
        echo "$_sha" > "$_d/$_n.sha1"
    fi
    { printf '%-24s ' "$_n"; echo "frozen $_sha ($(grep -c '^' "$WORK/$_n.1.log") lines)"; } > "$_o"
}

# guard 2: the instrument control — re-derive an ALREADY-frozen log and
# require bit-identity before writing anything new into this basis.
if [ -n "${VERIFY_BASIS:-}" ]; then
    ref="$DEST/logs/$VERIFY_BASIS.log"
    [ -f "$ref" ] || { echo "VERIFY_BASIS=$VERIFY_BASIS: no $ref to verify against"; exit 1; }
    echo "instrument control: re-deriving $VERIFY_BASIS under the given mask..."
    freeze_one "$VERIFY_BASIS" ""
    cat "$WORK/out_$VERIFY_BASIS"
    [ ! -f "$WORK/fail_$VERIFY_BASIS" ] || { echo "CONTROL FAILED — nothing written"; exit 1; }
    if cmp -s "$ref" "$WORK/$VERIFY_BASIS.1.log"; then
        echo "  ok: reproduces $ref bit-for-bit — the mask matches this basis"
    else
        echo "  FAIL: $VERIFY_BASIS does not reproduce $ref under this mask."
        echo "  Either the mask is wrong for this basis or the instrument moved."
        echo "  NOTHING WRITTEN — do not re-freeze to make this green (that"
        echo "  silently redefines the baseline the superset invariant rests on)."
        exit 1
    fi
fi

mkdir -p "$DEST/logs"
printf '%s\n' "$MASK" > "$DEST/MASK"
names="$*"
pool=0
for name in $names; do
    freeze_one "$name" "$DEST" &
    pool=$((pool + 1))
    if [ "$pool" -ge "$JOBS" ]; then wait; pool=0; fi
done
wait

fail=0
for name in $names; do
    if [ -f "$WORK/out_$name" ]; then cat "$WORK/out_$name"; fi
    if [ -f "$WORK/fail_$name" ]; then fail=1; fi
done
[ "$fail" = 0 ] && echo "BASIS FROZEN: $DEST" || { echo "BASIS INCOMPLETE"; exit 1; }
