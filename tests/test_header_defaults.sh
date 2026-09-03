#!/bin/sh
# test_header_defaults.sh — a gate's HEADER must state the default its CODE
# actually uses (14z-128). ROM-free, ~2 s.
#
# THE CLASS, and it is the twin of test_build_ref_rot.sh's. That gate closed
# the case where a gate's CODE default names a build dir that has been pruned;
# the freeze ritual's re-point sweep has kept those honest. Nobody was
# re-pointing the HEADERS: measured 14z-128, 37 lines across 37 gates told a
# reader to pass `BUILD=build/m3b_merged11` or `build/m3b_merged12` — dirs
# pruned freezes earlier — while the code defaulted to `build/m3b_merged22`.
#
# WHY IT MATTERS even though nothing was broken: the maintainer ruled at
# 14z-122 that a gate's WHY lives in its header, and `docs/project/gate_index.md`
# is GENERATED from those headers. A header naming a dead dir is a documented
# instruction that cannot be followed, in the one place a reader looks before
# running the gate.
#
# THE RULE is deliberately narrow (tools/audit_header_defaults.py states it in
# full): every `build/<dir>` on a header line that presents itself as an
# INVOCATION or a DEFAULT must be one of the defaults the code sets. Other
# mentions are left alone — a header may cite the build a measurement was
# taken on, and that build being pruned does not make the citation wrong. Two
# exemptions, each paid for during the first sweep: a BACKTICKED token is code
# being discussed (test_build_ref_rot.sh quotes `${1:-build/pyron22}` while
# explaining the very class), and a block introduced "(verbatim; ...)" is an
# ARCHIVE — most gate headers carry HANDOFF's old gate-index note, moved in at
# 14z-123, and rewriting a default inside one falsifies the quote ([VSP-13]:
# archived entries are never rewritten).
#
# Usage: tests/test_header_defaults.sh
set -eu
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
rc=0

echo "== 1. the tree"
if out="$(python3 tools/audit_header_defaults.py 2>&1)"; then
    echo "  ok: $out"
else
    printf '%s\n' "$out" | sed 's/^/  /'
    echo "  FAIL: fix the header, or re-point the code default — then re-run."
    echo "        tools/audit_header_defaults.py --fix rewrites the mechanical ones."
    rc=1
fi

echo "== 2. must-fire controls (each MUST be caught)"
T="$(mktemp -d)"; trap 'rm -rf "$T"' EXIT INT TERM
mkdir -p "$T/tests" "$T/tools"
cp tools/audit_header_defaults.py "$T/tools/"

# A: a Usage line naming a dir the code does not default to -> CAUGHT
{ echo '#!/bin/sh'
  echo '# g_a.sh — a stub.'
  echo '# Usage: ROMDIR=... [BUILD=build/old_dir] tests/g_a.sh'
  echo 'BUILD="${BUILD:-build/new_dir}"'; } > "$T/tests/g_a.sh"
# B: the same line, but agreeing with the code -> NOT caught
{ echo '#!/bin/sh'
  echo '# g_b.sh — a stub.'
  echo '# Usage: ROMDIR=... [BUILD=build/new_dir] tests/g_b.sh'
  echo 'BUILD="${BUILD:-build/new_dir}"'; } > "$T/tests/g_b.sh"
# C: a stale dir mentioned in ordinary prose (no "usage", no "default")
#    -> NOT caught, or the rule would forbid citing the build a measurement
#    was taken on
{ echo '#!/bin/sh'
  echo '# g_c.sh — a stub.'
  echo '# MEASURED 14z-1 on build/old_dir: the beam draws.'
  echo 'BUILD="${BUILD:-build/new_dir}"'; } > "$T/tests/g_c.sh"
# D: a stale dir inside a VERBATIM archive block -> NOT caught
{ echo '#!/bin/sh'
  echo '# g_d.sh — a stub.'
  echo '# HANDOFF note, moved into this header (verbatim; the doc pass ruled it):'
  echo '#   Defaults build/old_dir'
  echo 'BUILD="${BUILD:-build/new_dir}"'; } > "$T/tests/g_d.sh"
# E: a stale dir inside BACKTICKS on a "default" line -> NOT caught
{ echo '#!/bin/sh'
  echo '# g_e.sh — a stub.'
  echo '# Every `${1:-build/old_dir}` default is a pointer with a shelf life.'
  echo 'BUILD="${BUILD:-build/new_dir}"'; } > "$T/tests/g_e.sh"

out="$(python3 "$T/tools/audit_header_defaults.py" --root "$T" 2>&1 || true)"
check() {  # check <gate> <expect caught|clean> <why>
    if printf '%s\n' "$out" | grep -q "tests/$1.sh"; then got=caught; else got=clean; fi
    if [ "$got" = "$2" ]; then
        echo "  ok: $1 $2 — $3"
    else
        echo "  FAIL: $1 came out $got, expected $2 — $3"; rc=1
    fi
}
check g_a caught "a Usage line naming a non-default dir"
check g_b clean  "the same line, agreeing with the code"
check g_c clean  "a stale dir cited in prose is a measurement, not an instruction"
check g_d clean  "a stale dir inside a (verbatim) archive block"
check g_e clean  "a stale dir inside backticks, i.e. code being discussed"

# F: --fix repairs A and leaves the rest alone
python3 "$T/tools/audit_header_defaults.py" --root "$T" --fix >/dev/null 2>&1 || true
if grep -q 'BUILD=build/new_dir' "$T/tests/g_a.sh"; then
    echo "  ok: --fix rewrote the Usage line to the code's own default"
else
    echo "  FAIL: --fix did not repair g_a"; rc=1
fi
if grep -q 'build/old_dir' "$T/tests/g_c.sh" && grep -q 'build/old_dir' "$T/tests/g_d.sh"; then
    echo "  ok: --fix left the prose citation and the verbatim block untouched"
else
    echo "  FAIL: --fix rewrote a line it must not touch"; rc=1
fi

echo
[ "$rc" = 0 ] && echo "PASS: every header states the default its code uses" \
              || echo "FAIL: see above"
exit $rc
