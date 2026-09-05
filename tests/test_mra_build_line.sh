#!/bin/sh
# test_mra_build_line.sh — the WIDE MRA names the FREEZE it was generated for,
# and can never name the wrong one (14z-133b). Static tier: ROMDIR + the
# merged build + emu/jtcores; ~1 min (three ROM-free MRA generations).
#
# WHY. Maintainer, mid-field-test on M16, 2026-09-05: "it might be nicer to
# have the merged build referenced somewhere in the mister builds" — and,
# ruled the same hour, NOT in the MRA <name> (no menu churn). Until then the
# merged build was named only in the bundle README; answering "is this bundle
# M16?" took five hash comparisons (STATE 14z-133b). Now the WIDE MRA's
# comment header ends with a BUILD block written by tools/mra_header.py when
# tools/mister_mra.sh is given --wide: the registry row resolved from the
# build's rompath (whole-set key first, program key second), the mark when
# the row is merged-mN, the vsavjw.zip sha1 and both keys.
#
# THE PROPERTY THAT MATTERS: THE BLOCK IS SELF-VERIFYING. It is written only
# after every CRC-identified <part> of the MRA resolves against that build's
# zips; otherwise the tool REFUSES and the generator fails — an MRA naming a
# build it was not generated for is worse than no MRA. Section 3 is that
# refusal as a must-fire control.
#
# WHAT IT LOCKS
#  1. --wide <the current merged build>: the WIDE MRA's header names the row
#     build_fingerprint.py resolves for that build, the zip's sha1, and the
#     mark; the STOCK CONTROL MRA carries no block (jtframe's own header);
#  2. no --wide: the block says "not stated" — an unnamed MRA is honest;
#  3. MUST-FIRE: --wide pointing at a rompath whose vsavjw.zip differs by one
#     byte in a member (so one CRC part cannot resolve) makes the generator
#     FAIL and write NO block;
#  4. idempotent: rewriting the same header again changes no byte.
#
# Usage: ROMDIR=... [MRA_LINE_BUILD=build/m3b_merged23] tests/test_mra_build_line.sh
set -eu
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
ROMDIR="${ROMDIR:?set ROMDIR}"
ROMDIR="$(cd "$ROMDIR" && pwd)"
BUILD="${MRA_LINE_BUILD:-build/m3b_merged23}"
[ -f "emu/jtcores/.gitmodules" ] || { echo "SKIP: emu/jtcores not initialised (tools/setup_jtcores.sh)"; exit 0; }
[ -f "$BUILD/rompath/vsavjw.zip" ] || { echo "SKIP: no $BUILD/rompath/vsavjw.zip"; exit 0; }
WORK="$(mktemp -d "${TMPDIR:-/tmp}/mra_build_line.XXXXXX")"
trap 'rm -rf "$WORK"' EXIT
fail=0
WIDE_MRA="Vampire Saved - CPS-2 WIDE (Japan 970519).mra"
STOCK_MRA="Vampire Savior The Lord of Vampire (Japan 970519).mra"

echo "== 1. --wide $BUILD: the WIDE MRA names the freeze, the stock MRA does not =="
# THE EXPECTATION, resolved INDEPENDENTLY of the tool: the whole-set key from
# build_fingerprint.py, then the registry row that carries it, else the ONE
# annotated freeze/* tag whose message carries it (merged builds have no
# registry row by design — registry.tsv's header, B2 deferred 14z-132).
wkey="$(python3 tools/build_fingerprint.py "$BUILD/rompath" --set vsavjw --set-key | tail -1)"
expect="$(awk -F'\t' -v k="$wkey" '$1==k{print $2}' tests/expected/registry.tsv | head -1)"
if [ -z "$expect" ]; then
    for t in $(git tag -l 'freeze/*'); do
        git tag -l "$t" -n200 | grep -qF "$wkey" && { expect="${t#freeze/}"; break; }
    done
fi
[ -n "$expect" ] || { echo "  FAIL: neither registry.tsv nor a freeze tag carries this build's whole-set key $wkey"; fail=1; }
zsha="$(shasum "$BUILD/rompath/vsavjw.zip" | cut -c1-40)"
tools/mister_mra.sh --core cps2w --wide "$BUILD" --no-rom --quiet --out "$WORK/a" || { echo "  FAIL: generation with --wide failed"; fail=1; }
if grep -q "BUILD  $expect " "$WORK/a/mra/$WIDE_MRA" 2>/dev/null; then echo "  ok: header names $expect (build_fingerprint's own resolution)"
else echo "  FAIL: header does not name $expect: $(grep -m1 'BUILD' "$WORK/a/mra/$WIDE_MRA" 2>/dev/null)"; fail=1; fi
grep -q "vsavjw.zip  sha1 $zsha" "$WORK/a/mra/$WIDE_MRA" && echo "  ok: header carries the zip's sha1 $zsha" \
    || { echo "  FAIL: zip sha1 missing from the header"; fail=1; }
case "$expect" in merged-m*) grep -q "mark M${expect#merged-m} " "$WORK/a/mra/$WIDE_MRA" && echo "  ok: mark M${expect#merged-m} stated" || { echo "  FAIL: mark not stated"; fail=1; } ;; esac
stock="$(find "$WORK/a/mra" -name "$STOCK_MRA" | head -1)"   # the non-main set is filed under _alternatives/
[ -n "$stock" ] || { echo "  FAIL: no stock control MRA emitted"; fail=1; }
[ -n "$stock" ] && grep -q "BUILD" "$stock" && { echo "  FAIL: the STOCK CONTROL MRA carries a build block"; fail=1; } || echo "  ok: stock control MRA untouched (jtframe's own header)"
python3 -c "import xml.dom.minidom,sys; xml.dom.minidom.parse(sys.argv[1])" "$WORK/a/mra/$WIDE_MRA" && echo "  ok: still valid XML" || { echo "  FAIL: invalid XML"; fail=1; }

echo "== 2. no --wide: the block says the build is not stated =="
tools/mister_mra.sh --core cps2w --no-rom --quiet --out "$WORK/b" || { echo "  FAIL: generation without --wide failed"; fail=1; }
grep -q "BUILD  not stated" "$WORK/b/mra/$WIDE_MRA" && echo "  ok: 'BUILD  not stated' when no build was given" \
    || { echo "  FAIL: an unnamed MRA claims a build: $(grep -m1 BUILD "$WORK/b/mra/$WIDE_MRA")"; fail=1; }

echo "== 3. MUST-FIRE CONTROL: a rompath the MRA was not generated for is REFUSED =="
mkdir -p "$WORK/bad/rompath"; cp "$BUILD/rompath/"*.zip "$WORK/bad/rompath/"
python3 - "$WORK/bad/rompath/vsavjw.zip" <<'PY'
import sys, zipfile
p = sys.argv[1]; z = zipfile.ZipFile(p); infos = z.infolist(); data = {i.filename: z.read(i.filename) for i in infos}; z.close()
b = bytearray(data["vsw.37m"]); b[0] ^= 0xFF; data["vsw.37m"] = bytes(b)
o = zipfile.ZipFile(p, "w", zipfile.ZIP_DEFLATED)
for i in infos: o.writestr(i.filename, data[i.filename])
o.close()
PY
if tools/mister_mra.sh --core cps2w --wide "$WORK/bad" --no-rom --quiet --out "$WORK/c" > "$WORK/c.log" 2>&1; then
    echo "  FAIL: the generator ACCEPTED a build whose vsw.37m CRC the MRA does not carry"; fail=1
else
    grep -q "REFUSING to name build" "$WORK/c.log" && echo "  ok: control fires — refused: $(grep -o 'REFUSING to name build[^:]*' "$WORK/c.log" | head -1)" \
        || { echo "  FAIL: generator failed for another reason: $(tail -2 "$WORK/c.log")"; fail=1; }
fi
[ -f "$WORK/c/mra/$WIDE_MRA" ] && grep -q "BUILD  " "$WORK/c/mra/$WIDE_MRA" && { echo "  FAIL: a build block was written despite the refusal"; fail=1; } || echo "  ok: no build block written"

echo "== 4. idempotent =="
cp "$WORK/a/mra/$WIDE_MRA" "$WORK/a.before"
python3 tools/mra_header.py "$WORK/a/mra" --build "$BUILD" >/dev/null 2>&1 || { echo "  FAIL: second rewrite errored"; fail=1; }
cmp -s "$WORK/a/mra/$WIDE_MRA" "$WORK/a.before" && echo "  ok: a second rewrite changes no byte" || { echo "  FAIL: the rewrite is not idempotent"; fail=1; }

if [ "$fail" -eq 0 ]; then echo "PASS: the WIDE MRA names its freeze, an unnamed one says so, the wrong build is refused, and the rewrite is idempotent"
else echo "FAIL: mra build line"; exit 1; fi
