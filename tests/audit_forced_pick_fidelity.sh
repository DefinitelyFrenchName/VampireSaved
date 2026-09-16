#!/bin/sh
# audit_forced_pick_fidelity.sh — IS A FORCED-PICK NATIVE LEG FAITHFUL? The rig's poked pick vs a REAL cursor pick of the same tenant on native vsav2, diffed over the WHOLE fighter block (GitHub #151, 14z-160).
#
# MUST-FIRE: perturbed-copy: same-leg — the poked leg diffed against ITSELF yields no latched offset, and that empty set must fail the frozen non-empty expectation (in-gate: the first row's poked leg is diffed against itself and must come out empty where the frozen set is not; mode: every row is diffed leg-against-itself and the comparison FAILs)
# MUST-FIRE: known-bad: wrong-cursor — a real-cursor leg whose path is one move short confirms ANOTHER character, and the gate's identity assertion on the real leg must FAIL (in-gate: one extra leg with the last cursor move dropped; mode: every real leg runs one move short and the identity assertions FAIL)
#
# WHY. tests/audit_move_parity.sh (#136) forces Phobos and Pyron on its NATIVE
# leg with the early-window poke ([VSP-123]: RAM:$FF8782 := id at frames
# 1400/1450/1500). The select CONFIRM runs at frame ~1299, BEFORE those pokes,
# so every per-fighter field the confirm path writes is latched for the
# character the cursor was on — Donovan, the default cell's R,R — and the poke
# then swaps the id underneath it. #147 shipped a wrong fix to a freeze on
# exactly that: RAM:$FF87C2 (the VS2/VH2 flavor latch, +0x3C2) read Donovan's
# 0x01 on a "native Phobos" leg and the fix flipped our default to match it
# (14z-159; docs/project/gotchas.md "A FORCED-PICK NATIVE LEG MEASURES THE
# RIG"). The gate had no control proving its native leg faithful. This is that
# control, and it diffs the WHOLE block rather than a field list, because a
# field list is how +0x3C2 was missed.
#
# WHAT IT MEASURES, per row of tests/expected/forced_pick_fidelity.tsv:
#   POKED  — the #136 rig's own native leg: prologue R,R (Donovan's confirm)
#            + the id poke, + the rig's level and RNG pins (pokes_for, copied).
#   REAL   — the same rig with a REAL cursor path to the tenant (decoded from
#            vsav2's TABLE B by tools/select_wheel.py: from the default cell
#            Phobos is L,L,L and Pyron R,R,R) and NO id poke.
#   SELF   — the REAL path PLUS the same-id poke: isolates the poke MECHANISM
#            (a write at 1400-1500 to an id that already holds that value)
#            from the confirm's latch. Expected empty.
# Work RAM $FF8000-$FF8BFF (globals, P1 block $FF8400, P2 block $FF8800) is
# dumped at fixed frames and every differing byte of the P1 BLOCK between
# POKED and REAL is classified:
#   LATCHED   differs at EVERY pre-match sample from the last poke (1501) to
#             the frame before the match anchor (2362) — what the confirm
#             latched and the poke cannot reach;
#   TRANSIENT differs at some pre-match sample, not all;
#   PLAY      first differs at or after the rig's first event (2600).
# The frozen expectation is the LATCHED set per row (offsets into the P1
# block) and whether PLAY differences follow (the latch's behavioural
# consequence). P2's block and the globals are reported, not frozen: P2 is
# Victor by the same R,R on every leg, so its block is the instrument's own
# negative control and is asserted EMPTY pre-match.
#
# IDENTITY is asserted on every leg, never assumed: RAM:$FF8782 (the id at
# select/commit, [VSP-123]) must equal the tenant's id at 1600 (after the last
# poke, before the match) on POKED, REAL and SELF, and the REAL leg's cursor
# cell RAM:$FF8403 must equal it at 1290 (before the confirm).
#
# The donovan-self row is the negative control of the whole method: R,R IS
# Donovan on vsav2, so poking 0x13 over Donovan's own confirm must latch
# NOTHING — if it does, the poke mechanism itself perturbs state and every
# LATCHED finding above is suspect.
#
# Usage: ROMDIR=... [MAME_BIN=...] [ROWS="huitzil pyron donovan-self"] [JOBS=6] [FREEZE=1] [MEASURE=1] tests/audit_forced_pick_fidelity.sh
#   emulator tier, MAME, native vsav2 only (no build). MEASURE=1 prints every
#   differing offset with its values and classification and freezes nothing.
set -eu

[ -n "${ROMDIR:-}" ] || { echo "FAIL: set ROMDIR"; exit 1; }
[ -d "$ROMDIR" ] && ROMDIR="$(cd "$ROMDIR" && pwd)"
REPO="$(cd "$(dirname "$0")/.." && pwd)"
MAME_BIN="${MAME_BIN:-$HOME/.cache/vampire-saved/mame/cps2}"
export MAME_BIN
EXPECT="$REPO/tests/expected/forced_pick_fidelity.tsv"
JOBS="${JOBS:-6}"
CONTROL="${CONTROL:-}"
ROWS="${ROWS:-huitzil pyron donovan-self}"

[ -x "$MAME_BIN" ] || { echo "SKIP: no MAME at $MAME_BIN"; exit 0; }
[ -f "$ROMDIR/vsav2.zip" ] || { echo "SKIP: no vsav2.zip in $ROMDIR"; exit 0; }
case "$CONTROL" in
    ""|same-leg|wrong-cursor) ;;
    *) echo "REFUSED: no control named '$CONTROL' is declared by this gate"; exit 3 ;;
esac
if [ "${FREEZE:-0}" != 1 ] && [ "${MEASURE:-0}" != 1 ]; then
    [ -f "$EXPECT" ] || { echo "FAIL: no frozen expectation at $EXPECT (FREEZE=1 to create it)"; exit 1; }
fi

W="$(mktemp -d)"
trap 'rm -rf "$W"' EXIT INT TERM
fail=0
ok()  { printf '  ok    %s\n' "$1"; }
bad() { printf '  FAIL  %s\n' "$1"; fail=1; }

# Every row: tenant id, the rig part whose schedule supplies the pins, and the
# REAL cursor path from vsav2's default P1 cell (0x01: the only cell whose R,R
# is 0x13, which is what the naming rigs measure Donovan by).
row_id()   { case "$1" in huitzil) echo 10;; pyron) echo 11;; donovan-self) echo 13;; esac; }
row_rig()  { case "$1" in huitzil) echo huitzil_1;; pyron) echo pyron_1;; donovan-self) echo donovan_1;; esac; }
row_path() { case "$1" in huitzil) echo "L L L";; pyron) echo "R R R";; donovan-self) echo "R R";; esac; }

END=3400          # the rig is cut here: the first events (walk, walk back, crouch, JUMP) are enough
FIRST_EVENT=2600
# dump frames: around the confirm and the pokes, the pre-match run-up, then play
DFRAMES="1290 1310 1399 1401 1451 1501 1600 1800 2000 2200 2362 2400 2500 2599"
f=2600; while [ $f -le $END ]; do DFRAMES="$DFRAMES $f"; f=$((f + 20)); done
DSPEC="$(for f in $DFRAMES; do printf '%s:ff8000-ff8c00;' "$f"; done)"

# ONE function writes a leg's replay and pokes, so what the controls perturb
# is what the gate asserts ([VSP-181]).
#   mkleg <row> <leg: poked|real|self> <name> [short]
mkleg() {
    _row="$1"; _leg="$2"; _name="$3"; _short="${4:-}"
    _id="$(row_id "$_row")"; _rig="$(row_rig "$_row")"
    _j="$REPO/tests/replays/naming/$_rig.json"; _r="$REPO/tests/replays/naming/$_rig.rpl"
    mkdir -p "$W/$_name"
    _path="R R"                                   # the rig's own prologue: Donovan's confirm
    [ "$_leg" = poked ] || _path="$(row_path "$_row")"
    if [ "$_short" = short ]; then _path="$(echo $_path | awk '{$NF=""; print}')"; fi
    {
        printf '300-305 sys=C1\n420-425 sys=C2\n800-803 sys=S1\n940-943 sys=S2\n'
        _t=1100; for _m in $_path; do printf '%d-%d p1=%s\n' $_t $((_t + 2)) "$_m"; _t=$((_t + 60)); done
        printf '1104-1106 p2=R\n1164-1166 p2=R\n1300-1302 p1=1\n1360-1362 p2=1\n'
        # the rig's events up to END (its prologue lines are the ones above, re-emitted)
        awk -v end=$END '!/^#/ && !/^(300|420|800|940|1100|1160|1104|1164|1300|1360)-/ && $1+0 >= 2000 { split($1, a, "-"); if (a[1]+0 <= end) print }' "$_r"
        printf '%d wait\n' $END
    } > "$W/$_name/leg.rpl"
    # pokes: the rig's own (id pokes stripped, re-added below), the level pin
    # from 2000 and the RNG pin from the match anchor — pokes_for's protocol.
    _base="$(python3 -c "
import json; p=[x for x in json.load(open('$_j'))['pokes'] if ':ff8782:' not in x and int(x.split(':')[0]) <= $END]; print(';'.join(p))")"
    _lvl="$(python3 -c "print(';'.join(f'{f}:ff8116:06' for f in range(2000,$END)))")"
    _rng="$(python3 -c "print(';'.join(f'{f}:ff80d4:0000' for f in range(2363,$END)))")"
    _pick="$(python3 -c "print(';'.join(f'{f}:ff8782:$_id' for f in (1400,1450,1500)))")"
    case "$_leg" in
        real) printf '%s;%s;%s' "$_base" "$_lvl" "$_rng" ;;
        *)    printf '%s;%s;%s;%s' "$_pick" "$_base" "$_lvl" "$_rng" ;;
    esac > "$W/$_name/pokes"
}

runleg() {   # runleg <name>  (background; the caller waits)
    _name="$1"
    ( DUMPS="$DSPEC" POKES="$(cat "$W/$_name/pokes")" REPLAY="$W/$_name/leg.rpl" \
      CHECKSUM_OUT="$W/$_name/c.log" MAME_SANDBOX="$W/$_name/sb" MAME_ROMPATH="$ROMDIR" \
      "$REPO/tools/run_mame.sh" vsav2 -autoboot_script "$REPO/tests/lua/replay.lua" \
        > "$W/$_name/mame.log" 2>&1
      rm -rf "$W/$_name/sb" ) </dev/null &
}

# the reducer: identity, then the classified P1-block diff
# classify <A name> <B name> <id hex> <real leg name or ->  -> prints TSV fields
classify() {
    python3 - "$W" "$1" "$2" "$3" "$4" "$FIRST_EVENT" "${MEASURE:-0}" <<'EOF'
import sys, os
W, A, B, ID, REAL, FE, MEASURE = sys.argv[1:8]
FE = int(FE); ID = int(ID, 16); MEASURE = MEASURE == "1"
def dumps(name):
    out = {}
    for fn in os.listdir(f"{W}/{name}"):
        if fn.startswith("dump_") and fn.endswith("_ff8000.bin"):
            out[int(fn.split("_")[1])] = open(f"{W}/{name}/{fn}", "rb").read()
    return out
da, db = dumps(A), dumps(B)
frames = sorted(set(da) & set(db))
if not frames or len(da) != len(db):
    print(f"VOID\tdumps A={len(da)} B={len(db)}"); sys.exit(0)
def byte(d, f, addr): return d[f][addr - 0xFF8000]
# identity: $FF8782 at 1600 on both; the REAL leg's cursor cell $FF8403 at 1290
idn = []
for name, d in ((A, da), (B, db)):
    v = byte(d, 1600, 0xFF8782)
    idn.append(f"{name}:id@1600={v:02x}")
    if v != ID: idn.append(f"{name}:ID-MISMATCH(want {ID:02x})")
if REAL != "-":
    dr = da if REAL == A else db
    c = byte(dr, 1290, 0xFF8403)
    idn.append(f"{REAL}:cell@1290={c:02x}")
    if c != ID: idn.append(f"{REAL}:CELL-MISMATCH(want {ID:02x})")
pre = [f for f in frames if 1501 <= f <= 2362]
early = [f for f in frames if f < 1501]        # confirm-time transients the poke overwrites (cell, id)
play = [f for f in frames if f >= FE]
def diff_region(lo, hi):
    res = {}
    for off in range(lo, hi):
        fr = [f for f in frames if da[f][off] != db[f][off]]
        if fr: res[off] = fr
    return res
p1 = diff_region(0x400, 0x800); p2 = diff_region(0x800, 0xC00); gl = diff_region(0x000, 0x400)
latched, transient, earlyonly, playonly = [], [], [], []
for off, fr in sorted(p1.items()):
    prefr = [f for f in fr if f in pre]
    if prefr and len(prefr) == len(pre): latched.append(off)
    elif prefr: transient.append(off)
    elif all(f < 1501 for f in fr): earlyonly.append(off)
    else: playonly.append(off)
first_play = min((min(f for f in fr if f >= FE) for off, fr in p1.items()
                  if off not in latched and any(f >= FE for f in fr)), default=None)
p2pre = sorted(off for off, fr in p2.items() if any(f in pre for f in fr))
fmt = lambda xs: ",".join(f"+{o - 0x400:03x}" for o in xs) if xs else "-"
if MEASURE:   # diagnostics go to stderr; stdout is the one TSV line the caller parses
    e = sys.stderr
    for off in sorted(p1):
        fr = p1[off]
        cls = "LATCHED" if off in latched else "TRANSIENT" if off in transient else "EARLY" if off in earlyonly else "PLAY"
        vals = " ".join(f"{f}:{da[f][off]:02x}/{db[f][off]:02x}" for f in fr[:6])
        print(f"    P1 +{off - 0x400:03x} {cls:9s} {len(fr):3d} frames  first {fr[0]}  {vals}", file=e)
    for off in sorted(gl):
        fr = gl[off]; vals = " ".join(f"{f}:{da[f][off]:02x}/{db[f][off]:02x}" for f in fr[:4])
        print(f"    GL {0xFF8000 + off:06x} {len(fr):3d} frames  first {fr[0]}  {vals}", file=e)
    for off in sorted(p2): print(f"    P2 +{off - 0x800:03x} {len(p2[off]):3d} frames  first {p2[off][0]}", file=e)
print("\t".join([fmt(latched), str(len(transient)), str(len(playonly)),
                 str(first_play) if first_play else "-", fmt(p2pre) if p2pre else "-", " ".join(idn)]))
EOF
}

echo "== 1. the legs ($(echo $ROWS | wc -w | tr -d ' ') rows x 3 + 1 wrong-cursor control leg, native vsav2)"
n=0
for row in $ROWS; do
    for leg in poked real self; do
        mkleg "$row" "$leg" "${row}_$leg" "$([ "$CONTROL" = wrong-cursor ] && [ "$leg" != poked ] && echo short)"
        runleg "${row}_$leg"; n=$((n + 1)); [ $((n % JOBS)) -eq 0 ] && wait
    done
done
CTLROW="$(echo $ROWS | awk '{print $1}')"
mkleg "$CTLROW" real "${CTLROW}_wrongcursor" short
runleg "${CTLROW}_wrongcursor"; n=$((n + 1))
wait
for row in $ROWS; do
    for leg in poked real self; do
        [ "$(ls "$W/${row}_$leg"/dump_*_ff8000.bin 2>/dev/null | wc -l)" -ge 30 ] \
            || bad "${row}_$leg produced no dumps (see $W/${row}_$leg/mame.log)"
    done
done
[ "$fail" = 0 ] || { echo "FAIL: a leg did not run"; exit 1; }
ok "$n legs ran"

echo "== 2. identity on every leg, the P2 block empty pre-match, and the LATCHED set per row"
: > "$W/got.tsv"
for row in $ROWS; do
    id="$(row_id "$row")"
    A="${row}_poked"; B="${row}_real"; R="${row}_real"
    [ "$CONTROL" = same-leg ] && { B="$A"; R=-; }    # the mode compares the poked leg with itself; no real-leg cell to check there
    line="$(classify "$A" "$B" "$id" "$R")"
    self="$(classify "${row}_real" "${row}_self" "$id" "${row}_real")"
    case "$line" in VOID*) bad "$row: $line"; continue;; esac
    latched="$(printf '%s' "$line" | cut -f1)"; tr_="$(printf '%s' "$line" | cut -f2)"
    po="$(printf '%s' "$line" | cut -f3)"; fp="$(printf '%s' "$line" | cut -f4)"
    p2pre="$(printf '%s' "$line" | cut -f5)"; idn="$(printf '%s' "$line" | cut -f6)"
    selfl="$(printf '%s' "$self" | cut -f1)"; selfidn="$(printf '%s' "$self" | cut -f6)"
    case "$idn $selfidn" in *MISMATCH*) bad "$row: identity — $idn / $selfidn";; *) ok "$row: identity — $idn";; esac
    [ "$p2pre" = "-" ] && ok "$row: P2 block (Victor on every leg) has no pre-match difference" \
                       || bad "$row: P2 block differs pre-match at $p2pre — the instrument's negative control is not clean"
    [ "$selfl" = "-" ] && ok "$row: REAL vs SELF latches nothing (the poke mechanism itself is inert)" \
                       || bad "$row: REAL vs SELF latches $selfl — the poke mechanism perturbs state"
    echo "  $row: POKED vs REAL latched [$latched] transient $tr_ play-only $po first-play-diff $fp (early-only differences are the cell and id the poke overwrites)"
    printf '%s\t%s\t%s\n' "$row" "$latched" "$fp" >> "$W/got.tsv"
done
[ "${MEASURE:-0}" = 1 ] && { echo "MEASURE: nothing frozen, nothing compared"; exit 0; }
if [ "${FREEZE:-0}" = 1 ]; then
    { sed -n '1,/^#--$/p' "$EXPECT" 2>/dev/null || true; cat "$W/got.tsv"; } > "$W/new.tsv"
    cp "$W/new.tsv" "$EXPECT"
    echo "  FROZE  $(basename "$EXPECT") ($(wc -l < "$W/got.tsv" | tr -d ' ') rows) — VERIFY by re-running without FREEZE"
    exit 0
fi
while IFS="$(printf '\t')" read -r row latched fp; do
    [ -n "$row" ] || continue
    want="$(awk -F'\t' -v n="$row" '!/^#/ && $1==n {print $2"\t"$3}' "$EXPECT")"
    got="$(printf '%s\t%s' "$latched" "$fp")"
    if [ -z "$want" ]; then bad "$row: no row in $(basename "$EXPECT")"
    elif [ "$want" = "$got" ]; then ok "$row: latched [$latched], first play difference $fp — as frozen"
    else bad "$row: expected [$want] measured [$got]"; fi
done < "$W/got.tsv"

echo "== 3. must-fire controls"
# same-leg: the first row's poked leg against itself must be EMPTY where the
# frozen set is not — proving a vanished difference would be noticed.
sl="$(classify "${CTLROW}_poked" "${CTLROW}_poked" "$(row_id "$CTLROW")" - | cut -f1)"
fz="$(awk -F'\t' -v n="$CTLROW" '!/^#/ && $1==n {print $2}' "$EXPECT")"
if [ "$sl" = "-" ] && [ "$fz" != "-" ] && [ -n "$fz" ]; then
    echo "CONTROL FIRED: same-leg — $CTLROW poked-vs-poked latches nothing where the frozen set is [$fz]"
else
    echo "CONTROL DEAD: same-leg — poked-vs-poked read [$sl] against frozen [$fz]"; fail=1
fi
# wrong-cursor: one move short must confirm another character and fail identity
wc_="$(classify "${CTLROW}_wrongcursor" "${CTLROW}_wrongcursor" "$(row_id "$CTLROW")" "${CTLROW}_wrongcursor" | cut -f6)"
case "$wc_" in
    *MISMATCH*) echo "CONTROL FIRED: wrong-cursor — the one-move-short real leg reads $wc_" ;;
    *) echo "CONTROL DEAD: wrong-cursor — the one-move-short real leg still reads the tenant: $wc_"; fail=1 ;;
esac

if [ "$fail" = 0 ]; then echo "PASS: audit_forced_pick_fidelity"; else echo "FAIL: audit_forced_pick_fidelity"; exit 1; fi
