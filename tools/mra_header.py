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

THE BUILD BLOCK (14z-133b, maintainer-ruled 2026-09-05: "the merged build
referenced somewhere in the mister builds" -- and NOT in the MRA <name>).
With --build <dir|rompath> the comment ends with the freeze this MRA
belongs to: the registry row resolved from the build's rompath (whole-set
key first, program key second -- build_fingerprint.py's dual lookup), the
mark when the row is merged-mN (the mark IS the merged build number since
14z-132, gated by test_version_string), the vsavjw.zip sha1 and both keys.
IT IS SELF-VERIFYING: the block is written only after every CRC-identified
<part> of the MRA resolves against that build's zips (check_mra_parts'
index); a mismatch is a hard error, so the line can never name a build the
MRA was not generated for. Without --build the block says so.

Usage: mra_header.py <dir-holding-the-.mra-files> [--build <build dir or rompath>]
"""
import re, sys, pathlib, hashlib, zipfile
sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
import build_fingerprint as bf
import check_mra_parts as cmp_parts

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

def registry_rows(repo):
    reg = repo / "tests" / "expected" / "registry.tsv"
    rows = []
    if reg.is_file():
        for line in reg.read_text().splitlines():
            if line.strip() and not line.startswith("#"):
                parts = line.split("\t")
                if len(parts) >= 2:
                    rows.append((parts[0], parts[1]))
    return rows

def tag_lookup(repo, wkey, pkey):
    import subprocess
    try:
        out = subprocess.run(["git", "-C", str(repo), "for-each-ref", "refs/tags/freeze/",
                              "--format=%(refname:short)\t%(contents)"],
                             capture_output=True, text=True, check=True).stdout
    except Exception:
        return None, None
    tags = {}
    for chunk in re.split(r"(?m)^(?=freeze/)", out):
        if chunk.startswith("freeze/"):
            n, _, body = chunk.partition("\t"); tags[n[len("freeze/"):]] = body
    hit = [n for n, b in tags.items() if wkey in b]
    if len(hit) == 1:
        return hit[0], "whole-set key, annotated tag freeze/%s (a merged build not yet registered)" % hit[0]
    hit = sorted(n for n, b in tags.items() if pkey in b)
    if len(hit) == 1:
        return hit[0], "program key ONLY, annotated tag freeze/%s (not under a whole-set key)" % hit[0]
    if len(hit) > 1:
        return "AMBIGUOUS", "program key matches tags %s and no whole-set key matches" % ", ".join("freeze/" + n for n in hit)
    return None, None

def build_block(build):
    """The lines naming the freeze; raises SystemExit on an unresolvable build."""
    repo = pathlib.Path(__file__).resolve().parent.parent
    rp = pathlib.Path(build)
    if not (rp / "vsavjw.zip").is_file():
        rp = rp / "rompath"
    if not (rp / "vsavjw.zip").is_file():
        rp2 = repo / build / "rompath"
        rp = rp2 if (rp2 / "vsavjw.zip").is_file() else rp
    z = rp / "vsavjw.zip"
    if not z.is_file():
        sys.exit("mra_header: --build %s has no rompath/vsavjw.zip" % build)
    wkey = bf.wholeset_key(z); pkey = bf.program_sha1(z)
    zsha = hashlib.sha1(z.read_bytes()).hexdigest()
    rows = registry_rows(repo)
    name = next((n for k, n in rows if k == wkey), None); how = "whole-set key, tests/expected/registry.tsv"
    if name is None:
        name = next((n for k, n in rows if k == pkey), None)
        how = "program key, tests/expected/registry.tsv (NOT registered under a whole-set key)"
    if name is None:
        # A MERGED BUILD NOT YET REGISTERED (B2 gave merged-m16 a whole-set row at
        # 14z-133b; a later freeze is unregistered until its own): its record is the annotated
        # freeze/merged-mN tag, whose message carries the keys -- the anchor the
        # version-string gate was ruled to use ([VSP-166]). Whole-set key first;
        # a program-key-only match is named only when it is UNIQUE (merged-m15
        # and merged-m16 share one), and says so.
        name, how = tag_lookup(repo, wkey, pkey)
    if name is None:
        name = "UNREGISTERED"; how = "no registry row and no freeze tag for either key"
    m = re.match(r"merged-m(\d+)$", name)
    mark = ("mark M%s (the mark IS the merged build number since 14z-132)" % m.group(1)) if m else "mark: see the freeze's registry row"
    lines = ["", "              BUILD  %s  .  %s" % (name, mark),
             "              resolved by %s" % how,
             "              vsavjw.zip  sha1 %s" % zsha,
             "              whole-set key %s" % wkey,
             "              program key   %s" % pkey, ""]
    return "\n".join(lines) + "\n", rp

NO_BUILD = """
              BUILD  not stated: generated without a build (no wide build
              option), so this file names
              no freeze. Its CRCs are whatever the fork's doc/mame.xml held.
"""

def parts_resolve(mra_path, rp):
    """Every CRC-identified <part> must resolve in the build's own zips PLUS the
    pristine reference dumps ($ROMDIR: the WIDE set is a clone whose parent
    members the MRA also lists, and since 14z-112 a build packs only its own
    zip) -- AND at least one part must resolve ONLY through the build's zip,
    so a build the MRA never references cannot be named either."""
    import os
    romdir = os.environ.get("ROMDIR", "")
    if not romdir or not os.path.isdir(romdir):
        sys.exit("mra_header: --build needs ROMDIR (the parent members live there)")
    build_idx = cmp_parts.crc_index([str(rp)])
    all_idx = cmp_parts.crc_index([str(rp), romdir])
    t = mra_path.read_text(encoding="utf-8")
    crcs = [c.lower().zfill(8) for c in re.findall(r'<part[^>]*\bcrc="([0-9a-fA-F]+)"', t)]
    missing = [c for c in crcs if c not in all_idx]
    only_build = [c for c in crcs if c in build_idx and c not in cmp_parts.crc_index([romdir])]
    if crcs and not missing and not only_build:
        missing = ["<no part is served by the build's own zip>"]
    return len(crcs), missing

def rewrite(p, build=None):
    t = p.read_text(encoding="utf-8")
    if "<setname>vsavjw</setname>" not in t:
        return False                      # stock leg: never touched
    # XML FORBIDS "--" INSIDE A COMMENT. An em-dash written as "--" produces a
    # file MiSTer's parser can reject; caught here 14z-126b before it shipped.
    if "--" in HEADER:
        sys.exit("mra_header: HEADER contains '--', illegal inside an XML comment")
    if build:
        block, rp = build_block(build)
        n_parts, missing = parts_resolve(p, rp)
        if not n_parts or missing:
            sys.exit("mra_header: REFUSING to name build %s in %s: %d of %d CRC parts do not "
                     "resolve in %s (%s) -- the MRA was not generated for this build"
                     % (build, p.name, len(missing), n_parts, rp, ", ".join(missing[:4])))
    else:
        block = NO_BUILD
    if "--" in block:
        sys.exit("mra_header: build block contains '--'")
    new, n = re.subn(r"<!--.*?-->", "<!--%s%s-->" % (HEADER, block), t, count=1, flags=re.S)
    if n != 1:
        sys.exit("mra_header: no comment block in %s" % p)
    if new == t:
        return False                      # idempotent: already exactly this header
    import xml.dom.minidom
    try:
        xml.dom.minidom.parseString(new)
    except Exception as e:
        sys.exit("mra_header: rewrite would produce invalid XML in %s: %s" % (p, e))
    p.write_text(new, encoding="utf-8")
    return True

if __name__ == "__main__":
    args = sys.argv[1:]; build = None
    if "--build" in args:
        i = args.index("--build"); build = args[i + 1]; del args[i:i + 2]
    if len(args) != 1:
        sys.exit(__doc__)
    done = [str(p) for p in sorted(pathlib.Path(args[0]).rglob("*.mra")) if rewrite(p, build)]
    for d in done:
        print("[mra_header] rewrote %s" % d)
    if not done:
        print("[mra_header] no WIDE MRA needed rewriting", file=sys.stderr)
