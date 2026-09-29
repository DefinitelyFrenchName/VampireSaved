#!/bin/sh
# test_static_confirm.sh — the static tier's carry-forward predictor marks a gate STALE by every rule
# it states (`tools/static_confirm.py`, 14z-185b, GitHub #188 route A — PROVISIONAL).
#
# WHAT: tools/static_confirm.py's predictions mean what they say: a changed path makes a gate STALE
#   when it is a program in the gate's reach (R1), is named by basename on a code line of the reach
#   (R2), lies under a directory the reach reads (R3), or the reach reads the whole tree (R4); any
#   other gate is CARRIED.
# HOW: drives the predictor's selftest over a synthetic repo of five gates, one per reader class,
#   with known answers; two controls run copies with the directory rule and the whole-tree rule
#   removed, and each must fail the selftest.
# EXPECTS: the selftest's six cases pass and both controls fail on their copies. The HISTORY
#   backtest (tests/expected/static_confirm_backtest.tsv, `static_confirm.py backtest`) takes
#   minutes of worktrees and is run by hand, not here.
#
# PROVISIONAL (maintainer-ruled 2026-09-29, "History for now, traced on WSL2 later"): the predictor
# is not wired into tests/run_all_static.sh. This gate locks its rules; it does not claim they are
# enough — only a Linux run of the tier under strace, every gate's ACTUAL reads, can show that.
#
# MUST-FIRE: perturbed-copy: no-dir-rule — a copy with R3 (directory readers) removed must carry the gate that globs docs/game, and the selftest must FAIL (mode: that copy's selftest)
# MUST-FIRE: perturbed-copy: no-whole-rule — a copy with R4 (whole-tree readers) removed must carry the git ls-files gate, and the selftest must FAIL (mode: that copy's selftest)
#
# Usage: tests/test_static_confirm.sh      # ci_portable, ~1 s
set -eu
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
. "$REPO/tests/lib/controls.sh"; vs_ctl_mode "$0"
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT

make_copy() {  # make_copy <control> — a copy of tools/ with ONE perturbation in the predictor
    mkdir -p "$W/$1/tools"; cp tools/static_confirm.py tools/battery_reach.py "$W/$1/tools/"
    python3 - "$W/$1/tools/static_confirm.py" "$1" <<'PY'
import sys; p, name = sys.argv[1:3]; s = open(p).read()
edits = {
    "no-dir-rule": ('+ [("R3", rx, d) for d, rx in dps]', '+ []  # CONTROL no-dir-rule'),
    "no-whole-rule": ("        if not why and changed and WHOLE.search(blob):", "        if False:  # CONTROL no-whole-rule"),
}
a, b = edits[name]
assert s.count(a) == 1, name
open(p, "w").write(s.replace(a, b, 1))
PY
    echo "$W/$1/tools/static_confirm.py"
}

echo "== test_static_confirm: #188 route A — the carry-forward predictor (PROVISIONAL) =="
fail=0
SC=tools/static_confirm.py
if vs_ctl_is no-dir-rule || vs_ctl_is no-whole-rule; then SC="$(make_copy "$VS_CTL")"; fi
python3 "$SC" --selftest > "$W/self.txt" 2>&1 || true
sed 's/^/  /' "$W/self.txt"
grep -q '^SELFTEST PASS$' "$W/self.txt" || { echo "FAIL: the predictor's selftest"; fail=1; }

if [ -z "${VS_CTL:-}" ]; then
    for c in no-dir-rule no-whole-rule; do
        python3 "$(make_copy "$c")" --selftest > "$W/ctl_$c.txt" 2>&1 || true
        if grep -q '^SELFTEST FAIL$' "$W/ctl_$c.txt"; then vs_ctl_fired "$c" "$(grep -m1 'FAIL:' "$W/ctl_$c.txt" | sed 's/^ *//')"
        else vs_ctl_dead "$c" "the perturbed copy passed its selftest — the selftest cannot see this failure" || fail=1; fi
    done
fi

if [ "$fail" = 0 ]; then echo "PASS: the predictor marks STALE by each of its four rules and carries the rest (provisional: not wired, not traced)"
else echo "FAIL: test_static_confirm"; exit 1; fi
