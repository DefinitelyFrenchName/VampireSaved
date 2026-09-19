#!/bin/sh
# test_defense_rows_census.sh — THE DEFENSE CURVE AND RALLY THRESHOLD OF EVERY CHARACTER ID, vsavj against vs2 and our build, frozen (14z-168): the 15 legacy characters are identical between the games but for Sasquatch's row, vsavj's variant ids carry COPIES of their base rows, and our tenants therefore take their SHELLS' rows — the measurement the 2026-09-18 ruling "take the vs2 rows" rests on.
#
# MUST-FIRE: perturbed-copy: tenant-row-moved — a copy of our build's data view with Phobos's row 0x10 overwritten by his vs2 row (what the ruled fix will do) must FAIL the frozen compare, so the frozen rows are read from the build under test and the fix re-freezes this file deliberately (in-gate: the perturbed view must census differently; mode: the gate censuses the perturbed view and FAILs)
#
# MUST-FIRE: perturbed-copy: reader-planted — a copy of our build's opcode image with an absolute load of an address INSIDE the curve (`movea.l #$000B8980,a1`, 0x100 bytes before the image's end) and a `lea d16(pc),a0` landing on the threshold table must add one reader row per arm and FAIL the frozen compare, so both arms of the reader census read the image they are given (in-gate: the planted copy must add exactly those two rows; mode: the gate censuses the planted copy and FAILs)
#
# WHY. The maintainer asked, before ruling on the tenants' defense rows (2026-09-18,
# 14z-168): "compare the defense-side rows between characters present in both vsavj
# and VS2 and whether the approximated rows we are currently using are not, in fact,
# inherited from the shell characters". This is that comparison, kept as a gate.
# The tables (docs/project/tables/defense_rows.md): the defense curve, 32 B per
# victim id (vsavj PRG:0x0B8940, vs2 PRG:0x0D2ABE; the damage code reads row = the
# victim's full id, column = the attacker's id — tests/audit_defense_row_residue.sh),
# and the low-HP rally threshold, 1 B per id (vsavj PRG:0x0BCC80, vs2 PRG:0x0D6E1E).
# The shells (docs/game/engine_internals.md): Phobos 0x10 -> Bulleta 0x00, Pyron
# 0x11 -> Demitri 0x01, Donovan 0x13 -> Victor 0x03.
#
# WHO READS THE TWO TABLES (added 14z-169, rule-checker run 2026-09-18-51 Q4: the live
# gate tests/audit_defense_row_reads.sh taps only the two known reads, so a reader at
# another pc would be invisible to it): every even offset of vsavj's and vs2's opcode views
# and of our build's whole opcode image holding an address INSIDE a table as an absolute long
# (the `movea.l #imm` / absolute-operand forms; the base alone until run 2026-09-18-52 Q1), and every
# `lea d16(pc),An` / `pea d16(pc)` whose target lands inside a table. Measured: exactly the two host reads on vsavj and ours
# (PRG:0x018C20 the curve, 0x018C7C the threshold), their twins on vs2. NOT COVERED: a base
# computed at run time, `(d8,pc,Xn)` forms, a `(d16,pc)` operand of any instruction other than
# lea/pea (it reaches only 32 KB either side, i.e. code inside the tables' own region), and a
# table reached through a pointer in data. The scan is a raw match at every even offset, code and
# data alike: a row can be data that happens to equal a table address, never a missed long.
#
# FROZEN: tests/expected/defense_rows_census.tsv —
#   base <id> <name> row=<SAME|DIFFERS> thr=<vsavj>/<vs2>   (ids 0x00-0x0F, vsavj vs vs2)
#   variant <id> <copy of base|own>                         (vsavj's ids 0x10-0x1F)
#   tenant <id> <name> ours=<curve class> thr=<x> native=<curve class> thr=<x>
#   reader <game> <table> <instruction pc> <form>          (since 14z-169)
# where a curve class names the base characters whose vsavj row it equals.
#
# Usage: ROMDIR=... [BUILD=build/m3b_merged27] [FREEZE=1] tests/test_defense_rows_census.sh
#   static tier (the decrypt cache, a build's data view); measured 14z-168 on this MacBook: ~2 s
set -eu
[ -n "${ROMDIR:-}" ] || { echo "FAIL: set ROMDIR"; exit 1; }
[ -d "$ROMDIR" ] && ROMDIR="$(cd "$ROMDIR" && pwd)"
REPO="$(cd "$(dirname "$0")/.." && pwd)"
BUILD="${BUILD:-build/m3b_merged27}"
case "$BUILD" in /*) ;; *) BUILD="$REPO/$BUILD" ;; esac
EXPECT="$REPO/tests/expected/defense_rows_census.tsv"
CONTROL="${CONTROL:-}"
[ -f "$BUILD/verify_data.bin" ] || { echo "SKIP: no verify_data.bin in $BUILD"; exit 0; }
case "$CONTROL" in ""|tenant-row-moved|reader-planted) ;; *) echo "REFUSED: no control named '$CONTROL' is declared by this gate"; exit 3 ;; esac
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT INT TERM
fail=0
ok()  { printf '  ok    %s\n' "$1"; }
bad() { printf '  FAIL  %s\n' "$1"; fail=1; }

echo "== 1. the three data views"
. "$REPO/tests/lib/decrypt_cache.sh"
decrypt_view vsav2 "$W/v2_op.bin" "$W/v2_da.bin" || bad "vsav2 views not delivered"
decrypt_view vsavj "$W/vj_op.bin" "$W/vj_da.bin" || bad "vsavj views not delivered"
[ "$fail" = 0 ] || { echo "FAIL: test_defense_rows_census"; exit 1; }
cp "$BUILD/verify_data.bin" "$W/ours_da.bin"
[ -f "$BUILD/verify_op.bin" ] || { echo "SKIP: no verify_op.bin in $BUILD"; exit 0; }
cp "$BUILD/verify_op.bin" "$W/ours_op.bin"
# ONE planting function for the reader census ([VSP-181]): an extra absolute load of the curve's base
plant_reader() {  # plant_reader <ours op in> <out>: BOTH arms, in a copy — movea.l #$000B8980,a1 (an address INSIDE the
    # curve) 0x100 bytes before the image's end, and lea d16(pc),a0 landing on the threshold table 0x100 bytes below it
    python3 - "$1" "$2" <<'PY'
import sys, struct
o = bytearray(open(sys.argv[1], "rb").read())
a = len(o) - 0x100
o[a:a + 6] = bytes.fromhex("227c000b8980")
b = 0x0BCC80 - 0x100
o[b:b + 4] = bytes.fromhex("41fa") + struct.pack(">h", 0x0BCC80 - (b + 2))
open(sys.argv[2], "wb").write(o)
PY
}
if [ "$CONTROL" = reader-planted ]; then plant_reader "$W/ours_op.bin" "$W/ours_opp.bin" && mv "$W/ours_opp.bin" "$W/ours_op.bin"; fi
# ONE reader census, shared by the gate and the in-gate control
readers() {  # readers <vsavj op> <vs2 op> <ours op>
    python3 - "$@" <<'PY'
import sys, struct
imgs = [("vsavj", open(sys.argv[1], "rb").read(), 0x100000), ("vs2", open(sys.argv[2], "rb").read(), 0x100000), ("ours", open(sys.argv[3], "rb").read(), None)]
TAB = {"vsavj": {"curve": (0xB8940, 0x400), "threshold": (0xBCC80, 0x20)}, "vs2": {"curve": (0xD2ABE, 0x400), "threshold": (0xD6E1E, 0x20)}}
TAB["ours"] = TAB["vsavj"]
for g, img, end in imgs:
    end = end or len(img)
    for name, (base, size) in TAB[g].items():
        for a in range(2, end - 4, 2):
            v = struct.unpack(">I", img[a:a + 4])[0]
            if base <= v < base + size:
                print(f"reader\t{g}\t{name}\t{a - 2:06x}\tabs-long@{a:06x}" + ("" if v == base else f"+{v - base:#x}"))
        for a in range(0, end - 4, 2):
            w = struct.unpack(">H", img[a:a + 2])[0]
            if (w & 0xF1FF) == 0x41FA or w == 0x487A:
                t = a + 2 + struct.unpack(">h", img[a + 2:a + 4])[0]
                if base <= t < base + size:
                    print(f"reader\t{g}\t{name}\t{a:06x}\t{'lea' if w != 0x487A else 'pea'}-pc@{t:06x}")
PY
}
# ONE perturbation, shared by the in-gate control and the mode ([VSP-181])
move_row() {  # move_row <ours view in> <out>: Phobos's row 0x10 given his vs2 row
    python3 - "$1" "$W/v2_da.bin" "$2" <<'PY'
import sys
o = bytearray(open(sys.argv[1], "rb").read()); v2 = open(sys.argv[2], "rb").read()
o[0xB8940 + 0x10 * 32: 0xB8940 + 0x11 * 32] = v2[0xD2ABE + 0x10 * 32: 0xD2ABE + 0x11 * 32]
open(sys.argv[3], "wb").write(o)
PY
}
if [ "$CONTROL" = tenant-row-moved ]; then move_row "$W/ours_da.bin" "$W/ours_p.bin" && mv "$W/ours_p.bin" "$W/ours_da.bin"; fi
# ONE census, shared by the gate and the in-gate control
census() {  # census <vsavj view> <vs2 view> <ours view>
    python3 - "$@" <<'PY'
import sys, hashlib
vj, v2, ou = (open(p, "rb").read() for p in sys.argv[1:4])
for n, b in (("vsavj", vj), ("vs2", v2), ("ours", ou)):
    print(f"# {n} data view sha1 {hashlib.sha1(b).hexdigest()}", file=sys.stderr)
DJ, D2, TJ, T2 = 0xB8940, 0xD2ABE, 0xBCC80, 0xD6E1E
NAME = "Bulleta Demitri Gallon Victor Zabel Morrigan Anakaris Felicia Bishamon Aulbath Sasquatch random Q-Bee Lei-Lei Lilith Jedah".split()
row = lambda b, base, i: b[base + i * 32: base + i * 32 + 32]
def cls(r, b, base):
    who = [NAME[k] for k in range(16) if row(b, base, k) == r]
    return "+".join(who) if who else "own"
for i in range(16):
    print(f"base\t{i:#04x}\t{NAME[i]}\trow={'SAME' if row(vj, DJ, i) == row(v2, D2, i) else 'DIFFERS'}\tthr={vj[TJ + i]:#04x}/{v2[T2 + i]:#04x}")
for k in range(16):
    cp = row(vj, DJ, 0x10 + k) == row(vj, DJ, k) and vj[TJ + 0x10 + k] == vj[TJ + k]
    print(f"variant\t{0x10 + k:#04x}\t{'copy of ' + NAME[k] if cp else 'own'}")
for t, n in ((0x10, "Phobos"), (0x11, "Pyron"), (0x13, "Donovan")):
    print(f"tenant\t{t:#04x}\t{n}\tours={cls(row(ou, DJ, t), vj, DJ)}\tthr={ou[TJ + t]:#04x}\tnative={cls(row(v2, D2, t), v2, D2)}\tthr={v2[T2 + t]:#04x}")
PY
}
census "$W/vj_da.bin" "$W/v2_da.bin" "$W/ours_da.bin" > "$W/got.tsv" 2> "$W/sha.txt" || { bad "census: $(tail -1 "$W/sha.txt")"; }
readers "$W/vj_op.bin" "$W/v2_op.bin" "$W/ours_op.bin" >> "$W/got.tsv" 2>> "$W/sha.txt" || { bad "reader census: $(tail -1 "$W/sha.txt")"; }
[ "$fail" = 0 ] || { echo "FAIL: test_defense_rows_census"; exit 1; }
sed 's/^/  /' "$W/sha.txt"
echo "== 2. the census"
sed 's/^/  /' "$W/got.tsv" | grep -v -E '^  (variant|base)' || true
for g in vsavj ours; do
    _r="$(awk -F'\t' -v g="$g" '$1=="reader" && $2==g {printf "%s:%s ", $3, $4}' "$W/got.tsv")"
    [ "$_r" = "curve:018c20 threshold:018c7c " ] && ok "$g: the two tables are named only by the two host reads" || bad "$g: the tables are named by [$_r], not only by the two host reads"
done
ok "$(grep -c '^base' "$W/got.tsv" | tr -d ' ') base ids ($(awk -F'\t' '$1=="base" && $4=="row=DIFFERS" {printf "%s ", $3}' "$W/got.tsv")differ); $(awk -F'\t' '$1=="variant" && $3 ~ /^copy/' "$W/got.tsv" | grep -c . | tr -d ' ') of 16 variant rows are copies"

echo "== 3. the frozen rows"
if [ "${FREEZE:-0}" = 1 ]; then
    [ "$fail" = 0 ] && [ -z "$CONTROL" ] || { echo "FAIL: test_defense_rows_census (not frozen: fix the red first, no control)"; exit 1; }
    { echo "# tests/expected/defense_rows_census.tsv — the defense curve (vsavj 0x0B8940 / vs2 0x0D2ABE) and rally threshold (0x0BCC80 / 0x0D6E1E)"
      echo "# of every character id, vsavj vs vs2, and the tenants' rows on $(basename "$BUILD") (tests/test_defense_rows_census.sh). Evidence"
      echo "# class: static. Frozen 14z-168 with FREEZE=1. The ruled fix (2026-09-18, take the vs2 rows) moves the tenant rows: re-freeze then."
      echo "# The reader rows (every instruction naming either table by an absolute long or a pc-relative lea/pea) added and re-frozen 14z-169."
      echo "#--"; cat "$W/got.tsv"; } > "$EXPECT"
    echo "  FROZE  $(basename "$EXPECT") ($(wc -l < "$W/got.tsv" | tr -d ' ') rows) — VERIFY by re-running without FREEZE"; exit 0
fi
[ -f "$EXPECT" ] || { echo "FAIL: no frozen expectation at $EXPECT (FREEZE=1 to create it)"; exit 1; }
grep -v '^#' "$EXPECT" > "$W/want.tsv"
if diff "$W/want.tsv" "$W/got.tsv" > "$W/diff.txt"; then ok "every row as frozen"
else bad "differs from the frozen rows"; sed 's/^/        /' "$W/diff.txt"; fi

echo "== 4. must-fire controls"
if [ "$CONTROL" = reader-planted ]; then
    if [ "$fail" = 1 ]; then echo "CONTROL FIRED: reader-planted — the planted absolute load and pc-relative lea add reader rows"; echo "FAIL: test_defense_rows_census (control mode)"; exit 1
    else echo "CONTROL DEAD: reader-planted — the planted load changed nothing"; echo "FAIL: test_defense_rows_census"; exit 1; fi
fi
plant_reader "$W/ours_op.bin" "$W/ctl_op.bin"
readers "$W/vj_op.bin" "$W/v2_op.bin" "$W/ctl_op.bin" > "$W/ctl_r.tsv" 2>/dev/null || true
_add="$(grep '^reader' "$W/got.tsv" | diff - "$W/ctl_r.tsv" | grep -c '^>' | tr -d ' ')" || true
_arms="$(grep '^reader' "$W/got.tsv" | diff - "$W/ctl_r.tsv" | sed -n 's/^> //p' | awk -F'\t' '{split($5, f, "@"); print f[1]}' | sort | tr '\n' ' ')"
if [ "$_add" = 2 ] && [ "$_arms" = "abs-long lea-pc " ]; then echo "CONTROL FIRED: reader-planted — both planted arms read as rows: $(grep '^reader' "$W/got.tsv" | diff - "$W/ctl_r.tsv" | sed -n 's/^> //p' | tr '\t' ' ' | tr '\n' ';')"
else echo "CONTROL DEAD: reader-planted — the planted copy added $_add reader rows ($_arms), not one per arm"; fail=1; fi
if [ "$CONTROL" = tenant-row-moved ]; then
    if [ "$fail" = 1 ]; then echo "CONTROL FIRED: tenant-row-moved — Phobos given his vs2 row loses the frozen rows"; echo "FAIL: test_defense_rows_census (control mode)"; exit 1
    else echo "CONTROL DEAD: tenant-row-moved — the moved row changed nothing"; echo "FAIL: test_defense_rows_census"; exit 1; fi
fi
move_row "$W/ours_da.bin" "$W/ctl_da.bin"
census "$W/vj_da.bin" "$W/v2_da.bin" "$W/ctl_da.bin" > "$W/ctl.tsv" 2>/dev/null || true
if diff -q "$W/got.tsv" "$W/ctl.tsv" > /dev/null; then echo "CONTROL DEAD: tenant-row-moved — the census did not see the moved row"; fail=1
else echo "CONTROL FIRED: tenant-row-moved — Phobos given his vs2 row reads '$(awk -F'\t' '$1=="tenant" && $3=="Phobos" {print $4}' "$W/ctl.tsv")'"; fi

if [ "$fail" = 0 ]; then echo "PASS: test_defense_rows_census"; else echo "FAIL: test_defense_rows_census"; exit 1; fi
