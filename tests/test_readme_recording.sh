#!/bin/sh
# test_readme_recording.sh — the README's "record it on MAME" command, run as written on this host's release MAME against the current merged romset, records a session the project replays frame for frame: work RAM identical on every frame, on the release binary and on the tree's source-built MAME, from an empty nvram (14z-158).
#
# WHAT: the README's 'record it on MAME' command, run as written on this host's release MAME
#   against the merged romset, records a session the project replays frame for frame — work
#   RAM identical every frame on the release binary and on the source-built MAME, from an
#   EMPTY nvram — and the README prose agrees with the command.
# HOW: the indented command read out of README.md and run token for token from a player
#   folder built as the README says (cps2 -> the release binary, the dumps path -> $ROMDIR;
#   headless flags and -noreadconfig appended), the recording leg driven by replay 03, then
#   playback on both binaries; a no-playback leg must differ; controls start playback from a
#   used nvram and truncate the .inp.
# EXPECTS: the .inp valid and complete, both playbacks covering every frame with
#   byte-identical checksum logs, the idle leg departing at frame 300; the used nvram and
#   the truncated recording fail.
# FOLLOWS: build/manifest/ emu/mame-patches/ tests/lib/controls.sh tests/lib/native_path.sh
#   tests/lua/ tests/replays/03_two_player_vs.rpl tools/build_release_emulators.sh
#   tools/setup_mame.sh
#
# MUST-FIRE: perturbed-copy: used-nvram — a playback started from the nvram directory the recording run left behind (what a player's `nvram_fresh` holds once their session is over) must diverge from the recording and fail, so the comparison is proven able to fail and the README's EMPTY folder proven load-bearing
# MUST-FIRE: perturbed-copy: truncated-inp — the recording cut to half its input stream must fail the frame-count check, so a playback that stops early can never pass as the whole session
#
# WHY IT EXISTS. README.md "Report a problem" tells a player to create two
# empty folders, run the release MAME with `-record`, and attach the `.inp`.
# That route was smoke-tested BY HAND at 14z-155 (record and playback exit 0),
# and [VSP-18] does not let a check stay manual. Exit 0 was also never the
# claim: the README promises the project can "replay your exact session,
# frame for frame", and a recording that plays back into a different game
# exits 0 just the same.
#
# WHAT IS RUN. The indented `cps2 vsavjw … -record …` line is read OUT OF
# README.md and run token for token from a player folder the gate builds the
# way the README says (`rompath/` holding the merged romset's `vsavjw.zip`,
# where apply_release.py writes it; the two named folders, empty). The only
# substitutions: `cps2` becomes this host's release binary
# (release/emulators/mame/<os-arch>/), and the rompath's
# `/path/to/your/dumps` becomes $ROMDIR. APPENDED to every leg, never
# replacing a README token: the headless flags, a private cfg/state sandbox,
# and `-noreadconfig` — MAME reads the user's own `mame.ini` (on macOS
# `~/Library/Application Support/mame/`) even under `-homepath`, and on the
# maintainer's Mac, measured 2026-09-15 with `-showconfig` against
# `-noreadconfig -showconfig`, that file sets `rompath` (a stale pre-rename
# build dir) and `verbose`. A gate must not inherit a host file. The README
# prose is checked against the command, so the two cannot drift apart: the
# two "empty folders" it names are the command's nvram and input
# directories, the file it says to attach is <input dir>/<record name>, and
# the rompath's first element is apply_release.py's `--out`.
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
# Usage: ROMDIR=... [MERGED=build/m3b_merged27] [RELEASE_EMULATORS=release/emulators]
#        [MAME_BIN=~/.cache/vampire-saved/mame/cps2] [RPL=tests/replays/03_two_player_vs.rpl]
#        tests/test_readme_recording.sh
#   SKIPs when this host has no release MAME, no source-built MAME or no romset.
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
MERGED="${MERGED:-build/m3b_merged27}"
ROOT="${RELEASE_EMULATORS:-release/emulators}"
SRC="${MAME_BIN:-$HOME/.cache/vampire-saved/mame/cps2}"
RPL="${RPL:-tests/replays/03_two_player_vs.rpl}"
REL="$ROOT/mame/$OSARCH/cps2$EXESUF"
[ -x "$REL" ] || refuse_or SKIP "no release MAME at $REL for this host (tools/build_release_emulators.sh mame)"
[ -x "$SRC" ] || refuse_or SKIP "no source-built MAME at $SRC, the binary the project plays reports back on (tools/setup_mame.sh)"
[ -f "$MERGED/rompath/vsavjw.zip" ] || refuse_or SKIP "no romset at $MERGED/rompath/vsavjw.zip"
[ -f "$RPL" ] || refuse_or FAIL "no replay $RPL"
REL="$(cd "$(dirname "$REL")" && pwd)/cps2$EXESUF"
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT
PLAY="$W/player"
echo "== the README recording route on $OSARCH: release $REL, playback also on $SRC, romset $MERGED"

# ---- 0. the command, read out of README.md and checked against its own prose
python3 - "$REPO/README.md" "$(native_path "$ROMDIR")" "$W/readme.env" "$W/argv.txt" <<'PY'
import re, shlex, sys
sys.stdout.reconfigure(encoding="utf-8", newline="\n")  # a native Windows python writes CRLF (docs/platform/gotchas.md)
readme, romdir, envp, argvp = sys.argv[1:]
t = open(readme, encoding="utf-8").read()
cands = [l for l in t.splitlines() if re.match(r"^(?: {4}|\t)\s*cps2(?:\.exe)?\s", l) and " -record " in l]
if len(cands) != 1:
    print("FAIL: README.md carries %d indented `cps2 ... -record ...` command lines, expected exactly one" % len(cands))
    sys.exit(1)
argv = shlex.split(cands[0])
print("  README command: " + cands[0].strip())
bad = []
def need(ok, what):
    if not ok:
        bad.append(what)
need(argv[0] in ("cps2", "cps2.exe") and len(argv) > 1 and argv[1] == "vsavjw",
     "the command starts `cps2 vsavjw` (got %r)" % argv[:2])
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
norm = lambda p: p[2:] if p.startswith("./") else p
elems = opts["-rompath"].split(";")
ph = [e for e in elems if "path/to/your/dumps" in e]
need(len(ph) == 1, "the rompath carries one `/path/to/your/dumps` placeholder (got %r)" % elems)
m = re.search(r"apply_release\.py\b[^\n]*--out\s+(\S+)", t)
need(bool(m) and norm(m.group(1)) == norm(elems[0]),
     "the rompath's first element is apply_release.py's --out (%r vs %r)" % (m and m.group(1), elems[0]))
m = re.search(r"empty folders?,\s*`([^`]+)`\s+and\s+`([^`]+)`", t)
need(bool(m) and {norm(m.group(1)), norm(m.group(2))} == {norm(opts["-nvram_directory"]), norm(opts["-input_directory"])},
     "the two empty folders the prose names are the command's nvram and input directories (%r vs %r)"
     % (m and m.groups(), (opts["-nvram_directory"], opts["-input_directory"])))
m = re.search(r"attach\s+`([^`]+)`", t)
need(bool(m) and norm(m.group(1)) == norm(opts["-input_directory"]) + "/" + opts["-record"],
     "the file the prose says to attach is <input dir>/<record name> (%r)" % (m and m.group(1)))
need(opts["-record"].endswith(".inp"), "the record name ends in .inp")
if bad:
    print("\n".join("FAIL: README.md: " + b for b in bad)); sys.exit(1)
rp = ";".join(romdir if e in ph else e for e in elems)
out = []
for a in argv[1:]:
    out.append(rp if a == opts["-rompath"] else a)
open(argvp, "w").write("\n".join(out) + "\n")
q = shlex.quote
open(envp, "w").write("OUTDIR=%s\nNVDIR=%s\nINDIR=%s\nINPNAME=%s\nROMPATH_ARG=%s\n" % (
    q(norm(elems[0])), q(norm(opts["-nvram_directory"])), q(norm(opts["-input_directory"])),
    q(opts["-record"]), q(rp)))
print("  ok: the prose agrees with the command (folders, attachment, apply_release --out)")
PY
. "$W/readme.env"
mkdir -p "$PLAY/$OUTDIR" "$PLAY/$NVDIR" "$PLAY/$INDIR"
cp "$MERGED/rompath/vsavjw.zip" "$PLAY/$OUTDIR/vsavjw.zip"

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
N="$(awk '/^END /{print $2}' "$W/rec.log" 2>/dev/null)"
[ -n "$N" ] && [ "$N" -gt 0 ] 2>/dev/null \
    || { echo "FAIL: the recording leg did not reach its END (see the MAME output)"; tail -3 "$W/rec.out"; echo "FAIL: test_readme_recording ($OSARCH)"; exit 1; }
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

[ "$fail" = 0 ] && echo "PASS: test_readme_recording ($OSARCH)" || { echo "FAIL: test_readme_recording ($OSARCH)"; exit 1; }
