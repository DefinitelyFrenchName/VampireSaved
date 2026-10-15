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
#   only by the rules the control narrows: R6's directory template and N-A below the top level). Since #274 (14z-200)
#   a read of the session scratch the predictor's change set drops (N-D: build/agent<N>*/ and its siblings) is a MISS
#   in a gate that is not a whole-tree reader — g_tmpl reads build/agent7/x.txt, which its "build/$b" template names
#   but the change set never hands it — and is no miss in one that is (g_whole, `git ls-files`).
#   Since #283 (14z-202) the planted read is also written SPLIT, as strace writes a call another process interrupts
#   (`<unfinished ...>`, then `<... openat resumed>` after a line of another pid), and must score the same miss.
# EXPECTS: clean 0 misses and exit 0; planted exactly `MISS g_named docs/hidden.md` and exit 1; control `CONTROL FIRED`
#   with `MISS g_tmpl build/m1/out.txt`; the scratch traces exactly `MISS g_tmpl build/agent7/x.txt` and exit 1. A red is a scorer that cannot see a miss — the one property that makes a clean
#   trace (14z-190: 0 misses over 40,021 reads) evidence that a predictor change is safe.
#
# MUST-FIRE: perturbed-copy: planted-miss — the clean section scored on traces carrying an unnamed read (docs/hidden.md) must report the miss and FAIL the gate (mode: section 1 scores the planted traces)
# MUST-FIRE: shadow-tool: scratch-unscored — a copy of the tool whose score ignores the change set's drop (N-D) must count g_tmpl's read of build/agent7/x.txt as flagged (its template names it), and section 2b must FAIL (mode: section 2b scores with that copy)
# MUST-FIRE: shadow-tool: split-unread — a copy of the tool whose reads_of reads strace's lines without re-joining the split ones must miss nothing in the split traces, and section 2c must FAIL (mode: section 2c scores with that copy; #283, 14z-202)
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
printf 'g_named\ng_tmpl\ng_whole\n' > "$R/tests/ci_portable.txt"
printf '#!/bin/sh\ncat docs/named.md\n' > "$R/tests/g_named.sh"
printf '#!/bin/sh\nfor b in m1; do ls "build/$b"; done\n' > "$R/tests/g_tmpl.sh"
printf '#!/bin/sh\ngit ls-files > /dev/null\n' > "$R/tests/g_whole.sh"
mkdir -p "$R/build/agent7"; echo x > "$R/build/agent7/x.txt"
echo n > "$R/docs/named.md"; echo h > "$R/docs/hidden.md"; echo o > "$R/build/m1/out.txt"
( cd "$R" && git init -q && git add -A && git -c user.name=t -c user.email=t@t commit -qm base ) || { echo "FAIL: fixture repo"; exit 1; }
RR="$(cd "$R" && pwd -P)"
mk_traces() {   # mk_traces <dir> [planted] — strace-format traces of the two gates
    mkdir -p "$1/st"; printf 'g_named\ng_tmpl\ng_whole\n' > "$1/gates.txt"; echo fixture > "$1/head.txt"
    printf '1 openat(AT_FDCWD, "%s/docs/named.md", O_RDONLY) = 3\n' "$RR" > "$1/st/g_named.st"
    printf '1 openat(AT_FDCWD, "%s/build/m1/out.txt", O_RDONLY) = 3\n' "$RR" > "$1/st/g_tmpl.st"
    printf '1 openat(AT_FDCWD, "%s/docs/named.md", O_RDONLY) = 3\n' "$RR" > "$1/st/g_whole.st"
    if [ "${2:-}" = scratch ]; then   # the session scratch (N-D), read by a template gate and by a whole-tree reader
        printf '2 openat(AT_FDCWD, "%s/build/agent7/x.txt", O_RDONLY) = 4\n' "$RR" >> "$1/st/g_tmpl.st"
        printf '2 openat(AT_FDCWD, "%s/build/agent7/x.txt", O_RDONLY) = 4\n' "$RR" >> "$1/st/g_whole.st"
    fi
    [ "${2:-}" = planted ] && printf '2 openat(AT_FDCWD, "%s/docs/hidden.md", O_RDONLY) = 4\n' "$RR" >> "$1/st/g_named.st"
    if [ "${2:-}" = split ]; then   # #283: the planted read, split by strace around another process's line
        printf '2 openat(AT_FDCWD, "%s/docs/hidden.md", O_RDONLY|O_CLOEXEC <unfinished ...>\n' "$RR" >> "$1/st/g_named.st"
        printf '3 openat(AT_FDCWD, "%s/docs/named.md", O_RDONLY) = 5\n' "$RR" >> "$1/st/g_named.st"
        printf '2 <... openat resumed>)            = 4\n' >> "$1/st/g_named.st"
    fi
    return 0
}
mk_traces "$W/clean"; mk_traces "$W/planted" planted; mk_traces "$W/scratch" scratch; mk_traces "$W/split" split
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
split_unread() {   # the shadow: a copy of the tool whose reads_of does not re-join split lines (#283)
    python3 - "$TOOL" "$1" <<'PY'
import sys
s = open(sys.argv[1]).read()
a = "    for line in joined(open(st, errors=\"replace\")):   # SPLIT-PAIRED (#283)"
assert s.count(a) == 1, "the SPLIT-PAIRED line moved"
open(sys.argv[2], "w").write(s.replace(a, "    for line in open(st, errors=\"replace\"):   # CONTROL split-unread"))
PY
}
scratch_unscored() {   # the shadow: a copy of the tool whose score ignores the change set's drop (N-D)
    python3 - "$TOOL" "$1" <<'PY'
import sys
s = open(sys.argv[1]).read()
a = "    dropped = getattr(sc, \"drop_scratch\", lambda c: False)"
assert s.count(a) == 1, "the score's drop line moved"
open(sys.argv[2], "w").write(s.replace(a, "    dropped = lambda c: False   # CONTROL scratch-unscored"))
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

echo "== 2b. the session scratch (N-D, #274): a dropped read is a miss, except in a whole-tree reader"
ST="$TOOL"; if vs_ctl_is scratch-unscored; then scratch_unscored "$W/tool_su.py"; ST="$W/tool_su.py"; fi
out="$(cd "$R/tools" && python3 "$ST" score --root "$RR" --traces "$W/scratch" --jobs 2 2>&1)"; rc=$?
if [ "$rc" = 1 ] && [ "$(echo "$out" | grep -c '^MISS	')" = 1 ] && echo "$out" | grep -q '^MISS	g_tmpl	build/agent7/x.txt$'; then
    ok "MISS g_tmpl build/agent7/x.txt (its template names it, the change set drops it); g_whole's read is no miss; exit 1"
else bad "the scratch traces: exit $rc, $(echo "$out" | grep '^MISS' | tr '\n' ' ')"; fi

echo "== 2c. a read strace SPLIT around another process's line is scored (#283)"
SP="$TOOL"; if vs_ctl_is split-unread; then split_unread "$W/tool_sp.py"; SP="$W/tool_sp.py"; fi
out="$(cd "$R/tools" && python3 "$SP" score --root "$RR" --traces "$W/split" --jobs 2 2>&1)"; rc=$?
if [ "$rc" = 1 ] && [ "$(echo "$out" | grep -c '^MISS	')" = 1 ] && echo "$out" | grep -q '^MISS	g_named	docs/hidden.md$'; then
    ok "MISS g_named docs/hidden.md from the split lines, exit 1"
else bad "the split read: exit $rc, $(echo "$out" | grep '^MISS' | tr '\n' ' ')"; fi

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

if vs_ctl_is planted-miss || vs_ctl_is no-narrowing || vs_ctl_is scratch-unscored || vs_ctl_is split-unread; then
    [ "$fail" = 1 ] && { echo "FAIL: test_trace_static_reads (control mode: caught as it must be)"; exit 1; }
    # not caught: the gate's own verdict is PASS and the mode exits 0, which the runner reads as LIES (the control tests
    # nothing). Until 14z-200 this line exited 1, so a mode could never read LIES (rule-checker run 2026-10-14-1048 Q4).
    echo "PASS: test_trace_static_reads — under CONTROL=$VS_CTL nothing was caught: the control tests nothing"; exit 0
fi
echo "== 5. controls"
out="$(python3 "$TOOL" score --root "$RR" --traces "$W/planted" --jobs 2 2>&1)"
if echo "$out" | grep -q '^MISS	g_named	docs/hidden.md$'; then vs_ctl_fired planted-miss "the planted traces score MISS g_named docs/hidden.md"
else vs_ctl_dead planted-miss "the planted read was not reported"; fail=1; fi
scratch_unscored "$W/tool_su.py"
out="$(cd "$R/tools" && python3 "$W/tool_su.py" score --root "$RR" --traces "$W/scratch" --jobs 2 2>&1)"
if ! echo "$out" | grep -q '^MISS	g_tmpl	build/agent7/x.txt$'; then vs_ctl_fired scratch-unscored "a score that ignores the drop counts g_tmpl's scratch read as flagged — section 2b is what catches it"
else vs_ctl_dead scratch-unscored "the copy ignoring the drop still reported the miss"; fail=1; fi
split_unread "$W/tool_sp.py"
out="$(cd "$R/tools" && python3 "$W/tool_sp.py" score --root "$RR" --traces "$W/split" --jobs 2 2>&1)"
if ! echo "$out" | grep -q '^MISS	g_named	docs/hidden.md$'; then vs_ctl_fired split-unread "a scorer reading strace's lines raw misses the split read — section 2c is what catches it"
else vs_ctl_dead split-unread "the copy without re-joining still reported the split read"; fail=1; fi
no_narrowing "$W/tool_nn.py"
out="$(cd "$R/tools" && python3 "$W/tool_nn.py" control --root "$RR" --traces "$W/clean" --jobs 2 2>&1)"
if echo "$out" | grep -q '^CONTROL DEAD: over-narrowed'; then vs_ctl_fired no-narrowing "a control that narrows nothing reports itself dead"
else vs_ctl_dead no-narrowing "a control narrowing nothing still claimed to fire"; fail=1; fi

[ "$fail" = 0 ] && echo "PASS: test_trace_static_reads" || echo "FAIL: test_trace_static_reads"
exit "$fail"
