#!/bin/sh
# run_wide.sh — launch a CPS-2 WIDE build on a PATCHED emulator, playably.
#
# The WIDE track needs three things to line up: the vsavjw DRIVER (which
# only exists in a patched binary), the vsavjw SET NAME, and a rompath that
# fronts the build over $ROMDIR. Getting any one wrong fails confusingly —
# stock MAME says "unknown system", which reads like a ROM problem and is
# not one.
#
# DO NOT rename vsavjw.zip to vsavj.zip to "force" it. A filename cannot
# create a driver. Stock MAME would load it under the STOCK descriptor:
# 4MB program, vsw.41-44 ignored — while the code has the sfx helper live
# and slot 0x0F's sound pointer aimed at $400010, which on a 4MB map is the
# CPS2 output register window, not ROM. It boots, looks fine, and feeds
# hardware registers to the sound dispatcher as if they were sound records.
#
# Usage:
#   tools/run_wide.sh <build_dir> [fbneo|mame] [extra args...]
# The emulator defaults to fbneo. THE BUILD DOES NOT DEFAULT — see below.
#
# IT USED TO DEFAULT TO build/m5w (fixed 14z-97), and that is the one build in
# the tree HANDOFF says in capitals not to play: the KNOWN-BAD artifact of the
# 14z-60y sprite garble, kept as evidence. It is also pre-WIDE-v1.1 (19
# members, no vsw.z01/z02), so a bare `tools/run_wide.sh` did not even launch
# it — it failed in a way that reads as "the WIDE track is broken" rather than
# "you forgot the argument", which is exactly the confusing-failure class this
# script's own header exists to prevent.
#
# The replacement is NOT a new hardcoded default. A pinned "current build"
# re-dates itself at every freeze — the class tests/test_build_ref_rot.sh now
# reports on. Instead: no default, and the usage message LISTS the WIDE builds
# actually on disk, newest first, so it stays correct without being updated.
set -eu
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"

if [ $# -lt 1 ]; then
    echo "usage: tools/run_wide.sh <build_dir> [fbneo|mame] [extra args...]" >&2
    echo >&2
    echo "WIDE builds present here, newest first:" >&2
    for _d in $(ls -dt build/*/ 2>/dev/null); do
        _d="${_d%/}"
        [ -f "$_d/rompath/vsavjw.zip" ] || continue
        case "$_d" in
            build/m5w) echo "  $_d   — KNOWN-BAD (14z-60y sprite garble); do not play" >&2 ;;
            build/merged1) echo "  $_d  — legacy-only instrument, tenants draw BLANKS" >&2 ;;
            *) echo "  $_d" >&2 ;;
        esac
    done
    exit 2
fi
BUILD="$1"; shift
EMU="${1:-fbneo}";       [ $# -gt 0 ] && shift || true

# Two builds must never be launched by accident. Both are kept ON PURPOSE and
# both look launchable; neither is something to playtest.
case "$BUILD" in
build/m5w|./build/m5w)
    echo "REFUSING build/m5w: it is the KNOWN-BAD artifact of the 14z-60y" >&2
    echo "  sprite garble, kept as evidence (HANDOFF build registry). Its" >&2
    echo "  romset serves PRISTINE tiles for the members the build patched." >&2
    echo "  Set RUN_WIDE_ALLOW_KNOWN_BAD=1 if you are deliberately" >&2
    echo "  reproducing the garble." >&2
    [ "${RUN_WIDE_ALLOW_KNOWN_BAD:-0}" = 1 ] || exit 1 ;;
build/merged1|./build/merged1)
    echo "REFUSING build/merged1: it is the MERGED-LEGACY INSTRUMENT — gfx" >&2
    echo "  skipped, so all three tenants draw BLANK tiles by design" >&2
    echo "  (see its README-LEGACY-ONLY.txt). Play build/m3b_merged*." >&2
    [ "${RUN_WIDE_ALLOW_KNOWN_BAD:-0}" = 1 ] || exit 1 ;;
esac
ROMDIR="${ROMDIR:?set ROMDIR to the reference-set directory}"

RP="$REPO/$BUILD/rompath"
[ -d "$RP" ] || RP="$BUILD/rompath"
[ -f "$RP/vsavjw.zip" ] || {
    echo "No vsavjw.zip in $RP." >&2
    [ -f "$RP/vsavj.zip" ] && {
        echo "That build packed as vsavj (STOCK track) — it was built without" >&2
        echo "  --profile cps2-wide-v1, so there is nothing WIDE to run. Rebuild:" >&2
        echo "  KEY_SET=vsavj GEN_FLAGS=\"--allow-plausible --tripwire-open \\" >&2
        echo "    --profile cps2-wide-v1\" tools/build_donovan.sh 6 $BUILD" >&2; }
    exit 1; }

case "$EMU" in
fbneo)
    BIN="${FBNEO_BIN:-$REPO/emu/fbneo/fbneo}"
    [ -x "$BIN" ] || { echo "no FBNeo at $BIN (tools/setup_fbneo.sh)" >&2; exit 1; }
    strings -a "$BIN" 2>/dev/null | grep -q "CPS-2 WIDE v1" || {
        echo "$BIN does not carry the CPS-2 WIDE profile." >&2
        echo "Build the patched binary: tools/setup_fbneo.sh" >&2; exit 1; }
    # FBNeo's SDL frontend has NO -rompath option (verified in
    # src/burner/sdl: paths live in szAppRomPaths, defaulting to
    # "/usr/local/share/roms/" and "roms/" RELATIVE TO CWD). Passing
    # -rompath, as this script used to, is silently ignored and FBNeo then
    # looks somewhere with no vsavjw.zip — which is exactly the "I cannot
    # launch it" failure. Build the overlay directory the replay runner
    # uses and run from it: reference zips first, the build's zips win.
    PLAY="${FBNEO_PLAY_DIR:-$HOME/.cache/vampire-saved/fbneo-play}"
    # 14z-90 (GitHub issue #38). `rm -f "$PLAY/roms"/*.zip` globs THROUGH a
    # symlink: if $PLAY/roms is ever a link to $ROMDIR — which the sibling
    # runners create in their own sandboxes — this deletes the reference
    # dumps themselves. They are irreplaceable commercial dumps, and this
    # class has already cost this project once (ROMDIR lost qsound_hle.zip
    # to an emulator run directly against it). Refuse rather than glob.
    if [ -L "$PLAY/roms" ]; then
        echo "REFUSING: $PLAY/roms is a SYMLINK (-> $(readlink "$PLAY/roms"))." >&2
        echo "  Deleting *.zip through it would delete the reference dumps." >&2
        echo "  Remove the link and re-run." >&2
        exit 1
    fi
    mkdir -p "$PLAY/roms"
    # -maxdepth 1 -type l: only ever remove the LINKS this script created,
    # never a real file, and never anything a link points at.
    find "$PLAY/roms" -maxdepth 1 -type l -name '*.zip' -delete 2>/dev/null || true
    find "$PLAY/roms" -maxdepth 1 -type f -name '*.zip' -delete 2>/dev/null || true
    for z in "$ROMDIR"/*.zip;  do ln -sf "$z" "$PLAY/roms/$(basename "$z")"; done
    for z in "$RP"/*.zip;      do ln -sf "$z" "$PLAY/roms/$(basename "$z")"; done
    echo "FBNeo: $BIN"
    echo "set vsavjw, roms dir $PLAY/roms (build overlays \$ROMDIR)"
    # HOME is pinned to a STABLE dir (not a fresh temp one) so anything
    # that honours it persists between playtests. NOTE, measured: on macOS
    # FBNeo ignores it for support paths and still writes config/savestates
    # under ~/Library/Application Support/fbneo — the documented gotcha
    # that "$HOME overrides do NOT sandbox FBNeo on macOS". That is FINE
    # for playtesting (your controls persist naturally); it is only a
    # problem for determinism harnesses, which use their own sandbox.
    cd "$PLAY" && exec env HOME="$PLAY" "$BIN" vsavjw "$@"
    ;;
mame)
    BIN="${MAME_BIN:-$HOME/.cache/vampire-saved/mame/cps2}"
    [ -x "$BIN" ] || { echo "no source-built MAME at $BIN (tools/setup_mame.sh)" >&2; exit 1; }
    "$BIN" -listfull vsavjw >/dev/null 2>&1 || {
        echo "$BIN does not know the vsavjw driver." >&2
        echo "Homebrew MAME never will — build ours: tools/setup_mame.sh" >&2; exit 1; }
    echo "MAME: $BIN"
    echo "set vsavjw, rompath $RP;\$ROMDIR"
    # -verifyroms will call this set "bad" on CRC: expected for ANY patched
    # build, and it runs regardless (STATE 14z-59h).
    exec "$BIN" vsavjw -rompath "$RP;$ROMDIR" -skip_gameinfo "$@"
    ;;
*)  echo "unknown emulator '$EMU' (use fbneo or mame)" >&2; exit 1 ;;
esac
