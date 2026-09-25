#!/bin/sh
# audit_hitbox_parity.sh — THE HITBOXES IN PLAY, ours vs native (14z-181, GitHub #136): on every frame where a tenant's naming rig has both legs on the SAME node, the seven resolved hitbox pointers and the node's box-id word are equal — the resolution per node is identical, so the boxes the engine tests are the ported copy's rows of the same tables.
#
# WHAT: whether the hitboxes a tenant's moves put in play are the same on our build as on native
#   vs2: per frame of the parity gate's default parts (donovan_1, pyron_4, huitzil_1), where both
#   legs are on the same node (translated), the five resolved table pointers +0x80..+0x90 (three
#   vuln, push, attack), the hitbox base +0x60 and family table +0x64 (translated out of the
#   build's placements) and the node's box-id word +0x94 — frozen per part and field.
# HOW: both legs on MAME as tests/audit_move_parity.sh runs them (real cursor picks, the level
#   pinned at 6 and the RNG at 0000, the rig's own pokes), field_trace sampling the fighter block's
#   pointer fields; tools/hitbox_parity.py translates our pointers through every placed region of
#   the tenant and compares on the node-equal frames only (a frame whose nodes differ is the
#   parity gate's DIFF, attributed there); three controls.
# EXPECTS: SAME on every pointer and the box-id word of every part, the node-equal frame count
#   at or above its floor, the three controls failing. Not covered: frames whose nodes differ,
#   P2's boxes (Demitri's hitbox families differ between the games — same_data_p2.tsv), and the
#   table BYTES themselves (the charmap gates' subject).
# FOLLOWS: build/manifest/ emu/mame-patches/ tests/expected/hitbox_parity.tsv
#   tests/lua/field_trace.lua tests/replays/naming/ tools/hitbox_parity.py tools/name_moves.py
#   tools/select_paths.py tools/select_wheel.py tools/run_mame.sh tools/setup_mame.sh
#   tests/lib/controls.sh tests/lib/decrypt_cache.sh tests/lib/measures.sh
#
# MUST-FIRE: perturbed-copy: no-translation — our leg compared WITHOUT the placements translation (raw pointers) must read every pointer DIFFER, so the translation is proven load-bearing and the SAME rows are not two legs agreeing on untranslated numbers (in-gate: the raw compare of the first part must differ; mode: every part is compared raw and the gate FAILs)
# MUST-FIRE: perturbed-copy: pointer-planted — our first part's trace with one node-equal frame's attack-table pointer moved by 0x20 must read that field DIFFER, so a pointer that resolves differently on one frame is seen (in-gate: the planted copy must differ from the real rows; mode: the plant is applied and the table FAILs)
# MUST-FIRE: perturbed-copy: ids-planted — our first part's trace with one frame's box-id word altered (the attack id +1) must read `boxes` DIFFER, so the box-id comparison is live (in-gate: the planted copy must differ; mode: the plant is applied and the table FAILs)
# MEASURES: hitbox-node-equal-frames — 14890 the node-equal frames compared over the three parts, summed (14890 measured at the 14z-181 freeze: donovan_1 4331 of 4331, pyron_4 3928 of 4691, huitzil_1 6631 of 6631); a shrunken set is what this floor refuses
#
# WHY. #136's 14z-159 record said "hitboxes EXACT over 3,021 frames" and 14z-164 found no gate,
# log or file behind the sentence. On this engine (tests/test_hitbox_encoding.sh, 14z-120 (5)) the
# boxes the engine tests on a frame are rows of the five tables the fighter block resolves at
# +0x80..+0x90, selected by the node's box ids at +0x94 — so "the hitboxes in play" IS "the same
# node resolves the same pointers and ids", and the table bytes are the charmap gates' question.
#
# Usage: ROMDIR=... [MAME_BIN=...] [BUILD=build/m3b_merged27] [PARTS="donovan_1 pyron_4 huitzil_1"] [FREEZE=1] [CONTROL=<name>] tests/audit_hitbox_parity.sh
#   emulator tier, MAME: six legs in parallel, ~2 min.
set -u
REPO="$(cd "$(dirname "$0")/.." && pwd)"; cd "$REPO"
ROMDIR="${ROMDIR:?set ROMDIR}"; if [ -d "$ROMDIR" ]; then ROMDIR="$(cd "$ROMDIR" && pwd)"; fi
MAME_BIN="${MAME_BIN:-$HOME/.cache/vampire-saved/mame/cps2}"; export MAME_BIN
BUILD="${BUILD:-build/m3b_merged27}"; case "$BUILD" in /*) ;; *) BUILD="$REPO/$BUILD" ;; esac
PARTS="${PARTS:-donovan_1 pyron_4 huitzil_1}"
EXPECT="$REPO/tests/expected/hitbox_parity.tsv"
. "$REPO/tests/lib/controls.sh"; vs_ctl_mode "$0"
. "$REPO/tests/lib/measures.sh"
. "$REPO/tests/lib/decrypt_cache.sh"
[ -x "$MAME_BIN" ] || { echo "SKIP: no MAME at $MAME_BIN"; exit 0; }
[ -f "$ROMDIR/vsav2.zip" ] || { echo "SKIP: no vsav2.zip in $ROMDIR"; exit 0; }
[ -f "$BUILD/rompath/vsavjw.zip" ] || { echo "SKIP: no WIDE build at $BUILD"; exit 0; }
[ -f "$BUILD/patch/placements.json" ] || { echo "SKIP: no placements.json at $BUILD"; exit 0; }
[ -f "$BUILD/verify_data.bin" ] || { echo "SKIP: no verify_data.bin at $BUILD"; exit 0; }
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT INT TERM
fail=0; ok() { printf '  ok    %s\n' "$1"; }; bad() { printf '  FAIL  %s\n' "$1"; fail=1; }
HP="python3 $REPO/tools/hitbox_parity.py"
FIELDS="ff841c:l:node,ff8480:l:t0,ff8484:l:t1,ff8488:l:t2,ff848c:l:t3,ff8490:l:t4,ff8460:l:hbase,ff8464:l:hcomp,ff8494:l:boxes,ff8782:b:id,ff8b82:b:p2id"
FIRST="${PARTS%% *}"

echo "== 0. the two select wheels and the real routes (P1 the tenant from cell 0x01, P2 Demitri from 0x05)"
decrypt_view vsav2 "$W/v2_op.bin" "$W/v2_da.bin" || { echo "FAIL: no vsav2 decrypt view"; exit 1; }
python3 tools/select_wheel.py "$W/v2_da.bin" --set vsav2 --json "$W/wheel_native.json" > "$W/w1.log" 2>&1 || { echo "FAIL: vsav2 wheel"; exit 1; }
python3 tools/select_wheel.py "$BUILD/verify_data.bin" --set vsavj --json "$W/wheel_ours.json" > "$W/w2.log" 2>&1 || { echo "FAIL: our wheel"; exit 1; }
route() { python3 tools/select_paths.py "$W/wheel_$1.json" --cell "$3" --player "$2" | sed 's/^.*: //'; }
leg_rpl() {  # leg_rpl <rig.rpl> <p1 moves> <p2 moves> <out>
    python3 - "$1" "$2" "$3" "$4" <<'PY' || return 1
import sys
sys.path.insert(0, "tools")
import name_moves as nm
src = open(sys.argv[1]).read()
# the naming rigs carry the tenant's NATIVE route already (prologue(tenant)); replace the whole prologue
tenant = sys.argv[1].split("/")[-1].rsplit("_", 1)[0]
old = nm.prologue(tenant)
assert src.count(old) == 1, "the committed rig does not carry its own prologue verbatim"
open(sys.argv[4], "w").write(src.replace(old, nm.prologue_for(sys.argv[2].split(), sys.argv[3].split())))
PY
}
echo "== 1. the legs (as audit_move_parity: the rig's pokes, level 6, RNG 0000)"
for part in $PARTS; do
    t="${part%_*}"; p="${part##*_}"
    case $t in donovan) ID=13;; huitzil) ID=10;; pyron) ID=11;; esac
    J="tests/replays/naming/${part}.json"; R="tests/replays/naming/${part}.rpl"
    [ -f "$J" ] && [ -f "$R" ] || { bad "no committed rig $part"; continue; }
    FR="$(python3 -c "import json;print(json.load(open('$J'))['frames'])")"
    PK="$(python3 -c "import json;j=json.load(open('$J'));fr=j['frames'];print(';'.join(j['pokes']+[f'{f}:ff8116:06' for f in range(2000,fr)]+[f'{f}:ff80d4:0000' for f in range(2363,fr)]))")"
    for leg in native ours; do
        P1="$(route $leg 1 "$ID")"; P2="$(route $leg 2 01)"
        [ -n "$P1" ] && [ -n "$P2" ] || { bad "$part $leg: no route"; continue; }
        leg_rpl "$R" "$P1" "$P2" "$W/$part.$leg.rpl" || bad "$part $leg rpl"
        if [ $leg = native ]; then set_=vsav2; rp="$ROMDIR"; else set_=vsavjw; rp="$BUILD/rompath;$ROMDIR"; fi
        d="$W/$part.$leg"; mkdir -p "$d"
        ( set +e; cd "$d" && MAME_SANDBOX="$d/sb" MAME_ROMPATH="$rp" REPLAY="$W/$part.$leg.rpl" POKES="$PK" FIELDS="$FIELDS" FIELD_OUT="$W/$part.$leg.ft" \
            FIELD_FROM=2300 FIELD_TO="$FR" FRAMES="$FR" "$REPO/tools/run_mame.sh" "$set_" -autoboot_script "$REPO/tests/lua/field_trace.lua" > "$d/mame.log" 2>&1
          rm -rf "$d/sb" ) </dev/null &
    done
done
wait
for part in $PARTS; do for leg in native ours; do [ -s "$W/$part.$leg.ft" ] || bad "$part $leg: no samples"; done; done
[ $fail = 0 ] || { echo "FAIL: audit_hitbox_parity (a leg did not run)"; exit 1; }
echo "== 2. identity, and the rows over the node-equal frames"
: > "$W/rows.tsv"; : > "$W/rows_pert.tsv"; TOT=0
for part in $PARTS; do
    t="${part%_*}"; case $t in donovan) ID=13;; huitzil) ID=10;; pyron) ID=11;; esac
    FE="$(python3 -c "import json;print(json.load(open('tests/replays/naming/${part}.json'))['events'][0]['frame'])")"
    for leg in native ours; do
        ids="$(awk -v f="$FE" '$1=="F"&&$2==f{for(i=3;i<=NF;i++){split($i,a,"=");if(a[1]=="id"||a[1]=="p2id")printf "%s=%s ",a[1],a[2]}}' "$W/$part.$leg.ft")"
        want="id=$((16#$ID)) p2id=1 "; [ "$ids" = "$want" ] && ok "$part $leg at f$FE: $ids" || bad "$part $leg at f$FE: $ids (want $want)"
    done
    RAW=""; vs_ctl_is no-translation && RAW=--raw
    OURS="$W/$part.ours.ft"
    if [ "$part" = "$FIRST" ]; then
        $HP plant "$W/$part.ours.ft" "$W/$part.ours.ptr.ft" > "$W/plant_ptr.log"; $HP plant-ids "$W/$part.ours.ft" "$W/$part.ours.ids.ft" > "$W/plant_ids.log"
        $HP compare "$part" "$t" "$W/$part.native.ft" "$W/$part.ours.ft" "$BUILD/patch/placements.json" --first "$FE" --raw > "$W/raw_$part.tsv"
        $HP compare "$part" "$t" "$W/$part.native.ft" "$W/$part.ours.ptr.ft" "$BUILD/patch/placements.json" --first "$FE" > "$W/ptr_$part.tsv"
        $HP compare "$part" "$t" "$W/$part.native.ft" "$W/$part.ours.ids.ft" "$BUILD/patch/placements.json" --first "$FE" > "$W/ids_$part.tsv"
        vs_ctl_is pointer-planted && { OURS="$W/$part.ours.ptr.ft"; echo "MODE: pointer-planted — $(cat "$W/plant_ptr.log")"; }
        vs_ctl_is ids-planted && { OURS="$W/$part.ours.ids.ft"; echo "MODE: ids-planted — $(cat "$W/plant_ids.log")"; }
    fi
    $HP compare "$part" "$t" "$W/$part.native.ft" "$OURS" "$BUILD/patch/placements.json" --first "$FE" $RAW >> "$W/rows.tsv" || bad "compare $part"
    [ -n "$RAW" ] && echo "MODE: no-translation — $part compared on raw pointers"
    n="$(grep "^hb	$part	frames	" "$W/rows.tsv" | cut -f5 | sed 's/node-equal=//')"; TOT=$((TOT + n))
    grep "^hb	$part	" "$W/rows.tsv" | grep -v '	frames	' | awk -F'\t' '{printf "  %-10s %-6s %s %s\n", $3, $4, $5, $6}' | sed 's/^/ /'; ok "$part: $(grep "^hb	$part	frames	" "$W/rows.tsv" | cut -f4-)"
done
echo "== 3. the controls, in-gate"
real="$(grep "^hb	$FIRST	" "$W/rows.tsv" | grep -v '	frames	')"
if grep -q 'DIFFER' "$W/raw_$FIRST.tsv"; then vs_ctl_fired no-translation "$FIRST compared raw reads $(grep -c DIFFER "$W/raw_$FIRST.tsv") field(s) DIFFER"; else vs_ctl_dead no-translation "raw pointers equal the translated ones"; fail=1; fi
if grep -q "^hb	$FIRST	t3	DIFFER" "$W/ptr_$FIRST.tsv"; then vs_ctl_fired pointer-planted "$(cat "$W/plant_ptr.log"): t3 reads DIFFER"; else vs_ctl_dead pointer-planted "a moved attack-table pointer reads SAME"; fail=1; fi
if grep -q "^hb	$FIRST	boxes	DIFFER" "$W/ids_$FIRST.tsv"; then vs_ctl_fired ids-planted "$(cat "$W/plant_ids.log"): boxes reads DIFFER"; else vs_ctl_dead ids-planted "an altered box-id word reads SAME"; fail=1; fi
vs_measured hitbox-node-equal-frames "$TOT"
if [ "${FREEZE:-0}" = 1 ]; then
    [ $fail = 0 ] || { echo "REFUSED FREEZE: a check above is red"; echo "FAIL: audit_hitbox_parity"; exit 1; }
    [ -z "${VS_CTL:-}" ] || { echo "REFUSED FREEZE: under a control mode"; echo "FAIL: audit_hitbox_parity"; exit 1; }
    vs_meas_guard "$0" hitbox-node-equal-frames "$TOT" || { echo "FAIL: audit_hitbox_parity"; exit 1; }
    { echo "# tests/expected/hitbox_parity.tsv — the hitboxes in play, ours ($(basename "$BUILD")) vs native vsav2: per part and field, over the"
      echo "# frames where both legs are on the same node, the resolved pointers (translated) and the box-id word (tests/audit_hitbox_parity.sh)."
      echo "# Evidence class: in-emulator. Frozen 14z-181 with FREEZE=1 (GitHub #136: the 14z-159 'hitboxes EXACT' sentence given its gate)."
      echo "#--"; cat "$W/rows.tsv"; } > "$EXPECT"
    echo "  FROZE  $(basename "$EXPECT") ($TOT node-equal frames) — VERIFY by re-running without FREEZE"; exit 0
fi
[ -f "$EXPECT" ] || { echo "FAIL: no frozen expectation at $EXPECT (FREEZE=1 to create it)"; exit 1; }
grep -v '^#' "$EXPECT" > "$W/want.tsv"
for part in $PARTS; do
    grep "^hb	$part	" "$W/want.tsv" > "$W/want_$part.tsv"; grep "^hb	$part	" "$W/rows.tsv" > "$W/got_$part.tsv"
    [ -s "$W/want_$part.tsv" ] || { bad "$part: no frozen rows"; continue; }
    if diff "$W/want_$part.tsv" "$W/got_$part.tsv" > "$W/diff_$part.txt"; then ok "$part: every row as frozen"; else bad "$part: rows moved:"; head -8 "$W/diff_$part.txt"; fi
done
[ -n "${GOT_OUT:-}" ] && cp "$W/rows.tsv" "$GOT_OUT"
if [ -n "${VS_CTL:-}" ]; then [ $fail = 0 ] && { echo "PASS (the control mode did NOT reach FAIL — the control is dead)"; exit 0; } || { echo "FAIL: audit_hitbox_parity (control mode)"; exit 1; }; fi
[ $fail = 0 ] && echo "PASS: audit_hitbox_parity" || echo "FAIL: audit_hitbox_parity"
exit $fail
