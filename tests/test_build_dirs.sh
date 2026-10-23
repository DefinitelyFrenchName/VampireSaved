#!/bin/sh
# test_build_dirs.sh — every build/ top-level directory is classed in ONE list, and the planner's two scratch forms
# generated from it agree (`tools/build_dirs.py`, tests/expected/build_dirs.tsv; #304, 14z-207).
#
# WHAT: tools/build_dirs.py's census fails on each of its conditions and only then: a build/<top> named by a tracked
#   program under tools/ or tests/ that no row classes; a directory under build/ in this tree that no row classes; a
#   name a scratch row and a row of another class both match; and a planted path that the generated pathspec
#   (`:(exclude,glob)build/<pattern>/**`, the planner's pruned listing) and the generated regex (N-D's SCRATCH,
#   tools/static_confirm.py's drop_scratch) judge differently — each scratch pattern's instance and its near misses
#   (`agent7-x`, `agent7.d`, `agentX`, `sheets2`, a changed case) in a throwaway git repository.
# HOW: drives the tool's selftest (the generated forms on known paths, the classing, the plant check, and a census of a
#   synthetic repository with an unclassed code name, an unclassed directory and an ambiguous one), then runs the
#   census with the plant over THIS tree; five controls run perturbed copies and each must fail.
# EXPECTS: the selftest passes, the census of this tree reports 0 problems, and every control fails. A red names the
#   unclassed build/<top> and where it came from: class it in tests/expected/build_dirs.tsv (scratch only for output
#   no static gate reads), or remove the directory.
#
# WHY. #304's analysis (build/agent207/t304/) found 98.9% of a snapshot's files under the session's scratch, and the
# planner's scratch rule written twice — the regex `agent\d+\w*` and the glob `agent[0-9]*` disagreed on
# build/agent7-x/ (rule-checker run 2026-10-23-1195). The maintainer ruled: "Adopt all four (Recommended)".
#
# MUST-FIRE: perturbed-copy: drop-class — a copy of the list without its `input` rows must leave the build dirs this tree's programs name unclassed, and the census must FAIL (mode: the census of this tree with that list)
# MUST-FIRE: perturbed-copy: handwritten-apart — a copy whose scratch regex is written apart from the list (the regex `agent\d+\w*` of 14z-206) must judge build/agent7-x/ unlike the pathspec, and the selftest must FAIL (mode: that copy's selftest)
# MUST-FIRE: perturbed-copy: code-blind — a copy whose census ignores the names programs write must pass the synthetic unclassed code name, and the selftest must FAIL (mode: that copy's selftest)
# MUST-FIRE: perturbed-copy: live-blind — a copy whose census ignores the directories present must pass the synthetic unclassed directory, and the selftest must FAIL (mode: that copy's selftest)
# MUST-FIRE: perturbed-copy: ambiguity-off — a copy whose census allows a name matching scratch and another class must pass the synthetic ambiguous name, and the selftest must FAIL (mode: that copy's selftest)
#
# Usage: tests/test_build_dirs.sh      # ci_portable, ~10 s
set -eu
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
. "$REPO/tests/lib/controls.sh"; vs_ctl_mode "$0"
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT
CTLS="handwritten-apart code-blind live-blind ambiguity-off"

make_copy() {  # make_copy <control> — a copy of the tool and its list with ONE perturbation
    mkdir -p "$W/$1/tools" "$W/$1/tests/expected"; cp tools/build_dirs.py "$W/$1/tools/"
    cp tests/expected/build_dirs.tsv "$W/$1/tests/expected/"
    python3 - "$W/$1" "$1" <<'PY'
import os, sys; d, name = sys.argv[1:3]
if name == "drop-class":
    p = os.path.join(d, "tests", "expected", "build_dirs.tsv")
    s = open(p).read()
    open(p, "w").write("".join(l for l in s.splitlines(True) if not l.startswith("input\t")))
    sys.exit(0)
p = os.path.join(d, "tools", "build_dirs.py"); s = open(p).read()
a, b = {
    "handwritten-apart": ('    return re.compile(r"^build/(?:" + "|".join(glob_rx(p) for p in scratch_rows(rows or load())) + r")/")',
                          '    return re.compile(r"^build/(?:agent\\d+\\w*|" + "|".join(glob_rx(p) for p in scratch_rows(rows or load()) if not p.startswith("agent")) + r")/")  # CONTROL handwritten-apart'),
    "code-blind": ("    named = code_names(root)", "    named = {}  # CONTROL code-blind"),
    "live-blind": ("    for n in live_dirs(root):", "    for n in []:  # CONTROL live-blind"),
    "ambiguity-off": ('        if "scratch" in hit and len(hit) > 1:', "        if False:  # CONTROL ambiguity-off"),
}[name]
assert s.count(a) == 1, name
open(p, "w").write(s.replace(a, b, 1))
PY
    echo "$W/$1/tools/build_dirs.py"
}

echo "== test_build_dirs: #304 — build/'s top-level directories, classed once =="
fail=0
BD=tools/build_dirs.py
LISTARG=""
case " $CTLS " in *" ${VS_CTL:-none} "*) BD="$(make_copy "$VS_CTL")" ;; esac
if [ "${VS_CTL:-}" = drop-class ]; then make_copy drop-class > /dev/null; LISTARG="--list $W/drop-class/tests/expected/build_dirs.tsv"; fi
python3 "$BD" --selftest > "$W/self.txt" 2>&1 || true
sed 's/^/  /' "$W/self.txt"
grep -q '^SELFTEST PASS$' "$W/self.txt" || { echo "FAIL: the tool's selftest"; fail=1; }
# shellcheck disable=SC2086
python3 "$BD" census --root . --plant $LISTARG > "$W/census.txt" 2>&1 && crc=0 || crc=$?
grep -E '^(PROBLEM|census:)' "$W/census.txt" | sed 's/^/  /'
echo "  $(grep -c '^  code ' "$W/census.txt") code name(s), $(grep -c '^  tree ' "$W/census.txt") director(ies) of this tree, $(grep -c '^  plant ' "$W/census.txt") planted path(s)"
[ "$crc" = 0 ] || { echo "FAIL: the census of this tree"; fail=1; }

if [ -z "${VS_CTL:-}" ]; then
    for c in $CTLS; do
        python3 "$(make_copy "$c")" --selftest > "$W/ctl_$c.txt" 2>&1 || true
        if grep -q '^SELFTEST FAIL$' "$W/ctl_$c.txt"; then vs_ctl_fired "$c" "$(grep -m1 'FAIL' "$W/ctl_$c.txt" | sed 's/^ *//')"
        else vs_ctl_dead "$c" "the perturbed copy passed its selftest — the selftest cannot see this failure" || fail=1; fi
    done
    make_copy drop-class > /dev/null
    if python3 tools/build_dirs.py census --root . --list "$W/drop-class/tests/expected/build_dirs.tsv" > "$W/ctl_drop-class.txt" 2>&1; then
        vs_ctl_dead drop-class "the census passed with the input rows gone" || fail=1
    else vs_ctl_fired drop-class "$(grep -m1 '^PROBLEM' "$W/ctl_drop-class.txt")"; fi
fi

if [ "$fail" = 0 ]; then echo "PASS: every build/ top-level directory named or present is classed, and the generated scratch forms agree"
else echo "FAIL: test_build_dirs"; exit 1; fi
