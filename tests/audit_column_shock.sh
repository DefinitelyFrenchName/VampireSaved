#!/bin/sh
# audit_column_shock.sh — DONOVAN'S KILLSHREAD LIGHTNING COLUMN SHOCKS ITS VICTIM FOR 12 FRAMES ON OUR BUILD, 24 NATIVELY, and freezes Donovan 4 frames per hit where vs2 exempts him, frozen AS MEASURED (14z-168, GitHub #136): two earlier fixes compose — 14z-33 remapped the column's hit records from vs2's extended class 0x52 to 0x06, and 14z-42's Lightning Sword thunks give every Donovan hit that reaches vsavj's class-0x06 shock handler vs2's Lightning Sword tuning.
#
# MUST-FIRE: perturbed-copy: native-shock — a copy of our rows with the two thunk writes replaced by what vs2's 0x52 handler writes (the victim 0x18, no attacker write), and our timeline row replaced by native's, must FAIL the frozen compare, so the frozen rows are the defect and a fix is a deliberate re-freeze (in-gate: the perturbed copy must differ from the frozen rows; mode: our rows are rewritten before the compare and the table FAILs)
#
# WHY. #136's donovan_4 event 1 (Killshread Lightning [MP]) and donovan_10 event 9
# (the [LP] column) read DIFF at +40 / +35 on the counter: natively the column's hits
# carry class 0x52 and reach vs2's shock handler PRG:0x022656, which writes the
# victim's +0x5C = 0x18 and SKIPS the attacker's +0x5C for class 0x52 (`cmpi.b #$52`);
# on ours the class is 0x06 (donovan.toml's three 14z-33 `[[region_fix]]` rows,
# "semantically identical BY VS2'S OWN DEFINITION"), which reaches vsavj's 0x023AC8,
# and there the 14z-42 thunks `ls_freeze_vs2_victim` / `ls_freeze_vs2_attacker`
# (placed at PRG:0x3FFBB0 / 0x3FFBE0 on merged-m18) write vs2's LIGHTNING SWORD
# constants for any Donovan attacker: the victim's +0x5C = 0x0C (+0x147 = 0x0C) and
# Donovan's = 4. Damage and hit count are EQUAL (5 + 4 on the MP column); the second
# hit lands 4 frames later on ours (Donovan's own freeze). Measured 14z-168 with the
# non-debug write tap (build/p136_14z168). Nothing on record rules on it; the
# Plasma Trap's attacker freeze is the ruled precedent of the same remap class
# (14z-85g(2), tests/audit_trap_shock.sh), the victim's halved shock is not.
#
# WHAT IT FREEZES (tests/expected/column_shock.tsv): every write to P1's and P2's
# +0x5C (RAM:$FF845C / $FF885C) from 2836 to 2852 on the committed #136 rig donovan_4
# (event 1 at 2800), both legs REAL cursor picks with the parity gate's pins:
#   w <leg> <who> <frame> <writer PC> <value>
# and, since 14z-168, one row per leg of the move's TIMELINE (below):
#   timeline <leg> hits=<frames> special=<frame> p1_neutral=<frame> p2_neutral=<frame> gap=<frames>
# The maintainer, on the every-frame capture: "the move doesn't play out exactly the same since the
# timing of freeze, shock, recovery,etc. are slightly different. And I agree with your analysis."
# The fix is RULED (2026-09-18, DECISIONS_HISTORY.md "the column shock and the Plasma Trap take vs2's
# class-0x52 rule"); it re-freezes this file.
#
# Usage: ROMDIR=... [MAME_BIN=...] [BUILD=build/m3b_merged26] [FREEZE=1] tests/audit_column_shock.sh
#   emulator tier, MAME; four tap runs, then two field traces — measured 14z-168 on this MacBook, solo: ~12 s wall
set -eu
[ -n "${ROMDIR:-}" ] || { echo "FAIL: set ROMDIR"; exit 1; }
[ -d "$ROMDIR" ] && ROMDIR="$(cd "$ROMDIR" && pwd)"
REPO="$(cd "$(dirname "$0")/.." && pwd)"
MAME_BIN="${MAME_BIN:-$HOME/.cache/vampire-saved/mame/cps2}"; export MAME_BIN
BUILD="${BUILD:-build/m3b_merged26}"
case "$BUILD" in /*) ;; *) BUILD="$REPO/$BUILD" ;; esac
EXPECT="$REPO/tests/expected/column_shock.tsv"
CONTROL="${CONTROL:-}"
[ -x "$MAME_BIN" ] || { echo "SKIP: no MAME at $MAME_BIN"; exit 0; }
[ -f "$ROMDIR/vsav2.zip" ] || { echo "SKIP: no vsav2.zip in $ROMDIR"; exit 0; }
[ -f "$BUILD/rompath/vsavjw.zip" ] || { echo "SKIP: no WIDE build at $BUILD"; exit 0; }
case "$CONTROL" in ""|native-shock) ;; *) echo "REFUSED: no control named '$CONTROL' is declared by this gate"; exit 3 ;; esac
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT INT TERM
fail=0
ok()  { printf '  ok    %s\n' "$1"; }
bad() { printf '  FAIL  %s\n' "$1"; fail=1; }
PART=donovan_4; TENANT=donovan; FR=2860; LO=2836; HI=2852
# --- the rig as tests/audit_move_parity.sh builds it (pokes_for / rpl_for / OURS_PATH, copied) ---
OURS_PATH_donovan="D D DR DR"
pokes_for() {  # pokes_for <json> <frames>
    _b="$(python3 -c "import json;print(';'.join(json.load(open('$1'))['pokes']))")"
    _l="$(python3 -c "print(';'.join(f'{f}:ff8116:06' for f in range(2000,$2)))")"
    _r="$(python3 -c "print(';'.join(f'{f}:ff80d4:0000' for f in range(2363,$2)))")"
    printf '%s;%s;%s' "$_b" "$_l" "$_r"
}
rpl_for() {  # rpl_for <tenant> <rig.rpl> <leg> <out.rpl>
    if [ "$3" = native ]; then cp "$2" "$4"; return; fi
    eval "_path=\$OURS_PATH_$1"
    awk -v path="$_path" '
        /^1104-1106 p2=R$/ && !done { n = split(path, m, " "); t = 1100
            for (i = 1; i <= n; i++) { printf "%d-%d p1=%s\n", t, t + 2, m[i]; t += 60 }; done = 1 }
        /^(1100|1160|1220|1280)-[0-9]+ p1=/ { next }
        { print }' "$2" > "$4"
}
tap() {  # tap <name> <set> <rompath> <rpl> <pokes> <rtap> <out.txt>   (background)
    mkdir -p "$W/$1"
    # (14z-168) MAME can segfault at TEARDOWN after the instrument has closed its log (docs/platform/gotchas.md):
    # `set +e` keeps the status write alive, and a run whose instrument wrote its summary line counts as
    # completed (docs/project/gotchas.md, the set -e capture entry)
    ( set +e; cd "$W/$1" && MAME_SANDBOX="$W/$1/sb" MAME_ROMPATH="$3" REPLAY="$4" POKES="$5" FRAMES="$FR" \
        RTAP="$6" WINDOW=999999,999999 TRACE_OUT="$7" \
        "$REPO/tools/run_mame.sh" "$2" -autoboot_script "$REPO/tests/lua/read_tap.lua" > "$W/$1/mame.log" 2>&1
      _st=$?; grep -q -E '^(FIELDSUMMARY|END )' "$7" 2>/dev/null && _st=0; echo $_st > "$W/$1/rc"; rm -rf "$W/$1/sb" ) </dev/null &
}
reduce() {  # reduce <leg> <who> <tap>
    python3 - "$@" "$LO" "$HI" <<'PY'
import sys
leg, who, p, lo, hi = sys.argv[1], sys.argv[2], sys.argv[3], int(sys.argv[4]), int(sys.argv[5])
ended = False
for l in open(p):
    t = l.split()
    if not t: continue
    if t[0] == "END": ended = True
    if t[0] == "W" and lo <= int(t[1]) <= hi and int(t[9], 16) & 0xFF00:
        print(f"w\t{leg}\t{who}\t{t[1]}\t{t[3]}\t{(int(t[7], 16) >> 8) & 0xFF}")
if not ended: sys.exit(f"VOID: {p} has no END line (a dead tap is not evidence)")
PY
}
native_shock() {  # native_shock <rows in> <rows out>: our thunk writes replaced by vs2's 0x52 handler's, and our
    # timeline replaced by native's (what the ruled fix should read) — so the control covers both row kinds
    awk -F'\t' 'BEGIN{OFS="\t"} $1=="timeline" && $2=="native" {nt = $0}
        $2=="ours" && $5=="3ffbc4" {$5="022666"; $6=24} $2=="ours" && $5=="3ffbf4" {next}
        $1=="timeline" && $2=="ours" {held = 1; next} {print}
        END {if (held && nt != "") {sub(/^timeline\tnative/, "timeline\tours", nt); print nt}}' "$1" > "$2"
}

echo "== 1. the taps ($PART, +0x5C of both fighters, frames $LO-$HI)"
j="$REPO/tests/replays/naming/$PART.json"; r="$REPO/tests/replays/naming/$PART.rpl"
pk="$(pokes_for "$j" "$FR")"
rpl_for "$TENANT" "$r" native "$W/native.rpl"; rpl_for "$TENANT" "$r" ours "$W/ours.rpl"
ORP="$BUILD/rompath;$ROMDIR"
tap n1 vsav2  "$ROMDIR" "$W/native.rpl" "$pk" ff845c,2 "$W/native.p1.txt"
tap n2 vsav2  "$ROMDIR" "$W/native.rpl" "$pk" ff885c,2 "$W/native.p2.txt"
tap o1 vsavjw "$ORP"    "$W/ours.rpl"   "$pk" ff845c,2 "$W/ours.p1.txt"
tap o2 vsavjw "$ORP"    "$W/ours.rpl"   "$pk" ff885c,2 "$W/ours.p2.txt"
wait
for t in n1 n2 o1 o2; do _rc="$(cat "$W/$t/rc" 2>/dev/null || echo none)"; [ "$_rc" = 0 ] || bad "run $t exited $_rc (an emulator that crashed is not evidence)"; done
[ "$fail" = 0 ] || { echo "FAIL: audit_column_shock"; exit 1; }
: > "$W/got.tsv"
for leg in native ours; do for who in p1 p2; do
    reduce "$leg" "$who" "$W/$leg.$who.txt" >> "$W/got.tsv" 2> "$W/err" || bad "$leg $who: $(cat "$W/err")"
done; done
[ "$fail" = 0 ] || { echo "FAIL: audit_column_shock (a tap was VOID)"; exit 1; }
# THE TIMELINE (added 14z-168, after the maintainer asked for the whole move, input to recovery): two
# field_trace legs 2790..2990 on the same rig, reduced to the hit frames, the frame each fighter returns
# to neutral seq 0 (P1 out of the special 0x0E; P2 out of its after-hit reaction seq 2/4, shock over)
# and the gap between them — the swing a player feels. Measured first 14z-168: native 2859 / 2885 (26),
# ours 2865 / 2879 (14). The every-frame capture is build/p136_14z168/col_full (put before the maintainer).
trace() {  # trace <name> <set> <rompath> <rpl> <pokes> <out.ft>   (background)
    mkdir -p "$W/$1"
    ( set +e; cd "$W/$1" && MAME_SANDBOX="$W/$1/sb" MAME_ROMPATH="$3" REPLAY="$4" POKES="$5" \
        FIELDS="ff8406:b:seq,ff845c:b:frz,ff8806:b:p2seq,ff885c:b:p2frz,ff8850:w:p2hp" FIELD_OUT="$6" FIELD_FROM=2790 FIELD_TO=2990 FRAMES=2990 \
        "$REPO/tools/run_mame.sh" "$2" -autoboot_script "$REPO/tests/lua/field_trace.lua" > "$W/$1/mame.log" 2>&1
      _st=$?; grep -q -E '^(FIELDSUMMARY|END )' "$6" 2>/dev/null && _st=0; echo $_st > "$W/$1/rc"; rm -rf "$W/$1/sb" ) </dev/null &
}
pk_t="$(pokes_for "$j" 2990)"
trace nt vsav2  "$ROMDIR" "$W/native.rpl" "$pk_t" "$W/native.ft"
trace ot vsavjw "$ORP"    "$W/ours.rpl"   "$pk_t" "$W/ours.ft"
wait
for t in nt ot; do _rc="$(cat "$W/$t/rc" 2>/dev/null || echo none)"; [ "$_rc" = 0 ] || bad "trace $t exited $_rc"; done
[ "$fail" = 0 ] || { echo "FAIL: audit_column_shock"; exit 1; }
python3 - "$W" >> "$W/got.tsv" 2> "$W/err" <<'PY' || bad "timeline: $(cat "$W/err")"
import sys
W = sys.argv[1]
for leg in ("native", "ours"):
    d = {}
    for l in open(f"{W}/{leg}.ft"):
        t = l.split()
        if t and t[0] == "F": d[int(t[1])] = {k: int(v) for k, v in (kv.split("=", 1) for kv in t[2:])}
    if 2790 not in d or max(d) < 2989: sys.exit(f"VOID: {leg} trace incomplete")
    hits = [f for f in range(2791, 2990) if d[f]["p2hp"] < d[f - 1]["p2hp"]]
    sp = next((f for f in range(2790, 2990) if d[f]["seq"] == 0x0E), None)
    if not hits or sp is None: sys.exit(f"VOID: {leg} the column did not come out (special {sp}, hits {hits})")
    p1n = next(f for f in range(sp, 2990) if d[f]["seq"] == 0)
    p2n = next((f for f in range(hits[-1] + 1, 2990) if d[f]["p2seq"] == 0 and d[f]["p2frz"] == 0 and d[f - 1]["p2seq"] in (2, 4)), None)
    if p2n is None: sys.exit(f"VOID: {leg} P2 never returned to neutral after its reaction")
    print(f"timeline\t{leg}\thits={','.join(map(str, hits))}\tspecial={sp}\tp1_neutral={p1n}\tp2_neutral={p2n}\tgap={p2n - p1n}")
PY
[ "$fail" = 0 ] || { echo "FAIL: audit_column_shock (the timeline was VOID)"; exit 1; }
grep '^timeline' "$W/got.tsv" | sed 's/^/  /'
if [ "$CONTROL" = native-shock ]; then native_shock "$W/got.tsv" "$W/got.ns" && mv "$W/got.ns" "$W/got.tsv"; fi
awk -F'\t' '$2=="ours" && $3=="p2" && $5=="3ffbc4" && $6==12' "$W/got.tsv" | grep -q . || bad "ours: no 0x0C victim write by the placed thunk at 0x3FFBC4 — the frozen mechanism is absent"
awk -F'\t' '$2=="native" && $5=="022666" && $6==24' "$W/got.tsv" | grep -q . || bad "native: no 0x18 victim write by vs2's shock handler 0x22666 — the rig did not land the column"
awk -F'\t' '$5!="022474" && $5!="02309e" && $5!="02447c" && $5!="022558" && $5!="0231d0" && $5!="0245ae" {print "  " $0}' "$W/got.tsv" | head -12

echo "== 2. the frozen rows"
if [ "${FREEZE:-0}" = 1 ]; then
    {
        echo "# tests/expected/column_shock.tsv — every write to both fighters' hit-freeze byte +0x5C around Killshread Lightning [MP]'s"
        echo "# first column hit (#136 rig donovan_4, event 1 at 2800), ours (merged-m18) vs native vsav2 (tests/audit_column_shock.sh;"
        echo "# tests/lua/read_tap.lua, non-debug). Evidence class: in-emulator. Frozen 14z-168 with FREEZE=1. THE DEFECT IS FROZEN AS"
        echo "# MEASURED: native's 0x52 handler writes the victim 0x18 and exempts Donovan; ours' 14z-42 thunks write the victim 0x0C and"
        echo "# Donovan 4. A fix re-freezes this file DELIBERATELY, with its rule-checker run named in the commit."
        echo "# Columns: w <leg> <who> <frame> <writer PC> <value> | timeline <leg> hits= special= p1_neutral= p2_neutral= gap="
        echo "#--"
        cat "$W/got.tsv"
    } > "$EXPECT"
    echo "  FROZE  $(basename "$EXPECT") ($(wc -l < "$W/got.tsv" | tr -d ' ') rows) — VERIFY by re-running without FREEZE"; exit 0
fi
[ -f "$EXPECT" ] || { echo "FAIL: no frozen expectation at $EXPECT (FREEZE=1 to create it)"; exit 1; }
grep -v '^#' "$EXPECT" > "$W/want.tsv"
if diff "$W/want.tsv" "$W/got.tsv" > "$W/diff.txt"; then ok "every row as frozen"
else bad "differs from the frozen rows"; sed 's/^/        /' "$W/diff.txt" | head -20; fi

echo "== 3. must-fire control"
if [ "$CONTROL" = native-shock ]; then
    if [ "$fail" = 1 ]; then echo "CONTROL FIRED: native-shock — vs2's shock applied on ours loses the frozen rows"; echo "FAIL: audit_column_shock (control mode)"; exit 1
    else echo "CONTROL DEAD: native-shock — the rewrite changed nothing"; echo "FAIL: audit_column_shock"; exit 1; fi
fi
native_shock "$W/got.tsv" "$W/ctl.tsv"
if diff -q "$W/got.tsv" "$W/ctl.tsv" > /dev/null; then echo "CONTROL DEAD: native-shock — ours carries no thunk write to rewrite"; fail=1
else echo "CONTROL FIRED: native-shock — vs2's shock changes $(diff "$W/got.tsv" "$W/ctl.tsv" | grep -c '^<' | tr -d ' ') of our rows"; fi

if [ "$fail" = 0 ]; then echo "PASS: audit_column_shock"; else echo "FAIL: audit_column_shock"; exit 1; fi
