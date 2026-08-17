#!/bin/sh
# test_select_port_hygiene.sh — select_port.py must be chainable, idempotent
# and free of unreachable statements (14z-94, GitHub #46). ROM-free-ish, ~2 s.
#
# WHY THIS GATE EXISTS FOR A DORMANT TOOL. build_donovan.sh:306 calls
# select_port ONLY for a base-half tenant id (`TEN_ID < 16`), and all three
# live tenants are variant-half — Donovan 0x13, Huitzil 0x10, Pyron 0x11 — so
# nothing runs it today. #46's verifier established that and correctly reduced
# the severity. But the module is NOT dead: check_tenant_select.py imports it
# for PLACEMENTS, and it comes back to life for any future base-half tenant.
# A dormant tool with a broken contract is a trap set for the session that
# re-enables it, and that session will not re-read this ticket.
#
# THE TWO CONTRACT BREAKS, both fixed and both asserted here:
#   (a) it was the one builder that is not (src, out) — it rewrote its INPUT
#       members. So it could not be chained, a crash partway left a
#       HALF-PORTED image indistinguishable from a finished one, and a second
#       run replaced already-replaced records while `assert dsize <= jsize`
#       re-parsed the TARGET and therefore measured what it had just written.
#   (b) ~40 lines behind a hardcoded `WINPAL_ENABLE = False` could never
#       execute, so a reader grepping 0x248D80 found live-looking assignments
#       for a mechanism disabled FOR GOOD.
#
# The ANALYSIS around (b) is kept verbatim in the source — the round-22
# timeline convicting the block copies of the throw victim-teleport bug is
# evidence, not implementation. Section 4 asserts it survived, because
# deleting the finding along with the code is the obvious way to get this
# wrong.
set -eu
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
rc=0
fail() { echo "  FAIL: $*"; rc=1; }
SP="tools/select_port.py"

echo "== 1. the (src, out) form exists =="
if grep -q '"--out"' "$SP"; then
    echo "  ok: --out DIR is offered"
else
    fail "$SP has no --out; it is still the one builder that rewrites its input"
fi

echo "== 2. writes are staged, then renamed (no half-ported dir) =="
if grep -q "os.replace(tmp, dst)" "$SP" && grep -q "select_port.tmp" "$SP"; then
    echo "  ok: segments are staged and renamed only once all exist"
else
    fail "the write loop is not atomic — a crash partway leaves a half-ported"
    fail "      program image that looks finished"
fi

echo "== 3. a second IN-PLACE run is refused =="
T="$(mktemp -d)"; trap 'rm -rf "$T"' EXIT INT TERM
mkdir -p "$T/prg"; touch "$T/prg/.select_port.done"
VS2="${ROMDIR:-}/vsav2.zip"
if [ ! -f "$VS2" ]; then
    echo "  note: no ROMDIR — running the refusal without a real --vs2"
    VS2="$T/absent.zip"
fi
if python3 "$SP" "$T/prg" --vs2 "$VS2" --tiles-out "$T/t.json" > "$T/o" 2>&1; then
    fail "an already-ported directory was re-ported in place"
elif grep -q "already carries a select port" "$T/o"; then
    echo "  ok: refused, and it explains why the size guard would be meaningless"
else
    fail "it failed, but not by the idempotence guard:"
    head -2 "$T/o" | sed 's/^/        /'
fi
# ...and --force must get past it, or the escape hatch is fictional.
python3 "$SP" "$T/prg" --vs2 "$VS2" --tiles-out "$T/t.json" --force > "$T/f" 2>&1 || true
if grep -q "already carries a select port" "$T/f"; then
    fail "--force did not override the stamp"
else
    echo "  ok: --force gets past the stamp"
fi

echo "== 4. no unreachable WINPAL statements, but the FINDING survives =="
if grep -qE '^\s*WINPAL_ENABLE\s*=' "$SP"; then
    fail "WINPAL_ENABLE is a live assignment again — the ~40 gated lines are"
    fail "      unreachable code shadowing a mechanism disabled FOR GOOD"
else
    echo "  ok: no WINPAL_ENABLE assignment"
fi
for phrase in "throw victim-teleport" "0x248D80" "14t post-mortem"; do
    grep -q "$phrase" "$SP" \
        && echo "  ok: kept — \"$phrase\"" \
        || fail "the recorded analysis lost \"$phrase\"; the evidence must"
    grep -q "$phrase" "$SP" || fail "      outlive the implementation"
done

echo "== 5. the stamp cannot be mistaken for a program member =="
python3 - <<'PY' || rc=1
import sys
sys.path.insert(0, "tools")
import cps2_decrypt as cps
bad = [n for n in (".select_port.done", "vm3j.03d.select_port.tmp")
       if cps._PRG_RE.search(n)]
if bad:
    print(f"  FAIL: {bad} match the PRG member regex — they would be read back"
          f" in as program data")
    sys.exit(1)
print("  ok: neither the stamp nor a staged temp matches _PRG_RE")
PY

echo "== 6. the module still imports for its DATA (it is not dead) =="
python3 - <<'PY' || rc=1
import sys
sys.path.insert(0, "tools")
import select_port as sp
n = len(sp.PLACEMENTS)
if n < 10:
    print(f"  FAIL: PLACEMENTS has {n} entries; check_tenant_select.py reads it")
    sys.exit(1)
print(f"  ok: PLACEMENTS imports with {n} entries")
PY

echo
[ "$rc" = 0 ] && echo "PASS: select_port is chainable, idempotent and free of dead code." \
             || echo "FAIL: see above."
exit $rc
