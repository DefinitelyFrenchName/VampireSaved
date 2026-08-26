#!/bin/sh
# setup_jtcores.sh — check out the pinned jtcores FORK (the MiSTer core
# tree), init only the submodules this project needs, and build jtframe's
# Go tool. Mirrors tools/setup_mame.sh / setup_fbneo.sh (14z-106).
#
# WHY A FORK AND A PIN. The MiSTer deliverable is a SEPARATE core
# (cores/cps2w -> jtcps2w.rbf) inside a public GPL-3.0 fork of
# jotego/jtcores, so the reference cps2 core stays untouched and usable
# (maintainer ruling 2026-08-22; docs/platform/mister.md). The gitlink AND
# this literal SHA pin it — the MAME lesson (setup_mame.sh): a submodule
# add once staged the default branch while the tag sat only in the
# worktree. emu/jtcores-patches/ mirrors the fork's diff against
# upstream v1.7.3 as a PATCH SERIES — one file per fork commit, regenerated
# here — so the change stays a reviewable in-tree file (CLAUDE.md rule 1 v2)
# and each commit can be read on its own; tests/test_jtcores_twin.sh holds
# the series, the submodule and the core twin to each other. It was a single
# file until 14z-107 added the second commit (the sim work-RAM hook), and
# 14z-107 (3) added two more — both Verilator-harness bug fixes, no RTL:
# 0003 the SDRAM model's dropped top address bit at AW=23 (the upper 8MB of
# every bank aliased onto the lower 8MB) and 0004 the model clock that never
# advanced (so no `#` delay in the design ever fired, which is why
# `jtsim -verilator -stats` reported nothing) and 0005 raw machine-readable
# counters in the SDRAM usage reporter, whose two existing lines are
# cumulative and rounded and cannot be differenced per phase.
# 14z-107 (5) added 0006, SLICE D0 — the `vsavjw` machine entry in
# doc/mame.xml plus the MANDATORY QSound trim in cores/cps2w/cfg/mame2mra.toml
# (the WIDE image is 70.26 MB mapped verbatim, which overflows both the 26-bit
# ioctl_addr and the 16-bit header start word).
# 14z-107 (6) added 0007, SLICE D1 — THE FIRST RTL COMMIT. cores/cps2w stops
# being cfg-only: it gains hdl/ with two new files (the runtime profile gate
# and the gated QSound sample-bank latch) and OVERRIDES of two SHARED files
# (jtcps15_sound.v, jtcps2_game.v) that could not be edited in place without
# changing the reference cores. cores/cps2 and cores/cps15 remain
# BYTE-UNTOUCHED against upstream v1.7.3, which tests/test_jtcores_twin.sh
# now asserts directly.
# 14z-107 (7) added 0008 and 0009, both Verilator-harness only: the frame
# writer made optional and its children reaped, and the one-word repair that
# makes the forked child _exit(0) instead of exit(0) (exit() fclose()d the
# inherited FILE* behind the parent's sim_inputs.hex and POSIX rewinds the
# SHARED offset, so the simulated controller was being replayed).
# 14z-107 (8) added 0010, the LAST of that family and a FIDELITY fix: at
# v1.7.3 SimInputs held player buttons 5 and 6 DOWN on every 6-button core --
# `&0xf0` on a [9:0] ACTIVE-LOW port, plus a 0xff seed parse_inputs never
# corrects for players 2-4. It re-freezes tests/test_mister_sim_anchor.sh.
# 14z-107 (9) added 0011, SLICE D2 — THE PLACEMENT. cores/cps2w/hdl gains
# OVERRIDES of two more SHARED files (jtcps1_sdram.v, jtcps1_prom_we.v: the
# bank-0 re-pack, the group-C GFX redirect, the QSound split across two banks,
# and the two new slot counts), and jtframe gains ONE NEW FILE,
# hdl/sdram/jtframe_ram1_7slots.v — a mechanical member of the ram1_Nslots
# family, which upstream stops at 5. It is pulled by cores/cps2w's game.yaml
# alone, NOT by jtframe's shared jtframe_sdram64.yaml, so no other core's
# compile list moves. cores/cps1, cores/cps2 and cores/cps15 stay
# BYTE-UNTOUCHED. Gate: tests/test_mister_sdram_census.sh.
#
# Simulation lane deps (brew): go coreutils gnu-sed xmlstarlet verilator
# imagemagick — docs/platform/mister.md "Recipe".
# NEVER init modules/jtframe/target/pocket: it is a PRIVATE ssh submodule
# (git@github.com:jotego/pocket.git) and `--init --recursive` aborts on it.
#
# Usage: tools/setup_jtcores.sh          (no ROMs; needs git, go)
#   env JTCORES_SKIP_GO=1 to skip building the Go tool.
set -eu
REPO="$(cd "$(dirname "$0")/.." && pwd)"
SRC="$REPO/emu/jtcores"
UPSTREAM_TAG_SHA="63688ce5f4de9b92ac4d2ea4b306009b8ba4bcdb"   # jotego/jtcores v1.7.3
PINNED="4dfc3734fcddd069a4d1252bccb67b9cb242e70f"             # fork branch vampire-saved
FORK_URL="https://github.com/DefinitelyFrenchName/jtcores"

if [ ! -f "$SRC/.gitmodules" ]; then
    echo "emu/jtcores is empty — initialising the submodule from $FORK_URL" >&2
    git -C "$REPO" submodule update --init emu/jtcores
fi
HEAD="$(git -C "$SRC" rev-parse HEAD)"
if [ "$HEAD" != "$PINNED" ]; then
    echo "emu/jtcores is at $HEAD, expected pin $PINNED" >&2
    echo "  git -C emu/jtcores fetch origin && git -C emu/jtcores checkout $PINNED" >&2
    echo "  (or update PINNED here deliberately, with the patch regenerated)" >&2
    exit 1
fi
if [ -n "$(git -C "$SRC" status --porcelain --ignore-submodules=all)" ]; then
    echo "emu/jtcores has local modifications — commit them to the fork" >&2
    echo "branch and move PINNED, or \`git -C emu/jtcores checkout .\`" >&2
    exit 1
fi
# The modules the cps2 yaml chain pulls (cps1/common.yaml, cps15/qsound.yaml):
# fx68k (68000), jt12/jt51 (via common.yaml), jteeprom, jtdsp16 (QSound DSP).
git -C "$SRC" submodule update --init modules/fx68k modules/jt12 modules/jt51 modules/jteeprom modules/jtdsp16
echo "jtcores @ $HEAD (fork of v1.7.3 $UPSTREAM_TAG_SHA); jtdsp16 $(git -C "$SRC" submodule status modules/jtdsp16 | cut -c2-41)"

# The reviewable mirror of the fork's delta, one file per commit IN ORDER.
# The names are declared here (not derived from the commit subject) so the
# in-tree filenames stay stable and greppable; the gate reads this same list.
PATCH_NAMES="0001-cps2w-scaffold.patch 0002-jtframe-sim-wramdump.patch 0003-jtframe-sim-sdram-top-address-bit.patch 0004-jtframe-sim-advance-model-time.patch 0005-jtframe-sim-sdram-stats-raw.patch 0006-cps2w-wide-mra-trim.patch 0007-cps2w-qsound-width-runtime-gate.patch 0008-jtframe-sim-optional-frame-writer.patch 0009-jtframe-sim-child-must-exit-hard.patch 0010-jtframe-sim-joystick-top-bits.patch 0011-cps2w-sdram-placement.patch 0012-jtframe-sim-sdram-read-probe.patch 0013-cps2w-obj-promote.patch 0014-jtframe-sim-frame-window.patch 0015-cps2w-prg-window.patch 0016-cps2w-prg-read-probe.patch 0017-cps2w-decrypt-range.patch 0018-cps2w-retract-d4-decrypt-claim.patch 0019-cps2w-readme-d0-d5.patch 0020-jtframe-sim-p2-scriptable.patch"
i=1
for name in $PATCH_NAMES; do
    sha="$(git -C "$SRC" rev-list --reverse "$UPSTREAM_TAG_SHA..$PINNED" | sed -n "${i}p")"
    if [ -z "$sha" ]; then
        echo "the fork has fewer commits than PATCH_NAMES lists (missing $name)" >&2
        exit 1
    fi
    git -C "$SRC" format-patch --stdout -1 "$sha" > "$REPO/emu/jtcores-patches/$name"
    i=$((i + 1))
done
if [ -n "$(git -C "$SRC" rev-list --reverse "$UPSTREAM_TAG_SHA..$PINNED" | sed -n "${i}p")" ]; then
    echo "the fork has MORE commits than PATCH_NAMES lists — add the new name" >&2
    exit 1
fi

if [ "${JTCORES_SKIP_GO:-0}" != "1" ]; then
    command -v go >/dev/null 2>&1 || { echo "go not found (brew install go)" >&2; exit 1; }
    ( cd "$SRC/modules/jtframe/src/jtframe" && go build -o jtframe . )
    echo "jtframe tool: $SRC/modules/jtframe/src/jtframe/jtframe"
    echo "env: JTROOT=$SRC JTFRAME=$SRC/modules/jtframe JTBIN=$SRC/release CORES=$SRC/cores ROM=$SRC/rom"
fi
