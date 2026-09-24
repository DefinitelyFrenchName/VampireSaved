#!/bin/sh
# audit_df_modes.sh — DARK FORCE POWER vs DARK FORCE CHANGE, every selectable character, frozen AS MEASURED (14z-168, GitHub #136): on vsav2 P+K is the global DARK FORCE POWER (two stocks, no startup invincibility, the seq-0x16 handler never reached); on vsavj and our build it is each character's DARK FORCE CHANGE; the tenants' vs2 "personal" Dark Force is a timed EX install that reaches their Change handler on BOTH games.
#
# WHAT: Dark Force POWER vs Dark Force CHANGE, every selectable character: on vsav2 P+K is
#   the global Power (two stocks, no startup invincibility, the seq-0x16 handler never
#   reached, +0x1C3 held) while on vsavj and ours it is each character's Change; the
#   tenants' vs2 EX moves are a timed install that reaches their Change handler and arms
#   their own +0x147 on both games.
# HOW: 40 legs x 2 runs on MAME (vsav2's 15 ids and the three tenants' EX inputs, vsavj's
#   15, ours' P+K and EX), each a REAL cursor path with identity asserted at 1400, the df/97
#   prologue and activation frame, stocks poked, level and RNG pinned; one frozen row per
#   leg (stock, seq16 frames, the +0x147 arm and writer, the timer, the +0x111 span, the
#   flags); the control plants an arming write into a Power leg's log.
# EXPECTS: every Power row arm=none with pow held, every Change row armed from its handler,
#   the EX rows entering the Change machinery on both games; the planted Power log changes
#   its row and fails.
#
# MUST-FIRE: perturbed-copy: power-armed — a copy of a vsav2 P+K leg's tap log with ONE planted +0x147 arming write (what a reachable Change handler would leave) must change that leg's row and FAIL the frozen compare, so a Power row's `arm=none` is a reading of the log, not a default (in-gate: the planted copy must reduce differently; mode: every vsav2 P+K log is planted before the reduction and the table FAILs)
#
# WHY. The maintainer, 2026-09-18 (14z-168), on the first in-DF comparison of the
# #136 parity rigs: "you are testing DF in our build versus the global/common Dark
# Force Power in VS2 ... VS2's dark force power costs 2 meters instead of 1, has no
# invincibility at startup, is a global buff, has no specific moves while VS dark
# force (sometimes called dark force change) is a character altering ability with
# startup invincibility" — and asked for a double check that the Change window is
# unreachable in VS2 "since Dark Force Power overrules it for every character". It
# is, for P+K, on all 15 characters vsav2's wheel reaches. But the tenants' vs2 EX
# moves (the moves Vampire Saved maps onto their Dark Force: Slay Shred, Ray of Doom,
# Shining Gemini) enter the Change machinery through vs2's own entry PRG:0x02622A
# (+0x111, +0x110, +0x143 = 0x14, the 112-unit timer +0x176, a CONSTANT period
# +0x189 = 5) and arm each tenant's own +0x147 from its own vs2 handler — so the
# "shipped but never reached" reading of 14z-126 is wrong for the three tenants
# (docs/game/engine_internals.md, Dark Force). Our build still honours those EX
# inputs as well as P+K. The maintainer, asked (2026-09-18) "Keep it, or disable the EX
# input so P+K is the only way in? My recommendation is to disable it.", answered "agreed"
# (DECISIONS_HISTORY.md "Ruled 2026-09-18 (14z-168) — the tenants' vs2 EX route into Dark
# Force is DISABLED on our build").
#
# WHAT IT FREEZES (tests/expected/df_modes.tsv), one row per leg:
#   <mode> <leg> <id> stock=<before>-><after> seq16=<frames in seq 0x16>
#       arm=<+0x147 arming value@writer PC | none> timer=<+0x176 init@writer PC | none>
#       dec=<+0x176 decrement writer PC | none> span111=<frames +0x111 held | none>
#       flag=<frames $FF802E held | none> pow=<frames vs2's Power flag +0x1C3 held | none>
#   mode: power (vsav2, P+K), change (vsavj and ours, P+K), ex (vsav2 and ours, the
#   tenant's vs2 EX input: Donovan 421+KK, Phobos 263+PP, Pyron 2623+PP — measured
#   14z-168; the maintainer, 2026-09-18 (14z-169): "as far as I know these are the
#   correct inputs in VS2, and given you were able to trigger the moves for the comparison
#   we made last session I assume they are indeed correct")
# Legs: vsav2 ids 00 01 03 04 05 06 07 08 0c 0d 0e 0f 10 11 13 (P+K); vsavj ids
# 00-0a 0c-0f (P+K); ours 01 10 11 13 (P+K); vsav2 and ours 10 11 13 (EX). Every
# pick is the REAL cursor path (tools/select_paths.py on each game's decoded wheel),
# identity asserted at frame 1400. Rig: tests/replays/df/97_df_mech.rpl's prologue and
# activation frame (3260), idle after, 3 stocks poked at 3100/3120, the speed level
# pinned to 6 from 2000 and the RNG from 2363 (the parity gate's pins).
#
# THE POWER FLAG (+0x1C3, added 14z-169, item 3 of the #136 fixes' analysis): vs2's Power
# sets it and the tenants' ported code reads it at 26 placed sites (tests/test_df_field_readers.sh)
# — the meter adders, the POWER activation's own "already in Power" test (vs2 0x2617A; called the
# Change entry's test until 14z-170 — mislabelled), Phobos's powered specials
# (+0x106 = 0x1A) and a per-move latch (+0x19C) the tenants' own code tests later. Our build never
# sets it, so every one of them reads 0; the `pow` column says what the REFERENCE reads while the
# tenant is in its vs2 EX mode. POSITIVE CONTROL: every power row must hold it (a trace of an
# address that is not +0x1C3 would read 0 everywhere and pass the rest).
# WHAT IT DOES NOT COVER: whether other inputs also reach the vs2 EX moves; what
# the modes DO beyond their fields (the altered attacks — the next #136 rig);
# Sasquatch's alternate DFs; P2-side activations.
#
# Usage: ROMDIR=... [MAME_BIN=...] [BUILD=build/m3b_merged27] [JOBS=6] [FREEZE=1] tests/audit_df_modes.sh
#   emulator tier, MAME; 40 legs x 2 runs — measured 14z-168 on this MacBook, solo: ~95 s wall
set -eu
[ -n "${ROMDIR:-}" ] || { echo "FAIL: set ROMDIR"; exit 1; }
[ -d "$ROMDIR" ] && ROMDIR="$(cd "$ROMDIR" && pwd)"
REPO="$(cd "$(dirname "$0")/.." && pwd)"
MAME_BIN="${MAME_BIN:-$HOME/.cache/vampire-saved/mame/cps2}"; export MAME_BIN
BUILD="${BUILD:-build/m3b_merged27}"
case "$BUILD" in /*) ;; *) BUILD="$REPO/$BUILD" ;; esac
EXPECT="$REPO/tests/expected/df_modes.tsv"
JOBS="${JOBS:-6}"
CONTROL="${CONTROL:-}"
[ -x "$MAME_BIN" ] || { echo "SKIP: no MAME at $MAME_BIN"; exit 0; }
[ -f "$ROMDIR/vsav2.zip" ] || { echo "SKIP: no vsav2.zip in $ROMDIR"; exit 0; }
[ -f "$BUILD/rompath/vsavjw.zip" ] || { echo "SKIP: no WIDE build at $BUILD"; exit 0; }
[ -f "$BUILD/verify_data.bin" ] || { echo "SKIP: no verify_data.bin at $BUILD"; exit 0; }
case "$CONTROL" in ""|power-armed) ;; *) echo "REFUSED: no control named '$CONTROL' is declared by this gate"; exit 3 ;; esac
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT INT TERM
fail=0
ok()  { printf '  ok    %s\n' "$1"; }
bad() { printf '  FAIL  %s\n' "$1"; fail=1; }
FR=3900
PK="3100:ff8509:03;3120:ff8509:03;$(python3 -c "print(';'.join(f'{f}:ff8116:06' for f in range(2000,$FR)))");$(python3 -c "print(';'.join(f'{f}:ff80d4:0000' for f in range(2363,$FR)))")"
FIELDS="ff802e:b:df,ff8509:b:stock,ff8406:b:seq,ff8511:b:f111,ff8782:b:id,ff85c3:b:pow"
# the tenants' vs2 EX inputs, as replay lines relative to the activation frame (measured 14z-168)
ex_lines() {  # ex_lines <id> <t>
    case $1 in
        13) printf '%s\n' "$2-$(($2+2)) p1=L" "$(($2+4))-$(($2+6)) p1=D" "$(($2+8))-$(($2+12)) p1=DL" "$(($2+10))-$(($2+14)) p1=46" ;;
        10) printf '%s\n' "$2-$(($2+2)) p1=D" "$(($2+4))-$(($2+6)) p1=R" "$(($2+8))-$(($2+12)) p1=DR" "$(($2+10))-$(($2+14)) p1=13" ;;
        11) printf '%s\n' "$2-$(($2+2)) p1=D" "$(($2+4))-$(($2+6)) p1=R" "$(($2+8))-$(($2+10)) p1=D" "$(($2+12))-$(($2+16)) p1=DR" "$(($2+14))-$(($2+18)) p1=13" ;;
    esac
}
leg() {  # leg <mode> <game> <id>   (background: a field_trace run and a tap run)
    _m=$1; _g=$2; _id=$3
    case $_g in vsav2) _set=vsav2; _rp="$ROMDIR"; _wh="$W/wheel_vsav2.json" ;;
                vsavj) _set=vsavj; _rp="$ROMDIR"; _wh="$W/wheel_vsavj.json" ;;
                ours)  _set=vsavjw; _rp="$BUILD/rompath;$ROMDIR"; _wh="$W/wheel_ours.json" ;; esac
    _path="$(python3 "$REPO/tools/select_paths.py" "$_wh" --cell "$_id" --player 1 | sed 's/^P1 0x[0-9a-f]*: *//')"
    _r="$W/${_m}_${_g}_$_id.rpl"
    { grep -v -E '^(#|3260-3263 p1=36|7000 wait)' "$REPO/tests/replays/df/97_df_mech.rpl"
      _t=1100; for _mv in $_path; do echo "$_t-$((_t+2)) p1=$_mv"; _t=$((_t+60)); done
      if [ "$_m" = ex ]; then ex_lines "$_id" 3260; else echo "3260-3263 p1=36"; fi
      echo "$FR wait"; } > "$_r"
    _n="${_m}_${_g}_$_id"; mkdir -p "$W/$_n.f" "$W/$_n.t"
    # (14z-168) MAME can segfault at TEARDOWN after the instrument has closed its log (docs/platform/gotchas.md):
    # `set +e` keeps the status write alive, and a run whose instrument wrote its summary line counts as
    # completed (docs/project/gotchas.md, the set -e capture entry)
    ( set +e; cd "$W/$_n.f" && MAME_SANDBOX="$W/$_n.f/sb" MAME_ROMPATH="$_rp" REPLAY="$_r" POKES="$PK" FIELDS="$FIELDS" \
        FIELD_OUT="$W/$_n.ft" FIELD_FROM=1400 FIELD_TO="$FR" FRAMES="$FR" \
        "$REPO/tools/run_mame.sh" "$_set" -autoboot_script "$REPO/tests/lua/field_trace.lua" > "$W/$_n.f/mame.log" 2>&1
      _st=$?; grep -q -E '^(FIELDSUMMARY|END )' "$W/$_n.ft" 2>/dev/null && _st=0; echo $_st > "$W/$_n.f/rc"; rm -rf "$W/$_n.f/sb" ) </dev/null &
    ( set +e; cd "$W/$_n.t" && MAME_SANDBOX="$W/$_n.t/sb" MAME_ROMPATH="$_rp" REPLAY="$_r" POKES="$PK" RTAP=ff8546,50 \
        WINDOW=999999,999999 FRAMES="$FR" TRACE_OUT="$W/$_n.tap" \
        "$REPO/tools/run_mame.sh" "$_set" -autoboot_script "$REPO/tests/lua/read_tap.lua" > "$W/$_n.t/mame.log" 2>&1
      _st=$?; grep -q -E '^(FIELDSUMMARY|END )' "$W/$_n.tap" 2>/dev/null && _st=0; echo $_st > "$W/$_n.t/rc"; rm -rf "$W/$_n.t/sb" ) </dev/null &
}
# ONE planting function, shared by the in-gate control and the mode
plant_arm() {  # plant_arm <tap in> <tap out>: one +0x147 arming write at 3261 before the END line
    awk '/^END /{print "W 3261 PC 0bad00 off ff8546 data 00000040 mask 000000ff"} {print}' "$1" > "$2"
}
# ONE reducer: a leg's trace + tap -> its row
reduce() {  # reduce <mode> <game> <id> <trace> <tap>
    python3 - "$@" <<'PY'
import sys
m, g, want, ft, tp = sys.argv[1:6]
d = {}
for l in open(ft):
    t = l.split()
    if t and t[0] == "F": d[int(t[1])] = {k: int(v) for k, v in (kv.split("=", 1) for kv in t[2:])}
if not d or 1400 not in d: sys.exit(f"VOID: {ft} has no sample at 1400")
if d[1400]["id"] != int(want, 16): sys.exit(f"VOID: {g} P1 id {d[1400]['id']:#04x} at 1400, not {want} — the cursor path did not land")
if max(d) < 3899: sys.exit(f"VOID: {ft} stops at {max(d)}")
ended = False; arm = []; tinit = []; dec = {}
for l in open(tp):
    t = l.split()
    if not t: continue
    if t[0] == "END": ended = True
    if t[0] != "W" or int(t[1]) < 3255: continue
    off, v, mask = int(t[5], 16), int(t[7], 16), int(t[9], 16)
    if off == 0xFF8546 and mask & 0x00FF and v & 0xFF and t[3] not in ("022474", "020e2a"):
        arm.append(f"{v & 0xFF}@{t[3]}")
    if off == 0xFF8576:
        w = v & 0xFFFF
        if w == 0x70 and not tinit: tinit.append(f"{w}@{t[3]}")
        elif w < 0x70: dec[t[3]] = dec.get(t[3], 0) + 1
if not ended: sys.exit(f"VOID: {tp} has no END line (a dead tap is not evidence)")
fr = [f for f in sorted(d) if f >= 3255]
seq16 = sum(1 for f in fr if d[f]["seq"] == 0x16)
def span(k):
    on = [f for f in fr if d[f][k]]
    return str(on[-1] - on[0] + 1) if on else "none"
print(f"{m}\t{g}\t{want}\tstock={d[3250]['stock']}->{d[3400]['stock']}\tseq16={seq16}\tarm={','.join(arm) or 'none'}"
      f"\ttimer={','.join(tinit) or 'none'}\tdec={','.join(f'{p}x{n}' for p, n in sorted(dec.items())) or 'none'}"
      f"\tspan111={span('f111')}\tflag={span('df')}\tpow={span('pow')}")
PY
}

echo "== 1. the three decoded wheels"
. "$REPO/tests/lib/decrypt_cache.sh"
decrypt_view vsav2 "$W/v2_op.bin" "$W/v2_da.bin" || bad "vsav2 views not delivered"
decrypt_view vsavj "$W/vj_op.bin" "$W/vj_da.bin" || bad "vsavj views not delivered"
[ "$fail" = 0 ] || { echo "FAIL: audit_df_modes"; exit 1; }
python3 "$REPO/tools/select_wheel.py" "$W/v2_da.bin" --set vsav2 --json "$W/wheel_vsav2.json" > "$W/w1.log" 2>&1 || bad "vsav2 wheel: $(tail -1 "$W/w1.log")"
python3 "$REPO/tools/select_wheel.py" "$W/vj_da.bin" --set vsavj --json "$W/wheel_vsavj.json" > "$W/w2.log" 2>&1 || bad "vsavj wheel: $(tail -1 "$W/w2.log")"
python3 "$REPO/tools/select_wheel.py" "$BUILD/verify_data.bin" --set vsavj --json "$W/wheel_ours.json" > "$W/w3.log" 2>&1 || bad "our wheel: $(tail -1 "$W/w3.log")"
[ "$fail" = 0 ] || { echo "FAIL: audit_df_modes"; exit 1; }
ok "wheels decoded"

echo "== 2. the legs"
LEGS=""
for id in 00 01 03 04 05 06 07 08 0c 0d 0e 0f 10 11 13; do LEGS="$LEGS power:vsav2:$id"; done
for id in 00 01 02 03 04 05 06 07 08 09 0a 0c 0d 0e 0f; do LEGS="$LEGS change:vsavj:$id"; done
for id in 01 10 11 13; do LEGS="$LEGS change:ours:$id"; done
for id in 10 11 13; do LEGS="$LEGS ex:vsav2:$id ex:ours:$id"; done
n=0; PAR=$((JOBS / 2)); [ "$PAR" -ge 1 ] || PAR=1
for s in $LEGS; do
    IFS=: read -r m g id <<EOF2
$s
EOF2
    leg "$m" "$g" "$id"; n=$((n + 1)); [ $((n % PAR)) -eq 0 ] && wait
done
wait
: > "$W/got.tsv"
for s in $LEGS; do
    IFS=: read -r m g id <<EOF2
$s
EOF2
    nm="${m}_${g}_$id"
    for k in f t; do _rc="$(cat "$W/$nm.$k/rc" 2>/dev/null || echo none)"; [ "$_rc" = 0 ] || bad "$nm.$k exited $_rc (an emulator that crashed is not evidence)"; done
    tp="$W/$nm.tap"
    if [ "$CONTROL" = power-armed ] && [ "$m" = power ]; then plant_arm "$tp" "$W/$nm.pl" && tp="$W/$nm.pl"; fi
    reduce "$m" "$g" "$id" "$W/$nm.ft" "$tp" >> "$W/got.tsv" 2> "$W/$nm.err" || bad "$nm: $(cat "$W/$nm.err")"
done
[ "$fail" = 0 ] || { echo "FAIL: audit_df_modes (a leg did not run or was VOID)"; exit 1; }
ok "$(wc -l < "$W/got.tsv" | tr -d ' ') legs reduced"
# POSITIVE CONTROL on the +0x1C3 read (14z-169): vs2's P+K is Dark Force Power, which sets it
_np="$(awk -F'\t' '$1=="power" && $NF=="pow=none"' "$W/got.tsv" | wc -l | tr -d ' ')"
[ "$_np" = 0 ] && ok "positive control: +0x1C3 is held on every vsav2 P+K (Power) leg" || bad "$_np vsav2 P+K leg(s) never hold +0x1C3 — the Power flag is not being read"
sed 's/^/  /' "$W/got.tsv"

echo "== 3. the frozen rows"
if [ "${FREEZE:-0}" = 1 ]; then
    [ "$fail" = 0 ] && [ -z "$CONTROL" ] || { echo "FAIL: audit_df_modes (not frozen: fix the red first, no control)"; exit 1; }
    {
        echo "# tests/expected/df_modes.tsv — Dark Force Power vs Dark Force Change, every selectable character (tests/audit_df_modes.sh;"
        echo "# tests/lua/field_trace.lua + tests/lua/read_tap.lua over +0x146..+0x177, non-debug). Evidence class: in-emulator."
        echo "# Frozen 14z-168 with FREEZE=1 (GitHub #136); re-frozen 14z-169 with the pow column. vsav2's P+K is DARK FORCE POWER (two stocks, seq 0x16 never held, +0x147"
        echo "# never armed); vsavj's and ours' is each character's DARK FORCE CHANGE; the tenants' vs2 EX input reaches their Change"
        echo "# handler on BOTH games (period 5, 479/509 frames of +0x111). THE EX ROUTE ON OUR BUILD IS FROZEN AS MEASURED — the"
        echo "# maintainer, asked \"Keep it, or disable the EX input so P+K is the only way in?\", answered \"agreed\" (2026-09-18,"
        echo "# DECISIONS_HISTORY.md); that fix re-freezes the ex/ours rows DELIBERATELY."
        echo "# Columns: mode, leg, id, stock, seq16, arm, timer, dec, span111, flag, pow (frames at speed level 6; pow = vs2's Power"
        echo "# flag +0x1C3, the column added 14z-169)"
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
if [ "$CONTROL" = power-armed ]; then
    if [ "$fail" = 1 ]; then echo "CONTROL FIRED: power-armed — a planted arming write turns the Power rows"; echo "FAIL: audit_df_modes (control mode)"; exit 1
    else echo "CONTROL DEAD: power-armed — the planted write changed nothing"; echo "FAIL: audit_df_modes"; exit 1; fi
fi
nm="power_vsav2_13"; plant_arm "$W/$nm.tap" "$W/ctl.tap"
reduce power vsav2 13 "$W/$nm.ft" "$W/ctl.tap" > "$W/ctl.row" 2>/dev/null || true
if [ -s "$W/ctl.row" ] && ! grep -qxF "$(cat "$W/ctl.row")" "$W/got.tsv"; then
    echo "CONTROL FIRED: power-armed — the planted log reads $(cut -f6 "$W/ctl.row") where the real one reads $(grep "^power	vsav2	13	" "$W/got.tsv" | cut -f6)"
else echo "CONTROL DEAD: power-armed — the planted write was not read"; fail=1; fi

if [ "$fail" = 0 ]; then echo "PASS: audit_df_modes"; else echo "FAIL: audit_df_modes"; exit 1; fi
