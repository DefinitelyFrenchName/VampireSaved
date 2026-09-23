#!/bin/sh
# test_rule_checker.sh — the adversarial RULE-CHECKER's record is sound: every run in tests/rulecheck/ledger.tsv is complete and structured, every planted violation was caught, every fixture is calibrated, every VIOLATED resolved, and every freeze since the checker's birth was checked (GitHub #152, 14z-163). ROM-free, ~2 s.
#
# MUST-FIRE: perturbed-copy: quiet-control — a copy of the record in which one run's plant reads DEAD while its verdict still reads OK must fail: a dead plant VOIDS the verdict, and a checker that stopped catching its plants is a dead control
# MUST-FIRE: perturbed-copy: unchecked-freeze — a copy of the registry with one more row after the birth row, named by no `freeze` run, must fail: a freeze is bound to the checker mechanically
# MUST-FIRE: perturbed-copy: prose-verdict — a copy of the record in which one run's real verdict is prose instead of the six structured lines must fail: a prose verdict is unfalsifiable and the recorder refuses it
# MUST-FIRE: perturbed-copy: cross-family-plant — a copy of the record in which a PROCEDURE calibration names an EVIDENCE fixture as its plant must fail: a plant answers its own family's questions, so one from the other checklist proves nothing about the reader (#172 S3, 14z-176)
#
# WHY. The rule-checker (docs/project/rule_checker.md, [VSP-183]/[VSP-184]) is a
# fresh agent that answers five fixed questions from the artifacts behind a
# proposed action. Its own must-fire is the PLANT: every real run is paired
# with a known violation run blind, and a plant that is not caught voids the
# verdict. This gate is what makes the record auditable without re-running an
# agent: tools/rulecheck.py check reads the ledger, the run dirs, the fixtures
# and the registry, and refuses every shape in which the checker could look
# alive while asserting nothing.
#
# Section 1 is the tool's parser selftest (the recorder's refusal of prose is
# what "structured output, never prose" rests on). Section 2 is the check on
# the real tree. Section 3 fires the four controls on a copy (the fourth, cross-family-plant, since 14z-176).
#
# Usage: tests/test_rule_checker.sh
set -eu
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
fail=0
. "$REPO/tests/lib/controls.sh"; vs_ctl_mode "$0"
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT INT TERM

# a copy of everything `rulecheck check` reads, under a throwaway root
mkcopy() {  # mkcopy <root>
    mkdir -p "$1/docs/project" "$1/tests/expected" "$1/tools"
    _doc=docs/project/rule_checker.md; cp "$_doc" "$1"/docs/project/
    cp tests/expected/registry.tsv "$1/tests/expected/"
    cp -R tests/rulecheck "$1/tests/rulecheck"
}

# THE PERTURBATIONS — one function each, called by the control section and
# by the mode alike, so what the mode proves is what the control claims.
perturb() {  # perturb <name> <root>
    case "$1" in
    quiet-control)
        # the first CAUGHT row's plant is declared DEAD while its verdict stays
        python3 - "$2/tests/rulecheck/ledger.tsv" <<'PY'
import sys
p = sys.argv[1]; out = []; done = False
for ln in open(p):
    if not done and not ln.startswith("#") and "\tCAUGHT\t" in ln:
        ln = ln.replace("\tCAUGHT\t", "\tDEAD\t", 1); done = True
    out.append(ln)
assert done, "no CAUGHT row to perturb"
open(p, "w").write("".join(out))
PY
        ;;
    unchecked-freeze)
        printf '%s\t%s\t%s\n' "0000000000000000000000000000000000000000" "merged-m99" "a row planted by the unchecked-freeze control" >> "$2/tests/expected/registry.tsv"
        ;;
    prose-verdict)
        _run="$(ls -d "$2"/tests/rulecheck/runs/*/ | head -1)"
        [ -n "$_run" ] || { echo "no run dir to perturb"; return 1; }
        printf 'Overall this looks fine to me; the legs agree and the control exists.\n' > "$_run/verdict_real.txt"
        ;;
    cross-family-plant)
        # the first procedure-family run (a meta.tsv reading `family procedure`) names an evidence plant
        _run="$(grep -l '^family	procedure$' "$2"/tests/rulecheck/runs/*/meta.tsv | head -1 | xargs dirname)"
        [ -n "$_run" ] || { echo "no procedure run to perturb"; return 1; }
        printf 'fixture\tforced-pick-14z159\nslot\tb\n' > "$_run/control.txt"
        ;;
    *) echo "unknown perturbation $1"; return 1 ;;
    esac
}

# the finding each perturbation must produce — a copy that fails for any OTHER
# reason has not proven this control ([VSP-114])
expect_msg() {  # expect_msg <name>
    case "$1" in
    quiet-control)    echo "a DEAD plant must VOID the verdict" ;;
    unchecked-freeze) echo "was frozen with no OK \`freeze\` rulecheck row" ;;
    prose-verdict)    echo "not a structured verdict" ;;
    cross-family-plant) echo "is from the evidence family, but the run was read under the procedure checklist" ;;
    esac
}

if [ -n "${VS_CTL:-}" ]; then
    # THE EXECUTABLE FORM: the real record, copied, perturbed, checked — must FAIL
    # on the control's own finding
    mkcopy "$W/mode"; perturb "$VS_CTL" "$W/mode"
    if python3 tools/rulecheck.py check --root "$W/mode" > "$W/mode.log" 2>&1; then
        cat "$W/mode.log"; echo "FAIL: CONTROL=$VS_CTL left the check green"; exit 1
    fi
    cat "$W/mode.log"
    if ! grep -qF -- "$(expect_msg "$VS_CTL")" "$W/mode.log"; then
        echo "FAIL: CONTROL=$VS_CTL failed the check, but not on its own finding ($(expect_msg "$VS_CTL"))"; exit 1
    fi
    echo "FAIL: rule-checker record (control mode $VS_CTL reached the gate's own FAIL on its own finding)"; exit 1
fi

echo "== 1. the recorder's parser: structured verdicts accepted, prose refused =="
python3 tools/rulecheck.py --selftest || fail=1

echo "== 2. the record on the real tree =="
python3 tools/rulecheck.py check || fail=1

echo "== 3. MUST-FIRE CONTROLS on a copy =="
for c in quiet-control unchecked-freeze prose-verdict cross-family-plant; do
    rm -rf "$W/c"; mkcopy "$W/c"; perturb "$c" "$W/c"
    if python3 tools/rulecheck.py check --root "$W/c" > "$W/c.log" 2>&1; then
        vs_ctl_dead "$c" "the perturbed copy passed the check"; fail=1
    elif ! grep -qF -- "$(expect_msg "$c")" "$W/c.log"; then
        vs_ctl_dead "$c" "the copy failed, but not on this control's finding: $(grep -m1 '^  FAIL:' "$W/c.log" | cut -c9-120)"; fail=1
    else
        vs_ctl_fired "$c" "$(grep -m1 -F -- "$(expect_msg "$c")" "$W/c.log" | cut -c9-140)"
    fi
done

if [ "$fail" -eq 0 ]; then
    echo "PASS: the rule-checker's record is sound and its four controls fire"
else
    echo "FAIL: rule-checker record"
    exit 1
fi
