#!/bin/sh
# test_static_runner.sh — ground truth for tests/run_all_static.sh
# (14z-94, GitHub #30). ROM-free, ~3 s.
#
# MUST-FIRE: shadow-tool: reader-unplugged — a copy of run_all_static.sh that hands the classifier no gate script must let a stub with a declared-but-unfired control read PASS (mode: that copy is the runner every section drives, and section 11 must fail)
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
if vs_ctl_is reader-unplugged; then ln -s "$SHADOW" "$FR/tests/run_all_static.sh"; else ln -s "$RUNNER" "$FR/tests/run_all_static.sh"; fi
# the runner sources THE ONE classifier relative to its repo (14z-139), so
# the synthetic repo carries it too — the shipped lib, never a copy
mkdir -p "$FR/tests/lib"; ln -s "$REPO/tests/lib/classify.sh" "$FR/tests/lib/classify.sh"
# ...and the controls reader the classifier sources beside it (14z-147)
ln -s "$REPO/tests/lib/controls.sh" "$FR/tests/lib/controls.sh"

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
o12="$(cd "$FR" && sh tests/run_all_static.sh --tier portable 2>&1)" && s12=0 || s12=$?
for pair in "g_xlies:LIES" "g_xref:REFUSED" "g_xdied:DIED"; do
    g="${pair%%:*}"; v="${pair##*:}"
    printf '%s' "$o12" | grep -qE "^  $g +CONTROL $v: flip" && echo "  ok: $g -> CONTROL $v" \
        || { fail "$g was not reported CONTROL $v:"; printf '%s' "$o12" | grep -E "^  $g" | sed 's/^/        /'; }
done
printf '%s' "$o12" | grep -qE "^  g_xhon +CONTROL" && fail "the honoured control printed a red row" || echo "  ok: g_xhon (honoured) prints no red row"
printf '%s' "$o12" | grep -q 'executed: 4  honoured 1  lies 1  refused 1  died 1' \
    && echo "  ok: readout — executed 4, honoured 1, lies 1, refused 1, died 1" \
    || fail "executable readout wrong: $(printf '%s' "$o12" | grep 'executed:' || echo '(none)')"
printf '%s' "$o12" | grep -q 'PASS 4 .*SKIP 0 .*FAIL 3' \
    && echo "  ok: tally PASS 4  FAIL 3 — every gate passed its own run, three controls failed theirs" \
    || fail "wrong tally: $(printf '%s' "$o12" | grep -E '^PASS ' || echo '(none printed)')"
printf '%s' "$o12" | grep -q 'g_xlies(control:flip:LIES)' && echo "  ok: the failure list names the gate, the control and the verdict" \
    || fail "the failure list does not name the lying control: $(printf '%s' "$o12" | grep '^failed:' || echo '(none)')"
[ "$s12" != 0 ] && echo "  ok: and the runner exits nonzero ($s12)" || fail "a lying control left the runner green"
# the MUST-NOT-FIRE half: --exec-controls none runs nothing and the four stubs are all PASS
o12b="$(cd "$FR" && sh tests/run_all_static.sh --tier portable --exec-controls none 2>&1)" && s12b=0 || s12b=$?
[ "$s12b" = 0 ] && printf '%s' "$o12b" | grep -q 'PASS 4 .*FAIL 0' && printf '%s' "$o12b" | grep -q 'executed: (off' \
    && echo "  ok: control — with --exec-controls none the same four stubs are PASS 4 and the readout says off" \
    || fail "--exec-controls none still executed or failed something: $(printf '%s' "$o12b" | grep -E '^PASS |executed' || echo '(none)')"
# and the portable-only selector leaves a STATIC gate's controls unexecuted
: > "$FR/tests/ci_portable.txt"; printf 'g_xlies\n' > "$FR/tests/ci_static.txt"
o12c="$(cd "$FR" && ROMDIR="$T" sh tests/run_all_static.sh --tier static --exec-controls portable 2>&1)" && s12c=0 || s12c=$?
[ "$s12c" = 0 ] && echo "  ok: --exec-controls portable does not execute a static-tier gate's controls" \
    || fail "--exec-controls portable executed a static gate's control: $(printf '%s' "$o12c" | grep 'CONTROL' || echo '(none)')"
: > "$FR/tests/ci_static.txt"

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

echo
[ "$rc" = 0 ] && echo "PASS: the runner's verdicts mean what they say." \
             || echo "FAIL: see above."
exit $rc