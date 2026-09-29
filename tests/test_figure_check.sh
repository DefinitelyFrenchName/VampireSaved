#!/bin/sh
# test_figure_check.sh — a close's stated figures equal their sources, and a claim's figures are each
# checked or named unchecked (`tools/figure_check.py`, 14z-185b, GitHub #190 P1).
#
# WHAT: tools/figure_check.py fails on each of its four conditions and only then: a stated figure
#   that differs from its source (MISMATCH), a figure or source value its regex cannot find (NOT
#   FOUND), a claim figure neither checked nor named unchecked (UNCOVERED), and an unchecked row
#   the claim no longer needs (STALE); a clean spec passes.
# HOW: drives the tool's selftest (five cases over a synthetic row, claim and output); four controls
#   — one per condition of the verdict (#185 item 5, one plant per conjunct) — run copies with that
#   condition switched off, and each must fail the selftest.
# EXPECTS: the selftest's five cases read as designed and all four controls fail on their copies.
#
# WHY. The 14z-185 close's rule-checker runs 417, 424, 436 and 440 each found a figure its prose
# stated that no check compared, or a claim figure nobody listed; the scratch checker that answered
# them hard-coded that close's phrases. The maintainer ruled its promotion: "P1+P2, then P4".
#
# MUST-FIRE: perturbed-copy: mismatch-ignored — a copy that never reports a MISMATCH must pass the mismatch case, and the selftest must FAIL (mode: that copy's selftest)
# MUST-FIRE: perturbed-copy: notfound-ignored — a copy that skips a NOT FOUND row silently must pass the not-found case, and the selftest must FAIL (mode: that copy's selftest)
# MUST-FIRE: perturbed-copy: uncovered-ignored — a copy that never counts an UNCOVERED claim figure must pass the uncovered case, and the selftest must FAIL (mode: that copy's selftest)
# MUST-FIRE: perturbed-copy: stale-ignored — a copy that never counts a STALE unchecked row must pass the stale case, and the selftest must FAIL (mode: that copy's selftest)
#
# Usage: tests/test_figure_check.sh      # ci_portable, ~1 s
set -eu
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
. "$REPO/tests/lib/controls.sh"; vs_ctl_mode "$0"
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT

make_copy() {  # make_copy <control> — a copy of tools/ with ONE perturbation in the checker
    mkdir -p "$W/$1/tools/agent"; cp tools/figure_check.py "$W/$1/tools/"; cp tools/agent/extract.py tools/agent/agentlib.py "$W/$1/tools/agent/"
    python3 - "$W/$1/tools/figure_check.py" "$1" <<'PY'
import sys; p, name = sys.argv[1:3]; s = open(p).read()
edits = {
    "mismatch-ignored": ("        if norm(a) != norm(b):\n", "        if False:  # CONTROL mismatch-ignored\n"),
    "notfound-ignored": ("            bad += 1\n            continue\n", "            continue  # CONTROL notfound-ignored\n"),
    "uncovered-ignored": ("claim figure {f}: no figure row states it and no unchecked row names it\")\n                bad += 1\n",
                          "claim figure {f}: no figure row states it and no unchecked row names it\")  # CONTROL uncovered-ignored\n"),
    "stale-ignored": ("\"empty reason\"))\n                bad += 1\n", "\"empty reason\"))  # CONTROL stale-ignored\n"),
}
a, b = edits[name]
assert s.count(a) == 1, name
open(p, "w").write(s.replace(a, b, 1))
PY
    echo "$W/$1/tools/figure_check.py"
}

echo "== test_figure_check: #190 P1 — stated figures against their sources, and the claim's census =="
fail=0
FC=tools/figure_check.py
case "${VS_CTL:-}" in mismatch-ignored|notfound-ignored|uncovered-ignored|stale-ignored) FC="$(make_copy "$VS_CTL")" ;; esac
python3 "$FC" --selftest > "$W/self.txt" 2>&1 || true
sed 's/^/  /' "$W/self.txt"
grep -q '^SELFTEST PASS$' "$W/self.txt" || { echo "FAIL: the checker's selftest"; fail=1; }

if [ -z "${VS_CTL:-}" ]; then
    for c in mismatch-ignored notfound-ignored uncovered-ignored stale-ignored; do
        python3 "$(make_copy "$c")" --selftest > "$W/ctl_$c.txt" 2>&1 || true
        if grep -q '^SELFTEST FAIL$' "$W/ctl_$c.txt"; then vs_ctl_fired "$c" "$(grep -m1 '  FAIL:' "$W/ctl_$c.txt" | sed 's/^ *//')"
        else vs_ctl_dead "$c" "the perturbed copy passed its selftest — the selftest cannot see this failure" || fail=1; fi
    done
fi

if [ "$fail" = 0 ]; then echo "PASS: each of the four failure conditions fails the check, and a clean spec passes"
else echo "FAIL: test_figure_check"; exit 1; fi
