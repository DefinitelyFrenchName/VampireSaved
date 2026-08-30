#!/bin/sh
# test_capture_pose_sources.sh — THE #104 FIX PREMISES (14z-99). The
# maintainer ruled the fix scope: option (a), full, "measure first: if
# option (a) is not feasible, then we reassess". This gate IS that
# measurement, made rerunnable — it locks every ROM fact the fix design
# rests on, so drift in any of them is loud before the window opens.
#
# THE MECHANISM (engine_internals "THE CAPTURE-POSE INSTALLER"): the
# capture positioner (PRG:0x02802E) resolves the ATTACKER's keyframe block
# via 0xBE27A[attacker], then indexes the block's 32-word head by the
# VICTIM's char id UNMASKED. vsavj's blocks alias/copy rows 0x10-0x1F onto
# 0x00-0x0F, so a tenant victim is held on the base character's capture
# sub-block (GitHub #104; dynamic lock: audit_don_grab_pose.sh).
#
# WHAT THIS LOCKS (all measured 14z-99):
#  1. The positioner's id-unmasked read: the instruction bytes at
#     0x028058-0x028065 (move.b $382(a4),d1; add.w d1,d1;
#     add.w (a0,d1.w),d0; lea (a0,d0.w),a0) — the defect site.
#  2. FIVE code sites carry the 0xBE27A immediate, and no other: repointing
#     the table rows covers every consumer. A sixth appearing = a new
#     consumer the fix must re-verify.
#  3. vsavj block shapes: 14 of 16 blocks OFFSET-alias their variant half;
#     Zabel (0x04) and special (0x0B) MATERIALIZE the alias (variant
#     sub-block content byte-copies base, 15/16 rows — row 0x1F is the
#     known exception both times). ALL SIXTEEN are therefore defective for
#     tenant victims.
#  4. Source data: for every attacker, vs2 AND vhunt2 carry a twin block
#     with DISTINCT tenant rows (0x10/0x11/0x13), sub-block stride EQUAL
#     to vsavj's (the keyframe-index-space compatibility signal), and
#     vs2 == vh2 on the tenant sub-block content (cross-oracle).
#  5. Legacy invariance premise: every BASE sub-block is BYTE-IDENTICAL
#     between vsavj and vs2, all 16 attackers (each game followed through
#     its OWN table offsets — Zabel's table LAYOUT differs because vs2
#     merges Zabel+special into one shared block; the content is equal).
#     This is what makes the wholesale vs2 port legacy-safe by content.
#  6. The signed-16-bit bound: the extended blob's worst-case relative
#     offset (existing end + 3 appended sub-blocks) is 0x3730 < 0x8000
#     for every attacker — `lea (a0,d0.w)` sign-extends, so this is the
#     constraint that forbids pointing sub-blocks into far space.
#  7. The port inventory: 15 DISTINCT vs2 blocks (Zabel+special share
#     0x0ABC56), total 0x11BD0 bytes (~71 KiB) for wide_ext.
#  8. Two verdict controls (a perturbed buffer must FAIL each direction).
#
# Static, no emulator, ~5 s warm. Usage: ROMDIR=... tests/test_capture_pose_sources.sh
#
# HANDOFF's gate-index note, moved into this header 14z-123 (verbatim; the
# documentation pass ruled a gate's WHY lives in the gate):
#   14z-99 (GitHub #104, ci_static): THE OPTION-(a) FIX PREMISES, frozen — the
#   ruling was "measure first" and this gate IS the measurement, rerunnable.
#   Locks: the positioner's id-unmasked read (byte-exact at PRG:0x028058);
#   exactly 5 consumers of 0xBE27A; the 14-offset-alias + 2-material- ized-
#   alias block shapes; source twins for all 16 attackers in BOTH vs2 and
#   vhunt2 (tenant rows distinct, stride-equal, vs2==vh2 cross-oracle); every
#   BASE sub-block byte-identical vsavj==vs2 (the legacy-safety premise of the
#   wholesale port); the signed-16-bit bound (worst 0x3730); the
#   15-block/0x11BD0 port inventory. 2 verdict controls. Static, ~5 s warm
set -u
REPO="$(cd "$(dirname "$0")/.." && pwd)"; export REPO
ROMDIR="${ROMDIR:?set ROMDIR}"
. "$REPO/tests/lib/decrypt_cache.sh"
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT
fail() { echo "FAIL: $*"; exit 1; }

decrypt_view vsavj "$W/vj_op.bin" "$W/vj_dat.bin" || fail "vsavj decrypt view"
decrypt_view vsav2 "$W/v2_op.bin" "$W/v2_dat.bin" || fail "vsav2 decrypt view"
decrypt_view vhunt2 "$W/vh_op.bin" "$W/vh_dat.bin" || fail "vhunt2 decrypt view"

python3 - "$W" <<'PY' || exit 1
import sys, struct
w = sys.argv[1]
vj  = open(f"{w}/vj_dat.bin","rb").read()
vjo = open(f"{w}/vj_op.bin","rb").read()
v2  = open(f"{w}/v2_dat.bin","rb").read()
vh  = open(f"{w}/vh_dat.bin","rb").read()
def die(m): sys.exit(f"FAIL: {m}")
ORI_VJ,ORI_V2,ORI_VH = 0x0BD0FA,0x0D7298,0x0D6B2A
T = 0xBE27A
TEN = (0x10,0x11,0x13)
def L(im,a): return struct.unpack('>I',im[a:a+4])[0]
def W16(im,a): return struct.unpack('>H',im[a:a+2])[0]
def table(im,b): return [W16(im,b+2*i) for i in range(32)]
def stride(t):
    return min(x-y for x,y in zip(sorted(set(t))[1:],sorted(set(t))) if x-y>0)

# 1. the defect site's instruction bytes (opcode view)
want = bytes.fromhex("122c0382d241d070100041f00000")
got = vjo[0x028058:0x028058+len(want)]
if got != want: die(f"positioner bytes moved at 0x028058: {got.hex()}")
print("  ok: 1. the id-unmasked positioner read at PRG:0x028058 (byte-exact)")

# 2. exactly the five known 0xBE27A consumers
pat = struct.pack('>I',0x000BE27A)
sites=[]; i=0
while True:
    i = vjo.find(pat,i+1)
    if i<0: break
    sites.append(i)
def hx(l): return " ".join(f"{a:06x}" for a in l)
WANT_SITES=[0x02804e,0x0280c6,0x028140,0x05316c,0x06e78a]
if sites != WANT_SITES: die(f"0xBE27A consumer set moved: {hx(sites)} (want {hx(WANT_SITES)})")
print(f"  ok: 2. exactly 5 consumers of 0xBE27A ({hx(sites)})")

# 3+4+5+6+7 per attacker
rows_j=[L(vj,T+4*i) for i in range(16)]
offset_alias=0; materialized=[]
worst=0; v2blocks={}; tot=0
for i in range(16):
    bj=rows_j[i]; tj=table(vj,bj); sj=stride(tj)
    if all(tj[v+16]==tj[v] for v in range(16)):
        offset_alias += 1
    else:
        # must be the materialized-copy shape: content equal 15/16, 0x1F off
        eq=[vj[bj+tj[v+16]:bj+tj[v+16]+sj]==vj[bj+tj[v]:bj+tj[v]+sj] for v in range(16)]
        if sum(eq)!=15 or eq[15]: die(f"block {i:02x}: unknown variant-half shape ({sum(eq)}/16, row1F eq={eq[15]})")
        materialized.append(i)
    # source twins
    for nm,im,ori in (("vs2",v2,ORI_V2),("vh2",vh,ORI_VH)):
        bs=L(im,T+(ori-ORI_VJ)+4*i); ts=table(im,bs); ss=stride(ts)
        if ss!=sj: die(f"block {i:02x} {nm}: stride {ss:#x} != vsavj {sj:#x}")
        for v in TEN:
            if ts[v]==ts[v&0x0F]: die(f"block {i:02x} {nm}: tenant row {v:02x} is an alias")
        if nm=="vs2": b2,t2=bs,ts
        else:
            for v in TEN:
                if v2[b2+t2[v]:b2+t2[v]+sj]!=im[bs+ts[v]:bs+ts[v]+sj]:
                    die(f"block {i:02x}: vs2/vh2 disagree on tenant row {v:02x}")
    # 5. base halves byte-identical vsavj vs vs2 (own offsets each)
    for v in range(16):
        if vj[bj+tj[v]:bj+tj[v]+sj]!=v2[b2+t2[v]:b2+t2[v]+sj]:
            die(f"block {i:02x}: base sub-block {v:02x} differs vsavj vs vs2")
    # 6. bound
    mx=max(tj)+sj+3*sj
    worst=max(worst,mx)
    if mx>=0x8000: die(f"block {i:02x}: extended bound {mx:#x} >= 0x8000")
    # 7. inventory
    if b2 not in v2blocks:
        v2blocks[b2]=i
        tot += max(t2)+stride(t2)
if offset_alias!=14: die(f"offset-aliasing blocks: {offset_alias} != 14")
if materialized!=[0x04,0x0B]: die(f"materialized-alias blocks: {materialized} != [0x04,0x0B]")
print(f"  ok: 3. 14 offset-alias + 2 materialized (Zabel, special; row 0x1F excepted)")
print(f"  ok: 4. all 16 twins: tenant rows distinct, stride-equal, vs2==vh2")
print(f"  ok: 5. every base sub-block byte-identical vsavj vs vs2 (16/16)")
if worst!=0x3730: die(f"worst extended bound {worst:#x} != frozen 0x3730")
print(f"  ok: 6. worst extended offset {worst:#x} < 0x8000")
if len(v2blocks)!=15 or tot!=0x11BD0:
    die(f"port inventory moved: {len(v2blocks)} blocks / {tot:#x} bytes (want 15 / 0x11bd0)")
print(f"  ok: 7. port inventory: 15 distinct vs2 blocks, {tot:#x} bytes")

# 8. verdict controls: a perturbed buffer must FAIL each direction
buf=bytearray(vj)
bj=rows_j[3]; tj=table(vj,bj)               # Victor
buf[bj+2*0x13] ^= 0x01                       # break the offset alias
if all(W16(bytes(buf),bj+2*(v+16))==W16(bytes(buf),bj+2*v) for v in range(16)):
    die("control A dead: perturbed alias not detected")
print("  ok: 8a. control — a de-aliased row 0x13 IS detected")
buf2=bytearray(v2)
b2=L(v2,T+(ORI_V2-ORI_VJ)+4*3); t2=table(v2,b2); sj=stride(table(vj,bj))
buf2[b2+t2[0]] ^= 0xFF                       # corrupt a base sub-block byte
if vj[bj+tj[0]:bj+tj[0]+sj]==bytes(buf2)[b2+t2[0]:b2+t2[0]+sj]:
    die("control B dead: corrupted base sub-block reads as identical")
print("  ok: 8b. control — a corrupted base sub-block IS detected")
PY
echo "PASS: the #104 option-(a) premises hold (16 attackers, 15 vs2 blocks, 0x11bd0 bytes, bound 0x3730)"
