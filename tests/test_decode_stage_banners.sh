#!/bin/sh
# test_decode_stage_banners.sh — ground truth for tools/decode_stage_banners.py,
# the decoder that turns the #92 value space into NAMES (14z-94, GitHub #92).
#
# WHY THIS EXISTS. The #92 fix replaces four bytes per tenant with a legal
# stage value, and that value is player-perceptible — so it is a maintainer
# decision taken against a NAMED value space, not an arbitrary in-range pick.
# Every name in that space comes out of this decoder. If the decoder is wrong
# the decision is made on fiction, so its verdict logic is tested before any
# decode is believed (CLAUDE.md §4).
#
# THE CONTROL THAT MATTERS IS SECTION 3 — THE ANCHOR. The engine site is
#
#   move.w $100(a5),d0 ; add.w d0,d0 ; movea.l #ANCHOR,a0 ; lea -4(a0,d0.w),a0
#
# and ANCHOR is the address of the family's FIRST ROW, which is NOT the
# pointer table's base: vsavj anchors at table+0x3C (row 0x0f), vs2 at
# table+0x4C (row 0x13). Decoding vs2 from its table BASE instead shifts
# every value by four rows and manufactures a tidy "+8 renumber between the
# two games" that does not exist — it was believed for part of a session
# before the anchors were read out of the code. That wrong answer is
# reproduced here and must be REJECTED.
#
# Needs the decrypted DATA views (these tables live inside the crypt window
# and are read An-relative, so the opcode view is noise). Not in
# ci_portable for that reason.
set -eu
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
VJ=build/out/vsavj_data.bin
V2=build/out/vsav2_data.bin
[ -f "$VJ" ] && [ -f "$V2" ] || { echo "SKIP: need $VJ and $V2"; exit 0; }

T=$(mktemp -d); trap 'rm -rf "$T"' EXIT INT TERM
DEC="python3 tools/decode_stage_banners.py"
rc=0
say() { printf '%s\n' "$*"; }
fail() { say "  FAIL: $*"; rc=1; }

$DEC stages "$VJ" 0x26771e 0x26775a > "$T/vj.txt" 2>&1
$DEC stages "$V2" 0x2a0a4a 0x2a0a96 > "$T/v2.txt" 2>&1

say "== 1. the two families enumerate to their measured sizes =="
nvj=$(grep -c '^  v=' "$T/vj.txt" || true)
nv2=$(grep -c '^  v=' "$T/v2.txt" || true)
[ "$nvj" = 12 ] || fail "vsavj: expected 12 stages, got $nvj"
[ "$nv2" = 13 ] || fail "vsav2: expected 13 stages, got $nv2"
[ "$nvj" = 12 ] && [ "$nv2" = 12 ] && fail "vs2 must have MORE stages than vsavj"
say "  ok: vsavj $nvj, vsav2 $nv2 — the difference is the whole of #92"

say "== 2. known records decode to known text =="
grep -q 'v=0x00 .*FEASTOFTHEDAMNED' "$T/vj.txt" || fail "vsavj v=0x00 is not FEAST OF THE DAMNED"
grep -q 'v=0x16 .*FETUSOFGOD'       "$T/vj.txt" || fail "vsavj v=0x16 is not FETUS OF GOD"
grep -q 'v=0x18 .*REVENGER.*SROOST' "$T/v2.txt" || fail "vs2 v=0x18 is not REVENGER'S ROOST"
say "  ok: the endpoints and the crashing value are named"

say "== 3. VERDICT CONTROL — the table BASE must not pass as the anchor =="
# The pre-fix mistake: decode vs2 from 0x2a0a4a. Rows 0x0f-0x12 are a
# different family, so the decoder must refuse them rather than print text.
$DEC stages "$V2" 0x2a0a4a 0x2a0a4a > "$T/bad.txt" 2>&1 && bad_rc=0 || bad_rc=$?
if grep -q 'v=0x00 .*FEASTOFTHEDAMNED' "$T/bad.txt"; then
  fail "decoding vs2 from its table BASE produced the anchored answer — the"
  fail "      anchor is not load-bearing in this tool, so the +8 error can recur"
elif [ "$bad_rc" = 0 ]; then
  fail "the base-as-anchor decode SUCCEEDED. It must fail loudly, not merely"
  fail "      omit the names — silence is what let the +8 error stand."
elif ! grep -q 'EMPTY FAMILY' "$T/bad.txt"; then
  fail "the base-as-anchor decode failed for an UNNAMED reason; this control"
  fail "      would then pass on any unrelated crash. Output was:"
  sed 's/^/        /' "$T/bad.txt" >&2
else
  say "  ok: the base-as-anchor decode fails loudly and names the anchor as the cause"
fi

say "== 4. the twelve shared stages agree 1:1, in order =="
sed -n 's/^  v=\(0x[0-9a-f]*\) .*  \([A-Z[].*\)$/\1 \2/p' "$T/vj.txt" > "$T/a"
sed -n 's/^  v=\(0x[0-9a-f]*\) .*  \([A-Z[].*\)$/\1 \2/p' "$T/v2.txt" | head -12 > "$T/b"
if cmp -s "$T/a" "$T/b"; then
  say "  ok: same names at the same values — no renumber is owed by the port"
else
  fail "the shared stages do not agree; a value remap IS owed:"
  diff "$T/a" "$T/b" | sed 's/^/        /' || true
fi

say "== 5. VERDICT CONTROL — a corrupted record must not decode as text =="
python3 - "$VJ" "$T/corrupt.bin" <<'PY'
import sys
d = bytearray(open(sys.argv[1], "rb").read())
d[0x2690b6:0x2690b8] = b"\x00\x09"        # fmt 4 -> fmt 9 on v=0x00's record
open(sys.argv[2], "wb").write(d)
PY
$DEC stages "$T/corrupt.bin" 0x26771e 0x26775a > "$T/cor.txt" 2>&1 || true
if grep -q 'v=0x00 .*FEASTOFTHEDAMNED' "$T/cor.txt"; then
  fail "a fmt-9 record still decoded as a banner — the format check is dead"
else
  say "  ok: a non-fmt-4 record is refused, not decoded"
fi

say "== 6. the authored ladder rows are judged against the RIGHT image =="
# Every out-of-range entry on the shipped tenants must be class 0x13 wanting
# stage 0x18. If a NEW out-of-range shape appears, this gate says so rather
# than letting it ride under the #92 headline.
# hui41/pyron26 are DELIBERATE PINS (14z-103): the frozen PRE-fix builds
# that still carry #92's four authored bytes — the defect this section
# measures. The fix landed hui43/pyron27 (14z-94), so these can never
# re-point forward; both dirs are classed EVIDENCE in the build-dir census.
# The donovan leg is the clean control and follows the current freeze.
for spec in build/hui41:0x10 build/pyron26:0x11 build/don_m14:0x13; do  # don re-pointed 14z-111
  d=${spec%:*}; cls=${spec#*:}
  [ -f "$d/patch/patch.json" ] || { say "  (skip $d: no patch.json)"; continue; }
  python3 - "$d" "$cls" > "$T/row" <<'PY'
import json, sys
ops = json.load(open(f"{sys.argv[1]}/patch/patch.json"))["ops"]
cls = int(sys.argv[2], 16)
for base in (0x00B268, 0x00BB68):
    want = base + (cls << 6)
    for o in ops:
        a = o.get("addr")
        if isinstance(a, str) and int(a, 16) == want:
            print(o["hex"])
PY
  A=$(sed -n 1p "$T/row"); B=$(sed -n 2p "$T/row")
  [ -n "$A" ] && [ -n "$B" ] || { fail "$d: no authored voice rows found"; continue; }
  $DEC ladder-hex "$A" "$B" --stages "$VJ" 0x26771e 0x26775a > "$T/l.txt" 2>&1
  n=$(sed -n 's/^  \([0-9]*\) out-of-range entries$/\1/p' "$T/l.txt")
  odd=$(grep -c 'OUT OF RANGE' "$T/l.txt" || true)
  other=$(grep 'OUT OF RANGE' "$T/l.txt" | grep -vc 'class 0x13  stage 0x18' || true)
  say "  $d class $cls: $n out of range, $other not the known class-0x13/stage-0x18 shape"
  [ "$other" = 0 ] || fail "$d carries an out-of-range entry that is NOT #92's shape"
  case "$d" in
    build/don_m14) [ "$n" = 0 ] || fail "donovan must be clean, got $n" ;;
    *)            [ "$n" = 4 ] || fail "$d: expected 4 (the #92 bytes), got $n" ;;
  esac
done

echo
if [ "$rc" = 0 ]; then
  echo "PASS: the stage-banner value space decodes, and every out-of-range"
  echo "      authored entry is #92's single known shape."
else
  echo "FAIL: see above."
fi
exit $rc
