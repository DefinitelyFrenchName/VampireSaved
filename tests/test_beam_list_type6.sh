#!/bin/sh
# test_beam_list_type6.sh — the LIST-TYPE 6 TAKEOVER gate (14z-71).
#
# vsav's sprite-list drawer has six list types (0..10); vs2 has seven (0..12),
# and the beam's list is the type-12 COMPOSITE. The table cannot grow (entry
# 0's own offset IS its length) or move (the dispatch is (d8,PC,Xn)), so the
# port takes over list-type 6 — measured unused by legacy — by writing a
# 6-byte jmp over its dead handler and changing the type word on our own 39
# composite lists from 000C to 0006.
#
# WHAT THIS GATE PROTECTS. Two things that would fail silently:
#
#   1. THE BODY IS A TRANSCRIPTION of Capcom's handler (vs2 0x01A1FC), not
#      authored logic. Only four scratch displacements, one call and one loop
#      displacement may differ. A hand edit that drifts from the original
#      would still assemble and still draw something.
#
#   2. THE FALLBACK IS THE WHOLE SAFETY ARGUMENT. "Type 6 is dead" is
#      measured by ABSENCE, so the build deliberately does not rely on it:
#      any list outside our own placed region runs vsav's ORIGINAL type-6
#      code, reproduced instruction-for-instruction and rejoined by jmp. If
#      that reproduction is wrong, the safety net is gone and nothing else
#      would notice — legacy never exercises it (which is exactly the point).
#      So it is checked STATICALLY, here, against the vanilla image.
#
# The dynamic half of the watch lives in tests/audit_effect_class_rows.sh
# section 4. AMENDED 14z-91: it used to assert a counter at $FF010C stayed
# ZERO on legacy. 14z-89 measured that the deadness claim was FALSE — legacy
# lists do reach type 6, 387x on 21_don_mash and 948x on 26_don_arcade_mash
# — and the fallback held, exactly as designed. But the counter is live work
# RAM vanilla does not keep, so those replays could not re-converge with the
# vanilla basis. The counter is REMOVED; §4 now watches the fallback's
# EXECUTION against a FROZEN per-replay inventory, and drift in either
# direction is the stop-and-assess event.
#
# Usage: tests/test_beam_list_type6.sh [builddir]     (default build/hui25)
#        No emulator, no ROMDIR. Seconds.
set -eu
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
BUILD="${1:-build/hui25}"
case "$BUILD" in /*) ;; *) BUILD="$REPO/$BUILD" ;; esac

python3 - "$BUILD" <<'PYEOF'
import re, sys
build = sys.argv[1]
fail = 0
def ok(m):  print(f"  ok: {m}")
def bad(m):
    global fail; print(f"  FAIL: {m}"); fail = 1

vs2 = open('build/out/vsav2_opcodes.bin','rb').read()
vj  = open('build/out/vsavj_opcodes.bin','rb').read()
man = open('build/manifest/huitzil.toml').read()

# ── 1. the manifest body is Capcom's handler, bar the documented changes ──
print("1. the thunk body is a transcription of vs2 0x01A1FC")
m = re.search(r'name = "beam_list_type6".*?thunk_hex = "([0-9a-f]+)"', man, re.S)
if not m:
    bad("no beam_list_type6 site_thunk row in the manifest"); print(); sys.exit(1)
body = bytes.fromhex(m.group(1))
mine, theirs = body[0x10:0x4A], bytearray(vs2[0x01A1FC:0x01A1FC+0x3A])
# RECONSTRUCT what the body must be, by applying exactly the documented
# substitutions to Capcom's bytes — then demand equality. This is stronger
# than diffing with an allowance: any edit that is not one of these four
# named changes fails, including one that happens to land on a byte a
# tolerance would have forgiven.
SCRATCH = {0x02:0x8100, 0x06:0x8108, 0x0A:0x8104,   # count / a0 save / d4 save
           0x28:0x8108, 0x30:0x8104, 0x34:0x8100}   # a0 / d4 restore, count dec
for off, val in SCRATCH.items():
    theirs[off:off+2] = val.to_bytes(2,'big')
theirs[0x24:0x26] = mine[0x24:0x26]   # bsr target: local to our body
exp = bytes(theirs)
if mine == exp:
    ok(f"composite portion ({len(mine):#x} bytes) is vs2 0x01A1FC with exactly the "
       f"6 scratch displacements, bsr.w -> jsr 0x1AFAE, and the loop disp")
else:
    d = [hex(i) for i in range(min(len(mine),len(exp))) if mine[i] != exp[i]]
    bad(f"body is NOT the documented transcription; differs at {d[:12]}"
        f"{' …' if len(d)>12 else ''}")

# 1a. THE EXEMPTED WORD MUST STILL RESOLVE. `theirs[0x24:0x26] = mine[...]`
# above exempts the bsr.w displacement from the vs2 comparison because it is
# local to our body — which means NOTHING checked where it actually lands.
# That mattered the moment the body's length changed: 14z-91 removed the
# $FF010C counter at +0x4A, and this bsr.w at +0x32 is the ONE branch that
# crosses the cut (its target moved +0x60 -> +0x5C, displacement 0x2C ->
# 0x28). Get it wrong and the fallback calls into the middle of a bne.s, on
# legacy content, on exactly the two long mash replays most gate defaults
# never run. So resolve it and demand it lands on the local child
# dispatcher's head.
bsr_disp = int.from_bytes(body[0x34:0x36], 'big')
bsr_tgt = 0x34 + bsr_disp
if body[0x32:0x34] != b'\x61\x00':
    bad(f"expected bsr.w at body +0x32, found {body[0x32:0x34].hex()}")
elif not (0 < bsr_tgt < len(body) - 4):
    bad(f"bsr.w at +0x32 targets +{bsr_tgt:#x}, outside the {len(body):#x}-byte body")
elif body[bsr_tgt:bsr_tgt + 4] != bytes.fromhex("0c500004"):
    bad(f"bsr.w at +0x32 targets +{bsr_tgt:#x} = {body[bsr_tgt:bsr_tgt+4].hex()}, "
        f"expected 0c500004 (cmpi.w #4,(a0) — the local child dispatcher head). "
        f"A displacement that was not re-derived after a body-length change "
        f"lands mid-instruction and is silent until legacy runs it.")
else:
    ok(f"bsr.w at +0x32 resolves to +{bsr_tgt:#x} = cmpi.w #4,(a0), the local "
       f"child dispatcher")

# ── 1b. the ported TYPE-4 handler: vsav's, with exactly two constants ───
# The beam's middle piece is a list-type 4 — a procedural strip generator.
# Two constants in it are game-specific, and BOTH had to change:
#   * the BANK: type 4 composes its own y-word (ori.w #$2000 = bank 1) where
#     type 2 takes the object's. H's art is in WIDE group C = bank 4.
#   * the CODE BIAS: vsavj biases codes +0x3800, vs2 +0x4200 — ONE byte
#     apart, and the only difference between the two games' routines. Our
#     ported vs2 list data must use VS2's bias or it addresses tiles 0x0A00
#     low, landing on the freeze/reflection art. That byte was dismissed as
#     "a relocated address" for most of a session; this check exists so it
#     can never be dismissed again.
# Ported bias = vs2's 0x4200 + the group-C placement shift. The shift was
# 0x1000 (bias 0x5200) until 14z-83 relocated the strip to 0x86A0-0x87BF
# (maintainer-approved: the old dst sat inside Pyron's native band — the one
# real collision in the merged write set); it is now 0x3800, bias 0x7A00.
print("1b. the ported type-4 handler is vsavj's with exactly the two constants")
t4 = body[0x6E:]   # was 0x72; -4 since 14z-91 removed the $FF010C counter
src4 = bytearray(vj[0x01B61A:0x01B61A + 0x90])
if len(t4) != len(src4):
    bad(f"ported type-4 is {len(t4):#x} bytes, vsavj's is {len(src4):#x}")
else:
    src4[0x3A:0x3E] = bytes.fromhex("00401000")      # bank 4
    src4[0x7C:0x82] = bytes.fromhex("06817a000000")  # vs2 bias + shift
    if bytes(src4) == t4:
        ok("vsavj 0x01B61A verbatim + bank 0x1000 + bias 0x7A00")
    else:
        d4 = [hex(i) for i in range(len(t4)) if t4[i] != src4[i]]
        bad(f"ported type-4 differs from the documented form at {d4[:8]}")
    v2b = int.from_bytes(vs2[0x01A04A + 0x7C:0x01A04A + 0x82], 'big')
    vjb = int.from_bytes(vj[0x01B61A + 0x7C:0x01B61A + 0x82], 'big')
    if (v2b, vjb) == (0x068142000000, 0x068138000000):
        ok("the games' biases are still vs2 +0x4200 / vsavj +0x3800")
    else:
        bad(f"a game's type-4 bias moved: vs2 {v2b:#014x} vsavj {vjb:#014x}")

# ── 1c. THE CLASS: which list-type handlers differ between the games ────
# The type-4 bias was not a one-off. Comparing every handler in vsav's
# drawer table against vs2's counterpart, the SAME +0x3800 / +0x4200 code
# bias differs in types 4, 6 AND 8; types 0 and 2 differ only in branch
# displacements (which is why the muzzle and tip always drew correctly).
#
# This is the general hazard the beam exposed: ported vs2 list data is NOT
# interpreted identically by vsav's handlers. Any future tenant whose
# content uses a type-6 or type-8 list will address tiles 0x0A00 low and
# render someone else's art — the exact defect, pre-diagnosed. Frozen here
# so the discovery is not re-paid.
print("1c. the per-handler constant differences are the frozen inventory")
VJ_BASE, V2_BASE = 0x01AFBA, 0x0199E8
def tgt(img, base, ty):
    return base + int.from_bytes(img[base+ty:base+ty+2], 'big')
EXPECT = {0: 0, 2: 0, 4: 1, 6: 1, 8: 1}     # biased-constant sites per type
BODY  = {0: 0x26E, 2: 0x3E6, 4: 0x90, 6: 0x94, 8: 0x8E}
for ty, want in sorted(EXPECT.items()):
    a, b = tgt(vj, VJ_BASE, ty), tgt(vs2, V2_BASE, ty)
    n = BODY[ty]
    # TWO encodings of the same bias: type 4 uses addi.l #$38000000,d1
    # (long), types 6 and 8 use addi.w #$3800,d2 (word). Matching only the
    # long form reports a cheerful zero for the very handlers most likely to
    # bite a future tenant.
    got = 0
    for i in range(n - 5):
        if (vj[a+i:a+i+6] == bytes.fromhex("068138000000")
                and vs2[b+i:b+i+6] == bytes.fromhex("068142000000")):
            got += 1
        elif (vj[a+i:a+i+4] == bytes.fromhex("06423800")
                and vs2[b+i:b+i+4] == bytes.fromhex("06424200")):
            got += 1
    if got == want:
        ok(f"type {ty}: {got} game-specific code-bias site(s)"
           + ("  <- ported copy must carry vs2's 0x4200" if got else ""))
    else:
        bad(f"type {ty}: {got} bias site(s), frozen inventory says {want} — "
            f"the handler set moved; re-audit before porting any list of this type")

# ── 2. the FALLBACK reproduces vanilla type 6 exactly ────────────────────
print("2. the non-tenant fallback reproduces vsav's own type-6 head")
# vanilla: 3a18 (move.w (a0)+,d5) be45 (cmp.w d5,d7) 6500 008c (bcs.w 1b73c)
van = vj[0x01B6AA:0x01B6B2]
if van[:4] != b'\x3a\x18\xbe\x45':
    bad(f"vanilla type-6 head moved: {van.hex()}")
else:
    ok("vanilla head is move.w (a0)+,d5 ; cmp.w d5,d7 ; bcs.w")
tail = body[0x4A:]  # composite is 0x3A bytes (bsr.w, as vs2)
# 14z-91: the fallback no longer bumps a work-RAM counter. `526d810c`
# (addq.w #1,(-0x7EF4,A5) -> $FF010C) was removed from the head, so the
# fallback now opens directly with the two displaced vanilla instructions
# and every later field in this slice moved down by 4. The tripwire is not
# gone, it moved instruments: audit_effect_class_rows.sh §4 watches the
# fallback's EXECUTION (it already PC-attributes every hit) instead of a
# counter's value, which is what returns 21_don_mash and 26_don_arcade_mash
# to a strict vanilla basis. A counter in live work RAM vanilla does not
# keep cannot be reconciled with the superset invariant.
want_head = b'\x3a\x18\xbe\x45'
if tail[:4] != want_head:
    bad(f"fallback head is {tail[:4].hex()}, expected the two displaced instructions")
elif body[:0x4A].find(bytes.fromhex("526d810c")) != -1 or tail.find(bytes.fromhex("526d810c")) != -1:
    bad("the $FF010C tripwire counter write is still present in the body")
else:
    ok("fallback re-executes both displaced instructions, no work-RAM counter")
# the two absolute jumps must be the vanilla rejoin and the original bcs target
rejoin = int.from_bytes(tail[0x08:0x0C],'big')
skip   = int.from_bytes(tail[0x0E:0x12],'big')
# a .w branch is relative to its EXTENSION WORD, not to the opcode word:
# bcs.w sits at 0x01B6AE, its displacement word at 0x01B6B0.
orig_skip = 0x01B6B0 + int.from_bytes(vj[0x01B6B0:0x01B6B2],'big')
if rejoin != 0x0001B6B2:
    bad(f"fallback rejoins at {rejoin:#08x}, expected 0x0001B6B2 (the instruction after the displaced 6 bytes)")
else:
    ok("fallback rejoins vanilla type 6 at 0x01B6B2")
if skip != orig_skip:
    bad(f"fallback's skip target is {skip:#08x}, vanilla's bcs.w goes to {orig_skip:#08x}")
else:
    ok(f"fallback's budget-exhausted path goes to vanilla's own target {skip:#08x}")

# ── 3. the built image really carries the takeover ───────────────────────
print("3. the build carries the jmp and the retyped lists")
try:
    op = open(f'{build}/verify_op.bin','rb').read()
    dat = open(f'{build}/verify_data.bin','rb').read()
except FileNotFoundError:
    bad(f"no verify images under {build}"); op = dat = b''
if op:
    if op[0x01B6AA:0x01B6AC] != b'\x4e\xf9':
        bad(f"no jmp at 0x01B6AA (found {op[0x01B6AA:0x01B6B0].hex()})")
    else:
        tgt = int.from_bytes(op[0x01B6AC:0x01B6B0],'big')
        ok(f"dead type-6 handler head -> jmp {tgt:#08x}")
    rows = [int(a,16) for a in re.findall(r'src_addr = 0x([0-9A-Fa-f]{6})\nold_hex = "000c"', man)]
    anim = re.search(r'\| `PRG:0x([0-9A-Fa-f]+)` \|.*donovan anim \(vsav2 0x245872\)',
                     open(f'{build}/patch/atlas_fragment.md').read())
    if not rows: bad("no composite-list port_patch rows found in the manifest")
    elif not anim: bad("cannot find the anim placement in the build's atlas")
    else:
        base = int(anim.group(1),16); delta = 0x245872 - base
        wrong = [a for a in rows
                 if int.from_bytes(dat[a-delta:a-delta+2],'big') != 6]
        if wrong: bad(f"{len(wrong)} of {len(rows)} composite lists are not type 6")
        else: ok(f"all {len(rows)} composite lists carry type 6 in the built image")

print()
sys.exit(fail)
PYEOF
rc=$?
if [ "$rc" -eq 0 ]; then echo "PASS test_beam_list_type6.sh"; else echo "FAIL test_beam_list_type6.sh"; fi
exit $rc
