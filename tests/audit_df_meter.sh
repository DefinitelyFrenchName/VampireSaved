#!/bin/sh
# audit_df_meter.sh — NO GAUGE IS BUILT IN DARK FORCE CHANGE, and the tenants build it anyway, frozen AS MEASURED (14z-168, GitHub #157's Dark Force tail): a whiffed attack's start-up gauge (the "swing" call of the meter adder) is suppressed while +0x111 is held on vsavj, but the tenants' swings go through their placed copy of vs2's adder, which tests vs2's Dark Force Power field +0x1C3 — never set by vsav's Dark Force Change — so they gain +6 per whiffed attack in the mode.
#
# MUST-FIRE: perturbed-copy: suppressed — a copy of our tenant rows with every in-mode gauge step removed (what a fixed build gives, the shells' behaviour) must FAIL the frozen compare, so the frozen rows are the defect and a fix is a deliberate re-freeze (in-gate: the perturbed copy must differ from the frozen rows; mode: our tenant rows are rewritten before the compare and the table FAILs)
#
# WHY. The meter adder (vsavj PRG:0x29A16, vs2 0x28D48) is byte-identical in the two
# games but for the Dark Force test: vsavj `tst.b $111(a6)`, vs2 `tst.b $1c3(a6)` —
# each game's own mode field (vsavj's Dark Force Change sets +0x111, vs2's Dark Force
# Power +0x1C3; docs/game/engine_internals.md, Dark Force). Each tenant's x028122 copy
# carries vs2's adder verbatim, so under our Dark Force Change its test never sees
# the mode. The maintainer, 2026-09-18 (14z-168), on this measurement: "it makes sense
# that you can't build meter during DF" — the shells' behaviour is the rule; the
# tenants' is a defect. The 29 placed instructions that read +0x1C3 are censused
# statically by tests/test_df_field_readers.sh.
#
# THE RIG (per leg, real cursor picks, P2 Demitri kept 176 px away so every attack
# whiffs and only start-up gauge can move): j.HP at 2600 and 5HP at 2800 OUT of the
# mode, the mode at 3000 (P+K on vsavj and ours; the tenant's vs2 EX input on vsav2 —
# vs2's P+K is Dark Force Power, a different mode, audit_df_modes.sh), j.HP at 3150 and
# 5HP at 3350 IN it; X pinned at 2560 and 3120, 3 stocks at 2950, the speed level
# pinned to 6 from 2000.
#
# WHAT IT FREEZES (tests/expected/df_meter.tsv), per leg:
#   mode  <leg> <id> <+0x111 first>..<last>
#   step  <leg> <id> <frame> <P1 gauge delta> <in|out>   — every change of RAM:$FF850A
#   (in = inside the +0x111 span). The shells' in-mode swings are ABSENT; the tenants'
#   read +6 at 3164 and 3350 on ours (the defect) and on vsav2 (vs2's own EX install,
#   which does not suppress them either — vs2's adder tests +0x1C3). Gauge paid by the
#   altered attacks' HITS appears as further in-mode steps on the vsav2 legs; on ours a
#   hit pays through vsavj's own adder and is suppressed like any legacy hit.
#
# WHAT IT DOES NOT COVER: the other 26 +0x1C3 readers' consequences (the static census
# names them); P2's gauge; the gauge a HIT pays in the mode beyond these rows.
#
# Usage: ROMDIR=... [MAME_BIN=...] [BUILD=build/m3b_merged26] [FREEZE=1] tests/audit_df_meter.sh
#   emulator tier, MAME; 10 field_trace legs in parallel — measured 14z-168 on this MacBook, solo: ~25 s wall
set -eu
[ -n "${ROMDIR:-}" ] || { echo "FAIL: set ROMDIR"; exit 1; }
[ -d "$ROMDIR" ] && ROMDIR="$(cd "$ROMDIR" && pwd)"
REPO="$(cd "$(dirname "$0")/.." && pwd)"
MAME_BIN="${MAME_BIN:-$HOME/.cache/vampire-saved/mame/cps2}"; export MAME_BIN
BUILD="${BUILD:-build/m3b_merged26}"
case "$BUILD" in /*) ;; *) BUILD="$REPO/$BUILD" ;; esac
EXPECT="$REPO/tests/expected/df_meter.tsv"
CONTROL="${CONTROL:-}"
[ -x "$MAME_BIN" ] || { echo "SKIP: no MAME at $MAME_BIN"; exit 0; }
[ -f "$ROMDIR/vsav2.zip" ] || { echo "SKIP: no vsav2.zip in $ROMDIR"; exit 0; }
[ -f "$BUILD/rompath/vsavjw.zip" ] || { echo "SKIP: no WIDE build at $BUILD"; exit 0; }
[ -f "$BUILD/verify_data.bin" ] || { echo "SKIP: no verify_data.bin at $BUILD"; exit 0; }
case "$CONTROL" in ""|suppressed) ;; *) echo "REFUSED: no control named '$CONTROL' is declared by this gate"; exit 3 ;; esac
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT INT TERM
fail=0
ok()  { printf '  ok    %s\n' "$1"; }
bad() { printf '  FAIL  %s\n' "$1"; fail=1; }
FR=3600
PK="2560:ff8410:0228;2560:ff8810:02d8;2950:ff8509:03;3120:ff8410:0228;3120:ff8810:02d8;$(python3 -c "print(';'.join(f'{f}:ff8116:06' for f in range(2000,$FR)))")"
FIELDS="ff850a:w:meter,ff8511:b:f111,ff8782:b:id"
act_lines() {  # act_lines <game> <id>: the mode's activation at 3000
    if [ "$1" != vsav2 ]; then echo "3000-3004 p1=14"; return; fi
    case $2 in   # the tenants' vs2 EX inputs (measured 14z-168; audit_df_modes.sh)
        13) printf '%s\n' "3000-3002 p1=L" "3004-3006 p1=D" "3008-3012 p1=DL" "3010-3014 p1=46" ;;
        10) printf '%s\n' "3000-3002 p1=D" "3004-3006 p1=R" "3008-3012 p1=DR" "3010-3014 p1=13" ;;
        11) printf '%s\n' "3000-3002 p1=D" "3004-3006 p1=R" "3008-3010 p1=D" "3012-3016 p1=DR" "3014-3018 p1=13" ;;
    esac
}
leg() {  # leg <game> <id>   (background)
    _g=$1; _id=$2
    case $_g in vsav2) _set=vsav2; _rp="$ROMDIR"; _wh="$W/wheel_vsav2.json" ;;
                vsavj) _set=vsavj; _rp="$ROMDIR"; _wh="$W/wheel_vsavj.json" ;;
                ours)  _set=vsavjw; _rp="$BUILD/rompath;$ROMDIR"; _wh="$W/wheel_ours.json" ;; esac
    _path="$(python3 "$REPO/tools/select_paths.py" "$_wh" --cell "$_id" --player 1 | sed 's/^P1 0x[0-9a-f]*: *//')"
    _r="$W/${_g}_$_id.rpl"
    { printf '%s\n' "300-305 sys=C1" "420-425 sys=C2" "800-803 sys=S1" "940-943 sys=S2"
      _t=1100; for _mv in $_path; do echo "$_t-$((_t+2)) p1=$_mv"; _t=$((_t+60)); done
      printf '%s\n' "1104-1106 p2=R" "1300-1302 p1=1" "1360-1362 p2=1" \
          "2600-2602 p1=U" "2614-2617 p1=3" "2800-2802 p1=3"
      act_lines "$_g" "$_id"
      printf '%s\n' "3150-3152 p1=U" "3164-3167 p1=3" "3350-3352 p1=3" "$FR wait"; } > "$_r"
    mkdir -p "$W/$_g.$_id"
    # (14z-168) MAME can segfault at TEARDOWN after the instrument has closed its log (docs/platform/gotchas.md):
    # `set +e` keeps the status write alive, and a run whose instrument wrote its summary line counts as
    # completed (docs/project/gotchas.md, the set -e capture entry)
    ( set +e; cd "$W/$_g.$_id" && MAME_SANDBOX="$W/$_g.$_id/sb" MAME_ROMPATH="$_rp" REPLAY="$_r" POKES="$PK" FIELDS="$FIELDS" \
        FIELD_OUT="$W/$_g.$_id.ft" FIELD_FROM=1400 FIELD_TO="$FR" FRAMES="$FR" \
        "$REPO/tools/run_mame.sh" "$_set" -autoboot_script "$REPO/tests/lua/field_trace.lua" > "$W/$_g.$_id/mame.log" 2>&1
      _st=$?; grep -q -E '^(FIELDSUMMARY|END )' "$W/$_g.$_id.ft" 2>/dev/null && _st=0; echo $_st > "$W/$_g.$_id/rc"; rm -rf "$W/$_g.$_id/sb" ) </dev/null &
}
reduce() {  # reduce <game> <id> <trace>
    python3 - "$@" <<'PY'
import sys
g, want, ft = sys.argv[1:4]
d = {}
for l in open(ft):
    t = l.split()
    if t and t[0] == "F": d[int(t[1])] = {k: int(v) for k, v in (kv.split("=", 1) for kv in t[2:])}
if 1400 not in d: sys.exit(f"VOID: {ft} has no sample at 1400")
if d[1400]["id"] != int(want, 16): sys.exit(f"VOID: {g} P1 id {d[1400]['id']:#04x}, not {want} — the cursor path did not land")
if max(d) < 3599: sys.exit(f"VOID: {ft} stops at {max(d)}")
on = [f for f in sorted(d) if f > 2950 and d[f]["f111"]]
if not on: sys.exit(f"VOID: {g} {want} never entered the mode (+0x111 never set) — the activation did not happen")
print(f"mode\t{g}\t{want}\t{on[0]}..{on[-1]}")
for f in sorted(d):
    if f > 2550 and f - 1 in d and d[f]["meter"] != d[f - 1]["meter"]:
        print(f"step\t{g}\t{want}\t{f}\t{d[f]['meter'] - d[f - 1]['meter']}\t{'in' if on[0] <= f <= on[-1] else 'out'}")
PY
}
suppress() {  # suppress <rows in> <rows out>: our TENANT rows without any in-mode step (the shells' rule)
    awk -F'\t' '!($1 == "step" && $2 == "ours" && $3 != "01" && $6 == "in")' "$1" > "$2"
}

echo "== 1. the decoded wheels"
. "$REPO/tests/lib/decrypt_cache.sh"
decrypt_view vsav2 "$W/v2_op.bin" "$W/v2_da.bin" || bad "vsav2 views not delivered"
decrypt_view vsavj "$W/vj_op.bin" "$W/vj_da.bin" || bad "vsavj views not delivered"
[ "$fail" = 0 ] || { echo "FAIL: audit_df_meter"; exit 1; }
python3 "$REPO/tools/select_wheel.py" "$W/v2_da.bin" --set vsav2 --json "$W/wheel_vsav2.json" > "$W/w1.log" 2>&1 || bad "vsav2 wheel"
python3 "$REPO/tools/select_wheel.py" "$W/vj_da.bin" --set vsavj --json "$W/wheel_vsavj.json" > "$W/w2.log" 2>&1 || bad "vsavj wheel"
python3 "$REPO/tools/select_wheel.py" "$BUILD/verify_data.bin" --set vsavj --json "$W/wheel_ours.json" > "$W/w3.log" 2>&1 || bad "our wheel"
[ "$fail" = 0 ] || { echo "FAIL: audit_df_meter"; exit 1; }

echo "== 2. the legs"
LEGS="vsavj:00 vsavj:01 vsavj:03 ours:01 ours:10 ours:11 ours:13 vsav2:10 vsav2:11 vsav2:13"
for s in $LEGS; do leg "${s%:*}" "${s#*:}"; done
wait
: > "$W/got.tsv"
for s in $LEGS; do
    g="${s%:*}"; id="${s#*:}"
    _rc="$(cat "$W/$g.$id/rc" 2>/dev/null || echo none)"; [ "$_rc" = 0 ] || bad "$g $id exited $_rc (an emulator that crashed is not evidence)"
    reduce "$g" "$id" "$W/$g.$id.ft" >> "$W/got.tsv" 2> "$W/$g.$id.err" || bad "$g $id: $(cat "$W/$g.$id.err")"
done
[ "$fail" = 0 ] || { echo "FAIL: audit_df_meter (a leg did not run or was VOID)"; exit 1; }
if [ "$CONTROL" = suppressed ]; then suppress "$W/got.tsv" "$W/got.sp" && mv "$W/got.sp" "$W/got.tsv"; fi
ok "$(grep -c '^mode' "$W/got.tsv" | tr -d ' ') legs, $(grep -c '^step' "$W/got.tsv" | tr -d ' ') gauge steps"
for s in $LEGS; do g="${s%:*}"; id="${s#*:}"
    printf '  %-6s %s: in-mode steps %s | out %s\n' "$g" "$id" \
        "$(awk -F'\t' -v g="$g" -v i="$id" '$1=="step" && $2==g && $3==i && $6=="in" {printf "%s@%s ", $5, $4}' "$W/got.tsv")" \
        "$(awk -F'\t' -v g="$g" -v i="$id" '$1=="step" && $2==g && $3==i && $6=="out" {printf "%s@%s ", $5, $4}' "$W/got.tsv")"
done

echo "== 3. the frozen rows"
if [ "${FREEZE:-0}" = 1 ]; then
    {
        echo "# tests/expected/df_meter.tsv — the gauge in and out of Dark Force Change: the shells on vsavj, the tenants on ours (P+K) and"
        echo "# under their vs2 EX install on vsav2 (tests/audit_df_meter.sh; tests/lua/field_trace.lua). Evidence class: in-emulator."
        echo "# Frozen 14z-168 with FREEZE=1 (GitHub #157's Dark Force tail). THE DEFECT IS FROZEN AS MEASURED: the shells gain nothing"
        echo "# from a whiffed attack inside +0x111; our tenants gain +6 (their placed adder tests vs2's +0x1C3). A fix re-freezes this"
        echo "# file DELIBERATELY, with its rule-checker run named in the commit."
        echo "# Columns: mode <leg> <id> <+0x111 span> | step <leg> <id> <frame> <P1 gauge delta> <in|out>"
        echo "#--"
        cat "$W/got.tsv"
    } > "$EXPECT"
    echo "  FROZE  $(basename "$EXPECT") ($(wc -l < "$W/got.tsv" | tr -d ' ') rows) — VERIFY by re-running without FREEZE"; exit 0
fi
[ -f "$EXPECT" ] || { echo "FAIL: no frozen expectation at $EXPECT (FREEZE=1 to create it)"; exit 1; }
grep -v '^#' "$EXPECT" > "$W/want.tsv"
if diff "$W/want.tsv" "$W/got.tsv" > "$W/diff.txt"; then ok "every row as frozen"
else bad "differs from the frozen rows"; sed 's/^/        /' "$W/diff.txt"; fi

echo "== 4. must-fire control"
if [ "$CONTROL" = suppressed ]; then
    if [ "$fail" = 1 ]; then echo "CONTROL FIRED: suppressed — the shells' rule applied to our tenants loses the frozen rows"; echo "FAIL: audit_df_meter (control mode)"; exit 1
    else echo "CONTROL DEAD: suppressed — removing the tenants' in-mode steps changed nothing"; echo "FAIL: audit_df_meter"; exit 1; fi
fi
suppress "$W/got.tsv" "$W/ctl.tsv"
if diff -q "$W/got.tsv" "$W/ctl.tsv" > /dev/null; then echo "CONTROL DEAD: suppressed — our tenants carry no in-mode step to remove"; fail=1
else echo "CONTROL FIRED: suppressed — the shells' rule removes $(diff "$W/got.tsv" "$W/ctl.tsv" | grep -c '^<' | tr -d ' ') in-mode steps from our tenants"; fi

if [ "$fail" = 0 ]; then echo "PASS: audit_df_meter"; else echo "FAIL: audit_df_meter"; exit 1; fi
