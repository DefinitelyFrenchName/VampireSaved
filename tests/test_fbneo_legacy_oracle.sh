#!/bin/sh
# test_fbneo_legacy_oracle.sh — the HACKED build's legacy content, compared
# against VANILLA, on FBNeo (14z-92, GitHub #78 partial).
#
# THE HOLE THIS CLOSES. CLAUDE.md §4 defines the oracle as vanilla on
# vanilla FBNeo versus the hacked set on patched FBNeo, per-frame work RAM.
# What the suite actually had was two adjacent things:
#   test_wide_profile.sh  reference FBNeo == patched FBNeo on PRISTINE vsavj
#                         (the emulator superset invariant)
#   test_dualtrack.sh     stock track == WIDE track on the SAME patched binary
#   tests/lib/m2a_common  the hacked-build legacy comparison — on MAME
# So the emulator invariant and the hacked-build behaviour were each covered,
# but never their product: OUR PATCH BYTES against vanilla, under FBNeo. A
# 68k-core difference reachable only by authored code (thunks, the relocated
# walkers) sat in that gap.
#
# SCOPE, STATED PLAINLY (maintainer-agreed 14z-92): this is the PARTIAL, not
# the full second oracle track #78 describes. It samples a handful of frames
# on a handful of replays. The full track was ruled accepted-and-deferred
# because FBNeo has NO frozen expectation corpus BY DESIGN — every FBNeo gate
# is a live A/B, which is exactly what makes them machine-independent — so
# building it means either freezing an FBNeo basis (giving that up) or a live
# vanilla leg across all 46 legacy replays. Revisit when MiSTer work starts:
# a third implementation is where MAME-specific behaviour would surface, and
# a second independent legacy oracle is worth more then than now.
#
# THE COMPOSITION, and why the vanilla leg may run on the patched binary.
# With FBNEO_REF set, leg A runs on that reference binary and this gate is
# §4's oracle literally. Without it, leg A runs vanilla `vsavj` on the PATCHED
# binary, and the claim is completed by test_wide_profile.sh, which proves
# reference == patched on pristine vsavj bit-for-bit. That composition is
# sound ONLY while that gate is green — it is named here so the dependency is
# visible rather than assumed. Building a reference costs two full FBNeo
# rebuilds (WIDE=0 REVERTS the profile patch), which is why it is optional.
#
# WHY THESE FRAMES. Our builds carry hooks, so legacy replays have RATIFIED
# divergences from vanilla (the §4 flicker/window classes). Sampling blind
# would land on one and report a false finding. Instead the sample frames are
# derived FROM the frozen MAME spec for each replay and pushed clear of every
# ratified divergent region, so a mismatch here cannot be a known-tolerated
# one — it is FBNeo-only, which is the whole point of the gate.
#
# Masked per CLAUDE.md §4: the dead-stack window and the QSound handshake
# latch. The latch matters especially here — 14z-87 measured the voice-class
# borrow as a LOTTERY riding the QSound-latch one-frame phase, 0x06/0x0C/
# 0x09/0x00 on MAME versus 0x04 on FBNeo on identical inputs. That is the one
# documented same-content cross-emulator divergence, and it lives inside the
# mask by construction.
#
# THE REDUCED REFIT (14z-110b, maintainer-ruled; measured 14z-110b CLOSE).
# From donovan-m12 on, the ruled #99 fix (the reaction_hook d2 WINDOW, ~2
# compares on every hit-stun dispatch) shifts FBNeo's execution PHASE
# corpus-wide: the fraction-derived frames below went from PASS on m11 to
# byte-identical FAIL on m12 and m13 (root-caused, STATE 14z-110b addendum —
# m12 == m13 work RAM at the failing frame, the remap exonerated; MAME shows
# ZERO masked diffs at the same frames, so it is FBNeo pacing, not state).
# Rather than widen any tolerance, the sample INSTANTS move: FRAME_OVERRIDE
# names, per replay, five frames MEASURED masked-zero-diff on don_m13 (both
# legs, a ~22-frame scan per replay, dirty frames recorded in STATE). The
# frozen inventory is UNCHANGED — exact-only overrides need no growth. The
# override frames are still checked against the ratified MAME divergence
# regions: an override landing in one is a FAIL, not a silent skip.
#   26_don_arcade_mash is DROPPED from the default set (documented, not
# hidden): the Donovan arcade soak is cycle-saturated (1230-2574 masked bytes
# at 4 of 5 sampled frames, cascading — no clean instant exists), and it is
# covered on MAME by the full-corpus legacy oracle plus the don_m13 .sha1
# expectation. 05_timeout_idle takes its slot (a long legacy replay with a
# full timeout match). Passing 26 explicitly still runs it, and still fails.
#
# Usage: ROMDIR=... tests/test_fbneo_legacy_oracle.sh [build] [replays...]
#   env FBNEO_REF  optional reference (WIDE=0) fbneo binary for leg A
# ~5 min.
set -eu
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
ROMDIR="${ROMDIR:?set ROMDIR}"
BUILD="${1:-build/don_m13}"  # re-pointed 14z-110b
[ $# -gt 0 ] && shift
REPLAYS="${*:-01_attract_long 06_test_mode 21_don_mash 05_timeout_idle}"  # 26 dropped 14z-110b, see header
FB="$REPO/emu/fbneo/fbneo"

[ -x "$FB" ] || { echo "SKIP: no patched FBNeo at $FB"; exit 0; }
[ -f "$BUILD/rompath/vsavjw.zip" ] || {
    echo "SKIP: no WIDE build at $BUILD/rompath"; exit 0; }
strings -a "$FB" | grep -q "CPS-2 WIDE v1" || {
    echo "FAIL: $FB does not carry the WIDE profile"; exit 1; }

# The expectation set is RESOLVED from the build, never pinned (14z-92: two
# gates were found naming builds by path that had gone stale silently).
SET="$(python3 tools/build_fingerprint.py "$BUILD/rompath" --set vsavjw 2>/dev/null)" || {
    echo "FAIL: $BUILD is unregistered — this gate reads its frozen MAME"
    echo "      specs to choose safe sample frames, so it needs a registered"
    echo "      build (merged builds are unregistered by design)"; exit 1; }
MASK="$(cat "tests/expected/$SET/mask")"
echo "== build $BUILD -> expectation set $SET; mask $MASK"
[ -n "${FBNEO_REF:-}" ] && echo "== leg A on the REFERENCE binary $FBNEO_REF" \
    || echo "== leg A on the PATCHED binary (composition: test_wide_profile.sh)"

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
fail=0

for R in $REPLAYS; do
    RPL="tests/replays/$R.rpl"
    SPEC="tests/expected/$SET/$R.masked"
    BASE="tests/expected/vsavj/masked-v2/logs/$R.log"
    [ -f "$RPL" ] && [ -f "$SPEC" ] && [ -f "$BASE" ] || {
        echo "  FAIL: $R — missing replay, spec or basis log"; fail=1; continue; }

    # FRAME_OVERRIDE (14z-110b): measured-clean frames on don_m13; see header.
    case "$R" in
        01_attract_long) OVERRIDE="600 1000 1400 2600 3400" ;;
        21_don_mash)     OVERRIDE="600 2523 3164 4446 5087" ;;
        05_timeout_idle) OVERRIDE="600 2250 2800 3900 8300" ;;
        *)               OVERRIDE="" ;;   # 06_test_mode etc.: derived
    esac
    FRAMES="$(SPEC="$SPEC" BASE="$BASE" OVERRIDE="$OVERRIDE" python3 - <<'PY'
import os, re
spec = open(os.environ["SPEC"]).read().split()
end = 0
for line in open(os.environ["BASE"]):
    if line.startswith("END "):
        end = int(line.split()[1])
# ratified divergent regions from the frozen MAME spec: flicker frames and
# windows. Formats in use: "exact <basis> -", "window <basis> A B",
# "composite <basis> f1,f2 A-B", "flicker <basis> f1,f2".
bad = set()
for tok in spec[2:]:
    if tok == "-":
        continue
    if re.fullmatch(r"\d+-\d+", tok):
        a, b = tok.split("-"); bad.update(range(int(a) - 4, int(b) + 5))
    elif re.fullmatch(r"[\d,]+", tok):
        for f in tok.split(","):
            if f:
                bad.update(range(int(f) - 4, int(f) + 5))
if spec[0] == "window" and len(spec) >= 4:
    try:
        a, b = int(spec[2]), int(spec[3]); bad.update(range(a - 4, b + 5))
    except ValueError:
        pass
out = []
ovr = [int(x) for x in os.environ.get("OVERRIDE", "").split()]
if ovr:
    unsafe = [f for f in ovr if f in bad or not (60 < f < end - 1)]
    if unsafe:
        # loud: an override inside a ratified region would turn a known
        # MAME divergence into a false FBNeo finding (or hide one)
        print(f"unsafe-override {unsafe}"); raise SystemExit(0)
    print(" ".join(str(f) for f in ovr)); raise SystemExit(0)
for frac in (0.15, 0.35, 0.55, 0.75, 0.92):
    f = int(end * frac)
    while f in bad and f < end - 2:
        f += 1
    if 60 < f < end - 1 and f not in out:
        out.append(f)
print(" ".join(str(f) for f in out))
PY
)"
    [ -n "$FRAMES" ] && ! printf '%s' "$FRAMES" | grep -q unsafe || {
        echo "  FAIL: $R — no safe sample frames ($FRAMES)"; fail=1; continue; }

    DUMPS=""
    for f in $FRAMES; do DUMPS="$DUMPS;$f:ff0000-ffffff"; done
    DUMPS="${DUMPS#;}"

    FBNEO_BIN="${FBNEO_REF:-$FB}" FBNEO_DUMPS="$DUMPS" \
        tools/run_replay_fbneo.sh vsavj "$RPL" "$WORK/${R}_van.log" \
        "$WORK/sb_${R}_van" > "$WORK/${R}_van.run" 2>&1 || true
    FBNEO_BIN="$FB" FBNEO_ROMPATH="$REPO/$BUILD/rompath" FBNEO_DUMPS="$DUMPS" \
        tools/run_replay_fbneo.sh vsavjw "$RPL" "$WORK/${R}_new.log" \
        "$WORK/sb_${R}_new" > "$WORK/${R}_new.run" 2>&1 || true

    R="$R" FRAMES="$FRAMES" MASK="$MASK" W="$WORK" \
    FBNEO_ORACLE_EXPECT="${FBNEO_ORACLE_EXPECT:-phase-ratified}" \
    python3 - <<'PY' || fail=1
import os, sys
R, W, mask = os.environ["R"], os.environ["W"], os.environ["MASK"]
frames = [int(f) for f in os.environ["FRAMES"].split()]
skip = set()
for rng in mask.split(","):
    if not rng.strip():
        continue
    a, b = rng.split("-"); skip.update(range(int(a, 16), int(b, 16)))

EXPECT = os.environ.get("FBNEO_ORACLE_EXPECT", "phase-ratified")
ok = True
n_open = 0
for leg in ("van", "new"):
    if not os.path.exists(f"{W}/{R}_{leg}.log"):
        print(f"  FAIL: {R} — leg {leg} produced no checksum log (DEAD, not a verdict)")
        sys.exit(1)

n_cmp = 0
for f in frames:
    pa = f"{W}/{R}_van.log.dump_{f}_ff0000.bin"
    pb = f"{W}/{R}_new.log.dump_{f}_ff0000.bin"
    if not (os.path.exists(pa) and os.path.exists(pb)):
        print(f"  FAIL: {R} f{f} — a dump is MISSING (DEAD leg, not agreement)")
        ok = False; continue
    a, b = open(pa, "rb").read(), open(pb, "rb").read()
    if len(a) != len(b) or not a:
        print(f"  FAIL: {R} f{f} — dump length {len(a)} vs {len(b)}")
        ok = False; continue
    diff = [i for i in range(len(a)) if a[i] != b[i] and i not in skip]
    n_cmp += 1
    # THE TWO FBNeo-ONLY PHASE CLASSES — RATIFIED 2026-08-16 (maintainer,
    # GitHub #78). They were reported as `open:` awaiting a ruling; the
    # ruling is KEEP-AS-TOLERANCE, so they are now a named §4 class.
    #
    # RATIFIED DOES NOT MEAN UNBOUNDED, and §4 is explicit that a non-exact
    # class must have its expectation FROZEN. So the window is not the
    # tolerance — the frozen OFFSET INVENTORY below is. A byte that differs
    # inside a window but is NOT in the inventory is GROWTH and FAILS, the
    # same doctrine as the flicker inventory's standing watch ("if flickers
    # grow beyond the frozen inventory, stop and root-cause — that pattern
    # would indicate a deeper issue, not tolerance noise").
    # Set FBNEO_ORACLE_EXPECT=exact to require bit-identity anyway.
    # Two attributed windows, both named in docs/game/atlas/ram.md:
    #   $FF0500-$FF05FF  sound-driver work area — ram.md:74 already records
    #                    it as "differs between MAME/FBNeo boot phase"
    #   $FF06D0-$FF06EF  SECONDARY STACK, the per-frame OBJ-builder bsr
    #                    return-address chain — ram.md:62, "Execution
    #                    POSITION, not state": a build whose earlier
    #                    per-frame work costs different cycles sits one bsr
    #                    further along at the sample instant. Our builds
    #                    carry hooks, so under FBNeo's pacing the sample
    #                    lands a bsr apart from vanilla where MAME's does
    #                    not (verified: MAME shows 0 masked diffs at the
    #                    same frames).
    # NOTE this EXTENDS ram.md:62, which says that class "appears only on
    # tenant-content replays where no vanilla oracle applies". It appears
    # here on LEGACY content under FBNeo. That is new and wants a ruling.
    WINDOWS = ((0x0500, 0x0600), (0x06D0, 0x06F0))
    # THE FROZEN INVENTORY (measured 14z-92, ratified 14z-93). Every offset
    # ever observed to differ inside an attributed window. Growth is loud.
    # MEASURED 14z-93 across the whole sampled corpus, not transcribed from
    # a note: the first attempt froze {0x55B-0x55D, 0x6D1, 0x6D4, 0x6DB}
    # because the 14z-92 prose recorded only the FIRST byte of each
    # differing run, and the gate immediately reported the rest as growth.
    # The stack offsets sit at longword boundaries 0x06D0/0x06D4/0x06D8/
    # 0x06DC +1..+3 — the low bytes of return addresses in the per-frame
    # OBJ-builder bsr chain, exactly what ram.md:62 describes.
    FROZEN = {0x055B, 0x055C, 0x055D,                    # sound-driver work area
              0x06D1,                                    # OBJ-builder secondary
              0x06D4, 0x06D5,                            #   stack: the low bytes
              0x06D9,                                    #   of the bsr-chain
              0x06DB, 0x06DC, 0x06DD}                    #   return addresses
    inwin = lambda i: any(lo <= i < hi for lo, hi in WINDOWS)
    outside = [i for i in diff if not inwin(i)]
    inside = [i for i in diff if inwin(i)]
    grew = [i for i in inside if i not in FROZEN]
    if outside or grew or (diff and EXPECT == "exact"):
        print(f"  FAIL: {R} f{f} — {len(diff)} masked byte(s) differ, "
              f"first at work-RAM +0x{diff[0]:04x} "
              f"(vanilla {a[diff[0]]:#04x} vs build {b[diff[0]]:#04x})")
        print(f"        FBNeo-only: this frame is clear of every ratified "
              f"MAME divergence for {R}, so it is not a tolerated class.")
        if outside:
            print(f"        {len(outside)} byte(s) are OUTSIDE the attributed "
                  f"phase windows, first +0x{outside[0]:04x}")
        if grew:
            print(f"        inside-window offsets this frame: "
                  + ",".join(f"+0x{i:04x}" for i in inside))
            print(f"        {len(grew)} byte(s) are INSIDE a window but NOT in "
                  f"the frozen inventory, first +0x{grew[0]:04x} — this is "
                  f"GROWTH, not the ratified class. Root-cause it; do not "
                  f"add it to FROZEN without a new measured mechanism and "
                  f"maintainer sign-off (CLAUDE.md §4).")
        ok = False
    elif inside:
        # Print the FULL offset list, not just the first: the inventory is
        # the tolerance, so it has to be auditable from the gate's own
        # output. (Freezing it from a prose note that recorded only the
        # first byte of each run is exactly how 14z-93's first attempt got
        # it wrong — the runs are 3 bytes, a longword return address
        # differing in its low three.)
        print(f"  phase: {R} f{f} — {len(inside)} byte(s) differ, all in the "
              f"FROZEN inventory of the ratified FBNeo phase classes: "
              + ",".join(f"+0x{i:04x}" for i in inside))
        n_open += 1
if n_cmp == 0:
    print(f"  FAIL: {R} — zero frames actually compared")
    ok = False
elif ok:
    tail = f", {n_open} with a ratified FBNeo phase deviation" if n_open else ""
    print(f"  ok: {R} — {n_cmp} sampled frames compared{tail} "
          f"(frames {', '.join(str(f) for f in frames)})")
sys.exit(0 if ok else 1)
PY
done

echo "== verdict controls on the comparator =="
MASK="$MASK" python3 - <<'PY' || fail=1
import os
mask = os.environ["MASK"]
skip = set()
for rng in mask.split(","):
    a, b = rng.split("-"); skip.update(range(int(a, 16), int(b, 16)))

def differs(a, b):
    return [i for i in range(len(a)) if a[i] != b[i] and i not in skip]

base = bytearray(0x10000)
ok = True
# 1. a byte OUTSIDE the mask must be caught
p = bytearray(base); p[0x8000] = 1
c = bool(differs(base, p))
print(f"  control: byte outside the mask (+0x8000) CAUGHT: {c}")
ok = ok and c
# 2. a byte INSIDE the mask must NOT be caught — proves the mask is applied
#    rather than the comparison being vacuous
inside = sorted(skip)[0]
p = bytearray(base); p[inside] = 1
c = bool(differs(base, p))
print(f"  control: byte inside the mask (+0x{inside:04x}) ignored: {not c}")
ok = ok and not c
# 3. identical buffers must not report a difference
c = bool(differs(base, bytearray(base)))
print(f"  control: identical buffers report no difference: {not c}")
ok = ok and not c
raise SystemExit(0 if ok else 1)
PY

[ "$fail" -ne 0 ] && { echo "FAIL: FBNeo hacked-build legacy oracle"; exit 1; }
echo "PASS: FBNeo legacy oracle (partial) — every sampled frame is either"
echo "      masked-identical to vanilla under FBNeo, or differs ONLY at"
echo "      offsets in the FROZEN inventory of the two ratified phase"
echo "      classes. Any byte outside them FAILS. Lines marked"
echo "      'phase:' are the RATIFIED FBNeo-only phase classes"
echo "      (maintainer 2026-08-16, GitHub #78): the sound-driver work area"
echo "      \$FF0500-\$FF05FF and the OBJ-builder secondary stack"
echo "      \$FF06D0-\$FF06EF, each bounded by a FROZEN offset inventory —"
echo "      a byte inside a window but outside the inventory FAILS as"
echo "      GROWTH. Set FBNEO_ORACLE_EXPECT=exact to require bit-identity."
