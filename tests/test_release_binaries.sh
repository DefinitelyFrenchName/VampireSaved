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
# MUST-FIRE: perturbed-copy: flipped-library-byte — a copy of the fbneo resource dir with one byte of a bundled library flipped must fail the record check (mode: the gate checks that copy in place of the resource)
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
"$MM/cps2$EXESUF" -verifyroms vsavjw -rompath "$(native_pathlist "$REPO/$MERGED/rompath;$ROMDIR")" > "$W/verify.log" 2>&1 || true
python3 - "$W/verify.log" "$MERGED/rompath/vsavjw.zip" "$ROMDIR/vsavj.zip" "$ROMDIR/vsav.zip" <<'PY' || f2=1
import sys, re, zipfile
# THE LAST CR OF THE WINDOWS OUTPUT (14z-153): this block prints the gate's one PASS
# line from Python, and a NATIVE Windows python writes "\r\n" for "\n" — the one CR
# byte left in the MSYS2 output after 14z-152 reconfigured the other block (above).
sys.stdout.reconfigure(encoding="utf-8", newline="\n")
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
    MAME_BIN="$MM/cps2$EXESUF" MAME_ROMPATH="$(native_pathlist "$REPO/$MERGED/rompath;$ROMDIR")" SUITE_ONLY=05_timeout_idle \
        tests/run_suite.sh vsavjw > "$W/suite.log" 2>&1 || true
    n="$(grep -c 'PASS masked-\|PASS$' "$W/suite.log" || true)"
    if ! grep -q "SUITE GREEN" "$W/suite.log" || [ "$n" != 1 ]; then
        echo "FAIL: the release MAME did not reproduce 05_timeout_idle's frozen expectation:"; tail -6 "$W/suite.log"; f2=1
    fi
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
