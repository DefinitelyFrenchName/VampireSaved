#!/bin/sh
# test_static_runner.sh — ground truth for tests/run_all_static.sh
# (14z-94, GitHub #30). ROM-free, ~3 s.
#
# WHY A GATE FOR THE RUNNER. CLAUDE.md §4: "Verdict logic is itself tested. A
# test's classification code must be validated against known ground-truth
# scenarios before its verdicts are trusted — SMS shipped a wrong conclusion
# from a verdict bug, not a game bug."
#
# That applies with extra force here, because this runner's whole purpose is
# to be the thing nobody has to remember. If its PASS/SKIP/FAIL classifier is
# wrong, it converts "nobody runs the gates" into "everybody runs the gates
# and believes a wrong answer", which is strictly worse than the problem #30
# describes.
#
# THE ONE THAT MATTERS IS SKIP (GitHub #29). A gate whose inputs are missing
# prints `SKIP: ...` and exits 0. If the runner reads exit status alone, a
# fresh checkout reports GREEN while asserting nothing at all.
#
# Method: a synthetic repo containing stub gates with known verdicts, run
# through the REAL runner via its registry files — never a copy of its logic,
# so the classifier under test is the shipped one.
set -eu
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
rc=0
fail() { echo "  FAIL: $*"; rc=1; }

RUNNER="$REPO/tests/run_all_static.sh"
T="$(mktemp -d)"; trap 'rm -rf "$T"' EXIT INT TERM
FR="$T/fakerepo"
mkdir -p "$FR/tests"
ln -s "$RUNNER" "$FR/tests/run_all_static.sh"

mk() {  # mk <name> <exit> <output...>
    n="$1"; st="$2"; shift 2
    { echo "#!/bin/sh"; for l in "$@"; do echo "echo '$l'"; done; echo "exit $st"; } \
        > "$FR/tests/$n.sh"
    chmod +x "$FR/tests/$n.sh"
}

mk g_pass 0 "all good" "PASS: fine"
mk g_fail 1 "something broke" "FAIL: nope"
mk g_skip 0 "SKIP: no build at build/nope"
mk g_skip_indent 0 "  SKIP: indented skip marker"
# The nasty one: exits 0, and the word SKIP appears only in PROSE, not as a
# marker. It must be read as PASS, or every gate that documents the skip
# convention in its output would be miscounted.
mk g_prose 0 "checked 3 things, none had to be skipped" "PASS: prose only"

printf 'g_pass\ng_fail\ng_skip\ng_skip_indent\ng_prose\n' > "$FR/tests/ci_portable.txt"
: > "$FR/tests/ci_static.txt"

out="$(cd "$FR" && sh tests/run_all_static.sh --tier portable 2>&1)" && st=0 || st=$?

echo "== 1. each verdict is classified correctly =="
check() {  # check <name> <expected-verdict>
    if printf '%s' "$out" | grep -qE "^  $1 +$2( |$)"; then
        echo "  ok: $1 -> $2"
    else
        fail "$1 was not classified $2:"
        printf '%s' "$out" | grep -E "^  $1" | sed 's/^/        /'
    fi
}
check g_pass PASS
check g_fail FAIL
check g_skip SKIP
check g_skip_indent SKIP
check g_prose PASS

echo "== 2. the TALLY matches (the number a human reads) =="
if printf '%s' "$out" | grep -q "PASS 2 .*SKIP 2 .*FAIL 1"; then
    echo "  ok: PASS 2  SKIP 2  FAIL 1"
else
    fail "wrong tally: $(printf '%s' "$out" | grep -E '^PASS ' || echo '(none printed)')"
fi

echo "== 3. a FAIL makes the runner exit nonzero =="
[ "$st" != 0 ] && echo "  ok: exit $st" \
    || fail "the runner exited 0 with a failing gate — rule 6 cannot operate"

echo "== 4. THE #29 CONTROL — an all-SKIP run is not GREEN under --strict =="
printf 'g_skip\ng_skip_indent\n' > "$FR/tests/ci_portable.txt"
o2="$(cd "$FR" && sh tests/run_all_static.sh --tier portable 2>&1)" && s2=0 || s2=$?
if [ "$s2" = 0 ]; then
    echo "  ok: without --strict an all-SKIP run exits 0 (skips are legitimate"
    echo "      on a fresh checkout) — but it must SAY so:"
    printf '%s' "$o2" | grep -qE "SKIP 2" \
        && echo "      ok: the tally reports SKIP 2, so it cannot read as 2 passes" \
        || fail "the tally hides the skips"
else
    fail "a plain all-SKIP run failed; skips are legitimate without --strict"
fi
o3="$(cd "$FR" && sh tests/run_all_static.sh --tier portable --strict 2>&1)" && s3=0 || s3=$?
if [ "$s3" != 0 ]; then
    echo "  ok: --strict turns SKIP into failure (exit $s3)"
else
    fail "--strict accepted an all-SKIP run — the mode does nothing, and a"
    fail "      checkout with no build dirs would still report itself green"
fi

echo "== 5. a registered-but-missing gate is MISSING, not silently dropped =="
printf 'g_pass\nno_such_gate\n' > "$FR/tests/ci_portable.txt"
o4="$(cd "$FR" && sh tests/run_all_static.sh --tier portable 2>&1)" && s4=0 || s4=$?
if printf '%s' "$o4" | grep -q "MISSING" && [ "$s4" != 0 ]; then
    echo "  ok: reported MISSING and exited nonzero"
else
    fail "a registered gate that does not exist was ignored — a typo in the"
    fail "      registry would silently shrink the suite"
fi

echo "== 6. the anti-orphan check finds an unregistered emulator-free gate =="
printf 'g_pass\n' > "$FR/tests/ci_portable.txt"
mk g_orphan 0 "PASS: nobody registered me"
o5="$(cd "$FR" && sh tests/run_all_static.sh --tier portable 2>&1)"
if printf '%s' "$o5" | grep -q "g_orphan"; then
    echo "  ok: the unregistered gate is named"
else
    fail "an unregistered emulator-free gate was NOT reported — this check is"
    fail "      the whole anti-orphan mechanism (#30)"
fi
# ...and a gate that DOES use an emulator must not be nagged about.
mk g_emu 0 "PASS: I boot mame"
printf '#!/bin/sh\nMAME_BIN=x tools/run_mame.sh vsavj\n' > "$FR/tests/g_emu.sh"
chmod +x "$FR/tests/g_emu.sh"
o6="$(cd "$FR" && sh tests/run_all_static.sh --tier portable 2>&1)"
if printf '%s' "$o6" | grep -q "g_emu"; then
    fail "an EMULATOR gate was reported as an unregistered static gate — the"
    fail "      check would nag about every soak in the repo and be ignored"
else
    echo "  ok: an emulator gate is correctly left out of the nag list"
fi

echo "== 7. the real registries parse, and name real files =="
bad=0
for f in tests/ci_portable.txt tests/ci_static.txt; do
    [ -f "$f" ] || { fail "$f is missing"; bad=1; continue; }
    n=0
    while read -r g; do
        case "$g" in ""|\#*) continue;; esac
        n=$((n + 1))
        [ -x "tests/$g.sh" ] || { fail "$f names $g, which is not executable"; bad=1; }
    done < "$f"
    echo "  ok: $f — $n entries, all present"
done
[ "$bad" = 0 ] || rc=1

echo
[ "$rc" = 0 ] && echo "PASS: the runner's verdicts mean what they say." \
             || echo "FAIL: see above."
exit $rc
