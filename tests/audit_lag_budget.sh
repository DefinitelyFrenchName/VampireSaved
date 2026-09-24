#!/bin/sh
# audit_lag_budget.sh — A FIX SET ADDS NO FRAME OF LAG: over every #136 naming part (the three tenants' moves, and legacy attackers against each tenant), the build under test has no zero-pass frame that the reference build — the one before the fixes — does not have (14z-170; the maintainer's condition on the #136 fixes: "the total overhead cost of our combined changes is less than 1/60s at all times").
#
# WHAT: a fix set adds no frame of lag: over every #136 naming part, the build under test
#   has no zero-pass frame (the pass counter $FF8081 not advancing after the round start)
#   that the reference build before the fixes does not have — the maintainer's
#   combined-overhead condition, under 1/60 s at all times.
# HOW: 84 field-trace runs on MAME (42 parts on BOTH builds, the same replays and pokes, the
#   tenant parts through the merged wheel's path, level and RNG pinned), the build's
#   zero-pass frame set checked as a subset of the reference's; a leg that does not complete
#   is VOID and fails; the control removes one frame's pass advance from a build trace.
# EXPECTS: no new zero-pass frame on any part; the planted frame is caught. NOT covered:
#   content outside the naming corpus and the idle-time margin short of a lost pass.
#
# MUST-FIRE: perturbed-copy: lag-planted — a copy of each part's trace on the build under test with the midpoint frame's whole pass-counter advance removed (a zero-pass frame planted where the reference has none) must FAIL the subset check, so "no new zero-pass frame" is read from the build's own pass counter (in-gate: the planted copy of the first part must be caught; mode: every part's build trace is planted before the check and the gate FAILs)
#
# WHY. The maintainer, of the 2026-09-18 fix rulings (DECISIONS_HISTORY.md, the defense-row entry):
# "when I say no frame cost I don't mean " no cost at all", I mean "a total cost that doesn't end up
# introducing a new frame of lag (i.e. the total overhead cost of our combined changes is less than
# 1/60s at all times)" — measurable as NO new zero-pass frame (the pass counter RAM:$FF8081, the
# definition of tests/audit_pass_overrun.sh: a frame after 2546 on which it does not advance)
# anywhere in the corpus with the fixes combined, against the build before them.
# tests/audit_pass_overrun.sh freezes the three Blizzard Sword overruns against NATIVE; this gate is
# the corpus-wide A/B of two of OUR builds, live, with no frozen numbers.
#
# THE RIG: every committed naming part (tests/replays/naming/, 42 at 14z-170), each run on BOTH builds
# with the SAME replay and pokes — the tenant parts through the merged wheel's real cursor path (the
# parity gate's OURS_PATH), the victim parts as authored (their P2 poke) — to the part's last frame,
# with the speed level and the RNG pinned as the parity gate pins them. Both legs are our builds with
# the same wheel, so the rig selects the same characters on both. A leg that does not complete is VOID
# and fails the gate (an emulator that crashed is not evidence).
#
# NOT COVERED: frames outside the naming corpus (the legacy suite, the recordings — the freeze
# battery's oracles cover legacy content); the idle-time margin short of a zero-pass frame (a slower
# frame that still completes a pass is not lag by this definition); FBNeo and the MiSTer core.
#
# Usage: ROMDIR=... [MAME_BIN=...] [BUILD=build/m3b_merged27] [REF=build/m3b_merged26] [JOBS=6] [PARTS="donovan_1 pyron_2"] tests/audit_lag_budget.sh
#   emulator tier, MAME; 84 field-trace runs — measured 14z-170 on this MacBook at JOBS=6: see ci_emulator.tsv
set -eu
[ -n "${ROMDIR:-}" ] || { echo "FAIL: set ROMDIR"; exit 1; }
[ -d "$ROMDIR" ] && ROMDIR="$(cd "$ROMDIR" && pwd)"
REPO="$(cd "$(dirname "$0")/.." && pwd)"
MAME_BIN="${MAME_BIN:-$HOME/.cache/vampire-saved/mame/cps2}"; export MAME_BIN
BUILD="${BUILD:-build/m3b_merged27}"
REF="${REF:-build/m3b_merged26}"
case "$BUILD" in /*) ;; *) BUILD="$REPO/$BUILD" ;; esac
case "$REF" in /*) ;; *) REF="$REPO/$REF" ;; esac
JOBS="${JOBS:-6}"
[ -x "$MAME_BIN" ] || { echo "SKIP: no MAME at $MAME_BIN"; exit 0; }
[ -f "$BUILD/rompath/vsavjw.zip" ] || { echo "SKIP: no WIDE build at $BUILD"; exit 0; }
[ -f "$REF/rompath/vsavjw.zip" ] || { echo "SKIP: no reference build at $REF"; exit 0; }
. "$REPO/tests/lib/controls.sh"; vs_ctl_mode "$0"; MODE="${VS_CTL:-}"
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT INT TERM
fail=0
ok()  { printf '  ok    %s\n' "$1"; }
bad() { printf '  FAIL  %s\n' "$1"; fail=1; }
FP_B="$(python3 "$REPO/tools/build_fingerprint.py" "$BUILD/rompath" --set vsavjw --sha-only | cut -c1-8)"
FP_R="$(python3 "$REPO/tools/build_fingerprint.py" "$REF/rompath" --set vsavjw --sha-only | cut -c1-8)"
echo "== build under test: $BUILD $FP_B; reference: $REF $FP_R"
[ "$FP_B" != "$FP_R" ] || { echo "FAIL: the build under test and the reference are the same build ($FP_B) — the comparison would be vacuous"; exit 1; }
if [ -z "${PARTS:-}" ]; then
    PARTS="$(ls "$REPO/tests/replays/naming/" | sed -n 's/\.rpl$//p' | sort)"
fi
OURS_PATH_donovan="D D DR DR"; OURS_PATH_huitzil="D D D"; OURS_PATH_pyron="D D D D"
# ONE run function; the leg is only which build it boots
run() {  # run <part> <leg: build|ref>
    _p="$1"; _l="$2"; _d="$W/$_p.$_l"; mkdir -p "$_d"
    case "$_l" in build) _rp="$BUILD/rompath;$ROMDIR" ;; ref) _rp="$REF/rompath;$ROMDIR" ;; esac
    _j="$REPO/tests/replays/naming/$_p.json"; _r="$REPO/tests/replays/naming/$_p.rpl"
    _last="$(awk -F'[- ]' '/^[0-9]/{print $1}' "$_r" | sort -n | tail -1)"; _fr=$((_last + 60))
    _t="${_p%%_*}"; _path=""
    case "$_p" in *_victim_*) ;; *) eval "_path=\$OURS_PATH_$_t" ;; esac
    if [ -n "$_path" ]; then
        awk -v path="$_path" '/^1104-1106 p2=R$/ && !done { n = split(path, m, " "); t = 1100
            for (i = 1; i <= n; i++) { printf "%d-%d p1=%s\n", t, t + 2, m[i]; t += 60 }; done = 1 }
            /^(1100|1160|1220|1280)-[0-9]+ p1=/ { next } { print }' "$_r" > "$_d/r.rpl"
    else cp "$_r" "$_d/r.rpl"; fi
    _b="$(python3 -c "import json;print(';'.join(json.load(open('$_j'))['pokes']))")"
    _lv="$(python3 -c "print(';'.join(f'{f}:ff8116:06' for f in range(2000,$_fr)))")"
    _rn="$(python3 -c "print(';'.join(f'{f}:ff80d4:0000' for f in range(2363,$_fr)))")"
    ( set +e; cd "$_d" && MAME_SANDBOX="$_d/sb" MAME_ROMPATH="$_rp" REPLAY="$_d/r.rpl" POKES="$_b;$_lv;$_rn" \
        FIELDS="ff8081:b:pc" FIELD_OUT="$_d/f.ft" FIELD_FROM=2540 FIELD_TO="$_fr" FRAMES="$_fr" \
        "$REPO/tools/run_mame.sh" vsavjw -autoboot_script "$REPO/tests/lua/field_trace.lua" > "$_d/mame.log" 2>&1
      _st=$?; grep -q -E '^(FIELDSUMMARY|END )' "$_d/f.ft" 2>/dev/null && _st=0; echo $_st > "$_d/rc"; rm -rf "$_d/sb" ) </dev/null
}
echo "== 1. the runs ($(echo $PARTS | wc -w | tr -d ' ') parts x 2 builds, $JOBS at a time)"
n=0
for p in $PARTS; do for l in build ref; do
    run "$p" "$l" &
    n=$((n + 1)); [ $((n % JOBS)) = 0 ] && wait
done; done
wait
for p in $PARTS; do for l in build ref; do
    _rc="$(cat "$W/$p.$l/rc" 2>/dev/null || echo none)"
    [ "$_rc" = 0 ] && [ -s "$W/$p.$l/f.ft" ] || bad "$p $l: the run did not complete (exit $_rc) — VOID"
done; done
[ "$fail" = 0 ] || { echo "FAIL: audit_lag_budget"; exit 1; }
plant() {  # plant <trace in> <trace out>: THE PERTURBATION — the midpoint frame's whole pass-counter advance removed
    # (at the pinned speed level the counter usually moves 2 a frame, so "one step" would leave a delta of 1):
    # every value from the midpoint on is lowered by that frame's own delta, so the midpoint completes no pass
    awk 'function pcv(   i) { for (i = 3; i <= NF; i++) if ($i ~ /^pc=/) return substr($i, 4) + 0; return -1 }
         NR==FNR { if ($1=="F") { f[FNR] = $2; v[$2] = pcv(); last = $2; if (!first) first = $2 } next }
         FNR==1 { mid = int((first + last) / 2); while (!(mid in v) || !((mid - 1) in v)) mid++; d = (v[mid] - v[mid - 1] + 256) % 256 }
         $1=="F" && $2 >= mid { for (i = 3; i <= NF; i++) if ($i ~ /^pc=/) { x = (substr($i, 4) - d + 256) % 256; $i = "pc=" x } }
         { print }' "$1" "$1" > "$2"
}
if [ "$MODE" = lag-planted ]; then for p in $PARTS; do plant "$W/$p.build/f.ft" "$W/pl.ft" && mv "$W/pl.ft" "$W/$p.build/f.ft"; done; fi
zero() {  # zero <trace>: the zero-pass frames after 2546 (tests/audit_pass_overrun.sh's definition)
    python3 - "$1" <<'PY'
import sys
d = {}
for l in open(sys.argv[1]):
    t = l.split()
    if t and t[0] == "F": d[int(t[1])] = dict(kv.split("=", 1) for kv in t[2:])
z = [f for f in sorted(d) if f > 2546 and f - 1 in d and (int(d[f]["pc"]) - int(d[f - 1]["pc"])) % 256 == 0]
print(" ".join(map(str, z)))
PY
}
echo "== 2. the zero-pass frames, part by part"
new_total=0; zb_total=0; zr_total=0
for p in $PARTS; do
    zb="$(zero "$W/$p.build/f.ft")"; zr="$(zero "$W/$p.ref/f.ft")"
    newz="$(python3 -c "import sys; b=set(sys.argv[1].split()); r=set(sys.argv[2].split()); print(' '.join(sorted(b-r, key=int)))" "$zb" "$zr")"
    nb=$(echo $zb | wc -w | tr -d ' '); nr=$(echo $zr | wc -w | tr -d ' ')
    zb_total=$((zb_total + nb)); zr_total=$((zr_total + nr))
    if [ -n "$newz" ]; then bad "$p: NEW zero-pass frame(s) on the build under test: $newz (build $nb, reference $nr)"; new_total=$((new_total + 1))
    else printf '  %-18s zero-pass frames: build %s, reference %s — none new\n' "$p" "$nb" "$nr"; fi
done
[ "$new_total" = 0 ] && ok "no part has a zero-pass frame the reference lacks ($zb_total on the build, $zr_total on the reference, over $(echo $PARTS | wc -w | tr -d ' ') parts)"
if [ "$MODE" != lag-planted ]; then
    first="$(echo $PARTS | awk '{print $1}')"
    plant "$W/$first.build/f.ft" "$W/ctl.ft"
    zc="$(zero "$W/ctl.ft")"; zr="$(zero "$W/$first.ref/f.ft")"
    newc="$(python3 -c "import sys; b=set(sys.argv[1].split()); r=set(sys.argv[2].split()); print(len(b-r))" "$zc" "$zr")"
    if [ "$newc" -gt 0 ]; then echo "CONTROL FIRED: lag-planted — a zero-pass frame planted in $first's build trace is caught ($newc new)"
    else echo "CONTROL DEAD: lag-planted — the planted zero-pass frame was not caught"; fail=1; fi
fi
if [ "$fail" = 0 ]; then echo "PASS: audit_lag_budget"; else echo "FAIL: audit_lag_budget"; exit 1; fi
