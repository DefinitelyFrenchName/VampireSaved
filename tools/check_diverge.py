#!/usr/bin/env python3
"""check_diverge.py — verify a checksum log diverges from a frozen base log
at EXACTLY the expected frame (run_suite's .diverge expectation kind).

A .diverge expectation ("<baseset> <frame>") encodes: this replay's log must
be line-identical to tests/expected/<baseset>/logs/<name>.log through
frame-1, and its first divergence must be exactly at <frame>. Divergence
earlier, later, or absent is a FAIL — the superset invariant is never
weakened, only precisely specified (e.g. the attract's Jedah demo at 4278).

Usage:
    python3 tools/check_diverge.py <log> <spec.diverge> <expected_root>

Exit 0 with "PASS ..." on stdout, 1 with "FAIL ..."/"NO-BASE-LOG ...".
"""

import sys
from pathlib import Path


def main():
    if len(sys.argv) != 4:
        sys.exit(__doc__)
    log, spec, exproot = sys.argv[1], Path(sys.argv[2]), Path(sys.argv[3])
    baseset, want = spec.read_text().split()
    want = int(want)
    base = exproot / baseset / "logs" / (spec.stem + ".log")
    if not base.is_file():
        print(f"NO-BASE-LOG {base}")
        sys.exit(1)
    a = [l for l in base.read_text().splitlines() if not l.startswith("END")]
    b = [l for l in Path(log).read_text().splitlines() if not l.startswith("END")]
    # 14z-90 (issue #3, found during judging — the filed issue named only
    # compare_window/compare_composite and credited THIS tool as a mitigation
    # for them). It carries the identical idiom: a short log compared against a
    # prefix of the basis reports "no divergence" for a run that simply stopped.
    if len(a) != len(b):
        print(f"FAIL length mismatch ({len(a)} vs {len(b)} frames vs {baseset})")
        sys.exit(1)
    div = None
    for i in range(min(len(a), len(b))):
        if a[i] != b[i]:
            div = int(a[i].split()[0])
            break
    if div == want:
        print(f"PASS (diverges from {baseset} at exactly {want})")
        sys.exit(0)
    print(f"FAIL first divergence at {div} (expected exactly {want} vs {baseset})")
    sys.exit(1)


if __name__ == "__main__":
    main()
