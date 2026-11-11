#!/bin/sh
# test_instr_align_unjudged.sh — A DRIFT-FAMILY MODE RUN THAT MEASURED NOTHING, OR TESTED NOTHING, IS NOT HONOURED (#310 group 1, 14z-215). ci_portable: no ROM, ~2 s.
#
# WHAT: the instrument-alignment library's two controls, drift-clock and first-frame-skip, are modes of 30 emulator
#   gates (tests/lib/instr_align.sh). Under either mode (i) an instrument leg with no ALIGN line (ia_check), a staging
#   leg or replay.lua yardstick that read nothing, or a manifest with no staging run (ia_stage) prints `NOT JUDGED:`
#   at column 0, which tests/lib/classify.sh reads UNJUDGED; and (ii) a mode run that reaches the gate's green end
#   prints `CONTROL DEAD: <mode>` through tests/lib/controls.sh `vs_ctl_left_green`, which classify.sh's rule 1 reads
#   LIES. Outside a mode neither line is printed, and a real catch (a breakpoint run off its frozen game clock, a
#   staging leg reading another checksum) still reads HONOURED; a control's own leg inside ia_stage (its drift leg,
#   IA_NJ=0) prints no marker.
# HOW: a stub gate written into a scratch directory sources tests/lib/controls.sh and tests/lib/instr_align.sh (or a
#   control's copy with one new line disabled), replaces the MAME legs `_ia_leg` / `_ia_rl` by stubs that write a
#   chosen ALIGN line, anchor or checksum (or nothing), and ends in the drift family's close block; each case runs it
#   under CONTROL=<mode> (or none) and classifies its log with vs_classify_control exactly as both runners do.
# EXPECTS: every case its class (UNJUDGED, LIES, HONOURED) or its marker-free log; each control's disabled line
#   misreads its case.
# FOLLOWS: tests/lib/classify.sh tests/lib/controls.sh tests/lib/instr_align.sh
#
# MUST-FIRE: shadow-tool: nj-check-honoured — a copy of tests/lib/instr_align.sh whose ia_check NOT JUDGED line is disabled must let a drift-clock run with no ALIGN line read HONOURED, and the gate must FAIL (mode: the cases run on that copy)
# MUST-FIRE: shadow-tool: nj-stage-honoured — a copy whose ia_stage NOT JUDGED line (a leg that read nothing) is disabled must let a first-frame-skip run whose staging leg wrote no anchor read HONOURED, and the gate must FAIL (mode: as above)
# MUST-FIRE: shadow-tool: nj-manifest-honoured — a copy whose ia_stage no-staging-run NOT JUDGED line is disabled must let a first-frame-skip run over an empty manifest read HONOURED, and the gate must FAIL (mode: as above)
# MUST-FIRE: shadow-tool: nj-silencer-dropped — a copy whose `IA_NJ=0` around ia_stage's own drift leg is removed must print NOT JUDGED for a control's own dead leg under another mode, and the gate must FAIL (mode: as above)
# MUST-FIRE: shadow-tool: dead-close-honoured — a copy of tests/lib/controls.sh whose vs_ctl_left_green DEAD line is disabled must let a drift-clock run that stays green read HONOURED, and the gate must FAIL (mode: the cases run on that copy)
#
# WHY: #310 (the 14z-210 census, REMAINING section 1 shapes 1 and 6): 28 gates closed a green mode with "control mode X
#   left the gate green" in WORDS and exit 1 (56 controls read HONOURED with nothing tested), and a stalled MAME leg
#   under either mode failed the alignment check and read as the control firing. Ruled 2026-10-31 (maintainer, "Groups
#   1-4, then re-census 5-7"): each group proven by a planted case that must read UNJUDGED, LIES or DIED.
# SHARES: none — its 5 control modes were write-traced apart (tests/controls_concurrent.txt, pilot:17f4f67f) and its plain run always pooled (#370 A1, 14z-225)
set -u
REPO="$(cd "$(dirname "$0")/.." && pwd)"; cd "$REPO"
. "$REPO/tests/lib/controls.sh"; vs_ctl_mode "$0"
W="$(mktemp -d)" || { echo "FAIL: test_instr_align_unjudged — mktemp -d failed (W)"; exit 2; }; trap 'rm -rf "$W"' EXIT; trap 'exit 130' INT; trap 'exit 143' TERM
fail=0; ok() { echo "  ok    $*"; }; bad() { echo "  FAIL  $*" | tee -a "$W/main.log"; fail=1; }   # #369: the cases' findings

IAL="$REPO/tests/lib/instr_align.sh"; CTLS="$REPO/tests/lib/controls.sh"; CLS="$REPO/tests/lib/classify.sh"
shadow() {  # shadow <src> <marker> <sed expression> <out>: <src> with <sed expression> applied on <marker>'s line
    sed "/$2/$3" "$1" > "$4"
    cmp -s "$1" "$4" && { echo "FAIL: test_instr_align_unjudged — could not disable '$2' (the line moved)"; exit 1; }
    return 0
}
shadow_for() {  # shadow_for <control> <dir>: sets IAL/CTLS to that control's copies under <dir>
    mkdir -p "$2"; _i="$REPO/tests/lib/instr_align.sh"; _c="$REPO/tests/lib/controls.sh"
    case "$1" in
    nj-check-honoured)    shadow "$_i" '# #310 NJ-check' 's/_ia_nj "[^"]*"/:/' "$2/ia.sh"; _i="$2/ia.sh" ;;
    nj-stage-honoured)    shadow "$_i" '# #310 NJ-stage' 's/_ia_nj "[^"]*"/:/' "$2/ia.sh"; _i="$2/ia.sh" ;;
    nj-manifest-honoured) shadow "$_i" '# #310 NJ-manifest' 's/_ia_nj "[^"]*"/:/' "$2/ia.sh"; _i="$2/ia.sh" ;;
    nj-silencer-dropped)  shadow "$_i" "a control's own leg (#310)" 's/IA_NJ=0; //' "$2/ia.sh"; _i="$2/ia.sh" ;;
    dead-close-honoured)  shadow "$_c" '# #310 DEAD-close' 's/echo "CONTROL DEAD: [^"]*"/:/' "$2/ctl.sh"; _c="$2/ctl.sh" ;;
    esac
    IAL="$_i"; CTLS="$_c"
}
[ -n "${VS_CTL:-}" ] && shadow_for "$VS_CTL" "$W/mode"

# THE STUB GATE: the drift family's shape — the manifest check, the staging leg, the close block — with the MAME legs
# stubbed. STUB_CASE check|stage|green; per leg dir (stage, cdrift, cskip, one) STUB_<DIR>=none|<gameclock>:<anchor>;
# STUB_RL=none|<checksum>; STUB_EMPTY=1 for an empty manifest.
cat > "$W/g_drift.sh" <<'EOF'
#!/bin/sh
# g_drift.sh — a stub drift-family gate (tests/test_instr_align_unjudged.sh)
# MUST-FIRE: known-bad: drift-clock — stub
# MUST-FIRE: known-bad: first-frame-skip — stub
# MUST-FIRE: known-bad: other-mode — stub
set -u
. "$CTLS"; vs_ctl_mode "$0"; MODE="${VS_CTL:-}"
. "$IAL"
_ia_leg() {  # the instrument leg: STUB_<basename of dir> = none | <gameclock>:<anchor>
    mkdir -p "$7"; _v="$(eval "printf '%s' \"\${STUB_$(basename "$7" | tr a-z A-Z):-none}\"")"
    [ "$_v" = none ] || printf 'ALIGN g - frames %s emulated %s uiframes 7 gameclock %s anchor %s %s\n' "$5" "$5" "${_v%%:*}" "$5" "${_v#*:}" > "$7/align"
}
_ia_rl() { mkdir -p "$5"; [ "$STUB_RL" = none ] || printf '100 %s\n' "$STUB_RL" > "$5/cks.log"; }
T="$SW/clocks.tsv"; printf 'leg\tr\t100\t41\n' > "$T"
M="$SW/manifest.tsv"; : > "$M"
[ "${STUB_EMPTY:-0}" = 1 ] || printf 'leg\tr\tvsavj\t-\tr.rpl\t100\t-\t%s\n' "$SW/one/align" >> "$M"
mkdir -p "$SW/one"; _ia_leg x x x x 100 - "$SW/one" 1
fail=0
case "$STUB_CASE" in
check) if ia_check_manifest "$T" "$M" > "$SW/align_bad.txt"; then echo "  ok    on the frozen game clock"
       else echo "  FAIL  off the frozen alignment:"; sed 's/^/        /' "$SW/align_bad.txt"; fail=1; fi ;;
stage) ia_stage g_drift "$T" stub.lua "$M" 1 "$SW/st" "$MODE" || fail=1 ;;
green) echo "  ok    every clause green" ;;
esac
if [ "$MODE" = drift-clock ] || [ "$MODE" = first-frame-skip ]; then
    [ "$fail" = 1 ] && { echo "FAIL: g_drift (control mode: $MODE)"; exit 1; }
    vs_ctl_left_green "$MODE" "FAIL: g_drift — control mode $MODE left the gate green"
fi
[ "$fail" = 0 ] && echo "PASS: g_drift" || echo "FAIL: g_drift"; exit "$fail"
EOF
chmod +x "$W/g_drift.sh"
_n=0
# #369 (14z-224): the stubs stand for gates on the shrink-only debt list tests/expected/ctl_caught_debt.tsv, the
# pre-#369 fall-through these cases were written for; a scratch copy of the list naming them reaches the stub run and
# the classifier through REPO (the tracked list is never written). tests/test_control_classifier.sh holds the strict path.
mkdir -p "$W/debt/tests/expected"; { cat "$REPO/tests/expected/ctl_caught_debt.tsv"; echo g_drift.sh; } > "$W/debt/tests/expected/ctl_caught_debt.tsv"
run_stub() {  # run_stub <mode or -> <env words...>: runs the stub gate; sets LOG, ST, CLASS
    _n=$((_n + 1)); _m="$1"; shift; [ "$_m" = - ] && _m=""
    SW="$W/s$_n"; mkdir -p "$SW"; LOG="$SW.log"
    env CONTROL="$_m" CTLS="$CTLS" IAL="$IAL" SW="$SW" STUB_RL=none STUB_ONE=none STUB_STAGE=none STUB_CDRIFT=none \
        STUB_CSKIP=none REPO="$W/debt" "$@" sh "$W/g_drift.sh" > "$LOG" 2>&1 </dev/null && ST=0 || ST=$?
    CLASS="$(REPO="$W/debt" sh -c '. "$1"; vs_classify_control "$2" "$3" "$4" "$5"; echo "$VS_CTL_EXEC"' _ "$CLS" "$ST" "$LOG" "$W/g_drift.sh" "$_m")"
}
expect() {  # expect <label> <class> <mode> <env words...>
    _l="$1"; _c="$2"; shift 2; run_stub "$@"
    [ "$CLASS" = "$_c" ] && ok "$_l -> $_c" || bad "$_l -> $CLASS (exit $ST), expected $_c: $(command grep -a -m1 'NOT JUDGED\|CONTROL DEAD\|FAIL' "$LOG" | cut -c1-100)"
}
nomarker() {  # nomarker <label> <mode> <env words...>: the run's log carries no NOT JUDGED line
    _l="$1"; shift; run_stub "$@"
    if command grep -qa '^NOT JUDGED: ' "$LOG"; then bad "$_l printed $(command grep -a -m1 '^NOT JUDGED: ' "$LOG" | cut -c1-90)"
    else ok "$_l: no NOT JUDGED line (exit $ST)"; fi
}

cases() {
    echo "== ia_check: an instrument leg with no ALIGN line"
    expect "drift-clock, the breakpoint run wrote no ALIGN line"           UNJUDGED drift-clock STUB_CASE=check
    expect "  near miss: drift-clock, a run off its frozen game clock"      HONOURED drift-clock STUB_CASE=check STUB_ONE=3e:aa
    nomarker "  outside a mode, the same dead leg"                          -           STUB_CASE=check
    echo "== ia_stage: a staging leg or yardstick that read nothing"
    expect "first-frame-skip, the staging leg wrote no anchor"              UNJUDGED first-frame-skip STUB_CASE=stage STUB_RL=bb
    expect "first-frame-skip, replay.lua read nothing"                      UNJUDGED first-frame-skip STUB_CASE=stage STUB_STAGE=41:cc
    expect "first-frame-skip, the manifest holds no staging run"            UNJUDGED first-frame-skip STUB_CASE=stage STUB_EMPTY=1 STUB_RL=bb
    expect "  near miss: first-frame-skip, the staging leg reads another checksum" HONOURED first-frame-skip STUB_CASE=stage STUB_STAGE=41:cc STUB_RL=bb
    nomarker "  another mode: ia_stage's own drift leg dead (IA_NJ=0)"     other-mode  STUB_CASE=stage STUB_STAGE=41:bb STUB_RL=bb STUB_CSKIP=41:cc
    echo "== the close block: a mode run that stays green"
    expect "drift-clock left the gate green"                                LIES drift-clock STUB_CASE=green
    expect "first-frame-skip left the gate green"                           LIES first-frame-skip STUB_CASE=green
}
cases

if [ -n "${VS_CTL:-}" ]; then
    case "$VS_CTL" in   # #369: the case each disabled line must misread, named by the cases' own FAIL row
    nj-check-honoured)    WANT="FAIL  drift-clock, the breakpoint run wrote no ALIGN line -> HONOURED \(exit" ;;
    nj-stage-honoured)    WANT="FAIL  first-frame-skip, the staging leg wrote no anchor -> HONOURED \(exit" ;;
    nj-manifest-honoured) WANT="FAIL  first-frame-skip, the manifest holds no staging run -> HONOURED \(exit" ;;
    nj-silencer-dropped)  WANT="FAIL    another mode: ia_stage's own drift leg dead \(IA_NJ=0\) printed NOT JUDGED: under control mode other-mode, " ;;
    dead-close-honoured)  WANT="FAIL  drift-clock left the gate green -> HONOURED \(exit" ;;
    esac
    [ "$fail" = 0 ] || vs_ctl_caught "$W/main.log" "$WANT"
    [ "$fail" = 0 ] && echo "PASS: test_instr_align_unjudged" || echo "FAIL: test_instr_align_unjudged (control mode $VS_CTL)"; exit "$fail"
fi
echo "== controls: each new line disabled must misread its case"
fire() {  # fire <control> <label> <expected misread: class|MARKER> <mode> <env words...>
    _ctl="$1"; _lab="$2"; _want="$3"; shift 3
    shadow_for "$_ctl" "$W/c_$_ctl"; run_stub "$@"; IAL="$REPO/tests/lib/instr_align.sh"; CTLS="$REPO/tests/lib/controls.sh"
    if [ "$_want" = MARKER ]; then
        command grep -qa '^NOT JUDGED: ' "$LOG" && vs_ctl_fired "$_ctl" "with the silencer removed $_lab prints NOT JUDGED" \
            || { vs_ctl_dead "$_ctl" "$_lab printed no NOT JUDGED line with the silencer removed"; fail=1; }
    elif [ "$CLASS" = "$_want" ]; then vs_ctl_fired "$_ctl" "with the line disabled $_lab reads $CLASS"
    else vs_ctl_dead "$_ctl" "$_lab read '$CLASS' with the line disabled"; fail=1; fi
}
fire nj-check-honoured    "a drift-clock run with no ALIGN line"      HONOURED drift-clock STUB_CASE=check
fire nj-stage-honoured    "a first-frame-skip run with no staging anchor" HONOURED first-frame-skip STUB_CASE=stage STUB_RL=bb
fire nj-manifest-honoured "a first-frame-skip run over an empty manifest" HONOURED first-frame-skip STUB_CASE=stage STUB_EMPTY=1 STUB_RL=bb
fire nj-silencer-dropped  "ia_stage's own dead drift leg under another mode" MARKER other-mode STUB_CASE=stage STUB_STAGE=41:bb STUB_RL=bb STUB_CSKIP=41:cc
fire dead-close-honoured  "a drift-clock run that stays green"        HONOURED drift-clock STUB_CASE=green

[ "$fail" = 0 ] && echo "PASS: test_instr_align_unjudged — a dead leg reads UNJUDGED and a green mode LIES under both drift-family modes; real catches stay HONOURED" || echo "FAIL: test_instr_align_unjudged"
exit "$fail"
