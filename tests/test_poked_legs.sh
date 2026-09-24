#!/bin/sh
# test_poked_legs.sh — THE CENSUS OF EVERY FORCED-PICK LEG in tests/ and tools/, classified by what the poke leaves latched, frozen shrink-only; a new CROSS-FLAVOR pairing fails until it is measured and accepted (GitHub #151 step 3, 14z-161).
#
# WHAT: the census of every forced-pick leg in tests/ and tools/, classified by what the
#   poke leaves latched (SAME / CROSS-INERT / CROSS-FLAVOR / PARAM) through the game's own
#   select wheel, frozen shrink-only: a new CROSS-FLAVOR pairing fails until it is measured
#   and accepted in tests/expected/poked_legs_accepted.tsv.
# HOW: tools/audit_poked_legs.py statically pairs every poke of the id fields in a script
#   with the replays it names, resolves the confirm's cell through tools/select_wheel.py on
#   the decrypted data view and our wheel from the build, and classes each; controls feed a
#   fixture that pokes Phobos over Donovan's cell and drop a frozen row.
# EXPECTS: the census equal to the frozen file, every CROSS-FLAVOR row carrying its accepted
#   measurement; the new-flavour fixture is reported NEW and the dropped row fails.
#
# MUST-FIRE: perturbed-copy: new-flavor-leg — a fixture script that pokes Phobos (0x10) over Donovan's cell (replay 17's R,R prologue) on a native leg is a CROSS-FLAVOR pairing the accepted list does not carry, and the census must FAIL on it (in-gate: the fixture is fed through --extra-script and must be reported NEW; mode: the fixture is added to the real scan and the gate FAILs)
# MUST-FIRE: perturbed-copy: dropped-row — the frozen census minus one row must FAIL the exact comparison (in-gate: the file is compared against itself minus its first row and must differ; mode: the measured census is compared against that perturbed file and the gate FAILs)
#
# WHY. #151 asked which of the tree's forced-pick legs measure the rig rather
# than the game. tools/audit_poked_legs.py answers it STATICALLY: every poke of
# RAM:$FF8782/$FF8B82 in a script, paired with the replays it names, resolved
# through the game's own select wheel (tools/select_wheel.py on the decrypted
# data view; tools/select_paths.py for the two default cells) to the cell the
# confirm latched, and classified SAME / CROSS-INERT / CROSS-FLAVOR / PARAM by
# the two measured facts in the tool's docstring (what the confirm writes per
# cell; who reads it in play). The whole census is frozen so it can only
# change by a reviewed edit, and the CROSS-FLAVOR rows carry, in
# tests/expected/poked_legs_accepted.tsv, the measurement that lets each stay:
# a tap (tests/audit_latch_reads.sh) showing its subject never reads the byte,
# or the note that the pairing is one the script never executes.
#
# Static tier: needs ROMDIR only on a cold decrypt cache (tests/lib/decrypt_cache.sh)
# and build/m3b_merged27/verify_data.bin for our wheel (SKIP without it).
#
# Usage: ROMDIR=... [FREEZE=1] tests/test_poked_legs.sh
set -eu
REPO="$(cd "$(dirname "$0")/.." && pwd)"
[ -n "${ROMDIR:-}" ] || { echo "FAIL: set ROMDIR"; exit 1; }
[ -d "$ROMDIR" ] && ROMDIR="$(cd "$ROMDIR" && pwd)"
CONTROL="${CONTROL:-}"
case "$CONTROL" in ""|new-flavor-leg|dropped-row) ;; *) echo "REFUSED: no control named '$CONTROL' is declared by this gate"; exit 3 ;; esac
WIDE_DATA="${WIDE_DATA:-$REPO/build/m3b_merged27/verify_data.bin}"
[ -f "$WIDE_DATA" ] || { echo "SKIP: no WIDE data view at $WIDE_DATA"; exit 0; }
EXPECT="$REPO/tests/expected/poked_legs.tsv"
ACCEPT="$REPO/tests/expected/poked_legs_accepted.tsv"
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT INT TERM
fail=0
ok()  { printf '  ok    %s\n' "$1"; }
bad() { printf '  FAIL  %s\n' "$1"; fail=1; }

echo "== 1. the two wheels"
. "$REPO/tests/lib/decrypt_cache.sh"
decrypt_view vsav2 "$W/vs2.op" "$W/vs2.data" || { echo "FAIL: decrypt_view vsav2 unavailable"; exit 1; }
python3 "$REPO/tools/select_wheel.py" "$W/vs2.data" --set vsav2 --json "$W/wheel_vsav2.json" > "$W/w1.log" 2>&1 || { echo "FAIL: vsav2 wheel: $(tail -1 "$W/w1.log")"; exit 1; }
python3 "$REPO/tools/select_wheel.py" "$WIDE_DATA" --set vsavj --json "$W/wheel_wide.json" > "$W/w2.log" 2>&1 || { echo "FAIL: WIDE wheel: $(tail -1 "$W/w2.log")"; exit 1; }
python3 "$REPO/tools/select_paths.py" "$W/wheel_vsav2.json" --check > "$W/paths.log" 2>&1 || { echo "FAIL: the 14z-160 paths no longer resolve on vsav2's wheel: $(tail -1 "$W/paths.log")"; exit 1; }
ok "vsav2 and WIDE wheels decoded; the measured P1/P2 paths resolve"

# the fixture for the new-flavor-leg control: a native leg poking Phobos over Donovan's cell
# (the poke token is assembled from pieces so this gate's own text is not a poked leg — [VSP-181])
P1F="ff87"; P1F="${P1F}82"
{
    echo '# fixture: a native leg with replay 17 (P1 R,R = Donovan on vsav2) and the Phobos poke'
    echo '"$REPO/tools/run_mame.sh" vsav2 -autoboot_script x'
    echo 'RPL="$REPO/tests/replays/17_don_oracle_vsav2.rpl"'
    echo "PK=\"1400:$P1F:10;1450:$P1F:10;1500:$P1F:10\""
} > "$W/fixture_gate.sh"

echo "== 2. the census"
EXTRA=""; [ "$CONTROL" = new-flavor-leg ] && EXTRA="--extra-script $W/fixture_gate.sh"
if python3 "$REPO/tools/audit_poked_legs.py" --vsav2 "$W/wheel_vsav2.json" --wide "$W/wheel_wide.json" --repo "$REPO" --tsv "$W/got.tsv" --accepted "$ACCEPT" $EXTRA > "$W/census.log" 2>&1; then
    ok "$(head -1 "$W/census.log")"
else
    bad "the census reports an unaccepted CROSS-FLAVOR pairing: $(grep '^NEW' "$W/census.log" | head -3 | tr '\n' ' ')"
fi
if [ "$CONTROL" = new-flavor-leg ]; then
    if [ "$fail" = 1 ]; then echo "CONTROL FIRED: new-flavor-leg — the fixture's Phobos-over-Donovan leg is reported NEW"; echo "FAIL: test_poked_legs (control mode)"; exit 1
    else echo "CONTROL DEAD: new-flavor-leg — the fixture went unreported"; echo "FAIL: test_poked_legs"; exit 1; fi
fi
grep '^accepted CROSS-FLAVOR leg no longer poked' "$W/census.log" | while read -r l; do echo "  note  $l"; done

echo "== 3. the frozen census"
if [ "${FREEZE:-0}" = 1 ]; then
    {
        echo "# tests/expected/poked_legs.tsv — every forced-pick leg in tests/ and tools/, as tools/audit_poked_legs.py"
        echo "# classifies it (test_poked_legs.sh). Evidence class: static (the scripts, the replays, the two decoded wheels)."
        echo "# Frozen 14z-161 with FREEZE=1; a new row is a new poked leg — classify it (and tap it if CROSS-FLAVOR) before re-freezing."
        echo "#--"
        grep -v '^#' "$W/got.tsv"
    } > "$EXPECT"
    echo "  FROZE  $(basename "$EXPECT") ($(grep -vc '^#' "$EXPECT") rows) — VERIFY by re-running without FREEZE"; exit 0
fi
[ -f "$EXPECT" ] || { echo "FAIL: no frozen census at $EXPECT (FREEZE=1 to create it)"; exit 1; }
grep -v '^#' "$EXPECT" > "$W/want.rows"; grep -v '^#' "$W/got.tsv" > "$W/got.rows"
[ "$CONTROL" = dropped-row ] && sed -i.bak '2d' "$W/want.rows"
if diff "$W/want.rows" "$W/got.rows" > "$W/diff.txt"; then ok "census as frozen ($(wc -l < "$W/got.rows" | tr -d ' ') rows)"
else bad "census differs from the frozen file: $(grep -c '^[<>]' "$W/diff.txt") rows"; head -12 "$W/diff.txt" | sed 's/^/        /'; fi
if [ "$CONTROL" = dropped-row ]; then
    if [ "$fail" = 1 ]; then echo "CONTROL FIRED: dropped-row — the census minus one row fails the comparison"; echo "FAIL: test_poked_legs (control mode)"; exit 1
    else echo "CONTROL DEAD: dropped-row — a missing row went unseen"; echo "FAIL: test_poked_legs"; exit 1; fi
fi

echo "== 4. must-fire controls (in-gate)"
if python3 "$REPO/tools/audit_poked_legs.py" --vsav2 "$W/wheel_vsav2.json" --wide "$W/wheel_wide.json" --repo "$REPO" --accepted "$ACCEPT" --extra-script "$W/fixture_gate.sh" > "$W/ctl1.log" 2>&1; then
    echo "CONTROL DEAD: new-flavor-leg — the fixture's Phobos-over-Donovan leg was not reported"; fail=1
else
    echo "CONTROL FIRED: new-flavor-leg — $(grep -c '^NEW' "$W/ctl1.log") NEW pairing(s) reported for the fixture"
fi
sed '2d' "$W/want.rows" > "$W/minus.rows"
if diff "$W/want.rows" "$W/minus.rows" > /dev/null; then echo "CONTROL DEAD: dropped-row — removing a row went unseen"; fail=1
else echo "CONTROL FIRED: dropped-row — the frozen census minus its second row differs"; fi

if [ "$fail" = 0 ]; then echo "PASS: test_poked_legs"; else echo "FAIL: test_poked_legs"; exit 1; fi
