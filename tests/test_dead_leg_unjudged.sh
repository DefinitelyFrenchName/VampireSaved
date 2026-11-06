#!/bin/sh
# test_dead_leg_unjudged.sh — A DEAD EMULATOR LEG IS NOT THE CONTROL FIRING (#310 group 7, 14z-221). Needs ROMDIR (the gates' own ROM checks), runs no emulator: ~1 min.
#
# WHAT: tests/lib/controls.sh `vs_ctl_nj <why>`, which a gate calls beside each liveness check (an emulator that exited
#   non-zero, a trace with no END line, no samples, a reducer's VOID about a leg that never ran): under a CONTROL= mode it
#   prints `NOT JUDGED: under control mode <mode>, <why>` and tests/lib/classify.sh reads the run UNJUDGED; in a plain run
#   it prints nothing. Before it, those gates' modes ended a dead leg in their ordinary FAIL and read HONOURED: a control
#   certified on no measurement.
# HOW: (1) the helper on its own, in a subshell, with and without a mode. (2) For each row of
#   tests/expected/dead_leg_unjudged.tsv (gate, mode, class, stripped class, dead instrument), the gate's mode is run with
#   MAME_BIN=/usr/bin/false and the row's dead instrument (MAME_BIN, or FBNEO_BIN for an FBNeo leg: test_dualtrack, #310
#   group 7 batch 2, 14z-221c) set to /usr/bin/false, so every
#   leg dies at once, and its log is classified with vs_classify_control exactly as both runners do; the gate's PLAIN run
#   under the same dead emulator must exit non-zero and print no `NOT JUDGED:` line (a dead emulator never passes a plain
#   run, and the helper is silent there). A row whose dead instrument is not MAME_BIN runs its mode once more with ONLY
#   that instrument dead and MAME_BIN unset, and must read the same class: the class comes from the
#   instrument the row names, not from the dead MAME every other run carries (14z-221c, rule-checker run -1665). (3) The in-gate control: each row's gate copied with its `# #310 g7 NJ` lines
#   NEUTERED (vs_ctl_nj made `:`, a printed `NOT JUDGED:` renamed; never deleted, since a tagged line may carry the
#   gate's own command; its REPO line pinned to this repository, the crash sweep's form) must read its frozen pre-fix
#   class under the same dead emulator: HONOURED, or LIES where the batch also made a mode close fire only on its own
#   finding; never UNJUDGED, so the rows read UNJUDGED because of those lines.
# EXPECTS: (1) silent and 0 with no mode, the one line with a mode; (2) every row reads its frozen class (UNJUDGED), also
#   with only its named instrument dead, and every plain run is red and silent; (3) every neutered copy reads its frozen stripped class (HONOURED or LIES). A row whose mode is not declared by its gate
#   any more, whose gate carries no `# #310 g7 NJ` line, or whose dead instrument is neither MAME_BIN nor FBNEO_BIN, FAILs.
#   A gate may hold several rows (one per mode, batch 2): each row's runs are kept apart by gate and mode.
# FOLLOWS: tests/lib/controls.sh tests/lib/classify.sh tests/expected/dead_leg_unjudged.tsv
#
# MUST-FIRE: known-bad: nj-stripped — every row's mode run on its gate's copy with the `# #310 g7 NJ` lines neutered (the pre-fix gate) must read its frozen stripped class, not the frozen UNJUDGED, and the gate must FAIL (in-gate: section 3; mode: section 2 runs the stripped copies)
# MUST-FIRE: known-bad: plain-loud — a copy of tests/lib/controls.sh whose vs_ctl_nj prints in a plain run too, without crashing, must make section 1's plain case print and the plain run of every row whose gate calls vs_ctl_nj outside a mode-only branch print NOT JUDGED (23 of 25 at 14z-221: audit_dispatch_census prints its NOT JUDGED only under a mode, and audit_id_writers' calls outside its mode branch guard a missing or unregistered BUILD and a failed ROM audit, which a dead emulator does not reach; the count is read at each run, never frozen), and the gate must FAIL (in-gate: every run builds the copies and checks both cases print; mode: section 1 sources that copy; section 2 runs each row's gate copied with its controls.sh swapped for it)
#
# WHY: #310 (the 14z-215 re-census, group 7: 104 gates PRESENT): a leg that never finished counted as the control firing.
#   Ruled 2026-10-31 (maintainer): "5 and 6 now, 7 in batches (Recommended)", whose text read "Group 7 (104 gates) in
#   later sessions, batched by family, each batch proven by MAME_BIN=/usr/bin/false reading UNJUDGED". Batch 1 (14z-221):
#   the gates with one PRESENT mode whose dead-emulator run read HONOURED at HEAD d3e8810d.
set -u
REPO="$(cd "$(dirname "$0")/.." && pwd)"; cd "$REPO"
. "$REPO/tests/lib/controls.sh"; vs_ctl_mode "$0"
W="$(mktemp -d)" || { echo "FAIL: test_dead_leg_unjudged — mktemp -d failed (W)"; exit 2; }; trap '[ -n "${KEEP_W:-}" ] || rm -rf "$W"' EXIT; trap 'exit 130' INT; trap 'exit 143' TERM
fail=0; ok() { echo "  ok    $*"; }; bad() { echo "  FAIL  $*"; fail=1; }
T="$REPO/tests/expected/dead_leg_unjudged.tsv"
[ -f "$T" ] || { echo "FAIL: test_dead_leg_unjudged — no table $T"; exit 1; }
[ -n "${ROMDIR:-}" ] || { echo "FAIL: test_dead_leg_unjudged — ROMDIR unset, the row gates check their ROMs first"; exit 2; }
JOBS="${JOBS:-6}"

echo "== 1. the helper"
CTLS="$REPO/tests/lib/controls.sh"; LOUDCTL="$W/ctl_loud.sh"
# plain-loud's plant, built in EVERY run: the mode swaps it in for the real library (sections 1 and 2); a plain run checks
# in-gate that the same checks see it (the runner reads each declared control's FIRED line from the plain run)
loudok=1
python3 - "$CTLS" "$LOUDCTL" <<'PY' || loudok=0
import re, sys
s = open(sys.argv[1]).read()
# the whole line replaced by one that prints with or without a mode and is set -u safe: the failure planted is a helper
# LOUD in a plain run, never one that crashes (a crash fails section 1 for the wrong reason: rule-checker run 2026-11-05-1641)
t, n = re.subn(r'(?m)^vs_ctl_nj\(\) \{ \[ -n "\$\{VS_CTL:-\$\{CONTROL:-\}\}" \] \|\| return 0; echo "NOT JUDGED: under control mode \$\{VS_CTL:-\$CONTROL\}, \$1"; \}$',
               'vs_ctl_nj() { echo "NOT JUDGED: under control mode ${VS_CTL:-${CONTROL:-}}, $1"; }', s)
if n != 1: sys.exit(1)
open(sys.argv[2], "w").write(t)
PY
if vs_ctl_is plain-loud; then
    [ "$loudok" = 1 ] || { echo "REFUSED: plain-loud: the vs_ctl_nj line moved"; exit 3; }
    CTLS="$LOUDCTL"
fi
loud1_ig=0
if [ "$loudok" = 1 ] && ! vs_ctl_is plain-loud; then   # in-gate: the plant prints in section 1's plain case
    pl="$( (unset CONTROL VS_CTL; . "$LOUDCTL"; vs_ctl_nj "a leg died"; echo "rc=$?") 2>&1)"
    [ "$pl" = "NOT JUDGED: under control mode , a leg died
rc=0" ] && loud1_ig=1
fi
p="$( (unset CONTROL VS_CTL; . "$CTLS"; vs_ctl_nj "a leg died"; echo "rc=$?") 2>&1)"
[ "$p" = "rc=0" ] && ok "no mode: silent, returns 0" || bad "no mode: printed or failed: $(printf '%s' "$p" | tr '\n' '|')"
loud1=0; [ "$p" = "NOT JUDGED: under control mode , a leg died
rc=0" ] && loud1=1   # plain-loud's own evidence: the planted helper PRINTED (a crash is not this control firing)
m="$( (VS_CTL=some-mode; . "$CTLS"; VS_CTL=some-mode; vs_ctl_nj "a leg died"; echo "rc=$?") 2>&1)"
[ "$m" = "NOT JUDGED: under control mode some-mode, a leg died
rc=0" ] && ok "under a mode: the one NOT JUDGED line, returns 0" || bad "under a mode: got $(printf '%s' "$m" | tr '\n' '|')"
printf 'CONTROL MODE: x\n%s\nFAIL: stub\n' "$(printf '%s' "$m" | head -1)" > "$W/stub.log"
( . "$REPO/tests/lib/classify.sh"; vs_classify_control 1 "$W/stub.log" "" x; [ "$VS_CTL_EXEC" = UNJUDGED ] ) \
    && ok "a FAIL log carrying it classifies UNJUDGED" || bad "a FAIL log carrying it does not classify UNJUDGED"

echo "== 2. each row's mode, and its plain run, with a dead emulator"
rows="$(grep -v '^#' "$T" | awk -F'\t' 'NF >= 5')"
[ -n "$rows" ] || { echo "FAIL: test_dead_leg_unjudged — the table has no rows"; exit 1; }
mkdir -p "$W/c"
# the stripped copies (section 3, and section 2 under nj-stripped): the gate without its `# #310 g7 NJ` lines, REPO pinned
printf '%s\n' "$rows" | while IFS="$(printf '\t')" read -r g m c sc dv; do
    [ -f "$W/c/$g/strip.txt" ] && continue   # one copy per gate; a gate may hold several rows
    mkdir -p "$W/c/$g"
    python3 - "$REPO/tests/$g.sh" "$W/c/$g/$g.sh" "$REPO" <<'PY' > "$W/c/$g/strip.txt" 2>&1 || true
import re, sys
src, out, repo = sys.argv[1:4]
s = open(src).read()
# NEUTER, never delete: a tagged line may carry the gate's own command (`rig || { vs_ctl_nj ...; }`) or an else/fi
lines = s.split("\n"); n = 0
for i, l in enumerate(lines):
    if "# #310 g7 NJ" in l:
        n += 1; lines[i] = re.sub(r'\bvs_ctl_nj\b', ':', l).replace("NOT JUDGED:", "NJ STRIPPED:")
t = "\n".join(lines)
t, k = re.subn(r'(?m)^REPO="\$\(cd "\$\(dirname "\$0"\)/\.\." && pwd(?: -P)?\)"', f'REPO="{repo}"', t, count=1)
if n == 0 or k != 1: print(f"STRIP-FAILED stripped={n} repo_lines={k}"); sys.exit(1)
open(out, "w").write(t); print(f"stripped {n}")
PY
done
# plain-loud, section 2's half: each row's gate copied with REPO pinned and its controls.sh swapped for the loud copy, so
# the plain-run silence check below is shown to see a helper that prints without a mode
if [ "$loudok" = 1 ]; then
    printf '%s\n' "$rows" | while IFS="$(printf '\t')" read -r g m c sc dv; do
        [ -f "$W/l/$g/loud.txt" ] && continue   # one copy per gate
        mkdir -p "$W/l/$g"
        python3 - "$REPO/tests/$g.sh" "$W/l/$g/$g.sh" "$REPO" "$LOUDCTL" <<'PY' > "$W/l/$g/loud.txt" 2>&1 || true
import re, sys
src, out, repo, loud = sys.argv[1:5]
t = open(src).read()
t, k = re.subn(r'(?m)^REPO="\$\(cd "\$\(dirname "\$0"\)/\.\." && pwd(?: -P)?\)"', f'REPO="{repo}"', t, count=1)
t, n = re.subn(r'\. "\$REPO/tests/lib/controls\.sh"', f'. "{loud}"', t)
if n == 0 or k != 1: print(f"LOUD-FAILED sourced={n} repo_lines={k}"); sys.exit(1)
open(out, "w").write(t); print(f"loud {n}")
PY
        if grep -q 'LOUD-FAILED' "$W/l/$g/loud.txt" && vs_ctl_is plain-loud; then echo "REFUSED: plain-loud: $g: $(cat "$W/l/$g/loud.txt")"; exit 3; fi
    done || { echo "REFUSED: plain-loud: a row's loud gate copy could not be made (the REFUSED line above names it)"; exit 3; }
fi
loud_plain() {  # loud_plain <script> <out> <dead instrument> — plain-loud in-gate: a row's plain run on its loud copy
    env -u CONTROL PAIRINGS_OUT="$2.lpp" MAME_BIN=/usr/bin/false "$3=/usr/bin/false" timeout -k 30 600 sh "$1" < /dev/null > "$2.plain" 2>&1
}
run_row() {  # run_row <gate> <mode> <script> <out> <dead instrument> — the mode run and the plain run, each classified
    _g=$1; _m=$2; _s=$3; _o=$4; _dv=$5
    # PAIRINGS_OUT: audit_legacy_pairings keeps every dead leg's sandbox under its output dir (#233), ~2,000 files a run
    # here; this gate's runs keep theirs in its own scratch, never in build/ (the 14z-221 close tier's plan refused on them)
    env CONTROL="$_m" PAIRINGS_OUT="$_o.lp" MAME_BIN=/usr/bin/false "$_dv=/usr/bin/false" timeout -k 30 600 sh "$_s" < /dev/null > "$_o.mode" 2>&1; _st=$?
    ( . "$REPO/tests/lib/classify.sh"; vs_classify_control "$_st" "$_o.mode" "$_s" "$_m"; printf '%s\t%s\n' "$VS_CTL_EXEC" "$_st" ) > "$_o.cls"
    env -u CONTROL PAIRINGS_OUT="$_o.lpp" MAME_BIN=/usr/bin/false "$_dv=/usr/bin/false" timeout -k 30 600 sh "$_s" < /dev/null > "$_o.plain" 2>&1; echo $? > "$_o.pst"
    # a row whose dead instrument is not MAME_BIN: the mode once more with ONLY that instrument dead and MAME_BIN UNSET
    # (never made dead), so the row's class is shown to come from the instrument it names, not from the dead MAME every
    # other run carries (14z-221c, rule-checker runs 2026-11-06-1665 and -1666 Q4)
    if [ "$_dv" != MAME_BIN ]; then
        env -u MAME_BIN CONTROL="$_m" PAIRINGS_OUT="$_o.lo" "$_dv=/usr/bin/false" timeout -k 30 600 sh "$_s" < /dev/null > "$_o.only" 2>&1; _st=$?
        ( . "$REPO/tests/lib/classify.sh"; vs_classify_control "$_st" "$_o.only" "$_s" "$_m"; printf '%s\t%s\n' "$VS_CTL_EXEC" "$_st" ) > "$_o.ocls"
    fi
}
pool=0
printf '%s\n' "$rows" > "$W/rows.tsv"
nloud=0
while IFS="$(printf '\t')" read -r g m c sc dv; do
    case "$dv" in MAME_BIN|FBNEO_BIN) ;; *) continue ;; esac   # refused by name below
    s="$REPO/tests/$g.sh"; vs_ctl_is nj-stripped && s="$W/c/$g/$g.sh"; vs_ctl_is plain-loud && s="$W/l/$g/$g.sh"
    ( run_row "$g" "$m" "$s" "$W/r.$g.$m" "$dv" ) &
    ( run_row "$g" "$m" "$W/c/$g/$g.sh" "$W/s.$g.$m" "$dv" ) &
    if ! vs_ctl_is plain-loud && [ -f "$W/l/$g/$g.sh" ]; then ( loud_plain "$W/l/$g/$g.sh" "$W/l.$g.$m" "$dv" ) & pool=$((pool + 1)); fi
    pool=$((pool + 2)); if [ "$pool" -ge "$JOBS" ]; then wait; pool=0; fi
done < "$W/rows.tsv"
wait
while IFS="$(printf '\t')" read -r g m c sc dv; do
    case "$dv" in MAME_BIN|FBNEO_BIN) ;; *) bad "$g@$m: dead instrument '$dv' is neither MAME_BIN nor FBNEO_BIN"; continue ;; esac
    grep -q 'STRIP-FAILED' "$W/c/$g/strip.txt" && { bad "$g: $(cat "$W/c/$g/strip.txt") — the row's gate carries no NJ line, or its REPO line moved"; continue; }
    vs_ctl_declared "$REPO/tests/$g.sh" | grep -qx -- "$m" || { bad "$g: $m is not a declared mode of the gate any more"; continue; }
    got="$(cut -f1 "$W/r.$g.$m.cls" 2>/dev/null)"; gst="$(cut -f2 "$W/r.$g.$m.cls" 2>/dev/null)"
    gline="$(grep -a -m1 -E '^(NOT JUDGED|FAIL|CONTROL)' "$W/r.$g.$m.mode" | cut -c1-90)"
    if [ "$got" = "$c" ]; then ok "$g@$m reads $got under a dead emulator"
    else bad "$g@$m reads ${got:-nothing} under a dead emulator, frozen $c [exit $gst: $gline]"; fi
    if [ "$dv" != MAME_BIN ]; then
        og="$(cut -f1 "$W/r.$g.$m.ocls" 2>/dev/null)"
        if [ "$og" = "$c" ]; then ok "$g@$m reads $og with ONLY $dv dead (MAME_BIN unset, never made dead): the class comes from $dv"
        else bad "$g@$m reads ${og:-nothing} with only $dv dead, frozen $c: the row's dead instrument is not what made it $c"; fi
    fi
    pst="$(cat "$W/r.$g.$m.pst" 2>/dev/null)"
    if [ "${pst:-0}" = 0 ]; then bad "$g: its PLAIN run exits 0 with a dead emulator: it passes on no leg"
    elif grep -qa '^NOT JUDGED: ' "$W/r.$g.$m.plain"; then nloud=$((nloud + 1)); bad "$g: its plain run prints NOT JUDGED (the helper is not silent without a mode)"
    else ok "$g: plain run red (exit $pst) and silent with a dead emulator"; fi
done < "$W/rows.tsv"

echo "== 3. in-gate control: each gate with its NJ lines neutered reads its frozen pre-fix class again"
nfired=0; nrows=0
while IFS="$(printf '\t')" read -r g m c sc dv; do
    nrows=$((nrows + 1))
    grep -q 'STRIP-FAILED' "$W/c/$g/strip.txt" && continue
    sg="$(cut -f1 "$W/s.$g.$m.cls" 2>/dev/null)"
    sline="$(grep -a -m1 -E '^(FAIL|CONTROL|  File|[A-Za-z]*Error)' "$W/s.$g.$m.mode" | cut -c1-90)"
    case "$sc" in HONOURED|LIES) ;; *) bad "$g: the frozen stripped class '$sc' is neither HONOURED nor LIES"; continue ;; esac
    if [ "$sg" = "$sc" ]; then nfired=$((nfired + 1))
    else bad "nj-stripped: $g@$m with its NJ lines neutered reads ${sg:-nothing}, frozen $sc [$sline]"; fi
done < "$W/rows.tsv"
if [ "$nfired" = "$nrows" ]; then vs_ctl_fired nj-stripped "all $nrows rows' gates with their NJ lines neutered read their frozen pre-fix class under a dead emulator, none UNJUDGED"
else vs_ctl_dead nj-stripped "only $nfired of $nrows neutered gates read their frozen pre-fix class" || fail=1; fi

if vs_ctl_is plain-loud; then
    if [ "$loud1" = 1 ] && [ "$nloud" -gt 0 ]; then vs_ctl_fired plain-loud "the loud helper printed its NOT JUDGED line in section 1's plain case and in $nloud of $nrows rows' plain runs"
    else vs_ctl_dead plain-loud "the loud helper did not print where planted (section 1: $loud1, plain runs: $nloud of $nrows)" || fail=1; fi
else   # in-gate: the same two checks, run on the loud copies, would have failed
    nloud_ig=0
    while IFS="$(printf '\t')" read -r g m c sc dv; do
        grep -qa '^NOT JUDGED: ' "$W/l.$g.$m.plain" 2>/dev/null && nloud_ig=$((nloud_ig + 1))
    done < "$W/rows.tsv"
    if [ "$loud1_ig" = 1 ] && [ "$nloud_ig" -gt 0 ]; then vs_ctl_fired plain-loud "in-gate: the loud helper prints in section 1's plain case and in $nloud_ig of $nrows rows' plain runs, which sections 1 and 2 fail"
    else vs_ctl_dead plain-loud "in-gate: the loud helper did not print where planted (section 1: $loud1_ig, plain runs: $nloud_ig of $nrows)" || fail=1; fi
fi
if [ "$fail" = 0 ]; then echo "PASS: test_dead_leg_unjudged — $nrows rows read their frozen class with a dead emulator, plain runs red and silent"
else echo "FAIL: test_dead_leg_unjudged"; exit 1; fi
