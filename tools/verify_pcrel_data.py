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

Exit 1 if any pointer resolves to bytes that do not match its table.
"""
import argparse
import json
import os
import subprocess
import sys
import tempfile


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
    a = ap.parse_args()

    repo = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    extract = os.path.join(a.build_dir, "extract")
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
    zips = [f for f in os.listdir(os.path.join(a.build_dir, "rompath"))
            if f.endswith(".zip")]
    assert zips, "no romset zip in the build's rompath"
    _, built_da = decrypted_views(os.path.join(a.build_dir, "rompath", zips[0]))
    src_da = open(a.src_data, "rb").read()

    findings = census.get("pcrel_data_escapes", [])
    if a.region:
        findings = [f for f in findings if f["region"] == a.region]
    if not findings:
        print("no pcrel data-pointer escapes to verify")
        return 0

    bad, checked, skipped = [], 0, 0
    for f in findings:
        reg = f["region"]
        if reg not in placements:
            skipped += 1
            continue
        p = placements[reg]
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
