#!/bin/sh
# test_poke_readback.sh — EVERY GATE THAT SAMPLES AN ADDRESS ITS OWN RIG POKES IS ON THE
# TABLE, and the table's classification is the maintainer's, not the tool's (GitHub #171
# slice Q6, shape 4 of docs/project/gate_qualification_scope.md). ci_portable: no ROM, no
# emulator — the rig generators run in-process; ~2 s (measured 14z-180).
#
# WHAT: the census of tools/audit_poke_readback.py — for every tests/ci_emulator.tsv gate, each
#   address the gate's rig POKES (literal `frame:addr:hex` tokens and the pokes of the
#   name_moves / vanilla_join_rig schedules it generates) that a SAMPLE of the same gate reads
#   (FIELDS, DUMPS, TAP/WATCH/RTAP, FBNEO_HTAP) — equals the live rows of the frozen
#   tests/expected/poke_readback.tsv: every derived finding has a row with the census's LEG
#   (main / control / mixed — a control leg's plant reads its poke back by design), every
#   non-RETIRED row still derives, a READS-BACK row never silently disappears, and the known positive case
#   (test_killshread_es's `stock` column over the rig's ff8509 poke) derives and is classed
#   READS-BACK.
# HOW: the tool runs over the tree (and, for the controls, over a copy with one gate perturbed);
#   the gate joins its output with the frozen table by (gate, address, sample); a finding
#   without a row, a live row without a finding, or a mis-classed known case is a red.
# EXPECTS: PASS when the derived findings and the table agree. A red names the finding and the
#   direction (new finding: classify it — FREEZE=1 adds it as UNCLASSIFIED for the maintainer;
#   stale row: mark it RETIRED with why; the known case lost: the census went blind).
#
# MUST-FIRE: perturbed-copy: known-case-blind — a copy of the tree where test_killshread_es no longer samples ff8509 as `stock` must lose the known READS-BACK finding and FAIL: the census's positive control (mode: the census runs on that copy)
# MUST-FIRE: perturbed-copy: rig-poke-width — a copy with a synthetic gate that generates donovan part 12 (its HP pin a 4-byte poke at ff8850) and samples only the white-HP word at ff8852 must derive that finding, or a rig poke counted one byte wide misses what it covers — the 72-for-74 defect (mode: the census runs on that copy; the mode FAILS because the new finding has no row)
# MUST-FIRE: perturbed-copy: control-leg-flagged — a copy with a synthetic gate whose poke is assigned as PLANT_POKE and sampled must derive that finding with leg=control, or a known-bad plant's read-back would be listed as the measuring leg's (mode: the census runs on that copy; the mode FAILS because the new finding has no row)
# MUST-FIRE: perturbed-copy: unclassified-finding — a copy where one gate gains a FIELDS entry over an address its rig pokes must derive a finding with no row and FAIL (mode: the census runs on that copy)
#
# WHY A TABLE THE MAINTAINER OWNS: a value poked before an event and read after it can be a
# legitimate observation or the rig reading itself back, and only the gate's purpose decides
# which — dropping a column changes what a gate claims. The tool derives; the table rules; this
# gate keeps the two joined.
#
# Usage: tests/test_poke_readback.sh      # FREEZE=1 adds new findings to the table as UNCLASSIFIED
set -u
REPO="$(cd "$(dirname "$0")/.." && pwd)"; cd "$REPO"
. "$REPO/tests/lib/controls.sh"; vs_ctl_mode "$0"
EXP=tests/expected/poke_readback.tsv
W="$(mktemp -d "${TMPDIR:-/tmp}/pokerb.XXXXXX")"; trap 'rm -rf "$W"' EXIT INT TERM
fail=0; ok() { echo "  ok    $*"; }; bad() { echo "  FAIL  $*"; fail=1; }

census() {  # census ROOT -> gate<TAB>addr<TAB>sample (sorted), frames dropped
    python3 tools/audit_poke_readback.py --root "$1" 2>"$W/census.err" | awk -F'\t' 'NF==5 {print $1"\t"$2"\t"$4}' | sort -u
}
perturb() {  # perturb NAME ROOT — a copy of the tree with one gate perturbed; prints the gate
    mkdir -p "$2/tests"; cp tests/*.sh "$2/tests/"; cp tests/ci_emulator.tsv "$2/tests/"
    ln -s "$REPO/tools" "$2/tools"; ln -s "$REPO/tests/replays" "$2/tests/replays"; ln -s "$REPO/tests/lib" "$2/tests/lib"
    case "$1" in
        known-case-blind)
            sed -i.bak 's/,ff8509:b:stock//' "$2/tests/test_killshread_es.sh"; rm -f "$2/tests/"*.bak
            grep -q 'ff8509:b:stock' "$2/tests/test_killshread_es.sh" && { echo NONE; return 1; }
            echo test_killshread_es ;;
        control-leg-flagged)
            g=test_plant_probe
            printf '#!/bin/sh\n: "${MAME_BIN:-}"\nPLANT_POKE="1400:ff8782:10"\nFIELDS="ff8782:b:id"\necho PASS\n' > "$2/tests/$g.sh"
            chmod +x "$2/tests/$g.sh"; printf '%s\tmame\trelease\tromset\t-\tsynthetic\n' "$g" >> "$2/tests/ci_emulator.tsv"
            echo "$g" ;;
        rig-poke-width)
            # a synthetic gate that GENERATES donovan part 12 (whose HP pin is the 4-byte
            # 2550:ff8850:01200120) and samples only the white-HP word at ff8852: the finding
            # exists only if the rig poke is given its real width (rule-checker run 2026-09-24-145)
            g=test_rig_width_probe
            printf '#!/bin/sh\n: "${MAME_BIN:-}"\npython3 tools/name_moves.py gen donovan 12 "$W/r.rpl" "$W/r.json"\nFIELDS="ff8852:w:p2white"\necho PASS\n' > "$2/tests/$g.sh"
            chmod +x "$2/tests/$g.sh"; printf '%s\tmame\trelease\tromset\t-\tsynthetic\n' "$g" >> "$2/tests/ci_emulator.tsv"
            echo "$g" ;;
        unclassified-finding)
            # audit_tenant_throws pokes P2 HP (ff8850) and samples it already; give it a NEW sampled
            # address its rig pokes — the tenant id ff8782 (name_moves' early-window poke) — as a field
            g=test_stage_sweep_probe
            printf '#!/bin/sh\n: "${MAME_BIN:-}"\nPOKES="1400:ff8782:10;1450:ff8782:10"\nFIELDS="ff8782:b:id,ff8850:w:hp"\necho PASS\n' > "$2/tests/$g.sh"
            chmod +x "$2/tests/$g.sh"; printf '%s\tmame\trelease\tromset\t-\tsynthetic\n' "$g" >> "$2/tests/ci_emulator.tsv"
            echo "$g" ;;
    esac
}

root="."
if [ -n "$VS_CTL" ]; then
    g="$(perturb "$VS_CTL" "$W/mode" | tail -1)"; root="$W/mode"
    [ "$g" != NONE ] || { echo "FAIL: the perturbation could not be planted"; exit 1; }
    echo "MODE: control $VS_CTL — the census runs on a copy where $g.sh is perturbed"
fi

echo "== 1. the derived findings against $EXP"
[ -f "$EXP" ] || { echo "FAIL: $EXP missing"; exit 1; }
python3 tools/audit_poke_readback.py --root "$root" 2>/dev/null | awk -F'\t' 'NF==5' > "$W/census.full"
census "$root" > "$W/got.tsv"
if grep -q FAILED "$W/census.err"; then bad "a rig failed to generate: $(cat "$W/census.err")"; fi
n="$(wc -l < "$W/got.tsv" | tr -d ' ')"; echo "  derived: $n finding(s) — $(tail -1 "$W/census.err")"
awk -F'\t' '!/^#/ && NF>=4 && $4!="RETIRED" {print $1"\t"$2"\t"$3}' "$EXP" | sort -u > "$W/live.tsv"
new="$(comm -23 "$W/got.tsv" "$W/live.tsv")"; stale="$(comm -13 "$W/got.tsv" "$W/live.tsv")"
if [ -n "$new" ]; then
    if [ "${FREEZE:-0}" = 1 ] && [ -z "$VS_CTL" ]; then
        printf '%s\n' "$new" | while IFS="$(printf '\t')" read -r g a s; do
            leg="$(awk -F'\t' -v g="$g" -v a="$a" -v s="$s" '$1==g && $2==a && $4==s {print $5; exit}' "$W/census.full")"
            printf '%s\t%s\t%s\tUNCLASSIFIED\tderived %s; awaiting the maintainer'"'"'s ruling\t%s\n' "$g" "$a" "$s" "$(date +%Y-%m-%d)" "${leg:-?}" >> "$EXP"; done
        ok "FROZE $(printf '%s\n' "$new" | wc -l | tr -d ' ') new finding(s) as UNCLASSIFIED"
    else bad "finding(s) with no row (classify them — FREEZE=1 adds them as UNCLASSIFIED): $(printf '%s\n' "$new" | tr '\t' ':' | tr '\n' ' ')"; fi
else ok "every derived finding has a row"; fi
if [ -n "$stale" ]; then bad "live row(s) that no longer derive (mark RETIRED with why): $(printf '%s\n' "$stale" | tr '\t' ':' | tr '\n' ' ')"
else ok "every live row still derives ($(wc -l < "$W/live.tsv" | tr -d ' ') rows)"; fi

echo "== 1b. each live row's LEG (main / control / mixed) is the census's"
awk -F'\t' '!/^#/ && NF>=6 && $4!="RETIRED" {print $1"\t"$2"\t"$3"\t"$6}' "$EXP" | sort -u > "$W/live_leg.tsv"
awk -F'\t' '{print $1"\t"$2"\t"$4"\t"$5}' "$W/census.full" | sort -u > "$W/got_leg.tsv"
moved="$(comm -3 "$W/live_leg.tsv" "$W/got_leg.tsv" | awk -F'\t' '{print $1":"$2":"$3"="$4}' | sort -u | tr '\n' ' ')"
[ -z "$moved" ] && ok "every live row's leg agrees with the census ($(awk -F'\t' '$4=="control"' "$W/got_leg.tsv" | wc -l | tr -d ' ') control-leg, $(awk -F'\t' '$4=="mixed"' "$W/got_leg.tsv" | wc -l | tr -d ' ') mixed)" \
                || bad "a row's leg moved or is missing (edit the table's leg column after reading why): $moved"

echo "== 2. the known case: test_killshread_es samples ff8509 (stock) over the rig's poke, classed READS-BACK"
if grep -qx "test_killshread_es	ff8509	FIELDS:stock" "$W/got.tsv"; then
    cls="$(awk -F'\t' '$1=="test_killshread_es" && $2=="ff8509" && $3=="FIELDS:stock" {print $4}' "$EXP")"
    [ "$cls" = READS-BACK ] && ok "derived and classed READS-BACK" || bad "derived but classed '$cls' — the ruled case must read READS-BACK"
else bad "the known case did NOT derive — the census is blind to its positive control"; fi
for c in UNCLASSIFIED OBSERVES READS-BACK RETIRED; do printf '  %-13s %s\n' "$c" "$(awk -F'\t' -v c="$c" '!/^#/ && $4==c' "$EXP" | wc -l | tr -d ' ')"; done

if [ -z "$VS_CTL" ]; then
    echo "== 3. controls"
    g="$(perturb known-case-blind "$W/c1" | tail -1)"
    if [ "$g" = NONE ]; then vs_ctl_dead known-case-blind "could not remove the stock field"; fail=1
    elif census "$W/c1" | grep -qx "test_killshread_es	ff8509	FIELDS:stock"; then vs_ctl_dead known-case-blind "the finding still derives without the stock field"; fail=1
    else vs_ctl_fired known-case-blind "with the stock field removed the known finding is gone (section 2 would FAIL)"; fi
    g="$(perturb unclassified-finding "$W/c2" | tail -1)"
    if census "$W/c2" | grep -q "^$g	ff8782	FIELDS:id"; then vs_ctl_fired unclassified-finding "$g derives a finding (ff8782, FIELDS:id) with no row (section 1 would FAIL)"
    else vs_ctl_dead unclassified-finding "the planted poke-and-sample pair did not derive"; fail=1; fi
    g="$(perturb rig-poke-width "$W/c4" | tail -1)"
    if python3 tools/audit_poke_readback.py --root "$W/c4" 2>/dev/null | grep -q "^$g	ff8850	.*	FIELDS:p2white"; then
        vs_ctl_fired rig-poke-width "the rig's 4-byte HP pin at ff8850 reaches the white-HP word sampled at ff8852 ($g)"
    else vs_ctl_dead rig-poke-width "a rig poke counted one byte wide misses the word it covers"; fail=1; fi
    g="$(perturb control-leg-flagged "$W/c3" | tail -1)"
    leg="$(python3 tools/audit_poke_readback.py --root "$W/c3" 2>/dev/null | awk -F'\t' -v g="$g" '$1==g && $2=="ff8782" {print $5; exit}')"
    [ "$leg" = control ] && vs_ctl_fired control-leg-flagged "a poke assigned as PLANT_POKE derives with leg=control ($g)" \
                          || { vs_ctl_dead control-leg-flagged "the plant's poke read as leg '${leg:-none}'"; fail=1; }
fi

[ "$fail" -eq 0 ] && echo "PASS" || echo "FAIL"
exit "$fail"
