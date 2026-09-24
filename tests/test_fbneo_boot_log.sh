#!/bin/sh
# test_fbneo_boot_log.sh — the verdict logic of tests/lib/fbneo_boot_log.sh (what
# a healthy FBNeo WIDE boot log must show) against RECORDED boot logs from two
# real hosts: the first Windows boot of the release binary (2026-09-13, MSYS2 —
# every emulator-core message missing) and this MacBook's release-binary boot
# (14z-151). ROM-free, no emulator, ~1 s.
#
# WHAT: the verdict logic of tests/lib/fbneo_boot_log.sh — what a healthy FBNeo WIDE boot
#   log must show, per OS — proven against RECORDED boot logs from the first Windows boot
#   (no core messages by design) and this Mac's release-binary boot.
# HOW: the reader applied to the recorded logs under each OS rule: the Windows log passes on
#   windows and fails on macos, the macOS log passes on both (the profile line demanded
#   where the core prints); controls drop the WIDE member line, drop the profile line, and
#   remove the descriptor rows.
# EXPECTS: the five sections as listed; each control fails or refuses. A Windows release
#   verdict rests on this before it is trusted.
#
# MUST-FIRE: perturbed-copy: wide-member-dropped — the recorded Windows boot with its `vsw.41` load line removed must FAIL the member check (mode: section 1 checks that copy)
# MUST-FIRE: perturbed-copy: profile-line-dropped — the recorded macOS boot with `CPS-2 WIDE v1 profile active` removed must FAIL: the core's messages reach that log, so the missing line means vsavjw booted without the WIDE init (mode: section 2 checks that copy)
# MUST-FIRE: perturbed-copy: descriptor-unreadable — a copy of patch 0002 with the vsavjw descriptor's rows removed must make the check REFUSE, never pass an empty member list (mode: sections 1-3 read that copy)
#
# WHY. tests/test_release_binaries.sh booted the Windows binary CORRECTLY and went
# red on the one line FBNeo's Windows frontend can never print: it connects the
# emulator core's message function only off SDL_WINDOWS (docs/platform/gotchas.md,
# 2026-09-13). The evidence that replaced it is only ever exercised by that gate
# on a Windows host, so its verdicts are proven HERE, against the real Windows
# log, before a Windows verdict is trusted ([VSP-19]).
#
# Sections: 1 the Windows boot on windows PASSES and says why no profile line;
# 2 the macOS boot on macos PASSES; 3 the macOS boot on windows PASSES with the
# profile line DEMANDED (its core lines print); 4 the Windows boot on macos FAILS
# (no core line where FBNeo prints them); 5 an error line FAILS; then the controls.
#
# Usage: tests/test_fbneo_boot_log.sh
set -eu
REPO="$(cd "$(dirname "$0")/.." && pwd)"; cd "$REPO"
. "$REPO/tests/lib/controls.sh"; vs_ctl_mode "$0"
. "$REPO/tests/lib/fbneo_boot_log.sh"
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT INT TERM
fail=0
PATCH="$REPO/emu/fbneo-patches/0002-cps2-wide-v1.patch"
[ -f "$PATCH" ] || { echo "FAIL: no $PATCH"; echo "FAIL: test_fbneo_boot_log"; exit 1; }

# ---- THE RECORDED LOGS
# The 31 load lines are BYTE-IDENTICAL on the two hosts (diffed 2026-09-13), and
# so is the frontend block after sound init, so each is written once. Elided,
# and read by nothing here: home-directory paths (<home>), and the macOS boot's
# four-line ROM-size block, whose hexadecimal region sizes would read as
# addresses to tools/gen_annotations.py.
loads() { cat <<'EOF'
Loading program (vm3j.03d)... (OK)
Loading program (vm3j.04d)... (OK)
Loading program (vm3j.05a)... (OK)
Loading program (vm3j.06b)... (OK)
Loading program (vm3j.07b)... (OK)
Loading program (vm3j.08a)... (OK)
Loading program (vm3j.09b)... (OK)
Loading program (vm3j.10b)... (OK)
Loading program (vsw.41)... (OK)
Loading program (vsw.42)... (OK)
Loading program (vsw.43)... (OK)
Loading program (vsw.44)... (OK)
Loading graphics (vm3.13m)... (OK)
Loading graphics (vm3.15m)... (OK)
Loading graphics (vm3.17m)... (OK)
Loading graphics (vm3.19m)... (OK)
Loading graphics (vm3.14m)... (OK)
Loading graphics (vm3.16m)... (OK)
Loading graphics (vm3.18m)... (OK)
Loading graphics (vm3.20m)... (OK)
Loading graphics (vsw.31m)... (OK)
Loading graphics (vsw.33m)... (OK)
Loading graphics (vsw.35m)... (OK)
Loading graphics (vsw.37m)... (OK)
Loading program (vsw.z01)... (OK)
Loading program (vsw.z02)... (OK)
Loading sound (vm3.11m)... (OK)
Loading sound (vm3.12m)... (OK)
Loading sound (vsw.21m)... (OK)
Loading sound (vsw.22m)... (OK)
Loading vsavj.key... (OK)
EOF
}
frontend() { cat <<'EOF'
Game resolution: 384x224@59.630000
bbp: 32
setting logical size w: 384 h: 288
nVidImageWidth=384 nVidImageHeight=224 nVidImagePitch=1536
Malloc for video Ok 344064
p1 coin 5
p1 start 1
p1 up ARROW UP
p1 down ARROW DOWN
p1 left ARROW LEFT
p1 right ARROW RIGHT
p1 fire 1 A
p1 fire 2 S
p1 fire 3 D
p1 fire 4 Z
p1 fire 5 X
p1 fire 6 C
p2 coin 6
p2 start 2
p2 up Joy 0 Up (Y negative)
p2 down Joy 0 Down (Y positive)
p2 left Joy 0 Left (X negative)
p2 right Joy 0 Right (X positive)
p2 fire 1 Joy 0 Button 0
p2 fire 2 Joy 0 Button 1
p2 fire 3 Joy 0 Button 2
p2 fire 4 Joy 0 Button 3
p2 fire 5 Joy 0 Button 4
p2 fire 6 Joy 0 Button 5
reset F3
diag F2
service 9
volumeup code 0x00
volumedown code 0x00
EOF
}
# the Windows boot: MSYS2, release/emulators/fbneo/windows-x86_64, 2026-09-13
# (that host's build/fbneo_boot_windows.log, pasted by the maintainer)
{ loads
  printf 'FBNeo v1.0.0.03\nSDLSoundInit (44100Hz) (5963FPS)\n'
  frontend
  printf 'loading state 0 config/games/vsavjw.fs\n'
} > "$W/windows.log"
# this MacBook's boot: release/emulators/fbneo/macos-arm64, 14z-151 (build/fbneo_boot_macos.log)
{ cat <<'EOF'
*** Starting emulation of vsavjw - Vampire Savior: The Lord of Vampire (Japan 970519, CPS-2 WIDE v1).
Cheat cpu-register INIT.
CPS-2 WIDE v1 profile active
EOF
  loads
  printf 'FBNeo v1.0.0.03\nLoading config from <home>/Library/Application Support/fbneo/config/fbneo.ini\nSDLSoundInit (44100Hz) (5963FPS)\n'
  frontend
  printf 'loading state 0 <home>/Library/Application Support/fbneo/config/games/vsavjw.fs\n'
  printf 'saving state 0 <home>/Library/Application Support/fbneo/config/games/vsavjw.fs\nDoing exit cleanup\n'
} > "$W/macos.log"

# ---- the three perturbations, ONE function each (the control section and the mode both call them)
perturb_member()  { grep -v -x -F 'Loading program (vsw.41)... (OK)' "$1" > "$2"; }
perturb_profile() { grep -v -x -F 'CPS-2 WIDE v1 profile active' "$1" > "$2"; }
perturb_descriptor() {  # the rows of VsavjwRomDesc removed from a copy of the patch
    python3 - "$1" "$2" <<'PY'
import re, sys
t = open(sys.argv[1]).read()
t2, n = re.subn(r"(^\+static struct BurnRomInfo VsavjwRomDesc\[\] = \{\n)(.*?)(^\+\};)", r"\1\3", t,
                count=1, flags=re.S | re.M)
if n != 1:
    sys.exit("perturb_descriptor: VsavjwRomDesc not found in " + sys.argv[1])
open(sys.argv[2], "w").write(t2)
PY
}
WINLOG="$W/windows.log"; MACLOG="$W/macos.log"; PATCHUSE="$PATCH"
if vs_ctl_is wide-member-dropped;   then perturb_member "$W/windows.log" "$W/mode.log"; WINLOG="$W/mode.log"; fi
if vs_ctl_is profile-line-dropped;  then perturb_profile "$W/macos.log" "$W/mode.log"; MACLOG="$W/mode.log"; fi
if vs_ctl_is descriptor-unreadable; then perturb_descriptor "$PATCH" "$W/mode.patch"; PATCHUSE="$W/mode.patch"; fi

check() { vs_fbneo_boot_log "$1" "$2" "$3" > "$4" 2>&1; }   # check <log> <hostos> <patch> <out>
show()  { sed 's/^/        /' "$1"; }

# ---- 1. the Windows boot, on windows: PASS, and it says why there is no profile line
if check "$WINLOG" windows "$PATCHUSE" "$W/s1.txt"; then
    if grep -q '^  (windows: ' "$W/s1.txt"; then
        echo "  1 ok: the Windows boot (31 members, no core line) passes on windows, saying why"
    else
        echo "FAIL: section 1 passed without saying why no profile line can print:"; show "$W/s1.txt"; fail=1
    fi
else
    echo "FAIL: section 1 — the recorded Windows boot, a CORRECT boot, fails on windows:"; show "$W/s1.txt"; fail=1
fi
# ---- 2. the macOS boot, on macos: PASS
if check "$MACLOG" macos "$PATCHUSE" "$W/s2.txt"; then
    echo "  2 ok: the macOS boot (core lines, profile line, 31 members) passes on macos"
else
    echo "FAIL: section 2 — the recorded macOS boot, a CORRECT boot, fails on macos:"; show "$W/s2.txt"; fail=1
fi
# ---- 3. the macOS boot, on windows: PASS with the profile line DEMANDED — the rule
# keys on whether core lines print, never on the OS name, so nothing is excused here
if check "$MACLOG" windows "$PATCHUSE" "$W/s3.txt"; then
    if grep -q '^  (windows: ' "$W/s3.txt"; then
        echo "FAIL: section 3 excused the profile line on a log whose core lines DO print:"; show "$W/s3.txt"; fail=1
    else
        echo "  3 ok: a windows log whose core lines print gets the profile-line check, not the excuse"
    fi
else
    echo "FAIL: section 3 — the macOS boot fails when named windows:"; show "$W/s3.txt"; fail=1
fi
# ---- 4. the Windows boot, on macos: FAIL — no core line on a host where FBNeo prints them
if check "$W/windows.log" macos "$PATCH" "$W/s4.txt"; then
    echo "FAIL: section 4 — a log with no core line PASSED on macos"; fail=1
elif grep -q -F 'no `*** Starting emulation of` line on macos' "$W/s4.txt"; then
    echo "  4 ok: the same log on macos fails — a missing core line is excused on Windows only"
else
    echo "FAIL: section 4 failed for another reason:"; show "$W/s4.txt"; fail=1
fi
# ---- 5. an error line FAILS, on either host
{ cat "$W/windows.log"; echo "vsw.41 (not found)"; } > "$W/err.log"
if check "$W/err.log" windows "$PATCH" "$W/s5.txt"; then
    echo "FAIL: section 5 — a log carrying 'not found' PASSED"; fail=1
elif grep -q 'carries an error' "$W/s5.txt"; then
    echo "  5 ok: a 'not found' line fails"
else
    echo "FAIL: section 5 failed for another reason:"; show "$W/s5.txt"; fail=1
fi

# ---- must-fire controls: each perturbation of a REAL recorded input must FAIL, for the stated reason
perturb_member "$W/windows.log" "$W/c1.log"
if check "$W/c1.log" windows "$PATCH" "$W/c1.txt"; then
    vs_ctl_dead wide-member-dropped "the Windows boot with vsw.41 never loaded still passed" || true; fail=1
elif grep -q 'never loaded (OK): vsw.41$' "$W/c1.txt"; then
    vs_ctl_fired wide-member-dropped "$(grep -m1 'never loaded' "$W/c1.txt")"
else
    vs_ctl_dead wide-member-dropped "failed for another reason: $(grep -m1 '^FAIL' "$W/c1.txt")" || true; fail=1
fi
perturb_profile "$W/macos.log" "$W/c2.log"
if check "$W/c2.log" macos "$PATCH" "$W/c2.txt"; then
    vs_ctl_dead profile-line-dropped "the macOS boot without its profile line still passed" || true; fail=1
elif grep -q 'booted without the WIDE init' "$W/c2.txt"; then
    vs_ctl_fired profile-line-dropped "$(grep -m1 'WIDE init' "$W/c2.txt")"
else
    vs_ctl_dead profile-line-dropped "failed for another reason: $(grep -m1 '^FAIL' "$W/c2.txt")" || true; fail=1
fi
perturb_descriptor "$PATCH" "$W/c3.patch"
if check "$W/windows.log" windows "$W/c3.patch" "$W/c3.txt"; then
    vs_ctl_dead descriptor-unreadable "an empty vsavjw descriptor passed as every member loaded" || true; fail=1
elif grep -q 'REFUSING' "$W/c3.txt"; then
    vs_ctl_fired descriptor-unreadable "$(grep -m1 'REFUSING' "$W/c3.txt")"
else
    vs_ctl_dead descriptor-unreadable "failed for another reason: $(grep -m1 '^FAIL' "$W/c3.txt")" || true; fail=1
fi

[ "$fail" = 0 ] && echo "PASS: test_fbneo_boot_log" || { echo "FAIL: test_fbneo_boot_log"; exit 1; }
