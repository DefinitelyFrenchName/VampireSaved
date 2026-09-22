#!/bin/sh
# attribute_expectation.sh <gate> --since <commit> [--paths "p1 p2 …"] [--timeout N]
#
# A FROZEN EXPECTATION WENT RED. WAS IT THE SUBJECT, OR THE RIG?
#
# The one-variable answer: put the named paths back to what they were when the
# expectation was frozen, change NOTHING else, and re-run the gate.
#   PASS -> the whole delta is those paths. The subject did not move.
#   FAIL -> something else moved too, and re-freezing would bury it.
#
# WHY THIS IS A TOOL AND NOT A ONE-OFF (14z-174, GitHub #171). The M19 release tier
# came back with three expectations red, and "the rigs moved" was a plausible story
# for all three. A story is not an attribution. This ran it as a measurement, and it
# also caught the one case where the story was wrong in detail: the DF=195 shift
# named as a cause for test_killshread_es could not reach that rig at all.
#
# TWO TRAPS IT EXISTS TO AVOID, both paid for on the day:
#
#  1. RESTORE EVERYTHING THE GATE CONSUMES, NOT JUST THE OBVIOUS FILES. The first
#     attribution of test_killshread_es restored tests/replays/naming and left
#     tools/name_moves.py current — but that gate REGENERATES its rig from the
#     generator and compares, so it failed on its own "rig drifted" check and the
#     result read as a subject defect. Pass every path the gate reads.
#  2. NEVER RESTORE A WORKING FILE WITH `git checkout HEAD --`. If a path carries
#     UNCOMMITTED work, HEAD does not have it and the checkout destroys it silently.
#     This script saves every path first and restores from the saved copy, then
#     verifies with sha256 — and `git checkout <commit> -- path` also STAGES the old
#     version, so the index is reset too (that one bit after the fact: a commit would
#     have shipped the old file while the working tree looked right).
#
# Usage:
#   tools/attribute_expectation.sh test_killshread_es --since e3f7537c \
#       --paths "tests/replays/naming tools/name_moves.py"
set -eu
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"

GATE=""; SINCE=""; PATHS="tests/replays"; TMO=1800
while [ $# -gt 0 ]; do
    case "$1" in
        --since)   SINCE="$2"; shift 2 ;;
        --paths)   PATHS="$2"; shift 2 ;;
        --timeout) TMO="$2"; shift 2 ;;
        -*)        echo "unknown option $1" >&2; exit 2 ;;
        *)         GATE="$1"; shift ;;
    esac
done
[ -n "$GATE" ] && [ -n "$SINCE" ] || { sed -n '2,12p' "$0"; exit 2; }
[ -f "tests/$GATE.sh" ] || { echo "no such gate: tests/$GATE.sh" >&2; exit 2; }
git rev-parse --verify "$SINCE^{commit}" >/dev/null 2>&1 || { echo "--since $SINCE: not a commit" >&2; exit 2; }

# THE EXPERIMENT IS ONLY MEANINGFUL AGAINST THE EXPECTATION THAT WAS FROZEN AT
# --since. If the gate's expectation has been RE-FROZEN in between, restoring the
# rig alone compares old rig against new rows and reports NOT ATTRIBUTED for a
# reason that has nothing to do with the subject (measured 14z-174: the same gate
# attributed cleanly before its re-freeze and read as unattributed after).
# So: name any moved expectation, and refuse unless it is being restored too.
EXPS="$(grep -ohE 'tests/expected/[A-Za-z0-9_./-]+' "tests/$GATE.sh" | sort -u || true)"
STALE=""
for e in $EXPS; do
    [ -e "$e" ] || continue
    case " $PATHS " in *" $e "*) continue ;; esac
    if ! git diff --quiet "$SINCE" -- "$e" 2>/dev/null; then STALE="$STALE $e"; fi
done
if [ -n "$STALE" ]; then
    echo "REFUSING: this gate's expectation has moved since $SINCE and is not being restored:" >&2
    for e in $STALE; do echo "    $e" >&2; done
    echo "  Restoring the rig alone would compare the OLD rig against the NEW rows," >&2
    echo "  which answers a different question. Add them to --paths, or pick a --since" >&2
    echo "  at which the expectation and the rig belong together." >&2
    exit 2
fi

SAVE="$(mktemp -d)"
SUMS="$SAVE/sums.txt"
: > "$SUMS"
for p in $PATHS; do
    [ -e "$p" ] || continue
    mkdir -p "$SAVE/copy/$(dirname "$p")"
    cp -R "$p" "$SAVE/copy/$p"
    find "$p" -type f -exec shasum -a 256 {} + >> "$SUMS" 2>/dev/null || true
done

restore() {
    for p in $PATHS; do
        [ -e "$SAVE/copy/$p" ] || continue
        rm -rf "$p"; mkdir -p "$(dirname "$p")"; cp -R "$SAVE/copy/$p" "$p"
    done
    # the checkout staged the OLD content; put the index back where it was
    git reset -q -- $PATHS 2>/dev/null || true
    # NO PROCESS SUBSTITUTION: this is #!/bin/sh, where `<(...)` is a syntax error
    # (paid 14z-174 — the script would not parse, so it never ran at all).
    now="$(mktemp)"; a="$(mktemp)"; b="$(mktemp)"
    for p in $PATHS; do
        [ -e "$p" ] || continue
        find "$p" -type f -exec shasum -a 256 {} + >> "$now" 2>/dev/null || true
    done
    sort "$SUMS" > "$a"; sort "$now" > "$b"
    if cmp -s "$a" "$b"; then
        echo "RESTORED: every path byte-identical to before the run (sha256)"
    else
        echo "RESTORE FAILED — the saved copies are in $SAVE/copy; DO NOT COMMIT until this is resolved"
        diff "$a" "$b" | head -5
    fi
    rm -f "$now" "$a" "$b"
}
trap restore EXIT INT TERM

echo "== attributing $GATE: restoring to $SINCE =="
for p in $PATHS; do printf '   %s\n' "$p"; done
git checkout "$SINCE" -- $PATHS
echo "   files now differing from HEAD: $(git status --porcelain -- $PATHS | wc -l | tr -d ' ')"

rc=0
timeout "$TMO" "tests/$GATE.sh" > "$SAVE/run.log" 2>&1 || rc=$?
echo
if [ "$rc" = 0 ]; then
    echo "ATTRIBUTED: $GATE PASSES with those paths at $SINCE."
    echo "  So the whole delta is those paths — the gate's SUBJECT did not move."
    echo "  Re-freezing records the new rig; review the diff field by field first."
else
    echo "NOT ATTRIBUTED: $GATE still FAILS with those paths at $SINCE (rc=$rc)."
    echo "  Something else moved as well. Do NOT re-freeze on the rig story."
    grep -E '^(  FAIL|FAIL)' "$SAVE/run.log" | head -4 | sed 's/^/    /'
    echo "  full log: $SAVE/run.log"
fi
exit "$rc"
