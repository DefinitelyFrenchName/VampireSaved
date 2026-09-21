#!/bin/sh
# test_release_binaries.sh — the PREBUILT emulator binaries for THIS host under
# release/emulators/{fbneo,mame}/<os-arch>/ (the build resource every release's
# emulator/bin/<os-arch>/ is hash-verified from; maintainer-ruled 2026-09-11:
# recipe AND prebuilt) are what their BINARY.txt says (sha256 per file, every
# file named), SELF-CONTAINED (no absolute non-system library reference —
# bundled as @loader_path), SIGNED (codesign --verify), carry the profile, and
# BOOT the current merged romset: FBNeo headless under the SDL dummy drivers for
# 20 s (every vsavjw member "(OK)", the profile line wherever FBNeo prints the
# emulator core's messages — never on Windows — still running when killed); MAME
# `-verifyroms vsavjw` flags EXACTLY the WIDE zip's rewritten/new members (it can never say
# "good" on a content set: stock CRCs for rewritten members, sentinels for new ones,
# [VSP-75]) AND one frozen masked legacy expectation of the
# current freeze REPRODUCED by the release binary (run_suite, SUITE_ONLY). So a
# shipped binary is proven to be the same instrument the gates ran, not a
# recipe believed equivalent. mame + fbneo, ~2 min.
#
# AND SINCE 2026-09-20, SECTION 3: the SHIPPED release directory applied to the pristine
# dumps must yield a STANDALONE romset — one zip, no parent, no QSound BIOS zip — that is
# (3a) COMPLETE by the emulator's own descriptor, `-verifyroms` against that set alone
# reporting no NOT FOUND and the same flagged set as the build arrangement; and
# behaviourally identical to the gated build on (3b) MAME and (3c) FBNeo, in whole-RAM
# checksums AND per-frame framebuffer checksums. 3a is the leg that does not read the
# packager's `standalone_completion` declaration, so it is what can catch an omitted or
# wrong completion member — the three QSound members included, which neither stream sees.
# 3c uses the HARNESS FBNeo build, not the release binary, which carries no harness by
# design. 3d then holds the SECOND, `--no-qsound-bios` variant to the three properties the
# MiSTer README tells players to rely on: MAME refuses it, FBNeo runs it identically, and
# the WIDE MRA resolves every part with the BIOS one coming from the card's qsound.zip.
# ~11 min with section 3.
#
# MUST-FIRE: perturbed-copy: flipped-library-byte — a copy of the fbneo resource dir with one byte of a bundled library flipped must fail the record check (mode: the gate checks that copy in place of the resource)
# MUST-FIRE: perturbed-copy: standalone-audio-member-content — the applied STANDALONE set with a QSound completion member (vm3.11m) carrying another sample member's bytes must be caught by section 3a's `-verifyroms` completeness check; NEITHER compared stream can see an audio member (3 of the 7 completion members are QSound), so without 3a this failure mode is uncovered — which is also why 3a's expectation comes from the emulator's descriptor and not from the packager's own `standalone_completion` declaration (fires in-gate after 3a-3c pass)
# MUST-FIRE: perturbed-copy: standalone-member-content — the applied STANDALONE set with one completion member (vm3.14m) carrying another gfx member's bytes — same name, same size, so it still loads — must diverge from the build arrangement; measured 2026-09-20, work RAM is UNMOVED by that and only the framebuffer shows it (the 14z-60z class), so this is what makes section 3's VIDEO_OUT half load-bearing rather than decorative (fires in-gate after 3a-3c pass)
# MUST-FIRE: perturbed-copy: absolute-reference — a copy of the mame resource dir carrying a reference that does NOT resolve inside the directory, with the record made consistent so the record check PASSES, must fail the self-containment check (macOS: one install name rewritten back to an absolute Homebrew path, re-signed and re-hashed; Linux/Windows: one bundled library removed together with its sha256 row, so the folder now needs it from outside — Linux: tools/check_host_libs.py fails it as on no host-provided list; Windows: ldd resolves it outside the folder) (mode: the gate checks that copy)
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
#   Linux    tools/check_host_libs.py: every file's direct NEEDED soname is
#            shipped here AND resolves here (RUNPATH=$ORIGIN), or is on the
#            EXTERNAL host-provided list tests/expected/linux_host_provided.tsv;
#            nothing "not found". (A path check is blind on a build host, where
#            every bundled library also lives under /usr/lib — see the block.)
#   Windows  ldd/objdump: every import resolves beside the .exe or to the
#            Windows directory. There is NO signature on this platform, so the
#            record's sha256 rows are the integrity and the gate says so
#            instead of asserting a signature that cannot exist.
# An OS this gate does not know still FAILS, naming what must be added — never
# a silent pass.
#
# Usage: ROMDIR=... [MERGED=build/m3b_merged27] [RELEASE_EMULATORS=release/emulators]
#        tests/test_release_binaries.sh
#   defaults build/m3b_merged27 (M19, the current freeze). SKIPs when no resource
#   dir exists for this host's os-arch (tools/build_release_emulators.sh builds one).
set -eu
ROMDIR="${ROMDIR:?set ROMDIR}"
REPO="$(cd "$(dirname "$0")/.." && pwd)"; cd "$REPO"
ROMDIR="$(cd "$ROMDIR" && pwd)"
. "$REPO/tests/lib/controls.sh"; vs_ctl_mode "$0"
MERGED="${MERGED:-build/m3b_merged27}"
ROOT="${RELEASE_EMULATORS:-release/emulators}"
# The os-arch spelling MUST match tools/build_release_emulators.sh's, or this
# gate looks in a directory that builder never wrote (and SKIPs, reading as
# "nothing to check" instead of "wrong name").
#
# THE VARIABLE IS `HOSTOS`, NEVER `OS` (2026-09-13, found while reading this gate
# after its first Windows run). `OS` is Windows's own EXPORTED `Windows_NT`, a
# POSIX assignment keeps the export, so `OS=windows` here reached every program
# the gate launches, fbneo.exe and cps2.exe included. It broke nothing on that
# run; it is the collision the builder paid for first, and its header tells it
# in full (tools/build_release_emulators.sh).
case "$(uname -s)" in
Darwin) HOSTOS=macos ;;
Linux)  HOSTOS=linux ;;
MINGW*|MSYS*|CYGWIN*) HOSTOS=windows ;;
*) HOSTOS="$(uname -s | tr 'A-Z' 'a-z')" ;;
esac
case "$(uname -m)" in arm64|aarch64) ARCH=arm64 ;; x86_64|amd64) ARCH=x86_64 ;; *) ARCH="$(uname -m)" ;; esac
EXESUF=""; [ "$HOSTOS" = windows ] && EXESUF=".exe"
# what an `ok:` line may claim about signing: only macOS has a signature this gate
# verifies (2026-09-13 — the first Windows pass printed "signed" directly under its
# own "no code signature exists on this platform" note)
SIGNED="signed"; [ "$HOSTOS" = macos ] || SIGNED="unsigned (no signature exists on $HOSTOS)"
# the one translator for paths handed to a NATIVE program (a no-op off Windows)
. "$REPO/tests/lib/native_path.sh"
# what a healthy FBNeo WIDE boot log must show — ONE copy, ground-truthed over the
# recorded macOS and Windows logs by tests/test_fbneo_boot_log.sh
. "$REPO/tests/lib/fbneo_boot_log.sh"
OSARCH="$HOSTOS-$ARCH"
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
    if [ "$HOSTOS" != macos ]; then
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
# WHICH DIRECTORY EACH CONTROL PERTURBS IS A PROPERTY OF THE HOST, not a
# constant (2026-09-13, the first Windows run of this gate). Both
# perturbations need a BUNDLED LIBRARY to work on, and MAME's Windows build
# links `-static` (its `scripts/genie.lua`, configuration mingw*), so
# `release/emulators/mame/windows-x86_64/` holds the .exe and its record and
# nothing else. Pinning the control to MAME made the gate exit at this line,
# before it asserted anything at all.
#
# THE CLAIM IS UNCHANGED — a reference that does not resolve inside the
# directory must fail the self-containment check — and it is provable on
# whichever directory actually bundles something. So the subject is CHOSEN:
# MAME where it bundles (macOS, Linux), FBNeo where MAME does not (Windows).
# A host where NEITHER bundles cannot prove the property at all, and says so
# as a DEAD control rather than passing quietly ([VSP-181]).
bundles() { ls "$1" 2>/dev/null | grep -qE '[.](so[.0-9]*|dll|DLL|dylib)$'; }
ABSREF_SRC=""; ABSREF_EXE=""; ABSREF_KIND=""
if bundles "$MM"; then ABSREF_SRC="$MM"; ABSREF_EXE="cps2$EXESUF"; ABSREF_KIND=mame
elif bundles "$FB"; then ABSREF_SRC="$FB"; ABSREF_EXE="fbneo$EXESUF"; ABSREF_KIND=fbneo
fi
# The flip control has the SAME dependency on something being bundled, and the
# same answer: FBNeo bundles on all three OSes today, so it is the default and
# MAME the fallback — but a static FBNeo would make this dead rather than
# abort the gate before it asserts anything.
FLIP_SRC=""; FLIP_EXE=""; FLIP_KIND=""
if bundles "$FB"; then FLIP_SRC="$FB"; FLIP_EXE="fbneo$EXESUF"; FLIP_KIND=fbneo
elif bundles "$MM"; then FLIP_SRC="$MM"; FLIP_EXE="cps2$EXESUF"; FLIP_KIND=mame
fi
if [ -n "$FLIP_SRC" ]; then
    cp -R "$FLIP_SRC" "$W/fb_flip"
    perturb_flip "$W/fb_flip" || FLIP_SRC=""
fi
if [ -n "$ABSREF_SRC" ]; then
    cp -R "$ABSREF_SRC" "$W/absref"
    perturb_absref "$W/absref" "$ABSREF_EXE" || ABSREF_SRC=""
fi
if vs_ctl_is flipped-library-byte; then
    [ -n "$FLIP_SRC" ] || { echo "REFUSED: CONTROL=flipped-library-byte — no directory on this host bundles a library to flip"; exit 3; }
    if [ "$FLIP_KIND" = fbneo ]; then FB="$W/fb_flip"; else MM="$W/fb_flip"; fi
fi
if vs_ctl_is absolute-reference; then
    [ -n "$ABSREF_SRC" ] || { echo "REFUSED: CONTROL=absolute-reference — no directory on this host bundles a library to perturb"; exit 3; }
    if [ "$ABSREF_KIND" = mame ]; then MM="$W/absref"; else FB="$W/absref"; fi
fi
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
    case "$HOSTOS" in
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
        # NOT A PATH CHECK (2026-09-13, the first Linux run of this gate). This block
        # accepted any library resolved under /usr/lib as "host runtime", and on a
        # build host every bundled library also lives there (measured 18 of 18 in
        # the MAME folder, 17 of 17 in FBNeo's), so the absolute-reference control
        # removed libSDL2 and PASSED. The anchor the maintainer ruled: every file's
        # DIRECT NEEDED sonames are shipped here and resolve here, or are on
        # tests/expected/linux_host_provided.tsv — an EXTERNAL list (manylinux_2_39)
        # plus exceptions ruled one by one, never the bundler's own policy
        # ([VSP-166]). One copy of the rule: tools/check_host_libs.py, ground truth
        # tests/test_host_libs.sh.
        command -v ldd >/dev/null 2>&1 && command -v readelf >/dev/null 2>&1 \
            || { echo "FAIL: no ldd(1) or readelf(1) on this host — cannot check self-containment"; return 1; }
        if python3 "$REPO/tools/check_host_libs.py" "$d" "$REPO/tests/expected/linux_host_provided.tsv" > "$W/refs.txt" 2>&1; then
            sed 's/^/  /' "$W/refs.txt"
        else
            grep -v '^ok:' "$W/refs.txt" | sed 's/^REFUSED:/FAIL: check_host_libs REFUSED:/'; bad=1
        fi
        echo "  (linux: no code signature exists on this platform — the sha256 rows above are the integrity)" ;;
    windows)
        command -v ldd >/dev/null 2>&1 || { echo "FAIL: no ldd(1) in this shell — run the gate from an MSYS2 MINGW64/UCRT64 shell"; return 1; }
        for f in "$d"/*; do
            case "$(basename "$f")" in BINARY.txt) continue ;; esac
            head -c 2 "$f" 2>/dev/null | grep -q 'MZ' || continue
            ldd "$f" 2>/dev/null | python3 -c '
import sys, os, re, subprocess
sys.stdout.reconfigure(encoding="utf-8", newline="\n")   # native Windows python pipes cp1252 + CRLF (tests/lib/fbneo_boot_log.sh)
# BOTH SIDES IN ONE NAMESPACE (2026-09-13, the first Windows run of this
# check: every resolved path was reported "outside this folder" while sitting
# inside it). `ldd` answers in MSYS form and this python is a NATIVE Windows
# program, so comparing its `realpath` of one against the other compares two
# different namespaces. cygpath is MSYS2s own translator; the result is cached
# because a closure asks about the same handful of directories many times.
_cache = {}
def nat(p):
    if not p.startswith("/"):
        return os.path.realpath(p)
    if p not in _cache:
        try:
            _cache[p] = subprocess.run(["cygpath", "-m", p], capture_output=True,
                                       text=True).stdout.strip() or p
        except OSError:
            _cache[p] = p
    return os.path.realpath(_cache[p])
d = nat(sys.argv[1]); name = sys.argv[2]
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
    if os.path.dirname(nat(path)) == d:
        continue                      # beside the .exe: where the loader looks first
    if WIN.match(path.replace("\\", "/").lstrip()):
        continue                      # Windows itself
    print(f"FAIL: {name} resolves {dll} to {path}, outside this folder and outside Windows")
' "$d" "$(basename "$f")" > "$W/refs.txt"
            [ -s "$W/refs.txt" ] && { cat "$W/refs.txt"; bad=1; }
        done
        echo "  (windows: no code signature exists on this platform — the sha256 rows above are the integrity)" ;;
    *)
        echo "FAIL: the self-containment check is implemented for macOS, Linux and Windows — add this OS's ($HOSTOS) before trusting a $OSARCH prebuilt"
        bad=1 ;;
    esac
    return $bad
}

# ---- section 1: FBNeo
echo "== 1. fbneo $FB"
check_dir "$FB" "fbneo$EXESUF" || fail=1
# the FULL message (2026-09-13): `CPS-2 WIDE v1` alone is also in the driver's long
# name, so it could not tell a binary built without Cps2WideInit from one built with it
strings -a "$FB/fbneo$EXESUF" | grep -q "CPS-2 WIDE v1 profile active" || { echo "FAIL: fbneo does not carry the profile (no 'CPS-2 WIDE v1 profile active' in the binary)"; fail=1; }
! strings -a "$FB/fbneo$EXESUF" | grep -q -- "-hframes" || { echo "FAIL: fbneo carries the replay HARNESS (patch 0001) — a test instrument shipped"; fail=1; }
# NEVER RUN THE ARTIFACT IN PLACE (2026-09-13, the first Windows run: the boot
# left `config/ recordings/ roms/ savestates/ screenshots/` INSIDE
# release/emulators/fbneo/windows-x86_64/, and the next run's record check
# flagged all five as files BINARY.txt does not name — the gate polluting the
# thing it measures). The emulator runs from a COPY, and the copy is where its
# droppings go.
#
# AND FBNeo RESOLVES `roms/` AGAINST ITS OWN DIRECTORY on Windows, not against
# the working directory: that is why the set was invisible to it and why it
# created an empty `roms/` of its own. Staging the zips INSIDE the copy serves
# both facts at once.
PLAY="$W/play"; mkdir -p "$PLAY" "$W/home"
cp -R "$FB"/* "$PLAY/" 2>/dev/null || true
mkdir -p "$PLAY/roms"
for z in "$ROMDIR"/*.zip "$REPO/$MERGED/rompath"/*.zip; do
    # a symlink is not a file to a native program: an MSYS `ln -s` is a construct
    # the Windows loader cannot follow, so the set would read as missing there
    if [ "$VS_NATIVE" = 1 ]; then cp -f "$z" "$PLAY/roms/$(basename "$z")"
    else ln -sf "$z" "$PLAY/roms/$(basename "$z")"; fi
done
rc=0
( cd "$PLAY" && HOME="$W/home" SDL_VIDEODRIVER=dummy SDL_AUDIODRIVER=dummy \
    "$TIMEOUT" 20 "./fbneo$EXESUF" vsavjw > "$W/fb_boot.log" 2>&1 ) || rc=$?
if [ "$rc" != 124 ]; then echo "FAIL: fbneo exited rc=$rc within 20 s (expected to be still running):"; tail -5 "$W/fb_boot.log"; fail=1; fi
# WHATEVER THE VERDICT, KEEP THE BOOT LOG READABLE: this ran on a host nobody
# here has, and a red without its log is a dead end — the kept log is what
# showed, on 2026-09-13, that the Windows boot was CORRECT and the check was not.
cp "$W/fb_boot.log" "$REPO/build/fbneo_boot_$HOSTOS.log" 2>/dev/null || true
# THE LOG'S VERDICT is tests/lib/fbneo_boot_log.sh: every vsavjw member loaded
# (OK) — which only the WIDE init performs — and the profile line wherever the
# emulator core's messages reach the log at all. They never do on Windows
# (FBNeo's SDL frontend connects the core's message function only off
# SDL_WINDOWS), so a check keyed on that one line went red there on a correct boot.
vs_fbneo_boot_log "$W/fb_boot.log" "$HOSTOS" "$REPO/emu/fbneo-patches/0002-cps2-wide-v1.patch" || fail=1
# THE RATIFIED 0003 DECISION, LOCKED (2026-09-21). Patch 0003 drops the SDL2_image link
# so a macOS FBNeo bundle is 4 files instead of 24. What that costs a player using the
# System Settings route follows only if macOS asks once per blocked file — inferred from
# MAME's measured 2-file/2-approval case, never exercised at 24 or 4 (#144). This gate
# asserts the FILE COUNT, which is what it can see. Nothing else would
# notice it silently coming back: the record check only asserts that the files PRESENT
# match their hashes, so a bundle that regrew to 24 would still pass. This asserts the
# decision itself — no image codec may reappear beside the FBNeo binary.
if [ -n "${FB:-}" ] && [ -d "$FB" ]; then
    codecs="$(ls "$FB" 2>/dev/null | grep -icE 'SDL2_image|libaom|libavif|libbrotli|libdav1d|libhwy|libjpeg|libjxl|liblcms|liblzma|libpng|libsharpyuv|libtiff|libvmaf|libwebp|libzstd' || true)"
    if [ "${codecs:-0}" != 0 ]; then
        echo "FAIL: $codecs image-codec librar(ies) are back in the fbneo bundle — patch 0003 is not being applied"
        ls "$FB" | grep -iE 'SDL2_image|libaom|libavif|libbrotli|libdav1d|libhwy|libjpeg|libjxl|liblcms|liblzma|libpng|libsharpyuv|libtiff|libvmaf|libwebp|libzstd' | sed 's/^/        /'
        fail=1
    else
        echo "  ok: no image codec beside the fbneo binary — the ratified 0003 decision holds ($(ls "$FB" | grep -vc '^BINARY.txt$') files)"
    fi
fi

[ "$fail" = 0 ] && echo "  ok: record, self-contained, $SIGNED, profile, no harness; booted vsavjw headless (every descriptor member (OK), running at 20 s)"

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
# ONE function, two callers (this leg and section 3's standalone leg), so the standalone
# set is held to exactly the check the build arrangement is held to. The expectation is
# computed from the EMULATOR'S OWN descriptor plus the pristine dumps and NEVER from the
# packager's `standalone_completion` declaration: that independence is the whole point,
# because it is what catches a completion member that is MISSING (a NOT FOUND line) or
# that carries WRONG CONTENT (an extra INCORRECT CHECKSUM), for a QSound member as
# readily as for a gfx one, without inheriting the derivation under test.
verify_check() {   # verify_check <verifyroms log> <the vsavjw.zip it ran against> <label>
    # EVERY reference zip the set can draw a pristine member from must be in the twin
    # list, or a correct member with no twin is counted as "expected flagged" and the
    # check fails on its own arithmetic. qsound_hle.zip joined it on 2026-09-20 with the
    # standalone completion, whose dl-1425.bin comes from there — caught by this gate on
    # its first run ("missed ['dl-1425.bin']"). Adding the twin STRENGTHENS the check: the
    # member is now expected UNFLAGGED, so wrong content in it fails here.
    python3 - "$1" "$2" "$ROMDIR/vsavj.zip" "$ROMDIR/vsav.zip" "$ROMDIR/qsound_hle.zip" "$3" <<'PYV'
import sys, re, zipfile
# THE LAST CR OF THE WINDOWS OUTPUT (14z-153): this block prints the gate's one PASS
# line from Python, and a NATIVE Windows python writes "\r\n" for "\n" — the one CR
# byte left in the MSYS2 output after 14z-152 reconfigured the other block (above).
sys.stdout.reconfigure(encoding="utf-8", newline="\n")
log, z, p1, p2, p3, label = sys.argv[1:7]
pristine = [p1, p2, p3]
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
print(f"  -verifyroms{label}: {len(flagged)} members flagged = exactly the WIDE zip's {len(expect)} rewritten/new members, none NOT FOUND")
sys.exit(0 if ok else 1)
PYV
}

"$MM/cps2$EXESUF" -verifyroms vsavjw -rompath "$(native_pathlist "$REPO/$MERGED/rompath;$ROMDIR")" > "$W/verify.log" 2>&1 || true
verify_check "$W/verify.log" "$MERGED/rompath/vsavjw.zip" "" || f2=1
if [ "$f2" = 0 ]; then
    MAME_BIN="$MM/cps2$EXESUF" MAME_ROMPATH="$(native_pathlist "$REPO/$MERGED/rompath;$ROMDIR")" SUITE_ONLY=05_timeout_idle \
        tests/run_suite.sh vsavjw > "$W/suite.log" 2>&1 || true
    n="$(grep -c 'PASS masked-\|PASS$' "$W/suite.log" || true)"
    if ! grep -q "SUITE GREEN" "$W/suite.log" || [ "$n" != 1 ]; then
        echo "FAIL: the release MAME did not reproduce 05_timeout_idle's frozen expectation:"; tail -6 "$W/suite.log"; f2=1
    fi
fi
# ONE perturbation function for section 3, called by the control section AND by the
# CONTROL= mode, so what a mode proves is exactly what the control claims ([VSP-181]).
# The swap preserves the member's name and size, so the set still LOADS: that is the
# point, a member that fails to load is caught trivially and proves nothing about the
# comparison. <victim> takes <donor>'s bytes; both must be completion members.
sa_perturb() {  # sa_perturb <victim member> <donor member> <src dir> <out dir>
    rm -rf "$4"; cp -R "$3" "$4"
    python3 - "$4/vsavjw.zip" "$1" "$2" <<'PY3'
import zipfile, sys, shutil
p, victim, donor = sys.argv[1:4]
shutil.copyfile(p, p + ".orig")
src = zipfile.ZipFile(p + ".orig")
d = src.read(donor)
assert len(d) == len(src.read(victim)), "the swap must preserve the member size"
with zipfile.ZipFile(p, "w", zipfile.ZIP_STORED) as out:
    for n in src.namelist():
        out.writestr(n, d if n == victim else src.read(n))
PY3
    rm -f "$4/vsavjw.zip.orig"
}

# ---- section 3: THE SHIPPED RELEASE DIRECTORY PRODUCES A SET THAT STANDS ALONE AND
# BEHAVES LIKE THE GATED BUILD (2026-09-20, the standalone completion).
# The release completes `vsavjw.zip` so a player places ONE file, which makes the zip a
# player runs a declared SUPERSET of the zip every other gate measures. That difference is
# checked here, by machine, on BOTH emulators and on THREE independent instruments:
#
#   3a  COMPLETENESS, from the emulator's own descriptor — `-verifyroms` against the
#       applied set ALONE: no NOT FOUND, and exactly the same flagged set as the build
#       arrangement. This is the check that does not read the packager's
#       `standalone_completion` declaration, so it is what catches a completion member
#       that is missing or wrong — INCLUDING the three QSound members, which neither
#       stream below can see (measured 2026-09-20: `vm3.11m` given `vm3.12m`'s bytes adds
#       exactly one INCORRECT CHECKSUM line and is invisible to RAM and video alike).
#   3b  MAME behaviour — the applied set alone vs the build arrangement, whole-RAM
#       checksums AND `VIDEO_OUT` framebuffer checksums, on the RELEASE binary.
#   3c  FBNeo behaviour — the same A/B on the HARNESS build, because the release FBNeo
#       binary deliberately carries no harness (section 1 asserts that), and FBNeo is the
#       loader that matters most here: its CRC-then-`0xFF`-fill path runs thousands of
#       frames with work RAM BIT-IDENTICAL on missing members, so its own load log is
#       checked for `(not found)` as well (docs/platform/gotchas.md, 2026-09-20).
if [ "$f2" = 0 ]; then
    reldir="$(python3 - "$REPO" "$REPO/$MERGED/rompath" <<'PY2'
import glob, json, os, re, sys, subprocess
repo, rp = sys.argv[1:3]
out = subprocess.run([sys.executable, os.path.join(repo, "tools", "build_fingerprint.py"),
                      rp, "--set", "vsavjw", "--set-key"], capture_output=True, text=True).stdout
keys = re.findall(r"\b[0-9a-f]{40}\b", out)
key = keys[-1] if keys else None
for m in sorted(glob.glob(os.path.join(repo, "release", "*", "mame", "manifest.json"))):
    try:
        j = json.load(open(m))
    except Exception:
        continue
    if key and j.get("build_fingerprint") == key and j.get("standalone_completion"):
        print(os.path.dirname(m)); break
PY2
)"
    if [ -z "$reldir" ]; then
        echo "FAIL: no shipped release dir carries a standalone completion for this build — section 3 cannot run"
        f2=1
    else
        rm -rf "$W/standalone"
        if ! python3 "$reldir/apply_release.py" --romdir "$ROMDIR" --out "$W/standalone" > "$W/sa_apply.log" 2>&1; then
            echo "FAIL: the shipped applier did not produce a set:"; tail -5 "$W/sa_apply.log"; f2=1
        fi
        # THE MODES: the perturbed set becomes the INPUT the whole of section 3 runs on,
        # so the gate reaches its OWN FAIL rather than a bespoke assertion. The in-gate
        # control block below is then skipped by its `f2 = 0` guard, which is correct —
        # under a mode the main path IS the control.
        if [ "$f2" = 0 ] && vs_ctl_is standalone-member-content; then
            sa_perturb vm3.14m vm3.16m "$W/standalone" "$W/sa_mode"
            rm -rf "$W/standalone"; mv "$W/sa_mode" "$W/standalone"
        fi
        if [ "$f2" = 0 ] && vs_ctl_is standalone-audio-member-content; then
            sa_perturb vm3.11m vm3.12m "$W/standalone" "$W/sa_mode"
            rm -rf "$W/standalone"; mv "$W/sa_mode" "$W/standalone"
        fi
    fi
fi

# ---- 3a: completeness from the emulator's descriptor, the applied set ALONE.
# THE EXPECTATION IS COMPUTED FROM THE **BUILD'S** ZIP, NEVER FROM THE SET UNDER TEST.
# Paid for immediately: the first version passed the applied zip as the expectation
# source, so under `CONTROL=` the perturbation moved BOTH sides — the swapped member is
# not byte-identical to a pristine twin, so it became "expected flagged", was flagged,
# and 3a agreed with itself. That is the very defect (one derivation writing both sides)
# this leg exists to prevent, reintroduced inside the fix for it. The build's zip is the
# gated artifact and is untouched by any perturbation of the applied set, and the 7
# completion members are pristine copies that the descriptor does NOT flag, so the honest
# expectation is: the applied set flags EXACTLY the members the build authors, and nothing
# else. A completion member that is missing shows up as NOT FOUND; one carrying wrong
# content shows up as a flagged member the build does not author. Both then FAIL here.
if [ "$f2" = 0 ]; then
    "$MM/cps2$EXESUF" -verifyroms vsavjw -rompath "$(native_pathlist "$W/standalone")" > "$W/sa_verify.log" 2>&1 || true
    verify_check "$W/sa_verify.log" "$REPO/$MERGED/rompath/vsavjw.zip" " (standalone set alone, expectation from the build)" || f2=1
fi

# ---- 3b / 3c: the behavioural A/B on both emulators
if [ "$f2" = 0 ]; then
    sa_mame() {  # sa_mame <ramlog> <videolog> <rompath> <tag>
        MAME_BIN="$MM/cps2$EXESUF" MAME_ROMPATH="$(native_pathlist "$3")" VIDEO_OUT="$2" \
        tools/run_replay_mame.sh vsavjw tests/replays/05_timeout_idle.rpl "$1" "$W/sa_sb_$4" \
        > "$W/sa_run_$4.log" 2>&1
    }
    sa_fbneo() {  # sa_fbneo <ramlog> <videolog> <romdir> <fbneo_overlay_or_empty> <tag>
        ROMDIR="$3" FBNEO_ROMPATH="$4" FBNEO_HVIDEO="$2" \
        tools/run_replay_fbneo.sh vsavjw tests/replays/05_timeout_idle.rpl "$1" "$W/sa_fsb_$5" \
        > "$W/sa_frun_$5.log" 2>&1
    }
    cmp_legs() {  # cmp_legs <label> <ram_a> <ram_b> <vid_a> <vid_b>
        if ! cmp -s "$2" "$3"; then
            echo "FAIL: $1 — the standalone set diverges from the build arrangement in work RAM:"
            diff "$2" "$3" | head -4; return 1
        fi
        if ! cmp -s "$4" "$5"; then
            echo "FAIL: $1 — the standalone set diverges from the build arrangement in the FRAMEBUFFER:"
            diff "$4" "$5" | head -4; return 1
        fi
        d="$(sort -u "$4" | wc -l | tr -d ' ')"
        [ "$d" -ge 100 ] || { echo "FAIL: $1 — the framebuffer stream is near-constant ($d distinct); the video comparison would be vacuous"; return 1; }
        return 0
    }
    # 3b MAME, on the release binary
    if ! sa_mame "$W/sa_alone.log" "$W/sa_alone.vid" "$W/standalone" alone; then
        echo "FAIL: the applied standalone set did not complete a MAME replay:"; tail -5 "$W/sa_run_alone.log"; f2=1
    elif ! sa_mame "$W/sa_build.log" "$W/sa_build.vid" "$REPO/$MERGED/rompath;$ROMDIR" build; then
        echo "FAIL: the build arrangement did not complete a MAME replay:"; tail -5 "$W/sa_run_build.log"; f2=1
    elif ! cmp_legs "mame" "$W/sa_alone.log" "$W/sa_build.log" "$W/sa_alone.vid" "$W/sa_build.vid"; then
        f2=1
    else
        echo "  ok: mame — the standalone set alone reproduces the build arrangement's $(wc -l < "$W/sa_alone.log" | tr -d ' ')-frame RAM log AND framebuffer stream"
    fi
fi
# 3c FBNeo, on the HARNESS build (the release binary has none, by design)
FBH="${FBNEO_HARNESS_BIN:-$REPO/emu/fbneo/fbneo}"
if [ "$f2" = 0 ]; then
    if [ ! -x "$FBH" ]; then
        echo "FAIL: no harness FBNeo at $FBH — section 3c cannot run (tools/setup_fbneo.sh; the RELEASE binary carries no harness by design, so it cannot drive a replay)"
        f2=1
    elif ! FBNEO_BIN="$FBH" sa_fbneo "$W/fb_alone.log" "$W/fb_alone.vid" "$W/standalone" "" alone; then
        echo "FAIL: the applied standalone set did not complete an FBNeo replay:"; tail -5 "$W/sa_frun_alone.log"; f2=1
    elif ! FBNEO_BIN="$FBH" sa_fbneo "$W/fb_build.log" "$W/fb_build.vid" "$ROMDIR" "$REPO/$MERGED/rompath" build; then
        echo "FAIL: the build arrangement did not complete an FBNeo replay:"; tail -5 "$W/sa_frun_build.log"; f2=1
    elif ! cmp_legs "fbneo" "$W/fb_alone.log" "$W/fb_build.log" "$W/fb_alone.vid" "$W/fb_build.vid"; then
        f2=1
    else
        nnf="$(command grep -c '(not found)' "$W/sa_frun_alone.log" 2>/dev/null || true)"
        if [ "${nnf:-0}" != 0 ]; then
            echo "FAIL: FBNeo reported $nnf '(not found)' member(s) on the standalone set — it is not complete for FBNeo:"
            command grep '(not found)' "$W/sa_frun_alone.log" | head -4; f2=1
        else
            echo "  ok: fbneo — the standalone set alone loads every member ((not found) x0) and reproduces the build arrangement's RAM log AND framebuffer stream"
        fi
    fi
fi

# ---- 3d: THE SECOND, --no-qsound-bios VARIANT, whose three documented properties are
# what the MiSTer README now tells players to rely on, so they are asserted rather than
# stated: MAME REFUSES it (dl-1425.bin NOT FOUND — keep the member if MAME is your
# emulator); FBNeo runs it IDENTICALLY to the full variant (its descriptor does not list
# the member); and the WIDE MRA still resolves all of its CRC-matched parts, the BIOS one
# coming from the card's own qsound.zip.
if [ "$f2" = 0 ]; then
    rm -rf "$W/standalone_min"
    if ! python3 "$reldir/apply_release.py" --romdir "$ROMDIR" --out "$W/standalone_min" --no-qsound-bios > "$W/sa_min_apply.log" 2>&1; then
        echo "FAIL: the shipped applier did not produce a --no-qsound-bios set:"; tail -5 "$W/sa_min_apply.log"; f2=1
    else
        # (i) MAME must REFUSE it, and for the stated reason
        "$MM/cps2$EXESUF" -verifyroms vsavjw -rompath "$(native_pathlist "$W/standalone_min")" > "$W/sa_min_verify.log" 2>&1 || true
        if ! command grep -q 'dl-1425.bin .* - NOT FOUND' "$W/sa_min_verify.log"; then
            echo "FAIL: MAME did not report dl-1425.bin NOT FOUND on the --no-qsound-bios set — the README's warning is wrong"
            f2=1
        fi
        # (ii) FBNeo must run it identically to the full variant (reuse 3c's full-variant logs)
        if [ "$f2" = 0 ]; then
            if ! FBNEO_BIN="$FBH" sa_fbneo "$W/fb_min.log" "$W/fb_min.vid" "$W/standalone_min" "" min; then
                echo "FAIL: FBNeo did not complete a replay on the --no-qsound-bios set:"; tail -5 "$W/sa_frun_min.log"; f2=1
            elif ! cmp -s "$W/fb_min.log" "$W/fb_alone.log" || ! cmp -s "$W/fb_min.vid" "$W/fb_alone.vid"; then
                echo "FAIL: on FBNeo the --no-qsound-bios set differs from the full one:"
                cmp -s "$W/fb_min.log" "$W/fb_alone.log" || echo "  work RAM differs"
                cmp -s "$W/fb_min.vid" "$W/fb_alone.vid" || echo "  framebuffer differs"
                f2=1
            fi
        fi
        # (iii) the WIDE MRA's parts must still all resolve, the BIOS one from qsound.zip
        if [ "$f2" = 0 ]; then
            python3 - "$W/standalone_min/vsavjw.zip" "$ROMDIR/qsound_hle.zip" "$reldir/../mister" <<'PY4' || f2=1
import zipfile, re, sys, os, glob
zp, qp, misdir = sys.argv[1:4]
mras = [f for f in glob.glob(os.path.join(misdir, "*.mra")) if "STOCK" not in open(f).read()[:400].upper()]
wide = [f for f in mras if "WIDE" in os.path.basename(f).upper()]
if not wide:
    print("FAIL: no WIDE .mra beside the release to check"); sys.exit(1)
have = {i.CRC: "vsavjw.zip" for i in zipfile.ZipFile(zp).infolist()}
for i in zipfile.ZipFile(qp).infolist():
    have.setdefault(i.CRC, "qsound.zip")
parts = re.findall(r'<part name="([^"]+)" crc="([0-9a-fA-F]+)"', open(wide[0]).read())
miss = [(n, c) for n, c in parts if int(c, 16) not in have]
if miss:
    print(f"FAIL: the WIDE MRA cannot resolve {miss} from the --no-qsound-bios set plus qsound.zip")
    sys.exit(1)
from collections import Counter
src = Counter(have[int(c, 16)] for n, c in parts)
if src.get("qsound.zip", 0) != 1:
    print(f"FAIL: expected exactly ONE part from qsound.zip, got {dict(src)}"); sys.exit(1)
print(f"  ok: mister — the WIDE MRA resolves all {len(parts)} parts from the --no-qsound-bios set "
      f"plus the card's qsound.zip ({dict(src)})")
PY4
        fi
        [ "$f2" = 0 ] && echo "  ok: --no-qsound-bios — MAME refuses it (dl-1425.bin NOT FOUND, as the README says), FBNeo runs it identically to the full set"
    fi
    rm -rf "$W/standalone_min"
fi

# ---- section 3's must-fire controls: TWO perturbations, a gfx member and an AUDIO member.
# The audio one exists because 3 of the 7 completion members are QSound (vm3.11m/12m and
# dl-1425.bin) and NEITHER compared stream can see them — only 3a can, which is exactly
# why 3a does not read the packager's declaration.
if [ "$f2" = 0 ]; then
    # (i) a GFX completion member with another gfx member's bytes: same name, same size,
    # so it loads; work RAM is unmoved and the FRAMEBUFFER is what shows it.
    sa_perturb vm3.14m vm3.16m "$W/standalone" "$W/sa_gfx"
    grc=0
    sa_mame "$W/sa_g.log" "$W/sa_g.vid" "$W/sa_gfx" gfx || grc=$?
    gram=same; gvid=same
    cmp -s "$W/sa_g.log" "$W/sa_build.log" || gram=differs
    cmp -s "$W/sa_g.vid" "$W/sa_build.vid" || gvid=differs
    if [ "$grc" != 0 ]; then
        vs_ctl_fired standalone-member-content "vm3.14m := vm3.16m's bytes: the leg did not complete (rc=$grc) — caught, but not via the video comparison"
    elif [ "$gvid" = differs ]; then
        vs_ctl_fired standalone-member-content "vm3.14m := vm3.16m's bytes: framebuffer differs (work RAM $gram — which is why the video half is asserted)"
    elif [ "$gram" = differs ]; then
        vs_ctl_fired standalone-member-content "vm3.14m := vm3.16m's bytes: work RAM differs"
    else
        vs_ctl_dead standalone-member-content "a set whose vm3.14m carries vm3.16m's bytes compared EQUAL on both streams" || true; f2=1
    fi
    # (ii) an AUDIO completion member: invisible to RAM and video, so 3a must catch it.
    sa_perturb vm3.11m vm3.12m "$W/standalone" "$W/sa_aud"
    "$MM/cps2$EXESUF" -verifyroms vsavjw -rompath "$(native_pathlist "$W/sa_aud")" > "$W/sa_aud_verify.log" 2>&1 || true
    if verify_check "$W/sa_aud_verify.log" "$REPO/$MERGED/rompath/vsavjw.zip" " (audio control)" > "$W/sa_aud_check.log" 2>&1; then
        vs_ctl_dead standalone-audio-member-content "a set whose vm3.11m carries vm3.12m's bytes passed the completeness check" || true; f2=1
    else
        vs_ctl_fired standalone-audio-member-content "vm3.11m := vm3.12m's bytes: $(command grep -m1 '^FAIL' "$W/sa_aud_check.log" | cut -c1-96)"
    fi
    rm -rf "$W/sa_gfx" "$W/sa_aud"
fi
[ "$f2" = 0 ] && echo "  ok: record, self-contained, $SIGNED, knows vsavjw, -verifyroms flags exactly the WIDE members, reproduced 05_timeout_idle's frozen masked expectation"
[ "$f2" = 0 ] || fail=1

# ---- must-fire controls: the two perturbed copies must FAIL check_dir
if [ -z "$FLIP_SRC" ]; then
    vs_ctl_dead flipped-library-byte "no directory on this host bundles a library to flip — untestable here, not proven" || true
    fail=1
elif check_dir "$W/fb_flip" "$FLIP_EXE" > "$W/c1.txt" 2>&1; then
    vs_ctl_dead flipped-library-byte "a flipped library byte passed the record check" || true; fail=1
else
    vs_ctl_fired flipped-library-byte "on $FLIP_KIND: $(grep -c '^FAIL' "$W/c1.txt") FAIL line(s), first: $(grep -m1 '^FAIL' "$W/c1.txt")"
fi
if [ -z "$ABSREF_SRC" ]; then
    vs_ctl_dead absolute-reference "no directory on this host bundles a library to perturb — the property is untestable here, not proven" || true
    fail=1
elif check_dir "$W/absref" "$ABSREF_EXE" > "$W/c2.txt" 2>&1; then
    vs_ctl_dead absolute-reference "an unresolvable reference passed the self-containment check" || true; fail=1
else
    if grep -qE 'references /opt/homebrew|NOT FOUND|not found|outside this (directory|folder)|not bundled|not in this folder' "$W/c2.txt"; then
        vs_ctl_fired absolute-reference "on $ABSREF_KIND: $(grep -m1 -E 'references /opt/homebrew|NOT FOUND|not found|outside this|not bundled|not in this folder' "$W/c2.txt")"
    else
        vs_ctl_dead absolute-reference "check_dir failed for another reason: $(grep -m1 '^FAIL' "$W/c2.txt")" || true; fail=1
    fi
fi

[ "$fail" = 0 ] && echo "PASS: test_release_binaries ($OSARCH)" || { echo "FAIL: test_release_binaries ($OSARCH)"; exit 1; }
