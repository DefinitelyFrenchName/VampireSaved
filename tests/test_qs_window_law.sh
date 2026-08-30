#!/bin/sh
# test_qs_window_law.sh — ground truth for the QSound sample-window endpoint
# law (14z-93, GitHub #82). No ROMs, no emulator, ~1s.
#
# THE LAW: a record's `end` offset is played and looped INCLUSIVE (packing
# law #3, 14z-87b). Proven twice — by field width (native windows end at
# 0xFFFF, which an exclusive reading cannot express) and by the sword-plant
# beep, where an exclusive COPY left each packed sample's last played byte
# holding the next blob's first byte, audible as a ~1.8kHz impulse train.
#
# WHY A TEST AND NOT JUST A FIXED `+ 1`. `build_qs_songs.py` was corrected at
# 14z-87b; `audit_qs_voice_batch.py` and `check_qs_voice_batch.py` were not,
# and went on justifying the exclusive slice with the superseded measurement
# in their own comments. The tree contradicted itself in writing for six
# sessions, and the byte the exclusive reading omits is EXACTLY the byte that
# caused the beep — so corruption confined to it passed every batch check.
# The law now lives in tools/qs_window.py; this is what stops it drifting
# apart again.
#
# HANDOFF's gate-index note, moved into this header 14z-123 (verbatim; the
# documentation pass ruled a gate's WHY lives in the gate):
#   14z-93 (GitHub #82): the QSound sample-window endpoint is INCLUSIVE
#   (packing law #3). The builder was corrected at 14z-87b; both AUDIT paths
#   were not, and went on justifying the exclusive slice with the superseded
#   belief — so the byte that caused the sword-plant beep sat OUTSIDE the
#   audit surface. Law now in tools/qs_window.py, bounds CHECKED not clamped.
#   14 cases incl. a terminal-byte corruption control and a control
#   REPRODUCING the old blindness. ROM-free, ~1s; ci_portable
set -eu
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
fail=0
ok()   { echo "  ok $1"; }
bad()  { echo "  FAIL $1"; fail=1; }

echo "== 1: the endpoint is INCLUSIVE =="
python3 - <<'PY' || fail=1
import sys
sys.path.insert(0, "tools")
from qs_window import window, length, try_window

img = bytes(range(256))
rc = 0

# The window 4..9 is SIX bytes and the byte AT 9 is the last one played.
w = window(img, 4, 9)
if w == bytes([4, 5, 6, 7, 8, 9]):
    print("  ok inclusive: window(4,9) is 6 bytes and ends WITH index 9")
else:
    print("  FAIL inclusive: got", list(w)); rc = 1

if length(4, 9) == 6:
    print("  ok length: inclusive length is hi-lo+1")
else:
    print("  FAIL length:", length(4, 9)); rc = 1

# An exclusive reading would return 5 bytes ending at 8. Pin the difference
# so a regression to `img[lo:hi]` cannot pass.
if len(window(img, 4, 9)) != len(img[4:9]):
    print("  ok not-exclusive: the inclusive window is one byte longer")
else:
    print("  FAIL not-exclusive: window matches the exclusive slice"); rc = 1

# A single-byte window is legal and is 1 byte, not 0.
if window(img, 7, 7) == bytes([7]):
    print("  ok degenerate: a one-byte window (lo == hi) plays that byte")
else:
    print("  FAIL degenerate:", list(window(img, 7, 7))); rc = 1

sys.exit(rc)
PY

echo "== 2: THE TERMINAL-BYTE CONTROL — corruption at the endpoint must be visible =="
python3 - <<'PY' || fail=1
import sys
sys.path.insert(0, "tools")
from qs_window import window

rc = 0
good = bytearray(range(64))
# Mutate ONLY the declared terminal byte — the exact shape #82 describes,
# and the exact byte the sword-plant beep was made of.
bad_ = bytearray(good); bad_[31] ^= 0xFF

if window(good, 0, 31) != window(bad_, 0, 31):
    print("  ok terminal: a terminal-byte-only mutation CHANGES the window")
else:
    print("  FAIL terminal: the endpoint byte is outside the audit surface"); rc = 1

# The control on the control: under the OLD exclusive reading the same
# mutation was invisible. This is what shipped for six sessions.
if good[0:31] == bad_[0:31]:
    print("  ok exclusive-was-blind: the old slice could not see it "
          "(this is the defect, reproduced)")
else:
    print("  FAIL exclusive-was-blind: fixture does not reproduce the defect"); rc = 1

# And a mutation anywhere else is still visible, so the test above is not
# passing for a trivial reason.
mid = bytearray(good); mid[10] ^= 0xFF
if window(good, 0, 31) != window(mid, 0, 31):
    print("  ok interior: an interior mutation is visible too")
else:
    print("  FAIL interior"); rc = 1

sys.exit(rc)
PY

echo "== 3: bounds are CHECKED, never clamped =="
python3 - <<'PY' || fail=1
import sys
sys.path.insert(0, "tools")
from qs_window import window, try_window

img = bytes(64)
rc = 0

# hi == len-1 is the last legal window and must NOT raise.
try:
    window(img, 0, 63)
    print("  ok edge: a window ending at the last byte is legal")
except ValueError:
    print("  FAIL edge: the maximal legal window was rejected"); rc = 1

# One past is malformed. Clamping here would silently compare fewer bytes
# than the DSP plays — the same class as the exclusive slice.
try:
    window(img, 0, 64)
    print("  FAIL over: a window past the image was accepted"); rc = 1
except ValueError:
    print("  ok over: a window past the image RAISES, it does not clamp")

try:
    window(img, -1, 10)
    print("  FAIL neg: a negative start was accepted"); rc = 1
except ValueError:
    print("  ok neg: a negative start RAISES")

# try_window is the probing variant: misses are empty, not exceptions.
if try_window(img, 0, 64) == b'':
    print("  ok try: try_window returns b'' for the bank-probe callers")
else:
    print("  FAIL try"); rc = 1

sys.exit(rc)
PY

echo "== 4: drift guard — both audit paths go through the shared law =="
# The import must be REAL, not a mention in a comment. Written the naive way
# (`grep -q qs_window`) this section passed on a file that named the module
# only in prose and would have NameError'd at runtime — caught 14z-93 while
# writing it, which is the argument for the stricter form.
for f in tools/audit_qs_voice_batch.py tools/check_qs_voice_batch.py; do
    if grep -Eq '^[[:space:]]*(import qs_window|from qs_window import)' "$f"; then
        ok "$f imports the shared law"
    else
        bad "$f does not IMPORT tools/qs_window.py (a comment is not an import)"
    fi
    # and the module must actually be loadable from that file's own path
    if python3 -c "
import ast,sys
src=open('$f').read()
ast.parse(src)
" 2>/dev/null; then
        ok "$f parses"
    else
        bad "$f does not parse"
    fi
done
# Both tools must be importable/compilable — a NameError on a shared helper
# only shows up when the audit is actually run, which is rarely.
if python3 -m py_compile tools/audit_qs_voice_batch.py \
        tools/check_qs_voice_batch.py tools/qs_window.py 2>/dev/null; then
    ok "all three compile"
else
    bad "a QSound audit tool does not compile"
fi
# The builder is where the law was FIRST established; it must stay inclusive.
if grep -q 'q2\[w0:w1 + 1\]' tools/build_qs_songs.py; then
    ok "build_qs_songs.py still copies INCLUSIVE (packing law #3)"
else
    bad "build_qs_songs.py no longer copies q2[w0:w1 + 1] — re-read packing law #3"
fi

echo
if [ "$fail" = 0 ]; then
    echo "PASS: the QSound endpoint law is inclusive, bounded, and shared."
else
    echo "FAIL: the endpoint law is not what the builder assumes."
fi
exit "$fail"
