#!/bin/sh
# test_release_asset_shape.sh — EVERY PUBLISHED ASSET IS SELF-SUFFICIENT, and
# the two emulator routes never travel together. ROM-free, no emulator, ~10 s.
#
# MUST-FIRE: perturbed-copy: route-mixed — a prebuilt asset that also carries EMULATOR.md and the driver patch must FAIL: that is the 14z-149 shape the maintainer ruled out, a player handed a patch their binary already contains
# MUST-FIRE: perturbed-copy: applier-missing — an asset with no apply_release.py must FAIL: without the applier a download cannot build the romset, which is exactly what "self-sufficient" denies
#
# WHY THIS GATE EXISTS. The maintainer, 2026-09-12, reading the M18 release
# page: the prebuilt packages "dont include the parts and doc to patch the
# roms, so you have to also download that, but doing so makes you download
# patches for emulators, which you might want to apply although you
# shouldn't since your prebuilt binary is already patched, it's very
# confusing." THE RULING: package per platform, and "regardless of whether
# it's prebuilt or recipe and patches, the packages should include
# everything needed, rom patcher and patches included" — plus, on the second
# question, a prebuilt asset does NOT carry the driver patch or the recipe.
#
# So the invariant is: ONE DOWNLOAD IS PLAYABLE, and nothing in a download
# can be misapplied. That is a property of what `tools/upload_release_assets.sh`
# CUTS, and until now nothing checked it — which is [VSP-178]'s class exactly
# (an artifact derived from the build set with no static gate over it rots,
# and this one rotted into a shipped release before a human noticed).
#
# WHAT IT CHECKS, on the lists the real tool produces under --dry-run (which
# writes nothing into the tree):
#   1. self-sufficiency: every asset carries the README, the applier, the
#      manifest and the patch set;
#   2. the routes never mix: no asset holds a prebuilt binary AND the build
#      recipe;
#   3. the recipe asset is the build route (patch + EMULATOR.md, no binary);
#   4. a prebuilt asset is the ready-to-play route (binary + its record, no
#      patch, no EMULATOR.md) — skipped, and SAID, on a host that has neither
#      built nor fetched the binaries (a fresh clone is that host);
#   5. COMPLETENESS both ways: every file of the platform directory reaches
#      at least one asset, so nothing ruled into a release is orphaned by the
#      cut, and no asset names a file the directory does not have.
#
# WHAT IT DOES NOT CLAIM: that the assets on GitHub are these. The tool
# downloads each asset back and `cmp`s every served file against the tree's;
# this gate is about the CUT, not about the upload.
#
# Usage: tests/test_release_asset_shape.sh   [RELEASE=merged-mNN]
set -eu
REPO="$(cd "$(dirname "$0")/.." && pwd)"; cd "$REPO"
. "$REPO/tests/lib/controls.sh"; vs_ctl_mode "$0"
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT INT TERM
fail=0
ok()  { echo "  ok    $*"; }
bad() { echo "  FAIL  $*"; fail=1; }

# THE RELEASE UNDER TEST: the newest release/<name>/ that has a freeze tag —
# the same `sort -V` rule the tool's own --prune uses, so the two cannot
# disagree about which release is current.
NAME="${RELEASE:-}"
if [ -z "$NAME" ]; then
    for d in release/merged-m*/; do
        n="$(basename "$d")"
        if git rev-parse --verify -q "refs/tags/freeze/$n" >/dev/null; then echo "$n"; fi
    done | sort -V | tail -1 > "$W/name"
    NAME="$(cat "$W/name")"
fi
[ -n "$NAME" ] || { echo "SKIP: no release/merged-m*/ with a freeze tag in this checkout"; exit 0; }
echo "== the release under test: $NAME"

# ---- the lists the REAL tool would ship -----------------------------------
tools/upload_release_assets.sh "freeze/$NAME" --dry-run > "$W/dry.log" 2>&1 || {
    echo "  FAIL  the tool refused its own dry run:"; sed 's/^/        /' "$W/dry.log"; exit 1; }
mkdir -p "$W/lists"
for l in "build/scratch/release_assets/$NAME"/*.list; do cp "$l" "$W/lists/"; done
echo "  $(ls "$W/lists" | wc -l | tr -d ' ') asset(s) cut: $(ls "$W/lists" | sed 's/\.zip\.list$//' | tr '\n' ' ')"

# THE PERTURBATION, written ONCE so the control section and the CONTROL= mode
# prove the same thing ([VSP-181]). The input to this gate's verdict is the
# list of files an asset would hold; perturbing a real one is perturbing the
# real input.
perturb_list() {  # perturb_list <kind> <list-file>
    case "$1" in
    route-mixed)      p="$(head -1 "$2" | cut -d/ -f1)"
                      # BOTH routes forced into ONE list, from EITHER side, so the control
                      # works on a host with binaries and on a fresh clone alike — a control
                      # that can only fire where the binaries are is a control CI cannot run,
                      # which is the second half of today's own CI diagnosis.
                      { echo "$p/EMULATOR.md"
                        echo "$p/emulator/0002-cps2-wide-v1.patch"
                        echo "$p/emulator/bin/macos-arm64/BINARY.txt"; } >> "$2"
                      sort -u -o "$2" "$2" ;;
    applier-missing)  grep -v '/apply_release\.py$' "$2" > "$2.tmp" && mv "$2.tmp" "$2" ;;
    esac
}
prebuilt_list() {  # the first list that holds a binary, if any
    grep -l '/emulator/bin/' "$W"/lists/*.list 2>/dev/null | head -1
}
case "${VS_CTL:-}" in
route-mixed)     t="$(prebuilt_list || true)"
                 [ -n "$t" ] || t="$(ls "$W"/lists/*-recipe.zip.list | head -1)"
                 echo "  mode: $(basename "$t") carrying BOTH routes"; perturb_list route-mixed "$t" ;;
applier-missing) t="$(ls "$W"/lists/*.list | head -1)"
                 echo "  mode: $(basename "$t") without its applier"; perturb_list applier-missing "$t" ;;
esac

# ---- 1. self-sufficiency --------------------------------------------------
echo "== 1. every asset carries the whole romset route"
for L in "$W"/lists/*.list; do
    a="$(basename "$L" .list)"; p="$(head -1 "$L" | cut -d/ -f1)"
    miss=""
    for f in README.md apply_release.py manifest.json; do
        grep -q "^$p/$f$" "$L" || miss="$miss $f"
    done
    grep -q "^$p/patches/" "$L" || miss="$miss patches/"
    if [ -z "$miss" ]; then ok "$a: README + applier + manifest + patches"
    else bad "$a is not self-sufficient — missing:$miss"; fi
done

# ---- 2. the two routes never travel together ------------------------------
echo "== 2. no asset holds both a prebuilt binary and the build recipe"
for L in "$W"/lists/*.list; do
    a="$(basename "$L" .list)"
    hasbin=no; hasrec=no
    if grep -q '/emulator/bin/' "$L"; then hasbin=yes; fi
    if grep -qE '/EMULATOR\.md$|/emulator/[^/]*\.patch$' "$L"; then hasrec=yes; fi
    if [ "$hasbin" = yes ] && [ "$hasrec" = yes ]; then
        bad "$a carries a prebuilt binary AND the driver patch/recipe — the 14z-149 confusion, ruled out 2026-09-12"
    else ok "$a: binary=$hasbin recipe=$hasrec"; fi
done

# ---- 3. the recipe route --------------------------------------------------
echo "== 3. the recipe asset is the build route"
for L in "$W"/lists/*-recipe.zip.list; do
    [ -f "$L" ] || { bad "no -recipe asset was cut: the OSes with no prebuilt have no route"; break; }
    a="$(basename "$L" .list)"
    if ! grep -qE '/emulator/[^/]*\.patch$' "$L"; then bad "$a carries no driver patch"; fi
    if ! grep -q '/EMULATOR\.md$' "$L"; then bad "$a carries no EMULATOR.md"; fi
    if grep -q '/emulator/bin/' "$L"; then bad "$a carries a binary — it is the build route"; fi
    ok "$a: driver patch + recipe, no binary"
done

# ---- 4. the prebuilt route ------------------------------------------------
echo "== 4. a prebuilt asset is ready to play"
nb=0
for L in "$W"/lists/*.list; do
    grep -q '/emulator/bin/' "$L" || continue
    nb=$((nb+1)); a="$(basename "$L" .list)"
    if ! grep -q '/emulator/bin/[^/]*/BINARY\.txt$' "$L"; then bad "$a carries no BINARY.txt to verify the binary against"; fi
    sed -n 's#^[^/]*/emulator/bin/\([^/]*\)/.*#\1#p' "$L" | sort -u > "$W/archs.txt"
    archs="$(wc -l < "$W/archs.txt" | tr -d ' ')"; arch="$(head -1 "$W/archs.txt")"
    if [ "$archs" != 1 ]; then bad "$a carries $archs os-arch directories; an asset is for ONE OS"; fi
    case "$a" in *-"$arch".zip) ;; *) bad "$a does not name the os-arch it carries ($arch)" ;; esac
    ok "$a: one os-arch ($arch), its record beside it"
done
[ "$nb" -gt 0 ] || echo "  note: no prebuilt asset on this host (no binaries built or fetched) — section 4 asserted nothing"

# ---- 5. completeness, both ways -------------------------------------------
echo "== 5. every file of every platform directory reaches an asset"
cat "$W"/lists/*.list | sort -u > "$W/union.txt"
( cd "release/$NAME" && find . -type f | sed 's|^\./||' ) | sort > "$W/tree.txt"
# THE ONE NAMED EXEMPTION, and a fresh clone is the host that needs it: an
# os-arch directory whose BINARY.txt has no binaries beside it (the files are
# release assets, never git content — 14z-149) ships NO asset here, so its
# record cannot reach one. That is a property of the HOST, not of the cut.
# Everything else must land somewhere.
: > "$W/exempt.txt"
for bdir in release/"$NAME"/*/emulator/bin/*/; do
    [ -f "$bdir/BINARY.txt" ] || continue
    if [ "$(ls "$bdir" | grep -vc '^BINARY.txt$')" = 0 ]; then
        echo "${bdir#release/$NAME/}BINARY.txt" >> "$W/exempt.txt"
    fi
done
if [ -s "$W/exempt.txt" ]; then
    echo "  note: $(wc -l < "$W/exempt.txt" | tr -d ' ') record(s) exempt — this host holds no binaries for them"
    sort -o "$W/exempt.txt" "$W/exempt.txt"
    comm -23 "$W/tree.txt" "$W/exempt.txt" > "$W/tree2.txt" && mv "$W/tree2.txt" "$W/tree.txt"
fi
orphan="$(comm -13 "$W/union.txt" "$W/tree.txt")"
ghost="$(comm -23 "$W/union.txt" "$W/tree.txt")"
if [ -z "$orphan" ]; then ok "no file of release/$NAME/ is left out of every asset"
else bad "left out of every asset: $(echo "$orphan" | tr '\n' ' ')"; fi
if [ -z "$ghost" ]; then ok "no asset names a file the tree does not hold"
else bad "named but absent: $(echo "$ghost" | tr '\n' ' ')"; fi

# ---- the controls ---------------------------------------------------------
echo "== controls"
ctl_check() {  # ctl_check <name> <list> — the perturbed copy must be REJECTED
    c="$W/ctl.list"; cp "$2" "$c"; perturb_list "$1" "$c"
    p="$(head -1 "$c" | cut -d/ -f1)"
    case "$1" in
    route-mixed)     if grep -q '/emulator/bin/' "$c" && grep -qE '/EMULATOR\.md$|/emulator/[^/]*\.patch$' "$c"
                     then vs_ctl_fired route-mixed "a prebuilt list carrying EMULATOR.md is seen as mixed"
                     else vs_ctl_dead route-mixed "the perturbed list did not read as mixed" || true; fail=1; fi ;;
    applier-missing) if grep -q "^$p/apply_release.py$" "$c"
                     then vs_ctl_dead applier-missing "the applier survived its own removal" || true; fail=1
                     else vs_ctl_fired applier-missing "a list without apply_release.py is seen as not self-sufficient"; fi ;;
    esac
}
ctl_check route-mixed "$(ls "$W"/lists/*.list | head -1)"
ctl_check applier-missing "$(ls "$W"/lists/*.list | head -1)"

if [ "$fail" = 0 ]; then echo "PASS test_release_asset_shape"; exit 0; fi
echo "FAIL test_release_asset_shape"; exit 1
