#!/bin/sh
# test_qs_ledger_binding.sh — a QSound audit's voice-id inventory must come
# from the artifact it is auditing (14z-94, GitHub #89). ROM-free, no MAME,
# ~2 s: the fixture fabricates romsets and ledgers.
#
# THE DEFECT. The voice ids the QSound audits sweep come from the MANIFEST by
# way of build_qs_songs.py's ledger — never from the romset. Handed a build
# directory, both audits:
#
#     python3 build_qs_songs.py ... --ledger L --dry-run >/dev/null 2>&1 || true
#     [ -f L ] || <rebuild the ledger from build/wide0>
#
# `--dry-run` has NEVER existed, so argparse exited 2 every time; `|| true`
# swallowed it; and the fallback then derived ids from the canonical overlay.
# Auditing an older or independently produced build therefore swept TODAY'S
# manifest ids against it, never exercised voices that build actually
# authored, and reported the green result as a verdict on the supplied
# artifact.
#
# AND NO BUILD CARRIED A LEDGER: neither build_merged.sh nor build_donovan.sh
# passed --ledger, so the fallback was not the exceptional path, it was the
# ONLY path for every supplied build.
#
# THE FIX. The ledger is emitted by default next to the romset and carries a
# fingerprint over the members build_qs_songs.py writes (vsw.z01, vsw.z02,
# vsw.21m — the sound driver and packed sample extension, which are what
# determine voice playback). tools/qs_ledger.py recomputes it from the romset
# it is handed and refuses on mismatch or absence, before any emulator runs.
#
# Note a ledger-only mode is NOT the fix and could not be: a finished
# artifact's spans are already filled, so re-deriving through the build path
# is impossible by construction ("extension span not zero"). The ledger has
# to be written at build time or it does not exist.
#
# HANDOFF's review-triage table note, moved into this header 14z-123 (verbatim; the
# documentation pass ruled a gate's WHY lives in the gate):
#   (review-triage, #89) QSound audit ids come from a ledger fingerprint-bound
#   to the artifact under test, never rebuilt from `build/wide0`.
set -eu
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
rc=0
fail() { echo "  FAIL: $*"; rc=1; }

T="$(mktemp -d)"; trap 'rm -rf "$T"' EXIT INT TERM

echo "== 0. the phantom option is gone from both audits =="
for f in tests/audit_qs_voice_batch.sh tests/audit_qs_voice_wav.sh; do
    # Strip comments first: these files DOCUMENT the old call, and a naive
    # grep reads that prose as the defect (it did, on the first run).
    if sed 's/#.*//' "$f" | grep -q -- "--dry-run"; then
        fail "$f still invokes --dry-run, which build_qs_songs.py does not have"
    else
        echo "  ok: $(basename "$f") no longer invokes --dry-run"
    fi
done
# The premise: argparse must still reject it. Positional args are supplied
# because argparse reports MISSING POSITIONALS before unrecognized options,
# so without them this probe would pass on any error at all.
if python3 tools/build_qs_songs.py a.zip b.zip --dry-run 2>&1 \
     | grep -q "unrecognized arguments: --dry-run"; then
    echo "  ok: confirmed --dry-run is still not a real option (the premise)"
else
    fail "build_qs_songs.py now HAS --dry-run — re-check this finding"
fi
for f in tests/audit_qs_voice_batch.sh tests/audit_qs_voice_wav.sh; do
    # The fallback: any use of the canonical overlay to make ids for a
    # SUPPLIED build. Self-build mode may still reference wide0 as its base.
    if grep -q "scratch.zip" "$f"; then
        fail "$f still rebuilds a ledger from a scratch build/wide0 copy"
    else
        echo "  ok: $(basename "$f") has no wide0 ledger fallback"
    fi
done

echo "== 1. the builder emits a ledger BY DEFAULT =="
if grep -q 'a.ledger = a.vsavjw_zip + ".ledger.json"' tools/build_qs_songs.py; then
    echo "  ok: default ledger path travels with the romset"
else
    fail "build_qs_songs.py does not emit a ledger by default — a supplied"
    fail "      build would then have none, and every audit of one refuses"
fi

# A fabricated romset + its ledger, so the binding logic is exercised without
# a real build. mkset <zip> <driver-bytes> <ext-bytes>
mkset() {
    python3 - "$1" "$2" "$3" <<'PY'
import sys, zipfile
zp, drv, ext = sys.argv[1], sys.argv[2].encode(), sys.argv[3].encode()
with zipfile.ZipFile(zp, "w") as z:
    z.writestr("vsw.z01", drv * 16)
    z.writestr("vsw.z02", drv * 8)
    z.writestr("vsw.21m", ext * 32)
    z.writestr("vm3.03", b"unrelated member")
PY
}
# mkledger <zip> <out.json> <ids...>  — fingerprints the zip as the builder does
mkledger() {
    python3 - "$@" <<'PY'
import sys, json, zipfile, hashlib
zp, out = sys.argv[1], sys.argv[2]
ids = [int(x, 16) for x in sys.argv[3:]]
M = ["vsw.z01", "vsw.z02", "vsw.21m"]
z = zipfile.ZipFile(zp)
blobs = {m: z.read(m) for m in M}
sha1 = lambda b: hashlib.sha1(b).hexdigest()
json.dump({
    "voices": [{"id": i, "vs2_id": i + 0x100} for i in ids],
    "artifact": {"members": M,
                 "member_sha1": {m: sha1(blobs[m]) for m in M},
                 "fingerprint": sha1(b"".join(blobs[m] for m in M))},
}, open(out, "w"), indent=1)
PY
}

Z="$T/vsavjw.zip"
mkset "$Z" "DRIVER-A" "EXTENSION-A"
mkledger "$Z" "$Z.ledger.json" 10 11 12

echo "== 2. a BOUND ledger resolves, and yields the right ids =="
if out=$(python3 tools/qs_ledger.py "$Z" --print ours 2>"$T/err"); then
    if [ "$out" = "10,11,12" ]; then
        echo "  ok: ids come from the ledger ($out)"
    else
        fail "wrong id list: '$out'"
    fi
    grep -q "bound to artifact" "$T/err" && echo "  ok: and it says it verified" \
        || fail "no confirmation that the binding was checked"
else
    fail "a correctly bound ledger was refused:"; sed 's/^/        /' "$T/err"
fi
native=$(python3 tools/qs_ledger.py "$Z" --print native 2>/dev/null)
[ "$native" = "110,111,112" ] && echo "  ok: native ids too ($native)" \
    || fail "wrong native id list: '$native'"

echo "== 3. THE MISMATCH CONTROL — a ledger from another build is REFUSED =="
# The scenario from the ticket: same artifact, ledger from a build whose
# voice ids differ. It must fail BEFORE any emulator runs.
OTHER="$T/other.zip"
mkset "$OTHER" "DRIVER-B" "EXTENSION-B"
mkledger "$OTHER" "$T/other.ledger.json" 20 21 22
if python3 tools/qs_ledger.py "$Z" --ledger "$T/other.ledger.json" \
       > "$T/o" 2>&1; then
    fail "a ledger describing a DIFFERENT artifact was ACCEPTED — the audit"
    fail "      would sweep ids 20,21,22 against a build authoring 10,11,12"
else
    grep -q "does not describe" "$T/o" && echo "  ok: refused as not describing it" \
        || fail "refused, but not by the fingerprint check: $(head -1 "$T/o")"
    grep -q "differs" "$T/o" && echo "  ok: and it names WHICH members differ" \
        || fail "the refusal does not say which member differs"
fi

echo "== 4. a mismatch is fatal even under QS_LEDGER_UNBOUND =="
# The override exists for MISSING evidence, never for CONTRADICTORY evidence.
if QS_LEDGER_UNBOUND=1 python3 tools/qs_ledger.py "$Z" \
       --ledger "$T/other.ledger.json" > "$T/o" 2>&1; then
    fail "QS_LEDGER_UNBOUND=1 let a CONTRADICTED ledger through; the override"
    fail "      must only cover absent evidence, not a proven mismatch"
else
    echo "  ok: still refused"
fi

echo "== 5. a MISSING ledger is refused, not filled in from elsewhere =="
BARE="$T/bare.zip"
mkset "$BARE" "DRIVER-C" "EXTENSION-C"
if python3 tools/qs_ledger.py "$BARE" > "$T/o" 2>&1; then
    fail "a build with NO ledger was accepted"
else
    grep -q "no voice ledger" "$T/o" && echo "  ok: refused" \
        || fail "refused for another reason: $(head -1 "$T/o")"
    grep -q "QS_LEDGER_UNBOUND" "$T/o" && echo "  ok: and the opt-in is spelled out" \
        || fail "the refusal is a dead end — no way forward is offered"
    grep -q "build/wide0" "$T/o" && echo "  ok: and it names the old wrong behaviour" \
        || echo "  note: the refusal does not mention the old fallback"
fi

echo "== 6. CONTROL — a tampered romset breaks the binding =="
# Proves the fingerprint covers the members that matter, not just the name.
TAMPER="$T/tampered.zip"
cp "$Z" "$TAMPER"; cp "$Z.ledger.json" "$TAMPER.ledger.json"
python3 - "$TAMPER" <<'PY'
import sys, zipfile
zp = sys.argv[1]
z = zipfile.ZipFile(zp); out = {n: z.read(n) for n in z.namelist()}; z.close()
b = bytearray(out["vsw.21m"]); b[0] ^= 0xFF          # one byte of sample data
out["vsw.21m"] = bytes(b)
with zipfile.ZipFile(zp, "w") as w:
    for n, d in out.items(): w.writestr(n, d)
PY
if python3 tools/qs_ledger.py "$TAMPER" > "$T/o" 2>&1; then
    fail "ONE flipped byte in vsw.21m did not break the binding — the"
    fail "      fingerprint is not covering the sample data"
else
    echo "  ok: one flipped byte in vsw.21m is caught"
fi
# ...and an UNRELATED member must NOT break it, or every later build step
# would invalidate a ledger that is still accurate.
UNREL="$T/unrelated.zip"
cp "$Z" "$UNREL"; cp "$Z.ledger.json" "$UNREL.ledger.json"
python3 - "$UNREL" <<'PY'
import sys, zipfile
zp = sys.argv[1]
z = zipfile.ZipFile(zp); out = {n: z.read(n) for n in z.namelist()}; z.close()
out["vm3.03"] = b"a later build step rewrote this"
with zipfile.ZipFile(zp, "w") as w:
    for n, d in out.items(): w.writestr(n, d)
PY
if python3 tools/qs_ledger.py "$UNREL" >/dev/null 2>&1; then
    echo "  ok: a change to an unrelated member does NOT invalidate the ledger"
else
    fail "an unrelated member change broke the binding — the fingerprint is"
    fail "      too broad, and every ledger would go stale on the next step"
fi

echo "== 7. both audits actually call the verifier =="
for f in tests/audit_qs_voice_batch.sh tests/audit_qs_voice_wav.sh; do
    if grep -q "qs_ledger.py" "$f"; then
        echo "  ok: $(basename "$f") resolves its ids through qs_ledger.py"
    else
        fail "$f does not use the verifier, so it keeps its own rule"
    fi
done

echo
[ "$rc" = 0 ] && echo "PASS: audit ids are bound to the artifact under test." \
             || echo "FAIL: see above."
exit $rc
