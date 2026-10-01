#!/bin/sh
# audit_rng_draws.sh — THE ENGINE RNG'S DRAWS, BY CALLER: ours against native vs2 for the three tenants, and legacy content on ours against pristine vsavj (GitHub #176, 14z-185).
#
# WHAT: #176's question. The parity gates pin the RNG word every frame, so a port defect in how
#   the RNG ADVANCES would be reset away on both legs; this gate seeds the RNG once and lets it
#   run free, then compares the DRAWS. The facts it rests on (docs/game/engine_internals.md
#   "`0000` IS THE RNG'S FIXED POINT"): the routine (vsavj 0x014E8A, vs2 0x01357E, byte-identical)
#   is deterministic, so consecutive draws form a chain; the object loop draws once per pass on
#   both engines; vsavj's motion trackers arm their step timeout with a random draw where vs2's
#   write a constant 16, and the tenants' tracker calls run vsavj's trackers on ours — ruled host
#   behaviour, recorded, no ticket (maintainer, 2026-09-28: "Host behaviour, no ticket").
# HOW: tests/lua/rng_draws.lua reads every draw at the routine's first instruction with its caller
#   (the return address at USP; the game runs in user mode) and 48 longs of the active stack, on
#   MAME, frames 2600 to the rig's end, the RNG poked to 5a5a over 2363..2599 and then FREE, the
#   level pinned to 6 throughout. Legs: Lei-Lei vs Demitri (audit_air_gc_legacy's rig, real picks)
#   on pristine vsavj and on ours; each tenant's audit_chains174 rig on native vs2 and on ours.
#   tools/rng_draws.py reads them: (a) legacy ours equals pristine vsavj draw for draw; (b) a draw
#   whose stack holds a return address into the tenant's code is keyed by the innermost one (ours
#   mapped to native by the placement map), and a key on both legs counts alike; (c) the object
#   loop counts alike; (e) every leg's draws form an unbroken generator chain, so none was missed;
#   (f) legacy ours has no tenant frame; (g) each tenant's tracker-call block — declared, and
#   verified against the vs2 image as jsr's into vs2's motion helpers — is on the stack of no
#   native draw and of some ours draw.
# EXPECTS: the reader's CHECK PASS; its rows equal tests/expected/rng_draws.tsv (the one-leg keys
#   and their counts are FROZEN there: the tenants' tracker blocks on ours, vs2 engine code the
#   port copied on native); all five controls fail.
# FOLLOWS: build/manifest/ emu/mame-patches/ tests/expected/rng_draws.tsv tests/lib/controls.sh
#   tests/lib/decrypt_cache.sh tests/lua/rng_draws.lua tests/replays/chains174/ tools/rng_draws.py
#   tools/run_mame.sh tools/select_paths.py tools/select_wheel.py tools/setup_mame.sh
#
# MUST-FIRE: perturbed-copy: relabel — the legacy ours taps with ONE draw's caller changed must FAIL check (a), so "legacy ours equals vsavj draw for draw" compares callers, not only counts (in-gate: the reader run with the plant must report (a); mode: the gate's own read carries the plant and the gate FAILs)
# MUST-FIRE: perturbed-copy: drop — one huitzil ours draw removed from its tap must FAIL check (e), so the chain proves no draw was missed (in-gate: the reader with the plant must report (e); mode: the gate's own read carries the plant and FAILs)
# MUST-FIRE: perturbed-copy: map — the ours-to-native placement map shifted by 2 must FAIL (the tracker blocks vanish from ours' stacks, and the key rows move off the frozen table), so the keys rest on the map (in-gate: the reader with the plant must report (g); mode: FAILs)
# MUST-FIRE: perturbed-copy: strip — ours' first draw of a key native also has, dropped, must FAIL check (b), so a key on both legs is compared by count (in-gate: the reader with the plant must report (b); mode: FAILs)
# MUST-FIRE: perturbed-copy: block — the huitzil block's first address placed on one native draw's stack must FAIL check (g), so the native zero is read by a scan that sees the block (in-gate: the reader with the plant must report (g); mode: FAILs)
#
# NOT COVERED (named, not tested): seeds other than 5a5a and seed frames other than 2600; P2; the
#   naming corpus and other rigs; turbo speed; FBNeo and MiSTer; a call made by a jmp or a pushed
#   return (the key's call check does not see it; the block scan is raw); stack deeper than 48
#   longs; what the tracker timeout does to a player's inputs (the seesaawiki cross-check is in
#   engine_internals.md). The parity gates' 0000 pin, the RNG's fixed point, is #183.
#
# Usage: ROMDIR=... [MAME_BIN=...] [BUILD=build/m3b_merged29] [DON=build/don_m25 HUI=build/hui59 PYR=build/pyron44] [FREEZE=1] [KEEP=<dir>] tests/audit_rng_draws.sh
#   emulator tier, MAME; ~1 min (8 legs in parallel)
set -eu
[ -n "${ROMDIR:-}" ] || { echo "FAIL: set ROMDIR"; exit 1; }
[ -d "$ROMDIR" ] && ROMDIR="$(cd "$ROMDIR" && pwd)"
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
MAME_BIN="${MAME_BIN:-$HOME/.cache/vampire-saved/mame/cps2}"; export MAME_BIN
BUILD="${BUILD:-build/m3b_merged29}"; case "$BUILD" in /*) ;; *) BUILD="$REPO/$BUILD" ;; esac
DON="${DON:-build/don_m25}"; HUI="${HUI:-build/hui59}"; PYR="${PYR:-build/pyron44}"
EXPECT="$REPO/tests/expected/rng_draws.tsv"
RIGS="$REPO/tests/replays/chains174"
TENANTS="huitzil donovan pyron"
. "$REPO/tests/lib/controls.sh"
vs_ctl_mode "$0"
[ -x "$MAME_BIN" ] || { echo "SKIP: no MAME at $MAME_BIN"; exit 0; }
[ -f "$ROMDIR/vsav2.zip" ] || { echo "SKIP: no vsav2.zip in $ROMDIR"; exit 0; }
[ -f "$BUILD/rompath/vsavjw.zip" ] || { echo "SKIP: no WIDE build at $BUILD"; exit 0; }
[ -f "$BUILD/patch/placements.json" ] || { echo "SKIP: no placements.json at $BUILD"; exit 0; }
[ -f "$BUILD/verify_op.bin" ] || { echo "SKIP: no verify_op.bin (the program image) at $BUILD"; exit 0; }
for x in "$HUI" "$DON" "$PYR"; do [ -f "$x/extract/regions.json" ] || { echo "SKIP: no $x/extract/regions.json"; exit 0; }; done
if [ -n "${KEEP:-}" ]; then W="$KEEP"; mkdir -p "$W"; else W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT INT TERM; fi
fail=0
ok()  { printf '  ok    %s\n' "$1"; }
bad() { printf '  FAIL  %s\n' "$1"; fail=1; }
SEED=5a5a; S=2600

echo "== 1. rigs, views and legs"
. "$REPO/tests/lib/decrypt_cache.sh"
decrypt_view vsav2 "$W/v2_op.bin" "$W/v2_da.bin" || { echo "FAIL: vsav2 views not delivered"; exit 1; }
decrypt_view vsavj "$W/vj_op.bin" "$W/vj_da.bin" || { echo "FAIL: vsavj views not delivered"; exit 1; }
python3 "$REPO/tools/select_wheel.py" "$W/vj_da.bin" --set vsavj --json "$W/wheel_vsavj.json" > "$W/wheel.log" 2>&1 \
    || { echo "FAIL: vsavj wheel: $(tail -1 "$W/wheel.log")"; exit 1; }
# the Lei-Lei legacy rig: audit_air_gc_legacy's rig() for Lei-Lei (0x0d vs Demitri), byte for byte
{
    printf '300-305 sys=C1\n420-425 sys=C2\n800-803 sys=S1\n940-943 sys=S2\n'
    python3 "$REPO/tools/select_paths.py" "$W/wheel_vsavj.json" --rpl-prologue 0x0d 0x01
    t=2800; printf '%d-%d p1=R\n' $((t-190)) $((t-40))
    printf '%d-%d p2=3\n%d-%d p1=L\n%d-%d p1=R\n%d-%d p1=D\n%d-%d p1=DR1\n' $t $((t+3)) $((t-4)) $((t+11)) $((t+12)) $((t+13)) $((t+14)) $((t+15)) $((t+16)) $((t+19))
    for spec in "3220 2 10 22" "3640 6 14 26"; do
        set -- $spec; t=$1; a=$2; h=$3; g=$4
        printf '%d-%d p1=R\n' $((t-190)) $((t-40))
        printf '%d-%d p2=UL\n%d-%d p2=3\n%d-%d p1=U\n%d-%d p1=L\n%d-%d p1=R\n%d-%d p1=D\n%d-%d p1=DR1\n' $t $((t+2)) $((t+h)) $((t+h+3)) $((t+a)) $((t+a+2)) $((t+a+3)) $((t+g-1)) $((t+g)) $((t+g+1)) $((t+g+2)) $((t+g+3)) $((t+g+4)) $((t+g+7))
    done
    printf '4300 wait\n'
} > "$W/leilei.rpl"
lfr=4200
lpk="$(python3 -c "
p=[f'{2000}-{($lfr)-1}:ff8116:06']+[f'{2363}-{($S)-1}:ff80d4:$SEED']
for t in (2800,3220,3640): p+=[f'{t-230}:ff8410:0228', f'{t-230}:ff8810:02d8']
print(';'.join(p))")"
leg() {  # leg <name> <set> <rompath> <rpl> <pokes> <frames> <rng pc>
    mkdir -p "$W/$1"
    ( cd "$W/$1" && MAME_SANDBOX="$W/$1/sb" MAME_ROMPATH="$3" REPLAY="$4" POKES="$5" FRAMES="$6" \
        RSTACKN=48 RTAP=ff80d4,2 RPCS="$7" WINDOW="$S,$6" TRACE_OUT="$W/rt_$1.txt" \
        "$REPO/tools/run_mame.sh" "$2" -verbose -autoboot_script "$REPO/tests/lua/rng_draws.lua" > "$W/$1/mame.log" 2>&1
      rm -rf "$W/$1/sb" ) </dev/null &
}
leg leilei_vsavj vsavj  "$ROMDIR"             "$W/leilei.rpl" "$lpk" $lfr 14e8a
leg leilei_ours  vsavjw "$BUILD/rompath;$ROMDIR" "$W/leilei.rpl" "$lpk" $lfr 14e8a
for t in $TENANTS; do
    case $t in donovan) p="D D DR DR" ;; huitzil) p="D D D" ;; pyron) p="D D D D" ;; esac
    fr="$(python3 -c "import json;print(json.load(open('$RIGS/${t}_c174.json'))['frames'])")"
    pk="$(python3 -c "
import json
p=json.load(open('$RIGS/${t}_c174.json'))['pokes']+[f'{2000}-{($fr)-1}:ff8116:06']+[f'{2363}-{($S)-1}:ff80d4:$SEED']
print(';'.join(p))")"
    awk -v p="$p" '/^1104-1106 p2=R$/ && !done { n = split(p, m, " "); t = 1100
        for (i = 1; i <= n; i++) { printf "%d-%d p1=%s\n", t, t + 2, m[i]; t += 60 }; done = 1 }
        /^(1100|1160|1220|1280)-[0-9]+ p1=/ { next } { print }' "$RIGS/${t}_c174.rpl" > "$W/$t.ours.rpl"
    leg "${t}_native" vsav2  "$ROMDIR"             "$RIGS/${t}_c174.rpl" "$pk" "$fr" 1357e
    leg "${t}_ours"   vsavjw "$BUILD/rompath;$ROMDIR" "$W/$t.ours.rpl"     "$pk" "$fr" 14e8a
done
wait
for l in leilei_vsavj leilei_ours huitzil_native huitzil_ours donovan_native donovan_ours pyron_native pyron_ours; do
    command grep -q '^END' "$W/rt_$l.txt" 2>/dev/null || bad "$l: the tap has no END line (see $W/$l/mame.log)"
done
for l in leilei_ours huitzil_ours donovan_ours pyron_ours; do
    command grep -q 'load of vsavjw\.ini' "$W/$l/mame.log" || bad "$l: the MAME log does not name the vsavjw set"
done
[ "$fail" = 0 ] || { echo "FAIL: audit_rng_draws"; exit 1; }
ok "8 legs complete; the ours legs ran the vsavjw set"

echo "== 2. the draws, read"
ARGS="$W $BUILD/patch/placements.json $W/v2_op.bin $BUILD/verify_op.bin $HUI/extract $DON/extract $PYR/extract"
_plant=""; case "${VS_CTL:-}" in relabel|drop|map|strip|block) _plant="--plant $VS_CTL" ;; esac
python3 tools/rng_draws.py ${ARGS} ${_plant} > "$W/read.txt" || true
command grep -v '^#' "$W/read.txt" | command grep -v '^CHECK' | sed 's/^/  | /'
command grep -q '^CHECK PASS$' "$W/read.txt" && ok "every structural check (a) (b) (c) (e) (f) (g)" \
    || { bad "the reader's checks:"; command grep '^CHECK FAIL' "$W/read.txt" | sed 's/^/        /'; }
command grep -v '^#' "$W/read.txt" | command grep -v '^CHECK' > "$W/got.tsv"
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
    if [ "$fail" = 1 ]; then vs_ctl_fired "$VS_CTL" "the planted read fails the gate"; echo "FAIL: audit_rng_draws (control mode)"; exit 1
    else vs_ctl_dead "$VS_CTL" "the planted read still passed" || true; echo "FAIL: audit_rng_draws"; exit 1; fi
fi
for c in relabel:"(a)" drop:"(e)" map:"(g)" strip:"(b)" block:"(g)"; do
    n="${c%%:*}"; want="${c#*:}"
    python3 tools/rng_draws.py ${ARGS} --plant "$n" > "$W/ctl_$n.txt" && rc=0 || rc=$?
    if [ "$rc" = 1 ] && command grep -qF "CHECK FAIL	$want" "$W/ctl_$n.txt"; then
        vs_ctl_fired "$n" "the reader, planted, reports $(command grep -F "CHECK FAIL	$want" "$W/ctl_$n.txt" | head -1 | cut -f2 | cut -c1-90)"
    else vs_ctl_dead "$n" "the reader, planted, exited $rc without a $want failure" || fail=1; fi
done

if [ "$fail" = 0 ]; then echo "PASS: audit_rng_draws — the RNG's draws by caller: legacy ours as vsavj, the tenants' ported code as native, the rest attributed and frozen"
else echo "FAIL: audit_rng_draws"; exit 1; fi
