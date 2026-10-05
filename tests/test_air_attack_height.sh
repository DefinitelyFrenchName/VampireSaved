#!/usr/bin/env bash
# test_air_attack_height.sh — vsavj's MINIMUM AIR-DASH HEIGHT table, read where the code reads it
# (14z-189; the 14z-121 "36" corrected; "air-attack" CORRECTED to AIR-DASH 14z-191 — every caller's taken
# branch enters seq 0x14, the air dash, docs/game/engine_internals.md; the gate keeps its name). ci_static: ROMDIR only.
#
# WHAT: the routine at vsavj PRG:0x027B80 (fifteen bsr.w callers) tests +0x190 first; when it is
#   set neither guard applies. Otherwise it returns 0 when +0x121 is set, and, with +0x38 set,
#   returns 0 when +0x14 - +0x3A < word[+0x382] (unsigned, bcs), the word read from the table it
#   loads with `movea.l #$0BE23A,a0` (PRG:0x027B92). Every path reaching the button test returns
#   1 exactly when +0x113|+0x114 is nonzero.
#   The meanings of +0x121 (crouch), +0x38 (off the ground) and +0x14 (Y) are ram.md's; +0x3A,
#   +0x113 and +0x114 have no ram.md row: +0x14 - +0x3A as height above the floor is 14z-121's reading,
#   and +0x113 as the air-dash command latch is 14z-191's measurement (it was 14z-121's "button press",
#   RETRACTED: no LP press set it; the j.66 input did — tests/audit_air_dash_height.sh, #222). Its 32 rows read 0x0018 (24) for 0x04, 0x0D, 0x0F
#   (Zabel, Lei-Lei, Jedah per docs/game/atlas/character_tables.md) and their +0x10 mirrors
#   0x14, 0x1D, 0x1F, and 0 for the other 26, the tenants' 0x10/0x11/0x13 included; the 33rd
#   word on is another table. +0x382 is the character id per docs/game/atlas/ram.md (not
#   re-measured here).
# HOW: static over the decrypted vsavj opcode and data views (tests/lib/decrypt_cache.sh): the
#   table address is taken from the instruction's immediate, which must be the opcode view's
#   only reference to 0x000BE23A; capstone (the disassembler tools/audit_marionette_cost.py uses)
#   decodes the eight instructions after it, which must index the table by the character id
#   +0x382 at WORD stride (ext.w / add.w d1,d1 / move.w (0,a0,d1.w),d1); the 32 words are then
#   read from the data view at that stride. The whole routine (PRG:0x027B80-0x027BC1) is decoded
#   and frozen, so which branch returns 0 and which returns 1 is read from the code; its direct
#   callers are counted over every static transfer form (jsr/jmp abs.l, abs.w and (d16,PC); bra,
#   bsr and every Bcc .b/.w; DBcc) targeting 0x027B80 (indirect and (d8,PC,Xn) transfers are not).
# EXPECTS: the instruction at PRG:0x027B92, one reference, the frozen index sequence, the frozen
#   routine, fifteen callers and the frozen row values below; each control fails the run.
#
# MUST-FIRE: perturbed-copy: row-misread — a copy of vsavj's data view with row 0x04 of the table rewritten to 0x0024 (36, the 14z-121 figure) must fail the frozen row compare (mode: the gate reads the rewritten copy and FAILS)
# MUST-FIRE: perturbed-copy: branch-flipped — a copy of vsavj's opcode view with the height compare's `bcs.b` (PRG:0x027BAE) turned into `bcc.b` must fail the frozen routine compare, so which side of the compare returns 0 is checked against the code (mode: the gate reads the flipped copy and FAILS)
# MUST-FIRE: perturbed-copy: index-changed — a copy of vsavj's opcode view with the stride instruction `add.w d1,d1` (PRG:0x027BA6) replaced by a nop must fail the frozen index-sequence compare, so the word-stride reading is checked against the code (mode: the gate reads the changed copy and FAILS)
#
# WHY. docs/game/engine_internals.md and build/manifest/bank_map.toml said "36 for Zabel,
# Lilith and Jedah" from 14z-121; the table reads 0x0018 = 24 (how 36 was obtained is
# not recorded), and row 0x0D is Lei-Lei, Lilith being 0x0E. Measured 14z-189 while reviewing #162's census, which found vs2's row 0x10
# (Phobos) at 0x0018 where ours reads 0.
#
# Usage: ROMDIR=... tests/test_air_attack_height.sh
set -eu
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
ROMDIR="${ROMDIR:?set ROMDIR}"
if [ -d "$ROMDIR" ]; then ROMDIR="$(cd "$ROMDIR" && pwd)"; fi
[ -f "$ROMDIR/vsav.zip" ] || { echo "SKIP: no vsav.zip in ROMDIR"; exit 0; }
. "$REPO/tests/lib/decrypt_cache.sh"   # GitHub #69: never re-decrypt directly
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT
fail=0
note() { printf '%s\n' "$*"; }
chk() { # label expected actual
    if [ "$2" = "$3" ]; then note "  ok   $1"; else note "  FAIL $1: expected [$2] got [$3]"; fail=1; fi
}
decrypt_view vsavj "$W/vj_op.bin" "$W/vj_data.bin"
. "$REPO/tests/lib/controls.sh"; vs_ctl_mode "$0"

# The control image: the data view with row 0x04 rewritten to 0x0024.
python3 - "$W/vj_data.bin" "$W/vj_data_bad.bin" <<'EOF'
import sys
d = bytearray(open(sys.argv[1], 'rb').read()); a = 0x0BE23A + 2 * 0x04
assert d[a:a + 2] == b'\x00\x18', d[a:a + 2].hex()
d[a:a + 2] = b'\x00\x24'
open(sys.argv[2], 'wb').write(bytes(d))
EOF
DATA="$W/vj_data.bin"
vs_ctl_is row-misread && DATA="$W/vj_data_bad.bin"
# The second control image: the opcode view with add.w d1,d1 replaced by nop.
python3 - "$W/vj_op.bin" "$W/vj_op_bad.bin" <<'EOF2'
import sys
d = bytearray(open(sys.argv[1], 'rb').read()); a = 0x027BA6
assert d[a:a + 2] == b'\xd2\x41', d[a:a + 2].hex()
d[a:a + 2] = b'\x4e\x71'
open(sys.argv[2], 'wb').write(bytes(d))
EOF2
# The third control image: the opcode view with the height compare's bcs.b turned into bcc.b.
python3 - "$W/vj_op.bin" "$W/vj_op_flip.bin" <<'EOF3'
import sys
d = bytearray(open(sys.argv[1], 'rb').read()); a = 0x027BAE
assert d[a:a + 2] == b'\x65\x0e', d[a:a + 2].hex()
d[a] = 0x64
open(sys.argv[2], 'wb').write(bytes(d))
EOF3
OPV="$W/vj_op.bin"
vs_ctl_is index-changed && OPV="$W/vj_op_bad.bin"
vs_ctl_is branch-flipped && OPV="$W/vj_op_flip.bin"

read_table() { # <opcode view> <data view>: the instruction, the reference count, the rows
    python3 - "$1" "$2" <<'EOF'
import sys
op = open(sys.argv[1], 'rb').read(); da = open(sys.argv[2], 'rb').read()
ins = op[0x027B92:0x027B98]
print("INSN 0x027b92 " + ins.hex())
refs = []; a = op.find(bytes.fromhex('000be23a'))
while a >= 0: refs.append(a); a = op.find(bytes.fromhex('000be23a'), a + 1)
print("REFS " + " ".join("0x%06x" % r for r in refs))
base = int.from_bytes(ins[2:6], 'big') if ins[:2] == b'\x20\x7c' else None
if base is None: print("BASE none"); sys.exit(0)
print("BASE 0x%06x" % base)
sys.path.insert(0, "tools")
import capstone
md = capstone.Cs(capstone.CS_ARCH_M68K, capstone.CS_MODE_BIG_ENDIAN | capstone.CS_MODE_M68K_000)
seq = []
for i in md.disasm(op[0x027B98:0x027BB0], 0x027B98):
    seq.append((i.mnemonic + " " + i.op_str).strip())
    if len(seq) == 8: break
print("INDEX " + " ; ".join(seq))
print("ROUTINE " + " ; ".join("%x %s" % (i.address, (i.mnemonic + " " + i.op_str).strip())
                              for i in md.disasm(op[0x027B80:0x027BC2], 0x027B80)))
T = 0x027B80; calls = []
for p in range(0, len(op) - 6, 2):
    if op[p:p + 2] in (b'\x4e\xb9', b'\x4e\xf9') and int.from_bytes(op[p + 2:p + 6], 'big') == T: calls.append(p)
    if op[p:p + 2] in (b'\x4e\xb8', b'\x4e\xf8') and (int.from_bytes(op[p + 2:p + 4], 'big', signed=True) & 0xFFFFFF) == T: calls.append(p)
    if op[p:p + 2] in (b'\x4e\xba', b'\x4e\xfa') and p + 2 + int.from_bytes(op[p + 2:p + 4], 'big', signed=True) == T: calls.append(p)
    if 0x60 <= op[p] <= 0x6F:  # bra, bsr and every Bcc
        d8 = op[p + 1]
        if d8 == 0 and p + 2 + int.from_bytes(op[p + 2:p + 4], 'big', signed=True) == T: calls.append(p)
        elif d8 not in (0, 0xff) and p + 2 + (d8 - 256 if d8 > 127 else d8) == T: calls.append(p)
    if (int.from_bytes(op[p:p + 2], 'big') & 0xF0F8) == 0x50C8 and p + 2 + int.from_bytes(op[p + 2:p + 4], 'big', signed=True) == T: calls.append(p)  # DBcc
print("CALLERS %d %s" % (len(calls), " ".join("%06x" % c for c in calls)))
rows = [int.from_bytes(da[base + 2 * i:base + 2 * i + 2], 'big') for i in range(0x20)]
print("NONZERO " + " ".join("%02x:%d" % (i, v) for i, v in enumerate(rows) if v))
print("ZERO " + str(sum(1 for v in rows if v == 0)) + " of 32")
EOF
}
read_table "$OPV" "$DATA" > "$W/out.txt" || { note "  FAIL: the reader errored"; fail=1; }
sed 's/^/    /' "$W/out.txt"
row() { grep "^$1" "$W/out.txt" | head -1; }

note "1. the table address, from the code that reads it"
chk "the instruction (movea.l #imm,a0)" "INSN 0x027b92 207c000be23a" "$(row INSN)"
chk "its only reference in the opcode view" "REFS 0x027b94" "$(row REFS)"
chk "the base" "BASE 0x0be23a" "$(row BASE)"
chk "the routine, decoded whole (which branch returns 0, which 1)" "ROUTINE 27b80 tst.b \$190(a6) ; 27b84 bne.b \$27bb0 ; 27b86 tst.b \$121(a6) ; 27b8a bne.b \$27bbe ; 27b8c tst.b \$38(a6) ; 27b90 beq.b \$27bb0 ; 27b92 movea.l #\$be23a, a0 ; 27b98 move.w \$14(a6), d0 ; 27b9c sub.w \$3a(a6), d0 ; 27ba0 move.b \$382(a6), d1 ; 27ba4 ext.w d1 ; 27ba6 add.w d1, d1 ; 27ba8 move.w (a0, d1.w), d1 ; 27bac cmp.w d1, d0 ; 27bae bcs.b \$27bbe ; 27bb0 move.b \$113(a6), d0 ; 27bb4 or.b \$114(a6), d0 ; 27bb8 beq.b \$27bbe ; 27bba moveq #\$1, d0 ; 27bbc rts ; 27bbe moveq #\$0, d0 ; 27bc0 rts" "$(row ROUTINE)"
chk "its direct callers" "CALLERS 15 02267c 02279e 02283a 02291e 0229a2 022b02 022b94 022f1a 022f7e 02300e 02308c 0230e4 023164 0235b6 026bc0" "$(row CALLERS)"
chk "the index: char id +0x382 at word stride" "INDEX move.w \$14(a6), d0 ; sub.w \$3a(a6), d0 ; move.b \$382(a6), d1 ; ext.w d1 ; add.w d1, d1 ; move.w (a0, d1.w), d1 ; cmp.w d1, d0 ; bcs.b \$27bbe" "$(row INDEX)"
note "2. the rows (vsavj ids 0x00-0x1F)"
chk "non-zero rows" "NONZERO 04:24 0d:24 0f:24 14:24 1d:24 1f:24" "$(row NONZERO)"
chk "zero rows" "ZERO 26 of 32" "$(row ZERO)"

note "3. verdict control (must fire)"
if [ -z "${VS_CTL:-}" ]; then
    read_table "$W/vj_op.bin" "$W/vj_data_bad.bin" > "$W/bad.txt" || true
    if grep -q '^NONZERO 04:24 0d:24 0f:24 14:24 1d:24 1f:24$' "$W/bad.txt"; then
        vs_ctl_dead row-misread "the row compare did not see row 0x04 rewritten to 36"; fail=1
    else
        vs_ctl_fired row-misread "$(grep '^NONZERO' "$W/bad.txt")"
    fi
    read_table "$W/vj_op_bad.bin" "$W/vj_data.bin" > "$W/bad2.txt" || true
    if [ "$(grep '^INDEX' "$W/bad2.txt")" = "$(row INDEX)" ]; then
        vs_ctl_dead index-changed "the index sequence did not change with add.w d1,d1 replaced"; fail=1
    else
        vs_ctl_fired index-changed "$(grep '^INDEX' "$W/bad2.txt" | cut -c1-120)"
    fi
    read_table "$W/vj_op_flip.bin" "$W/vj_data.bin" > "$W/bad3.txt" || true
    if [ "$(grep '^ROUTINE' "$W/bad3.txt")" = "$(row ROUTINE)" ]; then
        vs_ctl_dead branch-flipped "the routine compare did not see bcs.b turned into bcc.b"; fail=1
    else
        vs_ctl_fired branch-flipped "$(grep '^ROUTINE' "$W/bad3.txt" | grep -o '27bae [^;]*')"
    fi
fi

if [ "$fail" -eq 0 ]; then note "PASS test_air_attack_height"; else note "FAIL test_air_attack_height"; exit 1; fi
