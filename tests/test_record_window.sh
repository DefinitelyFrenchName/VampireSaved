#!/bin/sh
# test_record_window.sh — ground truth for tests/lua/record_window.lua, the
# in-emulator windowed movie recorder (14z-94). ~40 s, needs ROMDIR + a WIDE
# build; no frozen expectations.
#
# WHY THIS GATE EXISTS. A recorder that drops, duplicates or blanks frames
# still produces a file that plays, and a human watching it cannot tell. Its
# output is then used to date a visual event — which is exactly what the
# round-end flashing question needs it for. So nothing may be read off a
# recording until the recorder has been shown to record the frames it claims.
#
# WHAT IS ASSERTED, and why each is not redundant:
#   1 EXTENT      the movie covers exactly the requested window. Catches an
#                 off-by-one at either end and a window that never closed.
#   2 DETERMINISM the same window recorded twice is byte-identical. Catches a
#                 recorder whose output depends on host timing — the whole
#                 reason for preferring this over a screen capture.
#   3 LIVENESS    a window the framebuffer checksum stream says CHANGES must
#                 produce a materially bigger file than one it says is STILL.
#                 Catches the failure that determinism cannot: a recorder
#                 faithfully and reproducibly emitting the same blank frame.
#                 The windows are CHOSEN FROM the measured checksum stream at
#                 run time, so no frame constant is baked in here to rot.
#   4 CONTROLS    an inverted window must abort, and a window still open at
#                 FRAMES must report a FORCED stop rather than a clean one.
#
# Usage: ROMDIR=... [MAME_BIN=...] [REC_BUILD=build/hui53] tests/test_record_window.sh
#
# HANDOFF's gate-index note, moved into this header 14z-123 (verbatim; the
# documentation pass ruled a gate's WHY lives in the gate):
#   14z-94: ground truth for tests/lua/record_window.lua, the in-emulator
#   WINDOWED movie recorder. `-aviwrite` works headless but writes
#   UNCOMPRESSED video for the whole run — measured 5.7 GB in two minutes of
#   wall time — so the recorder starts and stops on named frames and defaults
#   to MNG (2.4 MB for 120 frames). 4 assertions: EXTENT (the movie covers
#   exactly the window), DETERMINISM (same window twice is byte-identical —
#   the whole reason to prefer this over a screen capture), LIVENESS (a window
#   VIDEO_OUT says CHANGES must not compress like a STILL one — catches a
#   recorder reproducibly emitting blank frames, which determinism cannot),
#   and 2 controls. The busy/still windows are CHOSEN FROM the measured
#   checksum stream at run time, so no frame constant is baked in to rot. NOTE
#   replay.lua has NO frame cap — it runs to the script's last line, so the
#   gate truncates the rig instead. ROMDIR + a WIDE build, ~90s
#
# HANDOFF's review-triage table note, moved into this header 14z-123 (verbatim; the
# documentation pass ruled a gate's WHY lives in the gate):
#   (review-triage, 14z-94) the windowed MNG recorder (2.4 MB/120 frames vs
#   `-aviwrite`'s 5.7 GB/2 min). **Not portable.**
set -eu
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
ROMDIR="${ROMDIR:?set ROMDIR}"
MAME_BIN="${MAME_BIN:-$HOME/.cache/vampire-saved/mame/cps2}"
export MAME_BIN
BUILD="${REC_BUILD:-build/hui53}"  # re-pointed 14z-117b (random-select freeze) <- 14z-117  # re-pointed 14z-119 (physics-port freeze) <- 14z-117b
RPL="${REC_REPLAY:-tests/replays/26_don_arcade_mash.rpl}"  # truncated in section 0

[ -x "$MAME_BIN" ] || { echo "SKIP: no WIDE MAME binary at $MAME_BIN"; exit 0; }
[ -f "$BUILD/rompath/vsavjw.zip" ] || { echo "SKIP: no $BUILD/rompath/vsavjw.zip"; exit 0; }
[ -f "$RPL" ] || { echo "SKIP: no replay $RPL"; exit 0; }

T="$(mktemp -d)"; trap 'rm -rf "$T"' EXIT INT TERM
RP="$PWD/$BUILD/rompath;$ROMDIR"
rc=0
fail() { echo "  FAIL: $*"; rc=1; }

rec() { # rec <tag> <from> <to> <frames> [extra env already exported]
  tag=$1; from=$2; to=$3; frames=$4
  REPLAY="$RPL" REC_FROM="$from" REC_TO="$to" FRAMES="$frames" \
  REC_OUT="$T/$tag.mng" REC_FORMAT=mng \
  TRACE_OUT="$T/$tag.txt" MAME_SANDBOX="$T/sbx_$tag" MAME_ROMPATH="$RP" \
    tools/run_mame.sh vsavjw -autoboot_script tests/lua/record_window.lua \
    > "$T/$tag.log" 2>&1 || true
}

echo "== 0. measure the framebuffer checksum stream (picks the windows) =="
# replay.lua has NO frame cap — it runs the script to its last line plus
# TAIL_FRAMES, and the default rig here is a 40,620-frame arcade marathon.
# Truncate the input instead: replay.lua derives the run length from the
# highest frame in the file, so dropping later lines ends the run early.
# (Measured the hard way: FRAMES is honoured by snapshot_frames.lua and
# record_window.lua but is not a replay.lua variable at all.)
LIMIT=2700
awk -v lim="$LIMIT" '
  { line=$0; sub(/#.*/,"",line)
    if (match(line, /^[ \t]*[0-9]+/)) { n=int(substr(line, RSTART, RLENGTH)); if (n <= lim) print }
    else print }
' "$RPL" > "$T/short.rpl"
REPLAY="$T/short.rpl" VIDEO_OUT="$T/vid.txt" TRACE_OUT="$T/rep.txt" \
MAME_SANDBOX="$T/sbx_vid" MAME_ROMPATH="$RP" \
  tools/run_mame.sh vsavjw -autoboot_script tests/lua/replay.lua \
  > "$T/vid.log" 2>&1 || true
[ -s "$T/vid.txt" ] || { echo "  FAIL: no VIDEO_OUT stream — cannot choose windows"; exit 1; }

# Pick the 120-frame window with the MOST distinct checksums and the one with
# the FEWEST, from the measured stream. Both are reported so a later reader can
# see what the gate actually compared.
eval "$(python3 - "$T/vid.txt" <<'PY'
import sys, re
vals = []
for ln in open(sys.argv[1]):
    m = re.search(r'(\w+)\s*$', ln.strip())
    if m:
        vals.append(m.group(1))
N = 120
best = worst = None
for s in range(1, len(vals) - N, 20):
    d = len(set(vals[s:s + N]))
    if best is None or d > best[0]:
        best = (d, s)
    if worst is None or d < worst[0]:
        worst = (d, s)
print(f"BUSY_FROM={best[1]}; BUSY_TO={best[1]+N-1}; BUSY_D={best[0]}")
print(f"STILL_FROM={worst[1]}; STILL_TO={worst[1]+N-1}; STILL_D={worst[0]}")
PY
)"
echo "  busy window  ${BUSY_FROM}-${BUSY_TO}: ${BUSY_D} distinct checksums"
echo "  still window ${STILL_FROM}-${STILL_TO}: ${STILL_D} distinct checksums"
[ "${BUSY_D}" -gt "${STILL_D}" ] || fail "the stream shows no busy/still contrast — section 3 would be vacuous"

echo "== 1. EXTENT — the movie covers exactly the requested window =="
rec a "$BUSY_FROM" "$BUSY_TO" $((BUSY_TO + 40))
got=$(sed -n 's/.*recorded=\([0-9]*\).*/\1/p' "$T/a.txt")
want=$((BUSY_TO - BUSY_FROM + 1))
if [ "${got:-0}" = "$want" ]; then
  echo "  ok: recorded $got frames for a $want-frame window"
else
  fail "recorded ${got:-none} frames for a $want-frame window"
fi
grep -q "(forced at FRAMES)" "$T/a.txt" && fail "a window that fits reported a FORCED stop"

echo "== 2. DETERMINISM — the same window twice is byte-identical =="
rec b "$BUSY_FROM" "$BUSY_TO" $((BUSY_TO + 40))
if [ -f "$T/a.mng" ] && [ -f "$T/b.mng" ] && cmp -s "$T/a.mng" "$T/b.mng"; then
  echo "  ok: two runs produced byte-identical movies ($(wc -c < "$T/a.mng") bytes)"
else
  fail "the same window recorded twice differs — output depends on host timing"
fi

echo "== 3. LIVENESS — a changing window must not compress like a still one =="
rec c "$STILL_FROM" "$STILL_TO" $((STILL_TO + 40))
if [ -f "$T/a.mng" ] && [ -f "$T/c.mng" ]; then
  bs=$(wc -c < "$T/a.mng"); ss=$(wc -c < "$T/c.mng")
  echo "  busy $bs bytes vs still $ss bytes"
  if [ "$bs" -gt $((ss * 2)) ]; then
    echo "  ok: the busy window carries real, varying content"
  else
    fail "busy and still windows compress alike — the recorder may be emitting"
    fail "      duplicate or blank frames, which determinism alone cannot catch"
  fi
else
  fail "one of the two windows produced no movie"
fi

echo "== 4. VERDICT CONTROLS =="
REPLAY="$RPL" REC_FROM=900 REC_TO=800 FRAMES=950 REC_OUT="$T/bad.mng" \
TRACE_OUT="$T/bad.txt" MAME_SANDBOX="$T/sbx_bad" MAME_ROMPATH="$RP" \
  tools/run_mame.sh vsavjw -autoboot_script tests/lua/record_window.lua \
  > "$T/bad.log" 2>&1 && bad=0 || bad=1
if [ "$bad" = 1 ] && ! [ -s "$T/bad.mng" ]; then
  echo "  ok: an inverted window (REC_TO < REC_FROM) is refused"
else
  fail "an inverted window was accepted — the assertion is dead"
fi

rec trunc 600 2000 700      # window still open when FRAMES stops the run
if grep -q "(forced at FRAMES)" "$T/trunc.txt"; then
  echo "  ok: a window still open at FRAMES reports a FORCED stop"
else
  fail "a truncated window reported a clean stop — its length would be believed"
fi

echo
if [ "$rc" = 0 ]; then
  echo "PASS: the recorder records the frames it claims, reproducibly."
else
  echo "FAIL: do not date a visual event off a recording until this is green."
fi
exit $rc
