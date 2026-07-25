#!/bin/sh
# test_suite_dispatch.sh — ground truth for the auto-detecting runner's
# dispatch pieces (no emulator needed; the emulator-side behaviors they gate
# are proven by test_m2_repoint.sh and the suite itself):
#   1. build_fingerprint: vanilla rompath -> 'vsavj'; a patched build ->
#      loud UNREGISTERED failure (exit 2).
#   2. check_diverge verdicts on synthetic logs: divergence at exactly the
#      expected frame PASSes; early divergence, no divergence, and a missing
#      base log all FAIL.
#
# Usage: ROMDIR=... tests/test_suite_dispatch.sh
set -eu

ROMDIR="${ROMDIR:?set ROMDIR}"
REPO="$(cd "$(dirname "$0")/.." && pwd)"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
fail=0

# --- 1. fingerprint dispatch -------------------------------------------------
got=$(python3 "$REPO/tools/build_fingerprint.py" "$ROMDIR")
if [ "$got" = "vsavj" ]; then
    echo "  ok: vanilla rompath -> expectation set 'vsavj'"
else
    echo "FAIL: vanilla fingerprint mapped to '$got'"; fail=1
fi

printf '{"ops":[{"op":"poke16","addr":"0xBF800","val":"0x4AFC"}]}' > "$WORK/p.json"
python3 "$REPO/tools/patch_prg.py" "$ROMDIR/vsavj.zip" "$WORK/prg" --patch "$WORK/p.json" > /dev/null
ROMDIR="$ROMDIR" "$REPO/tools/pack_build.sh" "$WORK/prg" "$WORK/rompath" > /dev/null
rc=0
python3 "$REPO/tools/build_fingerprint.py" "$WORK/rompath;$ROMDIR" > /dev/null 2>&1 || rc=$?
if [ "$rc" = "2" ]; then
    echo "  ok: unregistered patched build fails loudly (exit 2)"
else
    echo "FAIL: unregistered build rc=$rc (expected 2)"; fail=1
fi

# --- 2. check_diverge verdicts on synthetic logs -----------------------------
EXPROOT="$WORK/expected"
mkdir -p "$EXPROOT/base/logs"
python3 - "$EXPROOT" "$WORK" <<'PY'
import sys
exproot, work = sys.argv[1], sys.argv[2]
base = [f"{i} {i:016x}" for i in range(1, 101)]
open(f"{exproot}/base/logs/case.log", "w").write("\n".join(base + ["END 100"]))
exact = list(base); exact[41] = "42 deadbeefdeadbeef"        # diverges at 42
open(f"{work}/exact.log", "w").write("\n".join(exact + ["END 100"]))
early = list(base); early[9] = "10 deadbeefdeadbeef"         # diverges at 10
open(f"{work}/early.log", "w").write("\n".join(early + ["END 100"]))
open(f"{work}/same.log", "w").write("\n".join(base + ["END 100"]))
PY
printf 'base 42' > "$WORK/case.diverge"

cd_run() { python3 "$REPO/tools/check_diverge.py" "$1" "$WORK/case.diverge" "$EXPROOT" > /dev/null 2>&1; }

if cd_run "$WORK/exact.log"; then
    echo "  ok: divergence at exactly 42 -> PASS"
else
    echo "FAIL: exact-divergence case rejected"; fail=1
fi
if cd_run "$WORK/early.log"; then
    echo "FAIL: early divergence accepted"; fail=1
else
    echo "  ok: early divergence -> FAIL"
fi
if cd_run "$WORK/same.log"; then
    echo "FAIL: no-divergence accepted"; fail=1
else
    echo "  ok: no divergence -> FAIL"
fi
printf 'nosuchset 42' > "$WORK/case.diverge"
if cd_run "$WORK/exact.log"; then
    echo "FAIL: missing base log accepted"; fail=1
else
    echo "  ok: missing base log -> FAIL"
fi

[ "$fail" = 0 ] && echo "PASS: suite dispatch verdicts validated" \
    || { echo "SUITE RED"; exit 1; }
