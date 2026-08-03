#!/bin/sh
# test_fbneo_instruments.sh — ground truth for the B5b FBNeo instruments.
#
# WHY: FBNeo is the PRIMARY target (the GGPO rollback-netplay reference), yet
# until B5b the oracle had far better debugging instruments than the platform
# players actually use. "Who wrote this address?" — the question that
# dominates reverse engineering — could only be answered on MAME.
#
# Three instruments, all frontend-only (Rule 1): no emulation-core file is
# touched, only the public 68k interface (SekMapHandler / SekSetWrite*Handler
# / SekGetPC) and the CPS RAM pointers.
#   FBNEO_HTAP   write tap with PC attribution
#   FBNEO_HPOKE  frame-scheduled pokes
#   FBNEO_DUMPS  now resolves by ADDRESS, so it reaches OBJ RAM ($708000) and
#                palette RAM ($900000), not just work RAM
#
# Each is tested the way this project requires rather than by "it ran":
#   1. NON-PERTURBATION — a tapped run must be checksum-identical to an
#      untapped one. The tap replaces direct memory mapping with a handler
#      that has to write through faithfully; a wrong write-through would
#      corrupt the game, so this is the gate that makes the tap trustworthy.
#   2. POSITIVE CONTROLS — an instrument that reports nothing proves nothing
#      (the B4 vacuous-relocation lesson). The tap must capture writes, and
#      the poke must actually change state.
#   3. ORACLE CROSS-CHECK — the region dumps are compared BYTE-FOR-BYTE
#      against MAME dumping the same region, which independently validates
#      both the region resolution and the ^1 byte-order swap (docs/GOTCHAS.md
#      entry #1). Run at a frame where the region is stable across the known
#      MAME/FBNeo frame skew, so a match cannot be a timing coincidence.
#
# Usage: ROMDIR=... [MAME_BIN=...] tests/test_fbneo_instruments.sh
set -eu
ROMDIR="${ROMDIR:?set ROMDIR}"
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
RPL="tests/replays/02_demitri_vs_cpu.rpl"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
fail=0

echo "== 1. write tap: NON-PERTURBING =="
tools/run_replay_fbneo.sh vsavj "$RPL" "$WORK/plain.log" "$WORK/s1" >/dev/null 2>&1
FBNEO_HTAP="ff8000-ff80ff" tools/run_replay_fbneo.sh vsavj "$RPL" \
    "$WORK/tap.log" "$WORK/s2" >/dev/null 2>&1
if cmp -s "$WORK/plain.log" "$WORK/tap.log"; then
    echo "  ok: tapped run is checksum-identical to the untapped run"
else
    echo "  FAIL: the tap perturbed emulation — write-through is wrong"
    diff "$WORK/plain.log" "$WORK/tap.log" | head -3
    fail=1
fi

echo "== 2. write tap: POSITIVE CONTROL (must capture writes, with PCs) =="
n=$(awk '/^[0-9]/' "$WORK/tap.log.tap" 2>/dev/null | wc -l | tr -d ' ')
if [ "${n:-0}" -gt 1000 ]; then
    echo "  ok: $n write events captured with PC attribution"
else
    echo "  FAIL: only ${n:-0} events — the tap is not seeing writes"
    fail=1
fi

echo "== 3. write tap: RE-DERIVES A KNOWN FINDING =="
# STATE 14z-49 mapped the in-fight HUD pipeline on MAME: per-char records land
# at RAM:$FF5D94, staged by routines at PRG:0x89370 (mugshot) and 0x8939C.
# The FBNeo tap must independently land on those same routines.
FBNEO_HTAP="ff5d94-ff5d9f" tools/run_replay_fbneo.sh vsavj "$RPL" \
    "$WORK/hud.log" "$WORK/s3" >/dev/null 2>&1
pcs=$(awk '/^[0-9]/ { print $5 }' "$WORK/hud.log.tap" | sort -u | sed 's/pc=//' | tr '\n' ' ')
hit370=$(echo "$pcs" | tr ' ' '\n' | awk '/^0893(7|8)/' | wc -l | tr -d ' ')
hit39c=$(echo "$pcs" | tr ' ' '\n' | awk '/^0893(a|b)/' | wc -l | tr -d ' ')
echo "  distinct writer PCs: $pcs"
if [ "$hit370" -gt 0 ] && [ "$hit39c" -gt 0 ]; then
    echo "  ok: lands on the documented stagers 0x89370 ($hit370 PCs) and 0x8939C ($hit39c PCs)"
    echo "      (refinement: the emitter 0x1BB3C does NOT write these records —"
    echo "       the stagers do. Measured here, consistent with STATE 14z-49.)"
else
    echo "  FAIL: does not reproduce the documented HUD stager addresses"
    fail=1
fi

echo "== 4. pokes: POSITIVE CONTROL (must change state, at the right frame) =="
FBNEO_HPOKE="2000:ff8100:deadbeef" tools/run_replay_fbneo.sh vsavj "$RPL" \
    "$WORK/poke.log" "$WORK/s4" >/dev/null 2>&1
if cmp -s "$WORK/plain.log" "$WORK/poke.log"; then
    echo "  FAIL: the poke changed nothing — vacuous"
    fail=1
else
    first=$(diff "$WORK/plain.log" "$WORK/poke.log" | awk '/^< [0-9]/ { print $2; exit }')
    if [ "$first" = "2000" ]; then
        echo "  ok: state changed, first divergence exactly at the poked frame 2000"
    else
        echo "  FAIL: diverged at frame $first, expected 2000"
        fail=1
    fi
fi

echo "== 5. region dumps: ORACLE CROSS-CHECK (byte order + resolution) =="
MB="${MAME_BIN:-$HOME/.cache/vampire-saved/mame-ref/cps2}"
if [ ! -x "$MB" ]; then
    echo "  SKIPPED: no MAME binary at $MB — the cross-check IS the validation"
    echo "           of the ^1 byte-order swap, so this is not cosmetic."
    skipped=1
else
    mkdir -p "$WORK/m"
    DUMPS="2599:900000-90003f;2600:900000-90003f;2601:900000-90003f" \
        MAME_BIN="$MB" tools/run_replay_mame.sh vsavj "$RPL" \
        "$WORK/m/r.log" "$WORK/sbm" >/dev/null 2>&1
    FBNEO_DUMPS="2600:900000-90003f;2600:708000-70803f" \
        tools/run_replay_fbneo.sh vsavj "$RPL" "$WORK/f.log" "$WORK/s5" >/dev/null 2>&1
    # Stability first: if the region moves across the skew window a match
    # would be luck, and a mismatch would be uninterpretable.
    if cmp -s "$WORK/m/dump_2599_900000.bin" "$WORK/m/dump_2601_900000.bin"; then
        if cmp -s "$WORK/m/dump_2600_900000.bin" "$WORK/f.log.dump_2600_900000.bin"; then
            echo "  ok: palette \$900000 byte-identical to MAME (region stable across the skew)"
        else
            echo "  FAIL: palette dump differs from MAME — byte order or region resolution wrong"
            fail=1
        fi
    else
        echo "  SKIPPED: palette not stable across frames 2599-2601 on this replay"
    fi
    # OBJ RAM must at least RESOLVE (unresolved addresses emit 0xFF fill).
    if [ -s "$WORK/f.log.dump_2600_708000.bin" ] &&
       ! xxd -p "$WORK/f.log.dump_2600_708000.bin" | tr -d '\n' | grep -qE '^f+$'; then
        echo "  ok: OBJ RAM \$708000 resolves to real content (not 0xFF fill)"
    else
        echo "  FAIL: OBJ RAM dump is 0xFF fill — the address did not resolve"
        fail=1
    fi
fi

echo
[ "$fail" = 0 ] || { echo "FAIL: FBNeo instrument self-check"; exit 1; }
if [ -n "${skipped:-}" ]; then
    echo "PARTIAL: instruments work, but the oracle cross-check did not run."
    exit 2
fi
echo "PASS: FBNeo instrument self-check — the write tap is non-perturbing and"
echo "      re-derives a known MAME finding, pokes change state at the named"
echo "      frame, and region dumps agree with the oracle byte-for-byte."
