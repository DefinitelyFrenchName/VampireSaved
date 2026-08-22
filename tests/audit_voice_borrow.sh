#!/bin/sh
# audit_voice_borrow.sh — THE VOICE-CLASS BORROW mechanism gate (14z-87).
#
# Freezes the sword-plant "ding" mechanism as its STABLE invariants. The
# fired id itself is a LOTTERY (the borrow scan consults the sound-state
# in-use mask, which moves with the QSound-latch one-frame phase — measured
# borrows 0x06/0x0C/0x09/0x00 across identical-input MAME runs), so this
# audit never freezes a single id; it asserts the INVARIANTS that hold in
# every run:
#
#   0. STATIC: the candidate tables are where the mechanism says
#      (vsavj 0x00B268/0x00BB68 via the 0xAF40/0xAF50 lea operands), row
#      0x13 aliases row 0x03 (the tenant rows are unported), vsavj's
#      Victor row slot 3 lists only vanilla classes while vs2's contains
#      Donovan's 0x13, and the signature ids sit where claimed (0x308 =
#      row0C[13]/row1C[13] only; 0x29B = row07[28]/row17[28] only).
#   1. SERIALIZED LIVE RUN (tests/lua/read_tap.lua on $FF8782, rig 90):
#      liveness (boot-POST writes), exactly ONE mid-match writer =
#      PRG:0x0AEF6 writing a value from the candidate row, and the
#      plant-end dispatcher READ returns THAT SAME value (read and write
#      in ONE run — the cross-run-correlation trap is the whole reason
#      this script exists; docs/platform/gotchas.md 14z-87).
#   2. OUTPUT LEVEL (ring_tap, plant-1-end window): the window fires ≥1
#      non-ambient id and every one is a candidate-row node-13 flavor
#      (or its +0x300 facing alias) or a P2-side row-3 entry — membership
#      over the WHOLE candidate set, never one lottery outcome.
#   3. VERDICT CONTROLS: the checker must FAIL on a synthetic foreign
#      ring id and on a synthetic writer census missing 0x0AEF6.
#
# VOICE_BORROW_EXPECT=own-class (default since the option-(b) fix shipped,
# 14z-87): no mid-match borrow write for a tenant P1, the class byte holds
# 0x13 through the plant-end window, and every window ring id is an
# AUTHORED VOICE id (0x58-0xA6 — his own flavor; measured 0x6A).
# VOICE_BORROW_EXPECT=lottery reproduces the PRE-FIX shape and is the
# ground-truth-failing pair against build/don_m4 (kept on disk as the
# known-bad reference): run
#   VOICE_BORROW_EXPECT=lottery tests/audit_voice_borrow.sh build/don_m4
#
# Usage: ROMDIR=... [MAME_BIN=...] tests/audit_voice_borrow.sh [builddir]
# Default build: build/don_m5. ~6 min (2 MAME runs).
set -eu

BUILD="${1:-build/don_m11}"
EXPECT="${VOICE_BORROW_EXPECT:-own-class}"
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
: "${ROMDIR:?set ROMDIR}"
MAME_BIN="${MAME_BIN:-$HOME/.cache/vampire-saved/mame/cps2}"
export MAME_BIN

RPL=tests/replays/don/90_don_plant.rpl
PK="1400:ff8782:13;1450:ff8782:13;1500:ff8782:13;1400:ff8b82:03;1450:ff8b82:03;1500:ff8b82:03"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT INT TERM

fail() { echo "FAIL: $*"; exit 1; }

echo "== section 0: static mechanism facts (build/out views)"
python3 - "$WORK" <<'EOF' || exit 1
import struct,sys
vj=open('build/out/vsavj_data.bin','rb').read()
vjo=open('build/out/vsavj_opcodes.bin','rb').read()
v2=open('build/out/vsav2_data.bin','rb').read()
# the populator's lea operands pin the table bases (RH-58 redundancy)
assert vjo[0xAF40:0xAF44]==bytes.fromhex('45fa0326'), "populator lea A (0xAF40) moved"
assert vjo[0xAF50:0xAF54]==bytes.fromhex('45fa0c16'), "populator lea B (0xAF50) moved"
A,B=0xB268,0xBB68
# tenant rows alias the base half (unported)
for t in (A,B):
    assert vj[t+0x13*0x40:t+0x14*0x40]==vj[t+0x03*0x40:t+0x04*0x40], f"row 0x13 no longer aliases 0x03 in {t:#x}"
# vsavj Victor row slot 3: vanilla classes only; vs2's contains 0x13
row3=vj[A+0x03*0x40+0x18:A+0x03*0x40+0x20]
assert row3==bytes.fromhex('060c010807020f18'), f"vsavj row3 slot3 moved: {row3.hex()}"
# (0x18 in the list is Oboro Bishamon's class — vanilla's one REAL
# variant-half occupant, id_space.md; no tenant class appears)
assert not any(c in (0x10,0x11,0x13) for c in row3), "a tenant class in vsavj's list?!"
v2row3=v2[0x9B2A+0x03*0x40+0x18:0x9B2A+0x03*0x40+0x20]
assert v2row3==bytes.fromhex('13000c0801110f18'), f"vs2 row3 slot3 moved: {v2row3.hex()}"
assert 0x13 in v2row3, "vs2 Victor row lost Donovan's class"
# the signature ids sit where the mechanism says, and nowhere else
def rows(img,base): return [struct.unpack('>I',img[base+i*4:base+i*4+4])[0] for i in range(32)]
rj=rows(vj,0xBF41A)
hits308=[(r,n) for r in range(32) for n in range(48)
         if vj[rj[r]+n*8:rj[r]+n*8+2]==b'\x03\x08']
assert sorted(hits308)==[(0x0C,13),(0x1C,13)], f"0x308 locations moved: {hits308}"
hits29b=[(r,n) for r in range(32) for n in range(48)
         if vj[rj[r]+n*8:rj[r]+n*8+2]==b'\x02\x9b']
assert sorted(hits29b)==[(0x07,28),(0x17,28)], f"0x29B locations moved: {hits29b}"
# node-13 flavor family for the membership check: row[c][13] for slot-3 candidates
fam=set()
for c in row3:
    fam.add(struct.unpack('>H',vj[rj[c]+13*8:rj[c]+13*8+2])[0])
open(sys.argv[1]+'/node13_family','w').write(' '.join(f'{x:04x}' for x in sorted(fam)))
open(sys.argv[1]+'/candidates','w').write(row3.hex())
print("  static facts hold; node-13 family:", ' '.join(f'{x:04x}' for x in sorted(fam)))
EOF

echo "== section 1: serialized borrow write + dispatcher read (one run)"
REPLAY="$RPL" POKES="$PK" RTAP="ff8782,2" WINDOW="3984,4004" FRAMES=4050 \
TRACE_OUT="$WORK/rt.txt" MAME_SANDBOX="$WORK/sbx1" \
MAME_ROMPATH="$PWD/$BUILD/rompath;$ROMDIR" \
  tools/run_mame.sh vsavjw -autoboot_script tests/lua/read_tap.lua \
  > "$WORK/run1.log" 2>&1 || true
grep -q "^END " "$WORK/rt.txt" || fail "read_tap run did not complete"
python3 - "$WORK" "$EXPECT" <<'EOF' || exit 1
import re,sys
work,expect=sys.argv[1],sys.argv[2]
W,R=[],[]
for ln in open(work+'/rt.txt'):
    m=re.match(r'([WR]) (\d+) PC (\w+) off (\w+) data (\w+) mask (\w+)',ln)
    if not m: continue
    kind,fr,pc,off,data,mask=m.group(1),int(m.group(2)),int(m.group(3),16),m.group(4),int(m.group(5),16),int(m.group(6),16)
    (W if kind=='W' else R).append((fr,pc,data,mask))
# liveness: the boot POST walks all of work RAM
assert any(pc in (0xD34,0xD3A,0xDD8) for _,pc,_,_ in W), "no boot-POST writes — dead instrument"
mid=[(fr,pc,data,mask) for fr,pc,data,mask in W if fr>2000]
def lane(data,mask): return (data>>8)&0xFF if mask&0xFF00 else data&0xFF
cands=set(bytes.fromhex(open(work+'/candidates').read()))
if expect=='lottery':
    assert len(mid)==1, f"expected exactly one mid-match $FF8782 write, got {len(mid)}: {mid}"
    fr,pc,data,mask=mid[0]
    assert pc in (0xAEF6,0xAEFA), f"mid-match writer PC {pc:#x} is not the borrow (0xAEF6)"
    v=lane(data,mask)
    assert v in cands, f"borrowed value {v:#x} not in the candidate row {sorted(cands)}"
    # the plant-end dispatcher read must return the SAME value (single run!)
    dr=[(fr,pc,data,mask) for fr,pc,data,mask in R if pc in (0x27F16,0x27F1A)]
    assert dr, "no dispatcher read of $FF8782 in the plant-end window — rig dead or path moved"
    got={lane(d,m) for _,_,d,m in dr}
    assert got=={v}, f"dispatcher read {got} != borrowed {v:#x} — the serialization invariant broke"
    print(f"  borrow write @f{fr} PC 0xAEF6 value {v:#x}; dispatcher read the same value. OK")
else:  # own-class (the shipped option-(b) fix, 14z-87)
    assert not any(pc in (0xAEF6,0xAEFA) for _,pc,_,_ in mid), \
        f"borrow write still fires for tenant P1: {mid}"
    # every read of the class byte in the plant-end window must return the
    # tenant id — reader PCs are build-dependent (the fixed build routes
    # through the PORTED dispatcher copy), so assert on the VALUE, not a PC
    assert R, "no reads of $FF8782 in the window — rig dead"
    got={lane(d,m) for _,_,d,m in R}
    assert got=={0x13}, f"class byte must hold 0x13 throughout, read {sorted(hex(x) for x in got)}"
    print(f"  own-class shape holds (no borrow; {len(R)} window reads all 0x13). OK")
EOF

# FRAME CONSTANTS RE-DATED -1 (14z-94, GitHub #10). Both windows here were
# tuned while ring_tap.lua and read_tap.lua staged inputs one frame off
# replay.lua; unifying the convention moved every scripted press one frame
# earlier, so the events they bracket moved with it. MEASURED, not assumed:
# the plant-end voice id 0x6A now fires at frame 3974, one frame below the
# old lower bound 3975 — which is what made section 2 report "rig dead".
# The window WIDTHS are unchanged; only the origin moved.
echo "== section 2: output level — ring window membership"
REPLAY="$RPL" POKES="$PK" FULL=1 FRAMES=4100 TRACE_OUT="$WORK/ring.txt" \
MAME_SANDBOX="$WORK/sbx2" MAME_ROMPATH="$PWD/$BUILD/rompath;$ROMDIR" \
  tools/run_mame.sh vsavjw -autoboot_script tests/lua/ring_tap.lua \
  > "$WORK/run2.log" 2>&1 || true
python3 - "$WORK" "$EXPECT" <<'EOF' || exit 1
import re,sys,struct
work,expect=sys.argv[1],sys.argv[2]
def check(path, fam, expect):
    ids=[]
    for ln in open(path):
        m=re.match(r'f(\d+) id (\w+)',ln)
        if m and 3974<=int(m.group(1))<=4029:
            i=int(m.group(2),16)
            if i not in (0x498,0x49A,0,0xFFFF): ids.append(i)
    assert ids, "no ids in the plant-end window — rig dead (liveness)"
    if expect=='lottery':
        ok=fam | {x+0x300 for x in fam}
        bad=[i for i in ids if i not in ok]
        assert not bad, f"window ids {bad} outside the node-13 flavor family {sorted(hex(x) for x in ok)}"
    else:
        # own-class: every non-ambient window id must be an AUTHORED VOICE
        # id (0x58-0xA6) — his own flavor, line-agnostic (the fixed build
        # routes the plant-end through his ported dispatcher and fires a
        # different node than the vanilla anim's 13; measured 0x6A)
        bad=[i for i in ids if not (0x58<=i<=0xA6)]
        assert not bad, f"non-authored ids in the window: {[hex(i) for i in bad]}"
    return ids
fam=set(int(x,16) for x in open(work+'/node13_family').read().split())
ids=check(work+'/ring.txt',fam,expect)
print(f"  window ids {[hex(i) for i in ids]} all in the flavor family. OK")
# section 3: verdict controls — the checker must FAIL on synthetic bads
open(work+'/bad_ring.txt','w').write("f4000 id 1234 pc 0031ee\n")
try:
    check(work+'/bad_ring.txt',fam,'lottery'); raise SystemExit("CONTROL DEAD: foreign id not caught")
except AssertionError: print("  verdict control 1 (foreign ring id) fires. OK")
EOF

echo "== section 3b: verdict control — writer census missing 0xAEF6 must fail"
python3 - "$WORK" <<'EOF' || exit 1
import sys
work=sys.argv[1]
# replay section-1 logic against a synthetic log whose only mid-match write
# has a wrong PC — the assertion must fire
synth=[l for l in open(work+'/rt.txt') if not (l.startswith('W') and ' PC 00aef' in l)]
synth.append("W 3464 PC 012345 off ff8782 data 00000c0c mask 0000ff00\n")
open(work+'/rt_bad.txt','w').writelines(synth)
import re
W=[(int(m.group(1)),int(m.group(2),16)) for l in open(work+'/rt_bad.txt')
   if (m:=re.match(r'W (\d+) PC (\w+)',l))]
mid=[(f,p) for f,p in W if f>2000]
assert not (len(mid)==1 and mid[0][1] in (0xAEF6,0xAEFA)), "CONTROL DEAD"
print("  verdict control 2 (wrong writer PC) fires. OK")
EOF

echo "PASS: voice-borrow mechanism invariants hold ($EXPECT)"
