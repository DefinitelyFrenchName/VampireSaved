#!/bin/sh
# test_gotchas_index_current.sh — docs/GOTCHAS.md FOLLOWS the three bucket
# files (14z-122, the documentation rationalization pass). ci_portable: no
# ROM, no build dir, no emulator, ~1 s.
#
# MUST-FIRE: perturbed-copy: new-bucket-entry — a `## ` entry appended to a bucket must fail --check and be NAMED in the diff, or a new gotcha can miss the index silently
# MUST-FIRE: perturbed-copy: hand-edited-index — a bullet hand-added to the committed index must fail the cmp, or the index stops being generated
#
# WHAT IT HOLDS. `tools/gen_gotchas_index.py --check` regenerates the index
# (one line per bucket `## ` entry — consecutive `## ` lines are one wrapped
# header — with anchor tokens stripped) and cmp's it against the committed
# file, the test_tables_current pattern. WHY: the index was hand-maintained
# and had already desynced once (a 14z-118 entry records an index line
# missing while the bucket entry existed); it had also accreted ten
# per-session digests and a third abridged copy of the buckets — all moved
# verbatim to docs/GOTCHAS_history.md at 14z-122.
#
# MUST-FIRE CONTROLS on a perturbed copy (RH-9): a new bucket entry must
# change the render AND appear in it; a hand-edit to the committed index
# must fail the cmp.
#
# HANDOFF's gate-table note, moved into this header 14z-123 (verbatim; the
# documentation pass ruled a gate's WHY lives in the gate):
#   (tier ci_portable (~1 s)) docs/GOTCHAS.md IS GENERATED (14z-122):
#   `tools/gen_gotchas_index.py --check` regenerates the index from the three
#   buckets' `## ` headers (consecutive `## ` lines are ONE wrapped header,
#   `[PFX-N]` tokens stripped, `(paid:)` tags kept so a grep that hits the
#   index hits the bucket; no per-entry slug links on purpose) and `cmp`s it —
#   the `test_tables_current` pattern. The hand-written index it replaced (ten
#   `### appended 14z-N` digests + a third abridged copy of the buckets) is
#   verbatim in `docs/GOTCHAS_history.md`. After appending a gotcha,
#   REGENERATE: `python3 tools/gen_gotchas_index.py`. Two must-fire controls
set -u
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
fail=0
ok()  { printf '  ok    %s\n' "$1"; }
bad() { printf '  FAIL  %s\n' "$1"; fail=1; }
. "$REPO/tests/lib/controls.sh"; vs_ctl_mode "$0"
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT INT TERM

FILES="docs/GOTCHAS.md docs/game/gotchas.md docs/platform/gotchas.md docs/project/gotchas.md"
mkcopy() { for f in $FILES; do mkdir -p "$1/$(dirname "$f")"; cp "$f" "$1/$f"; done; }
perturb() {  # perturb <name> <dir>; EXPECT = the failure's substring
    case "$1" in
    new-bucket-entry)  printf '\n## A synthetic trap for the control (paid: 14z-999)\nbody\n' >> "$2/docs/game/gotchas.md"; EXPECT="A synthetic trap for the control" ;;
    hand-edited-index) printf -- '- a bullet somebody hand-added\n' >> "$2/docs/GOTCHAS.md"; EXPECT="" ;;
    *) echo "no such perturbation: $1"; exit 3 ;;
    esac
}

# THE EXECUTABLE FORM: under CONTROL=<name> the perturbed copy IS the tree
# the main check reads, and this run must FAIL.
ROOT="$REPO"; SELFTEST=""
if [ -n "$VS_CTL" ]; then mkcopy "$W/mode"; perturb "$VS_CTL" "$W/mode"; ROOT="$W/mode"; SELFTEST="--no-selftest"; fi

echo "== test_gotchas_index_current: the index follows the buckets =="
if python3 tools/gen_gotchas_index.py --root "$ROOT" --check $SELFTEST >"$W/tree.log" 2>&1; then
    ok "index matches a regeneration from the three buckets"
else
    bad "gen_gotchas_index.py --check FAILS:"; sed 's/^/        /' "$W/tree.log" | head -20
fi

control() {  # control <name>
    d="$W/$1"; mkcopy "$d"; perturb "$1" "$d"
    if python3 tools/gen_gotchas_index.py --root "$d" --check --no-selftest >"$d/log" 2>&1; then
        vs_ctl_dead "$1" "the perturbed copy PASSED — the check is not checking"; bad "$1"
    elif [ -z "$EXPECT" ] || grep -q "$EXPECT" "$d/log"; then
        vs_ctl_fired "$1" "${EXPECT:-the perturbed copy fails --check}"; ok "$1: fires"
    else
        vs_ctl_dead "$1" "failed for the wrong reason"; bad "$1:"; sed 's/^/        /' "$d/log" | head -8
    fi
}
for n in $(vs_ctl_declared "$0"); do control "$n"; done

if [ "$fail" = 0 ]; then echo "PASS"; else echo "FAIL"; exit 1; fi
