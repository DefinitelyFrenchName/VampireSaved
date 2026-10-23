#!/bin/sh
# audit_dmg_legacy_sweep.sh — DEMITRI'S 2HK/5HP/623HP TAKE MORE HP ON VSAVJ THAN ON VSAV2 FROM ALMOST EVERY LEGACY VICTIM, with no port in the loop, BECAUSE VS2 LOWERED HIS OWN ATTACK RECORDS (10/14/20 -> 9/13/18) — each game given the other's records takes the other's damage on 14 of the 16 legacy victims, both sides (not on Sasquatch 0x0A, whose defense row differs, nor Oboro 0x18, whose hits land differently), 14z-187b; so Donovan's 9-against-8 on our build is vsavj's Demitri, not ours (GitHub #191, ruled not-ours 2026-10-01). ~~the two ENGINES'~~ RETRACTED 14z-187b: on these three hits the damage follows the record, on 14 of the 16 legacy victims (section 5); whether the engines ever differ on a record-equal hit is not claimed (Sasquatch 0x0A's rows stay apart with equal records).
#
# WHAT: Demitri's 2HK, 5HP and 623HP on every legacy victim, from P1 and from P2, on pristine vsavj
#   against pristine vsav2, and on Donovan (P1) on our merged build against native vs2; since #295 (14z-205) the
#   same 32 legacy legs on OUR merged build against pristine vsavj, exact (the superset invariant on these hits); and WHY the
#   games differ: those hits' own attack records, swapped between the games, swap the damage — the
#   record of #191 (the maintainer: "1) close as not ours 2) document with the other engine
#   differences between vsavj and VS2", 2026-10-01).
# HOW: 175 MAME runs, six at a time (section 2's 98: 16 legacy victims x 3 legs x 2 sides and Donovan's two; section 5's 74;
#   section 6's one, and its control's two 60-frame runs); the ours legs pass `-verbose` (#291 S4-A): 16 legacy victims x vsavj/vsav2/ours x 2 sides on the 14z-186
#   control's two replays (victim and Demitri by the early-window forced picks, the victim's HP
#   pinned to 288 sixty frames before each hit, the level pinned 6 from 2000 and the RNG word
#   0000 from 2363), and Donovan's 14z-186 probe-12 rig on native vs2 and ours (the parity
#   gates' cursor path and pins); tools/dmg_sweep.py reads every line of every trace into one row
#   per hit (red and white HP lost, first-drop frame, the attacker's id and the victim's
#   reaction class there); the damage pipeline's tables compared between the two games' data
#   images; section 5 reads the three hits' attack records on both games (tools/dmg_sweep.py
#   records) and replays one leg per game with those bytes set to the other game's values through
#   tests/lua/rom_poke.lua (verified writes, an own-value poke as the inert control on each of
#   the three images: vsavj and vs2 on victim 0x00's leg, the merged build and vs2 on Donovan's). Section 6 (#295)
#   compares each ours legacy trace with the same run's vsavj trace byte for byte (tools/dmg_sweep.py ours) and the
#   rows hit for hit, and runs one ours leg (P1, victim 0x00) with vs2's three records through rom_poke.lua.
# EXPECTS: every leg's forced ids as traced, Demitri the attacker at every hit, the defense rows
#   differing only for ids 0a 10 13 19 1a with the attack table and the 2D map equal, and every
#   row equal to tests/expected/dmg_legacy_sweep.tsv (on 2026-10-01: vsavj one more red HP on 2HK
#   on 14 of the 15 victims hit, Victor 0x03 alone equal, Oboro 0x18's 2HK no hit on vsavj; the
#   same on both sides; Donovan 9 ours / 8 native); the three records differ, each game poked to the
#   other's records deals the other's damage hit for hit (vsavj 9/13/19, vs2 8/12/17 on victim 0x00),
#   the hits are the record chains' nodes; over the WHOLE sweep (64 swapped legs) 176 of 192 rows equal
#   the other game's frozen row, the 16 others exactly Sasquatch 0x0A's and Oboro 0x18's; Donovan's
#   own legs swapped (ours given vs2's records, native given vsavj's) read the other leg's frozen rows,
#   8 of 8, and his own-value legs reproduce their unpoked traces; on our build every legacy leg's trace is
#   byte-identical to vsavj's, 32 of 32, and its rows equal vsavj's, 96 of 96 hits, each leg running $BUILD's
#   vsavjw.zip (section 6, not frozen: judged against the same run's vsavj legs, which section 4 holds); all six
#   controls fire.
# FOLLOWS: build/manifest/ emu/mame-patches/ tests/expected/dmg_legacy_sweep.tsv tests/replays/dmg191/
#   tests/expected/registry.tsv tests/lib/controls.sh tests/lua/field_trace.lua tools/dmg_sweep.py
#   tools/build_fingerprint.py tools/cps2_decrypt.py tools/run_mame.sh tools/setup_mame.sh
#   tests/lua/rom_poke.lua tools/audit_same_data_p2.py tools/hitbox_records.py tools/anim_nodes.py tests/lib/sheet.sh
#
# SHEET: legs vsavj,vs2,ours — moments: each judged hit at each leg's own first red-drop frame: Demitri's 2HK/5HP/623HP on every legacy victim from both sides (pristine vsav2 above pristine vsavj above ours, #295), Donovan's four events (native vs2 above ours), each proven on that leg's own field trace; and section 5's counterfactual on victim 0x00 (each game unpoked and with the other game's records, through rom_poke.lua), EVENT-PROVEN on that leg's own field log around each hit — not comparable: vs2 against vsavj on the legacy sheets (the engine difference #191 records; ours against vsavj is exact, #295); each game's stage and palette, and the victims' art (each game's own copy; [VSP-168]); the whole-sweep swap (64 legs) and Donovan's swapped legs are judged as row equalities and not drawn
#
# MUST-FIRE: perturbed-copy: engines-agree — the rows with every vsavj total replaced by its vsav2 twin's (what two games that agreed would read) must FAIL the frozen compare, so the +1 between the GAMES is read from the rows, not assumed (in-gate: the perturbed rows must differ from the frozen ones; mode: the perturbed rows are the gate's rows and the compare FAILs)
# MUST-FIRE: perturbed-copy: attacker-swapped — the reader run with the attacker id read as 0x03 at every hit must report every hit as not Demitri's, so "the hit was Demitri's 2HK" is something the gate can refuse (in-gate: the reader on the real traces with the perturbation must exit non-zero; mode: the gate's own read is perturbed and the gate FAILs)
# MUST-FIRE: perturbed-copy: counterfactual-skipped — the unpoked vsavj and vs2 legs must deal DIFFERENT damage, so "each game poked to the other's records deals the other's damage" is an equality the comparison can refuse (in-gate: the unpoked legs differ; mode: the unpoked traces stand in for the poked ones and the gate FAILs)
# MUST-FIRE: perturbed-copy: ours-diverged — the ours rows with one more red HP on P1/victim 0x00's 2HK (a planted one-HP difference) must fail section 6's comparison with vsavj, so "ours equals vsavj hit for hit" is something the gate can refuse (#295; in-gate: tools/dmg_sweep.py ours --perturb ours-diverged must exit non-zero naming that hit; mode: the perturbed rows are the ones compared and the gate FAILs)
# MUST-FIRE: perturbed-copy: ours-records-swapped — our build on P1/victim 0x00 with vs2's three attack records written through rom_poke.lua (every write verified) must deal different damage and fail section 6's comparison, so the comparison refuses a real difference on the real instrument, not only a planted row (#295; it does not show the leg ran OUR build: the mame.log check does; in-gate: that trace in place of the ours leg must fail naming the leg; mode: it stands in for the ours leg and the gate FAILs)
# MUST-FIRE: known-bad: zip-check-blind — an ours leg run as on a host whose mame.ini does not set `verbose` (`-noreadconfig`, and not the gate's own `-verbose`) shows NO `opened archive file` line, so section 6's ran-our-build check rests on the `-verbose` the gate passes, never on the user's file (#291 S4-A: on PILOT and ERIS the check read 0 of 32; in-gate: a 60-frame ours run with `-noreadconfig` shows none of the 25 lines the same run shows with `-noreadconfig -verbose`; mode: the 32 ours legs run that way and section 6 FAILs)
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
# #295 (14z-205; the maintainer, reading this gate's sheet: "Why are we not making the same tests with vsavj vs vsavjw?
# ... since it's about vsavj characters I fail to see the value" of vs2 alone): the gate was built for #191, an engine
# difference between the two ORIGINAL games, and ran our build only on Donovan's legs; these legacy hits were in no
# superset check (the 53-replay legacy oracle holds none of tests/replays/dmg191/). Section 6 adds them, judged exact
# against vsavj on the same rig (rule-checker runs 2026-10-19-1139, the plan, resolved). The legs start from poked ids
# after select, so the select screen and a cursor pick on our wheel stay the whole-RAM oracle's.
#
# NOT COVERED: WHERE in vsavj's pipeline the point is added (the ticket's open question, as for #161); the
# damage-level config byte; attackers other than Demitri and moves other than these three; Donovan as P2; whether
# the level and RNG pins change the per-game difference; FBNeo and the MiSTer core.
#
# Usage: ROMDIR=... [MAME_BIN=...] [BUILD=build/m3b_merged31] [JOBS=6] [FREEZE=1] tests/audit_dmg_legacy_sweep.sh
#   emulator tier, MAME; 175 runs of up to 4725 frames, six at a time
set -eu
[ -n "${ROMDIR:-}" ] || { echo "FAIL: set ROMDIR"; exit 1; }
[ -d "$ROMDIR" ] && ROMDIR="$(cd "$ROMDIR" && pwd)"
REPO="$(cd "$(dirname "$0")/.." && pwd)"
MAME_BIN="${MAME_BIN:-$HOME/.cache/vampire-saved/mame/cps2}"; export MAME_BIN
BUILD="${BUILD:-build/m3b_merged31}"
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
lpk() {  # lpk <side p1|p2> <victim id> — a legacy leg's forced picks and HP pins (one copy: the legs and the sheet)
    if [ "$1" = p1 ]; then echo "1400:ff8b82:$2;1450:ff8b82:$2;1500:ff8b82:$2;2940:ff8850:01200120;3380:ff8850:01200120;3780:ff8850:01200120"
    else echo "1400:ff8782:$2;1450:ff8782:$2;1500:ff8782:$2;1400:ff8b82:01;1450:ff8b82:01;1500:ff8b82:01;2940:ff8450:01200120;3380:ff8450:01200120;3780:ff8450:01200120"; fi
}
lrpl() { case "$1" in p1) echo "$REPO/tests/replays/dmg191/demitri_p1.rpl" ;; *) echo "$REPO/tests/replays/dmg191/demitri_p2.rpl" ;; esac; }
# The ours legs pass `-verbose` (#291 S4-A, 14z-206): section 6's ran-our-build check greps MAME's `opened archive file`
# line, which MAME prints only with verbose on. Until then the check passed only where the user's own mame.ini sets
# `verbose 1` (this Mac; docs/platform/gotchas.md "MAME READS THE USER'S OWN `mame.ini`") and read 0 of 32 on PILOT and
# ERIS. `-verbose` changes the log, not the run: the field traces are what the gate compares.
OURS_VERBOSE="-verbose"; [ "$MODE" = zip-check-blind ] && OURS_VERBOSE="-noreadconfig"
LFIELDS="ff8450:w:p1hp,ff8452:w:p1white,ff8454:b:p1cls,ff8850:w:p2hp,ff8852:w:p2white,ff8854:b:p2cls,ff8782:b:id,ff8b82:b:p2id"
lleg() {  # lleg <side p1|p2> <victim id> <vsavj|vsav2|ours> — ours: our merged build ($BUILD's vsavjw), the same inputs (#295)
    _s="$1"; _v="$2"; _g="$3"; _d="$W/L.$_s.$_v.$_g"; mkdir -p "$_d"
    _pk="$(lpk "$_s" "$_v")"; _r="$(lrpl "$_s")"
    _set="$_g"; _rp="$ROMDIR"; _vx=""; [ "$_g" = ours ] && { _set=vsavjw; _rp="$BUILD/rompath;$ROMDIR"; _vx="$OURS_VERBOSE"; }
    ( cd "$_d" && MAME_SANDBOX="$_d/sb" MAME_ROMPATH="$_rp" REPLAY="$_r" POKES="$LV;$_pk" \
        FIELDS="$LFIELDS" \
        FIELD_OUT="$_d/f.ft" FIELD_FROM=2300 FIELD_TO=4100 FRAMES=4100 \
        "$REPO/tools/run_mame.sh" "$_set" -autoboot_script "$REPO/tests/lua/field_trace.lua" $_vx > "$_d/mame.log" 2>&1; rm -rf "$_d/sb" ) </dev/null
}
DFIELDS="ff8450:w:p1hp,ff8452:w:p1white,ff8454:b:p1cls,ff8782:b:id,ff8b82:b:p2id"
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
        FIELDS="$DFIELDS" \
        FIELD_OUT="$_d/f.ft" FIELD_FROM=2300 FIELD_TO="$_fr" FRAMES="$_fr" \
        "$REPO/tools/run_mame.sh" "$_set" -autoboot_script "$REPO/tests/lua/field_trace.lua" > "$_d/mame.log" 2>&1; rm -rf "$_d/sb" ) </dev/null
}
echo "== 2. the legs (16 victims x vsavj/vsav2/ours x Demitri on P1/P2; Donovan native/ours $(basename "$BUILD")), $JOBS at a time"
n=0
for s in p1 p2; do for v in $IDS; do for g in vsavj vsav2 ours; do
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
CPK="1400:ff8b82:00;1450:ff8b82:00;1500:ff8b82:00;2940:ff8850:01200120;3380:ff8850:01200120;3780:ff8850:01200120"
CFIELDS="ff841c:l:node,ff8850:w:p2hp,ff8852:w:p2white,ff8782:b:id,ff8b82:b:p2id"
cleg() {  # cleg <vsavj|vsav2> <tag> <ROMPOKE>
    _g="$1"; _d="$W/C.$_g.$2"; mkdir -p "$_d"
    _pk="$CPK"
    ( cd "$_d" && MAME_SANDBOX="$_d/sb" MAME_ROMPATH="$ROMDIR" REPLAY="$REPO/tests/replays/dmg191/demitri_p1.rpl" POKES="$LV;$_pk" \
        ROMPOKE="$3" FIELDS="$CFIELDS" \
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

echo "== 6. our build against vsavj on every legacy leg (#295: the superset invariant on these hits)"
# The same 32 legs as section 2's vsavj legs, on our merged build: each trace must be BYTE-IDENTICAL to the same run's
# vsavj trace (2300-4100, every field) and each row equal hit for hit (red, white, first drop frame, attacker, class).
# The vsavj legs are held by the frozen rows (section 4); the ours rows are judged against them and not frozen.
if [ -z "$MODE" ]; then   # control zip-check-blind: without -verbose and without the user's file, the line is not printed
    for _zv in blind verbose; do
        _zd="$W/Z.$_zv"; mkdir -p "$_zd"; _zx="-noreadconfig"; [ "$_zv" = verbose ] && _zx="-noreadconfig -verbose"
        ( cd "$_zd" && MAME_SANDBOX="$_zd/sb" MAME_ROMPATH="$BUILD/rompath;$ROMDIR" FIELDS="ff8450:w:p1hp" \
            FIELD_OUT="$_zd/f.ft" FIELD_FROM=1 FIELD_TO=60 FRAMES=60 \
            "$REPO/tools/run_mame.sh" vsavjw -autoboot_script "$REPO/tests/lua/field_trace.lua" $_zx > "$_zd/mame.log" 2>&1
          rm -rf "$_zd/sb" ) </dev/null
    done
    _zb="$(grep -cF "opened archive file $BUILD/rompath/vsavjw.zip" "$W/Z.blind/mame.log" || true)"
    _zw="$(grep -cF "opened archive file $BUILD/rompath/vsavjw.zip" "$W/Z.verbose/mame.log" || true)"
    if [ "$_zb" = 0 ] && [ "$_zw" -gt 0 ]; then
        vs_ctl_fired zip-check-blind "a 60-frame ours run with -noreadconfig shows 0 'opened archive file' lines, with -noreadconfig -verbose $_zw: the check rests on the gate's own -verbose"
    else vs_ctl_dead zip-check-blind "with -noreadconfig the run shows $_zb such lines, with -verbose $_zw: the check cannot tell a host without verbose" || fail=1; fi
fi
_ol=0; for s in p1 p2; do for v in $IDS; do
    grep -qF "opened archive file $BUILD/rompath/vsavjw.zip" "$W/L.$s.$v.ours/mame.log" && _ol=$((_ol + 1))
done; done
[ "$_ol" = 32 ] && ok "all 32 ours legs ran $(basename "$BUILD")'s vsavjw.zip (each mame.log)" \
    || bad "only $_ol of the 32 ours legs show MAME opening $BUILD/rompath/vsavjw.zip"
# the records-swapped leg (control ours-records-swapped): ours on P1 against victim 0x00 with vs2's three attack records
# at vsavj's addresses (section 5's JV values, the ones Donovan's ours swap uses), every write verified
_od="$W/O.swap"; mkdir -p "$_od"
( cd "$_od" && MAME_SANDBOX="$_od/sb" MAME_ROMPATH="$BUILD/rompath;$ROMDIR" REPLAY="$(lrpl p1)" POKES="$LV;$(lpk p1 00)" \
    ROMPOKE="$JV_2,$JV_5,$JV_623" FIELDS="$LFIELDS" FIELD_OUT="$_od/f.ft" FIELD_FROM=2300 FIELD_TO=4100 FRAMES=4100 \
    "$REPO/tools/run_mame.sh" vsavjw -autoboot_script "$REPO/tests/lua/rom_poke.lua" > "$_od/mame.log" 2>&1; rm -rf "$_od/sb" ) </dev/null
OARGS=""
[ "$MODE" = ours-diverged ] && OARGS="--perturb ours-diverged"
[ "$MODE" = ours-records-swapped ] && OARGS="--leg-from ours.p1.00=$_od/f.ft"
if python3 "$REPO/tools/dmg_sweep.py" ours "$W" $OARGS > "$W/ours.txt" 2> "$W/ours_problems.txt"; then
    ok "$(head -1 "$W/ours.txt")"
else
    bad "our build differs from vsavj on a legacy leg, or a leg is structurally wrong:"
    sed 's/^/        /' "$W/ours.txt" "$W/ours_problems.txt" | head -40
fi
if [ -z "$MODE" ]; then
    if python3 "$REPO/tools/dmg_sweep.py" ours "$W" --perturb ours-diverged > "$W/ours_div.txt" 2>&1; then
        vs_ctl_dead ours-diverged "the ours rows with one more red HP on P1/0x00's 2HK still read equal to vsavj's" || fail=1
    elif grep -q '^DIFF legacy p1 00 2HK: ours red' "$W/ours_div.txt"; then
        vs_ctl_fired ours-diverged "one more red HP on P1/0x00's 2HK is refused: $(grep -m1 '^DIFF legacy p1 00 2HK' "$W/ours_div.txt" | cut -c1-120)"
    else vs_ctl_dead ours-diverged "the planted row failed without naming P1/0x00's 2HK: $(head -3 "$W/ours_div.txt" | tr '\n' ' ' | cut -c1-160)" || fail=1; fi
    if [ "$(grep -c '^ROMPOKE ok' "$_od/mame.log")" = 3 ] && ! grep -q 'ROMPOKE FAIL' "$_od/mame.log" \
            && ! python3 "$REPO/tools/dmg_sweep.py" ours "$W" --leg-from "ours.p1.00=$_od/f.ft" > "$W/ours_swap.txt" 2>&1 \
            && grep -q '^DIFF legacy p1 00 ' "$W/ours_swap.txt"; then
        vs_ctl_fired ours-records-swapped "our build with vs2's three records (verified) deals $(python3 -c "import sys; sys.path.insert(0, '$REPO/tools'); import dmg_sweep as d; R = d.load('$_od/f.ft')[0]; print('/'.join(str(sum(x for _, x in d.drops(R, 'p2hp', lo, hi))) for _, lo, hi in d.WIN))") on P1/0x00 and is refused"
    else vs_ctl_dead ours-records-swapped "the swapped leg's writes did not verify, or its trace still read equal to vsavj's" || fail=1; fi
fi

# THE SHEET (#291, D2): with SHEET_OUT set, the legs this run judged and one moment per judged hit — the legacy legs
# and Donovan's on each leg's own field trace (basis fields), section 5's counterfactual legs re-run under their own
# rom_poke.lua (basis event on each leg's own field log). Nothing the gate decides changes.
. "$REPO/tests/lib/sheet.sh"
if sheet_on && [ -z "$MODE" ]; then
    for s in p1 p2; do for v in $IDS; do
        sheet_new "L.$s.$v" "Demitri's 2HK/5HP/623HP from $s on victim 0x$v: pristine vsav2 above pristine vsavj above ours" - "#191, #295" \
            "vs2 against vsavj is the engine difference #191 records (vs2 lowered Demitri's own records); ours against vsavj is exact (#295); each game's stage, palette and art"
        sheet_leg "L.$s.$v" v2 vs2 vsav2 "$ROMDIR" "$(lrpl "$s")" "$LV;$(lpk "$s" "$v")" 4100
        sheet_leg "L.$s.$v" vj vsavj vsavj "$ROMDIR" "$(lrpl "$s")" "$LV;$(lpk "$s" "$v")" 4100
        sheet_leg "L.$s.$v" ours ours vsavjw "$BUILD/rompath;$ROMDIR" "$(lrpl "$s")" "$LV;$(lpk "$s" "$v")" 4100
    done; done
    _dj="$RD/donovan_p12.json"; _dfr="$(python3 -c "import json;print(json.load(open('$_dj'))['frames'])")"
    _dpk="$(python3 -c "import json;print(';'.join(json.load(open('$_dj'))['pokes']))")"
    sheet_new D "Donovan (P1) against Demitri's 2HK/5HP/623HP: native vs2 above ours" donovan "#191" \
        "each game's stage and palette, and Demitri's art (each game's own copy; [VSP-168])"
    sheet_leg D native vs2 vsav2 "$ROMDIR" "$W/D.native/r.rpl" "$_dpk;$LV" "$_dfr"
    sheet_leg D ours ours vsavjw "$BUILD/rompath;$ROMDIR" "$W/D.ours/r.rpl" "$_dpk;$LV" "$_dfr"
    sheet_new C "Section 5: Demitri on victim 0x00, each game unpoked and with the OTHER game's three attack records" - "#191" \
        "no leg of ours: the counterfactual runs on pristine vsavj and vsav2; each game's stage, palette and art"
    for g in vsavj vsav2; do
        if [ "$g" = vsavj ]; then _ro=vsavj _sw="$JV_2,$JV_5,$JV_623"; else _ro=vs2 _sw="$VJ_2,$VJ_5,$VJ_623"; fi
        for tg in base swap; do
            _rk=""; [ "$tg" = swap ] && _rk="$_sw"
            sheet_leg C "$g.$tg" "$_ro" "$g" "$ROMDIR" "$REPO/tests/replays/dmg191/demitri_p1.rpl" "$LV;$CPK" 4100
            sheet_tap C "$g.$tg" tests/lua/rom_poke.lua "ROMPOKE=$_rk;FIELDS=$CFIELDS;FIELD_FROM=2300;FIELD_TO=4100;FRAMES=4100"
            sheet_file C "$g.$tg.ft" "$W/C.$g.$tg/f.ft" > /dev/null
        done
    done
    python3 - "$W" "$REPO" "$LFIELDS" "$DFIELDS" "$_dj" "$IDS" > "$W/sheet_rows.tsv" <<'PYS'
import json, sys
W, REPO, LF, DF, DJ, IDS = sys.argv[1:7]
sys.path.insert(0, REPO + "/tools")
import dmg_sweep as ds
spec = lambda F: {name: "%s:%s" % (a, sz) for a, sz, name in (f.split(":") for f in F.split(","))}
def fields(R, f, sp):
    s = R.get(f)
    return ("fields", ",".join("%s=%d" % (sp[k], s[k]) for k in sorted(sp) if k in s)) if s else ("none", "-")
def window(R, fld, f, lo, hi):
    # S4-D (#291): the judged hit in context — 12 frames before the leg's first red drop in the judged window to 12
    # after its last (every hit the gate sums), inside that window and the trace; about 9 frames spread across it
    d = [x for x, _ in ds.drops(R, fld, lo, hi)]
    a, b = (d[0], d[-1]) if d else (f, f)
    return "%d-%d" % (max(lo, a - 12, min(R)), min(hi - 1, b + 12, max(R)))
def first_drop(R, fld, lo, hi):
    d = ds.drops(R, fld, lo, hi)
    return (d[0][0], sum(x for _, x in ds.drops(R, fld, lo, hi))) if d else (None, 0)
LS = spec(LF)
for side, m in ds.SIDE.items():
    for v in IDS.split():
        sid = "L.%s.%s" % (side, v)
        tr = {leg: ds.load("%s/L.%s.%s.%s/f.ft" % (W, side, v, g))[0] for leg, g in (("v2", "vsav2"), ("vj", "vsavj"), ("ours", "ours"))}
        for n, lo, hi in ds.WIN:
            fd = {leg: first_drop(tr[leg], m["vic"] + "hp", lo, hi) for leg in tr}
            if all(f is None for f, _ in fd.values()):
                continue
            vals = "red: vsavj %d, vs2 %d, ours %d" % (fd["vj"][1], fd["v2"][1], fd["ours"][1])
            print("moment\t%s\t%s\t%s (Demitri's first red drop on each leg)\tvsavj %+d red against vs2, ours %+d against vsavj\t%s" % (
                sid, n, n, fd["vj"][1] - fd["v2"][1], fd["ours"][1] - fd["vj"][1], vals))
            for leg in ("v2", "vj", "ours"):
                f = fd[leg][0] or next(x for x, _ in fd.values() if x)
                b, e = fields(tr[leg], f, LS)
                print("at\t%s\t%s\t%s\t%d\t%s\t%s" % (sid, n, leg, f, b, e))
                if b == "fields":
                    print("span\t%s\t%s\t%s\t%s" % (sid, n, leg, window(tr[leg], m["vic"] + "hp", f, lo, hi)))
DS = spec(DF)
ev = json.load(open(DJ))["events"]
tr = {leg: ds.load("%s/D.%s/f.ft" % (W, leg))[0] for leg in ("native", "ours")}
for k, e in enumerate(ev):
    fd = {leg: first_drop(tr[leg], "p1hp", e["frame"], e["frame"] + 120) for leg in tr}
    if all(f is None for f, _ in fd.values()):
        continue
    print("moment\tD\te%d\tevent %d (Demitri's first red drop on Donovan)\tours %+d red\tred: ours %d, native %d" % (
        k, k, fd["ours"][1] - fd["native"][1], fd["ours"][1], fd["native"][1]))
    for leg in ("native", "ours"):
        f = fd[leg][0] or next(x for x, _ in fd.values() if x)
        b, x = fields(tr[leg], f, DS)
        print("at\tD\te%d\t%s\t%d\t%s\t%s" % (k, leg, f, b, x))
        if b == "fields":
            print("span\tD\te%d\t%s\t%s" % (k, leg, window(tr[leg], "p1hp", f, e["frame"], e["frame"] + 120)))
legs = ["vsavj.base", "vsavj.swap", "vsav2.base", "vsav2.swap"]
hits = {}
for leg in legs:
    R = ds.load("%s/C.%s/f.ft" % (W, leg))[0]
    hits[leg] = [f for f in sorted(R) if f - 1 in R and R[f]["p2hp"] < R[f - 1]["p2hp"]]
    hits[leg] = [(f, R[f - 1]["p2hp"] - R[f]["p2hp"]) for f in hits[leg]]
for k, name in enumerate(("2HK", "5HP", "623HP")):
    if all(k >= len(hits[l]) for l in legs):
        continue
    vals = ", ".join("%s -%s" % (l, hits[l][k][1] if k < len(hits[l]) else "none") for l in legs)
    print("moment\tC\th%d\t%s (each leg's %s red drop)\tswap deals the other game's damage\t%s" % (k, name, ["first", "second", "third"][k], vals))
    for leg in legs:
        if k >= len(hits[leg]):
            continue
        f = hits[leg][k][0]
        # S4-D (#291): the event window is the span (spanned by default), widened from +-2 to +-4: 9 frames
        print("at\tC\th%d\t%s\t%d\tevent\tfiles/C.%s.ft:%d-%d" % (k, leg, f, leg, f - 4, f + 4))
PYS
    # S4-D (#291): each fields leg's per-frame trace, which proves every frame of its spans
    for s in p1 p2; do for v in $IDS; do
        sheet_trace "L.$s.$v" v2 "$W/L.$s.$v.vsav2/f.ft" "$LFIELDS"
        sheet_trace "L.$s.$v" vj "$W/L.$s.$v.vsavj/f.ft" "$LFIELDS"
        sheet_trace "L.$s.$v" ours "$W/L.$s.$v.ours/f.ft" "$LFIELDS"
    done; done
    sheet_trace D native "$W/D.native/f.ft" "$DFIELDS"
    sheet_trace D ours "$W/D.ours/f.ft" "$DFIELDS"
    sheet_rows "$W/sheet_rows.tsv"
fi

if [ "$fail" = 0 ]; then echo "PASS: audit_dmg_legacy_sweep"; else echo "FAIL: audit_dmg_legacy_sweep"; exit 1; fi
