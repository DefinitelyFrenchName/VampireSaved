#!/bin/sh
# run_all_static.sh — THE PRE-COMMIT GATE CHAIN. One command, every gate that
# does not need an emulator. (14z-94, GitHub #30.)
#
# MUST-FIRE: none — a RUNNER asserts no property of the artifact; its verdict logic is tested by tests/test_static_runner.sh
#
# WHY THIS EXISTS. There is no CI in this repo — no .github/, no Makefile, no
# justfile — and 101 of the then-130 test scripts had no shell caller at all.
# So running the reproducibility gate, the manifest-merge gate, or the
# region-overlap gate depended on a human remembering a filename. CLAUDE.md §4
# mandates that "one command validates any build variant", and rule 6 makes a
# failing regression halt forward work; neither can operate on a suite nobody
# invokes.
#
# WHAT IT COST, measured: `tests/test_dualtrack.sh` sat RED for 11 days
# (GitHub #95) while CLAUDE.md §4 cited it as one of FBNeo's three guarantees.
# It was found only because an unrelated fix happened to require rebuilding
# the FBNeo binary. That is the failure mode this script exists to end.
#
# SCOPE, deliberately narrow (#30's own handoff): this is NOT "fix 101
# orphans". Most orphans are expensive emulator soaks or one-off measurement
# rigs that SHOULD stay manual, and HANDOFF.md is their index. Automated here
# is the emulator-free set — the gates cheap enough to run before every
# commit. It is also NOT folded into run_battery_m2.sh, whose header defines
# it as the stage-6 DEV BUILD chain and which builds a ROM.
#
# THREE VERDICTS, AND SKIP IS NOT PASS (GitHub #29). A gate whose inputs are
# absent prints `SKIP: <reason>` and exits 0. Counting that as a pass is how a
# clean checkout reports green while asserting nothing, so SKIP is counted and
# printed separately, and `--strict` makes it fatal.
#
# Usage:
#   tests/run_all_static.sh                 portable tier only (no inputs)
#   ROMDIR=... tests/run_all_static.sh      portable + static tiers
#   ... --strict                            SKIP is a failure too
#   ... --list                              print the registry and exit
#   ... --tier portable|static              one tier only
#   ... --exec-controls all|portable|none  which tier's declared must-fire
#                                          controls are EXECUTED (default all)
#
# THE MUST-FIRE CONTROLS ARE READ AND EXECUTED (14z-147, step two of the
# maintainer's ruling, STATE 14z-145). Two things, both through
# tests/lib/controls.sh — the one reader of the `# MUST-FIRE:` grammar:
#   READ  (free, every gate): a gate whose header DECLARES a control must
#         print `CONTROL FIRED: <name>` in its run; a declared control that
#         did not fire, a `CONTROL DEAD:` line, or a firing no header declares
#         turns the verdict into plain FAIL (tests/lib/classify.sh). A gate
#         with no declaration is COUNTED as undeclared, never failed.
#   EXEC  (one extra run per declared control, `CONTROL=<name> tests/<g>.sh`):
#         the gate applies the perturbation to its REAL input and must reach
#         its OWN FAIL. Exit 0 is `LIES` (the control tests nothing), a
#         `REFUSED:` line is a dead mode, a shell error or traceback is
#         `DIED` — each a failure of the run. Why this is stronger than the
#         FIRED line: FIRED is the gate's SELF-report, and 14z-144 showed a
#         control can print it while asserting a value it just wrote.
#
# Registries: tests/ci_portable.txt (ROM-free, runs anywhere)
#             tests/ci_static.txt   (needs ROMDIR and/or build dirs; no emulator)
# A gate that is emulator-free and in NEITHER file is reported as UNREGISTERED
# — that check is the actual anti-orphan mechanism, and without it this
# script would simply become a new, smaller thing to forget to update.
set -eu
REPO="$(cd "$(dirname "$0")/.." && pwd)"

# ROMDIR must be ABSOLUTE for the gates: at least two resolve it from a
# DIFFERENT working directory than the caller's — audit_gfx_merged_census
# symlinks $ROMDIR/vsav.zip into a temp dir (a relative target dangles at
# the symlink's own directory), test_harness_frame_bound builds an overlay
# and cd's into it. Measured 14z-96: both red under ROMDIR=../ROMS, green
# under the absolute twin — 2 of the 3 "failures" that looked like a broken
# suite. Canonicalise at the entrance, BEFORE the cd below, so the
# documented pre-commit command is robust to how the caller spells it.
if [ -n "${ROMDIR:-}" ]; then
    ROMDIR="$(CDPATH= cd "$ROMDIR" && pwd)" || {
        echo "ROMDIR '$ROMDIR' does not resolve from $(pwd)" >&2; exit 2; }
    export ROMDIR
fi
cd "$REPO"
# THE ONE CLASSIFIER (14z-139). This runner carried its own copy of the
# PASS/SKIP/FAIL logic, and it DIFFERED from the sweep's: no branch for a
# gate that exits 0 after the shell's own error line ([VSP-176]), so the
# pre-commit command read such a crash as PASS while run_all_emulator.sh
# read it as FAIL. Sourced, not copied, so the two cannot drift again.
. "$REPO/tests/lib/classify.sh"

STRICT=0; TIER=all; LIST=0; EXEC_CTL=all
while [ $# -gt 0 ]; do
    case "$1" in
    --strict) STRICT=1 ;;
    --list)   LIST=1 ;;
    --tier)   shift; TIER="${1:?--tier needs portable|static|all}" ;;
    --exec-controls) shift; EXEC_CTL="${1:?--exec-controls needs all|portable|none}" ;;
    -h|--help) sed -n '2,40p' "$0"; exit 0 ;;
    *) echo "unknown argument '$1' (try --help)" >&2; exit 2 ;;
    esac
    shift
done

read_reg() {  # read_reg <file> — non-comment, non-blank lines
    [ -f "$1" ] || return 0
    sed 's/#.*//' "$1" | awk 'NF'
}

PORTABLE="$(read_reg tests/ci_portable.txt)"
STATIC="$(read_reg tests/ci_static.txt)"

if [ "$LIST" = 1 ]; then
    echo "portable ($(printf '%s\n' "$PORTABLE" | awk 'NF' | wc -l | tr -d ' ')):"
    printf '%s\n' "$PORTABLE" | awk 'NF{print "  " $0}'
    echo "static ($(printf '%s\n' "$STATIC" | awk 'NF' | wc -l | tr -d ' ')):"
    printf '%s\n' "$STATIC" | awk 'NF{print "  " $0}'
    exit 0
fi

WORK="$(mktemp -d)"; trap 'rm -rf "$WORK"' EXIT INT TERM
n_pass=0; n_skip=0; n_fail=0; n_miss=0
failed=""; skipped=""
# the controls ledger: declared / fired over the tier, the undeclared count,
# and the executable-control rows (gate, name, verdict, seconds)
c_decl=0; c_fired=0; c_undecl=0; c_none=0
x_ok=0; x_lies=0; x_refused=0; x_died=0
: > "$WORK/controls.tsv"

# WORKING-TREE SNAPSHOT (14z-94). This is the PRE-COMMIT command, so it must
# not leave the tree dirty — and it did on the first full run: several gates
# build into tracked paths (build/donovan6, build/donovan_stage4_gate) rather
# than a temp dir, so running the chain rewrote committed artifacts. A
# pre-commit check whose own side effect is a diff will get its output
# ignored, so the run reports it. Reported, not failed: the gates are correct,
# their output location is not, and that is its own fix.
tree_before=""
TREE_SUSPECT=""
if git rev-parse --git-dir >/dev/null 2>&1; then
    tree_before="$(git status --porcelain -- . 2>/dev/null | grep -v '^??' || true)"
fi

run_tier() {  # run_tier <label> <names>
    _label="$1"; _names="$2"
    [ -n "$_names" ] || return 0
    echo "== $_label tier =="
    for g in $_names; do
        if [ ! -x "tests/$g.sh" ]; then
            printf '  %-34s %s\n' "$g" "MISSING (registered but not executable)"
            n_miss=$((n_miss + 1)); failed="$failed $g(missing)"
            continue
        fi
        _t0=$(date +%s)
        # </dev/null: a gate that reads stdin otherwise swallows the rest of
        # this loop's input. Paid for once — a 32-entry run became 28 silently.
        tests/"$g".sh </dev/null > "$WORK/$g.out" 2>&1 && _st=0 || _st=$?
        _t1=$(date +%s)
        _dur=$((_t1 - _t0))
        # EXIT STATUS DECIDES FIRST (corrected 14z-128): a gate that prints
        # `SKIP:` AND exits non-zero is a FAILURE; exit 0 after the shell's own
        # error line is a FAILURE too (14z-139, the branch this runner lacked).
        # The rules and their history: tests/lib/classify.sh.
        # the 4th argument is the gate SCRIPT: the classifier reads its
        # MUST-FIRE declarations against the log (14z-147)
        vs_classify "$_st" "$WORK/$g.out" 58 "tests/$g.sh"
        case "${VS_CTL_VERDICT:-}" in
        OK|RED)     c_decl=$((c_decl + VS_CTL_DECLARED)); c_fired=$((c_fired + VS_CTL_FIRED)) ;;
        NONE)       c_none=$((c_none + 1)) ;;
        UNDECLARED) if [ "$VS_VERDICT" = PASS ]; then c_undecl=$((c_undecl + 1)); fi ;;
        esac
        case "$VS_VERDICT" in
        TIMEOUT)
            # no timeout wrapper here; kept so the verdict set is the sweep's
            printf '  %-34s TIMEOUT %3ss  (exit %s)\n' "$g" "$_dur" "$_st"
            n_fail=$((n_fail + 1)); failed="$failed $g" ;;
        FAIL)
            if [ "$_st" != 0 ]; then
                printf '  %-34s FAIL  %3ss  (exit %s)\n' "$g" "$_dur" "$_st"
            elif [ "${VS_CTL_VERDICT:-}" = RED ]; then
                # a controls red on an exit-0 run: say so, not "shell error"
                printf '  %-34s FAIL  %3ss  (%s)\n' "$g" "$_dur" "$VS_DETAIL"
            else
                printf '  %-34s FAIL  %3ss  (exit 0 after a shell error)\n' "$g" "$_dur"
            fi
            # FAIL_TAIL: how much of a failing gate's output to show (default 4;
            # the CI sets 80 — a red read remotely needs the section that failed,
            # not the last four lines of its controls; 14z-133b).
            tail -"${FAIL_TAIL:-4}" "$WORK/$g.out" | sed 's/^/        | /'
            n_fail=$((n_fail + 1)); failed="$failed $g" ;;
        SKIP)
            printf '  %-34s SKIP  %3ss  %s\n' "$g" "$_dur" "$VS_DETAIL"
            n_skip=$((n_skip + 1)); skipped="$skipped $g" ;;
        *)
            printf '  %-34s PASS  %3ss\n' "$g" "$_dur"
            n_pass=$((n_pass + 1))
            # an `if`, not `[ ] &&`: this is the loop's last command and the
            # runner is set -e — a false test here would end the tier
            if [ "${VS_CTL_DECLARED:-0}" != 0 ]; then exec_controls "$g" "$_label"; fi ;;
        esac
    done
}

# EXECUTABLE CONTROLS. For a PASSING gate with declarations, run it once per
# declared name under `CONTROL=<name>` and require its OWN FAIL. The verdicts:
#   HONOURED  exit non-zero, no shell error, no traceback — the gate failed
#   LIES      exit 0 — the perturbation left the gate green ([VSP-19]'s worst case)
#   REFUSED   the gate does not honour the mode (a declared name it never reads)
#   DIED      a shell error line or a traceback — a crash is not a verdict
#             ([VSP-108]: distinguish "rejected" from "died")
# Every row lands in the tally as a failure when it is not HONOURED.
exec_controls() {  # exec_controls <gate> <tier-label>
    case "$EXEC_CTL" in
    none) return 0 ;;
    portable) [ "$2" = portable ] || return 0 ;;
    all) ;;
    *) echo "bad --exec-controls '$EXEC_CTL'" >&2; exit 2 ;;
    esac
    for _n in $(vs_ctl_declared "tests/$1.sh"); do
        _c0=$(date +%s)
        CONTROL="$_n" tests/"$1".sh </dev/null > "$WORK/$1.ctl.$_n.out" 2>&1 && _cs=0 || _cs=$?
        _c1=$(date +%s); _cd=$((_c1 - _c0))
        vs_classify_control "$_cs" "$WORK/$1.ctl.$_n.out"; _cv="$VS_CTL_EXEC"
        printf '%s\t%s\t%s\t%s\n' "$1" "$_n" "$_cv" "$_cd" >> "$WORK/controls.tsv"
        case "$_cv" in
        HONOURED) x_ok=$((x_ok + 1)) ;;
        LIES)     x_lies=$((x_lies + 1)) ;;
        REFUSED)  x_refused=$((x_refused + 1)) ;;
        *)        x_died=$((x_died + 1)) ;;
        esac
        if [ "$_cv" != HONOURED ]; then
            n_fail=$((n_fail + 1)); failed="$failed $1(control:$_n:$_cv)"
            printf '  %-34s CONTROL %s: %s — %s (%ss)\n' "$1" "$_cv" "$_n" "$VS_CTL_EXEC_DETAIL" "$_cd"
        fi
    done
}

case "$TIER" in
portable) run_tier portable "$PORTABLE" ;;
static)   run_tier static   "$STATIC" ;;
all)
    run_tier portable "$PORTABLE"
    if [ -n "${ROMDIR:-}" ]; then
        run_tier static "$STATIC"
    else
        echo "== static tier =="
        echo "  NOT RUN: ROMDIR is unset. These gates read the reference set or"
        echo "           a build dir. Set ROMDIR to include them."
        n_skip=$((n_skip + $(printf '%s\n' "$STATIC" | awk 'NF' | wc -l | tr -d ' ')))
        skipped="$skipped <static-tier:ROMDIR-unset>"
    fi ;;
*) echo "bad --tier '$TIER'" >&2; exit 2 ;;
esac

echo
echo "== registry coverage (the anti-orphan check) =="
# Any emulator-free gate in NEITHER registry. Reported, not failed: adding a
# gate and forgetting to register it is exactly the drift this script exists
# to surface, but a new gate is also the moment when a hard failure would be
# most annoying and least informative. It prints loudly and is easy to act on.
python3 - "$WORK" <<'PY'
import glob, os, re, sys
# THE CHECK MUST BE TRANSITIVE. Two gates defeated earlier versions of this
# pattern: test_fbneo_smoke reaches FBNeo via tools/run_fbneo.sh (not the
# replay wrapper), and test_m2a_stage4_code reaches MAME by SOURCING
# tests/lib/m2a_common.sh and via tools/run_replay_guarded.sh. Both were
# reported as static, and the second one then ran for 208s inside a chain
# advertised as emulator-free. So: match every wrapper name, and follow
# sourced libs one level.
# run_sim_jtcps2.sh is the THIRD implementation's wrapper (Jotego's RTL under
# Verilator, 14z-107): a gate that calls it costs ~50 min and needs Verilator
# plus ROMDIR, so it belongs in the manual/emulator tier exactly like the MAME
# and FBNeo wrappers.
# run_inp_probe.sh / run_inp_guarded.sh are the RECORDING-PLAYBACK wrappers
# ([VSP-20], 14z-111) and they drive MAME too. They were MISSING here until
# 14z-127, so `test_pod_black_foot_palette` (which reaches MAME only through
# run_inp_probe.sh) was reported as an unregistered emulator-free gate every
# run -- inviting exactly the mis-registration this comment's own two
# precedents describe: it takes minutes and needs ROMDIR plus a build dir.
EMU = re.compile(r'run_(replay_)?(mame|fbneo)\.sh|run_replay_guarded\.sh'
                 r'|MAME_BIN|FBNEO_BIN|autoboot_script|emu/fbneo/fbneo'
                 r'|run_battery|run_sim_jtcps2\.sh'
                 r'|run_inp_probe\.sh|run_inp_guarded\.sh')
SRC = re.compile(r'^\s*\.\s+"?\$(?:REPO|\{REPO\})"?/(tests/lib/[a-z0-9_]+\.sh)',
                 re.M)

def uncomment(path):
    try:
        return "\n".join(l for l in open(path, errors="replace").read().splitlines()
                          if not l.lstrip().startswith("#"))
    except OSError:
        return ""

def needs_emulator(path, _depth=0):
    body = uncomment(path)
    if EMU.search(body):
        return True
    if _depth < 2:
        for lib in SRC.findall(body):
            if needs_emulator(lib, _depth + 1):
                return True
    return False
def reg(p):
    if not os.path.exists(p): return set()
    return {l.split('#')[0].strip() for l in open(p)} - {''}
known = reg("tests/ci_portable.txt") | reg("tests/ci_static.txt")
unreg = []
for p in sorted(glob.glob("tests/*.sh")):
    name = os.path.basename(p)[:-3]
    if name in known or name.startswith("run_") or name.endswith("_soak"):
        continue
    if not needs_emulator(p):
        unreg.append(name)
open(os.path.join(sys.argv[1], "unreg"), "w").write("\n".join(unreg))
if unreg:
    print(f"  {len(unreg)} emulator-free gate(s) in NEITHER registry:")
    for n in unreg: print(f"      {n}")
    print("  Add each to tests/ci_static.txt (or ci_portable.txt if it needs no")
    print("  ROMDIR and no build dir), or note why it must stay manual.")
else:
    print("  ok: every emulator-free gate is registered")
PY

echo
echo "== working tree (a pre-commit command must not dirty it) =="
if [ -z "$tree_before" ] && ! git rev-parse --git-dir >/dev/null 2>&1; then
    echo "  note: not a git checkout — not checked"
else
    tree_after="$(git status --porcelain -- . 2>/dev/null | grep -v '^??' || true)"
    if [ "$tree_before" = "$tree_after" ]; then
        echo "  ok: no tracked file changed during the run"
    else
        # Diff via files. `grep -vxF "$tree_before"` was wrong: it treats the
        # whole multi-line string as a pattern LIST, and a blank line in it
        # matches everything — so a real change printed an EMPTY list, which
        # reads as a mystery rather than a finding.
        printf '%s\n' "$tree_before" | awk 'NF' > "$WORK/tree_before.txt"
        printf '%s\n' "$tree_after"  | awk 'NF' > "$WORK/tree_after.txt"
        # THE MESSAGE USED TO ASSERT A CAUSE, and it was the wrong one
        # (14z-144). "these gates write into TRACKED paths" assumes a GATE
        # dirtied the tree. The other cause is a human EDITING the tree while
        # the run reads it — which happened on 2026-09-09, produced two FAILs
        # that were void rather than real, and cost a wasted run plus a
        # misdiagnosis BECAUSE this block named the file and the reader still
        # concluded the wrong thing. State the fact; offer both causes; and
        # ATTRIBUTE it to the verdicts it may have invalidated.
        echo "  TRACKED FILES CHANGED DURING THE RUN. Two causes, and this"
        echo "  check cannot tell them apart — decide which before trusting"
        echo "  any verdict below:"
        echo "    (a) a GATE wrote into a tracked path instead of a temp dir"
        echo "        -> restore with 'git checkout --' on it and fix the gate"
        echo "    (b) the TREE WAS EDITED while the run was reading it"
        echo "        -> every verdict here is suspect; re-run before acting"
        diff "$WORK/tree_before.txt" "$WORK/tree_after.txt" \
            | grep '^[<>]' | sed 's/^/      /' | head -12
        echo "      (before: $(wc -l < "$WORK/tree_before.txt" | tr -d ' ') entries," \
             "after: $(wc -l < "$WORK/tree_after.txt" | tr -d ' '))"
        # ATTRIBUTION: a gate that FAILED while a file it reads was changing
        # has a SUSPECT verdict, not a finding. Naming the pair is the whole
        # difference between "two gates are red" and "two gates read a file I
        # was editing".
        diff "$WORK/tree_before.txt" "$WORK/tree_after.txt" \
            | grep '^[<>]' | sed 's/^[<>] *//' | awk '{print $NF}' | sort -u \
            > "$WORK/tree_changed.txt"
        _susp=""
        for _cg in $failed; do
            _cs="tests/$_cg.sh"
            while IFS= read -r _cf; do
                [ -n "$_cf" ] || continue
                if [ "$_cf" = "$_cs" ] || grep -qF "$_cf" "$_cs" 2>/dev/null; then
                    _susp="$_susp $_cg($_cf)"
                    break
                fi
            done < "$WORK/tree_changed.txt"
        done
        if [ -n "$_susp" ]; then
            echo
            echo "  >> SUSPECT VERDICTS — these FAILED gates read a file that"
            echo "     changed during the run. Re-run them on a quiet tree"
            echo "     BEFORE treating any of it as a finding:"
            for _e in $_susp; do echo "       $_e"; done
            TREE_SUSPECT="$_susp"
        fi
    fi
fi

# NOTE-class numbers: measurements a gate REPORTS but never gates on (ruled
# 2026-09-07, living-docs L2). A NOTE is per NUMBER where a verdict is per
# GATE, so it is deliberately NOT a fifth verdict in tests/lib/classify.sh —
# that would have to reach all three runners and their ground truths, and
# reopen the classifier divergence 14z-139 closed. The convention: a gate
# prints `NOTE: <key> <value>` at column 0, exits 0 with its usual PASS, and
# this block surfaces it. A number moving the wrong way is the signal.
echo
echo "== NOTE-class numbers (reported, never fatal) =="
_notes=0
for _f in "$WORK"/*.out; do
    [ -f "$_f" ] || continue
    _g="$(basename "$_f" .out)"
    while IFS= read -r _line; do
        # An EMPTY command substitution still feeds `read` one blank line, so
        # without this guard the block printed a row for every gate in the
        # tier with nothing after its name (measured on the first run).
        [ -n "$_line" ] || continue
        printf '  %-34s %s\n' "$_g" "${_line#NOTE: }"
        _notes=$((_notes + 1))
    done <<EOF
$(grep '^NOTE: ' "$_f" 2>/dev/null || true)
EOF
done
[ "$_notes" = 0 ] && echo "  (none)"

# THE CONTROLS READOUT (14z-147). `fired / declared` is the number the
# maintainer asked for; the executable rows are what makes FIRED more than a
# self-report. Undeclared gates are a NOTE-class count (the grammar postdates
# most of the suite); a red control is already in the tally above.
# Printed only when the tier DECLARED or EXECUTED anything: a tree with no
# `# MUST-FIRE:` line prints nothing here, which keeps this runner's output
# byte-identical to the generic harness's over its declaration-free fake repo
# (bbh fidelity F1, `tests/test_bbh_fidelity.sh` — red on the first strict run
# after this block landed, 14z-147). The reader was LIFTED into bbh 14z-148
# (its lib/sh/controls.sh, a copy), so F1 now covers declaring gates too and
# F2 (opt-in, the real tier) is exact again; the header line below is generic
# on both sides by construction — it named this file until the lift.
_xn=$((x_ok + x_lies + x_refused + x_died))
if [ $((c_decl + c_none + _xn)) != 0 ]; then
echo
echo "== must-fire controls =="
echo "  read:     fired $c_fired / declared $c_decl  (gates declaring none: $c_none; undeclared: $c_undecl)"
if [ "$EXEC_CTL" = none ]; then
    echo "  executed: (off — --exec-controls none)"
else
    echo "  executed: $_xn  honoured $x_ok  lies $x_lies  refused $x_refused  died $x_died  (--exec-controls $EXEC_CTL)"
    awk -F'\t' '$3 != "HONOURED" {printf "      %-30s %-24s %s\n", $1, $2, $3}' "$WORK/controls.tsv"
fi
fi

echo
echo "======================================================================"
printf 'PASS %-4s  SKIP %-4s  FAIL %-4s  MISSING %s\n' \
    "$n_pass" "$n_skip" "$n_fail" "$n_miss"
[ -n "$skipped" ] && echo "skipped:$skipped"
[ -n "$failed" ]  && echo "failed: $failed"
# THE CAVEAT BELONGS IN THE SUMMARY, not only in a section above it (14z-144).
# The failure list is what a reader acts on; on 2026-09-09 the tree-change
# section printed the offending file and was skipped over, because the eye goes
# to `failed:` and stops.
if [ -n "${TREE_SUSPECT:-}" ]; then
    echo "SUSPECT: tracked files changed DURING this run and these failures read"
    echo "         them —$TREE_SUSPECT"
    echo "         Re-run on a quiet tree before treating them as findings."
fi

rc=0
[ "$n_fail" = 0 ] && [ "$n_miss" = 0 ] || rc=1
if [ "$STRICT" = 1 ] && [ "$n_skip" != 0 ]; then
    echo "--strict: SKIP counts as failure (a skipped gate asserts NOTHING)"
    rc=1
fi
[ "$rc" = 0 ] && echo "GREEN — every registered emulator-free gate passed." \
              || echo "NOT GREEN — see above. Rule 6: fixing this is the only task."
exit $rc
