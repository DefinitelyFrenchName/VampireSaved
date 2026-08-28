#!/usr/bin/env python3
"""verify_pcrel_data.py — decide whether a region's pc-relative DATA
pointers still reach their tables in a BUILT image (14z-69).

WHY THIS EXISTS. `census_regions.py` census 3 reports every
`lea (d16,pc),An` whose target leaves its region. That is a report, not
a verdict: the displacement is copied verbatim, so after placement the
pointer resolves to `target + region_delta`, and whether that is right
depends entirely on whether those bytes travelled with the region. This
tool answers that by reading the built image and comparing the bytes at
the resolved address against the source table.

It is the instrument that turned "the ported machine carries a live
embedded table that reads garbage" from a hypothesis into a measured
fact: on build/hui11, region x06cac0's four pointers (0x6D768, 0x6D7E8,
0x6D868, 0x6D91C — the row-8 machine's fleet param streams) all resolve
into unrelated bytes, because the region was extracted 0x2AC bytes
SHORTER than its declared root (0xC00 against `0x6cac0:0xebc`), leaving
every table past its end.

Compare DATA views: these are data reads, and inside the crypt range the
opcode and data views differ completely (docs/platform/gotchas.md).

Usage:
  verify_pcrel_data.py <build_dir> --src-data <vsav2_data.bin>
                       [--census <census.json>] [--region NAME]
                       [--extract <dir>] [--placement-suffix <@tenant>]

MERGED BUILDS (14z-101, GitHub #106): a merged build carries no extract/
of its own (it composes the solos' pinned extracts), and its placements
key non-reference tenants' regions as "<region>@<tenant>". Cover it one
tenant at a time with that tenant's own extract:

  verify_pcrel_data.py build/m3b_merged17 --src-data ... \
      --extract build/hui47/extract --placement-suffix @huitzil

Exit 1 if any pointer resolves to bytes that do not match its table.
"""
import argparse
import json
import os
import subprocess
import sys
import tempfile

# REFUSE TO RUN WITH ASSERTIONS DISABLED (14z-94, GitHub #79). The `zips` check is this instrument's census key: with it stripped, an
# empty rompath verifies NOTHING while still reporting success.
# These are `assert` statements, and `python -O` / PYTHONOPTIMIZE=1 removes
# assert statements ENTIRELY — so under that mode the check does not weaken,
# it VANISHES, and a bad result exits 0. Gated by tests/test_optimize_guard.sh.
if not __debug__:
    raise SystemExit(
        f"{__file__}: refusing to run under python -O / PYTHONOPTIMIZE — its "
        f"safety checks are assertions and would be stripped (GitHub #79)")


def decrypted_views(zip_path):
    """decrypt a built romset to (opcode, data) byte images"""
    repo = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    tmp = tempfile.mkdtemp()
    op = os.path.join(tmp, "op.bin")
    da = os.path.join(tmp, "da.bin")
    subprocess.run([sys.executable, os.path.join(repo, "tools", "cps2_decrypt.py"),
                    zip_path, op, "--data-out", da],
                   check=True, stdout=subprocess.DEVNULL)
    return open(op, "rb").read(), open(da, "rb").read()


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("build_dir")
    ap.add_argument("--src-data", required=True,
                    help="decrypted DATA view of the source set (vsav2)")
    ap.add_argument("--census", help="census_regions.py --json output; "
                    "default: run the census over <build_dir>/extract")
    ap.add_argument("--region", help="check only this region")
    ap.add_argument("--window", type=lambda s: int(s, 0), default=0x20,
                    help="bytes compared per table (default 0x20)")
    ap.add_argument("--extract", help="external extract dir (merged builds "
                    "have none of their own — pass the tenant's, #106)")
    ap.add_argument("--placement-suffix", default="",
                    help="appended to each region name when resolving "
                    "placements (merged builds key non-reference tenants' "
                    "regions as '<region>@<tenant>')")
    a = ap.parse_args()

    repo = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    extract = a.extract or os.path.join(a.build_dir, "extract")
    if not os.path.isdir(extract):
        print(f"FAIL: no extract dir at {extract} — a merged build needs "
              f"--extract <tenant's extract> (GitHub #106)", file=sys.stderr)
        return 2
    if a.census:
        census = json.load(open(a.census))
    else:
        tmp = tempfile.mkdtemp()
        out = os.path.join(tmp, "census.json")
        subprocess.run([sys.executable,
                        os.path.join(repo, "tools", "census_regions.py"),
                        extract, "--json", out],
                       check=True, stdout=subprocess.DEVNULL)
        census = json.load(open(out))

    placements = json.load(open(os.path.join(a.build_dir, "patch",
                                             "placements.json")))["regions"]
    zips = sorted(f for f in os.listdir(os.path.join(a.build_dir, "rompath"))
                  if f.endswith(".zip"))
    assert zips, "no romset zip in the build's rompath"
    # The PROGRAM image is the set zip (vsavjw.zip on the WIDE track);
    # vsav.zip is the pristine GFX DONOR, and verifying it would silently
    # measure the wrong image. zips[0] of an unordered listdir happened to
    # pick right on this filesystem — made deliberate 14z-101.
    prog = [z for z in zips if z != "vsav.zip"]
    _, built_da = decrypted_views(os.path.join(a.build_dir, "rompath",
                                               (prog or zips)[0]))
    src_da = open(a.src_data, "rb").read()

    # AN ABSENT KEY IS NOT AN EMPTY ONE (14z-94, GitHub #22). This used to be
    # `census.get("pcrel_data_escapes", [])`, so a renamed or missing key made
    # the tool print "nothing to verify" and exit 0 having checked zero
    # pointers — the permissive direction, and indistinguishable from a clean
    # result. The census is generated a few lines above, so the key's absence
    # means the census format moved, not that the build is clean.
    if "pcrel_data_escapes" not in census:
        print("FAIL: the census has no 'pcrel_data_escapes' key — the census "
              "format changed, so this tool verified NOTHING. Fix the key "
              "rather than reading the silence as a pass.", file=sys.stderr)
        return 2
    findings = census["pcrel_data_escapes"]
    total = len(findings)
    if a.region:
        findings = [f for f in findings if f["region"] == a.region]
        if total and not findings:
            print(f"FAIL: --region {a.region} matched none of the {total} "
                  f"escapes in the census; check the region name.",
                  file=sys.stderr)
            return 2
    if not findings:
        print("no pcrel data-pointer escapes in the census (0 to verify)")
        return 0

    bad, checked, skipped = [], 0, 0
    for f in findings:
        reg = f["region"]
        key = reg + a.placement_suffix
        if key not in placements:
            skipped += 1
            continue
        p = placements[key]
        delta = p["dst"] - p["src"]
        resolved = f["target"] + delta
        want = src_da[f["target"]:f["target"] + a.window]
        got = built_da[resolved:resolved + a.window]
        checked += 1
        if want != got:
            bad.append((reg, f["lea"], f["target"], resolved))
            print(f"  BROKEN {reg}: lea {f['lea']:#08x} -> table "
                  f"{f['target']:#08x} resolves to {resolved:#08x}, which "
                  f"does NOT hold that table")
            print(f"           want {want[:12].hex()}...")
            print(f"           got  {got[:12].hex()}...")
        else:
            print(f"  ok     {reg}: lea {f['lea']:#08x} -> table "
                  f"{f['target']:#08x} still reachable at {resolved:#08x}")

    print(f"\nverify_pcrel_data: {checked} checked, {len(bad)} BROKEN, "
          f"{skipped} skipped (region not placed in this build)")
    return 1 if bad else 0


if __name__ == "__main__":
    sys.exit(main())
