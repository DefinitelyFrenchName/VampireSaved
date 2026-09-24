#!/bin/sh
# audit_df_meter.sh — NO GAUGE IS BUILT IN DARK FORCE CHANGE, and since the 14z-170 fix (GitHub #157's Dark Force tail, ruled 2026-09-18) the tenants build none either: a whiffed attack's start-up gauge is suppressed inside +0x111 on every leg of ours, as vsavj's shells — frozen as measured, with vs2's EX install (which pays it) beside for reference. Until 14z-170 it froze the DEFECT: our tenants gained +6 per swing in the mode.
#
# WHAT: no gauge is built inside Dark Force Change on our build — for the shells as vsavj
#   does it and, since the 14z-170 fix, for the tenants too (their ported meter adder used
#   to pay start-up gauge inside the mode) — with vs2's EX install, which does pay it,
#   frozen beside for reference.
# HOW: 10 field-trace legs in parallel on MAME (real cursor picks, P2 kept out of reach so
#   every attack whiffs): j.HP and 5HP out of the mode and in it, the mode at 3000 (P+K on
#   vsavj and ours, the tenant's vs2 EX input on vsav2); every change of the gauge $FF850A
#   frozen with its in/out label; the control plants +6 in-mode steps into our rows.
# EXPECTS: no in-mode gauge step on any ours or vsavj leg, the vsav2 legs' +6 steps present,
#   the frozen table equal; the planted swings fail.
#
# MUST-FIRE: perturbed-copy: swing-planted — a copy of our rows with one in-mode gauge step planted per tenant (+6 at the in-mode swing frames, the pre-fix defect) must FAIL the no-in-mode-gauge check, so "no gauge in the mode" is read from our legs' steps (in-gate: the planted copy must be caught; mode: our rows are planted before the checks and the gate FAILs)
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
#   (in = inside the +0x111 span). The shells' in-mode swings are ABSENT, and since the
#   14z-170 fix the tenants' on ours too (until then +6 at 3164 and 3350 — the defect); on
#   vsav2 they read +6 (vs2's own EX install does not suppress them — its adder tests +0x1C3). Gauge paid by the
#   altered attacks' HITS appears as further in-mode steps on the vsav2 legs; on ours a
#   hit pays through vsavj's own adder and is suppressed like any legacy hit.
#
# WHAT IT DOES NOT COVER: the other 26 +0x1C3 readers' consequences (the static census
# names them); P2's gauge; the gauge a HIT pays in the mode beyond these rows.
#
# Usage: ROMDIR=... [MAME_BIN=...] [BUILD=build/m3b_merged27] [FREEZE=1] tests/audit_df_meter.sh
#   emulator tier, MAME; 10 field_trace legs in parallel — measured 14z-168 on this MacBook, solo: ~25 s wall
set -eu
[ -n "${ROMDIR:-}" ] || { echo "FAIL: set ROMDIR"; exit 1; }
[ -d "$ROMDIR" ] && ROMDIR="$(cd "$ROMDIR" && pwd)"
REPO="$(cd "$(dirname "$0")/.." && pwd)"
MAME_BIN="${MAME_BIN:-$HOME/.cache/vampire-saved/mame/cps2}"; export MAME_BIN
BUILD="${BUILD:-build/m3b_merged27}"
case "$BUILD" in /*) ;; *) BUILD="$REPO/$BUILD" ;; esac
EXPECT="$REPO/tests/expected/df_meter.tsv"
CONTROL="${CONTROL:-}"
[ -x "$MAME_BIN" ] || { echo "SKIP: no MAME at $MAME_BIN"; exit 0; }
[ -f "$ROMDIR/vsav2.zip" ] || { echo "SKIP: no vsav2.zip in $ROMDIR"; exit 0; }
[ -f "$BUILD/rompath/vsavjw.zip" ] || { echo "SKIP: no WIDE build at $BUILD"; exit 0; }
[ -f "$BUILD/verify_data.bin" ] || { echo "SKIP: no verify_data.bin at $BUILD"; exit 0; }
case "$CONTROL" in ""|swing-planted) ;; *) echo "REFUSED: no control named '$CONTROL' is declared by this gate"; exit 3 ;; esac
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
plant_swing() {  # plant_swing <rows in> <rows out>: THE PERTURBATION — one in-mode +6 per tenant leg of ours at the
    # first in-mode swing frame vs2's legs show (the pre-fix defect's shape)
    awk -F'\t' 'BEGIN{OFS="\t"} {print} $1=="step" && $2=="vsav2" && $6=="in" && !($3 in seen) {seen[$3]=1; print "step", "ours", $3, $4, 6, "in"}' "$1" > "$2"
}
no_mode_gauge() {  # no_mode_gauge <rows>: exit 0 when no leg of ours has an in-mode step and every leg of ours has an out-of-mode one
    awk -F'\t' '$1=="step" && $2=="ours" && $6=="in" {bad=1} $1=="step" && $2=="ours" && $6=="out" {live[$3]=1}
        END {n=0; for (k in live) n++; exit (bad || n < 4) ? 1 : 0}' "$1"
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
if [ "$CONTROL" = swing-planted ]; then plant_swing "$W/got.tsv" "$W/got.sp" && mv "$W/got.sp" "$W/got.tsv"; fi
ok "$(grep -c '^mode' "$W/got.tsv" | tr -d ' ') legs, $(grep -c '^step' "$W/got.tsv" | tr -d ' ') gauge steps"
# every leg's Dark Force span (+0x111), so the log shows each leg IN the mode — ours' by P+K (14z-170, run 54 Q4)
awk -F'\t' '$1=="mode" {printf "  mode   %-6s %s: +0x111 %s\n", $2, $3, $4}' "$W/got.tsv"
for s in $LEGS; do g="${s%:*}"; id="${s#*:}"
    printf '  %-6s %s: in-mode steps %s | out %s\n' "$g" "$id" \
        "$(awk -F'\t' -v g="$g" -v i="$id" '$1=="step" && $2==g && $3==i && $6=="in" {printf "%s@%s ", $5, $4}' "$W/got.tsv")" \
        "$(awk -F'\t' -v g="$g" -v i="$id" '$1=="step" && $2==g && $3==i && $6=="out" {printf "%s@%s ", $5, $4}' "$W/got.tsv")"
done

# THE FIX'S CLAIM (14z-170): no leg of ours gains gauge inside the mode — the shells' rule — and every leg of
# ours still shows its out-of-mode swings (the liveness: a dead meter trace would read "no in-mode step" too)
if no_mode_gauge "$W/got.tsv"; then ok "no leg of ours gains gauge in the mode, and all four gain it outside (the shells' rule, #157's DF tail fixed)"
else bad "a leg of ours gains gauge in the mode, or a leg of ours shows no out-of-mode swing (dead trace)"; fi
plant_swing "$W/got.tsv" "$W/ctl.tsv"
if [ "$CONTROL" != swing-planted ]; then
    if no_mode_gauge "$W/ctl.tsv"; then echo "CONTROL DEAD: swing-planted — a planted in-mode step passed the check"; fail=1
    else echo "CONTROL FIRED: swing-planted — one planted in-mode step per tenant fails the no-in-mode-gauge check"; fi
fi

echo "== 3. the frozen rows"
if [ "${FREEZE:-0}" = 1 ]; then
    {
        echo "# tests/expected/df_meter.tsv — the gauge in and out of Dark Force Change: the shells on vsavj, the tenants on ours (P+K) and"
        echo "# under their vs2 EX install on vsav2 (tests/audit_df_meter.sh; tests/lua/field_trace.lua). Evidence class: in-emulator."
        echo "# Frozen with FREEZE=1: first 14z-168 (the defect as measured: our tenants gained +6 in the mode), re-frozen 14z-170 on"
        echo "# the fix (GitHub #157's Dark Force tail): no leg of ours gains gauge inside +0x111; vs2's EX install still pays it."
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

echo "== 4. must-fire control (the mode)"
if [ "$CONTROL" = swing-planted ]; then
    if [ "$fail" = 1 ]; then echo "CONTROL FIRED: swing-planted — the planted in-mode steps fail the gate"; echo "FAIL: audit_df_meter (control mode)"; exit 1
    else echo "CONTROL DEAD: swing-planted — the planted rows passed"; echo "FAIL: audit_df_meter"; exit 1; fi
fi

if [ "$fail" = 0 ]; then echo "PASS: audit_df_meter"; else echo "FAIL: audit_df_meter"; exit 1; fi
