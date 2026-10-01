#!/bin/sh
# test_promise_check.sh — every promise a sitting's record makes is classed FULFILLED, CARRIED or NOT A
# PROMISE, and each class holds (`tools/promise_check.py`, 14z-187b, GitHub #190 P3).
#
# WHAT: tools/promise_check.py's verdicts mean what they say: the promise list is read from the
#   sitting's STATE group (bounded by the next group, a `---` or a level-1 heading) and its ledger
#   resolutions; a FULFILLED row's text must be in a tracked file and absent at the sitting's base
#   commit; a CARRIED row names an open or parked ticket or a START HERE item; a NOT-A-PROMISE row
#   gives its reason; an unclassed, ambiguous or stale row fails.
# HOW: drives the checker's selftest — a synthetic git repository with one case per failure
#   condition and a passing case that requires exactly four listed promises; three controls run
#   shadow copies with one perturbation each, and each must fail the selftest.
# EXPECTS: SELFTEST PASS (ten cases); each control's copy SELFTEST FAIL.
#
# WHY. The close checklist's step 4 had only a LIST (tools/close_findings.py's PROMISES) and
# case-specific scratch checks (14z-185, 14z-186). Writing the mechanism found two defects in the
# list itself: promise windows crossed table cells, so no match could name one promise; and the
# oldest STATE group's window ran past it into the standing sections (it ends at `# STANDING
# SECTIONS`, with no `---` since 14z-175), listing the maintainer's quoted "I'll install it" as the
# sitting's promises — close_findings.py had the same boundary and is fixed with it.
#
# MUST-FIRE: shadow-tool: no-boundary — a copy whose group window ignores a level-1 heading must list the standing sections' quote as a fifth promise, and the selftest must FAIL (mode: that copy's selftest)
# MUST-FIRE: shadow-tool: no-timing — a copy without the PREDATES leg must accept text that was there before the promise, and the selftest must FAIL (mode: that copy's selftest)
# MUST-FIRE: shadow-tool: start-here-ignored — a copy that finds a carried item anywhere in NEXT_SESSION must accept one outside START HERE, and the selftest must FAIL (mode: that copy's selftest)
#
# Usage: tests/test_promise_check.sh      # ci_portable, ~3 s
set -eu
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
. "$REPO/tests/lib/controls.sh"; vs_ctl_mode "$0"
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT

make_copy() {  # make_copy <control> — a copy of the checker (and the module it imports) with ONE perturbation
    mkdir -p "$W/$1"; cp tools/promise_check.py tools/close_findings.py "$W/$1/"
    python3 - "$W/$1/promise_check.py" "$1" <<'PY'
import sys; p, name = sys.argv[1:3]; s = open(p).read()
edits = {
    "no-boundary": ("(?=^## Session |^---$|^# |\\Z)", "(?=^## Session |^---$|\\Z)"),
    "no-timing": ("            if ws(text) in ws(then):\n", "            if False:  # CONTROL no-timing\n"),
    "start-here-ignored": ("ws(text) not in start_here(root)",
                           "ws(text) not in ws((Path(root) / path).read_text(errors='replace'))"),
}
a, b = edits[name]
assert s.count(a) == 1, name
open(p, "w").write(s.replace(a, b, 1))
PY
    echo "$W/$1/promise_check.py"
}

echo "== test_promise_check: #190 P3 — every listed promise classed, every class holding =="
fail=0
PC=tools/promise_check.py
if vs_ctl_is no-boundary || vs_ctl_is no-timing || vs_ctl_is start-here-ignored; then PC="$(make_copy "$VS_CTL")"; fi
python3 "$PC" --selftest > "$W/self.txt" 2>&1 || true
sed 's/^/  /' "$W/self.txt"
grep -q '^SELFTEST PASS$' "$W/self.txt" || { echo "FAIL: the checker's selftest"; fail=1; }

if [ -z "${VS_CTL:-}" ]; then
    for c in no-boundary no-timing start-here-ignored; do
        python3 "$(make_copy "$c")" --selftest > "$W/ctl_$c.txt" 2>&1 || true
        case "$c" in
        no-boundary)        want='^  FAIL  all classes hold: PASS$' ;;
        no-timing)          want='^  FAIL  PREDATES: PREDATES$' ;;
        start-here-ignored) want='^  FAIL  NOT CARRIED: NOT CARRIED$' ;;
        esac
        if grep -q '^SELFTEST FAIL$' "$W/ctl_$c.txt" && grep -q "$want" "$W/ctl_$c.txt"; then
            vs_ctl_fired "$c" "$(grep -m1 "$want" "$W/ctl_$c.txt" | sed 's/^ *//')"
        else vs_ctl_dead "$c" "the copy's selftest did not fail on its own case: $(grep -c 'FAIL  ' "$W/ctl_$c.txt") case(s) failed" || fail=1; fi
    done
fi

if [ "$fail" = 0 ]; then echo "PASS: every listed promise is classed and each class holds (the selftest's ten cases)"
else echo "FAIL: test_promise_check"; exit 1; fi
