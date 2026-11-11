#!/usr/bin/env python3
"""desktop_pause_check.py — does a window capture carry FBNeo's SDL2 PAUSE overlay? (#352, 14z-225)

FBNeo's SDL2 frontend, on SDL_WINDOWEVENT_FOCUS_LOST or _MINIMIZED, calls pause_game()
(emu/fbneo/src/burner/sdl/run.cpp), which stops the sound and draws inprint_shadowed(renderer, "PAUSE", 10, 10): the
text in black at (12,12), then in the font's current colour at (10,10), in renderer pixels, from the 8x8 bitmap font
inline_font_bits of emu/fbneo/src/burner/sdl/sdl2_inprint.cpp (128x64, 16 glyphs a row, glyph = ASCII code, bit 0 =
the opaque ink). FBNeo stays paused until SDL_WINDOWEVENT_FOCUS_GAINED (or Tab/P), so a run whose window lost focus
plays on behind its step schedule: the M24 release run (14z-217) read as "the select screen does not carry the mark"
and "silent". The template here is RENDERED FROM THAT SOURCE, never cut from a capture.

  desktop_pause_check.py judge <capture.png> [--font F]
      (no PIL, a missing or unreadable font file, or a capture that will not open: `PAUSE unread: <why>`, exit 2)
      For each scale s in 1..4 (window pixels per renderer pixel) the capture is sampled at the centre of every
      template pixel. INK (the text's pixels) must be bright (mean channel >= 140) and one colour (each channel within
      48 of the ink median); SHADOW (pixels of the black copy that are not ink) must be dark (max channel <= 60).
      PAUSED when, at some scale, at least 95 % of INK and 95 % of SHADOW samples hold. Prints ONE line:
        PAUSE yes scale=<s> ink=<hit>/<n> shadow=<hit>/<n> colour=<r,g,b>
        PAUSE no best scale=<s> ink=... shadow=... colour=...
        PAUSE unread: <why>                                   (exit 2; exit 0 otherwise)
  desktop_pause_check.py draw <in.png> <out.png> [--font F] [--scale S] [--dx N] [--colour R,G,B] [--no-shadow]
      Draws the overlay as FBNeo does (shadow, then ink) — the in-gate control of audit_release_linux_desktop and the
      ground truth of tests/test_desktop_pause_check.sh. --scale defaults to round(width / 384) (CPS-2 is 384 wide);
      --dx moves it right by N renderer pixels; --no-shadow draws the ink alone.

Ground truth (measured 14z-225 on PILOT, build/agent225/t352/, local): of 81 captures — the M24 failure's 34, an
unpaused M26 run's 22, and 25 from runs minimised 3 s after launch — it read PAUSED on exactly the 10 that show the
overlay, and no on the 71 others, yellow game art at the same place among them (ink 140/140, shadow 0/107).
THE LIMIT: it sees the overlay only in a capture; a pause that began and ended between two captures is not seen.
"""
import argparse, os, re, sys
# PIL is imported where it is used, so a host without it gets `PAUSE unread`, never a traceback (#352, run 2026-11-11-1774)

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
FONT = os.path.join(REPO, "emu/fbneo/src/burner/sdl/sdl2_inprint.cpp")
INK_MIN, INK_SPREAD, SHADOW_MAX, SHARE = 140, 48, 60, 0.95


def font_bits(path):
    src = open(path).read()
    body = src[src.index("inline_font_bits[]"):]
    body = body[body.index("{") + 1:body.index("}")]
    bits = [int(x, 16) for x in re.findall(r"0x[0-9a-fA-F]{2}", body)]
    if len(bits) != 128 * 64 // 8:
        raise ValueError("%s: inline_font_bits holds %d bytes, not 1024" % (path, len(bits)))
    return bits


def glyph_ink(bits, ch):
    row, col = ord(ch) // 16, ord(ch) % 16
    ink = set()
    for y in range(8):
        for x in range(8):
            px = (row * 8 + y) * 128 + col * 8 + x
            if not (bits[px // 8] >> (px % 8)) & 1:
                ink.add((x, y))
    return ink


def template(bits, text="PAUSE", x0=10, y0=10):
    ink = set()
    for i, ch in enumerate(text):
        ink |= {(x0 + i * 8 + x, y0 + y) for (x, y) in glyph_ink(bits, ch)}
    return ink, {(x + 2, y + 2) for (x, y) in ink} - ink


def judge(im, ink, shadow):
    best = None
    w, h = im.size
    for s in (1, 2, 3, 4):
        pts = [(int((x + 0.5) * s), int((y + 0.5) * s)) for (x, y) in ink | shadow]
        if any(cx >= w or cy >= h for cx, cy in pts):
            continue
        iv = [im.getpixel((int((x + 0.5) * s), int((y + 0.5) * s))) for (x, y) in ink]
        sv = [im.getpixel((int((x + 0.5) * s), int((y + 0.5) * s))) for (x, y) in shadow]
        med = tuple(sorted(c[k] for c in iv)[len(iv) // 2] for k in range(3))
        ih = sum(1 for c in iv if sum(c) / 3 >= INK_MIN and all(abs(c[k] - med[k]) <= INK_SPREAD for k in range(3)))
        sh = sum(1 for c in sv if max(c) <= SHADOW_MAX)
        cand = (ih / len(iv) + sh / len(sv), s, ih, len(iv), sh, len(sv), med)
        if best is None or cand > best:
            best = cand
    return best


def cmd_judge(a):
    # anything that stops a reading — no PIL, no font file or an unreadable one, a capture that will not open — is
    # reported as `PAUSE unread`, exit 2: never a verdict and never a traceback (#352, rule-checker run 2026-11-11-1774)
    try:
        from PIL import Image
        im = Image.open(a.png).convert("RGB")
        ink, shadow = template(font_bits(a.font))
    except Exception as e:  # noqa: BLE001 — any unreadable input is reported, never a verdict
        print("PAUSE unread: %s: %s" % (type(e).__name__, e)); return 2
    b = judge(im, ink, shadow)
    if b is None:
        print("PAUSE unread: the capture is smaller than the overlay at every scale"); return 2
    _score, s, ih, ni, sh, ns, med = b
    yes = ih >= SHARE * ni and sh >= SHARE * ns
    print("PAUSE %s scale=%d ink=%d/%d shadow=%d/%d colour=%d,%d,%d"
          % ("yes" if yes else "no best", s, ih, ni, sh, ns, *med))
    return 0


def cmd_draw(a):
    from PIL import Image, ImageDraw
    im = Image.open(a.inp).convert("RGB")
    s = a.scale or max(1, min(4, round(im.size[0] / 384)))
    ink, shadow = template(font_bits(a.font), x0=10 + a.dx)
    d = ImageDraw.Draw(im)
    col = tuple(int(v) for v in a.colour.split(","))
    layers = ([] if a.no_shadow else [({(x + 2, y + 2) for (x, y) in ink}, (0, 0, 0))]) + [(ink, col)]
    for pts, c in layers:
        for (x, y) in pts:
            d.rectangle([x * s, y * s, x * s + s - 1, y * s + s - 1], fill=c)
    im.save(a.out)
    print("drew PAUSE at scale %d%s%s into %s" % (s, " (no shadow)" if a.no_shadow else "", " dx=%d" % a.dx if a.dx else "", a.out))
    return 0


def main():
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    sub = ap.add_subparsers(dest="cmd", required=True)
    j = sub.add_parser("judge"); j.add_argument("png"); j.add_argument("--font", default=FONT)
    d = sub.add_parser("draw"); d.add_argument("inp"); d.add_argument("out"); d.add_argument("--font", default=FONT)
    d.add_argument("--scale", type=int, default=0); d.add_argument("--dx", type=int, default=0)
    d.add_argument("--colour", default="255,240,0"); d.add_argument("--no-shadow", action="store_true")
    a = ap.parse_args()
    return cmd_judge(a) if a.cmd == "judge" else cmd_draw(a)


if __name__ == "__main__":
    sys.exit(main())
