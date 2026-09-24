#!/bin/sh
# test_release_os_metadata.sh — a file manager's folder metadata (`.DS_Store`) in a release tree is never shipped and never counted: the real uploader cuts no asset carrying one, and every release listing that can see a dotfile drops it through the one definition, tests/lib/os_metadata.sh. ROM-free, ~3 s.
#
# WHAT: a file manager's folder metadata (.DS_Store) in a release tree is never shipped and
#   never counted: the uploader cuts no asset carrying one, and every release listing that
#   can see a dotfile drops it through the one definition tests/lib/os_metadata.sh.
# HOW: the filter over a path list (exact basename only); the REAL uploader under --dry-run
#   in a throwaway repo with .DS_Store planted in four places; the three listings' wiring
#   read from the scripts; the control disables the filter in a shadow copy of the lib.
# EXPECTS: no list and no zip carrying a dotfile, the wiring present; the disabled filter
#   lets the plant into an asset list and fails.
# MEASURES: zip-members — 20 the zip members read back from the dry-run assets of the fixture release (20 at 14z-180)
#
# MUST-FIRE: shadow-tool: filter-disabled — a shadow copy of tests/lib/os_metadata.sh whose filter passes every path must let a planted `.DS_Store` into the synthetic release's asset lists (mode: section 2 runs the uploader against that copy and must FAIL)
#
# WHY (maintainer-ruled 2026-09-14: "they must be ignored"). Finder writes a
# `.DS_Store` into every folder a person browses. At 14z-153 one at
# `release/merged-m18/.DS_Store` turned the strict static tier 149/0/1 through
# test_release_asset_shape §5 — the gate measured the host. And the uploader
# listed a platform directory with `find -type f`, which sees dotfiles, so one
# INSIDE a platform directory would have been zipped into a published asset.
# The files are gitignored and none was ever committed: this is about the
# working tree a release is cut from.
#
# THE LISTINGS THAT CAN SEE A DOTFILE, censused 14z-153: the uploader's asset
# list, test_release_asset_shape §5 and test_release_roundtrip §4, each a
# `find`. Globs and `ls` skip dotfiles; the packager copies only named files and
# `.mra` files; test_release_roundtrip's rule-7 scan walks its own temporary
# package; test_release_binaries checks only the rows its records name.
#
# WHAT IT RUNS:
#   1. the filter over a path list — the exact basename only, look-alikes survive;
#   2. the REAL uploader, --dry-run, in a throwaway repo root (a git repo with a
#      freeze tag and a synthetic two-platform release carrying `.DS_Store` at the
#      release root, in a platform directory, beside a prebuilt binary and inside
#      patches/): all three assets cut, no list and no zip carrying one;
#   3. the wiring: each of the three listings sources the one definition and pipes
#      its `find` through it. Read from the scripts — the uploader is ALSO proven
#      by running it in section 2; the two gates' listings run over the real
#      release tree, which a gate must not plant files into.
#
# Usage: tests/test_release_os_metadata.sh
set -eu
REPO="$(cd "$(dirname "$0")/.." && pwd)"; cd "$REPO"
. "$REPO/tests/lib/controls.sh"; vs_ctl_mode "$0"
. "$REPO/tests/lib/os_metadata.sh"
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT INT TERM
fail=0
ok()  { echo "  ok    $*"; }
bad() { echo "  FAIL  $*"; fail=1; }
command -v zip >/dev/null 2>&1 || { echo "FAIL: no zip(1) — the uploader needs it"; exit 1; }
command -v unzip >/dev/null 2>&1 || { echo "FAIL: no unzip(1) — the served-content check needs it"; exit 1; }
sha256_of() {
    if command -v shasum >/dev/null 2>&1; then shasum -a 256 "$1" | cut -c1-64
    else sha256sum "$1" | cut -c1-64; fi
}

# THE PERTURBATION, written ONCE: the helper with its filter disabled (a later
# definition wins), so the control and the mode prove the same thing ([VSP-181]).
perturb() {  # perturb <file>
    cp "$REPO/tests/lib/os_metadata.sh" "$1"
    echo 'vs_drop_os_metadata() { cat; }' >> "$1"
}

mkroot() {  # mkroot <root> <helper> — a throwaway repo: the real uploader, the given helper, a synthetic release
    r="$1"; mkdir -p "$r/tools" "$r/tests/lib"
    cp "$REPO/tools/upload_release_assets.sh" "$r/tools/"
    cp "$2" "$r/tests/lib/os_metadata.sh"
    rel="$r/release/merged-m99"
    for p in fbneo mister; do
        mkdir -p "$rel/$p/patches/vsavjw"
        for f in README.md manifest.json apply_release.py apply_release.html; do echo "$p $f" > "$rel/$p/$f"; done
        echo delta > "$rel/$p/patches/vsavjw/d_x.xdelta"
    done
    mkdir -p "$rel/fbneo/emulator/bin/macos-arm64"
    echo recipe > "$rel/fbneo/EMULATOR.md"
    echo patch > "$rel/fbneo/emulator/0002-cps2-wide-v1.patch"
    echo binary > "$rel/fbneo/emulator/bin/macos-arm64/fbneo"
    printf 'sha256 %s fbneo\n' "$(sha256_of "$rel/fbneo/emulator/bin/macos-arm64/fbneo")" \
        > "$rel/fbneo/emulator/bin/macos-arm64/BINARY.txt"
    echo rbf > "$rel/mister/jtcps2w.rbf"
    for d in "$rel" "$rel/fbneo" "$rel/fbneo/emulator/bin/macos-arm64" "$rel/mister/patches"; do
        echo "finder view settings" > "$d/.DS_Store"
    done
    ( cd "$r" && git init -q && git add tools tests \
        && git -c user.email=t@t -c user.name=t -c commit.gpgsign=false commit -q -m fixture \
        && git -c user.email=t@t -c user.name=t -c tag.gpgsign=false tag -a freeze/merged-m99 -m fixture \
        && git remote add origin https://example.invalid/fixture.git ) > "$r.git.log" 2>&1
}
cut_assets() {  # cut_assets <root> — the uploader's dry run; its lists land under the root's build/scratch
    ( cd "$1" && sh tools/upload_release_assets.sh freeze/merged-m99 --dry-run ) > "$1.log" 2>&1
}

perturb "$W/helper_off.sh"

echo "== 1. the filter drops the exact name and keeps everything else"
printf '%s\n' .DS_Store a/.DS_Store ./b/c/.DS_Store README.md x.DS_Store .DS_Store.bak a/DS_Store \
    emulator/bin/macos-arm64/fbneo > "$W/paths.txt"
vs_drop_os_metadata < "$W/paths.txt" > "$W/kept.txt"
printf '%s\n' README.md x.DS_Store .DS_Store.bak a/DS_Store emulator/bin/macos-arm64/fbneo > "$W/want.txt"
if cmp -s "$W/kept.txt" "$W/want.txt"; then ok "the three .DS_Store paths dropped, the five others kept (look-alikes included)"
else bad "the filter kept: $(tr '\n' ' ' < "$W/kept.txt")"; fi
if printf '%s\n' .DS_Store a/.DS_Store | vs_drop_os_metadata > "$W/none.txt" && [ ! -s "$W/none.txt" ]; then
    ok "a list of nothing but metadata yields nothing, and the filter still returns 0 (safe under set -e)"
else bad "the filter failed or kept something on a metadata-only list"; fi

echo "== 2. the real uploader over a release planted with .DS_Store"
HELPER="$REPO/tests/lib/os_metadata.sh"
if vs_ctl_is filter-disabled; then HELPER="$W/helper_off.sh"; echo "  mode: the uploader runs against a helper whose filter passes everything"; fi
mkroot "$W/main" "$HELPER"
np="$(find "$W/main/release" -name .DS_Store | wc -l | tr -d ' ')"
[ "$np" = 4 ] && ok "4 .DS_Store planted: the release root, a platform directory, beside a prebuilt binary, inside patches/" \
    || bad "the fixture planted $np .DS_Store file(s), expected 4 (git setup: $(tail -1 "$W/main.git.log" 2>/dev/null))"
if cut_assets "$W/main"; then
    L="$W/main/build/scratch/release_assets/merged-m99"
    na="$(ls "$L"/*.list 2>/dev/null | wc -l | tr -d ' ')"
    [ "$na" = 3 ] && ok "the dry run cut all 3 assets (fbneo recipe, fbneo macos-arm64, mister)" || bad "the dry run cut $na asset(s), expected 3"
    if grep -l 'DS_Store' "$L"/*.list > "$W/leaked.txt" 2>/dev/null; then
        bad "a .DS_Store reached the list of: $(sed 's|.*/||' "$W/leaked.txt" | tr '\n' ' ')"
    else ok "no asset list names a .DS_Store"; fi
    for z in "$L"/*.zip; do unzip -Z1 "$z"; done > "$W/members.txt" 2>/dev/null || true
    if grep -q 'DS_Store' "$W/members.txt"; then bad "a zip carries a .DS_Store: $(grep 'DS_Store' "$W/members.txt" | tr '\n' ' ')"
    elif [ -s "$W/members.txt" ]; then ok "no zip carries one ($(wc -l < "$W/members.txt" | tr -d ' ') members read back)"; echo "MEASURED: zip-members = $(wc -l < "$W/members.txt" | tr -d ' ')"
    else bad "no zip members could be read back"; fi
else
    bad "the uploader's dry run failed:"; tail -8 "$W/main.log" | sed 's/^/        /'
fi

# the control: with the filter disabled a planted .DS_Store MUST reach an asset list
mkroot "$W/ctl" "$W/helper_off.sh"
cut_assets "$W/ctl" || true
n="$(cat "$W/ctl/build/scratch/release_assets/merged-m99"/*.list 2>/dev/null | grep -c 'DS_Store' || true)"
if [ "${n:-0}" -gt 0 ]; then
    vs_ctl_fired filter-disabled "with the filter passing everything, $n .DS_Store path(s) reached the asset lists"
else
    vs_ctl_dead filter-disabled "no .DS_Store reached an asset list with the filter disabled — the uploader does not route its listing through the definition" || fail=1
fi

echo "== 3. the three release listings use the one definition"
for s in tools/upload_release_assets.sh tests/test_release_asset_shape.sh tests/test_release_roundtrip.sh; do
    if grep -q 'tests/lib/os_metadata\.sh' "$s" && grep -q 'find .*-type f.*| *vs_drop_os_metadata' "$s"; then
        ok "$s sources it and pipes its find listing through vs_drop_os_metadata"
    else
        bad "$s does not route its find listing through vs_drop_os_metadata"
    fi
done

echo
[ "$fail" = 0 ] && echo "PASS: .DS_Store is never shipped and never counted" \
    || { echo "FAIL: a release listing or the uploader does not ignore .DS_Store (see above)"; exit 1; }
