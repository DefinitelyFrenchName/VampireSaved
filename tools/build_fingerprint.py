#!/usr/bin/env python3
"""build_fingerprint.py — identify which build a rompath resolves to, and map
it to an expectation set (the auto-detecting regression runner's dispatch,
CLAUDE.md §4).

The fingerprint is the SHA-1 of the set's concatenated program members (file
order, sorted by member number) from the FIRST zip found across the
';'-separated rompath — the same resolution MAME applies. The registry
(tests/expected/registry.tsv, TAB-separated: sha1 / expectation-set / notes)
maps fingerprints to expectation directories under tests/expected/.

Rows are added to the registry only at freeze time, as a build decision
recorded in STATE.md.

Usage:
    python3 tools/build_fingerprint.py <rompath> [--set vsavj]
        [--registry tests/expected/registry.tsv] [--sha-only]

Prints the expectation-set name on stdout (exit 0), or the unregistered
fingerprint with exit 2. --sha-only always prints just the fingerprint.

KNOWN BLIND SPOT (measured 14z-54, CPS-2 WIDE B0): the dispatch fingerprint
covers PROGRAM members only. Two builds with identical program images but
different gfx/QSound members — or run under different emulator hardware
profiles — fingerprint identically, and today that difference survives only
as a hand-written note in the registry. `--full` computes a whole-set
fingerprint (every member of every resolved zip, plus a per-region
breakdown) which closes it for reporting and freeze records. Promoting
--full to the dispatch key is deliberate future work: it changes every
existing fingerprint and so requires recomputing the registry rows (the
expectation CONTENT is unaffected — it is a registry update, not a
re-freeze).
"""

import argparse
import hashlib
import sys
import zipfile
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import cps2_decrypt as cps  # noqa: E402


def program_sha1(zpath):
    with zipfile.ZipFile(zpath) as zf:
        prgs = sorted((n for n in zf.namelist() if cps._PRG_RE.search(n)),
                      key=lambda n: int(cps._PRG_RE.search(n).group(1)))
        if not prgs:
            sys.exit(f"{zpath}: no program members")
        h = hashlib.sha1()
        for n in prgs:
            h.update(zf.read(n))
    return h.hexdigest()


def full_fingerprint(zpaths):
    """SHA-1 over every member of every resolved zip, plus a per-region
    breakdown. Region classification mirrors the CPS-2 descriptor kinds so
    a grown region is visible at a glance."""
    per = {}
    h = hashlib.sha1()
    for zpath in zpaths:
        with zipfile.ZipFile(zpath) as zf:
            for n in sorted(zf.namelist()):
                data = zf.read(n)
                h.update(n.encode())
                h.update(data)
                if cps._PRG_RE.search(n):
                    region = "prg"
                elif n.endswith(".key"):
                    region = "key"
                elif n.endswith((".01", ".02")):
                    region = "z80"
                else:
                    region = "gfx/qsnd"
                cnt, size = per.get(region, (0, 0))
                per[region] = (cnt + 1, size + len(data))
    return h.hexdigest(), per


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("rompath", help="';'-separated rompath, MAME resolution order")
    ap.add_argument("--set", default="vsavj", dest="setname")
    ap.add_argument("--registry", type=Path,
                    default=Path(__file__).resolve().parent.parent
                    / "tests" / "expected" / "registry.tsv")
    ap.add_argument("--sha-only", action="store_true")
    ap.add_argument("--full", action="store_true",
                    help="whole-set fingerprint (all members, all resolved "
                         "zips) + region breakdown — covers the gfx/QSound "
                         "content the dispatch fingerprint cannot see")
    args = ap.parse_args()

    zpath = None
    for d in args.rompath.split(";"):
        cand = Path(d) / f"{args.setname}.zip"
        if cand.is_file():
            zpath = cand
            break
    if zpath is None:
        sys.exit(f"{args.setname}.zip not found in rompath {args.rompath}")

    if args.full:
        # Resolve the clone chain the way the emulator does: the set's own
        # zip first, then the parent set's zip for shared members.
        chain, seen = [zpath], {zpath.resolve()}
        for d in args.rompath.split(";"):
            for parent in ("vsav.zip",):
                cand = Path(d) / parent
                # dedupe by RESOLVED path: overlay rompaths symlink the
                # reference zips, so the same file appears under several
                # directories and would otherwise be hashed twice.
                if cand.is_file() and cand.resolve() not in seen:
                    seen.add(cand.resolve())
                    chain.append(cand)
        full, per = full_fingerprint(chain)
        print(f"full-set fingerprint: {full}")
        for region in sorted(per):
            cnt, size = per[region]
            print(f"  {region:9s} {cnt:2d} members  {size/1048576:7.2f} MB")
        print("  zips: " + ", ".join(str(z.name) for z in chain))
        return

    sha = program_sha1(zpath)
    if args.sha_only:
        print(sha)
        return

    if args.registry.is_file():
        for line in args.registry.read_text().splitlines():
            if not line.strip() or line.startswith("#"):
                continue
            parts = line.split("\t")
            if len(parts) >= 2 and parts[0] == sha:
                print(parts[1])
                return
    print(f"UNREGISTERED build fingerprint {sha} ({zpath})\n"
          f"add a row to {args.registry} as a build decision (STATE.md)",
          file=sys.stderr)
    print(sha)
    sys.exit(2)


if __name__ == "__main__":
    main()
