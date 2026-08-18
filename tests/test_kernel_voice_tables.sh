#!/bin/sh
# test_kernel_voice_tables.sh — the KERNEL per-class voice tables (14z-96, GitHub #101).
#
# Freezes the ROM facts under the merged-m2 "grunt after the electrocution,
# every other time" defect (engine_internals "The KERNEL per-class voice
# tables"): the sound kernel carries FOUR per-class voice-id word tables
# (events .0-.3), each a 16-entry base + a 16-entry VARIANT table directly
# after it. On vsavj the variant half is a byte-identical COPY of the base
# half — so a tenant class (0x10/0x11/0x13) fires the LEGACY row-copy alias
# (class 0x10 → row 0x00 = Bulleta's voice, the audible grunt). On vs2 the
# variant half carries the newcomers' real voices — and Phobos' .1/.2
# entries are 0x2a1/0x2a2, ids that are FREE rows in the Z80 id table of
# BOTH games: the robot's hurt events are voiced with deliberate silence.
#
# What this gate locks:
#   1. vsavj: variant half == base half for all four events (the alias
#      shape the defect rides on — if a fix lands, section 1's expectation
#      flips to the ported rows and THIS LINE is the re-freeze site);
#   2. vs2: the full 16-word variant half per event, frozen verbatim
#      (the fix plan's source values — incl. Phobos 0730/02a1/02a2/0733,
#      Pyron 0720/02a1/02a2/0723, Donovan 0700/0701/0702/0703);
#   3. the event-nibble law: every entry of event .N ends in nibble N
#      (a wrong base address dies here instantly, both games);
#   4. 0x2a1/0x2a2 are FREE in both games' Z80 id tables (the "silence is
#      the native behavior" premise — if an authored member ever takes
#      those ids, the premise breaks and this says so);
#   5. two verdict controls (a perturbed copy must FAIL each direction).
#
# The tables sit INSIDE the crypt window and are read through the OPCODE
# view (measured: the fired id matches the opcode-view word; the data view
# shows ciphertext there). Dynamic ground truth: replay
# tests/replays/hui/95_hui_electrocuted_x4.rpl + tests/audit_hui_grunt.sh.
#
# Static, no emulator, ~5 s warm / ~25 s on a cold decrypt cache.
# Usage: ROMDIR=... tests/test_kernel_voice_tables.sh
set -u
REPO="$(cd "$(dirname "$0")/.." && pwd)"; export REPO
ROMDIR="${ROMDIR:?set ROMDIR}"
. "$REPO/tests/lib/decrypt_cache.sh"
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT
fail() { echo "FAIL: $*"; exit 1; }

decrypt_view vsavj "$W/vj_op.bin" || fail "vsavj decrypt view"
decrypt_view vsav2 "$W/v2_op.bin" || fail "vsav2 decrypt view"

python3 "$REPO/tools/audit_qs_id_table.py" "$ROMDIR/vsav.zip:vm3" \
    --id 2a1 --id 2a2 > "$W/vj_ids.txt" 2>/dev/null || fail "vsav id census"
python3 "$REPO/tools/audit_qs_id_table.py" "$ROMDIR/vsav2.zip:vs2" \
    --id 2a1 --id 2a2 > "$W/v2_ids.txt" 2>/dev/null || fail "vs2 id census"

python3 - "$W" <<'PY' || exit 1
import sys
w = sys.argv[1]
vj = open(f"{w}/vj_op.bin", "rb").read()
v2 = open(f"{w}/v2_op.bin", "rb").read()

def die(m): sys.exit(f"FAIL: {m}")
def words(img, base, n=16):
    return [int.from_bytes(img[base+2*i:base+2*i+2], "big") for i in range(n)]

VJ = {0: 0x3BCE, 1: 0x3C3A, 2: 0x3CA6, 3: 0x3D10}
V2 = {0: 0x3C04, 1: 0x3C70, 2: 0x3CDC, 3: 0x3D46}
# frozen 14z-96 from the decrypted vs2 image (variant half, rows 0x10-0x1F)
V2_VARIANT = {
    0: "0730 0720 01c0 0700 0260 0220 0340 0280 02a0 02a0 01a0 0260 0300 02c0 0240 02e0",
    1: "02a1 02a1 01c1 0701 0261 0221 0341 0281 02a1 02a1 01a1 0261 0301 02c1 0241 02e1",
    2: "02a2 02a2 01c2 0702 0262 0222 0342 0282 02a2 02a2 01a2 0262 0302 02c2 0242 02e2",
    3: "0733 0723 01c3 0703 0263 0223 0343 03e3 02a3 02a3 01a3 0263 0303 02c3 0243 02e3",
}

def check(vj_img, v2_img, label=""):
    for ev in range(4):
        b = words(vj_img, VJ[ev]); v = words(vj_img, VJ[ev] + 0x20)
        # 3. the event-nibble law first — it catches a wrong base address
        for k, wv in enumerate(b + v):
            if wv & 0xF != ev:
                die(f"{label}vsavj event .{ev} entry {k} = {wv:#06x} does not "
                    f"end in nibble {ev} — wrong base address or drifted bytes")
        # 1. vsavj: variant half is a byte-copy of the base half
        if b != v:
            die(f"{label}vsavj event .{ev}: variant half differs from base "
                f"half — the alias shape moved. If this is a DELIBERATE port "
                f"of the tenant rows, re-freeze this gate with the new rows "
                f"(see the header).")
        # 2 + 3. vs2: frozen variant half, nibble law
        vb = words(v2_img, V2[ev]); vv = words(v2_img, V2[ev] + 0x20)
        for k, wv in enumerate(vb):
            if wv & 0xF != ev:
                die(f"{label}vs2 event .{ev} base entry {k} = {wv:#06x} "
                    f"breaks the nibble law")
        want = [int(x, 16) for x in V2_VARIANT[ev].split()]
        if vv != want:
            die(f"{label}vs2 event .{ev} variant half "
                f"{' '.join(f'{x:04x}' for x in vv)} != frozen "
                f"{V2_VARIANT[ev]}")
    return True

check(vj, v2)
print("  ok: vsavj — all four events' variant halves are byte-copies of "
      "the base halves (the measured alias shape)")
print("  ok: vs2 — all four variant halves match the frozen newcomer rows")
print("  ok: event-nibble law holds on all 256 entries")

# 4. the silence premise
for leg in ("vj", "v2"):
    txt = open(f"{w}/{leg}_ids.txt").read()
    for idh in ("0x2a1", "0x2a2"):
        for line in txt.splitlines():
            if line.strip().startswith(f"id {idh}:"):
                if "[free]" not in line:
                    die(f"{leg}: {idh} is not FREE in the Z80 id table "
                        f"({line.strip()}) — the silence premise broke")
                break
        else:
            die(f"{leg}: census printed nothing for {idh}")
print("  ok: 0x2a1/0x2a2 are FREE Z80 rows in both games (silence premise)")

# 5. verdict controls — each direction must be CAUGHT
p = bytearray(vj); p[0x3BEE + 1] ^= 0x40         # perturb vsavj variant row 0x10
try:
    check(bytes(p), v2, label="[ctl-a] ")
    die("control A did not fire: a perturbed vsavj variant row passed")
except SystemExit as e:
    if "control A" in str(e): raise
print("  ok: control A fired (perturbed vsavj variant row is caught)")
q = bytearray(v2); q[V2[2] + 0x20] ^= 0x01       # perturb vs2 Phobos .2 row
try:
    check(vj, bytes(q), label="[ctl-b] ")
    die("control B did not fire: a perturbed vs2 tenant row passed")
except SystemExit as e:
    if "control B" in str(e): raise
print("  ok: control B fired (perturbed vs2 tenant row is caught)")
PY

echo "PASS: kernel voice tables — vsavj alias shape + vs2 newcomer rows +"
echo "      nibble law + Z80 silence premise frozen; 2 verdict controls fired"
