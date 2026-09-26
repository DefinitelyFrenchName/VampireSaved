#!/bin/sh
# audit_move_parity.sh — EVERY TENANT MOVE, OURS vs NATIVE vsav2, AT A MATCHED SPEED LEVEL AND A PINNED RNG (GitHub #136, 14z-159).
#
# WHAT: every tenant move, ours vs native vsav2, at a matched speed level and a pinned RNG
#   (#136): the same naming rigs on both games, the tenant's own state compared every frame
#   (node translated out of its placement, seq, sub-state, counter, x, y, stock, facing, DF
#   flag, HP, meter fraction, P2's HP), one verdict per EVENT — IDENT / DIFF / VOID — frozen
#   for all 506 events.
# HOW: the 30 naming parts on MAME on both legs as REAL cursor picks (the merged wheel's
#   path on ours), the level pinned to 6 from 2000 and the RNG from the match anchor, the
#   comparison window starting at each rig's first event and each event judged in its own
#   X-pinned window (tools/move_parity.py); four controls (the native level unpinned, the
#   node untranslated, a stock starved, the X pins ignored).
# EXPECTS: the 506 rows equal to tests/expected/move_parity_events.tsv, every in-DF event
#   with the flag up on both legs, every DF activation seen; each control turns verdicts. A
#   DIFF's cause is audit_move_parity_attribution's question.
# FOLLOWS: build/manifest/ emu/mame-patches/ tests/expected/move_parity_events.tsv
#   tests/lib/decrypt_cache.sh tests/lua/field_trace.lua tests/replays/ tools/move_parity.py
#   tools/name_moves.py tools/run_mame.sh tools/setup_mame.sh
#
# MUST-FIRE: perturbed-copy: unpinned-level — the native leg left at vsav2's DEFAULT play mode (TURBO, level 8) against ours at NORMAL must fail every part, so each verdict is proven to rest on the level the gate pins (in-gate: one part is re-run with the native level pin withheld and must diverge; mode: every native leg runs unpinned and the comparisons FAIL)
# MUST-FIRE: shadow-tool: no-translation — comparing our RAW anim node pointer against native's, without translating it out of its placement, must fail, so every IDENTICAL verdict is proven to rest on the translation (in-gate: one part is compared both ways; mode: every part is compared untranslated and FAILs)
# MUST-FIRE: perturbed-copy: stock-starved — a copy of a meter part's OWN trace with the stock zeroed at one event frame must make section 2b report that event as starved, so the headroom check is live on the real traces (in-gate: the first meter part's ours leg, perturbed; mode: every meter part's ours leg is perturbed before 2b and the section FAILs)
# MUST-FIRE: perturbed-copy: pins-ignored — a copy of OUR trace with the compared X altered on exactly the rig's own X-pin frames (RAM:$FF8410, 40 f before each pinned event) must leave every verdict of the part as frozen under the pin exclusion and move at least one verdict with the exclusion off, so the exclusion is proven live in the comparator and load-bearing on the rig's own writes; a schedule without a `pokes` key is refused by the comparator (in-gate: the first part of the set whose schedule pins X — pyron_4 in the default set — compared both ways on its perturbed copy; mode: every part compared on its perturbed copy with the exclusion off, verdict columns only, and the table FAILs). Until 14z-165 this control hunted for a part whose REAL rows moved with the exclusion off; with Demitri on P2 no part of the 30 does (both legs agree on every pin frame), so a data-dependent control read DEAD
#
# WHAT IT MEASURES. tools/name_moves.py already performs every move of the
# maintainer's move lists (build/manifest/moves_<tenant>.toml, 145 moves) on the
# tenant's NATIVE game, and tests/test_move_naming.sh freezes what vs2 enters.
# Nothing ran those rigs on a PORT build. This does: the same rig, the same
# inputs, on native vsav2 and on the merged WIDE build, comparing the TENANT's
# own state every frame — node (translated out of its placement), seq, sub-state,
# node counter, x, y, stock, facing, Dark Force flag and HP — PLUS, since 14z-164,
# the METER FRACTION (RAM:$FF850A) and P2's HP (RAM:$FF8850, damage dealt).
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
#     it onwards. CORRECTED 14z-167 (measured, build/x_family_14z167/): NOT on the
#     guard-cancel parts huitzil_5/6/7, whose first X pin lands at 2370, inside
#     Phobos's round-start ENTRANCE (the round starts at 2544, atlas $FF812D): the
#     legs drew different entrances (native the car arrival, carried through the
#     pin to x=702; ours with Cecil in hand, left at the pinned 552) and reach the
#     first event apart, so those three first-event DIFF rows are the entrance,
#     not the move (docs/project/gotchas.md, the 14z-167 entrance entry).
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
# P2 IS DEMITRI SINCE 14z-165 (maintainer-ruled 2026-09-17, DECISIONS_HISTORY.md
# "the parity rigs' P2 is DEMITRI, Bishamon the fallback"; Victor until then).
# P2 is a legacy character, VS's copy on our leg and VS2's on the native one, so
# his node is never compared ([VSP-168]), only his HP — and Victor's basic hit
# reactions carry a retuned head hurtbox on vs2 (tests/test_same_data_p2.sh),
# which is where the 14z-164 census read five of the 13 part-level first
# divergences beginning (GitHub #136). Demitri's data differs between the games
# on three chains only — b:0x10 (the held-pose push box every legacy character
# gained on vs2), b:0x71 and b:0x74 (one attack record each) — so each leg's
# trace is checked with tools/move_parity.py p2check: P2's id is 0x01 at the
# first sampled frame and P2's node NEVER lies in b:0x71 / b:0x74 over the
# compared frames, on the native leg against the vs2 data view and on ours
# against the build's own data view. His route is `R` from P2's default cell
# 0x05 on BOTH wheels (tools/select_paths.py), so the two legs share the P2
# prologue lines verbatim. The 506 events were re-frozen on him at 14z-165.
#
# WHAT IT DOES NOT COVER: hitboxes and projectile parameters — separate
# instruments; P2's POSITION — P2's x is not a compared field, so a move that
# displaces P2 differently reads IDENT until P1's own fields feel it downstream
# (14z-167: Killshread Summon (ES) moved Demitri on native only, event 5 read IDENT
# and Press of Death read DIFF — GitHub #159); and WHICH ROOT a DIFF row belongs to —
# ATTRIBUTED since 14z-168 by tests/audit_move_parity_attribution.sh (ablation + a
# measured signature per root; every one of the 108 rows has a cause). The cnt rows
# the 14z-167 first look called "an engine tick lost on ours" are CPU OVERRUNS on
# Blizzard Sword frames — two of the three on NATIVE (tests/audit_pass_overrun.sh);
# and a DIFF that begins after contact is still not attributed to
# a side by this gate (P2's hurtboxes are the same data on both legs now, but
# the engine that reads them is each game's own).
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
# Usage: ROMDIR=... [MAME_BIN=...] [BUILD=build/m3b_merged28] [PARTS="donovan_1 pyron_2"] [ALL=1] [JOBS=6] [FREEZE=1] [GOT_OUT=<path>] tests/audit_move_parity.sh
#   GOT_OUT (14z-183): also copy this run's computed per-event table to <path> (verdicts unaffected) — how a probe build's
#   whole table is read when it moves rows (the failure diff shows only each part's first changed rows).
#   emulator tier, MAME. MEASURED 14z-159 on this MacBook, solo, at the default
#   JOBS=6: the default 3-part set 25 s; ALL=1 (27 parts, 54 legs) 130 s. Both
#   figures are wall clock, not MAME's emulated-time line — that line reads ~10x
#   long and a gate runtime was once quoted from it (docs/project/gotchas.md).
set -eu

[ -n "${ROMDIR:-}" ] || { echo "FAIL: set ROMDIR"; exit 1; }
[ -d "$ROMDIR" ] && ROMDIR="$(cd "$ROMDIR" && pwd)"
REPO="$(cd "$(dirname "$0")/.." && pwd)"
BUILD="${BUILD:-build/m3b_merged28}"
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
    ""|unpinned-level|no-translation|pins-ignored|stock-starved) ;;
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
  SET="donovan_1 pyron_4 huitzil_1"   # pyron_4 since 14z-164: a part whose schedule pins X, which the pins-ignored control needs
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

FIELDS="ff841c:l:node,ff8420:b:cnt,ff8406:b:seq,ff8407:b:sub,ff8509:b:stock,ff8410:w:x,ff8414:w:y,ff8450:w:p1hp,ff8782:b:id,ff802e:b:df,ff840b:b:face,ff8116:b:lvl,ff850a:w:meter,ff8850:w:p2hp,ff881c:l:p2node,ff8b82:b:p2id"

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

# perturb_x_pins <schedule.json> <trace in> <trace out>: OUR trace with x altered
# by +7 on exactly the frames the rig pins RAM:$FF8410 — the pins-ignored
# control's perturbed copy ([VSP-181]: one function, the control and the mode).
# Prints how many frames were altered (0 = the part pins no X; not a control part).
perturb_x_pins() {
    python3 - "$1" "$2" "$3" <<'PYX'
import json, sys
pins = {int(p.split(":")[0]) for p in json.load(open(sys.argv[1]))["pokes"] if p.split(":")[1].lower() == "ff8410"}
n = 0
with open(sys.argv[2]) as fi, open(sys.argv[3], "w") as fo:
    for line in fi:
        f = line.split()
        if len(f) >= 3 and f[0] == "F" and int(f[1]) in pins:
            f = [("x=%d" % (int(t[2:]) + 7)) if t.startswith("x=") else t for t in f]; n += 1
            line = " ".join(f) + "\n"
        fo.write(line)
print(n)
PYX
}

verdict_for() {  # verdict_for <tenant> <part> [--raw | --pert | --pert-no-pins]
    _t="$1"; _p="$2"; _raw="${3:-}"
    # the no-translation MODE applies the same perturbation to every part
    [ "$CONTROL" = no-translation ] && _raw=--raw
    _j="$REPO/tests/replays/naming/${_t}_${_p}.json"
    _fe="$(python3 -c "import json;print(json.load(open('$_j'))['events'][0]['frame'])")"
    _pl="$BUILD/patch/placements.json"
    [ "$_raw" = --raw ] && _pl="$W/nullplacements.json"
    _ours="$W/tr_${_t}_${_p}_ours.txt"
    # the pins-ignored MODE compares every part on its perturbed copy with the exclusion off
    [ "$CONTROL" = pins-ignored ] && _raw=--pert-no-pins
    case "$_raw" in --pert|--pert-no-pins)
        _ours="$W/tr_${_t}_${_p}_ours.pert.txt"
        [ -f "$_ours" ] || perturb_x_pins "$_j" "$W/tr_${_t}_${_p}_ours.txt" "$_ours" > /dev/null ;;
    esac
    _np=""; [ "$_raw" = --pert-no-pins ] && _np="--no-pin-exclusion"
    python3 "$REPO/tools/move_parity.py" events "$_t" "$_p" \
        "$W/tr_${_t}_${_p}_native.txt" "$_ours" "$_pl" \
        --first-event "$_fe" --events "$_j" $_np 2>/dev/null || true
}

# THE PERTURBATION for stock-starved, one function the control and the mode both
# call ([VSP-181]): a copy of a REAL trace with stock=0 written at a real EVENT
# frame — the frame the check reads, or the control proves nothing.
starve_trace() {  # starve_trace <src trace> <dst> <schedule json>
    python3 - "$1" "$2" "$3" <<'PY'
import json, re, sys
src, dst, js = sys.argv[1], sys.argv[2], sys.argv[3]
have = {int(l.split()[1]) for l in open(src) if l.startswith("F ")}
ev = [e["frame"] for e in json.load(open(js))["events"] if e["frame"] in have]
if not ev:
    sys.exit("REFUSED: no event frame of %s appears in %s" % (js, src))
target = ev[len(ev) // 2]
out = []
for l in open(src):
    f = l.split()
    if f and f[0] == "F" and int(f[1]) == target:
        l = re.sub(r"stock=\d+", "stock=0", l)
    out.append(l)
if not any("stock=0" in l for l in out):
    sys.exit("REFUSED: no stock= field at event frame %d to zero" % target)
open(dst, "w").writelines(out)
PY
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
# P2 (14z-165): Demitri by his real route on both legs, and never in a chain whose
# data differs between the games — from each leg's own trace against that leg's
# game image (native: the vs2 data view; ours: the build's data view).
. "$REPO/tests/lib/decrypt_cache.sh"
decrypt_view vsav2 "$W/v2_op.bin" "$W/v2.bin" || { echo "FAIL: no vsav2 decrypt view for the P2 check"; exit 1; }
[ -f "$BUILD/verify_data.bin" ] || { echo "FAIL: no $BUILD/verify_data.bin for the P2 check on our leg"; exit 1; }
P2ID="$(python3 -c "import sys; sys.path.insert(0,'$REPO/tools'); import name_moves; print(name_moves.TENANTS['donovan']['p2_id'])")"
P2NEVER="$(python3 -c "import sys; sys.path.insert(0,'$REPO/tools'); import name_moves; print(','.join(name_moves.P2_NEVER))")"
P2REPORT="$(python3 -c "import sys; sys.path.insert(0,'$REPO/tools'); import name_moves; print(','.join(name_moves.P2_REPORT))")"
for part in $SET; do
    t="${part%_*}"; p="${part##*_}"
    _fe="$(python3 -c "import json;print(json.load(open('$REPO/tests/replays/naming/${t}_${p}.json'))['events'][0]['frame'])")"
    for leg in native ours; do
        if [ "$leg" = native ]; then _img="$W/v2.bin"; _lay=vsav2; else _img="$BUILD/verify_data.bin"; _lay=vsavj; fi
        if python3 "$REPO/tools/move_parity.py" p2check "$W/tr_${t}_${p}_$leg.txt" "$_img" --layout "$_lay" --id "$P2ID" --never "$P2NEVER" --report "$P2REPORT" --from "$_fe" > "$W/p2_${part}_$leg.txt" 2>&1; then :
        else bad "$part: $leg leg P2 check — $(command grep -m1 FAIL "$W/p2_${part}_$leg.txt")"; fi
    done
    # the reported pose (b:0x10) is entered legitimately but its datum differs between
    # the games; assert P2 enters it the SAME number of frames on both legs, so the
    # difference is the datum, not a behavioural cascade (rule-checker run 2026-09-17-29 Q4)
    rn="$(command grep -m1 'P2REPORT:' "$W/p2_${part}_native.txt" | sed 's/.*P2REPORT: //')"
    ro="$(command grep -m1 'P2REPORT:' "$W/p2_${part}_ours.txt"   | sed 's/.*P2REPORT: //')"
    [ "$rn" = "$ro" ] || bad "$part: P2's reported-pose frame counts differ between legs (native [$rn] ours [$ro]) — b:0x10 is a behavioural divergence here, not just a datum difference"
done
[ "$fail" = 0 ] || { echo "FAIL: P2 is not Demitri on the same data on every leg"; exit 1; }
ok "P2 is Demitri (0x$P2ID) on every leg, never enters $P2NEVER, and holds the reported pose(s) the same on both legs (e.g. $(command grep -m1 'P2REPORT:' "$W/p2_$(echo $SET | awk '{print $1}')_native.txt"))"

echo "== 2. every EVENT's verdict equals the frozen expectation"
: > "$W/got.tsv"
for part in $SET; do
    t="${part%_*}"; p="${part##*_}"
    verdict_for "$t" "$p" >> "$W/got.tsv"
done
[ -n "${GOT_OUT:-}" ] && cp "$W/got.tsv" "$GOT_OUT"
if [ "${FREEZE:-0}" = 1 ]; then
    { sed -n '1,/^#--$/p' "$EXPECT" 2>/dev/null || true; cat "$W/got.tsv"; } > "$W/new.tsv"
    cp "$W/new.tsv" "$EXPECT"
    echo "  FROZE  $(basename "$EXPECT") from this run ($(command grep -c . "$W/got.tsv") events of $(echo $SET | wc -w | tr -d ' ') parts)"
    echo "  (freeze, then VERIFY: re-run without FREEZE — the second run is what makes it evidence)"
    exit 0
fi
[ -s "$W/got.tsv" ] || bad "the comparator produced no verdict at all — an empty result is not a pass"
# the pins-ignored MODE judges the VERDICT columns only (part, event, name, verdict,
# first, fields): the `excluded` count changes trivially with the exclusion off and
# would make the mode fire on its own bookkeeping (14z-164, 14z-165)
CUT=cat; [ "$CONTROL" = pins-ignored ] && CUT="cut -f1-6"
for part in $SET; do
    awk -F'\t' -v n="$part" '!/^#/ && $1==n' "$EXPECT" | $CUT > "$W/exp_$part.tsv"
    awk -F'\t' -v n="$part" '$1==n' "$W/got.tsv" | $CUT > "$W/got_$part.tsv"
    [ -s "$W/exp_$part.tsv" ] || { bad "$part: no rows in $(basename "$EXPECT")"; continue; }
    if command diff -u "$W/exp_$part.tsv" "$W/got_$part.tsv" > "$W/diff_$part.txt"; then
        ok "$part: $(command grep -c . "$W/got_$part.tsv") events as frozen ($(awk -F'\t' '$4=="IDENT"' "$W/got_$part.tsv" | command grep -c . || true) IDENT, $(awk -F'\t' '$4=="DIFF"' "$W/got_$part.tsv" | command grep -c . || true) DIFF, $(awk -F'\t' '$4!="IDENT" && $4!="DIFF"' "$W/got_$part.tsv" | command grep -c . || true) other)"
    else bad "$part: events moved:"; command grep '^[-+][^-+]' "$W/diff_$part.txt" | head -12; fi
done

echo "== 2b. STOCK HEADROOM at every event of a meter part, both legs"
# WHY THIS EXISTS (14z-171, rule-checker 2026-09-20-84 Q4). The rigs poke the
# stock to 9 sixty frames before every event of a meter part, so an ES move can
# never fire on an empty meter and degrade SILENTLY to its normal version
# ([VSP-170]) — which the naming table would then record as the ES move's own
# chain. That poke is PREVENTION; on its own nothing would notice if it stopped
# working, because the naming table freezes chain ids and this gate EXCLUDES the
# poke's own frames from the comparison. This section is the DETECTION half: it
# reads the stock the legs actually had AT each event and fails if any reached
# zero, and it prints the MINIMUM so a decline is visible long before it is a
# defect. MEASURED AT BIRTH, full corpus: 28 meter-part legs, no event on an
# empty meter, LOWEST STOCK AT ANY EVENT = 7 — not 9. The poke restores 9 sixty
# frames before an event, and where events sit close one can still spend before
# the next poke (donovan_7's tail reads 8). That is the honest figure and this
# section is what tracks it: a fall toward 0 is the signal, 0 is the failure.
# Under the two-poke scheme it replaces the same parts declined further
# (pyron_5 to 5, donovan_7's tail to 6, donovan_12 to 8) without reaching 0.
_sb_min=99; _sb_n=0; _sb_bad=0
for part in $SET; do
    t="${part%_*}"; p="${part##*_}"
    python3 -c "
import sys; sys.path.insert(0,'tools'); import name_moves
print('yes' if '$p' in name_moves.METER_PARTS.get('$t',[]) else 'no')" 2>/dev/null | grep -q yes || continue
    for leg in native ours; do
        _tr="$W/tr_${t}_${p}_$leg.txt"
        [ "$CONTROL" = stock-starved ] && [ "$leg" = ours ] && { starve_trace "$_tr" "$W/sb_$part.$leg" "$REPO/tests/replays/naming/${t}_${p}.json"; _tr="$W/sb_$part.$leg"; }
        _r="$(python3 - "$_tr" "$REPO/tests/replays/naming/${t}_${p}.json" <<'PY'
import json, sys
tr, js = sys.argv[1], sys.argv[2]
d = {}
for l in open(tr):
    f = l.split()
    if f and f[0] == "F": d[int(f[1])] = dict(kv.split("=", 1) for kv in f[2:])
lo, starved = 99, []
for e in json.load(open(js))["events"]:
    v = d.get(e["frame"], {}).get("stock")
    if v is None: continue
    v = int(v); lo = min(lo, v)
    if v == 0: starved.append(e["name"][:34])
print("%d\t%d\t%s" % (lo, len(starved), ";".join(starved[:3])))
PY
)"
        _lo="$(printf '%s' "$_r" | cut -f1)"; _ns="$(printf '%s' "$_r" | cut -f2)"; _nm="$(printf '%s' "$_r" | cut -f3)"
        _sb_n=$((_sb_n + 1))
        [ "$_lo" -lt "$_sb_min" ] 2>/dev/null && _sb_min="$_lo"
        if [ "${_ns:-0}" != 0 ]; then bad "2b: $part $leg — $_ns event(s) fired on an EMPTY meter ($_nm)"; _sb_bad=$((_sb_bad + 1)); fi
    done
done
[ "$_sb_bad" = 0 ] && ok "2b: $_sb_n meter-part legs, no event on an empty meter; lowest stock at any event = $_sb_min"
# MUST-FIRE: the same perturbation on a real trace must be SEEN by the same reader.
_sb_p=""; for part in $SET; do
    t="${part%_*}"; p="${part##*_}"
    python3 -c "
import sys; sys.path.insert(0,'tools'); import name_moves
print('yes' if '$p' in name_moves.METER_PARTS.get('$t',[]) else 'no')" 2>/dev/null | grep -q yes || continue
    [ -s "$W/tr_${t}_${p}_ours.txt" ] && { _sb_p="$part"; _sb_t="$t"; _sb_pp="$p"; break; }
done
if [ -n "$_sb_p" ] && starve_trace "$W/tr_${_sb_t}_${_sb_pp}_ours.txt" "$W/sb_ctl.txt" "$REPO/tests/replays/naming/${_sb_t}_${_sb_pp}.json" 2>/dev/null; then
    _c="$(python3 - "$W/sb_ctl.txt" "$REPO/tests/replays/naming/${_sb_t}_${_sb_pp}.json" <<'PY'
import json, sys
d = {}
for l in open(sys.argv[1]):
    f = l.split()
    if f and f[0] == "F": d[int(f[1])] = dict(kv.split("=", 1) for kv in f[2:])
print(sum(1 for e in json.load(open(sys.argv[2]))["events"]
          if d.get(e["frame"], {}).get("stock") == "0"))
PY
)"
    if [ "${_c:-0}" -ge 1 ]; then
        echo "CONTROL FIRED: stock-starved — $_sb_p's own ours trace with the stock zeroed at one event frame reads $_c starved event(s), where the real trace reads 0"
    else
        echo "CONTROL DEAD: stock-starved — the perturbed trace still read no starved event"; fail=1
    fi
else
    echo "CONTROL DEAD: stock-starved — no meter-part trace could be perturbed"; fail=1
fi


echo "== 3. must-fire controls"
CTL="$(echo $SET | awk '{print $1}')"
ct="${CTL%_*}"; cp="${CTL##*_}"

# pins-ignored (perturbed-copy, 14z-165): the first part of the set whose schedule
# pins X gets a copy of OUR trace with x altered on exactly those pin frames; its
# VERDICT columns (part, event, name, verdict, first, fields — never the `excluded`
# count) must equal the frozen rows under the exclusion AND differ with it off.
PP=""; PN=0
for part in $SET; do
    t="${part%_*}"; p="${part##*_}"
    rm -f "$W/tr_${t}_${p}_ours.pert.txt"
    PN="$(perturb_x_pins "$REPO/tests/replays/naming/${t}_${p}.json" "$W/tr_${t}_${p}_ours.txt" "$W/tr_${t}_${p}_ours.pert.txt")"
    [ "$PN" -gt 0 ] || continue
    verdict_for "$t" "$p" --pert | cut -f1-6 > "$W/ctl_pert_$part.tsv"
    verdict_for "$t" "$p" --pert-no-pins | cut -f1-6 > "$W/ctl_pertnp_$part.tsv"
    awk -F'\t' -v n="$part" '!/^#/ && $1==n' "$EXPECT" | cut -f1-6 > "$W/exp_ctl_$part.tsv"
    if command diff -q "$W/exp_ctl_$part.tsv" "$W/ctl_pert_$part.tsv" > /dev/null \
       && ! command diff -q "$W/exp_ctl_$part.tsv" "$W/ctl_pertnp_$part.tsv" > /dev/null; then PP="$part"; break; fi
    echo "  note  $part: x altered on $PN pin frames — under the exclusion $(command diff "$W/exp_ctl_$part.tsv" "$W/ctl_pert_$part.tsv" | command grep -c '^>' || true) verdict row(s) moved (must be 0), without it $(command diff "$W/exp_ctl_$part.tsv" "$W/ctl_pertnp_$part.tsv" | command grep -c '^>' || true) (must be >0)"
done
if [ -z "$PP" ]; then echo "CONTROL DEAD: pins-ignored — no part in the set both keeps its verdicts under the exclusion and moves one without it, on a copy perturbed on its X-pin frames"; fail=1
else echo "CONTROL FIRED: pins-ignored — $PP: x altered on its $PN X-pin frames leaves every verdict as frozen under the exclusion and moves $(command diff "$W/exp_ctl_$PP.tsv" "$W/ctl_pertnp_$PP.tsv" | command grep -c '^>' || true) verdict row(s) with the exclusion off"; fi

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
