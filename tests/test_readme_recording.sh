#!/bin/sh
# test_readme_recording.sh — the MAME package README's "record it" command, run as written on this host's release MAME against the romset that README's own build step writes, records a session the project replays frame for frame: work RAM identical on every frame, on the release binary and on the tree's source-built MAME, from an empty nvram (14z-158).
#
# WHAT: the 'record it' command of the MAME package README the generator writes NOW (#284),
#   the line for this host's os-arch, run as written on this host's release MAME against the
#   set the README's own build step writes, records a session the project replays frame for
#   frame — work RAM identical every frame on the release binary and on the source-built MAME,
#   from an EMPTY nvram — and the README prose agrees with the command; the generator and the gate
#   write that text the same on every host (#308).
# HOW: the MAME README rendered by tools/package_release.py + package_release_platforms.py from
#   $REL_TREE's manifest; its host line read out and run token for token from a player folder
#   built as the README says (`rompath/` written by the package's apply_release.py from $ROMDIR,
#   emulator/bin/<os-arch>/cps2 -> the release binary; headless flags and -noreadconfig
#   appended), the recording leg driven by replay 03, then
#   playback on both binaries; a no-playback leg must differ; controls start playback from a
#   used nvram and truncate the .inp.
# EXPECTS: the .inp valid and complete, both playbacks covering every frame with
#   byte-identical checksum logs, the idle leg departing at frame 300; the used nvram and
#   the truncated recording fail; no text open() without a named encoding and newline in the
#   render and reader steps; a missing recording log reaches a FAIL line.
# FOLLOWS: build/manifest/ emu/mame-patches/ tests/lib/controls.sh tests/lib/native_path.sh
#   tests/lua/ tests/replays/03_two_player_vs.rpl tools/build_release_emulators.sh
#   tools/setup_mame.sh tools/package_release.py tools/package_release_platforms.py
#   tools/package_release_readme.template.md tools/apply_release.py
#
# SHEET: none — an instrument, emulator, release or host check; no leg of our build compared with a reference set
#
# MUST-FIRE: perturbed-copy: used-nvram — a playback started from the nvram directory the recording run left behind (what a player's `nvram_fresh` holds once their session is over) must diverge from the recording and fail, so the comparison is proven able to fail and the README's EMPTY folder proven load-bearing
# MUST-FIRE: perturbed-copy: truncated-inp — the recording cut to half its input stream must fail the frame-count check, so a playback that stops early can never pass as the whole session
# MUST-FIRE: shadow-tool: unencoded-launcher — a copy of the generator whose PLAY.command write names no encoding (#308's cp1252 crash on ERIS) must be refused by the host-text guard on every host, so the guard is proven live in the render step where the Mac and Linux would never see cp1252
# MUST-FIRE: shadow-tool: crlf-argv — a copy of the gate's own command reader whose argv.txt write names no newline (#308's `vsavjw\r` on ERIS) must be refused by the same guard, so it is proven live in the reader as well
# MUST-FIRE: known-bad: rec-log-missing — a recording leg that left no checksum log must reach the gate's FAIL line (exit 1), never stop the gate silently under set -e (#308: exit 2 on ERIS, with no FAIL line)
#
# SINCE #308 (14z-207) the generator and the gate write text the same on every host: every text open() names its
# encoding (utf-8) and every text write its newline (LF), and both Python steps here run under a HOST-TEXT GUARD
# ($W/hosttext.py, written below) that refuses a text open() of this tree's code without them, on every host. ERIS
# (Windows, 14z-206) found three defects, all older than #284: the generator's unencoded writes (cp1252: a
# UnicodeEncodeError on PLAY.command's box-drawing characters), this gate's own CRLF argv.txt and readme.env (MAME
# was started as `cps2.exe $'vsavjw\r' …`), and a missing recording log stopping the gate with exit 2 under
# `set -eu` before its FAIL line.
#
# SINCE #284 (14z-206) the command is read from the MAME package README the generator writes, not the root
# README: the maintainer moved the procedure there (DECISIONS_HISTORY.md "Ruled 2026-10-15 (14z-201) — the
# recording procedure moves to the release package README"). The README writes one line per OS with the
# binary at its place in the package and `-rompath rompath` alone (#284's ERIS measurements: `cps2.exe` bare is
# "not recognized", `<…>` placeholders never start MAME, the dumps folder is not needed), so the gate picks this
# host's line and builds the set the way the README does — the build's own vsavjw.zip lacks the seven members
# the applier's standalone completion adds, and MAME would not load it from `rompath` alone.
#
# WHY IT EXISTS. README.md "Report a problem" tells a player to create two
# empty folders, run the release MAME with `-record`, and attach the `.inp`.
# That route was smoke-tested BY HAND at 14z-155 (record and playback exit 0),
# and [VSP-18] does not let a check stay manual. Exit 0 was also never the
# claim: the README promises the project can "replay your exact session,
# frame for frame", and a recording that plays back into a different game
# exits 0 just the same.
#
# WHAT IS RUN. The indented `emulator/bin/<os-arch>/cps2 vsavjw … -record …`
# line for this host is read OUT OF the rendered MAME package README and run
# token for token from a player folder the gate builds the way the README says
# (`rompath/` written by `apply_release.py --romdir $ROMDIR --out` with the
# README's own `--out`; the two named folders, empty). The only substitution:
# the binary becomes this host's release binary
# (release/emulators/mame/<os-arch>/, what that package directory holds). APPENDED to every leg, never
# replacing a README token: the headless flags, a private cfg/state sandbox,
# and `-noreadconfig` — MAME reads the user's own `mame.ini` (on macOS
# `~/Library/Application Support/mame/`) even under `-homepath`, and on the
# maintainer's Mac, measured 2026-09-15 with `-showconfig` against
# `-noreadconfig -showconfig`, that file sets `rompath` (a stale pre-rename
# build dir) and `verbose`. A gate must not inherit a host file. The README
# prose is checked against the command, so the two cannot drift apart: the
# two "empty folders" it names are the command's nvram and input
# directories, the file it says to attach is <input dir>/<record name>, and
# the rompath is apply_release.py's `--out` in the same README, and the README
# says each recording starts from an EMPTY nvram folder.
#
# The recording leg drives tests/lua/replay.lua with tests/replays/
# 03_two_player_vs.rpl (two credits, a 2-player fight, inputs through frame
# 4522), so the session has inputs throughout; MAME records the Lua-staged
# port values like any other input (measured 14z-158). ASSERTED:
#   1 RECORDING  replay.lua reached its END with no INPUT-VIOLATION; the
#                `.inp` exists in the input directory with MAME's `MAMEINP`
#                magic and sysname `vsavjw`; MAME wrote its nvram into the
#                README's nvram folder (so the option took effect).
#   2 PLAYBACK   on the release binary AND on the source-built MAME the
#                project plays reports with (the binary run_inp_guarded.sh
#                and test_inp_corpus use), each from an EMPTY nvram:
#                MAME's own "Total playback frames" covers every frame the
#                recording ran, and the per-frame work-RAM checksum log
#                (tests/lua/attract_checksum.lua) is byte-identical to the
#                recording leg's.
#   3 LIVENESS   the same run with NO playback differs from the recording, so
#                the recorded inputs are what the comparison reproduces
#                (measured 14z-158: an idle leg departs at frame 300, the
#                first coin).
# Measured 14z-158 (macOS arm64, merged-m18): the recording is 5,320 frames and
# the used nvram departs at frame 73; a half-length recording plays back 2,661
# frames. The cut control is not a checksum control on purpose: with
# 16_xemu_2p, whose inputs stop at frame 1362, half the stream reproduced
# every checksum, and only MAME's frame count saw the cut.
#
# Usage: ROMDIR=... [REL_TREE=release/merged-m23] [RELEASE_EMULATORS=release/emulators]
#        [MAME_BIN=~/.cache/vampire-saved/mame/cps2] [RPL=tests/replays/03_two_player_vs.rpl]
#        tests/test_readme_recording.sh
#   SKIPs when this host has no release MAME, no source-built MAME or no release tree.
# Runtime: ~50 s (six MAME legs; 47 s wall measured solo 14z-158), emulator tier.
set -eu
REPO="$(cd "$(dirname "$0")/.." && pwd)"; cd "$REPO"
. "$REPO/tests/lib/controls.sh"; vs_ctl_mode "$0"; MODE="${VS_CTL:-}"
refuse_or() { # <status word> <message>: a CONTROL mode that cannot run is REFUSED, never a pass
    if [ -n "$MODE" ]; then echo "REFUSED: CONTROL=$MODE — $2"; exit 3; fi
    echo "$1: $2"; [ "$1" = SKIP ] && exit 0; exit 1
}
[ -n "${ROMDIR:-}" ] || refuse_or FAIL "set ROMDIR"
[ -d "$ROMDIR" ] || refuse_or FAIL "ROMDIR does not exist: $ROMDIR"
ROMDIR="$(cd "$ROMDIR" && pwd)"
. "$REPO/tests/lib/native_path.sh"
# the os-arch spelling of tools/build_release_emulators.sh and test_release_binaries.sh
case "$(uname -s)" in
Darwin) HOSTOS=macos ;;
Linux)  HOSTOS=linux ;;
MINGW*|MSYS*|CYGWIN*) HOSTOS=windows ;;
*) HOSTOS="$(uname -s | tr 'A-Z' 'a-z')" ;;
esac
case "$(uname -m)" in arm64|aarch64) ARCH=arm64 ;; x86_64|amd64) ARCH=x86_64 ;; *) ARCH="$(uname -m)" ;; esac
EXESUF=""; [ "$HOSTOS" = windows ] && EXESUF=".exe"
OSARCH="$HOSTOS-$ARCH"
REL_TREE="${REL_TREE:-release/merged-m23}"
ROOT="${RELEASE_EMULATORS:-release/emulators}"
SRC="${MAME_BIN:-$HOME/.cache/vampire-saved/mame/cps2}"
RPL="${RPL:-tests/replays/03_two_player_vs.rpl}"
REL="$ROOT/mame/$OSARCH/cps2$EXESUF"
[ -x "$REL" ] || refuse_or SKIP "no release MAME at $REL for this host (tools/build_release_emulators.sh mame)"
[ -x "$SRC" ] || refuse_or SKIP "no source-built MAME at $SRC, the binary the project plays reports back on (tools/setup_mame.sh)"
[ -f "$REL_TREE/mame/manifest.json" ] && [ -f "$REL_TREE/mame/apply_release.py" ] || refuse_or SKIP "no MAME package at $REL_TREE/mame (manifest.json, apply_release.py)"
[ -f "$RPL" ] || refuse_or FAIL "no replay $RPL"
REL="$(cd "$(dirname "$REL")" && pwd)/cps2$EXESUF"
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT
PLAY="$W/player"
GUARD_DEAD=0   # a #308 control that did not fire (the verdict is FAIL, whatever the legs say)
echo "== the MAME package README's recording route on $OSARCH: release $REL, playback also on $SRC, package $REL_TREE/mame"

# ---- the HOST-TEXT GUARD (#308), imported by the render and the reader below: on every host, a text-mode open()
# from code outside Python's own library that names no encoding, or a text write that names no newline, is refused
# with a `HOST-TEXT:` line and exit 1 (no traceback: a traceback is a DIED run, never a verdict). On Windows such an
# open() is cp1252 and CRLF; on the Mac and Linux it is UTF-8 and LF, so without the guard only a Windows run sees it.
# It covers builtins.open (what the generator and the gate call), not io.open or pathlib.
cat > "$W/hosttext.py" <<'PY'
import builtins, os, sys
sys.stdout.reconfigure(encoding="utf-8", newline="\n")  # its own HOST-TEXT line too: per process (docs/platform/gotchas.md)
_open = builtins.open
_lib = tuple(os.path.realpath(p) + os.sep for p in {sys.prefix, sys.base_prefix, sys.exec_prefix})
def strict_open(file, mode="r", buffering=-1, encoding=None, errors=None, newline=None, closefd=True, opener=None):
    if "b" not in mode:
        f = sys._getframe(1)
        if not os.path.realpath(f.f_code.co_filename).startswith(_lib):
            why = ("names no encoding, so its bytes are the host's (cp1252 on Windows)" if encoding is None else
                   "names no newline, so it writes the host's line ends (CRLF on Windows)"
                   if newline is None and any(c in mode for c in "wax+") else "")
            if why:
                print("HOST-TEXT: %s:%d: open(%r, %r) %s" % (f.f_code.co_filename, f.f_lineno, file, mode, why), flush=True)
                os._exit(1)
    return _open(file, mode, buffering, encoding, errors, newline, closefd, opener)
builtins.open = strict_open
PY

# ---- 0. the command, read out of the MAME package README the generator writes now, checked against its own prose
render_readme() { # <tools dir> <package dir>: the MAME package README the generator writes from <package dir>/manifest.json
    python3 - "$W" "$1" "$2" <<'PY'
import json, os, sys
ht, tools, d = sys.argv[1:]
sys.path[:0] = [ht, tools, "tools"]
import hosttext                                   # the host-text guard (#308)
import package_release as pr, package_release_platforms as pp
pp.REPO = os.getcwd()                             # the gate runs from the tree; a shadow copy lives outside it
pp.binaries_side = lambda platform, edir: []      # text only: no binary read or copied
m = json.load(open(os.path.join(d, "manifest.json"), encoding="utf-8"))
open(os.path.join(d, "README.md"), "w", encoding="utf-8", newline="\n").write(pr.readme(None, m, 1, 1))   # the counts are prose only
pp.select_platform_text(d, "mame"); pp.emulator_side("mame", d, m["name"]); pp.fill_platform_text(d, "mame")
PY
}
shadow_unencoded() { # <dir>: a copy of the generator whose PLAY.command write names no encoding or newline (#308)
    mkdir -p "$1"
    python3 - "$1" <<'PY'
import sys
src = open("tools/package_release_platforms.py", encoding="utf-8").read()
old = 'with open(lp, "w", encoding="utf-8", newline="\\n") as f:'
if src.count(old) != 1:
    print("shadow: the PLAY.command write is not the line it was"); sys.exit(1)
open(sys.argv[1] + "/package_release_platforms.py", "w", encoding="utf-8", newline="\n").write(src.replace(old, 'with open(lp, "w") as f:'))
PY
}
mkdir -p "$W/pkg"; cp "$REL_TREE/mame/manifest.json" "$W/pkg/manifest.json"
GEN_TOOLS=tools
if vs_ctl_is unencoded-launcher; then
    shadow_unencoded "$W/shadow_gen" || { echo "REFUSED: CONTROL=unencoded-launcher — the shadow generator could not be written"; exit 3; }
    GEN_TOOLS="$W/shadow_gen"
fi
if ! render_readme "$GEN_TOOLS" "$W/pkg" > "$W/render.out" 2>&1; then
    cat "$W/render.out"
    if vs_ctl_is unencoded-launcher && grep -q '^HOST-TEXT: .*PLAY\.command.* names no encoding' "$W/render.out"; then
        echo "FAIL: the generator wrote host-dependent text (the host-text guard, #308)"; exit 1
    fi
    refuse_or FAIL "the generator did not render the MAME package README"
fi
vs_ctl_is unencoded-launcher && refuse_or FAIL "the shadow generator rendered the README: the host-text guard did not refuse its PLAY.command write"
cat "$W/render.out"
if shadow_unencoded "$W/ctl_gen" && mkdir -p "$W/pkg_ctl" && cp "$W/pkg/manifest.json" "$W/pkg_ctl/" \
   && ! render_readme "$W/ctl_gen" "$W/pkg_ctl" > "$W/c0.txt" 2>&1 && grep -q '^HOST-TEXT: .*PLAY\.command.* names no encoding' "$W/c0.txt"; then
    vs_ctl_fired unencoded-launcher "$(grep -m1 '^HOST-TEXT:' "$W/c0.txt" | sed 's/^HOST-TEXT: //')"
else
    vs_ctl_dead unencoded-launcher "the generator copy without its PLAY.command encoding was not refused: $(head -1 "$W/c0.txt" 2>/dev/null)" || true; GUARD_DEAD=1
fi
cat > "$W/readme_cmd.py" <<'PY'
import re, shlex, sys
import hosttext                                   # the host-text guard (#308); this script's own directory is on sys.path
sys.stdout.reconfigure(encoding="utf-8", newline="\n")  # a native Windows python writes CRLF (docs/platform/gotchas.md)
readme, osarch, envp, argvp = sys.argv[1:]
t = open(readme, encoding="utf-8").read()
exe = "cps2.exe" if osarch.startswith("windows") else "cps2"
want0 = "emulator/bin/%s/%s" % (osarch, exe)
binpath = lambda a: re.sub(r"^\.[\\/]", "", a).replace("\\", "/")
lines = [l for l in t.splitlines() if re.match(r"^(?: {4}|\t)", l) and " -record " in l]
mine = [l for l in lines if binpath(l.split()[0]) == want0]
if len(mine) != 1:
    print("FAIL: the MAME package README carries %d indented `%s ... -record ...` lines, expected exactly one (of %d record lines)" % (len(mine), want0, len(lines)))
    sys.exit(1)
line = mine[0].strip()
print("  README command: " + line)
bad = []
def need(ok, what):
    if not ok:
        bad.append(what)
need(not re.search(r"[\"'<>|&;]", line), "the line has no quote, placeholder or shell operator: a player types it as it is")
argv = line.split()          # no quotes (checked), so a Windows line's backslashes survive, as shlex.split would not
need(len(argv) > 1 and argv[1] == "vsavjw", "the command starts `%s vsavjw` (got %r)" % (want0, argv[:2]))
VALUED = ("-rompath", "-nvram_directory", "-input_directory", "-record")
opts, i = {}, 2
while i < len(argv):
    a = argv[i]
    if a in VALUED and i + 1 < len(argv):
        opts[a] = argv[i + 1]; i += 2
    else:
        i += 1
for k in VALUED:
    need(k in opts, "the command passes %s" % k)
if bad:
    print("\n".join("FAIL: README.md: " + b for b in bad)); sys.exit(1)
norm = lambda p: re.sub(r"^\.[\\/]", "", p)
m = re.search(r"apply_release\.py\b[^\n]*--out\s+(\S+)", t)
need(bool(m) and norm(m.group(1)) == norm(opts["-rompath"]),
     "the rompath is apply_release.py's --out in the same README (%r vs %r)" % (m and m.group(1), opts["-rompath"]))
m = re.search(r"empty folders?,\s*`([^`]+)`\s+and\s+`([^`]+)`", t)
need(bool(m) and {norm(m.group(1)), norm(m.group(2))} == {norm(opts["-nvram_directory"]), norm(opts["-input_directory"])},
     "the two empty folders the prose names are the command's nvram and input directories (%r vs %r)"
     % (m and m.groups(), (opts["-nvram_directory"], opts["-input_directory"])))
m = re.search(r"attach\s+`([^`]+)`", t)
need(bool(m) and norm(m.group(1)) == norm(opts["-input_directory"]) + "/" + opts["-record"],
     "the file the prose says to attach is <input dir>/<record name> (%r)" % (m and m.group(1)))
need(re.search(r"\*\*empty\*\*\s+`" + re.escape(norm(opts["-nvram_directory"])) + "`", t) is not None,
     "the prose says each recording starts from an EMPTY nvram folder (what the used-nvram control proves)")
need(opts["-record"].endswith(".inp"), "the record name ends in .inp")
if bad:
    print("\n".join("FAIL: README.md: " + b for b in bad)); sys.exit(1)
open(argvp, "w", encoding="utf-8", newline="\n").write("\n".join(argv[1:]) + "\n")   # LF: the shell reads it (#308)
q = shlex.quote
open(envp, "w", encoding="utf-8", newline="\n").write("OUTDIR=%s\nNVDIR=%s\nINDIR=%s\nINPNAME=%s\nROMPATH_ARG=%s\n" % (
    q(norm(opts["-rompath"])), q(norm(opts["-nvram_directory"])), q(norm(opts["-input_directory"])),
    q(opts["-record"]), q(opts["-rompath"])))
print("  ok: the prose agrees with the command (folders, attachment, empty nvram, apply_release --out)")
PY
shadow_crlf() { # <dir>: a copy of the reader whose argv.txt write names no newline (#308's `vsavjw\r`)
    mkdir -p "$1"; cp "$W/hosttext.py" "$1/"
    python3 - "$W/readme_cmd.py" "$1/readme_cmd.py" <<'PY'
import sys
src = open(sys.argv[1], encoding="utf-8").read()
old = 'open(argvp, "w", encoding="utf-8", newline="\\n")'
if src.count(old) != 1:
    print("shadow: the argv.txt write is not the line it was"); sys.exit(1)
open(sys.argv[2], "w", encoding="utf-8", newline="\n").write(src.replace(old, 'open(argvp, "w", encoding="utf-8")'))
PY
}
READER="$W/readme_cmd.py"
if vs_ctl_is crlf-argv; then
    shadow_crlf "$W/shadow_rd" || { echo "REFUSED: CONTROL=crlf-argv — the shadow reader could not be written"; exit 3; }
    READER="$W/shadow_rd/readme_cmd.py"
fi
if ! python3 "$READER" "$W/pkg/README.md" "$OSARCH" "$W/readme.env" "$W/argv.txt" > "$W/reader.out" 2>&1; then
    cat "$W/reader.out"
    grep -q '^HOST-TEXT:' "$W/reader.out" && { echo "FAIL: the gate's command reader wrote host-dependent text (the host-text guard, #308)"; exit 1; }
    grep -q '^FAIL' "$W/reader.out" || refuse_or FAIL "the README command reader stopped without a verdict"
    exit 1
fi
vs_ctl_is crlf-argv && refuse_or FAIL "the shadow reader wrote argv.txt: the host-text guard did not refuse it"
cat "$W/reader.out"
if shadow_crlf "$W/ctl_rd" && ! python3 "$W/ctl_rd/readme_cmd.py" "$W/pkg/README.md" "$OSARCH" "$W/ctl_rd/env" "$W/ctl_rd/argv.txt" > "$W/c00.txt" 2>&1 \
   && grep -q '^HOST-TEXT: .*argv\.txt.* names no newline' "$W/c00.txt"; then
    vs_ctl_fired crlf-argv "$(grep -m1 '^HOST-TEXT:' "$W/c00.txt" | sed 's/^HOST-TEXT: //')"
else
    vs_ctl_dead crlf-argv "the reader copy without its argv.txt newline was not refused: $(head -1 "$W/c00.txt" 2>/dev/null)" || true; GUARD_DEAD=1
fi
. "$W/readme.env"
mkdir -p "$PLAY/$NVDIR" "$PLAY/$INDIR"
# the set, built the way the README's step 1 says: the package's applier, the player's dumps, the README's --out
python3 "$REL_TREE/mame/apply_release.py" --romdir "$(native_path "$ROMDIR")" --out "$(native_path "$PLAY/$OUTDIR")" > "$W/apply.out" 2>&1 \
    || { tail -3 "$W/apply.out"; refuse_or FAIL "the package's apply_release.py did not build the set"; }
grep -q '^OK:' "$W/apply.out" || { tail -3 "$W/apply.out"; refuse_or FAIL "apply_release.py printed no OK: line"; }
echo "  ok: the set built by the package's applier into $OUTDIR/ ($(grep -m1 '^OK:' "$W/apply.out"))"

run_mame() { # <bin> <sandbox> <lua> <mame output> <args...> — from the player folder, headless flags APPENDED
    _bin="$1"; _sb="$2"; _lua="$3"; _out="$4"; shift 4
    mkdir -p "$_sb/cfg" "$_sb/diff" "$_sb/snap" "$_sb/sta"
    (cd "$PLAY" && SDL_VIDEODRIVER=dummy "$_bin" "$@" -noreadconfig \
        -video none -sound none -nothrottle -skip_gameinfo \
        -keyboardprovider none -mouseprovider none -joystickprovider none -lightgunprovider none \
        -cfg_directory "$(native_path "$_sb/cfg")" -diff_directory "$(native_path "$_sb/diff")" \
        -snapshot_directory "$(native_path "$_sb/snap")" -state_directory "$(native_path "$_sb/sta")" \
        -homepath "$(native_path "$_sb")" -autoboot_script "$(native_path "$REPO/tests/lua/$_lua")" \
        > "$_out" 2>&1 < /dev/null) || true
}
play_leg() { # <label> <bin> <nvram dir> [<input dir>] — no input dir = the same run with no playback
    _l="$1"; _b="$2"; _nv="$3"; _id="${4:-}"
    set -- vsavjw -rompath "$ROMPATH_ARG" -nvram_directory "$(native_path "$_nv")"
    [ -n "$_id" ] && set -- "$@" -input_directory "$(native_path "$_id")" -playback "$INPNAME"
    ( export FRAMES="$N" CHECKSUM_OUT="$(native_path "$W/$_l.log")"
      run_mame "$_b" "$W/sb_$_l" attract_checksum.lua "$W/$_l.out" "$@" )
}
first_diff() { diff "$W/$1" "$W/$2" | awk '/^[<>] [0-9]/{print $2; exit}'; }
rec_end() { # <checksum log>: the frame of its END line, or nothing; a missing log is nothing, never an awk error that stops the gate under set -e before its FAIL line (#308)
    [ -f "$1" ] || return 0
    awk '/^END /{print $2}' "$1"
}

# THE TWO PERTURBATIONS — one function each, called by the mode and by the control
nvram_for_playback() { # <dst> <fresh|used>: an EMPTY directory, or the one the recording run left behind
    if [ "$2" = used ]; then cp -R "$PLAY/$NVDIR" "$1"; else mkdir -p "$1"; fi
}
truncate_inp() { # <dst dir>: the recording with half its input stream (MAME 0.288: a 0x40 header, then zlib)
    mkdir -p "$1"
    python3 - "$PLAY/$INDIR/$INPNAME" "$1/$INPNAME" <<'PY'
import sys, zlib
src, dst = sys.argv[1:]
b = open(src, "rb").read()
if b[:8] != b"MAMEINP\x00":
    print("truncate_inp: no MAMEINP magic"); sys.exit(1)
raw = zlib.decompress(b[0x40:])
open(dst, "wb").write(b[:0x40] + zlib.compress(raw[:len(raw) // 2], 6))
PY
}
check_playback() { # <label>: prints FAIL lines, returns 1 on any
    _bad=0
    grep -q "^END $N\$" "$W/$1.log" 2>/dev/null \
        || { echo "FAIL: $1 did not reach frame $N (last line: $(tail -1 "$W/$1.log" 2>/dev/null))"; _bad=1; }
    _pb="$(grep -o 'Total playback frames: [0-9]*' "$W/$1.out" | tail -1 | awk '{print $4}')"
    if [ -z "$_pb" ]; then
        echo "FAIL: $1: MAME reported no playback ($(tail -1 "$W/$1.out"))"; _bad=1
    elif [ "$_pb" -lt "$N" ]; then
        echo "FAIL: $1: MAME played back $_pb recorded frames, fewer than the $N the recording ran"; _bad=1
    fi
    cmp -s "$W/rec.log" "$W/$1.log" \
        || { echo "FAIL: $1: work RAM differs from the recording from frame $(first_diff rec.log "$1.log")"; _bad=1; }
    return $_bad
}

# ---- 1. the recording, token for token from the README
set --
while IFS= read -r a; do set -- "$@" "$a"; done < "$W/argv.txt"
( export REPLAY="$(native_path "$REPO/$RPL")" CHECKSUM_OUT="$(native_path "$W/rec.log")"
  run_mame "$REL" "$W/sb_rec" replay.lua "$W/rec.out" "$@" )
vs_ctl_is rec-log-missing && rm -f "$W/rec.log"   # the mode: the recording leg left no checksum log
N="$(rec_end "$W/rec.log")"
[ -n "$N" ] && [ "$N" -gt 0 ] 2>/dev/null \
    || { echo "FAIL: the recording leg did not reach its END (see the MAME output)"; tail -3 "$W/rec.out"; echo "FAIL: test_readme_recording ($OSARCH)"; exit 1; }
# the control: the same function, in a shell of its own under set -eu (where its status is tested by nobody, as at the
# call above), on a log that does not exist, must hand back an empty frame and exit 0, so the FAIL line is reached
if sh -eu -c "$(sed -n '/^rec_end() {/,/^}/p' "$REPO/tests/test_readme_recording.sh")"'
N="$(rec_end "$1")"; echo "rec_end=[$N]"' rec_end "$W/no_such_rec.log" > "$W/c3.txt" 2>&1 && grep -qx 'rec_end=\[\]' "$W/c3.txt"; then
    vs_ctl_fired rec-log-missing "a recording leg with no checksum log reads as no END frame under set -eu, so the gate reaches its FAIL line"
else
    vs_ctl_dead rec-log-missing "the END read stopped the shell or read a frame from a missing log: $(head -1 "$W/c3.txt")" || true; GUARD_DEAD=1
fi
fail=0
grep -q '^INPUT-VIOLATION' "$W/rec.log" && { echo "FAIL: the recording leg saw input from outside its script: $(grep -m1 '^INPUT-VIOLATION' "$W/rec.log")"; fail=1; }
if python3 - "$PLAY/$INDIR/$INPNAME" <<'PY'
import sys
sys.stdout.reconfigure(encoding="utf-8", newline="\n")
try:
    b = open(sys.argv[1], "rb").read(0x40)
except OSError:
    print("FAIL: no recording at %s" % sys.argv[1]); sys.exit(1)
if b[:8] != b"MAMEINP\x00" or b[0x14:0x20].rstrip(b"\x00") != b"vsavjw":
    print("FAIL: %s is not a MAME recording of vsavjw (magic %r, sysname %r)" % (sys.argv[1], b[:8], b[0x14:0x20])); sys.exit(1)
PY
then :; else fail=1; fi
[ -n "$(ls -A "$PLAY/$NVDIR" 2>/dev/null)" ] || { echo "FAIL: MAME wrote nothing into the README's nvram folder $NVDIR"; fail=1; }
[ "$fail" = 0 ] && echo "  ok: recorded $N frames into $INDIR/$INPNAME ($(wc -c < "$PLAY/$INDIR/$INPNAME" | tr -d ' ') B), nvram written into $NVDIR"
[ "$fail" = 0 ] || { echo "FAIL: test_readme_recording ($OSARCH)"; exit 1; }

# ---- 2. the playbacks the project would run, each from an empty nvram
NV_KIND=fresh; vs_ctl_is used-nvram && NV_KIND=used
IN_MAIN="$PLAY/$INDIR"
if vs_ctl_is truncated-inp; then
    truncate_inp "$W/inp_mode" || { echo "REFUSED: CONTROL=truncated-inp — the recording could not be cut"; exit 3; }
    IN_MAIN="$W/inp_mode"
fi
nvram_for_playback "$W/nv_rel" "$NV_KIND"; play_leg pb_rel "$REL" "$W/nv_rel" "$IN_MAIN"
nvram_for_playback "$W/nv_src" "$NV_KIND"; play_leg pb_src "$SRC" "$W/nv_src" "$IN_MAIN"
for leg in pb_rel pb_src; do
    if check_playback "$leg"; then
        echo "  ok: $leg reproduced all $N frames of work RAM ($(grep -o 'Total playback frames: [0-9]*' "$W/$leg.out" | tail -1))"
    else
        fail=1
    fi
done

# ---- 3. liveness: without the playback the session is a different game
mkdir -p "$W/nv_idle"; play_leg idle "$REL" "$W/nv_idle"
if cmp -s "$W/rec.log" "$W/idle.log"; then
    echo "FAIL: the run with no playback matches the recording — the recorded inputs changed nothing, so the comparison proves nothing"; fail=1
else
    echo "  ok: with no playback the session departs from the recording at frame $(first_diff rec.log idle.log)"
fi

# ---- must-fire controls
nvram_for_playback "$W/nv_used" used; play_leg ctl_used "$REL" "$W/nv_used" "$PLAY/$INDIR"
if check_playback ctl_used > "$W/c1.txt"; then
    vs_ctl_dead used-nvram "a playback from the used nvram reproduced the recording" || true; fail=1
elif grep -q 'work RAM differs' "$W/c1.txt" && ! grep -q 'fewer than' "$W/c1.txt"; then
    vs_ctl_fired used-nvram "$(grep -m1 'work RAM differs' "$W/c1.txt" | sed 's/^FAIL: //')"
else
    vs_ctl_dead used-nvram "failed for another reason: $(head -1 "$W/c1.txt")" || true; fail=1
fi
if truncate_inp "$W/inp_ctl"; then
    mkdir -p "$W/nv_trunc"; play_leg ctl_trunc "$REL" "$W/nv_trunc" "$W/inp_ctl"
    if check_playback ctl_trunc > "$W/c2.txt"; then
        vs_ctl_dead truncated-inp "a half-length recording passed as the whole session" || true; fail=1
    elif grep -q 'fewer than' "$W/c2.txt"; then
        vs_ctl_fired truncated-inp "$(grep -m1 'fewer than' "$W/c2.txt" | sed 's/^FAIL: //')"
    else
        vs_ctl_dead truncated-inp "failed for another reason: $(head -1 "$W/c2.txt")" || true; fail=1
    fi
else
    vs_ctl_dead truncated-inp "the recording could not be cut" || true; fail=1
fi

[ "$fail" = 0 ] && [ "$GUARD_DEAD" = 0 ] && echo "PASS: test_readme_recording ($OSARCH)" || { echo "FAIL: test_readme_recording ($OSARCH)"; exit 1; }
