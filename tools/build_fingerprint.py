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
breakdown) which closes it for reporting and freeze records. CAVEAT: it
hashes the union of the resolved zips, which is a SUPERSET of what the
driver actually loads (a clone zip's parent carries the other regions'
program members too). It is a faithful identity for "this artifact set",
not a statement of "what the emulator mapped".

THE PROMOTION HAPPENED, FORWARD-ONLY (14z-132, maintainer-ruled). This
paragraph used to end "promoting --full to the dispatch key is deliberate
future work ... requires recomputing the registry rows". THAT PLAN WAS
MEASURED AND IS NOT EXECUTABLE: only 20 of 58 live registry rows are
recomputable, the other 38 having had their build dirs pruned under the N-2
policy — and those rows are INERT, since nothing can dispatch on a build that
no longer exists. So the promotion is forward-only: NEW rows carry the
whole-set key (`--set-key`, see wholeset_key() — NOT `--full`, which is
chain-dependent), historical rows keep their program key, and the resolver
tries whole-set first then program. No registry FORMAT change was needed: a
row's key is just a sha1. MERGED rows are whole-set-keyed ONLY, which is what
lets the merged build have a row at all — see registry.tsv's header for the
objection that blocked one, and docs/project/gotchas.md for what the program
key collapses.
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
                # Classify by NAME, which is a heuristic: FBNeo/MAME classify
                # by descriptor type, and this tool cannot read the driver
                # table. WIDE's appended members are named so the heuristic
                # stays right: "vsw.NNm" = gfx/qsnd, "vsw.NN" = program.
                if n.endswith(".key"):
                    region = "key"
                elif n.endswith((".01", ".02")):
                    region = "z80"
                elif n.startswith("vsw."):
                    region = "gfx/qsnd" if n.endswith("m") else "prg"
                elif cps._PRG_RE.search(n):
                    region = "prg"
                else:
                    region = "gfx/qsnd"
                cnt, size = per.get(region, (0, 0))
                per[region] = (cnt + 1, size + len(data))
    return h.hexdigest(), per


def wholeset_key(zpath):
    """The DISPATCH whole-set key: SHA-1 over every member of every zip in the
    BUILD'S OWN rompath directory — the directory holding the resolved zip —
    and nothing else.

    CHAIN-INDEPENDENT BY CONSTRUCTION, which is the whole point. `--full`
    hashes the union of the RESOLVED zips, so a ';' rompath folds $ROMDIR's
    members into the digest and one build hashes differently depending on
    which caller asked (measured 14z-132: `fcc83fc3` over
    `build/m3b_merged23/rompath`, `544990c4` over the same with `;../ROMS`).
    `tools/artifact_manifest.py` REFUSES a ';' chain for exactly that reason;
    this key achieves the same end by ignoring the chain instead.

    Since 14z-112 a build packs only its own zip(s), so this digest is
    precisely "what this build authored" — which is what a dispatch key
    should name.
    """
    h = hashlib.sha1()
    for zp in sorted(zpath.parent.glob("*.zip"), key=lambda q: q.name):
        h.update(zp.name.encode())
        with zipfile.ZipFile(zp) as zf:
            for n in sorted(zf.namelist()):
                h.update(n.encode())
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
    ap.add_argument("--set-key", action="store_true",
                    help="print the whole-set DISPATCH key (this "
                         "build's own rompath dir only) and exit")
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

    wkey = wholeset_key(zpath)
    if args.set_key:
        print(wkey)
        return

    # DUAL LOOKUP (14z-132, maintainer-ruled): a row's key is just a sha1, so
    # no registry FORMAT change was needed. The whole-set key is tried FIRST
    # because it is the specific one; the program key is the historical
    # space, which STOPS GROWING under the forward-only promotion. Merged
    # rows are whole-set-keyed ONLY, so the program fallback can never
    # resolve `build/merged1` (the blanks-only legacy instrument, which
    # shares the shipped merged image's program fingerprint) onto a merged
    # expectation set — the objection registry.tsv's own header raises.
    rows = []
    if args.registry.is_file():
        for line in args.registry.read_text().splitlines():
            if not line.strip() or line.startswith("#"):
                continue
            parts = line.split("\t")
            if len(parts) >= 2:
                rows.append((parts[0], parts[1]))

    for key, name in rows:
        if key == wkey:
            print(name)
            return
    for key, name in rows:
        if key == sha:
            # LOUD BY DESIGN. After the promotion a program-key hit always
            # means "not registered under a whole-set key", and a silent hit
            # here is how build/don_m20 resolves as donovan-m19 (both
            # 8065bc92) — docs/project/gotchas.md, "A gfx-only freeze gives
            # two builds ONE dispatch key". stderr, so callers capturing
            # stdout for the set name are unaffected.
            print(f"NOTE: {zpath.parent} resolved to '{name}' by PROGRAM KEY "
                  f"{sha} — not registered under a whole-set key ({wkey}). "
                  f"The program key cannot see gfx/QSound/extension content.",
                  file=sys.stderr)
            print(name)
            return
    print(f"UNREGISTERED build: whole-set {wkey}, program {sha} ({zpath})\n"
          f"add a row to {args.registry} as a build decision (STATE.md)",
          file=sys.stderr)
    print(sha)
    sys.exit(2)


if __name__ == "__main__":
    main()
