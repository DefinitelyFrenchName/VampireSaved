#!/bin/sh
# audit_ground_throws.sh — THE VSAVJ GROUND THROWS, MEASURED: every vanilla character's ground throw holds from the
# press, lands the damage the game staged, and stages the records it does — for the community cross-check (GitHub
# #229, 14z-195; reworked the same sitting on rule-checker runs 2026-10-08-728 and -730). Emulator tier, MAME lane,
# the vsavj ROM (the reference MAME build run_mame.sh pins for a stock set).
#
# WHAT: for each of the 14 vanilla characters the workbook lists with a ground throw (Anakaris has none), every
#   ground-throw input of the workbook (each "6MP or 6HP" row run with BOTH buttons, so the sheet's one-row claim is
#   measured; Aulbath's 4+P back throw; Victor's MP, HP and K throws), 42 events: the throw HOLDS from the press frame
#   and NOT before it (P1's +0x134 = 0x01 and P2's = 0xFF, RAM:$FF8534/$FF8934); the victim's red and white HP words
#   FALL (read from the dumps, never from the record reader); every record the appliers staged lies in the THROWER'S
#   OWN attack table and LANDS (a fall within 2 frames after its probe frame, in the same run); the event's frozen
#   signature — press-to-hold, the side P2 ends on, the meter paid, the measured falls (red, white, count, the first
#   fall's offset), the staged records in frame order (applier site, record index, real/white power CLASS, flags,
#   the record's meter) — is unchanged. Also: the rigs' row set equals the workbook's ground-throw rows.
# HOW: tools/ground_throw_rigs.py gen builds the rigs (tests/replays/ground_throws/, committed; a fresh gen must
#   equal them); each rig runs twice under tools/run_replay_guarded.sh (-debug, one logging breakpoint per run): at
#   the fighter applier's record read PRG:0x0189EA and at the object-hit applier's PRG:0x02979A. BOTH legs carry the
#   dumps; each leg's records are judged on its OWN dumps; the two legs must agree on the hold frame and on the falls'
#   amounts in order (run 728 Q1a) — NOT on their frames: measured 14z-195, the two -debug legs land the same falls
#   1-2 frames apart (a breakpoint stop skews the timeline, [VSP-129]), so a join by frame is wrong. The 0x0189EA leg
#   also takes SNAP_FRAMES at each event's frozen first-fall frame; a PASS means each snapshot is the frame that run's
#   own first fall landed on, drawn into the CAPTURE SHEET <OUT>/capture.png (tools/ground_throw_rigs.py sheet). The
#   header prints the tree's commit (`git describe --dirty`) and the host.
# EXPECTS: 42 events, each holding from the press and not on the frame before, every dump frame present on both
#   legs, the legs agreeing, every damage record own and landed, falls exactly when damage is staged, and every
#   signature equal to its frozen line; the row set equal to the workbook's (22 rows, Graviton Knuckle declared not
#   measured) where the workbook is present.
# NOT TESTED: the characters are FORCED by the early-window poke (the cursor path is not the subject); positions,
#   P2's HP and P1's meter are re-pinned before each event — the ROM is pristine, the RAM is not. The row set is
#   hand-coded (THROWS) and checked against the workbook only where the workbook is present (section 1 and the
#   cross-check page). Graviton Knuckle, mashed hit counts, throw techs, other victims, FBNeo.
#
# MUST-FIRE: known-bad: lp-no-throw — Bulleta's rig with both throw presses changed to toward+LP (no throw) must read NO HOLD on both events, and the gate must FAIL (mode: the BU rig runs with LP)
# MUST-FIRE: perturbed-copy: foreign-record — every probe line's A3 moved past the end of its thrower's attack table must fail the identity clause on every event (mode: the rows are built from the shifted probe logs)
# MUST-FIRE: perturbed-copy: class-raw — the rows built from each record's RAW power byte (the pre-#241 reader) must differ from the frozen lines on the flagged records, and the gate must FAIL (mode: the rows read the raw bytes)
# MUST-FIRE: perturbed-copy: leg-falls — the 0x02979A leg's dumps with one extra 1-point fall of P2's red HP planted on the frame after every press must make the two legs' fall amounts disagree on every event, and the gate must FAIL (mode: the rows read the planted leg)
# MUST-FIRE: perturbed-copy: hold-before-press — every event's press frame moved 5 frames later in a copy of the rig schedule must find the hold already set on the frame before that press, and the gate must FAIL (mode: the rows read the shifted schedules)
# MUST-FIRE: perturbed-copy: phantom-record — a staged damaging record planted at press+300 on every event (an applier the game never reached there) must read NOT LANDED, and the gate must FAIL (mode: the rows read the planted probes)
# A MODE exits 1 only when ITS perturbation made ITS clause fail (ctl_judge, the same predicate the control section
# reads); otherwise it prints REFUSED and exits 3 (docs/project/must_fire_contract.md; rule-checker run 2026-10-08-730).
# FOLLOWS: build/manifest/bank_map.toml tests/expected/ground_throws.tsv tests/lib/controls.sh tests/lib/decrypt_cache.sh
#   tests/lua/replay_guard.lua tests/replays/ground_throws/ tools/ground_throw_rigs.py tools/hitbox_records.py
#   tools/name_moves.py tools/run_mame.sh tools/run_replay_guarded.sh tools/setup_mame.sh tools/vanilla_frames.py
#   tools/vanilla_join_rig.py tools/xlsx_read.py emu/mame-patches/
#
# WHY: #229's ground-throw family, promoted the sitting it was measured ([VSP-18]). The damage figure is the
# record's power CLASS (#241), the record found by what the GAME staged (the applier's A3) and held to the fall it
# caused, never by a table lookup of our own.
#
# Usage: ROMDIR=... [JOBS=5] [OUT=<dir>] [SHEET=<workbook.xlsx>] tests/audit_ground_throws.sh
set -u
REPO="$(cd "$(dirname "$0")/.." && pwd)"; cd "$REPO"
. "$REPO/tests/lib/controls.sh"; vs_ctl_mode "$0"
[ -n "${ROMDIR:-}" ] || { echo "SKIP: ROMDIR not set"; exit 0; }
ROMDIR="$(cd "$ROMDIR" && pwd)"; export ROMDIR
JOBS="${JOBS:-5}"
RIGS=tests/replays/ground_throws
EXP=tests/expected/ground_throws.tsv
WB="${SHEET:-$REPO/../community/vsav-framedata.xlsx}"
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
raw_tool() {  # raw_tool <out path>: a copy of the rows reader that reads the RAW power byte (the pre-#241 reader)
    # the copy lives outside the tree, so its repo-relative bank_map path is pinned to this tree's
    sed -e 's/real, white = bb\[8\] & 0x1F, bb\[9\] & 0x1F/real, white = bb[8], bb[9]/' \
        -e "s|Path(__file__).resolve().parent.parent / \"build/manifest/bank_map.toml\"|Path(\"$REPO/build/manifest/bank_map.toml\")|" \
        tools/ground_throw_rigs.py > "$1"
    grep -q 'real, white = bb\[8\], bb\[9\]' "$1" || { echo "raw_tool: the class read was not found" >&2; return 1; }
    grep -q "Path(\"$REPO/build/manifest/bank_map.toml\")" "$1" || { echo "raw_tool: the bank_map path was not pinned" >&2; return 1; }
    return 0
}
shadow_legs() {  # shadow_legs <legs root> <out root> <shift|falls>: a perturbed view of every rig's legs (symlinks)
    python3 - "$1" "$2" "$3" <<'PY'
import os, re, sys
src, dst, kind = sys.argv[1:]
for rig in sorted(os.listdir(src)):
    for leg in ("0189ea", "02979a"):
        s, d = os.path.join(src, rig, leg), os.path.join(dst, rig, leg)
        if not os.path.isdir(s):
            continue
        os.makedirs(d, exist_ok=True)
        for f in os.listdir(s):
            p = os.path.join(s, f)
            if not os.path.isfile(p):
                continue
            if kind == "shift" and f == "run.log":          # every A3 moved past any attack table
                txt = open(p, errors="replace").read()
                txt = re.sub(r"A3=([0-9a-fA-F]{8})", lambda m: f"A3={int(m.group(1), 16) + 0x100000:08x}", txt)
                open(os.path.join(d, f), "w").write(txt); continue
            m = re.match(r"dump_(\d+)_ff8850\.bin$", f)
            if kind == "falls" and leg == "02979a" and m and (int(m.group(1)) - 2800) % 600 == 1:
                b = bytearray(open(p, "rb").read())       # one extra 1-point red fall on the frame after each press
                v = int.from_bytes(b[0:2], "big", signed=True) - 1
                b[0:2] = v.to_bytes(2, "big", signed=True)
                open(os.path.join(d, f), "wb").write(bytes(b)); continue
            os.symlink(p, os.path.join(d, f))
PY
}
late_rigs() {  # late_rigs <out dir>: every rig schedule with each event's press moved 5 frames later
    mkdir -p "$1"
    python3 - "$RIGS" "$1" <<'PY'
import json, os, sys
for f in sorted(os.listdir(sys.argv[1])):
    if f.endswith(".json"):
        s = json.load(open(os.path.join(sys.argv[1], f)))
        for e in s["events"]:
            e["press"] += 5
        json.dump(s, open(os.path.join(sys.argv[2], f), "w"))
PY
}
rows_of() {  # rows_of <rig json dir> <legs root> <tool> [probe extra] -> rows.jsonl on stdout
    for _j in "$1"/gt_*.json; do
        _b="$(basename "$_j" .json)"
        PYTHONPATH="$REPO/tools" python3 "$3" rows "$_j" "$2/$_b" "$W/vsavj_data.bin" ${4:+"$4"}
    done
}
# THE ONE PREDICATE PER CONTROL: did ITS perturbation make ITS clause fail? <expect output> <rows.jsonl>; prints the
# evidence; 0 = fired. The control section and the mode read the same function (run 730: a mode that exits 1 on any
# failure cannot tell a firing control from a dead one).
ctl_judge() {  # ctl_judge <control> <expect.txt> <rows.jsonl>
    case "$1" in
        lp-no-throw) _n=$(python3 -c "import json,sys;print(sum(1 for l in open(sys.argv[1]) if json.loads(l)['sheet']=='BU' and json.loads(l)['hold'] is None))" "$3")
                     echo "$_n of 2 BU events read NO HOLD"; [ "$_n" = 2 ] ;;
        foreign-record) _n=$(grep -c 'outside the thrower' "$2"); echo "$_n of 42 events fail the identity clause"; [ "$_n" = 42 ] ;;
        class-raw) _n=$(wc -l < "$3" | tr -d ' ')
                   echo "rows $_n of 42; $(grep -c '^BAD' "$2") events differ; Q-Bee's flagged hit: $(grep -c "^BAD ('QB', 'P', '6MP'): got" "$2")"
                   [ "$_n" = 42 ] && ! grep -q 'frozen but not measured' "$2" && grep -q "^BAD ('QB', 'P', '6MP'): got" "$2" ;;
        leg-falls) _n=$(grep -c 'two applier legs disagree' "$2"); echo "$_n of 42 events read the legs' fall amounts disagreeing"; [ "$_n" = 42 ] ;;
        hold-before-press) _n=$(grep -c 'frame BEFORE the press' "$2"); echo "$_n of 42 events find the hold set before the press"; [ "$_n" = 42 ] ;;
        phantom-record) _n=$(grep -c 'damage the victim never took' "$2"); echo "$_n of 42 events read the planted record NOT LANDED"; [ "$_n" = 42 ] ;;
        *) echo "no such control: $1"; return 2 ;;
    esac
}

echo "== audit_ground_throws: the vsavj ROM ($(python3 -c "import hashlib,sys;print(hashlib.sha1(open(sys.argv[1],'rb').read()).hexdigest()[:12])" "$ROMDIR/vsavj.zip")); tree $(git -C "$REPO" describe --always --dirty --abbrev=40 2>/dev/null || echo 'no git'); host $(hostname)"
echo "== 1. the committed rigs are what the generator writes, and cover the workbook's rows"
python3 tools/ground_throw_rigs.py gen "$W/fresh" > /dev/null
if diff -r "$W/fresh" "$RIGS" > "$W/rigs.diff" 2>&1; then ok "tests/replays/ground_throws/ equals a fresh gen ($(ls "$RIGS"/*.rpl | wc -l | tr -d ' ') rigs)"
else bad "the committed rigs differ from a fresh gen:"; sed 's/^/        /' "$W/rigs.diff" | head -10; fi
if [ -f "$WB" ]; then
    if python3 tools/ground_throw_rigs.py rowset "$WB" > "$W/rowset.txt" 2>&1; then ok "$(head -1 "$W/rowset.txt")"
    else bad "the rigs' row set differs from the workbook's:"; sed 's/^/        /' "$W/rowset.txt"; fi
else
    echo "  NOTE  no workbook at $WB: the row set is not checked here (it is third-party and lives outside the tree)"
fi

G="$RIGS"; vs_ctl_is lp-no-throw && { mkdir -p "$W/lp"; cp "$RIGS"/*.rpl "$RIGS"/*.json "$W/lp/"; lp_rig "$W/lp" || exit 1; G="$W/lp"; }
run_rig() {  # run_rig <rig dir> <name> <legs dir>
    _j="$1/$2.json"
    _p="$(python3 -c "import json,sys;print(';'.join(json.load(open(sys.argv[1]))['pokes']))" "$_j")"
    _d="$(python3 tools/ground_throw_rigs.py dumps "$_j")"
    _s=""; [ -f "$EXP" ] && _s="$(python3 tools/ground_throw_rigs.py snaps "$_j" "$EXP")"
    for _pc in 0189ea 02979a; do
        mkdir -p "$3/$2/$_pc"
        _ss=""; [ "$_pc" = 0189ea ] && _ss="$_s"
        ( POKES="$_p" GUARD_PROBE=$_pc DUMPS="$_d" SNAP_FRAMES="$_ss" \
            tools/run_replay_guarded.sh vsavj "$1/$2.rpl" "$3/$2/$_pc/run.log" "$3/$2/$_pc/sb" > "$3/$2/$_pc/run.out" 2>&1 ) &
        _n=$((_n + 1)); [ $((_n % JOBS)) -eq 0 ] && wait
    done
}

echo "== 2. the legs (two -debug legs per rig, both dumped, JOBS=$JOBS)"
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
LEGS="$W/legs"; vs_ctl_is foreign-record && { shadow_legs "$W/legs" "$W/legs_shift" shift; LEGS="$W/legs_shift"; }
vs_ctl_is leg-falls && { shadow_legs "$W/legs" "$W/legs_falls" falls; LEGS="$W/legs_falls"; }
GJ="$G"; vs_ctl_is hold-before-press && { late_rigs "$W/late"; GJ="$W/late"; }
EXTRA=""; vs_ctl_is phantom-record && EXTRA="+300:auto"
rows_of "$GJ" "$LEGS" "$TOOL" "$EXTRA" > "$W/rows.jsonl"
if python3 tools/ground_throw_rigs.py expect "$W/rows.jsonl" "$EXP" > "$W/expect.txt" 2>&1; then
    ok "$(tail -1 "$W/expect.txt")"
else
    bad "$(tail -1 "$W/expect.txt")"; grep '^BAD' "$W/expect.txt" | head -12 | sed 's/^/        /'
fi
[ -n "${FREEZE:-}" ] && [ -z "${VS_CTL:-}" ] && { python3 tools/ground_throw_rigs.py freeze "$W/rows.jsonl" > "$EXP"; echo "  FROZE $EXP ($(grep -vc '^#' "$EXP") events)"; }

if [ -n "${VS_CTL:-}" ]; then   # THE MODE: exit 1 only if ITS clause failed under ITS perturbation, else REFUSED (3)
    if _ev="$(ctl_judge "$VS_CTL" "$W/expect.txt" "$W/rows.jsonl")"; then
        vs_ctl_fired "$VS_CTL" "$_ev (mode)"; echo "FAIL"; exit 1
    fi
    echo "REFUSED: mode $VS_CTL — its perturbation did not make its own clause fail ($_ev): a dead mode, not a verdict"
    exit 3
fi

echo "== 4. the capture sheet (snapshots at each event's first fall, in the 0x0189EA legs above)"
if ls "$W"/legs/*/0189ea/sb/snap/*/*.png > /dev/null 2>&1; then
    python3 tools/ground_throw_rigs.py sheet "$W/capture.png" "$W/legs" "$G" "$EXP" > "$W/sheet.txt" 2>&1 \
        && ok "$(cat "$W/sheet.txt")" || echo "  NOTE  no capture sheet: $(tail -1 "$W/sheet.txt")"
else
    echo "  NOTE  no snapshots (no frozen expectation to date them yet)"
fi

echo "== 5. controls"
judge() {  # judge <control> <expect.txt> <rows.jsonl>
    if _ev="$(ctl_judge "$1" "$2" "$3")"; then vs_ctl_fired "$1" "$_ev"; else vs_ctl_dead "$1" "$_ev"; fail=1; fi
}
shadow_legs "$W/legs" "$W/c_shift" shift; rows_of "$RIGS" "$W/c_shift" "$REPO/tools/ground_throw_rigs.py" > "$W/rows_shift.jsonl"
python3 tools/ground_throw_rigs.py expect "$W/rows_shift.jsonl" "$EXP" > "$W/x_shift.txt" 2>&1
judge foreign-record "$W/x_shift.txt" "$W/rows_shift.jsonl"
if raw_tool "$W/tool_raw.py"; then rows_of "$RIGS" "$W/legs" "$W/tool_raw.py" > "$W/rows_raw.jsonl"; else : > "$W/rows_raw.jsonl"; fi
python3 tools/ground_throw_rigs.py expect "$W/rows_raw.jsonl" "$EXP" > "$W/x_raw.txt" 2>&1
judge class-raw "$W/x_raw.txt" "$W/rows_raw.jsonl"
shadow_legs "$W/legs" "$W/c_falls" falls; rows_of "$RIGS" "$W/c_falls" "$REPO/tools/ground_throw_rigs.py" > "$W/rows_falls.jsonl"
python3 tools/ground_throw_rigs.py expect "$W/rows_falls.jsonl" "$EXP" > "$W/x_falls.txt" 2>&1
judge leg-falls "$W/x_falls.txt" "$W/rows_falls.jsonl"
late_rigs "$W/c_late"; rows_of "$W/c_late" "$W/legs" "$REPO/tools/ground_throw_rigs.py" > "$W/rows_late.jsonl"
python3 tools/ground_throw_rigs.py expect "$W/rows_late.jsonl" "$EXP" > "$W/x_late.txt" 2>&1
judge hold-before-press "$W/x_late.txt" "$W/rows_late.jsonl"
rows_of "$RIGS" "$W/legs" "$REPO/tools/ground_throw_rigs.py" "+300:auto" > "$W/rows_phantom.jsonl"
python3 tools/ground_throw_rigs.py expect "$W/rows_phantom.jsonl" "$EXP" > "$W/x_phantom.txt" 2>&1
judge phantom-record "$W/x_phantom.txt" "$W/rows_phantom.jsonl"
if lp_rig "$W/lpc"; then
    _n=0; run_rig "$W/lpc" gt_BU "$W/legs_lp"; wait
    rows_of "$W/lpc" "$W/legs_lp" "$REPO/tools/ground_throw_rigs.py" > "$W/rows_lp.jsonl"
    python3 tools/ground_throw_rigs.py expect "$W/rows_lp.jsonl" "$EXP" > "$W/x_lp.txt" 2>&1
    judge lp-no-throw "$W/x_lp.txt" "$W/rows_lp.jsonl"
else vs_ctl_dead lp-no-throw "could not build the LP rig"; fail=1; fi
[ "$fail" -eq 0 ] && echo "PASS" || echo "FAIL"
exit "$fail"
