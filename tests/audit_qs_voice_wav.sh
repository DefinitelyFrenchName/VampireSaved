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
#
# HANDOFF's gate-index note, moved into this header 14z-123 (verbatim; the
# documentation pass ruled a gate's WHY lives in the gate):
#   14z-86 (~12 min, 2 -wavwrite runs): THE EAR-LEVEL VOICE A/B — per-window
#   RMS/high-band vs native audio. Exists because it CAUGHT the half-bank
#   truncation the register/content gates were BLIND to (signed DSP pointer
#   compare — equal data, different behavior). Synthetic-truncation verdict
#   control. Keep BOTH gates
set -u
REPO="$(cd "$(dirname "$0")/.." && pwd)"; export REPO
ROMDIR="${ROMDIR:?set ROMDIR}"; export ROMDIR
WIDE_BIN="${MAME_BIN:-$HOME/.cache/vampire-saved/mame/cps2}"
[ -x "$WIDE_BIN" ] || { echo "SKIP: no WIDE MAME binary"; exit 0; }
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT
fail() { echo "FAIL: $*"; exit 1; }

mkdir -p "$W/rp" "$W/ours" "$W/native"
# Same binding rule as audit_qs_voice_batch.sh — see tools/qs_ledger.py and
# GitHub #89. This audit had the identical build/wide0 fallback: a supplied
# build with no ledger got its voice id list rebuilt from the canonical
# overlay, i.e. from current manifest state, and the WAV verdict was then
# attributed to the supplied artifact.
if [ -n "${1:-}" ]; then
    cp "$1/rompath/vsavjw.zip" "$W/rp/vsavjw.zip" || fail "no romset in $1"
    LEDGER="$1/rompath/vsavjw.zip.ledger.json"
else
    [ -f "$REPO/build/wide0/rompath/vsavjw.zip" ] || {
        echo "SKIP: no canonical overlay"; exit 0; }
    cp "$REPO/build/wide0/rompath/vsavjw.zip" "$W/rp/vsavjw.zip"
    python3 "$REPO/tools/build_qs_songs.py" "$W/rp/vsavjw.zip" \
        "$ROMDIR/vsav2.zip" --vsav "$ROMDIR/vsav.zip" \
        --ledger "$W/ledger.json" > "$W/build.log" || fail "builder errored"
    LEDGER="$W/ledger.json"
fi
python3 "$REPO/tools/qs_ledger.py" "$W/rp/vsavjw.zip" --ledger "$LEDGER" \
    --print both > "$W/ids.txt" || fail "ledger not bound to the artifact"
OURS="$(sed -n '1p' "$W/ids.txt")"
NATIVE="$(sed -n '2p' "$W/ids.txt")"

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

# verdict control: truncate one sounding window in a copy -> must fire.
# Zero the HEAD (the loud attack), not the tail: RMS is attack-dominated,
# and a tail-zeroing control barely moves the metric — the first version
# of this control could not fail (RH-9; caught by its own dead-control
# check on the first shipped-artifact run, 14z-86)
#
# RUN AT BOTH ENDS OF THE SWEEP (14z-94, GitHub #85). It used to truncate
# index 0 only — the window where frame->time conversion error is smallest,
# so it could not detect late-window misalignment at all. With the 60 Hz
# literal that error reached 2.03 s by index 79 against a 3.35 s window, and
# this control would still have gone green. The window maths now comes from
# check_qs_voice_wav.window() rather than a second copy of the constants,
# so the control cannot compute a different window than the checker.
#
# BOTH ENDS ARE THE LAST *SOUNDING* WINDOWS, NOT THE LAST INDICES (fixed
# 14z-129 — the control had been DEAD at the late end and said so).
# THE MEASUREMENT: the checker skips any window both legs leave silent
# (`mo[0] < 50 and mn[0] < 50`), because there is nothing there to compare.
# Zeroing such a window therefore changes nothing and no suspect can fire.
# Voice 80 — the last index, vs2 id 0x733 — is RMS **1.0 on BOTH legs**, and
# it is not alone: 7 of the 81 windows are silent that way (indices 3, 11,
# 64, 65, 68, 69, 80). So the control was asking the checker to notice the
# truncation of silence. NOT A PORT DEFECT: ours equals native to the decimal
# in every window, silent ones included — the ids simply do not sound in this
# sweep. The control now picks the last index that actually SOUNDS (79 today)
# and asserts it is still LATE in the sweep, because "late" is the whole
# point of the second end ([VSP-19]: a control that cannot fail asserts
# nothing, and one that quietly moved to the near end asserts the wrong
# thing).
python3 - "$W" <<'PY' || exit 1
import json, os, subprocess, sys, wave
w = sys.argv[1]
repo = os.environ["REPO"]
sys.path.insert(0, os.path.join(repo, "tools"))
from check_qs_voice_wav import window, CPS_HZ

led = json.load(open(f"{w}/ledger.json"))
n = len(led["voices"])
src = wave.open(f"{w}/ours/voices.wav")
params = src.getparams()
base = bytearray(src.readframes(src.getnframes()))
rate, nch = params.framerate, params.nchannels
print(f"  (control at {CPS_HZ:.4f} Hz; sweep has {n} voices)")

# WHICH WINDOWS CAN THE CHECKER EVEN SEE? Exactly the ones it does not skip,
# so the test uses the checker's own rule rather than a second copy of it.
from check_qs_voice_wav import load as _load, metrics as _metrics
_ro, _so = _load(f"{w}/ours/voices.wav")
_rn, _sn = _load(f"{w}/native/voices.wav")
sounding = []
for _i in range(n):
    _a, _b = window(_i, _ro)
    if not (_metrics(_so, _a, _b)[0] < 50 and _metrics(_sn, _a, _b)[0] < 50):
        sounding.append(_i)
if not sounding:
    print("  CONTROL UNRUNNABLE: no window sounds on either leg — the capture"
          " is not of the sweep it claims to be")
    sys.exit(1)
print(f"  ({len(sounding)} of {n} windows sound; the checker skips the rest)")

# The late end must stay LATE, or the second control silently becomes a
# duplicate of the first (GitHub #85 is exactly that failure).
LATE = sounding[-1]
if LATE < int(n * 0.9):
    print(f"  CONTROL DEGRADED: the last SOUNDING window is index {LATE} of"
          f" {n} — too early to exercise late-window drift. Something changed"
          f" the sweep; re-measure before touching this threshold.")
    sys.exit(1)

bad = 0
for tag, i in (("first", sounding[0]), ("last", LATE)):
    raw = bytearray(base)
    a, b = window(i, rate, frames=160)
    a, b = a * nch * 2, b * nch * 2
    if b > len(raw):
        print(f"  CONTROL UNRUNNABLE ({tag}, voice {i}): window ends at sample"
              f" {b//(nch*2)} but the capture is only {len(raw)//(nch*2)} —"
              f" the capture is too short for the sweep it claims to cover")
        bad = 1; continue
    raw[a:b] = bytes(b - a)
    wf = f"{w}/bad_{tag}.wav"
    out = wave.open(wf, "wb")
    out.setparams(params); out.writeframes(bytes(raw)); out.close()
    r = subprocess.run([sys.executable, f"{repo}/tools/check_qs_voice_wav.py",
                        wf, f"{w}/native/voices.wav", f"{w}/ledger.json"],
                       capture_output=True, text=True)
    if r.returncode == 0:
        print(f"  CONTROL DEAD ({tag}, voice {i}): truncated window not flagged")
        bad = 1
    else:
        print(f"  ok: verdict control fired at the {tag} voice (index {i})")
sys.exit(bad)
PY
[ $? -eq 0 ] || exit 1

echo "PASS: ear-level voice A/B — per-window energy/spectral profile"
echo "      matches native for every sounding pair"
