#!/bin/sh
# audit_move_parity.sh — EVERY TENANT MOVE, OURS vs NATIVE vsav2, AT A MATCHED SPEED LEVEL AND A PINNED RNG (GitHub #136, 14z-159).
#
# MUST-FIRE: perturbed-copy: unpinned-level — the native leg left at vsav2's DEFAULT play mode (TURBO, level 8) against ours at NORMAL must fail every part, so each verdict is proven to rest on the level the gate pins (in-gate: one part is re-run with the native level pin withheld and must diverge; mode: every native leg runs unpinned and the comparisons FAIL)
# MUST-FIRE: shadow-tool: no-translation — comparing our RAW anim node pointer against native's, without translating it out of its placement, must fail, so every IDENTICAL verdict is proven to rest on the translation (in-gate: one part is compared both ways; mode: every part is compared untranslated and FAILs)
# MUST-FIRE: shadow-tool: pins-ignored — comparing with the rig's own pin frames NOT excluded must move at least one frozen row of a part whose schedule pins a compared field (pyron_4, in the default set since 14z-164: its Cosmo Disruption [KK held] row reads +167 excluded and +50, the HP-pin frame, not excluded), so the exclusion is proven live and load-bearing; a schedule without a `pokes` key is refused by the comparator (in-gate: pyron_4 compared both ways; mode: every part compared with the exclusion off and the table FAILs)
#
# WHAT IT MEASURES. tools/name_moves.py already performs every move of the
# maintainer's move lists (build/manifest/moves_<tenant>.toml, 145 moves) on the
# tenant's NATIVE game, and tests/test_move_naming.sh freezes what vs2 enters.
# Nothing ran those rigs on a PORT build. This does: the same rig, the same
# inputs, on native vsav2 and on the merged WIDE build, comparing the TENANT's
# own state every frame — node (translated out of its placement), seq, sub-state,
# node counter, x, y, stock, facing, Dark Force flag and HP — PLUS, since 14z-164,
# the METER FRACTION (RAM:$FF850A) and VICTOR's HP (RAM:$FF8850, damage dealt).
# The comparator and what it excludes are tools/move_parity.py.
#
# THE VERDICT IS PER EVENT SINCE 14z-164 (GitHub #136, maintainer-agreed
# 2026-09-17): the rig re-pins both fighters' X before every event, so each of the
# 506 events is judged IN ITS OWN WINDOW — IDENT / DIFF (+first frame, fields) /
# VOID — and frozen as one row of tests/expected/move_parity_events.tsv; an
# event labelled "in DF" must run with the DF flag up on both legs (NOT-IN-DF
# otherwise) and a DF-activating event must see the flag rise (DF-NOT-ENTERED).
# Until 14z-164 the gate froze one verdict per PART (the first divergent event;
# 27 rows), which left 103 events UNKNOWN and 21 "in DF" events of Donovan's
# part 6 unmeasured with the flag 0 on both legs (STATE 14z-164). A window IDENT
# after an earlier DIFF in its part carries `coupled=after:<k>`: bit-identical is
# evidence, a later DIFF may be downstream ([VSP-115]-shaped caveat, measured:
# a one-frame idle-phase offset persisted through donovan_2).
#
# THE PROTOCOL, AND WHY EACH PIN SITS WHERE IT DOES (all three measured 14z-159):
#   - SPEED LEVEL RAM:$FF8116 pinned to 6 on both legs from frame 2000. vsav2
#     defaults P1 to TURBO and vsavj to NORMAL (#135), so an unpinned comparison
#     measures the play mode, not the port. It is armed BEFORE the match anchor
#     (2363) because the intro runs at the level too.
#   - ENGINE RNG RAM:$FF80D4-D5 pinned from the MATCH ANCHOR, never earlier.
#     Pinning it through character load stops our build loading the match at all
#     (measured: our Donovan leg produced 377 live frames instead of 4568) — char
#     init draws from it.
#   - THE COMPARISON WINDOW STARTS AT THE RIG'S FIRST EVENT, not at the anchor.
#     The intro variant is an RNG draw at char load, so with the RNG pinned only
#     from the anchor each leg plays its own intro; measured, every one of those
#     differences lies before the first event and the legs are bit-identical from
#     it onwards.
#   - BOTH LEGS ARE REAL CURSOR PICKS (since 14z-160, GitHub #151). The rig's
#     own prologue is the native path (vsav2's default cell 0x01: Donovan R,R,
#     Phobos L,L,L, Pyron R,R,R — tools/name_moves.py `path`); our leg swaps
#     it for the merged wheel's path (D,D,D from Demitri's cell reaches Phobos
#     below Bishamon, one more D Pyron, DR from the random cell Donovan —
#     atlas/select_screen.md "the three inbound edges"). No id poke on either
#     leg: the select CONFIRM latches per-fighter state for the hovered cell
#     BEFORE the early-window poke lands (+0x3C2 the flavor, +0x3BD/+0x3E0 two
#     id copies — tests/audit_forced_pick_fidelity.sh), so a poked leg is not
#     the tenant. Identity is ASSERTED from each leg's own trace, never assumed.
#
# WHAT IT DOES NOT COVER: hitboxes and projectile parameters — separate
# instruments. P2 is Victor, a legacy character: his node is never compared
# ([VSP-168]), only his HP; and his basic hit reactions carry a retuned head
# hurtbox on vs2 (tests/test_same_data_p2.sh), so a DIFF that begins after
# contact may be his, not the tenant's — the 14z-164 census read five of the 13
# part-level first divergences as Victor-first (GitHub #136, the re-labelled table).
#
# THE FORCED-PICK HISTORY (14z-159 -> 14z-160, GitHub #147/#151). Until 14z-160
# Phobos's and Pyron's native legs were FORCED by the early-window poke, and the
# select confirm had already latched Donovan's per-fighter state — his VH2
# flavor above all — before the poke swapped the id. GitHub #147 shipped a wrong
# fix to a freeze on five readings of that rig, and the maintainer's field
# report caught it. tests/audit_forced_pick_fidelity.sh now freezes what a poked
# leg gets wrong (three bytes, none for a same-id poke), and this gate runs
# real picks on both sides; the 27 verdicts were re-frozen on them at 14z-160
# and the ten Phobos DIVERGES rows of 14z-159 were verdicts on the VH2 branch.
#
# Usage: ROMDIR=... [MAME_BIN=...] [BUILD=build/m3b_merged26] [PARTS="donovan_1 pyron_2"] [ALL=1] [JOBS=6] [FREEZE=1] tests/audit_move_parity.sh
#   emulator tier, MAME. MEASURED 14z-159 on this MacBook, solo, at the default
#   JOBS=6: the default 3-part set 25 s; ALL=1 (27 parts, 54 legs) 130 s. Both
#   figures are wall clock, not MAME's emulated-time line — that line reads ~10x
#   long and a gate runtime was once quoted from it (docs/project/gotchas.md).
set -eu

[ -n "${ROMDIR:-}" ] || { echo "FAIL: set ROMDIR"; exit 1; }
[ -d "$ROMDIR" ] && ROMDIR="$(cd "$ROMDIR" && pwd)"
REPO="$(cd "$(dirname "$0")/.." && pwd)"
BUILD="${BUILD:-build/m3b_merged26}"
case "$BUILD" in /*) ;; *) BUILD="$REPO/$BUILD" ;; esac
MAME_BIN="${MAME_BIN:-$HOME/.cache/vampire-saved/mame/cps2}"
export MAME_BIN
EXPECT="$REPO/tests/expected/move_parity_events.tsv"
JOBS="${JOBS:-6}"
CONTROL="${CONTROL:-}"

[ -x "$MAME_BIN" ] || { echo "SKIP: no MAME at $MAME_BIN"; exit 0; }
[ -f "$BUILD/rompath/vsavjw.zip" ] || { echo "SKIP: no WIDE build at $BUILD"; exit 0; }
[ -f "$BUILD/patch/placements.json" ] || { echo "SKIP: no placements.json at $BUILD"; exit 0; }
[ -f "$EXPECT" ] || { echo "FAIL: no frozen expectation at $EXPECT"; exit 1; }
case "$CONTROL" in
    ""|unpinned-level|no-translation|pins-ignored) ;;
    *) echo "REFUSED: no control named '$CONTROL' is declared by this gate"; exit 3 ;;
esac

W="$(mktemp -d)"
trap 'rm -rf "$W"' EXIT INT TERM
# the no-translation fixture is built HERE, not beside its control section: when it
# was created later, the control MODE found no file, every comparison silently
# produced nothing and the gate reported PASS on an empty result (measured 14z-159).
printf '{"regions":{"anim":{"dst":0,"src":0,"len":0},"anim@huitzil":{"dst":0,"src":0,"len":0},"anim@pyron":{"dst":0,"src":0,"len":0}}}' > "$W/nullplacements.json"
fail=0
ok()  { printf '  ok    %s\n' "$1"; }
bad() { printf '  FAIL  %s\n' "$1"; fail=1; }

if [ -n "${PARTS:-}" ]; then SET="$PARTS"
elif [ "${ALL:-0}" = 1 ]; then
  # every committed naming part of the three tenants (never the victim rigs, whose
  # subject is P2): since 14z-164 that includes Donovan's hit/block parts 9-11,
  # which the per-part gate never ran
  SET="$(ls "$REPO"/tests/replays/naming/donovan_[0-9]*.json "$REPO"/tests/replays/naming/huitzil_[0-9]*.json "$REPO"/tests/replays/naming/pyron_[0-9]*.json | sed 's|.*/||; s|\.json$||' | sort -t_ -k1,1 -k2,2n | tr '\n' ' ')"
else
  SET="donovan_1 pyron_4 huitzil_1"   # pyron_4 since 14z-164: the part the pins-ignored control needs
fi

ID_donovan=13; ID_huitzil=10; ID_pyron=11
# our leg's cursor path on the merged wheel, from Demitri's cell (the P1 default)
OURS_PATH_donovan="D D DR DR"; OURS_PATH_huitzil="D D D"; OURS_PATH_pyron="D D D D"

# ONE function builds a leg's pokes, so what the control perturbs is what the
# gate asserts ([VSP-181]).
pokes_for() {  # pokes_for <tenant> <json> <leg> <frames>
    _t="$1"; _j="$2"; _leg="$3"; _fr="$4"
    _base="$(python3 -c "import json;print(';'.join(json.load(open('$_j'))['pokes']))")"
    _lvl="$(python3 -c "print(';'.join(f'{f}:ff8116:06' for f in range(2000,$_fr)))")"
    _rng="$(python3 -c "print(';'.join(f'{f}:ff80d4:0000' for f in range(2363,$_fr)))")"
    if [ "$_leg" = native ]; then
        # the unpinned-level control withholds the level from the NATIVE leg only
        if [ "$CONTROL" = unpinned-level ] || [ "${CTL_ONE:-}" = unpinned-level ]; then
            printf '%s;%s' "$_base" "$_rng"
        else
            printf '%s;%s;%s' "$_base" "$_lvl" "$_rng"
        fi
    else
        printf '%s;%s;%s' "$_base" "$_lvl" "$_rng"
    fi
}

# rpl_for <tenant> <rig.rpl> <leg> <out.rpl> — the rig as committed for native;
# for ours, P1's prologue cursor moves replaced by the merged wheel's path
# (1100, then every 60 frames; the confirm at 1300 is untouched).
rpl_for() {
    _t="$1"; _r="$2"; _leg="$3"; _o="$4"
    if [ "$_leg" = native ]; then cp "$_r" "$_o"; return; fi
    eval "_path=\$OURS_PATH_$_t"
    awk -v path="$_path" '
        /^1104-1106 p2=R$/ && !done { n = split(path, m, " "); t = 1100
            for (i = 1; i <= n; i++) { printf "%d-%d p1=%s\n", t, t + 2, m[i]; t += 60 }; done = 1 }
        /^(1100|1160|1220|1280)-[0-9]+ p1=/ { next }
        { print }' "$_r" > "$_o"
}

FIELDS="ff841c:l:node,ff8420:b:cnt,ff8406:b:seq,ff8407:b:sub,ff8509:b:stock,ff8410:w:x,ff8414:w:y,ff8450:w:p1hp,ff8782:b:id,ff802e:b:df,ff840b:b:face,ff8116:b:lvl,ff850a:w:meter,ff8850:w:p2hp"

run_leg() {  # run_leg <tenant> <part> <leg>
    _t="$1"; _p="$2"; _leg="$3"
    _j="$REPO/tests/replays/naming/${_t}_${_p}.json"
    _r="$REPO/tests/replays/naming/${_t}_${_p}.rpl"
    _fr="$(python3 -c "import json;print(json.load(open('$_j'))['frames'])")"
    _pk="$(pokes_for "$_t" "$_j" "$_leg" "$_fr")"
    rpl_for "$_t" "$_r" "$_leg" "$W/${_t}_${_p}_$_leg.rpl"; _r="$W/${_t}_${_p}_$_leg.rpl"
    if [ "$_leg" = native ]; then _set=vsav2; _rp="$ROMDIR"
    else _set=vsavjw; _rp="$BUILD/rompath;$ROMDIR"; fi
    mkdir -p "$W/${_t}_${_p}_$_leg"
    ( cd "$W/${_t}_${_p}_$_leg" \
      && MAME_SANDBOX="$W/${_t}_${_p}_$_leg/sb" MAME_ROMPATH="$_rp" REPLAY="$_r" POKES="$_pk" \
         FIELDS="$FIELDS" FIELD_OUT="$W/tr_${_t}_${_p}_$_leg.txt" \
         FIELD_FROM=2300 FIELD_TO="$_fr" FRAMES="$_fr" \
         "$REPO/tools/run_mame.sh" "$_set" \
            -autoboot_script "$REPO/tests/lua/field_trace.lua" > "$W/${_t}_${_p}_$_leg/mame.log" 2>&1
      rm -rf "$W/${_t}_${_p}_$_leg/sb" ) </dev/null &
}

verdict_for() {  # verdict_for <tenant> <part> [--raw]
    _t="$1"; _p="$2"; _raw="${3:-}"
    # the no-translation MODE applies the same perturbation to every part
    [ "$CONTROL" = no-translation ] && _raw=--raw
    _j="$REPO/tests/replays/naming/${_t}_${_p}.json"
    _fe="$(python3 -c "import json;print(json.load(open('$_j'))['events'][0]['frame'])")"
    _pl="$BUILD/patch/placements.json"
    [ "$_raw" = --raw ] && _pl="$W/nullplacements.json"
    _np=""; { [ "$_raw" = --no-pins ] || [ "$CONTROL" = pins-ignored ]; } && _np="--no-pin-exclusion"
    python3 "$REPO/tools/move_parity.py" events "$_t" "$_p" \
        "$W/tr_${_t}_${_p}_native.txt" "$W/tr_${_t}_${_p}_ours.txt" "$_pl" \
        --first-event "$_fe" --events "$_j" $_np 2>/dev/null || true
}

echo "== 1. the legs ($(echo $SET | wc -w | tr -d ' ') parts x 2, build $(basename "$BUILD"))"
n=0
for part in $SET; do
    t="${part%_*}"; p="${part##*_}"
    [ -f "$REPO/tests/replays/naming/${t}_${p}.rpl" ] || { bad "$part: no committed rig"; continue; }
    for leg in native ours; do
        run_leg "$t" "$p" "$leg"
        n=$((n + 1))
        [ $((n % JOBS)) -eq 0 ] && wait
    done
done
wait
for part in $SET; do
    t="${part%_*}"; p="${part##*_}"
    [ -s "$W/tr_${t}_${p}_native.txt" ] || bad "$part: native leg produced no samples"
    [ -s "$W/tr_${t}_${p}_ours.txt" ]   || bad "$part: ours leg produced no samples"
done
[ "$fail" = 0 ] || { echo "FAIL: a leg did not run"; exit 1; }
ok "$n legs ran"
# IDENTITY: the id field at the first sampled frame (2300, before the match, when
# +0x382 is still the pick — in match the engine reassigns it, ram.md) must be
# the tenant on BOTH legs: a real cursor pick that landed elsewhere is not a leg.
for part in $SET; do
    t="${part%_*}"; p="${part##*_}"; eval "_want=\$ID_$t"
    for leg in native ours; do
        got="$(awk '$1=="F" && $2==2300 {for(i=3;i<=NF;i++) if ($i ~ /^id=/) {sub("id=","",$i); printf "%02x", $i}}' "$W/tr_${t}_${p}_$leg.txt")"
        [ "$got" = "$_want" ] || bad "$part: $leg leg picked id $got, not the tenant ($_want) — the cursor path did not land"
    done
done
[ "$fail" = 0 ] || { echo "FAIL: a leg is not the tenant"; exit 1; }
ok "every leg is the tenant by its own trace (id at 2300)"

echo "== 2. every EVENT's verdict equals the frozen expectation"
: > "$W/got.tsv"
for part in $SET; do
    t="${part%_*}"; p="${part##*_}"
    verdict_for "$t" "$p" >> "$W/got.tsv"
done
if [ "${FREEZE:-0}" = 1 ]; then
    { sed -n '1,/^#--$/p' "$EXPECT" 2>/dev/null || true; cat "$W/got.tsv"; } > "$W/new.tsv"
    cp "$W/new.tsv" "$EXPECT"
    echo "  FROZE  $(basename "$EXPECT") from this run ($(command grep -c . "$W/got.tsv") events of $(echo $SET | wc -w | tr -d ' ') parts)"
    echo "  (freeze, then VERIFY: re-run without FREEZE — the second run is what makes it evidence)"
    exit 0
fi
[ -s "$W/got.tsv" ] || bad "the comparator produced no verdict at all — an empty result is not a pass"
for part in $SET; do
    awk -F'\t' -v n="$part" '!/^#/ && $1==n' "$EXPECT" > "$W/exp_$part.tsv"
    awk -F'\t' -v n="$part" '$1==n' "$W/got.tsv" > "$W/got_$part.tsv"
    [ -s "$W/exp_$part.tsv" ] || { bad "$part: no rows in $(basename "$EXPECT")"; continue; }
    if command diff -u "$W/exp_$part.tsv" "$W/got_$part.tsv" > "$W/diff_$part.txt"; then
        ok "$part: $(command grep -c . "$W/got_$part.tsv") events as frozen ($(awk -F'\t' '$4=="IDENT"' "$W/got_$part.tsv" | command grep -c . || true) IDENT, $(awk -F'\t' '$4=="DIFF"' "$W/got_$part.tsv" | command grep -c . || true) DIFF, $(awk -F'\t' '$4!="IDENT" && $4!="DIFF"' "$W/got_$part.tsv" | command grep -c . || true) other)"
    else bad "$part: events moved:"; command grep '^[-+][^-+]' "$W/diff_$part.txt" | head -12; fi
done

echo "== 3. must-fire controls"
CTL="$(echo $SET | awk '{print $1}')"
ct="${CTL%_*}"; cp="${CTL##*_}"

# pins-ignored: the first part of the set whose VERDICT columns (part, event, name,
# verdict, first, fields — never the `excluded` count, which changes trivially)
# move when the rig's pin frames are compared too; pyron_4 in the default set.
# The exclusion is load-bearing, not decoration, or this reads DEAD.
PP=""
for part in $SET; do
    t="${part%_*}"; p="${part##*_}"
    verdict_for "$t" "$p" --no-pins | cut -f1-6 > "$W/ctl_nopins_$part.tsv"
    awk -F'\t' -v n="$part" '!/^#/ && $1==n' "$EXPECT" | cut -f1-6 > "$W/exp_ctl_$part.tsv"
    if ! command diff -q "$W/exp_ctl_$part.tsv" "$W/ctl_nopins_$part.tsv" > /dev/null; then PP="$part"; break; fi
done
if [ -z "$PP" ]; then echo "CONTROL DEAD: pins-ignored — no part in the set moves a verdict with the pin exclusion off"; fail=1
else echo "CONTROL FIRED: pins-ignored — $PP moves $(command diff "$W/exp_ctl_$PP.tsv" "$W/ctl_nopins_$PP.tsv" | command grep -c '^>' || true) verdict row(s) with the pin exclusion off"; fi

# no-translation: compare the raw pointer. The control part's IDENT events must
# stop being identical without the placement translation.
n_ident() { awk -F'\t' '$4=="IDENT"' "$1" | command grep -c . || true; }
verdict_for "$ct" "$cp" > "$W/ctl_base.tsv"; base="$(n_ident "$W/ctl_base.tsv")"
verdict_for "$ct" "$cp" --raw > "$W/ctl_raw.tsv"; raw="$(n_ident "$W/ctl_raw.tsv")"
if [ "$base" -gt 0 ] && [ "$raw" -lt "$base" ]; then
    echo "CONTROL FIRED: no-translation — $CTL reads $base IDENT events translated and $raw untranslated"
elif [ "$base" -gt 0 ]; then
    echo "CONTROL DEAD: no-translation — $CTL still reads $base IDENT events with the placement translation removed"; fail=1
else
    echo "CONTROL DEAD: no-translation — the control part $CTL has no IDENT event, so the control cannot discriminate"; fail=1
fi

# unpinned-level: re-run the control part's NATIVE leg at vsav2's own default.
CTL_ONE=unpinned-level run_leg "$ct" "$cp" native
wait
verdict_for "$ct" "$cp" > "$W/ctl_up.tsv"; up="$(n_ident "$W/ctl_up.tsv")"
if [ "$base" -gt 0 ] && [ "$up" -lt "$base" ]; then
    echo "CONTROL FIRED: unpinned-level — $CTL reads $up IDENT events with the native level pin withheld ($base pinned)"
else
    echo "CONTROL DEAD: unpinned-level — $CTL still reads $up IDENT events with the native leg at its default play mode ($base pinned)"; fail=1
fi

if [ "$fail" = 0 ]; then echo "PASS: audit_move_parity"; else echo "FAIL: audit_move_parity"; exit 1; fi
