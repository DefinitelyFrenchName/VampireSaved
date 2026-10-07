#!/bin/sh
# audit_release_linux_desktop.sh — THE LINUX RELEASE, PLAYED THE PLAYER'S WAY ON A LIVE DESKTOP:
# the window, the version mark and the SOUND, for both prebuilt emulators (#226, 14z-194).
#
# WHAT: each prebuilt linux-x86_64 asset (FBNeo and MAME), taken as a player gets it (the asset
#   cut by the real uploader, the shipped applier, `sh PLAY.command` in a live GNOME session),
#   opens a window, reaches the select screen showing the release's own version mark, and plays
#   SOUND: its own audio stream is linked to the session's sink, and that stream, recorded for
#   15 s at the select screen, carries signal in every 5 s window.
# HOW: tools/upload_release_assets.sh --dry-run cuts the assets (or ASSETS=<dir> of zips, e.g.
#   downloaded from the release); apply_release.py builds the set from ROMDIR;
#   tools/desktop_session_play.py records the null sink with pw-record (rec.wav, evidence),
#   launches PLAY.command, sends keys through XTEST, captures the window with xwd, snapshots
#   pw-dump at select and records the emulator's OWN stream node (app.wav);
#   tools/desktop_mark_check.py judges the select capture at font-pixel resolution against the
#   manifests' version font; tools/desktop_audio_check.py reads the links and the WAV levels.
#   About 6 min of desktop time (five runs of ~60-75 s). Linux with a live session ONLY: on any
#   other host it SKIPs and says so; at release it runs on PILOT (see HOW IT REACHES A RELEASE).
# EXPECTS: per emulator, mark mismatches 0 of 147 font cells, at least one active link from the
#   emulator's node to auto_null and from auto_null to pw-record, and every 5 s window of the
#   emulator's own stream above -45 dBFS RMS (the sink measured 14z-194 at -27 to -36 dBFS after
#   select); each control fails.
# FOLLOWS: tools/upload_release_assets.sh tools/desktop_session_play.py tools/desktop_audio_check.py
#   tools/desktop_mark_check.py build/manifest/version_font.json build/manifest/donovan.toml
#   build/manifest/huitzil.toml build/manifest/pyron.toml
#
# MUST-FIRE: known-bad: muted-stream — the same run with the emulator's sound switched off at launch (MAME `-sound none` through PLAY.command's own argument pass-through, FBNeo SDL_AUDIODRIVER=dummy) must FAIL the signal check on BOTH emulators: a silent game is exactly what a gate that only saw a window would pass
# MUST-FIRE: known-bad: unlinked-recorder — the recorder started with node.autoconnect=false (alive, linked to nothing) must FAIL the link check: a recording that is not of the emulator's output proves nothing about its sound, and the gate must be able to tell
# MUST-FIRE: known-bad: wrong-mark — the select capture judged against a mark one glyph off (the release's mark with its last character changed) must FAIL: a mark check that accepts a near miss cannot tell this release's binary from the last one's
#
# WHY. #226 (filed 14z-191): the Linux release had never been run as a player gets it. At 14z-193
# a hand run on PILOT's desktop showed the window, rendering and a match; at 14z-194 the sound
# was recorded from PipeWire's null sink and the maintainer listened ("sound is good"). This gate
# is that hand procedure made rerunnable, so the next release does not depend on remembering it.
#
# WHAT IT DOES NOT CLAIM: sound QUALITY (a human ear judged the 14z-194 clips); a real audio
# device and its driver (the VM has none: PipeWire's null sink `auto_null` stands in, which is the
# same sound server a real desktop routes to hardware); the physical keyboard (keys go through
# Xwayland's XTEST); a clean host (PILOT's toolchain is installed); X11 or KDE sessions; the
# recipe assets (tests/test_release_recipe_text.sh and #238 cover the recipe text).
#
# HOW IT REACHES A RELEASE. Like test_release_launcher_bat's Windows half on ERIS: the release
# commit is archived into a git clone on PILOT (the uploader's dry run needs the freeze tag), the
# linux-x86_64 binaries are copied into release/<name>/<platform>/emulator/bin/linux-x86_64/,
# and the gate is run there from a login shell; its log is the release's record. On the Mac it
# SKIPs, said.
#
# WHY THE SIGNAL IS JUDGED ON THE EMULATOR'S OWN STREAM (measured on PILOT, 14z-194): the sink
# monitor also carries gnome-shell's (Mutter's) event sounds. A MUTED run, with no emulator
# stream at all, recorded identical -31.9 dBFS bursts on the sink in alternate 5 s windows, the
# only output stream present being gnome-shell's: the same burst the hand run of 14z-194 found
# in every recording's 5-10 s window and could not explain. A sink-level check could be passed
# partly by the desktop, so the sink recording is kept only as evidence, and the link check is
# what ties the emulator's stream to the sink.
#
# WHY NOT A WRONG --target (measured on PILOT, 14z-194): pw-record pointed at a sink that does not
# exist does NOT stay unlinked — the session manager falls back to the default sink and the link
# check reads two active links, so that perturbation would leave the gate green (a dead control).
# A recorder with no capture property links to auto_null too. node.autoconnect=false is the form
# that leaves the recorder alive and linked to nothing.
#
# FBNeo keeps its config under $XDG_DATA_HOME/fbneo; a run that shares it with earlier play
# loads and saves that state, so every run here gets a FRESH XDG_DATA_HOME (a first-run player).
#
# Usage: ROMDIR=... tests/audit_release_linux_desktop.sh   [RELEASE=merged-mNN] [ASSETS=<dir>]
set -eu
REPO="$(cd "$(dirname "$0")/.." && pwd)"; cd "$REPO"
. "$REPO/tests/lib/controls.sh"; vs_ctl_mode "$0"
fail=0
ok()  { echo "  ok    $*"; }
bad() { echo "  FAIL  $*"; fail=1; }

# ---- where this gate can run at all --------------------------------------------------------
[ "$(uname -s)" = Linux ] || { echo "SKIP: not a Linux host with a live desktop session (this is $(uname -s)); at release it runs on PILOT"; exit 0; }
for t in pw-record pw-dump xwd xwininfo convert python3; do
    command -v "$t" >/dev/null 2>&1 || { echo "SKIP: $t is not installed on this host"; exit 0; }
done
python3 -c 'import PIL' 2>/dev/null || { echo "SKIP: python3 has no PIL on this host"; exit 0; }
ls "/run/user/$(id -u)"/.mutter-Xwaylandauth.* >/dev/null 2>&1 || { echo "SKIP: no live GNOME session for this user (/run/user/$(id -u)/.mutter-Xwaylandauth.*)"; exit 0; }
[ -n "${ROMDIR:-}" ] && [ -d "$ROMDIR" ] || { echo "FAIL: set ROMDIR to the reference dumps"; exit 1; }

W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT INT TERM
OUT="$REPO/build/desktop_release"; rm -rf "$OUT"; mkdir -p "$OUT"

# ---- the release under test: the newest release/merged-m*/ with a freeze tag (test_release_asset_shape's rule)
NAME="${RELEASE:-}"
if [ -z "$NAME" ]; then
    for d in release/merged-m*/; do
        n="$(basename "$d")"
        if git rev-parse --verify -q "refs/tags/freeze/$n" >/dev/null 2>&1; then echo "$n"; fi
    done | sort -V | tail -1 > "$W/name"
    NAME="$(cat "$W/name")"
fi
[ -n "$NAME" ] || { echo "SKIP: no release/merged-m*/ with a freeze tag in this checkout"; exit 0; }
MARK="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["version_string"])' "release/$NAME/fbneo/manifest.json")"
echo "== the release under test: $NAME (its manifest's mark: $MARK)"

# ---- the assets, cut by the real tool (or given) ---------------------------------------------
if [ -n "${ASSETS:-}" ]; then
    AD="$ASSETS"
else
    for p in fbneo/fbneo mame/cps2; do
        [ -x "release/$NAME/${p%/*}/emulator/bin/linux-x86_64/${p#*/}" ] || {
            echo "SKIP: release/$NAME/${p%/*}/emulator/bin/linux-x86_64/ holds no binary on this host (copy the release's linux-x86_64 build there, or give ASSETS=<dir of zips>)"; exit 0; }
    done
    tools/upload_release_assets.sh "freeze/$NAME" --dry-run > "$OUT/cut.log" 2>&1 || {
        echo "FAIL: the uploader refused its own dry run:"; sed 's/^/      /' "$OUT/cut.log"; exit 1; }
    AD="build/scratch/release_assets/$NAME"
fi
AD="$(cd "$AD" && pwd)"
for e in fbneo mame; do
    [ -f "$AD/$NAME-$e-linux-x86_64.zip" ] || { echo "FAIL: no $NAME-$e-linux-x86_64.zip in $AD"; exit 1; }
done
ok "assets: $NAME-fbneo-linux-x86_64.zip, $NAME-mame-linux-x86_64.zip (from $AD)"

# ---- one player run: unzip, apply, play -------------------------------------------------------
# The steps were measured by hand on PILOT (14z-193/194): MAME stops on its red bad-ROM box until
# a key (#234), then both reach the title, a coin and 1P start reach the select screen.
STEPS_mame="wait:6,cap:redbox,key:space,wait:10,cap:title,key:5,wait:2,key:1,wait:6,cap:select,pwdump:select,apprec:cps2:15,key:Control_L,wait:12,cap:fight,key:Control_L,wait:1,key:Alt_L,wait:1,key:space,wait:1,key:Control_L,wait:8,cap:fight2"
STEPS_fbneo="wait:8,cap:title,key:5,wait:2,key:1,wait:6,cap:select,pwdump:select,apprec:fbneo:15,key:Down,wait:1,key:Down,wait:1,key:Down,wait:1,key:z,wait:12,cap:fight,key:z,wait:1,key:x,wait:1,key:c,wait:1,key:z,wait:1,key:x,wait:8,cap:fight2"
BIN_mame=cps2; BIN_fbneo=fbneo

# THE PERTURBATIONS, written once: the control section and the CONTROL= mode call these.
mute_args() {  # mute_args <emu> -> the driver options that switch the emulator's sound off at launch
    # `--arg=` form: argparse reads a bare `--arg -sound` as a missing value (paid on the first run)
    case "$1" in mame) echo "--arg=-sound --arg=none" ;; fbneo) echo "--env SDL_AUDIODRIVER=dummy" ;; esac
}
UNLINK="--rec-prop node.autoconnect=false"   # the recorder alive and linked to nothing
wrong_mark() {  # wrong_mark <mark> -> the mark with its last character changed
    python3 -c 'import sys; m=sys.argv[1]; c=m[-1]; print(m[:-1] + ("2" if c != "2" else "3"))' "$1"
}

play() {  # play <emu> <run label> [driver options...] -> prints the run dir; returns 3 when the run itself broke
    e="$1"; lab="$2"; shift 2
    d="$OUT/$e.$lab"; mkdir -p "$d"
    pd="$W/$e.$lab/pkg"; mkdir -p "$pd" "$W/$e.$lab/xdg"
    # the asset as downloaded: unzipped (python's zipfile drops the exec bits, restored below)
    ( cd "$pd" && python3 -c 'import sys, zipfile; zipfile.ZipFile(sys.argv[1]).extractall(".")' "$AD/$NAME-$e-linux-x86_64.zip" )
    pkg="$(dirname "$(find "$pd" -name PLAY.command | head -1)")"
    chmod +x "$pkg"/emulator/bin/linux-x86_64/* 2>/dev/null || true
    # README step 1 on the command line, exactly as written there
    ( cd "$pkg" && python3 apply_release.py --romdir "$ROMDIR" --out ./rompath ) > "$d/apply.log" 2>&1 || {
        echo "      $e.$lab: the shipped applier failed:" >&2; tail -3 "$d/apply.log" | sed 's/^/        /' >&2; return 3; }
    stp="$(eval echo "\$STEPS_$e")"
    rc=0
    timeout -k 10 200 python3 "$REPO/tools/desktop_session_play.py" --pd "$pkg" --out "$d" --steps "$stp" \
        --env "XDG_DATA_HOME=$W/$e.$lab/xdg" "$@" > "$d/drive.log" 2>&1 || rc=$?
    if [ "$rc" != 0 ]; then
        echo "      $e.$lab: the desktop run broke (exit $rc):" >&2; tail -4 "$d/drive.log" | sed 's/^/        /' >&2; return 3; fi
    echo "$d"
}

# judge <emu> <run dir> <mark> -> prints MARK/LINKS/SIGNAL lines, sets M_OK L_OK S_OK
judge() {
    e="$1"; d="$2"; mk="$3"; b="$(eval echo "\$BIN_$e")"
    M_OK=0; L_OK=0; S_OK=0
    m="$(python3 tools/desktop_mark_check.py "$d/select.png" "$mk" 2>&1 | tail -1)" || true; echo "      $m"
    case "$m" in "MARK "*" mismatches 0 of "*) M_OK=1 ;; esac
    l="$(python3 tools/desktop_audio_check.py links "$d/pwdump_select.json" "$b" 2>&1 | tail -1)" || true; echo "      $l"
    a2s="$(echo "$l" | sed -n 's/^LINKS .*app_to_sink_active=\([0-9]*\).*/\1/p')"
    s2r="$(echo "$l" | sed -n 's/^LINKS .*sink_to_recorder_active=\([0-9]*\).*/\1/p')"
    if [ "${a2s:-0}" -ge 1 ] && [ "${s2r:-0}" -ge 1 ]; then L_OK=1; fi
    # SIGNAL on the emulator's OWN stream (app.wav, recorded at the select screen): the sink
    # monitor (rec.wav, kept as evidence) also carries gnome-shell's event sounds, measured
    # 14z-194 as -31.9 dBFS bursts in alternate 5 s windows of a MUTED run
    if [ ! -s "$d/app.wav" ]; then echo "      SIGNAL not judged: no app.wav — the emulator played no audio stream"; return 0; fi
    s="$(python3 tools/desktop_audio_check.py signal "$d/app.wav" 0 2>&1 | tail -1)" || true; echo "      $s"
    n="$(echo "$s" | sed -n 's/^SIGNAL windows=\([0-9]*\).*/\1/p')"; bf="$(echo "$s" | sed -n 's/^SIGNAL .*below_floor=\([0-9]*\).*/\1/p')"
    if [ "${n:-0}" -ge 2 ] && [ "${bf:-1}" = 0 ]; then S_OK=1; fi
    return 0
}

# ---- the real runs (in a CONTROL= mode, the perturbation applied to them) ----------------------
for e in fbneo mame; do
    echo "== $e: the player's run"
    opts=""
    vs_ctl_is muted-stream && opts="$(mute_args "$e")"
    vs_ctl_is unlinked-recorder && opts="$UNLINK"
    d="$(play "$e" real $opts)" || { bad "$e: the run did not complete (see above)"; continue; }
    mk="$MARK"; vs_ctl_is wrong-mark && mk="$(wrong_mark "$MARK")"
    judge "$e" "$d" "$mk"
    [ "$M_OK" = 1 ] && ok "$e: the select screen carries the mark $mk (0 mismatches)" || bad "$e: the select screen does not carry the mark $mk"
    [ "$L_OK" = 1 ] && ok "$e: its audio stream is linked to the sink, and the recorder to the sink's monitor" || bad "$e: no active link emulator -> sink -> recorder"
    [ "$S_OK" = 1 ] && ok "$e: its own stream carries signal above -45 dBFS in every 5 s window at the select screen" || bad "$e: its own stream is silent or absent at the select screen"
done

# ---- the controls, in-gate (skipped in a CONTROL= mode: the mode IS the control) ---------------
if [ -z "${VS_CTL:-}" ]; then
    echo "== controls"
    dead=""; got=""
    for e in fbneo mame; do
        d="$(play "$e" muted $(mute_args "$e"))" || { dead="$dead $e(run broke)"; continue; }
        judge "$e" "$d" "$MARK" > "$d/judge.txt"
        if [ "$S_OK" = 0 ]; then got="$got $e:$(grep SIGNAL "$d/judge.txt" | sed 's/^ *//')"; else dead="$dead $e(signal passed)"; fi
    done
    if [ -z "$dead" ]; then vs_ctl_fired muted-stream "the signal check failed on both emulators —$got"
    else vs_ctl_dead muted-stream "not caught on:$dead" || fail=1; fi

    if d="$(play fbneo unlinked $UNLINK)"; then
        judge fbneo "$d" "$MARK" > "$d/judge.txt"
        if [ "$L_OK" = 0 ]; then vs_ctl_fired unlinked-recorder "the link check failed — $(grep LINKS "$d/judge.txt" | sed 's/^ *//')"
        else vs_ctl_dead unlinked-recorder "the unlinked recorder still read as linked: $(grep LINKS "$d/judge.txt")" || fail=1; fi
    else vs_ctl_dead unlinked-recorder "the run broke before a verdict" || fail=1; fi

    wm="$(wrong_mark "$MARK")"; dead=""; got=""
    for e in fbneo mame; do
        m="$(python3 tools/desktop_mark_check.py "$OUT/$e.real/select.png" "$wm" 2>&1)" || true
        case "$m" in *" mismatches 0 of "*) dead="$dead $e" ;; *" mismatches "[0-9]*) got="$got $e:$(echo "$m" | sed -n 's/.*\(mismatches [0-9]* of [0-9]*\).*/\1/p')" ;; *) dead="$dead $e(no verdict)" ;; esac
    done
    if [ -z "$dead" ]; then vs_ctl_fired wrong-mark "$wm rejected on both captures —$got"
    else vs_ctl_dead wrong-mark "$wm accepted or unread on:$dead" || fail=1; fi
fi

echo "  (runs kept under $OUT)"
if [ "$fail" = 0 ]; then echo "PASS: audit_release_linux_desktop — $NAME, both prebuilt Linux emulators: window, mark $MARK, sound"; exit 0; fi
echo "FAIL: audit_release_linux_desktop"; exit 1
