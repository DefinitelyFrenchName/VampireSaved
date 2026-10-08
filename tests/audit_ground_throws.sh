#!/bin/sh
# audit_ground_throws.sh — THE VSAVJ GROUND THROWS, MEASURED: every vanilla character's ground throw holds, and
# stages the damage records it does, for the community cross-check (GitHub #229, 14z-195).
# Emulator tier, MAME lane, pristine vsavj only (the reference MAME build run_mame.sh pins for a stock set).
#
# WHAT: for each of the 14 vanilla characters the workbook lists with a ground throw (Anakaris has none), every
#   ground-throw input of the workbook (each "6MP or 6HP" row run with BOTH buttons, so the sheet's one-row claim is
#   measured; Aulbath's 4+P back throw; Victor's MP, HP and K throws), 42 events: the throw HOLDS from the press
#   frame (P1's +0x134 = 0x01 and P2's = 0xFF, RAM:$FF8534/$FF8934), its damage is staged from records of the
#   THROWER'S OWN attack table, and the event's frozen signature — press-to-hold, the side P2 ends on, the meter
#   paid, the damage records in frame order (applier site, record index, real/white power CLASS, flags, the
#   record's meter) — is unchanged. The workbook comparison lives on the cross-check page
#   (tools/crosscheck_framedata.py); this gate holds the measurement it rests on.
# HOW: tools/ground_throw_rigs.py gen builds the rigs (tests/replays/ground_throws/, committed; a fresh gen must
#   equal them); each rig runs twice under tools/run_replay_guarded.sh (-debug): a logging breakpoint at the
#   fighter applier's record read PRG:0x0189EA with the hold/end dumps, and one at the object-hit applier's
#   PRG:0x02979A (Felicia's, Demitri's K, Victor's MP/HP, Zabel's P, Q-Bee's second hit and Aulbath's and
#   Morrigan's P damage go through it); `rows` joins the legs per event, `expect` holds them to
#   tests/expected/ground_throws.tsv. 28 legs, JOBS at a time.
# EXPECTS: 42 events, each holding, every dump frame present, every damage record inside the thrower's own table,
#   and every signature equal to its frozen line.
#
# MUST-FIRE: known-bad: lp-no-throw — Bulleta's rig with both throw presses changed to toward+LP (no throw) must read NO HOLD on both events, and the gate must FAIL (mode: the BU rig runs with LP)
# MUST-FIRE: perturbed-copy: foreign-record — every probe line's A3 moved past the end of its thrower's attack table must fail the identity clause on every event (mode: the rows are built from the shifted probe logs)
# MUST-FIRE: perturbed-copy: class-raw — the rows built from each record's RAW power byte (the pre-#241 reader) must differ from the frozen lines on the flagged records (Q-Bee's second hit, 0x80 on both bytes), and the gate must FAIL (mode: the rows read the raw bytes)
# FOLLOWS: build/manifest/bank_map.toml tests/expected/ground_throws.tsv tests/lib/controls.sh tests/lib/decrypt_cache.sh
#   tests/lua/replay_guard.lua tests/replays/ground_throws/ tools/ground_throw_rigs.py tools/hitbox_records.py
#   tools/name_moves.py tools/run_mame.sh tools/run_replay_guarded.sh tools/setup_mame.sh tools/vanilla_frames.py
#   tools/vanilla_join_rig.py emu/mame-patches/
#
# WHY: #229's ground-throw family. The pursuits were measured at 14z-194 on scratch rigs; this family's rigs are
# promoted the same sitting they were measured ([VSP-18]). The damage figure is the record's power CLASS (#241),
# the record found by what the GAME staged (the applier's A3), never by a table lookup of our own.
#
# Usage: ROMDIR=... [JOBS=5] [OUT=<dir>] tests/audit_ground_throws.sh
set -u
REPO="$(cd "$(dirname "$0")/.." && pwd)"; cd "$REPO"
. "$REPO/tests/lib/controls.sh"; vs_ctl_mode "$0"
[ -n "${ROMDIR:-}" ] || { echo "SKIP: ROMDIR not set"; exit 0; }
ROMDIR="$(cd "$ROMDIR" && pwd)"; export ROMDIR
JOBS="${JOBS:-5}"
RIGS=tests/replays/ground_throws
EXP=tests/expected/ground_throws.tsv
W="${OUT:-$(mktemp -d "${TMPDIR:-/tmp}/gthrow.XXXXXX")}"; mkdir -p "$W"
[ -n "${OUT:-}" ] || trap 'rm -rf "$W"' EXIT
fail=0; ok() { echo "  ok    $*"; }; bad() { echo "  FAIL  $*"; fail=1; }

. "$REPO/tests/lib/decrypt_cache.sh"
decrypt_view vsavj "$W/vsavj_op.bin" "$W/vsavj_data.bin" >/dev/null 2>&1 || { echo "SKIP: the vsavj data view could not be made"; exit 0; }

# THE PERTURBATIONS, one function each, called by the control section and by the mode alike.
lp_rig() {  # lp_rig <out dir>: the BU rig with both throw presses changed to toward+LP
    mkdir -p "$1"; cp "$RIGS/gt_BU.json" "$1/gt_BU.json"
    sed -e 's/p1=R2$/p1=R1/' -e 's/p1=R3$/p1=R1/' "$RIGS/gt_BU.rpl" > "$1/gt_BU.rpl"
    cmp -s "$1/gt_BU.rpl" "$RIGS/gt_BU.rpl" && { echo "lp_rig: no throw press found to change" >&2; return 1; }
    return 0
}
shift_probes() {  # shift_probes <in log> <out log>: every A3 moved 0x100000 up, past any attack table
    python3 - "$1" "$2" <<'PY'
import re, sys
out = []
for l in open(sys.argv[1], errors="replace"):
    if l.startswith("PROBE "):
        l = re.sub(r"A3=([0-9a-fA-F]{8})", lambda m: f"A3={int(m.group(1), 16) + 0x100000:08x}", l)
    out.append(l)
open(sys.argv[2], "w").write("".join(out))
PY
}
raw_tool() {  # raw_tool <out path>: a copy of the rows reader that reads the RAW power byte (the pre-#241 reader)
    # the copy lives outside the tree, so its repo-relative bank_map path is pinned to this tree's
    sed -e 's/"real": b\[8\] & 0x1F, "white": b\[9\] & 0x1F/"real": b[8], "white": b[9]/' \
        -e "s|Path(__file__).resolve().parent.parent / \"build/manifest/bank_map.toml\"|Path(\"$REPO/build/manifest/bank_map.toml\")|" \
        tools/ground_throw_rigs.py > "$1"
    grep -q '"real": b\[8\], "white": b\[9\]' "$1" || { echo "raw_tool: the class read was not found" >&2; return 1; }
    grep -q "Path(\"$REPO/build/manifest/bank_map.toml\")" "$1" || { echo "raw_tool: the bank_map path was not pinned" >&2; return 1; }
    return 0
}

echo "== audit_ground_throws: pristine vsavj ($(python3 -c "import hashlib,sys;print(hashlib.sha1(open(sys.argv[1],'rb').read()).hexdigest()[:12])" "$ROMDIR/vsavj.zip"))"
echo "== 1. the committed rigs are what the generator writes"
python3 tools/ground_throw_rigs.py gen "$W/fresh" > /dev/null
if diff -r "$W/fresh" "$RIGS" > "$W/rigs.diff" 2>&1; then ok "tests/replays/ground_throws/ equals a fresh gen ($(ls "$RIGS"/*.rpl | wc -l | tr -d ' ') rigs)"
else bad "the committed rigs differ from a fresh gen:"; sed 's/^/        /' "$W/rigs.diff" | head -10; fi

G="$RIGS"; vs_ctl_is lp-no-throw && { mkdir -p "$W/lp"; cp "$RIGS"/*.rpl "$RIGS"/*.json "$W/lp/"; lp_rig "$W/lp" || exit 1; G="$W/lp"; }
run_rig() {  # run_rig <rig dir> <name> <legs dir>
    _j="$1/$2.json"
    _p="$(python3 -c "import json,sys;print(';'.join(json.load(open(sys.argv[1]))['pokes']))" "$_j")"
    _d="$(python3 tools/ground_throw_rigs.py dumps "$_j")"
    for _pc in 0189ea 02979a; do
        mkdir -p "$3/$2/$_pc"
        if [ "$_pc" = 0189ea ]; then _dd="$_d"; else _dd=""; fi
        ( POKES="$_p" GUARD_PROBE=$_pc DUMPS="$_dd" tools/run_replay_guarded.sh vsavj "$1/$2.rpl" "$3/$2/$_pc/run.log" "$3/$2/$_pc/sb" \
            > "$3/$2/$_pc/run.out" 2>&1 ) &
        _n=$((_n + 1)); [ $((_n % JOBS)) -eq 0 ] && wait
    done
}
rows_of() {  # rows_of <rig dir> <legs dir> <tool> <probe transform: none|shift> -> rows.jsonl on stdout
    for _j in "$1"/gt_*.json; do
        _b="$(basename "$_j" .json)"; _l1="$2/$_b/0189ea/run.log"; _l2="$2/$_b/02979a/run.log"
        if [ "$4" = shift ]; then shift_probes "$_l1" "$2/$_b/0189ea/shift.log"; shift_probes "$_l2" "$2/$_b/02979a/shift.log"
            _l1="$2/$_b/0189ea/shift.log"; _l2="$2/$_b/02979a/shift.log"; fi
        PYTHONPATH="$REPO/tools" python3 "$3" rows "$_j" "$2/$_b/0189ea" "0189ea=$_l1,02979a=$_l2" "$W/vsavj_data.bin"
    done
}

echo "== 2. the legs (two -debug legs per rig, JOBS=$JOBS)"
_n=0; t0=$(date +%s)
for j in "$G"/gt_*.json; do run_rig "$G" "$(basename "$j" .json)" "$W/legs"; done
wait
dead=0
for j in "$G"/gt_*.json; do b=$(basename "$j" .json)
    for pc in 0189ea 02979a; do grep -q '^END ' "$W/legs/$b/$pc/run.log" 2>/dev/null || { bad "leg $b/$pc did not end: $(tail -1 "$W/legs/$b/$pc/run.out" 2>/dev/null | cut -c1-120)"; dead=1; }
        grep -qE '^(CRASH|PCWEEDS|SOFTRESET)' "$W/legs/$b/$pc/run.log" 2>/dev/null && { bad "leg $b/$pc CRASHED"; dead=1; }; done
done
[ "$dead" = 0 ] && ok "$((_n)) legs ended clean in $(( $(date +%s) - t0 )) s"

echo "== 3. every event against its frozen line"
TOOL="$REPO/tools/ground_throw_rigs.py"; vs_ctl_is class-raw && { raw_tool "$W/tool_raw.py" || exit 1; TOOL="$W/tool_raw.py"; }
TR=none; vs_ctl_is foreign-record && TR=shift
rows_of "$G" "$W/legs" "$TOOL" "$TR" > "$W/rows.jsonl"
if python3 tools/ground_throw_rigs.py expect "$W/rows.jsonl" "$EXP" > "$W/expect.txt" 2>&1; then
    ok "$(tail -1 "$W/expect.txt")"
else
    bad "$(tail -1 "$W/expect.txt")"; grep '^BAD' "$W/expect.txt" | head -12 | sed 's/^/        /'
fi
[ -n "${FREEZE:-}" ] && { python3 tools/ground_throw_rigs.py freeze "$W/rows.jsonl" > "$EXP"; echo "  FROZE $EXP ($(grep -vc '^#' "$EXP") events)"; }

echo "== 4. controls"
if vs_ctl_is lp-no-throw || vs_ctl_is foreign-record || vs_ctl_is class-raw; then
    vs_ctl_fired "$VS_CTL" "the perturbed input ran in its section (mode)"
else
    # foreign-record and class-raw re-read the SAME legs; lp-no-throw runs BU's two legs again with LP
    rows_of "$RIGS" "$W/legs" "$REPO/tools/ground_throw_rigs.py" shift > "$W/rows_shift.jsonl"
    python3 tools/ground_throw_rigs.py expect "$W/rows_shift.jsonl" "$EXP" > "$W/x_shift.txt" 2>&1
    n_alien=$(grep -c 'outside the thrower' "$W/x_shift.txt")
    [ "$n_alien" = 42 ] && vs_ctl_fired foreign-record "the shifted probe logs fail the identity clause on $n_alien events" \
        || { vs_ctl_dead foreign-record "only $n_alien events failed identity"; fail=1; }
    raw_tool "$W/tool_raw.py" && rows_of "$RIGS" "$W/legs" "$W/tool_raw.py" none > "$W/rows_raw.jsonl"
    python3 tools/ground_throw_rigs.py expect "$W/rows_raw.jsonl" "$EXP" > "$W/x_raw.txt" 2>&1
    # FIRED only on a real measurement: every event measured (a crashed reader writes no rows and the expectation
    # then reads "frozen but not measured" — a crash, never a fired control) and a got/want mismatch on Q-Bee
    n_raw=$(wc -l < "$W/rows_raw.jsonl" | tr -d ' ')
    if [ "$n_raw" = 42 ] && ! grep -q 'frozen but not measured' "$W/x_raw.txt" && grep -q "^BAD ('QB', 'P', '6MP'): got" "$W/x_raw.txt"; then
        vs_ctl_fired class-raw "the raw reader differs on Q-Bee's flagged hit ($(grep -c '^BAD' "$W/x_raw.txt") of 42 events differ)"
    else vs_ctl_dead class-raw "rows $n_raw of 42; Q-Bee mismatch: $(grep -c "^BAD ('QB'" "$W/x_raw.txt")"; fail=1; fi
    lp_rig "$W/lpc" && { _n=0; run_rig "$W/lpc" gt_BU "$W/legs_lp"; wait
        python3 tools/ground_throw_rigs.py rows "$W/lpc/gt_BU.json" "$W/legs_lp/gt_BU/0189ea" \
            "0189ea=$W/legs_lp/gt_BU/0189ea/run.log,02979a=$W/legs_lp/gt_BU/02979a/run.log" "$W/vsavj_data.bin" > "$W/rows_lp.jsonl"
        n_nohold=$(python3 -c "import json,sys;print(sum(1 for l in open(sys.argv[1]) if json.loads(l)['hold'] is None))" "$W/rows_lp.jsonl")
        [ "$n_nohold" = 2 ] && vs_ctl_fired lp-no-throw "toward+LP holds on neither BU event (2 NO HOLD)" \
            || { vs_ctl_dead lp-no-throw "$n_nohold of 2 BU events read NO HOLD"; fail=1; }; }
fi
[ "$fail" -eq 0 ] && echo "PASS" || echo "FAIL"
exit "$fail"
