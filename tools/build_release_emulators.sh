#!/bin/sh
# build_release_emulators.sh — build the PREBUILT emulator binaries a release ships
# (maintainer-ruled 2026-09-11: the recipe AND the prebuilt, each user free to
# choose) into the build resource release/emulators/<platform>/<os-arch>/, with
# the BINARY.txt record tools/package_release_platforms.py hash-verifies into
# every release's emulator/bin/<os-arch>/.
#
# Usage: tools/build_release_emulators.sh fbneo|mame
#        CHECK=1 tools/build_release_emulators.sh fbneo   # resolve and PRINT the
#                                                         # plan for this host, build nothing
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
# Then the libraries the recipe linked out of the host's package manager are
# bundled beside the binary, because a player's machine does not have them:
#
#   macOS    tools/bundle_dylibs.py     @loader_path + ad-hoc signature
#   Linux    tools/bundle_elf_libs.py   patchelf --set-rpath '$ORIGIN'
#   Windows  tools/bundle_win_dlls.py   the DLLs beside the .exe (nothing to rewrite)
#
# ALL THREE OSes SINCE ITEM 1 OF THE 14z-149 CLOSE. macOS is the host this was
# written and measured on; the Linux and Windows halves were written for the
# maintainer's own machines (WSL2 / MSYS2 — ruled 14z-149 (4): a script they
# run, not a remote session) and have never been executed. What IS proven off
# those hosts is `tests/test_bundle_parsers.sh` (the parsers, the closure walk
# and both bundlers' refusal of an empty closure, against stub tools); what is
# NOT is the built binary, which is `tests/test_release_binaries.sh`'s job ON
# that host. `CHECK=1` prints what this host resolves without building.
#
# The gate for the result is tests/test_release_binaries.sh (record, references,
# signature where the OS has one, profile, and a BOOT of the current merged
# romset on each binary). Build here, measure there — never in one command
# ([VSP-40]).
set -eu

KIND="${1:?usage: [CHECK=1] tools/build_release_emulators.sh fbneo|mame}"
REPO="$(cd "$(dirname "$0")/.." && pwd)"
SCRATCH="${BUILD_SCRATCH:-$HOME/.cache/vampire-saved}"
ROOT="${RELEASE_EMULATORS:-$REPO/release/emulators}"
JOBS="${JOBS:-$(nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 4)}"

# ---- THIS HOST -------------------------------------------------------------
# One block resolves everything that differs per OS, so the build and record
# steps below read variables instead of branching in five places.
#
# THE VARIABLE IS `HOSTOS` AND MUST NEVER GO BACK TO `OS` (2026-09-12, the
# maintainer's first real MSYS2 run). `OS` is an EXPORTED Windows environment
# variable holding `Windows_NT`, and a POSIX assignment to an already-exported
# name KEEPS the export attribute — so `OS=windows` here silently replaced it
# in the environment every child inherits. Both build systems key on that exact
# value: FBNeo's `makefile.sdl2` and MAME's `makefile` each test
# `ifeq ($(OS),Windows_NT)`. FBNeo therefore built as if for Linux and died at
# the link with `cannot find -lGL` (the X11 name; Windows wants -lopengl32),
# having also compiled every object without -DSDL_WINDOWS; MAME would have
# configured GENIEOS=linux and been worse. Same family as the `CONTROL` env
# collision of 14z-147: a short, obvious name is one somebody else already owns.
EXESUF=""; SIGNED=""
case "$(uname -s)" in
Darwin)
    HOSTOS=macos
    BUNDLER=bundle_dylibs.py
    HOST="macOS $(sw_vers -productVersion) ($(uname -m)), $(clang --version | head -1)"
    SDL3LIB=libSDL3.dylib
    SIGNED=" all ad-hoc signed"
    FIRSTRUN="gatekeeper the binary is ad-hoc signed, NOT notarized: macOS quarantines a downloaded copy and refuses it on first launch. Either right-click > Open once on the executable, or run \`xattr -dr com.apple.quarantine .\` inside this directory."
    ;;
Linux)
    HOSTOS=linux
    BUNDLER=bundle_elf_libs.py
    HOST="$( (. /etc/os-release 2>/dev/null && echo "$PRETTY_NAME") || uname -sr ) ($(uname -m)), $( (cc --version 2>/dev/null || gcc --version) | head -1 )"
    SDL3LIB=libSDL3.so.0
    FIRSTRUN="first run  no signature and no quarantine on Linux: \`chmod +x\` the executable if your unzip dropped the bit, then run it from this directory. The sha256 rows above are the integrity check."
    ;;
MINGW*|MSYS*|CYGWIN*)
    HOSTOS=windows
    BUNDLER=bundle_win_dlls.py
    EXESUF=".exe"
    HOST="Windows via ${MSYSTEM:-MSYS2} ($(uname -m)), $( (cc --version 2>/dev/null || gcc --version) | head -1 )"
    SDL3LIB=SDL3.dll
    FIRSTRUN="first run  Windows SmartScreen warns about an unsigned download: More info > Run anyway. Keep every file in this folder TOGETHER — the .exe finds its DLLs beside itself. The sha256 rows above are the integrity check."
    ;;
*)  echo "REFUSING: unknown OS $(uname -s) — this script knows macOS, Linux and" >&2
    echo "  Windows (MSYS2). Add its bundling step and os-arch name first." >&2
    exit 2 ;;
esac
case "$(uname -m)" in
arm64|aarch64) ARCH=arm64 ;;
x86_64|amd64)  ARCH=x86_64 ;;
*) echo "unknown arch $(uname -m)" >&2; exit 2 ;;
esac
OSARCH="$HOSTOS-$ARCH"
case "$KIND" in
fbneo) EXENAME="fbneo$EXESUF" ;;
mame)  EXENAME="cps2$EXESUF" ;;
*) echo "unknown kind '$KIND' (fbneo|mame)" >&2; exit 2 ;;
esac
case "$SCRATCH" in *[[:space:]]*) echo "BUILD_SCRATCH has a space: '$SCRATCH'" >&2; exit 1 ;; esac
OUT="$ROOT/$KIND/$OSARCH"
DATE="$(date -u +%Y-%m-%d)"

# sha256 is spelled differently on each host; neither tool is universal.
sha256_of() {
    if command -v shasum >/dev/null 2>&1; then shasum -a 256 "$1" | cut -c1-64
    elif command -v sha256sum >/dev/null 2>&1; then sha256sum "$1" | cut -c1-64
    else echo "no shasum(1) or sha256sum(1) on this host" >&2; exit 1; fi
}
sha1_of() {
    if command -v shasum >/dev/null 2>&1; then shasum "$1" | cut -c1-40
    elif command -v sha1sum >/dev/null 2>&1; then sha1sum "$1" | cut -c1-40
    else echo "no shasum(1) or sha1sum(1) on this host" >&2; exit 1; fi
}

# THE MINIMUM THE ARTIFACT CARRIES, measured rather than assumed — the twin of
# the macOS LC_BUILD_VERSION minos line on every platform.
requires_line() {  # requires_line <dir> <exe> <libs description>
    _d="$1"; _e="$2"; _libs="$3"
    case "$HOSTOS" in
    macos)
        _min="$(otool -l "$_d/$_e" | awk '/LC_BUILD_VERSION/{f=1} f && /minos/{print $2; exit}')"
        echo "requires   macOS $_min or later, $ARCH. Nothing to install: the libraries the recipe links from Homebrew ($_libs) are bundled here with @loader_path install names,$SIGNED." ;;
    linux)
        _min="$(python3 -c 'import sys; sys.path.insert(0, sys.argv[1]); import bundle_elf_libs as e; print(e.glibc_floor(sys.argv[2:]))' \
                 "$REPO/tools" "$_d/$_e" 2>/dev/null || echo unknown)"
        echo "requires   glibc $_min or newer, $ARCH (built on $HOST — glibc is backward compatible, never forward, so an OLDER distribution than the build host will refuse to start). The libraries the recipe links from the package manager ($_libs) are bundled here and found through RUNPATH=\$ORIGIN. DELIBERATELY NOT bundled, because they belong to your machine: glibc itself, the GPU stack (libGL/libEGL/libdrm), the X11/Wayland and udev/dbus clients, and ALSA/PulseAudio — install your distribution's SDL2 runtime dependencies if the binary reports a missing one." ;;
    windows)
        echo "requires   Windows 10 or later, $ARCH. Nothing to install: the DLLs the recipe links from MSYS2 ($_libs) sit beside the .exe, where the loader looks first. Keep the folder together." ;;
    esac
}

if [ "${CHECK:-0}" = 1 ]; then
    echo "host       $HOST"
    echo "os-arch    $OSARCH"
    echo "kind       $KIND     executable: $EXENAME"
    echo "bundler    tools/$BUNDLER"
    [ "$KIND" = fbneo ] && echo "sdl3 probe $SDL3LIB   (bundled only when the linked SDL2 is sdl2-compat)"
    echo "out        $OUT"
    echo "jobs       $JOBS      scratch: $SCRATCH"
    echo "(CHECK=1: nothing was built, nothing was written)"
    exit 0
fi

# sdl2-compat loads SDL3 at RUN TIME (dlopen / LoadLibrary), so no load command,
# DT_NEEDED or import table names it — the string inside the SDL2 library is the
# only evidence, on every platform. Bundle it only when that string is there:
# a distribution shipping real SDL2 has no SDL3 to find, and demanding one would
# refuse a perfectly good host.
extra_sdl3_args() {  # extra_sdl3_args <path to the linked libSDL2> -> prints --extra ... or nothing
    _sdl2="$1"
    [ -n "$_sdl2" ] && [ -f "$_sdl2" ] || return 0
    strings -a "$_sdl2" 2>/dev/null | grep -q "$SDL3LIB" || return 0
    _dir="$(dirname "$_sdl2")"
    for _c in "$_dir/$SDL3LIB" "$_dir/../lib/$SDL3LIB" "$(dirname "$_dir")/bin/$SDL3LIB"; do
        [ -f "$_c" ] && { echo "--extra $_c:$SDL3LIB"; return 0; }
    done
    echo "REFUSING: the linked SDL2 is sdl2-compat (it names $SDL3LIB) but $SDL3LIB" >&2
    echo "  is not beside it — install the SDL3 runtime and rebuild." >&2
    exit 1
}

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
    BIN="$WT/$EXENAME"
    [ -f "$BIN" ] || { echo "fbneo build produced no $BIN" >&2; exit 1; }
    strings -a "$BIN" | grep -q "CPS-2 WIDE v1" || { echo "built fbneo does NOT carry the profile" >&2; exit 1; }
    ! strings -a "$BIN" | grep -q -- "-hframes" || { echo "built fbneo carries the HARNESS (-hframes)" >&2; exit 1; }
    echo "fbneo: built, carries the profile, no harness (verified on the binary)"
    rm -rf "$OUT"; mkdir -p "$OUT"; cp "$BIN" "$OUT/$EXENAME"
    # Where the recipe's own SDL2 came from: sdl2-config is what the makefile used.
    SDL2DIR="$(sdl2-config --prefix 2>/dev/null || true)"
    SDL2LIB=""
    for c in "$SDL2DIR/lib/libSDL2-2.0.0.dylib" "$SDL2DIR/lib/libSDL2-2.0.so.0" "$SDL2DIR/bin/SDL2.dll"; do
        [ -f "$c" ] && { SDL2LIB="$c"; break; }
    done
    # shellcheck disable=SC2046  # the helper prints zero or two arguments by design
    python3 "$REPO/tools/$BUNDLER" "$OUT" "$OUT/$EXENAME" $(extra_sdl3_args "$SDL2LIB")
    UPSTREAM="https://github.com/finalburnneo/FBNeo"
    RECIPE="git clone $UPSTREAM fbneo && cd fbneo && git checkout $PIN && git apply 0002-cps2-wide-v1.patch && make sdl2 SKIPDEPEND=1 -j$JOBS -k; make sdl2 SKIPDEPEND=1 -j$JOBS   (twice on a fresh clone: the first parallel pass dies on burn.o until the driver list is generated)"
    EXE="$EXENAME"
    TITLE="fbneo — FBNeo (SDL2 frontend) carrying the CPS-2 WIDE v1 driver patch, prebuilt for $OSARCH"
    RUN='run it from a directory that has a `roms/` subdirectory holding your built vsavjw.zip AND your pristine vsav.zip (FBNeo has no rom-path option: it reads `roms/` relative to the current directory, or the paths set in its config): `./'"fbneo$EXESUF"' vsavjw`. Controls: FBNeo'"'"'s own menu (Tab).'
    LIBS="SDL2 (sdl2-compat over SDL3 where the host uses it), SDL2_image and their image codecs"
    ;;
mame)
    PATCH="$REPO/emu/mame-patches/0002-cps2-wide-v1.patch"
    PIN="$(git -C "$REPO" rev-parse HEAD:emu/mame)"
    MIRROR="$SCRATCH/mame-release"
    MAME_BUILD_ROOT="$MIRROR" MAME_JOBS="$JOBS" "$REPO/tools/setup_mame.sh" > "$SCRATCH/mame-release.log" 2>&1 || {
        tail -30 "$SCRATCH/mame-release.log" >&2; echo "mame build FAILED (log: $SCRATCH/mame-release.log)" >&2; exit 1; }
    grep -q "verified: binary carries the vsavjw driver" "$SCRATCH/mame-release.log" || {
        echo "setup_mame.sh did not verify the driver" >&2; exit 1; }
    BIN="$MIRROR/$EXENAME"
    [ -f "$BIN" ] || { echo "mame build produced no $BIN" >&2; exit 1; }
    echo "mame: built at $BIN (tools/setup_mame.sh, its own mirror, patch 0002 verified)"
    rm -rf "$OUT"; mkdir -p "$OUT"; cp "$BIN" "$OUT/$EXENAME"
    python3 "$REPO/tools/$BUNDLER" "$OUT" "$OUT/$EXENAME"
    UPSTREAM="https://github.com/mamedev/mame"
    RECIPE="git clone $UPSTREAM mame && cd mame && git checkout $PIN && git apply 0002-cps2-wide-v1.patch && make SUBTARGET=cps2 SOURCES=src/mame/capcom/cps2.cpp NOWERROR=1 REGENIE=1 -j$JOBS"
    EXE="$EXENAME"
    TITLE="cps2 — MAME 0.288, CPS-2 subtarget, carrying the CPS-2 WIDE v1 driver patch, prebuilt for $OSARCH"
    RUN='`./'"cps2$EXESUF"' vsavjw -rompath "/path/to/your/built/set;/path/to/your/dumps"` (the built vsavjw.zip and the pristine vsav.zip must both be on the rompath). `./'"cps2$EXESUF"' -verifyroms vsavjw -rompath ...` says `is bad` BY DESIGN and must list exactly the members inside vsavjw.zip as INCORRECT CHECKSUM (stock CRCs for the members the port rewrites, sentinel CRCs for the new ones) — a NOT FOUND line is the real problem. MAME'"'"'s own UI (Tab) maps controls.'
    LIBS="SDL3"
    ;;
*)  echo "unknown kind '$KIND' (fbneo|mame)" >&2; exit 2 ;;
esac

PATCH_SHA1="$(sha1_of "$PATCH")"
{
    echo "$TITLE"
    printf '%s\n' "$TITLE" | sed 's/./=/g'
    echo
    echo "# Every file in this directory, and its sha256 — verify before running:"
    echo "#   awk '/^sha256 /{print \$2\"  \"\$3}' BINARY.txt | shasum -a 256 -c     (macOS, or any host with perl)"
    echo "#   awk '/^sha256 /{print \$2\"  \"\$3}' BINARY.txt | sha256sum -c        (Linux, MSYS2)"
    for f in "$OUT"/*; do
        case "$(basename "$f")" in BINARY.txt) ;; *)
            echo "sha256 $(sha256_of "$f") $(basename "$f")" ;;
        esac
    done
    echo
    echo "upstream   $UPSTREAM"
    echo "pin        $PIN"
    echo "patch      0002-cps2-wide-v1.patch  sha1 $PATCH_SHA1  (the ONLY patch applied; the project's replay-harness patch is a test instrument and is not in this binary)"
    echo "recipe     $RECIPE"
    echo "built      $DATE on $HOST, by tools/build_release_emulators.sh $KIND"
    requires_line "$OUT" "$EXE" "$LIBS"
    echo "run        $RUN"
    echo "$FIRSTRUN"
    echo "not works  \"Unknown system: vsavjw\" means the binary is not this one (no driver patch). A stock emulator fed the set renamed to vsavj.zip STALLS on the legal screen forever (measured 2026-09-11) — renaming is never the fix."
    echo "provenance a prebuilt is the recipe above run on one host and nothing else; the reviewable trust surface stays the patch (its sha1 above). Rebuild from the recipe to check: the binary is rebuildable, not byte-reproducible (link order, timestamps)."
} > "$OUT/BINARY.txt"
echo "record: $OUT/BINARY.txt"
echo "built: $OUT/$EXE  ($(du -sh "$OUT" | cut -f1) with libraries)"
echo "next:  ROMDIR=... tests/test_release_binaries.sh   # record, references, signature, profile, BOOT"
