#!/bin/sh
# test_m2a_target_policy.sh — the M2 battery's target is RESOLVED, never
# pinned, and the mask literal has exactly one home. ROM-free, ~1 s.
#
# WAS test_m2a_mask_pin.sh, and it asserted the OPPOSITE (14z-93 -> 14z-97).
# That gate existed because tests/lib/m2a_common.sh hardcoded the V1 mask and
# run_suite.sh carried the same string as its default: GitHub #70 called the
# duplication out, the answer at the time was "the pin is deliberate — this
# battery targets the donovan-m2c generation, and re-pointing it is an OPEN
# MAINTAINER QUESTION", so the gate locked the two copies together instead.
#
# The question was answered on 2026-08-19 (maintainer, GitHub #96, option
# (a)): the battery targets the CURRENT frozen generation, resolved from the
# build's own fingerprint through tests/expected/registry.tsv. So the pin is
# gone, the duplication with it, and what needs locking is the reverse —
# that neither comes back. A future session reading `m2a_common.sh` will find
# no mask and no set name in it, and "helpfully" adding one is exactly the
# defect #96 was filed for.
#
# Usage: tests/test_m2a_target_policy.sh
set -eu
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
rc=0

LIB=tests/lib/m2a_common.sh
MC=tests/lib/masked_compare.sh

echo "== 1. the battery pins no mask =="
# A bare M2A_MASK="" is the resolved-at-run-time placeholder and is fine;
# anything with hex ranges in it is a pin.
if grep -qE '^M2A_MASK="[0-9a-f]' "$LIB"; then
    echo "  FAIL: $LIB carries a literal mask again:"
    grep -nE '^M2A_MASK="[0-9a-f]' "$LIB" | sed 's/^/        /'
    echo "        The mask comes from the expectation set (masked_mask_for)."
    rc=1
else
    echo "  ok: no literal mask in $LIB"
fi

echo "== 2. the battery pins no expectation set =="
if grep -nE '^[A-Z_]*="?tests/expected/[a-z0-9-]+' "$LIB" > /dev/null 2>&1; then
    echo "  FAIL: $LIB names an expectation set as a constant:"
    grep -nE '^[A-Z_]*="?tests/expected/[a-z0-9-]+' "$LIB" | sed 's/^/        /'
    echo "        The set is resolved from the build fingerprint. If a build"
    echo "        does not resolve, that is rule 6 — not a reason to pin."
    rc=1
else
    echo "  ok: no expectation-set constant in $LIB"
fi

echo "== 3. the target really is resolved from the build =="
if grep -q "build_fingerprint.py" "$LIB"; then
    echo "  ok: the gate dispatches on the fingerprint"
else
    echo "  FAIL: $LIB no longer resolves its target from the build — the"
    echo "        auto-detecting-runner property (CLAUDE.md §4) is gone"
    rc=1
fi

echo "== 4. the V1 default mask literal has exactly one home =="
# The failure #70 named: two files claiming to be V1 while masking different
# byte sets. One definition cannot drift from itself.
# The literal is READ from the lib, never written here — otherwise this gate
# is itself a second copy and counts itself (measured: it did, first run).
V1=$(sed -n 's/^MASKED_DEFAULT_MASK="\(.*\)"$/\1/p' "$MC" | head -1)
if [ -z "$V1" ]; then
    echo "  FAIL: cannot read MASKED_DEFAULT_MASK from $MC — the definition"
    echo "        moved; fix this gate rather than pasting the string back"
    rc=1
fi
homes=$(grep -rlF "$V1" tests/ 2>/dev/null | sort)
n=$(printf '%s\n' "$homes" | grep -c . || true)
if [ "$n" = 1 ] && [ "$homes" = "$MC" ]; then
    echo "  ok: only $MC defines it"
else
    echo "  FAIL: the V1 literal appears in $n file(s) under tests/:"
    printf '%s\n' "$homes" | sed 's/^/        /'
    echo "        It belongs in $MC alone; read it from there."
    rc=1
fi

echo "== 5. the reason is still written down =="
# Without it the next reader sees an unexplained indirection and pins it back.
if grep -q "maintainer-ruled option (a)\|RULED 2026-08-19" "$LIB"; then
    echo "  ok: $LIB records the ruling that removed the pin"
else
    echo "  FAIL: the rationale is gone from $LIB — without it the re-point"
    echo "        looks like an oversight and will be 'fixed' back into a pin"
    rc=1
fi

echo
[ "$rc" = 0 ] && echo "PASS: the battery resolves its target and pins nothing." \
             || echo "FAIL: see above."
exit $rc
