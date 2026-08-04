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
#   tools/run_wide.sh [build_dir] [fbneo|mame] [extra args...]
# Defaults: build/m5w, fbneo.
set -eu
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
BUILD="${1:-build/m5w}"; [ $# -gt 0 ] && shift || true
EMU="${1:-fbneo}";       [ $# -gt 0 ] && shift || true
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
    echo "FBNeo: $BIN"
    echo "set vsavjw, rompath $RP"
    exec "$BIN" vsavjw -rompath "$RP;$ROMDIR" "$@"
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
