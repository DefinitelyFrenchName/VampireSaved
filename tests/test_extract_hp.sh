#!/bin/sh
# test_extract_hp.sh — the Huitzil/Pyron extraction gate (14z-65, M3b Phase 1).
#
# Freezes the measured extraction shapes for the two next tenants:
#   0x10 Huitzil: code [0x057020,+0x436) shift +0x36 with the 6-byte
#     SIBLING-INSERTION sliver at +0x430 (vs2-only `jsr $8ACD8` at his
#     handler head — absent in vhunt2, the +0x36 -> +0x30 boundary), plus
#     the +0x30 group as region x057456 with one 12-byte dead filler zone.
#   0x11 Pyron: single code region [0x0574C0,+0x5200) shift +0x30 with one
#     12-byte dead filler zone at +0x234 (junk after two jmps at
#     PRG:0x0576F4; code resumes byte-identical).
# Plus negative controls: a char with no anchor row is REFUSED (0x12 — also
# guards the reserved id), and the charid scanner finds the tenant's OWN id
# (the literal-0x13 bug class).
#
# Usage: ROMDIR=... tests/test_extract_hp.sh
set -eu

ROMDIR="${ROMDIR:?set ROMDIR}"
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

echo "== 0x10 Huitzil extraction"
python3 tools/extract_char.py "$ROMDIR/vsav2.zip" "$WORK/h" \
    --char 0x10 --oracle "$ROMDIR/vhunt2.zip" > "$WORK/h.log" 2>&1 \
    || { tail -10 "$WORK/h.log"; echo "FAIL: 0x10 extraction errored"; exit 1; }
python3 - "$WORK/h/regions.json" <<'PY'
import json, sys
m = json.load(open(sys.argv[1]))
r = m["regions"]
c = r["code"]
assert (c["src"], c["len"]) == (0x57020, 0x436), f"code region moved: {c}"
assert c["ins"] == [[0x430, 0x436]], f"insertion sliver moved: {c['ins']}"
assert m["shifts"]["code"] == 0x36, m["shifts"]
s = r["x057456"]
assert (s["src"], s["len"]) == (0x57456, 0x5200), f"x057456 moved: {s}"
assert m["shifts"]["x057456"] == 0x30, m["shifts"]
assert len(s["dead"]) == 1 and s["dead"][0][1] - s["dead"][0][0] == 0xC, s["dead"]
assert len(s["charid_sites"]) == 1, s["charid_sites"]
print("  ok: Huitzil shapes frozen (insertion sliver, +0x30 group, charid site)")
PY

echo "== 0x11 Pyron extraction"
python3 tools/extract_char.py "$ROMDIR/vsav2.zip" "$WORK/p" \
    --char 0x11 --oracle "$ROMDIR/vhunt2.zip" > "$WORK/p.log" 2>&1 \
    || { tail -10 "$WORK/p.log"; echo "FAIL: 0x11 extraction errored"; exit 1; }
python3 - "$WORK/p/regions.json" <<'PY'
import json, sys
m = json.load(open(sys.argv[1]))
c = m["regions"]["code"]
assert (c["src"], c["len"]) == (0x574C0, 0x5200), f"code region moved: {c}"
assert m["shifts"]["code"] == 0x30, m["shifts"]
assert c["dead"] == [[0x234, 0x240]], f"dead filler moved: {c['dead']}"
codes = [n for n, r in m["regions"].items() if r.get("kind") == "code"]
assert codes == ["code"], f"unexpected extra code regions: {codes}"
print("  ok: Pyron shapes frozen (single +0x30 region, filler at +0x234)")
PY

echo "== negative control: unanchored char refused"
if python3 tools/extract_char.py "$ROMDIR/vsav2.zip" "$WORK/x" \
    --char 0x12 --oracle "$ROMDIR/vhunt2.zip" > "$WORK/x.log" 2>&1; then
    echo "FAIL: char 0x12 (no anchor row, reserved id) was accepted"; exit 1
fi
grep -q "no anchor row" "$WORK/x.log" \
    || { echo "FAIL: refusal reason wrong:"; tail -5 "$WORK/x.log"; exit 1; }
echo "  ok: char without an anchor row is refused by name"

echo "PASS: H/P extraction shapes frozen + anchor negative control"
