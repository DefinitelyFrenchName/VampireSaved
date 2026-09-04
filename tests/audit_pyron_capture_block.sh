#!/bin/sh
# audit_pyron_capture_block.sh — PYRON THROWS WITH DEMITRI'S CAPTURE GEOMETRY
# (measured 14z-131, maintainer-ruled "measure against native vs2 first").
#
# THE MECHANISM, read off vsavj's own positioner at PRG:0x02802E (vanilla
# engine code, byte-identical in both games):
#
#     movea.w $32(a6),a4        ; a4 = the VICTIM, a6 = the ATTACKER
#     tst.b   $134(a4)          ; ...only while the victim is CAPTURED
#     move.b  $382(a6),d1 ; lsl.w #2,d1
#     movea.l #$be27a,a0 ; movea.l (a0,d1.w),a0   ; the ATTACKER's blob
#     move.b  $382(a4),d1 ; add.w d1,d1
#     add.w   (a0,d1.w),d0 ; lea (a0,d0.w),a0     ; + the per-VICTIM offset
#     move.w  (a0)+,d0 ; move.w (a0)+,d1          ; dx, dy
#     tst.b   $b(a6) ; neg.w d0                   ; facing
#     add.w   $10(a6),d0 ; add.w $14(a6),d1
#     move.w  d0,$10(a4) ; move.w d1,$14(a4)      ; the VICTIM's position
#
# So `capture_kf_ptr[ATTACKER]` (PRG:0x0BE27A, 32 LONGWORDS — the `lsl.w #2`
# is the fourth independent proof of the entry size) decides where a held
# victim is drawn, every frame of the hold.
#
# THE DEFECT. Every legacy attacker row is ported (the fifteen `capture_kf_*`
# data_port rows, GitHub #104), and so are Donovan's 0x13
# (`throw_victim_keyframes`) and Huitzil's 0x10 (`grab_hold_keyframes`).
# PYRON'S ROW 0x11 IS NOT. vsavj aliases it to 0x00094954 — DEMITRI's block —
# so when Pyron throws, the victim is placed by Demitri's geometry.
#
# MEASURED TWO INDEPENDENT WAYS, and they agree (they share no premise: one
# reads reference-ROM bytes, the other reads work RAM in a running game).
#   STATIC, from vsav2: Pyron's own block 0x0C7F98 vs Demitri's 0x0A3D88 —
#   for victim Victor the keyframe deltas are (-79,0) (-97,0) (-65,0)
#   (82,29) (58,124) (100,132) (116,-4) against Demitri's (-63,0) (-63,0)
#   (-63,0) (-26,0) (-26,0) (-10,32) (5,32). 1 of 8 keyframes agree, and that
#   one is the all-zero kf0.
#   IN-EMULATOR, P1 Pyron vs P2 Victor on judge/02_throw.rpl, hold 3010-3039:
#     ours   {(63,0) (26,0) (10,32) (-5,32) (-10,32) (5,32)}
#     native {(79,0) (97,0) (65,0) (-82,29) (-58,124) (-100,132) (-116,-4)
#             (-53,116) (12,39)}
#   ZERO overlap. Native lifts the victim ~130px overhead and throws them
#   BEHIND Pyron; ours holds them on the ground in front. This is not a
#   subtle cosmetic — it is the wrong throw entirely from the victim's side,
#   on a 2P-competitive surface.
#
# WHAT THIS GATE DOES. Runs the normal-throw rig with a tenant/legacy ATTACKER
# on ours and on native vsav2 and compares the victim's hold offsets.
#   SECTION 0 — THE LEGACY CONTROL, and it is not optional ([VSP-22], the
#     audit_don_grab_pose section-0 rule): a LEGACY attacker (Demitri) must
#     AGREE between the two legs. It proves the rig made the hold on both
#     legs, that the poke path and frame window are right, and that the
#     coordinate convention is shared. If it disagrees, every verdict below
#     is meaningless and the gate says so instead of reporting them.
#   SECTION 1 — PYRON. `EXPECT_MATCH=0` (the default) asserts the MEASURED
#     defect: the two legs must DISAGREE. Flip to `EXPECT_MATCH=1` when row
#     0x11 is ported — the same shape audit_don_grab_pose used across the
#     #104 fix, so the gate proves the fix landed rather than being rewritten
#     to suit it.
#
# NOT A CLAIM ABOUT DONOVAN OR HUITZIL: their rows are ported and their holds
# are locked by audit_don_grab_pose / test_hui_grab_victim.
#
# Static? No — 4 MAME runs, 2 at a time, ~4 min.
# Usage: ROMDIR=... [MAME_BIN=...] [BUILD=build/m3b_merged22] [EXPECT_MATCH=0]
#        tests/audit_pyron_capture_block.sh
set -eu
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
ROMDIR="${ROMDIR:?set ROMDIR}"
BUILD="${BUILD:-build/m3b_merged22}"
EXPECT_MATCH="${EXPECT_MATCH:-0}"   # 0 = the defect is present (today)
VICTIM="${VICTIM:-03}"              # Victor: a legacy dummy, no-input

[ -f "$BUILD/rompath/vsavjw.zip" ] || { echo "SKIP: no $BUILD/rompath/vsavjw.zip"; exit 0; }

W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT
fail=0
RPL="$REPO/tests/replays/judge/02_throw.rpl"
DF="$(python3 -c "print(';'.join(f'{f}:ff8410-ff8418;{f}:ff8810-ff8818;{f}:ff8934-ff8935' for f in range(3005,3075)))")"

run_pair() {  # attacker_hex outdir
    a="$1"; d="$2"
    pk="1400:ff8782:$a;1450:ff8782:$a;1500:ff8782:$a"
    pk="$pk;1400:ff8b82:$VICTIM;1450:ff8b82:$VICTIM;1500:ff8b82:$VICTIM"
    for leg in ours native; do
        mkdir -p "$d/$leg/sbx"
        if [ "$leg" = ours ]; then _s=vsavjw; _rp="$REPO/$BUILD/rompath;$ROMDIR"
        else                      _s=vsav2;  _rp="$ROMDIR"; fi
        ( cd "$d/$leg" && REPLAY="$RPL" POKES="$pk" DUMPS="$DF" \
          CHECKSUM_OUT="$d/$leg/out.log" MAME_SANDBOX="$d/$leg/sbx" \
          MAME_ROMPATH="$_rp" "$REPO/tools/run_mame.sh" "$_s" \
          -autoboot_script "$REPO/tests/lua/replay.lua" > "$d/$leg/mame.log" 2>&1 ) &
    done
    wait
}

compare() {  # dir label -> prints "<n_ours> <n_native> <overlap> <union>"
    python3 - "$1" <<'PY'
import glob, re, struct, sys
d = sys.argv[1]
def offs(leg):
    out = []
    for f in glob.glob(f"{d}/{leg}/dump_*_ff8810.bin"):
        fr = int(re.search(r'dump_(\d+)_', f).group(1))
        cap = open(f"{d}/{leg}/dump_{fr}_ff8934.bin", 'rb').read()
        if not (cap and cap[0]):
            continue
        v = open(f, 'rb').read(); a = open(f"{d}/{leg}/dump_{fr}_ff8410.bin", 'rb').read()
        out.append((struct.unpack_from('>h', v, 0)[0] - struct.unpack_from('>h', a, 0)[0],
                    struct.unpack_from('>h', v, 4)[0] - struct.unpack_from('>h', a, 4)[0]))
    return set(out), len(out)
so, no = offs("ours"); sn, nn = offs("native")
print(f"{no} {nn} {len(so & sn)} {len(so | sn)} {len(so)} {len(sn)}")
PY
}

echo "== 0. LEGACY CONTROL — a legacy attacker must AGREE on both legs =="
run_pair 01 "$W/ctl"
set -- $(compare "$W/ctl")
c_held_o=$1; c_held_n=$2; c_ov=$3; c_un=$4; c_do=$5; c_dn=$6
echo "  demitri: held frames ours=$c_held_o native=$c_held_n;" \
     "distinct offsets ours=$c_do native=$c_dn; overlap=$c_ov of union $c_un"
if [ "$c_held_o" -lt 10 ] || [ "$c_held_n" -lt 10 ]; then
    echo "  FAIL: the rig did not produce a hold on both legs — every verdict"
    echo "        below would be about a throw that never happened."
    fail=1; ctl_ok=0
elif [ "$c_ov" -lt "$c_do" ] || [ "$c_ov" -lt "$c_dn" ]; then
    echo "  FAIL: a LEGACY attacker's hold DIFFERS between ours and native."
    echo "        The shared-convention premise is dead; section 1 is void."
    fail=1; ctl_ok=0
else
    echo "  ok: identical offset sets — the rig, the pokes and the convention hold"
    ctl_ok=1
fi

echo "== 1. PYRON as attacker (row 0x11 of PRG:0x0BE27A) =="
if [ "$ctl_ok" = 0 ]; then
    echo "  SKIPPED: the legacy control failed, so this measures nothing."
else
    run_pair 11 "$W/pyr"
    set -- $(compare "$W/pyr")
    p_held_o=$1; p_held_n=$2; p_ov=$3; p_un=$4; p_do=$5; p_dn=$6
    echo "  pyron: held frames ours=$p_held_o native=$p_held_n;" \
         "distinct offsets ours=$p_do native=$p_dn; overlap=$p_ov of union $p_un"
    if [ "$p_held_o" -lt 10 ] || [ "$p_held_n" -lt 10 ]; then
        echo "  FAIL: no hold on one of the legs — Pyron's throw did not connect,"
        echo "        so this is a rig result, not a verdict ([VSP-137])."
        fail=1
    elif [ "$EXPECT_MATCH" = 1 ]; then
        if [ "$p_ov" -lt "$p_do" ] || [ "$p_ov" -lt "$p_dn" ]; then
            echo "  FAIL: EXPECT_MATCH=1 but the legs still disagree — row 0x11's"
            echo "        port did not take."
            fail=1
        else
            echo "  ok: Pyron's hold matches native — row 0x11 is ported"
        fi
    else
        if [ "$p_ov" = 0 ]; then
            echo "  ok: DISAGREES as measured — ours uses DEMITRI's block"
            echo "      (vsavj row 0x11 aliases 0x00094954). This is the frozen"
            echo "      record of an OPEN defect, not a pass: set EXPECT_MATCH=1"
            echo "      when row 0x11 is ported. STATE 'Decisions pending'."
        else
            echo "  FAIL: expected the two legs to be DISJOINT (the measured"
            echo "        14z-131 state) but overlap=$p_ov. Either the port landed"
            echo "        (flip EXPECT_MATCH) or the rig moved — re-measure."
            fail=1
        fi
    fi
fi

echo
[ "$fail" = 0 ] || { echo "FAIL: pyron capture-block audit"; exit 1; }
echo "PASS: pyron capture-block audit (EXPECT_MATCH=$EXPECT_MATCH)"
