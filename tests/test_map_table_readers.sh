#!/bin/sh
# test_map_table_readers.sh — WHO READS THE MAP'S NAME, PORTRAIT AND POOL TABLES (14z-195, GitHub #124).
# ci_static: needs the vsavj decrypted views (the build/out cache, else ROMDIR) and, for section 3,
# the merged build's verify_op.bin; no emulator, ~2 s.
#
# WHAT: #124's fix replaces the tenant rows of the name array PRG:0x26752A and the portrait array
#   PRG:0x26762A and authors pool rows 0x10/0x11/0x13 (PRG:0x3A3CA0 + id*32). Its two owed checks are
#   held here: every absolute reference to the three tables in the vsavj program is one of six frozen
#   sites — the map (0x05FC36 / 0x05FC76), the attract SCORE RANKING (0x08C5F6 / 0x08C5E0), the map's
#   per-opponent pool copy (0x00B0A2) and a fixed pool copy (0x07D182) — and that fixed copy moves
#   rows 0x00-0x0F only (`moveq #$f,d7`), so pool rows 0x10/0x11/0x13 have one reader, the map's
#   per-id copy. No data longword points at any of the three tables.
# HOW: section 1 scans the vsavj opcode view for every even-aligned 32-bit occurrence of the three
#   base addresses (an abs.l or immediate operand carries the value itself) and the data view for
#   the same values as longwords; section 2 reads the fixed copy's count word; section 3 compares
#   the six readers' code bytes between pristine vsavj and the merged build (they must be unpatched,
#   or a measurement on one says nothing about the other).
# EXPECTS: exactly the six operand sites, zero data longwords, the count 0x0F, byte-identical readers.
#   NOT covered: a PC-RELATIVE reference (its displacement does not carry the address; a capstone
#   census found none at 14z-195) or an address formed by arithmetic — what the engine READS at run
#   time is tests/audit_ranking_tenant.sh's question for the ranking.
#
# MUST-FIRE: perturbed-copy: extra-reader — a copy of the vsavj opcode view with a seventh `movea.l #$26762a,a0` planted at the fixed even offset 0x0FFF00 must fail section 1 (mode: section 1 reads the planted copy)
# MUST-FIRE: perturbed-copy: copy-widened — the fixed pool copy's count changed from 0x0F to 0x13 in a copy must fail section 2 (mode: section 2 reads the perturbed copy)
#
# WHY: the 14z-194 analysis named the map as the only consumer; the census found the score ranking
# reads the same arrays per entry, and a tenant player's score enters it (#124's 14z-195 comment).
set -u
REPO="$(cd "$(dirname "$0")/.." && pwd)"; cd "$REPO"
. "$REPO/tests/lib/controls.sh"; vs_ctl_mode "$0"
MERGED="${MERGED:-build/m3b_merged31}"
W="$(mktemp -d "${TMPDIR:-/tmp}/mapread.XXXXXX")"; trap 'rm -rf "$W"' EXIT
fail=0; ok() { echo "  ok    $*"; }; bad() { echo "  FAIL  $*"; fail=1; }

if [ -f build/out/vsavj_opcodes.bin ] && [ -f build/out/vsavj_data.bin ]; then
    OPJ=build/out/vsavj_opcodes.bin; DATJ=build/out/vsavj_data.bin
elif [ -n "${ROMDIR:-}" ]; then
    . "$REPO/tests/lib/decrypt_cache.sh"
    decrypt_view vsavj "$W/op.bin" "$W/data.bin" >/dev/null 2>&1 || { echo "SKIP: the vsavj views could not be made"; exit 0; }
    OPJ="$W/op.bin"; DATJ="$W/data.bin"
else
    echo "SKIP: no decrypted vsavj views in build/out and no ROMDIR (the views are ROM-derived)"; exit 0
fi

perturb() {  # perturb <extra-reader|copy-widened> <in.bin> <out.bin>
    python3 - "$1" "$2" "$3" <<'PY'
import sys
kind, src, dst = sys.argv[1:]
b = bytearray(open(src, "rb").read())
if kind == "extra-reader":
    # a fixed even offset inside the scanned program range; what it overwrites is irrelevant to a census
    i = 0x0FFF00
    b[i:i + 6] = bytes.fromhex("207c0026762a")
else:
    assert b[0x07D18E:0x07D190] == bytes.fromhex("7e0f"), "the count moved before the perturbation"
    b[0x07D18F] = 0x13
open(dst, "wb").write(b)
PY
}
OP1="$OPJ"; vs_ctl_is extra-reader && { perturb extra-reader "$OPJ" "$W/op_x.bin" || exit 1; OP1="$W/op_x.bin"; }
OP2="$OPJ"; vs_ctl_is copy-widened && { perturb copy-widened "$OPJ" "$W/op_c.bin" || exit 1; OP2="$W/op_c.bin"; }
census() {  # census <opcode view> <data view> — prints "OPERANDS <sites>" and "DATALONGS <n>"
    python3 - "$1" "$2" <<'PY'
import sys
op = open(sys.argv[1], "rb").read()[:0x100000]; dat = open(sys.argv[2], "rb").read()
want = {0x26752A: "names", 0x26762A: "portraits", 0x3A3CA0: "pool"}
sites = []
for v, name in want.items():
    k = v.to_bytes(4, "big"); i = op.find(k)
    while i >= 0:
        if i % 2 == 0: sites.append(f"{i - 2:#08x}:{name}")
        i = op.find(k, i + 1)
n = 0
for v in want:
    k = v.to_bytes(4, "big"); i = dat.find(k)
    while i >= 0:
        n += (i % 2 == 0); i = dat.find(k, i + 1)
print("OPERANDS " + " ".join(sorted(sites))); print(f"DATALONGS {n}")
PY
}

echo "== 1. every absolute reference to the three tables (vsavj)"
WANT="0x00b0a2:pool 0x05fc36:names 0x05fc76:portraits 0x07d182:pool 0x08c5e0:portraits 0x08c5f6:names"
census "$OP1" "$DATJ" > "$W/c.txt"
got="$(sed -n 's/^OPERANDS //p' "$W/c.txt")"
[ "$got" = "$WANT" ] && ok "six operand sites: $got" || bad "operand sites '$got' (want '$WANT')"
[ "$(sed -n 's/^DATALONGS //p' "$W/c.txt")" = 0 ] && ok "no data longword points at any of the three tables" || bad "data longwords: $(sed -n 's/^DATALONGS //p' "$W/c.txt")"

echo "== 2. the fixed pool copy moves rows 0x00-0x0F only"
cnt="$(python3 -c "import sys; b=open(sys.argv[1],'rb').read(); print(b[0x07D18E:0x07D190].hex())" "$OP2")"
[ "$cnt" = 7e0f ] && ok "0x07D18E moveq #\$f,d7 — 16 rows from pool row 0x00" || bad "the fixed copy's count word reads $cnt (want 7e0f)"

echo "== 3. the readers are unpatched on the merged build ($MERGED)"
if [ -f "$MERGED/verify_op.bin" ]; then
    python3 - "$OPJ" "$MERGED/verify_op.bin" > "$W/m.txt" <<'PY'
import sys
a = open(sys.argv[1], "rb").read(); b = open(sys.argv[2], "rb").read()
for lo, hi, what in ((0x00B090, 0x00B0B8, "map pool copy"), (0x05FC30, 0x05FC90, "map name/portrait"),
                     (0x07D180, 0x07D196, "fixed pool copy"), (0x08C5C0, 0x08C740, "ranking + its two tables")):
    print(("same" if a[lo:hi] == b[lo:hi] else "DIFF"), f"{lo:#08x}-{hi:#08x} {what}")
PY
    while IFS= read -r l; do case "$l" in same*) ok "${l#same }" ;; *) bad "$l" ;; esac; done < "$W/m.txt"
else
    bad "no $MERGED/verify_op.bin (the merged build is the subject of #124's fix)"
fi

echo "== 4. controls"
if vs_ctl_is extra-reader || vs_ctl_is copy-widened; then
    vs_ctl_fired "$VS_CTL" "the perturbed copy ran in its section (mode)"
else
    perturb extra-reader "$OPJ" "$W/op_x.bin" && census "$W/op_x.bin" "$DATJ" > "$W/cx.txt"
    n7="$(sed -n 's/^OPERANDS //p' "$W/cx.txt" 2>/dev/null | tr ' ' '\n' | grep -c 'portraits')"
    [ "$n7" = 3 ] && vs_ctl_fired extra-reader "the census lists the planted third portrait reader (0x0fff00)" \
        || { vs_ctl_dead extra-reader "the census did not see the planted reader"; fail=1; }
    perturb copy-widened "$OPJ" "$W/op_c.bin"
    [ "$(python3 -c "import sys; print(open(sys.argv[1],'rb').read()[0x07D18E:0x07D190].hex())" "$W/op_c.bin")" != 7e0f ] \
        && vs_ctl_fired copy-widened "the widened copy's count word is not 7e0f" || { vs_ctl_dead copy-widened "unchanged"; fail=1; }
fi
[ "$fail" -eq 0 ] && echo "PASS" || echo "FAIL"
exit "$fail"
