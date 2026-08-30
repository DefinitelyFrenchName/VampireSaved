#!/bin/sh
# test_romset_identity.sh — ground truth for tools/audit_romset_identity.py.
#
# The audit encodes the 14z-60z failure: both emulators resolve a ROM entry
# by HASH before falling back to its NAME, so any member carrying the
# PRISTINE bytes of a member the build patched can shadow it — the patch
# reverts at load time with no error, no 0xFF fill, and no failing RAM gate.
#
# A checker is only worth what its negative controls prove, so this drives
# the audit over four synthetic sets built from $ROMDIR (no build, no
# emulator, ~1s):
#
#   1. patched, no duplicate          -> PASS
#   2. patched + a copy of the member's pristine bytes under ANOTHER name
#      (the exact WIDE group-C shape)  -> FAIL, and it must NAME the member
#   3. patched + byte-identical PLACEHOLDER members that shadow nothing
#      (the shipped zero-fill group C) -> PASS  (no false positive)
#   4. nothing patched at all          -> PASS  (no false positive)
#
# Usage: ROMDIR=... tests/test_romset_identity.sh
#
# HANDOFF's gate-index note, moved into this header 14z-123 (verbatim; the
# documentation pass ruled a gate's WHY lives in the gate):
#   ground truth for tools/audit_romset_identity.py: no member may carry the
#   PRISTINE bytes of a member the build patched (both emulators resolve a ROM
#   entry by hash before name, so such a member silently reverts the patch —
#   14z-60z). 4 synthetic sets, no emulator, ~1s
set -eu
ROMDIR="${ROMDIR:?set ROMDIR}"
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
fail=0

python3 - "$ROMDIR" "$WORK" <<'PYEOF'
import os, sys, zipfile
romdir, work = sys.argv[1], sys.argv[2]
src = zipfile.ZipFile(os.path.join(romdir, "vsavj.zip"))
names = src.namelist()
VICTIM = "vm3j.03d"
pristine = src.read(VICTIM)
patched = bytes([pristine[0] ^ 0xFF]) + pristine[1:]     # one flipped byte
blank = b"\x00" * 0x1000

def write(case, patch_victim, extras):
    d = os.path.join(work, case)
    os.makedirs(d, exist_ok=True)
    with zipfile.ZipFile(os.path.join(d, "vsavj.zip"), "w") as z:
        for n in names:
            z.writestr(n, patched if (n == VICTIM and patch_victim) else src.read(n))
        for extra_name, data in extras:
            z.writestr(extra_name, data)

write("case1", True,  [])
write("case2", True,  [("vsw.99m", pristine)])            # the shadow
write("case3", True,  [("vsw.31m", blank), ("vsw.33m", blank)])
write("case4", False, [("vsw.31m", blank), ("vsw.33m", blank)])
PYEOF

check() {  # check <case> <expect pass|fail> <description>
    if python3 tools/audit_romset_identity.py "$WORK/$1" > "$WORK/$1.out" 2>&1; then
        got=pass
    else
        got=fail
    fi
    if [ "$got" = "$2" ]; then
        echo "  ok: $3 -> $got"
    else
        echo "  FAIL: $3 -> $got (expected $2)"
        sed 's/^/        /' "$WORK/$1.out"
        fail=1
    fi
}

echo "== ground truth for the member-identity audit =="
check case1 pass "patched member, no duplicate anywhere"
check case2 fail "patched member + its pristine bytes under another name"
check case3 pass "patched member + byte-identical placeholders (shadow nothing)"
check case4 pass "nothing patched"

# A failure that does not say WHICH member is not actionable.
if grep -q "vm3j.03d" "$WORK/case2.out" && grep -q "vsw.99m" "$WORK/case2.out"; then
    echo "  ok: the failure names both the patched member and its shadow"
else
    echo "  FAIL: case2 failed without naming the members involved"
    fail=1
fi

# And the benign case must not merely pass silently — it must be reported,
# or a real duplicate could hide in a build nobody looks at twice.
if grep -q "byte-identical members" "$WORK/case3.out"; then
    echo "  ok: harmless duplicates are reported, not hidden"
else
    echo "  FAIL: case3 passed without reporting the duplicate members"
    fail=1
fi

[ "$fail" = 0 ] || { echo "FAIL: romset member-identity audit ground truth"; exit 1; }
echo "PASS: romset member-identity audit ground truth (4 cases + 2 message checks)"
