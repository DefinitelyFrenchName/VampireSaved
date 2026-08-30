#!/bin/sh
# test_hui_electrocute.sh — PHOBOS AS THE ELECTROCUTE VICTIM, ours vs native
# vsav2 (14z-95). The consumer for tests/replays/hui/93_hui_electrocuted.rpl.
#
# WHY IT EXISTS. STATE recorded TWICE (14z-74, 14z-76) that "no existing
# replay produces an electrocute", so the effect-palette block's visibility
# had to be settled by playtest and the maintainer's 2026-08-18 sfx report had
# no instrument at all. This is that instrument.
#
# THE TRIGGER CAME FROM THE MAINTAINER AND IS NOT DERIVABLE FROM THE TREE:
# Victor's HELD HP — "the electrocuting version of his HP" — a CHARGEABLE
# NORMAL, not a special. Two traps are encoded here because both were paid
# for:
#
#   (a) THE CLASS IS 0x07, NOT 0x06. 0x06 is the REMAPPED TRAP DOME's route
#       into vsavj's electric-shake handler (14z-85g(2), audit_trap_shock).
#       Victor's own electrocuting HP carries class 0x07 with freeze ~0x2f. A
#       gate asserting 0x06 reports "no electrocute" forever while producing
#       one.
#   (b) A SHORT PRESS IS THE QUICK VERSION. The rig's first draft fired
#       236+HP for five frames. It CONNECTED on both legs — identical HP
#       288->275 at f3416 — and produced an ordinary hit (classes 0x00/0x04/
#       0x05, freeze 0x0a). A rig that lands a hit and reports clean is the
#       expensive kind of wrong, so section 2 keeps the quick press as a
#       standing NEGATIVE control: it must NOT install the shake.
#
# Also retired on the way, so nobody trusts the name: `tests/replays/
# 32_victor_shock_vsav2.rpl` does NOT produce a shock on native vs2 either
# (classes 0x00/0x05, freeze 0x0b, zero shake rows).
#
# WHAT THIS GATE DELIBERATELY DOES NOT ASSERT. The maintainer reports an EXTRA
# sound at the END of the electrocuted state. Measured whole-run, ours fires
# two ids native does not — 0x91 and 0x8e, both Phobos' OWN authored voices
# (vs2 0x749/0x746, "verbatim" rows in qs_voice_map.md) — but they land
# PRE-MATCH, not at the electrocute. And the native leg reaches Huitzil by
# poking +0x382, which 14z-87 proved is the VOICE-FLAVOR class in match
# (ram.md:85), so "native fires neither" may mean the native leg is not
# voicing as Huitzil at all. Until that confound is closed those two ids are a
# MEASUREMENT, not a finding, and freezing them here would ratify a possible
# rig artifact. Section 3 freezes only the ELECTROCUTE WINDOW, where the sole
# delta is the 010a/010b pair audit_trap_parity already records as cosmetic
# (same content, relocated banks, the defense-rows class).
#
# Usage: ROMDIR=... [BUILD=build/m3b_merged9] tests/test_hui_electrocute.sh
# ~2 min (4 MAME runs, parallel).
#
# HANDOFF's gate-index note, moved into this header 14z-123 (verbatim; the
# documentation pass ruled a gate's WHY lives in the gate):
#   14z-95: PHOBOS AS THE ELECTROCUTE VICTIM, ours vs native vsav2 — the
#   consumer for replay 93. STATE said TWICE (14z-74/76) that no replay
#   produced an electrocute; this is the first. TRIGGER FROM THE MAINTAINER,
#   not derivable from the tree: Victor's HELD HP, a CHARGEABLE NORMAL. TWO
#   PAID-FOR TRAPS ENCODED: (a) the class is 0x07, NOT 0x06 — 0x06 is the
#   remapped TRAP DOME's route into the same shake handler (14z-85g(2)), so a
#   gate on 0x06 reports "no electrocute" while producing one; (b) a SHORT
#   press is the QUICK version — the rig's first draft landed a hit (288->275
#   both legs) and produced an ordinary reaction, so the quick 6+HP is kept as
#   a standing NEGATIVE control. Section 3 freezes the ring inventory across
#   the electrocute window only, where the sole delta is the documented
#   010a/010b cosmetic pair. DELIBERATELY NOT ASSERTED: the two extra Phobos
#   voices (0x8e/0x91) measured PRE-match — a +0x382 poke confound is open on
#   the native leg, so freezing them would ratify a possible rig artifact. ~2
#   min
set -eu
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
ROMDIR="${ROMDIR:?set ROMDIR}"
BUILD="${BUILD:-build/m3b_merged21}"  # re-pointed 14z-117b (random-select freeze) <- 14z-117  # re-pointed 14z-119 (physics-port freeze) <- 14z-117b
[ -d "$BUILD/rompath" ] || { echo "SKIP: no build at $BUILD"; exit 0; }
MAME_BIN="${MAME_BIN:-$HOME/.cache/vampire-saved/mame/cps2}"
[ -x "$MAME_BIN" ] || { echo "SKIP: no WIDE MAME binary"; exit 0; }
export MAME_BIN

RPL="$REPO/tests/replays/hui/93_hui_electrocuted.rpl"
PK="1400:ff8782:10;1450:ff8782:10;1500:ff8782:10;1400:ff8b82:03;1450:ff8b82:03;1500:ff8b82:03"
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT
fail=0
ok()  { echo "  ok: $1"; }
bad() { echo "FAIL: $1"; fail=1; }

DF="$(python3 -c "print(';'.join(f'{f}:ff8400-ff85ff' for f in range(3380,4300,2)))")"
mkdir -p "$W/ours/s1" "$W/native/s1" "$W/ours_r" "$W/native_r"
( cd "$W/ours" && MAME_ROMPATH="$REPO/$BUILD/rompath;$ROMDIR" POKES="$PK" \
  DUMPS="$DF" FRAMES=4320 "$REPO/tools/run_replay_mame.sh" vsavjw "$RPL" ram.log s1 >out 2>&1 ) &
( cd "$W/native" && POKES="$PK" DUMPS="$DF" FRAMES=4320 \
  "$REPO/tools/run_replay_mame.sh" vsav2 "$RPL" ram.log s1 >out 2>&1 ) &
( cd "$W/ours_r" && REPLAY="$RPL" FRAMES=4320 POKES="$PK" TRACE_OUT=ring.txt \
  MAME_SANDBOX="$W/ours_r/sb" MAME_ROMPATH="$REPO/$BUILD/rompath;$ROMDIR" \
  "$REPO/tools/run_mame.sh" vsavjw -autoboot_script "$REPO/tests/lua/ring_tap.lua" >out 2>&1 ) &
( cd "$W/native_r" && REPLAY="$RPL" FRAMES=4320 POKES="$PK" TRACE_OUT=ring.txt \
  MAME_SANDBOX="$W/native_r/sb" \
  "$REPO/tools/run_mame.sh" vsav2 -autoboot_script "$REPO/tests/lua/ring_tap.lua" >out 2>&1 ) &
wait

echo "== 1-2: the shake installs on the HELD attempt and NOT on the quick one"
python3 - "$W" <<'PY' || exit 1
import glob, sys, struct
W = sys.argv[1]
# attempt windows, from the replay: held-HP f3400, 6+HP held f3700, quick f4000
ATT = {"held":(3400,3600), "fwd_held":(3700,3900), "quick":(4000,4290)}
SHAKE_CLASS, SHAKE_FREEZE = 0x07, 0x2f
rc = 0
for leg in ("native", "ours"):
    rows = []
    for f in sorted(glob.glob(f"{W}/{leg}/dump_*_ff8400.bin"),
                    key=lambda p: int(p.split("_")[-2])):
        fr = int(f.split("_")[-2]); v = open(f, "rb").read()
        rows.append((fr, struct.unpack(">H", v[0x50:0x52])[0], v[0x54], v[0x5C]))
    if not rows:
        print(f"FAIL: {leg} produced no dumps — rig dead, verdict vacuous"); rc = 1; continue
    seg = lambda a, b: [r for r in rows if a <= r[0] < b]
    held = [r for r in seg(*ATT["held"]) if r[2] == SHAKE_CLASS]
    if not held:
        cls = sorted({hex(r[2]) for r in seg(*ATT["held"]) if r[2]})
        print(f"FAIL: {leg} — held HP did NOT install the shake "
              f"(class {SHAKE_CLASS:#04x}); classes seen {cls}. Either the "
              f"spacing broke or the charge did not come out.")
        rc = 1
        continue
    frz = max(r[3] for r in held)
    if frz < SHAKE_FREEZE:
        print(f"FAIL: {leg} — shake class present but freeze {frz:#x} < "
              f"{SHAKE_FREEZE:#x}; that is a lighter reaction, not the electrocute")
        rc = 1
        continue
    print(f"  ok: {leg} — electrocute installs (class 0x07, freeze {frz:#x})")
    q = [r for r in seg(*ATT["quick"]) if r[2] == SHAKE_CLASS]
    if q:
        print(f"FAIL: {leg} — the QUICK 6+HP control also installed the shake. "
              f"The control is what proves the held version is doing the work; "
              f"if both fire, this gate cannot tell them apart.")
        rc = 1
    else:
        print(f"  ok: {leg} — quick 6+HP control correctly does NOT install it")
sys.exit(rc)
PY

echo "== 3: frozen ring inventory across the electrocute window"
python3 - "$W" <<'PY' || fail=1
import re, sys
W = sys.argv[1]
LO, HI = 3380, 3700          # widened: ring_tap is a +1 input-staging deviant (#10)
# FROZEN 14z-95 on merged-m2 vs native vsav2. Compared as an ID SEQUENCE, not
# by frame: the two games are never on the same frame, and ring_tap's staging
# differs from replay.lua's, so a frame-indexed compare would be a
# cross-convention error (docs/GOTCHAS.md).
EXPECT = {"native": ["0625","0419","0402","00f3","010b","0415"],
          "ours":   ["0625","0419","0402","00f3","010a","0415"]}
rc = 0
for leg, want in EXPECT.items():
    got = []
    for line in open(f"{W}/{leg}_r/ring.txt"):
        m = re.match(r"f(\d+) id ([0-9a-f]{4}) pc", line.strip())
        if m and LO <= int(m.group(1)) <= HI and m.group(2) not in ("0000","ffff","049a"):
            got.append(m.group(2))
    if got != want:
        print(f"FAIL: {leg} ring inventory {got}, frozen {want}")
        print("       Growth here is the standing watch (CLAUDE.md §4): "
              "root-cause it, do not widen the inventory.")
        rc = 1
    else:
        print(f"  ok: {leg} — {len(got)} ids, matching the frozen inventory")
# the ONE known delta, asserted by name so it cannot silently become two
d_o = set(EXPECT["ours"]) - set(EXPECT["native"])
d_n = set(EXPECT["native"]) - set(EXPECT["ours"])
if (d_o, d_n) != ({"010a"}, {"010b"}):
    print(f"FAIL: the cross-leg delta is no longer the documented 010a/010b "
          f"cosmetic pair: ours-only {d_o}, native-only {d_n}")
    rc = 1
else:
    print("  ok: the only cross-leg delta is the documented 010a/010b pair")
sys.exit(rc)
PY

[ "$fail" = 0 ] && echo "PASS: Phobos electrocute — installs on both legs, quick control clean, ring frozen" \
    || { echo "FAIL: hui electrocute"; exit 1; }
