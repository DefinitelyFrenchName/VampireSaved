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
# EVERY ASSET IS SELF-SUFFICIENT (maintainer-ruled 2026-09-12, 14z-151). The
# 14z-149 shape split a release along the WRONG SEAM: the platform zip carried
# the romset tooling and the driver patch, the binary zip carried a bare
# executable, so a player needed both and the second one handed them an
# emulator patch their prebuilt binary already contained. The maintainer:
# "either we ship the rom-related and the platform-related parts separately
# and in that case they should be fully separate, or we choose to package per
# platform and regardless of whether it's prebuilt or recipe and patches, the
# packages should include everything needed, rom patcher and patches
# included." They chose PER PLATFORM, and that ONE DOWNLOAD IS PLAYABLE is now
# the property this tool exists to hold. Second half of the same ruling: a
# prebuilt asset does NOT carry the driver patch or the build recipe — nothing
# in it can be misapplied. `BINARY.txt` still names the patch's sha1, and the
# recipe asset is where the patch itself lives.
#
# Usage: tools/upload_release_assets.sh freeze/<name> [--prune] [--dry-run]
#   THE ASSETS, cut from release/<name>/<platform>/ (one dir per platform, itself
#   self-sufficient — [VSP-100]), each holding the README, the romset patch set, the
#   manifest and the applier, PLUS exactly one emulator route:
#     `<name>-<platform>-<os-arch>.zip`  + emulator/bin/<os-arch>/ (the prebuilt binary and
#                                          its BINARY.txt) and NO patch, NO EMULATOR.md
#     `<name>-<platform>-recipe.zip`     + emulator/0002-*.patch + EMULATOR.md and NO binary,
#                                          for every other OS and for anyone who builds
#     `<name>-mister.zip`                 the whole MiSTer dir (bitstream + MRAs; it has no
#                                          emulator side, so it was always self-sufficient)
#   THE LIST OF FILES IS COMPUTED ONCE per asset (`asset_files`) and drives BOTH the zip and
#   the verification of what GitHub serves back, so the two cannot disagree — an exclusion
#   pattern on one side and a find on the other is the shape that has bitten this tree before.
#   Per asset: build, create the release if absent, `gh release upload --clobber`, DOWNLOAD IT
#   AGAIN and `cmp` every served file against the committed one (the assertion is on what
#   GitHub serves, not on what was sent). An asset that would be empty, a prebuilt asset with
#   no binary in it, or a recipe asset with no patch in it is REFUSED, never shipped.
#   BEFORE ANY OF THAT, the records: every release/<name>/*/emulator/bin/<os-arch>/ holding
#   files has its sha256 rows verified and its `asset` line written (the binary now travels
#   INSIDE the platform asset, so its record must be right before the zip is built; the rows
#   hash the OTHER files, so the record may change). The build resource's copy under
#   release/emulators/ is kept identical. A record with no files beside it is named and skipped
#   — this host has neither built nor fetched them.
#   --prune: the previous `freeze/merged-m*` tag (sort -V) that has a release loses every
#            `*-*.zip` asset (the release and the tag stay: the record of what shipped is the
#            tree's BINARY.txt, the tag is the source).
#   --dry-run: build and refuse locally, nothing touches GitHub.
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
[ -d "release/$NAME" ] || { echo "no release/$NAME/ in the tree — package it first" >&2; exit 1; }
# ONLY THIS RUN'S OUTPUT SURVIVES. A dry run from an earlier host state left
# its zips and lists here, and a reader — a human or the shape gate — takes
# them for what would ship today: the same trap the static runner's kept logs
# were given ("stale ones reading as current is the same trap in a different
# hat", 14z-150).
[ "$DRY" = 0 ] || rm -rf "build/scratch/release_assets/$NAME"

# ---- 0. the records, FIRST: the binary now travels inside its platform asset,
#         so BINARY.txt is a member of that zip and has to be right before it is built.
for bdir in release/"$NAME"/*/emulator/bin/*/; do
    [ -f "$bdir/BINARY.txt" ] || continue
    osarch="$(basename "$bdir")"; pdir="${bdir%/emulator/bin/$osarch/}"; platform="$(basename "$pdir")"
    if [ "$(ls "$bdir" | grep -vc '^BINARY.txt$')" = 0 ]; then
        echo "skip: $bdir holds the record only (not built or fetched on this host)"; continue
    fi
    bad="$(verify_rows "${bdir%/}")"
    [ -z "$bad" ] || { echo "$bad"; echo "REFUSING: ${bdir%/} does not match its record" >&2; exit 1; }
    # A DRY RUN WRITES NOTHING INTO THE TREE — verifying the rows above is read-only and is
    # exactly what a dry run should report; rewriting a tracked record is not (and it is what
    # lets a gate run this tool without editing tracked source).
    if [ "$DRY" = 1 ]; then
        echo "record: ${bdir%/} verified (dry run — the asset line is not written)"; continue
    fi
    # the record names its own home, in the release copy AND in the build resource they are copies of
    python3 - "$NAME-$platform-$osarch.zip" "$TAG" "$URL" "$bdir/BINARY.txt" "release/emulators/$platform/$osarch/BINARY.txt" <<'PY'
import sys, os, re
asset, tag, url = sys.argv[1:4]
line = (f"asset      {asset} attached to the GitHub release on tag {tag} — {url} "
        "(verify the rows above after unzipping; the previous freeze's assets are deleted at each release)")
for p in sys.argv[4:]:
    if not os.path.exists(p):
        continue
    t = re.sub(r"^asset .*$\n?", "", open(p).read(), flags=re.M)
    t = (re.sub(r"^(provenance )", line + "\n\\1", t, count=1, flags=re.M)
         if re.search(r"^provenance ", t, re.M) else t.rstrip("\n") + "\n" + line + "\n")
    open(p, "w").write(t)
PY
    echo "record: ${bdir%/} verified, asset line -> $NAME-$platform-$osarch.zip"
done

# ---- the file list of ONE asset: what goes IN the zip and what is verified coming
#      back are THE SAME list, so they cannot disagree.
asset_files() {   # asset_files <platform> <kind>; kind = recipe | <os-arch> | all
    _p="$1"; _k="$2"
    ( cd "release/$NAME" && find "$_p" -type f ) | sort | while read -r f; do
        case "$f" in
        "$_p"/emulator/bin/*)
            if [ "$_k" != recipe ]; then
                case "$f" in "$_p/emulator/bin/$_k/"*) echo "$f" ;; esac
            fi ;;
        "$_p"/emulator/*.patch|"$_p"/EMULATOR.md)
            if [ "$_k" = recipe ] || [ "$_k" = all ]; then echo "$f"; fi ;;
        *) echo "$f" ;;
        esac
    done
}

# ---- the assets to cut, one line each: <asset> <platform> <kind>
: > "$W/assets.txt"
for pdir in release/"$NAME"/*/; do
    platform="$(basename "$pdir")"
    if [ ! -f "$pdir/README.md" ] || [ ! -f "$pdir/manifest.json" ]; then continue; fi
    if [ -d "$pdir/emulator" ]; then
        echo "$NAME-$platform-recipe.zip $platform recipe" >> "$W/assets.txt"
        for bdir in "$pdir"emulator/bin/*/; do
            [ -f "$bdir/BINARY.txt" ] || continue
            osarch="$(basename "$bdir")"
            if [ "$(ls "$bdir" | grep -vc '^BINARY.txt$')" = 0 ]; then continue; fi
            echo "$NAME-$platform-$osarch.zip $platform $osarch" >> "$W/assets.txt"
        done
    else
        echo "$NAME-$platform.zip $platform all" >> "$W/assets.txt"
    fi
done

while read -r asset platform kind; do
    [ -n "$asset" ] || continue
    asset_files "$platform" "$kind" > "$W/$asset.list"
    # REFUSALS, not hopes: an empty asset, a prebuilt with no binary, a recipe with no patch.
    [ -s "$W/$asset.list" ] || { echo "REFUSING: $asset would be empty" >&2; exit 1; }
    case "$kind" in
    recipe) grep -q '/emulator/.*\.patch$' "$W/$asset.list" \
                || { echo "REFUSING: $asset is the build route and carries no driver patch" >&2; exit 1; } ;;
    all)    ;;
    *)      grep -q "/emulator/bin/$kind/" "$W/$asset.list" \
                || { echo "REFUSING: $asset is the prebuilt route and carries no binary" >&2; exit 1; }
            ! grep -qE '/EMULATOR\.md$|/emulator/.*\.patch$' "$W/$asset.list" \
                || { echo "REFUSING: $asset carries the build recipe a prebuilt user must not apply" >&2; exit 1; } ;;
    esac
    if ! grep -q "^$platform/README.md$" "$W/$asset.list" || ! grep -q "^$platform/apply_release.py$" "$W/$asset.list"; then
        echo "REFUSING: $asset is not self-sufficient (no README or no applier)" >&2; exit 1
    fi
    rm -f "$W/$asset"
    ( cd "release/$NAME" && zip -q -X "$W/$asset" -@ ) < "$W/$asset.list"
    echo "built $asset ($(du -h "$W/$asset" | cut -f1), $(wc -l < "$W/$asset.list" | tr -d ' ') files) from release/$NAME/$platform [$kind]"
    n=$((n+1))
    if [ "$DRY" = 1 ]; then
        # A DRY RUN YOU CANNOT OPEN PROVES NOTHING: keep the zip and its list
        # where a human (or the next gate) can look at what would ship.
        mkdir -p "build/scratch/release_assets/$NAME"
        cp "$W/$asset" "$W/$asset.list" "build/scratch/release_assets/$NAME/"
        continue
    fi
    if ! gh release view "$TAG" >/dev/null 2>&1 </dev/null; then
        gh release create "$TAG" --title "$NAME" --verify-tag --notes "(notes follow)" >/dev/null </dev/null
        echo "created release $TAG"
    fi
    gh release upload "$TAG" "$W/$asset" --clobber >/dev/null </dev/null
    # the assertion is on what GitHub serves
    mkdir -p "$W/dl" && rm -f "$W/dl/$asset"
    gh release download "$TAG" -p "$asset" -D "$W/dl" >/dev/null </dev/null
    rm -rf "$W/chk"; mkdir -p "$W/chk" && ( cd "$W/chk" && unzip -q "$W/dl/$asset" </dev/null )
    ( cd "$W/chk" && find "$platform" -type f ) | sort > "$W/got.txt"
    cmp -s "$W/$asset.list" "$W/got.txt" || { diff "$W/$asset.list" "$W/got.txt" | head; echo "FAIL: the served $asset does not hold exactly the files it was cut from" >&2; exit 1; }
    while read -r f; do cmp -s "release/$NAME/$f" "$W/chk/$f" || { echo "FAIL: served $f differs from the tree's" >&2; exit 1; }; done < "$W/$asset.list"
    echo "uploaded and re-verified from GitHub: $asset ($(wc -l < "$W/$asset.list" | tr -d ' ') files identical) -> $URL"
done < "$W/assets.txt"

[ "$n" -gt 0 ] || { echo "nothing to upload" >&2; exit 1; }

# ---- assets on the tag that THIS run did not build: named, never deleted.
# A stale asset is how a release page ends up serving a shape that no longer
# exists (the 2026-09-12 re-cut left `<name>-fbneo.zip` and `<name>-mame.zip`
# behind, and they are exactly the confusing pair the re-cut removed). It is
# NOT deleted automatically, and that is deliberate: the binaries are built
# per HOST, so a second machine uploading its own OS would otherwise delete
# the first one's asset. The operator is told, and decides.
if [ "$DRY" = 0 ]; then
    cut -d' ' -f1 "$W/assets.txt" | sort > "$W/built.txt"
    gh release view "$TAG" --json assets --jq '.assets[].name' </dev/null \
        | grep -E "^$NAME-.*\.zip$" | sort > "$W/onpage.txt" || true
    stale="$(comm -13 "$W/built.txt" "$W/onpage.txt")"
    if [ -n "$stale" ]; then
        echo "NOTE: $TAG also serves asset(s) this run did not build:"
        echo "$stale" | sed 's/^/  /'
        echo "  If they are an older shape, delete them: gh release delete-asset $TAG <name> -y"
        echo "  If another host built them (a different OS), leave them."
    fi
fi

# ---- the release notes: the deliverables, from what is actually attached
if [ "$DRY" = 0 ]; then
    assets="$(gh release view "$TAG" --json assets --jq '.assets[].name' | sort)"
    {
        echo "# VAMPIRE SAVED — $NAME"
        echo
        echo "Full-roster Vampire Savior on the real CPS-2 engine. **No ROM data and no copyrighted asset is distributed, ever**: every package rebuilds the romset from the three reference dumps YOU own (vsavj, vsav, vsav2) and verifies every byte before writing."
        echo
        echo "## What to download"
        echo
        echo "| asset | what it is |"; echo "|---|---|"
        for a in $assets; do
            case "$a" in
            "$NAME"-mister.zip) echo "| \`$a\` | **the MiSTer package** — README, romset patch set + applier, the \`jtcps2w.rbf\` bitstream + record, the two \`.mra\`, \`MISTER.md\` |" ;;
            "$NAME"-fbneo-recipe.zip) echo "| \`$a\` | **FBNeo, build the emulator once** — README, romset patch set + applier, the FBNeo driver patch + \`EMULATOR.md\`. Any OS |" ;;
            "$NAME"-mame-recipe.zip)  echo "| \`$a\` | **MAME, build the emulator once** — README, the same romset patch set + applier, the MAME driver patch + \`EMULATOR.md\`. Any OS |" ;;
            "$NAME"-fbneo-*.zip) oa="${a#"$NAME"-fbneo-}"; oa="${oa%.zip}"
                                 echo "| \`$a\` | **FBNeo for \`$oa\`, ready to play** — README, romset patch set + applier, and a prebuilt patched FBNeo; verify it against its \`BINARY.txt\` |" ;;
            "$NAME"-mame-*.zip)  oa="${a#"$NAME"-mame-}"; oa="${oa%.zip}"
                                 echo "| \`$a\` | **MAME (CPS-2 subtarget) for \`$oa\`, ready to play** — README, the same romset patch set + applier, and a prebuilt patched MAME; verify it against its \`BINARY.txt\` |" ;;
            *) echo "| \`$a\` | (unlisted asset) |" ;;
            esac
        done
        echo "| Source code (zip / tar.gz) | added by GitHub automatically: the whole project repository at this tag. **Not needed to play.** |"
        echo
        echo "**Take exactly ONE.** Every asset above is complete on its own — the README, the romset patch set, the applier, and one way to get the emulator or core — so there is nothing to combine and nothing to download twice. Pick your platform and, where a prebuilt exists, your OS; otherwise take that platform's \`-recipe\` asset and build the emulator once. Its README says what to do, in order: build the romset from your own dumps, get the emulator or core, play. Every asset rebuilds the same \`vsavjw.zip\`."
        echo
        echo "A prebuilt asset deliberately carries no emulator patch and no build recipe: the binary already contains them. The \`-recipe\` asset of the same platform is where the patch lives, and every \`BINARY.txt\` names its sha1."
        echo
        echo "Only the latest freeze keeps its binary assets; the record of every release (\`BINARY.txt\`, \`BITSTREAM.txt\`, \`manifest.json\`) stays in the repository under \`release/$NAME/\`."
    } > "$W/notes.md"
    gh release edit "$TAG" --title "$NAME" --notes-file "$W/notes.md" >/dev/null && echo "release notes written ($(echo "$assets" | wc -l | tr -d ' ') assets listed)"
fi

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
