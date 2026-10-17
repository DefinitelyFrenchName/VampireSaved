#!/bin/sh
# test_static_runner.sh — ground truth for tests/run_all_static.sh
# (14z-94, GitHub #30). ROM-free, ~3 s.
#
# WHAT: tests/run_all_static.sh's verdicts mean what they say: PASS / SKIP / FAIL counted
#   apart with SKIP in PROSE still PASS, an exit-0 shell crash FAIL, the anti-orphan
#   registry check both ways, --strict, the controls readout, and the cadence triggers (a
#   freeze-cadence gate runs when a path it follows changed), and a gate marked `# ORDER: last`
#   runs after every other gate of its tier (14z-185b, #188); and --confirm re-runs a red, the reader of
#   a changed input and nothing else, CARRYING the rest (14z-188, #188 route A wired); and the
#   gates a run starts do not inherit its STATIC_RESULTS_OUT (section 12c, 14z-199); and, the session run of #269
#   (14z-200, section 20), --confirm never carries a `# CONFIRM: always` core gate nor a gate whose controls the base
#   run did not execute, and is refused at a freeze.
# HOW: a synthetic repo of stub gates with known verdicts run through the REAL runner via
#   its registry files (never a copy of its logic); two shadow-tool controls unplug the
#   controls reader and blind the cadence trigger match.
# EXPECTS: every case reads its designed verdict; the unplugged reader lets a dead control
#   pass and fails section 11, the blind trigger leaves a triggered gate deferred and fails
#   section 14, and a planner with its prediction off carries a changed input's reader and
#   fails section 18; a planner blind to `# CONFIRM: always` or to a base's unexecuted
#   controls, and a runner taking --confirm at a freeze, each fail section 20 (#269).
#   Since #286 (14z-202, section 22): a dirty submodule whose fingerprint equals the base run's does not re-run
#   its reader, a changed one does; a gate re-run for a mention (R5) carries its controls, a gate whose code
#   reads the changed file directly (R1, R2, R6) executes them.
#
# MUST-FIRE: shadow-tool: reader-unplugged — a copy of run_all_static.sh that hands the classifier no gate script must let a stub with a declared-but-unfired control read PASS (mode: that copy is the runner every section drives, and section 11 must fail)
# MUST-FIRE: shadow-tool: trigger-blind — a copy of run_all_static.sh with its cadence TRIGGER match disabled must leave a freeze-cadence gate deferred although a path it depends on changed; section 14's triggered case must FAIL under it
# MUST-FIRE: shadow-tool: ondemand-triggered — a copy of run_all_static.sh whose ONDEMAND-NO-TRIGGER line is disabled must let a change to an ondemand gate's own script pull it into a session run; section 14i must catch it (in-gate in section 16; as a mode the gate FAILs)
# MUST-FIRE: shadow-tool: order-ignored — a copy of run_all_static.sh whose `# ORDER: last` test is disabled must run the marked stub FIRST, and section 16 must FAIL (mode: that copy drives every section; section 17 fires it in-run; 14z-185b, #188)
# MUST-FIRE: shadow-tool: crash-unread — a copy of run_all_static.sh that hands the CONTROL classifier no gate script must read a control mode that dies of `command not found` (exit 127) as HONOURED, and section 12b must FAIL (mode: that copy drives every section; section 12b fires it in-run; 14z-196, #254)
# MUST-FIRE: shadow-tool: results-inherited — a copy of run_all_static.sh whose RESULTS-OUT-PRIVATE unset is disabled must hand its STATIC_RESULTS_OUT to the gates it runs, and section 12c must FAIL (mode: that copy drives every section; section 12c fires it in-run; 14z-199)
# MUST-FIRE: shadow-tool: core-carried — a copy of tools/static_confirm.py whose plan ignores `# CONFIRM: always` (its CORE-ALWAYS line disabled) must CARRY the unchanged core stub g_e, and section 20 must FAIL (mode: that copy in the confirm repo; section 21 fires it in-run; #269, 14z-200)
# MUST-FIRE: shadow-tool: controls-carried — a copy of tools/static_confirm.py whose plan ignores a base row's unexecuted controls (its CONTROLS-UNEXECUTED line disabled) must CARRY g_d from a run made with --exec-controls none, and section 20 must FAIL (mode: that copy in the confirm repo; section 21 fires it in-run; #269, 14z-200)
# MUST-FIRE: shadow-tool: confirm-at-freeze — a copy of run_all_static.sh whose CONFIRM-SESSION-ONLY refusal is disabled must accept --confirm at --cadence freeze, and section 20 must FAIL (mode: that copy drives section 20; section 21 fires it in-run; #269, 14z-200)
# MUST-FIRE: shadow-tool: subfp-off — a copy of tools/static_confirm.py whose SUBMODULE-UNCHANGED drop is disabled must re-run the reader of an unchanged dirty submodule, and section 22 must FAIL (mode: that copy in the #286 repo; section 23 fires it in-run; #286, 14z-202)
# MUST-FIRE: shadow-tool: controls-always — a copy of tools/static_confirm.py whose plan never carries controls must execute g_f's control when only a file its data MENTIONS changed, and section 22 must FAIL (mode: that copy in the #286 repo; section 23 fires it in-run; #286, 14z-202)
# MUST-FIRE: shadow-tool: controls-never — a copy of tools/static_confirm.py whose CONTROLS-ON-REACH test is disabled must carry g_f's control when a data file its code reads directly changed, and section 22 must FAIL (mode: that copy in the #286 repo; section 23 fires it in-run; #286, 14z-202)
# MUST-FIRE: shadow-tool: prediction-off — a copy of tools/static_confirm.py whose plan marks nothing STALE must CARRY the stub whose input changed, and section 18 must FAIL (mode: that copy in the confirm repo)
#
# WHY A GATE FOR THE RUNNER. CLAUDE.md §4: "Verdict logic is itself tested. A
# test's classification code must be validated against known ground-truth
# scenarios before its verdicts are trusted — SMS shipped a wrong conclusion
# from a verdict bug, not a game bug."
#
# That applies with extra force here, because this runner's whole purpose is
# to be the thing nobody has to remember. If its PASS/SKIP/FAIL classifier is
# wrong, it converts "nobody runs the gates" into "everybody runs the gates
# and believes a wrong answer", which is strictly worse than the problem #30
# describes.
#
# THE ONE THAT MATTERS IS SKIP (GitHub #29). A gate whose inputs are missing
# prints `SKIP: ...` and exits 0. If the runner reads exit status alone, a
# fresh checkout reports GREEN while asserting nothing at all.
#
# Method: a synthetic repo containing stub gates with known verdicts, run
# through the REAL runner via its registry files — never a copy of its logic,
# so the classifier under test is the shipped one.
#
# HANDOFF's review-triage table note, moved into this header 14z-123 (verbatim; the
# documentation pass ruled a gate's WHY lives in the gate):
#   (review-triage, #30) ground truth for `run_all_static.sh`'s PASS/SKIP/FAIL
#   classifier. Sharpest case: SKIP in PROSE must still count PASS.
set -eu
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
rc=0
fail() { echo "  FAIL: $*"; rc=1; }

RUNNER="$REPO/tests/run_all_static.sh"
. "$REPO/tests/lib/controls.sh"; vs_ctl_mode "$0"
T="$(mktemp -d)"; trap 'rm -rf "$T"' EXIT INT TERM
FR="$T/fakerepo"
mkdir -p "$FR/tests"
# THE SHADOW TOOL: the runner with the classifier's 4th argument (the gate
# script) removed — the controls reader unplugged. Under
# CONTROL=reader-unplugged it is the runner every section drives.
SHADOW="$T/run_all_static_unplugged.sh"
sed 's|vs_classify "$_st" "$WORK/$g.out" 58 "tests/$g.sh"|vs_classify "$_st" "$WORK/$g.out" 58|' "$RUNNER" > "$SHADOW"
cmp -s "$RUNNER" "$SHADOW" && fail "could not unplug the reader — the vs_classify call moved"
chmod +x "$SHADOW"
# THE SECOND SHADOW (14z-162, #148): the runner with its cadence trigger match
# disabled — a changed path no longer pulls a deferred gate back in.
SHADOW_T="$T/run_all_static_triggerblind.sh"
sed 's|case "$_pth" in "$_t"\*) _hit="$_pth"; break 2 ;; esac   # TRIGGER-MATCH|: # TRIGGER-MATCH disabled|' "$RUNNER" > "$SHADOW_T"
cmp -s "$RUNNER" "$SHADOW_T" && fail "could not blind the trigger — the TRIGGER-MATCH line moved"
chmod +x "$SHADOW_T"
# THE FIFTH SHADOW (14z-196, maintainer-ruled 2026-10-09): the runner with its ONDEMAND-NO-TRIGGER
# line disabled — a changed path pulls an ondemand gate back in like any other listed gate.
SHADOW_D="$T/run_all_static_ondemandtriggered.sh"
sed 's|        if \[ "$_c" = ondemand \]; then echo "$_c $_g" >> "$WORK/deferred.txt"; continue; fi   # ONDEMAND-NO-TRIGGER|        : # ONDEMAND-NO-TRIGGER disabled|' "$RUNNER" > "$SHADOW_D"
cmp -s "$RUNNER" "$SHADOW_D" && fail "could not disable ONDEMAND-NO-TRIGGER — the line moved"
chmod +x "$SHADOW_D"
# THE THIRD SHADOW (14z-185b, #188): the runner with its `# ORDER: last` test disabled —
# a marked gate keeps its registry place.
SHADOW_O="$T/run_all_static_orderignored.sh"
sed 's|_last="$_last $_g"   # ORDER-LAST|_first="$_first $_g"   # ORDER-LAST disabled|' "$RUNNER" > "$SHADOW_O"
cmp -s "$RUNNER" "$SHADOW_O" && fail "could not disable ORDER: last — the ORDER-LAST line moved"
chmod +x "$SHADOW_O"
# THE FOURTH SHADOW (14z-196, #254): the runner with the control classifier's 3rd argument
# (the gate script) removed — a mode's own shell error is no longer recognised as a crash.
SHADOW_C="$T/run_all_static_crashunread.sh"
sed 's|vs_classify_control "$_cs" "$WORK/$1.ctl.$_n.out" "tests/$1.sh"|vs_classify_control "$_cs" "$WORK/$1.ctl.$_n.out"|' "$RUNNER" > "$SHADOW_C"
cmp -s "$RUNNER" "$SHADOW_C" && fail "could not unplug the crash reader — the vs_classify_control call moved"
chmod +x "$SHADOW_C"
# THE SIXTH SHADOW (14z-199): the runner with its RESULTS-OUT-PRIVATE unset disabled — the gates it
# runs inherit its results path.
SHADOW_R="$T/run_all_static_resultsinherited.sh"
sed 's|^unset STATIC_RESULTS_OUT   # RESULTS-OUT-PRIVATE|: # RESULTS-OUT-PRIVATE disabled|' "$RUNNER" > "$SHADOW_R"
cmp -s "$RUNNER" "$SHADOW_R" && fail "could not disable RESULTS-OUT-PRIVATE — the unset line moved"
chmod +x "$SHADOW_R"
if vs_ctl_is reader-unplugged; then ln -s "$SHADOW" "$FR/tests/run_all_static.sh"
elif vs_ctl_is results-inherited; then ln -s "$SHADOW_R" "$FR/tests/run_all_static.sh"
elif vs_ctl_is crash-unread; then ln -s "$SHADOW_C" "$FR/tests/run_all_static.sh"
elif vs_ctl_is trigger-blind; then ln -s "$SHADOW_T" "$FR/tests/run_all_static.sh"
elif vs_ctl_is ondemand-triggered; then ln -s "$SHADOW_D" "$FR/tests/run_all_static.sh"
elif vs_ctl_is order-ignored; then ln -s "$SHADOW_O" "$FR/tests/run_all_static.sh"
else ln -s "$RUNNER" "$FR/tests/run_all_static.sh"; fi
# the runner sources THE ONE classifier relative to its repo (14z-139), so
# the synthetic repo carries it too — the shipped lib, never a copy
mkdir -p "$FR/tests/lib"; ln -s "$REPO/tests/lib/classify.sh" "$FR/tests/lib/classify.sh"
# ...and the controls reader the classifier sources beside it (14z-147)
ln -s "$REPO/tests/lib/controls.sh" "$FR/tests/lib/controls.sh"
ln -s "$REPO/tests/lib/measures.sh" "$FR/tests/lib/measures.sh"   # the measurement reader beside it (14z-180): the first close tier died on its empty-list grep, which a fakerepo WITHOUT the library could not reach

mk() {  # mk <name> <exit> <output...>
    n="$1"; st="$2"; shift 2
    { echo "#!/bin/sh"; for l in "$@"; do echo "echo '$l'"; done; echo "exit $st"; } \
        > "$FR/tests/$n.sh"
    chmod +x "$FR/tests/$n.sh"
}

mk g_pass 0 "all good" "PASS: fine"
mk g_fail 1 "something broke" "FAIL: nope"
mk g_skip 0 "SKIP: no build at build/nope"
mk g_skip_indent 0 "  SKIP: indented skip marker"
# The nasty one: exits 0, and the word SKIP appears only in PROSE, not as a
# marker. It must be read as PASS, or every gate that documents the skip
# convention in its output would be miscounted.
mk g_prose 0 "checked 3 things, none had to be skipped" "PASS: prose only"
# The one that had to be paid for: a gate that prints a SKIP marker AND exits
# NON-ZERO. It ran, could not complete, and said so — that is a FAILURE, not a
# skip. Found 14z-128 in the emulator twin, where test_wide_profile.sh printed
# "SKIPPED: set FBNEO_REF" and exited 2 with "PARTIAL: the emulator superset
# invariant was NOT run", and the classifier called it a skip.
mk g_skip_fail 2 "  SKIPPED: no reference binary" "PARTIAL: the invariant was NOT run"

printf 'g_pass\ng_fail\ng_skip\ng_skip_indent\ng_prose\ng_skip_fail\n' > "$FR/tests/ci_portable.txt"
: > "$FR/tests/ci_static.txt"

out="$(cd "$FR" && sh tests/run_all_static.sh --tier portable 2>&1)" && st=0 || st=$?

echo "== 1. each verdict is classified correctly =="
check() {  # check <name> <expected-verdict>
    if printf '%s' "$out" | grep -qE "^  $1 +$2( |$)"; then
        echo "  ok: $1 -> $2"
    else
        fail "$1 was not classified $2:"
        printf '%s' "$out" | grep -E "^  $1" | sed 's/^/        /'
    fi
}
check g_pass PASS
check g_fail FAIL
check g_skip SKIP
check g_skip_indent SKIP
check g_prose PASS
check g_skip_fail FAIL

echo "== 2. the TALLY matches (the number a human reads) =="
if printf '%s' "$out" | grep -q "PASS 2 .*SKIP 2 .*FAIL 2"; then
    echo "  ok: PASS 2  SKIP 2  FAIL 2 (the SKIP-and-exit-2 gate counts FAIL)"
else
    fail "wrong tally: $(printf '%s' "$out" | grep -E '^PASS ' || echo '(none printed)')"
fi

echo "== 3. a FAIL makes the runner exit nonzero =="
[ "$st" != 0 ] && echo "  ok: exit $st" \
    || fail "the runner exited 0 with a failing gate — rule 6 cannot operate"

echo "== 4. THE #29 CONTROL — an all-SKIP run is not GREEN under --strict =="
printf 'g_skip\ng_skip_indent\n' > "$FR/tests/ci_portable.txt"
o2="$(cd "$FR" && sh tests/run_all_static.sh --tier portable 2>&1)" && s2=0 || s2=$?
if [ "$s2" = 0 ]; then
    echo "  ok: without --strict an all-SKIP run exits 0 (skips are legitimate"
    echo "      on a fresh checkout) — but it must SAY so:"
    printf '%s' "$o2" | grep -qE "SKIP 2" \
        && echo "      ok: the tally reports SKIP 2, so it cannot read as 2 passes" \
        || fail "the tally hides the skips"
else
    fail "a plain all-SKIP run failed; skips are legitimate without --strict"
fi
o3="$(cd "$FR" && sh tests/run_all_static.sh --tier portable --strict 2>&1)" && s3=0 || s3=$?
if [ "$s3" != 0 ]; then
    echo "  ok: --strict turns SKIP into failure (exit $s3)"
else
    fail "--strict accepted an all-SKIP run — the mode does nothing, and a"
    fail "      checkout with no build dirs would still report itself green"
fi

echo "== 5. a registered-but-missing gate is MISSING, not silently dropped =="
printf 'g_pass\nno_such_gate\n' > "$FR/tests/ci_portable.txt"
o4="$(cd "$FR" && sh tests/run_all_static.sh --tier portable 2>&1)" && s4=0 || s4=$?
if printf '%s' "$o4" | grep -q "MISSING" && [ "$s4" != 0 ]; then
    echo "  ok: reported MISSING and exited nonzero"
else
    fail "a registered gate that does not exist was ignored — a typo in the"
    fail "      registry would silently shrink the suite"
fi

echo "== 6. the anti-orphan check finds an unregistered emulator-free gate =="
printf 'g_pass\n' > "$FR/tests/ci_portable.txt"
mk g_orphan 0 "PASS: nobody registered me"
o5="$(cd "$FR" && sh tests/run_all_static.sh --tier portable 2>&1)"
if printf '%s' "$o5" | grep -q "g_orphan"; then
    echo "  ok: the unregistered gate is named"
else
    fail "an unregistered emulator-free gate was NOT reported — this check is"
    fail "      the whole anti-orphan mechanism (#30)"
fi
# ...and a gate that DOES use an emulator must not be nagged about.
mk g_emu 0 "PASS: I boot mame"
printf '#!/bin/sh\nMAME_BIN=x tools/run_mame.sh vsavj\n' > "$FR/tests/g_emu.sh"
chmod +x "$FR/tests/g_emu.sh"
o6="$(cd "$FR" && sh tests/run_all_static.sh --tier portable 2>&1)"
if printf '%s' "$o6" | grep -q "g_emu"; then
    fail "an EMULATOR gate was reported as an unregistered static gate — the"
    fail "      check would nag about every soak in the repo and be ignored"
else
    echo "  ok: an emulator gate is correctly left out of the nag list"
fi

echo "== 7. the real registries parse, and name real files =="
bad=0
for f in tests/ci_portable.txt tests/ci_static.txt; do
    [ -f "$f" ] || { fail "$f is missing"; bad=1; continue; }
    n=0
    while read -r g; do
        case "$g" in ""|\#*) continue;; esac
        n=$((n + 1))
        [ -x "tests/$g.sh" ] || { fail "$f names $g, which is not executable"; bad=1; }
    done < "$f"
    echo "  ok: $f — $n entries, all present"
done
[ "$bad" = 0 ] || rc=1

echo "== 8. exit 0 after a SHELL ERROR is FAIL; a MAME teardown segfault line is not (14z-139) =="
# The sweep runner has read this shape as FAIL since 14z-134 (a 65-minute
# Verilator gate recorded `PASS 0s` after a `${VAR:?}` abort behind an EXIT
# trap, [VSP-176]); THIS runner kept its own classifier copy and lacked the
# branch, so the pre-commit command said PASS where the sweep said FAIL for
# the same log. Both now source tests/lib/classify.sh. The benign look-alike
# — MAME segfaulting at teardown AFTER the summary line, digits where the
# NAME would be — must still PASS.
mk g_shellcrash 0 "tests/g_shellcrash.sh: line 3: FOO: set FOO to a dir OUTSIDE the repo"
mk g_segv 0 "PASS: the summary line" "tests/g_segv.sh: line 64:  2444 Segmentation fault: 11  REPLAY=x"
printf 'g_pass\ng_shellcrash\ng_segv\n' > "$FR/tests/ci_portable.txt"
o8="$(cd "$FR" && sh tests/run_all_static.sh --tier portable 2>&1)" && s8=0 || s8=$?
if printf '%s' "$o8" | grep -qE '^  g_shellcrash +FAIL .*\(exit 0 after a shell error\)'; then
    echo "  ok: a shell-error line with exit 0 is FAIL, and the row says why"
else
    fail "shell-error crash not classified FAIL (was PASS before 14z-139):"
    printf '%s' "$o8" | grep -E '^  g_shellcrash' | sed 's/^/        /'
fi
printf '%s' "$o8" | grep -qE '^  g_segv +PASS' \
    && echo "  ok: a MAME teardown segfault line after the summary stays PASS" \
    || fail "the benign segfault shape was not PASS"
printf '%s' "$o8" | grep -q "PASS 2 .*SKIP 0 .*FAIL 1" \
    && echo "  ok: tally PASS 2  SKIP 0  FAIL 1" \
    || fail "wrong tally: $(printf '%s' "$o8" | grep -E '^PASS ' || echo '(none printed)')"
[ "$s8" != 0 ] && echo "  ok: and the runner exits nonzero ($s8)" \
    || fail "the runner exited 0 with an exit-0 crash in the tier"
# THE LOCK on the cause: one classifier, sourced by all three runners. The
# 14z-135 census found two DIFFERING copies; a third copy is how it recurs.
for r in run_all_static run_all_emulator run_battery_m2; do
    grep -q '^\. "\$REPO/tests/lib/classify.sh"' "tests/$r.sh" \
        && echo "  ok: $r.sh sources tests/lib/classify.sh" \
        || fail "$r.sh does not source tests/lib/classify.sh — a second classifier copy"
done
for r in run_all_static run_all_emulator run_battery_m2; do
    if grep -v '^\s*#' "tests/$r.sh" | grep -q 'line \[0-9\]+: \[A-Za-z_\]'; then
        fail "$r.sh carries its own copy of the shell-error regex beside the lib's"
    fi
done

echo "== 9. NOTE-class numbers are SURFACED and are not verdicts (14z-141) =="
# A NOTE is per NUMBER where a verdict is per GATE, so it must not touch the
# tally, must not change the exit status, and must be visible without anyone
# opening a log. The must-NOT-fire half matters as much: prose that merely
# contains the word "note" is not a NOTE line.
mk g_note 0 "PASS: fine" "NOTE: rule5.gameplay in-table 15 baked 202"
mk g_noteprose 0 "PASS: fine" "a note: something" " Note: prose"
printf 'g_pass\ng_note\ng_noteprose\n' > "$FR/tests/ci_portable.txt"
: > "$FR/tests/ci_static.txt"
out="$(cd "$FR" && sh tests/run_all_static.sh 2>&1)" && st=0 || st=$?
# Read the BLOCK, not the whole log: the tier prints a result row per gate,
# so a bare grep for a gate name matches its verdict line and any control
# built on that is dead (measured on the first write, 14z-141).
noteblock() { printf '%s\n' "$1" | awk '/^== NOTE-class numbers/{f=1;next} /^====/{f=0} f'; }
printf '%s\n' "$(noteblock "$out")" | grep -q 'g_note  *rule5.gameplay in-table 15 baked 202' \
    && echo "  ok: the NOTE line is surfaced, named by its gate" \
    || fail "the NOTE line was not surfaced"
printf '%s\n' "$out" | grep -q 'PASS 3 ' \
    && echo "  ok: a NOTE does not disturb the tally (3 PASS)" \
    || fail "the tally moved: $(printf '%s\n' "$out" | grep '^PASS ')"
[ "$st" = 0 ] && echo "  ok: a NOTE does not change the exit status" \
              || fail "a NOTE changed the runner's exit status ($st)"
printf '%s\n' "$(noteblock "$out")" | grep -q 'g_noteprose' \
    && fail "prose containing 'note' was surfaced as a NOTE" \
    || echo "  ok: prose containing the word note is NOT a NOTE line"
# the control's own LIVENESS: the block reader must really see g_note there
printf '%s\n' "$(noteblock "$out")" | grep -q 'g_note ' \
    || fail "the block reader sees nothing - the must-NOT-fire control is dead"
# and the empty case must say so rather than printing a row per gate
printf 'g_pass\n' > "$FR/tests/ci_portable.txt"
out2="$(cd "$FR" && sh tests/run_all_static.sh 2>&1)"
printf '%s\n' "$(noteblock "$out2")" | grep -q '(none)' \
    && echo "  ok: with no NOTE anywhere the block says (none)" \
    || fail "the empty NOTE block printed rows: $(printf '%s\n' "$out2" | grep -A3 'NOTE-class')"

# ── THE MID-RUN EDIT: A FAILURE UNDER A CHANGING FILE IS SUSPECT, NOT A FINDING
# (14z-144). The runner has always DETECTED that tracked files changed during a
# run — and on 2026-09-09 it detected exactly that, named
# tests/run_all_emulator.sh, and the reader still drew the wrong conclusion,
# because the message asserted the wrong CAUSE ("these gates write into tracked
# paths") and never connected the changed file to the two gates that failed
# BECAUSE of it. Detection without attribution is a message people skip.
echo "== 10. a gate that FAILS while a file it reads changes is SUSPECT =="
# The tree check only runs in a GIT CHECKOUT — the synthetic repo is not one
# by default, so without this the section asserts against a message that can
# never appear (paid for while writing it, 14z-144).
printf 'original\n' > "$FR/shared_input.txt"
mk g_reader 1 "FAIL: I read shared_input.txt and did not like it"
( cd "$FR" \
  && git init -q . >/dev/null 2>&1 \
  && git -c user.email=t@t -c user.name=t add -A >/dev/null 2>&1 \
  && git -c user.email=t@t -c user.name=t commit -qm fixture >/dev/null 2>&1 ) || true
if ! ( cd "$FR" && git rev-parse --git-dir >/dev/null 2>&1 ); then
    echo "  SKIP: could not git-init the synthetic repo — the tree check is"
    echo "        a no-op outside a checkout, so this section cannot run"
else
# change it AFTER the snapshot is taken: run the runner with a gate that
# mutates the tracked file, which is indistinguishable to the runner from a
# human editing it — and that is the point, since it cannot tell them apart.
# NOT via mk(): mk ends the stub with `exit $st`, so an APPENDED line is dead
# code after the exit and the fixture silently does nothing (paid for while
# writing this section — the assertions failed against a scenario that never
# happened, which is the same shape as the defect being tested).
{ echo "#!/bin/sh"
  echo "echo 'PASS: and I edited a tracked file'"
  echo 'echo changed > "$(dirname "$0")/../shared_input.txt"'
  echo "exit 0"; } > "$FR/tests/g_editor.sh"
chmod +x "$FR/tests/g_editor.sh"
printf 'g_editor\ng_reader\n' > "$FR/tests/ci_portable.txt"
o10="$(cd "$FR" && sh tests/run_all_static.sh --tier portable 2>&1)" || true
if printf '%s' "$o10" | grep -q 'TRACKED FILES CHANGED DURING THE RUN'; then
    echo "  ok: the tree change is reported as a FACT with both causes offered"
else
    fail "the reworded tree-change message did not appear"
fi
if printf '%s' "$o10" | grep -q 'a GATE wrote into a tracked path' \
   && printf '%s' "$o10" | grep -q 'the TREE WAS EDITED while the run'; then
    echo "  ok: BOTH causes are offered — the message no longer asserts one"
else
    fail "the message still asserts a single cause; the mid-run-edit cause is"
    fail "      the one that cost a run on 2026-09-09"
fi
if printf '%s' "$o10" | grep -q 'SUSPECT'; then
    echo "  ok: the failing gate's verdict is marked SUSPECT"
else
    fail "a gate failed while a tracked file changed and its verdict was"
    fail "      presented as a finding — this is the 14z-144 defect"
fi
# THE MUST-NOT-FIRE CONTROL: a clean run must NOT cry suspect, or the caveat
# becomes noise and gets skipped exactly like the message it replaces.
printf 'g_pass\ng_fail\n' > "$FR/tests/ci_portable.txt"
o11="$(cd "$FR" && sh tests/run_all_static.sh --tier portable 2>&1)" || true
if printf '%s' "$o11" | grep -q 'SUSPECT'; then
    fail "a run that changed NOTHING reported SUSPECT — the caveat would be"
    fail "      noise, and a caveat that always fires is not read"
else
    echo "  ok: control — a failure on a QUIET tree is NOT marked suspect"
fi
fi

echo "== 11. the must-fire controls are READ: declared vs fired (14z-147) =="
# A gate that declares a control in its header and never prints CONTROL FIRED
# for it is FAIL; a CONTROL DEAD line is FAIL; a firing no header declares is
# FAIL; a gate with no declaration at all is untouched (identity for the
# gates that predate the grammar). The stubs are written by hand because mk()
# cannot carry header lines.
mkc() {  # mkc <name> <exit> <header-line> <output lines...>
    n="$1"; st="$2"; hdr="$3"; shift 3
    { echo "#!/bin/sh"; echo "# $n.sh — a stub"; echo "$hdr"; for l in "$@"; do echo "echo '$l'"; done; echo "exit $st"; } > "$FR/tests/$n.sh"
    chmod +x "$FR/tests/$n.sh"
}
mkc g_cfired   0 "# MUST-FIRE: perturbed-copy: flip — a flipped byte must fail" "PASS: fine" "CONTROL FIRED: flip — caught"
mkc g_cmissing 0 "# MUST-FIRE: perturbed-copy: flip — a flipped byte must fail" "PASS: fine"
mkc g_cdead    0 "# MUST-FIRE: perturbed-copy: flip — a flipped byte must fail" "PASS: fine" "CONTROL DEAD: flip — the copy passed"
mkc g_cghost   0 "# a header with no declaration" "PASS: fine" "CONTROL FIRED: ghost — nobody declared me"
mkc g_cnone    0 "# MUST-FIRE: none — a lister asserts nothing" "PASS: fine"
printf 'g_pass\ng_cfired\ng_cmissing\ng_cdead\ng_cghost\ng_cnone\n' > "$FR/tests/ci_portable.txt"
o11="$(cd "$FR" && sh tests/run_all_static.sh --tier portable --exec-controls none 2>&1)" && s11=0 || s11=$?
c11() {  # c11 <gate> <verdict>
    printf '%s' "$o11" | grep -qE "^  $1 +$2( |$)" && echo "  ok: $1 -> $2" \
        || { fail "$1 not classified $2:"; printf '%s' "$o11" | grep -E "^  $1" | sed 's/^/        /'; }
}
c11 g_cfired PASS
c11 g_cmissing FAIL
c11 g_cdead FAIL
c11 g_cghost FAIL
c11 g_cnone PASS
c11 g_pass PASS
printf '%s' "$o11" | grep -q 'read:     fired 1 / declared 3' \
    && echo "  ok: the readout counts fired 1 / declared 3 (three declaring stubs, one fired)" \
    || fail "readout wrong: $(printf '%s' "$o11" | grep 'read:' || echo '(none)')"
printf '%s' "$o11" | grep -q 'gates declaring none: 1; undeclared: 1' \
    && echo "  ok: one none-declaring gate and one undeclared gate (g_pass) are counted, not failed" \
    || fail "the none/undeclared counts are wrong: $(printf '%s' "$o11" | grep 'read:' || echo '(none)')"
printf '%s' "$o11" | grep -q 'PASS 3 .*SKIP 0 .*FAIL 3' \
    && echo "  ok: tally PASS 3  FAIL 3 — a red controls block is plain FAIL, no fourth verdict" \
    || fail "wrong tally: $(printf '%s' "$o11" | grep -E '^PASS ' || echo '(none printed)')"
[ "$s11" != 0 ] && echo "  ok: and the runner exits nonzero ($s11)" || fail "a dead control left the runner green"

echo "== 11b. a NON-PASS gate after a declaring one adds nothing to the readout and keeps its own label (GitHub #140) =="
# The reader runs only on a PASS, so before 14z-183 a FAIL row kept the previous gate's
# VS_CTL_*: `g_cfired g_fail g_fail` read fired 3 / declared 3, `g_cnone g_fail` counted
# two none-declaring gates, and a shell-crash stub after a controls-red gate took that
# gate's detail as its label. The orders below are the ticket's reproduction.
mk g_shellcrash 0 "tests/g_shellcrash.sh: line 3: FOO: parameter not set"
printf 'g_cfired\ng_fail\ng_fail\ng_cnone\ng_fail\ng_cmissing\ng_shellcrash\n' > "$FR/tests/ci_portable.txt"
o11b="$(cd "$FR" && sh tests/run_all_static.sh --tier portable --exec-controls none 2>&1)" || true
printf '%s' "$o11b" | grep -q 'read:     fired 1 / declared 2' \
    && echo "  ok: fired 1 / declared 2 — only g_cfired's and g_cmissing's own declarations, none re-added after a FAIL" \
    || fail "#140 readout wrong: $(printf '%s' "$o11b" | grep 'read:' || echo '(none)')"
printf '%s' "$o11b" | grep -q 'gates declaring none: 1;' \
    && echo "  ok: one none-declaring gate, not re-counted by the FAIL after it" \
    || fail "#140 none count wrong: $(printf '%s' "$o11b" | grep 'read:' || echo '(none)')"
printf '%s' "$o11b" | grep -qE '^  g_shellcrash +FAIL .*\(exit 0 after a shell error\)$' \
    && echo "  ok: the shell-crash stub after a controls-red gate keeps its own label" \
    || fail "#140 label: $(printf '%s' "$o11b" | grep -E '^  g_shellcrash' || echo '(none)')"

echo "== 12. the must-fire controls are EXECUTED: CONTROL=<name> must reach the gate's own FAIL =="
# Four stubs: one honours the mode (FAIL under it), one LIES (stays green),
# one REFUSES (declares a name it never reads), one DIES (a shell error under
# the mode). Only the first is a pass; the rows name the others.
mkx() {  # mkx <name> <body-under-mode>
    { echo "#!/bin/sh"; echo "# $1.sh — a stub"
      echo "# MUST-FIRE: perturbed-copy: flip — a flipped byte must fail"
      echo 'if [ "${CONTROL:-}" = flip ]; then'; echo "$2"; echo 'fi'
      echo "echo 'PASS: fine'"; echo "echo 'CONTROL FIRED: flip — caught'"; echo "exit 0"; } > "$FR/tests/$1.sh"
    chmod +x "$FR/tests/$1.sh"
}
mkx g_xhon  'echo "FAIL: the flipped input was caught"; exit 1'
mkx g_xlies 'echo "PASS: nothing changed"; exit 0'
mkx g_xref  'echo "REFUSED: CONTROL=flip is not a mode of this gate"; exit 3'
mkx g_xdied 'echo "tests/g_xdied.sh: line 9: FOO: parameter not set"; exit 0'
printf 'g_xhon\ng_xlies\ng_xref\ng_xdied\n' > "$FR/tests/ci_portable.txt"
o12="$(cd "$FR" && STATIC_RESULTS_OUT="$T/r12.tsv" sh tests/run_all_static.sh --tier portable 2>&1)" && s12=0 || s12=$?
for pair in "g_xlies:LIES" "g_xref:REFUSED" "g_xdied:DIED"; do
    g="${pair%%:*}"; v="${pair##*:}"
    printf '%s' "$o12" | grep -qE "^  $g +CONTROL $v: flip" && echo "  ok: $g -> CONTROL $v" \
        || { fail "$g was not reported CONTROL $v:"; printf '%s' "$o12" | grep -E "^  $g" | sed 's/^/        /'; }
done
printf '%s' "$o12" | grep -qE "^  g_xhon +CONTROL" && fail "the honoured control printed a red row" || echo "  ok: g_xhon (honoured) prints no red row"
printf '%s' "$o12" | grep -q 'executed: 4  honoured 1  lies 1  refused 1  died 1' \
    && echo "  ok: readout — executed 4, honoured 1, lies 1, refused 1, died 1" \
    || fail "executable readout wrong: $(printf '%s' "$o12" | grep 'executed:' || echo '(none)')"
# where the time went (2026-09-14): printed only when controls were executed
printf '%s' "$o12" | grep -qE '^  time:     gates [0-9]+s  controls [0-9]+s  wall [0-9]+s  \(costliest controls: g_x[a-z]+ [0-9]+s over 1' \
    && echo "  ok: readout — where the time went: gates, controls, wall and the costliest controls" \
    || fail "no time line after executed controls: $(printf '%s' "$o12" | grep 'time:' || echo '(none)')"
printf '%s' "$o12" | grep -q 'PASS 4 .*SKIP 0 .*FAIL 3' \
    && echo "  ok: tally PASS 4  FAIL 3 — every gate passed its own run, three controls failed theirs" \
    || fail "wrong tally: $(printf '%s' "$o12" | grep -E '^PASS ' || echo '(none printed)')"
printf '%s' "$o12" | grep -q 'g_xlies(control:flip:LIES)' && echo "  ok: the failure list names the gate, the control and the verdict" \
    || fail "the failure list does not name the lying control: $(printf '%s' "$o12" | grep '^failed:' || echo '(none)')"
[ "$s12" != 0 ] && echo "  ok: and the runner exits nonzero ($s12)" || fail "a lying control left the runner green"
# the per-control times are KEPT (14z-190, #188 option D): one row per executed control beside
# results.tsv — gate, control, verdict, seconds — so a confirm plan can be priced in wall time
CT12="$T/r12.controls.tsv"
if [ -f "$CT12" ] && [ "$(grep -vc '^#' "$CT12")" = 4 ] \
        && grep -qE "^g_xhon	flip	HONOURED	[0-9]+$" "$CT12" && grep -qE "^g_xlies	flip	LIES	[0-9]+$" "$CT12" \
        && grep -qE "^g_xref	flip	REFUSED	[0-9]+$" "$CT12" && grep -qE "^g_xdied	flip	DIED	[0-9]+$" "$CT12"; then
    echo "  ok: the run kept its control times beside results.tsv — 4 rows, gate / control / verdict / seconds"
else fail "no per-control times beside results.tsv ($CT12): $(grep -v '^#' "$CT12" 2>/dev/null | tr '\n' '|' || echo '(no file)')"; fi
# the MUST-NOT-FIRE half: --exec-controls none runs nothing and the four stubs are all PASS
o12b="$(cd "$FR" && STATIC_RESULTS_OUT="$T/r12b.tsv" sh tests/run_all_static.sh --tier portable --exec-controls none 2>&1)" && s12b=0 || s12b=$?
[ -f "$T/r12b.controls.tsv" ] && fail "--exec-controls none wrote a control-times file" \
    || echo "  ok: with --exec-controls none no control-times file is written"
[ "$s12b" = 0 ] && printf '%s' "$o12b" | grep -q 'PASS 4 .*FAIL 0' && printf '%s' "$o12b" | grep -q 'executed: (off' \
    && echo "  ok: control — with --exec-controls none the same four stubs are PASS 4 and the readout says off" \
    || fail "--exec-controls none still executed or failed something: $(printf '%s' "$o12b" | grep -E '^PASS |executed' || echo '(none)')"
printf '%s' "$o12b" | grep -q '^  time:' && fail "--exec-controls none printed a time line" \
    || echo "  ok: with --exec-controls none there is no time line"
# and the portable-only selector leaves a STATIC gate's controls unexecuted
: > "$FR/tests/ci_portable.txt"; printf 'g_xlies\n' > "$FR/tests/ci_static.txt"
o12c="$(cd "$FR" && ROMDIR="$T" sh tests/run_all_static.sh --tier static --exec-controls portable 2>&1)" && s12c=0 || s12c=$?
[ "$s12c" = 0 ] && echo "  ok: --exec-controls portable does not execute a static-tier gate's controls" \
    || fail "--exec-controls portable executed a static gate's control: $(printf '%s' "$o12c" | grep 'CONTROL' || echo '(none)')"
: > "$FR/tests/ci_static.txt"

echo "== 12b. a control mode that CRASHES with a non-zero exit is DIED, not HONOURED (14z-196, #254) =="
# A missing command exits 127 and a set -u abort exits 1: both FAIL the gate's run, and the
# classifier used to read that as the negative control reaching its predicate. The shell's
# own line about the gate script is the evidence; a real FAIL that QUOTES another script's
# error must stay honoured.
mkx g_xdie127 'no_such_helper_254; exit 1'
mkx g_xquote  'echo "tests/other.sh: line 3: x: command not found"; echo "FAIL: the flipped input was caught"; exit 1'
printf 'g_xdie127\ng_xquote\n' > "$FR/tests/ci_portable.txt"
o12c="$(cd "$FR" && STATIC_RESULTS_OUT="$T/r12c.tsv" sh tests/run_all_static.sh --tier portable 2>&1)" || true
printf '%s' "$o12c" | grep -qE "^  g_xdie127 +CONTROL DIED: flip" && echo "  ok: a mode dying of command-not-found (exit 127) -> CONTROL DIED" \
    || { fail "a crashing mode was not DIED:"; printf '%s' "$o12c" | grep -E '^  g_xdie127' | sed 's/^/        /'; }
printf '%s' "$o12c" | grep -qE "^  g_xquote +CONTROL" && fail "a real FAIL quoting another script's error read as a crash" \
    || echo "  ok: a real FAIL quoting another script's shell error stays honoured"
# the copy runs INSIDE the synthetic repo (the runner takes its repo from its own path; run from $T it
# judged nothing, and the absence of a red row read as a firing — 14z-199), and the firing needs the
# positive reading: both modes HONOURED
cp "$SHADOW_C" "$FR/tests/run_all_static_cu"
o12d="$(cd "$FR" && STATIC_RESULTS_OUT="$T/r12d.tsv" sh tests/run_all_static_cu --tier portable 2>&1)" || true
rm -f "$FR/tests/run_all_static_cu"
if printf '%s' "$o12d" | grep -qE "^  g_xdie127 +CONTROL" || ! printf '%s' "$o12d" | grep -q 'executed: 2  honoured 2'; then
    vs_ctl_dead crash-unread "the copy with no gate script did not read g_xdie127's crash as HONOURED: $(printf '%s' "$o12d" | grep -E '^  g_xdie127|executed:' | tr '\n' ' ')"; rc=1
else
    vs_ctl_fired crash-unread "with no gate script handed to the control classifier, a mode dying of command-not-found (exit 127) reads HONOURED"
fi
rm -f "$FR/tests/g_xdie127.sh" "$FR/tests/g_xquote.sh"

echo "== 12c. the results path is the run's own: the gates it runs do not inherit STATIC_RESULTS_OUT (14z-199) =="
# A gate that starts the runner itself would otherwise truncate the outer run's results file. The
# stub records what it sees; the runner's own file must hold its own header and the stub's row.
{ echo "#!/bin/sh"; echo "# g_xenv.sh — a stub that records the results path it inherited"
  echo "printf '%s' \"\${STATIC_RESULTS_OUT:-unset}\" > '$T/g_xenv.seen'"; echo "echo 'PASS: recorded'"; } > "$FR/tests/g_xenv.sh"
chmod +x "$FR/tests/g_xenv.sh"; printf 'g_xenv\n' > "$FR/tests/ci_portable.txt"
rm -f "$T/g_xenv.seen"
(cd "$FR" && STATIC_RESULTS_OUT="$T/r12e.tsv" sh tests/run_all_static.sh --tier portable --exec-controls none >/dev/null 2>&1) || true
if [ "$(cat "$T/g_xenv.seen" 2>/dev/null)" = unset ] && grep -q "^g_xenv	" "$T/r12e.tsv" 2>/dev/null; then
    echo "  ok: the gate saw no STATIC_RESULTS_OUT, and the run's own results file holds its row"
else fail "the gate inherited the results path [$(cat "$T/g_xenv.seen" 2>/dev/null || echo 'no record')] or the run's file lacks its row"; fi
rm -f "$T/g_xenv.seen"
cp "$SHADOW_R" "$FR/tests/run_all_static_ri"   # inside the repo: the runner takes its repo from its own path
(cd "$FR" && STATIC_RESULTS_OUT="$T/r12f.tsv" sh tests/run_all_static_ri --tier portable --exec-controls none >/dev/null 2>&1) || true
rm -f "$FR/tests/run_all_static_ri"
if [ "$(cat "$T/g_xenv.seen" 2>/dev/null)" = "$T/r12f.tsv" ]; then
    vs_ctl_fired results-inherited "with the unset disabled, the gate inherited the run's results path"
else
    vs_ctl_dead results-inherited "the copy without the unset still kept the path from the gate: [$(cat "$T/g_xenv.seen" 2>/dev/null || echo 'no record')]"; rc=1
fi
rm -f "$FR/tests/g_xenv.sh"

echo "== 13. MUST-FIRE: with the controls reader unplugged, section 11's dead-control stub reads PASS =="
# The shadow runner (built at the top) beside the real one in the fakerepo;
# the same stub as section 11. If this does not flip g_cmissing to PASS,
# section 11 was not proving the reader is in the loop.
ln -s "$SHADOW" "$FR/tests/run_all_static_unplugged.sh"
mkc g_cmissing 0 "# MUST-FIRE: perturbed-copy: flip — a flipped byte must fail" "PASS: fine"
printf 'g_cmissing\n' > "$FR/tests/ci_portable.txt"
o13="$(cd "$FR" && sh tests/run_all_static_unplugged.sh --tier portable --exec-controls none 2>&1)" || true
if printf '%s' "$o13" | grep -qE '^  g_cmissing +PASS'; then
    vs_ctl_fired reader-unplugged "with no gate script handed to the classifier, a declared-but-unfired control reads PASS"
else
    vs_ctl_dead reader-unplugged "the unplugged runner still failed g_cmissing: $(printf '%s' "$o13" | grep -E '^  g_cmissing')"; rc=1
fi
rm -f "$FR/tests/run_all_static_unplugged.sh"

echo "== 14. THE CADENCE (14z-162, #148): a listed gate is deferred AND NAMED, runs at its cadence, and is pulled back by a changed trigger path =="
mk g_pass 0 "PASS: fine"; mk g_fail 1 "FAIL: broken"
printf 'g_pass\ng_fail\n' > "$FR/tests/ci_portable.txt"; : > "$FR/tests/ci_static.txt"
# (a) no cadence file: the pre-#148 behaviour, byte-for-byte — g_fail runs, no cadence text
rm -f "$FR/tests/ci_cadence.tsv"
o14a="$(cd "$FR" && STATIC_CHANGED_PATHS= sh tests/run_all_static.sh --tier portable --exec-controls none 2>&1)" && s14a=0 || s14a=$?
[ "$s14a" = 1 ] && ! printf '%s' "$o14a" | grep -qi 'cadence' \
    && echo "  ok: without tests/ci_cadence.tsv every gate runs and nothing mentions a cadence" \
    || fail "14a: without a cadence file: exit $s14a, cadence text: $(printf '%s' "$o14a" | grep -ci cadence)"
# (b) g_fail listed freeze: a default (session) run defers it, NAMES it, and is GREEN
printf 'g_fail\tfreeze\tsrc/\n' > "$FR/tests/ci_cadence.tsv"
o14b="$(cd "$FR" && STATIC_CHANGED_PATHS= sh tests/run_all_static.sh --tier portable --exec-controls none 2>&1)" && s14b=0 || s14b=$?
if [ "$s14b" = 0 ] && printf '%s' "$o14b" | grep -q 'deferred (freeze cadence): g_fail' \
   && printf '%s' "$o14b" | grep -q '^deferred: 1 '; then echo "  ok: session run defers g_fail, names it, exits 0"
else fail "14b: session run: exit $s14b; $(printf '%s' "$o14b" | grep -E 'deferred|g_fail' | head -3)"; fi
printf '%s' "$o14b" | grep -qE '^  g_fail ' && fail "14b: the deferred gate still RAN"
# (c) --cadence freeze runs it -> RED
o14c="$(cd "$FR" && STATIC_CHANGED_PATHS= sh tests/run_all_static.sh --tier portable --exec-controls none --cadence freeze 2>&1)" && s14c=0 || s14c=$?
[ "$s14c" = 1 ] && printf '%s' "$o14c" | grep -qE '^  g_fail +FAIL' && echo "  ok: --cadence freeze runs g_fail and goes red" \
    || fail "14c: --cadence freeze: exit $s14c"
# (d) a changed trigger path pulls it back into a session run -> RED, and says why
o14d="$(cd "$FR" && STATIC_CHANGED_PATHS='src/gen.py' sh tests/run_all_static.sh --tier portable --exec-controls none 2>&1)" && s14d=0 || s14d=$?
if [ "$s14d" = 1 ] && printf '%s' "$o14d" | grep -q 'g_fail <- src/gen.py'; then echo "  ok: a changed src/ path triggers g_fail in a session run, and the readout names the path"
else fail "14d: triggered run: exit $s14d; $(printf '%s' "$o14d" | grep -E 'triggered|g_fail' | head -3)"; fi
# (e) an unrelated changed path does not
o14e="$(cd "$FR" && STATIC_CHANGED_PATHS='docs/x.md' sh tests/run_all_static.sh --tier portable --exec-controls none 2>&1)" && s14e=0 || s14e=$?
[ "$s14e" = 0 ] && echo "  ok: an unrelated changed path leaves g_fail deferred" || fail "14e: unrelated path triggered g_fail (exit $s14e)"
# (f) the gate's own script is always a trigger
o14f="$(cd "$FR" && STATIC_CHANGED_PATHS='tests/g_fail.sh' sh tests/run_all_static.sh --tier portable --exec-controls none 2>&1)" && s14f=0 || s14f=$?
[ "$s14f" = 1 ] && echo "  ok: editing the gate's own script triggers it" || fail "14f: own-script change did not trigger (exit $s14f)"
# (g) --list tags the listed gate
o14g="$(cd "$FR" && sh tests/run_all_static.sh --list 2>&1)"
printf '%s' "$o14g" | grep -q 'g_fail  \[freeze\]' && echo "  ok: --list tags g_fail [freeze]" || fail "14g: --list lacks the tag"
# (i) ONDEMAND (14z-196, maintainer-ruled 2026-10-09): deferred and named at EVERY cadence below
#     ondemand, never pulled back by a changed path — its own script included — and run by --cadence ondemand
printf 'g_fail\tondemand\t-\n' > "$FR/tests/ci_cadence.tsv"
o14i1="$(cd "$FR" && STATIC_CHANGED_PATHS= sh tests/run_all_static.sh --tier portable --exec-controls none 2>&1)" && s14i1=0 || s14i1=$?
if [ "$s14i1" = 0 ] && printf '%s' "$o14i1" | grep -q 'deferred (ondemand cadence): g_fail' \
   && printf '%s' "$o14i1" | grep -q 'an ondemand gate runs only when asked for'; then echo "  ok: a session run defers the ondemand g_fail, names it and says how to run it"
else fail "14i: session run with g_fail ondemand: exit $s14i1"; fi
o14i2="$(cd "$FR" && STATIC_CHANGED_PATHS= sh tests/run_all_static.sh --tier portable --exec-controls none --cadence release 2>&1)" && s14i2=0 || s14i2=$?
[ "$s14i2" = 0 ] && printf '%s' "$o14i2" | grep -q 'deferred (ondemand cadence): g_fail' && echo "  ok: --cadence release still defers it" \
    || fail "14i: --cadence release ran the ondemand gate (exit $s14i2)"
o14i3="$(cd "$FR" && STATIC_CHANGED_PATHS='tests/g_fail.sh' sh tests/run_all_static.sh --tier portable --exec-controls none 2>&1)" && s14i3=0 || s14i3=$?
[ "$s14i3" = 0 ] && ! printf '%s' "$o14i3" | grep -q 'g_fail <- ' && echo "  ok: a change to its own script does not pull it in" \
    || fail "14i: a changed own script pulled the ondemand gate in (exit $s14i3)"
o14i4="$(cd "$FR" && STATIC_CHANGED_PATHS= sh tests/run_all_static.sh --tier portable --exec-controls none --cadence ondemand 2>&1)" && s14i4=0 || s14i4=$?
[ "$s14i4" = 1 ] && printf '%s' "$o14i4" | grep -qE '^  g_fail +FAIL' && echo "  ok: --cadence ondemand runs it and goes red" \
    || fail "14i: --cadence ondemand: exit $s14i4"
printf 'g_fail\tfreeze\tsrc/\n' > "$FR/tests/ci_cadence.tsv"   # back to section 14's freeze listing: section 15 runs on it
# (h) the real cadence file: every listed gate is registered, cadence is freeze|release|ondemand, triggers non-empty
o14h="$(awk -F'\t' '!/^#/ && NF {print $1, $2, ($3 == "" ? "EMPTY" : "ok")}' "$REPO/tests/ci_cadence.tsv")"
while read -r g c t; do
    [ -n "$g" ] || continue
    grep -qx "$g" "$REPO/tests/ci_portable.txt" "$REPO/tests/ci_static.txt" || fail "14h: $g is in ci_cadence.tsv but in no registry"
    case "$c" in freeze|release|ondemand) ;; *) fail "14h: $g has cadence '$c'" ;; esac
    [ "$t" = ok ] || fail "14h: $g has no triggers"
done <<EOF14
$o14h
EOF14
echo "  ok: the real tests/ci_cadence.tsv lists $(printf '%s\n' "$o14h" | awk 'NF' | wc -l | tr -d ' ') registered gates, each freeze|release|ondemand with triggers"

echo "== 15. MUST-FIRE: with the trigger match blinded, section 14(d)'s changed path leaves g_fail deferred =="
ln -s "$SHADOW_T" "$FR/tests/run_all_static_triggerblind.sh"
o15="$(cd "$FR" && STATIC_CHANGED_PATHS='src/gen.py' sh tests/run_all_static_triggerblind.sh --tier portable --exec-controls none 2>&1)" && s15=0 || s15=$?
if [ "$s15" = 0 ] && ! printf '%s' "$o15" | grep -q 'g_fail <- '; then
    vs_ctl_fired trigger-blind "with the trigger match disabled, a changed src/ path no longer pulls the freeze-cadence g_fail into a session run (exit 0, nothing triggered)"
else
    vs_ctl_dead trigger-blind "the blinded runner still triggered g_fail (exit $s15)"; rc=1
fi
rm -f "$FR/tests/run_all_static_triggerblind.sh" "$FR/tests/ci_cadence.tsv"

echo "== 16. MUST-FIRE: with ONDEMAND-NO-TRIGGER disabled, section 14i's own-script change pulls the ondemand g_fail in =="
printf 'g_fail\tondemand\t-\n' > "$FR/tests/ci_cadence.tsv"
ln -s "$SHADOW_D" "$FR/tests/run_all_static_ondemandtriggered.sh"
o16="$(cd "$FR" && STATIC_CHANGED_PATHS='tests/g_fail.sh' sh tests/run_all_static_ondemandtriggered.sh --tier portable --exec-controls none 2>&1)" && s16=0 || s16=$?
if [ "$s16" = 1 ] && printf '%s' "$o16" | grep -q 'g_fail <- tests/g_fail.sh'; then
    vs_ctl_fired ondemand-triggered "with ONDEMAND-NO-TRIGGER disabled, a change to tests/g_fail.sh pulls the ondemand g_fail into a session run (exit 1)"
else
    vs_ctl_dead ondemand-triggered "the copy still deferred the ondemand g_fail (exit $s16)"; rc=1
fi
rm -f "$FR/tests/run_all_static_ondemandtriggered.sh" "$FR/tests/ci_cadence.tsv"

echo "== 16. ORDER: last (14z-185b, #188): a marked gate runs after every other gate of its tier, registry order kept otherwise =="
mk g_pass 0 "PASS: fine"; mk g_two 0 "PASS: two"
{ echo "#!/bin/sh"; echo "# ORDER: last"; echo "echo 'PASS: ran last'"; echo "exit 0"; } > "$FR/tests/g_last.sh"; chmod +x "$FR/tests/g_last.sh"
printf 'g_last\ng_pass\ng_two\n' > "$FR/tests/ci_portable.txt"; : > "$FR/tests/ci_static.txt"; rm -f "$FR/tests/ci_cadence.tsv"
o16="$(cd "$FR" && STATIC_CHANGED_PATHS= sh tests/run_all_static.sh --tier portable --exec-controls none 2>&1)" && s16=0 || s16=$?
ord16="$(printf '%s\n' "$o16" | awk '/^  g_(last|pass|two) /{printf "%s ", $1}')"
if [ "$s16" = 0 ] && [ "$ord16" = "g_pass g_two g_last " ]; then
    echo "  ok: registered first, g_last ran last; the others kept their order ($ord16)"
else fail "16: order was '$ord16' (exit $s16), expected 'g_pass g_two g_last '"; fi

echo "== 17. MUST-FIRE: with ORDER: last disabled, section 16's marked stub runs in its registry place =="
ln -s "$SHADOW_O" "$FR/tests/run_all_static_orderignored.sh"
o17="$(cd "$FR" && STATIC_CHANGED_PATHS= sh tests/run_all_static_orderignored.sh --tier portable --exec-controls none 2>&1)" || true
ord17="$(printf '%s\n' "$o17" | awk '/^  g_(last|pass|two) /{printf "%s ", $1}')"
if [ "$ord17" = "g_last g_pass g_two " ]; then
    vs_ctl_fired order-ignored "with ORDER: last disabled, the marked stub ran first, in its registry place ($ord17)"
else
    vs_ctl_dead order-ignored "the disabled copy ran '$ord17'"; rc=1
fi
rm -f "$FR/tests/run_all_static_orderignored.sh" "$FR/tests/g_last.sh" "$FR/tests/g_two.sh"

echo
echo "== 18. --confirm (14z-188, #188 route A): a red is re-run, a changed input re-runs its reader, the rest is CARRIED =="
FC="$T/confirmrepo"; mkdir -p "$FC/tests/lib" "$FC/tools" "$FC/data"
ln -s "$RUNNER" "$FC/tests/run_all_static.sh"
for _l in classify controls measures; do ln -s "$REPO/tests/lib/$_l.sh" "$FC/tests/lib/$_l.sh"; done
cp "$REPO/tools/static_confirm.py" "$REPO/tools/battery_reach.py" "$FC/tools/"
cp "$FC/tools/static_confirm.py" "$T/static_confirm_off.py"
python3 - "$T/static_confirm_off.py" <<'PYX'
import sys; p = sys.argv[1]; s = open(p).read()
a = "    _, stale, _ = predict(root, sorted(changed), r1) if changed else (gates, {}, gates)"
assert s.count(a) == 1, "the plan's predict line moved"
open(p, "w").write(s.replace(a, "    stale = {}  # CONTROL prediction-off"))
PYX
vs_ctl_is prediction-off && cp "$T/static_confirm_off.py" "$FC/tools/static_confirm.py"
printf '#!/bin/sh\ncat data/a.txt > /dev/null\necho "PASS: a"\n' > "$FC/tests/g_a.sh"
printf '#!/bin/sh\necho "PASS: b"\n' > "$FC/tests/g_b.sh"
printf '#!/bin/sh\nif grep -q good data/c.txt; then echo "PASS: c"; else echo "FAIL: c"; exit 1; fi\n' > "$FC/tests/g_c.sh"
{ echo "#!/bin/sh"; echo "# g_d.sh — a stub with a declared control (the row-writer must record the GATE's verdict, not its control's)"
  echo "# MUST-FIRE: perturbed-copy: flip — a flipped byte must fail"
  echo 'if [ "${CONTROL:-}" = flip ]; then echo "FAIL: the flipped input was caught"; exit 1; fi'
  echo "echo 'PASS: d'"; echo "echo 'CONTROL FIRED: flip — caught'"; echo "exit 0"; } > "$FC/tests/g_d.sh"
{ echo "#!/bin/sh"; echo "# g_e.sh — a CORE stub (#269): its inputs move outside the tracked tree"; echo "# CONFIRM: always"
  echo "echo 'PASS: e'"; } > "$FC/tests/g_e.sh"
chmod +x "$FC/tests/"g_*.sh
printf 'g_a\ng_b\ng_c\ng_d\ng_e\n' > "$FC/tests/ci_portable.txt"; : > "$FC/tests/ci_static.txt"
echo one > "$FC/data/a.txt"; echo bad > "$FC/data/c.txt"
(cd "$FC" && git init -q && git add -A && git -c user.name=t -c user.email=t@t commit -qm base)
r1="$(cd "$FC" && STATIC_RESULTS_OUT="$T/r1.tsv" sh tests/run_all_static.sh --tier portable 2>&1)" || true
grep -q "^g_d	PASS	[0-9]*	1	1	1$" "$T/r1.tsv" && echo "  ok: a gate whose control ran as a mode is recorded by ITS verdict: g_d PASS, declared 1, fired 1, honoured 1" \
    || fail "g_d's row (its control's FAIL must not overwrite its PASS): $(grep '^g_d' "$T/r1.tsv" 2>/dev/null)"
grep -q "^g_c	FAIL" "$T/r1.tsv" && grep -q "^g_a	PASS" "$T/r1.tsv" && echo "  ok: the first run records g_c FAIL and g_a PASS in its results.tsv" \
    || fail "the first run's results.tsv: $(grep -v '^#' "$T/r1.tsv" 2>/dev/null | tr '\n' ' ')"
echo good > "$FC/data/c.txt"; sleep 1
r2="$(cd "$FC" && STATIC_RESULTS_OUT="$T/r2.tsv" sh tests/run_all_static.sh --tier portable --confirm "$T/r1.tsv" 2>&1)" && s2c=0 || s2c=$?
if [ "$s2c" = 0 ] && printf '%s' "$r2" | grep -qE "^  g_a +PASS  carried" && printf '%s' "$r2" | grep -qE "^  g_b +PASS  carried" \
        && printf '%s' "$r2" | grep -qE "^  g_c +PASS +[0-9]+s" && printf '%s' "$r2" | grep -qE "^  g_d +PASS  carried" \
        && printf '%s' "$r2" | grep -q "carried: 3 of the PASS" && printf '%s' "$r2" | grep -qE "^  re-run g_e +the core"; then
    echo "  ok: confirming the red re-runs g_c (now PASS) and the core g_e, and carries g_a, g_b and g_d — GREEN, 'carried: 3'"
else fail "the confirm run (exit $s2c): $(printf '%s' "$r2" | grep -E '^  g_|^carried|^  re-run' | tr '\n' '|')"; fi
echo two > "$FC/data/a.txt"; sleep 1
r3="$(cd "$FC" && STATIC_RESULTS_OUT="$T/r3.tsv" sh tests/run_all_static.sh --tier portable --confirm "$T/r2.tsv" 2>&1)" && s3c=0 || s3c=$?
if printf '%s' "$r3" | grep -qE "^  re-run g_a +STALE" && printf '%s' "$r3" | grep -qE "^  g_a +PASS +[0-9]+s" \
        && printf '%s' "$r3" | grep -qE "^  g_b +PASS  carried"; then
    echo "  ok: a change to data/a.txt re-runs its reader g_a (STALE), g_b stays carried"
    S18=ok
else fail "after data/a.txt changed (exit $s3c): $(printf '%s' "$r3" | grep -E '^  g_|^  re-run' | tr '\n' '|')"; S18=bad; fi
r4="$(cd "$FC" && sh tests/run_all_static.sh --tier portable --confirm "$T/nope.tsv" 2>&1)" && s4c=0 || s4c=$?
[ "$s4c" = 2 ] && echo "  ok: a missing results file refuses (exit 2) — nothing carried from nothing" || fail "--confirm on a missing file exited $s4c"

echo "== 19. MUST-FIRE: with the plan's prediction off, section 18's changed input is CARRIED =="
if ! vs_ctl_is prediction-off; then
    cp "$T/static_confirm_off.py" "$FC/tools/static_confirm.py"
    echo three > "$FC/data/a.txt"; sleep 1
    r5="$(cd "$FC" && sh tests/run_all_static.sh --tier portable --confirm "$T/r3.tsv" 2>&1)" || true
    if printf '%s' "$r5" | grep -qE "^  g_a +PASS  carried"; then
        vs_ctl_fired prediction-off "with nothing marked STALE, g_a is carried although data/a.txt changed — section 18's check is what catches it"
    else vs_ctl_dead prediction-off "the prediction-off copy still re-ran g_a: $(printf '%s' "$r5" | grep -E '^  g_a')"; rc=1; fi
fi

echo "== 20. the session run (#269, 14z-200): the core and a base's unexecuted controls re-run; a freeze refuses --confirm =="
CORE_OFF="$T/static_confirm_coreoff.py"; CTL_OFF="$T/static_confirm_ctloff.py"; FREEZE_SHADOW="$T/run_all_static_confirmfreeze.sh"
python3 - "$REPO/tools/static_confirm.py" "$CORE_OFF" "$CTL_OFF" "$RUNNER" "$FREEZE_SHADOW" <<'PYX'
import sys
src, core_off, ctl_off, runner, shadow = sys.argv[1:]
s = open(src).read()
for tag, out in (("# CORE-ALWAYS", core_off), ("# CONTROLS-UNEXECUTED", ctl_off)):
    lines = s.split("\n"); hit = [i for i, l in enumerate(lines) if l.rstrip().endswith(tag)]
    assert len(hit) == 1, tag + " moved"
    lines[hit[0]] = lines[hit[0]].replace("elif ", "elif False and ", 1)
    open(out, "w").write("\n".join(lines))
r = open(runner).read(); a = 'if [ -n "$CONFIRM" ] && [ "$CADENCE" != session ]; then   # CONFIRM-SESSION-ONLY'
assert r.count(a) == 1, "the CONFIRM-SESSION-ONLY line moved"
open(shadow, "w").write(r.replace(a, 'if false; then   # CONTROL confirm-at-freeze'))
PYX
chmod +x "$FREEZE_SHADOW"
# one directory below the confirm repo, as the runner finds its root from its own path ($FC/shadow/.. = $FC)
mkdir -p "$FC/shadow"; ln -s "$FREEZE_SHADOW" "$FC/shadow/run_all_static.sh"
s20() {   # s20 <static_confirm.py to plan with> <runner> -> sets S20a S20b S20c (ok|bad), prints what it saw
    cp "$1" "$FC/tools/static_confirm.py"
    _r="$(cd "$FC" && sh tests/run_all_static.sh --tier portable --confirm "$T/r3.tsv" 2>&1)" || true
    if printf '%s' "$_r" | grep -qE "^  re-run g_e +the core" && printf '%s' "$_r" | grep -qE "^  g_e +PASS +[0-9]+s"; then S20a=ok
    else S20a=bad; echo "    g_e (unchanged core) was not re-run: $(printf '%s' "$_r" | grep -E '^  g_e|^  re-run g_e' | tr '\n' '|')"; fi
    (cd "$FC" && STATIC_RESULTS_OUT="$T/r6.tsv" sh tests/run_all_static.sh --tier portable --exec-controls none > /dev/null 2>&1) || true
    _r="$(cd "$FC" && sh tests/run_all_static.sh --tier portable --confirm "$T/r6.tsv" 2>&1)" || true
    if grep -q "^g_d	PASS	[0-9]*	1	1	0$" "$T/r6.tsv" && printf '%s' "$_r" | grep -qE "^  re-run g_d +0 of its 1 declared controls"; then S20b=ok
    else S20b=bad; echo "    g_d (controls not executed in the base) was not re-run: $(grep '^g_d' "$T/r6.tsv" 2>/dev/null) / $(printf '%s' "$_r" | grep -E '^  g_d|^  re-run g_d' | tr '\n' '|')"; fi
    _st=0; (cd "$FC" && sh "$2" --tier portable --cadence freeze --confirm "$T/r3.tsv" > "$T/r7.out" 2>&1) || _st=$?
    if [ "$_st" = 2 ] && grep -q "nothing is carried (#269)" "$T/r7.out"; then S20c=ok
    else S20c=bad; echo "    --confirm at --cadence freeze exited $_st: $(grep -E 'carried|confirm' "$T/r7.out" | head -2 | tr '\n' '|')"; fi
    cp "$REPO/tools/static_confirm.py" "$FC/tools/static_confirm.py"
}
SC20="$REPO/tools/static_confirm.py"; RN20="tests/run_all_static.sh"
vs_ctl_is core-carried && SC20="$CORE_OFF"; vs_ctl_is controls-carried && SC20="$CTL_OFF"
vs_ctl_is confirm-at-freeze && RN20="shadow/run_all_static.sh"
s20 "$SC20" "$RN20"
[ "$S20a" = ok ] && echo "  ok: the core stub g_e, unchanged, re-runs (# CONFIRM: always)" || fail "section 20: the core was carried"
[ "$S20b" = ok ] && echo "  ok: g_d, PASS in a base run made with --exec-controls none, re-runs ('0 of its 1 declared controls')" || fail "section 20: a base with unexecuted controls was carried"
[ "$S20c" = ok ] && echo "  ok: --confirm at --cadence freeze refuses (exit 2) — a freeze runs everything" || fail "section 20: --confirm at a freeze was not refused"

echo "== 21. MUST-FIRE: section 20's three properties, each broken by its shadow =="
if ! vs_ctl_is core-carried && ! vs_ctl_is controls-carried && ! vs_ctl_is confirm-at-freeze; then
    s20 "$CORE_OFF" tests/run_all_static.sh > /dev/null
    [ "$S20a" = bad ] && vs_ctl_fired core-carried "a plan ignoring # CONFIRM: always carries the unchanged core g_e — section 20 catches it" \
        || { vs_ctl_dead core-carried "the core-off plan still re-ran g_e"; rc=1; }
    s20 "$CTL_OFF" tests/run_all_static.sh > /dev/null
    [ "$S20b" = bad ] && vs_ctl_fired controls-carried "a plan ignoring a base's unexecuted controls carries g_d — section 20 catches it" \
        || { vs_ctl_dead controls-carried "the controls-off plan still re-ran g_d"; rc=1; }
    s20 "$REPO/tools/static_confirm.py" shadow/run_all_static.sh > /dev/null
    [ "$S20c" = bad ] && vs_ctl_fired confirm-at-freeze "a runner without the refusal accepts --confirm at a freeze — section 20 catches it" \
        || { vs_ctl_dead confirm-at-freeze "the shadow runner still refused --confirm at a freeze"; rc=1; }
fi

echo "== 22. #286 (14z-202): an unchanged dirty submodule is not a change; a mention re-runs a gate without its controls =="
FS="$T/repo286"; mkdir -p "$FS/tests/lib" "$FS/tools" "$FS/data"
ln -s "$RUNNER" "$FS/tests/run_all_static.sh"
for _l in classify controls measures; do ln -s "$REPO/tests/lib/$_l.sh" "$FS/tests/lib/$_l.sh"; done
SUBOFF="$T/static_confirm_suboff.py"; CTLALW="$T/static_confirm_ctlalways.py"; CTLNEV="$T/static_confirm_ctlnever.py"
python3 - "$REPO/tools/static_confirm.py" "$SUBOFF" "$CTLALW" "$CTLNEV" <<'PYX'
import sys
src, suboff, ctlalw, ctlnev = sys.argv[1:]
s = open(src).read()
for a, b, out in (
        ("    for p in [p for p in fps if p in changed]:   # SUBMODULE-UNCHANGED (#286 (b))",
         "    for p in []:   # CONTROL subfp-off", suboff),
        ("        if r1.get(r[0]) or len(r) < 6:   # CONTROLS-ON-REACH", "        if True:   # CONTROL controls-always", ctlalw),
        ("        if r1.get(r[0]) or len(r) < 6:   # CONTROLS-ON-REACH", "        if len(r) < 6:   # CONTROL controls-never", ctlnev)):
    assert s.count(a) == 1, out + ": its line moved"
    open(out, "w").write(s.replace(a, b, 1))
PYX
mkdir -p "$T/subsrc"; echo one > "$T/subsrc/x.txt"
(cd "$T/subsrc" && git init -q && git add -A && git -c user.name=t -c user.email=t@t commit -qm sub)
printf '#!/bin/sh\ncat sub/x.txt > /dev/null\necho "PASS: s"\n' > "$FS/tests/g_s.sh"
{ echo "#!/bin/sh"; echo "# g_f.sh — a stub with a declared control, reading a data file that MENTIONS data/notes.md"
  echo "# MUST-FIRE: perturbed-copy: flip — a flipped byte must fail"
  echo 'if [ "${CONTROL:-}" = flip ]; then echo "FAIL: the flipped input was caught"; exit 1; fi'
  echo "cat data/list.tsv > /dev/null"; echo "echo 'PASS: f'"; echo "echo 'CONTROL FIRED: flip — caught'"; echo "exit 0"; } > "$FS/tests/g_f.sh"
{ echo "#!/bin/sh"; echo "# g_o.sh — an ondemand stub: never run by a session tier, so absent from every base run"; echo "echo 'PASS: o'"; echo "exit 0"; } > "$FS/tests/g_o.sh"
chmod +x "$FS/tests/"g_*.sh
printf 'g_s\ng_f\ng_o\n' > "$FS/tests/ci_portable.txt"; : > "$FS/tests/ci_static.txt"
printf 'g_o\tondemand\t-\n' > "$FS/tests/ci_cadence.tsv"
printf 'name\tnote\nf\tdata/notes.md\n' > "$FS/data/list.tsv"; echo first > "$FS/data/notes.md"
(cd "$FS" && git init -q && git -c protocol.file.allow=always submodule add -q "$T/subsrc" sub > /dev/null 2>&1 \
    && git add -A && git -c user.name=t -c user.email=t@t commit -qm base)
echo dirty > "$FS/sub/x.txt"   # the submodule is dirty in every run, as emu/fbneo is
s22() {   # s22 <static_confirm.py> -> sets S22a S22b S22c S22d (ok|bad)
    cp "$1" "$FS/tools/static_confirm.py"; cp "$REPO/tools/battery_reach.py" "$FS/tools/"
    (cd "$FS" && STATIC_RESULTS_OUT="$T/s1.tsv" sh tests/run_all_static.sh --tier portable > /dev/null 2>&1) || true
    sleep 1
    _r="$(cd "$FS" && STATIC_RESULTS_OUT="$T/s2.tsv" sh tests/run_all_static.sh --tier portable --confirm "$T/s1.tsv" 2>&1)" || true
    if grep -q '^# subfp sub ' "$T/s1.tsv" && printf '%s' "$_r" | grep -qE "^  g_s +PASS  carried"; then S22a=ok
    else S22a=bad; echo "    the unchanged dirty submodule re-ran g_s: $(grep -c '^# subfp' "$T/s1.tsv") subfp line(s); $(printf '%s' "$_r" | grep -E '^  g_s|^  re-run g_s' | tr '\n' '|')"; fi
    echo dirtier > "$FS/sub/x.txt"; sleep 1
    _r="$(cd "$FS" && STATIC_RESULTS_OUT="$T/s3.tsv" sh tests/run_all_static.sh --tier portable --confirm "$T/s2.tsv" 2>&1)" || true
    if printf '%s' "$_r" | grep -qE "^  g_s +PASS +[0-9]+s"; then S22b=ok
    else S22b=bad; echo "    the changed submodule did not re-run g_s: $(printf '%s' "$_r" | grep -E '^  g_s' | tr '\n' '|')"; fi
    echo second > "$FS/data/notes.md"; sleep 1
    _r="$(cd "$FS" && STATIC_RESULTS_OUT="$T/s4.tsv" sh tests/run_all_static.sh --tier portable --confirm "$T/s3.tsv" 2>&1)" || true
    if printf '%s' "$_r" | grep -qE "^  re-run g_f +STALE: R5" && printf '%s' "$_r" | grep -qE "^  g_f +PASS +[0-9]+s" \
            && printf '%s' "$_r" | grep -q "controls carried: 1 honoured" && grep -q "^g_f	PASS	[0-9]*	1	1	1$" "$T/s4.tsv" \
            && printf '%s' "$_r" | grep -q '^  executed: 0  honoured 0 ' && printf '%s' "$_r" | grep -q '^  carried:  1  ' \
            && printf '%s' "$_r" | grep -qE '^  defer  g_o +absent' && ! printf '%s' "$_r" | grep -qE '^  re-run g_o'; then S22c=ok
    else S22c=bad; echo "    a mention (R5) did not re-run g_f with its control carried (or the readout counted it executed, #286): $(printf '%s' "$_r" | grep -E 'g_f|g_o|controls carried|executed:|carried:' | tr '\n' '|') / $(grep '^g_f' "$T/s4.tsv")"; fi
    printf 'name\tnote\nf\tdata/notes.md\ng\tdata/other.md\n' > "$FS/data/list.tsv"; sleep 1
    _r="$(cd "$FS" && STATIC_RESULTS_OUT="$T/s5.tsv" sh tests/run_all_static.sh --tier portable --confirm "$T/s4.tsv" 2>&1)" || true
    if printf '%s' "$_r" | grep -qE "^  re-run g_f +STALE: R2" && ! printf '%s' "$_r" | grep -q "controls carried" \
            && grep -q "^g_f	PASS	[0-9]*	1	1	1$" "$T/s5.tsv"; then S22d=ok
    else S22d=bad; echo "    a change in g_f's reach did not execute its control: $(printf '%s' "$_r" | grep -E 'g_f|controls carried' | tr '\n' '|')"; fi
    (cd "$FS" && git checkout -q -- data && echo dirty > sub/x.txt)
}
SC22="$REPO/tools/static_confirm.py"
vs_ctl_is subfp-off && SC22="$SUBOFF"; vs_ctl_is controls-always && SC22="$CTLALW"; vs_ctl_is controls-never && SC22="$CTLNEV"
s22 "$SC22"
[ "$S22a" = ok ] && echo "  ok: the dirty submodule, unchanged since the base run (its # subfp equal), leaves g_s carried" || fail "section 22: an unchanged dirty submodule re-ran its reader"
[ "$S22b" = ok ] && echo "  ok: the submodule changed again: g_s re-runs" || fail "section 22: a changed submodule was carried"
[ "$S22c" = ok ] && echo "  ok: data/notes.md, only MENTIONED by g_f's data file, re-runs g_f (R5) with its control carried (honoured 1 recorded; the readout says executed 0, carried 1; the ondemand g_o, absent from the base, is listed as deferred, not re-run)" || fail "section 22: a mention executed the control, or the readout counted a carried control as executed"
[ "$S22d" = ok ] && echo "  ok: data/list.tsv, which g_f's code reads directly, re-runs g_f (R2, a direct read) and executes its control" || fail "section 22: a direct read carried the control"

echo "== 23. MUST-FIRE: section 22's properties, each broken by its shadow =="
if ! vs_ctl_is subfp-off && ! vs_ctl_is controls-always && ! vs_ctl_is controls-never; then
    s22 "$SUBOFF" > /dev/null
    [ "$S22a" = bad ] && vs_ctl_fired subfp-off "a plan that keeps every dirty submodule re-runs g_s although sub/ did not change — section 22 catches it" \
        || { vs_ctl_dead subfp-off "the subfp-off plan still carried g_s"; rc=1; }
    s22 "$CTLALW" > /dev/null
    [ "$S22c" = bad ] && vs_ctl_fired controls-always "a plan that never carries controls executes g_f's control for a mention — section 22 catches it" \
        || { vs_ctl_dead controls-always "the controls-always plan still carried g_f's control"; rc=1; }
    s22 "$CTLNEV" > /dev/null
    [ "$S22d" = bad ] && vs_ctl_fired controls-never "a plan blind to direct reads carries g_f's control when the data its code reads changed — section 22 catches it" \
        || { vs_ctl_dead controls-never "the controls-never plan still executed g_f's control"; rc=1; }
fi

[ "$rc" = 0 ] && echo "PASS: the runner's verdicts mean what they say." \
             || echo "FAIL: see above."
exit $rc