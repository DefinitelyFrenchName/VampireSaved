#!/bin/sh
# test_release_launcher.sh — THE PLAYER'S LAUNCHER, DRIVEN (2026-09-20).
#
# WHAT: the player's PLAY.command reaches the right emulator invocation (creating FBNeo's
#   roms/ for it) and REFUSES every wrong situation with a message that names the cause — no
#   romset, no binary for this machine, a symlinked roms/, an emulator without the profile.
# HOW: both platforms' launchers driven in a staged copy of the release under PLAY_DRY_RUN=1
#   (stops before the emulator); the control stages an emulator binary without the profile
#   as the success path.
# EXPECTS: the success path's invocation, every refusal non-zero and named; the
#   unpatched-emulator control refused. The real launch is test_release_binaries' half.
#
# `PLAY.command` is the one shipped file whose whole job is to be run by somebody
# who knows none of this project's facts, so it is the one file whose FAILURE
# messages matter as much as its success path. This gate drives both platforms'
# launchers in a staged copy of the release: the success path (does it reach the
# right emulator invocation, and does it create FBNeo's `roms/` for it?) and every
# refusal (no romset, no binary for this machine, a symlinked `roms/`, an emulator
# without the profile) — each of which must exit NON-ZERO and name its cause,
# because a launcher that fails silently is worse than none.
#
# WHY IT IS NOT JUST "run it once": the messages are the deliverable. A player who
# gets `vsavjw.zip not found` with the applier command can finish; one who gets a
# bare shell error cannot. `PLAY_DRY_RUN=1` stops the script after every check but
# before the emulator, so all of that is testable without a window opening.
#
# The REAL launch is covered separately: tests/test_release_binaries.sh boots the
# binaries themselves, so this gate deliberately stops at the invocation.
#
# MUST-FIRE: perturbed-copy: launcher-accepts-unpatched — a copy whose emulator binary does NOT carry the profile must be REFUSED by the launcher; without that check a player runs a stock emulator, gets "Unknown system: vsavjw" and has no idea why (mode: the gate stages that copy as the success path)
#
# Usage: tests/test_release_launcher.sh [release/merged-m20]   # ci_portable (no ROMDIR, no emulator, no ROM bytes)
set -eu
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
. "$REPO/tests/lib/controls.sh"; vs_ctl_mode "$0"
REL="${1:-release/merged-m20}"
[ -d "$REL" ] || { echo "SKIP: no release tree at $REL"; exit 0; }

W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT
fail=0
ok()   { echo "  ok: $*"; }
bad()  { echo "FAIL: $*"; fail=1; }

# A romset stand-in: the launcher only ever checks that vsavjw.zip EXISTS and hands
# its directory to the emulator, so a named placeholder exercises every path here
# without a 28 MB copy or any ROM content in the gate.
mkzip() { printf 'not-a-rom' > "$1"; }

stage() {  # stage <platform> <dir>
    rm -rf "$2"; mkdir -p "$2"
    cp "$REL/$1/PLAY.command" "$2/" || return 1
    chmod +x "$2/PLAY.command"
    mkdir -p "$2/emulator/bin/$OSARCH"
    # a stub that answers the profile probe the way the real binary does
    if [ "$1" = fbneo ]; then
        printf '#!/bin/sh\necho "CPS-2 WIDE v1 profile active"\nsleep 0.1\n' > "$2/emulator/bin/$OSARCH/fbneo"
        # the FBNeo probe is `strings` over the BINARY, so the marker must be IN the file
        printf '#!/bin/sh\n# CPS-2 WIDE v1\necho started\n' > "$2/emulator/bin/$OSARCH/fbneo"
        chmod +x "$2/emulator/bin/$OSARCH/fbneo"
    else
        printf '#!/bin/sh\ncase "$*" in *-listfull*) echo vsavjw ;; *) echo started ;; esac\n' > "$2/emulator/bin/$OSARCH/cps2"
        chmod +x "$2/emulator/bin/$OSARCH/cps2"
    fi
    mkzip "$2/vsavjw.zip"
}

case "$(uname -s)" in
Darwin) OS=macos ;;
Linux)  OS=linux ;;
MINGW*|MSYS*|CYGWIN*) OS=windows ;;
*) echo "SKIP: this gate does not know $(uname -s)"; exit 0 ;;
esac
ARCH="$(uname -m)"
case "$ARCH" in arm64|aarch64) ARCH=arm64 ;; x86_64|amd64) ARCH=x86_64 ;; esac
OSARCH="$OS-$ARCH"

run() {  # run <dir> -> captures output in $OUT, status in $RC
    OUT="$W/out.txt"; RC=0
    ( cd "$1" && PLAY_DRY_RUN=1 PLAY_CLEAR_QUARANTINE=1 sh ./PLAY.command </dev/null ) > "$OUT" 2>&1 || RC=$?
}

for plat in fbneo mame; do
    [ -f "$REL/$plat/PLAY.command" ] || { bad "$REL/$plat/PLAY.command is missing"; continue; }
    echo "== $plat =="
    D="$W/$plat"

    # ---- the success path
    stage "$plat" "$D" || { bad "could not stage $plat"; continue; }
    if [ -n "${VS_CTL:-}" ] && vs_ctl_is launcher-accepts-unpatched; then
        # THE CONTROL/MODE: the binary no longer carries the profile. The launcher must
        # refuse; if it runs anyway, a player gets an unexplained "Unknown system".
        if [ "$plat" = fbneo ]; then
            printf '#!/bin/sh\necho stock\n' > "$D/emulator/bin/$OSARCH/fbneo"
            chmod +x "$D/emulator/bin/$OSARCH/fbneo"
        else
            printf '#!/bin/sh\nexit 1\n' > "$D/emulator/bin/$OSARCH/cps2"
            chmod +x "$D/emulator/bin/$OSARCH/cps2"
        fi
    fi
    run "$D"
    if [ "$RC" = 0 ] && grep -q '^WOULD RUN: ' "$OUT"; then
        grep -q 'vsavjw' "$OUT" || bad "$plat: the invocation does not name the set"
        if [ "$plat" = fbneo ]; then
            [ -f "$D/roms/vsavjw.zip" ] || bad "fbneo: the launcher did not put the set in ./roms (FBNeo reads roms/ relative to cwd and has no -rompath)"
            grep -q "cwd $D" "$OUT" || bad "fbneo: the launcher does not run from its own directory"
        else
            grep -q -- '-rompath' "$OUT" || bad "mame: the invocation carries no -rompath"
        fi
        [ "$fail" = 0 ] && ok "$plat: reaches the emulator with the set, $( [ "$plat" = fbneo ] && echo 'roms/ populated and cwd set' || echo '-rompath passed' )"
    else
        bad "$plat: the success path did not reach the emulator (rc=$RC): $(head -3 "$OUT" | tr '\n' ' ')"
    fi

    # ---- every refusal must exit non-zero AND name its cause
    refuse() {  # refuse <label> <needle>
        run "$D"
        if [ "$RC" = 0 ]; then bad "$plat/$1: the launcher ACCEPTED it (rc=0)"; return; fi
        grep -q "$2" "$OUT" || { bad "$plat/$1: exited $RC but never said why (wanted '$2'): $(grep -m1 '^!!' "$OUT" || echo 'no !! line')"; return; }
        ok "$plat/$1 refused, rc=$RC: $(grep -m1 '^!!' "$OUT" | cut -c4-64)"
    }
    stage "$plat" "$D"; rm -f "$D/vsavjw.zip"; rm -rf "$D/roms" "$D/rompath"
    refuse no-romset 'vsavjw.zip not found'
    stage "$plat" "$D"; rm -rf "$D/emulator/bin/$OSARCH"
    refuse no-binary 'no prebuilt'
    stage "$plat" "$D"
    if [ "$plat" = fbneo ]; then
        rm -rf "$D/roms"; ln -s /tmp "$D/roms"
        refuse symlinked-roms 'symlink'
        rm -f "$D/roms"
    fi
    stage "$plat" "$D"
    if [ "$plat" = fbneo ]; then printf '#!/bin/sh\necho stock\n' > "$D/emulator/bin/$OSARCH/fbneo"; chmod +x "$D/emulator/bin/$OSARCH/fbneo"
    else printf '#!/bin/sh\nexit 1\n' > "$D/emulator/bin/$OSARCH/cps2"; chmod +x "$D/emulator/bin/$OSARCH/cps2"; fi
    refuse unpatched-emulator 'does not'
done

# ---- the QUARANTINE branch (2026-09-20, #144). A macOS download is quarantined and
# `unzip` PROPAGATES the flag to every extracted file (measured, not assumed). Without
# consent the launcher must REFUSE and hand over the exact command; with
# PLAY_CLEAR_QUARANTINE=1 it must clear the flag and carry on. This is the only branch
# that touches the player's security state, so it is the one that must not act silently.
if [ "$(uname -s)" = Darwin ] && command -v xattr >/dev/null 2>&1; then
    QD="$W/quar"; stage fbneo "$QD"
    QV="0081;$(printf '%x' "$(date +%s)");Safari;$( (uuidgen 2>/dev/null) || echo 0-0-0-0-0)"
    find "$QD" -type f -exec xattr -w com.apple.quarantine "$QV" {} \; 2>/dev/null || true
    # (a) no consent given -> refuse, naming the command
    OUT="$W/out.txt"; RC=0
    ( cd "$QD" && PLAY_DRY_RUN=1 sh ./PLAY.command </dev/null ) > "$OUT" 2>&1 || RC=$?
    if [ "$RC" = 0 ]; then
        bad "quarantine: the launcher proceeded without consent"
    elif grep -q 'com.apple.quarantine' "$OUT"; then
        ok "quarantine: refused without consent and named the xattr command (rc=$RC)"
    else
        bad "quarantine: exited $RC but never named the fix: $(grep -m1 '^!!' "$OUT" || echo 'no !! line')"
    fi
    # (b) consent given -> clears the flag and reaches the emulator
    OUT="$W/out2.txt"; RC=0
    ( cd "$QD" && PLAY_DRY_RUN=1 PLAY_CLEAR_QUARANTINE=1 sh ./PLAY.command </dev/null ) > "$OUT" 2>&1 || RC=$?
    if [ "$RC" = 0 ] && grep -q '^WOULD RUN: ' "$OUT"; then
        if xattr -p com.apple.quarantine "$QD/emulator/bin/$OSARCH/fbneo" >/dev/null 2>&1; then
            bad "quarantine: the launcher said it cleared the flag but it is still set"
        else
            ok "quarantine: with consent, cleared the flag and reached the emulator"
        fi
    else
        bad "quarantine: with consent it did not reach the emulator (rc=$RC): $(grep -m1 '^!!' "$OUT" || head -2 "$OUT" | tr '\n' ' ')"
    fi
else
    echo "  note: not macOS (or no xattr) — the quarantine branch is not exercised here"
fi

# ---- the must-fire control, in-gate: an unpatched binary on the success path
CD="$W/ctl"; stage fbneo "$CD"
printf '#!/bin/sh\necho stock\n' > "$CD/emulator/bin/$OSARCH/fbneo"; chmod +x "$CD/emulator/bin/$OSARCH/fbneo"
run "$CD"
if [ "$RC" = 0 ]; then
    vs_ctl_dead launcher-accepts-unpatched "the launcher ran an emulator with no profile marker" || true; fail=1
else
    vs_ctl_fired launcher-accepts-unpatched "an emulator without the profile is refused (rc=$RC): $(grep -m1 '^!!' "$CD/../out.txt" 2>/dev/null | cut -c4-56)"
fi

[ "$fail" = 0 ] && echo "PASS: test_release_launcher (both launchers reach the emulator; every refusal exits non-zero and names its cause)" || echo "FAIL: test_release_launcher"
exit "$fail"
