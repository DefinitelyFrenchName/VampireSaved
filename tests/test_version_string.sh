#!/bin/sh
# test_version_string.sh — THE IN-GAME VERSION STRING (W2, 14z-105; CLAUDE.md
# §5 "shipped builds carry a visible in-game version string as the naked-eye
# A/B tell", open since 14z-92, maintainer-approved 14z-104).
#
# Where and how: the SELECT SCREEN, the one roster-owned always-visited
# surface (attract/title would violate the superset invariant; select
# already diverges under the ratified §4 v3 window). The [[select_wheel]]
# machinery copies the wheel OBJ record into profile-gated space and
# repoints its single referrer; `version_text` appends one 1x1 glyph sprite
# per character to that same record, with AUTHORED tiles (provenance NEW,
# build/manifest/version_font.json, 5x7 scaled 2x) placed in group C's
# upper bank by build_gfx --wheel-bank5 (the "authored" list) and drawn
# under palette row 0x19 — Phobos' medallion row, re-asserted every select
# frame by the 14z-63 thunk, so its content is stable by construction.
#
# Sections:
#   1  STATIC — the built record's LAST N entries are the glyph codes at
#      the declared palette row, and the coord list's last N pairs put them
#      at screen (version_x + 16*i, version_y) under the measured
#      OBJ->screen transform (x-64, y-16); every glyph tile in the packed
#      group C is byte-identical to the generator's and non-blank; pen 15
#      (transparent) fills every non-ink pixel.
#   2  RUNTIME — on a select frame the LIVE OBJ list carries exactly N
#      entries with those codes, bank 5, that palette, at those OBJ
#      coordinates (tests/lua/obj_records_dump.lua); and a MAME snapshot
#      pixel-matches the intended bitmap at the declared screen position
#      with ZERO mismatches (ink = the row's pen-`ink` colour), with no
#      opaque pen-0 pixel in the box. The snapshot check is what caught the
#      tile codec's half-mirror (docs/platform/gotchas.md, 14z-105).
#   3  VERDICT CONTROLS — a shifted expectation (x+1) must NOT pixel-match;
#      a corrupted glyph tile must be refused by section 1.
#
# Usage: ROMDIR=... tests/test_version_string.sh [outbase]
#   default build/m3b_merged22. Reads the knobs from the manifest the build
#   names (donovan.toml — identical in all three tenant manifests, asserted).
#
# HANDOFF's gate-index note, moved into this header 14z-123 (verbatim; the
# documentation pass ruled a gate's WHY lives in the gate):
#   14z-105 (W2, ~2 min, 2 MAME runs): the select-screen VERSION STRING — the
#   wheel record's last N entries are the glyph codes at the declared pal row
#   and screen position; authored tiles packed byte-identical, non-blank,
#   pen-15 background, font-exact; the LIVE OBJ list carries exactly N glyph
#   sprites at OBJ (x+64, y+16); a MAME snapshot pixel-matches the intended
#   bitmap with ZERO mismatches (this is what caught the codec half-mirror).
#   Controls: 1px shift, corrupted tile. Knobs read from the manifests and
#   asserted identical across them.
set -eu
ROMDIR="${ROMDIR:?set ROMDIR}"
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
OUT="${1:-build/m3b_merged22}"  # re-pointed 14z-117b (random-select freeze) <- 14z-117  # re-pointed 14z-119 (physics-port freeze) <- 14z-117b
MAME_BIN="${MAME_BIN:-$HOME/.cache/vampire-saved/mame/cps2}"
export MAME_BIN
[ -d "$OUT/rompath" ] || { echo "SKIP: $OUT/rompath missing"; exit 77; }
[ -f "$OUT/patch/wheel_bank5.json" ] || { echo "SKIP: $OUT is not a bank5 build"; exit 77; }
WORK="$(mktemp -d)"; trap 'rm -rf "$WORK"' EXIT
fail=0

# the knobs, read from the manifests (and asserted identical across them —
# the wheel row is ENGINE-SITE, emitted once from the deduped row)
python3 - "$WORK/knobs.json" <<'PY'
import json, sys
sys.path.insert(0, "tools")
from _minitoml import loads
rows = []
for m in ("donovan", "huitzil", "pyron"):
    d = loads(open(f"build/manifest/{m}.toml").read())
    sw = [r for r in d["select_wheel"] if r["name"] == "roster21"][0]
    rows.append({k: sw[k] for k in ("version_text", "version_font", "version_x",
                                     "version_y", "version_pal", "version_base")})
assert all(r == rows[0] for r in rows), f"version knobs differ across manifests: {rows}"
json.dump(rows[0], open(sys.argv[1], "w"))
print("  knobs:", rows[0])
PY

echo "== 1. static: record entries, coords, packed group C tiles =="
python3 - "$OUT" "$WORK/knobs.json" "$ROMDIR" "$WORK/want.json" <<'PY' || fail=1
import json, sys, zipfile, hashlib, struct
sys.path.insert(0, "tools")
from gfx_tiles import GROUP_C, tile_bytes, decode, encode, BLANK
out, knobs, romdir, want_path = sys.argv[1:5]
k = json.load(open(knobs))
text = k["version_text"]; n = len(text)
font = json.load(open(k["version_font"])); ink = int(font["ink"])
base = int(str(k["version_base"]), 0); pal = int(str(k["version_pal"]), 0)
sx, sy = int(k["version_x"]), int(k["version_y"])
ops = json.load(open(f"{out}/patch/patch.json"))["ops"]
rp = [o for o in ops if o["op"] == "poke32" and int(o["addr"], 16) == 0x2689FE]
assert len(rp) == 1, "wheel repoint op"
rec = int(str(rp[0]["val"]), 16)
body = bytes.fromhex([o for o in ops if o["op"] == "data" and int(o["addr"], 16) == rec][0]["hex"])
count = struct.unpack(">H", body[4:6])[0] + 1
cptr = int.from_bytes(body[6:10], "big")
cl = bytes.fromhex([o for o in ops if o["op"] == "data" and int(o["addr"], 16) == cptr][0]["hex"])
assert len(body) == 10 + 4 * count, f"record body {len(body)} vs count {count}"
assert len(cl) == 4 * count, f"coord list {len(cl)} vs count {count}"
# the last n entries are the glyphs
bad = []
for i in range(n):
    t, a = struct.unpack(">HH", body[10 + 4 * (count - n + i):14 + 4 * (count - n + i)])
    x, y = struct.unpack(">hh", cl[4 * (count - n + i):4 * (count - n + i) + 4])
    want_t = (base + i) & 0xFFFF
    # coords are relative to the drawer base (256,176); OBJ -> screen = (-64, -16)
    ox, oy = x + 256, y + 176
    if t != want_t or (a & 0x1F) != pal or (a >> 8) != 0:
        bad.append(f"entry {i}: tile {t:#06x} attr {a:#06x} (want {want_t:#06x} / pal {pal:#04x}, 1x1)")
    if (ox - 64, oy - 16) != (sx + 16 * i, sy):
        bad.append(f"entry {i}: screen ({ox-64},{oy-16}) != ({sx+16*i},{sy})")
if bad:
    print("FAIL: record/coords:", *bad, sep="\n  "); sys.exit(1)
print(f"  ok: record has {count} entries, the last {n} = {text!r} glyphs at pal {pal:#04x}, screen ({sx},{sy})+16i")
# tiles: generator json == packed group C, non-blank, pen 15 outside ink
wb5 = json.load(open(f"{out}/patch/wheel_bank5.json"))
auth = wb5.get("authored", {})
assert len(auth) == n, f"authored tiles {len(auth)} != {n}"
zw = zipfile.ZipFile(f"{out}/rompath/vsavjw.zip")
gc = [zw.read(f"vsw.{m}m") for m in GROUP_C]
want = []
for i in range(n):
    key = f"{base + i:#x}"
    tile = bytes.fromhex(auth[key])
    got = tile_bytes(gc, base + i)
    if got != tile:
        print(f"FAIL: glyph {key} packed bytes differ from the generator's"); sys.exit(1)
    if hashlib.sha1(tile).digest() in BLANK:
        print(f"FAIL: glyph {key} is blank"); sys.exit(1)
    px = decode(tile)
    if any(v not in (15, ink) for v in px):
        print(f"FAIL: glyph {key} uses pens other than 15/ink"); sys.exit(1)
    # the glyph is the font's bitmap, 2x, at (3,1)
    g = font["glyphs"][text[i]]
    exp = bytearray([15] * 256)
    for r, row in enumerate(g):
        for cx, v in enumerate(row):
            if v == "#":
                for dy in (0, 1):
                    for dx in (0, 1):
                        exp[(1 + 2 * r + dy) * 16 + 3 + 2 * cx + dx] = ink
    if bytes(px) != bytes(exp):
        print(f"FAIL: glyph {key} does not decode to the font bitmap of {text[i]!r}"); sys.exit(1)
    want.append([[px[r * 16 + c] == ink for c in range(16)] for r in range(16)])
json.dump({"n": n, "sx": sx, "sy": sy, "pal": pal, "base": base, "ink": ink,
           "want": want}, open(want_path, "w"))
print(f"  ok: {n} authored glyph tiles packed byte-identical, non-blank, pen-15 background, font-exact")
PY

echo "== 2. runtime: the live OBJ list and a pixel-exact snapshot =="
cat > "$WORK/sel.rpl" <<'EOF'
300-305 sys=C1
800-803 sys=S1
1300 wait
EOF
REPLAY="$WORK/sel.rpl" DUMP_FRAMES=1150,1151 TRACE_OUT="$WORK/obj.txt" \
    MAME_SANDBOX="$WORK/objbox" MAME_ROMPATH="$PWD/$OUT/rompath;$ROMDIR" \
    tools/run_mame.sh vsavjw -autoboot_script tests/lua/obj_records_dump.lua \
    > "$WORK/obj_mame.log" 2>&1 || { echo "FAIL: OBJ dump run"; tail -3 "$WORK/obj_mame.log"; fail=1; }
python3 - "$WORK/obj.txt" "$WORK/want.json" <<'PY' || fail=1
import json, re, sys
w = json.load(open(sys.argv[2])); n, base, pal = w["n"], w["base"], w["pal"]
ents = {}
for line in open(sys.argv[1]):
    m = re.match(r"F(\d+) B\d E\d+ x=([0-9a-f]+) y=([0-9a-f]+) code=([0-9a-f]+) attr=([0-9a-f]+) pal=([0-9a-f]+) sz=(\S+)", line)
    if not m: continue
    fr, x, y, code, attr, p, sz = m.groups()
    code = int(code, 16)
    if base <= 0x10000 + code < base + n:
        ents.setdefault(int(fr), []).append((0x10000 + code, int(x, 16) & 0x1FF, int(y, 16) & 0x1FF,
                                             int(y, 16) & 0x3000, int(p, 16), sz))
ok = True
for fr, es in sorted(ents.items()):
    es.sort()
    exp = [(base + i, w["sx"] + 64 + 16 * i, w["sy"] + 16, 0x3000, pal, "1x1") for i in range(n)]
    if es != exp:
        print(f"FAIL: frame {fr} OBJ entries {es} != {exp}"); ok = False
    else:
        print(f"  ok: frame {fr}: {n} glyph sprites at OBJ x={w['sx']+64}+16i y={w['sy']+16}, bank 5, pal {pal:#04x}")
if not ents or not ok:
    print("FAIL: no glyph sprite in the live OBJ list" if not ents else "FAIL: OBJ list"); sys.exit(1)
PY
REPLAY="$WORK/sel.rpl" SNAP_FRAMES=1150 TRACE_OUT="$WORK/snap.txt" \
    MAME_SANDBOX="$WORK/snapbox" MAME_ROMPATH="$PWD/$OUT/rompath;$ROMDIR" \
    tools/run_mame.sh vsavjw -autoboot_script tests/lua/snapshot_frames.lua \
    > "$WORK/snap_mame.log" 2>&1 || { echo "FAIL: snapshot run"; tail -3 "$WORK/snap_mame.log"; fail=1; }
PNG="$(find "$WORK/snapbox" -name '0000.png' | head -1)"
[ -n "$PNG" ] || { echo "FAIL: no snapshot"; fail=1; }
pixcheck() { # pixcheck <png> <dx> -> prints mismatches
    python3 - "$1" "$WORK/want.json" "$2" <<'PY'
import json, sys
from PIL import Image
im = Image.open(sys.argv[1]).convert("RGB"); w = json.load(open(sys.argv[2])); dx = int(sys.argv[3])
n, sx, sy = w["n"], w["sx"] + dx, w["sy"]
# ink colour = the most common colour where ink is expected (the row's pen)
from collections import Counter
cnt = Counter(im.getpixel((sx + 16 * i + c, sy + r)) for i in range(n) for r in range(16) for c in range(16) if w["want"][i][r][c])
ink = cnt.most_common(1)[0][0] if cnt else None
mism = sum((im.getpixel((sx + 16 * i + c, sy + r)) == ink) != w["want"][i][r][c]
           for i in range(n) for r in range(16) for c in range(16))
dark = sum(im.getpixel((sx + 16 * i + c, sy + r)) == (17, 17, 17) for i in range(n) for r in range(16) for c in range(16))
print(mism, dark, ink)
PY
}
set -- $(pixcheck "$PNG" 0)
if [ "$1" = 0 ] && [ "$2" = 0 ]; then
    echo "  ok: snapshot pixel-exact (0 mismatches, 0 opaque pen-0 pixels; ink $3)"
else
    echo "FAIL: snapshot: $1 mismatches, $2 opaque pen-0 pixels"; fail=1
fi

echo "== 3. verdict controls =="
set -- $(pixcheck "$PNG" 1)
[ "$1" != 0 ] && echo "  ok: a 1px-shifted expectation does not match ($1 mismatches)" \
    || { echo "FAIL: the pixel check cannot fail"; fail=1; }
mkdir -p "$WORK/neg/patch" "$WORK/neg/rompath"
cp "$OUT/patch/patch.json" "$WORK/neg/patch/"
ln -s "$PWD/$OUT/rompath/vsavjw.zip" "$WORK/neg/rompath/vsavjw.zip"
python3 - "$OUT/patch/wheel_bank5.json" "$WORK/neg/patch/wheel_bank5.json" <<'PY'
import json, sys
w = json.load(open(sys.argv[1])); k = sorted(w["authored"])[0]
h = bytearray.fromhex(w["authored"][k]); h[5] ^= 0x55; w["authored"][k] = h.hex()
json.dump(w, open(sys.argv[2], "w"))
PY
if python3 - "$WORK/neg" "$WORK/knobs.json" "$ROMDIR" "$WORK/want_neg.json" <<'PY' > "$WORK/neg.out" 2>&1
import json, sys, zipfile
sys.path.insert(0, "tools")
from gfx_tiles import GROUP_C, tile_bytes
out = sys.argv[1]; k = json.load(open(sys.argv[2])); base = int(str(k["version_base"]), 0)
auth = json.load(open(f"{out}/patch/wheel_bank5.json"))["authored"]
zw = zipfile.ZipFile(f"{out}/rompath/vsavjw.zip"); gc = [zw.read(f"vsw.{m}m") for m in GROUP_C]
for i in range(len(auth)):
    if tile_bytes(gc, base + i) != bytes.fromhex(auth[f"{base + i:#x}"]):
        print("differs"); sys.exit(1)
print("same")
PY
then echo "FAIL: a corrupted glyph tile was accepted"; fail=1
else echo "  ok: a corrupted glyph tile is refused ($(cat "$WORK/neg.out"))"; fi

if [ "$fail" = 0 ]; then
    echo "PASS: version string — record + coords + authored tiles static-exact,"
    echo "      live OBJ entries at the declared position, snapshot pixel-exact"
else
    echo "FAIL: version string"; exit 1
fi
