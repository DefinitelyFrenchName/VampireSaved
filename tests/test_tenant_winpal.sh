#!/bin/sh
# test_tenant_winpal.sh — the variant-id WIN-SCREEN palette (14z-63,
# phase 3 item 5): a tenant winning a 2P match must get its OWN vs2
# win palette, and a vanilla winner must get the untouched vanilla pool.
#
# MECHANISM (measured; STATE 14z-63 / patch_notes addendum 3). The 2P
# victory screen's palette load at PRG:0x5F1B6 computes
# pool + (color*17 + winner_id)*0xA0 with the winner id UNMASKED in d6
# (ids 0x12/0x18 have their own branches — the reserved pair again); at
# 0x13 the index lands in the wrong color's slices. The fix is the
# sparse-block design: a wide_ext block laid out at the VANILLA color
# stride (0xAA0) carrying only the tenant's 8 five-row sets, plus a
# thunk at the base load (d6==TT -> a0 = block - TT*0xA0, else the
# displaced movea re-executes). The ARCADE win-quote screen is a
# DIFFERENT family (62j) and never runs this site — measured; only 2P
# victories reach it, hence the two 2P replays.
#
#   1. STATIC — the patch carries the site jsr, the thunk (with the
#      rebase re-derived from the block allocation), and 8 sparse data
#      ops whose bytes equal vs2's sets (re-read from the vs2 image).
#   2. NEGATIVE CONTROL — a patch stripped of the site op FAILS.
#   3. RUNTIME — replay 61 (tenant beats Victor): victory rows
#      0x15-0x19 == vs2 Donovan color-0 set (F000-alpha), frames
#      5500 AND 5700. Replay 62 (Victor beats the tenant): rows ==
#      the VANILLA pool slice (color 0, id 3) at frame 5300 — the
#      else path serves untouched vanilla bytes.
#
# Usage: ROMDIR=... tests/test_tenant_winpal.sh [outbase]
# Env: MAME_WIDE_BIN (default ~/.cache/vampire-saved/mame/cps2);
#      SKIP_RUNTIME=1 skips section 3 (two ~6k-frame MAME runs).
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

decrypt_view vsav2 "$WORK/vs2_op.bin" "$WORK/vs2_data.bin"

echo "== 1. static: site + thunk + sparse block re-derived =="
python3 - "$OUTBASE" "$WORK/vs2_data.bin" > "$WORK/static.txt" <<'PY' || {
import json, sys
out, vs2p = sys.argv[1], sys.argv[2]
vs2 = open(vs2p, "rb").read()
p = json.load(open(out + "/patch/patch.json"))
ops = p["ops"] if isinstance(p, dict) and "ops" in p else p
SITE, TT, UNIT, CSTRIDE = 0x5F1B6, 0x13, 0xA0, 0xAA0
site_ops = [o for o in ops if o.get("op") == "code"
            and int(o.get("addr"), 16) == SITE]
assert len(site_ops) == 1 and site_ops[0]["hex"].startswith("4eb9"), \
    f"site op: {site_ops}"
tk = int(site_ops[0]["hex"][4:12], 16)
tk_ops = [o for o in ops if o.get("op") == "code"
          and int(o.get("addr"), 16) == tk]
assert len(tk_ops) == 1, f"thunk op at {tk:#x}: {tk_ops}"
body = tk_ops[0]["hex"]
assert body.startswith(f"0c06{TT:04x}6608207c"), f"thunk head: {body[:20]}"
rebase = int(body[16:24], 16)
assert body[24:] == "4e75207c003ad7004e75", f"thunk tail: {body[24:]}"
blk = rebase + TT * UNIT
n = 0
for c in range(8):
    want = vs2[0x3C365C + c * 0xB40:0x3C365C + c * 0xB40 + UNIT].hex()
    hit = [o for o in ops if o.get("op") == "data"
           and int(o.get("addr"), 16) == blk + c * CSTRIDE]
    assert len(hit) == 1 and hit[0]["hex"] == want, \
        f"sparse slice {c} at {blk + c*CSTRIDE:#x}: wrong or missing"
    n += 1
print(f"SITE {SITE:#x} -> thunk {tk:#x} rebase {rebase:#x} block {blk:#x}")
print(f"SLICES {n}")
print("OK")
PY
    echo "FAIL: static check:"; sed 's/^/  /' "$WORK/static.txt"; exit 1; }
sed 's/^/  ok: /' "$WORK/static.txt"

echo "== 2. negative control =="
mkdir -p "$WORK/neg/patch"
python3 - "$OUTBASE" "$WORK/neg" <<'PY'
import json, sys
p = json.load(open(sys.argv[1] + "/patch/patch.json"))
ops = p["ops"] if isinstance(p, dict) and "ops" in p else p
kept = [o for o in ops
        if not (o.get("op") == "code" and o.get("addr") == "0x5f1b6")]
if isinstance(p, dict) and "ops" in p:
    p["ops"] = kept
else:
    p = kept
json.dump(p, open(sys.argv[2] + "/patch/patch.json", "w"))
PY
if python3 - "$WORK/neg" "$WORK/vs2_data.bin" > /dev/null 2>&1 <<'PY'
import json, sys
p = json.load(open(sys.argv[1] + "/patch/patch.json"))
ops = p["ops"] if isinstance(p, dict) and "ops" in p else p
site_ops = [o for o in ops if o.get("op") == "code"
            and int(o.get("addr"), 16) == 0x5F1B6]
assert len(site_ops) == 1
PY
then
    echo "  FAIL: a patch without the site op PASSED"
    fail=1
else
    echo "  ok: a stripped site op is caught"
fi

echo "== 3. runtime: both thunk paths on real 2P victories =="
if [ "${SKIP_RUNTIME:-0}" = 1 ]; then
    echo "  SKIPPED (SKIP_RUNTIME=1)"
else
    WIDE_BIN="${MAME_WIDE_BIN:-$HOME/.cache/vampire-saved/mame/cps2}"
    "$WIDE_BIN" -listfull vsavjw > /dev/null 2>&1 || {
        echo "FAIL: $WIDE_BIN does not know vsavjw (tools/setup_mame.sh)"
        exit 1; }
    run() {  # run <tag> <replay> <dumpspec> <frames>
        mkdir -p "$WORK/$1"
        DUMPS="$3" CHECKSUM_OUT="$WORK/$1/cks.log" FRAMES="$4" \
        REPLAY="$REPO/tests/replays/$2" \
        MAME_SANDBOX="$WORK/sbx_$1" MAME_BIN="$WIDE_BIN" \
        MAME_ROMPATH="$OUTBASE/rompath;$ROMDIR" \
            tools/run_mame.sh vsavjw \
            -autoboot_script tests/lua/replay.lua > /dev/null 2>&1 || true
    }
    run win 61_tenant_2pwin.rpl \
        "5500:90c2a0-90c33f;5700:90c2a0-90c33f" 5750
    run lose 62_tenant_2plose.rpl "5300:90c2a0-90c33f" 5350
    python3 - "$WORK" "$WORK/vs2_data.bin" <<'PY' || fail=1
import sys
work, vs2p = sys.argv[1], sys.argv[2]
vs2 = open(vs2p, "rb").read()
vj = open("build/out/vsavj_data.bin", "rb").read()
def alpha(b):
    return bytes(((b[i] | 0xF0) if i % 2 == 0 else b[i])
                 for i in range(len(b)))
want_win = alpha(vs2[0x3C365C:0x3C365C + 0xA0])
for fr in (5500, 5700):
    got = open(f"{work}/win/dump_{fr}_90c2a0.bin", "rb").read()[:0xA0]
    assert got == want_win, (
        f"tenant win f{fr}: rows != vs2 Donovan c0 set (head "
        f"{got[:8].hex()})")
want_lose = alpha(vj[0x3AD700 + 3 * 0xA0:0x3AD700 + 3 * 0xA0 + 0xA0])
got = open(f"{work}/lose/dump_5300_90c2a0.bin", "rb").read()[:0xA0]
assert got == want_lose, (
    f"vanilla win f5300: rows != vanilla pool (c0,id3) (head "
    f"{got[:8].hex()})")
print("  ok: tenant win = vs2 set (f5500+f5700); vanilla win = "
      "untouched pool (f5300)")
PY
fi

if [ "$fail" -ne 0 ]; then
    echo "FAIL: tenant win-pal gate"
    exit 1
fi
echo "PASS: tenant win-pal gate (site/thunk/sparse-block re-derived +"
echo "      negative control + both thunk paths measured on real 2P"
echo "      victories)"
