#!/bin/sh
# test_mra_parts.sh — ground-truth for tools/check_mra_parts.py's VERDICT LOGIC.
#
# MUST-FIRE: known-bad: bogus-crc — an MRA whose second part carries a CRC no zip member has must fail the resolver, naming the one bad part
# MUST-FIRE: known-bad: missing-zip — an MRA resolved against a directory holding no zip at all must fail with every part unresolved
#
# WHY THIS GATE EXISTS. jtframe resolves zip members by CRC32 ALONE, and a part
# it cannot resolve is FILLED WITH 0xFF rather than refused (docs/GOTCHAS.md).
# So an MRA can look complete, "run", and hand the machine a ROM with holes in
# it. `tools/check_mra_parts.py` is what says whether a bundle's parts actually
# resolve — and CLAUDE.md §4 says a test's classification code is validated
# against known ground truth BEFORE its verdicts are trusted. That is this
# file: the checker is exercised on fixtures whose answer is known BY
# CONSTRUCTION, not on any real romset.
#
# ROM-FREE ON PURPOSE (rule 7): every fixture zip here holds text this script
# writes itself, so the gate runs in the ci_portable tier and in a fresh
# checkout with no ROMDIR.
#
# Usage: tests/test_mra_parts.sh
set -eu
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
TOOL="$REPO/tools/check_mra_parts.py"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
fail=0

pass() { echo "  PASS $1"; }
bad()  { echo "  FAIL $1"; fail=1; }
. "$REPO/tests/lib/controls.sh"; vs_ctl_mode "$0"

# ---------------------------------------------------------------------------
# Fixtures. Two members with CRCs we compute rather than assert, so the
# expectation cannot drift from the data.
# ---------------------------------------------------------------------------
mkdir -p "$WORK/zips"
printf 'alpha payload' > "$WORK/a.bin"
printf 'beta payload'  > "$WORK/b.bin"
( cd "$WORK" && zip -q zips/parts.zip a.bin b.bin )

CRC_A=$(python3 - "$WORK/zips/parts.zip" a.bin <<'PY'
import sys, zipfile
z = zipfile.ZipFile(sys.argv[1])
print("%08x" % (z.getinfo(sys.argv[2]).CRC & 0xFFFFFFFF))
PY
)
CRC_B=$(python3 - "$WORK/zips/parts.zip" b.bin <<'PY'
import sys, zipfile
z = zipfile.ZipFile(sys.argv[1])
print("%08x" % (z.getinfo(sys.argv[2]).CRC & 0xFFFFFFFF))
PY
)

mra() {  # mra <path> <crc1> <crc2>
    cat > "$1" <<EOF
<misterromdescription>
  <name>fixture</name>
  <setname>fixture</setname>
  <rbf>jtcps2w</rbf>
  <rom index="0" zip="parts.zip">
    <part name="a.bin" crc="$2"/>
    <part name="b.bin" crc="$3"/>
  </rom>
</misterromdescription>
EOF
}

mra "$WORK/good.mra" "$CRC_A" "$CRC_B"
mra "$WORK/bad1.mra" "$CRC_A" "deadbeef"
mkdir -p "$WORK/empty"
# THE EXECUTABLE FORM: under CONTROL=<name> section 1 resolves the known-bad
# input instead of the good one — and must FAIL.
MRA1="$WORK/good.mra"; ZIPS1="$WORK/zips"
vs_ctl_is bogus-crc   && MRA1="$WORK/bad1.mra"
vs_ctl_is missing-zip && ZIPS1="$WORK/empty"

echo "== 1 both parts resolve =="
if python3 "$TOOL" "$MRA1" "$ZIPS1" > "$WORK/o1" 2>&1; then
    grep -q "all 2 CRC-identified parts resolve" "$WORK/o1" \
        && pass "1a resolves, and says so" || bad "1a wrong wording: $(tail -1 "$WORK/o1")"
else
    bad "1a should have passed"; sed 's/^/    /' "$WORK/o1"
fi

echo "== 2 MUST-FIRE: one part does not resolve =="
if python3 "$TOOL" "$WORK/bad1.mra" "$WORK/zips" > "$WORK/o2" 2>&1; then
    vs_ctl_dead bogus-crc "a bogus CRC was accepted — the checker is blind"; bad "2a"
else
    grep -q "1 of 2 parts do not resolve" "$WORK/o2" \
        && { vs_ctl_fired bogus-crc "names exactly the one bad part"; pass "2a control fired"; } \
        || { vs_ctl_dead bogus-crc "fired but miscounted: $(tail -1 "$WORK/o2")"; bad "2a"; }
    grep -q "deadbeef" "$WORK/o2" \
        && pass "2b the failing CRC is reported, not just a count" \
        || bad "2b the bad CRC is not in the report"
fi

echo "== 3 MUST-FIRE: the zip is absent entirely =="
if python3 "$TOOL" "$WORK/good.mra" "$WORK/empty" > "$WORK/o3" 2>&1; then
    vs_ctl_dead missing-zip "an empty dir was accepted"; bad "3a"
else
    grep -q "2 of 2 parts do not resolve" "$WORK/o3" \
        && { vs_ctl_fired missing-zip "2 of 2 parts unresolved against an empty dir"; pass "3a control fired on a missing zip"; } \
        || { vs_ctl_dead missing-zip "fired but miscounted: $(tail -1 "$WORK/o3")"; bad "3a"; }
fi

echo "== 4 a part with NO crc attribute is not counted (header/fill parts) =="
cat > "$WORK/nocrc.mra" <<EOF
<misterromdescription>
  <rom index="0" zip="parts.zip">
    <part>00 ff</part>
    <part name="a.bin" crc="$CRC_A"/>
  </rom>
</misterromdescription>
EOF
if python3 "$TOOL" "$WORK/nocrc.mra" "$WORK/zips" > "$WORK/o4" 2>&1; then
    grep -q "CRC parts  : 1" "$WORK/o4" \
        && pass "4a inline literal parts are excluded from the count" \
        || bad "4a miscounted: $(grep 'CRC parts' "$WORK/o4")"
else
    bad "4a should have passed"; sed 's/^/    /' "$WORK/o4"
fi

echo "== 5 CRC width is normalised (a short crc must still match) =="
SHORT=$(printf '%s' "$CRC_A" | sed 's/^0*//')
if [ "$SHORT" != "$CRC_A" ]; then
    mra "$WORK/short.mra" "$SHORT" "$CRC_B"
    python3 "$TOOL" "$WORK/short.mra" "$WORK/zips" > "$WORK/o5" 2>&1 \
        && pass "5a a CRC written without leading zeros still resolves" \
        || bad "5a leading-zero normalisation is broken"
else
    pass "5a SKIP-equivalent: fixture CRC has no leading zero to strip"
fi

echo
[ "$fail" -eq 0 ] && echo "PASS test_mra_parts" || echo "FAIL test_mra_parts"
exit "$fail"
