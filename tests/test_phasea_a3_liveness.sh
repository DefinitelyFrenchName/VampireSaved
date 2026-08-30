#!/bin/sh
# test_phasea_a3_liveness.sh — ground truth that audit_wide_phase_a's A3
# cannot publish its permissive decision on a DEAD measurement (14z-94,
# GitHub #25). ROM-free, no emulator, ~2 s.
#
# WHY. A3 decides whether gfx groups may be appended at all. It used to print
# a `note` and `continue` when a replay produced no summary, so a corpus that
# measured NOTHING — a renamed Lua script, a MAME that aborts at boot, a wrong
# ROMDIR — left `a3_max` at 0, satisfied `-lt 49152`, and published "no real
# legacy code reaches the wrap point -> gfx growth is inert for scroll3".
# The audit's OWN A1 comment states the rule it was breaking: "a null result
# is only evidence if the probe can demonstrably see a real access".
#
# HOW. A scratch copy of the audit has its EMULATOR INVOCATION replaced by a
# stub — one that produces no scroll3 measurement (a dead probe), or one that
# measures only the first replay (a partial corpus) — and the audit must
# REFUSE rather than decide. Nothing real is run and no tracked file is edited.
# Stubbing the run_one() helper alone would NOT be enough, because A1's
# instrument ground-truth calls the runner directly; the audit then dies in A1
# and A3 never executes. This gate's first draft did exactly that and section
# 3 caught it, which is the whole reason section 3 exists.
#
# HANDOFF's review-triage table note, moved into this header 14z-123 (verbatim; the
# documentation pass ruled a gate's WHY lives in the gate):
#   (review-triage, #25) A3 cannot decide gfx growth on a measurement it never
#   made.
set -eu
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
SRC="${A3_SRC:-tests/audit_wide_phase_a.sh}"
T="$(mktemp -d)"; trap 'rm -rf "$T"' EXIT INT TERM
rc=0
fail() { echo "  FAIL: $*"; rc=1; }

# Build a scratch copy whose EMULATOR INVOCATION is a stub. Stubbing
# run_one() alone is not enough: A1's instrument ground-truth calls
# tools/run_mame.sh DIRECTLY, so the audit would die in A1 and sections 1-2
# would pass without A3 ever running — which is exactly what section 3 caught
# on this gate's first draft. Substituting the runner covers every call site.
#
# The stub answers by which Lua script it was asked for, so A1 and A2 are
# satisfied (their measurements are irrelevant here) and only A3's is varied.
mkstub() { # mkstub <mode> <outfile>
    sed 's|tools/run_mame\.sh|"$STUB_MAME"|g' "$SRC" > "$2"
    chmod +x "$2"
    cat > "$T/mame_$1.sh" <<STUB
#!/bin/sh
case "\$*" in
  *unmapped_probe*) printf 'UNMAPPEDSUMMARY total=0 CONTROL_workram=4242\n' > "\$TRACE_OUT" ;;
  *objy_bits*)      printf 'OBJYSUMMARY bit12=0\n' > "\$TRACE_OUT" ;;
  *scroll3_watch*)
      : > "\$TRACE_OUT"
      if [ "$1" = partial ] && [ ! -f "$T/stub_done" ]; then
          : > "$T/stub_done"
          printf 'SCROLL3SUMMARY maxcode=ffff\n' > "\$SCROLL3_OUT"
          printf 'SCROLL3CENSUS max_real=0100 high_cells=0\n' >> "\$SCROLL3_OUT"
      fi
      ;;
esac
exit 0
STUB
    chmod +x "$T/mame_$1.sh"
}

echo "== 1. a DEAD probe must not produce a decision =="
mkstub dead "$T/dead.sh"
if ROMDIR="$T" STUB_MAME="$T/mame_dead.sh" sh "$T/dead.sh" > "$T/dead.out" 2>&1; then
    fail "the audit exited 0 with no measurements at all"
elif grep -q "DECISION A3: no real legacy code reaches" "$T/dead.out"; then
    fail "it PUBLISHED the permissive A3 decision on zero measurements:"
    grep -n "DECISION A3" "$T/dead.out" | sed 's/^/        /'
else
    echo "  ok: refused, and printed no A3 decision"
fi

echo "== 2. a PARTIAL corpus must not produce a decision either =="
# The subtler case the first section cannot catch: some replays measure, the
# rest silently do not, and the max is computed over whatever survived.
mkstub partial "$T/partial.sh"
rm -f "$T/stub_done"
if ROMDIR="$T" STUB_MAME="$T/mame_partial.sh" sh "$T/partial.sh" > "$T/partial.out" 2>&1; then
    fail "the audit exited 0 on a partial corpus"
elif grep -q "DECISION A3: no real legacy code reaches" "$T/partial.out"; then
    fail "it published the permissive A3 decision from a partial corpus:"
    grep -n "DECISION A3" "$T/partial.out" | sed 's/^/        /'
else
    echo "  ok: refused a partial corpus"
fi

echo "== 3. CONTROL — the refusals are A3's, not an earlier section's =="
# If the audit died in A1 for an unrelated reason both sections above would
# pass vacuously. Require the failure text to name the scroll3 measurement.
if grep -qE "no scroll3 (summary|census)|contributed a measurement" "$T/dead.out" \
   || grep -qE "no scroll3 (summary|census)|contributed a measurement" "$T/partial.out"; then
    echo "  ok: at least one refusal names the scroll3 measurement"
else
    fail "neither refusal mentions scroll3 — the audit stopped somewhere else,"
    fail "      so sections 1-2 prove nothing about A3. Output head:"
    head -6 "$T/dead.out" | sed 's/^/        /'
fi

echo
if [ "$rc" = 0 ]; then
    echo "PASS: A3 cannot decide gfx growth on a measurement it never made."
else
    echo "FAIL: see above."
fi
exit $rc
