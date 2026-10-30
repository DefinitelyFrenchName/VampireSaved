#!/bin/sh
# test_emulator_runner.sh — ground truth for tests/run_all_emulator.sh
# (14z-128). ROM-free, ~72 s (measured 14z-210 on the Mac; ~26 s at 14z-162, before sections 18-19).
#
# WHAT: tests/run_all_emulator.sh's verdicts mean what they say: PASS / FAIL / SKIP counted
#   apart, SKIP-in-prose read as PASS, a non-executable registry row MISSING, a timeout
#   TIMEOUT, the anti-orphan check both ways, --strict, the prereq stop, --scope,
#   placeholder expansion, the exported MAME_BIN, the controls reader, a --dry-run
#   writing no commit of record (#219), and since 14z-209 (#321, #323, #305): a red prereq gate followed by a green one
#   still STOPS, the fbneo and mame lanes share one pool, --skip leaves a host-covered gate out by name, and a cold
#   decrypt cache is built before the tier; since 14z-210 (#321): a listed gate's controls run beside one another in a
#   pool (an unlisted gate's, and any gate's at --jobs 1, one after another) without deadlocking a full pool, and
#   --order starts a pooled lane longest first; and a control mode that says `NOT JUDGED: ` reads UNJUDGED (#310);
#   and a control mode stopped by its host (a full disk, a failed mktemp, a refused write) reads DIED (#321); and with
#   no TMPDIR from the caller a gate's temp files go to the run's own directory under build/tmp/, removed at the end,
#   and a run with less free space there than it needs refuses to start (#321); and a selected gate whose worker
#   died before writing its row is a FAIL of its own, never a GREEN on fewer rows (#321).
# HOW: a synthetic repository of stub gates with KNOWN verdicts is driven through the REAL
#   runner by symlink (never a copy of its logic), with stub tools so the runner's own
#   preconditions run; the controls run copies of the runner (and, for #323, of the two readers) with a piece removed
#   or restored (the export, the reader, an executable row, the --dry-run guard, the lane loop's own name, the decrypt
#   warm-up).
# EXPECTS: every case reads the verdict it was built to produce and each control's section
#   fails on its copy; a red names the case — a wrong reading here would turn the release
#   policy into a rubber stamp.
#
# MUST-FIRE: shadow-tool: export-removed — a copy of the runner without `export MAME_BIN` must leave the gate's MAME_BIN UNSET (mode: that copy is the runner every section drives; section 11 must fail)
# MUST-FIRE: shadow-tool: reader-unplugged — a copy that hands the classifier no gate script must let a declared-but-unfired control read PASS (mode: section 14 must fail)
# MUST-FIRE: shadow-tool: crash-unread — a copy that hands the CONTROL classifier no gate script must read a control mode dying of `command not found` (exit 127) as an honoured PASS row (mode: that copy is the runner every section drives; section 14b must fail; 14z-196, #254)
# MUST-FIRE: shadow-tool: ondemand-in-all — a copy whose scope selection lets --scope all take an `ondemand` row must run it there (mode: that copy is the runner every section drives; section 6a must fail; 14z-196, the ondemand scope)
# MUST-FIRE: shadow-tool: instrument-run — a copy whose selection keeps `instrument:` rows must run one under --scope ondemand (mode: that copy is the runner every section drives; section 6a must fail; 14z-199, #265)
# MUST-FIRE: shadow-tool: dry-run-records — a copy of the runner without the --dry-run guard on commit.txt must write a run of record on a dry run (mode: that copy is the runner every section drives; section 15's dry-run case must fail)
# MUST-FIRE: shadow-tool: empty-green — a copy of the runner without the empty-selection guard must print GREEN and write a run directory for a selection that matches no gate (mode: that copy is the runner every section drives; section 15's empty-selection case must fail)
# MUST-FIRE: shadow-tool: lane-var-shared — copies of the runner and of tests/lib/controls.sh and measures.sh with the lane loop variable and the readers' log variable all named `_l` again (the #323 shape) must let a red prereq gate followed by a green one run on past the prereq lane (mode: those copies are what every section drives; section 5b must fail; 14z-209)
# MUST-FIRE: shadow-tool: decrypt-warm-off — a copy of the runner whose DECRYPT-WARM call is disabled must leave a gate that reads build/out directly on a cold cache, and section 17 must FAIL (mode: that copy is the runner every section drives; #305, 14z-209)
# MUST-FIRE: shadow-tool: unjudged-honoured — a copy of tests/lib/classify.sh whose NOT-JUDGED branch is disabled must read a control mode that FAILs after printing `NOT JUDGED: ` as an honoured PASS, and section 14c must FAIL (mode: that copy is the classifier every section's runner sources; #310, 14z-210)
# MUST-FIRE: shadow-tool: env-honoured — a copy of tests/lib/classify.sh whose ENV-ERROR branch is disabled must read a control mode that FAILs on `mktemp: No space left on device` as an honoured PASS, and section 14k must FAIL (mode: that copy is the classifier every section's runner sources; #321, 14z-210)
# MUST-FIRE: shadow-tool: jobs-leak — a copy of the runner whose own job count is named JOBS again must hand a caller-exported JOBS=7 to a gate as its --jobs 2, and section 20 must FAIL (mode: that copy is the runner every section drives; #321, 14z-210)
# MUST-FIRE: shadow-tool: concurrent-off — a copy of the runner whose CONCURRENT-CONTROLS test is always false must run a listed gate's two controls one after another, and section 18 must FAIL (mode: that copy is the runner every section drives; #321, 14z-210)
# MUST-FIRE: shadow-tool: order-ignored — a copy of the runner whose ORDER-SORT step is disabled must start a pooled lane's gates in registry order under --order, and section 19 must FAIL (mode: that copy is the runner every section drives; #321, 14z-210)
# MUST-FIRE: shadow-tool: tmp-ignored — a copy of the runner whose DISK-TMPDIR test is always false must leave a gate with no TMPDIR from the caller writing its temp files in /tmp, and section 21 must FAIL (mode: that copy is the runner; #321, 14z-210)
# MUST-FIRE: shadow-tool: lost-unread — a copy of the runner whose LOST-ROWS check is disabled must print GREEN for a pooled lane in which one gate's worker died before writing its row, and section 22 must FAIL (mode: that copy is the runner; #321, 14z-210: PILOT printed GREEN on PASS 1 of 3)
# MUST-FIRE: perturbed-copy: row-not-executable — a farm of symlinks to the REAL scripts named by the REAL tests/ci_emulator.tsv, with ONE replaced by a non-executable copy, must make section 10b report it unrunnable (mode: that farm is what 10b checks; section 10b must fail)
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
#   REGISTRY EXECUTABILITY       10b: the same defect caught STATICALLY, over
#                                the SHIPPED registry — the runner only reports
#                                it once the release sweep reaches that row
#   TIMEOUT                      a gate that overruns --timeout is neither a
#                                PASS nor an ordinary FAIL: it asserted nothing
#   UNREGISTERED / DEAD ROW      the anti-orphan check, both directions
#   --strict                     SKIP and an unregistered gate become failures
#   prereq stop                  a red instrument gate STOPS the run ([CPE-24]);
#                                the mame lane must not have run — and (5b, #323) a green
#                                prereq gate AFTER the red one must not un-stop it
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
# the --dry-run guard on commit.txt removed (14z-191, #219)
sed 's|^if \[ "\$DRY" = 0 \] && \[ ! -f "\$LOGDIR/commit.txt" \]; then$|if [ ! -f "$LOGDIR/commit.txt" ]; then|' "$RUNNER" > "$T/runner_dryrecords.sh"
cmp -s "$RUNNER" "$T/runner_dryrecords.sh" && fail "could not remove the --dry-run guard — the commit.txt line moved"
# the empty-selection guard removed (14z-192, #211)
sed 's|^if \[ -z "\$(selected \| head -1)" \]; then$|if false; then|' "$RUNNER" > "$T/runner_emptygreen.sh"
cmp -s "$RUNNER" "$T/runner_emptygreen.sh" && fail "could not remove the empty-selection guard — the line moved"
# the ondemand exclusion removed from --scope all (14z-196, the ondemand scope)
sed 's|((scope == "all" \&\& $3 != "ondemand") \|\| (scope != "all" \&\& $3 == scope))|(scope == "all" \|\| $3 == scope)|' "$RUNNER" > "$T/runner_ondemandinall.sh"
cmp -s "$RUNNER" "$T/runner_ondemandinall.sh" && fail "could not remove the ondemand exclusion — the selection line moved"
chmod +x "$T/runner_ondemandinall.sh"
# the instrument exclusion removed from every scope (14z-199, #265)
sed 's| \&\& $6 !~ /^instrument:/||' "$RUNNER" > "$T/runner_instrumentrun.sh"
cmp -s "$RUNNER" "$T/runner_instrumentrun.sh" && fail "could not remove the instrument exclusion — the selection line moved"
chmod +x "$T/runner_instrumentrun.sh"
# the control classifier's gate-script argument removed (14z-196, #254)
sed 's|vs_classify_control "$_cs" "$_clog" "tests/$_g.sh" "$_cn"|vs_classify_control "$_cs" "$_clog" "" "$_cn"|' "$RUNNER" > "$T/runner_crashunread.sh"
cmp -s "$RUNNER" "$T/runner_crashunread.sh" && fail "could not unplug the crash reader — the vs_classify_control call moved"
# #323 restored (14z-209): the lane loop variable named `_l` again, and the two readers' log variable `_l` again
sed 's/_lane_pool/_l/g' "$RUNNER" > "$T/runner_lanevar.sh"
cmp -s "$RUNNER" "$T/runner_lanevar.sh" && fail "could not restore the shared name — the lane loop variable moved"
sed 's/_vcr_l\([=";]\)/_l\1/g' "$REPO/tests/lib/controls.sh" > "$T/controls_lanevar.sh"   # a no-op on readers that still say _l
sed 's/_vmr_l\([=";]\)/_l\1/g' "$REPO/tests/lib/measures.sh" > "$T/measures_lanevar.sh"
grep -q '_l="\$2"' "$T/controls_lanevar.sh" || fail "could not restore the shared name in the controls reader — its _vcr_l moved"
# the decrypt warm-up call disabled (#305, 14z-209)
sed 's@    decrypt_cache_warm "$LOGDIR/decrypt_warm.err" || :   # DECRYPT-WARM@    :   # DECRYPT-WARM disabled@' "$RUNNER" > "$T/runner_warmoff.sh"
cmp -s "$RUNNER" "$T/runner_warmoff.sh" && fail "could not disable the decrypt warm-up — the DECRYPT-WARM line moved"
# the concurrent-controls test made always false; the longest-first sort disabled (#321, 14z-210)
sed 's@                && awk -F.\\t. -v g="$_g" .!/^#/ && $1 == g {f = 1} END {exit !f}. tests/controls_concurrent_emu.txt 2>/dev/null; then   # CONCURRENT-CONTROLS@                \&\& false; then   # CONCURRENT-CONTROLS disabled@' "$RUNNER" > "$T/runner_ccoff.sh"
cmp -s "$RUNNER" "$T/runner_ccoff.sh" && fail "could not disable the concurrent-controls test — the CONCURRENT-CONTROLS line moved"
sed 's@    if \[ -n "$ORDER" \] && \[ "$_jobs" -gt 1 \]; then   # ORDER-SORT@    if false; then   # ORDER-SORT disabled@' "$RUNNER" > "$T/runner_orderoff.sh"
cmp -s "$RUNNER" "$T/runner_orderoff.sh" && fail "could not disable the longest-first sort — the ORDER-SORT line moved"
# the runner's own job count named JOBS again (#321, 14z-210)
sed 's/RUN_JOBS/JOBS/g' "$RUNNER" > "$T/runner_jobsleak.sh"
cmp -s "$RUNNER" "$T/runner_jobsleak.sh" && fail "could not restore the JOBS name — RUN_JOBS moved"
chmod +x "$T/runner_jobsleak.sh"
sed 's@    if \[ -z "${TMPDIR:-}" \]; then   # DISK-TMPDIR@    if false; then   # DISK-TMPDIR disabled@' "$RUNNER" > "$T/runner_tmpoff.sh"
cmp -s "$RUNNER" "$T/runner_tmpoff.sh" && fail "could not disable the disk TMPDIR — the DISK-TMPDIR line moved"
chmod +x "$T/runner_tmpoff.sh"
sed 's@    if \[ "$DRY" = 0 \]; then   # LOST-ROWS@    if false; then   # LOST-ROWS disabled@' "$RUNNER" > "$T/runner_lostoff.sh"
cmp -s "$RUNNER" "$T/runner_lostoff.sh" && fail "could not disable the lost-rows check — the LOST-ROWS line moved"
chmod +x "$T/runner_lostoff.sh"
chmod +x "$T/runner_noexport.sh" "$T/runner_unplugged.sh" "$T/runner_dryrecords.sh" "$T/runner_emptygreen.sh" "$T/runner_crashunread.sh" "$T/runner_lanevar.sh" "$T/runner_warmoff.sh" "$T/runner_ccoff.sh" "$T/runner_orderoff.sh"
case "$VS_CTL" in
empty-green)      ln -s "$T/runner_emptygreen.sh" "$FR/tests/run_all_emulator.sh" ;;
export-removed)   ln -s "$T/runner_noexport.sh" "$FR/tests/run_all_emulator.sh" ;;
reader-unplugged) ln -s "$T/runner_unplugged.sh" "$FR/tests/run_all_emulator.sh" ;;
dry-run-records)  ln -s "$T/runner_dryrecords.sh" "$FR/tests/run_all_emulator.sh" ;;
crash-unread)     ln -s "$T/runner_crashunread.sh" "$FR/tests/run_all_emulator.sh" ;;
ondemand-in-all)  ln -s "$T/runner_ondemandinall.sh" "$FR/tests/run_all_emulator.sh" ;;
instrument-run)   ln -s "$T/runner_instrumentrun.sh" "$FR/tests/run_all_emulator.sh" ;;
lane-var-shared)  ln -s "$T/runner_lanevar.sh" "$FR/tests/run_all_emulator.sh" ;;
decrypt-warm-off) ln -s "$T/runner_warmoff.sh" "$FR/tests/run_all_emulator.sh" ;;
concurrent-off)   ln -s "$T/runner_ccoff.sh" "$FR/tests/run_all_emulator.sh" ;;
jobs-leak)        ln -s "$T/runner_jobsleak.sh" "$FR/tests/run_all_emulator.sh" ;;
order-ignored)    ln -s "$T/runner_orderoff.sh" "$FR/tests/run_all_emulator.sh" ;;
tmp-ignored)      ln -s "$T/runner_tmpoff.sh" "$FR/tests/run_all_emulator.sh" ;;
lost-unread)      ln -s "$T/runner_lostoff.sh" "$FR/tests/run_all_emulator.sh" ;;
*)                ln -s "$RUNNER" "$FR/tests/run_all_emulator.sh" ;;
esac
# the runner sources THE ONE classifier relative to its repo (14z-139), so
# the synthetic repo carries it too — the shipped lib, never a copy
mkdir -p "$FR/tests/lib"
# CLSLIB: the classifier this run's synthetic repo carries (a shadow copy under its mode); a section that swaps in a
# shadow of its own restores THIS, never the shipped one (14z-210: 14c's restore undid env-honoured's copy)
CLSLIB="$REPO/tests/lib/classify.sh"
vs_ctl_is unjudged-honoured && CLSLIB="$T/classify_unjudged.sh"
vs_ctl_is env-honoured && CLSLIB="$T/classify_env.sh"
ln -s "$CLSLIB" "$FR/tests/lib/classify.sh"
CTLLIB="$REPO/tests/lib/controls.sh"; MEASLIB="$REPO/tests/lib/measures.sh"
if vs_ctl_is lane-var-shared; then CTLLIB="$T/controls_lanevar.sh"; MEASLIB="$T/measures_lanevar.sh"; fi
# the classifier with its NOT-JUDGED branch disabled (#310, 14z-210)
sed "s@        elif grep -qa '^NOT JUDGED: ' \"\$_clog\"; then   # NOT-JUDGED (#310)@        elif false; then   # NOT-JUDGED disabled@" "$REPO/tests/lib/classify.sh" > "$T/classify_unjudged.sh"
cmp -s "$REPO/tests/lib/classify.sh" "$T/classify_unjudged.sh" && fail "could not disable the NOT-JUDGED branch — the line moved"
sed "s@        elif grep -qaE \"\$VS_ENV_ERR\" \"\$_clog\"; then   # ENV-ERROR (#321)@        elif false; then   # ENV-ERROR disabled@" "$REPO/tests/lib/classify.sh" > "$T/classify_env.sh"
cmp -s "$REPO/tests/lib/classify.sh" "$T/classify_env.sh" && fail "could not disable the ENV-ERROR branch — the line moved"
ln -s "$CTLLIB" "$FR/tests/lib/controls.sh"   # the controls reader beside it (14z-147)
ln -s "$MEASLIB" "$FR/tests/lib/measures.sh"   # the measurement reader too (14z-180): the runner must survive a gate that declares nothing

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
mk g_ond     0 "an ondemand gate ran"
mk g_inst    0 "an instrument ran bare"
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
printf '%s\n' "$out" | grep >/dev/null "g_out" && fail "an \`out\` row ran under --scope release" \
    || ok "--scope release excluded the out-of-scope row"
printf '%s\n' "$out" | grep -E >/dev/null '^GREEN' && fail "a run with a FAIL printed GREEN" \
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
printf '%s\n' "$out2" | grep >/dev/null "g_orphan2" \
    && ok "an emulator-tier gate with no row is reported UNREGISTERED" \
    || fail "the unregistered gate was not reported"
reg "$(row g_pass mame release - '')" "$(row g_gone mame release - '')"
out3="$(run --log "$T/l3" || true)"
printf '%s\n' "$out3" | grep >/dev/null "DEAD ROW" \
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
printf '%s\n' "$out6" | grep >/dev/null "STOP: the prereq lane is not green" \
    && ok "the run stopped at the prereq lane" \
    || fail "a red prereq did not stop the run"
if printf '%s\n' "$out6" | grep >/dev/null "== mame lane"; then
    fail "the mame lane ran after a red prereq"
else
    ok "no later lane ran after a red prereq"
fi
out7="$(run --keep-going --log "$T/l7" || true)"
printf '%s\n' "$out7" | grep >/dev/null "== mame lane" \
    && ok "--keep-going runs the later lanes anyway" \
    || fail "--keep-going did not continue past the prereq lane"

echo "5b. a red prereq gate FOLLOWED by a green one still STOPS the run (#323, 14z-209)"
# The prereq lane is serial, so run_one runs in the runner's own shell, and the readers vs_classify calls on a PASS
# assigned `_l` — the runner's lane loop variable — so the STOP check after a green prereq gate read a log path, not
# "prereq". The 14z-208b freeze ran past test_mame_parity's PARTIAL that way (fork A's repro, build/agent209/t321/).
s5b() {  # s5b <runner script name in the fakerepo> <log> -> S5B ok|bad
    reg "$(row g_prereq_bad prereq release - '')" "$(row g_prereq prereq release - '')" "$(row g_pass mame release - '')"
    _o="$( (cd "$FR" && ROMDIR="$T/roms" MERGED=build/fake_merged sh "tests/$1" --log "$2" 2>&1) || true)"
    S5B=ok
    printf '%s\n' "$_o" | grep >/dev/null "STOP: the prereq lane is not green" || S5B=bad
    awk -F'\t' 'NR>1 && $1=="g_pass"' "$2/results.tsv" 2>/dev/null | grep -q . && S5B=bad
    awk -F'\t' 'NR>1 && $1=="g_prereq" && $4=="PASS"' "$2/results.tsv" 2>/dev/null | grep -q . || S5B=bad   # the green one RAN
}
s5b run_all_emulator.sh "$T/l7b"
[ "$S5B" = ok ] && ok "a red prereq gate then a green one: the run STOPS after the prereq lane and the mame lane never runs" \
                || fail "section 5b: a green prereq gate after a red one un-stopped the run (#323)"
if ! vs_ctl_is lane-var-shared; then
    ln -s "$T/runner_lanevar.sh" "$FR/tests/run_all_emulator_lanevar.sh"
    rm -f "$FR/tests/lib/controls.sh" "$FR/tests/lib/measures.sh"
    ln -s "$T/controls_lanevar.sh" "$FR/tests/lib/controls.sh"; ln -s "$T/measures_lanevar.sh" "$FR/tests/lib/measures.sh"
    s5b run_all_emulator_lanevar.sh "$T/l7c"
    rm -f "$FR/tests/run_all_emulator_lanevar.sh" "$FR/tests/lib/controls.sh" "$FR/tests/lib/measures.sh"
    ln -s "$CTLLIB" "$FR/tests/lib/controls.sh"; ln -s "$MEASLIB" "$FR/tests/lib/measures.sh"
    [ "$S5B" = bad ] && vs_ctl_fired lane-var-shared "with the lane loop and the readers sharing \`_l\` again, the green prereq gate un-stopped the run and the mame lane ran" \
        || { vs_ctl_dead lane-var-shared "the copies sharing \`_l\` still stopped the run"; fail "lane-var-shared"; }
fi

echo "6. --scope all includes the out-of-release-scope rows"
reg "$(row g_pass mame release - '')" "$(row g_out mame out - 'momentary: a stub')"
out8="$(run --scope all --log "$T/l8" || true)"
printf '%s\n' "$out8" | grep >/dev/null "g_out .*PASS" \
    && ok "--scope all ran the out-of-scope row" \
    || fail "--scope all did not run the out-of-scope row"

echo "6a. an ONDEMAND row runs only under --scope ondemand — never by default, never under --scope all (14z-196)"
reg "$(row g_pass mame release - '')" "$(row g_out mame out - 'momentary: a stub')" "$(row g_ond mame ondemand - 'pristine: a stub')" "$(row g_inst mame ondemand - 'instrument: a stub')"
o6a="$(run --log "$T/l6a1" || true)"; o6b="$(run --scope all --log "$T/l6a2" || true)"; o6c="$(run --scope ondemand --log "$T/l6a3" || true)"
printf '%s\n' "$o6a" | grep >/dev/null "g_ond " && fail "the default (release) run ran the ondemand row" || ok "the default run skips the ondemand row"
printf '%s\n' "$o6b" | grep >/dev/null "g_ond " && fail "--scope all ran the ondemand row" || ok "--scope all skips the ondemand row (and still runs g_out: $(printf '%s\n' "$o6b" | grep -c 'g_out .*PASS'))"
printf '%s\n' "$o6b" | grep >/dev/null "g_out .*PASS" || fail "--scope all no longer runs the out row"
if printf '%s\n' "$o6c" | grep >/dev/null "g_ond .*PASS" && ! printf '%s\n' "$o6c" | grep -E >/dev/null "g_(pass|out) .*PASS"; then
    ok "--scope ondemand runs the ondemand row and nothing else"
else fail "--scope ondemand did not run exactly the ondemand row"; fi
ln -s "$T/runner_ondemandinall.sh" "$FR/tests/run_all_emulator_ondemandinall.sh"
o6d="$( (cd "$FR" && ROMDIR="$T/roms" MERGED=build/fake_merged sh tests/run_all_emulator_ondemandinall.sh --scope all --log "$T/l6a4" 2>&1) || true)"
printf '%s\n' "$o6d" | grep >/dev/null "g_ond .*PASS" \
    && vs_ctl_fired ondemand-in-all "with the exclusion removed, --scope all ran the ondemand row" \
    || { vs_ctl_dead ondemand-in-all "the copy without the exclusion still skipped g_ond"; fail "ondemand-in-all"; }
rm -f "$FR/tests/run_all_emulator_ondemandinall.sh"
# an `instrument:` row (14z-199, #265) is selected by NO scope: run bare it only SKIPs, so it is run by hand
_ran=0; for _o in "$o6a" "$o6b" "$o6c"; do printf '%s\n' "$_o" | grep >/dev/null "g_inst " && _ran=1; done
[ "$_ran" = 0 ] && ok "no scope (default, --scope all, --scope ondemand) runs the instrument row" \
                || fail "a scope ran the instrument row"
ln -s "$T/runner_instrumentrun.sh" "$FR/tests/run_all_emulator_instrumentrun.sh"
o6e="$( (cd "$FR" && ROMDIR="$T/roms" MERGED=build/fake_merged sh tests/run_all_emulator_instrumentrun.sh --scope ondemand --log "$T/l6a5" 2>&1) || true)"
printf '%s\n' "$o6e" | grep >/dev/null "g_inst .*PASS" \
    && vs_ctl_fired instrument-run "with the exclusion removed, --scope ondemand ran the instrument row" \
    || { vs_ctl_dead instrument-run "the copy without the exclusion still skipped g_inst"; fail "instrument-run"; }
rm -f "$FR/tests/run_all_emulator_instrumentrun.sh"

echo "6b. CADENCE selects independently of scope, and --freeze ASKS the question"
# The maintainer's 2026-09-03 ruling: the bitstream gates are RELEASE-scope but
# a freeze pays them only when it targets MiSTer. Both halves are asserted —
# that the rows are dropped, AND that the runner NAMES them, because a silent
# drop is the same failure as a skipped ritual step.
reg "$(row  g_pass  mame   release   -  '')" \
    "$(rowc g_bits  mister release bitstream - 'a bitstream-cadence gate')"
outc="$(run --lane mame --lane mister --log "$T/lc" || true)"
printf '%s\n' "$outc" | grep >/dev/null "g_bits" \
    && ok "cadence=all (the default) runs the bitstream row" \
    || fail "the default cadence did NOT run the bitstream row"
outf="$(run --lane mame --lane mister --freeze --log "$T/lf" || true)"
printf '%s\n' "$outf" | grep >/dev/null "g_bits .*PASS" \
    && fail "--freeze RAN a bitstream-cadence gate" \
    || ok "--freeze excluded the bitstream-cadence gate"
printf '%s\n' "$outf" | grep >/dev/null "bitstream gates DROPPED" \
    && ok "--freeze NAMED what it dropped (the question is asked, not remembered)" \
    || fail "--freeze dropped a gate SILENTLY — the ruling's whole point"
printf '%s\n' "$outf" | grep >/dev/null "g_bits" \
    && ok "the dropped gate is named by name" \
    || fail "--freeze did not name the dropped gate"
# and the control: a romset-cadence gate is NOT dropped by --freeze
printf '%s\n' "$outf" | grep >/dev/null "g_pass .*PASS" \
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
if printf '%s\n' "$out10" | grep >/dev/null "== fbneo lane" \
   && printf '%s\n' "$out10" | grep >/dev/null "== mame lane"; then
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

echo "9. a pool WAITS for its own gates (--jobs > 1); the fbneo and mame lanes are ONE pool (#321, 14z-209)"
# The pipeline version announced the next lane while the previous lane's last
# partial batch was still running, orphaning gates across the boundary. Since 14z-209 the fbneo and mame lanes share
# one pool, so the boundary that must hold is the pool's: here a slow mame gate against the mister lane after it.
{ echo '#!/bin/sh'; echo ': "${MAME_BIN:-}"'; echo 'sleep 3'; echo 'echo slow-done'; } \
    > "$FR/tests/g_slow3.sh"; chmod +x "$FR/tests/g_slow3.sh"
reg "$(row g_slow3 mame release - '')" "$(row g_pass mister release - '')"
out12="$(run --lane mame --lane mister --jobs 4 --log "$T/l12" || true)"
# the slow mame gate's verdict line must appear BEFORE the mister lane heading
slow_line="$(printf '%s\n' "$out12" | grep -n 'g_slow3 ' | head -1 | cut -d: -f1)"
mist_line="$(printf '%s\n' "$out12" | grep -n '== mister lane' | head -1 | cut -d: -f1)"
if [ -n "$slow_line" ] && [ -n "$mist_line" ] && [ "$slow_line" -lt "$mist_line" ]; then
    ok "a pool's gates finish before the next lane is announced"
else
    fail "pool boundary crossed: g_slow3 at line ${slow_line:-none}, mister lane at ${mist_line:-none}"
fi
# ONE POOL: the slow fbneo gate is queued first, and the mame gate beside it finishes before it — which only a shared
# pool allows (lane by lane, the mame lane would not start until g_slow3 had ended)
reg "$(row g_slow3 fbneo release - '')" "$(row g_pass mame release - '')"
out12b="$(run --jobs 4 --log "$T/l12b" || true)"
slow_b="$(printf '%s\n' "$out12b" | grep -n 'g_slow3 ' | head -1 | cut -d: -f1)"
pass_b="$(printf '%s\n' "$out12b" | grep -n 'g_pass ' | head -1 | cut -d: -f1)"
if [ -n "$slow_b" ] && [ -n "$pass_b" ] && [ "$pass_b" -lt "$slow_b" ] \
        && printf '%s\n' "$out12b" | grep >/dev/null '== fbneo lane (1 gates; one pool of 2 with the mame lane'; then
    ok "the fbneo and mame lanes ran as one pool: g_pass (mame) finished while g_slow3 (fbneo, queued first) still ran"
else
    fail "the fbneo and mame lanes did not share a pool: g_slow3 at line ${slow_b:-none}, g_pass at ${pass_b:-none}"
fi
if awk -F'\t' 'NR>1 && $1=="g_slow3" && $2=="fbneo"' "$T/l12b/results.tsv" | grep -q . \
        && awk -F'\t' 'NR>1 && $1=="g_pass" && $2=="mame"' "$T/l12b/results.tsv" | grep -q .; then
    ok "each result is recorded under its OWN lane"
else
    fail "a pooled result is missing or filed under the wrong lane"
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
    if c[2] not in ("release", "out", "ondemand"):
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
    # 14z-196 (ruled): an ondemand row's subject is pristine content only, and says so; 14z-199 (ruled, #265): or it
    # is an instrument with no default subject, run by hand with its operands; 14z-206 (ruled 2026-10-23, #291): or its
    # subject is the comparative capture sheets themselves; 14z-212 (ruled 2026-10-29, #334): or its subject is the
    # test harness itself
    if c[2] == "ondemand" and c[5].split(":")[0] not in ("pristine", "instrument", "sheets", "harness"):
        print(f"  FAIL: ondemand row {c[0]} needs the reason keyword pristine:, instrument:, sheets: or harness:, got {c[5][:40]!r}")
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

echo "10b. every registry row's script is EXECUTABLE (a gate without +x reads MISSING only at release)"
# WHY, and why HERE. run_all_emulator.sh classifies a non-executable row
# MISSING (case 9 above is that ground truth), but nothing in the STATIC tier
# ever looked: a gate committed without its +x bit stayed green through every
# pre-commit run and surfaced hours into a release sweep, as a MISSING row
# nobody could distinguish from a deleted script. This section already owns the
# SHIPPED registry, so the cheap static check belongs to it.
#
# THE PERTURBATION IS ONE FUNCTION the control section and the mode both call
# ([VSP-181]): a farm of SYMLINKS to the real scripts named by the real
# registry (so the check reads the shipped bits, not a rewrite of them), with
# exactly one replaced by a non-executable COPY.
regfarm() {   # regfarm <dest> <gate to break, "" for none>
    rm -rf "$1"; mkdir -p "$1/tests"
    cp "$REPO/tests/ci_emulator.tsv" "$1/tests/ci_emulator.tsv"
    awk -F'\t' '!/^#/ && NF {print $1}' "$REPO/tests/ci_emulator.tsv" | while read -r _g; do
        [ -e "$REPO/tests/$_g.sh" ] || continue
        if [ "$_g" = "$2" ]; then
            cp "$REPO/tests/$_g.sh" "$1/tests/$_g.sh"; chmod -x "$1/tests/$_g.sh"
        else
            ln -s "$REPO/tests/$_g.sh" "$1/tests/$_g.sh"
        fi
    done
}
regx() {      # regx <root>; prints the tally, exits 1 naming the unrunnable rows
    python3 - "$1" <<'PY10B'
import os, sys
root = sys.argv[1]
bad, seen = [], 0
for line in open(os.path.join(root, "tests", "ci_emulator.tsv")):
    if line.startswith("#") or not line.strip():
        continue
    g = line.split("\t")[0].strip()
    seen += 1
    p = os.path.join(root, "tests", g + ".sh")
    if not os.path.exists(p):
        bad.append((g, "absent"))
    elif not os.access(p, os.X_OK):
        bad.append((g, "not executable"))
print("%d rows, %d unrunnable" % (seen, len(bad)))
for g, why in bad[:10]:
    print("    %s.sh %s" % (g, why))
sys.exit(1 if bad else 0)
PY10B
}
# The gate the perturbation breaks: the registry's FIRST row, so the choice
# follows the shipped file rather than a name frozen here ([VSP-95]).
CTLG="$(awk -F'\t' '!/^#/ && NF {print $1; exit}' "$REPO/tests/ci_emulator.tsv")"
BREAK10=""
[ "$VS_CTL" = row-not-executable ] && BREAK10="$CTLG"
regfarm "$T/regfarm" "$BREAK10"
out10b="$(regx "$T/regfarm" 2>&1)" && ok "10b: $(printf '%s' "$out10b" | head -1)" \
    || fail "10b: a registry row names a script that cannot be run —
$out10b"
# MUST-FIRE CONTROL: the same farm with one REAL script's +x bit cleared.
regfarm "$T/regfarm_bad" "$CTLG"
regx "$T/regfarm_bad" >"$T/regx_bad.log" 2>&1 \
    && { vs_ctl_dead row-not-executable "the check passed with $CTLG.sh non-executable"; fail "row-not-executable"; } \
    || vs_ctl_fired row-not-executable "$CTLG.sh with its +x cleared -> $(sed -n '1p' "$T/regx_bad.log")"

echo "11. the runner EXPORTS the WIDE MAME default, and a caller's MAME_BIN wins (14z-133b)"
# Until 14z-133 the runner exported nothing: an unpinned gate ran `mame` on
# PATH (Homebrew's — three M16 sweep reds on "Unknown system 'vsavjw'"). Now
# the runner hands every gate the WIDE instrument unless the caller set one.
printf '#!/bin/sh\necho "mame_bin=${MAME_BIN:-UNSET}"\nexit 0\n' > "$FR/tests/g_mamebin.sh"
chmod +x "$FR/tests/g_mamebin.sh"
reg "$(row g_mamebin mame release - '')"
out11a="$( (unset MAME_BIN; MAME_WIDE_BIN="$T/fake_wide" run --lane mame --only g_mamebin --log "$T/l11a") )"
if grep -q "mame_bin=$T/fake_wide" "$T/l11a/g_mamebin.log" 2>/dev/null \
   && printf '%s' "$out11a" | grep >/dev/null "MAME_BIN.*(runner default)"; then
    ok "unset by the caller -> the gate receives the WIDE instrument, and the log says 'runner default'"
else
    fail "runner default not delivered: $(grep mame_bin "$T/l11a/g_mamebin.log" 2>/dev/null)"
fi
out11b="$( MAME_BIN="$T/caller_mame" MAME_WIDE_BIN="$T/fake_wide" run --lane mame --only g_mamebin --log "$T/l11b" )"
if grep -q "mame_bin=$T/caller_mame" "$T/l11b/g_mamebin.log" 2>/dev/null \
   && printf '%s' "$out11b" | grep >/dev/null "MAME_BIN.*(set by the caller)"; then
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
    [ "$v" = "$2" ] && printf '%s' "$d" | grep >/dev/null "$3" && ok "$1 -> $2 ($3)" || fail "$1 -> '$v' '$d', expected $2 / $3"
}
x14 g_cfired@flip PASS "honoured"
x14 g_clies@flip  FAIL "LIES"
x14 g_cref@flip   FAIL "REFUSED"
[ -z "$(awk -F'\t' '$1=="g_cmissing@flip"' "$T/l14b/results.tsv")" ] && ok "a gate that FAILED its own run gets no control row (nothing to execute)" \
    || fail "a control was executed for a gate whose own run failed"
# PASS 4 = three gates that passed their own run + the honoured @ row; FAIL 3 =
# g_cmissing (its FIRED line missing) + the LIES row + the REFUSED row
printf '%s' "$out14" | grep >/dev/null 'PASS 4 .*FAIL 3' && ok "tally PASS 4 / FAIL 3: the @ rows count like gates" \
    || fail "tally: $(printf '%s' "$out14" | grep -E '^PASS ' || echo '(none)')"
printf '%s' "$out14" | grep >/dev/null 'read:     fired 3 / declared 4' && ok "readout: fired 3 / declared 4" \
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

echo "14b. a control mode that CRASHES with a non-zero exit is DIED, not honoured (14z-196, #254)"
mkc g_cdie127 'no_such_helper_254; exit 1' "PASS: fine" "CONTROL FIRED: flip — caught"
mkc g_cquote  'echo "tests/other.sh: line 3: x: command not found"; echo "FAIL: caught"; exit 1' "PASS: fine" "CONTROL FIRED: flip — caught"
reg "$(row g_cdie127 mame release - '')" "$(row g_cquote mame release - '')"
run --lane mame --controls --log "$T/l14d" >/dev/null 2>&1 || true
v14d="$(awk -F'\t' '$1=="g_cdie127@flip"{print $4"|"$6}' "$T/l14d/results.tsv")"
case "$v14d" in FAIL\|*DIED*) ok "g_cdie127@flip -> FAIL (DIED: exit 127, its own shell error)" ;; *) fail "g_cdie127@flip -> '$v14d', expected FAIL / DIED" ;; esac
v14e="$(awk -F'\t' '$1=="g_cquote@flip"{print $4}' "$T/l14d/results.tsv")"
[ "$v14e" = PASS ] && ok "g_cquote@flip -> PASS (a real FAIL quoting another script's error stays honoured)" || fail "g_cquote@flip -> '$v14e', expected PASS"
ln -s "$T/runner_crashunread.sh" "$FR/tests/run_all_emulator_crashunread.sh"
(cd "$FR" && ROMDIR="$T/roms" MERGED=build/fake_merged sh tests/run_all_emulator_crashunread.sh --lane mame --controls --log "$T/l14f" >/dev/null 2>&1) || true
v14f="$(awk -F'\t' '$1=="g_cdie127@flip"{print $4}' "$T/l14f/results.tsv" 2>/dev/null)"
[ "$v14f" = PASS ] && vs_ctl_fired crash-unread "with no gate script handed to the control classifier, a mode dying of command-not-found (exit 127) reads an honoured PASS" \
                   || { vs_ctl_dead crash-unread "the copy with no gate script classified g_cdie127@flip '$v14f'"; fail "crash-unread"; }
rm -f "$FR/tests/run_all_emulator_crashunread.sh" "$FR/tests/g_cdie127.sh" "$FR/tests/g_cquote.sh"

echo "14c. a control mode that FAILs after saying NOT JUDGED measured nothing: UNJUDGED, not honoured (#310, 14z-210)"
# 14z-206: test_applier_page_browser's broken-page mode stalled under load, printed "page NOT judged" and exited 1, and
# the classifier read it HONOURED. A gate now marks such a run with a `NOT JUDGED: ` line; a crash beside it stays DIED.
mkc g_cunj    'echo "NOT JUDGED: the browser run did not complete"; echo "FAIL: page NOT judged"; exit 1' "PASS: fine" "CONTROL FIRED: flip — caught"
mkc g_cunjdie 'echo "NOT JUDGED: stalled"; no_such_helper_310; exit 1' "PASS: fine" "CONTROL FIRED: flip — caught"
mkc g_cjudged 'echo "  judged: NOT JUDGED would be a lie here"; echo "FAIL: caught"; exit 1' "PASS: fine" "CONTROL FIRED: flip — caught"
reg "$(row g_cunj mame release - '')" "$(row g_cunjdie mame release - '')" "$(row g_cjudged mame release - '')"
run --lane mame --controls --log "$T/l14g" >/dev/null 2>&1 || true
v14g="$(awk -F'\t' '$1=="g_cunj@flip"{print $4"|"$6}' "$T/l14g/results.tsv")"
case "$v14g" in
    FAIL\|*UNJUDGED*) ok "g_cunj@flip -> FAIL (UNJUDGED: the mode run measured nothing)" ;;
    PASS\|*) fail "g_cunj@flip -> '$v14g', expected FAIL / UNJUDGED"
             vs_ctl_is unjudged-honoured && vs_ctl_fired unjudged-honoured "with the NOT-JUDGED branch disabled, a mode that measured nothing reads an honoured PASS" ;;
    *) fail "g_cunj@flip -> '$v14g', expected FAIL / UNJUDGED" ;;
esac
v14h="$(awk -F'\t' '$1=="g_cunjdie@flip"{print $4"|"$6}' "$T/l14g/results.tsv")"
case "$v14h" in FAIL\|*DIED*) ok "g_cunjdie@flip -> FAIL (DIED: the crash class is read first)" ;; *) fail "g_cunjdie@flip -> '$v14h', expected FAIL / DIED" ;; esac
v14i="$(awk -F'\t' '$1=="g_cjudged@flip"{print $4}' "$T/l14g/results.tsv")"
[ "$v14i" = PASS ] && ok "g_cjudged@flip -> PASS (the words NOT JUDGED inside a line are not the marker)" || fail "g_cjudged@flip -> '$v14i', expected PASS"
if ! vs_ctl_is unjudged-honoured; then
    rm -f "$FR/tests/lib/classify.sh"; ln -s "$T/classify_unjudged.sh" "$FR/tests/lib/classify.sh"
    run --lane mame --controls --log "$T/l14j" >/dev/null 2>&1 || true
    rm -f "$FR/tests/lib/classify.sh"; ln -s "$CLSLIB" "$FR/tests/lib/classify.sh"
    v14j="$(awk -F'\t' '$1=="g_cunj@flip"{print $4}' "$T/l14j/results.tsv" 2>/dev/null)"
    [ "$v14j" = PASS ] && vs_ctl_fired unjudged-honoured "a classifier without the NOT-JUDGED branch reads a mode that measured nothing as an honoured PASS — section 14c catches it" \
        || { vs_ctl_dead unjudged-honoured "the classifier without the branch read g_cunj@flip '$v14j'"; fail "unjudged-honoured"; }
fi
rm -f "$FR/tests/g_cunj.sh" "$FR/tests/g_cunjdie.sh" "$FR/tests/g_cjudged.sh"

echo "14k. a control mode stopped by its host is DIED, never honoured (#321, 14z-210)"
# ERIS's 24 GB tmpfs /tmp filled under concurrent controls and 28 modes read HONOURED in 0-1 s, some logs holding only
# `mktemp: No space left on device`; another printed the gate's own FAIL after a refused copy. A FAIL whose words merely
# resemble those stays honoured.
mkc g_cenv     'echo "mktemp: No space left on device (os error 28) at path \"/tmp/tmp.x\""; exit 1' "PASS: fine" "CONTROL FIRED: flip — caught"
mkc g_cenvfail 'echo "cp: cannot create regular file \x27/tmp/t/vj_op.bin\x27: No space left on device"; echo "FAIL: views not delivered"; exit 1' "PASS: fine" "CONTROL FIRED: flip — caught"
mkc g_cenvlike 'echo "FAIL: caught — no space between the two fields"; exit 1' "PASS: fine" "CONTROL FIRED: flip — caught"
reg "$(row g_cenv mame release - '')" "$(row g_cenvfail mame release - '')" "$(row g_cenvlike mame release - '')"
run --lane mame --controls --log "$T/l14k" >/dev/null 2>&1 || true
v14k="$(awk -F'\t' '$1=="g_cenv@flip"{print $4"|"$6}' "$T/l14k/results.tsv")"
case "$v14k" in
    FAIL\|*DIED*environment*) ok "g_cenv@flip -> FAIL (DIED: an environment error is not a verdict)" ;;
    PASS\|*) fail "g_cenv@flip -> '$v14k', expected FAIL / DIED"
             vs_ctl_is env-honoured && vs_ctl_fired env-honoured "with the ENV-ERROR branch disabled, a mode stopped by a full disk reads an honoured PASS" ;;
    *) fail "g_cenv@flip -> '$v14k', expected FAIL / DIED" ;;
esac
v14l="$(awk -F'\t' '$1=="g_cenvfail@flip"{print $4"|"$6}' "$T/l14k/results.tsv")"
case "$v14l" in FAIL\|*DIED*environment*) ok "g_cenvfail@flip -> FAIL (DIED: the gate's own FAIL after a refused write is not the perturbation)" ;; *) fail "g_cenvfail@flip -> '$v14l', expected FAIL / DIED" ;; esac
v14m="$(awk -F'\t' '$1=="g_cenvlike@flip"{print $4}' "$T/l14k/results.tsv")"
[ "$v14m" = PASS ] && ok "g_cenvlike@flip -> PASS (a FAIL that only resembles the signatures stays honoured)" || fail "g_cenvlike@flip -> '$v14m', expected PASS"
if ! vs_ctl_is env-honoured; then
    rm -f "$FR/tests/lib/classify.sh"; ln -s "$T/classify_env.sh" "$FR/tests/lib/classify.sh"
    run --lane mame --controls --log "$T/l14n" >/dev/null 2>&1 || true
    rm -f "$FR/tests/lib/classify.sh"; ln -s "$CLSLIB" "$FR/tests/lib/classify.sh"
    v14n="$(awk -F'\t' '$1=="g_cenv@flip"{print $4}' "$T/l14n/results.tsv" 2>/dev/null)"
    [ "$v14n" = PASS ] && vs_ctl_fired env-honoured "a classifier without the ENV-ERROR branch reads a mode stopped by a full disk as an honoured PASS — section 14k catches it" \
        || { vs_ctl_dead env-honoured "the classifier without the branch read g_cenv@flip '$v14n'"; fail "env-honoured"; }
fi
rm -f "$FR/tests/g_cenv.sh" "$FR/tests/g_cenvfail.sh" "$FR/tests/g_cenvlike.sh"

echo "15. the commit of record and --stale (14z-180, GitHub #171 slice Q4)"
# commit.txt: HEAD on its first line when the tree is a git checkout, `no-git` otherwise;
# --stale: the selection is exactly the names tools/audit_emulator_staleness.py prints.
reg "$(row g_pass mame release - '')" "$(row g_out mame release - '')"
run --lane mame --log "$T/l15a" >/dev/null 2>&1 || true
c15a="$(head -1 "$T/l15a/commit.txt" 2>/dev/null)"
[ "$c15a" = "no-git" ] && ok "outside a git checkout commit.txt says no-git" || fail "commit.txt outside git: '$c15a'"
( cd "$FR" && git init -q && git -c user.name=t -c user.email=t@t add -A . >/dev/null 2>&1 \
    && git -c user.name=t -c user.email=t@t commit -q -m base ) || fail "could not init the fakerepo as git"
head15="$(cd "$FR" && git rev-parse HEAD 2>/dev/null)"
run --lane mame --log "$T/l15b" >/dev/null 2>&1 || true
c15b="$(head -1 "$T/l15b/commit.txt" 2>/dev/null)"
[ -n "$head15" ] && [ "$c15b" = "$head15" ] && ok "commit.txt's first line is the HEAD the run measured" \
                                             || fail "commit.txt in git: '$c15b', HEAD '$head15'"
# a --dry-run executes nothing and writes no commit of record (14z-191, GitHub #219): the
# staleness audit took the newest directory carrying commit.txt as the run of record (per gate since #211)
run --lane mame --dry-run --log "$T/l15e" >/dev/null 2>&1 || true
[ -d "$T/l15e" ] && [ ! -f "$T/l15e/commit.txt" ] && ok "--dry-run wrote no commit.txt (no run of record)" \
    || fail "--dry-run: commit.txt present (or no run directory) in $T/l15e"
# MUST-FIRE: the same dry run through the copy without the guard writes one
ln -s "$T/runner_dryrecords.sh" "$FR/tests/run_all_emulator_dryrec.sh"
(cd "$FR" && ROMDIR="$T/roms" MERGED=build/fake_merged sh tests/run_all_emulator_dryrec.sh --lane mame --dry-run --log "$T/l15f" >/dev/null 2>&1) || true
[ -f "$T/l15f/commit.txt" ] && vs_ctl_fired dry-run-records "without the guard a dry run writes $T/l15f/commit.txt" \
                           || { vs_ctl_dead dry-run-records "the unguarded copy wrote no commit.txt on a dry run"; fail "dry-run-records"; }
rm -f "$FR/tests/run_all_emulator_dryrec.sh"
# a stub staleness audit naming one gate: --stale runs it and nothing else
printf '#!/usr/bin/env python3\nimport sys\nif "--names" in sys.argv: print("g_out")\n' > "$FR/tools/audit_emulator_staleness.py"
run --lane mame --stale --log "$T/l15c" >/dev/null 2>&1 || true
n15="$(awk -F'\t' 'NR>1{print $1}' "$T/l15c/results.tsv" 2>/dev/null | tr '\n' ' ')"
[ "$n15" = "g_out " ] && ok "--stale ran exactly the named gate (g_out), not g_pass" || fail "--stale selection: '$n15'"
printf '#!/usr/bin/env python3\n' > "$FR/tools/audit_emulator_staleness.py"
out15="$(run --lane mame --stale --log "$T/l15d" 2>&1 || true)"
printf '%s' "$out15" | grep >/dev/null 'no emulator gate is stale' && [ ! -d "$T/l15d" ] \
    && ok "--stale with nothing named exits before writing a run directory and says so" \
    || fail "--stale with an empty list: $(printf '%s' "$out15" | head -1)"
# 14z-192 (GitHub #211): a --stale name outside the selected lanes is REFUSED by name, and a
# selection matching no gate exits 1 — neither prints GREEN nor writes a run directory, so
# neither can become the staleness audit's run of record.
reg "$(row g_pass mame release - '')" "$(row g_mist mister release - '')"
printf '#!/usr/bin/env python3\nimport sys\nif "--names" in sys.argv: print("g_mist")\n' > "$FR/tools/audit_emulator_staleness.py"
rc15g=0; out15g="$(run --lane mame --stale --log "$T/l15g" 2>&1)" || rc15g=$?
printf '%s' "$out15g" | grep >/dev/null 'REFUSED: --stale names gate(s) outside' && printf '%s' "$out15g" | grep >/dev/null 'g_mist(lane mister)' \
    && [ "$rc15g" != 0 ] && [ ! -d "$T/l15g" ] \
    && ok "--stale naming a mister-lane gate under --lane mame is REFUSED by name, exit $rc15g, no run directory" \
    || fail "--stale outside the lanes: exit $rc15g, $(printf '%s' "$out15g" | head -2 | tr '\n' ' ')"
printf '%s' "$out15g" | grep >/dev/null 'GREEN' && fail "the refused --stale run printed GREEN" || ok "the refused --stale run printed no GREEN"
rc15h=0; out15h="$(run --lane mame --only g_nosuch --log "$T/l15h" 2>&1)" || rc15h=$?
if printf '%s' "$out15h" | grep >/dev/null 'NOTHING SELECTED' && [ "$rc15h" != 0 ] && [ ! -d "$T/l15h" ]; then
    ok "a selection matching no gate exits $rc15h with NOTHING SELECTED and no run directory"
else
    fail "empty selection: exit $rc15h, run dir $([ -d "$T/l15h" ] && echo present || echo absent), $(printf '%s' "$out15h" | tail -1)"
fi
# MUST-FIRE: the same empty selection through the copy without the guard prints GREEN
ln -s "$T/runner_emptygreen.sh" "$FR/tests/run_all_emulator_emptygreen.sh"
out15i="$( (cd "$FR" && ROMDIR="$T/roms" MERGED=build/fake_merged sh tests/run_all_emulator_emptygreen.sh --lane mame --only g_nosuch --log "$T/l15i" 2>&1) || true )"
printf '%s' "$out15i" | grep >/dev/null '^GREEN' && [ -f "$T/l15i/commit.txt" ] \
    && vs_ctl_fired empty-green "without the guard an empty selection prints GREEN and writes $T/l15i/commit.txt" \
    || { vs_ctl_dead empty-green "the unguarded copy did not print GREEN with a run of record"; fail "empty-green"; }
rm -f "$FR/tests/run_all_emulator_emptygreen.sh"
rm -rf "$FR/.git" "$FR/tools/audit_emulator_staleness.py"

echo "16. --skip leaves a host-covered gate OUT, by name, with no row (#321, maintainer-ruled 2026-10-26 \"Parity only on the Mac\")"
# ERIS has no reference MAME for test_mame_parity's A/B section, so the gate is PARTIAL there, a red prereq row — and
# with #323 fixed that STOPS the tier. The ERIS tier passes --skip test_mame_parity; the Mac's run is the row of record.
reg "$(row g_prereq_bad prereq release - '')" "$(row g_prereq prereq release - '')" "$(row g_pass mame release - '')"
out16="$(run --skip 'g_prereq_b*' --log "$T/l16" || true)"
if ! printf '%s\n' "$out16" | grep >/dev/null "STOP:" && awk -F'\t' 'NR>1 && $1=="g_pass" && $4=="PASS"' "$T/l16/results.tsv" | grep >/dev/null . \
        && ! awk -F'\t' 'NR>1 && $1=="g_prereq_bad"' "$T/l16/results.tsv" | grep -q . \
        && printf '%s\n' "$out16" | grep >/dev/null "NOT HERE   --skip 'g_prereq_b\*': g_prereq_bad" \
        && printf '%s\n' "$out16" | grep >/dev/null "^not here  (--skip): g_prereq_bad"; then
    ok "--skip 'g_prereq_b*' left g_prereq_bad out (no row, no STOP), named it in the header and the readout, and ran the rest"
else
    fail "--skip: $(printf '%s\n' "$out16" | grep -E 'NOT HERE|STOP|not here' | head -3 | tr '\n' ' ')"
fi
out16b="$(run --log "$T/l16b" || true)"
printf '%s\n' "$out16b" | grep >/dev/null "STOP: the prereq lane is not green" && ! printf '%s\n' "$out16b" | grep >/dev/null "NOT HERE" \
    && ok "without --skip the same registry STOPS on the red prereq gate and names nothing as skipped" \
    || fail "without --skip: $(printf '%s\n' "$out16b" | grep -E 'NOT HERE|STOP' | head -2 | tr '\n' ' ')"

echo "17. a cold decrypt cache is built BEFORE the tier (#305, 14z-209)"
# 15 release-scope emulator gates read build/out/<set>_*.bin directly; with the cache cold two SKIPped (ERIS, fork A).
# Here a stub reads build/out directly, the cache starts cold, a stub decrypt tool writes full-length images, and the
# ROMDIR holds vsavj and vsav2 but not vhunt2, which must not be attempted.
RV="$T/roms_dv"; mkdir -p "$RV"; : > "$RV/vsavj.zip"; : > "$RV/vsav2.zip"
ln -s "$REPO/tests/lib/decrypt_cache.sh" "$FR/tests/lib/decrypt_cache.sh"
cat > "$FR/tools/cps2_decrypt.py" <<'PY'
import sys                            # a stub decrypt: <zip> <op> --data-out <dat>, full-length images
open(sys.argv[2], "wb").write(b"\x00" * 4194304); open(sys.argv[4], "wb").write(b"\x01" * 4194304)
PY
{ echo '#!/bin/sh'; echo ': "${MAME_BIN:-}"'
  echo '[ "$(wc -c < build/out/vsavj_data.bin 2>/dev/null | tr -d " ")" = 4194304 ] && echo "PASS: views" || { echo "SKIP: no build/out/vsavj_data.bin"; exit 0; }'; } \
    > "$FR/tests/g_views.sh"; chmod +x "$FR/tests/g_views.sh"
reg "$(row g_views mame release - '')"
s17() {  # s17 <runner script name> <log> -> S17 ok|bad
    rm -rf "$FR/build/out"
    _o="$( (cd "$FR" && ROMDIR="$RV" MERGED=build/fake_merged sh "tests/$1" --lane mame --strict --log "$2" 2>&1) || true)"
    S17=ok
    awk -F'\t' 'NR>1 && $1=="g_views" && $4=="PASS"' "$2/results.tsv" 2>/dev/null | grep -q . || S17=bad
    printf '%s\n' "$_o" | grep >/dev/null '^== decrypt views built before the tier: vsavj vsav2 (' || S17=bad
}
s17 run_all_emulator.sh "$T/l17"
[ "$S17" = ok ] && ok "from a cold cache the runner built vsavj and vsav2 (not vhunt2, absent) before the tier, and the direct reader PASSed" \
                || fail "section 17: a gate reading build/out directly met a cold cache (#305)"
if ! vs_ctl_is decrypt-warm-off; then
    ln -s "$T/runner_warmoff.sh" "$FR/tests/run_all_emulator_warmoff.sh"
    s17 run_all_emulator_warmoff.sh "$T/l17b"
    rm -f "$FR/tests/run_all_emulator_warmoff.sh"
    [ "$S17" = bad ] && vs_ctl_fired decrypt-warm-off "a runner that does not build the views first leaves the direct reader on a cold cache (it SKIPs) — section 17 catches it" \
        || { vs_ctl_dead decrypt-warm-off "the runner without the warm-up still gave the reader its views"; fail "decrypt-warm-off"; }
fi
rm -rf "$FR/build/out" "$FR/tools/cps2_decrypt.py" "$FR/tests/lib/decrypt_cache.sh"

echo "18. a LISTED gate's controls run beside one another in a pool; an unlisted gate's, and --jobs 1, one after another (#321, 14z-210)"
# g_cc declares two controls; each control mode writes its start second, sleeps 3 s and FAILs as it must. Beside one
# another their starts are at most a second apart; one after another, at least three.
mkcc() {  # mkcc <name> — a stub gate with two controls that record when they started
    { echo '#!/bin/sh'; echo "# $1.sh — a stub"
      echo '# MUST-FIRE: perturbed-copy: ca — a planted fault must fail'
      echo '# MUST-FIRE: perturbed-copy: cb — another planted fault must fail'
      echo ': "${MAME_BIN:-}"'
      echo 'case "${CONTROL:-}" in ca|cb) date +%s > "'"$T"'/cc_$(basename "$0" .sh)_$CONTROL"; sleep 3; echo "FAIL: caught"; exit 1 ;; esac'
      echo 'echo "PASS: fine"; echo "CONTROL FIRED: ca — caught"; echo "CONTROL FIRED: cb — caught"; exit 0'; } > "$FR/tests/$1.sh"
    chmod +x "$FR/tests/$1.sh"
}
mkcc g_cc; mkcc g_cc2
gap18() {  # gap18 <gate> -> the seconds between its two controls' starts
    _a="$(cat "$T/cc_$1_ca" 2>/dev/null || echo 0)"; _b="$(cat "$T/cc_$1_cb" 2>/dev/null || echo 999)"
    _d=$((_a - _b)); [ "$_d" -lt 0 ] && _d=$((0 - _d)); echo "$_d"
}
honoured18() {  # honoured18 <log dir> <gate> -> true when both control rows are honoured PASS rows
    [ "$(awk -F'\t' -v g="$2" '$1 == g "@ca" || $1 == g "@cb" {if ($4 == "PASS" && $6 ~ /honoured/) n++} END {print n + 0}' "$1/results.tsv")" = 2 ]
}
reg "$(row g_cc mame release - '')"
printf '# a fake list\ng_cc\t%s\tfake\ttest\n' "$(printf '%040d' 0)" > "$FR/tests/controls_concurrent_emu.txt"
rm -f "$T"/cc_*; run --lane mame --controls --jobs 4 --log "$T/l18a" >/dev/null 2>&1 || true
g18a="$(gap18 g_cc)"
if [ "$g18a" -le 1 ] && honoured18 "$T/l18a" g_cc; then ok "listed, --jobs 4: the two controls started ${g18a}s apart, both honoured"
else fail "listed, --jobs 4: the controls started ${g18a}s apart (want <= 1), or a row is not an honoured PASS"
     vs_ctl_is concurrent-off && vs_ctl_fired concurrent-off "with the test always false the listed gate's controls ran one after another (${g18a}s apart)"; fi
rm -f "$T"/cc_*; run --lane mame --controls --jobs 1 --log "$T/l18b" >/dev/null 2>&1 || true
g18b="$(gap18 g_cc)"
[ "$g18b" -ge 3 ] && honoured18 "$T/l18b" g_cc && ok "listed, --jobs 1: one after another (${g18b}s apart)" \
    || fail "listed, --jobs 1: the controls started ${g18b}s apart (want >= 3)"
: > "$FR/tests/controls_concurrent_emu.txt"
rm -f "$T"/cc_*; run --lane mame --controls --jobs 4 --log "$T/l18c" >/dev/null 2>&1 || true
g18c="$(gap18 g_cc)"
[ "$g18c" -ge 3 ] && honoured18 "$T/l18c" g_cc && ok "unlisted, --jobs 4: one after another (${g18c}s apart)" \
    || fail "unlisted, --jobs 4: the controls started ${g18c}s apart (want >= 3)"
# A FULL POOL DOES NOT DEADLOCK: two listed gates, two slots, four controls — each worker gives its slot back before it
# asks for its controls' slots. A watchdog kills the run after 60 s.
reg "$(row g_cc mame release - '')" "$(row g_cc2 mame release - '')"
printf 'g_cc\t%s\tfake\ttest\ng_cc2\t%s\tfake\ttest\n' "$(printf '%040d' 0)" "$(printf '%040d' 0)" > "$FR/tests/controls_concurrent_emu.txt"
rm -f "$T"/cc_*
( cd "$FR" && ROMDIR="$T/roms" MERGED=build/fake_merged sh tests/run_all_emulator.sh --lane mame --controls --jobs 2 --log "$T/l18d" > "$T/l18d.out" 2>&1 ) &
_p18=$!; _w=0; while kill -0 "$_p18" 2>/dev/null && [ "$_w" -lt 60 ]; do sleep 1; _w=$((_w + 1)); done
if kill -0 "$_p18" 2>/dev/null; then kill "$_p18" 2>/dev/null; pkill -P "$_p18" 2>/dev/null; fail "two listed gates in a pool of two did not finish in 60 s (a deadlock)"
else wait "$_p18" 2>/dev/null || true
     honoured18 "$T/l18d" g_cc && honoured18 "$T/l18d" g_cc2 && ok "two listed gates, two slots: all four controls ran and were honoured, in ${_w}s" \
         || fail "two listed gates, two slots: a control row is missing or not honoured"; fi
if ! vs_ctl_is concurrent-off; then
    reg "$(row g_cc mame release - '')"; printf 'g_cc\t%s\tfake\ttest\n' "$(printf '%040d' 0)" > "$FR/tests/controls_concurrent_emu.txt"
    ln -s "$T/runner_ccoff.sh" "$FR/tests/run_all_emulator_ccoff.sh"; rm -f "$T"/cc_*
    (cd "$FR" && ROMDIR="$T/roms" MERGED=build/fake_merged sh tests/run_all_emulator_ccoff.sh --lane mame --controls --jobs 4 --log "$T/l18e" >/dev/null 2>&1) || true
    rm -f "$FR/tests/run_all_emulator_ccoff.sh"; g18e="$(gap18 g_cc)"
    [ "$g18e" -ge 3 ] && vs_ctl_fired concurrent-off "a runner whose concurrent test is always false ran the listed gate's controls ${g18e}s apart — section 18 catches it" \
        || { vs_ctl_dead concurrent-off "the disabled runner still ran them ${g18e}s apart"; fail "concurrent-off"; }
fi
: > "$FR/tests/controls_concurrent_emu.txt"; rm -f "$FR/tests/g_cc.sh" "$FR/tests/g_cc2.sh" "$T"/cc_*

echo "19. --order starts a pooled lane LONGEST FIRST; --jobs 1 and no --order keep registry order (#321, 14z-210)"
# The earlier run gives g_o1 100 s plus a 250 s control row (350 in all) and g_o3 300 s; g_o2 has no row, so its cost is
# unknown and it goes first. Registry order is g_o1 g_o2 g_o3; longest first is g_o2 g_o1 g_o3.
mk g_o1 0 "one"; mk g_o2 0 "two"; mk g_o3 0 "three"
reg "$(row g_o1 mame release - '')" "$(row g_o2 mame release - '')" "$(row g_o3 mame release - '')"
printf 'gate\tlane\tscope\tverdict\tseconds\tdetail\ng_o1\tmame\trelease\tPASS\t100\t\ng_o1@x\tmame\trelease\tPASS\t250\t\ng_o3\tmame\trelease\tPASS\t300\t\n' > "$T/order.tsv"
ord19() {  # ord19 <runner> <args...> -> the gates in the order a dry run lists them
    _r="$1"; shift
    (cd "$FR" && ROMDIR="$T/roms" MERGED=build/fake_merged sh "tests/$_r" --lane mame --dry-run "$@" 2>&1) | awk '$1 ~ /^g_o[0-9]$/ {printf "%s ", $1}'
}
o19a="$(ord19 run_all_emulator.sh --jobs 4 --order "$T/order.tsv")"
[ "$o19a" = "g_o2 g_o1 g_o3 " ] && ok "--order, --jobs 4: $o19a(the unknown first, then 350 s, then 300 s)" \
    || { fail "--order, --jobs 4: got '$o19a', want 'g_o2 g_o1 g_o3 '"
         vs_ctl_is order-ignored && vs_ctl_fired order-ignored "with the sort disabled the lane kept registry order ('$o19a')"; }
o19b="$(ord19 run_all_emulator.sh --jobs 1 --order "$T/order.tsv")"
[ "$o19b" = "g_o1 g_o2 g_o3 " ] && ok "--order, --jobs 1: registry order ($o19b)" || fail "--order, --jobs 1: got '$o19b'"
o19c="$(ord19 run_all_emulator.sh --jobs 4)"
[ "$o19c" = "g_o1 g_o2 g_o3 " ] && ok "no --order, --jobs 4: registry order ($o19c)" || fail "no --order: got '$o19c'"
run --lane mame --jobs 4 --order "$T/order.tsv" --log "$T/l19" >/dev/null 2>&1 || true
[ "$(awk -F'\t' 'NR > 1 && $4 == "PASS"' "$T/l19/results.tsv" | wc -l | tr -d ' ')" = 3 ] && ok "the ordered run gave every gate its verdict (3 PASS)" \
    || fail "the ordered run lost a verdict: $(cut -f1,4 "$T/l19/results.tsv" | tr '\n' ' ')"
if ! vs_ctl_is order-ignored; then
    ln -s "$T/runner_orderoff.sh" "$FR/tests/run_all_emulator_orderoff.sh"
    o19d="$(ord19 run_all_emulator_orderoff.sh --jobs 4 --order "$T/order.tsv")"; rm -f "$FR/tests/run_all_emulator_orderoff.sh"
    [ "$o19d" != "g_o2 g_o1 g_o3 " ] && vs_ctl_fired order-ignored "a runner without the sort starts '$o19d' — section 19 catches it" \
        || { vs_ctl_dead order-ignored "the runner without the sort still ordered them longest first"; fail "order-ignored"; }
fi
rm -f "$FR/tests/g_o1.sh" "$FR/tests/g_o2.sh" "$FR/tests/g_o3.sh"

echo "20. a caller's exported JOBS reaches the gate unchanged; the runner's --jobs is its own (#321, 14z-210)"
# fork K: the runner's count was named JOBS, the name many gates read for their own legs, so `JOBS=8 ... --jobs 8` gave 8x8
{ echo '#!/bin/sh'; echo ': "${MAME_BIN:-}"'; echo 'echo "gate JOBS=${JOBS:-unset}"'; } > "$FR/tests/g_jobs.sh"; chmod +x "$FR/tests/g_jobs.sh"
reg "$(row g_jobs mame release - '')"
j20() {  # j20 <runner> <log> -> the JOBS the gate saw
    (cd "$FR" && JOBS=7 ROMDIR="$T/roms" MERGED=build/fake_merged sh "tests/$1" --lane mame --jobs 2 --log "$2" >/dev/null 2>&1) || true
    sed -n 's/^gate JOBS=//p' "$2/g_jobs.log" 2>/dev/null | head -1
}
v20="$(j20 run_all_emulator.sh "$T/l20")"
if [ "$v20" = 7 ]; then ok "exported JOBS=7 with --jobs 2: the gate saw JOBS=7"
else fail "exported JOBS=7 with --jobs 2: the gate saw JOBS=$v20"; vs_ctl_is jobs-leak && vs_ctl_fired jobs-leak "with the runner's count named JOBS the gate saw JOBS=$v20"; fi
if ! vs_ctl_is jobs-leak; then
    ln -s "$T/runner_jobsleak.sh" "$FR/tests/run_all_emulator_jobsleak.sh"
    v20b="$(j20 run_all_emulator_jobsleak.sh "$T/l20b")"; rm -f "$FR/tests/run_all_emulator_jobsleak.sh"
    [ "$v20b" = 2 ] && vs_ctl_fired jobs-leak "a runner whose count is named JOBS hands the gate JOBS=2 for an exported 7 — section 20 catches it" \
        || { vs_ctl_dead jobs-leak "the JOBS-named runner handed the gate JOBS=$v20b"; fail "jobs-leak"; }
fi
rm -f "$FR/tests/g_jobs.sh"

echo "21. with no TMPDIR from the caller a gate's temp files go to the run's own directory on disk (#321, 14z-210)"
# ERIS: concurrent controls filled the 24 GB tmpfs /tmp and 28 modes read HONOURED in 0-1 s; TMPDIR on disk cured it
{ echo '#!/bin/sh'; echo ': "${MAME_BIN:-}"'; echo 'echo "gate TMPDIR=${TMPDIR:-unset}"'; echo 'd="$(mktemp -d)" && echo "gate made $d"'; } > "$FR/tests/g_tmp.sh"; chmod +x "$FR/tests/g_tmp.sh"
reg "$(row g_tmp mame release - '')"
t21() {  # t21 <runner> <log> [env...] -> the TMPDIR the gate saw
    _r="$1"; _l="$2"; shift 2
    (cd "$FR" && env -u TMPDIR "$@" ROMDIR="$T/roms" MERGED=build/fake_merged sh "tests/$_r" --lane mame --log "$_l" > "$_l.out" 2>&1) || true
    sed -n 's/^gate TMPDIR=//p' "$_l/g_tmp.log" 2>/dev/null | head -1
}
v21="$(t21 run_all_emulator.sh "$T/l21")"
case "$v21" in
    */build/tmp/emu_*) ok "no TMPDIR from the caller: the gate's TMPDIR is the run's own ($(basename "$v21"))"
        [ -d "$v21" ] && fail "the run's temp directory $v21 is still there after the run" || ok "the run's temp directory is removed at the end" ;;
    *) fail "no TMPDIR from the caller: the gate saw TMPDIR=$v21"; vs_ctl_is tmp-ignored && vs_ctl_fired tmp-ignored "with the DISK-TMPDIR test disabled the gate saw TMPDIR=$v21" ;;
esac
mkdir -p "$T/caller_tmp"; v21b="$(t21 run_all_emulator.sh "$T/l21b" TMPDIR="$T/caller_tmp")"
[ "$v21b" = "$T/caller_tmp" ] && ok "a caller's TMPDIR is kept" || fail "a caller's TMPDIR=$T/caller_tmp reached the gate as $v21b"
t21 run_all_emulator.sh "$T/l21c" VS_TMP_MIN_GB=999999 >/dev/null
if grep -q 'this run needs 999999 GB' "$T/l21c.out" && [ ! -f "$T/l21c/g_tmp.log" ]; then ok "too little free temp space: the run refuses to start and names the shortfall"
else fail "with VS_TMP_MIN_GB=999999 the run did not refuse at the start ($(tail -1 "$T/l21c.out" 2>/dev/null))"; fi
if ! vs_ctl_is tmp-ignored; then
    ln -s "$T/runner_tmpoff.sh" "$FR/tests/run_all_emulator_tmpoff.sh"
    v21d="$(t21 run_all_emulator_tmpoff.sh "$T/l21d")"; rm -f "$FR/tests/run_all_emulator_tmpoff.sh"
    [ "$v21d" = unset ] && vs_ctl_fired tmp-ignored "a runner without the disk TMPDIR leaves the gate on the default /tmp (TMPDIR unset) — section 21 catches it" \
        || { vs_ctl_dead tmp-ignored "the runner without the disk TMPDIR handed the gate TMPDIR=$v21d"; fail "tmp-ignored"; }
fi
rm -f "$FR/tests/g_tmp.sh"

echo "22. a selected gate whose worker died before writing its row is a FAIL, never a GREEN on fewer rows (#321, 14z-210)"
# PILOT: tests/lib/measures.sh's scratch file was named by $$, which every pooled subshell shares; two stub gates
# finishing together removed each other's, a worker died under set -e, and a lane of three printed GREEN on PASS 1.
# g_lost kills the pooled worker that started it (its parent, or the timeout wrapper's parent), so no row is written.
{ echo '#!/bin/sh'; echo ': "${MAME_BIN:-}"'; echo 'p=$PPID; case "$(ps -o comm= -p "$p" 2>/dev/null)" in *timeout*) p="$(ps -o ppid= -p "$p" | tr -d " ")" ;; esac'
  echo 'kill -9 "$p"; echo "PASS: the worker is gone"; exit 0'; } > "$FR/tests/g_lost.sh"; chmod +x "$FR/tests/g_lost.sh"
mk g_kept 0 "kept"
reg "$(row g_lost mame release - '')" "$(row g_kept mame release - '')"
l22() {  # l22 <runner> <log>
    (cd "$FR" && ROMDIR="$T/roms" MERGED=build/fake_merged sh "tests/$1" --lane mame --jobs 2 --log "$2" > "$2.out" 2>&1) || true
}
l22 run_all_emulator.sh "$T/l22"
v22="$(awk -F'\t' '$1=="g_lost"{print $4"|"$6}' "$T/l22/results.tsv" 2>/dev/null)"
case "$v22" in
    FAIL\|LOST:*) ok "g_lost -> FAIL (LOST: no verdict row was written)" ;;
    *) fail "g_lost -> '$v22', expected FAIL / LOST"; vs_ctl_is lost-unread && vs_ctl_fired lost-unread "with the LOST-ROWS check disabled g_lost has no row ('$v22')" ;;
esac
grep -q '^GREEN' "$T/l22.out" && fail "a lane that lost a row printed GREEN" || ok "a lane that lost a row is NOT GREEN"
v22k="$(awk -F'\t' '$1=="g_kept"{print $4}' "$T/l22/results.tsv" 2>/dev/null)"
[ "$v22k" = PASS ] && ok "g_kept -> PASS beside it" || fail "g_kept -> '$v22k', expected PASS"
if ! vs_ctl_is lost-unread; then
    ln -s "$T/runner_lostoff.sh" "$FR/tests/run_all_emulator_lostoff.sh"
    l22 run_all_emulator_lostoff.sh "$T/l22b"; rm -f "$FR/tests/run_all_emulator_lostoff.sh"
    if grep -q '^GREEN' "$T/l22b.out" && ! awk -F'\t' '$1=="g_lost"' "$T/l22b/results.tsv" | grep -q .; then
        vs_ctl_fired lost-unread "a runner without the lost-rows check prints GREEN with g_lost missing — section 22 catches it"
    else vs_ctl_dead lost-unread "the runner without the check did not print GREEN on the lost row ($(tail -1 "$T/l22b.out"))"; fail "lost-unread"; fi
fi
rm -f "$FR/tests/g_lost.sh" "$FR/tests/g_kept.sh"

echo
[ "$rc" = 0 ] && echo "PASS: run_all_emulator.sh classifies every ground-truth case correctly" \
              || echo "FAIL: see above"
exit $rc
