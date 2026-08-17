#!/bin/sh
# test_freeze_retires_diverge.sh — freezing a replay must actually govern it
# (14z-94, GitHub #88). ROM-free, no MAME, ~2 s.
#
# THE DEFECT. run_suite.sh dispatches `.diverge` BEFORE `.sha1`:
#
#     elif [ -f "$EXPDIR/$name.diverge" ]; then  check_diverge ...
#     elif [ ! -f "$EXPDIR/$name.sha1" ];  then  NO-EXPECTATION
#     elif [ "$sha" = "$(cat ...sha1)" ];  then  PASS
#
# so `--freeze` on a replay still carrying a `.diverge` wrote an expectation
# that could never be reached. The command printed "frozen <sha>" while the
# replay stayed governed by the OLD divergence allowance.
#
# The case this arises in is the worst one for it: a replay allowed to diverge
# at a ratified frame, since FIXED, and now frozen exact. Continuing to accept
# a divergence there is precisely backwards — and nothing said so.
#
# THE FIX retires the marker instead of deleting it (a `.diverge` is a
# ratified allowance and the frame it names is evidence) and says so loudly.
# run_suite already documents freeze as preserving only the AUTHORED `.skip`
# and `.masked` expectations, so superseding a self-frozen class is the
# documented intent, not a new policy.
#
# HOW THIS RUNS WITHOUT MAME: the REAL run_suite.sh is SYMLINKED into a fake
# repo — never copied, so it cannot drift — with stubbed MAME runner,
# fingerprint and check_diverge. The check_diverge stub prints a marker, so
# "which branch dispatched" is observable rather than inferred.
set -eu
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
rc=0
fail() { echo "  FAIL: $*"; rc=1; }

T="$(mktemp -d)"; trap 'rm -rf "$T"' EXIT INT TERM
FR="$T/fakerepo"
mkdir -p "$FR/tools" "$FR/tests/replays" "$FR/tests/expected" "$T/romdir"
ln -s "$REPO/tests/run_suite.sh" "$FR/tests/run_suite.sh"

echo "0 none" > "$FR/tests/replays/91_fixed.rpl"
cat > "$FR/tools/build_fingerprint.py" <<'PY'
print("stubset")
PY
cat > "$FR/tools/run_replay_mame.sh" <<'STUB'
#!/bin/sh
set -eu
printf 'frame 0 checksum deadbeef\nframe 1 checksum cafe%s\n' "${STUB_GEN:-01}" > "$3"
STUB
cat > "$FR/tools/check_diverge.py" <<'PY'
print("DIVERGE-BRANCH-RAN")
PY
chmod +x "$FR/tools/run_replay_mame.sh"
E="$FR/tests/expected/stubset"
mkdir -p "$E"

run() { ( cd "$FR" && ROMDIR="$T/romdir" sh ./tests/run_suite.sh "$@" ) \
          > "$T/out" 2>&1 || true; }

echo "== 0. harness sanity — the REAL run_suite runs and can freeze =="
run --freeze vsavj
if grep -q "frozen " "$T/out" && [ -f "$E/91_fixed.sha1" ]; then
    echo "  ok: a clean freeze writes .sha1"
else
    echo "  FAIL: the harness cannot even freeze; everything below is vacuous"
    sed 's/^/        /' "$T/out"; exit 1
fi
run vsavj
grep -q "PASS" "$T/out" && echo "  ok: and a normal run then PASSes on it" \
    || { echo "  FAIL: frozen replay does not pass"; sed 's/^/    /' "$T/out"; exit 1; }

echo "== 1. THE HAZARD — a stale .diverge shadows a fresh freeze =="
# Reproduce the ticket's scenario: the replay was allowed to diverge, has
# since been fixed, and is now frozen exact.
printf 'vsavj 4321' > "$E/91_fixed.diverge"
rm -f "$E/91_fixed.sha1"
run vsavj
if grep -q "DIVERGE-BRANCH-RAN" "$T/out"; then
    echo "  ok: with only a .diverge present, the diverge branch dispatches"
else
    fail "the .diverge branch did not run — this gate is not reproducing the"
    fail "      dispatch order the finding is about"
fi

echo "== 2. freezing RETIRES it, loudly =="
run --freeze vsavj
if [ -f "$E/91_fixed.diverge" ]; then
    fail "the stale .diverge SURVIVED the freeze — the new .sha1 is"
    fail "      unreachable and the replay is still governed by frame 4321"
else
    echo "  ok: .diverge is gone"
fi
if [ -f "$E/91_fixed.diverge.superseded" ]; then
    if [ "$(cat "$E/91_fixed.diverge.superseded")" = "vsavj 4321" ]; then
        echo "  ok: retired, not deleted — the ratified frame is preserved"
    else
        fail "the retained file lost the original spec"
    fi
else
    fail "the .diverge was DELETED, not retired; a ratified allowance and the"
    fail "      frame it names are evidence and must survive"
fi
grep -q "RETIRED" "$T/out" && echo "  ok: and the freeze says so on stdout" \
    || fail "the retirement is silent — a maintainer would not know"
[ -f "$E/91_fixed.sha1" ] && echo "  ok: the new .sha1 was written" \
    || fail "no .sha1 written"

echo "== 3. and the frozen expectation now actually GOVERNS =="
run vsavj
if grep -q "DIVERGE-BRANCH-RAN" "$T/out"; then
    fail "the diverge branch STILL dispatches after the freeze"
elif grep -q "PASS" "$T/out"; then
    echo "  ok: dispatch reaches the .sha1 branch and passes"
else
    fail "neither branch produced a verdict:"; sed 's/^/        /' "$T/out"
fi

echo "== 4. CONTROL — the frozen sha is the RUN's, not a rubber stamp =="
# If freeze wrote a constant, section 3 would pass on any build.
STUB_GEN=99 run vsavj
if grep -q "FAIL\|differs\|MISMATCH" "$T/out"; then
    echo "  ok: a changed log fails against the frozen sha"
else
    fail "a DIFFERENT log still passed — the .sha1 is not being compared:"
    sed 's/^/        /' "$T/out"
fi

echo "== 5. an AUTHORED expectation is not touched by freeze =="
# .masked is authored and explicitly not self-frozen; freeze must not retire
# anything belonging to it. Guards against over-broad cleanup.
printf 'exact vsavj/masked\n' > "$E/91_fixed.masked"
run --freeze vsavj
if [ -f "$E/91_fixed.masked" ]; then
    echo "  ok: .masked survives a freeze"
else
    fail "freeze destroyed an AUTHORED .masked expectation"
fi
grep -q "not self-frozen" "$T/out" && echo "  ok: and freeze declines it by name" \
    || fail "freeze did not report declining the authored expectation"
rm -f "$E/91_fixed.masked"

echo "== 6. the retired marker is invisible to the dispatch-kind gate =="
# test_suite_dispatch.sh enumerates tests/expected/*/*.* and requires every
# KIND to have an owner. `.diverge.superseded` must not read as a new kind.
stem="91_fixed.diverge"; ext="superseded"
if [ -f "$REPO/tests/replays/$stem.rpl" ]; then
    fail "'$stem.rpl' exists, so '$ext' WOULD register as an expectation kind"
else
    echo "  ok: its stem matches no replay, so it is data and not a kind"
fi

echo
[ "$rc" = 0 ] && echo "PASS: a freeze governs the replay it froze." \
             || echo "FAIL: see above."
exit $rc
