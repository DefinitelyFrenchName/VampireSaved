#!/usr/bin/env python3
"""desktop_mark_check.py <window.png> <text> [--dx N] [--json OUT] — does a WINDOW CAPTURE of the
select screen carry the in-game version mark <text>? (#226, 14z-194)

The mark itself is specified by the build manifests (`select_wheel` row `roster21`: version_font,
version_x/y — the same knobs tests/test_version_string.sh reads, asserted identical across the
three tenant manifests). That gate pixel-matches a NATIVE 384x224 MAME snapshot; a player's window
is SCALED (MAME pillarboxes a 4:3 picture in black and smooths it; FBNeo draws inside GNOME's grey
title bar and border), so this tool:
  1. finds the game rectangle as the bounding box of SATURATED pixels (max-min channel > SAT):
     the select screen's edges are magenta/maroon, the pillarbox is black and the decoration grey;
  2. maps a NATIVE coordinate into it by the rectangle's two scale factors (nearest window pixel);
  3. compares the mark at FONT-PIXEL resolution: each font pixel is a 2x2 native block (the glyph
     layout test_version_string.sh asserts: 5x7 at 2x, offset (3,1) in its 16x16 tile), sampled at
     the block's CENTRE, so a scaler's smoothing at glyph edges never decides a cell. Cells: the
     5x7 glyph plus one font-pixel column each side (7x7 per glyph). Ink colour = the most common
     colour where the font has ink (as test_version_string.sh does); a cell is ink when within TOL
     of it; MISMATCHES = cells whose ink-ness differs from the font. dx shifts the expected
     position by dx NATIVE pixels (half a font pixel per unit).
Prints `MARK <text> dx=<dx> mismatches M of N rect=(x0,y0,x1,y1) ink=(r,g,b)`; exit 0 always (the
caller judges against its frozen threshold). Needs PIL.
"""
import json, sys
from collections import Counter
sys.path.insert(0, __file__.rsplit("/", 1)[0])
from _minitoml import loads
from PIL import Image

SAT, TOL = 24, 60
NATIVE = (384, 224)


def knobs(root="."):
    rows = []
    for m in ("donovan", "huitzil", "pyron"):
        d = loads(open(f"{root}/build/manifest/{m}.toml").read())
        sw = [r for r in d["select_wheel"] if r["name"] == "roster21"][0]
        rows.append({k: sw[k] for k in ("version_font", "version_x", "version_y")})
    assert all(r == rows[0] for r in rows), f"version knobs differ across manifests: {rows}"
    return rows[0]


def game_rect(im):
    w, h = im.size
    px = im.load()
    xs, ys = [], []
    for y in range(h):
        for x in range(w):
            r, g, b = px[x, y][:3]
            if max(r, g, b) - min(r, g, b) > SAT:
                xs.append(x); ys.append(y)
    if not xs:
        return None
    return min(xs), min(ys), max(xs) + 1, max(ys) + 1


def check(png, text, dx=0, root="."):
    k = knobs(root)
    font = json.load(open(f"{root}/{k['version_font']}"))
    im = Image.open(png).convert("RGB")
    rect = game_rect(im)
    if rect is None:
        return {"text": text, "dx": dx, "mismatches": None, "cells": 49 * len(text),
                "rect": None, "ink": None}
    x0, y0, x1, y1 = rect
    kx, ky = (x1 - x0) / NATIVE[0], (y1 - y0) / NATIVE[1]
    src = im.load()
    sx, sy = int(k["version_x"]) + dx, int(k["version_y"])

    def at(nx, ny):  # the window pixel under a continuous NATIVE coordinate
        return src[min(x1 - 1, int(x0 + nx * kx)), min(y1 - 1, int(y0 + ny * ky))][:3]

    samples = []  # (want_ink, rgb)
    for i, ch in enumerate(text):
        g = font["glyphs"][ch]
        for r in range(7):
            for cx in range(-1, 6):
                w = 0 <= cx < 5 and g[r][cx] == "#"
                # the centre of the 2x2 block of font pixel (cx, r) in glyph i's tile
                samples.append((w, at(sx + 16 * i + 3 + 2 * cx + 1.0, sy + 1 + 2 * r + 1.0)))
    ink = Counter(p for w, p in samples if w).most_common(1)[0][0]
    near = lambda p: sum(abs(a - b) for a, b in zip(p, ink)) <= TOL
    mism = sum(near(p) != w for w, p in samples)
    return {"text": text, "dx": dx, "mismatches": mism, "cells": len(samples), "rect": list(rect),
            "ink": list(ink)}


if __name__ == "__main__":
    a = sys.argv[1:]
    dx = 0; jout = None
    if "--dx" in a:
        i = a.index("--dx"); dx = int(a[i + 1]); del a[i:i + 2]
    if "--json" in a:
        i = a.index("--json"); jout = a[i + 1]; del a[i:i + 2]
    r = check(a[0], a[1], dx)
    print("MARK %s dx=%d mismatches %s of %d rect=%s ink=%s" % (r["text"], r["dx"], r["mismatches"],
          r["cells"], r["rect"], r["ink"]))
    if jout:
        json.dump(r, open(jout, "w"))
