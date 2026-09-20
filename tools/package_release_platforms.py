#!/usr/bin/env python3
"""package_release_platforms.py <build_rompath> <release_root> --romdir ROMDIR
                                --name NAME --version TEXT
                                [--mister-src DIR] [--bitstream DIR]
                                [--platforms fbneo,mame,mister]

THE PER-PLATFORM RELEASE (maintainer-ruled 2026-08-28, 14z-113; the format
is docs/project/release_format.md).  One release = release/<NAME>/ with ONE
SUBDIRECTORY PER PLATFORM, each SELF-SUFFICIENT — everything that platform
needs and nothing else — and every version releases ALL platforms even when
only one of them changed:

  release/<NAME>/
    fbneo/    the romset patch set (package_release.py output, FLAT) +
              emulator/0002-cps2-wide-v1.patch + EMULATOR.md (pin + recipe)
    mame/     the romset patch set + emulator/0002-cps2-wide-v1.patch +
              EMULATOR.md (pin + recipe)
    mister/   the romset patch set + the .mra files + jtcps2w.rbf +
              BITSTREAM.txt — the bitstream and its record come from the
              CANONICAL build resource release/bitstreams/<seed>/ (the seed
              named by release/bitstreams/CURRENT, or --bitstream DIR), and
              the .rbf is VERIFIED against the record's sha256 before it is
              copied. A release never copies a bitstream from another
              release (maintainer, 2026-08-28).

The romset patch set is COPIED into each platform directory rather than
shared (ruled: self-sufficiency beats de-duplication; ~2.5 MB x 3).  It is
produced by tools/package_release.py — this script never computes a patch
itself, so the round-trip / refusal / rule-7 guarantees of that tool hold
unchanged for every copy, and the three copies are asserted IDENTICAL
(manifest.json byte-for-byte) by tests/test_release_roundtrip.sh section 4.

The emulator side ships the driver PATCH and a build recipe AND, since the
maintainer's 2026-09-11 ruling (recipe and prebuilt, each user free to
choose), prebuilt binaries per OS from the build resource
release/emulators/<platform>/<os-arch>/ (hash-verified against BINARY.txt;
none for an OS until a host builds it — see binaries_side).  The MiSTer side ships the MRAs the
release was verified with (from the field bundle or tools/mister_mra.sh
--no-rom — deterministic XML, no ROM content); the bitstream and its RECORD
are pulled from release/bitstreams/ and hash-verified, so a stale CURRENT or a
tampered file is a hard error, never a silently wrong release.

Rule 7: nothing here reads a reference ROM except through package_release.py
(which reads them only to compute deltas), and nothing ROM-derived is written.
Deterministic: two runs produce byte-identical trees.
"""
import argparse, os, re, shutil, subprocess, sys, tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.dirname(HERE)
PLATFORMS = ("fbneo", "mame", "mister")

EMU = {
    "fbneo": dict(
        patch="emu/fbneo-patches/0002-cps2-wide-v1.patch",
        submodule="emu/fbneo",
        upstream="https://github.com/finalburnneo/FBNeo",
        recipe="""\
    git clone {upstream} fbneo && cd fbneo && git checkout {pin}
    git apply /path/to/emulator/0002-cps2-wide-v1.patch
    make sdl2 SKIPDEPEND=1 -j8 -k     # SKIPDEPEND=1 is mandatory (see the project's docs/GOTCHAS.md);
    make sdl2 SKIPDEPEND=1 -j8        # TWICE on a fresh clone: the parallel first pass stops on burn.o
                                      # until the driver list is generated (-k lets it finish the rest)
""",
        note="""\
The patch adds the `vsavjw` driver (the CPS-2 WIDE profile: 6 MB program,
48 MB GFX via the CPS-2 Turbo bit-12 tile promote, 16 MB QSound) as a new
driver entry beside `vsavj`. Stock `vsavj` and every other CPS-2 game are
untouched by construction — the only emulation-logic change is one widened
condition in `cps_obj.cpp`, gated on the `Cps2Wide` flag that only the new
driver sets. The project's other FBNeo patch (0001, the replay harness) is a
frontend-only test instrument and is NOT needed to play.
NETPLAY: this is a custom build — every peer needs the same binary AND the
same romset (the patched build's fingerprint is in ../manifest.json).
""",
    ),
    "mame": dict(
        patch="emu/mame-patches/0002-cps2-wide-v1.patch",
        submodule="emu/mame",
        upstream="https://github.com/mamedev/mame",
        recipe="""\
    git clone {upstream} mame && cd mame && git checkout {pin}     # tag mame0288
    git apply /path/to/emulator/0002-cps2-wide-v1.patch
    make SOURCES=src/mame/capcom/cps2.cpp SUBTARGET=cps2 -j8    # CPS-2-only build, minutes not hours
    ./cps2 -verifyroms vsavjw -rompath "/your/built/set;/your/dumps"   # says "is bad" BY DESIGN: it lists exactly the
                                                                 # members inside vsavjw.zip as INCORRECT CHECKSUM (the
                                                                 # driver carries the stock CRCs for the members the port
                                                                 # rewrites and sentinel CRCs for the new ones) — nothing
                                                                 # may be NOT FOUND. "is good" is not reachable on this set.
""",
        note="""\
The patch is 164 lines added and exactly ONE line removed (the sprite
tile-code composition, gated on `m_cps2_wide`, a driver member only the
`vsavjw` machine config sets). It adds the `vsavjw` ROM descriptor, one
`GAME()` row and one `mame.lst` row. A Homebrew/distribution MAME binary
cannot load this romset — it has no `vsavjw` driver — so a source build is
required. MAME's own `-verifyroms vsavjw` is the independent check that the
romset the applier produced is the one the driver expects.
""",
    ),
}



# ── THE LAUNCHER (2026-09-20, the maintainer's item 2: "either provide an alternate
# shell script that runs the emulator the way we want or at least make it super obvious
# what to do") ──────────────────────────────────────────────────────────────────────
# One `PLAY.command` per EMULATOR platform (MiSTer launches from its own menu, so it
# gets none). It encodes the three things `tools/run_wide.sh` had to learn and that a
# player has no way to know: that the set is `vsavjw` and only the patched build knows
# it; that FBNeo's SDL frontend has NO rom-path option and reads `roms/` relative to the
# CURRENT DIRECTORY, so browsing to the set in its GUI cannot work; and that a macOS
# download is quarantined and Gatekeeper refuses an ad-hoc-signed binary on first launch.
# Every failure exits non-zero naming its cause, and keeps the Terminal window open,
# because a double-clicked .command closes on exit and takes the message with it.
# `PLAY_DRY_RUN=1` stops before the emulator so tests/test_release_launcher.sh can drive
# every path; `PLAY_CLEAR_QUARANTINE=1` answers its one prompt for the same reason.

LAUNCHER = r'''#!/bin/sh
# PLAY.command — start VAMPIRE SAVED (@NAME@) on @PLATFORM_UPPER@.
#
# GENERATED by tools/package_release_platforms.py; do not edit by hand.
# Double-click it on macOS, or run `sh PLAY.command` from a terminal.
#
# It exists because getting this right by hand is the one step players were
# measured to fail: @WHY@
set -eu
HERE="$(cd "$(dirname "$0")" && pwd)"
cd "$HERE"

say()  { printf '%s\n' "$*"; }
pause() { printf '\nPress Return to close this window.\n'; read _dummy 2>/dev/null || true; }
die()  { printf '\n!! %s\n' "$1" >&2; shift; for _l in "$@"; do printf '   %s\n' "$_l" >&2; done; pause; exit 1; }

say "VAMPIRE SAVED @NAME@ — @PLATFORM_UPPER@"
say ""

# ── 1. which prebuilt binary belongs to this machine ───────────────────────
case "$(uname -s)" in
Darwin) OS=macos ;;
Linux)  OS=linux ;;
MINGW*|MSYS*|CYGWIN*) OS=windows ;;
*) die "unsupported system: $(uname -s)" "This launcher knows macOS, Linux and MSYS2/Windows." ;;
esac
ARCH="$(uname -m)"
case "$ARCH" in arm64|aarch64) ARCH=arm64 ;; x86_64|amd64) ARCH=x86_64 ;; esac
OSARCH="$OS-$ARCH"
EXE="@EXE@"
[ "$OS" = windows ] && EXE="$EXE.exe"
BIN="$HERE/emulator/bin/$OSARCH/$EXE"

if [ ! -f "$BIN" ]; then
    _have="$(ls emulator/bin 2>/dev/null | tr '\n' ' ' || true)"
    die "no prebuilt @PLATFORM@ for $OSARCH in this package." \
        "Present: ${_have:-none}" \
        "If you took the '-recipe' download, it ships the patch and EMULATOR.md" \
        "instead of a binary — build it once from those, then run it yourself." \
        "Otherwise no host has built $OSARCH yet."
fi
chmod +x "$BIN" 2>/dev/null || true

# ── 2. macOS quarantine (the binary is ad-hoc signed, NOT notarized) ───────
# A downloaded copy carries com.apple.quarantine and Gatekeeper refuses it on
# first launch. This is the one first-run problem on macOS and it is the
# player's own security state, so we ASK rather than silently clear it.
if [ "$OS" = macos ] && command -v xattr >/dev/null 2>&1; then
    if xattr -p com.apple.quarantine "$BIN" >/dev/null 2>&1; then
        say "macOS has quarantined this download, so it will refuse to launch."
        say "The binary is ad-hoc signed, not notarized — that is expected here."
        if [ -n "${PLAY_CLEAR_QUARANTINE:-}" ]; then
            _ans=y
        else
            printf 'Clear the quarantine flag on this folder now? [y/N] '
            read _ans 2>/dev/null || _ans=n
        fi
        case "$_ans" in
        y|Y|yes|YES)
            xattr -dr com.apple.quarantine "$HERE" || die "could not clear the quarantine flag." \
                "Run this yourself, then start again:" "  xattr -dr com.apple.quarantine '$HERE'"
            say "Cleared."
            ;;
        *)
            die "not cleared, so macOS will block the emulator." \
                "macOS shows: \"fbneo\" Not Opened — Apple could not verify ..." \
                "with only Done and Move to Bin. RIGHT-CLICK > OPEN DOES NOT GET PAST IT" \
                "on current macOS. What works is clearing the flag:" \
                "  xattr -dr com.apple.quarantine '$HERE'" \
                "then start this launcher again."
            ;;
        esac
        say ""
    fi
fi

# ── 3. is this actually the patched emulator? ──────────────────────────────
@PROFILE_CHECK@

# ── 4. find the romset the applier built ──────────────────────────────────
# Looked for in the places a player plausibly puts it, nearest first.
ZIP=""
for _c in "$HERE/roms/vsavjw.zip" "$HERE/vsavjw.zip" "$HERE/rompath/vsavjw.zip"; do
    [ -f "$_c" ] && { ZIP="$_c"; break; }
done
if [ -z "$ZIP" ]; then
    die "vsavjw.zip not found." \
        "Build it from YOUR OWN dumps first — see README.md:" \
        "  python3 apply_release.py --romdir /path/to/your/dumps --out ./rompath" \
        "then put vsavjw.zip beside this launcher (or leave it in ./rompath/)."
fi
say "romset: $ZIP"
say "emulator: $BIN"
say ""

@LAUNCH@
'''

FBNEO_PROFILE = r'''if command -v strings >/dev/null 2>&1; then
    strings -a "$BIN" 2>/dev/null | grep -q "CPS-2 WIDE v1" || \
        die "that FBNeo does not carry the CPS-2 WIDE profile." \
            "Only a patched build knows the vsavjw set. Use this package's binary," \
            "or build one with emulator/0002-cps2-wide-v1.patch per EMULATOR.md."
fi'''

MAME_PROFILE = r'''"$BIN" -listfull vsavjw >/dev/null 2>&1 || \
    die "that MAME does not know the vsavjw driver." \
        "A stock or Homebrew MAME never will. Use this package's binary," \
        "or build one with emulator/0002-cps2-wide-v1.patch per EMULATOR.md."'''

# FBNeo has NO -rompath: src/burner/sdl reads szAppRomPaths, which defaults to
# "roms/" RELATIVE TO THE CURRENT DIRECTORY. Passing -rompath is silently
# ignored, which is exactly the "I cannot launch it" failure this script exists
# to remove. So: make ./roms/, put the set in it, and run from HERE.
FBNEO_LAUNCH = r'''if [ -L "$HERE/roms" ]; then
    die "./roms is a symlink (-> $(readlink "$HERE/roms"))." \
        "This launcher will not write through it. Remove the link and start again."
fi
mkdir -p "$HERE/roms"
if [ ! -f "$HERE/roms/vsavjw.zip" ]; then
    ln -sf "$ZIP" "$HERE/roms/vsavjw.zip" 2>/dev/null || cp "$ZIP" "$HERE/roms/vsavjw.zip"
fi
cd "$HERE"
# PLAY_DRY_RUN is how the project's own gate drives this script without starting
# an emulator; it changes nothing else, and every check above has already run.
if [ -n "${PLAY_DRY_RUN:-}" ]; then
    say "WOULD RUN: $BIN vsavjw (cwd $HERE, roms/vsavjw.zip present)"
    exit 0
fi
say "Starting. Tab opens FBNeo's own menu (controls, video, exit)."
say ""
exec "$BIN" vsavjw "$@"'''

MAME_LAUNCH = r'''# PLAY_DRY_RUN is how the project's own gate drives this script without starting
# an emulator; it changes nothing else, and every check above has already run.
if [ -n "${PLAY_DRY_RUN:-}" ]; then
    say "WOULD RUN: $BIN vsavjw -rompath $(dirname "$ZIP") -skip_gameinfo"
    exit 0
fi
say "Starting. Tab opens MAME's own menu (controls, video); Esc exits."
say ""
exec "$BIN" vsavjw -rompath "$(dirname "$ZIP")" -skip_gameinfo "$@"'''

WHY = {
    "fbneo": ("FBNeo's SDL build has no rom-path option at all, so it only ever looks in "
              "`roms/` next to the current directory. Browsing to the set in the GUI does not work."),
    "mame":  ("the set is `vsavjw`, which only the patched build knows, and it needs a rompath "
              "pointing at your built set — picking it from MAME's own list does not work."),
}


def launcher_text(platform, name):
    exe = "fbneo" if platform == "fbneo" else "cps2"
    t = LAUNCHER
    t = t.replace("@NAME@", name)
    t = t.replace("@PLATFORM_UPPER@", platform.upper())
    t = t.replace("@PLATFORM@", platform)
    t = t.replace("@EXE@", exe)
    t = t.replace("@WHY@", WHY[platform])
    t = t.replace("@PROFILE_CHECK@", FBNEO_PROFILE if platform == "fbneo" else MAME_PROFILE)
    t = t.replace("@LAUNCH@", FBNEO_LAUNCH if platform == "fbneo" else MAME_LAUNCH)
    return t


def run_packager(rompath, romdir, name, version, dest):
    """package_release.py writes <out>/<name>/; we want it FLAT at <dest>."""
    with tempfile.TemporaryDirectory() as tmp:
        subprocess.run([sys.executable, os.path.join(HERE, "package_release.py"),
                        rompath, tmp, "--romdir", romdir, "--name", name,
                        "--version", version], check=True, stdout=subprocess.DEVNULL)
        src = os.path.join(tmp, name)
        if os.path.exists(dest):
            shutil.rmtree(dest)
        shutil.copytree(src, dest)


def release_url(name):
    """The GitHub release page the prebuilt assets attach to (ruled 14z-149): the origin
    remote's HTTPS form + /releases/tag/freeze/<name>; a placeholder when no remote exists."""
    out = subprocess.run(["git", "-C", REPO, "remote", "get-url", "origin"],
                         capture_output=True, text=True).stdout.strip()
    if not out:
        return "the project's GitHub release page"
    out = out[:-4] if out.endswith(".git") else out
    if out.startswith("git@github.com:"):
        out = "https://github.com/" + out[len("git@github.com:"):]
    return f"{out}/releases/tag/freeze/{name}"


def pin_of(submodule):
    out = subprocess.run(["git", "-C", REPO, "submodule", "status", submodule],
                         capture_output=True, text=True).stdout.strip()
    return out.lstrip(" +-").split()[0] if out else "?"


def binaries_side(platform, edir):
    """THE PREBUILT BINARIES (maintainer-ruled 2026-09-11: recipe AND prebuilt,
    each user free to choose). A BUILD RESOURCE with its own cadence, like the
    bitstream: release/emulators/<platform>/<os-arch>/{<files>, BINARY.txt},
    the record naming every file with its sha256, the upstream pin and the
    driver-patch sha1 it was built from. Every <os-arch> dir present is
    hash-verified and copied to emulator/bin/<os-arch>/; NONE present is
    allowed (the recipe is always there) and said so. Returns the list copied."""
    import hashlib, re
    root = os.path.join(REPO, "release", "emulators", platform)
    copied = []
    if not os.path.isdir(root):
        return copied
    for osarch in sorted(os.listdir(root)):
        bdir = os.path.join(root, osarch)
        rec = os.path.join(bdir, "BINARY.txt")
        if not os.path.isdir(bdir) or not os.path.exists(rec):
            continue
        text = open(rec).read()
        rows = re.findall(r"^sha256\s+([0-9a-f]{64})\s+(\S+)\s*$", text, re.M)
        if not rows:
            sys.exit(f"{rec} names no 'sha256 <hex> <file>' row")
        out = os.path.join(edir, "bin", osarch)
        os.makedirs(out, exist_ok=True)
        for want, fname in rows:
            fp = os.path.join(bdir, fname)
            got = hashlib.sha256(open(fp, "rb").read()).hexdigest()
            if got != want:
                sys.exit(f"REFUSING: {fp} sha256 {got[:12]}… != the record's {want[:12]}…")
            shutil.copy(fp, os.path.join(out, fname))
        shutil.copy(rec, os.path.join(out, "BINARY.txt"))
        copied.append(osarch)
        print(f"  {platform} prebuilt {osarch}: {len(rows)} file(s), sha256 verified")
    return copied


def bins_available():
    """Which os-arch dirs under release/emulators/<platform>/ hold binaries (not a record alone) —
    read-only; binaries_side() is what verifies and copies them. Used by the deliverables table."""
    out = {}
    for platform in ("fbneo", "mame"):
        root = os.path.join(REPO, "release", "emulators", platform)
        found = []
        if os.path.isdir(root):
            for osarch in sorted(os.listdir(root)):
                d = os.path.join(root, osarch)
                if os.path.isdir(d) and os.path.exists(os.path.join(d, "BINARY.txt")) \
                        and [f for f in os.listdir(d) if f != "BINARY.txt"]:
                    found.append(osarch)
        out[platform] = found
    return out


def insert_deliverables(dest, name, platform):
    """THE DELIVERABLES section (maintainer, 2026-09-11: "please make the readme clearly
    explain what are each deliverable and how to use them") — inserted before "What is in
    this package" in every platform README: every asset on the release page, what it is,
    who needs it, and that GitHub's auto-added source archives are not needed to play."""
    url = release_url(name)
    b = bins_available()
    def have(pf):
        return ", ".join(b[pf]) if b[pf] else "none yet for any OS — build per the recipe in that package's `EMULATOR.md`"
    up = {"fbneo": "FBNeo", "mame": "MAME", "mister": "MiSTer"}[platform]
    text = f"""## The deliverables — what to download, and what each is for
Everything ships as ASSETS of the GitHub release on tag `freeze/{name}`:
{url}

**TAKE EXACTLY ONE.** Every asset below is complete on its own: the README,
the romset patch set, the applier, and ONE way to get the emulator or core.
There is nothing to combine and nothing to download twice.

| asset | what it is | who needs it |
|---|---|---|
| `{name}-fbneo-<os-arch>.zip` | the FBNeo package for that OS, **ready to play**: this README, the romset patch set + applier, and a prebuilt patched FBNeo with its `BINARY.txt` of sha256s. No build step, nothing to patch (available: {have('fbneo')}) | FBNeo players on a listed OS |
| `{name}-fbneo-recipe.zip` | the same FBNeo package for **any** OS, carrying the driver patch + build recipe (`EMULATOR.md`) instead of a binary: you build the emulator once | FBNeo players on any other OS, or anyone who prefers to build |
| `{name}-mame-<os-arch>.zip` | the MAME package for that OS, ready to play: the same romset patch set + applier, and a prebuilt patched MAME (CPS-2 subtarget) with its `BINARY.txt` (available: {have('mame')}) | MAME players on a listed OS |
| `{name}-mame-recipe.zip` | the same MAME package for any OS, with the driver patch + `EMULATOR.md` instead of a binary | MAME players on any other OS, or anyone who prefers to build |
| `{name}-mister.zip` | the MiSTer package: the same romset patch set + applier, the `jtcps2w.rbf` bitstream + its record (`BITSTREAM.txt`), the two `.mra` files, `MISTER.md` | MiSTer owners |
| "Source code (zip / tar.gz)" | added by GitHub to every release: the whole project repository at the tag — development tooling, logs and all. **NOT needed to play**; nothing above requires it | nobody, unless you want to audit or rebuild the project |

A prebuilt package deliberately carries NO emulator patch and no build
recipe: your binary already contains them, and a patch you cannot use is a
patch you might try to apply. If you want to read or rebuild what your binary
contains, the `-recipe` package of the same platform is where the patch
lives, and your `BINARY.txt` names its sha1.

Every package rebuilds the SAME `vsavjw.zip` from your own dumps (the three
copies of the patch set are byte-identical, and a gate asserts it).
**You are reading the {up} package.** In order: build the romset (below),
get the emulator or core ("Play on {up}" at the end), play.

"""
    rp = os.path.join(dest, "README.md")
    t = open(rp).read()
    marker = "## What is in this package"
    if marker not in t:
        sys.exit(f"{rp}: no '{marker}' section to insert the deliverables before")
    open(rp, "w").write(t.replace(marker, text + marker, 1))


def append_play(dest, text):
    """Put the platform's "Play on …" section where a PLAYER needs it — directly after
    the build step — rather than at the end of the file, which is where a plain append
    left it. #146, 2026-09-20: the reader is not a developer and has never seen this
    project, so the document has to run in the order they will act in."""
    path = os.path.join(dest, "README.md")
    body = open(path).read()
    if "<!--PLAY-->" in body:
        body = body.replace("<!--PLAY-->", text.strip("\n"), 1)
        open(path, "w").write(body)
    else:                       # no marker (an older common README): keep the old behaviour
        with open(path, "a") as f:
            f.write(text)


def emulator_side(platform, dest, name):
    e = EMU[platform]
    edir = os.path.join(dest, "emulator")
    os.makedirs(edir, exist_ok=True)
    shutil.copy(os.path.join(REPO, e["patch"]), os.path.join(edir, os.path.basename(e["patch"])))
    pin = pin_of(e["submodule"])
    bins = binaries_side(platform, edir)
    # THE TWO ROUTES NEVER TRAVEL TOGETHER (maintainer-ruled 2026-09-12), so this
    # step is written for a reader holding EITHER asset and says which files they
    # will actually see. A prebuilt package has no EMULATOR.md and no patch in it.
    avail = (f"built for: {', '.join(bins)}" if bins
             else "none built for any OS in this release yet — take the `-recipe` package")
    up = platform.upper()
    play = f"""
## Play on {up}
You need the prepared emulator, and then the game file next to it.

1. **The emulator.** You already have it, or you build it once — whichever package
   you downloaded:
   - `{name}-{platform}-<os-arch>.zip` ({avail}): the emulator is in this package
     under `emulator/bin/<os-arch>/`, where `<os-arch>` names your system —
     `macos-arm64` is an Apple-Silicon Mac, `windows-x86_64` an ordinary 64-bit
     Windows PC. `BINARY.txt` beside it lists a fingerprint for every file so you
     can confirm nothing was altered in transit. Nothing to build or patch.
   - `{name}-{platform}-recipe.zip`: no ready-made program, but the one small
     change (`emulator/0002-cps2-wide-v1.patch`) and step-by-step build commands
     in `EMULATOR.md`. Use this if your system is not listed above, or if you
     would rather build it yourself than trust a binary.
   Both routes give the same program.
2. **The easy way — macOS: double-click `PLAY.command`** (Linux:
   `sh PLAY.command`; not yet available on Windows). It picks the right program
   for your machine, checks it is the prepared one and not an ordinary copy,
   handles macOS's "downloaded from the internet" block, puts your `vsavjw.zip`
   where this emulator actually looks for it, and starts the game. If anything is
   missing it names it. Skip to step 4.
3. **By hand.** Put the `vsavjw.zip` you built in step 1 {'in a folder called `roms/` next to the emulator program, and start the emulator FROM that folder. This sounds fussy and is: this version of FBNeo has no setting for where games live — it only ever looks in `roms/` beside wherever you started it, so pointing at the file from its menu will not work' if platform == 'fbneo' else 'anywhere you like, and tell the emulator where by starting it with `-rompath "/that/folder"`'}.
   It is the **only** file you put there — not `vsav.zip`, not `vsavj.zip`, not
   the sound file. Everything the emulator needs is already inside it{', as long as you built it the normal way (without `--no-qsound-bios`, which is for MiSTer and which MAME will refuse)' if platform == 'mame' else ''}.
4. Start it. The emulator calls this game `vsavjw`. When it works, the first
   screen reads **VAMPIRE SAVED** and the character-select screen shows
   **{name.split('-')[-1].upper() if '-' in name else ''}** in the bottom-right
   corner. Donovan, Phobos and Pyron are on the select screen with everyone else.
"""
    append_play(dest, play)
    # the launcher, executable, beside the README it points at
    lp = os.path.join(dest, "PLAY.command")
    with open(lp, "w") as f:
        f.write(launcher_text(platform, name))
    os.chmod(lp, 0o755)
    text = f"""# {name} — {platform.upper()} side

This directory is self-sufficient for {platform.upper()}: the romset patch
set (`patches/`, `manifest.json`, `apply_release.py`, `README.md`) and the
emulator driver patch in `emulator/`. Nothing for any other platform is here.

## The emulator
Upstream: {e['upstream']}
Pinned commit: `{pin}` (the exact tree the patch is known to apply to and
the project's gates were run against).

{e['recipe'].format(upstream=e['upstream'], pin=pin)}
{e['note']}
## The romset
Apply `apply_release.py` per `README.md`, then point the patched emulator's
rom path at the output directory. The set is `vsavjw` and it is STANDALONE:
the applier copies in every member the loader asks for, the parent's and
MAME's QSound BIOS member included, so the output directory needs nothing
beside it.
"""
    # THIS FILE SHIPS IN THE `-recipe` ASSET ONLY (ruled 2026-09-12), so it
    # addresses a reader who is building, and points at the other route rather
    # than describing a directory their download does not have.
    text += f"""
## Prebuilt binaries — the other route

**You are reading the build route.** If you would rather not build, the
release on tag `freeze/{name}` ({release_url(name)}) also publishes
`{name}-{platform}-<os-arch>.zip`: the SAME package as this one, with a
prebuilt patched emulator in place of this patch and recipe. It is complete
too — romset patches and applier included — so it replaces this download
rather than joining it.

{('Built so far for: ' + ', '.join(bins) + '. Each carries a `BINARY.txt` naming every file with its sha256, the upstream pin and the sha1 of the driver patch beside this file — the binary is exactly the recipe above, run on one host, and the record says which. Only the latest freeze keeps its assets; the binaries are never files in the repository (ruled 2026-09-11).') if bins else 'None built for any OS in this release yet (ruled 2026-09-11: a release ships the recipe AND prebuilt binaries per OS, each user free to choose; they are added as each host builds them). The recipe above is complete.'}

## If it does not work
- "Unknown system: vsavjw" — this binary does not carry the driver patch.
- The set, RENAMED to `vsavj.zip` to force it into a stock emulator, sits on
  the QSound / CAPCOM legal screen forever (measured 2026-09-11: the stock 4 MB
  driver never loads the program extension, the sound driver or the QSound
  extension; no crash, no gameplay). Renaming is never the fix.
"""
    open(os.path.join(dest, "EMULATOR.md"), "w").write(text)


def resolve_bitstream(arg):
    """release/bitstreams/CURRENT names the seed dir unless --bitstream overrides."""
    if arg:
        return arg
    root = os.path.join(REPO, "release", "bitstreams")
    cur = os.path.join(root, "CURRENT")
    if not os.path.exists(cur):
        sys.exit(f"{cur} missing — no canonical bitstream to package (see docs/project/release_format.md)")
    return os.path.join(root, open(cur).read().strip())


def bitstream_side(dest, bdir):
    rec = os.path.join(bdir, "BITSTREAM.txt")
    rbfs = [f for f in os.listdir(bdir) if f.endswith(".rbf")]
    if not os.path.exists(rec) or len(rbfs) != 1:
        sys.exit(f"{bdir} must hold exactly one .rbf and a BITSTREAM.txt (found {rbfs})")
    import hashlib, re
    want = re.search(r"sha256\s+([0-9a-f]{64})", open(rec).read())
    if not want:
        sys.exit(f"{rec} carries no 'sha256 <64 hex>' line")
    rbf = os.path.join(bdir, rbfs[0])
    got = hashlib.sha256(open(rbf, "rb").read()).hexdigest()
    if got != want.group(1):
        sys.exit(f"REFUSING: {rbf} sha256 {got[:12]}… != the record's {want.group(1)[:12]}… — "
                 "a timing-failing seed emits an indistinguishable .rbf; fix the resource, not the release")
    shutil.copy(rbf, os.path.join(dest, rbfs[0]))
    shutil.copy(rec, os.path.join(dest, "BITSTREAM.txt"))
    print(f"  bitstream {rbfs[0]} from {bdir}: sha256 verified {got[:12]}…")


def mister_side(dest, src, name, bdir):
    if not src:
        sys.exit("mister: --mister-src DIR (holding the .mra files) is required for the mister platform")
    # WHAT SHIPS IS DECLARED BY SETNAME, NOT BY DIRECTORY LAYOUT (14z-126b).
    # jtframe files clones under _alternatives/<parent> and only setnames in
    # the core's parse.main_setnames land at the top level, so a listdir() of
    # the output dir silently depended on that layout: when cps2w made the
    # WIDE set main, the STOCK CONTROL leg moved into _alternatives and a
    # non-recursive scan would have dropped it from every release -- against
    # the ruling that it ships in each one (maintainer, 2026-08-29). Selecting
    # on the MRA's own <setname> is layout-independent and fails LOUDLY if one
    # goes missing, which a glob never would.
    SHIP = {"vsavjw": "the WIDE roster set",
            "vsavj":  "the [STOCK CONTROL] reference leg"}
    found, copied = {}, []
    for root, _dirs, files in os.walk(src):
        for f in sorted(files):
            if not f.endswith(".mra"):
                continue
            path = os.path.join(root, f)
            with open(path, encoding="utf-8", errors="replace") as fh:
                m = re.search(r"<setname>([^<]+)</setname>", fh.read())
            if not m or m.group(1) not in SHIP:
                continue
            if m.group(1) in found:
                sys.exit(f"mister: two MRAs claim setname {m.group(1)}: "
                         f"{found[m.group(1)]} and {path}")
            found[m.group(1)] = path
            shutil.copy(path, os.path.join(dest, f))
            copied.append(f)
    missing = [f"{k} ({v})" for k, v in SHIP.items() if k not in found]
    if missing:
        sys.exit(f"--mister-src {src} is missing: " + ", ".join(missing))
    bitstream_side(dest, bdir)
    text = f"""# {name} — MiSTer side

This directory is self-sufficient for MiSTer: the romset patch set
(`patches/`, `manifest.json`, `apply_release.py`, `README.md`), the `.mra`
files, the bitstream `jtcps2w.rbf` and its record `BITSTREAM.txt` (seed, slack,
sha256 — verified against the file when this directory was packaged).

## On the SD card
    _Arcade/<the .mra files here>
    _Arcade/cores/jtcps2w.rbf        <- in this directory (verify the sha256 in BITSTREAM.txt after copying)
    games/mame/vsavjw.zip            <- from apply_release.py --no-qsound-bios (see below)

**On MiSTer, build the set with `--no-qsound-bios`.** Your card already carries
`games/mame/qsound.zip` the moment you play any CPS-2 game, and the WIDE MRA's
part chain is `vsavjw.zip|vsav.zip|qsound.zip`, so it picks the BIOS member up
from there: measured 2026-09-20, **all 31 CRC-matched parts resolve — 30 out of
`vsavjw.zip` and `dl-1425.bin` out of `qsound.zip`** — and you do not need
`qsound_hle.zip` among your dumps at all. Keeping the member (the applier's
default) also works and costs nothing but the 24 KB; it is what emulator players
want, because MAME refuses a set without it.

The WIDE MRA runs the full roster on `jtcps2w.rbf`. Apart from the BIOS member it
needs nothing beside `vsavjw.zip`: the applier copies the parent's members in from
your own dumps. The other zips are only for the OTHER things on the card:

    games/mame/vsavj.zip             <- your PRISTINE dump: the STOCK CONTROL MRA only
    games/mame/vsav.zip              <- your PRISTINE dump: the STOCK CONTROL MRA, and
                                        stock Vampire Savior on Jotego's own jtcps2.rbf
    games/mame/qsound.zip            <- dl-1425.bin: the WIDE MRA (with --no-qsound-bios)
                                        and the STOCK CONTROL MRA

The `[STOCK CONTROL]`
MRA runs stock `vsavj` on the SAME bitstream with the profile bit at its
`0xFF` fill: it is the superset invariant on silicon and only needs running
when the BITSTREAM changes (new seed, slice or pin), not per release. Stock
Vampire Savior on Jotego's own `jtcps2.rbf` keeps working from the same
`vsav.zip` — the two coexist on one card (field-verified 2026-08-28).

VERIFY THE BITSTREAM'S sha256 BEFORE FLASHING: a timing-failing fitter seed
emits an .rbf indistinguishable from a passing one.
"""
    open(os.path.join(dest, "MISTER.md"), "w").write(text)
    append_play(dest, f"""
## Play on MiSTer
1. Copy `jtcps2w.rbf` to `_Arcade/cores/` and the two `.mra` files to
   `_Arcade/` (verify the bitstream's sha256 against `BITSTREAM.txt` first).
2. Put `vsavjw.zip` (from the applier), your pristine `vsav.zip` and
   `vsavj.zip`, and `qsound.zip` in `games/mame/`.
3. Launch "Vampire Saved - CPS-2 WIDE" from the Arcade menu. `MISTER.md` has
   the card layout and what the [STOCK CONTROL] entry is for.
""")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("rompath")
    ap.add_argument("release_root", help="e.g. release — the tree is written at release/<name>/")
    ap.add_argument("--romdir", required=True)
    ap.add_argument("--name", required=True)
    ap.add_argument("--version", required=True, help="the in-game mark, e.g. M8")
    ap.add_argument("--mister-src", default="", help="dir holding the .mra files (the field bundle's _Arcade/, or mister_mra.sh --no-rom output)")
    ap.add_argument("--bitstream", default="", help="bitstream dir (an .rbf + BITSTREAM.txt); default: release/bitstreams/<CURRENT>")
    ap.add_argument("--platforms", default=",".join(PLATFORMS))
    a = ap.parse_args()
    plats = [p for p in a.platforms.split(",") if p]
    bad = [p for p in plats if p not in PLATFORMS]
    if bad:
        sys.exit(f"unknown platform(s): {bad}")
    root = os.path.join(a.release_root, a.name)
    os.makedirs(root, exist_ok=True)
    for p in plats:
        dest = os.path.join(root, p)
        run_packager(a.rompath, a.romdir, a.name, a.version, dest)
        if p in EMU:
            emulator_side(p, dest, a.name)
        else:
            mister_side(dest, a.mister_src, a.name, resolve_bitstream(a.bitstream))
        insert_deliverables(dest, a.name, p)
        n = sum(len(f) for _, _, f in os.walk(dest))
        print(f"  {p}: {n} files -> {dest}")
    print(f"packaged {a.name} for {', '.join(plats)} -> {root}")


if __name__ == "__main__":
    main()
