#!/bin/sh
# test_reaction_classes.sh — THE ROUTE OF A HIT'S CLASS FROM THE RECORD TO THE REACTION, re-derived from the decrypted images for pristine vsavj, vs2 and our merged build, with the legacy record census by class and every constant writer of the victim's +0x54, frozen (14z-169, the analysis before the class-0x52 fix of the column shock and the Plasma Trap, #136, which the maintainer ruled on 2026-09-18: "then I'm all for fixing. Once again, as long as we don't introduce noticeable lag and we don't break more things, it's a pure win/win" — DECISIONS_HISTORY.md).
#
# MUST-FIRE: perturbed-copy: stager-38-copy — a copy of vsavj's opcode image with the ground stager's entry 0x38 re-pointed at the copy handler must move the 0x38 route and the copy count and FAIL the frozen compare, so the route rows are read from the image (in-gate: the planted run must differ on exactly those two rows; mode: the gate runs on the planted copy and FAILs)
# MUST-FIRE: perturbed-copy: record-06-to-38 — a copy of vsavj's data image with the first reachable class-0x06 legacy record re-classed 0x38 must move the 0x06 and 0x38 census rows and FAIL the frozen compare, so the census reads each record's class byte (in-gate: the planted run must differ on exactly those two rows; mode: the gate runs on the planted copy and FAILs)
#
# WHY. The 14z-168 design note for the ruled 0x52 fix named class 0x38 as a candidate
# discriminator: vsavj's reaction table sends 0x06 AND 0x38 to the shock handler
# 0x23AC8 with the same property byte, so a column record remapped to 0x38 "would reach
# the same handler with the victim's +0x54 naming it apart from Lightning Sword's 0x06".
# It asked for a census of 0x38 in every legacy record first. This gate is that census and
# it found the premise false one step earlier: the record's class goes through a STAGER
# before +0x54 is written, and vsavj's ground stager writes 6 for both 0x06 and 0x38 (air
# 7, KO 8) — no stager handler in either game writes 0x38, and no constant write to
# +0x54 does. One legacy Victor record carries 0x38 on both games; it reacts as 0x06.
# vs2 tells its 0x52 column apart only on a GROUNDED victim (its ground stager writes
# 0x52; its shock handler is vsavj's plus `cmpi.b #$52,$54(a6); beq` around the
# attacker's freeze write); its air and KO stagers fold 0x52 into 7 and 8.
# Mechanism and addresses: docs/game/engine_internals.md, the reaction-class paragraphs;
# tool: tools/audit_reaction_classes.py (its docstring has the method).
#
# NOT COVERED: +0x54 written from a register, and the class byte read by code other than
# the three stagers — tests/audit_reaction_class_live.sh taps +0x54 over the corpus. The
# record census counts REACHABLE records (the anim walk reaches a few that are not real).
#
# FROZEN: tests/expected/reaction_classes.tsv — `<game> <kind> <where> <class> <value>`, and one
# `ours build <registry row> - <whole-set key>` row naming the build the ours rows were read from.
# The `ours` rows follow the merged build: re-freeze at every freeze (FREEZE=1), reviewing
# the diff; the vsavj and vsav2 rows move only if the reference images or the tool do.
#
# Usage: ROMDIR=... [BUILD=build/m3b_merged27] [FREEZE=1] tests/test_reaction_classes.sh
#   static tier (a build dir + the decrypted reference views, no emulator); measured 14z-169 on this MacBook: ~3 s
set -eu
REPO="$(cd "$(dirname "$0")/.." && pwd)"
BUILD="${BUILD:-build/m3b_merged27}"
case "$BUILD" in /*) ;; *) BUILD="$REPO/$BUILD" ;; esac
EXPECT="$REPO/tests/expected/reaction_classes.tsv"
CONTROL="${CONTROL:-}"
[ -f "$BUILD/verify_op.bin" ] || { echo "SKIP: no verify_op.bin in $BUILD"; exit 0; }
python3 -c "import capstone" 2>/dev/null || { echo "SKIP: python capstone not installed"; exit 0; }
case "$CONTROL" in ""|stager-38-copy|record-06-to-38) ;; *) echo "REFUSED: no control named '$CONTROL' is declared by this gate"; exit 3 ;; esac
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT INT TERM
fail=0
ok()  { printf '  ok    %s\n' "$1"; }
bad() { printf '  FAIL  %s\n' "$1"; fail=1; }
. "$REPO/tests/lib/decrypt_cache.sh"
decrypt_view vsavj "$W/vj_op.bin" "$W/vj_data.bin" || { echo "FAIL: test_reaction_classes (no vsavj view)"; exit 1; }
decrypt_view vsav2 "$W/v2_op.bin" "$W/v2_data.bin" || { echo "FAIL: test_reaction_classes (no vsav2 view)"; exit 1; }
TOOL="$REPO/tools/audit_reaction_classes.py"
census() {  # census <out.tsv> [plant] — ONE invocation, shared by the gate, the in-gate controls and the modes
    python3 "$TOOL" "$W/vj_op.bin" "$W/vj_data.bin" "$W/v2_op.bin" "$W/v2_data.bin" --ours "$BUILD/verify_op.bin" --tsv ${2:+--plant "$2"} > "$1" 2> "$1.err"
}

echo "== 1. the census"
census "$W/got.tsv" "$CONTROL" || { bad "tool: $(tail -1 "$W/got.tsv.err")"; echo "FAIL: test_reaction_classes"; exit 1; }
# WHICH BUILD the ours rows are (added 14z-169, rule-checker run 2026-09-18-51 Q1): the build's
# whole-set fingerprint resolved through tests/expected/registry.tsv, frozen as a row
_bid="$(python3 "$REPO/tools/build_fingerprint.py" "$BUILD/rompath" --set vsavjw --registry "$REPO/tests/expected/registry.tsv" 2>/dev/null | tail -1)"
_bfp="$(python3 "$REPO/tools/build_fingerprint.py" "$BUILD/rompath" --set vsavjw --set-key 2>/dev/null | tail -1 | cut -c1-8)"   # the WHOLE-SET key (run 52 Q1: the program key is shared with build/merged1)
[ -n "$_bid" ] && [ -n "$_bfp" ] || { bad "the build's fingerprint did not resolve"; echo "FAIL: test_reaction_classes"; exit 1; }
printf 'ours\tbuild\t%s\t-\t%s\n' "$_bid" "$_bfp" >> "$W/got.tsv"
ok "the ours rows are $(basename "$BUILD") = registry row $_bid ($_bfp)"
sed -n 's/^# read /  read  /p' "$W/got.tsv.err"
ok "$(wc -l < "$W/got.tsv" | tr -d ' ') rows"
# positive controls on the reading itself: the shock handler must be reached by 0x06 on
# every image, and the vs2 difference must be the one test the engine doc names
grep -q '^vsavj	reaction-to-shock	023ac8	-	06' "$W/got.tsv" || bad "vsavj's reaction table does not send 0x06 to 0x23AC8 — the reading is wrong"
grep -q '^ours	reaction-to-shock	023ac8	-	06' "$W/got.tsv" || bad "our build's reaction table does not send 0x06 to 0x23AC8"
grep -q '^both	shock-handler	.*vs2-only: cmpi.b #\$52, \$54(a6)' "$W/got.tsv" || bad "the vs2 shock handler's 0x52 test is not seen"
awk -F'\t' '$2=="writes38" && $5!="none"' "$W/got.tsv" | grep -q . && bad "a stager handler writes 0x38 into +0x54: $(awk -F'\t' '$2=="writes38" && $5!="none"' "$W/got.tsv" | head -1)"
# the REFERENCE rows must EXIST before their "none" can mean anything (rule-checker run
# 2026-09-19-55 Q4: a check over rows the tool stopped emitting would pass vacuously)
for _g in vsavj vsav2; do
    awk -F'\t' -v g="$_g" '$1==g && $2=="imm54" && $3=="value" && $4=="38"' "$W/got.tsv" | grep -q . \
        || bad "no '$_g imm54 value 38' row — the reference 0x38 check below would read nothing"
done
awk -F'\t' '$1!="ours" && $2=="imm54" && $3=="value" && $4=="38" && $5!="none"' "$W/got.tsv" | grep -q . && bad "a constant write puts 0x38 into +0x54 on a REFERENCE image — the S1 marker's premise (vanilla never produces 0x38) is gone"
# OURS carries exactly ONE constant 0x38 writer since the M19 freeze (14z-170): the class-0x52
# fix's marker, reaction_hook case_a4 (`move.b #$38,$54(a1)`, donovan.toml), which the two
# 14z-42 thunks test; the frozen table pins where it is placed
_n38="$(awk -F'\t' '$1=="ours" && $2=="imm54" && $3=="value" && $4=="38" && $5!="none" {print $5}' "$W/got.tsv" | tr ',' '\n' | grep -c . || true)"
[ "$_n38" = 1 ] || bad "our build has $_n38 constant 0x38 writers into +0x54 — the S1 design has exactly one (reaction_hook case_a4)"

echo "== 2. the must-fire controls (in-gate)"
for c in stager-38-copy record-06-to-38; do
    [ -n "$CONTROL" ] && break
    census "$W/ctl_$c.tsv" "$c" || { echo "CONTROL DEAD: $c — the planted run failed: $(tail -1 "$W/ctl_$c.tsv.err")"; fail=1; continue; }
    _moved="$(diff "$W/got.tsv" "$W/ctl_$c.tsv" | grep -c '^>' | tr -d ' ')" || true
    _want="$(sed -n 's/^# plant .* must move: //p' "$W/ctl_$c.tsv.err" | tr '\t' ' ')"
    _miss=""
    for m in $(sed -n 's/^# plant .* must move: //p' "$W/ctl_$c.tsv.err" | tr '\t' '|'); do
        _pat="$(echo "$m" | tr '|' '\t')"
        diff "$W/got.tsv" "$W/ctl_$c.tsv" | grep "^> $_pat" > /dev/null || _miss="$_miss $m"
    done
    if [ "$_moved" = 2 ] && [ -z "$_miss" ]; then echo "CONTROL FIRED: $c — the planted copy moved exactly its two rows"
    else echo "CONTROL DEAD: $c — moved $_moved rows; not moved:${_miss:- none} (wanted: $_want)"; fail=1; fi
done

echo "== 3. the frozen rows"
if [ "${FREEZE:-0}" = 1 ]; then
    [ "$fail" = 0 ] && [ -z "$CONTROL" ] || { echo "FAIL: test_reaction_classes (not frozen: fix the red first)"; exit 1; }
    {
        echo "# tests/expected/reaction_classes.tsv — the route of a hit's class from the attack record (+0x17) through the three stager"
        echo "# tables (ground / air / KO: what each writes into the victim's +0x54) to the reaction table, for pristine vsavj, vs2 and"
        echo "# our merged build ($(basename "$BUILD")); the property bytes; the shock handler's shape on each; the legacy record census by"
        echo "# class; every constant write to +0x54 (tests/test_reaction_classes.sh; tools/audit_reaction_classes.py). Evidence class:"
        echo "# static. Frozen 14z-169 with FREEZE=1. Columns: <game> <kind> <where> <class> <value>."
        echo "# The ours rows follow the build: re-freeze at every freeze, reviewing the diff."
        echo "#--"
        cat "$W/got.tsv"
    } > "$EXPECT"
    echo "  FROZE  $(basename "$EXPECT") ($(wc -l < "$W/got.tsv" | tr -d ' ') rows) — VERIFY by re-running without FREEZE"; exit 0
fi
[ -f "$EXPECT" ] || { echo "FAIL: no frozen expectation at $EXPECT (FREEZE=1 to create it)"; exit 1; }
grep -v '^#' "$EXPECT" > "$W/want.tsv"
if diff "$W/want.tsv" "$W/got.tsv" > "$W/diff.txt"; then ok "every row as frozen"
else bad "differs from the frozen rows"; sed 's/^/        /' "$W/diff.txt"; fi

if [ -n "$CONTROL" ]; then
    if [ "$fail" = 1 ]; then echo "CONTROL FIRED: $CONTROL — the planted copy fails the frozen compare"; echo "FAIL: test_reaction_classes (control mode)"; exit 1
    else echo "CONTROL DEAD: $CONTROL — the planted copy passed"; echo "FAIL: test_reaction_classes"; exit 1; fi
fi
if [ "$fail" = 0 ]; then echo "PASS: test_reaction_classes"; else echo "FAIL: test_reaction_classes"; exit 1; fi
