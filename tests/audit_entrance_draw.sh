#!/bin/sh
# audit_entrance_draw.sh — PHOBOS'S ROUND-START ENTRANCE IS DRAWN FROM THE SAME THREE VARIANTS ON OUR BUILD AS ON vsav2 (14z-168, GitHub #136): the legs of #136's guard-cancel rigs drew different entrances because the draw follows each game's RNG state at character load, not because our build lost one — over six seeds both legs draw fighter +0x0A in {0, 2, 6}.
#
# WHAT: Phobos's round-start entrance is drawn from the same three variants (0 drive-in, 2
#   and 6 held) on our build as on vsav2: over six RNG seeds the two games draw DIFFERENT
#   variants per seed but the SAME set — so #136's differing openings were the draw, not a
#   lost entrance.
# HOW: 12 short field-trace runs in parallel on MAME (six seeds x two legs on huitzil_5)
#   reading fighter +0x0A through the intro and P1's x; a draw's variant is the first value
#   other than 0/255 after initialisation and must agree with the position (the drive-in
#   moves x through three values), else VOID; the control rewrites our draws to variant 6.
# EXPECTS: the per-seed rows frozen and the two legs' variant SETS equal; the rewritten
#   copy's set differs and fails.
# FOLLOWS: build/manifest/ emu/mame-patches/ tests/expected/entrance_draw.tsv
#   tests/lua/field_trace.lua tools/name_moves.py tools/run_mame.sh tools/setup_mame.sh
#
# MUST-FIRE: perturbed-copy: variant-lost — a copy of our rows with every drive-in draw rewritten to the held variant 6 (what a build that lost the car arrival would read) must FAIL the set compare against native, so the compared sets are what the draws produced (in-gate: the perturbed copy's set must differ from native's; mode: our rows are rewritten before the compare and the table FAILs)
#
# WHY. 14z-167 found #136's huitzil_5/6/7 first-event DIFF rows are the round-start
# entrance (tests/audit_rig_opening.sh): native drew the car arrival, ours the arrival
# with Cecil in hand, and the maintainer named three entrances on the capture. Whether
# our build CAN draw the car arrival was unmeasured. Measured 14z-168: the variant is
# written to fighter +0x0A during the intro (0 = the drive-in from x=360; 2 and 6 hold
# Phobos at the pinned 552), and one RNG poke at 2250 (no RNG pin, the level pinned)
# selects it — the two games draw DIFFERENT variants for a given seed (their RNG
# consumption differs — the RNG paragraph of docs/game/engine_internals.md's anim-walker section), but the SAME SET.
#
# WHAT IT FREEZES (tests/expected/entrance_draw.tsv): `draw <leg> <seed> <variant>
# drive=<yes|no> x2363=<P1 x>` for seeds 0000 1234 5a5a 9e37 c3d2 ffff on the rig
# huitzil_5 (first event 2800), and `set <leg> <the union of the variants>`. THE
# VARIANT OF ONE DRAW (corrected 14z-168 after rule-checker run 2026-09-18-46 Q3):
# +0x0A goes 255 -> 0 when the intro initialises, then either stays 0 (the drive-in)
# or takes 2 or 6 (held at 552) and returns to 0 when that pose ends — so the 0 every
# trace shows is NOT a draw. The variant is the first value other than 0/255 after
# initialisation, else 0; it must agree with the position, read independently: the
# drive-in moves P1 x through at least three values strictly between 0 and 552, a held
# variant never does. A draw where the two disagree is VOID, not a row.
#
# Usage: ROMDIR=... [MAME_BIN=...] [BUILD=build/m3b_merged27] [FREEZE=1] tests/audit_entrance_draw.sh
#   emulator tier, MAME; 12 short field_trace runs in parallel — measured 14z-168 on this MacBook, solo: ~15 s wall
set -eu
[ -n "${ROMDIR:-}" ] || { echo "FAIL: set ROMDIR"; exit 1; }
[ -d "$ROMDIR" ] && ROMDIR="$(cd "$ROMDIR" && pwd)"
REPO="$(cd "$(dirname "$0")/.." && pwd)"
MAME_BIN="${MAME_BIN:-$HOME/.cache/vampire-saved/mame/cps2}"; export MAME_BIN
BUILD="${BUILD:-build/m3b_merged27}"
case "$BUILD" in /*) ;; *) BUILD="$REPO/$BUILD" ;; esac
EXPECT="$REPO/tests/expected/entrance_draw.tsv"
CONTROL="${CONTROL:-}"
[ -x "$MAME_BIN" ] || { echo "SKIP: no MAME at $MAME_BIN"; exit 0; }
[ -f "$ROMDIR/vsav2.zip" ] || { echo "SKIP: no vsav2.zip in $ROMDIR"; exit 0; }
[ -f "$BUILD/rompath/vsavjw.zip" ] || { echo "SKIP: no WIDE build at $BUILD"; exit 0; }
case "$CONTROL" in ""|variant-lost) ;; *) echo "REFUSED: no control named '$CONTROL' is declared by this gate"; exit 3 ;; esac
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT INT TERM
fail=0
ok()  { printf '  ok    %s\n' "$1"; }
bad() { printf '  FAIL  %s\n' "$1"; fail=1; }
FR=2560; SEEDS="0000 1234 5a5a 9e37 c3d2 ffff"
( cd "$REPO" && python3 - "$W" <<'PY'
import sys, contextlib, io
sys.path.insert(0, "tools"); import name_moves as nm
nm.FIRST_EVENT = 2800
with contextlib.redirect_stdout(io.StringIO()):
    nm.gen("huitzil", "5", f"{sys.argv[1]}/rig.rpl", f"{sys.argv[1]}/rig.json")
PY
) || { echo "FAIL: rig generation"; exit 1; }
# our leg's cursor path on the merged wheel (tests/audit_move_parity.sh rpl_for)
awk '/^1104-1106 p2=R$/ && !done { print "1100-1102 p1=D"; print "1160-1162 p1=D"; print "1220-1222 p1=D"; done = 1 }
     /^(1100|1160|1220|1280)-[0-9]+ p1=/ { next } { print }' "$W/rig.rpl" > "$W/ours.rpl"
BASE="$(python3 -c "import json;print(';'.join(json.load(open('$W/rig.json'))['pokes']))");$(python3 -c "print(';'.join(f'{f}:ff8116:06' for f in range(2000,$FR)))")"
for s in $SEEDS; do for leg in native ours; do
    if [ $leg = native ]; then set_=vsav2; rp="$ROMDIR"; r="$W/rig.rpl"; else set_=vsavjw; rp="$BUILD/rompath;$ROMDIR"; r="$W/ours.rpl"; fi
    d="$W/$leg.$s"; mkdir -p "$d"
    # (14z-168) MAME can segfault at TEARDOWN after the instrument has closed its log (docs/platform/gotchas.md):
    # `set +e` keeps the status write alive, and a run whose instrument wrote its summary line counts as
    # completed (docs/project/gotchas.md, the set -e capture entry)
    ( set +e; cd "$d" && MAME_SANDBOX="$d/sb" MAME_ROMPATH="$rp" REPLAY="$r" POKES="$BASE;2250:ff80d4:$s" \
        FIELDS="ff840a:b:intro,ff8410:w:x,ff8782:b:id" FIELD_OUT="$d.ft" FIELD_FROM=2300 FIELD_TO="$FR" FRAMES="$FR" \
        "$REPO/tools/run_mame.sh" "$set_" -autoboot_script "$REPO/tests/lua/field_trace.lua" > "$d/mame.log" 2>&1
      _st=$?; grep -q -E '^(FIELDSUMMARY|END )' "$d.ft" 2>/dev/null && _st=0; echo $_st > "$d/rc"; rm -rf "$d/sb" ) </dev/null &
done; done
wait
for s in $SEEDS; do for leg in native ours; do _rc="$(cat "$W/$leg.$s/rc" 2>/dev/null || echo none)"; [ "$_rc" = 0 ] || bad "$leg $s exited $_rc"; done; done
[ "$fail" = 0 ] || { echo "FAIL: audit_entrance_draw"; exit 1; }
python3 - "$W" "$SEEDS" > "$W/got.tsv" 2> "$W/err" <<'PY' || bad "$(cat "$W/err")"
import sys
W, seeds = sys.argv[1], sys.argv[2].split()
sets = {}
for leg in ("native", "ours"):
    for s in seeds:
        d = {}
        for l in open(f"{W}/{leg}.{s}.ft"):
            t = l.split()
            if t and t[0] == "F": d[int(t[1])] = {k: int(v) for k, v in (kv.split("=", 1) for kv in t[2:])}
        if 2300 not in d or max(d) < 2544: sys.exit(f"VOID: {leg} {s} trace incomplete")
        if d[2300]["id"] != 0x10: sys.exit(f"VOID: {leg} {s} P1 is {d[2300]['id']:#x}, not Phobos")
        f0 = min((f for f in range(2300, 2545) if d[f]["intro"] != 255), default=None)
        if f0 is None: sys.exit(f"VOID: {leg} {s} the intro never initialised +0x0A")
        held = [d[f]["intro"] for f in range(f0, 2545) if d[f]["intro"] not in (0, 255)]
        v = held[0] if held else 0
        drive = len({d[f]["x"] for f in range(f0, 2545) if 0 < d[f]["x"] < 552}) >= 3
        if drive != (v == 0): sys.exit(f"VOID: {leg} {s} variant {v} but drive-in {drive} — the two readings disagree")
        sets.setdefault(leg, set()).add(v)
        print(f"draw\t{leg}\t{s}\t{v}\tdrive={'yes' if drive else 'no'}\tx2363={d[2363]['x']}")
for leg in ("native", "ours"):
    print(f"set\t{leg}\t{','.join(map(str, sorted(sets[leg])))}")
PY
[ "$fail" = 0 ] || { echo "FAIL: audit_entrance_draw"; exit 1; }
# the perturbation rewrites the draw rows AND recomputes the set row from them, so the set compare sees it
lost() { awk -F'\t' 'BEGIN{OFS="\t"} $1=="draw" && $2=="ours" && $4=="0" {$4="6"; $5="drive=no"}
    $1=="draw" {u[$2] = u[$2] "," $4} $1!="set" {print}
    END {for (l in u) {n = split(substr(u[l], 2), a, ","); s = ""; for (v = 0; v < 256; v++) for (i = 1; i <= n; i++) if (a[i] == v) {s = s (s == "" ? "" : ",") v; break}
         print "set", l, s}}' "$1" | sort -t'	' -k1,2 -s > "$2"; }
if [ "$CONTROL" = variant-lost ]; then lost "$W/got.tsv" "$W/got.l" && mv "$W/got.l" "$W/got.tsv"; fi
sed 's/^/  /' "$W/got.tsv"
[ "$(awk -F'\t' '$1=="set" && $2=="native"{print $3}' "$W/got.tsv")" = "$(awk -F'\t' '$1=="set" && $2=="ours"{print $3}' "$W/got.tsv")" ] \
    && ok "both legs draw the same set of entrance variants" || bad "the legs draw different entrance sets"

if [ "${FREEZE:-0}" = 1 ]; then
    { echo "# tests/expected/entrance_draw.tsv — Phobos's round-start entrance variant (fighter +0x0A) over six RNG seeds, ours (merged-m18)"
      echo "# vs native vsav2 (tests/audit_entrance_draw.sh; tests/lua/field_trace.lua). Evidence class: in-emulator. Frozen 14z-168 with"
      echo "# FREEZE=1 (GitHub #136). Columns: draw <leg> <seed> <variant> drive=<yes|no> x2363=<P1 x> | set <leg> <union>"
      echo "#--"; cat "$W/got.tsv"; } > "$EXPECT"
    echo "  FROZE  $(basename "$EXPECT") — VERIFY by re-running without FREEZE"; exit 0
fi
[ -f "$EXPECT" ] || { echo "FAIL: no frozen expectation at $EXPECT (FREEZE=1 to create it)"; exit 1; }
grep -v '^#' "$EXPECT" > "$W/want.tsv"
if diff "$W/want.tsv" "$W/got.tsv" > "$W/diff.txt"; then ok "every row as frozen"
else bad "differs from the frozen rows"; sed 's/^/        /' "$W/diff.txt"; fi

if [ "$CONTROL" = variant-lost ]; then
    if [ "$fail" = 1 ]; then echo "CONTROL FIRED: variant-lost — our rows without the car arrival lose the frozen rows"; echo "FAIL: audit_entrance_draw (control mode)"; exit 1
    else echo "CONTROL DEAD: variant-lost — the rewrite changed nothing"; echo "FAIL: audit_entrance_draw"; exit 1; fi
fi
lost "$W/got.tsv" "$W/ctl.tsv"
_n="$(awk -F'\t' '$1=="set" && $2=="native"{print $3}' "$W/ctl.tsv")"; _o="$(awk -F'\t' '$1=="set" && $2=="ours"{print $3}' "$W/ctl.tsv")"
if [ "$_n" = "$_o" ]; then echo "CONTROL DEAD: variant-lost — our set without the drive-in still equals native's ($_o)"; fail=1
else echo "CONTROL FIRED: variant-lost — without the drive-in our set reads $_o against native's $_n"; fi
if [ "$fail" = 0 ]; then echo "PASS: audit_entrance_draw"; else echo "FAIL: audit_entrance_draw"; exit 1; fi
