#!/bin/sh
# upload_release_assets.sh — publish the PREBUILT emulator binaries as GitHub
# RELEASE ASSETS on the freeze tag, and prune the previous freeze's.
#
# RULED 2026-09-11 (14z-149, option (b)): the binaries are NEVER git content —
# a committed binary lives in every clone's history forever (~140 MB per
# release, tripled by three OSes) and only a history rewrite removes it. The
# tree keeps each directory's BINARY.txt (the sha256 rows are what make a
# downloaded asset verifiable); the files sit under release/emulators/ and
# release/<name>/*/emulator/bin/ IGNORED; the assets attach to the release on
# `freeze/<name>` and the previous freeze's assets are DELETED so GitHub hosts
# only the latest ("can we have a release mechanism where we delete the
# previous existing binaries so that we only host on github the latest ones?").
# The maintainer's own web storage may mirror them later.
#
# Usage: tools/upload_release_assets.sh freeze/<name> [--prune] [--dry-run]
#   for every release/emulators/<platform>/<os-arch>/ holding a BINARY.txt AND its files:
#     1. every sha256 row verified on disk (a record with NO files is named and skipped —
#        this host has neither built nor fetched them);
#     2. the `asset` line written into BINARY.txt (zip name, tag, URL) — the record names its
#        own home; the rows hash the OTHER files, so the record may change;
#     3. `<name>-<platform>-<os-arch>.zip` built with the directory inside (BINARY.txt included;
#        zip keeps the executable bits; the ad-hoc signature is inside the Mach-O);
#     4. the GitHub release on the tag created if absent, then `gh release upload --clobber`;
#     5. the asset DOWNLOADED again and its rows re-verified — the assertion is on what GitHub
#        serves, not on what was sent;
#   --prune: the previous `freeze/merged-m*` tag (sort -V) that has a release loses every
#            `*-*.zip` asset (the release and the tag stay: the record of what shipped is the
#            tree's BINARY.txt, the tag is the source).
#   --dry-run: steps 1-3 only, nothing touches GitHub.
# Needs `gh` authenticated for the origin repository. Gate for the artifact on
# this host: tests/test_release_binaries.sh (before uploading, always).
set -eu
TAG="${1:?usage: tools/upload_release_assets.sh freeze/<name> [--prune] [--dry-run]}"; shift
PRUNE=0; DRY=0
for a in "$@"; do case "$a" in --prune) PRUNE=1 ;; --dry-run) DRY=1 ;; *) echo "unknown option $a" >&2; exit 2 ;; esac; done
REPO="$(cd "$(dirname "$0")/.." && pwd)"; cd "$REPO"
case "$TAG" in freeze/*) ;; *) echo "the tag must be a freeze tag (freeze/<name>)" >&2; exit 2 ;; esac
git rev-parse --verify -q "refs/tags/$TAG" >/dev/null || { echo "no such tag: $TAG" >&2; exit 1; }
NAME="${TAG#freeze/}"
ORIGIN="$(git remote get-url origin | sed -e 's#\.git$##' -e 's#^git@github.com:#https://github.com/#')"
URL="$ORIGIN/releases/tag/$TAG"
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT INT TERM

verify_rows() {  # verify_rows <dir> — every sha256 row's file present and matching; prints BAD lines
    d="$1"
    grep -E '^sha256 +[0-9a-f]{64} +[^ ]+' "$d/BINARY.txt" | while read -r _ want f; do
        got="$(shasum -a 256 "$d/$f" 2>/dev/null | cut -c1-64)"
        [ "$got" = "$want" ] || echo "BAD $d/$f (${got:-missing})"
    done
}

n=0
for rec in release/emulators/*/*/BINARY.txt; do
    [ -f "$rec" ] || continue
    d="$(dirname "$rec")"; osarch="$(basename "$d")"; platform="$(basename "$(dirname "$d")")"
    if [ "$(ls "$d" | grep -vc '^BINARY.txt$')" = 0 ]; then
        echo "skip: $d holds the record only (not built or fetched on this host)"; continue
    fi
    bad="$(verify_rows "$d")"
    [ -z "$bad" ] || { echo "$bad"; echo "REFUSING: $d does not match its record" >&2; exit 1; }
    asset="$NAME-$platform-$osarch.zip"
    # the record names its home (replace an earlier asset line, or append before 'provenance')
    python3 - "$rec" "$asset" "$TAG" "$URL" <<'PY'
import sys, re
p, asset, tag, url = sys.argv[1:]
t = open(p).read()
line = f"asset      {asset} attached to the GitHub release on tag {tag} — {url} (verify the rows above after unzipping; the previous freeze's assets are deleted at each release)"
t = re.sub(r"^asset .*$\n?", "", t, flags=re.M)
t = re.sub(r"^(provenance )", line + "\n\\1", t, count=1, flags=re.M) if re.search(r"^provenance ", t, re.M) else t.rstrip("\n") + "\n" + line + "\n"
open(p, "w").write(t)
PY
    ( cd "$(dirname "$d")" && rm -f "$W/$asset" && zip -q -r -X "$W/$asset" "$osarch" )
    echo "built $asset ($(du -h "$W/$asset" | cut -f1)) from $d"
    n=$((n+1))
    [ "$DRY" = 1 ] && continue
    if ! gh release view "$TAG" >/dev/null 2>&1; then
        gh release create "$TAG" --title "$NAME" --verify-tag \
            --notes "Prebuilt emulator binaries for the $NAME freeze (recipe AND prebuilt, each user free to choose). Verify every file against the BINARY.txt inside each zip. The romset patch set and the end-user README are in the repository under release/$NAME/. No ROM data is distributed, ever." >/dev/null
        echo "created release $TAG"
    fi
    gh release upload "$TAG" "$W/$asset" --clobber >/dev/null
    # the assertion is on what GitHub serves
    mkdir -p "$W/dl" && rm -f "$W/dl/$asset"
    gh release download "$TAG" -p "$asset" -D "$W/dl" >/dev/null
    rm -rf "$W/chk"; mkdir -p "$W/chk" && ( cd "$W/chk" && unzip -q "$W/dl/$asset" )
    bad="$(verify_rows "$W/chk/$osarch")"
    [ -z "$bad" ] || { echo "$bad"; echo "FAIL: the asset GitHub serves for $asset does not match its record" >&2; exit 1; }
    cmp -s "$W/chk/$osarch/BINARY.txt" "$rec" || { echo "FAIL: the served BINARY.txt differs from the tree's" >&2; exit 1; }
    echo "uploaded and re-verified from GitHub: $asset -> $URL"
done
[ "$n" -gt 0 ] || { echo "nothing to upload: no release/emulators/*/*/ holds binaries on this host" >&2; exit 1; }

if [ "$PRUNE" = 1 ] && [ "$DRY" = 0 ]; then
    prev="$(git tag -l 'freeze/merged-m*' | sort -V | awk -v t="$TAG" '$0==t{exit} {p=$0} END{print p}')"
    if [ -n "$prev" ] && gh release view "$prev" >/dev/null 2>&1; then
        gh release view "$prev" --json assets --jq '.assets[].name' | grep -E '\.zip$' | while read -r a; do
            gh release delete-asset "$prev" "$a" -y >/dev/null && echo "pruned $prev: $a"
        done
    else
        echo "prune: no earlier freeze release with assets ($prev)"
    fi
fi
echo "done: $n asset(s) on $URL"
