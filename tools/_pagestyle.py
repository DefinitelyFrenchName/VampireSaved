#!/usr/bin/env python3
"""_pagestyle.py — the one definition of this project's page theme.

Imported by `tools/mk_mister_page.py` (the drawn MiSTer synthesis page) and
`tools/mk_docs_site.py` (the rendered documentation site). Not a script.

WHY IT EXISTS (14z-140, living-docs slice L4, ruled 2026-09-07). The site
needs the theme the MiSTer page already has, and the alternative was a second
copy — the class 14z-139 closed for verdict classifiers, where one logic
travelling by copy became three that disagreed. **`mk_mister_page.py` cannot
simply be imported**: it does its argument parsing at module scope
(`ARGV = sys.argv[1:]`), so importing it runs it. So the SHARED layer moved
here and both generators import it.

WHAT IS HERE, and what deliberately is not:

  HERE  the colour maths (`mix`, `desat`, `contrast`, `label_ink`), the
        palette it operates on, and `theme_vars()` — the `--paper/--surface/
        --ink/…` custom properties in all three states a page needs (light,
        `@media (prefers-color-scheme: dark)`, and an explicit
        `[data-theme="dark"]`, so a toggle wins in both directions).
  NOT   anything that knows what is being drawn. `mk_mister_page.py` keeps its
        `ROLE` table and the per-role fills and label inks it generates from
        it — those are facts about the MiSTer SDRAM map, not about typography,
        and a doc site has no roles.

THE PALETTE IS NOT ARBITRARY: it is Demitri's own 16-colour sprite palette,
row 0 at `PRG:0x38C7A0`, which `mk_mister_page.py --check` re-reads from the
decrypted image when one is present. Three cool steps off his cape ramp and
three warm ones off his skin/gold ramp, chosen for TELLING APART rather than
for happening to carry white text — `label_ink()` then measures, per theme,
which of two inks a label can actually be read in.

Stdlib only, python 3.9.
"""

# Demitri's sprite palette, row 0, PRG:0x38C7A0.
DEMITRI = ["#443333", "#ffeeaa", "#ffbb99", "#ee9977",
           "#cc8866", "#ffdd00", "#ff0000", "#995511",
           "#550000", "#334455", "#446677", "#668899",
           "#88aabb", "#bbccdd", "#ffffff", "#000000"]


def _rgb(c):
    return int(c[1:3], 16), int(c[3:5], 16), int(c[5:7], 16)


def mix(a, b, t):
    """Blend two hex colours; t=0 is all a, t=1 is all b."""
    ra, ga, ba = _rgb(a)
    rb, gb, bb = _rgb(b)
    return "#%02x%02x%02x" % (round(ra + (rb - ra) * t),
                              round(ga + (gb - ga) * t),
                              round(ba + (bb - ba) * t))


def desat(c, t):
    """Pull a colour toward its own luminance. Used only for 'free space',
    which must read as absence rather than as another category."""
    r, g, b = _rgb(c)
    y = round(0.299 * r + 0.587 * g + 0.114 * b)
    return mix(c, "#%02x%02x%02x" % (y, y, y), t)


COOL_D, COOL_M, COOL_L = DEMITRI[9], DEMITRI[11], DEMITRI[13]   # 334455/668899/bbccdd
WARM_D, WARM_M, WARM_L = DEMITRI[7], DEMITRI[4], DEMITRI[2]     # 995511/cc8866/ffbb99
GOLD, FLAME, CREAM = DEMITRI[5], DEMITRI[6], DEMITRI[1]         # ffdd00/ff0000/ffeeaa


def _lum(c):
    def ch(v):
        v /= 255
        return v / 12.92 if v <= 0.04045 else ((v + 0.055) / 1.055) ** 2.4
    r, g, b = _rgb(c)
    return 0.2126 * ch(r) + 0.7152 * ch(g) + 0.0722 * ch(b)


def contrast(a, b):
    la, lb = sorted((_lum(a), _lum(b)))
    return (lb + 0.05) / (la + 0.05)


# The two inks a label inside a filled region may use. Which one each role gets
# is DECIDED BY MEASUREMENT, not by eye: label_ink() picks whichever of the two
# has the higher WCAG contrast against the fill, per theme, so no label can end
# up as pale text on a pale block. That is what frees the role fills to be
# chosen for TELLING APART — three cool steps and three warm ones off Demitri's
# own ramps — instead of for happening to carry white text.
INK_LIGHT = "#ffffff"
INK_DARK = mix(COOL_D, "#000000", .70)


def label_ink(fill):
    return max((INK_LIGHT, INK_DARK), key=lambda c: contrast(fill, c))


# --- the theme's custom properties, in all three states ----------------------

# THE THEME, AS VALUES. Both generators build their own stylesheet TEXT — the
# MiSTer page interleaves one custom property per region role and the site does
# not — so what is shared is the numbers, not the CSS. `--warn` is the case
# that proves the split is real: FLAME on light, WARM_L on dark, because red on
# a dark ground is unreadable. A page that copied the light block and swapped a
# few values would get that wrong silently.
THEME_LIGHT = {
    "paper": mix(CREAM, "#ffffff", .90),
    "surface": mix(CREAM, "#ffffff", .965),
    "sunken": mix(COOL_L, "#ffffff", .60),
    "ink": mix(COOL_D, "#000000", .55),
    "ink-2": mix(COOL_D, "#000000", .18),
    "ink-3": mix(COOL_D, "#ffffff", .34),
    "rule": mix(COOL_L, "#ffffff", .28),
    "accent": mix(WARM_D, "#000000", .10),
    "accent-soft": mix(WARM_L, "#ffffff", .72),
    "on-fill": "#ffffff",
    "warn": FLAME,
    "shadow": ("0 1px 2px rgba(20,17,17,.06), "
               "0 8px 24px -12px rgba(20,17,17,.20)"),
}
THEME_DARK = {
    "paper": mix(COOL_D, "#000000", .80),
    "surface": mix(COOL_D, "#000000", .66),
    "sunken": mix(COOL_D, "#000000", .74),
    "ink": mix(COOL_L, "#ffffff", .55),
    "ink-2": COOL_L,
    "ink-3": mix(COOL_M, "#ffffff", .10),
    "rule": mix(COOL_D, "#000000", .42),
    "accent": WARM_L,
    "accent-soft": mix(WARM_D, "#000000", .62),
    "on-fill": mix(COOL_D, "#000000", .74),
    "warn": WARM_L,
    "shadow": "0 1px 2px rgba(0,0,0,.5), 0 10px 30px -14px rgba(0,0,0,.7)",
}


def _vars(light):
    """The `--name:value;` run for one theme."""
    v = THEME_LIGHT if light else THEME_DARK
    return " ".join("--%s:%s;" % (k, val) for k, val in v.items())


def theme_vars(extra_light="", extra_dark=""):
    """The three blocks a theme-aware page needs, for a caller that wants the
    plain shape (the documentation site). All three states are emitted from the
    SAME two dicts, so a property cannot be defined in one theme and not the
    other — the failure that leaves a page borrowing its host's theme."""
    return (":root{ %s %s }\n"
            '@media (prefers-color-scheme: dark){ :root:not([data-theme="light"]){ %s %s } }\n'
            ':root[data-theme="dark"]{ %s %s }\n'
            % (_vars(True), extra_light,
               _vars(False), extra_dark,
               _vars(False), extra_dark))


def selftests():
    """Ground truth for the colour maths — the values other code depends on."""
    bad = []
    if mix("#000000", "#ffffff", 0) != "#000000":
        bad.append("mix t=0 is not all a")
    if mix("#000000", "#ffffff", 1) != "#ffffff":
        bad.append("mix t=1 is not all b")
    if mix("#000000", "#ffffff", .5) != "#808080":
        bad.append("mix midpoint moved: %s" % mix("#000000", "#ffffff", .5))
    if round(contrast("#ffffff", "#000000"), 2) != 21.0:
        bad.append("black/white contrast is not 21:1")
    if contrast("#ffffff", "#ffffff") != 1.0:
        bad.append("a colour against itself is not 1:1")
    if label_ink("#000000") != INK_LIGHT:
        bad.append("a label on black is not the light ink")
    if label_ink("#ffffff") != INK_DARK:
        bad.append("a label on white is not the dark ink")
    if desat("#ff0000", 1) != desat("#ff0000", 1)[:1] + desat("#ff0000", 1)[1:]:
        bad.append("desat is not deterministic")
    if THEME_LIGHT["warn"] == THEME_DARK["warn"]:
        bad.append("--warn is the same in both themes; red on dark is unreadable")
    if set(THEME_LIGHT) != set(THEME_DARK):
        bad.append("the two themes define different properties: %s"
                   % sorted(set(THEME_LIGHT) ^ set(THEME_DARK)))
    css = theme_vars()
    for needle in ("--paper:", "--ink:", "--accent:", "--shadow:",
                   "prefers-color-scheme: dark", '[data-theme="dark"]',
                   ':root:not([data-theme="light"])'):
        if needle not in css:
            bad.append("theme_vars() lacks %r" % needle)
    # every property defined in light must be defined in dark too, or a page
    # borrows its host's theme for whatever is missing
    import re
    blocks = css.split("\n")
    names = [set(re.findall(r"--[a-z0-9-]+(?=:)", b)) for b in blocks if b.strip()]
    if not (names[0] - {"--shadow"}) <= names[1]:
        bad.append("a custom property is defined in light and not in dark: %s"
                   % sorted((names[0] - {"--shadow"}) - names[1]))
    return bad


if __name__ == "__main__":
    import sys
    problems = selftests()
    for p in problems:
        print("  FAIL  %s" % p)
    print("ALL PASS (_pagestyle self-tests)" if not problems else "FAIL")
    sys.exit(1 if problems else 0)
