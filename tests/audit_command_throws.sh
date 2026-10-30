#!/bin/sh
# audit_command_throws.sh — THE VSAVJ COMMAND THROWS AND GRABS, MEASURED (GitHub #229, 14z-205, fork F4 of
# the parallel run). Emulator tier, MAME lane, the vsavj ROM (the reference MAME build run_mame.sh pins for a stock set).
#
# WHAT: for every workbook row of type command throw / grab (every spelling, ES and EX included) — 54 rows, plus
#   Victor's MEGA SPIKE, which the maintainer supplied (not in the workbook) — 168 events (a generic "P"/"K" row run
#   with all three strengths; since 14z-208b THE MOTION TEST: every half-circle throw with 6324/6321/6214/624 and the
#   mirrors 41236/4126/4123/4236/426, 71 events, each direction on its OWN frames since #329 (14z-211: replay.lua's
#   ranges are inclusive, and the 14z-208b rig's shared boundary frames fed every diagonal, so its "624" was 63214),
#   plus one shared-frame 624 kept as the control; the air throws moved to tests/audit_ground_throws.sh), each
#   event's frozen line: in the clear, whether P2 is HELD (P1 +0x134 = 0x01 with P2's = 0xFF, RAM:$FF8534/$FF8934), the
#   stock it spent, and the kind of the move's own state (+0x04: throw 0x0204xx, special 0x0E, ES 0x10, EX 0x12); and a
#   16-hex SHA-256 of its numeric signature — press-to-hold, the move's start, the entered chain START (the anim index
#   tables read with SIGNED offsets, as the game adds them), P2's falls (count, red, white, the first fall's offset),
#   P1's meter at END and the damage records the appliers staged (PRG:0x0189EA, PRG:0x02979A) in frame order. The
#   per-move numbers are not in the tree (the frame-data ruling): the full lines live beside the frame data, outside
#   it (../charpages/framedata/command_throws_full.tsv; CT_FULL), and a red prints the run's own. Also every damaging
#   record inside the thrower's OWN attack or projectile table and LANDED on its own leg's dumps; the capture leg's P2
#   HP at each event's snap frame equal to the trace leg's; the rigs' row set equal to the workbook's (where present).
# HOW: tools/command_throw_rigs.py gen builds the rigs (tests/replays/command_throws/, committed; a fresh gen must equal
#   them); per rig FOUR legs: TRACE (tests/lua/field_trace.lua, no debugger: the per-frame fields), two applier legs
#   P0189EA / P02979A (tools/run_replay_guarded.sh, one logging breakpoint each, P2's HP dumped on every frame of each
#   event: the staged records, each judged LANDED on that leg's OWN falls — a breakpoint stop skews its timeline,
#   [VSP-129]) and CAP (the guard without -debug, SNAP_FRAMES at each event's first fall: the capture sheet).
# EXPECTS: 168 events, every one judged and equal to its frozen line; the row set equal to the workbook's (54 rows).
#   THE INSTRUMENT'S ALIGNMENT (#228 step 4, maintainer-ruled 2026-10-10 "option A"; tests/lib/instr_align.sh): the
#   three replay_guard legs of every rig count EMULATED frames and end on their frozen game clock RAM:$FF8080
#   (tests/expected/instr_gameclock/audit_command_throws.tsv, frozen by `--freeze-clock` from REFERENCE legs each held to
#   replay.lua run live); one STAGING reference leg is held to replay.lua on every run. The TRACE leg is
#   tests/lua/field_trace.lua (no debugger, frame_done — as tests/audit_vanilla_pursuits.sh's FIELD leg): it writes no
#   ALIGN line, and is held instead to the aligned CAP leg — P2's HP equal at all 168 snap frames.
# NOT TESTED: the characters are FORCED by the early-window poke; positions, P2's HP and P1's stock and meter are
#   re-pinned before each event — the ROM is pristine, the RAM is not. The victim is Victor (Demitri for Victor)
#   only; throw techs, mashed hit counts, active, recovery and invuln, FBNeo. Rows the engine never reached on these
#   rigs (Anakaris's HP Mummy Drop in its slot) are frozen as what they DO, not as the move. Since 14z-208b Pit of
#   Blame runs after a knockdown (P2 sweeps; the press is the 623K at +20), Prova di Servo with its second K, Ira
#   Spinta HK at +16 (at the F4 cadence, +12, it grabbed or whiffed with the walk-in); each with a no-follow-up control.
#
# MUST-FIRE: known-bad: drift-clock — the drift leg under the OLD frame_done clock (INSTR_CLOCK=frame_done) must miss its frozen game clock (in-gate: one extra run; mode: every replay_guard leg runs the old clock and the gate FAILs on the alignment)
# MUST-FIRE: known-bad: first-frame-skip — the staging reference leg under the #213 first-frame skip (INSTR_CLOCK=skip_first) must miss replay.lua's checksum (in-gate; mode: the staging leg runs the skip and the gate FAILs on the alignment)
# MUST-FIRE: known-bad: light-strength — Bulleta's 632[4]MP event re-pressed with LP (her 6324+P branch masks the new press to MP|HP, `andi.b #$6` at PRG:0x02E14C) must read P2 NOT HELD, and the gate must FAIL (mode: the BU rig runs with LP)
# MUST-FIRE: perturbed-copy: foreign-record — every damaging record read as outside the thrower's attack and projectile tables must fail the identity clause on every event that staged one (mode: the records read that way)
# MUST-FIRE: perturbed-copy: phantom-record — a damaging record planted at press+300 on every event that staged one must read NOT LANDED, and the gate must FAIL (mode: the records carry the plant)
# MUST-FIRE: perturbed-copy: stock-blind — every event's stock read unchanged at its END must change the frozen stock column of every event that spent one (mode: the rows read that way)
# MUST-FIRE: perturbed-copy: cap-off-by-one — the capture leg's P2 HP compared with the trace leg's one frame early must disagree on every event whose snap frame is a fall (mode: the comparison reads that way)
# MUST-FIRE: perturbed-copy: unsigned-chain — the trace re-analysed with the anim index offsets read UNSIGNED (tools/anim_nodes.py's read) must change the frozen line of Sasquatch's command throws, whose chains start below their index table (mode: the rows read unsigned)
# MUST-FIRE: known-bad: foreign-image — an image one byte off vsavj's data view must fail the provenance check (tests/lib/pristine_vsavj.sh; in-gate; mode: the check is handed that image and the gate FAILs)
# MUST-FIRE: known-bad: foreign-romset — a ROMDIR whose vsavj.zip is vsav2.zip must fail the provenance check (in-gate; mode: the check audits that ROMDIR and the gate FAILs)
# MUST-FIRE: known-bad: foreign-rompath — MAME_ROMPATH pointed away from the audited ROMDIR must fail the provenance check (in-gate; mode: the check runs with it set and the gate FAILs)
# MUST-FIRE: known-bad: foreign-mame — a MAME_BIN that is not the pin's release must fail the provenance check (in-gate; mode: the check runs with it set and the gate FAILs)
# A MODE exits 1 only when ITS perturbation made ITS clause fail (ctl_judge, the same predicate the control section
# reads); otherwise it prints REFUSED and exits 3 (docs/project/must_fire_contract.md).
# FOLLOWS: build/manifest/bank_map.toml tests/expected/command_throws.tsv tests/lib/controls.sh tests/lib/decrypt_cache.sh
#   tests/lua/field_trace.lua tests/lua/pokes_spec.lua tests/lua/replay_guard.lua tests/replays/command_throws/
#   tools/command_throw_rigs.py tools/ground_throw_rigs.py tools/hitbox_records.py tools/name_moves.py tools/anim_nodes.py
#   tools/run_mame.sh tools/run_replay_guarded.sh tools/setup_mame.sh tools/vanilla_frames.py tools/vanilla_join_rig.py
#   tools/xlsx_read.py emu/mame-patches/ tests/expected/instr_gameclock/ tests/lib/instr_align.sh tests/lua/emu_clock.lua
#   tests/lua/replay.lua
#   tests/lib/pristine_vsavj.sh tools/audit_roms.py docs/checksums.txt tools/build_fingerprint.py tools/cps2_decrypt.py tests/expected/registry.tsv tests/lib/mame_ident.sh tools/setup_mame.sh tools/run_mame.sh
#
# SHEET: none — measures pristine vsavj only; no leg of our build (the CAP legs' snapshots are #229's capture sheets)
#
# WHY: #229's command-throw family, measured and gated the sitting it was measured ([VSP-18]). Identity is what the
# ENGINE did — the hold, the move's own state, the chain it entered, the records the GAME staged and the falls they
# caused — never the scripted input ([VSE-47]): the inputs themselves were taken from vsavj's command handlers.
#
# Usage: ROMDIR=... [JOBS=2] [OUT=<dir>] [SHEET=<workbook.xlsx>] [FREEZE=1] tests/audit_command_throws.sh [--freeze-clock]
set -u
REPO="$(cd "$(dirname "$0")/.." && pwd)"; cd "$REPO"
. "$REPO/tests/lib/controls.sh"; vs_ctl_mode "$0"; MODE="${VS_CTL:-}"
. "$REPO/tests/lib/instr_align.sh"
FREEZE_CLOCK=0; [ "${1:-}" = "--freeze-clock" ] && FREEZE_CLOCK=1
CLOCKS="tests/expected/instr_gameclock/audit_command_throws.tsv"
[ "$FREEZE_CLOCK" = 1 ] && [ -n "$MODE" ] && { echo "REFUSED: --freeze-clock in control mode"; exit 3; }
_clk=""; [ "$MODE" = drift-clock ] && _clk="INSTR_CLOCK=frame_done"
[ -n "${ROMDIR:-}" ] || { echo "SKIP: ROMDIR not set"; exit 0; }
ROMDIR="$(cd "$ROMDIR" && pwd)"; export ROMDIR
JOBS="${JOBS:-2}"
RIGS=tests/replays/command_throws
EXP=tests/expected/command_throws.tsv
T=tools/command_throw_rigs.py
WB="${SHEET:-$REPO/../community/vsav-framedata.xlsx}"
W="${OUT:-$(mktemp -d "${TMPDIR:-/tmp}/cthrow.XXXXXX")}" || { echo "FAIL: audit_command_throws — mktemp -d failed (W)"; exit 2; }; mkdir -p "$W"
[ -n "${OUT:-}" ] || trap 'rm -rf "$W"' EXIT
fail=0; ok() { echo "  ok    $*"; }; bad() { echo "  FAIL  $*"; fail=1; }

. "$REPO/tests/lib/decrypt_cache.sh"
decrypt_view vsavj "$W/vsavj_op.bin" "$W/vsavj_data.bin" >/dev/null 2>&1 || { echo "SKIP: the vsavj data view could not be made"; exit 0; }
export CT_IMAGE="$W/vsavj_data.bin"
# WHICH ROM AND WHICH IMAGE (14z-209, rule-checker run 2026-10-25-1294 Q1/Q4): tests/lib/pristine_vsavj.sh.
. "$REPO/tests/lib/pristine_vsavj.sh"
vs_pristine_vsavj "$W/pv" "$W/vsavj_data.bin" || { echo "FAIL: audit_command_throws (the ROM or the analysed image is not pristine vsavj)"; exit 1; }
if [ -z "$MODE" ]; then vs_pristine_vsavj_controls "$W/pv" || { echo "FAIL: audit_command_throws (a provenance control is dead)"; exit 1; }; fi

# THE PERTURBATIONS, one function each, called by the control section and by the mode alike.
lp_rig() {  # lp_rig <out dir>: every rig, Bulleta's with the 632[4]MP event's button changed to LP
    mkdir -p "$1"; cp "$RIGS"/*.rpl "$RIGS"/*.json "$1/"
    sed 's/ p1=2$/ p1=1/' "$RIGS/ct_BU_1.rpl" > "$1/ct_BU_1.rpl"
    cmp -s "$RIGS/ct_BU_1.rpl" "$1/ct_BU_1.rpl" && { echo "lp_rig: no MP press found to change" >&2; return 1; }
    return 0
}
unsigned_view() {  # unsigned_view <rigs dir> <legs root> <out root>: every leg linked, the trace rows re-analysed UNSIGNED
    for _j in "$1"/ct_*.json; do _b="$(basename "$_j" .json)"; mkdir -p "$3/$_b/trace"
        for _l in p0189ea p02979a cap; do ln -s "$2/$_b/$_l" "$3/$_b/$_l"; done
        ln -s "$2/$_b/trace/t.txt" "$3/$_b/trace/t.txt"
        CT_UNSIGNED=1 python3 "$T" analyse "$_j" "$2/$_b/trace/t.txt" "$W/vsavj_data.bin" > "$3/$_b/trace/rows.jsonl"
    done
}
ctl_judge() {  # ctl_judge <control> <expect.txt>: did ITS perturbation make ITS clause fail? prints the evidence
    case "$1" in
        light-strength) _n=$(grep "^BAD ('BU', '1', '632\[4\] MP'): got" "$2" | awk -F'\t' '$4 == "no"' | wc -l | tr -d ' '); echo "Bulleta's 632[4]MP pressed with LP reads P2 not held: $_n (want 1)"; [ "$_n" = 1 ] ;;
        foreign-record) _n=$(grep -c 'outside the thrower' "$2"); echo "$_n events fail the identity clause (want 159)"; [ "$_n" = 159 ] ;;
        phantom-record) _n=$(grep -c 'damage the victim never took' "$2"); echo "$_n events read the planted record NOT LANDED (want 159)"; [ "$_n" = 159 ] ;;
        stock-blind) _n=$(grep -c '^BAD' "$2"); echo "$_n events change the stock column (want 29)"; [ "$_n" = 29 ] ;;
        cap-off-by-one) _n=$(grep -c "the capture leg's P2 HP" "$2"); echo "$_n events read the capture leg disagreeing (want 159)"; [ "$_n" = 159 ] ;;
        unsigned-chain) _n=$(grep -c "^BAD ('SA'" "$2"); echo "$_n of Sasquatch's events change (want 10: all but motion 6321HP, a crouching normal, and 6214HP/624HP, normal throws since #329)"; [ "$_n" = 10 ] ;;
        *) echo "no such control: $1"; return 2 ;;
    esac
}

echo "== audit_command_throws: the vsavj ROM ($(python3 -c "import hashlib,sys;print(hashlib.sha1(open(sys.argv[1],'rb').read()).hexdigest()[:12])" "$ROMDIR/vsavj.zip")); tree $(git -C "$REPO" describe --always --dirty --abbrev=40 2>/dev/null || echo 'no git'); host $(hostname); JOBS=$JOBS"
echo "== 1. the committed rigs are what the generator writes, and cover the workbook's rows"
python3 "$T" gen "$W/fresh" > /dev/null
if diff -r "$W/fresh" "$RIGS" > "$W/rigs.diff" 2>&1; then ok "$RIGS equals a fresh gen ($(ls "$RIGS"/*.rpl | wc -l | tr -d ' ') rigs)"
else bad "the committed rigs differ from a fresh gen:"; sed 's/^/        /' "$W/rigs.diff" | head -10; fi
if [ -f "$WB" ]; then
    if python3 "$T" rowset "$WB" > "$W/rowset.txt" 2>&1; then ok "$(head -1 "$W/rowset.txt")"
    else bad "the rigs' row set differs from the workbook's:"; sed 's/^/        /' "$W/rowset.txt"; fi
else echo "  NOTE  no workbook at $WB: the row set is not checked here (it is third-party and lives outside the tree)"; fi

G="$REPO/$RIGS"; vs_ctl_is light-strength && { lp_rig "$W/lp" || exit 1; G="$W/lp"; }
run_leg() {  # run_leg <rigs dir> <rig> <legs root> <trace|p0189ea|p02979a|cap>
    _j="$1/$2.json"; _r="$1/$2.rpl"; _o="$3/$2/$4"; rm -rf "$_o"; mkdir -p "$_o"
    _p="$(python3 -c "import json,sys;print(';'.join(json.load(open(sys.argv[1]))['pokes']))" "$_j")"
    _f="$(python3 -c "import json,sys;print(json.load(open(sys.argv[1]))['frames'])" "$_j")"
    case "$4" in
      trace) ( cd "$_o" && MAME_SANDBOX="$_o/sb" REPLAY="$_r" POKES="$_p" FIELDS="$(python3 "$REPO/$T" fields)" FIELD_OUT="$_o/t.txt" \
                 FIELD_FROM=2400 FIELD_TO="$_f" FRAMES="$_f" "$REPO/tools/run_mame.sh" vsavj \
                 -autoboot_script "$REPO/tests/lua/field_trace.lua" > "$_o/l.log" 2>&1 ) </dev/null
             rm -rf "$_o/sb"
             python3 "$T" analyse "$_j" "$_o/t.txt" "$W/vsavj_data.bin" > "$_o/rows.jsonl" ;;
      p0189ea|p02979a) _pc="${4#p}"; _d="$(python3 "$T" dumps "$_j")"
             printf '%s' "POKES=$_p GUARD_PROBE=$_pc DUMPS=$_d" > "$_o/env"
             # shellcheck disable=SC2086
             ( env $_clk POKES="$_p" GUARD_PROBE="$_pc" DUMPS="$_d" ALIGN_OUT="$_o/align" \
                 tools/run_replay_guarded.sh vsavj "$_r" "$_o/run.log" "$_o/sb" > "$_o/run.out" 2>&1 ) </dev/null ;;
      cap)   _sn="$(python3 "$T" snaps "$3/$2/trace/rows.jsonl")"
             _sf="$(printf '%s\n' "$_sn" | sed -n 's/^SNAP_FRAMES=//p')"; _du="$(printf '%s\n' "$_sn" | sed -n 's/^DUMPS=//p')"
             printf '%s' "POKES=$_p DUMPS=$_du SNAP_FRAMES=$_sf GUARD_DEBUG=0" > "$_o/env"
             # shellcheck disable=SC2086
             ( env $_clk GUARD_DEBUG=0 POKES="$_p" DUMPS="$_du" SNAP_FRAMES="$_sf" ALIGN_OUT="$_o/align" \
                 tools/run_replay_guarded.sh vsavj "$_r" "$_o/run.log" "$_o/sb" > "$_o/run.out" 2>&1 ) </dev/null ;;
    esac
}
legs_of() {  # legs_of <rigs dir> <legs root>: TRACE and both applier legs JOBS at a time, then the CAP legs (dated by TRACE)
    mkdir -p "$2"; _n=0
    for _j in "$1"/ct_*.json; do _b="$(basename "$_j" .json)"
        for _l in trace p0189ea p02979a; do run_leg "$1" "$_b" "$2" "$_l" & _n=$((_n + 1)); [ $((_n % JOBS)) -eq 0 ] && wait; done
    done; wait
    for _j in "$1"/ct_*.json; do run_leg "$1" "$(basename "$_j" .json)" "$2" cap & _n=$((_n + 1)); [ $((_n % JOBS)) -eq 0 ] && wait; done; wait
}

echo "== 2. the legs (TRACE, P0189EA, P02979A, CAP per rig; JOBS=$JOBS)"
t0=$(date +%s); legs_of "$G" "$W/legs"
dead=0; nl=0
for j in "$G"/ct_*.json; do b=$(basename "$j" .json)
    grep -q '^FIELDSUMMARY' "$W/legs/$b/trace/t.txt" 2>/dev/null || { bad "leg $b/trace did not complete"; dead=1; }
    for l in p0189ea p02979a cap; do nl=$((nl + 1))
        grep -q '^END ' "$W/legs/$b/$l/run.log" 2>/dev/null || { bad "leg $b/$l did not end: $(tail -1 "$W/legs/$b/$l/run.out" 2>/dev/null | cut -c1-120)"; dead=1; }
        grep -qE '^(CRASH|PCWEEDS|SOFTRESET)' "$W/legs/$b/$l/run.log" 2>/dev/null && { bad "leg $b/$l CRASHED"; dead=1; }; done
done
[ "$dead" = 0 ] && ok "$(( nl + nl / 3 )) legs ended clean in $(( $(date +%s) - t0 )) s"
for j in "$G"/ct_*.json; do b=$(basename "$j" .json)
    for l in p0189ea p02979a cap; do
        _e="$(sed 's/SNAP_FRAMES=$//; s/SNAP_FRAMES= / /' "$W/legs/$b/$l/env")"
        ia_note_run "$W/manifest.tsv" "$l" "$b" vsavj - "$G/$b.rpl" "$_e" "$W/legs/$b/$l/align"
    done
done

echo "== 3. every event against its frozen line"
LEGS="$W/legs"; PT=""
case "$MODE" in foreign-record|phantom-record|stock-blind|cap-off-by-one) PT="--perturb=$MODE" ;; esac
vs_ctl_is unsigned-chain && { unsigned_view "$G" "$W/legs" "$W/legs_u"; LEGS="$W/legs_u"; }
if [ -n "${FREEZE:-}" ] && [ -z "$MODE" ]; then
    python3 "$T" expect "$LEGS" "$G" "$EXP" --freeze > "$W/freeze.txt" 2>&1 && ok "$(tail -1 "$W/freeze.txt")" || { bad "$(tail -1 "$W/freeze.txt")"; grep '^BAD' "$W/freeze.txt" | head -8; }
fi
if python3 "$T" expect "$LEGS" "$G" "$EXP" $PT > "$W/expect.txt" 2>&1; then ok "$(tail -1 "$W/expect.txt")"
else bad "$(tail -1 "$W/expect.txt")"; grep -A3 '^BAD' "$W/expect.txt" | head -16 | sed 's/^/        /'; fi
if [ -n "$MODE" ] && [ "$MODE" != drift-clock ] && [ "$MODE" != first-frame-skip ]; then
    if _ev="$(ctl_judge "$MODE" "$W/expect.txt")"; then vs_ctl_fired "$MODE" "$_ev (mode)"; echo "FAIL"; exit 1; fi
    echo "REFUSED: mode $MODE — its perturbation did not make its own clause fail ($_ev): a dead mode, not a verdict"; exit 3
fi

echo "== 3b. the instrument's alignment (#228 step 4, option A)"
if [ "$FREEZE_CLOCK" = 1 ]; then
    [ "$fail" = 0 ] || { echo "REFUSED: sections 1-3 failed — nothing frozen"; exit 1; }
    ia_freeze "$REPO/tests/lua/replay_guard.lua" "$W/manifest.tsv" "$W/fz" "$JOBS" "$W/clocks.tsv" \
        > "$W/fz.txt" || { sed 's/^/  /' "$W/fz.txt"; echo "REFUSED: the alignment does not hold — nothing frozen"; exit 1; }
    mkdir -p "$(dirname "$CLOCKS")"
    { echo "# $CLOCKS — the game clock RAM:\$FF8080 at each run's last frame, frozen from REFERENCE legs (#228 step 4,"
      echo "# option A) by \`tests/audit_command_throws.sh --freeze-clock\` at $(git rev-parse --short=8 HEAD): pristine vsavj; legs p0189ea,"
      echo "# p02979a and cap per rig; every reference leg held to replay.lua run live, every guarded leg to its reference leg's game clock."
      echo "# leg<TAB>replay<TAB>frames<TAB>gameclock"
      cat "$W/clocks.tsv"; } > "$CLOCKS"
    echo "froze $(wc -l < "$W/clocks.tsv" | tr -d ' ') game clocks into $CLOCKS"
    exit 0
fi
if ia_check_manifest "$CLOCKS" "$W/manifest.tsv" > "$W/align_bad.txt"; then ok "every guarded leg on emulated time, at its frozen game clock ($(wc -l < "$W/manifest.tsv" | tr -d ' ') runs)"
else bad "$(wc -l < "$W/align_bad.txt" | tr -d ' ') problem(s) off the frozen alignment:"; head -8 "$W/align_bad.txt" | sed 's/^/        /'; fi
ia_stage audit_command_throws "$CLOCKS" "$REPO/tests/lua/replay_guard.lua" "$W/manifest.tsv" 1 "$W/st" "$MODE" || fail=1
if [ "$MODE" = drift-clock ] || [ "$MODE" = first-frame-skip ]; then
    [ "$fail" = 1 ] && { echo "FAIL (control mode: $MODE)"; exit 1; }
    echo "FAIL — control mode $MODE left the gate green"; exit 1
fi
if [ "$IA_DRIFT" = fired ]; then vs_ctl_fired drift-clock "$IA_DRIFT_MSG"; else vs_ctl_dead drift-clock "$IA_DRIFT_MSG" || fail=1; fi
if [ "$IA_SKIP" = fired ]; then vs_ctl_fired first-frame-skip "$IA_SKIP_MSG"; else vs_ctl_dead first-frame-skip "$IA_SKIP_MSG" || fail=1; fi

echo "== 4. controls"
judge() { if _ev="$(ctl_judge "$1" "$2")"; then vs_ctl_fired "$1" "$_ev"; else vs_ctl_dead "$1" "$_ev"; fail=1; fi; }
for c in foreign-record phantom-record stock-blind cap-off-by-one; do
    python3 "$T" expect "$W/legs" "$G" "$EXP" --perturb=$c > "$W/x_$c.txt" 2>&1; judge "$c" "$W/x_$c.txt"
done
unsigned_view "$G" "$W/legs" "$W/c_u"; python3 "$T" expect "$W/c_u" "$G" "$EXP" > "$W/x_unsigned.txt" 2>&1; judge unsigned-chain "$W/x_unsigned.txt"
if lp_rig "$W/lpc"; then
    run_leg "$W/lpc" ct_BU_1 "$W/legs_lp" trace & run_leg "$W/lpc" ct_BU_1 "$W/legs_lp" p0189ea & wait   # JOBS <= 2 MAME
    run_leg "$W/lpc" ct_BU_1 "$W/legs_lp" p02979a & run_leg "$W/lpc" ct_BU_1 "$W/legs_lp" cap & wait
    for j in "$W"/lpc/ct_*.json; do b=$(basename "$j" .json); [ "$b" = ct_BU_1 ] || ln -s "$W/legs/$b" "$W/legs_lp/$b"; done
    python3 "$T" expect "$W/legs_lp" "$W/lpc" "$EXP" > "$W/x_lp.txt" 2>&1
    judge light-strength "$W/x_lp.txt"
else vs_ctl_dead light-strength "could not build the LP rig"; fail=1; fi
[ "$fail" -eq 0 ] && echo "PASS" || echo "FAIL"
exit "$fail"
