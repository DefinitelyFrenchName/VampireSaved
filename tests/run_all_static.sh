#!/bin/sh
# run_all_static.sh — THE PRE-COMMIT GATE CHAIN. One command, every gate that
# does not need an emulator. (14z-94, GitHub #30.)
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
#
# Registries: tests/ci_portable.txt (ROM-free, runs anywhere)
#             tests/ci_static.txt   (needs ROMDIR and/or build dirs; no emulator)
# A gate that is emulator-free and in NEITHER file is reported as UNREGISTERED
# — that check is the actual anti-orphan mechanism, and without it this
# script would simply become a new, smaller thing to forget to update.
set -eu
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"

STRICT=0; TIER=all; LIST=0
while [ $# -gt 0 ]; do
    case "$1" in
    --strict) STRICT=1 ;;
    --list)   LIST=1 ;;
    --tier)   shift; TIER="${1:?--tier needs portable|static|all}" ;;
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
        _out="$(tests/"$g".sh </dev/null 2>&1)" && _st=0 || _st=$?
        _t1=$(date +%s)
        _dur=$((_t1 - _t0))
        if printf '%s' "$_out" | grep -qE '^ *SKIP'; then
            _why="$(printf '%s' "$_out" | grep -E '^ *SKIP' | head -1 | cut -c1-58)"
            printf '  %-34s SKIP  %3ss  %s\n' "$g" "$_dur" "$_why"
            n_skip=$((n_skip + 1)); skipped="$skipped $g"
        elif [ "$_st" = 0 ]; then
            printf '  %-34s PASS  %3ss\n' "$g" "$_dur"
            n_pass=$((n_pass + 1))
        else
            printf '  %-34s FAIL  %3ss  (exit %s)\n' "$g" "$_dur" "$_st"
            printf '%s\n' "$_out" | tail -4 | sed 's/^/        | /'
            n_fail=$((n_fail + 1)); failed="$failed $g"
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
EMU = re.compile(r'run_(replay_)?(mame|fbneo)\.sh|run_replay_guarded\.sh'
                 r'|MAME_BIN|FBNEO_BIN|autoboot_script|emu/fbneo/fbneo'
                 r'|run_battery')
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
echo "======================================================================"
printf 'PASS %-4s  SKIP %-4s  FAIL %-4s  MISSING %s\n' \
    "$n_pass" "$n_skip" "$n_fail" "$n_miss"
[ -n "$skipped" ] && echo "skipped:$skipped"
[ -n "$failed" ]  && echo "failed: $failed"

rc=0
[ "$n_fail" = 0 ] && [ "$n_miss" = 0 ] || rc=1
if [ "$STRICT" = 1 ] && [ "$n_skip" != 0 ]; then
    echo "--strict: SKIP counts as failure (a skipped gate asserts NOTHING)"
    rc=1
fi
[ "$rc" = 0 ] && echo "GREEN — every registered emulator-free gate passed." \
              || echo "NOT GREEN — see above. Rule 6: fixing this is the only task."
exit $rc
