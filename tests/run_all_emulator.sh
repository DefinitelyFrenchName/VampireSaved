#!/bin/sh
# run_all_emulator.sh — THE EMULATOR-TIER GATE CHAIN. One command, every gate
# that needs MAME, FBNeo or the Verilator simulator. (14z-128.)
#
# WHY THIS EXISTS. tests/run_all_static.sh ended the same failure for the
# emulator-FREE set in 14z-94 and said so in its own header: "Emulator gates,
# soaks and one-off rigs are deliberately NOT here — they stay manual, and
# HANDOFF.md is their index." An index is not a runner. Measured at the 14z-127
# close and re-derived by this script on every run: 164 emulator-tier gates, 32
# of them named by any runner. The other 132 could be run only by typing a
# filename.
#
# That was survivable while the emulator tier was a development instrument. It
# stopped being survivable when the maintainer ruled the release policy (STATE
# "RELEASE-TIME TEST SCOPE", 2026-09-02):
#
#     "at release time, ALL tests should be run ... unless explicitly approved
#      AT release time, anything red, anything skipped is a hard fail of the
#      release process"
#
# A policy of "all tests" cannot operate over a set nobody enumerates, and
# "anything skipped is a hard fail" cannot operate over gates that self-skip
# with exit 0. So: tests/ci_emulator.tsv enumerates the set (completeness
# enforced both ways, below), and this script counts SKIP separately from PASS
# exactly as run_all_static.sh does, because SKIP IS NOT PASS (GitHub #29).
#
# WHAT IT IS NOT. Not a replacement for run_battery_m2.sh, which BUILDS a ROM
# and is the stage-6 dev-build chain; not the freeze ritual (that is
# run_suite.sh --freeze per track). This runs gates against builds that already
# exist.
#
# SCOPE, and it is the maintainer's call, not this script's. Every row of the
# registry carries `release` or `out`, and every `out` row carries its reason.
# `out` means OUT OF RELEASE SCOPE — never "do not run": --scope all runs
# everything, and that is the mode the sweep uses, because a gate nobody runs
# rots whether or not it gates a release.
#
# ORDER IS NOT DECORATION. The `prereq` lane — the instrument and verdict-logic
# ground truths — runs FIRST and, by default, a failure there STOPS the run.
# An instrument that moved invalidates every measurement taken after it
# ([CPE-24], and test_mame_parity.sh's own header). --keep-going overrides.
#
# Usage:
#   ROMDIR=... tests/run_all_emulator.sh                 prereq+fbneo+mame, release scope
#   ROMDIR=... tests/run_all_emulator.sh --scope all     + the out-of-scope rows
#   ... --lane prereq|mame|fbneo|mister|all              default: all but mister
#   ... --cadence romset|bitstream|all                   default: all
#   ... --freeze                                         = --cadence romset (see below)
#   ... --only 'glob'                                    a subset (shell glob on the gate name)
#   ... --jobs N                                         run N gates at once (default 1)
#   ... --timeout SECS                                   per gate (default 5400 = 90 min)
#   ... --log DIR                                        default build/emu_sweep_<stamp>
#   ... --resume                                         skip gates already in the log's results.tsv
#   ... --strict                                         SKIP and UNREGISTERED are failures too
#   ... --keep-going                                     do not stop when the prereq lane fails
#   ... --dry-run                                        print the resolved command per gate
#   ... --list                                           print the registry and exit
#
# THE MiSTer LANE IS OPT-IN (--lane mister or --lane all). Its gates are
# Verilator simulations at ~1 s per simulated frame: two of them are ~2 x 65
# min on their own. It is a release lane, not an overnight-sweep lane.
#
# CADENCE — WHAT MOVING THING A GATE FOLLOWS, which is a different question
# from whether it gates a release (maintainer-ruled 2026-09-03). Six MiSTer
# gates follow the BITSTREAM, which moves on its own cadence: the .rbf has not
# moved since 14z-108 while the romset moved many times. They are release-scope
# — a release always pays them — but a FREEZE should only pay them when the
# freeze targets MiSTer. `--freeze` selects cadence=romset and NAMES the gates
# it dropped, so the "should this freeze include them?" question is asked by
# the runner rather than remembered. Same rule the maintainer already made for
# the stock control MRA: run once per new .rbf, not per romset release.
# THE DEFAULT IS `all`, so no existing invocation changes behaviour.
set -eu
REPO="$(cd "$(dirname "$0")/.." && pwd)"

# ROMDIR must be ABSOLUTE — the same trap run_all_static.sh canonicalises for:
# at least two gates resolve it from a different working directory than the
# caller's (14z-96).
if [ -n "${ROMDIR:-}" ]; then
    ROMDIR="$(CDPATH= cd "$ROMDIR" && pwd)" || {
        echo "ROMDIR '$ROMDIR' does not resolve from $(pwd)" >&2; exit 2; }
    export ROMDIR
fi
cd "$REPO"

REG=tests/ci_emulator.tsv
SCOPE=release; CADENCE=all; LANES="prereq fbneo mame"; LANES_SET=""; ONLY=""; JOBS=1; TMO=5400
LOGDIR=""; RESUME=0; STRICT=0; KEEPGOING=0; DRY=0; LIST=0
while [ $# -gt 0 ]; do
    case "$1" in
    --scope)   shift; SCOPE="${1:?--scope needs release|all}" ;;
    --cadence) shift; CADENCE="${1:?--cadence needs romset|bitstream|all}" ;;
    --freeze)  CADENCE=romset ;;
    # --lane ACCUMULATES. It used to assign, so `--lane fbneo --lane mame`
    # silently ran only the mame lane — six gates skipped without a word, in
    # the runner whose whole point is that nothing goes unasked. Caught on its
    # first real invocation (14z-128).
    --lane)    shift; case "${1:?--lane needs a lane}" in
                      all) LANES="prereq fbneo mame mister" ;;
                      *)   case " $LANES_SET " in
                           *" $1 "*) ;;                    # already selected
                           *) LANES_SET="$LANES_SET $1" ;;
                           esac
                           LANES="${LANES_SET# }" ;; esac ;;
    --only)    shift; ONLY="${1:?--only needs a glob}" ;;
    --jobs)    shift; JOBS="${1:?--jobs needs N}" ;;
    --timeout) shift; TMO="${1:?--timeout needs seconds}" ;;
    --log)     shift; LOGDIR="${1:?--log needs a dir}" ;;
    --resume)  RESUME=1 ;;
    --strict)  STRICT=1 ;;
    --keep-going) KEEPGOING=1 ;;
    --dry-run) DRY=1 ;;
    --list)    LIST=1 ;;
    -h|--help) sed -n '2,72p' "$0"; exit 0 ;;
    *) echo "unknown argument '$1' (try --help)" >&2; exit 2 ;;
    esac
    shift
done

[ -f "$REG" ] || { echo "missing registry $REG" >&2; exit 2; }

# ── THE BUILD SET UNDER TEST ────────────────────────────────────────────────
# Placeholders the registry's `args` column may use. Overridable by env so one
# sweep can be re-run against another generation without editing the registry.
# Defaults: the CURRENT REGISTERED freeze (merged-m14 / donovan-m18 /
# huitzil-m25 / pyron-m19, mark M12, 14z-119). Deliberately not the newest
# built tracks: an UNREGISTERED image makes run_suite.sh refuse, so a sweep
# against one would report dispatch failures instead of gate verdicts.
MERGED="${MERGED:-build/m3b_merged21}"
DON="${DON:-build/don_m18}"
HUI="${HUI:-build/hui52}"
PYR="${PYR:-build/pyron36}"
STOCK="${STOCK:-build/m5_stock13}"

expand() {  # expand <string> — the %PLACEHOLDER% vocabulary
    printf '%s' "$1" \
      | sed -e "s|%MERGED_RP%|$MERGED/rompath|g" -e "s|%MERGED%|$MERGED|g" \
            -e "s|%DON_RP%|$DON/rompath|g"       -e "s|%DON%|$DON|g" \
            -e "s|%HUI_RP%|$HUI/rompath|g"       -e "s|%HUI%|$HUI|g" \
            -e "s|%PYR_RP%|$PYR/rompath|g"       -e "s|%PYR%|$PYR|g" \
            -e "s|%STOCK_RP%|$STOCK/rompath|g"   -e "s|%STOCK%|$STOCK|g"
}

# ── THE REGISTRY ────────────────────────────────────────────────────────────
rows() { sed 's/\r$//' "$REG" | awk -F'\t' 'NF>=3 && $0 !~ /^#/ && $1 != ""'; }

selected() {  # rows matching --lane / --scope / --cadence / --only, in lane order
    for _l in $LANES; do
        rows | awk -F'\t' -v lane="$_l" -v scope="$SCOPE" -v cad="$CADENCE" '
            $2 == lane && (scope == "all" || $3 == "release") \
                       && (cad == "all"   || $4 == cad)'
    done | while IFS= read -r line; do
        _g="${line%%	*}"
        if [ -n "$ONLY" ]; then
            # shellcheck disable=SC2254
            case "$_g" in $ONLY) ;; *) continue ;; esac
        fi
        printf '%s\n' "$line"
    done
}

if [ "$LIST" = 1 ]; then
    printf '%-34s %-7s %-8s %-9s %s\n' GATE LANE SCOPE CADENCE ARGS
    selected | while IFS="$(printf '\t')" read -r g lane scope cadence args note; do
        printf '%-34s %-7s %-8s %-9s %s\n' "$g" "$lane" "$scope" "$cadence" "$(expand "${args:--}")"
    done
    echo
    echo "lanes=$LANES scope=$SCOPE cadence=$CADENCE only=${ONLY:-*}  ($(selected | wc -l | tr -d ' ') gates)"
    exit 0
fi

# ── PRECONDITIONS ───────────────────────────────────────────────────────────
: "${ROMDIR:?set ROMDIR — every gate here reads the reference set}"
python3 tools/audit_roms.py "$ROMDIR" > /dev/null || {
    echo "ROM audit FAILED — stop (CLAUDE.md §3)"; exit 1; }

STAMP="$(date +%Y%m%d_%H%M%S)"
[ -n "$LOGDIR" ] || LOGDIR="build/emu_sweep_$STAMP"
mkdir -p "$LOGDIR"
RESULTS="$LOGDIR/results.tsv"
[ -f "$RESULTS" ] || printf 'gate\tlane\tscope\tverdict\tseconds\tdetail\n' > "$RESULTS"

echo "== the emulator-tier sweep =="
echo "  registry   $REG"
echo "  lanes      $LANES"
echo "  scope      $SCOPE${ONLY:+   only=$ONLY}"
echo "  cadence    $CADENCE"
echo "  jobs       $JOBS   timeout ${TMO}s"
echo "  log        $LOGDIR"
echo "  ROMDIR     $ROMDIR"

# The build set, IDENTIFIED — never named. A rompath is a search path, and a
# fingerprint equal to a known reference row is a bug until proven otherwise
# ([VSP-106], [VSP-108]).
echo "  builds under test:"
for pair in "MERGED=$MERGED" "DON=$DON" "HUI=$HUI" "PYR=$PYR" "STOCK=$STOCK"; do
    _n="${pair%%=*}"; _d="${pair#*=}"
    if [ ! -d "$_d/rompath" ]; then
        printf '    %-7s %-24s ABSENT\n' "$_n" "$_d"
        continue
    fi
    _set=vsavjw; [ -f "$_d/rompath/vsavjw.zip" ] || _set=vsavj
    _fp="$(python3 tools/build_fingerprint.py "$_d/rompath" --set "$_set" --sha-only 2>/dev/null | cut -c1-8)"
    printf '    %-7s %-24s %-6s %s\n' "$_n" "$_d" "$_set" "${_fp:-?}"
done

# THE CADENCE QUESTION, ASKED BY THE RUNNER RATHER THAN REMEMBERED.
# The maintainer's ruling (2026-09-03) is that a freeze pays the bitstream
# gates only when it TARGETS MiSTer, and that if the automation were
# unrealistic the question should be asked at freeze. It is not unrealistic —
# so the runner names exactly what it dropped and asks. A ritual step that
# lives only in prose is the step that gets skipped (14z-126b: three freeze
# tags were missing because "the tagging step of the ritual was simply
# skipped").
if [ "$CADENCE" = romset ]; then
    _dropped="$(rows | awk -F'\t' '$4 == "bitstream" { printf "%s ", $1 }')"
    if [ -n "$_dropped" ]; then
        echo
        echo "  ── CADENCE: bitstream gates DROPPED ──────────────────────────────"
        echo "     $_dropped"
        echo "     These follow the .rbf, not the romset (ruled 2026-09-03). A"
        echo "     RELEASE always runs them; this run does not."
        echo "     >> IS THIS FREEZE TARGETING MiSTer? If yes, re-run with"
        echo "        --cadence all --lane mister. If no, this is correct."
        echo "  ──────────────────────────────────────────────────────────────────"
    fi
fi

# The instruments, identified the same way. Gates resolve these themselves;
# printing them here is what makes a log readable six months later.
_MAME_W="${MAME_WIDE_BIN:-$HOME/.cache/vampire-saved/mame/cps2}"
_MAME_R="${MAME_REF_BIN:-$HOME/.cache/vampire-saved/mame-ref/cps2}"
echo "  instruments:"
for pair in "mame-wide=$_MAME_W" "mame-ref=$_MAME_R" "fbneo=$REPO/emu/fbneo/fbneo"; do
    _n="${pair%%=*}"; _b="${pair#*=}"
    if [ -x "$_b" ]; then printf '    %-10s %s\n' "$_n" "$_b"
    else                  printf '    %-10s %s   MISSING\n' "$_n" "$_b"; fi
done
command -v timeout >/dev/null 2>&1 || command -v gtimeout >/dev/null 2>&1 || {
    echo "  note: no timeout(1) — gates will run unbounded"; }
TIMEOUT_BIN="$(command -v timeout 2>/dev/null || command -v gtimeout 2>/dev/null || true)"
echo

# WORKING-TREE SNAPSHOT. A sweep that rewrites tracked artifacts invalidates
# its own evidence, and a run was voided that way on 2026-09-02.
tree_before=""
if git rev-parse --git-dir >/dev/null 2>&1; then
    tree_before="$(git status --porcelain -- . 2>/dev/null | grep -v '^??' || true)"
fi

# ── THE RUN ─────────────────────────────────────────────────────────────────
run_one() {   # run_one <gate> <lane> <scope> <args> — writes one results row
    _g="$1"; _lane="$2"; _scope="$3"; _args="$4"
    _log="$LOGDIR/$_g.log"
    if [ ! -x "tests/$_g.sh" ]; then
        printf '%s\t%s\t%s\tMISSING\t0\tregistered but not executable\n' \
            "$_g" "$_lane" "$_scope" >> "$RESULTS"
        return
    fi
    # Split args: VAR=value tokens before the script become environment.
    _env=""; _pos=""
    for _tok in $(expand "$_args"); do
        [ "$_tok" = "-" ] && continue
        case "$_tok" in
        [A-Z_][A-Z0-9_]*=*) _env="$_env $_tok" ;;
        *)                  _pos="$_pos $_tok" ;;
        esac
    done
    _t0=$(date +%s)
    {
        echo "### $_g  lane=$_lane scope=$_scope"
        echo "### cmd: env$_env tests/$_g.sh$_pos"
        echo "### started $(date -u +%Y-%m-%dT%H:%M:%SZ)"
    } > "$_log"
    # </dev/null: a gate that reads stdin otherwise swallows the rest of the
    # queue — paid for once already in run_all_static.sh.
    if [ -n "$TIMEOUT_BIN" ]; then
        # shellcheck disable=SC2086
        env $_env "$TIMEOUT_BIN" -k 30 "$TMO" "tests/$_g.sh" $_pos </dev/null >> "$_log" 2>&1 && _st=0 || _st=$?
    else
        # shellcheck disable=SC2086
        env $_env "tests/$_g.sh" $_pos </dev/null >> "$_log" 2>&1 && _st=0 || _st=$?
    fi
    _t1=$(date +%s); _dur=$((_t1 - _t0))
    # EXIT STATUS DECIDES FIRST. A gate that prints `SKIP:` AND exits non-zero
    # is a FAILURE, not a skip — and the case is not hypothetical: on the first
    # sweep `test_wide_profile.sh` printed "SKIPPED: set FBNEO_REF ..." and then
    # exited 2 with "PARTIAL: the emulator superset invariant was NOT run". The
    # gate was scrupulous; the classifier downgraded it, and the ONE gate that
    # justifies modifying an emulator at all read as a benign skip. SKIP is
    # only ever exit 0 plus the marker.
    if [ "$_st" = 124 ] || [ "$_st" = 137 ]; then
        _v=TIMEOUT; _d="killed after ${TMO}s"
    elif [ "$_st" != 0 ]; then
        _v=FAIL;    _d="exit $_st: $(grep -aE '^ *(SKIP|PARTIAL)|FAIL|ERROR|Traceback|not found' "$_log" | tail -1 | cut -c1-90)"
    elif grep -qE '^ *SKIP' "$_log"; then
        _v=SKIP;    _d="$(grep -E '^ *SKIP' "$_log" | head -1 | cut -c1-90)"
    else
        _v=PASS;    _d=""
    fi
    printf '%s\t%s\t%s\t%s\t%s\t%s\n' "$_g" "$_lane" "$_scope" "$_v" "$_dur" "$_d" >> "$RESULTS"
    printf '  %-34s %-7s %4ss  %s\n' "$_g" "$_v" "$_dur" "$_d"
}

already_done() {  # already_done <gate>
    [ "$RESUME" = 1 ] || return 1
    awk -F'\t' -v g="$1" 'NR>1 && $1==g {found=1} END{exit !found}' "$RESULTS"
}

n_total=0
for _l in $LANES; do
    _rows="$(selected | awk -F'\t' -v lane="$_l" '$2 == lane')"
    [ -n "$_rows" ] || continue
    _n=$(printf '%s\n' "$_rows" | wc -l | tr -d ' ')
    echo "== $_l lane ($_n gates) =="
    n_total=$((n_total + _n))
    # The prereq lane runs SEQUENTIALLY whatever --jobs says: these gates
    # measure the instruments, and an instrument measured under contention is
    # a different instrument.
    _jobs=$JOBS; [ "$_l" = prereq ] && _jobs=1
    _running=0
    # THE LANE'S ROWS GO THROUGH A FILE, NOT A PIPE. A `... | while read` loop
    # runs in a SUBSHELL: the background gates it starts belong to the
    # subshell, so the main shell's `wait` had nothing of its own to wait for
    # and the lane announced itself finished while its last partial batch was
    # still running. Measured on the second real invocation (14z-128):
    # `test_wide_profile` was left running ORPHANED, overlapping the next
    # lane, and its result landed under the wrong heading. Reading from a file
    # keeps the loop — and `wait`, and `_running` — in the main shell.
    printf '%s\n' "$_rows" > "$LOGDIR/.lane_$_l"
    while IFS="$(printf '\t')" read -r g lane scope cadence args note; do
        [ -n "$g" ] || continue
        if already_done "$g"; then
            printf '  %-34s %-7s        (resumed: already in results.tsv)\n' "$g" "-"
            continue
        fi
        if [ "$DRY" = 1 ]; then
            _shown="$(expand "${args:--}")"; [ "$_shown" = "-" ] && _shown=""
            printf '  %-34s %-7s %s\n' "$g" "$lane" "tests/$g.sh $_shown"
            continue
        fi
        if [ "$_jobs" -le 1 ]; then
            run_one "$g" "$lane" "$scope" "${args:--}"
        else
            run_one "$g" "$lane" "$scope" "${args:--}" &
            _running=$((_running + 1))
            if [ "$_running" -ge "$_jobs" ]; then wait; _running=0; fi
        fi
    done < "$LOGDIR/.lane_$_l"
    wait                       # the lane is not finished until its gates are
    rm -f "$LOGDIR/.lane_$_l"
    # THE INSTRUMENT GATE. A red prereq means every later measurement is
    # measured with a moved instrument, so the run stops by default.
    if [ "$_l" = prereq ] && [ "$DRY" = 0 ] && [ "$KEEPGOING" = 0 ]; then
        _bad="$(awk -F'\t' 'NR>1 && $2=="prereq" && ($4=="FAIL"||$4=="TIMEOUT"||$4=="MISSING") {print $1}' "$RESULTS")"
        if [ -n "$_bad" ]; then
            echo
            echo "STOP: the prereq lane is not green:"
            printf '%s\n' "$_bad" | sed 's/^/      /'
            echo "      These gates measure the INSTRUMENTS. A measurement taken after a"
            echo "      moved instrument is not evidence ([CPE-24]). Fix them, or re-run"
            echo "      with --keep-going if you have a reason to accept the risk."
            exit 1
        fi
    fi
done

# ── REGISTRY COVERAGE (the anti-orphan check, re-derived here every run) ────
echo
echo "== registry coverage (the anti-orphan check) =="
python3 - "$REG" "$LOGDIR" <<'PY'
import glob, os, re, sys
reg_path, logdir = sys.argv[1], sys.argv[2]
def reg(p):
    if not os.path.exists(p): return set()
    return {l.split('#')[0].strip() for l in open(p)} - {''}
known_static = reg("tests/ci_portable.txt") | reg("tests/ci_static.txt")
rows = {}
for line in open(reg_path):
    if line.startswith("#") or not line.strip():
        continue
    c = line.rstrip("\n").split("\t")
    if len(c) >= 3 and c[0]:
        rows[c[0]] = c
# The tier classifier is run_all_static.sh's, kept deliberately identical: a
# gate is emulator-tier when it reaches an emulator wrapper, transitively
# through tests/lib/*.sh. If the two ever disagree, a gate belongs to neither
# runner and that is exactly the orphan class both exist to end.
EMU = re.compile(r'run_(replay_)?(mame|fbneo)\.sh|run_replay_guarded\.sh'
                 r'|MAME_BIN|FBNEO_BIN|autoboot_script|emu/fbneo/fbneo'
                 r'|run_battery|run_sim_jtcps2\.sh'
                 r'|run_inp_probe\.sh|run_inp_guarded\.sh')
SRC = re.compile(r'^\s*\.\s+"?\$(?:REPO|\{REPO\})"?/(tests/lib/[a-z0-9_]+\.sh)', re.M)
def uncomment(path):
    try:
        return "\n".join(l for l in open(path, errors="replace").read().splitlines()
                         if not l.lstrip().startswith("#"))
    except OSError:
        return ""
def needs_emulator(path, depth=0):
    body = uncomment(path)
    if EMU.search(body):
        return True
    if depth < 2:
        for lib in SRC.findall(body):
            if needs_emulator(lib, depth + 1):
                return True
    return False
tier = set()
for p in sorted(glob.glob("tests/*.sh")):
    n = os.path.basename(p)[:-3]
    if n in known_static or n.startswith("run_"):
        continue
    if needs_emulator(p):
        tier.add(n)
unreg = sorted(tier - set(rows))
dead = sorted(set(rows) - tier)
rel = sum(1 for c in rows.values() if c[2] == "release")
print(f"  {len(tier)} emulator-tier gates; {len(rows)} registered "
      f"({rel} release scope, {len(rows)-rel} out of release scope)")
if unreg:
    print(f"  {len(unreg)} UNREGISTERED (in no runner — a release would not even ask them):")
    for n in unreg:
        print("      " + n)
if dead:
    print(f"  {len(dead)} DEAD ROW(S) (registered, script gone):")
    for n in dead:
        print("      " + n)
if not unreg and not dead:
    print("  ok: every emulator-tier gate has exactly one registry row")
open(os.path.join(logdir, "coverage"), "w").write(
    f"{len(unreg)} {len(dead)}\n" + "\n".join(unreg + dead))
PY
COV="$(head -1 "$LOGDIR/coverage" 2>/dev/null || echo '0 0')"
n_unreg="${COV%% *}"; n_dead="${COV##* }"

# ── WORKING TREE ────────────────────────────────────────────────────────────
echo
echo "== working tree =="
if ! git rev-parse --git-dir >/dev/null 2>&1; then
    echo "  note: not a git checkout — not checked"
else
    tree_after="$(git status --porcelain -- . 2>/dev/null | grep -v '^??' || true)"
    if [ "$tree_before" = "$tree_after" ]; then
        echo "  ok: no tracked file changed during the run"
    else
        printf '%s\n' "$tree_before" | awk 'NF' > "$LOGDIR/tree_before.txt"
        printf '%s\n' "$tree_after"  | awk 'NF' > "$LOGDIR/tree_after.txt"
        echo "  DIRTIED by the run — a sweep that rewrites tracked artifacts"
        echo "  invalidates its own evidence:"
        diff "$LOGDIR/tree_before.txt" "$LOGDIR/tree_after.txt" \
            | grep '^[<>]' | sed 's/^/      /' | head -12
    fi
fi

# ── VERDICT ─────────────────────────────────────────────────────────────────
if [ "$DRY" = 1 ]; then echo; echo "--dry-run: nothing was executed."; exit 0; fi
n_pass=$(awk -F'\t' 'NR>1 && $4=="PASS"'    "$RESULTS" | wc -l | tr -d ' ')
n_skip=$(awk -F'\t' 'NR>1 && $4=="SKIP"'    "$RESULTS" | wc -l | tr -d ' ')
n_fail=$(awk -F'\t' 'NR>1 && $4=="FAIL"'    "$RESULTS" | wc -l | tr -d ' ')
n_tmo=$(awk  -F'\t' 'NR>1 && $4=="TIMEOUT"' "$RESULTS" | wc -l | tr -d ' ')
n_miss=$(awk -F'\t' 'NR>1 && $4=="MISSING"' "$RESULTS" | wc -l | tr -d ' ')
echo
echo "======================================================================"
printf 'PASS %-4s  SKIP %-4s  FAIL %-4s  TIMEOUT %-4s  MISSING %s\n' \
    "$n_pass" "$n_skip" "$n_fail" "$n_tmo" "$n_miss"
for kind in SKIP FAIL TIMEOUT MISSING; do
    _l="$(awk -F'\t' -v k="$kind" 'NR>1 && $4==k {printf " %s", $1}' "$RESULTS")"
    [ -n "$_l" ] && echo "$(printf '%-8s' "$kind"):$_l"
done
echo "results   $RESULTS"
rc=0
[ "$n_fail" = 0 ] && [ "$n_tmo" = 0 ] && [ "$n_miss" = 0 ] || rc=1
if [ "$STRICT" = 1 ]; then
    if [ "$n_skip" != 0 ]; then
        echo "--strict: SKIP counts as failure (a skipped gate asserts NOTHING,"
        echo "          and at release the maintainer's ruling makes it a hard fail)"
        rc=1
    fi
    if [ "$n_unreg" != 0 ] || [ "$n_dead" != 0 ]; then
        echo "--strict: an unregistered or dead registry row is a failure"
        rc=1
    fi
fi
[ "$rc" = 0 ] && echo "GREEN — every selected emulator-tier gate passed." \
              || echo "NOT GREEN — see above. Rule 6: fixing this is the only task."
exit $rc
