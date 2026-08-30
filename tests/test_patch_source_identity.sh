#!/bin/sh
# test_patch_source_identity.sh — a patch may only be applied to the source
# set it was generated against (14z-94, GitHub #18). ~5 s, no emulator.
#
# THE GAP. A generated patch.json carries only {op, addr, val|hex|path}: no
# expected-old bytes and no statement of what it was generated AGAINST. All
# the old-byte verification in this project lives in gen_donovan_patch.py and
# runs against the CACHED decrypted views build/out/vsavj_{opcodes,data}.bin,
# which build_donovan.sh regenerates only when MISSING. The verified image and
# the image actually patched were joined by nothing — so patch_prg would write
# those ops at those offsets into ANY zip with one .key and a program member.
# patch_prg's own docstring advertises chaining onto "a PREVIOUS BUILDER'S
# OUTPUT", which is exactly the case where the generator's premises (0xFF fill
# at the allocation, dst_old_head at the destination) no longer hold.
#
# THE FIX is an identity, not per-op old bytes: the generator records
# `src_program_identity` (sha1 over each program member's name, length and
# bytes, in load order) and patch_prg refuses a mismatch. Both compute it from
# the SAME helper in cps2_decrypt so they cannot drift apart on what "the same
# source set" means.
#
# A MISMATCH IS FATAL; an ABSENT identity is a warning, because several gates
# build synthetic patches inline and those are legitimate. Section 4 pins that
# asymmetry so it stays deliberate.
#
# HANDOFF's review-triage table note, moved into this header 14z-123 (verbatim; the
# documentation pass ruled a gate's WHY lives in the gate):
#   (review-triage, #18) A patch applies only to the source set it was
#   verified against. **Not portable.**
set -eu
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
ROMDIR="${ROMDIR:?set ROMDIR}"
T="$(mktemp -d)"; trap 'rm -rf "$T"' EXIT INT TERM
rc=0
fail() { echo "  FAIL: $*"; rc=1; }

echo "== 1. the identity distinguishes the reference sets =="
python3 - <<PY || rc=1
import sys
sys.path.insert(0, "tools")
import cps2_decrypt as cps
a = cps.program_identity("$ROMDIR/vsavj.zip")
b = cps.program_identity("$ROMDIR/vsav2.zip")
c = cps.program_identity("$ROMDIR/vsavj.zip")
if a == b:
    print("  FAIL: vsavj and vsav2 hash the same — the identity is blind"); sys.exit(1)
if a != c:
    print("  FAIL: the identity is not stable across two reads"); sys.exit(1)
print(f"  ok: vsavj {a[:16]} != vsav2 {b[:16]}, and stable on re-read")
PY

echo "== 2. a patch carrying the RIGHT identity applies =="
python3 - <<PY
import json, sys
sys.path.insert(0, "tools")
import cps2_decrypt as cps
spec = {"ops": [], "src_program_identity": cps.program_identity("$ROMDIR/vsavj.zip")}
json.dump(spec, open("$T/right.json", "w"))
PY
if python3 tools/patch_prg.py "$ROMDIR/vsavj.zip" "$T/out_right" \
     --patch "$T/right.json" > "$T/right.out" 2>&1; then
    echo "  ok: applied against the set it names"
else
    fail "a correctly-identified patch was refused:"; sed 's/^/        /' "$T/right.out"
fi

echo "== 3. THE CONTROL — the WRONG source set must be REFUSED =="
# The report's demonstration: patch_prg happily wrote into a bogus set and
# exited 0. Here the same patch meets a different real romset.
if python3 tools/patch_prg.py "$ROMDIR/vsav2.zip" "$T/out_wrong" \
     --patch "$T/right.json" > "$T/wrong.out" 2>&1; then
    fail "a vsavj-generated patch APPLIED to vsav2 — the check is dead"
elif grep -q "source-set mismatch" "$T/wrong.out"; then
    echo "  ok: refused — $(grep -o 'source-set mismatch[^,]*' "$T/wrong.out" | head -1)"
    if [ -d "$T/out_wrong" ] && [ -n "$(ls -A "$T/out_wrong" 2>/dev/null)" ]; then
        fail "but it wrote output before refusing"
    else
        echo "  ok: and wrote nothing"
    fi
else
    fail "it failed for an UNNAMED reason — the control would pass on any"
    fail "      unrelated breakage:"; head -3 "$T/wrong.out" | sed 's/^/        /'
fi

echo "== 4. an ABSENT identity warns but is not fatal (synthetic patches) =="
echo '{"ops": []}' > "$T/none.json"
if python3 tools/patch_prg.py "$ROMDIR/vsavj.zip" "$T/out_none" \
     --patch "$T/none.json" > "$T/none.out" 2>&1; then
    if grep -q "no src_program_identity" "$T/none.out"; then
        echo "  ok: applied, with the unverified-source warning printed"
    else
        fail "applied SILENTLY — an unidentified patch must at least say so"
    fi
else
    fail "an identity-free patch was refused; several gates build one inline:"
    sed 's/^/        /' "$T/none.out"
fi

echo "== 5. the GENERATOR actually emits the field =="
# Sections 2-4 would all pass on a generator that never writes it, leaving the
# real pipeline unprotected. Assert the emit site exists and names the source.
if grep -q 'spec\["src_program_identity"\] = cps.program_identity(args.vsavj)' \
        tools/gen_donovan_patch.py; then
    echo "  ok: gen_donovan_patch records the identity of its --vsavj source"
else
    fail "the generator does not record src_program_identity — every patch it"
    fail "      produces would take the section-4 warning path"
fi

echo
if [ "$rc" = 0 ]; then
    echo "PASS: a patch cannot be applied to a set it was not verified against."
else
    echo "FAIL: see above."
fi
exit $rc
