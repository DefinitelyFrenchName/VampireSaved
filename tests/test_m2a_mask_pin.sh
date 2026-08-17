#!/bin/sh
# test_m2a_mask_pin.sh — the M2 battery's V1 mask and run_suite's built-in
# default are the same string, and must stay so (14z-94, GitHub #70).
# ROM-free, ~1 s.
#
# #70 observed that tests/lib/m2a_common.sh hardcodes the V1 basis and never
# reads tests/expected/<set>/mask, "the single source of truth". True — and
# deliberate: this battery targets the donovan-m2c generation, and whether it
# should be re-pointed at V2 and unified with run_suite's dispatch is an OPEN
# MAINTAINER QUESTION recorded in the lib itself and in STATE.md. Making it
# read the per-set mask would answer that question silently, by moving which
# generation the battery validates.
#
# So the pin stays and the DUPLICATION is gated instead. Two files carry the
# same V1 string for the same reason; if one is edited and the other is not,
# both go on claiming to be V1 while measuring different bases — which is the
# failure #70 is really about.
set -eu
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
rc=0

lib=$(sed -n 's/^M2A_MASK="\(.*\)"$/\1/p' tests/lib/m2a_common.sh | head -1)
suite=$(sed -n 's/^MASK="\(.*\)"$/\1/p' tests/run_suite.sh | head -1)
echo "  m2a_common.sh M2A_MASK : $lib"
echo "  run_suite.sh  default  : $suite"
if [ -z "$lib" ] || [ -z "$suite" ]; then
    echo "  FAIL: could not read one of them — the pattern moved, fix this gate"
    rc=1
elif [ "$lib" != "$suite" ]; then
    echo "  FAIL: the two V1 copies have DRIFTED. Both still claim to be V1"
    echo "        while masking different byte sets."
    rc=1
else
    echo "  ok: the two copies agree"
fi

# The pin is intentional; assert the reason is still written down, so nobody
# "fixes" it without meeting the maintainer question.
if grep -q "OPEN MAINTAINER QUESTION\|maintainer question" tests/lib/m2a_common.sh; then
    echo "  ok: the lib still records WHY it pins a generation"
else
    echo "  FAIL: the rationale for pinning is gone — without it this looks"
    echo "        like an oversight and will be 'fixed' into a silent re-point"
    rc=1
fi

echo
[ "$rc" = 0 ] && echo "PASS: the two V1 mask copies agree, and the pin is documented." \
             || echo "FAIL: see above."
exit $rc
