#!/bin/sh
# audit_stock_emulator_stall.sh — the WIDE romset FORCED into an UNPATCHED MAME (renamed to
# vsavj.zip) boots, prints WRONG CHECKSUMS, and STALLS on the QSound legal screen without a
# crash: RAM identical to the real WIDE run through frame 468, divergent from 469, no crash
# vector, no gameplay. This is the README's "if it does not work" diagnostic, measured.
# mame (the WIDE binary AND the stock reference binary), ~1 min (three MAME runs).
#
# MUST-FIRE: known-bad: wide-binary-no-stall — the same replay on the PATCHED binary with the real set must NOT diverge from itself at the frozen frame: under the mode the "stock" leg is the WIDE binary on the real set, so the divergence is absent and this gate must FAIL
#
# WHY. A user who renames vsavjw.zip to force it into a stock emulator sees a legal screen
# forever and reports "it hangs". The release README says what that means (measured
# 2026-09-11, STATE 14z-148); this gate keeps the claim true across freezes — if a future
# build crashed, garbled, or PLAYED wrong on a stock emulator instead, the README line
# would be false and this fails. The frozen divergence frame is where the stock descriptor's
# missing extension first reaches RAM; it moves only if boot-time code moves.
#
# Usage: ROMDIR=... [MERGED=build/m3b_merged26] [MAME_REF_BIN=~/.cache/vampire-saved/mame-ref/cps2]
#        tests/audit_stock_emulator_stall.sh
#   defaults build/m3b_merged26 (re-pointed 14z-148 at M18); the reference binary is the
#   WIDE=0 build of tools/setup_mame.sh. MAME_BIN (the WIDE binary) as every MAME gate.
set -eu
ROMDIR="${ROMDIR:?set ROMDIR}"
REPO="$(cd "$(dirname "$0")/.." && pwd)"; cd "$REPO"
ROMDIR="$(cd "$ROMDIR" && pwd)"
. "$REPO/tests/lib/controls.sh"; vs_ctl_mode "$0"
MERGED="${MERGED:-build/m3b_merged26}"
REF="${MAME_REF_BIN:-$HOME/.cache/vampire-saved/mame-ref/cps2}"
WIDE="${MAME_BIN:-$HOME/.cache/vampire-saved/mame/cps2}"
[ -f "$MERGED/rompath/vsavjw.zip" ] || { echo "SKIP: $MERGED/rompath/vsavjw.zip missing"; exit 0; }
[ -x "$REF" ] || { echo "SKIP: reference MAME $REF missing (WIDE=0 tools/setup_mame.sh)"; exit 0; }
[ -x "$WIDE" ] || { echo "SKIP: WIDE MAME $WIDE missing (tools/setup_mame.sh)"; exit 0; }
"$REF" -listfull vsavjw 2>/dev/null | grep -q vsavjw && { echo "FAIL: $REF knows vsavjw — it is not the STOCK reference binary"; exit 1; }
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT INT TERM
RPL=tests/replays/16_xemu_2p.rpl
FROZEN_DIVERGE=469     # measured 2026-09-11 on merged-m18, identical on three replays
mkdir -p "$W/rp"; cp "$MERGED/rompath/vsavjw.zip" "$W/rp/vsavj.zip"

# leg A: the real WIDE run (patched binary, the real set)
MAME_BIN="$WIDE" MAME_ROMPATH="$REPO/$MERGED/rompath;$ROMDIR" GUARD_DEBUG=0 \
    tools/run_replay_guarded.sh vsavjw "$RPL" "$W/wide.log" "$W/sb_wide" > "$W/wide.out" 2>&1 || true
# leg B: the STOCK binary on the renamed set (under the mode: the WIDE binary on the real set,
# so B == A and the divergence the gate demands is ABSENT — its own FAIL)
if vs_ctl_is wide-binary-no-stall; then
    MAME_BIN="$WIDE" MAME_ROMPATH="$REPO/$MERGED/rompath;$ROMDIR" GUARD_DEBUG=0 \
        tools/run_replay_guarded.sh vsavjw "$RPL" "$W/stock.log" "$W/sb_stock" > "$W/stock.out" 2>&1 || true
else
    MAME_BIN="$REF" MAME_ROMPATH="$W/rp;$ROMDIR" GUARD_DEBUG=0 \
        tools/run_replay_guarded.sh vsavj "$RPL" "$W/stock.log" "$W/sb_stock" > "$W/stock.out" 2>&1 || true
fi
# the control leg, always: the WIDE binary on the real set, a second time
MAME_BIN="$WIDE" MAME_ROMPATH="$REPO/$MERGED/rompath;$ROMDIR" GUARD_DEBUG=0 \
    tools/run_replay_guarded.sh vsavjw "$RPL" "$W/ctl.log" "$W/sb_ctl" > "$W/ctl.out" 2>&1 || true

fail=0
python3 - "$W/wide.log" "$W/stock.log" "$W/ctl.log" "$FROZEN_DIVERGE" <<'PY' || fail=1
import sys
def frames(p):
    d = {}
    for l in open(p, errors="replace"):
        t = l.split()
        if len(t) == 2 and t[0].isdigit(): d[int(t[0])] = t[1]
    return d
a, b, c = (frames(p) for p in sys.argv[1:4]); frozen = int(sys.argv[4])
def first_div(x, y):
    return next((f for f in sorted(set(x) & set(y)) if x[f] != y[f]), None)
print(f"  wide run {len(a)} frames, stock run {len(b)}, control {len(c)}")
if first_div(a, c) is not None:
    print(f"FAIL: the two WIDE legs differ at frame {first_div(a, c)} — the instrument is not deterministic, nothing below is evidence"); sys.exit(1)
print("  ok: the two WIDE legs are bit-identical (the instrument is sound)")
d = first_div(a, b)
if d != frozen:
    print(f"FAIL: stock-vs-wide first divergence at frame {d}, frozen {frozen} (None = no divergence: the 'stock' leg PLAYS the WIDE set)"); sys.exit(1)
print(f"  ok: the stock leg matches the WIDE run through frame {frozen-1} and diverges at {frozen} (the missing extension reaches RAM)")
tail = [b[f] for f in sorted(b)[-300:]]
if len(set(tail)) < 2:
    print("FAIL: the stock leg's RAM is FROZEN over its last 300 frames — a hang, not the measured stall"); sys.exit(1)
print(f"  ok: the stock leg keeps running ({len(set(tail))} distinct hashes over the last 300 frames)")
PY
for l in wide stock ctl; do
    if grep -aqE '^(CRASH|PCWEEDS|SOFTRESET|END-CRASH)' "$W/$l.log"; then echo "FAIL: $l leg raised a crash line: $(grep -aE '^(CRASH|PCWEEDS|SOFTRESET|END-CRASH)' "$W/$l.log" | head -1)"; fail=1; fi
    grep -aq '^END ' "$W/$l.log" || { echo "FAIL: $l leg has no END line"; fail=1; }
done
if vs_ctl_is wide-binary-no-stall; then :; else
    n="$(grep -ac 'WRONG CHECKSUMS' "$W/sb_stock/mame_guard.log" 2>/dev/null || echo 0)"
    [ "$n" = 8 ] && echo "  ok: the stock binary screamed WRONG CHECKSUMS on the 8 patched group-A members and booted anyway" \
        || { echo "FAIL: expected 8 WRONG CHECKSUMS lines from the stock binary, got $n"; fail=1; }
fi
[ "$fail" = 0 ] && echo "  ok: no crash vector on any leg — the failure mode is a STALL, not a crash and not gameplay" || true
# the control's readout (the mode above is its executable form)
if [ -n "$(grep -a '^469 ' "$W/wide.log")" ] && [ "$(grep -a '^469 ' "$W/wide.log")" = "$(grep -a '^469 ' "$W/ctl.log")" ]; then
    vs_ctl_fired wide-binary-no-stall "the WIDE binary on the real set has NO divergence at frame $FROZEN_DIVERGE from itself — the mode that swaps it in for the stock leg reaches this gate's FAIL"
else
    vs_ctl_dead wide-binary-no-stall "the two WIDE legs differ at the frozen frame" || fail=1
fi
[ "$fail" = 0 ] && echo "PASS: the WIDE set on an unpatched MAME boots, screams, and stalls on the legal screen (diverges at $FROZEN_DIVERGE, never crashes, never plays)" \
                || { echo "FAIL: see above"; exit 1; }
