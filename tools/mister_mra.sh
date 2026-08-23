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
#   1. THE STOCK LEG AND THE WIDE LEG NEED DIFFERENT `vsav.zip` FILES. The
#      WIDE romset is a CLONE set: `vsavjw.zip` carries the program, the Z80,
#      group C and the QSound extension, and everything else comes from its
#      PARENT — which for the WIDE build is the build's own `vsav.zip`, not
#      the pristine dump (the merged build patches vanilla GFX members
#      `vm3.13m/15m/17m/19m`; run_wide.sh overlays them the same way). The
#      stock `vsavj` reference leg needs the PRISTINE parent. One `$HOME`
#      cannot be both, so this script stages a PRIVATE one per invocation.
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
#     --wide BUILD_DIR     stage BUILD_DIR/rompath/{vsavjw,vsav}.zip, i.e.
#                          build the WIDE leg. Without it the pristine
#                          $ROMDIR sets are staged (the stock leg).
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
#   env JTSIM_SCRATCH=...  where the scratch clone lives (default
#                          ${TMPDIR:-/tmp}/vampire-saved-jtsim)
set -eu
REPO="$(cd "$(dirname "$0")/.." && pwd)"

CORE=cps2w; WIDE=""; NOROM=0; OUT=""; TOML=""; XML=""; QUIET=0
while [ $# -gt 0 ]; do
    case "$1" in
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
ROMDIR="${ROMDIR:?set ROMDIR to the reference-set directory}"
ROMDIR="$(CDPATH= cd "$ROMDIR" && pwd)"
say() { [ "$QUIET" = 1 ] || echo "[mister_mra] $*"; }

SCRATCH="${JTSIM_SCRATCH:-${TMPDIR:-/tmp}/vampire-saved-jtsim}"
case "$SCRATCH" in
    "$REPO"|"$REPO"/*) echo "REFUSING: JTSIM_SCRATCH is inside the repo ($SCRATCH)." >&2
                       echo "  jtframe mra writes release/ and rom/ into it." >&2; exit 2 ;;
esac
PIN="$(sed -n 's/^PINNED="\([0-9a-f]*\)".*/\1/p' "$REPO/tools/setup_jtcores.sh")"
[ -n "$PIN" ] || { echo "cannot read PINNED from tools/setup_jtcores.sh" >&2; exit 1; }

# ------------------------------------------------------------------ 1. clone
if [ ! -d "$SCRATCH/.git" ]; then
    [ -e "$REPO/emu/jtcores/.git" ] || {
        echo "emu/jtcores not initialised — run tools/setup_jtcores.sh" >&2; exit 1; }
    say "cloning the fork into $SCRATCH"
    git clone --quiet "$REPO/emu/jtcores" "$SCRATCH"
    git -C "$SCRATCH" remote set-url origin \
        "$(git -C "$REPO/emu/jtcores" remote get-url origin)"
fi
if [ "$(git -C "$SCRATCH" rev-parse HEAD)" != "$PIN" ]; then
    say "checking out the pin $PIN in the scratch clone"
    git -C "$SCRATCH" fetch --quiet "$REPO/emu/jtcores" 2>/dev/null || true
    git -C "$SCRATCH" fetch --quiet origin 2>/dev/null || true
    git -C "$SCRATCH" checkout --quiet "$PIN" 2>/dev/null || {
        echo "scratch clone cannot reach the pin $PIN — delete $SCRATCH and rerun" >&2
        exit 1; }
fi

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
        link vsav.zip   "$(CDPATH= cd "$RP" && pwd)/vsav.zip"
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
say "jtframe mra $ARGS $CORE  (HOME=$STAGE)"
if [ "$QUIET" = 1 ]; then
    ( cd "$JTROOT" && env HOME="$STAGE" "$JTF" mra $ARGS "$CORE" >/dev/null 2>&1 )
else
    ( cd "$JTROOT" && env HOME="$STAGE" "$JTF" mra $ARGS "$CORE" )
fi

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
