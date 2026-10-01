#!/bin/sh
# audit_dmg_legacy_sweep.sh — DEMITRI'S 2HK TAKES ONE MORE HP ON VSAVJ THAN ON VSAV2 FROM ALMOST EVERY LEGACY VICTIM, with no port in the loop, so Donovan's 9-against-8 on our build is the two ENGINES' (GitHub #191, ruled not-ours 2026-10-01): every legacy victim, both sides, pristine vsavj against pristine vsav2, plus Donovan's own rig ours against native, frozen as measured.
#
# WHAT: Demitri's 2HK, 5HP and 623HP on every legacy victim, from P1 and from P2, on pristine vsavj
#   against pristine vsav2, and on Donovan (P1) on our merged build against native vs2 — the
#   record of #191 (the maintainer: "1) close as not ours 2) document with the other engine
#   differences between vsavj and VS2", 2026-10-01).
# HOW: 66 MAME runs, six at a time: 16 legacy victims x 2 games x 2 sides on the 14z-186
#   control's two replays (victim and Demitri by the early-window forced picks, the victim's HP
#   pinned to 288 sixty frames before each hit, the level pinned 6 from 2000 and the RNG word
#   0000 from 2363), and Donovan's 14z-186 probe-12 rig on native vs2 and ours (the parity
#   gates' cursor path and pins); tools/dmg_sweep.py reads every line of every trace into one row
#   per hit (red and white HP lost, first-drop frame, the attacker's id and the victim's
#   reaction class there); the damage pipeline's tables compared between the two games' data
#   images.
# EXPECTS: every leg's forced ids as traced, Demitri the attacker at every hit, the defense rows
#   differing only for ids 0a 10 13 19 1a with the attack table and the 2D map equal, and every
#   row equal to tests/expected/dmg_legacy_sweep.tsv (on 2026-10-01: vsavj one more red HP on 2HK
#   on 14 of the 15 victims hit, Victor 0x03 alone equal, Oboro 0x18's 2HK no hit on vsavj; the
#   same on both sides; Donovan 9 ours / 8 native); both controls fire.
# FOLLOWS: build/manifest/ emu/mame-patches/ tests/expected/dmg_legacy_sweep.tsv tests/replays/dmg191/
#   tests/expected/registry.tsv tests/lib/controls.sh tests/lua/field_trace.lua tools/dmg_sweep.py
#   tools/build_fingerprint.py tools/cps2_decrypt.py tools/run_mame.sh tools/setup_mame.sh
#
# MUST-FIRE: perturbed-copy: engines-agree — the rows with every vsavj total replaced by its vsav2 twin's (what two engines that agreed would read) must FAIL the frozen compare, so the +1 between the ENGINES is read from the rows, not assumed (in-gate: the perturbed rows must differ from the frozen ones; mode: the perturbed rows are the gate's rows and the compare FAILs)
# MUST-FIRE: perturbed-copy: attacker-swapped — the reader run with the attacker id read as 0x03 at every hit must report every hit as not Demitri's, so "the hit was Demitri's 2HK" is something the gate can refuse (in-gate: the reader on the real traces with the perturbation must exit non-zero; mode: the gate's own read is perturbed and the gate FAILs)
#
# POKE READ-BACK (ruled 2026-10-01 (14z-187), tests/expected/poke_readback.tsv): the victim's HP words (ff8450/ff8850,
# red and white) are pinned to 288 before each hit and only the DROPS after the pin are read (OBSERVES); the two ids
# (ff8782/ff8b82) are the forced picks' own pokes, read back at 2300 and at each hit only as a stage guard that the
# picks landed and Demitri is the attacker — a rig record (READS-BACK), never a measurement of the game.
#
# WHY. #191 (14z-186) read Donovan losing 9 to Demitri's 2HK on ours against 8 natively, where a legacy control
# (Demitri on Victor, pristine vsavj and vsav2) agreed on 2HK — so the +1 looked like ours. 14z-187 widened the
# control to every legacy victim, from both sides (rule-checker runs 2026-10-01-504 to -506, 506 OK): Victor is the
# ONE victim on which the two engines agree on 2HK; on 14 of the 15 victims hit, vsavj takes one more, with the
# victims' defense rows, the attack table and the 2D map byte-equal between the games — the class #161 closed as
# not-ours (the #161 paragraph of docs/project/tables/defense_rows.md). Scratch origin:
# build/agent187/t191/ (sweep/, sweep2/, dmg191.py), promoted here ([VSP-18]).
#
# FROZEN: tests/expected/dmg_legacy_sweep.tsv — one row per hit: `legacy <side> <victim id> <game> <hit> <red>
# <white> <first drop frame> <attacker id> <victim class>` and `donovan p2 13 <native|ours> <event> <red> <white>
# <+offset> <attacker id> <victim class>`, plus the table check's two lines and one `ours build` row. FREEZE=1
# rewrites it.
#
# NOT COVERED: WHERE in vsavj's pipeline the point is added (the ticket's open question, as for #161); the
# damage-level config byte; attackers other than Demitri and moves other than these three; Donovan as P2; whether
# the level and RNG pins change the per-game difference; FBNeo and the MiSTer core.
#
# Usage: ROMDIR=... [MAME_BIN=...] [BUILD=build/m3b_merged29] [JOBS=6] [FREEZE=1] tests/audit_dmg_legacy_sweep.sh
#   emulator tier, MAME; 66 runs of up to 4725 frames, six at a time (~10 min quiet)
set -eu
[ -n "${ROMDIR:-}" ] || { echo "FAIL: set ROMDIR"; exit 1; }
[ -d "$ROMDIR" ] && ROMDIR="$(cd "$ROMDIR" && pwd)"
REPO="$(cd "$(dirname "$0")/.." && pwd)"
MAME_BIN="${MAME_BIN:-$HOME/.cache/vampire-saved/mame/cps2}"; export MAME_BIN
BUILD="${BUILD:-build/m3b_merged29}"
case "$BUILD" in /*) ;; *) BUILD="$REPO/$BUILD" ;; esac
JOBS="${JOBS:-6}"
EXPECT="$REPO/tests/expected/dmg_legacy_sweep.tsv"
RD="$REPO/tests/replays/dmg191"
[ -x "$MAME_BIN" ] || { echo "SKIP: no MAME at $MAME_BIN"; exit 0; }
[ -f "$BUILD/rompath/vsavjw.zip" ] || { echo "SKIP: no WIDE build at $BUILD"; exit 0; }
[ -f "$REPO/build/out/vsavj_data.bin" ] && [ -f "$REPO/build/out/vsav2_data.bin" ] || {
    echo "SKIP: no data images (build/out/vsavj_data.bin, build/out/vsav2_data.bin: tools/cps2_decrypt.py --data-out)"; exit 0; }
. "$REPO/tests/lib/controls.sh"; vs_ctl_mode "$0"; MODE="${VS_CTL:-}"
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT INT TERM
fail=0
ok()  { printf '  ok    %s\n' "$1"; }
bad() { printf '  FAIL  %s\n' "$1"; fail=1; }
IDS="00 01 02 03 04 05 06 07 08 09 0a 0c 0d 0e 0f 18"

echo "== 1. the damage pipeline's tables, vsavj against vsav2 (data views)"
python3 "$REPO/tools/dmg_sweep.py" tables "$REPO/build/out/vsavj_data.bin" "$REPO/build/out/vsav2_data.bin" > "$W/tables.txt"
sed 's/^/     /' "$W/tables.txt"
grep -qx 'defense rows differing by id: 0a 10 13 19 1a' "$W/tables.txt" \
    && grep -qx 'attack table: equal' "$W/tables.txt" && grep -qx '2D map: equal' "$W/tables.txt" \
    && ok "defense rows differ only for 0a 10 13 19 1a; the attack table and the 2D map are equal" \
    || bad "the tables are not as the attribution needs them (rows differing only for 0a 10 13 19 1a, the two tables equal)"

LV="$(python3 -c "print(';'.join(f'{f}:ff8116:06' for f in range(2000,4730)) + ';' + ';'.join(f'{f}:ff80d4:0000' for f in range(2363,4730)))")"
lleg() {  # lleg <side p1|p2> <victim id> <vsavj|vsav2>
    _s="$1"; _v="$2"; _g="$3"; _d="$W/L.$_s.$_v.$_g"; mkdir -p "$_d"
    if [ "$_s" = p1 ]; then _pk="1400:ff8b82:$_v;1450:ff8b82:$_v;1500:ff8b82:$_v;2940:ff8850:01200120;3380:ff8850:01200120;3780:ff8850:01200120"
    else _pk="1400:ff8782:$_v;1450:ff8782:$_v;1500:ff8782:$_v;1400:ff8b82:01;1450:ff8b82:01;1500:ff8b82:01;2940:ff8450:01200120;3380:ff8450:01200120;3780:ff8450:01200120"; fi
    case "$_s" in p1) _r="$REPO/tests/replays/dmg191/demitri_p1.rpl" ;; *) _r="$REPO/tests/replays/dmg191/demitri_p2.rpl" ;; esac
    ( cd "$_d" && MAME_SANDBOX="$_d/sb" MAME_ROMPATH="$ROMDIR" REPLAY="$_r" POKES="$LV;$_pk" \
        FIELDS="ff8450:w:p1hp,ff8452:w:p1white,ff8454:b:p1cls,ff8850:w:p2hp,ff8852:w:p2white,ff8854:b:p2cls,ff8782:b:id,ff8b82:b:p2id" \
        FIELD_OUT="$_d/f.ft" FIELD_FROM=2300 FIELD_TO=4100 FRAMES=4100 \
        "$REPO/tools/run_mame.sh" "$_g" -autoboot_script "$REPO/tests/lua/field_trace.lua" > "$_d/mame.log" 2>&1; rm -rf "$_d/sb" ) </dev/null
}
dleg() {  # dleg <native|ours> — Donovan (P1) against Demitri (P2), the 14z-186 probe-12 rig, the parity gates' pins
    _l="$1"; _d="$W/D.$_l"; mkdir -p "$_d"; _j="$RD/donovan_p12.json"
    _fr="$(python3 -c "import json;print(json.load(open('$_j'))['frames'])")"
    _pk="$(python3 -c "import json;print(';'.join(json.load(open('$_j'))['pokes']))")"
    if [ "$_l" = native ]; then _set=vsav2; _rp="$ROMDIR"; cp "$REPO/tests/replays/dmg191/donovan_p12.rpl" "$_d/r.rpl"
    else _set=vsavjw; _rp="$BUILD/rompath;$ROMDIR"
        awk -v p="D D DR DR" '/^1104-1106 p2=R$/ && !done { n = split(p, m, " "); t = 1100
            for (i = 1; i <= n; i++) { printf "%d-%d p1=%s\n", t, t + 2, m[i]; t += 60 }; done = 1 }
            /^(1100|1160|1220|1280)-[0-9]+ p1=/ { next } { print }' "$REPO/tests/replays/dmg191/donovan_p12.rpl" > "$_d/r.rpl"
    fi
    ( cd "$_d" && MAME_SANDBOX="$_d/sb" MAME_ROMPATH="$_rp" REPLAY="$_d/r.rpl" POKES="$_pk;$LV" \
        FIELDS="ff8450:w:p1hp,ff8452:w:p1white,ff8454:b:p1cls,ff8782:b:id,ff8b82:b:p2id" \
        FIELD_OUT="$_d/f.ft" FIELD_FROM=2300 FIELD_TO="$_fr" FRAMES="$_fr" \
        "$REPO/tools/run_mame.sh" "$_set" -autoboot_script "$REPO/tests/lua/field_trace.lua" > "$_d/mame.log" 2>&1; rm -rf "$_d/sb" ) </dev/null
}
echo "== 2. the legs (16 victims x vsavj/vsav2 x Demitri on P1/P2; Donovan native/ours $(basename "$BUILD")), $JOBS at a time"
n=0
for s in p1 p2; do for v in $IDS; do for g in vsavj vsav2; do
    lleg "$s" "$v" "$g" & n=$((n + 1)); [ $((n % JOBS)) = 0 ] && wait
done; done; done
dleg native & dleg ours & wait

echo "== 3. the rows (every line of every trace, tools/dmg_sweep.py)"
if python3 "$REPO/tools/dmg_sweep.py" rows "$W" "$RD/donovan_p12.json" > "$W/rows.tsv" 2> "$W/problems.txt"
then ok "$(wc -l < "$W/rows.tsv" | tr -d ' ') hit rows; every trace complete, every leg's forced ids as traced, Demitri (0x01) the attacker at every hit"
else bad "the reader found structural problems:"; sed 's/^/        /' "$W/problems.txt"; fi
python3 "$REPO/tools/dmg_sweep.py" rows "$W" "$RD/donovan_p12.json" --perturb engines-agree > "$W/agree.tsv" 2>/dev/null || true
if python3 "$REPO/tools/dmg_sweep.py" rows "$W" "$RD/donovan_p12.json" --perturb attacker-swapped > /dev/null 2> "$W/swapped.txt"; then sw=0; else sw=1; fi
if [ "$MODE" = attacker-swapped ]; then
    [ "$sw" = 1 ] && bad "attacker-swapped mode: the reader refuses every hit ($(grep -c 'not Demitri' "$W/swapped.txt") problems)"
fi
[ "$MODE" = engines-agree ] && cp "$W/agree.tsv" "$W/rows.tsv"
python3 - "$W/rows.tsv" <<'PY' | sed 's/^/     /'
import sys
R = [l.rstrip("\n").split("\t") for l in open(sys.argv[1])]
t = {(r[1], r[2], r[4], r[3]): r for r in R if r[0] == "legacy"}
for side in ("p1", "p2"):
    for hit in ("2HK", "5HP", "623HP"):
        d = []
        for (s, v, h, g), r in sorted(t.items()):
            if s == side and h == hit and g == "vsavj" and (s, v, h, "vsav2") in t:
                b = t[(s, v, h, "vsav2")]
                d.append(f"{v}:{int(r[5]) - int(b[5]):+d}")
        print(f"Demitri on {side}, {hit}: vsavj red minus vsav2 red per victim  " + " ".join(d))
for r in R:
    if r[0] == "donovan": print(f"Donovan event {r[4]} {r[3]}: red {r[5]} white {r[6]} at {r[7]} attacker {r[8]} class {r[9]}")
PY
_bid="$(python3 "$REPO/tools/build_fingerprint.py" "$BUILD/rompath" --set vsavjw --registry "$REPO/tests/expected/registry.tsv" 2>/dev/null | tail -1)"
_bfp="$(python3 "$REPO/tools/build_fingerprint.py" "$BUILD/rompath" --set vsavjw --set-key 2>/dev/null | tail -1 | cut -c1-8)"
{ grep -v '^read ' "$W/tables.txt" | sed 's/^/tables\t/'; cat "$W/rows.tsv"; printf 'ours\tbuild\t%s\t%s\n' "${_bid:-unregistered}" "${_bfp:-?}"; } > "$W/got.tsv"
{ grep -v '^read ' "$W/tables.txt" | sed 's/^/tables\t/'; cat "$W/agree.tsv"; printf 'ours\tbuild\t%s\t%s\n' "${_bid:-unregistered}" "${_bfp:-?}"; } > "$W/got_agree.tsv"

echo "== 4. the frozen rows"
if [ "${FREEZE:-0}" = 1 ] && [ -z "$MODE" ]; then
    [ "$fail" = 0 ] || { echo "FAIL: not freezing a table whose structural checks failed"; exit 1; }
    { echo "# tests/expected/dmg_legacy_sweep.tsv — Demitri's 2HK/5HP/623HP on every legacy victim (both sides) on pristine vsavj and"
      echo "# pristine vsav2, and on Donovan (P1) on our merged build and native vs2 (tests/audit_dmg_legacy_sweep.sh, GitHub #191)."
      echo "# Evidence class: in-emulator, MAME (+ the static table check). Frozen AS MEASURED with FREEZE=1 on $(basename "$BUILD")."
      echo "# Rows: legacy <side> <victim> <game> <hit> <red> <white> <first drop frame> <attacker> <victim class>; donovan p2 13"
      echo "# <leg> <event> <red> <white> <+offset> <attacker> <class>; the table lines; one ours build row."
      echo "#--"
      cat "$W/got.tsv"; } > "$EXPECT"
    echo "  FROZE $(basename "$EXPECT") — VERIFY by re-running without FREEZE"; exit 0
fi
[ -f "$EXPECT" ] || { echo "FAIL: no frozen expectation at $EXPECT (FREEZE=1 to create it)"; exit 1; }
grep -v '^#' "$EXPECT" > "$W/want.tsv"
if cmp -s "$W/want.tsv" "$W/got.tsv"; then ok "every row as frozen"
else bad "differs from the frozen rows"; diff "$W/want.tsv" "$W/got.tsv" | sed 's/^/        /'; fi
if [ -z "$MODE" ]; then
    if cmp -s "$W/want.tsv" "$W/got_agree.tsv"; then vs_ctl_dead engines-agree "the rows with vsav2's totals in vsavj's place still match the frozen rows" || fail=1
    else vs_ctl_fired engines-agree "the rows with vsav2's totals in vsavj's place differ from the frozen rows ($(diff "$W/want.tsv" "$W/got_agree.tsv" | grep -c '^>') rows) — the +1 between the two ENGINES is what the rows hold"; fi
    if [ "$sw" = 1 ]; then vs_ctl_fired attacker-swapped "the reader with the attacker read as 0x03 refuses $(grep -c 'not Demitri' "$W/swapped.txt") hits"
    else vs_ctl_dead attacker-swapped "the reader with the attacker read as 0x03 still passed" || fail=1; fi
fi
if [ "$fail" = 0 ]; then echo "PASS: audit_dmg_legacy_sweep"; else echo "FAIL: audit_dmg_legacy_sweep"; exit 1; fi
