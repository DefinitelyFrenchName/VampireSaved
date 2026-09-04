#!/bin/sh
# audit_don_grab_pose.sh — THE #104 LOCK: a legacy grab holds a TENANT victim
# on the wrong capture record. On-demand, ~12 min (8 MAME runs, 2 at a time:
# the build + native vsav2, for one legacy control victim and three tenants).
#
# THE REPORT (maintainer, MAME field test 2026-08-19): a tenant victim of
# Victor's headbutting grab (6+HP) shows a half-right / half-squished
# HORIZONTAL pose. Named DONOVAN and PHOBOS.
#
# THE MECHANISM — MEASURED AND CLOSED 14z-99. It is the VARIANT-ROW ALIAS
# class, the most common defect shape in this port. It is NOT a generation
# drift in the reaction-index space, and the ported anim_index tables do NOT
# need reordering: that 14z-98 (9) reading is RETRACTED (see below).
#
#   The capture pose is selected PER VICTIM. vsavj resolves the victim's
#   capture set through 32-row per-character structures whose rows 0x10-0x1F
#   are byte-copies of 0x00-0x0F, so a tenant victim is served the BASE
#   character it folds onto:
#         Donovan 0x13 -> 0x03 Victor    Phobos 0x11 -> ... see table
#   Measured index installed at victim +0x1C, ours vs native vsav2:
#         victim          fold      ours   native   verdict
#         Bulleta  0x00    -          12      12     legacy, agrees
#         Demitri  0x01    -          11      11     legacy, agrees
#         Victor   0x03    -           6       6     legacy, agrees
#         Lilith   0x0e    -           9       9     legacy, agrees
#         Phobos   0x10   -> 0x00     12      26..28  WRONG (Bulleta's)
#         Pyron    0x11   -> 0x01     11      11     right BY COINCIDENCE
#         Donovan  0x13   -> 0x03      6      11      WRONG (Victor's)
#   Pyron's fold value happens to equal his correct one, which is exactly
#   why the field report named Donovan and Phobos and not him.
#
# WHY THE LEGACY CONTROL IS SECTION 0 AND NOT OPTIONAL. The whole reading
# rests on "the reaction-index convention is SHARED between the engines".
# If a legacy victim ever installs a different index on the two legs, that
# premise is dead and every tenant verdict below is meaningless. It also
# proves both rigs made the hold.
#
# RETRACTED HERE, 14z-99 (both were mine, both measured false):
#  1. "GENERATION DRIFT IN THE REACTION-INDEX SPACE; the ported tables are
#     in vs2's index order; FIX = derive the permutation from the legacy
#     twins and REORDER 5 sibling tables x 3 tenants" (14z-98 (9)). The
#     legacy twins the permutation was to be derived FROM are BYTE-IDENTICAL
#     (Victor row 3: vsavj 0x157A50 vs vs2 0x13FAA2, entry for entry), so
#     that permutation is the IDENTITY and the reorder is a no-op.
#  2. "Pyron mismatches too: ours 0x26654C vs native 0x26614C" (14z-98 (7)).
#     That was THIS SCRIPT'S OWN BUG: it resolved every tenant through
#     placements["regions"]["anim"], which on a MERGED build is DONOVAN's
#     placement. Through anim@pyron, Pyron's held record maps to 0x26614C —
#     identical to native. The region is now resolved per victim.
#
# THE RESOLVING STRUCTURE, located 14z-99 — seven instructions at
# PRG:0x02802E (engine_internals "THE CAPTURE-POSE INSTALLER"):
#     move.b $382(a6),d1 ; lsl.w #2,d1 ; movea.l #$be27a,a0
#     movea.l (a0,d1.w),a0        ; the ATTACKER's keyframe BLOCK
#     move.b $382(a4),d1 ; add.w d1,d1
#     add.w (a0,d1.w),d0          ; += block[VICTIM id, UNMASKED]
#     lea (a0,d0.w),a0            ; block + block[victim] + keyframe*8
# THE FIRST 32 WORDS OF EVERY ATTACKER'S KEYFRAME BLOCK ARE A PER-VICTIM
# OFFSET TABLE, and in vsavj ALL SIXTEEN blocks alias its variant half
# onto the base half — fourteen by OFFSET, two (Zabel 0x04, special 0x0B)
# by MATERIALIZED byte-copies (measured 14z-99; the earlier "populated
# 32-entry shape" reading of that pair is RETRACTED). The tenant lands in the base
# character's capture sub-block and takes BOTH its position keyframes and
# its record index. Victor's block 0x098C28: block[0x13]==block[0x03]
# ==0x0568, block[0x10]==block[0x00]==0x0040, block[0x11]==block[0x01]
# ==0x01F8, and every measured A0 is block+block[victim]+0x106.
# vs2's twin blocks are NOT aliased and already carry real newcomer rows
# (vs2 Victor 0x0A8824: 0x10=0x1A08, 0x11=0x1BC0, 0x13=0x1D78).
# FIX: RULED 2026-08-19 (maintainer) — option (a), full, measured first;
# feasibility frozen in test_capture_pose_sources.sh (ci_static), and the
# fix SHIPPED at the 14z-99 freeze (#104; rehearsed on build/probe_104):
# 15 [[data_port]] slot_rows rows commented at the END of ALL THREE
# tenant manifests (uncomment at the re-freeze window; +32 ops per
# artifact). Probed: EXPECT_MATCH=1 green on all three tenants (Donovan
# idx 11, Phobos 26, Pyron 11 — native's exact records), legacy control
# agreeing, and legacy A/B vs frozen merged-m3 = ONE differing frame
# (f890, the ratified class-4 select-init pointer cache), bit-identical
# from f891 through full matches. FLIP EXPECT_MATCH's default TO 1 when
# the rows land.
# Eliminated on the way, with controls: on merged-m3 the anim_index family
# (a/a2/b/c/proj) and all 14 per-character dispatch tables have rows
# 0x10/0x11/0x13 MOVED OFF the vanilla alias for all three tenants, so
# none of them is handing a tenant its fold row; and 0xBE27A itself is
# ATTACKER-indexed (A0 sat in Victor's block while row 0x13 pointed at
# the tenant's own placed block).
#
# LEG A (the build) freezes the DEFECT per tenant while EXPECT_MATCH=0 (the
# #98 discipline — flip to 1 when the fix lands). LEG B (native vsav2) is
# the anchor and the rig-liveness control.
#
# The ours->vs2 mapping is DERIVED from the build's own placements.json anim
# row FOR THAT VICTIM (never hardcoded — placements move at every re-freeze).
#
# Usage: ROMDIR=... [MAME_BIN=...] [BUILD=build/m3b_merged23]
#        [EXPECT_MATCH=0] [VICTIMS="01 13 10 11"] tests/audit_don_grab_pose.sh
#
# HANDOFF's gate-index note, moved into this header 14z-123 (verbatim; the
# documentation pass ruled a gate's WHY lives in the gate):
#   14z-98 (6), REBUILT 14z-99, GitHub #104: a legacy grab holds a TENANT
#   victim on the wrong capture record. MECHANISM = THE VARIANT-ROW ALIAS
#   class (re-measured 14z-99, NOT the "reaction-index generation drift"
#   14z-98 (9) claimed — that and its 5-table reorder are RETRACTED in the
#   script header): the capture set is selected PER VICTIM through 32-row
#   structures whose rows 0x10-0x1F copy 0x00-0x0F, so a tenant is served the
#   base character it folds onto. MECHANISM LOCATED 14z-99 at PRG:0x02802E:
#   the first 32 words of EVERY attacker's keyframe block are a per-victim
#   offset table indexed by the victim's id UNMASKED, and vsavj aliases its
#   0x10-0x1F half onto 0x00-0x0F in ALL 16 blocks (14 by offset,
#   Zabel/special by materialized copies; vs2's are real). RULED option (a)
#   full, feasibility MEASURED CLEAN — premises frozen in
#   test_capture_pose_sources.sh; implementation + inventory: STATE 14z-99.
#   Donovan 0x13->0x03 gets Victor's index 6 (native 11); Phobos 0x10->0x00
#   gets Bulleta's 12 (native 26); PYRON 0x11->0x01 gets Demitri's 11, which
#   IS his correct one — right by coincidence, and why the field named D and P
#   only. SECTION 0 IS A LEGACY-VICTIM CONTROL: both engines must install the
#   SAME index for a legacy victim or the shared-convention premise is dead
#   and every tenant verdict here is meaningless. The anim region is resolved
#   PER VICTIM (anim / anim@huitzil / anim@pyron) — doing that unconditionally
#   through "anim" is what produced the retracted 14z-98 (7) Pyron reading on
#   the MERGED build. Hold detected from hp-DROP samples (no tuned pixel
#   window); a non-majority modal is NO-HOLD. EXPECT_MATCH=0 freezes the
#   defect; flip at the fix. VICTIMS= overrides the set. Rig:
#   replays/96_don_victor_grab.rpl (4 connects/run, no HP pokes). ~12 min, 8
#   MAME runs (2 at a time).
set -eu
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
ROMDIR="${ROMDIR:?set ROMDIR}"
BUILD="${BUILD:-build/m3b_merged23}"  # re-pointed 14z-117b (random-select freeze) <- 14z-117  # re-pointed 14z-119 (physics-port freeze) <- 14z-117b
[ -d "$BUILD/rompath" ] || { echo "SKIP: no build at $BUILD"; exit 0; }
[ -f "$BUILD/patch/placements.json" ] || { echo "SKIP: no placements.json in $BUILD"; exit 0; }
MAME_BIN="${MAME_BIN:-$HOME/.cache/vampire-saved/mame/cps2}"
[ -x "$MAME_BIN" ] || { echo "SKIP: no WIDE MAME binary"; exit 0; }
export MAME_BIN
EXPECT_MATCH="${EXPECT_MATCH:-1}"   # flipped at the 14z-99 window (#104 landed)
VICTIMS="${VICTIMS:-01 13 10 11}"

W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT
fail=0

RPL="$REPO/tests/replays/96_don_victor_grab.rpl"
DF="$(python3 -c "print(';'.join(f'{f}:ff8850-ff8856;{f}:ff881c-ff8824' for f in range(2900,4700,10)))")"

# which placed region carries each victim's anim data (MERGED builds place
# one region per tenant; a solo build has only "anim"). Getting this wrong
# is what produced the retracted Pyron reading.
region_for() {
    case "$1" in
    10) echo "anim@huitzil" ;;
    11) echo "anim@pyron" ;;
    *)  echo "anim" ;;
    esac
}

run_pair() { # victim_hex outdir
    v="$1"; d="$2"
    pk=""
    for f in 1200 1300 1400 1500 1700 1900 2100; do
        pk="$pk$f:ff8782:03;$f:ff8b82:$v;"
    done
    pk="${pk%;}"
    for leg in ours native; do
        mkdir -p "$d/$leg/sbx"
        if [ "$leg" = ours ]; then set2=vsavjw; rp="$REPO/$BUILD/rompath;$ROMDIR"
        else                       set2=vsav2;  rp="$ROMDIR"; fi
        ( cd "$d/$leg" && REPLAY="$RPL" POKES="$pk" DUMPS="$DF" \
          CHECKSUM_OUT="$d/$leg/out.log" MAME_SANDBOX="$d/$leg/sbx" \
          MAME_ROMPATH="$rp" "$REPO/tools/run_mame.sh" "$set2" \
          -autoboot_script "$REPO/tests/lua/replay.lua" > "$d/$leg/mame.log" 2>&1 ) &
    done
    wait
}

# held_index <legdir> <leg> <victim_hex> <region>
# The hold is read from the hp-DROP samples (the headbutt ticks): victim-
# independent, so no tuned pixel window. Prints "<vs2src> <idx> <n>/<total>"
# or "NO-HOLD"/"DEAD". A modal that is not a strict majority is NO-HOLD:
# a split reading is not a measurement.
held_index() {
    python3 - "$1" "$2" "$3" "$4" "$BUILD" <<'PY'
import glob, struct, re, sys, json, collections
d, leg, vic, region, build = sys.argv[1], sys.argv[2], int(sys.argv[3], 16), sys.argv[4], sys.argv[5]
v2 = open('build/out/vsav2_data.bin', 'rb').read()
vj = open('build/out/vsavj_data.bin', 'rb').read()
ORI_VJ, ORI_V2, C = 0x0BD0FA, 0x0D7298, 0x0BCFFA
# WHICH GAME'S TABLE resolves the index depends on the LEG and the VICTIM.
# A legacy victim on OUR leg is held on vsavj's own (unrelocated) table; a
# tenant victim on our leg is held in the PLACED copy of vs2's table. Getting
# this wrong reports a real hold as "not a table entry" (caught 14z-99).
if leg == "ours" and vic < 0x10:
    img, TBL = vj, struct.unpack('>I', vj[C + vic * 4:][:4])[0]
else:
    img, TBL = v2, struct.unpack('>I', v2[C + (ORI_V2 - ORI_VJ) + vic * 4:][:4])[0]
tab = [struct.unpack('>H', img[TBL + 2 * i:][:2])[0] for i in range(96)]
pl = json.load(open(f"{build}/patch/placements.json"))["regions"][region]
g = lambda k: int(pl[k], 16) if isinstance(pl[k], str) else pl[k]
DST, SRC = g("dst"), g("src")
fr = sorted(int(re.search(r'dump_(\d+)_ff8850', f).group(1))
            for f in glob.glob(f"{d}/dump_*_ff8850.bin"))
if not fr:
    print("DEAD"); sys.exit(0)
rows = [(f,
         struct.unpack(">H", open(f"{d}/dump_{f}_ff8850.bin", "rb").read()[:2])[0],
         struct.unpack(">I", open(f"{d}/dump_{f}_ff881c.bin", "rb").read()[:4])[0])
        for f in fr]
cnt = collections.Counter()
for i in range(1, len(rows)):
    if rows[i][1] < rows[i - 1][1]:
        cnt[rows[i][2]] += 1
if not cnt:
    print("NO-HOLD"); sys.exit(0)
addr, n = cnt.most_common(1)[0]
total = sum(cnt.values())
if n * 2 <= total:
    print("NO-HOLD"); sys.exit(0)
# a TENANT victim on our leg lives in the placed copy; everything else is
# already in its own game's space.
src = addr - DST + SRC if (leg == "ours" and vic >= 0x10) else addr
off = src - TBL
idx = [j for j, w in enumerate(tab) if w == off] if 0 <= off < 0x10000 else []
print(f"{src:#08x} {idx[0] if idx else -1} {n}/{total}")
PY
}

echo "== #104 capture-pose audit on $BUILD (EXPECT_MATCH=$EXPECT_MATCH)"
for v in $VICTIMS; do
    reg="$(region_for "$v")"
    run_pair "$v" "$W/$v"
    A="$(held_index "$W/$v/ours"   ours   "$v" "$reg")"
    B="$(held_index "$W/$v/native" native "$v" "$reg")"
    ai="$(echo "$A" | awk '{print $2}')"; bi="$(echo "$B" | awk '{print $2}')"
    printf "  victim 0x%s (%s)\n    ours  : %s\n    native: %s\n" "$v" "$reg" "$A" "$B"
    case "$A$B" in
    *DEAD*|*NO-HOLD*)
        echo "    FAIL: a leg produced no hold — the rig did not make the event"; fail=1; continue ;;
    esac
    if [ "$ai" = "-1" ] || [ "$bi" = "-1" ]; then
        echo "    FAIL: a held record is not a table entry — re-derive before trusting anything"
        fail=1; continue
    fi
    if [ "$v" = "01" ] || [ "$v" = "03" ] || [ "$v" = "00" ] || [ "$v" = "0e" ]; then
        # SECTION 0: the legacy control — the shared-convention premise
        if [ "$ai" = "$bi" ]; then
            echo "    ok: LEGACY CONTROL — both engines install index $ai (convention is shared)"
        else
            echo "    FAIL: legacy victim installs index $ai on ours and $bi on native."
            echo "          The shared-convention premise is DEAD and every tenant verdict"
            echo "          in this file is meaningless. Stop and re-derive (#104 reopens)."
            fail=1
        fi
        continue
    fi
    # tenants
    if [ "$EXPECT_MATCH" = 0 ]; then
        if [ "$v" = "11" ]; then
            [ "$ai" = "$bi" ] \
                && echo "    ok: Pyron matches native (index $ai) — the fold COINCIDES; frozen" \
                || { echo "    FAIL: Pyron no longer matches ($ai vs $bi)"; fail=1; }
        elif [ "$ai" = "$bi" ]; then
            echo "    FAIL: ours now matches native — if a fix landed, flip EXPECT_MATCH's"
            echo "          default and record it; if none did, rule 6"; fail=1
        else
            echo "    ok: the frozen defect — ours index $ai, native $bi (#104 open)"
        fi
    else
        [ "$ai" = "$bi" ] \
            && echo "    ok: ours holds native's record (index $ai) — the fix holds" \
            || { echo "    FAIL: still wrong — ours $ai, native $bi"; fail=1; }
    fi
done

[ "$fail" = 0 ] && echo "AUDIT PASS (defect state as expected)" \
    || { echo "AUDIT FAIL"; exit 1; }
