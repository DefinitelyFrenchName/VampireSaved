#!/bin/sh
# test_power_decode.sh — AN ATTACK RECORD'S POWER BYTE IS DECODED AS THE ENGINE DECODES IT
# (14z-195, GitHub #241). ci_static: needs the vsavj and vsav2 decrypted views (the build/out
# cache, else ROMDIR); no emulator, ~3 s.
#
# WHAT: a record's +8 (real) and +9 (white) are POWER bytes, not damage amounts: bits 0-4 the
#   class the scaler indexes, bit 5 skips the attacker's stat row, bit 7 is the no-kill clamp.
#   The engine side is read from both games' own instruction words, and the derivation's side
#   (tools/vanilla_frames.py through tools/hitbox_records.power) is held on the case that found
#   it: Zabel's pursuit, which read 258 red / 130 white undecoded for a hit the game scores
#   0 red / 2 white.
# HOW: section 1 compares the opcode words at the decode sites on vsavj and vsav2 (the scaler's
#   `andi.w #$1f,d2` and `btst #5,d0`; the post-process's `tst.b $8(a3)` / `tst.b $9(a3)` each
#   followed by `bpl`), from each game's own opcode view. Section 2 derives vsavj and reads
#   Zabel's P pursuit chain a2:0x56 (named by the #229 measurement, 14z-194: the chain
#   a2:0x40>a2:0x56; the maintainer confirmed the identity on capture sheets) and its records'
#   flags; section 3 prints the flag census over every record the derivation reaches (NOTE).
# EXPECTS: section 1 every word as listed; section 2 red 0 / white 2 with bit 7 set on both
#   bytes of the pursuit records (0x80 / 0x82 raw); a red is a site whose words moved or a
#   derivation that reports the raw byte.
#
# MUST-FIRE: perturbed-copy: raw-power — the derivation run with each record's class replaced by its raw byte (the pre-#241 reader) must read Zabel's pursuit as 128 / 130, and the gate must FAIL (mode: section 2 reads the raw derivation)
# MUST-FIRE: perturbed-copy: mask-moved — a copy of the vsavj opcode view with the scaler's mask immediate changed from 0x1F to 0x3F must fail section 1 (mode: section 1 reads the perturbed copy)
#
# WHY: the cross-check's derivation reported the raw bytes as damage, and the comparator's page
# carried a hand rule for Zabel ("compared on the HP the game takes") instead of the decode.
# The decode is docs/game/engine_internals.md "The DAMAGE pipeline: two appliers, one scaler chain"; [VSE-41] names the no-kill bit.
set -u
REPO="$(cd "$(dirname "$0")/.." && pwd)"; cd "$REPO"
. "$REPO/tests/lib/controls.sh"; vs_ctl_mode "$0"
W="$(mktemp -d "${TMPDIR:-/tmp}/powdec.XXXXXX")"; trap 'rm -rf "$W"' EXIT
fail=0; ok() { echo "  ok    $*"; }; bad() { echo "  FAIL  $*"; fail=1; }

if [ -f build/out/vsavj_opcodes.bin ] && [ -f build/out/vsav2_opcodes.bin ] && [ -f build/out/vsavj_data.bin ]; then
    OPJ=build/out/vsavj_opcodes.bin; OP2=build/out/vsav2_opcodes.bin; DATJ=build/out/vsavj_data.bin
elif [ -n "${ROMDIR:-}" ]; then
    . "$REPO/tests/lib/decrypt_cache.sh"
    decrypt_view vsavj "$W/vsavj_op.bin" "$W/vsavj_data.bin" >/dev/null 2>&1 || { echo "SKIP: the vsavj views could not be made"; exit 0; }
    decrypt_view vsav2 "$W/vsav2_op.bin" "$W/vsav2_data.bin" >/dev/null 2>&1 || { echo "SKIP: the vsav2 views could not be made"; exit 0; }
    OPJ="$W/vsavj_op.bin"; OP2="$W/vsav2_op.bin"; DATJ="$W/vsavj_data.bin"
else
    echo "SKIP: no decrypted views in build/out and no ROMDIR (the views are ROM-derived)"; exit 0
fi

perturb_mask() {  # perturb_mask <in.bin> <out.bin> — the vsavj scaler's mask 0x1F -> 0x3F
    python3 - "$1" "$2" <<'PY'
import sys
b = bytearray(open(sys.argv[1], "rb").read())
assert b[0x18B8E:0x18B92] == bytes.fromhex("0242001f"), "the mask moved before the perturbation"
b[0x18B91] = 0x3F
open(sys.argv[2], "wb").write(b)
PY
}
derive() {  # derive <data image> <out.json> [raw] — the derivation, or the pre-#241 raw reader
    python3 - "$1" "$2" "${3:-}" <<'PY'
import runpy, sys
img, out, raw = sys.argv[1], sys.argv[2], sys.argv[3]
sys.path.insert(0, "tools")
if raw:
    import hitbox_records as hr
    orig = hr.HitboxSet.record
    def record(self, idx, proj=False):
        r = orig(self, idx, proj)
        r["real_class"], r["white_class"] = r["real"], r["white"]
        return r
    hr.HitboxSet.record = record
sys.argv = ["tools/vanilla_frames.py", img, "--json", out]
runpy.run_path("tools/vanilla_frames.py", run_name="__main__")
PY
}
words() {  # words <vsavj opcode view> <vsav2 opcode view> — section 1's verdict lines
    python3 - "$1" "$2" <<'PY'
import sys
SITES = {  # game: [(address, expected words, what)]
    "vsavj": [(0x18B8E, "0242001f", "scaler andi.w #$1f,d2 (the class)"),
              (0x18B96, "08000005", "scaler btst #5,d0 (nostat)"),
              (0x18ACC, "4a2b00086a", "post-process tst.b $8(a3); bpl (real nokill)"),
              (0x18AEE, "4a2b00096a", "post-process tst.b $9(a3); bpl (white nokill)")],
    "vsav2": [(0x17524, "0242001f", "scaler andi.w #$1f,d2 (the class)"),
              (0x1752C, "08000005", "scaler btst #5,d0 (nostat)"),
              (0x1745E, "4a2b00086a", "post-process tst.b $8(a3); bpl (real nokill)"),
              (0x17480, "4a2b00096a", "post-process tst.b $9(a3); bpl (white nokill)")]}
for game, path in (("vsavj", sys.argv[1]), ("vsav2", sys.argv[2])):
    img = open(path, "rb").read()
    for a, want, what in SITES[game]:
        got = img[a:a + len(want) // 2].hex()
        print(f"{'ok' if got == want else 'BAD'} {game} {a:#08x} {what}: {got}")
PY
}

OPJ1="$OPJ"; if vs_ctl_is mask-moved; then perturb_mask "$OPJ" "$W/opj_bad.bin" || { echo "FAIL: could not perturb"; exit 1; }; OPJ1="$W/opj_bad.bin"; fi
echo "== 1. the engine decodes the power byte (each game's own opcode words)"
words "$OPJ1" "$OP2" > "$W/w.txt" 2>&1
while IFS= read -r l; do case "$l" in ok\ *) ok "${l#ok }" ;; *) bad "$l" ;; esac; done < "$W/w.txt"
[ "$(grep -c '^ok ' "$W/w.txt")" = 8 ] || bad "expected 8 decode sites, read $(grep -c '^ok ' "$W/w.txt")"

echo "== 2. the derivation decodes it (Zabel's pursuit, #241)"
RAW=""; vs_ctl_is raw-power && RAW=raw
derive "$DATJ" "$W/v.json" "$RAW" > "$W/derive.log" 2>&1 || { bad "vanilla_frames failed"; sed 's/^/        /' "$W/derive.log"; }
zread() { python3 - "$1" <<'PY'
import json, sys
c = json.load(open(sys.argv[1]))["characters"]["ZA"]["chains"]["a2:0x56"]
d = c["damage"]; recs = c["records"]
flags = sorted({(r.get("real_flags"), r.get("white_flags")) for r in recs.values() if (r.get("real_flags") or r.get("white_flags"))})
print(f"{d['red']} {d['white']} {flags}")
PY
}
z="$(zread "$W/v.json" 2>&1)"
case "$z" in
    "0 2 [(128, 128)]") ok "Zabel's P pursuit (a2:0x56) reads red 0 / white 2, the game's figure; its records carry bit 7 on both bytes" ;;
    *) bad "Zabel's P pursuit (a2:0x56) reads '$z' (want: 0 2 [(128, 128)])" ;;
esac

echo "== 3. the flag census over every record the derivation reaches (NOTE)"
python3 - "$W/v.json" <<'PY'
import json, sys
v = json.load(open(sys.argv[1]))["characters"]
seen, n = {}, {"real": [0, 0, 0], "white": [0, 0, 0]}
for tab, c in v.items():
    for ch in c["chains"].values():
        for a, r in ch.get("records", {}).items():
            seen[(tab, a)] = r
for r in seen.values():
    for f in ("real", "white"):
        fl = r.get(f + "_flags") or 0
        for i, bit in enumerate((0x20, 0x40, 0x80)):
            n[f][i] += bool(fl & bit)
print(f"  NOTE  {len(seen)} distinct records over 15 characters: bit 5 (nostat) real {n['real'][0]} white {n['white'][0]}; "
      f"bit 6 real {n['real'][1]} white {n['white'][1]}; bit 7 (nokill) real {n['real'][2]} white {n['white'][2]}")
PY

echo "== 4. controls"
if vs_ctl_is mask-moved || vs_ctl_is raw-power; then
    vs_ctl_fired "$VS_CTL" "the perturbed input ran in its section (mode)"
else
    perturb_mask "$OPJ" "$W/opj_bad.bin" && words "$W/opj_bad.bin" "$OP2" > "$W/w_bad.txt" 2>&1
    grep -q '^BAD vsavj 0x018b8e' "$W/w_bad.txt" && vs_ctl_fired mask-moved "the 0x3F copy fails the vsavj class mask" \
        || { vs_ctl_dead mask-moved "the perturbed copy passed section 1"; fail=1; }
    derive "$DATJ" "$W/v_raw.json" raw > "$W/derive_raw.log" 2>&1
    zr="$(zread "$W/v_raw.json" 2>&1)"
    case "$zr" in "128 130"*) vs_ctl_fired raw-power "the raw reader reads Zabel's pursuit as $zr" ;;
        *) vs_ctl_dead raw-power "the raw reader read '$zr'"; fail=1 ;; esac
fi
[ "$fail" -eq 0 ] && echo "PASS" || echo "FAIL"
exit "$fail"
