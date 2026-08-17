#!/bin/sh
# test_builder_rom_audit.sh — every builder that reads $ROMDIR must run the
# mandatory checksum gate first (14z-94, GitHub #28). ~5 s, no emulator.
#
# CLAUDE.md §3: "Verify SHA-1 against docs/checksums.txt before any session
# that reads them. If checksums mismatch, stop." build_donovan.sh did this;
# build_merged.sh did not, while reading $ROMDIR at five points — so pointing
# it at a different vsav revision, or a re-dumped / no-intro-renamed zip,
# produced a complete 3-tenant artifact with no complaint. The only downstream
# tell was a fingerprint matching nothing, and the script prints that as
# information rather than checking it (rule 4: unattributable provenance).
#
# WHAT THIS ASSERTS, and why the second half is the load-bearing one:
#   1. an UNAUDITABLE $ROMDIR is refused by every builder, with the §3 message;
#   2. the refusal happens EARLY — before the builder has written an artifact.
#      A gate that fires after the zip is packed still leaves a bad artifact on
#      disk for someone to pick up;
#   3. the check is not vacuous: a real $ROMDIR gets PAST it.
set -eu
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
T="$(mktemp -d)"; trap 'rm -rf "$T"' EXIT INT TERM
rc=0
fail() { echo "  FAIL: $*"; rc=1; }

BUILDERS="tools/build_merged.sh tools/build_donovan.sh"

echo "== 1. every builder that reads \$ROMDIR carries the gate =="
for b in $BUILDERS; do
    if grep -q 'audit_roms.py "\$ROMDIR"' "$b"; then
        echo "  ok: $b calls audit_roms.py on \$ROMDIR"
    else
        fail "$b reads \$ROMDIR but never audits it (CLAUDE.md §3)"
    fi
done

echo "== 2. an unauditable ROMDIR is REFUSED, and before any artifact =="
mkdir -p "$T/emptyrom" "$T/out"
# build_merged.sh: the gate sits above every write, so the out dir must not
# even be created. (It takes <outbase> as $1 and rm -rf's it later.)
set +e
ROMDIR="$T/emptyrom" sh tools/build_merged.sh "$T/out/merged" > "$T/m.log" 2>&1
mrc=$?
set -e
if [ "$mrc" = 0 ]; then
    fail "build_merged.sh ACCEPTED an unauditable ROMDIR"
elif ! grep -q "ROM audit FAILED" "$T/m.log"; then
    fail "build_merged.sh failed for an UNNAMED reason — this control would"
    fail "      then pass on any unrelated breakage. Output was:"
    sed 's/^/        /' "$T/m.log"
else
    echo "  ok: build_merged.sh refused it — $(grep -m1 'ROM audit FAILED' "$T/m.log")"
    if [ -e "$T/out/merged" ]; then
        fail "it created $T/out/merged before refusing — the gate is too late"
    else
        echo "  ok: refused before creating the output directory"
    fi
fi

echo "== 3. the gate is not vacuous — a real ROMDIR gets past it =="
if [ -z "${ROMDIR:-}" ]; then
    echo "  SKIP: no ROMDIR exported, cannot run the positive control"
else
    if python3 tools/audit_roms.py "$ROMDIR" > /dev/null 2>&1; then
        echo "  ok: the configured \$ROMDIR audits clean, so the refusal above"
        echo "      is about the DIRECTORY, not about the gate always failing"
    else
        fail "the configured \$ROMDIR does not audit clean — fix that first;"
        fail "      section 2's refusal cannot be attributed while it is dirty"
    fi
fi

echo
if [ "$rc" = 0 ]; then
    echo "PASS: builders refuse an unaudited ROMDIR before writing anything."
else
    echo "FAIL: see above."
fi
exit $rc
