#!/bin/sh
# test_baseset_mask_invariant.sh — a .masked spec's baseset must be frozen
# under the same mask the set runs (14z-94, GitHub #62). ROM-free, ~1 s.
#
# THE INVARIANT was stated in run_suite.sh's own header — "A .masked spec's
# <baseset> MUST be the vanilla basis generated under the SAME mask (masked
# bytes are skipped from the checksum, so v2 logs cannot be compared under a
# v3 mask)" — and checked nowhere. The RUN mask comes from the expectation
# set, the BASE comes from the spec, and nothing compared them.
# freeze_masked_basis.sh built exactly this guard for the WRITE side in
# 14z-89; this is the read side.
#
# THE HAZARD IS LIVE. A third basis, vsavj/masked-v3, is on disk right now
# with a different mask — ratified and withdrawn the same day (STATE 14z-88)
# and "kept as a parked basis". Retargeting a spec to it, or editing a set's
# mask file without its specs, is a one-token edit the suite could not detect.
#
# WHAT IS ASSERTED HERE is the STATIC pairing across the whole tree, so the
# invariant is checked even for expectation sets no current build dispatches
# to. run_suite enforces it per-replay at run time; this covers the rest.
set -eu
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
rc=0

python3 - <<'PY' || rc=1
import glob, os, sys

EXP = "tests/expected"
# run_suite's built-in default, used by sets that ship no mask file of their own
DEFAULT = "043c-043d,4182-41a2,7f00-8000"

def run_mask(setdir):
    p = os.path.join(setdir, "mask")
    return open(p).read().strip() if os.path.exists(p) else DEFAULT

def base_mask(base):
    p = os.path.join(EXP, base, "MASK")
    return open(p).read().strip() if os.path.exists(p) else None

bad = 0
pairs = {}
for spec_path in sorted(glob.glob(f"{EXP}/*/*.masked")):
    setdir = os.path.dirname(spec_path)
    parts = open(spec_path).read().split()
    if len(parts) < 2:
        print(f"  FAIL {spec_path}: spec has no baseset"); bad += 1; continue
    base = parts[1]
    rm, bm = run_mask(setdir), base_mask(base)
    pairs.setdefault((os.path.basename(setdir), base, rm, bm), 0)
    pairs[(os.path.basename(setdir), base, rm, bm)] += 1
    if bm is None:
        # A record-less basis (v1 predates MASK records) is only safe for a
        # set on the built-in default.
        if os.path.exists(os.path.join(setdir, "mask")):
            print(f"  FAIL {spec_path}: cites {base}, which has no MASK record,"
                  f" while the set overrides the default mask"); bad += 1
    elif rm != bm:
        print(f"  FAIL {spec_path}: set runs {rm}\n"
              f"        but {base} was frozen under {bm}"); bad += 1

print(f"  checked {sum(pairs.values())} .masked specs across "
      f"{len({p[0] for p in pairs})} expectation sets")
for (s, b, rm, bm) in sorted(pairs):
    tag = "default" if bm is None else "recorded"
    print(f"    {s:<14} -> {b:<18} ({tag})")
sys.exit(1 if bad else 0)
PY

echo "== VERDICT CONTROL — a mispaired spec must be CAUGHT =="
# Without this the section above passes on a tree that happens to be correct,
# which is indistinguishable from a checker that never compares anything.
T="$(mktemp -d)"; trap 'rm -rf "$T"' EXIT INT TERM
mkdir -p "$T/expected/setA" "$T/expected/vsavj/basisX"
printf 'aaaa-bbbb\n' > "$T/expected/setA/mask"
printf 'cccc-dddd\n' > "$T/expected/vsavj/basisX/MASK"
printf 'exact vsavj/basisX\n' > "$T/expected/setA/01_x.masked"
if (cd "$T" && python3 - <<'PY'
import glob, os, sys
EXP = "expected"
DEFAULT = "043c-043d,4182-41a2,7f00-8000"
bad = 0
for spec_path in sorted(glob.glob(f"{EXP}/*/*.masked")):
    setdir = os.path.dirname(spec_path)
    base = open(spec_path).read().split()[1]
    mp = os.path.join(setdir, "mask")
    rm = open(mp).read().strip() if os.path.exists(mp) else DEFAULT
    bp = os.path.join(EXP, base, "MASK")
    bm = open(bp).read().strip() if os.path.exists(bp) else None
    if bm is not None and rm != bm:
        bad += 1
sys.exit(1 if bad else 0)
PY
); then
    echo "  FAIL: a deliberately mispaired spec was NOT caught"
    rc=1
else
    echo "  ok: a mispaired spec is caught"
fi

echo "== run_suite carries the runtime half =="
if grep -q "mask mismatch" tests/run_suite.sh; then
    echo "  ok: run_suite.sh enforces it per replay at run time"
else
    echo "  FAIL: run_suite.sh no longer enforces the invariant"
    rc=1
fi

echo
if [ "$rc" = 0 ]; then
    echo "PASS: every .masked spec cites a basis frozen under its own mask."
else
    echo "FAIL: see above."
fi
exit $rc
