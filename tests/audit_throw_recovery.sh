#!/bin/sh
# audit_throw_recovery.sh — THE VSAVJ THROWS' RECOVERY AND THROW TECH, MEASURED: when each fighter can act again after
# every ground and air throw, thrown and teched, the tech window, and every command throw's whiff and techability — for
# the community cross-check (GitHub #330, 14z-211). Emulator tier, MAME lane, the vsavj ROM (the reference MAME build run_mame.sh pins for a stock set).
#
# WHAT: the normal throws of tools/ground_throw_rigs.py — the 42 GROUND events (the workbook's 22 ground-throw rows,
#   each "6MP or 6HP" row with both buttons) and the 28 AIR events (its 14 air-throw rows, j.6MP and j.6HP), victim
#   Victor (Demitri for Victor): (1) ACTIONABLE, the maintainer's "First accepted input" (2026-10-28): for the thrower
#   and the victim, thrown and teched, the frozen tick from the throw's commit (P1's press frame, where the hold starts)
#   at which a ONE-frame LP starts the normal, the tick before never doing so; (2) the TECH WINDOW: P2's back + the
#   throw's own button one frame at k ticks after the commit techs (the victim's red loss changes, or its recovery
#   moves more than 10 ticks) at k = 1 and k = 7 alike, at k = 8 not; the window frozen per event (`1-7`, or `none`
#   where no tech exists — Lei-Lei's air throw); (3) each event's full line — the four ticks, the controls' +0x04 at
#   them, the victim's red/white HP loss thrown and teched, the window — equals its frozen line: in the tree as a
#   16-hex SHA-256 per event (tests/expected/throw_recovery.tsv, throw_recovery_air.tsv), the line itself outside it
#   (../charpages/framedata/throw_recovery[_air]_full.tsv, TR_FULL; the 14z-126 frame-data ruling, #319). THE COMMAND
#   THROWS (family `command`, the maintainer's "Whiff recovery + techability", 2026-10-28): the 82 non-motion events of
#   tools/command_throw_rigs.py that hold in #229's frozen expectation — the WHIFF from pins 150 px wider each (the
#   first accepted input from the press, the tick before never; the whiff must START THE GRAB'S OWN MOVE: on the press
#   frame or the five after, the state seq the same input starts when it connects, the whiff control never holding — the four ES grabs, ruled to whiff
#   into their own seq 0x12, that seq — never standing, walking, a jump or the button's normal) and the TECH at contact (the
#   victim's back + HP and + HK at 1 and 7 ticks after the hold, alike). 28 EVENTS HAVE NO WHIFF (ruled 2026-10-28,
#   14z-212, "No whiff"): Pit of Blame (its input draws no move without a knocked-down victim) and the 24 grabs the
#   engine's throw check gates (tools/throw_recovery_rigs.py CMD_GATED): out of range, or against a victim the check
#   refuses, their input is the button's plain normal or a jump — a first measurement had frozen that as their "whiff".
# HOW: tools/throw_recovery_rigs.py gen makes, from the full lines' ticks, per event a THROWN rig (a sacrificial first
#   event — a rig's first event stands at another stage x —, the control, k = 8, P1 LP at A-1 and A, P2 LP at A-1 and
#   A) and a TECHED rig (the same with the tech at k = 1, and k = 7), at speed level 0 (RAM:$FF8116 = 00: one engine
#   pass per frame, so ticks are frames) with the RNG pinned (RAM:$FF80D4 = 0000), events 624 frames apart; the air
#   rigs press at the TICK the level-6 rigs reach it (tools/throw_recovery_rigs.py air_l0: every y and dx at the commit
#   equal the level-6 rig's). The rigs are made at run time and never committed (their press offsets ARE the per-move
#   ticks). Each rig runs once under tools/run_mame.sh with tests/lua/field_trace.lua (both fighters' +0x04, both
#   +0x134, both HP words, x, the pass counter), JOBS at a time; a press is ACCEPTED when the presser's +0x04 departs
#   from its no-LP control ON the press frame into seq 0x0A, mode 00. The header prints the tree's commit, the script's own blob (every log names the script it ran) and the host.
# EXPECTS: per family 2 rigs per event, every trace complete; on every event every A-1 press refused and every A press
#   accepted (four ticks), k = 1 and 7 alike, k = 8 not teching, every control holding on its press frame, every line
#   equal to its frozen hash; the full lines present and each equal to its in-tree hash.
# NOT TESTED: the air throws' other heights by default (TR_FAMILY=air TR_HEIGHT=-3 / 3 / 6 run their own frozen sets, the
#   cross-check page's height range, ruled 2026-10-28); other victims by default (TR_VICTIM=01 / 0e run Demitri and
#   Lilith against their own frozen sets, every family — the ground throw tech's three-victim range on the cross-check
#   page, ruled 2026-10-28, and the maintainer's "Measure them too" for the air and command families; not the gate's
#   default, ruled "New gate, Victor only"). On another victim an event whose control never holds there is LEFT OUT of
#   that victim's set (tools/throw_recovery_rigs.py AIR_NOHOLD_VICTIM, CMD_NOHOLD_VICTIM: on Lilith the air throws of
#   Aulbath, Gallon, Jedah and Victor; Anakaris's and Jedah's grabs listed there), as a height that does not throw is;
#   other STAGE POSITIONS (every event at the rig's one walk-in place; a rig's first event at another stage x moved
#   Morrigan's K throw by 6 ticks), the corner; the command throws' tech with any other input or tick (only the victim's
#   back + HP and back + HK at k = 1 and 7: Giga Shock's window `1-7` is read from those two, its edges unprobed); a
#   blocking or hit-stunned victim against the 24 gated grabs; mashing (Morrigan's and Demitri's K throws, the
#   multi-hit throws are measured unmashed), speed levels other than 0 (the window and the recovery in ticks were
#   measured level-independent on the pilot, probe 2), the characters picked by the cursor (forced by poke), FBNeo.
#   The ticks are MEASURED by build/agent211/t330's and build/agent212/t330's scans and only RE-PROVED here: a tick that moved fails, but the gate
#   does not find the new one. A host without the full lines (TR_FULL) SKIPs that family, saying so.
#
# MUST-FIRE: perturbed-copy: tick-early — every frozen tick moved one EARLIER in a copy (the true A-1 read as A) must find the press on it refusing to start the normal, on every tick of every event (in-gate: Felicia's 6MP and j.6MP alone, and the command family's first whiffing event, Anakaris's — every Felicia grab is gated; mode: every event of every family)
# MUST-FIRE: known-bad: lp-tech — the tech press made with LP (back + LP, not a throw input) must read no tech on every event whose frozen window is 1-7 (in-gate: each family's first techable event; mode: every techable event)
# MUST-FIRE: known-bad: gated-whiff — a whiff rig made for a grab with NO whiff (CMD_GATED) must read "the whiff started no move" (in-gate: Felicia's 632[4] MK alone; mode: all 24; command family only, the others are not judged)
# MUST-FIRE: perturbed-copy: es-exemption-dropped — the four ES grabs judged WITHOUT their ruled whiff seq 0x12 (as every other whiff is: the seq the input starts when it connects, 0x10) must each read "the whiff started seq 12, not the grab's own" (in-gate: Aulbath's 6324PP alone; mode: all four; command family only, the others are not judged)
# MUST-FIRE: known-bad: whiff-at-contact — every whiff rig made at CONTACT, where the grab connects, must read "the whiff control HOLDS" (in-gate: the command family's first whiffing event; mode: all 54; command family only, the others are not judged)
# MUST-FIRE: perturbed-copy: late-window — the thrown rig's k = 8 press moved to k = 7 must read the k = 8 slot TECHING on every techable event (in-gate: Felicia's 6MP alone; mode: every techable event; the command family has no k = 8 slot and is not judged)
# A MODE exits 1 only when ITS perturbation made ITS clause fail (ctl_judge, the same predicate the control section
# reads); otherwise it prints REFUSED and exits 3 (docs/project/must_fire_contract.md).
# FOLLOWS: tools/throw_recovery_rigs.py tools/ground_throw_rigs.py tools/name_moves.py tools/vanilla_join_rig.py
#   tools/vanilla_frames.py tools/run_mame.sh tools/setup_mame.sh tests/lua/field_trace.lua tests/lib/controls.sh
#   tests/lib/jobs.sh tests/expected/throw_recovery.tsv tests/expected/throw_recovery_v01.tsv
#   tests/expected/throw_recovery_v0e.tsv tests/expected/throw_recovery_air.tsv tests/expected/throw_recovery_air_h-3.tsv
#   tests/expected/throw_recovery_air_h+3.tsv tests/expected/throw_recovery_air_h+6.tsv tests/expected/throw_recovery_air_v01.tsv
#   tests/expected/throw_recovery_air_v0e.tsv tests/expected/throw_recovery_command.tsv tests/expected/throw_recovery_command_v01.tsv
#   tests/expected/throw_recovery_command_v0e.tsv
#   tests/expected/command_throws.tsv tools/command_throw_rigs.py emu/mame-patches/
#
# SHEET: none — measures pristine vsavj and/or native vsav2 only; no leg of our build
#
# WHY: #330 (split from #229): the workbook's `recovery` and `throw tech` columns, measured, promoted the sitting they
# were measured ([VSP-18]). The ticks are found by what the game ACCEPTS, never by a state the engine might pass through
# (the mode byte returns to 00 early on 22 of 42 ground events; build/agent211/t330/notes.md probes 5-6).
#
# Usage: ROMDIR=... [JOBS=N] [OUT=<dir>] [TR_FAMILY=ground|air|command] [TR_HEIGHT=-3|3|6] [TR_VICTIM=<hex>] [TR_FULL=<lines>]
#        [FREEZE=1 TR_FAMILY=<f> TR_TICKS=<ticks.tsv>] tests/audit_throw_recovery.sh
set -u
REPO="$(cd "$(dirname "$0")/.." && pwd)"; cd "$REPO"
. "$REPO/tests/lib/controls.sh"; vs_ctl_mode "$0"; MODE="${VS_CTL:-}"
. "$REPO/tests/lib/jobs.sh"
[ -n "${ROMDIR:-}" ] || { echo "SKIP: ROMDIR not set"; exit 0; }
ROMDIR="$(cd "$ROMDIR" && pwd)"; export ROMDIR
[ -f "$ROMDIR/vsavj.zip" ] || { echo "SKIP: no $ROMDIR/vsavj.zip"; exit 0; }
vs_jobs JOBS 12 1
TOOL=tools/throw_recovery_rigs.py
W="${OUT:-$(mktemp -d "${TMPDIR:-/tmp}/trec.XXXXXX")}" || { echo "FAIL: audit_throw_recovery — mktemp -d failed (W)"; exit 2; }; mkdir -p "$W"
[ -n "${OUT:-}" ] || trap 'rm -rf "$W"' EXIT
W="$(cd "$W" && pwd)"   # absolute: every run cds into its own directory
fail=0; ok() { echo "  ok    $*"; }; bad() { echo "  FAIL  $*"; fail=1; }
F="ff8404:l:p1st,ff8804:l:p2st,ff8534:b:p1thr,ff8934:b:p2thr,ff8850:w:p2red,ff8852:w:p2wht,ff8450:w:p1red,ff8452:w:p1wht,ff8410:w:p1x,ff8810:w:p2x,ff8081:b:pass"
FAMS="${TR_FAMILY:-ground air command}"
[ -n "${FREEZE:-}" ] && [ -z "${TR_FAMILY:-}" ] && { echo "REFUSED: FREEZE needs TR_FAMILY=ground|air|command (one family's ticks)"; exit 3; }
[ -n "${FREEZE:-}" ] && [ -n "$MODE" ] && { echo "REFUSED: FREEZE in control mode"; exit 3; }
tr_py() { TR_FAMILY="$1" python3 -c "import sys;sys.path.insert(0,'tools');import throw_recovery_rigs as t;print($2)"; }

# THE ONE PREDICATE PER CONTROL: did ITS perturbation make ITS clause fail? <expect output> <n events expected>
ctl_judge() {  # ctl_judge <control> <expect.txt> <n> [ticks per event, 4; the command family's whiff: 1]
    case "$1" in
        tick-early) _n=$(grep 'the LP on the frozen tick did not start the normal' "$2" | sed 's/: .*//' | sort | uniq -c | awk -v k="${4:-4}" '$1 == k' | wc -l | tr -d ' ')
                    echo "$_n of $3 events refuse the press on all ${4:-4} shifted tick(s)"; [ "$_n" = "$3" ] ;;
        lp-tech) _n=$(grep -c 'the tech window reads none, frozen 1-7' "$2"); echo "$_n of $3 techable events read no tech"; [ "$_n" = "$3" ] ;;
        late-window) _n=$(grep -c 'k = 8 TECHS' "$2"); echo "$_n of $3 techable events read the k = 8 slot teching"; [ "$_n" = "$3" ] ;;
        gated-whiff) _n=$(grep 'the whiff started no move' "$2" | sed 's/: .*//' | sort -u | wc -l | tr -d ' ')
                     echo "$_n of $3 gated grabs read their whiff as no move"; [ "$_n" = "$3" ] ;;
        whiff-at-contact) _n=$(grep 'the whiff control HOLDS' "$2" | sed 's/: .*//' | sort -u | wc -l | tr -d ' ')
                     echo "$_n of $3 whiffs made at contact read the grab connecting"; [ "$_n" = "$3" ] ;;
        es-exemption-dropped) _n=$(grep "the whiff started seq 12, not the grab's own" "$2" | sed 's/: .*//' | sort -u | wc -l | tr -d ' ')
                     echo "$_n of $3 ES grabs read their whiff as not the grab's own move"; [ "$_n" = "$3" ] ;;
        *) echo "no such control: $1"; return 2 ;;
    esac
}
run_one() {  # run_one <rigs dir> <rig> <traces dir>
    _o="$3/$2.d"; rm -rf "$_o"; mkdir -p "$_o"
    _p="$(python3 -c "import json,sys;print(';'.join(json.load(open(sys.argv[1]))['pokes']))" "$1/$2.json")"
    _n="$(python3 -c "import json,sys;print(json.load(open(sys.argv[1]))['frames'])" "$1/$2.json")"
    ( cd "$_o" && MAME_SANDBOX="$_o/sb" REPLAY="$1/$2.rpl" POKES="$_p" FIELDS="$F" FIELD_OUT="$3/$2.txt" FIELD_FROM=2400 \
        FIELD_TO="$_n" FRAMES="$_n" timeout 1800 "$REPO/tools/run_mame.sh" vsavj -autoboot_script "$REPO/tests/lua/field_trace.lua" \
        > "$_o/run.log" 2>&1; echo "rc=$?" >> "$_o/run.log" ) < /dev/null
}
run_rigs() {  # run_rigs <rigs dir> <traces dir>: every rig, JOBS at a time; each trace to <traces>/<rig>.txt
    mkdir -p "$2"; vs_pool_start "$JOBS"
    for _j in "$1"/tr_*.json; do vs_pool_run run_one "$1" "$(basename "$_j" .json)" "$2"; done
    vs_pool_wait
}
measure() {  # measure <family> <ticks source> <expected> <out dir> [gen options]: gen, run, rows, expect -> <out>/expect.txt
    _f="$1"; _src="$2"; _e="$3"; _d="$4"; shift 4
    TR_FAMILY="$_f" python3 "$TOOL" gen "$_src" "$_d/rigs" "$@" > /dev/null || { echo "gen failed" > "$_d/expect.txt"; return 2; }
    run_rigs "$_d/rigs" "$_d/traces"
    TR_FAMILY="$_f" python3 "$TOOL" rows "$_d/rigs" "$_d/traces" > "$_d/rows.jsonl"
    TR_FAMILY="$_f" python3 "$TOOL" expect "$_d/rows.jsonl" "$_e" > "$_d/expect.txt" 2>&1
}

echo "== audit_throw_recovery: the vsavj ROM ($(python3 -c "import hashlib,sys;print(hashlib.sha1(open(sys.argv[1],'rb').read()).hexdigest()[:12])" "$ROMDIR/vsavj.zip")); tree $(git -C "$REPO" describe --always --dirty --abbrev=40 2>/dev/null || echo 'no git'); script blob $(git -C "$REPO" hash-object tests/audit_throw_recovery.sh 2>/dev/null || echo '?'); host $(hostname); JOBS=$JOBS; families: $FAMS${TR_VICTIM:+; victim $TR_VICTIM}${TR_HEIGHT:+; air height $TR_HEIGHT}"
ran=0; mode_fired=0; mode_ev=""
for FAM in $FAMS; do
    EXP="$(tr_py "$FAM" 't.exp_path()')"; FULL="$(tr_py "$FAM" 't.full_path()')"
    NEV="$(tr_py "$FAM" 'sum(1 for _ in t.events())')"; CTL_RIG="$(tr_py "$FAM" 'next(r for r, *_ in t.events() if r.startswith("FE_"))')"
    # the command family: one whiff tick per event (none for Pit of Blame), no k = 8 slot; its techable grabs are few
    K=4; NT="$NEV"; WI=14
    [ "$FAM" = command ] && { K=1; NT="$(tr_py "$FAM" 'sum(1 for r, tab, row, lab, ev in t.cmd_events() if not t.cmd_no_whiff(lab, tab))')"; WI=8
        NG="$(tr_py "$FAM" 'len(t.CMD_GATED)')"   # every Felicia command event is gated: the controls take the first whiffing one
        CTL_RIG="$(tr_py "$FAM" 'next(r for r, tab, row, lab, ev in t.cmd_events() if not t.cmd_no_whiff(lab, tab))')"
        GW_RIG="$(tr_py "$FAM" 'next(r for r, tab, row, lab, ev in t.cmd_events() if (tab, lab) in t.CMD_GATED)')"
        NE="$(tr_py "$FAM" 'sum(1 for r, tab, row, lab, ev in t.cmd_events() if (tab, lab) in t.CMD_ES_WHIFF)')"
        ES_RIG="$(tr_py "$FAM" 'next(r for r, tab, row, lab, ev in t.cmd_events() if (tab, lab) in t.CMD_ES_WHIFF)')"; }
    D="$W/$FAM"; mkdir -p "$D"
    echo "== $FAM 1. the frozen ticks (the full lines outside the tree, each against its in-tree hash)"
    SRC="$FULL"
    if [ -n "${FREEZE:-}" ]; then
        [ -f "${TR_TICKS:-}" ] || { echo "REFUSED: FREEZE needs TR_TICKS=<the measured ticks, rig input thr_thrown vic_thrown thr_tech vic_tech>"; exit 3; }
        SRC="$TR_TICKS"; echo "  NOTE  FREEZE: the ticks come from $TR_TICKS"
    elif [ ! -f "$FULL" ]; then
        echo "  SKIP  no full lines at $FULL (the per-move ticks are outside the tree by the frame-data ruling; this host has none)"
        continue
    elif TR_FAMILY="$FAM" python3 - "$FULL" "$EXP" > "$D/full.txt" 2>&1 <<'PY'
import sys
sys.path.insert(0, "tools"); import throw_recovery_rigs as t
full = [l.rstrip("\n") for l in open(sys.argv[1]) if l.strip() and not l.startswith("#")]
want = {l.rstrip("\n") for l in open(sys.argv[2]) if l.strip() and not l.startswith("#")}
got = {t.hashed(l) for l in full}
n_ev = sum(1 for _ in t.events())
print(f"{len(full)} full lines, {len(want)} frozen hashes, {n_ev} events in the rigs' row set")
bad = sorted(got ^ want)
for b in bad: print("MISMATCH", b)
sys.exit(1 if bad or len(full) != n_ev else 0)
PY
    then ok "$(head -1 "$D/full.txt"): every full line is the frozen one"
    else bad "the full lines are not the frozen ones:"; sed 's/^/        /' "$D/full.txt" | head -8; continue; fi
    ran=$((ran + 1))

    NR=$((NEV + NT))   # a teched and a thrown (or whiff) rig per event; Pit of Blame has no whiff rig
    echo "== $FAM 2. the rigs ($NR, made from the ticks; JOBS=$JOBS)"
    t0=$(date +%s); mkdir -p "$D/m"
    G=""; vs_ctl_is tick-early && G="--shift -1"; vs_ctl_is lp-tech && G="--tech-token 1"; vs_ctl_is late-window && G="--late-tech 7"; vs_ctl_is gated-whiff && G="--gated-whiff"; vs_ctl_is whiff-at-contact && G="--whiff-contact"
    vs_ctl_is es-exemption-dropped && export TR_CTL_ES_DROPPED=1   # the clause judges the ES grabs as every other whiff
    # shellcheck disable=SC2086
    measure "$FAM" "$SRC" "$EXP" "$D/m" $G; _rc=$?
    _nt=$(ls "$D/m/traces"/*.txt 2>/dev/null | wc -l | tr -d ' ')
    _dead=$(grep -L '^rc=0$' "$D/m/traces"/*.d/run.log 2>/dev/null | wc -l | tr -d ' ')
    [ "$_nt" = "$NR" ] && [ "$_dead" = 0 ] && ok "$_nt rigs ran clean in $(( $(date +%s) - t0 )) s" \
        || bad "$_nt of $NR traces, $_dead run(s) not rc=0"

    echo "== $FAM 3. every event against its clauses and its frozen line"
    if [ -n "${FREEZE:-}" ]; then
        if TR_FAMILY="$FAM" python3 "$TOOL" freeze "$D/m/rows.jsonl" "$EXP" > "$D/freeze.txt" 2>&1; then ok "$(tail -1 "$D/freeze.txt")"
        else bad "nothing frozen:"; sed 's/^/        /' "$D/freeze.txt" | head -12; fi
        continue
    fi
    if [ "$_rc" = 0 ]; then ok "$(tail -1 "$D/m/expect.txt")"
    else bad "$(tail -1 "$D/m/expect.txt")"; grep '^BAD' "$D/m/expect.txt" | head -12 | sed 's/^/        /'; fi

    _tch="$(awk -F'\t' -v i="$WI" '!/^#/ && $i == "1-7"' "$FULL" | wc -l | tr -d ' ')"
    if [ -n "$MODE" ]; then   # THE MODE: judged per family; exit 1 below only if ITS clause failed in every family run
        if [ "$MODE" = late-window ] && [ "$FAM" = command ]; then ran=$((ran - 1)); mode_ev="$mode_ev $FAM: no k = 8 slot (not applicable);"; continue; fi
        if { [ "$MODE" = gated-whiff ] || [ "$MODE" = es-exemption-dropped ] || [ "$MODE" = whiff-at-contact ]; } && [ "$FAM" != command ]; then ran=$((ran - 1)); mode_ev="$mode_ev $FAM: no command grabs (not applicable);"; continue; fi
        _want="$NT"; [ "$MODE" != tick-early ] && _want="$_tch"; [ "$MODE" = gated-whiff ] && _want="$NG"; [ "$MODE" = es-exemption-dropped ] && _want="$NE"; [ "$MODE" = whiff-at-contact ] && _want="$NT"
        if _ev="$(ctl_judge "$MODE" "$D/m/expect.txt" "$_want" "$K")"; then mode_fired=$((mode_fired + 1)); fi
        mode_ev="$mode_ev $FAM: $_ev;"
        continue
    fi

    # the controls' rig: Felicia's first event; lp-tech's the family's first TECHABLE one (frozen window 1-7)
    TCH_RIG="$(awk -F'\t' -v i="$WI" '!/^#/ && $i == "1-7" {print $1 "\t" $2 "\t" $3; exit}' "$FULL")"
    TCH_RIG="$(TR_FAMILY="$FAM" python3 -c "
import sys; sys.path.insert(0, 'tools'); import throw_recovery_rigs as t
k = sys.argv[1].split('\t')
print(next((r for r, tab, key, inp, *_ in t.events() if (tab, key if '$FAM' != 'command' else r, inp) == tuple(k)), ''))" "$TCH_RIG")"
    echo "== $FAM 4. controls ($CTL_RIG; lp-tech on ${TCH_RIG:-none}, each perturbed)"
    for c in "tick-early:--shift -1" "lp-tech:--tech-token 1" "late-window:--late-tech 7" "gated-whiff:--gated-whiff" "es-exemption-dropped:" "whiff-at-contact:--whiff-contact"; do
        _c="${c%%:*}"; [ "$FAM" = command ] && [ "$_c" = late-window ] && continue
        [ "$FAM" != command ] && { [ "$_c" = gated-whiff ] || [ "$_c" = es-exemption-dropped ] || [ "$_c" = whiff-at-contact ]; } && continue
        _r="$CTL_RIG"; [ "$_c" = lp-tech ] && _r="$TCH_RIG"; [ "$_c" = gated-whiff ] && _r="$GW_RIG"; [ "$_c" = es-exemption-dropped ] && _r="$ES_RIG"
        mkdir -p "$D/c_$_c"
        # shellcheck disable=SC2086
        if [ "$_c" = es-exemption-dropped ]; then ( export TR_CTL_ES_DROPPED=1; measure "$FAM" "$SRC" "$EXP" "$D/c_$_c" --only "$_r" )
        else measure "$FAM" "$SRC" "$EXP" "$D/c_$_c" --only "$_r" ${c#*:}; fi
        if _ev="$(ctl_judge "$_c" "$D/c_$_c/expect.txt" 1 "$K")"; then vs_ctl_fired "$_c" "$FAM: $_ev"
        else vs_ctl_dead "$_c" "$FAM: $_ev"; fail=1; fi
    done
done

if [ -n "$MODE" ]; then
    if [ "$ran" -gt 0 ] && [ "$mode_fired" = "$ran" ]; then vs_ctl_fired "$MODE" "${mode_ev# } (mode)"; echo "FAIL"; exit 1; fi
    echo "REFUSED: mode $MODE — its perturbation did not make its own clause fail in every family run (${mode_ev# }): a dead mode, not a verdict"
    exit 3
fi
[ "$ran" -gt 0 ] || { echo "SKIP: no family had its full lines (nothing measured)"; exit 0; }
[ "$fail" -eq 0 ] && echo "PASS${FREEZE:+ (frozen)}" || echo "FAIL"
exit "$fail"
