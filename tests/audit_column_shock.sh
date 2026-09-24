#!/bin/sh
# audit_column_shock.sh — DONOVAN'S KILLSHREAD LIGHTNING COLUMN PLAYS vs2's CLASS-0x52 RULE ON OUR BUILD (since the 14z-170 fix, ruled 2026-09-18): the victim shocked 24 frames and Donovan exempt, every +0x5C write of both fighters equal to native's in frame and value, the move's timeline equal, and a column KO taking the same path (class 8, no exception). Until 14z-170 it froze the DEFECT as measured (14z-168, GitHub #136): 12 frames and Donovan frozen 4, from 14z-33's 0x52 -> 0x06 remap reaching 14z-42's Lightning Sword thunks.
#
# WHAT: Donovan's Killshread Lightning column plays vs2's class-0x52 rule on our build
#   (since the 14z-170 fix): the victim shocked 24 frames and Donovan exempt, every +0x5C
#   write of both fighters equal to native's in frame and value, the move's timeline equal,
#   and a column KO taking the same class-8 path with no exception.
# HOW: four non-debug write-tap runs and two field traces of the committed #136 rig
#   donovan_4 on MAME, both legs real cursor picks with the parity gate's pins; every write
#   to P1's and P2's +0x5C over 2836-2852 is frozen with its writer PC and value, plus a
#   timeline row per leg; section 1b pokes P2 to 1 HP and traces the KO on both legs; the
#   control plants the pre-fix values (12 and 4) into our rows.
# EXPECTS: our writes equal native's frame for frame, the timelines equal, the KO path equal
#   and exception-free; the planted pre-fix shape fails. A red is the remap class back.
#
# MUST-FIRE: perturbed-copy: old-shock — a copy of our rows with the pre-fix mechanism planted (the victim's hit writes 24 -> 12, a 4 written to Donovan's +0x5C at each hit — the 14z-42 Lightning Sword values the column took until 14z-170) must FAIL the native-equality check, so "equal to native" is a comparison of the two legs' writes (in-gate: the planted copy must be caught; mode: our rows are planted before the checks and the gate FAILs)
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
# THE FIX (14z-170, DECISIONS_HISTORY.md "the column shock and the Plasma Trap take vs2's class-0x52 rule"):
# the column's records keep native 0x52; reaction_hook case 0xA4 writes the marker 0x38 into +0x54;
# the ls_freeze thunks give 0x38 vsav's default victim freeze 0x18 and skip the attacker's
# (docs/game/engine_internals.md, "The fix as built"). The KO branch: es_type51_dispatch routes 0x52 to
# vsavj's KO handler 0x0186E0 (class 8) — section 1b, a column KO (P2's HP poked to 1 on both words
# at 2826 and 2830), traced on both legs: the same frames, fields and class, and no exception on ours.
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
# Usage: ROMDIR=... [MAME_BIN=...] [BUILD=build/m3b_merged27] [FREEZE=1] tests/audit_column_shock.sh
#   emulator tier, MAME; four tap runs, then two field traces — measured 14z-168 on this MacBook, solo: ~12 s wall
set -eu
[ -n "${ROMDIR:-}" ] || { echo "FAIL: set ROMDIR"; exit 1; }
[ -d "$ROMDIR" ] && ROMDIR="$(cd "$ROMDIR" && pwd)"
REPO="$(cd "$(dirname "$0")/.." && pwd)"
MAME_BIN="${MAME_BIN:-$HOME/.cache/vampire-saved/mame/cps2}"; export MAME_BIN
BUILD="${BUILD:-build/m3b_merged27}"
case "$BUILD" in /*) ;; *) BUILD="$REPO/$BUILD" ;; esac
EXPECT="$REPO/tests/expected/column_shock.tsv"
CONTROL="${CONTROL:-}"
[ -x "$MAME_BIN" ] || { echo "SKIP: no MAME at $MAME_BIN"; exit 0; }
[ -f "$ROMDIR/vsav2.zip" ] || { echo "SKIP: no vsav2.zip in $ROMDIR"; exit 0; }
[ -f "$BUILD/rompath/vsavjw.zip" ] || { echo "SKIP: no WIDE build at $BUILD"; exit 0; }
case "$CONTROL" in ""|old-shock) ;; *) echo "REFUSED: no control named '$CONTROL' is declared by this gate"; exit 3 ;; esac
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
old_shock() {  # old_shock <rows in> <rows out>: THE PERTURBATION — the pre-fix mechanism planted in our rows:
    # our victim's 24 at each native hit frame becomes 12, and a 4 is written to Donovan's +0x5C at each
    # (the 14z-42 Lightning Sword values the column took until 14z-170)
    awk -F'\t' 'BEGIN{OFS="\t"} NR==FNR {if ($2=="native" && $3=="p2" && $6==24) hit[$4]=1; next}
        $1=="w" && $2=="ours" && $3=="p2" && ($4 in hit) && $6==24 {$6=12; print; print "w", "ours", "p1", $4, "planted", 4; next}
        {print}' "$1" "$1" > "$2"
}
same_writes() {  # same_writes <rows>: exit 0 when ours' +0x5C writes equal native's in (fighter, frame, value)
    python3 - "$1" <<'PY'
import sys, collections
legs = collections.defaultdict(list)
for l in open(sys.argv[1]):
    t = l.rstrip("\n").split("\t")
    if t[0] == "w": legs[t[1]].append((t[2], int(t[3]), int(t[5])))
a, b = sorted(legs["native"]), sorted(legs["ours"])
if a == b and a: sys.exit(0)
na, nb = collections.Counter(a), collections.Counter(b)
print("native only:", sorted((na - nb).elements())[:6], " ours only:", sorted((nb - na).elements())[:6])
sys.exit(1)
PY
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
if [ "$CONTROL" = old-shock ]; then old_shock "$W/got.tsv" "$W/got.os" && mv "$W/got.os" "$W/got.tsv"; fi
awk -F'\t' '$2=="native" && $5=="022666" && $6==24' "$W/got.tsv" | grep -q . || bad "native: no 0x18 victim write by vs2's shock handler 0x22666 — the rig did not land the column"
awk -F'\t' '$5!="022474" && $5!="02309e" && $5!="02447c" && $5!="022558" && $5!="0231d0" && $5!="0245ae" {print "  " $0}' "$W/got.tsv" | head -12
# THE FIX'S CLAIM (14z-170): both fighters' +0x5C writes equal native's in frame and value, and the timeline
if same_writes "$W/got.tsv" > "$W/sw.txt"; then ok "ours' +0x5C writes equal native's in fighter, frame and value (vs2's 0x52 rule: the victim 24, Donovan exempt)"
else bad "ours' +0x5C writes differ from native's: $(cat "$W/sw.txt")"; fi
_tn="$(awk -F'\t' '$1=="timeline" && $2=="native" {sub(/^timeline\tnative\t/, ""); print}' "$W/got.tsv")"
_to="$(awk -F'\t' '$1=="timeline" && $2=="ours" {sub(/^timeline\tours\t/, ""); print}' "$W/got.tsv")"
[ -n "$_tn" ] && [ "$_tn" = "$_to" ] && ok "the move's timeline equals native's ($_to)" || bad "timeline: ours '$_to' vs native '$_tn'"
old_shock "$W/got.tsv" "$W/ctl.tsv"
if [ "$CONTROL" != old-shock ]; then
    if same_writes "$W/ctl.tsv" > /dev/null; then echo "CONTROL DEAD: old-shock — the planted pre-fix mechanism still reads equal to native"; fail=1
    else echo "CONTROL FIRED: old-shock — the planted pre-fix mechanism (victim 12, Donovan 4) fails the native-equality check"; fi
fi

echo "== 1b. the KO branch: a column KO on both legs (P2's HP poked to 1 on both words)"
ko_trace() {  # ko_trace <name> <set> <rompath> <rpl> <out.ft>   (background)
    mkdir -p "$W/$1"
    ( set +e; cd "$W/$1" && MAME_SANDBOX="$W/$1/sb" MAME_ROMPATH="$3" REPLAY="$4" \
        POKES="$(pokes_for "$j" 3100);2826:ff8850:0001;2826:ff8852:0001;2830:ff8850:0001;2830:ff8852:0001" \
        FIELDS="ff8854:b:cls,ff8850:w:hp,ff8852:w:white,ff8807:b:sub,ff891f:b:dead,ff0000:w:exc,ff8406:b:p1seq" \
        FIELD_OUT="$5" FIELD_FROM=2830 FIELD_TO=3100 FRAMES=3100 \
        "$REPO/tools/run_mame.sh" "$2" -autoboot_script "$REPO/tests/lua/field_trace.lua" > "$W/$1/mame.log" 2>&1
      _st=$?; grep -q -E '^(FIELDSUMMARY|END )' "$5" 2>/dev/null && _st=0; echo $_st > "$W/$1/rc"; rm -rf "$W/$1/sb" ) </dev/null &
}
ko_trace kn vsav2  "$ROMDIR" "$W/native.rpl" "$W/ko_native.ft"
ko_trace ko vsavjw "$ORP"    "$W/ours.rpl"   "$W/ko_ours.ft"
wait
for t in kn ko; do _rc="$(cat "$W/$t/rc" 2>/dev/null || echo none)"; [ "$_rc" = 0 ] || bad "KO trace $t exited $_rc"; done
python3 - "$W" >> "$W/got.tsv" 2> "$W/err" <<'PY' || bad "KO: $(cat "$W/err")"
import sys
W = sys.argv[1]
rows = {}
for leg in ("native", "ours"):
    d = {}
    for l in open(f"{W}/ko_{leg}.ft"):
        t = l.split()
        if t and t[0] == "F": d[int(t[1])] = tuple(sorted(t[2:]))
    if 2830 not in d or max(d) < 3099: sys.exit(f"VOID: {leg} KO trace incomplete")
    rows[leg] = d
    kv = {f: dict(x.split("=", 1) for x in v) for f, v in d.items()}
    ko = next((f for f in sorted(kv) if kv[f]["dead"] != "0"), None)
    if ko is None: sys.exit(f"VOID: {leg} the column did not KO (P2's death flag never set)")
    exc = max(int(kv[f]["exc"]) for f in kv)
    print(f"ko\t{leg}\tko_frame={ko}\tcls={kv[ko]['cls']}\texc_max={exc}")
if rows["native"] != rows["ours"]:
    diff = [f for f in sorted(rows["native"]) if rows["native"][f] != rows["ours"].get(f)]
    sys.exit(f"the KO traces differ from frame {diff[0]}: native {rows['native'][diff[0]]} ours {rows['ours'].get(diff[0])}")
PY
grep '^ko' "$W/got.tsv" | sed 's/^/  /'
awk -F'\t' '$1=="ko" && $2=="ours" && $5!="exc_max=0"' "$W/got.tsv" | grep -q . && bad "ours: an exception was raised on the KO path"
awk -F'\t' '$1=="ko"' "$W/got.tsv" | grep -q . && [ "$fail" = 0 ] && ok "the column KO takes the same path on both legs (every traced field, every frame), no exception"

echo "== 2. the frozen rows"
if [ "${FREEZE:-0}" = 1 ]; then
    {
        echo "# tests/expected/column_shock.tsv — every write to both fighters' hit-freeze byte +0x5C around Killshread Lightning [MP]'s"
        echo "# first column hit (#136 rig donovan_4, event 1 at 2800), ours ($(basename "$BUILD")) vs native vsav2 (tests/audit_column_shock.sh;"
        echo "# tests/lua/read_tap.lua, non-debug), the move's timeline, and a column KO. Evidence class: in-emulator. Frozen with FREEZE=1:"
        echo "# first 14z-168 (the defect as measured), re-frozen 14z-170 on the class-0x52 fix (ours' writes equal native's in"
        echo "# frame and value; the placed thunk PCs move with a freeze)."
        echo "# Columns: w <leg> <who> <frame> <writer PC> <value> | timeline <leg> hits= special= p1_neutral= p2_neutral= gap= | ko <leg> ko_frame= cls= exc_max="
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
if [ "$CONTROL" = old-shock ]; then
    if [ "$fail" = 1 ]; then echo "CONTROL FIRED: old-shock — the planted pre-fix mechanism fails the gate"; echo "FAIL: audit_column_shock (control mode)"; exit 1
    else echo "CONTROL DEAD: old-shock — the planted rows passed"; echo "FAIL: audit_column_shock"; exit 1; fi
fi

if [ "$fail" = 0 ]; then echo "PASS: audit_column_shock"; else echo "FAIL: audit_column_shock"; exit 1; fi
