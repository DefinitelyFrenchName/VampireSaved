#!/bin/sh
# test_ref_rot_image_pick.sh — ground truth for WHICH IMAGE test_build_ref_rot.sh
# judges a rompath by: the named preference (vsavjw, then vsavj, then name
# order), never directory order (14z-139). ROM-free, ~2 s.
#
# WHY. Until 14z-139 that gate took the `vsavjw` zip, else whatever
# `glob.glob` listed first — and `glob.glob` is unsorted. A stock build's
# rompath holds `vsavj.zip` beside the pristine parent `vsav.zip`; on the
# development host the filesystem happened to list `vsavj.zip` first, so the
# stock twins were judged by their own image and found in the registry. On
# another filesystem the same directories would have been judged by the
# parent's members and the currency report would have read `no registry
# row` for them. Found 14z-137 when the generic harness lifted the gate and
# had to NAME the preference to reproduce the verdict (`[ref_rot].image_prefer`
# there); recorded then, fixed here. A verdict that depends on which file the
# filesystem lists first is a verdict about the filesystem.
#
# METHOD. The REAL gate, symlinked into a synthetic repo so `$REPO` resolves
# there (the same trick test_static_runner uses on the runner). Two rompaths,
# each with an ADVERSARY beside the image that should be judged: a zip shaped
# exactly like the rot signature (vsw.* members, no vsw.z01), so a wrong pick
# is LOUD — ROTTED — instead of the real tree's quieter `no registry row`.
# Then the must-fire: a COPY of the gate with the preference edited to prefer
# the adversary must report both ROTTED. Then the fallback: with no preferred
# name present, the FIRST BY NAME is judged, whatever order the files were
# created in.
set -eu
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
rc=0
fail() { echo "  FAIL: $*"; rc=1; }

GATE="$REPO/tests/test_build_ref_rot.sh"
T="$(mktemp -d)"; trap 'rm -rf "$T"' EXIT INT TERM
FR="$T/fakerepo"
mkdir -p "$FR/tests" "$FR/build/stockx/rompath" "$FR/build/widex/rompath" "$FR/build/plainx/rompath"
ln -s "$GATE" "$FR/tests/test_build_ref_rot.sh"

# stub gates that name a build and READ its rompath (the gate only judges
# defaults that are dereferenced as a romset); written with printf so the
# `VAR=` lines do not start a line of THIS script, which the real gate scans.
printf '#!/bin/sh\n%s\nls "$BUILD/rompath"\n' 'BUILD="${BUILD:-build/stockx}"' > "$FR/tests/g_stock.sh"
printf '#!/bin/sh\n%s\nls "$BUILD/rompath"\n' 'BUILD="${BUILD:-build/widex}"'  > "$FR/tests/g_wide.sh"
printf '#!/bin/sh\n%s\nls "$BUILD/rompath"\n' 'BUILD="${BUILD:-build/plainx}"' > "$FR/tests/g_plain.sh"
chmod +x "$FR"/tests/g_*.sh

mkzip() {  # mkzip <path> <member>...
    python3 - "$@" <<'PY'
import sys, zipfile
p, *names = sys.argv[1:]
with zipfile.ZipFile(p, "w") as z:
    for n in names:
        z.writestr(n, b"x")
PY
}
# the ROT SIGNATURE: vsw.* members and no vsw.z01 (a pre-WIDE-v1.1 image)
ROTTED_SHAPE="vsw.03 vsw.04 vsw.05 vsw.06 vsw.07 vsw.08 vsw.09 vsw.10"
# a stock-shaped image: 9 vm3.* members, nothing the rot test looks at
STOCK_SHAPE="vm3.03d vm3.04d vm3.05a vm3.06a vm3.07a vm3.08a vm3.09a vm3.10a vm3.key"
# a current WIDE image: vsw.* WITH vsw.z01
WIDE_SHAPE="vsw.03 vsw.04 vsw.05 vsw.06 vsw.07 vsw.08 vsw.09 vsw.10 vsw.z01 vsw.z02"

# stock build: the image is vsavj.zip; the adversary wears the PARENT's name
mkzip "$FR/build/stockx/rompath/vsav.zip"  $ROTTED_SHAPE     # created FIRST
mkzip "$FR/build/stockx/rompath/vsavj.zip" $STOCK_SHAPE
# WIDE build: the image is vsavjw.zip; the adversary is the parent again
mkzip "$FR/build/widex/rompath/vsav.zip"   $ROTTED_SHAPE
mkzip "$FR/build/widex/rompath/vsavjw.zip" $WIDE_SHAPE
# no preferred name at all: name order decides — b (rotted) created first
mkzip "$FR/build/plainx/rompath/b_other.zip" $ROTTED_SHAPE
mkzip "$FR/build/plainx/rompath/a_other.zip" $STOCK_SHAPE

echo "== 1. the real gate judges each rompath by the NAMED preference =="
o1="$(cd "$FR" && sh tests/test_build_ref_rot.sh 2>&1)" && s1=0 || s1=$?
for d in build/stockx build/widex build/plainx; do
    printf '%s' "$o1" | grep -qE "^  ok +$d " \
        && echo "  ok: $d judged by its image, not the adversary" \
        || { fail "$d not judged ok:"; printf '%s' "$o1" | grep -E "$d" | sed 's/^/        /'; }
done
printf '%s' "$o1" | grep -qE '^  ROTTED ' && fail "an adversary was judged (a ROTTED row printed)" || true
[ "$s1" = 0 ] && echo "  ok: exit 0" || fail "the gate exited $s1 on a tree whose every image is current"

echo "== 2. MUST-FIRE — prefer the adversary and both rompaths read ROTTED =="
# A copy of the gate with the preference rewritten. If this does not flip the
# verdict, the preference is decoration and section 1 proved nothing.
sed 's/^IMAGE_PREFER = ("vsavjw", "vsavj")$/IMAGE_PREFER = ("vsav.zip",)/' "$GATE" > "$FR/tests/ref_rot_adv.sh"
grep -q 'IMAGE_PREFER = ("vsav.zip",)' "$FR/tests/ref_rot_adv.sh" \
    || { fail "could not rewrite the preference — the gate's IMAGE_PREFER line moved"; }
chmod +x "$FR/tests/ref_rot_adv.sh"
o2="$(cd "$FR" && sh tests/ref_rot_adv.sh 2>&1)" && s2=0 || s2=$?
for d in build/stockx build/widex; do
    printf '%s' "$o2" | grep -qE "^  ROTTED +$d " \
        && echo "  ok: $d read ROTTED under the adversarial preference" \
        || fail "$d did not flip to ROTTED — the preference is not load-bearing"
done
[ "$s2" != 0 ] && echo "  ok: and the copy exited $s2" || fail "the adversarial copy exited 0"

echo "== 3. the fallback is NAME order, not creation order =="
# build/plainx has no preferred name; b_other.zip (rotted) was created before
# a_other.zip (ok). Name order judges a_other.zip.
printf '%s' "$o1" | grep -qE "^  ok +build/plainx " \
    && echo "  ok: a_other.zip judged (first by name) though b_other.zip was created first" \
    || fail "the fallback did not pick the first image by name"

echo
[ "$rc" = 0 ] && echo "PASS: test_build_ref_rot.sh judges a rompath by the named image preference." \
             || echo "FAIL: see above."
exit $rc
