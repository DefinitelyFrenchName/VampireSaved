#!/bin/sh
# test_harness_frame_bound.sh — the FBNeo harness must bound replay frame
# numbers (14z-94, GitHub #77). ROM-free structurally; the functional half
# runs only if a built binary and ROMDIR are present. ~5 s.
#
# THE DEFECT. parse_script() took frame numbers as unrestricted UINT32 and fed
# them to unchecked arithmetic:
#
#     nScriptFrames = last + (UINT32)nHarnessTailFrames;
#     held = calloc(nScriptFrames + 2, sizeof(UINT32));
#
# Two failures, and the second is the dangerous one:
#   * `last + tail` wraps -> nScriptFrames becomes SMALL and the replay
#     silently TRUNCATES instead of reporting a bad script;
#   * `nScriptFrames + 2` wraps at 0xFFFFFFFF -> calloc(1, 4), while pass 2
#     still writes held[fr] for every fr <= nScriptFrames. That is an
#     out-of-bounds write of ~4 GB.
#
# A single mistyped frame in a hand-edited .rpl is the whole trigger.
#
# THE FIX is an operational cap, not a guess: the longest replay in
# tests/replays is the 40,620-frame arcade marathon, and 10,000,000 frames is
# ~46 hours of emulated play. Nothing legitimate approaches it, and with both
# addends bounded neither sum can wrap.
#
# HANDOFF's review-triage table note, moved into this header 14z-123 (verbatim; the
# documentation pass ruled a gate's WHY lives in the gate):
#   (review-triage, #77) FBNeo replay frames are bounded before the
#   arithmetic; the cap is re-derived from `tests/replays`, not trusted.
set -eu
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
rc=0
fail() { echo "  FAIL: $*"; rc=1; }
H="emu/fbneo/src/burner/sdl/harness.cpp"

echo "== 1. the cap exists, and is above every committed replay =="
[ -f "$H" ] || { echo "SKIP: no harness source (submodule not checked out)"; exit 0; }
cap=$(grep -oE '#define HARNESS_MAX_FRAMES ([0-9]+)u' "$H" | grep -oE '[0-9]+' || true)
if [ -z "$cap" ]; then
    fail "HARNESS_MAX_FRAMES is not defined — the frame arithmetic is unbounded"
else
    echo "  ok: HARNESS_MAX_FRAMES = $cap"
    longest=$(awk '{ l=$0; sub(/#.*/,"",l)
                     if (match(l, /[0-9]+/)) { n=substr(l,RSTART,RLENGTH)+0
                                               if (n>m) m=n } }
                   END { print m+0 }' tests/replays/*.rpl)
    echo "  longest frame in tests/replays: $longest"
    if [ "$longest" -ge "$cap" ]; then
        fail "a COMMITTED replay reaches $longest, at or above the cap — the"
        fail "      cap would reject real work. Raise it deliberately."
    else
        echo "  ok: the cap is above every committed replay, by $((cap - longest))"
    fi
fi

echo "== 2. every frame source is checked BEFORE the arithmetic =="
for want in \
    "a > HARNESS_MAX_FRAMES || b > HARNESS_MAX_FRAMES" \
    "nHarnessFrames > HARNESS_MAX_FRAMES" \
    "nScriptFrames > HARNESS_MAX_FRAMES"
do
    if grep -qF "$want" "$H"; then
        echo "  ok: checked — $want"
    else
        fail "missing check: $want"
    fi
done
# The allocation must not be able to wrap even in principle.
if grep -qF "calloc((size_t)nScriptFrames + 2" "$H"; then
    echo "  ok: the allocation widens to size_t before adding"
else
    fail "the calloc still adds in UINT32 — at 0xFFFFFFFF it wraps to a"
    fail "      1-element allocation that pass 2 then writes 4 GB past"
fi

echo "== 3. the tracked patch carries the fix (the binary is built from it) =="
P="emu/fbneo-patches/0001-vampire-saved-harness.patch"
if grep -q "HARNESS_MAX_FRAMES" "$P"; then
    echo "  ok: 0001 carries the cap, so a fresh setup_fbneo gets it"
else
    fail "$P does NOT carry the cap — a fresh checkout would build the"
    fail "      unbounded harness, and tree-integrity would flag the tree"
fi

echo "== 4. FUNCTIONAL — a wrapping frame is refused by name =="
FB="${FBNEO_BIN:-$REPO/emu/fbneo/fbneo}"
if [ ! -x "$FB" ] || [ -z "${ROMDIR:-}" ]; then
    echo "  note: no built binary or no ROMDIR — structural checks only"
else
    T="$(mktemp -d)"; trap 'rm -rf "$T"' EXIT INT TERM
    # 4294967290 + 120 wraps in UINT32; pre-fix this truncated the replay.
    printf '4294967290 p1=A\n' > "$T/wrap.rpl"
    tools/run_replay_fbneo.sh vsavj "$T/wrap.rpl" "$T/w.log" "$T/sb1" \
        > "$T/w.out" 2>&1 || true
    if grep -q "exceeds the .* cap" "$T/w.out"; then
        echo "  ok: refused, and the message names the cap"
    else
        fail "a wrapping frame was not refused:"
        tail -3 "$T/w.out" | sed 's/^/        /'
    fi
    if [ -s "$T/w.log" ]; then
        fail "it still produced a replay log — the run was not aborted"
    else
        echo "  ok: and no log was produced"
    fi

    echo "== 5. CONTROL — an ordinary replay is unaffected =="
    # Without this, "reject everything" would pass section 4.
    tools/run_replay_fbneo.sh vsavj tests/replays/01_attract_long.rpl \
        "$T/r.log" "$T/sb2" > "$T/r.out" 2>&1 || true
    if [ -s "$T/r.log" ] && grep -q '^END ' "$T/r.log"; then
        echo "  ok: 01_attract_long still runs to END ($(grep -c . "$T/r.log") lines)"
    else
        fail "a committed replay no longer completes — the bound broke real use:"
        tail -3 "$T/r.out" | sed 's/^/        /'
    fi
fi

echo
[ "$rc" = 0 ] && echo "PASS: replay frame numbers are bounded before they are used." \
             || echo "FAIL: see above."
exit $rc
