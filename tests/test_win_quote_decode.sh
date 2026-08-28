#!/usr/bin/env bash
# test_win_quote_decode.sh — the win-quote text system's STRUCTURE, frozen
# (14z-116). ci_static: needs ROMDIR only, no emulator, no build dir.
#
# WHAT THIS LOCKS, and why each line is here rather than in a session log.
# The 14z-76 decode of the win-quote system lived only in prose, and its two
# load-bearing numbers turned out to be wrong when finally measured:
#   - "the bank is ~0x40DC bytes" — that is the FIRST-LEVEL OFFSET of the
#     forced row, not a size; bank 0 actually spans 0x4104 bytes and the four
#     region banks span 0x4104/0x5B90/0x6130/0x5F2A.
#   - "a line is 16 codes" — vsavj ships lines of 17. The real bound is the
#     renderer's own 66-word buffer (`PRG:0x089062`, +0x4C..+0xD0).
# Both are now asserted against the pristine dumps, so the next session reads
# measurements instead of re-deriving them, and a wrong constant is loud.
#
# SECTIONS
#   1  the ROOT IS A 4-ENTRY REGION ARRAY (not one long): the four bank bases
#   2  the first-level ALIAS pattern that IS the defect (0x10->0x00 etc.)
#   3  every winner's every reachable line walks clean on all four banks
#   4  vs2 carries the three tenant blocks, and its variant half is NOT
#      aliased at exactly 0x10/0x11/0x13
#   5  VERDICT CONTROLS (must fire): a perturbed offset, an overlong record
#
# Usage: ROMDIR=... tests/test_win_quote_decode.sh
set -eu
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
ROMDIR="${ROMDIR:?set ROMDIR}"

. "$REPO/tests/lib/decrypt_cache.sh"   # GitHub #69: never re-decrypt directly
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT
DEC=tools/decode_win_quotes.py
fail=0
note() { printf '%s\n' "$*"; }
chk() { # label expected actual
    if [ "$2" = "$3" ]; then note "  ok   $1"; else note "  FAIL $1: expected [$2] got [$3]"; fail=1; fi
}

# Both views come from the shared cache, which is size-checked and atomic —
# a half-written image is a loud failure, never a truncated one this gate
# would then make claims about (GitHub #69).
decrypt_view vsavj "$W/vsavj_op.bin" "$W/vsavj_data.bin"
decrypt_view vsav2 "$W/vsav2_op.bin" "$W/vsav2_data.bin"

note "1. the root is a 4-entry REGION array"
banks=$(python3 - "$W/vsavj_data.bin" <<'EOF'
import sys
d=open(sys.argv[1],'rb').read()
print(' '.join(f"{int.from_bytes(d[0x112BC+4*i:0x112C0+4*i],'big'):06x}" for i in range(4)))
EOF
)
chk "region bank bases" "32d28a 335694 340b44 34c8d4" "$banks"

note "2. the first-level alias pattern (the defect itself)"
al=$(python3 - "$W/vsavj_data.bin" <<'EOF'
import sys
d=open(sys.argv[1],'rb').read(); B=0x32D28A
sw=lambda a:int.from_bytes(d[a:a+2],'big',signed=True)
fl=[sw(B+2*i) for i in range(0x21)]
print(','.join(f"{v:02x}->{fl.index(fl[v]):02x}" for v in (0x10,0x11,0x13)))
EOF
)
chk "variant rows alias the base half" "10->00,11->01,13->03" "$al"

note "3. every reachable line walks clean, all four regions"
for r in 0 1 2 3; do
    out="$W/dump_$r.txt"
    python3 "$DEC" dump "$W/vsavj_data.bin" --opcodes "$W/vsavj_op.bin" \
        --region "$r" > "$out" 2>&1 || { note "  FAIL: dump region $r"; fail=1; continue; }
    n=$(grep -c '^winner' "$out" || true)
    bad=$(grep -c '!!' "$out" || true)
    chk "region $r: 33 winners, 0 malformed" "33 0" "$n $bad"
done

note "4. vs2 carries the tenant blocks and does NOT alias them"
t=$(python3 - "$W/vsav2_data.bin" <<'EOF'
import sys
d=open(sys.argv[1],'rb').read(); B=0x09CA24
sw=lambda a:int.from_bytes(d[a:a+2],'big',signed=True)
fl=[sw(B+2*i) for i in range(0x21)]
out=[]
for v,base in ((0x10,0x00),(0x11,0x01),(0x13,0x03)):
    out.append(f"{v:02x}:{'own' if fl[v]!=fl[base] else 'ALIAS'}@{B+fl[v]:06x}")
print(' '.join(out))
EOF
)
chk "vs2 tenant blocks" "10:own@09fe24 11:own@0a0184 13:own@0a05e4" "$t"

note "5. verdict controls (each MUST fire)"
# 5a: a perturbed first-level word must make the walk malformed.
python3 - "$W/vsavj_data.bin" "$W/bad1.bin" <<'EOF'
import sys
d=bytearray(open(sys.argv[1],'rb').read()); B=0x32D28A
d[B+2*0x10:B+2*0x10+2]=(0x7ffe).to_bytes(2,'big')   # offset far out of the bank
open(sys.argv[2],'wb').write(bytes(d))
EOF
if python3 "$DEC" dump "$W/bad1.bin" --opcodes "$W/vsavj_op.bin" --winner 0x10 --verbose 2>&1 | grep -q '!!'; then
    note "  ok   control 5a fired (perturbed first-level offset is loud)"
else
    note "  FAIL control 5a did NOT fire — the walker accepts a bad offset"; fail=1
fi
# 5b: an overlong record must be refused against the renderer's buffer.
python3 - "$W/vsavj_data.bin" "$W/bad2.bin" <<'EOF'
import sys
d=bytearray(open(sys.argv[1],'rb').read())
# winner 0x00's first string starts at 0x32D2EE; make its length absurd.
d[0x32D2EE:0x32D2F0]=(0x0100).to_bytes(2,'big')
open(sys.argv[2],'wb').write(bytes(d))
EOF
if python3 "$DEC" dump "$W/bad2.bin" --opcodes "$W/vsavj_op.bin" --winner 0x00 2>&1 | grep -q 'buffer'; then
    note "  ok   control 5b fired (overlong record named against the buffer)"
else
    note "  FAIL control 5b did NOT fire — an overrun would pass"; fail=1
fi

if [ "$fail" -eq 0 ]; then note "PASS test_win_quote_decode"; else note "FAIL test_win_quote_decode"; fi
exit "$fail"
