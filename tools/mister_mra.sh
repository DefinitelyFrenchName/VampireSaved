#!/bin/sh
# mister_mra.sh — generate a core's MRAs (and, on request, the MiSTer `.rom`
# download image) from the pinned jtcores fork, reproducibly and without
# touching anything outside a scratch tree. (14z-107 (5), MiSTer slice D0.)
#
# WHY IT EXISTS. `jtframe mra` looks its ROM zips up at a HARD-CODED
# `$HOME/.mame/roms/<name>.zip` (`modules/jtframe/src/jtframe/mra/mrazip.go:23`),
# which makes the tool's output a function of the invoking user's home
# directory. Two consequences this script exists to remove:
#
#   1. THE TWO LEGS NEED DIFFERENT ZIP SETS. The WIDE romset is a CLONE set:
#      `vsavjw.zip` carries the program, the Z80, group C, the QSound
#      extension AND (since 14z-112) the patched group-A members
#      `vm3.13m/15m/17m/19m`; everything else comes from the PRISTINE parent.
#      **CORRECTED 14z-112: this used to say the legs need DIFFERENT
#      `vsav.zip` FILES, because the build packed a PATCHED parent.** That is
#      precisely what stopped a MiSTer SD card from carrying this profile and
#      stock Vampire Savior together — `games/mame/vsav.zip` can only be one
#      file, and a stock MRA pointed at the patched one got wrong art
#      SILENTLY. Both legs now share the pristine dump. The private `$HOME`
#      staging stays, because jtframe still hard-codes its lookup path.
#   2. Writing into the real `~/.mame/roms` is global mutable state shared
#      with every other tool on the machine. Nothing here does that.
#
# It also keeps the pinned submodule pristine: jtframe writes `release/`,
# `rom/` and `cores/<core>/ver/setnames.txt` into $JTROOT, so $JTROOT is a
# SCRATCH CLONE of the fork, never `emu/jtcores` (the same rule
# tools/run_sim_jtcps2.sh follows, and the same JTSIM_SCRATCH variable).
#
# RULE 7. `.rom` files are ROM content: they are written into the scratch
# clone, and copied out only to an --out directory OUTSIDE this repo, which
# the script enforces. MRAs are XML metadata (names, CRCs, offsets) and may
# be copied anywhere.
#
# Usage:
#   tools/mister_mra.sh --core cps2w [options]
#     --core NAME          cps2 | cps2w              (default cps2w)
#     --wide BUILD_DIR     stage BUILD_DIR/rompath/vsavjw.zip beside the
#                          PRISTINE $ROMDIR/vsav.zip, i.e. build the WIDE
#                          leg (since 14z-112 a build packs no vsav.zip of
#                          its own; a pre-14z-112 build that still has one
#                          is used with a loud NOTE). Without --wide the
#                          pristine $ROMDIR sets are staged (the stock leg).
#     --no-rom             pass `jtframe mra -n`: MRAs only, no .rom, no zip
#                          reads at all. This is the ROM-FREE mode — the MRA
#                          XML is then a pure function of doc/mame.xml plus
#                          the core's TOML, and `md5="None"`.
#     --out DIR            copy release/mra (and rom/*.rom unless --no-rom)
#                          here. Must be outside the repo when .rom files are
#                          produced.
#     --toml FILE          substitute FILE for cores/<core>/cfg/mame2mra.toml
#                          in the scratch clone for this run only, restoring
#                          it afterwards. This is how the gate's must-fire
#                          controls perturb the mapping without editing the
#                          pinned submodule.
#     --xml FILE           likewise for doc/mame.xml.
#     --quiet              suppress jtframe's own output
#   env ROMDIR=...         the reference-set directory (required)
#   --ensure-scratch       clone / pin / HEAL the scratch clone and exit — ROM-free;
#                          what run_sim_jtcps2.sh calls, and the reaper ground truth
#   env JTSIM_SCRATCH=...  where the scratch clone lives (default
#                          ${TMPDIR:-/tmp}/vampire-saved-jtsim)
set -eu
REPO="$(cd "$(dirname "$0")/.." && pwd)"

CORE=cps2w; WIDE=""; NOROM=0; OUT=""; TOML=""; XML=""; QUIET=0; ENSURE=0
while [ $# -gt 0 ]; do
    case "$1" in
    --ensure-scratch) ENSURE=1 ;;   # clone / pin / HEAL the scratch, then exit (ROM-free)
    --core)    shift; CORE="${1:?--core needs a name}" ;;
    --wide)    shift; WIDE="${1:?--wide needs a build dir}" ;;
    --no-rom)  NOROM=1 ;;
    --out)     shift; OUT="${1:?--out needs a dir}" ;;
    --toml)    shift; TOML="${1:?--toml needs a file}" ;;
    --xml)     shift; XML="${1:?--xml needs a file}" ;;
    --quiet)   QUIET=1 ;;
    -h|--help) sed -n '2,60p' "$0"; exit 0 ;;
    *) echo "unknown argument '$1' (try --help)" >&2; exit 2 ;;
    esac
    shift
done
if [ "$ENSURE" = 1 ]; then ROMDIR="${ROMDIR:-}"; else
ROMDIR="${ROMDIR:?set ROMDIR to the reference-set directory}"
ROMDIR="$(CDPATH= cd "$ROMDIR" && pwd)"
fi
say() { [ "$QUIET" = 1 ] || echo "[mister_mra] $*"; }

SCRATCH="${JTSIM_SCRATCH:-${TMPDIR:-/tmp}/vampire-saved-jtsim}"
case "$SCRATCH" in
    "$REPO"|"$REPO"/*) echo "REFUSING: JTSIM_SCRATCH is inside the repo ($SCRATCH)." >&2
                       echo "  jtframe mra writes release/ and rom/ into it." >&2; exit 2 ;;
esac
PIN="$(sed -n 's/^PINNED="\([0-9a-f]*\)".*/\1/p' "$REPO/tools/setup_jtcores.sh")"
[ -n "$PIN" ] || { echo "cannot read PINNED from tools/setup_jtcores.sh" >&2; exit 1; }

# ------------------------------------------------------------------ 1. clone
# (`-e`, not `-d`, for the submodule: in an initialised SUBMODULE .git is a
# gitfile, not a directory — measured 14z-107 (3).)
clone_scratch() {
    [ -e "$REPO/emu/jtcores/.git" ] || {
        echo "emu/jtcores not initialised — run tools/setup_jtcores.sh" >&2; exit 1; }
    say "cloning the fork into $SCRATCH"
    rm -rf "$SCRATCH"
    git clone --quiet "$REPO/emu/jtcores" "$SCRATCH"
    git -C "$SCRATCH" remote set-url origin \
        "$(git -C "$REPO/emu/jtcores" remote get-url origin)"
}
pin_scratch() {  # the LOCAL submodule is fetched first: fork commits are local-only
                 # until the maintainer authorises a push (measured 14z-107 (6))
    if [ "$(git -C "$SCRATCH" rev-parse HEAD 2>/dev/null)" != "$PIN" ]; then
        say "checking out the pin $PIN in the scratch clone"
        git -C "$SCRATCH" fetch --quiet "$REPO/emu/jtcores" \
            '+refs/heads/*:refs/remotes/local/*' 2>/dev/null || true
        git -C "$SCRATCH" fetch --quiet origin 2>/dev/null || true
        git -C "$SCRATCH" checkout --quiet "$PIN" 2>/dev/null
    fi
}
[ -d "$SCRATCH/.git" ] || clone_scratch
pin_scratch || { say "scratch clone cannot reach the pin $PIN — re-cloning"; clone_scratch; pin_scratch || {
    echo "scratch clone cannot reach the pin $PIN even after a re-clone" >&2; exit 1; }; }
# ---------------------------------------------------- 1b. HEAL (14z-133b)
# The macOS tmp reaper deletes files under $TMPDIR piecemeal by age, so a
# scratch clone can keep its .git and lose most of its TRACKED FILES (4,099 of
# 4,244 on 2026-09-05; `cores/cps2/cfg/macros.def` at 14z-111). `.git` present
# is therefore not "clone usable". Git knows exactly which tracked files are
# missing and the object store usually survives, so restore from it; if the
# store was reaped too, re-clone. docs/platform/gotchas.md "the macOS tmp
# reaper hollows out the jtsim scratch clone"; tests/test_jtsim_scratch_heal.sh.
_missing="$(git -C "$SCRATCH" ls-files --deleted 2>/dev/null | wc -l | tr -d ' ')"
if [ "${_missing:-1}" != 0 ]; then
    say "scratch clone is HOLLOW ($_missing tracked files missing — the tmp reaper); restoring from its object store"
    git -C "$SCRATCH" checkout --quiet -- . 2>/dev/null || true
    if [ "$(git -C "$SCRATCH" ls-files --deleted 2>/dev/null | wc -l | tr -d ' ')" != 0 ]; then
        say "the object store is hollow too — re-cloning"
        clone_scratch; pin_scratch || { echo "re-clone cannot reach the pin $PIN" >&2; exit 1; }
    fi
fi
if [ "$ENSURE" = 1 ]; then say "scratch clone ready at $PIN"; exit 0; fi

# ------------------------------------------------------- 2. the private HOME
STAGE="$SCRATCH/.mrahome"
rm -rf "$STAGE"; mkdir -p "$STAGE/.mame/roms"
link() { # link <name in the staged roms dir> <absolute source>
    [ -f "$2" ] || { echo "missing $2" >&2; exit 1; }
    ln -s "$2" "$STAGE/.mame/roms/$1"
    say "staged $1 -> $2"
}
if [ "$NOROM" = 0 ]; then
    link qsound.zip "$ROMDIR/qsound_hle.zip"
    if [ -n "$WIDE" ]; then
        RP="$WIDE/rompath"; [ -d "$RP" ] || RP="$REPO/$WIDE/rompath"
        [ -f "$RP/vsavjw.zip" ] || {
            echo "no $RP/vsavjw.zip — that build has no WIDE romset" >&2; exit 1; }
        link vsavjw.zip "$(CDPATH= cd "$RP" && pwd)/vsavjw.zip"
        # PRISTINE parent since 14z-112: the patched group-A members moved
        # INSIDE vsavjw.zip, so both legs share one vsav.zip and a MiSTer SD
        # card can carry this profile and stock Vampire Savior at once. A
        # build that still packs its own vsav.zip is pre-14z-112 — use it,
        # but say so, because its MRA cannot coexist with a stock one.
        if [ -f "$RP/vsav.zip" ]; then
            echo "  NOTE: $RP/vsav.zip exists (pre-14z-112 packaging) — using it;" >&2
            echo "        this bundle's vsav.zip will BREAK stock Vampire Savior." >&2
            link vsav.zip "$(CDPATH= cd "$RP" && pwd)/vsav.zip"
        else
            link vsav.zip "$ROMDIR/vsav.zip"
        fi
        link vsavj.zip  "$ROMDIR/vsavj.zip"
    else
        link vsav.zip  "$ROMDIR/vsav.zip"
        link vsavj.zip "$ROMDIR/vsavj.zip"
    fi
fi

# ------------------------------------------------------------ 3. environment
JTROOT="$SCRATCH"; JTFRAME="$JTROOT/modules/jtframe"; CORES="$JTROOT/cores"
ROM="$JTROOT/rom"; RLS="$JTROOT/release"; JTBIN="$RLS"; MRA="$RLS/mra"
POCKET="$JTFRAME/target/pocket"; MODULES="$JTROOT/modules"; MAME="$JTROOT/doc/mame"
export JTROOT JTFRAME CORES ROM RLS JTBIN MRA POCKET MODULES MAME
JTF="$JTFRAME/src/jtframe/jtframe"
if [ ! -x "$JTF" ]; then
    command -v go >/dev/null 2>&1 || { echo "go not found (brew install go)" >&2; exit 1; }
    say "building the jtframe Go tool"
    ( cd "$JTFRAME/src/jtframe" && go build -o jtframe . )
fi

# ------------------------------------------- 4. optional perturbed inputs
restore() {
    git -C "$SCRATCH" checkout --quiet -- "cores/$CORE/cfg/mame2mra.toml" 2>/dev/null || true
    git -C "$SCRATCH" checkout --quiet -- "doc/mame.xml" 2>/dev/null || true
}
trap restore EXIT INT TERM
# `if`, not `[ … ] && { … }`: an AND-OR list whose test fails is a portability
# trap under `set -e` (its behaviour differs between shells), and this is the
# one place a silent early exit would leave the scratch clone perturbed.
if [ -n "$TOML" ]; then
    cp "$TOML" "$SCRATCH/cores/$CORE/cfg/mame2mra.toml"; say "TOML substituted from $TOML"
fi
if [ -n "$XML" ]; then
    cp "$XML" "$SCRATCH/doc/mame.xml"; say "XML substituted from $XML"
fi

# ---------------------------------------------------------------- 5. run it
rm -rf "$RLS" "$ROM"
ARGS=""; if [ "$NOROM" = 1 ]; then ARGS="-n"; fi
# THE WIDE MRA'S HEADER IS OURS, the stock leg's is jtframe's (see
# tools/mra_header.py for why this is a post-process and not a config knob).
rewrite_wide_header() { python3 "$REPO/tools/mra_header.py" "$MRA" || true; }
say "jtframe mra $ARGS $CORE  (HOME=$STAGE)"
if [ "$QUIET" = 1 ]; then
    ( cd "$JTROOT" && env HOME="$STAGE" "$JTF" mra $ARGS "$CORE" >/dev/null 2>&1 )
else
    ( cd "$JTROOT" && env HOME="$STAGE" "$JTF" mra $ARGS "$CORE" )
fi
rewrite_wide_header

# ------------------------------------------------------------- 6. collect
if [ -n "$OUT" ]; then
    if [ "$NOROM" = 0 ]; then
        case "$(mkdir -p "$OUT" && CDPATH= cd "$OUT" && pwd)/" in
        "$REPO"/*) echo "REFUSING: --out $OUT is inside the repo and .rom files"
                   echo "  are ROM content (CLAUDE.md rule 7)." >&2; exit 2 ;;
        esac
    fi
    mkdir -p "$OUT"
    rm -rf "$OUT/mra"; cp -R "$RLS/mra" "$OUT/mra"
    if [ "$NOROM" = 0 ]; then
        for f in "$ROM"/*.rom; do [ -e "$f" ] || continue; cp "$f" "$OUT/"; done
    fi
    say "collected into $OUT"
fi
# The .rom summary is printed even under --quiet: it is the ONE line a caller
# needs (size + sha1 of what was produced), and a silent success is how a
# stale or mis-mapped image gets shipped.
for f in "$ROM"/*.rom; do
    [ -e "$f" ] || continue
    echo "[mister_mra] rom $(basename "$f") $(wc -c < "$f" | tr -d ' ') B sha1 $(shasum "$f" | cut -c1-40)"
done
