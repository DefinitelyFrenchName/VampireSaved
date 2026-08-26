#!/bin/sh
# test_beam_anim_walk.sh — the BEAM ANIM-WALK gate (14z-70): does the
# build ever WALK the anim nodes that carry the beam sprite lists?
#
# WHY IT EXISTS. The effect family (beam / grab lightning / ES big beam /
# 214 explosion) has been chased for several sessions from the emitter
# side. By 14z-69 the beam object was native-equivalent on every axis
# ever suspected — created, routed to the ported machine, record at
# native's OWN relative offset, param tables byte-identical, 118 of 128
# bytes matching native — and it still emitted nothing. The eliminations
# were real but they never answered the question they implied: is the
# ANIMATION that draws the beam ever entered at all?
#
# It was not (14z-70). Native walked the node twice inside its documented
# beam window; ours read the placed twin ZERO times over the same 3,230
# frames. That moved the defect off the draw path entirely and onto
# anim-sequence SELECTION.
#
# RESOLVED 14z-71: the cause was vsav shipping effect-class row 16 as a
# STUB where vs2/vh2 carry the beam's handler. The default expectation is
# now `walks`; `BEAM_WALK_EXPECT=absent` still reproduces the pre-fix state
# on an older build. The gate is kept because that flip is the cheapest
# proof the selection path is alive.
#
# THE ARMING ARTEFACT. trace_writes.lua logs one "frame 1 PC 000926"
# line with every register zero on BOTH legs — that is the watchpoint
# being armed, not an access. Counting it reads as "ours walks the node
# once" and inverts the whole conclusion. Every count here is windowed,
# and section 4 proves the window excludes it.
#
# WHAT DOES NOT TRANSFER BETWEEN THE LEGS. The native leg is vsav2 and
# the build is vsavj-based, so a PC logged on one leg does not name the
# same routine on the other (tools/reconcile_batch.py exists for exactly
# this). Some addresses coincide anyway — in the measuring run four low
# PCs matched exactly, counts and all, while the routine under
# investigation did not. So this gate compares only leg-independent
# quantities: whether the node was read, and how often. Never a PC.
#
# Sections:
#   1. STATIC — the nodes are correctly PORTED: structurally identical to
#      native, every differing byte a 3-byte pointer relocated by exactly
#      the anim delta. No emulator. This is the elimination that makes
#      section 3 meaningful: a node that is never walked could otherwise
#      just be a mis-ported node.
#   2. NATIVE LEG — vsav2 must read the node inside the beam window.
#      A zero here means the RIG is broken (wrong replay, pokes not
#      landing, window moved), not that native has no beam.
#   3. OUR LEG — the placed twin, same replay, same window, compared
#      against BEAM_WALK_EXPECT.
#   4. VERDICT CONTROLS — the counter must ignore the arming artefact,
#      must count a real in-window hit, and must not count an
#      out-of-window one.
#
# EXPECTATION. Default BEAM_WALK_EXPECT=walks as of 14z-71 — THE FLIP
# HAPPENED. The defect was vsav shipping effect-class row 16 as a stub
# where vs2/vh2 carry the beam's handler; porting it and repointing the
# row makes the build enter the animation. BEAM_WALK_EXPECT=absent still
# reproduces the pre-fix state on an older build (build/hui17).
#
# Usage: ROMDIR=... [BEAM_WALK_EXPECT=absent|walks] \
#            tests/test_beam_anim_walk.sh [wide-builddir]
#        (defaults to build/hui25; needs a build carrying H's real art)
set -eu

ROMDIR="${ROMDIR:?set ROMDIR}"
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
   # RE-POINTED 14z-94 (GitHub #94): was build/hui25, a pre-WIDE-v1.1 set
   # (19 members, no vsw.z01/z02) — the script could not run at all.
   # Its frozen inventory may still describe the OLD build: run it
   # before trusting a green, and re-measure rather than absorb.

BUILD="${1:-build/hui48}"
EXPECT="${BEAM_WALK_EXPECT:-walks}"
case "$BUILD" in /*) ;; *) BUILD="$REPO/$BUILD" ;; esac
[ -f "$BUILD/rompath/vsavjw.zip" ] || {
    echo "FAIL: no $BUILD/rompath/vsavjw.zip (WIDE tenant build required)"; exit 1; }

# The anim region: vs2 0x245872, placed wherever THIS build's allocator put
# it. DERIVED, never hardcoded (14z-71): adding the beam-handler region moved
# the anim placement 0x310 (hui17 0x0D89B0 -> hui18 0x0D8CC0), and a stale
# constant here would watch an address nothing reads and report "absent"
# forever — a false NEGATIVE on the one gate whose whole job is to flip.
ANIM_PLACED=$(sed -n 's/^| `PRG:0x\([0-9A-Fa-f]*\)` |.*donovan anim (vsav2 0x245872).*/\1/p' \
              "$BUILD/patch/atlas_fragment.md" | head -1)
[ -n "$ANIM_PLACED" ] || { echo "FAIL: cannot derive the anim placement from"
                           echo "      $BUILD/patch/atlas_fragment.md"; exit 1; }
ANIM_DELTA=$(printf '%d' $((0x245872 - 0x$ANIM_PLACED)))
NODE_NAT=24fcfa
NODE_OUR=$(printf '%x' $((0x24fcfa - ANIM_DELTA)))
echo "anim placed at 0x$ANIM_PLACED (delta $(printf '0x%X' $ANIM_DELTA)); "\
"beam node twin 0x$NODE_OUR"
# The documented native beam window is f3164-3208 (14z-69j dense scan);
# widened slightly so a one-frame phase shift cannot read as absence.
WIN_LO=3150
WIN_HI=3215
FRAMES=3230

RPL="$REPO/tests/replays/hui/83b_hui_ray_2p.rpl"
# P1 = Huitzil (native id 0x10 on BOTH games). Early-window only: late
# pokes leak into the 2P commit/load (the replay-80 rule).
PK="1400:ff8782:10;1450:ff8782:10;1500:ff8782:10"

fail=0

# --- 1. the nodes are correctly ported (static, no emulator) -----------
echo "1. the beam anim nodes are ported"
python3 - "$BUILD" "$ANIM_DELTA" <<'PYEOF' || fail=1
import sys
build = sys.argv[1]
DELTA = int(sys.argv[2])
SRC_BASE, OUR_BASE = 0x245872, 0x245872 - DELTA
src  = open(f'{build}/extract/region_anim.bin', 'rb').read()
ours = open(f'{build}/verify_data.bin', 'rb').read()
bad = 0
for node in (0x24FCFA, 0x251CDA):
    a = src[node - SRC_BASE : node - SRC_BASE + 48]
    b = ours[node - DELTA : node - DELTA + 48]
    if len(a) != 48 or len(b) != 48:
        print(f"  FAIL: node {node:06x} — could not read 48 bytes"); bad = 1; continue
    diffs = [i for i in range(48) if a[i] != b[i]]
    # Every differing byte must be one of exactly TWO documented classes:
    #   1. part of a 3-byte pointer tail relocated by the anim delta, or
    #   2. a composite list's TYPE WORD, retyped 000C -> 0006 by the 14z-71
    #      list-type-6 takeover. Node 0x251CDA's window contains the beam
    #      frame at 0x251CE6, so this class is reached in normal operation —
    #      it is a real change of ours, not a tolerance.
    ptrs, retypes, ok = set(), set(), True
    for i in diffs:
        base = i - (i % 4)
        if base + 4 > 48: ok = False; break
        na = int.from_bytes(a[base:base+4], 'big')
        nb = int.from_bytes(b[base:base+4], 'big')
        if na - nb == DELTA:
            ptrs.add(base); continue
        wbase = i - (i % 2)
        wa = int.from_bytes(a[wbase:wbase+2], 'big')
        wb = int.from_bytes(b[wbase:wbase+2], 'big')
        if (wa, wb) == (0x000C, 0x0006):
            retypes.add(wbase); continue
        ok = False; break
    if ok and diffs:
        extra = f", {len(retypes)} composite type words 000C->0006" if retypes else ""
        print(f"  ok: node {node:06x} -> {node-DELTA:06x} — "
              f"{len(ptrs)} pointers, all relocated by -0x{DELTA:X}{extra}")
    else:
        print(f"  FAIL: node {node:06x} — a differing byte is not a "
              f"correctly relocated pointer"); bad = 1
sys.exit(bad)
PYEOF

# --- the measuring rig -------------------------------------------------
# count_hits <tracefile> — in-window hits only (excludes the arming line)
count_hits() {
    awk -v lo="$WIN_LO" -v hi="$WIN_HI" \
        '$1=="frame" && $2+0>=lo && $2+0<=hi {n++} END{print n+0}' "$1"
}

run_leg() {  # run_leg <tag> <set> <watch> <mamebin> [rompath]
    _tag=$1; _set=$2; _watch=$3; _bin=$4; _rp=${5:-}
    if [ -n "$_rp" ]; then MAME_ROMPATH="$_rp"; export MAME_ROMPATH
    else unset MAME_ROMPATH || true; fi
    WATCH="$_watch,2,r" TRACE_OUT="$WORK/$_tag.txt" FRAMES="$FRAMES" \
    REPLAY="$RPL" POKES="$PK" MAME_SANDBOX="$WORK/sbx_$_tag" \
    MAME_BIN="$_bin" \
        tools/run_mame.sh "$_set" -debug -debugger none \
        -autoboot_script "$REPO/tests/lua/trace_writes.lua" \
        > "$WORK/$_tag.log" 2>&1 || {
        echo "  FAIL: the $_tag run did not complete"; tail -5 "$WORK/$_tag.log"
        fail=1; return 1; }
    return 0
}

# --- 2. native leg ------------------------------------------------------
echo "2. native vsav2 walks the node inside the beam window"
if run_leg native vsav2 "$NODE_NAT" \
        "${MAME_REF_BIN:-$HOME/.cache/vampire-saved/mame-ref/cps2}"; then
    nat=$(count_hits "$WORK/native.txt")
    if [ "$nat" -gt 0 ]; then
        echo "  ok: $nat read(s) of $NODE_NAT in f$WIN_LO-$WIN_HI"
    else
        echo "  FAIL: native read the node 0 times — THE RIG IS BROKEN,"
        echo "        not a finding (check the pokes, replay and window)"
        fail=1
    fi
fi

# --- 3. our leg ---------------------------------------------------------
echo "3. the build's placed twin, same replay and window"
if run_leg ours vsavjw "$NODE_OUR" \
        "${MAME_BIN:-$HOME/.cache/vampire-saved/mame/cps2}" \
        "$BUILD/rompath;$ROMDIR"; then
    our=$(count_hits "$WORK/ours.txt")
    case "$EXPECT" in
    absent)
        if [ "$our" -eq 0 ]; then
            echo "  ok: 0 reads of $NODE_OUR — the beam animation is never"
            echo "      entered (14z-70 measured state; defect is SELECTION)"
        else
            echo "  FAIL: expected 0 reads, got $our. If the build now walks"
            echo "        the node this is GOOD NEWS — re-run with"
            echo "        BEAM_WALK_EXPECT=walks and update the registry"
            fail=1
        fi ;;
    walks)
        if [ "$our" -gt 0 ]; then
            echo "  ok: $our read(s) of $NODE_OUR — the animation is entered"
        else
            echo "  FAIL: expected the build to walk the node, got 0 reads"
            fail=1
        fi ;;
    *)  echo "  FAIL: unknown BEAM_WALK_EXPECT=$EXPECT"; fail=1 ;;
    esac
fi

# --- 4. verdict controls ------------------------------------------------
echo "4. verdict-logic controls"
printf 'frame 1 PC 000926 D0 00000000 A0 00000000\nEND 3230 hits 1\n' \
    > "$WORK/c_arming.txt"
printf 'frame 3165 PC 0199dc D0 00000000 A0 002621c8\nEND 3230 hits 1\n' \
    > "$WORK/c_real.txt"
printf 'frame 900 PC 0199dc D0 00000000 A0 002621c8\nEND 3230 hits 1\n' \
    > "$WORK/c_outside.txt"
ctl() {  # ctl <file> <want> <label>
    got=$(count_hits "$1")
    if [ "$got" -eq "$2" ]; then echo "  ok: $3 -> $got"
    else echo "  FAIL: $3 -> got $got, want $2"; fail=1; fi
}
ctl "$WORK/c_arming.txt"  0 "the frame-1 arming artefact is not counted"
ctl "$WORK/c_real.txt"    1 "a real in-window read IS counted"
ctl "$WORK/c_outside.txt" 0 "an out-of-window read is not counted"

echo
if [ "$fail" -eq 0 ]; then echo "PASS test_beam_anim_walk.sh"; exit 0
else echo "FAIL test_beam_anim_walk.sh"; exit 1; fi
