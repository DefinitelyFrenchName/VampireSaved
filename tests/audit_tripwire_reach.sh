#!/bin/sh
# audit_tripwire_reach.sh — DO ANY PLANTED TRIPWIRES FIRE IN EXTENDED PLAY?
# (14z-93, on-demand, ~15 min at JOBS=3.)
#
# WHAT A TRIPWIRE IS. Every shipped build is generated with
# `--tripwire-open`, whose own help text is the point:
#
#     route refs with missing/open reconciliation rows to per-target
#     planted-ILLEGAL tripwires INSTEAD OF FAILING — the guard's fault PC
#     then names exactly which unresolved target actually fires
#
# So a planted `4AFC` is an UNRECONCILED REFERENCE, deferred rather than
# resolved. It is loud by design: if the path is ever taken, the machine
# dies at an address whose patch-fragment line names the vs2 target. The
# frozen builds carry dozens each (measured 14z-93: huitzil-m15 52,
# pyron-m9 31, donovan-m7 36, merged-m1 70).
#
# WHY THIS AUDIT EXISTS. Nothing measured whether any of them is REACHABLE.
# The suite's tenant rigs are short, single-match and move-focused; the
# maintainer's playtests are long but unscripted. Neither answers "does
# ordinary extended play take one of these paths". 14z-93 ran the longest
# rig in the corpus — `26_don_arcade_mash`, a 40,620-frame single-credit
# arcade marathon through several CPU matches and every transition — with
# the tenant forced, and the answer was YES:
#
#     hui41       CRASH 14767 vec4 PC 0fb6e0  -> unresolved vs2 0x494de
#     m3b_merged8 CRASH  8887 vec4 PC 456930  -> the SAME target, earlier
#
# `0x494de` is a 32-bit software divide helper (shift/compare/subtract,
# dbf x32), called from ELEVEN sites in vs2, and vsavj carries the
# byte-identical routine at `0x47fb6`. So it is a MISSING RECONCILIATION
# ROW, not a missing feature — and it is reachable on the shipping build.
#
# RULE 6 APPLIES ("failing regression halts forward work"): this audit
# FAILS on any fire. It does not tolerate, classify or count them down.
#
# THE RIG MATTERS AND IS THE HONEST LIMIT. A tenant's tripwires can only
# fire while the tenant is playing, so the forced pick is mandatory
# (`26_don_arcade_mash` picks a legacy character on its own — that is why
# it is a LEGACY pairing and why 14z-92 measured 228 hit-class map entries
# on it without ever touching a tenant). A PASS here means "no tripwire
# fired on THIS rig", never "no tripwire is reachable".
#
# Usage: ROMDIR=... [MAME_BIN=...] [JOBS=3] [TRIPWIRE_BUILDS="dir:id ..."]
#        [TRIPWIRE_REPLAY=26_don_arcade_mash] tests/audit_tripwire_reach.sh
#
# HANDOFF's gate-index note, moved into this header 14z-123 (verbatim; the
# documentation pass ruled a gate's WHY lives in the gate):
#   14z-93 (GitHub #91) ON-DEMAND (~15 min, JOBS=3): DO ANY PLANTED TRIPWIRES
#   FIRE IN EXTENDED PLAY? Every build carries --tripwire-open, which routes
#   UNRECONCILED refs to planted ILLEGALs instead of failing (huitzil-m15 52,
#   pyron-m9 31, donovan-m7 36, merged-m1 70). Nothing had measured whether
#   any is REACHABLE. Runs the 40,620-frame arcade marathon 26_don_arcade_mash
#   with the tenant FORCED (it picks a legacy character on its own — that is
#   why this was invisible) on each frozen build. MEASURED: hui41 CRASH 14767
#   and m3b_merged8 CRASH 8887, both the tripwire for unresolved 0x494de (a
#   32-bit DIVIDE helper; vsavj has the byte-identical routine at 0x47fb6);
#   pyron/donovan legs clean. Resolves the faulting PC to its fragment line so
#   the report NAMES the target. FAILS on any fire (rule 6) — never counts
#   them down. Honest limit in the header: a PASS is RIG-BOUNDED
set -eu
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
ROMDIR="${ROMDIR:?set ROMDIR}"
MAME_BIN="${MAME_BIN:-$HOME/.cache/vampire-saved/mame/cps2}"
export MAME_BIN
JOBS="${JOBS:-3}"
RPL="${TRIPWIRE_REPLAY:-26_don_arcade_mash}"
# dir:tenant-id. Frozen builds by default — this asks about what SHIPS.
# Defaults re-pointed 14z-100 to the CURRENT freeze (donovan-m9 /
# huitzil-m18 / pyron-m12 / merged-m4). They were still the pre-14z-94
# artifacts, so the 113 tripwires in the shipping merged build had ZERO
# reachability measurement — the exact staleness class this audit was
# built to catch (#91). RE-POINT AT EVERY FREEZE.
BUILDS="${TRIPWIRE_BUILDS:-build/hui52:10 build/pyron36:11 build/don_m18:13 build/m3b_merged21:10 build/m3b_merged21:11 build/m3b_merged21:13}"  # re-pointed 14z-117b (random-select freeze) <- 14z-117  # re-pointed 14z-119 (physics-port freeze) <- 14z-117b

[ -x "$MAME_BIN" ] || { echo "SKIP: no WIDE MAME binary at $MAME_BIN"; exit 0; }
[ -f "tests/replays/$RPL.rpl" ] || { echo "FAIL: no replay $RPL"; exit 1; }

W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT
fail=0
abspath() { case "$1" in /*) echo "$1";; *) echo "$PWD/$1";; esac; }
pool=0
sync_pool() { pool=$((pool+1)); if [ "$pool" -ge "$JOBS" ]; then wait; pool=0; fi; }

echo "== rig: $RPL (forced pick, frozen builds) =="
n=0
for b in $BUILDS; do
    dir="${b%%:*}"; id="${b##*:}"
    [ -f "$dir/rompath/vsavjw.zip" ] || { echo "  SKIP $dir (no vsavjw.zip)"; continue; }
    tag="$(basename "$dir")_$id"
    n=$((n+1))
    mkdir -p "$W/$tag"
    ( POKES="1704:ff8782:$id;1760:ff8782:$id;1900:ff8782:$id;2100:ff8782:$id;2400:ff8782:$id" \
      MAME_ROMPATH="$(abspath "$dir")/rompath;$ROMDIR" \
        tools/run_replay_guarded.sh vsavjw "tests/replays/$RPL.rpl" \
        "$W/$tag/probe.log" "$W/$tag/sb" >/dev/null 2>&1 || true ) &
    sync_pool
done
wait
[ "$n" -gt 0 ] || { echo "FAIL: no build had a vsavjw.zip — nothing measured"; exit 1; }

for b in $BUILDS; do
    dir="${b%%:*}"; id="${b##*:}"; tag="$(basename "$dir")_$id"
    log="$W/$tag/probe.log"
    [ -f "$log" ] || continue
    if ! grep -qE "^(END |CRASH |END-CRASH |PCWEEDS |SOFTRESET )" "$log"; then
        echo "  DEAD: $tag — the run produced no verdict line; not a measurement"
        fail=1; continue
    fi
    if grep -q "^CRASH " "$log"; then
        line="$(grep -m1 '^CRASH ' "$log")"
        pc="$(printf '%s' "$line" | sed -n 's/.*PC \([0-9a-f]*\).*/\1/p')"
        # Name the unresolved TARGET, not just the address — the fragment
        # line is the whole bug report and saves a manual lookup.
        who="$(grep -i "0x0*$pc ILLEGAL  TRIPWIRE" \
               "$dir/patch/patch_notes_fragment.md" 2>/dev/null | head -1)"
        echo "  FAIL: $tag — $line"
        if [ -n "$who" ]; then
            echo "        $who"
            echo "        => an UNRECONCILED reference is reachable in play."
            echo "           Resolve it (a reconciliation row) — do not widen"
            echo "           anything and do not remove the tripwire."
        else
            echo "        (PC is not a planted tripwire — this is an ordinary"
            echo "         crash, and a worse finding. Root-cause it first.)"
        fi
        fail=1
    else
        echo "  ok: $tag — $(grep -m1 '^END ' "$log")"
    fi
done

echo
if [ "$fail" = 0 ]; then
    echo "PASS: no planted tripwire fired on $RPL for any measured build."
    echo "      This is rig-bounded: it says nothing about paths $RPL never"
    echo "      takes. Widen the rig, never the tolerance."
else
    echo "FAIL: a planted tripwire is REACHABLE on a shipping build."
    echo "      Rule 6 — fixing this is the only task until green."
fi
exit "$fail"
