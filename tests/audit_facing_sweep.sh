#!/bin/sh
# audit_facing_sweep.sh — THE VICTIM FACING RULE 5 AT 32 GEOMETRIES: Killshread Summon (ES)'s facing writes on native vs2 against the build under test, and which vsavj facing rule could reproduce native's value per anim node (GitHub #159, 14z-185).
#
# WHAT: #159 at more than one geometry. tests/audit_facing_rule.sh measures the Summon on the
#   donovan_3 rig as authored; this gate moves the players before the Summon so its six contacts
#   land on different anim nodes and on both sides of Demitri, and asks two things. (1) Does the
#   build under test write what native writes, write for write? (2) On native, could any vsavj
#   facing rule, given per anim node (a data-only fix: repoint a node's attack record), give
#   native's value at every contact of that node? Native's value is rule 5, the attacker's
#   x-velocity sign (vs2 PRG:0x1717E -> 0x171D6); vsavj's resolver (PRG:0x18854) has rules 0-4 and
#   the negative (position) rule only (docs/game/engine_internals.md, the attack record's +0xE).
# HOW: the donovan_3 rig (event 5, Killshread Summon (ES) at 3840), the level and RNG pinned as the
#   parity gates pin them, P1/P2 x poked over 3790-3800: side L = P1 0x1F3, P2 0x1F3+d; side R = P1
#   0x343, P2 0x343-d with the motion mirrored (D DL L -> D DR R); d = 0x60..0x150 step 0x10. Each
#   geometry runs on native vs2 and on the build (ours by the parity gate's cursor path D D DR DR),
#   to frame 4040, tests/lua/facing_tap.lua tapping Demitri's +0x5C word from 3850 with the rule
#   inputs at every write; tools/facing_sweep.py reads the 64 taps.
# EXPECTS: the reader's CHECK PASS and its rows equal tests/expected/facing_sweep.tsv. RE-FROZEN
#   AS FIXED on merged-m21 (14z-185, the M21 freeze applied the patch below): every leg SAME,
#   32/32, the leg and build5 rows moving and nothing else (native, geometry, node rows as frozen).
#   FROZEN AS MEASURED on merged-m20 until then: every leg DIFF — the #159 defect: the build5 rows show vsavj's
#   resolver XORing rule 5 into the prior value, 4 on side L (1^5) and 5 on side R (0^5), where
#   native writes 1/0, and on 4 side-R legs the later contacts landing on other frames (-);
#   and 13 of the 29 native nodes fit NO vsavj rule (no data-only fix). On probe 159 (the staged row, build/manifest/staged/159_designA.patch until M21,
#   in a copy of donovan.toml; its build fingerprint e4d712eb equals a build of the staged row
#   itself, 14z-185) every leg is SAME, 32/32; the M21 freeze applied the patch (the staged file
#   retired into build/manifest/donovan.toml's `facing_rule5` row) and re-froze the leg and build5 rows. Both controls fail the gate.
# FOLLOWS: build/manifest/ emu/mame-patches/ tests/expected/facing_sweep.tsv tests/lib/controls.sh
#   tests/lua/facing_tap.lua tests/replays/naming/ tools/build_fingerprint.py tools/facing_sweep.py
#   tools/name_moves.py tools/run_mame.sh tools/setup_mame.sh
#
# MUST-FIRE: perturbed-copy: flip — native's rule-5 values inverted before the node table must change the node rows and FAIL, so the node table is read from native's writes (in-gate: the reader with the plant must print different node rows; mode: the gate's own read carries the plant and FAILs)
# MUST-FIRE: perturbed-copy: perturb — the last write of the build's L_60 leg (and its build5 value on native's last rule-5 frame) XORed with 1 must change that leg's row and FAIL, so the leg rows compare the build's own writes (in-gate: the reader with the plant must print a different L_60 row; mode: the gate's own read carries the plant and FAILs)
#
# WHY. Measured 14z-185 (build/agent185/t159/, probe159/; rule-checker runs 2026-09-25-361..371):
# a data-only fix was the cheaper candidate, and one geometry could not refute it — on the rig as
# authored, a per-node layout of vsavj rules fits native's six values. Across these geometries the
# same move puts native's 1 and 0 on the same node where no vsavj rule gives both. The maintainer
# then ruled "Design A, stage for M21 (Recommended)" (DECISIONS_HISTORY.md "Ruled 2026-09-28
# (14z-185) — #159", the question and answer verbatim).
# The node rule inputs are computed from native's logged state at each contact, not executed on
# vsavj. On the 14z-185 probe's five geometries (two of them repeats of the other three: 3 distinct)
# ours' state equalled native's on every rule input at the 8 distinct same-frame, same-node contacts,
# all on the OUTGOING wave (the return-wave contacts land on other frames once ours' facing differs),
# and vsavj's negative rule, EXECUTED on ours, equalled the computed one on 18 distinct contacts.
#
# NOT COVERED (named, not tested): P2 standing only (no P2 movement or block); Donovan as P1 only;
#   the other four rule-5 records (0xCA1CA, 0xCA1EA, 0xD17C2, 0xD1822); a node STRUCTURE change as a
#   data fix; FBNeo and MiSTer. The pokes set a TARGET separation; where the players actually stood
#   is measured at each leg's first write (the geom rows, frozen, with the count of distinct
#   geometries) and checked equal on both legs (check (c)), not assumed; legs whose write sequences
#   coincide are still distinct geometries when their geom rows differ.
#
# Usage: ROMDIR=... [MAME_BIN=...] [BUILD=build/m3b_merged31] [JOBS=8] [FREEZE=1] [KEEP=<dir>] tests/audit_facing_sweep.sh
#   emulator tier, MAME; ~41 s (64 legs to frame 4040 at JOBS=8, measured 14z-185 on this MacBook)
set -eu
[ -n "${ROMDIR:-}" ] || { echo "FAIL: set ROMDIR"; exit 1; }
[ -d "$ROMDIR" ] && ROMDIR="$(cd "$ROMDIR" && pwd)"
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
MAME_BIN="${MAME_BIN:-$HOME/.cache/vampire-saved/mame/cps2}"; export MAME_BIN
BUILD="${BUILD:-build/m3b_merged31}"; case "$BUILD" in /*) ;; *) BUILD="$REPO/$BUILD" ;; esac
JOBS="${JOBS:-8}"
EXPECT="$REPO/tests/expected/facing_sweep.tsv"
R="$REPO/tests/replays/naming/donovan_3.rpl"; J="$REPO/tests/replays/naming/donovan_3.json"
FR=4040; FROM=3850
. "$REPO/tests/lib/controls.sh"
vs_ctl_mode "$0"
[ -x "$MAME_BIN" ] || { echo "SKIP: no MAME at $MAME_BIN"; exit 0; }
[ -f "$ROMDIR/vsav2.zip" ] || { echo "SKIP: no vsav2.zip in $ROMDIR"; exit 0; }
[ -f "$BUILD/rompath/vsavjw.zip" ] || { echo "SKIP: no WIDE build at $BUILD"; exit 0; }
if [ -n "${KEEP:-}" ]; then W="$KEEP"; mkdir -p "$W"; else W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT INT TERM; fi
fail=0
ok()  { printf '  ok    %s\n' "$1"; }
bad() { printf '  FAIL  %s\n' "$1"; fail=1; }

echo "== 1. rigs and legs (build $BUILD, program fingerprint $(python3 "$REPO/tools/build_fingerprint.py" "$BUILD/rompath" --set vsavjw --sha-only | cut -c1-8))"
awk -v path="D D DR DR" '/^1104-1106 p2=R$/ && !done { n = split(path, m, " "); t = 1100
    for (i = 1; i <= n; i++) { printf "%d-%d p1=%s\n", t, t + 2, m[i]; t += 60 }; done = 1 }
    /^(1100|1160|1220|1280)-[0-9]+ p1=/ { next } { print }' "$R" > "$W/ours.rpl"
for s in native ours; do
    src="$R"; [ "$s" = ours ] && src="$W/ours.rpl"
    sed -e 's/^3845-3849 p1=DL$/3845-3849 p1=DR/' -e 's/^3850-3858 p1=L$/3850-3858 p1=R/' "$src" > "$W/${s}_mirror.rpl"
    n="$(diff "$src" "$W/${s}_mirror.rpl" | command grep -c '^>' || true)"
    [ "$n" = 2 ] || { echo "FAIL: the mirrored $s rig changed $n lines, not the motion's 2"; exit 1; }
done
pk() { python3 -c "
import json,sys
p=json.load(open('$J'))['pokes']+[f'{2000}-{($FR)-1}:ff8116:06']+[f'{2363}-{($FR)-1}:ff80d4:0000']
for spec in sys.argv[1:]:
    a,v=spec.split('=')
    p+=[f'{3790}-{(3801)-1}:{a}:{v}']
print(';'.join(p))" "$@"; }
leg() {  # leg <name> <set> <rompath> <rpl> <x pokes...>
    _n="$1"; _s="$2"; _rp="$3"; _rpl="$4"; shift 4; _p="$(pk "$@")"; mkdir -p "$W/$_n"
    ( cd "$W/$_n" && MAME_SANDBOX="$W/$_n/sb" MAME_ROMPATH="$_rp" REPLAY="$_rpl" POKES="$_p" FRAMES=$FR \
        RTAP=ff885c,2 WINDOW="$FROM,$FR" TRACE_OUT="$W/w_$_n.txt" \
        "$REPO/tools/run_mame.sh" "$_s" -verbose -autoboot_script "$REPO/tests/lua/facing_tap.lua" > "$W/$_n/mame.log" 2>&1
      rm -rf "$W/$_n/sb" ) </dev/null &
}
i=0
for d in 60 70 80 90 a0 b0 c0 d0 e0 f0 100 110 120 130 140 150; do
    l="$(printf '%04x' $((0x1f3 + 0x$d)))"; r="$(printf '%04x' $((0x343 - 0x$d)))"
    leg "native_L_$d" vsav2  "$ROMDIR"                 "$R"                   ff8410=01f3 ff8810=$l
    leg "ours_L_$d"   vsavjw "$BUILD/rompath;$ROMDIR"  "$W/ours.rpl"          ff8410=01f3 ff8810=$l
    leg "native_R_$d" vsav2  "$ROMDIR"                 "$W/native_mirror.rpl" ff8410=0343 ff8810=$r
    leg "ours_R_$d"   vsavjw "$BUILD/rompath;$ROMDIR"  "$W/ours_mirror.rpl"   ff8410=0343 ff8810=$r
    i=$((i + 4)); if [ $((i % JOBS)) -lt 4 ]; then wait; fi
done
wait
n=0
for f in "$W"/w_*.txt; do
    command grep -q '^END' "$f" 2>/dev/null && n=$((n + 1)) || bad "$(basename "$f"): no END line"
done
for f in "$W"/ours_*/mame.log; do
    command grep -q 'load of vsavjw\.ini' "$f" || bad "$(dirname "$f" | xargs basename): the MAME log does not name the vsavjw set"
done
[ "$n" = 64 ] || bad "$n of 64 taps ended"
[ "$fail" = 0 ] || { echo "FAIL: audit_facing_sweep"; exit 1; }
ok "64 legs complete (32 geometries x native, build); the build legs ran the vsavjw set"

echo "== 2. the writes and the node table, read"
_plant=""; case "${VS_CTL:-}" in flip|perturb) _plant="--plant $VS_CTL" ;; esac
python3 tools/facing_sweep.py "$W" ${_plant} > "$W/read.txt" || true
command grep -v '^CHECK' "$W/read.txt" > "$W/got.tsv"
command grep -E '^(leg|build5|geometries-distinct|nodes-nofit)' "$W/got.tsv" | sed 's/^/  | /'
command grep -q '^CHECK PASS$' "$W/read.txt" && ok "every native leg has its rule-5 stores, each after its caller's write; every leg's first write on native's frame with the players where native's stood" \
    || { bad "the reader's checks:"; command grep '^CHECK FAIL' "$W/read.txt" | sed 's/^/        /'; }
if [ "${FREEZE:-0}" = 1 ]; then
    [ -z "${VS_CTL:-}" ] || { echo "REFUSED: FREEZE=1 in control mode"; exit 3; }
    [ "$fail" = 0 ] || { echo "REFUSED: FREEZE=1 on a failing check"; exit 3; }
    { sed -n '/^#/p' "$EXPECT" 2>/dev/null; cat "$W/got.tsv"; } > "$W/new.tsv"
    command grep -q '^#' "$W/new.tsv" || { echo "REFUSED: $EXPECT has no header to keep"; exit 3; }
    mv "$W/new.tsv" "$EXPECT"; echo "FROZEN: $EXPECT ($(command grep -vc '^#' "$EXPECT") rows) — VERIFY by re-running without FREEZE"; exit 0
fi
command grep -v '^#' "$EXPECT" > "$W/want.tsv"
if diff "$W/want.tsv" "$W/got.tsv" > "$W/diff.txt"; then ok "$(wc -l < "$W/got.tsv" | tr -d ' ') rows as frozen"
else bad "rows differ from $(basename "$EXPECT"):"; sed 's/^/        /' "$W/diff.txt" | head -30; fi

echo "== 3. must-fire controls"
if [ -n "$_plant" ]; then
    if [ "$fail" = 1 ]; then vs_ctl_fired "$VS_CTL" "the planted read fails the gate"; echo "FAIL: audit_facing_sweep (control mode)"; exit 1
    else vs_ctl_dead "$VS_CTL" "the planted read still passed" || true; echo "FAIL: audit_facing_sweep"; exit 1; fi
fi
python3 tools/facing_sweep.py "$W" --plant flip > "$W/ctl_flip.txt" || true
command grep '^node' "$W/got.tsv" > "$W/nodes_real.txt" || true
command grep '^node' "$W/ctl_flip.txt" > "$W/nodes_flip.txt" || true
if ! cmp -s "$W/nodes_real.txt" "$W/nodes_flip.txt"; then
    vs_ctl_fired flip "native's values inverted change the node rows ($(diff "$W/nodes_real.txt" "$W/nodes_flip.txt" | command grep -c '^>' || true) rows)"
else vs_ctl_dead flip "the node rows did not move with native's values" || fail=1; fi
python3 tools/facing_sweep.py "$W" --plant perturb > "$W/ctl_perturb.txt" || true
if [ "$(command grep "^leg	L_60	" "$W/got.tsv")" != "$(command grep "^leg	L_60	" "$W/ctl_perturb.txt")" ]; then
    vs_ctl_fired perturb "one build write XORed changes the L_60 row"
else vs_ctl_dead perturb "the L_60 row did not move with the build's write" || fail=1; fi

if [ "$fail" = 0 ]; then echo "PASS: audit_facing_sweep — Killshread Summon (ES) at 32 geometries: the build's facing writes and native's per-node rule fit, as frozen"
else echo "FAIL: audit_facing_sweep"; exit 1; fi
