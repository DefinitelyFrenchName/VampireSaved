#!/bin/sh
# test_basis_publish_atomic.sh — freezing a masked basis is all-or-nothing
# (14z-94, GitHub #86). ROM-free, no MAME, ~3 s.
#
# THE DEFECT. tools/freeze_masked_basis.sh wrote MASK and then each replay's
# log/sha into the LIVE destination as that replay passed. A failure on
# replay 5 of 8 therefore left four new logs, four old ones, and a new MASK
# behind — under a command that exited 1 and printed BASIS INCOMPLETE.
#
# WHY THAT IS HIGH AND NOT COSMETIC. This directory is the oracle trust root:
# every masked expectation in the suite is compared against it. A
# MIXED-GENERATION basis is precisely the condition guards 1 (one mask per
# basis) and 2 (the instrument control) were written to prevent — arriving by
# a route neither could see, because both run BEFORE the writes. And on a new
# destination the failed command left behind something that looks usable.
#
# HOW THIS IS TESTED WITHOUT MAME. The REAL shipped script is SYMLINKED into
# a fake repo, so `dirname "$0"` re-roots it there while the code under test
# stays the shipped code — never a copy, so it cannot drift. Its MAME runner
# is a stub that fabricates deterministic logs and can be told to fail on a
# named replay, on the second run only, or to return different bytes each run.
# Section 0 proves the harness actually drives the real file.
#
# HANDOFF's review-triage table note, moved into this header 14z-123 (verbatim; the
# documentation pass ruled a gate's WHY lives in the gate):
#   (review-triage, #86) A masked basis publishes whole or not at all. Drives
#   the REAL script symlinked into a fake repo with a stubbed MAME runner.
set -eu
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
rc=0
fail() { echo "  FAIL: $*"; rc=1; }

REAL="$REPO/tools/freeze_masked_basis.sh"
T="$(mktemp -d)"; trap 'rm -rf "$T"' EXIT INT TERM
FR="$T/fakerepo"
mkdir -p "$FR/tools" "$FR/tests/replays" "$T/romdir"

echo "== 0. harness sanity — the REAL script is what runs =="
ln -s "$REAL" "$FR/tools/freeze_masked_basis.sh"
for n in r1 r2 r3; do echo "0 none" > "$FR/tests/replays/$n.rpl"; done

# Stub runner. Argv: <set> <rpl> <outlog> <sandbox>. Honours:
#   STUB_FAIL=<name>     exit 1 for that replay
#   STUB_FAIL2=<name>    exit 1 only on that replay's SECOND run
#   STUB_NONDET=<name>   emit different bytes on each run
#   STUB_GEN=<string>    content generation marker, so a republish is visible
cat > "$FR/tools/run_replay_mame.sh" <<'STUB'
#!/bin/sh
set -eu
rpl="$2"; out="$3"
name="$(basename "$rpl" .rpl)"
c="${STUB_COUNT_DIR:?}/$name"
n=$(( $(cat "$c" 2>/dev/null || echo 0) + 1 ))
echo "$n" > "$c"
[ "${STUB_FAIL:-}" = "$name" ] && exit 1
[ "${STUB_FAIL2:-}" = "$name" ] && [ "$n" -ge 2 ] && exit 1
if [ "${STUB_NONDET:-}" = "$name" ]; then
    echo "frame 0 checksum $name run$n" > "$out"
else
    echo "frame 0 checksum $name gen=${STUB_GEN:-A} mask=${MASK_RANGES:-none}" > "$out"
fi
exit 0
STUB
chmod +x "$FR/tools/run_replay_mame.sh"
export STUB_COUNT_DIR="$T/counts"; mkdir -p "$STUB_COUNT_DIR"

MASK1="043c-043d,7f00-8000"

# Failure injection goes through these, NOT through a `VAR=val freeze ...`
# prefix: for a shell FUNCTION, POSIX keeps such assignments set after the
# call, so each section's injection leaked into the next and the clean-freeze
# control ran with a stale STUB_NONDET. (Found by section 6, which is exactly
# what it is for.) freeze() clears them after every run.
S_FAIL=""; S_FAIL2=""; S_NONDET=""; S_GEN="A"
freeze() { # freeze <destdir> <mask> <names...>
    d="$1"; m="$2"; shift 2
    rm -f "$STUB_COUNT_DIR"/* 2>/dev/null || true
    ( cd "$FR" && ROMDIR="$T/romdir" \
        STUB_FAIL="$S_FAIL" STUB_FAIL2="$S_FAIL2" \
        STUB_NONDET="$S_NONDET" STUB_GEN="$S_GEN" \
        ./tools/freeze_masked_basis.sh "$d" "$m" "$@" ) > "$T/out" 2>&1
    st=$?
    S_FAIL=""; S_FAIL2=""; S_NONDET=""; S_GEN="A"
    return $st
}

# Hash the whole destination tree, so a change ANYWHERE is visible.
treehash() {
    [ -d "$1" ] || { echo "ABSENT"; return; }
    ( cd "$1" && find . -type f | LC_ALL=C sort | while read -r f; do
        printf '%s %s\n' "$f" "$(shasum -a 1 "$f" | cut -d' ' -f1)"; done )
}
stage_left() { find "$(dirname "$1")" -maxdepth 1 -name ".$(basename "$1").staging.*" \
                    -o -maxdepth 1 -name "$(basename "$1").replaced.*" 2>/dev/null; }

D="$T/basis"
if freeze "$D" "$MASK1" r1 r2 r3; then
    echo "  ok: the real script ran under the harness and froze 3 replays"
else
    echo "  FAIL: the baseline freeze did not even succeed — every section"
    echo "        below would be meaningless:"; sed 's/^/        /' "$T/out"; exit 1
fi
[ -f "$D/MASK" ] && [ -f "$D/logs/r1.log" ] && [ -f "$D/r1.sha1" ] \
    || { echo "  FAIL: the freeze produced no MASK/log/sha"; exit 1; }
GOOD="$(treehash "$D")"

echo "== 1. LATE FAILURE on an existing basis leaves it byte-identical =="
# r3 fails, but r1 and r2 pass FIRST — under the old code their new logs were
# already in the live directory by then.
S_FAIL=r3; S_GEN=B
freeze "$D" "$MASK1" r1 r2 r3 && \
    fail "the freeze REPORTED SUCCESS despite a failing replay"
if [ "$(treehash "$D")" = "$GOOD" ]; then
    echo "  ok: destination unchanged after a failure on the last replay"
else
    fail "THE LIVE BASIS WAS MODIFIED by a failed freeze:"
    treehash "$D" > "$T/now"; printf '%s\n' "$GOOD" > "$T/was"
    diff "$T/was" "$T/now" | sed 's/^/        /'
fi
grep -q "untouched" "$T/out" && echo "  ok: and it says so" \
    || fail "the failure message does not state the destination is untouched"

echo "== 2. failure on the SECOND run of a replay (determinism leg) =="
S_FAIL2=r2; S_GEN=C
freeze "$D" "$MASK1" r1 r2 r3 && \
    fail "a second-run failure reported success"
[ "$(treehash "$D")" = "$GOOD" ] && echo "  ok: destination unchanged" \
    || fail "the basis changed on a second-run failure"

echo "== 3. NONDETERMINISM must not publish anything either =="
S_NONDET=r2; S_GEN=D
freeze "$D" "$MASK1" r1 r2 r3 && \
    fail "a nondeterministic replay reported success"
[ "$(treehash "$D")" = "$GOOD" ] && echo "  ok: destination unchanged" \
    || fail "the basis changed on a nondeterministic replay"
grep -q "NONDETERMINISTIC" "$T/out" && echo "  ok: and it is named as such" \
    || fail "nondeterminism was not reported"

echo "== 4. a MISSING replay leaves the basis alone =="
S_GEN=E
freeze "$D" "$MASK1" r1 r2 nosuchreplay && \
    fail "a missing replay reported success"
[ "$(treehash "$D")" = "$GOOD" ] && echo "  ok: destination unchanged" \
    || fail "the basis changed when a replay was missing"

echo "== 5. an ABSENT destination stays ABSENT on failure =="
N="$T/newbasis"
S_FAIL=r3
freeze "$N" "$MASK1" r1 r2 r3 && fail "reported success"
if [ ! -e "$N" ]; then
    echo "  ok: no partial basis left behind"
else
    fail "a partial basis was created at $N:"; ls -R "$N" | sed 's/^/        /'
fi

echo "== 6. CONTROL — a SUCCESSFUL freeze does change the tree =="
# Without this, sections 1-5 would pass on a script that never writes at all.
S_GEN=Z
freeze "$D" "$MASK1" r1 r2 r3 || fail "a clean freeze failed"
NEW="$(treehash "$D")"
if [ "$NEW" != "$GOOD" ]; then
    echo "  ok: the tree is a new generation, so the comparison has teeth"
else
    fail "a successful re-freeze changed NOTHING — the harness cannot detect"
    fail "      a write, so every 'unchanged' verdict above is vacuous"
fi
grep -q "gen=Z" "$D/logs/r1.log" && echo "  ok: and the new content is live" \
    || fail "the published log is not the new generation"
if [ "$(cat "$D/r1.sha1")" = "$(shasum "$D/logs/r1.log" | cut -d' ' -f1)" ]; then
    echo "  ok: each .sha1 matches its published log"
else
    fail "the published sha1 does not match the published log"
fi
[ "$(cat "$D/MASK")" = "$MASK1" ] && echo "  ok: MASK records the mask used" \
    || fail "MASK does not match the argument"

echo "== 7. EXTENDING keeps names that were not re-frozen =="
# The dangerous direction guards 1-2 were written for: staging is seeded from
# the live basis, or a partial re-freeze would silently DROP the others.
R2_BEFORE="$(shasum "$D/logs/r2.log" | cut -d' ' -f1)"
S_GEN=Y
freeze "$D" "$MASK1" r1 || fail "extending with one replay failed"
if [ -f "$D/logs/r2.log" ] && \
   [ "$(shasum "$D/logs/r2.log" | cut -d' ' -f1)" = "$R2_BEFORE" ]; then
    echo "  ok: r2 and r3 survived a freeze that only named r1"
else
    fail "re-freezing ONE replay dropped or altered the others — an extension"
    fail "      would destroy the rest of the basis"
fi
grep -q "gen=Y" "$D/logs/r1.log" && echo "  ok: and r1 was updated" \
    || fail "r1 was not updated by the extension"

echo "== 8. no staging or replaced-generation directory is left anywhere =="
left="$(stage_left "$D")$(stage_left "$N")"
if [ -z "$left" ]; then
    echo "  ok: staging cleaned up after every path above"
else
    fail "leftover staging state: $left"
fi

echo
[ "$rc" = 0 ] && echo "PASS: a basis is published whole or not at all." \
             || echo "FAIL: see above."
exit $rc
