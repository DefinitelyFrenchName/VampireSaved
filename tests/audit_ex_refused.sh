#!/bin/sh
# audit_ex_refused.sh — WHAT THE TENANTS' vs2 EX INPUT DOES WHEN THE MODE IS REFUSED, on native vsav2 and on our merged build, frozen AS MEASURED (14z-169; since 14z-170 the ruled EX-route fix's gate): with an empty stock the input cannot enter the mode on either game, and on our build it enters at NO stock level — Phobos and Donovan take vs2's stock-0 path at stock 3, Pyron reads 623+PP (his ES move with a stock), as ruled.
#
# MUST-FIRE: perturbed-copy: stock-kept — the refused legs run with their stock left at 3 (the refusal removed) must be reported as ENTERING the mode and FAIL, so "never enters" is read from the mode field, not assumed from the poke (in-gate: vs2's three stock-3 legs, already run, must read entered on the same check — ours' no longer enter, which is the fix; mode: every refused leg runs with stock 3, vs2's enter, and the gate FAILs)
#
# WHY. The maintainer ruled the tenants' vs2 EX route into Dark Force DISABLED on our build
# (2026-09-18; asked "Keep it, or disable the EX input so P+K is the only way in? My
# recommendation is to disable it.", answered "agreed" — DECISIONS_HISTORY.md). Before a byte
# moves, what the input should do instead must be known: on vs2 the input with no stock left is
# the game's own "refused" case. This gate runs each tenant's EX input (Donovan 421+KK, Phobos
# 263+PP, Pyron 2623+PP — the maintainer: "as far as I know these are the correct inputs in
# VS2 ... I assume they are indeed correct") on both games with the stock poked to 0, and with
# 3 as the positive control, and freezes whether the mode was entered and P1's state path.
# Rig: tests/audit_df_modes.sh's (97_df_mech's prologue, real cursor picks through
# tools/select_paths.py on each game's decoded wheel, the input at 3260, the level pinned to 6
# and the RNG from 2363); the stock is poked at 3100 and 3120.
# NOT COVERED: which move the path IS (the captures are for the maintainer, not frozen here);
# P2-side inputs; inputs other than these three.
#
# THE FIX (14z-170, ruled 2026-09-18 "disable it" and 2026-09-19 "Natural reading" — DECISIONS_HISTORY.md):
# each tenant's EX site skips vs2's EX check (`0x028534`), so on ours NO stocked leg enters the mode,
# and Phobos's and Donovan's stocked paths equal vs2's REFUSED (stock-0) paths; Pyron's stocked leg
# reads 623+PP, his ES move (one stock), frozen as measured.
#
# FROZEN: tests/expected/ex_refused.tsv — `<game> <id> <refused|stocked> stock=<n> entered=<yes|no>
# stock_after=<n> path=<P1 (seq/sub) changes over 3255-3400, frame offsets from 3260>` (the stock-3
# role was named `entered` until 14z-170).
#
# Usage: ROMDIR=... [MAME_BIN=...] [BUILD=build/m3b_merged27] [FREEZE=1] tests/audit_ex_refused.sh
#   emulator tier, MAME; 12 field-trace runs — measured 14z-169 on this MacBook: see PROVENANCE
set -eu
[ -n "${ROMDIR:-}" ] || { echo "FAIL: set ROMDIR"; exit 1; }
[ -d "$ROMDIR" ] && ROMDIR="$(cd "$ROMDIR" && pwd)"
REPO="$(cd "$(dirname "$0")/.." && pwd)"
MAME_BIN="${MAME_BIN:-$HOME/.cache/vampire-saved/mame/cps2}"; export MAME_BIN
BUILD="${BUILD:-build/m3b_merged27}"
case "$BUILD" in /*) ;; *) BUILD="$REPO/$BUILD" ;; esac
EXPECT="$REPO/tests/expected/ex_refused.tsv"
CONTROL="${CONTROL:-}"
[ -x "$MAME_BIN" ] || { echo "SKIP: no MAME at $MAME_BIN"; exit 0; }
[ -f "$ROMDIR/vsav2.zip" ] || { echo "SKIP: no vsav2.zip in $ROMDIR"; exit 0; }
[ -f "$BUILD/rompath/vsavjw.zip" ] && [ -f "$BUILD/verify_data.bin" ] || { echo "SKIP: no WIDE build at $BUILD"; exit 0; }
case "$CONTROL" in ""|stock-kept) ;; *) echo "REFUSED: no control named '$CONTROL' is declared by this gate"; exit 3 ;; esac
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT INT TERM
fail=0
ok()  { printf '  ok    %s\n' "$1"; }
bad() { printf '  FAIL  %s\n' "$1"; fail=1; }
FR=3700
PINS="$(python3 -c "print(';'.join(f'{f}:ff8116:06' for f in range(2000,$FR)))");$(python3 -c "print(';'.join(f'{f}:ff80d4:0000' for f in range(2363,$FR)))")"
FIELDS="ff802e:b:df,ff8509:b:stock,ff8406:b:seq,ff8407:b:sub,ff8511:b:f111,ff8782:b:id"
ex_lines() {  # the same inputs as tests/audit_df_modes.sh, relative to the activation frame
    case $1 in
        13) printf '%s\n' "$2-$(($2+2)) p1=L" "$(($2+4))-$(($2+6)) p1=D" "$(($2+8))-$(($2+12)) p1=DL" "$(($2+10))-$(($2+14)) p1=46" ;;
        10) printf '%s\n' "$2-$(($2+2)) p1=D" "$(($2+4))-$(($2+6)) p1=R" "$(($2+8))-$(($2+12)) p1=DR" "$(($2+10))-$(($2+14)) p1=13" ;;
        11) printf '%s\n' "$2-$(($2+2)) p1=D" "$(($2+4))-$(($2+6)) p1=R" "$(($2+8))-$(($2+10)) p1=D" "$(($2+12))-$(($2+16)) p1=DR" "$(($2+14))-$(($2+18)) p1=13" ;;
    esac
}
. "$REPO/tests/lib/decrypt_cache.sh"
decrypt_view vsav2 "$W/v2_op.bin" "$W/v2_da.bin" || { echo "FAIL: no vsav2 view"; exit 1; }
python3 "$REPO/tools/select_wheel.py" "$W/v2_da.bin" --set vsav2 --json "$W/wheel_vsav2.json" > /dev/null 2>&1 || { echo "FAIL: vsav2 wheel"; exit 1; }
python3 "$REPO/tools/select_wheel.py" "$BUILD/verify_data.bin" --set vsavj --json "$W/wheel_ours.json" > /dev/null 2>&1 || { echo "FAIL: our wheel"; exit 1; }
# ONE leg builder: the stock value is the perturbation's only lever ([VSP-181])
leg() {  # leg <game> <id> <stock> <role>
    case $1 in vsav2) _set=vsav2; _rp="$ROMDIR" ;; ours) _set=vsavjw; _rp="$BUILD/rompath;$ROMDIR" ;; esac
    _path="$(python3 "$REPO/tools/select_paths.py" "$W/wheel_$1.json" --cell "$2" --player 1 | sed 's/^P1 0x[0-9a-f]*: *//')"
    _n="$1_$2_$4"; _r="$W/$_n.rpl"
    { grep -v -E '^(#|3260-3263 p1=36|7000 wait)' "$REPO/tests/replays/df/97_df_mech.rpl"
      _t=1100; for _mv in $_path; do echo "$_t-$((_t+2)) p1=$_mv"; _t=$((_t+60)); done
      ex_lines "$2" 3260; echo "$FR wait"; } > "$_r"
    mkdir -p "$W/$_n"
    ( set +e; cd "$W/$_n" && MAME_SANDBOX="$W/$_n/sb" MAME_ROMPATH="$_rp" REPLAY="$_r" POKES="3100:ff8509:$(printf %02x "$3");3120:ff8509:$(printf %02x "$3");$PINS" \
        FIELDS="$FIELDS" FIELD_OUT="$W/$_n.ft" FIELD_FROM=1400 FIELD_TO="$FR" FRAMES="$FR" \
        "$REPO/tools/run_mame.sh" "$_set" -autoboot_script "$REPO/tests/lua/field_trace.lua" > "$W/$_n/mame.log" 2>&1
      echo $? > "$W/$_n/rc"; rm -rf "$W/$_n/sb" ) </dev/null &
}
echo "== 1. the legs"
REFUSED_STOCK=0; [ "$CONTROL" = stock-kept ] && REFUSED_STOCK=3
for g in vsav2 ours; do for id in 13 10 11; do leg "$g" "$id" "$REFUSED_STOCK" refused; [ -n "$CONTROL" ] || leg "$g" "$id" 3 stocked; done; wait; done
# ONE reducer
reduce() {  # reduce <game> <id> <stock> <role> <trace> -> one row; exits 1 on a VOID leg
    python3 - "$@" <<'PY'
import sys
g, i, st, role, ft = sys.argv[1:6]
d = {}
for l in open(ft):
    t = l.split()
    if t and t[0] == "F": d[int(t[1])] = {k: int(v) for k, v in (kv.split("=", 1) for kv in t[2:])}
if 1400 not in d or 3699 not in d: sys.exit(f"VOID: {g} {i} stock {st}: trace incomplete")
if d[1400]["id"] != int(i, 16): sys.exit(f"VOID: {g} {i}: P1 is {d[1400]['id']:#04x} — the pick did not land")
if d[3250]["stock"] != int(st): sys.exit(f"VOID: {g} {i}: stock {d[3250]['stock']} at 3250, not the poked {st}")
entered = any(d[f]["f111"] for f in range(3255, 3700))
path, prev = [], None
for f in range(3255, 3401):
    k = f"{d[f]['seq']:02x}/{d[f]['sub']:02x}"
    if k != prev: path.append(f"{f - 3260}:{k}")
    prev = k
print(f"{g}\t{i}\t{role}\tstock={st}\tentered={'yes' if entered else 'no'}\tstock_after={d[3500]['stock']}\tpath={' '.join(path)}")
PY
}
: > "$W/got.tsv"
for g in vsav2 ours; do for id in 13 10 11; do for role in refused stocked; do
    [ "$role" = stocked ] && [ -n "$CONTROL" ] && continue
    st="$REFUSED_STOCK"; [ "$role" = stocked ] && st=3
    [ -f "$W/${g}_${id}_$role.ft" ] || { bad "${g}_${id}_$role: no trace (exit $(cat "$W/${g}_${id}_$role/rc" 2>/dev/null || echo none))"; continue; }
    reduce "$g" "$id" "$st" "$role" "$W/${g}_${id}_$role.ft" >> "$W/got.tsv" 2> "$W/err" || bad "$(cat "$W/err")"
done; done; done
[ "$fail" = 0 ] || { echo "FAIL: audit_ex_refused"; exit 1; }
sort -u "$W/got.tsv" -o "$W/got.tsv"
sed 's/^/  /' "$W/got.tsv"
# the property: a refused leg (stock 0) never enters the mode; the positive control: stock 3 does
_in="$(awk -F'\t' '$3=="refused" && $5=="entered=yes"' "$W/got.tsv")"
[ -z "$_in" ] && ok "no refused leg enters the mode" || { bad "a refused leg entered the mode:"; echo "$_in" | sed 's/^/        /'; }
if [ -z "$CONTROL" ]; then
    _c="$(awk -F'\t' '$1=="vsav2" && $3=="stocked" && $5=="entered=yes"' "$W/got.tsv" | wc -l | tr -d ' ')"
    if [ "$_c" = 3 ]; then echo "CONTROL FIRED: stock-kept — with stock 3 vs2's three legs read entered on the same check"
    else echo "CONTROL DEAD: stock-kept — only $_c of vs2's 3 stock-3 legs read entered"; fail=1; fi
    # THE FIX (14z-170): no stocked leg on ours enters; Phobos's and Donovan's stocked paths are vs2's refused paths
    _o="$(awk -F'\t' '$1=="ours" && $3=="stocked" && $5=="entered=yes"' "$W/got.tsv")"
    [ -z "$_o" ] && ok "no stocked leg on ours enters the mode (the disabled EX route)" || { bad "a stocked leg on ours entered the mode:"; echo "$_o" | sed 's/^/        /'; }
    for _id in 10 13; do
        _v="$(awk -F'\t' -v i="$_id" '$1=="vsav2" && $2==i && $3=="refused" {print $7}' "$W/got.tsv")"
        _s="$(awk -F'\t' -v i="$_id" '$1=="ours" && $2==i && $3=="stocked" {print $7}' "$W/got.tsv")"
        [ -n "$_v" ] && [ "$_v" = "$_s" ] && ok "0x$_id at stock 3 on ours takes vs2's stock-0 path" || bad "0x$_id at stock 3 on ours: '$_s' where vs2 at stock 0 takes '$_v'"
    done
fi

echo "== 2. the frozen rows"
if [ "${FREEZE:-0}" = 1 ]; then
    [ "$fail" = 0 ] && [ -z "$CONTROL" ] || { echo "FAIL: audit_ex_refused (not frozen: fix the red first, no control)"; exit 1; }
    { echo "# tests/expected/ex_refused.tsv — the tenants' vs2 EX input with the stock at 0 (refused) and 3 (stocked), native vsav2 and"
      echo "# $(basename "$BUILD") (tests/audit_ex_refused.sh; field_trace). Evidence class: in-emulator. Frozen with FREEZE=1 (first 14z-169; the EX-route fix 14z-170)."
      echo "# path = P1's (seq/sub) at each change over 3255-3400, as frame offsets from the input at 3260."
      echo "#--"; cat "$W/got.tsv"; } > "$EXPECT"
    echo "  FROZE  $(basename "$EXPECT") ($(wc -l < "$W/got.tsv" | tr -d ' ') rows) — VERIFY by re-running without FREEZE"; exit 0
fi
[ -f "$EXPECT" ] || { echo "FAIL: no frozen expectation at $EXPECT (FREEZE=1 to create it)"; exit 1; }
if [ -z "$CONTROL" ]; then
    grep -v '^#' "$EXPECT" > "$W/want.tsv"
    if diff "$W/want.tsv" "$W/got.tsv" > "$W/diff.txt"; then ok "every row as frozen"
    else bad "differs from the frozen rows"; sed 's/^/        /' "$W/diff.txt"; fi
fi
if [ "$CONTROL" = stock-kept ]; then
    if [ "$fail" = 1 ]; then echo "CONTROL FIRED: stock-kept — the unrefused legs enter the mode"; echo "FAIL: audit_ex_refused (control mode)"; exit 1
    else echo "CONTROL DEAD: stock-kept — the unrefused legs passed"; echo "FAIL: audit_ex_refused"; exit 1; fi
fi
if [ "$fail" = 0 ]; then echo "PASS: audit_ex_refused"; else echo "FAIL: audit_ex_refused"; exit 1; fi
