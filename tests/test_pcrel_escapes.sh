#!/bin/sh
# test_pcrel_escapes.sh — the pc-relative DATA-escape set must be UNCHANGED
# SINCE REVIEWED (14z-94, GitHub #22). Needs ROMDIR + the three tenant builds
# and build/out/vsav2_data.bin; ~2 min.
#
# THE FINDING BEHIND IT. tools/verify_pcrel_data.py is the instrument that
# turned "the ported machine carries a live embedded table that reads garbage"
# into a measured fact (14z-69i, region x06cac0 on build/hui11). #22 observed
# that nothing runs it: no test, no battery line, neither builder. So the
# defect class it was written to catch could return on the next placement
# change with nothing to notice.
#
# WHY IT IS NOT SIMPLY WIRED IN, which is what #22 proposed. Measured on all
# three shipping builds: 69/69, 10/10 and 10/10 escapes do NOT resolve to
# their tables. An escape whose table did not travel with its region resolves
# elsewhere BY CONSTRUCTION, so "BROKEN" is not automatically a defect — and a
# 100% rate on field-confirmed builds says these are accepted dead paths, not
# 89 live bugs. A gate that is permanently red is a gate nobody reads.
#
# SO THE VERDICT GETS A BASELINE, on the shared_writes doctrine: the inventory
# is frozen in build/manifest/pcrel_escapes.toml and ANY addition, removal or
# change fails. A pass means the set is unchanged since reviewed — NOT that
# these pointers are safe. That distinction is the whole honesty of this gate.
#
# THE POSITIVE CONTROL that the instrument still discriminates: region
# x06cac0, broken on hui11 and fixed in 14z-69i, must stay ABSENT from the
# inventory. If it ever reappears, the 14z-69i fix has regressed.
set -eu
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
FROZEN="build/manifest/pcrel_escapes.toml"
[ -f build/out/vsav2_data.bin ] || { echo "SKIP: need build/out/vsav2_data.bin"; exit 0; }
[ -f "$FROZEN" ] || { echo "FAIL: no frozen inventory at $FROZEN"; exit 1; }
rc=0

python3 - <<'PY' || rc=1
import os, re, subprocess, sys

BUILDS = ["hui51", "pyron35", "don_m17"]  # re-pointed 14z-117b (random-select freeze) <- 14z-117
present = [b for b in BUILDS if os.path.isdir(f"build/{b}/rompath")]
if not present:
    print("SKIP: none of the three tenant builds are on disk")
    sys.exit(0)

frozen_txt = open("build/manifest/pcrel_escapes.toml").read()
frozen = {}
cur = None
for line in frozen_txt.splitlines():
    m = re.match(r"^\[(\w+)\]", line)
    if m:
        cur = m.group(1); frozen[cur] = set(); continue
    m = re.match(r'^\s*"(.+)",\s*$', line)
    if m and cur:
        frozen[cur].add(m.group(1))

rc = 0
for b in present:
    out = subprocess.run([sys.executable, "tools/verify_pcrel_data.py", f"build/{b}",
                          "--src-data", "build/out/vsav2_data.bin"],
                         capture_output=True, text=True)
    if "verified NOTHING" in out.stderr:
        print(f"  FAIL {b}: the census key is gone — {out.stderr.strip()}")
        rc = 1; continue
    got = {f"{m.group(1)} {m.group(2)} -> {m.group(3)}" for m in
           re.finditer(r"BROKEN (\S+): lea (0x[0-9a-f]+) -> table (0x[0-9a-f]+)", out.stdout)}
    want = frozen.get(b, set())
    added, gone = got - want, want - got
    if added:
        print(f"  FAIL {b}: {len(added)} NEW escape(s) that do not resolve —")
        print( "        establish what each reads before shipping it:")
        for e in sorted(added)[:6]:
            print(f"          + {e}")
        rc = 1
    if gone:
        print(f"  FAIL {b}: {len(gone)} frozen escape(s) DISAPPEARED — that is")
        print( "        good news needing a re-freeze, not a silent pass:")
        for e in sorted(gone)[:6]:
            print(f"          - {e}")
        rc = 1
    if not added and not gone:
        print(f"  ok   {b}: {len(got)} escapes, inventory unchanged")

    if any(e.startswith("x06cac0 ") for e in got):
        print(f"  FAIL {b}: x06cac0 is broken again — the 14z-69i pc-rel table"
              f" fix has REGRESSED (see verify_pcrel_data's docstring)")
        rc = 1

# ── THE MERGED IMAGE (14z-101, GitHub #106) ──────────────────────────────
# The shipping artifact was outside this freeze entirely: merged builds
# carry no extract/ and key non-reference tenants' regions as
# "<region>@<tenant>". The [merged_*] sections freeze it BY REFERENCE
# (same_as a solo section — no second copy to drift), carrying the
# extract + placement-suffix each leg needs.
merged_secs = []
cur = None
for line in frozen_txt.splitlines():
    m = re.match(r"^\[(merged_\w+)\]", line)
    if m:
        cur = {"name": m.group(1)}; merged_secs.append(cur); continue
    if re.match(r"^\[", line):
        cur = None; continue
    m = re.match(r'^(\w+) = "(.*)"$', line)
    if m and cur is not None:
        cur[m.group(1)] = m.group(2)

for sec in merged_secs:
    name = sec["name"]
    bdir = f"build/{sec['build']}"
    if not os.path.isdir(f"{bdir}/rompath"):
        print(f"  SKIP {name}: no merged build at {bdir}")
        continue
    if not os.path.isdir(sec["extract"]):
        print(f"  SKIP {name}: no extract at {sec['extract']}")
        continue
    cmd = [sys.executable, "tools/verify_pcrel_data.py", bdir,
           "--src-data", "build/out/vsav2_data.bin",
           "--extract", sec["extract"]]
    if sec.get("placement_suffix"):
        cmd += ["--placement-suffix", sec["placement_suffix"]]
    out = subprocess.run(cmd, capture_output=True, text=True)
    if "verified NOTHING" in out.stderr or out.returncode == 2:
        print(f"  FAIL {name}: instrument error — {out.stderr.strip()}")
        rc = 1; continue
    got = {f"{m.group(1)} {m.group(2)} -> {m.group(3)}" for m in
           re.finditer(r"BROKEN (\S+): lea (0x[0-9a-f]+) -> table (0x[0-9a-f]+)",
                       out.stdout)}
    want = frozen.get(sec["same_as"], set())
    added, gone = got - want, want - got
    if added or gone:
        print(f"  FAIL {name}: merged inventory differs from its reference "
              f"[{sec['same_as']}] (+{len(added)}/-{len(gone)}) —")
        for e in sorted(added)[:4]:
            print(f"          + {e}")
        for e in sorted(gone)[:4]:
            print(f"          - {e}")
        rc = 1
    else:
        print(f"  ok   {name}: {len(got)} escapes on the MERGED placements, "
              f"identical to [{sec['same_as']}]")
    if any(e.startswith("x06cac0 ") for e in got):
        print(f"  FAIL {name}: x06cac0 broken on the merged image — 14z-69i "
              f"regressed")
        rc = 1

# MUST-FIRE CONTROL for the merged comparison: the same leg with its
# placement suffix deliberately WRONG must read zero escapes (every
# region skipped) and therefore FAIL the reference comparison — proving
# a wrong or rotted suffix/extract cannot present as green coverage.
ctl = next((s for s in merged_secs
            if s.get("placement_suffix") and os.path.isdir(f"build/{s['build']}/rompath")
            and os.path.isdir(s["extract"])), None)
if ctl is not None:
    out = subprocess.run([sys.executable, "tools/verify_pcrel_data.py",
                          f"build/{ctl['build']}",
                          "--src-data", "build/out/vsav2_data.bin",
                          "--extract", ctl["extract"],
                          "--placement-suffix", "@wrong_on_purpose"],
                         capture_output=True, text=True)
    got = {m.group(0) for m in re.finditer(r"BROKEN \S+", out.stdout)}
    if got or not frozen.get(ctl["same_as"]):
        print("  FAIL control: the wrong-suffix leg still produced findings — "
              "the must-fire premise is broken")
        rc = 1
    else:
        print(f"  ok   control: a wrong placement suffix reads 0 escapes vs "
              f"{len(frozen[ctl['same_as']])} frozen — the comparison would fire")

if rc == 0:
    print("  ok   x06cac0 absent everywhere — the 14z-69i fix still holds")
sys.exit(rc)
PY

echo
if [ "$rc" = 0 ]; then
    echo "PASS: the pc-rel escape set is unchanged since reviewed."
    echo "      (That is what this asserts. It does NOT assert they are safe.)"
else
    echo "FAIL: see above."
fi
exit $rc
