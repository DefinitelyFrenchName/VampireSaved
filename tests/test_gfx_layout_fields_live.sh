#!/bin/sh
# test_gfx_layout_fields_live.sh — gfx_layout3.toml's profile and scatter
# fields must MEAN something (14z-94, GitHub #87). ROM-free, ~2 s.
#
# THE DEFECT. bank4_word, bank5_word, collision_rule and the tenants'
# scatter_lo/scatter_hi read as executable layout policy and were consumed by
# nothing. The bank words are computed by gfx_tiles.bank_word(); the collision
# rule is hardcoded in place(), whose docstring even cites "gfx_layout3.toml's
# collision_rule" while not reading it; the delta-0 path places every
# inventoried tile at its native code without consulting the scatter bounds.
# Editing any of them changed no output and invalidated no build, so the
# repository recorded policy the artifact producer did not enforce.
#
# AND IT HAD ALREADY DRIFTED, which is the point. The moment the builder
# started checking scatter, huitzil's row failed: 246 placed codes outside the
# declared 0x0000-0x06D8. Measured on build/hui43, his out-of-band inventory
# is 270 codes in two parts — 24 singleton effect tiles ending exactly at the
# old bound 0x06D8 (which is why it looked right), plus ONE contiguous run
# 0x0A00-0x0AF5 that arrived later and ends at band_lo - 1. The bound was
# re-measured, not widened to fit. pyron's bounds were already correct; only
# his COUNT comment was stale (51 -> 54, all singletons).
#
# THESE ARE CHECKED, NOT OBEYED, and that is deliberate: the values are baked
# into frozen references (the m3a/stock fingerprints), so making them
# genuinely settable would be a way to silently produce a non-reproducible
# build. Asserting makes the manifest TRUE — an edit fails loudly instead of
# doing nothing — without giving it power to move a frozen byte.
#
# VERIFIED OUTPUT-INERT before this landed: both delta-0 tenants rebuilt
# against HEAD with identical arguments, 10/10 files byte-identical each.
set -eu
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
rc=0
fail() { echo "  FAIL: $*"; rc=1; }
MAN="build/manifest/gfx_layout3.toml"

echo "== 1. the builder READS the profile fields (not just the bands) =="
for fn in check_profile_fields check_scatter_bounds; do
    if grep -q "def $fn" tools/build_gfx_donovan.py && \
       grep -q "^ *$fn(\| $fn(" tools/build_gfx_donovan.py; then
        echo "  ok: $fn is defined and called"
    else
        fail "$fn is missing or never called — the field is inert again"
    fi
done

echo "== 2. the manifest AGREES with what the builder implements =="
python3 - <<'PY' || rc=1
import sys
sys.path.insert(0, "tools")
from _minitoml import loads
from gfx_tiles import bank_word
man = loads(open("build/manifest/gfx_layout3.toml").read())
prof = man["profile"]
bad = 0
for bank, key in ((4, "bank4_word"), (5, "bank5_word")):
    if int(prof[key]) != bank_word(bank):
        print(f"  FAIL: {key}={int(prof[key]):#06x} but bank_word({bank})"
              f"={bank_word(bank):#06x}"); bad = 1
    else:
        print(f"  ok: {key} {int(prof[key]):#06x} == bank_word({bank})")
if prof.get("collision_rule") != "same-source-or-fail":
    print(f"  FAIL: collision_rule={prof.get('collision_rule')!r}, but place()"
          f" implements same-source-or-fail and nothing else"); bad = 1
else:
    print("  ok: collision_rule matches place()'s implemented policy")
sys.exit(bad)
PY

echo "== 3. CONTROLS — each field, perturbed, must be REFUSED =="
# Without these, section 2 passes on a tree that happens to agree, which is
# indistinguishable from a builder that still reads nothing.
T="$(mktemp -d)"; trap 'rm -rf "$T"' EXIT INT TERM
python3 - <<'PY' || rc=1
import sys
sys.path.insert(0, "tools")
from build_gfx_donovan import check_profile_fields, check_scatter_bounds

def must_refuse(label, fn, *a):
    try:
        fn(*a)
    except SystemExit as e:
        if e.code and e.code != 0:
            print(f"  ok: {label} refused")
            return 0
        print(f"  FAIL: {label} exited 0"); return 1
    print(f"  FAIL: {label} was ACCEPTED"); return 1

bad = 0
bad |= must_refuse("a wrong bank4_word", check_profile_fields,
                   {"bank4_word": 0x8000, "bank5_word": 0x3000}, "fixture")
bad |= must_refuse("a wrong bank5_word", check_profile_fields,
                   {"bank4_word": 0x1000, "bank5_word": 0x2000}, "fixture")
bad |= must_refuse("an unimplemented collision_rule", check_profile_fields,
                   {"collision_rule": "last-writer-wins"}, "fixture")
row = {"name": "fix", "band_lo": 0x1000, "band_hi": 0x2000,
       "scatter_lo": 0x0000, "scatter_hi": 0x0100}
bad |= must_refuse("a code outside band AND scatter", check_scatter_bounds,
                   [0x0050, 0x1500, 0x0900], row, "fixture")

# ...and the agreeing case must be ACCEPTED, or "refuse everything" passes.
try:
    check_profile_fields({"bank4_word": 0x1000, "bank5_word": 0x3000,
                          "collision_rule": "same-source-or-fail"}, "fixture")
    check_scatter_bounds([0x0050, 0x1500], row, "fixture")
    print("  ok: agreeing values are accepted (not a blanket refusal)")
except SystemExit as e:
    print(f"  FAIL: correct values were refused: {e}"); bad = 1
sys.exit(1 if bad else 0)
PY

echo "== 4. the re-measured scatter bounds match the shipped inventories =="
# The bounds are a MEASUREMENT. If an inventory changes, this must be
# re-measured rather than the bound widened to fit.
python3 - <<'PY' || rc=1
import sys, json, os
sys.path.insert(0, "tools")
from _minitoml import loads
man = loads(open("build/manifest/gfx_layout3.toml").read())
rows = {r["name"]: r for r in man["tenant"]}
BUILDS = {"huitzil": "build/hui52", "pyron": "build/pyron36"}  # re-pointed 14z-117b (random-select freeze) <- 14z-117  # re-pointed 14z-119 (physics-port freeze) <- 14z-117b
checked = 0
bad = 0
for name, b in BUILDS.items():
    p = f"{b}/donovan_tiles.json"
    if not os.path.exists(p):
        print(f"  note: {p} absent — cannot verify {name}'s bounds here")
        continue
    r = rows[name]
    inv = sorted(int(c) for c in json.load(open(p)))
    blo, bhi = int(r["band_lo"]), int(r["band_hi"])
    slo, shi = int(r["scatter_lo"]), int(r["scatter_hi"])
    out = [c for c in inv if not (blo <= c <= bhi)]
    stray = [c for c in out if not (slo <= c <= shi)]
    if stray:
        print(f"  FAIL: {name} places {len(stray)} code(s) outside band and"
              f" scatter, e.g. {stray[0]:#06x}"); bad = 1
    else:
        print(f"  ok: {name} — {len(out)} out-of-band codes, all within"
              f" {slo:#06x}-{shi:#06x} (extent {min(out):#06x}-{max(out):#06x})")
    checked += 1
if checked == 0:
    print("  note: no tenant build on disk; bounds not verified against an"
          " inventory this run")
sys.exit(bad)
PY

echo "== 5. the safety property is proved ELSEWHERE, and still is =="
# Widening a scatter bound must never be mistaken for widening what is SAFE.
# The disjointness argument lives in test_gfx_layout3.sh against Donovan's
# SAFE_LO, independent of these bounds.
if grep -q "SAFE_LO" tests/test_gfx_layout3.sh; then
    echo "  ok: test_gfx_layout3.sh still asserts H/P codes below SAFE_LO"
else
    fail "the independent disjointness check is gone — the scatter bounds"
    fail "      would then be the only thing standing in for it, and they are"
    fail "      documentation of what IS placed, not of what is safe"
fi

echo
[ "$rc" = 0 ] && echo "PASS: the layout manifest is enforced, not decorative." \
             || echo "FAIL: see above."
exit $rc
