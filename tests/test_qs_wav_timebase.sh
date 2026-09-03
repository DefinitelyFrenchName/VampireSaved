#!/bin/sh
# test_qs_wav_timebase.sh — the WAV audit's frame->time conversion must use
# CPS timing, not 60 Hz (14z-94, GitHub #85). ROM-free, no MAME, ~2 s.
#
# THE DEFECT. tests/lua/qs_sweep.lua schedules injections by emulated FRAME.
# check_qs_voice_wav.py converted those frames to WAV sample offsets at a
# literal 60. CPS-2 runs at 8 MHz / (512 * 262) = 59.637405 Hz, so the error
# accumulates in one direction across the sweep:
#
#     voice  0  frame  1050   60Hz 17.500s   real 17.606s   +0.106s
#     voice 79  frame 20010   60Hz 333.500s  real 335.528s  +2.028s
#
# The window is 200 frames = 3.354 s wide. By the end of an 80-id sweep the
# examined window has slipped more than HALF A WINDOW off the injection it is
# meant to measure, so a late voice that is shortened, delayed or missing can
# be "verified" against residual audio from a neighbouring event.
#
# AND THE CONTROL COULD NOT SEE IT: the audit truncated index 0 only — the
# window where the error is smallest — so the one check that would have
# caught this was aimed at the one place it does not happen.
#
# WHAT IS ASSERTED. The rate is derived from MAME's own constants and matches
# the emulator actually pinned; the drift a 60 Hz reading would introduce is
# larger than a window by the end of the sweep (i.e. the finding is real, not
# a rounding quibble); and the audit's control shares the checker's window
# maths rather than carrying a second copy of the constants.
#
# HANDOFF's review-triage table note, moved into this header 14z-123 (verbatim; the
# documentation pass ruled a gate's WHY lives in the gate):
#   (review-triage, #85) The WAV audit converts frames at the CPS rate
#   (59.6374 Hz), not 60.
set -eu
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
rc=0
fail() { echo "  FAIL: $*"; rc=1; }

echo "== 1. the rate is DERIVED, and matches the pinned MAME's constants =="
python3 - <<'PY' || rc=1
import sys, re, os
sys.path.insert(0, "tools")
from check_qs_voice_wav import CPS_HZ, CPS_PIXEL_CLOCK, CPS_HTOTAL, CPS_VTOTAL

print(f"  ok: {CPS_PIXEL_CLOCK:.0f} / ({CPS_HTOTAL} * {CPS_VTOTAL})"
      f" = {CPS_HZ:.6f} Hz")
if not (59.6 < CPS_HZ < 59.7):
    print(f"  FAIL: {CPS_HZ} is not the CPS refresh rate"); sys.exit(1)

# Bind to the emulator rather than to a number I typed: if the MAME pin ever
# moves and these constants change, this must be re-derived, not assumed.
h = "emu/mame/src/mame/capcom/cps1.h"
if not os.path.exists(h):
    print("  note: MAME submodule not checked out — skipping the cross-check")
    sys.exit(0)
src = open(h).read()
def const(name, pat):
    m = re.search(pat, src)
    return m.group(1) if m else None
pix = const("CPS_PIXEL_CLOCK", r"#define CPS_PIXEL_CLOCK\s+\(XTAL\((\d+'?\d*'?\d*)\)/2\)")
ht  = const("CPS_HTOTAL", r"#define CPS_HTOTAL\s+\((\d+)\)")
vt  = const("CPS_VTOTAL", r"#define CPS_VTOTAL\s+\((\d+)\)")
bad = 0
if pix is not None and int(pix.replace("'", "")) / 2 != CPS_PIXEL_CLOCK:
    print(f"  FAIL: MAME's pixel clock is {pix}, ours implies"
          f" {CPS_PIXEL_CLOCK*2:.0f}"); bad = 1
if ht is not None and int(ht) != CPS_HTOTAL:
    print(f"  FAIL: MAME CPS_HTOTAL={ht}, ours {CPS_HTOTAL}"); bad = 1
if vt is not None and int(vt) != CPS_VTOTAL:
    print(f"  FAIL: MAME CPS_VTOTAL={vt}, ours {CPS_VTOTAL}"); bad = 1
if not bad:
    print("  ok: matches the pinned MAME's cps1.h (htotal/vtotal/pixel clock)")
sys.exit(bad)
PY

echo "== 2. THE FINDING IS REAL — 60 Hz drifts past a whole window =="
python3 - <<'PY' || rc=1
import sys
sys.path.insert(0, "tools")
from check_qs_voice_wav import (window, CPS_HZ, FIRST_FRAME, STEP_FRAMES,
                                WINDOW_FRAMES)
RATE, N = 44100, 80            # the 80-id voice batch
win_s = WINDOW_FRAMES / CPS_HZ
worst = 0
for i in (0, N // 2, N - 1):
    f0 = FIRST_FRAME + STEP_FRAMES * i
    a, _ = window(i, RATE)
    a60 = int(f0 / 60 * RATE)
    drift = (a - a60) / RATE
    worst = max(worst, abs(drift))
    print(f"  voice {i:2d}: real {a/RATE:8.3f}s  60Hz {a60/RATE:8.3f}s"
          f"  drift {drift:+.3f}s")
print(f"  window is {win_s:.3f}s wide; worst drift {worst:.3f}s")
if worst < win_s / 2:
    print("  FAIL: the 60 Hz reading never slips half a window, so this gate")
    print("        is guarding a problem that does not arise — re-check #85")
    sys.exit(1)
print("  ok: by the end of the sweep a 60 Hz window misses its own injection")
sys.exit(0)
PY

echo "== 3. no literal 60 Hz conversion survives in either file =="
if grep -nE '/ *60 *\*' tools/check_qs_voice_wav.py tests/audit_qs_voice_wav.sh; then
    fail "a frame/60 conversion is still present (listed above)"
else
    echo "  ok: neither file converts frames at a literal 60"
fi

echo "== 4. the audit's control SHARES the checker's window maths =="
# A second copy of the constants is how the two drifted apart in the first
# place: the control computed the same wrong window as the checker, so it
# agreed with the bug instead of catching it.
if grep -q "from check_qs_voice_wav import" tests/audit_qs_voice_wav.sh; then
    echo "  ok: the control imports window() from the checker"
else
    fail "the control does not import the checker's window maths"
fi

echo "== 5. and it exercises the LATE end of the sweep, not just index 0 =="
# Asserts the PROPERTY, not a literal (14z-129). This used to grep for
# `("last", n - 1)`, which was true of the code but wrong about the world:
# the last INDEX is silent on both legs (voice 80 is RMS 1.0), the checker
# skips windows where both legs are silent, and the control was therefore
# truncating silence and could never fire. The control now takes the last
# SOUNDING index, so the literal changed while the intent did not — and the
# intent is what this section exists to protect.
_late_ok=1
grep -q '("last", LATE)' tests/audit_qs_voice_wav.sh || _late_ok=0
grep -q 'LATE = sounding\[-1\]' tests/audit_qs_voice_wav.sh || _late_ok=0
if [ "$_late_ok" = 1 ]; then
    echo "  ok: the control truncates the last SOUNDING voice, not just the first"
else
    fail "the control no longer derives a LATE end from the sounding windows —"
    fail "      index 0 alone is the window where the conversion error is"
    fail "      SMALLEST, so it cannot see this class"
fi
# ... and the late end must STAY late, or this section passes while the
# control has quietly become a duplicate of the near one (GitHub #85).
if grep -q 'CONTROL DEGRADED' tests/audit_qs_voice_wav.sh; then
    echo "  ok: and it refuses a LATE index that has drifted early"
else
    fail "nothing stops the derived LATE index drifting to the near end,"
    fail "      which is the #85 failure this section was written for"
fi

echo "== 6. the sweep constants still match tests/lua/qs_sweep.lua =="
python3 - <<'PY' || rc=1
import sys, re
sys.path.insert(0, "tools")
from check_qs_voice_wav import FIRST_FRAME, STEP_FRAMES
lua = open("tests/lua/qs_sweep.lua").read()
m = re.search(r'SWEEP"\)\s*or\s*"(\d+),([0-9a-fA-F]+),(\d+),(\d+)"', lua)
if not m:
    print("  FAIL: cannot find qs_sweep.lua's SWEEP default — the checker's"
          "        FIRST_FRAME can no longer be cross-checked"); sys.exit(1)
first = int(m.group(4))
if first != FIRST_FRAME:
    print(f"  FAIL: qs_sweep.lua starts at frame {first}, the checker assumes"
          f" {FIRST_FRAME} — every window would be offset"); sys.exit(1)
print(f"  ok: first injection frame {first} agrees")
# STEP comes from the audits' STEP=240, not the lua default; check the caller.
aud = open("tests/audit_qs_voice_wav.sh").read()
if f"STEP={STEP_FRAMES}" not in aud:
    print(f"  FAIL: the audit no longer passes STEP={STEP_FRAMES}, so the"
          f" checker's spacing assumption is wrong"); sys.exit(1)
print(f"  ok: the audit still passes STEP={STEP_FRAMES}")
sys.exit(0)
PY

echo
[ "$rc" = 0 ] && echo "PASS: the WAV audit measures on the CPS timebase." \
             || echo "FAIL: see above."
exit $rc
