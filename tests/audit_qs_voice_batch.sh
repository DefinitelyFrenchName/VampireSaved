#!/bin/sh
# audit_qs_voice_batch.sh — THE VOICE-BATCH KEYON A/B (14z-86, on-demand,
# ~8 min, 2 parallel MAME runs).
#
# Builds the qs_songs voice batch onto a scratch copy of the canonical
# WIDE overlay (or verifies a given BUILD's romset directly), then sweeps
# EVERY authored voice id on ours and every scoped vs2 id on native
# vsav2 (test-mode venue, 240-frame isolation spacing) and compares the
# whole-run keyon multisets via tools/check_qs_voice_batch.py: no native
# (FROZEN EXCEPTION, GitHub #93, maintainer-ruled 2026-08-19: the bank-108
# inclusive-endpoint source difference — vsav 0xFF / vsav2 0x00 at 0x6C5000,
# byte-verified per run, QS_BATCH_STRICT=1 re-arms; upgrade path = the
# tenant-only authored copy, option C on the issue)
# signature missing, nothing ours plays foreign to vs2's sample library,
# counts within tolerance. Static-side correctness (verbatim songs,
# authored records/T7, vanilla-span identity) is build_qs_songs.py's own
# refusal set + test_qs_songs.sh.
#
# Verdict control: a corrupted byte in the packed extension member must
# flip the verdict (foreign signature) — run on a doctored copy.
#
# Usage: ROMDIR=... tests/audit_qs_voice_batch.sh [builddir]
#   builddir given  -> verify that build's vsavjw.zip in place
#   no builddir     -> self-build onto a scratch overlay copy
set -u
REPO="$(cd "$(dirname "$0")/.." && pwd)"
ROMDIR="${ROMDIR:?set ROMDIR}"
WIDE_BIN="${MAME_BIN:-$HOME/.cache/vampire-saved/mame/cps2}"
[ -x "$WIDE_BIN" ] || { echo "SKIP: no WIDE MAME binary"; exit 0; }
export REPO ROMDIR
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT
fail() { echo "FAIL: $*"; exit 1; }

mkdir -p "$W/rp" "$W/ours" "$W/native"
# THE ID INVENTORY MUST COME FROM THE ARTIFACT UNDER TEST (14z-94, GitHub
# #89). It used to attempt `build_qs_songs.py --dry-run` — an option that has
# never existed, so argparse exited 2 — suppress that with `|| true`, and then
# rebuild a ledger from the canonical build/wide0 overlay. That sweeps TODAY'S
# manifest ids against a possibly older supplied build and reports the result
# as a verdict on it. tools/qs_ledger.py now refuses unless the ledger's
# fingerprint matches the romset it is handed.
if [ -n "${1:-}" ]; then
    cp "$1/rompath/vsavjw.zip" "$W/rp/vsavjw.zip" || fail "no romset in $1"
    LEDGER="$1/rompath/vsavjw.zip.ledger.json"
else
    [ -f "$REPO/build/wide0/rompath/vsavjw.zip" ] || {
        echo "SKIP: no canonical overlay"; exit 0; }
    cp "$REPO/build/wide0/rompath/vsavjw.zip" "$W/rp/vsavjw.zip"
    python3 "$REPO/tools/build_qs_songs.py" "$W/rp/vsavjw.zip" \
        "$ROMDIR/vsav2.zip" --vsav "$ROMDIR/vsav.zip" \
        --ledger "$W/ledger.json" > "$W/build.log" || {
        tail -5 "$W/build.log"; fail "builder errored"; }
    LEDGER="$W/ledger.json"
fi
python3 "$REPO/tools/qs_ledger.py" "$W/rp/vsavjw.zip" --ledger "$LEDGER" \
    --print both > "$W/ids.txt" || fail "ledger not bound to the artifact"
sed -n '2p' "$W/ids.txt" > "$W/native.txt"; sed -n '1p' "$W/ids.txt" > "$W/ours.txt"
OURS="$(cat "$W/ours.txt")"
NATIVE="$(cat "$W/native.txt")"

( cd "$W/ours" && ROMDIR="$ROMDIR" MAME_BIN="$WIDE_BIN" \
  MAME_ROMPATH="$W/rp;$ROMDIR" MAME_SANDBOX="$W/ours/sb" \
  REPLAY="$REPO/tests/replays/06_test_mode.rpl" IDLIST="$OURS" STEP=240 \
  TRACE_OUT=sweep.txt FRAMES=21000 \
  "$REPO/tools/run_mame.sh" vsavjw \
  -autoboot_script "$REPO/tests/lua/qs_sweep.lua" > out 2>&1 ) &
( cd "$W/native" && ROMDIR="$ROMDIR" MAME_SANDBOX="$W/native/sb" \
  REPLAY="$REPO/tests/replays/06_test_mode.rpl" IDLIST="$NATIVE" STEP=240 \
  TRACE_OUT=sweep.txt FRAMES=21000 \
  "$REPO/tools/run_mame.sh" vsav2 \
  -autoboot_script "$REPO/tests/lua/qs_sweep.lua" > out 2>&1 ) &
wait
for leg in ours native; do
    [ -s "$W/$leg/sweep.txt" ] || { tail -5 "$W/$leg/out"; fail "$leg leg dead"; }
done
python3 "$REPO/tools/check_qs_voice_batch.py" "$W/ours/sweep.txt" \
    "$W/native/sweep.txt" "$W/rp/vsavjw.zip" --romdir "$ROMDIR" \
    || fail "keyon multiset A/B"

# THE FROZEN #93 EXCEPTION IS LOAD-BEARING (maintainer-ruled 2026-08-19):
# QS_BATCH_STRICT=1 disarms it, and on today's builds that MUST go red on
# exactly the known bank-108 endpoint pair — a strict run that passes would
# mean the exception is forgiving nothing, i.e. either the source
# difference vanished (re-measure, then retire the exception) or the
# checker stopped seeing it (instrument decay). Either way: stop and look.
QS_BATCH_STRICT=1 python3 "$REPO/tools/check_qs_voice_batch.py" \
    "$W/ours/sweep.txt" "$W/native/sweep.txt" "$W/rp/vsavjw.zip" \
    --romdir "$ROMDIR" > "$W/strict.txt" 2>&1 && {
    cat "$W/strict.txt"
    fail "STRICT control did not fire — the frozen #93 exception is forgiving nothing (see header)"; }
grep -q "foreign (ours-only): 1  missing (native-only): 1" "$W/strict.txt" || {
    cat "$W/strict.txt"
    fail "STRICT control fired on something OTHER than the known #93 pair"; }
echo "  ok: strict control fired on exactly the frozen #93 pair"

# verdict control: corrupt one packed sample byte -> must flip to foreign
python3 - "$W" <<'PY' || exit 1
import sys, zipfile, subprocess, os
w = sys.argv[1]
repo = os.environ["REPO"]; romdir = os.environ["ROMDIR"]
src = zipfile.ZipFile(f"{w}/rp/vsavjw.zip")
data = {n: src.read(n) for n in src.namelist()}
ext = bytearray(data["vsw.21m"])
if not any(ext):
    print("  note: no packed content in this romset — control vacuous, FAIL")
    sys.exit(1)
i = next(i for i, b in enumerate(ext) if b)
ext[i] ^= 0x55
data["vsw.21m"] = bytes(ext)
with zipfile.ZipFile(f"{w}/bad.zip", "w") as z:
    for n, b in data.items():
        z.writestr(n, b)
r = subprocess.run([sys.executable, f"{repo}/tools/check_qs_voice_batch.py",
                    f"{w}/ours/sweep.txt", f"{w}/native/sweep.txt",
                    f"{w}/bad.zip", "--romdir", romdir],
                   capture_output=True, text=True)
if r.returncode == 0:
    print("  CONTROL DEAD: corrupted packed sample still passed")
    sys.exit(1)
print("  ok: verdict control fired (corrupted sample -> foreign)")
PY
[ $? -eq 0 ] || exit 1

echo "PASS: voice-batch keyon A/B — every native signature keyed by ours,"
echo "      nothing foreign to vs2's library, counts within tolerance"
