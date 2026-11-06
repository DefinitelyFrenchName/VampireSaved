#!/bin/sh
# test_plants_not_applied.sh — A CONTROL MODE WHOSE PLANT DID NOT APPLY, OR WHOSE COPY IS RED ON ANOTHER FINDING, NEVER READS HONOURED (#310 group 6, 14z-215). ci_portable: no ROM, no emulator, ~45 s.
#
# WHAT: the three gates #310's group 6 named — tests/audit_latch_reads.sh (tap-window-moved), tests/test_gate_follows.sh
#   (five modes on a partial copy of the tree) and tests/test_poke_readback.sh (four) — run, as the runners run them, on
#   scratch trees where the mode's plant cannot apply or its copy is red on something that is not its own finding, each
#   run classified by tests/lib/classify.sh vs_classify_control: audit_latch_reads with the tap's target line moved reads
#   UNJUDGED (its REFUSED, exit 3), its perturbed tap copy dying of a shell error UNJUDGED (NOT JUDGED), the copy raising
#   a Python exception DIED (the copy's traceback at column 0, #310 group 5); test_gate_follows with no gate to perturb
#   UNJUDGED (REFUSED), with a second declaring gate's FOLLOWS gone on the copy UNJUDGED (NOT JUDGED); test_poke_readback
#   with the known case's field moved UNJUDGED (REFUSED), with a foreign synthetic finding on the copy UNJUDGED (NOT
#   JUDGED). And the two tests/test_rule_checker.sh shadow modes the 14z-215 re-read found reading ANY failure of their
#   shadow as fired (#310 group 5: counted-id's prepare ids, unfiltered-plants' rotation): the shadow's prepare raising
#   reads DIED (its traceback at column 0). Before 14z-215 every one of the nine read HONOURED.
# HOW: each scratch tree is symbolic links to this tree with the planted files real copies (test_rule_checker's
#   tests/rulecheck a real copy too: its probes write there); audit_latch_reads runs with a stub MAME (exit 0), empty
#   zips and LEGS=phobos-real, so it refuses or fails before any emulator could start; the rule-checker plant is an
#   assert placed after the line each shadow rewrites, false only once that line is rewritten.
# EXPECTS: each plant its class above; the four controls fire.
# FOLLOWS: tests/audit_latch_reads.sh tests/test_gate_follows.sh tests/test_poke_readback.sh tests/lib/classify.sh
#   tests/lib/controls.sh tests/lib/jobs.sh tools/tap_latch_reads.sh tools/gate_follows.py tools/audit_poke_readback.py
#   tools/name_moves.py tests/ci_emulator.tsv tests/test_killshread_es.sh tests/expected/gate_follows.tsv
#   tests/expected/poke_readback.tsv tests/replays/naming/huitzil_1.json tests/test_rule_checker.sh tools/rulecheck.py
#   tests/rulecheck/ tests/expected/registry.tsv docs/project/rule_checker.md
#
# MUST-FIRE: known-bad: latch-fix-reverted — a copy of tests/audit_latch_reads.sh with its 14z-215 lines reverted (the not-applied plant a plain FAIL exit 1, a failed leg's copy output cut to its last line) must read HONOURED on all three of its plants, so their UNJUDGED and DIED rest on those lines (mode: the plants run on that copy and the gate FAILs)
# MUST-FIRE: known-bad: follows-fix-reverted — a copy of tests/test_gate_follows.sh with its 14z-215 lines reverted (no gate to perturb a plain FAIL exit 1, no check that the copy's red is the mode's own row) must read HONOURED on both its plants (mode: as above)
# MUST-FIRE: known-bad: pokerb-fix-reverted — a copy of tests/test_poke_readback.sh with its 14z-215 lines reverted (a plant that could not be planted a plain FAIL exit 1, no check that the copy's red is the mode's own row) must read HONOURED on both its plants (mode: as above)
# MUST-FIRE: known-bad: rulecheck-fix-reverted — a copy of tests/test_rule_checker.sh without its 14z-215 traceback lines must read HONOURED on both its plants (mode: as above)
#
# WHY: #310's re-census of 2026-10-31 (build/agent215/t310/census57/SUMMARY.md, local), group 6: a mode whose plant did
#   not apply printed a plain FAIL and exited 1, and a mode run on a partial copy read ANY red there as its finding — a
#   control that tested nothing certified as caught. The maintainer ruled the fix and its proof (2026-10-31): "Each is
#   proven by a planted case that must read DIED or UNJUDGED". The mode logs of 14z-215 showed no foreign row on today's
#   copies; these plants make one.
set -u
REPO="$(cd "$(dirname "$0")/.." && pwd)"; cd "$REPO"
. "$REPO/tests/lib/controls.sh"; vs_ctl_mode "$0"
W="$(mktemp -d)" || { echo "FAIL: test_plants_not_applied — mktemp -d failed (W)"; exit 2; }; trap 'rm -rf "$W"' EXIT; trap 'exit 130' INT; trap 'exit 143' TERM
fail=0; ok() { echo "  ok    $*"; }; bad() { echo "  FAIL  $*"; fail=1; }

# run_cl <label> <gate copy> <mode> [VAR=value...] — runs the copy under CONTROL=<mode> as a runner would and sets CL
# to vs_classify_control's class (with the copy's own path and the mode's name, as the runners pass them)
run_cl() {
    _lab="$1"; _g="$2"; _c="$3"; shift 3
    env "$@" CONTROL="$_c" sh "$_g" > "$W/$_lab.log" 2>&1 </dev/null && _s=0 || _s=$?
    CL="$(sh -c '. "$1"; vs_classify_control "$2" "$3" "$4" "$5"; echo "$VS_CTL_EXEC"' _ "$REPO/tests/lib/classify.sh" "$_s" "$W/$_lab.log" "$_g" "$_c")"
}
# mirror <dir> — a tree of links to this one whose tests/ is a real directory of links, so a plant replaces one file
mirror() {
    mkdir -p "$1/tests"
    for _e in "$REPO"/*; do [ "$(basename "$_e")" = tests ] || ln -s "$_e" "$1/"; done
    for _e in "$REPO"/tests/*; do ln -s "$_e" "$1/tests/"; done
}
# revert <kind> <gate> <out> — the gate with its 14z-215 group-6 lines reverted to the pre-fix form; exit 1 if any
# replacement did not apply exactly once (the controls below)
revert() {
    python3 - "$1" "$2" "$3" <<'PY'
import re, sys
kind, src, dst = sys.argv[1:4]
s = open(src).read()
def sub(pat, new, flags=re.M | re.S):
    global s
    t, n = re.subn(pat, new, s, count=1, flags=flags)
    if n != 1:
        sys.exit(f"revert {kind}: {pat[:60]!r} matched {n} times")
    s = t
if kind == "latch":
    sub(r'^        grep -q \'printf %x\' .*?exit 3; \}\n',
        '        grep -q \'printf %x\' "$W/tap_moved.sh" || { echo "FAIL: the tap-window-moved perturbation did not apply"; exit 1; }\n')
    sub(r'^        if \[ "\$CONTROL" = tap-window-moved \]; then\n.*?^        fi\n', '')
elif kind == "rulecheck":
    for _ in range(2):
        sub(r"^    for _l in .*?Traceback.*?; done\n", '')
else:
    old = {"follows": 'FAIL: no declaring gate in the tree to perturb — the control cannot run',
           "pokerb": 'FAIL: the perturbation could not be planted'}[kind]
    sub(r'^    \[ "\$g" != NONE \] \|\| \{ echo "REFUSED: .*?exit 3; \}$', '    [ "$g" != NONE ] || { echo "' + old + '"; exit 1; }')
    sub(r"^# THE MODE'S VERDICT \(#310 group 6.*?^fi\n", '')
open(dst, "w").write(s)
PY
}

# ---- the plants, one function per gate: each runs the gate copy <g> on its plants and sets one class variable each
prove_latch() {  # prove_latch <gate copy> — sets LA1 LA2 LA3
    _t="$W/latch"; rm -rf "$_t"; mkdir -p "$_t/tests/lib" "$_t/tools" "$_t/romdir" "$_t/b/rompath"
    cp "$1" "$_t/tests/audit_latch_reads.sh"; ln -s "$REPO/tests/lib/jobs.sh" "$_t/tests/lib/jobs.sh"; ln -s "$REPO/tests/replays" "$_t/tests/replays"
    : > "$_t/romdir/vsav2.zip"; : > "$_t/b/rompath/vsavjw.zip"; printf '#!/bin/sh\nexit 0\n' > "$_t/mame"; chmod +x "$_t/mame"
    _g="$_t/tests/audit_latch_reads.sh"; _env="ROMDIR=$_t/romdir MAME_BIN=$_t/mame BUILD=b LEGS=phobos-real JOBS=1"
    # 1: the tap's target line moved (the same window written ${blk}), so the mode's sed matches nothing
    sed 's/RTAP="\$blk,40"/RTAP="${blk},40"/' tools/tap_latch_reads.sh > "$_t/tools/tap_latch_reads.sh"; chmod +x "$_t/tools/tap_latch_reads.sh"
    command grep -q 'RTAP="${blk},40"' "$_t/tools/tap_latch_reads.sh" || { LA1="(the plant itself did not apply)"; return; }
    # shellcheck disable=SC2086
    run_cl latch1 "$_g" tap-window-moved $_env; LA1="$CL"
    # 2 and 3: the sed applies, and the perturbed copy dies — of a shell error, then of a Python exception
    printf '#!/bin/sh\nblk=ff87bc; RTAP="$blk,40"\nREPO=x\ng6_no_such_command_planted\n' > "$_t/tools/tap_latch_reads.sh"
    # shellcheck disable=SC2086
    run_cl latch2 "$_g" tap-window-moved $_env; LA2="$CL"
    printf '#!/bin/sh\nblk=ff87bc; RTAP="$blk,40"\nREPO=x\npython3 -c "raise ValueError(\\"a planted crash in the perturbed tap copy\\")"\nexit 1\n' > "$_t/tools/tap_latch_reads.sh"
    # shellcheck disable=SC2086
    run_cl latch3 "$_g" tap-window-moved $_env; LA3="$CL"
}
prove_follows() {  # prove_follows <gate copy> — sets GF1 GF2
    _t="$W/gf1"; rm -rf "$_t"; mirror "$_t"; rm "$_t/tests/test_gate_follows.sh" "$_t/tests/ci_emulator.tsv"; cp "$1" "$_t/tests/test_gate_follows.sh"
    # 1: a registry with no gate in it — no declaring gate to perturb, so the plant cannot apply
    command grep '^#' tests/ci_emulator.tsv > "$_t/tests/ci_emulator.tsv"
    run_cl gf1 "$_t/tests/test_gate_follows.sh" dropped-declaration; GF1="$CL"
    # 2: a SECOND declaring gate's FOLLOWS gone in the tree the copy is made from — a foreign LOST row beside the mode's own
    _t="$W/gf2"; rm -rf "$_t"; mirror "$_t"; rm "$_t/tests/test_gate_follows.sh"; cp "$1" "$_t/tests/test_gate_follows.sh"
    _g2="$(python3 tools/gate_follows.py --root . 2>/dev/null | cut -f1,2 | sort | awk -F'\t' '$1=="declares"{print $2}' | sed -n 2p)"
    [ -n "$_g2" ] || { GF2="(no second declaring gate)"; return; }
    rm "$_t/tests/$_g2.sh"; sed -e '/^# FOLLOWS:/,/^#\( [A-Z]\|$\)/{/^# FOLLOWS:/d; /^#  /d;}' "tests/$_g2.sh" > "$_t/tests/$_g2.sh"
    cmp -s "tests/$_g2.sh" "$_t/tests/$_g2.sh" && { GF2="(the plant itself did not apply)"; return; }
    run_cl gf2 "$_t/tests/test_gate_follows.sh" dropped-declaration; GF2="$CL"; GF2_GATE="$_g2"
}
prove_pokerb() {  # prove_pokerb <gate copy> — sets PR1 PR2
    _t="$W/pr1"; rm -rf "$_t"; mirror "$_t"; rm "$_t/tests/test_poke_readback.sh" "$_t/tests/test_killshread_es.sh"; cp "$1" "$_t/tests/test_poke_readback.sh"
    # 1: the known case's field moved to the head of its FIELDS list, where the mode's sed (`,ff8509:b:stock`) cannot reach it
    sed -e 's/,ff8509:b:stock//' -e 's/^FIELDS="/FIELDS="ff8509:b:stock,/' tests/test_killshread_es.sh > "$_t/tests/test_killshread_es.sh"
    command grep -q '^FIELDS="ff8509:b:stock,' "$_t/tests/test_killshread_es.sh" || { PR1="(the plant itself did not apply)"; return; }
    run_cl pr1 "$_t/tests/test_poke_readback.sh" known-case-blind; PR1="$CL"
    # 2: a synthetic gate with its own unclassified finding in the tree the copy is made from, beside the mode's own
    _t="$W/pr2"; rm -rf "$_t"; mirror "$_t"; rm "$_t/tests/test_poke_readback.sh" "$_t/tests/ci_emulator.tsv"; cp "$1" "$_t/tests/test_poke_readback.sh"
    printf '#!/bin/sh\n: "${MAME_BIN:-}"\nPOKES="1400:ff%s:10"\nFIELDS="ff%s:b:id"\necho PASS\n' 8782 8782 > "$_t/tests/test_g6_foreign_probe.sh"   # the address is an argument so tools/audit_poked_legs.py does not census this fixture as a forced-pick leg
    { cat tests/ci_emulator.tsv; printf 'test_g6_foreign_probe\tmame\trelease\tromset\t-\tsynthetic\n'; } > "$_t/tests/ci_emulator.tsv"
    run_cl pr2 "$_t/tests/test_poke_readback.sh" rig-poke-width; PR2="$CL"
}

prove_rulecheck() {  # prove_rulecheck <gate copy> — sets RC1 RC2
    _t="$W/rc"; rm -rf "$_t"; mkdir -p "$_t/tests/expected" "$_t/tools" "$_t/docs/project" "$_t/.claude/agents"
    cp "$1" "$_t/tests/test_rule_checker.sh"; ln -s "$REPO/tests/lib" "$_t/tests/lib"
    cp -R tests/rulecheck "$_t/tests/rulecheck"; cp tests/expected/registry.tsv "$_t/tests/expected/"
    _rcdoc=docs/project/rule_checker.md; cp "$_rcdoc" "$_t/docs/project/"; cp .claude/agents/rule-checker.md "$_t/.claude/agents/"
    for _f in tools/*; do ln -s "$REPO/$_f" "$_t/tools/"; done; rm "$_t/tools/rulecheck.py"
    # the plant: an assert after the line the mode's shadow rewrites, true on this copy, false once that line is rewritten
    python3 - tools/rulecheck.py "$_t/tools/rulecheck.py" <<'PY' || { RC1="(the plant itself did not apply)"; RC2="$RC1"; return; }
import sys
s = open(sys.argv[1]).read()
for line, gone in (("    n = max(taken + [0])\n", "len(ledger_rows), len([p f"),
                   ("\n                    and calibrated(ledger_rows, n, root) and plant_readable(root, n)]\n", "calibrated(ledger_rows, n, root)]\n")):
    assert s.count(line) == 1, line
    ind = "    " if "taken" in line else "        "   # the statement's own indentation (the rotation's list ends its statement)
    probe = repr(gone[:5]) + " + " + repr(gone[5:])
    s = s.replace(line, line + f"{ind}assert ({probe}) not in open(__file__).read(), 'a planted crash in the shadow (tests/test_plants_not_applied.sh)'\n")
open(sys.argv[2], "w").write(s)
PY
    run_cl rc1 "$_t/tests/test_rule_checker.sh" counted-id; RC1="$CL"
    run_cl rc2 "$_t/tests/test_rule_checker.sh" unfiltered-plants; RC2="$CL"
}

if [ -n "$VS_CTL" ]; then   # THE MODE: the plants run on the reverted copy; the gate FAILs on exactly that — every plant HONOURED
    case "$VS_CTL" in latch-fix-reverted) k=latch; src=tests/audit_latch_reads.sh ;; follows-fix-reverted) k=follows; src=tests/test_gate_follows.sh ;;
                      pokerb-fix-reverted) k=pokerb; src=tests/test_poke_readback.sh ;;
                      rulecheck-fix-reverted) k=rulecheck; src=tests/test_rule_checker.sh ;; esac
    revert "$k" "$src" "$W/reverted.sh" || { echo "REFUSED: $VS_CTL — the 14z-215 lines were not found to revert: the mode judged nothing"; exit 3; }
    case "$k" in latch) prove_latch "$W/reverted.sh"; got="$LA1 $LA2 $LA3"; want="HONOURED HONOURED HONOURED" ;;
                 follows) prove_follows "$W/reverted.sh"; got="$GF1 $GF2"; want="HONOURED HONOURED" ;;
                 pokerb) prove_pokerb "$W/reverted.sh"; got="$PR1 $PR2"; want="HONOURED HONOURED" ;;
                 rulecheck) prove_rulecheck "$W/reverted.sh"; got="$RC1 $RC2"; want="HONOURED HONOURED" ;; esac
    echo "MODE: control $VS_CTL — the plants on the reverted copy read: $got"
    if [ "$got" = "$want" ]; then vs_ctl_fired "$VS_CTL" "the reverted copy reads $got (mode)"; echo "FAIL: test_plants_not_applied (control mode $VS_CTL)"; exit 1; fi
    case "$got" in *UNJUDGED*|*DIED*) vs_ctl_left_green "$VS_CTL" "FAIL: test_plants_not_applied — control mode $VS_CTL: the reverted copy still reads $got" ;; esac
    echo "NOT JUDGED: $VS_CTL — the reverted copy read $got, neither the fix's classes nor the false honour"; echo "FAIL: test_plants_not_applied"; exit 1
fi

echo "== 1. audit_latch_reads@tap-window-moved (a stub MAME; refused or failed before any emulator could start)"
prove_latch tests/audit_latch_reads.sh
[ "$LA1" = UNJUDGED ] && command grep -q '^REFUSED: tap-window-moved' "$W/latch1.log" && ok "the tap's target line moved: UNJUDGED ($(command grep -m1 '^REFUSED: ' "$W/latch1.log" | cut -c1-90))" \
    || bad "the tap's target line moved read $LA1 (want UNJUDGED with the gate's REFUSED line): $(tail -1 "$W/latch1.log")"
[ "$LA2" = UNJUDGED ] && ok "the perturbed tap copy died of a shell error: UNJUDGED ($(command grep -m1 '^NOT JUDGED: ' "$W/latch2.log" | cut -c1-90))" \
    || bad "the perturbed tap copy's shell error read $LA2 (want UNJUDGED): $(tail -1 "$W/latch2.log")"
[ "$LA3" = DIED ] && ok "the perturbed tap copy raised: DIED ($(command grep -m1 '^ValueError' "$W/latch3.log" | cut -c1-80))" \
    || bad "the perturbed tap copy's exception read $LA3 (want DIED): $(tail -1 "$W/latch3.log")"

echo "== 2. test_gate_follows@dropped-declaration on a partial copy"
prove_follows tests/test_gate_follows.sh
[ "$GF1" = UNJUDGED ] && command grep -q '^REFUSED: dropped-declaration' "$W/gf1.log" && ok "no gate to perturb: UNJUDGED ($(command grep -m1 '^REFUSED: ' "$W/gf1.log" | cut -c1-90))" \
    || bad "no gate to perturb read $GF1 (want UNJUDGED with the gate's REFUSED line): $(tail -1 "$W/gf1.log")"
[ "$GF2" = UNJUDGED ] && ok "a second declarer's FOLLOWS gone on the copy (${GF2_GATE:-?}): UNJUDGED ($(command grep -m1 '^NOT JUDGED: ' "$W/gf2.log" | cut -c1-110))" \
    || bad "a foreign LOST row on the copy read $GF2 (want UNJUDGED): $(tail -1 "$W/gf2.log")"

echo "== 3. test_poke_readback on a partial copy"
prove_pokerb tests/test_poke_readback.sh
[ "$PR1" = UNJUDGED ] && command grep -q '^REFUSED: known-case-blind' "$W/pr1.log" && ok "known-case-blind with the field moved: UNJUDGED ($(command grep -m1 '^REFUSED: ' "$W/pr1.log" | cut -c1-90))" \
    || bad "known-case-blind with the field moved read $PR1 (want UNJUDGED with the gate's REFUSED line): $(tail -1 "$W/pr1.log")"
[ "$PR2" = UNJUDGED ] && ok "rig-poke-width beside a foreign finding: UNJUDGED ($(command grep -m1 '^NOT JUDGED: ' "$W/pr2.log" | cut -c1-110))" \
    || bad "rig-poke-width beside a foreign finding read $PR2 (want UNJUDGED): $(tail -1 "$W/pr2.log")"

echo "== 4. test_rule_checker's shadow modes whose shadow's prepare raises (#310 group 5)"
prove_rulecheck tests/test_rule_checker.sh
[ "$RC1" = DIED ] && ok "counted-id, its shadow's prepare raising: DIED ($(command grep -m1 '^AssertionError' "$W/rc1.log" | cut -c1-80))" \
    || bad "counted-id with its shadow raising read $RC1 (want DIED): $(tail -1 "$W/rc1.log")"
[ "$RC2" = DIED ] && ok "unfiltered-plants, its shadow's prepare raising: DIED ($(command grep -m1 '^AssertionError' "$W/rc2.log" | cut -c1-80))" \
    || bad "unfiltered-plants with its shadow raising read $RC2 (want DIED): $(tail -1 "$W/rc2.log")"

echo "== 5. controls: each gate with its 14z-215 lines reverted reads HONOURED on its plants (the false honour)"
for c in latch-fix-reverted:latch:tests/audit_latch_reads.sh follows-fix-reverted:follows:tests/test_gate_follows.sh pokerb-fix-reverted:pokerb:tests/test_poke_readback.sh rulecheck-fix-reverted:rulecheck:tests/test_rule_checker.sh; do
    n="${c%%:*}"; r="${c#*:}"; k="${r%%:*}"; src="${r#*:}"
    if ! revert "$k" "$src" "$W/rev_$k.sh" > "$W/rev_$k.err" 2>&1; then vs_ctl_dead "$n" "the 14z-215 lines were not found to revert: $(tail -1 "$W/rev_$k.err")" || fail=1; continue; fi
    case "$k" in latch) prove_latch "$W/rev_$k.sh"; got="$LA1 $LA2 $LA3"; want="HONOURED HONOURED HONOURED" ;;
                 follows) prove_follows "$W/rev_$k.sh"; got="$GF1 $GF2"; want="HONOURED HONOURED" ;;
                 pokerb) prove_pokerb "$W/rev_$k.sh"; got="$PR1 $PR2"; want="HONOURED HONOURED" ;;
                 rulecheck) prove_rulecheck "$W/rev_$k.sh"; got="$RC1 $RC2"; want="HONOURED HONOURED" ;; esac
    if [ "$got" = "$want" ]; then vs_ctl_fired "$n" "the reverted copy reads $got on its plants"
    else vs_ctl_dead "$n" "the reverted copy reads $got (want $want)" || fail=1; fi
done

[ "$fail" = 0 ] && echo "PASS: test_plants_not_applied — no mode whose plant did not apply, or whose copy is red elsewhere, reads HONOURED" || echo "FAIL: test_plants_not_applied"
exit "$fail"
