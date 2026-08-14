#!/bin/sh
# audit_qs_voice_wav.sh — THE EAR-LEVEL VOICE A/B (14z-86, on-demand,
# ~12 min, 2 MAME runs with -wavwrite).
#
# Captures the full voice-id sweep as AUDIO on ours and native vsav2 and
# compares per-window RMS + high-band energy (tools/check_qs_voice_wav.py).
# This instrument exists because it CAUGHT a real defect every other gate
# passed: sample windows packed across a bank's 0x8000 offset truncate at
# once (the DSP compares pointers SIGNED 16-bit) — registers, records and
# member bytes were all "correct", only the AUDIO was wrong. The
# register/content gate (audit_qs_voice_batch.sh) and this one answer
# different questions; keep both.
#
# Verdict control: a synthetically truncated window in a COPY of the ours
# capture must fire the suspect verdict.
#
# Usage: ROMDIR=... tests/audit_qs_voice_wav.sh [builddir]
set -u
REPO="$(cd "$(dirname "$0")/.." && pwd)"; export REPO
ROMDIR="${ROMDIR:?set ROMDIR}"; export ROMDIR
WIDE_BIN="${MAME_BIN:-$HOME/.cache/vampire-saved/mame/cps2}"
[ -x "$WIDE_BIN" ] || { echo "SKIP: no WIDE MAME binary"; exit 0; }
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT
fail() { echo "FAIL: $*"; exit 1; }

mkdir -p "$W/rp" "$W/ours" "$W/native"
if [ -n "${1:-}" ]; then
    cp "$1/rompath/vsavjw.zip" "$W/rp/vsavjw.zip" || fail "no romset in $1"
else
    [ -f "$REPO/build/wide0/rompath/vsavjw.zip" ] || {
        echo "SKIP: no canonical overlay"; exit 0; }
    cp "$REPO/build/wide0/rompath/vsavjw.zip" "$W/rp/vsavjw.zip"
    python3 "$REPO/tools/build_qs_songs.py" "$W/rp/vsavjw.zip" \
        "$ROMDIR/vsav2.zip" --vsav "$ROMDIR/vsav.zip" \
        --ledger "$W/ledger.json" > "$W/build.log" || fail "builder errored"
fi
[ -f "$W/ledger.json" ] || {
    cp "$REPO/build/wide0/rompath/vsavjw.zip" "$W/scratch.zip"
    python3 "$REPO/tools/build_qs_songs.py" "$W/scratch.zip" \
        "$ROMDIR/vsav2.zip" --vsav "$ROMDIR/vsav.zip" \
        --ledger "$W/ledger.json" > /dev/null || fail "ledger derivation"
}
OURS="$(python3 -c "
import json; l = json.load(open('$W/ledger.json'))
print(','.join('%x' % v['id'] for v in l['voices']))")"
NATIVE="$(python3 -c "
import json; l = json.load(open('$W/ledger.json'))
print(','.join('%x' % v['vs2_id'] for v in l['voices']))")"

( cd "$W/ours" && MAME_BIN="$WIDE_BIN" MAME_ROMPATH="$W/rp;$ROMDIR" \
  MAME_SANDBOX="$W/ours/sb" REPLAY="$REPO/tests/replays/06_test_mode.rpl" \
  IDLIST="$OURS" STEP=240 TRACE_OUT=s.txt FRAMES=21000 \
  "$REPO/tools/run_mame.sh" vsavjw \
  -autoboot_script "$REPO/tests/lua/qs_sweep.lua" \
  -sound auto -wavwrite "$W/ours/voices.wav" > out 2>&1 ) &
( cd "$W/native" && MAME_SANDBOX="$W/native/sb" \
  REPLAY="$REPO/tests/replays/06_test_mode.rpl" \
  IDLIST="$NATIVE" STEP=240 TRACE_OUT=s.txt FRAMES=21000 \
  "$REPO/tools/run_mame.sh" vsav2 \
  -autoboot_script "$REPO/tests/lua/qs_sweep.lua" \
  -sound auto -wavwrite "$W/native/voices.wav" > out 2>&1 ) &
wait
for leg in ours native; do
    [ -s "$W/$leg/voices.wav" ] || { tail -5 "$W/$leg/out"; fail "$leg capture dead"; }
done

python3 "$REPO/tools/check_qs_voice_wav.py" "$W/ours/voices.wav" \
    "$W/native/voices.wav" "$W/ledger.json" || fail "spectral A/B"

# verdict control: truncate one sounding window in a copy -> must fire
python3 - "$W" <<'PY' || exit 1
import json, os, subprocess, sys, wave, struct
w = sys.argv[1]
repo = os.environ["REPO"]
src = wave.open(f"{w}/ours/voices.wav")
params = src.getparams()
raw = bytearray(src.readframes(src.getnframes()))
rate, nch = params.framerate, params.nchannels
led = json.load(open(f"{w}/ledger.json"))
# zero the tail 80% of the first sounding window
f0 = 1050 + 240 * 0
a = int((f0 + 40) / 60 * rate) * nch * 2
b = int((f0 + 200) / 60 * rate) * nch * 2
raw[a:b] = bytes(b - a)
out = wave.open(f"{w}/bad.wav", "wb")
out.setparams(params); out.writeframes(bytes(raw)); out.close()
r = subprocess.run([sys.executable, f"{repo}/tools/check_qs_voice_wav.py",
                    f"{w}/bad.wav", f"{w}/native/voices.wav",
                    f"{w}/ledger.json"], capture_output=True, text=True)
if r.returncode == 0:
    print("  CONTROL DEAD: truncated window not flagged"); sys.exit(1)
print("  ok: verdict control fired (synthetic truncation -> suspect)")
PY
[ $? -eq 0 ] || exit 1

echo "PASS: ear-level voice A/B — per-window energy/spectral profile"
echo "      matches native for every sounding pair"
