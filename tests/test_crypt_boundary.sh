#!/bin/sh
# test_crypt_boundary.sh — code in the WIDE extension must be stored RAW.
#
# WHY THIS IS LOAD-BEARING. vsavj's CPS-2 encryption covers only
# PRG:0x000000-0x100000 (HANDOFF "Key findings"); above that the CPU fetches
# opcodes raw. The `code` ops the generator emits are re-encrypted by
# patch_prg.py unconditionally — so the correctness of every byte of ported
# CODE placed above 1MB rests on Cipher.crypt_words_at() passing those words
# through unchanged.
#
# Today that matters for hole_b (0x3EC720-0x400000). It matters far more for
# Phase C: Donovan's port is ~338 KiB and Huitzil/Pyron are comparable, so
# the CPS-2 WIDE extension ($400010-$600000) is where character code will
# live. If the cipher ever encrypted there, every relocated routine would be
# silently corrupted — executable garbage, not a loud failure.
#
# A docstring says it passes through. This asserts it, in both directions,
# and pins the exact boundary word.
#
# Usage: ROMDIR=... tests/test_crypt_boundary.sh
#
# HANDOFF's gate-index note, moved into this header 14z-123 (verbatim; the
# documentation pass ruled a gate's WHY lives in the gate):
#   code above the encryption window is stored RAW (load-bearing: character
#   code in the extension)
set -eu
ROMDIR="${ROMDIR:?set ROMDIR}"
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"

python3 - "$ROMDIR/vsavj.zip" <<'PY'
import sys, zipfile
sys.path.insert(0, "tools")
import cps2_decrypt as cps

with zipfile.ZipFile(sys.argv[1]) as z:
    key = z.read([n for n in z.namelist() if n.endswith(".key")][0])
c = cps.Cipher(key)
print(f"  encrypted range: {c.lower:#08x}-{c.upper:#08x}")

# A blob that is not accidentally fixed-point under the cipher.
blob = bytes(range(0x40)) * 4
words = cps._raw_words_be(blob) if hasattr(cps, "_raw_words_be") else \
        [int.from_bytes(blob[i:i+2], "big") for i in range(0, len(blob), 2)]

fail = 0

def check(name, addr, want_changed):
    global fail
    out = c.crypt_words_at(list(words), addr // 2, decrypt=False)
    changed = out != list(words)
    ok = changed == want_changed
    verb = "transformed" if changed else "passed through RAW"
    print(f"  {'ok  ' if ok else 'FAIL'} {name} @{addr:#08x}: {verb}"
          + ("" if ok else f"  (expected {'transformed' if want_changed else 'RAW'})"))
    if not ok:
        fail = 1
    return out

# 1. inside the window: hole_a, where ported CODE lives today
enc = check("hole_a (inside)", 0x0BF6A0, True)
# round trip must restore, or the encrypt direction is wrong
back = c.crypt_words_at(enc, 0x0BF6A0 // 2, decrypt=True)
if back == list(words):
    print("  ok   hole_a round-trip: decrypt(encrypt(x)) == x")
else:
    print("  FAIL hole_a round-trip broken"); fail = 1

# 2. outside the window: hole_b (raw today) and the WIDE extension
check("hole_b (outside)", 0x3EC720, False)
check("wide_ext (outside)", 0x400010, False)
check("wide_ext far end", 0x5FFF00, False)

# 3. the boundary itself. NOTE the limit test is INCLUSIVE of the upper
# word, in both our Cipher (`lo <= a <= hi`) and MAME's cps2crypt.cpp
# (`a >= lower_limit && a <= upper_limit`). So the encrypted span is
# 0x000000-0x100001 INCLUSIVE — one word past the round 1MB the docs quote.
# Measured 14z-59k; the first draft of this test asserted the opposite and
# was wrong, not the code.
check("last encrypted word", c.upper, True)
check("first raw word", c.upper + 2, False)

sys.exit(fail)
PY
rc=$?

echo
if [ "$rc" = 0 ]; then
    echo "PASS: crypt boundary — code above the encryption window is stored RAW,"
    echo "      so ported character code can live in the WIDE extension."
else
    echo "FAIL: crypt boundary. Ported code placed outside the encryption"
    echo "      window would be silently corrupted — executable garbage, not a"
    echo "      loud failure. Do not place content above 1MB until this passes."
    exit 1
fi
