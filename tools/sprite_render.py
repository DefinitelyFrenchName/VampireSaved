#!/usr/bin/env python3
"""sprite_render.py — draw a character's SPRITE at a captured frame from the
game's own OBJ list, its own palette page and the build's tiles (14z-121 (6)).

  python3 tools/sprite_render.py <capture.txt> <zip:prefix> <out_dir> [--frames f1,f2] [--groups abc] [--tile-set tiles.txt --bank N | --min-addr 0x40000] [--names f=name,...]

<capture.txt> is tests/lua/sprite_capture.lua's output: per dumped frame the
OBJ entries ("F<frame> B<buf> E<n> x= y= code= attr= ... a19=") and the
palette page ("P<frame> <hex>"). For each frame the entries whose composed
19-bit tile address is >= --min-addr are the TENANT's (group C, banks 4-5:
the ported art — the host characters draw from groups A/B, so the filter
needs no owner byte); they are composited on a transparent canvas, cropped
and written as <out_dir>/f<frame>.png. Pen 15 is transparent (gfx_tiles);
attr bit 5 = x flip, bit 6 = y flip, bits 8-11/12-15 = block width/height
minus one (the block walks tiles with the 16-tile row stride, gfx_tiles.cell_at);
a CPS-2 colour word is bright.4 R.4 G.4 B.4 (the bright nibble is applied
as a linear scale, 0xF = full). Positions are the OBJ x/y low 10 bits.

Prints the SHA-1 of every simm it reads. Pure python (zlib PNG).
"""
import struct
import sys
import zlib
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import gfx_tiles  # noqa: E402


def load_groups(spec, groups):
    """spec = path.zip:prefix; groups = a subset of "abc" -> {group letter: 4 simms} (same interleave in every group)."""
    import hashlib, zipfile
    path, prefix = spec.rsplit(":", 1)
    z = zipfile.ZipFile(path)
    out = {}
    for g in groups:
        simms = []
        for n in {"a": gfx_tiles.GROUP_A, "b": gfx_tiles.GROUP_B, "c": gfx_tiles.GROUP_C}[g]:
            d = z.read(f"{prefix}.{n}m")
            print(f"  read {prefix}.{n}m sha1 {hashlib.sha1(d).hexdigest()}", file=sys.stderr)
            simms.append(d)
        out[g] = simms
    return out


def png(width, height, rgba_rows):
    raw = b"".join(b"\x00" + bytes(r) for r in rgba_rows)
    def chunk(t, d):
        c = t + d
        return struct.pack(">I", len(d)) + c + struct.pack(">I", zlib.crc32(c) & 0xffffffff)
    return b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", struct.pack(">IIBBBBB", width, height, 8, 6, 0, 0, 0)) + chunk(b"IDAT", zlib.compress(raw, 9)) + chunk(b"IEND", b"")


def colour(word):
    br = (word >> 12) & 0xF; r = (word >> 8) & 0xF; g = (word >> 4) & 0xF; b = word & 0xF
    s = (br + 1) / 16.0
    return (int(r * 17 * s), int(g * 17 * s), int(b * 17 * s), 255)


def render(capture, spec, out_dir, frames=None, min_addr=0x40000, tile_set=None, groups="c", names=None, bank=None):
    """tile_set: if given, an entry is the character's when its a19 is in the set (the tenant's own records'
    tiles, obj_records.walk on the extract — the filter for a NATIVE vs2 capture); else a19 >= min_addr
    (group C on our build). names: {frame: basename} for the output files."""
    simms = load_groups(spec, groups)
    tile_cache = {}
    def tile_px(a19):
        g = "abc"[a19 // gfx_tiles.TILES_PER_GROUP]
        t2 = a19 % gfx_tiles.TILES_PER_GROUP
        if a19 not in tile_cache:
            tile_cache[a19] = gfx_tiles.decode(gfx_tiles.tile_bytes(simms[g], t2))
        return tile_cache[a19]
    ents, pals, cams = {}, {}, {}
    for l in Path(capture).read_text().splitlines():
        if l.startswith("C"):
            fr, rest = l[1:].split(" ", 1); cams[int(fr)] = {k: (int(v) - 0x10000 if k != "p1face" and int(v) >= 0x8000 else int(v)) for k, v in (kv.split("=") for kv in rest.split())}
        elif l.startswith("P"):
            fr, hx = l[1:].split(" ", 1); pals[int(fr)] = bytes.fromhex(hx)
        elif l.startswith("F") and " E" in l:
            f = dict(kv.split("=") for kv in l.split()[3:])
            fr = int(l.split()[0][1:])
            ents.setdefault(fr, []).append({k: int(v, 16) for k, v in f.items() if k != "sz"})
    out_dir = Path(out_dir); out_dir.mkdir(parents=True, exist_ok=True)
    written = []
    for fr in sorted(ents):
        if frames and fr not in frames: continue
        pal = pals.get(fr)
        # the records' tile set is WITHIN-BANK codes (obj_records.walk: bank comes from the object's +0x18 word at emit
        # time), and on native vs2 several characters share a bank's code space — so: (1) keep the set's entries in the
        # MAJORITY bank among them (the HUD and effects sit elsewhere), (2) split what is left into x-clusters at the
        # largest gap and keep the LEFT one: the naming rigs pin P1 (the tenant) left of P2 and facing right
        # (test_move_naming flags a left-facing event), so the other fighter is always the right cluster.
        if tile_set is not None:
            cand = [e for e in ents[fr] if (e["a19"] & 0xFFFF) in tile_set]
            if cand:
                if bank is None:   # the OBJ bank table (vs2 0x27530, id-indexed: the three tenants -> 0x6000 = bank 3, measured on the captures) is the honest source; the majority is a fallback
                    from collections import Counter
                    bank = Counter(e["a19"] >> 16 for e in cand).most_common(1)[0][0]
                cand = [e for e in cand if (e["a19"] >> 16) == bank and 40 <= (e["y"] & 0x3FF) < 200]   # the y window drops the two HUD strips
                xs = sorted(((e["x"] & 0x3FF), i) for i, e in enumerate(cand))
                gaps = [(xs[k + 1][0] - xs[k][0], k) for k in range(len(xs) - 1)]
                if gaps and max(gaps)[0] > 48:
                    cut = max(gaps)[1]
                    keep = {i for _, i in xs[:cut + 1]}
                    cand = [e for i, e in enumerate(cand) if i in keep]
            mine = cand
        else:
            mine = [e for e in ents[fr] if e["a19"] >= min_addr]
        if not mine or not pal: continue
        pieces = []
        for e in mine:
            bx = ((e["attr"] >> 8) & 15) + 1; by = ((e["attr"] >> 12) & 15) + 1
            xf = bool(e["attr"] & 0x20); yf = bool(e["attr"] & 0x40)
            row = e["attr"] & 0x1F
            cols = [colour(int.from_bytes(pal[row * 32 + 2 * i:row * 32 + 2 * i + 2], "big")) for i in range(16)]
            x0 = e["x"] & 0x3FF; y0 = e["y"] & 0x3FF
            for dy in range(by):
                for dx in range(bx):
                    code = gfx_tiles.cell_at(e["a19"], dx, dy) if hasattr(gfx_tiles, "cell_at") else (e["a19"] & ~0xF) + (dy << 4) + ((e["a19"] + dx) & 0xF)
                    px = tile_px(code)
                    cx = x0 + (bx - 1 - dx if xf else dx) * 16
                    cy = y0 + (by - 1 - dy if yf else dy) * 16
                    pieces.append((cx, cy, px, xf, yf, cols))
        xs = [p[0] for p in pieces]; ys = [p[1] for p in pieces]
        X0, Y0 = min(xs), min(ys); W = max(xs) - X0 + 16; H = max(ys) - Y0 + 16
        canvas = [[(0, 0, 0, 0)] * W for _ in range(H)]
        # OBJ priority: later entries draw over earlier ones? On CPS-2 the FIRST entry has the highest priority;
        # draw in reverse so entry 0 lands on top.
        for cx, cy, px, xf, yf, cols in reversed(pieces):
            for r in range(16):
                for c in range(16):
                    pen = px[(15 - r if yf else r) * 16 + (15 - c if xf else c)]
                    if pen == 15: continue
                    canvas[cy - Y0 + r][cx - X0 + c] = cols[pen]
        rows = [bytes(v for pxl in row for v in pxl) for row in canvas]
        p = out_dir / (f"{names[fr]}.png" if names and fr in names else f"f{fr}.png"); p.write_bytes(png(W, H, rows)); written.append((fr, W, H, len(mine)))
        import json
        p.with_suffix(".json").write_text(json.dumps({"frame": fr, "x0": X0, "y0": Y0, "w": W, "h": H, "entries": len(mine), **cams.get(fr, {})}))
    return written


def main():
    a = sys.argv[1:]
    frames = None; min_addr = 0x40000
    if "--frames" in a:
        k = a.index("--frames"); frames = {int(x) for x in a[k + 1].split(",")}; del a[k:k + 2]
    if "--min-addr" in a:
        k = a.index("--min-addr"); min_addr = int(a[k + 1], 0); del a[k:k + 2]
    tile_set = None; groups = "c"; names = None; bank = None
    if "--bank" in a:
        k = a.index("--bank"); bank = int(a[k + 1], 0); del a[k:k + 2]
    if "--tile-set" in a:
        k = a.index("--tile-set"); tile_set = {int(x, 16) for x in Path(a[k + 1]).read_text().split()}; del a[k:k + 2]
    if "--groups" in a:
        k = a.index("--groups"); groups = a[k + 1]; del a[k:k + 2]
    if "--names" in a:   # "frame=name,frame=name"
        k = a.index("--names"); names = {int(x.split("=")[0]): x.split("=")[1] for x in a[k + 1].split(",") if x}; del a[k:k + 2]
    w = render(a[0], a[1], a[2], frames, min_addr, tile_set, groups, names, bank)
    for fr, W, H, n in w:
        print(f"f{fr}.png {W}x{H} from {n} entries")


if __name__ == "__main__":
    main()
