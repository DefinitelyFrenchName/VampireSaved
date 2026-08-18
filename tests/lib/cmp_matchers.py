#!/usr/bin/env python3
"""cmp_matchers.py — compare the canonical matcher against a reference
implementation over every committed reconciliation row (14z-95, GitHub #43).

Two modes, both used by tests/test_reconcile_matcher.sh:

    cmp_matchers.py <romdir> <old_reconcile_batch.py>
        Compare reconcile_batch._batch_search (the canonical matcher pinned
        to HIT_CAP/ALLOW_FALLBACK) against the PRE-REFACTOR drifted copy in
        the given file. Exit 0 iff every probe agrees — i.e. the refactor
        moved nothing and cannot move a row.

    cmp_matchers.py <romdir> <old_reconcile_batch.py> --control
        MUST-FIRE control for the mode above. Re-runs the same comparison
        with reconcile_batch's ALLOW_FALLBACK forced to True — a change that
        DOES move results — and exits 0 only if the comparison then FAILS.
        Without this, "1640 of 1640 identical" is equally consistent with a
        comparison that cannot detect anything.

    cmp_matchers.py <romdir> --free
        Compare the pinned parameters against the freed ones
        (hit_cap=None, allow_fallback=True). Exit 0 iff at least one probe
        DIFFERS — i.e. the parameters actually decide results. Inverted on
        purpose: here "no difference" is the failure, because a flag wired
        to nothing would make the gate blind and #43(b) a no-op.

Probes every (address, window) pair the batch tool would actually try: the
addresses are the vsav2 side of all three reconciliation manifests, and the
windows are pattern_resolve's own retry ladder. Reading them from the
manifests rather than hardcoding a list means the coverage grows with the
map instead of going stale against it.
"""

import importlib.util
import re
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent.parent
sys.path.insert(0, str(REPO / "tools"))

# pattern_resolve's retry ladder (tools/reconcile_batch.py). Kept here as the
# probe grid; if that ladder changes, this list is a deliberate second copy
# and section 2 of the gate will start disagreeing, which is the intent.
WINDOWS = (0x40, 0x30, 0x60, 0x80, 0x20)

MANIFESTS = ("reconciliation", "reconciliation_huitzil", "reconciliation_pyron")


def manifest_addrs():
    addrs = []
    for name in MANIFESTS:
        path = REPO / "build" / "manifest" / f"{name}.toml"
        if not path.exists():
            continue
        txt = path.read_text()
        addrs += [int(m, 16)
                  for m in re.findall(r"vsav2\s*=\s*0x([0-9a-fA-F]+)", txt)]
    return sorted(set(addrs))


def load_module(path, name):
    spec = importlib.util.spec_from_file_location(name, path)
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


def main():
    if len(sys.argv) not in (3, 4):
        sys.exit(__doc__)
    romdir, second = sys.argv[1], sys.argv[2]
    control = len(sys.argv) == 4 and sys.argv[3] == "--control"

    import find_equiv
    import reconcile_batch as rb

    if control:
        # perturb the binding, NOT the tracked file (GitHub #81: no test
        # writes into tools/). _batch_search reads these at call time.
        rb.ALLOW_FALLBACK = True

    src_pt, _ = rb.plaintext_image(f"{romdir}/vsav2.zip")
    dst_pt, _ = rb.plaintext_image(f"{romdir}/vsavj.zip")

    addrs = manifest_addrs()
    if not addrs:
        sys.exit("no reconciliation rows found — nothing to compare")

    free_mode = second == "--free"
    if free_mode:
        def reference(a, w):
            try:
                return find_equiv.masked_search(src_pt, dst_pt, a, w,
                                                hit_cap=None,
                                                allow_fallback=True)
            except find_equiv.WindowUnusable:
                return []
    else:
        old = load_module(second, "rb_prerefactor")
        if not hasattr(old, "masked_search"):
            sys.exit(f"{second} has no masked_search to compare against")
        reference = lambda a, w: old.masked_search(src_pt, dst_pt, a, w)  # noqa: E731

    same = 0
    moved = []
    for a in addrs:
        for w in WINDOWS:
            if rb._batch_search(src_pt, dst_pt, a, w) == reference(a, w):
                same += 1
            else:
                moved.append((a, w))
    total = len(addrs) * len(WINDOWS)

    if free_mode:
        print(f"  freed vs pinned: {len(moved)} of {total} probes DIFFER "
              f"({len(addrs)} rows x {len(WINDOWS)} windows)")
        # exit 0 = "the flags matter"; the gate treats a zero as the failure
        return 0 if moved else 1

    if control:
        print(f"  CONTROL (ALLOW_FALLBACK forced True): {len(moved)} of "
              f"{total} probes moved")
        # exit 0 = the control FIRED, i.e. the comparison can detect a change
        return 0 if moved else 1

    print(f"  pinned vs pre-refactor copy: {same} of {total} IDENTICAL "
          f"({len(addrs)} rows x {len(WINDOWS)} windows)")
    if moved:
        print(f"  MOVED at: {[(hex(a), hex(w)) for a, w in moved[:8]]}")
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
