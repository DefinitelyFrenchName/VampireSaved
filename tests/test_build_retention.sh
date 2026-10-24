#!/bin/sh
# test_build_retention.sh — what under build/ is kept, archived or pruned is decided by one tool whose rules are
# proven on a planted tree, and nothing it plans to delete is something a gate, a ticket or the session needs
# (`tools/build_retention.py`; #307, 14z-208).
#
# WHAT: tools/build_retention.py's plan keeps every build/ unit a rule names — an input-classed directory FIRST (the
#   emulator run records `emu_*` among them, never overridden), a directory a tracked program names outside a comment, one an open or
#   parked ticket's row or GitHub text names, one in START HERE, one in STATE.md, the newest close folders, an
#   unrecorded rule-checker staging folder — archives closed work's evidence, and prunes only regenerable or unread
#   bulk (old snapshot listings, recorded staging, sheet pages older than the newest freeze);
#   its apply deletes an archived unit only when the destination's sha256 of its tar was recorded as verified.
# HOW: drives the tool's selftest (a throwaway git repository with one planted unit per rule, plus an apply over a
#   manifest with one verified and one unverified tar), then plans THIS tree without sizes and checks that every
#   input-classed directory is kept; five controls run perturbed copies and each must fail the selftest.
# EXPECTS: the selftest passes, no input-classed directory of this tree is planned for archiving or pruning, and
#   every control fails. A red names the planted unit the tool decided wrongly, or this tree's directory.
#
# WHY. build/ had no retention rule and reached 71.4 GB (fork V's census, build/agent208/V/, 2026-10-24). The maintainer
# ruled closed work's evidence: "Archive, then move to files-hades (10.20.0.39)" (DECISIONS_HISTORY.md, 2026-10-24).
# [VSP-96]'s trap is the first control: counting a comment line as a read makes every directory look load-bearing.
#
# MUST-FIRE: perturbed-copy: comment-counted — a copy that counts comment lines as reads must keep the directory named only in a comment, and the selftest must FAIL (mode: that copy's selftest)
# MUST-FIRE: perturbed-copy: input-not-first — a copy that skips the input class must archive an input-classed emulator run record nothing names (the 14z-208 defect: an emulator-record rule ahead of the input class archived 33 and pruned 50 of them), and the selftest must FAIL (mode: that copy's selftest)
# MUST-FIRE: perturbed-copy: open-ticket-blind — a copy that ignores open tickets must archive the directory an open ticket names, and the selftest must FAIL (mode: that copy's selftest)
# MUST-FIRE: perturbed-copy: unrecorded-staging — a copy that treats every rule-checker staging folder as recorded must prune an unrecorded one, and the selftest must FAIL (mode: that copy's selftest)
# MUST-FIRE: perturbed-copy: apply-unverified — a copy whose apply skips the destination check must delete an archive with no verified tar, and the selftest must FAIL (mode: that copy's selftest)
#
# Usage: tests/test_build_retention.sh      # ci_portable, ~5 s
set -eu
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
. "$REPO/tests/lib/controls.sh"; vs_ctl_mode "$0"
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT
CTLS="comment-counted input-not-first open-ticket-blind unrecorded-staging apply-unverified"

make_copy() {  # make_copy <control> — the tools and the build-dir list, with ONE perturbation of the retention tool
    mkdir -p "$W/$1/tools" "$W/$1/tests/expected"
    cp tools/*.py "$W/$1/tools/"
    cp tests/expected/build_dirs.tsv "$W/$1/tests/expected/"
    python3 - "$W/$1/tools/build_retention.py" "$1" <<'PY'
import sys; p, name = sys.argv[1:3]; s = open(p).read()
a, b = {
    "comment-counted": ('        if car in ("code", "data") and is_comment(text, path):',
                        '        if False:  # CONTROL comment-counted'),
    "input-not-first": ('        if cls == "input":', '        if False:  # CONTROL input-not-first'),
    "open-ticket-blind": ("        elif top in trow or top in tgh:", "        elif False:  # CONTROL open-ticket-blind"),
    "unrecorded-staging": ("                if d in recorded:", "                if True:  # CONTROL unrecorded-staging"),
    "apply-unverified": ('            if m and ver.get(r[0]) == m["sha256"]:', "            if True:  # CONTROL apply-unverified"),
}[name]
assert s.count(a) == 1, name
open(p, "w").write(s.replace(a, b, 1))
PY
    echo "$W/$1/tools/build_retention.py"
}

echo "== test_build_retention: #307 — build/'s retention, decided by one tool =="
fail=0
BR=tools/build_retention.py
case " $CTLS " in *" ${VS_CTL:-none} "*) BR="$(make_copy "$VS_CTL")" ;; esac
python3 "$BR" --selftest > "$W/self.txt" 2>&1 || true
sed 's/^/  /' "$W/self.txt"
grep -q '^SELFTEST PASS$' "$W/self.txt" || { echo "FAIL: the tool's selftest"; fail=1; }

python3 tools/build_retention.py plan --root . --no-sizes --out "$W/plan.tsv" > "$W/plan.txt" 2>&1 || { echo "FAIL: the plan of this tree"; cat "$W/plan.txt"; fail=1; }
if [ -f "$W/plan.tsv" ]; then
    bad="$(awk -F'\t' 'NR > 1 && $3 == "input" && $4 != "KEEP" { print $1 }' "$W/plan.tsv")"
    echo "  this tree: $(awk 'NR > 1' "$W/plan.tsv" | wc -l | tr -d ' ') unit(s) planned"
    [ -z "$bad" ] || { echo "FAIL: input-classed director(ies) planned for archiving or pruning: $bad"; fail=1; }
fi

if [ -z "${VS_CTL:-}" ]; then
    for c in $CTLS; do
        python3 "$(make_copy "$c")" --selftest > "$W/ctl_$c.txt" 2>&1 || true
        if grep -q '^SELFTEST FAIL$' "$W/ctl_$c.txt"; then vs_ctl_fired "$c" "$(grep -m1 'FAIL ' "$W/ctl_$c.txt" | sed 's/^ *//')"
        else vs_ctl_dead "$c" "the perturbed copy passed its selftest — the selftest cannot see this failure" || fail=1; fi
    done
fi

if [ "$fail" = 0 ]; then echo "PASS: every retention rule decides its planted unit, apply deletes only verified archives, and no input directory of this tree is planned away"
else echo "FAIL: test_build_retention"; exit 1; fi
