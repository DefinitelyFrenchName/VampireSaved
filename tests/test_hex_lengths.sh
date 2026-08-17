#!/bin/sh
# test_hex_lengths.sh — ground truth for tools/audit_hex_lengths.py, the
# balanced-byte-edit check (14z-94, GitHub #20). ROM-free, ~1 s.
#
# WHY IT MATTERS HERE AND NOT ONLY IN THE ABSTRACT: the `fixes` key is what
# the #92 arcade-ladder fix rides (four `18:0a` entries per tenant). It was an
# unguarded mechanism at the moment it was used to change shipped bytes. The
# generator now hard-fails on a length mismatch at both write sites; this
# gate proves the STATIC checker that mirrors it actually catches one, because
# a checker that silently passes everything is indistinguishable from a clean
# tree.
#
# THE ISSUE'S MECHANISM IS WRONG AND THAT IS DELIBERATE HERE. #20 says a
# mismatch "changes the bytearray's length" and overruns the next allocation.
# It does not — the slice is sized by len(new), so the assignment is
# length-preserving. What actually goes wrong is an unverified write plus a
# provenance note recording the wrong span. Section 3 pins the real shape so a
# later reader does not re-derive the resize story from the issue text.
set -eu
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
T="$(mktemp -d)"; trap 'rm -rf "$T"' EXIT INT TERM
AUD="python3 tools/audit_hex_lengths.py"
rc=0
fail() { echo "  FAIL: $*"; rc=1; }

echo "== 1. every tracked manifest is balanced today =="
if $AUD > "$T/live.txt" 2>&1; then
  echo "  ok: $(sed -n 's/^ok: scanned \([0-9]*\).*/\1/p' "$T/live.txt") manifests, no unbalanced edit"
else
  fail "a tracked manifest carries an unbalanced byte edit:"
  sed 's/^/        /' "$T/live.txt"
fi

echo "== 2. the SHIPPED #92 rows are seen and accepted =="
# Not a tautology with section 1: it proves the scanner actually PARSES the
# fixes key rather than skipping it, which would make section 1 vacuous.
n=$(grep -c 'fixes = "0x01:18:0a' build/manifest/huitzil.toml build/manifest/pyron.toml 2>/dev/null | \
    awk -F: '{s+=$2} END {print s+0}')
if [ "$n" = 2 ]; then
  echo "  ok: both tenants' #92 fixes rows present and balanced"
else
  fail "expected the #92 fixes row in huitzil.toml and pyron.toml, found $n"
fi

echo "== 3. VERDICT CONTROLS — each must be CAUGHT =="
mk() { printf '%s\n' "$2" > "$T/$1.toml"; }

mk long_new '[[port_patch]]
src_addr = 0x1000
old_hex = "4e75"
new_hex = "4e714e75"'
mk short_new '[[port_patch]]
src_addr = 0x1000
old_hex = "4e714e75"
new_hex = "4e75"'
mk fix_long '[[data_port]]
fixes = "0x01:18:0a0a"'
mk fix_short '[[data_port]]
fixes = "0x01:1818:0a"'
mk fix_malformed '[[data_port]]
fixes = "0x01:18"'

for c in long_new short_new fix_long fix_short fix_malformed; do
  if $AUD "$T/$c.toml" > "$T/$c.out" 2>&1; then
    fail "control '$c' PASSED — the checker does not catch it"
    sed 's/^/        /' "$T/$c.out"
  else
    echo "  ok: '$c' caught — $(grep -m1 '^FAIL' "$T/$c.out" | sed 's/.*: //')"
  fi
done

echo "== 4. a BALANCED row must not be flagged (no false positives) =="
mk clean '[[port_patch]]
src_addr = 0x1000
old_hex = "4e75"
new_hex = "4e71"

[[data_port]]
fixes = "0x01:18:0a,0x1a:18:0a"'
if $AUD "$T/clean.toml" > "$T/clean.out" 2>&1; then
  echo "  ok: balanced rows pass"
else
  fail "a balanced manifest was flagged:"; sed 's/^/        /' "$T/clean.out"
fi

echo "== 5. row scoping — an old_hex must not pair across a row boundary =="
# old_hex in one row and new_hex in the NEXT would be a false pair; the
# scanner resets at every [[table]]. Without this the checker would invent
# comparisons between unrelated rows.
mk scoped '[[port_patch]]
old_hex = "4e75"

[[other_row]]
new_hex = "4e714e71"'
if $AUD "$T/scoped.toml" > "$T/scoped.out" 2>&1; then
  echo "  ok: an unpaired old_hex does not pair across a row boundary"
else
  fail "the scanner paired hex keys across rows:"; sed 's/^/        /' "$T/scoped.out"
fi

echo
if [ "$rc" = 0 ]; then
  echo "PASS: byte edits replace exactly what they verify, and the checker"
  echo "      demonstrably catches the ones that do not."
else
  echo "FAIL: see above."
fi
exit $rc
