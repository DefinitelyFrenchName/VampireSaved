#!/bin/sh
# test_tenant_winpal.sh — the variant-id WIN-SCREEN palette (14z-63,
# phase 3 item 5): a tenant winning a 2P match must get its OWN vs2
# win palette, and a vanilla winner must get the untouched vanilla pool.
#
# WHAT: a tenant winning a 2P match gets its OWN vs2 win-screen palette through the sparse
#   block and the TT thunk at the base load, and a vanilla winner still gets the untouched
#   vanilla pool slice through the thunk's else path.
# HOW: static: the site jsr, the thunk with its rebase re-derived, and the 8 sparse data ops
#   equal to vs2's sets; a patch stripped of the site op is the negative control; runtime:
#   replay 61 (tenant beats Victor) and replay 62 (Victor beats the tenant) on MAME with the
#   victory rows read at the KO-traced frames.
# EXPECTS: rows 0x15-0x19 equal to vs2's Donovan colour-0 set on replay 61 and to the
#   vanilla pool slice on replay 62; the stripped patch fails.
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
#      the VANILLA pool slice (color 0, id 3) on the quote screen — FOUND
#      per build since 14z-170 (the KO frame traced, P2's trailing mash
#      dropped, three consecutive samples) — the else path serves untouched
#      vanilla bytes.
#
# Usage: ROMDIR=... tests/test_tenant_winpal.sh [outbase]
# Env: MAME_WIDE_BIN (default ~/.cache/vampire-saved/mame/cps2);
#      SKIP_RUNTIME=1 skips section 3 (two ~6k-frame MAME runs).
#
# HANDOFF's gate-index note, moved into this header 14z-123 (verbatim; the
# documentation pass ruled a gate's WHY lives in the gate):
#   variant-id win-screen palette (14z-63): the sparse block + TT thunk at
#   0x5F1B6; BOTH thunk paths measured on real 2P victories (replays 61/62).
#   Self-builds at 0x13 unless
set -eu
ROMDIR="${ROMDIR:?set ROMDIR}"
# 14z-132: ABSOLUTE. Gates `cd` into work dirs and then compose paths that
# still contain $ROMDIR (e.g. MAME_ROMPATH="...;$ROMDIR"); a RELATIVE value —
# which is how the runners invoke everything (ROMDIR=../ROMS) — then resolves
# against the WORK dir and silently finds no reference members. Kept as a
# VARIABLE (forks set their own); only made absolute, and only if it exists,
# so a gate that means to SKIP on a missing ROMDIR still does.
if [ -d "$ROMDIR" ]; then ROMDIR="$(cd "$ROMDIR" && pwd)"; fi
REPO="$(cd "$(dirname "$0")/.." && pwd)"
. "$REPO/tests/lib/tenant_build.sh"    # GitHub #71
. "$REPO/tests/lib/decrypt_cache.sh"   # GitHub #69
cd "$REPO"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
fail=0

# The build shape lives in tests/lib/tenant_build.sh (GitHub #71): stage,
# profile and tenant id were inline in five gates and all three have moved
# before.
tenant_build_13 "$WORK" "${1:-}" || exit 1

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
    # THE LOSE LEG IS FOUND, NOT FRAME-PINNED (reworked 14z-170): at the M19 freeze the tenants' vs2
    # defense rows made Donovan die ~160 frames earlier in replay 62, so P2's scripted mash (to f5035)
    # landed on the win-quote screen and SKIPPED it — the fixed f5300 then read the next VS screen
    # (snapshots in STATE 14z-170). Pass 1 traces P1's HP to find the KO frame K on THIS build; pass 2
    # replays with P2's inputs dropped after K+10 (the quote screen is not skipped) and samples rows
    # 0x15-0x19 every 25 frames over K+300..K+1100: at least three CONSECUTIVE samples must hold the
    # vanilla pool slice. Measured: merged-m18's don_m22 K=4698, M19's don_m23 K=4538 (pool 5113-5463).
    mkdir -p "$WORK/ko"
    FIELDS="ff8450:w:p1hp" FIELD_OUT="$WORK/ko/f.ft" FIELD_FROM=2400 FIELD_TO=6000 FRAMES=6000 \
    REPLAY="$REPO/tests/replays/62_tenant_2plose.rpl" MAME_SANDBOX="$WORK/sbx_ko" MAME_BIN="$WIDE_BIN" \
    MAME_ROMPATH="$OUTBASE/rompath;$ROMDIR" \
        tools/run_mame.sh vsavjw -autoboot_script tests/lua/field_trace.lua > /dev/null 2>&1 || true
    KO="$(awk '$1=="F" { for (i = 3; i <= NF; i++) if ($i ~ /^p1hp=/) { v = substr($i, 6) + 0; if (v < 0 || v > 32767) { print $2; exit } } }' "$WORK/ko/f.ft")"
    [ -n "$KO" ] || { echo "  FAIL: replay 62: P1 is never KO'd before f6000 — the lose leg's rig is dead"; fail=1; KO=4600; }
    echo "  lose leg: P1 KO at f$KO (pass 1); P2's inputs dropped after f$((KO + 10))"
    awk -v k=$((KO + 10)) '/^[0-9]/ { split($1, r, "-"); if (r[1] > k && $0 ~ /p2=/) next } { print }' \
        "$REPO/tests/replays/62_tenant_2plose.rpl" > "$WORK/lose_cut.rpl"
    LOSE_DUMPS="$(python3 -c "print(';'.join(f'{f}:90c2a0-90c33f' for f in range($KO + 300, $KO + 1101, 25)))")"
    mkdir -p "$WORK/lose"
    DUMPS="$LOSE_DUMPS" CHECKSUM_OUT="$WORK/lose/cks.log" FRAMES=$((KO + 1150)) \
    REPLAY="$WORK/lose_cut.rpl" MAME_SANDBOX="$WORK/sbx_lose" MAME_BIN="$WIDE_BIN" \
    MAME_ROMPATH="$OUTBASE/rompath;$ROMDIR" \
        tools/run_mame.sh vsavjw -autoboot_script tests/lua/replay.lua > /dev/null 2>&1 || true
    python3 - "$WORK" "$WORK/vs2_data.bin" "$KO" <<'PY' || fail=1
import sys, os
work, vs2p, ko = sys.argv[1], sys.argv[2], int(sys.argv[3])
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
frames = list(range(ko + 300, ko + 1101, 25))
hit = [os.path.exists(f"{work}/lose/dump_{f}_90c2a0.bin")
       and open(f"{work}/lose/dump_{f}_90c2a0.bin", "rb").read()[:0xA0] == want_lose for f in frames]
run = best = 0
for h in hit:
    run = run + 1 if h else 0; best = max(best, run)
assert best >= 3, (
    f"vanilla win (KO f{ko}): rows 0x15-0x19 never hold the vanilla pool (c0,id3) "
    f"for 3 consecutive samples over f{frames[0]}..f{frames[-1]} (best run {best})")
first = frames[hit.index(True)]
print(f"  ok: tenant win = vs2 set (f5500+f5700); vanilla win = untouched pool "
      f"(KO f{ko}, pool from f{first}, {sum(hit)} of {len(frames)} samples, best run {best})")
PY
fi

if [ "$fail" -ne 0 ]; then
    echo "FAIL: tenant win-pal gate"
    exit 1
fi
echo "PASS: tenant win-pal gate (site/thunk/sparse-block re-derived +"
echo "      negative control + both thunk paths measured on real 2P"
echo "      victories)"
