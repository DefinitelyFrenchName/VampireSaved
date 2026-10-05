#!/bin/sh
# test_trace_static_reads.sh — #188's TRACED TEST, PROMOTED: the scorer finds a read the predictor does not flag, and
# its over-narrowed control must miss (GitHub #225, 14z-191). ci_portable: no ROM, no emulator, no strace, ~3 s.
#
# WHAT: tools/trace_static_reads.py's score marks every traced read its gate's predictor flags and reports, as a MISS,
#   one it does not; its control scores the same traces with this tree's predictor OVER-NARROWED and must miss; and
#   its trace step refuses to run without strace.
# HOW: a synthetic git repository carrying the REAL tools/static_confirm.py and tools/battery_reach.py and two gates —
#   g_named (cat docs/named.md) and g_tmpl (a build path named only through the template "build/$b") — with traces in
#   strace's own line format: g_named opening docs/named.md, g_tmpl opening build/m1/out.txt. Scored as written (no
#   miss), with an unnamed read of docs/hidden.md planted (one miss), and through the control (g_tmpl's read is caught
#   only by the rules the control narrows: R6's directory template and N-A below the top level).
# EXPECTS: clean 0 misses and exit 0; planted exactly `MISS g_named docs/hidden.md` and exit 1; control `CONTROL FIRED`
#   with `MISS g_tmpl build/m1/out.txt`. A red is a scorer that cannot see a miss — the one property that makes a clean
#   trace (14z-190: 0 misses over 40,021 reads) evidence that a predictor change is safe.
#
# MUST-FIRE: perturbed-copy: planted-miss — the clean section scored on traces carrying an unnamed read (docs/hidden.md) must report the miss and FAIL the gate (mode: section 1 scores the planted traces)
# MUST-FIRE: shadow-tool: no-narrowing — a copy of the tool whose control narrows nothing must not fire, and the gate must FAIL (mode: section 3 runs that copy)
#
# The real-data run lives on Linux: `python3 tools/trace_static_reads.py all --out DIR` on PILOT (strace), whose
# figures a predictor change quotes. This gate proves the scorer and its control, never a predictor.
set -u
REPO="$(cd "$(dirname "$0")/.." && pwd)"; cd "$REPO"
. "$REPO/tests/lib/controls.sh"; vs_ctl_mode "$0"
fail=0; ok() { echo "  ok    $*"; }; bad() { echo "  FAIL  $*"; fail=1; }
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT INT TERM

R="$W/r"; mkdir -p "$R/tools" "$R/tests" "$R/docs" "$R/build/m1"
cp tools/static_confirm.py tools/battery_reach.py tools/trace_static_reads.py "$R/tools/"
printf 'g_named\ng_tmpl\n' > "$R/tests/ci_portable.txt"
printf '#!/bin/sh\ncat docs/named.md\n' > "$R/tests/g_named.sh"
printf '#!/bin/sh\nfor b in m1; do ls "build/$b"; done\n' > "$R/tests/g_tmpl.sh"
echo n > "$R/docs/named.md"; echo h > "$R/docs/hidden.md"; echo o > "$R/build/m1/out.txt"
( cd "$R" && git init -q && git add -A && git -c user.name=t -c user.email=t@t commit -qm base ) || { echo "FAIL: fixture repo"; exit 1; }
RR="$(cd "$R" && pwd -P)"
mk_traces() {   # mk_traces <dir> [planted] — strace-format traces of the two gates
    mkdir -p "$1/st"; printf 'g_named\ng_tmpl\n' > "$1/gates.txt"; echo fixture > "$1/head.txt"
    printf '1 openat(AT_FDCWD, "%s/docs/named.md", O_RDONLY) = 3\n' "$RR" > "$1/st/g_named.st"
    printf '1 openat(AT_FDCWD, "%s/build/m1/out.txt", O_RDONLY) = 3\n' "$RR" > "$1/st/g_tmpl.st"
    [ "${2:-}" = planted ] && printf '2 openat(AT_FDCWD, "%s/docs/hidden.md", O_RDONLY) = 4\n' "$RR" >> "$1/st/g_named.st"
    return 0
}
mk_traces "$W/clean"; mk_traces "$W/planted" planted
TOOL="$R/tools/trace_static_reads.py"
no_narrowing() {   # the shadow: a copy of the tool whose control perturbs nothing
    python3 - "$TOOL" "$1" <<'PY'
import sys
s = open(sys.argv[1]).read()
a = "    for a, b in OVER_NARROW:\n"
assert s.count(a) == 1, "the control's loop moved"
open(sys.argv[2], "w").write(s.replace(a, "    for a, b in ():   # CONTROL no-narrowing\n"))
PY
}

echo "== 1. the clean traces: no miss"
T1="$W/clean"; vs_ctl_is planted-miss && T1="$W/planted"
out="$(python3 "$TOOL" score --root "$RR" --traces "$T1" --jobs 2 2>&1)"; rc=$?
echo "$out" | sed 's/^/  /'
if [ "$rc" = 0 ] && echo "$out" | grep -q '^MISSES 0 in 0 gates$'; then ok "every traced read flagged"; else bad "the clean traces scored a miss or failed (exit $rc)"; fi

echo "== 2. a planted unnamed read: exactly one miss"
out="$(python3 "$TOOL" score --root "$RR" --traces "$W/planted" --jobs 2 2>&1)"; rc=$?
if [ "$rc" = 1 ] && [ "$(echo "$out" | grep -c '^MISS	')" = 1 ] && echo "$out" | grep -q '^MISS	g_named	docs/hidden.md$'; then
    ok "MISS g_named docs/hidden.md, exit 1"
else bad "the planted read: exit $rc, $(echo "$out" | grep '^MISS' | tr '\n' ' ')"; fi

echo "== 3. the over-narrowed control misses the build-template read"
CT="$TOOL"; if vs_ctl_is no-narrowing; then no_narrowing "$W/tool_nn.py"; CT="$W/tool_nn.py"; fi
out="$(cd "$R/tools" && python3 "$CT" control --root "$RR" --traces "$W/clean" --jobs 2 2>&1)"; rc=$?
echo "$out" | grep -v '^==\|^traces' | sed 's/^/  /'
if [ "$rc" = 0 ] && echo "$out" | grep -q '^CONTROL FIRED: over-narrowed' && echo "$out" | grep -q '^MISS	g_tmpl	build/m1/out.txt$'; then
    ok "the control misses g_tmpl's build/m1/out.txt"
else bad "the control did not miss (exit $rc)"; fi

echo "== 4. the trace step refuses without strace"
if command -v strace >/dev/null 2>&1; then ok "strace present on this host: the refusal is not exercised here"
else
    out="$(python3 "$TOOL" trace --root "$RR" --out "$W/tr" 2>&1)"; rc=$?
    [ "$rc" != 0 ] && echo "$out" | grep -q 'REFUSED: strace not found' && ok "REFUSED without strace" || bad "trace without strace: exit $rc"
fi

if vs_ctl_is planted-miss || vs_ctl_is no-narrowing; then
    [ "$fail" = 1 ] && { echo "FAIL: test_trace_static_reads (control mode: caught as it must be)"; exit 1; }
    echo "FAIL: test_trace_static_reads — the control mode passed"; exit 1
fi
echo "== 5. controls"
out="$(python3 "$TOOL" score --root "$RR" --traces "$W/planted" --jobs 2 2>&1)"
if echo "$out" | grep -q '^MISS	g_named	docs/hidden.md$'; then vs_ctl_fired planted-miss "the planted traces score MISS g_named docs/hidden.md"
else vs_ctl_dead planted-miss "the planted read was not reported"; fail=1; fi
no_narrowing "$W/tool_nn.py"
out="$(cd "$R/tools" && python3 "$W/tool_nn.py" control --root "$RR" --traces "$W/clean" --jobs 2 2>&1)"
if echo "$out" | grep -q '^CONTROL DEAD: over-narrowed'; then vs_ctl_fired no-narrowing "a control that narrows nothing reports itself dead"
else vs_ctl_dead no-narrowing "a control narrowing nothing still claimed to fire"; fail=1; fi

[ "$fail" = 0 ] && echo "PASS: test_trace_static_reads" || echo "FAIL: test_trace_static_reads"
exit "$fail"
