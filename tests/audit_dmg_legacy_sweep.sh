#!/bin/sh
# audit_dmg_legacy_sweep.sh — DEMITRI'S 2HK/5HP/623HP TAKE MORE HP ON VSAVJ THAN ON VSAV2 FROM ALMOST EVERY LEGACY VICTIM, with no port in the loop, BECAUSE VS2 LOWERED HIS OWN ATTACK RECORDS (10/14/20 -> 9/13/18) — each game given the other's records takes the other's damage on 14 of the 16 legacy victims, both sides (not on Sasquatch 0x0A, whose defense row differs, nor Oboro 0x18, whose hits land differently), 14z-187b; so Donovan's 9-against-8 on our build is vsavj's Demitri, not ours (GitHub #191, ruled not-ours 2026-10-01). ~~the two ENGINES'~~ RETRACTED 14z-187b: on these three hits the damage follows the record, on 14 of the 16 legacy victims (section 5); whether the engines ever differ on a record-equal hit is not claimed (Sasquatch 0x0A's rows stay apart with equal records).
#
# WHAT: Demitri's 2HK, 5HP and 623HP on every legacy victim, from P1 and from P2, on pristine vsavj
#   against pristine vsav2, and on Donovan (P1) on our merged build against native vs2; and WHY the
#   games differ: those hits' own attack records, swapped between the games, swap the damage — the
#   record of #191 (the maintainer: "1) close as not ours 2) document with the other engine
#   differences between vsavj and VS2", 2026-10-01).
# HOW: 66 MAME runs, six at a time: 16 legacy victims x 2 games x 2 sides on the 14z-186
#   control's two replays (victim and Demitri by the early-window forced picks, the victim's HP
#   pinned to 288 sixty frames before each hit, the level pinned 6 from 2000 and the RNG word
#   0000 from 2363), and Donovan's 14z-186 probe-12 rig on native vs2 and ours (the parity
#   gates' cursor path and pins); tools/dmg_sweep.py reads every line of every trace into one row
#   per hit (red and white HP lost, first-drop frame, the attacker's id and the victim's
#   reaction class there); the damage pipeline's tables compared between the two games' data
#   images; section 5 reads the three hits' attack records on both games (tools/dmg_sweep.py
#   records) and replays one leg per game with those bytes set to the other game's values through
#   tests/lua/rom_poke.lua (verified writes, an own-value poke as the inert control on each of
#   the three images: vsavj and vs2 on victim 0x00's leg, the merged build and vs2 on Donovan's).
# EXPECTS: every leg's forced ids as traced, Demitri the attacker at every hit, the defense rows
#   differing only for ids 0a 10 13 19 1a with the attack table and the 2D map equal, and every
#   row equal to tests/expected/dmg_legacy_sweep.tsv (on 2026-10-01: vsavj one more red HP on 2HK
#   on 14 of the 15 victims hit, Victor 0x03 alone equal, Oboro 0x18's 2HK no hit on vsavj; the
#   same on both sides; Donovan 9 ours / 8 native); the three records differ, each game poked to the
#   other's records deals the other's damage hit for hit (vsavj 9/13/19, vs2 8/12/17 on victim 0x00),
#   the hits are the record chains' nodes; over the WHOLE sweep (64 swapped legs) 176 of 192 rows equal
#   the other game's frozen row, the 16 others exactly Sasquatch 0x0A's and Oboro 0x18's; Donovan's
#   own legs swapped (ours given vs2's records, native given vsavj's) read the other leg's frozen rows,
#   8 of 8, and his own-value legs reproduce their unpoked traces; all three controls fire.
# FOLLOWS: build/manifest/ emu/mame-patches/ tests/expected/dmg_legacy_sweep.tsv tests/replays/dmg191/
#   tests/expected/registry.tsv tests/lib/controls.sh tests/lua/field_trace.lua tools/dmg_sweep.py
#   tools/build_fingerprint.py tools/cps2_decrypt.py tools/run_mame.sh tools/setup_mame.sh
#   tests/lua/rom_poke.lua tools/audit_same_data_p2.py tools/hitbox_records.py tools/anim_nodes.py
#
# MUST-FIRE: perturbed-copy: engines-agree — the rows with every vsavj total replaced by its vsav2 twin's (what two games that agreed would read) must FAIL the frozen compare, so the +1 between the GAMES is read from the rows, not assumed (in-gate: the perturbed rows must differ from the frozen ones; mode: the perturbed rows are the gate's rows and the compare FAILs)
# MUST-FIRE: perturbed-copy: attacker-swapped — the reader run with the attacker id read as 0x03 at every hit must report every hit as not Demitri's, so "the hit was Demitri's 2HK" is something the gate can refuse (in-gate: the reader on the real traces with the perturbation must exit non-zero; mode: the gate's own read is perturbed and the gate FAILs)
# MUST-FIRE: perturbed-copy: counterfactual-skipped — the unpoked vsavj and vs2 legs must deal DIFFERENT damage, so "each game poked to the other's records deals the other's damage" is an equality the comparison can refuse (in-gate: the unpoked legs differ; mode: the unpoked traces stand in for the poked ones and the gate FAILs)
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
# not-ours (the #161 paragraph of docs/project/tables/defense_rows.md).
# **RETRACTED 14z-187b — the reading, not the rows:** "the two engines" assumed equal data, but the check above
# compared only the PIPELINE's tables (the attack table here is the shared 1 KB table at PRG:0x0B8140, not the
# attacker's per-character records). Demitri's three hits are nodes of his own a2 chains (2HK a2:0x11#2, 5HP a2:0x04#2,
# 623HP a2:0x28#1) whose records vs2 lowered by 1/1/2; setting one game's record bytes to the other's swaps the damage
# exactly, both ways, and over the whole sweep on 14 of the 16 legacy victims from both sides, Victor included
# (section 5). The swap leaves Sasquatch 0x0A's and Oboro 0x18's rows apart: Sasquatch's own defense row differs
# between the games (whether it alone explains his rows is not separated); Oboro's hits land differently on the two
# games (2HK misses on vsavj, 623HP lands as class 0x02) and WHY is not measured. Why Victor's 2HK reads equal on both games is not measured; the swap
# reproduces it. The rows stay valid and frozen; #191 stays not-ours (vsavj's data is the vanilla one). Scratch origin:
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

LV="$(python3 -c "print(f'{2000}-{(4730)-1}:ff8116:06' + ';' + f'{2363}-{(4730)-1}:ff80d4:0000')")"
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
    else vs_ctl_fired engines-agree "the rows with vsav2's totals in vsavj's place differ from the frozen rows ($(diff "$W/want.tsv" "$W/got_agree.tsv" | grep -c '^>') rows) — the +1 between the two GAMES is what the rows hold"; fi
    if [ "$sw" = 1 ]; then vs_ctl_fired attacker-swapped "the reader with the attacker read as 0x03 refuses $(grep -c 'not Demitri' "$W/swapped.txt") hits"
    else vs_ctl_dead attacker-swapped "the reader with the attacker read as 0x03 still passed" || fail=1; fi
fi
echo "== 5. the mechanism: Demitri's OWN attack records decide the difference (counterfactual, 14z-187b)"
# The three hits are nodes of Demitri's own a2 chains whose attack records are LOWER on vs2 (tools/dmg_sweep.py records).
# One leg (Demitri on P1 against victim 0x00, section 2's replay and pins) per game, three ways: unpoked; with the three
# record bytes poked to their OWN values (the poke path inert); and with them poked to the OTHER game's values. If the
# records are the cause, each game poked to the other's records deals the other game's damage, hit for hit.
python3 "$REPO/tools/dmg_sweep.py" records "$REPO/build/out/vsavj_data.bin" "$REPO/build/out/vsav2_data.bin" > "$W/records.txt"
sed 's/^/     /' "$W/records.txt"
[ "$(grep -c '^record .* DIFF$' "$W/records.txt")" = 3 ] \
    && ok "the three hits' records differ between the games (vs2 lower)" \
    || bad "the three hits' records are not all different — the counterfactual below has nothing to swap"
eval "$(awk '/^record /{n=$2; split($5,a,"="); split($7,b,"="); sub(/^0x/,"",a[1]); sub(/^0x/,"",b[1]);
    printf "J_%s=%s:%02x; V_%s=%s:%02x; JV_%s=%s:%02x; VJ_%s=%s:%02x;\n", n, a[1], a[2], n, b[1], b[2], n, a[1], b[2], n, b[1], a[2]}' "$W/records.txt" | sed 's/J_623HP/J_623/g; s/V_623HP/V_623/g; s/JV_623HP/JV_623/g; s/VJ_623HP/VJ_623/g; s/J_2HK/J_2/g; s/V_2HK/V_2/g; s/JV_2HK/JV_2/g; s/VJ_2HK/VJ_2/g; s/J_5HP/J_5/g; s/V_5HP/V_5/g; s/JV_5HP/JV_5/g; s/VJ_5HP/VJ_5/g')"
cleg() {  # cleg <vsavj|vsav2> <tag> <ROMPOKE>
    _g="$1"; _d="$W/C.$_g.$2"; mkdir -p "$_d"
    _pk="1400:ff8b82:00;1450:ff8b82:00;1500:ff8b82:00;2940:ff8850:01200120;3380:ff8850:01200120;3780:ff8850:01200120"
    ( cd "$_d" && MAME_SANDBOX="$_d/sb" MAME_ROMPATH="$ROMDIR" REPLAY="$REPO/tests/replays/dmg191/demitri_p1.rpl" POKES="$LV;$_pk" \
        ROMPOKE="$3" FIELDS="ff841c:l:node,ff8850:w:p2hp,ff8852:w:p2white,ff8782:b:id,ff8b82:b:p2id" \
        FIELD_OUT="$_d/f.ft" FIELD_FROM=2300 FIELD_TO=4100 FRAMES=4100 \
        "$REPO/tools/run_mame.sh" "$_g" -autoboot_script "$REPO/tests/lua/rom_poke.lua" > "$_d/mame.log" 2>&1; rm -rf "$_d/sb" ) </dev/null
}
cleg vsavj base "" & cleg vsavj same "$J_2,$J_5,$J_623" & cleg vsavj swap "$JV_2,$JV_5,$JV_623" &
cleg vsav2 base "" & cleg vsav2 same "$V_2,$V_5,$V_623" & cleg vsav2 swap "$VJ_2,$VJ_5,$VJ_623" & wait
for g in vsavj vsav2; do
    python3 "$REPO/tools/dmg_sweep.py" nodes "$REPO/build/out/${g}_data.bin" "$g" "$W/C.$g.base/f.ft" > "$W/C.$g.base.hits"
    for t in same swap; do python3 "$REPO/tools/dmg_sweep.py" nodes "$REPO/build/out/${g}_data.bin" "$g" "$W/C.$g.$t/f.ft" > "$W/C.$g.$t.hits"; done
    sed "s/^/     $g base: /" "$W/C.$g.base.hits"
    [ "$(grep -c '^ROMPOKE ok' "$W/C.$g.same/mame.log")" = 3 ] && [ "$(grep -c '^ROMPOKE ok' "$W/C.$g.swap/mame.log")" = 3 ] \
        && ! grep -q 'ROMPOKE FAIL' "$W/C.$g.same/mame.log" "$W/C.$g.swap/mame.log" \
        && ok "$g: all six record writes verified through the program space" || bad "$g: a record write did not verify (mame.log)"
    cmp -s "$W/C.$g.base/f.ft" "$W/C.$g.same/f.ft" && ok "$g: poking the records to their own values changes nothing (the poke path is inert)" \
        || bad "$g: the own-value poke changed the trace"
    [ "$(awk '{print $NF}' "$W/C.$g.base.hits" | tr '\n' ' ')" = "a2:0x11#2 a2:0x04#2 a2:0x28#1 " ] \
        && ok "$g: the three hits are the record chains' nodes (a2:0x11#2, a2:0x04#2, a2:0x28#1)" \
        || bad "$g: the hits are not the record chains' nodes: $(awk '{print $NF}' "$W/C.$g.base.hits" | tr '\n' ' ')"
done
# THE WHOLE SWEEP (after rule-checker run 2026-10-01-512 Q1: one leg was not the sweep): every legacy victim, both sides,
# each game with the OTHER game's three records — section 2's legs exactly, through rom_poke.lua. A swapped row must equal
# the OTHER game's frozen row (red and white) for every victim but Sasquatch 0x0A (his own defense row differs between the
# games; not separated as the cause) and Oboro 0x18 (his hits land differently: 2HK misses on vsavj, 623HP lands as class
# 0x02; why is not measured) — measured 14z-187b:
# 176 of 192 equal, the 16 others exactly those two victims' rows.
sleg() {  # sleg <side> <victim> <game> — section 2's lleg, with the other game's records
    _s="$1"; _v="$2"; _g="$3"; _d="$W/S/L.$_s.$_v.$_g"; mkdir -p "$_d"
    if [ "$_s" = p1 ]; then _pk="1400:ff8b82:$_v;1450:ff8b82:$_v;1500:ff8b82:$_v;2940:ff8850:01200120;3380:ff8850:01200120;3780:ff8850:01200120"
    else _pk="1400:ff8782:$_v;1450:ff8782:$_v;1500:ff8782:$_v;1400:ff8b82:01;1450:ff8b82:01;1500:ff8b82:01;2940:ff8450:01200120;3380:ff8450:01200120;3780:ff8450:01200120"; fi
    case "$_s" in p1) _r="$REPO/tests/replays/dmg191/demitri_p1.rpl" ;; *) _r="$REPO/tests/replays/dmg191/demitri_p2.rpl" ;; esac
    if [ "$_g" = vsavj ]; then _rp="$JV_2,$JV_5,$JV_623"; else _rp="$VJ_2,$VJ_5,$VJ_623"; fi
    ( cd "$_d" && MAME_SANDBOX="$_d/sb" MAME_ROMPATH="$ROMDIR" REPLAY="$_r" POKES="$LV;$_pk" ROMPOKE="$_rp" \
        FIELDS="ff8450:w:p1hp,ff8452:w:p1white,ff8454:b:p1cls,ff8850:w:p2hp,ff8852:w:p2white,ff8854:b:p2cls,ff8782:b:id,ff8b82:b:p2id" \
        FIELD_OUT="$_d/f.ft" FIELD_FROM=2300 FIELD_TO=4100 FRAMES=4100 \
        "$REPO/tools/run_mame.sh" "$_g" -autoboot_script "$REPO/tests/lua/rom_poke.lua" > "$_d/mame.log" 2>&1; rm -rf "$_d/sb" ) </dev/null
}
n=0
for s in p1 p2; do for v in $IDS; do for g in vsavj vsav2; do
    sleg "$s" "$v" "$g" & n=$((n + 1)); [ $((n % JOBS)) = 0 ] && wait
done; done; done; wait
[ "$(grep -l '^ROMPOKE ok' "$W"/S/L.*/mame.log | wc -l | tr -d ' ')" = 64 ] && ! grep -q 'ROMPOKE FAIL' "$W"/S/L.*/mame.log \
    && ok "the whole sweep: 64 swapped legs, every record write verified" || bad "the whole sweep: a swapped leg's record write did not verify"
python3 - "$W" "$REPO" "$MODE" <<'PY' > "$W/sweep_swap.txt"
import sys; W, REPO, MODE = sys.argv[1:4]; sys.path.insert(0, REPO + "/tools")
import dmg_sweep as ds
out, _ = ds.rows(f"{W}/S" if MODE != "counterfactual-skipped" else W, REPO + "/tests/replays/dmg191/donovan_p12.json")
sw = {(r[1], r[2], r[4], r[3]): r for r in ((l if isinstance(l, list) else l.split("\t")) for l in out) if r[0] == "legacy"}
fr = {}
for l in open(REPO + "/tests/expected/dmg_legacy_sweep.tsv"):
    r = l.rstrip("\n").split("\t")
    if r[0] == "legacy": fr[(r[1], r[2], r[4], r[3])] = r
other = {"vsavj": "vsav2", "vsav2": "vsavj"}
eq, ne = 0, []
for (side, v, hit, g), r in sorted(sw.items()):
    f = fr.get((side, v, hit, other[g]))
    if f and (r[5], r[6]) == (f[5], f[6]): eq += 1
    else: ne.append((side, v, hit, g))
print(f"equal {eq} of {len(sw)}; differing victims {sorted({x[1] for x in ne})}; differing rows {len(ne)}")
PY
sed 's/^/     /' "$W/sweep_swap.txt"
grep -qx "equal 176 of 192; differing victims \['0a', '18'\]; differing rows 16" "$W/sweep_swap.txt" \
    && ok "every legacy victim but Sasquatch 0x0A and Oboro 0x18, both sides, takes the OTHER game's damage from the other game's records (176 of 192 rows)" \
    || bad "the whole-sweep swap is not as measured (176 of 192 equal, only 0a and 18 differing): $(cat "$W/sweep_swap.txt")"
# DONOVAN'S OWN LEGS (after rule-checker run 2026-10-01-513 Q1: the header's "Donovan's 9-against-8 is vsavj's Demitri"
# needed his own legs swapped): section 2's dleg, ours given vs2's three records and native given vsavj's (the merged
# build's records sit at vsavj's addresses). Each swapped leg must read the OTHER leg's frozen Donovan rows, red and white
# — measured 14z-187b: exact, all four events, both ways.
dswap() {  # dswap <native|ours> [same] — section 2's dleg with the other game's records ("same": its OWN records, in $W/SAME)
    _l="$1"; _sd=S; [ -n "${2:-}" ] && _sd=SAME; _d="$W/$_sd/D.$_l"; mkdir -p "$_d"; _j="$RD/donovan_p12.json"
    _fr="$(python3 -c "import json;print(json.load(open('$_j'))['frames'])")"
    _pk="$(python3 -c "import json;print(';'.join(json.load(open('$_j'))['pokes']))")"
    if [ "$_l" = native ]; then _set=vsav2; _rp="$ROMDIR"; _rk="$VJ_2,$VJ_5,$VJ_623"; [ -n "${2:-}" ] && _rk="$V_2,$V_5,$V_623"
        cp "$REPO/tests/replays/dmg191/donovan_p12.rpl" "$_d/r.rpl"
    else _set=vsavjw; _rp="$BUILD/rompath;$ROMDIR"; _rk="$JV_2,$JV_5,$JV_623"; [ -n "${2:-}" ] && _rk="$J_2,$J_5,$J_623"
        cp "$W/D.ours/r.rpl" "$_d/r.rpl"; fi
    ( cd "$_d" && MAME_SANDBOX="$_d/sb" MAME_ROMPATH="$_rp" REPLAY="$_d/r.rpl" POKES="$_pk;$LV" ROMPOKE="$_rk" \
        FIELDS="ff8450:w:p1hp,ff8452:w:p1white,ff8454:b:p1cls,ff8782:b:id,ff8b82:b:p2id" \
        FIELD_OUT="$_d/f.ft" FIELD_FROM=2300 FIELD_TO="$_fr" FRAMES="$_fr" \
        "$REPO/tools/run_mame.sh" "$_set" -autoboot_script "$REPO/tests/lua/rom_poke.lua" > "$_d/mame.log" 2>&1; rm -rf "$_d/sb" ) </dev/null
}
dswap native & dswap ours & dswap native same & dswap ours same & wait
python3 - "$W" "$REPO" "$MODE" <<'PY' > "$W/dswap.txt"
import sys; W, REPO, MODE = sys.argv[1:4]; sys.path.insert(0, REPO + "/tools")
import dmg_sweep as ds
out, _ = ds.rows(f"{W}/S" if MODE != "counterfactual-skipped" else W, REPO + "/tests/replays/dmg191/donovan_p12.json")
sw = {(r[3], r[4]): (r[5], r[6]) for r in ((l if isinstance(l, list) else l.split("\t")) for l in out) if r[0] == "donovan"}
fr = {}
for l in open(REPO + "/tests/expected/dmg_legacy_sweep.tsv"):
    r = l.rstrip("\n").split("\t")
    if r[0] == "donovan": fr[(r[3], r[4])] = (r[5], r[6])
other = {"native": "ours", "ours": "native"}
eq = sum(1 for (leg, ev), v in sw.items() if fr.get((other[leg], ev)) == v)
print(f"donovan swapped rows {len(sw)}; equal to the other leg's frozen row {eq}")
PY
sed 's/^/     /' "$W/dswap.txt"
[ "$(grep -c 'ROMPOKE ok' "$W/S/D.native/mame.log" "$W/S/D.ours/mame.log" | awk -F: '{s+=$2} END {print s}')" = 6 ] \
    && grep -qx 'donovan swapped rows 8; equal to the other leg.s frozen row 8' "$W/dswap.txt" \
    && ok "Donovan's own legs: ours given vs2's records reads native's frozen rows and native given vsavj's reads ours (8 of 8)" \
    || bad "Donovan's swapped legs are not the other leg's frozen rows: $(cat "$W/dswap.txt")"
# THE INERT CONTROL ON EACH IMAGE THE SWAP USES (rule-checker run 2026-10-01-518 Q1/Q4: the own-value poke ran on the
# pristine images only): Donovan's legs with the three records poked to their OWN values reproduce section 2's unpoked
# traces byte for byte, on the merged build (vsavjw) and on vs2, while the swapped traces differ under the same comparison.
for l in native ours; do
    [ "$(grep -c '^ROMPOKE ok' "$W/SAME/D.$l/mame.log")" = 3 ] && ! grep -q 'ROMPOKE FAIL' "$W/SAME/D.$l/mame.log" \
        && cmp -s "$W/D.$l/f.ft" "$W/SAME/D.$l/f.ft" && ! cmp -s "$W/D.$l/f.ft" "$W/S/D.$l/f.ft" \
        && ok "Donovan $l: its own three records poked back (verified) reproduce the unpoked trace; the swapped trace differs" \
        || bad "Donovan $l: the own-value poke changed the trace, a write did not verify, or the swapped trace equals the unpoked one"
done
_red() { awk '{print $4}' "$1" | tr '\n' ' '; }   # the hit lines: hit f<frame> red -<n> node <chain>
JSWAP="$W/C.vsavj.swap.hits"; VSWAP="$W/C.vsav2.swap.hits"
if [ "$MODE" = counterfactual-skipped ]; then JSWAP="$W/C.vsavj.base.hits"; VSWAP="$W/C.vsav2.base.hits"; fi
[ "$(_red "$JSWAP")" = "$(_red "$W/C.vsav2.base.hits")" ] \
    && ok "vsavj with vs2's three records deals vs2's damage: $(_red "$JSWAP")" \
    || bad "vsavj with vs2's records deals $(_red "$JSWAP")against vs2's $(_red "$W/C.vsav2.base.hits")"
[ "$(_red "$VSWAP")" = "$(_red "$W/C.vsavj.base.hits")" ] \
    && ok "vs2 with vsavj's three records deals vsavj's damage: $(_red "$VSWAP")" \
    || bad "vs2 with vsavj's records deals $(_red "$VSWAP")against vsavj's $(_red "$W/C.vsavj.base.hits")"
if [ -z "$MODE" ]; then
    if [ "$(_red "$W/C.vsavj.base.hits")" != "$(_red "$W/C.vsav2.base.hits")" ]; then
        vs_ctl_fired counterfactual-skipped "the unpoked games deal $(_red "$W/C.vsavj.base.hits")and $(_red "$W/C.vsav2.base.hits")— the swap's equality is something the comparison can refuse"
    else vs_ctl_dead counterfactual-skipped "the unpoked games already deal the same damage; the swap proves nothing" || fail=1; fi
fi

if [ "$fail" = 0 ]; then echo "PASS: audit_dmg_legacy_sweep"; else echo "FAIL: audit_dmg_legacy_sweep"; exit 1; fi
