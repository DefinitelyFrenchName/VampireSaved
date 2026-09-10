#!/bin/sh
# test_emulator_runner.sh — ground truth for tests/run_all_emulator.sh
# (14z-128). ROM-free, ~5 s.
#
# MUST-FIRE: shadow-tool: export-removed — a copy of the runner without `export MAME_BIN` must leave the gate's MAME_BIN UNSET (mode: that copy is the runner every section drives; section 11 must fail)
# MUST-FIRE: shadow-tool: reader-unplugged — a copy that hands the classifier no gate script must let a declared-but-unfired control read PASS (mode: section 14 must fail)
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
. "$REPO/tests/lib/controls.sh"; vs_ctl_mode "$0"

T="$(mktemp -d)"; trap 'rm -rf "$T"' EXIT INT TERM
FR="$T/fakerepo"
mkdir -p "$FR/tests/lib" "$FR/tools" "$FR/build/fake_merged/rompath" "$T/roms"
# THE SHADOW TOOLS (built from the real runner, never through the symlink):
# the export line removed; the classifier's gate-script argument removed.
# Under CONTROL=<name> the named copy is the runner every section drives.
sed '/^export MAME_BIN$/d' "$RUNNER" > "$T/runner_noexport.sh"
cmp -s "$RUNNER" "$T/runner_noexport.sh" && fail "could not remove the export line — it moved"
sed 's|vs_classify "$_st" "$_log" 90 "tests/$_g.sh"|vs_classify "$_st" "$_log" 90|' "$RUNNER" > "$T/runner_unplugged.sh"
cmp -s "$RUNNER" "$T/runner_unplugged.sh" && fail "could not unplug the reader — the vs_classify call moved"
chmod +x "$T/runner_noexport.sh" "$T/runner_unplugged.sh"
case "$VS_CTL" in
export-removed)   ln -s "$T/runner_noexport.sh" "$FR/tests/run_all_emulator.sh" ;;
reader-unplugged) ln -s "$T/runner_unplugged.sh" "$FR/tests/run_all_emulator.sh" ;;
*)                ln -s "$RUNNER" "$FR/tests/run_all_emulator.sh" ;;
esac
# the runner sources THE ONE classifier relative to its repo (14z-139), so
# the synthetic repo carries it too — the shipped lib, never a copy
mkdir -p "$FR/tests/lib"; ln -s "$REPO/tests/lib/classify.sh" "$FR/tests/lib/classify.sh"
ln -s "$REPO/tests/lib/controls.sh" "$FR/tests/lib/controls.sh"   # the controls reader beside it (14z-147)

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
row()  { printf '%s\t%s\t%s\tromset\t%s\t%s' "$1" "$2" "$3" "$4" "$5"; }
# rowc = the same with an EXPLICIT cadence (gate lane scope cadence args note).
rowc() { printf '%s\t%s\t%s\t%s\t%s\t%s' "$1" "$2" "$3" "$4" "$5" "$6"; }

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

echo "6b. CADENCE selects independently of scope, and --freeze ASKS the question"
# The maintainer's 2026-09-03 ruling: the bitstream gates are RELEASE-scope but
# a freeze pays them only when it targets MiSTer. Both halves are asserted —
# that the rows are dropped, AND that the runner NAMES them, because a silent
# drop is the same failure as a skipped ritual step.
reg "$(row  g_pass  mame   release   -  '')" \
    "$(rowc g_bits  mister release bitstream - 'a bitstream-cadence gate')"
outc="$(run --lane mame --lane mister --log "$T/lc" || true)"
printf '%s\n' "$outc" | grep -q "g_bits" \
    && ok "cadence=all (the default) runs the bitstream row" \
    || fail "the default cadence did NOT run the bitstream row"
outf="$(run --lane mame --lane mister --freeze --log "$T/lf" || true)"
printf '%s\n' "$outf" | grep -q "g_bits .*PASS" \
    && fail "--freeze RAN a bitstream-cadence gate" \
    || ok "--freeze excluded the bitstream-cadence gate"
printf '%s\n' "$outf" | grep -q "bitstream gates DROPPED" \
    && ok "--freeze NAMED what it dropped (the question is asked, not remembered)" \
    || fail "--freeze dropped a gate SILENTLY — the ruling's whole point"
printf '%s\n' "$outf" | grep -q "g_bits" \
    && ok "the dropped gate is named by name" \
    || fail "--freeze did not name the dropped gate"
# and the control: a romset-cadence gate is NOT dropped by --freeze
printf '%s\n' "$outf" | grep -q "g_pass .*PASS" \
    && ok "--freeze kept the romset-cadence gate (it drops by cadence, not by lane)" \
    || fail "--freeze dropped a ROMSET-cadence gate"

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

echo "9. a lane WAITS for its own gates (--jobs > 1)"
# The pipeline version announced the next lane while the previous lane's last
# partial batch was still running, orphaning gates across the boundary.
{ echo '#!/bin/sh'; echo ': "${MAME_BIN:-}"'; echo 'sleep 3'; echo 'echo slow-done'; } \
    > "$FR/tests/g_slow3.sh"; chmod +x "$FR/tests/g_slow3.sh"
reg "$(row g_slow3 fbneo release - '')" "$(row g_pass mame release - '')"
out12="$(run --jobs 4 --log "$T/l12" || true)"
# the slow fbneo gate's verdict line must appear BEFORE the mame lane heading
slow_line="$(printf '%s\n' "$out12" | grep -n 'g_slow3 ' | head -1 | cut -d: -f1)"
mame_line="$(printf '%s\n' "$out12" | grep -n '== mame lane' | head -1 | cut -d: -f1)"
if [ -n "$slow_line" ] && [ -n "$mame_line" ] && [ "$slow_line" -lt "$mame_line" ]; then
    ok "a lane's gates finish before the next lane is announced"
else
    fail "lane boundary crossed: g_slow3 at line ${slow_line:-none}, mame lane at ${mame_line:-none}"
fi
if awk -F'\t' 'NR>1 && $1=="g_slow3" && $2=="fbneo"' "$T/l12/results.tsv" | grep -q .; then
    ok "its result is recorded under its OWN lane"
else
    fail "g_slow3's result is missing or filed under the wrong lane"
fi

echo "10. the shipped registry is complete both ways"
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
    if len(c) < 6 or len(c) > 7:
        print(f"  FAIL: registry row has {len(c)} columns, needs 6 or 7: {c[0] if c else line!r}")
        sys.exit(1)
    # 14z-134: the optional 7th column is the gate's OWN timeout in seconds
    # (or `-`), overriding run_all_emulator.sh --timeout.
    if len(c) == 7 and not (c[6] == "-" or c[6].isdigit()):
        print(f"  FAIL: timeout column for {c[0]} must be seconds or '-', got {c[6]!r}"); sys.exit(1)
    if c[1] not in ("prereq", "mame", "fbneo", "mister"):
        print(f"  FAIL: unknown lane {c[1]!r} for {c[0]}"); sys.exit(1)
    if c[2] not in ("release", "out"):
        print(f"  FAIL: unknown scope {c[2]!r} for {c[0]}"); sys.exit(1)
    if c[3] not in ("romset", "bitstream"):
        print(f"  FAIL: unknown cadence {c[3]!r} for {c[0]}"); sys.exit(1)
    # Cadence was ruled 2026-09-03 for the MiSTer bitstream specifically. If it
    # ever spreads to another lane that is a DECISION, not a column edit.
    if c[3] == "bitstream" and c[1] != "mister":
        print(f"  FAIL: bitstream cadence on lane {c[1]!r} for {c[0]} — only the"
              f" mister lane may be bitstream-cadence (ruled 2026-09-03)"); sys.exit(1)
    if c[2] == "out" and c[5].split(":")[0] not in ("romset", "platform", "momentary", "dev-ladder"):
        print(f"  FAIL: out-of-scope row {c[0]} needs a reason keyword, got {c[5][:40]!r}")
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

echo "11. the runner EXPORTS the WIDE MAME default, and a caller's MAME_BIN wins (14z-133b)"
# Until 14z-133 the runner exported nothing: an unpinned gate ran `mame` on
# PATH (Homebrew's — three M16 sweep reds on "Unknown system 'vsavjw'"). Now
# the runner hands every gate the WIDE instrument unless the caller set one.
printf '#!/bin/sh\necho "mame_bin=${MAME_BIN:-UNSET}"\nexit 0\n' > "$FR/tests/g_mamebin.sh"
chmod +x "$FR/tests/g_mamebin.sh"
reg "$(row g_mamebin mame release - '')"
out11a="$( (unset MAME_BIN; MAME_WIDE_BIN="$T/fake_wide" run --lane mame --only g_mamebin --log "$T/l11a") )"
if grep -q "mame_bin=$T/fake_wide" "$T/l11a/g_mamebin.log" 2>/dev/null \
   && printf '%s' "$out11a" | grep -q "MAME_BIN.*(runner default)"; then
    ok "unset by the caller -> the gate receives the WIDE instrument, and the log says 'runner default'"
else
    fail "runner default not delivered: $(grep mame_bin "$T/l11a/g_mamebin.log" 2>/dev/null)"
fi
out11b="$( MAME_BIN="$T/caller_mame" MAME_WIDE_BIN="$T/fake_wide" run --lane mame --only g_mamebin --log "$T/l11b" )"
if grep -q "mame_bin=$T/caller_mame" "$T/l11b/g_mamebin.log" 2>/dev/null \
   && printf '%s' "$out11b" | grep -q "MAME_BIN.*(set by the caller)"; then
    ok "set by the caller -> the caller's value wins, and the log says so"
else
    fail "caller's MAME_BIN not honoured: $(grep mame_bin "$T/l11b/g_mamebin.log" 2>/dev/null)"
fi
# MUST-FIRE CONTROL: a copy of the runner with the export removed must leave
# the gate UNSET — so the assertion above depends on the export, not on the
# fakerepo's environment.
ln -s "$T/runner_noexport.sh" "$FR/tests/run_all_emulator_noexport.sh"
(cd "$FR" && unset MAME_BIN && ROMDIR="$T/roms" MERGED=build/fake_merged MAME_WIDE_BIN="$T/fake_wide" \
    sh tests/run_all_emulator_noexport.sh --lane mame --only g_mamebin --log "$T/l11c" >/dev/null 2>&1) || true
if grep -q "mame_bin=UNSET" "$T/l11c/g_mamebin.log" 2>/dev/null; then
    vs_ctl_fired export-removed "without the export line the gate reports UNSET"; ok "control fires"
else
    vs_ctl_dead export-removed "$(grep mame_bin "$T/l11c/g_mamebin.log" 2>/dev/null)"; fail "control did not fire"
fi
rm -f "$FR/tests/run_all_emulator_noexport.sh" "$FR/tests/g_mamebin.sh"

echo "12. exit 0 after a SHELL ERROR is FAIL; a MAME teardown segfault line is not (14z-134)"
# The M16 release run recorded test_mister_obj_oracle as PASS 0s: it died at
# a `${JTSIM_SCRATCH:?}` demand placed after its EXIT trap, and macOS bash 3.2
# exits 0 for that abort (docs/project/gotchas.md). The classifier now reads
# the shell's own `<script>.sh: line N: NAME: message` as a crash. The
# benign look-alike — MAME segfaulting at teardown AFTER the summary line,
# `line N:  <pid> Segmentation fault: 11` — must still PASS.
printf '#!/bin/sh\necho "tests/g_shellcrash.sh: line 3: FOO: set FOO to a dir OUTSIDE the repo"\nexit 0\n' > "$FR/tests/g_shellcrash.sh"
printf '#!/bin/sh\necho "PASS: the summary line"\necho "tests/g_segv.sh: line 64:  2444 Segmentation fault: 11  REPLAY=x"\nexit 0\n' > "$FR/tests/g_segv.sh"
chmod +x "$FR/tests/g_shellcrash.sh" "$FR/tests/g_segv.sh"
reg "$(row g_shellcrash mame release - '')" "$(row g_segv mame release - '')"
run --lane mame --log "$T/l12" >/dev/null 2>&1 || true
v12a="$(awk -F'\t' '$1=="g_shellcrash"{print $4}' "$T/l12/results.tsv" 2>/dev/null)"
v12b="$(awk -F'\t' '$1=="g_segv"{print $4}' "$T/l12/results.tsv" 2>/dev/null)"
[ "$v12a" = FAIL ] && ok "a shell-error line with exit 0 is FAIL (was PASS before 14z-134)" \
                   || fail "shell-error crash classified '$v12a', expected FAIL"
[ "$v12b" = PASS ] && ok "a MAME teardown segfault line after the summary stays PASS" \
                   || fail "the benign segfault shape classified '$v12b', expected PASS"
rm -f "$FR/tests/g_shellcrash.sh" "$FR/tests/g_segv.sh"

echo "13. a row's 7th column is its timeout; --jobs N on the mister lane hands each slot its own scratch clone (14z-134)"
# The M16 release run lost two 3-hour Verilator gates to the single 90-minute
# cap while their notes said "~93 min a leg" in prose; and the MiSTer lane was
# serial only because every gate shared ONE scratch clone.
printf '#!/bin/sh\nsleep 20\necho PASS\n' > "$FR/tests/g_long.sh"; chmod +x "$FR/tests/g_long.sh"
printf '#!/bin/sh\necho "scratch=${JTSIM_SCRATCH:-UNSET}"\nsleep 2\necho PASS\n' > "$FR/tests/g_slotA.sh"
cp "$FR/tests/g_slotA.sh" "$FR/tests/g_slotB.sh"; chmod +x "$FR/tests/g_slotA.sh" "$FR/tests/g_slotB.sh"
reg "$(rowc g_long mame release romset - 'a slow gate')	2" "$(row g_pass mame release - '')"
run --lane mame --timeout 60 --log "$T/l13a" >/dev/null 2>&1 || true
v13a="$(awk -F'\t' '$1=="g_long"{print $4}' "$T/l13a/results.tsv" 2>/dev/null)"
v13b="$(awk -F'\t' '$1=="g_pass"{print $4}' "$T/l13a/results.tsv" 2>/dev/null)"
[ "$v13a" = TIMEOUT ] && ok "a 2-second 7th column killed a 20-second gate under a 60-second --timeout" \
                       || fail "per-row timeout not applied: g_long classified '$v13a'"
[ "$v13b" = PASS ] && ok "a 6-column row still runs under the global --timeout" \
                    || fail "6-column row classified '$v13b'"
reg "$(rowc g_slotA mister release romset - 'slot a')" "$(rowc g_slotB mister release romset - 'slot b')"
(cd "$FR" && ROMDIR="$T/roms" MERGED=build/fake_merged JTSIM_SCRATCH="$T/scratch" \
    sh tests/run_all_emulator.sh --lane mister --jobs 2 --log "$T/l13b" >/dev/null 2>&1) || true
sA="$(grep -h '^scratch=' "$T/l13b/g_slotA.log" 2>/dev/null)"; sB="$(grep -h '^scratch=' "$T/l13b/g_slotB.log" 2>/dev/null)"
if [ "$sA" = "scratch=$T/scratch" ] && [ "$sB" = "scratch=$T/scratch-slot1" ]; then
    ok "--jobs 2 on the mister lane: slot 0 keeps the base clone, slot 1 gets <base>-slot1"
else
    fail "per-slot scratch not delivered: A='$sA' B='$sB'"
fi
(cd "$FR" && ROMDIR="$T/roms" MERGED=build/fake_merged JTSIM_SCRATCH="$T/scratch" \
    sh tests/run_all_emulator.sh --lane mister --jobs 1 --log "$T/l13c" >/dev/null 2>&1) || true
sC="$(grep -h '^scratch=' "$T/l13c/g_slotB.log" 2>/dev/null)"
[ "$sC" = "scratch=$T/scratch" ] && ok "--jobs 1: every gate keeps the caller's JTSIM_SCRATCH" \
                                   || fail "serial mister lane changed the scratch: '$sC'"
rm -f "$FR/tests/g_long.sh" "$FR/tests/g_slotA.sh" "$FR/tests/g_slotB.sh"

echo "14. the must-fire controls are READ every run, and EXECUTED under --controls (14z-147)"
# READ: a gate whose header declares a control and whose log lacks the FIRED
# line is FAIL; EXECUTED: `<gate>@<name>` rows, PASS when the mode reaches the
# gate's own FAIL, FAIL when it LIES (exit 0), REFUSES or DIES.
mkc() {  # mkc <name> <mode-body> <output lines...>
    n="$1"; body="$2"; shift 2
    { echo "#!/bin/sh"; echo "# $n.sh — a stub"
      echo "# MUST-FIRE: perturbed-copy: flip — a flipped byte must fail"
      echo ': "${MAME_BIN:-}"'
      echo 'if [ "${CONTROL:-}" = flip ]; then'; echo "$body"; echo 'fi'
      for l in "$@"; do echo "echo '$l'"; done; echo "exit 0"; } > "$FR/tests/$n.sh"
    chmod +x "$FR/tests/$n.sh"
}
mkc g_cfired   'echo "FAIL: caught"; exit 1'          "PASS: fine" "CONTROL FIRED: flip — caught"
mkc g_cmissing 'echo "FAIL: caught"; exit 1'          "PASS: fine"
mkc g_clies    'echo "PASS: nothing changed"; exit 0' "PASS: fine" "CONTROL FIRED: flip — caught"
mkc g_cref     'echo "REFUSED: CONTROL=flip is not a mode of this gate"; exit 3' "PASS: fine" "CONTROL FIRED: flip — caught"
reg "$(row g_cfired mame release - '')" "$(row g_cmissing mame release - '')" \
    "$(row g_clies mame release - '')" "$(row g_cref mame release - '')"
run --lane mame --log "$T/l14a" >/dev/null 2>&1 || true
v14a="$(awk -F'\t' '$1=="g_cfired"{print $4}' "$T/l14a/results.tsv")"; v14b="$(awk -F'\t' '$1=="g_cmissing"{print $4}' "$T/l14a/results.tsv")"
[ "$v14a" = PASS ] && ok "a declared control that FIRED keeps its gate PASS" || fail "g_cfired classified '$v14a'"
[ "$v14b" = FAIL ] && ok "a declared control with no FIRED line is FAIL (read on every run, no flag)" || fail "g_cmissing classified '$v14b', expected FAIL"
n14="$(awk -F'\t' 'NR>1 && $1 ~ /@/' "$T/l14a/results.tsv" | wc -l | tr -d ' ')"
[ "$n14" = 0 ] && ok "without --controls no control was executed (no @ rows)" || fail "$n14 control rows without --controls"
out14="$(run --lane mame --controls --log "$T/l14b" || true)"
x14() {  # x14 <row> <verdict> <detail substring>
    v="$(awk -F'\t' -v r="$1" '$1==r{print $4}' "$T/l14b/results.tsv")"; d="$(awk -F'\t' -v r="$1" '$1==r{print $6}' "$T/l14b/results.tsv")"
    [ "$v" = "$2" ] && printf '%s' "$d" | grep -q "$3" && ok "$1 -> $2 ($3)" || fail "$1 -> '$v' '$d', expected $2 / $3"
}
x14 g_cfired@flip PASS "honoured"
x14 g_clies@flip  FAIL "LIES"
x14 g_cref@flip   FAIL "REFUSED"
[ -z "$(awk -F'\t' '$1=="g_cmissing@flip"' "$T/l14b/results.tsv")" ] && ok "a gate that FAILED its own run gets no control row (nothing to execute)" \
    || fail "a control was executed for a gate whose own run failed"
# PASS 4 = three gates that passed their own run + the honoured @ row; FAIL 3 =
# g_cmissing (its FIRED line missing) + the LIES row + the REFUSED row
printf '%s' "$out14" | grep -q 'PASS 4 .*FAIL 3' && ok "tally PASS 4 / FAIL 3: the @ rows count like gates" \
    || fail "tally: $(printf '%s' "$out14" | grep -E '^PASS ' || echo '(none)')"
printf '%s' "$out14" | grep -q 'read:     fired 3 / declared 4' && ok "readout: fired 3 / declared 4" \
    || fail "readout: $(printf '%s' "$out14" | grep 'read:' || echo '(none)')"
# MUST-FIRE: the same stub through the reader-unplugged copy reads PASS
ln -s "$T/runner_unplugged.sh" "$FR/tests/run_all_emulator_unplugged.sh"
reg "$(row g_cmissing mame release - '')"
(cd "$FR" && ROMDIR="$T/roms" MERGED=build/fake_merged sh tests/run_all_emulator_unplugged.sh --lane mame --log "$T/l14c" >/dev/null 2>&1) || true
v14c="$(awk -F'\t' '$1=="g_cmissing"{print $4}' "$T/l14c/results.tsv" 2>/dev/null)"
[ "$v14c" = PASS ] && vs_ctl_fired reader-unplugged "with no gate script handed to the classifier, the declared-but-unfired control reads PASS" \
                   || { vs_ctl_dead reader-unplugged "the unplugged runner classified g_cmissing '$v14c'"; fail "reader-unplugged"; }
rm -f "$FR/tests/run_all_emulator_unplugged.sh"
rm -f "$FR/tests/g_cfired.sh" "$FR/tests/g_cmissing.sh" "$FR/tests/g_clies.sh" "$FR/tests/g_cref.sh"

echo
[ "$rc" = 0 ] && echo "PASS: run_all_emulator.sh classifies every ground-truth case correctly" \
              || echo "FAIL: see above"
exit $rc
