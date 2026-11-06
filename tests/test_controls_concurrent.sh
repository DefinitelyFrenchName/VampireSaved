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
#   whose every control SKIPped HOLLOW. ONLY AN HONOURED RUN CERTIFIES (#349, 14z-218): the scorer classifies every run
#   with tests/lib/classify.sh, so a gate whose controls were all REFUSED (ERIS, 14z-216: test_readme_recording, exit 3,
#   0 s, read SAFE), one with an HONOURED and a TIMEOUT run, and one with a run that left no output read HOLLOW, while
#   the all-HONOURED clean traces above still read SAFE.
#   Section 3b (#321, 14z-210) runs the same census over the EMULATOR list, tests/controls_concurrent_emu.txt
#   (tools/controls_concurrent.py --emulator: a row's gate must have an fbneo or mame row in tests/ci_emulator.tsv).
# EXPECTS: 0 rows named on the tree. A red names the gate and says "re-trace it or take it off the list" — the #315
#   shape: 8 of lane S's 98 traced gates had changed before #312 landed and would have kept running their controls
#   beside one another on a trace that no longer described them.
#
# MUST-FIRE: perturbed-copy: unregistered — the list's first gate dropped from both registries must be named UNREGISTERED and FAIL the gate (mode: the census reads that copy)
# MUST-FIRE: perturbed-copy: one-control — the list's first gate cut to a single MUST-FIRE line must be named FEWCONTROLS and FAIL the gate (mode: the census reads that copy)
# MUST-FIRE: perturbed-copy: changed-script — the list's first gate with one line appended to its script must be named STALE and FAIL the gate (mode: the census reads that copy)
# MUST-FIRE: shadow-tool: refused-certified — tools/controls_overlap.py with its HONOURED-only rule (#349) cut back to the pre-#349 SKIP-only one must read g_refused (every control REFUSED) SAFE, and FAIL the gate (mode: section 4 scores the synthetic traces with that copy)
set -u
REPO="$(cd "$(dirname "$0")/.." && pwd)"; cd "$REPO"
. "$REPO/tests/lib/controls.sh"; vs_ctl_mode "$0"
W="$(mktemp -d)" || { echo "FAIL: test_controls_concurrent — mktemp -d failed (W)"; exit 2; }; trap 'rm -rf "$W"' EXIT; trap 'exit 130' INT; trap 'exit 143' TERM
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
if [ "$ROOT" != "$REPO" ]; then   # the mode's OWN finding: its tag naming the perturbed row, never any non-zero exit (#310, 14z-218)
    case "$VS_CTL" in unregistered) tag=UNREGISTERED ;; one-control) tag=FEWCONTROLS ;; *) tag=STALE ;; esac
    if echo "$out" | grep >/dev/null "^$tag	$G1	"; then echo "FAIL: test_controls_concurrent (control mode: the perturbed row was named $tag)"; exit 1; fi
    if [ "$rc" != 0 ]; then printf '%s\n' "$out" > "$W/mode.out"; vs_ctl_show_err "$W/mode.out" || :
        echo "NOT JUDGED: $VS_CTL — the list check failed (exit $rc) without naming $G1 $tag"; echo "FAIL: test_controls_concurrent"; exit 1; fi
    vs_ctl_left_green "$VS_CTL" "FAIL: test_controls_concurrent — the perturbed row was not named"
fi
[ "$rc" = 0 ] && ok "every listed gate is registered, declares 2+ controls and is the script that was traced" \
    || { bad "a listed gate must be re-traced or taken off the list (above)"; printf '%s\n' "$out" > "$W/s1.out"; vs_ctl_show_err "$W/s1.out" || :; }
echo "$out" | tail -1 | grep -Eq '^[1-9][0-9]* listed gate' && ok "the list was read: $(echo "$out" | tail -1)" \
    || bad "the census read no listed gate: $(echo "$out" | tail -1)"

echo "== 2. known answers on a copy (the first row: $G1)"
mkcopy "$W/clean" clean
out="$(python3 tools/controls_concurrent.py --root "$W/clean" 2>&1)" && ok "the unperturbed copy reads clean" \
    || { bad "the unperturbed copy was named: $(echo "$out" | head -1)"; printf '%s\n' "$out" > "$W/s2.out"; vs_ctl_show_err "$W/s2.out" || :; }

echo "== 3. controls"
chk() {  # chk <control> <tag>: the copy with that perturbation names the first row with that tag
    mkcopy "$W/$1" "$1"
    out="$(python3 tools/controls_concurrent.py --root "$W/$1" 2>&1)"
    if echo "$out" | grep >/dev/null "^$2	$G1	"; then vs_ctl_fired "$1" "$(echo "$out" | grep -m1 "^$2	" | cut -c1-120)"
    else printf '%s\n' "$out" > "$W/chk_$1.out"; vs_ctl_show_err "$W/chk_$1.out" || :   # a crash is re-printed (#310, 14z-218)
        vs_ctl_dead "$1" "the $1 row was not named $2: $(echo "$out" | tail -1)"; fail=1; fi
}
chk unregistered UNREGISTERED
chk one-control FEWCONTROLS
chk changed-script STALE

echo "== 3b. the EMULATOR list (#321, 14z-210): tests/controls_concurrent_emu.txt, read by tests/run_all_emulator.sh"
out="$(python3 tools/controls_concurrent.py --root "$REPO" --emulator 2>&1)"; erc=$?
echo "$out" | sed 's/^/  /' | tail -8
[ "$erc" = 0 ] && ok "every listed emulator gate has an fbneo/mame row, declares 2+ controls and is the script that was traced" \
    || { bad "a listed emulator gate must be re-traced or taken off tests/controls_concurrent_emu.txt (above)"; printf '%s\n' "$out" > "$W/s3b.out"; vs_ctl_show_err "$W/s3b.out" || :; }
echo "$out" | tail -1 | grep -Eq '^[1-9][0-9]* listed gate' && ok "the emulator list was read: $(echo "$out" | tail -1)" \
    || bad "the census read no listed emulator gate: $(echo "$out" | tail -1)"

echo "== 4. tools/controls_overlap.py's verdicts on synthetic traces (the freeze re-trace's scorer, ground truth)"
T="$W/tr"; mkdir -p "$T/st" "$T/out"; : > "$T/done.tsv"; EXIT=1
st() {  # st <gate> <control> <strace line>...: one trace file, its done.tsv row (exit $EXIT), a FAIL output (HONOURED)
    g="$1"; c="$2"; shift 2; printf '%s\n' "$@" > "$T/st/$g.$c.st"; printf '%s\t%s\t%s\t0\t/r\n' "$g" "$c" "$EXIT" >> "$T/done.tsv"
    echo "FAIL: $g (control mode)" > "$T/out/$g.$c.out"
}
# THE SCORER UNDER TEST (#349): the tracked tool, or under CONTROL=refused-certified its shadow copy with the HONOURED-only
# rule cut back to the pre-#349 one (only a SKIP-shaped run, LIES or UNJUDGED, leaves a gate uncertified)
OVL=tools/controls_overlap.py; SHADOW="$W/shadow/controls_overlap.py"; mkdir -p "$W/shadow"
sed 's/if klass\[g\]\[c\]\[0\] != "HONOURED"\]   # HONOURED-ONLY (#349)/if klass[g][c][0] in ("LIES", "UNJUDGED")]/' \
    tools/controls_overlap.py > "$SHADOW"
if cmp -s tools/controls_overlap.py "$SHADOW"; then
    echo "NOT JUDGED: the refused-certified shadow changed nothing — the HONOURED-ONLY (#349) line was not found"; bad "the shadow copy is the tool"
fi
vs_ctl_is refused-certified && OVL="$SHADOW"
score() { python3 "$1" "$T" --classify tests/lib/classify.sh > "$W/ovl.$2.out" 2>&1; }
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
# RELATIVE rename targets (#321, 14z-210): placed by renameat's dirfd, else by the pid's last AT_FDCWD; never placed = shared
st g_relsafe c1 '4 renameat2(AT_FDCWD</tmp/tmp.AbCdEf1x>, "z.tmp", AT_FDCWD</tmp/tmp.AbCdEf1x>, "vsavjw.zip", RENAME_NOREPLACE) = 0'
st g_relsafe c2 '5 openat(AT_FDCWD</tmp/tmp.GhIjKl2y>, "q", O_RDONLY) = 3</tmp/tmp.GhIjKl2y/q>' '5 rename("z.tmp", "vsavjw.zip") = 0'
st g_relshared c1 '4 renameat2(AT_FDCWD</r/w>, "z.tmp", AT_FDCWD</r/w>, "vsavjw.zip", RENAME_NOREPLACE) = 0'
st g_relshared c2 '5 openat(AT_FDCWD</r/w>, "q", O_RDONLY) = 3</r/w/q>' '5 rename("z.tmp", "vsavjw.zip") = 0'
st g_relunknown c1 '6 rename("z.tmp", "vsavjw.zip") = 0'; st g_relunknown c2 '7 rename("z.tmp", "vsavjw.zip") = 0'
# ONLY AN HONOURED RUN CERTIFIES (#349): every control REFUSED (exit 3, the ERIS shape); one HONOURED beside one killed by
# the timeout wrapper; one HONOURED beside one whose output file is missing (UNRECORDED). Each wrote nothing shared.
EXIT=3; st g_refused c1 "$W1"; st g_refused c2 "$W2"; EXIT=1
for c in c1 c2; do printf 'CONTROL MODE: %s\nREFUSED: CONTROL=%s — no release MAME at release/x for this host\n' "$c" "$c" > "$T/out/g_refused.$c.out"; done
st g_partial c1 "$W1"; EXIT=124; st g_partial c2 "$W2"; EXIT=1
st g_noout c1 "$W1"; st g_noout c2 "$W2"; rm -f "$T/out/g_noout.c2.out"
score "$OVL" main; out="$(cat "$W/ovl.main.out")"
vs_ctl_show_err "$W/ovl.main.out" - || bad "the scorer did not run to a verdict ($OVL)"
for want in "g_safe SAFE" "g_shared SHARED" "g_wr SHARED" "g_tmp SAFE" "g_split SHARED" "g_hollow HOLLOW" \
            "g_relsafe SAFE" "g_relshared SHARED" "g_relunknown SHARED" "g_refused HOLLOW" "g_partial HOLLOW" "g_noout HOLLOW"; do
    set -- $want
    echo "$out" | grep >/dev/null "^== $1: .* -> $2\$" && ok "$1 reads $2" || bad "$1 did not read $2: $(echo "$out" | grep "^== $1:" | cut -c1-120)"
done
echo "$out" | grep >/dev/null '^   (not HONOURED) c1 REFUSED: ' && ok "g_refused's runs are named REFUSED (tests/lib/classify.sh's verdict)" \
    || bad "the scorer did not name g_refused's runs REFUSED"
# the in-gate twin of CONTROL=refused-certified: the shadow must read the all-REFUSED gate SAFE (a positive line first)
score "$SHADOW" shadow
if grep >/dev/null '^== g_refused: .* -> SAFE$' "$W/ovl.shadow.out" && grep >/dev/null '^== g_hollow: .* -> HOLLOW$' "$W/ovl.shadow.out"; then
    vs_ctl_fired refused-certified "the pre-#349 rule reads $(grep -m1 '^== g_refused: ' "$W/ovl.shadow.out" | sed 's/^== //; s/:.* -> / -> /') (SKIP still HOLLOW)"
else
    vs_ctl_show_err "$W/ovl.shadow.out" - "$SHADOW"
    vs_ctl_dead refused-certified "the shadow did not read g_refused SAFE: $(grep '^== g_refused: ' "$W/ovl.shadow.out" | cut -c1-120)"; fail=1
fi

vs_ctl_is refused-certified && [ "$fail" = 0 ] && vs_ctl_left_green refused-certified "FAIL: test_controls_concurrent"
[ "$fail" = 0 ] && echo "PASS: test_controls_concurrent" || echo "FAIL: test_controls_concurrent"
exit "$fail"
