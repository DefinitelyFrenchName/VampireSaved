#!/bin/sh
# preflight_release_build.sh — before you spend forty minutes on a build that
# dies at the end, ask this host whether it has what the build needs.
#
# Usage:  sh preflight_release_build.sh            # from the bundle, before cloning
#         tools/preflight_release_build.sh         # from inside the repository
#         ROMDIR=~/roms tools/preflight_release_build.sh    # also audits the dumps
#
# It BUILDS NOTHING and WRITES NOTHING. It detects the environment, names the
# os-arch the binaries will be filed under, checks every tool and library the
# two tracks need, and prints the exact install command for whatever is
# missing. Exit 0 = this host can build; exit 1 = something essential is
# missing (every missing item is named); exit 2 = the environment itself is
# not one of the two.
#
# WHY IT EXISTS (14z-150). The Linux and Windows halves of
# tools/build_release_emulators.sh were written on a Mac that has neither OS,
# so the first real run is the maintainer's. The expensive failure mode is not
# a bug in those halves — it is MAME dying several minutes in because
# pkg-config cannot see SDL3, or FBNeo linking against an SDL2 that is not
# there, both of which are one question asked up front.
#
# THE TWO TRACKS, and they are the SAME MACHINE in this project's case:
#   WSL2 (Ubuntu)          -> linux-x86_64    binaries for Linux players
#   MSYS2 MINGW64 shell    -> windows-x86_64  binaries for Windows players
set -u

RED=0
say()  { printf '%s\n' "$*"; }
ok()   { printf '  ok      %s\n' "$*"; }
bad()  { printf '  MISSING %s\n' "$*"; RED=1; }
warn() { printf '  note    %s\n' "$*"; }

have() { command -v "$1" >/dev/null 2>&1; }

# ---- which environment is this? -------------------------------------------
case "$(uname -s)" in
Linux)
    if grep -qi microsoft /proc/version 2>/dev/null; then ENV=wsl2; else ENV=linux; fi
    OSARCH="linux-$(uname -m)"; TRACK="Linux players" ;;
MINGW64*|MSYS*|MINGW*)
    ENV=msys2
    OSARCH="windows-$(uname -m)"; TRACK="Windows players" ;;
Darwin)
    say "This is macOS — it is already built and published. Nothing to do here."
    exit 2 ;;
*)
    say "Unknown environment $(uname -s): this preflight knows WSL2/Linux and MSYS2."
    exit 2 ;;
esac
# uname -m says x86_64 on both; normalise the way the builder does
case "$(uname -m)" in arm64|aarch64) OSARCH="${OSARCH%-*}-arm64" ;; amd64) OSARCH="${OSARCH%-*}-x86_64" ;; esac

say "=============================================================="
say "environment   $ENV   ($(uname -s) $(uname -m))"
say "os-arch       $OSARCH        -> binaries for $TRACK"
[ "$ENV" = msys2 ] && say "MSYSTEM       ${MSYSTEM:-<unset>}"
say "=============================================================="

# ---- the MSYS2 shell trap, first, because everything else depends on it ----
if [ "$ENV" = msys2 ]; then
    case "${MSYSTEM:-}" in
    MINGW64|UCRT64)
        ok "shell is $MSYSTEM (a native-Windows toolchain — correct)" ;;
    MSYS)
        bad "you are in the MSYS shell, not MINGW64. Binaries built here are"
        say  "          MSYS2-runtime (Cygwin-like) executables, NOT native Windows ones,"
        say  "          and they will not run on a player's machine."
        say  "          FIX: close this window and open 'MSYS2 MINGW64' from the Start menu." ;;
    *)
        bad "MSYSTEM is '${MSYSTEM:-<unset>}' — open the 'MSYS2 MINGW64' shell" ;;
    esac
fi

# ---- the common tools ------------------------------------------------------
say ""
say "-- common --"
for t in git python3 make patch rsync zip unzip; do
    if have "$t"; then ok "$t"; else bad "$t"; fi
done
if have timeout || have gtimeout; then ok "timeout (the gate needs it)"; else bad "timeout — coreutils"; fi
# python3 is spelled `python` in some MSYS2 installs
if ! have python3 && have python; then warn "python3 is absent but python exists — install mingw-w64-x86_64-python, the scripts call python3"; fi

# ---- the compiler and the binary inspectors --------------------------------
say ""
say "-- toolchain --"
if have gcc || have cc; then ok "a C compiler ($( (gcc --version 2>/dev/null || cc --version) | head -1 ))"; else bad "gcc"; fi
have g++ && ok "g++" || bad "g++ (FBNeo and MAME are C++)"
have strings && ok "strings (the profile assertion reads the built binary)" || bad "strings — binutils"
have objdump && ok "objdump" || bad "objdump — binutils"
have ldd && ok "ldd (the bundler's resolver)" || bad "ldd"
if [ "$ENV" != msys2 ]; then
    have readelf && ok "readelf (RUNPATH + the glibc floor)" || bad "readelf — binutils"
    have patchelf && ok "patchelf (sets RUNPATH=\$ORIGIN)" || bad "patchelf"
fi
have perl && ok "perl (FBNeo's build scripts)" || bad "perl"

# ---- the libraries the two recipes link ------------------------------------
say ""
say "-- libraries --"
# MAME'S OSD IS A DIFFERENT ONE PER PLATFORM, and this check demanded the macOS
# one everywhere until 2026-09-12, when the maintainer's Linux build died on a
# missing `fontconfig.pc` nothing had asked for. READ FROM THE PINNED SOURCE
# (`emu/mame/makefile` "specify OSD layer", `scripts/src/osd/sdl.lua`):
#   windows -> OSD `windows`  the native OSD: NO SDL at all
#   linux   -> OSD `sdl`      SDL2 + SDL2_ttf + fontconfig (sdl.lua links
#                             SDL2_ttf and asks pkg-config for fontconfig)
#   macosx  -> OSD `sdl3`     SDL3
# So SDL3 is a macOS requirement, not MAME's requirement, and demanding it on
# the other two hosts would refuse a host that can build perfectly well.
if have pkg-config || have pkgconf; then
    PKG="$(command -v pkg-config || command -v pkgconf)"
    ok "pkg-config ($PKG)"
    case "$ENV" in
    macos)
        if "$PKG" --exists sdl3 2>/dev/null; then
            ok "SDL3 $("$PKG" --modversion sdl3 2>/dev/null) — MAME's OSD on macOS"
        else
            bad "SDL3 (pkg-config cannot see it). MAME's OSD on macOS is sdl3 and finds"
            say  "          it ONLY through pkg-config; the build dies minutes in on"
            say  "          'SDL3/SDL.h' file not found."
        fi ;;
    wsl2|linux)
        if "$PKG" --exists fontconfig 2>/dev/null; then
            ok "fontconfig $("$PKG" --modversion fontconfig 2>/dev/null) — MAME's sdl OSD links it"
        else
            bad "fontconfig (pkg-config cannot see fontconfig.pc). MAME's OSD on Linux"
            say  "          is 'sdl' and asks pkg-config for it: sudo apt install -y libfontconfig-dev"
        fi
        if [ -f /usr/include/SDL2/SDL_ttf.h ] || "$PKG" --exists SDL2_ttf 2>/dev/null; then
            ok "SDL2_ttf — MAME's sdl OSD links it on Linux"
        else
            bad "SDL2_ttf development files — MAME's sdl OSD links -lSDL2_ttf:"
            say  "          sudo apt install -y libsdl2-ttf-dev"
        fi ;;
    msys2)
        ok "MAME needs no SDL here — its Windows OSD is the native one (makefile: TARGETOS=windows -> OSD=windows)" ;;
    esac
else
    bad "pkg-config / pkgconf — every recipe finds its libraries through it"
fi
if have sdl2-config; then
    ok "SDL2 $(sdl2-config --version 2>/dev/null) at $(sdl2-config --prefix 2>/dev/null) — FBNeo's frontend"
else
    bad "sdl2-config (SDL2 development files) — FBNeo's frontend"
fi
# SDL2_image has no config program; look for its header next to SDL2's
if have sdl2-config; then
    _inc="$(sdl2-config --prefix 2>/dev/null)/include"
    if [ -f "$_inc/SDL2/SDL_image.h" ] || [ -f "$_inc/SDL_image.h" ]; then
        ok "SDL2_image headers"
    else
        bad "SDL2_image development files (FBNeo links -lSDL2_image)"
    fi
fi

# ---- the dumps -------------------------------------------------------------
say ""
say "-- what this host will throw at the build --"
# THE 10x SLOWDOWN NOBODY SEES COMING (measured by the maintainer 2026-09-12:
# FBNeo similar on both tracks, MAME still running in WSL2 after ~10x the
# native Windows time on a 3900X, CPU pinned). The builders default to
# `-j$(nproc)`, and under WSL2 `nproc` is the HOST's logical processor count
# while the VM gets HALF the host's RAM by default — Microsoft's documented
# defaults: memory "50% of total memory on Windows", processors "the same
# number of logical processors on Windows", swap "25% of memory size".
# MAME's translation units are large, so 24 jobs against 16 GB is not a slow
# build, it is a thrashing one, and the CPU looks busy while it swaps.
_cores="$(nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo '?')"
_memkb="$(awk '/^MemTotal:/{print $2}' /proc/meminfo 2>/dev/null || true)"
if [ -z "$_memkb" ]; then
    _memb="$(sysctl -n hw.memsize 2>/dev/null || true)"
    [ -z "$_memb" ] || _memkb=$((_memb / 1024))
fi
if [ -n "$_memkb" ] && [ "$_cores" != "?" ]; then
    _memgb=$((_memkb / 1024 / 1024))
    _per10=$(( _memkb * 10 / 1024 / 1024 / _cores ))     # GB per job, tenths
    say "  $_cores job(s) by default (nproc), ${_memgb} GB visible -> $(( _per10 / 10 )).$(( _per10 % 10 )) GB per job"
    if [ "$_per10" -lt 12 ]; then
        warn "under ~1.2 GB per job MAME's larger translation units swap, and a"
        say  "          swapping build looks like a busy one: the CPU is pinned and the"
        say  "          wall clock is 10x. Use fewer jobs — MAME_JOBS=8 (or JOBS=8) —"
        say  "          and on WSL2 consider raising the VM's memory:"
        say  "            %UserProfile%\\.wslconfig   [wsl2]  memory=24GB  swap=8GB"
        say  "            then  wsl --shutdown  (the VM keeps HALF your RAM by default)"
    fi
fi
say ""
say "-- your ROM dumps --"
if [ -n "${ROMDIR:-}" ] && [ -d "$ROMDIR" ]; then
    _miss=""
    for z in vsavj.zip vsav.zip vsav2.zip; do
        [ -f "$ROMDIR/$z" ] || _miss="$_miss $z"
    done
    if [ -z "$_miss" ]; then
        ok "the three dumps the release needs are in \$ROMDIR (vsavj, vsav, vsav2)"
    else
        bad "\$ROMDIR is missing:$_miss"
    fi
    for z in vhunt2.zip vhunt2r1.zip qsound_hle.zip; do
        [ -f "$ROMDIR/$z" ] || warn "$z absent — only needed for the full harness, not for this build"
    done
    if [ -f tools/audit_roms.py ] && have python3; then
        if python3 tools/audit_roms.py "$ROMDIR" >/dev/null 2>&1; then
            ok "audit_roms: every member matches docs/checksums.txt"
        else
            warn "audit_roms reports a mismatch — run it directly and read it before building"
        fi
    fi
else
    warn "\$ROMDIR is not set (or not a directory) — set it to the folder holding your dumps"
    warn "  you need THREE: vsavj.zip, vsav.zip, vsav2.zip. They are never in this repository."
fi

# ---- repository context, when run from inside it ---------------------------
say ""
say "-- repository --"
if [ -f tools/build_release_emulators.sh ]; then
    ok "running from inside the repository"
    [ -d emu/fbneo/src ] && ok "emu/fbneo submodule is checked out" \
        || bad "emu/fbneo submodule — git submodule update --init --depth 1 emu/fbneo"
    [ -d emu/mame/src ] && ok "emu/mame submodule is checked out" \
        || bad "emu/mame submodule — git submodule update --init --depth 1 emu/mame"
    case "$(pwd)" in *\ *) bad "this path contains a SPACE — MAME's build system cannot handle one. Move the clone." ;;
                     *) ok "no space in the repository path" ;; esac
else
    warn "not inside the repository (that is fine for a first look) — clone it, then run"
    warn "  tools/preflight_release_build.sh from the clone for the rest of the checks"
fi
case "$(pwd)" in
/mnt/[a-z]/*) [ "$ENV" = wsl2 ] && bad "you are under /mnt/c — building across the Windows filesystem bridge is dramatically slower and has its own file-semantics surprises. Work in the Linux home directory (~)." ;;
esac

# ---- verdict ---------------------------------------------------------------
say ""
say "=============================================================="
if [ "$RED" = 0 ]; then
    say "READY — this host has what the build needs ($OSARCH)."
    say "Next: CHECK=1 tools/build_release_emulators.sh fbneo"
else
    say "NOT READY — install what is marked MISSING above, then re-run this."
    say ""
    case "$ENV" in
    wsl2|linux)
        say "  sudo apt update && sudo apt install -y build-essential python3 git rsync \\"
        say "       patch pkgconf zip unzip perl patchelf binutils coreutils \\"
        say "       libsdl2-dev libsdl2-image-dev libsdl2-ttf-dev libfontconfig-dev"
        say ""
        say "  NO SDL3 on Linux: MAME's OSD here is 'sdl' (SDL2 + SDL2_ttf + fontconfig)."
        say "  SDL3 is the macOS OSD only — measured from the pinned source 2026-09-12." ;;
    msys2)
        say "  pacman -S --needed git make patch rsync zip unzip perl coreutils \\"
        say "       mingw-w64-x86_64-gcc mingw-w64-x86_64-binutils mingw-w64-x86_64-python \\"
        say "       mingw-w64-x86_64-pkgconf mingw-w64-x86_64-SDL2 mingw-w64-x86_64-SDL2_image"
        say "  (SDL2 is CAPITALISED in MSYS2. MAME needs no SDL here at all — its Windows"
        say "   OSD is the native one; the SDL2 packages are FBNeo's.)"
        say ""
        say "  Run that from the MSYS2 MINGW64 shell, and re-open the shell afterwards." ;;
    esac
fi
say "=============================================================="
exit $RED
