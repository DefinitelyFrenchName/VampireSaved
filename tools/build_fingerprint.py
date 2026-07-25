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


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("rompath", help="';'-separated rompath, MAME resolution order")
    ap.add_argument("--set", default="vsavj", dest="setname")
    ap.add_argument("--registry", type=Path,
                    default=Path(__file__).resolve().parent.parent
                    / "tests" / "expected" / "registry.tsv")
    ap.add_argument("--sha-only", action="store_true")
    args = ap.parse_args()

    zpath = None
    for d in args.rompath.split(";"):
        cand = Path(d) / f"{args.setname}.zip"
        if cand.is_file():
            zpath = cand
            break
    if zpath is None:
        sys.exit(f"{args.setname}.zip not found in rompath {args.rompath}")

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
