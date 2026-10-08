#!/bin/sh
# audit_release_linux_cleanhost.sh — THE LINUX RELEASE ON A CLEAN HOST: a stock Ubuntu 24.04 holding only the
# libraries the release may ask the host for runs both prebuilt emulators (#226, 14z-195).
#
# WHAT: each prebuilt linux-x86_64 asset (FBNeo and MAME), in a stock ubuntu:24.04 container (podman) with ONLY the
#   packages that provide tests/expected/linux_host_provided.tsv's sonames, python3 (the README's one prerequisite)
#   and Xvfb (a display server: the stand-in for a desktop's), is applied with the shipped applier, every binary and
#   bundled library resolves (ldd: nothing "not found"), and `sh PLAY.command` runs the emulator under LD_DEBUG=libs:
#   MAME for 30 emulated seconds to exit 0, FBNeo still running at its 30 s cut-off; and every library a PACKAGE
#   file asked the host for at run time — the dlopen'd ones included, which tools/check_host_libs.py (DT_NEEDED only)
#   cannot see — is on the list (tools/cleanhost_libs.py C1), every search resolved (C2).
# HOW: tools/upload_release_assets.sh --dry-run cuts the assets (or ASSETS=<dir> of zips); a container run per
#   emulator mounts the assets and ROMDIR read-only; the per-process LD_DEBUG logs come back to build/cleanhost_release/
#   and tools/cleanhost_libs.py judges each. The list of packages is THIS file's PKGS, checked in the container: every
#   listed soname must then be known to ldconfig (C0), so a list row with no package fails rather than going untested.
#   About 4 min on PILOT (two containers of ~2 min, the apt install dominating). Linux with podman ONLY; elsewhere it
#   SKIPs and says so.
# EXPECTS: C0 every listed soname present; per emulator: apply OK, ldd 0 not found (binary and every bundled .so),
#   the run's exit as above, C1 0 unlisted, C2 0 unresolved, and at least one process that asked the host for a
#   library (the emulator itself ran); each control fails.
# FOLLOWS: tests/expected/linux_host_provided.tsv tools/cleanhost_libs.py tools/upload_release_assets.sh
#   tools/package_release_platforms.py tools/build_release_emulators.sh tests/lib/controls.sh
#   emu/fbneo/ emu/fbneo-patches/ tools/setup_fbneo.sh emu/mame-patches/ tools/setup_mame.sh build/manifest/
#
# MUST-FIRE: known-bad: uninstalled-host-lib — the container built WITHOUT libasound2t64 (libasound.so.2, which both binaries link) must FAIL: C0 misses the soname and ldd reports it not found
# MUST-FIRE: perturbed-copy: list-minus-one — the measured runs judged against the list without libGL.so.1 (asked for by both) must FAIL C1 (in-gate; as a mode the real runs are judged that way and the gate FAILs)
#
# WHY. #226: the desktop gate (tests/audit_release_linux_desktop.sh) plays the release on PILOT, whose toolchain is
# installed, so a library the package forgot could be found on PILOT and missing on a player's machine. This gate is
# the clean host. First run 14z-195 (build/agent195/cleanhost1): 20 sonames asked through the package, 19 listed and
# libudev.so.1 not — SDL dlopens it for device hotplug; RULED host-provided by the maintainer 2026-10-08.
#
# WHAT IT DOES NOT CLAIM: a desktop's display server, compositor or GPU (Xvfb, software Mesa); sound reaching a device
# (no sound server runs: SDL's pulse and ALSA attempts are what is loaded); that a library loaded by a HOST library is
# present on every distribution (counted, not judged); other distributions or releases than ubuntu:24.04; the
# version mark, the window, the sound (the desktop gate's).
#
# Usage: ROMDIR=... tests/audit_release_linux_cleanhost.sh   [RELEASE=merged-mNN] [ASSETS=<dir>] [IMAGE=...]
set -eu
REPO="$(cd "$(dirname "$0")/.." && pwd)"; cd "$REPO"
. "$REPO/tests/lib/controls.sh"; vs_ctl_mode "$0"
fail=0
ok()  { echo "  ok    $*"; }
bad() { echo "  FAIL  $*"; fail=1; }

[ "$(uname -s)" = Linux ] || { echo "SKIP: not a Linux host (this is $(uname -s)); at release it runs on PILOT"; exit 0; }
command -v podman >/dev/null 2>&1 || { echo "SKIP: podman is not installed on this host"; exit 0; }
[ -n "${ROMDIR:-}" ] && [ -d "$ROMDIR" ] || { echo "FAIL: set ROMDIR to the reference dumps"; exit 1; }
ROMDIR="$(cd "$ROMDIR" && pwd)"
IMAGE="${IMAGE:-docker.io/library/ubuntu:24.04}"
echo "  head  $(git describe --always --dirty --abbrev=40 2>/dev/null || echo no git); host $(hostname) $(uname -sm); podman $(podman --version | awk '{print $3}'); image $IMAGE"

# The packages that provide the list's sonames on Ubuntu 24.04 (C0 checks the list is covered), and the two extras.
PKGS="libc6 libgcc-s1 libstdc++6 libatomic1 libnsl2 zlib1g libexpat1 libglib2.0-0t64 libgl1 libice6 libsm6 libx11-6
 libxext6 libxrender1 libxcursor1 libxfixes3 libxi6 libxrandr2 libxss1 libwayland-client0 libwayland-cursor0
 libwayland-egl1 libdrm2 libgbm1 libasound2t64 libpulse0 libudev1 python3 xvfb"

W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT INT TERM
OUT="$REPO/build/cleanhost_release"; rm -rf "$OUT"; mkdir -p "$OUT"

# ---- the release under test (the desktop gate's rule) and its assets ------------------------------------------
NAME="${RELEASE:-}"
if [ -z "$NAME" ]; then
    for d in release/merged-m*/; do
        n="$(basename "$d")"
        if git rev-parse --verify -q "refs/tags/freeze/$n" >/dev/null 2>&1; then echo "$n"; fi
    done | sort -V | tail -1 > "$W/name"
    NAME="$(cat "$W/name")"
fi
[ -n "$NAME" ] || { echo "SKIP: no release/merged-m*/ with a freeze tag in this checkout"; exit 0; }
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
echo "== the release under test: $NAME (assets from $AD)"

# ---- the in-container run, written once ------------------------------------------------------------------------
cat > "$W/in.sh" <<'IN'
#!/bin/sh
# inside the container: $1 emulator, $2 release name, $3 packages; /assets /roms (ro), /out, /list.tsv (ro)
set -u
e="$1"; n="$2"; pk="$3"
export DEBIAN_FRONTEND=noninteractive
{ apt-get update -qq && apt-get install -y -qq --no-install-recommends $pk; } > /out/apt.log 2>&1 || { echo "APT exit $?"; tail -5 /out/apt.log; exit 2; }
dpkg-query -W -f='${Package} ${Version}\n' > /out/dpkg.txt
miss=""; for so in $(grep -v '^#' /list.tsv | grep -v '^soname' | cut -f1); do ldconfig -p | grep -q "^[[:space:]]$so " || miss="$miss $so"; done
echo "C0 packages $(wc -l < /out/dpkg.txt); listed sonames missing:${miss:- none}"
Xvfb :9 -screen 0 1280x1024x24 > /out/xvfb.log 2>&1 &
export DISPLAY=:9 XDG_DATA_HOME=/tmp/xdg; sleep 2
mkdir -p /work && cd /work && python3 -c 'import sys, zipfile; zipfile.ZipFile(sys.argv[1]).extractall(".")' "/assets/$n-$e-linux-x86_64.zip"
cd "/work/$e"; B=emulator/bin/linux-x86_64; x=$B/cps2; [ "$e" = fbneo ] && x=$B/fbneo
chmod +x "$x"
python3 apply_release.py --romdir /roms --out ./rompath > /out/apply.log 2>&1; echo "APPLY exit $? $(tail -1 /out/apply.log)"
nf=0; for f in "$x" $B/*.so*; do c=$(ldd "$f" 2>&1 | grep -c 'not found'); nf=$((nf + c)); [ "$c" = 0 ] || ldd "$f" | grep 'not found' | sed "s|^|  $(basename "$f"):|"; done
echo "LDD not found $nf"
if [ "$e" = mame ]; then LD_DEBUG=libs LD_DEBUG_OUTPUT=/out/ld timeout 120 sh PLAY.command -seconds_to_run 30 -nothrottle > /out/play.log 2>&1
else LD_DEBUG=libs LD_DEBUG_OUTPUT=/out/ld timeout 30 sh PLAY.command > /out/play.log 2>&1; fi
echo "PLAY exit $?"
IN

crun() {  # crun <emu> <label> <packages> -> the container's summary in $OUT/<emu>.<label>/summary.txt
    d="$OUT/$1.$2"; mkdir -p "$d"
    podman run --rm -v "$AD:/assets:ro" -v "$ROMDIR:/roms:ro" -v "$d:/out" -v "$W/in.sh:/in.sh:ro" \
        -v "$REPO/tests/expected/linux_host_provided.tsv:/list.tsv:ro" "$IMAGE" sh /in.sh "$1" "$NAME" "$3" > "$d/summary.txt" 2>&1 || true
}

# judge <emu> <label> [--drop SONAME] -> sets C0_OK APPLY_OK LDD_OK PLAY_OK C1_OK RAN (and prints)
judge() {
    e="$1"; d="$OUT/$1.$2"; shift 2
    C0_OK=0; APPLY_OK=0; LDD_OK=0; PLAY_OK=0; C1_OK=1; RAN=0
    sed 's/^/      /' "$d/summary.txt"
    grep -q '^C0 .*missing: none$' "$d/summary.txt" && C0_OK=1
    grep -q '^APPLY exit 0 ' "$d/summary.txt" && APPLY_OK=1
    grep -q '^LDD not found 0$' "$d/summary.txt" && LDD_OK=1
    if [ "$e" = mame ]; then grep -q '^PLAY exit 0$' "$d/summary.txt" && PLAY_OK=1
    else grep -q '^PLAY exit 124$' "$d/summary.txt" && PLAY_OK=1; fi
    for f in "$d"/ld.*; do
        [ -f "$f" ] || continue
        r="$(python3 tools/cleanhost_libs.py "$f" "/work/$e" tests/expected/linux_host_provided.tsv "$@" 2>&1)" && rc=0 || rc=1
        s="$(echo "$r" | tail -1)"; echo "      $(basename "$f"): $s"
        echo "$r" | grep -E 'UNLISTED|UNRESOLVED' | sed 's/^/        /' || true
        [ "$rc" = 0 ] || C1_OK=0
        case "$s" in "CLEANHOST asked=0 "*) ;; "CLEANHOST asked="*) RAN=1 ;; esac
    done
}

DROP=""; vs_ctl_is list-minus-one && DROP="--drop libGL.so.1"
P="$PKGS"; vs_ctl_is uninstalled-host-lib && P="$(echo $PKGS | tr ' ' '\n' | grep -vx libasound2t64 | tr '\n' ' ')"
for e in fbneo mame; do
    echo "== $e: a stock $IMAGE, the list's packages only"
    crun "$e" real "$P"
    judge "$e" real $DROP
    [ "$C0_OK" = 1 ] && ok "$e: C0 every listed soname is present in the container" || bad "$e: C0 a listed soname is missing (see above)"
    [ "$APPLY_OK" = 1 ] && ok "$e: the shipped applier built the set" || bad "$e: the shipped applier failed"
    [ "$LDD_OK" = 1 ] && ok "$e: the binary and every bundled library resolve (ldd: 0 not found)" || bad "$e: ldd reports a library not found"
    [ "$PLAY_OK" = 1 ] && ok "$e: PLAY.command ran the emulator ($([ "$e" = mame ] && echo '30 emulated s, exit 0' || echo 'still running at the 30 s cut-off'))" || bad "$e: the run did not end as expected (see PLAY exit above)"
    [ "$RAN" = 1 ] && [ "$C1_OK" = 1 ] && ok "$e: C1/C2 every library the package asked the host for is listed, every search resolved${DROP:+ (list $DROP)}" \
        || bad "$e: C1/C2 an unlisted or unresolved library${DROP:+ (list $DROP)}, or no process asked for one (RAN=$RAN)"
done

if [ -n "${VS_CTL:-}" ]; then
    [ "$fail" = 1 ] && { vs_ctl_fired "$VS_CTL" "the perturbed run failed (mode)"; echo "FAIL: audit_release_linux_cleanhost (control mode)"; exit 1; }
    echo "REFUSED: CONTROL=$VS_CTL — the perturbation did not make the gate fail: a dead mode, not a verdict"; exit 3
fi

echo "== controls"
# list-minus-one, in-gate on the real runs' logs
got=""; dead=""
for e in fbneo mame; do
    judge "$e" real --drop libGL.so.1 > "$OUT/$e.real/ctl_list.txt"
    [ "$C1_OK" = 0 ] && got="$got $e" || dead="$dead $e"
done
[ -z "$dead" ] && vs_ctl_fired list-minus-one "C1 failed on$got with libGL.so.1 dropped from the list" || { vs_ctl_dead list-minus-one "C1 passed on:$dead" || fail=1; }
# uninstalled-host-lib: one container without libasound2t64 (the FBNeo package)
crun fbneo noasound "$(echo $PKGS | tr ' ' '\n' | grep -vx libasound2t64 | tr '\n' ' ')"
judge fbneo noasound > "$OUT/fbneo.noasound/judge.txt"
if [ "$C0_OK" = 0 ] && [ "$LDD_OK" = 0 ] && grep -q '^      C0 .*missing: libasound.so.2$' "$OUT/fbneo.noasound/judge.txt"; then vs_ctl_fired uninstalled-host-lib "without libasound2t64: $(grep '^      C0' "$OUT/fbneo.noasound/judge.txt" | sed 's/^ *//'); $(grep '^      LDD' "$OUT/fbneo.noasound/judge.txt" | sed 's/^ *//')"
else vs_ctl_dead uninstalled-host-lib "C0_OK=$C0_OK LDD_OK=$LDD_OK without libasound2t64" || fail=1; fi

if [ "$fail" = 0 ]; then echo "PASS: audit_release_linux_cleanhost"; else echo "FAIL: audit_release_linux_cleanhost"; exit 1; fi
