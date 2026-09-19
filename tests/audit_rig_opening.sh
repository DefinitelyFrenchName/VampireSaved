#!/bin/sh
# audit_rig_opening.sh — THE #136 GUARD-CANCEL RIG'S OPENING, ours vs native, frozen AS MEASURED (14z-167): the rig's first X pin lands before the round starts, inside the round-start entrance, and the two legs draw different entrances.
#
# MUST-FIRE: perturbed-copy: entrance-swapped — a copy of our opening rows carrying native's x and seq (what the two legs would read if they drew the same entrance) must FAIL the frozen compare, so the frozen rows are the entrance artifact and a rig fix is a deliberate re-freeze (in-gate: the perturbed copy must differ from the frozen rows; mode: our rows are replaced before the compare and the table FAILs)
#
# WHY. tests/expected/move_parity_events.tsv froze huitzil_5/6/7 event 0 as DIFF
# at +0 on x. Measured 14z-167 (build/x_family_14z167/; docs/game/engine_internals.md
# "The round-start ENTRANCE and the round start"): those guard-cancel parts pin both
# fighters' X at 2370, but the round starts at 2544 ($FF812D), so the pin lands
# inside the entrance; native drew the car arrival (Phobos carried from x=360 to
# 702), ours the arrival with Cecil in hand (held at 552 until 2481). The
# maintainer identified the two entrances on the capture before any conclusion
# (build/x_family_14z167/cap/huitzil_5_opening_sheet.png). This gate freezes the
# opening so the rig change that moves the first pin after the round start is a
# deliberate re-freeze, and so the artifact cannot silently change shape.
#
# WHAT IT FREEZES (tests/expected/rig_opening.tsv), huitzil_5 only (huitzil_6/7
# share its prologue and pokes, measured identical 14z-167):
#   start  <leg> <first frame $FF812D reads 1>
#   at     <leg> <frame> x=<P1 x> seq=<P1 seq>  at 2363 2370 2395 2481 2544 2560 2600
#
# A field_trace.lua trace carries NO END line (unlike read_tap.lua's logs), so this
# gate's reduction refuses a missing sample frame and asserts the emulator's exit
# status instead of an END check (rule-checker run 2026-09-18-43 Q1).
#
# Usage: ROMDIR=... [MAME_BIN=...] [BUILD=build/m3b_merged27] [FREEZE=1] tests/audit_rig_opening.sh
#   emulator tier, MAME; two field_trace runs in parallel — measured 14z-167b on this MacBook, solo: ~3 s wall
set -eu
[ -n "${ROMDIR:-}" ] || { echo "FAIL: set ROMDIR"; exit 1; }
[ -d "$ROMDIR" ] && ROMDIR="$(cd "$ROMDIR" && pwd)"
REPO="$(cd "$(dirname "$0")/.." && pwd)"
MAME_BIN="${MAME_BIN:-$HOME/.cache/vampire-saved/mame/cps2}"; export MAME_BIN
BUILD="${BUILD:-build/m3b_merged27}"
case "$BUILD" in /*) ;; *) BUILD="$REPO/$BUILD" ;; esac
EXPECT="$REPO/tests/expected/rig_opening.tsv"
CONTROL="${CONTROL:-}"
[ -x "$MAME_BIN" ] || { echo "SKIP: no MAME at $MAME_BIN"; exit 0; }
[ -f "$ROMDIR/vsav2.zip" ] || { echo "SKIP: no vsav2.zip in $ROMDIR"; exit 0; }
[ -f "$BUILD/rompath/vsavjw.zip" ] || { echo "SKIP: no WIDE build at $BUILD"; exit 0; }
case "$CONTROL" in ""|entrance-swapped) ;; *) echo "REFUSED: no control named '$CONTROL' is declared by this gate"; exit 3 ;; esac
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT INT TERM
fail=0
ok()  { printf '  ok    %s\n' "$1"; }
bad() { printf '  FAIL  %s\n' "$1"; fail=1; }
PART=huitzil_5; TENANT=huitzil; FR=2610
# --- the rig as tests/audit_move_parity.sh builds it (pokes_for / rpl_for / OURS_PATH, copied) ---
OURS_PATH_huitzil="D D D"
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
sample() {  # sample <leg> <set> <rompath> <rpl> <pokes>   (background)
    mkdir -p "$W/$1"
    # (14z-168) MAME can segfault at TEARDOWN after the instrument has closed its log (docs/platform/gotchas.md):
    # `set +e` keeps the status write alive, and a run whose instrument wrote its summary line counts as
    # completed (docs/project/gotchas.md, the set -e capture entry)
    ( set +e; cd "$W/$1" && MAME_SANDBOX="$W/$1/sb" MAME_ROMPATH="$3" REPLAY="$4" POKES="$5" FRAMES="$FR" \
        FIELDS="ff8410:w:x,ff8406:b:seq,ff812d:b:rnd,ff8782:b:id" FIELD_OUT="$W/$1.tr" FIELD_FROM=2300 FIELD_TO="$FR" \
        "$REPO/tools/run_mame.sh" "$2" -autoboot_script "$REPO/tests/lua/field_trace.lua" > "$W/$1/mame.log" 2>&1
      _st=$?; grep -q -E '^(FIELDSUMMARY|END )' "$W/$1.tr" 2>/dev/null && _st=0; echo $_st > "$W/$1/rc"; rm -rf "$W/$1/sb" ) </dev/null &
}
reduce() {  # reduce <leg> <trace> -> rows
    python3 - "$1" "$2" <<'PY'
import sys
leg, p = sys.argv[1], sys.argv[2]; d = {}
for l in open(p):
    t = l.split()
    if t and t[0] == "F": d[int(t[1])] = dict(kv.split("=", 1) for kv in t[2:])
if not d: sys.exit(f"VOID: {p} has no samples")
if d[min(d)].get("id") != "16": sys.exit(f"VOID: {leg} P1 id is {d[min(d)].get('id')} at {min(d)}, not Phobos (16)")
start = next((f for f in sorted(d) if d[f].get("rnd") == "1"), None)
print(f"start\t{leg}\t{start}")
for f in (2363, 2370, 2395, 2481, 2544, 2560, 2600):
    if f not in d: sys.exit(f"VOID: {leg} has no sample at {f}")
    print(f"at\t{leg}\t{f}\tx={d[f]['x']}\tseq={d[f]['seq']}")
PY
}
swap_entrance() {  # swap_entrance <native rows> <ours rows>: ours' at-rows carry native's x and seq
    python3 - "$1" "$2" <<'PY'
import sys
nat = {l.split("\t")[2]: l.rstrip("\n").split("\t")[3:] for l in open(sys.argv[1]) if l.startswith("at\t")}
for l in open(sys.argv[2]):
    t = l.rstrip("\n").split("\t")
    if t[0] == "at" and t[2] in nat: t[3:] = nat[t[2]]
    print("\t".join(t))
PY
}

echo "== 1. the opening, both legs ($PART, frames 2300-$FR)"
j="$REPO/tests/replays/naming/$PART.json"; r="$REPO/tests/replays/naming/$PART.rpl"
pk="$(pokes_for "$j" "$FR")"
rpl_for "$TENANT" "$r" native "$W/native.rpl"; rpl_for "$TENANT" "$r" ours "$W/ours.rpl"
sample native vsav2  "$ROMDIR" "$W/native.rpl" "$pk"
sample ours   vsavjw "$BUILD/rompath;$ROMDIR" "$W/ours.rpl" "$pk"
wait
for leg in native ours; do
    _rc="$(cat "$W/$leg/rc" 2>/dev/null || echo none)"; [ "$_rc" = 0 ] || bad "$leg: the emulator exited $_rc"
    reduce "$leg" "$W/$leg.tr" > "$W/$leg.rows" 2> "$W/$leg.err" || bad "$leg: $(cat "$W/$leg.err")"
done
[ "$fail" = 0 ] || { echo "FAIL: audit_rig_opening (a leg did not run or was VOID)"; exit 1; }
if [ "$CONTROL" = entrance-swapped ]; then swap_entrance "$W/native.rows" "$W/ours.rows" > "$W/ours.sw" && mv "$W/ours.sw" "$W/ours.rows"; fi
cat "$W/native.rows" "$W/ours.rows" > "$W/got.tsv"
sed 's/^/  /' "$W/got.tsv"

echo "== 2. the frozen rows"
if [ "${FREEZE:-0}" = 1 ]; then
    {
        echo "# tests/expected/rig_opening.tsv — the #136 guard-cancel rig's opening (huitzil_5), ours (merged-m18) vs native vsav2"
        echo "# (tests/audit_rig_opening.sh; tests/lua/field_trace.lua). Evidence class: in-emulator. Frozen 14z-167 with FREEZE=1."
        echo "# THE RIG ARTIFACT IS FROZEN AS MEASURED: the round starts after the rig's first X pin (2370), the legs draw different"
        echo "# entrances and stand apart at the first event. The rig change that pins after the round start re-freezes this file."
        echo "# Columns: start <leg> <first frame \$FF812D = 1> | at <leg> <frame> x= seq="
        echo "#--"
        cat "$W/got.tsv"
    } > "$EXPECT"
    echo "  FROZE  $(basename "$EXPECT") ($(wc -l < "$W/got.tsv" | tr -d ' ') rows) — VERIFY by re-running without FREEZE"; exit 0
fi
[ -f "$EXPECT" ] || { echo "FAIL: no frozen expectation at $EXPECT (FREEZE=1 to create it)"; exit 1; }
grep -v '^#' "$EXPECT" > "$W/want.tsv"
if diff "$W/want.tsv" "$W/got.tsv" > "$W/diff.txt"; then ok "every row as frozen"
else bad "differs from the frozen rows"; sed 's/^/        /' "$W/diff.txt"; fi

echo "== 3. must-fire controls"
if [ "$CONTROL" = entrance-swapped ]; then
    if [ "$fail" = 1 ]; then echo "CONTROL FIRED: entrance-swapped — our opening with native's entrance loses the frozen rows"; echo "FAIL: audit_rig_opening (control mode)"; exit 1
    else echo "CONTROL DEAD: entrance-swapped — the swapped opening still matched"; echo "FAIL: audit_rig_opening"; exit 1; fi
fi
swap_entrance "$W/native.rows" "$W/ours.rows" > "$W/ctl.rows"
if diff -q "$W/ours.rows" "$W/ctl.rows" > /dev/null; then echo "CONTROL DEAD: entrance-swapped — native's opening equals ours, nothing to discriminate"; fail=1
else echo "CONTROL FIRED: entrance-swapped — our opening with native's x and seq differs from the frozen rows ($(diff "$W/ours.rows" "$W/ctl.rows" | grep -c '^>' | tr -d ' ') rows)"; fi

if [ "$fail" = 0 ]; then echo "PASS: audit_rig_opening"; else echo "FAIL: audit_rig_opening"; exit 1; fi
