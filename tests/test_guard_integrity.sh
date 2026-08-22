#!/bin/sh
# test_guard_integrity.sh — the crash guard must carry the input-integrity
# assertion, and must refuse env vars it does not implement (14z-94,
# GitHub #31). Needs ROMDIR + a WIDE build; ~2 min.
#
# WHY. replay_guard.lua's header advertised "same env contract ... can
# substitute for replay.lua in any gate". Two things made that false:
#
#   (a) MASK_RANGES was read by NOBODY here. A masked comparison run through
#       the guard produced a whole-work-RAM log with the ratified windows
#       still in it; against a masked basis that diverges in the dead-stack
#       window on every hooked build, i.e. a phantom legacy regression with no
#       reachable green state.
#   (b) ~17 gates drive replays through this script — test_hui_grab,
#       audit_merged_legacy leg b, audit_objhook_owner_census and the rest —
#       and every one ran with NO input-integrity check, while
#       run_replay_guarded.sh grepped only for CRASH/PCWEEDS/SOFTRESET/END.
#       A stray host press therefore produced a clean PASS on a run that was
#       no longer a replay of anything. MAME's window takes focus even under
#       -video none (see tests/test_input_integrity.sh).
#
# The fix refuses (a) loudly and implements (b). This gate proves both,
# because a silent check and an absent one look identical from the outside.
set -eu
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
ROMDIR="${ROMDIR:?set ROMDIR}"
MAME_BIN="${MAME_BIN:-$HOME/.cache/vampire-saved/mame/cps2}"
export MAME_BIN
BUILD="${GUARD_BUILD:-build/hui47}"
RPL="${GUARD_REPLAY:-tests/replays/11_pick_donovan.rpl}"
[ -x "$MAME_BIN" ] || { echo "SKIP: no WIDE MAME binary at $MAME_BIN"; exit 0; }
[ -f "$BUILD/rompath/vsavjw.zip" ] || { echo "SKIP: no $BUILD/rompath/vsavjw.zip"; exit 0; }

T="$(mktemp -d)"; trap 'rm -rf "$T"' EXIT INT TERM
RP="$PWD/$BUILD/rompath;$ROMDIR"
rc=0
fail() { echo "  FAIL: $*"; rc=1; }

echo "== 1. a clean guarded run is SILENT on integrity =="
GUARD_DEBUG=0 MAME_ROMPATH="$RP" \
  tools/run_replay_guarded.sh vsavjw "$RPL" "$T/clean.log" "$T/sb1" \
  > "$T/clean.out" 2>&1 && crc=0 || crc=$?
if [ "$crc" != 0 ]; then
    fail "a clean run tripped the guard (rc=$crc):"; sed 's/^/        /' "$T/clean.out"
elif grep -q "INPUT-VIOLATION" "$T/clean.log"; then
    fail "a clean run reported an input violation — false positives make the"
    fail "      check unusable, which is how it gets disabled"
elif ! grep -q "^END " "$T/clean.log"; then
    fail "the clean run produced no END line"
else
    echo "  ok: clean run completed, no violation ($(grep -m1 '^END ' "$T/clean.log"))"
fi

echo "== 2. THE CONTROL — an injected press must be CAUGHT and must TRIP =="
# INPUT_INJECT_TEST fakes one phantom controller bit at the named frame. If
# this passes silently the check is decorative.
INPUT_INJECT_TEST=200 GUARD_DEBUG=0 MAME_ROMPATH="$RP" \
  tools/run_replay_guarded.sh vsavjw "$RPL" "$T/inj.log" "$T/sb2" \
  > "$T/inj.out" 2>&1 && irc=0 || irc=$?
if [ "$irc" = 0 ]; then
    fail "the injected press did NOT trip the runner — a stray host press"
    fail "      would still yield a clean PASS"
elif ! grep -q "^INPUT-VIOLATION 200 " "$T/inj.log"; then
    fail "no INPUT-VIOLATION line at the injected frame; log says:"
    grep -E "^(INPUT|CRASH|END)" "$T/inj.log" | sed 's/^/        /'
else
    echo "  ok: caught — $(grep -m1 '^INPUT-VIOLATION' "$T/inj.log")"
    echo "  ok: and the runner tripped on it (rc=$irc)"
fi

echo "== 3. the runner's trip set actually greps for it =="
# Section 2 could pass on a runner that trips for some other reason; this
# pins the mechanism.
if grep -q "INPUT-VIOLATION" tools/run_replay_guarded.sh; then
    echo "  ok: run_replay_guarded.sh greps INPUT-VIOLATION"
else
    fail "the runner does not grep INPUT-VIOLATION — the line would be written"
    fail "      to the log and never read, which is the same silent PASS"
fi

echo "== 4. env vars the guard does not implement are REFUSED, not ignored =="
for v in MASK_RANGES NO_INPUT_CHECK; do
    case $v in
        MASK_RANGES)    val="043c-043d" ;;
        NO_INPUT_CHECK) val="1" ;;
    esac
    env "$v=$val" GUARD_DEBUG=0 MAME_ROMPATH="$RP" \
      tools/run_replay_guarded.sh vsavjw "$RPL" "$T/$v.log" "$T/sb_$v" \
      > "$T/$v.out" 2>&1 && vrc=0 || vrc=$?
    if [ "$vrc" = 0 ]; then
        fail "$v was ACCEPTED — the guard ignores it and the log's meaning"
        fail "      silently changes"
    elif grep -qi "does not implement MASK_RANGES\|NO_INPUT_CHECK is replay.lua" "$T/$v.out"; then
        echo "  ok: $v refused, by name"
    else
        fail "$v failed for an UNNAMED reason — this control would pass on any"
        fail "      unrelated breakage:"; head -3 "$T/$v.out" | sed 's/^/        /'
    fi
done

echo
if [ "$rc" = 0 ]; then
    echo "PASS: the guard checks inputs, and refuses what it cannot honour."
else
    echo "FAIL: see above."
fi
exit $rc
