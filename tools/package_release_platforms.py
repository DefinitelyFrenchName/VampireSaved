#!/usr/bin/env python3
"""package_release_platforms.py <build_rompath> <release_root> --romdir ROMDIR
                                --name NAME --version TEXT
                                [--mister-src DIR] [--bitstream DIR]
                                [--platforms fbneo,mame,mister]

THE PER-PLATFORM RELEASE (maintainer-ruled 2026-08-28, 14z-113; the format
is docs/project/release_format.md).  One release = release/<NAME>/ with ONE
SUBDIRECTORY PER PLATFORM, each SELF-SUFFICIENT — everything that platform
needs and nothing else — and every version releases ALL platforms even when
only one of them changed:

  release/<NAME>/
    fbneo/    the romset patch set (package_release.py output, FLAT) +
              emulator/0002-cps2-wide-v1.patch + EMULATOR.md (pin + recipe)
    mame/     the romset patch set + emulator/0002-cps2-wide-v1.patch +
              EMULATOR.md (pin + recipe)
    mister/   the romset patch set + the .mra files + jtcps2w.rbf +
              BITSTREAM.txt — the bitstream and its record come from the
              CANONICAL build resource release/bitstreams/<seed>/ (the seed
              named by release/bitstreams/CURRENT, or --bitstream DIR), and
              the .rbf is VERIFIED against the record's sha256 before it is
              copied. A release never copies a bitstream from another
              release (maintainer, 2026-08-28).

The romset patch set is COPIED into each platform directory rather than
shared (ruled: self-sufficiency beats de-duplication; ~2.5 MB x 3).  It is
produced by tools/package_release.py — this script never computes a patch
itself, so the round-trip / refusal / rule-7 guarantees of that tool hold
unchanged for every copy, and the three copies are asserted IDENTICAL
(manifest.json byte-for-byte) by tests/test_release_roundtrip.sh section 4.

The emulator side ships the driver PATCH and a build recipe AND, since the
maintainer's 2026-09-11 ruling (recipe and prebuilt, each user free to
choose), prebuilt binaries per OS from the build resource
release/emulators/<platform>/<os-arch>/ (hash-verified against BINARY.txt;
none for an OS until a host builds it — see binaries_side).  The MiSTer side ships the MRAs the
release was verified with (from the field bundle or tools/mister_mra.sh
--no-rom — deterministic XML, no ROM content); the bitstream and its RECORD
are pulled from release/bitstreams/ and hash-verified, so a stale CURRENT or a
tampered file is a hard error, never a silently wrong release.

Rule 7: nothing here reads a reference ROM except through package_release.py
(which reads them only to compute deltas), and nothing ROM-derived is written.
Deterministic: two runs produce byte-identical trees.
"""
import argparse, json, os, re, shutil, subprocess, sys, tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.dirname(HERE)
PLATFORMS = ("fbneo", "mame", "mister")

EMU = {
    "fbneo": dict(
        patch="emu/fbneo-patches/0002-cps2-wide-v1.patch",
        submodule="emu/fbneo",
        upstream="https://github.com/finalburnneo/FBNeo",
        recipe="""\
    git clone {upstream} fbneo && cd fbneo && git checkout {pin}
    git apply /path/to/emulator/0002-cps2-wide-v1.patch
    make sdl2 SKIPDEPEND=1 -j8 -k     # SKIPDEPEND=1 is mandatory: without it the build tries to
    make sdl2 SKIPDEPEND=1 -j8        # regenerate dependency files and fails. Run it TWICE on a fresh
                                      # clone: the parallel first pass can stop on burn.o until the
                                      # driver list is generated (-k lets it finish the rest); the
                                      # second pass completes it (a no-op if the first already did)
""",
        deps="""\
Install these first (the packages the project's own build hosts carry; a
missing one stops the build):

- **Linux (Ubuntu 24.04 / Debian):** `sudo apt install git build-essential libsdl2-dev libsdl2-image-dev`
- **macOS:** the Command Line Tools (`xcode-select --install`), then Homebrew
  `brew install sdl2 sdl2_image pkgconf`
- **Windows:** MSYS2, in its MINGW64 shell:
  `pacman -S git make patch perl mingw-w64-x86_64-gcc mingw-w64-x86_64-pkgconf mingw-w64-x86_64-SDL2 mingw-w64-x86_64-SDL2_image`
""",
        note="""\
The patch adds the `vsavjw` driver (the CPS-2 WIDE profile: 6 MB program,
48 MB GFX via the CPS-2 Turbo bit-12 tile promote, 16 MB QSound) as a new
driver entry beside `vsavj`. Stock `vsavj` and every other CPS-2 game are
untouched by construction — the only emulation-logic change is one widened
condition in `cps_obj.cpp`, gated on the `Cps2Wide` flag that only the new
driver sets. The project's other FBNeo patch (0001, the replay harness) is a
frontend-only test instrument and is NOT needed to play.
NETPLAY: this is a custom build — every peer needs the same binary AND the
same romset (the patched build's fingerprint is in ../manifest.json).
""",
    ),
    "mame": dict(
        patch="emu/mame-patches/0002-cps2-wide-v1.patch",
        submodule="emu/mame",
        upstream="https://github.com/mamedev/mame",
        recipe="""\
    git clone {upstream} mame && cd mame && git checkout {pin}     # tag mame0288
    git apply /path/to/emulator/0002-cps2-wide-v1.patch
    make SOURCES=src/mame/capcom/cps2.cpp SUBTARGET=cps2 -j8                  # macOS, Windows (MSYS2 MINGW64)
    make SOURCES=src/mame/capcom/cps2.cpp SUBTARGET=cps2 USE_QTDEBUG=0 -j8    # LINUX: MAME turns its Qt debugger
                                                                 # ON there by default, then stops on a missing `moc`;
                                                                 # USE_QTDEBUG=0 turns it off (no Qt is linked)
    ./cps2 -verifyroms vsavjw -rompath "/your/built/set"   # says "is bad" BY DESIGN: it lists every member the
                                                           # port rewrites or adds as INCORRECT CHECKSUM (the driver
                                                           # carries the stock CRCs for the members the port rewrites
                                                           # and sentinel CRCs for the new ones); the members copied
                                                           # unchanged from your dumps are not listed. Nothing may be
                                                           # NOT FOUND. "is good" is not reachable on this set.
    ./cps2 vsavjw -rompath "/your/built/set" -skip_gameinfo   # PLAY: -skip_gameinfo removes one of the two
                                                              # screens that wait for a key; the red box is the other
""",
        deps="""\
Install these first (the packages the project's own build hosts carry; a
missing one stops the build):

- **Linux (Ubuntu 24.04 / Debian):** `sudo apt install git build-essential python3 libsdl2-dev libsdl2-ttf-dev libfontconfig-dev qmake6`
  — `qmake6` is the tool only, no Qt is linked: MAME's Linux build asks it for a
  folder, and without it the build fails minutes in with `char8_t` errors.
- **macOS:** the Command Line Tools (`xcode-select --install`), then Homebrew
  `brew install sdl3 pkgconf`
- **Windows:** MSYS2, in its MINGW64 shell:
  `pacman -S git make patch mingw-w64-x86_64-gcc mingw-w64-x86_64-pkgconf mingw-w64-x86_64-python`
""",
        note="""\
The patch is 164 lines added and exactly ONE line removed (the sprite
tile-code composition, gated on `m_cps2_wide`, a driver member only the
`vsavjw` machine config sets). It adds the `vsavjw` ROM descriptor, one
`GAME()` row and one `mame.lst` row. A Homebrew/distribution MAME binary
cannot load this romset — it has no `vsavjw` driver — so a source build is
required. MAME's own `-verifyroms vsavjw` is the independent check that the
romset the applier produced is the one the driver expects.
""",
    ),
}



# ── THE LAUNCHER (2026-09-20, the maintainer's item 2: "either provide an alternate
# shell script that runs the emulator the way we want or at least make it super obvious
# what to do") ──────────────────────────────────────────────────────────────────────
# One `PLAY.command` per EMULATOR platform (MiSTer launches from its own menu, so it
# gets none). It encodes the three things `tools/run_wide.sh` had to learn and that a
# player has no way to know: that the set is `vsavjw` and only the patched build knows
# it; that FBNeo's SDL frontend has NO rom-path option and reads `roms/` relative to the
# CURRENT DIRECTORY, so browsing to the set in its GUI cannot work; and that a macOS
# download is quarantined and Gatekeeper refuses an ad-hoc-signed binary on first launch.
# Every failure exits non-zero naming its cause, and keeps the Terminal window open,
# because a double-clicked .command closes on exit and takes the message with it.
# `PLAY_DRY_RUN=1` stops before the emulator so tests/test_release_launcher.sh can drive
# every path; `PLAY_CLEAR_QUARANTINE=1` answers its one prompt for the same reason.

LAUNCHER = r'''#!/bin/sh
# PLAY.command — start VAMPIRE SAVED (@NAME@) on @PLATFORM_UPPER@.
#
# GENERATED by tools/package_release_platforms.py; do not edit by hand.
# Double-click it on macOS, or run `sh PLAY.command` from a terminal.
#
# It exists because getting this right by hand is the one step players were
# measured to fail: @WHY@
set -eu
HERE="$(cd "$(dirname "$0")" && pwd)"
cd "$HERE"

say()  { printf '%s\n' "$*"; }
pause() { printf '\nPress Return to close this window.\n'; read _dummy 2>/dev/null || true; }
die()  { printf '\n!! %s\n' "$1" >&2; shift; for _l in "$@"; do printf '   %s\n' "$_l" >&2; done; pause; exit 1; }

say "VAMPIRE SAVED @NAME@ — @PLATFORM_UPPER@"
say ""

# ── 1. which prebuilt binary belongs to this machine ───────────────────────
case "$(uname -s)" in
Darwin) OS=macos ;;
Linux)  OS=linux ;;
MINGW*|MSYS*|CYGWIN*) OS=windows ;;
*) die "unsupported system: $(uname -s)" "This launcher knows macOS, Linux and MSYS2/Windows." ;;
esac
ARCH="$(uname -m)"
case "$ARCH" in arm64|aarch64) ARCH=arm64 ;; x86_64|amd64) ARCH=x86_64 ;; esac
OSARCH="$OS-$ARCH"
EXE="@EXE@"
[ "$OS" = windows ] && EXE="$EXE.exe"
BIN="$HERE/emulator/bin/$OSARCH/$EXE"

if [ ! -f "$BIN" ]; then
    _have="$(ls emulator/bin 2>/dev/null | tr '\n' ' ' || true)"
    die "no prebuilt @PLATFORM@ for $OSARCH in this package." \
        "Present: ${_have:-none}" \
        "If you took the '-recipe' download, it ships the patch and EMULATOR.md" \
        "instead of a binary — build it once from those, then run it yourself." \
        "Otherwise no host has built $OSARCH yet."
fi
chmod +x "$BIN" 2>/dev/null || true

# ── 2. macOS quarantine (the binary is ad-hoc signed, NOT notarized) ───────
# A downloaded copy carries com.apple.quarantine and Gatekeeper refuses it on
# first launch. This is the one first-run problem on macOS and it is the
# player's own security state, so we ASK rather than silently clear it.
if [ "$OS" = macos ] && command -v xattr >/dev/null 2>&1; then
    if xattr -p com.apple.quarantine "$BIN" >/dev/null 2>&1; then
        say "macOS has quarantined this download, so it will refuse to launch."
        say "The binary is ad-hoc signed, not notarized — that is expected here."
        if [ -n "${PLAY_CLEAR_QUARANTINE:-}" ]; then
            _ans=y
        else
            printf 'Clear the quarantine flag on this folder now? [y/N] '
            read _ans 2>/dev/null || _ans=n
        fi
        case "$_ans" in
        y|Y|yes|YES)
            xattr -dr com.apple.quarantine "$HERE" || die "could not clear the quarantine flag." \
                "Run this yourself, then start again:" "  xattr -dr com.apple.quarantine '$HERE'"
            say "Cleared."
            ;;
        *)
            die "not cleared, so macOS will block the emulator." \
                "macOS shows: \"@EXE@\" Not Opened — Apple could not verify ..." \
                "with only Done and Move to Bin. RIGHT-CLICK > OPEN DOES NOT GET PAST IT" \
                "on current macOS. What works is clearing the flag:" \
                "  xattr -dr com.apple.quarantine '$HERE'" \
                "then start this launcher again."
            ;;
        esac
        say ""
    fi
fi

# ── 3. is this actually the patched emulator? ──────────────────────────────
@PROFILE_CHECK@

# ── 4. find the romset the applier built ──────────────────────────────────
# Looked for in the places a player plausibly puts it, and THE NEWEST WINS (#248,
# maintainer-ruled 2026-10-10: "prefer the newest one, always"): an old set left in
# roms/ from an earlier release must never shadow the one just built. On a tie (a
# link to the same file) the first in this list is kept.
ZIP=""
for _c in "$HERE/roms/vsavjw.zip" "$HERE/vsavjw.zip" "$HERE/rompath/vsavjw.zip"; do
    [ -f "$_c" ] || continue
    if [ -z "$ZIP" ] || [ "$_c" -nt "$ZIP" ]; then ZIP="$_c"; fi
done
if [ -z "$ZIP" ]; then
    die "vsavjw.zip not found." \
        "Build it from YOUR OWN dumps first — see README.md:" \
        "  python3 apply_release.py --romdir /path/to/your/dumps --out ./rompath" \
        "then put vsavjw.zip beside this launcher (or leave it in ./rompath/)."
fi
say "romset: $ZIP"
say "emulator: $BIN"
say ""

@LAUNCH@
'''

FBNEO_PROFILE = r'''if command -v strings >/dev/null 2>&1; then
    strings -a "$BIN" 2>/dev/null | grep -q "CPS-2 WIDE v1" || \
        die "that FBNeo does not carry the CPS-2 WIDE profile." \
            "Only a patched build knows the vsavjw set. Use this package's binary," \
            "or build one with emulator/0002-cps2-wide-v1.patch per EMULATOR.md."
fi'''

MAME_PROFILE = r'''"$BIN" -listfull vsavjw >/dev/null 2>&1 || \
    die "that MAME does not know the vsavjw driver." \
        "A stock or Homebrew MAME never will. Use this package's binary," \
        "or build one with emulator/0002-cps2-wide-v1.patch per EMULATOR.md."'''

# FBNeo has NO -rompath: src/burner/sdl reads szAppRomPaths, which defaults to
# "roms/" RELATIVE TO THE CURRENT DIRECTORY. Passing -rompath is silently
# ignored, which is exactly the "I cannot launch it" failure this script exists
# to remove. So: make ./roms/, put the set in it, and run from HERE.
FBNEO_LAUNCH = r'''if [ -L "$HERE/roms" ]; then
    die "./roms is a symlink (-> $(readlink "$HERE/roms"))." \
        "This launcher will not write through it. Remove the link and start again."
fi
mkdir -p "$HERE/roms"
# FBNeo reads roms/vsavjw.zip only, so the chosen set goes THERE, replacing an older
# one (#248: a stale copy left in place was what the emulator ran)
if [ "$ZIP" != "$HERE/roms/vsavjw.zip" ]; then
    rm -f "$HERE/roms/vsavjw.zip"
    ln -s "$ZIP" "$HERE/roms/vsavjw.zip" 2>/dev/null || cp "$ZIP" "$HERE/roms/vsavjw.zip"
fi
cd "$HERE"
# PLAY_DRY_RUN is how the project's own gate drives this script without starting
# an emulator; it changes nothing else, and every check above has already run.
if [ -n "${PLAY_DRY_RUN:-}" ]; then
    say "WOULD RUN: $BIN vsavjw (cwd $HERE, roms/vsavjw.zip present)"
    exit 0
fi
say "Starting. Tab opens FBNeo's own menu (controls, video, exit)."
say ""
exec "$BIN" vsavjw "$@"'''

MAME_LAUNCH = r'''# PLAY_DRY_RUN is how the project's own gate drives this script without starting
# an emulator; it changes nothing else, and every check above has already run.
if [ -n "${PLAY_DRY_RUN:-}" ]; then
    say "WOULD RUN: $BIN vsavjw -rompath $(dirname "$ZIP") -skip_gameinfo"
    exit 0
fi
say "Starting. Tab opens MAME's own menu (controls, video); Esc exits."
say ""
exec "$BIN" vsavjw -rompath "$(dirname "$ZIP")" -skip_gameinfo "$@"'''

WHY = {
    "fbneo": ("FBNeo's SDL build has no rom-path option at all, so it only ever looks in "
              "`roms/` next to the current directory. Browsing to the set in the GUI does not work."),
    "mame":  ("the set is `vsavjw`, which only the patched build knows, and it needs a rompath "
              "pointing at your built set — picking it from MAME's own list does not work."),
}


def launcher_text(platform, name):
    exe = "fbneo" if platform == "fbneo" else "cps2"
    t = LAUNCHER
    t = t.replace("@NAME@", name)
    t = t.replace("@PLATFORM_UPPER@", platform.upper())
    t = t.replace("@PLATFORM@", platform)
    t = t.replace("@EXE@", exe)
    t = t.replace("@WHY@", WHY[platform])
    t = t.replace("@PROFILE_CHECK@", FBNEO_PROFILE if platform == "fbneo" else MAME_PROFILE)
    t = t.replace("@LAUNCH@", FBNEO_LAUNCH if platform == "fbneo" else MAME_LAUNCH)
    return t


# ── THE WINDOWS LAUNCHER (14z-189, GitHub #145; maintainer-ruled 2026-10-03: "PLAY.bat
# launcher") ───────────────────────────────────────────────────────────────────────────
# #145 reproduced on ERIS with the published merged-m19 Windows assets: double-clicking
# fbneo.exe exits at once (it needs the game name), and cps2.exe finds no ROMs (it needs
# -rompath); both run with those arguments. PLAY.command cannot help there (no sh on a
# plain Windows), so every package also carries PLAY.bat: PLAIN CMD (no PowerShell, so
# no execution-policy prompt), CRLF, ASCII only, and every check of PLAY.command that
# applies on Windows (the binary for this machine, the profile, the romset, a linked
# roms folder), each failure naming its cause and pausing so a double-clicked window
# keeps the message. FBNeo: vsavjw.zip goes into roms\ BESIDE fbneo.exe and the game is
# started from that folder (the measured working layout, ERIS 2026-10-03); MAME: run from
# the package folder with -rompath at the romset's directory. No parenthesised blocks:
# a %VAR% holding "Program Files (x86)" inside one ends the block early. PLAY_DRY_RUN=1
# stops before the emulator, as in PLAY.command. tests/test_release_launcher_bat.sh holds
# its content; ERIS's live runs are the 14z-189 record (STATE).

LAUNCHER_BAT = r'''@echo off
rem PLAY.bat - start VAMPIRE SAVED (@NAME@) with @PLATFORM_UPPER@ on Windows.
rem
rem GENERATED by tools/package_release_platforms.py; do not edit by hand.
rem Double-click it in Explorer. Plain cmd: no PowerShell, no execution-policy prompt.
rem
rem It exists because getting this right by hand is the one step players were
rem measured to fail (GitHub #145): @WHY@
setlocal EnableExtensions
cd /d "%~dp0"
set "HERE=%CD%"
echo VAMPIRE SAVED @NAME@ - @PLATFORM_UPPER@ on Windows
echo.

rem -- 1. the prebuilt binary for this machine
set "BINDIR=%HERE%\emulator\bin\windows-x86_64"
set "BIN=%BINDIR%\@EXE@.exe"
if exist "%BIN%" goto have_bin
echo !! no prebuilt @PLATFORM@ for windows-x86_64 in this package.
echo    If you took the '-recipe' download, it ships the patch and EMULATOR.md
echo    instead of a binary - build it once from those, then run it yourself.
goto fail
:have_bin

rem -- 2. is this actually the patched emulator?
@PROFILE_CHECK@
:profile_ok

rem -- 3. find the romset the applier built: the NEWEST of the places a player puts it
rem    (GitHub 248, ruled 2026-10-10: an old set left from an earlier launch never wins)
set "ZIP="
for %%C in (@CANDIDATES@) do if exist "%%~C" call :consider "%%~C"
if defined ZIP goto have_zip
echo !! vsavjw.zip not found.
echo    Build it from YOUR OWN dumps first - see README.md. The easy way:
echo    double-click apply_release.html, then save the vsavjw.zip it gives you
echo    into the "rompath" folder beside this launcher. Or, with Python installed:
echo      py apply_release.py --romdir C:\path\to\your\dumps --out rompath
echo    Then start this launcher again.
goto fail
:have_zip
for %%Z in ("%ZIP%") do set "ZIPDIR=%%~dpZ"
set "ZIPDIR=%ZIPDIR:~0,-1%"
echo romset: %ZIP%
echo emulator: %BIN%
echo.

@LAUNCH@
set "RC=%ERRORLEVEL%"
if "%RC%"=="0" exit /b 0
echo.
echo The emulator exited with code %RC%. Its own messages are above.
pause
exit /b %RC%

:fail
echo.
pause
exit /b 1

rem -- consider one candidate: kept when it is the first, or NEWER than the one held.
rem    xcopy /d /l lists the source only when it is newer than the destination, so its
rem    output is two lines (the file, the count) when newer and one line otherwise; the
rem    count of lines does not depend on the language Windows speaks (measured on ERIS).
rem    Both tools by their FULL path: a PATH holding Git's or MSYS2's usr\bin finds a Unix
rem    find first, which reads /c as a folder and walks the whole C: drive (paid on ERIS).
:consider
if defined ZIP goto consider_cmp
set "ZIP=%~1"
exit /b 0
:consider_cmp
set "NEWER="
for /f %%L in ('%SystemRoot%\System32\xcopy.exe /d /y /l "%~1" "%ZIP%" ^| %SystemRoot%\System32\find.exe /c /v ""') do set "NEWER=%%L"
if "%NEWER%"=="2" set "ZIP=%~1"
exit /b 0
'''

FBNEO_PROFILE_BAT = r'''findstr /m /c:"CPS-2 WIDE v1" "%BIN%" >nul 2>&1
if not errorlevel 1 goto profile_ok
echo !! that FBNeo does not carry the CPS-2 WIDE profile.
echo    Only a patched build knows the vsavjw set. Use this package's binary,
echo    or build one with emulator\0002-cps2-wide-v1.patch per EMULATOR.md.
goto fail'''

MAME_PROFILE_BAT = r'''"%BIN%" -listfull vsavjw >nul 2>&1
if not errorlevel 1 goto profile_ok
echo !! that MAME does not know the vsavjw driver.
echo    A stock MAME never will. Use this package's binary,
echo    or build one with emulator\0002-cps2-wide-v1.patch per EMULATOR.md.
goto fail'''

# FBNeo: roms\ BESIDE fbneo.exe, started from that folder (#145's measured layout).
FBNEO_LAUNCH_BAT = r'''set "ROMS=%BINDIR%\roms"
if not exist "%ROMS%\" goto make_roms
set "RATTR="
for %%R in ("%ROMS%") do set "RATTR=%%~aR"
if /i "%RATTR:~8,1%"=="l" goto roms_link
goto roms_ok
:roms_link
echo !! the roms folder beside the emulator is a link or junction.
echo    This launcher will not write through it. Remove the link and start again.
goto fail
:make_roms
mkdir "%ROMS%"
if errorlevel 1 goto fail
:roms_ok
rem the chosen set goes into roms\, replacing an older copy (GitHub 248)
if /i "%ZIP%"=="%ROMS%\vsavjw.zip" goto roms_has
copy /y "%ZIP%" "%ROMS%\vsavjw.zip" >nul
if errorlevel 1 goto copy_failed
goto roms_has
:copy_failed
echo !! could not copy vsavjw.zip into %ROMS%
goto fail
:roms_has
cd /d "%BINDIR%"
rem PLAY_DRY_RUN is how the project's own gate drives this script without starting
rem an emulator; it changes nothing else, and every check above has already run.
if not defined PLAY_DRY_RUN goto launch
echo WOULD RUN: "%BIN%" vsavjw [cwd %BINDIR%, roms\vsavjw.zip present]
exit /b 0
:launch
echo Starting. Tab opens FBNeo's own menu - controls, video, exit.
echo.
"%BIN%" vsavjw %*'''

MAME_LAUNCH_BAT = r'''cd /d "%HERE%"
rem PLAY_DRY_RUN is how the project's own gate drives this script without starting
rem an emulator; it changes nothing else, and every check above has already run.
if not defined PLAY_DRY_RUN goto launch
echo WOULD RUN: "%BIN%" vsavjw -rompath "%ZIPDIR%" -skip_gameinfo
exit /b 0
:launch
echo Starting. Tab opens MAME's own menu - controls, video. Esc exits.
echo.
"%BIN%" vsavjw -rompath "%ZIPDIR%" -skip_gameinfo %*'''

WHY_BAT = {
    "fbneo": ("double-clicking fbneo.exe exits at once - it needs the game name, and it only "
              "looks for games in roms\\ beside the folder it was started from."),
    "mame":  ("double-clicking cps2.exe finds no ROMs - the set is vsavjw, which only the "
              "patched build knows, and MAME needs -rompath pointing at your built set."),
}

# Where each launcher looks for the set; the NEWEST present wins (#248), and on a tie the
# first in this list (FBNeo's own roms\ first, so a set already in place runs on a tie).
CANDIDATES_BAT = {
    "fbneo": r'"%BINDIR%\roms\vsavjw.zip" "%HERE%\roms\vsavjw.zip" "%HERE%\vsavjw.zip" "%HERE%\rompath\vsavjw.zip"',
    "mame":  r'"%HERE%\roms\vsavjw.zip" "%HERE%\vsavjw.zip" "%HERE%\rompath\vsavjw.zip"',
}


def launcher_bat_bytes(platform, name):
    """PLAY.bat for <platform>, as the bytes shipped: CRLF line endings, ASCII only."""
    t = LAUNCHER_BAT
    t = t.replace("@NAME@", name)
    t = t.replace("@PLATFORM_UPPER@", platform.upper())
    t = t.replace("@PLATFORM@", platform)
    t = t.replace("@EXE@", "fbneo" if platform == "fbneo" else "cps2")
    t = t.replace("@WHY@", WHY_BAT[platform])
    t = t.replace("@PROFILE_CHECK@", FBNEO_PROFILE_BAT if platform == "fbneo" else MAME_PROFILE_BAT)
    t = t.replace("@CANDIDATES@", CANDIDATES_BAT[platform])
    t = t.replace("@LAUNCH@", FBNEO_LAUNCH_BAT if platform == "fbneo" else MAME_LAUNCH_BAT)
    if "@" in t.replace("@echo off", ""):
        sys.exit("PLAY.bat: an unreplaced @PLACEHOLDER@ remains")
    t.encode("ascii")           # cmd reads a .bat in the OEM code page: ASCII is the only safe set
    return t.replace("\r\n", "\n").replace("\n", "\r\n").encode("ascii")


def run_packager(rompath, romdir, name, version, dest):
    """package_release.py writes <out>/<name>/; we want it FLAT at <dest>."""
    with tempfile.TemporaryDirectory() as tmp:
        subprocess.run([sys.executable, os.path.join(HERE, "package_release.py"),
                        rompath, tmp, "--romdir", romdir, "--name", name,
                        "--version", version], check=True, stdout=subprocess.DEVNULL)
        src = os.path.join(tmp, name)
        if os.path.exists(dest):
            shutil.rmtree(dest)
        shutil.copytree(src, dest)


def repo_url():
    """The origin remote's HTTPS form, or "" when no remote exists."""
    out = subprocess.run(["git", "-C", REPO, "remote", "get-url", "origin"],
                         capture_output=True, text=True).stdout.strip()
    out = out[:-4] if out.endswith(".git") else out
    if out.startswith("git@github.com:"):
        out = "https://github.com/" + out[len("git@github.com:"):]
    return out


def release_url(name):
    """The GitHub release page the prebuilt assets attach to (ruled 14z-149): the origin
    remote's HTTPS form + /releases/tag/freeze/<name>; a placeholder when no remote exists."""
    out = repo_url()
    return f"{out}/releases/tag/freeze/{name}" if out else "the project's GitHub release page"


def issues_url():
    """Where a player reports a problem (#284): the origin's issues page."""
    out = repo_url()
    return f"{out}/issues" if out else "the project's GitHub issues page"


def pin_of(submodule):
    out = subprocess.run(["git", "-C", REPO, "submodule", "status", submodule],
                         capture_output=True, text=True).stdout.strip()
    return out.lstrip(" +-").split()[0] if out else "?"


def binaries_side(platform, edir):
    """THE PREBUILT BINARIES (maintainer-ruled 2026-09-11: recipe AND prebuilt,
    each user free to choose). A BUILD RESOURCE with its own cadence, like the
    bitstream: release/emulators/<platform>/<os-arch>/{<files>, BINARY.txt},
    the record naming every file with its sha256, the upstream pin and the
    driver-patch sha1 it was built from. Every <os-arch> dir present is
    hash-verified and copied to emulator/bin/<os-arch>/; NONE present is
    allowed (the recipe is always there) and said so. Returns the list copied."""
    import hashlib, re
    root = os.path.join(REPO, "release", "emulators", platform)
    copied = []
    if not os.path.isdir(root):
        return copied
    for osarch in sorted(os.listdir(root)):
        bdir = os.path.join(root, osarch)
        rec = os.path.join(bdir, "BINARY.txt")
        if not os.path.isdir(bdir) or not os.path.exists(rec):
            continue
        text = open(rec, encoding="utf-8").read()
        rows = re.findall(r"^sha256\s+([0-9a-f]{64})\s+(\S+)\s*$", text, re.M)
        if not rows:
            sys.exit(f"{rec} names no 'sha256 <hex> <file>' row")
        out = os.path.join(edir, "bin", osarch)
        os.makedirs(out, exist_ok=True)
        for want, fname in rows:
            fp = os.path.join(bdir, fname)
            got = hashlib.sha256(open(fp, "rb").read()).hexdigest()
            if got != want:
                sys.exit(f"REFUSING: {fp} sha256 {got[:12]}… != the record's {want[:12]}…")
            shutil.copy(fp, os.path.join(out, fname))
        shutil.copy(rec, os.path.join(out, "BINARY.txt"))
        copied.append(osarch)
        print(f"  {platform} prebuilt {osarch}: {len(rows)} file(s), sha256 verified")
    return copied


def select_platform_text(dest, platform):
    """THE COMMON README NAMES ONLY WHAT THIS PACKAGE SHIPS (14z-189, rule-checker run
    2026-10-03-602): tools/package_release.py writes the launcher passages between
    `<!--EMU-->` / `<!--/EMU-->` and the MiSTer alternative between `<!--MISTER-->` /
    `<!--/MISTER-->`; an emulator package keeps the first, the MiSTer package the second.
    Before this, the MiSTer README told its reader to double-click PLAY.command and
    PLAY.bat, neither of which the MiSTer package carries. A marker left over, or an
    unbalanced pair, stops the packaging rather than shipping it.
    `<!--MAME-->` / `<!--/MAME-->` (14z-192, GitHub #227) nest inside an EMU block and hold
    what is true of the MAME build alone (its four validation lines); only the mame package
    keeps them. They are dropped FIRST, so the EMU pass sees no nested pair.
    `<!--NOTMAME-->` / `<!--/NOTMAME-->` (#284) hold what every package but MAME's says (the
    report section without the recording procedure); only the mame package drops them."""
    import re
    path = os.path.join(dest, "README.md")
    body = open(path, encoding="utf-8").read()
    keep, drop = ("MISTER", "EMU") if platform == "mister" else ("EMU", "MISTER")
    for tag in (keep, drop, "MAME", "NOTMAME"):
        if body.count(f"<!--{tag}-->") != body.count(f"<!--/{tag}-->"):
            sys.exit(f"{path}: unbalanced <!--{tag}--> markers")
    # A marker stands on a line of its own and may be INDENTED (#284: the template's markers sit
    # inside the Markdown lists they cut), so the whole line goes, indentation included.
    mark = lambda t: rf"^[ \t]*<!--{t}-->[ \t]*\n"
    block = lambda t: rf"^[ \t]*<!--{t}-->[ \t]*\n.*?^[ \t]*<!--/{t}-->[ \t]*\n"
    if platform == "mame":
        body = re.sub(mark("/?MAME"), "", body, flags=re.M)
        body = re.sub(block("NOTMAME"), "", body, flags=re.S | re.M)
    else:
        body = re.sub(block("MAME"), "", body, flags=re.S | re.M)
        body = re.sub(mark("/?NOTMAME"), "", body, flags=re.M)
    body = re.sub(block(drop), "", body, flags=re.S | re.M)
    body = re.sub(mark("/?" + keep), "", body, flags=re.M)
    left = re.findall(r"<!--/?(?:EMU|MISTER|MAME|NOTMAME)-->", body)
    if left:
        sys.exit(f"{path}: platform markers left after selection: {left}")
    open(path, "w", encoding="utf-8", newline="\n").write(body)


def emulator_side(platform, dest, name):
    e = EMU[platform]
    edir = os.path.join(dest, "emulator")
    os.makedirs(edir, exist_ok=True)
    shutil.copy(os.path.join(REPO, e["patch"]), os.path.join(edir, os.path.basename(e["patch"])))
    pin = pin_of(e["submodule"])
    bins = binaries_side(platform, edir)
    # THE TWO ROUTES NEVER TRAVEL TOGETHER (maintainer-ruled 2026-09-12): the README's "Play on …"
    # section is written for a reader holding EITHER asset. Since #284 (Q4, 14z-206) it is the
    # template's own EMU block, its by-hand sentence the per-platform token @HAND@ (PLATFORM_TEXT).
    # the launcher, executable, beside the README it points at
    lp = os.path.join(dest, "PLAY.command")
    with open(lp, "w", encoding="utf-8", newline="\n") as f:
        f.write(launcher_text(platform, name))
    os.chmod(lp, 0o755)
    # and its Windows twin (#145): plain cmd, CRLF, beside it
    with open(os.path.join(dest, "PLAY.bat"), "wb") as f:
        f.write(launcher_bat_bytes(platform, name))
    text = f"""# {name} — {platform.upper()} side

This directory is self-sufficient for {platform.upper()}: the romset patch
set (`patches/`, `manifest.json`, `apply_release.py`, `apply_release.html`,
`README.md`) and the
emulator driver patch in `emulator/`. Nothing for any other platform is here.

## The emulator
Upstream: {e['upstream']}
Pinned commit: `{pin}` (the exact tree the patch is known to apply to and
the project's gates were run against).

{e['deps']}
{e['recipe'].format(upstream=e['upstream'], pin=pin)}
{e['note']}
## The romset
Apply the patch set per `README.md` — double-click `apply_release.html`, or run
`apply_release.py` — then point the patched emulator's
rom path at the output directory. The set is `vsavjw` and it is STANDALONE:
the applier copies in every member the loader asks for, the parent's and
MAME's QSound BIOS member included, so the output directory needs nothing
beside it.
"""
    # THIS FILE SHIPS IN THE `-recipe` ASSET ONLY (ruled 2026-09-12), so it
    # addresses a reader who is building, and points at the other route rather
    # than describing a directory their download does not have.
    text += f"""
## Prebuilt binaries — the other route

**You are reading the build route.** If you would rather not build, the
release on tag `freeze/{name}` ({release_url(name)}) also publishes
`{name}-{platform}-<os-arch>.zip`: the SAME package as this one, with a
prebuilt patched emulator in place of this patch and recipe. It is complete
too — romset patches and applier included — so it replaces this download
rather than joining it.

{('Built so far for: ' + ', '.join(bins) + '. Each carries a `BINARY.txt` naming every file with its sha256, the upstream pin and the sha1 of the driver patch beside this file — the binary is exactly the recipe above, run on one host, and the record says which. Only the latest freeze keeps its assets; the binaries are never files in the repository (ruled 2026-09-11).') if bins else 'None built for any OS in this release yet (ruled 2026-09-11: a release ships the recipe AND prebuilt binaries per OS, each user free to choose; they are added as each host builds them). The recipe above is complete.'}

## If it does not work
- "Unknown system: vsavjw" — this binary does not carry the driver patch.
- The set, RENAMED to `vsavj.zip` to force it into a stock emulator, sits on
  the QSound / CAPCOM legal screen forever (measured 2026-09-11: the stock 4 MB
  driver never loads the program extension, the sound driver or the QSound
  extension; no crash, no gameplay). Renaming is never the fix.
"""
    if platform == "mame":      # 14z-192, GitHub #227: the recipe builds the same filtered MAME
        text += """- Four "Driver is a clone of nonexistent driver megaman" errors at every start
  (`mmancp2u`, `mmancp2ur1`, `mmancp2ur2`, `rmancp2j`) are expected and harmless:
  the build is filtered to the CPS-2 drivers and their parent lives outside them.
- The red "One or more ROMs/disk images for this system are incorrect" box at every
  start is expected and harmless: press any key. The driver carries the stock CRCs
  for the members the port rewrites and sentinel CRCs for the new ones (the
  `-verifyroms` note above), and MAME 0.288 never lets `-skip_warnings` skip a
  ROM-load warning (`src/frontend/mame/ui/ui.cpp`, `display_startup_screens`).
  The applier has already verified every member's sha1 (#234).
"""
    open(os.path.join(dest, "EMULATOR.md"), "w", encoding="utf-8", newline="\n").write(text)


def resolve_bitstream(arg):
    """release/bitstreams/CURRENT names the seed dir unless --bitstream overrides."""
    if arg:
        return arg
    root = os.path.join(REPO, "release", "bitstreams")
    cur = os.path.join(root, "CURRENT")
    if not os.path.exists(cur):
        sys.exit(f"{cur} missing — no canonical bitstream to package (see docs/project/release_format.md)")
    return os.path.join(root, open(cur, encoding="utf-8").read().strip())


def bitstream_side(dest, bdir):
    rec = os.path.join(bdir, "BITSTREAM.txt")
    rbfs = [f for f in os.listdir(bdir) if f.endswith(".rbf")]
    if not os.path.exists(rec) or len(rbfs) != 1:
        sys.exit(f"{bdir} must hold exactly one .rbf and a BITSTREAM.txt (found {rbfs})")
    import hashlib, re
    want = re.search(r"sha256\s+([0-9a-f]{64})", open(rec, encoding="utf-8").read())
    if not want:
        sys.exit(f"{rec} carries no 'sha256 <64 hex>' line")
    rbf = os.path.join(bdir, rbfs[0])
    got = hashlib.sha256(open(rbf, "rb").read()).hexdigest()
    if got != want.group(1):
        sys.exit(f"REFUSING: {rbf} sha256 {got[:12]}… != the record's {want.group(1)[:12]}… — "
                 "a timing-failing seed emits an indistinguishable .rbf; fix the resource, not the release")
    shutil.copy(rbf, os.path.join(dest, rbfs[0]))
    shutil.copy(rec, os.path.join(dest, "BITSTREAM.txt"))
    print(f"  bitstream {rbfs[0]} from {bdir}: sha256 verified {got[:12]}…")


def mister_side(dest, src, name, bdir):
    if not src:
        sys.exit("mister: --mister-src DIR (holding the .mra files) is required for the mister platform")
    # WHAT SHIPS IS DECLARED BY SETNAME, NOT BY DIRECTORY LAYOUT (14z-126b).
    # jtframe files clones under _alternatives/<parent> and only setnames in
    # the core's parse.main_setnames land at the top level, so a listdir() of
    # the output dir silently depended on that layout: when cps2w made the
    # WIDE set main, the STOCK CONTROL leg moved into _alternatives and a
    # non-recursive scan would have dropped it from every release -- against
    # the ruling that it ships in each one (maintainer, 2026-08-29). Selecting
    # on the MRA's own <setname> is layout-independent and fails LOUDLY if one
    # goes missing, which a glob never would.
    SHIP = {"vsavjw": "the WIDE roster set",
            "vsavj":  "the [STOCK CONTROL] reference leg"}
    found, copied = {}, []
    for root, _dirs, files in os.walk(src):
        for f in sorted(files):
            if not f.endswith(".mra"):
                continue
            path = os.path.join(root, f)
            with open(path, encoding="utf-8", errors="replace") as fh:
                m = re.search(r"<setname>([^<]+)</setname>", fh.read())
            if not m or m.group(1) not in SHIP:
                continue
            if m.group(1) in found:
                sys.exit(f"mister: two MRAs claim setname {m.group(1)}: "
                         f"{found[m.group(1)]} and {path}")
            found[m.group(1)] = path
            shutil.copy(path, os.path.join(dest, f))
            copied.append(f)
    missing = [f"{k} ({v})" for k, v in SHIP.items() if k not in found]
    if missing:
        sys.exit(f"--mister-src {src} is missing: " + ", ".join(missing))
    bitstream_side(dest, bdir)
    text = f"""# {name} — MiSTer side

This directory is self-sufficient for MiSTer: the romset patch set
(`patches/`, `manifest.json`, `apply_release.py`, `apply_release.html`,
`README.md`), the `.mra`
files, the bitstream `jtcps2w.rbf` and its record `BITSTREAM.txt` (seed, slack,
sha256 — verified against the file when this directory was packaged).

## On the SD card
    _Arcade/<the .mra files here>
    _Arcade/cores/jtcps2w.rbf        <- in this directory (verify the sha256 in BITSTREAM.txt after copying)
    games/mame/vsavjw.zip            <- built WITHOUT the QSound BIOS member (see below)

**On MiSTer, build the set with `--no-qsound-bios`.** Your card already carries
`games/mame/qsound.zip` the moment you play any CPS-2 game, and the WIDE MRA's
part chain is `vsavjw.zip|vsav.zip|qsound.zip`, so it picks the BIOS member up
from there: measured 2026-09-20, **all 31 CRC-matched parts resolve — 30 out of
`vsavjw.zip` and `dl-1425.bin` out of `qsound.zip`** — and you do not need
`qsound_hle.zip` among your dumps at all. Keeping the member (the applier's
default) also works and costs nothing but the 24 KB; it is what emulator players
want, because MAME refuses a set without it.

The WIDE MRA runs the full roster on `jtcps2w.rbf`. Apart from the BIOS member it
needs nothing beside `vsavjw.zip`: the applier copies the parent's members in from
your own dumps. The other zips are only for the OTHER things on the card:

    games/mame/vsavj.zip             <- your PRISTINE dump: the STOCK CONTROL MRA only
    games/mame/vsav.zip              <- your PRISTINE dump: the STOCK CONTROL MRA, and
                                        stock Vampire Savior on Jotego's own jtcps2.rbf
    games/mame/qsound.zip            <- dl-1425.bin: the WIDE MRA (with --no-qsound-bios)
                                        and the STOCK CONTROL MRA

The `[STOCK CONTROL]`
MRA runs stock `vsavj` on the SAME bitstream with the profile bit at its
`0xFF` fill: it is the superset invariant on silicon and only needs running
when the BITSTREAM changes (new seed, slice or pin), not per release. Stock
Vampire Savior on Jotego's own `jtcps2.rbf` keeps working from the same
`vsav.zip` — the two coexist on one card (field-verified 2026-08-28).

VERIFY THE BITSTREAM'S sha256 BEFORE FLASHING: a timing-failing fitter seed
emits an .rbf indistinguishable from a passing one.
"""
    open(os.path.join(dest, "MISTER.md"), "w", encoding="utf-8", newline="\n").write(text)
    # its "Play on MiSTer" section is the template's own MISTER block since #284 (Q4, 14z-206)


# THE PER-PLATFORM WORDS (#284): the template's `@TOKEN@`s that differ by package. The report section
# and the "Play on …" sections are the template's own blocks since #284 Q4 (14z-206: the maintainer edits
# one file): only the MAME packages record (the recording procedure moved there from the root README,
# ruled 2026-10-15), and tests/test_readme_recording.sh runs the MAME command as written. @HAND@ is the
# by-hand sentence of "Play on …"; @PKGL@ the package's name part in the not-MAME report section.
HAND = {
    "fbneo": ("put `vsavjw.zip` in a folder called `roms` next to the emulator program and start the emulator "
              "from that folder: this FBNeo has no option for where games are, it only looks in `roms/` beside "
              "wherever it was started"),
    "mame": ("start the emulator with `-rompath` naming the folder that holds `vsavjw.zip`, for example "
             "`-rompath rompath` from this folder"),
}

PLATFORM_TEXT = {
    "mame": {"@PKG@": "MAME", "@EXE@": "cps2", "@ENGINE@": "emulator", "@HAND@": HAND["mame"], "@PKGL@": "mame-",
             "@SETTINGS_COUNT@": "for this MAME, 2 files.",
             "@WIN_SYMPTOM@": "finds no game files (\"NOT FOUND\")",
             "@WIN_NEEDS@": "where the game file is (`cps2.exe vsavjw -rompath rompath`)",
             "@PKGFILES@": "- `emulator/bin/<os-arch>/` — the prepared MAME, and `BINARY.txt` with a fingerprint\n  for every file. (The recipe package has `EMULATOR.md` and the patch instead.)",
             "@WHY_TAIL@": "A normal MAME knows only the original board: it refuses the file, or sits on the\nstartup screen forever. The MAME here is an ordinary MAME with one small published\nchange that teaches it the larger board."},
    "fbneo": {"@PKG@": "FBNeo", "@EXE@": "fbneo", "@ENGINE@": "emulator",
              "@HAND@": HAND["fbneo"], "@PKGL@": "fbneo-",
              "@SETTINGS_COUNT@": "for this FBNeo, 24 files (the program and the 23 libraries it carries),\n    which is why the Terminal way is the one to use.",
              "@WIN_SYMPTOM@": "only flashes a window shut",
              "@WIN_NEEDS@": "the game's name and to start where `roms\\` holds the game file (`fbneo.exe vsavjw`)",
              "@PKGFILES@": "- `emulator/bin/<os-arch>/` — the prepared FBNeo, and `BINARY.txt` with a fingerprint\n  for every file. (The recipe package has `EMULATOR.md` and the patch instead.)",
              "@WHY_TAIL@": "A normal FBNeo knows only the original board: it refuses the file, or sits on the\nstartup screen forever. The FBNeo here is an ordinary FBNeo with one small published\nchange that teaches it the larger board."},
    "mister": {"@PKG@": "MiSTer", "@EXE@": "", "@ENGINE@": "CPS-2 core",
               "@HAND@": "", "@PKGL@": "mister",
               "@SETTINGS_COUNT@": "", "@WIN_SYMPTOM@": "", "@WIN_NEEDS@": "",
               "@PKGFILES@": "- `jtcps2w.rbf`, `BITSTREAM.txt`, the two `.mra` files and `MISTER.md` — the core, its\n  record, the menu entries, and where each file goes on the SD card.",
               "@WHY_TAIL@": "Jotego's own `jtcps2.rbf` knows only the original board. `jtcps2w.rbf` is that core\nextended to the larger board, kept as a separate core so the ordinary one is\nuntouched."},
}


def fill_platform_text(dest, platform):
    """The last README step: the per-platform words, and the values the template's per-platform
    sections name (`@NAME@`, `@MARK@`, from this package's own manifest). A token
    left over stops the packaging rather than shipping it, as a marker does."""
    path = os.path.join(dest, "README.md")
    m = json.load(open(os.path.join(dest, "manifest.json"), encoding="utf-8"))
    body = open(path, encoding="utf-8").read()
    vals = dict(PLATFORM_TEXT[platform])
    vals["@SAVE_WHERE@"] = ("into a folder called `rompath` in this folder (make it if it is not there)"
                            if platform in EMU else
                            'anywhere you like; it goes on the SD card in step 2 ("Play on MiSTer")')
    vals["@MISTER_FLAG@"] = "" if platform in EMU else " --no-qsound-bios"
    vals.update({"@ISSUES@": issues_url(), "@NAME@": m["name"], "@MARK@": m["version_string"]})
    for k, v in vals.items():
        body = body.replace(k, v)
    left = sorted(set(re.findall(r"@[A-Z_]+@", body)))
    if left:
        sys.exit(f"{path}: template tokens left after filling: {left}")
    open(path, "w", encoding="utf-8", newline="\n").write(re.sub(r"\n{3,}", "\n\n", body))


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("rompath")
    ap.add_argument("release_root", help="e.g. release — the tree is written at release/<name>/")
    ap.add_argument("--romdir", required=True)
    ap.add_argument("--name", required=True)
    ap.add_argument("--version", required=True, help="the in-game mark, e.g. M8")
    ap.add_argument("--mister-src", default="", help="dir holding the .mra files (the field bundle's _Arcade/, or mister_mra.sh --no-rom output)")
    ap.add_argument("--bitstream", default="", help="bitstream dir (an .rbf + BITSTREAM.txt); default: release/bitstreams/<CURRENT>")
    ap.add_argument("--platforms", default=",".join(PLATFORMS))
    a = ap.parse_args()
    plats = [p for p in a.platforms.split(",") if p]
    bad = [p for p in plats if p not in PLATFORMS]
    if bad:
        sys.exit(f"unknown platform(s): {bad}")
    # the name is joined into a path whose platform dirs are deleted and rewritten: one safe
    # component inside release_root, or nothing is touched (14z-197, GitHub #246)
    sys.path.insert(0, HERE)
    from package_release import safe_release_name
    root = safe_release_name(a.release_root, a.name)
    os.makedirs(root, exist_ok=True)
    for p in plats:
        dest = os.path.join(root, p)
        run_packager(a.rompath, a.romdir, a.name, a.version, dest)
        select_platform_text(dest, p)
        if p in EMU:
            emulator_side(p, dest, a.name)
        else:
            mister_side(dest, a.mister_src, a.name, resolve_bitstream(a.bitstream))
        # the applier page again, now that the platform is known: its "when you have
        # the file" line is the only part that differs per platform, and a MiSTer
        # player is told to choose the smaller set (docs/project/applier_app_scope.md)
        subprocess.run([sys.executable, os.path.join(HERE, "gen_applier_page.py"),
                        dest, "--platform", p, "-o", os.path.join(dest, "apply_release.html")],
                       check=True, stdout=subprocess.DEVNULL)
        fill_platform_text(dest, p)
        n = sum(len(f) for _, _, f in os.walk(dest))
        print(f"  {p}: {n} files -> {dest}")
    print(f"packaged {a.name} for {', '.join(plats)} -> {root}")


if __name__ == "__main__":
    main()
