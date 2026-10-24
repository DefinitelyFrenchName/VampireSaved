#!/bin/sh
# test_release_reuse.sh — A RELEASE REUSES THE FREEZE'S TIER ONLY ON THE FREEZE'S IDENTITY (#316, 14z-208).
#
# WHAT: a release run given the freeze run's results (`tests/run_all_static.sh --cadence release --reuse <freeze
#   results.tsv>`, `tests/run_all_emulator.sh --reuse <freeze log dir>`) reuses a gate's PASS only when the tree, the
#   instruments and ROMDIR are the freeze's, byte for byte, and otherwise runs everything; a release-cadence gate, a
#   gate that reads VS_CADENCE and an emulator gate's must-fire controls are never reused.
# HOW: one synthetic git repo of stub gates that log every execution (session, freeze and release cadence, one reading
#   VS_CADENCE, one with a declared control; two emulator-tier stubs, one with a control) driven through the REAL
#   runners and the REAL tools/reuse_identity.py: a strict GREEN freeze run, then a release --reuse run on the same
#   identity, then one release run each with a tracked file changed, the mame-wide instrument changed and a ROMDIR
#   file changed; the emulator runner likewise (a freeze run, a --controls release on it, one with the instrument
#   changed); the argument refusals; and the tool's own self-test.
# EXPECTS: the same-identity release reuses exactly the session and freeze gates and executes no control of theirs,
#   runs the release-cadence and VS_CADENCE gates, and is GREEN; each changed key prints REUSE REFUSED with that key
#   DIFFERS and runs every gate; the emulator release reuses both gate rows and still executes the control; --reuse
#   outside --cadence release or beside --confirm exits 2. A red names the case that reused what it must not.
#
# MUST-FIRE: shadow-tool: blind-tree — a copy of tools/reuse_identity.py whose ID-TREE line is disabled must let the release with a changed tracked file reuse the freeze's gates, and section 3 must FAIL (mode: that copy is the synthetic repo's tool)
# MUST-FIRE: shadow-tool: blind-instrument — a copy of tools/reuse_identity.py whose ID-INSTRUMENT line is disabled must let the release with a changed mame-wide binary reuse the freeze's gates, and section 4 must FAIL (mode: that copy is the synthetic repo's tool)
# MUST-FIRE: shadow-tool: blind-romdir — a copy of tools/reuse_identity.py whose ID-ROMDIR line is disabled must let the release with a changed ROMDIR file reuse the freeze's gates, and section 5 must FAIL (mode: that copy is the synthetic repo's tool)
# MUST-FIRE: shadow-tool: release-reused — a copy of tools/reuse_identity.py whose REUSE-NOT-RELEASE branch is disabled must reuse the release-cadence stub, and section 2 must FAIL (mode: that copy is the synthetic repo's tool)
# MUST-FIRE: shadow-tool: identity-unchecked — a copy of run_all_static.sh whose REUSE-IDENTITY comparison is disabled must reuse on a changed identity, and sections 3 to 5 must FAIL (mode: that copy is the synthetic repo's static runner)
# MUST-FIRE: shadow-tool: emu-identity-unchecked — a copy of run_all_emulator.sh whose REUSE-IDENTITY comparison is disabled must reuse on a changed instrument, and section 8 must FAIL (mode: that copy is the synthetic repo's emulator runner)
# MUST-FIRE: shadow-tool: release-only-off — a copy of run_all_static.sh whose REUSE-RELEASE-ONLY refusal is disabled must accept --reuse at --cadence freeze, and section 6 must FAIL (mode: that copy is the synthetic repo's static runner)
set -u
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
. "$REPO/tests/lib/controls.sh"; vs_ctl_mode "$0"
rc=0
fail() { echo "  FAIL: $*"; rc=1; }
ok()   { echo "  ok: $*"; }

T="$(mktemp -d)"; trap 'rm -rf "$T"' EXIT INT TERM
R="$T/repo"
mkdir -p "$R/tests/lib" "$R/tools" "$R/tests/expected" "$T/roms" "$T/roms2"
unset STATIC_JOBS STATIC_RESULTS_OUT MAME_BIN MERGED DON HUI PYR STOCK CONTROL 2>/dev/null || true

# THE SHADOWS, each made from the real file on its tagged line; a moved line is a red here, never a silent no-op
shadow_py() {  # shadow_py <out> <tag> — the identity tool with the tagged line's statement replaced by `pass`
    python3 - "$REPO/tools/reuse_identity.py" "$1" "$2" <<'PYX'
import re, sys
src, out, tag = sys.argv[1:]
s = open(src).read()
if tag == "REUSE-NOT-RELEASE":
    a = 'if c == "release":   # REUSE-NOT-RELEASE'
    assert s.count(a) == 1, "the REUSE-NOT-RELEASE line moved"
    s = s.replace(a, 'if False:   # REUSE-NOT-RELEASE (CONTROL release-reused)')
else:
    s2, n = re.subn(r'lines\.append\([^\n]*\)   # %s$' % tag, 'pass   # CONTROL: %s blinded' % tag, s, flags=re.M)
    assert n >= 1, "the %s line moved" % tag
    s = s2
open(out, "w").write(s)
PYX
}
shadow_py "$T/ri_blind_tree.py" ID-TREE || fail "could not make blind-tree"
shadow_py "$T/ri_blind_instrument.py" ID-INSTRUMENT || fail "could not make blind-instrument"
shadow_py "$T/ri_blind_romdir.py" ID-ROMDIR || fail "could not make blind-romdir"
shadow_py "$T/ri_release_reused.py" REUSE-NOT-RELEASE || fail "could not make release-reused"
sed 's|^    elif ! python3 tools/reuse_identity.py compare "\$REUSE" "\$WORK/id_start.txt" > "\$WORK/reuse_cmp.txt" 2>&1; then   # REUSE-IDENTITY$|    elif ! : > "$WORK/reuse_cmp.txt"; then   # CONTROL identity-unchecked: nothing compared|' \
    tests/run_all_static.sh > "$T/static_unchecked.sh"
cmp -s tests/run_all_static.sh "$T/static_unchecked.sh" && fail "could not disable REUSE-IDENTITY in run_all_static.sh — the line moved"
sed 's|^if \[ -n "\$REUSE" \] && { \[ "\$CADENCE" != release \] \|\| \[ -n "\$CONFIRM" \]; }; then   # REUSE-RELEASE-ONLY$|if false; then   # CONTROL release-only-off|' \
    tests/run_all_static.sh > "$T/static_anycadence.sh"
cmp -s tests/run_all_static.sh "$T/static_anycadence.sh" && fail "could not disable REUSE-RELEASE-ONLY — the line moved"
sed 's|^    elif ! python3 tools/reuse_identity.py compare "\$REUSE/identity.tsv" "\$_ID_NOW" > "\$LOGDIR/.reuse_cmp" 2>&1; then   # REUSE-IDENTITY$|    elif ! : > "$LOGDIR/.reuse_cmp"; then   # CONTROL emu-identity-unchecked: nothing compared|' \
    tests/run_all_emulator.sh > "$T/emu_unchecked.sh"
cmp -s tests/run_all_emulator.sh "$T/emu_unchecked.sh" && fail "could not disable REUSE-IDENTITY in run_all_emulator.sh — the line moved"

# THE SYNTHETIC REPO: the real runners (or a shadow under its CONTROL), the real libraries, the real tools
case "${VS_CTL:-}" in
identity-unchecked) cp "$T/static_unchecked.sh" "$R/tests/run_all_static.sh" ;;
release-only-off)   cp "$T/static_anycadence.sh" "$R/tests/run_all_static.sh" ;;
*)                  cp tests/run_all_static.sh "$R/tests/run_all_static.sh" ;;
esac
if vs_ctl_is emu-identity-unchecked; then cp "$T/emu_unchecked.sh" "$R/tests/run_all_emulator.sh"
else cp tests/run_all_emulator.sh "$R/tests/run_all_emulator.sh"; fi
for _l in classify controls measures; do cp "tests/lib/$_l.sh" "$R/tests/lib/$_l.sh"; done
cp tools/static_confirm.py tools/battery_reach.py tools/build_dirs.py "$R/tools/"
cp tests/expected/build_dirs.tsv "$R/tools/"
case "${VS_CTL:-}" in
blind-tree)       cp "$T/ri_blind_tree.py" "$R/tools/reuse_identity.py" ;;
blind-instrument) cp "$T/ri_blind_instrument.py" "$R/tools/reuse_identity.py" ;;
blind-romdir)     cp "$T/ri_blind_romdir.py" "$R/tools/reuse_identity.py" ;;
release-reused)   cp "$T/ri_release_reused.py" "$R/tools/reuse_identity.py" ;;
*)                cp tools/reuse_identity.py "$R/tools/reuse_identity.py" ;;
esac
printf '#!/usr/bin/env python3\nimport sys\n' > "$R/tools/audit_roms.py"
printf '#!/usr/bin/env python3\nprint("deadbeefcafe")\n' > "$R/tools/build_fingerprint.py"
chmod +x "$R/tests/run_all_static.sh" "$R/tests/run_all_emulator.sh" "$R/tools/audit_roms.py" "$R/tools/build_fingerprint.py"
RAN="$T/ran.log"
stub() {  # stub <name> [ctl] [extra line] — a gate that logs each execution (name, or name@control) and PASSes
    { echo "#!/bin/sh"; echo "# $1.sh — a #316 stub"
      [ -z "${2:-}" ] || echo "# MUST-FIRE: perturbed-copy: $2 — the stub's own control"
      [ -z "${3:-}" ] || echo "$3"
      echo 'echo "$(basename "$0" .sh)${CONTROL:+@$CONTROL}" >> "$RAN_LOG"'
      [ -z "${2:-}" ] || { echo "if [ \"\${CONTROL:-}\" = $2 ]; then echo 'FAIL: caught'; exit 1; fi"; echo "echo 'CONTROL FIRED: $2 — caught'"; }
      echo "echo 'PASS'"; } > "$R/tests/$1.sh"
    chmod +x "$R/tests/$1.sh"
}
stub g_sess flip
stub g_frz
stub g_rel
stub g_cad "" ': "${VS_CADENCE:-}"   # judges by cadence'
stub e_a "" ': "${MAME_BIN:-}"   # emulator-tier marker'
stub e_b flip ': "${MAME_BIN:-}"   # emulator-tier marker'
printf 'g_sess\ng_frz\ng_rel\ng_cad\n' > "$R/tests/ci_portable.txt"; : > "$R/tests/ci_static.txt"
printf 'g_frz\tfreeze\t-\ng_rel\trelease\t-\n' > "$R/tests/ci_cadence.tsv"
printf 'e_a\tmame\trelease\tromset\t-\ta stub\ne_b\tmame\trelease\tromset\t-\ta stub\n' > "$R/tests/ci_emulator.tsv"
echo base > "$R/README"
(cd "$R" && git init -q && git add -A && git -c user.name=t -c user.email=t@t commit -qm base)
echo "zip-one" > "$T/roms/a.zip"; echo "zip-two" > "$T/roms2/a.zip"
printf 'wide\n' > "$T/mame_w"; printf 'wide-rebuilt\n' > "$T/mame_w2"; printf 'ref\n' > "$T/mame_r"
chmod +x "$T/mame_w" "$T/mame_w2" "$T/mame_r"

st() {  # st <out> <args...> — the static runner in the synthetic repo, its executions logged afresh
    _o="$1"; shift; : > "$RAN"
    (cd "$R" && RAN_LOG="$RAN" ROMDIR="${S_ROMDIR:-$T/roms}" MAME_WIDE_BIN="${S_MAME_W:-$T/mame_w}" MAME_REF_BIN="$T/mame_r" \
        STATIC_RESULTS_OUT="$_o" sh tests/run_all_static.sh "$@" 2>&1)
}
ran() { sort "$RAN" | tr '\n' ' ' | sed 's/ $//'; }
ALL="g_cad g_frz g_rel g_sess g_sess@flip"

echo "== 0. the identity tool's self-test =="
if python3 tools/reuse_identity.py --selftest > "$T/selftest.out" 2>&1 && grep -q '^selftest: PASS' "$T/selftest.out"; then
    ok "tools/reuse_identity.py --selftest PASS ($(grep -c '^  ok: ' "$T/selftest.out") checks)"
else fail "the self-test: $(tail -3 "$T/selftest.out" | tr '\n' '|')"; fi

echo "== 1. the freeze run: strict, GREEN, every gate and control run, its identity recorded at start and end =="
# the release-cadence stub's own script counts as changed, so the freeze pulls it in (a trigger, as a real freeze can):
# its PASS is then in the freeze's results, and section 2 proves it is still never reused
o1="$(STATIC_CHANGED_PATHS=tests/g_rel.sh st "$T/freeze.tsv" --strict --cadence freeze)" && s1=0 || s1=$?
if [ "$s1" = 0 ] && printf '%s' "$o1" | grep -q '^GREEN' && [ "$(ran)" = "$ALL" ]; then ok "the freeze run is GREEN and ran: $(ran)"
else fail "the freeze run (exit $s1) ran '$(ran)': $(printf '%s' "$o1" | tail -3 | tr '\n' '|')"; fi
for _k in tree romdir 'instrument mame-wide' 'instrument python3' untracked; do
    grep -q "^# id $_k " "$T/freeze.tsv" && grep -q "^# id_end $_k " "$T/freeze.tsv" \
        || fail "the freeze results lack '# id $_k' or '# id_end $_k'"
done

echo "== 2. the release on the freeze's identity: the session and freeze gates REUSED, no control of theirs executed =="
o2="$(st "$T/rel.tsv" --strict --cadence release --reuse "$T/freeze.tsv")" && s2=0 || s2=$?
if [ "$s2" = 0 ] && printf '%s' "$o2" | grep -q '^GREEN' && [ "$(ran)" = "g_cad g_rel" ] \
        && printf '%s' "$o2" | grep -qE '^  g_sess +PASS  reused' && printf '%s' "$o2" | grep -qE '^  g_frz +PASS  reused' \
        && printf '%s' "$o2" | grep -q '^reused: 2 of the PASS'; then
    ok "reused g_sess and g_frz (their control not executed); ran only: $(ran)"
else fail "the same-identity release (exit $s2) ran '$(ran)': $(printf '%s' "$o2" | grep -E '^  g_|^reused|GREEN' | tr '\n' '|')"; fi
grep -q "^g_sess	PASS	0	1	1	1$" "$T/rel.tsv" && ok "the reused row carries the freeze's control counts (declared 1, fired 1, honoured 1)" \
    || fail "the reused g_sess row: $(grep '^g_sess' "$T/rel.tsv")"
grep -q "^# reuse $T/freeze.tsv 2$" "$T/rel.tsv" && ok "the release results name the freeze run they reused and the count" \
    || fail "the release results lack '# reuse <file> 2'"
printf '%s' "$o2" | grep -qE '^    run    g_rel +release cadence' && printf '%s' "$o2" | grep -qE '^    run    g_cad +its script reads VS_CADENCE' \
    && ok "the release-cadence gate and the VS_CADENCE reader are named as run, with the reason" \
    || fail "the reuse plan's RUN lines: $(printf '%s' "$o2" | grep '^    run' | tr '\n' '|')"

refused() {  # refused <section label> <key> <output> <exit>
    if [ "$4" = 0 ] && printf '%s' "$3" | grep -q 'REUSE REFUSED: the identity differs' \
            && printf '%s' "$3" | grep -q "DIFFERS  $2" && [ "$(ran)" = "$ALL" ] && ! printf '%s' "$3" | grep -q 'reused'; then
        ok "$1: REUSE REFUSED ($2 DIFFERS), every gate and control ran"
    else fail "$1 (exit $4) ran '$(ran)': $(printf '%s' "$3" | grep -E 'REFUSED|DIFFERS|reused|GREEN' | tr '\n' '|')"; fi
}
echo "== 3. a changed tree refuses the reuse =="
echo changed > "$R/README"
o3="$(st "$T/rel3.tsv" --strict --cadence release --reuse "$T/freeze.tsv")" && s3=0 || s3=$?
refused "a tracked file changed" tree "$o3" "$s3"
(cd "$R" && git checkout -q -- README)

echo "== 4. a changed instrument refuses the reuse =="
o4="$(S_MAME_W="$T/mame_w2" st "$T/rel4.tsv" --strict --cadence release --reuse "$T/freeze.tsv")" && s4=0 || s4=$?
refused "the mame-wide binary changed" "instrument mame-wide" "$o4" "$s4"

echo "== 5. a changed ROMDIR refuses the reuse =="
o5="$(S_ROMDIR="$T/roms2" st "$T/rel5.tsv" --strict --cadence release --reuse "$T/freeze.tsv")" && s5=0 || s5=$?
refused "a ROMDIR file changed" romdir "$o5" "$s5"

echo "== 6. --reuse is a release's: refused at --cadence freeze and beside --confirm =="
o6="$(st "$T/rel6.tsv" --strict --cadence freeze --reuse "$T/freeze.tsv")" && s6=0 || s6=$?
[ "$s6" = 2 ] && printf '%s' "$o6" | grep -q '^--reuse: only a --cadence release run' && ok "--reuse at --cadence freeze exits 2, nothing run" \
    || fail "--reuse at --cadence freeze exited $s6 and ran '$(ran)'"
o6b="$(st "$T/rel6b.tsv" --strict --cadence release --confirm "$T/freeze.tsv" --reuse "$T/freeze.tsv")" && s6b=0 || s6b=$?
[ "$s6b" = 2 ] && ok "--reuse beside --confirm exits 2" || fail "--reuse beside --confirm exited $s6b"

echo "== 7. a results file that is not a freeze's run of record is not reused =="
o7="$(st "$T/rel7.tsv" --strict --cadence release --reuse "$T/rel.tsv")" && s7=0 || s7=$?
if [ "$s7" = 0 ] && printf '%s' "$o7" | grep -q 'REUSE REFUSED: the freeze file cannot be reused' && [ "$(ran)" = "$ALL" ]; then
    ok "a release run's results offered as the freeze's: REFUSED, every gate ran"
else fail "a non-freeze file (exit $s7) ran '$(ran)': $(printf '%s' "$o7" | grep -E 'REFUSED|reused' | tr '\n' '|')"; fi

echo "== 8. the emulator runner: gate rows reused on the freeze's identity, controls still executed; a changed instrument refuses =="
em() {  # em <logdir> <args...>
    _d="$1"; shift; : > "$RAN"
    (cd "$R" && RAN_LOG="$RAN" ROMDIR="$T/roms" MAME_WIDE_BIN="${S_MAME_W:-$T/mame_w}" MAME_REF_BIN="$T/mame_r" \
        sh tests/run_all_emulator.sh --strict --log "$_d" "$@" 2>&1)
}
e1="$(em "$T/efreeze" --freeze)" && se1=0 || se1=$?
if [ "$se1" = 0 ] && [ "$(ran)" = "e_a e_b" ] && [ -s "$T/efreeze/identity.tsv" ] && [ -s "$T/efreeze/identity_end.tsv" ]; then
    ok "the emulator freeze run ran e_a e_b and wrote identity.tsv and identity_end.tsv"
else fail "the emulator freeze run (exit $se1) ran '$(ran)': $(printf '%s' "$e1" | tail -3 | tr '\n' '|')"; fi
e2="$(em "$T/erel" --controls --reuse "$T/efreeze")" && se2=0 || se2=$?
if [ "$se2" = 0 ] && [ "$(ran)" = "e_b@flip" ] && [ "$(awk -F'\t' '$6 ~ /^reused: /' "$T/erel/results.tsv" | wc -l | tr -d ' ')" = 2 ] \
        && grep -q "^e_b@flip	mame	release	PASS" "$T/erel/results.tsv"; then
    ok "the --controls release reused e_a and e_b and executed e_b's control (e_b@flip PASS)"
else fail "the emulator release (exit $se2) ran '$(ran)': $(printf '%s' "$e2" | grep -E 'reused|REFUSED|e_' | tr '\n' '|')"; fi
e3="$(S_MAME_W="$T/mame_w2" em "$T/erel3" --controls --reuse "$T/efreeze")" && se3=0 || se3=$?
if [ "$se3" = 0 ] && printf '%s' "$e3" | grep -q 'REUSE REFUSED: the identity differs' && printf '%s' "$e3" | grep -q 'DIFFERS  instrument mame-wide' \
        && [ "$(ran)" = "e_a e_b e_b@flip" ]; then
    ok "a changed mame-wide binary: REUSE REFUSED, both gates and the control ran"
else fail "the emulator release on a changed instrument (exit $se3) ran '$(ran)': $(printf '%s' "$e3" | grep -E 'reused|REFUSED|DIFFERS' | tr '\n' '|')"; fi

# THE CONTROLS FIRE IN-RUN (the normal run only): each shadow, on the perturbation its section makes, misses it
if [ -z "${VS_CTL:-}" ]; then
    echo "== 9. MUST-FIRE: each shadow, given its section's perturbation, misses it =="
    blind() {  # blind <control> <shadow> <what> — env assignments in $B_ENV2 make the second identity
        (cd "$R" && ROMDIR="$T/roms" MAME_WIDE_BIN="$T/mame_w" MAME_REF_BIN="$T/mame_r" python3 "$2" emit --root .) > "$T/id_a"
        [ "$1" = blind-tree ] && echo changed > "$R/README"
        (cd "$R" && ROMDIR="$B_ROMDIR" MAME_WIDE_BIN="$B_MAME_W" MAME_REF_BIN="$T/mame_r" python3 "$2" emit --root .) > "$T/id_b"
        [ "$1" = blind-tree ] && (cd "$R" && git checkout -q -- README)
        if python3 "$2" compare "$T/id_a" "$T/id_b" > /dev/null; then vs_ctl_fired "$1" "$3 compares SAME with the line disabled"
        else vs_ctl_dead "$1" "the shadow still sees $3"; rc=1; fi
    }
    B_ROMDIR="$T/roms"; B_MAME_W="$T/mame_w"; blind blind-tree "$T/ri_blind_tree.py" "a changed tracked file"
    B_ROMDIR="$T/roms"; B_MAME_W="$T/mame_w2"; blind blind-instrument "$T/ri_blind_instrument.py" "a changed mame-wide binary"
    B_ROMDIR="$T/roms2"; B_MAME_W="$T/mame_w"; blind blind-romdir "$T/ri_blind_romdir.py" "a changed ROMDIR file"
    if python3 "$T/ri_release_reused.py" plan --root "$R" --results "$T/freeze.tsv" | grep -q "^REUSE	g_rel	"; then
        vs_ctl_fired release-reused "the release-cadence stub g_rel is planned REUSE with the branch disabled"
    else vs_ctl_dead release-reused "the shadow plan still runs g_rel"; rc=1; fi
    cp "$R/tests/run_all_static.sh" "$T/static_real.sh"; cp "$T/static_unchecked.sh" "$R/tests/run_all_static.sh"
    o9="$(S_ROMDIR="$T/roms2" st "$T/rel9.tsv" --strict --cadence release --reuse "$T/freeze.tsv")" || true
    if printf '%s' "$o9" | grep -q '^reused: 2 of the PASS'; then vs_ctl_fired identity-unchecked "a changed ROMDIR is reused with the comparison disabled"
    else vs_ctl_dead identity-unchecked "the shadow runner still refused: $(printf '%s' "$o9" | grep -E 'REFUSED|reused' | tr '\n' '|')"; rc=1; fi
    cp "$T/static_anycadence.sh" "$R/tests/run_all_static.sh"
    o9b="$(st "$T/rel9b.tsv" --strict --cadence freeze --reuse "$T/freeze.tsv")" && s9b=0 || s9b=$?
    if [ "$s9b" != 2 ]; then vs_ctl_fired release-only-off "--reuse at --cadence freeze is accepted (exit $s9b) with the refusal disabled"
    else vs_ctl_dead release-only-off "the shadow runner still refused --reuse at freeze"; rc=1; fi
    cp "$T/static_real.sh" "$R/tests/run_all_static.sh"
    cp "$T/emu_unchecked.sh" "$R/tests/run_all_emulator.sh"
    e9="$(S_MAME_W="$T/mame_w2" em "$T/erel9" --controls --reuse "$T/efreeze")" || true
    if [ "$(awk -F'\t' '$6 ~ /^reused: /' "$T/erel9/results.tsv" 2>/dev/null | wc -l | tr -d ' ')" = 2 ]; then
        vs_ctl_fired emu-identity-unchecked "a changed mame-wide binary is reused by the emulator runner with the comparison disabled"
    else vs_ctl_dead emu-identity-unchecked "the shadow emulator runner still refused: $(printf '%s' "$e9" | grep -E 'REFUSED|reused' | tr '\n' '|')"; rc=1; fi
fi

echo
if [ "$rc" = 0 ]; then echo "PASS: a release reuses the freeze's verdicts only on the freeze's identity, never a release-cadence gate, a VS_CADENCE reader or an emulator control"
else echo "FAIL: see above"; fi
exit $rc
