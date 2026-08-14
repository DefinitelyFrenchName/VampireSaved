#!/bin/sh
# audit_trap_parity.sh — the Plasma Trap SOUND parity A/B (14z-85g):
# the same far/timer replay on native vsav2 and on the build, trap-event
# ring-id inventories compared against the frozen measurement.
# On-demand, ~5 min (2 MAME runs, parallel).
#
# THE MEASURED MECHANISM THIS FREEZES (14z-85g, both halves):
# native vs2 fires per trap attempt: id 0x0739 at the mine SPAWN
# (throw+15f, per-node record node 10), 0x010B, then 0x073A at the
# TIMER DETONATION (the sound-farm stub vs2 0x4F2E, jsr'd from the
# mine handler x068458+0x120 — NOT the record path).
# OUR build (huitzil-m9+):
#  - DETONATION RESTORED: 0x73A's sample content is byte-identical in
#    both games' QSound images (0x6C0000, bank 108, 0-20480, pitch
#    12548) — vsavj keys it as 0x199/0x499. The hui recon overlay's
#    0x4F2E row (was stubbed_sound -> rts, the 14z-65 blanket 0x7xx
#    silence) is now kind=sound_stub sfx_id=0x199: a synthesized
#    vsavj twin stub. The detonation chirp fires SYSTEMATICALLY.
#  - EJECTION RESTORED (14z-86, huitzil-m11, the M5 pilot): record
#    node 10 remapped 0x739 -> 0xD8, an AUTHORED Z80 song row
#    (build/manifest/qs_songs.toml via tools/build_qs_songs.py): vs2's
#    one-note song copied verbatim at a free vsavj id; its sample
#    content is byte-identical in vsav's own image (0x18D800 = vsavj
#    record #0x5C = note-table-1 entry 0x28), so no sample port. The
#    +0x300 helper alias lands on the authored twin 0x3D8 (mirrors
#    native's 0xA39). Keyon A/B measured matching native (voice 11/12,
#    0x2800 window). OURS_EXPECT re-frozen deliberately with 00d8 in
#    the 0739 slot of BOTH windows — the re-freeze this header
#    anticipated since m9.
#
# ALSO LOCKED: ours MUST NOT enqueue 0x0739/0x073A (on vsavj they are
# music — their appearance would BE the music bug), and the periodic
# ambient id 0x049A must be present on both legs (ring liveness; note
# 14z-82d misattributed it as the detonation — RETRACTED 14z-85g, its
# ~144-frame cadence starts pre-trap).
#
# The 0x010A-vs-0x010B delta (ours/native) is a shared-library id pair
# (same content, relocated banks) reached through a per-char engine row
# — the defense-rows class, cosmetic, recorded not gated.
#
# Usage: ROMDIR=... tests/audit_trap_parity.sh [builddir]
set -eu
ROMDIR="${ROMDIR:?set ROMDIR}"
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
BUILD="${1:-build/hui38}"
[ -d "$BUILD/rompath" ] || { echo "SKIP: no build at $BUILD"; exit 0; }
WIDE_BIN="${MAME_BIN:-$HOME/.cache/vampire-saved/mame/cps2}"
[ -x "$WIDE_BIN" ] || { echo "SKIP: no WIDE MAME binary"; exit 0; }
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT
abspath() { case "$1" in /*) echo "$1";; *) echo "$PWD/$1";; esac; }

RPL="$PWD/tests/replays/hui/87_hui_plasma_trap.rpl"
PK="1400:ff8782:10;1450:ff8782:10;1500:ff8782:10;1400:ff8b82:03;1450:ff8b82:03;1500:ff8b82:03"

BUILD_RP="$(abspath "$BUILD")/rompath"
mkdir -p "$W/ours" "$W/native"
( cd "$W/ours" && REPLAY="$RPL" FRAMES=5000 POKES="$PK" \
  TRACE_OUT=ring.txt MAME_SANDBOX="$W/ours/sb" \
  MAME_BIN="$WIDE_BIN" MAME_ROMPATH="$BUILD_RP;$ROMDIR" \
  "$REPO/tools/run_mame.sh" vsavjw \
  -autoboot_script "$REPO/tests/lua/ring_tap.lua" >out 2>&1 ) &
( cd "$W/native" && REPLAY="$RPL" FRAMES=5000 POKES="$PK" \
  TRACE_OUT=ring.txt MAME_SANDBOX="$W/native/sb" \
  "$REPO/tools/run_mame.sh" vsav2 \
  -autoboot_script "$REPO/tests/lua/ring_tap.lua" >out 2>&1 ) &
wait
for leg in ours native; do
    [ -s "$W/$leg/ring.txt" ] || {
        echo "FAIL: $leg leg produced no ring log — emulator output:"
        tail -15 "$W/$leg/out" 2>/dev/null
        exit 1
    }
done

python3 - "$W" <<'PY'
import re, sys
W = sys.argv[1]

# Frozen trap-event inventories (14z-85g measurement, replay 87, two
# attempts at f3416/f4216): event ids inside the two attempt windows,
# ambient 0x049A excluded. Native re-derives the reference every run.
WINDOWS = [(3400, 3900), (4200, 4700)]
# Per-window frozen inventories (both windows measured, not assumed
# equal — ours' attempt 2 also carries an 0117/00f3 pair, an ordinary
# engine event on that leg's timeline).
NATIVE_EXPECT = [["0739", "010b", "073a"], ["0739", "010b", "073a"]]
OURS_EXPECT   = [["00d8", "010a", "0199"],
                 ["00d8", "010a", "0199", "0117", "00f3"]]
# ours: 00d8 = the RESTORED ejection (14z-86 authored Z80 song, the
# 0739 slot); 0199 = the RESTORED detonation chirp (vsavj id for
# 0x73A's content); 010a-vs-010b is the recorded per-char-row
# cosmetic delta
FORBIDDEN_OURS = {"0739", "073a"}             # music on vsavj — never

def parse(leg):
    ids = []
    for line in open(f"{W}/{leg}/ring.txt"):
        m = re.match(r"f(\d+) id ([0-9a-f]{4}) pc", line)
        if m: ids.append((int(m.group(1)), m.group(2)))
    return ids

def verdict(ids, expect, leg):
    errs = []
    ambient = [f for f, i in ids if i == "049a"]
    if len(ambient) < 5:
        errs.append(f"{leg}: ambient 0x049A x{len(ambient)} (<5) — ring "
                    "tap not live or match never formed; verdict vacuous")
        return errs
    for (wa, wb), want in zip(WINDOWS, expect):
        ev = [i for f, i in ids if wa <= f <= wb and i != "049a"
              and i not in ("0000", "ffff")]
        if ev != want:
            errs.append(f"{leg}: attempt window {wa}-{wb} event ids {ev}, "
                        f"frozen {want}")
    if leg == "ours":
        bad = [i for _, i in ids if i in FORBIDDEN_OURS]
        if bad:
            errs.append(f"ours: FORBIDDEN ids {bad} enqueued — on vsavj "
                        "these key MUSIC content (the retrigger class); "
                        "a fix must use NEW ids, never these")
    return errs

errs = []
native = parse("native"); ours = parse("ours")
errs += verdict(native, NATIVE_EXPECT, "native")
errs += verdict(ours, OURS_EXPECT, "ours")
if not errs:
    print("  ok: native fires 0739/010b/073a per attempt; ours fires the")
    print("      RESTORED ejection 00d8 (the 0739 slot, authored Z80 song)")
    print("      + 010a + the RESTORED detonation chirp 0199")

# Verdict-logic control: the checker on a mutated inventory MUST fail.
mut = [(f, ("0111" if i == "0199" else i)) for f, i in ours]
if not verdict(mut, OURS_EXPECT, "ours"):
    errs.append("control PASSED with a mutated inventory — verdict logic "
                "is not checking the ids")
else:
    print("  ok: verdict control — mutation fails as designed")

for e in errs: print("FAIL:", e)
sys.exit(1 if errs else 0)
PY
rc=$?
[ "$rc" = 0 ] && echo "audit_trap_parity: PASS (restored ejection+detonation state holds)" \
             || echo "audit_trap_parity: FAILURES"
exit "$rc"
