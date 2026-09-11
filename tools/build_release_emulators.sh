#!/bin/sh
# build_release_emulators.sh — build the PREBUILT emulator binaries a release ships
# (maintainer-ruled 2026-09-11: the recipe AND the prebuilt, each user free to
# choose) into the build resource release/emulators/<platform>/<os-arch>/, with
# the BINARY.txt record tools/package_release_platforms.py hash-verifies into
# every release's emulator/bin/<os-arch>/.
#
# Usage: tools/build_release_emulators.sh fbneo|mame
# Env:   JOBS               parallelism (default: nproc / hw.ncpu)
#        BUILD_SCRATCH      space-free scratch root (default ~/.cache/vampire-saved)
#        RELEASE_EMULATORS  the resource root (default <repo>/release/emulators)
#
# WHAT IT IS: EMULATOR.md's recipe run on THIS host, and nothing else — so a
# prebuilt is the same code a source-building user gets, and the same code the
# gates measure, minus the test instrument:
#   fbneo  a CLEAN git worktree of the PINNED submodule commit (the gitlink,
#          asserted equal to the checked-out submodule) with ONLY patch 0002.
#          tools/setup_fbneo.sh always applies patch 0001, the replay harness —
#          a frontend-only test instrument that must never ship — which is why
#          this script does not call it. `make sdl2 SKIPDEPEND=1`, as the recipe.
#   mame   tools/setup_mame.sh into its OWN mirror (MAME_BUILD_ROOT=...-release):
#          that script IS the 0002-only recipe (MAME's harness is Lua, not a
#          patch), and a separate mirror leaves the gates' instrument untouched.
# Then the Homebrew libraries the recipe linked by ABSOLUTE PATH are bundled
# beside the binary (tools/bundle_dylibs.py: @loader_path, ad-hoc signed, no
# absolute non-system reference left — verified on the artifact), because a
# user's Mac has no /opt/homebrew/opt/sdl3 at that path. The record states the
# minimum macOS the artifact carries (LC_BUILD_VERSION minos — inherited from
# Homebrew's bottles, which are built per OS release: 26.0 on this host).
#
# macOS ONLY today. On another OS it refuses and names what that host's session
# must add: the bundling step (Linux: patchelf --set-rpath '$ORIGIN' + the ldd
# closure, or a static SDL; Windows: the DLLs beside the .exe) and the os-arch
# name. The recipe half is identical there.
#
# The gate for the result is tests/test_release_binaries.sh (record, references,
# signature, profile, and a BOOT of the current merged romset on each binary).
# Build here, measure there — never in one command ([VSP-40]).
set -eu

KIND="${1:?usage: tools/build_release_emulators.sh fbneo|mame}"
REPO="$(cd "$(dirname "$0")/.." && pwd)"
SCRATCH="${BUILD_SCRATCH:-$HOME/.cache/vampire-saved}"
ROOT="${RELEASE_EMULATORS:-$REPO/release/emulators}"
JOBS="${JOBS:-$(nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 4)}"

case "$(uname -s)" in
Darwin) OS=macos ;;
*)  echo "REFUSING: this script bundles libraries the macOS way (install_name_tool," >&2
    echo "  codesign). On $(uname -s) the recipe half is the same but the bundling" >&2
    echo "  step and the os-arch name must be added by that host's session." >&2
    exit 2 ;;
esac
case "$(uname -m)" in
arm64|aarch64) ARCH=arm64 ;;
x86_64) ARCH=x86_64 ;;
*) echo "unknown arch $(uname -m)" >&2; exit 2 ;;
esac
OSARCH="$OS-$ARCH"
case "$SCRATCH" in *[[:space:]]*) echo "BUILD_SCRATCH has a space: '$SCRATCH'" >&2; exit 1 ;; esac
OUT="$ROOT/$KIND/$OSARCH"
HOST="macOS $(sw_vers -productVersion) ($ARCH), $(clang --version | head -1)"
DATE="$(date -u +%Y-%m-%d)"

minos() { otool -l "$1" | awk '/LC_BUILD_VERSION/{f=1} f && /minos/{print $2; exit}'; }

case "$KIND" in
fbneo)
    PATCH="$REPO/emu/fbneo-patches/0002-cps2-wide-v1.patch"
    PIN="$(git -C "$REPO" rev-parse HEAD:emu/fbneo)"
    CHECKED="$(git -C "$REPO/emu/fbneo" rev-parse HEAD)"
    [ "$PIN" = "$CHECKED" ] || {
        echo "emu/fbneo is checked out at $CHECKED but the committed pin is $PIN" >&2
        echo "  (a prebuilt must be the PINNED tree — fix the submodule first)" >&2; exit 1; }
    WT="$SCRATCH/fbneo-release"
    if [ -d "$WT" ]; then
        git -C "$REPO/emu/fbneo" worktree remove --force "$WT" 2>/dev/null || rm -rf "$WT"
    fi
    git -C "$REPO/emu/fbneo" worktree prune
    git -C "$REPO/emu/fbneo" worktree add --detach "$WT" "$PIN" >/dev/null
    echo "fbneo: clean worktree of $PIN at $WT"
    git -C "$WT" apply "$PATCH"
    # Assert the STATE of the tree, not the exit code: the profile present, the harness ABSENT.
    grep -q Cps2Wide "$WT/src/burn/drv/capcom/cps.h" || { echo "0002 did not land" >&2; exit 1; }
    [ ! -f "$WT/src/burner/sdl/harness.cpp" ] || { echo "harness present in a release tree" >&2; exit 1; }
    echo "fbneo: patch 0002 applied, harness absent (verified)"
    # TWO PASSES on a fresh tree (measured 14z-149, docs/platform/gotchas.md
    # [CPE-26]): burn.o's prerequisite is the GENERATED driverlist.h, whose rule
    # runs only after every driver object exists, so a parallel first pass
    # schedules burn.o early and dies with "No rule to make target
    # driverlist.h". `-k` lets the pass finish everything else (the list
    # included); the second pass builds burn.o and links. A second pass on a
    # complete tree is a no-op, so the recipe is the same for every host.
    ( cd "$WT" && make sdl2 SKIPDEPEND=1 -j"$JOBS" -k ) > "$WT/build.log" 2>&1 || true
    ( cd "$WT" && make sdl2 SKIPDEPEND=1 -j"$JOBS" ) >> "$WT/build.log" 2>&1 || {
        tail -30 "$WT/build.log" >&2; echo "fbneo build FAILED (log: $WT/build.log)" >&2; exit 1; }
    BIN="$WT/fbneo"
    strings -a "$BIN" | grep -q "CPS-2 WIDE v1" || { echo "built fbneo does NOT carry the profile" >&2; exit 1; }
    ! strings -a "$BIN" | grep -q -- "-hframes" || { echo "built fbneo carries the HARNESS (-hframes)" >&2; exit 1; }
    echo "fbneo: built, carries the profile, no harness (verified on the binary)"
    rm -rf "$OUT"; mkdir -p "$OUT"; cp "$BIN" "$OUT/fbneo"
    # sdl2-compat dlopen()s SDL3 as @executable_path/libSDL3.dylib — invisible to otool.
    SDL3="$(brew --prefix sdl3 2>/dev/null)/lib/libSDL3.dylib"
    [ -f "$SDL3" ] || { echo "no libSDL3.dylib at $SDL3 (brew install sdl3)" >&2; exit 1; }
    python3 "$REPO/tools/bundle_dylibs.py" "$OUT" "$OUT/fbneo" --extra "$SDL3:libSDL3.dylib"
    UPSTREAM="https://github.com/finalburnneo/FBNeo"
    RECIPE="git clone $UPSTREAM fbneo && cd fbneo && git checkout $PIN && git apply 0002-cps2-wide-v1.patch && make sdl2 SKIPDEPEND=1 -j$JOBS -k; make sdl2 SKIPDEPEND=1 -j$JOBS   (twice on a fresh clone: the first parallel pass dies on burn.o until the driver list is generated)"
    EXE=fbneo
    TITLE="fbneo — FBNeo (SDL2 frontend) carrying the CPS-2 WIDE v1 driver patch, prebuilt for $OSARCH"
    RUN='run it from a directory that has a `roms/` subdirectory holding your built vsavjw.zip AND your pristine vsav.zip (FBNeo has no rom-path option: it reads `roms/` relative to the current directory, or the paths set in its config): `./fbneo vsavjw`. Controls: FBNeo'"'"'s own menu (Tab).'
    LIBS="SDL2 (sdl2-compat over SDL3), SDL2_image and their image codecs"
    ;;
mame)
    PATCH="$REPO/emu/mame-patches/0002-cps2-wide-v1.patch"
    PIN="$(git -C "$REPO" rev-parse HEAD:emu/mame)"
    MIRROR="$SCRATCH/mame-release"
    MAME_BUILD_ROOT="$MIRROR" MAME_JOBS="$JOBS" "$REPO/tools/setup_mame.sh" > "$SCRATCH/mame-release.log" 2>&1 || {
        tail -30 "$SCRATCH/mame-release.log" >&2; echo "mame build FAILED (log: $SCRATCH/mame-release.log)" >&2; exit 1; }
    grep -q "verified: binary carries the vsavjw driver" "$SCRATCH/mame-release.log" || {
        echo "setup_mame.sh did not verify the driver" >&2; exit 1; }
    BIN="$MIRROR/cps2"
    echo "mame: built at $BIN (tools/setup_mame.sh, its own mirror, patch 0002 verified)"
    rm -rf "$OUT"; mkdir -p "$OUT"; cp "$BIN" "$OUT/cps2"
    python3 "$REPO/tools/bundle_dylibs.py" "$OUT" "$OUT/cps2"
    UPSTREAM="https://github.com/mamedev/mame"
    RECIPE="git clone $UPSTREAM mame && cd mame && git checkout $PIN && git apply 0002-cps2-wide-v1.patch && make SUBTARGET=cps2 SOURCES=src/mame/capcom/cps2.cpp NOWERROR=1 REGENIE=1 -j$JOBS"
    EXE=cps2
    TITLE="cps2 — MAME 0.288, CPS-2 subtarget, carrying the CPS-2 WIDE v1 driver patch, prebuilt for $OSARCH"
    RUN='`./cps2 vsavjw -rompath "/path/to/your/built/set;/path/to/your/dumps"` (the built vsavjw.zip and the pristine vsav.zip must both be on the rompath). `./cps2 -verifyroms vsavjw -rompath ...` says `is bad` BY DESIGN and must list exactly the members inside vsavjw.zip as INCORRECT CHECKSUM (stock CRCs for the members the port rewrites, sentinel CRCs for the new ones) — a NOT FOUND line is the real problem. MAME'"'"'s own UI (Tab) maps controls.'
    LIBS="SDL3"
    ;;
*)  echo "unknown kind '$KIND' (fbneo|mame)" >&2; exit 2 ;;
esac

PATCH_SHA1="$(shasum "$PATCH" | cut -c1-40)"
MINOS="$(minos "$OUT/$EXE")"
{
    echo "$TITLE"
    printf '%s\n' "$TITLE" | sed 's/./=/g'
    echo
    echo "# Every file in this directory, and its sha256 — verify before running:"
    echo "#   awk '/^sha256 /{print \$2\"  \"\$3}' BINARY.txt | shasum -a 256 -c      (macOS/Linux)"
    for f in "$OUT"/*; do
        case "$(basename "$f")" in BINARY.txt) ;; *)
            echo "sha256 $(shasum -a 256 "$f" | cut -c1-64) $(basename "$f")" ;;
        esac
    done
    echo
    echo "upstream   $UPSTREAM"
    echo "pin        $PIN"
    echo "patch      0002-cps2-wide-v1.patch  sha1 $PATCH_SHA1  (the ONLY patch applied; the project's replay-harness patch is a test instrument and is not in this binary)"
    echo "recipe     $RECIPE"
    echo "built      $DATE on $HOST, by tools/build_release_emulators.sh $KIND"
    echo "requires   macOS $MINOS or later, $ARCH. Nothing to install: the libraries the recipe links from Homebrew ($LIBS) are bundled here with @loader_path install names, all ad-hoc signed."
    echo "run        $RUN"
    echo "gatekeeper the binary is ad-hoc signed, NOT notarized: macOS quarantines a downloaded copy and refuses it on first launch. Either right-click > Open once on the executable, or run \`xattr -dr com.apple.quarantine .\` inside this directory."
    echo "not works  \"Unknown system: vsavjw\" means the binary is not this one (no driver patch). A stock emulator fed the set renamed to vsavj.zip STALLS on the legal screen forever (measured 2026-09-11) — renaming is never the fix."
    echo "provenance a prebuilt is the recipe above run on one host and nothing else; the reviewable trust surface stays the patch (its sha1 above). Rebuild from the recipe to check: the binary is rebuildable, not byte-reproducible (link order, timestamps)."
} > "$OUT/BINARY.txt"
echo "record: $OUT/BINARY.txt"
echo "built: $OUT/$EXE  (minos $MINOS, $(du -sh "$OUT" | cut -f1) with libraries)"
echo "next:  ROMDIR=... tests/test_release_binaries.sh   # record, references, signature, profile, BOOT"
