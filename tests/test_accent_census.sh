#!/bin/sh
# test_accent_census.sh — the accent/march census (14z-63, phase 3 item
# 6, the 62k-class audit): every path that can resolve a weapon-accent
# from the march family must be thunked on a variant-id build.
#
# MECHANISM. The accent march reads the 0x39A900 family; the static
# slots T0/T1 (0x39FBE0/0x39FC00) hold the HOST's punch-color rows and
# are vanilla on variant builds — any un-thunked family consumer that
# serves a TENANT surface shows host/grey colors (the 62k class). The
# census (measured 14z-63): the vanilla image contains EXACTLY FOUR
# family-base operand references (0x2AD82/0x2AD94/0x2B342/0x2B7E8 —
# the accent_color_aware_0..3 sites) and ZERO direct T0/T1 operand
# references. The venue sweep half of the audit lives in STATE 14z-63
# (every tenant accent surface measured or playtest-confirmed; the
# continue screen has no character surface).
#
#   1. STATIC CENSUS — the vanilla opcode image has exactly the four
#      known family-base sites and no direct slot references (a fifth
#      site appearing = a new consumer to audit; one vanishing = the
#      map moved).
#   2. VARIANT ROUTING — a variant-id build's patch routes ALL FOUR
#      sites (jsr thunks).
#   3. NEGATIVE CONTROL — a patch stripped of one route FAILS.
#
# Usage: ROMDIR=... tests/test_accent_census.sh [outbase]
set -eu
ROMDIR="${ROMDIR:?set ROMDIR}"
REPO="$(cd "$(dirname "$0")/.." && pwd)"
. "$REPO/tests/lib/decrypt_cache.sh"   # GitHub #69
cd "$REPO"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
fail=0

OUTBASE="${1:-}"
if [ -z "$OUTBASE" ]; then
    OUTBASE="$WORK/build"
    echo "== 0. building at --tenant-id 0x13 (fresh) =="
    KEY_SET=vsavj GEN_FLAGS="--allow-plausible --tripwire-open \
--profile cps2-wide-v1 --tenant-id 0x13" \
        tools/build_donovan.sh 6 "$OUTBASE" > "$WORK/build.log" 2>&1 || {
        echo "FAIL: build did not complete"; tail -20 "$WORK/build.log"
        exit 1; }
    tail -2 "$WORK/build.log" | sed 's/^/  /'
fi

OPC="$WORK/vsavj_op.bin"
decrypt_view vsavj "$OPC"

echo "== 1. static census: family-base + slot references =="
python3 - "$OPC" > "$WORK/census.txt" <<'PY' || {
import sys
img = open(sys.argv[1], "rb").read()
SITES = {0x2AD82, 0x2AD94, 0x2B342, 0x2B7E8}
def hits(pat):
    out, st = [], 0
    while True:
        i = img.find(pat, st)
        if i < 0:
            return out
        out.append(i - 2)   # operand follows the 2-byte movea/lea opcode
        st = i + 1
fam = hits(bytes.fromhex("0039a900"))
assert set(fam) == SITES, \
    f"family-base sites {sorted(hex(x) for x in fam)} != the frozen four"
for slot in ("0039fbe0", "0039fc00"):
    s = hits(bytes.fromhex(slot))
    assert not s, f"direct slot 0x{slot} reference(s) at {s}"
print(f"CENSUS 4 family-base sites (frozen), 0 direct slot refs")
PY
    echo "FAIL: census:"; sed 's/^/  /' "$WORK/census.txt"; exit 1; }
sed 's/^/  ok: /' "$WORK/census.txt"

echo "== 2. variant routing: all four sites thunked =="
python3 - "$OUTBASE" > "$WORK/routes.txt" <<'PY' || {
import json, sys
p = json.load(open(sys.argv[1] + "/patch/patch.json"))
ops = p["ops"] if isinstance(p, dict) and "ops" in p else p
for site in (0x2AD82, 0x2AD94, 0x2B342, 0x2B7E8):
    hit = [o for o in ops if o.get("op") == "code"
           and int(o.get("addr"), 16) == site]
    assert len(hit) == 1 and hit[0]["hex"].startswith("4eb9"), \
        f"site {site:#x} not jsr-routed: {hit}"
print("ROUTES 4/4 jsr-routed")
PY
    echo "FAIL: routing:"; sed 's/^/  /' "$WORK/routes.txt"; exit 1; }
sed 's/^/  ok: /' "$WORK/routes.txt"

echo "== 3. negative control =="
mkdir -p "$WORK/neg/patch"
python3 - "$OUTBASE" "$WORK/neg" <<'PY'
import json, sys
p = json.load(open(sys.argv[1] + "/patch/patch.json"))
ops = p["ops"] if isinstance(p, dict) and "ops" in p else p
kept = [o for o in ops
        if not (o.get("op") == "code" and o.get("addr") == "0x2b7e8")]
if isinstance(p, dict) and "ops" in p:
    p["ops"] = kept
else:
    p = kept
json.dump(p, open(sys.argv[2] + "/patch/patch.json", "w"))
PY
if python3 - "$WORK/neg" > /dev/null 2>&1 <<'PY'
import json, sys
p = json.load(open(sys.argv[1] + "/patch/patch.json"))
ops = p["ops"] if isinstance(p, dict) and "ops" in p else p
for site in (0x2AD82, 0x2AD94, 0x2B342, 0x2B7E8):
    hit = [o for o in ops if o.get("op") == "code"
           and int(o.get("addr"), 16) == site]
    assert len(hit) == 1 and hit[0]["hex"].startswith("4eb9")
PY
then
    echo "  FAIL: a patch missing one route PASSED"
    fail=1
else
    echo "  ok: a stripped route is caught"
fi

if [ "$fail" -ne 0 ]; then
    echo "FAIL: accent census gate"
    exit 1
fi
echo "PASS: accent census gate (4 frozen family-base sites, 0 direct"
echo "      slot refs, all four jsr-routed on the variant build)"
