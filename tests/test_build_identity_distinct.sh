#!/bin/sh
# test_build_identity_distinct.sh — a playtest build must be distinguishable
# from its legacy-only instrument (14z-94). ROM-free, ~2 s.
#
# WHY THIS EXISTS. The maintainer asked which merged build to test, fearing
# they had tested the wrong one. That fear was well founded and the obvious
# check would NOT have settled it:
#
#     build/m3b_merged9   program fingerprint 081e2e53...   the playtest build
#     build/merged1       program fingerprint 081e2e53...   the legacy rig
#
# Identical BY DESIGN — 14z-92 (d716e49) records that the merged build gets no
# registry.tsv row precisely "because the legacy-only instrument shares its
# fingerprint". Three things make it a live trap:
#
#   * merged1 is NEWER by 8 minutes, so "the latest merged build" is wrong;
#   * build_fingerprint.py covers PROGRAM members only — 12 of 21, 8.1% of
#     the shipped bytes — so it cannot see the difference at all;
#   * the in-game version string (14z-105, select screen) names the freeze
#     GENERATION and is in the shared program image, so it shows on BOTH
#     builds — it does not tell them apart either.
#
# And the wrong one is PLAYABLE: same program image, all 18 characters
# selectable, but the tenants render blank with no ported voices, because its
# gfx and QSound members are zero-filled.
#
# So the discriminator is the WHOLE-ARTIFACT manifest, and this gate asserts
# that it still discriminates — i.e. that a future rebuild has not made the
# two indistinguishable by that measure too.
#
# HANDOFF's review-triage table note, moved into this header 14z-123 (verbatim; the
# documentation pass ruled a gate's WHY lives in the gate):
#   (review-triage, 14z-94) the merged playtest build stays distinguishable
#   from its legacy-only instrument, which SHARES its program fingerprint by
#   design.
set -eu
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
rc=0
fail() { echo "  FAIL: $*"; rc=1; }

PLAY="build/m3b_merged23"     # the frozen merged playtest build (re-pointed 14z-111; 14z-117 -> merged-m12)  # re-pointed 14z-117b (random-select freeze) <- 14z-117  # re-pointed 14z-119 (physics-port freeze) <- 14z-117b
INSTR="build/merged1"         # the legacy-only instrument that shares its fp

for d in "$PLAY" "$INSTR"; do
    [ -d "$d/rompath" ] || { echo "SKIP: $d/rompath absent (build dirs are untracked)"; exit 0; }
done

echo "== 1. they DO share a program fingerprint (the trap is still real) =="
# If this ever stops being true the gate should be re-read, not silently kept:
# the hazard it guards would have changed shape.
if [ -n "${ROMDIR:-}" ]; then
    fp_p="$(python3 tools/build_fingerprint.py "$PLAY/rompath;$ROMDIR"  --set vsavjw --sha-only 2>/dev/null || echo x)"
    fp_i="$(python3 tools/build_fingerprint.py "$INSTR/rompath;$ROMDIR" --set vsavjw --sha-only 2>/dev/null || echo y)"
    if [ "$fp_p" = "$fp_i" ]; then
        echo "  ok: both $(echo "$fp_p" | cut -c1-12) — the program fingerprint cannot tell them apart"
    else
        echo "  NOTE: the fingerprints now DIFFER ($(echo "$fp_p" | cut -c1-8) vs"
        echo "        $(echo "$fp_i" | cut -c1-8)). The trap this gate documents has"
        echo "        changed shape — re-read it rather than assuming it is gone."
    fi
else
    echo "  note: no ROMDIR, program fingerprints not compared"
fi

echo "== 2. the WHOLE-ARTIFACT manifest DOES tell them apart =="
man_p="$(python3 tools/artifact_manifest.py "$PLAY/rompath")"
man_i="$(python3 tools/artifact_manifest.py "$INSTR/rompath")"
echo "  $PLAY  -> $man_p"
echo "  $INSTR -> $man_i"
if [ "$man_p" = "$man_i" ]; then
    fail "the two builds are now INDISTINGUISHABLE by whole-artifact manifest"
    fail "      too — there would be NO way to tell a playtester which one"
    fail "      they loaded. This is the condition the gate exists to prevent."
else
    echo "  ok: they differ, so 'which build is this?' has an answer"
fi

echo "== 3. and the member COUNT alone is a naked-eye tell =="
# The cheapest check a human can do without running anything.
n_p="$(printf '%s' "$man_p" | awk '{print $2}')"
n_i="$(printf '%s' "$man_i" | awk '{print $2}')"
if [ "$n_p" -gt "$n_i" ]; then
    echo "  ok: playtest build has $n_p members, the instrument $n_i"
    echo "      (the instrument ships ONE zip; the playtest build carries the"
    echo "       patched vsav.zip too, which is where tenant group-B art lives)"
else
    fail "the playtest build no longer has more members than the instrument"
fi

echo "== 4. the instrument's tenant content really is blanked =="
# This is what makes loading the wrong one visible ON SCREEN rather than
# subtle: identical program, but no tenant art and no ported voices.
python3 - "$INSTR" <<'PY' || rc=1
import sys, zipfile, hashlib, glob
d = sys.argv[1]
z = [p for p in glob.glob(f"{d}/rompath/*.zip") if "vsavjw" in p]
if not z:
    print("  FAIL: no vsavjw.zip in the instrument"); sys.exit(1)
zf = zipfile.ZipFile(z[0])
names = zf.namelist()
blank = {}
for m in ("vsw.31m", "vsw.33m", "vsw.35m", "vsw.37m", "vsw.21m"):
    if m in names:
        blank[m] = hashlib.sha1(zf.read(m)).hexdigest()
if not blank:
    print("  FAIL: the instrument carries none of the tenant content members")
    sys.exit(1)
uniq = set(blank.values())
if len(uniq) == 1:
    print(f"  ok: {len(blank)} tenant content members share ONE hash "
          f"({list(uniq)[0][:10]}) — zero-filled, so the tenants render blank")
else:
    print(f"  FAIL: the instrument's tenant members are NOT uniformly blank")
    for m, h in sorted(blank.items()):
        print(f"        {m} {h[:12]}")
    print("        If it now carries real content it is no longer a legacy-only")
    print("        instrument, and loading it would be much harder to notice.")
    sys.exit(1)
PY

echo
[ "$rc" = 0 ] && echo "PASS: the playtest build is distinguishable from the instrument." \
             || echo "FAIL: see above."
exit $rc
