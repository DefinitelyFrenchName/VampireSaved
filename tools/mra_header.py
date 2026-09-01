#!/usr/bin/env python3
"""mra_header.py — rewrite the WIDE MRA's comment header (14z-126b).

WHY THIS IS A POST-PROCESS AND NOT A CONFIG OR A FORK CHANGE.  The header
jtframe emits lives in SHARED code (`modules/jtframe/src/jtframe/mra/
mame2mra.go`), and the per-core `mraauthor` knob in `cores/cps2w/cfg/
mame2mra.toml` is read for BOTH legs -- so either route would also rewrite
the STOCK CONTROL MRA and break the twin invariant `test_jtcores_twin`
(2a/2c) exists to prove: that cps2w emits MRAs byte-identical to stock
cps2's except `<rbf>`.  Selecting by `<setname>vsavjw</setname>` touches
the WIDE leg ONLY and leaves the stock leg jtframe's own output.

WHAT IT ASSERTS.  Jotego's core is the FPGA arcade hardware and the support
link stays; the WIDE profile is ours; issues do NOT go to him or to the
MiSTer project; jtcores and this fork are both GPL-3.0 (verified against
both LICENSE files, 2026-09-01).  Maintainer-approved wording, 2026-09-01.
"""
import re, sys, pathlib

HEADER = """
              Vampire Saved - CPS-2 WIDE
              An 18-character Vampire Savior roster on CPS-2.

              THE FPGA ARCADE HARDWARE IS JOTEGO'S WORK.
              This MRA targets jtcps2w, a MODIFIED version of Jose Tejada's
              jtcps2 core (jotego/jtcores), extended by Project Vampire Saved
              with the CPS-2 WIDE profile. The CPS-2 implementation, which is
              everything that makes this a working arcade core, is his.

              PLEASE SUPPORT JOTEGO'S RESEARCH. It is what this is built on.
              Patreon: https://patreon.com/jotego
              (c) Jose Tejada, 2026. The original jtcps2 core.

              DO NOT REPORT ISSUES WITH THIS CORE TO JOTEGO OR TO THE MiSTer
              PROJECT. The WIDE modifications are neither his nor theirs.
              https://github.com/DefinitelyFrenchName/VampireSaved

              This work is not maintained by the MiSTer project.

              Neither project endorses or participates in illegal distribution
              of copyrighted material. This work can be used with compatible
              software: homebrew projects or legally obtained memory dumps.

              jtcores and this fork are both licensed GNU GPL v3.
              https://www.gnu.org/licenses/gpl-3.0.html

"""

def rewrite(p):
    t = p.read_text(encoding="utf-8")
    if "<setname>vsavjw</setname>" not in t:
        return False                      # stock leg: never touched
    if "THE FPGA ARCADE HARDWARE IS JOTEGO'S WORK" in t:
        return False                      # idempotent
    # XML FORBIDS "--" INSIDE A COMMENT. An em-dash written as "--" produces a
    # file MiSTer's parser can reject; caught here 14z-126b before it shipped.
    if "--" in HEADER:
        sys.exit("mra_header: HEADER contains '--', illegal inside an XML comment")
    new, n = re.subn(r"<!--.*?-->", "<!--%s-->" % HEADER, t, count=1, flags=re.S)
    if n != 1:
        sys.exit("mra_header: no comment block in %s" % p)
    import xml.dom.minidom
    try:
        xml.dom.minidom.parseString(new)
    except Exception as e:
        sys.exit("mra_header: rewrite would produce invalid XML in %s: %s" % (p, e))
    p.write_text(new, encoding="utf-8")
    return True

if __name__ == "__main__":
    done = [str(p) for p in sorted(pathlib.Path(sys.argv[1]).rglob("*.mra")) if rewrite(p)]
    for d in done:
        print("[mra_header] rewrote %s" % d)
    if not done:
        print("[mra_header] no WIDE MRA needed rewriting", file=sys.stderr)
