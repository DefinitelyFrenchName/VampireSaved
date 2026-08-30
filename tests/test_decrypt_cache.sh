#!/bin/sh
# test_decrypt_cache.sh — ground truth for tests/lib/decrypt_cache.sh
# (14z-94, GitHub #69). ~1 s warm; no ROMDIR needed when the cache is present.
#
# WHY A GATE. The helper replaced 22 direct decrypts with a cache read, so
# every converted gate now reads bytes this file handed it. If it delivers the
# WRONG bytes — or a short image — eighteen gates assert against garbage and
# say PASS. That is a worse failure than the 10.7 s it saves.
#
# THE CORRECTNESS HALF, which is why #69 is not only a perf ticket. The
# pattern it replaced was:
#
#     python3 tools/cps2_decrypt.py ... > /dev/null 2>&1 || true
#     JIMG="$W/vsavj_data.bin"; [ -f "$JIMG" ] || JIMG="build/out/..."
#
# errors discarded, fallback keyed on `[ -f ]`. A decrypt that dies
# half-written leaves a file that EXISTS, so the fallback never fires and the
# test reads a TRUNCATED image. Sections 3 and 4 are that scenario.
#
# HANDOFF's review-triage table note, moved into this header 14z-123 (verbatim; the
# documentation pass ruled a gate's WHY lives in the gate):
#   (review-triage, #69) the decrypt cache delivers full, correct images; a
#   TRUNCATED cache is refused, not silently served.
set -eu
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
rc=0
fail() { echo "  FAIL: $*"; rc=1; }

. "$REPO/tests/lib/decrypt_cache.sh"

CACHE_OP="$REPO/build/out/vsavj_opcodes.bin"
CACHE_DAT="$REPO/build/out/vsavj_data.bin"
if [ ! -f "$CACHE_OP" ] || [ ! -f "$CACHE_DAT" ]; then
    echo "SKIP: no build/out decrypted cache (and no ROMDIR to build one)"
    exit 0
fi
T="$(mktemp -d)"; trap 'rm -rf "$T"' EXIT INT TERM

echo "== 1. a warm cache delivers the cache's exact bytes =="
if decrypt_view vsavj "$T/op.bin" "$T/dat.bin"; then
    if cmp -s "$T/op.bin" "$CACHE_OP" && cmp -s "$T/dat.bin" "$CACHE_DAT"; then
        echo "  ok: both views byte-identical to build/out"
    else
        fail "delivered bytes differ from the cache — eighteen converted gates"
        fail "      would be reading something other than the decrypted image"
    fi
else
    fail "decrypt_view failed on a warm cache"
fi

echo "== 2. and they are full-length (not a short read) =="
for f in "$T/op.bin" "$T/dat.bin"; do
    n=$(wc -c < "$f" | tr -d ' ')
    [ "$n" = 4194304 ] && echo "  ok: $(basename "$f") $n bytes" \
        || fail "$(basename "$f") is $n bytes, expected 4194304"
done

echo "== 3. THE #69 HAZARD — a TRUNCATED cache must not be delivered =="
# Done against a fake REPO so the real cache is never at risk. No ROMDIR is
# set for this call, so the helper cannot silently "recover" by decrypting;
# it has to REFUSE, which is the behaviour under test.
FR="$T/fakerepo"; mkdir -p "$FR/build/out" "$FR/tools"
ln -s "$REPO/tools/cps2_decrypt.py" "$FR/tools/cps2_decrypt.py"
head -c 1000 "$CACHE_OP" > "$FR/build/out/vsavj_opcodes.bin"     # short!
cp "$CACHE_DAT" "$FR/build/out/vsavj_data.bin"
# decrypt_view reads $REPO at CALL time and is already defined here, so the
# subshell only has to point REPO at the fake tree.
if ( REPO="$FR"; unset ROMDIR
     decrypt_view vsavj "$T/bad_op.bin" ) 2>"$T/err"; then
    fail "a 1000-byte cache file was accepted and delivered"
else
    echo "  ok: refused ($(head -1 "$T/err" | cut -c1-64))"
fi
if [ -s "$T/bad_op.bin" ] && [ "$(wc -c < "$T/bad_op.bin" | tr -d ' ')" != 4194304 ]; then
    fail "it still wrote a short file to the destination"
else
    echo "  ok: no short image left at the destination"
fi

echo "== 4. CONTROL — the size check is what rejects it, not an absent file =="
# If section 3 passed merely because the file was missing, the guard would be
# untested. Prove a PRESENT-but-short file is what fails.
[ -f "$FR/build/out/vsavj_opcodes.bin" ] \
    && echo "  ok: the short file was present the whole time ($(wc -c < "$FR/build/out/vsavj_opcodes.bin" | tr -d ' ') bytes)" \
    || fail "the fixture file vanished — section 3 proved nothing"

echo "== 5. no converted gate still shells out to the decrypt =="
# Two are exempt BY DESIGN and are asserted as such rather than skipped
# silently: the oracle must re-decrypt (that is its whole purpose), and
# test_hui_walk decrypts a BUILD, which is not a cacheable reference set.
EXEMPT="tests/test_decrypt_oracle.sh tests/test_hui_walk.sh"
# Match an INVOCATION (`python3 ... cps2_decrypt.py`), not a mention. Three
# scripts legitimately name the path without running it — this gate's own
# symlink fixture, test_optimize_guard's guarded-tool list, and
# test_no_tracked_mutation's shadow-root probe — and a bare path grep called
# all three offenders.
INVOKE='python3[^|]*cps2_decrypt\.py'
stray=""
for f in tests/*.sh; do
    case " $EXEMPT " in *" $f "*) continue;; esac
    sed 's/#.*//' "$f" | grep -qE "$INVOKE" && stray="$stray $(basename "$f")"
done
[ -z "$stray" ] && echo "  ok: only the two exempt scripts decrypt directly" \
    || fail "still decrypting directly:$stray"
for f in $EXEMPT; do
    sed 's/#.*//' "$f" | grep -qE "$INVOKE" \
        && echo "  ok: $(basename "$f") still decrypts directly, as intended" \
        || fail "$f no longer decrypts — its exemption is stale, re-check it"
done

echo
[ "$rc" = 0 ] && echo "PASS: the decrypt cache delivers full, correct images." \
             || echo "FAIL: see above."
exit $rc
