#!/bin/sh
# audit_x2b7ef4_reach_m18.sh — DOES ANY NAMING PART READ A CORRUPTED x2b7ef4 RECORD ON merged-m18? The reachability the maintainer asked for (2026-09-19, "Measure it now (Recommended)"), re-measured SOUNDLY (14z-170): a -debug read watch on the corrupted bytes ONLY, armed after boot, every run checked frame-aligned against a non-debug run of the same rig.
#
# WHAT: whether any naming part on merged-m18 READS one of the companion-effect records the
#   placeholder scan corrupted there (fixed in M19): a -debug read watch over the corrupted
#   bytes only, armed after boot, with every run's node trajectory checked frame-aligned
#   against a non-debug run so a debugger stop cannot desync the replay unnoticed.
# HOW: 42 MAME runs (20 Donovan and Pyron parts, each a debug watch and a field-trace
#   reference, through the merged wheel's path with the parity pins, plus the control's
#   two); hits, first hit frame, the aligned prefix and the skew frame frozen per part; the
#   control widens the watch over a hot block, which must hit in the match and desync the
#   trajectory.
# EXPECTS: no read of a corrupted record on any part, every run tracking its reference (a
#   run that never tracks is VOID), the frozen skews; the hot-block control hits and skews
#   and fails. The gate refuses any build but merged-m18 by fingerprint.
# FOLLOWS: build/manifest/ emu/mame-patches/ tests/expected/registry.tsv
#   tests/expected/x2b7ef4_reach_m18.tsv tests/lib/controls.sh tests/lua/field_trace.lua
#   tests/lua/trace_writes.lua tests/replays/ tools/build_fingerprint.py tools/name_moves.py
#   tools/run_mame.sh tools/setup_mame.sh
#
# MUST-FIRE: known-bad: hot-block — the same rig with the watch widened over the block Donovan's copy reads in every match (CPU:$0FCC00, 1 KB) must HIT in the match AND its node trajectory must then leave the reference's, so the watch can fire and the trajectory check sees the desync a stop causes (in-gate: one run of donovan_4; mode: the widened watch replaces donovan_4's and the gate FAILs)
#
# WHY. merged-m16..m18 shipped companion-effect records the generator's in-place placeholder scan
# had corrupted (patch_notes 14z-170 §5; fixed in M19). The first measurement of whether a match
# ever reads them (build/rc170/reach/, 14z-170) watched Donovan's whole copy — including a block
# read thousands of times per match — and every debugger STOP advances the script's frame counter,
# so its replays desynced by up to ~5,700 frames and never played the moves ([CPE-5],
# docs/platform/gotchas.md "Debugger stops DESYNC replay frame counting", PAID AGAIN 14z-170).
# Its Donovan answer was VOID; this gate is the sound one. A "never read" is sound only from a
# run with NO stop before its question: so the watch covers the corrupted bytes alone (three
# clusters for Donovan, one span for Pyron — where the M18 and M19 images differ inside each
# copy), it is armed at frame 2000 (after the boot sweep, before the match at 2363), and the
# debug run's P1 anim-node trajectory (every change of +0x1C, RAM:$FF841C, with its frame) must
# follow a NON-debug run's (field_trace.lua) — the run played the part's moves on the reference's
# frames; a run that never tracks the reference is VOID, and where one leaves it is frozen. (Measured
# 14z-170 on pyron_6: an armed-but-silent debug run's trajectory is the reference's frame for
# frame; whole-block dumps differ between the two instruments and are not the test.)
#
# THE RIG: every Donovan and Pyron #136 naming part (tests/replays/naming/), through the merged
# wheel's real cursor path (the parity gate's OURS_PATH), the part's pokes plus the speed-level
# and RNG pins, run to its last input + 300.
#
# FROZEN: tests/expected/x2b7ef4_reach_m18.tsv — `<part> hits <n> first <frame|-> aligned <p>/<n> skew <frame|->`
# (p = the frame-exact common prefix of the n node changes before the first hit; skew = where the debug run
# first leaves the reference — measured 14z-170: donovan_10 and donovan_12 skew by ONE frame mid-move with no
# stop, deterministically, and play on slightly differently; their "no read" holds for the run they played),
# plus one `build <registry row>` row. FREEZE=1 rewrites it.
#
# NOT COVERED: moves the naming parts do not play (the CPU opponent's, the ladder's); FBNeo and
# the MiSTer core; builds other than merged-m18 (the ranges are its own — the gate refuses any
# other build by its registry fingerprint).
#
# Usage: ROMDIR=... [MAME_BIN=...] [BUILD=build/m3b_merged26] [JOBS=6] [FREEZE=1] tests/audit_x2b7ef4_reach_m18.sh
#   emulator tier, MAME; 42 runs (20 parts x debug + reference, plus the control's two)
set -eu
[ -n "${ROMDIR:-}" ] || { echo "FAIL: set ROMDIR"; exit 1; }
[ -d "$ROMDIR" ] && ROMDIR="$(cd "$ROMDIR" && pwd)"
REPO="$(cd "$(dirname "$0")/.." && pwd)"
MAME_BIN="${MAME_BIN:-$HOME/.cache/vampire-saved/mame/cps2}"; export MAME_BIN
BUILD="${BUILD:-build/m3b_merged26}"
case "$BUILD" in /*) ;; *) BUILD="$REPO/$BUILD" ;; esac
EXPECT="$REPO/tests/expected/x2b7ef4_reach_m18.tsv"
TW="$REPO/tests/lua/trace_writes.lua"
JOBS="${JOBS:-6}"
[ -x "$MAME_BIN" ] || { echo "SKIP: no MAME at $MAME_BIN"; exit 0; }
[ -f "$BUILD/rompath/vsavjw.zip" ] || { echo "SKIP: no merged-m18 build at $BUILD"; exit 0; }
. "$REPO/tests/lib/controls.sh"; vs_ctl_mode "$0"; MODE="${VS_CTL:-}"
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT INT TERM
fail=0
ok()  { printf '  ok    %s\n' "$1"; }
bad() { printf '  FAIL  %s\n' "$1"; fail=1; }
_bid="$(python3 "$REPO/tools/build_fingerprint.py" "$BUILD/rompath" --set vsavjw --registry "$REPO/tests/expected/registry.tsv" 2>/dev/null | tail -1)"
[ "$_bid" = merged-m18 ] || { echo "FAIL: $BUILD is '${_bid:-unregistered}', not merged-m18 — the watched ranges are merged-m18's own"; exit 1; }
# the corrupted bytes of merged-m18 (CPU addresses): where its copy differs from M19's repaired one
WATCH_don="f5efe,54,r;f7f56,54,r;fe16a,1d0,r"
WATCH_pyron="4bb5b0,190,r"
WATCH_hot="fcc00,400,r"
PATH_don="D D DR DR"; PATH_pyron="D D D D"
ARM=2000

run_part() {  # run_part <part> <watch>
    _p="$1"; _w="$2"; _t="${_p%%_*}"; [ "$_t" = donovan ] && _t=don
    _d="$W/$_p${3:-}"; mkdir -p "$_d"
    _j="$REPO/tests/replays/naming/${_p}.json"; _r="$REPO/tests/replays/naming/${_p}.rpl"
    _last="$(awk -F'[- ]' '/^[0-9]/{print $1}' "$_r" | sort -n | tail -1)"; _fr=$((_last + 300))
    eval "_path=\$PATH_$_t"
    awk -v path="$_path" '/^1104-1106 p2=R$/ && !done { n = split(path, m, " "); t = 1100
        for (i = 1; i <= n; i++) { printf "%d-%d p1=%s\n", t, t + 2, m[i]; t += 60 }; done = 1 }
        /^(1100|1160|1220|1280)-[0-9]+ p1=/ { next } { print }' "$_r" > "$_d/r.rpl"
    _pk="$(python3 -c "import json;print(';'.join(json.load(open('$_j'))['pokes']))");$(python3 -c "print(';'.join(f'{f}:ff8116:06' for f in range(2000,$_fr)))");$(python3 -c "print(';'.join(f'{f}:ff80d4:0000' for f in range(2363,$_fr)))")"
    mkdir -p "$_d/dbg" "$_d/ref"
    ( cd "$_d/dbg" && WATCH="$_w" WATCH_FROM=$ARM SAMPLE="ff841c,4" TRACE_OUT="$_d/dbg/t.txt" FRAMES=$_fr REPLAY="$_d/r.rpl" \
        POKES="$_pk" MAME_SANDBOX="$_d/dbg/sb" MAME_ROMPATH="$BUILD/rompath;$ROMDIR" \
        "$REPO/tools/run_mame.sh" vsavjw -debug -debugger none -autoboot_script "$TW" > "$_d/dbg/l.log" 2>&1; rm -rf "$_d/dbg/sb" ) </dev/null &
    ( cd "$_d/ref" && FIELDS="ff841c:l:node" FIELD_OUT="$_d/ref/f.ft" FIELD_FROM=$ARM FIELD_TO=$_fr FRAMES=$_fr REPLAY="$_d/r.rpl" \
        POKES="$_pk" MAME_SANDBOX="$_d/ref/sb" MAME_ROMPATH="$BUILD/rompath;$ROMDIR" \
        "$REPO/tools/run_mame.sh" vsavjw -autoboot_script "$REPO/tests/lua/field_trace.lua" > "$_d/ref/l.log" 2>&1; rm -rf "$_d/ref/sb" ) </dev/null &
    wait
}
# verdict_part <dir> -> "hits <n> first <f|-> aligned <k>/<k> ..." (k: node changes before the first hit, equal to the reference)
verdict_part() {
    python3 - "$1" "$ARM" <<'PY'
import sys, os
d, arm = sys.argv[1], int(sys.argv[2])
t = open(f"{d}/dbg/t.txt").read().splitlines() if os.path.exists(f"{d}/dbg/t.txt") else []
armed = any(l.startswith("ARMED ") for l in t); end = any(l.startswith("END ") for l in t)
# a hit is a stop logged at or after the arming frame (frame 1 is the debugger's initial break)
hits = [int(l.split()[1]) for l in t if l.startswith("frame ") and int(l.split()[1]) >= arm]
first = min(hits) if hits else None
dbg = [(int(l.split()[1]), int(l.split()[2], 16)) for l in t if l.startswith("S ") and int(l.split()[1]) > arm]
ref, prev = [], None
if os.path.exists(f"{d}/ref/f.ft"):
    for l in open(f"{d}/ref/f.ft"):
        p = l.split()
        if not p or p[0] != "F": continue
        v = int([x for x in p[2:] if x.startswith("node=")][0][5:])
        if prev is not None and v != prev and int(p[1]) > arm: ref.append((int(p[1]), v))
        prev = v
lim = first if first is not None else 10 ** 9
db = [x for x in dbg if x[0] < lim]; rb = [x for x in ref if x[0] < lim]
# the FRAME-EXACT common prefix of the two node-change lists, and where the debug run first leaves it
al = 0
while al < min(len(db), len(rb)) and db[al] == rb[al]: al += 1
skew = "-" if al == len(db) == len(rb) else (db[al][0] if al < len(db) else rb[al][0])
after_diff = int(first is not None and [x for x in dbg if x[0] >= lim][:50] != [x for x in ref if x[0] >= lim][:50])
print(f"hits {len(hits)} first {first if first is not None else '-'} aligned {al}/{len(rb)} armed {int(armed)} end {int(end)} afterdiff {after_diff} skew {skew}")
PY
}
PARTS="$(ls "$REPO"/tests/replays/naming/ | sed 's/\..*//' | sort -u | grep -E '^(donovan|pyron)_[0-9]+$' | sort -t_ -k1,1 -k2,2n)"
echo "== 1. $(echo $PARTS | wc -w | tr -d ' ') parts on $(basename "$BUILD") (merged-m18), a debug watch on the corrupted bytes armed at $ARM and a non-debug reference each, $JOBS at a time"
n=0
for p in $PARTS; do
    t="${p%%_*}"; [ "$t" = donovan ] && t=don
    eval "w=\$WATCH_$t"
    [ "$MODE" = hot-block ] && [ "$p" = donovan_4 ] && w="$WATCH_hot"
    run_part "$p" "$w" &
    n=$((n + 1)); [ $((n % (JOBS / 2 > 0 ? JOBS / 2 : 1))) = 0 ] && wait
done
wait
[ -z "$MODE" ] && { run_part donovan_4 "$WATCH_hot" _hot; }
: > "$W/got.tsv"; nfull=0
for p in $PARTS; do
    v="$(verdict_part "$W/$p")"
    set -- $v
    [ "$8" = 1 ] && [ "${10}" = 1 ] || bad "$p: the debug run did not arm at $ARM and reach its END ($v) — VOID"
    _a="${6%/*}"; _b="${6#*/}"
    [ "$_a" -gt 0 ] && [ "$_b" -gt 0 ] || bad "$p: the debug run never tracked the reference's node trajectory ($v) — its answer is VOID"
    [ "$_a" = "$_b" ] && nfull=$((nfull + 1))
    printf '%s\thits\t%s\tfirst\t%s\taligned\t%s\tskew\t%s\n' "$p" "$2" "$4" "$6" "${14}" >> "$W/got.tsv"
done
printf 'build\t%s\n' "$_bid" >> "$W/got.tsv"
echo "== 2. the rows"
sed 's/^/     /' "$W/got.tsv"
[ "$fail" = 0 ] && ok "every part armed after boot, reached its END and tracked its reference; $nfull of $(echo $PARTS | wc -w | tr -d ' ') frame-exact to the end (a skew row names the frame where a debug run left the reference)"
if [ -z "$MODE" ]; then
    v="$(verdict_part "$W/donovan_4_hot")"; set -- $v
    if [ "$2" -gt 0 ] && [ "${12}" = 1 ]; then vs_ctl_fired hot-block "the widened watch hits $2 times from f$4 and the debug run then differs from the reference ($v)"
    else vs_ctl_dead hot-block "the widened watch did not both hit and desync ($v)" || fail=1; fi
fi
echo "== 3. the frozen rows"
if [ "${FREEZE:-0}" = 1 ] && [ -z "$MODE" ]; then
    [ "$fail" = 0 ] || { echo "FAIL: not freezing a table whose checks failed"; exit 1; }
    { echo "# tests/expected/x2b7ef4_reach_m18.tsv — per Donovan/Pyron naming part on merged-m18: reads of the corrupted x2b7ef4"
      echo "# records (a -debug read watch on the corrupted bytes only, armed at frame $ARM), the first read's frame, and how many of"
      echo "# the part's three alignment dumps before it equal a non-debug run's (tests/audit_x2b7ef4_reach_m18.sh). Evidence class:"
      echo "# in-emulator, MAME. Frozen AS MEASURED with FREEZE=1. Columns: <part> hits <n> first <frame|-> aligned <k>/<k>; one build row."
      echo "#--"
      cat "$W/got.tsv"; } > "$EXPECT"
    echo "  FROZE $(basename "$EXPECT") — VERIFY by re-running without FREEZE"; exit 0
fi
[ -f "$EXPECT" ] || { echo "FAIL: no frozen expectation at $EXPECT (FREEZE=1 to create it)"; exit 1; }
grep -v '^#' "$EXPECT" > "$W/want.tsv"
if cmp -s "$W/want.tsv" "$W/got.tsv"; then ok "every row as frozen"
else bad "differs from the frozen rows"; diff "$W/want.tsv" "$W/got.tsv" | sed 's/^/        /'; fi
if [ "$fail" = 0 ]; then echo "PASS: audit_x2b7ef4_reach_m18"; else echo "FAIL: audit_x2b7ef4_reach_m18"; exit 1; fi
