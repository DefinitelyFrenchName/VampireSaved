#!/bin/sh
# test_claim_lint.sh — every universal or definite in a rule-checker claim is tied to a named check or to the claim's
# NOT TESTED part (tools/claim_lint.py, 14z-187b, GitHub #185 item 3).
#
# WHAT: tools/claim_lint.py's verdicts mean what they say: a sentence holding every/only/none/all/the one is TIED by a
#   path, a backticked name or a control's verdict in the same sentence (outside parentheses), or by sitting in the
#   NOT TESTED part; a frequency ("every 20 frames") and a quotation are not read; anything else is UNTIED.
# HOW: the tool's --selftest (eighteen cases, one per rule); a REAL fixture — rule-checker run 2026-10-01-518's claim
#   (tests/rulecheck/runs/2026-10-01-518/meta.tsv) — the sentence whose "each ... an own-value poke inert" its reader
#   found VIOLATED must be reported UNTIED (by its undisputed "every byte write verified": `each` is not one of the five
#   words, so the lint flags the SENTENCE, not that universal itself); three shadow copies with one
#   perturbation each must fail the selftest; and THE WIRING: on a throwaway root carrying its own copy of the
#   rule-checker's files, `tools/rulecheck.py prepare` is run on a real packet whose claim holds an untied universal —
#   it must refuse and leave no run directory; the same packet with --untied-ok must be prepared and its meta.tsv must
#   record the reason.
# EXPECTS: SELFTEST PASS; run 518's first sentence UNTIED; each control's copy SELFTEST FAIL on its own case; prepare
#   REFUSED (no run directory) without --untied-ok, PREPARED with it (an untied_ok row); a copy of rulecheck.py with
#   the lint call removed PREPARES the untied packet, so the refusal is the lint's.
# FOLLOWS: tools/claim_lint.py tools/rulecheck.py tests/rulecheck/ tests/expected/registry.tsv docs/project/rule_checker.md
#   .claude/agents/rule-checker.md tests/lib/controls.sh
#
# MUST-FIRE: shadow-tool: gap-ignored — a copy that reads the NOT TESTED part as claims must flag a named gap, and the selftest must FAIL (mode: that copy's selftest)
# MUST-FIRE: shadow-tool: lint-unwired — a copy of tools/rulecheck.py whose prepare never calls the lint must PREPARE the untied packet, and the wiring section must FAIL (in-gate: that copy prepares it; mode: that copy is the one checked)
# MUST-FIRE: shadow-tool: possessive-quote — a copy that reads any two apostrophes as a quotation must drop "every" between two possessives, and the selftest must FAIL (mode: that copy's selftest)
# MUST-FIRE: shadow-tool: frequency-read — a copy that reads "every 20 frames" as a universal must flag it, and the selftest must FAIL (mode: that copy's selftest)
#
# WHY. #185's finding (2026-09-29): most of a close loop's rule-checker findings were universals and definites written
# from intent, the check built afterwards to match. The lint makes the writer name the measurement or the gap in the
# same sentence before a reader is spent on it; it does not judge truth.
#
# Usage: tests/test_claim_lint.sh      # ci_portable, ~1 s
set -eu
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
. "$REPO/tests/lib/controls.sh"; vs_ctl_mode "$0"
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT
TOOL=tools/claim_lint.py

shadow() {  # shadow <control> — a copy of the tool with ONE perturbation
    python3 - "$TOOL" "$W/$1.py" "$1" <<'PY'
import sys; src, out, name = sys.argv[1:4]; s = open(src).read()
edits = {
    "gap-ignored": ("        if not words or in_gap:\n", "        if not words:\n"),
    "frequency-read": ("bare = FREQ.sub(\" \", QUOTED.sub(\" \", c))", "bare = QUOTED.sub(\" \", c)"),
    "possessive-quote": ("(?<!\\w)'[^']*'(?!\\w)", "'[^']*'"),
}
a, b = edits[name]
assert s.count(a) == 1, name
open(out, "w").write(s.replace(a, b, 1))
PY
    echo "$W/$1.py"
}

echo "== test_claim_lint: #185 item 3 — universals tied to a check or a named gap =="
fail=0
T="$TOOL"
if vs_ctl_is gap-ignored || vs_ctl_is frequency-read || vs_ctl_is possessive-quote; then T="$(shadow "$VS_CTL")"; fi
RC=tools/rulecheck.py
python3 "$T" --selftest > "$W/self.txt" 2>&1 || true
sed 's/^/  /' "$W/self.txt"
grep -q '^SELFTEST PASS$' "$W/self.txt" || { echo "FAIL: the lint's selftest"; fail=1; }

claim="$(awk -F'\t' '$1=="claim"{print substr($0, index($0,$2))}' tests/rulecheck/runs/2026-10-01-518/meta.tsv)"
python3 "$T" --claim "$claim" > "$W/r518.txt" 2>&1 || true
if grep -q '^UNTIED \[every\]: Three expectation changes rest on measured data swaps, each both ways with every byte write verified and an own-value poke inert\.$' "$W/r518.txt"; then
    echo "  ok    the sentence holding run 2026-10-01-518's violated universal is reported UNTIED (by its \"every\"; the violated \"each\" is not read)"
else echo "  FAIL  run 2026-10-01-518's violated universal is not reported: $(head -2 "$W/r518.txt")"; fail=1; fi

# THE WIRING (after rule-checker run 2026-10-02-530 Q1/Q4): prepare itself, on a throwaway root
mkroot() {  # mkroot <root> <rulecheck.py to install>
    mkdir -p "$1/docs/project" "$1/tests/expected" "$1/tools" "$1/.claude/agents"
    _doc=docs/project/rule_checker.md; cp "$_doc" "$1"/docs/project/; cp tests/expected/registry.tsv "$1/tests/expected/"
    cp -R tests/rulecheck "$1/tests/rulecheck"; cp .claude/agents/rule-checker.md "$1/.claude/agents/"
    cp "$2" "$1/tools/rulecheck.py"; cp tools/claim_lint.py "$1/tools/"
    echo "an artifact" > "$1/art.txt"
}
unwired() {  # unwired <out> — a copy of rulecheck.py whose prepare never calls the lint
    python3 - tools/rulecheck.py "$1" <<'PY'
import sys; src, out = sys.argv[1:3]; s = open(src).read()
a = "        untied = claim_lint.lint(claim)\n"
assert s.count(a) == 1, "the lint call is gone from rulecheck.py"
open(out, "w").write(s.replace(a, "        untied = []   # CONTROL lint-unwired\n", 1))
PY
}
UNTIED_CLAIM="Every row matches and the gate is green."
wiring() {  # wiring <rulecheck.py> <root> -> prints REFUSED|PREPARED for the bare packet, then the --untied-ok outcome
    rm -rf "$2"; mkroot "$2" "$1"
    n0="$(ls "$2/tests/rulecheck/runs" | wc -l | tr -d ' ')"
    ( cd "$2" && python3 tools/rulecheck.py prepare --decision recommendation --subject probe --claim "$UNTIED_CLAIM" --artifact art.txt --id 2099-02-02-01 ) > "$2/bare.log" 2>&1 && bare=PREPARED || bare=REFUSED
    grep -q "claim_lint (#185 item 3)" "$2/bare.log" || [ "$bare" = PREPARED ] || bare="REFUSED-FOR-ANOTHER-REASON: $(tail -1 "$2/bare.log")"
    n1="$(ls "$2/tests/rulecheck/runs" | wc -l | tr -d ' ')"; [ -d "$2/build/rulecheck/2099-02-02-01" ] && left=yes || left=no
    ( cd "$2" && python3 tools/rulecheck.py prepare --decision recommendation --subject probe --claim "$UNTIED_CLAIM" --artifact art.txt --id 2099-02-02-02 --untied-ok "a probe" ) > "$2/ok.log" 2>&1 && ok_=PREPARED || ok_="REFUSED: $(tail -1 "$2/ok.log")"
    rec="$(grep -h '^untied_ok' "$2"/tests/rulecheck/runs/2099-02-02-02/meta.tsv "$2"/build/rulecheck/2099-02-02-02/meta.tsv 2>/dev/null | head -1)"
    echo "bare=$bare runs_before=$n0 runs_after=$n1 run_dir_left=$left untied_ok=$ok_ meta=[$rec]"
}
RCT="$RC"; vs_ctl_is lint-unwired && { unwired "$W/rc_unwired.py"; RCT="$W/rc_unwired.py"; }
case "$RCT" in /*) ;; *) RCT="$REPO/$RCT" ;; esac
got="$(wiring "$RCT" "$W/root")"
echo "  wiring: $got"
case "$got" in
    "bare=REFUSED runs_before="*"run_dir_left=no untied_ok=PREPARED meta=[untied_ok	a probe]")
        n0="${got#*runs_before=}"; n0="${n0%% *}"; n1="${got#*runs_after=}"; n1="${n1%% *}"
        [ "$n0" = "$n1" ] && echo "  ok    prepare REFUSES the untied packet (no run directory), PREPARES it with --untied-ok (meta.tsv records the reason)" \
            || { echo "  FAIL  the refused prepare changed the runs directory ($n0 -> $n1)"; fail=1; } ;;
    *) echo "  FAIL  the wiring is not as required: $got"; fail=1 ;;
esac

if [ -z "${VS_CTL:-}" ]; then
    unwired "$W/rc_unwired.py"
    ug="$(wiring "$W/rc_unwired.py" "$W/root_unwired")"
    case "$ug" in
        bare=PREPARED*) vs_ctl_fired lint-unwired "a rulecheck.py without the lint call prepares the untied packet ($ug)" ;;
        *) vs_ctl_dead lint-unwired "the unwired copy still refuses: $ug" || fail=1 ;;
    esac
    for c in gap-ignored frequency-read possessive-quote; do
        python3 "$(shadow "$c")" --selftest > "$W/ctl_$c.txt" 2>&1 || true
        case "$c" in
        gap-ignored)    want='FAIL  in the NOT TESTED part' ;;
        frequency-read) want='FAIL  a frequency is not a universal' ;;
        possessive-quote) want='FAIL  two possessives are not a quotation' ;;
        esac
        if grep -q '^SELFTEST FAIL$' "$W/ctl_$c.txt" && grep -q "$want" "$W/ctl_$c.txt"; then
            vs_ctl_fired "$c" "$(grep -m1 "$want" "$W/ctl_$c.txt" | sed 's/^ *//')"
        else vs_ctl_dead "$c" "the copy's selftest did not fail on its own case" || fail=1; fi
    done
fi

if [ "$fail" = 0 ]; then echo "PASS: test_claim_lint"; else echo "FAIL: test_claim_lint"; exit 1; fi
