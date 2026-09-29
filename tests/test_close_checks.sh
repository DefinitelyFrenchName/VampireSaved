#!/bin/sh
# test_close_checks.sh — the close's check runner times every check, re-runs one alone, and never
# lets a partial run read as the run of record (`tools/close_checks.py`, 14z-185b, GitHub #187).
#
# WHAT: tools/close_checks.py's verdicts mean what they say: a check is OK when its exit equals
#   its EXPECTED exit (a plant expects non-zero), every row carries its seconds, `--only` re-runs
#   one check and records the run partial, and `status` accepts only a FULL, all-OK run of the
#   current checks file.
# HOW: drives the runner's selftest over a synthetic checks file with known answers; two controls
#   run copies with the partial marker forced to full and the expected exit ignored, and each must
#   fail the selftest.
# EXPECTS: the selftest's eight checks pass and both controls fail on their copies; a red names
#   the check.
#
# WHY. The 14z-185 close ran its scratch check runner 62 times, 18,799 s in all, every check every
# time, with no per-check seconds (tools/agent/close_loop_cost.py). The maintainer ruled "D + E + F
# now" (DECISIONS_HISTORY.md, 2026-09-29): this runner is E. A partial run passing as the run of
# record would be the new failure it could introduce, so that is what the first control plants.
#
# MUST-FIRE: perturbed-copy: partial-as-full — a copy of the runner that records every run full must let status accept a partial run, and the selftest must FAIL (mode: that copy's selftest)
# MUST-FIRE: perturbed-copy: expect-ignored — a copy that judges a check by exit 0 alone must read the expected-failure plant NOT AS EXPECTED, and the selftest must FAIL (mode: that copy's selftest)
#
# Usage: tests/test_close_checks.sh      # ci_portable, ~1 s
set -eu
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
. "$REPO/tests/lib/controls.sh"; vs_ctl_mode "$0"
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT

make_copy() {  # make_copy <control> — a copy of the runner with ONE perturbation
    mkdir -p "$W/$1"; cp tools/close_checks.py "$W/$1/close_checks.py"
    python3 - "$W/$1/close_checks.py" "$1" <<'PY'
import sys; p, name = sys.argv[1:3]; s = open(p).read()
edits = {
    "partial-as-full": ('    kind = "partial" if only else "full"\n', '    kind = "full"  # CONTROL partial-as-full\n'),
    "expect-ignored": ('        verdict = "OK" if st == expect else "NOT AS EXPECTED"\n',
                       '        verdict = "OK" if st == 0 else "NOT AS EXPECTED"  # CONTROL expect-ignored\n'),
}
a, b = edits[name]
assert s.count(a) == 1, name
open(p, "w").write(s.replace(a, b, 1))
PY
    echo "$W/$1/close_checks.py"
}

echo "== test_close_checks: #187 — the close's check runner =="
fail=0
CC=tools/close_checks.py
if vs_ctl_is partial-as-full || vs_ctl_is expect-ignored; then CC="$(make_copy "$VS_CTL")"; fi
python3 "$CC" --selftest > "$W/self.txt" 2>&1 || true
sed 's/^/  /' "$W/self.txt"
grep -q '^SELFTEST PASS$' "$W/self.txt" || { echo "FAIL: the runner's selftest"; fail=1; }

if [ -z "${VS_CTL:-}" ]; then
    for c in partial-as-full expect-ignored; do
        python3 "$(make_copy "$c")" --selftest > "$W/ctl_$c.txt" 2>&1 || true
        if grep -q '^SELFTEST FAIL$' "$W/ctl_$c.txt"; then vs_ctl_fired "$c" "$(grep -m1 'FAIL:' "$W/ctl_$c.txt" | sed 's/^ *//')"
        else vs_ctl_dead "$c" "the perturbed copy passed its selftest — the selftest cannot see this failure" || fail=1; fi
    done
fi

if [ "$fail" = 0 ]; then echo "PASS: the runner times every check, re-runs one alone, and keeps a partial run from reading as the run of record"
else echo "FAIL: test_close_checks"; exit 1; fi
