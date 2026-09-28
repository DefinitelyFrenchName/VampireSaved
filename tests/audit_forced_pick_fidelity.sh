#!/bin/sh
# audit_forced_pick_fidelity.sh — IS A FORCED-PICK NATIVE LEG FAITHFUL? The rig's poked pick vs a REAL cursor pick of the same tenant on native vsav2, diffed over the WHOLE fighter block (GitHub #151, 14z-160).
#
# WHAT: whether a forced-pick native leg is faithful: the #136 rig's poked pick of a tenant
#   on native vsav2, diffed over the WHOLE P1 fighter block against a REAL cursor pick of
#   the same tenant, freezing the offsets the confirm LATCHED for the cursor character that
#   the poke cannot reach (the #147 mechanism) and whether PLAY differences follow.
# HOW: per row (Phobos, Pyron, the donovan-self negative control) three MAME legs: POKED
#   (R,R + the id poke), REAL (the decoded cursor path, no poke) and SELF (real path plus
#   the same-id poke, expected empty), each built by the rig's own rpl_for and pokes_for
#   (read out of tests/audit_move_parity.sh; #155) and asserted to be the committed rig; work RAM dumped at fixed frames, every differing
#   P1-block byte classed LATCHED / TRANSIENT / PLAY; identity asserted on every leg from
#   the id at 1600 and the cursor cell at 1290; controls diff a leg against itself and drop
#   the last cursor move.
# EXPECTS: the frozen LATCHED set per row, SELF empty, donovan-self latching nothing, P2's
#   block empty pre-match; the self-diff control comes out empty against a non-empty
#   expectation and fails, the short cursor path confirms another character and fails
#   identity.
# FOLLOWS: emu/mame-patches/ tests/audit_move_parity.sh tests/expected/forced_pick_fidelity.tsv
#   tests/lua/replay.lua tests/replays/ tools/name_moves.py tools/run_mame.sh tools/setup_mame.sh
#
# MUST-FIRE: perturbed-copy: same-leg — the poked leg diffed against ITSELF yields no latched offset, and that empty set must fail the frozen non-empty expectation (in-gate: the first row's poked leg is diffed against itself and must come out empty where the frozen set is not; mode: every row is diffed leg-against-itself and the comparison FAILs)
# MUST-FIRE: known-bad: retyped-prologue — the pre-#155 hand-typed prologue (Victor's two P2 moves) over the rig's events must differ from the committed rig, and section 1b must FAIL on it: the legs are the rig's, not a replica that can drift (in-gate: the first row's rig retyped and compared; mode: every leg is built from the retyped prologue and section 1b FAILs) (GitHub #155, 14z-185)
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
#   POKED  — the #136 rig's native leg as it was before 14z-160: prologue R,R
#            (Donovan's confirm) + the id poke, + the rig's level and RNG pins.
#            Every leg is built by the rig's own functions (rpl_for, pokes_for,
#            read out of tests/audit_move_parity.sh) from the committed rig files:
#            only the P1 cursor path and the id poke are this gate's (#155).
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
# Demitri by the rig's same `R` on every leg (Victor by R,R until #155 took
# the prologue from the rig, 14z-185), so its block is the instrument's own
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
# Usage: ROMDIR=... [MAME_BIN=...] [ROWS="huitzil pyron donovan-self"] [JOBS=6] [FREEZE=1] [MEASURE=1 [WHOLE=1]] [KEEP=<dir>] tests/audit_forced_pick_fidelity.sh
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
    ""|same-leg|wrong-cursor|retyped-prologue) ;;
    *) echo "REFUSED: no control named '$CONTROL' is declared by this gate"; exit 3 ;;
esac
if [ "${FREEZE:-0}" != 1 ] && [ "${MEASURE:-0}" != 1 ]; then
    [ -f "$EXPECT" ] || { echo "FAIL: no frozen expectation at $EXPECT (FREEZE=1 to create it)"; exit 1; }
fi

if [ -n "${KEEP:-}" ]; then W="$KEEP"; mkdir -p "$W"; else W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT INT TERM; fi
fail=0
ok()  { printf '  ok    %s\n' "$1"; }
bad() { printf '  FAIL  %s\n' "$1"; fail=1; }

# Every row: tenant id, the rig part whose schedule supplies the pins, and the
# REAL cursor path from vsav2's default P1 cell (0x01: the only cell whose R,R
# is 0x13, which is what the naming rigs measure Donovan by).
row_id()   { case "$1" in huitzil) echo 10;; pyron) echo 11;; donovan-self) echo 13;; esac; }
row_rig()  { case "$1" in huitzil) echo huitzil_1;; pyron) echo pyron_1;; donovan-self) echo donovan_1;; esac; }
row_path() { case "$1" in huitzil) echo "L L L";; pyron) echo "R R R";; donovan-self) echo "R R";; esac; }
# A SECOND real route to the same cell (MEASURE only, 14z-161): REAL vs ALT is
# the route-residue control — a byte that differs between two real picks of the
# SAME cell is left by the cursor's route, not latched for the cell, and cannot
# be charged to the poke. Routes enumerated by tools/select_paths.py.
row_alt()  { case "$1" in huitzil) echo "L U L";; pyron) echo "R U R";; donovan-self) echo "D R";; esac; }

END=3400          # the rig is cut here: the first events (walk, walk back, crouch, JUMP) are enough
FIRST_EVENT=2600
# dump frames: around the confirm and the pokes, the pre-match run-up, then play
DFRAMES="1290 1310 1399 1401 1451 1501 1600 1800 2000 2200 2362 2400 2500 2599"
f=2600; while [ $f -le $END ]; do DFRAMES="$DFRAMES $f"; f=$((f + 20)); done
DSPEC="$(for f in $DFRAMES; do printf '%s:ff8000-ff8c00;' "$f"; done)"
# WHOLE=1 (MEASURE only, 14z-161): also dump the rest of work RAM at every
# frame, so the latched inventory is asked over ALL 64 KB, not the P1 block —
# a block copy (vs2 PRG:0x000D36) reads the latched bytes, so their values can
# propagate outside the block. Diagnostics only; nothing frozen from it.
[ "${WHOLE:-0}" = 1 ] && [ "${MEASURE:-0}" = 1 ] \
    && DSPEC="$DSPEC$(for f in $DFRAMES; do printf '%s:ff0000-ff7fff;%s:ff8c00-ffffff;' "$f" "$f"; done)"

# THE RIG'S OWN LEG BUILDERS (GitHub #155, 14z-185). The legs used to be a hand-typed REPLICA of the
# #136 rig's native leg — its select prologue re-typed here and its pins "per pokes_for's protocol" —
# and nothing held the replica to the rig. It drifted: the rig's P2 became Demitri at 14z-165, one
# cursor move (`1104-1106 p2=R`), while the replica kept Victor's two (`1104`, `1164`). The rig's own
# functions are now read out of the gate that runs the rig and used as they are: rpl_for (the
# committed rig replay, P1's prologue cursor moves replaced by a leg's path) and pokes_for (the rig's
# pokes plus its level and RNG pins, native leg). Section 1b asserts the REAL leg's replay IS the
# committed rig's, cut at END; the known-bad control retyped-prologue proves that assertion catches
# the old replica.
eval "$(sed -n '/^pokes_for() {/,/^}/p; /^rpl_for() {/,/^}/p' "$REPO/tests/audit_move_parity.sh")"
command -v pokes_for > /dev/null && command -v rpl_for > /dev/null \
    || { echo "FAIL: pokes_for / rpl_for not found in tests/audit_move_parity.sh"; exit 1; }
# the pre-#155 hand-typed prologue (Victor's two P2 moves) over the rig's events — the known-bad
retyped() {  # retyped <rig.rpl> <path>
    printf '300-305 sys=C1\n420-425 sys=C2\n800-803 sys=S1\n940-943 sys=S2\n'
    _t=1100; for _m in $2; do printf '%d-%d p1=%s\n' $_t $((_t + 2)) "$_m"; _t=$((_t + 60)); done
    printf '1104-1106 p2=R\n1164-1166 p2=R\n1300-1302 p1=1\n1360-1362 p2=1\n'
    awk '!/^#/ && !/^(300|420|800|940|1100|1160|1104|1164|1300|1360)-/ && $1+0 >= 2000' "$1"
}
cut_end() {  # cut_end <rpl>: the replay's lines up to END (comments dropped), then the END wait
    awk -v end=$END '!/^#/ { split($1, a, "-"); if (a[1]+0 <= end) print }' "$1"; printf '%d wait\n' $END
}

# ONE function writes a leg's replay and pokes, so what the controls perturb
# is what the gate asserts ([VSP-181]).
#   mkleg <row> <leg: poked|real|self|alt> <name> [short]
mkleg() {
    _row="$1"; _leg="$2"; _name="$3"; _short="${4:-}"
    _id="$(row_id "$_row")"; _rig="$(row_rig "$_row")"
    _j="$REPO/tests/replays/naming/$_rig.json"; _r="$REPO/tests/replays/naming/$_rig.rpl"
    mkdir -p "$W/$_name"
    _path="R R"                                   # the poked leg's prologue: Donovan's confirm
    [ "$_leg" = poked ] || _path="$(row_path "$_row")"
    [ "$_leg" = alt ] && _path="$(row_alt "$_row")"
    if [ "$_short" = short ]; then _path="$(echo $_path | awk '{$NF=""; print}')"; fi
    OURS_PATH_leg="$_path"
    if [ "$CONTROL" = retyped-prologue ]; then retyped "$_r" "$_path" > "$W/$_name/full.rpl"
    else ( rpl_for leg "$_r" ours "$W/$_name/full.rpl" ); fi   # a subshell: rpl_for sets _leg/_path/_r/_t
    cut_end "$W/$_name/full.rpl" > "$W/$_name/leg.rpl"
    # pokes: the rig's (pokes_for, native leg), cut at END, id pokes stripped and re-added below
    _base="$(pokes_for leg "$_j" native "$END" | tr ';' '\n' | awk -F: -v end=$END 'NF == 3 && $2 != "ff8782" && $1+0 <= end' | paste -sd ';' -)"
    _pick="$(python3 -c "print(';'.join(f'{f}:ff8782:$_id' for f in (1400,1450,1500)))")"
    case "$_leg" in
        real|alt) printf '%s' "$_base" ;;
        *)        printf '%s;%s' "$_pick" "$_base" ;;
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
    # WHOLE=1: the rest of work RAM, same LATCHED/TRANSIENT/PLAY classes, with the
    # frozen noise windows named rather than skipped (dead stack, QSound latch,
    # the sound-driver work area — docs/project/oracle_classes.md)
    NOISE = [(0xFF7F00, 0xFF8000, "dead-stack"), (0xFF043C, 0xFF043E, "qsound-latch"), (0xFF0500, 0xFF0600, "sound-work")]
    def dumps_at(name, tag):
        out = {}
        for fn in os.listdir(f"{W}/{name}"):
            if fn.startswith("dump_") and fn.endswith(f"_{tag}.bin"):
                out[int(fn.split("_")[1])] = open(f"{W}/{name}/{fn}", "rb").read()
        return out
    for tag, base in (("ff0000", 0xFF0000), ("ff8c00", 0xFF8C00)):
        wa, wb = dumps_at(A, tag), dumps_at(B, tag)
        if not wa or not wb: continue
        n = min(len(wa[f]) for f in wa) if wa else 0
        for off in range(n):
            fr = [f for f in frames if f in wa and f in wb and wa[f][off] != wb[f][off]]
            if not fr: continue
            prefr = [f for f in fr if f in pre]
            cls = "LATCHED" if prefr and len(prefr) == len(pre) else "TRANSIENT" if prefr else "EARLY" if all(f < 1501 for f in fr) else "PLAY"
            if cls == "PLAY": continue
            addr = base + off
            noise = next((nm for lo, hi, nm in NOISE if lo <= addr < hi), "")
            vals = " ".join(f"{f}:{wa[f][off]:02x}/{wb[f][off]:02x}" for f in fr[:5])
            print(f"    WR {addr:06x} {cls:9s} {len(fr):3d} frames  first {fr[0]}  {vals} {noise}", file=e)
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
if [ "${MEASURE:-0}" = 1 ]; then
    for row in $ROWS; do mkleg "$row" alt "${row}_alt"; runleg "${row}_alt"; n=$((n + 1)); done
fi
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

echo "== 1b. the legs ARE the rig's (#155): each REAL leg's replay equals the committed rig replay, cut at $END"
for row in $ROWS; do
    cut_end "$REPO/tests/replays/naming/$(row_rig "$row").rpl" > "$W/rig_$row.rpl"
    if cmp -s "$W/${row}_real/leg.rpl" "$W/rig_$row.rpl"; then
        ok "$row: the REAL leg's replay is tests/replays/naming/$(row_rig "$row").rpl, cut at $END"
    else
        bad "$row: the REAL leg's replay differs from the committed rig's — the legs drifted from the rig (#155):"
        diff "$W/rig_$row.rpl" "$W/${row}_real/leg.rpl" | head -6 | sed 's/^/        /'
    fi
    # the pokes: REAL carries no id poke, and POKED is exactly the three pick pokes over REAL's
    tr ';' '\n' < "$W/${row}_real/pokes" | command grep -q ':ff8782:' \
        && bad "$row: the REAL leg carries an id poke" || ok "$row: the REAL leg carries no id poke"
    _p3="$(tr ';' '\n' < "$W/${row}_poked/pokes" | command grep -c ':ff8782:' || true)"
    _rest="$(tr ';' '\n' < "$W/${row}_poked/pokes" | command grep -v ':ff8782:' | paste -sd ';' -)"
    [ "$_p3" = 3 ] && [ "$_rest" = "$(cat "$W/${row}_real/pokes")" ] \
        && ok "$row: the POKED leg is the REAL leg's pokes plus the three id pokes" \
        || bad "$row: the POKED leg's pokes are not the REAL leg's plus the id pokes ($_p3 id pokes)"
done

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
    [ "$p2pre" = "-" ] && ok "$row: P2 block (Demitri on every leg) has no pre-match difference" \
                       || bad "$row: P2 block differs pre-match at $p2pre — the instrument's negative control is not clean"
    [ "$selfl" = "-" ] && ok "$row: REAL vs SELF latches nothing (the poke mechanism itself is inert)" \
                       || bad "$row: REAL vs SELF latches $selfl — the poke mechanism perturbs state"
    echo "  $row: POKED vs REAL latched [$latched] transient $tr_ play-only $po first-play-diff $fp (early-only differences are the cell and id the poke overwrites)"
    printf '%s\t%s\t%s\n' "$row" "$latched" "$fp" >> "$W/got.tsv"
    if [ "${MEASURE:-0}" = 1 ]; then
        echo "  -- $row: REAL vs ALT (route-residue control; two real routes to the same cell) --" >&2
        altl="$(classify "${row}_real" "${row}_alt" "$id" "${row}_real")"
        echo "  $row: REAL vs ALT latched [$(printf '%s' "$altl" | cut -f1)] $(printf '%s' "$altl" | cut -f6)"
    fi
done
[ "${MEASURE:-0}" = 1 ] && { echo "MEASURE: nothing frozen, nothing compared"; exit 0; }
if [ "${FREEZE:-0}" = 1 ]; then
    # GitHub #154 (14z-183): a freeze is written only from a run whose section 2 is green —
    # the identity, P2-block and REAL-vs-SELF assertions each only set fail=1, and this
    # branch used to copy and exit before testing it. A control mode never freezes either.
    [ "$fail" = 0 ] || { echo "FAIL: section 2 is red — REFUSED to freeze $(basename "$EXPECT") (#154)"; exit 1; }
    [ -z "$CONTROL" ] || { echo "REFUSED: FREEZE=1 under CONTROL=$CONTROL — a control mode never writes the expectation (#154)"; exit 3; }
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
# retyped-prologue: the pre-#155 hand-typed prologue over the first row's rig must NOT equal the rig
# — proving section 1b sees the replica's drift (the in-gate form; the mode retypes every leg)
retyped "$REPO/tests/replays/naming/$(row_rig "$CTLROW").rpl" "$(row_path "$CTLROW")" > "$W/ctl_retyped.full"
cut_end "$W/ctl_retyped.full" > "$W/ctl_retyped.rpl"
if cmp -s "$W/ctl_retyped.rpl" "$W/rig_$CTLROW.rpl"; then
    echo "CONTROL DEAD: retyped-prologue — the hand-typed replica equals the rig, so section 1b could not see a drift"; fail=1
else
    echo "CONTROL FIRED: retyped-prologue — the hand-typed replica differs from the rig in $(diff "$W/rig_$CTLROW.rpl" "$W/ctl_retyped.rpl" | command grep -c '^[<>]') line(s): $(diff "$W/rig_$CTLROW.rpl" "$W/ctl_retyped.rpl" | command grep '^[<>]' | head -2 | tr '\n' ' ')"
fi

if [ "$fail" = 0 ]; then echo "PASS: audit_forced_pick_fidelity"; else echo "FAIL: audit_forced_pick_fidelity"; exit 1; fi
