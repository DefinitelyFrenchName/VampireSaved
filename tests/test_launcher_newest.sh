#!/bin/sh
# test_launcher_newest.sh — THE UNIX LAUNCHER RUNS THE NEWEST SET, NOT THE FIRST ONE IT FINDS (14z-197, GitHub #248). ci_portable: no ROM, no emulator, ~2 s.
#
# WHAT: PLAY.command as tools/package_release_platforms.py renders it NOW (launcher_text, the template the next
#   release ships — tests/test_release_launcher.sh drives the COMMITTED release's copy) picks the most recently
#   modified of its candidate sets, so an old roms/vsavjw.zip left from an earlier launch never shadows a newer
#   rompath/vsavjw.zip; FBNeo's roms/vsavjw.zip is replaced by the chosen set; with roms/ the newer, roms/ wins.
# HOW: both platforms' launchers rendered into staged directories with a stub emulator carrying the profile
#   marker, two placeholder sets with explicit mtimes (no ROM bytes), driven under PLAY_DRY_RUN=1.
# EXPECTS: the reported romset is the newer file in both orders, on both platforms; FBNeo's roms/vsavjw.zip reads
#   the newer bytes afterwards. The 14z-197 shape (#248): `PLAY_DRY_RUN=1 sh PLAY.command` printed
#   `romset: .../roms/vsavjw.zip` and kept the old bytes with a newer set in rompath/ (maintainer-ruled 2026-10-10:
#   "prefer the newest one, always"). The Windows PLAY.bat is NOT covered here (it needs cmd).
#
# MUST-FIRE: shadow-tool: first-found — the template with its candidate loop restored to first-found and FBNeo's roms/ copy made only when absent (the pre-#248 launcher) must report the old roms/ set and FAIL section 1 (mode: that template renders the launchers)
set -u
REPO="$(cd "$(dirname "$0")/.." && pwd)"; cd "$REPO"
. "$REPO/tests/lib/controls.sh"; vs_ctl_mode "$0"
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT INT TERM
rc=0; ok() { echo "  ok    $*"; }; bad() { echo "  FAIL  $*"; rc=1; }

case "$(uname -s)" in Darwin) OS=macos ;; Linux) OS=linux ;; *) echo "SKIP: PLAY.command is the macOS/Linux launcher; $(uname -s) runs PLAY.bat"; exit 0 ;; esac
ARCH="$(uname -m)"; case "$ARCH" in arm64|aarch64) ARCH=arm64 ;; x86_64|amd64) ARCH=x86_64 ;; esac
OSARCH="$OS-$ARCH"

first_found() {   # first_found <copy of package_release_platforms.py> — the pre-#248 launcher template
    python3 - "$REPO/tools/package_release_platforms.py" "$1" <<'PY'
import sys
s = open(sys.argv[1]).read()
for old, new in (
        ('    [ -f "$_c" ] || continue\n    if [ -z "$ZIP" ] || [ "$_c" -nt "$ZIP" ]; then ZIP="$_c"; fi\n',
         '    [ -f "$_c" ] && { ZIP="$_c"; break; }\n'),
        ('if [ "$ZIP" != "$HERE/roms/vsavjw.zip" ]; then\n    rm -f "$HERE/roms/vsavjw.zip"\n',
         'if [ ! -f "$HERE/roms/vsavjw.zip" ]; then\n')):
    if s.count(old) != 1:
        sys.exit(f"first_found: {old.splitlines()[0].strip()!r} found {s.count(old)} times, not once")
    s = s.replace(old, new)
open(sys.argv[2], "w").write(s)
PY
}
GEN="$REPO/tools/package_release_platforms.py"
if vs_ctl_is first-found; then
    first_found "$W/gen_first.py" || { echo "REFUSED: CONTROL=first-found could not build its copy"; exit 3; }
    GEN="$W/gen_first.py"
fi

render() {   # render <generator> <platform> <dir> — PLAY.command from launcher_text, a stub emulator
    rm -rf "$3"; mkdir -p "$3/emulator/bin/$OSARCH" "$3/roms" "$3/rompath"
    python3 - "$1" "$2" "$3/PLAY.command" <<'PY' || return 1
import importlib.util, sys
spec = importlib.util.spec_from_file_location("prp", sys.argv[1])
m = importlib.util.module_from_spec(spec); spec.loader.exec_module(m)
open(sys.argv[3], "w").write(m.launcher_text(sys.argv[2], "test"))
PY
    chmod +x "$3/PLAY.command"
    if [ "$2" = fbneo ]; then printf '#!/bin/sh\n# CPS-2 WIDE v1\necho started\n' > "$3/emulator/bin/$OSARCH/fbneo"
    else printf '#!/bin/sh\ncase "$*" in *-listfull*) echo vsavjw ;; *) echo started ;; esac\n' > "$3/emulator/bin/$OSARCH/cps2"; fi
    chmod +x "$3/emulator/bin/$OSARCH/"*
}
sets() {   # sets <dir> <older: roms|rompath> — two placeholder sets, the named one older
    printf 'roms set' > "$1/roms/vsavjw.zip"; printf 'rompath set' > "$1/rompath/vsavjw.zip"
    if [ "$2" = roms ]; then touch -t 202001010000 "$1/roms/vsavjw.zip"; touch -t 202501010000 "$1/rompath/vsavjw.zip"
    else touch -t 202501010000 "$1/roms/vsavjw.zip"; touch -t 202001010000 "$1/rompath/vsavjw.zip"; fi
}
case1() {   # case1 <generator> <dir> — one line per wrong choice
    for plat in fbneo mame; do
        for older in roms rompath; do
            D="$2/$plat-$older"; render "$1" "$plat" "$D" || { echo "    $plat: could not render PLAY.command"; continue; }
            sets "$D" "$older"
            newer=rompath; [ "$older" = rompath ] && newer=roms
            ( cd "$D" && PLAY_DRY_RUN=1 PLAY_CLEAR_QUARANTINE=1 sh ./PLAY.command </dev/null ) > "$D.log" 2>&1
            e=$?
            [ "$e" = 0 ] || { echo "    $plat/$older older: the launcher exited $e: $(grep -m1 '^!!' "$D.log")"; continue; }
            grep -q "^romset: $D/$newer/vsavjw.zip\$" "$D.log" \
                || echo "    $plat/$older older: chose $(sed -n 's/^romset: //p' "$D.log"), not the newer $newer/vsavjw.zip"
            if [ "$plat" = fbneo ]; then
                [ "$(cat "$D/roms/vsavjw.zip")" = "$newer set" ] \
                    || echo "    fbneo/$older older: roms/vsavjw.zip reads '$(cat "$D/roms/vsavjw.zip")', not the newer set"
            fi
        done
    done
}
echo "== 1. the newest set wins, in both orders, on both platforms (#248)"
case1 "$GEN" "$W/s1" > "$W/s1.txt" 2>&1
[ -s "$W/s1.txt" ] && { bad "a launcher chose an older set:"; cat "$W/s1.txt"; } \
    || ok "fbneo and mame: an older roms/ set loses to a newer rompath/ one and the reverse; FBNeo's roms/ carries the newer bytes"

if vs_ctl_is first-found; then
    [ "$rc" = 1 ] && { echo "FAIL: test_launcher_newest (control mode: first-found)"; exit 1; }
    echo "FAIL: test_launcher_newest — control mode first-found left the gate green"; exit 1
fi

echo "== 2. control"
if ! first_found "$W/ctl.py" > "$W/ctlb.txt" 2>&1; then vs_ctl_dead first-found "the copy could not be built: $(tail -1 "$W/ctlb.txt")" || rc=1
elif case1 "$W/ctl.py" "$W/c" > "$W/c.txt" 2>&1 && [ ! -s "$W/c.txt" ]; then vs_ctl_dead first-found "the first-found launcher passed section 1" || rc=1
elif grep -q 'roms older: chose .*/roms/vsavjw.zip, not the newer rompath' "$W/c.txt"; then vs_ctl_fired first-found "the first-found launcher ran the older roms/ set over a newer rompath/ one"
else vs_ctl_dead first-found "section 1 failed for another reason: $(head -1 "$W/c.txt")" || rc=1; fi

[ "$rc" = 0 ] && echo "PASS: test_launcher_newest" || echo "FAIL: test_launcher_newest"
exit "$rc"
