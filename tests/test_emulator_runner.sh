#!/bin/sh
# test_emulator_runner.sh — ground truth for tests/run_all_emulator.sh
# (14z-128). ROM-free, ~5 s.
#
# WHY A GATE FOR THE RUNNER, again. CLAUDE.md §4: "Verdict logic is itself
# tested." tests/test_static_runner.sh states the reason for its twin and it
# holds here with more force, because this runner is the one the RELEASE
# policy rests on: "anything red, anything skipped is a hard fail of the
# release process" (maintainer, 2026-09-02). A classifier that reads a
# self-skipping gate as PASS turns that policy into a rubber stamp — which is
# precisely the `bat` defect run_battery_m2.sh's own header documents.
#
# Method, deliberately the same as the static twin: a synthetic repo of stub
# gates with KNOWN verdicts, driven through the REAL runner by symlink, never
# through a copy of its logic. The fakerepo also carries stub `tools/` so the
# runner's own preconditions (the ROM audit, the fingerprint print) run for
# real rather than being bypassed by a test-only backdoor.
#
# THE CASES, and why each is here:
#   PASS / FAIL / SKIP           the three verdicts, counted separately
#   SKIP-in-prose                exits 0 and says "skipped" in a sentence; it
#                                must read PASS, or every gate that documents
#                                the convention is miscounted
#   MISSING                      a registry row whose script is not executable
#   TIMEOUT                      a gate that overruns --timeout is neither a
#                                PASS nor an ordinary FAIL: it asserted nothing
#   UNREGISTERED / DEAD ROW      the anti-orphan check, both directions
#   --strict                     SKIP and an unregistered gate become failures
#   prereq stop                  a red instrument gate STOPS the run ([CPE-24]);
#                                the mame lane must not have run
#   --scope release              `out` rows are excluded; --scope all includes
#   %PLACEHOLDER% expansion      the build set reaches the gate's argv
set -eu
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
rc=0
fail() { echo "  FAIL: $*"; rc=1; }
ok()   { echo "  ok: $*"; }

RUNNER="$REPO/tests/run_all_emulator.sh"
[ -x "$RUNNER" ] || { echo "FAIL: $RUNNER is not executable"; exit 1; }

T="$(mktemp -d)"; trap 'rm -rf "$T"' EXIT INT TERM
FR="$T/fakerepo"
mkdir -p "$FR/tests/lib" "$FR/tools" "$FR/build/fake_merged/rompath" "$T/roms"
ln -s "$RUNNER" "$FR/tests/run_all_emulator.sh"

# Stub tools so the runner's preconditions execute for real.
printf '#!/usr/bin/env python3\nimport sys\n' > "$FR/tools/audit_roms.py"
printf '#!/usr/bin/env python3\nprint("deadbeefcafe")\n' > "$FR/tools/build_fingerprint.py"
chmod +x "$FR/tools/audit_roms.py" "$FR/tools/build_fingerprint.py"
: > "$FR/tests/ci_portable.txt"
: > "$FR/tests/ci_static.txt"

mk() {  # mk <name> <exit> <line...> — a stub gate the tier classifier calls
        # emulator-tier (the MAME_BIN token is what makes it one)
    n="$1"; st="$2"; shift 2
    { echo "#!/bin/sh"
      echo ': "${MAME_BIN:-}"   # emulator-tier marker for the classifier'
      echo 'echo "argv: $*"'
      for l in "$@"; do echo "echo '$l'"; done
      echo "exit $st"; } > "$FR/tests/$n.sh"
    chmod +x "$FR/tests/$n.sh"
}

mk g_pass    0 "all good"
mk g_fail    1 "something broke" "FAIL: nope"
mk g_skip    0 "SKIP: no build at build/nope"
mk g_prose   0 "checked 3 things, none had to be skipped"
# The one that had to be paid for: a SKIP marker AND a non-zero exit. It ran,
# could not complete, and said so — a FAILURE. test_wide_profile.sh does
# exactly this (printing "SKIPPED: set FBNEO_REF" then exiting 2 with
# "PARTIAL: the emulator superset invariant was NOT run"), and the first
# classifier called it a skip: the one gate that justifies modifying an
# emulator at all read as benign.
mk g_skipfail 2 "  SKIPPED: no reference binary" "PARTIAL: the invariant was NOT run"
mk g_out     0 "an out-of-release-scope gate ran"
mk g_args    0 "argument check"
mk g_prereq  0 "the instrument is sound"
mk g_slow    0 "this one overruns"
# The slow gate must actually overrun the timeout.
printf '#!/bin/sh\n: "${MAME_BIN:-}"\nsleep 30\n' > "$FR/tests/g_slow.sh"
chmod +x "$FR/tests/g_slow.sh"
# MISSING: registered, present, but not executable.
printf '#!/bin/sh\nexit 0\n' > "$FR/tests/g_noexec.sh"
chmod 644 "$FR/tests/g_noexec.sh"
# UNREGISTERED: an emulator-tier gate with no registry row at all.
mk g_orphan  0 "nobody registered me"

reg() {  # reg <rows...> — write the fakerepo's registry
    { echo "# fake registry"
      for r in "$@"; do printf '%s\n' "$r"; done; } > "$FR/tests/ci_emulator.tsv"
}
row() { printf '%s\t%s\t%s\t%s\t%s' "$1" "$2" "$3" "$4" "$5"; }

run() {  # run <args...> — the real runner inside the fakerepo
    (cd "$FR" && ROMDIR="$T/roms" MERGED=build/fake_merged \
        sh tests/run_all_emulator.sh "$@" 2>&1)
}

echo "1. the three verdicts, plus SKIP-in-prose and MISSING"
reg "$(row g_pass mame release - '')" \
    "$(row g_fail mame release - '')" \
    "$(row g_skip mame release - '')" \
    "$(row g_prose mame release - '')" \
    "$(row g_noexec mame release - '')" \
    "$(row g_out mame out - 'momentary: a stub')" \
    "$(row g_args mame release '%MERGED%/rompath EXTRA=1' '')" \
    "$(row g_orphan mame release - '')" \
    "$(row g_skipfail mame release - '')"
out="$(run --log "$T/l1" || true)"
printf '%s\n' "$out" > "$T/out1.txt"
line="$(printf '%s\n' "$out" | grep -E '^PASS ' || true)"
case "$line" in
*"PASS 4 "*) ok "PASS counted 4 (g_pass, g_prose, g_args, g_orphan): $line" ;;
*) fail "expected PASS 4 (incl. the prose gate), got: $line" ;;
esac
case "$line" in *"FAIL 2 "*) ok "a SKIP marker with a NON-ZERO exit counts FAIL, not SKIP" ;;
*) fail "expected FAIL 2 (g_fail + the SKIP-and-exit-2 gate), got: $line" ;; esac
case "$line" in *"SKIP 1 "*) ok "SKIP counted separately from PASS" ;;
*) fail "expected SKIP 1, got: $line" ;; esac
case "$line" in *"MISSING 1"*) ok "a non-executable registered gate is MISSING" ;;
*) fail "expected MISSING 1, got: $line" ;; esac
printf '%s\n' "$out" | grep -q "g_out" && fail "an \`out\` row ran under --scope release" \
    || ok "--scope release excluded the out-of-scope row"
printf '%s\n' "$out" | grep -qE '^GREEN' && fail "a run with a FAIL printed GREEN" \
    || ok "a run with a FAIL is NOT GREEN"

echo "2. the placeholder reached the gate's argv"
if grep -q "argv: build/fake_merged/rompath" "$T/l1/g_args.log" 2>/dev/null; then
    ok "%MERGED% expanded into argv"
else
    fail "%MERGED% did not reach argv: $(head -5 "$T/l1/g_args.log" 2>/dev/null | tr '\n' ' ')"
fi
if grep -q "cmd: env EXTRA=1" "$T/l1/g_args.log" 2>/dev/null; then
    ok "a VAR=value token became environment, not a positional"
else
    fail "VAR=value token was not passed as environment"
fi

echo "3. the anti-orphan check, both directions"
# g_orphan above IS registered; the unregistered one is created here, so the
# check is measured against a gate that never had a row rather than a removal.
mk g_orphan2 0 "no row for me"
out2="$(run --log "$T/l2" || true)"
printf '%s\n' "$out2" | grep -q "g_orphan2" \
    && ok "an emulator-tier gate with no row is reported UNREGISTERED" \
    || fail "the unregistered gate was not reported"
reg "$(row g_pass mame release - '')" "$(row g_gone mame release - '')"
out3="$(run --log "$T/l3" || true)"
printf '%s\n' "$out3" | grep -q "DEAD ROW" \
    && ok "a row whose script is gone is reported DEAD" \
    || fail "a dead registry row was not reported"

echo "4. --strict makes SKIP and an unregistered gate fatal"
reg "$(row g_pass mame release - '')" "$(row g_skip mame release - '')"
if run --strict --log "$T/l4" >/dev/null 2>&1; then
    fail "--strict returned 0 with a SKIP present"
else
    ok "--strict is non-zero on SKIP"
fi
if run --log "$T/l5" >/dev/null 2>&1; then
    ok "without --strict the same run is zero (SKIP is reported, not fatal)"
else
    fail "a PASS+SKIP run failed without --strict"
fi

echo "5. a red prereq STOPS the run ([CPE-24])"
mk g_prereq_bad 1 "the instrument moved" "FAIL: parity lost"
reg "$(row g_prereq_bad prereq release - '')" "$(row g_pass mame release - '')"
out6="$(run --log "$T/l6" || true)"
printf '%s\n' "$out6" | grep -q "STOP: the prereq lane is not green" \
    && ok "the run stopped at the prereq lane" \
    || fail "a red prereq did not stop the run"
if printf '%s\n' "$out6" | grep -q "== mame lane"; then
    fail "the mame lane ran after a red prereq"
else
    ok "no later lane ran after a red prereq"
fi
out7="$(run --keep-going --log "$T/l7" || true)"
printf '%s\n' "$out7" | grep -q "== mame lane" \
    && ok "--keep-going runs the later lanes anyway" \
    || fail "--keep-going did not continue past the prereq lane"

echo "6. --scope all includes the out-of-release-scope rows"
reg "$(row g_pass mame release - '')" "$(row g_out mame out - 'momentary: a stub')"
out8="$(run --scope all --log "$T/l8" || true)"
printf '%s\n' "$out8" | grep -q "g_out .*PASS" \
    && ok "--scope all ran the out-of-scope row" \
    || fail "--scope all did not run the out-of-scope row"

echo "7. a gate that overruns --timeout is TIMEOUT, not PASS"
if command -v timeout >/dev/null 2>&1 || command -v gtimeout >/dev/null 2>&1; then
    reg "$(row g_slow mame release - '')"
    out9="$(run --timeout 2 --log "$T/l9" || true)"
    case "$(printf '%s\n' "$out9" | grep -E '^PASS ' || true)" in
    *"TIMEOUT 1"*) ok "an overrunning gate is TIMEOUT" ;;
    *) fail "expected TIMEOUT 1, got: $(printf '%s\n' "$out9" | grep -E '^PASS ' || true)" ;;
    esac
else
    echo "  note: no timeout(1) — TIMEOUT case not exercised"
fi

echo "8. --lane ACCUMULATES (it used to assign, and silently dropped a lane)"
reg "$(row g_pass mame release - '')" "$(row g_prereq fbneo release - '')"
out10="$(run --lane fbneo --lane mame --log "$T/l10" || true)"
if printf '%s\n' "$out10" | grep -q "== fbneo lane" \
   && printf '%s\n' "$out10" | grep -q "== mame lane"; then
    ok "two --lane flags select BOTH lanes"
else
    fail "two --lane flags did not select both lanes"
fi
out11="$(run --lane mame --lane mame --log "$T/l11" || true)"
if [ "$(printf '%s\n' "$out11" | grep -c '== mame lane')" = 1 ]; then
    ok "a repeated --lane is not run twice"
else
    fail "a repeated --lane ran the lane more than once"
fi

echo "9. the shipped registry is complete both ways"
python3 - <<'PY' || rc=1
import glob, os, sys
def reg(p):
    return {l.split('#')[0].strip() for l in open(p)} - {''}
known = reg("tests/ci_portable.txt") | reg("tests/ci_static.txt")
rows = {}
for line in open("tests/ci_emulator.tsv"):
    if line.startswith("#") or not line.strip():
        continue
    c = line.rstrip("\n").split("\t")
    if len(c) < 5:
        print(f"  FAIL: registry row has {len(c)} columns, needs 5: {c[0] if c else line!r}")
        sys.exit(1)
    if c[1] not in ("prereq", "mame", "fbneo", "mister"):
        print(f"  FAIL: unknown lane {c[1]!r} for {c[0]}"); sys.exit(1)
    if c[2] not in ("release", "out"):
        print(f"  FAIL: unknown scope {c[2]!r} for {c[0]}"); sys.exit(1)
    if c[2] == "out" and c[4].split(":")[0] not in ("romset", "platform", "momentary", "dev-ladder"):
        print(f"  FAIL: out-of-scope row {c[0]} needs a reason keyword, got {c[4][:40]!r}")
        sys.exit(1)
    if c[0] in rows:
        print(f"  FAIL: duplicate row {c[0]}"); sys.exit(1)
    rows[c[0]] = c
scripts = {os.path.basename(p)[:-3] for p in glob.glob("tests/*.sh")}
scripts = {s for s in scripts if s not in known and not s.startswith("run_")}
# The tier test is the runner's own; here we only need the two set differences
# to be empty for the scripts that ARE emulator-tier, which the runner reports.
missing = sorted(set(rows) - scripts)
if missing:
    print(f"  FAIL: {len(missing)} registry row(s) name a script that is not an "
          f"unregistered-tier script: {missing[:5]}")
    sys.exit(1)
print(f"  ok: {len(rows)} registry rows, all well-formed, no duplicates")
PY

echo
[ "$rc" = 0 ] && echo "PASS: run_all_emulator.sh classifies every ground-truth case correctly" \
              || echo "FAIL: see above"
exit $rc
