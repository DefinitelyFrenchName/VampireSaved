#!/bin/sh
# test_freeze_basis_sandbox.sh — GROUND TRUTH: tools/freeze_masked_basis.sh
# must never hand one run's MAME sandbox to the next run.
#
# WHY (14z-91, measured). freeze_one() derives its sandbox paths from the
# replay NAME alone (`$WORK/sb_${_n}_$_i`), and tools/run_mame.sh:6-10 treats
# an explicit MAME_SANDBOX as DELIBERATE REUSE — it does not clear it. So
# calling freeze_one twice for the same name in one invocation gives the
# second call the first call's cfg/nvram (an EEPROM is written on every run).
#
# That is not a hypothetical ordering: it is exactly what
#     VERIFY_BASIS=16_xemu_2p tools/freeze_masked_basis.sh <basis> <mask> 16_xemu_2p
# does — the canary command docs/NEXT_SESSION.md documents and STATE.md:280
# calls "the single cheapest canary". Measured on vsavj before the fix:
#   * the verify leg ran on fresh sandboxes and reproduced the frozen log
#     BIT-FOR-BIT, printing "ok: reproduces ... bit-for-bit";
#   * the freeze leg then ran on the dirty sandboxes, diverged at frame 73,
#     and OVERWROTE the basis log it had just verified (4248/4321 lines);
#   * both legs were internally deterministic, so the pair-cmp at
#     freeze_one's `cmp -s` and guard 2's control both stayed green.
# Independently ground-truthed with the real emulator the same session: a
# fresh-sandbox run is identical to the frozen basis, a reused-sandbox run
# differs from frame 73.
#
# A tool whose failure mode is "silently redefines the baseline the superset
# invariant rests on" is precisely the one that needs a gate, and the guards
# it already carries cannot see this one.
#
# HOW: no emulator and no ROMs. A scratch repo gets the real
# freeze_masked_basis.sh and a STUB run_replay_mame.sh whose output depends
# on whether it was handed a dirty sandbox — the same signature as the real
# defect, deterministic in a second. (The scratch-repo + stubbed-dependency
# idiom is tests/test_build_gate_status.sh's.)
#
# Usage: [GATE_SRC=<dir>] tests/test_freeze_basis_sandbox.sh
#   GATE_SRC points at a directory holding an alternative
#   freeze_masked_basis.sh — use it to re-run this against the pre-fix tool,
#   where section 1 MUST fail. Section 3 does that automatically.
set -eu
REPO="$(cd "$(dirname "$0")/.." && pwd)"; cd "$REPO"
SRC="${GATE_SRC:-$REPO/tools}"
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT
fail=0
NAME=99_stub_replay
MASK="043c-043d,7f00-8000"

# build a scratch repo: the tool under test + a stub runner + a dummy replay
mk_repo() {
    _r="$1"; _tool="$2"
    mkdir -p "$_r/tools" "$_r/tests/replays" "$_r/basis/logs"
    cp "$_tool" "$_r/tools/freeze_masked_basis.sh"
    chmod +x "$_r/tools/freeze_masked_basis.sh"
    echo "0 p1=R" > "$_r/tests/replays/$NAME.rpl"
    # THE STUB. Emits CLEAN on a fresh sandbox and DIRTY on a dirty one, then
    # dirties it — modelling MAME writing nvram/cfg into $MAME_SANDBOX.
    cat > "$_r/tools/run_replay_mame.sh" <<'STUB'
#!/bin/sh
set -eu
OUT="$3"; SB="${4:-}"
if [ -n "$SB" ] && [ -f "$SB/nvram/eeprom" ]; then
    printf '1 DIRTY-EEPROM-RUN\nEND 1\n' > "$OUT"
else
    printf '1 CLEAN-BOOT-RUN\nEND 1\n' > "$OUT"
fi
[ -n "$SB" ] && { mkdir -p "$SB/nvram"; : > "$SB/nvram/eeprom"; }
exit 0
STUB
    chmod +x "$_r/tools/run_replay_mame.sh"
    # the frozen basis: what a CLEAN run produces
    printf '1 CLEAN-BOOT-RUN\nEND 1\n' > "$_r/basis/logs/$NAME.log"
    printf '%s\n' "$MASK" > "$_r/basis/MASK"
}

# run the canary shape: VERIFY_BASIS=<name> AND <name> in the freeze list
run_canary() {
    _r="$1"
    ( cd "$_r" && ROMDIR=/nonexistent VERIFY_BASIS="$NAME" \
        tools/freeze_masked_basis.sh basis "$MASK" "$NAME" ) \
        > "$_r/out.txt" 2>&1 || true
}

echo "=== 1. the documented canary must not rewrite the basis it verifies"
mk_repo "$W/fixed" "$SRC/freeze_masked_basis.sh"
run_canary "$W/fixed"
sed 's/^/    /' "$W/fixed/out.txt"
if ! grep -q "bit-for-bit" "$W/fixed/out.txt"; then
    echo "  FAIL: the instrument control did not report a bit-for-bit match"; fail=1
fi
if grep -q "DIRTY-EEPROM-RUN" "$W/fixed/basis/logs/$NAME.log"; then
    echo "  FAIL: the basis log now carries a DIRTY-sandbox run — freeze_one"
    echo "        reused the verify leg's sandbox and overwrote the baseline"
    fail=1
else
    echo "  ok: basis log still the CLEAN-boot content"
fi

echo "=== 2. a fresh sandbox is used for every run (positive control)"
# The stub only ever reports CLEAN when its sandbox is fresh, so a green
# section 1 already proves it — but assert the tool actually RAN, or an
# early exit would pass section 1 by doing nothing.
if ! grep -q "BASIS FROZEN" "$W/fixed/out.txt"; then
    echo "  FAIL: the tool did not reach the freeze step — section 1 would"
    echo "        pass vacuously (nothing written cannot be wrong)"; fail=1
else
    echo "  ok: the tool ran to completion and still left the basis intact"
fi

echo "=== 3. verdict control: the PRE-FIX tool must fail section 1"
mkdir -p "$W/prefix"
# reconstruct the pre-fix tool by removing the sandbox clear
sed '/rm -rf "\$WORK\/sb_\${_n}_\$_i"/d' "$SRC/freeze_masked_basis.sh" \
    > "$W/prefix/freeze_masked_basis.sh"
if cmp -s "$W/prefix/freeze_masked_basis.sh" "$SRC/freeze_masked_basis.sh"; then
    echo "  FAIL: could not reconstruct a pre-fix tool — the sandbox clear is"
    echo "        not where this control expects it; re-point the sed"; fail=1
else
    mk_repo "$W/broken" "$W/prefix/freeze_masked_basis.sh"
    run_canary "$W/broken"
    if grep -q "DIRTY-EEPROM-RUN" "$W/broken/basis/logs/$NAME.log"; then
        echo "  ok: pre-fix tool reproduces the defect (basis overwritten with"
        echo "      a dirty-sandbox run, after reporting bit-for-bit)"
        grep -q "bit-for-bit" "$W/broken/out.txt" \
            && echo "  ok: ...and it did report bit-for-bit first — the guards are blind to it"
    else
        echo "  FAIL: pre-fix tool did NOT reproduce the defect — this gate is"
        echo "        not testing what it claims (a control that cannot fail"
        echo "        is a decoration)"; fail=1
    fi
fi

echo
[ "$fail" = 0 ] && echo "FREEZE-BASIS SANDBOX: PASS" || echo "FREEZE-BASIS SANDBOX: FAIL"
exit "$fail"
