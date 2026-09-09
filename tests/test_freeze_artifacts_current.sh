#!/bin/sh
# test_freeze_artifacts_current.sh — TRACKED ARTIFACTS THAT FOLLOW THE ROMSET
# MUST HAVE BEEN REFRESHED AT THE CURRENT FREEZE. (14z-144.)
#
# WHY THIS EXISTS, and it is measured rather than argued. [VSP-178] says "a
# frozen expectation FOLLOWS whatever moves it, whatever the gate's cadence
# says". That rule was written at 14z-134 after test_mister_prg_window's pair
# shipped five freezes stale, and the remedy was to change that gate's CADENCE
# column to `romset`. A cadence column tells the RUNNER what to run. It says
# nothing to the FREEZE about what to REFRESH.
#
# So the class bit FOUR TIMES on 2026-09-09 alone:
#   1. M17 shipped with tests/expect/mister_prg_window.txt frozen on merged-m16
#   2. M17 shipped with build/merged1 two ops stale (829 vs 831)
#   3. build/merged1 went stale AGAIN within hours of being refreshed, by the
#      M18 fix — with an IDENTICAL op count, only a value differing, so any
#      count-based check would have missed it
#   4. the prg_window pair went stale again at the very next freeze — PREDICTED
#      IN ADVANCE that morning and still not prevented, because nothing asks
#
# THE DISCRIMINATOR — why only these two artifacts, and how to add a third.
# Every OTHER build-derived tracked artifact is already refreshed at every
# freeze, because a ci_static gate fails loudly when it is not: pointer_flow
# (test_pointer_flow), the charmap tables (test_charmap_current), the artifact
# manifests and reproducibility pins (test_m3a_reproducible), bases.tsv
# (audit_roster_pairings). None of those has ever rotted. The two that DID rot
# are exactly the two with no static-tier gate over their currency:
#   * tests/expect/mister_prg_window.txt — its gate is a ~1 h Verilator run, so
#     nothing in the static tier can see it go stale
#   * build/merged1/ — it REBUILDS itself, so its gate's verdict is about the
#     BUILD and staleness surfaces only as working-tree churn a human notices
# ADD A ROW when an artifact is (a) tracked, (b) derived from the build set, and
# (c) not already covered by a ci_static gate that fails on its staleness.
#
# THE BUILD SET comes from tests/run_all_emulator.sh's placeholder defaults —
# the one machine-readable statement of "the current freeze" that is already
# re-pointed every freeze and already watched by test_build_ref_rot. Reading it
# here rather than re-declaring it means this gate cannot disagree with the
# runner about which build is current.
#
# Static, no emulator, ~1 s. Needs the current merged build dir.
# Usage: tests/test_freeze_artifacts_current.sh
set -eu
REPO="$(cd "$(dirname "$0")/.." && pwd)"; export REPO
cd "$REPO"

MERGED="$(sed -n 's/^MERGED="${MERGED:-\([^}]*\)}".*/\1/p' tests/run_all_emulator.sh | head -1)"
[ -n "$MERGED" ] || { echo "FAIL: could not read the MERGED default from tests/run_all_emulator.sh"; exit 1; }
echo "== the current freeze, per tests/run_all_emulator.sh: $MERGED"

MERGED="$MERGED" python3 - <<'PY'
import json, os, re, sys
from pathlib import Path
merged = os.environ["MERGED"]
fails, notes = [], []

def ops(p):
    o = json.loads(Path(p).read_text())
    return o["ops"] if isinstance(o, dict) and "ops" in o else o

def opkey(o):
    return (o.get("addr"), o.get("kind") or o.get("op"),
            json.dumps(o.get("hex") if "hex" in o else o.get("val"), sort_keys=True))

# ── 1. build/merged1 — the merged-legacy instrument ─────────────────────────
# It is the merged program image with gfx SKIPPED, generated from the SAME
# manifests in the same generator invocation, so its patch ops are EQUAL to the
# shipping merged build's. Measured 14z-144: identical as a set, 831 == 831.
# Comparing the ops CONTENT (not the count) is what catches instance 3, where
# the count was unchanged and one word differed.
src = Path("build/merged1/patch/patch.json")
dst = Path(merged) / "patch" / "patch.json"
if not src.exists():
    notes.append(f"1: SKIP — {src} absent")
elif not dst.exists():
    notes.append(f"1: SKIP — {dst} absent (no current merged build to compare against)")
else:
    a, b = ops(src), ops(dst)
    ka, kb = set(map(opkey, a)), set(map(opkey, b))
    if ka != kb:
        fails.append(f"1: build/merged1 is STALE against {merged}: "
                     f"{len(a)} vs {len(b)} ops, {len(ka - kb)} only in merged1, "
                     f"{len(kb - ka)} only in the build — regenerate it "
                     f"(tests/audit_merged_legacy.sh rebuilds it) and COMMIT it")
    else:
        notes.append(f"1: build/merged1 matches {merged} — {len(a)} ops, "
                     f"identical as a set")

# ── 2. tests/expect/mister_prg_window.txt — the frozen pair ─────────────────
# Its header records which build each freeze measured it on. The NEWEST such
# record must name the current merged build dir.
exp = Path("tests/expect/mister_prg_window.txt")
if not exp.exists():
    fails.append(f"2: {exp} is missing")
else:
    hdr = [l for l in exp.read_text().splitlines() if l.startswith("#")]
    dirs = re.findall(r"\(build/([A-Za-z0-9_]+)\)", "\n".join(hdr))
    want = merged.split("/", 1)[1]
    if not dirs:
        fails.append(f"2: {exp} header records no `(build/<dir>)` provenance — "
                     f"it cannot be checked for currency; state which build it "
                     f"was frozen on")
    elif want not in dirs:
        fails.append(f"2: {exp} is STALE: its header records {dirs}, none of "
                     f"which is the current {want}. Its pair follows the ROMSET "
                     f"([VSP-178]) — re-freeze it from a run's own measured "
                     f"line and re-run test_mister_prg_window under the runner")
    else:
        notes.append(f"2: {exp} records {want} — current")

# ── 3. MUST-FIRE CONTROLS ───────────────────────────────────────────────────
# Each perturbs the REAL comparison, not a copy of its own conclusion.
if src.exists() and dst.exists():
    a = ops(src)
    pert = [dict(o) for o in a]
    if pert:
        # instance-3 shape: same COUNT, one value changed
        for o in pert:
            if "hex" in o and isinstance(o["hex"], str) and len(o["hex"]) > 4:
                o["hex"] = ("0" if o["hex"][0] != "0" else "1") + o["hex"][1:]
                break
        if set(map(opkey, pert)) == set(map(opkey, ops(dst))):
            fails.append("3: CONTROL DID NOT FIRE — a one-value perturbation at "
                         "an unchanged op count is invisible to the comparison")
        else:
            notes.append("3: control fired — a one-VALUE change at an unchanged "
                         "op count is caught (this is instance 3, the shape a "
                         "count-based check would miss)")

hdr_txt = "# frozen on merged-m0 (build/definitely_not_the_current_dir)"
if re.findall(r"\(build/([A-Za-z0-9_]+)\)", hdr_txt)[0] == merged.split("/", 1)[1]:
    fails.append("3: CONTROL DID NOT FIRE — a wrong build dir in the header "
                 "reads as current")
else:
    notes.append("3: control fired — a header naming a non-current build dir is "
                 "caught by section 2")

for n in notes:
    print("  " + n)
if fails:
    print()
    for f in fails:
        print("FAIL: " + f)
    print(f"\nFAIL: test_freeze_artifacts_current ({len(fails)} failure(s))")
    sys.exit(1)
print("\nPASS: every romset-following tracked artifact is current with "
      f"{merged}")
PY
