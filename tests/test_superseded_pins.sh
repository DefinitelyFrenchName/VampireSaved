#!/bin/sh
# test_superseded_pins.sh — no live line in tests/ or tools/ pins a fingerprint the registry has
# SUPERSEDED (`tools/superseded_pins.py`, 14z-185b, GitHub #167).
#
# WHAT: no program under tests/ or tools/ holds, on a live line, a hex token that is a prefix of a
#   superseded registry key (a key a family's older row carries and its current row does not); a
#   comment, a docstring and a `RE-FROZEN … (was …)` note never count; the rule-checker's birth key
#   is the one named exemption, and an exemption that no live pin uses any more fails as stale.
# HOW: runs the tool's selftest (seven cases), then the tool over this tree; two controls plant, in a
#   scratch root built from this tree's own registry, a live pin on a real superseded key, and a
#   rulecheck.py without its birth key — each must be refused.
# EXPECTS: the selftest PASS, the tree clean (0 live pins, 0 stale exemptions), both controls FAIL
#   their scratch root.
#
# WHY. A freeze's re-point sweep renames build NAMES; a pinned FINGERPRINT names no build, so the M19
# freeze left tests/test_phasec_spaces.sh holding donovan-m19-stock's key and it went red only at the
# close tier (docs/project/gotchas.md "THE RE-POINT SWEEP SEES BUILD NAMES IN THIS TREE"). The
# sibling for build-dir references is test_build_ref_rot.sh.
#
# MUST-FIRE: known-bad: planted-pin — a scratch root with this tree's registry and a live pin on a real superseded key must be refused (mode: the gate checks that root)
# MUST-FIRE: known-bad: stale-exemption — a scratch root whose tools/rulecheck.py no longer holds the birth key must be refused as a stale exemption (mode: the gate checks that root)
#
# Usage: tests/test_superseded_pins.sh      # ci_portable, ~2 s
set -eu
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
. "$REPO/tests/lib/controls.sh"; vs_ctl_mode "$0"
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT

scratch() {  # scratch <control> — a root with this tree's registry, rulecheck.py, and ONE planted defect
    r="$W/$1"; mkdir -p "$r/tests/expected" "$r/tools"
    cp tests/expected/registry.tsv "$r/tests/expected/"
    cp tools/rulecheck.py tools/battery_reach.py "$r/tools/"
    case "$1" in
    planted-pin)
        k="$(python3 -c "import sys; sys.path.insert(0,'tools'); import superseded_pins as s; print(sorted(s.registry('.'))[0])")"
        printf 'EXPECT="%s"\n' "$(printf '%s' "$k" | cut -c1-8)" > "$r/tests/test_planted.sh" ;;
    stale-exemption)
        sed -i.bak '/^BIRTH_REGISTRY_KEY = /d' "$r/tools/rulecheck.py" ;;
    esac
    echo "$r"
}

echo "== test_superseded_pins: #167 — no live pin on a superseded fingerprint =="
fail=0
python3 tools/superseded_pins.py --selftest > "$W/self.txt" 2>&1 || true
grep -q '^SELFTEST PASS$' "$W/self.txt" && echo "  ok: the tool's selftest (seven cases)" \
    || { sed 's/^/  /' "$W/self.txt"; echo "FAIL: the tool's selftest"; fail=1; }

ROOT="."
case "${VS_CTL:-}" in planted-pin|stale-exemption) ROOT="$(scratch "$VS_CTL")" ;; esac
if python3 tools/superseded_pins.py --root "$ROOT" > "$W/tree.txt" 2>&1; then
    echo "  ok: $(tail -1 "$W/tree.txt")"
else
    sed 's/^/  /' "$W/tree.txt"; echo "FAIL: a live pin on a superseded fingerprint, or a stale exemption, in $ROOT"; fail=1
fi

if [ -z "${VS_CTL:-}" ]; then
    for c in planted-pin stale-exemption; do
        if python3 tools/superseded_pins.py --root "$(scratch "$c")" > "$W/ctl_$c.txt" 2>&1; then
            vs_ctl_dead "$c" "the planted scratch root passed" || fail=1
        else
            vs_ctl_fired "$c" "$(grep -m1 -E 'PIN|STALE' "$W/ctl_$c.txt" | sed 's/^ *//')"
        fi
    done
fi

if [ "$fail" = 0 ]; then echo "PASS: no live line pins a superseded fingerprint, and the named exemption is still in use"
else echo "FAIL: test_superseded_pins"; exit 1; fi
