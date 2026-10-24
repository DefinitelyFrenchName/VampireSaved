#!/bin/sh
# test_controls_concurrent.sh — THE CONCURRENT-CONTROLS LIST STILL DESCRIBES THE GATES IT NAMES (#315, 14z-207). ci_portable: no ROM, ~2 s.
#
# WHAT: tools/controls_concurrent.py reads tests/controls_concurrent.txt, the gates whose must-fire controls
#   tests/run_all_static.sh --jobs N runs beside one another (#312), and names every row whose gate is not registered
#   (tests/ci_portable.txt, tests/ci_static.txt), declares fewer than two must-fire controls, or whose script's git blob
#   differs from the blob that was write-traced. Each named row must be re-traced or taken off the list (ruled
#   2026-10-24: "Census gate + re-trace at freeze (Recommended)").
# HOW: the census over the tree; then on a copy of the tree's registries, list and gate scripts, three perturbations of
#   the list's first row: its gate dropped from the registries, its script cut to one MUST-FIRE line, its script given
#   one more line. Each must be named with its own tag, and the unperturbed copy must read clean. Then the freeze
#   re-trace's scorer, tools/controls_overlap.py, on synthetic traces: distinct writes SAFE, a shared write, a write
#   a sibling reads and a write split by strace SHARED, a control's own mktemp path and a bytecode cache SAFE, a gate
#   whose every control SKIPped HOLLOW.
# EXPECTS: 0 rows named on the tree. A red names the gate and says "re-trace it or take it off the list" — the #315
#   shape: 8 of lane S's 98 traced gates had changed before #312 landed and would have kept running their controls
#   beside one another on a trace that no longer described them.
#
# MUST-FIRE: perturbed-copy: unregistered — the list's first gate dropped from both registries must be named UNREGISTERED and FAIL the gate (mode: the census reads that copy)
# MUST-FIRE: perturbed-copy: one-control — the list's first gate cut to a single MUST-FIRE line must be named FEWCONTROLS and FAIL the gate (mode: the census reads that copy)
# MUST-FIRE: perturbed-copy: changed-script — the list's first gate with one line appended to its script must be named STALE and FAIL the gate (mode: the census reads that copy)
set -u
REPO="$(cd "$(dirname "$0")/.." && pwd)"; cd "$REPO"
. "$REPO/tests/lib/controls.sh"; vs_ctl_mode "$0"
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT INT TERM
fail=0; ok() { echo "  ok    $*"; }; bad() { echo "  FAIL  $*"; fail=1; }
G1="$(awk -F'\t' '!/^#/ && NF {print $1; exit}' tests/controls_concurrent.txt)"
mkcopy() {  # mkcopy <dir> <perturbation|clean>: the registries, the list and the listed gates' scripts, one row perturbed
    mkdir -p "$1/tests"
    cp tests/ci_portable.txt tests/ci_static.txt tests/controls_concurrent.txt "$1/tests/"
    awk -F'\t' '!/^#/ && NF {print $1}' tests/controls_concurrent.txt | while read -r g; do cp "tests/$g.sh" "$1/tests/"; done
    case "$2" in
        unregistered) for r in ci_portable ci_static; do grep -vx "$G1" "tests/$r.txt" > "$1/tests/$r.txt"; done ;;
        one-control) awk '/^# MUST-FIRE: / { if (n++) next } { print }' "tests/$G1.sh" > "$1/tests/$G1.sh" ;;
        changed-script) echo "# one more line" >> "$1/tests/$G1.sh" ;;
    esac
}

echo "== 1. the tree"
ROOT="$REPO"
for c in unregistered one-control changed-script; do
    if vs_ctl_is "$c"; then mkcopy "$W/mode" "$c"; ROOT="$W/mode"; fi
done
out="$(python3 tools/controls_concurrent.py --root "$ROOT" 2>&1)"; rc=$?
echo "$out" | sed 's/^/  /' | tail -12
if [ "$ROOT" != "$REPO" ]; then
    [ "$rc" != 0 ] && { echo "FAIL: test_controls_concurrent (control mode: the perturbed row was named)"; exit 1; }
    echo "FAIL: test_controls_concurrent — the perturbed row was not named"; exit 1
fi
[ "$rc" = 0 ] && ok "every listed gate is registered, declares 2+ controls and is the script that was traced" \
    || bad "a listed gate must be re-traced or taken off the list (above)"
echo "$out" | tail -1 | grep -Eq '^[1-9][0-9]* listed gate' && ok "the list was read: $(echo "$out" | tail -1)" \
    || bad "the census read no listed gate: $(echo "$out" | tail -1)"

echo "== 2. known answers on a copy (the first row: $G1)"
mkcopy "$W/clean" clean
out="$(python3 tools/controls_concurrent.py --root "$W/clean" 2>&1)" && ok "the unperturbed copy reads clean" \
    || bad "the unperturbed copy was named: $(echo "$out" | head -1)"

echo "== 3. controls"
chk() {  # chk <control> <tag>: the copy with that perturbation names the first row with that tag
    mkcopy "$W/$1" "$1"
    out="$(python3 tools/controls_concurrent.py --root "$W/$1" 2>&1)"
    if echo "$out" | grep -q "^$2	$G1	"; then vs_ctl_fired "$1" "$(echo "$out" | grep -m1 "^$2	" | cut -c1-120)"
    else vs_ctl_dead "$1" "the $1 row was not named $2: $(echo "$out" | tail -1)"; fail=1; fi
}
chk unregistered UNREGISTERED
chk one-control FEWCONTROLS
chk changed-script STALE

echo "== 4. tools/controls_overlap.py's verdicts on synthetic traces (the freeze re-trace's scorer, ground truth)"
T="$W/tr"; mkdir -p "$T/st" "$T/out"; : > "$T/done.tsv"
st() {  # st <gate> <control> <strace line>...: one trace file, its done.tsv row, a PASS-less output
    g="$1"; c="$2"; shift 2; printf '%s\n' "$@" > "$T/st/$g.$c.st"; printf '%s\t%s\t1\t0\t/r\n' "$g" "$c" >> "$T/done.tsv"
    echo "FAIL: $g (control mode)" > "$T/out/$g.$c.out"
}
W1='1 openat(AT_FDCWD, "a", O_WRONLY|O_CREAT|O_TRUNC, 0666) = 3</r/w/a>'
W2='1 openat(AT_FDCWD, "b", O_WRONLY|O_CREAT|O_TRUNC, 0666) = 3</r/w/b>'
RA='1 openat(AT_FDCWD, "a", O_RDONLY) = 3</r/w/a>'
st g_safe c1 "$W1"; st g_safe c2 "$W2"
st g_shared c1 "$W1"; st g_shared c2 "$W1"
st g_wr c1 "$W1"; st g_wr c2 "$RA"
st g_tmp c1 '1 openat(AT_FDCWD, "x", O_WRONLY|O_CREAT, 0600) = 3</tmp/tmp.AbCdEf1234/x>' '1 openat(AT_FDCWD, "y", O_WRONLY|O_CREAT, 0600) = 4</r/tools/__pycache__/m.cpython-312.pyc>'
st g_tmp c2 '1 openat(AT_FDCWD, "x", O_WRONLY|O_CREAT, 0600) = 3</tmp/tmp.AbCdEf1234/x>' '1 openat(AT_FDCWD, "y", O_WRONLY|O_CREAT, 0600) = 4</r/tools/__pycache__/m.cpython-312.pyc>'
st g_split c1 '7 openat(AT_FDCWD, "a", O_WRONLY|O_CREAT <unfinished ...>' '7 <... openat resumed>) = 3</r/w/a>'; st g_split c2 "$W1"
st g_hollow c1 "$W1"; st g_hollow c2 "$W2"
for c in c1 c2; do echo "SKIP: no thing on this host" > "$T/out/g_hollow.$c.out"; done
out="$(python3 tools/controls_overlap.py "$T" 2>&1)"
for want in "g_safe SAFE" "g_shared SHARED" "g_wr SHARED" "g_tmp SAFE" "g_split SHARED" "g_hollow HOLLOW"; do
    set -- $want
    echo "$out" | grep -q "^== $1: .* -> $2\$" && ok "$1 reads $2" || bad "$1 did not read $2: $(echo "$out" | grep "^== $1:" | cut -c1-120)"
done

[ "$fail" = 0 ] && echo "PASS: test_controls_concurrent" || echo "FAIL: test_controls_concurrent"
exit "$fail"
