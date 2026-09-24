#!/bin/sh
# test_gate_follows.sh — EVERY EMULATOR-TIER GATE DECLARES WHAT IT FOLLOWS, and no
# declaration is narrower than what the gate's own text reads (GitHub #171 slice Q3,
# ruled 2026-09-24 "Header line" — DECISIONS_HISTORY.md "Ruled 2026-09-24 (14z-180) —
# #171 gate qualification"). ci_portable: no ROM, no build dir, no emulator, ~2 s.
#
# WHAT: two properties of the `# FOLLOWS:` header field over every gate registered in
#   tests/ci_emulator.tsv: (1) the census — which gates DECLARE (grows only) and which are
#   UNDECLARED (shrinks only) — equals the frozen tests/expected/gate_follows.tsv; (2) the
#   RECONCILIATION, three classes — TEXT: every repo path a declaring gate's text
#   references (its script, the shared libraries it sources, the replay runners it calls,
#   its registry row's args) is covered by a declared prefix; RULE: every prefix the
#   widening rules require (the emulator's patches and setup script for the emulator the
#   gate reaches, the manifest for a gate that takes or builds a romset, the core sources
#   for the MiSTer lane, the rig generators) is declared; PROSE: every replay the gate's
#   own # WHAT: / # HOW: description names resolves to a covered file.
# HOW: tools/gate_follows.py (the ONE reader — the lane-carry tool and the staleness gate
#   import it) parses each leading comment block, extracts each script's references and
#   the rule-required prefixes, and reads the replay names out of the description prose
#   (an INDEPENDENT extractor: the prose was written by reading the gate, so a path the
#   text regex cannot see still has to be covered when the description names it); this
#   gate compares the census classes with the frozen file and runs --reconcile over the
#   tree; four controls run the checks on a copy of the tree with one gate perturbed.
# EXPECTS: PASS when the census equals the frozen file and --reconcile names no gate. A
#   red names the gate, the class and the item (lost its declaration / new declaration
#   not yet frozen / text:, rule: or prose: outside its declaration — widen the
#   declaration, never delete the reference).
#
# MUST-FIRE: perturbed-copy: dropped-declaration — a copy of the tree with one declaring gate's `# FOLLOWS:` field removed must class it undeclared and FAIL against the frozen file (mode: the census runs on that copy)
# MUST-FIRE: perturbed-copy: narrow-declaration — a copy where one declaring gate's declaration loses the prefix covering its first text reference must be named by --reconcile (class text) and FAIL (mode: the reconciliation runs on that copy)
# MUST-FIRE: perturbed-copy: rule-unwidened — a copy where a MAME-harness gate's declaration loses emu/mame-patches/ must be named by --reconcile (class rule) and FAIL: a widening rule that failed to fire is caught by the reader, not only by the script that wrote the declarations (mode: the reconciliation runs on that copy)
# MUST-FIRE: perturbed-copy: prose-uncovered — a copy where a gate's declaration loses every prefix covering a replay its own description names must be named by --reconcile (class prose) and FAIL, whatever the text regex saw (mode: the reconciliation runs on that copy)
#
# WHY A RECONCILIATION AND NOT JUST A CENSUS: a declaration that is present but too
# narrow would make the lane-carry verdict (tools/audit_lane_carry.py) and the staleness
# gate (tests/test_emulator_staleness.sh) confidently wrong — a moved replay the gate
# reads but did not declare would carry a green forward. The text is what the gate
# demonstrably reads; the declaration may be wider, never narrower.
#
# Usage: tests/test_gate_follows.sh      # FREEZE=1 rewrites the frozen census after review
set -u
REPO="$(cd "$(dirname "$0")/.." && pwd)"; cd "$REPO"
. "$REPO/tests/lib/controls.sh"; vs_ctl_mode "$0"
EXP=tests/expected/gate_follows.tsv
W="$(mktemp -d "${TMPDIR:-/tmp}/gfol.XXXXXX")"; trap 'rm -rf "$W"' EXIT INT TERM
fail=0; ok() { echo "  ok    $*"; }; bad() { echo "  FAIL  $*"; fail=1; }

census() { python3 tools/gate_follows.py --root "$1" 2>/dev/null | cut -f1,2 | sort; }
cls() { awk -F'\t' -v c="$1" '$1==c{print $2}' "$2" | sort; }

# perturb NAME ROOT — a copy of the tree's scripts under ROOT with one defect planted;
# prints the perturbed gate, or NONE
perturb() {
    mkdir -p "$2/tests/lib" "$2/tools"
    cp tests/*.sh "$2/tests/"; cp tests/lib/*.sh "$2/tests/lib/"; cp tools/*.sh "$2/tools/"
    cp tests/ci_emulator.tsv "$2/tests/"
    ln -s "$REPO/tests/replays" "$2/tests/replays"   # the prose class resolves replay names against the corpus
    case "$1" in
        dropped-declaration)
            g="$(census . | awk -F'\t' '$1=="declares"{print $2; exit}')"
            [ -n "$g" ] || { echo NONE; return 1; }
            sed -i.bak -e '/^# FOLLOWS:/,/^#\( [A-Z]\|$\)/{/^# FOLLOWS:/d; /^#  /d;}' "$2/tests/$g.sh" ;;
        narrow-declaration|rule-unwidened|prose-uncovered)
            g="$(python3 - "$2" "$1" <<'PY'
import sys, os
sys.path.insert(0, "tools"); import gate_follows as gf
root, mode = sys.argv[1], sys.argv[2]; rows = gf.registry_rows(".")
def drop_tokens(p, toks):
    text = open(os.path.join(root, p)).read(); new = text
    for d in toks:   # remove each token wherever the field wrapped it
        new = new.replace(f" {d}\n", "\n").replace(f" {d} ", " ")
    if new == text: return False
    open(os.path.join(root, p), "w").write(new); return True
for g in sorted(rows):
    p = f"tests/{g}.sh"
    if not os.path.exists(p): continue
    prefixes, refs, unc, problems = gf.reconcile(".", g, rows)
    if problems or unc: continue
    if mode == "narrow-declaration":
        if not refs: continue
        toks = [x for x in prefixes if gf.covered(refs[0], [x])][:1]
    elif mode == "rule-unwidened":
        if "emu/mame-patches/" not in gf.required(".", g, rows, refs): continue
        toks = ["emu/mame-patches/"]
    else:
        pr = gf.prose_refs(".", g)
        if not pr: continue
        paths = set().union(*pr.values())
        toks = sorted({x for x in prefixes if any(gf.covered(q, [x]) for q in paths)})
    if toks and drop_tokens(p, toks):
        print(g); break
else:
    print("NONE")
PY
)" ;;
    esac
    rm -f "$2/tests/"*.bak
    echo "$g"
}

root="."
if [ -n "$VS_CTL" ]; then
    g="$(perturb "$VS_CTL" "$W/mode" | tail -1)"; root="$W/mode"
    [ "$g" != NONE ] || { echo "FAIL: no declaring gate in the tree to perturb — the control cannot run"; exit 1; }
    echo "MODE: control $VS_CTL — the checks run on a copy where $g.sh is perturbed"
fi

echo "== 1. the census against $EXP"
if [ ! -f "$EXP" ]; then
    [ "${FREEZE:-0}" = 1 ] || { echo "FAIL: $EXP missing — run FREEZE=1 after review"; exit 1; }
    echo "  (no frozen file yet — FREEZE=1 writes the first census)"; : > "$W/empty.tsv"; EXP_READ="$W/empty.tsv"
else EXP_READ="$EXP"; fi
census "$root" > "$W/got.tsv"
nd="$(grep -c '^declares' "$W/got.tsv")"; nu="$(grep -c '^undeclared' "$W/got.tsv")"
echo "  census: $nd declares, $nu undeclared (over the registry's gates)"
cls declares "$EXP_READ" > "$W/exp_d.txt"; cls declares "$W/got.tsv" > "$W/got_d.txt"
lost="$(comm -23 "$W/exp_d.txt" "$W/got_d.txt")"
new="$(comm -13 "$W/exp_d.txt" "$W/got_d.txt")"
if [ -n "$lost" ]; then bad "a frozen declaring gate LOST its declaration: $(echo "$lost" | tr '\n' ' ')"; else ok "every frozen declaring gate still declares ($(wc -l < "$W/exp_d.txt" | tr -d ' ') frozen)"; fi
if [ -n "$new" ]; then
    if [ "${FREEZE:-0}" = 1 ]; then ok "new declaring gate(s) to freeze: $(echo "$new" | tr '\n' ' ')"
    else bad "new declaring gate(s) not yet frozen (review, then FREEZE=1): $(echo "$new" | tr '\n' ' ')"; fi
fi
cls undeclared "$EXP_READ" > "$W/exp_u.txt"; cls undeclared "$W/got.tsv" > "$W/got_u.txt"
grew="$(comm -13 "$W/exp_u.txt" "$W/got_u.txt")"
grew="$(printf '%s\n' "$grew" | grep -vxF -f "$W/exp_d.txt" || true)"   # a lost declarer is reported above, once
if [ -n "$grew" ]; then
    if [ "${FREEZE:-0}" = 1 ]; then ok "new undeclared gate(s) (new registry rows) to freeze: $(echo "$grew" | tr '\n' ' ')"
    else bad "undeclared grew by a gate the frozen file does not know (a new emulator gate: declare what it follows, or FREEZE=1 after review): $(echo "$grew" | tr '\n' ' ')"; fi
fi

echo "== 2. the reconciliation: no declaration narrower than its gate's text, its widening rules or its own description"
if python3 tools/gate_follows.py --root "$root" --reconcile > "$W/rec.txt" 2> "$W/rec.err"; then
    ok "$(cat "$W/rec.err")"
else
    bad "$(cat "$W/rec.err")"; sed 's/^/        /' "$W/rec.txt" | head -12
fi

if [ "${FREEZE:-0}" = 1 ] && [ -z "$VS_CTL" ]; then
    { echo "# tests/expected/gate_follows.tsv — which emulator-tier gates (tests/ci_emulator.tsv) DECLARE"
      echo "# the paths their verdict follows with a # FOLLOWS: header field (declares GROWS only) and"
      echo "# which do not yet (undeclared SHRINKS only). GitHub #171 slice Q3. Gate:"
      echo "# tests/test_gate_follows.sh; reader tools/gate_follows.py. Regenerate with FREEZE=1"
      echo "# after review. class<TAB>gate"
      cat "$W/got.tsv"; } > "$EXP"
    echo "  FROZE $EXP ($nd declares, $nu undeclared)"; fail=0
fi

if [ -z "$VS_CTL" ]; then
    echo "== 3. controls: each perturbation of a copy must be caught"
    g="$(perturb dropped-declaration "$W/c1" | tail -1)"
    if [ "$g" = NONE ]; then vs_ctl_dead dropped-declaration "no declaring gate to perturb"; fail=1
    elif census "$W/c1" | grep -qx "declares	$g"; then vs_ctl_dead dropped-declaration "$g still classed declares after its FOLLOWS line was removed"; fail=1
    else vs_ctl_fired dropped-declaration "$g classed undeclared on the perturbed copy"; fi
    for c in "narrow-declaration text" "rule-unwidened rule" "prose-uncovered prose"; do
        set -- $c; name="$1"; cls="$2"
        g="$(perturb "$name" "$W/$name" | tail -1)"
        if [ "$g" = NONE ]; then vs_ctl_dead "$name" "no declaring gate to perturb for this class"; fail=1
        elif python3 tools/gate_follows.py --root "$W/$name" --reconcile "$g" --check "$cls" 2>/dev/null | grep -q "^$g	UNCOVERED	$cls:"; then
            vs_ctl_fired "$name" "$g named UNCOVERED (class $cls) after its covering prefix was dropped"
        else vs_ctl_dead "$name" "$g still reconciled (class $cls) after its declaration was narrowed"; fail=1; fi
    done
fi

[ "$fail" -eq 0 ] && echo "PASS" || echo "FAIL"
exit "$fail"
