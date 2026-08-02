#!/bin/sh
# run_suite.sh — the oracle replay suite (MAME side), auto-detecting runner.
#
# Usage: ROMDIR=... [MAME_ROMPATH="patched_dir;$ROMDIR"] tests/run_suite.sh [--freeze] [set]
#
# The build under test is whatever the rompath resolves (vanilla by default;
# set MAME_ROMPATH to front a patched build). Its program-image fingerprint
# is looked up in tests/expected/registry.tsv and selects the expectation
# directory tests/expected/<expset>/ (CLAUDE.md §4 auto-detecting runner).
# An unregistered fingerprint fails loudly — registry rows are added only at
# freeze time as a build decision recorded in STATE.md.
#
# For every tests/replays/*.rpl: run twice, fail on nondeterminism, then:
#   <name>.skip expectation: replay not applicable to this set (e.g. it
#     targets another romset); body = the reason, printed.
#   <name>.masked expectation (hooked builds; CLAUDE.md §4 amended basis —
#     both runs use MASK_RANGES matching docs/atlas/ram.md):
#       exact <baseset>              bit-identical to the frozen masked log
#                                    tests/expected/<baseset>/logs/<name>.log
#       flicker <baseset> <n> <csv>  compare_flicker verdict must be exactly
#                                    "FLICKER <n> <csv>" (frozen inventory;
#                                    §4 v2 — drift in either direction is a
#                                    loud failure, not tolerance headroom)
#       diverge <baseset> <frame>    first divergence exactly at <frame>
#   <name>.diverge expectation ("<baseset> <frame>"): the log must be
#     line-identical to the frozen full log tests/expected/<baseset>/logs/
#     <name>.log through frame-1 and FIRST diverge exactly at <frame> —
#     for replays that legitimately involve a patched slot (e.g. attract
#     demos). The superset invariant is never weakened, only specified.
#   <name>.sha1 expectation: whole-log SHA-1 equality (the default).
#   --freeze: write sha1 + full log copies instead of comparing. Replays
#     carrying .skip or .masked are left untouched (those expectations are
#     authored from the gate inventory, not self-frozen).
set -eu

FREEZE=0
if [ "${1:-}" = "--freeze" ]; then FREEZE=1; shift; fi
SET="${1:-vsavj}"
ROMDIR="${ROMDIR:?set ROMDIR to the reference-set directory}"
REPO="$(cd "$(dirname "$0")/.." && pwd)"
ROMPATH="${MAME_ROMPATH:-$ROMDIR}"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

EXPSET=$(python3 "$REPO/tools/build_fingerprint.py" "$ROMPATH" --set "$SET") \
    || { echo "unregistered build fingerprint — see message above"; exit 1; }
EXPDIR="$REPO/tests/expected/$EXPSET"
mkdir -p "$EXPDIR"
echo "build fingerprint -> expectation set '$EXPSET'"

# check_diverge <log> <spec-file> -> prints verdict, returns 0/1
check_diverge() {
    python3 "$REPO/tools/check_diverge.py" "$1" "$2" "$REPO/tests/expected"
}

# The masked windows of the amended legacy basis (docs/atlas/ram.md:
# dead stack $FF7F00-$FF7FFF + QSound latch $FF043C + the 14z-49 palette
# staging slot $FF4182-$FF41A1, ratified round 64). Must stay in sync
# with M2A_MASK in tests/lib/m2a_common.sh.
MASK="043c-043d,4182-41a2,7f00-8000"

fail=0
for rpl in "$REPO"/tests/replays/*.rpl; do
    name="$(basename "$rpl" .rpl)"
    printf '%-24s ' "$name"
    if [ -f "$EXPDIR/$name.skip" ]; then
        echo "SKIP ($(cat "$EXPDIR/$name.skip"))"
        continue
    fi
    RUNMASK=""
    [ -f "$EXPDIR/$name.masked" ] && RUNMASK="$MASK"
    MASK_RANGES="$RUNMASK" "$REPO/tools/run_replay_mame.sh" "$SET" "$rpl" "$WORK/$name.1.log" || { echo "RUN-FAIL"; fail=1; continue; }
    MASK_RANGES="$RUNMASK" "$REPO/tools/run_replay_mame.sh" "$SET" "$rpl" "$WORK/$name.2.log" || { echo "RUN-FAIL"; fail=1; continue; }
    if ! cmp -s "$WORK/$name.1.log" "$WORK/$name.2.log"; then
        echo "NONDETERMINISTIC (first divergent frame below)"
        diff "$WORK/$name.1.log" "$WORK/$name.2.log" | head -3
        fail=1
        continue
    fi
    sha=$(shasum "$WORK/$name.1.log" | cut -d' ' -f1)
    if [ "$FREEZE" = 1 ] && [ -n "$RUNMASK" ]; then
        echo "authored .masked expectation — not self-frozen"
    elif [ "$FREEZE" = 1 ]; then
        echo "$sha" > "$EXPDIR/$name.sha1"
        mkdir -p "$EXPDIR/logs"
        cp "$WORK/$name.1.log" "$EXPDIR/logs/$name.log"
        echo "frozen $sha"
    elif [ -n "$RUNMASK" ]; then
        spec=$(cat "$EXPDIR/$name.masked")
        class=${spec%% *}; rest=${spec#* }; base=${rest%% *}; args=${rest#* }
        baselog="$REPO/tests/expected/$base/logs/$name.log"
        case "$class" in
        exact)
            if cmp -s "$baselog" "$WORK/$name.1.log"; then
                echo "PASS masked-exact"
            else
                echo "FAIL masked live-state diverged from $base"; fail=1
            fi ;;
        flicker)
            verdict=$(python3 "$REPO/tools/compare_flicker.py" "$baselog" "$WORK/$name.1.log") || true
            if [ "$verdict" = "FLICKER $args" ]; then
                echo "PASS masked-flicker ($verdict — frozen inventory)"
            else
                echo "FAIL masked-flicker: got '$verdict' expected 'FLICKER $args' (frozen; drift either way is loud — CLAUDE.md §4 standing watch)"; fail=1
            fi ;;
        diverge)
            printf '%s %s' "$base" "$args" > "$WORK/$name.mdiverge"
            check_diverge "$WORK/$name.1.log" "$WORK/$name.mdiverge" || fail=1 ;;
        *)
            echo "FAIL unknown .masked class '$class'"; fail=1 ;;
        esac
    elif [ -f "$EXPDIR/$name.diverge" ]; then
        check_diverge "$WORK/$name.1.log" "$EXPDIR/$name.diverge" || fail=1
    elif [ ! -f "$EXPDIR/$name.sha1" ]; then
        echo "NO-EXPECTATION (freeze after review, as a STATE.md decision)"
        fail=1
    elif [ "$sha" = "$(cat "$EXPDIR/$name.sha1")" ]; then
        echo "PASS"
    else
        echo "FAIL expected $(cat "$EXPDIR/$name.sha1") got $sha"
        cp "$WORK/$name.1.log" "$WORK/$name.divergent.log" 2>/dev/null || true
        fail=1
    fi
done

[ "$fail" = 0 ] && echo "SUITE GREEN" || echo "SUITE RED"
exit "$fail"
