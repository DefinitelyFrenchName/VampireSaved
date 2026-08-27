#!/usr/bin/env python3
"""gen_vsavjw_xml.py — emit the `vsavjw` machine entry for jtframe's machine
catalogue (`doc/mame.xml` in the jtcores fork), derived from a BUILT WIDE
romset.  (14z-107 (5), MiSTer slice D0; docs/project/mister_map.md.)

WHY THIS TOOL EXISTS — the finding that forced it.  jtframe's `.rom` builder
locates every zip member by **CRC32 and by nothing else**
(`modules/jtframe/src/jtframe/mra/mra2rom.go:163-172`: it walks the zips and
compares `file.CRC32`, with no fallback to the name).  FBNeo and MAME resolve
by NAME and only warn on a CRC mismatch, which is why the WIDE members carry
SENTINEL hashes in both drivers (`vsw.41` = `dec0de41`, …) and why a content
change there is free.  On MiSTer a sentinel CRC is not a warning, it is
`Warning: cannot find file … in zip` and NO `.rom` at all.  So the MiSTer
machine entry has to name the CRCs of the actual build, and it is generated
from the zip rather than hand-written.

WHAT IT PRODUCES.  A `<machine name="vsavjw" …>` element that is `vsavj`'s
entry from the same catalogue with three deliberate differences:

  * `sourcefile="capcom/cps2w.cpp"` — the reference `cps2` core parses
    `sourcefile=["cps2.cpp"]`, which does not match, so the WIDE set is
    invisible to it BY CONSTRUCTION and `cores/cps2` stays untouched.
    `cores/cps2w` opts in with `sourcefile=[ "cps2.cpp", "cps2w.cpp" ]`.
  * the description carries ", CPS-2 WIDE v1", matching the MAME driver entry
    (`emu/mame-patches/0002-cps2-wide-v1.patch`).
  * the ROM list is the WIDE v1 load map, with the QSound EXTENSION declared
    in a region of its own (`qsoundw`) so the MRA can trim it — see below.

Everything else (dipswitch ports, display, input, device_ref, driver status)
is copied VERBATIM from `vsavj`, so the generated MRA differs from the stock
`vsavj` MRA only where the ROM map differs.  That is what makes the twin
comparison in `tests/test_mister_mra_map.sh` mean something.

THE `qsoundw` REGION IS NOT A MAME REGION.  MAME's `vsavjw` puts all four
QSound members in `qsound`.  Here `vsw.21m` is split out into `qsoundw` and
`vsw.22m` is not declared at all, because the MiSTer image MUST trim the
declared-but-empty tail: mapped verbatim the WIDE `.rom` is 70.26 MB, which
overflows the 26-bit game-side `ioctl_addr` (64 MB) AND the 16-bit region
start word in the header (`docs/project/mister_map.md` §3).  Splitting the
region is what lets `cores/cps2w/cfg/mame2mra.toml` place a byte WINDOW into
`vsw.21m` while leaving the stock 8 MB mapped exactly as the reference core
maps it.  The ROMSET is untouched: `vsw.22m` and the rest of `vsw.21m` stay
in the zip for FBNeo and MAME.

Usage:
    tools/gen_vsavjw_xml.py <vsavjw.zip> [--template <mame.xml>] [-o <out>]
    tools/gen_vsavjw_xml.py <vsavjw.zip> --check <mame.xml>

`--check` compares the generated element against the one already in the
catalogue and exits non-zero on any difference — that is the gate's form, so
a romset rebuild that moves a CRC cannot silently leave the fork stale.

Rule 7: this tool reads a ROM zip and prints only names, sizes and hashes.
No ROM bytes are emitted, quoted or written.
"""
import argparse
import hashlib
import os
import re
import sys
import zipfile

# The WIDE v1 load map, mirroring ROM_START(vsavjw) in
# emu/mame-patches/0002-cps2-wide-v1.patch — same members, same regions, same
# offsets — EXCEPT that the QSound extension is split into `qsoundw` (see the
# module docstring) and `vsw.22m` is not declared.
#
# (region, member, offset)   offsets are hex strings, MAME listxml style
LOADMAP = [
    ("maincpu",  "vm3j.03d", "0"),
    ("maincpu",  "vm3j.04d", "80000"),
    ("maincpu",  "vm3j.05a", "100000"),
    ("maincpu",  "vm3j.06b", "180000"),
    ("maincpu",  "vm3j.07b", "200000"),
    ("maincpu",  "vm3j.08a", "280000"),
    ("maincpu",  "vm3j.09b", "300000"),
    ("maincpu",  "vm3j.10b", "380000"),
    ("maincpu",  "vsw.41",   "400000"),
    ("maincpu",  "vsw.42",   "480000"),
    ("maincpu",  "vsw.43",   "500000"),
    ("maincpu",  "vsw.44",   "580000"),
    ("gfx",      "vm3.13m",  "0"),
    ("gfx",      "vm3.15m",  "2"),
    ("gfx",      "vm3.17m",  "4"),
    ("gfx",      "vm3.19m",  "6"),
    ("gfx",      "vm3.14m",  "1000000"),
    ("gfx",      "vm3.16m",  "1000002"),
    ("gfx",      "vm3.18m",  "1000004"),
    ("gfx",      "vm3.20m",  "1000006"),
    ("gfx",      "vsw.31m",  "2000000"),
    ("gfx",      "vsw.33m",  "2000002"),
    ("gfx",      "vsw.35m",  "2000004"),
    ("gfx",      "vsw.37m",  "2000006"),
    ("audiocpu", "vsw.z01",  "0"),
    ("audiocpu", "vsw.z02",  "28000"),
    ("qsound",   "vm3.11m",  "0"),
    ("qsound",   "vm3.12m",  "400000"),
    ("qsoundw",  "vsw.21m",  "0"),
    ("key",      "vsavj.key", "0"),
]
# Members that live in the PARENT zip (vsav.zip); MAME marks those `merge=`.
# jtframe ignores the attribute, but the catalogue stays honest.
PARENT_MEMBERS = {
    "vm3.11m", "vm3.12m",
    "vm3.13m", "vm3.14m", "vm3.15m", "vm3.16m",
    "vm3.17m", "vm3.18m", "vm3.19m", "vm3.20m",
}
DESCRIPTION = ("Vampire Savior: The Lord of Vampire "
               "(Japan 970519, CPS-2 WIDE v1)")
SOURCEFILE = "capcom/cps2w.cpp"


def machine_element(text, name):
    m = re.search(r'<machine name="%s"[ >].*?</machine>\n' % re.escape(name),
                  text, re.S)
    if not m:
        sys.exit("no <machine name=\"%s\"> in the catalogue" % name)
    return m.group(0)


def member_facts(zips):
    """{name: (size, crc, sha1)} over every zip given, first hit wins."""
    facts = {}
    for path in zips:
        z = zipfile.ZipFile(path)
        print("read %s sha1 %s" % (path, sha1_file(path)), file=sys.stderr)
        for info in z.infolist():
            if info.filename in facts:
                continue
            data = z.read(info.filename)
            facts[info.filename] = (info.file_size, "%08x" % info.CRC,
                                    hashlib.sha1(data).hexdigest())
    return facts


def sha1_file(path):
    h = hashlib.sha1()
    with open(path, "rb") as f:
        for chunk in iter(lambda: f.read(1 << 20), b""):
            h.update(chunk)
    return h.hexdigest()


def build(template_text, facts):
    src = machine_element(template_text, "vsavj")
    head, _, tail = src.partition("\n")
    # everything from the first non-<rom> child after the rom block
    body = tail
    rows = []
    for region, member, offset in LOADMAP:
        if member not in facts:
            sys.exit("member %s is not in the romset — the WIDE build is not "
                     "the one this load map describes" % member)
        size, crc, sha1 = facts[member]
        merge = ' merge="%s"' % member if member in PARENT_MEMBERS else ""
        rows.append('\t\t<rom name="%s"%s size="%d" crc="%s" sha1="%s" '
                    'region="%s" offset="%s"/>' %
                    (member, merge, size, crc, sha1, region, offset))
    # replace the whole <rom .../> run with ours, keep everything else verbatim
    lines = body.split("\n")
    first = next(i for i, l in enumerate(lines) if l.lstrip().startswith("<rom "))
    last = max(i for i, l in enumerate(lines) if l.lstrip().startswith("<rom "))
    out = lines[:first] + rows + lines[last + 1:]
    head = ('<machine name="vsavjw" sourcefile="%s" cloneof="vsav" '
            'romof="vsav">' % SOURCEFILE)
    text = head + "\n" + "\n".join(out)
    text = re.sub(r"<description>.*?</description>",
                  "<description>%s</description>" % DESCRIPTION, text, count=1)
    return text


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("zip", help="the built WIDE romset (vsavjw.zip)")
    ap.add_argument("--parent", help="vsav.zip, for the merged members "
                    "(default: <zip dir>/vsav.zip)")
    ap.add_argument("--template", default=None,
                    help="jtframe machine catalogue to take vsavj from "
                         "(default: emu/jtcores/doc/mame.xml)")
    ap.add_argument("-o", "--out", help="write the element here (default stdout)")
    ap.add_argument("--check", metavar="MAME_XML",
                    help="compare against the vsavjw entry in this catalogue "
                         "and exit 1 on any difference")
    a = ap.parse_args()

    repo = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    template = a.template or os.path.join(repo, "emu", "jtcores", "doc", "mame.xml")
    # THE PARENT: the build's own vsav.zip if it packs one (pre-14z-112
    # packaging), otherwise the PRISTINE dump from $ROMDIR. Since 14z-112 a
    # WIDE build packs NO vsav.zip — the patched group-A members live inside
    # vsavjw.zip — so that one SD card can carry this profile and stock
    # Vampire Savior at once. Group B and the QSound members still come from
    # the parent, and with no fallback this exits "member vm3.14m is not in
    # the romset" on a perfectly good build.
    parent = a.parent or os.path.join(os.path.dirname(os.path.abspath(a.zip)),
                                      "vsav.zip")
    if not os.path.exists(parent) and os.environ.get("ROMDIR"):
        parent = os.path.join(os.environ["ROMDIR"], "vsav.zip")
    zips = [a.zip] + ([parent] if os.path.exists(parent) else [])
    facts = member_facts(zips)
    with open(template, encoding="utf-8", errors="replace") as f:
        text = build(f.read(), facts)

    if a.check:
        with open(a.check, encoding="utf-8", errors="replace") as f:
            have = machine_element(f.read(), "vsavjw").rstrip("\n")
        if have != text.rstrip("\n"):
            print("MISMATCH: the vsavjw entry in %s is not what %s produces"
                  % (a.check, a.zip), file=sys.stderr)
            import difflib
            for line in difflib.unified_diff(have.split("\n"),
                                             text.rstrip("\n").split("\n"),
                                             "catalogue", "generated",
                                             lineterm=""):
                print(line, file=sys.stderr)
            return 1
        print("ok: the catalogue's vsavjw entry matches %s" % a.zip)
        return 0

    if a.out:
        with open(a.out, "w", encoding="utf-8") as f:
            f.write(text + "\n")
        print("wrote %s" % a.out, file=sys.stderr)
    else:
        print(text)
    return 0


if __name__ == "__main__":
    sys.exit(main())
