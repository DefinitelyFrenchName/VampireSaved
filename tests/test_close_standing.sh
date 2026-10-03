#!/bin/sh
# test_close_standing.sh — the standing close-check set renders with every list derived and every plant generated,
# its claim comes from the run of record, and a finding is appended in the table's form (GitHub #204, #206, #207;
# 14z-189).
#
# WHAT: tools/close_standing.py renders tests/close_standing_checks.tsv for a close from three parameters (key, row,
#   run dir), derives the open-ticket list and the base commit, generates each plant from the live file so it must
#   fail its check, finds a repeated DECISIONS_HISTORY/STATE_HISTORY entry, holds the findings-row copy to the live
#   row, and writes the packet claim only from a FULL all-OK run; tools/findings_add.py appends a finding in the
#   form tools/none_reasons.py and tools/homes_tracked.py read, and refuses an untracked home or a bare `none`.
# HOW: both tools' self-tests on synthetic trees with known answers; then the REAL template rendered into a temp run
#   dir (no close is needed to render) and linted: every row parses for tools/close_checks.py, every `*_plant` row
#   expects a non-zero exit and its base check is in the set, every standing check declares WHAT and NOT SEEN.
#   Six controls are known-bad variants (each tool's --perturb, and a template copy whose plant expects 0).
# EXPECTS: both self-tests PASS, the template lint clean, and every control's variant FAILs.
#
# WHY. Three closes took 12, 8 and 7 documentation-packet runs, four of 14z-188's six VIOLATED on holes in checks
# written during that close (#204); the findings table was rebuilt at the close from summaries (#206); the claim was
# rewritten by hand for each run (#207). The maintainer: "Yes please: open one or multiple tickets on these avenues to
# make the close converge faster" (14z-188).
#
# MUST-FIRE: known-bad: plant-is-live — a close_standing.py whose plants equal their live files must fail its self-test (mode: that variant's self-test)
# MUST-FIRE: known-bad: dup-blind — a duplicate check that never counts a repeat must fail the self-test (mode: that variant's self-test)
# MUST-FIRE: known-bad: stale-row-accepted — a row-copy check that accepts any copy must fail the self-test (mode: that variant's self-test)
# MUST-FIRE: known-bad: claim-partial-accepted — a claim written from a partial run must fail the self-test (mode: that variant's self-test)
# MUST-FIRE: known-bad: form-unchecked — a findings_add.py accepting an untracked home and an empty none reason must fail its self-test (mode: that variant's self-test)
# MUST-FIRE: perturbed-copy: unpaired-plant — a copy of the template whose plant row expects exit 0 must fail the lint (mode: the lint on that copy)
#
# Usage: tests/test_close_standing.sh      # ci_portable, ~3 s
set -eu
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
. "$REPO/tests/lib/controls.sh"; vs_ctl_mode "$0"
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT

lint() {  # lint <template> — render it and check its shape; prints FAIL lines, exit 1 on any
    python3 tools/close_standing.py render --key 14z-99999 --row "(1) THE FINDINGS TABLE" --run "$W/run_$$" \
        --transcript /dev/null --template "$1" > "$W/render.txt" 2>&1 || { sed 's/^/  /' "$W/render.txt"; echo "FAIL: render"; return 1; }
    python3 - "$1" "$W/run_$$/checks.tsv" <<'PY'
import sys
sys.path.insert(0, "tools")
import close_checks
rows = [l.rstrip("\n").split("\t") for l in open(sys.argv[1]) if l.strip() and not l.startswith("#")]
names = {r[0] for r in rows}
bad = 0
close_checks.read_checks(sys.argv[2])
for r in rows:
    if r[0].endswith("_plant"):
        if r[1] == "0":
            print(f"FAIL: plant {r[0]} expects exit 0 — a plant must fail its check"); bad += 1
        if r[0][:-6] not in names:
            print(f"FAIL: plant {r[0]} has no base check {r[0][:-6]}"); bad += 1
    elif r[2] in ("", "-") or r[3] == "":
        print(f"FAIL: {r[0]} declares no WHAT or no NOT SEEN"); bad += 1
print(f"template rows {len(rows)}  plants {sum(r[0].endswith('_plant') for r in rows)}  lint failures {bad}")
sys.exit(1 if bad else 0)
PY
}

echo "== test_close_standing: #204/#206/#207 — the standing close-check set =="
fail=0
P=""
case "${VS_CTL:-}" in plant-is-live|dup-blind|stale-row-accepted|claim-partial-accepted) P="--perturb $VS_CTL";; esac
python3 tools/close_standing.py --selftest $P > "$W/s1.txt" 2>&1 || true
sed 's/^/  /' "$W/s1.txt"
grep -q '^SELFTEST PASS$' "$W/s1.txt" || { echo "FAIL: close_standing.py's self-test"; fail=1; }

P=""; vs_ctl_is form-unchecked && P="--perturb form-unchecked"
python3 tools/findings_add.py --selftest $P > "$W/s2.txt" 2>&1 || true
sed 's/^/  /' "$W/s2.txt"
grep -q '^SELFTEST PASS$' "$W/s2.txt" || { echo "FAIL: findings_add.py's self-test"; fail=1; }

T=tests/close_standing_checks.tsv
if vs_ctl_is unpaired-plant; then
    awk -F'\t' 'BEGIN{OFS="\t"} !done && $1 ~ /_plant$/ {$2="0"; done=1} {print}' "$T" > "$W/tmpl_ctl.tsv"; T="$W/tmpl_ctl.tsv"
fi
if lint "$T" > "$W/lint.txt" 2>&1; then sed 's/^/  /' "$W/lint.txt"
else sed 's/^/  /' "$W/lint.txt"; echo "FAIL: the template lint"; fail=1; fi

if [ -z "${VS_CTL:-}" ]; then
    for c in plant-is-live dup-blind stale-row-accepted claim-partial-accepted; do
        python3 tools/close_standing.py --selftest --perturb "$c" > "$W/c_$c.txt" 2>&1 || true
        if grep -q '^SELFTEST FAIL$' "$W/c_$c.txt"; then vs_ctl_fired "$c" "$(grep -m1 'FAIL:' "$W/c_$c.txt" | sed 's/^ *//')"
        else vs_ctl_dead "$c" "the known-bad variant passed the self-test" || fail=1; fi
    done
    python3 tools/findings_add.py --selftest --perturb form-unchecked > "$W/c_fu.txt" 2>&1 || true
    if grep -q '^SELFTEST FAIL$' "$W/c_fu.txt"; then vs_ctl_fired form-unchecked "$(grep -m1 'FAIL:' "$W/c_fu.txt" | sed 's/^ *//')"
    else vs_ctl_dead form-unchecked "the known-bad variant passed the self-test" || fail=1; fi
    awk -F'\t' 'BEGIN{OFS="\t"} !done && $1 ~ /_plant$/ {$2="0"; done=1} {print}' tests/close_standing_checks.tsv > "$W/tmpl_ctl.tsv"
    if lint "$W/tmpl_ctl.tsv" > "$W/c_up.txt" 2>&1; then vs_ctl_dead unpaired-plant "the lint accepted a plant expecting exit 0" || fail=1
    else vs_ctl_fired unpaired-plant "$(grep -m1 'FAIL:' "$W/c_up.txt")"; fi
fi

if [ "$fail" = 0 ]; then echo "PASS: the standing close-check set renders, derives its lists, generates its plants, and its claim and findings appends hold their form"
else echo "FAIL: test_close_standing"; exit 1; fi
