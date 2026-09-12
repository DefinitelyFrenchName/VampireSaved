#!/bin/sh
# test_release_binaries.sh — the PREBUILT emulator binaries for THIS host under
# release/emulators/{fbneo,mame}/<os-arch>/ (the build resource every release's
# emulator/bin/<os-arch>/ is hash-verified from; maintainer-ruled 2026-09-11:
# recipe AND prebuilt) are what their BINARY.txt says (sha256 per file, every
# file named), SELF-CONTAINED (no absolute non-system library reference —
# bundled as @loader_path), SIGNED (codesign --verify), carry the profile, and
# BOOT the current merged romset: FBNeo headless under the SDL dummy drivers for
# 20 s (the profile line, 31 members "(OK)", still running when killed); MAME
# `-verifyroms vsavjw` flags EXACTLY the WIDE zip's rewritten/new members (it can never say
# "good" on a content set: stock CRCs for rewritten members, sentinels for new ones,
# [VSP-75]) AND one frozen masked legacy expectation of the
# current freeze REPRODUCED by the release binary (run_suite, SUITE_ONLY). So a
# shipped binary is proven to be the same instrument the gates ran, not a
# recipe believed equivalent. mame + fbneo, ~2 min.
#
# MUST-FIRE: perturbed-copy: flipped-library-byte — a copy of the fbneo resource dir with one byte of a bundled library flipped must fail the record check (mode: the gate checks that copy in place of the resource)
# MUST-FIRE: perturbed-copy: absolute-reference — a copy of the mame resource dir carrying a reference that does NOT resolve inside the directory, with the record made consistent so the record check PASSES, must fail the self-containment check (macOS: one install name rewritten back to an absolute Homebrew path, re-signed and re-hashed; Linux/Windows: one bundled library removed together with its sha256 row, so ldd reports it not found) (mode: the gate checks that copy)
#
# WHY. A prebuilt built by the EMULATOR.md recipe links Homebrew's SDL by
# absolute path (measured 14z-149: otool -L on both binaries) and runs only on
# the build host; the bundling step is what makes it a release artifact, and a
# regression there is invisible to every other gate because every other gate
# runs the harness binary from emu/fbneo. The MAME leg's frozen expectation is
# the strongest claim available: the release binary and the gate instrument
# traverse the same RAM on a legacy replay.
#
# ALL THREE OSes SINCE ITEM 1 OF THE 14z-149 CLOSE, and the self-containment
# check is deliberately NOT the bundler's own library allowlist re-read back —
# it is a RESOLUTION check with the host's own loader tooling, which answers
# the question that matters ("will this load on a machine that has none of the
# build host's packages?") rather than the one the bundler already answered:
#   macOS    otool -L: every reference is /usr/lib, /System or @loader_path,
#            and codesign --verify --strict (install_name_tool invalidates a
#            signature, and an unsigned binary does not run on Apple Silicon)
#   Linux    ldd: every resolved path is inside this directory or a system
#            path, nothing "not found" — RUNPATH=$ORIGIN is what makes that so
#   Windows  ldd/objdump: every import resolves beside the .exe or to the
#            Windows directory. There is NO signature on this platform, so the
#            record's sha256 rows are the integrity and the gate says so
#            instead of asserting a signature that cannot exist.
# An OS this gate does not know still FAILS, naming what must be added — never
# a silent pass.
#
# Usage: ROMDIR=... [MERGED=build/m3b_merged26] [RELEASE_EMULATORS=release/emulators]
#        tests/test_release_binaries.sh
#   defaults build/m3b_merged26 (M18, the current freeze). SKIPs when no resource
#   dir exists for this host's os-arch (tools/build_release_emulators.sh builds one).
set -eu
ROMDIR="${ROMDIR:?set ROMDIR}"
REPO="$(cd "$(dirname "$0")/.." && pwd)"; cd "$REPO"
ROMDIR="$(cd "$ROMDIR" && pwd)"
. "$REPO/tests/lib/controls.sh"; vs_ctl_mode "$0"
MERGED="${MERGED:-build/m3b_merged26}"
ROOT="${RELEASE_EMULATORS:-release/emulators}"
# The os-arch spelling MUST match tools/build_release_emulators.sh's, or this
# gate looks in a directory that builder never wrote (and SKIPs, reading as
# "nothing to check" instead of "wrong name").
case "$(uname -s)" in
Darwin) OS=macos ;;
Linux)  OS=linux ;;
MINGW*|MSYS*|CYGWIN*) OS=windows ;;
*) OS="$(uname -s | tr 'A-Z' 'a-z')" ;;
esac
case "$(uname -m)" in arm64|aarch64) ARCH=arm64 ;; x86_64|amd64) ARCH=x86_64 ;; *) ARCH="$(uname -m)" ;; esac
EXESUF=""; [ "$OS" = windows ] && EXESUF=".exe"
# the one translator for paths handed to a NATIVE program (a no-op off Windows)
. "$REPO/tests/lib/native_path.sh"
OSARCH="$OS-$ARCH"
FB="$ROOT/fbneo/$OSARCH"; MM="$ROOT/mame/$OSARCH"
[ -f "$FB/BINARY.txt" ] || { echo "SKIP: no $FB/BINARY.txt for this host (tools/build_release_emulators.sh fbneo)"; exit 0; }
[ -f "$MM/BINARY.txt" ] || { echo "SKIP: no $MM/BINARY.txt for this host (tools/build_release_emulators.sh mame)"; exit 0; }
# A SKIP THAT DOES NOT SAY WHAT TO DO IS A DEAD END (2026-09-12, the first
# Windows session). The DEFAULT names a build directory, which exists only on a
# host that runs the build pipeline; a release host has no such thing and gets
# the romset from the published applier in about a minute. Name that route here,
# because this line is where a reader finds out they need it.
if [ ! -f "$MERGED/rompath/vsavjw.zip" ]; then
    echo "SKIP: no romset at $MERGED/rompath/vsavjw.zip — the gate BOOTS the set on each binary."
    echo "      This tree ships no ROM data, ever: build it from YOUR dumps with the published"
    echo "      applier (pure Python, no build pipeline, about a minute), then point the gate at it:"
    _rel="$(ls -d release/merged-m*/ 2>/dev/null | sort -V | tail -1)"; _rel="${_rel%/}"
    echo "        mkdir -p build/fromrelease/rompath"
    echo "        python3 ${_rel:-release/<name>}/fbneo/apply_release.py --romdir \"\$ROMDIR\" --out build/fromrelease/rompath"
    echo "        ROMDIR=... MERGED=build/fromrelease tests/test_release_binaries.sh"
    exit 0
fi
# the records are tracked, the files are RELEASE ASSETS (ruled 14z-149): a record with no file
# beside it means this host has neither built nor fetched them — not measured, so SKIP (red
# under --strict, which is right: a release host must have them)
for d in "$FB" "$MM"; do
    [ "$(ls "$d" | grep -vc '^BINARY.txt$')" != 0 ] \
        || { echo "SKIP: $d holds the record only — build (tools/build_release_emulators.sh) or fetch the release asset"; exit 0; }
done
TIMEOUT="$(command -v gtimeout || command -v timeout || true)"
[ -n "$TIMEOUT" ] || { echo "FAIL: no timeout(1) (brew install coreutils)"; exit 1; }
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT INT TERM
fail=0
sha256_of() {
    if command -v shasum >/dev/null 2>&1; then shasum -a 256 "$1" | cut -c1-64
    elif command -v sha256sum >/dev/null 2>&1; then sha256sum "$1" | cut -c1-64
    else echo "no shasum(1) or sha256sum(1)" >&2; return 1; fi
}

# ---- the two perturbations, ONE function each (the control section and the mode both call them)
perturb_flip() {  # flip one byte of the first bundled library
    python3 - "$1" <<'PY'
import sys, os, glob
d = sys.argv[1]
libs = sorted(glob.glob(os.path.join(d, "*.dylib")) + glob.glob(os.path.join(d, "*.so*"))
              + glob.glob(os.path.join(d, "*.dll")) + glob.glob(os.path.join(d, "*.DLL")))
if not libs:
    sys.exit("perturb_flip: no bundled library in " + d)
p = libs[0]; b = bytearray(open(p, "rb").read()); b[len(b)//2] ^= 0x01; open(p, "wb").write(b)
PY
}
perturb_absref() {  # a reference that does NOT resolve inside the directory, with
    # the record left CONSISTENT so the record check passes and the
    # self-containment check is the only thing that can catch it. The CLAIM is
    # one; the mechanism is what each OS makes possible.
    d="$1"; exe="$2"
    if [ "$OS" != macos ]; then
        # Linux/Windows: one bundled library REMOVED together with its sha256
        # row. Inventory and record stay consistent, so only a RESOLUTION check
        # can see that the binary now needs something the directory lacks.
        victim="$(ls "$d" | grep -E '[.](so[.0-9]*|dll|DLL)$' | head -1)"
        [ -n "$victim" ] || { echo "perturb_absref: no bundled library in $d"; return 1; }
        rm -f "$d/$victim"
        grep -v " $victim\$" "$d/BINARY.txt" > "$d/BINARY.new" && mv "$d/BINARY.new" "$d/BINARY.txt"
        return 0
    fi
    ref="$(otool -L "$d/$exe" | awk 'NR>1 && $1 ~ /^@loader_path\//{print $1; exit}')"
    [ -n "$ref" ] || { echo "perturb_absref: $exe has no @loader_path reference"; return 1; }
    install_name_tool -change "$ref" "/opt/homebrew/lib/$(basename "$ref")" "$d/$exe" 2>/dev/null
    codesign -s - -f "$d/$exe" 2>/dev/null
    new="$(sha256_of "$d/$exe")"
    python3 - "$d/BINARY.txt" "$exe" "$new" <<'PY'
import sys, re
p, exe, new = sys.argv[1:]
t = open(p).read()
t = re.sub(r"^(sha256 +)[0-9a-f]{64}( +%s)$" % re.escape(exe), r"\g<1>%s\2" % new, t, flags=re.M)
open(p, "w").write(t)
PY
}
cp -R "$FB" "$W/fb_flip";   perturb_flip "$W/fb_flip"
cp -R "$MM" "$W/mm_absref"; perturb_absref "$W/mm_absref" "cps2$EXESUF"
vs_ctl_is flipped-library-byte && FB="$W/fb_flip"
vs_ctl_is absolute-reference && MM="$W/mm_absref"
FB="$(cd "$FB" && pwd)"; MM="$(cd "$MM" && pwd)"   # absolute: the boot legs cd elsewhere

# ---- check_dir <dir> <exe>: record, self-containment, signature. Prints FAIL lines; returns 1 on any.
check_dir() {
    d="$1"; exe="$2"; bad=0
    grep -E '^sha256 +[0-9a-f]{64} +[^ ]+' "$d/BINARY.txt" > "$W/rows.txt" || true
    [ -s "$W/rows.txt" ] || { echo "FAIL: $d/BINARY.txt has no sha256 rows"; return 1; }
    while read -r _ want fname; do
        got="$(sha256_of "$d/$fname" 2>/dev/null || true)"
        [ "$got" = "$want" ] || { echo "FAIL: $d/$fname sha256 ${got:-<missing>} != record ${want}"; bad=1; }
    done < "$W/rows.txt"
    for f in "$d"/*; do
        case "$(basename "$f")" in BINARY.txt) ;; *)
            grep -q " $(basename "$f")\$" "$W/rows.txt" || { echo "FAIL: $f is not named by BINARY.txt"; bad=1; } ;;
        esac
    done
    grep -q "^sha256 .* $exe\$" "$W/rows.txt" || { echo "FAIL: $d/BINARY.txt does not name the executable $exe"; bad=1; }
    for k in pin patch recipe requires run; do
        grep -q "^$k " "$d/BINARY.txt" || { echo "FAIL: $d/BINARY.txt lacks the '$k' line"; bad=1; }
    done
    case "$OS" in
    macos)
        for f in "$d"/*; do
            case "$(basename "$f")" in BINARY.txt) continue ;; esac
            otool -L "$f" 2>/dev/null | awk 'NR>1{print $1}' | while read -r ref; do
                case "$ref" in /usr/lib/*|/System/*|@loader_path/*|"$(basename "$f")") ;;
                *) echo "FAIL: $(basename "$f") references $ref (not bundled: absolute or non-system)" ;;
                esac
            done > "$W/refs.txt"
            [ -s "$W/refs.txt" ] && { cat "$W/refs.txt"; bad=1; }
            codesign --verify --strict "$f" 2>/dev/null || { echo "FAIL: $f does not verify (codesign)"; bad=1; }
        done ;;
    linux)
        # ldd honours the file's own RUNPATH, so this is what the loader will
        # actually do on a machine with none of the build host's packages:
        # every resolved path must be INSIDE this directory or a system path,
        # and nothing may be "not found".
        command -v ldd >/dev/null 2>&1 || { echo "FAIL: no ldd(1) on this host — cannot check self-containment"; return 1; }
        for f in "$d"/*; do
            case "$(basename "$f")" in BINARY.txt) continue ;; esac
            head -c 4 "$f" 2>/dev/null | grep -q 'ELF' || continue
            ldd "$f" 2>/dev/null | python3 -c '
import sys, os
d = os.path.realpath(sys.argv[1]); name = sys.argv[2]
SYS = ("/lib/", "/lib64/", "/usr/lib/", "/usr/lib64/", "/usr/local/lib/")
for line in sys.stdin:
    line = line.strip()
    if "=>" not in line:
        continue
    soname, right = (x.strip() for x in line.split("=>", 1))
    if right.startswith("not found"):
        print(f"FAIL: {name} needs {soname}, NOT FOUND — the directory is not self-contained")
        continue
    path = right.rsplit(" (0x", 1)[0].strip()
    if not path:
        continue
    real = os.path.realpath(path)
    if os.path.dirname(real) == d:
        continue                      # beside the binary: what $ORIGIN is for
    if real.startswith(SYS):
        continue                      # the host runtime, deliberately not bundled
    print(f"FAIL: {name} resolves {soname} to {path}, outside this directory and outside the system paths")
' "$d" "$(basename "$f")" > "$W/refs.txt"
            [ -s "$W/refs.txt" ] && { cat "$W/refs.txt"; bad=1; }
        done
        echo "  (linux: no code signature exists on this platform — the sha256 rows above are the integrity)" ;;
    windows)
        command -v ldd >/dev/null 2>&1 || { echo "FAIL: no ldd(1) in this shell — run the gate from an MSYS2 MINGW64/UCRT64 shell"; return 1; }
        for f in "$d"/*; do
            case "$(basename "$f")" in BINARY.txt) continue ;; esac
            head -c 2 "$f" 2>/dev/null | grep -q 'MZ' || continue
            ldd "$f" 2>/dev/null | python3 -c '
import sys, os, re
d = os.path.realpath(sys.argv[1]); name = sys.argv[2]
WIN = re.compile(r"^(?:[a-zA-Z]:/|/[a-zA-Z]/)?(?:WINDOWS|WinNT)/", re.I)
for line in sys.stdin:
    line = line.strip()
    if "=>" not in line:
        continue
    dll, right = (x.strip() for x in line.split("=>", 1))
    if dll == "???":
        continue
    if right.startswith("not found"):
        print(f"FAIL: {name} imports {dll}, NOT FOUND — the folder is not self-contained")
        continue
    path = right.rsplit(" (0x", 1)[0].strip()
    if not path or path == "???":
        continue
    if os.path.dirname(os.path.realpath(path)) == d:
        continue                      # beside the .exe: where the loader looks first
    if WIN.match(path.replace("\\", "/").lstrip()):
        continue                      # Windows itself
    print(f"FAIL: {name} resolves {dll} to {path}, outside this folder and outside Windows")
' "$d" "$(basename "$f")" > "$W/refs.txt"
            [ -s "$W/refs.txt" ] && { cat "$W/refs.txt"; bad=1; }
        done
        echo "  (windows: no code signature exists on this platform — the sha256 rows above are the integrity)" ;;
    *)
        echo "FAIL: the self-containment check is implemented for macOS, Linux and Windows — add this OS's ($OS) before trusting a $OSARCH prebuilt"
        bad=1 ;;
    esac
    return $bad
}

# ---- section 1: FBNeo
echo "== 1. fbneo $FB"
check_dir "$FB" "fbneo$EXESUF" || fail=1
strings -a "$FB/fbneo$EXESUF" | grep -q "CPS-2 WIDE v1" || { echo "FAIL: fbneo does not carry the profile"; fail=1; }
! strings -a "$FB/fbneo$EXESUF" | grep -q -- "-hframes" || { echo "FAIL: fbneo carries the replay HARNESS (patch 0001) — a test instrument shipped"; fail=1; }
mkdir -p "$W/play/roms" "$W/home"
# A SYMLINK IS NOT A FILE TO A NATIVE PROGRAM. On MSYS2 an `ln -s` is an MSYS
# construct the Windows loader and a native FBNeo cannot follow, so the set
# would read as missing; everywhere else a link is free and a copy is 40 MB.
for z in "$ROMDIR"/*.zip "$REPO/$MERGED/rompath"/*.zip; do
    if [ "$VS_NATIVE" = 1 ]; then cp -f "$z" "$W/play/roms/$(basename "$z")"
    else ln -sf "$z" "$W/play/roms/$(basename "$z")"; fi
done
rc=0
( cd "$W/play" && HOME="$W/home" SDL_VIDEODRIVER=dummy SDL_AUDIODRIVER=dummy \
    "$TIMEOUT" 20 "$FB/fbneo$EXESUF" vsavjw > "$W/fb_boot.log" 2>&1 ) || rc=$?
oks="$(grep -c '(OK)' "$W/fb_boot.log" || true)"
if [ "$rc" != 124 ]; then echo "FAIL: fbneo exited rc=$rc within 20 s (expected to be still running):"; tail -5 "$W/fb_boot.log"; fail=1; fi
grep -q "CPS-2 WIDE v1 profile active" "$W/fb_boot.log" || { echo "FAIL: fbneo boot log lacks 'CPS-2 WIDE v1 profile active'"; fail=1; }
[ "$oks" = 31 ] || { echo "FAIL: fbneo loaded $oks members (OK), expected 31"; fail=1; }
! grep -qi 'not found\|error' "$W/fb_boot.log" || { echo "FAIL: fbneo boot log carries an error:"; grep -i 'not found\|error' "$W/fb_boot.log" | head -3; fail=1; }
[ "$fail" = 0 ] && echo "  ok: record, self-contained, signed, profile, no harness; booted vsavjw headless (31 (OK), running at 20 s)"

# ---- section 2: MAME
echo "== 2. mame $MM"
f2=0
check_dir "$MM" "cps2$EXESUF" || f2=1
"$MM/cps2$EXESUF" -listfull vsavjw 2>/dev/null | grep -q vsavjw || { echo "FAIL: cps2 does not know vsavjw"; f2=1; }
# -verifyroms can never say "is good" on a WIDE content set: the descriptor carries the
# STOCK CRCs for the members the port rewrites and SENTINELS for the new ones ([VSP-75]),
# so the honest expectation is: exactly the members vsavjw.zip ships that are NOT
# byte-identical to a pristine twin are flagged INCORRECT CHECKSUM, and nothing is NOT
# FOUND (measured 14z-149; the shipped
# recipe's "must say good" line was false since the first content build).
"$MM/cps2$EXESUF" -verifyroms vsavjw -rompath "$(native_pathlist "$REPO/$MERGED/rompath;$ROMDIR")" > "$W/verify.log" 2>&1 || true
python3 - "$W/verify.log" "$MERGED/rompath/vsavjw.zip" "$ROMDIR/vsavj.zip" "$ROMDIR/vsav.zip" <<'PY' || f2=1
import sys, re, zipfile
log, z, *pristine = sys.argv[1:]
text = open(log, errors="replace").read()
flagged = set(re.findall(r"^vsavjw\s*:\s*(\S+) .* - INCORRECT CHECKSUM", text, re.M))
other = [l for l in text.splitlines() if l.startswith("vsavjw") and "INCORRECT CHECKSUM" not in l]
twins = {}
for pz in pristine:
    for i in zipfile.ZipFile(pz).infolist(): twins.setdefault(i.filename, i.CRC)
# expected flagged: every member the WIDE zip ships that is NOT byte-identical to a pristine twin
expect = {i.filename for i in zipfile.ZipFile(z).infolist() if twins.get(i.filename) != i.CRC}
ok = True
if other: print("FAIL: -verifyroms reports something other than a checksum mismatch:", *other[:3], sep="\n  "); ok = False
if flagged != expect:
    print(f"FAIL: -verifyroms flagged {sorted(flagged - expect)} unexpectedly / missed {sorted(expect - flagged)}"); ok = False
if not re.search(r"^romset vsavjw \[vsav\] is bad", text, re.M): print("FAIL: no 'romset vsavjw [vsav] is bad' summary line"); ok = False
print(f"  -verifyroms: {len(flagged)} members flagged = exactly the WIDE zip's {len(expect)} rewritten/new members, none NOT FOUND")
sys.exit(0 if ok else 1)
PY
if [ "$f2" = 0 ]; then
    MAME_BIN="$MM/cps2$EXESUF" MAME_ROMPATH="$REPO/$MERGED/rompath;$ROMDIR" SUITE_ONLY=05_timeout_idle \
        tests/run_suite.sh vsavjw > "$W/suite.log" 2>&1 || true
    n="$(grep -c 'PASS masked-\|PASS$' "$W/suite.log" || true)"
    if ! grep -q "SUITE GREEN" "$W/suite.log" || [ "$n" != 1 ]; then
        echo "FAIL: the release MAME did not reproduce 05_timeout_idle's frozen expectation:"; tail -6 "$W/suite.log"; f2=1
    fi
fi
[ "$f2" = 0 ] && echo "  ok: record, self-contained, signed, knows vsavjw, -verifyroms flags exactly the WIDE members, reproduced 05_timeout_idle's frozen masked expectation"
[ "$f2" = 0 ] || fail=1

# ---- must-fire controls: the two perturbed copies must FAIL check_dir
if check_dir "$W/fb_flip" "fbneo$EXESUF" > "$W/c1.txt" 2>&1; then
    vs_ctl_dead flipped-library-byte "a flipped library byte passed the record check"; fail=1
else
    vs_ctl_fired flipped-library-byte "$(grep -c '^FAIL' "$W/c1.txt") FAIL line(s), first: $(grep -m1 '^FAIL' "$W/c1.txt")"
fi
if check_dir "$W/mm_absref" "cps2$EXESUF" > "$W/c2.txt" 2>&1; then
    vs_ctl_dead absolute-reference "an absolute install name passed the self-containment check"; fail=1
else
    if grep -qE 'references /opt/homebrew|NOT FOUND|outside this (directory|folder)' "$W/c2.txt"; then
        vs_ctl_fired absolute-reference "$(grep -m1 -E 'references /opt/homebrew|NOT FOUND|outside this' "$W/c2.txt")"
    else
        vs_ctl_dead absolute-reference "check_dir failed for another reason: $(grep -m1 '^FAIL' "$W/c2.txt")"; fail=1
    fi
fi

[ "$fail" = 0 ] && echo "PASS: test_release_binaries ($OSARCH)" || { echo "FAIL: test_release_binaries ($OSARCH)"; exit 1; }
