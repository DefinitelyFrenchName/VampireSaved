#!/bin/sh
# test_controls_concurrent.sh — THE WRITE-TRACE SCORER'S GROUND TRUTH (#315, 14z-207; #349, 14z-218). ci_portable: no ROM, ~2 s.
#
# WHAT: tools/controls_overlap.py, the scorer of a write trace of control modes (tools/trace_controls.sh), reads each
#   synthetic trace with the verdict its shape demands. UNTIL #370 (14z-225) this gate also held the CONCURRENT-CONTROLS
#   LISTS (tests/controls_concurrent.txt, tests/controls_concurrent_emu.txt, tools/controls_concurrent.py, ruled
#   2026-10-24 "Census gate + re-trace at freeze (Recommended)"); #370 replaced the lists with each gate's `# SHARES:`
#   line (tests/test_shares.sh is their census), and the scorer stays for the trace audit that replaces the freeze
#   re-trace (#370 design item 4).
# HOW: the scorer on synthetic traces: distinct writes SAFE, a shared write, a write a sibling reads and a write split by
#   strace SHARED, a control's own mktemp path and a bytecode cache SAFE, a gate whose every control SKIPped HOLLOW. ONLY
#   AN HONOURED RUN CERTIFIES (#349, 14z-218): the scorer classifies every run with tests/lib/classify.sh, so a gate
#   whose controls were all REFUSED (ERIS, 14z-216: test_readme_recording, exit 3, 0 s, read SAFE), one with an HONOURED
#   and a TIMEOUT run, and one with a run that left no output read HOLLOW, while the all-HONOURED clean traces read SAFE.
# EXPECTS: every synthetic trace its verdict.
#
# MUST-FIRE: shadow-tool: refused-certified — tools/controls_overlap.py with its HONOURED-only rule (#349) cut back to the pre-#349 SKIP-only one must read g_refused (every control REFUSED) SAFE, and FAIL the gate (mode: section 4 scores the synthetic traces with that copy)
# SHARES: none — one control mode since #370 cut the list census (14z-225), so no two of its own jobs to keep apart, and its plain run always pooled
set -u
REPO="$(cd "$(dirname "$0")/.." && pwd)"; cd "$REPO"
. "$REPO/tests/lib/controls.sh"; vs_ctl_mode "$0"
W="$(mktemp -d)" || { echo "FAIL: test_controls_concurrent — mktemp -d failed (W)"; exit 2; }; trap 'rm -rf "$W"' EXIT; trap 'exit 130' INT; trap 'exit 143' TERM
fail=0; ok() { echo "  ok    $*"; }; bad() { echo "  FAIL  $*"; fail=1; }
echo "== 1. tools/controls_overlap.py's verdicts on synthetic traces (the freeze re-trace's scorer, ground truth)"
T="$W/tr"; mkdir -p "$T/st" "$T/out"; : > "$T/done.tsv"; EXIT=1
st() {  # st <gate> <control> <strace line>...: one trace file, its done.tsv row (exit $EXIT), a FAIL output (HONOURED)
    g="$1"; c="$2"; shift 2; printf '%s\n' "$@" > "$T/st/$g.$c.st"; printf '%s\t%s\t%s\t0\t/r\n' "$g" "$c" "$EXIT" >> "$T/done.tsv"
    # #369 (14z-224): an honoured run carries its own check's evidence, the CONTROL CAUGHT line vs_ctl_caught prints; the
    # scorer classifies through tests/lib/classify.sh, which reads a FAIL without one (the gate not on the debt list) UNJUDGED
    printf 'FAIL: %s (control mode)\nCONTROL CAUGHT: %s — FAIL: %s (control mode)\n' "$g" "$c" "$g" > "$T/out/$g.$c.out"
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
