#!/bin/sh
# test_crash_sweep.sh — EVERY CALL OF vs_ctl_show_err IS PROVEN BY A PLANTED CRASH (#310, 14z-218). Freeze cadence.
#
# WHAT: tests/lib/controls.sh `vs_ctl_show_err` re-prints a perturbed copy's crash so a control MODE reads DIED or
#   UNJUDGED, never HONOURED (#310 group 5). This gate proves each CALL of it in every gate that makes one: for every call
#   site (tools/crash_sweep.py's key, `<first argument>#<k>`) a row of tests/expected/crash_sweep.tsv plants a crash in
#   one call the gate's run makes, and the run must read not-honoured on the gate as it stands while the same plant, with
#   the helper neutered, reads HONOURED — so the row reaches THAT call and the call is what surfaces the crash. Rows with
#   site `-` are regression rows for crashes a gate surfaces by its own code (14z-218's F-findings).
# HOW: (1) `python3 tools/crash_sweep.py check` on the table: every caller's every site covered by a row, or its gate on
#   an `# EXEMPT:` line; every row well-formed (a declared mode, a live site key). (2) For each row of the selected tier
#   (static by default; `--tier emulator`: the rows whose target gate needs an emulator, and on a Linux host with
#   podman the `linux` rows (audit_release_linux_cleanhost) — tests/audit_crash_sweep_emu.sh runs it), two copies of the target gate, each `<gate>.sh` in its own
#   directory under the sweep's scratch directory and never in tests/, its REPO pinned to this repository (#362: a gate
#   walking tests/ beside the sweep read a transient copy there) (each call wrapped by its site tag; the second with the
#   helper neutered), each run under tests/lib/crash_sweep.sh's PATH shim that turns
#   the row's nth matching python3/sh call into a crash; the run classified with tests/lib/classify.sh exactly as both
#   runners classify (vs_classify_control for a mode, vs_classify for PLAIN). Copies are re-made for every run.
# EXPECTS: (1) 0 problems; (2) per row: the fx leg's class is the row's (DIED|UNJUDGED for a mode, FAIL for PLAIN), the
#   plant applied (a planted call counted) and, for a site row, its site key fired; the kb leg reads the row's kb
#   (HONOURED / PASS). A red names the row and both legs' classes and logs. A row of another tier is listed as
#   NOT RUN; on a host without podman the linux rows are NOT RUN too.
# FOLLOWS: tools/crash_sweep.py tests/lib/crash_sweep.sh tests/lib/controls.sh tests/lib/classify.sh
#   tests/expected/crash_sweep.tsv
#
# MUST-FIRE: known-bad: helper-neutered — every site row's kb leg runs the target gate with vs_ctl_show_err neutered and must read HONOURED (PASS for a PLAIN row): the plant really is a crash the gate would otherwise read as its control firing, so the fx leg's not-honoured is the helper's doing (in-gate; mode: the fx legs run the neutered copy, so they read HONOURED and the gate FAILs)
# MUST-FIRE: perturbed-copy: row-dropped — a copy of the table without its first site row must leave that site UNCOVERED in tools/crash_sweep.py check (in-gate; mode: the check reads that copy, so the gate FAILs)
# MUST-FIRE: shadow-tool: shim-inert — a copy of tests/lib/crash_sweep.sh whose shims never plant must make the first static row's fx leg read HONOURED with no planted call (in-gate; mode: every row runs that copy, so the gate FAILs)
#
# WHY: #310 (14z-215, the maintainer: "Next session, first batch (Recommended)"): ~20 group-5 gates had no planted proof
#   of their own, and a miswired call or refusal line would let a crash read HONOURED in its perturbed copy. 14z-216's
#   discovery (build/agent216/t310/FINDINGS.md) and 14z-218's per-call pass found the rows this table freezes.
# SHARES: none — its 3 control modes were write-traced apart (tests/controls_concurrent.txt, pilot:413e9b92) and its plain run always pooled (#370 A1, 14z-225)
set -u
REPO="$(cd "$(dirname "$0")/.." && pwd -P)"; cd "$REPO"
. "$REPO/tests/lib/controls.sh"; vs_ctl_mode "$0"
. "$REPO/tests/lib/classify.sh"
TIER=static
case "${1:-}" in --tier) TIER="${2:-}"; shift 2 ;; "") ;; *) echo "usage: $0 [--tier static|emulator]"; exit 2 ;; esac
case "$TIER" in static|emulator) ;; *) echo "REFUSED: tier $TIER (static|emulator)"; exit 3 ;; esac
T="$REPO/tests/expected/crash_sweep.tsv"
W="$(mktemp -d)" || { echo "FAIL: test_crash_sweep — mktemp -d failed"; exit 2; }
case "$(cd "$W" && pwd -P)/" in "$REPO"/tests/*) echo "REFUSED: the scratch directory $W is inside tests/ — the copies must live outside it (#362)"; exit 3 ;; esac
trap 'rm -rf "$W"' EXIT
trap 'exit 143' INT TERM   # a TERM must END the run (the EXIT trap then cleans up): a trap on TERM alone returns to the script
fail=0; ok() { echo "  ok    $*"; }; bad() { echo "  FAIL  $*"; fail=1; }
CS_PY="$(command -v python3)"; CS_REPO="$REPO"; export CS_PY CS_REPO

LIB="$REPO/tests/lib/crash_sweep.sh"
shim_inert_copy() {  # a copy of the library whose shims never plant (CS-PLANT lines disabled); returns 1 if they moved
    python3 - "$REPO/tests/lib/crash_sweep.sh" "$1" <<'PY' || return 1
import sys
s = open(sys.argv[1]).read(); k = 'if [ "$n" = "$CS_NTH" ]; then'; k2 = 'if str(n) != os.environ.get("CS_NTH"):'
if s.count(k) != 2 or s.count(k2) != 1: sys.exit("shim-inert: the plant tests matched %d/%d times (need 2/1)" % (s.count(k), s.count(k2)))
open(sys.argv[2], "w").write(s.replace(k, 'if false; then').replace(k2, 'if True:'))
PY
}
if [ "$VS_CTL" = shim-inert ]; then
    shim_inert_copy "$W/lib_inert.sh" || { echo "REFUSED: CONTROL=shim-inert — its line moved"; exit 3; }
    LIB="$W/lib_inert.sh"
fi
. "$LIB"
cs_mkshim "$W/shim"

# --- (1) the table is complete and well-formed
TBL="$T"
if [ "$VS_CTL" = row-dropped ]; then
    awk -F'\t' 'BEGIN{d=0} !/^#/ && NF>=10 && $1!="gate" && $7!="-" && !d {d=1; next} {print}' "$T" > "$W/dropped.tsv"; TBL="$W/dropped.tsv"
fi
if python3 tools/crash_sweep.py check "$TBL" > "$W/check.out" 2>&1; then ok "$(tail -1 "$W/check.out")"
else sed 's/^/  /' "$W/check.out"; bad "tools/crash_sweep.py check"; fi
# the in-gate row-dropped control
awk -F'\t' 'BEGIN{d=0} !/^#/ && NF>=10 && $1!="gate" && $7!="-" && !d {d=1; print $1 " " $7 > "/dev/stderr"; next} {print}' "$T" > "$W/drop_ctl.tsv" 2> "$W/drop_ctl.which"
if python3 tools/crash_sweep.py check "$W/drop_ctl.tsv" 2>&1 | grep -qF "UNCOVERED $(cat "$W/drop_ctl.which"):"; then
    vs_ctl_fired row-dropped "the table without its first site row leaves $(cat "$W/drop_ctl.which") UNCOVERED"
else vs_ctl_dead row-dropped "dropping the first site row ($(cat "$W/drop_ctl.which")) left check silent"; fi

if [ "$VS_CTL" = row-dropped ]; then   # the mode judges the check alone: the rows are not what it perturbs
    [ "$fail" = 1 ] && { echo "FAIL: test_crash_sweep (CONTROL=row-dropped: the check)"; exit 1; }
    echo "NOT JUDGED: CONTROL=row-dropped — the table without its first site row passed the check"; exit 1
fi

# --- (2) the rows
podman_ok=0; command -v podman > /dev/null 2>&1 && [ "$(uname -s)" = Linux ] && podman_ok=1
nrun=0; nkb=0; nkbok=0; nskip=0; i=0
grep -v '^#' "$T" | awk -F'\t' 'NF>=10 && $1!="gate"' > "$W/rows.tsv"
while IFS="$(printf '\t')" read -r G TR M K RE NTH SITE FX KB NOTE; do
    i=$((i + 1))
    want_tier="$TR"; [ "$TR" = linux ] && want_tier=emulator   # the linux rows ride the emulator tier, on a podman host
    if [ "$want_tier" != "$TIER" ] || { [ "$TR" = linux ] && [ "$podman_ok" = 0 ]; }; then nskip=$((nskip + 1)); continue; fi
    nrun=$((nrun + 1)); tag="row $i ($G $M $K nth $NTH${SITE:+ site $SITE})"
    legs="fx"; [ "$KB" != - ] && legs="fx kb"
    for leg in $legs; do
        mkdir -p "$W/c$i.$leg"; c="$W/c$i.$leg/$G.sh"   # outside tests/ (#362), named as the gate
        neut=""; [ "$leg" = kb ] && neut="--neuter"
        [ "$leg" = fx ] && [ "$VS_CTL" = helper-neutered ] && neut="--neuter"
        python3 tools/crash_sweep.py copy "tests/$G.sh" "$c" $neut > "$W/copy.out" 2>&1 || { bad "$tag: cannot copy the gate ($(head -1 "$W/copy.out"))"; continue; }
        cs_run "$c" "$M" "$K" "$RE" "$NTH" "$W/shim" "$W/r$i.$leg"
        rm -rf "$W/c$i.$leg"
        got="$CS_CLASS h$CS_HITS [$CS_SITES] ${CS_SECS}s"
        if [ "$leg" = fx ]; then
            want_ok=0
            case "$FX" in
                FAIL) [ "$CS_CLASS" = FAIL ] && want_ok=1 ;;
                DIED|UNJUDGED) [ "$CS_CLASS" = "$FX" ] && want_ok=1 ;;
                "DIED|UNJUDGED") { [ "$CS_CLASS" = DIED ] || [ "$CS_CLASS" = UNJUDGED ]; } && want_ok=1 ;;
            esac
            [ "$CS_HITS" -ge 1 ] || want_ok=0
            if [ "$SITE" != - ]; then case ",$CS_SITES," in *",$SITE,"*) ;; *) want_ok=0 ;; esac; fi
            if [ "$want_ok" = 1 ]; then ok "$tag fx: $got"
            else bad "$tag fx: want $FX, the plant applied${SITE:+ and $SITE fired}; got $got — log:"; tail -5 "$W/r$i.fx.log" | sed 's/^/        /'; fi
        else
            nkb=$((nkb + 1))
            if [ "$CS_CLASS" = "$KB" ] && [ "$CS_HITS" -ge 1 ]; then nkbok=$((nkbok + 1)); ok "$tag kb: $got"
            else bad "$tag kb: want $KB with the plant applied; got $got"; fi
        fi
    done
done < "$W/rows.tsv"
echo "  rows: $nrun run (tier $TIER), $nskip NOT RUN (another tier, or no podman for linux)"
if [ "$nkb" -gt 0 ] && [ "$nkb" = "$nkbok" ]; then vs_ctl_fired helper-neutered "$nkbok of $nkb site rows with a known-bad leg read HONOURED (PASS for PLAIN) with the helper neutered"
elif [ "$nkb" = 0 ]; then vs_ctl_dead helper-neutered "no site row ran a known-bad leg in tier $TIER"
else vs_ctl_dead helper-neutered "$((nkb - nkbok)) of $nkb known-bad legs did not read honoured"; fi

# the in-gate shim-inert control: the first row of this tier, its fx leg on a never-planting library copy
if [ "$VS_CTL" != shim-inert ] && [ "$nrun" -gt 0 ] && shim_inert_copy "$W/lib_inert_ctl.sh"; then
    first="$(awk -F'\t' -v t="$TIER" '$2==t' "$W/rows.tsv" | head -1)"
    G="$(printf '%s' "$first" | cut -f1)"; M="$(printf '%s' "$first" | cut -f3)"; K="$(printf '%s' "$first" | cut -f4)"
    RE="$(printf '%s' "$first" | cut -f5)"; NTH="$(printf '%s' "$first" | cut -f6)"
    mkdir -p "$W/c_inert"; c="$W/c_inert/$G.sh"   # outside tests/ (#362)
    python3 tools/crash_sweep.py copy "tests/$G.sh" "$c" > /dev/null 2>&1
    ( . "$W/lib_inert_ctl.sh"; cs_mkshim "$W/shim_inert"; cs_run "$c" "$M" "$K" "$RE" "$NTH" "$W/shim_inert" "$W/inert"
      echo "$CS_CLASS $CS_HITS" > "$W/inert.res" )
    rm -rf "$W/c_inert"
    case "$(cat "$W/inert.res" 2>/dev/null)" in
        "HONOURED 0"|"PASS 0") vs_ctl_fired shim-inert "$G $M with a never-planting shim reads $(cut -d' ' -f1 "$W/inert.res"), no planted call" ;;
        *) vs_ctl_dead shim-inert "$G $M with a never-planting shim read $(cat "$W/inert.res" 2>/dev/null)" ;;
    esac
elif [ "$VS_CTL" != shim-inert ]; then vs_ctl_dead shim-inert "no row of tier $TIER to run it on"; fi

[ "$fail" = 0 ] && { echo "PASS: test_crash_sweep (tier $TIER)"; exit 0; }
echo "FAIL: test_crash_sweep (tier $TIER)"; exit 1
