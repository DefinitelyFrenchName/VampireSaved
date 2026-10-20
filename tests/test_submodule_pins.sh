#!/bin/sh
# test_submodule_pins.sh — the submodule-pin check's verdicts mean what they say (`tools/submodule_pins.py`, GitHub #260).
#
# WHAT: tools/submodule_pins.py, which the session close runs as its `pins` step before the push
#   (docs/project/session_close.md; ruled 2026-10-19, 14z-205), reads OK for a pin its remote serves (a tip or an
#   ancestor), MISSING (exit 1) for a pin only the local clone holds (the 14z-192 shape) or one of two pins unpushed,
#   ERROR (exit 2, never a pass) for a remote it cannot reach, and MISSING for its plant on a passing tree.
# HOW: drives the tool's selftest (a bare file:// remote, a clone holding one commit it never pushed, a superproject
#   pinning each case; no network, ~1 s a run); two controls run copies of the tool with one verdict switched off.
# EXPECTS: the selftest's six cases read as designed, and both copies fail it.
#
# MUST-FIRE: perturbed-copy: refused-blind — a copy that never reads the remote's refusal as MISSING must class the unpushed commit as ERROR (exit 2, not 1), and the selftest must FAIL
# MUST-FIRE: perturbed-copy: error-passes — a copy that returns 0 when a pin could not be checked must pass the unreachable remote, and the selftest must FAIL
#
# WHY. The check ran as three close-check rows from 14z-197 (`tests/close_standing_checks.tsv`); #288 cut the close
# checks on 2026-10-15, and nothing ran it before the pushes after. The maintainer, 2026-10-19: "#260 make it a close
# step". The close step runs the real check on the network; this gate keeps its logic tested in every tier.
#
# Usage: tests/test_submodule_pins.sh      # ci_portable, ~3 s
set -eu
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
. "$REPO/tests/lib/controls.sh"; vs_ctl_mode "$0"
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT

make_copy() {  # make_copy <control> — a copy of the tool with ONE perturbation
    mkdir -p "$W/$1"; cp tools/submodule_pins.py "$W/$1/"
    python3 - "$W/$1/submodule_pins.py" "$1" <<'PY'
import sys; p, name = sys.argv[1:3]; s = open(p).read()
edits = {
    "refused-blind": ("        if any(m in err for m in REFUSED):\n", "        if False:  # CONTROL refused-blind\n"),
    "error-passes": ('    return 1 if counts["MISSING"] else 2 if counts["ERROR"] else 0\n',
                     '    return 1 if counts["MISSING"] else 0  # CONTROL error-passes\n'),
}
a, b = edits[name]
assert s.count(a) == 1, name
open(p, "w").write(s.replace(a, b, 1))
PY
    echo "$W/$1/submodule_pins.py"
}

echo "== test_submodule_pins: #260 — a pin its remote does not serve is MISSING, an unanswered one is never a pass =="
fail=0
SP=tools/submodule_pins.py
case "${VS_CTL:-}" in refused-blind|error-passes) SP="$(make_copy "$VS_CTL")" ;; esac
python3 "$SP" --selftest > "$W/self.txt" 2>&1 || true
sed 's/^/  /' "$W/self.txt"
grep -q '^SELFTEST PASS$' "$W/self.txt" || { echo "FAIL: the tool's selftest"; fail=1; }

if [ -z "${VS_CTL:-}" ]; then
    for c in refused-blind error-passes; do
        python3 "$(make_copy "$c")" --selftest > "$W/ctl_$c.txt" 2>&1 || true
        if grep -q '^SELFTEST FAIL$' "$W/ctl_$c.txt"; then vs_ctl_fired "$c" "$(grep -m1 '  FAIL:' "$W/ctl_$c.txt" | sed 's/^ *//')"
        else vs_ctl_dead "$c" "the perturbed copy passed its selftest — the selftest cannot see this failure" || fail=1; fi
    done
fi

if [ "$fail" = 0 ]; then echo "PASS: a pin its remote does not serve fails the check, and a pin that could not be checked is never a pass"
else echo "FAIL: test_submodule_pins"; exit 1; fi
