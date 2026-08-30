#!/bin/sh
# test_gotchas_index_current.sh — docs/GOTCHAS.md FOLLOWS the three bucket
# files (14z-122, the documentation rationalization pass). ci_portable: no
# ROM, no build dir, no emulator, ~1 s.
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
set -u
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
fail=0
ok()  { printf '  ok    %s\n' "$1"; }
bad() { printf '  FAIL  %s\n' "$1"; fail=1; }

echo "== test_gotchas_index_current: the index follows the buckets =="
if python3 tools/gen_gotchas_index.py --check >/tmp/gotchas_idx.$$.log 2>&1; then
    ok "index matches a regeneration from the three buckets"
else
    bad "gen_gotchas_index.py --check FAILS:"; sed 's/^/        /' /tmp/gotchas_idx.$$.log | head -20
fi
rm -f /tmp/gotchas_idx.$$.log

FILES="docs/GOTCHAS.md docs/game/gotchas.md docs/platform/gotchas.md docs/project/gotchas.md"
mkcopy() { for f in $FILES; do mkdir -p "$1/$(dirname "$f")"; cp "$f" "$1/$f"; done; }
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT INT TERM

# a: a new bucket entry changes the render and appears in it
mkcopy "$W/a"; printf '\n## A synthetic trap for the control (paid: 14z-999)\nbody\n' >> "$W/a/docs/game/gotchas.md"
if python3 tools/gen_gotchas_index.py --root "$W/a" --check --no-selftest >"$W/a/log" 2>&1; then
    bad "control a: a new bucket entry did not fail --check"
elif grep -q 'A synthetic trap for the control' "$W/a/log"; then
    ok "control a: a new bucket entry fires and is named in the diff"
else
    bad "control a: failed for the wrong reason:"; sed 's/^/        /' "$W/a/log" | head -8
fi

# b: a hand-edit to the committed index fails the cmp
mkcopy "$W/b"; printf -- '- a bullet somebody hand-added\n' >> "$W/b/docs/GOTCHAS.md"
if python3 tools/gen_gotchas_index.py --root "$W/b" --check --no-selftest >"$W/b/log" 2>&1; then
    bad "control b: a hand-edited index passed --check"
else
    ok "control b: a hand-edited index fires"
fi

if [ "$fail" = 0 ]; then echo "PASS"; else echo "FAIL"; exit 1; fi
