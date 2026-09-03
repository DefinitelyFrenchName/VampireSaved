#!/bin/sh
# audit_mask_window_ff42a2.sh — the row-0x1D palette-staging window
# ($FF42A2-$FF42C1, mask entry `42a2-42c2`, V3 basis; maintainer-ratified
# 2026-08-15, applied 14z-88 — then WITHDRAWN the same day with the
# medallion REVERT this audit motivated) attributed on the TENANT-CONTENT
# replays. Kept as THE pre/post attribution instrument for any future
# select-palette row move (it is what caught the 38 regression).
#
# THE QUESTION: when the 14z-87b medallion move (Pyron's wheel pal_row
# 0x1A -> 0x1D, one layout field) moved a set's self-frozen `.sha1`
# replays, did anything move OUTSIDE the ratified staging family? Those
# replays have no vanilla oracle (they involve a tenant), so the legacy
# suite cannot answer it; this audit does, by A/B-ing the PRE-move build
# against the POST-move build on each replay:
#   1. unmasked: the pair must DIFFER (the replay's .sha1 moved for a
#      reason; a bit-identical pair means it should not be on the list —
#      the audit refuses to attribute a move that did not happen);
#   2. under the V3 mask (window included): the pair must be EXACT, or
#      differ only on ISOLATED single frames (<=4, each neighbour
#      identical); for every such frame the two builds' work RAM is DUMPED
#      and every differing byte must be either inside the palette STAGING
#      AREA $FF3F02-$FF4301 (slot(row) = $FF3F02 + row*0x20,
#      docs/game/atlas/ram.md) or a return address of the per-frame
#      OBJ-builder bsr chain PRG:0x1ABFC-0x1AC40 on the secondary stack
#      (~$FF06D0: the frame-done sample catching the main loop one bsr
#      further along on a heavy transition frame — execution position,
#      not state; measured 22/23/24 f11862/f12313), or the single byte
#      $FF80B5 (the input-accept transition latch = the ratified session-7
#      flicker class of the frozen legacy inventories; 26/61/37).
#      Measured 14z-88: the
#      transition fade's per-frame staging copy (writer PRG:0x01C3BA, ROM
#      0x390CD0 table, identical PC/source/values on both builds) lands its
#      slot-0x0B chunk ONE FRAME later on the moved build — a one-frame
#      staging PHASE at f2836 (11_pick_donovan / 12_donovan_vs_cpu), the
#      same shape the maintainer ratified for the merged build's replay 11
#      (composite 2836 889-2415, 2026-08-12);
#   3. informational (INFO=1): which ratified windows carry the diff — the
#      V2 mask (window excluded) verdict says whether row 0x1D's slot is
#      involved; the staging-only mask (no dead-stack/latch) says whether
#      dead-stack/latch bytes are.
# Any replay failing (1) or (2) = a mechanism outside the ratified family —
# STOP and root-cause; do not widen the mask (CLAUDE.md §4 standing watch).
# THIS AUDIT'S FIRST RUN (14z-88) DID EXACTLY THAT: 38_victor_p1_vsavj on
# the huitzil/pyron builds diverged SUSTAINED from f2313 — the moved build
# loses one main-loop iteration at the select->VS fade (per-iteration
# counters $FF8081/$FF80B4 one behind vanilla forever): the medallion
# palette content changed the fade's cycles on a frame that already runs
# at the VBL edge. A legacy pairing (ids identical to vanilla) — a
# superset-invariant regression, filed as the 14z-88 decision in STATE.
#
# The pre-move build is rebuilt from the tree ONE commit before the move
# (git worktree at e6abaa9^; only wheel_layout_proposed.json cells.11
# pal_row differs for the program image) — recipe in STATE 14z-88.
#
# Usage: ROMDIR=... MAME_BIN=<WIDE cps2> [INFO=1] [SKIP_RAW=1] \
#   tests/audit_mask_window_ff42a2.sh <pre_rompath_dir> <post_rompath_dir> <replay-name>...
# (~2-3 min per replay without INFO; the 14z-88 run covered every moved
#  .sha1 of the three sets — 40/41/42 replays.)
#
# HANDOFF's gate-index note, moved into this header 14z-123 (verbatim; the
# documentation pass ruled a gate's WHY lives in the gate):
#   14z-88: the ROW-0x1D staging window ($FF42A2-C1, V3 basis) attributed on
#   the tenant-content .sha1 replays the 14z-87b medallion move shifted: pre-
#   move vs post-move build IDENTICAL under the V3 mask, DIFFERENT under V2
#   (control), + unmasked first-div frame. Args: pre rompath, post rompath,
#   replay names
set -eu
ROMDIR="${ROMDIR:?set ROMDIR}"
REPO="$(cd "$(dirname "$0")/.." && pwd)"
# THIS IS AN INSTRUMENT, NOT A GATE, and with no operands there is nothing to
# attribute — so it SKIPS rather than dying on a raw `${1:?...}` shell error
# (added 14z-128, after the emulator-tier sweep invoked it bare and recorded
# "FAIL 0s: line 70: 1: pre-move rompath dir", which is a message about the
# caller, not a verdict about the build). Its operands DESCRIBE A CHANGE UNDER
# INVESTIGATION — a pre-move and a post-move rompath and the replays a
# select-palette row move shifted — so there is no standing pair to sweep it
# with. `tests/ci_emulator.tsv` marks it out of release scope for that reason.
if [ $# -lt 3 ]; then
    echo "  SKIP: no operands — this is the pre/post attribution INSTRUMENT for a"
    echo "        select-palette row move ([VSP-35]), not a standing gate. It needs"
    echo "        a pre-move rompath, a post-move rompath and the replay names of"
    echo "        the change being attributed; there is no default pair, because"
    echo "        there is no default change."
    exit 0
fi
PRE="$1"; POST="$2"; shift 2
case "$PRE" in /*) ;; *) PRE="$REPO/$PRE" ;; esac
case "$POST" in /*) ;; *) POST="$REPO/$POST" ;; esac
V2="043c-043d,4182-41a2,41c2-41e2,4222-4262,7f00-8000"
V3="043c-043d,4182-41a2,41c2-41e2,4222-4262,42a2-42c2,7f00-8000"
STG="4182-41a2,41c2-41e2,4222-4262,42a2-42c2"
# V2/V3 are the audit's own constants (the V3 basis is PARKED since the
# 14z-88 revert — the row-0x1D window is not in any live set; override
# with MASK_PRE_POST=... to attribute a different move under its mask).
V3="${MASK_PRE_POST:-$V3}"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
cd "$REPO"

run_pair() { # $1=replay $2=mask $3=tag [$4=DUMPS] -> $WORK/$1.$3.{pre,post}/c.log
    mkdir -p "$WORK/$1.$3.pre" "$WORK/$1.$3.post"
    DUMPS="${4:-}" MASK_RANGES="$2" MAME_ROMPATH="$PRE;$ROMDIR" \
        tools/run_replay_mame.sh vsavjw "tests/replays/$1.rpl" "$WORK/$1.$3.pre/c.log" \
        "$WORK/$1.$3.pre/box" > "$WORK/$1.$3.pre/out" 2>&1 &
    DUMPS="${4:-}" MASK_RANGES="$2" MAME_ROMPATH="$POST;$ROMDIR" \
        tools/run_replay_mame.sh vsavjw "tests/replays/$1.rpl" "$WORK/$1.$3.post/c.log" \
        "$WORK/$1.$3.post/box" > "$WORK/$1.$3.post/out" 2>&1 &
    wait
    [ -s "$WORK/$1.$3.pre/c.log" ] && [ -s "$WORK/$1.$3.post/c.log" ]
}
first_div() { # $1=a $2=b -> first differing line number (or "-")
    n=$(cmp "$1" "$2" 2>/dev/null | sed -n 's/.*line \([0-9]*\).*/\1/p'); echo "${n:--}"
}
verdict() { python3 tools/compare_flicker.py "$1" "$2" 2>/dev/null || true; }

fail=0
for name in "$@"; do
    printf '%-24s ' "$name"
    rawdiv="(SKIP_RAW)"
    if [ "${SKIP_RAW:-0}" != 1 ]; then
        # the unmasked control; redundant when the list comes from a suite
        # run that already showed the .sha1 moved (SKIP_RAW=1 saves a third)
        if ! run_pair "$name" "" raw; then echo "RUN-FAIL (raw)"; fail=1; continue; fi
        if cmp -s "$WORK/$name.raw.pre/c.log" "$WORK/$name.raw.post/c.log"; then
            echo "FAIL  unmasked pair IDENTICAL — this replay's .sha1 did not move; nothing to attribute"; fail=1; continue
        fi
        rawdiv=$(first_div "$WORK/$name.raw.pre/c.log" "$WORK/$name.raw.post/c.log")
    fi
    if ! run_pair "$name" "$V3" v3; then echo "RUN-FAIL (v3)"; fail=1; continue; fi
    frames=$(python3 - "$WORK/$name.v3.pre/c.log" "$WORK/$name.v3.post/c.log" <<'EOF'
import sys
a = open(sys.argv[1]).read().split("\n"); b = open(sys.argv[2]).read().split("\n")
if len(a) != len(b): print("LENGTH"); sys.exit(0)
d = [i + 1 for i, (x, y) in enumerate(zip(a, b)) if x != y]
ds = set(d)
if not d: print("EXACT")
elif len(d) > 4 or any((f - 1 in ds) or (f + 1 in ds) for f in d): print("FAIL " + ",".join(map(str, d[:8])))
else: print("ISOLATED " + ",".join(map(str, d)))
EOF
    )
    case "$frames" in
    EXACT) attributed="v3 EXACT" ;;
    ISOLATED*)
        frames=${frames#ISOLATED }
        # byte-attribute every divergent frame: dump both builds; every
        # differing byte must be (a) inside the staging area
        # $FF3F02-$FF4301, or (b) a RETURN ADDRESS of the per-frame
        # OBJ-builder call chain PRG:0x1ABFC-0x1AC40 (a run of bsr.w) on the
        # secondary stack around $FF06D0 — the frame-done sample catching
        # the main loop one bsr further along on a heavy transition frame
        # (measured 14z-88 on 22/23/24: $FF06DE.l 0001AC1C vs 0001AC20/18;
        # execution position, not state; identical the next frame).
        spec=""; for f in $(echo "$frames" | tr ',' ' '); do spec="$spec${spec:+;}$f:ff0000-ffffff"; done
        if ! run_pair "$name" "$V3" dump "$spec"; then echo "RUN-FAIL (dump)"; fail=1; continue; fi
        bad=$(python3 - "$WORK/$name.dump.pre" "$WORK/$name.dump.post" $(echo "$frames" | tr ',' ' ') 2>"$WORK/$name.attr" <<'EOF'
import sys, struct
pre, post, frames = sys.argv[1], sys.argv[2], sys.argv[3:]
LO, HI = 0x3F02, 0x4302   # staging area, end exclusive (32 slots of 0x20)
CH_LO, CH_HI = 0x1ABFC, 0x1AC44   # the OBJ-builder bsr chain's return addresses
def ret_addr_pair(a, b, i):
    for j in range(i - 3, i + 1):
        if j < 0 or j % 2 or j + 4 > len(a): continue
        va = struct.unpack(">I", a[j:j+4])[0]; vb = struct.unpack(">I", b[j:j+4])[0]
        if va != vb and CH_LO <= va <= CH_HI and CH_LO <= vb <= CH_HI and va % 4 == 0 and vb % 4 == 0:
            return (j, va, vb)
    return None
out = []
for f in frames:
    a = open(f"{pre}/dump_{f}_ff0000.bin", "rb").read()
    b = open(f"{post}/dump_{f}_ff0000.bin", "rb").read()
    d = [i for i in range(len(a)) if a[i] != b[i]
         and not (0x7F00 <= i < 0x8000) and not (0x043C <= i < 0x043E)]  # dead stack / latch are ratified
    inside = [i for i in d if LO <= i < HI]
    outside = [i for i in d if not (LO <= i < HI)]
    notes = []
    if inside:
        notes.append(f"{len(inside)} staging bytes in slots {[hex(s) for s in sorted({(i - LO) // 0x20 for i in inside})]}")
    unexplained = []
    for i in outside:
        r = ret_addr_pair(a, b, i)
        if r: notes.append(f"OBJ-chain return addr @{hex(0xFF0000 + r[0])} {r[1]:06x}->{r[2]:06x}")
        elif i == 0x80B5: notes.append(f"$FF80B5 input-accept transition latch {a[i]:02x}->{b[i]:02x} (the ratified session-7 flicker class)")
        else: unexplained.append(hex(0xFF0000 + i))
    if unexplained:
        out.append(f"f{f}: byte(s) OUTSIDE the attributed classes: {unexplained[:6]}")
    print(f"f{f}: " + "; ".join(notes), file=sys.stderr)
print("\n".join(out))
EOF
        )
        if [ -n "$bad" ]; then echo "FAIL  v3 divergence at $frames NOT attributed: $bad"; fail=1; continue; fi
        attributed="v3 isolated frame(s) $frames [$(tr '\n' ' ' < "$WORK/$name.attr")]" ;;
    *) echo "FAIL  v3 divergence '$frames' — sustained or too many frames: outside the ratified family (do not widen; root-cause)"; fail=1; continue ;;
    esac
    # informational (INFO=1, +4 runs per replay): which windows carry the diff
    info="(INFO=1 for window attribution)"
    if [ "${INFO:-0}" = 1 ] && run_pair "$name" "$V2" v2; then
        cmp -s "$WORK/$name.v2.pre/c.log" "$WORK/$name.v2.post/c.log" && info="row-0x1D slot NOT involved" || info="row-0x1D slot involved"
    fi
    if [ "${INFO:-0}" = 1 ] && run_pair "$name" "$STG" stg; then
        sv=$(verdict "$WORK/$name.stg.pre/c.log" "$WORK/$name.stg.post/c.log")
        case "$sv" in
        EXACT) info="$info; dead-stack/latch: no diff" ;;
        FLICKER*) info="$info; dead-stack/latch: $sv" ;;
        *) info="$info; dead-stack/latch differ over $(echo "$sv" | awk '{print $2}') frames (data-dependent cycle skew of the staging math — inside the ratified windows)" ;;
        esac
    fi
    echo "PASS  $attributed | unmasked first-div line $rawdiv | $info"
done
[ "$fail" = 0 ] && echo "PASS: every moved replay attributed to the ratified staging family (nothing outside it moved)" \
                || { echo "FAIL: attribution incomplete — see rows above"; exit 1; }
